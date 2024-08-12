---
title: "Netcat"
date: 2024-08-12T18:40:47+01:00
draft: true
description: Ncat is a feature-packed networking utility which reads and writes data across networks from the command line.
categories:
  - Netcat
tags:
  - netcat
math: false
author: "Me"
type: "post"
layout: "post"
cover:
  hidden: false # hide everywhere but not in structured data
  image: "covers/netcat.jpg"
  alt: 
  caption: 
  relative: true
---

Ncat is a feature-packed networking utility which reads and writes data across
networks from the command line.

<!--more-->

# Ncat

Any of the following global options can be seen in the [netcat manpage](https://manpage.me/?q=nc)

## Commands

> [!NOTE]
> Replace host with the address of the server you want to connect to.

> [!NOTE]
> You can press CTRL+C to stop the connection.

| Description | Server Command | Client Command |
| --------------- | --------------- | --------------- |
| Send Messages | nc -l 1234 | nc host 1234 |
| Send File | nc -l -p 1234 < filename | nc host 1234 > received_filename |

