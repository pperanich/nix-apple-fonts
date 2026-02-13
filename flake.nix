{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      treefmt-nix,
    }:
    let
      lib = nixpkgs.lib;

      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
      forEachSystem = lib.genAttrs systems;

      treefmtEval = forEachSystem (
        system:
        treefmt-nix.lib.evalModule nixpkgs.legacyPackages.${system} {
          projectRootFile = "flake.nix";
          programs.nixfmt.enable = true;
        }
      );

      # Font definitions: name -> { url, hash, pkgName }
      fontDefs = {
        sf-pro = {
          url = "https://devimages-cdn.apple.com/design/resources/download/SF-Pro.dmg";
          hash = "sha256-W0sZkipBtrduInk0oocbFAXX1qy0Z+yk2xUyFfDWx4s=";
          pkgName = "SF Pro Fonts.pkg";
        };
        sf-compact = {
          url = "https://devimages-cdn.apple.com/design/resources/download/SF-Compact.dmg";
          hash = "sha256-RWeq4GFt01r8NLrWvvVH5y/R5lhFMFozlzBkUY0dU0g=";
          pkgName = "SF Compact Fonts.pkg";
        };
        sf-mono = {
          url = "https://devimages-cdn.apple.com/design/resources/download/SF-Mono.dmg";
          hash = "sha256-bUoLeOOqzQb5E/ZCzq0cfbSvNO1IhW1xcaLgtV2aeUU=";
          pkgName = "SF Mono Fonts.pkg";
        };
        sf-arabic = {
          url = "https://devimages-cdn.apple.com/design/resources/download/SF-Arabic.dmg";
          hash = "sha256-J2DGLVArdwEsSVF8LqOS7C1MZH/gYJhckn30jRBRl7k=";
          pkgName = "SF Arabic Fonts.pkg";
        };
        sf-armenian = {
          url = "https://devimages-cdn.apple.com/design/resources/download/SF-Armenian.dmg";
          hash = "sha256-/9cVrpPXwhW+P0NLhGJBhHebtQsrs9Zrj9QogMZfra0=";
          pkgName = "SF Armenian Fonts.pkg";
        };
        sf-georgian = {
          url = "https://devimages-cdn.apple.com/design/resources/download/SF-Georgian.dmg";
          hash = "sha256-wWsXmEcrJiMkRTMepRrIKZJgZ0/o+386NU7t61OQotI=";
          pkgName = "SF Georgian Fonts.pkg";
        };
        sf-hebrew = {
          url = "https://devimages-cdn.apple.com/design/resources/download/SF-Hebrew.dmg";
          hash = "sha256-MljkBxW4vPRelEHbv3IYruqlcAZdzB97+lXJ7W0Lk4Q=";
          pkgName = "SF Hebrew Fonts.pkg";
        };
        ny = {
          url = "https://devimages-cdn.apple.com/design/resources/download/NY.dmg";
          hash = "sha256-HC7ttFJswPMm+Lfql49aQzdWR2osjFYHJTdgjtuI+PQ=";
          pkgName = "NY Fonts.pkg";
        };
      };
    in
    {
      overlays.default = final: _prev: self.packages.${final.system};

      packages = forEachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          makeAppleFont =
            {
              fontName,
              fontDef,
              nerd ? false,
            }:
            pkgs.stdenvNoCC.mkDerivation (
              {
                pname = if nerd then "${fontName}-nerd" else fontName;
                version = "0-unstable-2025-02-13";

                src = pkgs.fetchurl {
                  inherit (fontDef) url hash;
                };

                nativeBuildInputs = [
                  pkgs.undmg
                  pkgs.p7zip
                ]
                ++ lib.optionals nerd [
                  pkgs.parallel
                  pkgs.nerd-font-patcher
                ];

                sourceRoot = ".";

                unpackPhase = ''
                  runHook preUnpack
                  undmg $src
                  7z x '${fontDef.pkgName}'
                  7z x 'Payload~'
                  runHook postUnpack
                '';

                installPhase = ''
                  runHook preInstall
                  mkdir -p "$out/share/fonts/opentype" "$out/share/fonts/truetype"
                  find -name '*.otf' ${lib.optionalString nerd "-maxdepth 1"} -exec install -Dm644 -t "$out/share/fonts/opentype" {} +
                  find -name '*.ttf' ${lib.optionalString nerd "-maxdepth 1"} -exec install -Dm644 -t "$out/share/fonts/truetype" {} +
                  runHook postInstall
                '';

                meta = {
                  description = "Apple ${fontName} font family${lib.optionalString nerd " (Nerd Font patched)"}";
                  homepage = "https://developer.apple.com/fonts/";
                  license = lib.licenses.unfree;
                  platforms = lib.platforms.all;
                };
              }
              // lib.optionalAttrs nerd {
                buildPhase = ''
                  runHook preBuild
                  find -name '*.ttf' -o -name '*.otf' -print0 \
                    | parallel --will-cite -j $NIX_BUILD_CORES -0 nerd-font-patcher --no-progressbars -c {}
                  runHook postBuild
                '';
              }
            );
        in
        lib.concatMapAttrs (fontName: fontDef: {
          ${fontName} = makeAppleFont {
            inherit fontName fontDef;
          };
          "${fontName}-nerd" = makeAppleFont {
            inherit fontName fontDef;
            nerd = true;
          };
        }) fontDefs
      );

      formatter = forEachSystem (system: treefmtEval.${system}.config.build.wrapper);

      checks = forEachSystem (system: {
        formatting = treefmtEval.${system}.config.build.check self;
      });

      hydraJobs = {
        inherit (self) packages;
      };
    };
}
