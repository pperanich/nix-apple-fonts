# nix-apple-fonts

A Nix flake for Apple's San Francisco and New York font families, sourced directly from [Apple](https://developer.apple.com/fonts/).

> [!Note]
> This project is based on [Lyndeno/apple-fonts.nix](https://github.com/Lyndeno/apple-fonts.nix) by [Lyndeno](https://github.com/Lyndeno). Licensed under MIT.

## Available Packages

| Package       | Nerd Font Variant  |
| ------------- | ------------------ |
| `sf-pro`      | `sf-pro-nerd`      |
| `sf-compact`  | `sf-compact-nerd`  |
| `sf-mono`     | `sf-mono-nerd`     |
| `sf-arabic`   | `sf-arabic-nerd`   |
| `sf-armenian` | `sf-armenian-nerd` |
| `sf-georgian` | `sf-georgian-nerd` |
| `sf-hebrew`   | `sf-hebrew-nerd`   |
| `ny`          | `ny-nerd`          |

> [!Tip]
> Nerd Font variants are automatically patched with the [nerd font patcher](https://github.com/ryanoasis/nerd-fonts), adding common symbols suitable for terminals, status bars, etc.

## Usage

### Add the flake input

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    apple-fonts.url = "github:pperanich/nix-apple-fonts";
    apple-fonts.inputs.nixpkgs.follows = "nixpkgs";
  };
}
```

### Install fonts (NixOS)

```nix
{ pkgs, inputs, ... }:
{
  fonts.packages = [
    inputs.apple-fonts.packages.${pkgs.system}.sf-pro
    inputs.apple-fonts.packages.${pkgs.system}.sf-mono-nerd
  ];
}
```

### Install fonts (Home Manager)

```nix
{ pkgs, inputs, ... }:
{
  home.packages = [
    inputs.apple-fonts.packages.${pkgs.system}.sf-pro
    inputs.apple-fonts.packages.${pkgs.system}.ny
  ];
}
```

### Via overlay

An overlay is provided for users who prefer adding packages to the `pkgs` namespace:

```nix
{
  nixpkgs.overlays = [ inputs.apple-fonts.overlays.default ];

  # Then use directly:
  fonts.packages = [ pkgs.sf-pro pkgs.sf-mono-nerd ];
}
```

## Binary Cache

Pre-built font packages are available via [Cachix](https://www.cachix.org/) to avoid building from source.

### Cachix

```nix
nix.settings = {
  substituters = [ "https://nix-apple-fonts.cachix.org" ];
  trusted-public-keys = [ "nix-apple-fonts.cachix.org-1:+IufU9qEralI2eCib9vH4bv093Xo1F9l0rw24KzLEdg=" ];
};
```

Or with the Cachix CLI:

```sh
cachix use nix-apple-fonts
```

### FlakeHub

This flake is also published to [FlakeHub](https://flakehub.com). Users of [Determinate Nix](https://determinate.systems) get automatic cache hits via FlakeHub Cache with no additional configuration.
