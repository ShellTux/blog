---
title: "FFmpeg"
date: 2024-05-03T09:37:14+01:00
description: FFmpeg collection of useful video/audio editor commands
categories:
  - FFmpeg
tags:
  - ffmpeg
math: false
author: "Me"
type: "post"
layout: "post"
cover:
  hidden: false # hide everywhere but not in structured data
  image: "covers/ffmpeg.jpeg"
  alt: 
  caption: 
  relative: true
---

FFmpeg is a collection of libraries and tools to process multimedia content such
as audio, video, subtitles and related metadata.

<!--more-->

# FFmpeg

Any of the following global options can be seen in the [ffmpeg manpage](https://manpage.me/?q=ffmpeg)

## Commands

| Description                                                  | Command                                                                                                                                                           |
| ---------------                                              | ---------------                                                                                                                                                   |
| Change Loglevel and print a less verbose stats               | `ffmpeg -i input.mp4 -loglevel warning -stats output.mkv`                                                                                                         |
| Converting Media Formats                                     | `ffmpeg -i input.mp4 output.mkv`                                                                                                                                  |
| Extracting Audio From Videos                                 | `ffmpeg -i input.mp4 -vn audio.mp3`                                                                                                                               |
| Resizing Videos                                              | `ffmpeg -i input.mp4 -vf scale=1280:720 resized.mp4`                                                                                                              |
| Trimming a video (From 3s)                                   | `ffmpeg -i input.mp4 -ss 00:03 -c copy cut.mp4`                                                                                                                   |
| Trimming a video (To 5s)                                     | `ffmpeg -i input.mp4 -to 00:05 -c copy cut.mp4`                                                                                                                   |
| Trimming a video (From 3s to 5s)                             | `ffmpeg -i input.mp4 -ss 00:03 -to 00:05 -c copy cut.mp4`                                                                                                         |
| Trimming a video (From 3s during 5s)                         | `ffmpeg -i input.mp4 -ss 00:03 -t 00:05 -c copy cut.mp4`                                                                                                          |
| Adding Subtitles                                             | `ffmpeg -i input.mp4 -vf "subtitles=subtitles.srt" output-subtitles.mp4`                                                                                          |
| Creating a Video Slideshow from Images                       | `ffmpeg -framerate 1 -i img%03d.jpg slideshow.mp4`                                                                                                                |
| Extracting Frames from a Video                               | `ffmpeg -i input.mp4 -vf "select=mod(n\,100)" -vsync vfr frame%03d.png`                                                                                           |
| Extracting a frame each second from a video                  | `ffmpeg -i input.mp4 -vf fps=1 output_%04d.jpg`                                                                                                                   |
| Speeding Up or Slowing Down a Video                          | `ffmpeg -i input.mp4 -vf "setpts=0.5*PTS" speed.mp4`                                                                                                              |
| Concatenating Videos                                         | `ffmpeg -i "concat:input1.mp4\|input2.mp4\|input3.mp4" -c copy concatenated.mp4`                                                                                  |
| Rotating a video (transpose=0,1,2,3 1=90º)                   | `ffmpeg -i input.mp4 -vf "transpose=1" rotated.mp4`                                                                                                               |
| Creating a video thumbnail (@ 3 seconds)                     | `ffmpeg -i input.mp4 -ss 00:03:00 -vframes 1 thumbnail.jpg`                                                                                                       |
| Extracting Audio Channels                                    | `ffmpeg -i input.mp4 -map_channel 0.1.0 audio_channel.wav`                                                                                                        |
| Changing Volume (80% Volume)                                 | `ffmpeg -i input.mp4 -filter:a "volume=0.80" output-80-volume.mp4`                                                                                                |
| Creating a Video Loop (10min=600s loop)                      | `ffmpeg -stream_loop -1 -i input.mp4 -c copy -fflags +genpts -t 600 loop.mp4`                                                                                     |
| Adding a Video Overlay (Between 0-20s @-10,10)               | `ffmpeg -i main.mp4 -i overlay.mp4 -filter_complex "[0:v][1:v] overlay=main_w-overlay_w-10:10:enable='between(t,0,20)'" -pix_fmt yuv420p -c:a copy overlayed.mp4` |
| Creating a Picture-in-Picture Effects (Between 0-20s @25,25) | `ffmpeg -i main.mp4 -i pip.mp4 -filter_complex "[0:v][1:v] overlay=25:25:enable='between(t,0,20)'" -pix_fmt yuv420p -c:a copy output-pip.mp4`                     |
| Adding a Soundtrack to a Video                               | `ffmpeg -i video.mp4 -i audio.mp3 -c:v copy -c:a aac -map 0:v:0 -map 1:a:0 output-with-audio.mp4`                                                                 |
| Looping video back and forth (loop 4 times @20fps)           | `ffmpeg -i input.mp4 -filter_complex "[0]reverse[r];[0][r]concat,loop=4:250,setpts=N/20/TB" back-forth.mp4`                                                       |

## [Concatenating videos by applying a filter and a concat file](https://trac.ffmpeg.org/wiki/Concatenate)

This section covers concatenating videos by providing ffmpeg a file in a given
syntax and by applying the `concat` filter.

This approach could be useful if you want to concat multiple videos by a given
section specific to each video.

Example:

```
# Comment
file './input1.mkv'
file './input2.mkv'
inpoint 00:10
file './input3.mkv'
outpoint 00:20
file './input4.mkv'
inpoint 00:10
outpoint 00:20
```

```sh
ffmpeg -f concat -safe 0 -i concat.txt -c copy -loglevel warning -stats concat.mkv
```
