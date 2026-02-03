--[[
  * chapterskip.lua v.2025-02-02 (Modified for Anikku)
  *
  * Original AUTHORS: detuur, microraptor
  * Modified by: deep-sleepy (Jake)
  * License: MIT
  * Original: https://github.com/detuur/mpv-scripts
  * 
  * This script auto-skips chapters named Opening/Ending and provides
  * manual skip with silence detection as fallback.
  *
  * Features:
  * - Auto-skip Opening and Ending chapters
  * - Manual skip button for when chapters aren't available
  * - Scans for silence as fallback
  * - 3-minute max scan with +85s fallback
--]]

local opts = {
    quietness = -50,
    duration = 0.5,
    mutewhileskipping = true,
    prefer_chapters = true,
    fallback_skip = 85,
    silence_offset = 0.5,
    max_scan_duration = 180,
    auto_skip = true,              -- Enable auto-skip for chapters
    -- Chapter skip patterns (set to false to disable)
    skip_opening = true,           -- Skip "Opening", "OP", "Intro", オープニング, 片头
    skip_ending = true,            -- Skip "Ending", "ED", "Outro", エンディング, 片尾
    skip_intro = false,            -- Skip "Intro"
    skip_outro = false,            -- Skip "Outro"
    skip_preview = true,           -- Skip "Preview", プレビュー, 预告
    skip_recap = true,             -- Skip "Recap", あらすじ, 回顾
}

local mp = require 'mp'
local msg = require 'mp.msg'
local options = require 'mp.options'

old_speed = 1
was_paused = false
was_muted = false
skipping = false
fallback_timer = nil
start_time = 0
skipped_chapters = {}

local function show_message(msg_text, time)
    mp.osd_message(msg_text, time or 2)
end

local function matches_skip_pattern(title)
    if not title then return false end
    
    -- Check each pattern type
    local patterns = {
        opening = {
            enabled = opts.skip_opening,
            patterns = {"^OP$", "^OP%d*$", "Opening", "Intro Start", "オープニング", "^片头$", "片头开始"}
        },
        ending = {
            enabled = opts.skip_ending,
            patterns = {"^ED$", "^ED%d*$", "Ending", "エンディング", "^片尾$"}
        },
        intro = {
            enabled = opts.skip_intro,
            patterns = {"^Intro$", "^Introduction$"}
        },
        outro = {
            enabled = opts.skip_outro,
            patterns = {"^Outro$"}
        },
        preview = {
            enabled = opts.skip_preview,
            patterns = {"Preview", "Next Episode", "プレビュー", "予告", "^预告$"}
        },
        recap = {
            enabled = opts.skip_recap,
            patterns = {"^Recap$", "^Previously$", "あらすじ", "^回顾$"}
        }
    }
    
    for category, data in pairs(patterns) do
        if data.enabled then
            for _, pattern in ipairs(data.patterns) do
                if string.match(title, pattern) then
                    msg.info("Matched " .. category .. " pattern: " .. pattern .. " in title: " .. title)
                    return true
                end
            end
        end
    end
    
    return false
end

local function skip_to_next_chapter()
    local chapters = mp.get_property_native("chapter-list")
    local current_chapter = mp.get_property_number("chapter")
    
    if not chapters or #chapters == 0 then
        return false
    end
    
    if not current_chapter then
        current_chapter = -1
    end
    
    local next_chapter_index = current_chapter + 1
    
    if next_chapter_index < #chapters then
        mp.set_property_number("chapter", next_chapter_index)
        local next_chapter = chapters[next_chapter_index + 1]
        show_message("Skipping to next chapter: " .. (next_chapter.title or ("Chapter " .. (next_chapter_index + 1))))
        return true
    end
    
    return false
end

