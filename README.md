# AnimeSkip for Anikku

A smart skip script for Anikku that automatically skips anime openings, endings, previews, and recaps by detecting chapter markers or scanning for silence.

## Features

- 🎯 **Auto-Skip Chapters**: Automatically skips Opening, Ending, Preview, and Recap chapters
- 🎚️ **Customizable**: Toggle each skip type individually (Opening/Ending/Intro/Outro/Preview/Recap)
- 🔇 **Silence Detection**: Scans for silence when chapters aren't available
- ⚡ **Fast Scanning**: Scans at 100x speed to quickly find silence
- 🛡️ **Fallback Protection**: If no silence is found within 3 minutes, skips +85 seconds
- 🎛️ **Adjustable Sensitivity**: Customize detection settings for different anime

## Installation

### Step 1: Install the Script

1. Download `chapterskip.lua` from this repository
2. Open the Anikku base folder you set during initial setup
3. Navigate to `mpv-config/scripts/` (create the folders if they don't exist)
4. Copy `chapterskip.lua` into the `scripts` folder
   - Full path should be: `[Anikku base folder]/mpv-config/scripts/chapterskip.lua`
5. Restart Anikku

### Step 2: Set Up the Custom Button (Optional)

The script works automatically, but you can add a manual skip button:

1. In Anikku, go to **More → Player settings → Custom buttons**
2. Tap the **+** button to add a new custom button
3. Configure the button with the following settings:

**Title:**
```
Skip
```

**Lua code (tap):**
```lua
mp.commandv("script-binding", "skip-to-silence")
```

**Lua code (on long press):**
```
(Leave this blank - long press is not required)
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

### Automatic Skipping

The script automatically skips the following chapter types when detected:
- ✅ **Opening** (OP, Opening, オープニング, 片头) - Enabled by default
- ✅ **Ending** (ED, Ending, エンディング, 片尾) - Enabled by default
- ✅ **Preview** (Preview, Next Episode, プレビュー, 予告) - Enabled by default
- ✅ **Recap** (Recap, Previously, あらすじ, 回顾) - Enabled by default
- ❌ **Intro** - Disabled by default
- ❌ **Outro** - Disabled by default

### Manual Skipping

If you added the custom button, tap it to manually skip:
- If chapters exist → skips to next chapter
- If no chapters → scans forward for silence at 100x speed
- If no silence found in 3 minutes → skips +85 seconds from activation point

## Configuration

You can customize the script's behavior by editing `chapterskip.lua` in `[Anikku base folder]/mpv-config/scripts/`:

### Toggle Auto-Skip for Each Chapter Type
```lua
local opts = {
    auto_skip = true,              -- Master toggle for auto-skip
    skip_opening = true,           -- Skip Opening chapters
    skip_ending = true,            -- Skip Ending chapters
    skip_intro = false,            -- Skip Intro chapters
    skip_outro = false,            -- Skip Outro chapters
    skip_preview = true,           -- Skip Preview chapters
    skip_recap = true,             -- Skip Recap chapters
}
```

Set any of these to `false` to disable skipping for that chapter type.

### Adjust Silence Detection
```lua
local opts = {
    quietness = -50,               -- dB threshold (-60 = stricter, -30 = more lenient)
    duration = 0.5,                -- Minimum silence duration in seconds
    fallback_skip = 85,            -- Seconds to skip if no silence found
    silence_offset = 0.5,          -- Rewind from silence end to avoid overshooting
    max_scan_duration = 180,       -- Max seconds to scan before using fallback
}
```

### Sensitivity Guide

**If the script skips too often during episodes:**
- Increase `quietness` to `-60` (stricter - needs quieter audio)
- Increase `duration` to `1.0` or `1.5` (needs longer silence)

**If the script doesn't detect silence at the end of openings:**
- Decrease `quietness` to `-40` or `-30` (more lenient)
- Decrease `duration` to `0.3` (detects shorter silence)

## How It Works

### Auto-Skip (Chapter Detection)
1. **Chapter Detection**: Watches for chapter changes during playback
2. **Pattern Matching**: Checks if chapter title matches skip patterns (Opening, Ending, etc.)
3. **Auto-Skip**: Automatically jumps to the next chapter when a match is found

### Manual Skip (Silence Detection)
1. **Audio Filter**: Adds a silence detection filter to the audio stream
2. **Fast Forward**: Plays at 100x speed with muted audio and black screen
3. **Smart Stopping**: Stops when silence is detected
4. **Fallback**: If max scan time is reached, skips +85 seconds from activation point

## Troubleshooting

**Auto-skip not working:**
- Make sure `auto_skip = true` in the script
- Check that the chapter titles match the patterns (e.g., "Opening", "OP", "Ending", "ED")
- Some anime may not have properly named chapters

**Manual button doesn't appear:**
- Make sure the script is in `[Anikku base folder]/mpv-config/scripts/chapterskip.lua`
- Restart Anikku completely
- Check that you set the button as primary in custom button settings

**Script doesn't find silence:**
- Try adjusting `quietness` and `duration` settings
- Some anime may not have silence at the end of openings
- The 85-second fallback will activate automatically

**Skips too far past the opening:**
- Increase `silence_offset` to rewind more from detected silence
- Try `silence_offset = 1.0` or higher

**Specific chapter type keeps skipping when I don't want it to:**
- Set that chapter type to `false` in the configuration
- Example: `skip_preview = false` to stop skipping preview chapters

## Credits

- Original `skiptosilence.lua` by [detuur](https://github.com/detuur/mpv-scripts) and microraptor
- Modified for Anikku by [deep-sleepy](https://github.com/deep-sleepy)
- Built for use with [Anikku](https://github.com/Hasuki69/Anikku) (MPV-based anime player)

## License

MIT License - See LICENSE file for details
