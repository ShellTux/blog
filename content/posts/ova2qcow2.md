---
title: "Ova2qcow2"
date: 2024-02-22T20:30:33Z
draft: true
description: Converting a VirtualBox VM image (ova) to QEMU VM image (qcow2)
categories:
  - Virtualizing
tags:
  - VM
math: false
author: "Me"
type: "post"
layout: "post"
cover:
  hidden: false # hide everywhere but not in structured data
  alt: 
  caption: 
  relative: true
---



<!--more-->

# Ova2qcow2

## Introduction

In this tutorial, you will learn how to convert a VirtualBox image to QEMU image

## Requirements

Packages:
- qemu-img
- tar

## Tutorial

### Create temporary directory to extract ova image

```sh
temp_dir="$(mktemp --directory)"
tar -xvf your_virtual_machine.ova --directory="$temp_dir"
```

Your temp_dir should look like this:

```sh
$ ls "$temp_dir"
your_virtual_machine-disk001.vmdk  your_virtual_machine.mf  your_virtual_machine.ovf
```

### Convert to Qcow2 using qemu-img tool

```sh
qemu-img convert -f vmdk -O qcow2 "$temp_dir/your_virtual_machine-disk001.vmdk" destination_image.qcow2
```

This process should take a while...

And you are done, you should find the image at the destination you provided

You can delete everything under the temporary directory

```sh
rm -r "$temp_dir"
unset temp_dir
```

## Conclusion

To summarize everything, I wrote a shell script that given a ova file as first
argument and qcow2 destination file path as second argument, it will produce the
image you want.

Something like this:

```sh
#!/bin/sh
set -e

usage() {
	echo "Usage: $(basename "$0") <ova file> <qcow2 file>"
	exit 1
}

[ "$#" -ne 2 ] && usage

set -x

ova_file="$1"
qcow2_file="$2"
temp_dir="$(mktemp --directory)"
tar -xvf "$ova_file" --directory="$temp_dir"
qemu-img convert \
	-f vmdk \
	-O qcow2 \
	"$(ls "$temp_dir"/*-disk001.vmdk)" \
	"$qcow2_file"
rm -r "$temp_dir"
unset temp_dir
```

also can be found at https://github.com/ShellTux/ConvertOva2Qcow2