function doSkip()
    -- First, try chapter skip
    if opts.prefer_chapters then
        if skip_to_next_chapter() then
            return
        else
            show_message("No chapters, scanning for silence...")
        end
    end

    -- Check for audio
    local audio_track = mp.get_property("aid")
    if not audio_track or audio_track == "no" then
        show_message("No audio stream detected")
        return
    end

    if skipping then
        -- Stop skipping if already skipping
        stopSkip()
        show_message("Stopped skipping")
        return
    end

    skipping = true
    start_time = mp.get_property_number("time-pos") or 0

    -- Get video dimensions
    local width = mp.get_property_native("width") or 1920
    local height = mp.get_property_native("height") or 1080

    -- Create audio and video filters
    mp.command(
        "no-osd af add @skiptosilence:lavfi=[silencedetect=noise=" ..
        opts.quietness .. "dB:d=" .. opts.duration .. "]"
    )
    mp.command(
        "no-osd vf add @skiptosilence-blackout:lavfi=" ..
        "[nullsink,color=c=black:s=" .. width .. "x" .. height .. "]"
    )

    -- Triggers whenever the `silencedetect` filter emits output
    mp.observe_property("af-metadata/skiptosilence", "string", foundSilence)

    was_muted = mp.get_property_native("mute")
    if opts.mutewhileskipping then
        mp.set_property_bool("mute", true)
    end

    was_paused = mp.get_property_native("pause")
    mp.set_property_bool("pause", false)
    old_speed = mp.get_property_native("speed")
    mp.set_property("speed", 100)

    -- Fallback timer: if no silence found in max_scan_duration, skip +85s
    fallback_timer = mp.add_timeout(opts.max_scan_duration, function()
        if skipping then
            mp.set_property_number("time-pos", start_time + opts.fallback_skip)
            show_message("No silence found, skipping +" .. opts.fallback_skip .. "s")
            stopSkip()
        end
    end)
end

function stopSkip()
    if not skipping then return end
    
    skipping = false
    
    if fallback_timer then
        fallback_timer:kill()
        fallback_timer = nil
    end
    
    mp.set_property_bool("mute", was_muted)
    mp.set_property_bool("pause", was_paused)
    mp.set_property("speed", old_speed)
    mp.unobserve_property(foundSilence)

    -- Remove used audio and video filters
    mp.command("no-osd af remove @skiptosilence")
    mp.command("no-osd vf remove @skiptosilence-blackout")
end

function foundSilence(name, value)
    if not skipping then return end
    
    if value == "{}" or value == nil then
        return
    end

    timecode = tonumber(string.match(value, "%d+%.?%d+"))
    time_pos = mp.get_property_native("time-pos")
    
    if timecode == nil or timecode < time_pos + 1 then
        return -- Ignore anything less than a second ahead
    end

    -- Check if we've exceeded max scan duration
    local elapsed = timecode - start_time
    if elapsed > opts.max_scan_duration then
        mp.set_property_number("time-pos", start_time + opts.fallback_skip)
        show_message("Max scan time exceeded, skipping +" .. opts.fallback_skip .. "s")
        stopSkip()
        return
    end

    -- Apply offset to prevent overshooting
    local target_time = timecode - opts.silence_offset
    
    -- Make sure we don't go backwards
    if target_time < time_pos then
        target_time = timecode
    end

    stopSkip()

    -- Seeking to the exact moment allows the video decoder to skip
    -- the missed video. This prevents massive A-V lag.
    mp.set_property_number("time-pos", target_time)

    -- Wait 50ms before messaging to display correct time-pos
    mp.add_timeout(0.05, skippedMessage)
end

function skippedMessage()
    msg.info("Skipped to silence at " .. mp.get_property_osd("time-pos"))
    mp.osd_message("Skipped to silence at " .. mp.get_property_osd("time-pos"))
end

-- Auto-skip chapters with Opening/Ending names
local function check_auto_skip()
    if not opts.auto_skip then return end
    
    local chapters = mp.get_property_native("chapter-list")
    local current_chapter = mp.get_property_number("chapter")
    
    if not chapters or not current_chapter then
        return
    end
    
    local chapter = chapters[current_chapter + 1] -- Lua arrays are 0-indexed in mpv
    if not chapter then return end
    
    -- Check if we've already skipped this chapter
    if skipped_chapters[current_chapter] then
        return
    end
    
    -- Check if chapter name matches skip patterns
    if matches_skip_pattern(chapter.title) then
        skipped_chapters[current_chapter] = true
        show_message("Auto-skipping: " .. chapter.title)
        
        -- Skip to next chapter
        if current_chapter + 1 < #chapters then
            mp.set_property_number("chapter", current_chapter + 1)
        else
            -- If no next chapter, skip to end of current chapter
            local next_time = chapters[current_chapter + 2] and chapters[current_chapter + 2].time or mp.get_property_number("duration")
            if next_time then
                mp.set_property_number("time-pos", next_time)
            end
        end
    end
end

options.read_options(opts)

mp.add_key_binding(nil, "skip-to-silence", doSkip)

-- Watch for chapter changes to auto-skip OP/ED
if opts.auto_skip then
    mp.observe_property("chapter", "number", function()
        skipped_chapters = {} -- Reset on new file
    end)
    
    mp.register_event("file-loaded", function()
        skipped_chapters = {}
    end)
    
    mp.observe_property("chapter", "number", check_auto_skip)
end

msg.info("chapterskip.lua loaded successfully")
