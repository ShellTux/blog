---
title: "Nix"
date: 2024-04-29T23:22:17+01:00
draft: true
description: Nix Package Manager
categories:
  - NixOS
  - Nix
tags:
  - nixos
  - nix
math: false
author: "Me"
type: "post"
layout: "post"
cover:
  hidden: false
  image: "covers/nix.png"
  alt: 
  caption: 
  relative: true
---

Nix is a purely functional package manager. This means that it treats packages
like values in purely functional programming languages such as Haskell — they
are built by functions that don’t have side-effects, and they never change after
they have been built.

<!--more-->

# Nix

## Configuration Files

File | Description
--- | ---
`/etc/nixos/configuration.nix` | System NixOS Configuration

## Installation / Uninstalling Packages

Search for packages [here](https://search.nixos.org/packages)

| Command | Description |
| -------------- | --------------- |
| `nix-env -iA nixos.vim` | User-Wide Installation of vim package |
| `sudo nix-env -iA nixos.vim` | System-Wide Installation of vim package |
| `nix-env --uninstall vim` | Uninstall vim package |
| `nixos-rebuild switch` | Rebuild NixOS System and change into it |

You can Install in 2 ways:
- Changing Configuration File and rebuild
```nix
environment.systemPackages = [
pkgs.vim
];
```
- nix-env

```sh
nix-env -iA nixos.vim # User-Wide
sudo nix-env -iA nixos.vim # System-Wide
```

Uninstall:

```sh
nix-env --uninstall vim
```
