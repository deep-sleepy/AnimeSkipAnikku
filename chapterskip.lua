--[[
  * chapterskip.lua v.2025-02-02 (Modified for Anikku)
  *
  * Original AUTHORS: detuur, microraptor
  * Modified by: deep-sleepy (Jake)
  * License: MIT
  * Original: https://github.com/detuur/mpv-scripts
  * 
  * This script skips to the next silence in the file, with chapter
  * preference and fallback skip. Optimized for anime in Anikku.
  *
  * Features:
  * - Prefers embedded chapters if available
  * - Scans for silence (typical at end of openings)
  * - 3-minute max scan with +85s fallback
  * - Adjustable sensitivity settings
--]]

local opts = {
    quietness = -30,
    duration = 0.5,
    mutewhileskipping = true,
    prefer_chapters = true,
    fallback_skip = 85,
    silence_offset = 0.5,
    max_scan_duration = 180,
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

local function show_message(msg_text, time)
    mp.osd_message(msg_text, time or 2)
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

options.read_options(opts)

mp.add_key_binding(nil, "skip-to-silence", doSkip)
msg.info("chapterskip.lua loaded successfully")