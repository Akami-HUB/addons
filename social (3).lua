local source_controls = {}
local ffi = require("ffi")
local color4 = color4 or function(r,g,b,a) if type(r)=="table" then return color(r.r or r[1],r.g or r[2],r.b or r[3],r.a or r[4] or 255) end return color(r,g,b,a) end
local function import_color(value)
    if type(value) == "string" then
        local hex = value:gsub("^#", ""):gsub("^0[xX]", "")
        if #hex == 6 then hex = hex .. "FF" end
        if #hex == 8 and hex:match("^%x+$") then
            local r = tonumber(hex:sub(1, 2), 16)
            local g = tonumber(hex:sub(3, 4), 16)
            local b = tonumber(hex:sub(5, 6), 16)
            local a = tonumber(hex:sub(7, 8), 16)
            if r and g and b and a then return color(r, g, b, a) end
        end
        return nil
    end
    if type(value) == "table" then
        local ok, converted = pcall(color4, value)
        if ok then return converted end
    end
    return nil
end
local clipboard = require("neverlose/clipboard");
local base64 = require("neverlose/base64");
local PAD = "\226\128\138";
local function concat(...)
    local result = "";
    for index = 1, select("#", ...) do
        result = result .. select(index, ...);
    end;
    return result;
end;
local config = {
    cheat = "nl",
    user = common.get_username(),
    name = "social",
    build = "beta"
};
local brand_name = "social";
local enums = {
    teams = {
        [1] = "Terrorist",
        [2] = "Counter-Terrorist"
    },
    states = {
        [1] = "Standing",
        [2] = "Running",
        [3] = "Walking",
        [4] = "Crouching",
        [5] = "Sneaking",
        [6] = "In Air",
        [7] = "Air Crouch"
    }
};
local icons = {};
local icon_cache = {};
do
    icons.get = function(icon_name)
        local icon = icon_cache[icon_name];
        if icon == nil then
            icon = ui.get_icon(icon_name);
            icon_cache[icon_name] = icon;
        end;
        return icon;
    end;
end;

local notifications = {};
-- Keep the established local call sites valid; notifications is the implementation.
local notify = notifications
local success_sound = "ui\\beepclear.wav";
local error_sound = "resource\\warning.wav";
local sound_player = cvar.play;
local notification_prefix = "\aA9BBFFFFsocial\a697489FF / \aC3CCDDFF";
do
    notifications.success = function(message)
        message = notification_prefix .. "\a9AFF9AFF" .. message;
        print_raw(message);
        print_dev(message);
        sound_player:call(success_sound);
    end;
    notifications.error = function(message2)
        message2 = notification_prefix .. "\aFF0032FF" .. message2;
        print_raw(message2);
        print_dev(message2);
        sound_player:call(error_sound);
    end;
end;

local function finite_number(value)
    return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

local interpolation = {};
local function linear_ease(progress, start, change)
    return start + change * progress
end
local last_realtime = nil
local function get_frame_time()
    local frame_time = tonumber(globals.frametime)
    if finite_number(frame_time) and frame_time > 0 then
        return math.min(frame_time, 0.1)
    end

    local now = tonumber(globals.realtime)
    if finite_number(now) then
        frame_time = last_realtime and (now - last_realtime) or 0
        last_realtime = now
    end
    if not finite_number(frame_time) or frame_time <= 0 then
        return 0
    end
    return math.min(frame_time, 0.1)
end
local function interpolate(easing, current, target, elapsed, duration)
    if type(current) ~= "number" or not finite_number(target) then
        return target
    end
    if elapsed <= 0 then
        return current
    end
    if not finite_number(duration) or duration <= 0 then
        return target
    end

    local progress = 1 - math.exp(-elapsed / duration)
    if type(easing) ~= "function" or easing == linear_ease then
        current = current + (target - current) * progress
    else
        current = easing(progress, current, target - current, 1)
    end
    if type(current) ~= "number" or not finite_number(current) then
        return target
    end

    local epsilon = math.max(0.0001, math.min(0.01, math.abs(target) * 0.0001))
    if math.abs(target - current) <= epsilon then
        return target
    end
    return current
end
do
    interpolation.interp = function(current, target, duration, easing)
        if type(target) == "boolean" then
            target = target and 1 or 0
        end
        return interpolate(easing or linear_ease, current, target, get_frame_time(), duration)
    end;
end;

local debug_overlay = {};
local vector_type = ffi.typeof("        struct {\n            float x, y, z;\n        }\n    ");
local color_type = ffi.typeof("        struct {\n            uint8_t r, g, b, a;\n        }\n    ");
local debug_overlay_box_fn = utils.get_vfunc("engine.dll", "VDebugOverlay004", 21, "void(__thiscall*)(void *thisptr, const $ &origin, const $ &mins, const $ &maxs, const $ &angles, $ *face_color, $ *edge_color, float duration)", vector_type, vector_type, vector_type, vector_type, color_type, color_type);
do
    debug_overlay.box_new = function(origin, mins, maxs, angles, face_color, edge_color, duration)
        origin = vector_type(origin:unpack())
        mins = vector_type(mins:unpack())
        maxs = vector_type(maxs:unpack())
        angles = vector_type(angles:unpack())
        face_color = color_type(face_color:unpack())
        edge_color = color_type(edge_color:unpack())
        debug_overlay_box_fn(origin, mins, maxs, angles, face_color, edge_color, duration)
    end
end;

local preset_manager = {};
local preset_prefix = string.format("%s::%s::", string.lower(config.name), string.lower(config.cheat));
local preset_controls = {};

do
    preset_manager.push = function(category, key, control)
        if preset_controls[category] == nil then
            preset_controls[category] = {}
        end
        preset_controls[category][key] = control
        return control
    end
    preset_manager.encode = function(value)
        local ok, encoded = pcall(json.stringify, value)
        if not ok then return false, "Invalid JSON" end

        ok, encoded = pcall(base64.encode, encoded)
        if not ok then return false, "Invalid BASE64" end

        encoded = encoded:gsub("[%+%/%=]", {
            ["="] = "_",
            ["/"] = "g2634",
            ["+"] = "g2134"
        })
        return true, preset_prefix .. encoded
    end

    preset_manager.decode = function(value)
        local name, cheat, encoded = value:match("^(%w+)::(%w+)::(.+)$")
        if name ~= string.lower(config.name) then
            return false, "Preset not supported!"
        elseif cheat ~= string.lower(config.cheat) then
            return false, "Preset for another cheat!"
        end

        encoded = encoded:gsub("[%g2134%g2634%_]", {
            g2634 = "/",
            g2134 = "+",
            _ = "="
        })

        local ok, decoded = pcall(base64.decode, encoded)
        if not ok then return false, "Invalid BASE64" end

        ok, decoded = pcall(json.parse, decoded)
        if not ok then return false, "Invalid JSON" end
        return true, decoded
    end
    preset_manager.import = function(import)
        if import == nil then
            return false, "Preset is empty!";
        elseif type(import) ~= "table" then
            return false, "Preset is not valid!";
        else
            local imported_count = 0;
            for category, controls in pairs(import) do
                local target_category = category == "Aimbot" and "Rage" or category
                local target_controls = preset_controls[target_category] or preset_controls[category]
                if target_controls ~= nil then
                    if category == "Anti-Aim" and controls["auto_lc.states"] ~= nil and controls["auto_lc.enabled"] == nil then
                        local legacy_states = controls["auto_lc.states"]
                        local enabled = type(legacy_states) == "table" and #legacy_states > 0
                        local enabled_control = target_controls["auto_lc.enabled"]
                        if enabled_control then
                            pcall(enabled_control.set, enabled_control, enabled)
                        end
                    end

                    for control, control_value in pairs(controls) do
                        local target = target_controls[control]
                        if target ~= nil then
                            if target:type() == "color_picker" then
                                local converted = import_color(control_value)
                                if converted ~= nil then
                                    control_value = converted
                                else
                                    target = nil
                                end
                            end
                            if target ~= nil then
                                pcall(target.set, target, control_value)
                            end
                        end
                    end
                    imported_count = imported_count + 1
                end
            end;
            return true, imported_count;
        end;
    end;
    preset_manager.export = function()
        local exported = {};
        for category, controls in pairs(preset_controls) do
            local group = {};
            for key, control in pairs(controls) do
                local value = control:get();
                if control:type() == "color_picker" then
                    value = value:to_hex();
                end;
                group[key] = value;
            end;
            exported[category] = group;
        end;
        return exported;
    end;
end;

local refs = {
    rage = {
        main = {
            dormant_aimbot = ui.find("Aimbot", "Ragebot", "Main", "Enabled", "Dormant Aimbot"),
            hide_shots = ui.find("Aimbot", "Ragebot", "Main", "Hide Shots"),
            hide_shots_options = ui.find("Aimbot", "Ragebot", "Main", "Hide Shots", "Options"),
            double_tap = ui.find("Aimbot", "Ragebot", "Main", "Double Tap"),
            double_tap_lag_options = ui.find("Aimbot", "Ragebot", "Main", "Double Tap", "Lag Options"),
            double_tap_fake_lag_limit = ui.find("Aimbot", "Ragebot", "Main", "Double Tap", "Fake Lag Limit"),
            peek_assist = {
                ui.find("Aimbot", "Ragebot", "Main", "Peek Assist"),
                ui.find("Aimbot", "Ragebot", "Main", "Peek Assist", "Style"),
                ui.find("Aimbot", "Ragebot", "Main", "Peek Assist", "Auto Stop"),
                ui.find("Aimbot", "Ragebot", "Main", "Peek Assist", "Retreat Mode")
            }
        },
        selection = {
            hit_chance = ui.find("Aimbot", "Ragebot", "Selection", "Hit Chance"),
            min_damage = ui.find("Aimbot", "Ragebot", "Selection", "Min. Damage"),
            multipoint_scale = {
                ui.find("Aimbot", "Ragebot", "Selection", "Multipoint", "Head Scale"),
                ui.find("Aimbot", "Ragebot", "Selection", "Multipoint", "Body Scale")
            }
        },
        safety = {
            body_aim = ui.find("Aimbot", "Ragebot", "Safety", "Body Aim"),
            safe_points = ui.find("Aimbot", "Ragebot", "Safety", "Safe Points")
        }
    },
    antiaim = {
        angles = {
            enabled = ui.find("Aimbot", "Anti Aim", "Angles", "Enabled"),
            pitch = ui.find("Aimbot", "Anti Aim", "Angles", "Pitch"),
            yaw = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw"),
            yaw_base = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw", "Base"),
            yaw_offset = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw", "Offset"),
            avoid_backstab = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw", "Avoid Backstab"),
            hidden = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw", "Hidden"),
            yaw_modifier = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw Modifier"),
            modifier_offset = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw Modifier", "Offset"),
            body_yaw = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw"),
            inverter = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Inverter"),
            left_limit = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Left Limit"),
            right_limit = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Right Limit"),
            options = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Options"),
            freestanding_body_yaw = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Freestanding"),
            freestanding = ui.find("Aimbot", "Anti Aim", "Angles", "Freestanding"),
            disable_yaw_modifiers = ui.find("Aimbot", "Anti Aim", "Angles", "Freestanding", "Disable Yaw Modifiers"),
            body_freestanding = ui.find("Aimbot", "Anti Aim", "Angles", "Freestanding", "Body Freestanding"),
            extended_angles = ui.find("Aimbot", "Anti Aim", "Angles", "Extended Angles"),
            extended_pitch = ui.find("Aimbot", "Anti Aim", "Angles", "Extended Angles", "Extended Pitch"),
            extended_roll = ui.find("Aimbot", "Anti Aim", "Angles", "Extended Angles", "Extended Roll")
        },
        fake_lag = {
            enabled = ui.find("Aimbot", "Anti Aim", "Fake Lag", "Enabled"),
            limit = ui.find("Aimbot", "Anti Aim", "Fake Lag", "Limit"),
            variability = ui.find("Aimbot", "Anti Aim", "Fake Lag", "Variability")
        },
        misc = {
            fake_duck = ui.find("Aimbot", "Anti Aim", "Misc", "Fake Duck"),
            slow_walk = ui.find("Aimbot", "Anti Aim", "Misc", "Slow Walk"),
            leg_movement = ui.find("Aimbot", "Anti Aim", "Misc", "Leg Movement")
        }
    },
    visuals = {
        world = {
            main = {
                scope_overlay = ui.find("Visuals", "World", "Main", "Override Zoom", "Scope Overlay")
            }
        }
    },
    misc = {
        main = {
            in_game = {
                clan_tag = ui.find("Miscellaneous", "Main", "In-Game", "Clan Tag")
            },
            other = {
                windows = ui.find("Miscellaneous", "Main", "Other", "Windows"),
                log_events = ui.find("Miscellaneous", "Main", "Other", "Log Events"),
                fake_latency = ui.find("Miscellaneous", "Main", "Other", "Fake Latency")
            }
        }
    }
};

local ui_controls = {};
local pad_spaces = function(pad)
    return string.rep(PAD, pad);
end;
local function padded_label(label, padding)
    local pad = string.rep(PAD, padding)
    return pad .. label .. pad
end
local function hidden_label(label, id)
    if not string.find(label, "##", 1, true) then
        label = label .. "##"
    end
    return label .. id
end
local small_label_cache = {}
local function icon_label(name)
    local cached = small_label_cache[name]
    if cached then return cached end
    local glyph = icons.get(name) or "•"
    local glyph_width = 0
    local ok, measured = pcall(render.measure_text, 2, nil, glyph)
    if ok and measured and measured.x then glyph_width = measured.x end

    local spacing = math.max(0, math.min(8, math.ceil((16 - glyph_width) / 2.2)))
    cached = concat("\a{Small Text}", glyph, string.rep(PAD, spacing), "\aDEFAULT")
    small_label_cache[name] = cached
    return cached
end;
do
    local function section_label(text, tint)
        return concat(pad_spaces(1), tint or "\a{Small Text}", "\226\128\162", "\aDEFAULT", pad_spaces(5), text)
    end

    local function ensure_defaults(control)
        local selected = control:get()
        local items = control:list()
        local kind = control:type()
        local defaults = {}

        if #selected == 0 then
            if kind == "selectable" then
                defaults = items
            elseif kind == "listable" then
                for i = 1, #items do
                    defaults[i] = items[i]
                end
            end
            control:set(defaults)
        end
    end
    local home_tab = {};
    local home_icon = icons.get("house");
    local home_containers = {
        profile = ui.create(home_icon, "##profile", 1),
        presets = ui.create(home_icon, "##presets", 2)
    };
    home_tab.profile = {};
    local presets_tab = {}
    local presets_ui = {}
    local presets_db_key = string.lower(config.name) .. "#data"
    local saved_presets = db[presets_db_key] or {}
    if type(saved_presets) ~= "table" then saved_presets = {} end
    local preset_list = {}
    local builtin_presets = {}
    local builtin_ui = {}
    do
        local function add_builtin(name, data)
            builtin_presets[#builtin_presets + 1] = {
                name = name,
                data = data
            }
        end
            add_builtin("Dev", "social::nl::eyJBbnRpLUFpbSI6eyJDb3VudGVyLVRlcnJvcmlzdDpBaXIgQ3JvdWNoOmJvZHlfeWF3IjoiRGlzYWJsZWQiLCJDb3VudGVyLVRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlZmVuc2l2ZV9jaG9rZV8xIjoxNi4wLCJDb3VudGVyLVRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlZmVuc2l2ZV9jaG9rZV8yIjoxNi4wLCJDb3VudGVyLVRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlZmVuc2l2ZV9jdXN0b21fY2hva2UiOmZhbHNlLCJDb3VudGVyLVRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlZmVuc2l2ZV9lbmFibGVkIjpmYWxzZSwiQ291bnRlci1UZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfZm9yY2VfZGVmZW5zaXZlIjpmYWxzZSwiQ291bnRlci1UZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfcGl0Y2giOiJTdGF0aWMiLCJDb3VudGVyLVRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlZmVuc2l2ZV9waXRjaF8xIjotODkuMCwiQ291bnRlci1UZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfcGl0Y2hfMiI6ODkuMCwiQ291bnRlci1UZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfcGl0Y2hfb2Zmc2V0IjotODkuMCwiQ291bnRlci1UZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfcmFuZG9tX2Nob2tlIjpmYWxzZSwiQ291bnRlci1UZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfcmFuZG9taXphdGlvbiI6NC4wLCJDb3VudGVyLVRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlZmVuc2l2ZV95YXciOiJTcGluIiwiQ291bnRlci1UZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfeWF3XzEiOi0xMDEuMCwiQ291bnRlci1UZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfeWF3XzIiOjEwMS4wLCJDb3VudGVyLVRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlZmVuc2l2ZV95YXdfb2Zmc2V0IjoxODAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfeWF3X3NwZWVkIjoyMC4wLCJDb3VudGVyLVRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlbGF5XzEiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWxheV8yIjowLjAsIkNvdW50ZXItVGVycm9yaXN0OkFpciBDcm91Y2g6bGVmdF9saW1pdCI6NjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6QWlyIENyb3VjaDptb2RpZmllcl9vZmZzZXQiOi0yNS4wLCJDb3VudGVyLVRlcnJvcmlzdDpBaXIgQ3JvdWNoOnJpZ2h0X2xpbWl0Ijo2MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpBaXIgQ3JvdWNoOnlhd19hZGQiOnRydWUsIkNvdW50ZXItVGVycm9yaXN0OkFpciBDcm91Y2g6eWF3X2xlZnQiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6QWlyIENyb3VjaDp5YXdfbW9kaWZpZXIiOiJDZW50ZXIiLCJDb3VudGVyLVRlcnJvcmlzdDpBaXIgQ3JvdWNoOnlhd19vZmZzZXQiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6QWlyIENyb3VjaDp5YXdfcmlnaHQiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6Q3JvdWNoaW5nOmJvZHlfeWF3IjoiSml0dGVyIiwiQ291bnRlci1UZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlZmVuc2l2ZV9jaG9rZV8xIjoxNi4wLCJDb3VudGVyLVRlcnJvcmlzdDpDcm91Y2hpbmc6ZGVmZW5zaXZlX2Nob2tlXzIiOjE2LjAsIkNvdW50ZXItVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfY3VzdG9tX2Nob2tlIjpmYWxzZSwiQ291bnRlci1UZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlZmVuc2l2ZV9lbmFibGVkIjpmYWxzZSwiQ291bnRlci1UZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlZmVuc2l2ZV9mb3JjZV9kZWZlbnNpdmUiOmZhbHNlLCJDb3VudGVyLVRlcnJvcmlzdDpDcm91Y2hpbmc6ZGVmZW5zaXZlX3BpdGNoIjoiU3dheSIsIkNvdW50ZXItVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfcGl0Y2hfMSI6LTg5LjAsIkNvdW50ZXItVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfcGl0Y2hfMiI6ODkuMCwiQ291bnRlci1UZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlZmVuc2l2ZV9waXRjaF9vZmZzZXQiOi04OS4wLCJDb3VudGVyLVRlcnJvcmlzdDpDcm91Y2hpbmc6ZGVmZW5zaXZlX3JhbmRvbV9jaG9rZSI6ZmFsc2UsIkNvdW50ZXItVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfcmFuZG9taXphdGlvbiI6NC4wLCJDb3VudGVyLVRlcnJvcmlzdDpDcm91Y2hpbmc6ZGVmZW5zaXZlX3lhdyI6IlNwaW4iLCJDb3VudGVyLVRlcnJvcmlzdDpDcm91Y2hpbmc6ZGVmZW5zaXZlX3lhd18xIjotMTAxLjAsIkNvdW50ZXItVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfeWF3XzIiOjEwMS4wLCJDb3VudGVyLVRlcnJvcmlzdDpDcm91Y2hpbmc6ZGVmZW5zaXZlX3lhd19vZmZzZXQiOjE4MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpDcm91Y2hpbmc6ZGVmZW5zaXZlX3lhd19zcGVlZCI6MjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlbGF5XzEiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlbGF5XzIiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6Q3JvdWNoaW5nOmxlZnRfbGltaXQiOjYwLjAsIkNvdW50ZXItVGVycm9yaXN0OkNyb3VjaGluZzptb2RpZmllcl9vZmZzZXQiOi0zNS4wLCJDb3VudGVyLVRlcnJvcmlzdDpDcm91Y2hpbmc6cmlnaHRfbGltaXQiOjYwLjAsIkNvdW50ZXItVGVycm9yaXN0OkNyb3VjaGluZzp5YXdfYWRkIjp0cnVlLCJDb3VudGVyLVRlcnJvcmlzdDpDcm91Y2hpbmc6eWF3X2xlZnQiOi0zMS4wLCJDb3VudGVyLVRlcnJvcmlzdDpDcm91Y2hpbmc6eWF3X21vZGlmaWVyIjoiRGlzYWJsZWQiLCJDb3VudGVyLVRlcnJvcmlzdDpDcm91Y2hpbmc6eWF3X29mZnNldCI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpDcm91Y2hpbmc6eWF3X3JpZ2h0Ijo0NS4wLCJDb3VudGVyLVRlcnJvcmlzdDpJbiBBaXI6Ym9keV95YXciOiJEaXNhYmxlZCIsIkNvdW50ZXItVGVycm9yaXN0OkluIEFpcjpkZWZlbnNpdmVfY2hva2VfMSI6MTYuMCwiQ291bnRlci1UZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV9jaG9rZV8yIjoxNi4wLCJDb3VudGVyLVRlcnJvcmlzdDpJbiBBaXI6ZGVmZW5zaXZlX2N1c3RvbV9jaG9rZSI6ZmFsc2UsIkNvdW50ZXItVGVycm9yaXN0OkluIEFpcjpkZWZlbnNpdmVfZW5hYmxlZCI6ZmFsc2UsIkNvdW50ZXItVGVycm9yaXN0OkluIEFpcjpkZWZlbnNpdmVfZm9yY2VfZGVmZW5zaXZlIjpmYWxzZSwiQ291bnRlci1UZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV9waXRjaCI6IlN3YXkiLCJDb3VudGVyLVRlcnJvcmlzdDpJbiBBaXI6ZGVmZW5zaXZlX3BpdGNoXzEiOi04OS4wLCJDb3VudGVyLVRlcnJvcmlzdDpJbiBBaXI6ZGVmZW5zaXZlX3BpdGNoXzIiOjg5LjAsIkNvdW50ZXItVGVycm9yaXN0OkluIEFpcjpkZWZlbnNpdmVfcGl0Y2hfb2Zmc2V0IjotODkuMCwiQ291bnRlci1UZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV9yYW5kb21fY2hva2UiOmZhbHNlLCJDb3VudGVyLVRlcnJvcmlzdDpJbiBBaXI6ZGVmZW5zaXZlX3JhbmRvbWl6YXRpb24iOjQuMCwiQ291bnRlci1UZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV95YXciOiJTcGluIiwiQ291bnRlci1UZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV95YXdfMSI6LTEwMS4wLCJDb3VudGVyLVRlcnJvcmlzdDpJbiBBaXI6ZGVmZW5zaXZlX3lhd18yIjoxMDEuMCwiQ291bnRlci1UZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV95YXdfb2Zmc2V0IjoxODAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV95YXdfc3BlZWQiOjIwLjAsIkNvdW50ZXItVGVycm9yaXN0OkluIEFpcjpkZWxheV8xIjowLjAsIkNvdW50ZXItVGVycm9yaXN0OkluIEFpcjpkZWxheV8yIjowLjAsIkNvdW50ZXItVGVycm9yaXN0OkluIEFpcjpsZWZ0X2xpbWl0Ijo2MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpJbiBBaXI6bW9kaWZpZXJfb2Zmc2V0IjotMzUuMCwiQ291bnRlci1UZXJyb3Jpc3Q6SW4gQWlyOnJpZ2h0X2xpbWl0Ijo2MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpJbiBBaXI6eWF3X2FkZCI6dHJ1ZSwiQ291bnRlci1UZXJyb3Jpc3Q6SW4gQWlyOnlhd19sZWZ0IjowLjAsIkNvdW50ZXItVGVycm9yaXN0OkluIEFpcjp5YXdfbW9kaWZpZXIiOiJDZW50ZXIiLCJDb3VudGVyLVRlcnJvcmlzdDpJbiBBaXI6eWF3X29mZnNldCI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpJbiBBaXI6eWF3X3JpZ2h0IjowLjAsIkNvdW50ZXItVGVycm9yaXN0OlJ1bm5pbmc6Ym9keV95YXciOiJEaXNhYmxlZCIsIkNvdW50ZXItVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX2Nob2tlXzEiOjE2LjAsIkNvdW50ZXItVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX2Nob2tlXzIiOjE2LjAsIkNvdW50ZXItVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX2N1c3RvbV9jaG9rZSI6ZmFsc2UsIkNvdW50ZXItVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX2VuYWJsZWQiOmZhbHNlLCJDb3VudGVyLVRlcnJvcmlzdDpSdW5uaW5nOmRlZmVuc2l2ZV9mb3JjZV9kZWZlbnNpdmUiOmZhbHNlLCJDb3VudGVyLVRlcnJvcmlzdDpSdW5uaW5nOmRlZmVuc2l2ZV9waXRjaCI6IlN0YXRpYyIsIkNvdW50ZXItVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX3BpdGNoXzEiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6UnVubmluZzpkZWZlbnNpdmVfcGl0Y2hfMiI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpSdW5uaW5nOmRlZmVuc2l2ZV9waXRjaF9vZmZzZXQiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6UnVubmluZzpkZWZlbnNpdmVfcmFuZG9tX2Nob2tlIjpmYWxzZSwiQ291bnRlci1UZXJyb3Jpc3Q6UnVubmluZzpkZWZlbnNpdmVfcmFuZG9taXphdGlvbiI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpSdW5uaW5nOmRlZmVuc2l2ZV95YXciOiJTdGF0aWMiLCJDb3VudGVyLVRlcnJvcmlzdDpSdW5uaW5nOmRlZmVuc2l2ZV95YXdfMSI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpSdW5uaW5nOmRlZmVuc2l2ZV95YXdfMiI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpSdW5uaW5nOmRlZmVuc2l2ZV95YXdfb2Zmc2V0IjoxODAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6UnVubmluZzpkZWZlbnNpdmVfeWF3X3NwZWVkIjoyMC4wLCJDb3VudGVyLVRlcnJvcmlzdDpSdW5uaW5nOmRlbGF5XzEiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6UnVubmluZzpkZWxheV8yIjowLjAsIkNvdW50ZXItVGVycm9yaXN0OlJ1bm5pbmc6bGVmdF9saW1pdCI6MzAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6UnVubmluZzptb2RpZmllcl9vZmZzZXQiOi02MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpSdW5uaW5nOnJpZ2h0X2xpbWl0IjozMC4wLCJDb3VudGVyLVRlcnJvcmlzdDpSdW5uaW5nOnlhd19hZGQiOnRydWUsIkNvdW50ZXItVGVycm9yaXN0OlJ1bm5pbmc6eWF3X2xlZnQiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6UnVubmluZzp5YXdfbW9kaWZpZXIiOiJDZW50ZXIiLCJDb3VudGVyLVRlcnJvcmlzdDpSdW5uaW5nOnlhd19vZmZzZXQiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6UnVubmluZzp5YXdfcmlnaHQiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U25lYWtpbmc6Ym9keV95YXciOiJKaXR0ZXIiLCJDb3VudGVyLVRlcnJvcmlzdDpTbmVha2luZzpkZWZlbnNpdmVfY2hva2VfMSI6MTYuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX2Nob2tlXzIiOjE2LjAsIkNvdW50ZXItVGVycm9yaXN0OlNuZWFraW5nOmRlZmVuc2l2ZV9jdXN0b21fY2hva2UiOmZhbHNlLCJDb3VudGVyLVRlcnJvcmlzdDpTbmVha2luZzpkZWZlbnNpdmVfZW5hYmxlZCI6ZmFsc2UsIkNvdW50ZXItVGVycm9yaXN0OlNuZWFraW5nOmRlZmVuc2l2ZV9mb3JjZV9kZWZlbnNpdmUiOmZhbHNlLCJDb3VudGVyLVRlcnJvcmlzdDpTbmVha2luZzpkZWZlbnNpdmVfcGl0Y2giOiJTd2F5IiwiQ291bnRlci1UZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX3BpdGNoXzEiOi04OS4wLCJDb3VudGVyLVRlcnJvcmlzdDpTbmVha2luZzpkZWZlbnNpdmVfcGl0Y2hfMiI6ODkuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX3BpdGNoX29mZnNldCI6LTg5LjAsIkNvdW50ZXItVGVycm9yaXN0OlNuZWFraW5nOmRlZmVuc2l2ZV9yYW5kb21fY2hva2UiOmZhbHNlLCJDb3VudGVyLVRlcnJvcmlzdDpTbmVha2luZzpkZWZlbnNpdmVfcmFuZG9taXphdGlvbiI6NC4wLCJDb3VudGVyLVRlcnJvcmlzdDpTbmVha2luZzpkZWZlbnNpdmVfeWF3IjoiU3BpbiIsIkNvdW50ZXItVGVycm9yaXN0OlNuZWFraW5nOmRlZmVuc2l2ZV95YXdfMSI6LTEwMS4wLCJDb3VudGVyLVRlcnJvcmlzdDpTbmVha2luZzpkZWZlbnNpdmVfeWF3XzIiOjEwMS4wLCJDb3VudGVyLVRlcnJvcmlzdDpTbmVha2luZzpkZWZlbnNpdmVfeWF3X29mZnNldCI6MTgwLjAsIkNvdW50ZXItVGVycm9yaXN0OlNuZWFraW5nOmRlZmVuc2l2ZV95YXdfc3BlZWQiOjIwLjAsIkNvdW50ZXItVGVycm9yaXN0OlNuZWFraW5nOmRlbGF5XzEiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U25lYWtpbmc6ZGVsYXlfMiI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpTbmVha2luZzpsZWZ0X2xpbWl0Ijo2MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpTbmVha2luZzptb2RpZmllcl9vZmZzZXQiOi0zNS4wLCJDb3VudGVyLVRlcnJvcmlzdDpTbmVha2luZzpyaWdodF9saW1pdCI6NjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U25lYWtpbmc6eWF3X2FkZCI6dHJ1ZSwiQ291bnRlci1UZXJyb3Jpc3Q6U25lYWtpbmc6eWF3X2xlZnQiOi0zMS4wLCJDb3VudGVyLVRlcnJvcmlzdDpTbmVha2luZzp5YXdfbW9kaWZpZXIiOiJEaXNhYmxlZCIsIkNvdW50ZXItVGVycm9yaXN0OlNuZWFraW5nOnlhd19vZmZzZXQiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U25lYWtpbmc6eWF3X3JpZ2h0Ijo0NS4wLCJDb3VudGVyLVRlcnJvcmlzdDpTdGFuZGluZzpib2R5X3lhdyI6IkppdHRlciIsIkNvdW50ZXItVGVycm9yaXN0OlN0YW5kaW5nOmRlZmVuc2l2ZV9jaG9rZV8xIjo0LjAsIkNvdW50ZXItVGVycm9yaXN0OlN0YW5kaW5nOmRlZmVuc2l2ZV9jaG9rZV8yIjoxMi4wLCJDb3VudGVyLVRlcnJvcmlzdDpTdGFuZGluZzpkZWZlbnNpdmVfY3VzdG9tX2Nob2tlIjp0cnVlLCJDb3VudGVyLVRlcnJvcmlzdDpTdGFuZGluZzpkZWZlbnNpdmVfZW5hYmxlZCI6ZmFsc2UsIkNvdW50ZXItVGVycm9yaXN0OlN0YW5kaW5nOmRlZmVuc2l2ZV9mb3JjZV9kZWZlbnNpdmUiOmZhbHNlLCJDb3VudGVyLVRlcnJvcmlzdDpTdGFuZGluZzpkZWZlbnNpdmVfcGl0Y2giOiJTdGF0aWMiLCJDb3VudGVyLVRlcnJvcmlzdDpTdGFuZGluZzpkZWZlbnNpdmVfcGl0Y2hfMSI6LTU1LjAsIkNvdW50ZXItVGVycm9yaXN0OlN0YW5kaW5nOmRlZmVuc2l2ZV9waXRjaF8yIjo1NS4wLCJDb3VudGVyLVRlcnJvcmlzdDpTdGFuZGluZzpkZWZlbnNpdmVfcGl0Y2hfb2Zmc2V0IjotODkuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX3JhbmRvbV9jaG9rZSI6dHJ1ZSwiQ291bnRlci1UZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX3JhbmRvbWl6YXRpb24iOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX3lhdyI6IlNwaW4iLCJDb3VudGVyLVRlcnJvcmlzdDpTdGFuZGluZzpkZWZlbnNpdmVfeWF3XzEiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX3lhd18yIjowLjAsIkNvdW50ZXItVGVycm9yaXN0OlN0YW5kaW5nOmRlZmVuc2l2ZV95YXdfb2Zmc2V0IjoxODAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX3lhd19zcGVlZCI6NTAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVsYXlfMSI6MS4wLCJDb3VudGVyLVRlcnJvcmlzdDpTdGFuZGluZzpkZWxheV8yIjowLjAsIkNvdW50ZXItVGVycm9yaXN0OlN0YW5kaW5nOmxlZnRfbGltaXQiOjMwLjAsIkNvdW50ZXItVGVycm9yaXN0OlN0YW5kaW5nOm1vZGlmaWVyX29mZnNldCI6LTQ2LjAsIkNvdW50ZXItVGVycm9yaXN0OlN0YW5kaW5nOnJpZ2h0X2xpbWl0IjozMC4wLCJDb3VudGVyLVRlcnJvcmlzdDpTdGFuZGluZzp5YXdfYWRkIjp0cnVlLCJDb3VudGVyLVRlcnJvcmlzdDpTdGFuZGluZzp5YXdfbGVmdCI6LTMwLjAsIkNvdW50ZXItVGVycm9yaXN0OlN0YW5kaW5nOnlhd19tb2RpZmllciI6IkRpc2FibGVkIiwiQ291bnRlci1UZXJyb3Jpc3Q6U3RhbmRpbmc6eWF3X29mZnNldCI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpTdGFuZGluZzp5YXdfcmlnaHQiOjM0LjAsIkNvdW50ZXItVGVycm9yaXN0OldhbGtpbmc6Ym9keV95YXciOiJEaXNhYmxlZCIsIkNvdW50ZXItVGVycm9yaXN0OldhbGtpbmc6ZGVmZW5zaXZlX2Nob2tlXzEiOjQuMCwiQ291bnRlci1UZXJyb3Jpc3Q6V2Fsa2luZzpkZWZlbnNpdmVfY2hva2VfMiI6Ny4wLCJDb3VudGVyLVRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV9jdXN0b21fY2hva2UiOnRydWUsIkNvdW50ZXItVGVycm9yaXN0OldhbGtpbmc6ZGVmZW5zaXZlX2VuYWJsZWQiOmZhbHNlLCJDb3VudGVyLVRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV9mb3JjZV9kZWZlbnNpdmUiOnRydWUsIkNvdW50ZXItVGVycm9yaXN0OldhbGtpbmc6ZGVmZW5zaXZlX3BpdGNoIjoiU3dheSIsIkNvdW50ZXItVGVycm9yaXN0OldhbGtpbmc6ZGVmZW5zaXZlX3BpdGNoXzEiOi04OS4wLCJDb3VudGVyLVRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV9waXRjaF8yIjo4OS4wLCJDb3VudGVyLVRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV9waXRjaF9vZmZzZXQiOi04OS4wLCJDb3VudGVyLVRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV9yYW5kb21fY2hva2UiOnRydWUsIkNvdW50ZXItVGVycm9yaXN0OldhbGtpbmc6ZGVmZW5zaXZlX3JhbmRvbWl6YXRpb24iOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6V2Fsa2luZzpkZWZlbnNpdmVfeWF3IjoiU3dheSIsIkNvdW50ZXItVGVycm9yaXN0OldhbGtpbmc6ZGVmZW5zaXZlX3lhd18xIjotOTAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6V2Fsa2luZzpkZWZlbnNpdmVfeWF3XzIiOjkwLjAsIkNvdW50ZXItVGVycm9yaXN0OldhbGtpbmc6ZGVmZW5zaXZlX3lhd19vZmZzZXQiOjM2MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV95YXdfc3BlZWQiOjIwLjAsIkNvdW50ZXItVGVycm9yaXN0OldhbGtpbmc6ZGVsYXlfMSI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpXYWxraW5nOmRlbGF5XzIiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6V2Fsa2luZzpsZWZ0X2xpbWl0Ijo1OC4wLCJDb3VudGVyLVRlcnJvcmlzdDpXYWxraW5nOm1vZGlmaWVyX29mZnNldCI6LTQ0LjAsIkNvdW50ZXItVGVycm9yaXN0OldhbGtpbmc6cmlnaHRfbGltaXQiOjU4LjAsIkNvdW50ZXItVGVycm9yaXN0OldhbGtpbmc6eWF3X2FkZCI6dHJ1ZSwiQ291bnRlci1UZXJyb3Jpc3Q6V2Fsa2luZzp5YXdfbGVmdCI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpXYWxraW5nOnlhd19tb2RpZmllciI6IkNlbnRlciIsIkNvdW50ZXItVGVycm9yaXN0OldhbGtpbmc6eWF3X29mZnNldCI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpXYWxraW5nOnlhd19yaWdodCI6MC4wLCJUZXJyb3Jpc3Q6QWlyIENyb3VjaDpib2R5X3lhdyI6IkppdHRlciIsIlRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlZmVuc2l2ZV9jaG9rZV8xIjoxNi4wLCJUZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfY2hva2VfMiI6MTYuMCwiVGVycm9yaXN0OkFpciBDcm91Y2g6ZGVmZW5zaXZlX2N1c3RvbV9jaG9rZSI6ZmFsc2UsIlRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlZmVuc2l2ZV9lbmFibGVkIjpmYWxzZSwiVGVycm9yaXN0OkFpciBDcm91Y2g6ZGVmZW5zaXZlX2ZvcmNlX2RlZmVuc2l2ZSI6ZmFsc2UsIlRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlZmVuc2l2ZV9waXRjaCI6IlN0YXRpYyIsIlRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlZmVuc2l2ZV9waXRjaF8xIjotODkuMCwiVGVycm9yaXN0OkFpciBDcm91Y2g6ZGVmZW5zaXZlX3BpdGNoXzIiOjg5LjAsIlRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlZmVuc2l2ZV9waXRjaF9vZmZzZXQiOi04OS4wLCJUZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfcmFuZG9tX2Nob2tlIjpmYWxzZSwiVGVycm9yaXN0OkFpciBDcm91Y2g6ZGVmZW5zaXZlX3JhbmRvbWl6YXRpb24iOjQuMCwiVGVycm9yaXN0OkFpciBDcm91Y2g6ZGVmZW5zaXZlX3lhdyI6IlNwaW4iLCJUZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfeWF3XzEiOi0xMDEuMCwiVGVycm9yaXN0OkFpciBDcm91Y2g6ZGVmZW5zaXZlX3lhd18yIjoxMDEuMCwiVGVycm9yaXN0OkFpciBDcm91Y2g6ZGVmZW5zaXZlX3lhd19vZmZzZXQiOjE4MC4wLCJUZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfeWF3X3NwZWVkIjoyMC4wLCJUZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWxheV8xIjoxLjAsIlRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlbGF5XzIiOjAuMCwiVGVycm9yaXN0OkFpciBDcm91Y2g6bGVmdF9saW1pdCI6NjAuMCwiVGVycm9yaXN0OkFpciBDcm91Y2g6bW9kaWZpZXJfb2Zmc2V0IjotMzUuMCwiVGVycm9yaXN0OkFpciBDcm91Y2g6cmlnaHRfbGltaXQiOjYwLjAsIlRlcnJvcmlzdDpBaXIgQ3JvdWNoOnlhd19hZGQiOnRydWUsIlRlcnJvcmlzdDpBaXIgQ3JvdWNoOnlhd19sZWZ0IjotMzEuMCwiVGVycm9yaXN0OkFpciBDcm91Y2g6eWF3X21vZGlmaWVyIjoiRGlzYWJsZWQiLCJUZXJyb3Jpc3Q6QWlyIENyb3VjaDp5YXdfb2Zmc2V0IjowLjAsIlRlcnJvcmlzdDpBaXIgQ3JvdWNoOnlhd19yaWdodCI6NDUuMCwiVGVycm9yaXN0OkNyb3VjaGluZzpib2R5X3lhdyI6IkppdHRlciIsIlRlcnJvcmlzdDpDcm91Y2hpbmc6ZGVmZW5zaXZlX2Nob2tlXzEiOjE2LjAsIlRlcnJvcmlzdDpDcm91Y2hpbmc6ZGVmZW5zaXZlX2Nob2tlXzIiOjE2LjAsIlRlcnJvcmlzdDpDcm91Y2hpbmc6ZGVmZW5zaXZlX2N1c3RvbV9jaG9rZSI6ZmFsc2UsIlRlcnJvcmlzdDpDcm91Y2hpbmc6ZGVmZW5zaXZlX2VuYWJsZWQiOmZhbHNlLCJUZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlZmVuc2l2ZV9mb3JjZV9kZWZlbnNpdmUiOmZhbHNlLCJUZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlZmVuc2l2ZV9waXRjaCI6IlN3YXkiLCJUZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlZmVuc2l2ZV9waXRjaF8xIjotODkuMCwiVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfcGl0Y2hfMiI6ODkuMCwiVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfcGl0Y2hfb2Zmc2V0IjotODkuMCwiVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfcmFuZG9tX2Nob2tlIjpmYWxzZSwiVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfcmFuZG9taXphdGlvbiI6NC4wLCJUZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlZmVuc2l2ZV95YXciOiJTcGluIiwiVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfeWF3XzEiOi0xMDEuMCwiVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfeWF3XzIiOjEwMS4wLCJUZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlZmVuc2l2ZV95YXdfb2Zmc2V0IjoxODAuMCwiVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfeWF3X3NwZWVkIjoyMC4wLCJUZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlbGF5XzEiOjAuMCwiVGVycm9yaXN0OkNyb3VjaGluZzpkZWxheV8yIjowLjAsIlRlcnJvcmlzdDpDcm91Y2hpbmc6bGVmdF9saW1pdCI6NjAuMCwiVGVycm9yaXN0OkNyb3VjaGluZzptb2RpZmllcl9vZmZzZXQiOi0zNS4wLCJUZXJyb3Jpc3Q6Q3JvdWNoaW5nOnJpZ2h0X2xpbWl0Ijo2MC4wLCJUZXJyb3Jpc3Q6Q3JvdWNoaW5nOnlhd19hZGQiOnRydWUsIlRlcnJvcmlzdDpDcm91Y2hpbmc6eWF3X2xlZnQiOi0zMS4wLCJUZXJyb3Jpc3Q6Q3JvdWNoaW5nOnlhd19tb2RpZmllciI6IkRpc2FibGVkIiwiVGVycm9yaXN0OkNyb3VjaGluZzp5YXdfb2Zmc2V0IjowLjAsIlRlcnJvcmlzdDpDcm91Y2hpbmc6eWF3X3JpZ2h0Ijo0NS4wLCJUZXJyb3Jpc3Q6SW4gQWlyOmJvZHlfeWF3IjoiSml0dGVyIiwiVGVycm9yaXN0OkluIEFpcjpkZWZlbnNpdmVfY2hva2VfMSI6MS4wLCJUZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV9jaG9rZV8yIjoyMi4wLCJUZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV9jdXN0b21fY2hva2UiOnRydWUsIlRlcnJvcmlzdDpJbiBBaXI6ZGVmZW5zaXZlX2VuYWJsZWQiOmZhbHNlLCJUZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV9mb3JjZV9kZWZlbnNpdmUiOmZhbHNlLCJUZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV9waXRjaCI6IlN3YXkiLCJUZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV9waXRjaF8xIjotODkuMCwiVGVycm9yaXN0OkluIEFpcjpkZWZlbnNpdmVfcGl0Y2hfMiI6ODkuMCwiVGVycm9yaXN0OkluIEFpcjpkZWZlbnNpdmVfcGl0Y2hfb2Zmc2V0IjotODkuMCwiVGVycm9yaXN0OkluIEFpcjpkZWZlbnNpdmVfcmFuZG9tX2Nob2tlIjp0cnVlLCJUZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV9yYW5kb21pemF0aW9uIjo0LjAsIlRlcnJvcmlzdDpJbiBBaXI6ZGVmZW5zaXZlX3lhdyI6IlNwaW4iLCJUZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV95YXdfMSI6LTEwMS4wLCJUZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV95YXdfMiI6MTAxLjAsIlRlcnJvcmlzdDpJbiBBaXI6ZGVmZW5zaXZlX3lhd19vZmZzZXQiOjE4MC4wLCJUZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV95YXdfc3BlZWQiOjIwLjAsIlRlcnJvcmlzdDpJbiBBaXI6ZGVsYXlfMSI6MC4wLCJUZXJyb3Jpc3Q6SW4gQWlyOmRlbGF5XzIiOjAuMCwiVGVycm9yaXN0OkluIEFpcjpsZWZ0X2xpbWl0Ijo2MC4wLCJUZXJyb3Jpc3Q6SW4gQWlyOm1vZGlmaWVyX29mZnNldCI6LTY1LjAsIlRlcnJvcmlzdDpJbiBBaXI6cmlnaHRfbGltaXQiOjYwLjAsIlRlcnJvcmlzdDpJbiBBaXI6eWF3X2FkZCI6dHJ1ZSwiVGVycm9yaXN0OkluIEFpcjp5YXdfbGVmdCI6LTMxLjAsIlRlcnJvcmlzdDpJbiBBaXI6eWF3X21vZGlmaWVyIjoiRGlzYWJsZWQiLCJUZXJyb3Jpc3Q6SW4gQWlyOnlhd19vZmZzZXQiOjAuMCwiVGVycm9yaXN0OkluIEFpcjp5YXdfcmlnaHQiOjQ1LjAsIlRlcnJvcmlzdDpSdW5uaW5nOmJvZHlfeWF3IjoiRGlzYWJsZWQiLCJUZXJyb3Jpc3Q6UnVubmluZzpkZWZlbnNpdmVfY2hva2VfMSI6MTYuMCwiVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX2Nob2tlXzIiOjE2LjAsIlRlcnJvcmlzdDpSdW5uaW5nOmRlZmVuc2l2ZV9jdXN0b21fY2hva2UiOmZhbHNlLCJUZXJyb3Jpc3Q6UnVubmluZzpkZWZlbnNpdmVfZW5hYmxlZCI6ZmFsc2UsIlRlcnJvcmlzdDpSdW5uaW5nOmRlZmVuc2l2ZV9mb3JjZV9kZWZlbnNpdmUiOmZhbHNlLCJUZXJyb3Jpc3Q6UnVubmluZzpkZWZlbnNpdmVfcGl0Y2giOiJTdGF0aWMiLCJUZXJyb3Jpc3Q6UnVubmluZzpkZWZlbnNpdmVfcGl0Y2hfMSI6MC4wLCJUZXJyb3Jpc3Q6UnVubmluZzpkZWZlbnNpdmVfcGl0Y2hfMiI6MC4wLCJUZXJyb3Jpc3Q6UnVubmluZzpkZWZlbnNpdmVfcGl0Y2hfb2Zmc2V0IjowLjAsIlRlcnJvcmlzdDpSdW5uaW5nOmRlZmVuc2l2ZV9yYW5kb21fY2hva2UiOmZhbHNlLCJUZXJyb3Jpc3Q6UnVubmluZzpkZWZlbnNpdmVfcmFuZG9taXphdGlvbiI6MC4wLCJUZXJyb3Jpc3Q6UnVubmluZzpkZWZlbnNpdmVfeWF3IjoiU3RhdGljIiwiVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX3lhd18xIjowLjAsIlRlcnJvcmlzdDpSdW5uaW5nOmRlZmVuc2l2ZV95YXdfMiI6MC4wLCJUZXJyb3Jpc3Q6UnVubmluZzpkZWZlbnNpdmVfeWF3X29mZnNldCI6MTgwLjAsIlRlcnJvcmlzdDpSdW5uaW5nOmRlZmVuc2l2ZV95YXdfc3BlZWQiOjIwLjAsIlRlcnJvcmlzdDpSdW5uaW5nOmRlbGF5XzEiOjAuMCwiVGVycm9yaXN0OlJ1bm5pbmc6ZGVsYXlfMiI6MC4wLCJUZXJyb3Jpc3Q6UnVubmluZzpsZWZ0X2xpbWl0IjozMC4wLCJUZXJyb3Jpc3Q6UnVubmluZzptb2RpZmllcl9vZmZzZXQiOi02MC4wLCJUZXJyb3Jpc3Q6UnVubmluZzpyaWdodF9saW1pdCI6MzAuMCwiVGVycm9yaXN0OlJ1bm5pbmc6eWF3X2FkZCI6dHJ1ZSwiVGVycm9yaXN0OlJ1bm5pbmc6eWF3X2xlZnQiOjAuMCwiVGVycm9yaXN0OlJ1bm5pbmc6eWF3X21vZGlmaWVyIjoiQ2VudGVyIiwiVGVycm9yaXN0OlJ1bm5pbmc6eWF3X29mZnNldCI6MC4wLCJUZXJyb3Jpc3Q6UnVubmluZzp5YXdfcmlnaHQiOjAuMCwiVGVycm9yaXN0OlNuZWFraW5nOmJvZHlfeWF3IjoiSml0dGVyIiwiVGVycm9yaXN0OlNuZWFraW5nOmRlZmVuc2l2ZV9jaG9rZV8xIjoxNi4wLCJUZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX2Nob2tlXzIiOjE2LjAsIlRlcnJvcmlzdDpTbmVha2luZzpkZWZlbnNpdmVfY3VzdG9tX2Nob2tlIjpmYWxzZSwiVGVycm9yaXN0OlNuZWFraW5nOmRlZmVuc2l2ZV9lbmFibGVkIjpmYWxzZSwiVGVycm9yaXN0OlNuZWFraW5nOmRlZmVuc2l2ZV9mb3JjZV9kZWZlbnNpdmUiOmZhbHNlLCJUZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX3BpdGNoIjoiU3dheSIsIlRlcnJvcmlzdDpTbmVha2luZzpkZWZlbnNpdmVfcGl0Y2hfMSI6LTg5LjAsIlRlcnJvcmlzdDpTbmVha2luZzpkZWZlbnNpdmVfcGl0Y2hfMiI6ODkuMCwiVGVycm9yaXN0OlNuZWFraW5nOmRlZmVuc2l2ZV9waXRjaF9vZmZzZXQiOi04OS4wLCJUZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX3JhbmRvbV9jaG9rZSI6ZmFsc2UsIlRlcnJvcmlzdDpTbmVha2luZzpkZWZlbnNpdmVfcmFuZG9taXphdGlvbiI6NC4wLCJUZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX3lhdyI6IlNwaW4iLCJUZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX3lhd18xIjotMTAxLjAsIlRlcnJvcmlzdDpTbmVha2luZzpkZWZlbnNpdmVfeWF3XzIiOjEwMS4wLCJUZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX3lhd19vZmZzZXQiOjE4MC4wLCJUZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX3lhd19zcGVlZCI6MjAuMCwiVGVycm9yaXN0OlNuZWFraW5nOmRlbGF5XzEiOjAuMCwiVGVycm9yaXN0OlNuZWFraW5nOmRlbGF5XzIiOjAuMCwiVGVycm9yaXN0OlNuZWFraW5nOmxlZnRfbGltaXQiOjYwLjAsIlRlcnJvcmlzdDpTbmVha2luZzptb2RpZmllcl9vZmZzZXQiOi0zNS4wLCJUZXJyb3Jpc3Q6U25lYWtpbmc6cmlnaHRfbGltaXQiOjYwLjAsIlRlcnJvcmlzdDpTbmVha2luZzp5YXdfYWRkIjp0cnVlLCJUZXJyb3Jpc3Q6U25lYWtpbmc6eWF3X2xlZnQiOi0zMS4wLCJUZXJyb3Jpc3Q6U25lYWtpbmc6eWF3X21vZGlmaWVyIjoiRGlzYWJsZWQiLCJUZXJyb3Jpc3Q6U25lYWtpbmc6eWF3X29mZnNldCI6MC4wLCJUZXJyb3Jpc3Q6U25lYWtpbmc6eWF3X3JpZ2h0Ijo0NS4wLCJUZXJyb3Jpc3Q6U3RhbmRpbmc6Ym9keV95YXciOiJKaXR0ZXIiLCJUZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX2Nob2tlXzEiOjE2LjAsIlRlcnJvcmlzdDpTdGFuZGluZzpkZWZlbnNpdmVfY2hva2VfMiI6MTYuMCwiVGVycm9yaXN0OlN0YW5kaW5nOmRlZmVuc2l2ZV9jdXN0b21fY2hva2UiOmZhbHNlLCJUZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX2VuYWJsZWQiOmZhbHNlLCJUZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX2ZvcmNlX2RlZmVuc2l2ZSI6ZmFsc2UsIlRlcnJvcmlzdDpTdGFuZGluZzpkZWZlbnNpdmVfcGl0Y2giOiJTdGF0aWMiLCJUZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX3BpdGNoXzEiOjAuMCwiVGVycm9yaXN0OlN0YW5kaW5nOmRlZmVuc2l2ZV9waXRjaF8yIjowLjAsIlRlcnJvcmlzdDpTdGFuZGluZzpkZWZlbnNpdmVfcGl0Y2hfb2Zmc2V0IjowLjAsIlRlcnJvcmlzdDpTdGFuZGluZzpkZWZlbnNpdmVfcmFuZG9tX2Nob2tlIjpmYWxzZSwiVGVycm9yaXN0OlN0YW5kaW5nOmRlZmVuc2l2ZV9yYW5kb21pemF0aW9uIjowLjAsIlRlcnJvcmlzdDpTdGFuZGluZzpkZWZlbnNpdmVfeWF3IjoiU3RhdGljIiwiVGVycm9yaXN0OlN0YW5kaW5nOmRlZmVuc2l2ZV95YXdfMSI6MC4wLCJUZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX3lhd18yIjowLjAsIlRlcnJvcmlzdDpTdGFuZGluZzpkZWZlbnNpdmVfeWF3X29mZnNldCI6MTgwLjAsIlRlcnJvcmlzdDpTdGFuZGluZzpkZWZlbnNpdmVfeWF3X3NwZWVkIjoyMC4wLCJUZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVsYXlfMSI6MS4wLCJUZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVsYXlfMiI6MC4wLCJUZXJyb3Jpc3Q6U3RhbmRpbmc6bGVmdF9saW1pdCI6MzAuMCwiVGVycm9yaXN0OlN0YW5kaW5nOm1vZGlmaWVyX29mZnNldCI6LTQ2LjAsIlRlcnJvcmlzdDpTdGFuZGluZzpyaWdodF9saW1pdCI6MzAuMCwiVGVycm9yaXN0OlN0YW5kaW5nOnlhd19hZGQiOnRydWUsIlRlcnJvcmlzdDpTdGFuZGluZzp5YXdfbGVmdCI6LTMwLjAsIlRlcnJvcmlzdDpTdGFuZGluZzp5YXdfbW9kaWZpZXIiOiJEaXNhYmxlZCIsIlRlcnJvcmlzdDpTdGFuZGluZzp5YXdfb2Zmc2V0IjowLjAsIlRlcnJvcmlzdDpTdGFuZGluZzp5YXdfcmlnaHQiOjM0LjAsIlRlcnJvcmlzdDpXYWxraW5nOmJvZHlfeWF3IjoiRGlzYWJsZWQiLCJUZXJyb3Jpc3Q6V2Fsa2luZzpkZWZlbnNpdmVfY2hva2VfMSI6NC4wLCJUZXJyb3Jpc3Q6V2Fsa2luZzpkZWZlbnNpdmVfY2hva2VfMiI6Ny4wLCJUZXJyb3Jpc3Q6V2Fsa2luZzpkZWZlbnNpdmVfY3VzdG9tX2Nob2tlIjp0cnVlLCJUZXJyb3Jpc3Q6V2Fsa2luZzpkZWZlbnNpdmVfZW5hYmxlZCI6ZmFsc2UsIlRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV9mb3JjZV9kZWZlbnNpdmUiOmZhbHNlLCJUZXJyb3Jpc3Q6V2Fsa2luZzpkZWZlbnNpdmVfcGl0Y2giOiJTd2F5IiwiVGVycm9yaXN0OldhbGtpbmc6ZGVmZW5zaXZlX3BpdGNoXzEiOi04OS4wLCJUZXJyb3Jpc3Q6V2Fsa2luZzpkZWZlbnNpdmVfcGl0Y2hfMiI6ODkuMCwiVGVycm9yaXN0OldhbGtpbmc6ZGVmZW5zaXZlX3BpdGNoX29mZnNldCI6LTg5LjAsIlRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV9yYW5kb21fY2hva2UiOnRydWUsIlRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV9yYW5kb21pemF0aW9uIjowLjAsIlRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV95YXciOiJTd2F5IiwiVGVycm9yaXN0OldhbGtpbmc6ZGVmZW5zaXZlX3lhd18xIjotOTAuMCwiVGVycm9yaXN0OldhbGtpbmc6ZGVmZW5zaXZlX3lhd18yIjo5MC4wLCJUZXJyb3Jpc3Q6V2Fsa2luZzpkZWZlbnNpdmVfeWF3X29mZnNldCI6MzYwLjAsIlRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV95YXdfc3BlZWQiOjIwLjAsIlRlcnJvcmlzdDpXYWxraW5nOmRlbGF5XzEiOjAuMCwiVGVycm9yaXN0OldhbGtpbmc6ZGVsYXlfMiI6MC4wLCJUZXJyb3Jpc3Q6V2Fsa2luZzpsZWZ0X2xpbWl0Ijo1OC4wLCJUZXJyb3Jpc3Q6V2Fsa2luZzptb2RpZmllcl9vZmZzZXQiOi00NC4wLCJUZXJyb3Jpc3Q6V2Fsa2luZzpyaWdodF9saW1pdCI6NTguMCwiVGVycm9yaXN0OldhbGtpbmc6eWF3X2FkZCI6dHJ1ZSwiVGVycm9yaXN0OldhbGtpbmc6eWF3X2xlZnQiOjAuMCwiVGVycm9yaXN0OldhbGtpbmc6eWF3X21vZGlmaWVyIjoiQ2VudGVyIiwiVGVycm9yaXN0OldhbGtpbmc6eWF3X29mZnNldCI6MC4wLCJUZXJyb3Jpc3Q6V2Fsa2luZzp5YXdfcmlnaHQiOjAuMCwiYXV0b19sYy5lbmFibGVkIjp0cnVlLCJhdm9pZF9iYWNrc3RhYi5lbmFibGVkIjp0cnVlLCJmbGlja19leHBsb2l0LmNvbmRpdGlvbnMiOlsiU3RhbmRpbmciLCJXYWxraW5nIiwiQ3JvdWNoaW5nIiwiU25lYWtpbmciXSwiZmxpY2tfZXhwbG9pdC5lbmFibGVkIjpmYWxzZSwiZnJlZXN0YW5kaW5nLmRpc2FibGVycyI6WyJJbiBBaXIiLCJBaXIgQ3JvdWNoIl0sImZyZWVzdGFuZGluZy5lbmFibGVkIjpmYWxzZSwiZnJlZXN0YW5kaW5nLnN0YXRpYyI6dHJ1ZSwibWFudWFsX3lhdy5kaXJlY3Rpb24iOiJEaXNhYmxlZCIsIm1hbnVhbF95YXcuZGlzYWJsZXJzIjpbXSwibWFudWFsX3lhdy5zdGF0aWMiOmZhbHNlLCJtb2RpZnlfb25fd2FybXVwLmVuYWJsZWQiOmZhbHNlLCJvbl91c2UuZW5hYmxlZCI6ZmFsc2UsInNhZmVfaGVhZC5jb25kaXRpb25zIjpbIkFpciBLbmlmZSIsIkFpciBUYXNlciIsIkRpc3RhbmNlIl0sInNhZmVfaGVhZC5lbmFibGVkIjp0cnVlfSwiTWlzY2VsbGFuZW91cyI6eyJhdm9pZF9jb2xsaXNpb25zLmVuYWJsZWQiOmZhbHNlLCJjbGFudGFnLmN1c3RvbSI6IiNzd2FnZ2VkIiwiY2xhbnRhZy5lbmFibGVkIjp0cnVlLCJjbGFudGFnLm1vZGUiOiJDdXN0b20iLCJjb2xsaXNpb25fYWlyX2R1Y2suZW5hYmxlZCI6ZmFsc2UsImVkZ2Vfc3RvcC5lbmFibGVkIjpmYWxzZSwiZmFzdF9sYWRkZXIuZW5hYmxlZCI6dHJ1ZSwibm9fZmFsbF9kYW1hZ2UuZW5hYmxlZCI6dHJ1ZSwic291cmNlLmV4dHJhcG9sYXRpb24iOmZhbHNlLCJzb3VyY2UuZm9yY2VfaW50ZXJwb2xhdGlvbiI6dHJ1ZSwic3VwZXJfdG9zcy5lbmFibGVkIjp0cnVlLCJ0cmFzaHRhbGsuZGVhdGgiOnRydWUsInRyYXNodGFsay5lbmFibGVkIjp0cnVlLCJ0cmFzaHRhbGsua2lsbCI6dHJ1ZSwidHJhc2h0YWxrLnN0eWxlIjoi0KDRg9GB0YHQutC40LkiLCJ1bmxvY2tfZmRfc3BlZWQuZW5hYmxlZCI6ZmFsc2V9LCJSYWdlIjp7ImRvcm1hbnRfYWltYm90LmFjY3VyYWN5Ijo2MC4wLCJkb3JtYW50X2FpbWJvdC5lbmFibGVkIjpmYWxzZSwiZG9ybWFudF9haW1ib3QuaGl0Ym94ZXMiOlsiSGVhZCIsIkNoZXN0IiwiU3RvbWFjaCIsIkxlZ3MiXSwiZG9ybWFudF9haW1ib3QubWluX2RhbWFnZSI6MTAuMCwiZmFrZV9sYXRlbmN5LmVuYWJsZWQiOmZhbHNlLCJtYXh1c3JjbWRwcm9jZXNzdGlja3MuZW5hYmxlZCI6dHJ1ZSwibWF4dXNyY21kcHJvY2Vzc3RpY2tzLnRpY2tzIjozMi4wfSwiVmlzdWFscyI6eyJhY2NlbnRfY29sb3IiOiJDMENBRkZGRiIsImFzcGVjdF9yYXRpby5lbmFibGVkIjp0cnVlLCJhc3BlY3RfcmF0aW8ucHJvcG9ydGlvbiI6MTM1LjAsImNvbnNvbGVfY29sb3IuY29sb3IiOiI4MDgwODBGRiIsImNvbnNvbGVfY29sb3IuZW5hYmxlZCI6dHJ1ZSwiY3Jvc3NoYWlyX2luZGljYXRvcnMuZW5hYmxlZCI6dHJ1ZSwiY3Jvc3NoYWlyX2luZGljYXRvcnMuaXRlbXMiOlsiRFQiLCJIUyIsIkZTIl0sImRhbWFnZV9pbmRpY2F0b3IuZW5hYmxlZCI6dHJ1ZSwiaGl0X21hcmtlci5lbmFibGVkIjp0cnVlLCJrZWVwX3RyYW5zcGFyZW5jeS5lbmFibGVkIjp0cnVlLCJsb2dfZXZlbnRzLmVuYWJsZWQiOnRydWUsIm5hZGVfcmFkaXVzLmVuYWJsZWQiOnRydWUsInBhbmVscy5iaW5kcyI6dHJ1ZSwicGFuZWxzLmJpbmRzLngiOjMwNC4wLCJwYW5lbHMuYmluZHMueSI6NDYwLjAsInBhbmVscy5zcGVjdGF0b3JzIjp0cnVlLCJwYW5lbHMuc3BlY3RhdG9ycy54IjozMS4wLCJwYW5lbHMuc3BlY3RhdG9ycy55Ijo0MTUuMCwicGFuZWxzLndhdGVybWFyayI6dHJ1ZSwicGFuZWxzLndhdGVybWFyay5pdGVtcyI6WyJVc2VyIiwiTGF0ZW5jeSIsIkZQUyIsIlRpbWUiXSwicGFuZWxzLndhdGVybWFyay54Ijo4MjMuMCwicGFuZWxzLndhdGVybWFyay55IjoxOC4wLCJyZW1vdmVfZm9vdHN0ZXBzX3NoYWRvdy5lbmFibGVkIjp0cnVlLCJzY29wZV9vdmVybGF5LmFkZGl0aW9ucyI6WyJJbnZlcnRlZCJdLCJzY29wZV9vdmVybGF5LmNvbG9yIjoiRkZGRkZGRkYiLCJzY29wZV9vdmVybGF5LmVuYWJsZWQiOnRydWUsInNjb3BlX292ZXJsYXkuZXhjbHVkZV9saW5lcyI6W10sInNjb3BlX292ZXJsYXkuZ2FwIjowLjAsInNjb3BlX292ZXJsYXkuc2l6ZSI6MjAuMCwidHJhbnNwYXJlbnQuZW5hYmxlZCI6ZmFsc2UsInZlbG9jaXR5X3dhcm5pbmcuZW5hYmxlZCI6dHJ1ZSwidmlld21vZGVsLmVuYWJsZWQiOnRydWUsInZpZXdtb2RlbC5mb3YiOjcyNy4wLCJ2aWV3bW9kZWwub2Zmc2V0X3giOjI1LjAsInZpZXdtb2RlbC5vZmZzZXRfeSI6MC4wLCJ2aWV3bW9kZWwub2Zmc2V0X3oiOi0xNS4wfX0_")            ;
            ;

            add_builtin("Desync", "social::nl::eyJBaW1ib3QiOnsiYWlfcGVlay5jb2xvciI6IkZGRkZGRkZGIiwiYWlfcGVlay5kb3RzIjo0LjAsImFpX3BlZWsuZW5hYmxlZCI6ZmFsc2UsImFpX3BlZWsuaGl0Ym94ZXMiOlsiSGVhZCIsIkNoZXN0IiwiU3RvbWFjaCIsIkFybXMiLCJMZWdzIiwiRmVldCJdLCJhaV9wZWVrLnJhZGl1cyI6MzIuMCwiYWlfcGVlay53ZWFwb25zIjpbIlNTRyAwOCIsIlI4IFJldm9sdmVyIiwiRGVzZXJ0IEVhZ2xlIiwiUGlzdG9sIiwiUmlmbGUiLCJTaG90Z3VuIl0sImRvcm1hbnRfYWltYm90LmFjY3VyYWN5Ijo2MC4wLCJkb3JtYW50X2FpbWJvdC5lbmFibGVkIjpmYWxzZSwiZG9ybWFudF9haW1ib3QuaGl0Ym94ZXMiOlsiSGVhZCIsIkNoZXN0IiwiU3RvbWFjaCIsIkxlZ3MiXSwiZG9ybWFudF9haW1ib3QubWluX2RhbWFnZSI6MTAuMCwiZmFrZV9sYXRlbmN5LmVuYWJsZWQiOmZhbHNlLCJsb2dfZXZlbnRzLmNvbG9yX2hpdCI6IkMzQ0FGRkZGIiwibG9nX2V2ZW50cy5jb2xvcl9taXNzIjoiRkY5MjkyRkYiLCJsb2dfZXZlbnRzLmVuYWJsZWQiOnRydWUsImxvZ19ldmVudHMub3V0cHV0IjpbIkNvbnNvbGUiLCJEZWJ1ZyIsIk5vdGlmeSJdLCJtYXh1c3JjbWRwcm9jZXNzdGlja3MuZW5hYmxlZCI6ZmFsc2UsIm1heHVzcmNtZHByb2Nlc3N0aWNrcy50aWNrcyI6MTYuMH0sIkFudGktQWltIjp7IkNvdW50ZXItVGVycm9yaXN0OkFpciBDcm91Y2g6Ym9keV95YXciOiJKaXR0ZXIiLCJDb3VudGVyLVRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlZmVuc2l2ZV9jaG9rZV8xIjoxNi4wLCJDb3VudGVyLVRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlZmVuc2l2ZV9jaG9rZV8yIjoxNi4wLCJDb3VudGVyLVRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlZmVuc2l2ZV9jdXN0b21fY2hva2UiOmZhbHNlLCJDb3VudGVyLVRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlZmVuc2l2ZV9lbmFibGVkIjpmYWxzZSwiQ291bnRlci1UZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfZm9yY2VfZGVmZW5zaXZlIjpmYWxzZSwiQ291bnRlci1UZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfcGl0Y2giOiJTdGF0aWMiLCJDb3VudGVyLVRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlZmVuc2l2ZV9waXRjaF8xIjowLjAsIkNvdW50ZXItVGVycm9yaXN0OkFpciBDcm91Y2g6ZGVmZW5zaXZlX3BpdGNoXzIiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfcGl0Y2hfb2Zmc2V0IjowLjAsIkNvdW50ZXItVGVycm9yaXN0OkFpciBDcm91Y2g6ZGVmZW5zaXZlX3JhbmRvbV9jaG9rZSI6ZmFsc2UsIkNvdW50ZXItVGVycm9yaXN0OkFpciBDcm91Y2g6ZGVmZW5zaXZlX3JhbmRvbWl6YXRpb24iOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfeWF3IjoiU3RhdGljIiwiQ291bnRlci1UZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfeWF3XzEiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfeWF3XzIiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfeWF3X29mZnNldCI6MTgwLjAsIkNvdW50ZXItVGVycm9yaXN0OkFpciBDcm91Y2g6ZGVmZW5zaXZlX3lhd19zcGVlZCI6MjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWxheV8xIjowLjAsIkNvdW50ZXItVGVycm9yaXN0OkFpciBDcm91Y2g6ZGVsYXlfMiI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpBaXIgQ3JvdWNoOmxlZnRfbGltaXQiOjU4LjAsIkNvdW50ZXItVGVycm9yaXN0OkFpciBDcm91Y2g6bW9kaWZpZXJfb2Zmc2V0IjotNDYuMCwiQ291bnRlci1UZXJyb3Jpc3Q6QWlyIENyb3VjaDpyaWdodF9saW1pdCI6NTguMCwiQ291bnRlci1UZXJyb3Jpc3Q6QWlyIENyb3VjaDp5YXdfYWRkIjp0cnVlLCJDb3VudGVyLVRlcnJvcmlzdDpBaXIgQ3JvdWNoOnlhd19sZWZ0IjotOC4wLCJDb3VudGVyLVRlcnJvcmlzdDpBaXIgQ3JvdWNoOnlhd19tb2RpZmllciI6IkNlbnRlciIsIkNvdW50ZXItVGVycm9yaXN0OkFpciBDcm91Y2g6eWF3X29mZnNldCI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpBaXIgQ3JvdWNoOnlhd19yaWdodCI6MTQuMCwiQ291bnRlci1UZXJyb3Jpc3Q6Q3JvdWNoaW5nOmJvZHlfeWF3IjoiSml0dGVyIiwiQ291bnRlci1UZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlZmVuc2l2ZV9jaG9rZV8xIjoxNi4wLCJDb3VudGVyLVRlcnJvcmlzdDpDcm91Y2hpbmc6ZGVmZW5zaXZlX2Nob2tlXzIiOjE2LjAsIkNvdW50ZXItVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfY3VzdG9tX2Nob2tlIjpmYWxzZSwiQ291bnRlci1UZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlZmVuc2l2ZV9lbmFibGVkIjpmYWxzZSwiQ291bnRlci1UZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlZmVuc2l2ZV9mb3JjZV9kZWZlbnNpdmUiOmZhbHNlLCJDb3VudGVyLVRlcnJvcmlzdDpDcm91Y2hpbmc6ZGVmZW5zaXZlX3BpdGNoIjoiU3RhdGljIiwiQ291bnRlci1UZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlZmVuc2l2ZV9waXRjaF8xIjowLjAsIkNvdW50ZXItVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfcGl0Y2hfMiI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpDcm91Y2hpbmc6ZGVmZW5zaXZlX3BpdGNoX29mZnNldCI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpDcm91Y2hpbmc6ZGVmZW5zaXZlX3JhbmRvbV9jaG9rZSI6ZmFsc2UsIkNvdW50ZXItVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfcmFuZG9taXphdGlvbiI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpDcm91Y2hpbmc6ZGVmZW5zaXZlX3lhdyI6IlN0YXRpYyIsIkNvdW50ZXItVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfeWF3XzEiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlZmVuc2l2ZV95YXdfMiI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpDcm91Y2hpbmc6ZGVmZW5zaXZlX3lhd19vZmZzZXQiOjE4MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpDcm91Y2hpbmc6ZGVmZW5zaXZlX3lhd19zcGVlZCI6MjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlbGF5XzEiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlbGF5XzIiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6Q3JvdWNoaW5nOmxlZnRfbGltaXQiOjU4LjAsIkNvdW50ZXItVGVycm9yaXN0OkNyb3VjaGluZzptb2RpZmllcl9vZmZzZXQiOi0zNS4wLCJDb3VudGVyLVRlcnJvcmlzdDpDcm91Y2hpbmc6cmlnaHRfbGltaXQiOjU4LjAsIkNvdW50ZXItVGVycm9yaXN0OkNyb3VjaGluZzp5YXdfYWRkIjp0cnVlLCJDb3VudGVyLVRlcnJvcmlzdDpDcm91Y2hpbmc6eWF3X2xlZnQiOi0xMC4wLCJDb3VudGVyLVRlcnJvcmlzdDpDcm91Y2hpbmc6eWF3X21vZGlmaWVyIjoiQ2VudGVyIiwiQ291bnRlci1UZXJyb3Jpc3Q6Q3JvdWNoaW5nOnlhd19vZmZzZXQiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6Q3JvdWNoaW5nOnlhd19yaWdodCI6MTYuMCwiQ291bnRlci1UZXJyb3Jpc3Q6SW4gQWlyOmJvZHlfeWF3IjoiSml0dGVyIiwiQ291bnRlci1UZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV9jaG9rZV8xIjoxNi4wLCJDb3VudGVyLVRlcnJvcmlzdDpJbiBBaXI6ZGVmZW5zaXZlX2Nob2tlXzIiOjE2LjAsIkNvdW50ZXItVGVycm9yaXN0OkluIEFpcjpkZWZlbnNpdmVfY3VzdG9tX2Nob2tlIjpmYWxzZSwiQ291bnRlci1UZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV9lbmFibGVkIjpmYWxzZSwiQ291bnRlci1UZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV9mb3JjZV9kZWZlbnNpdmUiOmZhbHNlLCJDb3VudGVyLVRlcnJvcmlzdDpJbiBBaXI6ZGVmZW5zaXZlX3BpdGNoIjoiU3RhdGljIiwiQ291bnRlci1UZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV9waXRjaF8xIjowLjAsIkNvdW50ZXItVGVycm9yaXN0OkluIEFpcjpkZWZlbnNpdmVfcGl0Y2hfMiI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpJbiBBaXI6ZGVmZW5zaXZlX3BpdGNoX29mZnNldCI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpJbiBBaXI6ZGVmZW5zaXZlX3JhbmRvbV9jaG9rZSI6ZmFsc2UsIkNvdW50ZXItVGVycm9yaXN0OkluIEFpcjpkZWZlbnNpdmVfcmFuZG9taXphdGlvbiI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpJbiBBaXI6ZGVmZW5zaXZlX3lhdyI6IlN0YXRpYyIsIkNvdW50ZXItVGVycm9yaXN0OkluIEFpcjpkZWZlbnNpdmVfeWF3XzEiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV95YXdfMiI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpJbiBBaXI6ZGVmZW5zaXZlX3lhd19vZmZzZXQiOjE4MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpJbiBBaXI6ZGVmZW5zaXZlX3lhd19zcGVlZCI6MjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6SW4gQWlyOmRlbGF5XzEiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6SW4gQWlyOmRlbGF5XzIiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6SW4gQWlyOmxlZnRfbGltaXQiOjU4LjAsIkNvdW50ZXItVGVycm9yaXN0OkluIEFpcjptb2RpZmllcl9vZmZzZXQiOi00Ny4wLCJDb3VudGVyLVRlcnJvcmlzdDpJbiBBaXI6cmlnaHRfbGltaXQiOjU4LjAsIkNvdW50ZXItVGVycm9yaXN0OkluIEFpcjp5YXdfYWRkIjp0cnVlLCJDb3VudGVyLVRlcnJvcmlzdDpJbiBBaXI6eWF3X2xlZnQiOi0zLjAsIkNvdW50ZXItVGVycm9yaXN0OkluIEFpcjp5YXdfbW9kaWZpZXIiOiJDZW50ZXIiLCJDb3VudGVyLVRlcnJvcmlzdDpJbiBBaXI6eWF3X29mZnNldCI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpJbiBBaXI6eWF3X3JpZ2h0IjoxNi4wLCJDb3VudGVyLVRlcnJvcmlzdDpSdW5uaW5nOmJvZHlfeWF3IjoiSml0dGVyIiwiQ291bnRlci1UZXJyb3Jpc3Q6UnVubmluZzpkZWZlbnNpdmVfY2hva2VfMSI6MTYuMCwiQ291bnRlci1UZXJyb3Jpc3Q6UnVubmluZzpkZWZlbnNpdmVfY2hva2VfMiI6MTYuMCwiQ291bnRlci1UZXJyb3Jpc3Q6UnVubmluZzpkZWZlbnNpdmVfY3VzdG9tX2Nob2tlIjpmYWxzZSwiQ291bnRlci1UZXJyb3Jpc3Q6UnVubmluZzpkZWZlbnNpdmVfZW5hYmxlZCI6ZmFsc2UsIkNvdW50ZXItVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX2ZvcmNlX2RlZmVuc2l2ZSI6ZmFsc2UsIkNvdW50ZXItVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX3BpdGNoIjoiU3RhdGljIiwiQ291bnRlci1UZXJyb3Jpc3Q6UnVubmluZzpkZWZlbnNpdmVfcGl0Y2hfMSI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpSdW5uaW5nOmRlZmVuc2l2ZV9waXRjaF8yIjowLjAsIkNvdW50ZXItVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX3BpdGNoX29mZnNldCI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpSdW5uaW5nOmRlZmVuc2l2ZV9yYW5kb21fY2hva2UiOmZhbHNlLCJDb3VudGVyLVRlcnJvcmlzdDpSdW5uaW5nOmRlZmVuc2l2ZV9yYW5kb21pemF0aW9uIjowLjAsIkNvdW50ZXItVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX3lhdyI6IlN0YXRpYyIsIkNvdW50ZXItVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX3lhd18xIjowLjAsIkNvdW50ZXItVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX3lhd18yIjowLjAsIkNvdW50ZXItVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX3lhd19vZmZzZXQiOjE4MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpSdW5uaW5nOmRlZmVuc2l2ZV95YXdfc3BlZWQiOjIwLjAsIkNvdW50ZXItVGVycm9yaXN0OlJ1bm5pbmc6ZGVsYXlfMSI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpSdW5uaW5nOmRlbGF5XzIiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6UnVubmluZzpsZWZ0X2xpbWl0IjozNi4wLCJDb3VudGVyLVRlcnJvcmlzdDpSdW5uaW5nOm1vZGlmaWVyX29mZnNldCI6LTUyLjAsIkNvdW50ZXItVGVycm9yaXN0OlJ1bm5pbmc6cmlnaHRfbGltaXQiOjM2LjAsIkNvdW50ZXItVGVycm9yaXN0OlJ1bm5pbmc6eWF3X2FkZCI6dHJ1ZSwiQ291bnRlci1UZXJyb3Jpc3Q6UnVubmluZzp5YXdfbGVmdCI6LTYuMCwiQ291bnRlci1UZXJyb3Jpc3Q6UnVubmluZzp5YXdfbW9kaWZpZXIiOiJDZW50ZXIiLCJDb3VudGVyLVRlcnJvcmlzdDpSdW5uaW5nOnlhd19vZmZzZXQiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6UnVubmluZzp5YXdfcmlnaHQiOjExLjAsIkNvdW50ZXItVGVycm9yaXN0OlNuZWFraW5nOmJvZHlfeWF3IjoiSml0dGVyIiwiQ291bnRlci1UZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX2Nob2tlXzEiOjE2LjAsIkNvdW50ZXItVGVycm9yaXN0OlNuZWFraW5nOmRlZmVuc2l2ZV9jaG9rZV8yIjoxNi4wLCJDb3VudGVyLVRlcnJvcmlzdDpTbmVha2luZzpkZWZlbnNpdmVfY3VzdG9tX2Nob2tlIjpmYWxzZSwiQ291bnRlci1UZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX2VuYWJsZWQiOmZhbHNlLCJDb3VudGVyLVRlcnJvcmlzdDpTbmVha2luZzpkZWZlbnNpdmVfZm9yY2VfZGVmZW5zaXZlIjpmYWxzZSwiQ291bnRlci1UZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX3BpdGNoIjoiU3RhdGljIiwiQ291bnRlci1UZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX3BpdGNoXzEiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX3BpdGNoXzIiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX3BpdGNoX29mZnNldCI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpTbmVha2luZzpkZWZlbnNpdmVfcmFuZG9tX2Nob2tlIjpmYWxzZSwiQ291bnRlci1UZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX3JhbmRvbWl6YXRpb24iOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX3lhdyI6IlN0YXRpYyIsIkNvdW50ZXItVGVycm9yaXN0OlNuZWFraW5nOmRlZmVuc2l2ZV95YXdfMSI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpTbmVha2luZzpkZWZlbnNpdmVfeWF3XzIiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX3lhd19vZmZzZXQiOjE4MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpTbmVha2luZzpkZWZlbnNpdmVfeWF3X3NwZWVkIjoyMC4wLCJDb3VudGVyLVRlcnJvcmlzdDpTbmVha2luZzpkZWxheV8xIjowLjAsIkNvdW50ZXItVGVycm9yaXN0OlNuZWFraW5nOmRlbGF5XzIiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U25lYWtpbmc6bGVmdF9saW1pdCI6NTguMCwiQ291bnRlci1UZXJyb3Jpc3Q6U25lYWtpbmc6bW9kaWZpZXJfb2Zmc2V0IjotMzUuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U25lYWtpbmc6cmlnaHRfbGltaXQiOjU4LjAsIkNvdW50ZXItVGVycm9yaXN0OlNuZWFraW5nOnlhd19hZGQiOnRydWUsIkNvdW50ZXItVGVycm9yaXN0OlNuZWFraW5nOnlhd19sZWZ0IjotMTAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U25lYWtpbmc6eWF3X21vZGlmaWVyIjoiQ2VudGVyIiwiQ291bnRlci1UZXJyb3Jpc3Q6U25lYWtpbmc6eWF3X29mZnNldCI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpTbmVha2luZzp5YXdfcmlnaHQiOjE2LjAsIkNvdW50ZXItVGVycm9yaXN0OlN0YW5kaW5nOmJvZHlfeWF3IjoiSml0dGVyIiwiQ291bnRlci1UZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX2Nob2tlXzEiOjE2LjAsIkNvdW50ZXItVGVycm9yaXN0OlN0YW5kaW5nOmRlZmVuc2l2ZV9jaG9rZV8yIjoxNi4wLCJDb3VudGVyLVRlcnJvcmlzdDpTdGFuZGluZzpkZWZlbnNpdmVfY3VzdG9tX2Nob2tlIjpmYWxzZSwiQ291bnRlci1UZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX2VuYWJsZWQiOmZhbHNlLCJDb3VudGVyLVRlcnJvcmlzdDpTdGFuZGluZzpkZWZlbnNpdmVfZm9yY2VfZGVmZW5zaXZlIjpmYWxzZSwiQ291bnRlci1UZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX3BpdGNoIjoiU3RhdGljIiwiQ291bnRlci1UZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX3BpdGNoXzEiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX3BpdGNoXzIiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX3BpdGNoX29mZnNldCI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpTdGFuZGluZzpkZWZlbnNpdmVfcmFuZG9tX2Nob2tlIjpmYWxzZSwiQ291bnRlci1UZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX3JhbmRvbWl6YXRpb24iOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX3lhdyI6IlN0YXRpYyIsIkNvdW50ZXItVGVycm9yaXN0OlN0YW5kaW5nOmRlZmVuc2l2ZV95YXdfMSI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpTdGFuZGluZzpkZWZlbnNpdmVfeWF3XzIiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX3lhd19vZmZzZXQiOjE4MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpTdGFuZGluZzpkZWZlbnNpdmVfeWF3X3NwZWVkIjoyMC4wLCJDb3VudGVyLVRlcnJvcmlzdDpTdGFuZGluZzpkZWxheV8xIjowLjAsIkNvdW50ZXItVGVycm9yaXN0OlN0YW5kaW5nOmRlbGF5XzIiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U3RhbmRpbmc6bGVmdF9saW1pdCI6MzAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U3RhbmRpbmc6bW9kaWZpZXJfb2Zmc2V0IjotNDYuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U3RhbmRpbmc6cmlnaHRfbGltaXQiOjMwLjAsIkNvdW50ZXItVGVycm9yaXN0OlN0YW5kaW5nOnlhd19hZGQiOnRydWUsIkNvdW50ZXItVGVycm9yaXN0OlN0YW5kaW5nOnlhd19sZWZ0IjotNy4wLCJDb3VudGVyLVRlcnJvcmlzdDpTdGFuZGluZzp5YXdfbW9kaWZpZXIiOiJDZW50ZXIiLCJDb3VudGVyLVRlcnJvcmlzdDpTdGFuZGluZzp5YXdfb2Zmc2V0IjowLjAsIkNvdW50ZXItVGVycm9yaXN0OlN0YW5kaW5nOnlhd19yaWdodCI6MTEuMCwiQ291bnRlci1UZXJyb3Jpc3Q6V2Fsa2luZzpib2R5X3lhdyI6IkppdHRlciIsIkNvdW50ZXItVGVycm9yaXN0OldhbGtpbmc6ZGVmZW5zaXZlX2Nob2tlXzEiOjE2LjAsIkNvdW50ZXItVGVycm9yaXN0OldhbGtpbmc6ZGVmZW5zaXZlX2Nob2tlXzIiOjE2LjAsIkNvdW50ZXItVGVycm9yaXN0OldhbGtpbmc6ZGVmZW5zaXZlX2N1c3RvbV9jaG9rZSI6ZmFsc2UsIkNvdW50ZXItVGVycm9yaXN0OldhbGtpbmc6ZGVmZW5zaXZlX2VuYWJsZWQiOmZhbHNlLCJDb3VudGVyLVRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV9mb3JjZV9kZWZlbnNpdmUiOmZhbHNlLCJDb3VudGVyLVRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV9waXRjaCI6IlN0YXRpYyIsIkNvdW50ZXItVGVycm9yaXN0OldhbGtpbmc6ZGVmZW5zaXZlX3BpdGNoXzEiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6V2Fsa2luZzpkZWZlbnNpdmVfcGl0Y2hfMiI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV9waXRjaF9vZmZzZXQiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6V2Fsa2luZzpkZWZlbnNpdmVfcmFuZG9tX2Nob2tlIjpmYWxzZSwiQ291bnRlci1UZXJyb3Jpc3Q6V2Fsa2luZzpkZWZlbnNpdmVfcmFuZG9taXphdGlvbiI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV95YXciOiJTdGF0aWMiLCJDb3VudGVyLVRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV95YXdfMSI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV95YXdfMiI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV95YXdfb2Zmc2V0IjoxODAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6V2Fsa2luZzpkZWZlbnNpdmVfeWF3X3NwZWVkIjoyMC4wLCJDb3VudGVyLVRlcnJvcmlzdDpXYWxraW5nOmRlbGF5XzEiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6V2Fsa2luZzpkZWxheV8yIjowLjAsIkNvdW50ZXItVGVycm9yaXN0OldhbGtpbmc6bGVmdF9saW1pdCI6NDUuMCwiQ291bnRlci1UZXJyb3Jpc3Q6V2Fsa2luZzptb2RpZmllcl9vZmZzZXQiOi01LjAsIkNvdW50ZXItVGVycm9yaXN0OldhbGtpbmc6cmlnaHRfbGltaXQiOjQ1LjAsIkNvdW50ZXItVGVycm9yaXN0OldhbGtpbmc6eWF3X2FkZCI6dHJ1ZSwiQ291bnRlci1UZXJyb3Jpc3Q6V2Fsa2luZzp5YXdfbGVmdCI6LTIzLjAsIkNvdW50ZXItVGVycm9yaXN0OldhbGtpbmc6eWF3X21vZGlmaWVyIjoiU3BpbiIsIkNvdW50ZXItVGVycm9yaXN0OldhbGtpbmc6eWF3X29mZnNldCI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpXYWxraW5nOnlhd19yaWdodCI6NDcuMCwiVGVycm9yaXN0OkFpciBDcm91Y2g6Ym9keV95YXciOiJKaXR0ZXIiLCJUZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfY2hva2VfMSI6MTYuMCwiVGVycm9yaXN0OkFpciBDcm91Y2g6ZGVmZW5zaXZlX2Nob2tlXzIiOjE2LjAsIlRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlZmVuc2l2ZV9jdXN0b21fY2hva2UiOmZhbHNlLCJUZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfZW5hYmxlZCI6ZmFsc2UsIlRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlZmVuc2l2ZV9mb3JjZV9kZWZlbnNpdmUiOmZhbHNlLCJUZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfcGl0Y2giOiJTdGF0aWMiLCJUZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfcGl0Y2hfMSI6MC4wLCJUZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfcGl0Y2hfMiI6MC4wLCJUZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfcGl0Y2hfb2Zmc2V0IjowLjAsIlRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlZmVuc2l2ZV9yYW5kb21fY2hva2UiOmZhbHNlLCJUZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfcmFuZG9taXphdGlvbiI6MC4wLCJUZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfeWF3IjoiU3RhdGljIiwiVGVycm9yaXN0OkFpciBDcm91Y2g6ZGVmZW5zaXZlX3lhd18xIjowLjAsIlRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlZmVuc2l2ZV95YXdfMiI6MC4wLCJUZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfeWF3X29mZnNldCI6MTgwLjAsIlRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlZmVuc2l2ZV95YXdfc3BlZWQiOjIwLjAsIlRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlbGF5XzEiOjAuMCwiVGVycm9yaXN0OkFpciBDcm91Y2g6ZGVsYXlfMiI6MC4wLCJUZXJyb3Jpc3Q6QWlyIENyb3VjaDpsZWZ0X2xpbWl0Ijo1OC4wLCJUZXJyb3Jpc3Q6QWlyIENyb3VjaDptb2RpZmllcl9vZmZzZXQiOi00Ni4wLCJUZXJyb3Jpc3Q6QWlyIENyb3VjaDpyaWdodF9saW1pdCI6NTguMCwiVGVycm9yaXN0OkFpciBDcm91Y2g6eWF3X2FkZCI6dHJ1ZSwiVGVycm9yaXN0OkFpciBDcm91Y2g6eWF3X2xlZnQiOi04LjAsIlRlcnJvcmlzdDpBaXIgQ3JvdWNoOnlhd19tb2RpZmllciI6IkNlbnRlciIsIlRlcnJvcmlzdDpBaXIgQ3JvdWNoOnlhd19vZmZzZXQiOjAuMCwiVGVycm9yaXN0OkFpciBDcm91Y2g6eWF3X3JpZ2h0IjoxNC4wLCJUZXJyb3Jpc3Q6Q3JvdWNoaW5nOmJvZHlfeWF3IjoiSml0dGVyIiwiVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfY2hva2VfMSI6MTYuMCwiVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfY2hva2VfMiI6MTYuMCwiVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfY3VzdG9tX2Nob2tlIjpmYWxzZSwiVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfZW5hYmxlZCI6ZmFsc2UsIlRlcnJvcmlzdDpDcm91Y2hpbmc6ZGVmZW5zaXZlX2ZvcmNlX2RlZmVuc2l2ZSI6ZmFsc2UsIlRlcnJvcmlzdDpDcm91Y2hpbmc6ZGVmZW5zaXZlX3BpdGNoIjoiU3RhdGljIiwiVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfcGl0Y2hfMSI6MC4wLCJUZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlZmVuc2l2ZV9waXRjaF8yIjowLjAsIlRlcnJvcmlzdDpDcm91Y2hpbmc6ZGVmZW5zaXZlX3BpdGNoX29mZnNldCI6MC4wLCJUZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlZmVuc2l2ZV9yYW5kb21fY2hva2UiOmZhbHNlLCJUZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlZmVuc2l2ZV9yYW5kb21pemF0aW9uIjowLjAsIlRlcnJvcmlzdDpDcm91Y2hpbmc6ZGVmZW5zaXZlX3lhdyI6IlN0YXRpYyIsIlRlcnJvcmlzdDpDcm91Y2hpbmc6ZGVmZW5zaXZlX3lhd18xIjowLjAsIlRlcnJvcmlzdDpDcm91Y2hpbmc6ZGVmZW5zaXZlX3lhd18yIjowLjAsIlRlcnJvcmlzdDpDcm91Y2hpbmc6ZGVmZW5zaXZlX3lhd19vZmZzZXQiOjE4MC4wLCJUZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlZmVuc2l2ZV95YXdfc3BlZWQiOjIwLjAsIlRlcnJvcmlzdDpDcm91Y2hpbmc6ZGVsYXlfMSI6MC4wLCJUZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlbGF5XzIiOjAuMCwiVGVycm9yaXN0OkNyb3VjaGluZzpsZWZ0X2xpbWl0Ijo1OC4wLCJUZXJyb3Jpc3Q6Q3JvdWNoaW5nOm1vZGlmaWVyX29mZnNldCI6LTM1LjAsIlRlcnJvcmlzdDpDcm91Y2hpbmc6cmlnaHRfbGltaXQiOjU4LjAsIlRlcnJvcmlzdDpDcm91Y2hpbmc6eWF3X2FkZCI6dHJ1ZSwiVGVycm9yaXN0OkNyb3VjaGluZzp5YXdfbGVmdCI6LTEwLjAsIlRlcnJvcmlzdDpDcm91Y2hpbmc6eWF3X21vZGlmaWVyIjoiQ2VudGVyIiwiVGVycm9yaXN0OkNyb3VjaGluZzp5YXdfb2Zmc2V0IjowLjAsIlRlcnJvcmlzdDpDcm91Y2hpbmc6eWF3X3JpZ2h0IjoxNi4wLCJUZXJyb3Jpc3Q6SW4gQWlyOmJvZHlfeWF3IjoiSml0dGVyIiwiVGVycm9yaXN0OkluIEFpcjpkZWZlbnNpdmVfY2hva2VfMSI6MTYuMCwiVGVycm9yaXN0OkluIEFpcjpkZWZlbnNpdmVfY2hva2VfMiI6MTYuMCwiVGVycm9yaXN0OkluIEFpcjpkZWZlbnNpdmVfY3VzdG9tX2Nob2tlIjpmYWxzZSwiVGVycm9yaXN0OkluIEFpcjpkZWZlbnNpdmVfZW5hYmxlZCI6ZmFsc2UsIlRlcnJvcmlzdDpJbiBBaXI6ZGVmZW5zaXZlX2ZvcmNlX2RlZmVuc2l2ZSI6ZmFsc2UsIlRlcnJvcmlzdDpJbiBBaXI6ZGVmZW5zaXZlX3BpdGNoIjoiU3RhdGljIiwiVGVycm9yaXN0OkluIEFpcjpkZWZlbnNpdmVfcGl0Y2hfMSI6MC4wLCJUZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV9waXRjaF8yIjowLjAsIlRlcnJvcmlzdDpJbiBBaXI6ZGVmZW5zaXZlX3BpdGNoX29mZnNldCI6MC4wLCJUZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV9yYW5kb21fY2hva2UiOmZhbHNlLCJUZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV9yYW5kb21pemF0aW9uIjowLjAsIlRlcnJvcmlzdDpJbiBBaXI6ZGVmZW5zaXZlX3lhdyI6IlN0YXRpYyIsIlRlcnJvcmlzdDpJbiBBaXI6ZGVmZW5zaXZlX3lhd18xIjowLjAsIlRlcnJvcmlzdDpJbiBBaXI6ZGVmZW5zaXZlX3lhd18yIjowLjAsIlRlcnJvcmlzdDpJbiBBaXI6ZGVmZW5zaXZlX3lhd19vZmZzZXQiOjE4MC4wLCJUZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV95YXdfc3BlZWQiOjIwLjAsIlRlcnJvcmlzdDpJbiBBaXI6ZGVsYXlfMSI6MC4wLCJUZXJyb3Jpc3Q6SW4gQWlyOmRlbGF5XzIiOjAuMCwiVGVycm9yaXN0OkluIEFpcjpsZWZ0X2xpbWl0Ijo1OC4wLCJUZXJyb3Jpc3Q6SW4gQWlyOm1vZGlmaWVyX29mZnNldCI6LTQ3LjAsIlRlcnJvcmlzdDpJbiBBaXI6cmlnaHRfbGltaXQiOjU4LjAsIlRlcnJvcmlzdDpJbiBBaXI6eWF3X2FkZCI6dHJ1ZSwiVGVycm9yaXN0OkluIEFpcjp5YXdfbGVmdCI6LTMuMCwiVGVycm9yaXN0OkluIEFpcjp5YXdfbW9kaWZpZXIiOiJDZW50ZXIiLCJUZXJyb3Jpc3Q6SW4gQWlyOnlhd19vZmZzZXQiOjAuMCwiVGVycm9yaXN0OkluIEFpcjp5YXdfcmlnaHQiOjE2LjAsIlRlcnJvcmlzdDpSdW5uaW5nOmJvZHlfeWF3IjoiSml0dGVyIiwiVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX2Nob2tlXzEiOjE2LjAsIlRlcnJvcmlzdDpSdW5uaW5nOmRlZmVuc2l2ZV9jaG9rZV8yIjoxNi4wLCJUZXJyb3Jpc3Q6UnVubmluZzpkZWZlbnNpdmVfY3VzdG9tX2Nob2tlIjpmYWxzZSwiVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX2VuYWJsZWQiOmZhbHNlLCJUZXJyb3Jpc3Q6UnVubmluZzpkZWZlbnNpdmVfZm9yY2VfZGVmZW5zaXZlIjpmYWxzZSwiVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX3BpdGNoIjoiU3RhdGljIiwiVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX3BpdGNoXzEiOjAuMCwiVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX3BpdGNoXzIiOjAuMCwiVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX3BpdGNoX29mZnNldCI6MC4wLCJUZXJyb3Jpc3Q6UnVubmluZzpkZWZlbnNpdmVfcmFuZG9tX2Nob2tlIjpmYWxzZSwiVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX3JhbmRvbWl6YXRpb24iOjAuMCwiVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX3lhdyI6IlN0YXRpYyIsIlRlcnJvcmlzdDpSdW5uaW5nOmRlZmVuc2l2ZV95YXdfMSI6MC4wLCJUZXJyb3Jpc3Q6UnVubmluZzpkZWZlbnNpdmVfeWF3XzIiOjAuMCwiVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX3lhd19vZmZzZXQiOjE4MC4wLCJUZXJyb3Jpc3Q6UnVubmluZzpkZWZlbnNpdmVfeWF3X3NwZWVkIjoyMC4wLCJUZXJyb3Jpc3Q6UnVubmluZzpkZWxheV8xIjowLjAsIlRlcnJvcmlzdDpSdW5uaW5nOmRlbGF5XzIiOjAuMCwiVGVycm9yaXN0OlJ1bm5pbmc6bGVmdF9saW1pdCI6MzYuMCwiVGVycm9yaXN0OlJ1bm5pbmc6bW9kaWZpZXJfb2Zmc2V0IjotNTIuMCwiVGVycm9yaXN0OlJ1bm5pbmc6cmlnaHRfbGltaXQiOjM2LjAsIlRlcnJvcmlzdDpSdW5uaW5nOnlhd19hZGQiOnRydWUsIlRlcnJvcmlzdDpSdW5uaW5nOnlhd19sZWZ0IjotNi4wLCJUZXJyb3Jpc3Q6UnVubmluZzp5YXdfbW9kaWZpZXIiOiJDZW50ZXIiLCJUZXJyb3Jpc3Q6UnVubmluZzp5YXdfb2Zmc2V0IjowLjAsIlRlcnJvcmlzdDpSdW5uaW5nOnlhd19yaWdodCI6MTEuMCwiVGVycm9yaXN0OlNuZWFraW5nOmJvZHlfeWF3IjoiSml0dGVyIiwiVGVycm9yaXN0OlNuZWFraW5nOmRlZmVuc2l2ZV9jaG9rZV8xIjoxNi4wLCJUZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX2Nob2tlXzIiOjE2LjAsIlRlcnJvcmlzdDpTbmVha2luZzpkZWZlbnNpdmVfY3VzdG9tX2Nob2tlIjpmYWxzZSwiVGVycm9yaXN0OlNuZWFraW5nOmRlZmVuc2l2ZV9lbmFibGVkIjpmYWxzZSwiVGVycm9yaXN0OlNuZWFraW5nOmRlZmVuc2l2ZV9mb3JjZV9kZWZlbnNpdmUiOmZhbHNlLCJUZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX3BpdGNoIjoiU3RhdGljIiwiVGVycm9yaXN0OlNuZWFraW5nOmRlZmVuc2l2ZV9waXRjaF8xIjowLjAsIlRlcnJvcmlzdDpTbmVha2luZzpkZWZlbnNpdmVfcGl0Y2hfMiI6MC4wLCJUZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX3BpdGNoX29mZnNldCI6MC4wLCJUZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX3JhbmRvbV9jaG9rZSI6ZmFsc2UsIlRlcnJvcmlzdDpTbmVha2luZzpkZWZlbnNpdmVfcmFuZG9taXphdGlvbiI6MC4wLCJUZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX3lhdyI6IlN0YXRpYyIsIlRlcnJvcmlzdDpTbmVha2luZzpkZWZlbnNpdmVfeWF3XzEiOjAuMCwiVGVycm9yaXN0OlNuZWFraW5nOmRlZmVuc2l2ZV95YXdfMiI6MC4wLCJUZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX3lhd19vZmZzZXQiOjE4MC4wLCJUZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX3lhd19zcGVlZCI6MjAuMCwiVGVycm9yaXN0OlNuZWFraW5nOmRlbGF5XzEiOjAuMCwiVGVycm9yaXN0OlNuZWFraW5nOmRlbGF5XzIiOjAuMCwiVGVycm9yaXN0OlNuZWFraW5nOmxlZnRfbGltaXQiOjU4LjAsIlRlcnJvcmlzdDpTbmVha2luZzptb2RpZmllcl9vZmZzZXQiOi0zNS4wLCJUZXJyb3Jpc3Q6U25lYWtpbmc6cmlnaHRfbGltaXQiOjU4LjAsIlRlcnJvcmlzdDpTbmVha2luZzp5YXdfYWRkIjp0cnVlLCJUZXJyb3Jpc3Q6U25lYWtpbmc6eWF3X2xlZnQiOi0xMC4wLCJUZXJyb3Jpc3Q6U25lYWtpbmc6eWF3X21vZGlmaWVyIjoiQ2VudGVyIiwiVGVycm9yaXN0OlNuZWFraW5nOnlhd19vZmZzZXQiOjAuMCwiVGVycm9yaXN0OlNuZWFraW5nOnlhd19yaWdodCI6MTYuMCwiVGVycm9yaXN0OlN0YW5kaW5nOmJvZHlfeWF3IjoiSml0dGVyIiwiVGVycm9yaXN0OlN0YW5kaW5nOmRlZmVuc2l2ZV9jaG9rZV8xIjoxNi4wLCJUZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX2Nob2tlXzIiOjE2LjAsIlRlcnJvcmlzdDpTdGFuZGluZzpkZWZlbnNpdmVfY3VzdG9tX2Nob2tlIjpmYWxzZSwiVGVycm9yaXN0OlN0YW5kaW5nOmRlZmVuc2l2ZV9lbmFibGVkIjpmYWxzZSwiVGVycm9yaXN0OlN0YW5kaW5nOmRlZmVuc2l2ZV9mb3JjZV9kZWZlbnNpdmUiOmZhbHNlLCJUZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX3BpdGNoIjoiU3RhdGljIiwiVGVycm9yaXN0OlN0YW5kaW5nOmRlZmVuc2l2ZV9waXRjaF8xIjowLjAsIlRlcnJvcmlzdDpTdGFuZGluZzpkZWZlbnNpdmVfcGl0Y2hfMiI6MC4wLCJUZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX3BpdGNoX29mZnNldCI6MC4wLCJUZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX3JhbmRvbV9jaG9rZSI6ZmFsc2UsIlRlcnJvcmlzdDpTdGFuZGluZzpkZWZlbnNpdmVfcmFuZG9taXphdGlvbiI6MC4wLCJUZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX3lhdyI6IlN0YXRpYyIsIlRlcnJvcmlzdDpTdGFuZGluZzpkZWZlbnNpdmVfeWF3XzEiOjAuMCwiVGVycm9yaXN0OlN0YW5kaW5nOmRlZmVuc2l2ZV95YXdfMiI6MC4wLCJUZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX3lhd19vZmZzZXQiOjE4MC4wLCJUZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX3lhd19zcGVlZCI6MjAuMCwiVGVycm9yaXN0OlN0YW5kaW5nOmRlbGF5XzEiOjAuMCwiVGVycm9yaXN0OlN0YW5kaW5nOmRlbGF5XzIiOjAuMCwiVGVycm9yaXN0OlN0YW5kaW5nOmxlZnRfbGltaXQiOjMwLjAsIlRlcnJvcmlzdDpTdGFuZGluZzptb2RpZmllcl9vZmZzZXQiOi00Ni4wLCJUZXJyb3Jpc3Q6U3RhbmRpbmc6cmlnaHRfbGltaXQiOjMwLjAsIlRlcnJvcmlzdDpTdGFuZGluZzp5YXdfYWRkIjp0cnVlLCJUZXJyb3Jpc3Q6U3RhbmRpbmc6eWF3X2xlZnQiOi03LjAsIlRlcnJvcmlzdDpTdGFuZGluZzp5YXdfbW9kaWZpZXIiOiJDZW50ZXIiLCJUZXJyb3Jpc3Q6U3RhbmRpbmc6eWF3X29mZnNldCI6MC4wLCJUZXJyb3Jpc3Q6U3RhbmRpbmc6eWF3X3JpZ2h0IjoxMS4wLCJUZXJyb3Jpc3Q6V2Fsa2luZzpib2R5X3lhdyI6IkppdHRlciIsIlRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV9jaG9rZV8xIjoxNi4wLCJUZXJyb3Jpc3Q6V2Fsa2luZzpkZWZlbnNpdmVfY2hva2VfMiI6MTYuMCwiVGVycm9yaXN0OldhbGtpbmc6ZGVmZW5zaXZlX2N1c3RvbV9jaG9rZSI6ZmFsc2UsIlRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV9lbmFibGVkIjpmYWxzZSwiVGVycm9yaXN0OldhbGtpbmc6ZGVmZW5zaXZlX2ZvcmNlX2RlZmVuc2l2ZSI6ZmFsc2UsIlRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV9waXRjaCI6IlN0YXRpYyIsIlRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV9waXRjaF8xIjowLjAsIlRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV9waXRjaF8yIjowLjAsIlRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV9waXRjaF9vZmZzZXQiOjAuMCwiVGVycm9yaXN0OldhbGtpbmc6ZGVmZW5zaXZlX3JhbmRvbV9jaG9rZSI6ZmFsc2UsIlRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV9yYW5kb21pemF0aW9uIjowLjAsIlRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV95YXciOiJTdGF0aWMiLCJUZXJyb3Jpc3Q6V2Fsa2luZzpkZWZlbnNpdmVfeWF3XzEiOjAuMCwiVGVycm9yaXN0OldhbGtpbmc6ZGVmZW5zaXZlX3lhd18yIjowLjAsIlRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV95YXdfb2Zmc2V0IjoxODAuMCwiVGVycm9yaXN0OldhbGtpbmc6ZGVmZW5zaXZlX3lhd19zcGVlZCI6MjAuMCwiVGVycm9yaXN0OldhbGtpbmc6ZGVsYXlfMSI6MC4wLCJUZXJyb3Jpc3Q6V2Fsa2luZzpkZWxheV8yIjowLjAsIlRlcnJvcmlzdDpXYWxraW5nOmxlZnRfbGltaXQiOjQ1LjAsIlRlcnJvcmlzdDpXYWxraW5nOm1vZGlmaWVyX29mZnNldCI6LTUuMCwiVGVycm9yaXN0OldhbGtpbmc6cmlnaHRfbGltaXQiOjQ1LjAsIlRlcnJvcmlzdDpXYWxraW5nOnlhd19hZGQiOnRydWUsIlRlcnJvcmlzdDpXYWxraW5nOnlhd19sZWZ0IjotMjMuMCwiVGVycm9yaXN0OldhbGtpbmc6eWF3X21vZGlmaWVyIjoiU3BpbiIsIlRlcnJvcmlzdDpXYWxraW5nOnlhd19vZmZzZXQiOjAuMCwiVGVycm9yaXN0OldhbGtpbmc6eWF3X3JpZ2h0Ijo0Ny4wLCJhdm9pZF9iYWNrc3RhYi5lbmFibGVkIjp0cnVlLCJmbGlja19leHBsb2l0LmNvbmRpdGlvbnMiOltdLCJmbGlja19leHBsb2l0LmVuYWJsZWQiOmZhbHNlLCJmcmVlc3RhbmRpbmcuZGlzYWJsZXJzIjpbIkluIEFpciIsIkFpciBDcm91Y2giXSwiZnJlZXN0YW5kaW5nLmVuYWJsZWQiOmZhbHNlLCJmcmVlc3RhbmRpbmcuc3RhdGljIjpmYWxzZSwibWFudWFsX3lhdy5kaXJlY3Rpb24iOiJEaXNhYmxlZCIsIm1hbnVhbF95YXcuZGlzYWJsZXJzIjpbXSwibWFudWFsX3lhdy5zdGF0aWMiOmZhbHNlLCJtb2RpZnlfb25fd2FybXVwLmVuYWJsZWQiOnRydWUsIm9uX3VzZS5lbmFibGVkIjp0cnVlLCJzYWZlX2hlYWQuY29uZGl0aW9ucyI6WyJTdGFuZGluZyIsIkNyb3VjaCIsIkFpciBDcm91Y2giLCJBaXIgS25pZmUiLCJBaXIgVGFzZXIiLCJEaXN0YW5jZSJdLCJzYWZlX2hlYWQuZW5hYmxlZCI6dHJ1ZX0sIk1pc2NlbGxhbmVvdXMiOnsiYXZvaWRfY29sbGlzaW9ucy5lbmFibGVkIjpmYWxzZSwiY2xhbnRhZy5lbmFibGVkIjpmYWxzZSwiY29sbGlzaW9uX2Fpcl9kdWNrLmVuYWJsZWQiOmZhbHNlLCJlZGdlX3N0b3AuZW5hYmxlZCI6ZmFsc2UsImZhc3RfbGFkZGVyLmVuYWJsZWQiOnRydWUsIm5vX2ZhbGxfZGFtYWdlLmVuYWJsZWQiOnRydWUsInN1cGVyX3Rvc3MuZW5hYmxlZCI6dHJ1ZSwidHJhc2h0YWxrLmRlbGF5IjozMC4wLCJ0cmFzaHRhbGsuZW5hYmxlZCI6ZmFsc2UsInVubG9ja19mZF9zcGVlZC5lbmFibGVkIjp0cnVlfSwiVmlzdWFscyI6eyJhbmltYXRpb25zLmVhcnRocXVha2UiOmZhbHNlLCJhbmltYXRpb25zLmVuYWJsZWQiOmZhbHNlLCJhbmltYXRpb25zLmluX2FpciI6IkRpc2FibGVkIiwiYW5pbWF0aW9ucy5tb3ZlX2xlYW4iOjAuMCwiYW5pbWF0aW9ucy5vbl9ncm91bmQiOiJEaXNhYmxlZCIsImFuaW1hdGlvbnMucGl0Y2hfb25fbGFuZCI6ZmFsc2UsImFuaW1hdGlvbnMuc2xpZGluZ19jcm91Y2giOmZhbHNlLCJhbmltYXRpb25zLnNsaWRpbmdfc2xvd3dhbGsiOmZhbHNlLCJhc3BlY3RfcmF0aW8uZW5hYmxlZCI6ZmFsc2UsImFzcGVjdF9yYXRpby5wcm9wb3J0aW9uIjowLjAsImNvbnNvbGVfY29sb3IuY29sb3IiOiI4MDgwODA5RSIsImNvbnNvbGVfY29sb3IuZW5hYmxlZCI6dHJ1ZSwiY3Jvc3NoYWlyX2luZGljYXRvcnMuY29sb3IiOiJGRkI3NEZGRiIsImNyb3NzaGFpcl9pbmRpY2F0b3JzLmVuYWJsZWQiOnRydWUsImNyb3NzaGFpcl9pbmRpY2F0b3JzLm9mZnNldCI6NDAuMCwiZGFtYWdlX2luZGljYXRvci5jb2xvciI6IkZGRkZGRkZGIiwiZGFtYWdlX2luZGljYXRvci5lbmFibGVkIjp0cnVlLCJkYW1hZ2VfaW5kaWNhdG9yLmZvbnQiOiJTbWFsbCIsImhpdF9tYXJrZXIuY29sb3IiOiIwMDAwMDBGRiIsImhpdF9tYXJrZXIuZW5hYmxlZCI6dHJ1ZSwiaGl0X21hcmtlci5zaXplIjo0LjAsImhpdF9tYXJrZXIudGhpY2tuZXNzIjoyLjAsImtlZXBfdHJhbnNwYXJlbmN5LmVuYWJsZWQiOnRydWUsImxhZ19jb21wX2JveC5jb2xvciI6IjJGNzVEREZGIiwibGFnX2NvbXBfYm94LmVuYWJsZWQiOnRydWUsIm1hbnVhbF9hcnJvd3MuY29sb3IiOiJGRkZGRkZGRiIsIm1hbnVhbF9hcnJvd3MuZW5hYmxlZCI6dHJ1ZSwibWFudWFsX2Fycm93cy5vZmZzZXQiOjQwLjAsIm5hZGVfcmFkaXVzLmVuYWJsZWQiOnRydWUsIm5hZGVfcmFkaXVzLm1vbG90b3YiOnRydWUsIm5hZGVfcmFkaXVzLm1vbG90b3ZfY29sb3IiOiJEODk4NjBGRiIsIm5hZGVfcmFkaXVzLnNtb2tlIjp0cnVlLCJuYWRlX3JhZGl1cy5zbW9rZV9jb2xvciI6Ijg2OTRDNEZGIiwicmVtb3ZlX2Zvb3RzdGVwc19zaGFkb3cuZW5hYmxlZCI6dHJ1ZSwic2NvcGVfb3ZlcmxheS5hZGRpdGlvbnMiOltdLCJzY29wZV9vdmVybGF5LmNvbG9yIjoiRkZGRkZGOUUiLCJzY29wZV9vdmVybGF5LmVuYWJsZWQiOnRydWUsInNjb3BlX292ZXJsYXkuZXhjbHVkZV9saW5lcyI6W10sInNjb3BlX292ZXJsYXkuZ2FwIjowLjAsInNjb3BlX292ZXJsYXkuc2l6ZSI6NTUuMCwic2tlZXRfaW5kaWNhdG9ycy5lbmFibGVkIjp0cnVlLCJza2VldF9pbmRpY2F0b3JzLml0ZW1zIjpbMS4wLDIuMCwzLjAsNC4wLDUuMCw2LjAsNy4wLDguMCw5LjAsMTAuMCwxMS4wXSwidmVsb2NpdHlfd2FybmluZy5jb2xvciI6IkZGQjc0RkZGIiwidmVsb2NpdHlfd2FybmluZy5lbmFibGVkIjp0cnVlLCJ2ZWxvY2l0eV93YXJuaW5nLm9mZnNldCI6MTYwLjAsInZpZXdtb2RlbC5lbmFibGVkIjpmYWxzZSwidmlld21vZGVsLmZvdiI6NjgwLjAsInZpZXdtb2RlbC5vZmZzZXRfeCI6MjUuMCwidmlld21vZGVsLm9mZnNldF95IjowLjAsInZpZXdtb2RlbC5vZmZzZXRfeiI6LTE1LjB9fQ__");

        local function centered_preset_icon(icon_name, tint)
            local glyph = icons.get(icon_name) or ""
            local measured_width = 12
            local pad_width = 2.2
            local ok, measured = pcall(render.measure_text, 2, nil, glyph)
            if ok and measured and measured.x then measured_width = measured.x end
            ok, measured = pcall(render.measure_text, 2, nil, PAD)
            if ok and measured and measured.x and measured.x > 0 then pad_width = measured.x end
            local target_width = 25
            local pads = math.max(0, math.ceil((target_width - measured_width) / (2 * pad_width)))
            local prefix = tint or ""
            local suffix = tint and "\aDEFAULT" or ""
            local side = string.rep(PAD, pads)
            return concat(side, prefix, glyph, suffix, side)
        end

        local function clean_preset_ui_text(value)
            if type(value) ~= "string" then return "" end
            value = value:gsub("##ss", "")
            value = value:gsub("##[%w_%-]+$", "")
            value = value:gsub("%s+$", "")
            return value
        end

        local function normalize_preset_name(value)
            value = clean_preset_ui_text(value)
            value = value:gsub("\a%x%x%x%x%x%x%x%x", "")
            value = value:gsub("\a%b{}", "")
            value = value:gsub("\226\128\139", "")
            value = value:gsub("\226\128\141", "")
            value = value:gsub("\226\129\160", "")
            value = value:gsub("\194\160", " ")
            value = value:gsub("[%s%p]+", "")
            return string.lower(value)
        end

        local reserved_builtin_names = {}
        for _, entry in ipairs(builtin_presets) do
            reserved_builtin_names[normalize_preset_name(entry.name)] = true
        end
        local cleaned_saved_presets = {}
        local seen_saved_names = {}
        local saved_presets_changed = false
        for _, entry in ipairs(saved_presets) do
            local normalized_name = type(entry) == "table" and normalize_preset_name(entry.name) or ""
            if normalized_name == "" or reserved_builtin_names[normalized_name] or seen_saved_names[normalized_name] then
                saved_presets_changed = true
            else
                seen_saved_names[normalized_name] = true
                cleaned_saved_presets[#cleaned_saved_presets + 1] = entry
            end
        end
        if saved_presets_changed then
            saved_presets = cleaned_saved_presets
            db[presets_db_key] = saved_presets
        end

        local function preset_names(entries)
            local names = {}
            for _, entry in ipairs(entries) do
                local label = clean_preset_ui_text(entry.name)
                names[#names + 1] = label
            end
            if #names == 0 then
                names[1] = "\aFFFFFF40Empty presets list..."
            end
            return names
        end

        local function find_entry(entries, name)
            local wanted = normalize_preset_name(name)
            if wanted == "" then return nil end
            for index, entry in ipairs(entries) do
                if type(entry) == "table" and normalize_preset_name(entry.name) == wanted then
                    return entry, index
                end
            end
            return nil
        end

        local function refresh_presets()
            preset_list = {}
            local seen_names = {}
            local function append_unique(entry)
                if type(entry) ~= "table" then return false end
                local normalized_name = normalize_preset_name(entry.name)
                if normalized_name == "" or seen_names[normalized_name] then return false end
                seen_names[normalized_name] = true
                preset_list[#preset_list + 1] = entry
                return true
            end

            for _, entry in ipairs(builtin_presets) do
                append_unique(entry)
            end
            local filtered_saved = {}
            for _, entry in ipairs(saved_presets) do
                if append_unique(entry) then
                    filtered_saved[#filtered_saved + 1] = entry
                end
            end
            if #filtered_saved ~= #saved_presets then
                saved_presets = filtered_saved
                db[presets_db_key] = saved_presets
            end
            if presets_ui.list then
                presets_ui.list:update(preset_names(preset_list))
            end
        end

        local function load_preset()
            local name = clean_preset_ui_text(presets_ui.name:get())
            if name == "" then return end
            local entry = find_entry(builtin_presets, name) or find_entry(saved_presets, name)
            if not entry or type(entry.data) ~= "string" or entry.data == "" then
                notify.error("Preset data is invalid!")
                return
            end
            local ok, decoded = preset_manager.decode(entry.data)
            if not ok or decoded == nil then
                notify.error(decoded or "Preset data is invalid!")
                return
            end
            local imported, count = preset_manager.import(decoded)
            if not imported then
                notify.error(count or "Preset import failed!")
                return
            end
            notify.success(string.format("%d groups successfully loaded!", count))
        end

        local function save_preset()
            local name = clean_preset_ui_text(presets_ui.name:get())
            if name == "" then return end
            if find_entry(builtin_presets, name) then
                notify.error("Can't modify built-in preset!")
                return
            end
            local ok, encoded = preset_manager.encode(preset_manager.export())
            if not ok then
                notify.error(encoded or "Preset export failed!")
                return
            end
            local entry = find_entry(saved_presets, name)
            if entry then
                entry.data = encoded
            else
                saved_presets[#saved_presets + 1] = {name = name, data = encoded}
            end
            db[presets_db_key] = saved_presets
            refresh_presets()
            notify.success("Preset successfully saved!")
        end

        local function delete_preset()
            local name = clean_preset_ui_text(presets_ui.name:get())
            local _, index = find_entry(saved_presets, name)
            if not index then
                if find_entry(builtin_presets, name) then
                    notify.error("Can't delete built-in preset!")
                else
                    notify.error("Preset not selected!")
                end
                return
            end
            table.remove(saved_presets, index)
            db[presets_db_key] = saved_presets
            refresh_presets()
            presets_ui.name:set("")
            notify.success("Preset successfully deleted!")
        end

        local function import_preset()
            local ok, decoded = preset_manager.decode(clipboard.get())
            if not ok or decoded == nil then
                notify.error(decoded or "Preset is empty!")
                return
            end
            local imported, count = preset_manager.import(decoded)
            if not imported then
                notify.error(count or "Preset import failed!")
                return
            end
            notify.success(string.format("%d groups successfully imported!", count))
        end

        local function export_preset()
            local ok, encoded = preset_manager.encode(preset_manager.export())
            if not ok then
                notify.error(encoded or "Preset export failed!")
                return
            end
            clipboard.set(encoded)
            notify.success("Preset successfully exported!")
        end

        source_controls.accent_color = preset_manager.push(
            "Visuals", "accent_color",
            home_containers.profile:color_picker(
                concat(pad_spaces(4), icon_label("palette"), pad_spaces(7), "Accent Color"),
                color4(192, 202, 255, 255)
            )
        )
        source_controls.transparent = preset_manager.push(
            "Visuals", "transparent.enabled",
            home_containers.profile:switch(concat(pad_spaces(3), icon_label("eye"), pad_spaces(7), "Transparent"), false)
        )

        builtin_ui.header = home_containers.presets:label(section_label("Presets"))
        presets_ui.list = home_containers.presets:list("##presets.list", {})
        presets_ui.list:set_callback(function(control)
            local index = control:get()
            local entry = index and preset_list[index]
            if not entry then return end
            presets_ui.name:set(clean_preset_ui_text(entry.name))
        end, true)
        presets_ui.name = home_containers.presets:input("Preset Name")
        presets_ui.load_button = home_containers.presets:button(centered_preset_icon("check"), load_preset, true)
        presets_ui.save_button = home_containers.presets:button(centered_preset_icon("floppy-disk"), save_preset, true)
        presets_ui.delete_button = home_containers.presets:button(centered_preset_icon("trash-can", "\aFF5050FF"), delete_preset, true)
        presets_ui.import_button = home_containers.presets:button(centered_preset_icon("down-to-bracket"), import_preset, true)
        presets_ui.export_button = home_containers.presets:button(centered_preset_icon("up-from-bracket"), export_preset, true)

        refresh_presets()
        presets_tab.main = presets_ui
        presets_tab.builtin = builtin_ui
    end
    home_tab.presets = presets_tab
    ui_controls.home = home_tab;
    local home_icon = {};
    local home_containers = icons.get("shield");
    local antiaim_tabs = {
        tweaks = ui.create(home_containers, "##tweaks", 1),
        angles = ui.create(home_containers, "##angles", 2),
        hotkeys = ui.create(home_containers, "##hotkeys", 1),
        builder = ui.create(home_containers, "##builder", 2),
        defensive = ui.create(home_containers, "##defenive", 2)
    };
    local presets_tab = {
        avoid_backstab = {
            enabled = preset_manager.push("Anti-Aim", "avoid_backstab.enabled", antiaim_tabs.tweaks:switch(concat(pad_spaces(2), icon_label("knife-kitchen"), pad_spaces(7), "Avoid Backstab")))
        },
        on_use = {
            enabled = preset_manager.push("Anti-Aim", "on_use.enabled", antiaim_tabs.tweaks:switch(concat(pad_spaces(2), icon_label("user-helmet-safety"), pad_spaces(7), "On Use")))
        },
        modify_on_warmup = {
            enabled = preset_manager.push("Anti-Aim", "modify_on_warmup.enabled", antiaim_tabs.tweaks:switch(concat(pad_spaces(2), icon_label("shuffle"), pad_spaces(7), "Modify on Warmup")))
        }
    };
    local preset_list = {
        enabled = preset_manager.push("Anti-Aim", "flick_exploit.enabled", antiaim_tabs.tweaks:switch(concat(pad_spaces(2), icon_label("wand-magic-sparkles"), pad_spaces(7), "Flick Exploit")))
    };
    local builtin_presets = preset_list.enabled:create();
    preset_list.conditions = preset_manager.push("Anti-Aim", "flick_exploit.conditions", builtin_presets:selectable("Conditions", {
        [1] = "Standing",
        [2] = "Walking",
        [3] = "Crouching",
        [4] = "Sneaking"
    }));
    presets_tab.flick_exploit = preset_list;
    local builtin_presets = {
        enabled = preset_manager.push("Anti-Aim", "safe_head.enabled", antiaim_tabs.tweaks:switch(concat(pad_spaces(2), icon_label("face-head-bandage"), pad_spaces(7), "Safe Head")))
    };
    local container = builtin_presets.enabled:create();
    builtin_presets.conditions = preset_manager.push("Anti-Aim", "safe_head.conditions", container:selectable("Conditions", {
        [1] = "Standing",
        [2] = "Crouch",
        [3] = "Air Crouch",
        [4] = "Air Knife",
        [5] = "Air Taser",
        [6] = "Distance"
    }));
    presets_tab.safe_head = builtin_presets;
    local anim_breaker = {
        enabled = preset_manager.push("Anti-Aim", "anim_breaker.enabled", antiaim_tabs.tweaks:switch(concat(pad_spaces(2), icon_label("seedling"), pad_spaces(7), "Anim Breakers")))
    };
    local anim_breaker_group = anim_breaker.enabled:create();
    anim_breaker.air = preset_manager.push("Anti-Aim", "anim_breaker.air", anim_breaker_group:combo("Air", {
        [1] = "None",
        [2] = "Static",
        [3] = "Walking"
    }));
    anim_breaker.move = preset_manager.push("Anti-Aim", "anim_breaker.move", anim_breaker_group:combo("Ground", {
        [1] = "None",
        [2] = "Slide",
        [3] = "Shake",
        [4] = "Walking"
    }));
    anim_breaker.other = preset_manager.push("Anti-Aim", "anim_breaker.other", anim_breaker_group:selectable("Other", {
        [1] = "Flashed",
        [2] = "Move lean",
        [3] = "Landing pitch",
        [4] = "Static creeping"
    }));
    anim_breaker.lean_weight = preset_manager.push("Anti-Aim", "anim_breaker.lean_weight", anim_breaker_group:slider("Lean weight", 0, 100, 100, 1, "%"));
    do
        local function update_anim_breaker_visibility()
            local enabled = anim_breaker.enabled:get();
            anim_breaker_group:visibility(enabled);
            anim_breaker.lean_weight:visibility(anim_breaker.other:get("Move lean"));
        end;
        anim_breaker.enabled:set_callback(update_anim_breaker_visibility, true);
        anim_breaker.other:set_callback(update_anim_breaker_visibility, true);
        update_anim_breaker_visibility();
    end;
    presets_tab.anim_breaker = anim_breaker;
    source_controls.lc_enabled=preset_manager.push("Anti-Aim","auto_lc.enabled",antiaim_tabs.tweaks:switch(concat(pad_spaces(3),icon_label("bolt"),pad_spaces(7),"Auto LC"),true))
    local lc_group = source_controls.lc_enabled:create();
    source_controls.lc_mode=preset_manager.push("Anti-Aim","auto_lc.mode",lc_group:combo("Air Teleport",{"On enemy","Exploit"}))
    source_controls.lc_on_cross=preset_manager.push("Anti-Aim","auto_lc.on_cross",lc_group:switch("Allow on cross",true))
    source_controls.lc_weapons=preset_manager.push("Anti-Aim","auto_lc.weapons",lc_group:selectable("Weapons",{"AWP","SSG 08","Taser"}))
    ensure_defaults(source_controls.lc_weapons)
    source_controls.lc_exploit_ticks=preset_manager.push("Anti-Aim","auto_lc.exploit_ticks",lc_group:slider("Exploit ticks",10,30,10,1,"t"))
    do
        local function update_lc_visibility()
            local mode = source_controls.lc_mode:get();
            lc_group:visibility(source_controls.lc_enabled:get());
            source_controls.lc_on_cross:visibility(mode == "On enemy");
            source_controls.lc_weapons:visibility(mode == "On enemy");
            source_controls.lc_exploit_ticks:visibility(mode == "Exploit");
        end;
        source_controls.lc_mode:set_callback(update_lc_visibility, true);
        source_controls.lc_enabled:set_callback(update_lc_visibility, true);
        update_lc_visibility();
    end;
    source_controls.exploit_backtrack = preset_manager.push("Rage", "exploit_backtrack.enabled", antiaim_tabs.tweaks:switch(concat(pad_spaces(3), icon_label("rewind"), pad_spaces(7), "Exploit Backtrack"), false))
    source_controls.exploit_backtrack_status = "off"
    source_controls.adaptive_fakelags = preset_manager.push("Rage", "adaptive_fakelags.enabled", antiaim_tabs.tweaks:switch(concat(pad_spaces(3), icon_label("activity"), pad_spaces(7), "Adaptive Fake Lags"), false))
    source_controls.predict_uncharge = preset_manager.push("Rage", "predict_uncharge.enabled", antiaim_tabs.tweaks:switch(concat(pad_spaces(3), icon_label("crosshair"), pad_spaces(7), "Predict Exploit Uncharge"), false))
    source_controls.predict_uncharge_status = "off"
    home_icon.tweaks = presets_tab;
    local presets_ui = {};
    local presets_db_key = {
        enabled = preset_manager.push("Anti-Aim", "freestanding.enabled", antiaim_tabs.hotkeys:switch(concat(pad_spaces(2), icon_label("compass"), pad_spaces(7), "Freestanding")))
    };
    local saved_presets = presets_db_key.enabled:create();
    presets_db_key.static = preset_manager.push("Anti-Aim", "freestanding.static", saved_presets:switch("Static Freestanding"));
    presets_db_key.disablers = preset_manager.push("Anti-Aim", "freestanding.disablers", saved_presets:selectable("Disablers", {
        [1] = "Standing",
        [2] = "Running",
        [3] = "Walking",
        [4] = "Crouching",
        [5] = "Sneaking",
        [6] = "In Air",
        [7] = "Air Crouch"
    }));
    presets_ui.freestanding = presets_db_key;
    local saved_presets = {
        direction = preset_manager.push("Anti-Aim", "manual_yaw.direction", antiaim_tabs.hotkeys:combo(concat(pad_spaces(2), icon_label("arrows-left-right"), pad_spaces(7), "Manual Yaw"), {
            [1] = "Disabled",
            [2] = "Left",
            [3] = "Right",
            [4] = "Backward",
            [5] = "Forward"
        }))
    };
    local preset_list = saved_presets.direction:create();
    saved_presets.static = preset_manager.push("Anti-Aim", "manual_yaw.static", preset_list:switch("Static Manual Yaw"));
    saved_presets.disablers = preset_manager.push("Anti-Aim", "manual_yaw.disablers", preset_list:selectable("Disablers", {
        [1] = "Standing",
        [2] = "Running",
        [3] = "Walking",
        [4] = "Crouching",
        [5] = "Sneaking",
        [6] = "In Air",
        [7] = "Air Crouch"
    }));
    presets_ui.manual_yaw = saved_presets;
    home_icon.hotkeys = presets_ui;
    local presets_db_key = function()
        local state = home_icon.builder.state:get();
        local team = home_icon.builder.team:get();
        for team_index = 1, #enums.teams do
            local team_name = enums.teams[team_index];
            local team_selected = team_name == team;
            for state_index = 1, #enums.states do
                local state_name = enums.states[state_index];
                local state_selected = state_name == state;
                local visible = team_selected and state_selected;
                local angles = home_icon.builder[team_name][state_name].angles;
                angles.yaw_offset:visibility(visible);
                angles.yaw_add:visibility(visible);
                angles.yaw_modifier:visibility(visible);
                angles.body_yaw:visibility(visible);
                local defensive = home_icon.builder[team_name][state_name].defensive;
                defensive.force_defensive:visibility(visible);
                defensive.enabled:visibility(visible);
                if not defensive.enabled:get() then
                    visible = false;
                end;
                defensive.pitch:visibility(visible);
                defensive.yaw:visibility(visible);
            end;
        end;
    end;
    do
        local saved_presets = function(build_defensive, arg38)
            local defensive2 = {};
            local function defensive_key(arg39)
                return build_defensive .. ":" .. arg38 .. ":defensive_" .. arg39;
            end;
            defensive2.force_defensive = preset_manager.push("Anti-Aim", defensive_key("force_defensive"), antiaim_tabs.defensive:switch(hidden_label(section_label("Force Defensive"), defensive_key("force_defensive"))));
            local container2 = defensive2.force_defensive:create();
            defensive2.custom_choke = preset_manager.push("Anti-Aim", defensive_key("custom_choke"), container2:switch("Custom Choke"));
            defensive2.random_choke = preset_manager.push("Anti-Aim", defensive_key("random_choke"), container2:switch("Randomize Choke"));
            defensive2.choke_1 = preset_manager.push("Anti-Aim", defensive_key("choke_1"), container2:slider("Choke", 1, 22, 16, nil, "t"));
            defensive2.choke_2 = preset_manager.push("Anti-Aim", defensive_key("choke_2"), container2:slider("2nd Choke", 1, 22, 16, nil, "t"));
            local value21 = nil;
            local function update_choke_visibility()
                local enabled = defensive2.force_defensive:get();
                defensive2.custom_choke:visibility(enabled);
                if not defensive2.custom_choke:get() then
                    enabled = false;
                end;
                defensive2.random_choke:visibility(enabled);
                defensive2.choke_1:visibility(enabled);
                if not defensive2.random_choke:get() then
                    enabled = false;
                end;
                defensive2.choke_2:visibility(enabled);
            end;
            defensive2.force_defensive:set_callback(update_choke_visibility);
            defensive2.custom_choke:set_callback(update_choke_visibility);
            defensive2.random_choke:set_callback(update_choke_visibility);
            update_choke_visibility();
            defensive2.enabled = preset_manager.push("Anti-Aim", defensive_key("enabled"), antiaim_tabs.defensive:switch(hidden_label(section_label("Hidden", "\a{Link Active}"), defensive_key("enabled")))):set_callback(presets_db_key);
            defensive2.pitch = preset_manager.push("Anti-Aim", defensive_key("pitch"), antiaim_tabs.defensive:combo(hidden_label(section_label("Pitch"), defensive_key("pitch")), {
                [1] = "Static",
                [2] = "Jitter",
                [3] = "Random",
                [4] = "Spin",
                [5] = "Sway"
            }));
            value21 = defensive2.pitch:create();
            defensive2.pitch_offset = preset_manager.push("Anti-Aim", defensive_key("pitch_offset"), value21:slider("Offset", -89, 89, 0, 1, "\194\176"));
            defensive2.pitch_1 = preset_manager.push("Anti-Aim", defensive_key("pitch_1"), value21:slider("From", -89, 89, 0, 1, "\194\176"));
            defensive2.pitch_2 = preset_manager.push("Anti-Aim", defensive_key("pitch_2"), value21:slider("To", -89, 89, 0, 1, "\194\176"));
            update_choke_visibility = nil;
            local function update_pitch_visibility()
                local method = defensive2.pitch:get();
                defensive2.pitch_offset:visibility(method == "Static");
                defensive2.pitch_1:visibility(method ~= "Static");
                defensive2.pitch_2:visibility(method ~= "Static");
            end;
            defensive2.pitch:set_callback(update_pitch_visibility, true);
            defensive2.yaw = preset_manager.push("Anti-Aim", defensive_key("yaw"), antiaim_tabs.defensive:combo(hidden_label(section_label("Yaw"), defensive_key("yaw")), {
                [1] = "Static",
                [2] = "Switch",
                [3] = "Random",
                [4] = "Spin",
                [5] = "Sway",
                [6] = "Distortion",
                [7] = "Ember Spin"
            }));
            update_choke_visibility = defensive2.yaw:create();
            defensive2.yaw_offset = preset_manager.push("Anti-Aim", defensive_key("yaw_offset"), update_choke_visibility:slider("Offset", 0, 360, 180, 1, "\194\176"));
            defensive2.yaw_1 = preset_manager.push("Anti-Aim", defensive_key("yaw_1"), update_choke_visibility:slider("From", -180, 180, 0, 1, "\194\176"));
            defensive2.yaw_2 = preset_manager.push("Anti-Aim", defensive_key("yaw_2"), update_choke_visibility:slider("To", -180, 180, 0, 1, "\194\176"));
            defensive2.randomization = preset_manager.push("Anti-Aim", defensive_key("randomization"), update_choke_visibility:slider("Randomization", 0, 20, 0, 1, "\194\176"));
            defensive2.yaw_speed = preset_manager.push("Anti-Aim", defensive_key("yaw_speed"), update_choke_visibility:slider("Speed", -50, 50, 20, 0.1));
            update_pitch_visibility = nil;
            local function update_yaw_visibility()
                local method2 = defensive2.yaw:get();
                defensive2.yaw_offset:visibility(method2 == "Static" or not (method2 ~= "Spin") or method2 == "Sway" or method2 == "Distortion" or method2 == "Ember Spin");
                defensive2.yaw_1:visibility(method2 == "Switch" or method2 == "Random");
                defensive2.yaw_2:visibility(method2 == "Switch" or method2 == "Random");
                defensive2.randomization:visibility(method2 == "Switch");
                defensive2.yaw_speed:visibility(method2 == "Spin" or method2 == "Sway" or method2 == "Distortion" or method2 == "Ember Spin");
            end;
            defensive2.yaw:set_callback(update_yaw_visibility, true);
            return defensive2;
        end;
        local preset_list = function(build_angles, arg40)
            local angles2 = {};
            local function angles_key(arg41)
                return build_angles .. ":" .. arg40 .. ":" .. arg41;
            end;
            angles2.yaw_offset = preset_manager.push("Anti-Aim", angles_key("yaw_offset"), antiaim_tabs.builder:slider(hidden_label(section_label("Yaw Offset"), angles_key("yaw_offset")), -180, 180, 0, nil, "\194\176"));
            angles2.yaw_add = preset_manager.push("Anti-Aim", angles_key("yaw_add"), antiaim_tabs.builder:switch(hidden_label(section_label("Yaw Add"), angles_key("yaw_add"))));
            local container3 = angles2.yaw_add:create();
            angles2.yaw_left = preset_manager.push("Anti-Aim", angles_key("yaw_left"), container3:slider("Left Offset", -180, 180, 0, nil, "\194\176"));
            angles2.yaw_right = preset_manager.push("Anti-Aim", angles_key("yaw_right"), container3:slider("Right Offset", -180, 180, 0, nil, "\194\176"));
            local function update_yaw_add_visibility()
                local enabled2 = angles2.yaw_add:get();
                angles2.yaw_left:visibility(enabled2);
                angles2.yaw_right:visibility(enabled2);
            end;
            angles2.yaw_add:set_callback(update_yaw_add_visibility, true);
            angles2.yaw_modifier = preset_manager.push("Anti-Aim", angles_key("yaw_modifier"), antiaim_tabs.builder:combo(hidden_label(section_label("Yaw Modifier"), angles_key("yaw_modifier")), {
                [1] = "Disabled",
                [2] = "Center",
                [3] = "Offset",
                [4] = "Random",
                [5] = "Spin",
                [6] = "3-Way",
                [7] = "5-Way"
            }));
            update_yaw_add_visibility = angles2.yaw_modifier:create();
            angles2.modifier_offset = preset_manager.push("Anti-Aim", angles_key("modifier_offset"), update_yaw_add_visibility:slider("Offset", -180, 180, 0, nil, "\194\176"));
            local function update_modifier_visibility()
                local method3 = angles2.yaw_modifier:get();
                angles2.modifier_offset:visibility(method3 ~= "Disabled");
            end;
            angles2.yaw_modifier:set_callback(update_modifier_visibility, true);
            angles2.body_yaw = preset_manager.push("Anti-Aim", angles_key("body_yaw"), antiaim_tabs.builder:combo(hidden_label(section_label("Body Yaw"), angles_key("body_yaw")), {
                [1] = "Disabled",
                [2] = "Left",
                [3] = "Right",
                [4] = "Jitter",
                [5] = "Randomize Jitter"
            }));
            update_modifier_visibility = angles2.body_yaw:create();
            angles2.left_limit = preset_manager.push("Anti-Aim", angles_key("left_limit"), update_modifier_visibility:slider("Left Limit", 0, 60, 60, nil, "\194\176"));
            angles2.right_limit = preset_manager.push("Anti-Aim", angles_key("right_limit"), update_modifier_visibility:slider("Right Limit", 0, 60, 60, nil, "\194\176"));
            angles2.delay_1 = preset_manager.push("Anti-Aim", angles_key("delay_1"), update_modifier_visibility:slider("Delay", 0, 16, 0, nil, "t"));
            angles2.delay_2 = preset_manager.push("Anti-Aim", angles_key("delay_2"), update_modifier_visibility:slider("2nd Delay", 0, 16, 0, nil, "t"));
            local function update_body_yaw_visibility()
                local method4 = angles2.body_yaw:get();
                angles2.left_limit:visibility(method4 ~= "Disabled");
                angles2.right_limit:visibility(method4 ~= "Disabled");
                angles2.delay_1:visibility(method4 == "Jitter" or method4 == "Randomize Jitter");
                angles2.delay_2:visibility(method4 == "Randomize Jitter");
            end;
            angles2.body_yaw:set_callback(update_body_yaw_visibility, true);
            return angles2;
        end;
        local builtin_presets = {
            team = antiaim_tabs.angles:combo(section_label("Team", "\a{Link Active}"), enums.teams):set_callback(presets_db_key),
            state = antiaim_tabs.angles:combo(section_label("State", "\a{Link Active}"), enums.states):set_callback(presets_db_key)
        };
        for team_index2 = 1, #enums.teams do
            local team2 = enums.teams[team_index2];
            local states = {};
            for state_index2 = 1, #enums.states do
                local state2 = enums.states[state_index2];
                states[state2] = {};
                states[state2].angles = preset_list(team2, state2);
                states[state2].defensive = saved_presets(team2, state2);
            end;
            builtin_presets[team2] = states;
        end;
        local container = function(collect_state_values)
            local values = {};
            for control_key, index12 in pairs(collect_state_values) do
                local control2 = collect_state_values[control_key];
                if control2 ~= nil then
                    values[control_key] = {};
                    for key2, _2 in pairs(index12) do
                        local control_value = control2[key2];
                        if control_value ~= nil then
                            values[control_key][key2] = control_value:get();
                        end;
                    end;
                end;
            end;
            return values;
        end;
        local function apply_state_values(arg42, arg43)
            for source_key, index13 in pairs(arg42) do
                for source_value, _3 in pairs(index13) do
                    local target_control = arg42[source_key][source_value];
                    local source_value2 = arg43[source_key][source_value];
                    if target_control ~= nil and source_value2 ~= nil then
                        target_control:set(source_value2);
                    end;
                end;
            end;
        end;
        do
            local function export_state()
                local success
                local control_value2 = builtin_presets.team:get();
                local values2 = builtin_presets.state:get();
                local other_team = builtin_presets[control_value2][values2];
                if other_team == nil then
                    return;
                else
                    local value22 = container(other_team);
                    local value23, value24 = pcall(json.stringify, value22);
                    value22 = value24;
                    success = value23;
                    if not success then
                        return;
                    else
                        value23, value24 = pcall(base64.encode, value22);
                        value22 = value24;
                        success = value23;
                        if not success then
                            return;
                        else
                            clipboard.set(value22);
                            notify.success("State successfully exported!");
                            return;
                        end;
                    end;
                end;
            end;
            local function import_state()
                local data2, success
                local ok2, value25 = pcall(clipboard.get);
                data2 = value25;
                success = ok2;
                if not success then
                    print("failed 1");
                    return;
                else
                    ok2, value25 = pcall(base64.decode, data2);
                    data2 = value25;
                    success = ok2;
                    if not success then
                        print("failed 2");
                        return;
                    else
                        ok2, value25 = pcall(json.parse, data2);
                        data2 = value25;
                        success = ok2;
                        if not success then
                            print("failed 3");
                            return;
                        else
                            ok2 = builtin_presets.team:get();
                            value25 = builtin_presets.state:get();
                            local value26 = builtin_presets[ok2][value25];
                            if value26 == nil then
                                print("failed 4");
                                return;
                            else
                                apply_state_values(value26, data2);
                                notify.success("State successfully imported!");
                                return;
                            end;
                        end;
                    end;
                end;
            end;
            local function send_to_other_team()
                local team3 = builtin_presets.team:get();
                local state3 = builtin_presets.state:get();
                local state_values = builtin_presets[team3][state3];
                if state_values == nil then
                    return;
                else
                    local value27 = container(state_values);
                    local value28 = builtin_presets[team3 == "Counter-Terrorist" and "Terrorist" or "Counter-Terrorist"][state3];
                    if value28 == nil then
                        return;
                    else
                        apply_state_values(value28, value27);
                        notify.success("State successfully transfered to opposite team!");
                        return;
                    end;
                end;
            end;
            local state_actions = builtin_presets.state:create();
            state_actions:button(padded_label(concat(icon_label("arrow-up-from-bracket"), pad_spaces(7), "Copy"), 5), export_state, true);
            state_actions:button(padded_label(concat(icon_label("arrow-down-to-bracket"), pad_spaces(7), "Paste"), 5), import_state, true);
            state_actions:button(padded_label(concat(icon_label("send-backward"), pad_spaces(7), "Send to another team"), 3), send_to_other_team, true);
            home_icon.builder = builtin_presets;
        end;
        presets_db_key();
        ui_controls.antiaim = home_icon;
    end;
    local home_containers = {};
    local antiaim_tabs = icons.get("send-backward");
    local presets_tab = {
        category = ui.create(antiaim_tabs, "##category", 1),
        aimbot = ui.create(antiaim_tabs, "##aimbot", 2),
        interface = ui.create(antiaim_tabs, "##interface", 2),
        visuals = ui.create(antiaim_tabs, "##visuals", 1),
        misc = ui.create(antiaim_tabs, "##misc", 2),
        movement = ui.create(antiaim_tabs, "##movement", 2),
        shared = ui.create(antiaim_tabs, "##shared", 1)
    };
    home_containers.category = presets_tab.category:list("##category", {
        section_label("Rage"),
        section_label("Visuals"),
        section_label("Misc")
    });
    do
        local function apply_category(control)
            local index = control:get()
            presets_tab.aimbot:visibility(index == 1)
            presets_tab.interface:visibility(index == 2)
            presets_tab.visuals:visibility(index == 2)
            presets_tab.misc:visibility(index == 2)
            presets_tab.movement:visibility(index == 3)
            presets_tab.shared:visibility(index == 3)
        end
        local function update_category_labels(control)
            local selected = control:get()
            local items = control:list()
            local labels = {}
            for index, item in ipairs(items) do
                if selected == index then
                    labels[index] = item:gsub("\a{Small Text}", "\a{Link Active}")
                else
                    labels[index] = item:gsub("\a{Link Active}", "\a{Small Text}")
                end
            end
            control:update(labels)
        end
        home_containers.category:set_callback(function(control)
            apply_category(control)
            update_category_labels(control)
        end, true)
    end
    source_controls.extrap=preset_manager.push("Miscellaneous","source.extrapolation",presets_tab.aimbot:switch(concat(pad_spaces(2),icon_label("arrows-left-right"),pad_spaces(7),"Extrapolation"),false))
    source_controls.force=preset_manager.push("Miscellaneous","source.force_interpolation",presets_tab.aimbot:switch(concat(pad_spaces(2),icon_label("arrows-rotate"),pad_spaces(7),"Force Interpolation"),false))
    do
        local preset_list = {};
        if config.build ~= "Live" then
            local builtin_presets = {
                enabled = preset_manager.push("Rage", "dormant_aimbot.enabled", presets_tab.aimbot:switch(concat(pad_spaces(2), icon_label("person-rays"), pad_spaces(7), "Dormant Aimbot")))
            };
            local container = builtin_presets.enabled:create();
            builtin_presets.hitboxes = preset_manager.push("Rage", "dormant_aimbot.hitboxes", container:selectable("Hitboxes", {
                [1] = "Head",
                [2] = "Chest",
                [3] = "Stomach",
                [4] = "Legs"
            }));
            ensure_defaults(builtin_presets.hitboxes);
            builtin_presets.accuracy = preset_manager.push("Rage", "dormant_aimbot.accuracy", container:slider("Accuracy", 1, 100, 60, nil, "%"));
            builtin_presets.min_damage = preset_manager.push("Rage", "dormant_aimbot.min_damage", container:slider("Min. damage", 0, 130, 10, nil, function(arg44)
                if arg44 == 0 then
                    return "Auto";
                elseif arg44 > 100 then
                    return "+" .. arg44;
                else
                    return arg44;
                end;
            end));
            preset_list.dormant_aimbot = builtin_presets;
        end;
        if config.build == "Alpha" then
            local builtin_presets = {
                enabled = preset_manager.push("Rage", "ai_peek.enabled", presets_tab.aimbot:switch(concat(pad_spaces(2), icon_label("microchip-ai"), pad_spaces(7), "AI Peek")))
            };
            local container = builtin_presets.enabled:create();
            builtin_presets.hitboxes = preset_manager.push("Rage", "ai_peek.hitboxes", container:selectable("Hitboxes", {
                [1] = "Head",
                [2] = "Chest",
                [3] = "Stomach",
                [4] = "Arms",
                [5] = "Legs",
                [6] = "Feet"
            }));
            ensure_defaults(builtin_presets.hitboxes);
            builtin_presets.weapons = preset_manager.push("Rage", "ai_peek.weapons", container:selectable("Weapons", {
                [1] = "SSG 08",
                [2] = "R8 Revolver",
                [3] = "Desert Eagle",
                [4] = "Pistol",
                [5] = "Rifle",
                [6] = "Shotgun"
            }));
            ensure_defaults(builtin_presets.weapons);
            builtin_presets.dots = preset_manager.push("Rage", "ai_peek.dots", container:slider("Dots", 1, 10, 4));
            builtin_presets.radius = preset_manager.push("Rage", "ai_peek.radius", container:slider("Radius", 32, 64, 32));
            builtin_presets.color = preset_manager.push("Rage", "ai_peek.color", container:color_picker("Color"));
            preset_list.ai_peek = builtin_presets;
        end;
        do
            local container = {
                enabled = preset_manager.push("Rage", "maxusrcmdprocessticks.enabled", presets_tab.aimbot:switch(concat(pad_spaces(2), icon_label("code-compare"), pad_spaces(7), "Max User Process Ticks")))
            };
            local container4 = container.enabled:create();
            container.ticks = preset_manager.push("Rage", "maxusrcmdprocessticks.ticks", container4:slider("Value", 8, 32, 16, nil, function(arg45)
                if arg45 == 16 then
                    return "Default";
                else
                    return arg45 .. "t";
                end;
            end));

            do
                local function on_toggle(arg46)
                    container4:visibility(arg46:get());
                end;
                container.enabled:set_callback(on_toggle, true);
                preset_list.maxusrcmdprocessticks = container;
            end;
            do
                local lag_disablers = {
                    enabled = preset_manager.push("Rage", "lag_disablers.enabled", presets_tab.aimbot:switch(concat(pad_spaces(2), icon_label("wand-magic-sparkles"), pad_spaces(7), "Lag Disablers")))
                };
                local lag_group = lag_disablers.enabled:create();
                lag_disablers.states = preset_manager.push("Rage", "lag_disablers.states", lag_group:selectable("States", {
                    [1] = "Stand",
                    [2] = "DT Knife",
                    [3] = "DT Revolver",
                    [4] = "DT Discharge"
                }));
                lag_disablers.states:tooltip("Temporarily disables Fake Lag in the selected situations.");
                do
                    local function update_lag_disablers(control)
                        lag_group:visibility(control:get());
                    end;
                    lag_disablers.enabled:set_callback(update_lag_disablers, true);
                    update_lag_disablers(lag_disablers.enabled);
                end;
                preset_list.lag_disablers = lag_disablers;
            end;
            preset_list.fake_latency = {
                enabled = preset_manager.push("Rage", "fake_latency.enabled", presets_tab.aimbot:switch(concat(pad_spaces(2), icon_label("satellite-dish"), pad_spaces(7), "Unlock Fake Latency")))
            };
            home_containers.aimbot = preset_list;
        end;
        local builtin_presets = {};
        do
            builtin_presets.accent_color=source_controls.accent_color
            local panel_defs={
                {id="binds",label="Keybind List",icon="keyboard",x=20,y=380},
                {id="spectators",label="Spectators",icon="eye",x=20,y=600},
                {id="watermark",label="Watermark",icon="signature",x=850,y=30},
            }
            for _,def in ipairs(panel_defs) do
                local id=def.id
                local item=presets_tab.interface:switch(concat(pad_spaces(2),icon_label(def.icon),pad_spaces(7),def.label),false)
                local g=item:create()
                local panel={enabled=preset_manager.push("Visuals","panels."..id,item)}
                panel.x=preset_manager.push("Visuals","panels."..id..".x",g:slider("Horizontal",0,1000,def.x,0.1,"%"))
                panel.y=preset_manager.push("Visuals","panels."..id..".y",g:slider("Vertical",0,1000,def.y,0.1,"%"))
                if id=="watermark" then
                    panel.items=preset_manager.push("Visuals","panels.watermark.items",g:selectable("Details",{"User","Latency","FPS","Time"}))
                    panel.items:set({"User","Latency","FPS","Time"})
                    source_controls.hud_blur = { get = function() return true end }
                end
                panel.x:visibility(false);panel.y:visibility(false)
                source_controls[id]=panel
            end
        end
        local notifications = {
            enabled = preset_manager.push("Visuals", "log_events.enabled", presets_tab.interface:switch(concat(pad_spaces(2), icon_label("bell"), pad_spaces(7), "Notifications")))
        }
        builtin_presets.notifications = notifications
        source_controls.notifications = notifications
        local container = {
            enabled = preset_manager.push("Visuals", "crosshair_indicators.enabled", presets_tab.interface:switch(concat(pad_spaces(2), icon_label("crosshairs"), pad_spaces(7), "Crosshair Indicators")))
        };
        local container4 = container.enabled:create();
        container.items = preset_manager.push("Visuals", "crosshair_indicators.items", container4:selectable("Indicators", {"DT","HS","FS"}))
        do
            local selected=container.items:get()
            if type(selected)~="table" or #selected==0 then container.items:set({"DT","HS","FS"}) end
        end
        local container5 = nil;
        do
            local function on_toggle2(arg47)
                container4:visibility(arg47:get());
            end;
            container.enabled:set_callback(on_toggle2, true);
            builtin_presets.crosshair_indicators = container;
        end;
        local container5 = {
            enabled = preset_manager.push("Visuals", "damage_indicator.enabled", presets_tab.interface:switch(concat(pad_spaces(2), icon_label("hundred-points"), pad_spaces(7), "Damage Indicator")))
        };
        builtin_presets.damage_indicator = container5;
        local container6 = {
            enabled = preset_manager.push("Visuals", "velocity_warning.enabled", presets_tab.interface:switch(concat(pad_spaces(2), icon_label("chart-line"), pad_spaces(7), "Velocity Indicator")))
        };
        builtin_presets.velocity_warning = container6;
        local container8 = {
            enabled = preset_manager.push("Visuals", "hit_marker.enabled", presets_tab.visuals:switch(concat(pad_spaces(2), icon_label("xmark-large"), pad_spaces(7), "Hit Marker")))
        };
        builtin_presets.hit_marker = container8;
        local animation_modes = {
            enabled = preset_manager.push("Visuals", "scope_overlay.enabled", presets_tab.visuals:switch(concat(pad_spaces(2), icon_label("crosshairs-simple"), pad_spaces(7), "Scope Overlay")))
        };
        local container9 = animation_modes.enabled:create();
        animation_modes.additions = preset_manager.push("Visuals", "scope_overlay.additions", container9:selectable("Additions", {
            [1] = "Inverted",
            [2] = "Rotated",
            [3] = "Spread Dependency"
        }));
        animation_modes.exclude_lines = preset_manager.push("Visuals", "scope_overlay.exclude_lines", container9:selectable("Exclude Lines", {
            [1] = "Left",
            [2] = "Right",
            [3] = "Top",
            [4] = "Bottom"
        }));
        animation_modes.size = preset_manager.push("Visuals", "scope_overlay.size", container9:slider("Size", 0, 300, 50, nil, "px"));
        animation_modes.gap = preset_manager.push("Visuals", "scope_overlay.gap", container9:slider("Gap", 0, 300, 5, nil, "px"));
        animation_modes.color = preset_manager.push("Visuals", "scope_overlay.color", container9:color_picker("Color", color4(255, 255, 255, 255)));
        do
            local function on_toggle7(arg54)
                container9:visibility(arg54:get());
            end;
            animation_modes.enabled:set_callback(on_toggle7, true);
            builtin_presets.scope_overlay = animation_modes;
        end;
        local container9 = {
            enabled = preset_manager.push("Visuals", "nade_radius.enabled", presets_tab.visuals:switch(concat(pad_spaces(2), icon_label("fire"), pad_spaces(7), "Nade Radius")))
        };
        builtin_presets.nade_radius = container9;
        local container11 = {
            enabled = preset_manager.push("Visuals", "console_color.enabled", presets_tab.visuals:switch(concat(pad_spaces(2), icon_label("rectangle-terminal"), pad_spaces(7), "Console Color")))
        };
        container11.color = preset_manager.push("Visuals", "console_color.color", container11.enabled:color_picker(color4(128, 128, 128, 255)));

        do
            local function update_color_visibility(arg57)
                container11.color:visibility(arg57:get());
            end;
            container11.enabled:set_callback(update_color_visibility, true);
            builtin_presets.console_color = container11;
            local container12 = {
                enabled = preset_manager.push("Visuals", "aspect_ratio.enabled", presets_tab.misc:switch(concat(pad_spaces(2), icon_label("tv"), pad_spaces(7), "Aspect Ratio")))
            };
            local aspect_slider = container12.enabled:create();
            container12.proportion = preset_manager.push("Visuals", "aspect_ratio.proportion", aspect_slider:slider("", 0, 200, 0, 0.01));
            do
                local function aspect_visibility(control)
                    aspect_slider:visibility(control:get());
                end;
                container12.enabled:set_callback(aspect_visibility, true);
                builtin_presets.aspect_ratio = container12;
            end;
            local update_color_visibility = {
                enabled = preset_manager.push("Visuals", "viewmodel.enabled", presets_tab.misc:switch(concat(pad_spaces(2), icon_label("hand"), pad_spaces(7), "Viewmodel")))
            };
            local aspect_ratios = update_color_visibility.enabled:create();
            update_color_visibility.fov = preset_manager.push("Visuals", "viewmodel.fov", aspect_ratios:slider("Field of View", 0, 1000, 680, 0.1, "\194\176"));
            update_color_visibility.offset_x = preset_manager.push("Visuals", "viewmodel.offset_x", aspect_ratios:slider("Offset X", -100, 100, 25, 0.1, "\194\176"));
            update_color_visibility.offset_y = preset_manager.push("Visuals", "viewmodel.offset_y", aspect_ratios:slider("Offset Y", -100, 100, 0, 0.1, "\194\176"));
            update_color_visibility.offset_z = preset_manager.push("Visuals", "viewmodel.offset_z", aspect_ratios:slider("Offset Z", -100, 100, -15, 0.1, "\194\176"));
            aspect_ratios:button("Reset", function()
                update_color_visibility.fov:reset();
                update_color_visibility.offset_x:reset();
                update_color_visibility.offset_y:reset();
                update_color_visibility.offset_z:reset();
            end, true);

            do
                local aspect_lookup = function(on_toggle11)
                    aspect_ratios:visibility(on_toggle11:get());
                end;
                update_color_visibility.enabled:set_callback(aspect_lookup, true);
                builtin_presets.viewmodel = update_color_visibility;
            end;
            builtin_presets.keep_transparency = {
                enabled = preset_manager.push("Visuals", "keep_transparency.enabled", presets_tab.misc:switch(concat(pad_spaces(2), icon_label("transporter-2"), pad_spaces(7), "Keep Transparency")))
            };
            local world_modulate = {
                enabled = preset_manager.push("Visuals", "world_modulate.enabled", presets_tab.misc:switch(concat(pad_spaces(2), icon_label("moon-stars"), pad_spaces(7), "World Modulate")))
            };
            local world_group = world_modulate.enabled:create();
            local function percent_label(value)
                return value == 0 and "Off" or value .. "%";
            end;
            world_modulate.bloom = preset_manager.push("Visuals", "world_modulate.bloom", world_group:slider("Bloom", 0, 100, 0, 1, percent_label));
            world_modulate.exposure = preset_manager.push("Visuals", "world_modulate.exposure", world_group:slider("Exposure", 0, 100, 0, 1, percent_label));
            world_modulate.model_brightness = preset_manager.push("Visuals", "world_modulate.model_brightness", world_group:slider("Model brightness", 0, 200, 0, 1, percent_label));
            world_modulate.enabled:tooltip("Bloom, exposure and model brightness. Model transparency is handled by the existing Keep Transparency option.");
            do
                local function update_world_visibility(control)
                    world_group:visibility(control:get());
                end;
                world_modulate.enabled:set_callback(update_world_visibility, true);
                update_world_visibility(world_modulate.enabled);
            end;
            builtin_presets.world_modulate = world_modulate;
            builtin_presets.remove_footsteps_shadow = {
                enabled = preset_manager.push("Visuals", "remove_footsteps_shadow.enabled", presets_tab.misc:switch(concat(pad_spaces(2), icon_label("shoe-prints"), pad_spaces(7), "Remove Footsteps Shadow")))
            };
            home_containers.visuals = builtin_presets;
        end;
        local container = {
            avoid_collisions = {
                enabled = preset_manager.push("Miscellaneous", "avoid_collisions.enabled", presets_tab.movement:switch(concat(pad_spaces(3), icon_label("person-rays"), pad_spaces(7), "Avoid Collisions")))
            },
            collision_air_duck = {
                enabled = preset_manager.push("Miscellaneous", "collision_air_duck.enabled", presets_tab.movement:switch(concat(pad_spaces(2), icon_label("person-walking-dashed-line-arrow-right"), pad_spaces(7), "Collision Air Duck")))
            },
            fast_ladder = {
                enabled = preset_manager.push("Miscellaneous", "fast_ladder.enabled", presets_tab.movement:switch(concat(pad_spaces(2), icon_label("water-ladder"), pad_spaces(7), "Fast Ladder")))
            },
            super_toss = {
                enabled = preset_manager.push("Miscellaneous", "super_toss.enabled", presets_tab.movement:switch(concat(pad_spaces(2), icon_label("bomb"), pad_spaces(7), "Super Toss")))
            },
            edge_stop = {
                enabled = preset_manager.push("Miscellaneous", "edge_stop.enabled", presets_tab.movement:switch(concat(pad_spaces(2), icon_label("person-falling-burst"), pad_spaces(7), "Edge Stop")))
            },
            no_fall_damage = {
                enabled = preset_manager.push("Miscellaneous", "no_fall_damage.enabled", presets_tab.movement:switch(concat(pad_spaces(2), icon_label("person-arrow-up-from-line"), pad_spaces(7), "No Fall Damage")))
            },
            unlock_fd_speed = {
                enabled = preset_manager.push("Miscellaneous", "unlock_fd_speed.enabled", presets_tab.movement:switch(concat(pad_spaces(2), icon_label("duck"), pad_spaces(7), "Unlock FD Speed")))
            }
        };
        do
            local item=preset_manager.push("Miscellaneous","trashtalk.enabled",presets_tab.shared:switch(concat(pad_spaces(2),icon_label("trash-can"),pad_spaces(7),"Trash Talk")))
            local talk_gear=item:create()
            local talk={enabled=item}
            talk.style=preset_manager.push("Miscellaneous","trashtalk.style",talk_gear:combo("Language",{"English","Русский"}))
            talk.kill=preset_manager.push("Miscellaneous","trashtalk.kill",talk_gear:switch("Kill Phrases",true))
            talk.death=preset_manager.push("Miscellaneous","trashtalk.death",talk_gear:switch("Death Phrases",false))
            source_controls.talk=talk;container.trashtalk={enabled=item}
            item:set_callback(function()talk_gear:visibility(item:get())end,true)
        end
        do
            local item=preset_manager.push("Miscellaneous","clantag.enabled",presets_tab.shared:switch(concat(pad_spaces(2),icon_label("tags"),pad_spaces(7),"Clan Tag")))
            local tag_gear=item:create()
            local tag={enabled=item}
            tag.mode=preset_manager.push("Miscellaneous","clantag.mode",tag_gear:combo("Tag Preset",{"Social","Custom","Femboy","Buyme"}))
            tag.custom=preset_manager.push("Miscellaneous","clantag.custom",tag_gear:input("Custom Tag"))
            source_controls.tag=tag;container.clantag={enabled=item}
            local saved_mode=tag.mode:get()
            if saved_mode=="Femboy (phr 1)" then tag.mode:set("Femboy")
            elseif saved_mode=="Buyme (phr 2)" then tag.mode:set("Buyme")
            elseif saved_mode=="Vanta" then tag.mode:set("Social") end
            item:set_callback(function()tag_gear:visibility(item:get())end,true)
            tag.mode:set_callback(function()
                local mode=tag.mode:get()
                tag.custom:visibility(mode=="Custom")
            end,true)
        end
        home_containers.misc = container;
        ui_controls.other = home_containers;
    end;
end;

local player_state = {
    is_moving = false,
    is_onground = false,
    is_crouched = false
};
local function update_player_state(cmd)
    local player = entity.get_local_player()
    if not player then return end

    player_state.is_onground = bit.band(player.m_fFlags, 1) ~= 0
    player_state.is_moving = player.m_vecVelocity:length2dsqr() > 25
    player_state.is_crouched = player.m_flDuckAmount > 0.5 or cmd.in_duck == true
end;
events.createmove(update_player_state);

local state_context = {};
local state_stack = {};
local state_count = 0;
do
    local function push_state(state)
        state_count = state_count + 1
        state_stack[state_count] = state
    end
    local function clear_states()
        for i = 1, state_count do
            state_stack[i] = nil
        end
        state_count = 0;
    end;
    local function push_ground_states()
        if not player_state.is_onground then
            return;
        elseif player_state.is_moving then
            push_state("Running");
            if player_state.is_crouched then
                return;
            else
                if refs.antiaim.misc.slow_walk:get() then
                    push_state("Walking");
                end;
                return;
            end;
        else
            push_state("Standing");
            return;
        end;
    end;
    local function push_duck_states()
        if not player_state.is_crouched then
            return;
        else
            push_state("Crouching");
            if player_state.is_moving then
                push_state("Sneaking");
            end;
            return;
        end;
    end;
    local function push_air_states()
        if player_state.is_onground then
            return;
        else
            push_state("In Air");
            if player_state.is_crouched then
                push_state("Air Crouch");
            end;
            return;
        end;
    end;
    state_context.get = function()
        return state_stack[#state_stack];
    end;
    local function update_state_stack()
        clear_states();
        push_ground_states();
        push_duck_states();
        push_air_states();
    end;
    events.createmove(update_state_stack);
end;

local team_info = {
    get = function()
        local local_player = entity.get_local_player();
        if local_player == nil then
            return;
        else
            local team = local_player.m_iTeamNum
            if team == 2 then
                return "Terrorist";
            elseif team == 3 then
                return "Counter-Terrorist";
            else
                return;
            end;
        end;
    end
};

local aa_patch={owner=nil,packet_cmd=nil,hidden_cmd=nil,command=nil,draws={},hidden_owned=false}
local function aa_rand(tag,a,b)
    a,b=math.ceil(math.min(a,b)),math.floor(math.max(a,b))
    local key=tag..":"..tostring(a)..":"..tostring(b)
    if aa_patch.draws[key]==nil then aa_patch.draws[key]=utils.random_int(a,b) end
    return aa_patch.draws[key]
end
local function aa_hidden_pitch(value)
    aa_patch.hidden_owned=true
    rage.antiaim:override_hidden_pitch(math.clamp(value,-89,89))
end
local function aa_hidden_yaw(value)
    aa_patch.hidden_owned=true
    rage.antiaim:override_hidden_yaw_offset(math.normalize_yaw(value))
end
local function aa_release_hidden()
    if not aa_patch.hidden_owned then return end

    rage.antiaim:override_hidden_pitch(89)
    rage.antiaim:override_hidden_yaw_offset(0)
    aa_patch.hidden_owned=false
end
local function is_grenade_weapon(weapon)
    if not weapon then return false end
    local info=weapon:get_weapon_info()
    if info and info.weapon_type==9 then return true end
    local class=weapon:get_classname()
    return class=="CHEGrenade" or class=="CFlashbang" or class=="CSmokeGrenade"
        or class=="CMolotovGrenade" or class=="CIncendiaryGrenade" or class=="CDecoyGrenade"
end
local tick_count = 0;
local switch_state = false;
local flags = false;
local counter = 0;
local angles_state = {};
local angle_refs = refs.antiaim.angles;
local function unset_override(arg65)
    arg65:override(nil);
end;
local function set_override(arg66, ...)
    if ... == nil then
        return;
    else
        arg66:override(...);
        return;
    end;
end;
local state_meta = {};
state_meta.__index = state_meta;
state_meta.clear = function(clear_state)
    for key3 in pairs(clear_state) do
        clear_state[key3] = nil;
    end;
end;
state_meta.copy = function(copy_state, arg67)
    for key4, index21 in pairs(arg67) do
        copy_state[key4] = index21;
    end;
end;
do
    state_meta.unset = function(unset_angles)
        unset_override(angle_refs.extended_roll);
        unset_override(angle_refs.extended_pitch);
        unset_override(angle_refs.extended_angles);
        unset_override(angle_refs.body_freestanding);
        unset_override(angle_refs.disable_yaw_modifiers);
        unset_override(angle_refs.freestanding);
        unset_override(angle_refs.freestanding_body_yaw);
        unset_override(angle_refs.options);
        unset_override(angle_refs.right_limit);
        unset_override(angle_refs.left_limit);
        unset_override(angle_refs.inverter);
        unset_override(angle_refs.body_yaw);
        unset_override(angle_refs.modifier_offset);
        unset_override(angle_refs.yaw_modifier);
        unset_override(angle_refs.hidden);
        unset_override(angle_refs.avoid_backstab);
        unset_override(angle_refs.yaw_offset);
        unset_override(angle_refs.yaw_base);
        unset_override(angle_refs.yaw);
        unset_override(angle_refs.pitch);
        unset_override(angle_refs.enabled);
    end;
    state_meta.set = function(state5)
        if state5.yaw_offset ~= nil then
            state5.yaw_offset = math.normalize_yaw(state5.yaw_offset);
        end;
        if state5.modifier_offset ~= nil then
            state5.modifier_offset = math.normalize_yaw(state5.modifier_offset);
        end;
        if state5.left_limit ~= nil then
            state5.left_limit = math.clamp(state5.left_limit, 0, 60);
        end;
        if state5.right_limit ~= nil then
            state5.right_limit = math.clamp(state5.right_limit, 0, 60);
        end;
        if state5.extended_pitch ~= nil then
            state5.extended_pitch = math.normalize_yaw(state5.extended_pitch);
        end;
        if state5.extended_roll ~= nil then
            state5.extended_roll = math.clamp(state5.extended_roll, -90, 90);
        end;
        set_override(angle_refs.enabled, state5.enabled);
        set_override(angle_refs.pitch, state5.pitch);
        set_override(angle_refs.yaw, state5.yaw);
        set_override(angle_refs.yaw_base, state5.yaw_base);
        set_override(angle_refs.yaw_offset, state5.yaw_offset);
        set_override(angle_refs.avoid_backstab, state5.avoid_backstab);
        set_override(angle_refs.hidden, state5.hidden);
        set_override(angle_refs.yaw_modifier, state5.yaw_modifier);
        set_override(angle_refs.modifier_offset, state5.modifier_offset);
        set_override(angle_refs.body_yaw, state5.body_yaw);
        set_override(angle_refs.inverter, state5.inverter);
        set_override(angle_refs.left_limit, state5.left_limit);
        set_override(angle_refs.right_limit, state5.right_limit);
        set_override(angle_refs.options, state5.options);
        set_override(angle_refs.freestanding_body_yaw, state5.freestanding_body_yaw);
        set_override(angle_refs.freestanding, state5.freestanding);
        set_override(angle_refs.disable_yaw_modifiers, state5.disable_yaw_modifiers);
        set_override(angle_refs.body_freestanding, state5.body_freestanding);
        set_override(angle_refs.extended_angles, state5.extended_angles);
        set_override(angle_refs.extended_pitch, state5.extended_pitch);
        set_override(angle_refs.extended_roll, state5.extended_roll);
    end;
    setmetatable(angles_state, state_meta);
end;
local angle_refs = {};
local unset_override = false;
local set_override = false;
local state_meta = function(lerp, arg68, arg69)
    return lerp + arg69 * (arg68 - lerp);
end;
do
    do
        local function flip_switch()
            unset_override = not unset_override;
        end;
        local function resolve_pitch(_5, arg70)
            local method5 = arg70.pitch:get();
            local offset = arg70.pitch_offset:get();
            local from_value = arg70.pitch_1:get();
            local to_value = arg70.pitch_2:get();
            angles_state.pitch = "Down";
            if method5 == "Static" then
                return offset;
            elseif method5 == "Jitter" then
                return unset_override and from_value or to_value;
            elseif method5 == "Random" then
                return (aa_rand("pitch",from_value,to_value));
            elseif method5 == "Spin" then
                local value38 = globals.curtime * 1.5;
                return (state_meta(from_value, to_value, value38 % 1));
            elseif method5 == "Sway" then
                local value39 = globals.curtime * 5;
                return (state_meta(from_value, to_value, math.sin(value39) % 1));
            else
                return 0;
            end;
        end;
        local function resolve_yaw(_6, arg71)
            local apply_modifier2 = arg71.yaw:get();
            local offset2 = arg71.yaw_offset:get();
            local from_value2 = arg71.yaw_1:get();
            local to_value2 = arg71.yaw_2:get();
            local variation = arg71.randomization:get();
            local speed = arg71.yaw_speed:get();
            angles_state.yaw = "Backward";
            angles_state.yaw_base = "At Target";
            angles_state.yaw_offset = 0;
            angles_state.hidden = true;
            angles_state.yaw_add = false;
            angles_state.yaw_left = 0;
            angles_state.yaw_right = 0;
            angles_state.yaw_modifier = "Disabled";
            angles_state.modifier_offset = 0;
            angles_state.inverter = false;
            angles_state.left_limit = 60;
            angles_state.right_limit = 60;
            angles_state.options = {};
            angles_state.freestanding_body_yaw = "Off";
            if apply_modifier2 == "Static" then
                angles_state.body_yaw = "Left";
                return offset2;
            elseif apply_modifier2 == "Switch" then
                local profile=tostring(arg71)..":"..from_value2..":"..to_value2
                if aa_patch.switch_cmd~=_6.command_number or aa_patch.switch_profile~=profile then
                    aa_patch.switch_cmd=_6.command_number;aa_patch.switch_profile=profile;aa_patch.switch_phase=switch_state
                end
                local yaw=aa_patch.switch_phase and from_value2 or to_value2
                if variation>0 then yaw=yaw+math.ceil(aa_rand("hidden jitter",-variation,variation)/2) end
                return math.clamp(yaw,-180,180);
            elseif apply_modifier2 == "Random" then
                local value40 = aa_rand("yaw",from_value2,to_value2);
                angles_state.body_yaw = "Left";
                return value40;
            elseif apply_modifier2 == "Spin" then
                local value41 = globals.curtime * speed * 0.1;
                local value42 = offset2 * 0.5;
                local value43 = state_meta(-value42, value42, value41 % 1);
                angles_state.body_yaw = "Left";
                return value43;
            elseif apply_modifier2 == "Distortion" then
                angles_state.body_yaw = "Left";
                return math.sin(globals.curtime*speed)*math.min(180,offset2*.5);
            elseif apply_modifier2 == "Ember Spin" then
                angles_state.body_yaw = "Left";
                local amplitude=math.min(180,offset2*.5)
                if amplitude==0 then return 0 end
                return -(globals.curtime*speed*90 % (amplitude*2))+amplitude;
            elseif apply_modifier2 == "Sway" then
                local value44 = globals.curtime * speed * 0.1;
                local value45 = offset2 * 0.5;
                local value46 = state_meta(-value45, value45, math.sin(value44) % 1);
                angles_state.body_yaw = "Left";
                return value46;
            else
                return 0;
            end;
        end;
        local function resolve_choke(arg72)
            if arg72.random_choke:get() then
                return aa_rand("choke",arg72.choke_1:get(),arg72.choke_2:get());
            else
                return arg72.choke_1:get();
            end;
        end;
        local function apply_choke(cmd,setup)
            if not setup.force_defensive:get() then return end
            local period=setup.custom_choke:get() and math.max(1,resolve_choke(setup)) or 16
            if cmd.command_number % period==0 then cmd.force_defensive=true end
            if not setup.custom_choke:get() then
                refs.rage.main.double_tap_lag_options:override("Always On")
                refs.rage.main.hide_shots_options:override("Break LC")
            end
        end;
        angle_refs.update = function(self, arg75)
            if arg75.choked_commands == 0 and aa_patch.hidden_cmd~=arg75.command_number then
                aa_patch.hidden_cmd=arg75.command_number
                flip_switch();
            end;
        end;
        angle_refs.reset = function() unset_override=false;aa_patch.hidden_cmd=nil;aa_patch.switch_cmd=nil;aa_patch.switch_profile=nil end
        angle_refs.apply = function(self2, arg76, arg77)
            local is_double_tap = rage.exploit:get() == 1;
            local fake_duck = refs.antiaim.misc.fake_duck:get();
            if not is_double_tap or fake_duck then
                return false;
            elseif not arg77.enabled:get() then
                return false;
            else
                apply_choke(arg76,arg77)
                local value47 = resolve_pitch(arg76, arg77);
                local value48 = resolve_yaw(arg76, arg77);
                aa_hidden_pitch(value47);
                aa_hidden_yaw(math.clamp(value48,-180,180));
                return true;
            end;
        end;
    end;
    local unset_override = {};
    local set_override = ui_controls.antiaim.builder;
    local state_meta = function(reset_pitch)
        angles_state.pitch = "Down";
        angles_state.hidden = false;
    end;
    local function apply_yaw(arg78)
        angles_state.yaw = "Backward";
        angles_state.yaw_base = "At Target";
        angles_state.yaw_offset = arg78.yaw_offset:get();
        angles_state.yaw_add = arg78.yaw_add:get();
        angles_state.yaw_left = arg78.yaw_left:get();
        angles_state.yaw_right = arg78.yaw_right:get();
    end;
    local function apply_modifier(arg79)
        angles_state.yaw_modifier = arg79.yaw_modifier:get();
        angles_state.modifier_offset = arg79.modifier_offset:get();
    end;
    local function apply_body_yaw(arg80)
        angles_state.body_yaw = arg80.body_yaw:get();
        angles_state.inverter = false;
        angles_state.left_limit = arg80.left_limit:get();
        angles_state.right_limit = arg80.right_limit:get();
        angles_state.options = {};
        angles_state.freestanding_body_yaw = "Off";
        angles_state.delay_1 = arg80.delay_1:get();
        angles_state.delay_2 = arg80.delay_2:get();
    end;
    local function apply_freestanding(_8)
        angles_state.freestanding = false;
    end;
    local function apply_extended(_9)
        angles_state.extended_angles = false;
        angles_state.extended_pitch = 0;
        angles_state.extended_roll = 0;
    end;
    do
        unset_override.get = function(self3, arg81, arg82)
            return set_override[arg81][arg82];
        end;
        unset_override.is_active_ex = function(self4, arg83)
            if arg83.angles == nil then
                return false;
            else
                return true;
            end;
        end;
        unset_override.is_active = function(self5, arg84, arg85)
            local entry3 = self5:get(arg84, arg85);
            if entry3 == nil then
                return false;
            else
                return self5:is_active_ex(entry3);
            end;
        end;
        unset_override.apply_ex = function(self6, arg86)
            if arg86 == nil then
                return false;
            else
                local value49 = arg86.angles;
                if value49 == nil then
                    return false;
                else
                    state_meta(value49);
                    apply_yaw(value49);
                    apply_modifier(value49);
                    apply_body_yaw(value49);
                    apply_freestanding(value49);
                    apply_extended(value49);
                    return true;
                end;
            end;
        end;
        unset_override.apply = function(self7, arg87, arg88)
            local entry4 = self7:get(arg87, arg88);
            if entry4 == nil then
                return false, nil;
            elseif not self7:is_active_ex(entry4) then
                return false, entry4;
            else
                self7:apply_ex(entry4);
                return true, entry4;
            end;
        end;
        unset_override.update = function(self8)
            local state6 = state_context.get();
            local team4 = team_info.get();
            if state6 == nil or team4 == nil then
                return false, nil;
            else
                local _, value50 = self8:apply(team4, state6);
                return true, value50;
            end;
        end;
    end;
    local set_override = {};
    local state_meta = ui_controls.antiaim.tweaks.avoid_backstab;
    do
        set_override.update = function(self9)
            angles_state.avoid_backstab = state_meta.enabled:get();
        end;
    end;
    local state_meta = {};
    local apply_yaw = ui_controls.antiaim.tweaks.on_use;
    local apply_modifier = false;
    do
        local apply_body_yaw = function(can_use_objective)
            if not apply_yaw.enabled:get() then
                return false;
            else
                local value51 = entity.get_local_player();
                if value51 == nil then
                    return false;
                else
                    local value52 = value51:get_player_weapon();
                    if value52 == nil then
                        return false;
                    else
                        local value53 = value52:get_weapon_info();
                        if value53 == nil then
                            return false;
                        else
                            local value54 = value51.m_iTeamNum;
                            local value55 = value51:get_origin();
                            local value56 = value53.idx == 49;
                            local value57 = value51.m_bIsDefusing;
                            local value58 = value51.m_bIsGrabbingHostage;
                            local value59 = value51.m_bInBombZone;
                            if value57 or value58 then
                                return false;
                            elseif value59 and value56 then
                                return false;
                            else
                                if value54 == 3 and can_use_objective.view_angles.x > 25 then
                                    local value65 = entity.get_entities("CPlantedC4");
                                    for index22 = 1, #value65 do
                                        if (value65[index22]:get_origin() - value55):lengthsqr() < 3844 then
                                            return false;
                                        end;
                                    end;
                                end;
                                local value60 = render.camera_angles();
                                local value61 = vector():angles(value60);
                                local value62 = value51:get_eye_position();
                                local value63 = value62 + value61 * 128;
                                local value64 = utils.trace_line(value62, value63, value51);
                                if value64.fraction ~= 1 then
                                    local hit_entity=value64.entity
                                    if hit_entity==nil then return true end
                                    local value66 = hit_entity:get_classname();
                                    if value66 == "CWorld" then
                                        return true;
                                    elseif value66 == "CFuncBrush" then
                                        return true;
                                    elseif value66 == "CCSPlayer" then
                                        return true;
                                    elseif value66 == "CHostage" and value62:distsqr(hit_entity:get_origin()) < 7056 then
                                        return false;
                                    elseif not apply_modifier then
                                        apply_modifier = true;
                                        return false;
                                    end;
                                end;
                                return true;
                            end;
                        end;
                    end;
                end;
            end;
        end;
        state_meta.update = function(self10, arg89)
            if arg89.in_use == false then
                apply_modifier = false;
                return false;
            elseif not apply_body_yaw(arg89) then
                return false;
            else
                angles_state.pitch = "Disabled";
                angles_state.yaw_base = "Local View";
                angles_state.yaw_offset = angles_state.yaw_offset + 180;
                angles_state.freestanding = false;
                arg89.in_use = false;
                return true;
            end;
        end;
    end;
    local apply_yaw = {};
    local apply_modifier = ui_controls.antiaim.tweaks.modify_on_warmup;
    local apply_body_yaw = function()
        local game_rules = entity.get_game_rules();
        if game_rules == nil then
            return false;
        else
            return game_rules.m_bWarmupPeriod;
        end;
    end;
    do
        local apply_freestanding = function()
            if not apply_modifier.enabled:get() then
                return false;
            else
                return apply_body_yaw();
            end;
        end;
        apply_yaw.update = function(self11)
            if not apply_freestanding() then
                return false;
            else
                angles_state.enabled = true;
                angles_state.pitch = "Disabled";
                angles_state.yaw = "Backward";
                angles_state.yaw_base = "At Target";
                angles_state.yaw_offset = globals.tickcount * 8;
                angles_state.yaw_add = false;
                angles_state.yaw_left = 0;
                angles_state.yaw_right = 0;
                angles_state.yaw_modifier = "Disabled";
                angles_state.modifier_offset = 0;
                angles_state.body_yaw = "Disabled";
                angles_state.inverter = false;
                angles_state.left_limit = 0;
                angles_state.right_limit = 0;
                angles_state.options = {};
                angles_state.freestanding_body_yaw = "Off";
                angles_state.delay_1 = 0;
                angles_state.delay_2 = 0;
                angles_state.freestanding = false;
                return true;
            end;
        end;
    end;
    local apply_modifier = {};
    local apply_body_yaw = ui_controls.antiaim.tweaks.flick_exploit;
    do
        local apply_freestanding = function()
            if not apply_body_yaw.enabled:get() then
                return false;
            else
                local value67 = entity.get_local_player();
                if value67 == nil then
                    return false;
                else
                    local value68 = value67:get_player_weapon();
                    if value68 == nil then
                        return false;
                    else
                        local value69 = value68:get_weapon_info();
                        if value69 == nil or value69.is_revolver then
                            return false;
                        elseif not (rage.exploit:get() == 1) then
                            return false;
                        else
                            local value70 = state_context.get();
                            if value70 == nil then
                                return false;
                            else
                                return apply_body_yaw.conditions:get(value70);
                            end;
                        end;
                    end;
                end;
            end;
        end;
        apply_modifier.update = function(self12, arg90)
            if not apply_freestanding() then
                return false;
            else
                angles_state.enabled = true;
                angles_state.pitch = "Down";
                angles_state.yaw = "Backward";
                angles_state.yaw_base = "At Target";
                angles_state.yaw_offset = 5;
                angles_state.hidden = true;
                angles_state.yaw_add = false;
                angles_state.yaw_left = 0;
                angles_state.yaw_right = 0;
                angles_state.yaw_modifier = "Random";
                angles_state.modifier_offset = 5;
                angles_state.body_yaw = "Left";
                angles_state.inverter = false;
                angles_state.left_limit = 42;
                angles_state.right_limit = 42;
                angles_state.options = {};
                angles_state.freestanding_body_yaw = "Off";
                angles_state.delay_1 = 0;
                angles_state.delay_2 = 0;
                angles_state.freestanding = false;
                refs.rage.main.hide_shots_options:override("Break LC");
                refs.rage.main.double_tap_lag_options:override("Always On");
                aa_hidden_pitch(89);
                aa_hidden_yaw(-90);
                if arg90.command_number % 7 == 0 then arg90.force_defensive=true end;
                return true;
            end;
        end;
    end;
    local apply_body_yaw = {};
    local apply_freestanding = ui_controls.antiaim.tweaks.safe_head;
    local apply_extended = 1000000;
    do
        local function distance_to(arg91, arg92)
            local weapon = arg91:get_player_weapon();
            if weapon == nil then
                return nil;
            else
                local value71 = weapon:get_classname();
                local value72 = value71 == "CKnife";
                local value73 = value71 == "CWeaponTaser";
                local value74 = arg91:get_origin();
                local value75 = arg92:get_origin() - value74;
                local value76 = -value75.z;
                local value77 = value75:length2dsqr();
                if player_state.is_onground then
                    if (not player_state.is_moving or player_state.is_crouched) and value76 >= 10 and apply_extended < value77 then
                        return "Distance";
                    else
                        if player_state.is_crouched then
                            if value76 >= 48 then
                                return "Crouch";
                            end;
                        elseif not player_state.is_moving and value76 >= 24 then
                            return "Standing";
                        end;
                        return nil;
                    end;
                else
                    if player_state.is_crouched then
                        if value73 and value76 > -20 and value77 < 250000 then
                            return "Air Taser";
                        elseif value72 and value76 > -100 then
                            return "Air Knife";
                        elseif value76 > 130 then
                            return "Air Crouch";
                        end;
                    end;
                    return nil;
                end;
            end;
        end;
        local function update_safe_head()
            if not apply_freestanding.enabled:get() then return false end
            local player=entity.get_local_player()
            if not player or not player:is_alive() then return false end
            local weapon=player:get_player_weapon()
            if not weapon then return false end
            local class=weapon:get_classname()
            local knife=class=="CKnife" or class=="CKnifeGG"
            local taser=class=="CWeaponTaser"
            if (knife or taser) and player_state.is_crouched then
                local conditions=apply_freestanding.conditions
                if player_state.is_onground then
                    if conditions:get("Crouch") then return true end
                elseif conditions:get("Air Crouch")
                    or (knife and conditions:get("Air Knife"))
                    or (taser and conditions:get("Air Taser")) then
                    return true
                end
            end
            local threat=entity.get_threat()
            if not threat then return false end
            local condition=distance_to(player,threat)
            if condition and apply_freestanding.conditions:get(condition) then return true end
            if condition=="Air Taser" or condition=="Air Knife" then
                local delta=threat:get_origin()-player:get_origin()
                return -delta.z>130 and apply_freestanding.conditions:get("Air Crouch")
            end
            return false
        end;
        apply_body_yaw.update = function(self13)
            if not update_safe_head() then
                return false;
            else
                angles_state.enabled = true;
                angles_state.pitch = "Down";
                angles_state.yaw = "Backward";
                angles_state.yaw_base = "At Target";
                angles_state.yaw_offset = 0;
                angles_state.hidden = false;
                angles_state.yaw_add = false;
                angles_state.yaw_left = 0;
                angles_state.yaw_right = 0;
                angles_state.yaw_modifier = "Disabled";
                angles_state.modifier_offset = 0;
                angles_state.body_yaw = "Left";
                angles_state.inverter = false;
                angles_state.left_limit = 1;
                angles_state.right_limit = 1;
                angles_state.options = {};
                angles_state.freestanding_body_yaw = "Off";
                angles_state.delay_1 = 0;
                angles_state.delay_2 = 0;
                angles_state.freestanding = false;
                angles_state.body_freestanding = false;
                angles_state.disable_yaw_modifiers = true;
                angles_state.avoid_backstab = false;
                return true;
            end;
        end;
    end;
    local apply_freestanding = {};
    local apply_extended = ui_controls.antiaim.hotkeys.freestanding;
    do
        local function is_static()
            return apply_extended.static:get()
        end
        local function is_disabled()
            local state = state_context.get()
            return state ~= nil and apply_extended.disablers:get(state) or false
        end
        apply_freestanding.update = function(self16)
            if not apply_extended.enabled:get() then
                return false;
            elseif is_disabled() then
                return false;
            else
                angles_state.enabled = true;
                angles_state.yaw = "Backward";
                angles_state.yaw_base = "At Target";
                angles_state.yaw_offset = 0;
                angles_state.yaw_add = false;
                angles_state.yaw_modifier = "Disabled";
                angles_state.modifier_offset = 0;
                angles_state.disable_yaw_modifiers = true;
                angles_state.hidden = false;
                angles_state.freestanding = true;
                angles_state.body_freestanding = true;
                angles_state.body_yaw = angles_state.body_yaw ~= "Disabled";
                angles_state.inverter = nil;
                angles_state.options = {};
                local wall=aa_patch.wall and aa_patch.wall()
                if wall and is_static() then
                    local wall_offset=math.normalize_yaw(wall-render.camera_angles().y-180)

                    if math.abs(wall_offset) > 5 then
                        angles_state.yaw_base="Local View"
                        angles_state.yaw_offset=wall_offset
                        angles_state.freestanding=false
                        angles_state.body_freestanding=false
                        angles_state.freestanding_body_yaw="Off"
                    end
                end
                return true;
            end;
        end;
    end;
    local apply_extended = {};
    local manual_yaw = ui_controls.antiaim.hotkeys.manual_yaw;
    local offsets = {
        Backward = 0,
        Right = 90,
        Left = -90,
        Forward = 180
    };
    do
        local function update_freestanding()
            return manual_yaw.static:get();
        end;
        local function update_manual_yaw()
            local state8 = state_context.get();
            if state8 == nil then
                return false;
            else
                return manual_yaw.disablers:get(state8);
            end;
        end;
        apply_extended.update = function(self17)
            local offset3 = offsets[manual_yaw.direction:get()];
            if not offset3 then
                return false;
            elseif update_manual_yaw() then
                return false;
            else
                if update_freestanding() then
                    angles_state.yaw_offset = 0;
                    angles_state.yaw_add = false;
                    angles_state.yaw_modifier = "Disabled";
                    angles_state.body_yaw = "Left";
                end;
                angles_state.yaw_base = "Local View";
                angles_state.yaw_offset = angles_state.yaw_offset + offset3;
                return true;
            end;
        end;
    end;
    local manual_yaw = function(cmd)
        if aa_patch.packet_cmd==cmd.command_number then return end
        aa_patch.packet_cmd=cmd.command_number
        if rage.exploit:get() == 0 then
            switch_state = not switch_state;
            return;
        else
            if angles_state.body_yaw == "Jitter" then
                counter = angles_state.delay_1;
            end;
            if angles_state.body_yaw == "Randomize Jitter" and flags then
                counter = aa_rand("body delay",angles_state.delay_1,angles_state.delay_2);
                flags = false;
            end;
            tick_count = tick_count + 1;
            if counter < tick_count then
                switch_state = not switch_state;
                tick_count = 0;
                flags = true;
            end;
            return;
        end;
    end;
    local offsets = function(update)
        local active, value81 = unset_override:update();
        angle_refs:update(update);
        if apply_yaw:update() then
            return "warmup";
        elseif state_meta:update(update) then
            return "use";
        elseif set_override:update() then
            return "backstab";
        elseif apply_freestanding:update() then
            return "freestand";
        elseif apply_body_yaw:update() then
            return "safe_head";
        elseif apply_extended:update() then
            return "manual";
        elseif apply_modifier:update(update) then
            return "flick";
        else
            if active and value81 ~= nil and value81.defensive ~= nil then
                angle_refs:apply(update, value81.defensive);
            end;
            return "builder";
        end;
    end;
    local function update_flick()
        if not angles_state.yaw_add then
            return;
        else
            local value82 = switch_state and angles_state.yaw_left or angles_state.yaw_right;
            angles_state.yaw_offset = angles_state.yaw_offset + value82;
            return;
        end;
    end;
    local function update_body_yaw()
        if angles_state.body_yaw == "Disabled" then
            angles_state.body_yaw = false;
            return;
        elseif angles_state.body_yaw == "Left" then
            angles_state.body_yaw = true;
            angles_state.inverter=false;
            return;
        elseif angles_state.body_yaw == "Right" then
            angles_state.body_yaw = true;
            angles_state.inverter=true;
            return;
        elseif angles_state.body_yaw == "Jitter" or angles_state.body_yaw == "Randomize Jitter" then
            angles_state.body_yaw = true;
            angles_state.inverter=switch_state;
            return;
        else
            return;
        end;
    end;
    local function on_shutdown(arg93)
        if arg93.choked_commands == 0 then
            manual_yaw(arg93);
        end;
        update_body_yaw();
        update_flick();
    end;
    local function reset_overrides()
        aa_release_hidden()
        angles_state:clear()
        angles_state:unset()
        refs.rage.main.double_tap_lag_options:override()
        refs.rage.main.hide_shots_options:override()
        tick_count,counter,switch_state,flags=0,0,false,true
        angle_refs:reset()
        aa_patch.wall_cache=nil
        aa_patch.owner=nil;aa_patch.profile=nil;aa_patch.packet_cmd=nil;aa_patch.hidden_cmd=nil;aa_patch.command=nil
    end
    local local_key,last_tick=nil,nil
    local function on_createmove(cmd)
        local player=entity.get_local_player()
        if not player or not player:is_alive() then reset_overrides();local_key=nil;return end
        local key=tostring(player:get_index())..":"..tostring(player.m_flSpawnTime)
        if local_key~=key or (last_tick and globals.tickcount<last_tick) then reset_overrides() end
        local_key=key;last_tick=globals.tickcount
        local profile=tostring(team_info.get())..":"..tostring(state_context.get())
        if aa_patch.profile~=profile then angle_refs:reset();aa_patch.profile=profile end
        if aa_patch.command~=cmd.command_number then aa_patch.command=cmd.command_number;aa_patch.draws={} end
        angles_state:clear()
        angles_state:unset()
        refs.rage.main.double_tap_lag_options:override()
        refs.rage.main.hide_shots_options:override()
        local owner=offsets(cmd)
        local scope=tostring(team_info.get())..":"..tostring(state_context.get())..":"..tostring(owner)
            ..":"..tostring(angles_state.body_yaw)..":"..tostring(angles_state.delay_1)..":"..tostring(angles_state.delay_2)
        if aa_patch.owner~=scope then
            tick_count,counter,switch_state,flags=0,0,false,true
            aa_patch.packet_cmd=nil
            aa_patch.owner=scope
        end
        on_shutdown(cmd)
        if not angles_state.hidden then aa_release_hidden() end
        angles_state:set()
        if aa_patch.lc then aa_patch.lc(cmd,owner,state_context.get(),angles_state.hidden) end
    end
    events.level_init(function()reset_overrides();local_key=nil;last_tick=nil end)
    events.shutdown(reset_overrides);
    events.createmove(on_createmove);
end;

do
    local anim_breaker = ui_controls.antiaim.tweaks.anim_breaker;
    local leg_movement = refs.antiaim.misc.leg_movement;
    local overlay_type = ffi.typeof("struct { char pad_0x0000[0x18]; int sequence; float prev_cycle; float weight; float weight_delta_rate; float playback_rate; float cycle; void *entity; char pad_0x0038[0x4]; } **");
    local warned = false;
    local event_registered = false;

    local function set_pose(player, index, value)
        pcall(function()
            player.m_flPoseParameter[index] = value;
        end);
    end

    local function get_overlays(player)
        local ok, overlays = pcall(function()
            local base = ffi.cast("uintptr_t", player[0]);
            if base == 0 then return nil end
            return ffi.cast(overlay_type, base + 10640)[0];
        end);
        if not ok or overlays == nil or overlays == ffi.NULL then return nil end
        return overlays;
    end

    local function on_update(player)
        if not anim_breaker.enabled:get() then return end
        local local_player = entity.get_local_player();
        if not local_player or player ~= local_player then return end
        local anim_state = local_player:get_anim_state();
        if not anim_state then return end
        if leg_movement then leg_movement:override() end

        local in_air = not anim_state.on_ground;
        local ground_mode = anim_breaker.move:get();
        local overlays = nil;
        if ground_mode == "Slide" then
            if leg_movement then leg_movement:override("Sliding") end
            set_pose(local_player, 0, 0);
        elseif ground_mode == "Walking" then
            if leg_movement then leg_movement:override("Walking") end
            set_pose(local_player, 7, 0);
        elseif ground_mode == "Shake" then
            if leg_movement then leg_movement:override("Sliding") end
            set_pose(local_player, 0, globals.tickcount % 4 > 1 and 0.5 or 0);
        end

        if anim_breaker.air:get() == "Static" then
            set_pose(local_player, 6, 1);
        elseif anim_breaker.air:get() == "Walking" and in_air then
            overlays = get_overlays(local_player);
            if overlays then overlays[6].weight = 1 end
            set_pose(local_player, 7, 0);
        end

        if anim_breaker.other:get("Flashed") or anim_breaker.other:get("Move lean") then
            overlays = overlays or get_overlays(local_player);
        end
        if anim_breaker.other:get("Flashed") and overlays then
            overlays[0].sequence = 227;
        end
        if anim_breaker.other:get("Move lean") and overlays then
            overlays[12].weight = anim_breaker.lean_weight:get() * 0.01;
        end
        if anim_breaker.other:get("Landing pitch") and anim_state.landing and not in_air then
            set_pose(local_player, 12, 0.5);
        end
        if anim_breaker.other:get("Static creeping") then
            set_pose(local_player, 8, 0);
        end
    end

    local function set_event(enabled)
        if not enabled and not event_registered then return true end
        local ok, err = pcall(function()
            events.post_update_clientside_animation(on_update, enabled);
        end);
        if not ok and not warned then
            warned = true;
            print_raw("[social] Anim Breakers: post_update_clientside_animation unavailable: " .. tostring(err));
        end
        if ok then event_registered = enabled end
        return ok;
    end

    anim_breaker.enabled:set_callback(function(control)
        if leg_movement then leg_movement:override() end
        if control:get() then
            set_event(true);
        else
            set_event(false);
        end
    end, true);
    events.shutdown(function()
        set_event(false);
        if leg_movement then leg_movement:override() end
    end);
end;

do
    local lag_disablers = ui_controls.other.aimbot.lag_disablers;
    local fake_lag = refs.antiaim.fake_lag.enabled;
    local double_tap = refs.rage.main.double_tap;

    local function double_tap_active()
        if not double_tap then return false end
        if double_tap:get() then return true end
        local ok, override = pcall(function() return double_tap:get_override() end);
        return ok and override == true;
    end

    local function on_createmove()
        if fake_lag then fake_lag:override() end
        if not lag_disablers.enabled:get() then return end

        local player = entity.get_local_player();
        if not player or not player:is_alive() then return end
        local anim_state = player:get_anim_state();
        local weapon = player:get_player_weapon();
        if not anim_state or not weapon then return end

        local disable = false;
        if lag_disablers.states:get("Stand") then
            local velocity = anim_state.velocity;
            local speed = velocity and velocity:length() or 0;
            disable = speed < 2 and anim_state.on_ground and (anim_state.anim_duck_amount or 0) < 0.8;
        end
        if not disable and lag_disablers.states:get("DT Knife") then
            local classname = weapon:get_classname();
            disable = double_tap_active() and (classname == "CKnife" or classname == "CKnifeGG");
        end
        if not disable and lag_disablers.states:get("DT Revolver") then
            disable = double_tap_active() and weapon:get_name() == "R8 Revolver";
        end
        if not disable and lag_disablers.states:get("DT Discharge") then
            disable = rage.exploit:get() < 1 and double_tap_active();
        end
        if disable and fake_lag then
            fake_lag:override(false);
        end
    end

    lag_disablers.enabled:set_callback(function(control)
        if fake_lag then fake_lag:override() end
        events.createmove(on_createmove, control:get());
    end, true);
    events.shutdown(function()
        if fake_lag then fake_lag:override() end
    end);
end;

if config.build ~= "Live" then

    local flags = ui_controls.other.aimbot.dormant_aimbot;
    local counter = function(is_valid_weapon)
        return is_valid_weapon.weapon_type >= 1 and is_valid_weapon.weapon_type <= 6;
    end;
    local angles_state = function(player, arg95, arg96)
        if arg96.max_clip1 == 0 or arg95.m_iClip1 == 0 then
            return false;
        elseif globals.curtime < player.m_flNextAttack then
            return false;
        elseif globals.curtime < arg95.m_flNextPrimaryAttack then
            return false;
        else
            return true;
        end;
    end;
    local angle_refs = function(is_scoped, arg97)
        if arg97.weapon_type == 5 then
            return is_scoped.m_bIsScoped or is_scoped.m_bResumeZoom;
        else
            return true;
        end;
    end;
    local unset_override = function(self18, arg98, arg99, arg100)
        local params, value83 = utils.trace_bullet(self18, arg98, arg99, arg100);
        if value83 ~= nil then
            local value84 = value83.entity;
            if value84 == nil then
                return 0, value83;
            elseif value84:is_player() and not value84:is_enemy() then
                return 0, value83;
            end;
        end;
        return params, value83;
    end;
    do
        local set_override = function()
            local hitboxes = {};
            if flags.hitboxes:get("Head") then
                local value85 = {
                    position = vector(0, 0, 58),
                    hitbox = "Head"
                };
                table.insert(hitboxes, value85);
            end;
            if flags.hitboxes:get("Chest") then
                local value86 = {
                    position = vector(0, 0, 50),
                    hitbox = "Chest"
                };
                table.insert(hitboxes, value86);
            end;
            if flags.hitboxes:get("Stomach") then
                local value87 = {
                    position = vector(0, 0, 40),
                    hitbox = "Stomach"
                };
                table.insert(hitboxes, value87);
            end;
            if flags.hitboxes:get("Legs") then
                local value88 = {
                    position = vector(0, 0, 20),
                    hitbox = "Legs"
                };
                table.insert(hitboxes, value88);
            end;
            return hitboxes;
        end;
        local state_meta = function()
            local players = {};
            local player_resource = entity.get_player_resource();
            for index23 = 1, globals.max_players do
                local player2 = entity.get(index23);
                if player2 ~= nil and player_resource.m_bConnected[index23] and player2:is_enemy() and player2:is_dormant() and player2:is_alive() and player2:get_network_state() ~= 5 then
                    table.insert(players, player2);
                end;
            end;
            return players;
        end;
        local function on_createmove_hitbox(arg101)
            local local_player2 = entity.get_local_player();
            if local_player2 == nil then
                return;
            else
                local value89 = local_player2:get_player_weapon();
                if value89 == nil then
                    return;
                else
                    local value90 = value89:get_weapon_info();
                    if value90 == nil then
                        return;
                    else
                        local value91 = value89:get_inaccuracy();
                        if value91 == nil then
                            return;
                        elseif arg101.in_jump or not player_state.is_onground then
                            return;
                        else
                            local value92 = local_player2:get_eye_position();
                            if not counter(value90) then
                                return;
                            elseif not angles_state(local_player2, value89, value90) then
                                return;
                            else
                                local value93 = set_override();
                                if #value93 == 0 then
                                    return;
                                else
                                    local value94 = flags.accuracy:get();
                                    local value95 = flags.min_damage:get();
                                    local value96 = nil;
                                    local value97 = state_meta();
                                    if #value97 == 0 then
                                        return;
                                    else
                                        for weapon2 = 1, #value97 do
                                            local weapon3 = value97[weapon2];
                                            if weapon3 ~= nil then
                                                local value98 = weapon3:get_bbox();
                                                if value98 ~= nil then
                                                    local value99 = value98.alpha;
                                                    if value99 ~= 0 and math.floor(value99 * 100) + 5 > value94 then
                                                        local value100 = weapon3.m_vecOrigin;
                                                        local value101 = weapon3.m_flDuckAmount;
                                                        for index24 = 1, #value93 do
                                                            local player3 = value93[index24];
                                                            local position = player3.position;
                                                            local state9 = player3.hitbox;
                                                            position = position + value100;
                                                            if state9 == "Head" then
                                                                position = position - vector(0, 0, 10 * value101);
                                                            end;
                                                            if state9 == "Chest" then
                                                                position = position - vector(0, 0, 4 * value101);
                                                            end;
                                                            local fraction, value102 = unset_override(local_player2, value92, position, function(arg102)
                                                                return arg102 == target3;
                                                            end);
                                                            if state9 == "Head" then
                                                                fraction = fraction * 4;
                                                            end;
                                                            if (value102 == nil or not value102:is_visible()) and fraction ~= 0 and value95 <= fraction then
                                                                value96 = position;
                                                            end;
                                                        end;
                                                    end;
                                                end;
                                            end;
                                        end;
                                        if not value96 then
                                            return;
                                        else
                                            local value103 = value92:to(value96):angles();
                                            if not angle_refs(local_player2, value90) then
                                                arg101.in_attack2 = true;
                                            end;
                                            arg101.block_movement = 1;
                                            if value91 < 0.01 then
                                                arg101.view_angles = value103;
                                                arg101.in_attack = true;
                                            end;
                                            return;
                                        end;
                                    end;
                                end;
                            end;
                        end;
                    end;
                end;
            end;
        end;
        local function on_toggle13(arg103)
            local value104 = arg103:get();
            events.createmove(on_createmove_hitbox, value104);
        end;
        flags.enabled:set_callback(on_toggle13, true);
    end;
end;
if config.build == "Alpha" then

    local flags = ui_controls.other.aimbot.ai_peek;
    local counter = {
        point = nil,
        retreat = -1,
        retreat_point = nil
    };
    local angles_state = 1;
    local angle_refs = 40;
    local unset_override = 64;
    local set_override = 0;
    local state_meta = 1;
    local value105 = 2;
    local value106 = 3;
    local value107 = 4;
    local value108 = 5;
    local value109 = 6;
    local value110 = 7;
    local value111 = 0;
    local value112 = 3;
    local value113 = 5;
    local value114 = 7;
    local value115 = 8;
    local value116 = 9;
    local value117 = 10;
    local value118 = 11;
    local value119 = 12;
    local value120 = 15;
    local value121 = 17;
    local value122 = {
        [value111] = state_meta,
        [value113] = value105,
        [value112] = value106,
        [value115] = value109,
        [value114] = value110,
        [value119] = value109,
        [value118] = value110,
        [value121] = value107,
        [value120] = value108
    };
    do
        local function get_hitbox_config(arg104)
            return value122[arg104] or set_override;
        end;
        local function build_resolver()
            local hitboxes2 = {};
            if flags.hitboxes:get("Head") then
                table.insert(hitboxes2, value111);
            end;
            if flags.hitboxes:get("Chest") then
                table.insert(hitboxes2, value113);
            end;
            if flags.hitboxes:get("Stomach") then
                table.insert(hitboxes2, value112);
            end;
            if flags.hitboxes:get("Arms") then
                table.insert(hitboxes2, value121);
                table.insert(hitboxes2, value120);
            end;
            if flags.hitboxes:get("Legs") then
                table.insert(hitboxes2, value115);
                table.insert(hitboxes2, value114);
                table.insert(hitboxes2, value117);
                table.insert(hitboxes2, value116);
            end;
            return hitboxes2;
        end;
        local function multiply(arg105)
            if arg105 == state_meta then
                return 4;
            elseif arg105 == value106 then
                return 1.25;
            elseif arg105 == value109 then
                return 0.75;
            elseif arg105 == value110 then
                return 0.75;
            else
                return 1;
            end;
        end;
        local function scale_damage(arg106, arg107, arg108, arg109)
            arg107 = arg107 * multiply(arg108);
            local armor_value = arg106.m_ArmorValue;
            local has_helmet = arg106.m_bHasHelmet;
            if armor_value > 0 then
                if arg108 == state_meta then
                    if has_helmet ~= 0 then
                        arg107 = arg107 * (arg109 * 0.5);
                    end;
                else
                    arg107 = arg107 * (arg109 * 0.5);
                end;
            end;
            return arg107;
        end;
        local function estimate_damage(arg110, arg111, arg112, arg113, arg114)
            local delta = arg111 - arg110;
            local distance = arg114.damage;
            local armor_ratio = arg114.armor_ratio;
            local range = arg114.range;
            local range_modifier = arg114.range_modifier;
            local player4 = math.min(range, delta:length());
            distance = distance * math.pow(range_modifier, player4 * 0.002);
            return (scale_damage(arg112, distance, arg113, armor_ratio));
        end;
        local function find_lethal_hitbox(arg115, arg116, arg117, arg118, arg119)
            local hits = {};
            local eye_position = arg116:get_eye_position();
            local health = arg118.m_iHealth;
            for index25 = 1, #arg115 do
                local player5 = arg115[index25];
                local config2 = get_hitbox_config(player5);
                local hitbox_pos = arg118:get_hitbox_position(player5);
                local damage = estimate_damage(eye_position, hitbox_pos, arg118, config2, arg117);
                local lethal = damage < arg119;
                local lethal2 = damage < health;
                if not lethal or not lethal2 then
                    table.insert(hits, {
                        index = index25,
                        pos = hitbox_pos
                    });
                end;
            end;
            return hits;
        end;
        local function get_weapon_index(arg120, arg121)
            local index26 = arg120:get_weapon_index();
            local weapon_type = arg121.weapon_type;
            if weapon_type == 5 and index26 == angle_refs then
                return "SSG 08";
            elseif weapon_type == 1 then
                if index26 == unset_override then
                    return "R8 Revolver";
                elseif index26 == angles_state then
                    return "Desert Eagle";
                else
                    return "Pistol";
                end;
            elseif weapon_type == 3 then
                return "Rifle";
            elseif weapon_type == 4 then
                return "Shotgun";
            else
                return nil;
            end;
        end;
        local function is_pistol(arg122, arg123, arg124)
            if arg124.max_clip1 == 0 or arg123.m_iClip1 == 0 then
                return false;
            elseif globals.curtime < arg122.m_flNextAttack then
                return false;
            elseif globals.curtime < arg123.m_flNextPrimaryAttack then
                return false;
            else
                return true;
            end;
        end;
        local function is_scoped_player(arg125, arg126)
            if arg126.weapon_type_int == 5 then
                return arg125.m_bIsScoped == 1;
            else
                return true;
            end;
        end;
        local function update_conditions()
            refs.rage.main.double_tap:override();
        end;
        local function is_moving(arg127)
            return not arg127.in_forward and not arg127.in_back and not arg127.in_moveleft and not arg127.in_moveright;
        end;
        local function reset_moves(arg128)
            arg128.in_duck = false;
            arg128.in_jump = false;
            arg128.in_speed = false;
            arg128.in_forward = false;
            arg128.in_back = false;
            arg128.in_moveleft = false;
            arg128.in_moveright = false;
        end;
        local function trace(arg129, arg130, arg131, arg132)
            local fraction3, value123 = utils.trace_bullet(arg129, arg130, arg131, arg132);
            if value123 ~= nil then
                local value124 = value123.entity;
                if value124 == nil then
                    return 0, value123;
                elseif value124:is_player() and not value124:is_enemy() then
                    return 0, value123;
                end;
            end;
            return fraction3, value123;
        end;
        local function move_towards(arg133, arg134, arg135)
            local delta2 = arg135 - arg134.m_vecOrigin;
            if delta2:length2dsqr() < 25 then
                local value125 = arg134.m_vecVelocity;
                local value126 = value125:length();
                arg133.move_yaw = value125:angles().y;
                arg133.forwardmove = -value126;
                arg133.sidemove = 0;
                return true;
            else
                arg133.move_yaw = delta2:angles().y;
                arg133.forwardmove = 450;
                arg133.sidemove = 0;
                return false;
            end;
        end;
        local function forward_offset(arg136, arg137, arg138)
            return arg136 + vector():angles(0, arg137, 0) * arg138;
        end;
        local function trace_from_offset(arg139, arg140, arg141, arg142)
            local dest = forward_offset(arg140, arg141, arg142);
            return utils.trace_line(arg140, dest, arg139).end_pos;
        end;
        local function trace_points(arg143, arg144, arg145, arg146, arg147, arg148, arg149, arg150)
            local fraction4 = trace_from_offset(arg143, arg146, arg147, arg148);
            for position2 = 1, #arg149 do
                local fraction5 = arg149[position2].pos;
                local target, _ = trace(arg143, fraction4, fraction5, function(arg151)
                    return arg151 == arg144;
                end);
                if arg150 <= target then
                    return fraction4 - vector(0, 0, arg146.z - arg145.z), true;
                end;
            end;
            return nil, false;
        end;
        local function handle_createmove(arg152, arg153, _22, arg154)
            if not is_moving(arg152) then
                return;
            else
                local value127 = arg153.m_fFlags;
                if bit.band(value127, 1) == 0 then
                    return;
                else
                    local value128 = entity.get_threat();
                    if value128 == nil or not value128:is_alive() or value128:is_dormant() or value128:get_network_state() == 5 then
                        return;
                    else
                        local value129 = arg153.m_vecOrigin;
                        local value130 = value128.m_vecOrigin;
                        local value131 = arg153:get_eye_position();
                        local value132 = build_resolver();
                        local value133 = refs.rage.selection.min_damage:get();
                        local value134 = find_lethal_hitbox(value132, arg153, arg154, value128, value133);
                        local value135 = nil;
                        local value136 = nil;
                        local value137 = (value130 - value129):angles().y + 180;
                        value135 = value137 - 90;
                        value136 = value137 + 90;
                        local value138 = 0;
                        local value139 = 0;
                        value137 = flags.dots:get();
                        local value140 = flags.radius:get() / value137;
                        for index27 = 1, value137 do
                            local spread = value140 * index27;
                            if value138 ~= -1 then
                                value138 = index27;
                                local value141, value142 = trace_points(arg153, value128, value129, value131, value135, spread, value134, value133);
                                if value142 then
                                    counter.point = value141;
                                    break;
                                end;
                            end;
                            if value139 ~= -1 then
                                value139 = index27;
                                local value143, value144 = trace_points(arg153, value128, value129, value131, value136, spread, value134, value133);
                                if value144 then
                                    counter.point = value143;
                                    break;
                                end;
                            end;
                        end;
                        return;
                    end;
                end;
            end;
        end;
        local function update_visuals(arg155, arg156, arg157, arg158)
            if counter.retreat_point == nil then
                counter.retreat_point = arg156.m_vecOrigin;
            end;
            local value145 = is_pistol(arg156, arg157, arg158);
            local value146 = is_scoped_player(arg156, arg158);
            handle_createmove(arg155, arg156, arg157, arg158);
            local mins2 = arg156.m_vecMins;
            local maxs = arg156.m_vecMaxs;
            local color = flags.color:get();
            local edge_color = color4(0, 0, 0, 0);
            if counter.retreat <= 0 and value145 and value146 and counter.point then
                local value147 = move_towards(arg155, arg156, counter.point);
                reset_moves(arg155);
                counter.retreat = 0;
                if value147 then
                    counter.retreat = 1;
                end;
                debug_overlay.box_new(counter.point, mins2, maxs, vector(), edge_color, color, globals.tickinterval * 2);
                return;
            elseif counter.retreat == -1 then
                return;
            else
                local value148 = move_towards(arg155, arg156, counter.retreat_point);
                reset_moves(arg155);
                counter.retreat = counter.retreat + 1;
                if counter.retreat >= 3 then
                    refs.rage.main.double_tap:override(false);
                end;
                if value145 and value148 then
                    counter.point = nil;
                    counter.retreat = -1;
                    counter.retreat_point = nil;
                    update_conditions();
                end;
                return;
            end;
        end;
        local function get_weapon_setting(arg159, arg160)
            local weapon_index = get_weapon_index(arg159, arg160);
            if weapon_index == nil then
                return;
            else
                return flags.weapons:get(weapon_index);
            end;
        end;
        local function on_createmove2(arg161)
            update_conditions();
            local local_player3 = entity.get_local_player();
            if local_player3 == nil or not local_player3:is_alive() then
                return;
            else
                local value149 = local_player3:get_player_weapon();
                if value149 == nil then
                    return;
                else
                    local value150 = value149:get_weapon_info();
                    if value150 == nil then
                        return;
                    elseif not get_weapon_setting(value149, value150) then
                        return;
                    else
                        update_visuals(arg161, local_player3, value149, value150);
                        return;
                    end;
                end;
            end;
        end;
        local function on_aim_fire()
            counter.retreat = 1;
            update_conditions();
        end;
        local function on_shutdown2()
            update_conditions();
        end;
        local function on_toggle14(arg162)
            local value151 = arg162:get();
            if not value151 then
                counter.point = nil;
                counter.retreat = -1;
                counter.retreat_point = nil;
                update_conditions();
            end;
            events.shutdown(on_shutdown2, value151);
            events.aim_fire(on_aim_fire, value151);
            events.createmove(on_createmove2, value151);
        end;
        flags.enabled:set_callback(on_toggle14, true);
    end;
end;

local function notification_accent()
    local accent = source_controls.accent_color
    if accent then
        local ok, value = pcall(function() return accent:get() end)
        if ok and value then return value end
    end
    return color(192, 202, 255, 255)
end

local function notification_hit_color()
    return notification_accent()
end

local function notification_miss_color()
    return notification_accent()
end

do
    local flags = source_controls.notifications
    local notification_items = {}
    local notification_key = "social.notifications.position"
    local notification_position = db[notification_key]
    if type(notification_position) ~= "table"
        or type(notification_position.x) ~= "number"
        or type(notification_position.y) ~= "number" then
        notification_position = nil
    end

    local notification_bounds, notification_drag, notification_context = nil, nil, nil
    local left_before, right_before = false, false

    local function strip_markup(value, preserve_edges)
        value = tostring(value or ""):gsub("\r", " "):gsub("\n", " "):gsub("\t", " ")
        value = value:gsub("\a[%x][%x][%x][%x][%x][%x][%x][%x]", "")
        value = value:gsub("\a[%a]+", "")
        value = value:gsub("%s+", " ")

        if not preserve_edges then
            value = value:gsub("^%s+", ""):gsub("%s+$", "")
        end
        return value
    end

    local function normalize_segments(message)
        local result = {}
        if type(message) == "table" then
            for _, part in ipairs(message) do
                if type(part) == "table" then
                    local text = strip_markup(part.text or "", true)
                    if text ~= "" then
                        result[#result + 1] = {text = string.lower(text), accent = part.accent == true}
                    end
                elseif type(part) == "string" then
                    local text = strip_markup(part, true)
                    if text ~= "" then result[#result + 1] = {text = string.lower(text), accent = false} end
                end
            end
        else
            local text = strip_markup(message)
            if text ~= "" then result[1] = {text = string.lower(text), accent = false} end
        end
        return result
    end

    local function segments_plain(segments)
        local out = {}
        for _, segment in ipairs(segments) do out[#out + 1] = segment.text end
        return table.concat(out)
    end

    local function reset_notification_position(all)
        notification_position = nil
        db[notification_key] = nil
        if all and source_controls.reset_all_positions then
            source_controls.reset_all_positions()
        end
    end
    source_controls.reset_notification_position = function()
        notification_position = nil
        db[notification_key] = nil
    end

    local function set_override(event_color, message, label, value)
        if not flags or not flags.enabled or not flags.enabled:get() then return end
        local segments = normalize_segments(message)
        local plain = segments_plain(segments)
        if plain == "" then return end
        table.insert(notification_items, 1, {
            text = plain,
            segments = segments,
            color = event_color or notification_accent(),
            born = globals.realtime,
            duration = 5.0
        })
        while #notification_items > 5 do table.remove(notification_items) end
    end

    source_controls.push_notification = function(label, message)
        set_override(notification_accent(), message, label)
    end

    local function notification_wrap(segments, font, max_width)
        local lines, current, current_plain = {}, {}, ""
        local function push_line()
            if #current > 0 then
                lines[#lines + 1] = current
                current, current_plain = {}, ""
            end
        end
        local function add_piece(piece, accent)
            if piece == "" then return end
            local candidate = current_plain .. piece
            if current_plain ~= "" and render.measure_text(font, nil, candidate).x > max_width then
                push_line()
            end
            if render.measure_text(font, nil, piece).x <= max_width then
                current[#current + 1] = {text = piece, accent = accent}
                current_plain = current_plain .. piece
                return
            end

            local chunk = ""
            for char in piece:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
                if chunk ~= "" and render.measure_text(font, nil, chunk .. char).x > max_width then
                    current[#current + 1] = {text = chunk, accent = accent}
                    push_line()
                    chunk = char
                else
                    chunk = chunk .. char
                end
            end
            if chunk ~= "" then
                current[#current + 1] = {text = chunk, accent = accent}
                current_plain = current_plain .. chunk
            end
        end

        for _, segment in ipairs(segments) do

            for token in segment.text:gmatch("%s*%S+%s*") do
                add_piece(token, segment.accent)
            end
        end
        push_line()
        if #lines == 0 then lines[1] = {{text = "", accent = false}} end
        return lines
    end

    local function line_plain(line)
        local out = {}
        for _, segment in ipairs(line) do out[#out + 1] = segment.text end
        return table.concat(out)
    end

    local function notification_text_size(font)
        local ok, measured = pcall(render.measure_text, font, nil, "Ag")
        if ok and measured and measured.y and measured.y > 0 then return measured.y end
        return 13
    end

    local function build_notification_layout(item, font_body, max_card_width)
        local message = item.segments or {{text = string.lower(strip_markup(item.text or "")), accent = false}}
        local lines = notification_wrap(message, font_body, math.max(80, max_card_width - 36))
        local max_line_width = 0
        for _, line in ipairs(lines) do
            max_line_width = math.max(max_line_width, render.measure_text(font_body, nil, line_plain(line)).x)
        end
        local width = math.min(max_card_width, math.max(122, max_line_width + 36))
        local line_height = notification_text_size(font_body)
        local height = math.max(30, #lines * line_height + 14)
        return {item = item, width = width, height = height, lines = lines, line_height = line_height}
    end

    local function notification_render()
        local screen = render.screen_size()
        local now = globals.realtime
        local enabled = flags and flags.enabled and flags.enabled:get() or false
        for i = #notification_items, 1, -1 do
            local item = notification_items[i]
            if now - item.born >= (item.duration or 5.0) then table.remove(notification_items, i) end
        end

        if not enabled then
            notification_items = {}
            notification_context, notification_drag = nil, nil
            notification_bounds = nil
            return
        end

        local menu_open = ui.get_alpha() > 0.5
        local font_bank = source_controls.fonts or {}
        local font_body = font_bank.detail or font_bank.body or 1
        local entries, preview = {}, false
        if menu_open and #notification_items == 0 then
            preview = true
            entries = {
                {segments = {{text = "missed ", accent = true}, {text = "social", accent = false}, {text = " due to ", accent = false}, {text = "correction", accent = true}, {text = " (7t)", accent = true}}, color = notification_accent(), born = now, duration = 5},
                {segments = {{text = "hit ", accent = true}, {text = "social", accent = false}, {text = " for ", accent = false}, {text = "84 damage", accent = true}}, color = notification_accent(), born = now, duration = 5}
            }
        else
            for i = 1, math.min(5, #notification_items) do entries[#entries + 1] = notification_items[i] end
        end

        if #entries == 0 and not notification_context then
            notification_bounds = nil
            local left_now = common.is_button_down(1) == true
            local right_now = common.is_button_down(2) == true
            if not left_now then notification_drag = nil end
            if not menu_open then notification_context = nil end
            left_before, right_before = left_now, right_now
            return
        end

        local gap = 6
        local max_card_width = math.max(160, math.min(440, screen.x - 24))
        local layouts, card_w, total_h = {}, 0, 0
        for index, item in ipairs(entries) do
            local layout = build_notification_layout(item, font_body, max_card_width)
            layouts[index] = layout
            card_w = math.max(card_w, layout.width)
            total_h = total_h + layout.height
            if index < #entries then total_h = total_h + gap end
        end
        if #entries == 0 then total_h = 30 end

        local x = math.floor((screen.x - card_w) * 0.5)
        local y = math.floor(screen.y * 0.62 - total_h * 0.5)
        if notification_position then
            x = notification_position.x / 1000 * screen.x
            y = notification_position.y / 1000 * screen.y
        end
        x = math.clamp(x, 0, math.max(0, screen.x - card_w))
        y = math.clamp(y, 0, math.max(0, screen.y - math.max(total_h, 30)))
        notification_bounds = #entries > 0 and {x = x, y = y, w = card_w, h = total_h} or nil

        local mouse = ui.get_mouse_position()
        local left = common.is_button_down(1) == true
        local right = common.is_button_down(2) == true
        local menu_pos, menu_size = ui.get_position(), ui.get_size()
        local over_menu = mouse and menu_pos and menu_size
            and mouse.x >= menu_pos.x and mouse.x <= menu_pos.x + menu_size.x
            and mouse.y >= menu_pos.y and mouse.y <= menu_pos.y + menu_size.y

        if not menu_open then
            if notification_drag and notification_position then db[notification_key] = notification_position end
            notification_drag, notification_context = nil, nil
        elseif notification_context then
            if left and not left_before then
                if mouse and mouse.x >= notification_context.x and mouse.x <= notification_context.x + notification_context.w
                    and mouse.y >= notification_context.y and mouse.y <= notification_context.y + notification_context.h then
                    local row = math.floor((mouse.y - notification_context.y) / 25) + 1
                    if row == 1 then reset_notification_position(false)
                    elseif row == 2 then reset_notification_position(true) end
                end
                notification_context = nil
            elseif right and not right_before then
                notification_context = nil
            end
        elseif not over_menu then
            local over_cards = mouse and notification_bounds
                and mouse.x >= notification_bounds.x and mouse.x <= notification_bounds.x + notification_bounds.w
                and mouse.y >= notification_bounds.y and mouse.y <= notification_bounds.y + notification_bounds.h
            if right and not right_before and over_cards then
                notification_context = {
                    x = math.clamp(mouse.x, 0, math.max(0, screen.x - 174)),
                    y = math.clamp(mouse.y, 0, math.max(0, screen.y - 54)),
                    w = 174, h = 50
                }
            elseif left and not left_before and over_cards then
                notification_drag = {dx = mouse.x - x, dy = mouse.y - y}
            end
        end

        if notification_drag and left and mouse then
            x = math.clamp(mouse.x - notification_drag.dx, 0, math.max(0, screen.x - card_w))
            y = math.clamp(mouse.y - notification_drag.dy, 0, math.max(0, screen.y - math.max(total_h, 30)))
            notification_position = {x = x / screen.x * 1000, y = y / screen.y * 1000}
            db[notification_key] = notification_position
            notification_bounds = #entries > 0 and {x = x, y = y, w = card_w, h = total_h} or nil
        elseif notification_drag and not left then
            notification_drag = nil
            if notification_position then db[notification_key] = notification_position end
        end

        local accent = notification_accent()
        local current_top = y
        for _, layout in ipairs(layouts) do
            local item = layout.item
            local duration = item.duration or 5
            local age = preview and 0 or math.max(0, now - item.born)
            local fade_in = preview and 1 or math.min(1, age / 0.16)
            local fade_out = preview and 1 or math.min(1, math.max(0, (duration - age) / 0.5))
            local alpha = math.min(fade_in, fade_out)
            local transparent = source_controls.transparent and source_controls.transparent:get()
            local a = math.floor((transparent and 148 or 244) * alpha)
            local top, width, height = current_top, layout.width, layout.height
            local card_x = x + (card_w - width) * 0.5

            local card_color = transparent and color(13, 17, 23, a) or color(5, 6, 9, a)
            render.rect(vector(card_x, top), vector(card_x + width, top + height), card_color, 8)
            render.rect_outline(vector(card_x, top), vector(card_x + width, top + height), color(255, 255, 255, math.floor(17 * alpha)), 1, 8)

            local text_y = top + math.floor((height - #layout.lines * layout.line_height) * 0.5)
            for line_index, line in ipairs(layout.lines) do
                local cursor_x = card_x + 23
                local baseline = text_y + (line_index - 1) * layout.line_height
                if line_index == 1 then
                    render.circle(vector(card_x + 12, baseline + math.floor(layout.line_height * 0.5)), color(accent.r, accent.g, accent.b, math.floor(255 * alpha)), 2, 0, 1)
                end
                for _, segment in ipairs(line) do
                    local c = segment.accent and accent or color(226, 230, 238, 255)
                    render.text(font_body, vector(cursor_x, baseline), color(c.r, c.g, c.b, math.floor(255 * alpha)), nil, segment.text)
                    cursor_x = cursor_x + render.measure_text(font_body, nil, segment.text).x
                end
            end
            current_top = current_top + height + gap
        end

        if notification_context then
            local context_alpha = source_controls.transparent and source_controls.transparent:get() and 148 or 242
            local context_color = source_controls.transparent and source_controls.transparent:get()
                and color(13, 17, 23, context_alpha) or color(5, 6, 9, context_alpha)
            render.rect(vector(notification_context.x, notification_context.y), vector(notification_context.x + notification_context.w, notification_context.y + notification_context.h), context_color, 7)
            render.rect_outline(vector(notification_context.x, notification_context.y), vector(notification_context.x + notification_context.w, notification_context.y + notification_context.h), color(255, 255, 255, 20), 1, 7)
            local labels = {"reset position", "reset all positions"}
            for i, label in ipairs(labels) do
                local yy = notification_context.y + (i - 1) * 25
                if mouse and mouse.x >= notification_context.x and mouse.x <= notification_context.x + notification_context.w
                    and mouse.y >= yy and mouse.y <= yy + 25 then
                    render.rect(vector(notification_context.x + 3, yy + 2), vector(notification_context.x + notification_context.w - 3, yy + 23), color(255, 255, 255, 13), 4)
                end
                render.text(font_body, vector(notification_context.x + 10, yy + 5), color(232, 237, 246), nil, label)
            end
        end
        left_before, right_before = left, right
    end

    events.render(notification_render, true)
    events.level_init(function()
        notification_items = {}
        notification_context, notification_drag = nil, nil
    end)

    local hitgroup_names = {
        [0] = "generic",
        [1] = "head",
        [2] = "chest",
        [3] = "stomach",
        [4] = "left arm",
        [5] = "right arm",
        [6] = "left leg",
        [7] = "right leg",
        [8] = "neck",
        [9] = nil,
        [10] = "gear"
    };
    local weapon_names = {
        flashbang = "Harmed",
        knife = "Knifed",
        c4 = "Bombed",
        smokegrenade = "Harmed",
        incgrenade = "Harmed",
        hegrenade = "Naded",
        molotov = "Harmed",
        inferno = "Burned",
        decoy = "Decoyed"
    };
    local function format_message(arg164, arg165)
        arg165 = arg165:to_hex();
        return (arg164:gsub("%${(.-)}", function(arg166)
            return string.format("\a%s%s\aC8C8C8FF", arg165, arg166);
        end));
    end;
    local function print_dev_msg(message)
        return "\aA9BBFFFFsocial\a697489FF  |  \aC3CCDDFF" .. message
    end
    local function print_raw_msg(message)
        print_raw(print_dev_msg(message))
    end
    local function hitgroup_name(arg173)
        return hitgroup_names[arg173] or "?";
    end;
    local function update_hit(arg174)
        local target_name = arg174.target;
        if target_name == nil then
            return;
        else
            local action = target_name:is_alive() and "hit " or "killed ";
            local target = string.lower(tostring(target_name:get_name() or "enemy"));
            local hitgroup = string.lower(hitgroup_name(arg174.hitgroup));
            local damage = tonumber(arg174.damage) or 0;
            local desired_damage = tonumber(arg174.wanted_damage) or damage;
            local backtrack = tonumber(arg174.backtrack);
            local backtrack_suffix = backtrack ~= nil
                and string.format(" (%dt)", math.max(0, math.floor(backtrack))) or "";
            local value163 = notification_hit_color();
            local value165 = string.format("%s %s in %s for %d damage", action, target, hitgroup, damage);
            if desired_damage ~= damage then
                value165 = value165 .. string.format(" (%d)", desired_damage);
            end
            value165 = value165 .. backtrack_suffix;
            local console_message = format_message(value165, value163);
            local hit_segments = {
                {text = action, accent = true},
                {text = target, accent = false},
                {text = " in ", accent = false},
                {text = hitgroup, accent = true},
                {text = " for ", accent = false},
                {text = tostring(damage) .. " damage", accent = true}
            }
            if desired_damage ~= damage then
                hit_segments[#hit_segments + 1] = {text = string.format(" (%d)", desired_damage), accent = false}
            end
            if backtrack_suffix ~= "" then
                hit_segments[#hit_segments + 1] = {text = backtrack_suffix, accent = true}
            end
            set_override(value163, hit_segments);
            print_raw_msg(console_message);
            return;
        end;
    end;
    local function reset_overrides2(arg175)
        local shot = arg175.target;
        if shot == nil then
            return;
        else
            local target = string.lower(tostring(shot:get_name() or "enemy"));
            local reason = string.lower(tostring(arg175.state or "unknown"));
            local ticks = tonumber(arg175.backtrack);
            local suffix = ticks and string.format(" (%dt)", math.max(0, math.floor(ticks))) or "";
            local value173 = notification_miss_color();
            local value175 = string.format("missed %s due to %s%s", target, reason, suffix);
            set_override(value173, {
                {text = "missed ", accent = true},
                {text = target, accent = false},
                {text = " due to ", accent = false},
                {text = reason, accent = true},
                {text = suffix, accent = true}
            });
            print_raw_msg(value175);
            return;
        end;
    end;
    local function damage2(arg176)
        if arg176.state == nil then
            update_hit(arg176);
        else
            reset_overrides2(arg176);
        end;
    end;
    local function on_player_hurt(arg177)
        local local_player4 = entity.get_local_player();
        local attacker = entity.get(arg177.userid, true);
        if entity.get(arg177.attacker, true) ~= local_player4 or attacker == local_player4 then
            return;
        else
            local value178 = weapon_names[arg177.weapon];
            if value178 == nil then
                return;
            else
                local value179 = string.lower(tostring(attacker:get_name() or "enemy"));
                local value180 = tonumber(arg177.dmg_health) or 0;
                local value181 = notification_hit_color();
                local value182 = string.format("dealt %d damage to %s", value180, value179);
                set_override(value181, {
                    {text = "dealt ", accent = true},
                    {text = tostring(value180) .. " damage", accent = true},
                    {text = " to ", accent = false},
                    {text = value179, accent = false}
                });
                print_raw_msg(value182);
                return;
            end;
        end;
    end;

    events.player_hurt(on_player_hurt, true)
    events.aim_ack(damage2, true)
end;

do
    local counter = ui_controls.other.aimbot.maxusrcmdprocessticks;
    local process_ticks_cvar = cvar.sv_maxusrcmdprocessticks;
    local state = {
        original = nil,
        applied = nil,
        temporary = false,
        temporary_until = 0
    };
    local warned = nil;

    local function warn_once(message)
        if warned == message then return end
        warned = message;
        print_raw("[social] User Process Ticks: " .. message);
    end

    local function read_ticks()
        if process_ticks_cvar == nil then return nil end
        local ok, value = pcall(function() return process_ticks_cvar:int() end);
        if ok and finite_number(value) then return value end
        ok, value = pcall(function() return tonumber(process_ticks_cvar:string()) end);
        if ok and finite_number(value) then return value end
        return nil
    end

    local function write_ticks(value)
        if process_ticks_cvar == nil or not finite_number(value) then return false end
        local ok, err = pcall(function() process_ticks_cvar:int(value, true) end);
        if not ok then
            warn_once("cannot write sv_maxusrcmdprocessticks: " .. tostring(err));
            return false;
        end
        local after = read_ticks();
        if after ~= value then
            warn_once("sv_maxusrcmdprocessticks readback mismatch (" .. tostring(after) .. " != " .. tostring(value) .. ").");
            return false;
        end
        state.applied = value;
        return true;
    end

    local function ensure_original()
        if state.original ~= nil then return true end
        local value = read_ticks();
        if value == nil then
            warn_once("sv_maxusrcmdprocessticks is unavailable.");
            return false;
        end
        state.original = value;
        return true;
    end

    local function configured_value()
        if counter.enabled and counter.enabled:get() then
            local value = tonumber(counter.ticks:get());
            if finite_number(value) then
                return math.max(8, math.min(32, math.floor(value + 0.5)));
            end
        end
        return state.original;
    end

    local function sync()
        if process_ticks_cvar == nil then return false end
        local tick = tonumber(globals.tickcount);
        if state.temporary and finite_number(tick) and tick >= state.temporary_until then
            state.temporary = false;
        end

        if state.temporary then
            if read_ticks() == 19 then
                state.applied = 19;
                return true;
            end
            return write_ticks(19);
        end
        if counter.enabled and counter.enabled:get() then
            if not ensure_original() then return false end
        elseif state.original == nil then
            return true;
        end

        local target = configured_value();
        if target == nil then return true end
        if read_ticks() == target then
            state.applied = target;
            return true;
        end
        return write_ticks(target);
    end

    local function begin_override()
        if process_ticks_cvar == nil or not ensure_original() then return false end
        state.temporary = true;
        local tick = tonumber(globals.tickcount);
        state.temporary_until = (finite_number(tick) and tick or 0) + 3;
        if write_ticks(19) then return true end
        state.temporary = false;
        return false;
    end

    local function end_override(force)
        if not state.temporary then return true end
        local tick = tonumber(globals.tickcount);
        if not force and finite_number(tick) and tick < state.temporary_until then
            return false;
        end
        state.temporary = false;
        return sync();
    end

    local function reset()
        state.temporary = false;
        if state.original == nil then return true end
        local ok = write_ticks(state.original);
        if ok then
            state.original = nil;
            state.applied = nil;
        end
        return ok;
    end

    source_controls.process_ticks = {
        sync = sync,
        begin_override = begin_override,
        end_override = end_override,
        reset = reset
    };

    local function on_setting_change()
        sync();
    end
    counter.enabled:set_callback(on_setting_change, true);
    counter.ticks:set_callback(on_setting_change);
    events.shutdown(reset);
end;

local angles_state = ui_controls.other.aimbot.fake_latency;
local angle_refs = cvar.sv_maxunlag;
do
    local unset_override = function()
        angle_refs:float(tonumber(angle_refs:string()), true);
    end;
    local set_override = function()
        angle_refs:float(0.4, true);
    end;
    local state_meta = function()
        unset_override();
    end;
    local function on_toggle17(arg181)
        local distance3 = arg181:get();
        if distance3 then
            set_override();
        else
            unset_override();
        end;
        events.shutdown(state_meta, distance3);
    end;
    angles_state.enabled:set_callback(on_toggle17, true);
end;

local tick_flag = ui_controls.other.visuals.scope_overlay;
local ready_flag = 0;
do
    local state_flag = function()
        local value328 = entity.get_local_player();
        if value328 == nil or not value328:is_alive() then
            return;
        else
            local value329 = value328:get_player_weapon();
            if value329 == nil then
                return;
            else
                ready_flag = interpolation.interp(ready_flag, value328.m_bIsScoped, 0.05);
                if ready_flag <= 0 then
                    return;
                else
                    refs.visuals.world.main.scope_overlay:override("Remove All");
                    local value330 = render.screen_size() * 0.5;
                    local value331 = tick_flag.additions:get("Inverted");
                    local value332 = tick_flag.additions:get("Rotated");
                    local value333 = tick_flag.additions:get("Spread Dependency");
                    local value334 = tick_flag.size:get() * ready_flag;
                    local value335 = tick_flag.gap:get();
                    local value336 = tick_flag.color:get();
                    local value337 = value329:get_inaccuracy();
                    if value333 then
                        value335 = value335 + value337 * 100;
                    end;
                    local value338 = value336:clone();
                    local value339 = value336:clone();
                    value338.a = value331 and value338.a * ready_flag or 0;
                    value339.a = value331 and 0 or value339.a * ready_flag;
                    if value332 then
                        render.push_rotation(45);
                    end;
                    if not tick_flag.exclude_lines:get("Top") then
                        local value340 = vector(value330.x, value330.y - (value334 + value335));
                        local value341 = vector(value340.x + 1, value330.y - value335);
                        render.gradient(value340, value341, value338, value338, value339, value339);
                    end;
                    if not tick_flag.exclude_lines:get("Bottom") then
                        local value342 = vector(value330.x, value330.y + value334 + value335);
                        local value343 = vector(value342.x + 1, value330.y + value335);
                        render.gradient(value342, value343, value338, value338, value339, value339);
                    end;
                    if not tick_flag.exclude_lines:get("Left") then
                        local value344 = vector(value330.x - (value334 + value335), value330.y);
                        local value345 = vector(value330.x - value335, value330.y + 1);
                        render.gradient(value344, value345, value338, value339, value338, value339);
                    end;
                    if not tick_flag.exclude_lines:get("Right") then
                        local value346 = vector(value330.x + value334 + value335, value330.y);
                        local value347 = vector(value330.x + value335, value330.y + 1);
                        render.gradient(value346, value347, value338, value339, value338, value339);
                    end;
                    if value332 then
                        render.pop_rotation();
                    end;
                    return;
                end;
            end;
        end;
    end;

    local update_hit_indicator = function(arg227)
        local value348 = arg227:get();
        if not value348 then
            refs.visuals.world.main.scope_overlay:override();
        end;
        events.render(state_flag, value348);
    end;
    tick_flag.enabled:set_callback(update_hit_indicator, true);
end;

local ready_flag = ui_controls.other.visuals.aspect_ratio;
local state_flag = cvar.r_aspectratio;
do
    local target_flag = function()
        state_flag:float(tonumber(state_flag:string()), true);
    end;
    local update_hit_indicator = function()
        state_flag:float(ready_flag.proportion:get() * 0.01, true);
    end;
    local update_indicators = function()
        target_flag();
    end;

    local image_size = function(draw_os)
        local draw_freestanding = draw_os:get();
        if draw_freestanding then
            ready_flag.proportion:set_callback(update_hit_indicator);
            update_hit_indicator();
        else
            ready_flag.proportion:unset_callback(update_hit_indicator);
            target_flag();
        end;
        events.shutdown(update_indicators, draw_freestanding);
    end;
    ready_flag.enabled:set_callback(image_size, true);
end;

local viewmodel = ui_controls.other.visuals.viewmodel
local viewmodel_fov = cvar.viewmodel_fov
local viewmodel_x = cvar.viewmodel_offset_x
local viewmodel_y = cvar.viewmodel_offset_y
local viewmodel_z = cvar.viewmodel_offset_z

do
    local function restore_viewmodel()
        viewmodel_fov:float(tonumber(viewmodel_fov:string()), true)
        viewmodel_x:float(tonumber(viewmodel_x:string()), true)
        viewmodel_y:float(tonumber(viewmodel_y:string()), true)
        viewmodel_z:float(tonumber(viewmodel_z:string()), true)
    end

    local function apply_viewmodel()
        viewmodel_fov:float(viewmodel.fov:get() * 0.1, true)
        viewmodel_x:float(viewmodel.offset_x:get() * 0.1, true)
        viewmodel_y:float(viewmodel.offset_y:get() * 0.1, true)
        viewmodel_z:float(viewmodel.offset_z:get() * 0.1, true)
    end

    local function on_shutdown()
        restore_viewmodel()
    end

    local function update_viewmodel(control)
        local enabled = control:get()
        if enabled then
            viewmodel.fov:set_callback(apply_viewmodel)
            viewmodel.offset_x:set_callback(apply_viewmodel)
            viewmodel.offset_y:set_callback(apply_viewmodel)
            viewmodel.offset_z:set_callback(apply_viewmodel)
            apply_viewmodel()
        else
            viewmodel.fov:unset_callback(apply_viewmodel)
            viewmodel.offset_x:unset_callback(apply_viewmodel)
            viewmodel.offset_y:unset_callback(apply_viewmodel)
            viewmodel.offset_z:unset_callback(apply_viewmodel)
            restore_viewmodel()
        end
        events.shutdown(on_shutdown, enabled)
    end

    viewmodel.enabled:set_callback(update_viewmodel, true)
end

local nade_radius = ui_controls.other.visuals.nade_radius

do
    local function draw_nade_radius()
        if entity.get_local_player() == nil then return end
        local molotov_color = notification_accent():clone()
        local smoke_color = color(255, 255, 255, 255)
        entity.get_entities("CInferno", nil, function(projectile)
            local origin = projectile:get_origin()
            local bbox = projectile:get_bbox()
            local draw_color = molotov_color:clone()
            draw_color.a = draw_color.a * bbox.alpha
            render.circle_3d_outline(origin, draw_color, 125, 0, 1, 1.5)
        end)
        entity.get_entities("CSmokeGrenadeProjectile", nil, function(projectile)
            if projectile.m_bDidSmokeEffect then
                local origin = projectile:get_origin()
                local bbox = projectile:get_bbox()
                local draw_color = smoke_color:clone()
                draw_color.a = draw_color.a * bbox.alpha
                render.circle_3d_outline(origin, draw_color, 125, 0, 1, 1.5)
            end
        end)
    end

    nade_radius.enabled:set_callback(function(control)
        events.render(draw_nade_radius, control:get())
    end, true)
end

local console_color = ui_controls.other.visuals.console_color
local is_console_visible = utils.get_vfunc("engine.dll", "VEngineClient014", 11, "bool(__thiscall*)(void*)")
local console_materials = {
    materials.get_materials("vgui_white")[1],
    materials.get_materials("vgui/hud/800corner1")[1],
    materials.get_materials("vgui/hud/800corner2")[1],
    materials.get_materials("vgui/hud/800corner3")[1],
    materials.get_materials("vgui/hud/800corner4")[1]
}

do
    local function reset_materials()
        for i = 1, #console_materials do
            console_materials[i]:reset()
        end
    end

    local function set_materials(tint)
        local alpha = tint.a / 255
        for i = 1, #console_materials do
            local material = console_materials[i]
            material:alpha_modulate(alpha)
            material:color_modulate(tint)
        end
    end

    local function update_console_color()
        if not is_console_visible() then
            set_materials(color4(255, 255, 255, 255))
        else
            set_materials(console_color.color:get())
        end
    end

    local function on_shutdown()
        reset_materials()
    end

    local function update_console_color_enabled(control)
        local enabled = control:get()
        if not enabled then
            reset_materials()
        end
        events.shutdown(on_shutdown, enabled)
        events.pre_render(update_console_color, enabled)
    end

    console_color.enabled:set_callback(update_console_color_enabled, true)
end

local keep_transparency = ui_controls.other.visuals.keep_transparency
local transparency_alpha = nil

local function scoped_alpha(current_alpha)
    local player = entity.get_local_player()
    if not player then return end

    local target = (player.m_bIsScoped or player.m_bResumeZoom) and 59 or tonumber(current_alpha)
    if not finite_number(target) then return end
    if transparency_alpha == nil then
        transparency_alpha = target
    end

    local elapsed = get_frame_time()
    if elapsed > 0 then
        local step = 1 - math.exp(-elapsed / 0.07)
        transparency_alpha = transparency_alpha + (target - transparency_alpha) * step
        if math.abs(target - transparency_alpha) < 0.5 then
            transparency_alpha = target
        end
    end

    if finite_number(current_alpha) and math.abs(current_alpha - transparency_alpha) < 0.01 then
        return
    end
    return transparency_alpha
end

do
    local function update_transparency(control)
        if not control:get() then transparency_alpha = nil end
        events.localplayer_transparency(scoped_alpha, control:get())
    end

    keep_transparency.enabled:set_callback(update_transparency, true)
    events.shutdown(function() transparency_alpha = nil end)
end

do
    local world_modulate = ui_controls.other.visuals.world_modulate
    local model_ambient = cvar.r_modelAmbientMin
    local tone = nil
    local tone_retry = 0
    local brightness_original = nil
    local brightness_applied = false
    local last_bloom = nil
    local last_exposure = nil
    local last_brightness = nil

    local function capture_tone()
        tone_retry = tonumber(globals.realtime) or 0
        entity.get_entities("CEnvTonemapController", false, function(controller)
            if tone then return end
            tone = {
                entity = controller,
                use_bloom = controller.m_bUseCustomBloomScale,
                bloom = controller.m_flCustomBloomScale,
                use_exposure_min = controller.m_bUseCustomAutoExposureMin,
                use_exposure_max = controller.m_bUseCustomAutoExposureMax,
                exposure_min = controller.m_flCustomAutoExposureMin,
                exposure_max = controller.m_flCustomAutoExposureMax
            };
        end);
    end

    local function restore_tone()
        if tone then
            local controller = tone.entity;
            pcall(function()
                controller.m_bUseCustomBloomScale = tone.use_bloom;
                controller.m_flCustomBloomScale = tone.bloom;
                controller.m_bUseCustomAutoExposureMin = tone.use_exposure_min;
                controller.m_bUseCustomAutoExposureMax = tone.use_exposure_max;
                controller.m_flCustomAutoExposureMin = tone.exposure_min;
                controller.m_flCustomAutoExposureMax = tone.exposure_max;
            end);
        end
        tone = nil;
        last_bloom = nil;
        last_exposure = nil;
    end

    local function restore_brightness()
        if not brightness_applied or brightness_original == nil or model_ambient == nil then return end
        pcall(function()
            model_ambient:float(brightness_original, true);
        end);
        brightness_applied = false;
        last_brightness = nil;
    end

    local function paint()
        if not world_modulate.enabled:get() then return end
        local now = tonumber(globals.realtime) or 0;
        if not tone and now - tone_retry >= 0.5 then
            capture_tone();
        end

        local bloom = world_modulate.bloom:get() / 10;
        local exposure = world_modulate.exposure:get() / 100;
        if tone and last_bloom ~= bloom then
            pcall(function()
                local controller = tone.entity;
                if bloom > 0 then
                    controller.m_bUseCustomBloomScale = true;
                    controller.m_flCustomBloomScale = bloom;
                else
                    controller.m_bUseCustomBloomScale = tone.use_bloom;
                    controller.m_flCustomBloomScale = tone.bloom;
                end
            end);
            last_bloom = bloom;
        end
        if tone and last_exposure ~= exposure then
            pcall(function()
                local controller = tone.entity;
                if exposure > 0 then
                    controller.m_bUseCustomAutoExposureMin = true;
                    controller.m_bUseCustomAutoExposureMax = true;
                    controller.m_flCustomAutoExposureMin = exposure;
                    controller.m_flCustomAutoExposureMax = exposure;
                else
                    controller.m_bUseCustomAutoExposureMin = tone.use_exposure_min;
                    controller.m_bUseCustomAutoExposureMax = tone.use_exposure_max;
                    controller.m_flCustomAutoExposureMin = tone.exposure_min;
                    controller.m_flCustomAutoExposureMax = tone.exposure_max;
                end
            end);
            last_exposure = exposure;
        end

        local brightness = world_modulate.model_brightness:get() / 5;
        if model_ambient and last_brightness ~= brightness then
            if brightness > 0 then
                if brightness_original == nil then
                    local ok, value = pcall(function() return model_ambient:float() end);
                    if ok and finite_number(value) then brightness_original = value end
                end
                if brightness_original ~= nil then
                    pcall(function() model_ambient:float(brightness, true) end);
                    brightness_applied = true;
                end
            else
                restore_brightness();
            end
            last_brightness = brightness;
        end
    end

    local function on_shutdown()
        restore_tone();
        restore_brightness();
    end

    world_modulate.enabled:set_callback(function(control)
        if not control:get() then
            on_shutdown();
        end
        events.render(paint, control:get());
    end, true);
    events.level_init(function()
        tone = nil;
        last_bloom = nil;
        last_exposure = nil;
        last_brightness = nil;
    end);
    events.shutdown(on_shutdown);
end

local footstep_shadow = ui_controls.other.visuals.remove_footsteps_shadow
local footstep_shadow_cvar = cvar.cl_foot_contact_shadows

do
    local function disable_footstep_shadow()
        footstep_shadow_cvar:int(0, true)
    end

    local function restore_footstep_shadow()
        footstep_shadow_cvar:int(tonumber(footstep_shadow_cvar:string()), true)
    end

    local function on_shutdown()
        restore_footstep_shadow()
    end

    local function update_footstep_shadow(control)
        local enabled = control:get()
        if enabled then
            disable_footstep_shadow()
        else
            restore_footstep_shadow()
        end
        events.shutdown(on_shutdown, enabled)
    end

    footstep_shadow.enabled:set_callback(update_footstep_shadow, true)
end

local avoid_collisions = ui_controls.other.misc.avoid_collisions

local function avoid_collision(cmd)
    local player = entity.get_local_player()
    if not player then return end
    if bit.band(player.m_fFlags, 1) == 1 then return end
    if cmd.in_duck or cmd.in_speed then return end

    local camera = render.camera_angles()
    local origin = player.m_vecOrigin
    local velocity = player.m_vecVelocity
    velocity.z = 0

    local forward = vector():angles(0, camera.y)
    local right = forward:vectors()
    local move_dir = vector(
        forward.x * cmd.forwardmove + right.x * cmd.sidemove,
        forward.y * cmd.forwardmove + right.y * cmd.sidemove
    )
    move_dir:normalize()

    local end_pos = origin + move_dir * 8
    local trace = utils.trace_hull(
        origin, end_pos, player.m_vecMins, player.m_vecMaxs,
        entity.get_players(), 33636363, 0
    )
    if trace.entity == nil or not trace:did_hit_world() or bit.band(trace.contents, 536870912) ~= 0 then
        return
    end

    local move_velocity = velocity:normalized()
    if move_velocity:dot(move_dir) <= 0 then return end

    local normal = trace.plane.normal
    if math.abs(normal.z) >= 0.1 then return end
    if move_velocity:dot(normal) < -0.85 then
        move_velocity = move_dir
    end

    local slide_dir = normal:vectors()
    if slide_dir:dot(move_velocity) < 0 then
        slide_dir = slide_dir * -1
    end

    cmd.move_yaw = math.deg(math.atan2(slide_dir.y, slide_dir.x))
    cmd.forwardmove = 450
    cmd.sidemove = 0
end

do
    local function update_avoid_collisions(control)
        events.createmove(avoid_collision, control:get())
    end
    avoid_collisions.enabled:set_callback(update_avoid_collisions, true)
end

local collision_air_duck = ui_controls.other.misc.collision_air_duck

local function can_duck_for_collision(cmd, player)
    if player.m_MoveType == 9 or player.m_MoveType == 8 then return false end
    if cmd.in_duck then return false end
    if bit.band(player.m_fFlags, 1) ~= 0 then return false end
    return true
end

do
    local function update_collision_duck(cmd)
        local player = entity.get_local_player()
        if not player or not can_duck_for_collision(cmd, player) then return end

        local movement = player:simulate_movement()
        movement:think(1)
        cmd.in_duck = true
        local hit_first = bit.band(movement.flags, 1) == 0 and movement.did_hit_collision
        movement:think(1)
        cmd.in_duck = false
        local hit_second = bit.band(movement.flags, 1) == 0 and movement.did_hit_collision
        if not hit_first and hit_second then
            cmd.in_duck = true
        end
    end

    local function update_collision_air_duck(control)
        events.createmove(update_collision_duck, control:get())
    end
    collision_air_duck.enabled:set_callback(update_collision_air_duck, true)
end

local fast_ladder = ui_controls.other.misc.fast_ladder
local ladder_move_type = 9

local function fix_ladder_movement(cmd)
    local camera_pitch = render.camera_angles().x
    if cmd.forwardmove > 0 and camera_pitch < 45 then
        cmd.view_angles.x = 89
        cmd.in_moveright = 1
        cmd.in_moveleft = 0
        cmd.in_forward = 0
        cmd.in_back = 1
        if cmd.sidemove == 0 then
            cmd.view_angles.y = cmd.view_angles.y + 90
        end
        if cmd.sidemove < 0 then
            cmd.view_angles.y = cmd.view_angles.y + 150
        end
        if cmd.sidemove > 0 then
            cmd.view_angles.y = cmd.view_angles.y + 30
        end
    end

    if cmd.forwardmove < 0 then
        cmd.view_angles.x = 89
        cmd.in_moveleft = 1
        cmd.in_moveright = 0
        cmd.in_forward = 1
        cmd.in_back = 0
        if cmd.sidemove == 0 then
            cmd.view_angles.y = cmd.view_angles.y + 90
        end
        if cmd.sidemove > 0 then
            cmd.view_angles.y = cmd.view_angles.y + 150
        end
        if cmd.sidemove < 0 then
            cmd.view_angles.y = cmd.view_angles.y + 30
        end
    end
end

do
    local function update_fast_ladder(cmd)
        local player = entity.get_local_player()
        if not player or not player:is_alive() then return end
        if is_grenade_weapon(player:get_player_weapon()) then return end
        if player.m_MoveType ~= ladder_move_type then return end
        fix_ladder_movement(cmd)
    end

    local function register_fast_ladder(control)
        events.createmove(update_fast_ladder, control:get())
    end
    fast_ladder.enabled:set_callback(register_fast_ladder, true)
end

local edge_stop = ui_controls.other.misc.edge_stop

local function stop_at_edge(cmd)
    local player = entity.get_local_player()
    if not player then return end

    local movement = player:simulate_movement()
    movement:think(5)
    if movement.velocity.z < 0 then
        cmd.block_movement = 2
    end
end

do
    local function register_edge_stop(control)
        events.createmove(stop_at_edge, control:get())
    end
    edge_stop.enabled:set_callback(register_edge_stop, true)
end

local no_fall_damage = ui_controls.other.misc.no_fall_damage
local was_ducking = false
local full_circle = math.pi * 2
local circle_step = full_circle / 8

do
    local function has_ground_below(player, distance)
        local origin = player:get_origin()
        for angle = 0, full_circle, circle_step do
            local x = origin.x + math.cos(angle) * 10
            local y = origin.y + math.sin(angle) * 10
            local start_pos = vector(x, y, origin.z)
            local end_pos = start_pos:clone()
            end_pos.z = end_pos.z - distance
            if utils.trace_line(start_pos, end_pos, player).fraction ~= 1 then
                return true
            end
        end
        return false
    end

    local function update_no_fall_damage(cmd)
        local player = entity.get_local_player()
        if not player then return end
        if player.m_vecVelocity.z >= -500 then
            was_ducking = false
            return
        end

        if has_ground_below(player, 15) then
            was_ducking = false
        elseif has_ground_below(player, 75) then
            was_ducking = true
        end
        cmd.in_duck = was_ducking
    end

    local function register_no_fall_damage(control)
        events.createmove(update_no_fall_damage, control:get())
    end
    no_fall_damage.enabled:set_callback(register_no_fall_damage, true)
end

local unlock_fd_speed = ui_controls.other.misc.unlock_fd_speed
local min_move_speed = 5

do
    local function normalize_fake_duck_speed(cmd)
        if not refs.antiaim.misc.fake_duck:get() then return end
        if entity.get_local_player() == nil then return end

        local forward = cmd.forwardmove
        local side = cmd.sidemove
        if math.abs(forward) > min_move_speed or math.abs(side) > min_move_speed then
            local scale = 450 / (forward * forward + side * side) ^ 0.5
            cmd.forwardmove = forward * scale
            cmd.sidemove = side * scale
        end
    end

    local function register_fd_speed(control)
        events.createmove_run(normalize_fake_duck_speed, control:get())
    end
    unlock_fd_speed.enabled:set_callback(register_fd_speed, true)
end

do
local toss=ui_controls.other.misc.super_toss
local toss_cache=nil
local function toss_finite(x)return type(x)=="number" and x==x and math.abs(x)<math.huge end
local function toss_vector(v)return v and toss_finite(v.x) and toss_finite(v.y) and toss_finite(v.z) end
local function toss_same(a,b)
    return toss_vector(a) and toss_vector(b) and math.abs(a.x-b.x)<.00001 and math.abs(math.normalize_yaw(a.y-b.y))<.00001
end
local function toss_solve(angles,velocity,throw_velocity,strength)
    if not toss_vector(angles) or not toss_vector(velocity) or not toss_finite(throw_velocity) or not toss_finite(strength) then return nil end
    local input=vector(angles.x,math.normalize_yaw(angles.y),0)
    local pitch=input.x-10+math.abs(input.x)/9
    local desired=vector():angles(pitch,input.y)
    local speed=math.clamp(throw_velocity*.9,15,750)*(.3+.7*math.clamp(strength,0,1))
    local inherited=velocity*1.25
    local dot=desired.x*inherited.x+desired.y*inherited.y+desired.z*inherited.z
    local length_sq=inherited.x^2+inherited.y^2+inherited.z^2
    local discriminant=dot^2+speed^2-length_sq
    if discriminant<0 then return nil end
    local distance=dot+math.sqrt(discriminant)
    if distance<=.00001 then return nil end
    local launch=desired*distance-inherited
    local output=launch:angles()
    output.x=output.x>-10 and .9*output.x+9 or 1.125*output.x+11.25
    output.y=math.normalize_yaw(output.y)
    output.z=0
    if not toss_vector(output) or output.x < -89 or output.x > 89 then return nil end
    return output
end
local function toss_weapon()
    local player=entity.get_local_player()
    if not player or not player:is_alive() then return nil end
    local weapon=player:get_player_weapon()
    if not weapon then return nil end
    local info=weapon:get_weapon_info()
    if not info or info.weapon_type~=9 then return nil end
    return player,weapon,info
end
local function toss_preview(ctx)
    if not toss.enabled:get() then return end
    local player,weapon,info=toss_weapon()
    if not player then return end
    local output=toss_solve(ctx.angles,ctx.velocity,info.throw_velocity,weapon.m_flThrowStrength)
    if output then ctx.angles=output end
end
local function toss_command(cmd)
    if not toss.enabled:get() then toss_cache=nil;return end
    local player,weapon,info=toss_weapon()
    if not player then toss_cache=nil;return end
    local time=weapon.m_fThrowTime
    local offset=(tonumber(globals.clock_offset) or 0)*globals.tickinterval
    if not toss_finite(time) or time<=0 or time<globals.curtime-offset then toss_cache=nil;return end
    if not toss_vector(cmd.view_angles) then return end
    local key=tostring(player:get_index())..":"..tostring(player.m_flSpawnTime)..":"..tostring(weapon)..":"..tostring(weapon.m_flThrowStrength)..":"..tostring(time)
    if toss_cache and toss_cache.command==cmd.command_number and toss_cache.key==key
        and (toss_same(cmd.view_angles,toss_cache.input) or toss_same(cmd.view_angles,toss_cache.output)) then
        if toss_cache.output then cmd.view_angles=vector(toss_cache.output.x,toss_cache.output.y,0) end
        return
    end
    local camera=render.camera_angles()
    if not toss_same(cmd.view_angles,camera) then return end
    local movement=player:simulate_movement()
    movement:think()
    local input=vector(cmd.view_angles.x,cmd.view_angles.y,0)
    local output=toss_solve(input,movement.velocity,info.throw_velocity,weapon.m_flThrowStrength)
    toss_cache={command=cmd.command_number,key=key,input=input,output=output}
    if output then cmd.view_angles=vector(output.x,output.y,0) end
end
toss.enabled:set_callback(function()toss_cache=nil end)
events.createmove(toss_command)
events.grenade_override_view(toss_preview)
events.level_init(function()toss_cache=nil end)
events.shutdown(function()toss_cache=nil end)
end
do
    local last=-1
    local function blend(a, b, t)
        return math.floor(a + (b - a) * t + 0.5)
    end
    events.render(function()
        if globals.realtime>=last and globals.realtime-last<1/30 then return end
        last=globals.realtime
        local accent = notification_accent()
        local label="s o c i a l"
        local out={}
        local icon = icons.get("user") or icons.get("user-round") or ""
        local icon_wave=(math.sin(globals.realtime*3.4+0.15)+1)*0.5
        local icon_mix=0.10+icon_wave*0.78
        local icon_r=blend(accent.r,255,icon_mix)
        local icon_g=blend(accent.g,255,icon_mix)
        local icon_b=blend(accent.b,255,icon_mix)
        for i=1,#label do
            local wave=(math.sin(globals.realtime*3.4+(i-1)*0.48)+1)*0.5
            local lift=0.08+wave*0.82
            local r=blend(accent.r,255,lift)
            local g=blend(accent.g,255,lift)
            local b=blend(accent.b,255,lift)
            out[#out+1]=string.format("\a%02X%02X%02XFF%s",r,g,b,label:sub(i,i))
        end
        local icon_color=string.format("\a%02X%02X%02XFF",icon_r,icon_g,icon_b)
        ui.sidebar(table.concat(out),icon_color..icon)
    end)
end

do
    local extrap=source_controls.extrap
    local force=source_controls.force
    local state={armed=false,hook=nil,attached=false,attach_unknown=false,broken=false,extrap_interval=nil,extrap_applied_at=0,predict_guard=0}
    local messages={}
    local function warn(key,msg)
        if messages[key]~=msg then messages[key]=msg;print_raw("\aA9BBFFFFsocial\a697489FF / \aC3CCDDFF"..msg)end
    end
    local function finite(n)return type(n)=="number" and n==n and math.abs(n)<math.huge end
    local function live()
        if not globals.is_connected or not globals.is_in_game then return false end
        local p=entity.get_local_player()
        return p~=nil and p:is_alive()
    end
    local function cvar_slot(name,method)
        return {name=name,method=method,owned=false}
    end
    local function read(slot)
        local ok,v=pcall(function()
            local ref=cvar[slot.name]
            if not ref then error("missing cvar "..slot.name)end
            return ref[slot.method](ref)
        end)
        if not ok or not finite(v) then warn("read:"..slot.name,"Cvar read failed: "..slot.name.." / "..tostring(v));return nil end
        return v
    end
    local function close(a,b)return finite(a) and finite(b) and math.abs(a-b)<.00001 end
    local function put(slot,value,force_write)
        local ok,err=pcall(function()
            local ref=cvar[slot.name]
            ref[slot.method](ref,value,force_write)
        end)
        local after=read(slot)
        if not ok or not close(after,value)then
            warn("write:"..slot.name,"Cvar write/readback failed: "..slot.name.." / "..tostring(ok and after or err))
            return false,after
        end
        return true,after
    end
    local function restore(slot)
        if not slot.owned then return true end
        local current=read(slot)
        if current==nil then return false end
        if slot.last~=nil and not close(current,slot.last) then

            slot.owned=false;slot.original=nil;return true
        end
        local ok,after=put(slot,slot.original,slot.force)
        if not ok then
            if after~=nil then slot.last=after end
            return false
        end
        slot.owned=false;slot.original=nil;slot.last=nil;return true
    end
    local function own_write(slot,value,force_write)
        if not slot.owned then
            local original=read(slot)
            if original==nil then return false end
            if close(original,value)then return true end
            slot.original=original;slot.last=original;slot.owned=true
        end
        slot.force=force_write
        local ok,after=put(slot,value,force_write)

        if after~=nil then slot.last=after end
        return ok
    end
    local band={cvar_slot("cl_interpolate","int"),cvar_slot("cl_interp_ratio","int"),cvar_slot("cl_interp","float")}
    local prediction=cvar_slot("cl_predictweapons","int")
    local function stop_extrap()
        local ok=true
        for _,slot in ipairs(band)do if not restore(slot)then ok=false end end
        state.extrap_interval=nil
        state.extrap_applied_at=0
        return ok
    end
    local function tick_extrap()
        if not extrap:get() or not live()then stop_extrap();return end
        local interval=tonumber(globals.tickinterval)
        if not finite(interval) or interval<=0 then warn("tickinterval","Invalid tickinterval; extrapolation paused.");stop_extrap();return end
        interval=math.clamp(interval,1/128,1/32)

        local now=tonumber(globals.realtime) or 0
        if state.extrap_interval==interval and now-state.extrap_applied_at<1 then return end
        local targets={1,1,interval}
        for i,slot in ipairs(band)do
            if not own_write(slot,targets[i],false)then
                stop_extrap()
                return
            end
        end
        state.extrap_interval=interval
        state.extrap_applied_at=now
    end
    local function detach()
        if state.hook and (state.attached or state.attach_unknown)then
            local ok,err=pcall(state.hook.detach,state.hook)
            if not ok then
                state.attach_unknown=true
                warn("detach","CRITICAL: Force hook detach failed. Keep this Lua loaded, disable the feature and restart the game: "..tostring(err))

                return false
            end
        end
        state.attached=false;state.attach_unknown=false
        return true
    end
    local function stop_force()
        local detached=detach()
        local restored=restore(prediction)
        state.predict_guard=0
        if not restored then warn("restore-predict","cl_predictweapons restoration pending.")end
        return detached and restored
    end
    local function setup_hook()
        if state.hook then return not state.attach_unknown end

        local ok,result=pcall(function()
            local memory=require("neverlose/memory")
            if type(memory.hook_func)~="function"then error("neverlose/memory.hook_func unavailable")end
            local ptr=utils.opcode_scan("client.dll","57 8B F9 8B 07 8B 80 ? ? ? ? FF D0 84 C0 75 35")
            if ptr==nil or ptr==ffi.NULL or ptr==0 then error("Starsync signature not found")end
            local fn=ffi.cast("void(__fastcall*)(void*, void*)",ptr)
            local hook=memory.hook_func(fn,function(original,a,b)

                local checked,skip=pcall(function()
                    if not state.armed or not state.attached or not force:get() or not live()then return false end
                    local me=entity.get_local_player()
                    return a~=nil and b~=nil and me~=nil and entity.get(a)==me
                end)
                if not checked then warn("callback","Force entity lookup failed: "..tostring(skip))end
                if checked and skip then state.last_time=globals.realtime;return end
                return original:get_original(a,b)
            end)

            state.hook=hook;state.attach_unknown=true
            local detached,err=pcall(hook.detach,hook)
            if not detached then error("initial detach failed: "..tostring(err))end
            state.attach_unknown=false
            return hook
        end)
        if not ok then
            state.broken=true
            warn("setup","Force Interpolation setup failed: "..tostring(result))
            stop_force()

            return false
        end
        return true
    end
    local function tick_force()
        if not state.armed or not force:get() or not live() or state.broken then
            stop_force()
            return
        end
        if not setup_hook()then return end
        if not state.attached then
            local ok,err=pcall(state.hook.attach,state.hook)
            if not ok then
                state.attach_unknown=true;state.broken=true
                warn("attach","Force hook attach failed: "..tostring(err));stop_force();return
            end
            state.attached=true

        end
        local now=tonumber(globals.realtime)
        if not finite(now) or now-state.predict_guard<1 then return end
        state.predict_guard=now
        local current=read(prediction)
        if current==nil then return end
        if current~=0 and not own_write(prediction,0,true)then stop_force();state.broken=true end
    end
    local function guard(key,fn)
        local ok,err=pcall(fn)
        if not ok then warn(key,tostring(err))end
    end
    extrap:set_callback(function()guard("extrap-toggle",function()if not extrap:get()then stop_extrap()end end)end)
    force:set_callback(function()guard("force-toggle",function()
        if force:get() then
            state.armed=true;state.broken=false
            warn("risk","Force Interpolation: native Starsync hook enabled.")
            tick_force()
        else
            state.armed=false
            stop_force()
        end
    end)end)
    events.net_update_end(function()guard("extrap",tick_extrap);guard("force",function()if force:get() and not state.broken then state.armed=true end;tick_force()end)end)
    events.render(function()guard("lifecycle",function()if not live()then stop_extrap();stop_force()end end)end)
    events.level_init(function()guard("map",function()
        local a,b=stop_extrap(),stop_force()
        state.armed=force:get() and b;state.broken=not b
        if not a then warn("map-extrap","Extrapolation cvar restoration still pending after map change.")end
    end)end)
    events.shutdown(function()guard("shutdown",function()
        local a,b=stop_extrap(),stop_force()
        if not a or not b then warn("unload","CRITICAL: source-module cleanup incomplete. Restart the game before further testing.")end
    end)end)
end

do
    function aa_patch.wall()
        local player=entity.get_local_player()
        if not player or not player:is_alive() or entity.get_threat() then aa_patch.wall_cache=nil;return end
        if bit.band(player.m_fFlags,1)==0 then aa_patch.wall_cache=nil;return end
        local origin=player:get_eye_position()
        local tick=globals.tickcount
        local cache=aa_patch.wall_cache
        if cache and tick>=cache.tick and tick-cache.tick<4 and (origin-cache.origin):length()<8 then return cache.yaw end
        local best,best_yaw=64,nil
        local distances={}
        for i=0,23 do
            local yaw=i*15
            local tr=utils.trace_line(origin,origin+vector():angles(0,yaw)*80,player,nil,1)
            if tr and not tr.start_solid and not tr.all_solid and type(tr.fraction)=="number" and tr.fraction>0 and tr.fraction<.8 then
                local distance=tr.fraction*80
                distances[i]=distance
                if distance<best then best,best_yaw=distance,yaw end
            end
        end
        if cache and cache.yaw and best_yaw then
            local old=distances[math.floor(cache.yaw/15+.5)%24]
            if old and old<=best+5 then best_yaw=cache.yaw end
        end
        aa_patch.wall_cache={tick=tick,origin=origin:clone(),yaw=best_yaw}
        return best_yaw
    end
end

do
    local state = {
        last_cmd = nil,
        last_enemy = nil,
        last_trigger_time = 0,
        air_last_tick = nil
    }
    local warned = nil
    local process_ticks = source_controls.process_ticks

    local function reset()
        local restored = process_ticks.end_override(true)
        if not restored and warned ~= "ticks" then
            warned = "ticks"
            print_raw("[social] Auto LC: sv_maxusrcmdprocessticks could not be restored; keep the script loaded and retry.")
        end
        state.last_cmd = nil
        state.last_enemy = nil
        state.air_last_tick = nil
        state.last_trigger_time = 0
        source_controls.lc_status = "waiting"
        if refs.rage.main.double_tap_fake_lag_limit then
            refs.rage.main.double_tap_fake_lag_limit:override()
        end
    end

    local function get_hittable_enemy()
        local ok, enemy = pcall(entity.get_threat, true)
        if not ok or enemy == nil then return nil end
        local valid, result = pcall(function()
            return enemy:is_player()
                and enemy:is_enemy()
                and enemy:is_alive()
                and not enemy:is_dormant()
        end)
        if not valid or not result then return nil end
        return enemy
    end

    local function trigger(enemy)
        if not process_ticks.begin_override() then
            source_controls.lc_status = "tick cvar unavailable"
            return false
        end

        local ok, err = pcall(function()
            rage.exploit:force_teleport()
            rage.exploit:force_charge()
        end)
        if not ok then
            if warned ~= tostring(err) then
                warned = tostring(err)
                print_raw("[social] Auto LC: " .. tostring(err))
            end
            source_controls.lc_status = "error"
            return false
        end

        state.last_trigger_time = globals.realtime
        local ok_index, index = pcall(function() return enemy:get_index() end)
        state.last_enemy = ok_index and index or nil
        source_controls.lc_status = "active"
        return true
    end

    local function air_teleport_weapon_allowed(weapon)
        local selected = source_controls.lc_weapons;
        if not selected then return true end
        local ok_index, index = pcall(function() return weapon:get_weapon_index() end);
        local key = ok_index and ({[9] = "AWP", [31] = "Taser", [40] = "SSG 08"})[index] or nil;
        if key == nil then
            local ok_name, name = pcall(function() return weapon:get_name() end);
            if not ok_name then return false end
            if name == "AWP" then key = "AWP"
            elseif name == "SSG 08" then key = "SSG 08"
            elseif name == "Taser" or name == "Zeus x27" then key = "Taser"
            else return false end
        end
        local ok_selected, value = pcall(function() return selected:get(key) end);
        return ok_selected and value == true;
    end

    local function command_is_firing(cmd, player)
        local firing = cmd and (
            cmd.in_attack == true or cmd.in_attack == 1 or
            cmd.in_attack2 == true or cmd.in_attack2 == 1
        ) or false
        if firing then return true end
        local last_shot
        pcall(function()
            local weapon = player:get_player_weapon()
            last_shot = weapon and tonumber(weapon.m_fLastShotTime or weapon:get_prop("m_fLastShotTime"))
        end)
        if finite_number(last_shot) then
            local age = (tonumber(globals.curtime) or 0) - last_shot
            return age >= 0 and age < 0.12
        end
        return false
    end

    local function run_air_teleport(cmd, player, anim_state, weapon, mode)
        if mode == "On enemy" then
            if not refs.rage.main.double_tap:get() then
                source_controls.lc_status = "DT disabled"
                return
            end
            if command_is_firing(cmd, player) then
                source_controls.lc_status = "shot protected"
                return
            end
            if rage.exploit:get() ~= 1 then
                source_controls.lc_status = "waiting DT charge"
                return
            end
            if not air_teleport_weapon_allowed(weapon) then
                source_controls.lc_status = "weapon filtered"
                return
            end
            if cmd and cmd.in_jump and not source_controls.lc_on_cross:get() then return end

            local eye = player:get_eye_position()
            local velocity = player.m_vecVelocity
            if not eye or not velocity then return end
            local interval = tonumber(globals.tickinterval)
            if not finite_number(interval) or interval <= 0 then return end
            local current_tick = tonumber(globals.tickcount)
            if not finite_number(current_tick) or state.air_last_tick == current_tick then return end
            state.air_last_tick = current_tick

            -- Use the current threat rather than tracing every enemy. The old all-player,
            -- 7-horizon x 4-hitbox scan was expensive enough to tank FPS with DT enabled.
            local enemy = get_hittable_enemy()
            if not enemy then
                source_controls.lc_status = "no threat"
                return
            end
            local enemy_velocity = enemy.m_vecVelocity
            if not enemy_velocity then return end

            local points = {}
            for _, hitbox_id in ipairs({0, 2, 5}) do
                local point = enemy:get_hitbox_position(hitbox_id)
                if point then points[#points + 1] = point end
            end
            if #points == 0 then return end

            local found, best_horizon = false, nil
            -- Three horizons and three representative hitboxes: at most 9 bullet traces
            -- instead of up to 28 per enemy per command. Stop at the first valid window.
            for _, horizon in ipairs({0, 2, 4}) do
                local dt = interval * horizon
                local predicted_eye = eye:clone()
                predicted_eye.x = predicted_eye.x + velocity.x * dt
                predicted_eye.y = predicted_eye.y + velocity.y * dt
                predicted_eye.z = predicted_eye.z + velocity.z * dt
                for _, base_point in ipairs(points) do
                    local predicted_point = base_point:clone()
                    predicted_point.x = predicted_point.x + enemy_velocity.x * dt
                    predicted_point.y = predicted_point.y + enemy_velocity.y * dt
                    predicted_point.z = predicted_point.z + enemy_velocity.z * dt
                    local ok, damage, trace = pcall(utils.trace_bullet, player, predicted_eye, predicted_point)
                    if ok and tonumber(damage) and damage > 10 and trace and trace.entity == enemy then
                        found, best_horizon = true, horizon
                        break
                    end
                end
                if found then break end
            end

            if not found then
                source_controls.lc_status = "no predicted window"
                return
            end

            local now = tonumber(globals.realtime) or 0
            local cooldown = (now - (tonumber(state.last_trigger_time) or 0)) >= 0.075
            if cooldown then
                local ok = trigger(enemy)
                if not ok then
                    -- A failed cvar override must not silently suppress the native teleport.
                    pcall(function() rage.exploit:force_teleport() end)
                end
            else
                source_controls.lc_status = "re-arming"
            end
            if best_horizon == 0 then
                source_controls.lc_status = cooldown and "air teleport" or "re-arming"
            else
                source_controls.lc_status = cooldown and ("peek t+" .. tostring(best_horizon)) or "re-arming"
            end
            return
        end

        if mode == "Exploit" then
            local lag_limit = refs.rage.main.double_tap_fake_lag_limit
            if lag_limit then lag_limit:override() end
            local ok_info, info = pcall(function() return weapon:get_weapon_info() end)
            if not ok_info or not info or info.weapon_type == 9 then return end

            local tick = tonumber(globals.tickcount)
            if not finite_number(tick) or not cmd then return end
            local ticks = math.max(10, math.min(30, math.floor(tonumber(source_controls.lc_exploit_ticks:get()) or 10)))
            if rage.exploit:get() ~= 1 or tick % ticks ~= 0 then
                rage.exploit:force_charge()
            else
                cmd.force_defensive = true
                if lag_limit then lag_limit:override(math.random(7)) end
                rage.exploit:force_teleport()
                state.air_last_tick = globals.tickcount
                source_controls.lc_status = "air exploit"
            end
        end
    end

    function aa_patch.lc(cmd, owner, actual_state, hidden)
        process_ticks.end_override(false)

        if not source_controls.lc_enabled or not source_controls.lc_enabled:get() then
            source_controls.lc_status = "off"
            state.last_enemy = nil
            process_ticks.end_override(true)
            if refs.rage.main.double_tap_fake_lag_limit then
                refs.rage.main.double_tap_fake_lag_limit:override()
            end
            return
        end

        local player = entity.get_local_player()
        if not player or not player:is_alive() then
            reset()
            return
        end

        local command_id = cmd and cmd.command_number or globals.tickcount
        if state.last_cmd == command_id then return end
        state.last_cmd = command_id

        local mode = source_controls.lc_mode:get()
        if mode ~= "Exploit" and refs.rage.main.double_tap_fake_lag_limit then
            refs.rage.main.double_tap_fake_lag_limit:override()
        end
        local flags = tonumber(player.m_fFlags)
        local anim_state = player:get_anim_state()
        local weapon = player:get_player_weapon()
        if mode == "On enemy" or mode == "Exploit" then
            if flags == nil or bit.band(flags, 1) ~= 0 or not anim_state or not weapon then
                state.last_enemy = nil
                source_controls.lc_status = "waiting"
                if refs.rage.main.double_tap_fake_lag_limit then
                    refs.rage.main.double_tap_fake_lag_limit:override()
                end
                return
            end
            source_controls.lc_status = "waiting"
            local ok, err = pcall(run_air_teleport, cmd, player, anim_state, weapon, mode)
            if not ok and warned ~= tostring(err) then
                warned = tostring(err)
                print_raw("[social] Auto LC: " .. tostring(err))
                source_controls.lc_status = "error"
            end
            return
        end

        if flags == nil then
            state.last_enemy = nil
            source_controls.lc_status = "waiting"
            return
        end
        local in_air = bit.band(flags, 1) == 0
        local is_crouching = bit.band(flags, 2) ~= 0
        if not in_air or not is_crouching then
            state.last_enemy = nil
            source_controls.lc_status = "waiting"
            return
        end

        local enemy = get_hittable_enemy()
        if not enemy then
            state.last_enemy = nil
            source_controls.lc_status = "not hittable"
            return
        end
        trigger(enemy)
    end

    events.render(function()
        local player = entity.get_local_player()
        if not player or not player:is_alive() then reset() end
    end)
    events.level_init(reset)
    events.shutdown(reset)
end

-- Exploit Backtrack: Anemone baseline policy, with ground-only activation.
-- Conservative target is approximately 105 ms total (measured latency + native Fake Latency).
-- This trades some artificial delay for more reliable shot registration; it is not record rewriting.
do
    local ref = refs.misc.main.other.fake_latency
    local owned, applied = false, nil
    local function release()
        if owned and ref then
            local ok, current = pcall(function() return ref:get_override() end)
            if ok and current == applied then pcall(function() ref:override() end) end
        end
        owned, applied = false, nil
        source_controls.exploit_backtrack_status = "off"
    end
    local function update(cmd)
        if not source_controls.exploit_backtrack or not source_controls.exploit_backtrack:get() or not ref then
            release(); return
        end
        local player = entity.get_local_player()
        if not player or not player:is_alive() then release(); return end
        local flags = tonumber(player.m_fFlags) or 0
        local grounded = bit.band(flags, 1) ~= 0
        if not grounded then release(); source_controls.exploit_backtrack_status = "airborne"; return end
        local measured = 0
        pcall(function()
            local channel = utils.net_channel()
            if channel and channel.latency then measured = (tonumber(channel.latency[0]) or 0) * 1000 end
        end)
        local shot_flying = cmd and (cmd.in_attack == true or cmd.in_attack == 1 or cmd.in_attack2 == true or cmd.in_attack2 == 1) or false
        if not shot_flying then
            pcall(function()
                local weapon = player:get_player_weapon()
                local last_shot = weapon and tonumber(weapon.m_fLastShotTime or weapon:get_prop("m_fLastShotTime"))
                if finite_number(last_shot) then shot_flying = ((tonumber(globals.curtime) or 0)-last_shot) < 0.10 end
            end)
        end
        if shot_flying then
            source_controls.exploit_backtrack_status = "shot"
            return
        end
        local current_ok, current = pcall(function() return ref:get_override() end)
        if owned and current_ok and current ~= applied then
            owned, applied = false, nil
            source_controls.exploit_backtrack_status = "external override"
            return
        end
        if not owned and (not current_ok or current ~= nil) then
            source_controls.exploit_backtrack_status = "control busy"
            return
        end
        local desired = math.floor(math.max(0, math.min(100, 105 - measured)) + 0.5)
        local set_ok = pcall(function() ref:override(desired) end)
        if set_ok then
            owned, applied = true, desired
            source_controls.exploit_backtrack_status = "grounded"
        end
    end
    events.createmove(update)
    events.render(function()
        if not source_controls.exploit_backtrack or not source_controls.exploit_backtrack:get() then release() end
    end)
    events.level_init(release)
    events.shutdown(release)
end

-- Adaptive Fake Lags: Anemone state/distance/shot/desync policy, adapted to social refs.
-- Normal cycle ticks are randomized from 10..14; hit/shot flushes and rare troughs stay short.
do
    local fl = refs.antiaim.fake_lag
    local self = {
        owned = {}, values = {},
        fake_lag_roll = 0, fake_lag_state = nil,
        fake_lag_limit = 12, fake_lag_var = 4,
        last_health = nil, hit_flush = 0,
        last_lag_roll = nil, aimed_hold = 0,
        last_tickbase = nil, desync_ticks = 0,
        shot_flying = false, shoot_lag = nil
    }
    local function read_override(ref)
        if not ref then return false, nil end
        return pcall(function() return ref:get_override() end)
    end
    local function release()
        for key, ref in pairs({enabled=fl.enabled, limit=fl.limit, variability=fl.variability}) do
            if self.owned[key] and ref then
                local ok, current = read_override(ref)
                if ok and current == self.values[key] then pcall(function() ref:override() end) end
            end
            self.owned[key], self.values[key] = false, nil
        end
        self.last_health, self.hit_flush = nil, 0
        self.fake_lag_roll, self.fake_lag_state = 0, nil
        self.last_tickbase, self.desync_ticks = nil, 0
        self.shot_flying, self.shoot_lag = false, nil
    end
    local function set_owned(key, ref, value)
        if not ref then return end
        local ok, current = read_override(ref)
        if self.owned[key] and ok and current ~= self.values[key] then
            self.owned[key], self.values[key] = false, nil
        end
        if self.owned[key] or (ok and current == nil) then
            local success = pcall(function() ref:override(value) end)
            if success then self.owned[key], self.values[key] = true, value end
        end
    end
    local function local_state(me, speed)
        local flags = tonumber(me.m_fFlags) or 1
        local on_ground = bit.band(flags, 1) ~= 0
        local ducked = bit.band(flags, 2) ~= 0
        local fake_duck, double_tap, hide_shots, slow_walk = false, false, false, false
        pcall(function() fake_duck = refs.antiaim.misc.fake_duck:get() == true end)
        pcall(function() double_tap = refs.rage.main.double_tap:get() == true end)
        pcall(function() hide_shots = refs.rage.main.hide_shots:get() == true end)
        pcall(function() slow_walk = refs.antiaim.misc.slow_walk:get() == true end)
        if not fake_duck and not double_tap and not hide_shots then return "Fake lag", speed, on_ground, ducked, false end
        if (self.ground_ticks or 0) > 5 then
            if fake_duck and not ducked then return "Fake duck", speed, on_ground, ducked, true end
            if speed > 5 then return slow_walk and "Walk" or (ducked and "Crawl" or "Run"), speed, on_ground, ducked, true end
            return ducked and "Duck" or "Stand", speed, on_ground, ducked, true
        end
        return ducked and "Air duck" or "Air", speed, on_ground, ducked, true
    end
    local function update_shot_state(cmd, me)
        local weapon, last_shot
        pcall(function() weapon = me:get_player_weapon() end)
        if weapon then pcall(function() last_shot = weapon.m_fLastShotTime or weapon:get_prop("m_fLastShotTime") end) end
        local flying = cmd and ((cmd.in_attack == true or cmd.in_attack == 1) or (cmd.in_attack2 == true or cmd.in_attack2 == 1)) or false
        if not flying and finite_number(tonumber(last_shot)) then
            flying = ((tonumber(globals.curtime) or 0) - tonumber(last_shot)) < 0.10
        end
        self.shot_flying = flying
        local tickbase
        pcall(function() tickbase = tonumber(me.m_nTickBase) end)
        if tickbase then
            if self.last_tickbase and math.abs(tickbase - self.last_tickbase) > 64 then self.last_tickbase = nil end
            if self.last_tickbase and tickbase < self.last_tickbase then
                self.desync_ticks = math.min(14, math.max(0, self.last_tickbase - tickbase - 1))
            else
                self.desync_ticks = 0
            end
            self.last_tickbase = tickbase
        end
    end
    local function update(cmd)
        if not source_controls.adaptive_fakelags or not source_controls.adaptive_fakelags:get() then release(); return end
        local me = entity.get_local_player()
        if not me or not me:is_alive() then release(); return end
        local velocity, speed = me.m_vecVelocity, 0
        pcall(function() if velocity then speed = velocity:length2d() end end)
        update_shot_state(cmd, me)
        local flags = tonumber(me.m_fFlags) or 1
        local on_ground = bit.band(flags, 1) ~= 0
        self.ground_ticks = on_ground and ((self.ground_ticks or 0) + 1) or 0
        local state, _, _, ducked, exploit = local_state(me, speed)
        local in_air = state == "Air" or state == "Air duck"
        local threat, distance = nil, 1000
        pcall(function() threat = entity.get_threat() end)
        if threat then
            pcall(function()
                local a, b = me:get_eye_position(), threat:get_eye_position()
                if a and b then
                    local dx, dy, dz = a.x-b.x, a.y-b.y, a.z-b.z
                    distance = math.sqrt(dx*dx + dy*dy + dz*dz)
                end
            end)
        end
        local health = tonumber(me.m_iHealth) or 100
        if self.last_health and health < self.last_health then self.hit_flush = math.random(4, 8) end
        self.last_health = health
        local hit_flush_active = (self.hit_flush or 0) > 0

        self.fake_lag_roll = (self.fake_lag_roll or 0) - 1
        if self.fake_lag_state ~= state then
            self.fake_lag_state, self.fake_lag_roll = state, 0
        end
        if (self.hit_flush or 0) > 0 then
            self.hit_flush = self.hit_flush - 1
            self.fake_lag_limit, self.fake_lag_var = 1, 0
        elseif self.fake_lag_roll <= 0 and not self.shot_flying then
            local far = math.max(0, math.min(1, (distance - 200) / 1200))
            local base = math.floor(10 + far * 4 + (in_air and 1 or 0) + (ducked and 1 or 0))
            if state == "Fake lag" then base = math.max(10, math.min(13, base)) end
            if exploit then base = math.max(10, base - 1) end
            if threat then
                pcall(function()
                    local their_eye, our_eye, angles = threat:get_eye_position(), me:get_eye_position(), threat.m_angEyeAngles
                    if their_eye and our_eye and angles then
                        local target_yaw = tonumber(angles.y)
                        if target_yaw then
                            local yaw_to_us = math.deg(math.atan2(our_eye.y-their_eye.y, our_eye.x-their_eye.x))
                            local delta = ((yaw_to_us-target_yaw+180)%360)-180
                            self.aimed_hold = math.abs(delta) < 25 and 5 or math.max(0, (self.aimed_hold or 0)-1)
                            if (self.aimed_hold or 0) > 0 then base = math.min(14, base + 1) end
                        end
                    end
                end)
            end
            local trough = math.random(0, 5) == 0
            local spike = (not trough and math.random(0, 4) == 0) and math.random(1, 3) or 0
            if trough then
                self.fake_lag_limit, self.fake_lag_var = math.random(1, 2), math.random(0, 5)
            else
                self.fake_lag_limit = math.max(10, math.min(14, base + math.random(-2, 2) + spike))
                local desync = tonumber(self.desync_ticks) or 0
                local variability_base = math.max(in_air and desync + 5 or desync, math.random(3, 9))
                self.fake_lag_var = math.max(0, math.min(15, variability_base + math.random(-2, 4)))
            end
            local roll, guard = math.random(4, 15), 6
            while guard > 0 and self.last_lag_roll and math.abs(roll-self.last_lag_roll) <= 1 do
                roll, guard = math.random(4, 15), guard-1
            end
            self.last_lag_roll, self.fake_lag_roll = roll, roll
        end

        local limit = tonumber(self.fake_lag_limit) or 12
        local variability = tonumber(self.fake_lag_var) or 4
        if limit >= 10 then
            if speed > 120 then limit = math.max(10, math.min(14, limit-2))
            elseif speed > 3 then limit = math.max(10, math.min(14, limit-1)) end
        end
        if self.shot_flying then
            if not self.shoot_lag then self.shoot_lag = math.max(1, math.min(5, limit-6)) end
            limit, variability = self.shoot_lag, 0
        else
            self.shoot_lag = nil
        end
        if hit_flush_active then limit, variability = 1, 0 end
        if variability > 0 and math.random(0, 2) == 0 then variability = math.random(0, math.min(15, variability+4)) end
        set_owned("enabled", fl.enabled, true)
        set_owned("limit", fl.limit, math.max(1, math.min(14, limit)))
        set_owned("variability", fl.variability, math.max(0, math.min(15, variability)))
    end
    events.createmove(update)
    events.render(function()
        if not source_controls.adaptive_fakelags or not source_controls.adaptive_fakelags:get() then release() end
    end)
    events.level_init(release)
    events.shutdown(release)
end


-- Predict Exploit Uncharge: Anemone timing policy + social-native observations.
-- Uses observed simulation timing and predicted visible peek windows; never forces attack.
do
    local timing = {}
    local records = {}
    local local_tb = nil
    local last_command = nil
    local auto_seen, auto_cooldown = nil, 0
    local accuracy_owned, accuracy_values = {}, {}
    local status = "off"

    local function finite(v) return type(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge end
    local function clamp(v, a, b) return math.max(a, math.min(b, v)) end
    local function bool_ref(ref)
        local ok, value = pcall(function() return ref and ref:get() end)
        return ok and value == true
    end
    local function read_sim(ent)
        local sim
        pcall(function()
            sim = ent:get_simulation_time()
            if type(sim) == "table" then sim = sim.current end
            sim = tonumber(sim)
            if not finite(sim) then sim = tonumber(ent.m_flSimulationTime) end
        end)
        return finite(sim) and sim or nil
    end
    local function read_yaw(ent)
        local yaw
        pcall(function()
            local a = ent.m_angEyeAngles
            yaw = a and tonumber(a.y)
        end)
        if not finite(yaw) then
            pcall(function()
                local a = ent:get_eye_angles()
                yaw = a and tonumber(a.y)
            end)
        end
        return finite(yaw) and ((yaw + 180) % 360 - 180) or 0
    end
    local function read_shot(ent)
        local value
        pcall(function()
            local w = ent:get_player_weapon()
            if w then value = tonumber(w.m_fLastShotTime or w:get_prop("m_fLastShotTime")) end
        end)
        return finite(value) and value or nil
    end
    local function new_timing()
        return {status="warmup", confidence=0, samples=0, burst_votes=0, pulse_events={}, cadence_conf=0, generation=1}
    end
    local function update_timing(st, sample)
        local function norm(x) return (x + 180) % 360 - 180 end
        if not finite(sample.tick) or not finite(sample.sim) then return st, "invalid" end
        if st.tick and (sample.tick < st.tick or sample.tick-st.tick > 128 or (st.uid and sample.uid and st.uid ~= sample.uid) or (st.state and sample.state and st.state ~= sample.state)) then
            local generation = (st.generation or 1) + 1
            st = new_timing(); st.generation = generation
        end
        if st.tick == sample.tick then return st, "duplicate" end
        if not st.tick then
            st.tick, st.sim, st.uid, st.state = sample.tick, sample.sim, sample.uid, sample.state
            st.yaw, st.baseline, st.quiet, st.shot, st.sim_frontier = sample.yaw, sample.yaw, 0, sample.shot, sample.sim
            return st, "warmup"
        end
        local arrival, advance = sample.tick-st.tick, sample.sim-st.sim
        local previous_sim = st.sim
        st.advance, st.arrival = advance, arrival
        st.tick, st.uid, st.state = sample.tick, sample.uid, sample.state
        if finite(sample.shot) and sample.shot > 0 then
            if finite(st.shot) and sample.shot > st.shot then st.shot_until = sample.tick+2 end
            st.shot = sample.shot
        end
        if advance == 0 then
            st.stall = (st.stall or 0) + arrival
            if st.stall > 8 then st.status, st.confidence = "stale", 0 end
            return st, "stalled"
        end
        local gap = (st.stall or 0) + arrival
        st.stall = 0
        st.sim, st.samples = sample.sim, (st.samples or 0)+1
        st.sim_frontier = math.max(st.sim_frontier or previous_sim, sample.sim)
        local event = "normal"
        if advance < -1 and advance >= -22 then
            st.status, st.confidence = "rollback_evidence", 0.80
            st.risk_until, st.burst_until = sample.tick+3, nil
            event = "rollback"
        elseif advance < -22 or advance > 64 then
            local generation = (st.generation or 1)+1
            st = new_timing(); st.generation = generation
            st.tick, st.sim, st.uid, st.state = sample.tick, sample.sim, sample.uid, sample.state
            st.yaw, st.baseline, st.sim_frontier = sample.yaw, sample.yaw, sample.sim
            return st, "reset"
        else
            local excess = advance-gap
            st.excess, st.advance, st.arrival = excess, advance, gap
            if st.samples >= 3 and gap <= 3 and excess >= 3 and excess <= 22 then
                st.burst_votes = math.min(3, (st.burst_votes or 0)+1)
                st.status, st.confidence = "burst_evidence", 0.45+0.15*st.burst_votes
                st.burst_until, st.risk_until = sample.tick+2, nil
                event = "burst"
            elseif gap >= 4 and math.abs(excess) <= 2 then
                st.status, st.confidence = "choke_release", 0.20
                st.burst_until = nil
                event = "choke_release"
            elseif not st.risk_until or sample.tick >= st.risk_until then
                st.status, st.confidence = "normal", 0
                st.burst_votes = math.max(0, (st.burst_votes or 0)-0.10)
            end
        end
        if finite(sample.yaw) then
            local yaw, pending = norm(sample.yaw), st.pending
            if pending then
                local age = sample.sim-pending.sim
                if age > 0 and age <= 4 and math.abs(norm(yaw-pending.base)) <= 15 and pending.delta*norm(yaw-pending.snap) < 0 then
                    local events = st.pulse_events
                    events[#events+1] = pending.sim
                    if #events > 7 then table.remove(events, 1) end
                    st.baseline = norm(pending.base+norm(yaw-pending.base)*0.35)
                    st.pulse_until = sample.tick+1
                    local intervals = {}
                    for i=2,#events do local d=events[i]-events[i-1]; if d>=2 and d<=40 then intervals[#intervals+1]=d end end
                    table.sort(intervals)
                    local period = #intervals>0 and intervals[math.ceil(#intervals/2)] or 0
                    local good = 0
                    for i=1,#intervals do if math.abs(intervals[i]-period)<=1 then good=good+1 end end
                    st.period, st.cadence_conf = period, (#intervals>=3 and good/#intervals or 0)
                    st.last_pulse, st.pending = pending.sim, nil
                    event = "pulse_recovery"
                elseif age < 0 or age > 4 or math.abs(norm(yaw-pending.base)) > 35 then st.pending = nil end
            end
            if not st.pending and finite(st.yaw) and advance>0 and advance<=3 then
                local jump = norm(yaw-st.yaw)
                if math.abs(jump)>=28 and (st.quiet or 0)>=2 then
                    st.pending = {sim=sample.sim, base=st.yaw, snap=yaw, delta=jump}
                    st.pulse_until = sample.tick+2
                    event = "pulse_snap"
                end
                if math.abs(jump)<=9 then
                    st.quiet = math.min(8, (st.quiet or 0)+1)
                    if not st.pending then st.baseline = yaw end
                else st.quiet = 0 end
            end
            st.yaw = yaw
        end
        return st, event
    end
    local function timing_decision(st, tick)
        if not st or not finite(tick) or not st.tick or tick<st.tick or tick-st.tick>8 or (st.stall or 0)>8 then
            return {status="stale", confidence=0, force_send=false}
        end
        local defensive = st.risk_until and tick<st.risk_until or false
        local burst = st.burst_until and tick<st.burst_until or false
        local pulse = st.pulse_until and tick<st.pulse_until or false
        local forecast = false
        if st.cadence_conf>=0.80 and st.period and st.period>=2 and st.last_pulse then
            local phase = st.sim+(tick-st.tick)-st.last_pulse
            forecast = phase>=st.period-1 and phase<=st.period+1
        end
        return {status=st.status, confidence=st.confidence or 0, defensive=defensive, burst=burst, pulse=pulse,
            forecast=forecast, force_send=defensive or (burst and (st.confidence or 0)>=0.70) or pulse,
            period=st.period, cadence_conf=st.cadence_conf,
            evidence=(burst and st.shot_until and tick<st.shot_until) and "burst_with_observed_shot" or (defensive and "simulation_rollback" or (burst and "excess_simulation_advance" or "none"))}
    end
    local function sample_observations()
        if not source_controls.predict_uncharge or not source_controls.predict_uncharge:get() or not globals.is_in_game then
            timing, records = {}, {}
            return
        end
        local tick, iv = tonumber(globals.tickcount), tonumber(globals.tickinterval)
        if not finite(tick) or not finite(iv) or iv<=0 then return end
        local ok, players = pcall(entity.get_players, true)
        if not ok or type(players)~="table" then return end
        local present = {}
        for _, ent in pairs(players) do
            local got, data = pcall(function()
                if not ent:is_alive() or ent:is_dormant() then return nil end
                local id = ent:get_index()
                local info = ent:get_player_info()
                local sim = read_sim(ent)
                local origin = ent:get_origin()
                local vel = ent.m_vecVelocity
                if not id or not info or not finite(sim) or not origin or not vel then return nil end
                local vx, vy, vz = tonumber(vel.x), tonumber(vel.y), tonumber(vel.z)
                local x, y, z = tonumber(origin.x), tonumber(origin.y), tonumber(origin.z)
                if not finite(vx) or not finite(vy) or not finite(vz) or not finite(x) or not finite(y) or not finite(z) then return nil end
                local flags = tonumber(ent.m_fFlags) or 0
                return {id=id, uid=tonumber(info.userid), sim=sim, sim_tick=math.floor(sim/iv+0.5), tick=tick,
                    x=x,y=y,z=z,vx=vx,vy=vy,vz=vz, yaw=read_yaw(ent), shot=read_shot(ent),
                    state=(bit.band(flags,1)~=0 and "ground" or "air")}
            end)
            if got and data and data.uid then
                present[data.id] = true
                local st = timing[data.id] or new_timing()
                local old_generation = st.generation
                st = update_timing(st, {tick=data.tick, sim=data.sim_tick, uid=data.uid, state=data.state, yaw=data.yaw, shot=data.shot})
                timing[data.id] = st
                local rec = records[data.id]
                if not rec or rec.uid~=data.uid or data.tick<rec.tick then
                    rec = {uid=data.uid, samples={}, events={}, quality=0.35, status="warmup", horizon=1, gap_ticks=1}
                    records[data.id] = rec
                end
                rec.tick = data.tick
                local prev = rec.last
                if not prev then
                    rec.last = data
                    rec.quality, rec.status, rec.horizon = 0.35, "warmup", 1
                elseif data.sim == prev.sim then
                    -- A changing payload at the same simulation time is not fresh evidence.
                    local moved = math.sqrt((data.x-prev.x)^2+(data.y-prev.y)^2+(data.z-prev.z)^2)
                    if moved > 0.5 then rec.quality, rec.status, rec.horizon = math.min(rec.quality or 1, 0.5), "same-simulation payload changed", 1 end
                else
                    local ds = data.sim-prev.sim
                    local quality, why, horizon = 1, "fresh", 15
                    if ds < -iv*0.5 then
                        quality, why, horizon = 0, "rollback/catchup", 1
                        rec.ax, rec.ay, rec.az = 0, 0, 0
                    elseif ds <= 0 then
                        quality, why, horizon = 0, "non-advancing simulation", 1
                        rec.ax, rec.ay, rec.az = 0, 0, 0
                    elseif ds > 0.5 then
                        quality, why, horizon = 0.25, "gap reset", 1
                        rec.ax, rec.ay, rec.az = 0, 0, 0
                        rec.events = {}
                    else
                        local dx,dy,dz = data.x-prev.x,data.y-prev.y,data.z-prev.z
                        local dvx,dvy,dvz = data.vx-prev.vx,data.vy-prev.vy,data.vz-prev.vz
                        local ax,ay,az = clamp(dvx/ds,-1200,1200),clamp(dvy/ds,-1200,1200),clamp(dvz/ds,-1200,1200)
                        rec.ax = (tonumber(rec.ax) or ax)*0.35 + ax*0.65
                        rec.ay = (tonumber(rec.ay) or ay)*0.35 + ay*0.65
                        rec.az = (tonumber(rec.az) or az)*0.35 + az*0.65
                        rec.accel_tick = data.tick
                        local accel = math.sqrt(dvx*dvx+dvy*dvy+dvz*dvz)/ds
                        local ex = dx-(data.vx+prev.vx)*0.5*ds
                        local ey = dy-(data.vy+prev.vy)*0.5*ds
                        local ez = dz-(data.vz+prev.vz)*0.5*ds
                        local residual = math.sqrt(ex*ex+ey*ey+ez*ez)
                        horizon = clamp(math.floor(math.sqrt(16/math.max(accel,1))/iv),1,15)
                        quality = clamp(1-residual/32,0,1)
                        if dx*dx+dy*dy+dz*dz>4096 then quality,why,horizon=0,"position discontinuity",1
                        elseif residual>16 then why,horizon="movement mismatch",1 end
                        local gap = math.floor(ds/iv+0.5)
                        rec.gap_ticks = gap
                        if gap>=14 and finite(data.shot) and finite(prev.shot) and data.shot>prev.shot and data.shot<=data.sim+iv then
                            rec.events[#rec.events+1] = data.tick
                            if #rec.events>4 then table.remove(rec.events,1) end
                            rec.last_burst, rec.evidence = data.tick, "simulation gap + observed shot"
                            quality, horizon = math.min(quality,0.5), math.min(horizon,2)
                        end
                    end
                    rec.last, rec.quality, rec.status, rec.horizon = data, quality, why, horizon
                end
            end
        end
        for id in pairs(timing) do if not present[id] then timing[id]=nil; records[id]=nil end end
        for id in pairs(records) do if not present[id] then records[id]=nil end end
    end
    local function assessment(id, uid, tick, iv)
        local rec = records[id]
        if not rec or rec.uid~=uid or not rec.last then return nil end
        local age = tick-(tonumber(rec.last.tick) or tick)
        local budget = clamp(math.ceil(0.03125/iv)+(rec.gap_ticks or 1)+2,4,16)
        local stale = age<0 or age>budget
        local invalid = (rec.quality or 0)==0 or stale
        local expected, anticipated = false, false
        if #rec.events>=4 then
            local intervals={}
            for i=2,#rec.events do intervals[#intervals+1]=rec.events[i]-rec.events[i-1] end
            table.sort(intervals)
            local period=intervals[math.ceil(#intervals/2)]
            local spread=intervals[#intervals]-intervals[1]
            if period>=8 and period<=128 and spread<=2 then
                expected=rec.events[#rec.events]+period
                anticipated=tick>=expected-1 and tick<=expected+1
            end
        end
        return {quality=stale and 0 or rec.quality, invalid=invalid,
            status=stale and "expired observed record" or rec.status,
            horizon=rec.horizon, age=age, budget=budget, sim=rec.last.sim,
            evidence=rec.evidence, anticipated=anticipated, next_window=expected,
            force_send=invalid or (rec.last_burst and tick-rec.last_burst<=2) or anticipated}
    end
    local function policy(decision, shared, observed, tick)
        if not shared or not observed or not finite(tick) then return nil,"waiting for observations" end
        if not finite(observed.tick) or tick<observed.tick or tick-observed.tick>2 then return nil,"waiting for fresh evidence" end
        if decision.defensive and (decision.confidence or 0)>=0.75 and decision.evidence=="simulation_rollback" then
            return "fresh simulation rollback", "rollback:"..tostring(observed.generation)..":"..tostring(observed.risk_until)
        end
        if decision.burst and (decision.confidence or 0)>=0.75 and decision.evidence=="burst_with_observed_shot" and not shared.invalid then
            return "verified excess advance + observed shot", "burst:"..tostring(observed.generation)..":"..tostring(observed.burst_until)
        end
        if shared.anticipated and not shared.invalid and shared.quality>=0.75 and finite(shared.next_window) then
            return "recurring observed gap/shot window", "window:"..tostring(shared.next_window)
        end
        return nil, shared.invalid and "waiting for valid fresh record" or "observing; no substantiated window"
    end
    local function read_number_method(obj, name)
        local value
        pcall(function() value = obj[name](obj) end)
        if type(value)=="table" then
            local x,y = tonumber(value.x), tonumber(value.y)
            if finite(x) and finite(y) then value = math.sqrt(x*x+y*y) else value=nil end
        end
        value = tonumber(value)
        return finite(value) and value or nil
    end
    local function read_accuracy(ref, ref_key, desired)
        if not ref then return end
        local ok,current = pcall(function() return ref:get_override() end)
        if accuracy_owned[ref_key] and ok and current~=accuracy_values[ref_key] then
            accuracy_owned[ref_key], accuracy_values[ref_key] = false, nil
        end
        if accuracy_owned[ref_key] or (ok and current==nil) then
            local set_ok = pcall(function() ref:override(desired) end)
            if set_ok then accuracy_owned[ref_key], accuracy_values[ref_key] = true, desired end
        end
    end
    local function release_accuracy()
        local refs_to_restore = {
            hc=refs.rage.selection.hit_chance,
            head=refs.rage.selection.multipoint_scale and refs.rage.selection.multipoint_scale[1],
            body=refs.rage.selection.multipoint_scale and refs.rage.selection.multipoint_scale[2]
        }
        for key, ref in pairs(refs_to_restore) do
            if accuracy_owned[key] and ref then
                local ok,current=pcall(function() return ref:get_override() end)
                if ok and current==accuracy_values[key] then pcall(function() ref:override() end) end
            end
            accuracy_owned[key],accuracy_values[key]=false,nil
        end
    end
    local function peek_prediction(me, enemy, iv)
        local eye, weapon = me:get_eye_position(), me:get_player_weapon()
        if not eye or not weapon then return nil end
        local velocity = enemy.m_vecVelocity
        if not velocity then return nil end
        local info = enemy:get_player_info()
        local rec = info and records[enemy:get_index()] or nil
        local use_accel = rec and rec.uid==tonumber(info.userid) and rec.quality and rec.quality>=0.5
            and finite(rec.accel_tick) and (tonumber(globals.tickcount)-rec.accel_tick)<=2
        local ax = use_accel and clamp(tonumber(rec.ax) or 0,-1200,1200) or 0
        local ay = use_accel and clamp(tonumber(rec.ay) or 0,-1200,1200) or 0
        local az = use_accel and clamp(tonumber(rec.az) or 0,-1200,1200) or 0
        local hitboxes = {0,2,5}
        local points = {}
        for _,hb in ipairs(hitboxes) do
            local p = enemy:get_hitbox_position(hb)
            if p then points[#points+1]=p end
        end
        if #points==0 then return nil end
        local best = nil
        -- Check near-term peek windows first; the old 9 x 4 scan ran 36 bullet
        -- traces per command even while DT was charging. This caps it at 15.
        for _,horizon in ipairs({0,1,2,4,6}) do
            local dt=iv*horizon
            for _,base in ipairs(points) do
                local p=base:clone()
                p.x=p.x+(tonumber(velocity.x) or 0)*dt+0.5*ax*dt*dt
                p.y=p.y+(tonumber(velocity.y) or 0)*dt+0.5*ay*dt*dt
                p.z=p.z+(tonumber(velocity.z) or 0)*dt+0.5*az*dt*dt
                local ok,damage,tr=pcall(utils.trace_bullet,me,eye,p)
                if ok and finite(tonumber(damage)) and damage>10 and tr and tr.entity==enemy then
                    best={horizon=horizon,damage=damage,point=p}
                    return best
                end
            end
        end
        return best
    end
    local function apply_stationary_accuracy(me, enemy, peek)
        if not peek then release_accuracy(); return end
        local flags=tonumber(me.m_fFlags) or 0
        local grounded=bit.band(flags,1)~=0
        local vel=me.m_vecVelocity
        local speed=0
        pcall(function() if vel then speed=vel:length2d() end end)
        if not grounded or speed>3 then release_accuracy(); return end
        local weapon=me:get_player_weapon()
        if not weapon then release_accuracy(); return end
        local inaccuracy=read_number_method(weapon,"get_inaccuracy") or 0
        local spread=read_number_method(weapon,"get_spread") or 0
        local dispersion=math.max(0,inaccuracy+spread)
        local accuracy=clamp(1-dispersion*14,0,1)
        -- Stationary-only force-shot assistance: lower HC as spread rises and widen MP.
        local hc=math.floor(clamp(42+accuracy*20,42,62)+0.5)
        local head=math.floor(clamp(84+(1-accuracy)*16,84,100)+0.5)
        local body=math.floor(clamp(76+(1-accuracy)*18,76,94)+0.5)
        read_accuracy(refs.rage.selection.hit_chance,"hc",hc)
        if refs.rage.selection.multipoint_scale then
            read_accuracy(refs.rage.selection.multipoint_scale[1],"head",head)
            read_accuracy(refs.rage.selection.multipoint_scale[2],"body",body)
        end
    end
    local function local_timing_update(cmd)
        local me=entity.get_local_player()
        if not me then return nil end
        local tb=tonumber(me.m_nTickBase)
        local seq=cmd and tonumber(cmd.command_number)
        local uid
        pcall(function() local info=me:get_player_info(); uid=info and tonumber(info.userid) end)
        if not finite(tb) or not finite(seq) then return nil end
        if not local_tb or seq<local_tb.sequence or (uid and local_tb.uid~=uid) then
            local_tb={uid=uid,tb=tb,frontier=tb,delta=0,tick=globals.tickcount,sequence=seq,status="warmup"}
        elseif seq~=local_tb.sequence then
            local_tb.delta=tb-local_tb.tb
            local_tb.tb=tb
            local_tb.frontier=math.max(local_tb.frontier or tb,tb)
            local_tb.tick=globals.tickcount
            local_tb.sequence=seq
            local_tb.status=tb<(local_tb.frontier or tb)-1 and "local rollback" or (local_tb.delta>=14 and "local burst" or "normal")
        end
        return local_tb
    end
    local function update(cmd)
        if not source_controls.predict_uncharge or not source_controls.predict_uncharge:get() then
            status="off"; source_controls.predict_uncharge_status=status
            auto_seen,auto_cooldown,last_command=nil,0,nil
            release_accuracy()
            return
        end
        if not cmd then return end
        local seq=tonumber(cmd.command_number)
        if not finite(seq) then status="command identity unavailable"; source_controls.predict_uncharge_status=status; return end
        if last_command==seq then return end
        if last_command and seq<last_command then auto_seen,auto_cooldown=nil,0 end
        last_command=seq
        if not globals.is_in_game or not bool_ref(refs.rage.main.double_tap) then
            status="Double Tap / live Rage context unavailable"
            source_controls.predict_uncharge_status=status
            release_accuracy()
            return
        end
        local me=entity.get_local_player()
        if not me or not me:is_alive() then
            status="local player unavailable"; source_controls.predict_uncharge_status=status; release_accuracy(); return
        end
        local enemy
        pcall(function() enemy=entity.get_threat() end)
        if not enemy or not enemy:is_player() or not enemy:is_enemy() or not enemy:is_alive() or enemy:is_dormant() then
            status="no live threat"; source_controls.predict_uncharge_status=status; release_accuracy(); return
        end
        local info=enemy:get_player_info()
        local uid=info and tonumber(info.userid)
        local index=enemy:get_index()
        local tick,iv=tonumber(globals.tickcount),tonumber(globals.tickinterval)
        if not uid or not finite(tick) or not finite(iv) or iv<=0 then
            status="target identity / tick interval unavailable"; source_controls.predict_uncharge_status=status; release_accuracy(); return
        end
        local observed=timing[index]
        local shared=assessment(index,uid,tick,iv)
        local reason,key
        if observed and observed.uid==uid and shared then
            local decision=timing_decision(observed,tick)
            reason,key=policy(decision,shared,observed,tick)
        else
            key="observed timing warming up"
        end
        local charge
        pcall(function() charge=tonumber(rage.exploit:get()) end)
        -- Prediction traces are useful only at a charged DT window. Avoid spending
        -- command time forecasting shots while the exploit is still recharging.
        local peek=(finite(charge) and charge>=0.99) and peek_prediction(me,enemy,iv) or nil
        apply_stationary_accuracy(me,enemy,(peek and peek.horizon<=3) and peek or nil)
        local peek_reason,peek_key
        if peek and peek.horizon<=3 then
            peek_reason="predicted visible peek t+"..tostring(peek.horizon)
            peek_key="peek:"..tostring(uid)..":"..tostring(tick-peek.horizon)
        end
        if not reason and peek_reason then reason,key=peek_reason,peek_key end
        if not reason then status=key or "observing; no substantiated window"; source_controls.predict_uncharge_status=status; return end

        local local_state=local_timing_update(cmd)
        local busy=(local_state and (local_state.status=="local rollback" or local_state.status=="local burst"))
            or not finite(charge) or (charge<0.99)
        local action=(cmd.in_attack==true or cmd.in_attack==1 or cmd.in_attack2==true or cmd.in_attack2==1
            or cmd.in_use==true or cmd.in_use==1 or cmd.in_reload==true or cmd.in_reload==1)
        local native_busy=bool_ref(refs.antiaim.misc.fake_duck) or bool_ref(refs.rage.main.hide_shots)
        if busy or action or native_busy then
            status="window observed; preserving local exploit/action"
            source_controls.predict_uncharge_status=status
            return
        end
        key=tostring(uid)..":"..tostring(key)
        if auto_seen==key or tick<(auto_cooldown or 0) then
            status="window observed; duplicate/cooldown"
            source_controls.predict_uncharge_status=status
            return
        end
        cmd.send_packet,cmd.no_choke=true,true
        auto_seen,auto_cooldown=key,tick+4
        status="auto flush: "..reason
        source_controls.predict_uncharge_status=status
    end
    local function reset()
        timing,records={},{}
        local_tb=nil
        auto_seen,auto_cooldown,last_command=nil,0,nil
        release_accuracy()
        status="waiting"
        source_controls.predict_uncharge_status=status
    end
    events.net_update_end(function()
        local ok, err = pcall(sample_observations)
        if not ok then source_controls.predict_uncharge_status = "observation error" end
    end)
    events.createmove(function(cmd)
        local ok, err = pcall(update, cmd)
        if not ok then
            status = "prediction error"
            source_controls.predict_uncharge_status = status
            pcall(release_accuracy)
        end
    end)
    events.render(function()
        local me=entity.get_local_player()
        if not me or not me:is_alive() then release_accuracy() end
        if not source_controls.predict_uncharge or not source_controls.predict_uncharge:get() then release_accuracy() end
    end)
    events.level_init(reset)
    events.shutdown(reset)
end

do
    local native=refs.misc.main.other.windows
    local old,ours,baseline=nil,nil,nil
    local function same(a,b)
        if type(a)~="table" or type(b)~="table" or #a~=#b then return a==b end
        for i,v in ipairs(a) do if v~=b[i] then return false end end
        return true
    end
    local function copy(t)local out={};for i,v in ipairs(t) do out[i]=v end;return out end
    local function release()
        if ours and same(native:get_override(),ours) then
            if old~=nil then native:override(old) else native:override() end
        end
        old,ours,baseline=nil,nil,nil
    end
    local function windows()
        local replace={}
        for _,entry in ipairs({{"binds",{"keybinds","keybindlist","keybindslist","hotkeys","binds"}},{"spectators",{"spectators","spectatorlist","spectatorslist"}},{"watermark",{"watermark"}}}) do
            if source_controls[entry[1]].enabled:get() then for _,name in ipairs(entry[2]) do replace[name]=true end end
        end
        if not next(replace) then release();return end
        local current=native:get_override()
        if ours and not same(current,ours) then old,ours,baseline=nil,nil,nil;return end
        local base
        if ours then
            local raw=native:get()
            if old==nil and type(raw)=="table" and not same(raw,ours) then baseline=copy(raw) end
            base=old~=nil and old or baseline
        else
            old=type(current)=="table" and copy(current) or current
            base=current~=nil and current or native:get()
            baseline=type(base)=="table" and copy(base) or nil
        end
        if type(base)~="table" then return end
        local filtered={}
        for _,name in ipairs(base) do
            if not replace[tostring(name):lower():gsub("[^%a]","")] then filtered[#filtered+1]=name end
        end
        ours=filtered;native:override(filtered)
    end
    local font_bank = source_controls.fonts
    if not font_bank then
        font_bank = {
            body = render.load_font("Verdana", 12, "a") or 1,
            small = render.load_font("Verdana", 10, "a") or 2,
            title = render.load_font("Verdana", 12, "ab") or 1,
            detail = render.load_font("Verdana", 12, "ab") or render.load_font("Verdana", 12, "a") or 1,
            brand = render.load_font("Verdana", 16, "ab") or 1,
            value = render.load_font("Verdana", 14, "ab") or 1
        }
        source_controls.fonts = font_bank
    end
    local detail_font = font_bank.detail or font_bank.body or 1
    local fonts = {body=detail_font, small=detail_font, title=font_bank.title or detail_font, detail=detail_font, strong=detail_font, brand=font_bank.brand or font_bank.title or detail_font, value=detail_font}
    local bounds,drag,context={},nil,nil
    local positioned={}
    local boxes={}
    local held_before,right_before=false,false
    local defaults={binds={20,380},spectators={20,600},watermark={850,30}}
    local saved=db["social.hud.positions"]
    if type(saved)=="table" then
        for id,cfg in pairs(defaults) do
            local v=saved[id]
            if type(v)=="table" and type(v.x)=="number" and type(v.y)=="number" and v.x==v.x and v.y==v.y then
                source_controls[id].x:set(math.clamp(v.x,0,1000));source_controls[id].y:set(math.clamp(v.y,0,1000));positioned[id]=v.pinned~=false
            end
        end
    end
    local function save()
        local out={}
        for id in pairs(defaults) do out[id]={x=source_controls[id].x:get(),y=source_controls[id].y:get(),pinned=positioned[id]==true} end
        db["social.hud.positions"]=out
    end
    local function reset(id)
        local d=defaults[id]
        if d then source_controls[id].x:set(d[1]);source_controls[id].y:set(d[2]);positioned[id]=nil end
    end
    source_controls.reset_all_positions=function()
        for id in pairs(defaults) do reset(id) end
        save()
        if source_controls.reset_visual_positions then source_controls.reset_visual_positions() end
        if source_controls.reset_notification_position then source_controls.reset_notification_position() end
    end
    local function inside(mouse,b)
        return mouse and b and mouse.x>=b.x and mouse.x<=b.x+b.w and mouse.y>=b.y and mouse.y<=b.y+b.h
    end
    local function input()
        local mouse=ui.get_mouse_position()
        local held=common.is_button_down(1)==true
        local right=common.is_button_down(2)==true
        if ui.get_alpha()<.5 then
            if drag then save() end
            drag,context=nil,nil;held_before,right_before=held,right;return
        end
        local screen=render.screen_size()
        local pos,dim=ui.get_position(),ui.get_size()
        local blocked=inside(mouse,{x=pos.x,y=pos.y,w=dim.x,h=dim.y})
        if context then
            if held and not held_before then
                if inside(mouse,context) then
                    local row=math.floor((mouse.y-context.y)/26)+1
                    if row==1 then reset(context.id);save()
                    elseif row==2 then
                        if source_controls.reset_all_positions then source_controls.reset_all_positions() end
                    end
                end
                context=nil
            elseif right and not right_before then context=nil end
        elseif not blocked then
            local hover=nil
            for _,id in ipairs({"watermark","spectators","binds"}) do
                if source_controls[id].enabled:get() and inside(mouse,bounds[id]) then hover=id;break end
            end
            if right and not right_before and hover then
                context={id=hover,x=math.clamp(mouse.x,0,math.max(0,screen.x-172)),y=math.clamp(mouse.y,0,math.max(0,screen.y-52)),w=172,h=52}
            elseif held and not held_before and hover then
                drag={id=hover,dx=mouse.x-bounds[hover].x,dy=mouse.y-bounds[hover].y}
            end
        end
        if drag and not source_controls[drag.id].enabled:get() then drag=nil;save() end
        if drag and held then
            local b=bounds[drag.id]
            local x=math.clamp(mouse.x-drag.dx,0,math.max(0,screen.x-b.w))
            local y=math.clamp(mouse.y-drag.dy,0,math.max(0,screen.y-b.h))
            positioned[drag.id]=true
            source_controls[drag.id].x:set(math.floor(x/screen.x*1000+.5))
            source_controls[drag.id].y:set(math.floor(y/screen.y*1000+.5))
        elseif drag then drag=nil;save() end
        held_before,right_before=held,right
    end
    local function size(font,text)return render.measure_text(font,nil,tostring(text)).x end
    local function fit(font,text,width)
        text=tostring(text):gsub("[\r\n\t]"," ")
        if size(font,text)<=width then return text end
        if width<size(font,"...") then return "" end
        local bytes={}
        for char in text:gmatch("[%z\1-\127\194-\244][\128-\191]*") do bytes[#bytes+1]=char end
        while #bytes>0 and size(font,table.concat(bytes).."...")>width do bytes[#bytes]=nil end
        return table.concat(bytes).."..."
    end
    local function glass(x,y,w,h,alpha)
        alpha=math.clamp(alpha or 1,0,1)
        if alpha<=0 then return end
        if source_controls.hud_blur and source_controls.hud_blur:get() then
            render.blur(vector(x,y),vector(x+w,y+h),1,alpha,7)
        end
        local transparent = source_controls.transparent and source_controls.transparent:get()
        local background_alpha = transparent and 148 or 244
        local background_color = transparent
            and color(13,17,23,math.floor(background_alpha*alpha))
            or color(5,6,9,math.floor(background_alpha*alpha))
        render.rect(vector(x,y),vector(x+w,y+h),background_color,7)
        render.rect_outline(vector(x,y),vector(x+w,y+h),color(255,255,255,math.floor(18*alpha)),1,7)
    end
    local function watermark_width(parts)
        local brand=size(fonts.title,brand_name)
        local count=parts and #parts or 0
        if count==0 then return math.min(560,math.max(150,23+brand+12)) end
        local content=0
        for _,part in ipairs(parts) do content=content+size(fonts.detail,part) end
        return math.min(560,math.max(150,23+brand+34+content+20*(count-1)))
    end
    local function header(x,y,label,accent,alpha)
        render.circle(vector(x+12,y+12),color(accent.r,accent.g,accent.b,math.floor(255*alpha)),2,0,1)
        render.text(fonts.title,vector(x+23,y+6),color(235,240,248,math.floor(255*alpha)),nil,label)
    end
    local function text_height(font,text)
        local measured=render.measure_text(font,nil,tostring(text or ""))
        return measured and measured.y or 13
    end
    local function draw_binds(x,y,w,h,alpha,rows)
        local accent=(ui_controls.other.visuals.accent_color and ui_controls.other.visuals.accent_color:get()) or color(192,202,255,255)
        glass(x,y,w,h,alpha)
        header(x,y,"keybinds",accent,alpha)
        if #rows==0 then return end
        local row_h=22
        for i,row in ipairs(rows) do
            local py=y+30+(i-1)*row_h
            local label=tostring(row[1] or "")
            local badge=tostring(row[2] or "")
            local th=text_height(fonts.detail,label)
            local ty=py+math.max(0,math.floor((row_h-th)/2))
            render.text(fonts.detail,vector(x+12,ty),color(229,234,243,math.floor(255*alpha)),nil,fit(fonts.detail,label,w-24-(badge~="" and size(fonts.detail,badge)+14 or 0)))
            if badge~="" then
                local bw=size(fonts.detail,badge)
                render.text(fonts.detail,vector(x+w-12-bw,ty),color(accent.r,accent.g,accent.b,math.floor(245*alpha)),nil,badge)
            end
        end
    end
    local function draw_spectators(x,y,w,h,alpha,rows)
        local accent=(ui_controls.other.visuals.accent_color and ui_controls.other.visuals.accent_color:get()) or color(192,202,255,255)
        glass(x,y,w,h,alpha)
        header(x,y,"spectators",accent,alpha)
        if #rows==0 then return end
        local row_h=21
        for i,row in ipairs(rows) do
            local py=y+30+(i-1)*row_h
            local label=tostring(row[1] or "")
            local th=text_height(fonts.detail,label)
            local ty=py+math.max(0,math.floor((row_h-th)/2))
            render.text(fonts.detail,vector(x+12,ty),color(229,234,243,math.floor(255*alpha)),nil,fit(fonts.detail,label,w-24))
        end
    end
    local function draw_brand_mark(cx,cy,accent,alpha)
        render.circle(vector(cx,cy),color(accent.r,accent.g,accent.b,math.floor(255*alpha)),2,0,1)
    end
    local function draw_watermark(x,y,w,h,alpha,rows,data)
        local accent=(ui_controls.other.visuals.accent_color and ui_controls.other.visuals.accent_color:get()) or color(192,202,255,255)
        local parts=data or rows or {}
        local a=math.floor(255*alpha)
        glass(x,y,w,h,alpha)
        draw_brand_mark(x+12,y+15,accent,alpha)
        render.text(fonts.title,vector(x+23,y+8),color(244,246,250,a),nil,brand_name)
        local brand_end=23+size(fonts.title,brand_name)
        if #parts>0 then
            local separator_x=brand_end+11
            render.rect(vector(x+separator_x,y+9),vector(x+separator_x+1,y+21),color(255,255,255,math.floor(42*alpha)))
            local cursor=brand_end+22
            for i,part in ipairs(parts) do
                local remaining=w-cursor-12
                local value=fit(fonts.detail,part,remaining)
                render.text(fonts.detail,vector(x+cursor,y+8),color(225,231,241,a),nil,value)
                cursor=cursor+size(fonts.detail,value)
                if i<#parts then
                    local sx=cursor+9
                    render.rect(vector(x+sx,y+9),vector(x+sx+1,y+21),color(255,255,255,math.floor(42*alpha)))
                    cursor=cursor+20
                end
            end
        end
    end
    local function panel(id,title,rows,opt)
        opt=opt or {}
        local cfg=source_controls[id]
        local menu_preview = ui.get_alpha() > 0.5
        if not cfg or not cfg.enabled:get() then bounds[id]=nil;return end
        local ui_alpha=1
        if #rows==0 and not opt.empty and not menu_preview then bounds[id]=nil;return end
        local screen=render.screen_size()
        local accent=(ui_controls.other.visuals.accent_color and ui_controls.other.visuals.accent_color:get()) or color(192,202,255,255)
        local limit=opt.limit or math.max(1,math.floor((screen.y-32)/(opt.row_height or 29)))
        if #rows>limit then
            local clipped={}
            for i=1,limit-1 do clipped[i]=rows[i] end
            clipped[limit]={"+ "..tostring(#rows-limit+1).." more",""}
            rows=clipped
        end
        local width=opt.width or 210
        if not opt.width then
            for _,row in ipairs(rows) do width=math.max(width,size(fonts.body,row[1])+size(fonts.small,row[2] or "")+44) end
        end
        width=math.min(width,screen.x)
        local height=opt.height or (opt.height_fn and opt.height_fn(rows)) or (36+math.max(1,#rows)*28+5)
        height=math.min(height,screen.y)
        local x=math.clamp(cfg.x:get()/1000*screen.x,0,math.max(0,screen.x-width))
        local y=math.clamp(cfg.y:get()/1000*screen.y,0,math.max(0,screen.y-height))
        if not positioned[id] and not drag then
            for attempt=1,#boxes+1 do
                local changed=false
                for _,b in ipairs(boxes) do
                    if x<b.x+b.w+7 and x+width+7>b.x and y<b.y+b.h+7 and y+height+7>b.y then
                        if b.y+b.h+8+height<=screen.y then y=b.y+b.h+8
                        elseif b.x+b.w+8+width<=screen.x then x=b.x+b.w+8
                        elseif b.y-height-8>=0 then y=b.y-height-8 end
                        changed=true;break
                    end
                end
                if not changed then break end
            end
        end
        boxes[#boxes+1]={x=x,y=y,w=width,h=height}
        bounds[id]={x=x,y=y,w=width,h=height}
        if opt.draw then opt.draw(x,y,width,height,ui_alpha,rows,opt.data);return end
        glass(x,y,width,height,ui_alpha)
        render.text(fonts.title,vector(x+14,y+12),color(210,221,242,math.floor(255*ui_alpha)),nil,title)
        render.rect(vector(x+13,y+33),vector(x+width-13,y+34),color(255,255,255,math.floor(15*ui_alpha)))
        if #rows==0 then render.text(fonts.body,vector(x+14,y+44),color(120,136,160,math.floor(255*ui_alpha)),nil,"No active "..title) end
        for i,row in ipairs(rows) do
            local py=y+36+(i-1)*28
            local value=row[2] or ""
            local value_width=math.min(size(fonts.small,value),width*.42)
            render.text(fonts.body,vector(x+14,py+6),color(221,229,245,math.floor(255*ui_alpha)),nil,fit(fonts.body,row[1],width-value_width-42))
            render.text(fonts.small,vector(x+width-14-value_width,py+7),color(accent.r,accent.g,accent.b,math.floor(210*ui_alpha)),nil,fit(fonts.small,value,value_width))
        end
    end
    local telemetry={ema=nil,last=-100,fps="-- fps",ping="-- ms",clock="--:--"}
    source_controls.telemetry=telemetry
    events.level_init(function()drag,context=nil,nil;telemetry.last=-100;telemetry.ema=nil;telemetry.ping="-- ms" end)
    events.shutdown(save)
    local function value_text(bind)
        local value=bind.value
        if type(value)=="number" then return tostring(value) end
        if type(value)=="string" and value~="" then return value end
        return bind.mode==1 and "hold" or "toggle"
    end
    local function watermark()
        local dt=globals.frametime
        if type(dt)=="number" and dt>0 and dt<1 then
            local alpha=1-math.exp(-dt/.4)
            telemetry.ema=telemetry.ema and telemetry.ema+(dt-telemetry.ema)*alpha or dt
        end
        if globals.realtime<telemetry.last or globals.realtime-telemetry.last>=.5 then
            telemetry.last=globals.realtime
            local ch=utils.net_channel()
            local seconds=nil
            if ch then
                local function lane(source,index)
                    local ok,value=pcall(function() return tonumber(source[index]) end)
                    if ok and value and value==value and value>=0 and value<10 then return value end
                end
                local outgoing=ch.avg_latency and lane(ch.avg_latency,0)
                local incoming=ch.avg_latency and lane(ch.avg_latency,1)
                if outgoing~=nil or incoming~=nil then
                    seconds=(outgoing or 0)+(incoming or 0)
                end
                local is_loopback=false
                pcall(function() is_loopback=ch.is_loopback==true end)
                if (seconds==nil or (seconds==0 and not is_loopback)) then
                    outgoing=ch.latency and lane(ch.latency,0)
                    incoming=ch.latency and lane(ch.latency,1)
                    if outgoing~=nil or incoming~=nil then
                        local instant=(outgoing or 0)+(incoming or 0)
                        if instant>0 or is_loopback then seconds=instant end
                    end
                end
            end
            if seconds==nil or seconds==0 then
                local resource=entity.get_player_resource()
                local local_player=entity.get_local_player()
                if resource and local_player then
                    local ok,ping=pcall(function() return tonumber(resource.m_iPing[local_player:get_index()]) end)
                    if ok and ping and ping>=0 and ping<5000 then seconds=ping/1000 end
                end
            end
            telemetry.ping=seconds and (math.floor(seconds*1000+.5).." ms") or "-- ms"
            telemetry.fps=telemetry.ema and (math.min(9999,math.floor(1/telemetry.ema+.5)).." fps") or "-- fps"
            telemetry.clock=common.get_date("%H:%M")
        end
        local details=source_controls.watermark.items
        local parts={}
        if details:get("User") then parts[#parts+1]=common.get_username() end
        if details:get("Latency") then parts[#parts+1]=telemetry.ping end
        if details:get("FPS") then parts[#parts+1]=telemetry.fps end
        if details:get("Time") then parts[#parts+1]=telemetry.clock end
        return parts
    end
    local function draw()
        input();windows();boxes={}
        local binds={}
        local menu_preview=ui.get_alpha()>.5
        if source_controls.binds.enabled:get() then
            for _,bind in ipairs(ui.get_binds()) do
                if bind.active then
                    local name=tostring(bind.name)
                    if name:lower()=="damage override" then name="Min Damage" end
                    binds[#binds+1]={name,value_text(bind)}
                end
            end
            table.sort(binds,function(a,b)return a[1]<b[1] end)
        end
        if source_controls.binds.enabled:get() and menu_preview and #binds==0 then
            binds={{"Min Damage","38"},{"Double Tap","toggle"},{"Fake Duck","hold"}}
        end
        local bind_width=190
        for _,row in ipairs(binds) do bind_width=math.max(bind_width,size(fonts.body,row[1])+size(fonts.body,row[2] or "")+58) end
        panel("binds","",binds,{width=math.min(bind_width,290),height_fn=function(rows)return 32+#rows*22 end,draw=draw_binds})
        local spectators={}
        local player=entity.get_local_player()
        if source_controls.spectators.enabled:get() and player then
            local list=player:get_spectators()
            if list then for _,spectator in ipairs(list) do local name=tostring(spectator:get_name() or "");if name~="" then spectators[#spectators+1]={name,""} end end end
        end
        table.sort(spectators,function(a,b)return a[1]<b[1] end)
        if source_controls.spectators.enabled:get() and menu_preview and #spectators==0 then
            spectators={{"spectator_one",""},{"spectator_two",""}}
        end
        local spectator_width=150
        for _,row in ipairs(spectators) do spectator_width=math.max(spectator_width,size(fonts.body,row[1])+42) end
        panel("spectators","",spectators,{width=math.min(spectator_width,250),height_fn=function(rows)return 32+#rows*21 end,draw=draw_spectators})
        if source_controls.watermark.enabled:get() then
            local parts=watermark()
            panel("watermark","",{}, {width=watermark_width(parts),height=30,empty=true,draw=draw_watermark,data=parts})
        end
        if context then
            local labels={"Reset position","Reset all positions"}
            glass(context.x,context.y,context.w,context.h,1)
            local mouse=ui.get_mouse_position()
            for i,label in ipairs(labels) do
                local yy=context.y+(i-1)*26
                if inside(mouse,{x=context.x,y=yy,w=context.w,h=26}) then render.rect(vector(context.x+3,yy+2),vector(context.x+context.w-3,yy+24),color(255,255,255,12),5) end
                render.text(fonts.body,vector(context.x+10,yy+6),color(232,237,245),nil,label)
            end
        end
    end
    local last_error=nil
    events.render(function()local ok,err=pcall(draw);if not ok then release();if last_error~=tostring(err) then last_error=tostring(err);print_raw("\aA9BBFFFFsocial\a697489FF / \aEAA5B1FFwindows\aC3CCDDFF  "..tostring(err)) end end end)
    events.shutdown(release)

end
do
local phrases = {
    ["English"] = {
        kill = {
            { "ez" },
            { "sit down" },
            { "1", "difference" },
            { "outplayed", "too easy" },
            { "deleted", "who is next", "0 aim" },
            { "owned", "ez", "sit down" },
        },
        death = {
            { "lag" },
            { "interpolate" },
            { "resolver diff", "net diff" },
            { "eyes diff", "ping diff" },
            { "reported", "hvh diff", "hook me" },
        },
    },
    ["Русский"] = {
        kill = {
            { "Т..ты умер. Хозяин" },
            { "Ой кто попался :3" },
            { "Ух..", "К.. какой ФеМбоЙчик...", "скинешь мне свои чулочки?) :3" },
            { "Ах..", "Я..", "я тебя убил хозяин" },
            { "Х.. Х. Хозяин", "П.. просыпайся", "я.. я. принесу тебе монстр" },
            { "ez xozain :3" },
            { "ой [>_<]" },
            { "Опять подскальзнулся)", "миленький фембойчик.. :3" },
            { "ой чулок снимал..", "н.. н. ничего же Х.. Х. Хозяин?" },
        },
        death = {
            { "Ахх..", "Г.. Г. Глубже", "Х.. Хозяин" },
            { "Ай.. Хозяин", "т.. т. ты простишь меня", "если я буду душить тебя ляшками?" },
            { "Ахх..", "Очень глубоко..", "Х.. Х. Хозяин" },
            { "Мфх..", "Твой м.. монстр вкусней моего.." },
            { "Ахх..", "Аххх..", "Н.. Нет только не в меня", "Х.. Хозяяяииин..." },
        },
    },
}

    local talk=source_controls.talk
    local tag=source_controls.tag
    local queue,counters={}, {kill=0,death=0}
    local function clean(text)
        return tostring(text):gsub('[";\\\r\n]'," "):gsub("[%z\1-\31]",""):sub(1,180)
    end
    local function custom(value)
        local out={}
        for part in tostring(value):gmatch("[^,]+") do
            local trimmed=part:gsub("^%s+",""):gsub("%s+$","")
            if trimmed~="" then out[#out+1]={trimmed} end
        end
        return out
    end
    local function schedule(kind)
        if not talk.enabled:get() or not talk[kind]:get() then return end
        local style=talk.style:get()
        local list=phrases[style] and phrases[style][kind]
        if not list or #list==0 then return end
        counters[kind]=counters[kind]%#list+1
        for i,message in ipairs(list[counters[kind]]) do
            if #queue>=12 then break end
            queue[#queue+1]={at=globals.realtime+(i-1)*1.25,text=clean(message),kind=kind}
        end
    end
    events.player_death(function(e)
        local player=entity.get_local_player()
        if not player then return end
        local victim,attacker=entity.get(e.userid,true),entity.get(e.attacker,true)
        if attacker==player and victim and victim~=player then
            schedule("kill")
        elseif victim==player and attacker and attacker~=player then
            schedule("death")
            if source_controls.push_notification then
                local ok_name, attacker_name = pcall(function() return attacker:get_name() end)
                source_controls.push_notification("DEATH", "Killed by " .. (ok_name and tostring(attacker_name) or "opponent"))
            end
        end
    end)
    talk.enabled:set_callback(function()if not talk.enabled:get() then queue={} end end)
    local native=refs.misc.main.in_game.clan_tag
    local old,owned,last=nil,false,nil
    local blocked=false
    local lists={["Femboy"]={"фембой","стримит","ляшки :3"},["Buyme"]={"Купите","Мне","Опиоидов","Трамадол","Лирику","<3"}}
    local function cut(text)
        local out=""
        for char in tostring(text):gmatch("[%z\1-\127\194-\244][\128-\191]*") do if #out+#char>15 then break end;out=out..char end
        return out
    end
    local function release_tag()
        if not owned then return end
        if native:get_override()==false then
            common.set_clan_tag("")
            if old~=nil then native:override(old) else native:override() end
            cvar.cl_clanid:call(cvar.cl_clanid:string())
        end
        old,owned,last=nil,false,nil
    end
    local function clan()
        if not tag.enabled:get() or not globals.is_in_game then release_tag();return end
        if blocked then return end
        if not owned then old=native:get_override();native:override(false);owned=true end
        if native:get_override()~=false then blocked=true;release_tag();return end
        local mode=tag.mode:get()
        local text
        if mode=="Custom" then text=tag.custom:get()
        elseif lists[mode] then local list=lists[mode];text=list[math.floor(globals.realtime/.45)%#list+1]
        else
            local frames={"","s","so","soc","soci","socia","social","social.","social.l","social.lu","social.lua","social.lu","social.l","social.","social","socia","soci","soc","so","s",""}
            text=frames[math.floor(globals.realtime/.38)%#frames+1]
        end
        text=cut(text)
        if text~=last then common.set_clan_tag(text);last=text end
    end
    tag.enabled:set_callback(function()blocked=false;if not tag.enabled:get() then release_tag() end end)
    local warned=nil
    events.render(function()
        local ok,err=pcall(function()
            if not talk.enabled:get() or not globals.is_in_game then queue={} end
            table.sort(queue,function(a,b)return a.at<b.at end)
            local i=1
            while i<=#queue do
                local item=queue[i]
                if globals.realtime>=item.at then
                    if talk.enabled:get() and talk[item.kind]:get() and item.text~="" then utils.console_exec('say "'..item.text..'"') end
                    table.remove(queue,i)
                else i=i+1 end
            end
            clan()
        end)
        if not ok and warned~=tostring(err) then warned=tostring(err);print_raw("[social] Chat / clan: "..tostring(err)) end
    end)
    events.level_init(function()queue={};release_tag() end)
    events.shutdown(function()queue={};release_tag() end)

end

do
    local voice_event = events and events.voice_message
    local badge_url = "https://raw.githubusercontent.com/Akami-HUB/addons/main/badge.png"
    local packet_magic = 0x534F434C
    local packet_version = 1
    local heartbeat_interval = 0.5
    local peer_timeout = 4.0
    local last_heartbeat = -math.huge
    local peers = {}
    local own_entity, own_xuid, own_icon_set = nil, nil, false
    local warned = {}

    local function warn_once(key, message)
        if warned[key] then return end
        warned[key] = true
        print_raw("[social] peer sync: " .. tostring(message))
    end

    local function clear_entity_icon(player, expected_xuid)
        if not player then return end
        pcall(function()
            if expected_xuid == nil or tostring(player:get_xuid()) == tostring(expected_xuid) then
                player:set_icon()
            end
        end)
    end

    local function clear_own_badge()
        if own_icon_set and own_entity then
            clear_entity_icon(own_entity, own_xuid)
        end
        own_entity, own_xuid, own_icon_set = nil, nil, false
    end

    local function sync_own_badge()
        local player = entity.get_local_player()
        if not player then
            clear_own_badge()
            return
        end

        local ok_id, xuid = pcall(function() return tostring(player:get_xuid()) end)
        if not ok_id or not xuid or xuid == "" or xuid == "nil" then return end

        if own_entity and (own_entity ~= player or own_xuid ~= xuid) then
            clear_own_badge()
        end
        if not own_icon_set then
            local ok_icon, err = pcall(function() player:set_icon(badge_url) end)
            own_entity, own_xuid, own_icon_set = player, xuid, ok_icon
            if not ok_icon then warn_once("own_icon", err) end
        end
    end

    local function remove_peer_icon(xuid, peer)
        if not peer or not peer.icon_set or not peer.entity then return end
        clear_entity_icon(peer.entity, xuid)
        peer.icon_set = false
    end

    local function clear_peers()
        for xuid, peer in pairs(peers) do
            remove_peer_icon(xuid, peer)
        end
        peers = {}
        clear_own_badge()
    end

    local function receive_peer_packet(ctx)
        if not ctx or not ctx.buffer or not ctx.entity then return end
        local buffer, player = ctx.buffer, ctx.entity
        pcall(function() buffer:reset() end)
        local ok_magic, magic = pcall(function() return buffer:read_bits(32) end)
        local ok_version, version = pcall(function() return buffer:read_bits(8) end)

        pcall(function() buffer:reset() end)
        if not ok_magic or not ok_version or magic ~= packet_magic or version ~= packet_version then return end

        local ok_player, valid_player = pcall(function()
            return player:is_player()
        end)
        if not ok_player or not valid_player then return end

        local ok_id, xuid = pcall(function() return tostring(player:get_xuid()) end)
        if not ok_id or not xuid or xuid == "" or xuid == "nil" then return end

        local local_player = entity.get_local_player()
        if local_player then
            local ok_local, local_xuid = pcall(function() return tostring(local_player:get_xuid()) end)
            if ok_local and local_xuid == xuid then return end
        end

        local ok_index, index = pcall(function() return player:get_index() end)
        if not ok_index or type(index) ~= "number" then return end

        local now = globals.realtime
        local peer = peers[xuid]
        if peer and peer.index ~= index then
            remove_peer_icon(xuid, peer)
            peer = nil
            peers[xuid] = nil
        end
        if not peer then
            peer = {entity = player, index = index, last_seen = now, icon_set = false}
            peers[xuid] = peer
        else
            peer.entity = player
            peer.last_seen = now
        end

        if not peer.icon_set then
            local ok_icon, err = pcall(function() player:set_icon(badge_url) end)
            peer.icon_set = ok_icon
            if not ok_icon then warn_once("peer_icon", err) end
        end
    end

    local function send_peer_heartbeat()
        if not voice_event or not globals.is_in_game then return end
        if not entity.get_local_player() then return end

        local now = globals.realtime
        if now - last_heartbeat < heartbeat_interval then return end
        last_heartbeat = now

        local ok, err = pcall(function()
            voice_event:call(function(buffer)
                buffer:write_bits(packet_magic, 32)
                buffer:write_bits(packet_version, 8)
            end)
        end)
        if not ok then warn_once("send", err) end
    end

    local function peer_frame()
        local now = globals.realtime
        sync_own_badge()
        for xuid, peer in pairs(peers) do
            if now - peer.last_seen > peer_timeout then
                remove_peer_icon(xuid, peer)
                peers[xuid] = nil
            end
        end
        send_peer_heartbeat()
    end

    local function on_voice_message(ctx)
        local ok, err = pcall(receive_peer_packet, ctx)
        if not ok then warn_once("receive", err) end
    end

    if voice_event then

        events.voice_message(on_voice_message, true)
    else
        warn_once("event", "voice_message event is unavailable")
    end

    events.render(peer_frame, true)
    events.level_init(function()
        clear_peers()
        last_heartbeat = -math.huge
        sync_own_badge()
        send_peer_heartbeat()
    end)
    events.shutdown(function()
        if voice_event then events.voice_message(on_voice_message, false) end
        clear_peers()
    end)
end

do
    local visual=ui_controls.other.visuals
    local font_bank = source_controls.fonts or {body=1,small=1,title=1,brand=1}
    local detail_font = font_bank.detail or font_bank.body or 1
    local fonts = {body=detail_font,small=detail_font,title=font_bank.title or detail_font,detail=detail_font,strong=detail_font,brand=font_bank.brand or font_bank.title or detail_font,value=detail_font}
    local markers={}
    local scope_blend=0
    local function effective(ref)local v=ref:get_override();if v~=nil then return v end;return ref:get()end
    local function width(font,text)return render.measure_text(font,nil,tostring(text)).x end
    local function text(font,x,y,c,value,center)
        value=tostring(value)
        if center then x=x-width(font,value)/2 end
        render.text(font,vector(x,y),c,nil,value)
    end
    local function surface(x,y,w,h)
        if source_controls.hud_blur and source_controls.hud_blur:get() then
            render.blur(vector(x,y),vector(x+w,y+h),1,1,7)
        end
        local transparent = source_controls.transparent and source_controls.transparent:get()
        local background_color = transparent and color(13,17,23,148) or color(5,6,9,244)
        render.rect(vector(x,y),vector(x+w,y+h),background_color,7)
        render.rect_outline(vector(x,y),vector(x+w,y+h),color(255,255,255,18),1,7)
    end
    source_controls.visual={fonts=fonts,surface=surface,text=text}
    local function bound(ref)
        for _,bind in ipairs(ui.get_binds()) do
            if bind.active and bind.reference and (bind.reference==ref or bind.reference:id()==ref:id()) then return bind.value end
        end
    end

    local visual_positions=db["social.visual.positions"]
    if type(visual_positions)~="table" then visual_positions={} end
    local visual_bounds={}
    local visual_drag=nil
    local visual_drag_delta=nil
    local visual_mouse_before=false
    local visual_right_before=false
    local visual_context=nil
    local function visual_pos(id,dx,dy,w,h,screen)
        local saved=visual_positions[id]
        local x,y=dx,dy
        if type(saved)=="table" and type(saved.x)=="number" and type(saved.y)=="number" then
            x=saved.x/1000*screen.x
            y=saved.y/1000*screen.y
        end
        x=math.clamp(x,0,math.max(0,screen.x-w))
        y=math.clamp(y,0,math.max(0,screen.y-h))
        visual_bounds[id]={x=x,y=y,w=w,h=h}
        return x,y
    end
    local function visual_center_pos(id,dx,dy,w,h,screen,scope_offset,cx,cy)
        local anchor=visual_positions[id.."_center"]
        local legacy=visual_positions[id]
        local x,y=dx,dy
        local custom=false
        if type(anchor)=="table" and type(anchor.x)=="number" and type(anchor.y)=="number" then
            x=anchor.x/1000*screen.x-w/2
            y=anchor.y/1000*screen.y
            custom=true
        elseif type(legacy)=="table" and type(legacy.x)=="number" and type(legacy.y)=="number" then

            x=legacy.x/1000*screen.x
            y=legacy.y/1000*screen.y
            custom=true
        end
        if custom then

            local dx_center=(x+w/2)-(cx or screen.x/2)
            local dy_center=(y+h/2)-(cy or screen.y/2)
            if dx_center*dx_center+dy_center*dy_center<=240*240 then
                y=y+(scope_offset or 0)
            end
        else
            y=y+(scope_offset or 0)
        end
        x=math.clamp(x,0,math.max(0,screen.x-w))
        y=math.clamp(y,0,math.max(0,screen.y-h))
        visual_bounds[id]={x=x,y=y,w=w,h=h,center_anchor=true}
        return x,y
    end
    local function visual_inside(mouse,b)
        return mouse and b and mouse.x>=b.x and mouse.x<=b.x+b.w and mouse.y>=b.y and mouse.y<=b.y+b.h
    end
    local function save_visual_positions()
        db["social.visual.positions"]=visual_positions
    end
    local function reset_visual_position(id)
        if id=="all" then
            for key in pairs(visual_positions) do visual_positions[key]=nil end
        else
            visual_positions[id]=nil
            visual_positions[id.."_center"]=nil
        end
        save_visual_positions()
    end
    source_controls.reset_visual_positions=function()
        for key in pairs(visual_positions) do visual_positions[key]=nil end
        save_visual_positions()
    end
    local function visual_drag_update()
        local mouse=ui.get_mouse_position()
        local held=common.is_button_down(1)==true
        local right=common.is_button_down(2)==true
        if ui.get_alpha()<.5 then
            if visual_drag then save_visual_positions() end
            visual_drag=nil;visual_drag_delta=nil;visual_context=nil
            visual_mouse_before=held;visual_right_before=right
            return
        end
        local pos,dim=ui.get_position(),ui.get_size()
        local in_menu=mouse and mouse.x>=pos.x and mouse.x<=pos.x+dim.x and mouse.y>=pos.y and mouse.y<=pos.y+dim.y
        local screen=render.screen_size()
        if visual_context then
            if held and not visual_mouse_before then
                if visual_inside(mouse,visual_context) then
                    local row=math.floor((mouse.y-visual_context.y)/25)+1
                    if row==1 then reset_visual_position(visual_context.id)
                    elseif row==2 then
                        if source_controls.reset_all_positions then source_controls.reset_all_positions()
                        else reset_visual_position("all") end
                    end
                end
                visual_context=nil
            elseif right and not visual_right_before then
                visual_context=nil
            end
        elseif not in_menu then
            if right and not visual_right_before then
                for _,id in ipairs({"crosshair_indicators","damage_indicator","velocity_warning"}) do
                    if visual_inside(mouse,visual_bounds[id]) then
                        visual_context={id=id,x=math.clamp(mouse.x,0,math.max(0,screen.x-176)),y=math.clamp(mouse.y,0,math.max(0,screen.y-50)),w=176,h=50}
                        break
                    end
                end
            elseif held and not visual_mouse_before then
                for _,id in ipairs({"crosshair_indicators","damage_indicator","velocity_warning"}) do
                    local b=visual_bounds[id]
                    if visual_inside(mouse,b) then
                        visual_drag=id
                        visual_drag_delta={x=mouse.x-b.x,y=mouse.y-b.y}
                        break
                    end
                end
            end
        end
        if visual_drag and held and mouse and visual_drag_delta then
            local b=visual_bounds[visual_drag]
            if b then
                local x=math.clamp(mouse.x-visual_drag_delta.x,0,math.max(0,screen.x-b.w))
                local y=math.clamp(mouse.y-visual_drag_delta.y,0,math.max(0,screen.y-b.h))
                if visual_drag=="crosshair_indicators" or visual_drag=="damage_indicator" then
                    visual_positions[visual_drag.."_center"]={x=(x+b.w/2)/screen.x*1000,y=y/screen.y*1000}
                    visual_positions[visual_drag]=nil
                else
                    visual_positions[visual_drag]={x=x/screen.x*1000,y=y/screen.y*1000}
                end
                b.x,b.y=x,y
            end
        elseif visual_drag and not held then
            save_visual_positions()
            visual_drag=nil;visual_drag_delta=nil
        end
        visual_mouse_before=held
        visual_right_before=right
    end
    local function draw()
        local p=entity.get_local_player()
        local alive=p~=nil and p:is_alive()
        local preview=ui.get_alpha()>.5
        if not alive and not preview then
            for _,id in ipairs({"velocity_warning","crosshair_indicators","damage_indicator"}) do visual_bounds[id]=nil end
            return
        end
        visual_drag_update()
        local screen=render.screen_size()
        local cx,cy=screen.x/2,screen.y/2
        local accent=(visual.accent_color and visual.accent_color:get()) or color(192,202,255,255)
        local bright=color(230,236,246,255)

        local scope_span=0
        local scope_top_visible=false
        local scope_bottom_visible=false
        if alive and visual.scope_overlay then
            pcall(function()
                if visual.scope_overlay.enabled:get() then
                    local scoped_value=p.m_bIsScoped
                    local scoped=(scoped_value==true or tonumber(scoped_value)==1)
                    scope_blend=interpolation.interp(scope_blend,scoped and 1 or 0,0.05)
                    local scale=math.clamp(tonumber(scope_blend) or 0,0,1)
                    if scale>0 then
                        local size_px=tonumber(visual.scope_overlay.size:get()) or 0
                        local gap_px=tonumber(visual.scope_overlay.gap:get()) or 0
                        local spread_px=0
                        local additions=visual.scope_overlay.additions
                        if additions:get("Spread Dependency") then
                            local weapon=p:get_player_weapon()
                            if weapon then spread_px=(tonumber(weapon:get_inaccuracy()) or 0)*100 end
                        end
                        scope_span=size_px*scale+gap_px+spread_px
                        if additions:get("Rotated") then scope_span=scope_span*0.70710678 end
                        local excluded=visual.scope_overlay.exclude_lines
                        scope_top_visible=not excluded:get("Top")
                        scope_bottom_visible=not excluded:get("Bottom")
                    end
                else
                    scope_blend=interpolation.interp(scope_blend,0,0.05)
                end
            end)
        else
            scope_blend=interpolation.interp(scope_blend,0,0.05)
        end
        local crosshair_scope_offset=scope_bottom_visible and scope_span or 0
        local damage_scope_offset=scope_top_visible and -scope_span or 0

        if visual.crosshair_indicators.enabled:get() then
            local dt=not not effective(refs.rage.main.double_tap)
            local hs=not not effective(refs.rage.main.hide_shots)
            local fs=not not effective(refs.antiaim.angles.freestanding)
            local selected=visual.crosshair_indicators.items
            local show_dt=selected and selected:get("DT") or false
            local show_hs=selected and selected:get("HS") or false
            local show_fs=selected and selected:get("FS") or false
            local charge=dt and math.clamp(tonumber(rage.exploit:get()) or .72,0,1) or 0
            local values={}
            if show_dt and show_hs and dt and hs then
                values[#values+1]={"OSAA",1}
            else
                if show_dt and dt then values[#values+1]={"DT",charge} end
                if show_hs and hs then values[#values+1]={"HS",1} end
            end
            if show_fs and fs then values[#values+1]={"FS",1} end
            local status_width=0
            for _,item in ipairs(values) do
                status_width=status_width+math.max(42,width(fonts.detail,item[1])+22)
            end
            local total=math.max(status_width,width(fonts.title,brand_name)+22)
            local default_crosshair_y=cy+8
            local content_h=#values>0 and 41 or 20
            local x,y=visual_center_pos("crosshair_indicators",cx-total/2,default_crosshair_y,total,content_h,screen,crosshair_scope_offset,cx,cy)
            text(fonts.title,x+total/2,y,accent,brand_name,true)
            if #values>0 then
                local cursor=x+(total-status_width)/2
                for _,item in ipairs(values) do
                    local w=math.max(42,width(fonts.detail,item[1])+22)
                    local fill=math.clamp(tonumber(item[2]) or 0,0,1)
                    text(fonts.detail,cursor+w/2,y+23,bright,item[1],true)
                    render.rect(vector(cursor+7,y+37),vector(cursor+w-7,y+38),color(255,255,255,25))
                    if fill>0 then render.rect(vector(cursor+7,y+37),vector(cursor+7+(w-14)*fill,y+38),accent) end
                    cursor=cursor+w
                end
            end
        else
            visual_bounds.crosshair_indicators=nil
        end

        if visual.damage_indicator.enabled:get() then
            local hc=bound(refs.rage.selection.hit_chance)
            local md=bound(refs.rage.selection.min_damage)
            if preview and (hc==nil and md==nil) then
                hc=hc or "76%"
                md=md or "38"
            end
            if hc~=nil or md~=nil then
                local bw,bh=112,34
                local default_damage_y=cy-bh+13
                local bx,by=visual_center_pos("damage_indicator",cx-bw/2,default_damage_y,bw,bh,screen,damage_scope_offset,cx,cy)
                if hc~=nil then
                    text(fonts.detail,bx+27,by,accent,"HC",true)
                    text(fonts.detail,bx+27,by+14,bright,hc,true)
                end
                if md~=nil then
                    text(fonts.detail,bx+85,by,accent,"DMG",true)
                    text(fonts.detail,bx+85,by+14,bright,md,true)
                end
            else
                visual_bounds.damage_indicator=nil
            end
        else
            visual_bounds.damage_indicator=nil
        end

        if visual.velocity_warning.enabled:get() then
            local modifier=alive and tonumber(p.m_flVelocityModifier) or nil
            local velocity_preview=preview and (not modifier or modifier>=0.995)
            if velocity_preview then modifier=0.78 end
            if modifier and modifier==modifier and modifier>=0 and (modifier<0.995 or velocity_preview) then
                modifier=math.clamp(modifier,0,1)
                local w,h=132,30
                local left,top=visual_pos("velocity_warning",cx-w/2,160,w,h,screen)
                local white=color(245,247,250,255)
                local accent=notification_accent()
                local value=math.floor(modifier*100+.5).."%"
                surface(left,top,w,h)
                render.text(fonts.detail,vector(left+9,top+5),white,nil,"velocity")
                render.text(fonts.detail,vector(left+w-9-width(fonts.detail,value),top+5),accent,nil,value)
                render.rect(vector(left+9,top+22),vector(left+w-9,top+23),color(255,255,255,42))
                if modifier>0 then
                    render.rect(vector(left+9,top+22),vector(left+9+(w-18)*modifier,top+23),accent)
                end
            else
                visual_bounds.velocity_warning=nil
            end
        else
            visual_bounds.velocity_warning=nil
        end

        for i=#markers,1,-1 do
            local age=globals.realtime-markers[i].at
            if age<0 or age>1 then table.remove(markers,i)
            elseif visual.hit_marker.enabled:get() and alive then
                local pos=render.world_to_screen(markers[i].position)
                if pos then
                    local accent=notification_accent()
                    local c=color(accent.r,accent.g,accent.b,math.floor((1-age)*255))
                    local gap=4;local thick=2
                    for n=0,thick-1 do
                        render.line(pos+vector(-gap-3,-gap+n),pos+vector(-gap,-gap+3+n),c)
                        render.line(pos+vector(gap+3,-gap+n),pos+vector(gap,-gap+3+n),c)
                        render.line(pos+vector(-gap-3,gap-n),pos+vector(-gap,gap-3-n),c)
                        render.line(pos+vector(gap+3,gap-n),pos+vector(gap,gap-3-n),c)
                    end
                end
            end
        end
        if visual_context then
            local cx,cy,cw,ch=visual_context.x,visual_context.y,visual_context.w,visual_context.h
            surface(cx,cy,cw,ch)
            local mouse=ui.get_mouse_position()
            local labels={"Reset position","Reset all positions"}
            for i,label in ipairs(labels) do
                local yy=cy+(i-1)*25
                if visual_inside(mouse,{x=cx,y=yy,w=cw,h=25}) then
                    render.rect(vector(cx+3,yy+2),vector(cx+cw-3,yy+23),color(255,255,255,13),4)
                end
                render.text(fonts.body,vector(cx+11,yy+5),color(232,237,246),nil,label)
            end
        end
    end
    events.shutdown(function()db["social.visual.positions"]=visual_positions end)
    events.aim_ack(function(e)
        if e and e.state==nil and e.aim and visual.hit_marker.enabled:get() then
            markers[#markers+1]={position=e.aim,at=globals.realtime}
            while #markers>32 do table.remove(markers,1) end
        end
    end)
    events.level_init(function()markers={}end)
    local failure=nil
    events.render(function()
        local ok,err=pcall(draw)
        if not ok and failure~=tostring(err) then failure=tostring(err);print_raw("\aA9BBFFFFsocial\a697489FF / \aEAA5B1FFvisuals\aC3CCDDFF  "..failure) end
    end)
end
