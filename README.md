# AnimeSkip for Anikku

A smart skip script for Anikku that automatically skips anime openings by detecting silence or using embedded chapters.

## Features

- 🎯 **Chapter Priority**: Automatically uses embedded chapter markers if available
- 🔇 **Silence Detection**: Scans for silence at the end of openings when chapters aren't available
- ⚡ **Fast Scanning**: Scans at 100x speed to quickly find silence
- 🛡️ **Fallback Protection**: If no silence is found within 3 minutes, skips +85 seconds
- 🎚️ **Adjustable Sensitivity**: Customize detection settings for different anime

## Installation

### Step 1: Install the Script

1. Download `chapterskip.lua` from this repository
2. In Anikku, go to **More → Advanced → Open config directory**
3. Navigate to the `scripts` folder (create it if it doesn't exist)
4. Copy `chapterskip.lua` into the `scripts` folder
5. Restart Anikku

### Step 2: Set Up the Custom Button

1. In Anikku, go to **More → Player settings → Custom buttons**
2. Tap the **+** button to add a new custom button
3. Configure the button with the following settings:

**Lua code (tap):**
```lua
mp.commandv("script-binding", "skip-to-silence")
```

**Lua code (on long press):**
```lua
aniyomi.show_text("Skip to silence")
```

**On startup:**
```lua
if $isPrimary then
  aniyomi.set_button_title("Skip")
  aniyomi.show_button()
end
```

4. Save the button
5. The "Skip" button should now appear in your player interface

## Usage

Simply tap the **Skip** button during anime playback:

- If the anime has embedded chapters (like "OP" or "Opening"), it will skip to the next chapter
- If no chapters are available, it will scan forward at 100x speed looking for silence
- If no silence is found within 3 minutes, it will skip forward 85 seconds

## Configuration

You can adjust the script's behavior by editing `chapterskip.lua` and changing these values:
```lua
local opts = {
    quietness = -30,           -- dB threshold (-50 = stricter, -30 = more lenient)
    duration = 0.5,            -- Minimum silence duration in seconds
    prefer_chapters = true,    -- Try chapters before silence detection
    fallback_skip = 85,        -- Seconds to skip if no silence found
    silence_offset = 0.5,      -- Rewind from silence end to avoid overshooting
    max_scan_duration = 180,   -- Max seconds to scan before using fallback
}
```

### Adjusting Sensitivity

If the script is skipping too often during episodes:
- Increase `quietness` to `-40` or `-50` (stricter)
- Increase `duration` to `1.0` or `1.5` (needs longer silence)

If the script isn't detecting silence at the end of openings:
- Decrease `quietness` to `-20` (more lenient)
- Decrease `duration` to `0.3` (detects shorter silence)

## How It Works

1. **Chapter Detection**: First checks if the video has embedded chapters
2. **Silence Scanning**: If no chapters, adds an audio filter that detects silence
3. **Fast Forward**: Plays at 100x speed with muted audio and black screen
4. **Smart Stopping**: Stops when silence is detected or max scan time is reached
5. **Fallback**: If nothing works, skips forward 85 seconds from activation point

## Troubleshooting

**Button doesn't appear:**
- Make sure the script is in the `scripts` folder
- Restart Anikku completely
- Check that the button is set as primary in custom button settings

**Script doesn't find silence:**
- Try adjusting `quietness` and `duration` settings
- Some anime may not have silence at the end of openings
- The 85-second fallback will activate automatically

**Skips too far past the opening:**
- Increase `silence_offset` to rewind more from detected silence
- Try `silence_offset = 1.0` or higher

## Credits

- Original `skiptosilence.lua` by [detuur](https://github.com/detuur/mpv-scripts) and microraptor
- Modified for Anikku by [deep-sleepy](https://github.com/deep-sleepy)
- Built for use with [Anikku](https://github.com/Hasuki69/Anikku) (MPV-based anime player)

## License

MIT License - See LICENSE file for details
```

## LICENSE
```
MIT License

Copyright (c) 2022 detuur, microraptor (original skiptosilence.lua)
Copyright (c) 2025 deep-sleepy (modifications for Anikku)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.