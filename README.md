# video_led_sync

A simple video player created with Flutter, that can read a video file (e.g. *.mp4) and a csv-file containing timestamped RGB keyframes and then sends the keyframes over USB-Serial/Websockets in sync with the video.

## RGB-keyframes file

### Overview
- no column titles
- 4 columns
    1. timestamp (more on that below)
    2. R-value (8-bit, e.g. from 0 to 255)
    3. G-value (8-bit, e.g. from 0 to 255)
    4. B-value (8-bit, e.g. from 0 to 255)
- 1 row per keyframe
- video_led_sync interpolates linearly between all keyframes

### Timestamps

The timestamps can be provided in the following formats (leading zeros are optional for minutes and seconds):
- `mm:ss` (minutes, seconds)
- `mm:ss:s` (minutes, seconds and hundreds of milliseconds)
- `mm:ss:ss` (minutes, seconds and tens of milliseconds)
- `mm:ss:sss` (minutes, seconds and milliseconds)