 
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
local function round(arg)
    return math.floor(arg + 0.5);
end;
local function concat(...)
    local result = "";
    for index = 1, select("#", ...) do
        result = result .. select(index, ...);
    end;
    return result;
end;
local config = nil;
local config = {
    cheat = "nl",
    user = common.get_username(),
    name = "social",
    build = "debug"
};
local brand_name = "social";
local brand_symbol = "s";
local enums = nil;
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
local icons = nil;
local icons = {};
local notify = {};
do
    icons.get = function(icon_name)
        local icon = notify[icon_name];
        if icon == nil then
            icon = ui.get_icon(icon_name);
            notify[icon_name] = icon;
        end;
        return icon;
    end;
end;
 
local notify = {};
local interp = "ui\\beepclear.wav";
local overlay = "resource\\warning.wav";
local presets = cvar.play;
local api = "\aA9BBFFFFsocial\a697489FF / \aC3CCDDFF";
do
    notify.success = function(message)
        message = api .. "\a9AFF9AFF" .. message;
        print_raw(message);
        print_dev(message);
        presets:call(interp);
    end;
    notify.error = function(message2)
        message2 = api .. "\aFF0032FF" .. message2;
        print_raw(message2);
        print_dev(message2);
        presets:call(overlay);
    end;
end;
 
local interp = {};
local overlay = function(from, arg2, arg3, arg4)
    return arg3 * from / arg4 + arg2;
end;
local presets = function()
    return globals.frametime;
end;
local api = function(easing, arg5, arg6, arg7, arg8)
    if arg7 <= 0 then
        return arg6;
    elseif arg8 <= arg7 then
        return arg6;
    else
        arg5 = easing(arg7, arg5, arg6 - arg5, arg8);
        if type(arg5) == "number" then
            if math.abs(arg6 - arg5) < 0.001 then
                return arg6;
            else
                local value = arg5 % 1;
                if value < 0.001 then
                    return math.floor(arg5);
                elseif value > 0.999 then
                    return math.ceil(arg5);
                end;
            end;
        end;
        return arg5;
    end;
end;
do
    interp.interp = function(from2, arg9, arg10, arg11)
        if not arg11 then
            arg11 = overlay;
        end;
        if type(arg9) == "boolean" then
            arg9 = arg9 and 1 or 0;
        end;
        return api(arg11, from2, arg9, presets(), arg10);
    end;
end;
 
local overlay = {};
local presets = ffi.typeof("        struct {\n            float x, y, z;\n        }\n    ");
local api = ffi.typeof("        struct {\n            uint8_t r, g, b, a;\n        }\n    ");
local debug_overlay_line = utils.get_vfunc("engine.dll", "VDebugOverlay004", 20, ffi.typeof("void(__thiscall*)(void *thisptr, const $ &origin, const $ &dest, int r, int g, int b, int a, bool noDepthTest, float duration)", presets, presets));
local debug_overlay_box = utils.get_vfunc("engine.dll", "VDebugOverlay004", 21, "void(__thiscall*)(void *thisptr, const $ &origin, const $ &mins, const $ &maxs, const $ &angles, $ *face_color, $ *edge_color, float duration)", presets, presets, presets, presets, api, api);
do
    overlay.line = function(from3, arg12, arg13, arg14, arg15)
        from3 = presets(from3:unpack());
        arg12 = presets(arg12:unpack());
        debug_overlay_line(from3, arg12, arg13.r, arg13.g, arg13.b, arg13.a, arg14, arg15);
    end;
    overlay.box_new = function(mins, arg16, arg17, arg18, arg19, arg20, arg21)
        mins = presets(mins:unpack());
        arg16 = presets(arg16:unpack());
        arg17 = presets(arg17:unpack());
        arg18 = presets(arg18:unpack());
        arg19 = api(arg19:unpack());
        arg20 = api(arg20:unpack());
        debug_overlay_box(mins, arg16, arg17, arg18, arg19, arg20, arg21);
    end;
end;
 
local presets = {};
local api = string.format("%s::%s::", string.lower(config.name), string.lower(config.cheat));
local debug_overlay_line = {};
 
do
    presets.bind = function(root)
        debug_overlay_box = root;
    end;
    presets.push = function(category, arg22, arg23)
        if debug_overlay_line[category] == nil then
            debug_overlay_line[category] = {};
        end;
        debug_overlay_line[category][arg22] = arg23;
        return arg23;
    end;
    presets.encode = function(encode)
        local ok, value2 = pcall(json.stringify, encode);
        encode = value2;
        success = ok;
        if not success then
            return false, "Invalid JSON";
        else
            ok, value2 = pcall(base64.encode, encode);
            encode = value2;
            success = ok;
            if not success then
                return false, "Invalid BASE64";
            else
                encode = string.gsub(encode, "[%+%/%=]", {
                    ["="] = "_",
                    ["/"] = "g2634",
                    ["+"] = "g2134"
                });
                return true, api .. encode;
            end;
        end;
    end;
    presets.decode = function(decode)
        local preset_name, value3, value4 = string.match(decode, "^(%w+)::(%w+)::(.+)$");
        decode = value4;
        cheat = value3;
        name5 = preset_name;
        if name5 ~= string.lower(config.name) then
            return false, "Preset not supported!";
        elseif cheat ~= string.lower(config.cheat) then
            return false, "Preset for another cheat!";
        else
            decode = string.gsub(decode, "[%g2134%g2634%_]", {
                g2634 = "/",
                g2134 = "+",
                _ = "="
            });
            preset_name, value3 = pcall(base64.decode, decode);
            decode = value3;
            success = preset_name;
            if not success then
                return false, "Invalid BASE64";
            else
                preset_name, value3 = pcall(json.parse, decode);
                decode = value3;
                success = preset_name;
                if not success then
                    return false, "Invalid JSON";
                else
                    return true, decode;
                end;
            end;
        end;
    end;
    presets.import = function(import)
        if import == nil then
            return false, "Preset is empty!";
        elseif type(import) ~= "table" then
            return false, "Preset is not valid!";
        else
            local value5 = 0;
            for category2, index2 in pairs(import) do
                local target_category = category2 == "Aimbot" and "Rage" or category2
                if debug_overlay_box == nil or debug_overlay_box:get(target_category) then
                    local value6 = debug_overlay_line[target_category] or debug_overlay_line[category2];
                    if value6 ~= nil then
                        if category2 == "Anti-Aim" and index2["auto_lc.states"] ~= nil and index2["auto_lc.enabled"] == nil then
                            local legacy_states=index2["auto_lc.states"]
                            local enabled=type(legacy_states)=="table" and #legacy_states>0
                            local enabled_control=value6["auto_lc.enabled"]
                            if enabled_control then pcall(enabled_control.set,enabled_control,enabled) end
                        end
                        for control, index3 in pairs(index2) do
                            local set_value = value6[control];
                            if set_value ~= nil then
                                if set_value:type() == "color_picker" then
                                    local converted = import_color(index3)
                                    if converted ~= nil then
                                        index3 = converted
                                    else
                                        set_value = nil
                                    end
                                end;
                                if set_value ~= nil then pcall(set_value.set, set_value, index3) end;
                            end;
                        end;
                        value5 = value5 + 1;
                    end;
                end;
            end;
            return true, value5;
        end;
    end;
    presets.export = function()
        local exported = {};
        for category3, index4 in pairs(debug_overlay_line) do
            local group = {};
            for key, index5 in pairs(index4) do
                local value7 = index5:get();
                if index5:type() == "color_picker" then
                    value7 = value7:to_hex();
                end;
                group[key] = value7;
            end;
            exported[category3] = group;
        end;
        return exported;
    end;
end;
 
