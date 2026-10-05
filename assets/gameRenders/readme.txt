Codename Engine FFmpeg Song Renderer

Video Rendering Mode:
1. Put ffmpeg.exe next to the Windows game executable.
2. Enable Options > Game Renderer > Video Rendering Mode.
3. Play the song normally.
4. The engine writes the MP4 to assets/gameRenders/.

Classic Rendering Mode saves numbered frames:
assets/gameRenders/<song>/0000000.jpg
or
assets/gameRenders/<song>/0000000.png

Convert classic frames with FFmpeg:
ffmpeg -r 60 -i "./<song>/%07d.jpg" output.mp4

PNG:
ffmpeg -r 60 -i "./<song>/%07d.png" output.mp4

The renderer also exposes video framerate, bitrate, encoder, lossless screenshots, JPEG quality, garbage collection rate, output folder, and unlocked rendering FPS settings.