local api = {
    rage = {
        main = {
            dormant_aimbot = ui.find("Aimbot", "Ragebot", "Main", "Enabled", "Dormant Aimbot"),
            hide_shots = ui.find("Aimbot", "Ragebot", "Main", "Hide Shots"),
            hide_shots_options = ui.find("Aimbot", "Ragebot", "Main", "Hide Shots", "Options"),
            double_tap = ui.find("Aimbot", "Ragebot", "Main", "Double Tap"),
            double_tap_lag_options = ui.find("Aimbot", "Ragebot", "Main", "Double Tap", "Lag Options"),
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
 
local debug_overlay_line = {};
local debug_overlay_box = function(pad)
    return string.rep(PAD, pad);
end;
local function pad_text(arg24, arg25)
    local pad2 = string.rep(PAD, arg25);
    return pad2 .. arg24 .. pad2;
end;
local function hidden_id(arg26, arg27)
    if string.find(arg26, "##") == nil then
        arg26 = arg26 .. "##";
    end;
    return arg26 .. arg27;
end;
local small_label_cache = {}
local function small_label(arg28)
    local cached = small_label_cache[arg28]
    if cached then return cached end
    local glyph = icons.get(arg28) or "•"
    local glyph_width = 0
    local ok, measured = pcall(render.measure_text, 2, nil, glyph)
    if ok and measured and measured.x then glyph_width = measured.x end
    -- All icons occupy the same visual column; preserve their individual glyphs.
    local spacing = math.max(0, math.min(8, math.ceil((16 - glyph_width) / 2.2)))
    cached = concat("\a{Small Text}", glyph, string.rep(PAD, spacing), "\aDEFAULT")
    small_label_cache[arg28] = cached
    return cached
end;
do
    local function section_label(arg29, arg30)
        return concat(debug_overlay_box(1), arg30 or "\a{Small Text}", "\226\128\162", "\aDEFAULT", debug_overlay_box(5), arg29);
    end;
    local function ensure_defaults(arg31)
        local section_label2 = arg31:get();
        local list = arg31:list();
        local ensure_defaults2 = arg31:type();
        local defaults = {};
        if #section_label2 == 0 then
            if ensure_defaults2 == "selectable" then
                defaults = list;
            elseif ensure_defaults2 == "listable" then
                for index6 = 1, #list do
                    defaults[index6] = list[index6];
                end;
            end;
            arg31:set(defaults);
        end;
    end;
    local function url_button(arg32)
        return function()
            panorama.SteamOverlayAPI.OpenExternalBrowserURL(arg32);
        end;
    end;
    local home_tab = {};
    local home_icon = icons.get("house");
    local home_containers = {
        profile = ui.create(home_icon, "##profile", 1),
        storage = ui.create(home_icon, "##storage", 2),
        presets = ui.create(home_icon, "##presets", 2),
        description = ui.create(home_icon, "##description", 2)
    };
    home_tab.profile = {
        build_label = home_containers.profile:label(concat(debug_overlay_box(2), small_label("signature"), debug_overlay_box(7), brand_name)),
        build_button = home_containers.profile:button(pad_text(config.build, 2), nil, true),
        discord_label = home_containers.profile:label(concat(debug_overlay_box(2), small_label("discord"), debug_overlay_box(7), "Discord")),
        discord_link_button = home_containers.profile:button(pad_text(icons.get("link"), 2), url_button("https://discord.gg/dR8vG3APvx"), true)
    };
    local presets_tab = {
        categories = home_containers.storage:selectable(section_label("Categories"), {
            [1] = "Anti-Aim",
            [2] = "Rage",
            [3] = "Visuals",
            [4] = "Miscellaneous"
        })
    };
    ensure_defaults(presets_tab.categories);
    local presets_ui = {};
    local presets_db_key = string.lower(config.name) .. "#data";
    local saved_presets = db[presets_db_key] or {};
    local preset_list = {};
    local builtin_presets = {};
    do
        do
            local function add_builtin(arg33, arg34, arg35)
                local entry = {
                    name = arg33,
                    data = arg35,
                    desc = arg34
                };
                table.insert(builtin_presets, entry);
            end;
            add_builtin("Defensive", concat("\a{Link Active}", icons.get("circle-info"), "\aDEFAULT", "  This configuration uses defensive & slow jitter anti-aim, designed specifically for community servers."), "social::nl::eyJBaW1ib3QiOnsiYWlfcGVlay5jb2xvciI6IkZGRkZGRkZGIiwiYWlfcGVlay5kb3RzIjo0LjAsImFpX3BlZWsuZW5hYmxlZCI6ZmFsc2UsImFpX3BlZWsuaGl0Ym94ZXMiOlsiSGVhZCIsIkNoZXN0IiwiU3RvbWFjaCIsIkFybXMiLCJMZWdzIiwiRmVldCJdLCJhaV9wZWVrLnJhZGl1cyI6MzIuMCwiYWlfcGVlay53ZWFwb25zIjpbIlNTRyAwOCIsIlI4IFJldm9sdmVyIiwiRGVzZXJ0IEVhZ2xlIiwiUGlzdG9sIiwiUmlmbGUiLCJTaG90Z3VuIl0sImRvcm1hbnRfYWltYm90LmFjY3VyYWN5Ijo2MC4wLCJkb3JtYW50X2FpbWJvdC5lbmFibGVkIjpmYWxzZSwiZG9ybWFudF9haW1ib3QuaGl0Ym94ZXMiOlsiSGVhZCIsIkNoZXN0IiwiU3RvbWFjaCIsIkxlZ3MiXSwiZG9ybWFudF9haW1ib3QubWluX2RhbWFnZSI6MTAuMCwiZmFrZV9sYXRlbmN5LmVuYWJsZWQiOmZhbHNlLCJsb2dfZXZlbnRzLmNvbG9yX2hpdCI6IkQ4OTg2MEZGIiwibG9nX2V2ZW50cy5jb2xvcl9taXNzIjoiODY5NEM0RkYiLCJsb2dfZXZlbnRzLmVuYWJsZWQiOnRydWUsImxvZ19ldmVudHMub3V0cHV0IjpbIkNvbnNvbGUiLCJEZWJ1ZyIsIk5vdGlmeSJdLCJtYXh1c3JjbWRwcm9jZXNzdGlja3MuZW5hYmxlZCI6ZmFsc2UsIm1heHVzcmNtZHByb2Nlc3N0aWNrcy50aWNrcyI6MTYuMH0sIkFudGktQWltIjp7IkNvdW50ZXItVGVycm9yaXN0OkFpciBDcm91Y2g6Ym9keV95YXciOiJKaXR0ZXIiLCJDb3VudGVyLVRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlZmVuc2l2ZV9jaG9rZV8xIjoxNi4wLCJDb3VudGVyLVRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlZmVuc2l2ZV9jaG9rZV8yIjoxNi4wLCJDb3VudGVyLVRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlZmVuc2l2ZV9jdXN0b21fY2hva2UiOmZhbHNlLCJDb3VudGVyLVRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlZmVuc2l2ZV9lbmFibGVkIjp0cnVlLCJDb3VudGVyLVRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlZmVuc2l2ZV9mb3JjZV9kZWZlbnNpdmUiOnRydWUsIkNvdW50ZXItVGVycm9yaXN0OkFpciBDcm91Y2g6ZGVmZW5zaXZlX3BpdGNoIjoiU3RhdGljIiwiQ291bnRlci1UZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfcGl0Y2hfMSI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlZmVuc2l2ZV9waXRjaF8yIjowLjAsIkNvdW50ZXItVGVycm9yaXN0OkFpciBDcm91Y2g6ZGVmZW5zaXZlX3BpdGNoX29mZnNldCI6LTQ1LjAsIkNvdW50ZXItVGVycm9yaXN0OkFpciBDcm91Y2g6ZGVmZW5zaXZlX3JhbmRvbV9jaG9rZSI6ZmFsc2UsIkNvdW50ZXItVGVycm9yaXN0OkFpciBDcm91Y2g6ZGVmZW5zaXZlX3JhbmRvbWl6YXRpb24iOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfeWF3IjoiU3BpbiIsIkNvdW50ZXItVGVycm9yaXN0OkFpciBDcm91Y2g6ZGVmZW5zaXZlX3lhd18xIjowLjAsIkNvdW50ZXItVGVycm9yaXN0OkFpciBDcm91Y2g6ZGVmZW5zaXZlX3lhd18yIjowLjAsIkNvdW50ZXItVGVycm9yaXN0OkFpciBDcm91Y2g6ZGVmZW5zaXZlX3lhd19vZmZzZXQiOjM2MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlZmVuc2l2ZV95YXdfc3BlZWQiOjUwLjAsIkNvdW50ZXItVGVycm9yaXN0OkFpciBDcm91Y2g6ZGVsYXlfMSI6MS4wLCJDb3VudGVyLVRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlbGF5XzIiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6QWlyIENyb3VjaDpsZWZ0X2xpbWl0Ijo1OC4wLCJDb3VudGVyLVRlcnJvcmlzdDpBaXIgQ3JvdWNoOm1vZGlmaWVyX29mZnNldCI6LTQ2LjAsIkNvdW50ZXItVGVycm9yaXN0OkFpciBDcm91Y2g6cmlnaHRfbGltaXQiOjU4LjAsIkNvdW50ZXItVGVycm9yaXN0OkFpciBDcm91Y2g6eWF3X2FkZCI6dHJ1ZSwiQ291bnRlci1UZXJyb3Jpc3Q6QWlyIENyb3VjaDp5YXdfbGVmdCI6LTMxLjAsIkNvdW50ZXItVGVycm9yaXN0OkFpciBDcm91Y2g6eWF3X21vZGlmaWVyIjoiRGlzYWJsZWQiLCJDb3VudGVyLVRlcnJvcmlzdDpBaXIgQ3JvdWNoOnlhd19vZmZzZXQiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6QWlyIENyb3VjaDp5YXdfcmlnaHQiOjM3LjAsIkNvdW50ZXItVGVycm9yaXN0OkNyb3VjaGluZzpib2R5X3lhdyI6IkppdHRlciIsIkNvdW50ZXItVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfY2hva2VfMSI6MTYuMCwiQ291bnRlci1UZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlZmVuc2l2ZV9jaG9rZV8yIjoxNi4wLCJDb3VudGVyLVRlcnJvcmlzdDpDcm91Y2hpbmc6ZGVmZW5zaXZlX2N1c3RvbV9jaG9rZSI6ZmFsc2UsIkNvdW50ZXItVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfZW5hYmxlZCI6dHJ1ZSwiQ291bnRlci1UZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlZmVuc2l2ZV9mb3JjZV9kZWZlbnNpdmUiOnRydWUsIkNvdW50ZXItVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfcGl0Y2giOiJKaXR0ZXIiLCJDb3VudGVyLVRlcnJvcmlzdDpDcm91Y2hpbmc6ZGVmZW5zaXZlX3BpdGNoXzEiOi00NS4wLCJDb3VudGVyLVRlcnJvcmlzdDpDcm91Y2hpbmc6ZGVmZW5zaXZlX3BpdGNoXzIiOjQ1LjAsIkNvdW50ZXItVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfcGl0Y2hfb2Zmc2V0IjowLjAsIkNvdW50ZXItVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfcmFuZG9tX2Nob2tlIjpmYWxzZSwiQ291bnRlci1UZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlZmVuc2l2ZV9yYW5kb21pemF0aW9uIjowLjAsIkNvdW50ZXItVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfeWF3IjoiU3RhdGljIiwiQ291bnRlci1UZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlZmVuc2l2ZV95YXdfMSI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpDcm91Y2hpbmc6ZGVmZW5zaXZlX3lhd18yIjowLjAsIkNvdW50ZXItVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfeWF3X29mZnNldCI6MTgwLjAsIkNvdW50ZXItVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfeWF3X3NwZWVkIjoyMC4wLCJDb3VudGVyLVRlcnJvcmlzdDpDcm91Y2hpbmc6ZGVsYXlfMSI6MS4wLCJDb3VudGVyLVRlcnJvcmlzdDpDcm91Y2hpbmc6ZGVsYXlfMiI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpDcm91Y2hpbmc6bGVmdF9saW1pdCI6NjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6Q3JvdWNoaW5nOm1vZGlmaWVyX29mZnNldCI6LTM1LjAsIkNvdW50ZXItVGVycm9yaXN0OkNyb3VjaGluZzpyaWdodF9saW1pdCI6NjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6Q3JvdWNoaW5nOnlhd19hZGQiOnRydWUsIkNvdW50ZXItVGVycm9yaXN0OkNyb3VjaGluZzp5YXdfbGVmdCI6LTMxLjAsIkNvdW50ZXItVGVycm9yaXN0OkNyb3VjaGluZzp5YXdfbW9kaWZpZXIiOiJEaXNhYmxlZCIsIkNvdW50ZXItVGVycm9yaXN0OkNyb3VjaGluZzp5YXdfb2Zmc2V0IjowLjAsIkNvdW50ZXItVGVycm9yaXN0OkNyb3VjaGluZzp5YXdfcmlnaHQiOjQ1LjAsIkNvdW50ZXItVGVycm9yaXN0OkluIEFpcjpib2R5X3lhdyI6IkppdHRlciIsIkNvdW50ZXItVGVycm9yaXN0OkluIEFpcjpkZWZlbnNpdmVfY2hva2VfMSI6MTYuMCwiQ291bnRlci1UZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV9jaG9rZV8yIjoxNi4wLCJDb3VudGVyLVRlcnJvcmlzdDpJbiBBaXI6ZGVmZW5zaXZlX2N1c3RvbV9jaG9rZSI6ZmFsc2UsIkNvdW50ZXItVGVycm9yaXN0OkluIEFpcjpkZWZlbnNpdmVfZW5hYmxlZCI6dHJ1ZSwiQ291bnRlci1UZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV9mb3JjZV9kZWZlbnNpdmUiOnRydWUsIkNvdW50ZXItVGVycm9yaXN0OkluIEFpcjpkZWZlbnNpdmVfcGl0Y2giOiJTdGF0aWMiLCJDb3VudGVyLVRlcnJvcmlzdDpJbiBBaXI6ZGVmZW5zaXZlX3BpdGNoXzEiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV9waXRjaF8yIjowLjAsIkNvdW50ZXItVGVycm9yaXN0OkluIEFpcjpkZWZlbnNpdmVfcGl0Y2hfb2Zmc2V0IjotNDUuMCwiQ291bnRlci1UZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV9yYW5kb21fY2hva2UiOmZhbHNlLCJDb3VudGVyLVRlcnJvcmlzdDpJbiBBaXI6ZGVmZW5zaXZlX3JhbmRvbWl6YXRpb24iOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV95YXciOiJTd2l0Y2giLCJDb3VudGVyLVRlcnJvcmlzdDpJbiBBaXI6ZGVmZW5zaXZlX3lhd18xIjotOTAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV95YXdfMiI6OTAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV95YXdfb2Zmc2V0IjoxODAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV95YXdfc3BlZWQiOjIwLjAsIkNvdW50ZXItVGVycm9yaXN0OkluIEFpcjpkZWxheV8xIjoxLjAsIkNvdW50ZXItVGVycm9yaXN0OkluIEFpcjpkZWxheV8yIjowLjAsIkNvdW50ZXItVGVycm9yaXN0OkluIEFpcjpsZWZ0X2xpbWl0Ijo1OC4wLCJDb3VudGVyLVRlcnJvcmlzdDpJbiBBaXI6bW9kaWZpZXJfb2Zmc2V0IjotNDcuMCwiQ291bnRlci1UZXJyb3Jpc3Q6SW4gQWlyOnJpZ2h0X2xpbWl0Ijo1OC4wLCJDb3VudGVyLVRlcnJvcmlzdDpJbiBBaXI6eWF3X2FkZCI6dHJ1ZSwiQ291bnRlci1UZXJyb3Jpc3Q6SW4gQWlyOnlhd19sZWZ0IjotMjYuMCwiQ291bnRlci1UZXJyb3Jpc3Q6SW4gQWlyOnlhd19tb2RpZmllciI6IkRpc2FibGVkIiwiQ291bnRlci1UZXJyb3Jpc3Q6SW4gQWlyOnlhd19vZmZzZXQiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6SW4gQWlyOnlhd19yaWdodCI6MzkuMCwiQ291bnRlci1UZXJyb3Jpc3Q6UnVubmluZzpib2R5X3lhdyI6IkppdHRlciIsIkNvdW50ZXItVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX2Nob2tlXzEiOjIuMCwiQ291bnRlci1UZXJyb3Jpc3Q6UnVubmluZzpkZWZlbnNpdmVfY2hva2VfMiI6Ni4wLCJDb3VudGVyLVRlcnJvcmlzdDpSdW5uaW5nOmRlZmVuc2l2ZV9jdXN0b21fY2hva2UiOnRydWUsIkNvdW50ZXItVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX2VuYWJsZWQiOmZhbHNlLCJDb3VudGVyLVRlcnJvcmlzdDpSdW5uaW5nOmRlZmVuc2l2ZV9mb3JjZV9kZWZlbnNpdmUiOmZhbHNlLCJDb3VudGVyLVRlcnJvcmlzdDpSdW5uaW5nOmRlZmVuc2l2ZV9waXRjaCI6IkppdHRlciIsIkNvdW50ZXItVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX3BpdGNoXzEiOi00NS4wLCJDb3VudGVyLVRlcnJvcmlzdDpSdW5uaW5nOmRlZmVuc2l2ZV9waXRjaF8yIjowLjAsIkNvdW50ZXItVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX3BpdGNoX29mZnNldCI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpSdW5uaW5nOmRlZmVuc2l2ZV9yYW5kb21fY2hva2UiOnRydWUsIkNvdW50ZXItVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX3JhbmRvbWl6YXRpb24iOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6UnVubmluZzpkZWZlbnNpdmVfeWF3IjoiU3dpdGNoIiwiQ291bnRlci1UZXJyb3Jpc3Q6UnVubmluZzpkZWZlbnNpdmVfeWF3XzEiOi05MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpSdW5uaW5nOmRlZmVuc2l2ZV95YXdfMiI6OTAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6UnVubmluZzpkZWZlbnNpdmVfeWF3X29mZnNldCI6MTgwLjAsIkNvdW50ZXItVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX3lhd19zcGVlZCI6NTAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6UnVubmluZzpkZWxheV8xIjoxLjAsIkNvdW50ZXItVGVycm9yaXN0OlJ1bm5pbmc6ZGVsYXlfMiI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpSdW5uaW5nOmxlZnRfbGltaXQiOjYwLjAsIkNvdW50ZXItVGVycm9yaXN0OlJ1bm5pbmc6bW9kaWZpZXJfb2Zmc2V0IjotNTIuMCwiQ291bnRlci1UZXJyb3Jpc3Q6UnVubmluZzpyaWdodF9saW1pdCI6NjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6UnVubmluZzp5YXdfYWRkIjp0cnVlLCJDb3VudGVyLVRlcnJvcmlzdDpSdW5uaW5nOnlhd19sZWZ0IjotMzIuMCwiQ291bnRlci1UZXJyb3Jpc3Q6UnVubmluZzp5YXdfbW9kaWZpZXIiOiJEaXNhYmxlZCIsIkNvdW50ZXItVGVycm9yaXN0OlJ1bm5pbmc6eWF3X29mZnNldCI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpSdW5uaW5nOnlhd19yaWdodCI6MzcuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U25lYWtpbmc6Ym9keV95YXciOiJKaXR0ZXIiLCJDb3VudGVyLVRlcnJvcmlzdDpTbmVha2luZzpkZWZlbnNpdmVfY2hva2VfMSI6MTYuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX2Nob2tlXzIiOjE2LjAsIkNvdW50ZXItVGVycm9yaXN0OlNuZWFraW5nOmRlZmVuc2l2ZV9jdXN0b21fY2hva2UiOmZhbHNlLCJDb3VudGVyLVRlcnJvcmlzdDpTbmVha2luZzpkZWZlbnNpdmVfZW5hYmxlZCI6ZmFsc2UsIkNvdW50ZXItVGVycm9yaXN0OlNuZWFraW5nOmRlZmVuc2l2ZV9mb3JjZV9kZWZlbnNpdmUiOmZhbHNlLCJDb3VudGVyLVRlcnJvcmlzdDpTbmVha2luZzpkZWZlbnNpdmVfcGl0Y2giOiJTdGF0aWMiLCJDb3VudGVyLVRlcnJvcmlzdDpTbmVha2luZzpkZWZlbnNpdmVfcGl0Y2hfMSI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpTbmVha2luZzpkZWZlbnNpdmVfcGl0Y2hfMiI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpTbmVha2luZzpkZWZlbnNpdmVfcGl0Y2hfb2Zmc2V0IjowLjAsIkNvdW50ZXItVGVycm9yaXN0OlNuZWFraW5nOmRlZmVuc2l2ZV9yYW5kb21fY2hva2UiOmZhbHNlLCJDb3VudGVyLVRlcnJvcmlzdDpTbmVha2luZzpkZWZlbnNpdmVfcmFuZG9taXphdGlvbiI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpTbmVha2luZzpkZWZlbnNpdmVfeWF3IjoiU3RhdGljIiwiQ291bnRlci1UZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX3lhd18xIjowLjAsIkNvdW50ZXItVGVycm9yaXN0OlNuZWFraW5nOmRlZmVuc2l2ZV95YXdfMiI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpTbmVha2luZzpkZWZlbnNpdmVfeWF3X29mZnNldCI6MTgwLjAsIkNvdW50ZXItVGVycm9yaXN0OlNuZWFraW5nOmRlZmVuc2l2ZV95YXdfc3BlZWQiOjIwLjAsIkNvdW50ZXItVGVycm9yaXN0OlNuZWFraW5nOmRlbGF5XzEiOjEuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U25lYWtpbmc6ZGVsYXlfMiI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpTbmVha2luZzpsZWZ0X2xpbWl0Ijo2MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpTbmVha2luZzptb2RpZmllcl9vZmZzZXQiOi0zNS4wLCJDb3VudGVyLVRlcnJvcmlzdDpTbmVha2luZzpyaWdodF9saW1pdCI6NjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U25lYWtpbmc6eWF3X2FkZCI6dHJ1ZSwiQ291bnRlci1UZXJyb3Jpc3Q6U25lYWtpbmc6eWF3X2xlZnQiOi0yNy4wLCJDb3VudGVyLVRlcnJvcmlzdDpTbmVha2luZzp5YXdfbW9kaWZpZXIiOiJEaXNhYmxlZCIsIkNvdW50ZXItVGVycm9yaXN0OlNuZWFraW5nOnlhd19vZmZzZXQiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U25lYWtpbmc6eWF3X3JpZ2h0IjozMy4wLCJDb3VudGVyLVRlcnJvcmlzdDpTdGFuZGluZzpib2R5X3lhdyI6IkppdHRlciIsIkNvdW50ZXItVGVycm9yaXN0OlN0YW5kaW5nOmRlZmVuc2l2ZV9jaG9rZV8xIjoxNi4wLCJDb3VudGVyLVRlcnJvcmlzdDpTdGFuZGluZzpkZWZlbnNpdmVfY2hva2VfMiI6MTYuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX2N1c3RvbV9jaG9rZSI6ZmFsc2UsIkNvdW50ZXItVGVycm9yaXN0OlN0YW5kaW5nOmRlZmVuc2l2ZV9lbmFibGVkIjpmYWxzZSwiQ291bnRlci1UZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX2ZvcmNlX2RlZmVuc2l2ZSI6ZmFsc2UsIkNvdW50ZXItVGVycm9yaXN0OlN0YW5kaW5nOmRlZmVuc2l2ZV9waXRjaCI6IlN0YXRpYyIsIkNvdW50ZXItVGVycm9yaXN0OlN0YW5kaW5nOmRlZmVuc2l2ZV9waXRjaF8xIjowLjAsIkNvdW50ZXItVGVycm9yaXN0OlN0YW5kaW5nOmRlZmVuc2l2ZV9waXRjaF8yIjowLjAsIkNvdW50ZXItVGVycm9yaXN0OlN0YW5kaW5nOmRlZmVuc2l2ZV9waXRjaF9vZmZzZXQiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX3JhbmRvbV9jaG9rZSI6ZmFsc2UsIkNvdW50ZXItVGVycm9yaXN0OlN0YW5kaW5nOmRlZmVuc2l2ZV9yYW5kb21pemF0aW9uIjowLjAsIkNvdW50ZXItVGVycm9yaXN0OlN0YW5kaW5nOmRlZmVuc2l2ZV95YXciOiJTdGF0aWMiLCJDb3VudGVyLVRlcnJvcmlzdDpTdGFuZGluZzpkZWZlbnNpdmVfeWF3XzEiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX3lhd18yIjowLjAsIkNvdW50ZXItVGVycm9yaXN0OlN0YW5kaW5nOmRlZmVuc2l2ZV95YXdfb2Zmc2V0IjoxODAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX3lhd19zcGVlZCI6MjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVsYXlfMSI6MS4wLCJDb3VudGVyLVRlcnJvcmlzdDpTdGFuZGluZzpkZWxheV8yIjowLjAsIkNvdW50ZXItVGVycm9yaXN0OlN0YW5kaW5nOmxlZnRfbGltaXQiOjMwLjAsIkNvdW50ZXItVGVycm9yaXN0OlN0YW5kaW5nOm1vZGlmaWVyX29mZnNldCI6LTQ2LjAsIkNvdW50ZXItVGVycm9yaXN0OlN0YW5kaW5nOnJpZ2h0X2xpbWl0IjozMC4wLCJDb3VudGVyLVRlcnJvcmlzdDpTdGFuZGluZzp5YXdfYWRkIjp0cnVlLCJDb3VudGVyLVRlcnJvcmlzdDpTdGFuZGluZzp5YXdfbGVmdCI6LTMwLjAsIkNvdW50ZXItVGVycm9yaXN0OlN0YW5kaW5nOnlhd19tb2RpZmllciI6IkRpc2FibGVkIiwiQ291bnRlci1UZXJyb3Jpc3Q6U3RhbmRpbmc6eWF3X29mZnNldCI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpTdGFuZGluZzp5YXdfcmlnaHQiOjM0LjAsIkNvdW50ZXItVGVycm9yaXN0OldhbGtpbmc6Ym9keV95YXciOiJKaXR0ZXIiLCJDb3VudGVyLVRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV9jaG9rZV8xIjoxNi4wLCJDb3VudGVyLVRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV9jaG9rZV8yIjoxNi4wLCJDb3VudGVyLVRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV9jdXN0b21fY2hva2UiOmZhbHNlLCJDb3VudGVyLVRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV9lbmFibGVkIjpmYWxzZSwiQ291bnRlci1UZXJyb3Jpc3Q6V2Fsa2luZzpkZWZlbnNpdmVfZm9yY2VfZGVmZW5zaXZlIjpmYWxzZSwiQ291bnRlci1UZXJyb3Jpc3Q6V2Fsa2luZzpkZWZlbnNpdmVfcGl0Y2giOiJTdGF0aWMiLCJDb3VudGVyLVRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV9waXRjaF8xIjowLjAsIkNvdW50ZXItVGVycm9yaXN0OldhbGtpbmc6ZGVmZW5zaXZlX3BpdGNoXzIiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6V2Fsa2luZzpkZWZlbnNpdmVfcGl0Y2hfb2Zmc2V0IjowLjAsIkNvdW50ZXItVGVycm9yaXN0OldhbGtpbmc6ZGVmZW5zaXZlX3JhbmRvbV9jaG9rZSI6ZmFsc2UsIkNvdW50ZXItVGVycm9yaXN0OldhbGtpbmc6ZGVmZW5zaXZlX3JhbmRvbWl6YXRpb24iOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6V2Fsa2luZzpkZWZlbnNpdmVfeWF3IjoiU3RhdGljIiwiQ291bnRlci1UZXJyb3Jpc3Q6V2Fsa2luZzpkZWZlbnNpdmVfeWF3XzEiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6V2Fsa2luZzpkZWZlbnNpdmVfeWF3XzIiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6V2Fsa2luZzpkZWZlbnNpdmVfeWF3X29mZnNldCI6MTgwLjAsIkNvdW50ZXItVGVycm9yaXN0OldhbGtpbmc6ZGVmZW5zaXZlX3lhd19zcGVlZCI6MjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6V2Fsa2luZzpkZWxheV8xIjoxLjAsIkNvdW50ZXItVGVycm9yaXN0OldhbGtpbmc6ZGVsYXlfMiI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpXYWxraW5nOmxlZnRfbGltaXQiOjYwLjAsIkNvdW50ZXItVGVycm9yaXN0OldhbGtpbmc6bW9kaWZpZXJfb2Zmc2V0IjotNS4wLCJDb3VudGVyLVRlcnJvcmlzdDpXYWxraW5nOnJpZ2h0X2xpbWl0Ijo2MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpXYWxraW5nOnlhd19hZGQiOnRydWUsIkNvdW50ZXItVGVycm9yaXN0OldhbGtpbmc6eWF3X2xlZnQiOi0zOC4wLCJDb3VudGVyLVRlcnJvcmlzdDpXYWxraW5nOnlhd19tb2RpZmllciI6IkRpc2FibGVkIiwiQ291bnRlci1UZXJyb3Jpc3Q6V2Fsa2luZzp5YXdfb2Zmc2V0IjowLjAsIkNvdW50ZXItVGVycm9yaXN0OldhbGtpbmc6eWF3X3JpZ2h0Ijo0Mi4wLCJUZXJyb3Jpc3Q6QWlyIENyb3VjaDpib2R5X3lhdyI6IkppdHRlciIsIlRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlZmVuc2l2ZV9jaG9rZV8xIjoxNi4wLCJUZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfY2hva2VfMiI6MTYuMCwiVGVycm9yaXN0OkFpciBDcm91Y2g6ZGVmZW5zaXZlX2N1c3RvbV9jaG9rZSI6ZmFsc2UsIlRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlZmVuc2l2ZV9lbmFibGVkIjp0cnVlLCJUZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfZm9yY2VfZGVmZW5zaXZlIjp0cnVlLCJUZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfcGl0Y2giOiJTdGF0aWMiLCJUZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfcGl0Y2hfMSI6MC4wLCJUZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfcGl0Y2hfMiI6MC4wLCJUZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfcGl0Y2hfb2Zmc2V0IjotNDUuMCwiVGVycm9yaXN0OkFpciBDcm91Y2g6ZGVmZW5zaXZlX3JhbmRvbV9jaG9rZSI6ZmFsc2UsIlRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlZmVuc2l2ZV9yYW5kb21pemF0aW9uIjowLjAsIlRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlZmVuc2l2ZV95YXciOiJTcGluIiwiVGVycm9yaXN0OkFpciBDcm91Y2g6ZGVmZW5zaXZlX3lhd18xIjowLjAsIlRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlZmVuc2l2ZV95YXdfMiI6MC4wLCJUZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfeWF3X29mZnNldCI6MzYwLjAsIlRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlZmVuc2l2ZV95YXdfc3BlZWQiOjUwLjAsIlRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlbGF5XzEiOjEuMCwiVGVycm9yaXN0OkFpciBDcm91Y2g6ZGVsYXlfMiI6MC4wLCJUZXJyb3Jpc3Q6QWlyIENyb3VjaDpsZWZ0X2xpbWl0Ijo1OC4wLCJUZXJyb3Jpc3Q6QWlyIENyb3VjaDptb2RpZmllcl9vZmZzZXQiOi00Ni4wLCJUZXJyb3Jpc3Q6QWlyIENyb3VjaDpyaWdodF9saW1pdCI6NTguMCwiVGVycm9yaXN0OkFpciBDcm91Y2g6eWF3X2FkZCI6dHJ1ZSwiVGVycm9yaXN0OkFpciBDcm91Y2g6eWF3X2xlZnQiOi0zMS4wLCJUZXJyb3Jpc3Q6QWlyIENyb3VjaDp5YXdfbW9kaWZpZXIiOiJEaXNhYmxlZCIsIlRlcnJvcmlzdDpBaXIgQ3JvdWNoOnlhd19vZmZzZXQiOjAuMCwiVGVycm9yaXN0OkFpciBDcm91Y2g6eWF3X3JpZ2h0IjozNy4wLCJUZXJyb3Jpc3Q6Q3JvdWNoaW5nOmJvZHlfeWF3IjoiSml0dGVyIiwiVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfY2hva2VfMSI6MTYuMCwiVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfY2hva2VfMiI6MTYuMCwiVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfY3VzdG9tX2Nob2tlIjpmYWxzZSwiVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfZW5hYmxlZCI6dHJ1ZSwiVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfZm9yY2VfZGVmZW5zaXZlIjp0cnVlLCJUZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlZmVuc2l2ZV9waXRjaCI6IkppdHRlciIsIlRlcnJvcmlzdDpDcm91Y2hpbmc6ZGVmZW5zaXZlX3BpdGNoXzEiOi00NS4wLCJUZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlZmVuc2l2ZV9waXRjaF8yIjo0NS4wLCJUZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlZmVuc2l2ZV9waXRjaF9vZmZzZXQiOjAuMCwiVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfcmFuZG9tX2Nob2tlIjpmYWxzZSwiVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfcmFuZG9taXphdGlvbiI6MC4wLCJUZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlZmVuc2l2ZV95YXciOiJTdGF0aWMiLCJUZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlZmVuc2l2ZV95YXdfMSI6MC4wLCJUZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlZmVuc2l2ZV95YXdfMiI6MC4wLCJUZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlZmVuc2l2ZV95YXdfb2Zmc2V0IjoxODAuMCwiVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfeWF3X3NwZWVkIjoyMC4wLCJUZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlbGF5XzEiOjEuMCwiVGVycm9yaXN0OkNyb3VjaGluZzpkZWxheV8yIjowLjAsIlRlcnJvcmlzdDpDcm91Y2hpbmc6bGVmdF9saW1pdCI6NjAuMCwiVGVycm9yaXN0OkNyb3VjaGluZzptb2RpZmllcl9vZmZzZXQiOi0zNS4wLCJUZXJyb3Jpc3Q6Q3JvdWNoaW5nOnJpZ2h0X2xpbWl0Ijo2MC4wLCJUZXJyb3Jpc3Q6Q3JvdWNoaW5nOnlhd19hZGQiOnRydWUsIlRlcnJvcmlzdDpDcm91Y2hpbmc6eWF3X2xlZnQiOi0zMS4wLCJUZXJyb3Jpc3Q6Q3JvdWNoaW5nOnlhd19tb2RpZmllciI6IkRpc2FibGVkIiwiVGVycm9yaXN0OkNyb3VjaGluZzp5YXdfb2Zmc2V0IjowLjAsIlRlcnJvcmlzdDpDcm91Y2hpbmc6eWF3X3JpZ2h0Ijo0NS4wLCJUZXJyb3Jpc3Q6SW4gQWlyOmJvZHlfeWF3IjoiSml0dGVyIiwiVGVycm9yaXN0OkluIEFpcjpkZWZlbnNpdmVfY2hva2VfMSI6MTYuMCwiVGVycm9yaXN0OkluIEFpcjpkZWZlbnNpdmVfY2hva2VfMiI6MTYuMCwiVGVycm9yaXN0OkluIEFpcjpkZWZlbnNpdmVfY3VzdG9tX2Nob2tlIjpmYWxzZSwiVGVycm9yaXN0OkluIEFpcjpkZWZlbnNpdmVfZW5hYmxlZCI6dHJ1ZSwiVGVycm9yaXN0OkluIEFpcjpkZWZlbnNpdmVfZm9yY2VfZGVmZW5zaXZlIjp0cnVlLCJUZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV9waXRjaCI6IlN0YXRpYyIsIlRlcnJvcmlzdDpJbiBBaXI6ZGVmZW5zaXZlX3BpdGNoXzEiOjAuMCwiVGVycm9yaXN0OkluIEFpcjpkZWZlbnNpdmVfcGl0Y2hfMiI6MC4wLCJUZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV9waXRjaF9vZmZzZXQiOi00NS4wLCJUZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV9yYW5kb21fY2hva2UiOmZhbHNlLCJUZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV9yYW5kb21pemF0aW9uIjowLjAsIlRlcnJvcmlzdDpJbiBBaXI6ZGVmZW5zaXZlX3lhdyI6IlN3aXRjaCIsIlRlcnJvcmlzdDpJbiBBaXI6ZGVmZW5zaXZlX3lhd18xIjotOTAuMCwiVGVycm9yaXN0OkluIEFpcjpkZWZlbnNpdmVfeWF3XzIiOjkwLjAsIlRlcnJvcmlzdDpJbiBBaXI6ZGVmZW5zaXZlX3lhd19vZmZzZXQiOjE4MC4wLCJUZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV95YXdfc3BlZWQiOjIwLjAsIlRlcnJvcmlzdDpJbiBBaXI6ZGVsYXlfMSI6MS4wLCJUZXJyb3Jpc3Q6SW4gQWlyOmRlbGF5XzIiOjAuMCwiVGVycm9yaXN0OkluIEFpcjpsZWZ0X2xpbWl0Ijo1OC4wLCJUZXJyb3Jpc3Q6SW4gQWlyOm1vZGlmaWVyX29mZnNldCI6LTQ3LjAsIlRlcnJvcmlzdDpJbiBBaXI6cmlnaHRfbGltaXQiOjU4LjAsIlRlcnJvcmlzdDpJbiBBaXI6eWF3X2FkZCI6dHJ1ZSwiVGVycm9yaXN0OkluIEFpcjp5YXdfbGVmdCI6LTI2LjAsIlRlcnJvcmlzdDpJbiBBaXI6eWF3X21vZGlmaWVyIjoiRGlzYWJsZWQiLCJUZXJyb3Jpc3Q6SW4gQWlyOnlhd19vZmZzZXQiOjAuMCwiVGVycm9yaXN0OkluIEFpcjp5YXdfcmlnaHQiOjM5LjAsIlRlcnJvcmlzdDpSdW5uaW5nOmJvZHlfeWF3IjoiSml0dGVyIiwiVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX2Nob2tlXzEiOjIuMCwiVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX2Nob2tlXzIiOjYuMCwiVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX2N1c3RvbV9jaG9rZSI6dHJ1ZSwiVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX2VuYWJsZWQiOmZhbHNlLCJUZXJyb3Jpc3Q6UnVubmluZzpkZWZlbnNpdmVfZm9yY2VfZGVmZW5zaXZlIjpmYWxzZSwiVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX3BpdGNoIjoiSml0dGVyIiwiVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX3BpdGNoXzEiOi00NS4wLCJUZXJyb3Jpc3Q6UnVubmluZzpkZWZlbnNpdmVfcGl0Y2hfMiI6MC4wLCJUZXJyb3Jpc3Q6UnVubmluZzpkZWZlbnNpdmVfcGl0Y2hfb2Zmc2V0IjowLjAsIlRlcnJvcmlzdDpSdW5uaW5nOmRlZmVuc2l2ZV9yYW5kb21fY2hva2UiOnRydWUsIlRlcnJvcmlzdDpSdW5uaW5nOmRlZmVuc2l2ZV9yYW5kb21pemF0aW9uIjowLjAsIlRlcnJvcmlzdDpSdW5uaW5nOmRlZmVuc2l2ZV95YXciOiJTd2l0Y2giLCJUZXJyb3Jpc3Q6UnVubmluZzpkZWZlbnNpdmVfeWF3XzEiOi05MC4wLCJUZXJyb3Jpc3Q6UnVubmluZzpkZWZlbnNpdmVfeWF3XzIiOjkwLjAsIlRlcnJvcmlzdDpSdW5uaW5nOmRlZmVuc2l2ZV95YXdfb2Zmc2V0IjoxODAuMCwiVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX3lhd19zcGVlZCI6NTAuMCwiVGVycm9yaXN0OlJ1bm5pbmc6ZGVsYXlfMSI6MS4wLCJUZXJyb3Jpc3Q6UnVubmluZzpkZWxheV8yIjowLjAsIlRlcnJvcmlzdDpSdW5uaW5nOmxlZnRfbGltaXQiOjYwLjAsIlRlcnJvcmlzdDpSdW5uaW5nOm1vZGlmaWVyX29mZnNldCI6LTUyLjAsIlRlcnJvcmlzdDpSdW5uaW5nOnJpZ2h0X2xpbWl0Ijo2MC4wLCJUZXJyb3Jpc3Q6UnVubmluZzp5YXdfYWRkIjp0cnVlLCJUZXJyb3Jpc3Q6UnVubmluZzp5YXdfbGVmdCI6LTMyLjAsIlRlcnJvcmlzdDpSdW5uaW5nOnlhd19tb2RpZmllciI6IkRpc2FibGVkIiwiVGVycm9yaXN0OlJ1bm5pbmc6eWF3X29mZnNldCI6MC4wLCJUZXJyb3Jpc3Q6UnVubmluZzp5YXdfcmlnaHQiOjM3LjAsIlRlcnJvcmlzdDpTbmVha2luZzpib2R5X3lhdyI6IkppdHRlciIsIlRlcnJvcmlzdDpTbmVha2luZzpkZWZlbnNpdmVfY2hva2VfMSI6MTYuMCwiVGVycm9yaXN0OlNuZWFraW5nOmRlZmVuc2l2ZV9jaG9rZV8yIjoxNi4wLCJUZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX2N1c3RvbV9jaG9rZSI6ZmFsc2UsIlRlcnJvcmlzdDpTbmVha2luZzpkZWZlbnNpdmVfZW5hYmxlZCI6ZmFsc2UsIlRlcnJvcmlzdDpTbmVha2luZzpkZWZlbnNpdmVfZm9yY2VfZGVmZW5zaXZlIjpmYWxzZSwiVGVycm9yaXN0OlNuZWFraW5nOmRlZmVuc2l2ZV9waXRjaCI6IlN0YXRpYyIsIlRlcnJvcmlzdDpTbmVha2luZzpkZWZlbnNpdmVfcGl0Y2hfMSI6MC4wLCJUZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX3BpdGNoXzIiOjAuMCwiVGVycm9yaXN0OlNuZWFraW5nOmRlZmVuc2l2ZV9waXRjaF9vZmZzZXQiOjAuMCwiVGVycm9yaXN0OlNuZWFraW5nOmRlZmVuc2l2ZV9yYW5kb21fY2hva2UiOmZhbHNlLCJUZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX3JhbmRvbWl6YXRpb24iOjAuMCwiVGVycm9yaXN0OlNuZWFraW5nOmRlZmVuc2l2ZV95YXciOiJTdGF0aWMiLCJUZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX3lhd18xIjowLjAsIlRlcnJvcmlzdDpTbmVha2luZzpkZWZlbnNpdmVfeWF3XzIiOjAuMCwiVGVycm9yaXN0OlNuZWFraW5nOmRlZmVuc2l2ZV95YXdfb2Zmc2V0IjoxODAuMCwiVGVycm9yaXN0OlNuZWFraW5nOmRlZmVuc2l2ZV95YXdfc3BlZWQiOjIwLjAsIlRlcnJvcmlzdDpTbmVha2luZzpkZWxheV8xIjoxLjAsIlRlcnJvcmlzdDpTbmVha2luZzpkZWxheV8yIjowLjAsIlRlcnJvcmlzdDpTbmVha2luZzpsZWZ0X2xpbWl0Ijo2MC4wLCJUZXJyb3Jpc3Q6U25lYWtpbmc6bW9kaWZpZXJfb2Zmc2V0IjotMzUuMCwiVGVycm9yaXN0OlNuZWFraW5nOnJpZ2h0X2xpbWl0Ijo2MC4wLCJUZXJyb3Jpc3Q6U25lYWtpbmc6eWF3X2FkZCI6dHJ1ZSwiVGVycm9yaXN0OlNuZWFraW5nOnlhd19sZWZ0IjotMjcuMCwiVGVycm9yaXN0OlNuZWFraW5nOnlhd19tb2RpZmllciI6IkRpc2FibGVkIiwiVGVycm9yaXN0OlNuZWFraW5nOnlhd19vZmZzZXQiOjAuMCwiVGVycm9yaXN0OlNuZWFraW5nOnlhd19yaWdodCI6MzMuMCwiVGVycm9yaXN0OlN0YW5kaW5nOmJvZHlfeWF3IjoiSml0dGVyIiwiVGVycm9yaXN0OlN0YW5kaW5nOmRlZmVuc2l2ZV9jaG9rZV8xIjoxNi4wLCJUZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX2Nob2tlXzIiOjE2LjAsIlRlcnJvcmlzdDpTdGFuZGluZzpkZWZlbnNpdmVfY3VzdG9tX2Nob2tlIjpmYWxzZSwiVGVycm9yaXN0OlN0YW5kaW5nOmRlZmVuc2l2ZV9lbmFibGVkIjpmYWxzZSwiVGVycm9yaXN0OlN0YW5kaW5nOmRlZmVuc2l2ZV9mb3JjZV9kZWZlbnNpdmUiOmZhbHNlLCJUZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX3BpdGNoIjoiU3RhdGljIiwiVGVycm9yaXN0OlN0YW5kaW5nOmRlZmVuc2l2ZV9waXRjaF8xIjowLjAsIlRlcnJvcmlzdDpTdGFuZGluZzpkZWZlbnNpdmVfcGl0Y2hfMiI6MC4wLCJUZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX3BpdGNoX29mZnNldCI6MC4wLCJUZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX3JhbmRvbV9jaG9rZSI6ZmFsc2UsIlRlcnJvcmlzdDpTdGFuZGluZzpkZWZlbnNpdmVfcmFuZG9taXphdGlvbiI6MC4wLCJUZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX3lhdyI6IlN0YXRpYyIsIlRlcnJvcmlzdDpTdGFuZGluZzpkZWZlbnNpdmVfeWF3XzEiOjAuMCwiVGVycm9yaXN0OlN0YW5kaW5nOmRlZmVuc2l2ZV95YXdfMiI6MC4wLCJUZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX3lhd19vZmZzZXQiOjE4MC4wLCJUZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX3lhd19zcGVlZCI6MjAuMCwiVGVycm9yaXN0OlN0YW5kaW5nOmRlbGF5XzEiOjEuMCwiVGVycm9yaXN0OlN0YW5kaW5nOmRlbGF5XzIiOjAuMCwiVGVycm9yaXN0OlN0YW5kaW5nOmxlZnRfbGltaXQiOjMwLjAsIlRlcnJvcmlzdDpTdGFuZGluZzptb2RpZmllcl9vZmZzZXQiOi00Ni4wLCJUZXJyb3Jpc3Q6U3RhbmRpbmc6cmlnaHRfbGltaXQiOjMwLjAsIlRlcnJvcmlzdDpTdGFuZGluZzp5YXdfYWRkIjp0cnVlLCJUZXJyb3Jpc3Q6U3RhbmRpbmc6eWF3X2xlZnQiOi0zMC4wLCJUZXJyb3Jpc3Q6U3RhbmRpbmc6eWF3X21vZGlmaWVyIjoiRGlzYWJsZWQiLCJUZXJyb3Jpc3Q6U3RhbmRpbmc6eWF3X29mZnNldCI6MC4wLCJUZXJyb3Jpc3Q6U3RhbmRpbmc6eWF3X3JpZ2h0IjozNC4wLCJUZXJyb3Jpc3Q6V2Fsa2luZzpib2R5X3lhdyI6IkppdHRlciIsIlRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV9jaG9rZV8xIjoxNi4wLCJUZXJyb3Jpc3Q6V2Fsa2luZzpkZWZlbnNpdmVfY2hva2VfMiI6MTYuMCwiVGVycm9yaXN0OldhbGtpbmc6ZGVmZW5zaXZlX2N1c3RvbV9jaG9rZSI6ZmFsc2UsIlRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV9lbmFibGVkIjpmYWxzZSwiVGVycm9yaXN0OldhbGtpbmc6ZGVmZW5zaXZlX2ZvcmNlX2RlZmVuc2l2ZSI6ZmFsc2UsIlRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV9waXRjaCI6IlN0YXRpYyIsIlRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV9waXRjaF8xIjowLjAsIlRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV9waXRjaF8yIjowLjAsIlRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV9waXRjaF9vZmZzZXQiOjAuMCwiVGVycm9yaXN0OldhbGtpbmc6ZGVmZW5zaXZlX3JhbmRvbV9jaG9rZSI6ZmFsc2UsIlRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV9yYW5kb21pemF0aW9uIjowLjAsIlRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV95YXciOiJTdGF0aWMiLCJUZXJyb3Jpc3Q6V2Fsa2luZzpkZWZlbnNpdmVfeWF3XzEiOjAuMCwiVGVycm9yaXN0OldhbGtpbmc6ZGVmZW5zaXZlX3lhd18yIjowLjAsIlRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV95YXdfb2Zmc2V0IjoxODAuMCwiVGVycm9yaXN0OldhbGtpbmc6ZGVmZW5zaXZlX3lhd19zcGVlZCI6MjAuMCwiVGVycm9yaXN0OldhbGtpbmc6ZGVsYXlfMSI6MS4wLCJUZXJyb3Jpc3Q6V2Fsa2luZzpkZWxheV8yIjowLjAsIlRlcnJvcmlzdDpXYWxraW5nOmxlZnRfbGltaXQiOjYwLjAsIlRlcnJvcmlzdDpXYWxraW5nOm1vZGlmaWVyX29mZnNldCI6LTUuMCwiVGVycm9yaXN0OldhbGtpbmc6cmlnaHRfbGltaXQiOjYwLjAsIlRlcnJvcmlzdDpXYWxraW5nOnlhd19hZGQiOnRydWUsIlRlcnJvcmlzdDpXYWxraW5nOnlhd19sZWZ0IjotMzguMCwiVGVycm9yaXN0OldhbGtpbmc6eWF3X21vZGlmaWVyIjoiRGlzYWJsZWQiLCJUZXJyb3Jpc3Q6V2Fsa2luZzp5YXdfb2Zmc2V0IjowLjAsIlRlcnJvcmlzdDpXYWxraW5nOnlhd19yaWdodCI6NDIuMCwiYXZvaWRfYmFja3N0YWIuZW5hYmxlZCI6dHJ1ZSwiZmxpY2tfZXhwbG9pdC5jb25kaXRpb25zIjpbXSwiZmxpY2tfZXhwbG9pdC5lbmFibGVkIjpmYWxzZSwiZnJlZXN0YW5kaW5nLmRpc2FibGVycyI6WyJJbiBBaXIiLCJBaXIgQ3JvdWNoIl0sImZyZWVzdGFuZGluZy5lbmFibGVkIjpmYWxzZSwiZnJlZXN0YW5kaW5nLnN0YXRpYyI6ZmFsc2UsIm1hbnVhbF95YXcuZGlyZWN0aW9uIjoiRGlzYWJsZWQiLCJtYW51YWxfeWF3LmRpc2FibGVycyI6W10sIm1hbnVhbF95YXcuc3RhdGljIjpmYWxzZSwibW9kaWZ5X29uX3dhcm11cC5lbmFibGVkIjpmYWxzZSwib25fdXNlLmVuYWJsZWQiOnRydWUsInNhZmVfaGVhZC5jb25kaXRpb25zIjpbIlN0YW5kaW5nIiwiQ3JvdWNoIiwiQWlyIENyb3VjaCIsIkFpciBLbmlmZSIsIkFpciBUYXNlciIsIkRpc3RhbmNlIl0sInNhZmVfaGVhZC5lbmFibGVkIjp0cnVlfSwiTWlzY2VsbGFuZW91cyI6eyJhdm9pZF9jb2xsaXNpb25zLmVuYWJsZWQiOmZhbHNlLCJjbGFudGFnLmVuYWJsZWQiOmZhbHNlLCJjb2xsaXNpb25fYWlyX2R1Y2suZW5hYmxlZCI6ZmFsc2UsImVkZ2Vfc3RvcC5lbmFibGVkIjpmYWxzZSwiZmFzdF9sYWRkZXIuZW5hYmxlZCI6dHJ1ZSwibm9fZmFsbF9kYW1hZ2UuZW5hYmxlZCI6dHJ1ZSwic3VwZXJfdG9zcy5lbmFibGVkIjp0cnVlLCJ0cmFzaHRhbGsuZGVsYXkiOjMwLjAsInRyYXNodGFsay5lbmFibGVkIjpmYWxzZSwidW5sb2NrX2ZkX3NwZWVkLmVuYWJsZWQiOnRydWV9LCJWaXN1YWxzIjp7ImFuaW1hdGlvbnMuZWFydGhxdWFrZSI6ZmFsc2UsImFuaW1hdGlvbnMuZW5hYmxlZCI6ZmFsc2UsImFuaW1hdGlvbnMuaW5fYWlyIjoiRGlzYWJsZWQiLCJhbmltYXRpb25zLm1vdmVfbGVhbiI6MC4wLCJhbmltYXRpb25zLm9uX2dyb3VuZCI6IkRpc2FibGVkIiwiYW5pbWF0aW9ucy5waXRjaF9vbl9sYW5kIjpmYWxzZSwiYW5pbWF0aW9ucy5zbGlkaW5nX2Nyb3VjaCI6ZmFsc2UsImFuaW1hdGlvbnMuc2xpZGluZ19zbG93d2FsayI6ZmFsc2UsImFzcGVjdF9yYXRpby5lbmFibGVkIjpmYWxzZSwiYXNwZWN0X3JhdGlvLnByb3BvcnRpb24iOjAuMCwiY29uc29sZV9jb2xvci5jb2xvciI6IjgwODA4MDlFIiwiY29uc29sZV9jb2xvci5lbmFibGVkIjp0cnVlLCJjcm9zc2hhaXJfaW5kaWNhdG9ycy5jb2xvciI6IkZGQjc0RkZGIiwiY3Jvc3NoYWlyX2luZGljYXRvcnMuZW5hYmxlZCI6dHJ1ZSwiY3Jvc3NoYWlyX2luZGljYXRvcnMub2Zmc2V0Ijo0MC4wLCJkYW1hZ2VfaW5kaWNhdG9yLmNvbG9yIjoiRkZGRkZGRkYiLCJkYW1hZ2VfaW5kaWNhdG9yLmVuYWJsZWQiOnRydWUsImRhbWFnZV9pbmRpY2F0b3IuZm9udCI6IlNtYWxsIiwiaGl0X21hcmtlci5jb2xvciI6IjAwMDAwMEZGIiwiaGl0X21hcmtlci5lbmFibGVkIjp0cnVlLCJoaXRfbWFya2VyLnNpemUiOjQuMCwiaGl0X21hcmtlci50aGlja25lc3MiOjIuMCwia2VlcF90cmFuc3BhcmVuY3kuZW5hYmxlZCI6dHJ1ZSwibGFnX2NvbXBfYm94LmNvbG9yIjoiMkY3NURERkYiLCJsYWdfY29tcF9ib3guZW5hYmxlZCI6dHJ1ZSwibWFudWFsX2Fycm93cy5jb2xvciI6IkZGRkZGRkZGIiwibWFudWFsX2Fycm93cy5lbmFibGVkIjp0cnVlLCJtYW51YWxfYXJyb3dzLm9mZnNldCI6NDAuMCwibmFkZV9yYWRpdXMuZW5hYmxlZCI6dHJ1ZSwibmFkZV9yYWRpdXMubW9sb3RvdiI6dHJ1ZSwibmFkZV9yYWRpdXMubW9sb3Rvdl9jb2xvciI6IkQ4OTg2MEZGIiwibmFkZV9yYWRpdXMuc21va2UiOnRydWUsIm5hZGVfcmFkaXVzLnNtb2tlX2NvbG9yIjoiODY5NEM0RkYiLCJyZW1vdmVfZm9vdHN0ZXBzX3NoYWRvdy5lbmFibGVkIjp0cnVlLCJzY29wZV9vdmVybGF5LmFkZGl0aW9ucyI6W10sInNjb3BlX292ZXJsYXkuY29sb3IiOiJGRkZGRkY5RSIsInNjb3BlX292ZXJsYXkuZW5hYmxlZCI6dHJ1ZSwic2NvcGVfb3ZlcmxheS5leGNsdWRlX2xpbmVzIjpbXSwic2NvcGVfb3ZlcmxheS5nYXAiOjAuMCwic2NvcGVfb3ZlcmxheS5zaXplIjo1NS4wLCJza2VldF9pbmRpY2F0b3JzLmVuYWJsZWQiOnRydWUsInNrZWV0X2luZGljYXRvcnMuaXRlbXMiOlsxLjAsMi4wLDMuMCw0LjAsNS4wLDYuMCw3LjAsOC4wLDkuMCwxMC4wLDExLjBdLCJ2ZWxvY2l0eV93YXJuaW5nLmNvbG9yIjoiRkZCNzRGRkYiLCJ2ZWxvY2l0eV93YXJuaW5nLmVuYWJsZWQiOnRydWUsInZlbG9jaXR5X3dhcm5pbmcub2Zmc2V0IjoxNjAuMCwidmlld21vZGVsLmVuYWJsZWQiOmZhbHNlLCJ2aWV3bW9kZWwuZm92Ijo2ODAuMCwidmlld21vZGVsLm9mZnNldF94IjoyNS4wLCJ2aWV3bW9kZWwub2Zmc2V0X3kiOjAuMCwidmlld21vZGVsLm9mZnNldF96IjotMTUuMH19");
            add_builtin("Desync", concat("\a{Link Active}", icons.get("circle-info"), "\aDEFAULT", "  This configuration is based on the default NeverLose anti-aim, with no exploit or tickrate tweaks."), "social::nl::eyJBaW1ib3QiOnsiYWlfcGVlay5jb2xvciI6IkZGRkZGRkZGIiwiYWlfcGVlay5kb3RzIjo0LjAsImFpX3BlZWsuZW5hYmxlZCI6ZmFsc2UsImFpX3BlZWsuaGl0Ym94ZXMiOlsiSGVhZCIsIkNoZXN0IiwiU3RvbWFjaCIsIkFybXMiLCJMZWdzIiwiRmVldCJdLCJhaV9wZWVrLnJhZGl1cyI6MzIuMCwiYWlfcGVlay53ZWFwb25zIjpbIlNTRyAwOCIsIlI4IFJldm9sdmVyIiwiRGVzZXJ0IEVhZ2xlIiwiUGlzdG9sIiwiUmlmbGUiLCJTaG90Z3VuIl0sImRvcm1hbnRfYWltYm90LmFjY3VyYWN5Ijo2MC4wLCJkb3JtYW50X2FpbWJvdC5lbmFibGVkIjpmYWxzZSwiZG9ybWFudF9haW1ib3QuaGl0Ym94ZXMiOlsiSGVhZCIsIkNoZXN0IiwiU3RvbWFjaCIsIkxlZ3MiXSwiZG9ybWFudF9haW1ib3QubWluX2RhbWFnZSI6MTAuMCwiZmFrZV9sYXRlbmN5LmVuYWJsZWQiOmZhbHNlLCJsb2dfZXZlbnRzLmNvbG9yX2hpdCI6IkMzQ0FGRkZGIiwibG9nX2V2ZW50cy5jb2xvcl9taXNzIjoiRkY5MjkyRkYiLCJsb2dfZXZlbnRzLmVuYWJsZWQiOnRydWUsImxvZ19ldmVudHMub3V0cHV0IjpbIkNvbnNvbGUiLCJEZWJ1ZyIsIk5vdGlmeSJdLCJtYXh1c3JjbWRwcm9jZXNzdGlja3MuZW5hYmxlZCI6ZmFsc2UsIm1heHVzcmNtZHByb2Nlc3N0aWNrcy50aWNrcyI6MTYuMH0sIkFudGktQWltIjp7IkNvdW50ZXItVGVycm9yaXN0OkFpciBDcm91Y2g6Ym9keV95YXciOiJKaXR0ZXIiLCJDb3VudGVyLVRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlZmVuc2l2ZV9jaG9rZV8xIjoxNi4wLCJDb3VudGVyLVRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlZmVuc2l2ZV9jaG9rZV8yIjoxNi4wLCJDb3VudGVyLVRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlZmVuc2l2ZV9jdXN0b21fY2hva2UiOmZhbHNlLCJDb3VudGVyLVRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlZmVuc2l2ZV9lbmFibGVkIjpmYWxzZSwiQ291bnRlci1UZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfZm9yY2VfZGVmZW5zaXZlIjpmYWxzZSwiQ291bnRlci1UZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfcGl0Y2giOiJTdGF0aWMiLCJDb3VudGVyLVRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlZmVuc2l2ZV9waXRjaF8xIjowLjAsIkNvdW50ZXItVGVycm9yaXN0OkFpciBDcm91Y2g6ZGVmZW5zaXZlX3BpdGNoXzIiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfcGl0Y2hfb2Zmc2V0IjowLjAsIkNvdW50ZXItVGVycm9yaXN0OkFpciBDcm91Y2g6ZGVmZW5zaXZlX3JhbmRvbV9jaG9rZSI6ZmFsc2UsIkNvdW50ZXItVGVycm9yaXN0OkFpciBDcm91Y2g6ZGVmZW5zaXZlX3JhbmRvbWl6YXRpb24iOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfeWF3IjoiU3RhdGljIiwiQ291bnRlci1UZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfeWF3XzEiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfeWF3XzIiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfeWF3X29mZnNldCI6MTgwLjAsIkNvdW50ZXItVGVycm9yaXN0OkFpciBDcm91Y2g6ZGVmZW5zaXZlX3lhd19zcGVlZCI6MjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWxheV8xIjowLjAsIkNvdW50ZXItVGVycm9yaXN0OkFpciBDcm91Y2g6ZGVsYXlfMiI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpBaXIgQ3JvdWNoOmxlZnRfbGltaXQiOjU4LjAsIkNvdW50ZXItVGVycm9yaXN0OkFpciBDcm91Y2g6bW9kaWZpZXJfb2Zmc2V0IjotNDYuMCwiQ291bnRlci1UZXJyb3Jpc3Q6QWlyIENyb3VjaDpyaWdodF9saW1pdCI6NTguMCwiQ291bnRlci1UZXJyb3Jpc3Q6QWlyIENyb3VjaDp5YXdfYWRkIjp0cnVlLCJDb3VudGVyLVRlcnJvcmlzdDpBaXIgQ3JvdWNoOnlhd19sZWZ0IjotOC4wLCJDb3VudGVyLVRlcnJvcmlzdDpBaXIgQ3JvdWNoOnlhd19tb2RpZmllciI6IkNlbnRlciIsIkNvdW50ZXItVGVycm9yaXN0OkFpciBDcm91Y2g6eWF3X29mZnNldCI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpBaXIgQ3JvdWNoOnlhd19yaWdodCI6MTQuMCwiQ291bnRlci1UZXJyb3Jpc3Q6Q3JvdWNoaW5nOmJvZHlfeWF3IjoiSml0dGVyIiwiQ291bnRlci1UZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlZmVuc2l2ZV9jaG9rZV8xIjoxNi4wLCJDb3VudGVyLVRlcnJvcmlzdDpDcm91Y2hpbmc6ZGVmZW5zaXZlX2Nob2tlXzIiOjE2LjAsIkNvdW50ZXItVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfY3VzdG9tX2Nob2tlIjpmYWxzZSwiQ291bnRlci1UZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlZmVuc2l2ZV9lbmFibGVkIjpmYWxzZSwiQ291bnRlci1UZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlZmVuc2l2ZV9mb3JjZV9kZWZlbnNpdmUiOmZhbHNlLCJDb3VudGVyLVRlcnJvcmlzdDpDcm91Y2hpbmc6ZGVmZW5zaXZlX3BpdGNoIjoiU3RhdGljIiwiQ291bnRlci1UZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlZmVuc2l2ZV9waXRjaF8xIjowLjAsIkNvdW50ZXItVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfcGl0Y2hfMiI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpDcm91Y2hpbmc6ZGVmZW5zaXZlX3BpdGNoX29mZnNldCI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpDcm91Y2hpbmc6ZGVmZW5zaXZlX3JhbmRvbV9jaG9rZSI6ZmFsc2UsIkNvdW50ZXItVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfcmFuZG9taXphdGlvbiI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpDcm91Y2hpbmc6ZGVmZW5zaXZlX3lhdyI6IlN0YXRpYyIsIkNvdW50ZXItVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfeWF3XzEiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlZmVuc2l2ZV95YXdfMiI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpDcm91Y2hpbmc6ZGVmZW5zaXZlX3lhd19vZmZzZXQiOjE4MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpDcm91Y2hpbmc6ZGVmZW5zaXZlX3lhd19zcGVlZCI6MjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlbGF5XzEiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlbGF5XzIiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6Q3JvdWNoaW5nOmxlZnRfbGltaXQiOjU4LjAsIkNvdW50ZXItVGVycm9yaXN0OkNyb3VjaGluZzptb2RpZmllcl9vZmZzZXQiOi0zNS4wLCJDb3VudGVyLVRlcnJvcmlzdDpDcm91Y2hpbmc6cmlnaHRfbGltaXQiOjU4LjAsIkNvdW50ZXItVGVycm9yaXN0OkNyb3VjaGluZzp5YXdfYWRkIjp0cnVlLCJDb3VudGVyLVRlcnJvcmlzdDpDcm91Y2hpbmc6eWF3X2xlZnQiOi0xMC4wLCJDb3VudGVyLVRlcnJvcmlzdDpDcm91Y2hpbmc6eWF3X21vZGlmaWVyIjoiQ2VudGVyIiwiQ291bnRlci1UZXJyb3Jpc3Q6Q3JvdWNoaW5nOnlhd19vZmZzZXQiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6Q3JvdWNoaW5nOnlhd19yaWdodCI6MTYuMCwiQ291bnRlci1UZXJyb3Jpc3Q6SW4gQWlyOmJvZHlfeWF3IjoiSml0dGVyIiwiQ291bnRlci1UZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV9jaG9rZV8xIjoxNi4wLCJDb3VudGVyLVRlcnJvcmlzdDpJbiBBaXI6ZGVmZW5zaXZlX2Nob2tlXzIiOjE2LjAsIkNvdW50ZXItVGVycm9yaXN0OkluIEFpcjpkZWZlbnNpdmVfY3VzdG9tX2Nob2tlIjpmYWxzZSwiQ291bnRlci1UZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV9lbmFibGVkIjpmYWxzZSwiQ291bnRlci1UZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV9mb3JjZV9kZWZlbnNpdmUiOmZhbHNlLCJDb3VudGVyLVRlcnJvcmlzdDpJbiBBaXI6ZGVmZW5zaXZlX3BpdGNoIjoiU3RhdGljIiwiQ291bnRlci1UZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV9waXRjaF8xIjowLjAsIkNvdW50ZXItVGVycm9yaXN0OkluIEFpcjpkZWZlbnNpdmVfcGl0Y2hfMiI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpJbiBBaXI6ZGVmZW5zaXZlX3BpdGNoX29mZnNldCI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpJbiBBaXI6ZGVmZW5zaXZlX3JhbmRvbV9jaG9rZSI6ZmFsc2UsIkNvdW50ZXItVGVycm9yaXN0OkluIEFpcjpkZWZlbnNpdmVfcmFuZG9taXphdGlvbiI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpJbiBBaXI6ZGVmZW5zaXZlX3lhdyI6IlN0YXRpYyIsIkNvdW50ZXItVGVycm9yaXN0OkluIEFpcjpkZWZlbnNpdmVfeWF3XzEiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV95YXdfMiI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpJbiBBaXI6ZGVmZW5zaXZlX3lhd19vZmZzZXQiOjE4MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpJbiBBaXI6ZGVmZW5zaXZlX3lhd19zcGVlZCI6MjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6SW4gQWlyOmRlbGF5XzEiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6SW4gQWlyOmRlbGF5XzIiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6SW4gQWlyOmxlZnRfbGltaXQiOjU4LjAsIkNvdW50ZXItVGVycm9yaXN0OkluIEFpcjptb2RpZmllcl9vZmZzZXQiOi00Ny4wLCJDb3VudGVyLVRlcnJvcmlzdDpJbiBBaXI6cmlnaHRfbGltaXQiOjU4LjAsIkNvdW50ZXItVGVycm9yaXN0OkluIEFpcjp5YXdfYWRkIjp0cnVlLCJDb3VudGVyLVRlcnJvcmlzdDpJbiBBaXI6eWF3X2xlZnQiOi0zLjAsIkNvdW50ZXItVGVycm9yaXN0OkluIEFpcjp5YXdfbW9kaWZpZXIiOiJDZW50ZXIiLCJDb3VudGVyLVRlcnJvcmlzdDpJbiBBaXI6eWF3X29mZnNldCI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpJbiBBaXI6eWF3X3JpZ2h0IjoxNi4wLCJDb3VudGVyLVRlcnJvcmlzdDpSdW5uaW5nOmJvZHlfeWF3IjoiSml0dGVyIiwiQ291bnRlci1UZXJyb3Jpc3Q6UnVubmluZzpkZWZlbnNpdmVfY2hva2VfMSI6MTYuMCwiQ291bnRlci1UZXJyb3Jpc3Q6UnVubmluZzpkZWZlbnNpdmVfY2hva2VfMiI6MTYuMCwiQ291bnRlci1UZXJyb3Jpc3Q6UnVubmluZzpkZWZlbnNpdmVfY3VzdG9tX2Nob2tlIjpmYWxzZSwiQ291bnRlci1UZXJyb3Jpc3Q6UnVubmluZzpkZWZlbnNpdmVfZW5hYmxlZCI6ZmFsc2UsIkNvdW50ZXItVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX2ZvcmNlX2RlZmVuc2l2ZSI6ZmFsc2UsIkNvdW50ZXItVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX3BpdGNoIjoiU3RhdGljIiwiQ291bnRlci1UZXJyb3Jpc3Q6UnVubmluZzpkZWZlbnNpdmVfcGl0Y2hfMSI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpSdW5uaW5nOmRlZmVuc2l2ZV9waXRjaF8yIjowLjAsIkNvdW50ZXItVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX3BpdGNoX29mZnNldCI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpSdW5uaW5nOmRlZmVuc2l2ZV9yYW5kb21fY2hva2UiOmZhbHNlLCJDb3VudGVyLVRlcnJvcmlzdDpSdW5uaW5nOmRlZmVuc2l2ZV9yYW5kb21pemF0aW9uIjowLjAsIkNvdW50ZXItVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX3lhdyI6IlN0YXRpYyIsIkNvdW50ZXItVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX3lhd18xIjowLjAsIkNvdW50ZXItVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX3lhd18yIjowLjAsIkNvdW50ZXItVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX3lhd19vZmZzZXQiOjE4MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpSdW5uaW5nOmRlZmVuc2l2ZV95YXdfc3BlZWQiOjIwLjAsIkNvdW50ZXItVGVycm9yaXN0OlJ1bm5pbmc6ZGVsYXlfMSI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpSdW5uaW5nOmRlbGF5XzIiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6UnVubmluZzpsZWZ0X2xpbWl0IjozNi4wLCJDb3VudGVyLVRlcnJvcmlzdDpSdW5uaW5nOm1vZGlmaWVyX29mZnNldCI6LTUyLjAsIkNvdW50ZXItVGVycm9yaXN0OlJ1bm5pbmc6cmlnaHRfbGltaXQiOjM2LjAsIkNvdW50ZXItVGVycm9yaXN0OlJ1bm5pbmc6eWF3X2FkZCI6dHJ1ZSwiQ291bnRlci1UZXJyb3Jpc3Q6UnVubmluZzp5YXdfbGVmdCI6LTYuMCwiQ291bnRlci1UZXJyb3Jpc3Q6UnVubmluZzp5YXdfbW9kaWZpZXIiOiJDZW50ZXIiLCJDb3VudGVyLVRlcnJvcmlzdDpSdW5uaW5nOnlhd19vZmZzZXQiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6UnVubmluZzp5YXdfcmlnaHQiOjExLjAsIkNvdW50ZXItVGVycm9yaXN0OlNuZWFraW5nOmJvZHlfeWF3IjoiSml0dGVyIiwiQ291bnRlci1UZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX2Nob2tlXzEiOjE2LjAsIkNvdW50ZXItVGVycm9yaXN0OlNuZWFraW5nOmRlZmVuc2l2ZV9jaG9rZV8yIjoxNi4wLCJDb3VudGVyLVRlcnJvcmlzdDpTbmVha2luZzpkZWZlbnNpdmVfY3VzdG9tX2Nob2tlIjpmYWxzZSwiQ291bnRlci1UZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX2VuYWJsZWQiOmZhbHNlLCJDb3VudGVyLVRlcnJvcmlzdDpTbmVha2luZzpkZWZlbnNpdmVfZm9yY2VfZGVmZW5zaXZlIjpmYWxzZSwiQ291bnRlci1UZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX3BpdGNoIjoiU3RhdGljIiwiQ291bnRlci1UZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX3BpdGNoXzEiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX3BpdGNoXzIiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX3BpdGNoX29mZnNldCI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpTbmVha2luZzpkZWZlbnNpdmVfcmFuZG9tX2Nob2tlIjpmYWxzZSwiQ291bnRlci1UZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX3JhbmRvbWl6YXRpb24iOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX3lhdyI6IlN0YXRpYyIsIkNvdW50ZXItVGVycm9yaXN0OlNuZWFraW5nOmRlZmVuc2l2ZV95YXdfMSI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpTbmVha2luZzpkZWZlbnNpdmVfeWF3XzIiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX3lhd19vZmZzZXQiOjE4MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpTbmVha2luZzpkZWZlbnNpdmVfeWF3X3NwZWVkIjoyMC4wLCJDb3VudGVyLVRlcnJvcmlzdDpTbmVha2luZzpkZWxheV8xIjowLjAsIkNvdW50ZXItVGVycm9yaXN0OlNuZWFraW5nOmRlbGF5XzIiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U25lYWtpbmc6bGVmdF9saW1pdCI6NTguMCwiQ291bnRlci1UZXJyb3Jpc3Q6U25lYWtpbmc6bW9kaWZpZXJfb2Zmc2V0IjotMzUuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U25lYWtpbmc6cmlnaHRfbGltaXQiOjU4LjAsIkNvdW50ZXItVGVycm9yaXN0OlNuZWFraW5nOnlhd19hZGQiOnRydWUsIkNvdW50ZXItVGVycm9yaXN0OlNuZWFraW5nOnlhd19sZWZ0IjotMTAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U25lYWtpbmc6eWF3X21vZGlmaWVyIjoiQ2VudGVyIiwiQ291bnRlci1UZXJyb3Jpc3Q6U25lYWtpbmc6eWF3X29mZnNldCI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpTbmVha2luZzp5YXdfcmlnaHQiOjE2LjAsIkNvdW50ZXItVGVycm9yaXN0OlN0YW5kaW5nOmJvZHlfeWF3IjoiSml0dGVyIiwiQ291bnRlci1UZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX2Nob2tlXzEiOjE2LjAsIkNvdW50ZXItVGVycm9yaXN0OlN0YW5kaW5nOmRlZmVuc2l2ZV9jaG9rZV8yIjoxNi4wLCJDb3VudGVyLVRlcnJvcmlzdDpTdGFuZGluZzpkZWZlbnNpdmVfY3VzdG9tX2Nob2tlIjpmYWxzZSwiQ291bnRlci1UZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX2VuYWJsZWQiOmZhbHNlLCJDb3VudGVyLVRlcnJvcmlzdDpTdGFuZGluZzpkZWZlbnNpdmVfZm9yY2VfZGVmZW5zaXZlIjpmYWxzZSwiQ291bnRlci1UZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX3BpdGNoIjoiU3RhdGljIiwiQ291bnRlci1UZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX3BpdGNoXzEiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX3BpdGNoXzIiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX3BpdGNoX29mZnNldCI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpTdGFuZGluZzpkZWZlbnNpdmVfcmFuZG9tX2Nob2tlIjpmYWxzZSwiQ291bnRlci1UZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX3JhbmRvbWl6YXRpb24iOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX3lhdyI6IlN0YXRpYyIsIkNvdW50ZXItVGVycm9yaXN0OlN0YW5kaW5nOmRlZmVuc2l2ZV95YXdfMSI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpTdGFuZGluZzpkZWZlbnNpdmVfeWF3XzIiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX3lhd19vZmZzZXQiOjE4MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpTdGFuZGluZzpkZWZlbnNpdmVfeWF3X3NwZWVkIjoyMC4wLCJDb3VudGVyLVRlcnJvcmlzdDpTdGFuZGluZzpkZWxheV8xIjowLjAsIkNvdW50ZXItVGVycm9yaXN0OlN0YW5kaW5nOmRlbGF5XzIiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U3RhbmRpbmc6bGVmdF9saW1pdCI6MzAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U3RhbmRpbmc6bW9kaWZpZXJfb2Zmc2V0IjotNDYuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U3RhbmRpbmc6cmlnaHRfbGltaXQiOjMwLjAsIkNvdW50ZXItVGVycm9yaXN0OlN0YW5kaW5nOnlhd19hZGQiOnRydWUsIkNvdW50ZXItVGVycm9yaXN0OlN0YW5kaW5nOnlhd19sZWZ0IjotNy4wLCJDb3VudGVyLVRlcnJvcmlzdDpTdGFuZGluZzp5YXdfbW9kaWZpZXIiOiJDZW50ZXIiLCJDb3VudGVyLVRlcnJvcmlzdDpTdGFuZGluZzp5YXdfb2Zmc2V0IjowLjAsIkNvdW50ZXItVGVycm9yaXN0OlN0YW5kaW5nOnlhd19yaWdodCI6MTEuMCwiQ291bnRlci1UZXJyb3Jpc3Q6V2Fsa2luZzpib2R5X3lhdyI6IkppdHRlciIsIkNvdW50ZXItVGVycm9yaXN0OldhbGtpbmc6ZGVmZW5zaXZlX2Nob2tlXzEiOjE2LjAsIkNvdW50ZXItVGVycm9yaXN0OldhbGtpbmc6ZGVmZW5zaXZlX2Nob2tlXzIiOjE2LjAsIkNvdW50ZXItVGVycm9yaXN0OldhbGtpbmc6ZGVmZW5zaXZlX2N1c3RvbV9jaG9rZSI6ZmFsc2UsIkNvdW50ZXItVGVycm9yaXN0OldhbGtpbmc6ZGVmZW5zaXZlX2VuYWJsZWQiOmZhbHNlLCJDb3VudGVyLVRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV9mb3JjZV9kZWZlbnNpdmUiOmZhbHNlLCJDb3VudGVyLVRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV9waXRjaCI6IlN0YXRpYyIsIkNvdW50ZXItVGVycm9yaXN0OldhbGtpbmc6ZGVmZW5zaXZlX3BpdGNoXzEiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6V2Fsa2luZzpkZWZlbnNpdmVfcGl0Y2hfMiI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV9waXRjaF9vZmZzZXQiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6V2Fsa2luZzpkZWZlbnNpdmVfcmFuZG9tX2Nob2tlIjpmYWxzZSwiQ291bnRlci1UZXJyb3Jpc3Q6V2Fsa2luZzpkZWZlbnNpdmVfcmFuZG9taXphdGlvbiI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV95YXciOiJTdGF0aWMiLCJDb3VudGVyLVRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV95YXdfMSI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV95YXdfMiI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV95YXdfb2Zmc2V0IjoxODAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6V2Fsa2luZzpkZWZlbnNpdmVfeWF3X3NwZWVkIjoyMC4wLCJDb3VudGVyLVRlcnJvcmlzdDpXYWxraW5nOmRlbGF5XzEiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6V2Fsa2luZzpkZWxheV8yIjowLjAsIkNvdW50ZXItVGVycm9yaXN0OldhbGtpbmc6bGVmdF9saW1pdCI6NDUuMCwiQ291bnRlci1UZXJyb3Jpc3Q6V2Fsa2luZzptb2RpZmllcl9vZmZzZXQiOi01LjAsIkNvdW50ZXItVGVycm9yaXN0OldhbGtpbmc6cmlnaHRfbGltaXQiOjQ1LjAsIkNvdW50ZXItVGVycm9yaXN0OldhbGtpbmc6eWF3X2FkZCI6dHJ1ZSwiQ291bnRlci1UZXJyb3Jpc3Q6V2Fsa2luZzp5YXdfbGVmdCI6LTIzLjAsIkNvdW50ZXItVGVycm9yaXN0OldhbGtpbmc6eWF3X21vZGlmaWVyIjoiU3BpbiIsIkNvdW50ZXItVGVycm9yaXN0OldhbGtpbmc6eWF3X29mZnNldCI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpXYWxraW5nOnlhd19yaWdodCI6NDcuMCwiVGVycm9yaXN0OkFpciBDcm91Y2g6Ym9keV95YXciOiJKaXR0ZXIiLCJUZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfY2hva2VfMSI6MTYuMCwiVGVycm9yaXN0OkFpciBDcm91Y2g6ZGVmZW5zaXZlX2Nob2tlXzIiOjE2LjAsIlRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlZmVuc2l2ZV9jdXN0b21fY2hva2UiOmZhbHNlLCJUZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfZW5hYmxlZCI6ZmFsc2UsIlRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlZmVuc2l2ZV9mb3JjZV9kZWZlbnNpdmUiOmZhbHNlLCJUZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfcGl0Y2giOiJTdGF0aWMiLCJUZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfcGl0Y2hfMSI6MC4wLCJUZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfcGl0Y2hfMiI6MC4wLCJUZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfcGl0Y2hfb2Zmc2V0IjowLjAsIlRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlZmVuc2l2ZV9yYW5kb21fY2hva2UiOmZhbHNlLCJUZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfcmFuZG9taXphdGlvbiI6MC4wLCJUZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfeWF3IjoiU3RhdGljIiwiVGVycm9yaXN0OkFpciBDcm91Y2g6ZGVmZW5zaXZlX3lhd18xIjowLjAsIlRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlZmVuc2l2ZV95YXdfMiI6MC4wLCJUZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfeWF3X29mZnNldCI6MTgwLjAsIlRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlZmVuc2l2ZV95YXdfc3BlZWQiOjIwLjAsIlRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlbGF5XzEiOjAuMCwiVGVycm9yaXN0OkFpciBDcm91Y2g6ZGVsYXlfMiI6MC4wLCJUZXJyb3Jpc3Q6QWlyIENyb3VjaDpsZWZ0X2xpbWl0Ijo1OC4wLCJUZXJyb3Jpc3Q6QWlyIENyb3VjaDptb2RpZmllcl9vZmZzZXQiOi00Ni4wLCJUZXJyb3Jpc3Q6QWlyIENyb3VjaDpyaWdodF9saW1pdCI6NTguMCwiVGVycm9yaXN0OkFpciBDcm91Y2g6eWF3X2FkZCI6dHJ1ZSwiVGVycm9yaXN0OkFpciBDcm91Y2g6eWF3X2xlZnQiOi04LjAsIlRlcnJvcmlzdDpBaXIgQ3JvdWNoOnlhd19tb2RpZmllciI6IkNlbnRlciIsIlRlcnJvcmlzdDpBaXIgQ3JvdWNoOnlhd19vZmZzZXQiOjAuMCwiVGVycm9yaXN0OkFpciBDcm91Y2g6eWF3X3JpZ2h0IjoxNC4wLCJUZXJyb3Jpc3Q6Q3JvdWNoaW5nOmJvZHlfeWF3IjoiSml0dGVyIiwiVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfY2hva2VfMSI6MTYuMCwiVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfY2hva2VfMiI6MTYuMCwiVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfY3VzdG9tX2Nob2tlIjpmYWxzZSwiVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfZW5hYmxlZCI6ZmFsc2UsIlRlcnJvcmlzdDpDcm91Y2hpbmc6ZGVmZW5zaXZlX2ZvcmNlX2RlZmVuc2l2ZSI6ZmFsc2UsIlRlcnJvcmlzdDpDcm91Y2hpbmc6ZGVmZW5zaXZlX3BpdGNoIjoiU3RhdGljIiwiVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfcGl0Y2hfMSI6MC4wLCJUZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlZmVuc2l2ZV9waXRjaF8yIjowLjAsIlRlcnJvcmlzdDpDcm91Y2hpbmc6ZGVmZW5zaXZlX3BpdGNoX29mZnNldCI6MC4wLCJUZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlZmVuc2l2ZV9yYW5kb21fY2hva2UiOmZhbHNlLCJUZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlZmVuc2l2ZV9yYW5kb21pemF0aW9uIjowLjAsIlRlcnJvcmlzdDpDcm91Y2hpbmc6ZGVmZW5zaXZlX3lhdyI6IlN0YXRpYyIsIlRlcnJvcmlzdDpDcm91Y2hpbmc6ZGVmZW5zaXZlX3lhd18xIjowLjAsIlRlcnJvcmlzdDpDcm91Y2hpbmc6ZGVmZW5zaXZlX3lhd18yIjowLjAsIlRlcnJvcmlzdDpDcm91Y2hpbmc6ZGVmZW5zaXZlX3lhd19vZmZzZXQiOjE4MC4wLCJUZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlZmVuc2l2ZV95YXdfc3BlZWQiOjIwLjAsIlRlcnJvcmlzdDpDcm91Y2hpbmc6ZGVsYXlfMSI6MC4wLCJUZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlbGF5XzIiOjAuMCwiVGVycm9yaXN0OkNyb3VjaGluZzpsZWZ0X2xpbWl0Ijo1OC4wLCJUZXJyb3Jpc3Q6Q3JvdWNoaW5nOm1vZGlmaWVyX29mZnNldCI6LTM1LjAsIlRlcnJvcmlzdDpDcm91Y2hpbmc6cmlnaHRfbGltaXQiOjU4LjAsIlRlcnJvcmlzdDpDcm91Y2hpbmc6eWF3X2FkZCI6dHJ1ZSwiVGVycm9yaXN0OkNyb3VjaGluZzp5YXdfbGVmdCI6LTEwLjAsIlRlcnJvcmlzdDpDcm91Y2hpbmc6eWF3X21vZGlmaWVyIjoiQ2VudGVyIiwiVGVycm9yaXN0OkNyb3VjaGluZzp5YXdfb2Zmc2V0IjowLjAsIlRlcnJvcmlzdDpDcm91Y2hpbmc6eWF3X3JpZ2h0IjoxNi4wLCJUZXJyb3Jpc3Q6SW4gQWlyOmJvZHlfeWF3IjoiSml0dGVyIiwiVGVycm9yaXN0OkluIEFpcjpkZWZlbnNpdmVfY2hva2VfMSI6MTYuMCwiVGVycm9yaXN0OkluIEFpcjpkZWZlbnNpdmVfY2hva2VfMiI6MTYuMCwiVGVycm9yaXN0OkluIEFpcjpkZWZlbnNpdmVfY3VzdG9tX2Nob2tlIjpmYWxzZSwiVGVycm9yaXN0OkluIEFpcjpkZWZlbnNpdmVfZW5hYmxlZCI6ZmFsc2UsIlRlcnJvcmlzdDpJbiBBaXI6ZGVmZW5zaXZlX2ZvcmNlX2RlZmVuc2l2ZSI6ZmFsc2UsIlRlcnJvcmlzdDpJbiBBaXI6ZGVmZW5zaXZlX3BpdGNoIjoiU3RhdGljIiwiVGVycm9yaXN0OkluIEFpcjpkZWZlbnNpdmVfcGl0Y2hfMSI6MC4wLCJUZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV9waXRjaF8yIjowLjAsIlRlcnJvcmlzdDpJbiBBaXI6ZGVmZW5zaXZlX3BpdGNoX29mZnNldCI6MC4wLCJUZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV9yYW5kb21fY2hva2UiOmZhbHNlLCJUZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV9yYW5kb21pemF0aW9uIjowLjAsIlRlcnJvcmlzdDpJbiBBaXI6ZGVmZW5zaXZlX3lhdyI6IlN0YXRpYyIsIlRlcnJvcmlzdDpJbiBBaXI6ZGVmZW5zaXZlX3lhd18xIjowLjAsIlRlcnJvcmlzdDpJbiBBaXI6ZGVmZW5zaXZlX3lhd18yIjowLjAsIlRlcnJvcmlzdDpJbiBBaXI6ZGVmZW5zaXZlX3lhd19vZmZzZXQiOjE4MC4wLCJUZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV95YXdfc3BlZWQiOjIwLjAsIlRlcnJvcmlzdDpJbiBBaXI6ZGVsYXlfMSI6MC4wLCJUZXJyb3Jpc3Q6SW4gQWlyOmRlbGF5XzIiOjAuMCwiVGVycm9yaXN0OkluIEFpcjpsZWZ0X2xpbWl0Ijo1OC4wLCJUZXJyb3Jpc3Q6SW4gQWlyOm1vZGlmaWVyX29mZnNldCI6LTQ3LjAsIlRlcnJvcmlzdDpJbiBBaXI6cmlnaHRfbGltaXQiOjU4LjAsIlRlcnJvcmlzdDpJbiBBaXI6eWF3X2FkZCI6dHJ1ZSwiVGVycm9yaXN0OkluIEFpcjp5YXdfbGVmdCI6LTMuMCwiVGVycm9yaXN0OkluIEFpcjp5YXdfbW9kaWZpZXIiOiJDZW50ZXIiLCJUZXJyb3Jpc3Q6SW4gQWlyOnlhd19vZmZzZXQiOjAuMCwiVGVycm9yaXN0OkluIEFpcjp5YXdfcmlnaHQiOjE2LjAsIlRlcnJvcmlzdDpSdW5uaW5nOmJvZHlfeWF3IjoiSml0dGVyIiwiVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX2Nob2tlXzEiOjE2LjAsIlRlcnJvcmlzdDpSdW5uaW5nOmRlZmVuc2l2ZV9jaG9rZV8yIjoxNi4wLCJUZXJyb3Jpc3Q6UnVubmluZzpkZWZlbnNpdmVfY3VzdG9tX2Nob2tlIjpmYWxzZSwiVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX2VuYWJsZWQiOmZhbHNlLCJUZXJyb3Jpc3Q6UnVubmluZzpkZWZlbnNpdmVfZm9yY2VfZGVmZW5zaXZlIjpmYWxzZSwiVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX3BpdGNoIjoiU3RhdGljIiwiVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX3BpdGNoXzEiOjAuMCwiVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX3BpdGNoXzIiOjAuMCwiVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX3BpdGNoX29mZnNldCI6MC4wLCJUZXJyb3Jpc3Q6UnVubmluZzpkZWZlbnNpdmVfcmFuZG9tX2Nob2tlIjpmYWxzZSwiVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX3JhbmRvbWl6YXRpb24iOjAuMCwiVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX3lhdyI6IlN0YXRpYyIsIlRlcnJvcmlzdDpSdW5uaW5nOmRlZmVuc2l2ZV95YXdfMSI6MC4wLCJUZXJyb3Jpc3Q6UnVubmluZzpkZWZlbnNpdmVfeWF3XzIiOjAuMCwiVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX3lhd19vZmZzZXQiOjE4MC4wLCJUZXJyb3Jpc3Q6UnVubmluZzpkZWZlbnNpdmVfeWF3X3NwZWVkIjoyMC4wLCJUZXJyb3Jpc3Q6UnVubmluZzpkZWxheV8xIjowLjAsIlRlcnJvcmlzdDpSdW5uaW5nOmRlbGF5XzIiOjAuMCwiVGVycm9yaXN0OlJ1bm5pbmc6bGVmdF9saW1pdCI6MzYuMCwiVGVycm9yaXN0OlJ1bm5pbmc6bW9kaWZpZXJfb2Zmc2V0IjotNTIuMCwiVGVycm9yaXN0OlJ1bm5pbmc6cmlnaHRfbGltaXQiOjM2LjAsIlRlcnJvcmlzdDpSdW5uaW5nOnlhd19hZGQiOnRydWUsIlRlcnJvcmlzdDpSdW5uaW5nOnlhd19sZWZ0IjotNi4wLCJUZXJyb3Jpc3Q6UnVubmluZzp5YXdfbW9kaWZpZXIiOiJDZW50ZXIiLCJUZXJyb3Jpc3Q6UnVubmluZzp5YXdfb2Zmc2V0IjowLjAsIlRlcnJvcmlzdDpSdW5uaW5nOnlhd19yaWdodCI6MTEuMCwiVGVycm9yaXN0OlNuZWFraW5nOmJvZHlfeWF3IjoiSml0dGVyIiwiVGVycm9yaXN0OlNuZWFraW5nOmRlZmVuc2l2ZV9jaG9rZV8xIjoxNi4wLCJUZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX2Nob2tlXzIiOjE2LjAsIlRlcnJvcmlzdDpTbmVha2luZzpkZWZlbnNpdmVfY3VzdG9tX2Nob2tlIjpmYWxzZSwiVGVycm9yaXN0OlNuZWFraW5nOmRlZmVuc2l2ZV9lbmFibGVkIjpmYWxzZSwiVGVycm9yaXN0OlNuZWFraW5nOmRlZmVuc2l2ZV9mb3JjZV9kZWZlbnNpdmUiOmZhbHNlLCJUZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX3BpdGNoIjoiU3RhdGljIiwiVGVycm9yaXN0OlNuZWFraW5nOmRlZmVuc2l2ZV9waXRjaF8xIjowLjAsIlRlcnJvcmlzdDpTbmVha2luZzpkZWZlbnNpdmVfcGl0Y2hfMiI6MC4wLCJUZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX3BpdGNoX29mZnNldCI6MC4wLCJUZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX3JhbmRvbV9jaG9rZSI6ZmFsc2UsIlRlcnJvcmlzdDpTbmVha2luZzpkZWZlbnNpdmVfcmFuZG9taXphdGlvbiI6MC4wLCJUZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX3lhdyI6IlN0YXRpYyIsIlRlcnJvcmlzdDpTbmVha2luZzpkZWZlbnNpdmVfeWF3XzEiOjAuMCwiVGVycm9yaXN0OlNuZWFraW5nOmRlZmVuc2l2ZV95YXdfMiI6MC4wLCJUZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX3lhd19vZmZzZXQiOjE4MC4wLCJUZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX3lhd19zcGVlZCI6MjAuMCwiVGVycm9yaXN0OlNuZWFraW5nOmRlbGF5XzEiOjAuMCwiVGVycm9yaXN0OlNuZWFraW5nOmRlbGF5XzIiOjAuMCwiVGVycm9yaXN0OlNuZWFraW5nOmxlZnRfbGltaXQiOjU4LjAsIlRlcnJvcmlzdDpTbmVha2luZzptb2RpZmllcl9vZmZzZXQiOi0zNS4wLCJUZXJyb3Jpc3Q6U25lYWtpbmc6cmlnaHRfbGltaXQiOjU4LjAsIlRlcnJvcmlzdDpTbmVha2luZzp5YXdfYWRkIjp0cnVlLCJUZXJyb3Jpc3Q6U25lYWtpbmc6eWF3X2xlZnQiOi0xMC4wLCJUZXJyb3Jpc3Q6U25lYWtpbmc6eWF3X21vZGlmaWVyIjoiQ2VudGVyIiwiVGVycm9yaXN0OlNuZWFraW5nOnlhd19vZmZzZXQiOjAuMCwiVGVycm9yaXN0OlNuZWFraW5nOnlhd19yaWdodCI6MTYuMCwiVGVycm9yaXN0OlN0YW5kaW5nOmJvZHlfeWF3IjoiSml0dGVyIiwiVGVycm9yaXN0OlN0YW5kaW5nOmRlZmVuc2l2ZV9jaG9rZV8xIjoxNi4wLCJUZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX2Nob2tlXzIiOjE2LjAsIlRlcnJvcmlzdDpTdGFuZGluZzpkZWZlbnNpdmVfY3VzdG9tX2Nob2tlIjpmYWxzZSwiVGVycm9yaXN0OlN0YW5kaW5nOmRlZmVuc2l2ZV9lbmFibGVkIjpmYWxzZSwiVGVycm9yaXN0OlN0YW5kaW5nOmRlZmVuc2l2ZV9mb3JjZV9kZWZlbnNpdmUiOmZhbHNlLCJUZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX3BpdGNoIjoiU3RhdGljIiwiVGVycm9yaXN0OlN0YW5kaW5nOmRlZmVuc2l2ZV9waXRjaF8xIjowLjAsIlRlcnJvcmlzdDpTdGFuZGluZzpkZWZlbnNpdmVfcGl0Y2hfMiI6MC4wLCJUZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX3BpdGNoX29mZnNldCI6MC4wLCJUZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX3JhbmRvbV9jaG9rZSI6ZmFsc2UsIlRlcnJvcmlzdDpTdGFuZGluZzpkZWZlbnNpdmVfcmFuZG9taXphdGlvbiI6MC4wLCJUZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX3lhdyI6IlN0YXRpYyIsIlRlcnJvcmlzdDpTdGFuZGluZzpkZWZlbnNpdmVfeWF3XzEiOjAuMCwiVGVycm9yaXN0OlN0YW5kaW5nOmRlZmVuc2l2ZV95YXdfMiI6MC4wLCJUZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX3lhd19vZmZzZXQiOjE4MC4wLCJUZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX3lhd19zcGVlZCI6MjAuMCwiVGVycm9yaXN0OlN0YW5kaW5nOmRlbGF5XzEiOjAuMCwiVGVycm9yaXN0OlN0YW5kaW5nOmRlbGF5XzIiOjAuMCwiVGVycm9yaXN0OlN0YW5kaW5nOmxlZnRfbGltaXQiOjMwLjAsIlRlcnJvcmlzdDpTdGFuZGluZzptb2RpZmllcl9vZmZzZXQiOi00Ni4wLCJUZXJyb3Jpc3Q6U3RhbmRpbmc6cmlnaHRfbGltaXQiOjMwLjAsIlRlcnJvcmlzdDpTdGFuZGluZzp5YXdfYWRkIjp0cnVlLCJUZXJyb3Jpc3Q6U3RhbmRpbmc6eWF3X2xlZnQiOi03LjAsIlRlcnJvcmlzdDpTdGFuZGluZzp5YXdfbW9kaWZpZXIiOiJDZW50ZXIiLCJUZXJyb3Jpc3Q6U3RhbmRpbmc6eWF3X29mZnNldCI6MC4wLCJUZXJyb3Jpc3Q6U3RhbmRpbmc6eWF3X3JpZ2h0IjoxMS4wLCJUZXJyb3Jpc3Q6V2Fsa2luZzpib2R5X3lhdyI6IkppdHRlciIsIlRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV9jaG9rZV8xIjoxNi4wLCJUZXJyb3Jpc3Q6V2Fsa2luZzpkZWZlbnNpdmVfY2hva2VfMiI6MTYuMCwiVGVycm9yaXN0OldhbGtpbmc6ZGVmZW5zaXZlX2N1c3RvbV9jaG9rZSI6ZmFsc2UsIlRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV9lbmFibGVkIjpmYWxzZSwiVGVycm9yaXN0OldhbGtpbmc6ZGVmZW5zaXZlX2ZvcmNlX2RlZmVuc2l2ZSI6ZmFsc2UsIlRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV9waXRjaCI6IlN0YXRpYyIsIlRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV9waXRjaF8xIjowLjAsIlRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV9waXRjaF8yIjowLjAsIlRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV9waXRjaF9vZmZzZXQiOjAuMCwiVGVycm9yaXN0OldhbGtpbmc6ZGVmZW5zaXZlX3JhbmRvbV9jaG9rZSI6ZmFsc2UsIlRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV9yYW5kb21pemF0aW9uIjowLjAsIlRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV95YXciOiJTdGF0aWMiLCJUZXJyb3Jpc3Q6V2Fsa2luZzpkZWZlbnNpdmVfeWF3XzEiOjAuMCwiVGVycm9yaXN0OldhbGtpbmc6ZGVmZW5zaXZlX3lhd18yIjowLjAsIlRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV95YXdfb2Zmc2V0IjoxODAuMCwiVGVycm9yaXN0OldhbGtpbmc6ZGVmZW5zaXZlX3lhd19zcGVlZCI6MjAuMCwiVGVycm9yaXN0OldhbGtpbmc6ZGVsYXlfMSI6MC4wLCJUZXJyb3Jpc3Q6V2Fsa2luZzpkZWxheV8yIjowLjAsIlRlcnJvcmlzdDpXYWxraW5nOmxlZnRfbGltaXQiOjQ1LjAsIlRlcnJvcmlzdDpXYWxraW5nOm1vZGlmaWVyX29mZnNldCI6LTUuMCwiVGVycm9yaXN0OldhbGtpbmc6cmlnaHRfbGltaXQiOjQ1LjAsIlRlcnJvcmlzdDpXYWxraW5nOnlhd19hZGQiOnRydWUsIlRlcnJvcmlzdDpXYWxraW5nOnlhd19sZWZ0IjotMjMuMCwiVGVycm9yaXN0OldhbGtpbmc6eWF3X21vZGlmaWVyIjoiU3BpbiIsIlRlcnJvcmlzdDpXYWxraW5nOnlhd19vZmZzZXQiOjAuMCwiVGVycm9yaXN0OldhbGtpbmc6eWF3X3JpZ2h0Ijo0Ny4wLCJhdm9pZF9iYWNrc3RhYi5lbmFibGVkIjp0cnVlLCJmbGlja19leHBsb2l0LmNvbmRpdGlvbnMiOltdLCJmbGlja19leHBsb2l0LmVuYWJsZWQiOmZhbHNlLCJmcmVlc3RhbmRpbmcuZGlzYWJsZXJzIjpbIkluIEFpciIsIkFpciBDcm91Y2giXSwiZnJlZXN0YW5kaW5nLmVuYWJsZWQiOmZhbHNlLCJmcmVlc3RhbmRpbmcuc3RhdGljIjpmYWxzZSwibWFudWFsX3lhdy5kaXJlY3Rpb24iOiJEaXNhYmxlZCIsIm1hbnVhbF95YXcuZGlzYWJsZXJzIjpbXSwibWFudWFsX3lhdy5zdGF0aWMiOmZhbHNlLCJtb2RpZnlfb25fd2FybXVwLmVuYWJsZWQiOnRydWUsIm9uX3VzZS5lbmFibGVkIjp0cnVlLCJzYWZlX2hlYWQuY29uZGl0aW9ucyI6WyJTdGFuZGluZyIsIkNyb3VjaCIsIkFpciBDcm91Y2giLCJBaXIgS25pZmUiLCJBaXIgVGFzZXIiLCJEaXN0YW5jZSJdLCJzYWZlX2hlYWQuZW5hYmxlZCI6dHJ1ZX0sIk1pc2NlbGxhbmVvdXMiOnsiYXZvaWRfY29sbGlzaW9ucy5lbmFibGVkIjpmYWxzZSwiY2xhbnRhZy5lbmFibGVkIjpmYWxzZSwiY29sbGlzaW9uX2Fpcl9kdWNrLmVuYWJsZWQiOmZhbHNlLCJlZGdlX3N0b3AuZW5hYmxlZCI6ZmFsc2UsImZhc3RfbGFkZGVyLmVuYWJsZWQiOnRydWUsIm5vX2ZhbGxfZGFtYWdlLmVuYWJsZWQiOnRydWUsInN1cGVyX3Rvc3MuZW5hYmxlZCI6dHJ1ZSwidHJhc2h0YWxrLmRlbGF5IjozMC4wLCJ0cmFzaHRhbGsuZW5hYmxlZCI6ZmFsc2UsInVubG9ja19mZF9zcGVlZC5lbmFibGVkIjp0cnVlfSwiVmlzdWFscyI6eyJhbmltYXRpb25zLmVhcnRocXVha2UiOmZhbHNlLCJhbmltYXRpb25zLmVuYWJsZWQiOmZhbHNlLCJhbmltYXRpb25zLmluX2FpciI6IkRpc2FibGVkIiwiYW5pbWF0aW9ucy5tb3ZlX2xlYW4iOjAuMCwiYW5pbWF0aW9ucy5vbl9ncm91bmQiOiJEaXNhYmxlZCIsImFuaW1hdGlvbnMucGl0Y2hfb25fbGFuZCI6ZmFsc2UsImFuaW1hdGlvbnMuc2xpZGluZ19jcm91Y2giOmZhbHNlLCJhbmltYXRpb25zLnNsaWRpbmdfc2xvd3dhbGsiOmZhbHNlLCJhc3BlY3RfcmF0aW8uZW5hYmxlZCI6ZmFsc2UsImFzcGVjdF9yYXRpby5wcm9wb3J0aW9uIjowLjAsImNvbnNvbGVfY29sb3IuY29sb3IiOiI4MDgwODA5RSIsImNvbnNvbGVfY29sb3IuZW5hYmxlZCI6dHJ1ZSwiY3Jvc3NoYWlyX2luZGljYXRvcnMuY29sb3IiOiJGRkI3NEZGRiIsImNyb3NzaGFpcl9pbmRpY2F0b3JzLmVuYWJsZWQiOnRydWUsImNyb3NzaGFpcl9pbmRpY2F0b3JzLm9mZnNldCI6NDAuMCwiZGFtYWdlX2luZGljYXRvci5jb2xvciI6IkZGRkZGRkZGIiwiZGFtYWdlX2luZGljYXRvci5lbmFibGVkIjp0cnVlLCJkYW1hZ2VfaW5kaWNhdG9yLmZvbnQiOiJTbWFsbCIsImhpdF9tYXJrZXIuY29sb3IiOiIwMDAwMDBGRiIsImhpdF9tYXJrZXIuZW5hYmxlZCI6dHJ1ZSwiaGl0X21hcmtlci5zaXplIjo0LjAsImhpdF9tYXJrZXIudGhpY2tuZXNzIjoyLjAsImtlZXBfdHJhbnNwYXJlbmN5LmVuYWJsZWQiOnRydWUsImxhZ19jb21wX2JveC5jb2xvciI6IjJGNzVEREZGIiwibGFnX2NvbXBfYm94LmVuYWJsZWQiOnRydWUsIm1hbnVhbF9hcnJvd3MuY29sb3IiOiJGRkZGRkZGRiIsIm1hbnVhbF9hcnJvd3MuZW5hYmxlZCI6dHJ1ZSwibWFudWFsX2Fycm93cy5vZmZzZXQiOjQwLjAsIm5hZGVfcmFkaXVzLmVuYWJsZWQiOnRydWUsIm5hZGVfcmFkaXVzLm1vbG90b3YiOnRydWUsIm5hZGVfcmFkaXVzLm1vbG90b3ZfY29sb3IiOiJEODk4NjBGRiIsIm5hZGVfcmFkaXVzLnNtb2tlIjp0cnVlLCJuYWRlX3JhZGl1cy5zbW9rZV9jb2xvciI6Ijg2OTRDNEZGIiwicmVtb3ZlX2Zvb3RzdGVwc19zaGFkb3cuZW5hYmxlZCI6dHJ1ZSwic2NvcGVfb3ZlcmxheS5hZGRpdGlvbnMiOltdLCJzY29wZV9vdmVybGF5LmNvbG9yIjoiRkZGRkZGOUUiLCJzY29wZV9vdmVybGF5LmVuYWJsZWQiOnRydWUsInNjb3BlX292ZXJsYXkuZXhjbHVkZV9saW5lcyI6W10sInNjb3BlX292ZXJsYXkuZ2FwIjowLjAsInNjb3BlX292ZXJsYXkuc2l6ZSI6NTUuMCwic2tlZXRfaW5kaWNhdG9ycy5lbmFibGVkIjp0cnVlLCJza2VldF9pbmRpY2F0b3JzLml0ZW1zIjpbMS4wLDIuMCwzLjAsNC4wLDUuMCw2LjAsNy4wLDguMCw5LjAsMTAuMCwxMS4wXSwidmVsb2NpdHlfd2FybmluZy5jb2xvciI6IkZGQjc0RkZGIiwidmVsb2NpdHlfd2FybmluZy5lbmFibGVkIjp0cnVlLCJ2ZWxvY2l0eV93YXJuaW5nLm9mZnNldCI6MTYwLjAsInZpZXdtb2RlbC5lbmFibGVkIjpmYWxzZSwidmlld21vZGVsLmZvdiI6NjgwLjAsInZpZXdtb2RlbC5vZmZzZXRfeCI6MjUuMCwidmlld21vZGVsLm9mZnNldF95IjowLjAsInZpZXdtb2RlbC5vZmZzZXRfeiI6LTE1LjB9fQ__");
            add_builtin("Delay", concat("\a{Link Active}", icons.get("circle-info"), "\aDEFAULT", "  This configuration is based on slow jitter & tickrate tweaks, with no exploit usage."), "social::nl::eyJBaW1ib3QiOnsiYWlfcGVlay5jb2xvciI6IkZGRkZGRkZGIiwiYWlfcGVlay5kb3RzIjo0LjAsImFpX3BlZWsuZW5hYmxlZCI6ZmFsc2UsImFpX3BlZWsuaGl0Ym94ZXMiOlsiSGVhZCIsIkNoZXN0IiwiU3RvbWFjaCIsIkFybXMiLCJMZWdzIiwiRmVldCJdLCJhaV9wZWVrLnJhZGl1cyI6MzIuMCwiYWlfcGVlay53ZWFwb25zIjpbIlNTRyAwOCIsIlI4IFJldm9sdmVyIiwiRGVzZXJ0IEVhZ2xlIiwiUGlzdG9sIiwiUmlmbGUiLCJTaG90Z3VuIl0sImRvcm1hbnRfYWltYm90LmFjY3VyYWN5Ijo2MC4wLCJkb3JtYW50X2FpbWJvdC5lbmFibGVkIjpmYWxzZSwiZG9ybWFudF9haW1ib3QuaGl0Ym94ZXMiOlsiSGVhZCIsIkNoZXN0IiwiU3RvbWFjaCIsIkxlZ3MiXSwiZG9ybWFudF9haW1ib3QubWluX2RhbWFnZSI6MTAuMCwiZmFrZV9sYXRlbmN5LmVuYWJsZWQiOmZhbHNlLCJsb2dfZXZlbnRzLmNvbG9yX2hpdCI6IjgwOUJDRUZGIiwibG9nX2V2ZW50cy5jb2xvcl9taXNzIjoiQzQ4Njg2RkYiLCJsb2dfZXZlbnRzLmVuYWJsZWQiOnRydWUsImxvZ19ldmVudHMub3V0cHV0IjpbIkNvbnNvbGUiLCJEZWJ1ZyIsIk5vdGlmeSJdLCJtYXh1c3JjbWRwcm9jZXNzdGlja3MuZW5hYmxlZCI6ZmFsc2UsIm1heHVzcmNtZHByb2Nlc3N0aWNrcy50aWNrcyI6MTYuMH0sIkFudGktQWltIjp7IkNvdW50ZXItVGVycm9yaXN0OkFpciBDcm91Y2g6Ym9keV95YXciOiJSYW5kb21pemUgSml0dGVyIiwiQ291bnRlci1UZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfY2hva2VfMSI6MTYuMCwiQ291bnRlci1UZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfY2hva2VfMiI6MTYuMCwiQ291bnRlci1UZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfY3VzdG9tX2Nob2tlIjpmYWxzZSwiQ291bnRlci1UZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfZW5hYmxlZCI6ZmFsc2UsIkNvdW50ZXItVGVycm9yaXN0OkFpciBDcm91Y2g6ZGVmZW5zaXZlX2ZvcmNlX2RlZmVuc2l2ZSI6ZmFsc2UsIkNvdW50ZXItVGVycm9yaXN0OkFpciBDcm91Y2g6ZGVmZW5zaXZlX3BpdGNoIjoiU3RhdGljIiwiQ291bnRlci1UZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfcGl0Y2hfMSI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlZmVuc2l2ZV9waXRjaF8yIjowLjAsIkNvdW50ZXItVGVycm9yaXN0OkFpciBDcm91Y2g6ZGVmZW5zaXZlX3BpdGNoX29mZnNldCI6LTQ1LjAsIkNvdW50ZXItVGVycm9yaXN0OkFpciBDcm91Y2g6ZGVmZW5zaXZlX3JhbmRvbV9jaG9rZSI6ZmFsc2UsIkNvdW50ZXItVGVycm9yaXN0OkFpciBDcm91Y2g6ZGVmZW5zaXZlX3JhbmRvbWl6YXRpb24iOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfeWF3IjoiU3BpbiIsIkNvdW50ZXItVGVycm9yaXN0OkFpciBDcm91Y2g6ZGVmZW5zaXZlX3lhd18xIjowLjAsIkNvdW50ZXItVGVycm9yaXN0OkFpciBDcm91Y2g6ZGVmZW5zaXZlX3lhd18yIjowLjAsIkNvdW50ZXItVGVycm9yaXN0OkFpciBDcm91Y2g6ZGVmZW5zaXZlX3lhd19vZmZzZXQiOjM2MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlZmVuc2l2ZV95YXdfc3BlZWQiOjUwLjAsIkNvdW50ZXItVGVycm9yaXN0OkFpciBDcm91Y2g6ZGVsYXlfMSI6MS4wLCJDb3VudGVyLVRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlbGF5XzIiOjMuMCwiQ291bnRlci1UZXJyb3Jpc3Q6QWlyIENyb3VjaDpsZWZ0X2xpbWl0Ijo1OC4wLCJDb3VudGVyLVRlcnJvcmlzdDpBaXIgQ3JvdWNoOm1vZGlmaWVyX29mZnNldCI6LTQ2LjAsIkNvdW50ZXItVGVycm9yaXN0OkFpciBDcm91Y2g6cmlnaHRfbGltaXQiOjU4LjAsIkNvdW50ZXItVGVycm9yaXN0OkFpciBDcm91Y2g6eWF3X2FkZCI6dHJ1ZSwiQ291bnRlci1UZXJyb3Jpc3Q6QWlyIENyb3VjaDp5YXdfbGVmdCI6LTMxLjAsIkNvdW50ZXItVGVycm9yaXN0OkFpciBDcm91Y2g6eWF3X21vZGlmaWVyIjoiRGlzYWJsZWQiLCJDb3VudGVyLVRlcnJvcmlzdDpBaXIgQ3JvdWNoOnlhd19vZmZzZXQiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6QWlyIENyb3VjaDp5YXdfcmlnaHQiOjM3LjAsIkNvdW50ZXItVGVycm9yaXN0OkNyb3VjaGluZzpib2R5X3lhdyI6IkppdHRlciIsIkNvdW50ZXItVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfY2hva2VfMSI6MTYuMCwiQ291bnRlci1UZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlZmVuc2l2ZV9jaG9rZV8yIjoxNi4wLCJDb3VudGVyLVRlcnJvcmlzdDpDcm91Y2hpbmc6ZGVmZW5zaXZlX2N1c3RvbV9jaG9rZSI6ZmFsc2UsIkNvdW50ZXItVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfZW5hYmxlZCI6ZmFsc2UsIkNvdW50ZXItVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfZm9yY2VfZGVmZW5zaXZlIjpmYWxzZSwiQ291bnRlci1UZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlZmVuc2l2ZV9waXRjaCI6IkppdHRlciIsIkNvdW50ZXItVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfcGl0Y2hfMSI6LTQ1LjAsIkNvdW50ZXItVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfcGl0Y2hfMiI6NDUuMCwiQ291bnRlci1UZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlZmVuc2l2ZV9waXRjaF9vZmZzZXQiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlZmVuc2l2ZV9yYW5kb21fY2hva2UiOmZhbHNlLCJDb3VudGVyLVRlcnJvcmlzdDpDcm91Y2hpbmc6ZGVmZW5zaXZlX3JhbmRvbWl6YXRpb24iOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlZmVuc2l2ZV95YXciOiJTdGF0aWMiLCJDb3VudGVyLVRlcnJvcmlzdDpDcm91Y2hpbmc6ZGVmZW5zaXZlX3lhd18xIjowLjAsIkNvdW50ZXItVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfeWF3XzIiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlZmVuc2l2ZV95YXdfb2Zmc2V0IjoxODAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlZmVuc2l2ZV95YXdfc3BlZWQiOjIwLjAsIkNvdW50ZXItVGVycm9yaXN0OkNyb3VjaGluZzpkZWxheV8xIjoxLjAsIkNvdW50ZXItVGVycm9yaXN0OkNyb3VjaGluZzpkZWxheV8yIjowLjAsIkNvdW50ZXItVGVycm9yaXN0OkNyb3VjaGluZzpsZWZ0X2xpbWl0Ijo2MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpDcm91Y2hpbmc6bW9kaWZpZXJfb2Zmc2V0IjotMzUuMCwiQ291bnRlci1UZXJyb3Jpc3Q6Q3JvdWNoaW5nOnJpZ2h0X2xpbWl0Ijo2MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpDcm91Y2hpbmc6eWF3X2FkZCI6dHJ1ZSwiQ291bnRlci1UZXJyb3Jpc3Q6Q3JvdWNoaW5nOnlhd19sZWZ0IjotMzEuMCwiQ291bnRlci1UZXJyb3Jpc3Q6Q3JvdWNoaW5nOnlhd19tb2RpZmllciI6IkRpc2FibGVkIiwiQ291bnRlci1UZXJyb3Jpc3Q6Q3JvdWNoaW5nOnlhd19vZmZzZXQiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6Q3JvdWNoaW5nOnlhd19yaWdodCI6NDUuMCwiQ291bnRlci1UZXJyb3Jpc3Q6SW4gQWlyOmJvZHlfeWF3IjoiSml0dGVyIiwiQ291bnRlci1UZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV9jaG9rZV8xIjoxNi4wLCJDb3VudGVyLVRlcnJvcmlzdDpJbiBBaXI6ZGVmZW5zaXZlX2Nob2tlXzIiOjE2LjAsIkNvdW50ZXItVGVycm9yaXN0OkluIEFpcjpkZWZlbnNpdmVfY3VzdG9tX2Nob2tlIjpmYWxzZSwiQ291bnRlci1UZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV9lbmFibGVkIjpmYWxzZSwiQ291bnRlci1UZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV9mb3JjZV9kZWZlbnNpdmUiOmZhbHNlLCJDb3VudGVyLVRlcnJvcmlzdDpJbiBBaXI6ZGVmZW5zaXZlX3BpdGNoIjoiU3RhdGljIiwiQ291bnRlci1UZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV9waXRjaF8xIjowLjAsIkNvdW50ZXItVGVycm9yaXN0OkluIEFpcjpkZWZlbnNpdmVfcGl0Y2hfMiI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpJbiBBaXI6ZGVmZW5zaXZlX3BpdGNoX29mZnNldCI6LTQ1LjAsIkNvdW50ZXItVGVycm9yaXN0OkluIEFpcjpkZWZlbnNpdmVfcmFuZG9tX2Nob2tlIjpmYWxzZSwiQ291bnRlci1UZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV9yYW5kb21pemF0aW9uIjowLjAsIkNvdW50ZXItVGVycm9yaXN0OkluIEFpcjpkZWZlbnNpdmVfeWF3IjoiU3dpdGNoIiwiQ291bnRlci1UZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV95YXdfMSI6LTkwLjAsIkNvdW50ZXItVGVycm9yaXN0OkluIEFpcjpkZWZlbnNpdmVfeWF3XzIiOjkwLjAsIkNvdW50ZXItVGVycm9yaXN0OkluIEFpcjpkZWZlbnNpdmVfeWF3X29mZnNldCI6MTgwLjAsIkNvdW50ZXItVGVycm9yaXN0OkluIEFpcjpkZWZlbnNpdmVfeWF3X3NwZWVkIjoyMC4wLCJDb3VudGVyLVRlcnJvcmlzdDpJbiBBaXI6ZGVsYXlfMSI6MS4wLCJDb3VudGVyLVRlcnJvcmlzdDpJbiBBaXI6ZGVsYXlfMiI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpJbiBBaXI6bGVmdF9saW1pdCI6NTguMCwiQ291bnRlci1UZXJyb3Jpc3Q6SW4gQWlyOm1vZGlmaWVyX29mZnNldCI6LTQ3LjAsIkNvdW50ZXItVGVycm9yaXN0OkluIEFpcjpyaWdodF9saW1pdCI6NTguMCwiQ291bnRlci1UZXJyb3Jpc3Q6SW4gQWlyOnlhd19hZGQiOnRydWUsIkNvdW50ZXItVGVycm9yaXN0OkluIEFpcjp5YXdfbGVmdCI6LTI2LjAsIkNvdW50ZXItVGVycm9yaXN0OkluIEFpcjp5YXdfbW9kaWZpZXIiOiJEaXNhYmxlZCIsIkNvdW50ZXItVGVycm9yaXN0OkluIEFpcjp5YXdfb2Zmc2V0IjowLjAsIkNvdW50ZXItVGVycm9yaXN0OkluIEFpcjp5YXdfcmlnaHQiOjM5LjAsIkNvdW50ZXItVGVycm9yaXN0OlJ1bm5pbmc6Ym9keV95YXciOiJKaXR0ZXIiLCJDb3VudGVyLVRlcnJvcmlzdDpSdW5uaW5nOmRlZmVuc2l2ZV9jaG9rZV8xIjoyLjAsIkNvdW50ZXItVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX2Nob2tlXzIiOjYuMCwiQ291bnRlci1UZXJyb3Jpc3Q6UnVubmluZzpkZWZlbnNpdmVfY3VzdG9tX2Nob2tlIjp0cnVlLCJDb3VudGVyLVRlcnJvcmlzdDpSdW5uaW5nOmRlZmVuc2l2ZV9lbmFibGVkIjpmYWxzZSwiQ291bnRlci1UZXJyb3Jpc3Q6UnVubmluZzpkZWZlbnNpdmVfZm9yY2VfZGVmZW5zaXZlIjpmYWxzZSwiQ291bnRlci1UZXJyb3Jpc3Q6UnVubmluZzpkZWZlbnNpdmVfcGl0Y2giOiJKaXR0ZXIiLCJDb3VudGVyLVRlcnJvcmlzdDpSdW5uaW5nOmRlZmVuc2l2ZV9waXRjaF8xIjotNDUuMCwiQ291bnRlci1UZXJyb3Jpc3Q6UnVubmluZzpkZWZlbnNpdmVfcGl0Y2hfMiI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpSdW5uaW5nOmRlZmVuc2l2ZV9waXRjaF9vZmZzZXQiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6UnVubmluZzpkZWZlbnNpdmVfcmFuZG9tX2Nob2tlIjp0cnVlLCJDb3VudGVyLVRlcnJvcmlzdDpSdW5uaW5nOmRlZmVuc2l2ZV9yYW5kb21pemF0aW9uIjowLjAsIkNvdW50ZXItVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX3lhdyI6IlN3aXRjaCIsIkNvdW50ZXItVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX3lhd18xIjotOTAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6UnVubmluZzpkZWZlbnNpdmVfeWF3XzIiOjkwLjAsIkNvdW50ZXItVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX3lhd19vZmZzZXQiOjE4MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpSdW5uaW5nOmRlZmVuc2l2ZV95YXdfc3BlZWQiOjUwLjAsIkNvdW50ZXItVGVycm9yaXN0OlJ1bm5pbmc6ZGVsYXlfMSI6MS4wLCJDb3VudGVyLVRlcnJvcmlzdDpSdW5uaW5nOmRlbGF5XzIiOjIuMCwiQ291bnRlci1UZXJyb3Jpc3Q6UnVubmluZzpsZWZ0X2xpbWl0Ijo2MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpSdW5uaW5nOm1vZGlmaWVyX29mZnNldCI6LTU4LjAsIkNvdW50ZXItVGVycm9yaXN0OlJ1bm5pbmc6cmlnaHRfbGltaXQiOjYwLjAsIkNvdW50ZXItVGVycm9yaXN0OlJ1bm5pbmc6eWF3X2FkZCI6dHJ1ZSwiQ291bnRlci1UZXJyb3Jpc3Q6UnVubmluZzp5YXdfbGVmdCI6LTI2LjAsIkNvdW50ZXItVGVycm9yaXN0OlJ1bm5pbmc6eWF3X21vZGlmaWVyIjoiRGlzYWJsZWQiLCJDb3VudGVyLVRlcnJvcmlzdDpSdW5uaW5nOnlhd19vZmZzZXQiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6UnVubmluZzp5YXdfcmlnaHQiOjM1LjAsIkNvdW50ZXItVGVycm9yaXN0OlNuZWFraW5nOmJvZHlfeWF3IjoiSml0dGVyIiwiQ291bnRlci1UZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX2Nob2tlXzEiOjE2LjAsIkNvdW50ZXItVGVycm9yaXN0OlNuZWFraW5nOmRlZmVuc2l2ZV9jaG9rZV8yIjoxNi4wLCJDb3VudGVyLVRlcnJvcmlzdDpTbmVha2luZzpkZWZlbnNpdmVfY3VzdG9tX2Nob2tlIjpmYWxzZSwiQ291bnRlci1UZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX2VuYWJsZWQiOmZhbHNlLCJDb3VudGVyLVRlcnJvcmlzdDpTbmVha2luZzpkZWZlbnNpdmVfZm9yY2VfZGVmZW5zaXZlIjpmYWxzZSwiQ291bnRlci1UZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX3BpdGNoIjoiU3RhdGljIiwiQ291bnRlci1UZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX3BpdGNoXzEiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX3BpdGNoXzIiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX3BpdGNoX29mZnNldCI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpTbmVha2luZzpkZWZlbnNpdmVfcmFuZG9tX2Nob2tlIjpmYWxzZSwiQ291bnRlci1UZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX3JhbmRvbWl6YXRpb24iOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX3lhdyI6IlN0YXRpYyIsIkNvdW50ZXItVGVycm9yaXN0OlNuZWFraW5nOmRlZmVuc2l2ZV95YXdfMSI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpTbmVha2luZzpkZWZlbnNpdmVfeWF3XzIiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX3lhd19vZmZzZXQiOjE4MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpTbmVha2luZzpkZWZlbnNpdmVfeWF3X3NwZWVkIjoyMC4wLCJDb3VudGVyLVRlcnJvcmlzdDpTbmVha2luZzpkZWxheV8xIjoxLjAsIkNvdW50ZXItVGVycm9yaXN0OlNuZWFraW5nOmRlbGF5XzIiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U25lYWtpbmc6bGVmdF9saW1pdCI6NjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U25lYWtpbmc6bW9kaWZpZXJfb2Zmc2V0IjotMzUuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U25lYWtpbmc6cmlnaHRfbGltaXQiOjYwLjAsIkNvdW50ZXItVGVycm9yaXN0OlNuZWFraW5nOnlhd19hZGQiOnRydWUsIkNvdW50ZXItVGVycm9yaXN0OlNuZWFraW5nOnlhd19sZWZ0IjotMjcuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U25lYWtpbmc6eWF3X21vZGlmaWVyIjoiRGlzYWJsZWQiLCJDb3VudGVyLVRlcnJvcmlzdDpTbmVha2luZzp5YXdfb2Zmc2V0IjowLjAsIkNvdW50ZXItVGVycm9yaXN0OlNuZWFraW5nOnlhd19yaWdodCI6MzMuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U3RhbmRpbmc6Ym9keV95YXciOiJKaXR0ZXIiLCJDb3VudGVyLVRlcnJvcmlzdDpTdGFuZGluZzpkZWZlbnNpdmVfY2hva2VfMSI6MTYuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX2Nob2tlXzIiOjE2LjAsIkNvdW50ZXItVGVycm9yaXN0OlN0YW5kaW5nOmRlZmVuc2l2ZV9jdXN0b21fY2hva2UiOmZhbHNlLCJDb3VudGVyLVRlcnJvcmlzdDpTdGFuZGluZzpkZWZlbnNpdmVfZW5hYmxlZCI6ZmFsc2UsIkNvdW50ZXItVGVycm9yaXN0OlN0YW5kaW5nOmRlZmVuc2l2ZV9mb3JjZV9kZWZlbnNpdmUiOmZhbHNlLCJDb3VudGVyLVRlcnJvcmlzdDpTdGFuZGluZzpkZWZlbnNpdmVfcGl0Y2giOiJTdGF0aWMiLCJDb3VudGVyLVRlcnJvcmlzdDpTdGFuZGluZzpkZWZlbnNpdmVfcGl0Y2hfMSI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpTdGFuZGluZzpkZWZlbnNpdmVfcGl0Y2hfMiI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpTdGFuZGluZzpkZWZlbnNpdmVfcGl0Y2hfb2Zmc2V0IjowLjAsIkNvdW50ZXItVGVycm9yaXN0OlN0YW5kaW5nOmRlZmVuc2l2ZV9yYW5kb21fY2hva2UiOmZhbHNlLCJDb3VudGVyLVRlcnJvcmlzdDpTdGFuZGluZzpkZWZlbnNpdmVfcmFuZG9taXphdGlvbiI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpTdGFuZGluZzpkZWZlbnNpdmVfeWF3IjoiU3RhdGljIiwiQ291bnRlci1UZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX3lhd18xIjowLjAsIkNvdW50ZXItVGVycm9yaXN0OlN0YW5kaW5nOmRlZmVuc2l2ZV95YXdfMiI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpTdGFuZGluZzpkZWZlbnNpdmVfeWF3X29mZnNldCI6MTgwLjAsIkNvdW50ZXItVGVycm9yaXN0OlN0YW5kaW5nOmRlZmVuc2l2ZV95YXdfc3BlZWQiOjIwLjAsIkNvdW50ZXItVGVycm9yaXN0OlN0YW5kaW5nOmRlbGF5XzEiOjEuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVsYXlfMiI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpTdGFuZGluZzpsZWZ0X2xpbWl0IjozMC4wLCJDb3VudGVyLVRlcnJvcmlzdDpTdGFuZGluZzptb2RpZmllcl9vZmZzZXQiOi00Ni4wLCJDb3VudGVyLVRlcnJvcmlzdDpTdGFuZGluZzpyaWdodF9saW1pdCI6MzAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U3RhbmRpbmc6eWF3X2FkZCI6dHJ1ZSwiQ291bnRlci1UZXJyb3Jpc3Q6U3RhbmRpbmc6eWF3X2xlZnQiOi0zMC4wLCJDb3VudGVyLVRlcnJvcmlzdDpTdGFuZGluZzp5YXdfbW9kaWZpZXIiOiJEaXNhYmxlZCIsIkNvdW50ZXItVGVycm9yaXN0OlN0YW5kaW5nOnlhd19vZmZzZXQiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6U3RhbmRpbmc6eWF3X3JpZ2h0IjozNC4wLCJDb3VudGVyLVRlcnJvcmlzdDpXYWxraW5nOmJvZHlfeWF3IjoiUmFuZG9taXplIEppdHRlciIsIkNvdW50ZXItVGVycm9yaXN0OldhbGtpbmc6ZGVmZW5zaXZlX2Nob2tlXzEiOjE2LjAsIkNvdW50ZXItVGVycm9yaXN0OldhbGtpbmc6ZGVmZW5zaXZlX2Nob2tlXzIiOjE2LjAsIkNvdW50ZXItVGVycm9yaXN0OldhbGtpbmc6ZGVmZW5zaXZlX2N1c3RvbV9jaG9rZSI6ZmFsc2UsIkNvdW50ZXItVGVycm9yaXN0OldhbGtpbmc6ZGVmZW5zaXZlX2VuYWJsZWQiOmZhbHNlLCJDb3VudGVyLVRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV9mb3JjZV9kZWZlbnNpdmUiOmZhbHNlLCJDb3VudGVyLVRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV9waXRjaCI6IlN0YXRpYyIsIkNvdW50ZXItVGVycm9yaXN0OldhbGtpbmc6ZGVmZW5zaXZlX3BpdGNoXzEiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6V2Fsa2luZzpkZWZlbnNpdmVfcGl0Y2hfMiI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV9waXRjaF9vZmZzZXQiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6V2Fsa2luZzpkZWZlbnNpdmVfcmFuZG9tX2Nob2tlIjpmYWxzZSwiQ291bnRlci1UZXJyb3Jpc3Q6V2Fsa2luZzpkZWZlbnNpdmVfcmFuZG9taXphdGlvbiI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV95YXciOiJTdGF0aWMiLCJDb3VudGVyLVRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV95YXdfMSI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV95YXdfMiI6MC4wLCJDb3VudGVyLVRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV95YXdfb2Zmc2V0IjoxODAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6V2Fsa2luZzpkZWZlbnNpdmVfeWF3X3NwZWVkIjoyMC4wLCJDb3VudGVyLVRlcnJvcmlzdDpXYWxraW5nOmRlbGF5XzEiOjEuMCwiQ291bnRlci1UZXJyb3Jpc3Q6V2Fsa2luZzpkZWxheV8yIjoyLjAsIkNvdW50ZXItVGVycm9yaXN0OldhbGtpbmc6bGVmdF9saW1pdCI6NjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6V2Fsa2luZzptb2RpZmllcl9vZmZzZXQiOi01LjAsIkNvdW50ZXItVGVycm9yaXN0OldhbGtpbmc6cmlnaHRfbGltaXQiOjYwLjAsIkNvdW50ZXItVGVycm9yaXN0OldhbGtpbmc6eWF3X2FkZCI6dHJ1ZSwiQ291bnRlci1UZXJyb3Jpc3Q6V2Fsa2luZzp5YXdfbGVmdCI6LTI1LjAsIkNvdW50ZXItVGVycm9yaXN0OldhbGtpbmc6eWF3X21vZGlmaWVyIjoiRGlzYWJsZWQiLCJDb3VudGVyLVRlcnJvcmlzdDpXYWxraW5nOnlhd19vZmZzZXQiOjAuMCwiQ291bnRlci1UZXJyb3Jpc3Q6V2Fsa2luZzp5YXdfcmlnaHQiOjM1LjAsIlRlcnJvcmlzdDpBaXIgQ3JvdWNoOmJvZHlfeWF3IjoiUmFuZG9taXplIEppdHRlciIsIlRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlZmVuc2l2ZV9jaG9rZV8xIjoxNi4wLCJUZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfY2hva2VfMiI6MTYuMCwiVGVycm9yaXN0OkFpciBDcm91Y2g6ZGVmZW5zaXZlX2N1c3RvbV9jaG9rZSI6ZmFsc2UsIlRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlZmVuc2l2ZV9lbmFibGVkIjpmYWxzZSwiVGVycm9yaXN0OkFpciBDcm91Y2g6ZGVmZW5zaXZlX2ZvcmNlX2RlZmVuc2l2ZSI6ZmFsc2UsIlRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlZmVuc2l2ZV9waXRjaCI6IlN0YXRpYyIsIlRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlZmVuc2l2ZV9waXRjaF8xIjowLjAsIlRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlZmVuc2l2ZV9waXRjaF8yIjowLjAsIlRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlZmVuc2l2ZV9waXRjaF9vZmZzZXQiOi00NS4wLCJUZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfcmFuZG9tX2Nob2tlIjpmYWxzZSwiVGVycm9yaXN0OkFpciBDcm91Y2g6ZGVmZW5zaXZlX3JhbmRvbWl6YXRpb24iOjAuMCwiVGVycm9yaXN0OkFpciBDcm91Y2g6ZGVmZW5zaXZlX3lhdyI6IlNwaW4iLCJUZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWZlbnNpdmVfeWF3XzEiOjAuMCwiVGVycm9yaXN0OkFpciBDcm91Y2g6ZGVmZW5zaXZlX3lhd18yIjowLjAsIlRlcnJvcmlzdDpBaXIgQ3JvdWNoOmRlZmVuc2l2ZV95YXdfb2Zmc2V0IjozNjAuMCwiVGVycm9yaXN0OkFpciBDcm91Y2g6ZGVmZW5zaXZlX3lhd19zcGVlZCI6NTAuMCwiVGVycm9yaXN0OkFpciBDcm91Y2g6ZGVsYXlfMSI6MS4wLCJUZXJyb3Jpc3Q6QWlyIENyb3VjaDpkZWxheV8yIjozLjAsIlRlcnJvcmlzdDpBaXIgQ3JvdWNoOmxlZnRfbGltaXQiOjU4LjAsIlRlcnJvcmlzdDpBaXIgQ3JvdWNoOm1vZGlmaWVyX29mZnNldCI6LTQ2LjAsIlRlcnJvcmlzdDpBaXIgQ3JvdWNoOnJpZ2h0X2xpbWl0Ijo1OC4wLCJUZXJyb3Jpc3Q6QWlyIENyb3VjaDp5YXdfYWRkIjp0cnVlLCJUZXJyb3Jpc3Q6QWlyIENyb3VjaDp5YXdfbGVmdCI6LTMxLjAsIlRlcnJvcmlzdDpBaXIgQ3JvdWNoOnlhd19tb2RpZmllciI6IkRpc2FibGVkIiwiVGVycm9yaXN0OkFpciBDcm91Y2g6eWF3X29mZnNldCI6MC4wLCJUZXJyb3Jpc3Q6QWlyIENyb3VjaDp5YXdfcmlnaHQiOjM3LjAsIlRlcnJvcmlzdDpDcm91Y2hpbmc6Ym9keV95YXciOiJKaXR0ZXIiLCJUZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlZmVuc2l2ZV9jaG9rZV8xIjoxNi4wLCJUZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlZmVuc2l2ZV9jaG9rZV8yIjoxNi4wLCJUZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlZmVuc2l2ZV9jdXN0b21fY2hva2UiOmZhbHNlLCJUZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlZmVuc2l2ZV9lbmFibGVkIjpmYWxzZSwiVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfZm9yY2VfZGVmZW5zaXZlIjpmYWxzZSwiVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfcGl0Y2giOiJKaXR0ZXIiLCJUZXJyb3Jpc3Q6Q3JvdWNoaW5nOmRlZmVuc2l2ZV9waXRjaF8xIjotNDUuMCwiVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfcGl0Y2hfMiI6NDUuMCwiVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfcGl0Y2hfb2Zmc2V0IjowLjAsIlRlcnJvcmlzdDpDcm91Y2hpbmc6ZGVmZW5zaXZlX3JhbmRvbV9jaG9rZSI6ZmFsc2UsIlRlcnJvcmlzdDpDcm91Y2hpbmc6ZGVmZW5zaXZlX3JhbmRvbWl6YXRpb24iOjAuMCwiVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfeWF3IjoiU3RhdGljIiwiVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfeWF3XzEiOjAuMCwiVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfeWF3XzIiOjAuMCwiVGVycm9yaXN0OkNyb3VjaGluZzpkZWZlbnNpdmVfeWF3X29mZnNldCI6MTgwLjAsIlRlcnJvcmlzdDpDcm91Y2hpbmc6ZGVmZW5zaXZlX3lhd19zcGVlZCI6MjAuMCwiVGVycm9yaXN0OkNyb3VjaGluZzpkZWxheV8xIjoxLjAsIlRlcnJvcmlzdDpDcm91Y2hpbmc6ZGVsYXlfMiI6MC4wLCJUZXJyb3Jpc3Q6Q3JvdWNoaW5nOmxlZnRfbGltaXQiOjYwLjAsIlRlcnJvcmlzdDpDcm91Y2hpbmc6bW9kaWZpZXJfb2Zmc2V0IjotMzUuMCwiVGVycm9yaXN0OkNyb3VjaGluZzpyaWdodF9saW1pdCI6NjAuMCwiVGVycm9yaXN0OkNyb3VjaGluZzp5YXdfYWRkIjp0cnVlLCJUZXJyb3Jpc3Q6Q3JvdWNoaW5nOnlhd19sZWZ0IjotMzEuMCwiVGVycm9yaXN0OkNyb3VjaGluZzp5YXdfbW9kaWZpZXIiOiJEaXNhYmxlZCIsIlRlcnJvcmlzdDpDcm91Y2hpbmc6eWF3X29mZnNldCI6MC4wLCJUZXJyb3Jpc3Q6Q3JvdWNoaW5nOnlhd19yaWdodCI6NDUuMCwiVGVycm9yaXN0OkluIEFpcjpib2R5X3lhdyI6IkppdHRlciIsIlRlcnJvcmlzdDpJbiBBaXI6ZGVmZW5zaXZlX2Nob2tlXzEiOjE2LjAsIlRlcnJvcmlzdDpJbiBBaXI6ZGVmZW5zaXZlX2Nob2tlXzIiOjE2LjAsIlRlcnJvcmlzdDpJbiBBaXI6ZGVmZW5zaXZlX2N1c3RvbV9jaG9rZSI6ZmFsc2UsIlRlcnJvcmlzdDpJbiBBaXI6ZGVmZW5zaXZlX2VuYWJsZWQiOmZhbHNlLCJUZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV9mb3JjZV9kZWZlbnNpdmUiOmZhbHNlLCJUZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV9waXRjaCI6IlN0YXRpYyIsIlRlcnJvcmlzdDpJbiBBaXI6ZGVmZW5zaXZlX3BpdGNoXzEiOjAuMCwiVGVycm9yaXN0OkluIEFpcjpkZWZlbnNpdmVfcGl0Y2hfMiI6MC4wLCJUZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV9waXRjaF9vZmZzZXQiOi00NS4wLCJUZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV9yYW5kb21fY2hva2UiOmZhbHNlLCJUZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV9yYW5kb21pemF0aW9uIjowLjAsIlRlcnJvcmlzdDpJbiBBaXI6ZGVmZW5zaXZlX3lhdyI6IlN3aXRjaCIsIlRlcnJvcmlzdDpJbiBBaXI6ZGVmZW5zaXZlX3lhd18xIjotOTAuMCwiVGVycm9yaXN0OkluIEFpcjpkZWZlbnNpdmVfeWF3XzIiOjkwLjAsIlRlcnJvcmlzdDpJbiBBaXI6ZGVmZW5zaXZlX3lhd19vZmZzZXQiOjE4MC4wLCJUZXJyb3Jpc3Q6SW4gQWlyOmRlZmVuc2l2ZV95YXdfc3BlZWQiOjIwLjAsIlRlcnJvcmlzdDpJbiBBaXI6ZGVsYXlfMSI6MS4wLCJUZXJyb3Jpc3Q6SW4gQWlyOmRlbGF5XzIiOjAuMCwiVGVycm9yaXN0OkluIEFpcjpsZWZ0X2xpbWl0Ijo1OC4wLCJUZXJyb3Jpc3Q6SW4gQWlyOm1vZGlmaWVyX29mZnNldCI6LTQ3LjAsIlRlcnJvcmlzdDpJbiBBaXI6cmlnaHRfbGltaXQiOjU4LjAsIlRlcnJvcmlzdDpJbiBBaXI6eWF3X2FkZCI6dHJ1ZSwiVGVycm9yaXN0OkluIEFpcjp5YXdfbGVmdCI6LTI2LjAsIlRlcnJvcmlzdDpJbiBBaXI6eWF3X21vZGlmaWVyIjoiRGlzYWJsZWQiLCJUZXJyb3Jpc3Q6SW4gQWlyOnlhd19vZmZzZXQiOjAuMCwiVGVycm9yaXN0OkluIEFpcjp5YXdfcmlnaHQiOjM5LjAsIlRlcnJvcmlzdDpSdW5uaW5nOmJvZHlfeWF3IjoiSml0dGVyIiwiVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX2Nob2tlXzEiOjIuMCwiVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX2Nob2tlXzIiOjYuMCwiVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX2N1c3RvbV9jaG9rZSI6dHJ1ZSwiVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX2VuYWJsZWQiOmZhbHNlLCJUZXJyb3Jpc3Q6UnVubmluZzpkZWZlbnNpdmVfZm9yY2VfZGVmZW5zaXZlIjpmYWxzZSwiVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX3BpdGNoIjoiSml0dGVyIiwiVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX3BpdGNoXzEiOi00NS4wLCJUZXJyb3Jpc3Q6UnVubmluZzpkZWZlbnNpdmVfcGl0Y2hfMiI6MC4wLCJUZXJyb3Jpc3Q6UnVubmluZzpkZWZlbnNpdmVfcGl0Y2hfb2Zmc2V0IjowLjAsIlRlcnJvcmlzdDpSdW5uaW5nOmRlZmVuc2l2ZV9yYW5kb21fY2hva2UiOnRydWUsIlRlcnJvcmlzdDpSdW5uaW5nOmRlZmVuc2l2ZV9yYW5kb21pemF0aW9uIjowLjAsIlRlcnJvcmlzdDpSdW5uaW5nOmRlZmVuc2l2ZV95YXciOiJTd2l0Y2giLCJUZXJyb3Jpc3Q6UnVubmluZzpkZWZlbnNpdmVfeWF3XzEiOi05MC4wLCJUZXJyb3Jpc3Q6UnVubmluZzpkZWZlbnNpdmVfeWF3XzIiOjkwLjAsIlRlcnJvcmlzdDpSdW5uaW5nOmRlZmVuc2l2ZV95YXdfb2Zmc2V0IjoxODAuMCwiVGVycm9yaXN0OlJ1bm5pbmc6ZGVmZW5zaXZlX3lhd19zcGVlZCI6NTAuMCwiVGVycm9yaXN0OlJ1bm5pbmc6ZGVsYXlfMSI6MS4wLCJUZXJyb3Jpc3Q6UnVubmluZzpkZWxheV8yIjoyLjAsIlRlcnJvcmlzdDpSdW5uaW5nOmxlZnRfbGltaXQiOjYwLjAsIlRlcnJvcmlzdDpSdW5uaW5nOm1vZGlmaWVyX29mZnNldCI6LTU4LjAsIlRlcnJvcmlzdDpSdW5uaW5nOnJpZ2h0X2xpbWl0Ijo2MC4wLCJUZXJyb3Jpc3Q6UnVubmluZzp5YXdfYWRkIjp0cnVlLCJUZXJyb3Jpc3Q6UnVubmluZzp5YXdfbGVmdCI6LTI2LjAsIlRlcnJvcmlzdDpSdW5uaW5nOnlhd19tb2RpZmllciI6IkRpc2FibGVkIiwiVGVycm9yaXN0OlJ1bm5pbmc6eWF3X29mZnNldCI6MC4wLCJUZXJyb3Jpc3Q6UnVubmluZzp5YXdfcmlnaHQiOjM1LjAsIlRlcnJvcmlzdDpTbmVha2luZzpib2R5X3lhdyI6IkppdHRlciIsIlRlcnJvcmlzdDpTbmVha2luZzpkZWZlbnNpdmVfY2hva2VfMSI6MTYuMCwiVGVycm9yaXN0OlNuZWFraW5nOmRlZmVuc2l2ZV9jaG9rZV8yIjoxNi4wLCJUZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX2N1c3RvbV9jaG9rZSI6ZmFsc2UsIlRlcnJvcmlzdDpTbmVha2luZzpkZWZlbnNpdmVfZW5hYmxlZCI6ZmFsc2UsIlRlcnJvcmlzdDpTbmVha2luZzpkZWZlbnNpdmVfZm9yY2VfZGVmZW5zaXZlIjpmYWxzZSwiVGVycm9yaXN0OlNuZWFraW5nOmRlZmVuc2l2ZV9waXRjaCI6IlN0YXRpYyIsIlRlcnJvcmlzdDpTbmVha2luZzpkZWZlbnNpdmVfcGl0Y2hfMSI6MC4wLCJUZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX3BpdGNoXzIiOjAuMCwiVGVycm9yaXN0OlNuZWFraW5nOmRlZmVuc2l2ZV9waXRjaF9vZmZzZXQiOjAuMCwiVGVycm9yaXN0OlNuZWFraW5nOmRlZmVuc2l2ZV9yYW5kb21fY2hva2UiOmZhbHNlLCJUZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX3JhbmRvbWl6YXRpb24iOjAuMCwiVGVycm9yaXN0OlNuZWFraW5nOmRlZmVuc2l2ZV95YXciOiJTdGF0aWMiLCJUZXJyb3Jpc3Q6U25lYWtpbmc6ZGVmZW5zaXZlX3lhd18xIjowLjAsIlRlcnJvcmlzdDpTbmVha2luZzpkZWZlbnNpdmVfeWF3XzIiOjAuMCwiVGVycm9yaXN0OlNuZWFraW5nOmRlZmVuc2l2ZV95YXdfb2Zmc2V0IjoxODAuMCwiVGVycm9yaXN0OlNuZWFraW5nOmRlZmVuc2l2ZV95YXdfc3BlZWQiOjIwLjAsIlRlcnJvcmlzdDpTbmVha2luZzpkZWxheV8xIjoxLjAsIlRlcnJvcmlzdDpTbmVha2luZzpkZWxheV8yIjowLjAsIlRlcnJvcmlzdDpTbmVha2luZzpsZWZ0X2xpbWl0Ijo2MC4wLCJUZXJyb3Jpc3Q6U25lYWtpbmc6bW9kaWZpZXJfb2Zmc2V0IjotMzUuMCwiVGVycm9yaXN0OlNuZWFraW5nOnJpZ2h0X2xpbWl0Ijo2MC4wLCJUZXJyb3Jpc3Q6U25lYWtpbmc6eWF3X2FkZCI6dHJ1ZSwiVGVycm9yaXN0OlNuZWFraW5nOnlhd19sZWZ0IjotMjcuMCwiVGVycm9yaXN0OlNuZWFraW5nOnlhd19tb2RpZmllciI6IkRpc2FibGVkIiwiVGVycm9yaXN0OlNuZWFraW5nOnlhd19vZmZzZXQiOjAuMCwiVGVycm9yaXN0OlNuZWFraW5nOnlhd19yaWdodCI6MzMuMCwiVGVycm9yaXN0OlN0YW5kaW5nOmJvZHlfeWF3IjoiSml0dGVyIiwiVGVycm9yaXN0OlN0YW5kaW5nOmRlZmVuc2l2ZV9jaG9rZV8xIjoxNi4wLCJUZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX2Nob2tlXzIiOjE2LjAsIlRlcnJvcmlzdDpTdGFuZGluZzpkZWZlbnNpdmVfY3VzdG9tX2Nob2tlIjpmYWxzZSwiVGVycm9yaXN0OlN0YW5kaW5nOmRlZmVuc2l2ZV9lbmFibGVkIjpmYWxzZSwiVGVycm9yaXN0OlN0YW5kaW5nOmRlZmVuc2l2ZV9mb3JjZV9kZWZlbnNpdmUiOmZhbHNlLCJUZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX3BpdGNoIjoiU3RhdGljIiwiVGVycm9yaXN0OlN0YW5kaW5nOmRlZmVuc2l2ZV9waXRjaF8xIjowLjAsIlRlcnJvcmlzdDpTdGFuZGluZzpkZWZlbnNpdmVfcGl0Y2hfMiI6MC4wLCJUZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX3BpdGNoX29mZnNldCI6MC4wLCJUZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX3JhbmRvbV9jaG9rZSI6ZmFsc2UsIlRlcnJvcmlzdDpTdGFuZGluZzpkZWZlbnNpdmVfcmFuZG9taXphdGlvbiI6MC4wLCJUZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX3lhdyI6IlN0YXRpYyIsIlRlcnJvcmlzdDpTdGFuZGluZzpkZWZlbnNpdmVfeWF3XzEiOjAuMCwiVGVycm9yaXN0OlN0YW5kaW5nOmRlZmVuc2l2ZV95YXdfMiI6MC4wLCJUZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX3lhd19vZmZzZXQiOjE4MC4wLCJUZXJyb3Jpc3Q6U3RhbmRpbmc6ZGVmZW5zaXZlX3lhd19zcGVlZCI6MjAuMCwiVGVycm9yaXN0OlN0YW5kaW5nOmRlbGF5XzEiOjEuMCwiVGVycm9yaXN0OlN0YW5kaW5nOmRlbGF5XzIiOjAuMCwiVGVycm9yaXN0OlN0YW5kaW5nOmxlZnRfbGltaXQiOjMwLjAsIlRlcnJvcmlzdDpTdGFuZGluZzptb2RpZmllcl9vZmZzZXQiOi00Ni4wLCJUZXJyb3Jpc3Q6U3RhbmRpbmc6cmlnaHRfbGltaXQiOjMwLjAsIlRlcnJvcmlzdDpTdGFuZGluZzp5YXdfYWRkIjp0cnVlLCJUZXJyb3Jpc3Q6U3RhbmRpbmc6eWF3X2xlZnQiOi0zMC4wLCJUZXJyb3Jpc3Q6U3RhbmRpbmc6eWF3X21vZGlmaWVyIjoiRGlzYWJsZWQiLCJUZXJyb3Jpc3Q6U3RhbmRpbmc6eWF3X29mZnNldCI6MC4wLCJUZXJyb3Jpc3Q6U3RhbmRpbmc6eWF3X3JpZ2h0IjozNC4wLCJUZXJyb3Jpc3Q6V2Fsa2luZzpib2R5X3lhdyI6IlJhbmRvbWl6ZSBKaXR0ZXIiLCJUZXJyb3Jpc3Q6V2Fsa2luZzpkZWZlbnNpdmVfY2hva2VfMSI6MTYuMCwiVGVycm9yaXN0OldhbGtpbmc6ZGVmZW5zaXZlX2Nob2tlXzIiOjE2LjAsIlRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV9jdXN0b21fY2hva2UiOmZhbHNlLCJUZXJyb3Jpc3Q6V2Fsa2luZzpkZWZlbnNpdmVfZW5hYmxlZCI6ZmFsc2UsIlRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV9mb3JjZV9kZWZlbnNpdmUiOmZhbHNlLCJUZXJyb3Jpc3Q6V2Fsa2luZzpkZWZlbnNpdmVfcGl0Y2giOiJTdGF0aWMiLCJUZXJyb3Jpc3Q6V2Fsa2luZzpkZWZlbnNpdmVfcGl0Y2hfMSI6MC4wLCJUZXJyb3Jpc3Q6V2Fsa2luZzpkZWZlbnNpdmVfcGl0Y2hfMiI6MC4wLCJUZXJyb3Jpc3Q6V2Fsa2luZzpkZWZlbnNpdmVfcGl0Y2hfb2Zmc2V0IjowLjAsIlRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV9yYW5kb21fY2hva2UiOmZhbHNlLCJUZXJyb3Jpc3Q6V2Fsa2luZzpkZWZlbnNpdmVfcmFuZG9taXphdGlvbiI6MC4wLCJUZXJyb3Jpc3Q6V2Fsa2luZzpkZWZlbnNpdmVfeWF3IjoiU3RhdGljIiwiVGVycm9yaXN0OldhbGtpbmc6ZGVmZW5zaXZlX3lhd18xIjowLjAsIlRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV95YXdfMiI6MC4wLCJUZXJyb3Jpc3Q6V2Fsa2luZzpkZWZlbnNpdmVfeWF3X29mZnNldCI6MTgwLjAsIlRlcnJvcmlzdDpXYWxraW5nOmRlZmVuc2l2ZV95YXdfc3BlZWQiOjIwLjAsIlRlcnJvcmlzdDpXYWxraW5nOmRlbGF5XzEiOjEuMCwiVGVycm9yaXN0OldhbGtpbmc6ZGVsYXlfMiI6Mi4wLCJUZXJyb3Jpc3Q6V2Fsa2luZzpsZWZ0X2xpbWl0Ijo2MC4wLCJUZXJyb3Jpc3Q6V2Fsa2luZzptb2RpZmllcl9vZmZzZXQiOi01LjAsIlRlcnJvcmlzdDpXYWxraW5nOnJpZ2h0X2xpbWl0Ijo2MC4wLCJUZXJyb3Jpc3Q6V2Fsa2luZzp5YXdfYWRkIjp0cnVlLCJUZXJyb3Jpc3Q6V2Fsa2luZzp5YXdfbGVmdCI6LTI1LjAsIlRlcnJvcmlzdDpXYWxraW5nOnlhd19tb2RpZmllciI6IkRpc2FibGVkIiwiVGVycm9yaXN0OldhbGtpbmc6eWF3X29mZnNldCI6MC4wLCJUZXJyb3Jpc3Q6V2Fsa2luZzp5YXdfcmlnaHQiOjM1LjAsImF2b2lkX2JhY2tzdGFiLmVuYWJsZWQiOnRydWUsImZsaWNrX2V4cGxvaXQuY29uZGl0aW9ucyI6W10sImZsaWNrX2V4cGxvaXQuZW5hYmxlZCI6ZmFsc2UsImZyZWVzdGFuZGluZy5kaXNhYmxlcnMiOlsiSW4gQWlyIiwiQWlyIENyb3VjaCJdLCJmcmVlc3RhbmRpbmcuZW5hYmxlZCI6ZmFsc2UsImZyZWVzdGFuZGluZy5zdGF0aWMiOmZhbHNlLCJtYW51YWxfeWF3LmRpcmVjdGlvbiI6IkRpc2FibGVkIiwibWFudWFsX3lhdy5kaXNhYmxlcnMiOltdLCJtYW51YWxfeWF3LnN0YXRpYyI6ZmFsc2UsIm1vZGlmeV9vbl93YXJtdXAuZW5hYmxlZCI6ZmFsc2UsIm9uX3VzZS5lbmFibGVkIjp0cnVlLCJzYWZlX2hlYWQuY29uZGl0aW9ucyI6WyJBaXIgS25pZmUiLCJEaXN0YW5jZSJdLCJzYWZlX2hlYWQuZW5hYmxlZCI6dHJ1ZX0sIk1pc2NlbGxhbmVvdXMiOnsiYXZvaWRfY29sbGlzaW9ucy5lbmFibGVkIjpmYWxzZSwiY2xhbnRhZy5lbmFibGVkIjp0cnVlLCJjb2xsaXNpb25fYWlyX2R1Y2suZW5hYmxlZCI6ZmFsc2UsImVkZ2Vfc3RvcC5lbmFibGVkIjpmYWxzZSwiZmFzdF9sYWRkZXIuZW5hYmxlZCI6dHJ1ZSwibm9fZmFsbF9kYW1hZ2UuZW5hYmxlZCI6dHJ1ZSwic3VwZXJfdG9zcy5lbmFibGVkIjp0cnVlLCJ0cmFzaHRhbGsuZGVsYXkiOjMwLjAsInRyYXNodGFsay5lbmFibGVkIjpmYWxzZSwidW5sb2NrX2ZkX3NwZWVkLmVuYWJsZWQiOnRydWV9LCJWaXN1YWxzIjp7ImFuaW1hdGlvbnMuZWFydGhxdWFrZSI6ZmFsc2UsImFuaW1hdGlvbnMuZW5hYmxlZCI6dHJ1ZSwiYW5pbWF0aW9ucy5pbl9haXIiOiJEaXNhYmxlZCIsImFuaW1hdGlvbnMubW92ZV9sZWFuIjoxMDAuMCwiYW5pbWF0aW9ucy5vbl9ncm91bmQiOiJEaXNhYmxlZCIsImFuaW1hdGlvbnMucGl0Y2hfb25fbGFuZCI6ZmFsc2UsImFuaW1hdGlvbnMuc2xpZGluZ19jcm91Y2giOmZhbHNlLCJhbmltYXRpb25zLnNsaWRpbmdfc2xvd3dhbGsiOmZhbHNlLCJhc3BlY3RfcmF0aW8uZW5hYmxlZCI6ZmFsc2UsImFzcGVjdF9yYXRpby5wcm9wb3J0aW9uIjowLjAsImNvbnNvbGVfY29sb3IuY29sb3IiOiI4MDgwODA5RSIsImNvbnNvbGVfY29sb3IuZW5hYmxlZCI6dHJ1ZSwiY3Jvc3NoYWlyX2luZGljYXRvcnMuY29sb3IiOiI4MDlCQ0VGRiIsImNyb3NzaGFpcl9pbmRpY2F0b3JzLmVuYWJsZWQiOnRydWUsImNyb3NzaGFpcl9pbmRpY2F0b3JzLm9mZnNldCI6NDAuMCwiZGFtYWdlX2luZGljYXRvci5jb2xvciI6IkZGRkZGRkZGIiwiZGFtYWdlX2luZGljYXRvci5lbmFibGVkIjp0cnVlLCJkYW1hZ2VfaW5kaWNhdG9yLmZvbnQiOiJTbWFsbCIsImhpdF9tYXJrZXIuY29sb3IiOiIwMDAwMDBGRiIsImhpdF9tYXJrZXIuZW5hYmxlZCI6dHJ1ZSwiaGl0X21hcmtlci5zaXplIjo0LjAsImhpdF9tYXJrZXIudGhpY2tuZXNzIjoyLjAsImtlZXBfdHJhbnNwYXJlbmN5LmVuYWJsZWQiOnRydWUsImxhZ19jb21wX2JveC5jb2xvciI6IjJGNzVEREZGIiwibGFnX2NvbXBfYm94LmVuYWJsZWQiOnRydWUsIm1hbnVhbF9hcnJvd3MuY29sb3IiOiJGRkZGRkZGRiIsIm1hbnVhbF9hcnJvd3MuZW5hYmxlZCI6dHJ1ZSwibWFudWFsX2Fycm93cy5vZmZzZXQiOjQwLjAsIm5hZGVfcmFkaXVzLmVuYWJsZWQiOnRydWUsIm5hZGVfcmFkaXVzLm1vbG90b3YiOnRydWUsIm5hZGVfcmFkaXVzLm1vbG90b3ZfY29sb3IiOiJEODYwNjBGRiIsIm5hZGVfcmFkaXVzLnNtb2tlIjp0cnVlLCJuYWRlX3JhZGl1cy5zbW9rZV9jb2xvciI6Ijg2OTRDNEZGIiwicmVtb3ZlX2Zvb3RzdGVwc19zaGFkb3cuZW5hYmxlZCI6dHJ1ZSwic2NvcGVfb3ZlcmxheS5hZGRpdGlvbnMiOltdLCJzY29wZV9vdmVybGF5LmNvbG9yIjoiRkZGRkZGOUUiLCJzY29wZV9vdmVybGF5LmVuYWJsZWQiOnRydWUsInNjb3BlX292ZXJsYXkuZXhjbHVkZV9saW5lcyI6W10sInNjb3BlX292ZXJsYXkuZ2FwIjowLjAsInNjb3BlX292ZXJsYXkuc2l6ZSI6NTUuMCwic2tlZXRfaW5kaWNhdG9ycy5lbmFibGVkIjp0cnVlLCJza2VldF9pbmRpY2F0b3JzLml0ZW1zIjpbMS4wLDIuMCwzLjAsNC4wLDUuMCw2LjAsNy4wLDguMCw5LjAsMTAuMCwxMS4wXSwidmVsb2NpdHlfd2FybmluZy5jb2xvciI6IjgwOUJDRUZGIiwidmVsb2NpdHlfd2FybmluZy5lbmFibGVkIjp0cnVlLCJ2ZWxvY2l0eV93YXJuaW5nLm9mZnNldCI6MTYwLjAsInZpZXdtb2RlbC5lbmFibGVkIjpmYWxzZSwidmlld21vZGVsLmZvdiI6NjgwLjAsInZpZXdtb2RlbC5vZmZzZXRfeCI6MjUuMCwidmlld21vZGVsLm9mZnNldF95IjowLjAsInZpZXdtb2RlbC5vZmZzZXRfeiI6LTE1LjB9fQ__");
            local add_builtin = function(find_preset)
                for index7 = #preset_list, 1, -1 do
                    local entry2 = preset_list[index7];
                    if entry2.name == find_preset then
                        return entry2, index7;
                    end;
                end;
                return nil, -1;
            end;
            local function preset_names()
                local names = {};
                for preset, index8 in pairs(preset_list) do
                    local label = index8.name;
                    if builtin_presets[preset] then
                        label = string.format("* %s", label);
                    end;
                    table.insert(names, label);
                end;
                if #names == 0 then
                    return {
                        [1] = "\aFFFFFF40Empty presets list..."
                    };
                else
                    return names;
                end;
            end;
            local function get_preset(arg36)
                return preset_list[arg36];
            end;
            local function refresh_presets()
                preset_list = {};
                for builtin, index9 in pairs(builtin_presets) do
                    table.insert(preset_list, index9);
                end;
                for saved, index10 in pairs(saved_presets) do
                    table.insert(preset_list, index10);
                end;
                presets_ui.list:update(preset_names());
            end;
            local function load_preset()
                local name = presets_ui.name:get();
                if name == "" then
                    return;
                else
                    local value8, _ = add_builtin(name);
                    if value8 == nil or value8.data == nil then
                        notify.error("Preset data is invalid!");
                        return;
                    else
                        local value9, value10 = presets.decode(value8.data);
                        data2 = value10;
                        success = value9;
                        if not success or data2 == nil then
                            notify.error(data2);
                            return;
                        else
                            value9, value10 = presets.import(data2);
                            data2 = value10;
                            success = value9;
                            if not success then
                                notify.error(data2);
                                return;
                            else
                                notify.success(string.format("%d groups successfully loaded!", data2));
                                return;
                            end;
                        end;
                    end;
                end;
            end;
            local function save_preset()
                local preset2 = presets_ui.name:get();
                if preset2 == "" then
                    return;
                else
                    local value11, value12 = presets.encode(presets.export());
                    data2 = value12;
                    success = value11;
                    if not success then
                        notify.error(data2);
                        return;
                    else
                        value11 = {
                            name = preset2,
                            data = data2
                        };
                        local value13;
                        value12, value13 = add_builtin(preset2);
                        if value12 == nil then
                            value12 = value11;
                            table.insert(saved_presets, value11);
                        end;
                        if value13 ~= -1 and value13 <= #builtin_presets then
                            notify.error("Can't modify built-in preset!");
                            return;
                        else
                            value12.data = data2;
                            db[presets_db_key] = saved_presets;
                            refresh_presets();
                            notify.success("Preset successfully saved!");
                            return;
                        end;
                    end;
                end;
            end;
            local function delete_preset()
                local name2 = presets_ui.name:get();
                if name2 == "" then
                    return;
                else
                    local value14, value15 = add_builtin(name2);
                    if value14 == nil then
                        notify.error("Preset not selected!");
                        return;
                    elseif value15 ~= -1 and value15 <= #builtin_presets then
                        notify.error("Can't delete built-in preset!");
                        return;
                    else
                        table.remove(saved_presets, value15 - #builtin_presets);
                        db[presets_db_key] = saved_presets;
                        refresh_presets();
                        notify.success("Preset successfully deleted!");
                        return;
                    end;
                end;
            end;
            local function import_preset()
                local name3, value16 = presets.decode(clipboard.get());
                if not name3 then
                    notify.error(value16);
                    return;
                else
                    local value17, value18 = presets.import(value16);
                    value16 = value18;
                    if not value17 then
                        notify.error(value16);
                        return;
                    else
                        notify.success(string.format("%d groups successfully imported!", value16));
                        return;
                    end;
                end;
            end;
            local function export_preset()
                local data, value19 = presets.encode(presets.export());
                if not data then
                    notify.error(value19);
                    return;
                else
                    clipboard.set(value19);
                    notify.success("Preset successfully exported!");
                    return;
                end;
            end;
            presets_ui.description = home_containers.description:label("##ss");
            -- Keep the shared HUD accent in the Home / preset area, next to the saved sets.
            source_controls.accent_color = presets.push("Visuals", "accent_color", home_containers.presets:color_picker(concat(debug_overlay_box(2), small_label("palette"), debug_overlay_box(7), "Accent Color"), color4(192, 202, 255, 255)));
            presets_ui.name = home_containers.presets:input("Preset Name");
            presets_ui.load_button = home_containers.presets:button(pad_text(icons.get("check"), 5), load_preset, false);
            presets_ui.save_button = home_containers.presets:button(pad_text(small_label("floppy-disk"), 7), save_preset, true);
            presets_ui.delete_button = home_containers.presets:button(pad_text(concat("\aFF5050FF", icons.get("trash-can")), 7), delete_preset, true);
            presets_ui.export_button = home_containers.presets:button(pad_text(icons.get("up-from-bracket"), 7), export_preset, true);
            presets_ui.import_button = home_containers.presets:button(pad_text(icons.get("down-to-bracket"), 7), import_preset, true);
            presets_ui.list = home_containers.presets:list("##main.list", {});
            presets_ui.list:set_callback(function(arg37)
                local index11 = arg37:get();
                if index11 == nil or index11 <= 0 then
                    return;
                else
                    local value20 = get_preset(index11);
                    if value20 == nil then
                        return;
                    else
                        print(value20.desc);
                        if value20.desc == nil then
                            presets_ui.description:visibility(false);
                            presets_ui.description:name("");
                        else
                            presets_ui.description:visibility(true);
                            presets_ui.description:name(value20.desc);
                        end;
                        presets_ui.name:set(value20.name);
                        return;
                    end;
                end;
            end, true);
            refresh_presets();
            presets_tab.main = presets_ui;
        end;
        presets.bind(presets_tab.categories);
        home_tab.presets = presets_tab;
    end;
    debug_overlay_line.home = home_tab;
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
            enabled = presets.push("Anti-Aim", "avoid_backstab.enabled", antiaim_tabs.tweaks:switch(concat(debug_overlay_box(2), small_label("knife-kitchen"), debug_overlay_box(7), "Avoid Backstab")))
        },
        on_use = {
            enabled = presets.push("Anti-Aim", "on_use.enabled", antiaim_tabs.tweaks:switch(concat(debug_overlay_box(2), small_label("user-helmet-safety"), debug_overlay_box(7), "On Use")))
        },
        modify_on_warmup = {
            enabled = presets.push("Anti-Aim", "modify_on_warmup.enabled", antiaim_tabs.tweaks:switch(concat(debug_overlay_box(2), small_label("shuffle"), debug_overlay_box(7), "Modify on Warmup")))
        }
    };
    local preset_list = {
        enabled = presets.push("Anti-Aim", "flick_exploit.enabled", antiaim_tabs.tweaks:switch(concat(debug_overlay_box(2), small_label("wand-magic-sparkles"), debug_overlay_box(7), "Flick Exploit")))
    };
    local builtin_presets = preset_list.enabled:create();
    preset_list.conditions = presets.push("Anti-Aim", "flick_exploit.conditions", builtin_presets:selectable("Conditions", {
        [1] = "Standing",
        [2] = "Walking",
        [3] = "Crouching",
        [4] = "Sneaking"
    }));
    presets_tab.flick_exploit = preset_list;
    local builtin_presets = {
        enabled = presets.push("Anti-Aim", "safe_head.enabled", antiaim_tabs.tweaks:switch(concat(debug_overlay_box(2), small_label("face-head-bandage"), debug_overlay_box(7), "Safe Head")))
    };
    local container = builtin_presets.enabled:create();
    builtin_presets.conditions = presets.push("Anti-Aim", "safe_head.conditions", container:selectable("Conditions", {
        [1] = "Standing",
        [2] = "Crouch",
        [3] = "Air Crouch",
        [4] = "Air Knife",
        [5] = "Air Taser",
        [6] = "Distance"
    }));
    presets_tab.safe_head = builtin_presets;
    source_controls.lc_enabled=presets.push("Anti-Aim","auto_lc.enabled",antiaim_tabs.tweaks:switch(concat(debug_overlay_box(5),small_label("bolt"),debug_overlay_box(7),"Auto LC"),true))
    home_icon.tweaks = presets_tab;
    local presets_ui = {};
    local presets_db_key = {
        enabled = presets.push("Anti-Aim", "freestanding.enabled", antiaim_tabs.hotkeys:switch(concat(debug_overlay_box(2), small_label("compass"), debug_overlay_box(7), "Freestanding")))
    };
    local saved_presets = presets_db_key.enabled:create();
    presets_db_key.static = presets.push("Anti-Aim", "freestanding.static", saved_presets:switch("Static Freestanding"));
    presets_db_key.disablers = presets.push("Anti-Aim", "freestanding.disablers", saved_presets:selectable("Disablers", {
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
        direction = presets.push("Anti-Aim", "manual_yaw.direction", antiaim_tabs.hotkeys:combo(concat(debug_overlay_box(2), small_label("arrows-left-right"), debug_overlay_box(7), "Manual Yaw"), {
            [1] = "Disabled",
            [2] = "Left",
            [3] = "Right",
            [4] = "Backward",
            [5] = "Forward"
        }))
    };
    local preset_list = saved_presets.direction:create();
    saved_presets.static = presets.push("Anti-Aim", "manual_yaw.static", preset_list:switch("Static Manual Yaw"));
    saved_presets.disablers = presets.push("Anti-Aim", "manual_yaw.disablers", preset_list:selectable("Disablers", {
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
            defensive2.force_defensive = presets.push("Anti-Aim", defensive_key("force_defensive"), antiaim_tabs.defensive:switch(hidden_id(section_label("Force Defensive"), defensive_key("force_defensive"))));
            local container2 = defensive2.force_defensive:create();
            defensive2.custom_choke = presets.push("Anti-Aim", defensive_key("custom_choke"), container2:switch("Custom Choke"));
            defensive2.random_choke = presets.push("Anti-Aim", defensive_key("random_choke"), container2:switch("Randomize Choke"));
            defensive2.choke_1 = presets.push("Anti-Aim", defensive_key("choke_1"), container2:slider("Choke", 1, 22, 16, nil, "t"));
            defensive2.choke_2 = presets.push("Anti-Aim", defensive_key("choke_2"), container2:slider("2nd Choke", 1, 22, 16, nil, "t"));
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
            defensive2.enabled = presets.push("Anti-Aim", defensive_key("enabled"), antiaim_tabs.defensive:switch(hidden_id(section_label("Hidden", "\a{Link Active}"), defensive_key("enabled")))):set_callback(presets_db_key);
            defensive2.pitch = presets.push("Anti-Aim", defensive_key("pitch"), antiaim_tabs.defensive:combo(hidden_id(section_label("Pitch"), defensive_key("pitch")), {
                [1] = "Static",
                [2] = "Jitter",
                [3] = "Random",
                [4] = "Spin",
                [5] = "Sway"
            }));
            value21 = defensive2.pitch:create();
            defensive2.pitch_offset = presets.push("Anti-Aim", defensive_key("pitch_offset"), value21:slider("Offset", -89, 89, 0, 1, "\194\176"));
            defensive2.pitch_1 = presets.push("Anti-Aim", defensive_key("pitch_1"), value21:slider("From", -89, 89, 0, 1, "\194\176"));
            defensive2.pitch_2 = presets.push("Anti-Aim", defensive_key("pitch_2"), value21:slider("To", -89, 89, 0, 1, "\194\176"));
            update_choke_visibility = nil;
            local function update_pitch_visibility()
                local method = defensive2.pitch:get();
                defensive2.pitch_offset:visibility(method == "Static");
                defensive2.pitch_1:visibility(method ~= "Static");
                defensive2.pitch_2:visibility(method ~= "Static");
            end;
            defensive2.pitch:set_callback(update_pitch_visibility, true);
            defensive2.yaw = presets.push("Anti-Aim", defensive_key("yaw"), antiaim_tabs.defensive:combo(hidden_id(section_label("Yaw"), defensive_key("yaw")), {
                [1] = "Static",
                [2] = "Switch",
                [3] = "Random",
                [4] = "Spin",
                [5] = "Sway",
                [6] = "Distortion",
                [7] = "Ember Spin"
            }));
            update_choke_visibility = defensive2.yaw:create();
            defensive2.yaw_offset = presets.push("Anti-Aim", defensive_key("yaw_offset"), update_choke_visibility:slider("Offset", 0, 360, 180, 1, "\194\176"));
            defensive2.yaw_1 = presets.push("Anti-Aim", defensive_key("yaw_1"), update_choke_visibility:slider("From", -180, 180, 0, 1, "\194\176"));
            defensive2.yaw_2 = presets.push("Anti-Aim", defensive_key("yaw_2"), update_choke_visibility:slider("To", -180, 180, 0, 1, "\194\176"));
            defensive2.randomization = presets.push("Anti-Aim", defensive_key("randomization"), update_choke_visibility:slider("Randomization", 0, 20, 0, 1, "\194\176"));
            defensive2.yaw_speed = presets.push("Anti-Aim", defensive_key("yaw_speed"), update_choke_visibility:slider("Speed", -50, 50, 20, 0.1));
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
            angles2.yaw_offset = presets.push("Anti-Aim", angles_key("yaw_offset"), antiaim_tabs.builder:slider(hidden_id(section_label("Yaw Offset"), angles_key("yaw_offset")), -180, 180, 0, nil, "\194\176"));
            angles2.yaw_add = presets.push("Anti-Aim", angles_key("yaw_add"), antiaim_tabs.builder:switch(hidden_id(section_label("Yaw Add"), angles_key("yaw_add"))));
            local container3 = angles2.yaw_add:create();
            angles2.yaw_left = presets.push("Anti-Aim", angles_key("yaw_left"), container3:slider("Left Offset", -180, 180, 0, nil, "\194\176"));
            angles2.yaw_right = presets.push("Anti-Aim", angles_key("yaw_right"), container3:slider("Right Offset", -180, 180, 0, nil, "\194\176"));
            local function update_yaw_add_visibility()
                local enabled2 = angles2.yaw_add:get();
                angles2.yaw_left:visibility(enabled2);
                angles2.yaw_right:visibility(enabled2);
            end;
            angles2.yaw_add:set_callback(update_yaw_add_visibility, true);
            angles2.yaw_modifier = presets.push("Anti-Aim", angles_key("yaw_modifier"), antiaim_tabs.builder:combo(hidden_id(section_label("Yaw Modifier"), angles_key("yaw_modifier")), {
                [1] = "Disabled",
                [2] = "Center",
                [3] = "Offset",
                [4] = "Random",
                [5] = "Spin",
                [6] = "3-Way",
                [7] = "5-Way"
            }));
            update_yaw_add_visibility = angles2.yaw_modifier:create();
            angles2.modifier_offset = presets.push("Anti-Aim", angles_key("modifier_offset"), update_yaw_add_visibility:slider("Offset", -180, 180, 0, nil, "\194\176"));
            local function update_modifier_visibility()
                local method3 = angles2.yaw_modifier:get();
                angles2.modifier_offset:visibility(method3 ~= "Disabled");
            end;
            angles2.yaw_modifier:set_callback(update_modifier_visibility, true);
            angles2.body_yaw = presets.push("Anti-Aim", angles_key("body_yaw"), antiaim_tabs.builder:combo(hidden_id(section_label("Body Yaw"), angles_key("body_yaw")), {
                [1] = "Disabled",
                [2] = "Left",
                [3] = "Right",
                [4] = "Jitter",
                [5] = "Randomize Jitter"
            }));
            update_modifier_visibility = angles2.body_yaw:create();
            angles2.left_limit = presets.push("Anti-Aim", angles_key("left_limit"), update_modifier_visibility:slider("Left Limit", 0, 60, 60, nil, "\194\176"));
            angles2.right_limit = presets.push("Anti-Aim", angles_key("right_limit"), update_modifier_visibility:slider("Right Limit", 0, 60, 60, nil, "\194\176"));
            angles2.delay_1 = presets.push("Anti-Aim", angles_key("delay_1"), update_modifier_visibility:slider("Delay", 0, 16, 0, nil, "t"));
            angles2.delay_2 = presets.push("Anti-Aim", angles_key("delay_2"), update_modifier_visibility:slider("2nd Delay", 0, 16, 0, nil, "t"));
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
            for controls, index12 in pairs(collect_state_values) do
                local control2 = collect_state_values[controls];
                if control2 ~= nil then
                    values[controls] = {};
                    for key2, _2 in pairs(index12) do
                        local control_value = control2[key2];
                        if control_value ~= nil then
                            values[controls][key2] = control_value:get();
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
            state_actions:button(pad_text(concat(small_label("arrow-up-from-bracket"), debug_overlay_box(7), "Copy"), 5), export_state, true);
            state_actions:button(pad_text(concat(small_label("arrow-down-to-bracket"), debug_overlay_box(7), "Paste"), 5), import_state, true);
            state_actions:button(pad_text(concat(small_label("send-backward"), debug_overlay_box(7), "Send to another team"), 3), send_to_other_team, true);
            home_icon.builder = builtin_presets;
        end;
        presets_db_key();
        debug_overlay_line.antiaim = home_icon;
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
    source_controls.extrap=presets.push("Miscellaneous","source.extrapolation",presets_tab.aimbot:switch(concat(debug_overlay_box(2),small_label("arrows-left-right"),debug_overlay_box(7),"Extrapolation"),false))
    source_controls.force=presets.push("Miscellaneous","source.force_interpolation",presets_tab.aimbot:switch(concat(debug_overlay_box(2),small_label("arrows-rotate"),debug_overlay_box(7),"Force Interpolation"),false))
    home_containers.category = presets_tab.category:list("##category", {
        section_label("Rage"),
        section_label("Visuals"),
        section_label("Misc")
    });
    do
        local presets_ui = function(select_category)
            local index14 = select_category:get();
            presets_tab.aimbot:visibility(index14 == 1);
            presets_tab.interface:visibility(index14 == 2);
            presets_tab.visuals:visibility(index14 == 2);
            presets_tab.misc:visibility(index14 == 2);
            presets_tab.movement:visibility(index14 == 3);
            presets_tab.shared:visibility(index14 == 3);
        end;
        local presets_db_key = function(update_category_labels)
            local state4 = update_category_labels:get();
            local items = update_category_labels:list();
            local labels = {};
            for index15 = 1, #items do
                local item = items[index15];
                if state4 == index15 then
                    labels[index15] = item:gsub("\a{Small Text}", "\a{Link Active}");
                else
                    labels[index15] = item:gsub("\a{Link Active}", "\a{Small Text}");
                end;
            end;
            update_category_labels:update(labels);
        end;
        local saved_presets = function(on_category_change)
            presets_ui(on_category_change);
            presets_db_key(on_category_change);
        end;
        home_containers.category:set_callback(saved_presets, true);
        local preset_list = {};
        if config.build ~= "Live" then
            local builtin_presets = {
                enabled = presets.push("Rage", "dormant_aimbot.enabled", presets_tab.aimbot:switch(concat(debug_overlay_box(2), small_label("person-rays"), debug_overlay_box(7), "Dormant Aimbot")))
            };
            local container = builtin_presets.enabled:create();
            builtin_presets.hitboxes = presets.push("Rage", "dormant_aimbot.hitboxes", container:selectable("Hitboxes", {
                [1] = "Head",
                [2] = "Chest",
                [3] = "Stomach",
                [4] = "Legs"
            }));
            ensure_defaults(builtin_presets.hitboxes);
            builtin_presets.accuracy = presets.push("Rage", "dormant_aimbot.accuracy", container:slider("Accuracy", 1, 100, 60, nil, "%"));
            builtin_presets.min_damage = presets.push("Rage", "dormant_aimbot.min_damage", container:slider("Min. damage", 0, 130, 10, nil, function(arg44)
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
                enabled = presets.push("Rage", "ai_peek.enabled", presets_tab.aimbot:switch(concat(debug_overlay_box(2), small_label("microchip-ai"), debug_overlay_box(7), "AI Peek")))
            };
            local container = builtin_presets.enabled:create();
            builtin_presets.hitboxes = presets.push("Rage", "ai_peek.hitboxes", container:selectable("Hitboxes", {
                [1] = "Head",
                [2] = "Chest",
                [3] = "Stomach",
                [4] = "Arms",
                [5] = "Legs",
                [6] = "Feet"
            }));
            ensure_defaults(builtin_presets.hitboxes);
            builtin_presets.weapons = presets.push("Rage", "ai_peek.weapons", container:selectable("Weapons", {
                [1] = "SSG 08",
                [2] = "R8 Revolver",
                [3] = "Desert Eagle",
                [4] = "Pistol",
                [5] = "Rifle",
                [6] = "Shotgun"
            }));
            ensure_defaults(builtin_presets.weapons);
            builtin_presets.dots = presets.push("Rage", "ai_peek.dots", container:slider("Dots", 1, 10, 4));
            builtin_presets.radius = presets.push("Rage", "ai_peek.radius", container:slider("Radius", 32, 64, 32));
            builtin_presets.color = presets.push("Rage", "ai_peek.color", container:color_picker("Color"));
            preset_list.ai_peek = builtin_presets;
        end;
        do
            local container = {
                enabled = presets.push("Rage", "maxusrcmdprocessticks.enabled", presets_tab.aimbot:switch(concat(debug_overlay_box(2), small_label("code-compare"), debug_overlay_box(7), "Max User Process Ticks")))
            };
            local container4 = container.enabled:create();
            container.ticks = presets.push("Rage", "maxusrcmdprocessticks.ticks", container4:slider("Value", 8, 32, 16, nil, function(arg45)
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
            preset_list.fake_latency = {
                enabled = presets.push("Rage", "fake_latency.enabled", presets_tab.aimbot:switch(concat(debug_overlay_box(2), small_label("satellite-dish"), debug_overlay_box(7), "Unlock Fake Latency")))
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
                local item=presets_tab.interface:switch(concat(debug_overlay_box(2),small_label(def.icon),debug_overlay_box(7),def.label),false)
                local g=item:create()
                local panel={enabled=presets.push("Visuals","panels."..id,item)}
                panel.x=presets.push("Visuals","panels."..id..".x",g:slider("Horizontal",0,1000,def.x,0.1,"%"))
                panel.y=presets.push("Visuals","panels."..id..".y",g:slider("Vertical",0,1000,def.y,0.1,"%"))
                if id=="watermark" then
                    panel.items=presets.push("Visuals","panels.watermark.items",g:selectable("Details",{"User","Latency","FPS","Time"}))
                    panel.items:set({"User","Latency","FPS","Time"})
                    source_controls.hud_blur=presets.push("Visuals","panels.blur",g:switch(concat(debug_overlay_box(2),small_label("layers"),debug_overlay_box(7),"Blur"),false))
                end
                panel.x:visibility(false);panel.y:visibility(false)
                source_controls[id]=panel
            end
        end
        -- Notifications intentionally has one control only. The switch controls
        -- on-screen cards; hit/miss console messages are always emitted.
        local notifications = {
            enabled = presets.push("Visuals", "log_events.enabled", presets_tab.interface:switch(concat(debug_overlay_box(2), small_label("bell"), debug_overlay_box(7), "Notifications")))
        }
        builtin_presets.notifications = notifications
        local container = {
            enabled = presets.push("Visuals", "crosshair_indicators.enabled", presets_tab.interface:switch(concat(debug_overlay_box(2), small_label("crosshairs"), debug_overlay_box(7), "Crosshair Indicators")))
        };
        local container4 = container.enabled:create();
        container.items = presets.push("Visuals", "crosshair_indicators.items", container4:selectable("Indicators", {"DT","HS","FS"}))
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
            enabled = presets.push("Visuals", "damage_indicator.enabled", presets_tab.interface:switch(concat(debug_overlay_box(2), small_label("hundred-points"), debug_overlay_box(7), "Damage Indicator")))
        };
        builtin_presets.damage_indicator = container5;
        local container6 = {
            enabled = presets.push("Visuals", "velocity_warning.enabled", presets_tab.interface:switch(concat(debug_overlay_box(2), small_label("chart-line"), debug_overlay_box(7), "Velocity Indicator")))
        };
        builtin_presets.velocity_warning = container6;
        local screen_size = {
            enabled = presets.push("Visuals", "animations.enabled", presets_tab.visuals:switch(concat(debug_overlay_box(2), small_label("layer-group"), debug_overlay_box(7), "Animations")))
        };
        local container8 = screen_size.enabled:create();
        local animation_modes = {
            [1] = "Disabled",
            [2] = "Static",
            [3] = "Walking",
            [4] = "Jitter",
            [5] = "Kangaroo"
        };
        screen_size.on_ground = presets.push("Visuals", "animations.on_ground", container8:combo("On Ground", animation_modes));
        screen_size.in_air = presets.push("Visuals", "animations.in_air", container8:combo("In Air", animation_modes));
        screen_size.pitch_on_land = presets.push("Visuals", "animations.pitch_on_land", container8:switch("0 Pitch on Land"));
        screen_size.sliding_slowwalk = presets.push("Visuals", "animations.sliding_slowwalk", container8:switch("Sliding Slow Walk"));
        screen_size.sliding_crouch = presets.push("Visuals", "animations.sliding_crouch", container8:switch("Sliding Crouch"));
        screen_size.earthquake = presets.push("Visuals", "animations.earthquake", container8:switch("Earthquake"));
        screen_size.move_lean = presets.push("Visuals", "animations.move_lean", container8:slider("Move Lean", 0, 100, 0, nil, "%"));
         
        do
            local function enabled4(arg52)
                container8:visibility(arg52:get());
            end;
            screen_size.enabled:set_callback(enabled4, true);
            builtin_presets.animations = screen_size;
        end;
        local container8 = {
            enabled = presets.push("Visuals", "hit_marker.enabled", presets_tab.visuals:switch(concat(debug_overlay_box(2), small_label("xmark-large"), debug_overlay_box(7), "Hit Marker")))
        };
        local animation_modes = container8.enabled:create();
        container8.size = presets.push("Visuals", "hit_marker.size", animation_modes:slider("Size", 2, 5, 4, nil, "px"));
        container8.thickness = presets.push("Visuals", "hit_marker.thickness", animation_modes:slider("Thickness", 1, 5, 2, nil, "px"));
        container8.color = presets.push("Visuals", "hit_marker.color", animation_modes:color_picker("Color", color4(0, 255, 255, 255)));
        local container9 = nil;
        do
            local function on_toggle6(arg53)
                animation_modes:visibility(arg53:get());
            end;
            container8.enabled:set_callback(on_toggle6, true);
            builtin_presets.hit_marker = container8;
        end;
        local animation_modes = {
            enabled = presets.push("Visuals", "scope_overlay.enabled", presets_tab.visuals:switch(concat(debug_overlay_box(2), small_label("crosshairs-simple"), debug_overlay_box(7), "Scope Overlay")))
        };
        local container9 = animation_modes.enabled:create();
        animation_modes.additions = presets.push("Visuals", "scope_overlay.additions", container9:selectable("Additions", {
            [1] = "Inverted",
            [2] = "Rotated",
            [3] = "Spread Dependency"
        }));
        animation_modes.exclude_lines = presets.push("Visuals", "scope_overlay.exclude_lines", container9:selectable("Exclude Lines", {
            [1] = "Left",
            [2] = "Right",
            [3] = "Top",
            [4] = "Bottom"
        }));
        animation_modes.size = presets.push("Visuals", "scope_overlay.size", container9:slider("Size", 0, 300, 50, nil, "px"));
        animation_modes.gap = presets.push("Visuals", "scope_overlay.gap", container9:slider("Gap", 0, 300, 5, nil, "px"));
        animation_modes.color = presets.push("Visuals", "scope_overlay.color", container9:color_picker("Color", color4(255, 255, 255, 255)));
        local container10 = nil;
        do
            local function on_toggle7(arg54)
                container9:visibility(arg54:get());
            end;
            animation_modes.enabled:set_callback(on_toggle7, true);
            builtin_presets.scope_overlay = animation_modes;
        end;
        local container9 = {
            enabled = presets.push("Visuals", "nade_radius.enabled", presets_tab.visuals:switch(concat(debug_overlay_box(2), small_label("fire"), debug_overlay_box(7), "Nade Radius")))
        };
        local container10 = container9.enabled:create();
        container9.molotov = presets.push("Visuals", "nade_radius.molotov", container10:switch("Molotov"));
        container9.molotov_color = presets.push("Visuals", "nade_radius.molotov_color", container9.molotov:color_picker(color4(255, 63, 63, 255)));
        container9.smoke = presets.push("Visuals", "nade_radius.smoke", container10:switch("Smoke"));
        container9.smoke_color = presets.push("Visuals", "nade_radius.smoke_color", container9.smoke:color_picker(color4(61, 147, 250, 255)));
        local container11 = nil;
        do
            local function on_toggle8(arg55)
                container10:visibility(arg55:get());
            end;
            container9.enabled:set_callback(on_toggle8, true);
            builtin_presets.nade_radius = container9;
        end;
        local container11 = {
            enabled = presets.push("Visuals", "console_color.enabled", presets_tab.visuals:switch(concat(debug_overlay_box(2), small_label("rectangle-terminal"), debug_overlay_box(7), "Console Color")))
        };
        container11.color = presets.push("Visuals", "console_color.color", container11.enabled:color_picker(color4(128, 128, 128, 255)));
         
        do
            local function update_color_visibility(arg57)
                container11.color:visibility(arg57:get());
            end;
            container11.enabled:set_callback(update_color_visibility, true);
            builtin_presets.console_color = container11;
            local container12 = {
                enabled = presets.push("Visuals", "aspect_ratio.enabled", presets_tab.misc:switch(concat(debug_overlay_box(2), small_label("tv"), debug_overlay_box(7), "Aspect Ratio")))
            };
            local update_color_visibility = container12.enabled:create();
            local aspect_ratios = {
                [1] = "5:4",
                [2] = "4:3",
                [3] = "3:2",
                [4] = "16:10",
                [5] = "16:9"
            };
            local aspect_values = {
                ["4:3"] = 133,
                ["5:4"] = 125,
                ["16:9"] = 177,
                ["16:10"] = 160,
                ["3:2"] = 150
            };
            local aspect_lookup = {};
            for index16 = 1, #aspect_ratios do
                local ratio = aspect_ratios[index16];
                aspect_lookup[aspect_values[ratio]] = ratio;
            end;
            do
                local function aspect_label(arg58)
                    if arg58 == 0 then
                        return "Off";
                    else
                        return aspect_lookup[arg58];
                    end;
                end;
                container12.proportion = presets.push("Visuals", "aspect_ratio.proportion", update_color_visibility:slider("Aspect Ratio", 0, 200, 0, 0.01, aspect_label));
                for index17 = 1, #aspect_ratios do
                    local ratio2 = aspect_ratios[index17];
                    local value30 = aspect_values[ratio2];
                    do
                        local function set_aspect()
                            container12.proportion:set(value30);
                        end;
                        update_color_visibility:button(pad_text(ratio2, 3), set_aspect, true);
                    end;
                end;
            end;
             
            do
                local aspect_values = function(on_toggle10)
                    update_color_visibility:visibility(on_toggle10:get());
                end;
                container12.enabled:set_callback(aspect_values, true);
                builtin_presets.aspect_ratio = container12;
            end;
            local update_color_visibility = {
                enabled = presets.push("Visuals", "viewmodel.enabled", presets_tab.misc:switch(concat(debug_overlay_box(2), small_label("hand"), debug_overlay_box(7), "Viewmodel")))
            };
            local aspect_ratios = update_color_visibility.enabled:create();
            update_color_visibility.fov = presets.push("Visuals", "viewmodel.fov", aspect_ratios:slider("Field of View", 0, 1000, 680, 0.1, "\194\176"));
            update_color_visibility.offset_x = presets.push("Visuals", "viewmodel.offset_x", aspect_ratios:slider("Offset X", -100, 100, 25, 0.1, "\194\176"));
            update_color_visibility.offset_y = presets.push("Visuals", "viewmodel.offset_y", aspect_ratios:slider("Offset Y", -100, 100, 0, 0.1, "\194\176"));
            update_color_visibility.offset_z = presets.push("Visuals", "viewmodel.offset_z", aspect_ratios:slider("Offset Z", -100, 100, -15, 0.1, "\194\176"));
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
                enabled = presets.push("Visuals", "keep_transparency.enabled", presets_tab.misc:switch(concat(debug_overlay_box(2), small_label("transporter-2"), debug_overlay_box(7), "Keep Transparency")))
            };
            builtin_presets.remove_footsteps_shadow = {
                enabled = presets.push("Visuals", "remove_footsteps_shadow.enabled", presets_tab.misc:switch(concat(debug_overlay_box(2), small_label("shoe-prints"), debug_overlay_box(7), "Remove Footsteps Shadow")))
            };
            home_containers.visuals = builtin_presets;
        end;
        local container = {
            avoid_collisions = {
                enabled = presets.push("Miscellaneous", "avoid_collisions.enabled", presets_tab.movement:switch(concat(debug_overlay_box(2), small_label("person-rays"), debug_overlay_box(7), "Avoid Collisions")))
            },
            collision_air_duck = {
                enabled = presets.push("Miscellaneous", "collision_air_duck.enabled", presets_tab.movement:switch(concat(debug_overlay_box(2), small_label("person-walking-dashed-line-arrow-right"), debug_overlay_box(7), "Collision Air Duck")))
            },
            fast_ladder = {
                enabled = presets.push("Miscellaneous", "fast_ladder.enabled", presets_tab.movement:switch(concat(debug_overlay_box(2), small_label("water-ladder"), debug_overlay_box(7), "Fast Ladder")))
            },
            super_toss = {
                enabled = presets.push("Miscellaneous", "super_toss.enabled", presets_tab.movement:switch(concat(debug_overlay_box(2), small_label("bomb"), debug_overlay_box(7), "Super Toss")))
            },
            edge_stop = {
                enabled = presets.push("Miscellaneous", "edge_stop.enabled", presets_tab.movement:switch(concat(debug_overlay_box(2), small_label("person-falling-burst"), debug_overlay_box(7), "Edge Stop")))
            },
            no_fall_damage = {
                enabled = presets.push("Miscellaneous", "no_fall_damage.enabled", presets_tab.movement:switch(concat(debug_overlay_box(2), small_label("person-arrow-up-from-line"), debug_overlay_box(7), "No Fall Damage")))
            },
            unlock_fd_speed = {
                enabled = presets.push("Miscellaneous", "unlock_fd_speed.enabled", presets_tab.movement:switch(concat(debug_overlay_box(2), small_label("duck"), debug_overlay_box(7), "Unlock FD Speed")))
            }
        };
        do
            local item=presets.push("Miscellaneous","trashtalk.enabled",presets_tab.shared:switch(concat(debug_overlay_box(2),small_label("trash-can"),debug_overlay_box(7),"Trash Talk")))
            local talk_gear=item:create()
            local talk={enabled=item}
            talk.style=presets.push("Miscellaneous","trashtalk.style",talk_gear:combo("Language",{"English","Русский"}))
            talk.kill=presets.push("Miscellaneous","trashtalk.kill",talk_gear:switch("Kill Phrases",true))
            talk.death=presets.push("Miscellaneous","trashtalk.death",talk_gear:switch("Death Phrases",false))
            source_controls.talk=talk;container.trashtalk={enabled=item}
            item:set_callback(function()talk_gear:visibility(item:get())end,true)
        end
        do
            local item=presets.push("Miscellaneous","clantag.enabled",presets_tab.shared:switch(concat(debug_overlay_box(2),small_label("tags"),debug_overlay_box(7),"Clan Tag")))
            local tag_gear=item:create()
            local tag={enabled=item}
            tag.mode=presets.push("Miscellaneous","clantag.mode",tag_gear:combo("Tag Preset",{"Social","Custom","Femboy","Buyme"}))
            tag.custom=presets.push("Miscellaneous","clantag.custom",tag_gear:input("Custom Tag"))
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
        debug_overlay_line.other = home_containers;
    end;
end;
 
local debug_overlay_box = {
    is_moving = false,
    is_onground = false,
    is_crouched = false,
    sent_packets = 0,
    duck_amount = 0,
    velocity2d_sqr = 0,
    side = -1,
    desync_delta = 0
};
local pad_text = function(on_createmove_state)
    local cmd = entity.get_local_player();
    if cmd == nil then
        return;
    else
        local value31 = cmd.m_fFlags;
        local value32 = cmd.m_vecVelocity;
        local value33 = cmd.m_flDuckAmount;
        local value34 = bit.band(value31, 1) ~= 0;
        local value35 = math.abs(cmd.m_flPoseParameter[11] * 2 - 1);
        local value36 = value32:length2dsqr();
        debug_overlay_box.is_moving = value36 > 25;
        debug_overlay_box.is_onground = value34;
        debug_overlay_box.is_crouched = value33 > 0.5 or on_createmove_state.in_duck == true;
        if on_createmove_state.choked_commands == 0 then
            debug_overlay_box.sent_packets = debug_overlay_box.sent_packets + 1;
            debug_overlay_box.duck_amount = value33;
            debug_overlay_box.desync_delta = value35;
        end;
        debug_overlay_box.velocity2d_sqr = value36;
        if on_createmove_state.sidemove ~= 0 then
            debug_overlay_box.side = on_createmove_state.sidemove < 0 and -1 or 1;
        end;
        return;
    end;
end;
events.createmove(pad_text);
 
local pad_text = {};
local hidden_id = {};
local small_label = 0;
do
    local function push_state(arg59)
        small_label = small_label + 1;
        hidden_id[small_label] = arg59;
    end;
    local function clear_states()
        for index18 = 1, small_label do
            hidden_id[index18] = nil;
        end;
        small_label = 0;
    end;
    local function push_ground_states()
        if not debug_overlay_box.is_onground then
            return;
        elseif debug_overlay_box.is_moving then
            push_state("Running");
            if debug_overlay_box.is_crouched then
                return;
            else
                if api.antiaim.misc.slow_walk:get() then
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
        if not debug_overlay_box.is_crouched then
            return;
        else
            push_state("Crouching");
            if debug_overlay_box.is_moving then
                push_state("Sneaking");
            end;
            return;
        end;
    end;
    local function push_air_states()
        if debug_overlay_box.is_onground then
            return;
        else
            push_state("In Air");
            if debug_overlay_box.is_crouched then
                push_state("Air Crouch");
            end;
            return;
        end;
    end;
    pad_text.get = function()
        return hidden_id[#hidden_id];
    end;
    local function update_state_stack()
        clear_states();
        push_ground_states();
        push_duck_states();
        push_air_states();
    end;
    events.createmove(update_state_stack);
end;
 
local hidden_id = {
    get = function()
        local local_player = entity.get_local_player();
        if local_player == nil then
            return;
        else
            local value37 = local_player.m_iTeamNum;
            if value37 == 2 then
                return "Terrorist";
            elseif value37 == 3 then
                return "Counter-Terrorist";
            else
                return;
            end;
        end;
    end
};
 
local small_label = {};
local function gradient_text(arg60, arg61, arg62)
    local out = "";
    local length = #arg60 - 1;
    local step_r = (arg62.r - arg61.r) / length;
    local step_g = (arg62.g - arg61.g) / length;
    local step_b = (arg62.b - arg61.b) / length;
    local step_a = (arg62.a - arg61.a) / length;
    for index19 = 1, length + 1 do
        out = out .. "\a" .. arg61:to_hex() .. arg60:sub(index19, index19);
        arg61.r = arg61.r + step_r;
        arg61.g = arg61.g + step_g;
        arg61.b = arg61.b + step_b;
        arg61.a = arg61.a + step_a;
    end;
    return out;
end;
local function random_char()
    local used = {};
    local charset = "abcdefghijklmnopqrstuvwxyz0123456789@#$&*+-/=?_";
    local index20 = nil;
    repeat
        index20 = math.random(1, #charset);
    until not used[index20];
    used[index20] = true;
    return charset:sub(index20, index20);
end;
do
    small_label.matrix = function(matrix_text, arg63, arg64)
        arg63 = arg63:clone();
        arg64 = arg64:clone();
        local push_state2 = "";
        local cut = math.abs(globals.realtime * 0.4 % 2 - 1) * (#matrix_text + 1);
        cut = math.max(0, math.min(cut, #matrix_text));
        local garbage = "";
        for push_duck_states2 = 1, #matrix_text do
            garbage = garbage .. random_char();
        end;
        return matrix_text:sub(1, cut) .. gradient_text(garbage.sub(garbage, cut + 1), arg63, arg64);
    end;
end;

local random_char = {};
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
local angle_refs = api.antiaim.angles;
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
    random_char.buffer = angles_state;
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
                api.rage.main.double_tap_lag_options:override("Always On")
                api.rage.main.hide_shots_options:override("Break LC")
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
            local fake_duck = api.antiaim.misc.fake_duck:get();
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
    local set_override = debug_overlay_line.antiaim.builder;
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
            local state6 = pad_text.get();
            local team4 = hidden_id.get();
            if state6 == nil or team4 == nil then
                return false, nil;
            else
                local _10, value50 = self8:apply(team4, state6);
                return true, value50;
            end;
        end;
    end;
    local set_override = {};
    local state_meta = debug_overlay_line.antiaim.tweaks.avoid_backstab;
    do
        set_override.update = function(self9)
            angles_state.avoid_backstab = state_meta.enabled:get();
        end;
    end;
    local state_meta = {};
    local apply_yaw = debug_overlay_line.antiaim.tweaks.on_use;
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
    local apply_modifier = debug_overlay_line.antiaim.tweaks.modify_on_warmup;
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
    local apply_body_yaw = debug_overlay_line.antiaim.tweaks.flick_exploit;
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
                            local value70 = pad_text.get();
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
                api.rage.main.hide_shots_options:override("Break LC");
                api.rage.main.double_tap_lag_options:override("Always On");
                aa_hidden_pitch(89);
                aa_hidden_yaw(-90);
                if arg90.command_number % 7 == 0 then arg90.force_defensive=true end;
                return true;
            end;
        end;
    end;
    local apply_body_yaw = {};
    local apply_freestanding = debug_overlay_line.antiaim.tweaks.safe_head;
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
                if debug_overlay_box.is_onground then
                    if (not debug_overlay_box.is_moving or debug_overlay_box.is_crouched) and value76 >= 10 and apply_extended < value77 then
                        return "Distance";
                    else
                        if debug_overlay_box.is_crouched then
                            if value76 >= 48 then
                                return "Crouch";
                            end;
                        elseif not debug_overlay_box.is_moving and value76 >= 24 then
                            return "Standing";
                        end;
                        return nil;
                    end;
                else
                    if debug_overlay_box.is_crouched then
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
            if (knife or taser) and debug_overlay_box.is_crouched then
                local conditions=apply_freestanding.conditions
                if debug_overlay_box.is_onground then
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
    local apply_extended = debug_overlay_line.antiaim.hotkeys.freestanding;
    do
        local function self14()
            return apply_extended.static:get();
        end;
        local function self15()
            local state7 = pad_text.get();
            if state7 == nil then
                return false;
            else
                return apply_extended.disablers:get(state7);
            end;
        end;
        apply_freestanding.update = function(self16)
            if not apply_extended.enabled:get() then
                return false;
            elseif self15() then
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
                if self14() then angles_state.freestanding_body_yaw = "Off" end;
                local wall=aa_patch.wall and aa_patch.wall()
                if wall then
                    angles_state.yaw_base="Local View"
                    angles_state.yaw_offset=math.normalize_yaw(wall-render.camera_angles().y-180)
                    angles_state.freestanding=false
                    angles_state.body_freestanding=false
                    angles_state.freestanding_body_yaw="Off"
                end
                return true;
            end;
        end;
    end;
    local apply_extended = {};
    local manual_yaw = debug_overlay_line.antiaim.hotkeys.manual_yaw;
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
            local state8 = pad_text.get();
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
    local function update_hide_angles()

    end;
    local function update_fake_lag()
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
        update_fake_lag();
        update_hide_angles();
        update_flick();
    end;
    local function reset_overrides()
        aa_release_hidden()
        angles_state:clear()
        angles_state:unset()
        api.rage.main.double_tap_lag_options:override()
        api.rage.main.hide_shots_options:override()
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
        local profile=tostring(hidden_id.get())..":"..tostring(pad_text.get())
        if aa_patch.profile~=profile then angle_refs:reset();aa_patch.profile=profile end
        if aa_patch.command~=cmd.command_number then aa_patch.command=cmd.command_number;aa_patch.draws={} end
        angles_state:clear()
        angles_state:unset()
        api.rage.main.double_tap_lag_options:override()
        api.rage.main.hide_shots_options:override()
        local owner=offsets(cmd)
        local scope=tostring(hidden_id.get())..":"..tostring(pad_text.get())..":"..tostring(owner)
            ..":"..tostring(angles_state.body_yaw)..":"..tostring(angles_state.delay_1)..":"..tostring(angles_state.delay_2)
        if aa_patch.owner~=scope then
            tick_count,counter,switch_state,flags=0,0,false,true
            aa_patch.packet_cmd=nil
            aa_patch.owner=scope
        end
        on_shutdown(cmd)
        if not angles_state.hidden then aa_release_hidden() end
        angles_state:set()
        if aa_patch.lc then aa_patch.lc(cmd,owner,pad_text.get(),angles_state.hidden) end
    end
    events.level_init(function()reset_overrides();local_key=nil;last_tick=nil end)
    local _4 = nil;
    events.shutdown(reset_overrides);
    events.createmove(on_createmove);
end;
 
if config.build ~= "Live" then
     
    local flags = debug_overlay_line.other.aimbot.dormant_aimbot;
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
                        elseif arg101.in_jump or not debug_overlay_box.is_onground then
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
        local _11 = nil;
        local function on_toggle13(arg103)
            local value104 = arg103:get();
            events.createmove(on_createmove_hitbox, value104);
        end;
        flags.enabled:set_callback(on_toggle13, true);
    end;
end;
if config.build == "Alpha" then
     
    local flags = debug_overlay_line.other.aimbot.ai_peek;
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
    local _12 = 10;
    local value111 = 0;
    local _13 = 1;
    local _14 = 2;
    local value112 = 3;
    local _15 = 4;
    local value113 = 5;
    local _16 = 6;
    local value114 = 7;
    local value115 = 8;
    local value116 = 9;
    local value117 = 10;
    local value118 = 11;
    local value119 = 12;
    local _17 = 13;
    local _18 = 14;
    local value120 = 15;
    local _19 = 16;
    local value121 = 17;
    local _20 = 18;
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
            api.rage.main.double_tap:override();
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
                local target, _21 = trace(arg143, fraction4, fraction5, function(arg151)
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
                        local value133 = api.rage.selection.min_damage:get();
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
                overlay.box_new(counter.point, mins2, maxs, vector(), edge_color, color, globals.tickinterval * 2);
                return;
            elseif counter.retreat == -1 then
                return;
            else
                local value148 = move_towards(arg155, arg156, counter.retreat_point);
                reset_moves(arg155);
                counter.retreat = counter.retreat + 1;
                if counter.retreat >= 3 then
                    api.rage.main.double_tap:override(false);
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
        local fraction2 = nil;
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
 
local flags = debug_overlay_line.other.visuals.notifications;
local counter = 6;
local angles_state = 24;
local angle_refs = {};
local function notification_accent()
    local visual = debug_overlay_line.other.visuals
    if visual and visual.accent_color then
        local ok, value = pcall(function() return visual.accent_color:get() end)
        if ok and value ~= nil then return value end
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
    local function unset_override()
        angle_refs = {}
    end

    local function set_override(event_color, message, label)
        -- The single Notifications switch controls only the on-screen queue.
        if not flags.enabled:get() then return end

        table.insert(angle_refs, 1, {
            text = message,
            color = event_color or notification_accent(),
            label = label or "EVENT",
            time = 4.25,
            duration = 4.25,
            alpha = 0,
            slide = 10
        })

        -- Keep the overlay readable during busy rounds.
        while #angle_refs > 3 do
            table.remove(angle_refs)
        end
    end

    local notification_key = "social.notifications.position"
    local notification_position = db[notification_key]
    if type(notification_position) ~= "table"
        or type(notification_position.x) ~= "number"
        or type(notification_position.y) ~= "number" then
        notification_position = nil
    end

    local notification_bounds, notification_drag, notification_context = nil, nil, nil
    local notification_left_before, notification_right_before = false, false

    local function reset_notification_position(all)
        notification_position = nil
        db[notification_key] = nil
        if all and source_controls.reset_all_positions then
            source_controls.reset_all_positions()
        end
    end

    local function state_meta()
        local screen = render.screen_size()
        local font_bank = source_controls.fonts or {}
        local font_title = font_bank.title or font_bank.detail or font_bank.body or 1
        local font_body = font_bank.detail or font_bank.body or 1
        local menu_open = ui.get_alpha() > 0.5
        local enabled = flags.enabled:get()
        local dt = math.min(math.max(globals.frametime or 0, 0), 0.1)

        for i = #angle_refs, 1, -1 do
            local entry = angle_refs[i]
            entry.time = entry.time - dt
            entry.alpha = math.min(1, (entry.alpha or 0) + dt * 10)
            entry.slide = math.max(0, (entry.slide or 0) - dt * 80)
            if entry.time <= 0 then
                table.remove(angle_refs, i)
            end
        end

        local entries = {}
        if enabled then
            if menu_open then
                entries = {
                    {text="Hit player in head for 84 damage", color=notification_accent(), label="HIT", time=1, duration=1, alpha=1, slide=0, preview=true},
                    {text="Missed player due to spread", color=notification_accent(), label="MISS", time=1, duration=1, alpha=1, slide=0, preview=true}
                }
            else
                for i = 1, math.min(3, #angle_refs) do
                    entries[#entries + 1] = angle_refs[i]
                end
            end
        end

        local card_w, card_h, gap = 304, 48, 7
        local total_h = #entries > 0 and (#entries * card_h + (#entries - 1) * gap) or 0
        local x = screen.x - card_w - 24
        local y = math.max(18, math.floor(screen.y * 0.66 - total_h / 2))
        if notification_position then
            x = notification_position.x / 1000 * screen.x
            y = notification_position.y / 1000 * screen.y
        end
        x = math.clamp(x, 0, math.max(0, screen.x - card_w))
        y = math.clamp(y, 0, math.max(0, screen.y - math.max(total_h, card_h)))
        notification_bounds = total_h > 0 and {x=x, y=y, w=card_w, h=total_h} or nil

        local mouse = ui.get_mouse_position()
        local left = common.is_button_down(1) == true
        local right = common.is_button_down(2) == true
        local menu_pos, menu_size = ui.get_position(), ui.get_size()
        local over_menu = mouse and mouse.x >= menu_pos.x and mouse.x <= menu_pos.x + menu_size.x
            and mouse.y >= menu_pos.y and mouse.y <= menu_pos.y + menu_size.y

        if not menu_open then
            if notification_drag and notification_position then
                db[notification_key] = notification_position
            end
            notification_drag, notification_context = nil, nil
        elseif notification_context then
            if left and not notification_left_before then
                if mouse and mouse.x >= notification_context.x and mouse.x <= notification_context.x + notification_context.w
                    and mouse.y >= notification_context.y and mouse.y <= notification_context.y + notification_context.h then
                    local row = math.floor((mouse.y - notification_context.y) / 25) + 1
                    if row == 1 then
                        reset_notification_position(false)
                    elseif row == 2 then
                        reset_notification_position(true)
                    end
                end
                notification_context = nil
            elseif right and not notification_right_before then
                notification_context = nil
            end
        elseif not over_menu then
            local over_notification = mouse and notification_bounds
                and mouse.x >= notification_bounds.x and mouse.x <= notification_bounds.x + notification_bounds.w
                and mouse.y >= notification_bounds.y and mouse.y <= notification_bounds.y + notification_bounds.h
            if right and not notification_right_before and over_notification then
                notification_context = {
                    x = math.clamp(mouse.x, 0, math.max(0, screen.x - 174)),
                    y = math.clamp(mouse.y, 0, math.max(0, screen.y - 54)),
                    w = 174,
                    h = 50
                }
            elseif left and not notification_left_before and over_notification then
                notification_drag = {dx=mouse.x-x, dy=mouse.y-y}
            end
        end

        if notification_drag and left and mouse then
            x = math.clamp(mouse.x - notification_drag.dx, 0, math.max(0, screen.x - card_w))
            y = math.clamp(mouse.y - notification_drag.dy, 0, math.max(0, screen.y - math.max(total_h, card_h)))
            notification_position = {x=x/screen.x*1000, y=y/screen.y*1000}
            db[notification_key] = notification_position
            notification_bounds = total_h > 0 and {x=x, y=y, w=card_w, h=total_h} or nil
        elseif notification_drag and not left then
            notification_drag = nil
            if notification_position then db[notification_key] = notification_position end
        end

        local function fit_message(value, max_width)
            value = tostring(value):gsub("[\r\n\t]", " ")
            if render.measure_text(font_body, nil, value).x <= max_width then return value end
            local chars = {}
            for char in value:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
                chars[#chars + 1] = char
            end
            while #chars > 0 and render.measure_text(font_body, nil, table.concat(chars) .. "…").x > max_width do
                chars[#chars] = nil
            end
            return table.concat(chars) .. "…"
        end

        for i, entry in ipairs(entries) do
            local alpha = entry.preview and 1 or math.min(1, math.max(0, math.min(entry.alpha or 0, entry.time / 0.38)))
            local event_color = entry.color or notification_accent()
            local top = y + (i - 1) * (card_h + gap) - (entry.preview and 0 or (entry.slide or 0))
            local label = tostring(entry.label or "EVENT"):upper()
            local message = tostring(entry.text or ""):gsub("\a[%x][%x][%x][%x][%x][%x][%x][%x]", "")
            local a = math.floor(255 * alpha)
            local accent_color = color(event_color.r, event_color.g, event_color.b, a)

            if source_controls.hud_blur and source_controls.hud_blur:get() then
                render.blur(vector(x, top), vector(x + card_w, top + card_h), 1, alpha, 7)
            end
            render.rect(vector(x, top), vector(x + card_w, top + card_h), color(12, 15, 22, math.floor(205 * alpha)), 7)
            render.rect_outline(vector(x, top), vector(x + card_w, top + card_h), color(255, 255, 255, math.floor(22 * alpha)), 1, 7)
            render.rect(vector(x + 8, top + 9), vector(x + 10, top + card_h - 9), accent_color, 1)
            render.circle(vector(x + 20, top + 16), accent_color, 2.5, 0, 1)
            render.text(font_title, vector(x + 30, top + 7), color(239, 242, 249, a), nil, label)
            local clean_message = fit_message(message, card_w - 43)
            render.text(font_body, vector(x + 30, top + 25), color(220, 226, 238, a), nil, clean_message)

            local remaining = entry.preview and 1 or math.min(1, math.max(0, entry.time / (entry.duration or 4.25)))
            render.rect(vector(x + 12, top + card_h - 3), vector(x + card_w - 12, top + card_h - 2), color(255, 255, 255, math.floor(18 * alpha)))
            if remaining > 0 then
                render.rect(vector(x + 12, top + card_h - 3), vector(x + 12 + (card_w - 24) * remaining, top + card_h - 2), color(event_color.r, event_color.g, event_color.b, math.floor(205 * alpha)))
            end
        end

        if notification_context then
            render.rect(vector(notification_context.x, notification_context.y), vector(notification_context.x + notification_context.w, notification_context.y + notification_context.h), color(13, 17, 23, 238), 6)
            render.rect_outline(vector(notification_context.x, notification_context.y), vector(notification_context.x + notification_context.w, notification_context.y + notification_context.h), color(255, 255, 255, 24), 1, 6)
            local labels = {"Reset position", "Reset all positions"}
            for i, label in ipairs(labels) do
                local yy = notification_context.y + (i - 1) * 25
                if mouse and mouse.x >= notification_context.x and mouse.x <= notification_context.x + notification_context.w and mouse.y >= yy and mouse.y <= yy + 25 then
                    render.rect(vector(notification_context.x + 3, yy + 2), vector(notification_context.x + notification_context.w - 3, yy + 23), color(255, 255, 255, 13), 4)
                end
                render.text(font_body, vector(notification_context.x + 10, yy + 5), color(232, 237, 246), nil, label)
            end
        end

        notification_left_before = left
        notification_right_before = right
    end

    events.render(state_meta, true)
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
    local function print_dev_msg(arg167, arg168)
        return "\aA9BBFFFFsocial\a697489FF / \a"..arg168:to_hex().."shot\a697489FF  |  \aC3CCDDFF"..arg167;
    end;
    local function print_dev_raw(arg169, arg170)
        -- Debug-console output was removed with the old notification settings.
    end
    local function print_raw_msg(arg171, arg172)
        -- Combat hit/miss logs are unconditional and independent of Notifications.
        print_raw(print_dev_msg(arg172, arg171))
    end
    local function hitgroup_name(arg173)
        return hitgroup_names[arg173] or "?";
    end;
    local function update_hit(arg174)
        local target_name = arg174.target;
        if target_name == nil then
            return;
        else
            local value155 = "Hit";
            if not arg174.target:is_alive() then
                value155 = "Killed";
            end;
            local value156 = target_name:get_name();
            local value157 = hitgroup_name(arg174.hitgroup);
            local value158 = hitgroup_name(arg174.wanted_hitgroup);
            local value159 = arg174.damage;
            local value160 = arg174.wanted_damage;
            local value161 = arg174.hitchance;
            local value162 = arg174.backtrack;
            local value163 = notification_hit_color();
            local value164 = nil;
            value164 = string.format("%s ${%s} in ${%s} for ${%s} damage", value155, value156, value157, value159);
            value164 = format_message(value164, value163);
            local value165 = nil;
            if value157 ~= value158 then
                value157 = string.format("%s(%s)", value157, value158);
            end;
            if value159 ~= value160 then
                value159 = string.format("%s(%d)", value159, value160);
            end;
            local value166 = {};
            local value167 = " \194\183 ";
            table.insert(value166, string.format("hc: ${%d%%}", value161));
            table.insert(value166, string.format("bt: ${%dt}", value162));
            value166 = table.concat(value166, value167);
            value165 = string.format("%s ${%s} in ${%s} for ${%s} damage (%s)", value155, value156, value157, value159, value166);
            value165 = format_message(value165, value163);
            set_override(value163, value164, "HIT");
            print_dev_raw(value163, value165);
            print_raw_msg(value163, value165);
            return;
        end;
    end;
    local function reset_overrides2(arg175)
        local shot = arg175.target;
        if shot == nil then
            return;
        else
            local value168 = shot:get_name();
            local value169 = hitgroup_name(arg175.wanted_hitgroup);
            local value170 = arg175.state;
            local value171 = arg175.hitchance;
            local value172 = arg175.backtrack;
            local value173 = notification_miss_color();
            local value174 = nil;
            value174 = string.format("Missed ${%s}'s ${%s} due to ${%s}", value168, value169, value170);
            value174 = format_message(value174, value173);
            local value175 = nil;
            local value176 = {};
            local value177 = " \194\183 ";
            table.insert(value176, string.format("hc: ${%d%%}", value171));
            table.insert(value176, string.format("bt: ${%dt}", value172));
            value176 = table.concat(value176, value177);
            value175 = string.format("Missed ${%s}'s ${%s} due to ${%s} (%s)", value168, value169, value170, value176);
            value175 = format_message(value175, value173);
            set_override(value173, value174, "MISS");
            print_dev_raw(value173, value175);
            print_raw_msg(value173, value175);
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
                local value179 = attacker:get_name();
                local value180 = arg177.dmg_health;
                local value181 = notification_hit_color();
                local value182 = string.format("%s ${%s} for ${%d} damage", value178, value179, value180);
                value182 = format_message(value182, value181);
                set_override(value181, value182, "DAMAGE");
                print_dev_raw(value181, value182);
                print_raw_msg(value181, value182);
                return;
            end;
        end;
    end;
    local get_hitbox_config2 = nil;
    local function on_toggle15(arg179)
        if not arg179:get() then unset_override() end
    end
    -- Event callbacks stay registered so console hit/miss logs are unconditional.
    events.player_hurt(on_player_hurt, true)
    events.aim_ack(damage2, true)
    flags.enabled:set_callback(on_toggle15, true)
end;
 
local counter = debug_overlay_line.other.aimbot.maxusrcmdprocessticks;
local angles_state = cvar.sv_maxusrcmdprocessticks;
do
    local angle_refs = function()
        angles_state:int(tonumber(angles_state:string()), true);
    end;
    local unset_override = function()
        angles_state:int(counter.ticks:get(), true);
    end;
    local set_override = function()
        angle_refs();
    end;
     
    local function on_log_events(_25)
        unset_override();
    end;
    do
        local function on_toggle16(arg180)
            local value183 = arg180:get();
            if value183 then
                counter.ticks:set_callback(on_log_events);
                unset_override();
            else
                counter.ticks:unset_callback(on_log_events);
                angle_refs();
            end;
            events.shutdown(set_override, value183);
        end;
        counter.enabled:set_callback(on_toggle16, true);
    end;
end;
 
local angles_state = debug_overlay_line.other.aimbot.fake_latency;
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
    local distance2 = nil;
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

local tick_flag = debug_overlay_line.other.visuals.scope_overlay;
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
                ready_flag = interp.interp(ready_flag, value328.m_bIsScoped, 0.05);
                if ready_flag <= 0 then
                    return;
                else
                    api.visuals.world.main.scope_overlay:override("Remove All");
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
            api.visuals.world.main.scope_overlay:override();
        end;
        events.render(state_flag, value348);
    end;
    tick_flag.enabled:set_callback(update_hit_indicator, true);
end;
 
local ready_flag = debug_overlay_line.other.visuals.aspect_ratio;
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
 
local state_flag = debug_overlay_line.other.visuals.viewmodel;
local target_flag = cvar.viewmodel_fov;
local update_hit_indicator = cvar.viewmodel_offset_x;
local update_indicators = cvar.viewmodel_offset_y;
local hitbox_ticks = cvar.viewmodel_offset_z;
do
    local image_size = function()
        target_flag:float(tonumber(target_flag:string()), true);
        update_hit_indicator:float(tonumber(update_hit_indicator:string()), true);
        update_indicators:float(tonumber(update_indicators:string()), true);
        hitbox_ticks:float(tonumber(hitbox_ticks:string()), true);
    end;
    local bomb_image = function()
        target_flag:float(state_flag.fov:get() * 0.1, true);
        update_hit_indicator:float(state_flag.offset_x:get() * 0.1, true);
        update_indicators:float(state_flag.offset_y:get() * 0.1, true);
        hitbox_ticks:float(state_flag.offset_z:get() * 0.1, true);
    end;
    local shadow_color = function()
        image_size();
    end;
     
    local get_control_value = function(arg228)
        local value349 = arg228:get();
        if value349 then
            state_flag.fov:set_callback(bomb_image);
            state_flag.offset_x:set_callback(bomb_image);
            state_flag.offset_y:set_callback(bomb_image);
            state_flag.offset_z:set_callback(bomb_image);
            bomb_image();
        else
            state_flag.fov:unset_callback(bomb_image);
            state_flag.offset_x:unset_callback(bomb_image);
            state_flag.offset_y:unset_callback(bomb_image);
            state_flag.offset_z:unset_callback(bomb_image);
            image_size();
        end;
        events.shutdown(shadow_color, value349);
    end;
    state_flag.enabled:set_callback(get_control_value, true);
end;
 
local target_flag = debug_overlay_line.other.visuals.animations;
local update_hit_indicator = ffi.typeof("                struct {\n                    float  m_flLayerAnimtime;\n                    float  m_flLayerFadeOuttime;\n        \n                    // dispatch flags\n                    void  *m_pDispatchedStudioHdr;\n                    int    m_nDispatchedSrc;\n                    int    m_nDispatchedDst;\n        \n                    int    m_nOrder;\n                    int    m_nSequence;\n                    float  m_flPrevCycle;\n                    float  m_flWeight;\n                    float  m_flWeightDeltaRate;\n        \n                    // used for automatic crossfades between sequence changes;\n                    float  m_flPlaybackRate;\n                    float  m_flCycle;\n                    int    m_pOwner;\n                    int    m_nInvalidatePhysicsBits;\n                } **\n            ");
do
    local update_indicators = function(arg229)
        return ffi.cast(update_hit_indicator, ffi.cast("uintptr_t", arg229[0]) + 10640)[0];
    end;
    local hitbox_ticks = 6;
    local image_size = 12;
    local bomb_image = function(arg230)
        local value352 = target_flag.on_ground:get();
        if value352 == "Static" then
            arg230.m_flPoseParameter[0] = 1;
            api.antiaim.misc.leg_movement:override("Sliding");
            return;
        elseif value352 == "Jitter" then
            if globals.tickcount % 4 > 1 then
                arg230.m_flPoseParameter[0] = 1;
                arg230.m_flPoseParameter[1] = 1;
            end;
            api.antiaim.misc.leg_movement:override("Sliding");
            return;
        elseif value352 == "Walking" then
            arg230.m_flPoseParameter[7] = 0;
            api.antiaim.misc.leg_movement:override("Walking");
            return;
        elseif value352 == "Kangaroo" then
            arg230.m_flPoseParameter[0] = utils.random_float(0, 1);
            api.antiaim.misc.leg_movement:override("Sliding");
            return;
        else
            api.antiaim.misc.leg_movement:override();
            return;
        end;
    end;
    local shadow_color = function(arg231)
        local value353 = target_flag.in_air:get();
        if value353 == "Static" then
            arg231.m_flPoseParameter[6] = 1;
            return;
        elseif value353 == "Jitter" then
            arg231.m_flPoseParameter[6] = globals.tickcount % 4 > 1 and 1 or 0;
            return;
        elseif value353 == "Walking" then
            local value354 = update_indicators(arg231);
            if value354 == nil then
                return;
            else
                local value355 = value354[hitbox_ticks];
                if value355 == nil then
                    return;
                else
                    value355.m_flWeight = 1;
                    return;
                end;
            end;
        elseif value353 == "Kangaroo" then
            arg231.m_flPoseParameter[6] = utils.random_float(0.1, 1);
            return;
        else
            return;
        end;
    end;
    local empty_color = function(arg232)
        if not target_flag.pitch_on_land:get() then
            return;
        else
            local value356 = arg232:get_anim_state();
            if value356 == nil or not value356.landing then
                return;
            else
                arg232.m_flPoseParameter[12] = 0.5;
                return;
            end;
        end;
    end;
    local get_control_value = function(arg233)
        if not target_flag.sliding_slowwalk:get() then
            return;
        else
            arg233.m_flPoseParameter[9] = 0;
            return;
        end;
    end;
    local find_bind = function(arg234)
        if not target_flag.sliding_crouch:get() then
            return;
        else
            arg234.m_flPoseParameter[8] = 0;
            return;
        end;
    end;
    local lerp_ratio = function(arg235)
        local value357 = update_indicators(arg235);
        if value357 == nil then
            return;
        else
            local value358 = value357[image_size];
            if value358 == nil then
                return;
            elseif target_flag.earthquake:get() then
                value358.m_flWeight = utils.random_float(0, 1);
                return;
            else
                local value359 = target_flag.move_lean:get();
                if value359 == -1 then
                    return;
                else
                    value358.m_flWeight = value359 * 0.01;
                    return;
                end;
            end;
        end;
    end;
    local function value350(arg236)
        local value360 = entity.get_local_player();
        if arg236 ~= value360 then
            return;
        else
            bomb_image(value360);
            shadow_color(value360);
            empty_color(value360);
            get_control_value(value360);
            find_bind(value360);
            lerp_ratio(value360);
            return;
        end;
    end;
    local _27 = nil;
    local function value351(arg237)
        local value361 = arg237:get();
        if not value361 then
            api.antiaim.misc.leg_movement:override();
        end;
        events.post_update_clientside_animation(value350, value361);
    end;
    target_flag.enabled:set_callback(value351, true);
end;
 
local update_hit_indicator = debug_overlay_line.other.visuals.nade_radius;
do
    local update_indicators = function()
        if entity.get_local_player() == nil then
            return;
        else
            local value362 = update_hit_indicator.molotov_color:get();
            local value363 = update_hit_indicator.smoke_color:get();
            if update_hit_indicator.molotov:get() then
                entity.get_entities("CInferno", nil, function(arg238)
                    local value364 = arg238:get_origin();
                    local value365 = arg238:get_bbox();
                    local value366 = value362:clone();
                    value366.a = value366.a * value365.alpha;
                    render.circle_3d_outline(value364, value366, 125, 0, 1, 1.5);
                end);
            end;
            if update_hit_indicator.smoke:get() then
                entity.get_entities("CSmokeGrenadeProjectile", nil, function(arg239)
                    if not arg239.m_bDidSmokeEffect then
                        return;
                    else
                        local value367 = arg239:get_origin();
                        local value368 = arg239:get_bbox();
                        local value369 = value363:clone();
                        value369.a = value369.a * value368.alpha;
                        render.circle_3d_outline(value367, value369, 125, 0, 1, 1.5);
                        return;
                    end;
                end);
            end;
            return;
        end;
    end;
     
    local image_size = function(arg240)
        events.render(update_indicators, arg240:get());
    end;
    update_hit_indicator.enabled:set_callback(image_size, true);
end;
 
local hitbox_ticks = debug_overlay_line.other.visuals.console_color;
local image_size = utils.get_vfunc("engine.dll", "VEngineClient014", 11, "bool(__thiscall*)(void*)");
local bomb_image = {
    [1] = materials.get_materials("vgui_white")[1],
    [2] = materials.get_materials("vgui/hud/800corner1")[1],
    [3] = materials.get_materials("vgui/hud/800corner2")[1],
    [4] = materials.get_materials("vgui/hud/800corner3")[1],
    [5] = materials.get_materials("vgui/hud/800corner4")[1]
};
do
    local shadow_color = function()
        for value382 = 1, #bomb_image do
            bomb_image[value382]:reset();
        end;
    end;
    local empty_color = function(arg246)
        local value383 = arg246.a / 255;
        for value384 = 1, #bomb_image do
            local value385 = bomb_image[value384];
            value385:alpha_modulate(value383);
            value385:color_modulate(arg246);
        end;
    end;
    local get_control_value = function()
        if not image_size() then
            empty_color(color4(255, 255, 255, 255));
        else
            empty_color(hitbox_ticks.color:get());
        end;
    end;
    local find_bind = function()
        shadow_color();
    end;
     
    local function value381(arg247)
        local value386 = arg247:get();
        if not value386 then
            shadow_color();
        end;
        events.shutdown(find_bind, value386);
        events.pre_render(get_control_value, value386);
    end;
    hitbox_ticks.enabled:set_callback(value381, true);
end;
 
local image_size = debug_overlay_line.other.visuals.keep_transparency;
local bomb_image = function(_28)
    local value387 = entity.get_local_player();
    if value387 == nil then
        return;
    else
        local value388 = value387.m_bIsScoped;
        local value389 = value387.m_bResumeZoom;
        if not value388 and not value389 then
            return;
        else
            return 59;
        end;
    end;
end;
 
do
    local empty_color = function(arg248)
        events.localplayer_transparency(bomb_image, arg248:get());
    end;
    image_size.enabled:set_callback(empty_color, true);
end;
 
local bomb_image = debug_overlay_line.other.visuals.remove_footsteps_shadow;
local shadow_color = cvar.cl_foot_contact_shadows;
do
    local empty_color = function()
        shadow_color:int(0, true);
    end;
    local get_control_value = function()
        shadow_color:int(tonumber(shadow_color:string()), true);
    end;
    local find_bind = function()
        get_control_value();
    end;
     
    local function value390(arg249)
        local value391 = arg249:get();
        if value391 then
            empty_color();
        else
            get_control_value();
        end;
        events.shutdown(find_bind, value391);
    end;
    bomb_image.enabled:set_callback(value390, true);
end;

local angles_state = debug_overlay_line.other.misc.avoid_collisions;
local angle_refs = function(arg250)
    local value392 = entity.get_local_player();
    if value392 == nil then
        return;
    else
        local value393 = value392.m_fFlags;
        if bit.band(value393, 1) == 1 then
            return;
        elseif arg250.in_duck or arg250.in_speed then
            return;
        else
            local value394 = render.camera_angles();
            local value395 = value392.m_vecOrigin;
            local value396 = value392.m_vecVelocity;
            value396.z = 0;
            local value397 = value392.m_vecMins;
            local value398 = value392.m_vecMaxs;
            local value399 = vector():angles(0, value394.y);
            local value400 = value399:vectors();
            local value401 = vector(value399.x * arg250.forwardmove + value400.x * arg250.sidemove, value399.y * arg250.forwardmove + value400.y * arg250.sidemove);
            value401:normalize();
            local value402 = value395 + value401 * 8;
            local value403 = utils.trace_hull(value395, value402, value397, value398, entity.get_players(), 33636363, 0);
            if value403.entity == nil or not value403:did_hit_world() or bit.band(value403.contents, 536870912) ~= 0 then
                return;
            else
                local value404 = value396:normalized();
                if value404:dot(value401) <= 0 then
                    return;
                else
                    local value405 = value403.plane.normal;
                    if math.abs(value405.z) >= 0.1 then
                        return;
                    else
                        if value404:dot(value405) < -0.85 then
                            value404 = value401;
                        end;
                        local value406 = value405:vectors();
                        if value406:dot(value404) < 0 then
                            value406 = value406 * -1;
                        end;
                        arg250.move_yaw = math.deg(math.atan2(value406.y, value406.x));
                        arg250.forwardmove = 450;
                        arg250.sidemove = 0;
                        return;
                    end;
                end;
            end;
        end;
    end;
end;
 
do
    local set_override = function(arg251)
        events.createmove(angle_refs, arg251:get());
    end;
    angles_state.enabled:set_callback(set_override, true);
end;
 
local angle_refs = debug_overlay_line.other.misc.collision_air_duck;
local unset_override = function(arg252, arg253)
    if arg253.m_MoveType == 9 or arg253.m_MoveType == 8 then
        return false;
    elseif arg252.in_duck then
        return false;
    elseif bit.band(arg253.m_fFlags, bit.lshift(1, 0)) ~= 0 then
        return false;
    else
        return true;
    end;
end;
do
    local set_override = function(arg254)
        local value407 = entity.get_local_player();
        if value407 == nil then
            return;
        elseif not unset_override(arg254, value407) then
            return;
        else
            local value408 = value407:simulate_movement();
            value408:think(1);
            arg254.in_duck = true;
            local value409 = bit.band(value408.flags, bit.lshift(1, 0)) == 0 and value408.did_hit_collision;
            value408:think(1);
            arg254.in_duck = false;
            local value410 = bit.band(value408.flags, bit.lshift(1, 0)) == 0 and value408.did_hit_collision;
            if not value409 and value410 then
                arg254.in_duck = true;
            end;
            return;
        end;
    end;
     
    local hit_flag = function(arg255)
        events.createmove(set_override, arg255:get());
    end;
    angle_refs.enabled:set_callback(hit_flag, true);
end;
 
local unset_override = debug_overlay_line.other.misc.fast_ladder;
local set_override = 9;
local state_meta = function(arg256)
    local value411 = render.camera_angles().x;
    if arg256.forwardmove > 0 and value411 < 45 then
        arg256.view_angles.x = 89;
        arg256.in_moveright = 1;
        arg256.in_moveleft = 0;
        arg256.in_forward = 0;
        arg256.in_back = 1;
        if arg256.sidemove == 0 then
            arg256.view_angles.y = arg256.view_angles.y + 90;
        end;
        if arg256.sidemove < 0 then
            arg256.view_angles.y = arg256.view_angles.y + 150;
        end;
        if arg256.sidemove > 0 then
            arg256.view_angles.y = arg256.view_angles.y + 30;
        end;
    end;
    if arg256.forwardmove < 0 then
        arg256.view_angles.x = 89;
        arg256.in_moveleft = 1;
        arg256.in_moveright = 0;
        arg256.in_forward = 1;
        arg256.in_back = 0;
        if arg256.sidemove == 0 then
            arg256.view_angles.y = arg256.view_angles.y + 90;
        end;
        if arg256.sidemove > 0 then
            arg256.view_angles.y = arg256.view_angles.y + 150;
        end;
        if arg256.sidemove < 0 then
            arg256.view_angles.y = arg256.view_angles.y + 30;
        end;
    end;
end;
do
    local hit_flag = function(arg257)
        local value412 = entity.get_local_player();
        if value412 == nil then
            return;
        elseif not value412:is_alive() or is_grenade_weapon(value412:get_player_weapon()) then
            return;
        elseif value412.m_MoveType ~= set_override then
            return;
        else
            state_meta(arg257);
            return;
        end;
    end;
     
    local ready_flag = function(arg258)
        events.createmove(hit_flag, arg258:get());
    end;
    unset_override.enabled:set_callback(ready_flag, true);
end;
 
local set_override = debug_overlay_line.other.misc.edge_stop;
local state_meta = function(arg259)
    local value413 = entity.get_local_player();
    if value413 == nil then
        return;
    else
        local value414 = value413:simulate_movement();
        value414:think(5);
        if value414.velocity.z < 0 then
            arg259.block_movement = 2;
        end;
        return;
    end;
end;
 
do
    local tick_flag = function(arg260)
        events.createmove(state_meta, arg260:get());
    end;
    set_override.enabled:set_callback(tick_flag, true);
end;
 
local state_meta = debug_overlay_line.other.misc.no_fall_damage;
local hit_flag = false;
local tick_flag = math.pi * 2;
local ready_flag = tick_flag / 8;
do
    local state_flag = function(arg261, arg262)
        local value415 = arg261:get_origin();
        for value416 = 0, tick_flag, ready_flag do
            local value417 = math.sin(value416);
            local value418 = math.cos(value416);
            local value419 = value415.x + value418 * 10;
            local value420 = value415.y + value417 * 10;
            local value421 = vector(value419, value420, value415.z);
            local value422 = value421:clone();
            value422.z = value422.z - arg262;
            if utils.trace_line(value421, value422, arg261).fraction ~= 1 then
                return true;
            end;
        end;
        return false;
    end;
    local target_flag = function(arg263)
        local value423 = entity.get_local_player();
        if value423 == nil then
            return;
        elseif value423.m_vecVelocity.z >= -500 then
            hit_flag = false;
            return;
        else
            if state_flag(value423, 15) then
                hit_flag = false;
            elseif state_flag(value423, 75) then
                hit_flag = true;
            end;
            arg263.in_duck = hit_flag;
            return;
        end;
    end;
     
    local update_indicators = function(arg264)
        events.createmove(target_flag, arg264:get());
    end;
    state_meta.enabled:set_callback(update_indicators, true);
end;
 
local hit_flag = debug_overlay_line.other.misc.unlock_fd_speed;
local tick_flag = 5;
do
    local ready_flag = function(arg265)
        if not api.antiaim.misc.fake_duck:get() then
            return;
        elseif entity.get_local_player() == nil then
            return;
        else
            local value424 = arg265.forwardmove;
            local value425 = arg265.sidemove;
            if math.abs(value424) > tick_flag or math.abs(value425) > tick_flag then
                local value426 = 450 / (value424 * value424 + value425 * value425) ^ 0.5;
                arg265.forwardmove = value424 * value426;
                arg265.sidemove = value425 * value426;
            end;
            return;
        end;
    end;
     
    local target_flag = function(arg266)
        events.createmove_run(ready_flag, arg266:get());
    end;
    hit_flag.enabled:set_callback(target_flag, true);
end;
 
do
local toss=debug_overlay_line.other.misc.super_toss
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
    events.render(function()
        if globals.realtime>=last and globals.realtime-last<1/30 then return end
        last=globals.realtime
        local label="s o c i a l"
        local out={}
        for i=1,#label do
            local t=(math.sin(globals.realtime*3+(i+1)/3)+1)/2
            local r=math.floor(151+(224-151)*t+.5)
            local g=math.floor(170+(233-170)*t+.5)
            local b=math.floor(234+(255-234)*t+.5)
            out[#out+1]=string.format("\a%02X%02X%02XFF%s",r,g,b,label:sub(i,i))
        end
        ui.sidebar(table.concat(out),"bullseye")
    end)
end

do
    local extrap=source_controls.extrap
    local force=source_controls.force
    local state={armed=false,hook=nil,attached=false,attach_unknown=false,last_time=0,broken=false}
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
        return ok
    end
    local function tick_extrap()
        if not extrap:get() or not live()then stop_extrap();return end
        local interval=tonumber(globals.tickinterval)
        if not finite(interval) or interval<=0 then warn("tickinterval","Invalid tickinterval; extrapolation paused.");stop_extrap();return end
        interval=math.clamp(interval,1/128,1/32)
        local targets={1,1,interval}
        for i,slot in ipairs(band)do
            if not own_write(slot,targets[i],false)then
                stop_extrap()
                return
            end
        end
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
        local interval,tick=tonumber(globals.tickinterval),tonumber(globals.server_tick)
        if not finite(interval) or interval<=0 or not finite(tick)then return end
        local period=math.max(1,math.floor(.25/interval+.5))
        if math.floor(tick)%period==0 then
            if not own_write(prediction,0,true)then stop_force();state.broken=true end
        end
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
    -- Auto LC: get_threat(true) returns the player entity that can hit us.
    -- Keep this entity as the single threat source; the legacy Smart trace used
    -- a second, generic get_threat() result and could therefore test another player.
    local state = {
        last_cmd = nil,
        last_enemy = nil,
        process_ticks_original = nil,
        process_ticks_written = nil,
        process_ticks_restore = nil,
        next_trigger_tick = nil
    }
    local warned = nil
    local process_ticks = cvar.sv_maxusrcmdprocessticks

    local function get_restore_ticks()
        -- If our own Max User Process Ticks feature is active, restore its
        -- configured value. Otherwise restore exactly what Auto LC captured.
        local rage_options = debug_overlay_line.other
            and debug_overlay_line.other.aimbot
            and debug_overlay_line.other.aimbot.maxusrcmdprocessticks
        if rage_options and rage_options.enabled and rage_options.enabled:get()
            and rage_options.ticks then
            return rage_options.ticks:get()
        end
        return state.process_ticks_original
    end

    local function clear_process_ticks_lease()
        state.process_ticks_original = nil
        state.process_ticks_written = nil
        state.process_ticks_restore = nil
    end

    local function restore_process_ticks(force)
        if state.process_ticks_original == nil then
            return true
        end

        local restore_at = state.process_ticks_restore
        if not force and restore_at ~= nil and globals.tickcount < restore_at then
            return false
        end

        local ok_current, current = pcall(function()
            return process_ticks:int()
        end)
        if not ok_current or type(current) ~= "number" then
            -- Keep the lease so a later callback can retry the restoration.
            return false
        end

        -- Another feature changed the value after our write. Relinquish
        -- ownership rather than overwriting that newer value.
        if current ~= state.process_ticks_written then
            clear_process_ticks_lease()
            return true
        end

        local value = get_restore_ticks()
        if type(value) ~= "number" then
            return false
        end

        local ok_write = pcall(function()
            process_ticks:int(value)
        end)
        if not ok_write then
            return false
        end

        local ok_after, after = pcall(function()
            return process_ticks:int()
        end)
        if not ok_after or type(after) ~= "number" then
            -- The write may have happened; keep ownership and verify next tick.
            return false
        end

        if after == value then
            clear_process_ticks_lease()
            return true
        end

        if after ~= state.process_ticks_written then
            -- The ConVar was changed externally while restoration was pending.
            clear_process_ticks_lease()
            return true
        end

        return false
    end

    local function reset()
        restore_process_ticks(true)
        state.last_cmd = nil
        state.last_enemy = nil
        state.next_trigger_tick = nil
        source_controls.lc_status = "waiting"
    end

    local function get_hittable_enemy()
        local ok, enemy = pcall(entity.get_threat, true)
        if not ok or enemy == nil then
            return nil
        end

        local valid, result = pcall(function()
            return enemy:is_player()
                and enemy:is_enemy()
                and enemy:is_alive()
                and not enemy:is_dormant()
        end)
        if not valid or not result then
            return nil
        end

        return enemy
    end

    local function acquire_process_ticks()
        -- Do not claim or later restore a value that was already 19 before
        -- Auto LC ran; it may belong to another script or feature.
        if state.process_ticks_original ~= nil then
            return
        end

        local ok_current, current = pcall(function()
            return process_ticks:int()
        end)
        if not ok_current or type(current) ~= "number" or current == 19 then
            return
        end

        state.process_ticks_original = current
        state.process_ticks_written = 19

        local ok_write = pcall(function()
            process_ticks:int(19)
        end)
        local ok_after, after = pcall(function()
            return process_ticks:int()
        end)

        if ok_after and after == 19 then
            state.process_ticks_restore = globals.tickcount + 3
        elseif ok_after and after ~= current then
            -- A value other than ours was applied; do not overwrite it.
            clear_process_ticks_lease()
        elseif not ok_write then
            clear_process_ticks_lease()
        else
            clear_process_ticks_lease()
        end
    end

    local function trigger(enemy_index)
        acquire_process_ticks()

        local ok, err = pcall(function()
            rage.exploit:force_teleport()
            rage.exploit:force_charge()
        end)
        if not ok then
            if warned ~= tostring(err) then
                warned = tostring(err)
                print_raw("[social] Auto LC: " .. tostring(err))
            end
            state.last_enemy = enemy_index
            state.next_trigger_tick = globals.tickcount + 2
            source_controls.lc_status = "error"
            return false
        end

        state.last_enemy = enemy_index
        state.next_trigger_tick = globals.tickcount + 4
        source_controls.lc_status = "active"
        return true
    end

    function aa_patch.lc(cmd, owner, actual_state, hidden)
        -- Always service a pending restore before evaluating a new threat.
        restore_process_ticks(false)

        if not source_controls.lc_enabled or not source_controls.lc_enabled:get() then
            source_controls.lc_status = "off"
            state.last_enemy = nil
            state.next_trigger_tick = nil
            restore_process_ticks(true)
            return
        end

        local player = entity.get_local_player()
        if not player or not player:is_alive() then
            reset()
            return
        end

        local command_id = cmd and cmd.command_number or globals.tickcount
        if state.last_cmd == command_id then
            return
        end
        state.last_cmd = command_id

        local player_flags = tonumber(player.m_fFlags)
        if player_flags == nil then
            state.last_enemy = nil
            state.next_trigger_tick = nil
            source_controls.lc_status = "waiting"
            return
        end

        -- Smart conditions from AutoLCBreak: airborne and crouching.
        local in_air = bit.band(player_flags, 1) == 0
        local is_crouching = bit.band(player_flags, 2) ~= 0
        if not in_air or not is_crouching then
            state.last_enemy = nil
            state.next_trigger_tick = nil
            source_controls.lc_status = "waiting"
            return
        end

        -- The hittable query already supplies the actual enemy that can hit us.
        local enemy = get_hittable_enemy()
        if not enemy then
            state.last_enemy = nil
            state.next_trigger_tick = nil
            source_controls.lc_status = "not hittable"
            return
        end

        local ok_index, enemy_index = pcall(function()
            return enemy:get_index()
        end)
        if not ok_index then
            enemy_index = nil
        end

        -- Avoid re-forcing the exploit every command while the same threat
        -- remains hittable. The ConVar lease is restored after three ticks;
        -- one tick is left before the next attempt can be armed.
        local next_tick = state.next_trigger_tick
        if next_tick ~= nil and globals.tickcount < next_tick
            and enemy_index == state.last_enemy then
            source_controls.lc_status = "active"
            return
        end

        trigger(enemy_index)
    end

    events.render(function()
        local player = entity.get_local_player()
        if not player or not player:is_alive() then
            reset()
        end
    end)
    events.level_init(reset)
    events.shutdown(reset)
end

do
    local native=api.misc.main.other.windows
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
                    elseif row==2 then for id in pairs(defaults) do reset(id) end;save() end
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
        render.rect(vector(x,y),vector(x+w,y+h),color(13,17,23,math.floor(148*alpha)),7)
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
    local function draw_binds(x,y,w,h,alpha,rows,data)
        local accent=(debug_overlay_line.other.visuals.accent_color and debug_overlay_line.other.visuals.accent_color:get()) or color(192,202,255,255)
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
    local function draw_spectators(x,y,w,h,alpha,rows,data)
        local accent=(debug_overlay_line.other.visuals.accent_color and debug_overlay_line.other.visuals.accent_color:get()) or color(192,202,255,255)
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
        local accent=(debug_overlay_line.other.visuals.accent_color and debug_overlay_line.other.visuals.accent_color:get()) or color(192,202,255,255)
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
        local accent=(debug_overlay_line.other.visuals.accent_color and debug_overlay_line.other.visuals.accent_color:get()) or color(192,202,255,255)
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
        local ui_alpha=1
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
        local bind_preview=false
        if source_controls.binds.enabled:get() and menu_preview and #binds==0 then
            binds={{"Min Damage","38"},{"Double Tap","toggle"},{"Fake Duck","hold"}}
            bind_preview=true
        end
        local bind_width=190
        for _,row in ipairs(binds) do bind_width=math.max(bind_width,size(fonts.body,row[1])+size(fonts.body,row[2] or "")+58) end
        panel("binds","",binds,{width=math.min(bind_width,290),height_fn=function(rows)return 32+#rows*22 end,draw=draw_binds,data={preview=bind_preview}})
        local spectators={}
        local player=entity.get_local_player()
        if source_controls.spectators.enabled:get() and player then
            local list=player:get_spectators()
            if list then for _,spectator in ipairs(list) do local name=tostring(spectator:get_name() or "");if name~="" then spectators[#spectators+1]={name,""} end end end
        end
        table.sort(spectators,function(a,b)return a[1]<b[1] end)
        local spectator_preview=false
        if source_controls.spectators.enabled:get() and menu_preview and #spectators==0 then
            spectators={{"spectator_one",""},{"spectator_two",""}}
            spectator_preview=true
        end
        local spectator_width=150
        for _,row in ipairs(spectators) do spectator_width=math.max(spectator_width,size(fonts.body,row[1])+42) end
        panel("spectators","",spectators,{width=math.min(spectator_width,250),height_fn=function(rows)return 32+#rows*21 end,draw=draw_spectators,data={preview=spectator_preview}})
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
        if attacker==player and victim and victim~=player then schedule("kill")
        elseif victim==player and attacker and attacker~=player then schedule("death") end
    end)
    talk.enabled:set_callback(function()if not talk.enabled:get() then queue={} end end)
    local native=api.misc.main.in_game.clan_tag
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
            text=frames[math.floor(globals.realtime/.45)%#frames+1]
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
    local visual=debug_overlay_line.other.visuals
    local font_bank = source_controls.fonts or {body=1,small=1,title=1,brand=1}
    local detail_font = font_bank.detail or font_bank.body or 1
    local fonts = {body=detail_font,small=detail_font,title=font_bank.title or detail_font,detail=detail_font,strong=detail_font,brand=font_bank.brand or font_bank.title or detail_font,value=detail_font}
    local markers={}
    local scope_blend=0
    local groups={[0]="body","head","chest","stomach","left arm","right arm","left leg","right leg","neck"}
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
        render.rect(vector(x,y),vector(x+w,y+h),color(13,17,23,148),7)
        render.rect_outline(vector(x,y),vector(x+w,y+h),color(255,255,255,18),1,7)
    end
    source_controls.visual={fonts=fonts,surface=surface,text=text}
    local function bound(ref)
        for _,bind in ipairs(ui.get_binds()) do
            if bind.active and bind.reference and (bind.reference==ref or bind.reference:id()==ref:id()) then return bind.value end
        end
    end

    -- Custom HUD positions are saved independently of preset controls and expressed
    -- in 0..1000 screen coordinates, so they survive resolution changes.
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
            -- Legacy layouts stored the top-left corner rather than a center anchor.
            x=legacy.x/1000*screen.x
            y=legacy.y/1000*screen.y
            custom=true
        end
        if custom then
            -- A deliberately moved indicator remains independent when it is far
            -- from the reticle. If it is still near the reticle, scope geometry
            -- follows it by the exact same pixel offset as the default position.
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
                    elseif row==2 then reset_visual_position("all") end
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
        local muted=color(145,158,180,255)

        -- Match the actual Scope Overlay geometry: the center is screen center,
        -- Size is scaled by the same scoped fade, Gap stays in pixels, and Spread
        -- Dependency adds weapon inaccuracy * 100. Rotation projects by cos(45°).
        local scope_span=0
        local scope_top_visible=false
        local scope_bottom_visible=false
        if alive and visual.scope_overlay then
            pcall(function()
                if visual.scope_overlay.enabled:get() then
                    local scoped_value=p.m_bIsScoped
                    local scoped=(scoped_value==true or tonumber(scoped_value)==1)
                    scope_blend=interp.interp(scope_blend,scoped and 1 or 0,0.05)
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
                    scope_blend=interp.interp(scope_blend,0,0.05)
                end
            end)
        else
            scope_blend=interp.interp(scope_blend,0,0.05)
        end
        local crosshair_scope_offset=scope_bottom_visible and scope_span or 0
        local damage_scope_offset=scope_top_visible and -scope_span or 0

        -- Show only active states. DT + HS is represented by the combined OSAA label.
        if visual.crosshair_indicators.enabled:get() then
            local dt=not not effective(api.rage.main.double_tap)
            local hs=not not effective(api.rage.main.hide_shots)
            local fs=not not effective(api.antiaim.angles.freestanding)
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
            local hc=bound(api.rage.selection.hit_chance)
            local md=bound(api.rage.selection.min_damage)
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
                local c=color(255,255,255,255)
                local value=math.floor(modifier*100+.5).."%"
                surface(left,top,w,h)
                render.text(fonts.detail,vector(left+9,top+5),c,nil,"velocity")
                render.text(fonts.detail,vector(left+w-9-width(fonts.detail,value),top+5),c,nil,value)
                render.rect(vector(left+9,top+22),vector(left+w-9,top+23),color(255,255,255,42))
                if modifier>0 then
                    render.rect(vector(left+9,top+22),vector(left+9+(w-18)*modifier,top+23),c)
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
                    local c=visual.hit_marker.color:get();c=color(c.r,c.g,c.b,math.floor((1-age)*255))
                    local gap=visual.hit_marker.size:get();local thick=visual.hit_marker.thickness:get()
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
