local settings_visibility_tick, hotkeys_box, widget_tick
local NAME = "anemone • beta"
local WHITE = ""
local RESET = ""
local warned = { }
local function console_line(text)
  text = tostring(text)
  local ok = pcall(function ()
    print_raw(text .. "\n")
  end)
  if not ok then
    pcall(function ()
      print(text)
    end)
  end
end
local function warn_once(key, text)
  if warned[key] then
    return
  end
  warned[key] = true
  console_line("[Anemone] " .. text)
end
local ANEMONE_ID = tostring({ })
local ANEMONE_SECOND_COPY = false
local EVENT_CHAIN = { }
local function chain(name, fn)
  local list = EVENT_CHAIN[name]
  if not list then
    list = { }
    EVENT_CHAIN[name] = list
    local ok, err = pcall(function ()
      events[name]:set(function (arg)
        local core=EVENT_CHAIN.core
        if core and not core.ready and name~="shutdown" and name~="config_state" then return end
        local profiler=EVENT_CHAIN.profiler
        local started=profiler and profiler:begin(name)
        for _, sub in ipairs(list) do
          local sok, serr = pcall(sub, arg)
          if not sok then
            warn_once("chain_" .. name, name .. ": " .. tostring(serr):gsub("%c", " "))
          end
        end
        if profiler then profiler:finish(name,started)end
      end)
    end)
    if not ok then
      EVENT_CHAIN[name] = nil
      warn_once("hook_" .. name, "Event unavailable: " .. name .. "; see diagnostics.")
      return false
    end
  end
  list[# list + 1] = fn
  return true
end
local function anemone_second_copy()
  local ok, dup = pcall(function ()
    local now = 0
    if globals and type(globals.realtime) == "number" then
      now = globals.realtime
    end
    local holder = _G.__ANEMONE_HOLDER
    if type(holder) == "table" and holder.id ~= ANEMONE_ID and (now - (holder.t or 0)) < 1.0 then
      return true
    end
    _G.__ANEMONE_HOLDER = { id = ANEMONE_ID, t = now }
    return false
  end)
  if ok and dup then
    if not ANEMONE_SECOND_COPY then
      ANEMONE_SECOND_COPY = true
      warn_once("second_copy", "Duplicate Anemone instance detected; this copy idles. Unload the extra Anemone script from the Lua list!")
    end
    return true
  end
  ANEMONE_SECOND_COPY = false
  return false
end
pcall(function ()
  ui.sidebar(NAME, "meteor")
end)
local function number(value)
  if type(value) ~= "number" or value ~= value then
    return nil
  end
  if value == math.huge or value == - math.huge then
    return nil
  end
  return value
end
local function clamp(value, low, high)
  return math.max(low, math.min(high, value))
end
local function flag_set(value, mask)
  value, mask = tonumber(value), tonumber(mask)
  if not value or not mask then
    return false
  end
  if bit and bit.band then
    return bit.band(value, mask) ~= 0
  end
  return math.floor(value / mask) % 2 == 1
end
local function command_attack(cmd)
  if not cmd then
    return false
  end
  if cmd.in_attack == true then
    return true
  end
  local value = tonumber(cmd.in_attack)
  return value ~= nil and flag_set(value, 1)
end
local function clock()
  return (globals and number(globals.realtime)) or 0
end
local function get_bool(item)
  if EVENT_CHAIN.core and not EVENT_CHAIN.core.ready then return false end
  local ok, value = pcall(function ()
    return item:get()
  end)
  return ok and value == true
end
local function icon(names)
  for i = 1, # names do
    local ok, value = pcall(function ()
      return ui.get_icon(names[i])
    end)
    if ok and type(value) == "string" and value ~= "" then
      return value
    end
  end
  return ""
end
local function label(ic, text)
  return WHITE .. (ic ~= "" and (ic .. "  ") or "") .. text
end
local function tooltip(item, text)
  if item and type(text) == "string" then
    pcall(function() item:tooltip(text) end)
  end
end
local function client_nick()
  local ok, value = pcall(function ()
    return common.get_username()
  end)
  if ok and type(value) == "string" and value ~= "" then
    return value
  end
  warn_once("cheat_username", "Neverlose username unavailable; no Steam/workspace nickname substituted.")
  return "Unknown"
end
local function info_text(value)
  local text = tostring(value)
  text = text:gsub(string.char(7) .. "%x%x%x%x%x%x%x%x", ""):gsub(string.char(7) .. "DEFAULT", ""):gsub("%c", " "):gsub(" +", " "):gsub("^%s+", ""):gsub("%s+$", "")
  return text ~= "" and text or "Unknown"
end
local function static_info_row(group, title, value)
  local names = title == "User" and { "user", "circle-user", "user-circle" } or { "cube", "layer-group", "code" }
  local glyph = icon(names)
  local prefix = glyph ~= "" and (WHITE .. glyph .. "  ") or ""
  return group:label(prefix .. WHITE .. info_text(title) .. "   " .. WHITE .. info_text(value) .. RESET)
end
local function static_info_pill(group, items)
  local segments = { }
  for i, kv in ipairs(items) do
    local title, value = kv[1], kv[2]
    local names = title == "User" and { "user", "circle-user", "user-circle" } or { "cube", "layer-group", "code" }
    local glyph = icon(names)
    local prefix = glyph ~= "" and (WHITE .. glyph .. "  ") or ""
    local seg = prefix .. WHITE .. info_text(title) .. " " .. WHITE .. info_text(value)
    if i > 1 then
      seg = WHITE .. "› " .. seg
    end
    segments[i] = seg
  end
  return group:label(table.concat(segments, "") .. RESET)
end
local cfg = { }
cfg.main_tab = icon({ "island-tropical", "sunrise", "house" })
if cfg.main_tab == "" then cfg.main_tab = "Main" end
local section = ui.create(cfg.main_tab, "\226\128\139", 2)
local function section_item(names, text)
  local glyph = icon(names)
  return (glyph ~= "" and (glyph .. "  ") or "") .. text
end
local SECTION_ITEMS = {
  section_item({ "circle-info", "info-circle", "info" }, "Information"),
  section_item({ "sliders", "gears", "gear", "function" }, "Functions"),
  section_item({ "code-branch", "layer-group", "cubes" }, "Version")
}
cfg.section = section:list("", SECTION_ITEMS)
pcall(function ()
  cfg.section:set(1)
end)
cfg.workspace_items = {
  section_item({ "house", "home" }, "Home"),
  section_item({ "folder-gear", "folder", "floppy-disk", "gear" }, "Configs")
}
cfg.workspace = section:list("", cfg.workspace_items)
pcall(function ()
  cfg.workspace:set(1)
end)
cfg.version_state = {
  blood_hex = "A6192EFF",
  dark_blood_hex = "64101CFF",
  lime_hex = "B5FF2EFF",
  intro_active = false,
  intro_time = 0,
  intro_font_big = nil,
  intro_font_small = nil,
  intro_delay = 0,
  menu_closed_by_intro = false,
  boot_lock = true,
  beta_updated = "11/10/26 - 15:57",
  lua_version = "v49",
  ultimate_updated = "07/10/26 - 16:19",
  adaptive_updated = "07/10/26 - 16:19",
  ultimate_extrap_ticks = 6
}
function cfg.version_state.blood_text(text)
  return string.char(7) .. cfg.version_state.blood_hex .. tostring(text) .. string.char(7) .. "DEFAULT"
end
function cfg.version_state.dark_blood_text(text)
  return string.char(7) .. cfg.version_state.dark_blood_hex .. tostring(text) .. string.char(7) .. "DEFAULT"
end
function cfg.version_state.lime_text(text)
  return string.char(7) .. cfg.version_state.lime_hex .. tostring(text) .. string.char(7) .. "DEFAULT"
end
function cfg.version_state.clean_bind_name(value)
  local text, mark = tostring(value or ""), string.char(7)
  text = text:gsub(mark .. "%x%x%x%x%x%x%x%x", "")
  text = text:gsub(mark .. "%b{}", "")
  text = text:gsub(mark .. "DEFAULT", "")
  return text:gsub("[%c%z]", ""):gsub("[^%w%s%-%._]", ""):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
end
function cfg.version_state.sanitize_live_binds()
  local ok, binds = pcall(ui.get_binds)
  if not ok or type(binds) ~= "table" then return end
  for _, bind in pairs(binds) do
    local clean = cfg.version_state.clean_bind_name(bind.name)
    if clean ~= "" and clean ~= tostring(bind.name or "") then pcall(function () bind.name = clean end) end
  end
end
pcall(function ()
  chain("render",function () cfg.version_state.sanitize_live_binds() end)
end)
function cfg.version_state.is_ultimate()
  return false
end
cfg.version_developer = ui.create(cfg.main_tab, "\226\128\139\226\128\139", 1)
cfg.version_ultimate = cfg.version_developer:switch(cfg.version_state.blood_text("Ultimate"), false)
cfg.version_ultimate_menu = cfg.version_ultimate:create()
cfg.version_skip_intro = cfg.version_ultimate_menu:switch("Skip Intro", false)
cfg.version_plus = cfg.version_developer:switch(cfg.version_state.lime_text("Plus"), false)
cfg.version_plus_menu = cfg.version_plus:create()
cfg.version_plus_skip_intro = cfg.version_plus_menu:switch("Skip Intro", false)
cfg.version_base = ui.create(cfg.main_tab, "\226\128\140\226\128\140", 1)
cfg.version_beta = cfg.version_base:switch("Beta", true)
pcall(function ()
  cfg.version_ultimate:set(false)
  cfg.version_plus:set(false)
  cfg.version_beta:set(true)
  cfg.version_beta:disabled(true)
end)
cfg.version_state.tiers = {
  beta = { "Beta", "Adaptive", "FFI" },
  plus = { "Beta", "Adaptive", "FFI" },
  ultimate = { "Beta", "Adaptive", "FFI" },
}
function cfg.version_state.is_plus()
  return false
end
function cfg.version_state.tier()
  return "beta"
end
function cfg.version_state.tier_modes()
  return cfg.version_state.tiers[cfg.version_state.tier()] or cfg.version_state.tiers.beta
end
cfg.version_state.legacy_modes = {
  Main = "Beta",
  Trial = "Beta",
  Bypass = "Adaptive",
  Test = "Adaptive",
  Free = "Beta",
  Plus = "Adaptive",
  Ultimate = "Adaptive",
}
function cfg.version_state.normalize_mode(value)
  if type(value) ~= "string" then
    return nil
  end
  return cfg.version_state.legacy_modes[value] or value
end
function cfg.version_state.allowed_mode(value)
  local modes = cfg.version_state.tier_modes()
  value = cfg.version_state.normalize_mode(value)
  for i = 1, # modes do
    if modes[i] == value then
      return value
    end
  end
  return modes[1]
end
function cfg.version_state.sync_mode_items()
  local modes = cfg.version_state.tier_modes()
  local ok = pcall(function () cfg.yaw_mode:update(modes) end)
  if not ok then ok = pcall(function () cfg.yaw_mode:items(modes) end) end
  if ok then
    cfg.version_state.mode_items = modes
    local current = cfg.version_state.normalize_mode(cfg.yaw_mode:get())
    cfg.yaw_mode:set(cfg.version_state.allowed_mode(current))
  end
  return ok
end
cfg.config_panel = ui.create(cfg.main_tab, "\226\128\139\226\128\139\226\128\139\226\129\160", 1)
cfg.config_system = {
  version = 1,
  active_kind = "builtin",
  has_users = false,
  user_names = { },
  profile = "beta",
  stores = { beta = { }, ultimate = { } },
  store = { },
  builtin_names = { "PWNZ$CRASH", "666TEST" },
  ultimate_builtin_names = { },
  builtins = {
    ["PWNZ$CRASH"] = [=[{"name":"123","row":{"updated":0.0,"values":{"aspect":false,"aspect_value":100.0,"assist":false,"avoid_collision":true,"clantag":true,"crosshair_indicator":true,"crosshair_indicator_color":{"__anemone_kind":"color","a":255.0,"b":98.0,"g":202.0,"r":43.0},"crosshair_indicator_shadow":true,"damage_indicator":true,"damage_indicator_color":{"__anemone_kind":"color","a":255.0,"b":98.0,"g":202.0,"r":43.0},"damage_indicator_font":"Pixel","effects":true,"effects_mode":"CSGO","extrapolation":true,"extrapolation_mode":"Adaptive","fast_ladder":true,"forceshot":false,"fortnite_hit":true,"fps_optimizer":true,"hit_effect":true,"hotkeys":false,"interpolation":true,"jump_scout":true,"kill_particle_amount":18.0,"kill_particle_color":{"__anemone_kind":"color","a":255.0,"b":98.0,"g":202.0,"r":43.0},"kill_particle_duration":2.0,"kill_particles":true,"model_changer":false,"model_changer_ct":"z-piks.ru/gta_crip","model_changer_t":"eminem/gta_sa/vwfypro","model_changer_team":["CT","T"],"movement":true,"no_fall_damage":true,"notification_console":false,"notification_debug":false,"notification_screen":false,"notifications":false,"opt_list":["Decals","Blood and gibs","Tracers","Breakable debris","3D sky","Ropes"],"opt_preset":"Maximum FPS","predict_strength":"Extreme","presets":[],"resolver":true,"specs_header":false,"spectators":true,"unsafe_recharge":true,"watermark":true,"wm_accent":{"__anemone_kind":"color","a":255.0,"b":43.0,"g":202.0,"r":159.0},"wm_elements":["Logo","FPS","Frametime variance","Ping"],"wm_eval_accent":{"__anemone_kind":"color","a":255.0,"b":255.0,"g":190.0,"r":185.0},"wm_eval_elements":["Version","Username","Latency","Frames","Time"],"wm_eval_time_format":"24h","wm_eval_username_custom":"","wm_eval_username_source":"Cheat","wm_nl_accent":{"__anemone_kind":"color","a":255.0,"b":97.0,"g":202.0,"r":42.0},"wm_nl_elements":["Avatar","Username","Clock","FPS","Ping","Var","Loss","Build","Blur"],"wm_position":"Top-right","wm_style":"Neverlose","yaw":true,"yaw_mode":"Bypass"},"version":1.0}}]=],
    ["666TEST"] = [=[{"name":"1234","row":{"updated":0.0,"values":{"aspect":false,"aspect_value":100.0,"assist":false,"avoid_collision":true,"clantag":true,"crosshair_indicator":true,"crosshair_indicator_color":{"__anemone_kind":"color","a":255.0,"b":43.0,"g":43.0,"r":202.0},"crosshair_indicator_shadow":true,"damage_indicator":true,"damage_indicator_color":{"__anemone_kind":"color","a":255.0,"b":42.0,"g":42.0,"r":202.0},"damage_indicator_font":"Pixel","effects":true,"effects_mode":"CSGO","extrapolation":true,"extrapolation_mode":"Aggressive","fast_ladder":true,"forceshot":false,"fortnite_hit":true,"fps_optimizer":true,"hit_effect":true,"hotkeys":false,"interpolation":true,"jump_scout":true,"kill_particle_amount":18.0,"kill_particle_color":{"__anemone_kind":"color","a":255.0,"b":43.0,"g":43.0,"r":202.0},"kill_particle_duration":2.0,"kill_particles":true,"model_changer":false,"model_changer_ct":"z-piks.ru/gta_crip","model_changer_t":"eminem/gta_sa/vwfypro","model_changer_team":["CT","T"],"movement":true,"no_fall_damage":true,"notification_console":false,"notification_debug":false,"notification_screen":false,"notifications":false,"opt_list":["Decals","Blood and gibs","Tracers","Breakable debris","3D sky","Ropes"],"opt_preset":"Maximum FPS","predict_strength":"Extreme","presets":[],"resolver":true,"specs_header":false,"spectators":true,"unsafe_recharge":true,"watermark":true,"wm_accent":{"__anemone_kind":"color","a":255.0,"b":43.0,"g":43.0,"r":202.0},"wm_elements":["Logo","FPS","Frametime variance","Ping","Speed","K/D ratio","Clock"],"wm_eval_accent":{"__anemone_kind":"color","a":255.0,"b":255.0,"g":190.0,"r":185.0},"wm_eval_elements":["Version","Username","Latency","Frames","Time"],"wm_eval_time_format":"24h","wm_eval_username_custom":"","wm_eval_username_source":"Cheat","wm_nl_accent":{"__anemone_kind":"color","a":255.0,"b":97.0,"g":202.0,"r":42.0},"wm_nl_elements":["Avatar","Username","Clock","FPS","Ping","Var","Loss","Build","Blur"],"wm_position":"Top-right","wm_style":"Gamesense","yaw":true,"yaw_mode":"Test"},"version":1.0}}]=]
  }
}
function cfg.config_system.profile_name()
  return cfg.version_state.is_ultimate() and "ultimate" or "beta"
end
function cfg.config_system.active_builtins()
  return cfg.config_system.profile == "ultimate" and cfg.config_system.ultimate_builtin_names or cfg.config_system.builtin_names
end
function cfg.config_system.switch_profile()
  cfg.config_system.profile = cfg.config_system.profile_name()
  cfg.config_system.store = cfg.config_system.stores[cfg.config_system.profile] or { }
  cfg.config_system.stores[cfg.config_system.profile] = cfg.config_system.store
  if cfg.config_list then
    cfg.config_system.refresh()
  end
end
function cfg.config_system.notify(text)
  pcall(function ()
    common.add_notify(cfg.config_system.profile == "ultimate" and "HellSing Ultimate Configs" or "Anemone Configs", tostring(text))
  end)
  console_line((cfg.config_system.profile == "ultimate" and "[HellSing Ultimate Configs] " or "[Anemone Configs] ") .. tostring(text))
end
function cfg.config_system.clean_name(value)
  local name = tostring(value or "")
  name = name:gsub("[%c]", ""):gsub("^%s+", ""):gsub("%s+$", ""):gsub("[/\\:*?\"<>|]", "")
  if # name > 32 then
    name = name:sub(1, 32)
  end
  return name
end
function cfg.config_system.colored_icon(names, fallback, hex)
  local glyph = icon(names)
  if glyph == "" then
    glyph = fallback
  end
  return string.char(7) .. hex .. glyph .. string.char(7) .. "DEFAULT"
end
function cfg.config_system.config_label(names, fallback, name)
  return cfg.config_system.colored_icon(names, fallback, "23B7FFFF") .. "  " .. tostring(name)
end
function cfg.config_system.name_conflict(name, include_users)
  local needle = tostring(name or ""):lower()
  if needle:match("^%-+$") or needle == "no user configs" then
    return "reserved"
  end
  for _, builtin in ipairs(cfg.config_system.active_builtins()) do
    if builtin:lower() == needle then
      return "prepared"
    end
  end
  if include_users then
    for existing in pairs(cfg.config_system.store) do
      if tostring(existing):lower() == needle then
        return "user"
      end
    end
  end
  return nil
end
function cfg.config_system.encode_value(value, depth)
  depth = depth or 0
  if depth > 5 then
    return nil
  end
  local kind = type(value)
  if kind == "nil" or kind == "boolean" or kind == "number" or kind == "string" then
    return value
  end
  if kind == "table" then
    local out = { }
    for key, item in pairs(value) do
      local encoded = cfg.config_system.encode_value(item, depth + 1)
      if encoded ~= nil and (type(key) == "number" or type(key) == "string") then
        out[key] = encoded
      end
    end
    return out
  end
  local ok, r, g, b, a = pcall(function ()
    return tonumber(value.r), tonumber(value.g), tonumber(value.b), tonumber(value.a)
  end)
  if ok and r and g and b then
    return { __anemone_kind = "color", r = r, g = g, b = b, a = a or 255 }
  end
  return nil
end
function cfg.config_system.decode_value(value)
  if type(value) == "table" then
    local legacy_kind = value["__em" .. "ber_kind"]
    if value.__anemone_kind == "color" or legacy_kind == "color" then
      return color(tonumber(value.r) or 255, tonumber(value.g) or 255, tonumber(value.b) or 255, tonumber(value.a) or 255)
    end
  end
  return value
end
function cfg.config_system.is_config_item(key, item)
  if key == "section" or key == "workspace" or key == "workspace_items" or key == "config_panel" or key == "config_system" then
    return false
  end
  if tostring(key):sub(1, 7) == "config_" or tostring(key):sub(1, 8) == "version_" then
    return false
  end
  local ok, item_type = pcall(function ()
    return item:type()
  end)
  return ok and item_type ~= "button" and item_type ~= "label" and item_type ~= "texture"
end
function cfg.config_system.capture()
  local values = { }
  for key, item in pairs(cfg) do
    if cfg.config_system.is_config_item(key, item) then
      local ok, value = pcall(function ()
        return item:get()
      end)
      if ok then
        local encoded = cfg.config_system.encode_value(value, 0)
        if encoded ~= nil then
          values[key] = encoded
        end
      end
    end
  end
  return values
end
function cfg.config_system.set_item(key, encoded)
  local item = cfg[key]
  if not item or not cfg.config_system.is_config_item(key, item) then
    return
  end
  pcall(function ()
    item:set(cfg.config_system.decode_value(encoded))
  end)
end
function cfg.config_system.apply_resolver_path(values)
  if values.resolver ~= nil then
    cfg.config_system.set_item("resolver", values.resolver)
  end
  if values.assist ~= nil then
    cfg.config_system.set_item("assist", values.assist)
  end
  if values.yaw ~= nil then
    cfg.config_system.set_item("yaw", values.yaw)
  end
  if values.assist ~= nil then
    cfg.config_system.set_item("assist", values.assist)
  end
end
function cfg.config_system.apply(values)
  if type(values) ~= "table" then
    return false
  end
  for key, value in pairs(values) do
    if key ~= "resolver" and key ~= "assist" and key ~= "yaw" then
      cfg.config_system.set_item(key, value)
    end
  end
  cfg.config_system.apply_resolver_path(values)
  pcall(function ()
    local stored = cfg.yaw_mode:get()
    local normalized = cfg.version_state.normalize_mode(stored)
    if normalized and normalized ~= stored then
      cfg.yaw_mode:set(normalized)
    end
    cfg.version_state.sync_mode_items()
  end)
  pcall(function ()
    utils.execute_after(0.05, function ()
      cfg.config_system.apply_resolver_path(values)
    end)
  end)
  pcall(settings_visibility_tick)
  return true
end
function cfg.config_system.reset_items()
  for key, item in pairs(cfg) do
    if cfg.config_system.is_config_item(key, item) then
      pcall(function ()
        item:reset()
      end)
    end
  end
end
function cfg.config_system.persist()
  cfg.config_system.stores[cfg.config_system.profile] = cfg.config_system.store
  pcall(function ()
    if cfg.config_system.profile == "ultimate" then
      db.hellsing_ultimate_user_configs_v1 = cfg.config_system.store
    else
      db.anemone_user_configs_v1 = cfg.config_system.store
    end
  end)
end
function cfg.config_system.current_entry()
  local ok, value = pcall(function ()
    return cfg.config_list:get()
  end)
  if not ok then
    return nil, nil
  end
  local index = nil
  if type(value) == "number" then
    index = value
  else
    for i, name in ipairs(cfg.config_system.combined_items or { }) do
      if value == name then
        index = i
        break
      end
    end
  end
  if not index then
    return nil, nil
  end
  return cfg.config_system.combined_kinds[index], cfg.config_system.combined_names[index]
end
function cfg.config_system.sync_actions()
  local user_mode = cfg.config_system.active_kind == "user" and cfg.config_system.has_users
  for _, item in ipairs({ cfg.config_save, cfg.config_export, cfg.config_delete }) do
    if item then
      pcall(function ()
        item:disabled(not user_mode)
      end)
    end
  end
end
function cfg.config_system.refresh(preferred)
  cfg.config_system.user_names = { }
  for name, data in pairs(cfg.config_system.store) do
    if type(name) == "string" and type(data) == "table" then
      cfg.config_system.user_names[# cfg.config_system.user_names + 1] = name
    end
  end
  table.sort(cfg.config_system.user_names, function (a, b)
    return a:lower() < b:lower()
  end)
  cfg.config_system.has_users = # cfg.config_system.user_names > 0
  cfg.config_system.combined_items = { }
  cfg.config_system.combined_kinds = { }
  cfg.config_system.combined_names = { }
  local active_builtins = cfg.config_system.active_builtins()
  for _, name in ipairs(active_builtins) do
    local names = name == "PWNZ$CRASH" and { "crown" } or { "star", "asterisk" }
    local fallback = name == "PWNZ$CRASH" and "♛" or "★"
    cfg.config_system.combined_items[# cfg.config_system.combined_items + 1] = cfg.config_system.config_label(names, fallback, name)
    cfg.config_system.combined_kinds[# cfg.config_system.combined_kinds + 1] = "builtin"
    cfg.config_system.combined_names[# cfg.config_system.combined_names + 1] = name
  end
  if #active_builtins > 0 then
    cfg.config_system.combined_items[# cfg.config_system.combined_items + 1] = "---------------------------------------"
    cfg.config_system.combined_kinds[# cfg.config_system.combined_kinds + 1] = "separator"
    cfg.config_system.combined_names[# cfg.config_system.combined_names + 1] = "__separator__"
  end
  if cfg.config_system.has_users then
    for _, name in ipairs(cfg.config_system.user_names) do
      cfg.config_system.combined_items[# cfg.config_system.combined_items + 1] = cfg.config_system.config_label({ "list-ul", "list", "bars-staggered" }, "≡", name)
      cfg.config_system.combined_kinds[# cfg.config_system.combined_kinds + 1] = "user"
      cfg.config_system.combined_names[# cfg.config_system.combined_names + 1] = name
    end
  else
    cfg.config_system.combined_items[# cfg.config_system.combined_items + 1] = "No user configs"
    cfg.config_system.combined_kinds[# cfg.config_system.combined_kinds + 1] = "empty"
    cfg.config_system.combined_names[# cfg.config_system.combined_names + 1] = "No user configs"
  end
  pcall(function ()
    cfg.config_list:update(cfg.config_system.combined_items)
  end)
  if preferred and cfg.config_system.has_users then
    local preferred_index = 1
    for i, name in ipairs(cfg.config_system.combined_names) do
      if name == preferred then
        preferred_index = i
        break
      end
    end
    pcall(function ()
      cfg.config_list:set(preferred_index)
    end)
    cfg.config_system.active_kind = "user"
  else
    pcall(function ()
      cfg.config_list:set(1)
    end)
    cfg.config_system.active_kind = "builtin"
  end
  cfg.config_system.sync_actions()
end
function cfg.config_system.user_selected()
  local kind, name = cfg.config_system.current_entry()
  return kind == "user" and name or nil
end
function cfg.config_system.load_active()
  local kind, name = cfg.config_system.current_entry()
  if kind == "builtin" then
    local payload = name and cfg.config_system.builtins[name] or nil
    if not payload then
      cfg.config_system.notify("Select a prepared config first.")
      return
    end
    local parsed_ok, parsed = pcall(json.parse, payload)
    if not parsed_ok or type(parsed) ~= "table" or type(parsed.row) ~= "table" or type(parsed.row.values) ~= "table" then
      cfg.config_system.notify("Prepared config is damaged: " .. tostring(name))
      return
    end
    cfg.config_system.apply(parsed.row.values)
    cfg.config_system.notify("Loaded prepared config: " .. name)
    return
  end
  if kind ~= "user" then
    cfg.config_system.notify("Select a config first.")
    return
  end
  local row = name and cfg.config_system.store[name] or nil
  if not row or type(row.values) ~= "table" then
    cfg.config_system.notify("Select a user config first.")
    return
  end
  cfg.config_system.apply(row.values)
  cfg.config_system.notify("Loaded user config: " .. name)
end
function cfg.config_system.create()
  local name = cfg.config_system.clean_name(cfg.config_name:get())
  if name == "" then
    cfg.config_system.notify("Enter a config name.")
    return
  end
  local conflict = cfg.config_system.name_conflict(name, true)
  if conflict == "prepared" or conflict == "reserved" then
    cfg.config_system.notify("This name is reserved by a prepared config.")
    return
  elseif conflict == "user" then
    cfg.config_system.notify("A config with this name already exists.")
    return
  end
  cfg.config_system.store[name] = {
    version = cfg.config_system.version,
    updated = os and os.time and os.time() or 0,
    values = cfg.config_system.capture()
  }
  cfg.config_system.persist()
  cfg.config_system.active_kind = "user"
  cfg.config_system.refresh(name)
  cfg.config_system.notify("Created config: " .. name)
end
function cfg.config_system.save()
  local name = cfg.config_system.user_selected()
  if cfg.config_system.active_kind ~= "user" or not name then
    cfg.config_system.notify("Prepared configs are read-only.")
    return
  end
  cfg.config_system.store[name] = {
    version = cfg.config_system.version,
    updated = os and os.time and os.time() or 0,
    values = cfg.config_system.capture()
  }
  cfg.config_system.persist()
  cfg.config_system.notify("Saved config: " .. name)
end
function cfg.config_system.delete()
  local name = cfg.config_system.user_selected()
  if cfg.config_system.active_kind ~= "user" or not name then
    cfg.config_system.notify("Prepared configs cannot be deleted.")
    return
  end
  cfg.config_system.store[name] = nil
  cfg.config_system.persist()
  cfg.config_system.active_kind = "builtin"
  cfg.config_system.refresh()
  cfg.config_system.notify("Deleted config: " .. name)
end
function cfg.config_system.export()
  local name = cfg.config_system.user_selected()
  local row = name and cfg.config_system.store[name] or nil
  if cfg.config_system.active_kind ~= "user" or not row then
    cfg.config_system.notify("Prepared configs cannot be exported.")
    return
  end
  local ok, err = pcall(function ()
    local clipboard = require("neverlose/clipboard")
    local prefix = cfg.config_system.profile == "ultimate" and "HELLSING_ULT_CFG_V1:" or "ANEMONE_CFG_V1:"
    clipboard.set(prefix .. json.stringify({ name = name, row = row }))
  end)
  if not ok then
    cfg.config_system.notify("Export failed: " .. tostring(err))
    return
  end
  cfg.config_system.notify("Exported to clipboard: " .. name)
end
function cfg.config_system.import()
  local ok, payload = pcall(function ()
    local clipboard = require("neverlose/clipboard")
    return clipboard.get()
  end)
  if not ok or type(payload) ~= "string" then
    cfg.config_system.notify("Could not read the clipboard.")
    return
  end
  local prefix = cfg.config_system.profile == "ultimate" and "HELLSING_ULT_CFG_V1:" or "ANEMONE_CFG_V1:"
  local payload_offset = #prefix + 1
  if payload:sub(1, #prefix) ~= prefix then
    local legacy_prefix = "EMBER" .. "LIGHT_CFG_V1:"
    if cfg.config_system.profile ~= "ultimate" and payload:sub(1, #legacy_prefix) == legacy_prefix then
      payload_offset = #legacy_prefix + 1
    else
      cfg.config_system.notify("Invalid Anemone config string.")
      return
    end
  end
  local parsed_ok, parsed = pcall(json.parse, payload:sub(payload_offset))
  if not parsed_ok or type(parsed) ~= "table" or type(parsed.row) ~= "table" or type(parsed.row.values) ~= "table" then
    cfg.config_system.notify("The imported config is damaged.")
    return
  end
  local requested = cfg.config_system.clean_name(cfg.config_name:get())
  local name = requested ~= "" and requested or cfg.config_system.clean_name(parsed.name)
  if name == "" then
    cfg.config_system.notify("Enter a name for the imported config.")
    return
  end
  local conflict = cfg.config_system.name_conflict(name, false)
  if conflict == "prepared" or conflict == "reserved" then
    cfg.config_system.notify("This name is reserved by a prepared config.")
    return
  end
  cfg.config_system.store[name] = parsed.row
  cfg.config_system.persist()
  cfg.config_system.active_kind = "user"
  cfg.config_system.refresh(name)
  cfg.config_system.notify("Imported config: " .. name)
end
cfg.config_list = cfg.config_panel:list("", {
  cfg.config_system.config_label({ "crown" }, "♛", "PWNZ$CRASH"),
  cfg.config_system.config_label({ "star", "asterisk" }, "★", "666TEST"),
  "---------------------------------------",
  "No user configs"
})
cfg.config_name = cfg.config_panel:input("Configs Name")
cfg.config_create = cfg.config_panel:button(cfg.config_system.colored_icon({ "circle-plus", "plus" }, "+", "55D66BFF"), function ()
  cfg.config_system.create()
end, true)
cfg.config_load = cfg.config_panel:button("Load", function ()
  cfg.config_system.load_active()
end, true)
cfg.config_save = cfg.config_panel:button("Save", function ()
  cfg.config_system.save()
end, true)
cfg.config_import = cfg.config_panel:button("Import", function ()
  cfg.config_system.import()
end, true)
cfg.config_export = cfg.config_panel:button("Export", function ()
  cfg.config_system.export()
end, true)
cfg.config_delete = cfg.config_panel:button(cfg.config_system.colored_icon({ "trash", "trash-can" }, "×", "FF4D5AFF"), function ()
  cfg.config_system.delete()
end, true)
pcall(function ()
  local beta_saved = db.anemone_user_configs_v1
  if type(beta_saved) ~= "table" then
    beta_saved = db["ember" .. "light_user_configs_v1"]
    if type(beta_saved) == "table" then db.anemone_user_configs_v1 = beta_saved end
  end
  local ultimate_saved = db.hellsing_ultimate_user_configs_v1
  if type(beta_saved) == "table" then cfg.config_system.stores.beta = beta_saved end
  if type(ultimate_saved) == "table" then cfg.config_system.stores.ultimate = ultimate_saved end
end)
cfg.config_system.profile = "beta"
cfg.config_system.store = cfg.config_system.stores.beta
cfg.config_system.refresh()
pcall(function ()
  cfg.config_list:set_callback(function ()
    local kind, name = cfg.config_system.current_entry()
    cfg.config_system.active_kind = kind or "none"
    if kind == "user" and name then
      cfg.config_name:set(name)
    elseif kind ~= "user" then
      cfg.config_name:set("")
    end
    cfg.config_system.sync_actions()
  end, true)
end)
local info = ui.create(cfg.main_tab, "\226\128\140", 1)
local function info_button(group, title, value)
  local icon_names = title == "User" and { "user", "circle-user", "user-circle" } or title == "Build" and { "cube", "layer-group", "code" } or title == "Version" and { "code-branch", "code", "layer-group" } or { "clock", "calendar", "rotate" }
  group:label(label(icon(icon_names), info_text(title)))
  local text = " " .. info_text(value) .. " "
  local ok, item = pcall(function ()
    return group:button(WHITE .. text .. RESET, nil, true)
  end)
  if ok then
    return item
  end
  return group:label(WHITE .. text .. RESET)
end
local function open_external_url(url)
  if type(url)~="string" or #url>2048 or url:find("[%z\1-\32]") or not url:match("^https?://[%w%.%-]+") then
    warn_once("url_invalid","Invalid external URL; no browser call made.");return false
  end
  local ok=pcall(function ()
    local api=panorama.SteamOverlayAPI
    if not api or type(api.OpenExternalBrowserURL)~="function" then error("overlay API unavailable") end
    local result=api.OpenExternalBrowserURL(url)
    if result==false then error("overlay rejected URL") end
  end)
  if not ok then
    ok=pcall(function ()
      local api=panorama.CSGOMainMenu.SteamOverlayAPI
      if not api or type(api.OpenExternalBrowserURL)~="function" then error("menu overlay API unavailable") end
      local result=api.OpenExternalBrowserURL(url)
      if result==false then error("overlay rejected URL") end
    end)
  end
  if not ok then
    console_line("[Anemone URL] Open manually: "..url)
    warn_once("open_url","Steam overlay could not open the link; URL printed to console.")
  end
  return ok
end
cfg.version_user_info = info_button(info, "User", client_nick())
cfg.version_build_info = info_button(info, "Build", "Beta")
cfg.version_number_info = info_button(info, "Version", cfg.version_state.lua_version)
cfg.version_updated_info = info_button(info, "Updated", cfg.version_state.beta_updated)
local info_links = ui.create(cfg.main_tab, "\226\129\160", 1)
info_links:label(label(icon({ "user-pen", "pen", "user" }), "Created"))
local author_cell = info_links:button(" PWNZ ", nil, true)
info_links:label(label(icon({ "link", "globe", "earth" }), "URL"))
local social_links = {
  {
    "Discord",
    "https://discord.gg/cey7mgz75P",
    { "discord" }
  },
  {
    "Telegram",
    "https://t.me/crackdildo",
    { "telegram", "paper-plane" }
  },
  {
    "YouTube",
    "https://www.youtube.com/@nos1st3m",
    { "youtube", "play" }
  },
}
cfg.version_social_buttons = { }
for _, social in ipairs(social_links) do
  local glyph = icon(social[3])
  local caption = glyph ~= "" and glyph or social[1]
  local button = info_links:button(WHITE .. " " .. caption .. " " .. RESET, function ()
    open_external_url(social[2])
  end, true)
  cfg.version_social_buttons[#cfg.version_social_buttons + 1] = { button, caption }
  tooltip(button, social[1] .. ": " .. social[2])
end
local funcs = ui.create(cfg.main_tab, "\226\128\141", 1)
local N
do
  local ems = rawget(_G, "__ANEMONE_MISS_STATE_V2")
  if type(ems) ~= "table" then
    ems = { }
  end
  if type(ems.miss_log) ~= "table" then
    ems.miss_log = { }
  end
  if type(ems.bucket_stats) ~= "table" then
    ems.bucket_stats = { }
  end
  if type(ems.miss_counts) ~= "table" then
    ems.miss_counts = { }
  end
  if type(ems.ack_stats) ~= "table" then
    ems.ack_stats = { hits = 0, misses = 0, correction = 0, unmatched = 0 }
  end
  if type(ems.mode_stats) ~= "table" then
    ems.mode_stats = { }
  end
  if type(ems.delta_stats) ~= "table" then
    ems.delta_stats = { }
  end
  if type(ems.population) ~= "table" then
    ems.population = { acks = 0, hits = 0, misses = 0, correlated = 0, matched = 0, learned = 0, wide_rejects = 0 }
  end
  _G.__ANEMONE_MISS_STATE_V2 = ems
end
local Y = {
  miss_owner = { },
  miss_state = _G.__ANEMONE_MISS_STATE_V2,
  suspended = false,
  fault = nil,
  enabled = false,
  yielded = false,
  last_status = "Yaw-Resolver: OFF",
  last_check = 0,
  native_ref = nil,
  brute = 0,
  brute_target = nil,
  last_miss = 0,
  miss_target = nil,
  last_target = nil,
  last_angles = nil,
  last_write = 0,
  writes = 0,
  blocked = 0,
  mode = "off",
  learn = { },
  shots = { },
  ack_fallbacks = 0,
  miss_log = _G.__ANEMONE_MISS_STATE_V2.miss_log,
  bucket_stats = _G.__ANEMONE_MISS_STATE_V2.bucket_stats,
  miss_counts = _G.__ANEMONE_MISS_STATE_V2.miss_counts,
  ack_stats = _G.__ANEMONE_MISS_STATE_V2.ack_stats,
  mode_stats = _G.__ANEMONE_MISS_STATE_V2.mode_stats,
  delta_stats = _G.__ANEMONE_MISS_STATE_V2.delta_stats,
  population = _G.__ANEMONE_MISS_STATE_V2.population,
  last_decay = 0,
}
Y.miss_state.owner = Y.miss_owner
Y.core=(function()
local function create_ffi_core(env)
  local M={ready=false,fault=nil,epoch=1,captures=0,matches=0,cache_hits=0,cache_misses=0,jump_calls=0,particle_dropped=0}
  local function finite(v)return type(v)=="number" and v==v and math.abs(v)<math.huge end
  local keys={"uid","sim","x","y","z","vx","vy","vz","duck","flags"}
  local ok,why=pcall(function()
    local f=assert(env.ffi,"LuaJIT FFI unavailable")
    assert(env.platform_ok==true,"Windows x86 LuaJIT required")
    if not pcall(f.typeof,"anemone_core_snapshot_v47")then
      f.cdef([[typedef struct { double uid,sim,x,y,z,vx,vy,vz,duck,flags,tick,generation; } anemone_core_snapshot_v47;
        typedef struct { anemone_core_snapshot_v47 source; double interval,ticks,time,valid; } anemone_core_prediction_v47;
        typedef struct { double vx,vy,yaw,interval,accel,speed,forward,side; } anemone_core_motion_v47;
        typedef struct { double x,y,z,vx,vy,vz,size,scale,born,life,phase,line; } anemone_core_particle_v47;
        typedef struct { double x,y,z,damage; } anemone_core_ray_v47;]])
    end
    assert(f.sizeof("anemone_core_snapshot_v47")==96 and f.sizeof("anemone_core_motion_v47")==64 and f.sizeof("anemone_core_particle_v47")==96,"FFI core schema mismatch")
    M.ffi=f;M.snapshots=f.new("anemone_core_snapshot_v47[65]");M.predictions=f.new("anemone_core_prediction_v47[65]");M.motion=f.new("anemone_core_motion_v47[1]")
    M.ray_banks=f.new("anemone_core_ray_v47[2][64]")
    M.kill={buffer=f.new("anemone_core_particle_v47[120]"),n=0,capacity=120}
    M.hit={buffer=f.new("anemone_core_particle_v47[256]"),n=0,capacity=256}
    M.ready=true
  end)
  if not ok then M.fault=tostring(why);M.ready=false end
  local function valid_id(id)return finite(id)and id%1==0 and id>=1 and id<=64 end
  local function valid_snapshot(d)
    if type(d)~="table"then return false end
    for _,k in ipairs(keys)do if not finite(d[k])then return false end end
    return d.uid>0 and d.uid%1==0 and d.sim>=0 and d.duck>=0 and d.duck<=1 and d.flags>=0 and d.flags%1==0 and math.max(math.abs(d.x),math.abs(d.y),math.abs(d.z))<=1e7 and math.max(math.abs(d.vx),math.abs(d.vy),math.abs(d.vz))<=4096
  end
  local function equal(a,d)
    for _,k in ipairs(keys)do if tonumber(a[k])~=d[k]then return false end end
    return true
  end
  function M:capture(id,d)
    if not self.ready or not valid_id(id)or not valid_snapshot(d)or not finite(d.tick)or d.tick<0 or d.tick%1~=0 then return false end
    local q=self.snapshots[id]
    if not equal(q,d)or d.tick<tonumber(q.tick)then q.generation=q.generation+1;self.predictions[id].valid=0 end
    for _,k in ipairs(keys)do q[k]=d[k]end;q.tick=d.tick
    self.captures=self.captures+1;return true
  end
  function M:matches_live(d,tick)
    if not self.ready or not valid_id(d.id)or not valid_snapshot(d)or not finite(tick)then return false end
    local q=self.snapshots[d.id];local age=tick-tonumber(q.tick)
    if age<0 or age>2 or not equal(q,d)then return false end
    self.matches=self.matches+1;return true
  end
  function M:prediction_match(d,iv,ticks,t)
    if not self.ready or not valid_id(d.id)or not valid_snapshot(d)or not finite(t)then return false end
    local p=self.predictions[d.id];local age=t-tonumber(p.time)
    local yes=tonumber(p.valid)==1 and age>=0 and age<=0.12 and tonumber(p.interval)==iv and tonumber(p.ticks)==ticks and equal(p.source,d)
    if yes then self.cache_hits=self.cache_hits+1 else self.cache_misses=self.cache_misses+1 end
    return yes
  end
  function M:prediction_commit(d,iv,ticks,t)
    if not self.ready or not valid_id(d.id)or not valid_snapshot(d)or not finite(iv)or iv<=0 or iv>0.1 or not finite(ticks)or ticks%1~=0 or ticks<1 or ticks>15 or not finite(t)then return false end
    local p=self.predictions[d.id]
    for _,k in ipairs(keys)do p.source[k]=d[k]end
    p.interval,p.ticks,p.time,p.valid=iv,ticks,t,1;return true
  end
  function M:counter_motion(vx,vy,yaw,iv,accel)
    if not self.ready or not finite(vx)or not finite(vy)or not finite(yaw)or not finite(iv)or iv<=0 or iv>0.1 or not finite(accel)or accel<=0 or accel>1000 then return nil end
    local q=self.motion[0];q.vx,q.vy,q.yaw,q.interval,q.accel=vx,vy,yaw,iv,accel
    q.speed=math.sqrt(vx*vx+vy*vy)
    if q.speed>=110 then return nil end
    local r=yaw*math.pi/180;local scale=math.min(8,1/(accel*iv))
    if q.speed<=8 then q.forward,q.side=0,0 else
      q.forward=math.max(-180,math.min(180,(-math.cos(r)*q.vx-math.sin(r)*q.vy)*scale))
      q.side=math.max(-180,math.min(180,(math.sin(r)*q.vx-math.cos(r)*q.vy)*scale))
    end
    self.jump_calls=self.jump_calls+1;return tonumber(q.forward),tonumber(q.side)
  end
  function M:particle_new(pool)
    if not self.ready or not pool then return nil end
    if pool.n>=pool.capacity then self.particle_dropped=self.particle_dropped+1;return nil end
    local p=pool.buffer[pool.n];pool.n=pool.n+1;return p
  end
  function M:particle_remove(pool,index)
    if not pool or index<0 or index>=pool.n then return false end
    pool.n=pool.n-1;if index~=pool.n then pool.buffer[index]=pool.buffer[pool.n]end;return true
  end
  function M:reset()
    if not self.ready then return end
    self.ffi.fill(self.snapshots,self.ffi.sizeof(self.snapshots));self.ffi.fill(self.predictions,self.ffi.sizeof(self.predictions))
    self.kill.n,self.hit.n=0,0;self.epoch=self.epoch+1
  end
  function M:report_lines()
    return {"FFI core v49 ready="..tostring(self.ready).." fault="..tostring(self.fault).."; runtime requires FFI, no observation Lua fallback; this is NOT copy protection",
      string.format("FFI core snapshots=%d exact_matches=%d prediction_cache=%d/%d jump_calls=%d particles=%d/%d allocation_refusals=%d epoch=%d",self.captures,self.matches,self.cache_hits,self.cache_misses,self.jump_calls,self.kill and self.kill.n or 0,self.hit and self.hit.n or 0,self.particle_dropped,self.epoch),
      "FFI core private memory only: snapshots/movement/prediction keys/visual pools are NOT pointers transferred to Neverlose; guarded native matrix bridge remains separate"}
  end
  return M
end

local ok,f=pcall(require,"ffi")
return create_ffi_core({ffi=ok and f or nil,platform_ok=ok and f.os=="Windows" and f.sizeof("void*")==4})
end)()
EVENT_CHAIN.core=Y.core
if not Y.core.ready then warn_once("ffi_core", "FFI core unavailable; gameplay callbacks disabled: "..tostring(Y.core.fault))end
function Y.print_banner()
  local banner
  if false then
    banner = {
      "██╗  ██╗███████╗██╗     ██╗     ███████╗██╗███╗   ██╗ ██████╗ ",
      "██║  ██║██╔════╝██║     ██║     ██╔════╝██║████╗  ██║██╔════╝ ",
      "███████║█████╗  ██║     ██║     ███████╗██║██╔██╗ ██║██║  ███╗",
      "██╔══██║██╔══╝  ██║     ██║     ╚════██║██║██║╚██╗██║██║   ██║",
      "██║  ██║███████╗███████╗███████╗███████║██║██║ ╚████║╚██████╔╝",
      "╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝╚══════╝╚═╝╚═╝  ╚═══╝ ╚═════╝ "
    }
  else
    banner = {
      " █████╗  ███╗   ██╗ ███████╗ ███╗   ███╗  ██████╗  ███╗   ██╗ ███████╗",
      "██╔══██╗ ████╗  ██║ ██╔════╝ ████╗ ████║ ██╔═══██╗ ████╗  ██║ ██╔════╝",
      "███████║ ██╔██╗ ██║ █████╗   ██╔████╔██║ ██║   ██║ ██╔██╗ ██║ █████╗  ",
      "██╔══██║ ██║╚██╗██║ ██╔══╝   ██║╚██╔╝██║ ██║   ██║ ██║╚██╗██║ ██╔══╝  ",
      "██║  ██║ ██║ ╚████║ ███████╗ ██║ ╚═╝ ██║ ╚██████╔╝ ██║ ╚████║ ███████╗",
      "╚═╝  ╚═╝ ╚═╝  ╚═══╝ ╚══════╝ ╚═╝     ╚═╝  ╚═════╝  ╚═╝  ╚═══╝ ╚══════╝"
    }
  end
  for i = 1, #banner do
    console_line(banner[i])
  end
end
local YAW_OVERRIDE_PATHS = {
  { "Aimbot", "Ragebot", "Main", "Enabled", "Override Resolver" },
  { "Aimbot", "Ragebot", "Resolver", "Enabled" },
  { "Aimbot", "Ragebot", "Resolver", "Override Resolver" },
  { "Aimbot", "Ragebot", "Resolver" },
  { "Aimbot", "Ragebot", "Override Resolver" },
}
local function Y_find_native()
  local now = clock()
  if Y.native_ref and now - Y.last_check < 30 then
    return Y.native_ref
  end
  Y.last_check = now
  for _, path in ipairs(YAW_OVERRIDE_PATHS) do
    local ok, ref = pcall(function ()
      if # path == 1 then
        return ui.find(path[1])
      end
      if # path == 2 then
        return ui.find(path[1], path[2])
      end
      if # path == 3 then
        return ui.find(path[1], path[2], path[3])
      end
      if # path == 4 then
        return ui.find(path[1], path[2], path[3], path[4])
      end
      return ui.find(path[1], path[2], path[3], path[4], path[5])
    end)
    if ok and ref then
      Y.native_ref = ref
      return ref
    end
  end
  Y.native_ref = nil
  return nil
end
local function Y_native_on()
  local ref = Y_find_native()
  if not ref then
    return false
  end
  local ok, value = pcall(function ()
    return ref:get()
  end)
  return ok and value == true
end
local function Y_angle(ent)
  local ok, ang = pcall(function ()
    return ent:get_eye_angles()
  end)
  if ok and ang and number(ang.y) then
    return number(ang.y), "eye"
  end
  local ok2, ang2 = pcall(function ()
    return ent.m_angEyeAngles
  end)
  if ok2 and ang2 and number(ang2.y) then
    return number(ang2.y), "eye"
  end
  local ok3, ang3 = pcall(function ()
    return ent:get_angles()
  end)
  if ok3 and ang3 and number(ang3.y) then
    return number(ang3.y), "shared"
  end
  return nil, nil
end
local function Y_velocity(ent)
  local ok, vel = pcall(function ()
    return ent.m_vecVelocity
  end)
  if ok and vel and number(vel.x) and number(vel.y) then
    local vx, vy = number(vel.x), number(vel.y)
    local speed = math.sqrt(vx * vx + vy * vy)
    if speed > 0.01 then
      return math.deg(math.atan2(vy, vx)), speed
    end
  end
  return nil, 0
end
local function Y_lby(ent)
  local ok, value = pcall(function ()
    return ent.m_flLowerBodyYawTarget
  end)
  if ok and number(value) then
    return number(value)
  end
  return nil
end
local function Y_norm(a)
  while a > 180 do
    a = a - 360
  end
  while a < - 180 do
    a = a + 360
  end
  return a
end
local function Y_pose_delta(ent)
  local ok, value = pcall(function ()
    local v = entity.get_prop(ent, "m_flPoseParameter", 11)
    if number(v) then
      return number(v)
    end
    local arr = ent.m_flPoseParameter
    if type(arr) == "table" and number(arr[11]) then
      return number(arr[11])
    end
    if type(arr) == "table" and number(arr[12]) then
      return number(arr[12])
    end
    return nil
  end)
  if not ok or not number(value) then
    return nil
  end
  if value >= 0 and value <= 1.2 then
    return clamp((value - 0.5) * 120, - 60, 60)
  end
  if value >= - 1.2 and value <= 1.2 then
    return clamp(value * 60, - 60, 60)
  end
  return clamp(value, - 60, 60)
end
local function Y_duck_amount(ent)
  local ok, value = pcall(function ()
    return ent.m_flDuckAmount
  end)
  if ok and number(value) then
    return clamp(number(value), 0, 1)
  end
  local ok2, value2 = pcall(function ()
    return entity.get_prop(ent, "m_flDuckAmount")
  end)
  if ok2 and number(value2) then
    return clamp(number(value2), 0, 1)
  end
  return 0
end
local function Y_circular_mean(values, first)
  if not values or # values == 0 then
    return nil
  end
  local sx, sy, count = 0, 0, 0
  for i = first or 1, # values do
    local r = math.rad(values[i])
    sx, sy, count = sx + math.cos(r), sy + math.sin(r), count + 1
  end
  if count == 0 or (math.abs(sx) < 0.0001 and math.abs(sy) < 0.0001) then
    return values[# values]
  end
  return Y_norm(math.deg(math.atan2(sy, sx)))
end
local function Y_track_jitter(L, yaw_now, tick, state)
  if not yaw_now then
    return
  end
  yaw_now = Y_norm(yaw_now)
  tick = tonumber(tick) or 0
  if L.jhist_tick == tick then
    if L.jhist and # L.jhist > 0 then
      L.jhist[# L.jhist] = yaw_now
    end
    return
  end
  L.jhist_tick = tick
  local h = L.jhist
  if not h then
    h = { }
    ;
    L.jhist = h
  end
  h[# h + 1] = yaw_now
  if # h > 12 then
    table.remove(h, 1)
  end
  if # h < 3 then
    L.jitter, L.alternating, L.spin_score = 0, false, 0
    ;
    return
  end
  local first = math.max(2, # h - 7)
  local big, total, flips, same, considered, prev_delta, signed = 0, 0, 0, 0, 0, nil, 0
  for i = first, # h do
    local d = Y_norm(h[i] - h[i - 1])
    local ad = math.abs(d)
    total, signed = total + ad, signed + d
    if ad > 20 then
      big = big + 1
    end
    if ad > 8 then
      considered = considered + 1
      if prev_delta then
        if d * prev_delta < 0 then
          flips = flips + 1
        else
          same = same + 1
        end
      end
      prev_delta = d
    end
  end
  local intervals = # h - first + 1
  local avg = intervals > 0 and total / intervals or 0
  local flip_ratio = considered > 1 and flips / (considered - 1) or 0
  local same_ratio = considered > 1 and same / (considered - 1) or 0
  L.jcenter = Y_circular_mean(h, math.max(1, # h - 7))
  local amplitude = 0
  for i = math.max(1, # h - 7), # h do
    amplitude = amplitude + math.abs(Y_norm(h[i] - (L.jcenter or yaw_now)))
  end
  amplitude = amplitude / math.min(8, # h)
  L.jamp = clamp((L.jamp or amplitude) * 0.55 + amplitude * 0.45, 0, 60)
  L.jitter = clamp((big / math.max(1, intervals)) * 0.35 + (avg / 100) * 0.25 + flip_ratio * 0.30 + clamp(L.jamp / 55, 0, 1) * 0.10, 0, 1)
  L.phase_conf = flip_ratio
  L.alternating = flip_ratio > 0.60 and L.jamp > 14
  L.spin_score = same_ratio
  L.spin_step = considered > 0 and signed / considered or 0
  local delta = Y_norm(yaw_now - (L.jcenter or yaw_now))
  if math.abs(delta) > 7 then
    L.jitter_side = delta >= 0 and 1 or - 1
  end
end
local function Y_predicted(L, tick)
  local h = L.jhist
  if not h or # h < 4 then
    return nil
  end
  local center = L.jcenter or Y_circular_mean(h, math.max(1, # h - 7))
  if not center then
    return nil
  end
  local last = h[# h]
  local amplitude = clamp(L.jamp or 32, 18, 58)
  if L.alternating and (L.phase_conf or 0) > 0.55 then
    local side = Y_norm(last - center) >= 0 and - 1 or 1
    return Y_norm(center + side * amplitude)
  end
  if (L.spin_score or 0) > 0.70 and math.abs(L.spin_step or 0) > 10 then
    return Y_norm(last + clamp(L.spin_step, - 58, 58))
  end
  local side = L.jitter_side or (tick % 2 == 0 and 1 or - 1)
  return Y_norm(center + side * clamp(amplitude, 28, 50))
end
local function Y_state(ent, speed, duck, pose_delta)
  local flags = nil
  pcall(function ()
    flags = tonumber(ent.m_fFlags)
  end)
  if flags == nil then
    pcall(function ()
      flags = tonumber(entity.get_prop(ent, "m_fFlags"))
    end)
  end
  local airborne = flags ~= nil and not flag_set(flags, 1) or false
  local speed_factor = clamp(speed / 260, 0, 1)
  local modifier = 1 - 0.50 * speed_factor
  if duck > 0 then
    modifier = modifier + duck * speed_factor * (0.5 - modifier)
  end
  local delta = 58 * modifier
  if pose_delta and math.abs(pose_delta) > 12 then
    delta = delta * 0.70 + math.abs(pose_delta) * 0.30
  end
  if airborne then
    return "air", clamp(delta, 32, 48)
  end
  if duck > 0.55 and speed < 110 then
    return "duck", clamp(delta, 38, 58)
  end
  if speed < 3 then
    return "stand", clamp(delta, 52, 58)
  end
  if speed < 85 then
    return "slow", clamp(delta, 40, 56)
  end
  return "move", clamp(delta, 26, 45)
end
local function Y_desync_side(L, base, pose_delta, lby)
  local vote = 0
  if pose_delta and math.abs(pose_delta) > 5 then
    vote = vote + (pose_delta > 0 and 1 or - 1) * clamp(math.abs(pose_delta) / 30, 0.55, 1.45)
  end
  if lby then
    local d = Y_norm(lby - base)
    if math.abs(d) > 10 and math.abs(d) < 150 then
      vote = vote + (d > 0 and 1 or - 1)
    end
  end
  if L.jitter_side then
    vote = vote + L.jitter_side * 0.45
  end
  L.side_score = clamp((L.side_score or 0) * 0.72 + vote, - 4, 4)
  if math.abs(L.side_score) > 0.35 then
    L.side = L.side_score >= 0 and 1 or - 1
  end
  return L.side or 1
end
Y.PLAUSIBLE_AIM = {
  stand = 60, slow = 60, duck = 60,
  move = 75,
  air = 95
}
function Y.plausible_yaw(L, state, yaw)
  local anchor = tonumber(L and (L.__candidate_anchor or L.__base))
  if not anchor or not number(yaw) then
    return true
  end
  local limit = Y.PLAUSIBLE_AIM[state] or 60
  if math.abs(Y_norm(yaw - anchor)) <= limit then
    return true
  end
  L.resolve_wide_rejects = (L.resolve_wide_rejects or 0) + 1
  return false
end
function Y.filter_wide(L, list, state)
  local kept, dropped = 0, 0
  for i = 1, list.n do
    local c = list[i]
    if Y.plausible_yaw(L, state, c.yaw) then
      kept = kept + 1
      list[kept] = c
    else
      dropped = dropped + 1
    end
  end
  list.n = kept
  return dropped
end
function Y.gate_clamp(L, state, yaw)
  local anchor = tonumber(L and (L.__candidate_anchor or L.__base))
  local limit = Y.PLAUSIBLE_AIM[state] or 60
  if not anchor or not number(yaw) then
    return Y_norm(yaw)
  end
  local off = Y_norm(yaw - anchor)
  if math.abs(off) <= limit then
    return Y_norm(yaw)
  end
  return Y_norm(anchor + (off > 0 and 1 or - 1) * limit)
end
function Y.vel_alignment(L, vel_angle)
  local anchor = tonumber(L and L.__base)
  if not anchor or not number(vel_angle) then
    return 1
  end
  return 1 - clamp(math.abs(Y_norm(vel_angle - anchor)) / 75, 0, 1)
end
local function Y_new_list()
  local list = {
    n = 0,
    seen = { }
  }
  function list.add(bucket, value, prior)
    if value == nil or list.seen[bucket] then
      return
    end
    list.seen[bucket] = true
    list.n = list.n + 1
    list[list.n] = { bucket = bucket, yaw = Y_norm(value), prior = prior or 0 }
  end
  return list
end
local Y_PRIOR = {
  vel = 0.08,
  eye = - 0.05,
  eye_side = 0.14,
  eye_opp = 0.08,
  body = 0.18,
  lby = 0.10,
  lby_side = 0.11,
  st_opp = 0.20,
  hyb = 0.14,
  pred = - 0.08,
  feedback = 0.04,
  exp_side = - 0.06,
  exp_opp = - 0.04,
  brute = - 0.12,
  ["vel+180"] = - 0.80,
  ["eye+180"] = - 0.32,
  head_read = 0.12
}
local function Y_bucket_prior(bucket)
  local exact = Y_PRIOR[bucket]
  if exact ~= nil then
    return exact
  end
  if bucket:sub(1, 5) == "brute" then
    return Y_PRIOR.brute
  end
  local canonical = Y.canonical_bucket and Y.canonical_bucket(bucket, "unknown") or bucket
  if canonical ~= bucket then
    local mapped = Y_PRIOR[canonical]
    if mapped ~= nil then
      return mapped
    end
  end
  return 0
end
Y.canonical_buckets = {
  beta_body = "body",
  beta_lby = "lby",
  beta_lby_side = "lby_side",
  beta_side = "commit",
  beta_eye = "eye",
  beta_micro = "micro_lby",
  beta_lastmove = "last_move",
  beta_pred = "pred",
  beta_vel = "vel",
  beta_good = "good_anchor",
  beta_lbybreak = "lby_break",
  beta_defeye = "def_eye",
  beta_defhalf = "def_half",
  adaptive_side = "commit",
  adaptive_eye = "eye",
  adaptive_body = "body",
  adaptive_lby = "lby",
  adaptive_good = "good_anchor",
  adaptive_evalate = "body",
  adaptive_feedback = "feedback",
  adaptive_pred = "pred",
  adaptive_vel = "vel",
  adaptive_lbybreak = "lby_break",
  adaptive_defeye = "def_eye",
  ult_body = "body",
  ult_lby = "lby",
  ult_lby_side = "lby_side",
  ult_lbybreak = "lby_break",
  ult_good = "good_anchor",
  ult_cadence = "lby",
  ult_slow = "lby",
  ult_lby_exact = "lby",
  ult_feet = "body",
  ult_vel = "vel",
  ult_vel_side = "vel_side",
  ult_vel_opp = "vel_opp",
  ult_micro = "micro_lby",
  ult_lastmove = "last_move",
  ult_near = "near_eye",
  ult_pred = "pred",
  ult_hyb = "hyb",
  ult_commit = "commit",
  ult_opp = "eye_opp",
  ult_eye = "eye",
  ult_eye2 = "eye",
  ult_eye_side = "eye_side",
  ult_eye29 = "eye",
  ult_head_read = "head_read",
  adaptive_head = "head_read",
  ult_def_eye = "def_eye",
  ult_def_half = "def_half",
  ult_lby_moving = "lby",
  ult_evalate = "body",
  ult_feedback = "feedback",
}
function Y.canonical_bucket(bucket, state)
  if type(bucket) ~= "string" then
    return bucket
  end
  if bucket == "beta_opp" or bucket == "adaptive_opp" or bucket == "ult_opp" then
    return state == "air" and "vel_opp" or "eye_opp"
  end
  return Y.canonical_buckets[bucket] or bucket
end
local function Y_pick_learned(L, list, explore, state)
  Y.filter_wide(L, list, state)
  local best, best_score = nil, - 1e9
  local state_stats = L.by_state and L.by_state[state] or nil
  for i = 1, list.n do
    local c = list[i]
    local global = L[c.bucket]
    local rec = state_stats and state_stats[c.bucket] or nil
    local swh = rec and (rec.wh or rec.h or 0) or 0
    local swm = rec and (rec.wm or rec.m or 0) or 0
    local gwh = global and (global.wh or global.h or 0) or 0
    local gwm = global and (global.wm or global.m or 0) or 0
    local wh, wm = swh + gwh * 0.30, swm + gwm * 0.30
    local n = wh + wm
    local accuracy = (wh + 1.25) / (n + 2.5)
    local confidence = math.min(1, n / 7)
    local score = accuracy * 1.42 + confidence * 0.10 + Y_bucket_prior(c.bucket) + c.prior
if c.bucket == "vel" or c.bucket == "vel_side" or c.bucket == "vel_opp" then
      if state == "slow" or state == "stand" or state == "duck" then
        score = score - 0.22
      elseif state == "move" then
        score = score + 0.07 * Y.vel_alignment(L, c.yaw)
      elseif state == "air" then
        score = score + 0.28 * Y.vel_alignment(L, c.yaw)
      end
    elseif (c.bucket == "body" or c.bucket == "lby" or c.bucket == "lby_side") and (state == "stand" or state == "slow") then
      score = score + 0.09
    end
    if state == "air" and (c.bucket == "body" or c.bucket == "lby" or c.bucket == "lby_side" or c.bucket == "micro_lby" or c.bucket == "last_move" or c.bucket == "eye" or c.bucket == "eye_side" or c.bucket == "eye_opp" or c.bucket == "eye+29" or c.bucket == "pred" or c.bucket == "hyb") then
      score = score - 0.60
    end
    if explore then
      score = score + math.sqrt(1.2 / (n + 1)) * 0.03
    end
    local streak = rec and (rec.streak or 0) or global and (global.streak or 0) or 0
    if streak >= 2 then
      score = score - 0.22 * (streak - 1)
    end
    if score > best_score then
      best, best_score = c, score
    end
  end
  if not best then
    return nil, "none"
  end
  return best.yaw, best.bucket
end
local function yaw_mode()
  local ok, v = pcall(function ()
    return cfg.yaw_mode and cfg.yaw_mode:get()
  end)
  if ok and type(v) == "string" then
    return cfg.version_state.allowed_mode(v)
  end
  return cfg.version_state.tier_modes()[1]
end
function Y.path_active()
  return get_bool(cfg.resolver) and get_bool(cfg.yaw)
end
function Y.mode_label()
  if not get_bool(cfg.resolver) then return "Baseline" end
  if get_bool(cfg.assist) and not (get_bool(cfg.yaw)and yaw_mode()=="FFI")then return "Assist"end
  if not get_bool(cfg.yaw) then return "Baseline" end
  return yaw_mode()
end
-- Native activation follows the saved feature settings; no manual session authorization.
function Y.native_ready(level)
  return not cfg.runtime_paused and not ANEMONE_SECOND_COPY
end
function Y.native_requested()
  local mode=yaw_mode()
  return get_bool(cfg.resolver) and get_bool(cfg.yaw) and (not get_bool(cfg.assist)or mode=="FFI") and (mode=="Adaptive" or mode=="FFI") and not cfg.runtime_paused and not ANEMONE_SECOND_COPY and not Y.suspended and not Y.fault and not Y.yielded
end
function Y.native_threshold(state,detail)
  local threshold=0.50
  state=tostring(state or "unknown")
  if state:find("air",1,true) then threshold=0.60
  elseif state:find("duck",1,true) or (detail and tonumber(detail.duck) and tonumber(detail.duck)>=0.5) then threshold=0.55
  elseif state=="unknown" then threshold=0.65 end
  if detail then
    local q=tonumber(detail.record_quality);local jitter=tonumber(detail.jitter);local stability=tonumber(detail.stability)
    if q and q<0.60 then threshold=threshold+0.04 end
    if jitter and jitter>0.60 then threshold=threshold+0.05 end
    if stability and stability<3 then threshold=threshold+0.03 end
  end
  return math.max(0.50,math.min(0.75,threshold))
end
Y.native_policy={state="automatic",key=nil}
function Y.native_policy:sync()
  local mode=yaw_mode();local want=Y.native_requested()
  local key=table.concat({mode,tostring(want),tostring((true))},":")
  if self.key and self.key~=key then
    if Y.native_records then Y.native_records:restore_live() end
    if Y.native_trace then Y.native_trace:bridge_clear("native mode/helper policy changed") end
  end
  self.key=key
  for _,name in ipairs({"native_record_write","native_selector_trace","native_selector_bridge"})do
    if get_bool(cfg[name])~=want then cfg[name]:set(want) end
  end
  self.state=want and (mode..": native record writer and argument bridge requested") or (mode=="FFI" and "FFI withheld: native helper/context inactive; NO SDK fallback" or "native writer inactive; normal mode policy")
end
function Y.native_policy:report_lines()
  return {"Native activation=automatic from Resolver/Yaw; Native Records helper ALWAYS ON; no manual session buttons; pause/duplicate/context/fault checks retained",
    "Native automatic policy mode="..yaw_mode().." helper="..tostring((true)).." state="..self.state,
    "Native automatic patches=hitscan+lerp follow Resolver; extrap follows Extrapolation and Native tick limit; no manual session authorization",
    "Native automatic confidence=0.50 ground / 0.55 duck / 0.60 air / 0.65 unknown; quality/jitter/transition add bounded penalties; heuristic score NOT hit probability",
    "FFI mode scope=shared Adaptive candidate model, private transformed matrix buffers, immutable Anemone snapshots and guarded native return-pointer substitution; native record-ring insertion NOT implemented"}
end

local FEEDBACK_CFG = {
  ignore_no_impact = true,
  isolate_per_shot = true,
  static_aa_correction = true,
  shot_ttl = 3.0,
  shot_tick_ttl = 256,
  min_feedback_weight = 0.35,
  min_static_confidence = 0.50,
  max_learning_spread = 1.5,
  adaptive_ban_ticks = 128,
}
local LOG_CFG = {
  noise_spread = 0.30,
  bands = { 3, 8, 15, 25, 40 },
  max_rows = 800,
}
local function log_delta_band(v)
  local a = tonumber(v)
  if not a then
    return "?"
  end
  a = math.abs(a)
  local prev = 0
  for _, edge in ipairs(LOG_CFG.bands) do
    if a < edge then
      return string.format("%02d-%02d", prev, edge)
    end
    prev = edge
  end
  return string.format("%02d+", prev)
end
local function log_delta_side(shot)
  local s = shot and tonumber(shot.yaw_side) or nil
  if s == nil then
    local c = shot and tonumber(shot.yaw_corr) or nil
    s = c and (c >= 0 and 1 or - 1) or 0
  end
  return s > 0 and "R" or (s < 0 and "L" or "?")
end
local function feedback_decay(L, tick)
  tick = tonumber(tick) or 0
  local last = tonumber(L.feedback_tick)
  if last and tick > last then
    local elapsed = math.min(64, tick - last)
    local factor = math.max(0.55, 1 - elapsed * 0.025)
    L.feedback_bias = (tonumber(L.feedback_bias) or 0) * factor
    if math.abs(L.feedback_bias) < 0.35 then
      L.feedback_bias = 0
    end
  end
  L.feedback_tick = tick
end
local function feedback_corrected_yaw(L, base, tick, scale)
  feedback_decay(L, tick)
  local bias = tonumber(L.feedback_bias) or 0
  if math.abs(bias) < 5 then
    return nil
  end
  return Y_norm(base + bias * (scale or 1)), bias
end
Y.angel_cycle_size = { Beta = 12, Adaptive = 12, FFI = 12 }
function Y.angel_feedback(L, mode, hit, tick, state)
  if not L or not Y.angel_cycle_size[mode] then
    return
  end
  L.angel = L.angel or { }
  local row = L.angel[mode] or { phase = 0, misses = 0, state = state }
  L.angel[mode] = row
  if hit then
    row.phase, row.misses, row.last_tick = 0, 0, tick
    row.state = state
    return
  end
  if row.state ~= state or (row.last_tick and (tick < row.last_tick or tick - row.last_tick > 192)) then
    row.phase, row.misses = 0, 0
  end
  row.state = state
  row.misses = math.min(32, (row.misses or 0) + 1)
  local size = Y.angel_cycle_size[mode]
  row.phase = size and (((row.phase or 0) % size) + 1) or 0
  row.last_tick = tick
end
function Y.angel_phase_candidate(L, mode, base, vel_angle, lby, side, state, delta, tick)
  local row = L and L.angel and L.angel[mode] or nil
  if not row or not number(row.phase) or row.phase <= 0 then
    return nil
  end
  if row.last_tick and (tick < row.last_tick or tick - row.last_tick > 192) then
    row.phase, row.misses = 0, 0
    return nil
  end
  base = number(base) or 0
  side = number(side) and (side >= 0 and 1 or - 1) or 1
  delta = clamp(number(delta) or 0, 0, 60)
  local phase = math.floor(row.phase)
  local body = number(L.body_hint) and L.body_hint or nil
  local yaw
  if phase <= 8 then
    local step = phase <= 2 and delta * 0.25 or phase <= 4 and delta * 0.50 or phase <= 6 and delta * 0.75 or delta
    yaw = base + (phase % 2 == 0 and - 1 or 1) * step
  elseif phase == 9 then
    yaw = lby or (base + side * delta * 0.875)
  elseif phase == 10 then
    yaw = body or (base - side * delta * 0.375)
  elseif phase == 11 then
    yaw = base
  else
    local raw = number(vel_angle)
    local bound = delta * 0.625
    yaw = raw and (base + clamp(Y_norm(raw - base), - bound, bound)) or base
  end
  return Y_norm(yaw), "aw_phase_" .. string.lower(mode)
end
function Y:reset_angel_all()
  self.timing_states = {}
  for _, L in pairs(self.learn) do
    if type(L) == "table" then
      L.angel = nil
    end
  end
end
function Y:reset_angel_event(event, drop)
  local uid = event and tonumber(event.userid) or nil
  if not uid then
    return
  end
  local ent = nil
  pcall(function ()
    ent = entity.get(uid, true)
  end)
  local idx = nil
  if ent then
    pcall(function ()
      idx = ent:get_index()
    end)
  end
  if not number(idx) then
    return
  end
  if drop then
    self.learn[idx] = nil
  elseif self.learn[idx] then
    self.learn[idx].angel = nil
  end
  if self.brute_target == idx then
    self.brute, self.brute_target = 0, nil
  end
end
function Y.evalate_signal(L, base, pose_delta, lby, max_delta, tick, state)
  tick = tonumber(tick) or 0
  local pose = tonumber(pose_delta)
  local goal = number(lby) and Y_norm(lby) or (pose and Y_norm(base + pose) or nil)
  if not goal then
    L.evalate_forced, L.evalate_yaw, L.evalate_confidence = nil, nil, 0
    return nil
  end
  local sample = { tick = tick, pose = pose, eye_yaw = base, goal_feet_yaw = goal }
  if L.evalate_tick ~= tick then
    L.evalate_prev = L.evalate_last
    L.evalate_last = sample
    L.evalate_tick = tick
  else
    L.evalate_last = sample
  end
  local previous_pose = L.evalate_prev and tonumber(L.evalate_prev.pose) or nil
  local body_pose = previous_pose or pose
  local goal_delta = Y_norm(goal - base)
  local direction = goal_delta > 0 and 1 or (goal_delta < 0 and - 1 or 0)
  local brute = tonumber(L.evalate_brute) or 1
  brute = brute >= 0 and 1 or - 1
  L.evalate_brute = brute
  local desync_ratio = clamp((tonumber(max_delta) or 0) / 58, 0, 1)
  if not body_pose or math.abs(body_pose) < 5 or desync_ratio < 0.55 then
    L.evalate_forced, L.evalate_yaw, L.evalate_confidence = nil, nil, 0
    return nil
  end
  local signed = direction ~= 0 and direction or brute
  local forced = clamp(math.abs(body_pose) * signed * brute, - 60, 60)
  local static_bonus = (state == "stand" or state == "slow" or state == "duck") and 0.20 or 0
  local confidence = clamp(math.abs(body_pose) / 42 * 0.45 + desync_ratio * 0.35 + static_bonus, 0, 1)
  L.evalate_forced = forced
  L.evalate_yaw = Y_norm(base + forced)
  L.evalate_confidence = confidence
  return L.evalate_yaw, confidence
end
local function track_stability(L, state, speed, base, lby, tick)
  if L.stability_tick == tick then
    return
  end
  local gap = L.stability_tick and tick - L.stability_tick or 1
  local same = L.stability_state == state and gap > 0 and gap <= 3
  L.state_stability = same and math.min(12, (L.state_stability or 0) + 1) or 1
  L.stability_state, L.stability_tick = state, tick
  local static = state == "stand" or state == "slow" or state == "duck"
  local body_delta = lby and math.abs(Y_norm(lby - base)) or 0
  local evidence = math.max(clamp((L.body_strength or 0) / 38, 0, 1), clamp(body_delta / 44, 0, 1), clamp((L.jitter or 0) / 0.72, 0, 1))
  local stable = clamp((L.state_stability or 0) / 6, 0, 1)
  L.static_evidence = static and evidence or 0
  L.static_confidence = static and clamp(stable * 0.55 + evidence * 0.45, 0, 1) or 0
  L.break_lc = gap > 3
  L.__speed = speed
end
function Y.aim_at_me(ent)
  local me = nil
  pcall(function ()
    me = entity.get_local_player()
  end)
  if not me or not ent then
    return nil
  end
  local my_origin = nil
  pcall(function ()
    my_origin = me:get_origin()
  end)
  if not my_origin or not number(my_origin.x) or not number(my_origin.y) then
    return nil
  end
  local en_origin = nil
  pcall(function ()
    en_origin = ent:get_origin()
  end)
  if not en_origin or not number(en_origin.x) or not number(en_origin.y) then
    return nil
  end
  local dx, dy = my_origin.x - en_origin.x, my_origin.y - en_origin.y
  if math.abs(dx) < 0.01 and math.abs(dy) < 0.01 then
    return nil
  end
  return Y_norm(math.deg(math.atan2(dy, dx)))
end
function Y.distance_sqr(ent)
  local me = nil
  pcall(function ()
    me = entity.get_local_player()
  end)
  if not me or not ent then
    return nil
  end
  local a, b = nil, nil
  pcall(function ()
    a = me:get_origin()
    b = ent:get_origin()
  end)
  if not a or not b or not number(a.x) or not number(b.x) then
    return nil
  end
  local dx, dy, dz = a.x - b.x, a.y - b.y, (a.z or 0) - (b.z or 0)
  return dx * dx + dy * dy + dz * dz
end
function Y.game_context(L, ent, state, speed, duck, tick)
  if not L or not ent then return end
  local flags, move_type, life_state
  pcall(function () flags = tonumber(ent.m_fFlags) end)
  if flags == nil then pcall(function () flags = tonumber(entity.get_prop(ent, "m_fFlags")) end) end
  pcall(function () move_type = tonumber(ent.m_MoveType) end)
  if move_type == nil then pcall(function () move_type = tonumber(entity.get_prop(ent, "m_MoveType")) end) end
  pcall(function () life_state = tonumber(ent.m_lifeState) end)
  if life_state == nil then pcall(function () life_state = tonumber(entity.get_prop(ent, "m_lifeState")) end) end
  L.game_grounded = flags ~= nil and flag_set(flags, 1) or false
  L.game_move_type = move_type
  L.game_life_state = life_state
  L.game_state = state
  L.game_speed = tonumber(speed) or 0
  L.game_duck = tonumber(duck) or 0
  L.game_special = move_type == 8 or move_type == 9 or move_type == 10
  L.game_context_tick = tick
end
function Y.head_signal(L, ent, base, tick)
  if not L or not ent or not get_bool(cfg.adaptive_head) then
    L.head_valid, L.head_confidence = false, 0
    return
  end
  if L.head_tick and tick and tick >= L.head_tick and tick - L.head_tick < 2 then
    return
  end
  L.head_tick = tick
  local me = nil
  pcall(function () me = entity.get_local_player() end)
  if not me then
    L.head_valid, L.head_confidence = false, 0
    return
  end
  local head, neck, chest, enemy_origin, local_origin, local_head
  pcall(function () head = ent:get_hitbox_position(0) end)
  pcall(function () neck = ent:get_hitbox_position(1) end)
  pcall(function () chest = ent:get_hitbox_position(2) end)
  pcall(function () enemy_origin = ent:get_origin() end)
  pcall(function () local_origin = me:get_origin() end)
  pcall(function () local_head = me:get_hitbox_position(0) end)
  if local_head and number(local_head.x) and number(local_head.y) and number(local_head.z) then
    local_origin = local_head
  end
  if not head or not number(head.x) or not number(head.y) or not number(head.z) then head = neck end
  if not head or not number(head.x) or not number(head.y) or not number(head.z) or not local_origin or not number(local_origin.x) or not number(local_origin.y) or not number(local_origin.z) then
    L.head_valid, L.head_confidence = false, 0
    return
  end
  local hx, hy, hz = head.x, head.y, head.z
  if neck and number(neck.x) and number(neck.y) and number(neck.z) then
    hx, hy, hz = head.x * 0.82 + neck.x * 0.18, head.y * 0.82 + neck.y * 0.18, head.z * 0.82 + neck.z * 0.18
  elseif chest and number(chest.x) and number(chest.y) and number(chest.z) then
    hx, hy, hz = head.x * 0.90 + chest.x * 0.10, head.y * 0.90 + chest.y * 0.10, head.z * 0.90 + chest.z * 0.10
  end
  local dx, dy = local_origin.x - hx, local_origin.y - hy
  if math.abs(dx) < 0.01 and math.abs(dy) < 0.01 then
    L.head_valid, L.head_confidence = false, 0
    return
  end
  local head_yaw = Y_norm(math.deg(math.atan2(dy, dx)))
  local head_delta = math.abs(Y_norm(head_yaw - (number(base) or head_yaw)))
  local height = enemy_origin and number(enemy_origin.z) and hz - enemy_origin.z or 0
  local history = L.head_history or { }
  L.head_history = history
  history[# history + 1] = { tick = tick, yaw = head_yaw, x = hx, y = hy, z = hz }
  while # history > 8 do table.remove(history, 1) end
  local sample_count = # history
  local yaw_jitter, point_jitter = 0, 0
  if sample_count >= 2 then
    local prev = history[sample_count - 1]
    yaw_jitter = math.abs(Y_norm(head_yaw - prev.yaw))
    local pdx, pdy, pdz = hx - prev.x, hy - prev.y, hz - prev.z
    point_jitter = math.sqrt(pdx * pdx + pdy * pdy + pdz * pdz)
  end
  local stable_samples = clamp(1 - yaw_jitter / 42, 0, 1)
  local stable_points = clamp(1 - point_jitter / 18, 0, 1)
  local temporal = sample_count >= 3 and (stable_samples * 0.65 + stable_points * 0.35) or 0
  local state_stability = clamp((tonumber(L.state_stability) or 0) / 6, 0, 1)
  local trace_ok = nil
  if utils and type(utils.trace_line) == "function" then
    pcall(function ()
      local fraction = utils.trace_line(local_origin, { x = hx, y = hy, z = hz }, me)
      if number(fraction) then trace_ok = fraction >= 0.97 end
    end)
  end
  local visibility = trace_ok == nil and 0.50 or (trace_ok and 1.0 or 0.0)
  L.head_yaw = head_yaw
  L.head_delta = head_delta
  L.head_height = height
  L.head_exposure = clamp((height - 42) / 24, 0, 1)
  L.head_jitter = yaw_jitter
  L.head_point_jitter = point_jitter
  L.head_samples = sample_count
  L.head_visible = trace_ok
  L.head_confidence = clamp(
    (head_delta <= 75 and 0.22 or 0) +
    temporal * 0.34 +
    state_stability * 0.14 +
    L.head_exposure * 0.08 +
    visibility * 0.22,
    0, 1
  )
  L.head_valid = sample_count >= 3 and (trace_ok ~= false) and L.head_confidence >= 0.58
end
function Y.context_signal(L, state, speed, pose_delta, lby, base, tick)
  if L.context_tick == tick then
    return
  end
  local gap = L.context_tick and tick - L.context_tick or 1
  L.context_tick = tick
  if number(lby) then
    local prev = tonumber(L.lby_prev_yaw)
    if prev then
      local d = math.abs(Y_norm(lby - prev))
      if d > 25 then
        L.lby_break_tick = tick
        L.lby_break_yaw = Y_norm(lby)
        L.lby_breaks = (L.lby_breaks or 0) + 1
      end
    end
    L.lby_prev_yaw = lby
  end
  L.lby_age = L.lby_break_tick and (tick - L.lby_break_tick) or 999
  local valid_gap = gap > 0 and gap <= 3
  local pose = tonumber(pose_delta)
  local pose_sign = pose and math.abs(pose) >= 7 and (pose >= 0 and 1 or - 1) or 0
  if pose_sign ~= 0 and L.pose_sign and L.pose_sign ~= 0 and pose_sign ~= L.pose_sign then
    L.side_switch_tick = tick
    L.side_switches = math.min(16, (L.side_switches or 0) + 1)
  end
  if pose_sign ~= 0 then
    L.pose_sign = pose_sign
  end
  L.side_switch = L.side_switch_tick and tick >= L.side_switch_tick and tick - L.side_switch_tick <= 3 or false
  L.micro_move = state ~= "air" and speed >= 0.5 and speed < 18
  if state == "move" and speed > 40 then
    L.last_move_yaw = lby or (pose and Y_norm(base + pose)) or base
    L.last_move_tick = tick
  end
  local signal = math.max(clamp(math.abs(pose or 0) / 42, 0, 1), lby and clamp(math.abs(Y_norm(lby - base)) / 48, 0, 1) or 0, clamp((L.jitter or 0) / 0.75, 0, 1))
  local freshness = valid_gap and 1 or (gap > 0 and gap <= 8 and 0.45 or 0.15)
  L.record_quality = clamp(freshness * 0.55 + signal * 0.30 + clamp((L.state_stability or 0) / 6, 0, 1) * 0.15, 0, 1)
end
function Y.lby_cadence(L, state, speed, lby, tick, base)
  if not L then
    return
  end
  local moving = speed and speed > 3
  if moving then
    L.cad_move_yaw = lby or base
    L.cad_move_tick = tick
    L.cad_phase = "moving"
    L.cad_stop_tick = nil
    L.cad_stop_yaw = nil
    L.cad_anchor = nil
    return
  end
  local move_tick = tonumber(L.cad_move_tick)
  local stop_tick = tonumber(L.cad_stop_tick)
  if move_tick and not stop_tick and tick - move_tick <= 4 then
    L.cad_stop_tick = tick
    L.cad_stop_yaw = L.cad_move_yaw or lby or base
    stop_tick = tick
  end
  if not stop_tick then
    L.cad_phase = "expired"
    L.cad_anchor = nil
    return
  end
  local age = tick - stop_tick
  if age <= 14 and L.cad_stop_yaw then
    L.cad_phase = "stop"
    L.cad_anchor = L.cad_stop_yaw
  elseif age <= 70 then
    L.cad_phase = "lby"
    L.cad_anchor = lby or L.cad_stop_yaw
  else
    L.cad_phase = "expired"
    L.cad_anchor = nil
  end
end
function Y.miss_penalty(L, state, yaw, tick)
  if not L or not number(yaw) then
    return 0
  end
  local arcs = L.miss_arcs and L.miss_arcs[state]
  if type(arcs) ~= "table" then
    return 0
  end
  local penalty = 0
  for i = # arcs, 1, - 1 do
    local a = arcs[i]
    local age = tick - (tonumber(a.tick) or tick)
    if age < 0 or age > 192 then
      table.remove(arcs, i)
    else
      local distance = math.abs(Y_norm(yaw - (tonumber(a.yaw) or yaw)))
      if distance < 44 then
        local freshness = 1 - age / 192
        penalty = penalty + (tonumber(a.weight) or 1) * (1 - distance / 44) * freshness
      end
    end
  end
  return clamp(penalty, 0, 2.5)
end
function Y.remanemone_miss(L, state, yaw, tick, weight, bucket)
  if not L or not number(yaw) then
    return
  end
  L.miss_arcs = L.miss_arcs or { }
  local arcs = L.miss_arcs[state] or { }
  L.miss_arcs[state] = arcs
  local merged = false
  for i = # arcs, 1, - 1 do
    local a = arcs[i]
    if tick - (tonumber(a.tick) or tick) > 192 then
      table.remove(arcs, i)
    elseif math.abs(Y_norm(yaw - (tonumber(a.yaw) or yaw))) <= 12 then
      a.yaw = Y_norm(a.yaw + Y_norm(yaw - a.yaw) * 0.35)
      a.tick = tick
      a.weight = clamp((tonumber(a.weight) or 0) * 0.72 + (weight or 1), 0.20, 2.25)
      a.bucket = bucket
      merged = true
      break
    end
  end
  if not merged then
    arcs[# arcs + 1] = {
      yaw = Y_norm(yaw),
      tick = tick,
      weight = clamp(weight or 1, 0.20, 1),
      bucket = bucket
    }
  end
  while # arcs > 6 do
    table.remove(arcs, 1)
  end
end
function Y.remanemone_hit(L, state, yaw, tick, bucket)
  if not L or not number(yaw) then
    return
  end
  L.good_yaw = L.good_yaw or { }
  L.good_yaw[state] = { yaw = Y_norm(yaw), tick = tick, bucket = bucket }
  local arcs = L.miss_arcs and L.miss_arcs[state]
  if type(arcs) ~= "table" then
    return
  end
  for i = # arcs, 1, - 1 do
    local a = arcs[i]
    local distance = math.abs(Y_norm(yaw - (tonumber(a.yaw) or yaw)))
    if distance <= 18 then
      a.weight = (tonumber(a.weight) or 1) * 0.28
      if a.weight < 0.18 then
        table.remove(arcs, i)
      end
    end
  end
end
function Y.feedback_score(L, state, bucket, yaw, tick)
  local state_stats = L.by_state and L.by_state[state] or nil
  local rec = state_stats and state_stats[bucket] or nil
  local global = L[bucket]
  local h = (rec and (rec.wh or rec.h) or 0) + (global and (global.wh or global.h) or 0) * 0.20
  local m = (rec and (rec.wm or rec.m) or 0) + (global and (global.wm or global.m) or 0) * 0.20
  local canonical = Y.canonical_bucket(bucket, state)
  if canonical and canonical ~= bucket then
    local canonical_rec = state_stats and state_stats[canonical] or nil
    local canonical_global = L[canonical]
    h = h + ((canonical_rec and (canonical_rec.wh or canonical_rec.h) or 0) + (canonical_global and (canonical_global.wh or canonical_global.h) or 0) * 0.20) * 0.42
    m = m + ((canonical_rec and (canonical_rec.wm or canonical_rec.m) or 0) + (canonical_global and (canonical_global.wm or canonical_global.m) or 0) * 0.20) * 0.42
  end
  local reliability = (h + 1.10) / (h + m + 2.20) - 0.50
  local score = reliability * 0.70 - Y.miss_penalty(L, state, yaw, tick) * 1.35
  local good = L.good_yaw and L.good_yaw[state] or nil
  if good and tick >= (good.tick or tick) and tick - (good.tick or tick) <= 128 then
    local distance = math.abs(Y_norm(yaw - good.yaw))
    if distance <= 24 then
      score = score + (1 - distance / 24) * 0.38
    end
  end
  return score
end
function Y.add_main_candidates(list, L, base, vel_angle, speed, lby, tick, jitter, side, state, delta)
  if state=="air" then vel_angle=nil end
  local airborne = state == "air"
  local quality = tonumber(L.record_quality) or 0
  if airborne then list.add("air_eye",base,0.24) end
  if not airborne then
    list.add("commit", base + side * delta, state == "move" and 0.10 or 0.16)
    list.add("eye", base, state == "stand" and 0.06 or - 0.04)
    list.add("eye_side", base + side * delta, 0.05)
    list.add("eye_opp", base - side * delta, L.side_switch and 0.12 or - 0.02)
  end
  if L.body_hint and not airborne then
    list.add("body", L.body_hint, (L.body_strength or 0) > 24 and 0.12 or 0.02)
  end
  if L.head_valid and L.head_yaw and not airborne and (L.head_confidence or 0) >= 0.55 then
    list.add("head_read", L.head_yaw, 0.08 + math.min(0.10, (L.head_confidence or 0) * 0.10))
  end
  if vel_angle and speed > 34 and (airborne or state == "move") then
    list.add("vel", vel_angle, airborne and 0.24 or (quality >= 0.28 and 0.13 or 0.03))
    if airborne then
      list.add("vel_side", vel_angle + side * math.min(delta, 32), 0.06)
      list.add("vel_opp", vel_angle - side * math.min(delta, 32), 0.09)
    end
  end
  if lby and not airborne then
    list.add("lby", lby, (state == "stand" or state == "slow") and 0.08 or 0)
    if L.micro_move then
      list.add("micro_lby", lby + side * math.min(delta * 0.35, 20), 0.11)
    end
  end
  if L.last_move_yaw and L.last_move_tick and tick - L.last_move_tick <= 64 and (state == "stand" or state == "slow") then
    list.add("last_move", L.last_move_yaw, 0.11)
  end
  local cad_phase = L.cad_phase
  if (state == "stand" or state == "slow") and cad_phase == "stop" and L.cad_anchor then
    list.add("cad_stop", L.cad_anchor, 0.30)
  elseif (state == "stand" or state == "slow") and cad_phase == "lby" and lby then
    list.add("cad_lby", lby, 0.18)
  end
  if state == "slow" and speed > 0.5 and lby then
    list.add("cad_slow", lby + side * math.min(28, delta * 0.55), 0.08)
  end
  if L.aim_delta and not airborne and not L.side_switch and not L.micro_move then
    if L.defensive then
      list.add("def_eye", base, 0.08)
      list.add("def_half", base + side * delta * 0.5, 0.05)
    elseif L.aim_delta >= 60 then
      list.add("side_eye", base, 0.07)
      list.add("side_half", base + side * delta * 0.5, 0.04)
    end
  end
  if L.distance_sqr and L.distance_sqr < 1000000 and (state == "stand" or state == "slow") then
    list.add("near_eye", base, 0.14)
  end
  if jitter > 0.72 and L.side_switch and not airborne then
    list.add("hvh_jit_eye", base, 0.10)
  end
  if L.side_switch and not airborne then
    list.add("side_switch", base - side * delta, 0.12)
  end
  local pred = not L.break_lc and not airborne and Y_predicted(L, tick) or nil
  if pred and jitter > 0.52 and quality >= 0.48 then
    list.add("pred", pred, - 0.02)
  end
  local good = L.good_yaw and L.good_yaw[state] or nil
  if good and tick >= good.tick and tick - good.tick <= 128 then
    list.add("good_anchor", good.yaw, 0.24)
  end
  return base, airborne
end
function Y.lby_span_track(L,base,lby,tick,state)
  if not L then return end
  tick=number(tick) or number(globals.tickcount) or 0
  local span=L.lby_span
  if not span or span.state~=state or tick<(span.tick or tick) then
    span={history={},state=state};L.lby_span=span
  end
  if span.tick==tick then return end
  span.tick=tick
  if not number(base) or not number(lby) then span.observed_span=nil;span.span=nil;return end
  local value=math.abs(Y_norm(lby-base))
  span.history[#span.history+1]=value
  if #span.history>16 then table.remove(span.history,1) end
  local ordered={};for i,v in ipairs(span.history) do ordered[i]=v end;table.sort(ordered)
  span.observed_span=ordered[math.floor((#ordered+1)/2)]
  span.samples=#ordered
  span.span=nil
end
function Y.resolve_free(L, base, vel_angle, speed, lby, tick, jitter, side, state, delta, last_angles, same_target, t, brute)
  if state=="air" then vel_angle=nil end
  local list = Y_new_list()
  local quality = tonumber(L.record_quality) or 0
  local airborne = state == "air"
  local eff_side = ((tonumber(brute) or 0) % 2 == 1) and - side or side
  local side_conf = clamp(math.abs(tonumber(L.side_score) or 0) / 2, 0, 1)
  local eff_delta = delta
  local span = L.lby_span and tonumber(L.lby_span.span) or nil
  if span and span > 14 and span < delta then
    eff_delta = span
  end
  local commit_prior = 0.30 + side_conf * 0.40
  if state == "move" then
    commit_prior = 0.10 + side_conf * 0.20
  end
  if not airborne then
    list.add("commit", Y_norm(base + eff_side * eff_delta), commit_prior)
  end
  if L.body_hint and not airborne then
    list.add("body", L.body_hint, (L.body_strength > 24 and 0.22 or 0.05) * (0.55 + quality * 0.45))
  end
  local moving = vel_angle and speed > 34 and (state == "move" or airborne)
  if moving and (airborne or quality >= 0.28) then
    list.add("vel", vel_angle, airborne and 0.30 or (state == "move" and 0.10 or - 0.05))
  end
  local pred = not L.break_lc and not airborne and Y_predicted(L, tick) or nil
  if pred and moving and quality >= 0.48 and (L.alternating or jitter > 0.48) then
    local movement_weight = clamp(speed / 260, 0.18, 0.55)
    list.add("hyb", pred + Y_norm(vel_angle - pred) * movement_weight, 0.06)
  end
  if not airborne then
    list.add("eye", base, state == "stand" and 0.10 or 0)
    list.add("eye_side", base + eff_side * eff_delta, 0.10)
    list.add("eye_opp", base - eff_side * eff_delta, - 0.02)
    list.add("eye+29", base + eff_side * 29, - 0.04)
  elseif vel_angle then
    list.add("vel_side", vel_angle + side * math.min(eff_delta, 32), 0.12)
    list.add("vel_opp", vel_angle - side * math.min(eff_delta, 32), 0.06)
  end
  if lby and not airborne then
    list.add("lby", lby, state == "stand" and 0.08 or 0)
    list.add("lby_side", lby + eff_side * math.min(eff_delta, 50), - 0.02)
    if L.micro_move then
      list.add("micro_lby", lby + side * math.min(eff_delta * 0.35, 20), 0.18)
    end
  end
  if state == "stand" or state == "slow" then
    if L.cad_phase == "stop" and L.cad_anchor then
      list.add("cad_stop", L.cad_anchor, 0.30)
    elseif L.cad_phase == "lby" and lby then
      list.add("cad_lby", lby, 0.18)
    end
  end
  if state == "slow" and speed > 0.5 and lby then
    list.add("cad_slow", lby + side * math.min(28, eff_delta * 0.55), 0.08)
  end
  if L.last_move_yaw and L.last_move_tick and tick - L.last_move_tick <= 64 and (state == "stand" or state == "slow") then
    list.add("last_move", L.last_move_yaw, 0.15)
  end
  if L.side_switch and not airborne then
    list.add("side_switch", base - eff_side * eff_delta, 0.16)
  end
  if pred and jitter > 0.58 and quality >= 0.48 then
    list.add("pred", pred, jitter > 0.78 and 0.04 or - 0.08)
  end
  local good = L.good_yaw and L.good_yaw[state] or nil
  if good and tick >= good.tick and tick - good.tick <= 128 then
    list.add("good_anchor", good.yaw, 0.24)
  end
  if not airborne and L.lby_break_yaw and L.lby_break_tick and tick - L.lby_break_tick <= 16 and (state == "stand" or state == "slow" or state == "duck") then
    list.add("lby_break", L.lby_break_yaw, 0.30)
  end
  if L.defensive and not airborne and not L.side_switch and not L.micro_move then
    list.add("def_eye", base, 0.16)
    list.add("def_half", Y_norm(base + eff_side * eff_delta * 0.5), 0.12)
  end
  if not L.defensive and L.aim_delta and L.aim_delta >= 60 and not airborne and not L.side_switch and not L.micro_move then
    list.add("side_eye", base, 0.07)
    list.add("side_half", Y_norm(base + eff_side * eff_delta * 0.5), 0.04)
  end
  if L.distance_sqr and L.distance_sqr < 1000000 and (state == "stand" or state == "slow") then
    list.add("near_eye", base, 0.14)
  end
  for i = 1, list.n do
    local c = list[i]
    c.prior = (c.prior or 0) + Y.feedback_score(L, state, c.bucket, c.yaw, tick)
  end
  local yaw, mode = Y_pick_learned(L, list, jitter > 0.66, state)
  if not number(yaw) then
    local vel_ok = airborne and number(vel_angle) and Y.plausible_yaw(L, state, vel_angle)
    local fb = vel_ok and vel_angle or ((not airborne and number(lby)) and lby or (base + eff_side * eff_delta))
    yaw = Y.gate_clamp(L, state, fb)
    mode = vel_ok and "vel_fallback" or "commit_fallback"
  end
  local state_hit = L.last_hit_by_state and L.last_hit_by_state[state] or nil
  if state_hit and t - state_hit < 1.10 and last_angles and same_target and Y.miss_penalty(L, state, last_angles, tick) < 0.20 then
    yaw = Y_norm(last_angles + Y_norm(yaw - last_angles) * 0.28)
  end
  return yaw, mode
end
function Y.resolve_beta(L, base, vel_angle, speed, lby, tick, jitter, side, state, delta)
  if state=="air" then vel_angle=nil end
  local list = Y_new_list()
  local quality = tonumber(L.record_quality) or 0
  local airborne = state == "air"
  local eff_delta = delta
  local span = L.lby_span and tonumber(L.lby_span.span) or nil
  if span and span > 14 and span < delta then
    eff_delta = span
  end
  Y.add_main_candidates(list, L, base, vel_angle, speed, lby, tick, jitter, side, state, eff_delta)
  if L.body_hint and not airborne then
    list.add("beta_body", L.body_hint, 0.18 + quality * 0.10)
  end
  if lby and not airborne then
    local degenerate = math.abs(Y_norm(lby - base)) <= 2
    list.add("beta_lby", lby, (state == "stand" or state == "slow" or state == "duck") and (degenerate and 0.05 or 0.22) or 0.02)
    list.add("beta_lby_side", lby + side * math.min(eff_delta * 0.65, 38), 0.04)
  end
  list.add("beta_side", base + side * eff_delta, airborne and 0.16 or 0.12)
  list.add("beta_opp", base - side * eff_delta, L.side_switch and 0.18 or (airborne and 0.06 or - 0.02))
  if not airborne then
    list.add("beta_eye", base, state == "stand" and 0.08 or - 0.04)
  end
  if L.micro_move and lby and not airborne then
    list.add("beta_micro", lby + side * math.min(eff_delta * 0.30, 18), 0.14)
  end
  if L.last_move_yaw and L.last_move_tick and tick - L.last_move_tick <= 64 and (state == "stand" or state == "slow") then
    list.add("beta_lastmove", L.last_move_yaw, 0.18)
  end
  local pred = not L.break_lc and not airborne and Y_predicted(L, tick) or nil
  if pred and quality >= 0.48 and jitter > 0.44 then
    list.add("beta_pred", pred, 0.08)
  end
  if vel_angle and (airborne or quality >= 0.38) and speed > 34 then
    list.add("beta_vel", vel_angle, (airborne and 0.30 or (state == "move" and 0.08 or - 0.05)) * Y.vel_alignment(L, vel_angle))
  end
  local good = L.good_yaw and L.good_yaw[state] or nil
  if good and tick >= good.tick and tick - good.tick <= 128 then
    list.add("beta_good", good.yaw, 0.26)
  end
  if not airborne and L.lby_break_yaw and L.lby_break_tick and tick - L.lby_break_tick <= 16 and (state == "stand" or state == "slow" or state == "duck") then
    list.add("beta_lbybreak", L.lby_break_yaw, 0.24)
  end
  if L.defensive and not airborne and not L.side_switch and not L.micro_move then
    list.add("beta_defeye", base, 0.12)
    list.add("beta_defhalf", Y_norm(base + side * eff_delta * 0.5), 0.02)
  end
  local angel_yaw, angel_bucket = Y.angel_phase_candidate(L, "Beta", base, vel_angle, lby, side, state, eff_delta, tick)
  if angel_yaw then
    list.add(angel_bucket, angel_yaw, 0.20)
  end
  Y.filter_wide(L, list, state)
  local state_stats = L.by_state and L.by_state[state] or nil
  local scored = { }
  for i = 1, list.n do
    local c = list[i]
    local global = L[c.bucket]
    local rec = state_stats and state_stats[c.bucket] or nil
    local h = (rec and (rec.wh or rec.h) or 0) + (global and (global.wh or global.h) or 0) * 0.25
    local m = (rec and (rec.wm or rec.m) or 0) + (global and (global.wm or global.m) or 0) * 0.25
    local n = h + m
    local reliability = (h + 1.35) / (n + 2.70)
    local w = 0.55 + reliability * 0.85 + math.min(1, n / 7) * 0.12 + (c.prior or 0) + Y_bucket_prior(c.bucket) + Y.feedback_score(L, state, c.bucket, c.yaw, tick)
    if L.break_lc and not airborne and (c.bucket == "beta_pred" or c.bucket == "beta_vel") then
      w = w * 0.55
    end
    local streak = rec and (rec.streak or 0) or global and (global.streak or 0) or 0
    if streak >= 1 then
      w = w - math.min(3, streak) * 0.25
    end
    local tban_key = state .. "|" .. c.bucket
    local tban_until = L.beta_ban and L.beta_ban[tban_key]
    if tban_until then
      if tick < tban_until then
        w = w - 2.5
      else
        L.beta_ban[tban_key] = nil
      end
    end
    scored[# scored + 1] = { yaw = c.yaw, bucket = c.bucket, weight = math.max(0.02, w) }
  end
  if # scored == 0 then
    L.beta_confidence = 0
    return Y.gate_clamp(L, state, base + side * eff_delta), "beta_fallback"
  end
  local best, second = nil, nil
  for i = 1, # scored do
    local c, support = scored[i], 0
    for j = 1, # scored do
      local distance = math.abs(Y_norm(scored[j].yaw - c.yaw))
      if distance <= 22 then
        support = support + scored[j].weight * (1 - distance / 44)
      end
    end
    c.score = support
    if not best or c.score > best.score then
      second, best = best, c
    elseif not second or c.score > second.score then
      second = c
    end
  end
  local margin = second and clamp((best.score - second.score) / math.max(0.20, best.score), 0, 1) or 1
  L.beta_confidence = clamp(quality * 0.35 + margin * 0.35 + math.min(1, best.score / 3.2) * 0.30, 0, 1)
  return Y_norm(best.yaw), best.bucket
end
function Y.adaptive_signal(L, ent, base, pose_delta, lby, speed, tick, state)
  local roll_pose = nil
  pcall(function ()
    local v = entity.get_prop(ent, "m_flPoseParameter", 12)
    if number(v) then
      roll_pose = tonumber(v)
    end
  end)
  if roll_pose then
    if roll_pose >= 0 and roll_pose <= 1.2 then
      roll_pose = clamp((roll_pose - 0.5) * 120, - 60, 60)
    elseif roll_pose >= - 1.2 and roll_pose <= 1.2 then
      roll_pose = clamp(roll_pose * 60, - 60, 60)
    else
      roll_pose = clamp(roll_pose, - 60, 60)
    end
  end
  L.adaptive_roll_pose = roll_pose
  if L.adaptive_signal_tick ~= tick then
    local prev_speed, prev_pose = tonumber(L.adaptive_prev_speed) or speed, tonumber(L.adaptive_prev_pose) or pose_delta or 0
    local speed_change = math.abs(speed - prev_speed)
    local pose_change = math.abs((pose_delta or 0) - prev_pose)
    local gap = L.adaptive_signal_tick and tick - L.adaptive_signal_tick or 1
    L.adaptive_anim_proxy = clamp(speed_change / 90 * 0.35 + pose_change / 45 * 0.40 + (gap > 2 and 0.25 or 0), 0, 1)
    L.adaptive_prev_speed, L.adaptive_prev_pose, L.adaptive_signal_tick = speed, pose_delta or 0, tick
    local h = L.adaptive_history or { }
    L.adaptive_history = h
    h[# h + 1] = { tick = tick, eye = base, pose = pose_delta, lby = lby, speed = speed }
    if # h > 10 then
      table.remove(h, 1)
    end
    if # h >= 3 then
      local start = math.max(2, # h - 4)
      local trend, n = 0, 0
      for i = start, # h do
        trend, n = trend + Y_norm(h[i].eye - h[i - 1].eye), n + 1
      end
      L.adaptive_trend_yaw = Y_norm(base + clamp(trend / math.max(1, n), - 42, 42))
    end
  end
  L.adaptive_features = {
    1,
    clamp(math.abs(pose_delta or 0) / 58, 0, 1),
    clamp((L.jitter or 0), 0, 1),
    clamp(speed / 260, 0, 1),
    (state == "stand" or state == "slow" or state == "duck") and 1 or 0,
    L.break_lc and 1 or 0,
    L.side_switch and 1 or 0,
    L.micro_move and 1 or 0,
    clamp(math.abs(roll_pose or 0) / 60, 0, 1),
    clamp(tonumber(L.adaptive_anim_proxy) or 0, 0, 1),
    clamp(math.abs(tonumber(L.aim_delta) or 0) / 180, 0, 1),
    L.defensive and 1 or 0,
    clamp((tonumber(L.lby_age) or 999) / 96, 0, 1),
    (L.lby_break_tick and (tick - L.lby_break_tick) <= 16) and 1 or 0,
  }
end
function Y.adaptive_feedback(L, bucket, features, hit, weight)
  if type(features) ~= "table" or type(bucket) ~= "string" or bucket:sub(1, 5) ~= "adaptive_" then
    return
  end
  if bucket:sub(1, 11) == "adaptive_probe_" then
    bucket = "adaptive_" .. bucket:sub(12)
  end
  L.adaptive_model = L.adaptive_model or { }
  local model = L.adaptive_model[bucket] or {
    w = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    n = 0
  }
  L.adaptive_model[bucket] = model
  local lr = (hit and 0.055 or 0.13) / math.sqrt(1 + (model.n or 0) * 0.12)
  local target = hit and 1 or - clamp((weight or 1) * 1.6, 0.30, 1.25)
  for i = 1, 14 do
    model.w[i] = clamp((model.w[i] or 0) * 0.997 + lr * target * (features[i] or 0), - 1.25, 1.25)
  end
  model.n = (model.n or 0) + 1
end
function Y.resolve_adaptive_rich(L, base, vel_angle, speed, lby, tick, jitter, side, state, delta)
  if state=="air" then vel_angle=nil end
  local list = Y_new_list()
  local static = state == "stand" or state == "slow" or state == "duck"
  local airborne = state == "air"
  local quality = tonumber(L.record_quality) or 0
  local eff_delta = delta
  local span = L.lby_span and tonumber(L.lby_span.span) or nil
  if span and span > 14 and span < delta then
    eff_delta = span
  end
  Y.add_main_candidates(list, L, base, vel_angle, speed, lby, tick, jitter, side, state, eff_delta)
  if static and L.evalate_yaw and (tonumber(L.evalate_confidence) or 0) >= 0.52 then
    list.add("adaptive_evalate", L.evalate_yaw, 0.30)
  end
  local feedback_yaw = FEEDBACK_CFG.static_aa_correction and (L.static_confidence or 0) >= FEEDBACK_CFG.min_static_confidence and feedback_corrected_yaw(L, base, tick, 1) or nil
  if feedback_yaw then
    list.add("adaptive_feedback", feedback_yaw, 0.24)
  end
  if L.adaptive_trend_yaw and not L.break_lc and not airborne then
    list.add("adaptive_history", L.adaptive_trend_yaw, 0.12)
  end
  if L.adaptive_roll_pose and math.abs(L.adaptive_roll_pose) >= 12 and not airborne then
    list.add("adaptive_roll", base + (L.adaptive_roll_pose >= 0 and 1 or - 1) * math.min(eff_delta, math.abs(L.adaptive_roll_pose)), 0.06)
  end
  local proxy = tonumber(L.adaptive_anim_proxy) or 0
  list.add("adaptive_animproxy", base + side * eff_delta * (0.45 + proxy * 0.45), proxy > 0.55 and 0.14 or - 0.02)
  list.add("adaptive_side", base + side * eff_delta, airborne and 0.16 or 0.08)
  list.add("adaptive_opp", base - side * eff_delta, L.side_switch and 0.18 or (airborne and 0.06 or 0.02))
  if not airborne then
    list.add("adaptive_eye", base, state == "stand" and 0.04 or - 0.04)
  end
  if L.body_hint and not airborne then
    list.add("adaptive_body", L.body_hint, (L.body_strength > 18 and 0.16) or 0.04)
  end
  if L.head_valid and L.head_yaw and not airborne and (L.head_confidence or 0) >= 0.58 then
    list.add("adaptive_head", L.head_yaw, 0.12 + math.min(0.08, (L.head_confidence or 0) * 0.08))
  end
  if static and lby then
    local degenerate = math.abs(Y_norm(lby - base)) <= 2
    list.add("adaptive_lby", lby, degenerate and 0.03 or 0.18)
  end
  local pred = not L.break_lc and not airborne and Y_predicted(L, tick) or nil
  if pred and jitter > 0.48 and quality >= 0.48 then
    list.add("adaptive_pred", pred, 0.12)
  end
  if vel_angle and speed > 34 and (state == "move" or airborne or quality >= 0.35) then
    list.add("adaptive_vel", vel_angle, (airborne and 0.26 or (state == "move" and 0.10 or 0.06)) * Y.vel_alignment(L, vel_angle))
  end
  local good = L.good_yaw and L.good_yaw[state] or nil
  if good and tick >= good.tick and tick - good.tick <= 128 then
    list.add("adaptive_good", good.yaw, 0.30)
  end
  if static and L.lby_break_yaw and L.lby_break_tick and tick - L.lby_break_tick <= 16 then
    list.add("adaptive_lbybreak", L.lby_break_yaw, 0.28)
  end
  if L.defensive and not airborne and not L.side_switch and not L.micro_move then
    list.add("adaptive_defeye", base, 0.16)
  end
  local angel_yaw, angel_bucket = Y.angel_phase_candidate(L, "Adaptive", base, vel_angle, lby, side, state, eff_delta, tick)
  if angel_yaw then
    list.add(angel_bucket, angel_yaw, 0.40)
  end
  Y.filter_wide(L, list, state)
  local features = L.adaptive_features or { 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }
  local state_stats = L.by_state and L.by_state[state] or nil
  L.adaptive_model = L.adaptive_model or { }
  local best, second = nil, nil
  for i = 1, list.n do
    local c = list[i]
    local canonical = Y.canonical_bucket(c.bucket, state)
    local rec = state_stats and state_stats[c.bucket] or nil
    local global = L[c.bucket]
    local h = (rec and (rec.wh or rec.h) or 0) + (global and (global.wh or global.h) or 0) * 0.25
    local m = (rec and (rec.wm or rec.m) or 0) + (global and (global.wm or global.m) or 0) * 0.25
    local reliability = (h + 1.2) / (h + m + 2.4) - 0.50
    local model = L.adaptive_model[c.bucket]
    local learned = 0
    if model and model.w then
      for j = 1, 14 do
        learned = learned + (model.w[j] or 0) * (features[j] or 0)
      end
    end
    local score = (c.prior or 0) + reliability * 0.60 + Y_bucket_prior(canonical or c.bucket) + clamp(learned, - 0.55, 0.55) + quality * 0.08 + Y.feedback_score(L, state, c.bucket, c.yaw, tick)
    if L.break_lc and not airborne and (c.bucket == "adaptive_pred" or c.bucket == "adaptive_vel") then
      score = score * 0.85
    end
    local ban_key = state .. "|" .. c.bucket
    local ban_until = L.adaptive_ban and L.adaptive_ban[ban_key]
    if ban_until then
      if tick < ban_until then
        score = score - 2.5
      else
        L.adaptive_ban[ban_key] = nil
      end
    end
    local streak = rec and (rec.streak or 0) or global and (global.streak or 0) or 0
    if streak >= 1 then
      score = score - math.min(3, streak) * 0.30
    end
    c.score = score
    if not best or score > best.score then
      second, best = best, c
    elseif not second or score > second.score then
      second = c
    end
  end
  if not best then
    L.adaptive_confidence = 0
    return Y.gate_clamp(L, state, base + side * eff_delta), "adaptive_fallback"
  end
  local margin = second and best.score - second.score or 0.45
  L.adaptive_confidence = clamp(quality * 0.35 + clamp(margin / 0.45, 0, 1) * 0.45 + math.min(1, ((L.adaptive_model[best.bucket] or { }).n or 0) / 8) * 0.20, 0, 1)
  return Y_norm(best.yaw), best.bucket
end
function Y.resolve_adaptive(L, base, vel_angle, speed, lby, tick, jitter, side, state, delta)
  local beta_yaw, beta_mode = Y.resolve_beta(L, base, vel_angle, speed, lby, tick, jitter, side, state, delta)
  local rich_yaw, rich_mode = Y.resolve_adaptive_rich(L, base, vel_angle, speed, lby, tick, jitter, side, state, delta)
  local bc = tonumber(L.beta_confidence) or 0
  local ac = tonumber(L.adaptive_confidence) or 0
  local beta_bias=Y.ffi_feedback and Y.ffi_feedback:bias(L,state,beta_mode,beta_yaw,base)or 0
  local rich_bias=Y.ffi_feedback and Y.ffi_feedback:bias(L,state,rich_mode,rich_yaw,base)or 0
  local choose_rich=number(rich_yaw)and (ac+rich_bias>=0.58 or ac+rich_bias>=bc+beta_bias+0.10)
  L.native_candidates={
    {yaw=Y.gate_clamp(L,state,beta_yaw),confidence=bc,source="adaptive_beta",mode="adaptive_beta_"..tostring(beta_mode),tick=tick,uid=L.__uid},
    {yaw=Y.gate_clamp(L,state,rich_yaw),confidence=ac,source="adaptive_rich",mode="adaptive_"..tostring(rich_mode),tick=tick,uid=L.__uid}
  }
  if type(rich_mode) == "string" then
    local low = rich_mode:lower()
    if low:find("lby_exact", 1, true) and math.abs(Y_norm((lby or base) - base)) <= 2 then
      choose_rich = false
    end
    if low:find("fallback", 1, true) and ac < 0.72 then
      choose_rich = false
    end
  end
  local yaw = choose_rich and rich_yaw or beta_yaw
  local mode = choose_rich and "adaptive_" .. tostring(rich_mode or "rich") or "adaptive_beta_" .. tostring(beta_mode or "consensus")
  local max_corr = state == "air" and 58 or 60
  local correction = math.abs(Y_norm(yaw - base))
  if correction > max_corr then
    yaw = base + (Y_norm(yaw - base) >= 0 and max_corr or -max_corr)
    mode = mode .. "_capped"
  end
  if not number(yaw) then
    yaw, mode = beta_yaw, "adaptive_beta_fallback"
    choose_rich = false
  end
  L.adaptive_confidence = clamp((ac * 0.65) + (bc * 0.35), 0, 1)
  local final_yaw=Y.gate_clamp(L, state, yaw)
  L.native_candidate={yaw=final_yaw,confidence=clamp(choose_rich and ac or bc,0,1),source=choose_rich and "adaptive_rich" or "adaptive_beta",beta=bc,rich=ac,blended=L.adaptive_confidence,mode=mode,tick=tick,uid=L.__uid}
  return final_yaw, mode
end
function Y.native_selection(L,yaw)
  local tick=number(globals.tickcount)
  local selected=L.native_candidate
  local detail={source="no_current_candidate"}
  if not selected or not number(selected.yaw)or not number(yaw)or not tick or selected.tick~=tick or selected.uid~=L.__uid then return 0,detail end
  detail={source=selected.source,beta=selected.beta,rich=selected.rich,blended=selected.blended,candidate_yaw=selected.yaw,mode=selected.mode}
  if math.abs(Y_norm(yaw-selected.yaw))<=0.10 then return clamp(number(selected.confidence)or 0,0,1),detail end
  local best,best_score,best_distance=nil,0,nil
  for _,c in ipairs(L.native_candidates or {})do
    if c.tick==tick and c.uid==L.__uid and number(c.yaw)and number(c.confidence)then
      local distance=math.abs(Y_norm(yaw-c.yaw))
      if distance<=18 then
        local score=clamp(c.confidence,0,1)*(1-distance/18)
        if score>best_score then best,best_score,best_distance=c,score,distance end
      end
    end
  end
  if not best then detail.source="post_selection_yaw_unsupported";return 0,detail end
  detail.source="current_support/"..best.source;detail.support_distance=best_distance;detail.mode=best.mode;detail.candidate_yaw=yaw
  L.native_candidate={yaw=Y_norm(yaw),confidence=best_score,source=detail.source,mode=best.mode,beta=selected.beta,rich=selected.rich,blended=selected.blended,tick=tick,uid=L.__uid}
  return best_score,detail
end
Y.ffi_feedback=(function()
local function create_ffi_feedback(env)
  local M={pending={},used={},used_order={},stats={fires=0,eligible=0,learned=0,hits=0,misses=0,rejected=0,duplicates=0,retired_head_hits=0},reasons={}}
  local function finite(x)return type(x)=="number"and x==x and math.abs(x)<math.huge end
  local function integer(x)return finite(x)and x%1==0 end
  local function norm(x)return (x+180)%360-180 end
  local function key(state,bucket,offset)
    if type(state)~="string"or type(bucket)~="string"or not finite(offset)then return nil end
    bucket=bucket:gsub("_hold$","")
    for i=1,3 do bucket=bucket:gsub("^adaptive_beta_",""):gsub("^adaptive_",""):gsub("^beta_","")end
    return state.."|"..bucket.."|"..math.floor((norm(offset)+180)/15)
  end
  function M:block(reason)
    self.stats.rejected=self.stats.rejected+1;self.reasons[reason]=(self.reasons[reason]or 0)+1;return false,reason
  end
  function M:reset()
    self.pending={};self.used={};self.used_order={}
    local rows=env.learn();for _,L in pairs(rows or {})do L.ffi_outcomes=nil;L.ffi_outcome_count=nil end
  end
  function M:fire(event)
    if not env.active()then return false end
    local now,tick=env.now(),env.tick();local shot_id=tonumber(event and event.id)
    if not finite(now)or not integer(tick)or not integer(shot_id)or shot_id<0 then return self:block("invalid fire clock/id")end
    for id,p in pairs(self.pending)do if now<p.time or now-p.time>4 then self.pending[id]=nil end end
    if self.pending[shot_id]then self.stats.duplicates=self.stats.duplicates+1;return false,"duplicate fire"end
    self.stats.fires=self.stats.fires+1
    local identity=env.identity(event.target);local info=identity and env.evidence(shot_id,identity.id,identity.uid)
    local f=info and info.feedback
    if not f then return self:block(info and info.feedback_reason or "no native shot evidence")end
    if not identity or f.id~=identity.id or f.uid~=identity.uid or f.fire_tick~=tick or f.epoch~=env.epoch()then return self:block("identity/fire epoch mismatch")end
    local L=env.learn()[f.id];local observer=env.observer(f.id)
    if not L or L.__uid~=f.uid or not observer or observer.uid~=f.uid or observer.generation~=f.observer_generation then return self:block("observer identity/generation mismatch")end
    if not integer(f.seq)or f.seq<1 or not integer(f.token)or f.token<1 or not integer(f.snapshot)or f.snapshot<1 or not finite(f.yaw)or not finite(f.base)then return self:block("invalid native/candidate receipt")end
    local k=key(f.state,f.bucket,f.yaw-f.base)
    if not k then return self:block("missing candidate metadata")end
    if self.used[f.seq]then return self:block("native call already linked to a fire")end
    local count=0;for _ in pairs(self.pending)do count=count+1 end
    if count>=128 then return self:block("pending limit")end
    local p={id=f.id,uid=f.uid,shot_id=shot_id,time=now,tick=tick,epoch=f.epoch,generation=f.observer_generation,key=k,seq=f.seq,token=f.token,snapshot=f.snapshot,bucket=f.bucket,state=f.state,yaw=f.yaw,base=f.base,bank_group=f.bank_group}
    self.pending[shot_id]=p;self.used[f.seq]=true;self.used_order[#self.used_order+1]=f.seq
    if #self.used_order>256 then self.used[table.remove(self.used_order,1)]=nil end
    self.stats.eligible=self.stats.eligible+1;return true,"weak unique own-record/backtrack correlation; selected record NOT proven"
  end
  function M:death(uid)
    for _,p in pairs(self.pending)do if p.uid==uid then p.dead=true end end
  end
  function M:cancel_uid(uid)
    for id,p in pairs(self.pending)do if p.uid==uid then self.pending[id]=nil end end
  end
  function M:ack(event)
    local id=tonumber(event and event.id);local p=id and self.pending[id]
    if not p then return false end
    self.pending[id]=nil
    if not env.active()then return self:block("inactive at ACK")end
    local now,tick=env.now(),env.tick();local identity=env.identity(event.target)
    if not finite(now)or not integer(tick)or now<p.time or now-p.time>4 or tick<p.tick or tick-p.tick>256 or p.epoch~=env.epoch()or not identity or identity.id~=p.id or identity.uid~=p.uid then return self:block("ACK identity/age/epoch mismatch")end
    local L=env.learn()[p.id];local o=env.observer(p.id)
    if p.dead and not L then
      local reason=event.state;if reason==nil then reason=event.reason end
      local hg=tostring(event.hitgroup or ""):lower()
      if reason==nil and (hg=="1"or hg=="head")then
        self.stats.retired_head_hits=self.stats.retired_head_hits+1
        return true,"post-death head ACK counted; no live or respawn model updated"
      end
      return self:block("dead target no longer has a live outcome owner")
    end
    if not L or L.__uid~=p.uid or not o or o.uid~=p.uid or o.generation~=p.generation then return self:block("ACK observer changed")end
    local reason=event.state;if reason==nil then reason=event.reason end
    local hit=reason==nil
    if hit then
      local hg=tostring(event.hitgroup or ""):lower()
      if hg~="1"and hg~="head"then return self:block("non-head hit not an angle reward")end
    else
      local r=tostring(reason):lower():gsub("^%s+",""):gsub("%s+$","")
      if r~="correction"and r~="resolver"then return self:block("spread/occlusion/unknown miss excluded")end
      local spread=tonumber(event.spread)
      if not finite(spread)or spread<0 or spread>env.max_spread()then return self:block("missing/high spread excluded")end
    end
    L.ffi_outcomes=L.ffi_outcomes or {};local row=L.ffi_outcomes[p.key]
    if not row then
      if (L.ffi_outcome_count or 0)>=64 then return self:block("outcome row limit")end
      row={h=0,m=0,time=now};L.ffi_outcomes[p.key]=row;L.ffi_outcome_count=(L.ffi_outcome_count or 0)+1
    end
    if now<row.time then return self:block("feedback clock rollback")end
    local decay=math.exp(-(now-row.time)/30);row.h,row.m=row.h*decay,row.m*decay;row.time=now
    if hit then row.h=math.min(8,row.h+0.1);self.stats.hits=self.stats.hits+1 else row.m=math.min(8,row.m+0.1);self.stats.misses=self.stats.misses+1 end
    self.stats.learned=self.stats.learned+1
    return true,"bounded observational update, NOT causal selected-record proof"
  end
  function M:bias(L,state,bucket,yaw,base)
    if not env.active()or not L or not finite(yaw)or not finite(base)then return 0 end
    local k=key(state,bucket,yaw-base);local row=k and L.ffi_outcomes and L.ffi_outcomes[k];local now=env.now()
    if not row or not finite(now)or now<row.time or now-row.time>120 then return 0 end
    local decay=math.exp(-(now-row.time)/30);local h,m=row.h*decay,row.m*decay
    -- Deliberately weak: native consumer identity is known; final selected shot record is not.
    return math.max(-0.04,math.min(0.04,((h+1)/(h+m+2)-0.5)*0.08))
  end
  function M:report_lines()
    local q=self.stats;local n=0;for _ in pairs(self.pending)do n=n+1 end
    local lines={string.format("FFI observational feedback fires=%d eligible=%d updates=%d head_hits=%d correction_misses=%d rejected=%d duplicates=%d retired_head_hits=%d pending=%d/128",q.fires,q.eligible,q.learned,q.hits,q.misses,q.rejected,q.duplicates,q.retired_head_hits,n),
      "FFI feedback scope=unique primary-or-alternate own-bank token/tuple + machine-clock window + SDK backtrack agreement + UID/observer/epoch + one native call per fire; weak weight=0.1, bias capped +/-0.04; native selected record and server hitboxes NOT proven; generic Adaptive learning untouched"}
    local keys={};for k in pairs(self.reasons)do keys[#keys+1]=k end;table.sort(keys)
    for _,k in ipairs(keys)do lines[#lines+1]="FFI feedback rejection="..k.." events="..self.reasons[k]end
    return lines
  end
  return M
end

return create_ffi_feedback({
 active=function()return globals and globals.is_in_game==true and N and N:master_enabled()and yaw_mode()=="FFI"and Y.native_requested()end,
 now=clock,tick=function()return number(globals.tickcount)end,
 epoch=function()return Y.feedback_epoch or 0 end,
 learn=function()return Y.learn end,observer=function(id)return Y.timing_states and Y.timing_states[id]end,
 identity=function(ent)
   local ok,id,uid=pcall(function()local info=ent:get_player_info();return ent:get_index(),info and number(tonumber(info.userid))end)
   if ok and number(id)and number(uid)then return {id=id,uid=uid}end
 end,
 evidence=function(shot,id,uid)return Y.native_trace and Y.native_trace:shot_context_evidence(shot,id,uid)end,
 max_spread=function()return FEEDBACK_CFG.max_learning_spread end
})
end)()

local function Y_apply(ent,yaw)
  if not number(yaw) then return false end
  local ok,ang=pcall(function () return ent.m_angEyeAngles end)
  if not ok or not ang or not number(ang.y) then
    ok,ang=pcall(function () return ent:get_eye_angles() end)
  end
  if not ok or not ang or not number(ang.y) then return false end
  local prior=ang.y
  local function readback()
    local got,value=pcall(function () return ent.m_angEyeAngles.y end)
    if got and number(value) then return math.abs(Y_norm(value-yaw))<0.5 end
    local legacy,v=pcall(function () return ent:get_eye_angles().y end)
    return legacy and number(v) and math.abs(Y_norm(v-yaw))<0.5 or false
  end
  if math.abs(Y_norm(prior-yaw))<0.5 then return true,false end
  local set=pcall(function () ent.m_angEyeAngles=vector(number(ang.x) or 0,Y_norm(yaw),number(ang.z) or 0) end)
  if set and readback() then return true,true end
  local legacy=pcall(function () ent:set_eye_angles(vector(number(ang.x) or 0,Y_norm(yaw),number(ang.z) or 0)) end)
  return legacy and readback() or false,true
end
function Y.stabilize(L, yaw, mode, tick)
  if not L or not number(yaw) then
    return yaw, mode
  end
  local confidence = (yaw_mode() == "Adaptive" or yaw_mode()=="FFI") and (tonumber(L.adaptive_confidence) or 0) or (tonumber(L.beta_confidence) or 0)
  local previous_yaw, previous_mode, previous_tick = tonumber(L.__stable_yaw), L.__stable_mode, tonumber(L.__stable_tick)
  if previous_yaw and previous_mode and previous_tick and tick >= previous_tick and tick - previous_tick <= 4 and previous_mode ~= mode then
    local change = math.abs(Y_norm(yaw - previous_yaw))
    if change <= 18 and confidence < 0.62 then
      return previous_yaw, previous_mode .. "_hold"
    end
  end
  L.__stable_yaw, L.__stable_mode, L.__stable_tick = Y_norm(yaw), mode, tick
  L.__stable_confidence = confidence
  return yaw, mode
end
Y.timing_core = (function ()
local Timing = {}
local function finite(x)
    return type(x) == 'number' and x == x and x ~= math.huge and x ~= -math.huge
end
local function norm(x) return (x + 180) % 360 - 180 end
local function median(a)
    local b = {}; for i = 1, #a do b[i] = a[i] end
    table.sort(b); local n = #b
    if n == 0 then return 0 end
    if n % 2 == 1 then return b[(n+1)/2] end
    return (b[n/2] + b[n/2+1])/2
end
function Timing.new()
    return { status='warmup', confidence=0, samples=0, burst_votes=0,
             pulse_events={}, cadence_conf=0, generation=1 }
end
function Timing.update(s, o)
    if not finite(o.tick) or not finite(o.sim) then return s, 'invalid' end
    if s.tick and (o.tick < s.tick or o.tick - s.tick > 128
        or (s.uid and o.uid and s.uid ~= o.uid)
        or (s.state and o.state and s.state ~= o.state)) then
        local generation=(s.generation or 1)+1
        s=Timing.new(); s.generation=generation
    end
    if s.tick == o.tick then return s, 'duplicate' end
    if not s.tick then
        s.tick=o.tick; s.sim=o.sim; s.uid=o.uid; s.state=o.state
        s.yaw=o.yaw; s.baseline=o.yaw; s.quiet=0; s.shot=o.shot; s.sim_frontier=o.sim
        return s, 'warmup'
    end
    local arrival=o.tick-s.tick; local advance=o.sim-s.sim
    local event='normal'
    s.advance=advance; s.arrival=arrival
    local previous_sim=s.sim
    s.tick=o.tick; s.uid=o.uid; s.state=o.state
    if finite(o.shot) and o.shot>0 then
      if finite(s.shot) and o.shot>s.shot then s.shot_until=o.tick+2 end
      s.shot=o.shot
    end
    if advance == 0 then
        s.stall=(s.stall or 0)+arrival
        if s.stall>8 then s.status='stale'; s.confidence=0 end
        return s, 'stalled'
    end
    local gap=(s.stall or 0)+arrival; s.stall=0
    s.sim=o.sim; s.samples=s.samples+1
    s.sim_frontier=math.max(s.sim_frontier or previous_sim,o.sim)
    if advance < -1 and advance >= -22 then
        s.status='rollback_evidence'; s.confidence=0.80
        s.risk_until=o.tick+3; s.burst_until=nil
        event='rollback'
    elseif advance < -22 or advance > 64 then
        local generation=s.generation+1; s=Timing.new(); s.generation=generation
        s.tick=o.tick; s.sim=o.sim; s.uid=o.uid; s.state=o.state
        s.yaw=o.yaw; s.baseline=o.yaw; s.sim_frontier=o.sim
        return s,'reset'
    else
        local excess=advance-gap
        s.excess=excess; s.advance=advance; s.arrival=gap
        if s.samples >= 3 and gap<=3 and excess>=3 and excess<=22 then
            s.burst_votes=math.min(3,(s.burst_votes or 0)+1)
            s.status='burst_evidence'; s.confidence=0.45+0.15*s.burst_votes
            s.burst_until=o.tick+2; s.risk_until=nil
            event='burst'
        elseif gap>=4 and math.abs(excess)<=2 then
            s.status='choke_release'; s.confidence=0.20
            s.burst_until=nil
            event='choke_release'
        elseif not s.risk_until or o.tick>=s.risk_until then
            s.status='normal'; s.confidence=0
            s.burst_votes=math.max(0,(s.burst_votes or 0)-0.10)
        end
    end
    if finite(o.yaw) then
        local yaw=norm(o.yaw)
        local pending=s.pending
        if pending then
            local age=o.sim-pending.sim
            if age>0 and age<=4 and math.abs(norm(yaw-pending.base))<=15
                and pending.delta*norm(yaw-pending.snap)<0 then
                local events=s.pulse_events
                events[#events+1]=pending.sim
                if #events>7 then table.remove(events,1) end
                s.baseline=norm(pending.base+norm(yaw-pending.base)*0.35)
                s.pulse_until=o.tick+1
                local intervals={}
                for i=2,#events do
                    local d=events[i]-events[i-1]
                    if d>=2 and d<=40 then intervals[#intervals+1]=d end
                end
                local period=median(intervals); local good=0
                for i=1,#intervals do if math.abs(intervals[i]-period)<=1 then good=good+1 end end
                s.period=period; s.cadence_conf=#intervals>=3 and good/#intervals or 0
                s.last_pulse=pending.sim
                s.pending=nil; event='pulse_recovery'
            elseif age<0 or age>4 or math.abs(norm(yaw-pending.base))>35 then
                s.pending=nil
            end
        end
        if not s.pending and finite(s.yaw) and advance>0 and advance<=3 then
            local jump=norm(yaw-s.yaw)
            if math.abs(jump)>=28 and (s.quiet or 0)>=2 then
                s.pending={sim=o.sim,base=s.yaw,snap=yaw,delta=jump}
                s.pulse_until=o.tick+2
                event='pulse_snap'
            end
            if math.abs(jump)<=9 then
                s.quiet=math.min(8,(s.quiet or 0)+1)
                if not s.pending then s.baseline=yaw end
            else s.quiet=0 end
        end
        s.yaw=yaw
    end
    return s,event
end
function Timing.decision(s,tick)
    if not s or not finite(tick) or not s.tick or tick<s.tick or tick-s.tick>8 or (s.stall or 0)>8 then
        return {status='stale',confidence=0,force_send=false}
    end
    local defensive=s.risk_until and tick<s.risk_until or false
    local burst=s.burst_until and tick<s.burst_until or false
    local pulse=s.pulse_until and tick<s.pulse_until or false
    local forecast=false
    if s.cadence_conf>=0.80 and s.period and s.period>=2 and s.last_pulse then
        local phase=(s.sim+(tick-s.tick)-s.last_pulse)
        forecast=phase>=s.period-1 and phase<=s.period+1
    end
    return {status=s.status,confidence=s.confidence or 0,
        defensive=defensive,burst=burst,pulse=pulse,forecast=forecast,
        baseline=(pulse or forecast) and s.baseline or nil,
        force_send=defensive or (burst and (s.confidence or 0)>=0.70) or pulse,
        delay=defensive,period=s.period,cadence_conf=s.cadence_conf,
        evidence=(burst and s.shot_until and tick<s.shot_until) and 'burst_with_observed_shot' or (defensive and 'simulation_rollback' or (burst and 'excess_simulation_advance' or 'none'))}
end
return Timing
end)()
Y.record_tools = (function ()
local Tools={}
local function finite(x) return type(x)=='number' and x==x and x~=math.huge and x~=-math.huge end
local function norm(x) return (x+180)%360-180 end
function Tools.pattern(history)
  local n=#history
  if n<6 then return {jitter=false,confidence=0} end
  local steps,flips,prev=0,0,nil
  for i=2,n do
    local d=norm(history[i]-history[i-1])
    if math.abs(d)>=18 then
      steps=steps+1; local side=d>0 and 1 or -1
      if prev and side~=prev then flips=flips+1 end;prev=side
    end
  end
  local jitter=steps>=3 and flips>=2 and steps/(n-1)>=0.40
  local medoid,cost=nil,math.huge
  for _,v in ipairs(history) do
    local c=0;for _,u in ipairs(history) do c=c+math.abs(norm(v-u)) end
    if c<cost then medoid,cost=v,c end
  end
  return {jitter=jitter,confidence=jitter and math.min(1,steps/(n-1)) or 0,medoid=medoid,steps=steps,flips=flips}
end
function Tools.lerp(interp,ratio,rate,minratio,maxratio,minrate,maxrate)
  if not finite(interp) or interp<0 or not finite(ratio) or ratio<0 or not finite(rate) or rate<=0 then return nil end
  if finite(minratio) and finite(maxratio) and minratio>=0 and maxratio>0 and minratio>maxratio then return nil end
  if finite(minrate) and finite(maxrate) and minrate>0 and maxrate>0 and minrate>maxrate then return nil end
  if ratio==0 then ratio=1 end
  if finite(minratio) and minratio>=0 then ratio=math.max(ratio,minratio) end
  if finite(maxratio) and maxratio>0 then ratio=math.min(ratio,maxratio) end
  if finite(minrate) and minrate>0 then rate=math.max(rate,minrate) end
  if finite(maxrate) and maxrate>0 then rate=math.min(rate,maxrate) end
  return math.max(interp,ratio/rate)
end
function Tools.lethal(hp,min_damage,damages)
  if not finite(hp) or hp<=0 or not finite(min_damage) or min_damage<0 then return false end
  local floor=min_damage>100 and hp+min_damage-100 or min_damage
  local needed=math.max(hp,floor)
  local good=0;for _,d in ipairs(damages) do if finite(d) and d>=needed then good=good+1 end end
  return good>=2
end
function Tools.local_tickbase(s,tick,tb,uid)
  if not finite(tick) or not finite(tb) then return nil end
  if not s or s.uid~=uid or tick<(s.tick or tick) or tick-(s.tick or tick)>128 then return {tick=tick,tb=tb,frontier=tb,uid=uid,delta=0,status='warmup'} end
  if tick==s.tick then return s end
  s.delta=tb-s.tb;s.tb=tb;s.tick=tick;s.frontier=math.max(s.frontier or tb,tb)
  s.status=tb<s.frontier-1 and 'local rollback' or (s.delta>=14 and 'local burst' or 'normal')
  return s
end
return Tools
end)()
Y.timing_states = {}
Y.timing_reads = 0
function Y:observe_timing()
  local active = get_bool(cfg.predict_exploit_uncharge) or (get_bool(cfg.resolver) and get_bool(cfg.yaw))
  if not active then self.timing_states = {}; return end
  local tick = number(globals.tickcount) or 0
  local iv = number(globals.tickinterval) or (1/64)
  if iv <= 0 then return end
  local ok, players = pcall(function () return entity.get_players(true) end)
  if not ok or type(players) ~= "table" then return end
  local present = {}
  for _, ent in pairs(players) do
    local sok, data = pcall(function ()
      if not ent:is_alive() or ent:is_dormant() then return nil end
      local index = ent:get_index()
      local info = ent:get_player_info()
      local sim = ent:get_simulation_time()
      local value = type(sim) == "table" and number(sim.current) or number(sim)
      if not value then value = number(ent.m_flSimulationTime) end
      local base = Y_angle(ent)
      local shot
      pcall(function () local w=ent:get_player_weapon();if w then shot=number(w.m_fLastShotTime) end end)
      local _, speed = Y_velocity(ent)
      local state = Y_state(ent, speed, Y_duck_amount(ent), Y_pose_delta(ent))
      if not index or not value then return nil end
      return {index=index, tick=tick, sim=math.floor(value/iv+0.5), yaw=base,
              uid=info and info.userid, state=state, shot=shot}
    end)
    if sok and data then
      present[data.index] = true
      local old = self.timing_states[data.index] or self.timing_core.new()
      local previous_sim,previous_generation=old.sim,old.generation
      local next_state, event = self.timing_core.update(old, data)
      if next_state.generation~=previous_generation then next_state.raw_yaws={} end
      if data.sim~=previous_sim and data.sim>=(next_state.sim_frontier or data.sim) and event~="rollback" and event~="reset" and number(data.yaw) then
        next_state.raw_yaws=next_state.raw_yaws or {}
        table.insert(next_state.raw_yaws,Y_norm(data.yaw))
        if #next_state.raw_yaws>16 then table.remove(next_state.raw_yaws,1) end
        next_state.pattern=self.record_tools.pattern(next_state.raw_yaws)
      end
      if data.sim~=previous_sim then next_state.sample_revision=(next_state.sample_revision or 0)+1 end
      self.timing_states[data.index] = next_state
      next_state.last_event = event
      self.timing_reads = self.timing_reads + 1
    end
  end
  for index in pairs(self.timing_states) do
    if not present[index] then self.timing_states[index] = nil end
  end
end
function Y:timing_decision(index)
  return self.timing_core.decision(self.timing_states[index], number(globals.tickcount) or 0)
end
function Y.shot_evidence(ent,bt,shot_id)
  local result={valid=false,reason="no target receipt",execution="unverified",schema=2}
  if not ent then return result end
  local ok,idx,uid,sim,yaw=pcall(function ()
    local i=ent:get_index();local info=ent:get_player_info();local value=ent:get_simulation_time()
    local current=type(value)=="table" and value.current or value
    local angle=ent.m_angEyeAngles
    return i,info and tonumber(info.userid),number(current),angle and number(angle.y)
  end)
  if not ok or not number(idx) or not number(uid) or not sim then result.reason="target identity/simulation unavailable";return result end
  result.id,result.uid=idx,uid
  local L=Y.learn[idx];local observed=Y.timing_states[idx]
  if not L or L.__uid~=uid or not observed or observed.uid~=uid then result.reason="target UID mismatch or no observation";return result end
  if yaw_mode()=="FFI" then
    result.execution="ffi/native-unverified"
    local info=Y.native_trace and shot_id and Y.native_trace:shot_context_evidence(shot_id,idx,uid)
    result.native_context_calls=info and info.context_calls or 0
    result.native_own_returns=info and info.own_returns or 0
    result.native_token=info and info.token;result.native_snapshot=info and info.snapshot
    result.native_context=info and info.context
    result.reason=result.native_own_returns>0 and "own-pointer return observed near shot; selected record/hitboxes unproven" or "no own-pointer return observed in this shot window"
    if result.native_own_returns>0 then result.execution="ffi/own-pointer-temporal" end
    return result
  end
  if L.__native_receipt and Y.native_requested() then
    result.execution="native-record/unverified-shot-selection"
    result.reason="native scalar readback is not proof of selected native shot record"
    result.target_status=L.__status
    result.native_selector_observed=true; result.native_scalar_written=nil
    return result
  end
  result.prior_readback=L.__write_verified==true
  result.status=L.__status or "no per-target update status"
  result.bucket=L.__cur;result.state=L.__state;result.base=number(L.__base)
  if not get_bool(cfg.resolver) or not get_bool(cfg.yaw) or Y.suspended or Y.fault or Y.yielded then result.reason="custom yaw path inactive";result.execution="native/withheld";return result end
  if L.__record_guard or not L.__write_verified then result.reason="no usable current write receipt";result.execution="native/withheld";return result end
  local tick=number(globals.tickcount);local iv=number(globals.tickinterval)
  if not tick or not iv or iv<=0 then result.reason="invalid clock";return result end
  local decision=Y:timing_decision(idx)
  if decision.status=="stale" or decision.defensive then result.reason="stale or defensive observation";return result end
  if L.__sample_generation~=observed.generation or L.__sample_revision~=observed.sample_revision then result.reason="observation revision mismatch";return result end
  if not L.__write_tick or tick<L.__write_tick or tick-L.__write_tick>2 then result.reason="write receipt expired";return result end
  local sim_tick=math.floor(sim/iv+0.5)
  if L.__applied_sim~=sim_tick or observed.sim~=sim_tick then result.reason="simulation mismatch";return result end
  local shared=Y.observation_bridge and Y.observation_bridge:assessment(idx,uid,tick,iv)
  if not shared or shared.invalid or not number(shared.sim) or math.abs(shared.sim-sim)>iv*0.1 then result.reason="shared record mismatch or invalid";return result end
  local applied=number(L.__applied_yaw)
  if not yaw or not applied or math.abs(Y_norm(yaw-applied))>0.1 then result.reason="live angle no longer matches receipt";return result end
  local backtrack=number(tonumber(bt))
  if backtrack==nil or backtrack<0 or backtrack%1~=0 then result.reason="selected record information unavailable";return result end
  if backtrack>0 then result.reason="native historical record not exposed";result.execution="historical/unverified";return result end
  if not result.base or math.abs(Y_norm(applied-result.base))<0.5 then result.reason="no actual angle correction";result.execution="native/no-angle-change";return result end
  result.valid=true;result.reason="current entity readback; native hitbox correctness unproven"
  result.execution="custom/current-observation";result.yaw=applied
  result.sim_tick,result.generation,result.revision=sim_tick,observed.generation,observed.sample_revision
  return result
end

function Y:update()
  if Y.native_records and not Y.native_requested() then
    Y.native_records:restore_live()
  end
  if self.suspended or ANEMONE_SECOND_COPY then
    return
  end
  local resolver_master = get_bool(cfg.resolver)
  local yaw_active = resolver_master and get_bool(cfg.yaw)
  local assist_active = resolver_master and get_bool(cfg.assist)
  if not yaw_active and not assist_active then
    if self.enabled then
      self:reset("switch off")
    end
    return
  end
  local decay_now = clock()
  if decay_now - (self.last_decay or 0) >= 5 then
    self.last_decay = decay_now
    for _, L in pairs(self.learn) do
      for bucket, rec in pairs(L) do
        if type(rec) == "table" and rec.m and rec.h and rec.m > rec.h then
          rec.m = rec.m - 1
        end
      end
    end
  end
  if self.fault then
    if clock() < (self.fault_until or 0) then
      return
    end
    self.fault = nil
  end
  if not globals or globals.is_in_game ~= true then
    self.last_status = "Yaw-Resolver: PAUSE"
    return
  end
  if N.master and not N:master_enabled() then
    self.last_status = "Yaw-Resolver: native Ragebot off; unchanged"
    return
  end
  if yaw_active and Y_native_on() then
    self.yielded = true
    self.last_status = "Yaw-Resolver: native Override Resolver ON; custom resolver yielded"
    warn_once("yaw_native_conflict", "Yaw Resolver: native Override Resolver is ON; the custom resolver yields. Disable the native resolver to use Anemone's own yaw logic.")
    return
  end
  self.yielded = false
  self.enabled = yaw_active
  local ok, threat = pcall(function ()
    return entity.get_threat()
  end)
  if not ok or not threat then
    self.last_status = "Yaw-Resolver: no current threat"
    return
  end
  local ok2, alive, dormant, enemy = pcall(function ()
    return threat:is_alive(), threat:is_dormant(), threat:is_enemy()
  end)
  if not ok2 or not alive or dormant or not enemy then
    self.last_status = "Yaw-Resolver: threat not a live enemy"
    return
  end
  if Y.steam_exclusion and Y.steam_exclusion:is_protected(threat) then
    self.last_status="Yaw-Resolver: protected SteamID; custom resolver skipped (conditional global damage gate)"
    return
  end
  local base, kind = Y_angle(threat)
  if not base then
    self.last_status = "Yaw-Resolver: eye angles unavailable"
    return
  end
  local vel_angle, speed = Y_velocity(threat)
  local lby = Y_lby(threat)
  local t = clock()
  local ok3, target_id = pcall(function ()
    return threat:get_index()
  end)
  if not ok3 or not number(target_id) then
    local ok4, info = pcall(function ()
      return threat:get_player_info()
    end)
    if ok4 and type(info) == "table" and number(tonumber(info.userid)) then
      target_id = tonumber(info.userid)
    else
      self.last_status = "Yaw-Resolver: target index unavailable"
      return
    end
  end
  if self.brute_target ~= target_id then
    self.brute, self.brute_target = 0, target_id
  end
  if self.miss_target == target_id and t - self.last_miss <= 2.0 then
    self.brute = math.min(8, self.brute + 1)
    self.miss_target, self.last_miss = nil, 0
  end
  local L = self.learn[target_id]
  if not L then
    L = { }
    self.learn[target_id] = L
  end
  local tick = number(globals.tickcount) or 0
  local observed=self.timing_states[target_id]
  if observed and observed.uid and L.__uid~=observed.uid then L={__uid=observed.uid};self.learn[target_id]=L end
  local timing_now=self:timing_decision(target_id)
  local shared=Y.observation_bridge and Y.observation_bridge:assessment(target_id,nil,tick,globals.tickinterval)
  if shared then Y.observation_bridge:consume("resolver") end
  local native_record
  if Y.native_records then
    local allowed,reason,record=Y.native_records:guard(threat,"resolver")
    native_record=record;L.__native_snapshot=record
    if not allowed and shared then shared.invalid=true;shared.status=reason end
  end
  local structural_bad=observed and (timing_now.status=="stale" or timing_now.defensive or observed.sim<(observed.sim_frontier or observed.sim) or observed.last_event=="reset")
  local record_guard={skip_yaw=not observed or not observed.uid or not shared or structural_bad or shared.invalid or false}
  L.__record_guard = record_guard.skip_yaw
  if record_guard.skip_yaw then
    L.__cur, L.__yaw, L.__base = "record_guard", nil, base
    L.__state = (self.timing_states[target_id] or {}).state or "unknown"
    L.record_quality = 0
    L.__applied_yaw,L.__applied_sim,L.__write_verified=nil,nil,false
    L.__stable_yaw,L.__stable_mode,L.__stable_tick=nil,nil,nil
    self.last_angles,self.last_target=nil,nil
    self.mode="record_guard"
    self.last_status="Yaw-Resolver: invalid/frozen record; custom yaw withheld"
    L.__status=self.last_status
    self.guard_skips=(self.guard_skips or 0)+1
    return
  end
  if observed and L.__sample_generation==observed.generation and L.__sample_revision==observed.sample_revision then
    self.last_status="Yaw-Resolver: cached candidate; no fresh simulation observation"
    L.__status=self.last_status
    return
  end
  if observed and number(observed.yaw) then base=observed.yaw end
  L.__applied_yaw,L.__applied_sim,L.__write_verified=nil,nil,false
  local pose_delta = Y_pose_delta(threat)
  local duck = Y_duck_amount(threat)
  local state, delta = Y_state(threat, speed, duck, pose_delta)
  if shared then
    L.observed_quality,L.observed_acceleration=shared.quality,shared.acceleration
    if shared.anim_limit and state~="air" then delta=math.min(delta,shared.anim_limit) end
  end
  Y.game_context(L, threat, state, speed, duck, tick)
  Y.lby_span_track(L, base, lby, tick, state)
  if state ~= "air" then
  end
  local body_hint = lby or (pose_delta and Y_norm(base + pose_delta)) or base
  if state ~= "air" then
    Y_track_jitter(L, body_hint, tick, state)
  end
  local jitter = L.jitter or 0
  local side = Y_desync_side(L, base, pose_delta, lby)
  L.body_hint = pose_delta and Y_norm(base + pose_delta) or nil
  L.body_strength = pose_delta and math.abs(pose_delta) or 0
  track_stability(L, state, speed, base, lby, tick)
  Y.context_signal(L, state, speed, pose_delta, lby, base, tick)
  Y.evalate_signal(L, base, pose_delta, lby, delta, tick, state)
  local aim_yaw = Y.aim_at_me(threat)
  if aim_yaw then
    L.aim_delta = math.abs(Y_norm(aim_yaw - base))
    L.defensive = L.aim_delta >= 110
  else
    L.aim_delta = nil
    L.defensive = nil
  end
  L.distance_sqr = Y.distance_sqr(threat)
  Y.head_signal(L, threat, base, tick)
  L.__state, L.__base, L.__side, L.__delta = state, base, side, delta
  L.__candidate_anchor = base
  Y.lby_cadence(L, state, speed, lby, tick, base)
  if L.game_special then
    L.__cur, L.__yaw = "special_move", base
    self.mode = "special_move"
    self.last_status = "Yaw-Resolver: native resolver; special MoveType " .. tostring(L.game_move_type)
    L.__status=self.last_status
    if yaw_mode()=="FFI" then self.last_status="FFI: special movement withheld; no SDK fallback";L.__status=self.last_status;return end
    if self.last_target ~= target_id or not self.last_angles or math.abs(Y_norm(base - self.last_angles)) >= 0.5 then
      local applied,changed=Y_apply(threat,base)
      if applied then
        if changed then self.writes=self.writes+1 else self.unchanged=(self.unchanged or 0)+1 end
        self.last_write, self.last_target, self.last_angles = t, target_id, base
      end
    end
    return
  end
  local spinning = jitter > 0.72 and speed < 15 and not L.alternating and (L.spin_score or 0) > 0.70
  local rmode = (assist_active and not yaw_active) and "Free" or yaw_mode()
  if rmode == "Adaptive" or rmode == "FFI" then
    Y.adaptive_signal(L, threat, base, pose_delta, lby, speed, tick, state)
  end
  L.native_candidate=nil;L.native_candidates=nil
  local yaw, mode
  if spinning then
    yaw = Y_norm(base + clamp(L.spin_step or 0, - delta, delta))
    mode = "spin"
  elseif rmode == "Beta" then
    yaw, mode = Y.resolve_beta(L, base, vel_angle, speed, lby, tick, jitter, side, state, delta)
  elseif rmode == "Adaptive" or rmode == "FFI" then
    yaw, mode = Y.resolve_adaptive(L, base, vel_angle, speed, lby, tick, jitter, side, state, delta)
  else
    yaw, mode = Y.resolve_free(L, base, vel_angle, speed, lby, tick, jitter, side, state, delta, self.last_angles, self.last_target == target_id, t, self.brute)
  end
  local timing = self:timing_decision(target_id)
  L.timing_status, L.timing_confidence = timing.status, timing.confidence
  L.timing_pulse, L.timing_forecast = timing.pulse, timing.forecast
  if timing.baseline and (timing.pulse or timing.forecast) then
    local observer = self.timing_states[target_id]
    local proven = observer and #observer.pulse_events >= 2
    if proven and not L.side_switch and (tonumber(L.record_quality) or 0) >= 0.45 then
      yaw, mode = Y.gate_clamp(L, state, timing.baseline), "pulse_baseline"
      L.__stable_yaw, L.__stable_mode = nil, nil
    end
  end
  yaw, mode = Y.stabilize(L, yaw, mode, tick)
  if not number(yaw) then
    local safe_base = number(base) or 0
    local safe_delta = clamp(number(delta) or 0, 0, 60)
    local safe_side = number(side) and (side >= 0 and 1 or - 1) or 1
    if state == "air" then
      yaw, mode = Y_norm(safe_base), "air_eye_fallback"
    elseif number(lby) then
      yaw, mode = Y.gate_clamp(L, state, lby), "lby_safe_fallback"
    else
      yaw, mode = Y.gate_clamp(L, state, safe_base + safe_side * safe_delta), "commit_safe_fallback"
    end
    L.resolve_fallbacks = (L.resolve_fallbacks or 0) + 1
  end
  if state=="air" then
    local offset=Y_norm(yaw-base)
    if math.abs(offset)>58 then yaw=Y_norm(base+(offset>=0 and 58 or -58));mode=mode.."_eye_limit" end
  end
  L.__cur, L.__yaw = mode, yaw
  if observed then L.__sample_generation,L.__sample_revision=observed.generation,observed.sample_revision end
  self.mode = mode
  if assist_active and not yaw_active then
    self.last_status = string.format("Assist Resolver: observing %s / conf %.2f", mode, tonumber(L.static_confidence) or 0)
    L.__status=self.last_status
    return
  end
  if rmode=="FFI" or Y.native_requested() then
    L.__write_verified,L.__applied_yaw,L.__applied_sim=false,nil,nil
    if not Y.native_requested() then
      self.last_status="FFI native helper/context unavailable; SDK yaw fallback withheld"
      L.__status=self.last_status;return
    end
    local native_confidence,native_detail=Y.native_selection(L,yaw)
    native_detail.bucket=native_detail.mode;native_detail.base=L.__base;native_detail.observer_generation=observed and observed.generation;native_detail.observer_revision=observed and observed.sample_revision;native_detail.feedback_epoch=Y.feedback_epoch or 0
    native_detail.native_mode=rmode;native_detail.record_quality=tonumber(L.record_quality);native_detail.jitter=tonumber(L.jitter);native_detail.stability=tonumber(L.state_stability);native_detail.duck=Y_duck_amount(threat)
    local receipt,reason=Y.native_records:resolve(threat,yaw,native_confidence,state,native_detail)
    L.__native_receipt=receipt
    if rmode=="FFI" and Y.native_trace and Y.native_trace.own_status then
      self.last_status=Y.native_trace:own_status()
    else
      self.last_status=(rmode=="FFI" and "FFI native-only: " or "Native selector: ")..tostring(reason)
    end
    L.__status=self.last_status;return
  end
  L.__native_receipt=nil
  local applied,changed=Y_apply(threat,yaw)
  if applied then
    if changed then self.writes=self.writes+1 else self.unchanged=(self.unchanged or 0)+1 end
    self.last_write, self.last_target, self.last_angles = t, target_id, yaw
    L.__applied_yaw,L.__applied_sim,L.__write_verified=yaw,observed and observed.sim or nil,true
    L.__write_tick=tick
    self.last_status = string.format("Yaw-Resolver: %s -> %.1f (base %.1f, idx %d)", mode, yaw, base, self.brute + 1)
    L.__status=self.last_status
  else
    self.blocked = self.blocked + 1
    self.last_status = "Yaw-Resolver: write blocked (API)"
    L.__status=self.last_status
  end
end
function Y:note_miss(ent)
  if not Y.path_active() or self.fault or self.suspended then
    return
  end
  local ok, id = pcall(function ()
    return ent:get_index()
  end)
  if not ok or not number(id) then
    return
  end
  self.miss_target, self.last_miss = id, clock()
end
function Y:on_shot(event)
  if yaw_mode()=="FFI"and self.ffi_feedback then self.ffi_feedback:fire(event)end
  if self.suspended or self.fault or not Y.path_active() then
    return
  end
  local ok, tid = pcall(function ()
    local t = event.target
    if not t then
      return nil
    end
    local idx = t:get_index()
    if number(idx) then
      return idx
    end
    local info = t:get_player_info()
    return info and tonumber(info.userid) or nil
  end)
  if not ok or not tid then
    return
  end
  local L = self.learn[tid]
  local shot_id=number(tonumber(event.id))
  if not shot_id or shot_id<0 or shot_id%1~=0 then return end
  local evidence=Y.shot_evidence(event.target,event.backtrack,shot_id)
  if not evidence.valid then return end
  local bucket = (L and L.__cur) or "unknown"
  local st = (L and L.__state) or "unknown"
  local mode = yaw_mode()
  local now, tick = clock(), number(globals.tickcount) or 0
  for id, old in pairs(self.shots) do
    local stale_time = old.time and (now < old.time or now - old.time > FEEDBACK_CFG.shot_ttl)
    local stale_tick = old.tick and (tick < old.tick or tick - old.tick > FEEDBACK_CFG.shot_tick_ttl)
    if stale_time or stale_tick then
      self.shots[id] = nil
    end
  end
  local base = L and tonumber(L.__base) or nil
  local yaw = evidence.yaw
  local resolve_side = base and yaw and (Y_norm(yaw - base) >= 0 and 1 or - 1) or (L and L.__side) or 1
  local tf = L and L.adaptive_features or nil
  self.shots[shot_id] = {
    tid = tid,
    uid=evidence.uid,
    generation=evidence.generation,
    evidence_schema=2,
    feedback_epoch=self.feedback_epoch or 0,
    bucket = bucket,
    state = st,
    mode = mode,
    base = base,
    yaw = yaw,
    side = resolve_side,
    static_confidence = (L and tonumber(L.static_confidence)) or 0,
    adaptive_features = tf and {
      tf[1],
      tf[2],
      tf[3],
      tf[4],
      tf[5],
      tf[6],
      tf[7],
      tf[8],
      tf[9],
      tf[10],
      tf[11],
      tf[12],
      tf[13],
      tf[14]
    } or nil,
    beta_confidence = (L and tonumber(L.beta_confidence)) or 0,
    adaptive_confidence = (L and tonumber(L.adaptive_confidence)) or 0,
    ult_confidence = (L and tonumber(L.ult_confidence)) or 0,
    record_quality = (L and tonumber(L.record_quality)) or 0,
    tick = tick,
    time = now
  }
  local n = 0
  for _ in pairs(self.shots) do
    n = n + 1
  end
  if n > 256 then
    self.shots = { }
  end
end
function Y:on_ack(event)
  if yaw_mode()=="FFI"and self.ffi_feedback and event then self.ffi_feedback:ack(event)end
  if not event then
    return
  end
  local normalized_id=number(tonumber(event.id))
  local shot=normalized_id and self.shots[normalized_id] or nil
  local shot_key=shot and normalized_id or nil
  if not shot and event.id ~= nil then
    shot = self.shots[tostring(event.id)]
    shot_key = shot and tostring(event.id) or nil
  end
  if shot and event.target then
    local target_index
    pcall(function () target_index=event.target:get_index() end)
    if tonumber(shot.tid)~=tonumber(target_index) then shot,shot_key=nil,nil end
  end
  if not shot then
    return
  end
  self.shots[shot_key] = nil
  if event.id ~= nil then
    self.shots[event.id] = nil
    self.shots[tostring(event.id)] = nil
  end
  if shot.time and (clock() < shot.time or clock() - shot.time > FEEDBACK_CFG.shot_ttl) then
    return
  end
  local now_tick = number(globals.tickcount) or 0
  if shot.tick and (now_tick < shot.tick or now_tick - shot.tick > FEEDBACK_CFG.shot_tick_ttl) then
    return
  end
  if shot.mode == "Adaptive" and FEEDBACK_CFG.isolate_per_shot then
    local ack_tid = nil
    pcall(function ()
      if event.target then
        ack_tid = event.target:get_index()
      end
    end)
    if ack_tid and tonumber(ack_tid) ~= tonumber(shot.tid) then
      return
    end
  end
  local L = self.learn[shot.tid]
  if not L then
    return
  end
  if shot.evidence_schema~=2 or shot.uid~=L.__uid or shot.feedback_epoch~=(self.feedback_epoch or 0) then return end
  local observer=self.timing_states[shot.tid]
  if not observer or observer.uid~=shot.uid or observer.generation~=shot.generation then return end
  local state = shot.state or "unknown"
  local bucket = shot.bucket or "unknown"
  L.by_state = L.by_state or { }
  L.by_state[state] = L.by_state[state] or { }
  L.state_miss = L.state_miss or { }
  L.last_hit_by_state = L.last_hit_by_state or { }
  local global = L[bucket] or { h = 0, m = 0 }
  L[bucket] = global
  local rec = L.by_state[state][bucket] or { h = 0, m = 0 }
  L.by_state[state][bucket] = rec
  self.population.learned = (self.population.learned or 0) + 1
  local function reward(row, hit, weight)
    if hit then
      row.h = (row.h or 0) + 1
      row.wh = (row.wh or 0) + 1
      row.streak = 0
    else
      row.m = (row.m or 0) + 1
      row.wm = (row.wm or 0) + weight
      row.streak = (row.streak or 0) + weight
    end
  end
  local reason = event.state
  if reason == nil then
    reason = event.reason
  end
  local tick = number(globals.tickcount) or shot.tick or 0
  feedback_decay(L, tick)
  if reason == nil then
    reward(global, true, 1)
    ;
    reward(rec, true, 1)
    L.consec_miss = 0
    L.state_miss[state] = 0
    L.last_hit, L.last_hit_by_state[state] = clock(), clock()
    Y.angel_feedback(L, shot.mode, true, tick, state)
    local hg = tostring(event.hitgroup or ""):lower()
    Y.remanemone_hit(L, state, shot.yaw, tick, bucket)
    if shot.mode == "Adaptive" then
      Y.adaptive_feedback(L, bucket, shot.adaptive_features, true, 1)
      if L.adaptive_ban then
        for key in pairs(L.adaptive_ban) do
          if key:sub(1, # state + 1) == state .. "|" then
            L.adaptive_ban[key] = nil
          end
        end
      end
    end
    if shot.mode == "Beta" and L.beta_ban then
      for key in pairs(L.beta_ban) do
        if key:sub(1, # state + 1) == state .. "|" then
          L.beta_ban[key] = nil
        end
      end
    end
    if shot.mode == "Adaptive" and FEEDBACK_CFG.static_aa_correction then
      if hg == "head" or hg == "1" then
        L.feedback_bias, L.feedback_samples = 0, 0
      elseif hg ~= "" and (shot.static_confidence or 0) >= FEEDBACK_CFG.min_static_confidence then
        L.feedback_bias = clamp((L.feedback_bias or 0) * 0.88 + (shot.side or 1) * 3.5, - 48, 48)
      end
    end
    return
  end
  local bt = tonumber(event.backtrack) or 0
  local weight = bt >= 12 and 0.35 or bt >= 8 and 0.50 or bt >= 5 and 0.72 or 1.0
  local reason_key = tostring(reason):lower():gsub("^%s+", ""):gsub("%s+$", "")
  if reason_key == "damage rejection" then
    reward(global, true, 1)
    ;
    reward(rec, true, 1)
    L.consec_miss = 0
    Y.remanemone_hit(L, state, shot.yaw, tick, bucket)
    Y.angel_feedback(L, shot.mode, true, tick, state)
    if shot.mode == "Adaptive" then
      Y.adaptive_feedback(L, bucket, shot.adaptive_features, true, 0.5)
    end
    return
  end
  local resolver_miss = reason_key == "correction" or reason_key == "resolver" or reason_key == "?"
  if not resolver_miss then
    return
  end
  local spread = tonumber(event.spread) or 0
  if spread >= FEEDBACK_CFG.max_learning_spread then
    return
  end
  local weak_evidence = weight <= FEEDBACK_CFG.min_feedback_weight
  if shot.mode == "Adaptive" and not weak_evidence then
    L.evalate_brute = - (tonumber(L.evalate_brute) or 1)
    L.evalate_forced, L.evalate_yaw = nil, nil
  end
  reward(global, false, weight)
  ;
  reward(rec, false, weight)
  Y.remanemone_miss(L, state, shot.yaw, tick, weight, bucket)
  if shot.mode == "Adaptive" and not weak_evidence then
    Y.adaptive_feedback(L, bucket, shot.adaptive_features, false, weight)
    L.adaptive_ban = L.adaptive_ban or { }
    L.adaptive_ban[state .. "|" .. bucket] = tick + FEEDBACK_CFG.adaptive_ban_ticks
  end
  if shot.mode == "Beta" and not weak_evidence then
    L.beta_ban = L.beta_ban or { }
    L.beta_ban[state .. "|" .. bucket] = tick + FEEDBACK_CFG.adaptive_ban_ticks
  end
  if shot.mode == "Adaptive" and FEEDBACK_CFG.static_aa_correction and not weak_evidence and (shot.static_confidence or 0) >= FEEDBACK_CFG.min_static_confidence then
    local confidence = clamp(shot.static_confidence or FEEDBACK_CFG.min_static_confidence, 0.25, 1)
    local gain = math.min(1.75, 1 + (L.feedback_samples or 0) * 0.08)
    L.feedback_bias = clamp((L.feedback_bias or 0) * 0.88 - (shot.side or 1) * 4 * confidence * gain, - 52, 52)
    L.feedback_samples = math.min(16, (L.feedback_samples or 0) + 1)
  end
  if not weak_evidence then
    L.consec_miss = (L.consec_miss or 0) + 1
    L.state_miss[state] = (L.state_miss[state] or 0) + 1
    Y.angel_feedback(L, shot.mode, false, tick, state)
  end
end
function Y:log_miss_ack(event, shot)
  if not event then
    return
  end
  local reason = event.state
  if reason == nil then
    reason = event.reason
  end
  if reason == nil then
    self.ack_stats.hits = (self.ack_stats.hits or 0) + 1
    return
  end
  local raw_reason = tostring(reason)
  local reason_key = raw_reason:lower():gsub("^%s+", ""):gsub("%s+$", "")
  if reason_key == "" then
    reason_key = "unknown"
  end
  local spread_value = tonumber(event.spread)
  local spread_masked = spread_value ~= nil and spread_value >= FEEDBACK_CFG.max_learning_spread and (reason_key == "correction" or reason_key == "resolver" or reason_key == "?")
  self.ack_stats.misses = (self.ack_stats.misses or 0) + 1
  self.miss_counts[spread_masked and "spread (masked)" or reason_key] = (self.miss_counts[spread_masked and "spread (masked)" or reason_key] or 0) + 1
  if reason_key == "correction" and not spread_masked then
    self.ack_stats.correction = (self.ack_stats.correction or 0) + 1
  end
  if not shot then
    self.ack_stats.unmatched = (self.ack_stats.unmatched or 0) + 1
  end
  local id = tonumber(event.id) or 0
  local target = event.target
  local target_id, target_name
  pcall(function ()
    if target then
      target_id = target:get_index()
      target_name = target:get_name()
    end
  end)
  target_id = tonumber(target_id) or (shot and shot.id) or 0
  target_name = (shot and shot.tag) or target_name or "?"
  target_name = tostring(target_name):gsub("[%c|]", " "):sub(1, 48)
  local L = target_id ~= 0 and self.learn[target_id] or nil
  local bucket=(shot and shot.yaw_bucket) or "unmatched"
  local state=(shot and shot.yaw_state) or "unknown"
  local mode=(shot and shot.yaw_mode) or "Unmatched"
  local yaw = shot and shot.yaw_value or nil
  local bt = tonumber(event.backtrack) or (shot and shot.backtrack) or 0
  local interval = (shot and shot.interval) or (globals and number(globals.tickinterval))
  local bt_ms = interval and bt >= 0 and bt * interval * 1000 or nil
  local age = shot and math.max(0, clock() - (shot.time or clock())) or nil
  local hitchance = tonumber(event.hitchance)
  local spread = tonumber(event.spread)
  local wanted = tonumber(event.wanted_damage)
  local damage = tonumber(event.damage)
  local wanted_hg = event.wanted_hitgroup
  local hitgroup = event.hitgroup
  local safe = shot and tostring(shot.safe_value) or "?"
  local owned = shot and (shot.safe_owned and "anemone" or "native/external") or "unmatched"
  local corr = shot and tonumber(shot.yaw_corr) or nil
  local corr_abs = corr and math.abs(corr) or nil
  local corr_side = shot and tonumber(shot.yaw_side) or nil
  if corr and corr_side == nil then
    corr_side = corr >= 0 and 1 or - 1
  end
  local base = shot and tonumber(shot.yaw_base) or nil
  local pose = shot and tonumber(shot.yaw_pose) or nil
  local signal = "?"
  if spread ~= nil then
    signal = spread > LOG_CFG.noise_spread and "noise" or "clean"
  end
  local details = {
    "resolver_status=" .. tostring(shot and shot.resolver_status or "unmatched"),
    "native_fixes="..tostring(shot and shot.native_fix_state or "unknown"),
    "record_guard=" .. tostring(shot and shot.record_guard or false),
    "write_verified=" .. tostring(shot and shot.yaw_write_verified or false),
    "evidence_schema="..tostring(shot and shot.evidence_schema or "unmatched"),
    "yaw_execution="..tostring(shot and shot.yaw_execution or "unmatched"),
    "evidence_reason="..tostring(shot and shot.evidence_reason or "no shot receipt"),
    "prior_readback_receipt="..tostring(shot and shot.prior_readback_receipt or false),
    "ffi_first_shot="..tostring(shot and shot.ffi_first and shot.ffi_first.first),
    "ffi_shot_ordinal="..tostring(shot and shot.ffi_first and shot.ffi_first.ordinal),
    "ffi_selector_pending_at_fire="..tostring(shot and shot.ffi_first and shot.ffi_first.selector_pending),
    "ffi_construction_pending_at_fire="..tostring(shot and shot.ffi_first and shot.ffi_first.construction_pending),
    "ffi_publication_pending_at_fire="..tostring(shot and shot.ffi_first and shot.ffi_first.publication_pending),
    "ffi_approval_present_at_fire="..tostring(shot and shot.ffi_first and shot.ffi_first.approval_present),
    "ffi_context_calls="..tostring(shot and shot.native_context_calls or 0),
    "ffi_own_returns_temporal="..tostring(shot and shot.native_own_returns or 0),
    "ffi_token="..tostring(shot and shot.native_token),
    "ffi_snapshot="..tostring(shot and shot.native_snapshot),
    "ffi_latest_context_guard="..tostring(shot and shot.native_context and shot.native_context.guard_reason or "no temporal context"),
    "ffi_native_flags="..(shot and shot.native_context and string.format("%08X",shot.native_context.flags)or "unknown"),
    "ffi_native_capture="..tostring(shot and shot.native_context and shot.native_context.capture_tick),
    "ffi_native_age_ticks="..tostring(shot and shot.native_context and shot.native_context.capture_age_ticks),
    "ffi_approval_coverage="..tostring(shot and shot.native_context and shot.native_context.approval_coverage),
    "ffi_prior_attempt="..tostring(shot and shot.native_context and shot.native_context.attempt_stage)..":"..tostring(shot and shot.native_context and shot.native_context.attempt_reason),
    "ffi_approval_UID_match="..tostring(shot and shot.native_context and shot.native_context.approval_uid_match or false),
    "candidate=" .. tostring(shot and shot.yaw_candidate or "unknown"),
    "timing_evidence=" .. tostring(shot and shot.timing_evidence or "unknown"),
    "lerp=" .. tostring(shot and shot.lerp_seconds or "unknown"),
    "air_floors=" .. tostring(shot and shot.air_hc_floor or "unknown") .. "/" .. tostring(shot and shot.air_damage_floor or "unknown"),
    "packet=" .. tostring(shot and shot.packet_action or "unknown"),
    "timing=" .. tostring(shot and shot.timing_status or "unknown") .. "/conf=" .. tostring(shot and shot.timing_confidence or 0),
    "air_stop=" .. tostring(shot and shot.air_stop_state or "unknown"),
    string.format("#%d %s", id, target_name),
    "reason=" .. raw_reason .. (spread_masked and " [spread]" or ""),
    "signal=" .. signal .. (spread_masked and "/masked" or ""),
    "correlated=" .. (shot and "yes" or "NO"),
    "target=" .. tostring(target_id),
    "mode=" .. tostring(mode),
    "state=" .. tostring(state),
    "bucket=" .. tostring(bucket),
    "yaw=" .. (yaw and string.format("%.2f", yaw) or "unknown"),
    "corr=" .. (corr and string.format("%+.2f", corr) or "?") .. "/" .. (corr_abs and string.format("%.2f", corr_abs) or "?") .. "/" .. tostring((shot and shot.yaw_band) or "?") .. "/side=" .. (corr_side and (corr_side >= 0 and "+" or "-") .. "1" or "?"),
    "base=" .. (base and string.format("%.2f", base) or "?") .. "/pose=" .. (pose and string.format("%.2f", pose) or "?"),
    "sconf=" .. (shot and string.format("%.2f", tonumber(shot.resolver_confidence) or 0) or "?") .. "/econf=" .. (shot and string.format("%.2f", tonumber(shot.evalate_confidence) or 0) or "?") .. "/fbias=" .. (shot and string.format("%.2f", tonumber(shot.feedback_bias) or 0) or "?"),
    "evalate=" .. (shot and (shot.evalate_active and "ACTIVE" or "off") or "unmatched") .. "/brute=" .. (shot and tostring(shot.evalate_brute or "?") or "?") .. "/forced=" .. (shot and shot.evalate_forced and string.format("%.2f", shot.evalate_forced) or "?") .. "/conf=" .. (shot and string.format("%.2f", tonumber(shot.evalate_confidence) or 0) or "?"),
    "pack=q" .. (shot and string.format("%.2f", tonumber(shot.record_quality) or 0) or "?") .. "/beta=" .. (shot and string.format("%.2f", tonumber(shot.beta_confidence) or 0) or "?") .. "/plus=" .. (shot and string.format("%.2f", tonumber(shot.adaptive_confidence) or 0) or "?") .. "/ult=" .. (shot and string.format("%.2f", tonumber(shot.ult_confidence) or 0) or "?") .. "/proxy=" .. (shot and string.format("%.2f", tonumber(shot.adaptive_anim_proxy) or 0) or "?") .. "/roll=" .. (shot and shot.adaptive_roll_pose and string.format("%.2f", shot.adaptive_roll_pose) or "?") .. "/switch=" .. (shot and (shot.side_switch and "yes" or "no") or "?") .. "/micro=" .. (shot and (shot.micro_move and "yes" or "no") or "?"),
    "bt=" .. tostring(bt) .. "t/" .. (bt_ms and string.format("%.2fms", bt_ms) or "?ms"),
    "age=" .. (age and string.format("%.3fs", age) or "?s"),
    "srv=" .. (shot and tostring(shot.server_tick) or "?") .. "/" .. tostring(shot and shot.server_tick_source or "?") .. "/lag=" .. (shot and tonumber(shot.lag) and string.format("%.3fs", tonumber(shot.lag)) or "?") .. "/dead=" .. (shot and tonumber(shot.dead_time) and string.format("%.3fs", tonumber(shot.dead_time)) or "?") .. "/lat=" .. (shot and tonumber(shot.latency) and string.format("%.3fs", tonumber(shot.latency)) or "?") .. "/unlag=" .. (shot and tonumber(shot.max_unlag) and string.format("%.3fs", tonumber(shot.max_unlag)) or "?"),
    "safe=" .. safe .. "/" .. owned,
    "hc_ack=" .. (hitchance and string.format("%.1f", hitchance) or "?"),
    "spread=" .. (spread and string.format("%.3f", spread) or "?"),
    "dmg=" .. tostring(damage or "?") .. "/" .. tostring(wanted or "?"),
    "hg=" .. tostring(hitgroup or "?") .. "/" .. tostring(wanted_hg or "?"),
  }
  local log = self.miss_log
  log[# log + 1] = table.concat(details, " | ")
  Y.miss_state.miss_log = self.miss_log
  Y.miss_state.bucket_stats = self.bucket_stats
  Y.miss_state.miss_counts = self.miss_counts
  Y.miss_state.ack_stats = self.ack_stats
  Y.miss_state.mode_stats = self.mode_stats
  Y.miss_state.delta_stats = self.delta_stats
  Y.miss_state.population = self.population
  if # log > LOG_CFG.max_rows then
    table.remove(log, 1)
  end
end
function Y:miss_log_lines()
  local lines, log, a = { }, self.miss_log, self.ack_stats
  lines[#lines+1] = "==== Anemone Miss Logs ===="
  lines[#lines+1] = "resolver_live: " .. tostring(self.last_status) .. " | timing_reads=" .. tostring(self.timing_reads or 0) .. " | writes=" .. tostring(self.writes or 0) .. " | rollback_guard_skips=" .. tostring(self.guard_skips or 0)
  lines[#lines+1] = "AirStop: " .. tostring(self.air_stop_state or "OFF") .. "; sampled HC is an estimate, not native firing-decision HC."
  lines[#lines+1] = string.format("acks: hits=%d misses=%d correction=%d unmatched_miss_rows=%d | stored=%d", a.hits or 0, a.misses or 0, a.correction or 0, a.unmatched or 0, #log)
  local pop = self.population or { }
  lines[#lines+1] = string.format(
    "population: acks=%d hits=%d misses=%d correlated=%d matched=%d learned=%d wide_rejects=%d | noise_spread=%.2f learn_max_spread=%.1f",
    pop.acks or 0, pop.hits or 0, pop.misses or 0, pop.correlated or 0, pop.matched or 0, pop.learned or 0, pop.wide_rejects or 0,
    LOG_CFG.noise_spread, FEEDBACK_CFG.max_learning_spread)
  lines[#lines+1] = "note: hc_ack/spread are values reported by the ack event, not values used by the firing decision."
  lines[#lines+1] = "note: signal=noise is reporting-only (spread > noise_spread); it never gates learning."
  lines[#lines+1] = "note: wide_rejects counts candidates dropped for sitting further than the per-state aim limit (stand/slow/duck 60, move 75, air 95) from the recorded eye yaw."
  lines[#lines+1] = "note: Baseline = master or Yaw path was off, so the native ragebot resolved. Compare its hitrate against the mode rows to judge the custom resolver."
  lines[#lines+1] = "---- persistent per-mode totals ----"
  for _, mode in ipairs({ "Baseline", "Beta", "Adaptive", "FFI", "Assist", "Unmatched" }) do
    local row = self.mode_stats[mode]
    if row then
      local attempts = (row.hits or 0) + (row.misses or 0)
      local hitrate = attempts > 0 and (row.hits or 0) * 100 / attempts or 0
      lines[#lines+1] = string.format("mode %-9s | hits=%d misses=%d correction=%d attempts=%d hitrate=%.1f%%", mode, row.hits or 0, row.misses or 0, row.correction or 0, attempts, hitrate)
    end
  end
  local reasons = { }
  for reason, count in pairs(self.miss_counts) do reasons[#reasons+1] = { reason=reason, count=count } end
  table.sort(reasons, function(a1,b1) if a1.count~=b1.count then return a1.count>b1.count end return a1.reason<b1.reason end)
  if #reasons==0 then lines[#lines+1]="reasons: none captured" else
    for _, r in ipairs(reasons) do lines[#lines+1]=string.format("reason %-24s | count=%d",r.reason,r.count) end
  end
  lines[#lines+1] = "---- applied correction by candidate x magnitude band x side ----"
  local any_delta = false
  local order = { }
  for bucket in pairs(self.delta_stats) do order[#order+1] = bucket end
  table.sort(order)
  for _, bucket in ipairs(order) do
    local cells = { }
    for key, rec in pairs(self.delta_stats[bucket]) do
      cells[#cells+1] = { key=key, h=rec.h or 0, m=rec.m or 0 }
    end
    table.sort(cells, function (x, y) return x.key < y.key end)
    local parts = { }
    for _, c in ipairs(cells) do
      local attempts = c.h + c.m
      local hitrate = attempts > 0 and c.h * 100 / attempts or 0
      parts[#parts+1] = string.format("%s h%d/m%d/%d%%", c.key, c.h, c.m, math.floor(hitrate + 0.5))
    end
    if #parts > 0 then
      any_delta = true
      lines[#lines+1] = string.format("delta %-14s | %s", bucket, table.concat(parts, "  "))
    end
  end
  if not any_delta then
    lines[#lines+1] = "delta: no rows captured (no shot carried a base/applied yaw pair)"
  end
  lines[#lines+1] = "---- chronological misses (oldest -> newest) ----"
  for i=1,#log do lines[#lines+1]=log[i] end
  lines[#lines+1] = string.format("---- per-candidate hit/miss (correlated shots only, %d of %d acks; unmatched acks carry no bucket) ----", pop.correlated or 0, pop.acks or 0)
  local rows={ }
  for bucket, rec in pairs(self.bucket_stats) do rows[#rows+1]={bucket=bucket,h=rec.h or 0,m=rec.m or 0} end
  table.sort(rows,function(a1,b1) if a1.h~=b1.h then return a1.h>b1.h end return a1.bucket<b1.bucket end)
  local cand_h, cand_m = 0, 0
  for _,r in ipairs(rows) do
    lines[#lines+1]=string.format("candidate %-12s | hits=%d misses=%d",r.bucket,r.h,r.m)
    cand_h, cand_m = cand_h + r.h, cand_m + r.m
  end
  lines[#lines+1] = string.format("candidate %-12s | hits=%d misses=%d", "TOTAL", cand_h, cand_m)
  lines[#lines+1] = "==== end of Miss Logs ===="
  return lines
end
function Y:build_miss_log_text()
  return table.concat(self:miss_log_lines(), "\r\n")
end
function Y:reset(reason)
  self.enabled = false
  self.last_status = "Yaw-Resolver: OFF"
end
function Y:guard(method, ...)
  local perf=method==self.update and self.native_trace or nil
  local started=perf and perf:perf_start()
  local ok, err = pcall(method, self, ...)
  if perf then perf:perf_finish("resolver_update",started) end
  if not ok then
    self.fault = "yaw resolver error"
    local detail = tostring(err):gsub("%c", " "):sub(1, 90)
    self.last_status = "Yaw-Resolver: error: " .. detail
    self.fault_until = clock() + 5
    warn_once("yaw_resolver_fault", self.fault .. ": " .. detail)
  end
end
local rb = ui.create(cfg.main_tab, "\226\128\142", 2)
cfg.adaptive_helpers_label = rb:label(label(icon({ "gears", "gear", "sliders" }), "Adaptive Helpers"))
local adaptive_helpers_menu = cfg.adaptive_helpers_label:create()
cfg.predict_exploit_uncharge = adaptive_helpers_menu:switch("Predict Exploit Uncharge", false)
cfg.adaptive_fakelags = adaptive_helpers_menu:switch("Adaptive Fake Lags", true)
cfg.ping_spike = adaptive_helpers_menu:switch("Exploit Backtrack", false)
tooltip(cfg.predict_exploit_uncharge, "Automatic observed-window prediction. One switch; no packet-policy settings. Reacts to fresh rollback / verified burst+shot / repeated windows. Never edits movement, attack or tickcount; never chokes packets.")
tooltip(cfg.adaptive_fakelags, "Juicy adaptive fake lag policy: irregular depth, distance/aim/exploit/air/shot compensation and bounded variability.")
tooltip(cfg.ping_spike, "Native Fake Latency helper (legacy Ping Spike). Does not extend the server lag-compensation window or patch backtrack records. No random per-command latency changes or sv_maxunlag writes.")
cfg.version_state.resolver_label = label(icon({ "shield-halved", "shield-check", "shield" }), "Resolver")
cfg.native_code_patches = rb:switch("Native Code Patches FFI (experimental)", false)
local native_patch_menu = cfg.native_code_patches:create()
cfg.native_patch_extrap = native_patch_menu:switch("Extrapolation ticks limit", false)
-- Native tick limit is created under Extrapolation below.
cfg.native_patch_hitscan = native_patch_menu:switch("Hitscan fix", false)
cfg.native_patch_lerp = native_patch_menu:switch("Fix backtrack lerp", false)
tooltip(cfg.native_code_patches, "Experimental pinned Windows x86 code patches. Separate from record writes. Exact byte verification, OS writes, instruction-cache flush and owned-byte restoration. Code changes are not atomic across all native threads. Do not combine with another script patching these sites.")
tooltip(cfg.native_patch_extrap, "Changes only the verified native cmp immediate. Original value is 2. Does not rewrite record origins or matrices.")
tooltip(cfg.native_patch_hitscan, "Removes the two verified conditional branches from Barsik. Does not prove improved hitbox correctness; no native validator replacement.")
tooltip(cfg.native_patch_lerp, "Switches the verified instruction operand from the existing 0.5 constant to the existing 1.5 constant. Does not change server sv_maxunlag.")
-- Neverlose disallows a popup group inside Adaptive Helpers. Hidden legacy controls stay at the root.
local native_records_menu = rb
cfg.native_record_write = native_records_menu:switch("Automatic native record writes", false)
cfg.native_selector_confidence = native_records_menu:slider("Native selector confidence threshold", 50, 90, 60)
tooltip(cfg.native_selector_confidence, "Legacy saved value only; admission threshold is automatic per movement state and current evidence.")
cfg.native_selector_trace = native_records_menu:switch("Native Selector Trace (experimental)", false)
cfg.native_selector_bridge = native_records_menu:switch("Native Shot Selector Bridge (experimental)", false)
tooltip(cfg.native_selector_bridge, "Requires Trace + Adaptive record writes + Resolver/Yaw Adaptive. Defaults OFF. For context_path_a only, forwards that exact record's earlier approved variant1/2; approved decisions may survive field8C restoration until capture_tick+32 native ticks. Exact pointer/index/capture/simulation/epoch matching and machine approval-token logging. Unknown or expired historical records pass through. No current yaw applied to old records. Native record-validity checks unchanged. Adaptive forwards the variant; FFI can substitute an approved private matrix buffer. Native aimpoint consistency and server hitboxes remain unverified.")
tooltip(cfg.native_selector_trace, "FFI production hooks only two shot-context CALL sites; full diagnostics hooks five pinned sites using a native-only wrapper; observes arguments/result; the separate Shot Selector Bridge may override copied arg1. Samples default field8C==0 scan traffic 1/32; retains nonzero selector scans and parsed shot context separately. Logs returned bank and owned-record matches; correlates nearby calls with aim_fire without claiming exact shot-record selection. Defaults OFF. CALL operands restored on disable/unload; 36KiB of trace allocations plus immutable own-matrix snapshots retained until process exit for in-flight calls.")
tooltip(cfg.native_record_write, "Experimental deferred existing-record selector +8C. Requests queue in net_update_end/menu callbacks and execute in render after network processing; changed SDK samples are discarded. Adaptive + Resolver + Yaw required; defaults OFF. Chooses native alternative closest to Anemone yaw; only initialized banks, configured confidence threshold (default 0.60), error <=15 degrees. Restores owned selector on disable/expiry. A readback does NOT prove RageBot shot consumption. Adaptive uses existing banks; FFI uses private transformed banks without +8C writes. SDK yaw writes are withheld while native application is requested.")
for _,ref in ipairs({cfg.native_code_patches,cfg.native_patch_extrap,cfg.native_patch_hitscan,cfg.native_patch_lerp,cfg.native_record_write,cfg.native_selector_trace,cfg.native_selector_bridge,cfg.native_selector_confidence})do
  pcall(function()ref:visibility(false)end)
end
cfg.resolver = rb:switch(cfg.version_state.resolver_label, false)
local resolver_menu = cfg.resolver:create()
cfg.assist = resolver_menu:switch(label(icon({ "life-ring", "handshake-angle", "user-shield" }), "Assist"), false)
tooltip(cfg.assist, "Assist Resolver never writes enemy yaw. It observes resolver geometry and requests native Safe Points Prefer/Force only for fresh, exact risk signals. In FFI mode Assist can coexist with Yaw; it changes Safe Points only, not the selected yaw. Beta/Adaptive retain Assist-only exclusivity.")
cfg.yaw = resolver_menu:switch(label(icon({ "rotate", "arrows-rotate", "compass" }), "Yaw Resolver"), false)
cfg.yaw_mode = resolver_menu:combo("Resolver Mode", { "Beta", "Adaptive", "FFI" })
cfg.adaptive_head = resolver_menu:switch("Adaptive Head Geometry", true)
 pcall(function () cfg.adaptive_head:disabled(true); cfg.adaptive_head:visibility(false) end)
tooltip(cfg.adaptive_head, "Uses several exposed CS:GO head/neck hitbox samples as a low-weight geometry signal. It is not a hidden anti-aim resolver and never writes hitboxes or memory.")
cfg.high_ground_damage = nil
  tooltip(cfg.yaw_mode, "Beta: SDK application. Adaptive: adaptive candidates with optional Native Records helper. FFI: adaptive candidate model with native-only application; exact record/initialized matrix banks required. No SDK fallback when FFI is unavailable.")
pcall(function ()
  local stored = cfg.yaw_mode:get()
  local normalized = cfg.version_state.normalize_mode(stored)
  if normalized then
    cfg.yaw_mode:set(normalized)
  end
end)
cfg.version_state.sync_mode_items()
tooltip(cfg.yaw, "Beta applies SDK yaw. Adaptive uses native application when Native Records helper is ON. FFI is native-only with no SDK fallback. Hitscan/lerp patches follow Resolver master automatically. Native Override Resolver still makes this resolver yield.")
cfg.assist:set_callback(function ()
  if get_bool(cfg.assist)then
    pcall(function()
      if yaw_mode()~="FFI"then cfg.yaw:set(false)end
    end)
    Y.enabled = false
    Y:guard(Y.update)
  else
    pcall(function ()
      if N then
        N:request("safe", nil)
      end
    end)
  end
end)
cfg.yaw:set_callback(function ()
  if get_bool(cfg.assist)and get_bool(cfg.yaw)and yaw_mode()~="FFI"then
    pcall(function ()
      cfg.yaw:set(false)
    end)
    return
  end
  if get_bool(cfg.yaw) then
    Y.fault = nil
    Y:guard(Y.update)
  else
    Y:reset("user toggle")
  end
end)
cfg.yaw_mode:set_callback(function()
  if get_bool(cfg.assist)and yaw_mode()~="FFI"then cfg.yaw:set(false)end
  if Y.native_policy then Y.native_policy:sync()end
  if Y.ffi_feedback then Y.ffi_feedback:reset()end
  for _,L in pairs(Y.learn)do L.native_candidate=nil;L.native_candidates=nil;L.__stable_yaw=nil;L.__sample_generation=nil;L.__sample_revision=nil end
end)
tooltip(cfg.resolver, "Master for Beta/Adaptive/FFI and Assist. Automatically applies the verified hitscan/lerp code patches in every mode, restores owned code on disable. Assist can coexist with FFI Yaw; Beta/Adaptive remain exclusive. Native Records helper is in Adaptive Helpers.")
cfg.forceshot = rb:switch(label(icon({ "crosshairs", "fire", "bolt" }), "ForceShot"), false)
tooltip(cfg.forceshot, "ForceShot helper: prepares an adaptive HC request before native attack only after a complete 64/64 current-head damage/spread estimate. Sampler is not native HC and never changes the native aim point. Real weapon spread only, bounded work. AirStop remains separate; no forced IN_ATTACK.")
do
  local fs_menu = cfg.forceshot:create()
  cfg.air_stop = fs_menu:switch("AirStop", false)
  cfg.air_stop_hold = fs_menu:hotkey("AirStop Hold", 0)
  tooltip(cfg.air_stop, "Auto: two current damage/spread checks plus ready weapon; bounded six-tick counter-brake. Manual Hold bypasses shot-readiness/target/HC gates. Requests native full stop, writes opposite movement input, and disables native Air Strafe when its slot is available. Vertical motion/gravity stay unchanged.")
  tooltip(cfg.air_stop_hold, "Assign a key and select Hold in the keybind editor. ForceShot + AirStop must be enabled. Manual Hold counter-brakes horizontally in the air even with movement keys pressed and without a target or ready weapon. Applied after this script movement helpers. No gravity/vertical-velocity freeze; release restores owned native Air Strafe override.")
end
cfg.version_state.extrapolation_label = label(icon({ "forward", "angles-right", "chart-line" }), "Extrapolation")
cfg.extrapolation = rb:switch(cfg.version_state.extrapolation_label, false)
local extrapolation_menu = cfg.extrapolation:create()
cfg.native_patch_ticks = extrapolation_menu:slider("Native tick limit", 1, 5, 3)
tooltip(cfg.native_patch_ticks, "Verified CS:GO native extrapolation cmp limit. Applied with Extrapolation ON; independently owned/restored. Separate from the portable prediction horizon below.")
cfg.interpolation = extrapolation_menu:switch("Interpolation (built-in)", true)
pcall(function ()
  cfg.interpolation:set(true)
end)
pcall(function ()
  cfg.interpolation:disabled(true)
end)
pcall(function ()
  cfg.interpolation:visibility(false)
end)
local set_menu_section
function cfg.version_state.apply_ui()
  pcall(function ()
    cfg.version_beta:set(true)
    cfg.version_beta:disabled(true)
    cfg.version_ultimate:set(false)
    cfg.version_plus:set(false)
    cfg.version_ultimate:disabled(true)
    cfg.version_plus:disabled(true)
    cfg.yaw_mode:update({ "Beta", "Adaptive", "FFI" })
  end)
end
cfg.extrapolation_ticks = extrapolation_menu:slider("Ticks", 0, 15, 0, 1, function (v)
  return v == 0 and "Off" or (v .. "t")
end)
cfg.extrapolation_auto = extrapolation_menu:switch("Auto from ping", true)
cfg.extrapolation_fake_latency = extrapolation_menu:switch("Include Fake Latency", true)
tooltip(cfg.extrapolation_ticks, "0 disables the feature. 1..15 aims that many ticks ahead. CS2 formula: 1 tick per 15ms of ping. 0-15 ping = 1t, 16-30 = 2t, 31-45 = 3t and so on, capped at 15t.\n\nCS:GO build: Neverlose has no native Extrapolation switch there (it is CS2-only), so this sets the portable movement-simulation horizon used for record validation and native safety requests. Auto from ping still retunes it.\n\nCS2 build: when the native Extrapolation switch is found it is driven directly at this value.\n\nAuto from ping sets the value for you every second from your live ping. Include Fake Latency adds the native Fake Latency value to your ping before the formula.")
tooltip(cfg.extrapolation_auto, "Every second, sets Ticks = clamp(round((ping + fake_latency) / 15), 0, 15). Turn off to set the slider manually.")
tooltip(cfg.extrapolation_fake_latency, "Adds the value of the native Fake Latency switch (Miscellaneous > Main > Other > Fake Latency) to your ping when Auto from ping is on.")
cfg.unsafe_recharge = rb:switch(label(icon({ "bolt", "battery-bolt", "gauge-high" }), "Unsafe Charge"), false)
cfg.movement = rb:switch(label(icon({ "person-running", "shoe-prints", "arrows-up-down-left-right" }), "Movement"), false)
local movement_menu = cfg.movement:create()
cfg.fast_ladder = movement_menu:switch("Fast Ladder", false)
cfg.no_fall_damage = movement_menu:switch("No Fall Damage", false)
cfg.avoid_collision = movement_menu:switch("Avoid Collision", false)
cfg.jump_scout = rb:switch(label(icon({ "person-ski-jumping", "crosshairs" }), "JumpScout"), false)
local movement_tick = function ()
end
local rb_functions = ui.create(cfg.main_tab, "\226\128\142\226\128\140", 2)
cfg.clantag = rb_functions:switch(label(icon({ "tag", "signature" }), "ClanTag"), false)
tooltip(cfg.clantag, "All editions share the same anemone frames indexed by Unix seconds; enabling time does not restart the animation. Client clocks must agree. No second clan-tag changer.")
cfg.trash = rb_functions:switch(label(icon({ "comments", "comment-dots" }), "TrashTalk"), false)
tooltip(cfg.trash, "Version-aware TrashTalk. Beta uses ZXC, Plus uses short English lines, and Ultimate uses separate Hellsing-inspired kill/death lines.")
do
  local m = cfg.trash:create()
  cfg.trash_mode = m:combo("Mode", { "ZXC" })
  pcall(function () cfg.trash_mode:set("ZXC") end)
  cfg.trash_trigger = m:selectable("Trigger", {
    label(icon({ "skull-crossbones", "skull" }), "On Kill"),
    label(icon({ "heart-crack", "heart" }), "On Death")
  })
  pcall(function ()
    cfg.trash_trigger:set({
      label(icon({ "skull-crossbones", "skull" }), "On Kill"),
      label(icon({ "heart-crack", "heart" }), "On Death")
    })
  end)
end
cfg.fps_optimizer = rb_functions:switch(label(icon({ "gauge-high", "bolt" }), "FPS Optimizer"), false)
do
  local m = cfg.fps_optimizer:create()
  cfg.opt_preset = m:combo("Preset", { "Recommended", "Maximum FPS" })
  pcall(function () cfg.opt_preset:set("Recommended") end)
  cfg.opt_list = m:selectable("Optimization", { "Decals", "Blood and gibs", "Tracers", "Breakable debris", "3D sky", "Ropes", "Foot shadows", "Multithreaded rendering", "Ragdoll physics", "Eye animation", "Detail sway", "Joystick", "Dynamic lights", "Lower sound quality" })
end
tooltip(cfg.fps_optimizer, "Verified cvar optimization adapted from juicy. Recommended: cosmetic/physics reductions. Maximum FPS also requests mat_queue_mode 2, sky/decals/ropes/dynamic lights. Sound quality is optional. No brush-model removal. Prior values restore on disable/unload; external changes preserved.")
local vis = ui.create(cfg.main_tab, "‐", 1)
cfg.aspect = vis:switch(label(icon({ "expand", "arrows-left-right", "desktop" }), "Aspect Ratio"), false)
local aspect_menu = cfg.aspect:create()
cfg.aspect_value = aspect_menu:slider("Aspect Value", 0, 200, 100, 0.01)
cfg.presets = aspect_menu:selectable("Presets", { "4:3", "3:2", "16:10", "5:4", "16:9" })
tooltip(cfg.aspect_value, "0 = native screen ratio. Deselect Presets to use the slider.")
tooltip(cfg.presets, "The first selected preset wins. Deselect all for the slider.")
cfg.crosshair_indicator = vis:switch(label(icon({ "crosshairs", "bullseye", "location-crosshairs" }), "Crosshair Indicator"), false)
local crosshair_indicator_menu = cfg.crosshair_indicator:create()
cfg.crosshair_indicator_color = crosshair_indicator_menu:color_picker("Indicator Color", color(185, 190, 255, 255))
cfg.crosshair_indicator_shadow = crosshair_indicator_menu:switch("Shadow Effect", false)
cfg.damage_indicator = vis:switch(label(icon({ "hundred-points", "crosshairs", "burst" }), "Damage Indicator"), false)
local damage_indicator_menu = cfg.damage_indicator:create()
cfg.damage_indicator_color = damage_indicator_menu:color_picker("Color", color(255, 255, 255, 255))
cfg.damage_indicator_font = damage_indicator_menu:combo("Font", { "Default", "Pixel", "Bold", "Museo Sans" })
pcall(function () cfg.damage_indicator_font:set("Pixel") end)
tooltip(cfg.crosshair_indicator, "Exscord-style centered indicator adapted for Anemone. Displays ANEMONE BETA, movement state and active combat features.")
tooltip(cfg.damage_indicator, "Exscord Damage Indicator. Shows current native minimum damage; drag it while the menu is open and right-click it to reset position.")
cfg.scope_overlay = vis:switch(label(icon({ "shuffle", "crosshairs", "expand" }), "Scope Overlay"), false)
do
  local m = cfg.scope_overlay:create()
  cfg.scope_overlay_options = m:selectable("Options", { "Inverted" })
  cfg.scope_overlay_length = m:slider("Length", 10, 300, 220)
  cfg.scope_overlay_gap = m:slider("Gap", 1, 300, 12)
  cfg.scope_overlay_main = m:color_picker("Main Accent", color(255, 255, 255, 255))
  cfg.scope_overlay_edge = m:color_picker("Edge Accent", color(0, 0, 0, 50))
end
tooltip(cfg.scope_overlay, "Scope Overlay ported 1:1 from Billionars. It removes the native scope lines and draws four animated gradients.")
cfg.side_indicators = vis:switch(label(icon({ "object-intersect", "bars-staggered", "list" }), "Side Indicators"), false)
do
  local m = cfg.side_indicators:create()
  cfg.side_indicators_type = m:combo("Side Indicator Type", { "GS", "Emberlash" })
  cfg.side_indicators_accent = m:color_picker("Side Indicators Accent", color(159, 166, 205, 255))
  cfg.side_indicators_background = m:color_picker("Side Indicators Background", color(0, 0, 0, 100))
  cfg.side_indicators_line = m:switch("Side Indicators Line", true)
  cfg.side_indicators_items = m:selectable("Indicators", {
    "Double Tap", "Min Damage", "Hit Chance", "Force Body", "HideShots", "Bomb",
    "Freestanding", "Force Safe Points", "Fake Duck", "Exploit Backtrack", "Dormant Aimbot"
  })
  pcall(function ()
    cfg.side_indicators_type:set("Emberlash")
    cfg.side_indicators_line:set(true)
    cfg.side_indicators_items:set({ "Double Tap", "Min Damage", "Hit Chance", "Force Body", "HideShots", "Bomb", "Freestanding", "Force Safe Points", "Fake Duck", "Exploit Backtrack", "Dormant Aimbot" })
  end)
end
tooltip(cfg.side_indicators, "Side Indicators ported from Emberlash: Old and Emberlash layouts.")
cfg.kill_particles = vis:switch(label(icon({ "sparkles", "star", "wand-magic-sparkles" }), "Kill Particles"), false)
local kill_particle_menu = cfg.kill_particles:create()
cfg.kill_particle_color = kill_particle_menu:color_picker("Color", color(235, 245, 255, 255))
cfg.kill_particle_amount = kill_particle_menu:slider("Particle Amount", 6, 80, 18, 1)
cfg.kill_particle_duration = kill_particle_menu:slider("Duration", 1, 4, 2, 0.1)
tooltip(cfg.kill_particles, "Creates round glowing particles over an enemy model after your kill. Ported from PrioraClub and distance-optimized for Neverlose CS:GO.")
cfg.hit_effect = vis:switch(label(icon({ "burst", "sparkles", "wand-magic-sparkles" }), "Hit Effect"), false)
local hit_effect_menu = cfg.hit_effect:create()
cfg.fortnite_hit = hit_effect_menu:switch("Fortnite Hit", false)
cfg.effects = hit_effect_menu:switch("Effects", false)
cfg.effects_mode = hit_effect_menu:combo("Mode", { "CSGO", "CS2" })
pcall(function () cfg.effects_mode:set("CSGO") end)
tooltip(cfg.hit_effect, "Hit feedback adapted from Fortnite Damage, Spark Impact and ParticleCS2. CSGO uses engine sparks; CS2 uses a rendered particle burst.")
do
  local model_paths = _G.__ANEMONE_MODEL_PATHS
  if type(model_paths) ~= "table" then model_paths = { }; _G.__ANEMONE_MODEL_PATHS = model_paths end
  local ffi_ok, scan_ffi = pcall(require, "ffi")
  local scan_ready, kernel32 = false, nil
  local function init_scanner()
    if scan_ready then return true end
    if not ffi_ok or not scan_ffi then return false end
    pcall(scan_ffi.cdef, [[
      typedef unsigned long anemone_DWORD;
      typedef int anemone_BOOL;
      typedef void* anemone_HANDLE;
      typedef struct { anemone_DWORD dwLowDateTime; anemone_DWORD dwHighDateTime; } anemone_FILETIME;
      typedef struct _WIN32_FIND_DATAA {
        anemone_DWORD dwFileAttributes;
        anemone_FILETIME ftCreationTime;
        anemone_FILETIME ftLastAccessTime;
        anemone_FILETIME ftLastWriteTime;
        anemone_DWORD nFileSizeHigh;
        anemone_DWORD nFileSizeLow;
        anemone_DWORD dwReserved0;
        anemone_DWORD dwReserved1;
        char cFileName[260];
        char cAlternateFileName[14];
      } anemone_WIN32_FIND_DATAA;
      anemone_HANDLE FindFirstFileA(const char*, anemone_WIN32_FIND_DATAA*);
      anemone_BOOL FindNextFileA(anemone_HANDLE, anemone_WIN32_FIND_DATAA*);
      anemone_BOOL FindClose(anemone_HANDLE);
    ]])
    local ok, lib = pcall(scan_ffi.load, "kernel32")
    if not ok or not lib then return false end
    kernel32, scan_ready = lib, true
    return true
  end
  local function clean_dir(path)
    return tostring(path or ""):gsub("/", "\\"):gsub("\\+$", "")
  end
  local function scan_root(root, out, seen, depth)
    if depth > 16 or #out >= 2048 then return end
    local data = scan_ffi.new("struct _WIN32_FIND_DATAA[1]")
    local handle = kernel32.FindFirstFileA(root .. "\\*", data)
    local invalid = scan_ffi.cast("void*", -1)
    if handle == nil or handle == invalid then return end
    repeat
      local name = scan_ffi.string(data[0].cFileName)
      if name ~= "." and name ~= ".." then
        local attrs = tonumber(data[0].dwFileAttributes) or 0
        local is_dir = bit.band(attrs, 0x10) ~= 0
        local is_reparse = bit.band(attrs, 0x400) ~= 0
        local full = root .. "\\" .. name
        if is_dir and not is_reparse then
          scan_root(full, out, seen, depth + 1)
        elseif name:lower():sub(-4) == ".mdl" then
          local normalized = full:gsub("\\", "/")
          local lower = normalized:lower()
          local marker = "/models/player/custom_player/"
          local at = lower:find(marker, 1, true)
          if at then
            local relative = normalized:sub(at + #marker)
            local game_path = "models/player/custom_player/" .. relative
            local display = relative:gsub("%.mdl$", "")
            if not seen[game_path:lower()] then
              seen[game_path:lower()] = true
              out[#out + 1] = { name = display, path = game_path }
            end
          end
        end
      end
    until kernel32.FindNextFileA(handle, data) == 0 or #out >= 2048
    kernel32.FindClose(handle)
  end
  local function discover_models()
    local found, seen = { }, { }
    if not init_scanner() then return found end
    local game_dir = ""
    pcall(function () game_dir = clean_dir(common.get_game_directory()) end)
    local roots = { }
    if game_dir ~= "" then
      roots[#roots+1] = game_dir .. "\\models\\player\\custom_player"
      roots[#roots+1] = game_dir .. "\\csgo\\models\\player\\custom_player"
    end
    local root_seen = { }
    for _, root in ipairs(roots) do
      local key = root:lower()
      if not root_seen[key] then root_seen[key] = true; scan_root(root, found, seen, 0) end
    end
    table.sort(found, function(a,b) return a.name:lower() < b.name:lower() end)
    return found
  end
  local function update_combo(item, options)
    local ok = pcall(function () item:update(options) end)
    if not ok then pcall(function () item:update((unpack or table.unpack)(options)) end) end
  end
  local initial = discover_models()
  for k in pairs(model_paths) do model_paths[k] = nil end
  local initial_names = { }
  for _, entry in ipairs(initial) do initial_names[#initial_names+1]=entry.name; model_paths[entry.name]=entry.path end
  cfg.model_changer_available = #initial_names > 0
  local initial_options = #initial_names > 0 and initial_names or { "No installed models" }
  cfg.model_changer = vis:switch(label(icon({ "person", "shirt", "user-gear" }), "Model Changer"), false)
  local m = cfg.model_changer:create()
  cfg.model_changer_team = m:selectable("Team", { "CT", "T" })
  cfg.model_changer_ct = m:combo("CT Model", initial_options)
  cfg.model_changer_t = m:combo("T Model", initial_options)
  cfg.model_changer_status = m:label(#initial_names > 0 and ("Installed models: "..tostring(#initial_names)) or "No custom models found")
  local function refresh_models(notify)
    local old_ct, old_t
    pcall(function () old_ct=cfg.model_changer_ct:get(); old_t=cfg.model_changer_t:get() end)
    local found = discover_models()
    for k in pairs(model_paths) do model_paths[k] = nil end
    local names, exists = { }, { }
    for _, entry in ipairs(found) do
      names[#names+1]=entry.name; exists[entry.name]=true; model_paths[entry.name]=entry.path
    end
    local available = #names > 0
    cfg.model_changer_available = available
    local options = available and names or { "No installed models" }
    update_combo(cfg.model_changer_ct, options)
    update_combo(cfg.model_changer_t, options)
    if available then
      pcall(function () cfg.model_changer_ct:set(exists[old_ct] and old_ct or names[1]) end)
      pcall(function () cfg.model_changer_t:set(exists[old_t] and old_t or names[1]) end)
    else
      pcall(function () cfg.model_changer:set(false) end)
    end
    pcall(function () cfg.model_changer:disabled(not available) end)
    pcall(function () cfg.model_changer_status:name(available and ("Installed models: "..tostring(#names)) or "No custom models found") end)
    _G.__ANEMONE_MODEL_REFRESH_TOKEN = (tonumber(_G.__ANEMONE_MODEL_REFRESH_TOKEN) or 0) + 1
    if notify then
      local msg = available and ("Model list refreshed: "..tostring(#names).." found") or "No custom models found"
      pcall(common.add_notify, "Anemone", msg)
      console_line("[Anemone] "..msg)
    end
  end
  cfg.model_changer_refresh = m:button("Refresh Models", function () refresh_models(true) end)
  if #initial_names > 0 then
    pcall(function () cfg.model_changer_ct:set(initial_names[1]); cfg.model_changer_t:set(initial_names[1]) end)
  else
    pcall(function () cfg.model_changer:set(false); cfg.model_changer:disabled(true) end)
  end
end
tooltip(cfg.model_changer, "Recursively scans models/player/custom_player. Add .mdl files, then press Refresh Models; no hardcoded model catalog is used.")
cfg.watermark = funcs:switch(label(icon({ "droplet", "stamp", "copyright" }), "Watermark"), false)
local watermark_menu = cfg.watermark:create()
cfg.wm_style = watermark_menu:combo("Style", { "Gamesense", "Neverlose", "Evalate" })
cfg.wm_elements = watermark_menu:selectable("Elements", { "Logo", "FPS", "Frametime variance", "Ping", "Speed", "K/D ratio", "Clock" })
cfg.wm_nl_elements = watermark_menu:selectable("NL Elements", { "Avatar", "Username", "Clock", "FPS", "Ping", "Var", "Loss", "Build", "Blur" })
cfg.wm_position = watermark_menu:combo("Position", { "Top-right", "Top-left", "Bottom-center" })
cfg.wm_accent = watermark_menu:color_picker("Accent", color(159, 202, 43, 255))
cfg.wm_nl_accent = watermark_menu:color_picker("NL Accent", color(185, 190, 255, 255))
cfg.wm_eval_elements = watermark_menu:selectable("Evalate Elements", { "Version", "Username", "Latency", "Frames", "Time" })
cfg.wm_eval_accent = watermark_menu:color_picker("Evalate Accent", color(185, 190, 255, 255))
cfg.wm_eval_username_source = watermark_menu:combo("Evalate Username source", { "Cheat", "Steam", "Custom" })
do
  local ok, ref = pcall(function ()
    return watermark_menu:input("Evalate Custom username")
  end)
  cfg.wm_eval_username_custom = ok and ref or nil
end
cfg.wm_eval_time_format = watermark_menu:combo("Evalate Time format", { "24h", "12h" })
pcall(function ()
  cfg.wm_eval_elements:set({ "Version", "Username", "Latency", "Frames", "Time" })
end)
pcall(function ()
  cfg.wm_eval_username_source:set("Cheat")
end)
pcall(function ()
  cfg.wm_eval_time_format:set("24h")
end)
tooltip(cfg.watermark, "Watermark styles ported 1:1 from PrioraClub: Gamesense (gradient shadow bar with colored metrics) and Neverlose (rounded pill with avatar, icons, animated blocks, optional blur).")
pcall(function ()
  cfg.wm_elements:set({ "Logo", "FPS", "Frametime variance", "Ping" })
end)
pcall(function ()
  cfg.wm_nl_elements:set({ "Avatar", "Username", "Clock", "FPS", "Ping", "Build" })
end)
local function wm_eval_elem_enabled(name)
  local ok, sel = pcall(function ()
    return cfg.wm_eval_elements:get()
  end)
  if not ok or type(sel) ~= "table" then
    return false
  end
  for _, v in ipairs(sel) do
    if v == name then
      return true
    end
  end
  return sel[name] == true
end
local WM_STYLES = { "Gamesense", "Neverlose", "Evalate" }
local function wm_read_style()
  local ok, v = pcall(function ()
    return cfg.wm_style:get()
  end)
  if ok then
    if type(v) == "string" then
      return v
    end
    if type(v) == "number" then
      return WM_STYLES[v] or WM_STYLES[v + 1] or "Gamesense"
    end
  end
  return "Gamesense"
end
local function wm_eval_accent_color()
  local ok, c = pcall(function ()
    return cfg.wm_eval_accent:get()
  end)
  if ok and c and number(c.r) and number(c.g) and number(c.b) then
    return c
  end
  return color(185, 190, 255, 255)
end
local function wm_style_visibility()
  local style = wm_read_style()
  local gs_like = style == "Gamesense"
  pcall(function ()
    cfg.wm_elements:visibility(gs_like)
  end)
  pcall(function ()
    cfg.wm_accent:visibility(gs_like)
  end)
  pcall(function ()
    cfg.wm_nl_elements:visibility(style == "Neverlose")
  end)
  pcall(function ()
    cfg.wm_nl_accent:visibility(style == "Neverlose")
  end)
  local ev = style == "Evalate"
  pcall(function ()
    cfg.wm_eval_elements:visibility(ev)
  end)
  pcall(function ()
    cfg.wm_eval_accent:visibility(ev)
  end)
  pcall(function ()
    cfg.wm_eval_username_source:visibility(ev and wm_eval_elem_enabled("Username"))
  end)
  pcall(function ()
    cfg.wm_eval_time_format:visibility(ev and wm_eval_elem_enabled("Time"))
  end)
  local custom = false
  pcall(function ()
    custom = cfg.wm_eval_username_source:get() == "Custom"
  end)
  pcall(function ()
    if cfg.wm_eval_username_custom then
      cfg.wm_eval_username_custom:visibility(ev and wm_eval_elem_enabled("Username") and custom)
    end
  end)
end
pcall(function ()
  cfg.wm_style:set_callback(wm_style_visibility)
end)
wm_style_visibility()
cfg.hotkeys = funcs:switch(label(icon({ "brackets-curly", "keyboard" }), "HotKeys"), false)
do
  local m = cfg.hotkeys:create()
  cfg.hotkeys_style = m:combo("Style", { "Evalate", "Emberlash" })
  cfg.hotkeys_anemone_accent = m:color_picker("Accent Color", color(159, 166, 205, 255))
  cfg.hotkeys_anemone_background = m:color_picker("Background Color", color(0, 0, 0, 100))
  pcall(function () cfg.hotkeys_style:set("Evalate") end)
end
cfg.spectators = funcs:switch(label(icon({ "users", "eye", "binoculars" }), "Spectators"), false)
local spec_menu = cfg.spectators:create()
cfg.specs_header = spec_menu:switch("Header", false)
tooltip(cfg.spectators, "Spectator list ported 1:1 from PrioraClub: rounded rows, round avatars, accent corner, slide animations. Header toggle moves it to a fixed right-side panel.")
cfg.notifications = funcs:switch(label(icon({ "bell", "message", "circle-info" }), "Notification"), false)
local notification_menu = cfg.notifications:create()
cfg.notification_debug = notification_menu:switch("Debug", false)
cfg.notification_screen = notification_menu:switch("Screen", false)
cfg.notification_console = notification_menu:switch("Console", false)
tooltip(cfg.notifications, "Anemone Notification port: screen cards, debug output and console output for shots, deaths and utility damage.")
cfg.report = section:button("Report / Diagnostics", function ()
end)
cfg.export_report = section:button("Export Report", function ()
end)
cfg.export_logs = section:button("Export Logs", function ()
  local text = Y:build_miss_log_text()
  local clip_ok, clip_err = pcall(function ()
    local clipboard = require("neverlose/clipboard")
    assert(clipboard and type(clipboard.set) == "function", "clipboard module unavailable")
    clipboard.set(text)
  end)
  local written, write_err = { }, nil
  local home = os and os.getenv and (os.getenv("USERPROFILE") or os.getenv("HOME")) or nil
  local dir = home and (home .. "\\OneDrive\\Desktop") or nil
  local names = {
    string.char(236, 232, 241, 241, 251) .. ".txt",
    "anemone_miss_logs.txt",
  }
  if dir then
    for _, name in ipairs(names) do
      local ok_w, err_w = pcall(function ()
        local f = assert(io.open(dir .. "\\" .. name, "wb"))
        f:write(text, "\r\n")
        f:close()
      end)
      if ok_w then written[#written+1] = dir .. "\\" .. name
      else write_err = write_err or err_w end
    end
  end
  if #written > 0 then
    pcall(common.add_notify, "Anemone", "Miss Logs exported to " .. #written .. " file(s)")
    for _, path in ipairs(written) do
      console_line("[Anemone] Export Logs: wrote " .. tostring(#Y.miss_log) .. " stored misses -> " .. path)
    end
    if clip_ok then
      console_line("[Anemone] Export Logs: also copied to clipboard.")
    end
  elseif clip_ok then
    pcall(common.add_notify, "Anemone", "All stored Miss Logs copied to clipboard")
    console_line("[Anemone] Export Logs: copied " .. tostring(#Y.miss_log) .. " stored misses to clipboard (disk write unavailable).")
  else
    warn_once("export_logs", "Export Logs failed: " .. tostring(clip_err) .. " | disk: " .. tostring(write_err))
  end
end)
tooltip(cfg.report, "Report / Diagnostics prints to the game console: Resolver master, native patch status/gate, session and movement/charge data. For ON/OFF comparison join a match, spawn alive, then print with Resolver enabled and disabled.")
tooltip(cfg.export_report, "Copies a fresh full report plus retained Native state coverage/history. History survives target death and live resets until script unload. BEGIN/END markers identify a complete report. Clipboard text is not shortened.")
tooltip(cfg.export_logs, "Writes every stored Miss Log entry to the Desktop as 'миссы.txt' (and anemone_miss_logs.txt), and copies it to the clipboard as a fallback.")
cfg.version_state.function_labels = {
  { cfg.clantag, label(icon({ "tag", "signature" }), "ClanTag"), true, true },
  { cfg.trash, label(icon({ "comments", "comment-dots" }), "TrashTalk"), true, true },
  { cfg.unsafe_recharge, label(icon({ "bolt", "battery-bolt", "gauge-high" }), "Unsafe Charge"), true, true },
  { cfg.forceshot, label(icon({ "crosshairs", "fire", "bolt" }), "ForceShot"), true, true },
  { cfg.crosshair_indicator, label(icon({ "crosshairs", "bullseye", "location-crosshairs" }), "Crosshair Indicator"), true, true },
  { cfg.scope_overlay, label(icon({ "shuffle", "crosshairs", "expand" }), "Scope Overlay"), true, true },
  { cfg.hotkeys, label(icon({ "brackets-curly", "keyboard" }), "HotKeys"), false, true },
  { cfg.side_indicators, label(icon({ "object-intersect", "bars-staggered", "list" }), "Side Indicators"), false, true }
}
local side_indicator_tick = (function ()
local asgard_gs_side_runtime = {
    bomb = {
        was_defused = false,
        was_bombed = false,
        defuse_time = 0,
        defuse_start = 0,
        is_defusing = false,
        plant_site = 0,
        plant_time = 3.2,
        plant_start = 0,
        planting = false
    }
};
local function asgard_gs_bind_active(v_name)
    local v_binds = ui.get_binds() or {};
    for _, v_bind in pairs(v_binds) do
        if v_bind.name == v_name and v_bind.active then
            return true, v_bind.value;
        end;
    end;
    return false, nil;
end;
local function asgard_gs_bomb_timer(v_bomb)
    if not v_bomb then
        return 0;
    end;
    local v_time = v_bomb.m_flC4Blow - globals.curtime;
    return v_time and math.max(v_time, 0) or 0;
end;
local function asgard_gs_bomb_site(v_site)
    local v_resource = entity.get_player_resource();
    if not v_resource then
        return "?";
    end;
    local v_a = v_resource.m_bombsiteCenterA;
    local v_b = v_resource.m_bombsiteCenterB;
    local v_ent = entity.get(v_site, false);
    if not v_ent or not v_a or not v_b then
        return "?";
    end;
    local v_center = (v_ent.m_vecMins + v_ent.m_vecMaxs) / 2;
    return v_a:dist(v_center) < v_b:dist(v_center) and "A" or "B";
end;
local function asgard_gs_bomb_damage(v_player, v_bomb)
    if not v_player or not v_bomb then
        return nil;
    end;
    local v_distance = v_player:get_origin():dist(v_bomb:get_origin());
    local v_armor = v_player.m_ArmorValue or 0;
    local v_value = (v_distance - 75.68) / 789.2;
    local v_damage = 450.7 * math.exp(-v_value * v_value);
    if v_armor > 0 then
        local v_new = v_damage * 0.5;
        if v_armor < (v_damage - v_new) * 0.5 then
            v_new = v_damage - v_armor * 2;
        end;
        v_damage = v_new;
    end;
    return v_damage;
end;
local asgard_gs_font = nil;
pcall(function()
    asgard_gs_font = render.load_font("Calibri Bold", vector(24.3, 23.5, 0), "da");
end);
local asgard_anemone_icon_defs = {
                    icons = {
                        HC = {
                            scale = 0.7,
                            svg = [[
<svg version="1.1" xmlns="http://www.w3.org/2000/svg" width="32px" height="32px" viewBox="0 0 32 32" xml:space="preserve">
    <path fill="#FFFFFF" d="M19.939,2.104c-2.592-0.738-5.217-0.703-7.647-0.059c-0.011,0.003-0.021,0.007-0.032,0.01
        c-0.438,0.117-0.867,0.254-1.289,0.411c-0.033,0.013-0.064,0.021-0.099,0.031c-0.056,0.022-0.108,0.047-0.165,0.067
        c-0.251,0.102-0.502,0.201-0.746,0.314C9.837,2.938,9.721,3,9.6,3.061c-0.506,0.25-0.996,0.524-1.468,0.834
        c-0.019,0.01-0.036,0.021-0.055,0.03C5.566,5.57,3.629,8.023,2.461,10.986c-0.885,2.246-0.873,4.306-0.873,4.306
        c-0.181,4.422,1.723,8.821,5.196,11.924l0.04-0.052c3.85,3.146,9.207,4.236,14.197,2.361c1.135-0.426,2.172-0.992,3.125-1.652
        c0.041-0.025,0.078-0.055,0.117-0.081c0.271-0.19,0.534-0.385,0.788-0.591c0.251-0.202,0.497-0.412,0.733-0.631
        c0.08-0.074,0.154-0.15,0.232-0.228c1.77-1.7,3.129-3.87,3.851-6.403C32.053,12.273,27.607,4.287,19.939,2.104z M22.154,17.327
        h5.154c-0.221,1.868-0.89,3.655-1.951,5.194c-0.084,0.117-0.168,0.232-0.256,0.347c-0.158,0.211-0.313,0.421-0.486,0.621
        c-0.281,0.321-0.576,0.632-0.891,0.918c-0.063,0.059-0.134,0.112-0.199,0.17c-0.338,0.295-0.688,0.575-1.057,0.828
        c-0.015,0.011-0.027,0.021-0.044,0.03c-1.276,0.865-2.722,1.472-4.249,1.771l0.008,0.027c-0.287,0.058-0.572,0.084-0.856,0.117
        v-5.105c0-0.732-0.595-1.327-1.327-1.327s-1.327,0.595-1.327,1.327v5.117c-2.34-0.271-4.552-1.242-6.315-2.807
        c-1.92-1.858-3.271-4.474-3.653-7.229H9.76c0.733,0,1.327-0.595,1.327-1.327s-0.594-1.327-1.327-1.327H4.645
        c0.047-0.478,0.123-0.952,0.236-1.422c0.986-3.433,3.496-6.596,6.977-7.929c0.035-0.014,0.072-0.027,0.106-0.042
        c0.896-0.332,1.804-0.53,2.709-0.634v5.246c0,0.733,0.595,1.327,1.327,1.327s1.327-0.594,1.327-1.327V4.655
        c4.098,0.501,7.784,3.198,9.337,7.331c0.332,0.886,0.543,1.787,0.648,2.687h-5.158c-0.732,0-1.326,0.595-1.326,1.327
        S21.422,17.327,22.154,17.327z"/>
</svg>
]],
                        },
                        MD = {
                            scale = 0.78,
                            load_w = 32,
                            load_h = 32,
                            x_offset = 0,
                            y_offset = 0,
                            svg = [[
<svg width="32" height="32" viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg">
    <path fill="#FFFFFF" fill-rule="evenodd" clip-rule="evenodd" d="M16 2.1C8.322 2.1 2.1 8.322 2.1 16S8.322 29.9 16 29.9S29.9 23.678 29.9 16S23.678 2.1 16 2.1ZM16 5.05C9.952 5.05 5.05 9.952 5.05 16S9.952 26.95 16 26.95S26.95 22.048 26.95 16S22.048 5.05 16 5.05Z"/>
    <path fill="#FFFFFF" d="M14.6 0.9H17.4V7.05H14.6V0.9Z"/>
    <path fill="#FFFFFF" d="M14.6 24.95H17.4V31.1H14.6V24.95Z"/>
    <path fill="#FFFFFF" d="M0.9 14.6H7.05V17.4H0.9V14.6Z"/>
    <path fill="#FFFFFF" d="M24.95 14.6H31.1V17.4H24.95V14.6Z"/>
    <g transform="translate(16 16) scale(0.52) translate(-16 -16)">
        <path fill="#FFFFFF" fill-rule="evenodd" clip-rule="evenodd" d="M28.443 16.63C28.463 14.896 27.853 14.857 27.814 13.794C27.793 13.261 27.858 11.769 27.814 10.329C27.769 8.89499 27.616 7.51299 27.499 7.17899C27.263 6.50899 26.995 5.40599 24.979 3.71499C22.773 1.86299 18.52 0.288995 16.159 0.249995C13.796 0.209995 11.04 1.39199 8.91301 2.76999C6.78701 4.14699 6.27501 4.73799 5.44901 5.91999C4.62101 7.101 4.30601 7.92699 4.50301 10.015C4.70001 12.101 4.74701 11.55 4.81801 13.48C4.87801 15.074 4.15301 15.568 4.18801 16.63C4.24001 18.216 4.83601 18.547 4.81801 19.15C4.80501 19.546 4.10901 20.043 4.18801 21.355C4.26801 22.691 4.54201 23.048 7.02301 24.505C8.63301 25.45 10.527 25.804 10.488 26.394C10.43 27.259 10.213 28.679 10.174 29.544C10.135 30.411 10.528 30.489 11.433 30.804C12.34 31.12 14.465 31.788 16.789 31.749C19.112 31.71 20.097 31.237 21.199 30.804C22.301 30.372 22.459 29.978 22.459 29.23C22.459 28.482 21.829 26.947 21.829 26.394C21.829 25.843 23.719 25.253 25.924 24.189C28.13 23.126 28.104 22.064 28.13 21.355C28.177 20.017 27.499 19.701 27.499 19.15C27.499 18.074 28.431 17.891 28.443 16.63ZM9.85801 19.875C8.75501 19.914 6.39301 19.914 6.39301 16.724C6.39301 12.304 8.75501 11.802 10.488 11.683C12.221 11.566 12.457 11.369 13.324 11.999C14.88 13.13 14.78 15.136 14.268 16.724C13.893 17.887 13.48 18.338 12.693 18.93C11.906 19.52 10.961 19.834 9.85801 19.875ZM17.104 24.914L16.67 23.307L16 23.313L15.528 24.915C13.716 24.423 12.988 23.694 13.008 22.71C13.028 21.726 13.579 20.702 14.582 19.876C15.587 19.048 15.749 18.921 16.473 18.931C17.164 18.941 17.225 19.074 17.733 19.56C18.83 20.611 19.54 21.312 19.624 22.71C19.706 24.086 18.107 24.855 17.104 24.914ZM22.773 19.875C21.67 19.834 20.726 19.52 19.938 18.93C19.151 18.338 18.686 17.903 18.363 16.724C17.956 15.24 17.753 13.13 19.31 12C20.176 11.369 20.412 11.566 22.145 11.684C23.876 11.803 26.24 12.305 26.24 16.725C26.239 19.914 23.876 19.914 22.773 19.875Z"/>
    </g>
</svg>
]],
                        },
                        DA = {
                            scale = 0.82,
                            load_w = 32,
                            load_h = 32,
                            x_offset = 0,
                            y_offset = 0,
                            svg = [[
<svg width="32" height="32" viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg">
    <path fill="#FFFFFF" fill-rule="evenodd" clip-rule="evenodd" d="M16 3.0C8.82 3.0 3.0 8.82 3.0 16S8.82 29.0 16 29.0S29.0 23.18 29.0 16S23.18 3.0 16 3.0ZM16 5.8C10.367 5.8 5.8 10.367 5.8 16S10.367 26.2 16 26.2S26.2 21.633 26.2 16S21.633 5.8 16 5.8Z"/>
    <path fill="#FFFFFF" d="M14.7 0.9H17.3V6.1H14.7V0.9Z"/>
    <path fill="#FFFFFF" d="M14.7 25.9H17.3V31.1H14.7V25.9Z"/>
    <path fill="#FFFFFF" d="M0.9 14.7H6.1V17.3H0.9V14.7Z"/>
    <path fill="#FFFFFF" d="M25.9 14.7H31.1V17.3H25.9V14.7Z"/>
    <path fill="#FFFFFF" fill-rule="evenodd" clip-rule="evenodd" d="M16 8.0C12.58 8.0 9.8 10.72 9.8 14.06C9.8 18.82 16 24.25 16 24.25S22.2 18.82 22.2 14.06C22.2 10.72 19.42 8.0 16 8.0ZM16 11.25C14.43 11.25 13.15 12.48 13.15 14.0C13.15 15.52 14.43 16.75 16 16.75C17.57 16.75 18.85 15.52 18.85 14.0C18.85 12.48 17.57 11.25 16 11.25Z"/>
</svg>
]],
                        },
                        SAFE = {
                            scale = 0.84,
                            load_w = 32,
                            load_h = 32,
                            x_offset = 0,
                            y_offset = 0,
                            svg = [[
<svg width="32" height="32" viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg">
    <path fill="none" d="M16 2.0L26.2 5.7V13.4C26.2 20.0 22.1 25.8 16 29.6C9.9 25.8 5.8 20.0 5.8 13.4V5.7L16 2.0Z" stroke="#FFFFFF" stroke-width="2.6" stroke-linejoin="round"/>
    <circle cx="16.0" cy="15.7" r="2.1" fill="#FFFFFF"/>
    <circle cx="12.2" cy="13.2" r="1.5" fill="#FFFFFF"/>
    <circle cx="19.8" cy="13.2" r="1.5" fill="#FFFFFF"/>
    <circle cx="13.1" cy="19.0" r="1.45" fill="#FFFFFF"/>
    <circle cx="18.9" cy="19.0" r="1.45" fill="#FFFFFF"/>
</svg>
]],
                        },
                        BODY = {
                            scale = 0.84,
                            load_w = 32,
                            load_h = 32,
                            x_offset = 0,
                            y_offset = 0,
                            svg = [[
<svg width="32" height="32" viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg">
    <circle cx="16" cy="5.4" r="3.2" fill="#FFFFFF"/>
    <path fill="none" d="M10.4 27.6V14.4C10.4 11.2 12.7 9.2 16 9.2C19.3 9.2 21.6 11.2 21.6 14.4V27.6" stroke="#FFFFFF" stroke-width="2.7" stroke-linecap="round" stroke-linejoin="round"/>
    <path fill="none" d="M10.1 13.7L7.5 17.1" stroke="#FFFFFF" stroke-width="2.8" stroke-linecap="round"/>
    <path fill="none" d="M21.9 13.7L24.5 17.1" stroke="#FFFFFF" stroke-width="2.8" stroke-linecap="round"/>
    <circle cx="16" cy="17.1" r="4.1" fill="none" stroke="#FFFFFF" stroke-width="2.4"/>
    <path fill="none" d="M16 12.0V15.0" stroke="#FFFFFF" stroke-width="2.0" stroke-linecap="round"/>
    <path fill="none" d="M16 19.2V22.2" stroke="#FFFFFF" stroke-width="2.0" stroke-linecap="round"/>
    <path fill="none" d="M10.9 17.1H13.9" stroke="#FFFFFF" stroke-width="2.0" stroke-linecap="round"/>
    <path fill="none" d="M18.1 17.1H21.1" stroke="#FFFFFF" stroke-width="2.0" stroke-linecap="round"/>
    <circle cx="16" cy="17.1" r="1.25" fill="#FFFFFF"/>
</svg>
]],
                        },
                        OSAA = {
                            scale = 0.9,
                            load_w = 32,
                            load_h = 32,
                            x_offset = 0,
                            y_offset = 0,
                            svg = [[
<svg width="32" height="32" viewBox="0 0 32 32" xmlns="http://www.w3.org/2000/svg">
    <path fill="#FFFFFF" fill-rule="evenodd" clip-rule="evenodd" d="M13.7 8.1C10.77 8.1 8.4 10.47 8.4 13.4C8.4 16.33 10.77 18.7 13.7 18.7C16.63 18.7 19.0 16.33 19.0 13.4C19.0 10.47 16.63 8.1 13.7 8.1ZM13.7 10.6C12.15 10.6 10.9 11.85 10.9 13.4C10.9 14.95 12.15 16.2 13.7 16.2C15.25 16.2 16.5 14.95 16.5 13.4C16.5 11.85 15.25 10.6 13.7 10.6Z"/>
    <path fill="#FFFFFF" d="M7.6 27.0C7.7 21.7 9.8 18.9 13.8 18.9C16.0 18.9 17.8 19.9 18.9 21.8L16.6 23.0C16.0 21.9 15.1 21.4 13.8 21.4C11.6 21.4 10.4 23.2 10.3 27.0H7.6Z"/>
    <path fill="#FFFFFF" d="M3.9 6.1H8.9V8.3H3.9V6.1ZM18.5 6.1H23.5V8.3H18.5V6.1ZM12.6 2.4H14.8V7.3H12.6V2.4ZM12.6 19.5H14.8V24.4H12.6V19.5Z"/>
    <path fill="#FFFFFF" d="M21.0 11.8L29.0 14.8L24.7 17.1L26.4 21.2L18.4 18.1L22.7 15.9L21.0 11.8Z"/>
    <path fill="#FFFFFF" d="M4.2 25.0L25.0 4.2L27.0 6.2L6.2 27.0L4.2 25.0Z"/>
</svg>
]],
                        },
                        DUCK = {
                            scale = 0.8,
                            load_w = 32,
                            load_h = 32,
                            x_offset = 0,
                            y_offset = 0,
                            svg = [[
<svg width="32" height="32" viewBox="0 0 32 32" xmlns="http://www.w3.org/2000/svg">
    <g transform="scale(0.05)">
        <path fill="#FFFFFF" d="M448 192C448 262.7 390.7 320 320 320C262.8 320 214.4 282.5 198 230.7C196.9 232 195.8 233.3 194.5 234.5C178.7 250.3 155.7 255.2 140.9 256.6C132.8 257.4 126.3 250.9 127.1 242.8C128.5 228.1 133.4 205 149.2 189.2C155 183.4 161.8 179.1 168.8 175.8C161.8 172.6 155 168.2 149.2 162.4C133.4 146.6 128.5 123.6 127.1 108.8C126.3 100.7 132.8 94.2 140.9 95C155.6 96.4 178.7 101.3 194.5 117.1C199.3 121.9 203.2 127.5 206.2 133.2C227.5 92 270.5 63.8 320 63.8C390.7 63.8 448 121.1 448 191.8Z M240 176C240 184.8 247.2 192 256 192L384 192C392.8 192 400 184.8 400 176C400 167.2 392.8 160 384 160L256 160C247.2 160 240 167.2 240 176Z M238.6 387L305.6 437.2C314.1 443.6 325.9 443.6 334.4 437.2L401.4 387C407.9 382.1 416.6 380.8 424 384.2C485.4 412.4 528.1 474.4 528.1 546.3C528.1 562.7 514.8 576 498.4 576L141.7 576C125.3 576 112 562.7 112 546.3C112 474.3 154.7 412.3 216.1 384.2C223.5 380.8 232.2 382.1 238.7 387Z"/>
    </g>
</svg>
]],
                        },
                        FS = {
                            scale = 0.8,
                            load_w = 32,
                            load_h = 32,
                            x_offset = 1,
                            y_offset = 0,
                            svg = [[
<svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" width="32px"
     height="32px" viewBox="0 0 32 32" enable-background="new 0 0 32 32" xml:space="preserve">
<symbol id="dude-transit" viewBox="0 -25.1 21.25 25.118">
    <path fill-rule="evenodd" clip-rule="evenodd" fill="#FFFFFF" d="M15.5-4.2l0.75-1.05l1-3.1l3.9-2.65v-0.05
        c0.067-0.1,0.1-0.233,0.1-0.4c0-0.2-0.05-0.383-0.15-0.55c-0.167-0.233-0.383-0.35-0.65-0.35l-4.3,1.8l-1.2,1.65l-1.5-3.95
        l2.25-5.05l-3.25-6.9c-0.267-0.2-0.633-0.3-1.1-0.3c-0.3,0-0.55,0.15-0.75,0.45c-0.1,0.133-0.15,0.25-0.15,0.35
        c0,0.067,0.017,0.15,0.05,0.25c0.033,0.1,0.067,0.184,0.1,0.25l2.55,5.6L10.7-14l-3.05-4.9L0.8-18.7
        c-0.367,0.033-0.6,0.184-0.7,0.45c-0.067,0.3-0.1,0.467-0.1,0.5c0,0.5,0.2,0.767,0.6,0.8l5.7,0.15l2.15,5.4l3.1,5.65L9.4-5.6
        c-1.367-2-2.1-3.033-2.2-3.1C7.1-8.8,6.95-8.85,6.75-8.85C6.35-8.85,6.1-8.667,6-8.3C5.9-8,5.9-7.8,6-7.7H5.95l2.5,4.4l3.7,0.3
        L14-3.5L15.5-4.2z M14.55-2.9c-0.333,0.4-0.45,0.85-0.35,1.35c0.033,0.5,0.25,0.9,0.65,1.2c0.4,0.3,0.85,0.417,1.35,0.35
        c0.5-0.067,0.9-0.3,1.2-0.7c0.333-0.4,0.467-0.85,0.4-1.35c-0.066-0.5-0.3-0.9-0.7-1.2c-0.4-0.333-0.85-0.45-1.35-0.35
        C15.25-3.533,14.85-3.3,14.55-2.9z"/>
</symbol>
<g id="Layer_2">
</g>
<g id="topo">
    <g id="Layer_1">
        <g>
                <rect x="28.437" y="10.648" fill="#FFFFFF" width="3.149" height="0.861"/>
                <rect x="27.524" y="8.531" transform="matrix(0.7026 -0.7116 0.7116 0.7026 2.1814 23.1408)" fill="#FFFFFF" width="2.5" height="0.859"/>
                <rect x="28.611" y="12.046" transform="matrix(0.7032 -0.711 0.711 0.7032 -0.8341 24.5945)" fill="#FFFFFF" width="0.86" height="2.501"/>
                <rect x="26.869" y="13.128" transform="matrix(0.9028 -0.43 0.43 0.9028 -3.3506 13.0957)" fill="#FFFFFF" width="0.86" height="1.667"/>
                <rect x="26.401" y="7.718" transform="matrix(0.5382 -0.8428 0.8428 0.5382 5.7095 26.7163)" fill="#FFFFFF" width="1.667" height="0.86"/>
                <path fill="#FFFFFF" d="M27.299,10.939l-2.667-1.046l-7.114,0.018c-0.267-0.822-1.557-2.424-1.92-2.813
                c-0.364-0.387-1.284-1.21-2.375-1.742c-1.09-0.534-2.592-0.97-4.044-1.065C7.727,4.196,6.467,4.484,5.571,4.798
                C4.674,5.113,3.368,5.839,2.325,7.001c-1.042,1.163-1.671,3.368-1.671,5.887c0,1.769,1.454,5.959,1.345,7.666l-0.292,2.761
                c-0.218,0.945-0.289,2.145-0.289,2.145c0.447,0.532,1.925,2.204,3.475,3.366c1.551,1.162,3.658,2.76,5.693,2.737
                c2.034-0.023,2.494-0.436,3.365-0.896c0.872-0.461,1.042-0.824,1.17-1.164c0.127-0.339-0.103-0.774-0.249-1.234
                c-0.144-0.461,0.024-0.872,0.249-1.042c0.223-0.169,0.574-0.533,0.914-0.823c0.339-0.292,0.702-1.042,0.896-1.599
                c0.193-0.558,0.557-2.108,0.774-2.642c0.218-0.532,0.823-1.912,0.993-2.398c0.17-0.484,0.146-1.622-0.072-2.249
                c-0.218-0.627-0.218-1.213-0.146-1.966c0.073-0.751,0.508-0.994,0.508-2.378c0-0.31-0.104-0.683-0.304-1.057l5.978-0.026
                L27.299,10.939z M8.491,13.291l-1.089,1.236l-1.332-0.97l-0.921,0.631l-0.582-1.696L3.89,12.445l0.073-1.066L2.34,10.893v-0.072
                l1.283-0.751L3.212,8.714h1.694l0.243-1.26l0.993,0.437L6.917,6.8l0.485,1.042L8.88,7.527l0.314,1.284l1.891,1.283l-0.944,1.066
                l0.944,0.993l-1.43,0.266l-0.12,1.188L8.491,13.291z M12.134,16.448c-0.724-0.062-1.574-0.509-1.84-0.896
                c-0.267-0.387-0.363-1.018,0-1.308c0.363-0.29,1.138-0.896,2.325-0.774c1.188,0.121,1.938,0.881,1.889,1.481
                c-0.048,0.601-0.461,0.988-0.896,1.183C13.175,16.326,12.422,16.473,12.134,16.448z M17.125,23.06c0,0-0.112,0.294-0.291,0.436
                c-0.483,0.388-0.558,0.437-0.848,0.461c-0.291,0.024-0.8,0-1.09,0s-0.727-0.218-1.065-0.389c-0.339-0.169-0.823-0.678-0.921-0.75
                c-0.097-0.073-0.351-0.416-0.169-0.557c0.287-0.224,0.727-0.606,1.066-0.679c0.338-0.073,0.762-0.193,1.313-0.193
                c0.552,0,1.35-0.049,1.641,0.096c0.291,0.146,0.581,0.484,0.581,0.655C17.342,22.311,17.125,23.06,17.125,23.06z M18.602,14.487
                c0.068,0.252-0.28,0.704-0.34,0.969c-0.097,0.436,0.024,0.703,0,0.992c-0.023,0.291-0.217,0.412-0.217,0.412
                s-0.218-0.097-0.534-0.218c-0.315-0.121-0.75-0.483-0.75-0.775c0-0.291,0.024-0.702,0.315-0.969c0.291-0.266,0.8-0.604,1.14-0.63
                C18.554,14.244,18.516,14.171,18.602,14.487z"/>
        </g>
    </g>
</g>
</svg>
]],
                        },
                        PING = {
                            scale = 0.7,
                            load_w = 32,
                            load_h = 32,
                            x_offset = 0,
                            y_offset = 0,
                            svg = [[
<svg version="1.1" xmlns="http://www.w3.org/2000/svg" width="32px" height="32px" viewBox="0 0 32 32" xml:space="preserve">
    <g>
        <circle fill="#FFFFFF" cx="9.466" cy="16.048" r="0.998"/>
        <circle fill="#FFFFFF" cx="21.332" cy="9.013" r="0.998"/>
        <circle fill="#FFFFFF" cx="21.332" cy="22.866" r="0.998"/>
        <path fill="#FFFFFF" d="M15.961,0.41c-8.636,0-15.638,7.001-15.638,15.638c0,8.636,7.002,15.638,15.638,15.638
                c8.637,0,15.639-7.002,15.639-15.638C31.6,7.412,24.598,0.41,15.961,0.41z M12.24,3.416c-0.959,1.245-1.766,2.952-2.349,4.973
                H5.256C6.947,6.033,9.395,4.256,12.24,3.416z M10.466,14.206c0.431,0.245,0.766,0.637,0.94,1.107
                c0.086,0.229,0.135,0.477,0.135,0.735c0,0.269-0.052,0.525-0.144,0.762c-0.177,0.457-0.507,0.837-0.928,1.078
                c-0.31,0.178-0.667,0.28-1.049,0.28c-0.161,0-0.317-0.02-0.468-0.054c-0.692-0.157-1.256-0.653-1.508-1.305
                c-0.092-0.236-0.145-0.493-0.145-0.762c0-0.259,0.049-0.506,0.134-0.735c0.247-0.664,0.815-1.17,1.514-1.33
                c0.152-0.035,0.31-0.055,0.473-0.055C9.801,13.928,10.157,14.03,10.466,14.206z M4.325,9.887h5.191
                c-0.196,0.898-0.347,1.846-0.454,2.828c-1.438,0.153-2.602,1.214-2.912,2.599H2.812C2.92,13.361,3.456,11.522,4.325,9.887z
             M4.339,22.236c-0.874-1.635-1.413-3.474-1.524-5.426h3.344c0.318,1.374,1.479,2.424,2.911,2.573
                c0.11,0.992,0.265,1.948,0.466,2.854H4.339z M5.275,23.733h4.642c0.593,2.025,1.411,3.73,2.383,4.965
                C9.438,27.868,6.977,26.094,5.275,23.733z M15.255,29.188c-1.029-0.388-2.061-1.556-2.916-3.337
                c-0.313-0.653-0.59-1.362-0.831-2.117h3.747V29.188z M15.255,22.236h-4.159c-0.229-0.964-0.396-1.987-0.512-3.046
                c1.045-0.387,1.844-1.278,2.101-2.38h2.57V22.236z M15.255,15.313h-2.563c-0.251-1.117-1.058-2.021-2.115-2.41
                c0.112-1.047,0.275-2.061,0.499-3.016h4.18V15.313z M15.255,8.389h-3.773c0.247-0.787,0.532-1.527,0.858-2.205
                c0.814-1.699,1.79-2.838,2.771-3.277c0.048-0.003,0.096-0.008,0.144-0.011V8.389z M27.598,9.887
                c0.869,1.636,1.405,3.474,1.514,5.426h-6.002c-0.025-1.144-0.121-2.248-0.265-3.31c0.839-0.425,1.473-1.191,1.723-2.117H27.598z
             M21.332,24.986c-1.169,0-2.12-0.952-2.12-2.121c0-1.168,0.951-2.12,2.12-2.12s2.12,0.952,2.12,2.12
                C23.452,24.034,22.501,24.986,21.332,24.986z M21.332,11.133c-1.169,0-2.12-0.951-2.12-2.12c0-1.169,0.951-2.12,2.12-2.12
                s2.12,0.951,2.12,2.12C23.452,10.183,22.501,11.133,21.332,11.133z M21.091,5.655c-0.393-0.841-0.835-1.584-1.314-2.212
                c2.807,0.851,5.219,2.616,6.891,4.946h-2.042c-0.292-1.553-1.654-2.729-3.293-2.729 M16.742,2.902
                c0.055,0.003,0.107,0.008,0.16,0.012c0.965,0.439,1.922,1.557,2.727,3.214c-0.815,0.483-1.408,1.298-1.59,2.261h-1.297V2.902z
             M16.742,9.887h1.355c0.385,1.428,1.686,2.48,3.234,2.48c0.01,0,0.02-0.001,0.029-0.001c0.122,0.953,0.2,1.938,0.224,2.947h-4.843
                V9.887z M16.742,16.81h4.84c-0.024,0.924-0.094,1.828-0.2,2.705c-0.018,0-0.032-0.003-0.05-0.003
                c-1.637,0-2.998,1.174-3.292,2.725h-1.298V16.81z M19.658,25.851c-0.854,1.781-1.887,2.949-2.916,3.337v-5.454h1.342
                c-0.014-0.058-0.021-0.117-0.033-0.177c0.2,0.957,0.81,1.764,1.636,2.231c-0.005,0.01-0.011,0.022-0.016,0.032
                S19.662,25.841,19.658,25.851z M19.718,28.671c0.526-0.674,1.006-1.49,1.431-2.417c0.006-0.013,0.011-0.028,0.018-0.041
                c0.056,0.002,0.11,0.007,0.166,0.007c1.615,0,2.963-1.142,3.282-2.663c-0.013,0.06-0.021,0.119-0.035,0.177h2.068
                C24.965,26.067,22.539,27.829,19.718,28.671z M27.584,22.236h-2.96c-0.195-1.026-0.857-1.886-1.758-2.351
                c0.129-0.99,0.214-2.015,0.241-3.076h6.002C28.997,18.763,28.458,20.602,27.584,22.236z"/>
    </g>
</svg>
]],
                        },
                        DT_KNIFE = {
                            scale = 0.7,
                            load_w = 32,
                            load_h = 32,
                            x_offset = 0,
                            y_offset = 0,
                            svg = [[
<svg width="32" height="32" viewBox="0 0 32 32" xmlns="http://www.w3.org/2000/svg">
    <g transform="translate(16 16) rotate(225) scale(0.46) translate(-46.03 -16)">
        <path fill="#FFFFFF" stroke="#FFFFFF" stroke-width="4.5" stroke-linejoin="round" stroke-linecap="round" d="M72.948,12.353c-11.712-2.169-28.352-1.323-28.352-1.323s-0.106,0.382-0.364,0.382
                c-0.258,0-0.374-0.382-0.374-0.382l-0.444,0.018c0,0-0.116,0.391-0.382,0.391s-0.354-0.337-0.354-0.337l-0.471,0.009
                c0,0-0.125,0.364-0.382,0.373c-0.257,0.009-0.337-0.355-0.337-0.355l-0.479,0.009c0,0-0.035,0.355-0.355,0.364
                c-0.32,0.009-0.355-0.346-0.355-0.346l-0.506,0.009c0,0-0.063,0.337-0.355,0.346s-0.329-0.355-0.329-0.355l-0.489,0.018
                c0,0-0.124,0.391-0.408,0.391s-0.364-0.4-0.364-0.4l-4.682,0.098l0.675-2.248V8.755l-0.941-0.693l-0.249,0.125l-0.79,1.999
                l-0.782,0.675l-0.897,0.364l-1.679,0.089l-0.213,0.337l-0.364,0.213v-0.213l-0.178-0.257L6.639,11.9l-0.595,0.586v0.506H5.706
                l-0.399,0.391v0.417H4.916l-0.417,0.391v0.444H4.099l-0.373,0.346v0.436l-0.32-0.036l-0.427,0.364v0.409H2.58l-0.453,0.56
                l1.108,2.805l5.07-0.764l16.332-1.82c0,0,1.82-0.049,1.934-0.082c0.114-0.031,0.219-0.39,0.382-0.39s0.317,0.293,0.317,0.293
                s1.567,0.258,1.917,1.796c0.268,1.178-0.26,2.624-0.26,2.624l0.91,0.552c0,0,0.357-0.617,0.715-1.332
                c0.357-0.715,0.455-1.332,0.455-1.332s1.584-1.748,3.9-0.943c2.56,0.89,2.535,3.607,2.535,3.607s4.063-2.015,11.277-2.242
                s10.4,0.846,19.533,0.813c9.133-0.032,15.34-4.858,15.34-4.858S81.504,13.937,72.948,12.353z M4.49,18.422
                c-0.492,0-0.89-0.42-0.89-0.938s0.398-0.938,0.89-0.938c0.491,0,0.89,0.42,0.89,0.938S4.981,18.422,4.49,18.422z"/>
    </g>
</svg>
]],
                        },
                        DT_BULLET_SINGLE = {
                            scale = 0.7,
                            load_w = 32,
                            load_h = 32,
                            x_offset = 0,
                            y_offset = 0,
                            svg = [[
<svg width="32" height="32" viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg">
    <g transform="translate(16 16) rotate(15) translate(-16 -16)">
        <path d="M30.0937 24.9687L24.9687 30.0937L26.2499 31.375L31.3749 26.25L30.0937 24.9687Z" fill="white"/>
        <path d="M10.3719 7.01136L7.01136 10.3719L8.46695 13.5919L13.5919 8.46695L10.3719 7.01136Z" fill="white"/>
        <path d="M1.26573 1.26556C0.842195 1.68909 4.10718 6.07482 6.39062 8.95315L8.95312 6.39065C6.0747 4.10672 1.68925 0.842026 1.26573 1.26556Z" fill="white"/>
        <path d="M23.8827 29.0077L24.7637 28.1267L28.1267 24.7637L29.0077 23.8827L14.6118 9.48682L9.48682 14.6118L23.8827 29.0077Z" fill="white"/>
    </g>
</svg>
]],
                        },
                        DT_X = {
                            scale = 0.7,
                            load_w = 32,
                            load_h = 32,
                            x_offset = 0,
                            y_offset = 0,
                            svg = [[
<svg width="32" height="32" viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg">
    <path fill-rule="evenodd" clip-rule="evenodd" fill="white" d="M16 1.5C7.992 1.5 1.5 7.992 1.5 16S7.992 30.5 16 30.5S30.5 24.008 30.5 16S24.008 1.5 16 1.5ZM9.348 12.319C8.744 11.715 8.744 10.737 9.348 10.133L10.133 9.348C10.737 8.744 11.715 8.744 12.319 9.348L16 13.029L19.681 9.348C20.285 8.744 21.263 8.744 21.867 9.348L22.652 10.133C23.256 10.737 23.256 11.715 22.652 12.319L18.971 16L22.652 19.681C23.256 20.285 23.256 21.263 22.652 21.867L21.867 22.652C21.263 23.256 20.285 23.256 19.681 22.652L16 18.971L12.319 22.652C11.715 23.256 10.737 23.256 10.133 22.652L9.348 21.867C8.744 21.263 8.744 20.285 9.348 19.681L13.029 16L9.348 12.319Z"/>
</svg>
]],
                        },
                        C4 = {
                            scale = 1.05,
                            load_w = 32,
                            load_h = 32,
                            center = {
                                x_offset = -5,
                                grouped_x_offset = -5,
                                no_line_x_offset = -5,
                                grouped_no_line_x_offset = -5,
                                y_offset = 0,
                            },
                            beep_rays = {
                                {x1 = 16.9, y1 = 7.5, x2 = 16.9, y2 = 3.1},
                                {x1 = 12.6, y1 = 7.5, x2 = 10.5, y2 = 4.7},
                                {x1 = 21.5, y1 = 7.5, x2 = 24.1, y2 = 4.9},
                                {x1 = 25.2, y1 = 11.7, x2 = 29.1, y2 = 9.4},
                                {x1 = 25.2, y1 = 16.1, x2 = 30.4, y2 = 16},
                                {x1 = 25.2, y1 = 20.4, x2 = 29.1, y2 = 22.7},
                                {x1 = 21.5, y1 = 25.1, x2 = 24, y2 = 27.8},
                                {x1 = 16.9, y1 = 25.1, x2 = 16.9, y2 = 29.3},
                                {x1 = 12.6, y1 = 25.1, x2 = 10.5, y2 = 27.8},
                            },
                            svg = [[
<svg version="1.1" xmlns="http://www.w3.org/2000/svg" width="32px" height="32px" viewBox="0 0 32 32" xml:space="preserve">
    <path fill="#FFFFFF" d="M18.3,7.5c0-1.1-.1-2.2-.1-3.3V3.9c0-.3,0-.8-.1-1-.1-.2-.5-.5-.8-.4-.3.1-.5.3-.6.6l-.1,4.4h1.7zM11.1,6.8c.1.2.3.5.4.7h1.9c-.2-.3-.4-.6-.6-.9-.4-.6-.7-1.1-1-1.7-.2-.3-.3-.7-.9-.7-.2.1-.5.2-.6.4-.2.4.1.7.2,1 .2.4.4.8.6,1.2zM23.8,4.2c-.2.1-.3.2-.4.3-.2.3-.3.5-.5.8l-1.4,2.2c.6,0,1.4-.1,1.8.1.2-.4.4-.7.6-1.1.1-.2.2-.4.3-.6.2-.2.4-.5.4-.8.2-.5-.3-.9-.8-.9zM26.6,11.8c.6-.4,1.2-.7,1.8-1.1.3-.2.5-.3.8-.4.3-.2.3-.8.1-1.1-.1-.2-.4-.2-.7-.2-.2.1-.4.2-.6.3-.5.3-1,.5-1.5.8-.3.2-.6.3-.9.5-.1.1-.2.2-.4.2v2c.2-.1.3-.2.5-.3.3-.3.6-.5.9-.7zM23.2,22.8c.3-.4.2-1.1.2-1.8v-9.2c0-.8.1-1.8-.4-2.1-.5-.4-1-.3-1.9-.3h-19c-.1,0-.2,0-.3.1-.3.1-.5.4-.7.7-.1.3-.1,1.3-.1,1.8v10.4c.1.3.3.6.5.8.4.3.9.3,1.6.3h18.1c1.1-.1,1.7,0,2-.7zM3.9,20.3c.2.4.7.8,1.4.7.2,0,.4-.1.5-.1,0,.3.1.6.1.9,0,.2-.2.2-.4.2-.2.1-.8.1-1.1.1-.2,0-.4,0-.6-.1-.6-.2-1-.5-1.2-1.1-.1-.2-.1-.4-.2-.7-.1-.4,0-.9.1-1.2.3-.7.7-1.1,1.5-1.3.2-.1.4,0,.6-.1.1,0,.5,0,.7,0,.2,0,.4.1.6.1l-.2,1c-.3-.1-.8-.2-1.2-.1-.5.2-1,.9-.6,1.7zM10.8,20.6h-.8v1.3H8.8v-1.3H6.3v-.9c.1-.1.1-.2.2-.3.1-.2.2-.4.4-.6.4-.6.7-1.1,1-1.7.2-.3.4-.6.6-.9h1.6v3.4h.8c-.1.3,0,.8-.1,1zM21.5,16.8c-.1.3-.5.2-.9.2H14c-.4,0-1.3.1-1.6-.1-.2-.2-.1-1.1-.1-1.5v-3.1c0-.3-.1-1.1,0-1.3.1-.1.2-.2.3-.2h7.9c.4,0,.6,0,.9.1.1.4.1,1.1.1,1.6v3.9c0,.2.1.4,0,.4zM14.6,14c.1-.1.2-.1.3-.2,0-.1,0-.1-.1-.2-.1.1-.3.1-.4.2.1-.1,0-.2.1-.4h-.3v.4c-.1,0-.3-.1-.3-.2,0,.1-.1.1-.1.2.1.1.2.2.3.2-.1.1-.2.1-.3.2,0,.1.1.2.1.2.1,0,.3-.1.3-.2v.4h.3c0-.1,0-.2-.1-.3.1,0,.3.1.4.2,0-.1.1-.2.1-.3-.1-.1-.2-.1-.3-.2zM16.2,14c.1,0,.3-.1.3-.2,0-.1-.1-.1-.1-.2-.1,0-.3.1-.4.2,0-.1.1-.2.1-.4h-.3v.4c-.1-.1-.2-.1-.3-.2,0,.1-.1.1-.1.2.1.1.2.2.3.2-.1,0-.2.1-.3.2,0,.1.1.2.1.2.1,0,.2-.1.3-.1v.3h.3c0-.1,0-.2-.1-.3.1.1.3.1.4.2,0-.1.1-.2.1-.2-.1-.2-.2-.2-.3-.3zM18.2,13.7c-.1,0-.3.1-.3.2,0-.1,0-.2,0-.4h-.3v.4c-.1,0-.2-.1-.3-.2,0,.1-.1.1-.1.2.1.1.2.1.3.2-.1.1-.2.1-.3.2,0,.1.1.1.1.2.1,0,.3-.1.3-.2v.4h.3c0-.1,0-.2,0-.3.1.1.2.1.4.2,0-.1,0-.1.1-.2,0-.2-.2-.2-.3-.3.1-.1.2-.1.4-.2-.1-.1-.1-.2-.3-.2zM30.6,15.5l-5.4-.2V17c.3,0,.8,0,1.1,0,.2,0,.5,0,.7,0h3.5c.4-.1.6-.2.7-.6.1-.5-.3-.8-.6-.9zM28.5,21.7c-.6-.4-1.3-.8-1.9-1.2-.3-.2-.6-.4-.9-.6-.1-.1-.3-.2-.4-.3v1.9c.1.1.1.1.2.1.2.1.4.2.7.4.4.3.9.5,1.4.8.3.2.6.4.9.5.3.1.8.1.9-.1.2-.3.1-.9-.1-1.1-.2-.1-.5-.2-.8-.4zM23.5,25h-.2c-.1.1-.3,0-.5.1h-1.2c.1.3.4.6.5.8.4.6.7,1.2,1.1,1.9.1.2.5.5.8.4.3-.1.7-.5.5-1-.2-.8-.6-1.5-1-2.2zM11,25.6c-.2.4-.3.7-.5,1.1-.1.2-.2.3-.3.5-.2.5.3.9.6,1 .5.1.7-.4.9-.6.3-.5.7-1.1,1-1.6.2-.3.3-.7.5-.9h-1.9c-.1.2-.2.3-.3.5zM18.3,25.1h-1.7c0,.3,0,.7.1,1,0,.2,0,.4,0,.6l.1,2.7c.1.3.3.5.6.6.3.1.7-.3.8-.5.1-.2.1-.6.1-.9v-.3l0-3.2z"/>
</svg>
]],
                        },
                    },
                }
local asgard_anemone_icon_cache = {};
local function asgard_anemone_load_icon(v_key)
    local v_def = asgard_anemone_icon_defs.icons[v_key];
    if v_def == nil then
        return nil, nil;
    end;
    if asgard_anemone_icon_cache[v_key] == nil then
        local v_ok, v_image = pcall(function()
            return render.load_image(v_def.svg, vector(v_def.load_w or 32, v_def.load_h or 32));
        end);
        asgard_anemone_icon_cache[v_key] = v_ok and v_image or false;
    end;
    local v_image = asgard_anemone_icon_cache[v_key];
    return v_def, v_image ~= false and v_image or nil;
end;
local asgard_anemone_side_font = asgard_gs_font;
local asgard_anemone_side_layout_font = asgard_gs_font;
pcall(function()
    asgard_anemone_side_font = render.load_font("Calibri", vector(24, 23, 0), "dab");
    asgard_anemone_side_layout_font = render.load_font("Calibri Bold", vector(28, 27, 0), "da");
end);
local asgard_anemone_side_anim = {};
local asgard_anemone_side_last_y = {};
local function asgard_anemone_approach(v_current, v_target, v_speed)
    if math.abs(v_target - v_current) <= 0.001 then
        return v_target;
    end;
    return v_current + (v_target - v_current) * math.min(1, v_speed);
end;
local function asgard_anemone_row_key(v_row, v_index)
    local v_text = tostring(v_row.text or "");
    if v_text:find(" - ", 1, true) and v_text:find("s", 1, true) then
        return "bomb_timer";
    elseif v_text == "FATAL" or v_text:find("HP", 1, true) then
        return "bomb_damage";
    elseif (v_text == "A" or v_text == "B") and v_row.progress ~= nil then
        return "bombsite_" .. v_text;
    end;
    return v_text ~= "" and v_text or tostring(v_index);
end;
local function asgard_anemone_icon_key(v_row, v_key)
    if v_key == "bomb_timer" or v_key == "bomb_damage" or tostring(v_key):find("bombsite_", 1, true) then
        return "C4", 1;
    end;
    local v_text = tostring(v_row.text or ""):upper();
    if v_text == "HITCHANCE" or v_text == "HITCHANCE OVR" then
        return "HC", 1;
    elseif v_text == "MD" then
        return "MD", 1;
    elseif v_text == "DT" then
        if (v_row.r or 255) == 255 and (v_row.g or 255) == 0 and (v_row.b or 255) == 50 then
            return "DT_X", 1;
        end;
        local v_player = entity.get_local_player();
        local v_weapon = v_player and v_player:get_player_weapon() or nil;
        local v_info = v_weapon and v_weapon:get_weapon_info() or nil;
        local v_name = v_info and tostring(v_info.console_name or v_info.weapon_name or ""):lower() or "";
        if v_name:find("knife", 1, true) then
            return "DT_KNIFE", 1;
        end;
        local v_single = v_name:find("awp", 1, true)
            or v_name:find("ssg08", 1, true)
            or v_name:find("revolver", 1, true)
            or v_name:find("taser", 1, true)
            or v_name:find("nova", 1, true)
            or v_name:find("xm1014", 1, true)
            or v_name:find("mag7", 1, true)
            or v_name:find("sawedoff", 1, true);
        return "DT_BULLET_SINGLE", v_single and 1 or 2;
    elseif asgard_anemone_icon_defs.icons[v_text] ~= nil then
        return v_text, 1;
    end;
    return nil, 1;
end;
local function asgard_anemone_display_text(v_row)
    local v_text = tostring(v_row.text or "");
    if v_text == "MD" then
        return tostring(v_row.value or 0);
    elseif v_text == "HITCHANCE" then
        return "HITCHANCE OVR";
    end;
    return v_text;
end;
local function asgard_gs_render_old(v_rows)
    local v_screen = render.screen_size();
    local v_yoff = 0;
    for _, v_row in ipairs(v_rows) do
        if v_row.show then
            local v_font = asgard_gs_font or 4;
            local v_size = render.measure_text(v_font, "da", v_row.text);
            local v_y = v_screen.y * 0.5 + (v_screen.y * 0.5 * 0.43 - 1) + v_yoff;
            render.gradient(
                vector(0, v_y),
                vector(31 + v_size.x * 0.5, v_y + 33),
                color(0, 0, 0, 0),
                color(12, 12, 12, 35),
                color(0, 0, 0, 0),
                color(12, 12, 12, 35)
            );
            render.gradient(
                vector(31 + v_size.x * 0.5, v_y),
                vector(31 + v_size.x * 0.5 + 29 + v_size.x * 0.5, v_y + 33),
                color(12, 12, 12, 35),
                color(0, 0, 0, 0),
                color(12, 12, 12, 35),
                color(0, 0, 0, 0)
            );
            render.text(v_font, vector(29, v_y + 7), color(v_row.r or 230, v_row.g or 230, v_row.b or 230, 235), nil, v_row.text);
            if v_row.progress then
                local v_x = 29 + v_size.x + 15;
                local v_py = v_screen.y * 0.0125;
                render.circle_outline(vector(v_x, v_y + v_py), color(10, 10, 10, 230), 10, 0, 1, 5);
                render.circle_outline(vector(v_x, v_y + v_py), color(205, 205, 205, 255), 9, 0, 1 - v_row.progress, 3);
            end;
            v_yoff = v_yoff - 41;
        end;
    end;
end;
local function asgard_anemone_vertical_fade(v_x, v_y, v_width, v_height, v_r, v_g, v_b, v_alpha, v_fade)
    if v_width <= 0 or v_height <= 0 or v_alpha <= 0 then
        return;
    end;
    v_width = math.floor(v_width + 0.5);
    v_height = math.floor(v_height + 0.5);
    v_alpha = math.max(0, math.min(255, math.floor(v_alpha + 0.5)));
    if v_width <= 0 or v_height <= 0 or v_alpha <= 0 then
        return;
    end;
    if v_height <= 2 then
        render.rect(vector(v_x, v_y), vector(v_x + v_width, v_y + v_height), color(v_r, v_g, v_b, v_alpha));
        return;
    end;
    v_fade = math.max(1, math.min(v_fade or 1, math.floor(v_height / 2)));
    local v_middle = math.max(0, v_height - v_fade * 2);
    render.gradient(
        vector(v_x, v_y), vector(v_x + v_width, v_y + v_fade),
        color(v_r, v_g, v_b, 0), color(v_r, v_g, v_b, 0),
        color(v_r, v_g, v_b, v_alpha), color(v_r, v_g, v_b, v_alpha)
    );
    if v_middle > 0 then
        render.rect(vector(v_x, v_y + v_fade), vector(v_x + v_width, v_y + v_fade + v_middle), color(v_r, v_g, v_b, v_alpha));
    end;
    render.gradient(
        vector(v_x, v_y + v_fade + v_middle), vector(v_x + v_width, v_y + v_height),
        color(v_r, v_g, v_b, v_alpha), color(v_r, v_g, v_b, v_alpha),
        color(v_r, v_g, v_b, 0), color(v_r, v_g, v_b, 0)
    );
end;
local function asgard_gs_render_emberlash(v_rows, v_cfg)
    local v_screen = render.screen_size();
    local v_font = asgard_anemone_side_font or asgard_gs_font or 4;
    local v_layout_font = asgard_anemone_side_layout_font or asgard_gs_font or v_font;
    local v_frame = tonumber(globals.frametime) or 0.016;
    local v_pos_speed = math.min(1, v_frame * 18);
    local v_alpha_speed = math.min(1, v_frame * 15);
    local v_color_speed = math.min(1, v_frame * 14);
    local v_seen = {};
    local v_order = {};
    local v_accent = v_cfg.accent:get();
    local v_bg = v_cfg.background:get();
    local v_line = v_cfg.line_accent:get();
    local v_sample = render.measure_text(v_layout_font, "da", "a");
    local v_sample_h = math.max(12, v_sample.y);
    local v_layout_sample_h = v_sample_h + 2;
    local v_icon_sample_h = math.max(1, v_layout_sample_h - 2);
    local v_dpi = math.max(1, v_layout_sample_h / 12);
    local v_style = {
        line_text_gap = 8,
        padding_right = 8,
        accent_rect_height_ratio = 0.45,
        accent_gradient_top_ratio = 0.22,
        accent_main_alpha = 0.9,
        accent_glow_alpha = 0.26,
        padding_y = math.max(1, math.floor(1.5 * v_dpi + 0.5)),
        spacing = (v_bg.a or 100) > 30 and math.floor(4 * v_dpi + 0.5) or math.max(1, math.floor(2 * v_dpi + 0.5)),
        accent_unit = math.max(1, math.floor(v_dpi + 0.5)),
        line_w = math.max(2, math.floor(v_dpi + 0.5)),
        line_glow_w = math.max(2, math.floor(2 * v_dpi + 0.5)),
        radius = math.max(8, math.floor(5 * v_dpi + 0.5) + 4)
    };
    v_style.accent_inset = v_style.accent_unit;
    v_style.line_rect_w = v_style.accent_unit;
    v_style.accent_w = v_line and (v_style.accent_inset + v_style.line_rect_w + v_style.line_w + v_style.line_glow_w) or 0;
    v_style.content_left_w = v_line
        and (v_style.accent_w + v_style.line_text_gap)
        or (v_style.line_text_gap + math.max(3, math.floor(3 * v_dpi + 0.5)));
    v_style.accent_overlap = v_style.accent_unit * 2;
    for v_index, v_row in ipairs(v_rows) do
        if v_row.show then
            local v_key = asgard_anemone_row_key(v_row, v_index);
            local v_text = asgard_anemone_display_text(v_row);
            local v_icon_key, v_icon_repeat = asgard_anemone_icon_key(v_row, v_key);
            local v_icon_def, v_icon = asgard_anemone_load_icon(v_icon_key);
            local v_size = render.measure_text(v_font, "da", v_text);
            local v_layout_size = render.measure_text(v_layout_font, "da", v_text);
            local v_icon_size = v_icon and math.max(1, math.floor(v_icon_sample_h * (v_icon_def.scale or 0.7) + 0.5)) or 0;
            local v_icon_dx = v_icon_repeat > 1 and math.max(3, math.floor(v_icon_size * 0.48 + 0.5)) or 0;
            local v_icon_dy = v_icon_repeat > 1 and math.max(2, math.floor(v_icon_size * 0.34 + 0.5)) or 0;
            local v_icon_h = v_icon_size + (v_icon_repeat - 1) * v_icon_dy;
            local v_icon_slot = v_icon and (v_icon_size + v_icon_dx + 3) or 0;
            local v_row_h = math.max(v_layout_size.y, v_icon_h);
            local v_width = math.max(1, math.floor(v_layout_size.x + v_icon_slot + v_style.content_left_w + v_style.padding_right + 0.5));
            local v_height = math.max(1, math.floor(v_row_h + v_style.padding_y * 2 + 0.5));
            local v_target_r, v_target_g, v_target_b = v_row.r or 255, v_row.g or 255, v_row.b or 255;
            if v_target_r == 255 and v_target_g == 255 and v_target_b == 255 then
                v_target_r, v_target_g, v_target_b = v_accent.r or 159, v_accent.g or 166, v_accent.b or 205;
            end;
            local v_anim = asgard_anemone_side_anim[v_key];
            if not v_anim then
                v_anim = {
                    key = v_key,
                    text = v_text,
                    order = v_index,
                    y = asgard_anemone_side_last_y[v_key] or (v_screen.y * 0.625 + 10),
                    alpha = 0,
                    reveal = 0,
                    width = v_width,
                    height = v_height,
                    r = v_target_r,
                    g = v_target_g,
                    b = v_target_b,
                    icon_key = v_icon_key,
                    icon = v_icon,
                    icon_def = v_icon_def,
                    icon_repeat = v_icon_repeat,
                    icon_size = v_icon_size,
                    icon_dx = v_icon_dx,
                    icon_dy = v_icon_dy,
                    icon_progress = 1
                };
                asgard_anemone_side_anim[v_key] = v_anim;
            end;
            v_anim.present = true;
            v_anim.text = v_text;
            v_anim.order = v_index;
            if v_anim.icon_key ~= v_icon_key then
                v_anim.old_icon = v_anim.icon;
                v_anim.old_icon_def = v_anim.icon_def;
                v_anim.old_icon_repeat = v_anim.icon_repeat;
                v_anim.old_icon_size = v_anim.icon_size;
                v_anim.old_icon_dx = v_anim.icon_dx;
                v_anim.old_icon_dy = v_anim.icon_dy;
                v_anim.icon_progress = 0;
            end;
            v_anim.icon_key = v_icon_key;
            v_anim.icon = v_icon;
            v_anim.icon_def = v_icon_def;
            v_anim.icon_repeat = v_icon_repeat;
            v_anim.icon_size = v_icon_size;
            v_anim.icon_dx = v_icon_dx;
            v_anim.icon_dy = v_icon_dy;
            v_anim.target_width = v_width;
            v_anim.target_height = v_height;
            v_anim.progress = v_row.progress;
            v_anim.target_r = v_target_r;
            v_anim.target_g = v_target_g;
            v_anim.target_b = v_target_b;
            v_seen[v_key] = true;
            v_order[#v_order + 1] = v_anim;
        end;
    end;
    for v_key, v_anim in pairs(asgard_anemone_side_anim) do
        if not v_seen[v_key] then
            v_anim.present = false;
            v_order[#v_order + 1] = v_anim;
        end;
    end;
    table.sort(v_order, function(v_a, v_b)
        if v_a.order == v_b.order then
            return tostring(v_a.key) < tostring(v_b.key);
        end;
        return (v_a.order or 0) < (v_b.order or 0);
    end);
    local v_target_y = v_screen.y * 0.625;
    for _, v_anim in ipairs(v_order) do
        local v_present = v_anim.present and 1 or 0;
        v_anim.reveal = asgard_anemone_approach(v_anim.reveal or 0, v_present, v_alpha_speed);
        v_anim.alpha = asgard_anemone_approach(v_anim.alpha or 0, v_anim.present and 255 or 0, v_alpha_speed);
        v_anim.width = asgard_anemone_approach(v_anim.width or v_anim.target_width, v_anim.target_width or v_anim.width, v_pos_speed);
        v_anim.height = asgard_anemone_approach(v_anim.height or v_anim.target_height, v_anim.target_height or v_anim.height, v_pos_speed);
        v_anim.r = asgard_anemone_approach(v_anim.r or 255, v_anim.target_r or v_anim.r or 255, v_color_speed);
        v_anim.g = asgard_anemone_approach(v_anim.g or 255, v_anim.target_g or v_anim.g or 255, v_color_speed);
        v_anim.b = asgard_anemone_approach(v_anim.b or 255, v_anim.target_b or v_anim.b or 255, v_color_speed);
        v_anim.icon_progress = asgard_anemone_approach(v_anim.icon_progress or 1, 1, v_pos_speed);
        if v_anim.icon_progress >= 0.999 then
            v_anim.old_icon = nil;
            v_anim.old_icon_def = nil;
        end;
        v_anim.target_y = v_target_y;
        v_anim.y = asgard_anemone_approach(v_anim.y or v_target_y, v_target_y, v_pos_speed);
        if v_anim.present then
            asgard_anemone_side_last_y[v_anim.key] = v_anim.target_y;
        end;
        v_target_y = v_target_y + ((v_anim.height or 18) + v_style.spacing) * math.max(0, math.min(1, v_anim.reveal or 0));
    end;
    for _, v_anim in ipairs(v_order) do
        local v_alpha = math.max(0, math.min(255, (v_anim.alpha or 0) * math.max(0, math.min(1, v_anim.reveal or 0))));
        if v_alpha > 0.5 then
            local v_x = 16;
            local v_y = math.floor(v_anim.y + 0.5);
            local v_w = math.max(1, math.floor(v_anim.width + 0.5));
            local v_h = math.max(1, math.floor(v_anim.height + 0.5));
            local v_radius = math.max(1, math.min(v_style.radius, math.floor(math.min(v_w, v_h) / 2)));
            local v_bg_alpha = math.floor((v_bg.a or 100) * v_alpha / 255);
            render.rect(vector(v_x, v_y), vector(v_x + v_w, v_y + v_h), color(v_bg.r or 0, v_bg.g or 0, v_bg.b or 0, v_bg_alpha), v_radius);
            local v_content_x = math.floor(v_x + v_style.content_left_w + 0.5) - 4;
            if v_line then
                local v_is_bomb = tostring(v_anim.key):find("bomb", 1, true) ~= nil;
                local v_line_r = v_is_bomb and 255 or math.floor(v_anim.r or v_accent.r or 159);
                local v_line_g = v_is_bomb and 35 or math.floor(v_anim.g or v_accent.g or 166);
                local v_line_b = v_is_bomb and 35 or math.floor(v_anim.b or v_accent.b or 205);
                local v_line_alpha = math.floor(v_alpha * v_style.accent_main_alpha);
                local v_accent_x = v_x + v_style.accent_inset;
                local v_bomb_pad = v_is_bomb and math.max(3, math.floor(4 * v_dpi + 0.5)) or 0;
                v_bomb_pad = math.min(v_bomb_pad, math.floor(v_h / 2));
                local v_rect_h = v_is_bomb
                    and math.max(1, v_h - v_bomb_pad * 2)
                    or math.max(1, math.min(v_h, math.floor(v_h * v_style.accent_rect_height_ratio + 0.5)));
                local v_rect_y = v_is_bomb
                    and (v_y + v_bomb_pad)
                    or (v_y + math.floor((v_h - v_rect_h) / 2 + 0.5));
                local v_grad_y = v_is_bomb
                    and v_rect_y
                    or (v_y + math.floor(v_h * v_style.accent_gradient_top_ratio + 0.5));
                local v_grad_h = v_is_bomb
                    and v_rect_h
                    or math.max(1, math.min(v_h, v_h - (v_grad_y - v_y) * 2));
                local v_fade = math.max(1, math.min(math.floor(v_grad_h / 2), math.floor(4 * v_dpi + 0.5)));
                local v_overlap = v_is_bomb and 0 or v_style.accent_overlap;
                asgard_anemone_vertical_fade(
                    v_accent_x - v_style.accent_unit,
                    v_rect_y + v_style.accent_unit,
                    v_style.line_rect_w,
                    math.max(1, v_rect_h - v_overlap),
                    v_line_r, v_line_g, v_line_b, v_line_alpha, v_fade
                );
                asgard_anemone_vertical_fade(
                    v_accent_x,
                    v_rect_y - v_overlap,
                    v_style.line_rect_w,
                    v_rect_h + v_overlap * 2,
                    v_line_r, v_line_g, v_line_b, v_line_alpha, v_fade
                );
                asgard_anemone_vertical_fade(
                    v_accent_x + v_style.line_rect_w,
                    v_grad_y - v_overlap,
                    v_style.line_w,
                    v_grad_h + v_overlap * 2,
                    v_line_r, v_line_g, v_line_b, v_line_alpha, v_fade
                );
                for v_i = 0, v_style.line_glow_w - 1 do
                    local v_glow_alpha = math.floor(v_alpha * (v_style.accent_glow_alpha / (v_i + 1)));
                    asgard_anemone_vertical_fade(
                        v_accent_x + v_style.line_rect_w + v_style.line_w + v_i,
                        v_grad_y,
                        v_style.accent_unit,
                        v_grad_h,
                        v_line_r, v_line_g, v_line_b, v_glow_alpha, v_fade
                    );
                end;
            end;
            local v_text_r = math.floor(v_anim.r or 255);
            local v_text_g = math.floor(v_anim.g or 255);
            local v_text_b = math.floor(v_anim.b or 255);
            if v_text_r == 255 and v_text_g == 255 and v_text_b == 255 then
                v_text_r, v_text_g, v_text_b = v_accent.r or 159, v_accent.g or 166, v_accent.b or 205;
            end;
            local function v_draw_icon(v_image, v_def, v_repeat, v_size, v_dx, v_dy, v_icon_alpha)
                if v_image == nil or v_icon_alpha <= 0 then
                    return;
                end;
                local v_xoff = v_def and (v_def.x_offset or (v_def.line and v_def.line.x_offset)) or 0;
                local v_yoff = v_def and (v_def.y_offset or (v_def.line and v_def.line.y_offset)) or 0;
                local v_total_h = v_size + ((v_repeat or 1) - 1) * (v_dy or 0);
                for v_i = 1, (v_repeat or 1) do
                    local v_n = v_i - 1;
                    render.texture(
                        v_image,
                        vector(v_content_x + v_xoff + (v_dx or 0) * v_n, v_y + (v_h - v_total_h) / 2 + v_yoff + (v_dy or 0) * v_n - 1),
                        vector(v_size, v_size),
                        color(v_text_r, v_text_g, v_text_b, math.floor(v_icon_alpha)),
                        v_def and v_def.mode or "f"
                    );
                end;
            end;
            local v_icon_mix = math.max(0, math.min(1, v_anim.icon_progress or 1));
            if v_anim.old_icon ~= nil then
                v_draw_icon(v_anim.old_icon, v_anim.old_icon_def, v_anim.old_icon_repeat, v_anim.old_icon_size, v_anim.old_icon_dx, v_anim.old_icon_dy, v_alpha * (1 - v_icon_mix));
            end;
            v_draw_icon(v_anim.icon, v_anim.icon_def, v_anim.icon_repeat, v_anim.icon_size, v_anim.icon_dx, v_anim.icon_dy, v_alpha * v_icon_mix);
            local v_icon_slot = v_anim.icon and ((v_anim.icon_size or 0) + (v_anim.icon_dx or 0) + 5) or 0;
            local v_text_size = render.measure_text(v_font, "da", v_anim.text);
            render.text(
                v_font,
                vector(v_content_x + v_icon_slot, v_y + math.floor((v_h - v_text_size.y) / 2) + 1),
                color(v_text_r, v_text_g, v_text_b, math.floor(v_alpha)),
                "da",
                v_anim.text
            );
            if v_anim.progress ~= nil then
                local v_radius2 = math.max(5, math.floor(v_h * 0.28));
                local v_circle = vector(v_x + v_w - v_radius2 - 6, v_y + v_h / 2);
                render.circle_outline(v_circle, color(0, 0, 0, math.floor(v_alpha * 0.8)), v_radius2, 0, 1, 5);
                render.circle_outline(v_circle, color(200, 200, 200, math.floor(v_alpha)), math.max(1, v_radius2 - 1), 0, 1 - v_anim.progress, 3);
            end;
        end;
    end;
    for v_key, v_anim in pairs(asgard_anemone_side_anim) do
        if not v_anim.present and (v_anim.alpha or 0) < 1 and (v_anim.reveal or 0) < 0.01 then
            asgard_anemone_side_anim[v_key] = nil;
        end;
    end;
end;
  local side_cfg = {
    accent = cfg.side_indicators_accent,
    background = cfg.side_indicators_background,
    line_accent = cfg.side_indicators_line
  }
  local function side_selected(name)
    local ok, value = pcall(function() return cfg.side_indicators_items:get(name) end)
    if ok and type(value) == "boolean" then return value end
    local list={}; pcall(function() list=cfg.side_indicators_items:get() or {} end)
    for _,v in ipairs(list) do if v==name then return true end end
    return false
  end
  local function side_bind(...)
    local aliases={...}; local binds={}; pcall(function() binds=ui.get_binds() or {} end)
    for _,bind in pairs(binds) do
      local name=cfg.version_state.clean_bind_name(bind.name):lower()
      for _,alias in ipairs(aliases) do
        if name:find(tostring(alias):lower(),1,true) and bind.active then return true,bind.value end
      end
    end
    return false,nil
  end
  local function side_add(rows,text,show,r,g,b,progress,value)
    rows[#rows+1]={text=text,show=show==true,r=r,g=g,b=b,progress=progress,value=value}
  end
  local function side_rows(player)
    local rows={}
    local dt=side_bind("double tap"); local hs=side_bind("hide shots","on shot anti-aim"); local fd=side_bind("fake duck")
    if side_selected("Double Tap") then local ready=false; pcall(function() ready=rage.exploit:get()==1 end); side_add(rows,"DT",dt and not fd,ready and 200 or 255,ready and 207 or 0,ready and 200 or 50) end
    if side_selected("HideShots") then side_add(rows,"OSAA",hs and not dt and not fd) end
    if side_selected("Fake Duck") then side_add(rows,"DUCK",fd) end
    if side_selected("Dormant Aimbot") then side_add(rows,"DA",(side_bind("dormant aimbot"))) end
    if side_selected("Force Safe Points") then side_add(rows,"SAFE",(side_bind("safe point"))) end
    if side_selected("Force Body") then side_add(rows,"BODY",(side_bind("body aim"))) end
    if side_selected("Min Damage") then local active,value=side_bind("min. damage","min damage","damage override"); side_add(rows,"MD",active,nil,nil,nil,nil,value) end
    if side_selected("Hit Chance") then side_add(rows,"HITCHANCE",(side_bind("hit chance","hitchance"))) end
    if side_selected("Freestanding") then side_add(rows,"FS",(side_bind("freestanding","freestand"))) end
    if side_selected("Exploit Backtrack") then local active,value=side_bind("ping spike","fake latency"); local n=tonumber(value) or 0; local r,g,b=230,230,230; if n>=1 and n<=100 then r,g,b=189,199,118 elseif n>100 then r,g,b=169,203,82 end; side_add(rows,"PING",active,r,g,b) end
    if side_selected("Bomb") then
      local b=asgard_gs_side_runtime.bomb
      if b.planting then local elapsed=(tonumber(globals.curtime) or 0)-b.plant_start; side_add(rows,asgard_gs_bomb_site(b.plant_site),true,255,255,120,math.max(0,1-elapsed/b.plant_time)) end
      local bombs={}; pcall(function() bombs=entity.get_entities("CPlantedC4",true) or {} end); local ent=bombs[1]
      if ent and not ent.m_bBombDefused and asgard_gs_bomb_timer(ent)>0 and not b.was_bombed then
        local site=ent.m_nBombSite==0 and "A" or (ent.m_nBombSite==1 and "B" or "?"); local timer=string.format("%.1f",asgard_gs_bomb_timer(ent)).."s"; local pct=nil
        if b.is_defusing and b.defuse_time>0 then pct=math.max(0,1-((tonumber(globals.curtime) or 0)-b.defuse_start)/b.defuse_time) end
        side_add(rows,site.." - "..timer,true,b.is_defusing and 195 or 210,b.is_defusing and 205 or 210,b.is_defusing and 75 or 210,pct)
        local damage=asgard_gs_bomb_damage(player,ent); if damage and math.floor(damage)>0 then local d=math.floor(damage); side_add(rows,player.m_iHealth<=d and "FATAL" or ("-"..d.." HP"),true,255,player.m_iHealth<=d and 0 or 245,player.m_iHealth<=d and 0 or 104) end
      end
    end
    return rows
  end
  local function side_reset()
    local b=asgard_gs_side_runtime.bomb; b.was_defused=false; b.was_bombed=false; b.defuse_time=0; b.defuse_start=0; b.is_defusing=false; b.plant_site=0; b.plant_time=3.2; b.plant_start=0; b.planting=false
    asgard_anemone_side_anim={}; asgard_anemone_side_last_y={}
  end
  chain("bomb_beginplant",function(e) local b=asgard_gs_side_runtime.bomb; b.planting=true; b.plant_start=globals.curtime; b.plant_site=e.site end)
  chain("bomb_abortplant",function() asgard_gs_side_runtime.bomb.planting=false end)
  chain("bomb_planted",function() asgard_gs_side_runtime.bomb.planting=false end)
  chain("bomb_begindefuse",function(e) local b=asgard_gs_side_runtime.bomb; if not b.is_defusing then b.defuse_start=globals.curtime end; b.is_defusing=true; b.defuse_time=e.haskit and 5 or 10 end)
  chain("bomb_abortdefuse",function() asgard_gs_side_runtime.bomb.is_defusing=false end)
  chain("bomb_defused",function() local b=asgard_gs_side_runtime.bomb; b.is_defusing=false; b.was_defused=true end)
  chain("bomb_exploded",function() asgard_gs_side_runtime.bomb.was_bombed=true end)
  chain("round_start",side_reset); chain("round_prestart",side_reset); chain("disconnect",side_reset)
  return function()
    if not get_bool(cfg.side_indicators) then return end
    local player=entity.get_local_player(); if not player or not player:is_alive() then return end
    local rows=side_rows(player); local style="Emberlash"; pcall(function() style=cfg.side_indicators_type:get() end)
    if style=="GS" then asgard_gs_render_old(rows) else asgard_gs_render_emberlash(rows,side_cfg) end
  end
end)()
local function setting_visible(ref, state)
  if ref then
    pcall(function ()
      ref:visibility(state == true)
    end)
  end
end
settings_visibility_tick = function()
  pcall(cfg.version_state.sanitize_live_binds)
  local resolver_on = get_bool(cfg.resolver)
  ;
  local ultimate_on = cfg.version_state.is_ultimate()
  local adaptive_on = cfg.version_state.is_plus()
  local resolver_options = resolver_on and not ultimate_on
  local assist_available = resolver_options and not adaptive_on
  local assist_on = assist_available and get_bool(cfg.assist)
  local ffi_assist=assist_on and yaw_mode()=="FFI"
  if not resolver_on then
    pcall(function ()
      if get_bool(cfg.assist) then cfg.assist:set(false) end
      if get_bool(cfg.yaw) then cfg.yaw:set(false) end
    end)
    assist_on = false
  elseif not assist_on and resolver_options and not get_bool(cfg.yaw) then
    pcall(function () cfg.yaw:set(true) end)
  end
  if adaptive_on and get_bool(cfg.assist) then pcall(function() cfg.assist:set(false) end) end
  if assist_on and not ffi_assist and get_bool(cfg.yaw)then
    pcall(function ()
      cfg.yaw:set(false)
    end)
  end
  local yaw_on=resolver_options and (not assist_on or ffi_assist)and get_bool(cfg.yaw)
  setting_visible(cfg.assist, assist_available)
  setting_visible(cfg.adaptive_head, false)
  setting_visible(cfg.yaw, resolver_options)
  setting_visible(cfg.yaw_mode,resolver_options)
  pcall(function ()
    cfg.yaw:disabled(not resolver_options or (assist_on and not ffi_assist))
  end)
  pcall(function ()
    cfg.yaw_mode:disabled(not resolver_options)
  end)
  local extrap_on = get_bool(cfg.extrapolation)
  pcall(function ()
    cfg.interpolation:set(true)
    cfg.interpolation:visibility(false)
  end)
  local ultimate_arm = cfg.version_state.is_ultimate()
  for _, ref in ipairs({ cfg.extrapolation_ticks, cfg.extrapolation_auto, cfg.extrapolation_fake_latency }) do
    setting_visible(ref, extrap_on and not ultimate_arm)
  end
  pcall(function ()
    if cfg.yaw_mode then
      setting_visible(cfg.yaw_mode,resolver_on and not ultimate_arm)
    end
    if cfg.extrapolation_mode then
      setting_visible(cfg.extrapolation_mode, extrap_on and not ultimate_arm)
    end
    local show = ultimate_arm and cfg.version_state.ultimate_built == true
    for _, entry in ipairs(cfg.version_state.ultimate_controls or { }) do
      local control = entry[1]
      if control then
        control:visibility(show)
      end
    end
  end)
  setting_visible(cfg.opt_preset, get_bool(cfg.fps_optimizer))
  setting_visible(cfg.opt_list, get_bool(cfg.fps_optimizer))
  local model_available = cfg.model_changer_available == true
  local model_on = model_available and get_bool(cfg.model_changer)
  setting_visible(cfg.model_changer_team, model_on)
  setting_visible(cfg.model_changer_status, true)
  setting_visible(cfg.model_changer_refresh, true)
  local model_teams = { }
  pcall(function () model_teams = cfg.model_changer_team:get() or { } end)
  local model_ct, model_t = false, false
  for _, team in ipairs(model_teams) do
    if team == "CT" then model_ct = true elseif team == "T" then model_t = true end
  end
  setting_visible(cfg.model_changer_ct, model_on and model_ct)
  setting_visible(cfg.model_changer_t, model_on and model_t)
  local movement_on = get_bool(cfg.movement)
  for _, v in ipairs({ cfg.fast_ladder, cfg.no_fall_damage, cfg.avoid_collision }) do
    setting_visible(v, movement_on)
  end
  local aspect_on = get_bool(cfg.aspect)
  ;
  setting_visible(cfg.aspect_value, aspect_on)
  ;
  setting_visible(cfg.presets, aspect_on)
  local indicator_on = get_bool(cfg.crosshair_indicator)
  setting_visible(cfg.crosshair_indicator_color, indicator_on)
  setting_visible(cfg.crosshair_indicator_shadow, indicator_on)
  setting_visible(cfg.damage_indicator, indicator_on)
  local damage_on = indicator_on and get_bool(cfg.damage_indicator)
  setting_visible(cfg.damage_indicator_color, damage_on)
  setting_visible(cfg.damage_indicator_font, damage_on)
  local ultimate_widgets = cfg.version_state.is_ultimate()
  pcall(function () cfg.side_indicators:visibility(true) end)
  local side_on = get_bool(cfg.side_indicators)
  setting_visible(cfg.side_indicators_type, side_on and ultimate_widgets)
  local side_ember = side_on and ultimate_widgets and cfg.side_indicators_type:get() == "Emberlash"
  setting_visible(cfg.side_indicators_accent, side_ember)
  setting_visible(cfg.side_indicators_background, side_ember)
  setting_visible(cfg.side_indicators_line, side_ember)
  setting_visible(cfg.side_indicators_items, side_on)
  local particles_on = get_bool(cfg.kill_particles)
  for _, v in ipairs({ cfg.kill_particle_color, cfg.kill_particle_amount, cfg.kill_particle_duration }) do
    setting_visible(v, particles_on)
  end
  local hit_on = get_bool(cfg.hit_effect)
  setting_visible(cfg.fortnite_hit, hit_on)
  setting_visible(cfg.effects, hit_on)
  setting_visible(cfg.effects_mode, hit_on and get_bool(cfg.effects))
  local watermark_on = get_bool(cfg.watermark)
  ;
  setting_visible(cfg.wm_style, watermark_on)
  ;
  setting_visible(cfg.wm_position, watermark_on)
  local style = wm_read_style()
  ;
  setting_visible(cfg.wm_elements, watermark_on and style == "Gamesense")
  ;
  setting_visible(cfg.wm_accent, watermark_on and style == "Gamesense")
  ;
  setting_visible(cfg.wm_nl_elements, watermark_on and style == "Neverlose")
  ;
  setting_visible(cfg.wm_nl_accent, watermark_on and style == "Neverlose")
  local ev = watermark_on and style == "Evalate"
  setting_visible(cfg.wm_eval_elements, ev)
  setting_visible(cfg.wm_eval_accent, ev)
  setting_visible(cfg.wm_eval_username_source, ev and wm_eval_elem_enabled("Username"))
  setting_visible(cfg.wm_eval_time_format, ev and wm_eval_elem_enabled("Time"))
  local custom = false
  ;
  pcall(function ()
    custom = cfg.wm_eval_username_source:get() == "Custom"
  end)
  setting_visible(cfg.wm_eval_username_custom, ev and wm_eval_elem_enabled("Username") and custom)
  local hotkeys_on = get_bool(cfg.hotkeys)
  setting_visible(cfg.hotkeys_style, hotkeys_on and ultimate_widgets)
  local hotkeys_ember = hotkeys_on and ultimate_widgets and cfg.hotkeys_style:get() == "Emberlash"
  setting_visible(cfg.hotkeys_anemone_accent, hotkeys_ember)
  setting_visible(cfg.hotkeys_anemone_background, hotkeys_ember)
  setting_visible(cfg.specs_header, get_bool(cfg.spectators))
  local notify_on = get_bool(cfg.notifications)
  for _, v in ipairs({ cfg.notification_debug, cfg.notification_screen, cfg.notification_console }) do
    setting_visible(v, notify_on)
  end
  local trash_on = get_bool(cfg.trash)
  setting_visible(cfg.trash_mode, trash_on)
  setting_visible(cfg.trash_trigger, trash_on)
end
settings_visibility_tick()
settings_visibility_tick()
set_menu_section = function()
  local ok, active = pcall(function ()
    return cfg.section:get()
  end)
  active = ok and active or 1
  local workspace_ok, workspace = pcall(function ()
    return cfg.workspace:get()
  end)
  workspace = workspace_ok and workspace or 1
  local workspace_text = tostring(workspace or "")
  local show_home = workspace == 1 or workspace == "Home" or workspace == cfg.workspace_items[1] or workspace_text:find("Home", 1, true) ~= nil
  local show_configs = workspace == 2 or workspace == "Configs" or workspace == cfg.workspace_items[2] or workspace_text:find("Configs", 1, true) ~= nil
  if not show_home and not show_configs then
    show_home = true
  end
  local information_selected = active == 1 or active == "Information" or active == SECTION_ITEMS[1]
  local show_info = show_home and information_selected
  local show_funcs = show_home and (active == 2 or active == "Functions" or active == SECTION_ITEMS[2])
  local show_version = show_home and (active == 3 or active == "Version" or active == SECTION_ITEMS[3])
  if show_home and not show_info and not show_funcs and not show_version then
    show_info = true
    information_selected = true
  end
  pcall(function ()
    cfg.section:visibility(not show_configs)
  end)
  pcall(function ()
    cfg.workspace:visibility(show_configs or (show_home and information_selected))
  end)
  for _, item in ipairs({ cfg.report, cfg.export_report, cfg.export_logs }) do
    pcall(function () item:visibility(show_info) end)
  end
  pcall(function ()
    cfg.version_developer:visibility(show_version)
    cfg.version_base:visibility(show_version)
  end)
  pcall(function () cfg.config_panel:visibility(true) end)
  cfg.config_system.page_visible = show_configs == true
  for _, item in ipairs({ cfg.config_list, cfg.config_name, cfg.config_create, cfg.config_load, cfg.config_save, cfg.config_import, cfg.config_export, cfg.config_delete }) do
    pcall(function () item:visibility(cfg.config_system.page_visible) end)
  end
  for _, item in ipairs({ info, info_links }) do
    pcall(function ()
      item:visibility(show_info)
    end)
  end
  for _, item in ipairs({ funcs, rb, vis, rb_functions }) do
    pcall(function ()
      item:visibility(show_funcs)
    end)
  end
end
pcall(function ()
  cfg.section:set_callback(set_menu_section, true)
end)
pcall(function ()
  cfg.workspace:set_callback(function ()
    set_menu_section()
    pcall(function () utils.execute_after(0, set_menu_section) end)
  end, true)
end)
set_menu_section()
function cfg.version_state.force_beta_startup()
  if cfg.version_state.boot_forcing then return end
  cfg.version_state.boot_forcing = true
  pcall(function() cfg.version_ultimate:set(false); cfg.version_plus:set(false) end)
  pcall(function() cfg.version_beta:set(true); cfg.version_beta:disabled(true) end)
  local white_sections = {
    section_item({ "circle-info", "info-circle", "info" }, "Information"),
    section_item({ "sliders", "gears", "gear", "function" }, "Functions"),
    section_item({ "code-branch", "layer-group", "cubes" }, "Version")
  }
  local white_workspace = {
    section_item({ "house", "home" }, "Home"),
    section_item({ "folder-gear", "folder", "floppy-disk", "gear" }, "Configs")
  }
  SECTION_ITEMS = white_sections
  cfg.workspace_items = white_workspace
  pcall(function() cfg.section:update(white_sections); cfg.section:set(1) end)
  pcall(function() cfg.workspace:update(white_workspace); cfg.workspace:set(1) end)
  pcall(function()
    cfg.version_build_info:name(WHITE .. " Beta " .. RESET)
    cfg.version_number_info:name(WHITE .. " " .. info_text(cfg.version_state.lua_version) .. " " .. RESET)
    cfg.version_user_info:name(WHITE .. " " .. info_text(client_nick()) .. " " .. RESET)
    cfg.version_updated_info:name(WHITE .. " " .. info_text(cfg.version_state.beta_updated) .. " " .. RESET)
    author_cell:name(WHITE .. " PWNZ " .. RESET)
    for _, social in ipairs(cfg.version_social_buttons or {}) do
      social[1]:name(WHITE .. " " .. social[2] .. " " .. RESET)
    end
  end)
  cfg.version_state.intro_active = false
  cfg.version_state.boot_forcing = false
  pcall(set_menu_section)
end
cfg.version_state.force_beta_startup()
cfg.scope_runtime = { master = 0, scoped = 0, native = nil }
pcall(function() cfg.scope_runtime.native = ui.find("Visuals", "World", "Main", "Override Zoom", "Scope Overlay") end)
function cfg.scope_overlay_tick()
  local me = entity.get_local_player()
  local alive = false; pcall(function() alive = me ~= nil and me:is_alive() end)
  local enabled = alive and get_bool(cfg.scope_overlay)
  local scoped = false; pcall(function() scoped = me.m_bIsScoped == true end)
  local dt = math.min(1, math.max(0.001, tonumber(globals.frametime) or 0.016) * 20)
  cfg.scope_runtime.master = cfg.scope_runtime.master + ((enabled and 1 or 0) - cfg.scope_runtime.master) * dt
  cfg.scope_runtime.scoped = cfg.scope_runtime.scoped + ((enabled and scoped and 1 or 0) - cfg.scope_runtime.scoped) * dt
  if cfg.scope_runtime.master <= 0.002 then
    pcall(function() if cfg.scope_runtime.native then cfg.scope_runtime.native:override() end end)
    return
  end
  pcall(function() if cfg.scope_runtime.native then cfg.scope_runtime.native:override("Remove All") end end)
  local a = cfg.scope_runtime.master * cfg.scope_runtime.scoped
  if a <= 0.002 then return end
  local screen = render.screen_size(); local center = screen * 0.5
  local gap = math.floor(cfg.scope_overlay_gap:get()); local length = math.floor(cfg.scope_overlay_length:get()); local diff = length - gap
  local main, edge = cfg.scope_overlay_main:get(), cfg.scope_overlay_edge:get()
  local inverted = false; pcall(function() inverted = cfg.scope_overlay_options:get("Inverted") or cfg.scope_overlay_options:get(1) end)
  if inverted then main, edge = edge, main end
  main = color(main.r, main.g, main.b, math.floor(main.a * a)); edge = color(edge.r, edge.g, edge.b, math.floor(edge.a * a))
  render.gradient(vector(center.x, center.y-gap+1), vector(center.x+1, center.y-length*a), main, main, edge, edge)
  render.gradient(vector(center.x, center.y+gap), vector(center.x+1, center.y+length*a), main, main, edge, edge)
  render.gradient(vector(center.x-gap+1, center.y), vector(center.x-gap+1-diff*a, center.y+1), main, edge, main, edge)
  render.gradient(vector(center.x+gap, center.y), vector(center.x+gap+diff*a+1, center.y+1), main, edge, main, edge)
end
pcall(function() chain("render",cfg.scope_overlay_tick) end)
N = {
  slots = { },
  master = nil
}
local SAFE_RANK = { Off = 0, Disabled = 0, Prefer = 1, Force = 2 }
local SAFE_PATHS = {
  { "Aimbot", "Ragebot", "Safety", "Safe Points" },
  { "Aimbot", "Ragebot", "Main", "Safe Points" },
  { "Aimbot", "Ragebot", "Safe Points" },
  { "Aimbot", "Ragebot", "Safety", "Safe Headshot" },
  { "Aimbot", "Ragebot", "Safety", "Force Safe Headshot" },
  { "Aimbot", "Ragebot", "Main", "Safety", "Safe Points" },
  { "Aimbot", "Ragebot", "Main", "Safety", "Safe Headshot" },
  { "Aimbot", "Ragebot", "Safety", "Prefer Safe Headshot" },
  { "Aimbot", "Ragebot", "Main", "Prefer Safe Headshot" },
  { "Aimbot", "Ragebot", "Prefer Safe Headshot" },
}
function N:find(path)
  local unpack_values = unpack or table.unpack
  local ok, ref = pcall(function ()
    return ui.find(unpack_values(path))
  end)
  if not ok or not ref then
    return nil
  end
  local readable = pcall(function ()
    ref:get()
    ;
    ref:get_override()
  end)
  return readable and ref or nil
end
function N:read(ref)
  if not ref then
    return false
  end
  local ok, base, forced = pcall(function ()
    return ref:get(), ref:get_override()
  end)
  if not ok then
    return false
  end
  return true, base, forced
end
function N:effective(ref)
  local ok, base, forced = self:read(ref)
  if not ok then
    return nil
  end
  if forced ~= nil then
    return forced
  end
  return base
end
function N:master_enabled()
  return self:effective(self.master) == true
end
function N:bind_safe()
  for _, p in ipairs(SAFE_PATHS) do
    local ref = self:find(p)
    if ref then
      local readable = self:read(ref)
      local ok, options = pcall(function ()
        return ref:list()
      end)
      local prefer = false
      if ok and type(options) == "table" then
        for _, value in pairs(options) do
          if value == "Prefer" then
            prefer = true
          end
        end
      end
      if readable and prefer and SAFE_RANK[self:effective(ref)] ~= nil then
        return ref, p
      end
    end
  end
  return nil
end
N.EXTRAPOLATION_PATHS = {
  { "Aimbot", "Ragebot", "Extrapolation" },
  { "Aimbot", "Ragebot", "Main", "Extrapolation" },
  { "Aimbot", "Ragebot", "Selection", "Extrapolation" },
  { "Aimbot", "Ragebot", "Accuracy", "Extrapolation" },
  { "Aimbot", "Ragebot", "Safety", "Extrapolation" },
  { "Aimbot", "Ragebot", "Extrapolation", "Enabled" },
  { "Aimbot", "Ragebot", "Main", "Extrapolation", "Enabled" },
}
function N:bind_extrapolation()
  for _, p in ipairs(N.EXTRAPOLATION_PATHS) do
    local ref = self:find(p)
    if ref then
      local ok, base = self:read(ref)
      if ok and type(base) == "number" then
        return ref, p
      end
    end
  end
  return nil
end
function N:fake_latency_ticks()
  if not self.fake_latency_ref then return 0 end
  local ok,base,forced=self:read(self.fake_latency_ref)
  if not ok then return 0 end
  local value=base
  if forced~=nil then value=forced end
  if not number(value) or value<=0 then return 0 end
  local iv=globals and number(globals.tickinterval)
  if not iv or iv<0.001 or iv>0.1 then return 0 end
  return math.floor(value/(iv*1000)+0.5)
end
function N:drive_extrapolation(t)
  local enabled = get_bool(cfg.extrapolation)
  if not enabled then
    if self.slots.extrap then
      self:request("extrap", nil)
    end
    return
  end
  local ticks = nil
  local auto = get_bool(cfg.extrapolation_auto)
  if auto then
      local now = t or clock()
      if not self.extrap_auto_at or now - self.extrap_auto_at >= 1.0 then
        self.extrap_auto_at = now
        local ping_ms = 0
        local ok, lat = pcall(function () return net.avg_latency and net.avg_latency[0] end)
        if ok and number(lat) then ping_ms = lat * 1000 end
        local fl = get_bool(cfg.extrapolation_fake_latency) and self:fake_latency_ticks() or 0
        local iv=globals and number(globals.tickinterval)
        ticks=iv and iv>0 and math.max(0,math.min(15,math.floor(ping_ms/(iv*1000)+fl+0.5))) or 0
        pcall(function () cfg.extrapolation_ticks:set(ticks) end)
      end
  else
    ticks = tonumber(cfg.extrapolation_ticks:get())
  end
  if ticks==nil then pcall(function () ticks=tonumber(cfg.extrapolation_ticks:get()) end) end
  if not ticks or ticks < 0 or ticks > 15 then ticks=0 end
  if not self.slots.extrap.ref then
    return
  end
  if ticks <= 0 then
    self:request("extrap", nil)
    return
  end
  if Y.observation_bridge then
    local found,ent=pcall(entity.get_threat)
    local id,uid
    if found and ent then pcall(function () id=ent:get_index();uid=ent:get_player_info().userid end) end
    local shared=id and Y.observation_bridge:assessment(id,uid,globals.tickcount,globals.tickinterval)
    if shared then
      if shared.invalid then self:request("extrap",nil);return end
      ticks=math.min(ticks,shared.horizon)
    end
  end
  local ok, range = pcall(function ()
    local minv, maxv = self.slots.extrap.ref:range()
    return minv, maxv
  end)
  if ok and number(range) and range > 0 then
    ticks = math.max(0, math.min(range, ticks))
  end
  self:request("extrap", ticks)
end
function N:init()
  self.master = self:find({ "Aimbot", "Ragebot", "Main", "Enabled" })
  if type(self:effective(self.master)) ~= "boolean" then
    self.master = nil
  end
  local safe, safe_path = self:bind_safe()
  local dormant = self:find({ "Aimbot", "Ragebot", "Main", "Enabled", "Dormant Aimbot" })
  if type(self:effective(dormant)) ~= "boolean" then
    dormant = nil
  end
  local extrap = self:bind_extrapolation()
  local fake_latency = self:find({ "Miscellaneous", "Main", "Other", "Fake Latency" })
  self.slots.safe = {
    ref = safe,
    kind = "safe",
    owned = false,
    yielded = false,
    applied = 0,
    released = 0,
    conflicts = 0,
    state = "idle"
  }
  self.slots.dormant = {
    ref = dormant,
    kind = "dormant",
    owned = false,
    yielded = false,
    applied = 0,
    released = 0,
    conflicts = 0,
    state = "idle"
  }
  self.slots.extrap = {
    ref = extrap,
    kind = "extrap",
    owned = false,
    yielded = false,
    applied = 0,
    released = 0,
    conflicts = 0,
    state = "idle"
  }
  local body=self:find({"Aimbot","Ragebot","Safety","Body Aim"})
  local body_base=self:effective(body)
  if SAFE_RANK[body_base]==nil then body=nil end
  self.slots.body={ref=body,kind="body",owned=false,yielded=false,applied=0,released=0,conflicts=0,state="idle"}
  self.fake_latency_ref = fake_latency
  if not self.master then
    warn_once("native_master", "Native Ragebot Enabled is unavailable; no combat overrides will be issued.")
  end
  if not dormant then
    warn_once("native_dormant", "Native Dormant Aimbot unavailable. No custom dormant shots will be substituted.")
  end
end
function N:retry_bind()
  if not self.master then
    self.master = self:find({ "Aimbot", "Ragebot", "Main", "Enabled" })
    if type(self:effective(self.master)) ~= "boolean" then
      self.master = nil
    end
  end
  if self.slots.safe and not self.slots.safe.ref then
    local safe = self:bind_safe()
    if safe then
      self.slots.safe = {
        ref = safe,
        kind = "safe",
        owned = false,
        yielded = false,
        applied = 0,
        released = 0,
        conflicts = 0,
        state = "idle"
      }
    end
  end
  if self.slots.dormant and not self.slots.dormant.ref then
    local dormant = self:find({ "Aimbot", "Ragebot", "Main", "Enabled", "Dormant Aimbot" })
    if dormant and type(self:effective(dormant)) == "boolean" then
      self.slots.dormant = {
        ref = dormant,
        kind = "dormant",
        owned = false,
        yielded = false,
        applied = 0,
        released = 0,
        conflicts = 0,
        state = "idle"
      }
    end
  end
  if self.slots.extrap and not self.slots.extrap.ref then
    local extrap = self:bind_extrapolation()
    if extrap then
      self.slots.extrap = {
        ref = extrap,
        kind = "extrap",
        owned = false,
        yielded = false,
        applied = 0,
        released = 0,
        conflicts = 0,
        state = "idle"
      }
    end
  end
  if not self.fake_latency_ref then
    self.fake_latency_ref = self:find({ "Miscellaneous", "Main", "Other", "Fake Latency" })
  end
end
function N:conflict(s, reason)
  if not s.yielded then
    s.conflicts = s.conflicts + 1
  end
  s.yielded, s.state = true, reason
  warn_once("native_conflict_" .. s.kind, reason .. ". Anemone yielded; check other scripts and then toggle the feature OFF/ON.")
end
function N:release(key)
  local s = self.slots[key]
  if not s or not s.owned then
    return true
  end
  local ok, base, current = self:read(s.ref)
  if not ok then
    s.release_failed = true
    s.state = "release read failed; check native menu"
    warn_once("release_read_" .. key, s.state)
    return false
  end
  if current ~= s.written then
    s.owned, s.counted = false, false
    s.release_failed = false
    self:conflict(s, "native " .. key .. " changed externally")
    return true
  end
  if s.retry_at and clock() < s.retry_at then
    return false
  end
  s.retry_at = clock() + 0.5
  local released = pcall(function ()
    s.ref:override()
  end)
  local read, _, after = self:read(s.ref)
  if released and read and after == nil then
    if s.counted then
      s.released = s.released + 1
    end
    s.owned, s.counted, s.retry_at = false, false, nil
    s.release_failed = false
    s.state = "released; native config retained"
    return true
  end
  if read and after ~= s.written then
    s.owned, s.counted = false, false
    s.release_failed = false
    self:conflict(s, "native " .. key .. " changed during release")
    return true
  end
  s.release_failed = true
  s.state = "release not verified; check native menu"
  warn_once("release_failed_" .. key, s.state)
  return false
end
function N:release_all()
  local safe_ok = self:release("safe")
  local body_ok = self:release("body")
  local dormant_ok = self:release("dormant")
  local extrap_ok = self:release("extrap")
  local air_ok=self:release("air_strafe")
  return safe_ok and body_ok and dormant_ok and extrap_ok and air_ok
end
function N:reset(key)
  local ok
  if key then
    ok = self:release(key)
  else
    ok = self:release_all()
  end
  if ok then
    for name, s in pairs(self.slots) do
      if key == nil or key == name then
        s.yielded, s.retry_at = false, nil
        s.release_failed = false
        s.state = s.ref and "idle" or "unavailable"
      end
    end
  end
  return ok
end
function N:satisfied(s, base, desired)
  if s.kind == "dormant" or s.kind == "air_strafe" then
    return base == desired
  end
  if s.kind == "extrap" then
    return type(base) == "number" and type(desired) == "number" and base == desired
  end
  local actual, wanted = SAFE_RANK[base], SAFE_RANK[desired]
  return actual ~= nil and wanted ~= nil and actual >= wanted
end
function N:request(key, desired)
  local s = self.slots[key]
  if not s then
    return "unavailable"
  end
  if desired == nil then
    if not self:release(key) then
      return s.state
    end
    if not s.yielded then
      s.state = s.ref and "native unchanged" or "unavailable"
    end
    return s.state
  end
  if not s.ref then
    s.state = "unavailable"
    ;
    return s.state
  end
  if s.release_failed then
    self:release(key)
    return s.state
  end
  if s.yielded then
    return s.state
  end
  local ok, base, current = self:read(s.ref)
  if not ok then
    s.state = "native read failed"
    self:release(key)
    return s.state
  end
  if s.owned then
    if current ~= s.written then
      s.owned, s.counted = false, false
      self:conflict(s, "native " .. key .. " changed externally")
      return s.state
    end
    local base_changed = base ~= s.base and (not s.get_is_effective or base ~= s.written)
    if base_changed then
      local released = self:release(key)
      if released then
        self:conflict(s, "native " .. key .. " config changed while active")
      end
      return s.state
    end
    if current == desired then
      s.state = "Anemone override verified"
      ;
      return s.state
    end
    if not self:release(key) then
      return s.state
    end
    ok, base, current = self:read(s.ref)
    if not ok then
      s.state = "native read failed"
      ;
      return s.state
    end
  end
  if current ~= nil then
    self:conflict(s, "external " .. key .. " override present")
    return s.state
  end
  if self:satisfied(s, base, desired) then
    s.state = "native already satisfies request; unchanged"
    return s.state
  end
  if (s.kind == "safe" and SAFE_RANK[base] == nil) or (s.kind == "dormant" and type(base) ~= "boolean") or (s.kind == "extrap" and type(base) ~= "number") then
    s.state = "unknown native value; unchanged"
    return s.state
  end
  s.base, s.written, s.counted = base, desired, false
  s.owned = true
  local changed = pcall(function ()
    s.ref:override(desired)
  end)
  local verified, after_base, after = self:read(s.ref)
  if changed and verified and after == desired then
    s.applied, s.counted = s.applied + 1, true
    s.get_is_effective = after_base == desired and base ~= desired
    s.state = "Anemone override verified"
    return s.state
  end
  if verified and after ~= desired then
    s.owned = false
  end
  self:conflict(s, "native " .. key .. " assignment not verified")
  self:release(key)
  return s.state
end
function N:fire_state()
  local s = self.slots.safe
  local ok, base, forced = self:read(s and s.ref)
  if not ok then
    return "unavailable", false
  end
  local value = base
  if forced ~= nil then
    value = forced
  end
  return tostring(value), s.owned and forced == s.written or false
end
N:init()
pcall(function ()
  N:request("dormant", nil)
end)
local D = {
  suspended = false,
  fault = nil,
  shots = 0,
  scan_at = - 1,
  counts = { 0, 0, 0, 0, 0, 0 },
  in_game = false,
  alive = false,
  shot_hook = false
}
function D:sync()
  pcall(function ()
    N:request("dormant", nil)
  end)
end
function D:scan()
  self.scan_at = clock()
  self.counts = { 0, 0, 0, 0, 0, 0 }
  self.in_game = globals and globals.is_in_game == true or false
  self.alive = false
  pcall(function () local me=entity.get_local_player();self.alive=me~=nil and me:is_alive() end)
end
function D:fire(event)
end
function D:guard(method, ...)
  local ok, err = pcall(method, self, ...)
  if not ok then
    self.fault = "Dormant stub error"
  end
end
local RATIOS = {
  ["4:3"] = 4 / 3,
  ["3:2"] = 1.5,
  ["16:10"] = 1.6,
  ["5:4"] = 1.25,
  ["16:9"] = 16 / 9
}
local PRESETS = { "4:3", "3:2", "16:10", "5:4", "16:9" }
local ASPECT_SPEED = 9
local aspect_ref
local aspect = { saved = nil, current = nil, last_write = nil, time = nil, yielded = false }
pcall(function ()
  aspect_ref = cvar.r_aspectratio
end)
if not aspect_ref then
  pcall(function ()
    aspect_ref = cvar.find and cvar.find("r_aspectratio")
  end)
end
if not aspect_ref then
  pcall(function ()
    aspect_ref = cvar["r_aspectratio"]
  end)
end
local function screen_ratio()
  local ok, ratio = pcall(function ()
    local size = render.screen_size()
    if number(size.x) and number(size.y) and size.x > 0 and size.y > 0 then
      return size.x / size.y
    end
  end)
  return ok and number(ratio) or nil
end
local function aspect_target()
  local ok, selected = pcall(function ()
    return cfg.presets:get()
  end)
  if ok then
    if type(selected) == "string" and RATIOS[selected] then
      return RATIOS[selected]
    end
    if type(selected) == "table" then
      for i = 1, # PRESETS do
        for _, value in ipairs(selected) do
          if value == PRESETS[i] then
            return RATIOS[PRESETS[i]]
          end
        end
        if selected[PRESETS[i]] == true then
          return RATIOS[PRESETS[i]]
        end
      end
    end
  end
  local valid, raw = pcall(function ()
    return cfg.aspect_value:get()
  end)
  return valid and number(raw) and clamp(raw, 0, 200) * 0.01 or 0
end
local function reset_aspect_state()
  aspect.saved, aspect.current, aspect.last_write = nil, nil, nil
end
local function aspect_read()
  local ok, value = pcall(function ()
    return aspect_ref:float()
  end)
  return ok and number(value) or nil
end
local function aspect_write(value)
  local ok = pcall(function ()
    aspect_ref:float(value)
  end)
  if ok then
    aspect.last_write = value
    ;
    return true
  end
  warn_once("aspect_write", "Aspect Ratio could not be applied. Check cvar access and other aspect scripts.")
  return false
end
local function restore_aspect()
  if aspect.saved == nil or aspect.last_write == nil then
    reset_aspect_state()
    return
  end
  local actual = aspect_read()
  if actual and math.abs(actual - aspect.last_write) < 0.0001 then
    aspect_write(aspect.saved)
  end
  reset_aspect_state()
end
local function aspect_tick()
  local t = clock()
  local dt = aspect.time and clamp(t - aspect.time, 0, 0.1) or 0
  aspect.time = t
  local enabled = get_bool(cfg.aspect)
  if not enabled then
    aspect.yielded = false
  end
  if not aspect_ref or aspect.yielded then
    return
  end
  if not enabled and aspect.saved == nil then
    return
  end
  local actual = aspect_read()
  if actual == nil then
    warn_once("aspect_read", "Cannot read r_aspectratio. No value was forced.")
    return
  end
  if aspect.last_write ~= nil and math.abs(actual - aspect.last_write) > 0.0001 then
    reset_aspect_state()
    aspect.yielded = true
    warn_once("aspect_conflict", "Aspect Ratio changed externally; Anemone yielded. Toggle it OFF/ON to retry.")
    return
  end
  local native = screen_ratio()
  if not native then
    return
  end
  if aspect.saved == nil then
    aspect.saved = actual
    aspect.current = actual > 0 and actual or native
  end
  local raw_target = enabled and aspect_target() or aspect.saved
  local target = raw_target > 0 and raw_target or native
  aspect.current = aspect.current + (target - aspect.current) * (1 - math.exp(- ASPECT_SPEED * dt))
  local settled = math.abs(aspect.current - target) < 0.0005
  local output = settled and raw_target or aspect.current
  if aspect.last_write == nil or math.abs(actual - output) > 0.00001 then
    if not aspect_write(output) then
      restore_aspect()
      aspect.yielded = true
      return
    end
  end
  if settled then
    aspect.current = target
  end
  if settled and not enabled then
    reset_aspect_state()
  end
end
local zxc = {
  beta_kill = { "1", "weak", "sit down" },
  beta_death = { "lucky shot", "not twice" },
  adaptive_kill = {
    "too weak", "sit the fuck down", "one tap, bitch", "try harder", "free frag", "aim diff"
  },
  adaptive_death = {
    "lucky bastard", "enjoy that one", "not impressed", "you needed that", "run it back"
  },
  ultimate_kill = {
    "Another soul for the night.", "The monster was faster.", "Your blood signed the verdict.",
    "The Hellsing order stands.", "You faced the night and blinked.", "Amen. Target erased."
  },
  ultimate_death = {
    "A monster rises again.", "Death is only an intermission.", "You merely delayed the hunt.",
    "The night has not released me.", "Enjoy the silence while it lasts."
  },
  on_kill = true,
  on_death = false
}
function zxc.lines(kind)
  local tier = cfg.version_state.tier()
  return zxc[tier .. "_" .. kind] or zxc.beta_kill
end
function zxc.say(kind)
  local lines = zxc.lines(kind or "kill")
  if #lines == 0 then return end
  local line = lines[math.random(#lines)]
  local command = 'say "' .. tostring(line):gsub('"', '') .. '"'
  if utils and type(utils.console_exec) == "function" then utils.console_exec(command); return end
  if client and type(client.exec) == "function" then client.exec(command); return end
  if client and type(client.execute) == "function" then client.execute(command); return end
  error("console command API unavailable")
end
chain("player_death", function (event)
  local ok, err = pcall(function ()
    if not get_bool(cfg.trash) then return end
    pcall(function ()
      local got, sel = pcall(function () return cfg.trash_trigger:get() end)
      if not got or type(sel) ~= "table" then return end
      local function chosen(name)
        for _, v in ipairs(sel) do
          if v == name or tostring(v):find(name .. "$") then return true end
        end
        return sel[name] == true
      end
      zxc.on_kill, zxc.on_death = chosen("On Kill"), chosen("On Death")
    end)
    local me = entity.get_local_player()
    if not me then return end
    local victim = event and entity.get(event.userid, true) or nil
    local attacker = event and entity.get(event.attacker, true) or nil
    if zxc.on_kill and attacker == me and victim and victim ~= me then zxc.say("kill") end
    if zxc.on_death and victim == me and attacker and attacker ~= me then zxc.say("death") end
  end)
  if not ok then warn_once("trash_death", "TrashTalk: " .. tostring(err):gsub("%c", " "):sub(1, 90)) end
end)
local LTRASH = {
  next = 0,
  active = false
}
function LTRASH.say()
  local command = cfg.version_state.is_ultimate() and "say \"hellsing ultimate\"" or (cfg.version_state.is_plus() and "say \"anemone plus\"" or "say \"anemone production\"")
  if utils and type(utils.console_exec) == "function" then
    utils.console_exec(command)
    ;
    return
  end
  if client and type(client.exec) == "function" then
    client.exec(command)
    ;
    return
  end
  if client and type(client.execute) == "function" then
    client.execute(command)
    ;
    return
  end
  error("console command API unavailable")
end
function LTRASH.tick()
  local now = clock()
  if not globals or globals.is_in_game ~= true then
    LTRASH.active = false
    return
  end
  if not LTRASH.active then
    LTRASH.active = true
    LTRASH.next = now + math.random(300, 600)
    return
  end
  if now < LTRASH.next then
    return
  end
  local ok, err = pcall(LTRASH.say)
  LTRASH.next = now + math.random(300, 600)
  if not ok then
    warn_once("trash_talk", "TrashTalk: " .. tostring(err):gsub("%c", " "):sub(1, 90))
  end
end
local kill_particles = {pool=Y.core.kill or {n=0},max=120}
local function kill_particle_clear()
  kill_particles.pool.n=0
end
local function kill_particle_color()
  local ok, c = pcall(function ()
    return cfg.kill_particle_color:get()
  end)
  if ok and c then
    local r, g, b, a = tonumber(c.r), tonumber(c.g), tonumber(c.b), tonumber(c.a)
    if r and g and b then
      return r, g, b, a or 255
    end
  end
  return 235, 245, 255, 255
end
local function kill_particle_spawn(event)
  if not get_bool(cfg.kill_particles) then
    return
  end
  local me = entity.get_local_player()
  if not me then
    return
  end
  local victim = entity.get(event.userid, true)
  local attacker = entity.get(event.attacker, true)
  if not victim or not attacker or attacker ~= me or victim == me then
    return
  end
  local ok_origin, origin = pcall(function ()
    return victim:get_origin()
  end)
  if not ok_origin or not origin or not number(origin.x) then
    return
  end
  local points = { }
  for hitbox = 0, 18 do
    local ok, point = pcall(function ()
      return victim:get_hitbox_position(hitbox)
    end)
    if ok and point and number(point.x) and number(point.y) and number(point.z) then
      points[# points + 1] = point
    end
  end
  if # points == 0 then
    points[1] = vector(origin.x, origin.y, (origin.z or 0) + 42)
  end
  local distance = 0
  local ok_me, me_origin = pcall(function ()
    return me:get_origin()
  end)
  if ok_me and me_origin and number(me_origin.x) then
    local dx, dy, dz = origin.x - me_origin.x, origin.y - me_origin.y, (origin.z or 0) - (me_origin.z or 0)
    distance = math.sqrt(dx * dx + dy * dy + dz * dz)
  end
  local scale = distance > 0 and clamp(300 / distance, 0.18, 1) or 1
  local ok_amount, amount = pcall(function ()
    return cfg.kill_particle_amount:get()
  end)
  local ok_duration, duration = pcall(function ()
    return cfg.kill_particle_duration:get()
  end)
  amount = clamp(math.floor((ok_amount and tonumber(amount) or 18) + 0.5), 6, 80)
  duration = clamp(ok_duration and tonumber(duration) or 2, 1, 4)
  local now = clock()
  for i = 1, amount do
    if kill_particles.pool.n >= kill_particles.max then
      break
    end
    local point = points[((i - 1) % # points) + 1]
    local angle = math.random() * math.pi * 2
    local spread = 1.5 + math.random() * 4
    local p=Y.core:particle_new(kill_particles.pool)
    if not p then break end
    p.x=point.x + math.cos(angle) * spread;p.y=point.y + math.sin(angle) * spread;p.z=point.z + (math.random() - 0.5) * 5;p.vx=(math.random() - 0.5) * 7;p.vy=(math.random() - 0.5) * 7;p.vz=7 + math.random() * 12;p.size=1 + math.random();p.scale=scale;p.born=now + math.random() * 0.14;p.life=duration * (0.82 + math.random() * 0.18);p.phase=math.random() * math.pi * 2
  end
end
local function kill_particle_tick()
  if not get_bool(cfg.kill_particles) then
    if kill_particles.pool.n > 0 then
      kill_particle_clear()
    end
    return
  end
  local now = clock()
  local cr, cg, cb, ca = kill_particle_color()
  local i = 0
  while i < kill_particles.pool.n do
    local p = kill_particles.pool.buffer[i]
    local age = now - p.born
    if age > p.life then
      Y.core:particle_remove(kill_particles.pool,i)
    elseif age < 0 then
      i = i + 1
    else
      local progress = age / p.life
      local drag = 1 - progress * 0.28
      local drift = math.sin(age * 4 + p.phase) * 1.2
      local pos = vector(p.x + p.vx * age * drag + drift, p.y + p.vy * age * drag - drift * 0.5, p.z + p.vz * age - 5.5 * age * age + 2 * math.sin(progress * math.pi))
      local ok_screen, screen = pcall(render.world_to_screen, pos)
      if ok_screen and screen and number(screen.x) and number(screen.y) then
        local appear = math.min(1, age / 0.12)
        local fade = 1 - math.max(0, (progress - 0.55) / 0.45)
        local alpha = math.floor(ca * appear * fade)
        local pulse = 1 + math.sin(age * 7 + p.phase) * 0.12
        local radius = math.max(1, math.floor(p.size * pulse * p.scale + 0.5))
        local center = vector(screen.x, screen.y)
        local ft=number(globals.frametime)or 0
        if ft<1/60 then
          render.circle(center, color(cr, cg, cb, math.floor(alpha * 0.07)), radius + 3, 0, 1)
          render.circle(center, color(cr, cg, cb, math.floor(alpha * 0.15)), radius + 2, 0, 1)
        end
        render.circle(center, color(cr, cg, cb, math.floor(alpha * 0.30)), radius + 1, 0, 1)
        render.circle(center, color(math.min(255, cr + 18), math.min(255, cg + 18), math.min(255, cb + 18), alpha), radius, 0, 1)
        render.circle(vector(screen.x - radius * 0.3, screen.y - radius * 0.3), color(255, 255, 255, math.floor(alpha * 0.7)), math.max(0.6, radius * 0.3), 0, 1)
      end
      i = i + 1
    end
  end
end
chain("player_death", function (event)
  local ok, err = pcall(kill_particle_spawn, event)
  if not ok then
    warn_once("kill_particles_death", "Kill Particles: " .. tostring(err):gsub("%c", " "):sub(1, 90))
  end
end)
chain("round_start", kill_particle_clear)
local rng = math.floor(clock() * 1000) % 2147483646 + 1
local function random_unit()
  rng = (rng * 48271) % 2147483647
  return rng / 2147483647
end
local CLAN_BETA_FRAMES = {
  "⣀anemone⣿", "⣀anemone⣿",
  "⣤anemone⣶", "⣤anemone⣶",
  "⣶anemone⣤", "⣶anemone⣤",
  "⣿anemone⣀", "⣿anemone⣀",
  "⣶anemone⣤", "⣶anemone⣤",
  "⣤anemone⣶", "⣤anemone⣶",
  "⣀anemone⣿", "⣀anemone⣿"
}
local CLAN_ULTIMATE_FRAMES = { "† hellsing †", "† ultimate †" }
cfg.version_state.clan_adaptive_frames = {
  "⣀anemone⣿", "⣀anemone⣿",
  "⣤anemone⣶", "⣤anemone⣶",
  "⣶anemone⣤", "⣶anemone⣤",
  "⣿anemone⣀", "⣿anemone⣀",
  "⣶anemone⣤", "⣶anemone⣤",
  "⣤anemone⣶", "⣤anemone⣶",
  "⣀anemone⣿", "⣀anemone⣿"
}
local clan = { last = nil, owned = false, failed = false, prev = "" }
local function release_clan()
  if clan.owned then
    pcall(function () common.set_clan_tag("\0") end)
  end
  clan.last, clan.owned, clan.prev = nil, false, ""
end
local function clan_tick()
  if not get_bool(cfg.clantag) then release_clan(); clan.failed=false; return end
  if not globals or not globals.is_in_game or clan.failed then return end
  local epoch
  pcall(function () epoch=number(common.get_unixtime()) end)
  if not epoch then pcall(function () epoch=os and os.time and number(os.time()) end) end
  local tag=epoch and CLAN_BETA_FRAMES[(math.floor(epoch)%#CLAN_BETA_FRAMES)+1] or "anemone"
  if tag==clan.prev then return end
  local ok=pcall(function () common.set_clan_tag(tag) end)
  if ok then clan.prev,clan.last,clan.owned=tag,tag,true else clan.failed=true; warn_once("clan","ClanTag API unavailable.") end
end
local UR = {
  pending = nil,
  watching = nil,
  spent = false,
  cooldown_until = 0,
  fault = nil,
  ready = false,
  commands = nil,
  suspended = false,
  state = "OFF",
  requests = 0,
  attempts = 0,
  observed_full = 0,
  timeouts = 0,
  expired = 0,
  shot_events = 0,
  charge_value = nil,
  last_result = "none",
  scope = nil,
  last_shot_id = nil,
  last_shot_time = 0
}
local RECHARGE_TOOLTIP = "Double Tap recharge request after verified full-to-partial spend. Allows natural charge once per cycle; does not call force_charge or force a tick burst, after burst separation; no attack/use/reload/rollback phase. Observed completion is reported separately. OFF by default."
tooltip(cfg.unsafe_recharge, RECHARGE_TOOLTIP)
function UR:log(text, always)
  if always then
    console_line("[Anemone Recharge] " .. text)
  end
end
function UR:reset(reason)
  self.pending, self.watching, self.spent, self.cooldown_until = nil, nil, false, 0
  self.commands, self.fault, self.scope = nil, nil, nil
  self.read_strikes = 0
  self.local_tb=nil
  self.last_charge, self.last_charge_t, self.charge_rate_v = nil, nil, nil
  self.full_baseline=nil;self.charge_value=nil;self.last_shot_id=nil;self.last_shot_time=0
  self.state = reason or "reset"
  tooltip(cfg.unsafe_recharge, RECHARGE_TOOLTIP)
end
function UR:charge()
  local ok, value = pcall(function ()
    return rage.exploit:get()
  end)
  if ok and number(value) and value >= 0 and value <= 1 then
    return value
  end
  return nil
end
function UR:charge_rate(t, charge)
  local last, last_t = self.last_charge, self.last_charge_t
  self.last_charge, self.last_charge_t = charge, t
  if last and last_t and t > last_t then
    local dt = t - last_t
    if dt > 0.001 and dt < 0.25 then
      if charge < last - 0.05 then
        self.charge_rate_v = nil
        return nil
      end
      local rate = (charge - last) / dt
      self.charge_rate_v = (self.charge_rate_v or 0) * 0.70 + rate * 0.30
    end
  end
  return self.charge_rate_v
end
function UR.rate_lim(rate, base, floor)
  if not rate then
    return base
  end
  if rate > 0.60 then
    return math.max(floor, base - 0.30)
  elseif rate > 0.35 then
    return math.max(floor, base - 0.20)
  elseif rate > 0.15 then
    return math.max(floor, base - 0.10)
  end
  return base
end
function UR:local_timing()
  local shared=Y.observation_bridge and Y.observation_bridge:local_timing()
  if shared then return shared end
  local ok,state=pcall(function ()
    local me=entity.get_local_player();if not me then return nil end
    local info=me:get_player_info()
    return Y.record_tools.local_tickbase(self.local_tb,number(globals.tickcount),number(me.m_nTickBase),info and info.userid)
  end)
  if ok then self.local_tb=state end
  return ok and state or nil
end
function UR:tickbase_ready()
  local ok, ready = pcall(function ()
    local me = entity.get_local_player()
    if not me then return nil end
    local tickbase = number(me.m_nTickBase)
    if tickbase == nil then pcall(function () tickbase = number(entity.get_prop(me, "m_nTickBase")) end) end
    local tickcount = globals and number(globals.tickcount)
    if not tickbase or not tickcount then return nil end
    return math.floor(tickbase - tickcount - 3) <= -11
  end)
  return ok and ready or nil
end
function UR:context()
  if self.suspended then return nil, "config / unload paused" end
  if not globals or globals.is_in_game ~= true then return nil, "not in game" end
  if not N:master_enabled() then return nil, "native Ragebot OFF / unavailable" end
  if N:effective(self.dt) ~= true then return nil, "Double Tap OFF / unavailable" end
  local ok, ctx, reason = pcall(function ()
    local me = entity.get_local_player()
    if not me then return nil, "no local player" end
    if not me:is_alive() then return nil, "local player dead" end
    local weapon = me:get_player_weapon()
    if not weapon or not weapon:is_weapon() then return nil, "no weapon" end
    local info = weapon:get_weapon_info()
    if not info or not number(info.max_clip1) or info.max_clip1 <= 1 or info.is_revolver == true then
      return nil, "unsupported weapon (grenade/knife/revolver/single-round)"
    end
    local id = weapon:get_index()
    local player_info = me:get_player_info()
    local uid = player_info and player_info.userid
    if not number(id) or not number(uid) then return nil, "weapon/player identity unavailable" end
    return { weapon = id, user = uid }
  end)
  if not ok then return nil, "context read failed" end
  return ctx, reason
end
function UR:on_shot(event)
  if not self.ready or self.fault or self.suspended or not get_bool(cfg.unsafe_recharge) or not event then return end
  local now, shot_id = clock(), tonumber(event.id)
  if shot_id and self.last_shot_id == shot_id and now - self.last_shot_time < 0.25 then return end
  self.last_shot_id, self.last_shot_time = shot_id, now
  self.shot_events = self.shot_events + 1
  local ctx, reason = self:context()
  local charge = self:charge()
  if not ctx or charge == nil then
    self.pending = nil
    self.state = reason or "charge unreadable"
    return
  end
  if charge >= 0.99 and not self.watching then self.spent = false end
  if self.spent or self.watching or now < self.cooldown_until then return end
  local baseline=self.full_baseline
  local full_spend=baseline and baseline.user==ctx.user and baseline.weapon==ctx.weapon and now>=baseline.time and now-baseline.time<=0.5 and charge<0.94
  if self.pending and self.pending.user==ctx.user and self.pending.weapon==ctx.weapon and now>=self.pending.time and now-self.pending.time<0.25 then
    self.pending.discharge_seen=self.pending.discharge_seen or full_spend or (number(self.charge_value) and charge<self.charge_value-0.05) or false
    self.merged_shots=(self.merged_shots or 0)+1
    return
  end
  self.pending = {
    weapon = ctx.weapon,
    user = ctx.user,
    time = now,
    steps = 0,
    initial = charge,
    prior = self.charge_value,
    discharge_seen = full_spend or (number(self.charge_value) and charge<self.charge_value-0.05) or false,
    id = shot_id,
  }
  self.scope = tostring(ctx.user) .. ":" .. tostring(ctx.weapon)
  self.state = "queued; waiting for verified charge expenditure"
end
function UR:step(cmd)
  if not self.ready then
    self.state = "unavailable"
    ;
    return
  end
  if self.suspended then
    self.state = "config / unload paused"
    ;
    return
  end
  if self.fault then
    self.state = self.fault
    ;
    return
  end
  if not get_bool(cfg.unsafe_recharge) then
    self.pending, self.watching, self.spent = nil, nil, false
    ;
    self.state = "OFF"
    ;
    return
  end
  local valid, seq = pcall(function ()
    return number(cmd.command_number)
  end)
  if not valid or not seq then
    self.state = "command number unavailable"
    ;
    return
  end
  if seq == self.commands then
    return
  end
  if self.commands and seq < self.commands then
    self:reset("command sequence reset")
  end
  self.commands = seq
  local ctx, reason = self:context()
  if not ctx then
    self.pending, self.watching, self.spent, self.scope = nil, nil, false, nil
    self.state = reason
    ;
    return
  end
  local scope = tostring(ctx.user) .. ":" .. tostring(ctx.weapon)
  if self.scope and self.scope ~= scope then
    self.pending, self.watching, self.spent = nil, nil, false
    self.state = "weapon/player changed; old request cancelled"
  end
  self.scope = scope
  local local_timing=self:local_timing()
  if Y.observation_bridge and local_timing then Y.observation_bridge:consume("unsafe") end
  local charge = self:charge()
  local previous_charge=self.charge_value
  self.charge_value = charge
  if charge and charge>=0.99 then self.full_baseline={user=ctx.user,weapon=ctx.weapon,time=clock()} end
  if self.pending and number(previous_charge) and charge and charge<previous_charge-0.05 then self.pending.discharge_seen=true end
  if charge == nil then
    self.pending, self.watching = nil, nil
    self.read_strikes = (self.read_strikes or 0) + 1
    if self.read_strikes >= 3 then
      self.read_strikes = 0
      self.fault = "Cannot read exploit charge"
      ;
      self.state = self.fault
      self:log(self.fault .. "; no request issued. Toggle OFF/ON to retry.", true)
      ;
      return
    end
    self.state = string.format("charge read failed (%d/3)", self.read_strikes)
    return
  end
  self.read_strikes = 0
  local t = clock()
  if self.watching then
    local w = self.watching
    if charge >= 0.99 then
      self.observed_full = self.observed_full + 1
      self.last_result = string.format("full charge observed %.3fs after request (causation not proven)", t - w.time)
      self.watching, self.spent = nil, false
    elseif t < w.time or t - w.time > 2.0 then
      self.timeouts = self.timeouts + 1
      self.last_result = "no full charge observed within 2.0s; cycle released, no automatic retry"
      self.watching, self.spent = nil, false
    else
      w.best = math.max(w.best or w.initial or 0, charge)
      if charge < (w.spent_lim or 0.95) and charge < (w.best or 0) - 0.005 then
        self.observed_spend = (self.observed_spend or 0) + 1
        self.last_result = string.format("charge expenditure observed %.3fs after request (%.1f%% -> %.1f%%)", t - w.time, (w.best or 0) * 100, charge * 100)
        self.watching, self.spent = nil, false
        return
      end
      self.state = string.format("request sent; observed charge %.1f%%", charge * 100)
      return
    end
  elseif charge >= 0.99 then
    self.spent = false
  end
  local p = self.pending
  if not p then
    self.state = self.spent and "cycle spent; waiting for full charge / toggle reset" or (charge >= 0.99 and "charged; waiting for shot" or "waiting for ragebot shot")
    return
  end
  if p.weapon ~= ctx.weapon or p.user ~= ctx.user or t < p.time or t - p.time > 0.8 then
    self.pending = nil
    ;
    self.expired = self.expired + 1
    self.state = "pending request expired / context changed"
    ;
    return
  end
  p.steps = p.steps + 1
  local rate=self:charge_rate(t,charge)
  local unsafe, spend_lim, min_steps, min_dt, cooldown = true, UR.rate_lim(rate,0.88,0.58), 2, nil, 0.24
  if not p.discharge_seen then self.state="queued; no measured charge drop after shot";return end
  if command_attack(cmd) or cmd.in_use==true or cmd.in_reload==true or (local_timing and local_timing.status=="local rollback") then
    self.state="queued; local attack/use/reload/defensive phase";return
  end
  if charge >= spend_lim then
    self.state = "queued; waiting for verified charge expenditure"
    ;
    return
  end
  if not unsafe and p.initial and p.initial < 0.95 and math.abs(charge - p.initial) < 0.005 and p.steps < 3 then
    self.state = "queued; confirming stable partial charge"
    ;
    return
  end
  local interval = globals and number(globals.tickinterval)
  if not interval or interval <= 0 or interval > 0.1 then
    self.state = "tick interval unavailable"
    ;
    return
  end
  min_dt = min_dt or interval * min_steps
  if p.steps < min_steps or t - p.time < min_dt then
    self.state = "queued; burst separation"
    ;
    return
  end
  if self.spent or t < self.cooldown_until then
    self.state = "queued; cycle cooldown"
    ;
    return
  end
  self.pending, self.cooldown_until = nil, t + (cooldown or 0.35)
  self.attempts = self.attempts + 1
  local ok, err = pcall(function ()
    rage.exploit:allow_charge(true)
  end)
  if not ok then
    self.spent = false
    self.force_failures=(self.force_failures or 0)+1
    self.cooldown_until = t + 0.50
    self.pending=nil;self.full_baseline=nil
    self.fault="Recharge API error; request result unknown; toggle OFF/ON to retry"
    self.state=self.fault
    self:log("Recharge request failed: " .. tostring(err):gsub("%c", " "), true)
    ;
    return
  end
  self.spent = true
  self.requests = self.requests + 1
  self.permission_requests=(self.permission_requests or 0)+1
  self.full_baseline=nil
  self.watching = { time = t, initial = charge, best = charge, spent_lim = spend_lim }
  self.state = "natural charge allowed once; waiting for observed completion (no forced burst)"
end
function UR:idle()
  if self.suspended or self.fault or not self.ready then
    return
  end
  if not get_bool(cfg.unsafe_recharge) then
    self.pending,self.watching,self.spent,self.scope,self.full_baseline=nil,nil,false,nil,nil
    self.state="OFF";return
  end
  local ctx, reason = self:context()
  if not ctx then
    self.pending, self.watching, self.spent, self.scope = nil, nil, false, nil
    self.state = not get_bool(cfg.unsafe_recharge) and "OFF" or reason
  elseif self.pending and clock() - self.pending.time > 0.8 then
    self.pending = nil
    ;
    self.expired = self.expired + 1
    ;
    self.state = "pending request expired"
  end
end
function UR:guard(method, ...)
  local ok, err = pcall(method, self, ...)
  if not ok then
    self.pending, self.watching = nil, nil
    ;
    self.fault = "Recharge callback error"
    ;
    self.state = self.fault
    warn_once("recharge_callback", tostring(err):gsub("%c", " "))
  end
end
do
  UR.dt = N:find({ "Aimbot", "Ragebot", "Main", "Double Tap" })
  local api = pcall(function ()
    assert(type(rage.exploit.allow_charge) == "function")
    ;
    assert(type(rage.exploit.get) == "function")
    assert(Y.core.ready,"FFI core unavailable")
  end)
  UR.api_ready = UR.dt ~= nil and type(N:effective(UR.dt)) == "boolean" and api
  UR.ready = UR.api_ready
  if not UR.ready then
    cfg.unsafe_recharge:set(false)
    ;
    cfg.unsafe_recharge:disabled(true)
    tooltip(cfg.unsafe_recharge, "Unavailable: native Double Tap / charge-permission API missing.")
    warn_once("recharge_unavailable", "Unsafe Recharge unavailable in this build.")
  end
  cfg.unsafe_recharge:set_callback(function ()
    UR:reset("switch changed")
  end)
end
local R = {
  players = { },
  shots = { },
  epoch = 1,
  sequence = 0,
  ready = false,
  fault = nil,
  last_clock = clock(),
  last_command = nil,
  last_step = nil,
  last_frame = - 1,
  local_uid = nil,
  in_session = false,
  suspended = false,
  simulated = 0,
  simulation_skips = 0,
  defensive_signals = 0,
  correction_signals = 0,
  next_simulation = 0,
  prediction_fault = nil,
  prediction_fault_strikes = 0,
  fault_until = nil,
  plan = "starting",
  prediction_state = "waiting",
  status_cache = { },
  status_at = - 1,
  net_count = 0,
  command_count = 0,
  ack_fallbacks = 0,
}
local FS = {
  count = 0,
  state = "OFF",
  hc = { },
  active = false
}
function FS:mode()
  return "Adaptive"
end
FS.adaptive_thresholds = {
  scout = { air = { p = 0.007, w = 0.080 }, land = { p = 0.003, w = 0.035 }, noscope = { p = 0.040, w = 0.120 } },
  awp = { air = { p = 0.010, w = 0.100 }, land = { p = 0.001, w = 0.025 }, noscope = { p = 0.030, w = 0.100 } },
  auto = { air = { p = 0.008, w = 0.090 }, land = { p = 0.002, w = 0.030 }, noscope = { p = 0.025, w = 0.080 } },
  deagle = { air = { p = 0.020, w = 0.150 }, land = { p = 0.004, w = 0.050 }, noscope = { p = 0.004, w = 0.050 } },
  revolver = { air = { p = 0.015, w = 0.120 }, land = { p = 0.003, w = 0.040 }, noscope = { p = 0.003, w = 0.040 } },
  pistol = { air = { p = 0.020, w = 0.120 }, land = { p = 0.005, w = 0.045 }, noscope = { p = 0.005, w = 0.045 } },
}
function FS:weapon_kind(weapon)
  local id
  pcall(function () id = tonumber(weapon.m_iItemDefinitionIndex) end)
  if not number(id) then
    pcall(function () id = tonumber(entity.get_prop(weapon, "m_iItemDefinitionIndex")) end)
  end
  if id == 40 then return "scout", id end
  if id == 38 or id == 11 then return "auto", id end
  if id == 9 then return "awp", id end
  if id == 2 or id == 3 or id == 4 or id == 30 or id == 32 or id == 36 or id == 61 or id == 63 then return "pistol", id end
  if id == 64 then return "revolver", id end
  if id == 1 then return "deagle", id end
  if id == 7 or id == 8 or id == 10 or id == 13 or id == 16 or id == 17 or id == 19 or id == 23 or id == 24 or id == 26 or id == 27 or id == 28 or id == 29 or id == 33 or id == 34 or id == 39 or id == 60 then return "pistol", id end
  return nil, id
end
function FS:adaptive_hitchance()
  local me, weapon
  pcall(function () me = entity.get_local_player() end)
  if not me then return nil, "local unavailable" end
  pcall(function () weapon = me:get_player_weapon() end)
  if not weapon then pcall(function () weapon = entity.get_player_weapon(me) end) end
  if not weapon then return nil, "weapon unavailable" end
  local kind = self:weapon_kind(weapon)
  local threshold = kind and self.adaptive_thresholds[kind] or nil
  if not threshold then return nil, "unsupported weapon" end
  local flags
  pcall(function () flags = tonumber(me.m_fFlags) end)
  if flags == nil then pcall(function () flags = tonumber(entity.get_prop(me, "m_fFlags")) end) end
  local on_ground = flags ~= nil and flag_set(flags, 1) or false
  if not on_ground then return nil, "air blocked" end
  local scoped = false
  pcall(function () scoped = tonumber(me.m_bIsScoped) == 1 end)
  if not scoped then pcall(function () scoped = tonumber(entity.get_prop(me, "m_bIsScoped")) == 1 end) end
  local region = not scoped and threshold.noscope or threshold.land
  local penalty
  pcall(function () penalty = tonumber(weapon.m_fAccuracyPenalty) end)
  if penalty == nil then pcall(function () penalty = tonumber(entity.get_prop(weapon, "m_fAccuracyPenalty")) end) end
  if not number(penalty) then return nil, "accuracy penalty unavailable" end
  local base_hc = tonumber(self.base_hc)
  if not base_hc then
    for _, h in ipairs(self.hc or {}) do
      local ok, value = pcall(function () return tonumber(h.ref:get()) end)
      if ok and number(value) then base_hc = value; break end
    end
  end
  if not base_hc then return nil, "base hitchance unavailable" end
  self.base_hc = base_hc
  local width = math.max(0.0001, region.w - region.p)
  local accuracy_factor = clamp(1 - (penalty - region.p) / width, 0, 1)
  local vx, vy = 0, 0
  pcall(function ()
    local v = me.m_vecVelocity
    if v then vx, vy = number(v.x) or 0, number(v.y) or 0 end
  end)
  if vx == 0 and vy == 0 then
    pcall(function () vx = tonumber(entity.get_prop(me, "m_vecVelocity[0]")) or 0 end)
    pcall(function () vy = tonumber(entity.get_prop(me, "m_vecVelocity[1]")) or 0 end)
  end
  local speed = math.sqrt(vx * vx + vy * vy)
  local speed_factor = speed <= 2 and 1 or (speed >= 85 and 0 or 1 - (speed - 2) / 83)
  local quality = clamp(math.min(accuracy_factor, speed_factor), 0, 1)
  quality = quality * quality * (3 - 2 * quality)
  local floor_hc = math.min(base_hc, 15 + 40 * (1 - quality))
  local result = floor_hc + (base_hc - floor_hc) * (1 - quality)
  result = clamp(math.floor(result + 0.5), 1, math.floor(base_hc + 0.5))
  return result, string.format("%s penalty=%.3f speed=%.0f quality=%.2f", kind, penalty, speed, quality)
end
function FS:release_hc()
  local stuck=0
  for _,h in ipairs(self.hc) do
    if h.owned then
      local ok,current=pcall(function () return h.ref:get_override() end)
      if not ok then stuck=stuck+1
      elseif current~=h.written then h.owned,h.written=false,nil
      else
        pcall(function () h.ref:override() end)
        local read,after=pcall(function () return h.ref:get_override() end)
        if read and (after==nil or after==false) then h.owned,h.written=false,nil else stuck=stuck+1 end
      end
    end
  end
  self.active=false;self.base_hc=nil;self.hc_value=nil;self.hc_reason=nil
  if stuck>0 then self.state="HC release unverified";warn_once("forceshot_release","ForceShot HC release unverified; check native menu") end
  return stuck==0
end
function FS:bind_hc()
  if # self.hc > 0 then
    return true
  end
  local cands = {
    { "Aimbot", "Ragebot", "Selection", "Hit Chance" },
    { "Aimbot", "Ragebot", "Accuracy", "Hit Chance" },
    { "Aimbot", "Ragebot", "Main", "Hit Chance" },
    { "Aimbot", "Ragebot", "Selection", "Hitchance" },
  }
  local seen, found, bad_value = { }, 0, 0
  for _, p in ipairs(cands) do
    local ok, ref = pcall(function ()
      return ui.find(p[1], p[2], p[3], p[4])
    end)
    if ok and ref and not seen[ref] then
      seen[ref] = true
      found = found + 1
      local rok, v = pcall(function ()
        return ref:get()
      end)
      if rok and number(v) then
        self.hc[# self.hc + 1] = { ref = ref }
      else
        bad_value = bad_value + 1
      end
    end
  end
  self.bind_found, self.bind_bad_value = found, bad_value
  if # self.hc == 0 and found > 0 and bad_value == found then
    self.state = string.format("hitchance slot found (%d) but not numeric in this build", found)
  end
  return # self.hc > 0
end
function FS:valid_threat()
  local ok, threat = pcall(function ()
    return entity.get_threat()
  end)
  if not ok or not threat then
    return nil
  end
  local alive, enemy, dormant = false, false, true
  pcall(function ()
    alive = threat:is_alive()
  end)
  pcall(function ()
    enemy = threat:is_enemy()
  end)
  pcall(function ()
    dormant = threat:is_dormant()
  end)
  if not alive or not enemy or dormant then
    return nil
  end
  return threat
end
function FS:prediction_clean(threat)
  if not get_bool(cfg.extrapolation) then
    return true
  end
  if R.prediction_fault then
    return false
  end
  local slot = nil
  pcall(function ()
    slot = threat:get_index()
  end)
  if not number(slot) then
    return false
  end
  local s = R.players and R.players[slot]
  local p = s and s.prediction
  if not p then
    return false
  end
  local live=R:snapshot(threat);local iv=R:interval();local now=clock()
  if not live or not iv or not Y.core:prediction_match(live,iv,p.ticks,now)then return false end
  if now < (p.time or 0)or now - (p.time or 0) > 0.10 then
    return false
  end
  if p.collision then
    return false
  end
  if (number(p.divergence) or 999) > 12 then
    return false
  end
  if (number(p.velocity_change) or 999) > 220 then
    return false
  end
  return true
end
function FS:stopped()
  local ok, me = pcall(function ()
    return entity.get_local_player()
  end)
  if not ok or not me then
    return false
  end
  local alive = false
  pcall(function ()
    alive = me:is_alive()
  end)
  if not alive then
    return false
  end
  local flags = nil
  pcall(function ()
    flags = number(me.m_fFlags)
  end)
  if flags == nil then
    pcall(function ()
      flags = number(entity.get_prop(me, "m_fFlags"))
    end)
  end
  local ground = flags ~= nil and flag_set(flags, 1) or false
  if not ground then
    return false
  end
  local vel = nil
  pcall(function ()
    vel = me.m_vecVelocity
  end)
  if not vel then
    return false
  end
  local sp = math.sqrt((number(vel.x) or 0) ^ 2 + (number(vel.y) or 0) ^ 2)
  return sp < 10
end
function FS:self_speed()
  local ok, speed = pcall(function ()
    local me = entity.get_local_player()
    if not me or not me:is_alive() then return nil end
    local vel = me.m_vecVelocity
    if not vel then return nil end
    local vx, vy = number(vel.x) or 0, number(vel.y) or 0
    return math.sqrt(vx * vx + vy * vy)
  end)
  return ok and speed or nil
end
FS.spread_sampler=(function()
local function create_forceshot_sampler(env)
  local M={samples=64,interval=0.10,time_budget_us=2000,evaluations=0,rays=0,cache_hits=0,waits=0,partial=0,rejections=0,ready=0,last="waiting",serial=0}
  local function finite(x)return type(x)=="number"and x==x and math.abs(x)<math.huge end
  local function vec(v)return type(v)=="table"and finite(v.x)and finite(v.y)and finite(v.z)end
  function M:clear()self.cache=nil;self.last_start=nil;self.last="cleared"end
  function M.minimum_damage(setting,hp)
    if not finite(setting)or setting<=0 or setting>200 or not finite(hp)or hp<=0 then return nil end
    return setting>100 and hp+setting-100 or setting
  end
  function M.summarize(damage,directions,origin,point,minimum,hp,bank)
    if (not bank and (type(damage)~="table"or #damage~=64 or type(directions)~="table"or #directions~=64))or not vec(origin)or not vec(point)or not finite(minimum)or minimum<=0 or not finite(hp)or hp<=0 then return nil,"invalid sampler data"end
    local hits,player_hits,lethal=0,0,0
    local cap=minimum*(1+math.max(0,minimum/hp-1)*2.5)
    local sx,sy,sz,weight=0,0,0,0
    for seed=1,64 do
      local dir=bank and bank[seed-1]or directions[seed]
      local d=bank and tonumber(dir.damage)or damage[seed]
      if not finite(d)or d<0 or not (bank and finite(tonumber(dir.x))and finite(tonumber(dir.y))and finite(tonumber(dir.z))or not bank and vec(dir))then return nil,"invalid seed result"end
      if d>=minimum then hits=hits+1 end
      if d>0 then player_hits=player_hits+1 end
      if d>=hp then lethal=lethal+1 end
      -- The CS2 mask-selection predicate isn't supplied; choose and label our own policy.
      if (minimum<hp and d>0)or (minimum>=hp and d>=hp)then
        local w=math.min(cap,d);sx=sx+dir.x*w;sy=sy+dir.y*w;sz=sz+dir.z*w;weight=weight+w
      end
    end
    local result={hits=hits,hc=hits*100/64,all_pass=hits==64,player_hits=player_hits,lethal_hits=lethal,damage_cap=cap,mask_policy=minimum<hp and "observed player rays"or "observed lethal rays"}
    if weight>0 then
      local x,y,z=sx/weight,sy/weight,sz/weight
      local distance=(point.x-origin.x)*x+(point.y-origin.y)*y+(point.z-origin.z)*z
      result.proposed_point={x=origin.x+x*distance,y=origin.y+y*distance,z=origin.z+z*distance}
      local q=result.proposed_point
      result.shift=math.sqrt((q.x-point.x)^2+(q.y-point.y)^2+(q.z-point.z)^2)
    end
    return result
  end
  function M:evaluate(c,minimum)
    if not env.core or not env.core.ready then return nil,"FFI core unavailable"end
    if type(c)~="table"or not vec(c.origin)or not vec(c.point)or not finite(c.inaccuracy)or not finite(c.spread)or c.inaccuracy<0 or c.spread<0 or c.inaccuracy+c.spread>1 or not finite(c.hp)or c.hp<=0 or not finite(minimum)or minimum<=0 or type(c.key)~="string"then self.rejections=self.rejections+1;return nil,"invalid spread context"end
    local now=env.now();if not finite(now)then return nil,"clock unavailable"end
    if self.cache and self.cache.key==c.key and now>=self.cache.time and now-self.cache.time<=self.interval then
      self.cache_hits=self.cache_hits+1;return self.summarize(nil,nil,c.origin,c.point,minimum,c.hp,self.cache.bank)
    end
    if self.last_start and now>=self.last_start and now-self.last_start<self.interval then self.waits=self.waits+1;self.last="rate budget; native HC unchanged";return nil,self.last end
    self.last_start=now;self.evaluations=self.evaluations+1
    local dx,dy,dz=c.point.x-c.origin.x,c.point.y-c.origin.y,c.point.z-c.origin.z
    local length=math.sqrt(dx*dx+dy*dy+dz*dz)
    if length<1 then return nil,"target too close for spread estimate"end
    local fx,fy,fz=dx/length,dy/length,dz/length
    local horizontal=math.sqrt(fx*fx+fy*fy)
    if horizontal<0.01 then return nil,"vertical aim estimate unavailable"end
    local rx,ry=-fy/horizontal,fx/horizontal
    local ux,uy,uz=-fz*ry,fz*rx,fx*ry-fy*rx
    local bank_index=self.cache and (1-self.cache.bank_index)or 0
    local bank=env.core.ray_banks[bank_index]
    local endpoint={x=0,y=0,z=0}
    local started=env.time_us and env.time_us()
    for seed=1,64 do
      if started and env.time_us then
        local t=env.time_us()
        if t and t>=started and t-started>self.time_budget_us then self.partial=self.partial+1;self.last="time budget exceeded; incomplete estimate discarded";return nil,self.last end
      end
      local a=(seed*2.399963229728653)%(2*math.pi)
      local b=(seed*1.4142135623730951)%1*2*math.pi
      local r1=(seed-0.5)/64*c.inaccuracy
      local r2=(((seed*13)%64)+0.5)/64*c.spread
      local sx,sy=math.cos(a)*r1+math.cos(b)*r2,math.sin(a)*r1+math.sin(b)*r2
      local vx,vy,vz=fx+rx*sx+ux*sy,fy+ry*sx+uy*sy,fz+uz*sy
      local norm=math.sqrt(vx*vx+vy*vy+vz*vz)
      vx,vy,vz=vx/norm,vy/norm,vz/norm
      endpoint.x,endpoint.y,endpoint.z=c.origin.x+vx*(length+64),c.origin.y+vy*(length+64),c.origin.z+vz*(length+64)
      local ok,value,matched=pcall(env.trace,c,endpoint)
      self.rays=self.rays+1
      if not ok or not finite(value)then self.rejections=self.rejections+1;self.last="trace failed; estimate discarded";return nil,self.last end
      local row=bank[seed-1]
      row.damage=matched and math.max(0,value)or 0;row.x,row.y,row.z=vx,vy,vz
    end
    if started and env.time_us then
      local finished=env.time_us()
      if finished and finished>=started and finished-started>self.time_budget_us then self.partial=self.partial+1;self.last="time budget exceeded; complete trace batch discarded";return nil,self.last end
    end
    if env.valid and not env.valid(c)then self.rejections=self.rejections+1;self.last="SDK/weapon/spread snapshot changed; estimate discarded";return nil,self.last end
    self.serial=self.serial+1;self.ready=self.ready+1
    self.cache={key=c.key,time=now,bank=bank,bank_index=bank_index,serial=self.serial}
    local result,why=self.summarize(nil,nil,c.origin,c.point,minimum,c.hp,bank)
    if result then result.serial=self.serial;self.last=string.format("head estimate=%d/64 weighted_shift=%.3f; real spread scale=1; native aim point untouched",result.hits,result.shift or 0)end
    return result,why
  end
  function M:cached(c,minimum)
    local now=env.now();local saved=self.cache
    if not finite(now)or not saved or saved.key~=c.key or now<saved.time or now-saved.time>self.interval then return nil,"waiting for exact network-prepared spread batch"end
    self.cache_hits=self.cache_hits+1
    if not env.core or not env.core.ready then return nil,"FFI core unavailable"end
    local result,why=self.summarize(nil,nil,c.origin,c.point,minimum,c.hp,saved.bank)
    if result then result.serial=saved.serial end;return result,why
  end
  function M:report_lines()
    return {"ForceShot storage=shared core double FFI ray banks; command callback performs ZERO 64-ray batch traces; single endpoint table reused during preparation",string.format("ForceShot spread sampler evaluations=%d complete=%d rays=%d cache_hits=%d budget_waits=%d partial_discarded=%d rejected=%d state=%s",self.evaluations,self.ready,self.rays,self.cache_hits,self.waits,self.partial,self.rejections,self.last),
      "ForceShot sampler scope=current SDK head position, 64 deterministic low-discrepancy probes, NOT native CS:GO spread seeds or native selected aim point; minimum-damage qualification and capped damage-weighted projection adapted from supplied code; projection diagnostics ONLY",
      "ForceShot sampler budget=10 evaluations/s, <=64 traces/evaluation, 2ms soft deadline between traces when QPC available; individual engine trace cannot be preempted; incomplete/stale results never lower HC; no CS2 addresses, aim-point writes or artificial spread reduction"}
  end
  return M
end

local function snapshot(me,weapon,threat)
  local _,item_id=FS:weapon_kind(weapon)
  if item_id==25 or item_id==27 or item_id==29 or item_id==35 or item_id==28 or item_id==64 then return nil,"weapon-specific spread/cocking model unavailable; native HC unchanged"end
  local info=threat:get_player_info();local local_info=me:get_player_info()
  local id,uid,local_id,local_uid=threat:get_index(),info and tonumber(info.userid),me:get_index(),local_info and tonumber(local_info.userid)
  local weapon_id=weapon:get_index()
  local hp,inaccuracy,spread=number(threat.m_iHealth),number(weapon:get_inaccuracy()),number(weapon:get_spread())
  local from,point=me:get_eye_position(),threat:get_hitbox_position(0)
  local current_sim=threat:get_simulation_time()
  if type(current_sim)=="table"then current_sim=current_sim.current end
  current_sim=number(current_sim)
  local flags=number(me.m_fFlags)
  local clip,attack,player_attack,now=number(weapon.m_iClip1),number(weapon.m_flNextPrimaryAttack),number(me.m_flNextAttack),number(globals.curtime)
  if not number(id)or not number(uid)or not number(local_id)or not number(local_uid)or not number(weapon_id)or not hp or hp<=0 or not current_sim or not from or not point or not flags or not flag_set(flags,1)or not inaccuracy or not spread or not clip or clip<1 or not attack or not player_attack or not now or attack>now or player_attack>now then return nil,"live weapon/head context unavailable or weapon not ready"end
  if not me:is_alive()or not threat:is_alive()or threat:is_dormant()or not threat:is_enemy()then return nil,"entity context inactive"end
  local values={id,uid,local_id,local_uid,weapon_id,hp,current_sim,flags,inaccuracy,spread,from.x,from.y,from.z,point.x,point.y,point.z}
  for i,value in ipairs(values)do if not number(value)then return nil,"nonfinite snapshot value"end;values[i]=string.format("%.17g",value)end
  local key=table.concat(values,":")
  return {key=key,me=me,weapon=weapon,threat=threat,id=id,uid=uid,local_id=local_id,local_uid=local_uid,weapon_id=weapon_id,hp=hp,inaccuracy=inaccuracy,spread=spread,origin={x=from.x,y=from.y,z=from.z},point={x=point.x,y=point.y,z=point.z}}
end
local sampler=create_forceshot_sampler({
  core=Y.core,
  now=clock,
  time_us=function()return Y.native_trace and Y.native_trace:perf_start()end,
  trace=function(c,to)
    local damage,trace=utils.trace_bullet(c.me,vector(c.origin.x,c.origin.y,c.origin.z),vector(to.x,to.y,to.z))
    local target=trace and trace.entity
    return number(damage),target and target:get_index()==c.id or false
  end,
  valid=function(c)
    local ok,next_context=pcall(function()
      local me=entity.get_local_player();local target=FS:valid_threat()
      local weapon=me and me:get_player_weapon()
      if not me or not target or not weapon then return nil end
      return snapshot(me,weapon,target)
    end)
    return ok and next_context and next_context.key==c.key or false
  end
})
function FS:sampled_gate(prepare)
  local ok,context,damage=pcall(function()
    local me=entity.get_local_player();local threat=self:valid_threat()
    if not me or not threat then return nil,"target unavailable"end
    if Y.steam_exclusion and Y.steam_exclusion:is_protected(threat)then return nil,"protected SteamID"end
    local weapon=me:get_player_weapon();if not weapon then return nil,"weapon unavailable"end
    local c,why=snapshot(me,weapon,threat);if not c then return nil,why end
    if not self.sample_damage_ref then self.sample_damage_ref=N:find({"Aimbot","Ragebot","Selection","Min. Damage"})end
    local setting=self.sample_damage_ref and number(N:effective(self.sample_damage_ref))
    local minimum=sampler.minimum_damage(setting,c.hp)
    if not minimum then return nil,"automatic/unreadable minimum damage; native HC unchanged"end
    return c,minimum
  end)
  if not ok then return nil,"spread SDK context read failed"end
  if not context then return nil,tostring(damage)end
  if prepare then return sampler:evaluate(context,damage)end
  return sampler:cached(context,damage)
end
return sampler
end)()

function FS:tick(cmd)
  if cfg.runtime_paused or ANEMONE_SECOND_COPY then self:release_hc();self.state="paused";return end
  if not get_bool(cfg.forceshot) then
    self.state = "OFF"
    self:release_hc()
    return
  end
  if not N:master_enabled() then
    self.state = "native Ragebot OFF"
    self:release_hc()
    return
  end
  local threat = self:valid_threat()
  if not threat then
    self.state = "no valid threat"
    self:release_hc()
    return
  end
  if get_bool(cfg.extrapolation) and not self:prediction_clean(threat) then
    self.state = "prediction unstable; forced shot refused"
    self:release_hc()
    return
  end
  local mode = self:mode()
  local active = false
  if not cmd or cmd.in_use==true or cmd.in_use==1 or cmd.in_reload==true or cmd.in_reload==1 then
    self:release_hc();self.state="use/reload/no command; native HC unchanged";return
  end
  active=true
  if Y.native_records then
    local allowed,reason=Y.native_records:guard(threat,"forceshot")
    if not allowed then self:release_hc();self.state=reason.."; native aim unchanged";return end
  end
  local shared_geometry
  if Y.observation_bridge then
    local min_ref=R.body_damage_ref or N:find({"Aimbot","Ragebot","Selection","Min. Damage"})
    R.body_damage_ref=min_ref
    local raw_damage=min_ref and number(N:effective(min_ref))or nil
    local damage=self.spread_sampler.minimum_damage(raw_damage,number(threat.m_iHealth))
    local me=entity.get_local_player()
    if me and damage then shared_geometry=Y.observation_bridge:geometry(me,threat,damage)end
    if not shared_geometry or not shared_geometry.eligible then
      self:release_hc();self.state="center-damage gate: native aim unchanged";return
    end
    Y.observation_bridge:consume("forceshot")
  end
  if not self:bind_hc() then
    self:release_hc()
    self.state = "hitchance slot unavailable"
    return
  end
  local desired_hc, hc_reason = self:adaptive_hitchance()
  if not desired_hc then
    self:release_hc()
    self.state = "adaptive gate refused: " .. tostring(hc_reason)
    return
  end
  local sampled,sample_reason=self:sampled_gate()
  self.sampled_result=sampled
  if not sampled or not sampled.all_pass then
    self:release_hc()
    self.state=sampled and ("64-ray head coverage "..sampled.hits.."/64; native HC unchanged")or ("spread gate: "..tostring(sample_reason))
    return
  end
  hc_reason=tostring(hc_reason).."; 64/64 damage-qualified head probes, real spread"
  if shared_geometry and shared_geometry.quality<0.65 then
    local base
    for _,h in ipairs(self.hc) do local ok,v=pcall(function () return h.ref:get() end);if ok and number(v) then base=math.max(base or 0,v) end end
    if base then desired_hc=math.max(desired_hc,math.floor(base*0.75+0.5));hc_reason=tostring(hc_reason).."; unstable-motion HC floor" end
  end
  local applied=0
  for _,h in ipairs(self.hc)do
    local read,current=pcall(function()return h.ref:get_override()end)
    if read then
      if h.owned and current~=h.written then h.owned,h.written=false,nil end
      if h.owned or current==nil or current==false then
        if h.owned and current==desired_hc then applied=applied+1
        else
          local previously_owned,previous_written=h.owned,h.written
          pcall(function()h.ref:override(desired_hc)end)
          local verified,after=pcall(function()return h.ref:get_override()end)
          if verified and number(after)and math.abs(after-desired_hc)<0.5 then
            h.owned,h.written=true,after;applied=applied+1
          elseif verified then
            if after~=current then
              pcall(function()if current==nil or current==false then h.ref:override()else h.ref:override(current)end end)
            end
            local restored,value=pcall(function()return h.ref:get_override()end)
            if restored and value==current then h.owned,h.written=previously_owned,previous_written
            elseif not restored or value==after then h.owned,h.written=true,after
            else h.owned,h.written=false,nil end
          else h.owned,h.written=true,desired_hc end
        end
      end
    end
  end
  if applied == 0 then
    self:release_hc()
    self.state = "hitchance override not verified"
    return
  end
  if not self.active then
    self.count = self.count + 1
  end
  self.active = true
  self.hc_value = desired_hc
  self.hc_reason = hc_reason
  self.state = mode .. (mode == "CS2" and "-like" or "") .. ": adaptive force-shot hc=" .. tostring(desired_hc)
end
function FS.air_policy(native_hc, native_damage, hp, center_damage, cone_ratio)
  if not number(native_hc) or native_hc<0 or native_hc>100 or not number(native_damage) or native_damage<0 or native_damage>200 or not number(hp) or hp<=0 or not number(center_damage) or center_damage<=0 or not number(cone_ratio) or cone_ratio<0 then
    return nil,"invalid live thresholds"
  end
  local native_floor=native_damage>100 and hp+native_damage-100 or native_damage
  local lethal=center_damage>=hp
  local damage=native_floor
  if native_damage==0 then damage=lethal and hp or math.ceil(hp/2) end
  damage=math.max(1,damage)
  if center_damage<damage then return nil,"center damage below effective floor" end
  local uncertainty=clamp(cone_ratio,0,1)
  local automatic_hc=50+20*(1-math.min(1,center_damage/hp))+15*uncertainty
  local margin=100/32+5*uncertainty
  local hc=math.min(100,math.max(native_hc,automatic_hc)+margin)
  return {damage=damage,hc=hc,margin=margin,lethal=lethal}
end
function FS:air_thresholds(me,weapon,threat)
  local ok,p,note=pcall(function ()
    if not self:bind_hc() then return nil,"native HC unavailable" end
    local hc
    for _,h in ipairs(self.hc) do
      local value=number(h.ref:get())
      local override=number(h.ref:get_override())
      if value then hc=math.max(hc or 0,value) end
      if override then hc=math.max(hc or 0,override) end
    end
    if not hc then return nil,"native HC unreadable" end
    if not self.air_damage_ref then
      for _,path in ipairs({{"Aimbot","Ragebot","Selection","Min. Damage"},{"Aimbot","Ragebot","Selection","Minimum Damage"}}) do
        local found,ref=pcall(function () return ui.find(unpack(path)) end)
        if found and ref then self.air_damage_ref=ref;break end
      end
    end
    if not self.air_damage_ref then return nil,"native Min Damage unavailable" end
    local damage=number(self.air_damage_ref:get_override()) or number(self.air_damage_ref:get())
    if not damage then return nil,"native Min Damage unreadable" end
    local hp=number(threat.m_iHealth)
    local from,target=me:get_eye_position(),threat:get_hitbox_position(5)
    if not from or not target then return nil,"thorax unavailable" end
    local delta=target-from
    local distance=math.sqrt(delta.x*delta.x+delta.y*delta.y+delta.z*delta.z)
    local center,tr=utils.trace_bullet(me,from,target)
    if not tr or not tr.entity or tr.entity:get_index()~=threat:get_index() then return nil,"center target mismatch" end
    local inac,spread=number(weapon:get_inaccuracy()),number(weapon:get_spread())
    if not inac or not spread or inac<0 or spread<0 or inac+spread>1 then return nil,"accuracy unavailable" end
    local ratio=(inac+spread)*distance/8
    local result,why=self.air_policy(hc,damage,hp,number(center),ratio)
    if not result then return nil,why end
    result.signature=tostring(threat:get_index())..":"..tostring(hp)..":"..tostring(damage)..":"..tostring(hc)
    result.note=string.format("auto HC>=%.1f damage>=%.1f HP=%.0f center=%.1f cone=%.2f",result.hc,result.damage,hp,center,ratio)
    return result
  end)
  if not ok then self.air_damage_ref=nil;return nil,"adaptive thresholds unavailable" end
  return p,note
end
function FS:air_hitchance(me, weapon, threat, min_damage)
  local ok, result, note = pcall(function ()
    local inac, spread = number(weapon:get_inaccuracy()), number(weapon:get_spread())
    if not inac or not spread or inac < 0 or spread < 0 or inac + spread > 1 then return nil, "accuracy API unavailable" end
    local from = me:get_eye_position()
    local target = threat:get_hitbox_position(5)
    if not from or not target then return nil, "hitbox unavailable" end
    local d = target - from
    local len = math.sqrt(d.x*d.x+d.y*d.y+d.z*d.z)
    if len < 1 then return nil, "distance unavailable" end
    local fx, fy, fz = d.x/len, d.y/len, d.z/len
    local rlen = math.sqrt(fx*fx+fy*fy)
    if rlen < 0.01 then return nil, "vertical aim refused" end
    local rx, ry = -fy/rlen, fx/rlen
    local ux, uy, uz = -fz*ry, fz*rx, fx*ry-fy*rx
    local index = threat:get_index()
    local damage, trace = utils.trace_bullet(me, from, target)
    if not number(damage) or damage < min_damage or not trace or not trace.entity or trace.entity:get_index() ~= index then
      return 0, "center damage/target refused"
    end
    local hits = 0
    for i=1,32 do
      local a=(i*2.399963229728653)% (2*math.pi)
      local b=(i*1.4142135623730951)%1*2*math.pi
      local r1=(i-0.5)/32*inac
      local r2=(((i*13)%32)+0.5)/32*spread
      local sx=math.cos(a)*r1+math.cos(b)*r2
      local sy=math.sin(a)*r1+math.sin(b)*r2
      local vx,vy,vz=fx+rx*sx+ux*sy, fy+ry*sx+uy*sy, fz+uz*sy
      local vl=math.sqrt(vx*vx+vy*vy+vz*vz)
      local to=from+vector(vx/vl,vy/vl,vz/vl)*(len+64)
      local dmg,tr=utils.trace_bullet(me,from,to)
      if number(dmg) and dmg>=min_damage and tr and tr.entity and tr.entity:get_index()==index then hits=hits+1 end
    end
    return hits*100/32, string.format("sample=%d/32 inac=%.4f spread=%.4f dmg=%.1f",hits,inac,spread,damage)
  end)
  if not ok then return nil, "trace unavailable: "..tostring(result):sub(1,60) end
  return result,note
end
function FS.air_counter(vx,vy,yaw,interval,airaccelerate)
  if not number(vx) or not number(vy) or not number(yaw) then return nil end
  local speed=math.sqrt(vx*vx+vy*vy)
  if speed<=2 then return 0,0,speed end
  local dt=number(interval) or 1/64
  local aa=number(airaccelerate) or 12
  if dt<=0 or dt>0.1 or aa<=0 then return nil end
  local magnitude=clamp(speed/(aa*dt),0,450)
  local x,y=-vx/speed*magnitude,-vy/speed*magnitude
  local r=math.rad(yaw)
  return x*math.cos(r)+y*math.sin(r),x*math.sin(r)-y*math.cos(r),speed
end
function FS:air_strafe(active)
  if active and not N.slots.air_strafe then
    local ref
    for _,path in ipairs({{"Miscellaneous","Main","Movement","Air Strafe"},{"Miscellaneous","Main","Movement","Air strafe"},{"Miscellaneous","Movement","Air Strafe"}}) do
      local candidate=N:find(path)
      if candidate and type(N:effective(candidate))=="boolean" then ref=candidate;break end
    end
    N.slots.air_strafe={ref=ref,kind="air_strafe",owned=false,yielded=false,applied=0,released=0,conflicts=0,state="idle"}
  end
  if not N.slots.air_strafe then return "not requested" end
  if active then return N:request("air_strafe",false) end
  return N:request("air_strafe",nil)
end
function FS:air_finish(note)
  self.air_state=note or "OFF"
  Y.air_stop_state=self.air_state
  self:air_strafe(false)
end
function FS:apply_air_brake(cmd,vel)
  local yaw=number(cmd.move_yaw)
  if not yaw then pcall(function () yaw=number(cmd.view_angles.y) end) end
  local aa
  pcall(function () aa=number(cvar.sv_airaccelerate:float()) end)
  local forward,side,speed=self.air_counter(number(vel.x),number(vel.y),yaw,number(globals.tickinterval),aa)
  if forward==nil then self:air_finish("movement yaw/velocity unavailable");return false end
  local state=self:air_strafe(true)
  cmd.block_movement=2
  for _,key in ipairs({"in_forward","in_back","in_moveleft","in_moveright"}) do
    pcall(function() local old=cmd[key];cmd[key]=type(old)=="boolean" and false or 0 end)
  end
  cmd.forwardmove,cmd.sidemove=forward,side
  self.air_horizontal_speed=speed
  self.air_strafe_state=state
  self.air_state=self.air_state..string.format("; speed=%.1f counter=(%.1f,%.1f) strafe=%s",speed,forward,side,tostring(state))
  Y.air_stop_state=self.air_state
  return true
end
function FS:air_tick(cmd)
  if cfg.runtime_paused or ANEMONE_SECOND_COPY then self:air_finish("paused");return end
  local manual=get_bool(cfg.air_stop_hold)
  if not cmd or not get_bool(cfg.forceshot) or not get_bool(cfg.air_stop) then
    self.air_votes,self.air_until,self.air_sample_tick,self.air_used=0,nil,nil,false
    self.air_budget_end=nil
    self.air_estimate,self.air_hc_floor,self.air_damage_floor=nil,nil,nil
    self:air_finish("OFF; enable ForceShot + AirStop");return
  end
  local ok,me,weapon,vel,flags,mt=pcall(function ()
    local ent=entity.get_local_player();if not ent or not ent:is_alive() then return nil end
    return ent,ent:get_player_weapon(),ent.m_vecVelocity,number(ent.m_fFlags),number(ent.m_MoveType)
  end)
  if not ok or not me or not vel or flags==nil then self:air_finish("no live movement data");return end
  local tick=number(globals.tickcount) or 0
  local weapon_id
  pcall(function () weapon_id=weapon and weapon:get_index() end)
  if (self.air_last_tick and tick<self.air_last_tick) or self.air_weapon~=weapon_id then
    self.air_votes,self.air_until,self.air_used,self.air_sample_tick=0,nil,false,nil
    self.air_budget_end,self.air_policy_signature=nil,nil
  end
  self.air_last_tick,self.air_weapon=tick,weapon_id
  if flag_set(flags,1) then
    self.air_votes,self.air_until,self.air_sample_tick,self.air_used=0,nil,nil,false
    self.air_budget_end,self.air_policy_signature=nil,nil
    self:air_finish("ground");return
  end
  if mt~=nil and mt~=2 then self:air_finish("special movement refused");return end
  if cmd.in_use==true or cmd.in_use==1 then self:air_finish("use action; movement unchanged");return end
  if not self.air_duck_ref then self.air_duck_ref=N:find({"Aimbot","Anti Aim","Misc","Fake Duck"}) end
  if self.air_duck_ref and N:effective(self.air_duck_ref)==true then self.air_votes,self.air_until=0,nil;self:air_finish("Fake Duck conflict");return end
  if manual then
    self.air_state="manual Hold: counter-brake"
    self:apply_air_brake(cmd,vel);return
  end
  if not N:master_enabled() or not weapon then self:air_finish("automatic: native Ragebot/weapon unavailable");return end
  if cmd.in_reload==true or cmd.in_reload==1 then self:air_finish("automatic: reload");return end
  local ready=false
  pcall(function ()
    local clip,next_shot,next_player,now=number(weapon.m_iClip1),number(weapon.m_flNextPrimaryAttack),number(me.m_flNextAttack),number(globals.curtime)
    ready=clip~=nil and clip>0 and now~=nil and next_shot~=nil and next_shot<=now and (not next_player or next_player<=now)
  end)
  if not ready then self:air_finish("automatic: weapon not ready");return end
  if self.air_used or (self.air_budget_end and tick>=self.air_budget_end) then self.air_used=true;self:air_finish("auto window spent; waiting landing");return end
  local threat=self:valid_threat()
  if not threat then self.air_votes,self.air_until=0,nil;self:air_finish("automatic: no live threat");return end
  local index=threat:get_index()
  local shared=Y.observation_bridge and Y.observation_bridge:assessment(index,nil,tick,globals.tickinterval)
  if shared and shared.invalid then self.air_votes,self.air_until=0,nil;self:air_finish("automatic: observed record invalid");return end
  if self.air_target~=index then self.air_target,self.air_votes,self.air_sample_tick,self.air_until=index,0,nil,nil end
  if not self.air_sample_tick or tick<self.air_sample_tick or tick-self.air_sample_tick>=2 then
    self.air_sample_tick=tick
    local policy,why=self:air_thresholds(me,weapon,threat)
    if policy and self.air_policy_signature~=policy.signature then self.air_votes,self.air_until=0,nil;self.air_policy_signature=policy.signature end
    local estimate,note
    if policy then estimate,note=self:air_hitchance(me,weapon,threat,policy.damage) end
    self.air_estimate=estimate
    self.air_note=policy and (policy.note.."; "..tostring(note)) or tostring(why)
    self.air_hc_floor,self.air_damage_floor=policy and policy.hc or nil,policy and policy.damage or nil
    if policy and estimate and estimate>=policy.hc then self.air_votes=(self.air_votes or 0)+1 else self.air_votes=0;self.air_until=nil end
    if self.air_votes>=2 and not self.air_until then self.air_until=tick+6;self.air_budget_end=tick+6 end
  end
  if self.air_until and tick<self.air_until and (self.air_votes or 0)>=2 then
    self.air_state=string.format("auto sampled HC %.1f%%",self.air_estimate or 0)
    self:apply_air_brake(cmd,vel)
  else self:air_finish("automatic: "..tostring(self.air_note or "sampling")) end
end
function FS:guard(method, ...)
  local ok, err = pcall(method, self, ...)
  if not ok then
    pcall(function ()
      self:release_hc()
    end)
    pcall(function () self:air_strafe(false) end)
    warn_once("forceshot_callback", "ForceShot callback error: " .. tostring(err):gsub("%c", " "))
    self.state = "callback error; override released"
  end
end
local MD = {
  ref = nil,
  active = false,
  written = nil,
  base = nil,
  target_id = nil,
  high_ground = false,
  state = "removed; no speculative damage override",
  applies = 0,
  releases = 0,
  conflicts = 0
}
function MD:find_ref()
  return nil
end
function MD:release(reason)
  self.active = false
  self.written = nil
  self.base = nil
  self.target_id = nil
  self.high_ground = false
  self.state = reason or "removed; no speculative damage override"
  return true
end
function MD:tick()
  self.active = false
  self.high_ground = false
  self.state = "removed; no speculative damage override"
end
function MD:guard(method, ...)
  self:tick()
end
local LIMITS = {
  max_players = 64,
  max_shots = 128,
  shot_age = 3,
  fresh_age = 0.25,
  simulation_period = 0.04,
  prediction_ticks = 2,
  command_watchdog = 0.20,
  correction_window = 2.5,
  assist_duration = 0.8,
  assist_cooldown = 1.2,
  prediction_fault_limit = 4,
  lag_soft = 0.30,
  lag_hard = 0.45,
}
function R:say(text, always)
  if always then
    console_line("[Anemone] " .. tostring(text):gsub("%c", " "):sub(1, 480))
  end
end
function R:identity(ent)
  local ok, id, uid = pcall(function ()
    return ent:get_index(), ent:get_player_info().userid
  end)
  if not ok or not number(id) or not number(uid) then
    return nil
  end
  if id < 1 or id > LIMITS.max_players or id ~= math.floor(id) or uid < 1 or uid ~= math.floor(uid) then
    return nil
  end
  return id, uid
end
function R:tag(ent, id)
  local ok, text = pcall(function ()
    return ent:get_name()
  end)
  if not ok or type(text) ~= "string" then
    text = "player " .. tostring(id or "?")
  end
  return text:gsub("[%c|]", " "):sub(1, 72)
end
function R:interval()
  local dt = globals and number(globals.tickinterval)
  if dt and dt >= 0.001 and dt <= 0.1 then
    return dt
  end
  return nil
end
function R:server_tick()
  local ok, tick = pcall(function ()
    local base = tonumber(globals.client_tick)
    local offset = tonumber(globals.clock_offset)
    if base and offset and base + offset > 0 then
      return base + offset, "client_tick"
    end
  end)
  if ok and tonumber(tick) then
    return tick, "client_tick"
  end
  local st = number(globals.server_tick)
  if st and st > 0 then
    return st, "server_tick"
  end
  local tc = number(globals.tickcount)
  if tc then
    return tc, "tickcount"
  end
  return nil, "unavailable"
end
function R:to_time(tick)
  local dt = self:interval()
  if not dt or not tonumber(tick) then
    return nil
  end
  return tick * dt
end
function R:to_ticks(time)
  local dt = self:interval()
  if not dt or dt <= 0 or not tonumber(time) then
    return nil
  end
  return math.floor(time / dt)
end
function R:lag_time(sim)
  local tick, source = self:server_tick()
  local st = self:to_time(tick)
  if source ~= "server_tick" and source ~= "client_tick" then
    return nil, source
  end
  if not st or not tonumber(sim) then
    return nil, source
  end
  return st - sim, source
end
function R:dead_time()
  local tick, source = self:server_tick()
  if source ~= "server_tick" and source ~= "client_tick" then
    return nil, source
  end
  local st = self:to_time(tick)
  if not st then
    return nil, source
  end
  local max_unlag = nil
  local got, ref = pcall(function ()
    if cvar.sv_maxunlag then
      return cvar.sv_maxunlag
    end
    if cvar.find then
      return cvar.find("sv_maxunlag")
    end
  end)
  if got and ref then
    local read, value = pcall(function ()
      if ref.get_float then
        return ref:get_float()
      end
      if ref.float then
        return ref:float()
      end
      return ref:get_int() / 1000
    end)
    if read and tonumber(value) and tonumber(value) > 0 then
      max_unlag = tonumber(value)
    end
  end
  local latency = nil
  local okc, channel = pcall(utils.net_channel)
  if okc and channel and channel.latency then
    local l = number(channel.latency[0])
    if l and l >= 0 then
      latency = l
    end
  end
  if latency==nil or max_unlag==nil then return nil,"latency / max_unlag unavailable" end
  return {
    time = st - latency - max_unlag,
    tick = self:to_ticks(st - (latency or 0) - (max_unlag or 0)),
    latency = latency,
    max_unlag = max_unlag,
    source = source
  }
end
function R:context()
  if not self.ready then
    return nil, "required events unavailable"
  end
  if self.suspended then
    return nil, "config transaction"
  end
  if self.fault then
    if clock() < (self.fault_until or 0) then
      return nil, self.fault
    end
    self.fault = nil
  end
  if not N.master then
    return nil, "native Ragebot switch unavailable"
  end
  if not N:master_enabled() then
    return nil, "native Ragebot is off; unchanged"
  end
  local ok, me, uid = pcall(function ()
    if not globals or globals.is_in_game ~= true then
      return nil
    end
    local lp = entity.get_local_player()
    if not lp or not lp:is_alive() then
      return nil
    end
    local _, user = self:identity(lp)
    if not user then
      return nil
    end
    return lp, user
  end)
  if not ok or not me then
    return nil, "not alive / not in game"
  end
  return { me = me, uid = uid }
end
function R:reset(reason)
  if Y.native_records then Y.native_records:reset() end
  if Y.observation_bridge then Y.observation_bridge:reset() end
  local safe_released = N:reset("safe")
  local body_released = N:reset("body")
  local released = safe_released and body_released
  self.players, self.shots = { }, { }
  Y.feedback_epoch=(Y.feedback_epoch or 0)+1
  if Y.ffi_feedback then Y.ffi_feedback:reset()end
  self.epoch, self.sequence = self.epoch + 1, 0
  self.local_uid, self.in_session, self.last_command, self.last_step = nil, false, nil, nil
  self.next_simulation, self.last_clock = 0, clock()
  self.prediction_state, self.prediction_fault = "waiting for fresh network data", nil
  self.prediction_fault_strikes, self.fault_until = 0, nil
  self.plan = reason or "reset; native configuration retained"
  if released then
    self.fault = nil
  else
    self.fault = "native release unverified; check menu"
    self.fault_until = clock() + 5
  end
  self:status(true)
end
function R:ensure_context()
  local ctx, reason = self:context()
  if not ctx then
    if self.in_session then
      local old_fault, old_until = self.fault, self.fault_until
      self:reset(reason)
      self.fault, self.fault_until = old_fault or self.fault, old_until
    end
    N:request("safe", nil)
    self.plan = reason
    return nil
  end
  if self.local_uid and self.local_uid ~= ctx.uid then
    self:reset("local player changed")
  end
  self.local_uid, self.in_session = ctx.uid, true
  return ctx
end
function R:snapshot(ent)
  local ok, d, reason = pcall(function ()
    local id, uid = self:identity(ent)
    if not id then
      return nil, "invalid player identity"
    end
    if not ent:is_alive() or not ent:is_enemy() then
      return nil, "not an alive enemy"
    end
    if ent:is_dormant() then
      return nil, "dormant; leave to native Dormant Aimbot"
    end
    if ent:get_network_state() ~= 0 then
      return nil, "non-live network state"
    end
    local sim, pos, velocity = ent:get_simulation_time(), ent:get_origin(), ent.m_vecVelocity
    if type(sim) ~= "table" then
      return nil, "simulation time unavailable"
    end
    local st, flags = number(sim.current), number(ent.m_fFlags)
    if flags == nil then
      pcall(function ()
        flags = number(entity.get_prop(ent, "m_fFlags"))
      end)
    end
    local x, y, z = number(pos.x), number(pos.y), number(pos.z)
    local vx, vy, vz = number(velocity.x), number(velocity.y), number(velocity.z)
    if not (st and st >= 0 and flags and x and y and z and vx and vy and vz) then
      return nil, "non-finite snapshot"
    end
    if flags < 0 or flags ~= math.floor(flags) or math.abs(x) > 1e7 or math.abs(y) > 1e7 or math.abs(z) > 1e7 or math.abs(vx) > 4096 or math.abs(vy) > 4096 or math.abs(vz) > 4096 then
      return nil, "invalid snapshot range"
    end
    local lag, lag_source = self:lag_time(st)
    return {
      ent = ent,
      id = id,
      uid = uid,
      sim = st,
      old_sim = number(sim.old),
      flags = flags,
      duck = Y_duck_amount(ent) or 0,
      x = x,
      y = y,
      z = z,
      vx = vx,
      vy = vy,
      vz = vz,
      speed = math.sqrt(vx * vx + vy * vy),
      lag = lag,
      lag_source = lag_source
    }, "live"
  end)
  if not ok then
    return nil, "snapshot read failed: " .. tostring(d):gsub("%c", " "):sub(1, 120)
  end
  return d, reason
end
function R:mark(s, key, reason, duration)
  local t = clock()
  local item = s.risks[key]
  if item and t < item.rearm then
    return false
  end
  local ttl = duration or LIMITS.assist_duration
  s.risks[key] = { until_t = t + ttl, rearm = t + ttl + LIMITS.assist_cooldown, reason = reason }
  return true
end
function R:observe(ent)
  local id, uid = self:identity(ent)
  if not id then
    return
  end
  local d = self:snapshot(ent)
  if not d then
    self.players[id] = nil
    ;
    return
  end
  local t, s = clock(), self.players[id]
  if not s or s.uid ~= uid then
    s = {
      uid = uid,
      risks = { },
      good = 0,
      corrections = 0,
      seen = t
    }
    self.players[id] = s
  end
  s.seen = t
  local old = s.data
  if old and math.abs(old.sim - d.sim) <= 0.0001 then
    s.unchanged_reads=(s.unchanged_reads or 0)+1
    return
  end
  local reason
  local clean = true
  if old then
    local dt = d.sim - old.sim
    local distance_sq = (d.x - old.x) ^ 2 + (d.y - old.y) ^ 2 + (d.z - old.z) ^ 2
    if d.sim < (s.frontier or old.sim) - 0.0001 then
      reason, clean = "network time regression (not proof of defensive desync)", false
    elseif dt > 0.25 or distance_sq > 4096 then
      reason, clean = "network gap / position discontinuity", false
    end
  end
  s.frontier = math.max(s.frontier or d.sim, d.sim)
  s.good = clean and math.min(8, s.good + 1) or 0
  s.previous = old
  s.clean, s.data, s.sample_time, s.prediction = clean, d, t, nil
  if reason then
    if self:mark(s, "defensive", reason, 0.6) then
      self.defensive_signals = self.defensive_signals + 1
    end
  end
end
function R:trim()
  local t = clock()
  for id, s in pairs(self.players) do
    if t - (s.seen or 0) > 1.5 or t < (s.seen or t) then
      self.players[id] = nil
    end
  end
  for id, shot in pairs(self.shots) do
    if t - shot.time > LIMITS.shot_age or t < shot.time then
      self.shots[id] = nil
    end
  end
end
function R:net_update()
  if not self:ensure_context() then
    return
  end
  local ok, players = pcall(function ()
    return entity.get_players(true, true)
  end)
  if not ok or type(players) ~= "table" then
    self.plan = "enemy enumeration unavailable"
    ;
    return
  end
  local count = 0
  for _, ent in pairs(players) do
    if count >= LIMITS.max_players then
      break
    end
    count = count + 1
    self:observe(ent)
  end
  self.net_count = self.net_count + 1
  self:trim()
end
function R.adaptive_extrap_ticks(base_ticks, live, record)
  local out = math.max(1, math.min(15, math.floor(tonumber(base_ticks) or 1)))
  local speed = math.sqrt((live.vx or 0) ^ 2 + (live.vy or 0) ^ 2 + (live.vz or 0) ^ 2)
  if speed > 260 then
    out = math.min(out, 2)
  elseif speed > 190 then
    out = math.min(out, 3)
  elseif speed > 130 then
    out = math.min(out, 4)
  end
  if record and (record.good or 0) < 4 then
    out = math.min(out, 3)
  end
  if live.lag and live.lag > 0.20 then
    out = math.min(out, 2)
  end
  return math.max(1, out)
end
function R:predict(s, live)
  if not get_bool(cfg.extrapolation) then
    s.prediction=nil
    self.prediction_state = "OFF"
    ;
    return
  end
  if self.prediction_fault then
    s.prediction=nil
    self.prediction_state = self.prediction_fault
    ;
    return
  end
  if not s.clean or s.good < 2 then
    s.prediction=nil
    self.prediction_state = "waiting for consistent samples"
    ;
    return
  end
  local t, interval = clock(), self:interval()
  if not interval then
    s.prediction=nil
    self.prediction_state = "tick interval unavailable"
    ;
    return
  end
  local ticks = 0
  pcall(function ()
    if cfg.extrapolation_ticks then
      local v = tonumber(cfg.extrapolation_ticks:get())
      if v then ticks = math.max(0, math.min(15, math.floor(v))) end
    end
  end)
  if ticks <= 0 then
    s.prediction=nil
    self.prediction_state = "OFF (0 ticks)"
    ;
    return
  end
  if Y.native_records then
    local allowed,reason,record=Y.native_records:guard(live.ent,"extrapolation")
    if not allowed then self.prediction_state=reason.."; extrapolation withheld";s.prediction=nil;return end
    if record then ticks=math.min(ticks,math.max(1,math.min(15,record.choke+1))) end
  end
  ticks = R.adaptive_extrap_ticks(ticks, live, s)
  local shared=Y.observation_bridge and Y.observation_bridge:assessment(live.id,live.uid,globals.tickcount,interval,self:record_lerp())
  if shared then
    Y.observation_bridge:consume("extrapolation")
    if shared.invalid then self.prediction_state="observed record invalid; prediction withheld";s.prediction=nil;return end
    ticks=math.min(ticks,shared.horizon)
    self.observed_extrap_horizon=ticks
  end
  if not Y.core.ready then self.prediction_state="FFI core unavailable";s.prediction=nil;return end
  if s.prediction and Y.core:prediction_match(live,interval,ticks,t)then
    self.prediction_state="cached exact FFI-keyed isolated prediction";return
  end
  s.prediction=nil
  if t>=self.next_simulation then self.next_simulation=t+LIMITS.simulation_period else return end
  local ok, result = pcall(function ()
    local sim = live.ent:simulate_movement(vector(live.x, live.y, live.z), vector(live.vx, live.vy, live.vz), live.flags)
    if not sim then
      error("movement context unavailable")
    end
    sim:think(ticks)
    local p, v = sim.origin, sim.velocity
    return {
      x = number(p.x),
      y = number(p.y),
      z = number(p.z),
      vx = number(v.x),
      vy = number(v.y),
      vz = number(v.z),
      collision = sim.did_hit_collision == true or sim.did_hit_collision == 1
    }
  end)
  if not ok then
    self.simulation_skips = self.simulation_skips + 1
    self.prediction_fault_strikes = (self.prediction_fault_strikes or 0) + 1
    if self.prediction_fault_strikes >= LIMITS.prediction_fault_limit then
      self.prediction_fault = "movement simulation unavailable / failed"
      self.prediction_fault_strikes = 0
      warn_once("predict_api", self.prediction_fault .. "; Extrapolation is paused, native aim is untouched. Toggle OFF/ON to retry.")
    end
    self.prediction_state = string.format("simulation call failed (%d/%d), retries left", self.prediction_fault_strikes, LIMITS.prediction_fault_limit)
    return
  end
  self.prediction_fault_strikes = 0
  if not (result.x and result.y and result.z and result.vx and result.vy and result.vz) or type(result.collision) ~= "boolean" then
    self.prediction_state = "invalid simulation result; skipped"
    self.simulation_skips = self.simulation_skips + 1
    return
  end
  local after = self:snapshot(live.ent)
  if not after or after.uid~=live.uid or after.sim~=live.sim or after.x~=live.x or after.y~=live.y or after.z~=live.z or after.vx~=live.vx or after.vy~=live.vy or after.vz~=live.vz or after.duck~=live.duck or after.flags~=live.flags then
    self.prediction_state = "record changed during simulation; skipped"
    self.simulation_skips = self.simulation_skips + 1
    return
  end
  local dt = interval * ticks
  local distance = math.sqrt((result.x - live.x) ^ 2 + (result.y - live.y) ^ 2 + (result.z - live.z) ^ 2)
  local maximum = math.sqrt(live.vx ^ 2 + live.vy ^ 2 + live.vz ^ 2) * dt + 40
  if distance > maximum then
    self.prediction_state = "unbounded prediction rejected"
    self.simulation_skips = self.simulation_skips + 1
    return
  end
  local expected_x, expected_y = live.x + live.vx * dt, live.y + live.vy * dt
  local velocity_change = 0
  local prev = s.previous
  if prev and live.sim > prev.sim then
    local sample_dt = live.sim - prev.sim
    if sample_dt > 0.001 and sample_dt < 0.25 then
      local ax = clamp((live.vx - prev.vx) / sample_dt, - 1200, 1200)
      local ay = clamp((live.vy - prev.vy) / sample_dt, - 1200, 1200)
      expected_x = expected_x + 0.5 * ax * dt * dt
      expected_y = expected_y + 0.5 * ay * dt * dt
      velocity_change = math.sqrt((live.vx - prev.vx) ^ 2 + (live.vy - prev.vy) ^ 2)
    end
  end
  local divergence = math.sqrt((result.x - expected_x) ^ 2 + (result.y - expected_y) ^ 2)
  if not Y.core:prediction_commit(live,interval,ticks,t)then self.prediction_state="FFI prediction key rejected";return end
  s.prediction = {
    sim = live.sim,
    time = t,
    x = result.x,
    y = result.y,
    z = result.z,
    ticks = ticks,
    collision = result.collision,
    divergence = divergence,
    velocity_change = velocity_change
  }
  self.simulated = self.simulated + 1
  self.prediction_state = string.format("isolated %dt prediction: div %.1f", ticks, divergence)
  local div_lim = 4 + math.floor(ticks / 4)
  local vel_lim = 100 + ticks * 8
  if result.collision and live.speed > 35 then
    self:mark(s, "extrapolation", string.format("extrapolation %dt: collision, Prefer", ticks), 0.45)
  elseif divergence > div_lim then
    self:mark(s, "extrapolation", string.format("extrapolation %dt: non-linear (div %.1f>%d), Prefer", ticks, divergence, div_lim), 0.45)
  elseif velocity_change > vel_lim then
    self:mark(s, "extrapolation", string.format("extrapolation %dt: accel (dv %.1f>%d), Prefer", ticks, velocity_change, vel_lim), 0.45)
  end
end
function R:reasons(s)
  local t, out = clock(), { }
  local desired = nil
  local keys = { "resolver", "resolver_probe", "defensive", "extrapolation" }
  for _, key in ipairs(keys) do
    local enabled = ((key == "resolver" or key == "resolver_probe") and get_bool(cfg.resolver) and get_bool(cfg.assist)) or key == "defensive" or (key == "extrapolation" and get_bool(cfg.extrapolation) and not self.prediction_fault)
    local item = s.risks[key]
    if enabled and item and t < item.until_t then
      out[# out + 1] = item.reason
      local preference = (key == "extrapolation" or key == "resolver_probe") and "Prefer" or "Force"
      if not desired or SAFE_RANK[preference] > SAFE_RANK[desired] then
        desired = preference
      end
    end
  end
  return out, desired
end
function R:candidate_confidence(L, state)
  if not L then
    return 0, 0, 0
  end
  local bucket = L.__cur
  if not bucket then
    return 0, 0, 0
  end
  local global = L[bucket]
  local by_state = L.by_state and L.by_state[state]
  local rec = by_state and by_state[bucket]
  local hits = (rec and (rec.wh or rec.h) or 0) + (global and (global.wh or global.h) or 0) * 0.25
  local misses = (rec and (rec.wm or rec.m) or 0) + (global and (global.wm or global.m) or 0) * 0.25
  local total = hits + misses
  local accuracy = (hits + 1.25) / (total + 2.5)
  return clamp(total / 7, 0, 1) * accuracy, hits, misses
end
function R:cvar_number(name)
  local ok,value=pcall(function () local ref=cvar[name];if ref then return ref:float() end end)
  return ok and number(value) or nil
end
function R:record_lerp()
  return Y.record_tools.lerp(self:cvar_number("cl_interp"),self:cvar_number("cl_interp_ratio"),self:cvar_number("cl_updaterate"),self:cvar_number("sv_client_min_interp_ratio"),self:cvar_number("sv_client_max_interp_ratio"),self:cvar_number("sv_minupdaterate"),self:cvar_number("sv_maxupdaterate"))
end
function R:auto_geometry()
  self.auto_body_state="inactive"
  if not get_bool(cfg.resolver) or not N:master_enabled() then N:request("body",nil);return nil end
  local ok,safe,body,why=pcall(function ()
    local me,ent=entity.get_local_player(),entity.get_threat()
    if not me or not me:is_alive() or not ent or not ent:is_alive() or ent:is_dormant() or not ent:is_enemy() then return nil,nil,"no live threat" end
    local id,uid=self:identity(ent);local rec=id and self.players[id];local live=self:snapshot(ent);local now=clock()
    if not live or not rec or rec.uid~=uid or not rec.clean or now<(rec.sample_time or now) or now-(rec.sample_time or 0)>LIMITS.fresh_age or math.abs(live.sim-rec.data.sim)>0.0001 then return nil,nil,"unproven fresh record" end
    local timing=Y:timing_decision(id)
    if timing.status=="stale" or timing.defensive then return nil,nil,"timing record refused" end
    local lerp=self:record_lerp();self.lerp_seconds=lerp
    local shared=Y.observation_bridge:assessment(id,uid,globals.tickcount,globals.tickinterval,lerp)
    if not shared or shared.invalid then return nil,nil,"record-age/movement check refused" end
    self.record_age_budget=shared.budget
    local max_unlag=self:cvar_number("sv_maxunlag")
    if live.lag and max_unlag and live.lag>max_unlag+(lerp or 0) then return nil,nil,"outside measured unlag+lerp" end
    local md_ref=self.body_damage_ref or N:find({"Aimbot","Ragebot","Selection","Min. Damage"});self.body_damage_ref=md_ref
    local md=md_ref and number(N:effective(md_ref)) or nil
    local geometry=md and Y.observation_bridge:geometry(me,ent,md)
    if not geometry then return nil,nil,"center geometry unavailable" end
    local risky=not flag_set(live.flags,1) or live.duck>=0.70 or shared.quality<0.65
    return risky and "Prefer" or nil,geometry.lethal_body and "Force" or nil,geometry.lethal_body and "two verified lethal body centers" or (risky and "observed air/duck/movement uncertainty" or "observed geometry; native unchanged")
  end)
  if not ok then N:request("body",nil);self.auto_body_state="geometry API unavailable";return nil end
  N:request("body",body);self.auto_body_state=why or "native unchanged";return safe
end
function R:plan_safety(predict)
  local t = clock()
  local auto_safe=self:auto_geometry()
  if not N.slots.safe.ref then
    self.assist_force=nil
    self.plan = get_bool(cfg.resolver) and get_bool(cfg.assist) and "Assist ON but native Safe Points slot unbound (no-op)" or "Assist OFF (no native safety request)"
    N:request("safe", nil)
    return
  end
  if get_bool(cfg.resolver) and get_bool(cfg.yaw) and not get_bool(cfg.assist) then
    self.assist_force=nil
    N:request("safe",auto_safe)
    self.plan=auto_safe and ("Auto resolver safety: "..auto_safe.."; "..tostring(self.auto_body_state)) or "Auto resolver safety: no observed risk; native unchanged"
    return
  end
  if not get_bool(cfg.resolver) or not get_bool(cfg.assist) then
    self.assist_force=nil
    self.plan = "Assist OFF (master or user toggle)"
    N:request("safe", nil)
    return
  end
  local found, ent = pcall(function ()
    return entity.get_threat()
  end)
  if not found or not ent then
    self.assist_force=nil
    self.plan = "native aim; no current threat"
    ;
    N:request("safe", nil)
    ;
    return
  end
  local live, why = self:snapshot(ent)
  if not live then
    self.assist_force=nil
    self.plan = why
    ;
    N:request("safe", nil)
    ;
    return
  end
  local desired = auto_safe
  local reasons = { }
  local s = self.players[live.id]
  local fresh = s and s.uid == live.uid and s.clean==true and s.data and t - (s.sample_time or 0) <= LIMITS.fresh_age and t >= (s.sample_time or t) and math.abs(live.sim - s.data.sim) <= 0.0001
  fresh=fresh and Y.core:matches_live(live,globals.tickcount)
  local lag, lag_source = live.lag, live.lag_source
  local lag_hard, lag_soft = lag and (lag >= LIMITS.lag_hard), lag and (lag >= LIMITS.lag_soft)
  if fresh and lag_hard then
    fresh = false
    reasons[# reasons + 1] = string.format("sample %.3fs behind server time (%s)", lag, lag_source or "?")
  end
  if fresh then
    if predict and not lag_soft then
      self:predict(s, live)
    end
    local risks, risk_desired = self:reasons(s)
    for _, reason in ipairs(risks) do
      reasons[# reasons + 1] = reason
    end
    if risk_desired then
      desired = risk_desired
    end
    if lag_soft then
      reasons[# reasons + 1] = string.format("server-lag sample %.3fs (%s); extrapolation withheld", lag, lag_source or "?")
      if not desired or SAFE_RANK["Prefer"] > SAFE_RANK[desired] then
        desired = "Prefer"
      end
    end
    local YL = Y.learn and Y.learn[live.id]
    if YL and YL.__uid~=live.uid then YL=nil end
    local state = YL and YL.__state or "unknown"
    local jitter = YL and (number(YL.jitter) or 0) or 0
    local static_conf = YL and (number(YL.static_confidence) or 0) or 0
    local learned_conf, hits, misses = self:candidate_confidence(YL, state)
    local stable = YL and (number(YL.state_stability) or 0) >= 3
    local hot = stable and hits >= 2 and learned_conf >= 0.48 and hits > misses * 1.15
    if hot then
      desired = "Force"
      ;
      reasons[# reasons + 1] = string.format("state candidate confidence %.2f", learned_conf)
    elseif stable and static_conf >= 0.58 and jitter >= 0.68 then
      desired = "Force"
      ;
      reasons[# reasons + 1] = "stable static high-jitter evidence"
    elseif YL and YL.side_switch and (YL.record_quality or 0) >= 0.45 then
      if not desired or SAFE_RANK["Prefer"] > SAFE_RANK[desired] then
        desired = "Prefer"
      end
      reasons[# reasons + 1] = "fresh desync side switch"
    elseif YL and YL.micro_move and jitter >= 0.30 then
      if not desired or SAFE_RANK["Prefer"] > SAFE_RANK[desired] then
        desired = "Prefer"
      end
      reasons[# reasons + 1] = "micro-movement resolver uncertainty"
    elseif YL and YL.break_lc then
      if not desired or SAFE_RANK["Prefer"] > SAFE_RANK[desired] then
        desired = "Prefer"
      end
      reasons[# reasons + 1] = "resolver record gap / lag-comp break"
    elseif not desired and (static_conf >= 0.34 or jitter >= 0.40 or (s.corrections or 0) > 0) then
      desired = "Prefer"
      ;
      reasons[# reasons + 1] = "uncertain resolver geometry: prefer safety"
    end
  else
    reasons[# reasons + 1] = "waiting for exact fresh threat record"
  end
  if not fresh or not desired then self.assist_force=nil;desired=nil
  elseif desired=="Force" then
    local f=self.assist_force
    if not f or f.id~=live.id or f.uid~=live.uid or t<f.time or t-f.time>LIMITS.fresh_age then f={id=live.id,uid=live.uid,sim=live.sim,count=1,time=t};self.assist_force=f
    elseif math.abs(f.sim-live.sim)>0.0001 then f.sim=live.sim;f.count=f.count+1;f.time=t end
    if f.count<2 then desired="Prefer";reasons[#reasons+1]="Force waiting for second distinct fresh sample" end
  else self.assist_force=nil end
  self.plan = # reasons > 0 and table.concat(reasons, " + ") or "native aim; no risk request"
  self.desired_safe = desired
  N:request("safe", desired)
  N:drive_extrapolation(t)
end
function R:prediction_only()
  local t = clock()
  if not globals or globals.is_in_game ~= true then
    self.prediction_state = "not in game"
    N:drive_extrapolation(t)
    return
  end
  if not get_bool(cfg.extrapolation) then
    N:drive_extrapolation(t)
    return
  end
  if not N:master_enabled() then
    self.prediction_state = "native Ragebot off; prediction idle"
    N:drive_extrapolation(t)
    return
  end
  local ok, threat = pcall(function () return entity.get_threat() end)
  if not ok or not threat then
    self.prediction_state = "waiting for live threat"
    N:drive_extrapolation(t)
    return
  end
  local live = self:snapshot(threat)
  if not live then
    self.prediction_state = "waiting for valid threat snapshot"
    N:drive_extrapolation(t)
    return
  end
  local record = self.players[live.id]
  local fresh = record and record.uid == live.uid and record.data and math.abs(live.sim - record.data.sim) <= 0.0001 and t - (record.sample_time or 0) <= LIMITS.fresh_age and t >= (record.sample_time or t)
  if fresh then
    self:predict(record, live)
  else
    self.prediction_state = "waiting for fresh network data"
  end
  N:drive_extrapolation(t)
end
function R:step(cmd)
  local t = clock()
  if t < self.last_clock then
    self:reset("clock reset")
  end
  self.last_clock = t
  if not self:ensure_context() then
    return
  end
  local ok, sequence = pcall(function ()
    return number(cmd.command_number)
  end)
  if not ok or not sequence then
    self.plan = "command number unavailable"
    ;
    N:request("safe", nil)
    ;
    return
  end
  if sequence == self.last_command then
    return
  end
  self.last_command, self.last_step = sequence, t
  self.command_count = self.command_count + 1
  self:prediction_only()
  self:plan_safety(true)
end
function R:fire(event)
  local ok, id, ent, bt = pcall(function ()
    return number(tonumber(event.id)), event.target, number(tonumber(event.backtrack))
  end)
  if not ok or not id or id<0 or id%1~=0 then return end
  local slot, uid = self:identity(ent)
  if not slot then
    return
  end
  self:trim()
  local existing=self.shots[id]
  if existing and existing.id==slot and existing.uid==uid and existing.epoch==self.epoch and existing.sdk_fire_tick==number(globals.tickcount)then return end
  local count, oldest, oldest_t = 0, nil, math.huge
  for key, shot in pairs(self.shots) do
    count = count + 1
    if shot.time < oldest_t then
      oldest, oldest_t = key, shot.time
    end
  end
  if count >= LIMITS.max_shots then
    self.shots[oldest] = nil
  end
  self.sequence = self.sequence + 1
  local ffi_first=Y.ffi_service and Y.ffi_service:fire(id,slot,uid)or nil
  local value, owned = N:fire_state()
  local YL = Y.learn and Y.learn[slot] or nil
  local timing_at_fire = Y:timing_decision(slot)
  local evidence=Y.shot_evidence(ent,bt,id)
  local yaw_base=evidence.base
  local yaw_applied=evidence.valid and evidence.yaw or nil
  local yaw_corr = (yaw_base and yaw_applied) and Y_norm(yaw_applied - yaw_base) or nil
  if YL then
    local wide = (tonumber(YL.resolve_wide_rejects) or 0) - (tonumber(YL.__wide_reported) or 0)
    if wide > 0 then
      Y.population.wide_rejects = (Y.population.wide_rejects or 0) + wide
      YL.__wide_reported = tonumber(YL.resolve_wide_rejects) or 0
    end
  end
  local server_tick, server_source = self:server_tick()
  local server_time = self:to_time(server_tick)
  local dead_info = self:dead_time()
  local rec = self.players[slot]
  local live = rec and rec.data or nil
  self.shots[id] = {
    sdk_fire_tick=number(globals.tickcount),
    ffi_first=ffi_first,
    native_fix_state = Y.native_fix_state,
    evidence_schema=2,
    evidence_reason=evidence.reason,
    native_context_calls=evidence.native_context_calls,native_own_returns=evidence.native_own_returns,native_token=evidence.native_token,native_snapshot=evidence.native_snapshot,native_context=evidence.native_context,
    yaw_execution=evidence.execution,
    prior_readback_receipt=evidence.prior_readback or false,
    resolver_status=evidence.valid and (evidence.status or "current target readback") or ("Yaw withheld/unverified: "..evidence.reason),
    record_guard=not evidence.valid,
    timing_status = timing_at_fire.status,
    timing_confidence = timing_at_fire.confidence,
    air_stop_state = FS.air_state or "OFF",
    id = slot,
    uid = uid,
    time = clock(),
    sequence = self.sequence,
    epoch = self.epoch,
    tag = self:tag(ent, slot),
    backtrack = bt,
    interval = self:interval(),
    safe_value = value,
    safe_owned = owned,
    resolver = get_bool(cfg.resolver) and get_bool(cfg.assist),
    defensive = timing_at_fire.defensive==true,
    yaw_bucket=evidence.valid and (YL.__cur or "unknown") or ("unverified/"..evidence.execution),
    yaw_state = (YL and YL.__state) or "unknown",
    yaw_mode=get_bool(cfg.resolver)and Y.mode_label()or "Native",
    yaw_value = yaw_applied,
    yaw_base = yaw_base,
    yaw_applied = yaw_applied,
    yaw_candidate=evidence.valid and evidence.yaw or nil,
    yaw_write_verified=evidence.valid,
    lerp_seconds = self:record_lerp(),
    auto_body_state = self.auto_body_state,
    timing_evidence = timing_at_fire.evidence,
    air_hc_floor = FS.air_hc_floor,
    air_damage_floor = FS.air_damage_floor,
    air_sample_age = FS.air_sample_tick and globals.tickcount-FS.air_sample_tick or nil,
    packet_action = Y.packet_action or "none",
    yaw_corr = yaw_corr,
    yaw_band = log_delta_band(yaw_corr),
    yaw_side = (YL and tonumber(YL.__side)) or nil,
    yaw_pose = (YL and tonumber(YL.__delta)) or nil,
    resolver_confidence = (YL and tonumber(YL.static_confidence)) or 0,
    feedback_bias = (YL and tonumber(YL.feedback_bias)) or 0,
    server_tick = server_tick,
    server_tick_source = server_source,
    server_time = server_time,
    lag = live and self:lag_time(live.sim),
    lag_source = live and live.lag_source,
    dead_time = dead_info and dead_info.time,
    dead_tick = dead_info and dead_info.tick,
    latency = dead_info and dead_info.latency,
    max_unlag = dead_info and dead_info.max_unlag,
    evalate_active = YL and YL.__cur == "adaptive_evalate" or false,
    evalate_brute = (YL and tonumber(YL.evalate_brute)) or 1,
    evalate_forced = (YL and tonumber(YL.evalate_forced)) or nil,
    evalate_confidence = (YL and tonumber(YL.evalate_confidence)) or 0,
    record_quality = (YL and tonumber(YL.record_quality)) or 0,
    beta_confidence = (YL and tonumber(YL.beta_confidence)) or 0,
    adaptive_confidence = (YL and tonumber(YL.adaptive_confidence)) or 0,
    ult_confidence = (YL and tonumber(YL.ult_confidence)) or 0,
    adaptive_anim_proxy = (YL and tonumber(YL.adaptive_anim_proxy)) or 0,
    adaptive_roll_pose = (YL and tonumber(YL.adaptive_roll_pose)) or nil,
    side_switch = YL and YL.side_switch or false,
    micro_move = YL and YL.micro_move or false,
    active = self.ready and not self.fault and not self.suspended and N:master_enabled()
  }
  self.audit_shots=self.audit_shots or {}
  self.audit_shots[id]=self.shots[id]
  local now=clock();local count,oldest,oldest_time=0,nil,math.huge
  for key,shot in pairs(self.audit_shots) do
    if now<shot.time or now-shot.time>LIMITS.shot_age then self.audit_shots[key]=nil
    else count=count+1;if shot.time<oldest_time then oldest,oldest_time=key,shot.time end end
  end
  if count>LIMITS.max_shots and oldest then self.audit_shots[oldest]=nil end

end
function R:find_ack_shot(id,ent)
  if id==nil then return nil,nil,"missing ACK id" end
  local shot=self.shots[id] or self.shots[tostring(id)] or (self.audit_shots and (self.audit_shots[id] or self.audit_shots[tostring(id)]))
  if not shot then return nil,nil,"missing fire receipt" end
  if ent then local idx,uid=self:identity(ent);if idx~=shot.id or uid~=shot.uid then return nil,nil,"ACK target identity mismatch" end end
  if clock()<shot.time or clock()-shot.time>LIMITS.shot_age then return nil,nil,"receipt expired or clock reset" end
  local key=(self.shots[id] or (self.audit_shots and self.audit_shots[id])) and id or tostring(id)
  return shot,key,shot.epoch==self.epoch and "current context" or "retained logging receipt; learning disabled"
end

function R:ack(event)
  local ok, id, ent, reason = pcall(function ()
    local r = event.state
    if r == nil then
      r = event.reason
    end
    return number(tonumber(event.id)), event.target, r
  end)
  if not ok then
    return
  end
  local shot, shot_key,correlation_reason = self:find_ack_shot(id, ent)
  self.correlation_reasons=self.correlation_reasons or {}
  self.correlation_reasons[correlation_reason]=(self.correlation_reasons[correlation_reason] or 0)+1
  if self.audit_shots and id then self.audit_shots[id]=nil;self.audit_shots[tostring(id)]=nil end
  if shot_key then
    self.shots[shot_key] = nil
  elseif id then
    self.shots[id] = nil
  end
  if shot and Y.ffi_service then Y.ffi_service:ack(shot.ffi_first,reason)end
  local stat_mode = "Unmatched"
  if shot then
    if type(shot.yaw_mode) == "string" and shot.yaw_mode ~= "" then
      stat_mode = shot.yaw_mode.." / "..tostring(shot.yaw_execution or "legacy")
    else
      local ok_mode, current_mode = pcall(Y.mode_label)
      if ok_mode and type(current_mode) == "string" and current_mode ~= "" then
        stat_mode = current_mode
      end
    end
  end
  local mode_row = Y.mode_stats[stat_mode] or { hits = 0, misses = 0, correction = 0 }
  Y.mode_stats[stat_mode] = mode_row
  if reason ~= nil then
    mode_row.misses = (mode_row.misses or 0) + 1
    Y.population.misses = (Y.population.misses or 0) + 1
    local mode_reason = tostring(reason):lower():gsub("^%s+", ""):gsub("%s+$", "")
    if mode_reason == "correction" then
      local ack_spread = tonumber(event.spread)
      if ack_spread == nil or ack_spread < FEEDBACK_CFG.max_learning_spread then
        mode_row.correction = (mode_row.correction or 0) + 1
      end
    end
    Y:guard(Y.log_miss_ack, event, shot)
  else
    mode_row.hits = (mode_row.hits or 0) + 1
    Y.ack_stats.hits = (Y.ack_stats.hits or 0) + 1
    Y.population.hits = (Y.population.hits or 0) + 1
  end
  local pop = Y.population
  pop.acks = (pop.acks or 0) + 1
  if shot then
    pop.correlated = (pop.correlated or 0) + 1
  end
  if shot and shot.active and shot.epoch == self.epoch and not self.suspended and not self.fault then
    pop.matched = (pop.matched or 0) + 1
  end
  local hit_bucket = (shot and type(shot.yaw_bucket) == "string") and shot.yaw_bucket or ""
  if hit_bucket ~= "" then
    local brow = Y.bucket_stats[hit_bucket] or { h = 0, m = 0 }
    Y.bucket_stats[hit_bucket] = brow
    if reason == nil then
      brow.h = (brow.h or 0) + 1
    else
      brow.m = (brow.m or 0) + 1
    end
    local dkey = tostring((shot and shot.yaw_band) or "?") .. "/" .. log_delta_side(shot)
    local drow = Y.delta_stats[hit_bucket] or { }
    Y.delta_stats[hit_bucket] = drow
    local cell = drow[dkey] or { h = 0, m = 0 }
    drow[dkey] = cell
    if reason == nil then
      cell.h = (cell.h or 0) + 1
    else
      cell.m = (cell.m or 0) + 1
    end
  end
  Y.miss_state.bucket_stats = Y.bucket_stats
  Y.miss_state.delta_stats = Y.delta_stats
  Y.miss_state.population = Y.population
  Y.miss_state.mode_stats = Y.mode_stats
  if not id or not shot or not shot.active or shot.epoch ~= self.epoch or self.suspended or self.fault then
    return
  end
  local t = clock()
  if t < shot.time or t - shot.time > LIMITS.shot_age then
    return
  end
  local index, uid = self:identity(ent)
  if index ~= shot.id or uid ~= shot.uid then
    return
  end
  local s = self.players[index]
  if not s or s.uid ~= uid or shot.sequence <= (s.last_ack_sequence or 0) then
    return
  end
  s.last_ack_sequence = shot.sequence
  if reason == nil then
    s.corrections = 0
    ;
    s.correction_since = nil
    ;
    s.risks.resolver = nil
    ;
    s.risks.resolver_probe = nil
    return
  end
  local reason_key = tostring(reason):lower():gsub("^%s+", ""):gsub("%s+$", "")
  if reason_key == "correction" and shot.resolver and shot.evidence_schema==2 and shot.yaw_write_verified and get_bool(cfg.resolver) and get_bool(cfg.assist) then
    if not s.correction_since or t - s.correction_since > LIMITS.correction_window then
      s.corrections, s.correction_since = 0, t
    end
    s.corrections = s.corrections + 1
    self.correction_signals = self.correction_signals + 1
    Y:guard(Y.note_miss, ent)
    if s.corrections == 1 then
      self:mark(s, "resolver_probe", "first exact correction miss", 0.45)
    end
    if s.corrections >= 2 then
      self:mark(s, "resolver", "repeated correction misses", LIMITS.assist_duration)
      s.corrections, s.correction_since = 0, nil
    end
  elseif (reason_key == "prediction error" or reason_key == "misprediction" or reason_key == "backtrack failure") and shot.defensive then
    if self:mark(s, "defensive", "native shot timing / prediction failure", 0.6) then
      self.defensive_signals = self.defensive_signals + 1
    end
  end
end
function R:player_left(event)
  local ok, uid = pcall(function ()
    return number(event.userid)
  end)
  if not ok or not uid then
    return
  end
  if uid == self.local_uid then
    self:reset("local player death/disconnect")
    ;
    return
  end
  for id, s in pairs(self.players) do
    if s.uid == uid then
      self.players[id] = nil
    end
  end
  for id, shot in pairs(self.shots) do
    if shot.uid == uid then
      self.shots[id] = nil
    end
  end
  N:request("safe", nil)
end
function R:status(force)
  local t = clock()
  if not force and self.status_at >= 0 and t - self.status_at < 0.25 then
    return self.status_cache
  end
  self.status_at = t
  local slot = N.slots.safe
  self.status_cache = string.format("Assist %s | Safe Points %s | plan: %s",
    (get_bool(cfg.resolver) and get_bool(cfg.assist)) and "ON" or "OFF",
    tostring((slot and slot.state) or "unavailable"),
    tostring(self.plan or "-"))
  return self.status_cache
end
function R:frame()
  local t = clock()
  if t < self.last_clock then
    self:reset("clock reset")
  end
  self.last_clock = t
  if t >= self.last_frame and t - self.last_frame < 0.1 then
    return
  end
  self.last_frame = t
  N:retry_bind()
  if not self:ensure_context() or not self.last_step or t - self.last_step > LIMITS.command_watchdog then
    N:request("safe", nil)
    N:request("body", nil)
    N:request("air_strafe",nil)
    if self.in_session then
      self.plan = "idle command watchdog; safety request released"
    end
  else
    self:plan_safety(false)
  end
  self:trim()
  self:status()
end
function R:guard(method, ...)
  local ok, err = pcall(method, self, ...)
  if not ok then
    self.fault = "safety coordinator error; safety request released"
    self.fault_until = clock() + 5
    N:release("safe")
    N:release("body")
    warn_once("coordinator_fault", self.fault .. ": " .. tostring(err):gsub("%c", " "))
    self:status(true)
  end
end
local AH = (function ()
local ah_lagrecord_ok, ah_lagrecord_module = false, nil
local AH = {
  refs = {},
  records = {},
  previous_records = {},
  lagrecord = nil,
  lagrecord_field = nil,
  lagrecord_checked = false,
  warned_lagrecord = false,
  fake_lag_active = false,
  fake_lag_enabled_owned = false,
  fake_lag_limit_owned = false,
  fake_lag_var_owned = false,
  fake_lag_limit_value = nil,
  fake_lag_var_value = nil,
  latency_owned = false,
  latency_value = nil,
  saved_unlag = nil,
  saved_interp_ratio = nil,
  clock_owned = false,
  saved_clock_correction = nil,
  delay_owned = false,
  fake_lag_roll = 0,
  fake_lag_state = nil,
  fake_lag_limit = 1,
  fake_lag_var = 0,
  last_lag_roll = nil,
  ping_roll = 0,
  ping_last = nil,
  shot_flying = false,
  shoot_lag = nil,
  aimed_hold = 0,
  hit_flush = 0,
  last_health = nil,
  ground_ticks = 0,
  last_tickbase = 0,
  desync_ticks = 0,
  uncharge_target = nil,
  uncharge_until = 0,
  uncharge_last_fire = {},
}
local function ah_find(paths)
  for _, path in ipairs(paths) do
    local ok, ref = pcall(function () return ui.find(unpack(path)) end)
    if ok and ref then return ref end
  end
  return nil
end
local function ah_random(a, b)
  local ok, value = pcall(function () return utils.random_int(a, b) end)
  if ok and number(value) then return math.floor(value) end
  return math.random(a, b)
end
local function ah_override(ref, value)
  if not ref then return false end
  return pcall(function ()
    if value == nil then ref:override() else ref:override(value) end
  end)
end
local function ah_get_override(ref)
  if not ref then return false, nil end
  return pcall(function () return ref:get_override() end)
end
local function ah_get(ref)
  if not ref then return nil end
  local ok, value = pcall(function () return ref:get() end)
  return ok and value or nil
end
function AH:bind()
  if self.bound then return end
  self.bound = true
  self.refs.fake_lag_enabled = ah_find({ {"Aimbot","Anti Aim","Fake Lag","Enabled"} })
  self.refs.fake_lag_limit = ah_find({ {"Aimbot","Anti Aim","Fake Lag","Limit"} })
  self.refs.fake_lag_variability = ah_find({ {"Aimbot","Anti Aim","Fake Lag","Variability"} })
  self.refs.fake_latency = ah_find({ {"Miscellaneous","Main","Other","Fake Latency"} })
  self.refs.fake_duck = ah_find({ {"Aimbot","Anti Aim","Misc","Fake Duck"}, {"Aimbot","Anti Aim","Misc","Fake duck"} })
  self.refs.slow_walk = ah_find({ {"Aimbot","Anti Aim","Misc","Slow Walk"}, {"Aimbot","Anti Aim","Misc","Slow walk"} })
  self.refs.double_tap = ah_find({ {"Aimbot","Ragebot","Main","Double Tap"}, {"Aimbot","Ragebot","Exploits","Double Tap"} })
  self.refs.hide_shots = ah_find({ {"Aimbot","Ragebot","Main","Hide Shots"}, {"Aimbot","Ragebot","Exploits","Hide Shots"} })
  self.refs.delay_shot = ah_find({ {"Aimbot","Ragebot","Selection","Min. Damage","Delay Shot"}, {"Aimbot","Ragebot","Selection","Minimum Damage","Delay Shot"} })
end
function AH:init_lagrecord()
  if self.lagrecord_checked then return self.lagrecord ~= nil end
  self.lagrecord_checked = true
  if not ah_lagrecord_ok or not ah_lagrecord_module then return false end
  local function accept(candidate)
    if candidate == nil then return false end
    local ok_snapshot, snapshot = pcall(function () return candidate.get_snapshot end)
    if ok_snapshot and type(snapshot) == "function" then
      self.lagrecord, self.lagrecord_field = candidate, "get_snapshot"
      return true
    end
    local ok_get, getter = pcall(function () return candidate.get end)
    if ok_get and type(getter) == "function" then
      self.lagrecord, self.lagrecord_field = candidate, "get"
      return true
    end
    local ok_legacy, legacy = pcall(function () return candidate.snapshot end)
    if ok_legacy and type(legacy) == "function" then
      self.lagrecord, self.lagrecord_field = candidate, "snapshot"
      return true
    end
    return false
  end
  if accept(ah_lagrecord_module) then return true end
  local signed_ok, signed = pcall(function () return ah_lagrecord_module.SIGNED end)
  if signed_ok and accept(signed) then return true end
  if signed_ok and type(signed) == "function" then
    local made_ok, made = pcall(signed)
    if made_ok and accept(made) then return true end
  end
  return false
end
function AH:read_lagrecord(player)
  if not self:init_lagrecord() then return nil end
  local ok, record
  if self.lagrecord_field == "get_snapshot" then
    ok, record = pcall(self.lagrecord.get_snapshot, player)
  elseif self.lagrecord_field == "get" then
    ok, record = pcall(self.lagrecord.get, player)
  else
    ok, record = pcall(self.lagrecord.snapshot, player)
  end
  return ok and record or nil
end
local function ah_to_ticks(seconds)
  local interval = number(globals and globals.tickinterval) or (1 / 64)
  if interval <= 0 then interval = 1 / 64 end
  return math.floor((number(seconds) or 0) / interval + 0.5)
end
local function ah_simulate(origin, velocity, ticks)
  local pos = vector(origin.x, origin.y, origin.z)
  local vel = vector(velocity.x, velocity.y, velocity.z)
  local interval = number(globals and globals.tickinterval) or (1 / 64)
  local gravity, friction, stopspeed = 800, 5, 75
  pcall(function () if cvar.sv_gravity then gravity = cvar.sv_gravity:float() end end)
  pcall(function () if cvar.sv_friction then friction = cvar.sv_friction:float() end end)
  pcall(function () if cvar.sv_stopspeed then stopspeed = cvar.sv_stopspeed:float() end end)
  for _ = 1, math.max(0, math.min(16, ticks)) do
    vel.z = vel.z - gravity * interval
    local speed = math.sqrt(vel.x * vel.x + vel.y * vel.y)
    if speed > 0 then
      local drop = (speed < stopspeed and stopspeed or speed) * friction * interval
      local scale = math.max(speed - drop, 0) / speed
      vel.x, vel.y = vel.x * scale, vel.y * scale
    end
    pos = pos + vel * interval
  end
  return pos
end
local function ah_record_number(value, fallback)
  value = number(value)
  if value == nil then return fallback end
  return value
end
function AH:normalize_uncharge_record(player, raw, previous)
  local sim, raw_previous_sim, shift, no_entry, origin, velocity
  local explicit = false
  if raw then
    pcall(function ()
      local st = raw.simulation_time
      if type(st) == "table" then
        sim = ah_record_number(st.current, sim)
        raw_previous_sim = ah_record_number(st.previous, raw_previous_sim)
      else
        sim = ah_record_number(st, sim)
      end
      local command = raw.command
      if type(command) == "table" then
        if command.shifting ~= nil then explicit = true; shift = ah_record_number(command.shifting, 0) end
        local no = command.no_entry
        if type(no) == "table" and no.y ~= nil then explicit = true; no_entry = ah_record_number(no.y, 0) end
      end
      local ro = raw.origin
      if type(ro) == "table" and ro.current then origin = ro.current end
    end)
  end
  pcall(function ()
    if sim == nil then
      sim = ah_record_number(player.m_flSimulationTime, nil)
      if sim == nil then
        local st = player:get_simulation_time()
        sim = type(st) == "table" and ah_record_number(st.current, nil) or ah_record_number(st, nil)
      end
    end
    origin = origin or player.m_vecOrigin or player:get_origin()
    velocity = player.m_vecVelocity
  end)
  if sim == nil then return nil end
  local sim_tick = ah_to_ticks(sim)
  local previous_tick = previous and previous.sim_tick or ah_to_ticks(raw_previous_sim or sim)
  local changed = not previous or sim_tick ~= previous.sim_tick
  local advance = changed and math.max(0, sim_tick - previous_tick) or 0
  local stall = 0
  if previous then
    stall = changed and 0 or math.min(32, (previous.stall or 0) + math.max(1, globals.tickcount - (previous.seen_tick or globals.tickcount)))
  end
  if shift == nil then
    shift = changed and 0 or math.min(16, stall)
  end
  no_entry = no_entry or 0
  return {
    raw = raw,
    simulation_time = sim,
    sim_tick = sim_tick,
    shift = clamp(math.floor(shift + 0.5), 0, 16),
    no_entry = no_entry,
    explicit = explicit,
    origin = origin,
    velocity = velocity,
    seen_tick = globals.tickcount,
    changed = changed,
    advance = advance,
    stall = stall,
  }
end
function AH:update_uncharge_records()
  self.records = Y.timing_states
  self.previous_records = {}
end
function AH:release_uncharge()
  if self.delay_owned then ah_override(self.refs.delay_shot, nil); self.delay_owned = false end
  if self.clock_owned then
    pcall(function () if cvar.cl_clock_correction then cvar.cl_clock_correction:int(self.saved_clock_correction or 1, true) end end)
    self.clock_owned = false
  end
  self.uncharge_target, self.uncharge_until = nil, 0
end
function AH.auto_uncharge_policy(decision,shared,observed,tick)
  if not shared or not observed or not number(tick) then return nil,"waiting for observations" end
  if not number(observed.tick) or tick<observed.tick or tick-observed.tick>2 then return nil,"waiting for fresh evidence" end
  if decision.defensive and (decision.confidence or 0)>=0.75 and decision.evidence=="simulation_rollback" then
    return "fresh simulation rollback","rollback:"..tostring(observed.generation)..":"..tostring(observed.risk_until)
  end
  if decision.burst and (decision.confidence or 0)>=0.75 and decision.evidence=="burst_with_observed_shot" and not shared.invalid then
    return "verified excess advance + observed shot","burst:"..tostring(observed.generation)..":"..tostring(observed.burst_until)
  end
  if shared.anticipated and not shared.invalid and shared.quality>=0.75 and number(shared.next_window) then
    return "recurring observed gap/shot window","window:"..tostring(shared.next_window)
  end
  return nil,shared.invalid and "waiting for valid fresh record" or "observing; no substantiated window"
end
function AH:predict_uncharge(cmd)
  if cfg.runtime_paused or ANEMONE_SECOND_COPY then self.predict_state="paused";self:release_uncharge();return end
  if self.delay_owned then ah_override(self.refs.delay_shot,nil);self.delay_owned=false end
  if not cmd then return end
  Y.packet_action="none"
  if not get_bool(cfg.predict_exploit_uncharge) then
    self.packet_pending=nil;self.auto_seen=nil;self.auto_cooldown=0
    self.predict_state="OFF";self:release_uncharge();return
  end
  local seq=number(cmd.command_number)
  if not seq then self.predict_state="command identity unavailable";return end
  if self.predict_last_command==seq then return end
  if self.predict_last_command and seq<self.predict_last_command then self.auto_seen=nil;self.auto_cooldown=0 end
  self.predict_last_command=seq
  if not globals or globals.is_in_game~=true or not N:master_enabled() then self.predict_state="no live Ragebot context";return end
  self:bind()
  local ok,me,threat,index,uid=pcall(function ()
    local me=entity.get_local_player();local target=entity.get_threat()
    if not me or not me:is_alive() or not target or not target:is_alive() or target:is_dormant() or not target:is_enemy() then return nil end
    return me,target,target:get_index(),target:get_player_info().userid
  end)
  if not ok or not me or not index or not uid then self.predict_state="no live threat";return end
  local tick=number(globals.tickcount)
  local decision=Y:timing_decision(index)
  local observed=Y.timing_states[index]
  local shared=Y.observation_bridge:assessment(index,uid,tick,globals.tickinterval)
  if Y.native_records then
    local allowed,reason=Y.native_records:guard(threat,"predict")
    if not allowed then self.predict_state=reason.."; packet action withheld";return end
  end
  if not observed or observed.uid~=uid then self.predict_state="target identity changed; warming up";return end
  if shared then Y.observation_bridge:consume("predict") end
  self.observed_next_window=shared and shared.next_window or false
  self.timing_status=(decision.status or "unknown").." / observed="..tostring(shared and shared.status or "unavailable")
  local reason,key=AH.auto_uncharge_policy(decision,shared,observed,tick)
  if not reason then self.predict_state=key;return end
  local local_tb=UR:local_timing();local charge=UR:charge()
  Y.local_tickbase_status=local_tb and local_tb.status or "unavailable"
  local busy=(local_tb and (local_tb.status=="local rollback" or local_tb.status=="local burst")) or charge==nil or (get_bool(self.refs.double_tap) and charge<0.99) or (charge>0 and charge<0.99)
  local action=command_attack(cmd) or cmd.in_use==true or cmd.in_use==1 or cmd.in_reload==true or cmd.in_reload==1
  local native_busy=get_bool(self.refs.fake_duck) or get_bool(self.refs.hide_shots)
  if busy or action or native_busy then
    self.predict_state="window observed; preserving local exploit/action"
    self.auto_suppressed=(self.auto_suppressed or 0)+1;return
  end
  key=tostring(uid)..":"..key
  if self.auto_seen==key or tick<(self.auto_cooldown or 0) then self.predict_state="window observed; duplicate/cooldown";return end
  cmd.send_packet,cmd.no_choke=true,true
  self.auto_seen,self.auto_cooldown=key,tick+4
  self.auto_flushes=(self.auto_flushes or 0)+1
  self.predict_state="auto flush: "..reason
  Y.packet_action=self.predict_state
end
function AH:local_state(me)
  local flags, vel = 1, nil
  pcall(function () flags = tonumber(me.m_fFlags) or 1; vel = me.m_vecVelocity end)
  local on_ground = bit and bit.band and bit.band(flags, 1) == 1 or flags % 2 == 1
  local ducked = bit and bit.band and bit.band(flags, 2) == 2 or false
  self.ground_ticks = on_ground and ((self.ground_ticks or 0) + 1) or 0
  local speed = vel and math.sqrt((number(vel.x) or 0)^2 + (number(vel.y) or 0)^2) or 0
  local fake_duck = ah_get(self.refs.fake_duck) == true
  local double_tap = ah_get(self.refs.double_tap) == true
  local hide_shots = ah_get(self.refs.hide_shots) == true
  local slow_walk = ah_get(self.refs.slow_walk) == true
  if not fake_duck and not double_tap and not hide_shots then
    return "Fake lag", speed
  elseif self.ground_ticks > 5 then
    if fake_duck and not ducked then return "Fake duck", speed end
    if speed > 5 then return slow_walk and "Walk" or (ducked and "Crawl" or "Run"), speed end
    return ducked and "Duck" or "Stand", speed
  end
  return ducked and "Air duck" or "Air", speed
end
function AH:update_shot_state(cmd, me)
  local weapon, last_shot
  pcall(function () weapon = me:get_player_weapon() end)
  if weapon then pcall(function () last_shot = weapon.m_fLastShotTime or weapon:get_prop("m_fLastShotTime") end) end
  local flying = cmd and (cmd.in_attack == true or cmd.in_attack == 1 or cmd.in_attack2 == true or cmd.in_attack2 == 1) or false
  if not flying and number(last_shot) then flying = ((number(globals.curtime) or 0) - last_shot) < 0.1 end
  self.shot_flying = flying
  local tickbase
  pcall(function () tickbase = number(me.m_nTickBase) end)
  if tickbase then
    if math.abs(tickbase - (self.last_tickbase or 0)) > 64 then self.last_tickbase = 0 end
    if (self.last_tickbase or 0) < tickbase then
      self.last_tickbase, self.desync_ticks = tickbase, 0
    elseif tickbase < (self.last_tickbase or 0) then
      self.desync_ticks = math.min(14, math.max(0, self.last_tickbase - tickbase - 1))
    else
      self.desync_ticks = 0
    end
  end
end
function AH:release_ping()
  if self.latency_owned then
    local ok, current = ah_get_override(self.refs.fake_latency)
    if ok and current == self.latency_value then ah_override(self.refs.fake_latency, nil) end
    self.latency_owned, self.latency_value = false, nil
  end
  if self.saved_unlag ~= nil and not self.fake_lag_active then
    pcall(function () if cvar.sv_maxunlag then cvar.sv_maxunlag:float(self.saved_unlag, true) end end)
    self.saved_unlag = nil
  end
  if self.saved_interp_ratio ~= nil then pcall(function () if cvar.cl_interp_ratio then cvar.cl_interp_ratio:int(self.saved_interp_ratio, true) end end) end
  self.saved_interp_ratio = nil
end
function AH:ping_spike()
  if not get_bool(cfg.ping_spike) then self:release_ping();return end
  self:bind()
  local measured=0
  pcall(function () local channel=utils.net_channel();if channel and channel.latency then measured=(number(channel.latency[0]) or 0)*1000 end end)
  local desired=math.floor(clamp(180-measured,0,140)+0.5)
  if self.shot_flying then return end
  local ok,current=ah_get_override(self.refs.fake_latency)
  if self.latency_owned and ok and current~=self.latency_value then self.latency_owned=false;return end
  if self.latency_owned or (ok and (current==nil or current==false)) then
    if ah_override(self.refs.fake_latency,desired) then self.latency_owned,self.latency_value=true,desired end
  end
end
function AH:release_fake_lag()
  local entries = {
    { self.refs.fake_lag_enabled, "fake_lag_enabled_owned", true },
    { self.refs.fake_lag_limit, "fake_lag_limit_owned", self.fake_lag_limit_value },
    { self.refs.fake_lag_variability, "fake_lag_var_owned", self.fake_lag_var_value },
  }
  for _, entry in ipairs(entries) do
    if self[entry[2]] then
      local ok, current = ah_get_override(entry[1])
      if ok and current == entry[3] then ah_override(entry[1], nil) end
      self[entry[2]] = false
    end
  end
  self.fake_lag_active = false
  if not get_bool(cfg.ping_spike) and self.saved_unlag ~= nil then
    pcall(function () if cvar.sv_maxunlag then cvar.sv_maxunlag:float(self.saved_unlag, true) end end)
    self.saved_unlag = nil
  end
end
function AH:set_fake_lag_ref(ref, ownership_key, value_key, value)
  local ok, current = ah_get_override(ref)
  if self[ownership_key] and ok and current ~= self[value_key] then self[ownership_key] = false end
  if self[ownership_key] or (ok and current == nil) then
    if ah_override(ref, value) then self[ownership_key], self[value_key] = true, value end
  end
end
function AH:adaptive_fake_lag(me, state, speed)
  if not get_bool(cfg.adaptive_fakelags) then self:release_fake_lag(); return end
  self:bind()
  self.fake_lag_active = true
  self:set_fake_lag_ref(self.refs.fake_lag_enabled, "fake_lag_enabled_owned", "fake_lag_enabled_value", true)
  local in_air = state == "Air" or state == "Air duck"
  local exploit = ah_get(self.refs.double_tap) == true or ah_get(self.refs.hide_shots) == true
  local threat
  pcall(function () threat = entity.get_threat() end)
  local distance = 1000
  if threat then
    pcall(function ()
      local a, b = me:get_eye_position(), threat:get_eye_position()
      if a and b then distance = math.sqrt((a.x-b.x)^2 + (a.y-b.y)^2 + (a.z-b.z)^2) end
    end)
  end
  self.fake_lag_roll = (self.fake_lag_roll or 0) - 1
  if self.fake_lag_state ~= state then self.fake_lag_state, self.fake_lag_roll = state, 0 end
  local health = 100
  pcall(function () health = tonumber(me.m_iHealth) or 100 end)
  if self.last_health and health < self.last_health then self.hit_flush = ah_random(4, 8) end
  self.last_health = health
  if (self.hit_flush or 0) > 0 then
    self.hit_flush = self.hit_flush - 1
    self.fake_lag_limit, self.fake_lag_var = 1, 0
  elseif self.fake_lag_roll <= 0 and not self.shot_flying then
    local far = clamp((distance - 200) / 1200, 0, 1)
    local base = math.min(11, math.floor(1 + far * 13 + (in_air and 3 or 0)))
    if state == "Fake lag" then
      base = clamp(base, 1, 4)
    elseif ah_get(self.refs.fake_duck) == true and not in_air then
      base = base + 1
    end
    if exploit then base = clamp(base - 2, 1, 10) end
    if threat then
      pcall(function ()
        local their_eye, our_eye, angles = threat:get_eye_position(), me:get_eye_position(), threat.m_angEyeAngles
        if their_eye and our_eye and angles then
          local yaw_to_us = math.deg(math.atan2(our_eye.y - their_eye.y, our_eye.x - their_eye.x))
          local delta = ((yaw_to_us - angles.y + 180) % 360) - 180
          self.aimed_hold = math.abs(delta) < 25 and 5 or math.max(0, (self.aimed_hold or 0) - 1)
          base = clamp(base + ((self.aimed_hold or 0) > 0 and 3 or -2), 1, 11)
        end
      end)
    end
    local trough = ah_random(0, 5) == 0
    local spike = (not trough and ah_random(0, 4) == 0) and ah_random(5, 9) or 0
    if trough then
      self.fake_lag_limit, self.fake_lag_var = ah_random(1, 2), ah_random(0, 5)
    else
      self.fake_lag_limit = math.max(1, base + ah_random(-3, 3) + spike)
      self.fake_lag_var = spike > 0 and ah_random(3, 7) or ah_random(0, 3)
    end
    local roll, guard = ah_random(4, 15), 6
    while guard > 0 and self.last_lag_roll and math.abs(roll - self.last_lag_roll) <= 1 do roll, guard = ah_random(4, 15), guard - 1 end
    self.last_lag_roll, self.fake_lag_roll = roll, roll
  end
  if speed > 120 then self.fake_lag_limit = clamp(self.fake_lag_limit - 4, 1, 8)
  elseif speed > 3 then self.fake_lag_limit = clamp(self.fake_lag_limit - 2, 1, 11) end
  if self.shot_flying then
    if not self.shoot_lag then self.shoot_lag = clamp(self.fake_lag_limit - 6, 1, 5) end
    self.fake_lag_limit = self.shoot_lag
  else self.shoot_lag = nil end
  local limit = math.min(self.fake_lag_limit, 11)
  local desync = number(self.desync_ticks) or 0
  local variability = math.max(in_air and desync + 5 or desync, self.fake_lag_var or 0)
  variability = clamp(variability, 0, 15)
  if variability > 0 and ah_random(0, 2) == 0 then variability = ah_random(0, math.min(15, variability + 4)) end
  self:set_fake_lag_ref(self.refs.fake_lag_limit, "fake_lag_limit_owned", "fake_lag_limit_value", limit)
  self:set_fake_lag_ref(self.refs.fake_lag_variability, "fake_lag_var_owned", "fake_lag_var_value", variability)
end
function AH:on_net_update()
  local ok, err = pcall(function () self:update_uncharge_records() end)
  if not ok then warn_once("adaptive_helpers_uncharge_update", tostring(err):gsub("%c", " "):sub(1, 120)) end
end
function AH:on_createmove(cmd)
  if cfg.runtime_paused or ANEMONE_SECOND_COPY then self:reset();return end
  local ok, err = pcall(function ()
    self:bind()
    local me = entity.get_local_player()
    local alive = false
    pcall(function () alive = me and me:is_alive() end)
    if not alive then
      self.shot_flying = false
      self:release_ping(); self:release_fake_lag(); self:release_uncharge()
      return
    end
    self:update_shot_state(cmd, me)
    self:ping_spike()
    local state, speed = self:local_state(me)
    self:adaptive_fake_lag(me, state, speed)
  end)
  if not ok then warn_once("adaptive_helpers_move", tostring(err):gsub("%c", " "):sub(1, 120)) end
end
function AH:reset()
  self.packet_pending, self.packet_cooldown = nil, 0
  self.auto_seen,self.auto_cooldown,self.predict_last_command=nil,0,nil
  self.records, self.previous_records = {}, {}
  self.fake_lag_roll, self.fake_lag_state, self.hit_flush = 0, nil, 0
  self.ground_ticks, self.last_tickbase, self.desync_ticks = 0, 0, 0
  self:release_uncharge(); self:release_ping(); self:release_fake_lag()
end
function AH:shutdown()
  self:reset()
end
return AH
end)()
Y.observation_bridge=(function()
  local M={records={},capacity=16,storage="not initialized",accepted=0,rejected=0,consumers={},local_record=nil}
  local fields={"sim","tick","uid","x","y","z","vx","vy","vz","yaw","lby","duck","shot","anim_limit","anim_valid"}
  local function num(x) return type(x)=="number" and x==x and math.abs(x)<math.huge and x or nil end
  local function norm(x) return (x+180)%360-180 end
  local function limit(x,a,b) return math.max(a,math.min(b,x)) end
  function M:init()
    if self.initialized then return self.ffi~=nil end
    self.initialized=true
    if not Y.core.ready then self.storage="FFI core unavailable";return false end
    local f=Y.core.ffi
    local ok=pcall(function()
      if not pcall(f.typeof,"anemone_observation_1856_v1")then f.cdef("typedef struct { double sim,tick,uid,x,y,z,vx,vy,vz,yaw,lby,duck,shot,anim_limit,anim_valid; } anemone_observation_1856_v1;")end
      assert(f.sizeof("anemone_observation_1856_v1")==120,"observation schema mismatch")
    end)
    if not ok then self.storage="FFI observation schema unavailable";return false end
    self.ffi=f;self.storage="FFI own-memory ring / shared core v47";return true
  end
  function M:reset()
    self.records={};self.local_record=nil;self.geometry_cache=nil;self.geometry_cache_tick=nil
    Y.core:reset()
  end
  function M:allocate(uid,tick)
    if not self:init()then return nil end
    local ok,buf=pcall(self.ffi.new,"anemone_observation_1856_v1[16]")
    if not ok then self.storage="FFI allocation failed; observation rejected";return nil end
    return {uid=uid,tick=tick,buffer=buf,ffi=true,head=-1,count=0,frontier=nil,events={},quality=0,status="warmup",horizon=1}
  end
  function M:ingest(id,d,iv)
    if not num(id) or id~=math.floor(id) or id<1 or id>64 or not num(iv) or iv<=0 or iv>0.1 then return false,"invalid identity/interval" end
    for _,k in ipairs({"uid","sim","tick","x","y","z","vx","vy","vz","yaw"}) do if not num(d[k]) then self.rejected=self.rejected+1;return false,"invalid "..k end end
    if d.uid<1 or d.uid~=math.floor(d.uid) or d.tick<0 or d.tick~=math.floor(d.tick) then self.rejected=self.rejected+1;return false,"invalid UID/tick" end
    if d.sim<0 or math.max(math.abs(d.vx),math.abs(d.vy),math.abs(d.vz))>4096 or math.max(math.abs(d.x),math.abs(d.y),math.abs(d.z))>1e7 then self.rejected=self.rejected+1;return false,"out of range" end
    local s=self.records[id]
    if not s or s.uid~=d.uid or d.tick<s.tick then s=self:allocate(d.uid,d.tick);self.records[id]=s end
    if not s then self.rejected=self.rejected+1;return false,"FFI storage unavailable"end
    Y.core:capture(id,d)
    local p=s.count>0 and s.buffer[s.head] or nil
    s.tick=d.tick
    if p and d.sim==tonumber(p.sim)then
      local changed=false
      for _,k in ipairs(fields)do if tonumber(p[k])~=(num(d[k])or 0)then changed=true;break end end
      if changed then
        for _,k in ipairs(fields)do p[k]=num(d[k])or 0 end
        s.assessment_cache=nil;s.assessment_count=0
        if self.geometry_cache then self.geometry_cache[id]=nil end
        s.quality=math.min(s.quality,0.5);s.horizon=1;s.status="same-simulation payload changed"
      end
      return true,changed and s.status or "duplicate"
    end
    local quality,status,horizon=1,"fresh",15
    local ds=p and d.sim-tonumber(p.sim) or nil
    if not p then quality,status,horizon=0.35,"warmup",1
    elseif ds<-iv*0.5 or d.sim<(s.frontier or d.sim)-iv*0.5 then quality,status,horizon=0,"rollback/catchup",1
    elseif ds<=0 then return true,"duplicate"
    elseif ds>0.5 then quality,status,horizon=0.25,"gap reset",1;s.events={};s.count=0
    else
      local dx,dy,dz=d.x-tonumber(p.x),d.y-tonumber(p.y),d.z-tonumber(p.z)
      local dvx,dvy,dvz=d.vx-tonumber(p.vx),d.vy-tonumber(p.vy),d.vz-tonumber(p.vz)
      local accel=math.sqrt(dvx*dvx+dvy*dvy+dvz*dvz)/ds
      local ex=dx-(d.vx+tonumber(p.vx))*0.5*ds
      local ey=dy-(d.vy+tonumber(p.vy))*0.5*ds
      local ez=dz-(d.vz+tonumber(p.vz))*0.5*ds
      local residual=math.sqrt(ex*ex+ey*ey+ez*ez)
      s.acceleration,s.residual=accel,residual
      horizon=limit(math.floor(math.sqrt(16/math.max(accel,1))/iv),1,15)
      quality=limit(1-residual/32,0,1)
      if dx*dx+dy*dy+dz*dz>4096 then quality,status,horizon=0,"position discontinuity",1
      elseif residual>16 then status,horizon="movement mismatch",1 end
      local gap=math.floor(ds/iv+0.5)
      s.gap_ticks=gap
      if gap>=14 and num(d.shot) and d.shot>tonumber(p.shot) and d.shot<=d.sim+iv then
        s.events[#s.events+1]=d.tick;if #s.events>4 then table.remove(s.events,1) end
        s.last_burst=d.tick;s.evidence="simulation gap + observed shot"
        quality=math.min(quality,0.5);horizon=math.min(horizon,2)
      end
    end
    s.assessment_cache=nil;s.assessment_count=0
    s.head=(s.head+1)%self.capacity
    if not s.ffi then s.buffer[s.head]={} end
    local out=s.buffer[s.head]
    for _,k in ipairs(fields) do out[k]=num(d[k]) or 0 end
    s.count=math.min(self.capacity,s.count+1)
    s.frontier=math.max(s.frontier or d.sim,d.sim)
    s.quality,s.status,s.horizon=quality,status,horizon
    self.accepted=self.accepted+1
    return true,status
  end
  function M:assessment(id,uid,tick,iv,lerp)
    if not num(tick) or not num(iv) or iv<=0 then return nil end
    local s=self.records[id]
    if not s or (uid and s.uid~=uid) or s.count==0 then return nil end
    local key=tostring(iv)..":"..tostring(lerp)
    if s.assessment_tick~=tick then s.assessment_cache={};s.assessment_tick=tick;s.assessment_count=0 end
    local cached=s.assessment_cache and s.assessment_cache[key]
    if cached then
      self.assessment_cache_hits=(self.assessment_cache_hits or 0)+1
      local copy={};for k,v in pairs(cached)do copy[k]=v end;return copy
    end
    self.assessment_calculations=(self.assessment_calculations or 0)+1
    local p=s.buffer[s.head]
    local age=tick-tonumber(p.tick)
    local budget=limit(math.ceil(limit(num(lerp) or 0.03125,0,0.1)/iv)+(s.gap_ticks or 1)+2,4,16)
    local stale=age<0 or age>budget
    local invalid=s.quality==0 or stale
    local expected,anticipated=false,false
    if #s.events>=4 then
      local intervals={};for i=2,#s.events do intervals[#intervals+1]=s.events[i]-s.events[i-1] end
      table.sort(intervals);local period=intervals[math.ceil(#intervals/2)]
      local spread=intervals[#intervals]-intervals[1]
      if period>=8 and period<=128 and spread<=2 then
        expected=s.events[#s.events]+period
        anticipated=tick>=expected-1 and tick<=expected+1
      end
    end
    local result={quality=stale and 0 or s.quality,invalid=invalid,status=stale and "expired observed record" or s.status,horizon=s.horizon,age=age,budget=budget,
      sim=tonumber(p.sim),yaw=tonumber(p.yaw),anim_limit=tonumber(p.anim_valid)==1 and tonumber(p.anim_limit) or nil,
      evidence=s.evidence,force_send=invalid or (s.last_burst and tick-s.last_burst<=2) or anticipated,
      anticipated=anticipated,next_window=expected,acceleration=s.acceleration,residual=s.residual}
    s.assessment_cache=s.assessment_cache or {};s.assessment_count=s.assessment_count or 0
    if s.assessment_count<8 then s.assessment_cache[key]=result;s.assessment_count=s.assessment_count+1 end
    local copy={};for k,v in pairs(result)do copy[k]=v end;return copy
  end
  function M:sample_entities()
    if cfg.runtime_paused or ANEMONE_SECOND_COPY then self:reset();return end
    if not globals or globals.is_in_game~=true then self:reset();return end
    if not (get_bool(cfg.resolver) or get_bool(cfg.predict_exploit_uncharge) or get_bool(cfg.forceshot) or get_bool(cfg.extrapolation)) then self.records={};return end
    local tick,iv=num(globals.tickcount),num(globals.tickinterval)
    if not tick or not iv or iv<=0 then return end
    local ok,players=pcall(entity.get_players,true)
    if not ok or type(players)~="table" then return end
    local present={}
    for _,ent in pairs(players) do
      local got,id,d=pcall(function ()
        if not ent:is_alive() or ent:is_dormant() then return nil end
        local id=ent:get_index();local info=ent:get_player_info();local sim=ent:get_simulation_time()
        local pos,vel=ent:get_origin(),ent.m_vecVelocity
        local yaw=Y_angle(ent)
        if not info or not sim or not pos or not vel then return nil end
        local anim,shot
        pcall(function () anim=ent:get_anim_state() end)
        pcall(function () local w=ent:get_player_weapon();shot=w and num(w.m_fLastShotTime) end)
        local span=anim and num(anim.aim_yaw_max)
        if span then span=math.abs(span);if span<1 or span>90 then span=nil end end
        local after=ent:get_simulation_time()
        if not after or sim.current~=after.current then return nil end
        return id,{uid=info.userid,sim=sim.current,tick=tick,x=pos.x,y=pos.y,z=pos.z,vx=vel.x,vy=vel.y,vz=vel.z,yaw=yaw,lby=Y_lby(ent),duck=Y_duck_amount(ent)or 0,flags=num(ent.m_fFlags),shot=shot,anim_limit=span,anim_valid=span and 1 or 0}
      end)
      if got and id and d then present[id]=true;self:ingest(id,d,iv) end
    end
    for id in pairs(self.records) do if not present[id] then self.records[id]=nil end end
  end
  function M:update_local(cmd)
    if cfg.runtime_paused or ANEMONE_SECOND_COPY then self.local_record=nil;return end
    if not (get_bool(cfg.resolver) or get_bool(cfg.predict_exploit_uncharge) or get_bool(cfg.forceshot) or get_bool(cfg.unsafe_recharge) or get_bool(cfg.extrapolation)) then self.local_record=nil;return end
    local ok,uid,tb,weapon=pcall(function ()
      if not globals or globals.is_in_game~=true then return nil end
      local me=entity.get_local_player();if not me or not me:is_alive() then return nil end
      local info=me:get_player_info();local w=me:get_player_weapon()
      return info and info.userid,num(me.m_nTickBase),w and w:get_index()
    end)
    local seq=cmd and num(cmd.command_number)
    if not ok or not uid or not tb or not seq then self.local_record=nil;return end
    local s=self.local_record
    if not s or s.uid~=uid or s.weapon~=weapon or seq<s.sequence then
      self:init();local buf
      if self.ffi then local got,value=pcall(self.ffi.new,"anemone_observation_1856_v1[1]");if got then buf=value end end
      if not buf then self.local_record=nil;return end
      s={uid=uid,weapon=weapon,sequence=seq,frontier=tb,tb=tb,delta=0,status="warmup",buffer=buf,tick=globals.tickcount};self.local_record=s
    elseif seq~=s.sequence then
      s.delta=tb-s.tb;s.tb=tb;s.frontier=math.max(s.frontier,tb);s.sequence=seq;s.tick=globals.tickcount
      s.status=tb<s.frontier-1 and "local rollback" or (s.delta>=14 and "local burst" or "normal")
    end
    s.buffer[0].sim=tb;s.buffer[0].tick=s.tick;s.buffer[0].uid=uid
  end
  function M:local_timing()
    local s=self.local_record
    if not s or not globals or globals.tickcount-s.tick>2 or globals.tickcount<s.tick then return nil end
    if not s.timing_cache or s.timing_sequence~=s.sequence then
      s.timing_cache={uid=s.uid,tb=tonumber(s.buffer[0].sim),tick=tonumber(s.buffer[0].tick),delta=s.delta,status=s.status,frontier=s.frontier}
      s.timing_sequence=s.sequence
    else self.local_timing_cache_hits=(self.local_timing_cache_hits or 0)+1 end
    local copy={};for k,v in pairs(s.timing_cache)do copy[k]=v end;return copy
  end
  function M:geometry(me,ent,min_damage)
    local ok,result=pcall(function ()
      local id=ent:get_index();local info=ent:get_player_info();local p=self.records[id]
      if not p or not info or p.uid~=info.userid then return nil,"identity/snapshot unavailable" end
      local a=self:assessment(id,info.userid,globals.tickcount,globals.tickinterval)
      if not a or a.invalid then return nil,"observed record invalid" end
      local eye=me:get_eye_position();local w=me:get_player_weapon();local wid=w and w:get_index()
      local hp=num(ent.m_iHealth);if not eye or not wid or not hp then return nil,"weapon/HP unavailable" end
      local tick=globals.tickcount
      if self.geometry_cache_tick~=tick then self.geometry_cache={};self.geometry_cache_tick=tick end
      self.geometry_cache=self.geometry_cache or {}
      local c=self.geometry_cache[id]
      if not c or c.uid~=info.userid or c.sim~=a.sim or c.weapon~=wid or c.ex~=eye.x or c.ey~=eye.y or c.ez~=eye.z then
        local damages={};local body={};local best=0
        for _,hb in ipairs({0,2,3,5}) do
          local point=ent:get_hitbox_position(hb)
          if point then
            self.geometry_traces=(self.geometry_traces or 0)+1
            local damage,tr=utils.trace_bullet(me,eye,point)
            if num(damage) and damage>0 and tr and tr.entity and tr.entity:get_index()==id then
              damages[#damages+1]=damage;best=math.max(best,damage)
              if tr.hitgroup==2 or tr.hitgroup==3 then body[#body+1]=damage end
            end
          end
        end
        c={uid=info.userid,sim=a.sim,weapon=wid,ex=eye.x,ey=eye.y,ez=eye.z,damages=damages,body=body,best=best};self.geometry_cache[id]=c
      else
        self.geometry_cache_hits=(self.geometry_cache_hits or 0)+1
      end
      local floor=min_damage>100 and hp+min_damage-100 or min_damage
      local count=0;for _,d in ipairs(c.damages) do if d>=floor then count=count+1 end end
      local lethal=0;for _,d in ipairs(c.body) do if d>=math.max(hp,floor) then lethal=lethal+1 end end
      return {eligible=count>0,lethal_body=lethal>=2,best=c.best,quality=a.quality,reason=count>0 and "verified target-center damage" or "no center meets current damage"}
    end)
    return ok and result or nil
  end
  function M:consume(name) self.consumers[name]=(self.consumers[name] or 0)+1 end
  function M:report()
    local count=0;for _ in pairs(self.records) do count=count+1 end
    local names={};for _,name in ipairs({"resolver","predict","forceshot","unsafe","extrapolation"}) do names[#names+1]=name.."="..tostring(self.consumers[name] or 0) end
    return self.storage.." targets="..count.." accepted="..self.accepted.." rejected="..self.rejected.." | "..table.concat(names," ").." | observer code writes=disabled; optional code patches reported separately"
  end
  return M
end)()
Y.native_fix_state="REIMPLEMENTED: observed geometry + record-age checks; optional native code patches separately controlled"
function R:install()
  local handlers = {
    {
      "net_update_start",
      function ()if Y.steam_exclusion then local ok=pcall(Y.steam_exclusion.before_network,Y.steam_exclusion);if not ok then Y.steam_exclusion.state="FAULT: pre-network restore callback"end end end
    },
    {
      "net_update_end",
      function ()
        if Y.steam_exclusion then local ok=pcall(Y.steam_exclusion.sync,Y.steam_exclusion);if not ok then Y.steam_exclusion.state="FAULT: network apply callback"end end
        if Y.native_records then
          local native_ok,native_err=pcall(Y.native_records.request_collection,Y.native_records)
          if not native_ok then Y.native_records:collector_error(native_err) end
        end
        local observed_ok,observed_err=pcall(Y.observation_bridge.sample_entities,Y.observation_bridge)
        if not observed_ok then Y.observation_bridge:reset();warn_once("observed_ffi_sample",tostring(observed_err)) end
        Y:guard(Y.observe_timing)
        AH:on_net_update()
        self:guard(self.net_update)
        ;
        Y:guard(Y.update)
        if Y.ffi_service then
          local ready,why=pcall(Y.ffi_service.network_ready,Y.ffi_service)
          if not ready then warn_once("ffi_network_ready",tostring(why):gsub("%c"," "))end
        end
      end
    },
    {
      "createmove",
      function (cmd)
        if Y.steam_exclusion then local ok=pcall(Y.steam_exclusion.before_command,Y.steam_exclusion);if not ok then Y.steam_exclusion.state="FAULT: command prelude callback"end end
        local local_ok,local_err=pcall(Y.observation_bridge.update_local,Y.observation_bridge,cmd)
        if not local_ok then Y.observation_bridge.local_record=nil;warn_once("observed_ffi_local",tostring(local_err)) end
        AH:on_createmove(cmd)
        D:guard(D.sync)
        ;
        movement_tick(cmd)
        ;
        self:guard(self.step, cmd)
        ;
        MD:guard(MD.tick)
        ;
        UR:guard(UR.step, cmd)
        ;
        FS:guard(FS.tick, cmd)
        FS:guard(FS.air_tick, cmd)
        local tok, terr = pcall(function () AH:predict_uncharge(cmd) end)
        if not tok then warn_once("timing_policy", tostring(terr)) end
      end
    },
    {
      "aim_fire",
      function (event)
        if Y.steam_exclusion then pcall(Y.steam_exclusion.shot,Y.steam_exclusion,event)end
        if Y.native_trace then local ok,err=pcall(Y.native_trace.fire,Y.native_trace,event);if not ok then Y.native_trace.last_error=tostring(err):sub(1,180) end end
        D:guard(D.fire, event)
        ;
        self:guard(self.fire, event)
        ;
        UR:guard(UR.on_shot, event)
        ;
        Y:guard(Y.on_shot, event)
        if FS.air_until then FS.air_until=nil; FS.air_used=true; FS.air_votes=0 end
      end
    },
    {
      "aim_ack",
      function (event)
        if Y.native_trace then pcall(Y.native_trace.ack,Y.native_trace,event) end
        self:guard(self.ack, event)
        ;
        Y:guard(Y.on_ack, event)
      end
    },
    {
      "round_start",
      function ()
        AH:reset()
        self:guard(self.reset, "round start")
        ;
        UR:reset()
        ;
        MD:release("round / map reset")
        ;
        Y:guard(Y.reset_angel_all)
      end
    },
    {
      "level_init",
      function ()
        AH:reset()
        self:guard(self.reset, "map / connection changed")
        ;
        UR:reset()
        ;
        MD:release("round / map reset")
        ;
        Y:guard(Y.reset_angel_all)
      end
    },
    {
      "player_death",
      function (event)
        if Y.ffi_feedback then Y.ffi_feedback:death(tonumber(event.userid))end
        if Y.native_trace then pcall(Y.native_trace.bridge_departure,Y.native_trace,event) end
        if Y.native_records then Y.native_records:note_departure(event,"death") end
        self:guard(self.player_left, event)
        ;
        Y:guard(Y.reset_angel_event, event, true)
      end
    },
    {
      "player_spawn",
      function (event)
        if Y.ffi_feedback then Y.ffi_feedback:cancel_uid(tonumber(event.userid))end
        Y:guard(Y.reset_angel_event, event, false)
      end
    },
    {
      "player_disconnect",
      function (event)
        if Y.native_trace then pcall(Y.native_trace.bridge_departure,Y.native_trace,event) end
        if Y.ffi_feedback then Y.ffi_feedback:cancel_uid(tonumber(event.userid))end
        if Y.native_records then Y.native_records:note_departure(event,"disconnect") end
        self:guard(self.player_left, event)
      end
    },
  }
  self.hooks = { }
  for _, h in ipairs(handlers) do
    self.hooks[h[1]] = chain(h[1], h[2])
  end
  self.ready = self.hooks.createmove and self.hooks.net_update_end and self.hooks.aim_fire and self.hooks.aim_ack
  UR.ready = UR.api_ready and self.hooks.createmove and self.hooks.aim_fire
  D.shot_hook = self.hooks.aim_fire
  if not UR.ready then
    cfg.unsafe_recharge:set(false)
    ;
    cfg.unsafe_recharge:disabled(true)
    tooltip(cfg.unsafe_recharge, "Unavailable: Double Tap API / required move or shot hook is missing.")
  end
  cfg.resolver:set_callback(function ()
    local enabled = get_bool(cfg.resolver)
    pcall(function ()
      cfg.assist:set(false)
      cfg.yaw:set(enabled)
    end)
    if enabled then
      Y.fault = nil
      Y:guard(Y.update)
    else
      Y:reset("resolver master disabled")
      N:request("safe", nil)
    end
    self:guard(self.reset, "resolver master changed")
    pcall(settings_visibility_tick)
  end)
  cfg.extrapolation:set_callback(function ()
    self:guard(self.reset, "feature settings changed")
  end)
  local function build_report()
    local lines={}
    local function say(text)
      lines[#lines+1]=tostring(text):gsub("%c"," ")
    end
    say("REPORT | BEGIN FFI Own Matrix Buffers v49 / Exact Phase Retry + Motion Cache + Both Own Banks; fresh snapshot plus retained script-lifetime history")
    D.scan_at = - 1
    ;
    D:guard(D.scan)
    ;
    D:guard(D.sync)
    local s = N.slots.safe
    local function values(ref)
      local ok, base, override = N:read(ref)
      return ok and ("base=" .. tostring(base) .. " override=" .. tostring(override) .. " effective=" .. tostring(N:effective(ref))) or "unavailable"
    end
    local _, context_reason = self:context()
    for _,line in ipairs(Y.core:report_lines())do say("REPORT | "..line,true)end
    say("REPORT | Unsafe Charge policy=natural charge permission only; force_charge disabled; forced tick-burst microfreeze path removed, runtime FPS still requires measurement",true)
    say("REPORT | ForceShot execution=network preparation; command path consumes exact complete cached batch only",true)
    say("REPORT | Anemone " .. cfg.version_state.lua_version .. " updated=" .. cfg.version_state.beta_updated .. " / observable records | in_game=" .. tostring(D.in_game) .. " alive=" .. tostring(D.alive) .. " native master=" .. tostring(N:master_enabled()) .. " | context=" .. tostring(context_reason or "live") .. " | processed net=" .. self.net_count .. " cmd=" .. self.command_count, true)
    say("REPORT | AirStop enabled="..tostring(get_bool(cfg.air_stop)).." ForceShot="..tostring(get_bool(cfg.forceshot)).." Hold="..tostring(get_bool(cfg.air_stop_hold)).." horizontal_speed="..tostring(FS.air_horizontal_speed).." strafe_slot="..tostring(N.slots.air_strafe and N.slots.air_strafe.ref~=nil).." strafe_state="..tostring(FS.air_strafe_state),true)
    say("REPORT | Timing=" .. tostring(AH.timing_status or "waiting") .. " reads=" .. tostring(Y.timing_reads or 0) .. " | AirStop=" .. tostring(FS.air_state or "OFF") .. " sampled_hc=" .. tostring(FS.air_estimate or "unavailable"), true)
    say("REPORT | Resolver master="..tostring(get_bool(cfg.resolver)).." Report button=Report / Diagnostics",true)
    say("REPORT | Anemone Assist=" .. tostring(get_bool(cfg.assist)) .. " | Yaw=" .. tostring(get_bool(cfg.yaw)) .. " | Yaw Status=" .. tostring(Y.last_status), true)
    say("REPORT | " .. tostring(self:status(true)), true)
    say("REPORT | Yaw writes=" .. Y.writes .. " blocked=" .. Y.blocked .. " mode=" .. tostring(Y.mode) .. " brute idx=" .. Y.brute, true)
    say("REPORT | Safe Points " .. values(s.ref) .. " | " .. s.state .. " | set=" .. s.applied .. " clear=" .. s.released .. " conflicts=" .. s.conflicts, true)
    say("REPORT | Safety plan=" .. tostring(self.plan) .. " | Defensive alerts=" .. self.defensive_signals .. " correction signals=" .. self.correction_signals, true)
    say("REPORT | Extrapolation simulations=" .. self.simulated .. " skips=" .. self.simulation_skips .. " | " .. self.prediction_state, true)
    local srv_tick, srv_source = self:server_tick()
    local srv_info = self:dead_time()
    say("REPORT | ServerTick=" .. (srv_tick and tostring(srv_tick) or "?") .. " source=" .. tostring(srv_source) .. " time=" .. (srv_tick and self:to_time(srv_tick) and string.format("%.4f", self:to_time(srv_tick)) or "?") .. " | bands soft=" .. LIMITS.lag_soft .. "s hard=" .. LIMITS.lag_hard .. "s | dead=" .. (srv_info and (srv_info.time and string.format("%.4f", srv_info.time) or "?") or "?") .. " lat=" .. (srv_info and srv_info.latency and string.format("%.4f", srv_info.latency) or "?") .. " unlag=" .. (srv_info and srv_info.max_unlag and string.format("%.3f", srv_info.max_unlag) or "?"), true)
    local fl_ok, fl_val = false, nil
    if N.fake_latency_ref then
      fl_ok, fl_val = N:read(N.fake_latency_ref)
    end
    local ping_ms = 0
    local ok_lat, lat = pcall(function ()
      return net.avg_latency and net.avg_latency[0]
    end)
    if ok_lat and number(lat) then
      ping_ms = lat * 1000
    end
    say("REPORT | Extrap cfg: on=" .. tostring(get_bool(cfg.extrapolation)) .. " auto=" .. tostring(get_bool(cfg.extrapolation_auto)) .. " include_fl=" .. tostring(get_bool(cfg.extrapolation_fake_latency)) .. " origin_rewrite=disabled" .. " | slider=" .. tostring(cfg.extrapolation_ticks and cfg.extrapolation_ticks:get() or "?") .. " | ping_ms=" .. string.format("%.0f", ping_ms) .. " | native FL ref=" .. tostring(N.fake_latency_ref ~= nil) .. " value=" .. (fl_ok and tostring(fl_val) or "unavailable") .. " | fl_ticks=" .. N:fake_latency_ticks(), true)
    say("REPORT | ForceShot switch="..tostring(get_bool(cfg.forceshot)).." | "..tostring(FS.state).." | HC_request_windows="..tostring(FS.count).."; request/readback is NOT forced-shot proof",true)
    if FS.spread_sampler then for _,line in ipairs(FS.spread_sampler:report_lines())do say("REPORT | "..line,true)end end
    local charge = UR:charge()
    say("REPORT | Recharge switch=" .. tostring(get_bool(cfg.unsafe_recharge)) .. " ready=" .. tostring(UR.ready) .. " DT=" .. tostring(N:effective(UR.dt)) .. " charge=" .. (charge and string.format("%.1f%%", charge * 100) or "unknown") .. " | " .. UR.state, true)
    say("REPORT | Auto body="..tostring(self.auto_body_state).." body_slot="..tostring(N.slots.body and N.slots.body.ref~=nil).." lerp="..tostring(self.lerp_seconds).." | local_tickbase="..tostring(Y.local_tickbase_status),true)
    if Y.steam_exclusion then for _,line in ipairs(Y.steam_exclusion:report_lines())do say("REPORT | "..line,true)end end
    if Y.steam_marker then say("REPORT | SteamID visual "..Y.steam_marker:report(),true)end
    if Y.fps_optimizer then for _,line in ipairs(Y.fps_optimizer:report_lines())do say("REPORT | "..line,true)end end
    if Y.ffi_service then for _,line in ipairs(Y.ffi_service:report_lines())do say("REPORT | "..line,true)end end
    if Y.ffi_feedback then for _,line in ipairs(Y.ffi_feedback:report_lines())do say("REPORT | "..line,true)end end
    say("REPORT | FFI + Assist coexist="..tostring(yaw_mode()=="FFI"and get_bool(cfg.yaw)and get_bool(cfg.assist)).."; final yaw support rescored from CURRENT candidate pool, unsupported/stale candidates still rejected",true)
    if Y.runtime_perf then for _,line in ipairs(Y.runtime_perf:report_lines())do say("REPORT | "..line,true)end end
    say("REPORT | FPS maintenance UI=10Hz dormant_status=4Hz; FFI candidate/preparation/publication cadence unchanged",true)
    if Y.steam_identity then for _,line in ipairs(Y.steam_identity:report_lines())do say("REPORT | "..line,true)end end
    say("REPORT | Shared observations="..Y.observation_bridge:report(),true)
    local native_probe_ok,native_probe_err=pcall(function ()
      if (true) then
        local target=entity.get_threat()
        if target then Y.native_records:snapshot(target,"diagnostics",true) end
      end
    end)
    if Y.native_policy then for _,line in ipairs(Y.native_policy:report_lines())do say("REPORT | "..line) end end
    if Y.native_patches then
      for _,line in ipairs(Y.native_patches:report_lines()) do say("REPORT | "..line) end
    end
    say("REPORT | Native records="..tostring((true)).." writes_enabled="..tostring(get_bool(cfg.native_record_write)).." | "..Y.native_records:report(),true)
    if not native_probe_ok then say("REPORT | Native probe error="..tostring(native_probe_err),true) end
    for _,line in ipairs(Y.native_records:diagnostic_lines()) do say("REPORT | "..line,true) end
    if Y.native_trace then for _,line in ipairs(Y.native_trace:report_lines()) do say("REPORT | "..line) end end
    say("REPORT | Shot evidence v2: current entity readback only; historical native records unexposed",true)
    for reason,count in pairs(self.correlation_reasons or {}) do say("REPORT | ACK correlation "..reason.."="..count,true) end
    say("REPORT | Predict auto="..tostring(AH.predict_state or "warming up").." flushes="..tostring(AH.auto_flushes or 0).." suppressed="..tostring(AH.auto_suppressed or 0).." | local flush only; no enemy DT-state access",true)
    say("REPORT | Record assist: geometry="..tostring(self.auto_body_state).." age_budget="..tostring(self.record_age_budget).." extrap_horizon="..tostring(self.observed_extrap_horizon).." next_observed_gap="..tostring(AH.observed_next_window),true)
    say("REPORT | Yaw changed="..tostring(Y.writes).." unchanged="..tostring(Y.unchanged or 0).." blocked="..tostring(Y.blocked).." | readback is not proof of resolved server hitboxes",true)
    say("REPORT | Recharge observed_spend="..tostring(UR.observed_spend or 0).." natural_permission_requests="..tostring(UR.permission_requests or 0).." force_requests="..tostring(UR.force_requests or 0).." force_failures="..tostring(UR.force_failures or 0).." merged_shots="..tostring(UR.merged_shots or 0),true)
    say("REPORT | FFI shared assessments computed="..tostring(Y.observation_bridge.assessment_calculations or 0).." cache_hits="..tostring(Y.observation_bridge.assessment_cache_hits or 0).." local_timing_hits="..tostring(Y.observation_bridge.local_timing_cache_hits or 0).."; independent result copies; new sample/tick/reset invalidates caches",true)
    say("REPORT | FFI shared geometry cache_hits="..tostring(Y.observation_bridge.geometry_cache_hits or 0).." traces="..tostring(Y.observation_bridge.geometry_traces or 0).."; exact eye/UID/simulation/weapon, one cache per target per tick",true)
    say("REPORT | Recharge shot_events=" .. UR.shot_events .. " attempts=" .. UR.attempts .. " requests=" .. UR.requests .. " observed_full=" .. UR.observed_full .. " timeouts=" .. UR.timeouts .. " expired=" .. UR.expired .. " | " .. UR.last_result, true)
    for _,line in ipairs(Y.native_records:history_lines()) do say("REPORT | "..line) end
    say("REPORT | END lines="..tostring(#lines+1).."; history retained across death/round/reset; experimental record selector reported separately from code patches")
    return lines
  end
  local function run_report(export)
    local ok,lines=pcall(build_report)
    if not ok then
      console_line("[Anemone] Report failed: "..tostring(lines):gsub("%c"," "))
      pcall(common.add_notify,"Anemone","Report generation failed; see console")
      return
    end
    local full={}
    for i,line in ipairs(lines) do full[i]="[Anemone] "..line end
    local text=table.concat(full,"\r\n").."\r\n"
    self.last_report_text=text
    if not export then
      for _,line in ipairs(lines) do self:say(line,true) end
      return
    end
    local copied,copy_error=pcall(function ()
      local clipboard=require("neverlose/clipboard")
      assert(clipboard and type(clipboard.set)=="function","clipboard module unavailable")
      assert(clipboard.set(text)~=false,"clipboard.set returned false")
    end)
    if copied then
      console_line("[Anemone] Export Report: copied "..#lines.." lines ("..#text.." bytes) to clipboard.")
      pcall(common.add_notify,"Anemone","Full report copied to clipboard")
    else
      console_line("[Anemone] Export Report failed: "..tostring(copy_error):gsub("%c"," "))
      pcall(common.add_notify,"Anemone","Clipboard export failed; report printed to console")
      for _,line in ipairs(lines) do self:say(line,true) end
    end
  end
  cfg.report:set_callback(function () run_report(false) end)
  cfg.export_report:set_callback(function () run_report(true) end)
  self:status(true)
end
do
local function create(env)
  local M={state="OFF",reads=0,writes=0,restores=0,blocked=0,consumers={},targets={},receipts={},failed={},rejects=0,epoch=1}
  local P={base=0x412A0000,size=0x3501000,stride=0x10940,header=0xD0,max_capacity=128}
  local function finite(x) return type(x)=="number" and x==x and math.abs(x)<math.huge and x or nil end
  local function integral(x) return finite(x) and x==math.floor(x) and x or nil end
  local function has(x,mask) return math.floor(x/mask)%2==1 end
  local function norm(x) return (x+180)%360-180 end
  local function u32(s,o)
    if not s or #s<o+4 then return nil end
    local a,b,c,d=s:byte(o+1,o+4);return a+b*256+c*65536+d*16777216
  end
  local function float(s,o)
    local x=u32(s,o);if not x then return nil end
    local sign=x>=2147483648 and -1 or 1
    local e=math.floor(x/8388608)%256;local m=x%8388608
    if e==255 then return nil end
    if e==0 then return sign*m*2^-149 end
    return sign*(1+m/8388608)*2^(e-127)
  end
  local function valid_address(a,n)
    return integral(a) and integral(n) and a>=65536 and n>=1 and n<=1024 and a+n<=4294967296
  end
  local function address_in_image(a) return a>=P.base and a<P.base+P.size end
  function M:initialize()
    if self.io then return true end
    if self.initialization_failed then return false end
    if env.io then self.io=env.io;return true end
    local ok,io=pcall(function()
      local f=require("ffi")
      assert(f.os=="Windows" and f.sizeof("void*")==4,"Windows x86 LuaJIT required")
      if not pcall(f.typeof,"anr_mbi_2250_v1") then
        f.cdef([[typedef struct { void* BaseAddress; void* AllocationBase; uint32_t AllocationProtect; size_t RegionSize; uint32_t State; uint32_t Protect; uint32_t Type; } anr_mbi_2250_v1;
          void* __stdcall GetCurrentProcess(void);
          size_t __stdcall VirtualQuery(const void*,void*,size_t);
          int __stdcall ReadProcessMemory(void*,const void*,void*,size_t,size_t*);
          int __stdcall WriteProcessMemory(void*,void*,const void*,size_t,size_t*);]])
      end
      assert(f.sizeof("anr_mbi_2250_v1")==28,"unexpected Win32 memory-query layout")
      local lib=f.load("kernel32")
      local process=lib.GetCurrentProcess()
      local query,read=lib.VirtualQuery,lib.ReadProcessMemory
      local backend={ffi=f,lib=lib,process=process}
      function backend:query(a)
        self._query_out=self._query_out or f.new("anr_mbi_2250_v1[1]");local out=self._query_out
        if tonumber(query(f.cast("const void*",a),out,28))~=28 then return nil end
        local v=out[0]
        return {base=tonumber(f.cast("uintptr_t",v.BaseAddress)),allocation=tonumber(f.cast("uintptr_t",v.AllocationBase)),size=tonumber(v.RegionSize),state=tonumber(v.State),protect=tonumber(v.Protect),kind=tonumber(v.Type)}
      end
      function backend:read(a,n)
        if not self._read_capacity or n>self._read_capacity then
          local capacity=256;while capacity<n do capacity=capacity*2 end
          self._read_capacity=capacity;self._read_out=f.new("uint8_t[?]",capacity)
        end
        self._read_got=self._read_got or f.new("size_t[1]")
        local out,got=self._read_out,self._read_got
        if read(process,f.cast("const void*",a),out,n,got)==0 or tonumber(got[0])~=n then return nil end
        return f.string(out,n)
      end
      function backend:write(a,data)
        local got=f.new("size_t[1]")
        return lib.WriteProcessMemory(process,f.cast("void*",a),data,#data,got)~=0 and tonumber(got[0])==#data
      end
      return backend
    end)
    if not ok then self.initialization_failed=true;self.state="BLOCKED: "..tostring(io):gsub("%c"," "):sub(1,120);return false end
    self.io=io;self.state="Windows x86 IO initialized; profile pending";return true
  end
  function M:range(a,n,writable)
    if not valid_address(a,n) or not self:initialize() then return false end
    local at=a;local finish=a+n;local steps=0
    while at<finish do
      local ok,q=pcall(self.io.query,self.io,at);steps=steps+1
      if not ok then self.state="BLOCKED: memory query failed";return false end
      if not q or steps>3 or q.state~=0x1000 or not integral(q.base) or not integral(q.size) or q.size<=0 or q.base>at or q.base+q.size<=at then return false end
      local prot=q.protect or 0;local low=prot%256
      if has(prot,0x100) or not (low==2 or low==4 or low==8 or low==0x20 or low==0x40 or low==0x80) then return false end
      if writable and (q.kind~=0x20000 or not (low==4 or low==8 or low==0x40 or low==0x80)) then return false end
      at=math.min(finish,q.base+q.size)
    end
    return true
  end
  function M:read(a,n)
    if not self:range(a,n,false) then return nil end
    local ok,data=pcall(self.io.read,self.io,a,n)
    if not ok then self.state="BLOCKED: OS memory read failed";return nil end
    if type(data)~="string" or #data~=n then return nil end
    self.reads=self.reads+1;return data
  end
  function M:profile()
    if not self:initialize() then return false end
    local queried,q=pcall(self.io.query,self.io,P.base)
    if not queried then self.state="BLOCKED: native image query failed";return false end
    if not q or q.allocation~=P.base or q.kind~=0x20000 or q.state~=0x1000 then self.state="BLOCKED: native image allocation mismatch";return false end
    local signatures={
      {0xAEAC6,"\137\134\176\000\000\000\161"},
      {0x1FE85C,"\131\122\040\002\015\142\194\002\000\000"},
      {0x1FE8DC,"\131\122\040\003\015\140\066\002\000\000"},
      {0xB38DB,"\243\015\088\021\024\165\005\066"}}
    for _,v in ipairs(signatures) do
      local actual=self:read(P.base+v[1],#v[2])
      local accepted=false
      if actual~=v[2] and env.accept_profile_signature then
        local ok,value=pcall(env.accept_profile_signature,v[1],v[2],actual);accepted=ok and value==true
      end
      if actual~=v[2] and not accepted then self.state="BLOCKED: build mismatch or unowned native code patch";return false end
    end
    local code=self:read(P.base+0xAEAC6+7,4);local slot=u32(code,0)
    if not slot or slot%4~=0 or not address_in_image(slot) then self.state="BLOCKED: record table operand invalid";return false end
    self.table_slot=slot;self.state="profile matched; native record layout requires live validation";return true
  end
  function M:select_origin(render_x,render_y,render_z,net_x,net_y,net_z)
    if finite(net_x) and finite(net_y) and finite(net_z) and math.abs(net_x)<=1e7 and math.abs(net_y)<=1e7 and math.abs(net_z)<=1e7 then
      return net_x,net_y,net_z,"m_vecOrigin"
    end
    return render_x,render_y,render_z,"get_origin_fallback"
  end
  function M:context(ent)
    local ok,c,reason=pcall(env.context,ent)
    if not ok then self.state="BLOCKED: SDK context error: "..tostring(c):gsub("%c"," "):sub(1,160);return nil end
    if type(c)~="table" then self.state="WAIT: "..tostring(reason or "no eligible enemy context");return nil end
    for _,k in ipairs({"id","uid","sim","x","y","z","duck","tick"}) do
      if not finite(c[k]) then self.state="BLOCKED: SDK context field "..k.." missing/nonfinite";return nil end
    end
    if not integral(c.id) or c.id<1 or c.id>64 or not integral(c.uid) or c.uid<1 or c.sim<0 or not integral(c.tick) then
      self.state="BLOCKED: invalid SDK identity/simulation/tick";return nil
    end
    if env.performance_reader and env.performance_reader()==true then
      if not integral(c.sdk_flags)or c.sdk_flags<0 then self.state="BLOCKED: FFI SDK flags missing";return nil end
      for _,k in ipairs({"sdk_vx","sdk_vy","sdk_vz"})do if not finite(c[k])or math.abs(c[k])>4096 then self.state="BLOCKED: FFI SDK motion "..k.." invalid";return nil end end
    end
    return c
  end
  function M:ring(c)
    local root=u32(self:read(self.table_slot,4),0)
    if not valid_address(root,4) then self.state="BLOCKED: ring root unreadable/invalid";return nil end
    local address=root+c.id*P.stride
    local bytes=self:read(address,20)
    if not bytes then self.state="BLOCKED: ring header unreadable";return nil end
    local r={root=root,address=address,records=u32(bytes,4),capacity=u32(bytes,8),head=u32(bytes,12),count=u32(bytes,16),header_bytes=bytes}
    if not valid_address(r.records,4) or r.records%4~=0 or r.capacity<2 or r.capacity>P.max_capacity or r.head>=r.capacity or r.count>r.capacity then
      self.state=string.format("BLOCKED: ring fields invalid data=%08X head=%u count=%u capacity=%u",r.records,r.head,r.count,r.capacity);return nil
    end
    if r.count==0 then self.state="WAIT: native ring empty";return nil end
    local power=1;while power<r.capacity do power=power*2 end
    if power~=r.capacity then self.state="BLOCKED: ring capacity is not a power of two";return nil end
    local slots=self:read(r.records,r.capacity*4)
    if not slots then self.state="BLOCKED: ring pointer array unreadable";return nil end
    r.slots=slots;return r
  end
  function M:decode(data,ptr,check_matrix)
    local r={pointer=ptr,sim=float(data,0x94),x=float(data,0),y=float(data,4),z=float(data,8),vx=float(data,12),vy=float(data,16),vz=float(data,20),entity_index=u32(data,0x3C),raw_40=u32(data,0x40),raw_5c=float(data,0x5C),pitch=float(data,0x64),eye_yaw=float(data,0x68),eye_roll=float(data,0x6C),raw_70=float(data,0x70),entity_flags=u32(data,0x80),capture_tick=u32(data,0x84),raw_88=u32(data,0x88),duck=float(data,0x98),raw_a4=u32(data,0xA4),raw_flags=u32(data,0xB0),center=ptr+0xC0,header_bytes=data,observation_only=true,native_validity="unknown"}
    for _,k in ipairs({"sim","x","y","z","vx","vy","vz","pitch","eye_yaw","eye_roll","duck"}) do
      if not finite(r[k]) then return nil,"field="..k.." nonfinite float32" end
    end
    for _,key in ipairs({"pitch","eye_yaw","eye_roll"}) do
      local raw=r[key]
      if math.abs(raw)>720 then return nil,string.format("field=%s raw_angle=%.9g outside [-720,720]",key,raw) end
      r[key.."_raw"]=raw;r[key]=norm(raw)
    end
    for _,check in ipairs({{"sim",0,math.huge},{"x",-1e7,1e7},{"y",-1e7,1e7},{"z",-1e7,1e7},{"vx",-4096,4096},{"vy",-4096,4096},{"vz",-4096,4096},{"entity_index",1,64},{"pitch",-180,180},{"eye_yaw",-720,720},{"eye_roll",-720,720},{"duck",0,1}}) do
      local key=check[1];local value=r[key]
      if value<check[2] or value>check[3] then
        return nil,string.format("field=%s value=%.9g expected=[%.9g,%.9g]",key,value,check[2],check[3])
      end
    end
    -- +A4 includes independently accessed bytes (+A5, +A7) in native code.
    -- +B0 is an internal bitfield, not an established invalid-record mask.
    r.matrix_valid=nil;r.observation_valid=false;r.matrix_reason="not checked for historical header"
    if check_matrix==false then return r end
    local matrix=self:read(r.center,48)
    r.matrix_valid=matrix~=nil and r.center%4==0
    r.matrix_reason=r.matrix_valid and "first inline matrix passed numeric/row-length checks" or "matrix unreadable/unaligned"
    if r.matrix_valid then
      for i=0,11 do
        local value=float(matrix,i*4)
        if not finite(value) or math.abs(value)>1e7 then r.matrix_valid=false;r.matrix_reason="matrix nonfinite/out-of-range element="..i;break end
      end
    end
    if r.matrix_valid then
      for row=0,2 do
        local a,b,c=float(matrix,row*16),float(matrix,row*16+4),float(matrix,row*16+8)
        local length=a*a+b*b+c*c
        if length<0.25 or length>4 then r.matrix_valid=false;r.matrix_reason=string.format("matrix row=%d squared_length=%.9g",row,length);break end
      end
    end
    r.matrix_bytes=matrix
    r.observation_valid=r.matrix_valid
    return r
  end
  local function same_sdk_sample(a,b)
    return a and b and a.id==b.id and a.uid==b.uid and a.sim==b.sim and a.x==b.x and a.y==b.y and a.z==b.z and a.duck==b.duck and a.origin_source==b.origin_source and a.sdk_flags==b.sdk_flags and a.sdk_vx==b.sdk_vx and a.sdk_vy==b.sdk_vy and a.sdk_vz==b.sdk_vz
  end
  local function copy_sdk_sample(c)
    return {id=c.id,uid=c.uid,sim=c.sim,x=c.x,y=c.y,z=c.z,duck=c.duck,origin_source=c.origin_source,sdk_flags=c.sdk_flags,sdk_vx=c.sdk_vx,sdk_vy=c.sdk_vy,sdk_vz=c.sdk_vz}
  end
  function M:snapshot(ent,consumer,force)
    if not env.enabled() and not (self.restoring and env.live and env.live()) then self.state="OFF";self.diagnostic=nil;return nil end
    local c=self:context(ent);if not c then self.diagnostic=nil;return nil end
    local failure=self.failed[c.id]
    if failure and same_sdk_sample(failure.sample,c) and c.tick>=failure.tick and c.tick-failure.tick<4 and not self.restoring and not force then
      self.state=failure.reason;return nil
    end
    local st=self.targets[c.id]
    if st and st.record and st.tick==c.tick and same_sdk_sample(st.sample,c) and not force then
      if st.record then self.consumers[consumer or "shared"]=(self.consumers[consumer or "shared"] or 0)+1 end
      return st.record
    end
    if not self:profile() then self.diagnostic=nil;return nil end
    local ring=self:ring(c);if not ring then self.diagnostic=nil;return nil end
    local chosen,seen=nil,{}
    local fast_prefilter=consumer~="diagnostics" and env.performance_reader and env.performance_reader()==true
    local diagnostic={scanned=0,schema=0,sim=0,origin=0,duck=0,identity=0,capacity=ring.capacity,count=ring.count,head=ring.head,invalid_pointer=0,unreadable=0,samples={},reasons={},id=c.id,uid=c.uid,tick=c.tick,sdk=c,root=ring.root,address=ring.address,records=ring.records,ring_header=ring.header_bytes,ring_slots=ring.slots}
    local nearest=nil
    -- Native insertion decrements head. Active entries are head .. head+count-1.
    for offset=0,ring.count-1 do
      local index=(ring.head+offset)%ring.capacity
      local ptr=u32(ring.slots,index*4)
      if not valid_address(ptr,P.header) or ptr%4~=0 then
        diagnostic.invalid_pointer=diagnostic.invalid_pointer+1
      elseif not seen[ptr] then
        seen[ptr]=true
        local bytes=self:read(ptr,P.header)
        diagnostic.scanned=diagnostic.scanned+1
        if not bytes then diagnostic.unreadable=diagnostic.unreadable+1 end
        if bytes then
          if #diagnostic.samples<3 then diagnostic.samples[#diagnostic.samples+1]={index=index,pointer=ptr,bytes=bytes} end
          local rawsim=float(bytes,0x94)
          local rx,ry,rz,rd=float(bytes,0),float(bytes,4),float(bytes,8),float(bytes,0x98)
          if rawsim and rx and ry and rz and rd then
            local delta=math.abs(rawsim-c.sim)
            if not nearest or delta<nearest.delta then
              nearest={delta=delta,signed_delta=rawsim-c.sim,sim=rawsim,distance=math.sqrt((rx-c.x)^2+(ry-c.y)^2+(rz-c.z)^2),duck_delta=math.abs(rd-c.duck),index=index,pointer=ptr,header_bytes=bytes}
              if finite(c.net_x) and finite(c.net_y) and finite(c.net_z) then nearest.network_distance=math.sqrt((rx-c.net_x)^2+(ry-c.net_y)^2+(rz-c.net_z)^2) end
            end
          end
        end
        local rec,decode_reason
        local sim=bytes and float(bytes,0x94)
        local prefiltered=fast_prefilter and sim and math.abs(sim-c.sim)>0.0001
        if prefiltered then
          diagnostic.prefiltered=(diagnostic.prefiltered or 0)+1;diagnostic.sim=diagnostic.sim+1
          self.sim_prefiltered=(self.sim_prefiltered or 0)+1
        elseif bytes then rec,decode_reason=self:decode(bytes,ptr,false) else decode_reason="header read failed" end
        if prefiltered then
          -- Not a candidate for this SDK simulation; no matrix/header schema work needed.
        elseif not rec then
          diagnostic.schema=diagnostic.schema+1
          if #diagnostic.reasons<6 then diagnostic.reasons[#diagnostic.reasons+1]="slot="..index.." "..tostring(decode_reason) end
        else
          local delta=math.abs(rec.sim-c.sim)
          if rec.entity_index~=c.id then diagnostic.identity=diagnostic.identity+1 end
          if delta>0.0001 then diagnostic.sim=diagnostic.sim+1 end
          if (rec.x-c.x)^2+(rec.y-c.y)^2+(rec.z-c.z)^2>4 then diagnostic.origin=diagnostic.origin+1 end
          if math.abs(rec.duck-c.duck)>0.03 then diagnostic.duck=diagnostic.duck+1 end
          if rec.entity_index==c.id and delta<=0.0001 and (rec.x-c.x)^2+(rec.y-c.y)^2+(rec.z-c.z)^2<=4 and math.abs(rec.duck-c.duck)<=0.03 then
            if chosen and chosen.pointer~=ptr then self.diagnostic=diagnostic;self.state="BLOCKED: ambiguous current native record";return nil end
            chosen=self:decode(bytes,ptr,true);chosen.index=index
          end
        end
      end
    end
    diagnostic.nearest=nearest
    self.diagnostic=diagnostic
    -- A scan is a set of separate OS reads, not an atomic native snapshot.
    if self:read(ring.address,20)~=ring.header_bytes or self:read(ring.records,ring.capacity*4)~=ring.slots then
      self.state="RETRY: native ring changed during scan";return nil
    end
    local latest=self:context(ent)
    if not latest then return nil end
    if latest.tick~=c.tick or not same_sdk_sample(latest,c) then
      self.state="RETRY: SDK context changed during scan";return nil
    end
    if not chosen then
      if diagnostic.scanned==0 then self.state="BLOCKED: no eligible pointers in active native ring"
      elseif diagnostic.schema==diagnostic.scanned then self.state="BLOCKED: all active headers rejected by pinned schema"
      else self.state="BLOCKED: active native records do not match SDK simulation/origin/duck" end
      self.rejects=self.rejects+1;self.failed[c.id]={uid=c.uid,tick=c.tick,reason=self.state,sample=copy_sdk_sample(c)}
      return nil
    end
    if self:read(chosen.pointer,P.header)~=chosen.header_bytes then
      self.state="RETRY: selected native header changed during scan";return nil
    end
    diagnostic.selected=chosen
    self.failed[c.id]=nil
    local same=st and st.uid==c.uid and c.tick>=st.tick and c.sim>=st.sim and st.root==ring.root and st.address==ring.address
    local validations=same and st.validations or 0
    local direction,steady=0,0
    chosen.steady_side=0
    if not st or st.tick~=c.tick then validations=validations+1 end
    chosen.id,chosen.uid,chosen.tick,chosen.epoch=c.id,c.uid,c.tick,self.epoch
    chosen.root,chosen.ring_address,chosen.records=ring.root,ring.address,ring.records
    chosen.capacity,chosen.head,chosen.count=ring.capacity,ring.head,ring.count
    chosen.validations=validations
    self.targets[c.id]={uid=c.uid,tick=c.tick,sim=c.sim,sample=copy_sdk_sample(c),root=ring.root,address=ring.address,validations=validations,direction=direction,steady=steady,record=chosen,ent=ent}
    self.consumers[consumer or "shared"]=(self.consumers[consumer or "shared"] or 0)+1
    self.state=chosen.observation_valid and "native identity matched; first matrix numerically valid; native shot validity unknown" or "native identity matched; matrix observation rejected (see Native selected)"
    return chosen
  end
  function M:guard(ent,consumer)
    self.guard_requests=self.guard_requests or {}
    self.guard_requests[consumer]=(self.guard_requests[consumer] or 0)+1
    if env.read_only then return true,"read-only collector; native gameplay gates disabled",nil end
    local r=self:snapshot(ent,consumer)
    return true,r and "native observation only; shot validity unknown" or self.state,nil
  end
  function M:transaction()
    return nil,"READ-ONLY observer: native field ownership and shot consumption unverified"
  end
  function M:selector_profile()
    local anchors={
      {0x1589C0,"\083\087\086\131\236\020\137\206\139\124\036\036\139\092\036\040\161\000\039\038\066\049\224\137\068\036\016\198\068\036\012\000\242\015\016\068\036\008\242\015\017\004\036\232\208\176\255\255\131\236\008\232\152\035\121\000\139\142\176\000\000\000\137\202\131\226\064\193\234\006\131\251\001\015\148\196\032\212\132\192\116\012\132\228\116\020\129\198\192\096\000\000\235\036\132\228\116\021\129\198\192\216\000\000\235\024\246\193\032\117\041\129\198\192\000\000\000\235\011\246\193\032\117\048\129\198\192\120\000\000\139\076\036\016\049\225\232\015\242\154\000\137\240\131\196\020\094\095\091\194\008\000\131\255\003\119\210\255\036\189\136\072\007\066\129\198\192\048\000\000\235\214\131\255\003\119\203\255\036\189\120\072\007\066\129\198\192\168\000\000\235\194\132\201\120\020\129\198\192\024\000\000\235\182\132\201\120\016\129\198\192\144\000\000\235\170\129\198\192\072\000\000\235\162"},
      {0xDD4878,"\060\138\063\065\120\138\063\065\144\138\063\065\140\138\063\065\047\138\063\065\100\138\063\065\132\138\063\065\128\138\063\065"},
      {0x1573B2,"\243\015\016\134\164\000\000\000\243\015\017\066\116\243\015\016\134\168\000\000\000\243\015\017\066\120"},
      {0xDEE87,"\139\129\176\000\000\000\131\224\004\106\000\255\180\008\140\000\000\000\232\034\155\007\000"},
    }
    for _,v in ipairs(anchors) do
      local actual=self:read(P.base+v[1],#v[2])
      if actual~=v[2] then
        local ok,accepted=false,false
        if env.accept_selector_signature then ok,accepted=pcall(env.accept_selector_signature,v[1],v[2],actual) end
        if not ok or accepted~=true then return false end
      end
    end
    return true
  end
  local function word(n)
    return string.char(n%256,math.floor(n/256)%256,math.floor(n/65536)%256,math.floor(n/16777216)%256)
  end
  function M:selector_stats()
    if not self.selector then self.selector={requests=0,commits=0,unchanged=0,restores=0,conflicts=0,expired=0,abandoned=0,blocks={},last="not requested",fault=nil} end
    return self.selector
  end
  function M:selector_block(reason)
    local t=self:selector_stats();t.blocks[reason]=(t.blocks[reason] or 0)+1;t.last=reason;t.last_result=reason
    return nil,reason
  end
  function M:selector_geometry(r,yaw)
    local g={valid=false}
    if not r or not r.header_bytes or not finite(yaw) then return g end
    local eye,a,b=float(r.header_bytes,0x68),float(r.header_bytes,0x74),float(r.header_bytes,0x78)
    if not finite(eye) or not finite(a) or not finite(b) or math.abs(eye)>720 or math.abs(a)>720 or math.abs(b)>720 then return g end
    g.valid=true;g.requested=norm(yaw);g.eye_proxy=norm(eye);g.variant1_yaw=norm(a);g.variant2_yaw=norm(b)
    g.error1=math.abs(norm(g.requested-g.variant1_yaw));g.error2=math.abs(norm(g.requested-g.variant2_yaw))
    g.gap=math.abs(g.error1-g.error2);g.eye_error=math.abs(norm(g.requested-g.eye_proxy))
    g.nearest_variant=g.error1<g.error2 and 1 or 2;g.nearest_error=math.min(g.error1,g.error2)
    g.eye_proxy_closer=g.eye_error<g.nearest_error;g.flags=r.raw_flags
    return g
  end
  function M:selector_threshold(state,detail)
    if env.confidence_threshold then
      local ok,value=pcall(env.confidence_threshold,state,detail)
      if ok and finite(value) and value>=0.50 and value<=0.90 then return value end
    end
    return 0.60
  end
  function M:selector_choice(r,yaw,confidence,threshold)
    threshold=threshold or self:selector_threshold()
    if not finite(yaw) or not finite(confidence) or confidence<threshold then return nil,string.format("confidence below %.2f or invalid request",threshold) end
    if not r or not r.observation_valid then return nil,"current record matrix observation unavailable" end
    if has(r.raw_flags,4) then return nil,"special selector +90 active; +8C withheld" end
    if not has(r.raw_flags,0x20) then return nil,"native alternative banks not initialized (B0&20 absent)" end
    local a,b=float(r.header_bytes,0x74),float(r.header_bytes,0x78)
    if not finite(a) or not finite(b) or math.abs(a)>720 or math.abs(b)>720 then return nil,"native alternative angles invalid" end
    a,b=norm(a),norm(b)
    local own_mode=env.require_own_matrices and env.require_own_matrices()==true
    local angle_separation=math.abs(norm(a-b))
    if not own_mode and angle_separation<0.5 then return nil,"native alternatives have indistinguishable angles" end
    local da,db=math.abs(norm(yaw-a)),math.abs(norm(yaw-b))
    local gap=math.abs(da-db)
    if not own_mode and gap<2 then return nil,"nearest alternative ambiguous (gap below 2 degrees)" end
    -- Own banks receive the requested rotation. A tie chooses variant 1, not an unrelated SDK fallback.
    local choice=(own_mode and da<=db or not own_mode and da<db) and {variant=1,offset=0x30C0,yaw=a,error=da} or {variant=2,offset=0x18C0,yaw=b,error=db}
    choice.own_tie=own_mode and (gap<2 or angle_separation<0.5);choice.gap=gap
    local budget=own_mode and 60 or 15
    if choice.error>budget then return nil,string.format("nearest native alternative outside %d-degree %s budget",budget,own_mode and "own-matrix" or "selector") end
    return choice
  end
  function M:selector_matrix(address)
    local data=self:read(address,48)
    if not data then return false end
    for i=0,11 do local v=float(data,i*4);if not finite(v) or math.abs(v)>1e7 then return false end end
    for row=0,2 do
      local a,b,c=float(data,row*16),float(data,row*16+4),float(data,row*16+8)
      local length=a*a+b*b+c*c;if length<0.25 or length>4 then return false end
    end
    return true,data
  end
  function M:selector_identity(ent)
    if env.identity then
      local ok,c=pcall(env.identity,ent)
      if ok and type(c)=="table" and integral(c.id) and integral(c.uid) then return c end
      return nil
    end
    return self:context(ent)
  end
  function M:selector_member(ent,v)
    if not env.live or not env.live() then return nil,"context not live" end
    local c=self:selector_identity(ent)
    if not c or c.id~=v.id or c.uid~=v.uid then return nil,"identity departed/reused" end
    if not self:profile() or not self:selector_profile() then return nil,"selector profile mismatch" end
    local ring=self:ring(c);if not ring then return nil,"native ring unavailable" end
    if ring.root~=v.root or ring.address~=v.ring_address then return nil,"ring allocation replaced" end
    local found=false
    for offset=0,ring.count-1 do
      if u32(ring.slots,((ring.head+offset)%ring.capacity)*4)==v.pointer then found=true;break end
    end
    if not found then return nil,"record expired from active ring" end
    local header=self:read(v.pointer,P.header)
    if not header or u32(header,0x3C)~=v.id or u32(header,0x84)~=v.capture_tick or header:sub(0x94+1,0x94+4)~=v.sim_bytes then return nil,"record identity changed" end
    local ok,q=pcall(self.io.query,self.io,v.pointer)
    if not ok or not q or q.allocation~=v.allocation then return nil,"record allocation changed" end
    if self:read(ring.address,20)~=ring.header_bytes or self:read(ring.records,ring.capacity*4)~=ring.slots then return nil,"ring changed before selector operation" end
    return header,ring
  end
  function M:selector_write(ent,v,expected,replacement,preflight_header)
    local header,ring=self:selector_member(ent,v)
    if not header then return false,ring end
    if preflight_header and header~=preflight_header then return false,"header changed since selector preflight" end
    if header:sub(0x8C+1,0x8C+4)~=expected then return false,"selector ownership conflict" end
    if not self:range(v.pointer+0x8C,4,true) or type(self.io.write)~="function" then return false,"selector field not writable" end
    if self:read(v.pointer,P.header)~=header then return false,"header changed before selector write" end
    local ok,written=pcall(self.io.write,self.io,v.pointer+0x8C,replacement)
    if not ok or written~=true then return false,"selector OS write failed; write extent unverified",true end
    local after,reason=self:selector_member(ent,v)
    if not after or after:sub(0x8C+1,0x8C+4)~=replacement then return false,"selector readback failed: "..tostring(reason),true end
    self.targets[v.id]=nil
    return true
  end
  function M:selector_release(id)
    local v=self.receipts[id];if not v then return true end
    local t=self:selector_stats()
    if not env.live or not env.live() then
      t.abandoned=t.abandoned+1;if env.selector_release then pcall(env.selector_release,v,"nonlive") end;self.receipts[id]=nil;return true
    end
    local header,reason=self:selector_member(v.ent,v)
    if not header then
      if reason=="record expired from active ring" or reason=="identity departed/reused" or reason=="record identity changed" or reason=="ring allocation replaced" or reason=="record allocation changed" then
        t.expired=t.expired+1;if env.selector_release then pcall(env.selector_release,v,reason) end;self.receipts[id]=nil;return true
      end
      t.last="restore pending: "..tostring(reason);return false
    end
    if header:sub(0x8C+1,0x8C+4)~=v.applied then
      t.conflicts=t.conflicts+1;t.last="external selector change; not restored";if env.selector_release then pcall(env.selector_release,v,"external change") end;self.receipts[id]=nil;return true
    end
    local ok,why,uncertain=self:selector_write(v.ent,v,v.applied,v.original)
    if not ok then if uncertain then t.fault=why end;t.last="restore pending: "..tostring(why);return false end
    t.restores=t.restores+1;self.restores=self.restores+1;if env.selector_release then pcall(env.selector_release,v,"restored") end;self.receipts[id]=nil;return true
  end
  function M:resolve_now(ent,yaw,confidence,state,detail)
    local t=self:selector_stats();t.attempts=(t.attempts or 0)+1
    local r,audit_number,audit_variant
    local admitted=false
    local function audit_finish(stage,reason)
      if env.selector_attempt_finish then
        local ok=pcall(env.selector_attempt_finish,audit_number,stage,reason,audit_variant)
        if not ok then t.audit_errors=(t.audit_errors or 0)+1 end
      end
    end
    local function audit_block(reason)
      audit_finish(r and (admitted and "accepted_transfer_blocked" or "rejected") or "unmapped_preflight",reason)
      return self:selector_block(reason)
    end
    local early_own=self.selector_phase=="network_ready" and env.require_own_matrices and env.require_own_matrices()==true and env.selector_deferred and env.selector_deferred()==true
    if self.selector_phase~="render_after_network" and not early_own then return audit_block("writer execution outside deferred render/own-only network phase")end
    if not env.writes_enabled or not env.writes_enabled() then return audit_block("native selector writes disabled") end
    if t.fault then return audit_block("writer latched after unverified write; reload required") end
    local threshold=self:selector_threshold(state,detail)
    if t.confidence_threshold~=threshold then
      t.confidence_threshold=threshold;t.confidence_count=0;t.confidence_sum=0;t.confidence_min=nil;t.confidence_max=nil;t.confidence_pass=0
    end
    t.confidence_sources=t.confidence_sources or {}
    local source=detail and detail.source or "unspecified"
    t.confidence_sources[source]=(t.confidence_sources[source] or 0)+1
    t.last_confidence={value=confidence,source=source,beta=detail and detail.beta,rich=detail and detail.rich,blended=detail and detail.blended,yaw=yaw,candidate_yaw=detail and detail.candidate_yaw}
    if finite(confidence) then
      t.confidence_count=(t.confidence_count or 0)+1;t.confidence_sum=(t.confidence_sum or 0)+confidence
      t.confidence_min=t.confidence_min and math.min(t.confidence_min,confidence) or confidence
      t.confidence_max=t.confidence_max and math.max(t.confidence_max,confidence) or confidence
      if confidence>=threshold then t.confidence_pass=(t.confidence_pass or 0)+1 end
    end
    local c=self:context(ent);if not c then return audit_block("eligible target unavailable") end
    local previous=self.receipts[c.id]
    if previous and (previous.uid~=c.uid or previous.sim~=c.sim) and not self:selector_release(c.id) then return audit_block("previous selector restoration pending") end
    t.last_attempt={id=c.id,uid=c.uid,tick=c.tick,sim=c.sim,x=c.x,y=c.y,z=c.z,phase=self.selector_phase}
    if env.performance_reader and env.performance_reader()==true and env.selector_preflight_idle and not self.receipts[c.id] and (not finite(yaw) or not finite(confidence) or confidence<threshold) then
      local checked,idle=pcall(env.selector_preflight_idle,c)
      if checked and idle==true then
        local reason=string.format("confidence below %.2f or invalid request",threshold)
        t.confidence_prefiltered=(t.confidence_prefiltered or 0)+1
        if env.selector_attempt_unmapped then
          local ok=pcall(env.selector_attempt_unmapped,"confidence preflight; native snapshot not read: "..reason)
          if not ok then t.audit_errors=(t.audit_errors or 0)+1 end
        end
        return audit_block(reason)
      end
    end
    r=self:snapshot(ent,"resolver",true)
    if not r then
      t.last_snapshot_failure=self.state
      local n=self.diagnostic and self.diagnostic.nearest
      t.last_nearest=n and {sim=n.sim,delta=n.signed_delta,distance=n.distance} or nil
      return audit_block("fresh native record unavailable")
    end
    if env.selector_attempt_begin then
      local ok,number=pcall(env.selector_attempt_begin,r,yaw,confidence,state,detail,threshold,self:selector_geometry(r,yaw))
      if ok then audit_number=number else t.audit_errors=(t.audit_errors or 0)+1 end
    end
    if not self:selector_profile() then return audit_block("native selector code profile mismatch") end
    local choice,why=self:selector_choice(r,yaw,confidence,threshold)
    if not choice then
      if env.selector_abstained then pcall(env.selector_abstained,r,why) end
      self:selector_release(c.id)
      return audit_block(why)
    end
    admitted=true;audit_variant=choice.variant
    local primary_ok,primary=self:selector_matrix(r.pointer+choice.offset)
    -- The selector can use its alternate matrix group; verify its first matrix as well.
    local alternate_ok,alternate=self:selector_matrix(r.pointer+choice.offset+0x7800)
    if not primary_ok or not alternate_ok then self:selector_release(c.id);return audit_block("selected primary/alternate bank matrix rejected") end
    local original=r.header_bytes:sub(0x8C+1,0x8C+4);local current=u32(original,0)
    if not current or current>3 then return audit_block("existing selector enum outside 0..3") end
    local owned=self.receipts[c.id]
    if owned and owned.pointer~=r.pointer then
      if not self:selector_release(c.id) then return audit_block("previous selector restoration pending") end
      owned=nil
    end
    if owned and original~=owned.applied then
      t.conflicts=t.conflicts+1;if env.selector_release then pcall(env.selector_release,owned,"native/external change") end;self.receipts[c.id]=nil
      return audit_block("native/external selector changed; request skipped")
    end
    local queried,q=pcall(self.io.query,self.io,r.pointer)
    if not queried or not q then return audit_block("record allocation query failed") end
    local v={id=r.id,uid=r.uid,sim=r.sim,pointer=r.pointer,capture_tick=r.capture_tick,sim_bytes=r.header_bytes:sub(0x94+1,0x94+4),allocation=q.allocation,root=r.root,ring_address=r.ring_address,ent=ent,original=owned and owned.original or original,applied=word(choice.variant),source_selector=current,variant=choice.variant,yaw=choice.yaw,requested_yaw=norm(yaw),error=choice.error,state=state,tick=r.tick,sdk_sim=c.sim,sdk_x=c.x,sdk_y=c.y,sdk_z=c.z,sdk_duck=c.duck,sdk_flags=c.sdk_flags,sdk_vx=c.sdk_vx,sdk_vy=c.sdk_vy,sdk_vz=c.sdk_vz,own_tie=choice.own_tie,selector_attempt=audit_number,feedback_bucket=detail and detail.bucket,feedback_base=detail and detail.base,feedback_generation=detail and detail.observer_generation,feedback_revision=detail and detail.observer_revision,feedback_epoch=detail and detail.feedback_epoch}
    if env.require_own_matrices and env.require_own_matrices() then
      if owned then self:selector_release(c.id);return audit_block("previous owned selector released; retry own matrices from a fresh native snapshot") end
      if self:read(r.pointer+choice.offset,48)~=primary or self:read(r.pointer+choice.offset+0x7800,48)~=alternate or self:read(r.pointer,P.header)~=r.header_bytes then return audit_block("record/bank changed during own-matrix preflight") end
      local ok,published,why=pcall(env.selector_existing,v)
      if not ok or published~=true then return audit_block("own matrix approval refused without native field write: "..tostring(why or published)) end
      if env.selector_deferred and env.selector_deferred() then
        t.own_queued=(t.own_queued or 0)+1
        t.last="own matrix candidate queued; preparation/publication NOT yet confirmed; native field8C unchanged"
        audit_finish("own_matrix_preparation_queued",t.last)
      else
        t.own_approved=(t.own_approved or 0)+1
        if choice.own_tie then t.own_tie_approved=(t.own_tie_approved or 0)+1 end
        t.last="own matrices approved; native record field8C unchanged; native consumer delivery pending"
        audit_finish("own_matrix_approved_no_field_write",t.last)
      end
      return v,t.last
    end
    if current==choice.variant then
      if owned then
        owned.tick=r.tick;owned.requested_yaw=norm(yaw);owned.yaw=choice.yaw;owned.error=choice.error
        if env.selector_refresh then
          local ok,published,why=pcall(env.selector_refresh,owned)
          if env.require_own_matrices and env.require_own_matrices() and (not ok or published~=true) then
            self:selector_release(c.id);return audit_block("own matrix refresh refused; selector restoration attempted: "..tostring(why or published))
          end
        end
      elseif env.require_own_matrices and env.require_own_matrices() then
        local ok,published,why=pcall(env.selector_existing,v)
        if not ok or published~=true then return audit_block("own matrices for existing native selector refused: "..tostring(why or published)) end
      end
      t.unchanged=t.unchanged+1;t.last=string.format("selector already %d; consumption unverified",choice.variant)
      audit_finish(owned and "owned_selector_refreshed" or ((env.require_own_matrices and env.require_own_matrices()) and "existing_native_selector_own_matrix_approved" or "native_already_selected_unowned"),t.last)
      return owned or v,t.last
    end
    -- Recheck copied bank bytes and the selected header immediately before the write.
    if self:read(r.pointer+choice.offset,48)~=primary or self:read(r.pointer+choice.offset+0x7800,48)~=alternate or self:read(r.pointer,P.header)~=r.header_bytes then return audit_block("record/bank changed during preflight") end
    local ok,reason,uncertain=self:selector_write(ent,v,original,v.applied,r.header_bytes)
    if not ok then
      if uncertain then t.fault=reason;if env.selector_release then pcall(env.selector_release,owned or v,"unverified selector write") end;self.receipts[c.id]=v end
      return audit_block(reason)
    end
    self.receipts[c.id]=v;t.commits=t.commits+1;self.writes=self.writes+1
    if env.selector_commit then
      local committed,published,why=pcall(env.selector_commit,v)
      if env.require_own_matrices and env.require_own_matrices() and (not committed or published~=true) then
        self:selector_release(c.id)
        return audit_block("own matrix approval refused; selector restoration attempted: "..tostring(why or published))
      end
    end
    t.last=string.format("+8C readback enum=%d target_yaw=%.2f bank_yaw=%.2f error=%.2f; shot consumption unverified",choice.variant,v.requested_yaw,v.yaw,v.error)
    audit_finish("field_committed",t.last)
    return v,t.last
  end
  function M:resolve(ent,yaw,confidence,state,detail)
    local t=self:selector_stats();t.requests=t.requests+1
    if not env.writes_enabled or not env.writes_enabled() then return self:selector_block("native selector writes disabled") end
    if t.fault then return self:selector_block("writer latched after unverified write; reload required") end
    if not finite(yaw) or not finite(confidence) then return self:selector_block("invalid queued yaw/confidence") end
    local c=self:context(ent);if not c then return self:selector_block("eligible target unavailable") end
    self.selector_pending=self.selector_pending or {}
    if self.selector_pending[c.id] then t.coalesced=(t.coalesced or 0)+1 end
    self.selector_pending[c.id]={ent=ent,id=c.id,uid=c.uid,tick=c.tick,sim=c.sim,x=c.x,y=c.y,z=c.z,duck=c.duck,sdk_flags=c.sdk_flags,sdk_vx=c.sdk_vx,sdk_vy=c.sdk_vy,sdk_vz=c.sdk_vz,yaw=yaw,confidence=confidence,state=state,epoch=self.epoch,detail=detail and {bucket=detail.bucket,base=detail.base,observer_generation=detail.observer_generation,observer_revision=detail.observer_revision,feedback_epoch=detail.feedback_epoch,source=tostring(detail.source or "unspecified"),beta=detail.beta,rich=detail.rich,blended=detail.blended,candidate_yaw=detail.candidate_yaw,mode=detail.mode,native_mode=detail.native_mode,record_quality=detail.record_quality,jitter=detail.jitter,stability=detail.stability,duck=detail.duck} or nil}
    t.queued=(t.queued or 0)+1;t.last="queued for deferred render/own-only network phase; no native write in source callback"
    return nil,t.last
  end
  function M:drain_selector(only_id,phase)
    local pending=self.selector_pending or {}
    if only_id~=nil then
      if not pending[only_id]then return end
      local selected=pending[only_id];pending[only_id]=nil;pending={[only_id]=selected}
    else self.selector_pending={}end
    local t=self:selector_stats()
    local function unmapped_block(reason)
      if env.selector_attempt_unmapped then local ok=pcall(env.selector_attempt_unmapped,reason);if not ok then t.audit_errors=(t.audit_errors or 0)+1 end end
      self:selector_block(reason)
    end
    if not env.writes_enabled or not env.writes_enabled() then self:restore_live();return end
    self.selector_phase=phase=="network_ready"and "network_ready"or "render_after_network"
    local ids={};for id in pairs(pending) do ids[#ids+1]=id end
    local priority
    if #ids>1 and env.priority_target then local ok,value=pcall(env.priority_target);if ok then priority=value end end
    table.sort(ids,function(a,b)if a==priority then return b~=priority end;if b==priority then return false end;return a<b end)
    for _,id in ipairs(ids) do
      local q=pending[id]
      local ok,err=pcall(function()
        local c=self:context(q.ent)
        if not c or c.id~=q.id or c.uid~=q.uid or q.epoch~=self.epoch then unmapped_block("queued target identity changed");return end
        if c.tick<q.tick or c.tick-q.tick>2 then unmapped_block("queued request older than 2 ticks");return end
        if c.sim~=q.sim or c.x~=q.x or c.y~=q.y or c.z~=q.z or c.duck~=q.duck then unmapped_block("queued SDK sample changed; old yaw not reused");return end
        for _,k in ipairs({"sdk_flags","sdk_vx","sdk_vy","sdk_vz"})do if q[k]~=nil and c[k]~=q[k]then unmapped_block("queued SDK motion changed");return end end
        if q.phase_retry then
          if self.selector_phase=="network_ready"then self.selector_pending[id]=q;return end
          if q.retry_probe_tick==c.tick then self.selector_pending[id]=q;return end
          q.retry_probe_tick=c.tick;t.phase_retry_probes=(t.phase_retry_probes or 0)+1
          local ring=self:ring(c)
          if not ring then unmapped_block("phase retry native ring unavailable");return end
          if ring.root~=q.retry_root or ring.address~=q.retry_address then unmapped_block("phase retry native root changed");return end
          local changed=ring.header_bytes~=q.retry_header or ring.slots~=q.retry_slots
          if not changed then
            for _,sample in ipairs(q.retry_headers or {})do
              local bytes=self:read(sample.pointer,P.header)
              if not bytes then unmapped_block("phase retry header unreadable");return end
              if bytes~=sample.bytes then changed=true;break end
            end
          end
          if not changed then
            t.phase_retry_unchanged=(t.phase_retry_unchanged or 0)+1
            if c.tick-q.tick<2 then self.selector_pending[id]=q else t.phase_retry_expired=(t.phase_retry_expired or 0)+1 end
            return
          end
          t.phase_retry_attempts=(t.phase_retry_attempts or 0)+1
        end
        t.drains=(t.drains or 0)+1
        local receipt,reason=self:resolve_now(q.ent,q.yaw,q.confidence,q.state,q.detail)
        t.last_result=tostring(reason)
        if q.phase_retry then
          if receipt then t.phase_retry_admitted=(t.phase_retry_admitted or 0)+1 else t.phase_retry_failed=(t.phase_retry_failed or 0)+1 end
        elseif self.selector_phase=="network_ready"and env.require_own_matrices and env.require_own_matrices()==true and q.confidence>=self:selector_threshold(q.state,q.detail)and reason=="fresh native record unavailable"and self.state=="BLOCKED: active native records do not match SDK simulation/origin/duck"then
          local d=self.diagnostic
          if d and d.id==q.id and d.uid==q.uid and d.tick==c.tick and d.sdk and same_sdk_sample(d.sdk,c) and d.ring_header and d.ring_slots then
            q.phase_retry=true;q.retry_root=d.root;q.retry_address=d.address;q.retry_header=d.ring_header;q.retry_slots=d.ring_slots;q.retry_headers={}
            for i=1,math.min(3,#(d.samples or {}))do local sample=d.samples[i];q.retry_headers[i]={pointer=sample.pointer,bytes=sample.bytes}end
            self.selector_pending[id]=q;t.phase_retry_queued=(t.phase_retry_queued or 0)+1
          end
        end
      end)
      if not ok then t.errors=(t.errors or 0)+1;t.last_error=tostring(err):gsub("%c"," "):sub(1,180) end
    end
    self.selector_phase=nil
    self:selector_housekeeping()
  end
  function M:restore_live()
    self.selector_pending={}
    for id in pairs(self.receipts) do self:selector_release(id) end
  end
  function M:selector_housekeeping()
    if not env.writes_enabled or not env.writes_enabled() then self:restore_live();return end
    local tick=env.tick and tonumber(env.tick())
    for id,v in pairs(self.receipts) do
      if not tick or tick<v.tick or tick-v.tick>2 then self:selector_release(id) end
    end
  end
  function M:selector_lines()
    local t=self:selector_stats();local owned=0;for _ in pairs(self.receipts) do owned=owned+1 end
    local pending=0;for _ in pairs(self.selector_pending or {}) do pending=pending+1 end
    local lines={string.format("Native selector experimental enabled=%s requests=%d commits=%d unchanged=%d restores=%d conflicts=%d expired=%d abandoned=%d owned=%d",tostring(env.writes_enabled and env.writes_enabled() or false),t.requests,t.commits,t.unchanged,t.restores,t.conflicts,t.expired,t.abandoned,owned),
      "Native selector scope=Adaptive may own record +8C; FFI leaves +8C unchanged and publishes own matrix pointers; variants 1/+30C0/yaw+74, 2/+18C0/yaw+78; flags20 required; special +90 withheld",
      string.format("Native selector policy=confidence>=%.2f (automatic per-sample heuristic threshold); Adaptive error<=15deg and gap>=2deg; FFI own transform error<=60deg experimental, ties nearest bank (exact tie: variant1); actual studio bone count and active matrix checks",self:selector_threshold()),
      "Native selector proof=Adaptive scalar write/readback; FFI own buffers require construction/readback and native return substitution; see Own matrices verified_returns and Native delivery receipts",
      "Native selector last="..t.last,"Native selector last deferred result="..tostring(t.last_result or "not drained"),"Native selector fault="..tostring(t.fault)}
    lines[#lines+1]=string.format("Native selector phase=render_after_network/own_only_network_ready requests=%d queued=%d coalesced=%d pending=%d drains=%d attempts=%d errors=%d",t.requests,t.queued or 0,t.coalesced or 0,pending,t.drains or 0,t.attempts or 0,t.errors or 0)
    lines[#lines+1]="Native selector deferred policy=same UID, epoch, simulation, position, duck, flags and velocity as queued request; <=2 tick age; changed samples discarded, never relabeled as current"
    lines[#lines+1]=string.format("Native phase retry queued=%d probes=%d unchanged_ring=%d attempts=%d admitted=%d failed=%d expired=%d; ONE late scan only after ring header/slots or <=3 observed headers change; <=2 original SDK ticks, exact sample/motion retained; admission is NOT publication/consumption",t.phase_retry_queued or 0,t.phase_retry_probes or 0,t.phase_retry_unchanged or 0,t.phase_retry_attempts or 0,t.phase_retry_admitted or 0,t.phase_retry_failed or 0,t.phase_retry_expired or 0)
    lines[#lines+1]="FFI perf background_collector_skips="..tostring(self:history().performance_throttled or 0).."; production background <=1 target/8 ticks; active resolver drains unchanged"
    lines[#lines+1]="FFI perf confidence_preflight_skips="..tostring(t.confidence_prefiltered or 0).."; FFI only; no new native snapshot on low score AND no live target approval/owned selector; active approvals retain full abstention/revocation path"
    lines[#lines+1]="FFI perf reader_sim_prefiltered="..tostring(self.sim_prefiltered or 0).."; full candidate schema/duplicate detection/ring recheck retained; Diagnostics scans remain full"
    lines[#lines+1]="Native selector own_matrix_approvals_no_field_write="..tostring(t.own_approved or 0).." own_tie_approvals="..tostring(t.own_tie_approved or 0).." preparation_queued="..tostring(t.own_queued or 0)
    lines[#lines+1]="FFI perf collector_same_tick_writer_snapshot_reuses="..tostring(self:history().writer_snapshot_reuses or 0).."; identical UID/simulation/position/duck/reader epoch required"
    lines[#lines+1]="Native selector attempt_journal callback_errors="..tostring(t.audit_errors or 0)
    if t.last_attempt then local a=t.last_attempt;lines[#lines+1]=string.format("Native selector last attempt id=%d uid=%d tick=%d sim=%.9g origin=(%.9g,%.9g,%.9g) phase=%s",a.id,a.uid,a.tick,a.sim,a.x,a.y,a.z,a.phase) end
    if t.last_snapshot_failure then lines[#lines+1]="Native selector retained snapshot failure="..t.last_snapshot_failure end
    if t.last_nearest then local n=t.last_nearest;lines[#lines+1]=string.format("Native selector retained nearest sim=%.9g signed_delta=%s distance=%s",n.sim,tostring(n.delta),tostring(n.distance)) end
    if t.last_error then lines[#lines+1]="Native selector retained error="..t.last_error end
    if t.last_confidence then
      local c=t.last_confidence
      lines[#lines+1]=string.format("Native selector confidence last=%s source=%s beta=%s rich=%s blended=%s requested_yaw=%s candidate_yaw=%s threshold=%.2f",tostring(c.value),c.source,tostring(c.beta),tostring(c.rich),tostring(c.blended),tostring(c.yaw),tostring(c.candidate_yaw),t.confidence_threshold or self:selector_threshold())
    end
    if (t.confidence_count or 0)>0 then lines[#lines+1]=string.format("Native selector confidence sampled=%d min=%.6f mean=%.6f max=%.6f passed_threshold=%d",t.confidence_count,t.confidence_min,t.confidence_sum/t.confidence_count,t.confidence_max,t.confidence_pass or 0) end
    lines[#lines+1]="Native selector confidence policy=summary resets on threshold change; score of the selected yaw branch, not blended competitors; heuristic score is NOT hit probability; post-selection replacement receives no inherited confidence"
    local sources={};for name in pairs(t.confidence_sources or {}) do sources[#sources+1]=name end;table.sort(sources)
    for _,name in ipairs(sources) do lines[#lines+1]="Native selector confidence source="..name.." attempts="..t.confidence_sources[name] end
    local reasons={};for reason in pairs(t.blocks) do reasons[#reasons+1]=reason end;table.sort(reasons)
    for _,reason in ipairs(reasons) do lines[#lines+1]="Native selector blocked reason="..reason.." requests="..t.blocks[reason] end
    return lines
  end
  function M:reset()
    if env.selector_reset then pcall(env.selector_reset) end
    self:restore_live()
    local t=self:selector_stats();for _,v in pairs(self.receipts) do t.abandoned=t.abandoned+1;if env.selector_release then pcall(env.selector_release,v,"reset unresolved receipt") end end
    self.selector_pending={};self.selector_phase=nil
    self.targets={};self.receipts={};self.failed={};self.diagnostic=nil;self.table_slot=nil;self.epoch=self.epoch+1
    self.poll_cursor=0;self.last_poll_tick=nil;self.pending_collection=nil
    self.state="reset; live references cleared; collector history retained"
  end
  local movement_states={"stand","walk","slow_movement","duck_stand","duck_move","air","airduck","unknown"}
  function M:history()
    if not self.telemetry then
      self.telemetry={attempts=0,matched=0,numeric_ok=0,failed=0,errors=0,states={},reasons={},targets={},last_attempts={},recent={},recent_head=0,recent_count=0,capacity=48,started_tick=nil,network_signals=0,render_drains=0,coalesced_signals=0,reason_examples={},origin_sources={}}
    end
    return self.telemetry
  end
  function M:movement(c)
    if not integral(c.sdk_flags) or not finite(c.sdk_vx) or not finite(c.sdk_vy) then return "unknown",nil end
    local speed=math.sqrt(c.sdk_vx*c.sdk_vx+c.sdk_vy*c.sdk_vy)
    local crouched=c.duck>=0.5
    if not has(c.sdk_flags,1) then return crouched and "airduck" or "air",speed end
    if crouched then return speed<5 and "duck_stand" or "duck_move",speed end
    if speed<5 then return "stand",speed end
    if speed<80 then return "slow_movement",speed end
    return "walk",speed
  end
  function M:failure_kind(reason)
    if reason:find("RETRY:",1,true) then return "changing_snapshot" end
    if reason:find("schema",1,true) then return "schema" end
    if reason:find("do not match SDK",1,true) then return "sdk_mismatch" end
    if reason:find("ambiguous",1,true) then return "ambiguous" end
    if reason:find("ring",1,true) then return "ring_unavailable" end
    if reason:find("profile",1,true) or reason:find("image",1,true) or reason:find("build mismatch",1,true) then return "profile_unavailable" end
    return "context_or_io"
  end
  function M:collector_error(err)
    local h=self:history();h.errors=h.errors+1
    h.last_error=tostring(err):gsub("%c"," "):sub(1,200)
  end
  function M:capture_result(c,r,reason)
    local h=self:history();local state,speed=self:movement(c)
    local b=h.states[state]
    if not b then b={attempts=0,matched=0,numeric_ok=0,failed=0};h.states[state]=b end
    h.started_tick=h.started_tick or c.tick
    h.attempts=h.attempts+1;b.attempts=b.attempts+1
    local source=c.origin_source or "unspecified"
    h.origin_sources[source]=(h.origin_sources[source] or 0)+1
    local outcome=r and (r.observation_valid and "matched_numeric_ok" or "matrix_rejected") or self:failure_kind(reason)
    -- History owns scalars and byte strings only, never entity handles or native addresses.
    local sample={id=c.id,uid=c.uid,tick=c.tick,sim=c.sim,state=state,speed=speed,duck=c.duck,outcome=outcome,reason=tostring(reason):gsub("%c"," "):sub(1,180),epoch=self.epoch,x=c.x,y=c.y,z=c.z,render_x=c.render_x,render_y=c.render_y,render_z=c.render_z,origin_source=source,net_x=c.net_x,net_y=c.net_y,net_z=c.net_z,phase=self.collection_phase or "direct",signal_tick=self.collection_signal_tick}
    if r then
      h.matched=h.matched+1;b.matched=b.matched+1
      if r.observation_valid then h.numeric_ok=h.numeric_ok+1;b.numeric_ok=b.numeric_ok+1 end
      sample.header_bytes=r.header_bytes;sample.matrix_bytes=r.matrix_bytes
      sample.matrix_ok=r.matrix_valid;sample.capture_tick=r.capture_tick;sample.flags=r.raw_flags
      b.bank_observations=(b.bank_observations or 0)+1
      if has(r.raw_flags,0x20) then
        b.alternative_banks=(b.alternative_banks or 0)+1
        local a,z=float(r.header_bytes,0x74),float(r.header_bytes,0x78)
        if finite(a) and finite(z) and math.abs(a)<=720 and math.abs(z)<=720 and math.abs(norm(a-z))>=0.5 then b.distinct_bank_yaws=(b.distinct_bank_yaws or 0)+1 end
      end
      if has(r.raw_flags,4) then b.special_selectors=(b.special_selectors or 0)+1 end
      b.last_matched=sample
    end
    if not r or not r.observation_valid then
      h.failed=h.failed+1;b.failed=b.failed+1
      h.reasons[outcome]=(h.reasons[outcome] or 0)+1;b.last_failed=sample
      local d=self.diagnostic
      if d and d.id==c.id and d.uid==c.uid and d.tick==c.tick then
        sample.ring_head=d.head;sample.ring_count=d.count;sample.ring_capacity=d.capacity
        local nearest=d.nearest
        if nearest then
          sample.nearest_sim=nearest.sim;sample.sim_delta=nearest.signed_delta
          sample.nearest_distance=nearest.distance;sample.nearest_duck_delta=nearest.duck_delta;sample.network_distance=nearest.network_distance
          sample.probe_bytes=nearest.header_bytes
        end
        if not sample.probe_bytes and d.samples and d.samples[1] then sample.probe_bytes=d.samples[1].bytes end
        if d.reasons and #d.reasons>0 then sample.schema_reason=table.concat(d.reasons,"; ",1,math.min(2,#d.reasons)) end
        sample.scanned=d.scanned;sample.schema_reject=d.schema
      end
      h.reason_examples[outcome]=sample
    end
    b.last=sample
    h.targets[c.id]={id=c.id,uid=c.uid,last=sample,status="last observed alive"}
    h.recent_head=h.recent_head%h.capacity+1
    h.recent[h.recent_head]=sample;h.recent_count=math.min(h.capacity,h.recent_count+1)
  end
  function M:request_collection()
    if not env.enabled() then self.pending_collection=nil;return end
    local h=self:history();h.network_signals=h.network_signals+1
    if self.pending_collection then h.coalesced_signals=h.coalesced_signals+1 end
    self.pending_collection={epoch=self.epoch,tick=env.tick and env.tick() or nil}
  end
  function M:drain_collection()
    local pending=self.pending_collection
    if not pending then return end
    self.pending_collection=nil
    if pending.epoch~=self.epoch or not env.enabled() then return end
    local h=self:history()
    local production=env.performance_reader and env.performance_reader()==true
    local tick=env.tick and env.tick()
    if production and tick and self.last_background_tick and tick>=self.last_background_tick and tick-self.last_background_tick<8 then
      h.performance_throttled=(h.performance_throttled or 0)+1;return
    end
    if production then self.last_background_tick=tick end
    h.render_drains=h.render_drains+1
    self.collection_phase="render_after_network";self.collection_signal_tick=pending.tick
    local ok,err=pcall(self.sample_entities,self)
    self.collection_phase=nil;self.collection_signal_tick=nil
    if not ok then self:collector_error(err) end
  end
  function M:sample_entities()
    if not env.enabled() then return end
    local ok,players=pcall(env.players)
    if not ok or type(players)~="table" then self:collector_error(ok and "enemy list unavailable" or players);return end
    local candidates={}
    for _,ent in pairs(players) do
      local c=self:context(ent)
      if c then candidates[#candidates+1]={ent=ent,c=c} end
    end
    table.sort(candidates,function(a,b)return a.c.id<b.c.id end)
    local n=#candidates
    if n==0 then return end
    local tick=candidates[1].c.tick
    if self.last_poll_tick==tick then return end
    self.last_poll_tick=tick
    local h=self:history();local start=self.poll_cursor or 0;local sampled=0
    local budget=env.performance_reader and env.performance_reader()==true and 1 or 2
    -- At most two targets per network tick, at least four ticks between attempts per target.
    for step=1,n do
      local index=(start+step-1)%n+1
      local item=candidates[index];local c=item.c;self.poll_cursor=index
      local last=h.last_attempts[c.id]
      local eligible=not last or last.uid~=c.uid or last.epoch~=self.epoch or c.tick<last.tick
      if not eligible and c.tick-last.tick>=4 then
        eligible=c.sim~=last.sim or (not last.success and c.tick-last.tick>=8)
      end
      if eligible then
        self.diagnostic=nil
        local st=self.targets[c.id]
        local fresh=st and st.uid==c.uid and st.tick==c.tick and st.sim==c.sim and st.record and st.record.epoch==self.epoch and st.record.x==c.x and st.record.y==c.y and st.record.z==c.z and st.record.duck==c.duck
        local r=self:snapshot(item.ent,"collector",not fresh)
        if fresh and r then h.writer_snapshot_reuses=(h.writer_snapshot_reuses or 0)+1 end
        local reason=self.state
        self:capture_result(c,r,reason)
        h.last_attempts[c.id]={uid=c.uid,tick=c.tick,sim=c.sim,epoch=self.epoch,success=r~=nil and r.observation_valid==true}
        sampled=sampled+1
        if sampled>=budget then break end
      end
    end
  end
  function M:note_departure(event,reason)
    local uid=event and tonumber(event.userid)
    if not uid or not self.telemetry then return end
    for _,target in pairs(self.telemetry.targets) do
      if target.uid==uid then target.status=reason.."; last observation retained" end
    end
    for id,st in pairs(self.targets) do
      if st.uid==uid then self.targets[id]=nil;self.failed[id]=nil end
    end
  end
  function M:history_lines()
    local h=self:history()
    local lines={string.format("Native history attempts=%d matched=%d numeric_ok=%d failed=%d collector_errors=%d retained_recent=%d/%d started_tick=%s",h.attempts,h.matched,h.numeric_ok,h.failed,h.errors,h.recent_count,h.capacity,tostring(h.started_tick))}
    lines[#lines+1]="Native history scope=net_update_end queues scalar signal; next render reads enemies; FFI background <=1 target/8 ticks, other modes <=2/tick; >=4 ticks/target; unchanged successful simulations skipped"
    lines[#lines+1]=string.format("Native collector phase=render_after_network network_signals=%d render_drains=%d coalesced_signals=%d pending=%s",h.network_signals,h.render_drains,h.coalesced_signals,tostring(self.pending_collection~=nil))
    local sources={};for source in pairs(h.origin_sources) do sources[#sources+1]=source end;table.sort(sources)
    for _,source in ipairs(sources) do lines[#lines+1]="Native history position_source="..source.." attempts="..h.origin_sources[source] end
    lines[#lines+1]="Native history states use SDK ground flag, duck>=0.5, horizontal speed: stand<5, slow_movement<80, walk>=80; slow_movement is NOT verified slowwalk"
    lines[#lines+1]="Native history validity=identity match and first matrix numeric checks only; no resolved-hitbox/shot-consumption proof"
    for _,state in ipairs(movement_states) do
      local b=h.states[state] or {attempts=0,matched=0,numeric_ok=0,failed=0}
      lines[#lines+1]=string.format("Native coverage state=%s attempts=%d matched=%d numeric_ok=%d failed=%d",state,b.attempts,b.matched,b.numeric_ok,b.failed)
      local sample=b.last_matched or b.last_failed
      if sample then
        lines[#lines+1]=string.format("Native retained state=%s id=%d uid=%d tick=%d epoch=%d sim=%.9g speed=%s duck=%.4f result=%s",state,sample.id,sample.uid,sample.tick,sample.epoch,sample.sim,tostring(sample.speed),sample.duck,sample.outcome)
        if sample.header_bytes then
          for offset=0,#sample.header_bytes-1,32 do
            local bytes=sample.header_bytes:sub(offset+1,offset+32)
            local hex=bytes:gsub(".",function(ch)return string.format("%02X",ch:byte())end)
            lines[#lines+1]=string.format("Native retained header state=%s +%02X=%s",state,offset,hex)
          end
        end
      end
      if b.last_failed then lines[#lines+1]="Native retained failure state="..state.." reason="..b.last_failed.reason end
    end
    local reasons={};for name in pairs(h.reasons) do reasons[#reasons+1]=name end;table.sort(reasons)
    for _,name in ipairs(reasons) do
      lines[#lines+1]="Native history failure="..name.." attempts="..h.reasons[name]
      local sample=h.reason_examples[name]
      if sample then
        lines[#lines+1]=string.format("Native failure example kind=%s id=%d uid=%d tick=%d signal_tick=%s phase=%s state=%s sdk_sim=%.9g",name,sample.id,sample.uid,sample.tick,tostring(sample.signal_tick),sample.phase,sample.state,sample.sim)
        lines[#lines+1]=string.format("Native failure probe kind=%s nearest_sim=%s signed_sim_delta=%s distance=%s duck_delta=%s ring=%s/%s/%s scanned=%s schema_reject=%s",name,tostring(sample.nearest_sim),tostring(sample.sim_delta),tostring(sample.nearest_distance),tostring(sample.nearest_duck_delta),tostring(sample.ring_head),tostring(sample.ring_count),tostring(sample.ring_capacity),tostring(sample.scanned),tostring(sample.schema_reject))
        lines[#lines+1]=string.format("Native failure position kind=%s match_source=%s match_origin=(%.9g,%.9g,%.9g) get_origin=(%s,%s,%s) native_to_m_vecOrigin=%s",name,sample.origin_source,sample.x,sample.y,sample.z,tostring(sample.render_x),tostring(sample.render_y),tostring(sample.render_z),tostring(sample.network_distance))
        if sample.schema_reason then lines[#lines+1]="Native failure schema kind="..name.." "..sample.schema_reason end
        if sample.probe_bytes then
          for offset=0,#sample.probe_bytes-1,32 do
            local bytes=sample.probe_bytes:sub(offset+1,offset+32)
            local hex=bytes:gsub(".",function(ch)return string.format("%02X",ch:byte())end)
            lines[#lines+1]=string.format("Native failure header kind=%s +%02X=%s",name,offset,hex)
          end
        end
      end
    end
    local ids={};for id in pairs(h.targets) do ids[#ids+1]=id end;table.sort(ids)
    for _,id in ipairs(ids) do
      local target=h.targets[id];local sample=target.last
      lines[#lines+1]=string.format("Native target id=%d uid=%d last_tick=%d state=%s result=%s lifecycle=%s",id,target.uid,sample.tick,sample.state,sample.outcome,target.status)
    end
    for age=0,math.min(h.recent_count,12)-1 do
      local index=(h.recent_head-age-1)%h.capacity+1;local sample=h.recent[index]
      lines[#lines+1]=string.format("Native recent id=%d uid=%d tick=%d epoch=%d state=%s phase=%s result=%s",sample.id,sample.uid,sample.tick,sample.epoch,sample.state,sample.phase,sample.outcome)
    end
    if h.last_error then lines[#lines+1]="Native collector last_error="..h.last_error end
    return lines
  end
  function M:diagnostic_lines()
    local lines={"Native mode=FFI Own Matrix Buffers v49 / Exact Phase Retry + Motion Cache + Both Own Banks; optional +8C writes; native cache-miss snapshot diagnostics; gameplay gates disabled"}
    for _,line in ipairs(self:selector_lines()) do lines[#lines+1]=line end
    local h=self:history()
    for _,name in ipairs(movement_states) do
      local b=h.states[name]
      if b and (b.bank_observations or 0)>0 then lines[#lines+1]=string.format("Native bank coverage state=%s observed=%d alternatives_flag20=%d distinct_yaws=%d special_selector_flag4=%d",name,b.bank_observations,b.alternative_banks or 0,b.distinct_bank_yaws or 0,b.special_selectors or 0) end
    end
    local d=self.diagnostic
    if not d then return lines end
    local c=d.sdk
    lines[#lines+1]=string.format("Native SDK id=%d uid=%d tick=%d sim=%.9g origin=(%.9g,%.9g,%.9g) duck=%.9g",d.id,d.uid,d.tick,c.sim,c.x,c.y,c.z,c.duck)
    lines[#lines+1]=string.format("Native SDK position_source=%s get_origin=(%s,%s,%s) m_vecOrigin=(%s,%s,%s)",tostring(c.origin_source),tostring(c.render_x),tostring(c.render_y),tostring(c.render_z),tostring(c.net_x),tostring(c.net_y),tostring(c.net_z))
    lines[#lines+1]=string.format("Native ring root=%08X header=%08X slots=%08X active=%d/%d head=%d invalid_ptr=%d unreadable=%d",d.root,d.address,d.records,d.count,d.capacity,d.head,d.invalid_pointer,d.unreadable)
    if d.selected then
      local r=d.selected
      lines[#lines+1]=string.format("Native selected slot=%d ptr=%08X entity_index=%d sim=%.9g observation_valid=%s matrix_numeric_ok=%s",r.index,r.pointer,r.entity_index,r.sim,tostring(r.observation_valid),tostring(r.matrix_valid))
      lines[#lines+1]=string.format("Native selected capture_tick+84=%u entity_flags+80=%08X internal_flags+B0=%08X raw+A4=%08X",r.capture_tick,r.entity_flags,r.raw_flags,r.raw_a4)
      lines[#lines+1]=string.format("Native selected angles pitch_raw=%.9g pitch_signed=%.9g yaw_raw=%.9g yaw_signed=%.9g",r.pitch_raw,r.pitch,r.eye_yaw_raw,r.eye_yaw)
      lines[#lines+1]="Native selected matrix: "..r.matrix_reason
      lines[#lines+1]="Native selected native_shot_validity=unknown; +A4==0 and +B0&0x100 no longer reject observations"
      lines[#lines+1]="Native layout note: +3C is integer entity index; +80 is separate entity flag data; +84 is capture tick. Flags20 identifies initialized alternatives; +74/+78 native alternative yaw; +8C selector is experimental, shot-context selection remains separate"
    end
    for _,reason in ipairs(d.reasons) do lines[#lines+1]="Native reject: "..reason end
    if d.nearest then local n=d.nearest;lines[#lines+1]=string.format("Native nearest slot=%d ptr=%08X sim=%.9g delta=%.9g distance=%.9g duck_delta=%.9g",n.index,n.pointer,n.sim,n.delta,n.distance,n.duck_delta) end
    for _,sample in ipairs(d.samples) do
      local bytes=sample.bytes
      local candidates={}
      for offset=0,#bytes-4,4 do
        local value=float(bytes,offset)
        if value and c.sim>0 and math.abs(value-c.sim)<=0.0001 then candidates[#candidates+1]=string.format("+%02X",offset) end
      end
      lines[#lines+1]=string.format("Native sample slot=%d ptr=%08X time_candidates=%s (diagnostic only)",sample.index,sample.pointer,#candidates>0 and table.concat(candidates,",") or "none")
      -- Keep each line below R:say's 480-character limit.
      for offset=0,#bytes-4,16 do
        local cells={}
        for at=offset,math.min(offset+12,#bytes-4),4 do cells[#cells+1]=string.format("+%02X=%08X/f:%s",at,u32(bytes,at),tostring(float(bytes,at))) end
        lines[#lines+1]="Native raw slot="..sample.index.." "..table.concat(cells," ")
      end
    end
    return lines
  end
  function M:report()
    local counts={}
    for _,name in ipairs({"resolver","predict","forceshot","unsafe","extrapolation","diagnostics","collector"}) do counts[#counts+1]=name.."="..tostring(self.consumers[name] or 0) end
    local detail=""
    if self.diagnostic then
      local d=self.diagnostic
      detail=" | active scanned="..d.scanned.." schema_reject="..d.schema.." sim_mismatch="..d.sim.." origin_mismatch="..d.origin.." duck_mismatch="..d.duck.." identity_mismatch="..d.identity.." ring="..d.head.."/"..d.count.."/"..d.capacity
    end
    return self.state..detail.." | rejects="..self.rejects.." | reads="..self.reads.." writes="..self.writes.." | "..table.concat(counts," ")
  end
  M.codec={u32=u32,float=float};M.profile_spec=P
  return M
end
  local function live_native_context()
    return not cfg.runtime_paused and not ANEMONE_SECOND_COPY and globals and globals.is_in_game==true
  end
  Y.native_records=create({
    live=live_native_context,
    enabled=function() return Y.native_ready(1) and live_native_context() and (true) end,
    read_only=true,
    accept_selector_signature=function(rva,original,actual) return Y.native_trace and Y.native_trace:accept_signature(rva,original,actual) or false end,
    performance_reader=function()return yaw_mode()=="FFI" and Y.native_requested()end,
    selector_attempt_begin=function(r,yaw,confidence,state,detail,threshold,geometry) if Y.native_trace then return Y.native_trace:attempt_begin(r,yaw,confidence,state,detail,threshold,geometry) end end,
    selector_attempt_finish=function(number,stage,reason,variant) if Y.native_trace then Y.native_trace:attempt_finish(number,stage,reason,variant) end end,
    selector_attempt_unmapped=function(reason) if Y.native_trace then Y.native_trace:attempt_unmapped(reason) end end,
    selector_commit=function(v) if Y.native_trace then return Y.native_trace:commit(v) end;return false,"trace unavailable" end,
    selector_existing=function(v) if Y.native_trace then return Y.native_trace:queue_own_transfer(v,0,false) end;return false end,
    selector_deferred=function()return yaw_mode()=="FFI" end,
    priority_target=function()local ent=entity.get_threat();return ent and ent:get_index() or nil end,
    require_own_matrices=function()return yaw_mode()=="FFI" end,
    selector_refresh=function(v) if Y.native_trace then return Y.native_trace:bridge_refresh(v) end;return false end,
    selector_preflight_idle=function(c) return not Y.native_trace or not Y.native_trace:bridge_has_target(c.id,c.uid) end,
    selector_abstained=function(r,reason) if Y.native_trace then Y.native_trace:bridge_invalidate_record(r,reason) end end,
    selector_reset=function() if Y.native_trace then Y.native_trace:bridge_clear("reader/round reset") end end,
    selector_release=function(v,reason) if Y.native_trace then Y.native_trace:release(v,reason) end end,
    confidence_threshold=function(state,detail) return Y.native_threshold(state,detail) end,
    writes_enabled=function() return live_native_context() and Y.native_requested() end,
    identity=function(ent)
      if not ent then return nil end
      local info=ent:get_player_info()
      return info and {id=ent:get_index(),uid=tonumber(info.userid)} or nil
    end,
    players=function() return entity.get_players(true) end,
    tick=function() return tonumber(globals.tickcount) end,
    accept_profile_signature=function(rva,original,actual)
      return Y.native_patches and Y.native_patches:accept_signature(rva,original,actual) or false
    end,
    context=function(ent)
      if not ent then return nil,"no target" end
      if not ent:is_alive() then return nil,"target dead" end
      if ent:is_dormant() then return nil,"target dormant" end
      if not ent:is_enemy() then return nil,"target not enemy" end
      local info=ent:get_player_info();local sim=ent:get_simulation_time();local pos=ent:get_origin()
      if not info or not pos then return nil,"SDK player info/origin unavailable" end
      local current=type(sim)=="number" and sim or (sim and sim.current)
      local velocity=ent.m_vecVelocity
      local net_x,net_y,net_z
      pcall(function ()
        local network_origin=ent.m_vecOrigin
        if network_origin then net_x,net_y,net_z=tonumber(network_origin.x),tonumber(network_origin.y),tonumber(network_origin.z) end
      end)
      local render_x,render_y,render_z=tonumber(pos.x),tonumber(pos.y),tonumber(pos.z)
      local x,y,z,origin_source=Y.native_records:select_origin(render_x,render_y,render_z,net_x,net_y,net_z)
      local captured={id=ent:get_index(),uid=tonumber(info.userid),sim=tonumber(current),x=x,y=y,z=z,duck=tonumber(ent.m_flDuckAmount),tick=tonumber(globals.tickcount),sdk_flags=tonumber(ent.m_fFlags),sdk_vx=velocity and tonumber(velocity.x),sdk_vy=velocity and tonumber(velocity.y),sdk_vz=velocity and tonumber(velocity.z),net_x=net_x,net_y=net_y,net_z=net_z,render_x=render_x,render_y=render_y,render_z=render_z,origin_source=origin_source}
      local after=ent:get_simulation_time();local after_sim=type(after)=="number"and after or (after and after.current)
      local after_info=ent:get_player_info()
      if tonumber(after_sim)~=captured.sim or not after_info or tonumber(after_info.userid)~=captured.uid or ent:get_index()~=captured.id or tonumber(globals.tickcount)~=captured.tick then return nil,"SDK tuple changed during capture"end
      return captured
    end
  })
  N.records=Y.native_records
  cfg.native_selector_confidence:set_callback(function()
    if Y.native_records then Y.native_records:restore_live() end
    if Y.native_trace then Y.native_trace:bridge_clear("confidence threshold changed; prior approvals invalidated") end
  end)
  cfg.native_record_write:set_callback(function()
    if not get_bool(cfg.native_record_write) then Y.native_records:restore_live() end
  end)
end
do
local function create_code_patches(env)
  local M={state="OFF",owned={},faults={},writes=0,restores=0,conflicts=0,feature_stats={}}
  local BASE,SIZE=0x412A0000,0x3501000
  local function bytes(hex)
    return (hex:gsub("%x%x",function(x)return string.char(tonumber(x,16))end))
  end
  local sites={
    extrap={rva=0x159EBB,original=bytes("F7D90F48C883F902"),offset=7,length=1,group="extrap"},
    head_a={rva=0x1FE85C,original=bytes("837A28020F8EC2020000"),offset=4,length=6,group="hitscan"},
    head_b={rva=0x1FE8DC,original=bytes("837A28030F8C42020000"),offset=4,length=6,group="hitscan"},
    lerp={rva=0xB38DB,original=bytes("F30F581518A50542"),offset=4,length=4,group="lerp"},
  }
  local groups={extrap={"extrap"},hitscan={"head_a","head_b"},lerp={"lerp"}}
  local function readable(q)
    if not q or q.allocation~=BASE or q.kind~=0x20000 or q.state~=0x1000 then return false end
    local p=q.protect or 0;local low=p%256
    return math.floor(p/0x100)%2==0 and (low==2 or low==4 or low==8 or low==0x20 or low==0x40 or low==0x80)
  end
  function M:feature_counts(group)
    if not self.feature_stats[group] then self.feature_stats[group]={commits=0,restores=0} end
    return self.feature_stats[group]
  end
  function M:initialize()
    if self.io then return true end
    if self.init_error then self.state="BLOCKED: "..self.init_error;return false end
    if env.io then self.io=env.io;return true end
    local ok,io=pcall(function()
      local f=require("ffi")
      assert(f.os=="Windows" and f.sizeof("void*")==4,"Windows x86 LuaJIT required")
      if not pcall(f.typeof,"anp_mbi_v8") then
        f.cdef([[typedef struct { void* BaseAddress; void* AllocationBase; uint32_t AllocationProtect; size_t RegionSize; uint32_t State; uint32_t Protect; uint32_t Type; } anp_mbi_v8;
          void* __stdcall GetCurrentProcess(void);
          size_t __stdcall VirtualQuery(const void*,void*,size_t);
          int __stdcall ReadProcessMemory(void*,const void*,void*,size_t,size_t*);
          int __stdcall WriteProcessMemory(void*,void*,const void*,size_t,size_t*);
          int __stdcall VirtualProtect(void*,size_t,uint32_t,uint32_t*);
          int __stdcall FlushInstructionCache(void*,const void*,size_t);]])
      end
      assert(f.sizeof("anp_mbi_v8")==28,"unexpected Win32 memory layout")
      local lib=f.load("kernel32");local process=lib.GetCurrentProcess()
      local io={ffi=f,lib=lib,process=process,perf={queries=0,reads=0,data_writes=0,code_writes=0,data_cas=0,code_cas=0}}
      function io:query(a)
        self.perf.queries=self.perf.queries+1
        self._query_out=self._query_out or f.new("anp_mbi_v8[1]");local out=self._query_out
        if tonumber(lib.VirtualQuery(f.cast("const void*",a),out,28))~=28 then return nil end
        local q=out[0]
        return {base=tonumber(f.cast("uintptr_t",q.BaseAddress)),allocation=tonumber(f.cast("uintptr_t",q.AllocationBase)),size=tonumber(q.RegionSize),state=tonumber(q.State),protect=tonumber(q.Protect),kind=tonumber(q.Type)}
      end
      function io:read(a,n)
        self.perf.reads=self.perf.reads+1
        if not self._read_capacity or n>self._read_capacity then
          local capacity=256;while capacity<n do capacity=capacity*2 end
          self._read_capacity=capacity;self._read_out=f.new("uint8_t[?]",capacity)
        end
        self._read_got=self._read_got or f.new("size_t[1]")
        local out,got=self._read_out,self._read_got
        if lib.ReadProcessMemory(process,f.cast("const void*",a),out,n,got)==0 or tonumber(got[0])~=n then return nil end
        return f.string(out,n)
      end
      function io:write_data(a,data)
        if self.protection_pending and not self:finish_protection() then return false,"previous code protection restore pending" end
        local q=self:query(a);local p=q and (q.protect or 0)%256
        if not q or q.state~=0x1000 or q.kind~=0x20000 or not q.base or not q.size or a<q.base or a+#data>q.base+q.size or math.floor((q.protect or 0)/0x100)%2~=0 or (p~=4 and p~=8) then return false,"private RW write target unavailable" end
        self._write_got=self._write_got or f.new("size_t[1]")
        local got=self._write_got
        self.perf.data_writes=(self.perf.data_writes or 0)+1
        local written=lib.WriteProcessMemory(process,f.cast("void*",a),data,#data,got)~=0 and tonumber(got[0])==#data
        return written,not written and "RW WriteProcessMemory failed/partial" or nil
      end
      pcall(f.cdef,"int __stdcall QueryPerformanceCounter(int64_t*); int __stdcall QueryPerformanceFrequency(int64_t*);")
      local frequency=f.new("int64_t[1]")
      if lib.QueryPerformanceFrequency(frequency)~=0 and tonumber(frequency[0])>0 then
        local counter=f.new("int64_t[1]");local hz=tonumber(frequency[0])
        function io:time_us()if lib.QueryPerformanceCounter(counter)==0 then return nil end;return tonumber(counter[0])*1000000/hz end
      end
      function io:finish_protection()
        local pending=self.protection_pending
        if not pending then return true end
        local out=f.new("uint32_t[1]")
        if lib.VirtualProtect(f.cast("void*",pending.address),pending.length,pending.old,out)==0 then return false end
        self.protection_pending=nil;return true
      end
      function io:write(a,data)
        self.perf.code_writes=self.perf.code_writes+1
        if not self:finish_protection() then return false,"previous page protection restoration failed" end
        local address=f.cast("void*",a);local old=f.new("uint32_t[1]")
        if lib.VirtualProtect(address,#data,0x40,old)==0 then return false,"VirtualProtect failed" end
        self.protection_pending={address=a,length=#data,old=tonumber(old[0])}
        local out=f.new("uint8_t[?]",#data);f.copy(out,data,#data);local got=f.new("size_t[1]")
        local written=lib.WriteProcessMemory(process,address,out,#data,got)~=0 and tonumber(got[0])==#data
        local flushed=lib.FlushInstructionCache(process,address,#data)~=0
        local protected=self:finish_protection()
        if not protected then return false,"page protection restoration failed" end
        if not written then return false,"WriteProcessMemory failed/partial" end
        if not flushed then return false,"FlushInstructionCache failed" end
        return true
      end
      return io
    end)
    if not ok then self.init_error=tostring(io):gsub("%c"," "):sub(1,180);self.state="BLOCKED: "..self.init_error;return false end
    self.io=io;return true
  end
  function M:read(rva,n)
    if type(rva)~="number" or rva<0 or n<1 or n>32 or rva+n>SIZE or not self:initialize() then return nil end
    local a=BASE+rva
    local ok,q=pcall(self.io.query,self.io,a)
    if not ok or not readable(q) or not q.base or not q.size or q.base>a or q.base+q.size<a+n then return nil end
    local got,data=pcall(self.io.read,self.io,a,n)
    return got and type(data)=="string" and #data==n and data or nil
  end
  function M:check_build()
    if self:read(0xAEAC6,11)~=bytes("8986B0000000A14C004B42") then return false,"record-table anchor mismatch" end
    if self:read(0x160BF0,6)~=bytes("53575683EC14") then return false,"validator anchor changed (another hook/build)" end
    if self:read(0xE7897,14)~=bytes("0F57C0F30F51C10F2E0528A60542") then return false,"lerp locator mismatch" end
    if self:read(0xDBA518,4)~=bytes("0000003F") or self:read(0xDBA628,4)~=bytes("0000C03F") then return false,"0.5/1.5 constants mismatch" end
    for name,site in pairs(sites) do
      local owner=self.owned[name];local expected=owner and owner.after or site.original
      if self:read(site.rva,#site.original)~=expected then return false,name.." changed externally or build mismatch" end
    end
    return true
  end
  function M:restore_group(group)
    local clean=true
    for i=#groups[group],1,-1 do
      local name=groups[group][i];local site=sites[name];local owner=self.owned[name]
      if owner then
        local current=self:read(site.rva,#site.original)
        if current==site.original then self.owned[name]=nil
        elseif current~=owner.after then
          if not owner.conflict then self.conflicts=self.conflicts+1;owner.conflict=true end
          self.faults[group]=name.." restore withheld: bytes changed/unreadable";clean=false
        else
          local data=site.original:sub(site.offset+1,site.offset+site.length)
          local ok,written,err=pcall(self.io.write,self.io,BASE+site.rva+site.offset,data)
          local restored=self:read(site.rva,#site.original)==site.original
          if restored then self.owned[name]=nil;self.restores=self.restores+1;local h=self:feature_counts(group);h.restores=h.restores+1 end
          if not ok or not written or not restored then self.faults[group]=name.." restore failed: "..tostring(err or written);clean=false end
        end
      end
    end
    return clean
  end
  function M:restore_all()
    local a=self:restore_group("lerp");local b=self:restore_group("hitscan");local c=self:restore_group("extrap")
    local protected=true
    if self.io and self.io.finish_protection then
      local ok,value=pcall(self.io.finish_protection,self.io);protected=ok and value==true
    end
    self.state=a and b and c and protected and "OFF; owned code bytes restored" or "FAULT: restore incomplete; see patch report"
    return a and b and c and protected
  end
  function M:apply(group,desired)
    if self.faults[group] then return false end
    local valid,reason=self:check_build()
    if not valid then self.faults[group]=reason;self.state="BLOCKED: "..reason;return false end
    for _,name in ipairs(groups[group]) do
      local site=sites[name];local owner=self.owned[name]
      local before=owner and owner.after or site.original
      local after=desired[name]
      if before~=after then
        if self:read(site.rva,#before)~=before then self.faults[group]=name.." changed before write";self:restore_group(group);return false end
        -- Claim only this fixed verified site; keep the intended bytes for conflict-aware cleanup.
        self.owned[name]={after=after,conflict=false}
        local data=after:sub(site.offset+1,site.offset+site.length)
        local ok,written,err=pcall(self.io.write,self.io,BASE+site.rva+site.offset,data)
        local readback=self:read(site.rva,#after)
        if not ok or not written or readback~=after then
          self.faults[group]=name.." commit failed: "..tostring(err or written)
          self:restore_group(group);self.state="FAULT: "..self.faults[group];return false
        end
        self.writes=self.writes+1;local h=self:feature_counts(group);h.commits=h.commits+1
      end
    end
    return true
  end
  function M:accept_signature(rva,original,actual)
    if type(original)~="string" or type(actual)~="string" then return false end
    for name,site in pairs(sites) do
      local owner=self.owned[name]
      if owner and rva==site.rva and site.original:sub(1,#original)==original and owner.after:sub(1,#actual)==actual and #actual==#original then return true end
    end
    return false
  end
  function M:sync(force)
    local settings=env.settings()
    local live=env.live();local now=env.now and env.now() or 0
    local key=table.concat({tostring(settings.master),tostring(settings.hitscan),tostring(settings.lerp),tostring(settings.extrap),tostring(settings.ticks),tostring(live)},":")
    if not force and self.last_key==key and self.last_time and now>=self.last_time and now-self.last_time<0.25 then return end
    self.last_key,self.last_time=key,now
    if not settings.master or not live then
      if next(self.owned) or (self.io and self.io.protection_pending) then self:restore_all() else self.state="OFF; no code patches applied" end
      return
    end
    if not self:initialize() then return end
    local ticks=tonumber(settings.ticks)
    if not ticks or ticks~=math.floor(ticks) or ticks<1 or ticks>5 then self.state="BLOCKED: extrapolation ticks must be 1..5";return end
    local wanted={
      extrap=settings.extrap and {extrap=sites.extrap.original:sub(1,7)..string.char(ticks)} or nil,
      hitscan=settings.hitscan and {head_a=sites.head_a.original:sub(1,4)..string.rep("\144",6),head_b=sites.head_b.original:sub(1,4)..string.rep("\144",6)} or nil,
      lerp=settings.lerp and {lerp=sites.lerp.original:sub(1,4)..bytes("28A60542")} or nil,
    }
    -- Release disabled sites before checking/applying the requested profile.
    for _,group in ipairs({"lerp","hitscan","extrap"}) do if not wanted[group] then self:restore_group(group) end end
    if not wanted.extrap and not wanted.hitscan and not wanted.lerp then
      self.state=next(self.owned) and "FAULT: restore incomplete" or "ON; no patch feature enabled";return
    end
    for _,group in ipairs({"extrap","hitscan","lerp"}) do if wanted[group] then self:apply(group,wanted[group]) end end
    local failed=false;for _ in pairs(self.faults) do failed=true end
    self.state=failed and "BLOCKED/FAULT; see per-feature patch status" or "verified native code patch profile; selector writer is a separate module"
  end
  function M:report_lines()
    local lines={string.format("Native code patches state=%s code_commits=%d restores=%d conflicts=%d",self.state,self.writes,self.restores,self.conflicts)}
    local ok,settings=pcall(env.settings);if not ok or type(settings)~="table" then settings={} end
    lines[#lines+1]=string.format("Native code configuration master=%s extrap=%s ticks=%s hitscan=%s lerp=%s",tostring(settings.master==true),tostring(settings.extrap==true),tostring(settings.ticks),tostring(settings.hitscan==true),tostring(settings.lerp==true))
    local function hex(value) if not value then return "unavailable" end;return (value:gsub(".",function(c)return string.format("%02X",c:byte())end)) end
    local ticks=tonumber(settings.ticks)
    local desired={head_a=sites.head_a.original:sub(1,4)..string.rep("\144",6),head_b=sites.head_b.original:sub(1,4)..string.rep("\144",6),lerp=sites.lerp.original:sub(1,4)..bytes("28A60542")}
    if ticks and ticks==math.floor(ticks) and ticks>=1 and ticks<=5 then desired.extrap=sites.extrap.original:sub(1,7)..string.char(ticks) end
    if self.io then
      local valid,reason=self:check_build()
      lines[#lines+1]="Native code read_only_profile="..(valid and "matched" or "mismatch").." reason="..tostring(reason or "pinned anchors/constants/current ownership matched")
    else lines[#lines+1]="Native code read_only_profile=backend_not_initialized; report does not initialize or enable patches" end
    for _,group in ipairs({"extrap","hitscan","lerp"}) do
      local active,verified=0,0;local details={}
      for _,name in ipairs(groups[group])do local site=sites[name];local owner=self.owned[name]
        if owner then active=active+1 end
        local current=self.io and self:read(site.rva,#site.original) or nil
        local status
        if not self.io then status="backend_not_initialized"
        elseif owner and current==owner.after then status="owned_readback_ok";verified=verified+1
        elseif owner then status="owned_readback_mismatch_or_unreadable"
        elseif current==site.original then status="original_unpatched"
        elseif desired[name] and current==desired[name] then status="matching_patch_bytes_without_ownership"
        else status="foreign_bytes_or_unreadable" end
        details[#details+1]=string.format("Native code site=%s RVA=%X state=%s current=%s original=%s desired=%s",name,site.rva,status,hex(current),hex(site.original),hex(desired[name]))
      end
      local h=self:feature_counts(group)
      lines[#lines+1]=string.format("Native code feature=%s requested=%s owned_sites=%d readback_verified=%d/%d feature_commits=%d feature_restores=%d status=%s",group,tostring(settings[group]==true),active,verified,#groups[group],h.commits,h.restores,tostring(self.faults[group] or (active>0 and (verified==active and "applied bytes verified; gameplay effect unproven" or "ownership readback mismatch") or "not applied")))
      for _,line in ipairs(details)do lines[#lines+1]=line end
    end
    lines[#lines+1]="Native code proof=configuration, current bytes and owned write/restore only; extrap/hitscan/lerp gameplay effect NOT proven; no matrix or record copying"
    if self.io and self.io.protection_pending then lines[#lines+1]="Native code FAULT: original page protection restoration pending" end
    return lines
  end
  M.sites=sites;M.groups=groups
  return M
end
  Y.native_patches=create_code_patches({
    live=function() return not cfg.runtime_paused and not ANEMONE_SECOND_COPY and globals and globals.is_in_game==true end,
    now=function() return globals and tonumber(globals.realtime) or 0 end,
    settings=function()
      local allowed=not ANEMONE_SECOND_COPY;local resolver=allowed and get_bool(cfg.resolver) and not cfg.runtime_paused;local extrap=allowed and get_bool(cfg.extrapolation) and not cfg.runtime_paused
      return {master=resolver or extrap,hitscan=resolver,lerp=resolver,extrap=extrap,ticks=cfg.native_patch_ticks:get()}
    end,
  })
  local function sync_native_patches()
    local ok,err=pcall(Y.native_patches.sync,Y.native_patches,true)
    if not ok then Y.native_patches.state="FAULT: "..tostring(err):gsub("%c"," "):sub(1,180);console_line("[Anemone] Native code patches: "..Y.native_patches.state) end
  end
  for _,item in ipairs({cfg.resolver,cfg.extrapolation,cfg.native_patch_ticks}) do item:set_callback(sync_native_patches) end
  chain("shutdown",function()
    local ok,restored=pcall(Y.native_patches.restore_all,Y.native_patches)
    if not ok or not restored then console_line("[Anemone] Native code patch restore incomplete; no foreign bytes overwritten") end
  end)
end
do
local function create_trace(env)
  local M={state="OFF",owned={},fault=nil,installs=0,restores=0,conflicts=0,last_seq=0,lost=0,events=0,sites_seen={},recent={},intervals={},commit_counter=0,shots={},shot_order={},shot_total=0,acks=0,context_recent={},site_recent={},relations={}}
  local BASE,SELECTOR,CAP,ROW=0x412A0000,0x413F89C0,128,64
  local function word(n) n=n%4294967296;return string.char(n%256,math.floor(n/256)%256,math.floor(n/65536)%256,math.floor(n/16777216)%256) end
  local function u32(s,o)if not s or #s<o+4 then return nil end;local a,b,c,d=s:byte(o+1,o+4);return a+256*b+65536*c+16777216*d end
  local function has(x,m)return math.floor(x/m)%2==1 end
  local function fromhex(h)return (h:gsub('%x%x',function(x)return string.char(tonumber(x,16))end))end
  local sites={{rva=0xDEE99,name="record_copy",source="record_field",window="\131\224\004\106\000\255\180\008\140\000\000\000\232\034\155\007\000\139\142\164\000\000\000\193\225"},{rva=0x15C198,name="matrix_copy_args",source="caller_args",window="\000\000\137\249\255\117\016\137\215\255\117\012\232\035\200\255\255\139\143\032\041\000\000\193\225"},{rva=0x1E1910,name="context_path_a",source="shot_context",window="\255\176\224\000\000\000\255\176\220\000\000\000\232\171\112\247\255\139\014\129\193\140\007\000\000"},{rva=0x1E47FF,name="context_path_b",source="shot_context",window="\255\176\224\000\000\000\255\176\220\000\000\000\232\188\065\247\255\139\014\129\193\140\007\000\000"},{rva=0x1EC173,name="scan_variants",source="scan_enum",window="\199\134\216\000\000\000\255\255\255\255\080\082\232\072\200\246\255\131\236\016\243\015\016\134\136"}}
  local TEMPLATE="\085\137\229\141\100\036\128\137\077\252\199\069\216\000\000\000\000\156\096\139\069\008\137\069\212\199\069\208\000\000\000\000\199\069\204\000\000\000\000\199\069\200\000\000\000\000\199\069\196\000\000\000\000\199\069\192\000\000\000\000\199\069\188\000\000\000\000\199\069\184\000\000\000\000\199\069\180\000\000\000\000\199\069\176\000\000\000\000\199\069\172\000\000\000\000\199\069\168\000\000\000\000\199\069\164\000\000\000\000\199\069\160\000\000\000\000\199\069\156\000\000\000\000\199\069\152\000\000\000\000\199\069\148\000\000\000\000\199\069\144\000\000\000\000\199\069\140\000\000\000\000\199\069\136\000\000\000\000\199\069\132\000\000\000\000\191\068\051\034\017\131\127\012\001\015\133\029\003\000\000\131\127\036\001\117\039\129\125\004\021\025\072\065\116\030\129\125\004\004\072\072\065\116\021\184\001\000\000\000\240\015\193\071\040\169\063\000\000\000\015\133\240\002\000\000\139\065\060\137\069\248\139\129\132\000\000\000\137\069\244\139\129\148\000\000\000\137\069\240\139\129\176\000\000\000\137\069\236\139\129\140\000\000\000\137\069\232\139\129\144\000\000\000\137\069\228\139\071\016\137\069\224\139\071\020\137\069\220\199\069\216\001\000\000\000\131\127\028\001\015\133\160\002\000\000\129\125\004\021\025\072\065\015\133\147\002\000\000\131\125\012\000\015\133\234\001\000\000\139\069\236\169\004\000\000\000\015\133\232\001\000\000\169\032\000\000\000\015\132\221\001\000\000\139\069\248\072\131\248\063\015\135\220\001\000\000\139\069\248\107\192\017\003\069\244\131\224\127\137\069\204\193\224\006\141\180\007\000\033\000\000\139\022\137\085\200\139\070\032\137\069\196\139\070\004\137\069\192\139\070\008\137\069\188\139\070\012\137\069\184\139\070\016\137\069\180\139\070\040\137\069\176\139\070\044\137\069\172\139\070\048\137\069\160\139\070\052\137\069\156\139\070\056\137\069\152\139\070\060\137\069\132\199\069\164\001\000\000\000\057\022\015\133\217\001\000\000\247\194\001\000\000\000\015\133\106\001\000\000\199\069\164\002\000\000\000\131\125\196\001\015\133\098\001\000\000\139\069\252\057\070\004\015\133\095\001\000\000\139\069\248\057\070\008\015\133\092\001\000\000\139\069\244\057\070\012\015\133\089\001\000\000\139\069\240\057\070\016\015\133\086\001\000\000\139\069\220\057\070\044\015\133\083\001\000\000\161\040\244\035\066\059\071\032\015\133\078\001\000\000\133\192\015\132\070\001\000\000\139\128\108\001\000\000\137\069\168\059\070\024\015\130\061\001\000\000\059\070\028\015\135\052\001\000\000\139\078\020\131\249\001\015\130\049\001\000\000\131\249\002\015\135\040\001\000\000\057\022\015\133\050\001\000\000\131\127\028\001\015\133\049\001\000\000\131\127\012\001\015\133\039\001\000\000\139\069\220\057\071\020\015\133\229\000\000\000\139\070\040\133\192\015\132\025\001\000\000\061\255\255\255\000\015\135\014\001\000\000\057\022\015\133\244\000\000\000\131\125\152\000\116\077\131\125\152\001\117\088\129\125\132\128\000\000\000\117\079\129\125\160\000\000\001\000\114\070\129\125\160\255\231\255\255\119\061\247\069\160\003\000\000\000\117\052\129\125\156\000\000\001\000\114\043\129\125\156\255\231\255\255\119\034\247\069\156\003\000\000\000\117\025\057\022\015\133\161\000\000\000\193\224\008\131\200\001\137\069\208\137\077\212\233\171\000\000\000\199\069\208\020\000\000\000\233\159\000\000\000\199\069\208\002\000\000\000\233\147\000\000\000\199\069\208\003\000\000\000\233\135\000\000\000\199\069\208\004\000\000\000\235\126\199\069\208\018\000\000\000\235\117\199\069\208\005\000\000\000\235\108\199\069\208\006\000\000\000\235\099\199\069\208\007\000\000\000\235\090\199\069\208\008\000\000\000\235\081\199\069\208\009\000\000\000\235\072\199\069\208\010\000\000\000\235\063\199\069\208\011\000\000\000\235\054\199\069\208\012\000\000\000\235\045\199\069\208\013\000\000\000\235\036\199\069\208\014\000\000\000\235\027\199\069\208\015\000\000\000\235\018\199\069\208\016\000\000\000\235\009\199\069\208\017\000\000\000\235\000\097\157\255\117\012\255\117\212\232\136\119\102\085\156\096\191\068\051\034\017\139\068\036\028\137\069\144\128\125\208\001\015\133\208\000\000\000\131\125\152\001\015\133\198\000\000\000\199\069\136\002\000\000\000\131\127\012\001\015\133\181\000\000\000\131\127\028\001\015\133\171\000\000\000\139\069\220\057\071\020\015\133\159\000\000\000\139\069\204\193\224\006\141\180\007\000\033\000\000\139\069\200\057\006\015\133\135\000\000\000\139\069\208\193\232\008\057\070\040\117\124\131\126\056\001\117\118\161\040\244\035\066\059\071\032\117\108\139\128\108\001\000\000\059\070\024\114\097\059\070\028\119\092\137\069\168\139\069\252\131\125\212\001\117\007\005\192\048\000\000\235\005\005\192\024\000\000\057\069\144\116\020\005\000\120\000\000\057\069\144\117\053\139\069\156\057\070\052\117\045\235\008\139\069\160\057\070\048\117\035\139\085\200\057\022\117\028\137\068\036\028\137\069\140\199\069\136\001\000\000\000\139\069\208\037\000\255\255\255\131\200\019\137\069\208\131\127\012\001\015\133\088\001\000\000\131\125\216\001\015\133\078\001\000\000\139\069\220\057\071\020\015\133\066\001\000\000\129\125\004\120\193\072\065\117\028\131\125\232\000\117\022\184\001\000\000\000\240\015\193\071\024\064\169\031\000\000\000\015\133\029\001\000\000\049\192\186\001\000\000\000\240\015\177\023\015\133\008\001\000\000\139\119\004\131\254\254\015\131\246\000\000\000\070\137\240\072\131\224\127\193\224\006\141\092\007\064\199\003\000\000\000\000\139\069\004\137\067\004\139\069\252\137\067\008\139\069\248\137\067\012\139\069\244\137\067\016\139\069\240\137\067\020\139\069\212\137\067\024\139\069\012\137\067\028\139\069\236\137\067\032\139\069\232\137\067\036\139\068\036\028\137\067\040\139\069\224\137\067\044\139\069\228\137\067\048\139\069\220\137\067\052\139\069\008\137\067\056\139\069\208\137\067\060\129\125\004\021\025\072\065\117\113\137\240\131\224\015\193\224\006\141\140\007\000\073\000\000\199\001\000\000\000\000\139\069\204\137\065\004\139\069\200\137\065\008\139\069\196\137\065\012\139\069\192\137\065\016\139\069\188\137\065\020\139\069\184\137\065\024\139\069\180\137\065\028\139\069\176\137\065\032\139\069\172\137\065\036\139\069\168\137\065\040\139\069\164\137\065\044\139\069\144\137\065\048\139\069\140\137\065\052\139\069\136\137\065\056\139\069\152\137\065\060\137\049\137\051\137\119\004\199\007\000\000\000\000\235\010\199\007\000\000\000\000\240\255\071\008\097\157\137\236\093\194\008\000"
  local CAS="\139\076\036\004\139\068\036\008\139\084\036\012\240\015\177\017\015\148\192\015\182\192\195"
  local function readable(q,a,n)
    if not q or q.state~=0x1000 or not q.base or not q.size or q.base>a or q.base+q.size<a+n then return false end
    local p=q.protect or 0;local b=p%256
    return not has(p,0x100) and (b==2 or b==4 or b==8 or b==0x20 or b==0x40 or b==0x80)
  end
  function M:read(a,n)
    if not self.io or n<1 or n>16384 or a<65536 or a+n>4294967296 then return nil end
    local ok,q=pcall(self.io.query,self.io,a);if not ok or not readable(q,a,n) then return nil end
    local good,data=pcall(self.io.read,self.io,a,n)
    return good and type(data)=="string" and #data==n and data or nil
  end
  function M:register_rw(base,size)
    self.rw_pages=self.rw_pages or {}
    local q={base=base,size=size}
    for page=math.floor(base/4096),math.floor((base+size-1)/4096)do self.rw_pages[page]=q end
  end
  function M:owns_rw(a,n)
    local q=self.rw_pages and self.rw_pages[math.floor(a/4096)]
    return q and a>=q.base and a+n<=q.base+q.size
  end
  function M:write(a,data)
    local fn=self:owns_rw(a,#data) and self.io.write_data or self.io.write
    local ok,written,reason=pcall(fn,self.io,a,data)
    return ok and written==true,reason or (not ok and tostring(written) or nil)
  end
  function M:patch(a,before,after)
    if self.code and self:read(self.code+2048,#CAS)~=CAS then return false,"atomic helper code changed" end
    if self:read(a-1,1)~="\232" then return false,"CALL opcode changed" end
    local ok,written,reason=pcall(self.io.atomic,self.io,a,u32(before,0),u32(after,0))
    return ok and written==true,reason or (not ok and tostring(written) or nil)
  end
  function M:prepare()
    if self.io and self.data and self.code then return true end
    if self.fault then return false end
    local ok,reason=pcall(function()
      if env.io then self.io=env.io else
        local p=env.backend();assert(p and p:initialize(),"Windows code backend unavailable");self.io=p.io
      end
      local io=self.io
      if not io.allocate then
        local f=io.ffi;assert(f and f.os=="Windows" and f.sizeof("void*")==4,"Windows x86 LuaJIT required")
        if not pcall(f.typeof,"ant_alloc_v13") then f.cdef("typedef void* (__stdcall *ant_alloc_v13)(void*,size_t,uint32_t,uint32_t); void* __stdcall VirtualAlloc(void*,size_t,uint32_t,uint32_t);") end
        function io:allocate(n,protection)
          local ptr=self.lib.VirtualAlloc(nil,n,0x3000,protection)
          local a=tonumber(f.cast("uintptr_t",ptr));return a and a>=65536 and a or nil
        end
      end
      self.data=assert(io:allocate(0x8000,4),"trace data allocation failed")
      self.code=assert(io:allocate(0x1000,0x20),"trace executable allocation failed")
      self:register_rw(self.data,0x8000)
      assert(self:write(self.data,string.rep("\0",0x2040)),"trace data initialization failed")
      local function replace(s,o,w)return s:sub(1,o)..w..s:sub(o+5) end
      local payload=TEMPLATE
      payload=replace(payload,0xA6,word(self.data));payload=replace(payload,0x3E1,word(self.data))
      payload=replace(payload,0x3DA,word(SELECTOR-(self.code+0x3DA+4)))
      self.payload=payload
      self.code_image=payload..string.rep("\144",2048-#payload)..CAS
      assert(self:write(self.code,self.code_image),"wrapper write failed")
      assert(self:read(self.code,#self.code_image)==self.code_image,"wrapper/helper readback failed")
      if not io.atomic then
        local f,lib=io.ffi,io.lib
        local fn,abi_reason=self:abi_function("atomic_cas",self.code+2048)
        assert(fn,abi_reason)
        self.atomic_fn=fn
        function io:atomic(a,expected,replacement)
          self.perf=self.perf or {};self.perf.code_cas=(self.perf.code_cas or 0)+1
          if not self:finish_protection() then return false,"previous protection restore pending" end
          local old=f.new("uint32_t[1]")
          if lib.VirtualProtect(f.cast("void*",a),4,0x40,old)==0 then return false,"CALL operand protection failed" end
          self.protection_pending={address=a,length=4,old=tonumber(old[0])}
          local ok,value=pcall(fn,f.cast("uint32_t*",a),expected,replacement)
          local flushed=lib.FlushInstructionCache(self.process,f.cast("void*",a),4)~=0
          local protected=self:finish_protection()
          return ok and tonumber(value)==1 and flushed and protected,not ok and tostring(value) or (not protected and "CALL protection restore failed" or (not flushed and "instruction cache flush failed" or "CALL compare-exchange mismatch"))
        end
      end
      if not io.atomic_data and self.atomic_fn then
        local f,fn=io.ffi,self.atomic_fn
        function io:atomic_data(a,expected,replacement)
          if self.protection_pending and not self:finish_protection() then return false,"previous code protection restore pending" end
          local q=self:query(a);local p=q and (q.protect or 0)%256
          if not q or q.state~=0x1000 or q.kind~=0x20000 or not q.base or not q.size or a<q.base or a+4>q.base+q.size or has(q.protect or 0,0x100) or (p~=4 and p~=8) then return false,"private RW atomic target unavailable" end
          self.perf=self.perf or {};self.perf.data_cas=(self.perf.data_cas or 0)+1
          local ok,value=pcall(fn,f.cast("uint32_t*",a),expected,replacement)
          return ok and tonumber(value)==1,not ok and tostring(value) or (tonumber(value)~=1 and "RW compare-exchange mismatch" or nil)
        end
      end
      for _,site in ipairs(sites) do site.after="\232"..word(self.code-(BASE+site.rva+5));site.original=site.window:sub(13,17) end
    end)
    if not ok then self.fault=tostring(reason):gsub("%c"," "):sub(1,180);self.state="BLOCKED: "..self.fault;return false end
    return true
  end
  function M:site_image(site,patched)
    return patched and site.window:sub(1,12)..site.after..site.window:sub(18) or site.window
  end
  function M:check()
    if not self.io then return false end
    if self:read(SELECTOR,224)~="\083\087\086\131\236\020\137\206\139\124\036\036\139\092\036\040\161\000\039\038\066\049\224\137\068\036\016\198\068\036\012\000\242\015\016\068\036\008\242\015\017\004\036\232\208\176\255\255\131\236\008\232\152\035\121\000\139\142\176\000\000\000\137\202\131\226\064\193\234\006\131\251\001\015\148\196\032\212\132\192\116\012\132\228\116\020\129\198\192\096\000\000\235\036\132\228\116\021\129\198\192\216\000\000\235\024\246\193\032\117\041\129\198\192\000\000\000\235\011\246\193\032\117\048\129\198\192\120\000\000\139\076\036\016\049\225\232\015\242\154\000\137\240\131\196\020\094\095\091\194\008\000\131\255\003\119\210\255\036\189\136\072\007\066\129\198\192\048\000\000\235\214\131\255\003\119\203\255\036\189\120\072\007\066\129\198\192\168\000\000\235\194\132\201\120\020\129\198\192\024\000\000\235\182\132\201\120\016\129\198\192\144\000\000\235\170\129\198\192\072\000\000\235\162" then return false,"selector body mismatch" end
    if self:read(BASE+0x157597,17)~="\161\040\244\035\066\139\136\108\001\000\000\137\143\132\000\000\000" then return false,"native clock instruction anchor mismatch" end
    if self:read(BASE+0xDD4878,32)~="\060\138\063\065\120\138\063\065\144\138\063\065\140\138\063\065\047\138\063\065\100\138\063\065\132\138\063\065\128\138\063\065" then return false,"selector dispatch table mismatch" end
    if self:read(self.code,#self.code_image)~=self.code_image then return false,"owned wrapper code changed" end
    for _,site in ipairs(sites) do
      if self:read(BASE+site.rva-12,#site.window)~=self:site_image(site,self.owned[site.rva]) then return false,"CALL site changed: "..site.name end
    end
    return true
  end
  function M:counter()
    if not self.data then return nil end
    local b=self:read(self.data,28)
    if not b or u32(b,0)~=0 then return nil end
    self.filtered_scan_candidates=u32(b,24)
    return u32(b,4),u32(b,8),u32(b,20)
  end
  function M:stop()
    self.interface_cache=nil
    self.interface_cache=nil
    self:bridge_off()
    if not self.running and not next(self.owned) then return end
    if self.running and not self.fault then self:poll() end
    if self.data and not self:write(self.data+12,word(0)) then self.fault="trace disable write failed";self.state="BLOCKED: "..self.fault end
    self.running=false
    for i=#sites,1,-1 do
      local site=sites[i]
      if self.owned[site.rva] then
        local a=BASE+site.rva;local b=self:read(a,5)
        if b==site.original then self.owned[site.rva]=nil
        elseif b~=site.after then
          if not self.conflicted then self.conflicts=self.conflicts+1;self.conflicted=true end
          self.fault="restore withheld: CALL bytes changed";self.state="BLOCKED: "..self.fault
        else
          local ok,reason=self:patch(a+1,site.after:sub(2),site.original:sub(2))
          if self:read(a,5)==site.original then self.owned[site.rva]=nil;self.restores=self.restores+1 end
          if not ok then self.fault=tostring(reason or "CALL restore failed");self.state="BLOCKED: "..self.fault end
        end
      end
    end
    if not next(self.owned) and not self.fault then self.state="OFF; CALL targets restored" end
  end
  function M:sync(defer_poll)
    local wanted=env.enabled() and env.live()
    if not wanted or self.fault then self:stop();return end
    if not self:prepare() then return end
    local production=env.production_filter and env.production_filter() and 1 or 0
    if self.running and self.production_filter_value~=production then self:stop();if self.fault or next(self.owned) then return end end
    if self.production_filter_value~=production then
      if not self:write(self.data+36,word(production)) or u32(self:read(self.data+36,4),0)~=production then self.fault="production trace filter publication failed";self:stop();return end
      self.production_filter_value=production
    end
    if not self.running then
      local ok,reason=self:check();if not ok then self.fault=reason;self:stop();return end
      self.generation=(self.generation or 0)+1
      assert(self:write(self.data+16,word(env.tick())..word(self.generation)))
      self.last_published_tick=env.tick()
      for _,site in ipairs(sites) do
        if production~=1 or site.source=="shot_context" then
          self.owned[site.rva]=true
          local written,why=self:patch(BASE+site.rva+1,site.original:sub(2),site.after:sub(2))
          if not written or self:read(BASE+site.rva,5)~=site.after then self.fault="CALL install failed: "..tostring(why);self:stop();return end
          self.installs=self.installs+1
        end
      end
      if not self:write(self.data+12,word(1)) then self.fault="trace enable write failed";self:stop();return end
      self.running=true;self.state="ON; CALL observation with optional guarded argument bridge"
    else
      local tick=env.tick()
      if tick~=self.last_published_tick then
        if not self:write(self.data+16,word(tick)) then self.fault="published tick write failed";self:stop();return end
        self.last_published_tick=tick
      end
      if not self.last_check or tick<self.last_check or tick-self.last_check>=16 then
        local ok,reason=self:check();self.last_check=tick
        if not ok then self.fault=reason;self:stop() end
      end
    end
    self:bridge_sync()
    if not defer_poll then self:poll() end
  end
  function M:accept_signature(rva,original,actual)
    if not self.io or type(actual)~="string" or #actual~=#original then return false end
    local expected=original;local touched=false
    for _,site in ipairs(sites) do
      if self.owned[site.rva] and site.rva>=rva and site.rva+5<=rva+#original then
        if self:read(BASE+site.rva,5)~=site.after then return false end
        local off=site.rva-rva
        if original:sub(off+1,off+5)~=site.original then return false end
        expected=expected:sub(1,off)..site.after..expected:sub(off+6);touched=true
      end
    end
    return touched and actual==expected
  end
  local function approval_bucket(id,capture_tick) return (capture_tick+id*17)%128 end
  local function tuple_key(v)
    return table.concat({v.pointer,v.id,v.capture_tick,v.sim_bits,v.generation or 0},":")
  end
  function M:own_code_match(address,expected,stage)
    local actual=self:read(address,#expected)
    local stable=actual~=nil and actual==self:read(address,#expected)
    local d=self.own_consumer_profile or {checks=0,rejections=0}
    self.own_consumer_profile=d;d.checks=d.checks+1
    if actual==expected and stable then
      d.last_pass_tick=env.tick();return true
    end
    d.rejections=d.rejections+1;d.stage=stage;d.address=address;d.expected=expected;d.actual=actual;d.stable=stable;d.tick=env.tick();d.first=nil;d.differing=0
    if actual and #actual==#expected then
      for i=1,#expected do if actual:byte(i)~=expected:byte(i) then d.first=d.first or i-1;d.differing=d.differing+1 end end
    end
    if not actual then return false,stage.." unreadable" end
    if not stable then return false,stage.." changed between reads" end
    return false,stage.." mismatch"
  end
  function M:interface_pointer(kind,factory,refresh)
    if not env.performance_interfaces then return factory() end
    self.interface_cache=self.interface_cache or {}
    if not refresh and self.interface_cache[kind] then return self.interface_cache[kind] end
    local value=factory()
    if type(value)=="number" and value>=65536 then self.interface_cache[kind]=value else self.interface_cache[kind]=nil end
    return value
  end
  function M:own_runtime_binding(model,target)
    model=model or 0x60CCD560
    if not env.runtime_model_info_pointer then return false,"runtime consumer interface verifier unavailable" end
    local ok,ptr=pcall(self.interface_pointer,self,"model_info",env.runtime_model_info_pointer)
    if ok and ptr~=model and env.performance_interfaces then ok,ptr=pcall(self.interface_pointer,self,"model_info",env.runtime_model_info_pointer,true) end
    self.own_runtime_interface=ok and ptr or nil
    if not ok or ptr~=model then return false,"runtime consumer ModelInfo pointer differs from captured session profile: factory="..tostring(ptr) end
    local vt=u32(self:read(model,4),0)
    local fn=vt and u32(self:read(vt+0x80,4),0) or nil
    if not fn or fn<65536 then return false,"runtime consumer ModelInfo vtable slot unreadable" end
    local function executable(address)
      local good,q=pcall(self.io.query,self.io,address)
      if not good or not q or q.state~=0x1000 or not q.base or not q.size or address<q.base or address>=q.base+q.size or has(q.protect or 0,0x100) then return false end
      local p=(q.protect or 0)%256;return p==0x20 or p==0x40 or p==0x80
    end
    if not executable(fn) or not self:read(fn,1) then return false,"runtime consumer ModelInfo vtable slot not executable/readable" end
    target=target or 0x33B705D0
    if not executable(target) then return false,"captured consumer jump target not executable" end
    local bytes=self:read(target,32)
    if not bytes or self:read(target,32)~=bytes then return false,"captured consumer jump target unreadable or unstable" end
    self.runtime_stub_pins=self.runtime_stub_pins or {}
    if self.runtime_stub_pins[target] and self.runtime_stub_pins[target]~=bytes then return false,"captured consumer jump target changed after binding" end
    self.runtime_stub_pins[target]=bytes
    self.own_runtime_trampoline=bytes;self.own_runtime_target=target;self.own_runtime_model_fn=fn
    return true
  end
  function M:own_profile()
    local ok,why=self:own_code_match(BASE+0x1E1915,"\139\014\129\193\140\007\000\000\080\139\134\208\000\000\000\255\048\232\165\183\239\255","own matrix consumer tail");if not ok then return false,why end
    local runtime_expected="\085\083\087\086\131\236\028\137\076\036\016\139\116\036\048\161\000\039\038\066\049\224\137\068\036\024\086\232\112\142\041\000\131\196\004\133\192\015\132\212\002\000\000\137\199\139\000\137\249\255\144\148\000\000\000\137\197\128\184\070\005\000\000\001\184\069\005\000\000\131\216\000\128\124\005\000\000\015\132\172\002\000\000\139\006\137\241\255\080\040\137\195\243\015\016\000\243\015\017\068\036\020\141\068\036\020\080\232\219\155\202\000\131\196\004\102\133\192\015\143\131\002\000\000\243\015\016\067\004\243\015\017\068\036\020\141\068\036\020\080\232\186\155\202\000\131\196\004\102\133\192\015\143\098\002\000\000\243\015\016\067\008\243\015\017\068\036\020\141\068\036\020\080\232\153\155\202\000\131\196\004\102\133\192\015\143\065\002\000\000\243\015\016\003\243\015\017\068\036\020\141\068\036\020\080\232\121\155\202\000\131\196\004\102\131\248\002\015\132\032\002\000\000\243\015\016\067\004\243\015\017\068\036\020\141\068\036\020\080\232\087\155\202\000\131\196\004\102\131\248\002\015\132\254\001\000\000\243\015\016\067\008\243\015\017\068\036\020\141\068\036\020\080\232\053\155\202\000\131\196\004\102\131\248\002\015\132\220\001\000\000\139\006\137\241\255\080\044\137\068\036\012\139\006\137\241\255\080\020\133\192\015\132\194\001\000\000\139\070\004\131\198\004\137\241\255\080\032\133\192\015\132\175\001\000\000\137\198\137\092\036\008\233\165\051\127\242\144\139\136\168\000\000\000\003\136\164\000\000\000\003\136\184\000\000\000\003\136\188\000\000\000\003\072\100\184\116\092\117\062\193\201\032\193\192\022\193\203\032\005\151\205\167\085\053\231\195\161\060\045\162\020\024\044\053\071\148\254\033\144\137\068\036\020\057\076\036\020\116\035\137\232\015\190\244\001\216\102\041\250\192\194\016\102\209\202\102\193\236\002\102\211\228\015\205\049\251\008\210\128\227\062\253\255\226\184\096\213\204\096\144\144\144\144\144\144\144\144\144\144\144\144\144\144\144\144\144\144\144\144\144\144\144\144\144\144\144\144\144\144\137\068\036\020\139\076\036\020\139\001\086\255\144\128\000\000\000\133\192\015\132\252\000\000\000\137\068\036\004\139\157\000\005\000\000\128\187\246\014\000\000\001\184\245\014\000\000\131\216\000\128\060\003\000\139\076\036\016\116\028\139\001\139\081\004\057\208\116\019\199\128\208\030\000\000\000\000\000\000\005\216\030\000\000\057\208\117\237\139\105\004\059\105\008\116\053\104\212\030\000\000\106\000\085\137\092\036\012\137\243\137\206\232\241\251\200\000\131\196\012\199\133\212\030\000\000\000\000\128\063\139\110\004\141\133\216\030\000\000\137\070\004\137\222\139\028\036\235\008\085\232\171\225\000\000\137\197\137\125\000\141\125\004\137\249\232\172\243\127\000\015\183\134\056\001\000\000\137\249\080\232\093\255\127\000\141\133\160\006\000\000\139\076\036\004\139\137\156\000\000\000\193\225\004\141\012\073\081\255\116\036\056\080\232\012\246\200\000\131\196\012\141\133\160\030\000\000\255\116\036\008\255\116\036\016\080\232\021\093\031\000\131\196\012\161\004\202\035\066\015\182\139\236\015\000\000\243\015\016\132\139\228\015\000\000\243\015\088\000\243\015\017\133\208\030\000\000\139\076\036\024\049\225\232\130\168\162\000\131\196\028\094\095\091\093\194\008\000"
    local live=self:read(BASE+0xDD0D0,0x314)
    -- Only rel32 and the materialized ModelInfo pointer may vary. Opcodes/NOPs/all other body bytes stay exact.
    local normalized=live
    if live and #live==#runtime_expected then
      normalized=live:sub(1,0x157)..runtime_expected:sub(0x158,0x15B)..live:sub(0x15C)
      normalized=normalized:sub(1,0x1C8)..runtime_expected:sub(0x1C9,0x1CC)..normalized:sub(0x1CD)
    end
    if normalized==runtime_expected then
      local displacement=u32(live,0x157)
      if displacement>=2147483648 then displacement=displacement-4294967296 end
      local target=BASE+0xDD0D0+0x156+5+displacement
      local model=u32(live,0x1C8)
      if target<65536 or target+32>4294967296 or model<65536 then return false,"runtime consumer operand outside address range" end
      self.own_consumer_profile_mode="validated_runtime_operands"
      local bound,reason=self:own_runtime_binding(model,target);self.own_runtime_binding_status=bound and "matched" or reason
      if not bound then return false,reason end
      return self:own_code_match(BASE+0xDD0D0,live,"own matrix validated runtime consumer body")
    end
    self.own_consumer_profile_mode="raw_dump_exact_or_unknown"
    return self:own_code_match(BASE+0xDD0D0,"\085\083\087\086\131\236\028\137\076\036\016\139\116\036\048\161\000\039\038\066\049\224\137\068\036\024\086\232\112\142\041\000\131\196\004\133\192\015\132\212\002\000\000\137\199\139\000\137\249\255\144\148\000\000\000\137\197\128\184\070\005\000\000\001\184\069\005\000\000\131\216\000\128\124\005\000\000\015\132\172\002\000\000\139\006\137\241\255\080\040\137\195\243\015\016\000\243\015\017\068\036\020\141\068\036\020\080\232\219\155\202\000\131\196\004\102\133\192\015\143\131\002\000\000\243\015\016\067\004\243\015\017\068\036\020\141\068\036\020\080\232\186\155\202\000\131\196\004\102\133\192\015\143\098\002\000\000\243\015\016\067\008\243\015\017\068\036\020\141\068\036\020\080\232\153\155\202\000\131\196\004\102\133\192\015\143\065\002\000\000\243\015\016\003\243\015\017\068\036\020\141\068\036\020\080\232\121\155\202\000\131\196\004\102\131\248\002\015\132\032\002\000\000\243\015\016\067\004\243\015\017\068\036\020\141\068\036\020\080\232\087\155\202\000\131\196\004\102\131\248\002\015\132\254\001\000\000\243\015\016\067\008\243\015\017\068\036\020\141\068\036\020\080\232\053\155\202\000\131\196\004\102\131\248\002\015\132\220\001\000\000\139\006\137\241\255\080\044\137\068\036\012\139\006\137\241\255\080\020\133\192\015\132\194\001\000\000\139\070\004\131\198\004\137\241\255\080\032\133\192\015\132\175\001\000\000\137\198\137\092\036\008\100\161\048\000\000\000\139\136\168\000\000\000\003\136\164\000\000\000\003\136\184\000\000\000\003\136\188\000\000\000\003\072\100\184\116\092\117\062\193\201\032\193\192\022\193\203\032\005\151\205\167\085\053\231\195\161\060\045\162\020\024\044\053\071\148\254\033\144\137\068\036\020\057\076\036\020\116\035\137\232\015\190\244\001\216\102\041\250\192\194\016\102\209\202\102\193\236\002\102\211\228\015\205\049\251\008\210\128\227\062\253\255\226\184\213\066\080\214\053\046\135\153\084\053\195\080\141\011\045\099\002\147\072\193\200\025\045\031\021\046\012\193\200\002\144\144\144\144\137\068\036\020\139\076\036\020\139\001\086\255\144\128\000\000\000\133\192\015\132\252\000\000\000\137\068\036\004\139\157\000\005\000\000\128\187\246\014\000\000\001\184\245\014\000\000\131\216\000\128\060\003\000\139\076\036\016\116\028\139\001\139\081\004\057\208\116\019\199\128\208\030\000\000\000\000\000\000\005\216\030\000\000\057\208\117\237\139\105\004\059\105\008\116\053\104\212\030\000\000\106\000\085\137\092\036\012\137\243\137\206\232\241\251\200\000\131\196\012\199\133\212\030\000\000\000\000\128\063\139\110\004\141\133\216\030\000\000\137\070\004\137\222\139\028\036\235\008\085\232\171\225\000\000\137\197\137\125\000\141\125\004\137\249\232\172\243\127\000\015\183\134\056\001\000\000\137\249\080\232\093\255\127\000\141\133\160\006\000\000\139\076\036\004\139\137\156\000\000\000\193\225\004\141\012\073\081\255\116\036\056\080\232\012\246\200\000\131\196\012\141\133\160\030\000\000\255\116\036\008\255\116\036\016\080\232\021\093\031\000\131\196\012\161\004\202\035\066\015\182\139\236\015\000\000\243\015\016\132\139\228\015\000\000\243\015\088\000\243\015\017\133\208\030\000\000\139\076\036\024\049\225\232\130\168\162\000\131\196\028\094\095\091\093\194\008\000","own matrix consumer body")
  end
  function M:own_consumer_lines()
    local d=self.own_consumer_profile
    if not d then return {"Own consumer profile=not checked; no code mismatch snapshot available"} end
    local lines={string.format("Own consumer checks=%d rejected=%d last_pass_tick=%s; exact raw/runtime layout checks; only runtime rel32 + ModelInfo operands vary after binding validation; all other bytes exact",d.checks,d.rejections,tostring(d.last_pass_tick))}
    lines[#lines+1]="Own consumer profile_mode="..tostring(self.own_consumer_profile_mode).." runtime_binding="..tostring(self.own_runtime_binding_status).." ModelInfo_factory="..tostring(self.own_runtime_interface)
    lines[#lines+1]="Own consumer runtime scope=exact runtime instruction layout; two operands validated (factory ModelInfo and stable executable rel32 target); all other bytes exact; consumer code unchanged; trampoline semantics NOT established"
    if self.own_runtime_target then lines[#lines+1]=string.format("Own consumer runtime target=%08X model_vfunc=%08X target32_stable=true; target snapshot pinned within this script instance",self.own_runtime_target,self.own_runtime_model_fn) end
    if not d.expected then return lines end
    lines[#lines+1]=string.format("Own consumer mismatch stage=%s address=%08X length=%d tick=%s stable=%s differing_bytes=%d first_offset=%s",d.stage,d.address,#d.expected,tostring(d.tick),tostring(d.stable),d.differing,d.first and string.format("+%X",d.first) or "none")
    if not d.actual or #d.actual~=#d.expected then lines[#lines+1]="Own consumer live bytes unavailable or incomplete; own publication stays blocked";return lines end
    local function hex(b)local t={};for i=1,#b do t[#t+1]=string.format("%02X",b:byte(i)) end;return table.concat(t) end
    local rows=0
    for o=0,#d.expected-1,16 do
      local want=d.expected:sub(o+1,o+16);local live=d.actual:sub(o+1,o+16)
      if want~=live then
        rows=rows+1
        lines[#lines+1]=string.format("Own consumer bytes +%03X RVA=%X expected=%s actual=%s",o,d.address-BASE+o,hex(want),hex(live))
      end
    end
    lines[#lines+1]=string.format("Own consumer mismatch rows=%d; complete changed 16-byte rows from latest captured rejection; unchanged rows omitted",rows)
    return lines
  end
local function create_matrix_transform(codec)
  local function finite(x)return type(x)=="number" and x==x and x~=math.huge and x~=-math.huge end
  local function norm(x)return (x+180)%360-180 end
  local function transform(bytes,delta,origin,budget,bone_count)
    if type(bytes)~="string" or #bytes~=0x1800 then return nil,"bank must contain 128 matrix3x4 slots" end
    budget=budget or 15
    if not finite(budget) or budget<0 or budget>60 or not finite(delta) or math.abs(norm(delta))>budget+0.001 then return nil,"rotation outside requested decision budget" end
    if type(origin)~="table" or #origin~=3 then return nil,"origin decoder failed" end
    for i=1,3 do if not finite(origin[i]) or math.abs(origin[i])>1e7 then return nil,"invalid record origin" end end
    bone_count=bone_count or 128
    if not finite(bone_count) or bone_count~=math.floor(bone_count) or bone_count<1 or bone_count>128 then return nil,"invalid active bone count" end
    local used=bone_count*48
    local padding=bytes:sub(used+1)
    if padding~=string.rep("\0",0x1800-used) then return nil,"nonzero inactive matrix padding" end
    local values=codec.decode(bytes:sub(1,used))
    if type(values)~="table" or #values~=bone_count*12 then return nil,"float decoder failed" end
    local angle=math.rad(norm(delta));local c,s=math.cos(angle),math.sin(angle)
    local active=0
    for bone=0,bone_count-1 do
      local o=bone*12;local zero=true
      for k=1,12 do local v=values[o+k];if not finite(v) or math.abs(v)>1e7 then return nil,"nonfinite/out-of-range source matrix" end;if v~=0 then zero=false end end
      if not zero then
        for row=0,2 do local j=o+row*4;local a,b,d=values[j+1],values[j+2],values[j+3];local length=a*a+b*b+d*d
          if length<0.25 or length>4 then return nil,"source matrix row length rejected at slot "..bone end
        end
        active=active+1
        for col=1,3 do local x,y=values[o+col],values[o+4+col];values[o+col]=c*x-s*y;values[o+4+col]=s*x+c*y end
        local x,y=values[o+4]-origin[1],values[o+8]-origin[2]
        values[o+4]=origin[1]+c*x-s*y;values[o+8]=origin[2]+s*x+c*y
      elseif bone==0 then return nil,"first matrix is empty" end
    end
    if active==0 then return nil,"empty bank" end
    local encoded=codec.encode(values)
    if type(encoded)~="string" or #encoded~=used then return nil,"float encoder failed" end
    local verified=codec.decode(encoded)
    if type(verified)~="table" or #verified~=bone_count*12 then return nil,"encoded matrix decoder failed" end
    for i=1,bone_count*12 do if not finite(verified[i]) or math.abs(verified[i])>1e7 then return nil,"encoded matrix invalid" end end
    return encoded..padding,active
  end
  return {transform=transform,norm=norm}
end
  local function own_cache_key(v)
    return table.concat({v.pointer,v.id,v.uid,v.capture_tick,v.sim_bytes,v.variant,string.format("%.17g",v.requested_yaw),string.format("%.17g",v.yaw)},":")
  end
  function M:own_stats()
    if not self.own_matrices then self.own_matrices={allocated=0,created=0,reused=0,failed=0,returned=0,blocks={},records={},capacity=1024,last="not requested"} end
    return self.own_matrices
  end
  function M:matrix_codec()
    if self.io.matrix_codec then return self.io.matrix_codec end
    local f=self.io.ffi
    if not f then return nil,"matrix float codec unavailable" end
    local codec={}
    local decode_buffer,decode_capacity,encode_buffer,encode_capacity
    function codec.decode(bytes)
      if #bytes%4~=0 then return nil end
      local count=#bytes/4
      if not decode_capacity or count>decode_capacity then decode_buffer=f.new("float[?]",count);decode_capacity=count end
      local a=decode_buffer;f.copy(a,bytes,#bytes)
      local values={};for i=0,count-1 do values[i+1]=tonumber(a[i]) end
      return values
    end
    function codec.encode(values)
      if not encode_capacity or #values>encode_capacity then encode_buffer=f.new("float[?]",#values);encode_capacity=#values end
      local a=encode_buffer;for i=1,#values do a[i-1]=values[i] end
      return f.string(a,#values*4)
    end
    self.io.matrix_codec=codec;return codec
  end
  function M:own_block(reason)
    local h=self:own_stats();h.failed=h.failed+1;h.blocks[reason]=(h.blocks[reason] or 0)+1;h.last=reason
    return nil,reason
  end
  function M:own_executable(fn)
    if not fn or fn<65536 then return false end
    local good,q=pcall(self.io.query,self.io,fn)
    if not good or not q or not readable(q,fn,1) then return false end
    local p=(q.protect or 0)%256;return p==0x20 or p==0x40 or p==0x80
  end
  function M:abi_function(role,address)
    if self.abi_fault then return nil,self.abi_fault end
    local f=self.io and self.io.ffi
    if not f or type(f.typeof)~="function"or type(f.cdef)~="function"then return nil,"FFI named-prototype API unavailable"end
    if type(address)~="number"or address~=address or address%1~=0 or address<65536 or address>=4294967296 then return nil,"invalid ABI function address"end
    local cache=self.io.anemone_abi_cache
    if not cache then
      cache={types={},functions={},hits=0,casts=0,definitions=0,prototypes={
        entity_lookup={"anemone_entity_lookup_fn_v45","typedef void* (__thiscall *anemone_entity_lookup_fn_v45)(void*,int);"},
        renderable_model={"anemone_renderable_model_fn_v45","typedef void* (__thiscall *anemone_renderable_model_fn_v45)(void*);"},
        studio_model={"anemone_studio_model_fn_v45","typedef void* (__thiscall *anemone_studio_model_fn_v45)(void*,const void*);"},
        atomic_cas={"anemone_atomic_cas_fn_v45","typedef int (__cdecl *anemone_atomic_cas_fn_v45)(uint32_t*,uint32_t,uint32_t);"}
      }}
      self.io.anemone_abi_cache=cache
    end
    local key=role=="model_by_index"and "entity_lookup"or role
    local prototype=cache.prototypes[key]
    if not prototype then return nil,"unknown ABI function role"end
    local existing=cache.functions[role]
    if existing and existing.address==address then cache.hits=cache.hits+1;return existing.fn end
    local ctype=cache.types[key]
    if not ctype then
      local ok,value=pcall(f.typeof,prototype[1])
      if not ok then
        ok,value=pcall(function()f.cdef(prototype[2]);cache.definitions=cache.definitions+1;return f.typeof(prototype[1])end)
      end
      if not ok then
        self.abi_fault="FFI prototype initialization failed: "..tostring(value):gsub("%c"," "):sub(1,160).."; recreate LuaJIT VM if its type table is exhausted"
        return nil,self.abi_fault
      end
      ctype=value;cache.types[key]=ctype
    end
    local ok,fn=pcall(f.cast,ctype,address)
    if not ok then self.abi_fault="FFI cached-prototype cast failed: "..tostring(fn):gsub("%c"," "):sub(1,160);return nil,self.abi_fault end
    cache.functions[role]={address=address,fn=fn};cache.casts=cache.casts+1
    return fn
  end
  function M:own_native_model(v)
    if not env.entity_list_pointer or not env.sdk_identity then return nil,"native entity/model adapter unavailable"end
    local ok,identity=pcall(env.sdk_identity,v.ent)
    if not ok or type(identity)~="table"or identity.id~=v.id or identity.uid~=v.uid then return nil,"SDK identity changed before native model lookup"end
    self.model_lookup_stats=self.model_lookup_stats or {calls=0,invalid_returns=0,call_errors=0,refreshes=0,changed_interfaces=0,recovered=0}
    local stats=self.model_lookup_stats;stats.calls=stats.calls+1
    local got,list=pcall(self.interface_pointer,self,"entity_list",env.entity_list_pointer)
    if not got or type(list)~="number"or list<65536 then return nil,"VClientEntityList003 unavailable"end
    local f=self.io.ffi
    local function lookup(address)
      local vt=u32(self:read(address,4),0)
      local fn=vt and u32(self:read(vt+12,4),0)or nil
      if not f or not self:own_executable(fn)then return nil,"GetClientEntity ABI/function unavailable",vt,fn end
      local called,result=pcall(function()
        local call,why=self:abi_function("entity_lookup",fn);assert(call,why)
        return tonumber(f.cast("uintptr_t",call(f.cast("void*",address),v.id)))
      end)
      stats.last={id=v.id,uid=v.uid,tick=env.tick(),list=address,vtable=vt,fn=fn,returned=called and result or nil,error=not called and tostring(result):gsub("%c"," "):sub(1,160)or nil}
      if not called then stats.call_errors=stats.call_errors+1;return nil,"GetClientEntity call failed",vt,fn end
      if type(result)~="number"or result~=result or result%1~=0 or result<65536 or result>=4294967296 then stats.invalid_returns=stats.invalid_returns+1;return nil,"GetClientEntity returned invalid pointer",vt,fn end
      if self:read(address,4)~=word(vt)or self:read(vt+12,4)~=word(fn)then return nil,"entity-list vtable changed during lookup",vt,fn end
      return result,nil,vt,fn
    end
    local native,reason=lookup(list)
    if self.abi_fault then return nil,self.abi_fault end
    if not native and env.performance_interfaces then
      local tick=env.tick()
      if type(tick)=="number"and (not stats.last_refresh_tick or tick<stats.last_refresh_tick or tick-stats.last_refresh_tick>=16)then
        stats.last_refresh_tick=tick;stats.refreshes=stats.refreshes+1
        local refreshed,fresh=pcall(self.interface_pointer,self,"entity_list",env.entity_list_pointer,true)
        if refreshed and type(fresh)=="number"and fresh>=65536 and fresh~=list then
          stats.changed_interfaces=stats.changed_interfaces+1
          local same,current=pcall(env.sdk_identity,v.ent)
          if same and type(current)=="table"and current.id==v.id and current.uid==v.uid then
            native,reason=lookup(fresh);if native then stats.recovered=stats.recovered+1 end
          else return nil,"SDK identity changed before refreshed model lookup"end
        end
      end
    end
    if not native then return nil,reason end
    local renderable=native+4
    local rvt=u32(self:read(renderable,4),0)
    local getmodel=rvt and u32(self:read(rvt+0x20,4),0)or nil
    if not self:own_executable(getmodel)then return nil,"IClientRenderable GetModel function unavailable"end
    local readmodel,model=pcall(function()
      local call,why=self:abi_function("renderable_model",getmodel);assert(call,why)
      return tonumber(f.cast("uintptr_t",call(f.cast("void*",renderable))))
    end)
    if not readmodel or not model or model<65536 or not self:read(model,1)then return nil,"IClientRenderable model pointer unavailable"end
    local same,current=pcall(env.sdk_identity,v.ent)
    if not same or type(current)~="table"or current.id~=v.id or current.uid~=v.uid or self:read(renderable,4)~=word(rvt)then return nil,"SDK/renderable changed during model lookup"end
    return model,native
  end
  function M:own_renderable_count(v)
    local model,native=self:own_native_model(v)
    if not model then return nil,native end
    local got,iface=pcall(self.interface_pointer,self,"model_info",env.runtime_model_info_pointer)
    if not got or type(iface)~="number" or iface<65536 then return nil,"ModelInfo interface unavailable for native model" end
    local vt=u32(self:read(iface,4),0)
    local getstudio=vt and u32(self:read(vt+0x80,4),0) or nil
    local f=self.io.ffi
    if not f or not self:own_executable(getstudio) then return nil,"GetStudioModel ABI/function unavailable" end
    local called,studio=pcall(function()
      local call,why=self:abi_function("studio_model",getstudio);assert(call,why)
      return tonumber(f.cast("uintptr_t",call(f.cast("void*",iface),f.cast("const void*",model))))
    end)
    if not called or not studio or studio<65536 then return nil,"native model studio header unavailable" end
    local header=self:read(studio,0xA0)
    if not header or header:sub(1,4)~="IDST" then return nil,"native model studio IDST signature mismatch" end
    local version=u32(header,4);local length=u32(header,0x4C);local count=u32(header,0x9C)
    self.own_studio_probe={address=studio,model=model,native_entity=native,version=version,length=length,bones=count,source="native_renderable",tick=env.tick()}
    if (version~=48 and version~=49) or not length or length<0xA0 or length>0x1000000 then
      return nil,string.format("native studio version/length mismatch: version=%s allowed=48/49 length=%s bones=%s",tostring(version),tostring(length),tostring(count))
    end
    if not count or count<1 or count>128 then return nil,"native studio bone count outside owned 1..128 capacity" end
    local checked,checked_native=self:own_native_model(v)
    if checked~=model or checked_native~=native or self:read(studio,0xA0)~=header then return nil,"native model/studio changed during bone-count read" end
    self.own_last_model={version=version,length=length,index=model,bones=count,studio=studio,native_entity=native,source="IClientRenderable_GetModel"}
    return count,model,studio,native
  end
  function M:own_model_count(v)
    if env.entity_list_pointer then return self:own_renderable_count(v) end
    -- Unit-test fixtures lacking an SDK adapter provide complete 128-slot banks.
    if not env.model_index then return 128,nil,nil end
    local ok,index=pcall(env.model_index,v.ent)
    if not ok or type(index)~="number" or index<1 or index>65535 or index~=math.floor(index) then return nil,"target model index unavailable" end
    local got,iface=pcall(self.interface_pointer,self,"model_info",env.runtime_model_info_pointer)
    if not got or type(iface)~="number" or iface<65536 then return nil,"ModelInfo interface unavailable for bone count" end
    local vt=u32(self:read(iface,4),0)
    local getmodel=vt and u32(self:read(vt+4,4),0) or nil
    local getstudio=vt and u32(self:read(vt+0x80,4),0) or nil
    local function executable(fn)
      if not fn or fn<65536 then return false end
      local good,q=pcall(self.io.query,self.io,fn)
      if not good or not q or not readable(q,fn,1) then return false end
      local p=(q.protect or 0)%256;return p==0x20 or p==0x40 or p==0x80
    end
    if not executable(getmodel) or not executable(getstudio) then return nil,"ModelInfo model/studio vtable functions not executable" end
    local f=self.io.ffi
    if not f then return nil,"ModelInfo native call ABI unavailable" end
    local called,studio=pcall(function()
      local model_fn,model_why=self:abi_function("model_by_index",getmodel);assert(model_fn,model_why)
      local studio_fn,studio_why=self:abi_function("studio_model",getstudio);assert(studio_fn,studio_why)
      local object=f.cast("void*",iface)
      local model=model_fn(object,index)
      local address=tonumber(f.cast("uintptr_t",model))
      if not address or address<65536 or not self:read(address,1) then return nil end
      return tonumber(f.cast("uintptr_t",studio_fn(object,model)))
    end)
    if not called or not studio or studio<65536 then return nil,"target studio header unavailable" end
    local header=self:read(studio,0xA0)
    if not header or header:sub(1,4)~="IDST" then return nil,"studio header IDST signature mismatch" end
    local version=u32(header,4);local length=u32(header,0x4C);local count=u32(header,0x9C)
    self.own_studio_probe={address=studio,model=index,version=version,length=length,bones=count,source="model_index",tick=env.tick()}
    if (version~=48 and version~=49) or not length or length<0xA0 or length>0x1000000 then
      return nil,string.format("studio version/length mismatch: version=%s allowed=48/49 length=%s bones=%s",tostring(version),tostring(length),tostring(count))
    end
    if not count or count<1 or count>128 then return nil,"studio bone count outside owned 1..128 capacity" end
    local again,now=pcall(env.model_index,v.ent)
    if not again or now~=index or self:read(studio,0xA0)~=header then return nil,"target model/studio changed during bone-count read" end
    self.own_last_model={version=version,length=length,index=index,bones=count,studio=studio}
    return count,index,studio
  end
  function M:own_build_impl(v)
    local h=self:own_stats()
    local pinned,profile_reason=self:own_profile();if not pinned then return self:own_block(profile_reason) end
    local codec,why=self:matrix_codec();if not codec then return self:own_block(why) end
    self.matrix_transform=self.matrix_transform or create_matrix_transform(codec)
    local transform=self.matrix_transform
    if type(v.requested_yaw)~="number" or type(v.yaw)~="number" then return self:own_block("candidate yaw missing") end
    local delta=transform.norm(v.requested_yaw-v.yaw)
    if delta~=delta or math.abs(delta)>60.001 then return self:own_block("rotation outside own-matrix 60-degree error budget") end
    local header=self:read(v.pointer,0xd0)
    if not header or u32(header,0x3c)~=v.id or u32(header,0x84)~=v.capture_tick or header:sub(0x95,0x98)~=v.sim_bytes or (v.source_selector~=nil and u32(header,0x8c)~=v.source_selector) then return self:own_block("source record identity changed") end
    local origin=codec.decode(header:sub(1,12))
    local offset=v.variant==1 and 0x30c0 or 0x18c0
    local bones,model_index,studio,native_entity=self:own_model_count(v)
    if not bones then return self:own_block(model_index) end
    local used=bones*48
    local source_primary=self:read(v.pointer+offset,used);local source_alternate=self:read(v.pointer+offset+0x7800,used)
    if not source_primary or not source_alternate then return self:own_block("active matrix bank prefix unreadable") end
    local padding=string.rep("\0",0x1800-used)
    local primary,alternate=source_primary..padding,source_alternate..padding
    h.by_request=h.by_request or {};h.latest_by_target=h.latest_by_target or {};h.registry=h.registry or {}
    local key=own_cache_key(v)
    local function match(old)
      return old and old.bank_yaw==v.yaw and old.bone_count==bones and old.model_index==model_index and old.studio==studio and old.native_entity==native_entity and old.source==v.pointer and old.id==v.id and old.uid==v.uid and old.capture_tick==v.capture_tick and old.sim_bytes==v.sim_bytes and old.variant==v.variant and math.abs(transform.norm(old.requested_yaw-v.requested_yaw))<0.001 and old.source_header==header and old.source_primary==primary and old.source_alternate==alternate
    end
    local old=h.by_request[key] or h.latest_by_target[v.id]
    if not match(old) then
      old=nil
      for i=#h.records,math.max(1,#h.records-127),-1 do if match(h.records[i]) then old=h.records[i];break end end
    end
    if old then
      if self:read(old.primary,0x1800)~=old.encoded_primary or self:read(old.alternate,0x1800)~=old.encoded_alternate then return self:own_block("immutable own bank modified or unreadable") end
      h.latest_by_target[v.id]=old;h.reused=h.reused+1;h.index_reuses=(h.index_reuses or 0)+1;return old
    end
    if h.allocated>=h.capacity then return self:own_block("immutable matrix allocation budget reached; no buffer reuse while native lifetime is unproven") end
    local p,pa=transform.transform(primary,delta,origin,60,bones);if not p then return self:own_block(pa) end
    local a,aa=transform.transform(alternate,delta,origin,60,bones);if not a then return self:own_block(aa) end
    if self:read(v.pointer,0xd0)~=header or self:read(v.pointer+offset,used)~=source_primary or self:read(v.pointer+offset+0x7800,used)~=source_alternate then return self:own_block("source banks changed during construction") end
    local checked,checked_index,checked_studio,checked_native=self:own_model_count(v)
    if checked~=bones or checked_index~=model_index or checked_studio~=studio or checked_native~=native_entity then return self:own_block("target model/bone count changed during construction") end
    local allocated,base=pcall(self.io.allocate,self.io,0x4000,4)
    if not allocated or type(base)~="number" or base<65536 or base+0x4000>4294967296 then return self:own_block("own matrix allocation failed") end
    h.allocated=h.allocated+1
    self:register_rw(base,0x4000)
    local pp,ap=base+0x200,base+0x1a00
    local metadata="ANM1"..word(1)..word(v.id)..word(v.uid)..word(v.capture_tick)..v.sim_bytes..word(v.pointer)..word(v.variant)..word(pp)..word(ap)..word(128)..word(self.generation)..codec.encode({v.requested_yaw,v.yaw,delta,origin[1],origin[2],origin[3]})..word(bones)..word(model_index or 0)
    if not self:write(base,metadata) or not self:write(base+0x80,header) or not self:write(pp,p) or not self:write(ap,a) or self:read(base,#metadata)~=metadata or self:read(pp,0x1800)~=p or self:read(ap,0x1800)~=a then return self:own_block("own snapshot/matrix write readback failed") end
    -- Immutable memory remains allocated even after script unload. No native object ownership is claimed.
    local r={native_entity=native_entity,native_model_source=env.entity_list_pointer~=nil,ent=v.ent,bone_count=bones,model_index=model_index,studio=studio,number=h.created+1,base=base,primary=pp,alternate=ap,source=v.pointer,id=v.id,uid=v.uid,capture_tick=v.capture_tick,sim_bytes=v.sim_bytes,variant=v.variant,requested_yaw=v.requested_yaw,bank_yaw=v.yaw,delta=delta,active_primary_slots=pa,active_alternate_slots=aa,source_header=header,source_primary=primary,source_alternate=alternate,encoded_primary=p,encoded_alternate=a}
    h.by_request[key]=r;h.latest_by_target[v.id]=r;h.registry[base]=r
    h.created=h.created+1;h.records[#h.records+1]=r;h.last=string.format("own snapshot=%d primary=%08X alternate=%08X delta=%.3f bones=%d model=%s",r.number,pp,ap,delta,bones,tostring(model_index))
    return r
  end
  function M:own_build(v)
    local started=self:perf_start()
    local ok,value,reason=pcall(self.own_build_impl,self,v)
    self:perf_finish("own_build",started)
    if not ok then error(value,0) end
    return value,reason
  end
  function M:validate_prepared_own(v,own)
    local h=self:own_stats()
    if not own or not h.registry or h.registry[own.base]~=own then return nil,"prepared bank is not owned by this trace instance" end
    if own.source~=v.pointer or own.id~=v.id or own.uid~=v.uid or own.capture_tick~=v.capture_tick or own.sim_bytes~=v.sim_bytes or own.variant~=v.variant or own.bank_yaw~=v.yaw or math.abs((own.requested_yaw-v.requested_yaw+180)%360-180)>=0.001 then return nil,"prepared bank decision mismatch" end
    local ok,why=self:own_profile();if not ok then return nil,why end
    local bones,model,studio,native=self:own_model_count(v)
    if bones~=own.bone_count or model~=own.model_index or studio~=own.studio or native~=own.native_entity then return nil,"target model changed after preparation" end
    local used=bones*48;local offset=v.variant==1 and 0x30c0 or 0x18c0
    if self:read(v.pointer,0xd0)~=own.source_header or self:read(v.pointer+offset,used)~=own.source_primary:sub(1,used) or self:read(v.pointer+offset+0x7800,used)~=own.source_alternate:sub(1,used) then return nil,"source record/banks changed after preparation" end
    if self:read(own.primary,0x1800)~=own.encoded_primary or self:read(own.alternate,0x1800)~=own.encoded_alternate then return nil,"prepared own bank readback changed" end
    return own
  end
  function M:own_status()
    local h=self:own_stats();local b=self:bridge_stats();local active=0
    for _ in pairs(b.slots)do active=active+1 end
    if b.fault then return "FFI blocked: "..tostring(b.fault).."; session verified returns="..h.returned end
    if h.allocated>=h.capacity then
      return string.format("FFI allocation budget exhausted (%d/%d); new snapshots blocked; session verified returns=%d; active approvals=%d",h.allocated,h.capacity,h.returned,active)
    end
    if h.returned>0 then
      return string.format("FFI native own-pointer returns VERIFIED (session=%d); snapshots=%d; active approvals=%d; allocation=%d/%d; not proof of current target/hitboxes",h.returned,h.created,active,h.allocated,h.capacity)
    end
    if h.created>0 then
      return string.format("FFI own snapshots built=%d; native own-pointer return still pending; active approvals=%d; allocation=%d/%d",h.created,active,h.allocated,h.capacity)
    end
    return "FFI own snapshots not built; last="..tostring(h.last)
  end
  function M:own_lines()
    local h=self:own_stats()
    local lines={string.format("Own matrices allocated=%d/%d snapshots_built=%d reused=%d build_failures=%d verified_returns=%d retained_bytes=%d",h.allocated,h.capacity,h.created,h.reused,h.failed,h.returned,h.allocated*0x4000),
      "Own matrices construction=world-space rigid yaw rotation of selected native banks about matched record origin; experimental own-mode budget=60deg; preserves Z; real studio bone count, zero-padded unused slots; geometric transform NOT proof of server animation/hitboxes",
      "Own records=Anemone immutable snapshot/descriptor ONLY; not inserted into Neverlose record ring, no native constructor/destructor bypass",
      "Own matrices lifetime=16KiB immutable allocation per snapshot, retained to process exit; hard budget 1024 allocations; budget failure blocks own-matrix approval, does NOT silently use borrowed buffers",
      "Own matrices last="..h.last}
    if self.own_last_model then local q=self.own_last_model;lines[#lines+1]=string.format("Own matrices model_key=%08X studio=%08X bone_count=%d capacity=128 unused_slots_zero=%d source=%s native_entity=%s",q.index,q.studio,q.bones,128-q.bones,tostring(q.source or "model_index_GetModel"),tostring(q.native_entity)) end
    if self.own_studio_probe then local q=self.own_studio_probe
      lines[#lines+1]=string.format("Own studio address=%08X version=%s allowed=48/49 length=%s bone_count=%s model_key=%s native_entity=%s source=%s tick=%s",q.address,tostring(q.version),tostring(q.length),tostring(q.bones),tostring(q.model),tostring(q.native_entity),q.source,tostring(q.tick))
    end
    lines[#lines+1]="Own matrices session_status="..self:own_status()
    local keys={};for k in pairs(h.blocks)do keys[#keys+1]=k end;table.sort(keys)
    for _,k in ipairs(keys)do lines[#lines+1]="Own matrices blocked="..k.." attempts="..h.blocks[k] end
    local lookup=self.model_lookup_stats
    if lookup then
      lines[#lines+1]=string.format("Own model lookup calls=%d invalid_returns=%d call_errors=%d factory_refreshes=%d changed_interfaces=%d recovered=%d; refresh on failure at most once/16 SDK ticks; unchanged failed pointer is NEVER retried blindly",lookup.calls,lookup.invalid_returns,lookup.call_errors,lookup.refreshes,lookup.changed_interfaces,lookup.recovered)
      local q=lookup.last
      if q then lines[#lines+1]=string.format("Own model lookup last id=%s UID=%s tick=%s entity_list=%s vtable=%s GetClientEntity=%s returned=%s error=%s; no guessed SDK raw-pointer fallback",tostring(q.id),tostring(q.uid),tostring(q.tick),tostring(q.list),tostring(q.vtable),tostring(q.fn),tostring(q.returned),tostring(q.error))end
    end
    local abi=self.io and self.io.anemone_abi_cache
    if abi then
      local count,bindings=0,0;for _ in pairs(abi.types)do count=count+1 end;for _ in pairs(abi.functions)do bindings=bindings+1 end
      lines[#lines+1]=string.format("FFI ABI cache named_types=%d/4 function_bindings=%d/5 definitions=%d pointer_casts=%d binding_hits=%d fault=%s; NO repeated anonymous function-type parsing; current vtable/executable/SDK identity checks still required",count,bindings,abi.definitions,abi.casts,abi.hits,tostring(self.abi_fault))
    end
    return lines
  end
  function M:delivery_stats()
    if not self.delivery then self.delivery={total=0,retained={},evicted=0,variants={[1]=0,[2]=0},unchanged_args=0,changed_args=0,primary=0,alternate=0,clock_verified=0,clock_unknown=0,clock_mismatch=0,shot_links=0} end
    return self.delivery
  end
  function M:delivery_capture(e)
    if not e.approval_match or not e.bridge_applied or e.site~="context_path_a" then return end
    local h=self:delivery_stats();h.total=h.total+1
    local d=self:bridge_stats().decisions[e.approval_token]
    local q=e.slot_snapshot
    local timing="native_snapshot_unavailable"
    if q and q.status==2 and q.token==e.approval_token and q.pointer==e.pointer and q.id==e.id and q.capture==e.capture_tick and q.sim==e.sim_bits and q.epoch==e.generation then
      timing=(q.native_tick>=d.armed_tick and q.native_tick<=d.expires) and "native_clock_within_approval_window" or "native_snapshot_clock_mismatch"
    end
    if timing=="native_clock_within_approval_window" then h.clock_verified=h.clock_verified+1 elseif timing=="native_snapshot_clock_mismatch" then h.clock_mismatch=h.clock_mismatch+1 else h.clock_unknown=h.clock_unknown+1 end
    local primary=e.own_bank_match and e.own_primary or (not e.own_bank_match and e.offset==(e.variant==1 and 0x30C0 or 0x18C0))
    if primary then h.primary=h.primary+1 else h.alternate=h.alternate+1 end
    if e.original_variant~=e.variant then h.changed_args=h.changed_args+1 else h.unchanged_args=h.unchanged_args+1 end
    h.variants[e.variant]=(h.variants[e.variant] or 0)+1
    local r={number=h.total,seq=e.seq,token=e.approval_token,commit=e.approval_writer_commit,id=e.id,uid=e.approval_uid,pointer=e.pointer,capture_tick=e.capture_tick,sim_bits=e.sim_bits,generation=e.generation,original=e.original_variant,forwarded=e.variant,field8c=e.field8c,offset=e.offset,group=e.group,flags=e.flags,published_tick=e.published_tick,native_tick=q and q.native_tick or nil,armed_tick=d.armed_tick,expires=d.expires,timing=timing,bank_group=primary and "primary" or "alternate",shot_links=0,custom=e.own_bank_match==true,own_snapshot=e.own_snapshot,returned=e.bank,native_return=q and q.native_bank or nil}
    if e.model_attempt then r.attempt=e.model_attempt.number;r.confidence=e.model_attempt.confidence;r.threshold=e.model_attempt.threshold;r.requested_yaw=e.model_attempt.yaw end
    h.retained[#h.retained+1]=r
    if #h.retained>64 then table.remove(h.retained,1);h.evicted=h.evicted+1 end
    e.delivery_receipt=r.number
  end
  function M:delivery_link(e,shot)
    if not e.delivery_receipt or e.approval_uid~=shot.uid then return end
    local h=self:delivery_stats()
    for i=#h.retained,1,-1 do local r=h.retained[i]
      if r.number==e.delivery_receipt and r.seq==e.seq then
        r.shot_links=r.shot_links+1;r.last_shot_id=shot.id;r.last_shot_tick=shot.tick;r.last_shot_uid=shot.uid;h.shot_links=h.shot_links+1
        return
      end
    end
  end
  function M:delivery_lines()
    local h=self:delivery_stats()
    local lines={string.format("Native delivery verified_calls=%d argument_changes=%d same_argument=%d variant1=%d variant2=%d primary=%d alternate=%d retained=%d/64 evicted=%d",h.total,h.changed_args,h.unchanged_args,h.variants[1],h.variants[2],h.primary,h.alternate,#h.retained,h.evicted),
      string.format("Native delivery clock_checked=%d clock_unknown=%d clock_mismatch=%d UID_temporal_shot_links=%d",h.clock_verified,h.clock_unknown,h.clock_mismatch,h.shot_links),
      "Native delivery proof=exact approval token/tuple, changed or preserved call argument, expected native bank return; custom matrices identified per receipt; NO native record-ring insertion; aimpoint consistency and server-hitbox correctness NOT established"}
    for i=math.max(1,#h.retained-15),#h.retained do local r=h.retained[i]
      lines[#lines+1]=string.format("Native delivery receipt=%d seq=%d token=%d commit=%s id=%d SDK_uid=%s record=%08X capture=%d sim=%08X epoch=%d",r.number,r.seq,r.token,tostring(r.commit),r.id,tostring(r.uid),r.pointer,r.capture_tick,r.sim_bits,r.generation)
      lines[#lines+1]=string.format("Native delivery result=%d original=%d forwarded=%d field8C=%d bank_offset=%X bank_group=%s group_arg=%d flags=%08X",r.number,r.original,r.forwarded,r.field8c,r.offset,r.bank_group,r.group,r.flags)
      lines[#lines+1]=string.format("Native delivery own_matrix=%d used=%s snapshot=%s actual_return=%08X original_native_return=%s; actual pointer substitution, not record-ring insertion",r.number,tostring(r.custom),tostring(r.own_snapshot),r.returned,tostring(r.native_return))
      lines[#lines+1]=string.format("Native delivery timing=%d native_tick=%s approval_window=%d..%d status=%s",r.number,tostring(r.native_tick),r.armed_tick,r.expires,r.timing)
      lines[#lines+1]=string.format("Native delivery shot_link=%d links=%d last_shot=%s SDK_uid=%s tick=%s; UID/render-window correlation ONLY",r.number,r.shot_links,tostring(r.last_shot_id),tostring(r.last_shot_uid),tostring(r.last_shot_tick))
    end
    return lines
  end
  function M:attempt_stats()
    if not self.attempt_log then self.attempt_log={total=0,retained=0,capacity=8192,evicted=0,rows={},unmapped=0,unmapped_reasons={},outcomes={},lookup={},context_reasons={}} end
    return self.attempt_log
  end
  function M:attempt_unmapped(reason)
    local h=self:attempt_stats();h.unmapped=h.unmapped+1
    reason=tostring(reason or "no exact record"):gsub("%c"," "):sub(1,160)
    h.unmapped_reasons[reason]=(h.unmapped_reasons[reason] or 0)+1
  end
  function M:attempt_begin(r,yaw,confidence,state,detail,threshold,geometry)
    if not r or not r.pointer or not r.capture_tick or not r.header_bytes then self:attempt_unmapped("attempt without exact native snapshot");return nil end
    local h=self:attempt_stats();h.total=h.total+1
    local seq=self:counter()
    local a={number=h.total,pointer=r.pointer,id=r.id,uid=r.uid,capture_tick=r.capture_tick,sim_bits=u32(r.header_bytes,0x94),reader_epoch=r.epoch,generation=self.generation,begin_seq=seq,tick=env.tick(),yaw=yaw,confidence=confidence,threshold=threshold or 0.60,state=tostring(state),source=detail and tostring(detail.source or "unspecified") or "unspecified",stage="started"}
    if geometry then
      a.geometry={valid=geometry.valid==true,requested=geometry.requested,eye_proxy=geometry.eye_proxy,variant1_yaw=geometry.variant1_yaw,variant2_yaw=geometry.variant2_yaw,error1=geometry.error1,error2=geometry.error2,gap=geometry.gap,eye_error=geometry.eye_error,nearest_variant=geometry.nearest_variant,nearest_error=geometry.nearest_error,eye_proxy_closer=geometry.eye_proxy_closer==true,flags=geometry.flags}
    end
    local slot=(a.number-1)%h.capacity+1
    h.exact=h.exact or {}
    local gone=h.rows[slot]
    if gone then
      h.evicted=h.evicted+1
      if gone.exact_key and h.exact[gone.exact_key]==gone.number then h.exact[gone.exact_key]=nil end
    else h.retained=h.retained+1 end
    a.exact_key=tuple_key(a);a.previous_exact=h.exact[a.exact_key]
    h.exact[a.exact_key]=a.number;h.rows[slot]=a
    return a.number
  end
  function M:attempt_finish(number,stage,reason,variant)
    if not number then self:attempt_unmapped(reason);return end
    local h=self:attempt_stats();local a=h.rows[(number-1)%h.capacity+1]
    if not a or a.number~=number then return end
    a.stage=tostring(stage);a.reason=tostring(reason or ""):gsub("%c"," "):sub(1,160);a.variant=variant;a.finish_seq=self:counter();a.finish_tick=env.tick()
    h.outcomes[a.stage]=(h.outcomes[a.stage] or 0)+1
  end
  function M:attempt_lookup(e)
    local h=self:attempt_stats();local timing_unknown,later
    local function inspect(a)
      if a and a.pointer==e.pointer and a.id==e.id and a.capture_tick==e.capture_tick and a.sim_bits==e.sim_bits and a.generation==e.generation then
        if a.finish_seq and a.finish_seq<e.seq and a.stage~="started" then return a end
        if not a.finish_seq or not a.begin_seq then timing_unknown=true else later=true end
      end
    end
    if h.exact then
      local n=h.exact[tuple_key(e)]
      local floor=math.max(1,h.total-h.capacity+1)
      while n and n>=floor do
        local a=h.rows[(n-1)%h.capacity+1]
        if not a or a.number~=n then break end
        h.lookup_steps=(h.lookup_steps or 0)+1
        local match=inspect(a);if match then return match,"exact_prior_attempt" end
        n=a.previous_exact
      end
    else
      -- Older retained/fixture journals have no index; retain their exact matching behavior.
      for n=h.total,math.max(1,h.total-h.capacity+1),-1 do
        local a=h.rows[(n-1)%h.capacity+1]
        if a and a.number==n then local match=inspect(a);if match then return match,"exact_prior_attempt" end end
      end
    end
    return nil,timing_unknown and "exact_attempt_order_unknown" or (later and "exact_attempt_not_proven_before_call" or "no_exact_attempt_in_retained_history")
  end

  function M:attempt_lines()
    local h=self:attempt_stats()
    local lines={string.format("Native attempt journal total=%d retained=%d/%d evicted=%d unmapped=%d; scalar copies ONLY, no live handles",h.total,h.retained,h.capacity,h.evicted,h.unmapped),
      "FFI perf attempt_lookup=exact tuple index; history capacity unchanged; examined_exact_rows="..tostring(h.lookup_steps or 0),
      "Native attempt matching=pointer/index/capture/simulation/trace epoch; only finish producer_seq < call seq qualifies as prior; UID belongs to sampled SDK decision, not read from native context",
      "Native attempt absence=not found in retained exact history; does NOT prove never processed if history evicted, mapping failed, or trace was disabled"}
    for _,map in ipairs({{name="outcome",data=h.outcomes},{name="unmapped",data=h.unmapped_reasons},{name="context_lookup",data=h.lookup},{name="context_reason",data=h.context_reasons}})do
      local keys={};for k in pairs(map.data)do keys[#keys+1]=k end;table.sort(keys)
      for _,k in ipairs(keys)do lines[#lines+1]="Native attempt "..map.name.."="..k.." events="..map.data[k] end
    end
    local pool=self.context_recent or {}
    for i=math.max(1,#pool-11),#pool do local e=pool[i];local a=e.model_attempt
      lines[#lines+1]=string.format("Native attempt context seq=%d id=%d record=%08X capture=%d lookup=%s earlier_approval=%s",e.seq,e.id,e.pointer,e.capture_tick,tostring(e.attempt_lookup),tostring(e.earlier_approval_token))
      if a then
        lines[#lines+1]=string.format("Native attempt matched seq=%d attempt=%d SDK_uid=%s stage=%s variant=%s confidence=%s threshold=%s yaw=%s source=%s",e.seq,a.number,tostring(a.uid),a.stage,tostring(a.variant),tostring(a.confidence),tostring(a.threshold),tostring(a.yaw),a.source)
        lines[#lines+1]=string.format("Native attempt result seq=%d finish_seq=%s finish_tick=%s reason=%s",e.seq,tostring(a.finish_seq),tostring(a.finish_tick),a.reason)
        local g=a.geometry
        if g and g.valid then
          lines[#lines+1]=string.format("Native attempt geometry seq=%d requested=%.3f yaw1=%.3f yaw2=%.3f error1=%.3f error2=%.3f gap=%.3f nearest=%d error=%.3f",e.seq,g.requested,g.variant1_yaw,g.variant2_yaw,g.error1,g.error2,g.gap,g.nearest_variant,g.nearest_error)
          lines[#lines+1]=string.format("Native attempt eye_proxy seq=%d yaw=%.3f error=%.3f closer_than_alternatives=%s; eye yaw is NOT verified center-bank matrix yaw",e.seq,g.eye_proxy,g.eye_error,tostring(g.eye_proxy_closer))
        end
      end
    end
    return lines
  end
  function M:bridge_stats()
    if not self.bridge then self.bridge={arms=0,refreshes=0,disarms=0,guarded=0,changed=0,bank_ok=0,blocks={},slots={},decisions={},decision_order={},approval_counter=0,evictions=0,expired=0,retained_after_restore=0,clears=0,last="OFF",fault=nil} end
    return self.bridge
  end
  function M:bridge_atomic(a,expected,replacement)
    if not self.data or a<self.data or a+4>self.data+0x8000 or a%4~=0 then return false,"bridge control outside allocation" end
    if self:read(self.code+2048,#CAS)~=CAS then return false,"atomic helper changed" end
    local fn=self.io.atomic_data or self.io.atomic
    local ok,value,why=pcall(fn,self.io,a,expected,replacement)
    return ok and value==true,why or (not ok and tostring(value) or nil)
  end
  function M:bridge_control(on)
    if not self.data then return not on end
    local actual=u32(self:read(self.data+28,4),0)
    if actual==nil then return false end
    local target=on and 1 or 0
    if actual==target then return true end
    return self:bridge_atomic(self.data+28,actual,target)
  end
  function M:bridge_fail(reason)
    local b=self:bridge_stats();b.fault=tostring(reason):gsub("%c"," "):sub(1,160);b.last="BLOCKED: "..b.fault
    self:bridge_control(false)
  end
  function M:bridge_block(reason)
    local b=self:bridge_stats();b.blocks[reason]=(b.blocks[reason] or 0)+1;b.last=reason
    return false
  end
  function M:bridge_clock()
    local ptr=u32(self:read(0x4223F428,4),0)
    local b=self:bridge_stats();b.clock_pointer=ptr;b.clock_native_tick=nil;b.clock_sdk_tick=env.tick()
    if not ptr or ptr<65536 or ptr>0xFFFFFF00 or ptr%4~=0 then return nil end
    local tick=u32(self:read(ptr+0x16C,4),0);b.clock_native_tick=tick
    if not tick or tick>0xFFFFFFDF or math.abs(tick-env.tick())>2 then return nil end
    return tick,ptr
  end
  function M:bridge_publish(bucket,body)
    local a=self.data+0x2100+bucket*64
    local old=u32(self:read(a,4),0)
    if not old or old%2~=0 or old>0xFFFFFFFC then return false,"approval slot version unavailable/odd/exhausted" end
    local ok,why=self:bridge_atomic(a,old,old+1);if not ok then return false,why end
    if not self:write(a+4,body) or self:read(a+4,60)~=body then return false,"approval slot body readback failed" end
    return self:bridge_atomic(a,old+1,old+2)
  end
  function M:bridge_disarm_bucket(bucket,reason)
    local b=self:bridge_stats();if not b.slots[bucket] then return true end
    local ok,why=self:bridge_publish(bucket,string.rep("\0",60))
    if not ok then self:bridge_fail(why or "approval disarm failed");return false end
    b.slots[bucket].retired_reason=reason or "unspecified";b.slots[bucket].retired_tick=env.tick();b.slots[bucket]=nil;b.disarms=b.disarms+1
    return true
  end
  function M:bridge_clear(reason)
    self:clear_transfer_pipeline(reason or "bridge cleared")
    local b=self:bridge_stats()
    if self.data and not self:bridge_control(false) then self:bridge_fail("bridge disable before cache clear failed");return end
    local had=next(b.slots)~=nil
    for bucket in pairs(b.slots)do if not self:bridge_disarm_bucket(bucket,reason) then return end end
    if had and self.running then
      local current=u32(self:read(self.data+20,4),0)
      if not current or current>=0xFFFFFFFE or not self:bridge_atomic(self.data+20,current,current+1) then self:bridge_fail("trace epoch invalidation failed");return end
      self.generation=current+1
    end
    if had then b.clears=b.clears+1 end
    b.last=reason or "approval cache cleared"
  end
  function M:bridge_arm(v,commit,refresh,prepared)
    local b=self:bridge_stats()
    if not self.running or not env.bridge_enabled or not env.bridge_enabled() then return false end
    if b.fault then return self:bridge_block("bridge fault latched; reload required") end
    if not commit or (v.variant~=1 and v.variant~=2) or not v.id or v.id<1 or v.id>64 then return self:bridge_block("approved owned decision unavailable") end
    local tick,ptr=self:bridge_clock()
    if not tick then return self:bridge_block("native clock pointer/tick not validated against SDK") end
    if tick<v.capture_tick or tick>v.capture_tick+32 then return self:bridge_block("record outside fixed 32-tick approval window") end
    local custom_mode=env.own_matrix_enabled and env.own_matrix_enabled()
    if not custom_mode and u32(self:read(v.pointer+0x8C,4),0)~=v.variant then return self:bridge_block("record selector no longer matches fresh owned decision") end
    local tuple=self:read(v.pointer,0x98)
    if not tuple or tuple:sub(0x95,0x98)~=v.sim_bytes or u32(tuple,0x84)~=v.capture_tick or u32(tuple,0x3C)~=v.id then return self:bridge_block("native tuple changed before approval") end
    local current=u32(self:read(self.data+32,4),0)
    if current~=ptr then
      if current and current~=0 then self:bridge_clear("native clock pointer changed") end
      if not self:bridge_control(false) or not self:write(self.data+32,word(ptr)) or u32(self:read(self.data+32,4),0)~=ptr then self:bridge_fail("native clock pointer publication failed");return false end
    end
    if b.approval_counter>=0x00FFFFFE then return self:bridge_block("approval token exhausted; reload required") end
    local token=b.approval_counter+1
    local bucket=approval_bucket(v.id,v.capture_tick)
    local own
    if env.own_matrix_enabled and env.own_matrix_enabled() then
      local why
      if prepared then own,why=self:validate_prepared_own(v,prepared) else own,why=self:own_build(v) end
      if not own then self:bridge_invalidate_record(v,"own matrix rebuild rejected");return self:bridge_block("own matrices not published: "..tostring(why)) end
    end
    local body=word(v.pointer)..word(v.id)..word(v.capture_tick)..v.sim_bytes..word(v.variant)..word(tick)..word(v.capture_tick+32)..word(1)..word(v.uid)..word(token)..word(self.generation)..word(own and own.primary or 0)..word(own and own.alternate or 0)..word(own and 1 or 0)..word(own and 128 or 0)
    local ok,why=self:bridge_publish(bucket,body)
    if not ok then self:bridge_fail(why or "approval publication failed");return false end
    local old=b.slots[bucket]
    if old and (old.pointer~=v.pointer or old.capture_tick~=v.capture_tick or old.id~=v.id or old.sim_bytes~=v.sim_bytes) then old.retired_reason="hash collision";old.retired_tick=tick;b.evictions=b.evictions+1 end
    local d={token=token,id=v.id,pointer=v.pointer,uid=v.uid,capture_tick=v.capture_tick,sim_bytes=v.sim_bytes,sim_bits=u32(v.sim_bytes,0),variant=v.variant,commit=commit,armed_tick=tick,expires=v.capture_tick+32,generation=self.generation,own=own,feedback={bucket=v.feedback_bucket,base=v.feedback_base,observer_generation=v.feedback_generation,observer_revision=v.feedback_revision,epoch=v.feedback_epoch,state=v.state,yaw=v.requested_yaw,sdk_sim=v.sdk_sim}}
    b.approval_counter=token;b.slots[bucket]=d;b.decisions[token]=d;b.decision_order[#b.decision_order+1]=token
    b.exact_decisions=b.exact_decisions or {};d.exact_key=tuple_key(d);b.exact_decisions[d.exact_key]=token
    if #b.decision_order>256 then
      local gone=table.remove(b.decision_order,1);local old=b.decisions[gone]
      if old and old.exact_key and b.exact_decisions[old.exact_key]==gone then b.exact_decisions[old.exact_key]=nil end
      b.decisions[gone]=nil
    end
    if not self:bridge_control(true) then self:bridge_fail("bridge master enable failed");return false end
    if refresh then b.refreshes=b.refreshes+1 else b.arms=b.arms+1 end
    b.last=string.format("approved id=%d capture=%d token=%d writer_commit=%d variant=%d expires=%d",v.id,v.capture_tick,token,commit,v.variant,d.expires)
    return true
  end
  function M:bridge_refresh(v)
    for i=#self.intervals,1,-1 do local w=self.intervals[i]
      if not w.closed and w.pointer==v.pointer and w.uid==v.uid and w.capture_tick==v.capture_tick and w.variant==v.variant then return self:bridge_arm(v,w.number,true) end
    end
  end
  function M:pipeline_stats()
    if not self.transfer_pipeline then self.transfer_pipeline={candidates={},ready={},epoch=1,serial=0,queued=0,coalesced=0,prepared=0,published=0,rejected=0,cancelled=0,errors=0,priority_first=0,last="idle"} end
    return self.transfer_pipeline
  end
  function M:pipeline_result(job,ok,reason,revoke)
    local p=self:pipeline_stats();p.last=tostring(reason or "unknown"):gsub("%c"," "):sub(1,180)
    if ok then p.published=p.published+1 else p.rejected=p.rejected+1 end
    if job.v.selector_attempt then self:attempt_finish(job.v.selector_attempt,ok and "own_matrix_approved_no_field_write" or "own_pipeline_rejected",p.last,job.v.variant) end
    if env.transfer_complete then
      local good=pcall(env.transfer_complete,job.v,ok,p.last)
      if not good then p.errors=p.errors+1 end
    end
    if not ok and revoke then self:bridge_invalidate_record(job.v,"staged decision rejected: "..p.last) end
  end
  function M:clear_transfer_pipeline(reason)
    local p=self:pipeline_stats();local candidates,ready=p.candidates,p.ready
    p.epoch=p.epoch+1
    if not next(candidates)and not next(ready)then p.empty_clears=(p.empty_clears or 0)+1;return end
    p.candidates={};p.ready={}
    for _,jobs in ipairs({candidates,ready})do for _,job in pairs(jobs)do
      p.cancelled=p.cancelled+1;self:pipeline_result(job,false,reason or "pipeline cleared",false)
    end end
  end
  function M:cancel_transfer_uid(uid,reason)
    local p=self:pipeline_stats()
    for _,jobs in ipairs({p.candidates,p.ready})do
      for id,job in pairs(jobs)do if job.v.uid==uid then jobs[id]=nil;p.cancelled=p.cancelled+1;self:pipeline_result(job,false,reason or "identity departed",false) end end
    end
  end
  function M:transfer_valid(job,member)
    local p=self:pipeline_stats();local v=job.v
    if not env.transfer_pipeline or not env.transfer_pipeline() or not self.running or self.fault or self:bridge_stats().fault or not env.live() or not env.bridge_enabled or not env.bridge_enabled() or not env.own_matrix_enabled or not env.own_matrix_enabled() then return false,"pipeline context/mode inactive" end
    if job.epoch~=p.epoch or job.generation~=self.generation then return false,"pipeline/trace epoch changed" end
    local tick=env.tick()
    if type(tick)~="number" or tick~=tick or type(v.tick)~="number" or v.tick~=v.tick or tick<v.tick or tick-v.tick>2 then return false,"prepared request older than two SDK ticks or clock reversed" end
    if not env.transfer_context then return false,"staged SDK context adapter unavailable" end
    local good,c=pcall(env.transfer_context,v.ent)
    if not good or type(c)~="table" or c.id~=v.id or c.uid~=v.uid or c.sim~=v.sdk_sim or c.x~=v.sdk_x or c.y~=v.sdk_y or c.z~=v.sdk_z or c.duck~=v.sdk_duck then return false,"staged SDK identity/simulation/position/duck changed" end
    for _,k in ipairs({"sdk_flags","sdk_vx","sdk_vy","sdk_vz"})do if v[k]~=nil and c[k]~=v[k]then return false,"staged SDK flags/velocity changed"end end
    if member then
      if not env.transfer_member then return false,"staged ring membership adapter unavailable" end
      local ok,header,reason=pcall(env.transfer_member,v)
      if not ok or type(header)~="string" then return false,"staged ring membership rejected: "..tostring(ok and reason or header) end
      if job.own and header~=job.own.source_header then return false,"native header changed after preparation" end
    end
    return true
  end
  function M:queue_own_transfer(v,commit,refresh)
    if not env.transfer_pipeline or not env.transfer_pipeline() then return self:approve_existing_selector(v) end
    local p=self:pipeline_stats()
    if type(v)~="table" or type(v.id)~="number" or v.id<1 or v.id>64 or v.id~=math.floor(v.id) then return false,"invalid staged target" end
    local copy={};for k,value in pairs(v)do if type(value)~="table" then copy[k]=value end end
    copy.ent=v.ent
    local job={v=copy,commit=commit,refresh=refresh,epoch=p.epoch,generation=self.generation,serial=p.serial+1}
    local ok,why=self:transfer_valid(job,false)
    if not ok then self:pipeline_result(job,false,why,true);return false,why end
    local old=p.candidates[v.id]
    if old then p.coalesced=p.coalesced+1;self:pipeline_result(old,false,"newer candidate superseded queued preparation",false) end
    p.serial=job.serial;p.candidates[v.id]=job;p.queued=p.queued+1;p.last="candidate queued; no matrix allocation or pointer publication yet"
    return true,p.last
  end
  function M:ordered_transfer_ids(jobs)
    local ids={};for id in pairs(jobs)do ids[#ids+1]=id end
    local priority
    if env.priority_target then local ok,id=pcall(env.priority_target);if ok then priority=id end end
    table.sort(ids,function(a,b)if a==priority then return b~=priority end;if b==priority then return false end;return a<b end)
    if ids[1] and ids[1]==priority then local p=self:pipeline_stats();p.priority_first=p.priority_first+1 end
    return ids
  end
  function M:prepare_transfers(only_id)
    local p=self:pipeline_stats()
    if not next(p.candidates)then return end
    local jobs=p.candidates
    if only_id~=nil then
      if not jobs[only_id]then return end
      local selected=jobs[only_id];jobs[only_id]=nil;jobs={[only_id]=selected}
    else p.candidates={}end
    for _,id in ipairs(self:ordered_transfer_ids(jobs))do
      local job=jobs[id]
      local good,why=self:transfer_valid(job,false)
      if good then
        local ok,own,reason=pcall(self.own_build,self,job.v)
        if ok and own then job.own=own;p.ready[id]=job;p.prepared=p.prepared+1
        else p.errors=p.errors+(ok and 0 or 1);self:pipeline_result(job,false,tostring(reason or own or "own preparation failed"),true) end
      else self:pipeline_result(job,false,why,true) end
    end
  end
  function M:publish_transfers(only_id)
    local p=self:pipeline_stats()
    if not next(p.ready)then return end
    local jobs=p.ready
    if only_id~=nil then
      if not jobs[only_id]then return end
      local selected=jobs[only_id];jobs[only_id]=nil;jobs={[only_id]=selected}
    else p.ready={}end
    for _,id in ipairs(self:ordered_transfer_ids(jobs))do
      local job=jobs[id]
      local good,why=self:transfer_valid(job,true)
      if good then
        local ok,published,reason=pcall(self.bridge_arm,self,job.v,job.commit,job.refresh,job.own)
        if ok and published then self:pipeline_result(job,true,"prepared matrices published; native field8C unchanged; consumer return not yet observed",false)
        else p.errors=p.errors+(ok and 0 or 1);self:pipeline_result(job,false,tostring(reason or self:bridge_stats().last or published),true) end
      else self:pipeline_result(job,false,why,true) end
    end
  end
  function M:pipeline_lines()
    local p=self:pipeline_stats();local candidates,ready=0,0
    for _ in pairs(p.candidates)do candidates=candidates+1 end;for _ in pairs(p.ready)do ready=ready+1 end
    return {"FFI pipeline stages=network observations -> exact candidate queue -> own-bank preparation -> guarded pointer publication -> diagnostics; sequential Lua stages, NOT worker threads or extra native hooks",
      string.format("FFI pipeline queued=%d coalesced=%d prepared=%d published=%d rejected=%d cancelled=%d errors=%d candidates=%d ready=%d epoch=%d",p.queued,p.coalesced,p.prepared,p.published,p.rejected,p.cancelled,p.errors,candidates,ready,p.epoch),
      "FFI pipeline priority_first="..p.priority_first.."; all queued targets drain in the same render; no new per-frame cap or reduced update cadence; exact SDK sample <=2 ticks and active ring rechecked before publication",
      "FFI pipeline last="..p.last.."; published count is NOT verified native consumption or hit rate"}
  end

  function M:approve_existing_selector(v)
    if not env.own_matrix_enabled or not env.own_matrix_enabled() then return false,"own-matrix mode inactive" end
    local ok=self:bridge_arm(v,0,false)
    return ok,self:bridge_stats().last
  end
  function M:bridge_release(v,reason)
    local b=self:bridge_stats()
    local bucket=approval_bucket(v.id,v.capture_tick);local d=b.slots[bucket]
    if d and d.pointer==v.pointer and d.uid==v.uid and d.capture_tick==v.capture_tick then
      if reason=="restored" then b.retained_after_restore=b.retained_after_restore+1;return end
      self:bridge_disarm_bucket(bucket,reason)
    end
  end
  function M:bridge_has_target(id,uid)
    for _,d in pairs(self:bridge_stats().slots)do if d.id==id and d.uid==uid then return true end end
    return false
  end
  function M:bridge_invalidate_record(r,reason)
    if not r or not r.id or not r.capture_tick then return end
    local b=self:bridge_stats();local bucket=approval_bucket(r.id,r.capture_tick);local d=b.slots[bucket]
    local sim_bits=r.sim_bytes and u32(r.sim_bytes,0) or u32(r.header_bytes,0x94)
    if d and d.pointer==r.pointer and d.uid==r.uid and d.sim_bits==sim_bits then self:bridge_disarm_bucket(bucket,reason or "new model abstention for same record") end
  end
  function M:bridge_off()
    self:bridge_clear("OFF; approved slots invalidated")
  end
  function M:bridge_sync()
    local b=self:bridge_stats()
    if not self.running or b.fault or not env.bridge_enabled or not env.bridge_enabled() then self:bridge_off();return end
    local tick,ptr=self:bridge_clock()
    if not tick then self:bridge_clear("native clock validation lost");return end
    if b.last_native_tick and tick<b.last_native_tick then self:bridge_clear("native clock moved backward") end
    if self.data and u32(self:read(self.data+32,4),0)~=ptr and next(b.slots) then self:bridge_clear("native clock pointer changed") end
    b.last_native_tick=tick
    local model_checks={}
    for bucket,d in pairs(b.slots)do
      if tick>d.expires or tick<d.armed_tick then
        if self:bridge_disarm_bucket(bucket,"approval age expired") then b.expired=b.expired+1 end
      elseif d.own and d.own.native_model_source then
        local q=model_checks[d.id]
        if not q or q.uid~=d.uid then
          local ok,model,native=pcall(self.own_native_model,self,{id=d.id,uid=d.uid,ent=d.own.ent})
          q={uid=d.uid,ok=ok,model=model,native=native};model_checks[d.id]=q
        end
        if not q.ok or q.model~=d.own.model_index or q.native~=d.own.native_entity then self:bridge_disarm_bucket(bucket,"SDK/native model changed after own-bank construction") end
      elseif d.own and d.own.model_index and env.model_index then
        local ok,index=pcall(env.model_index,d.own.ent)
        if not ok or index~=d.own.model_index then self:bridge_disarm_bucket(bucket,"SDK model changed after own-bank construction") end
      end
    end
  end
  function M:bridge_departure(event)
    local ok,uid=pcall(function()return tonumber(event.userid)end)
    if not ok or not uid then return end
    self:cancel_transfer_uid(uid,"SDK death/disconnect")
    local b=self:bridge_stats()
    for bucket,d in pairs(b.slots)do if d.uid==uid then self:bridge_disarm_bucket(bucket,"SDK death/disconnect") end end
  end
  function M:bridge_lines()
    local b=self:bridge_stats();local stored=0;for _ in pairs(b.slots)do stored=stored+1 end
    local lines={string.format("Native bridge requested=%s control=%s arms=%d refreshes=%d disarms=%d stored_approvals=%d/128 guarded_calls=%d arg_changes=%d returned_bank_ok=%d fault=%s",tostring(env.bridge_enabled and env.bridge_enabled() or false),tostring(self.data and u32(self:read(self.data+28,4),0) or 0),b.arms,b.refreshes,b.disarms,stored,b.guarded,b.changed,b.bank_ok,tostring(b.fault)),
      string.format("Native bridge approval_cache token=%d retained_after_field_restore=%d evictions=%d expired=%d clears=%d attributed_calls=%d attribution_missed=%d",b.approval_counter,b.retained_after_restore,b.evictions,b.expired,b.clears,b.attributed or 0,b.attribution_missed or 0),
      "Native bridge scope=context_path_a ONLY; per-record decisions computed when SDK/native snapshot matched; restored field8C does NOT revoke its earlier decision; current yaw is NEVER applied to an unknown historical record",
      "Native bridge cache=128 direct-mapped slots; hash=(capture_tick+17*entity_index)%128; collisions lose older approvals, never relax full tuple matching; fixed expiry=capture_tick+32 native ticks, NOT extended by refresh",
      "Native bridge guards=pointer/index/capture-tick/sim-bits/trace epoch; group0; flags20 and not flag4; native clock pointer unchanged; decision native tick..fixed expiry; stable even slot version; nonzero 24-bit approval token",
      "Native bridge invalidation=same-record model abstention, SDK death/disconnect/model change, reader/round reset, disabled bridge/trace, invalid clock; native lagcomp/record-validity checks remain untouched",
      "Native bridge proof=actual original/forwarded arg and bank return plus machine-logged approval token; UID validated at decision time only; aim_fire correlation and server-hitbox/aimpoint consistency remain unverified",
      "Native bridge last="..b.last}
    lines[#lines+1]=string.format("Native bridge clock pointer=%s native_tick=%s SDK_tick=%s alignment_tolerance=2",tostring(b.clock_pointer),tostring(b.clock_native_tick),tostring(b.clock_sdk_tick))
    local names={};for reason in pairs(b.blocks)do names[#names+1]=reason end;table.sort(names)
    for _,reason in ipairs(names)do lines[#lines+1]="Native bridge publication blocked="..reason.." attempts="..b.blocks[reason] end
    local reasons={[2]="native_group_not_zero",[3]="native_flags_rejected",[4]="index_out_of_range",[5]="approval_slot_inactive",[6]="record_pointer_mismatch",[7]="record_index_mismatch",[8]="capture_tick_mismatch",[9]="simulation_bits_mismatch",[10]="trace_epoch_mismatch",[11]="native_clock_pointer_changed",[12]="fixed_record_age_expired_or_before_decision",[13]="variant_not_1_or_2",[14]="unused_legacy_owned_field_guard",[15]="slot_version_changed",[16]="bridge_disabled_during_guard",[17]="approval_token_invalid",[18]="approval_slot_version_odd",[20]="own_matrix_pointer_or_capacity_invalid"}
    for i=2,20 do if (b.rejected or {})[i] then lines[#lines+1]="Native bridge native_guard_reject="..tostring(reasons[i] or "own_matrix_return").." events="..b.rejected[i] end end
    lines[#lines+1]=string.format("Native bridge coverage retained_decisions=%d/256 snapshot_missing=%d; absent history is NOT proof a record was never approved",#b.decision_order,b.snapshot_missing or 0)
    local names={};for reason in pairs(b.coverage or {})do names[#names+1]=reason end;table.sort(names)
    for _,reason in ipairs(names)do lines[#lines+1]="Native bridge coverage="..reason.." context_calls="..b.coverage[reason] end
    local pool=self.context_recent or {}
    for i=math.max(1,#pool-7),#pool do local e=pool[i];local q=e.slot_snapshot
      lines[#lines+1]=string.format("Native bridge cache_probe seq=%d id=%d record=%08X capture=%d bucket=%d reason=%d coverage=%s earlier_token=%s retired=%s",e.seq,e.id,e.pointer,e.capture_tick,e.approval_bucket or -1,e.bridge_reason,tostring(e.approval_coverage),tostring(e.earlier_approval_token),tostring(e.approval_retired_reason))
      if q then lines[#lines+1]=string.format("Native bridge machine_slot seq=%d status=%d bucket=%d version=%d active=%d record=%08X id=%d capture=%d sim=%08X token=%d epoch=%d native_tick=%d",e.seq,q.status,q.bucket,q.version,q.active,q.pointer,q.id,q.capture,q.sim,q.token,q.epoch,q.native_tick) end
    end
    for _,line in ipairs(self:attempt_lines())do lines[#lines+1]=line end
    for _,line in ipairs(self:delivery_lines())do lines[#lines+1]=line end
    for _,line in ipairs(self:own_lines())do lines[#lines+1]=line end
    for _,line in ipairs(self:own_consumer_lines())do lines[#lines+1]=line end
    return lines
  end
  function M:commit(v)
    if not self.running then return false,"trace inactive" end
    self.commit_attempts=(self.commit_attempts or 0)+1
    local seq,_,generation=self:counter();if not seq then self.commit_marker_missed=(self.commit_marker_missed or 0)+1;return end
    for _,w in ipairs(self.intervals) do
      if not w.closed and w.pointer==v.pointer and w.id==v.id and w.uid==v.uid and w.capture_tick==v.capture_tick then w.closed=true;w.end_seq=seq;w.end_reason="next commit" end
    end
    self.commit_counter=self.commit_counter+1
    local w={number=self.commit_counter,pointer=v.pointer,id=v.id,uid=v.uid,capture_tick=v.capture_tick,sim_bits=u32(v.sim_bytes,0),variant=v.variant,begin_seq=seq,generation=generation}
    self.intervals[#self.intervals+1]=w
    local published=self:bridge_arm(v,w.number,false)
    if #self.intervals>256 then table.remove(self.intervals,1) end
    return published,self:bridge_stats().last
  end
  function M:release(v,reason)
    self:bridge_release(v,reason)
    local seq=self:counter()
    if not seq then self.release_marker_missed=(self.release_marker_missed or 0)+1 end
    for i=#self.intervals,1,-1 do local w=self.intervals[i]
      if not w.closed and w.pointer==v.pointer and w.id==v.id and w.uid==v.uid and w.capture_tick==v.capture_tick then w.closed=true;w.end_seq=seq or w.begin_seq;w.end_reason=reason end
    end
  end
  function M:decode(row)
    local e={seq=u32(row,0),caller=u32(row,4),pointer=u32(row,8),id=u32(row,12),capture_tick=u32(row,16),sim_bits=u32(row,20),variant=u32(row,24),group=u32(row,28),flags=u32(row,32),field8c=u32(row,36),bank=u32(row,40),published_tick=u32(row,44),field90=u32(row,48),generation=u32(row,52),original_variant=u32(row,56),bridge_applied=(u32(row,60)%256==1 or u32(row,60)%256==19),custom_applied=u32(row,60)%256==19,bridge_reason=u32(row,60)%256,approval_token=math.floor(u32(row,60)/256)}
    for _,site in ipairs(sites) do if e.caller==BASE+site.rva+5 then e.site=site.name;e.source=site.source end end
    if not e.site or not e.id or e.id<1 or e.id>64 then return nil end
    e.offset=e.bank-e.pointer
    local special=e.group==1 and has(e.flags,0x40)
    local alternatives=has(e.flags,0x20) and not special
    local a,b=0xC0,0x78C0
    if special then a,b=0x60C0,0xD8C0
    elseif alternatives and e.variant==1 then a,b=0x30C0,0xA8C0
    elseif alternatives and (e.variant==2 or e.variant==3) then
      if e.variant==3 and has(e.flags,0x80) then a,b=0x48C0,0xC0C0 else a,b=0x18C0,0x90C0 end
    end
    e.bank_matches=e.offset==a or e.offset==b
    e.native_bank_matches=e.bank_matches
    if e.custom_applied then
      local d=self:bridge_stats().decisions[e.approval_token]
      if d and d.own and (e.bank==d.own.primary or e.bank==d.own.alternate) then
        e.bank_matches=true;e.own_bank_match=true;e.own_snapshot=d.own.number;e.own_primary=e.bank==d.own.primary
      else e.bank_matches=false end
    end
    e.native_source=e.source=="record_field" and (has(e.flags,4) and "record+90" or "record+8C") or e.source
    e.field_matches=e.source=="record_field" and e.variant==(has(e.flags,4) and e.field90 or e.field8c) or false
    e.writer_relation="no_tracked_native_tuple"
    local history=self.intervals
    if self.poll_interval_index then
      history=self.poll_interval_index[table.concat({e.pointer,e.id,e.capture_tick,e.sim_bits},":")]or {}
      self.interval_index_events=(self.interval_index_events or 0)+1
    end
    for i=#history,1,-1 do local w=history[i]
      self.interval_comparisons=(self.interval_comparisons or 0)+1
      if e.pointer==w.pointer and e.id==w.id and e.capture_tick==w.capture_tick and e.sim_bits==w.sim_bits then
        local fallback
        if e.generation~=w.generation then fallback="different_trace_epoch"
        elseif e.seq<=w.begin_seq then fallback="before_commit_marker"
        elseif w.closed and e.seq>w.end_seq then fallback="after_release_marker" end
        if fallback then
          if not e.related_commit then e.related_commit=w.number;e.related_uid=w.uid;e.expected_variant=w.variant;e.writer_relation=fallback end
        else
          e.related_commit=w.number;e.related_uid=w.uid;e.expected_variant=w.variant
          if e.field8c~=w.variant then e.writer_relation="active_field_value_changed"
          elseif e.variant~=w.variant then e.writer_relation="active_field_arg_different"
          elseif not alternatives then e.writer_relation="active_no_alternative_branch"
          elseif not e.bank_matches then e.writer_relation="active_unexpected_bank"
          else
            e.writer_relation="owned_value_and_bank_match";e.owned_match=true;e.commit=w.number;e.uid=w.uid
            e.field_consumed=e.native_source=="record+8C" and e.field_matches
          end
          break
        end
      end
    end
    if e.bridge_applied then
      local b=self:bridge_stats();local d=b.decisions[e.approval_token]
      if d and e.site=="context_path_a" and e.generation==d.generation and e.pointer==d.pointer and e.id==d.id and e.capture_tick==d.capture_tick and e.sim_bits==d.sim_bits and e.variant==d.variant and (d.variant==1 or d.variant==2) and e.group==0 and has(e.flags,0x20) and not has(e.flags,4) and e.bank_matches then
        e.approval_match=true;e.approval_uid=d.uid;e.approval_writer_commit=d.commit;b.attributed=(b.attributed or 0)+1;if e.own_bank_match then local h=self:own_stats();h.returned=h.returned+1 end
      else b.attribution_missed=(b.attribution_missed or 0)+1 end
    end
    if e.site=="context_path_a" then
      local b=self:bridge_stats();local bucket=approval_bucket(e.id,e.capture_tick)
      e.approval_bucket=bucket
      local a=self.data+0x4900+(e.seq%16)*64
      local batch=self.poll_snapshot_batch
      local slot=e.seq%16
      local row=batch and batch:sub(slot*64+1,(slot+1)*64) or self:read(a,64)
      if row and u32(row,0)==e.seq and (batch or u32(self:read(a,4),0)==e.seq) then
        e.slot_snapshot={bucket=u32(row,4),version=u32(row,8),active=u32(row,12),pointer=u32(row,16),id=u32(row,20),capture=u32(row,24),sim=u32(row,28),token=u32(row,32),epoch=u32(row,36),native_tick=u32(row,40),status=u32(row,44),native_bank=u32(row,48),custom_bank=u32(row,52),custom_status=u32(row,56),custom_enabled=u32(row,60)}
      else b.snapshot_missing=(b.snapshot_missing or 0)+1 end
      local found
      if b.exact_decisions then
        found=b.decisions[b.exact_decisions[tuple_key(e)]]
      else
        for i=#b.decision_order,1,-1 do local d=b.decisions[b.decision_order[i]]
          if d and d.pointer==e.pointer and d.id==e.id and d.capture_tick==e.capture_tick and d.sim_bits==e.sim_bits and d.generation==e.generation then found=d;break end
        end
      end
      if found then
        e.earlier_approval_token=found.token;e.approval_retired_reason=found.retired_reason
        e.approval_coverage=found.retired_reason and "exact_decision_retired" or "exact_decision_retained"
      else e.approval_coverage="no_exact_decision_in_retained_history" end
      local attempt,lookup=self:attempt_lookup(e)
      e.model_attempt=attempt;e.attempt_lookup=lookup
      local h=self:attempt_stats();h.lookup[lookup]=(h.lookup[lookup] or 0)+1
      if attempt then local reason=attempt.stage=="field_committed" and "field_committed: native field write/readback verified" or (attempt.stage..": "..attempt.reason);h.context_reasons[reason]=(h.context_reasons[reason] or 0)+1 end
      self:delivery_capture(e)
      b.coverage=b.coverage or {};b.coverage[e.approval_coverage]=(b.coverage[e.approval_coverage] or 0)+1
    end
    return e
  end
  function M:poll()
    if not self.running then return end
    local seq,drops=self:counter();if not seq then return end
    self.native_drops=drops
    if seq<self.last_seq then self.fault="trace counter moved backward";self:stop();return end
    local begin=self.last_seq+1
    self.poll_interval_index=nil
    if seq>=begin then
      local index={}
      for _,w in ipairs(self.intervals)do
        local key=table.concat({w.pointer,w.id,w.capture_tick,w.sim_bits},":")
        local bucket=index[key]or {};index[key]=bucket;bucket[#bucket+1]=w
      end
      self.poll_interval_index=index;self.interval_index_builds=(self.interval_index_builds or 0)+1
    end
    if seq-self.last_seq>CAP then self.lost=self.lost+(seq-self.last_seq-CAP);begin=seq-CAP+1 end
    local batched={}
    self.poll_snapshot_batch=nil
    if seq>=begin then
      local address=self.data+0x4900
      local first=self:read(address,16*64)
      if first and self:read(address,16*64)==first then self.poll_snapshot_batch=first end
    end
    local cursor=begin
    while cursor<=seq do
      local index=(cursor-1)%CAP
      local amount=math.min(seq-cursor+1,CAP-index)
      local address=self.data+64+index*ROW
      local first=self:read(address,amount*ROW)
      local second=first and self:read(address,amount*ROW)
      if first and first==second then
        for j=0,amount-1 do batched[cursor+j]=first:sub(j*ROW+1,(j+1)*ROW) end
        self.trace_batch_rows=(self.trace_batch_rows or 0)+amount
      else self.trace_batch_fallbacks=(self.trace_batch_fallbacks or 0)+1 end
      cursor=cursor+amount
    end
    for n=begin,seq do
      local a=self.data+64+((n-1)%CAP)*ROW
      local row=batched[n] or self:read(a,ROW)
      if row and u32(row,0)==n and (batched[n] or u32(self:read(a,4),0)==n) then
        local e=self:decode(row)
        if e then
          self.events=self.events+1
          if e.bridge_applied then local b=self:bridge_stats();b.guarded=b.guarded+1;if e.original_variant~=e.variant then b.changed=b.changed+1 end;if e.bank_matches then b.bank_ok=b.bank_ok+1 end end
          if e.source=="shot_context" and e.bridge_reason>1 and e.bridge_reason~=19 then local b=self:bridge_stats();b.rejected=b.rejected or {};b.rejected[e.bridge_reason]=(b.rejected[e.bridge_reason] or 0)+1 end
          local st=self.sites_seen[e.site] or {calls=0,bank_ok=0,owned=0,field_consumed=0};self.sites_seen[e.site]=st
          st.calls=st.calls+1;if e.bank_matches then st.bank_ok=st.bank_ok+1 end
          if e.owned_match then st.owned=st.owned+1 end;if e.field_consumed then st.field_consumed=st.field_consumed+1 end
          self.recent[#self.recent+1]=e;if #self.recent>128 then table.remove(self.recent,1) end
          local pool=self.site_recent[e.site] or {};self.site_recent[e.site]=pool
          pool[#pool+1]=e;if #pool>16 then table.remove(pool,1) end
          if e.source=="shot_context" then self.context_recent[#self.context_recent+1]=e;if #self.context_recent>64 then table.remove(self.context_recent,1) end end
          local r=self.relations[e.site] or {};self.relations[e.site]=r;r[e.writer_relation]=(r[e.writer_relation] or 0)+1
        else self.decode_rejects=(self.decode_rejects or 0)+1 end
      else self.torn=(self.torn or 0)+1 end
      self.last_seq=n
    end
    self.poll_snapshot_batch=nil;self.poll_interval_index=nil
  end
  function M:fire(event)
    if not self.running or not event then return end
    self:poll()
    local ok,data=pcall(env.shot,event);if not ok or type(data)~="table" or type(data.id)~="number" then return end
    local previous=self.shots[data.id]
    if previous and previous.target==data.target and previous.uid==data.uid and previous.tick==data.tick then return end
    self.shot_total=self.shot_total+1
    local shot={id=data.id,target=data.target,uid=data.uid,tick=data.tick,backtrack=data.backtrack,matched=0,field=0,context=0}
    local feedback_candidates={}
    -- A separate pool prevents scan_enum traffic from evicting parsed shot-context calls.
    local candidates,seen={},{}
    for _,pool in ipairs({self.recent,self.context_recent}) do
      for _,e in ipairs(pool) do if not seen[e.seq] then seen[e.seq]=true;candidates[#candidates+1]=e end end
    end
    table.sort(candidates,function(a,b)return a.seq>b.seq end)
    shot.target_index_calls=0;shot.target_context_calls=0;shot.approved_context_calls=0;shot.own_context_calls=0
    for _,e in ipairs(candidates) do
      if e.published_tick<=data.tick and data.tick-e.published_tick<=2 and e.id==data.target then
        shot.target_index_calls=shot.target_index_calls+1
        if e.own_bank_match and e.approval_match and e.approval_uid==data.uid then
          shot.own_context_calls=shot.own_context_calls+1;if not shot.own_token then shot.own_token=e.approval_token;shot.own_snapshot=e.own_snapshot end
        end
        if e.source=="shot_context" then
          shot.target_context_calls=shot.target_context_calls+1
          if not shot.native_context then
            shot.native_context={pointer=e.pointer,approval_coverage=e.approval_coverage,retired_reason=e.approval_retired_reason,attempt_stage=e.model_attempt and e.model_attempt.stage,attempt_reason=e.model_attempt and e.model_attempt.reason,seq=e.seq,site=e.site,variant=e.variant,field8c=e.field8c,group=e.group,offset=e.offset,capture_tick=e.capture_tick,sim_bits=e.sim_bits,flags=e.flags,relation=e.writer_relation,owned=e.owned_match==true,render_tick=e.published_tick,original_variant=e.original_variant,bridge_applied=e.bridge_applied,bridge_reason=e.bridge_reason,bank_matches=e.bank_matches,approval_token=e.approval_token,approval_match=e.approval_match==true,approval_uid=e.approval_uid}
          end
        end
        if e.approval_match and e.approval_uid==data.uid then shot.approved_context_calls=shot.approved_context_calls+1;self:delivery_link(e,shot) end
        if e.uid==data.uid and e.owned_match then
          shot.matched=shot.matched+1;if e.field_consumed then shot.field=shot.field+1 end
          if e.source=="shot_context" then shot.context=shot.context+1 end
          if not shot.latest then shot.latest=e.seq;shot.commit=e.commit;shot.variant=e.variant;shot.offset=e.offset;shot.site=e.site end
        end
      end
    end
    local bt,iv=tonumber(data.backtrack),env.interval and env.interval()
    local sdk_sim
    if env.transfer_context and event.target then local ok,c=pcall(env.transfer_context,event.target);if ok and type(c)=="table"and c.id==data.target and c.uid==data.uid then sdk_sim=c.sim end end
    if type(bt)=="number"and bt==bt and bt%1==0 and bt>=0 and bt<=32 and type(iv)=="number"and iv>0 and iv<=0.1 and type(sdk_sim)=="number"then
      for _,e in ipairs(candidates)do
        local d=e.approval_match and self:bridge_stats().decisions[e.approval_token]
        local f=d and d.feedback;local q=e.slot_snapshot
        if e.site=="context_path_a"and e.own_bank_match and e.bridge_applied and e.approval_uid==data.uid and e.id==data.target and e.published_tick<=data.tick and data.tick-e.published_tick<=2 and d and d.own and e.bank==(e.own_primary and d.own.primary or d.own.alternate)and d.generation==self.generation and f and type(f.bucket)=="string"and type(f.yaw)=="number"and type(f.base)=="number"and q and q.status==2 and q.token==d.token and q.epoch==d.generation and q.pointer==d.pointer and q.id==d.id and q.capture==d.capture_tick and q.sim==d.sim_bits and q.native_tick>=d.armed_tick and q.native_tick<=d.expires and q.custom_status==1 and q.custom_bank==e.bank then
          local codec=self:matrix_codec();local decoded=codec and codec.decode(d.sim_bytes);local sim=decoded and decoded[1]
          if sim and math.abs(sim-(sdk_sim-bt*iv))<=iv*0.1 then
            feedback_candidates[d.token]={id=d.id,uid=d.uid,fire_tick=data.tick,seq=e.seq,token=d.token,snapshot=d.own and d.own.number,epoch=f.epoch,observer_generation=f.observer_generation,observer_revision=f.observer_revision,state=f.state,bucket=f.bucket,yaw=f.yaw,base=f.base,bank_group=e.own_primary and "primary"or "alternate"}
          end
        end
      end
    end
    local n,unique=0,nil;for _,candidate in pairs(feedback_candidates)do n=n+1;unique=candidate end
    if n==1 then shot.feedback=unique;shot.feedback_reason="unique own-record/backtrack correlation; selected record NOT proven"
    elseif n>1 then shot.feedback_reason="multiple candidate approvals in fire window"
    elseif shot.own_context_calls==0 then shot.feedback_reason="no approved own-bank return in target fire window"
    else shot.feedback_reason="own return present; exact backtrack/machine-clock/candidate tuple rejected"end
    self.shots[data.id]=shot;self.shot_order[#self.shot_order+1]=shot
    if #self.shot_order>48 then local old=table.remove(self.shot_order,1);if self.shots[old.id]==old then self.shots[old.id]=nil end end
  end
  function M:shot_context_evidence(shotid,id,uid)
    local shot=self.shots[shotid]
    if not shot or shot.target~=id or shot.uid~=uid then return nil end
    local c=shot.native_context;local context
    if c then
      context={};for k,v in pairs(c)do context[k]=v end
      local reasons={[0]="bridge_not_attempted",[1]="guarded_native_bank",[2]="group_not_zero",[3]="native_flags_rejected",[4]="index_out_of_range",[5]="approval_slot_inactive",[6]="record_pointer_mismatch",[7]="record_index_mismatch",[8]="capture_tick_mismatch",[9]="simulation_bits_mismatch",[10]="trace_epoch_mismatch",[11]="clock_pointer_changed",[12]="approval_age_rejected",[13]="variant_rejected",[14]="legacy_guard",[15]="slot_version_changed",[16]="bridge_disabled",[17]="token_invalid",[18]="slot_version_odd",[19]="own_bank_substituted",[20]="own_pointer_or_capacity_invalid"}
      context.guard_reason=reasons[c.bridge_reason] or ("unknown_guard_"..tostring(c.bridge_reason))
      context.capture_age_ticks=shot.tick-c.capture_tick
      context.approval_uid_match=c.approval_match==true and c.approval_uid==uid
    end
    return {context_calls=shot.target_context_calls or 0,own_returns=shot.own_context_calls or 0,token=shot.own_token,snapshot=shot.own_snapshot,context=context,selected_record_proven=false,feedback=shot.feedback and (function()local copy={};for k,v in pairs(shot.feedback)do copy[k]=v end;return copy end)()or nil,feedback_reason=shot.feedback_reason}
  end
  function M:ack(event)
    if not event then return end
    local ok,id,state=pcall(function()return tonumber(event.id),tostring(event.state or "unknown"):sub(1,80)end)
    local s=ok and self.shots[id] or nil
    if s and not s.ack then
      local good,data=pcall(env.shot,event)
      if good and type(data)=="table" and data.uid~=nil and data.target~=nil and (data.uid~=s.uid or data.target~=s.target or data.tick<s.tick or data.tick-s.tick>256) then return end
      self.acks=self.acks+1;s.ack=state;s.ack_scope="event-id correlation"
    end
  end
  function M:perf_start()
    if self.io and self.io.time_us then local ok,value=pcall(self.io.time_us,self.io);if ok then return value end end
  end
  function M:perf_finish(name,start)
    if not start then return end
    local now=self:perf_start();if not now or now<start then return end
    self.stage_perf=self.stage_perf or {};local q=self.stage_perf[name] or {calls=0,total=0,max=0}
    self.stage_perf[name]=q;local elapsed=now-start;q.calls=q.calls+1;q.total=q.total+elapsed;q.max=math.max(q.max,elapsed);q.last=elapsed
  end
  function M:report_lines()
    self:poll()
    local owned=0;for _ in pairs(self.owned)do owned=owned+1 end
    local lines={string.format("Native trace state=%s enabled=%s call_sites_owned=%d installs=%d restores=%d conflicts=%d",self.state,tostring(self.running==true),owned,self.installs,self.restores,self.conflicts),
      "Native trace fault="..tostring(self.fault),
      "Native trace ABI fault="..tostring(self.abi_fault).."; exhausted LuaJIT type tables require a fresh VM, not garbage collection",
      string.format("Native trace events=%d producer_seq=%d lost_overrun=%d dropped_lock=%d torn_or_overwritten=%d decode_rejects=%d tracked_commits=%d",self.events,self.last_seq,self.lost,self.native_drops or 0,self.torn or 0,self.decode_rejects or 0,self.commit_counter),
      string.format("Native trace attribution markers attempted=%d commit_marker_missed=%d release_marker_missed=%d; missing markers exclude uncertain ownership",self.commit_attempts or 0,self.commit_marker_missed or 0,self.release_marker_missed or 0),
      string.format("Native trace filter=scan_variants with field8C==0 sampled 1/32; all nonzero-field8C scans eligible; other sites unsampled; examined_default_scans=%d",self.filtered_scan_candidates or 0),
      "Native trace counts=saved events, NOT total calls; producer/lock/overrun losses still reported; parsed context pool retained separately (64 events)",
      "Native trace scope=two shot-context CALL operands in FFI production; five in full diagnostics; original selector executes; optional bridge may override arg1 at context_path_a; no Lua callback from native code; actual returned bank pointer observed",
      "Native trace attribution=commit UID plus native pointer/index/capture-tick/sim-bits/variant and producer-sequence interval; record_field and shot_context are distinct",
      "Native trace absence policy=zero owned matches is NOT proof of nonconsumption when events or attribution markers were lost",
      "Native trace shot correlation=owned tuple+commit UID within <=2 published render ticks observed by aim_fire poll; native execution time/order unverified; correlation only, NOT proof of selected shot record or hitboxes",
      "Native trace patches=atomic compare-exchange of the four-byte CALL operand; E8 opcode unchanged; executable pages and protection restoration checked",
      "Native trace memory_policy=after activation, one 4KiB executable page and one 32KiB data allocation retained until process exit, including after script unload, for in-flight wrappers"}
    lines[#lines+1]=string.format("FFI perf cold_trace_filter=%s cold_calls_seen=%s policy=production installs ONLY two shot-context hooks; cold CALLs are original/unhooked; full diagnostics installs five hooks",tostring(self.production_filter_value==1),tostring(self.data and u32(self:read(self.data+40,4),0)))
    local p=self.io and self.io.perf
    if p then lines[#lines+1]=string.format("FFI perf IO queries=%d reads=%d data_writes=%d data_cas=%d code_writes=%d code_cas=%d; private RW data paths use NO VirtualProtect/FlushInstructionCache",p.queries or 0,p.reads or 0,p.data_writes or 0,p.data_cas or 0,p.code_writes or 0,p.code_cas or 0) end
    for _,name in ipairs({"trace_sync","deferred_collection","deferred_selector","own_prepare","own_publish","trace_diagnostics","own_build","resolver_update","network_ready"})do
      local q=self.stage_perf and self.stage_perf[name]
      if q then lines[#lines+1]=string.format("FFI perf stage=%s calls=%d mean_us=%.1f max_us=%.1f last_us=%.1f timer=QueryPerformanceCounter; stage timing NOT whole-frame FPS",name,q.calls,q.total/q.calls,q.max,q.last) end
    end
    lines[#lines+1]=string.format("FFI perf interval_index builds=%d events=%d comparisons=%d; exact pointer/index/capture/simulation buckets; generation/sequence/ownership checks unchanged; all trace events still decoded",self.interval_index_builds or 0,self.interval_index_events or 0,self.interval_comparisons or 0)
    for _,line in ipairs(self:bridge_lines())do lines[#lines+1]=line end
    if self.last_error then lines[#lines+1]="Native trace retained error="..self.last_error end
    for _,site in ipairs(sites) do local st=self.sites_seen[site.name] or {};lines[#lines+1]=string.format("Native trace site=%s source=%s calls=%d bank_ok=%d owned_tuple_matches=%d owned_record8C_consumed=%d",site.name,site.source,st.calls or 0,st.bank_ok or 0,st.owned or 0,st.field_consumed or 0) end
    for _,site in ipairs(sites) do
      local relations=self.relations[site.name] or {};local names={};for name in pairs(relations) do names[#names+1]=name end;table.sort(names)
      for _,name in ipairs(names) do lines[#lines+1]="Native trace relation site="..site.name.." reason="..name.." events="..relations[name] end
      local pool=self.site_recent[site.name] or {}
      for i=math.max(1,#pool-2),#pool do local e=pool[i]
        lines[#lines+1]=string.format("Native trace site_recent seq=%d site=%s id=%d capture_tick=%d sim_bits=%08X arg=%d field8C=%d bank_offset=%X relation=%s related_commit=%s expected_variant=%s",e.seq,e.site,e.id,e.capture_tick,e.sim_bits,e.variant,e.field8c,e.offset%4294967296,e.writer_relation,tostring(e.related_commit),tostring(e.expected_variant))
      end
    end
    for i=math.max(1,#self.recent-5),#self.recent do local e=self.recent[i]
      lines[#lines+1]=string.format("Native trace recent seq=%d site=%s id=%d arg=%d group=%d field8C=%d flags=%08X bank_offset=%X bank_ok=%s owned=%s record8C_consumed=%s commit=%s render_tick=%d",e.seq,e.site,e.id,e.variant,e.group,e.field8c,e.flags,e.offset%4294967296,tostring(e.bank_matches),tostring(e.owned_match==true),tostring(e.field_consumed==true),tostring(e.commit),e.published_tick)
    end
    lines[#lines+1]=string.format("Native trace shots=%d ack_correlated=%d retained=%d/48",self.shot_total,self.acks,#self.shot_order)
    for i=math.max(1,#self.shot_order-11),#self.shot_order do local a=self.shot_order[i]
      lines[#lines+1]=string.format("Native trace shot id=%s target=%s uid=%s tick=%s backtrack=%s nearby_owned_calls=%d record8C_calls=%d owned_context_calls=%d latest_seq=%s commit=%s site=%s ack=%s proof=temporal-correlation-only",tostring(a.id),tostring(a.target),tostring(a.uid),tostring(a.tick),tostring(a.backtrack),a.matched,a.field,a.context,tostring(a.latest),tostring(a.commit),tostring(a.site),tostring(a.ack))
    end
    for i=math.max(1,#self.shot_order-11),#self.shot_order do local a=self.shot_order[i]
      lines[#lines+1]=string.format("Native trace shot_window id=%s target_index_calls=%d target_context_calls=%d scope=target-index/render-window ONLY; no UID proof without owned tuple",tostring(a.id),a.target_index_calls or 0,a.target_context_calls or 0)
      local c=a.native_context
      if c then lines[#lines+1]=string.format("Native trace shot_context id=%s seq=%d site=%s arg=%d field8C=%d group=%d bank_offset=%X capture_tick=%d sim_bits=%08X flags=%08X relation=%s owned=%s render_tick=%d proof=temporal-correlation-only",tostring(a.id),c.seq,c.site,c.variant,c.field8c,c.group,c.offset%4294967296,c.capture_tick,c.sim_bits,c.flags,c.relation,tostring(c.owned),c.render_tick)
        lines[#lines+1]=string.format("Native bridge shot_context id=%s seq=%d original_arg=%d forwarded_arg=%d guarded=%s bank_offset=%X bank_ok=%s approval_token=%d approval_match=%s; shot-record linkage unverified",tostring(a.id),c.seq,c.original_variant,c.variant,tostring(c.bridge_applied),c.offset%4294967296,tostring(c.bank_matches),c.approval_token,tostring(c.approval_match))
        lines[#lines+1]=string.format("Native bridge approval_shot id=%s UID_matched_context_calls=%d; temporal correlation ONLY",tostring(a.id),a.approved_context_calls or 0)
      end
    end
    for i=math.max(1,#self.shot_order-11),#self.shot_order do local a=self.shot_order[i]
      local e=self:shot_context_evidence(a.id,a.target,a.uid);local c=e and e.context
      lines[#lines+1]=string.format("Native trace shot_delivery id=%s total_context_calls=%d own_returns=%d latest_guard=%s coverage=%s observed_capture=%s observed_age=%s; temporal context ONLY, not selected shot-record proof",tostring(a.id),a.target_context_calls or 0,a.own_context_calls or 0,c and c.guard_reason or "no temporal context",c and tostring(c.approval_coverage)or "unknown",c and tostring(c.capture_tick)or "unknown",c and tostring(c.capture_age_ticks)or "unknown")
      if c then lines[#lines+1]=string.format("Native trace shot_record id=%s record=%08X flags=%08X prior_stage=%s prior_reason=%s approval_UID_match=%s; scalar diagnostic copy, never dereferenced later",tostring(a.id),c.pointer or 0,c.flags or 0,tostring(c.attempt_stage),tostring(c.attempt_reason),tostring(c.approval_uid_match))end
    end
    for _,line in ipairs(self:pipeline_lines())do lines[#lines+1]=line end
    lines[#lines+1]="FFI perf immutable_bank_index_reuses="..tostring(self:own_stats().index_reuses or 0).."; source/model/owned-byte checks retained; native lifetime policy unchanged"
    lines[#lines+1]="FFI perf trace_batch_rows="..tostring(self.trace_batch_rows or 0).." batch_fallbacks="..tostring(self.trace_batch_fallbacks or 0).."; complete double-read rows; pointer/tuple/expiry guards unchanged"
    return lines
  end
  M.spec={relocations={a=0xA6,b=0x3E1,call=0x3DA,cas=2048},base=BASE,selector=SELECTOR,sites=sites,capacity=CAP,row=ROW,template=TEMPLATE,cas=CAS}
  return M
end

  Y.native_trace=create_trace({
    backend=function() return Y.native_patches end,
    bridge_enabled=function() return Y.native_requested() end,
    interval=function()return number(globals.tickinterval)end,
    own_matrix_enabled=function()return yaw_mode()=="FFI" and Y.native_requested()end,
    production_filter=function()return yaw_mode()=="FFI" end,
    performance_interfaces=true,
    transfer_pipeline=function()return yaw_mode()=="FFI" and Y.native_requested()end,
    priority_target=function()local ent=entity.get_threat();return ent and ent:get_index() or nil end,
    transfer_context=function(ent)
      if Y.steam_exclusion and Y.steam_exclusion:is_protected(ent) then return nil,"protected SteamID" end
      return Y.native_records:context(ent)
    end,
    transfer_member=function(v)return Y.native_records:selector_member(v.ent,v)end,
    transfer_complete=function(v,ok,reason)
      local t=Y.native_records:selector_stats()
      if ok then
        t.own_approved=(t.own_approved or 0)+1
        if v.own_tie then t.own_tie_approved=(t.own_tie_approved or 0)+1 end
        t.last="prepared own matrices published; native field8C unchanged; consumer delivery pending"
      else t.last="own preparation/publication rejected: "..tostring(reason) end
      t.last_result=t.last
    end,
    entity_list_pointer=function()
      if not utils or type(utils.create_interface)~="function" then return nil end
      local f=require("ffi")
      for _,module in ipairs({"client.dll","client_panorama.dll"})do
        local ok,ptr=pcall(utils.create_interface,module,"VClientEntityList003")
        if ok and ptr then
          local good,address=pcall(function()return tonumber(f.cast("uintptr_t",ptr))end)
          if good and address and address>=65536 then return address end
        end
      end
      return nil
    end,
    sdk_identity=function(ent)
      if not ent then return nil end
      local info=ent:get_player_info()
      return info and {id=ent:get_index(),uid=tonumber(info.userid)} or nil
    end,
    model_index=function(ent)
      if not ent then return nil end
      local ok,index=pcall(function()return tonumber(ent.m_nModelIndex)end)
      if ok and index then return index end
      if entity and type(entity.get_prop)=="function" then return tonumber(entity.get_prop(ent,"m_nModelIndex")) end
      return nil
    end,
    runtime_model_info_pointer=function()
      if not utils or type(utils.create_interface)~="function" then return nil end
      local ok,ptr=pcall(utils.create_interface,"engine.dll","VModelInfoClient004")
      if not ok or not ptr then return nil end
      local f=require("ffi")
      return tonumber(f.cast("uintptr_t",ptr))
    end,
    enabled=function() return Y.native_ready(2) and (true) end,
    live=function() return not cfg.runtime_paused and not ANEMONE_SECOND_COPY and globals.is_in_game==true end,
    tick=function() return tonumber(globals.tickcount) or 0 end,
    shot=function(event)
      local target=event.target
      if not target then return nil end
      local info=target:get_player_info();local id=tonumber(event.id)
      if not id or not info or not tonumber(info.userid) then return nil end
      return {id=id,target=target:get_index(),uid=tonumber(info.userid),tick=tonumber(globals.tickcount),backtrack=tonumber(event.backtrack)}
    end
  })
  cfg.native_selector_bridge:set_callback(function()
    if not get_bool(cfg.native_selector_bridge) then Y.native_trace:bridge_off() end
  end)
  cfg.native_selector_trace:set_callback(function()
    if not get_bool(cfg.native_selector_trace) then Y.native_trace:stop() end
  end)
end
R:install()
cfg.sidebar_gradient = nil
pcall(function ()
  cfg.sidebar_gradient = require("neverlose/gradient")
end)
local sidebar_theme_at = - 1
local sidebar_theme_hex = nil
local function update_sidebar_theme()
  local now = clock()
  if now >= sidebar_theme_at and now - sidebar_theme_at < 0.04 then
    return
  end
  sidebar_theme_at = now
  local selected, selected_score = nil, - 1
  for rank, style_name in ipairs({ "Link Active", "Accent", "Text Active", "Button Active", "Active" }) do
    local ok, value = pcall(ui.get_style, style_name)
    if ok and value and number(tonumber(value.r)) and number(tonumber(value.g)) and number(tonumber(value.b)) then
      selected, selected_score = value, 200 - rank
      break
    end
  end
  if not selected then
    local ok, styles = pcall(ui.get_style)
    if ok and type(styles) == "table" then
      for style_name, value in pairs(styles) do
        if value and number(tonumber(value.r)) and number(tonumber(value.g)) and number(tonumber(value.b)) then
          local key = tostring(style_name):lower()
          local score = key:find("link active", 1, true) and 120 or key:find("accent", 1, true) and 110 or key:find("active", 1, true) and 90 or key:find("link", 1, true) and 70 or 10
          if key:find("background", 1, true) then
            score = score - 80
          end
          if score > selected_score then
            selected, selected_score = value, score
          end
        end
      end
    end
  end
  local ultimate = cfg.version_state.is_ultimate()
  local plus = cfg.version_state.is_plus()
  if ultimate then
    selected = color(166, 25, 46, 255)
  elseif plus then
    selected = color(181, 255, 46, 255)
  end
  local display_name = ultimate and "hellsing • ultimate" or (plus and "anemone • plus" or NAME)
  local hex = nil
  if selected then
    pcall(function ()
      hex = selected:to_hex()
    end)
    if type(hex) ~= "string" or # hex < 8 then
      hex = string.format("%02X%02X%02X%02X", tonumber(selected.r) or 255, tonumber(selected.g) or 255, tonumber(selected.b) or 255, tonumber(selected.a) or 255)
    end
  end
  hex = type(hex) == "string" and hex:sub(1, 8):upper() or nil
  if hex == sidebar_theme_hex and not (cfg.sidebar_gradient and cfg.sidebar_gradient.text) then
    return
  end
  sidebar_theme_hex = hex
  local title = hex and (string.char(7) .. hex .. display_name .. string.char(7) .. "DEFAULT") or display_name
  if selected and cfg.sidebar_gradient and cfg.sidebar_gradient.text then
    local colors = { }
    for i = 1, 5 do
      local wave = (math.sin(now * 4.6 + (i - 1) * 1.30) + 1) * 0.5
      local lift = 0.06 + wave * 0.40
      local r = math.floor((tonumber(selected.r) or 255) + (255 - (tonumber(selected.r) or 255)) * lift + 0.5)
      local g = math.floor((tonumber(selected.g) or 255) + (255 - (tonumber(selected.g) or 255)) * lift + 0.5)
      local b = math.floor((tonumber(selected.b) or 255) + (255 - (tonumber(selected.b) or 255)) * lift + 0.5)
      colors[i] = color(clamp(r, 0, 255), clamp(g, 0, 255), clamp(b, 0, 255), tonumber(selected.a) or 255)
    end
    local ok, value = pcall(function ()
      return cfg.sidebar_gradient.text(display_name, false, colors)
    end)
    if ok and type(value) == "string" and value ~= "" then
      title = value
    end
  end
  pcall(function ()
    local sidebar_icon = ultimate and cfg.version_state.blood_text(icon({ "skull", "skull-crossbones" })) or (plus and cfg.version_state.lime_text(icon({ "flask", "atom", "vial" })) or "meteor")
    ui.sidebar(title, sidebar_icon)
  end)
end
update_sidebar_theme()
local function clean_text(value)
  return tostring(value):gsub("%c", " "):sub(1, 120)
end
local function guarded(key, fn)
  local ok, err = pcall(fn)
  if not ok then
    warn_once(key, key .. ": " .. clean_text(err))
  end
end
local last_maintenance = - 1
local interp_saved = nil
local function interpolation_restore()
  if not interp_saved then
    return
  end
  pcall(function ()
    if cvar.cl_interpolate then
      cvar.cl_interpolate:int(interp_saved[1])
    end
  end)
  pcall(function ()
    if cvar.cl_interp_ratio then
      cvar.cl_interp_ratio:int(interp_saved[2])
    end
  end)
  pcall(function ()
    if cvar.cl_interp then
      cvar.cl_interp:float(interp_saved[3])
    end
  end)
  interp_saved = nil
end
local function interpolation_tick()
  if interp_saved then interpolation_restore() end
  if not get_bool(cfg.resolver) and not get_bool(cfg.extrapolation) then R.lerp_seconds=nil;return end
  R.lerp_seconds=R:record_lerp()
end
local model_changer_tick, model_changer_restore, model_changer_map_reset = (function()
  local models = _G.__ANEMONE_MODEL_PATHS or { }
  local initialized, unavailable = false, false
  local ffi, class_ptr, model_info, string_tables
  local get_model_index, find_or_load_model, find_table
  local precached, original_index, original_entity = { }, nil, nil
  local refresh_token = tonumber(_G.__ANEMONE_MODEL_REFRESH_TOKEN) or 0
  local function create_interface(module, name)
    if not utils or type(utils.create_interface) ~= "function" then
      return nil
    end
    local ok, ptr = pcall(utils.create_interface, module, name)
    return ok and ptr or nil
  end
  local function init()
    if initialized then return true end
    if unavailable then return false end
    local ok, err = pcall(function ()
      ffi = require("ffi")
      pcall(ffi.cdef, [[
        typedef struct { void* fnHandle; char szName[260]; int nLoadFlags; int nServerCount; int type; int flags; float vecMins[3]; float vecMaxs[3]; float radius; char pad[0x1C]; } anemone_model_t;
        typedef int(__thiscall* anemone_get_model_index_t)(void*, const char*);
        typedef const anemone_model_t(__thiscall* anemone_find_or_load_model_t)(void*, const char*);
        typedef int(__thiscall* anemone_add_string_t)(void*, bool, const char*, int, const void*);
        typedef void*(__thiscall* anemone_find_table_t)(void*, const char*);
      ]])
      class_ptr = ffi.typeof("void***")
      local raw_model = create_interface("engine.dll", "VModelInfoClient004")
      local raw_tables = create_interface("engine.dll", "VEngineClientStringTable001")
      if not raw_model or not raw_tables then error("required engine interface unavailable") end
      model_info = ffi.cast(class_ptr, raw_model)
      string_tables = ffi.cast(class_ptr, raw_tables)
      get_model_index = ffi.cast("anemone_get_model_index_t", model_info[0][2])
      find_or_load_model = ffi.cast("anemone_find_or_load_model_t", model_info[0][39])
      find_table = ffi.cast("anemone_find_table_t", string_tables[0][3])
      if not get_model_index or not find_or_load_model or not find_table then error("model functions unavailable") end
    end)
    initialized = ok
    unavailable = not ok
    if not ok then warn_once("model_changer_init", "Model Changer unavailable: " .. tostring(err)) end
    return initialized
  end
  local function selected_team(name)
    local selected={ }
    pcall(function () selected=cfg.model_changer_team:get() or { } end)
    for _, value in ipairs(selected) do if value==name then return true end end
    return false
  end
  local function precache(path)
    if precached[path] then return true end
    local ok, result = pcall(function ()
      local raw = find_table(string_tables, "modelprecache")
      if raw == nil then return false end
      local table_ptr = ffi.cast(class_ptr, raw)
      local add_string = ffi.cast("anemone_add_string_t", table_ptr[0][8])
      if add_string == nil then return false end
      find_or_load_model(model_info, path)
      return add_string(table_ptr, false, path, -1, nil) ~= -1
    end)
    if ok and result then precached[path]=true; return true end
    return false
  end
  local function write_index(ent, model_index)
    if not ent or model_index == nil then return false end
    local ok = pcall(function () ent.m_nModelIndex = model_index end)
    if not ok then ok = pcall(function () ent["m_nModelIndex"] = model_index end) end
    return ok
  end
  local function restore()
    if original_index ~= nil then
      local me=entity.get_local_player()
      if me then
        local idx=nil; pcall(function () idx=me:get_index() end)
        if idx==original_entity then write_index(me,original_index) end
      end
    end
    original_index, original_entity = nil, nil
  end
  local applied_path, applied_index = nil, nil
  local function map_reset()
    restore()
    precached, original_index, original_entity = { }, nil, nil
    applied_path, applied_index = nil, nil
    initialized, unavailable = false, false
    model_info, string_tables, get_model_index, find_or_load_model, find_table = nil, nil, nil, nil, nil
  end
  local function tick()
    local token = tonumber(_G.__ANEMONE_MODEL_REFRESH_TOKEN) or 0
    if token ~= refresh_token then
      refresh_token = token
      precached, applied_path, applied_index = { }, nil, nil
    end
    if not cfg.model_changer_available or not get_bool(cfg.model_changer) then
      if original_index~=nil then restore() end
      applied_path,applied_index=nil,nil
      return
    end
    if not init() then return end
    local me=entity.get_local_player()
    if not me then restore(); applied_path,applied_index=nil,nil; return end
    local entity_index, team
    pcall(function () entity_index=me:get_index(); team=tonumber(me.m_iTeamNum) end)
    if not entity_index or (team~=2 and team~=3) then restore(); return end
    local team_name=team==2 and "T" or "CT"
    if not selected_team(team_name) then
      if original_index~=nil then restore() end
      applied_path,applied_index=nil,nil
      return
    end
    if original_entity~=entity_index then
      restore(); original_entity=entity_index
      pcall(function () original_index=tonumber(me.m_nModelIndex) end)
    end
    local choice
    pcall(function () choice=(team==2 and cfg.model_changer_t or cfg.model_changer_ct):get() end)
    local path=models[choice]
    if not path then return end
    if applied_path~=path then
      if not precache(path) then
        warn_once("model_changer_precache_"..tostring(choice), "Model file missing or could not be precached: "..path)
        return
      end
      local ok,index=pcall(get_model_index,model_info,path)
      if not ok or not tonumber(index) or index<0 then
        warn_once("model_changer_index_"..tostring(choice), "Model index unavailable: "..path)
        return
      end
      applied_path,applied_index=path,tonumber(index)
    end
    if applied_index then
      write_index(me, applied_index)
      pcall(function () me.m_nSkin = 0 end)
      pcall(function () me.m_nBody = 0 end)
      pcall(function () me.m_nHitboxSet = 0 end)
    end
  end
  return tick, restore, map_reset
end)()
chain("level_init", function ()
  guarded("model_changer_map_reset", model_changer_map_reset)
  if get_bool(cfg.model_changer) then
    utils.execute_after(2.0, function () guarded("model_changer_map_reload", model_changer_tick) end)
  end
end)
chain("pre_render", function ()
  guarded("model_changer_pre_render", model_changer_tick)
end)
chain("net_update_end", function ()
  if get_bool(cfg.model_changer) then
    guarded("model_changer_net_update", model_changer_tick)
  end
end)
local crosshair_indicator_tick = (function()
  local PIXEL_FONT = 2
  local alpha, scope_align = 0, 1
  local bind_rows = { }
  local bind_order = { DT=1, HS=2, DMG=3, HC=4, BAIM=5, SAFE=6, DUCK=7, PING=8, DA=9 }
  local function measure(text)
    local ok, size = pcall(render.measure_text, PIXEL_FONT, "s", tostring(text))
    if not ok or not size then ok, size = pcall(render.measure_text, PIXEL_FONT, nil, tostring(text)) end
    return ok and size or vector(#tostring(text)*6, 10)
  end
  local function clean_name(value)
    return cfg.version_state.clean_bind_name(value)
  end
  local function bind_label(name)
    local n=clean_name(name); local key=n:lower():gsub("[%s%-%._]", "")
    if key:find("doubletap",1,true) or key:find("rapidfire",1,true) then return "DT" end
    if key:find("hideshot",1,true) then return "HS" end
    if key:find("minimumdamage",1,true) or key:find("mindamage",1,true) then return "DMG" end
    if key:find("hitchance",1,true) then return "HC" end
    if key:find("bodyaim",1,true) then return "BAIM" end
    if key:find("safepoint",1,true) then return "SAFE" end
    if key:find("fakeduck",1,true) then return "DUCK" end
    if key:find("fakelatency",1,true) then return "PING" end
    if key:find("dormant",1,true) then return "DA" end
    n=n:upper()
    return #n>16 and n:sub(1,16) or n
  end
  local function update_binds(dt)
    local seen={ }
    local ok,list=pcall(ui.get_binds)
    if ok and type(list)=="table" then
      for _,bind in ipairs(list) do
        local active=false
        pcall(function () active=bind.active==true end)
        if active then
          local label=bind_label(bind.name)
          if label~="" and label~="CROSSHAIR INDICATOR" then
            seen[label]=true
            if not bind_rows[label] then bind_rows[label]={ text=label, alpha=0 } end
          end
        end
      end
    end
    for label,row in pairs(bind_rows) do
      local target=seen[label] and 1 or 0
      row.alpha=row.alpha+(target-row.alpha)*math.min(1,dt*12)
      if row.alpha<0.005 and not seen[label] then bind_rows[label]=nil end
    end
    local out={ }
    for _,row in pairs(bind_rows) do out[#out+1]=row end
    table.sort(out,function(a,b)
      local oa,ob=bind_order[a.text] or 100,bind_order[b.text] or 100
      if oa~=ob then return oa<ob end
      return a.text<b.text
    end)
    return out
  end
  local function accent()
    local ok,c=pcall(function () return cfg.crosshair_indicator_color:get() end)
    return ok and c or color(185,190,255,255)
  end
  local function movement_state(me)
    if not me then return "STANDING" end
    local flags,duck,vx,vy=1,0,0,0
    pcall(function () flags=tonumber(me.m_fFlags) or 1 end)
    pcall(function () duck=tonumber(me.m_flDuckAmount) or 0 end)
    pcall(function () local v=me.m_vecVelocity; if v then vx,vy=tonumber(v.x) or 0,tonumber(v.y) or 0 end end)
    if flags%2==0 then return "AIR" end
    if duck>0.65 then return "CROUCH" end
    if math.sqrt(vx*vx+vy*vy)>8 then return "MOVING" end
    return "STANDING"
  end
  local function draw_center(text,y,c,align,xoff)
    local size=measure(text)
    local x=render.screen_size().x*0.5-size.x*0.5*(align or 1)+(xoff or 0)
    render.text(PIXEL_FONT,vector(x,y),c,"s",text)
    return size.y
  end
  local function tick()
    local dt=0.016
    pcall(function () dt=math.min(0.05,math.max(0.001,globals.frametime)) end)
    local target=get_bool(cfg.crosshair_indicator) and 1 or 0
    alpha=alpha+(target-alpha)*math.min(1,dt*12)
    if alpha<0.01 then return end
    local me=entity.get_local_player(); local alive=false
    pcall(function () alive=me and me:is_alive() end)
    if not alive then return end
    local scoped=false; pcall(function () scoped=me.m_bIsScoped==true end)
    scope_align=scope_align+((scoped and 0 or 1)-scope_align)*math.min(1,dt*10)
    local ac=accent(); local ar,ag,ab,aa=ac:unpack(); aa=aa or 255
    local pulse=math.max(0.2,math.abs(math.sin(clock()*2.5)))
    local base_a=math.floor(255*alpha); local xoff=(1-scope_align)*18
    local screen=render.screen_size(); local y=screen.y*0.5+20
    local ultimate=cfg.version_state.is_ultimate()
    local plus=cfg.version_state.is_plus()
    local brand=ultimate and "HELLSING " or "ANEMONE "
    local edition=ultimate and "ULTIMATE" or (plus and "PLUS" or "BETA")
    local title=brand..edition; local ts=measure(title)
    local tx=screen.x*0.5-ts.x*0.5*scope_align+xoff
    if get_bool(cfg.crosshair_indicator_shadow) then
      pcall(render.shadow,vector(tx,y+ts.y*0.55),vector(tx+ts.x-1,y+ts.y*0.55),color(ar,ag,ab,math.floor(120*alpha)),20,0,0)
    end
    render.text(PIXEL_FONT,vector(tx,y),color(255,255,255,base_a),"s",brand)
    local first=measure(brand)
    render.text(PIXEL_FONT,vector(tx+first.x,y),color(ar,ag,ab,math.floor(aa*alpha*pulse)),"s",edition)
    y=y+ts.y-4
    local state=movement_state(me)
    draw_center(state,y,color(ar,ag,ab,math.floor(aa*alpha)),scope_align,xoff)
    y=y+measure(state).y-4
    local rows=update_binds(dt); local offset=0
    for _,row in ipairs(rows) do
      if row.alpha>0.01 then
        draw_center(row.text,y+offset,color(ar,ag,ab,math.floor(aa*alpha*row.alpha)),scope_align,xoff)
        offset=offset+(measure(row.text).y-4)*row.alpha
      end
    end
  end
  return tick
end)()
local damage_indicator_tick = (function()
  local alpha, ref, last_find = 0, nil, -100
  local pos = _G.__ANEMONE_DAMAGE_POS or { x=nil, y=nil, drag=false, was_left=false, was_right=false, dx=0, dy=0 }
  local museo
  local function find_ref()
    if ref then return ref end
    if clock()-last_find<2 then return nil end
    last_find=clock()
    local paths={
      {"Aimbot","Ragebot","Selection","Minimum Damage"},
      {"Aimbot","Ragebot","Selection","Min. Damage"},
      {"Aimbot","Ragebot","Accuracy","Minimum Damage"},
      {"Aimbot","Ragebot","Main","Minimum Damage"},
      {"Aimbot","Ragebot","Minimum Damage"},
    }
    for _,p in ipairs(paths) do
      local ok,r=pcall(ui.find,p[1],p[2],p[3],p[4])
      if ok and r then local rok=pcall(function() r:get() end); if rok then ref=r; return ref end end
    end
  end
  local function current_damage()
    local r=find_ref(); if not r then return 0 end
    local ok,v=pcall(function() return r:get() end)
    if not ok then ref=nil; return 0 end
    if type(v)=="number" then return v end
    return tonumber(v) or 0
  end
  local function chosen_font()
    local name="Pixel"; pcall(function() name=cfg.damage_indicator_font:get() end)
    if name=="Default" then return 1 end
    if name=="Bold" then return 4 end
    if name=="Museo Sans" then
      if not museo then
        local ok,f=pcall(function()
          if render.safe_load_font then return render.safe_load_font("museo500",15,"a") end
          return render.load_font("Arial",15,"a")
        end)
        museo=ok and f or 1
      end
      return museo
    end
    return 2
  end
  local function tick()
    local dt=0.016; pcall(function() dt=math.min(0.05,math.max(0.001,globals.frametime)) end)
    local enabled=get_bool(cfg.crosshair_indicator) and get_bool(cfg.damage_indicator)
    local me=entity.get_local_player(); local alive=false; pcall(function() alive=me and me:is_alive() end)
    local target=enabled and alive and 1 or 0
    alpha=alpha+(target-alpha)*math.min(1,dt*12)
    if alpha<0.01 then return end
    local screen=render.screen_size()
    if not pos.x then pos.x=screen.x*0.5+5; pos.y=screen.y*0.5-22 end
    local font=chosen_font(); local dmg=current_damage(); local text=dmg==0 and "AUTO" or tostring(math.floor(dmg+0.5))
    local ok,sz=pcall(render.measure_text,font,"s",text); if not ok or not sz then sz=vector(#text*7,12) end
    local w,h=math.max(20,sz.x+8),math.max(20,sz.y+8)
    local menu=false; pcall(function() menu=(ui.get_alpha() or 0)>0.01 end)
    local mouse; pcall(function() mouse=ui.get_mouse_position() end)
    local left,right=false,false; pcall(function() left=common.is_button_down(1)==true; right=common.is_button_down(2)==true end)
    local hover=mouse and mouse.x>=pos.x and mouse.x<=pos.x+w and mouse.y>=pos.y and mouse.y<=pos.y+h
    if menu and hover and left and not pos.was_left then pos.drag=true; pos.dx=mouse.x-pos.x; pos.dy=mouse.y-pos.y end
    if pos.drag and left and mouse then pos.x=clamp(mouse.x-pos.dx,0,screen.x-w); pos.y=clamp(mouse.y-pos.dy,0,screen.y-h) end
    if not left then pos.drag=false end
    if menu and hover and right and not pos.was_right then pos.x=screen.x*0.5+5; pos.y=screen.y*0.5-22 end
    pos.was_left,pos.was_right=left,right
    _G.__ANEMONE_DAMAGE_POS=pos
    local c=color(255,255,255,255); pcall(function() c=cfg.damage_indicator_color:get() end)
    local r,g,b,a=c:unpack(); a=math.floor((a or 255)*alpha)
    render.text(font,vector(pos.x+w*0.5,pos.y+h*0.5),color(r,g,b,a),"cs",text)
  end
  return tick
end)()
local hit_effect_tick, hit_effect_clear = (function()
  local damage_items, cs2_particles = {}, Y.core.hit or {n=0}
  local hit_font
  local spark_ready, spark_failed, spark_fn, spark_vec, spark_angle, spark_material
  local function enabled(item)
    return get_bool(cfg.hit_effect) and get_bool(item)
  end
  local function event_entity(value)
    local ok, ent = pcall(entity.get, value, true)
    return ok and ent or nil
  end
  local function local_attack(e)
    local me = entity.get_local_player()
    if not me then return nil, nil end
    local attacker = event_entity(e.attacker or e.userid)
    if attacker ~= me then return nil, me end
    return attacker, me
  end
  local function effect_mode()
    local ok, mode = pcall(function () return cfg.effects_mode:get() end)
    return ok and mode or "CSGO"
  end
  local function init_spark()
    if spark_ready then return true end
    if spark_failed then return false end
    local ok, result = pcall(function ()
      local ffi = require("ffi")
      pcall(ffi.cdef, [[
        typedef struct { float x; float y; float z; } AnemoneHitVector;
        typedef void(__fastcall* AnemoneSparkFn)(const AnemoneHitVector*, int, int, const AnemoneHitVector*);
      ]])
      local address = utils.opcode_scan("client.dll", "55 8B EC 83 EC 3C 53 8B D9 89 55 FC 8B 0D ?? ?? ?? ?? 56 57")
      if not address then error("spark signature unavailable") end
      spark_fn = ffi.cast("AnemoneSparkFn", address)
      spark_vec = ffi.new("AnemoneHitVector")
      spark_angle = ffi.new("AnemoneHitVector", { x = 0, y = 0, z = 0 })
      spark_material = materials.get("effects/spark", true)
      return spark_fn ~= nil
    end)
    spark_ready = ok and result == true
    spark_failed = not spark_ready
    return spark_ready
  end
  local function spawn_csgo(x, y, z)
    if not init_spark() then return end
    spark_vec.x, spark_vec.y, spark_vec.z = x, y, z
    pcall(function ()
      if spark_material and spark_material:is_valid() then
        spark_material:alpha_modulate(1)
        spark_material:color_modulate(color(190, 225, 255, 255))
      end
      spark_fn(spark_vec, 6, 4, spark_angle)
    end)
  end
  local function spawn_cs2(x, y, z)
    local now = clock()
    for i = 1, 22 do
      local a = math.random() * math.pi * 2
      local speed = 38 + math.random() * 88
      local p=Y.core:particle_new(cs2_particles);if not p then break end
      p.x=x;p.y=y;p.z=z;p.vx=math.cos(a)*speed;p.vy=math.sin(a)*speed;p.vz=35 + math.random()*95;p.born=now;p.life=0.42 + math.random()*0.48;p.size=1.2 + math.random()*2.4;p.line=(i % 3 == 0)and 1 or 0
    end
  end
  local function on_impact(e)
    if not enabled(cfg.effects) then return end
    local attacker = event_entity(e.userid)
    local me = entity.get_local_player()
    if not me or attacker ~= me then return end
    local x, y, z = tonumber(e.x), tonumber(e.y), tonumber(e.z)
    if not x or not y or not z then return end
    if effect_mode() == "CS2" then spawn_cs2(x,y,z) else spawn_csgo(x,y,z) end
  end
  local function on_hurt(e)
    if not enabled(cfg.fortnite_hit) then return end
    local attacker, me = local_attack(e)
    if not attacker or not me then return end
    local victim = event_entity(e.userid)
    if not victim or victim == me then return end
    local pos
    pcall(function () pos = victim:get_hitbox_position(0) end)
    if not pos then pcall(function () pos = victim:get_origin() end) end
    if not pos then return end
    local idx = victim:get_index()
    local now = clock()
    local old = damage_items[idx]
    damage_items[idx] = {
      damage=(old and now-old.born < 0.32 and old.damage or 0) + (tonumber(e.dmg_health) or 0),
      born=now, pos=pos, head=(tonumber(e.hitgroup) or 0)==1
    }
  end
  local function font()
    if hit_font then return hit_font end
    local ok, f = pcall(render.load_font, "Verdana", 25, "abd")
    hit_font = ok and f or 4
    return hit_font
  end
  local function draw_damage(now)
    if not enabled(cfg.fortnite_hit) then damage_items = { }; return end
    for idx, item in pairs(damage_items) do
      local age = now-item.born
      if age >= 1.15 then damage_items[idx]=nil else
        local p = render.world_to_screen(item.pos)
        if p then
          local t = math.min(1, age/0.18)
          local fade = age < 0.72 and 1 or math.max(0, 1-(age-0.72)/0.43)
          local bounce = math.sin(t*math.pi)*20
          local text = tostring(math.floor(item.damage+0.5))
          local c = item.head and color(255,220,45,math.floor(255*fade)) or color(255,255,255,math.floor(255*fade))
          local ok, sz = pcall(render.measure_text, font(), nil, text)
          local w = ok and sz and sz.x or #text*14
          render.text(font(), vector(p.x-w/2, p.y-52-bounce-age*26), c, nil, text)
        end
      end
    end
  end
  local function draw_cs2(now, dt)
    if not enabled(cfg.effects) or effect_mode() ~= "CS2" then cs2_particles.n=0; return end
    for i=cs2_particles.n-1,0,-1 do
      local p=cs2_particles.buffer[i]; local age=now-p.born
      if age>=p.life then Y.core:particle_remove(cs2_particles,i) else
        local drag=(1-math.exp(-0.906817*age))/0.906817
        local screen=render.world_to_screen(vector(p.x+p.vx*drag,p.y+p.vy*drag,p.z+p.vz*age-75*age*age))
        if screen then
          local fade=math.max(0,1-age/p.life); local a=math.floor(230*fade)
          local c=color(120+math.floor(110*fade),190+math.floor(55*fade),255,a)
          if p.line~=0 then
            render.line(vector(screen.x-3*fade,screen.y+4*fade),vector(screen.x+3*fade,screen.y-4*fade),c)
          else render.circle(screen,c,p.size*(0.55+fade),0,1) end
        end
      end
    end
  end
  local last=clock()
  local function tick()
    local now=clock(); local dt=math.min(0.05,math.max(0,now-last)); last=now
    if not get_bool(cfg.hit_effect) then damage_items={};cs2_particles.n=0; return end
    draw_damage(now); draw_cs2(now,dt)
  end
  local function clear() damage_items={};cs2_particles.n=0 end
  chain("player_hurt", on_hurt)
  chain("bullet_impact", on_impact)
  return tick, clear
end)()
local ANEMONE_ACCENT = color(185, 190, 255, 255)
local anemone_font, anemone_header_font = nil, nil
local function ew_accent()
  local style = wm_read_style()
  if style == "Evalate" then
    return wm_eval_accent_color()
  elseif style == "Neverlose" then
    local ok_c, c = pcall(function ()
      return cfg.wm_nl_accent:get()
    end)
    if ok_c and c and number(c.r) and number(c.g) and number(c.b) then
      return c
    end
  elseif style == "Gamesense" then
    local ok_c, c = pcall(function ()
      return cfg.wm_accent:get()
    end)
    if ok_c and c and number(c.r) and number(c.g) and number(c.b) then
      return c
    end
  end
  return ANEMONE_ACCENT
end
local function ew_font()
  if anemone_font then
    return anemone_font
  end
  local ok, f = pcall(render.load_font, "arial", vector(13, 11), "a")
  anemone_font = ok and f or 2
  return anemone_font
end
local function ew_header_font()
  if anemone_header_font then
    return anemone_header_font
  end
  local ok, f = pcall(render.load_font, "arial", 14, "ad")
  anemone_header_font = ok and f or ew_font()
  return anemone_header_font
end
local function ew_measure(text, font)
  local ok, sz = pcall(render.measure_text, font or ew_font(), nil, tostring(text or ""))
  if ok and sz then
    return tonumber(sz.x) or 0, tonumber(sz.y) or 12
  end
  return # tostring(text or "") * 7, 12
end
local function ew_menu_open()
  local ok, a = pcall(ui.get_alpha)
  ;
  return ok and type(a) == "number" and a > 0.01
end
local function ew_mouse()
  local ok, p = pcall(ui.get_mouse_position)
  if ok and p and number(p.x) and number(p.y) then
    return p.x, p.y
  end
end
local function ew_down()
  local ok, v = pcall(common.is_button_down, 1)
  ;
  return ok and v == true
end
local function ew_card(x, y, w, h, alpha, radius)
  alpha = clamp(alpha or 1, 0, 1)
  ;
  radius = radius or 12
  local accent = ew_accent()
  local inner_a = math.floor(65 * alpha)
  local glow = color(accent.r, accent.g, accent.b, inner_a)
  local ix = x + 12.5
  ;
  local iy = y + h / 2 - 1
  pcall(function ()
    render.rect(vector(ix, iy), vector(x + w - 12.5, iy + 2), glow, radius)
  end)
  pcall(function ()
    render.shadow(vector(ix, iy), vector(x + w - 12.5, iy + 2), color(accent.r, accent.g, accent.b, math.floor(255 * alpha)), 70, 0, radius)
  end)
  pcall(function ()
    render.blur(vector(x, y), vector(x + w, y + h), 0, alpha, radius)
  end)
  render.rect(vector(x, y), vector(x + w, y + h), color(150, 150, 150, math.floor(40 * alpha)), radius)
  pcall(function ()
    render.rect_outline(vector(x, y), vector(x + w, y + h), color(255, 255, 255, math.floor(20 * alpha)), 1, radius)
  end)
end
local function ew_drag(box, x, y, w, h)
  local down = ew_down()
  ;
  local mx, my = ew_mouse()
  if ew_menu_open() and down and not box.was and mx and mx >= x and mx <= x + w and my >= y and my <= y + h then
    box.drag = true
    ;
    box.dx = mx - x
    ;
    box.dy = my - y
  end
  if box.drag and down and mx then
    box.x = clamp(mx - box.dx, 0, render.screen_size().x - w)
    ;
    box.y = clamp(my - box.dy, 0, render.screen_size().y - h)
  end
  if not down then
    box.drag = false
  end
  box.was = down
  if box == hotkeys_box then
    _G.__ANEMONE_HOTKEYS_POS = {
      x = box.x,
      y = box.y,
      was = box.was,
      drag = box.drag,
      dx = box.dx,
      dy = box.dy
    }
  end
end
local function ew_clean_name(v)
  return cfg.version_state.clean_bind_name(v)
end
local function ew_bind_blocked(name)
  local n = tostring(name or ""):lower():gsub("[%s%-%._]", "")
  return n == "hitchance" or n == "hideshots"
end
local function ew_binds()
  local ok, list = pcall(ui.get_binds)
  ;
  if not ok or type(list) ~= "table" then
    return { }
  end
  local out = { }
  for _, bind in ipairs(list) do
    local active = false
    ;
    pcall(function ()
      active = bind.active == true
    end)
    if active then
      local name = ew_clean_name(bind.name)
      ;
      local value = bind.value
      if type(value) == "table" then
        local q = { }
        ;
        for _, v in ipairs(value) do
          q[# q + 1] = tostring(v):sub(1, 1)
        end
        ;
        value = # q > 0 and table.concat(q, ", ") or ""
      end
      if type(value) == "boolean" then
        value = ({ [1] = "hold", [2] = "toggle" })[bind.mode] or "?"
      end
      if name ~= "" and not ew_bind_blocked(name) then
        out[# out + 1] = { name = name, value = tostring(value or "") }
      end
    end
  end
  return out
end
local function hotkeys_lerp(a, b, speed)
  local ft = clamp(number(globals and globals.frametime) or 0.016, 0, 0.05)
  return a + (b - a) * (1 - math.exp(- speed * ft))
end
hotkeys_box = _G.__ANEMONE_HOTKEYS_POS or { x = 300, y = 300, was = false, drag = false }
_G.__ANEMONE_HOTKEYS_POS = hotkeys_box
local hotkeys_anim = {
  rows = { },
  serial = 0,
  master = 0,
  width = 128
}
cfg.version_state.emberlash_hotkeys_tick = (function()
  local svg = [[
<svg width="18" height="18" viewBox="0 0 18 18" fill="none" xmlns="http://www.w3.org/2000/svg">
    <rect x="3" y="3.2" width="1.8" height="1.8" rx="0.45" fill="white"/>
    <path d="M3 7.1H4.8V8.1H7V10H4.8V12.2C4.8 12.7 5.2 13.1 5.7 13.1H7V15H5.7C4.2 15 3 13.8 3 12.2V7.1Z" fill="white"/>
    <rect x="6" y="3.2" width="8.7" height="1.8" rx="0.9" fill="white"/>
    <rect x="8.1" y="8.1" width="6.6" height="1.9" rx="0.95" fill="white"/>
    <rect x="8.1" y="13.1" width="6.6" height="1.9" rx="0.95" fill="white"/>
</svg>]]
  local header_icon=nil; pcall(function() header_icon=render.load_image(svg,vector(18,18)) end)
  local header_font,row_font=4,1
  local panel={alpha=0,rect_h=0,window_w=0,window_h=0,rows={}}
  local defs={
    {name="Double tap",label="Double Tap",aliases={"double tap"}},
    {name="On shot anti-aim",label="Hide Shots",aliases={"hide shots","on shot anti-aim"}},
    {name="Force shot",label="Force Shot",aliases={"force shot"}},
    {name="Freestanding",label="Freestanding",aliases={"freestanding","freestand"}},
    {name="Edge yaw",label="Edge Yaw",aliases={"edge yaw"}},
    {name="Static fake yaw inverter",label="Inverter",aliases={"inverter","static fake yaw inverter"}},
    {name="Slow motion",label="Slow Motion",aliases={"slow motion","slow walk"}},
    {name="Damage override",label="Min Damage",aliases={"min. damage","min damage","damage override"}},
    {name="Force body aim",label="Body Aim",aliases={"body aim","force body aim"}},
    {name="Force safe point",label="Safe Point",aliases={"safe points","safe point","force safe point"}},
    {name="Fake duck",label="Fake Duck",aliases={"fake duck"}},
    {name="Ping spike",label="Exploit Backtrack",aliases={"ping spike","fake latency"}}
  }
  local function approach(a,b,s) if math.abs(b-a)<=0.001 then return b end return a+(b-a)*math.min(1,s) end
  local function states()
    local out={}; local binds={}; pcall(function() binds=ui.get_binds() or {} end)
    for _,bind in pairs(binds) do if bind.active then
      local name=cfg.version_state.clean_bind_name(bind.name):lower()
      for _,def in ipairs(defs) do for _,alias in ipairs(def.aliases) do if name:find(alias,1,true) then out[def.name]=true break end end end
    end end
    return out
  end
  local function background(x,y,w,h,a,bg,effects)
    local radius=math.max(1,math.min(10,math.floor(h/2)))
    render.rect(vector(x,y),vector(x+w,y+h),color(bg.r or 0,bg.g or 0,bg.b or 0,math.floor((bg.a or 100)*a/255)),radius)
  end
  local function switch_pill(x,y,w,h,progress,a)
    local tw=math.max(14,math.floor(h*0.58+0.5)); local th=math.max(8,math.floor(h*0.32+0.5)); local tx=x+math.floor((w-tw)/2); local ty=y+math.floor((h-th)/2); local pad=2; local knob=math.max(4,th-pad*2); local kx=tx+pad+math.floor((tw-knob-pad*2)*math.max(0,math.min(1,progress))+0.5)
    render.rect(vector(tx,ty),vector(tx+tw,ty+th),color(222,222,222,math.floor(235*a/255)),math.floor(th/2)); render.circle(vector(kx+knob/2,ty+pad+knob/2),color(0,0,0,math.floor(150*a/255)),knob/2,0,1)
  end
  return function()
    local style="Evalate"; pcall(function() style=cfg.hotkeys_style:get() end)
    local enabled=get_bool(cfg.hotkeys) and style=="Emberlash"; local menu=ew_menu_open(); local frame=tonumber(globals.frametime) or 0.016; local as=math.min(1,frame*14); local ms=math.min(1,frame*16); local state=enabled and states() or {}; local active_count=0
    for _,def in ipairs(defs) do
      local active=state[def.name]==true; local row=panel.rows[def.name]
      if active and not row then row={alpha=0,active=true,y=nil,switch_progress=0,label=def.label}; panel.rows[def.name]=row end
      if row then if active then row.active=true; row.leave_y=nil; row.label=def.label; active_count=active_count+1 else if row.active then row.leave_y=row.y end; row.active=false end; row.alpha=approach(row.alpha or 0,active and 1 or 0,as); row.switch_progress=approach(row.switch_progress or 0,active and 1 or 0,ms); if not active and row.alpha<=0.01 then panel.rows[def.name]=nil end end
    end
    local toggle=enabled and (active_count>0 or menu); panel.alpha=approach(panel.alpha,toggle and 1 or 0,as); if not toggle and panel.alpha<=0.01 and next(panel.rows)==nil then return end
    local title_size=render.measure_text(header_font,"bd","Hotkeys"); local icon_size=math.max(16,title_size.y+3); local header_h=math.max(29,title_size.y+15); local gap=8; local padx=10; local indent=8; local row_h=math.max(24,title_size.y+12); local row_gap=6; local xgap=4; local rowpad=4; local sw=math.max(22,row_h-2); local rows_y=header_h+4; local base_w=padx*2+icon_size+gap+title_size.x; local ww=base_w
    for _,def in ipairs(defs) do local row=panel.rows[def.name]; if row and (row.active or (row.alpha or 0)>0.01) then local sz=render.measure_text(row_font,"d",row.label or def.label); ww=math.max(ww,indent+sw+xgap+math.max(46,sz.x+rowpad*2)+indent) end end
    local target_h=active_count>0 and (rows_y+(active_count-1)*(row_h+row_gap)+row_h) or header_h; panel.rect_h=approach(panel.rect_h,target_h,ms); panel.window_w=approach(panel.window_w>0 and panel.window_w or base_w,ww,ms); panel.window_h=approach(panel.window_h,panel.rect_h,ms)
    ew_drag(hotkeys_box,hotkeys_box.x,hotkeys_box.y,panel.window_w,panel.window_h); local x=math.floor(hotkeys_box.x+0.5); local y=math.floor(hotkeys_box.y+0.5); local a=math.floor(panel.alpha*255); local accent=color(159,166,205,255); local bg=color(0,0,0,100); pcall(function() accent=cfg.hotkeys_anemone_accent:get(); bg=cfg.hotkeys_anemone_background:get() end)
    background(x,y,panel.window_w,header_h,a,bg,true); if header_icon then render.texture(header_icon,vector(x+padx,y+math.floor((header_h-icon_size)/2)),vector(icon_size,icon_size),color(accent.r or 159,accent.g or 166,accent.b or 205,a),"f") end; render.text(header_font,vector(x+padx+icon_size+gap,y+math.floor((header_h-title_size.y)/2)),color(170,170,170,a),"bd","Hotkeys")
    local dy=y+rows_y
    for _,def in ipairs(defs) do local row=panel.rows[def.name]; if row then local target=row.active and dy or ((row.leave_y or row.y or dy)-6); row.y=approach(row.y or (dy+6),target,ms); local ra=math.floor(panel.alpha*(row.alpha or 0)*255); local size=render.measure_text(row_font,"d",row.label or def.label); local lw=math.max(46,size.x+rowpad*2); local rx=x+indent; if ra>1 then background(rx,row.y,sw,row_h,ra,bg,false); background(rx+sw+xgap,row.y,lw,row_h,ra,bg,false); switch_pill(rx,row.y,sw,row_h,row.switch_progress,ra); render.text(row_font,vector(rx+sw+xgap+rowpad,row.y+math.floor((row_h-size.y)/2)),color(211,211,211,ra),"d",row.label or def.label) end; if row.active then dy=dy+row_h+row_gap end end end
  end
end)()
local function hotkeys_tick()
  cfg.version_state.emberlash_hotkeys_tick()
  local selected_style="Evalate"; pcall(function() selected_style=cfg.hotkeys_style:get() end)
  if selected_style=="Emberlash" then return end
  local enabled = get_bool(cfg.hotkeys)
  ;
  local source = enabled and ew_binds() or { }
  for _, r in pairs(hotkeys_anim.rows) do
    r.target = 0
  end
  for order, row in ipairs(source) do
    local key = row.name:lower()
    ;
    local r = hotkeys_anim.rows[key]
    if not r then
      hotkeys_anim.serial = hotkeys_anim.serial + 1
      ;
      r = {
        name = row.name,
        value = row.value,
        alpha = 0,
        target = 1,
        order = hotkeys_anim.serial
      }
      ;
      hotkeys_anim.rows[key] = r
    end
    r.name, r.value, r.target, r.live_order = row.name, row.value, 1, order
  end
  local rows = { }
  for key, r in pairs(hotkeys_anim.rows) do
    r.alpha = hotkeys_lerp(r.alpha, r.target, 12)
    if r.target == 0 and r.alpha < 0.012 then
      hotkeys_anim.rows[key] = nil
    else
      rows[# rows + 1] = r
    end
  end
  table.sort(rows, function (a, b)
    return (a.live_order or 999) < (b.live_order or 999) or ((a.live_order or 999) == (b.live_order or 999) and a.order < b.order)
  end)
  local should_show = enabled and (# rows > 0 or ew_menu_open())
  ;
  hotkeys_anim.master = hotkeys_lerp(hotkeys_anim.master, should_show and 1 or 0, 10)
  if hotkeys_anim.master < 0.01 then
    return
  end
  local content_w = 103
  for _, row in ipairs(rows) do
    local nw = ew_measure(row.name)
    ;
    local vw = ew_measure(row.value)
    ;
    content_w = math.max(content_w, nw + vw + 10)
  end
  hotkeys_anim.width = hotkeys_lerp(hotkeys_anim.width, content_w + 25, 12)
  local final_w = hotkeys_anim.width
  ;
  local header_h = 25
  ;
  local body_y = 30
  ;
  local visible_h = 0
  for _, row in ipairs(rows) do
    visible_h = visible_h + 16 * row.alpha
  end
  local body_h = 13 + visible_h
  ;
  local x, y = hotkeys_box.x, hotkeys_box.y
  ew_drag(hotkeys_box, x, y, final_w, body_y + body_h)
  ;
  x, y = hotkeys_box.x, hotkeys_box.y
  ew_card(x, y, final_w, header_h, hotkeys_anim.master, 12)
  local title = "Hotkeys"
  ;
  local tw, th = ew_measure(title)
  ;
  local accent = ew_accent()
  ;
  local title_x = x + final_w / 2 - tw / 2 + 5
  ;
  local ma = math.floor(255 * hotkeys_anim.master)
  render.text(ew_font(), vector(title_x, y + (header_h - th) / 2), color(240, 240, 240, ma), nil, title)
  render.text(ew_font(), vector(title_x - 13, y + (header_h - th) / 2), color(accent.r, accent.g, accent.b, ma), nil, "{}")
  ew_card(x, y + body_y, final_w, body_h, hotkeys_anim.master, 12)
  local yy = y + body_y + 9
  for _, row in ipairs(rows) do
    local alpha = hotkeys_anim.master * row.alpha
    ;
    local vw = ew_measure(row.value)
    ;
    local a = math.floor(255 * alpha)
    render.text(ew_font(), vector(x + 12.5, yy), color(240, 240, 240, a), nil, row.name)
    render.text(ew_font(), vector(x + final_w - 12.5 - vw, yy), color(170, 170, 175, a), nil, row.value)
    yy = yy + 16 * row.alpha
  end
end
local notification_tick
local EN = _G.__ANEMONE_EN or {
  items = { },
  x = nil,
  y = nil,
  was = false,
  drag = false,
  last_preview = 0,
  burn = { }
}
_G.__ANEMONE_EN = EN
if _G.__ANEMONE_NOTIFY_POS then
  EN.cx, EN.y = _G.__ANEMONE_NOTIFY_POS.cx, _G.__ANEMONE_NOTIFY_POS.y
end
local EN_REASON = {
  spread = color(237, 196, 119, 255),
  correction = color(255, 93, 82, 255),
  misprediction = color(255, 93, 82, 255),
  ["prediction error"] = color(255, 93, 82, 255),
  ["damage rejection"] = color(255, 93, 82, 255),
  ["backtrack failure"] = color(122, 159, 250, 255),
  death = color(140, 140, 140, 255),
  ["player death"] = color(140, 140, 140, 255),
  ["unregistered shot"] = color(140, 140, 140, 255)
}
local EN_HITGROUP = {
  [0] = "generic",
  [1] = "head",
  [2] = "chest",
  [3] = "stomach",
  [4] = "left arm",
  [5] = "right arm",
  [6] = "left leg",
  [7] = "right leg",
  [8] = "neck",
  [9] = "generic",
  [10] = "gear"
}
local function en_enabled(ref)
  return get_bool(cfg.notifications) and get_bool(ref)
end
local function en_print(text)
  if en_enabled(cfg.notification_debug) then
    local ok = pcall(function ()
      print_dev("anemone › " .. text)
    end)
    ;
    if not ok then
      console_line("[anemone debug] " .. text)
    end
  end
  if en_enabled(cfg.notification_console) then
    local ok = pcall(function ()
      print_raw("anemone › " .. text)
    end)
    ;
    if not ok then
      console_line("[anemone] " .. text)
    end
  end
end
local function en_add(text, clr, log_text)
  if en_enabled(cfg.notification_screen) then
    table.insert(EN.items, 1, { text = tostring(text), color = clr or ew_accent(), born = clock() })
    ;
    while # EN.items > 5 do
      table.remove(EN.items)
    end
  end
  en_print(tostring(log_text or text))
end
local function en_name(ent)
  local n = "target"
  ;
  if ent then
    pcall(function ()
      n = ent:get_name()
    end)
  end
  ;
  return tostring(n):gsub("%c", " "):sub(1, 28)
end
local function en_entity(v)
  if type(v) == "userdata" then
    return v
  end
  local e = nil
  ;
  pcall(function ()
    e = entity.get(v, true)
  end)
  ;
  return e
end
local function en_ack(e)
  if not get_bool(cfg.notifications) or not e then
    return
  end
  local target = en_entity(e.target)
  ;
  local name = en_name(target)
  ;
  local state = e.state
  ;
  local hg = EN_HITGROUP[tonumber(e.hitgroup) or - 1] or "?"
  ;
  local whg = EN_HITGROUP[tonumber(e.wanted_hitgroup) or - 1] or "?"
  local dmg = tonumber(e.damage) or 0
  ;
  local wanted = tonumber(e.wanted_damage) or dmg
  ;
  local alive = true
  ;
  local hp = 0
  ;
  if target then
    pcall(function ()
      alive = target:is_alive()
      ;
      hp = number(target.m_iHealth) or 0
    end)
  end
  local main
  if state then
    main = string.format("Miss in %s's %s due to %s", name, whg, tostring(state))
  elseif alive then
    main = string.format("Hit %s in %s for %d damage", name, hg, dmg)
  else
    main = string.format("Killed %s in %s", name, hg)
  end
  local extra = string.format(" › %dt · %d%% · %.2f°", tonumber(e.backtrack) or 0, math.floor((tonumber(e.hitchance) or 0) + 0.5), tonumber(e.spread) or 0)
  if not state and hp > 0 then
    extra = extra .. string.format(" · %d hp", hp)
  end
  if dmg ~= wanted then
    extra = extra .. string.format(" · %d dmg", wanted)
  end
  en_add(main, EN_REASON[state] or ew_accent(), main .. extra)
end
chain("aim_ack", en_ack)
chain("player_death", function (e)
  if not get_bool(cfg.notifications) then
    return
  end
  local me = nil
  ;
  pcall(function ()
    me = entity.get_local_player()
  end)
  ;
  local victim = en_entity(e.userid)
  ;
  local attacker = en_entity(e.attacker)
  if me and victim == me and attacker then
    en_add("Killed by " .. en_name(attacker), EN_REASON.death)
  end
end)
chain("player_hurt", function (e)
  if not get_bool(cfg.notifications) then
    return
  end
  local me = nil
  ;
  pcall(function ()
    me = entity.get_local_player()
  end)
  ;
  local attacker = en_entity(e.attacker)
  ;
  local victim = en_entity(e.userid)
  ;
  if not me or attacker ~= me or not victim then
    return
  end
  local map = {
    inferno = { "Burned", "burned out" },
    knife = { "Knifed", "Stabbed" },
    hegrenade = { "Naded", "Exploded" },
    taser = { "Tased", "Tased" }
  }
  ;
  local m = map[tostring(e.weapon or "")]
  ;
  if not m then
    return
  end
  local alive = (tonumber(e.health) or 0) > 0
  ;
  en_add(string.format("%s %s%s", alive and m[1] or m[2], en_name(victim), alive and (" for " .. tostring(tonumber(e.dmg_health) or 0) .. " damage") or ""), ew_accent())
end)
notification_tick = function ()
  if not get_bool(cfg.notifications) or not get_bool(cfg.notification_screen) then
    EN.items = { }
    ;
    return
  end
  local sc = render.screen_size()
  local now = clock()
  ;
  for i = # EN.items, 1, - 1 do
    if now - EN.items[i].born > 5 then
      table.remove(EN.items, i)
    end
  end
  local list = EN.items
  ;
  local preview = ew_menu_open() and # list == 0
  if preview then
    list = {
      { text = "your face is like a melody - it won't leave my head", color = ew_accent(), born = now },
      { text = "Glad to see you again, PWNZ!", color = ew_accent(), born = now }
    }
  end
  local maxw = 100
  ;
  for _, it in ipairs(list) do
    local w = ew_measure(it.text)
    ;
    maxw = math.max(maxw, w + 36)
  end
  if not EN.cx then
    EN.cx = sc.x / 2
    ;
    EN.y = sc.y / 1.7
  end
  local down = ew_down()
  ;
  local mx, my = ew_mouse()
  ;
  local bx = EN.cx - maxw / 2
  ;
  local bh = 33 * math.max(1, # list)
  if ew_menu_open() and down and not EN.was and mx and mx >= bx and mx <= bx + maxw and my >= EN.y and my <= EN.y + bh then
    EN.drag = true
    ;
    EN.dx = mx - EN.cx
    ;
    EN.dy = my - EN.y
  end
  if EN.drag and down and mx then
    EN.cx = clamp(mx - EN.dx, maxw / 2, sc.x - maxw / 2)
    ;
    EN.y = clamp(my - EN.dy, 0, sc.y - bh)
  end
  if not down then
    EN.drag = false
  end
  ;
  EN.was = down
  ;
  _G.__ANEMONE_NOTIFY_POS = { cx = EN.cx, y = EN.y }
  for i, it in ipairs(list) do
    local age = now - it.born
    ;
    local alpha = preview and 1 or math.min(clamp(age / .18, 0, 1), clamp((5 - age) / .55, 0, 1))
    ;
    local yy = EN.y + (i - 1) * 33
    local tw, th = ew_measure(it.text)
    ;
    local item_w = math.max(100, tw + 36)
    ;
    local item_x = EN.cx - item_w / 2
    ew_card(item_x, yy, item_w, 29, alpha, 12)
    ;
    local clr = it.color or ew_accent()
    render.circle(vector(item_x + 13, yy + 14.5), color(clr.r or 185, clr.g or 190, clr.b or 255, math.floor(70 * alpha)), 4, 0, 1)
    ;
    render.circle(vector(item_x + 13, yy + 14.5), color(clr.r or 185, clr.g or 190, clr.b or 255, math.floor(255 * alpha)), 2, 0, 1)
    render.text(ew_font(), vector(EN.cx - tw / 2 + 5, yy + (29 - th) / 2), color(235, 235, 240, math.floor(255 * alpha)), nil, it.text)
  end
end
movement_tick = function (cmd)
  if not cmd then
    return
  end
  local ok, me = pcall(entity.get_local_player)
  ;
  if not ok or not me then
    return
  end
  local alive = false
  ;
  pcall(function ()
    alive = me:is_alive()
  end)
  ;
  if not alive then
    return
  end
  local on_ladder,movement_type=false,nil
  do
    local mt = nil
    pcall(function ()
      mt = number(me.m_MoveType)
    end)
    if mt == nil then
      pcall(function ()
        mt = number(entity.get_prop(me, "m_MoveType"))
      end)
    end
    movement_type=mt
    if mt == 9 then
      on_ladder = true
    end
  end
  pcall(function ()
    if on_ladder and not _G.__ANEMONE_AA_HELD then
      _G.__ANEMONE_AA_HELD = { }
      local cands = {
        { "Aimbot", "Anti Aim", "Angles", "Enabled" },
        { "Aimbot", "Anti-Aim", "Angles", "Enabled" },
        { "Aimbot", "Anti Aim", "Enabled" },
      }
      for _, p in ipairs(cands) do
        local ok, ref = pcall(function ()
          if # p == 4 then
            return ui.find(p[1], p[2], p[3], p[4])
          end
          return ui.find(p[1], p[2], p[3])
        end)
        if ok and ref then
          local rok, base = pcall(function ()
            return ref:get()
          end)
          if rok and type(base) == "boolean" and base == true then
            local aok = pcall(function ()
              ref:override(false)
            end)
            if aok then
              _G.__ANEMONE_AA_HELD[# _G.__ANEMONE_AA_HELD + 1] = { ref = ref, base = base }
            end
          end
        end
      end
    elseif (not on_ladder) and _G.__ANEMONE_AA_HELD then
      for _, h in ipairs(_G.__ANEMONE_AA_HELD) do
        pcall(function ()
          h.ref:override()
        end)
      end
      _G.__ANEMONE_AA_HELD = nil
    end
  end)
  if get_bool(cfg.movement) and get_bool(cfg.fast_ladder) and on_ladder then
    pcall(function ()
      local camx = nil
      pcall(function ()
        camx = render.camera_angles().x
      end)
      if camx == nil or camx < 45 then
        if (number(cmd.forwardmove) or 0) > 0 then
          cmd.view_angles.x = 89
          cmd.in_moveright = 1
          cmd.in_moveleft = 0
          cmd.in_forward = 0
          cmd.in_back = 1
          local sm = number(cmd.sidemove) or 0
          if sm == 0 then
            cmd.view_angles.y = cmd.view_angles.y + 90
          elseif sm < 0 then
            cmd.view_angles.y = cmd.view_angles.y + 150
          else
            cmd.view_angles.y = cmd.view_angles.y + 30
          end
        elseif (number(cmd.forwardmove) or 0) < 0 then
          cmd.view_angles.x = 89
          cmd.in_moveleft = 1
          cmd.in_moveright = 0
          cmd.in_forward = 1
          cmd.in_back = 0
          local sm = number(cmd.sidemove) or 0
          if sm == 0 then
            cmd.view_angles.y = cmd.view_angles.y + 90
          elseif sm > 0 then
            cmd.view_angles.y = cmd.view_angles.y + 150
          else
            cmd.view_angles.y = cmd.view_angles.y + 30
          end
        end
      end
    end)
  end
  local vel = nil
  ;
  pcall(function ()
    vel = me.m_vecVelocity
  end)
  if get_bool(cfg.movement) and get_bool(cfg.no_fall_damage) and vel and number(vel.z) and vel.z <= - 500 then
    pcall(function ()
      local org = nil
      ;
      pcall(function ()
        org = me:get_origin()
      end)
      if org == nil then
        pcall(function ()
          org = me.m_vecOrigin
        end)
      end
      if not org then
        return
      end
      local function trace_fall(length)
        local TAU = math.pi * 2
        for i = 0, TAU, TAU / 8 do
          local x = org.x + math.cos(i) * 10
          local y = org.y + math.sin(i) * 10
          local s = vector(x, y, org.z)
          local e = vector(x, y, org.z - length)
          local ok, tr = pcall(function ()
            return utils.trace_line(s, e, me)
          end)
          if ok and tr and number(tr.fraction) and tr.fraction < 1.0 then
            return true
          end
        end
        return false
      end
      local state = false
      if trace_fall(15) then
        state = false
      elseif trace_fall(75) then
        state = true
      end
      cmd.in_duck = state
    end)
  end
  if get_bool(cfg.movement) and get_bool(cfg.avoid_collision) and vel and number(vel.x) and number(vel.y) then
    local org = nil
    ;
    pcall(function ()
      org = me:get_origin()
    end)
    if org == nil then
      pcall(function ()
        org = me.m_vecOrigin
      end)
    end
    local sp = math.sqrt((vel.x or 0) * (vel.x or 0) + (vel.y or 0) * (vel.y or 0))
    if org and number(org.x) and sp > 40 and cmd.in_jump and cmd.in_jump ~= 0 then
      local dst = vector(org.x + vel.x / sp * 48, org.y + vel.y / sp * 48, org.z + 24)
      local src = vector(org.x, org.y, org.z + 24)
      local oktr, tr = pcall(function ()
        return utils.trace_line(src, dst, nil, nil, 1)
      end)
      if oktr and tr and number(tr.fraction) and tr.fraction < 0.55 then
        cmd.sidemove = ((number(cmd.command_number) or 0) % 2 == 0) and 450 or - 450
        cmd.forwardmove = - 40
      end
    end
  end
  if get_bool(cfg.jump_scout) and vel then
    local flags = nil
    pcall(function ()
      flags = number(me.m_fFlags)
    end)
    if flags == nil then
      pcall(function ()
        flags = number(entity.get_prop(me, "m_fFlags"))
      end)
    end
    local air = flags ~= nil and not flag_set(flags, 1) or false
    if air then
      local weapon = nil
      ;
      pcall(function ()
        weapon = me:get_player_weapon()
      end)
      local info = nil
      ;
      if weapon then
        pcall(function ()
          info = weapon:get_weapon_info()
        end)
      end
      local name = info and tostring(info.console_name or ""):lower() or ""
      local is_scout = name:find("ssg08", 1, true) ~= nil
      if is_scout then
        local hands_off = (not cmd.in_forward or cmd.in_forward == 0) and (not cmd.in_back or cmd.in_back == 0) and (not cmd.in_moveleft or cmd.in_moveleft == 0) and (not cmd.in_moveright or cmd.in_moveright == 0)
        hands_off=hands_off and math.abs(number(cmd.forwardmove)or 0)<0.01 and math.abs(number(cmd.sidemove)or 0)<0.01 and not (cmd.in_use==true or cmd.in_use==1 or cmd.in_reload==true or cmd.in_reload==1)
        if hands_off and not on_ladder and movement_type~=8 and Y.core.ready then
          local vx, vy = number(vel.x) or 0, number(vel.y) or 0
          local sp = math.sqrt(vx * vx + vy * vy)
          if sp<110 then
            local yaw=cmd.view_angles and number(cmd.view_angles.y)
            if yaw==nil then pcall(function()yaw=number(render.camera_angles().y)end)end
            local aa;pcall(function()aa=number(cvar.sv_airaccelerate:float())end)
            local forward,side=Y.core:counter_motion(vx,vy,yaw,number(globals.tickinterval),aa)
            if forward~=nil then cmd.forwardmove,cmd.sidemove=forward,side end
          end
        end
      end
    end
  end
end
local OPT=(function()
local function create_fps_optimizer(env)
  local M={
    groups={
      ["Decals"]={r_decals=0,r_drawbatchdecals=0,r_drawmodeldecals=0},
      ["Blood and gibs"]={violence_ablood=0,violence_hblood=0,violence_agibs=0,violence_hgibs=0},
      ["Tracers"]={muzzleflash_light=0,r_drawtracers_firstperson=0},
      ["Breakable debris"]={func_break_max_pieces=0,props_break_max_pieces=0},
      ["3D sky"]={r_3dsky=0},
      ["Ropes"]={rope_collide=0,rope_smooth=0,rope_subdiv=0,rope_wind_dist=0,r_drawropes=0},
      ["Foot shadows"]={cl_foot_contact_shadows=0},
      ["Multithreaded rendering"]={mat_queue_mode=2},
      ["Ragdoll physics"]={cl_disable_ragdolls=1,cl_ragdoll_physics_enable=0},
      ["Eye animation"]={r_eyemove=0,r_eyegloss=0,r_eyeshift_x=0,r_eyeshift_y=0,r_eyeshift_z=0,r_eyesize=0},
      ["Detail sway"]={cl_detail_max_sway=0},
      ["Joystick"]={joystick=0},
      ["Dynamic lights"]={r_dynamic=0,muzzleflash_light=0},
      ["Lower sound quality"]={dsp_slow_cpu=1}
    },
    presets={
      ["Recommended"]={"Blood and gibs","Tracers","Breakable debris","Foot shadows","Ragdoll physics","Eye animation","Detail sway","Joystick"},
      ["Maximum FPS"]={"Decals","Blood and gibs","Tracers","Breakable debris","3D sky","Ropes","Foot shadows","Multithreaded rendering","Ragdoll physics","Eye animation","Detail sway","Joystick","Dynamic lights"}
    },
    saved={},active=false,dirty=true,writes=0,restores=0,conflicts=0,unavailable=0,rejected=0,checks=0,selection_reads=0,state="OFF"
  }
  local function finite(v)return type(v)=="number" and v==v and math.abs(v)<math.huge end
  function M:read(ref)
    local ok,v=pcall(function()return ref:float()end)
    if ok and finite(v)then return v end
    ok,v=pcall(function()return ref:int()end)
    if ok and finite(v)then return v end
  end
  function M:write(ref,value)
    local ok=pcall(function()ref:float(value,true)end)
    if not ok then ok=pcall(function()ref:int(value,true)end)end
    return ok and self:read(ref)==value
  end
  function M:selected()
    self.selection_reads=self.selection_reads+1
    local ok,sel=pcall(env.selection);local selected,seen={},{}
    if ok and type(sel)=="table"then
      for k,v in pairs(sel)do
        local name=type(v)=="string"and v or (v==true and type(k)=="string"and k or nil)
        if name and self.groups[name]and not seen[name]then selected[#selected+1]=name;seen[name]=true end
      end
    end
    if #selected==0 then
      local got,preset=pcall(env.preset)
      for _,name in ipairs(self.presets[got and preset or "Recommended"]or self.presets.Recommended)do selected[#selected+1]=name end
    end
    table.sort(selected);return selected
  end
  function M:restore()
    local pending={}
    for name,state in pairs(self.saved)do
      local current=self:read(state.ref)
      if current==nil then pending[name]=state
      elseif current~=state.expected then self.conflicts=self.conflicts+1
      elseif self:write(state.ref,state.previous)then self.restores=self.restores+1
      else pending[name]=state end
    end
    self.saved=pending;self.active=next(pending)~=nil
    self.signature=nil;self.state=self.active and "RESTORE PENDING"or "OFF; prior values restored, external changes preserved"
    return not self.active
  end
  function M:apply(groups)
    if not self:restore()then return false end
    local desired={}
    for _,name in ipairs(groups)do for key,value in pairs(self.groups[name]or {})do desired[key]=value end end
    for name,value in pairs(desired)do
      local ok,ref=pcall(env.ref,name)
      local previous=ok and ref and self:read(ref)or nil
      if previous==nil then self.unavailable=self.unavailable+1
      elseif previous~=value then
        if self:write(ref,value)then
          self.saved[name]={ref=ref,previous=previous,expected=value};self.writes=self.writes+1
        else
          self.rejected=self.rejected+1
          local after=self:read(ref)
          if after~=previous then
            -- Retain ownership even when rollback is temporarily unreadable.
            self.saved[name]={ref=ref,previous=previous,expected=after or value}
            if after~=nil and self:write(ref,previous)then self.saved[name]=nil;self.restores=self.restores+1 end
          end
        end
      end
    end
    self.signature=table.concat(groups,"|");self.active=true;self.state="ON; verified cvars only; no brush-model removal or gameplay cvars"
    return true
  end
  function M:tick()
    local now=env.now();local enabled=env.enabled()
    if not finite(now)then return end
    if not enabled then
      if self.active and (not self.last_restore or now<self.last_restore or now-self.last_restore>=0.25)then self.last_restore=now;self:restore()end
      self.dirty=true;self.last_enabled=false;return
    end
    if self.dirty or not self.last_enabled or not self.last_selection or now<self.last_selection or now-self.last_selection>=0.25 then
      local groups=self:selected();local signature=table.concat(groups,"|")
      self.last_selection=now;self.dirty=false
      if not self.active or signature~=self.signature then self:apply(groups)end
    end
    self.last_enabled=true
    if not self.last_check or now<self.last_check or now-self.last_check>=1 then
      self.last_check=now;self.checks=self.checks+1
      for name,state in pairs(self.saved)do
        local current=self:read(state.ref)
        if current~=nil and current~=state.expected then self.saved[name]=nil;self.conflicts=self.conflicts+1 end
      end
    end
  end
  function M:report_lines()
    local owned=0;for _ in pairs(self.saved)do owned=owned+1 end
    return {string.format("FPS Optimizer enabled=%s state=%s owned_cvars=%d verified_writes=%d restores=%d external_changes=%d unavailable=%d rejected=%d",tostring(env.enabled()),self.state,owned,self.writes,self.restores,self.conflicts,self.unavailable,self.rejected),
      "FPS Optimizer groups="..tostring(self.signature).."; selection_reads="..self.selection_reads.." watchdog_checks="..self.checks.."; selection polling 4Hz, cvar watchdog 1Hz; no per-frame cvar writes; sound reduction opt-in"}
  end
  return M
end

return create_fps_optimizer({
  enabled=function()return get_bool(cfg.fps_optimizer) and not cfg.runtime_paused and not ANEMONE_SECOND_COPY end,
  now=clock,selection=function()return cfg.opt_list:get()end,preset=function()return cfg.opt_preset:get()end,
  ref=function(name)
    local ref=cvar[name];if not ref and cvar.find then ref=cvar.find(name)end;return ref
  end
})
end)()
Y.fps_optimizer=OPT
Y.runtime_perf=(function()
local function create_runtime_profiler(env)
  local M={events={},stride=16}
  function M:begin(name)
    if name~="render" and name~="createmove" and name~="net_update_end" then return nil end
    local q=self.events[name]
    if not q then q={calls=0,samples=0,total=0,max=0};self.events[name]=q end
    q.calls=q.calls+1
    if q.calls%self.stride~=0 then return nil end
    local ok,t=pcall(env.time_us)
    if ok and type(t)=="number" and t==t then return t end
  end
  function M:finish(name,start)
    if start==nil then return end
    local ok,t=pcall(env.time_us);local q=self.events[name]
    if not ok or type(t)~="number" or t~=t or t<start or not q then return end
    local elapsed=t-start
    q.samples=q.samples+1;q.total=q.total+elapsed;q.max=math.max(q.max,elapsed);q.last=elapsed
  end
  function M:report_lines()
    local lines={"FPS callback profiler sample=1/16 events; QueryPerformanceCounter when available; times cover this Lua event chain only, NOT whole-game frame time"}
    for _,name in ipairs({"render","createmove","net_update_end"})do
      local q=self.events[name]
      if q then lines[#lines+1]=string.format("FPS callback %s calls=%d samples=%d mean_ms=%.3f max_ms=%.3f last_ms=%.3f",name,q.calls,q.samples,q.samples>0 and q.total/q.samples/1000 or 0,q.max/1000,(q.last or 0)/1000)end
    end
    return lines
  end
  return M
end

return create_runtime_profiler({time_us=function()return Y.native_trace and Y.native_trace:perf_start()end})
end)()
EVENT_CHAIN.profiler=Y.runtime_perf
pcall(function()cfg.opt_preset:set_callback(function()
  local preset=cfg.opt_preset:get();local values=OPT.presets[preset]or OPT.presets.Recommended
  cfg.opt_list:set(values);OPT.dirty=true;OPT:tick()
end)end)
pcall(function()cfg.opt_list:set_callback(function()OPT.dirty=true;OPT:tick()end)end)
pcall(function()cfg.fps_optimizer:set_callback(function()OPT.dirty=true;OPT:tick()end)end)
local function on_render()
  guarded("native_automatic_policy",function()if Y.native_policy then Y.native_policy:sync() end end)
  guarded("native_selector_trace_sync",function ()
    local perf=Y.native_trace;local started=perf and perf:perf_start()
    if perf then
      local ok,err=pcall(perf.sync,perf,true)
      if not ok then perf.fault=tostring(err):gsub("%c"," "):sub(1,180);perf:stop() end
      perf:perf_finish("trace_sync",started)
    end
  end)
  guarded("native_code_patch_sync",function ()
    if Y.native_patches then Y.native_patches:sync(false) end
  end)
  guarded("native_candidate_preparation",function ()
    local perf=Y.native_trace;local started=perf and perf:perf_start()
    if Y.native_records then Y.native_records:drain_selector() end
    if perf then perf:perf_finish("deferred_selector",started) end
  end)
  guarded("native_own_bank_preparation",function ()
    local perf=Y.native_trace
    if perf and perf.transfer_pipeline and next(perf.transfer_pipeline.candidates)then
      local started=perf:perf_start()
      local ok,err=pcall(perf.prepare_transfers,perf)
      if not ok then perf:clear_transfer_pipeline("preparation stage error");perf.last_error=tostring(err):gsub("%c"," "):sub(1,180) end
      perf:perf_finish("own_prepare",started)
    end
  end)
  guarded("native_own_pointer_publication",function ()
    local perf=Y.native_trace
    if perf and perf.transfer_pipeline and next(perf.transfer_pipeline.ready)then
      local started=perf:perf_start()
      local ok,err=pcall(perf.publish_transfers,perf)
      if not ok then perf:clear_transfer_pipeline("publication stage error");perf.last_error=tostring(err):gsub("%c"," "):sub(1,180) end
      perf:perf_finish("own_publish",started)
    end
  end)
  guarded("native_deferred_collection",function ()
    local perf=Y.native_trace;local started=perf and perf:perf_start()
    if Y.native_records then
      local ok,err=pcall(Y.native_records.drain_collection,Y.native_records)
      if not ok then Y.native_records:collector_error(err) end
    end
    if perf then perf:perf_finish("deferred_collection",started) end
  end)
  guarded("native_trace_diagnostics",function ()
    local perf=Y.native_trace
    if perf then
      local started=perf:perf_start()
      local ok,err=pcall(perf.poll,perf)
      if not ok then perf.fault=tostring(err):gsub("%c"," "):sub(1,180);perf:stop() end
      perf:perf_finish("trace_diagnostics",started)
    end
  end)
  local maintenance_now=clock()
  local ui_due=not OPT.ui_maintenance_at or maintenance_now<OPT.ui_maintenance_at or maintenance_now-OPT.ui_maintenance_at>=0.1
  if ui_due then
    OPT.ui_maintenance_at=maintenance_now
    guarded("menu_section", set_menu_section)
    guarded("settings_visibility", settings_visibility_tick)
    guarded("beta_policy", cfg.version_state.enforce_beta_policy)
    guarded("sidebar_theme", update_sidebar_theme)
  end
  guarded("fps_opt", function ()
    OPT:tick()
  end)
  if not OPT.diagnostics_maintenance_at or maintenance_now<OPT.diagnostics_maintenance_at or maintenance_now-OPT.diagnostics_maintenance_at>=0.25 then
    OPT.diagnostics_maintenance_at=maintenance_now;D:guard(D.sync);D:guard(D.scan)
  end
  R:guard(R.frame)
  guarded("aspect", aspect_tick)
  guarded("crosshair_indicator", crosshair_indicator_tick)
  guarded("side_indicators", side_indicator_tick)
  guarded("damage_indicator", damage_indicator_tick)
  guarded("interpolation", interpolation_tick)
  guarded("hit_effect", hit_effect_tick)
  guarded("hotkeys", hotkeys_tick)
  guarded("clantag", clan_tick)
  local t = clock()
  if t < last_maintenance or t - last_maintenance >= 0.25 then
    last_maintenance = t
    UR:guard(UR.idle)
    guarded("trash_talk", LTRASH.tick)
  end
end
local function on_config(state)
  Y.core:reset()
  OPT.ui_maintenance_at=nil;OPT.diagnostics_maintenance_at=nil;OPT.dirty=true
  if state == "pre_load" or state == "pre_save" then
    cfg.runtime_paused=true
    OPT:tick()
    if Y.steam_exclusion then pcall(Y.steam_exclusion.sync,Y.steam_exclusion) end
    R.suspended,D.suspended,UR.suspended,Y.suspended=true,true,true,true
    FS:release_hc();FS:air_finish("config transaction")
    if FS.spread_sampler then FS.spread_sampler:clear()end
    AH:reset()
    D:guard(D.sync)
    R:guard(R.reset, "config transaction; requests released")
    UR:guard(UR.reset)
    MD:release("config transaction")
  elseif state == "post_load" or state == "post_save" then
    cfg.runtime_paused=false
    OPT:tick()
    R.suspended,D.suspended,UR.suspended,Y.suspended=false,false,false,false
    Y.fault = nil
    pcall(function ()
      N:request("dormant", nil)
    end)
    ;
    D:guard(D.sync)
    R:guard(R.reset, "config transaction complete")
    UR:guard(UR.reset)
    MD:release("config transaction complete")
  end
end
local function shutdown()
  if Y.steam_exclusion then pcall(Y.steam_exclusion.restore_all,Y.steam_exclusion) end
  if Y.native_trace then pcall(Y.native_trace.stop,Y.native_trace) end
  if Y.native_records then Y.native_records:reset() end
  pcall(function ()
    cfg.version_state.boot_lock = true
    cfg.version_beta:set(true)
  end)
  R.suspended, D.suspended, UR.suspended, Y.suspended = true, true, true, true
  UR:guard(UR.reset)
  MD:release("shutdown")
  Y:guard(Y.reset, "shutdown; yaw released")
  pcall(function ()
    Y.miss_state.miss_log = Y.miss_log
    Y.miss_state.bucket_stats = Y.bucket_stats
    Y.miss_state.miss_counts = Y.miss_counts
    Y.miss_state.ack_stats = Y.ack_stats
    Y.miss_state.mode_stats = Y.mode_stats
    Y.miss_state.delta_stats = Y.delta_stats
    Y.miss_state.population = Y.population
    _G.__ANEMONE_MISS_STATE_V2 = Y.miss_state
    Y.shots, Y.learn = { }, { }
  end)
  guarded("adaptive_helpers_cleanup", function () AH:shutdown() end)
  guarded("native_cleanup", function ()
    if not N:release_all() then
      console_line("[Anemone] Native release NOT verified. Check Safe Points in the native menu.")
    end
  end)
  guarded("aspect_cleanup", restore_aspect)
  guarded("interpolation_cleanup", interpolation_restore)
  guarded("kill_particles_cleanup", kill_particle_clear)
  guarded("hit_effect_cleanup", hit_effect_clear)
  guarded("model_changer_cleanup", model_changer_restore)
  guarded("clantag_cleanup", release_clan)
  guarded("optimizer_cleanup", function ()
    OPT:restore()
  end)
  pcall(function ()
    if _G.__ANEMONE_AA_HELD then
      for _, h in ipairs(_G.__ANEMONE_AA_HELD) do
        pcall(function ()
          h.ref:override()
        end)
      end
      _G.__ANEMONE_AA_HELD = nil
    end
  end)
  pcall(function ()
    if type(FS) == "table" and FS.release_hc then
      FS:release_hc()
    end
  end)
end
chain("shutdown", shutdown)
local wm_tick, nl_tick, evalate_tick
do
  local wm = {
    alpha = 0,
    kills = 0,
    deaths = 0,
    fps = 0,
    var = 0,
    ping = 0,
    last_update = 0,
    ft_samples = { },
    ft_count = 0,
  }
  local font_main, font_small
  local function wm_fonts()
    if font_main then
      return
    end
    local ok_main, f_main = pcall(render.load_font, "Verdana", 12, "a")
    local ok_small, f_small = pcall(render.load_font, "Verdana", 10, "a")
    font_main = (ok_main and f_main) or 2
    font_small = (ok_small and f_small) or 2
  end
  local function wm_section_font(flags)
    return flags == "-" and font_small or font_main
  end
  local function wm_text(x, y, c, alpha, flags, text)
    render.text(wm_section_font(flags), vector(x, y), color(c[1], c[2], c[3], math.floor((c[4] or 255) * alpha)), nil, text)
  end
  local function wm_measure(flags, text)
    local ok, size = pcall(render.measure_text, wm_section_font(flags), nil, text)
    if ok and size then
      return size.x or 0, size.y or 0
    end
    return 0, 0
  end
  local function wm_gradient(x, y, w, h, left_a, right_a)
    render.gradient(vector(x, y), vector(x + w, y + h), color(0, 0, 0, left_a), color(0, 0, 0, right_a), color(0, 0, 0, left_a), color(0, 0, 0, right_a))
  end
  local function wm_draw_shadow(x, y, w, h, alpha)
    local center = math.floor(0.5 + w * 0.5)
    local edge_a = math.floor(22 * alpha)
    local center_a = math.floor(125 * alpha)
    wm_gradient(x, y, center, h, edge_a, center_a)
    wm_gradient(x + center, y, w - center, h, center_a, edge_a)
  end
  local function wm_draw_outline(x, y, w, h, alpha)
    local center = math.floor(0.5 + w * 0.5)
    local center_a = math.floor(40 * alpha)
    wm_gradient(x, y, center, 1, 0, center_a)
    wm_gradient(x + center, y, w - center, 1, center_a, 0)
    wm_gradient(x, y + h - 1, center, 1, 0, center_a)
    wm_gradient(x + center, y + h - 1, w - center, 1, center_a, 0)
  end
  local function wm_metric_color(value, good_limit, warning_limit, lower_is_better, good_color)
    local red = { 139, 31, 31, 255 }
    local green = good_color or { 146, 183, 51, 255 }
    local orange = { 183, 121, 51, 255 }
    if lower_is_better then
      if value < good_limit then
        return green
      end
      if value < warning_limit then
        return orange
      end
      return red
    end
    if value < good_limit then
      return red
    end
    if value < warning_limit then
      return orange
    end
    return green
  end
  local function wm_selected(name)
    local ok, sel = pcall(function ()
      return cfg.wm_elements:get()
    end)
    if not ok or type(sel) ~= "table" then
      return false
    end
    for _, v in ipairs(sel) do
      if v == name then
        return true
      end
    end
    if sel[name] == true then
      return true
    end
    return false
  end
  local function wm_position()
    local ok, v = pcall(function ()
      return cfg.wm_position:get()
    end)
    return (ok and type(v) == "string") and v or "Top-right"
  end
  local function wm_accent()
    local ok, c = pcall(function ()
      return cfg.wm_accent:get()
    end)
    if ok and c then
      local r, g, b = tonumber(c.r), tonumber(c.g), tonumber(c.b)
      if r and g and b then
        return { r, g, b, 255 }
      end
    end
    return { 159, 202, 43, 255 }
  end
  local function wm_speed()
    local lp = entity.get_local_player()
    if not lp then
      return 0
    end
    local ok, v = pcall(function ()
      return lp.m_vecVelocity
    end)
    if not ok or v == nil then
      return 0
    end
    local vx, vy = 0, 0
    pcall(function ()
      vx, vy = v.x or 0, v.y or 0
    end)
    return math.floor(math.sqrt(vx * vx + vy * vy))
  end
  local function wm_clock_text()
    local ok, t = pcall(function ()
      return common.get_system_time()
    end)
    if ok and type(t) == "table" then
      local h = tonumber(t.hours) or 0
      local m = tonumber(t.minutes) or 0
      local s = tonumber(t.seconds) or 0
      return string.format("%02d:%02d:%02d", h, m, s)
    end
    local ok2, s = pcall(function ()
      return common.get_date("%H:%M:%S")
    end)
    if ok2 and type(s) == "string" then
      return s
    end
    return "--:--:--"
  end
  local function wm_update_metrics(ft)
    wm.ft_count = wm.ft_count + 1
    wm.ft_samples[(wm.ft_count % 100) + 1] = ft
    local now = number(globals.realtime) or 0
    if now - wm.last_update <= 0.5 then
      return
    end
    wm.last_update = now
    wm.fps = ft > 0 and math.floor(0.5 + 1 / ft) or 0
    local n = math.min(wm.ft_count, 100)
    if n > 1 then
      local sum = 0
      for i = 1, n do
        sum = sum + (wm.ft_samples[i] or 0)
      end
      local mean = sum / n
      local acc = 0
      for i = 1, n do
        local d = (wm.ft_samples[i] or 0) - mean
        acc = acc + d * d
      end
      wm.var = math.floor(0.5 + math.sqrt(acc / n) * 1000)
    end
    wm.ping = 0
    if globals.is_connected then
      local ok, net = pcall(utils.net_channel)
      if ok and net and net.avg_latency then
        local l = net.avg_latency[0]
        if type(l) == "number" then
          wm.ping = math.floor(0.5 + l * 1000)
        end
      end
    end
  end
  chain("player_death", function (e)
    pcall(function ()
      local me = entity.get_local_player()
      if not me then
        return
      end
      local victim = entity.get(e.userid, true)
      local attacker = entity.get(e.attacker, true)
      if victim == me then
        wm.deaths = wm.deaths + 1
      end
      if attacker == me and victim ~= me then
        wm.kills = wm.kills + 1
      end
    end)
  end)
  wm_tick = function ()
    wm_fonts()
    local enabled = get_bool(cfg.watermark)
    local ft = number(globals.frametime) or 0
    local target = enabled and 1 or 0
    wm.alpha = wm.alpha + (target - wm.alpha) * math.min(1, ft * 12)
    if not enabled and wm.alpha <= 0.01 then
      wm.alpha = 0
      return
    end
    local alpha = wm.alpha
    local style = wm_read_style()
    if style == "Evalate" then
      if evalate_tick then
        evalate_tick(alpha)
      end
      return
    end
    if style == "Neverlose" then
      nl_tick(alpha)
      return
    end
    wm_update_metrics(ft)
    local accent = wm_accent()
    local white = { 194, 194, 194, 255 }
    local function section(c, flags, text, shift_x, shift_y)
      return {
        color = c,
        flags = flags or "",
        text = tostring(text or ""),
        shift_x = shift_x or 0,
        shift_y = shift_y or 0
      }
    end
    local list = { }
    if wm_selected("Logo") then
      list[# list + 1] = {
        section({ 255, 255, 255, 255 }, "", "game"),
        section(accent, "", "sense"),
      }
    end
    if wm_selected("FPS") then
      list[# list + 1] = {
        section(wm_metric_color(wm.fps, 60, 120, false, accent), "", wm.fps),
        section(white, "-", "FPS", 1, 2),
      }
    end
    if wm_selected("Frametime variance") then
      list[# list + 1] = {
        section(wm_metric_color(wm.var, 2, 3, true, accent), "", wm.var),
        section(white, "-", "VAR", 1, 2),
      }
    end
    if wm_selected("Ping") then
      list[# list + 1] = {
        section(wm_metric_color(wm.ping, 40, 100, true, accent), "", wm.ping),
        section(white, "-", "PING", 1, 2),
      }
    end
    if wm_selected("Speed") then
      list[# list + 1] = { section(white, "", wm_speed()), section(white, "-", "SPEED", 1, 2), }
    end
    if wm_selected("K/D ratio") then
      local kd = wm.deaths > 0 and wm.kills / wm.deaths or wm.kills
      local kd_color = kd > 2 and accent or ((kd > 0 and kd < 1) and { 139, 31, 31, 255 } or { 183, 121, 51, 255 })
      list[# list + 1] = {
        section(kd_color, "", string.format("%.1f", kd)),
        section(white, "-", "K/D", 1, 2),
      }
    end
    if wm_selected("Clock") then
      list[# list + 1] = { section(white, "", wm_clock_text()) }
    end
    if # list == 0 then
      return
    end
    local measures, total_width = { }, 0
    for i = 1, # list do
      measures[i] = { }
      for j = 1, # list[i] do
        local s = list[i][j]
        local tw, th = wm_measure(s.flags, s.text)
        measures[i][j] = { x = tw, y = th }
        total_width = total_width + tw + s.shift_x
      end
      if i ~= # list then
        total_width = total_width + 12
      end
    end
    local height = 20
    local width = total_width + 15
    local screen = render.screen_size()
    local sw, sh = screen.x, screen.y
    local x, y = sw - width - 5, 5
    if wm_position() == "Bottom-center" then
      x = (sw - width) / 2
      y = sh - height - 5
    end
    wm_draw_shadow(x - 10, y, width + 20, height, alpha)
    wm_draw_outline(x - 10, y, width + 20, height, alpha)
    local draw_x = x + 5
    local offset = 0
    for i = 1, # list do
      for j = 1, # list[i] do
        local s = list[i][j]
        local size = measures[i][j]
        local ty = y + math.floor((height - size.y) * 0.5)
        wm_text(draw_x + offset + s.shift_x, ty, s.color, alpha, s.flags, s.text)
        offset = offset + size.x
      end
      offset = offset + 12
    end
  end
end
do
  local ev = { content_alpha = 0, fps = 0, fps_at = 0, header_font = nil, content_font = nil }
  local function ev_lerp(a, b, speed)
    local ft = number(globals and (globals.absoluteframetime or globals.frametime)) or 0.016
    return a + (b - a) * clamp(ft * speed, 0, 1)
  end
  local function ev_fonts()
    if ev.header_font and ev.content_font then
      return
    end
    local ok1, f1 = pcall(render.load_font, "arial", 14, "ad")
    local ok2, f2 = pcall(render.load_font, "arial", vector(13, 11), "a")
    ev.header_font = (ok1 and f1) or 2
    ev.content_font = (ok2 and f2) or 2
  end
  local function ev_measure(font, text)
    local ok, v = pcall(render.measure_text, font, nil, tostring(text or ""))
    return (ok and v and number(v.x)) or 0, (ok and v and number(v.y)) or 11
  end
  local function ev_read(ref, default)
    if not ref then
      return default
    end
    local ok, v = pcall(function ()
      return ref:get()
    end)
    return ok and v or default
  end
  local function ev_username()
    local source = ev_read(cfg.wm_eval_username_source, "Cheat")
    if source == "Custom" then
      local v = ev_read(cfg.wm_eval_username_custom, "")
      if type(v) == "string" and v ~= "" then
        return v
      end
    elseif source == "Steam" then
      local ok, v = pcall(function ()
        local me = entity.get_local_player()
        return me and me:get_name() or nil
      end)
      if ok and type(v) == "string" and v ~= "" then
        return v
      end
    end
    local ok, v = pcall(function ()
      return common.get_username()
    end)
    return (ok and type(v) == "string" and v ~= "") and v or "user"
  end
  local function ev_latency()
    local value = 0
    pcall(function ()
      local net = utils.net_channel()
      if net and net.avg_latency and number(net.avg_latency[0]) then
        value = math.floor(net.avg_latency[0] * 1000 + 0.5)
      end
    end)
    return value
  end
  local function ev_time()
    local fmt = ev_read(cfg.wm_eval_time_format, "24h") == "12h" and "%I:%M %p" or "%H:%M"
    local ok, v = pcall(function ()
      return common.get_date(fmt)
    end)
    return (ok and type(v) == "string") and v:lower() or "--:--"
  end
  local function ev_items()
    local now = number(globals and globals.realtime) or 0
    if now - ev.fps_at > 0.8 then
      local ft = number(globals and (globals.absoluteframetime or globals.frametime)) or 0
      ev.fps = ft > 0 and math.floor(1 / ft + 0.5) or 0
      ev.fps_at = now
    end
    local out = { }
    local function add(ic, value)
      out[# out + 1] = { icon = ic, value = tostring(value) }
    end
    if wm_eval_elem_enabled("Version") then
      add("</>", "Beta")
    end
    if wm_eval_elem_enabled("Username") then
      add("@", ev_username())
    end
    if wm_eval_elem_enabled("Latency") and globals and globals.is_connected then
      add("↻", string.format("%i ms", ev_latency()))
    end
    if wm_eval_elem_enabled("Frames") then
      add("▣", string.format("%i fps", ev.fps))
    end
    if wm_eval_elem_enabled("Time") then
      add("◷", ev_time())
    end
    return out
  end
  local function ev_pill(x, y, content_w, alpha, accent)
    local padding = vector(25, 13)
    local height, rounding, spread = 12, 12, 70
    local p1, p2 = vector(x, y), vector(x, y) + padding + vector(content_w, height)
    local center = (p1 + vector(padding.x / 2, height / 2 + padding.y / 2)):floor()
    local glow_size = vector(content_w, 2):floor()
    pcall(function ()
      render.rect(center, center + glow_size, color(accent.r, accent.g, accent.b, math.floor(65 * alpha * ((number(accent.a) or 255) / 255))), rounding)
    end)
    pcall(function ()
      render.shadow(center, center + glow_size, color(accent.r, accent.g, accent.b, math.floor(255 * alpha * ((number(accent.a) or 255) / 255))), spread, 0, rounding)
    end)
    pcall(function ()
      render.blur(p1, p2, 0, alpha, rounding)
    end)
    render.rect(p1, p2, color(150, 150, 150, math.floor(40 * alpha)), rounding)
    pcall(function ()
      render.rect_outline(p1, p2, color(255, 255, 255, math.floor(20 * alpha)), 1, rounding)
    end)
    return padding
  end
  local function ev_header(x, y, alpha, accent)
    local cursor = x
    local now = number(globals and globals.realtime) or 0
    for i, ch in ipairs({ "𝒆", "𝒗", "𝒂", "𝒍", "𝒂", "𝒕", "𝒆" }) do
      local wave = (math.sin(now * 2.4 - i * 0.72) + 1) * 0.5
      local a = math.floor(255 * alpha * (0.35 + 0.65 * wave))
      render.text(ev.header_font, vector(cursor, y), color(accent.r, accent.g, accent.b, math.floor(a * ((number(accent.a) or 255) / 255))), nil, ch)
      cursor = cursor + ev_measure(ev.header_font, ch)
    end
  end
  evalate_tick = function (alpha)
    if not alpha or alpha <= 0 then
      return
    end
    ev_fonts()
    local accent = wm_eval_accent_color()
    local items = ev_items()
    ev.content_alpha = ev_lerp(ev.content_alpha, # items > 0 and 1 or 0, 10)
    local header = "𝒆𝒗𝒂𝒍𝒂𝒕𝒆"
    local header_w = ev_measure(ev.header_font, header)
    local content_w, gap = 0, 14
    local sizes = { }
    for i, it in ipairs(items) do
      local iw, ih = ev_measure(ev.content_font, it.icon)
      local vw, vh = ev_measure(ev.content_font, it.value)
      sizes[i] = { iw = iw, ih = ih, vw = vw, vh = vh }
      content_w = content_w + iw + 5 + vw + (i < # items and gap or 0)
    end
    local content_anim_w = content_w * ev.content_alpha
    local total = header_w + 25 + (5 + content_w + 25) * ev.content_alpha
    local screen = render.screen_size()
    local pos = ev_read(cfg.wm_position, "Top-right")
    local x, y = screen.x - total - 10, 10 * alpha
    if pos == "Top-left" then
      x = 10
    elseif pos == "Bottom-center" then
      x = screen.x / 2 - total / 2
      ;
      y = screen.y - 44 * alpha
    end
    local pad = ev_pill(x, y, header_w, alpha, accent)
    ev_header(x + pad.x / 2, y + pad.y / 2 - 2, alpha, accent)
    if ev.content_alpha > 0.01 and # items > 0 then
      local cx = x + header_w + 25 + 5
      local ca = alpha * ev.content_alpha
      local cpad = ev_pill(cx, y, content_anim_w, ca, accent)
      local cursor = cx + cpad.x / 2
      for i, it in ipairs(items) do
        local m = sizes[i]
        local ty = y + cpad.y / 2
        render.text(ev.content_font, vector(cursor, ty), color(accent.r, accent.g, accent.b, math.floor(255 * ca * ((number(accent.a) or 255) / 255))), nil, it.icon)
        cursor = cursor + m.iw + 5
        render.text(ev.content_font, vector(cursor, ty), color(240, 240, 240, math.floor(255 * ca)), nil, it.value)
        cursor = cursor + m.vw + gap
      end
    end
  end
end
;(function ()
  local nl_ico_raw = {
    user = "iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAQAAAC1QeVaAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAACYktHRAAAqo0jMgAAAAd0SU1FB+oIDwgeLYyV+8EAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjYtMDgtMTVUMDg6MzA6NDUrMDA6MDCfoKOTAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI2LTA4LTE1VDA4OjMwOjQ1KzAwOjAw7v0bLwAAACh0RVh0ZGF0ZTp0aW1lc3RhbXAAMjAyNi0wOC0xNVQwODozMDo0NSswMDowMLnoOvAAAAB1elRYdHN2Zzpjb21tZW50AAAImVN0y88rUXAsTy3Oz01VcCtKTVUw1zPWM1RIqlRwSAPKJUKldBUySkoKiq309ZFE9ZLzcxV8MpNT84rxqNDPgajQTwMZ75xfUFmUmZ5RomBkYGSmALI/Mzk/r1hHwTMvWQ8ABXAx8CqAOMQAAACzSURBVBjTZZC9agJREEbPlQ3+NYFNmTbgG2hrayE+QMDK50iTl3AhD5Eu0UJtBF/DVtDGJXbH5m7ubvIVw8AZvvlmAgBIUyHViJ4ZE9hyTBgQ8cW9qgcH1p1EfLPSewVbvxP5/y7BNVcASlaNbCJmvvrlt3MfKttQO6PPE4ETZXVOFsEjC2bkwJlPCi7JsuvSuj7siRFO/GnAm1Mxph3SaSRsMwLizh1F+hcAG4Dw9+V13QFwg2bHk3mbwgAAAABJRU5ErkJggg==",
    fps = "iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAYAAAAfSC3RAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAcElEQVR4nOWSMQqAMAxFCw6Cg1OX4iC4O4gXcPAq7YUcpKd9EqiYoYMZnPwQyM/P275zXwsYgQnoLNDMo0MHA7ADG9BUwFWBWQenChYLmFUgTwFIZYIFjMpHC5iUT38HfamTTAv0yssut9v715Wr6QJiYqmSoSEP8wAAAABJRU5ErkJggg==",
    ping = "iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAQAAAC1QeVaAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAACYktHRAAAqo0jMgAAAAd0SU1FB+oIDwgiNewKGmgAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjYtMDgtMTVUMDg6MzQ6NTMrMDA6MDA5MTZNAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI2LTA4LTE1VDA4OjM0OjUzKzAwOjAwSGyO8QAAACh0RVh0ZGF0ZTp0aW1lc3RhbXAAMjAyNi0wOC0xNVQwODozNDo1MyswMDowMB95ry4AAAB1elRYdHN2Zzpjb21tZW50AAAImVN0y88rUXAsTy3Oz01VcCtKTVUw1zPWM1RIqlRwSAPKJUKldBUySkoKiq309ZFE9ZLzcxV8MpNT84rxqNDPgajQTwMZ75xfUFmUmZ5RomBkYGSmALI/Mzk/r1hHwTMvWQ8ABXAx8CqAOMQAAACiSURBVBjTbc8/UsJgEIbxX0LQgRlGC6W2omGA23AFGi28AnfA03ihhKGwscgQliIEPzBb7b/32XfpjRCbKIv75jVeTPMe2dhTm/QN3+0MBUUPcGbl8b9yYoLQtGVqKLfF5x+kSIADc5Gud9hnY+HklF7JA0a+fIjUVYt99ePBwq/s/qfct7VGcwvslEtvyGRctFnHKFT2aqXKUYmjSql2UJ0BVLEpJKBtW7EAAAAASUVORK5CYII=",
    loss = "iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAQAAAC1QeVaAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAACYktHRAAAqo0jMgAAAAd0SU1FB+oIDwkOBmspeucAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjYtMDgtMTVUMDk6MTQ6MDYrMDA6MDCmE3fKAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI2LTA4LTE1VDA5OjE0OjA2KzAwOjAw107PdgAAACh0RVh0ZGF0ZTp0aW1lc3RhbXAAMjAyNi0wOC0xNVQwOToxNDowNiswMDowMIBb7qkAAADVSURBVBjTbY8hS0NhGEbPtzvvFEwmBwYt3mBZNZkG02IbmkSFZeN+gbA/sSZrVvEHmMQyGIjJZBLBCbKx7R6Dn5epO+m8nKe8EBFx2aqpyB/ExJY3Nv9FEXd9Uftmv7KIq/acqiM7JnNZxAs//ObZ/SKKmHmnvtt2onZdE2NKvTRXXz1wrI49ESkBsMcxAQhUCEDKEVtQAtY5ZROAMhkBgAaHpJh47g8z38yjP1nDHe+L+OmV0+i513hWbHXkrbPisswjA7bjw4E6k+g5D8ElNlhhEcMvpM27GnDpAHMAAAAASUVORK5CYII=",
    clock = "iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAYAAAAfSC3RAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAzElEQVR4nK2SQQ6CMBBFWekxRG9hDLpy7QrW4plYWMGQeBj1AHoUdPnMT4ak1gYX2uQnzHReO/NpkvxrASvgCFyAM9AAyyFgDJyADnDA1uQs16omBgq6AROL15J9p7bXxtrershyleTFqdVkPqiZ9sFhlQ9a7gDUfuIKlBGwCXI7mfYN3ABPoBgCZbmLGFYYnFtcq12/ILPBpxE4B+bADHgAi7BA/0mWpxFY0F0mhnv9AxCsm+VeaVJ7uknOjz7AoG3NrOcmCXxv75f1AuUNNMS82KlpAAAAAElFTkSuQmCC",
    neverlose = "iVBORw0KGgoAAAANSUhEUgAAABYAAAAWCAMAAADzapwJAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAJMUExURQAAAOXq7PLy9Pj4+v////r6/Pr6+6fBzxFagBZaf1FcYND1/67d8+/z9gmr9AhZfzZ2lVGHopy4xf///zM+QwpXfCdukVGJo5m2xf///wVRcw5dhUB+mmGOo+Lk5fz6+wxsm/f5+fz9/f///wAAAANhkPf6+////wBJcyKBrfH19vv8+/n4+wx7sP7+/v3+/wRqnP///wBKdSWUx/7+/vr6/Ax5r/3+/eHZ1QRpnQBKdyWTx/7+/vr6+wx5r/7+/fn3+AFonABKeCSTx/z7+ymAqySTxvr6/P///YG61ABKegx6r/f8/WXF7gBKewx6r/7+/XvI613D7////wBKef39/v/8/gx6sP3+/OXu9Ram5wBKdfr8+6C8ygAUSQAuXwAGPvz9/Pz69wCS4Um87SSTxu/19nqluV2Rql2Tq3qkt/b39wx6sPT29g+l6ABLdSSTx/39/A+Bt/n8/PP19wCa4zW07f7//gBFbyibzfr8/BWf21zA6YHO653U6vDx9A+i5FO96YDN6o/R6tru9CWm23DH64HO7IHP7ILP7YLP7YLO7IPP7LXg7p/M3+3z9W2x0Ozz9cvk7q3g9f///3jH6t71/a3g9P///v/+/v7//nfG6d30/f7+/f7+/t31/fj8+uv3+nbG6fH6/KXd8/b8/XjH68Dp+Nnv+JjX8vz+/f7///P7/fv+/trw9/v9/dz1/ang9v///f7+/9z0/eb2+6zf9I7W9P7//fX5+vT4+ff6+6rg9P3//dDv+fv+/dnz/P3//vz+/gAAADE0SbgAAACOdFJOUwAAAAAAAAAAAAAAAAAAAMnQymIUAonQyWUXN8zVqTgG9veVBAKq9nJC+v7NGfPxRql8QffcG/S3D6ZA99sa9fpjoz/30cH3Gv74PvT88j7z95fuez7cG/T5UZo/3igNDwj6SSvj+PTKy82cRPZMfkD46Mn6SxrMfSvc7mbw9sQjZvP23kSW9/Ly8vHy8JssXrF2AAAAAWJLR0QAiAUdSAAAAAd0SU1FB+oIDwgxCjuDdscAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjYtMDgtMTVUMDg6NDg6MzcrMDA6MDA4Fu7UAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI2LTA4LTE1VDA4OjQ4OjM3KzAwOjAwSUtWaAAAACh0RVh0ZGF0ZTp0aW1lc3RhbXAAMjAyNi0wOC0xNVQwODo0OToxMCswMDowMHYeJXoAAAExSURBVBjTY2CgIeAXEBQSZhQRFROXkJSSlpGVk2cCCSv09SsqKauoTpiopq6hOUlLW4cZJKw7ecoUPX0Wg6lTphgaGU+bYmLKChI2mz5j5ixzC8vZQGEr6zlTbGzZQMJ202fMnWfv4AgSdnKejyS8YOE8F9dFIGE3oLA7K1R48ZKlHp7LZkwx9AKpdger9p4+w8d3+YwVK1etNvQDCkOt9J8+IyAwaM3adetnBIc4b5gRGsbOwcnFED59RkRk1MZNm1dPCY5227IpJjYuPoEFZEhiUnLK1ilTpgQbpW6YkpaekZmVzZCzbVNiLnfe9rlzdxjmF8yZsWrnrl27CxmK9uwtLuEpLdu3an95ReWBg2sPHVq7v4qhuqa2rp6Xr6GxqbmFpbWtvaOzq7unl5aRAwCBLnQTxYlAtQAAAABJRU5ErkJggg==",
    sqrt = "iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAYAAAAfSC3RAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAmUlEQVR4nM3QMQ4BQRQG4G01NgoaHdFqtEq1zgE0XIALqFxA4wYah3AHN9CQaEgUIj7ZZIolWUYh8SeTTF7mS/43SfKXQRujcIYox6AyDp4ziIEz3NBBBWkMquGEZdGDJnrovswXuKBeBDe5/uMwa+GK+btKKRpY4xzuKxyzvWJ2qmKPLe6YfkQ53A+VdyhFw4An2Wd9hX6eB259snjhlCxcAAAAAElFTkSuQmCC",
  }
  local function nl_b64dec(data)
    local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    data = data:gsub("[^" .. b .. "=]", "")
    return (data:gsub(".", function (x)
      if x == "=" then
        return ""
      end
      local r, f = "", (b:find(x, 1, true) - 1)
      for i = 6, 1, - 1 do
        r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) >= 1 and "1" or "0")
      end
      return r
    end):gsub("%d%d%d?%d?%d?%d?%d?%d?", function (x)
      if # x ~= 8 then
        return ""
      end
      local c = 0
      for i = 1, 8 do
        c = c + (x:sub(i, i) == "1" and 2 ^ (8 - i) or 0)
      end
      return string.char(c)
    end))
  end
  local nl = {
    master_alpha = 0.0,
    held_w = 0.0,
    shrink_start = nil,
    SHRINK_DELAY = 5.0,
    last_vis_count = 0,
    last_t = nil,
    order = { "username", "clock", "fps", "ping", "var", "loss", "timeout" },
    blocks = { },
    prev_block_visible = nil,
    releasing = false,
    release_start = nil,
    loss_hide_timer = nil,
    loss_was_bad = false,
    var_hide_timer = nil,
    var_was_bad = false,
    HIDE_DELAY = 5.0,
    ft_samples = { },
    ft_count = 0,
    cache = {
      uname = "user",
      time_str = "00:00",
      ping = 0,
      fps = 0,
      loss = 0,
      var = 0,
      last_update = 0
    },
    tex = { },
    tex_loaded = false,
    av_tex = nil,
    av_next_try = 0,
    font = nil,
  }
  local function nl_lerp(a, b, t)
    t = clamp(t or 0, 0, 1)
    return a + (b - a) * t
  end
  local function nl_get_font()
    if nl.font then
      return nl.font
    end
    local ok, f = pcall(render.load_font, "Verdana", 12, "ab")
    nl.font = (ok and f) or 4
    return nl.font
  end
  local function nl_text_w(text)
    local ok, size = pcall(render.measure_text, nl_get_font(), nil, tostring(text or ""))
    return (ok and size and size.x) or 0
  end
  local function nl_text_h()
    local ok, size = pcall(render.measure_text, nl_get_font(), nil, "0")
    return (ok and size and size.y) or 12
  end
  local function nl_text(x, y, r, g, b, a, text)
    render.text(nl_get_font(), vector(x, y), color(r, g, b, a), nil, tostring(text or ""))
  end
  local function nl_round_rect(x, y, w, h, radius, clr)
    radius = math.min(w / 2, h / 2, radius)
    render.rect(vector(x, y), vector(x + w, y + h), color(clr[1], clr[2], clr[3], clr[4]), radius)
  end
  local NL_DEFAULT_ELEMENTS = { Avatar = true, Username = true, Clock = true, FPS = true, Ping = true, Build = true }
  local function nl_element_enabled(name)
    local ok, sel = pcall(function ()
      return cfg.wm_nl_elements:get()
    end)
    if not ok or type(sel) ~= "table" then
      return NL_DEFAULT_ELEMENTS[name] == true
    end
    local any = false
    for _, v in ipairs(sel) do
      any = true
      if v == name then
        return true
      end
    end
    for key, value in pairs(sel) do
      if value == true then
        any = true
        if key == name then
          return true
        end
      end
    end
    if not any then
      return NL_DEFAULT_ELEMENTS[name] == true
    end
    return false
  end
  local NL_BLOCK_LABEL = {
    avatar = "Avatar",
    username = "Username",
    clock = "Clock",
    fps = "FPS",
    ping = "Ping",
    var = "Var",
    loss = "Loss",
    timeout = "Build",
  }
  local function nl_block_enabled(id)
    local label_name = NL_BLOCK_LABEL[id]
    if not label_name then
      return true
    end
    return nl_element_enabled(label_name)
  end
  local function nl_menu_open()
    local ok, a = pcall(ui.get_alpha)
    return ok and type(a) == "number" and a > 0
  end
  local function nl_accent()
    local ok, c = pcall(function ()
      return cfg.wm_nl_accent:get()
    end)
    if ok and c then
      local r, g, b = tonumber(c.r), tonumber(c.g), tonumber(c.b)
      if r and g and b then
        return { r, g, b }
      end
    end
    return { 185, 190, 255 }
  end
  local function nl_time_hm()
    local ok, t = pcall(function ()
      return common.get_system_time()
    end)
    if ok and type(t) == "table" then
      return string.format("%02d:%02d", tonumber(t.hours) or 0, tonumber(t.minutes) or 0)
    end
    return "00:00"
  end
  local NL_ICON_SIZE = {
    user = 14,
    fps = 14,
    ping = 14,
    loss = 14,
    clock = 14,
    neverlose = 22,
    sqrt = 14
  }
  local function nl_ensure_tex()
    if nl.tex_loaded then
      return
    end
    nl.tex_loaded = true
    for name, raw in pairs(nl_ico_raw) do
      local ok, img = pcall(function ()
        return render.load_image(nl_b64dec(raw), vector(NL_ICON_SIZE[name], NL_ICON_SIZE[name]))
      end)
      if ok and img then
        nl.tex[name] = img
      end
    end
  end
  local function nl_try_avatar()
    if nl.av_tex then
      return
    end
    local now = number(globals.realtime) or 0
    if now < nl.av_next_try then
      return
    end
    nl.av_next_try = now + 2
    local ok, img = pcall(function ()
      local lp = entity.get_local_player()
      return lp and lp:get_steam_avatar() or nil
    end)
    if ok and img then
      nl.av_tex = img
    end
  end
  local function nl_draw_bg(x, y, w, h, rad)
    rad = rad or math.floor(h / 2)
    if w <= 0 or h <= 0 then
      return
    end
    if nl_element_enabled("Blur") then
      pcall(function ()
        render.blur(vector(x, y), vector(x + w, y + h), 8, 0.9, rad)
      end)
    end
    nl_round_rect(x, y, w, h, rad, { 10, 10, 10, 150 })
  end
  local function nl_draw_gray_shadow(x, y, w, h, alpha)
    if w <= 0 or h <= 0 or alpha <= 0 then
      return
    end
    local rad = math.floor(h / 2)
    nl_round_rect(x - 2, y - 2, w + 4, h + 4, rad + 2, { 78, 82, 90, math.floor(34 * alpha) })
    nl_round_rect(x - 4, y - 4, w + 8, h + 8, rad + 4, { 64, 68, 75, math.floor(18 * alpha) })
    nl_round_rect(x - 7, y - 7, w + 14, h + 14, rad + 7, { 52, 55, 62, math.floor(8 * alpha) })
  end
  local function nl_update_metrics(ft)
    nl.ft_count = nl.ft_count + 1
    nl.ft_samples[(nl.ft_count % 100) + 1] = ft
    local now = number(globals.realtime) or 0
    if now - nl.cache.last_update < 0.5 then
      return
    end
    nl.cache.last_update = now
    local raw_fps = ft > 0 and (1 / ft) or 0
    nl.cache.fps = clamp(nl.cache.fps * 0.7 + raw_fps * 0.3, 0, 6107)
    local n = math.min(nl.ft_count, 100)
    if n > 1 then
      local sum = 0
      for i = 1, n do
        sum = sum + (nl.ft_samples[i] or 0)
      end
      local mean = sum / n
      local acc = 0
      for i = 1, n do
        local d = (nl.ft_samples[i] or 0) - mean
        acc = acc + d * d
      end
      nl.cache.var = math.floor(math.sqrt(acc / n) * 1000)
    end
    local ping, loss = 0, 0
    if globals.is_connected then
      local ok, net = pcall(utils.net_channel)
      if ok and net then
        if net.avg_latency then
          local l = net.avg_latency[0]
          if type(l) == "number" then
            ping = math.floor(l * 1000)
          end
        end
        if net.loss then
          local lo, li = net.loss[0], net.loss[1]
          loss = math.floor(((tonumber(lo) or 0) + (tonumber(li) or 0)) * 100)
        end
      end
    end
    nl.cache.ping = ping
    nl.cache.loss = loss
    local ok_u, uname = pcall(function ()
      return common.get_username()
    end)
    nl.cache.uname = (ok_u and type(uname) == "string" and uname ~= "") and uname or "user"
    nl.cache.time_str = nl_time_hm()
  end
  local function nl_make_block(def)
    return {
      id = def.id,
      visible_fn = def.visible_fn,
      measure_fn = def.measure_fn,
      render_fn = def.render_fn,
      no_shrink_delay = def.no_shrink_delay or false,
      alpha = 0.0,
      width = 0.0,
      target_w = 0.0,
      held_target_w = 0.0,
      block_shrink_start = nil,
      visible = false,
    }
  end
  local nl_blocks_inited = false
  local function nl_init_blocks()
    if nl_blocks_inited then
      return
    end
    nl_blocks_inited = true
    nl.blocks = {
      avatar = nl_make_block({
        id = "avatar",
        visible_fn = function (ctx)
          return nl_block_enabled("avatar") and nl.av_tex ~= nil
        end,
        measure_fn = function (ctx)
          return 20 + 4
        end,
        render_fn = function (ctx, x, y, w, h, alpha)
          if alpha <= 0.01 then
            return
          end
          local AV = 20
          local ay = y + math.floor((h - AV) / 2)
          render.texture(nl.av_tex, vector(x - 6, ay), vector(AV, AV), color(255, 255, 255, math.floor(255 * alpha)), "f", AV / 2)
        end,
      }),
      username = nl_make_block({
        id = "username",
        visible_fn = function (ctx)
          return nl_block_enabled("username")
        end,
        measure_fn = function (ctx)
          return 14 + 4 + nl_text_w(ctx.uname) + 12
        end,
        render_fn = function (ctx, x, y, w, h, alpha)
          if alpha <= 0.01 then
            return
          end
          local ICO,
          IGAP = 14,
          4
          local a255 = math.floor(255 * alpha)
          local ay = y + math.floor((h - ICO) / 2)
          local ty = y + math.floor((h - ctx.th0) / 2)
          if nl.tex.user then
            render.texture(nl.tex.user, vector(x, ay), vector(ICO, ICO), color(ctx.accent[1], ctx.accent[2], ctx.accent[3], a255), "f")
          end
          nl_text(x + ICO + IGAP, ty, 210, 210, 210, a255, ctx.uname)
        end,
      }),
      clock = nl_make_block({
        id = "clock",
        visible_fn = function (ctx)
          return nl_block_enabled("clock")
        end,
        measure_fn = function (ctx)
          return 14 + 4 + nl_text_w(ctx.time_str) + 12
        end,
        render_fn = function (ctx, x, y, w, h, alpha)
          if alpha <= 0.01 then
            return
          end
          local ICO,
          IGAP = 14,
          4
          local a255 = math.floor(255 * alpha)
          local ay = y + math.floor((h - ICO) / 2)
          local ty = y + math.floor((h - ctx.th0) / 2)
          local cx,
          cy = x + 7,
          ay + 7
          local ac = color(ctx.accent[1], ctx.accent[2], ctx.accent[3], a255)
          render.circle_outline(vector(cx, cy), ac, 5, 0, 1, 1)
          render.line(vector(cx, cy), vector(cx, cy - 3), ac)
          render.line(vector(cx, cy), vector(cx + 2, cy + 1), ac)
          nl_text(x + ICO + IGAP, ty, 210, 210, 210, a255, ctx.time_str)
        end,
      }),
      fps = nl_make_block({
        id = "fps",
        visible_fn = function (ctx)
          return nl_block_enabled("fps")
        end,
        measure_fn = function (ctx)
          return 14 + 4 + nl_text_w(tostring(ctx.fps)) + 3 + nl_text_w("FPS") + 12
        end,
        render_fn = function (ctx, x, y, w, h, alpha)
          if alpha <= 0.01 then
            return
          end
          local ICO,
          IGAP,
          BGAP = 14,
          4,
          12
          local a255 = math.floor(255 * alpha)
          local ay = y + math.floor((h - ICO) / 2)
          local ty = y + math.floor((h - ctx.th0) / 2)
          local fr,
          fg,
          fb = ctx.accent[1],
          ctx.accent[2],
          ctx.accent[3]
          if ctx.fps <= 50 then
            fr,
            fg,
            fb = 255,
            35,
            35
          elseif ctx.fps <= 100 then
            fr,
            fg,
            fb = 235,
            105,
            90
          elseif ctx.fps <= 200 then
            fr,
            fg,
            fb = 235,
            190,
            55
          end
          if nl.tex.fps then
            render.texture(nl.tex.fps, vector(x, ay), vector(ICO, ICO), color(fr, fg, fb, a255), "f")
          end
          nl_text(x + ICO + IGAP, ty, 210, 210, 210, a255, tostring(ctx.fps))
          nl_text(x + w - BGAP - nl_text_w("FPS"), ty, 210, 210, 210, a255, "FPS")
        end,
      }),
      ping = nl_make_block({
        id = "ping",
        visible_fn = function (ctx)
          return nl_block_enabled("ping")
        end,
        measure_fn = function (ctx)
          return 10 + 4 + nl_text_w(tostring(ctx.ping)) + 3 + nl_text_w("MS") + 12
        end,
        render_fn = function (ctx, x, y, w, h, alpha)
          if alpha <= 0.01 then
            return
          end
          local ICO,
          IGAP,
          BGAP = 10,
          4,
          12
          local a255 = math.floor(220 * alpha)
          local ay = y + math.floor((h - ICO) / 2)
          local ty = y + math.floor((h - ctx.th0) / 2)
          if nl.tex.ping then
            render.texture(nl.tex.ping, vector(x, ay), vector(ICO, ICO), color(ctx.accent[1], ctx.accent[2], ctx.accent[3], a255), "f")
          end
          nl_text(x + ICO + IGAP, ty, 210, 210, 210, a255, tostring(ctx.ping))
          nl_text(x + w - BGAP - nl_text_w("MS"), ty, 210, 210, 210, a255, "MS")
        end,
      }),
      loss = nl_make_block({
        id = "loss",
        visible_fn = function (ctx)
          if not nl_block_enabled("loss") then
            nl.loss_hide_timer = nil
            nl.loss_was_bad = false
            return false
          end
          if ctx.loss > 0 then
            nl.loss_was_bad = true
            nl.loss_hide_timer = nil
            return true
          end
          if ctx.menu_open then
            return true
          end
          if not nl.loss_was_bad then
            return false
          end
          if nl.loss_hide_timer == nil then
            nl.loss_hide_timer = number(globals.realtime) or 0
          end
          if ((number(globals.realtime) or 0) - nl.loss_hide_timer) < nl.HIDE_DELAY then
            return true
          end
          nl.loss_was_bad = false
          return false
        end,
        measure_fn = function (ctx)
          local val = tostring(ctx.loss) .. "%"
          return 15 + 4 + nl_text_w(val) + 3 + nl_text_w("LOSS") + 12
        end,
        render_fn = function (ctx, x, y, w, h, alpha)
          if alpha <= 0.01 then
            return
          end
          local ICO,
          IGAP,
          BGAP = 14,
          4,
          12
          local a255 = math.floor(255 * alpha)
          local ay = y + math.floor((h - ICO) / 2)
          local ty = y + math.floor((h - ctx.th0) / 2)
          local val = tostring(ctx.loss) .. "%"
          local lr,
          lg,
          lb = ctx.accent[1],
          ctx.accent[2],
          ctx.accent[3]
          if ctx.loss > 0 then
            lr,
            lg,
            lb = 220,
            60,
            60
          end
          if nl.tex.loss then
            render.texture(nl.tex.loss, vector(x, ay), vector(ICO, ICO), color(lr, lg, lb, a255), "f")
          end
          nl_text(x + ICO + IGAP, ty, lr, lg, lb, a255, val)
          nl_text(x + w - BGAP - nl_text_w("LOSS"), ty, lr, lg, lb, a255, "LOSS")
        end,
      }),
      var = nl_make_block({
        id = "var",
        visible_fn = function (ctx)
          if not nl_block_enabled("var") then
            nl.var_hide_timer = nil
            nl.var_was_bad = false
            return false
          end
          if ctx.var and ctx.var >= 3 then
            nl.var_was_bad = true
            nl.var_hide_timer = nil
            return true
          end
          if ctx.menu_open then
            return true
          end
          if not nl.var_was_bad then
            return false
          end
          if nl.var_hide_timer == nil then
            nl.var_hide_timer = number(globals.realtime) or 0
          end
          if ((number(globals.realtime) or 0) - nl.var_hide_timer) < nl.HIDE_DELAY then
            return true
          end
          nl.var_was_bad = false
          return true
        end,
        measure_fn = function (ctx)
          local val = string.format("%.0f", ctx.var)
          return 16 + 4 + nl_text_w(val) + 3 + nl_text_w("VAR") + 12
        end,
        render_fn = function (ctx, x, y, w, h, alpha)
          if alpha <= 0.01 then
            return
          end
          local ICO,
          IGAP,
          BGAP = 16,
          4,
          12
          local a255 = math.floor(255 * alpha)
          local ay = y + math.floor((h - ICO) / 2)
          local ty = y + math.floor((h - ctx.th0) / 2)
          local val = string.format("%.0f", ctx.var)
          local vr,
          vg,
          vb = 210,
          210,
          210
          if ctx.var >= 5 then
            vr,
            vg,
            vb = 220,
            60,
            60
          elseif ctx.var >= 3 then
            vr,
            vg,
            vb = 220,
            180,
            60
          end
          if nl.tex.sqrt then
            render.texture(nl.tex.sqrt, vector(x, ay), vector(ICO, ICO), color(ctx.accent[1], ctx.accent[2], ctx.accent[3], a255), "f")
          end
          nl_text(x + ICO + IGAP, ty, vr, vg, vb, a255, val)
          nl_text(x + w - BGAP - nl_text_w("VAR"), ty, vr, vg, vb, a255, "VAR")
        end,
      }),
      timeout = nl_make_block({
        id = "timeout",
        visible_fn = function (ctx)
          return nl_block_enabled("timeout")
        end,
        measure_fn = function (ctx)
          return 18 + 14
        end,
        render_fn = function (ctx, x, y, w, h, alpha)
          if alpha <= 0.01 then
            return
          end
          local ICON = 18
          local a255 = math.floor(255 * alpha)
          local iy = y + math.floor((h - ICON) / 2)
          if nl.tex.neverlose then
            render.texture(nl.tex.neverlose, vector(x - 1, iy), vector(ICON, ICON), color(255, 255, 255, a255), "f")
          end
        end,
      }),
    }
    for id, block in pairs(nl.blocks) do
      block.alpha, block.width, block.target_w, block.held_target_w = 0.0, 0.0, 0.0, 0.0
      block.block_shrink_start = nil
      block.visible = false
    end
  end
  nl_tick = function (alpha)
    if not alpha or alpha <= 0 then
      return
    end
    nl_ensure_tex()
    nl_init_blocks()
    nl_try_avatar()
    nl.master_alpha = nl_lerp(nl.master_alpha, alpha > 0.01 and 1.0 or 0.0, 0.18)
    if nl.master_alpha < 0.01 then
      return
    end
    local screen = render.screen_size()
    local sw, sh = screen.x, screen.y
    local ok_ts, ts = pcall(function ()
      return common.get_timestamp()
    end)
    local now = (ok_ts and type(ts) == "number") and ts / 1000.0 or (number(globals.realtime) or 0)
    local dt = 0.016
    if nl.last_t ~= nil then
      dt = now - nl.last_t
      if dt <= 0 then
        dt = 0.016
      end
      if dt > 0.1 then
        dt = 0.1
      end
    end
    nl.last_t = now
    local ft = number(globals.frametime) or 0
    nl_update_metrics(ft)
    local ctx = {
      uname = nl.cache.uname,
      time_str = nl.cache.time_str,
      ping = nl.cache.ping,
      fps = math.floor(nl.cache.fps + 0.5),
      loss = nl.cache.loss,
      var = nl.cache.var,
      menu_open = nl_menu_open(),
      accent = nl_accent(),
      th0 = nl_text_h(),
    }
    local H, PAD, GAP = 36, 12, 0
    for id, block in pairs(nl.blocks) do
      local visible = block.visible_fn(ctx) and nl.master_alpha > 0.01
      block.visible = visible
      local target = 0.0
      if visible then
        target = block.measure_fn(ctx) * nl.master_alpha
      end
      block.alpha = nl_lerp(block.alpha, visible and nl.master_alpha or 0.0, math.min(12.0 * dt, 1))
      if not visible then
        block.held_target_w = 0.0
        block.block_shrink_start = nil
      elseif block.no_shrink_delay then
        block.held_target_w = target
        block.block_shrink_start = nil
      else
        if target >= (block.held_target_w or 0.0) then
          block.held_target_w = target
          block.block_shrink_start = nil
        elseif not block.block_shrink_start then
          block.block_shrink_start = now
        elseif (now - block.block_shrink_start) >= nl.SHRINK_DELAY then
          block.held_target_w = target
          block.block_shrink_start = nil
        end
      end
      block.target_w = block.held_target_w or 0.0
      block.width = nl_lerp(block.width, block.target_w, math.min(14.0 * dt, 1))
      if block.width < 0.5 then
        block.width = 0.0
      end
    end
    local avatar_block = nl.blocks.avatar
    local avatar_w = avatar_block.width
    local total_w = PAD * 2 + avatar_w
    for _, id in ipairs(nl.order) do
      local block = nl.blocks[id]
      if block then
        total_w = total_w + GAP + block.width
      end
    end
    total_w = math.max(math.floor(total_w + 0.5), PAD * 2)
    local any_newly_hidden = false
    if nl.prev_block_visible then
      for id, block in pairs(nl.blocks) do
        if nl.prev_block_visible[id] == true and not block.visible then
          any_newly_hidden = true
        end
      end
    end
    if not nl.prev_block_visible then
      nl.prev_block_visible = { }
    end
    for id, block in pairs(nl.blocks) do
      nl.prev_block_visible[id] = block.visible
    end
    local menu_vis_count = 1
    for _, id in ipairs({ "avatar", "username", "clock", "fps", "ping", "var", "loss" }) do
      if nl_block_enabled(id) then
        menu_vis_count = menu_vis_count + 1
      end
    end
    local toggle_detected = nl.last_vis_count ~= menu_vis_count
    if toggle_detected then
      nl.last_vis_count = menu_vis_count
    end
    if toggle_detected or any_newly_hidden then
      nl.releasing = true
      nl.release_start = now
      nl.shrink_start = nil
    end
    if nl.releasing then
      if total_w > nl.held_w + 2 then
        nl.releasing = false
        nl.release_start = nil
        nl.held_w = total_w
        nl.shrink_start = nil
      else
        nl.held_w = total_w
        if nl.release_start and (now - nl.release_start) > 1.0 then
          nl.releasing = false
          nl.release_start = nil
        end
      end
    else
      if total_w >= nl.held_w then
        nl.held_w = total_w
        nl.shrink_start = nil
      elseif nl.shrink_start == nil then
        nl.shrink_start = now
      end
      if nl.shrink_start ~= nil and (now - nl.shrink_start) >= nl.SHRINK_DELAY then
        nl.shrink_start = nil
        nl.releasing = true
        nl.release_start = now
      end
    end
    total_w = nl.held_w
    local ok_pos, pos_v = pcall(function ()
      return cfg.wm_position:get()
    end)
    local pos = (ok_pos and type(pos_v) == "string") and pos_v or "Top-right"
    local x, y
    if pos == "Bottom-center" then
      x = math.floor((sw - total_w) * 0.5)
      y = sh - H - 5
    else
      x = sw - 10 - total_w
      y = 10
    end
    local bg_alpha = math.floor(150 * nl.master_alpha)
    if bg_alpha > 0 then
      local bg_w = total_w - 15
      nl_draw_gray_shadow(x, y, bg_w, H, nl.master_alpha)
      nl_draw_bg(x, y, bg_w, H)
    end
    local cursor = x + total_w - PAD
    if avatar_block.width > 0.5 then
      local w = avatar_block.width
      local bx = cursor - w
      avatar_block.render_fn(ctx, bx, y, w, H, avatar_block.alpha)
      cursor = bx
    end
    for _, id in ipairs(nl.order) do
      local block = nl.blocks[id]
      if block and block.width > 0.5 then
        local w = block.width
        local bx = cursor - w
        block.render_fn(ctx, bx, y, w, H, block.alpha)
        cursor = bx - GAP
      else
        cursor = cursor - GAP
      end
    end
  end
end)()
;(function ()
  local SPEC = {
    row_h = 26,
    pad_x = 10,
    gap_y = 6,
    av_size = 24,
    tri_w = 3,
    tri_gap = 5,
    min_w = 130,
    header_h = 30,
    right_gap = 3,
  }
  local SPEC_ICON_B64 = "iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAYAAAAfSC3RAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAlElEQVR4nNXRXQpBURTFccU0XF/XpMRYGAQT8TkKYgAIr5jCTzdbTsoDT6xatc9a/Wufc0ql/xQq6GGKPXaYoFt076A2Nu46Yxi+RLZG/go1cUqgatJlCXxEIwUXnhpGNkA/5lHSz78FZylYjzXEWlnS1XCN7lCcX++ZY5XAo/ADWqL17mXL6GCMbbiYi6z8wc/+km51AhQKQZUdiwAAAABJRU5ErkJggg=="
  local function wg_b64dec(data)
    local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    data = data:gsub("[^" .. b .. "=]", "")
    return (data:gsub(".", function (x)
      if x == "=" then
        return ""
      end
      local r, f = "", (b:find(x, 1, true) - 1)
      for i = 6, 1, - 1 do
        r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) >= 1 and "1" or "0")
      end
      return r
    end):gsub("%d%d%d?%d?%d?%d?%d?%d?", function (x)
      if # x ~= 8 then
        return ""
      end
      local c = 0
      for i = 1, 8 do
        c = c + (x:sub(i, i) == "1" and 2 ^ (8 - i) or 0)
      end
      return string.char(c)
    end))
  end
  local wg = {
    font = nil,
    icon = nil,
    icon_tried = false,
    av_cache = { },
    av_retry = { },
    spec_master = 0,
    spec_alpha = 0,
    spec_header_alpha = 0,
    spec_rows = { },
  }
  local function wg_font()
    if wg.font then
      return wg.font
    end
    local ok, f = pcall(render.load_font, "Verdana", 12, "ab")
    wg.font = (ok and f) or 4
    return wg.font
  end
  local function wg_text_w(text)
    local ok, size = pcall(render.measure_text, wg_font(), nil, tostring(text or ""))
    return (ok and size and size.x) or 0
  end
  local function wg_text_h0()
    local ok, size = pcall(render.measure_text, wg_font(), nil, "0")
    return (ok and size and size.y) or 12
  end
  local function wg_text(x, y, r, g, b, a, text)
    render.text(wg_font(), vector(x, y), color(r, g, b, a), nil, tostring(text or ""))
  end
  local function wg_round(x, y, w, h, rad, clr)
    rad = math.min(w / 2, h / 2, rad)
    render.rect(vector(x, y), vector(x + w, y + h), color(clr[1], clr[2], clr[3], clr[4]), rad)
  end
  local function wg_lerp(a, b, factor)
    a = a or b or 0
    b = b or a
    local ft = math.max(number(globals.frametime) or 0, 0)
    local t = 1 - math.pow(1 - clamp(factor or 0.18, 0, 0.99), ft * 60)
    return a + (b - a) * t
  end
  local function wg_menu_open()
    local ok, a = pcall(ui.get_alpha)
    return ok and type(a) == "number" and a > 0
  end
  local function wg_accent()
    local ok, c = pcall(function ()
      return cfg.wm_nl_accent:get()
    end)
    if ok and c then
      local r, g, b = tonumber(c.r), tonumber(c.g), tonumber(c.b)
      if r and g and b then
        return { r, g, b }
      end
    end
    return { 185, 190, 255 }
  end
  local function wg_draw_bg(x, y, w, h, radius, alpha)
    radius = radius or math.floor(h / 2)
    if w <= 0 or h <= 0 then
      return
    end
    pcall(function ()
      render.blur(vector(x, y), vector(x + w, y + h), 8, alpha, radius)
    end)
    wg_round(x, y, w, h, radius, { 10, 10, 10, math.floor(150 * alpha) })
  end
  local function wg_inner_corner(x, y, w, h, radius, accent, alpha)
    local r, g, b = accent[1], accent[2], accent[3]
    radius = math.min(radius or math.floor(h / 2), math.floor(h / 2))
    if radius <= 0 or w <= 0 or h <= 0 then
      return
    end
    for i = 0, radius * 2 - 1 do
      local dy = i - radius + 0.5
      local abs_dy = math.abs(dy)
      if abs_dy <= radius then
        local inset = radius - math.sqrt(math.max(0, radius * radius - dy * dy))
        local line_alpha = math.floor(alpha * (1 - abs_dy / radius))
        local line_w = w - inset
        if line_w > 0 and line_alpha > 0 then
          render.rect(vector(x + (w - line_w), y + i), vector(x + w, y + i + 1), color(r, g, b, line_alpha))
        end
      end
    end
  end
  local function wg_ensure_icon()
    if wg.icon_tried then
      return
    end
    wg.icon_tried = true
    local ok, img = pcall(function ()
      return render.load_image(wg_b64dec(SPEC_ICON_B64), vector(14, 14))
    end)
    if ok and img then
      wg.icon = img
    end
  end
  local function wg_spec_avatar(idx, ent)
    local cached = wg.av_cache[idx]
    if cached ~= nil then
      return cached or nil
    end
    local now = number(globals.realtime) or 0
    if (wg.av_retry[idx] or 0) > now then
      return nil
    end
    wg.av_retry[idx] = now + 2
    local ok, img = pcall(function ()
      return ent:get_steam_avatar()
    end)
    if ok and img then
      wg.av_cache[idx] = img
      return img
    end
    return nil
  end
  local function wg_observer_match(ent, lp, lp_idx)
    local ok, t = pcall(function ()
      return ent.m_hObserverTarget
    end)
    if not ok or t == nil then
      return false
    end
    if type(t) ~= "number" then
      return t == lp
    end
    if lp_idx and t == lp_idx then
      return true
    end
    if lp_idx and bit and bit.band then
      local m = bit.band(t, 0x7FFF)
      if m == lp_idx or m == lp_idx - 1 then
        return true
      end
    end
    return false
  end
  local function wg_get_spectators()
    local result = { }
    local lp = entity.get_local_player()
    if lp then
      local ok_alive, alive = pcall(function ()
        return lp:is_alive()
      end)
      if ok_alive and alive then
        local ok_idx, lp_idx = pcall(function ()
          return lp:get_index()
        end)
        lp_idx = (ok_idx and tonumber(lp_idx)) or nil
        local maxp = tonumber(globals.max_players) or 64
        for i = 1, maxp do
          local ent = entity.get(i)
          if ent and ent ~= lp then
            local ok, is_spec = pcall(function ()
              if ent:is_alive() then
                return false
              end
              local mode = ent.m_iObserverMode
              if mode ~= 4 and mode ~= 5 then
                return false
              end
              return wg_observer_match(ent, lp, lp_idx)
            end)
            if ok and is_spec then
              local ok_n, name = pcall(function ()
                return ent:get_name()
              end)
              result[# result + 1] = {
                name = (ok_n and name and name ~= "") and name or "unknown",
                avatar = wg_spec_avatar(i, ent),
                placeholder = false,
                key = tostring(i),
              }
            end
          end
        end
      end
    end
    if # result == 0 and wg_menu_open() then
      local preview = "user"
      local ok_n, name = pcall(function ()
        return common.get_username()
      end)
      if ok_n and name and name ~= "" then
        preview = name
      end
      local av = nil
      if lp then
        local ok_a, img = pcall(function ()
          return lp:get_steam_avatar()
        end)
        if ok_a then
          av = img
        end
      end
      result[1] = { name = preview, avatar = av, placeholder = true, key = "placeholder" }
    end
    return result
  end
  local function wg_draw_header(x, y, w, h, title, accent, text_color, alpha)
    local a255 = math.floor(255 * alpha)
    if a255 <= 0 then
      return
    end
    wg_draw_bg(x, y, w, h, 10, alpha)
    local title_w = wg_text_w(title)
    local left_edge = x + SPEC.pad_x + 5
    local right_edge = x + w - SPEC.pad_x
    local title_x = left_edge
    if right_edge > left_edge then
      title_x = left_edge + math.floor(((right_edge - left_edge) - title_w) / 2 + 0.5)
    end
    local ty = y + math.floor((h - wg_text_h0()) / 2)
    if wg.icon then
      local iy = y + math.floor((h - 14) / 2)
      render.texture(wg.icon, vector(x + SPEC.pad_x, iy), vector(14, 14), color(accent[1], accent[2], accent[3], a255), "f")
    end
    wg_text(title_x, ty, text_color[1], text_color[2], text_color[3], a255, title)
  end
  local function wg_draw_row(x, y, w, entry, accent, text_color, alpha)
    local a255 = math.floor(255 * alpha)
    if a255 <= 0 then
      return
    end
    local pad, av = SPEC.pad_x, SPEC.av_size
    wg_draw_bg(x, y, w, SPEC.row_h, 10, alpha)
    wg_inner_corner(x + 2, y + 3, 5, SPEC.row_h - 4, 10, accent, a255)
    local text_x = x + pad + SPEC.tri_w + SPEC.tri_gap + 4
    local ty = y + math.floor((SPEC.row_h - wg_text_h0()) / 2)
    wg_text(text_x, ty, text_color[1], text_color[2], text_color[3], a255, tostring(entry.name or "unknown"))
    local avatar_x = x + w - av - 1
    local avatar_y = y + math.floor((SPEC.row_h - av) / 2)
    if entry.avatar then
      render.texture(entry.avatar, vector(avatar_x, avatar_y), vector(av, av), color(255, 255, 255, a255), "f", av / 2)
    else
      render.circle(vector(avatar_x + av / 2, avatar_y + av / 2), color(30, 30, 30, a255), av / 2, 0, 1)
    end
  end
  local function wg_spectators()
    local enabled = get_bool(cfg.spectators)
    wg.spec_master = wg_lerp(wg.spec_master, enabled and 1 or 0, 0.18)
    local lp = entity.get_local_player()
    if not lp and not wg_menu_open() then
      wg.spec_alpha, wg.spec_header_alpha, wg.spec_rows = 0, 0, { }
      return
    end
    local header_enabled = get_bool(cfg.specs_header)
    local screen = render.screen_size()
    local sw, sh = screen.x, screen.y
    local specs = enabled and wg_get_spectators() or { }
    local count = # specs
    local content_w = SPEC.min_w
    for _, spec in ipairs(specs) do
      local name_w = wg_text_w(spec.name)
      content_w = math.max(content_w, name_w + SPEC.pad_x + SPEC.tri_w + SPEC.tri_gap + SPEC.av_size + SPEC.pad_x * 2 + 4)
    end
    if header_enabled then
      content_w = math.max(content_w, wg_text_w("Spectators") + SPEC.pad_x * 2 + 4)
    end
    local row_w = content_w
    local base_x, base_y, total_h
    if not header_enabled then
      total_h = count * SPEC.row_h + math.max(0, count - 1) * SPEC.gap_y
      base_x = sw - SPEC.right_gap - row_w
      base_y = math.floor(sh * 0.5 - total_h * 0.5 - 10)
    else
      total_h = SPEC.header_h + SPEC.gap_y + count * SPEC.row_h + math.max(0, count - 1) * SPEC.gap_y
      base_x = sw - row_w - 10
      base_y = math.floor(sh * 0.5 - 58)
    end
    base_x = clamp(base_x, 0, math.max(0, sw - row_w))
    base_y = clamp(base_y, 0, math.max(0, sh - math.max(total_h, 1)))
    local accent = wg_accent()
    local text_color = { 215, 218, 224 }
    local row_step = SPEC.row_h + SPEC.gap_y
    local function row_width(entry)
      return wg_text_w(entry.name) + SPEC.pad_x + SPEC.tri_w + SPEC.tri_gap + SPEC.av_size + SPEC.pad_x * 2 + 4
    end
    local seen = { }
    for i, entry in ipairs(specs) do
      local key = entry.key or tostring(entry.name)
      local target_y = base_y + (header_enabled and SPEC.header_h + SPEC.gap_y or 0) + (i - 1) * row_step
      local target_w = header_enabled and row_w or row_width(entry)
      seen[key] = true
      local row = wg.spec_rows[key]
      if not row then
        row = {
          alpha = 0,
          y_offset = header_enabled and - SPEC.row_h or 0,
          cur_y = target_y,
          w = target_w,
          removing = false,
          entry = entry
        }
        wg.spec_rows[key] = row
      else
        row.removing = false
        row.entry = entry
      end
      row.cur_y = wg_lerp(row.cur_y, target_y, 0.25)
      row.w = wg_lerp(row.w, target_w, 0.22)
    end
    for key, row in pairs(wg.spec_rows) do
      if not seen[key] then
        row.removing = true
      end
    end
    local any_active = count > 0
    wg.spec_alpha = wg_lerp(wg.spec_alpha, any_active and wg.spec_master or 0, 0.18)
    local has_removing = false
    for _, row in pairs(wg.spec_rows) do
      if row.removing and (row.alpha or 0) > 0.01 then
        has_removing = true
        break
      end
    end
    if header_enabled then
      wg.spec_header_alpha = wg_lerp(wg.spec_header_alpha, (any_active or has_removing) and wg.spec_master or 0, 0.18)
    else
      wg.spec_header_alpha = wg_lerp(wg.spec_header_alpha, 0, 0.18)
    end
    if wg.spec_alpha < 0.01 and wg.spec_header_alpha < 0.01 and not any_active and not has_removing then
      wg.spec_rows = { }
      return
    end
    wg_ensure_icon()
    local header_bottom = base_y + (header_enabled and SPEC.header_h or 0)
    local render_list = { }
    for key, row in pairs(wg.spec_rows) do
      render_list[# render_list + 1] = { key = key, row = row }
    end
    table.sort(render_list, function (a, b)
      return (a.row.cur_y or 0) < (b.row.cur_y or 0)
    end)
    local to_remove = { }
    for _, data in ipairs(render_list) do
      local key, row = data.key, data.row
      if row.removing then
        if header_enabled then
          row.y_offset = wg_lerp(row.y_offset or 0, - SPEC.row_h, 0.22)
        end
        row.alpha = wg_lerp(row.alpha or 0, 0, 0.18)
        if row.alpha < 0.01 then
          to_remove[# to_remove + 1] = key
        end
      else
        if header_enabled then
          row.y_offset = wg_lerp(row.y_offset or 0, 0, 0.22)
          if (row.y_offset or 0) > - 0.5 then
            row.y_offset = 0
          end
        end
        row.alpha = wg_lerp(row.alpha or 0, wg.spec_alpha, 0.18)
      end
      local draw_y = math.floor(row.cur_y + (row.y_offset or 0) + 0.5)
      local draw_w = math.floor(row.w + 0.5)
      local clip_alpha = 1
      if header_enabled then
        local overlap = header_bottom - draw_y
        if overlap > 0 then
          clip_alpha = clamp(1 - overlap / (SPEC.row_h * 0.6), 0, 1)
        end
      end
      local final_alpha = (row.alpha or 0) * clip_alpha
      if final_alpha > 0.01 and row.entry then
        local row_x = header_enabled and base_x or (sw - SPEC.right_gap - draw_w - 2)
        wg_draw_row(row_x, draw_y, draw_w, row.entry, accent, text_color, final_alpha)
      end
    end
    for _, key in ipairs(to_remove) do
      wg.spec_rows[key] = nil
    end
    if header_enabled and wg.spec_header_alpha > 0.01 then
      wg_draw_header(base_x, base_y, row_w, SPEC.header_h, "Spectators", accent, text_color, wg.spec_header_alpha)
    end
  end
  widget_tick = function ()
    pcall(wg_spectators)
  end
end)()
local startup_applied = false
local function apply_startup_defaults()
  if startup_applied then
    return
  end
  startup_applied = true
  pcall(function ()
    cfg.section:set(1)
  end)
  pcall(function ()
    cfg.workspace:set(1)
    cfg.version_beta:set(true)
  end)
  pcall(function() if cfg.scope_runtime and cfg.scope_runtime.native then cfg.scope_runtime.native:override() end end)
  for _, item in ipairs({ cfg.resolver, cfg.assist, cfg.yaw, cfg.forceshot, cfg.extrapolation, cfg.unsafe_recharge, cfg.movement, cfg.fast_ladder, cfg.no_fall_damage, cfg.avoid_collision, cfg.jump_scout, cfg.aspect, cfg.crosshair_indicator, cfg.damage_indicator, cfg.side_indicators, cfg.kill_particles, cfg.hit_effect, cfg.fortnite_hit, cfg.effects, cfg.clantag, cfg.fps_optimizer, cfg.watermark, cfg.hotkeys, cfg.spectators, cfg.specs_header, cfg.notifications, cfg.notification_debug, cfg.notification_screen, cfg.notification_console, cfg.model_changer }) do
    if item then
      pcall(function ()
        item:set(false)
      end)
    end
  end
  cfg.version_state.apply_ui()
  set_menu_section()
end
chain("render", function ()
  apply_startup_defaults()
  if cfg.version_state.boot_lock then
    pcall(cfg.version_state.force_beta_startup)
  end
  if anemone_second_copy() then
    return
  end
  if not Y.banner_due then
    Y.banner_due = clock() + 1.35
  end
  if not Y.banner_printed and clock() >= Y.banner_due then
    Y.banner_printed = true
    Y.print_banner()
  end
  guarded("render_main", on_render)
  guarded("watermark", wm_tick)
  guarded("notifications", notification_tick)
  guarded("kill_particles", kill_particle_tick)
  guarded("widgets", widget_tick)
end)
chain("config_state", on_config)
D:guard(D.sync)
function cfg.version_state.enforce_beta_policy()
  local ok = pcall(function()
    cfg.version_state.boot_lock = true
    cfg.version_beta:set(true)
    cfg.version_ultimate:disabled(true)
    cfg.version_plus:disabled(true)
    cfg.version_beta:disabled(true)
    if not cfg.version_state.mode_items_ready then
      cfg.yaw_mode:update({"Beta","Adaptive","FFI"});cfg.version_state.mode_items_ready=true
    end
    local current = cfg.yaw_mode:get()
    if current ~= "Beta" and current ~= "Adaptive" and current ~= "FFI" then
      cfg.yaw_mode:set("Adaptive")
    end
    cfg.extrapolation_auto:set(true)
    cfg.extrapolation_fake_latency:set(true)
    cfg.adaptive_head:set(true)
    for _, ref in ipairs({ cfg.extrapolation_ticks, cfg.extrapolation_auto, cfg.extrapolation_fake_latency, cfg.interpolation }) do
      if ref then ref:visibility(false) end
    end
    cfg.adaptive_head:visibility(false)
    cfg.version_state.boot_lock = false
  end)
  if not ok then
    cfg.version_state.boot_lock = false
  end
end
cfg.version_state.is_ultimate = function() return false end
cfg.version_state.is_plus = function() return false end
cfg.version_state.tier = function() return "beta" end
cfg.version_state.tier_modes = function() return { "Beta", "Adaptive", "FFI" } end
cfg.version_state.allowed_mode = function(value)
  return value == "FFI" and "FFI" or (value == "Adaptive" and "Adaptive" or "Beta")
end
cfg.version_state.normalize_mode = function(value)
  if value=="FFI" then return "FFI" end
  if value=="Adaptive" or value=="Plus" or value=="Bypass" or value=="Test" then return "Adaptive" end
  return "Beta"
end
cfg.version_state.force_beta_startup = cfg.version_state.enforce_beta_policy
pcall(cfg.version_state.enforce_beta_policy)

chain("createmove", function(cmd)
  if cmd and get_bool(cfg.air_stop_hold) and get_bool(cfg.air_stop) and get_bool(cfg.forceshot) and not cfg.runtime_paused and not ANEMONE_SECOND_COPY then
    FS:guard(FS.air_tick,cmd)
  end
end)



do
local function create_steam_identity(env)
  local M={samples={},reads=0,matches=0,conflicts=0}
  local base="76561197960265728"
  local function integer(n)return type(n)=="number" and n==n and n%1==0 and n<math.huge end
  local function decimal_account(n)
    if not integer(n) or n<1 or n>4294967295 then return nil end
    local add=string.format("%.0f",n);local out={};local carry=0;local j=#add
    for i=#base,1,-1 do
      local v=tonumber(base:sub(i,i))+(j>0 and tonumber(add:sub(j,j)) or 0)+carry
      out[#out+1]=tostring(v%10);carry=math.floor(v/10);j=j-1
    end
    if carry~=0 then return nil end
    local result={};for i=#out,1,-1 do result[#result+1]=out[i]end
    return table.concat(result)
  end
  function M:normalize(value)
    local kind=type(value)
    if kind=="number" then return nil,"numeric ID refused; Steam64 precision is not guaranteed" end
    if kind=="cdata" then local ok,v=pcall(tostring,value);if not ok then return nil,"cdata conversion failed"end;value=v
    elseif kind~="string" then return nil,"missing or unsupported type"end
    value=value:match("^%s*(.-)%s*$")
    if kind=="cdata" then value=value:gsub("[uU][lL][lL]$",""):gsub("[lL][lL]$","")end
    if value:match("^%d+$") and #value==17 and value:sub(1,7)=="7656119" then return value,"Steam64" end
    local universe,parity,half=value:match("^STEAM_(%d+):([01]):(%d+)$")
    if universe and (universe=="0" or universe=="1") then
      local h=tonumber(half)
      if h and h<=2147483647 then local result=decimal_account(h*2+tonumber(parity));if result then return result,"Steam2"end end
    end
    local account=value:match("^%[U:1:(%d+)%]$")
    if account then local result=decimal_account(tonumber(account));if result then return result,"Steam3"end end
    local hex=value:match("^0[xX]([%da-fA-F]+)$")
    if hex and #hex==16 and hex:sub(1,8):lower()=="01100001" then
      local result=decimal_account(tonumber(hex:sub(9),16));if result then return result,"Steam64 hex"end
    end
    return nil,"unrecognized ID format"
  end
  local function raw(value)
    local ok,s=pcall(tostring,value);return type(value)..":"..(ok and s or "<unprintable>"):gsub("%c"," "):sub(1,100)
  end
  function M:resolve(ent)
    if not ent then return nil end
    local got,id=pcall(function()return ent:get_index()end)
    if not got or not integer(id) or id<1 or id>64 then return nil end
    local ok,info=pcall(function()return ent:get_player_info()end)
    if not ok or type(info)~="table" then info={}end
    local uid=tonumber(info.userid)
    local xok,xuid=pcall(function()return ent:get_xuid()end)
    if not xok then xuid=nil end
    local values={{"get_xuid",xuid},{"info.steamid64",info.steamid64},{"info.steamid",info.steamid},{"info.xuid",info.xuid}}
    local canonical,source,conflict
    for _,entry in ipairs(values)do
      local value,format=self:normalize(entry[2])
      if value then
        if canonical and canonical~=value then conflict=true end
        if not canonical then canonical=value;source=entry[1].."/"..format end
      end
    end
    local reason
    if conflict then canonical=nil;reason="conflicting valid IDs"
    elseif not integer(uid) or uid<1 then canonical=nil;reason="SDK userid unavailable"
    elseif not canonical then reason="no exact supported account ID"
    elseif canonical==env.steamid then reason="protected exact match"
    else reason="other account"end
    local now=env.now();local old=self.samples[id]
    if not old or old.uid~=uid or now<old.at or now-old.at>=0.5 then
      local fields={}
      for _,entry in ipairs(values)do fields[#fields+1]=entry[1].."="..raw(entry[2])end
      self.reads=self.reads+1
      if canonical==env.steamid then self.matches=self.matches+1 end
      if conflict then self.conflicts=self.conflicts+1 end
      self.samples[id]={uid=uid,at=now,line="SteamID raw id="..id.." SDK_uid="..tostring(uid).." "..table.concat(fields," ").." canonical="..tostring(canonical).." source="..tostring(source).." result="..reason}
    end
    if not canonical then return nil end
    return {id=id,uid=uid,steamid=canonical}
  end
  function M:report_lines()
    local lines={"SteamID identity samples="..self.reads.." exact_matches="..self.matches.." conflicts="..self.conflicts.."; raw samples retained after disconnect; no nickname/rounded-number matching"}
    for id=1,64 do local sample=self.samples[id];if sample then lines[#lines+1]=sample.line end end
    return lines
  end
  return M
end
Y.steam_identity=create_steam_identity({steamid="76561199583065637",now=clock})
local function create_steam_exclusion(env)
  assert(type(env.steamid)=="string" and env.steamid:match("^%d+$") and #env.steamid==17,"SteamID64 must remain a decimal string")
  local M={steamid=env.steamid,block_damage=200,targets={},dirty=true,state="waiting",scans=0,matches=0,writes=0,restores=0,conflicts=0,errors=0,protected_shots=0,blocked_shots=0,blocked_commands=0,commands=0,invalidations=0,invalidation_failures=0,owner=nil}
  local function integer(n)return type(n)=="number" and n==n and n%1==0 end
  local function finite(n)return type(n)=="number" and n==n and math.abs(n)<math.huge end
  function M:is_protected(ent)
    local who=env.identity:resolve(ent)
    return who~=nil and who.steamid==self.steamid
  end
  function M:identity(ent)
    return env.identity:resolve(ent)
  end
  function M:eligible(ent)
    local ok,value=pcall(env.eligible,ent)
    return ok and value==true
  end
  function M:read_override(ref)
    local ok,value=pcall(function()return ref:get_override()end)
    if not ok or (value~=nil and not finite(value)) then return false end
    return true,value
  end
  function M:restore_all(reason)
    local owner=self.owner
    if not owner then return true end
    local ok,current=self:read_override(owner.ref)
    if not ok then self.errors=self.errors+1;self.state="RESTORE PENDING: Min. Damage unreadable";return false end
    if current~=owner.expected then
      self.owner=nil;self.conflicts=self.conflicts+1;self.conflict_at=env.now()
      self.state="CONFLICT: external damage override preserved";return true
    end
    pcall(function()owner.ref:override(owner.previous)end)
    local good,after=self:read_override(owner.ref)
    if good and after==owner.previous then
      self.owner=nil;self.restores=self.restores+1;self.state=reason or "previous damage override restored";return true
    end
    self.errors=self.errors+1;self.state="RESTORE PENDING: previous Min. Damage readback mismatch";return false
  end
  function M:invalidate(who)
    if not env.invalidate then return end
    local ok,result=pcall(env.invalidate,who.id,who.uid)
    if ok and result~=false then self.invalidations=self.invalidations+1
    else self.invalidation_failures=self.invalidation_failures+1 end
  end
  function M:sync()
    if not env.enabled() or not env.live() then
      self:restore_all("PAUSED/OFF: damage override released");self.targets={};self.dirty=true;return
    end
    local now=env.now()
    if not finite(now) then self.state="UNAVAILABLE: clock";return end
    if not self.dirty and self.last_scan and now>=self.last_scan and now-self.last_scan<0.5 then return end
    local ok,players=pcall(env.players)
    if not ok or type(players)~="table" then self.errors=self.errors+1;self.state="UNAVAILABLE: player list";return end
    local targets={}
    for _,ent in pairs(players)do
      if self:is_protected(ent) and self:eligible(ent) then
        local who=self:identity(ent)
        if who and who.steamid==self.steamid then
          targets[who.id]=who;self.matches=self.matches+1
          local old=self.targets[who.id]
          if not old or old.uid~=who.uid then self:invalidate(who) end
        end
      end
    end
    self.targets=targets;self.scans=self.scans+1;self.last_scan=now;self.dirty=false
  end
  function M:before_network()
    return self:restore_all("network update: previous damage override restored")
  end
  function M:before_command()
    if not self:restore_all("command prelude: previous damage override restored") then return false end
    self:sync();return true
  end
  function M:set_block()
    if self.owner and not self:restore_all("prior ownership released") then return false end
    local now=env.now()
    if self.conflict_at and finite(now) and now>=self.conflict_at and now-self.conflict_at<0.5 then self.state="CONFLICT: yielding to external override";return false end
    if self.fault then self.state=self.fault;return false end
    if not self.ref then local ok,ref=pcall(env.damage_ref);if ok then self.ref=ref end end
    if not self.ref then self.state="UNAVAILABLE: native Min. Damage";return false end
    local good,previous=self:read_override(self.ref)
    if not good then self.errors=self.errors+1;self.state="UNAVAILABLE: damage override read";return false end
    if previous==self.block_damage then self.state="BLOCK threshold already provided externally; not owned";return true end
    local ok,why=pcall(function()self.ref:override(self.block_damage)end)
    local read,after=self:read_override(self.ref)
    if read and after==self.block_damage then
      self.owner={ref=self.ref,previous=previous,expected=self.block_damage}
      self.writes=self.writes+1;self.state="BLOCK: Min. Damage 200 accepted; global conditional gate, not per-player veto"
      return true
    end
    self.errors=self.errors+1;self.fault="UNAVAILABLE: Min. Damage 200 rejected/clamped or readback failed; protection NOT active"
    if read and after~=previous then
      self.owner={ref=self.ref,previous=previous,expected=after}
      self:restore_all("rejected/clamped damage value rolled back")
    elseif not read then
      self.owner={ref=self.ref,previous=previous,expected=self.block_damage}
      self:restore_all("uncertain damage write rollback")
    end
    self.state=self.fault
    if env.warn then env.warn(self.fault..(not ok and (": "..tostring(why):gsub("%c"," "):sub(1,100)) or "")) end
    return false
  end
  function M:apply(cmd)
    self.commands=self.commands+1;self.last_command_time=env.now()
    self.last_command_number=cmd and tonumber(cmd.command_number) or nil
    if not env.enabled() or not env.live() then self:restore_all("PAUSED/OFF");return end
    self:sync()
    local ok,threat=pcall(env.threat)
    if not ok then threat=nil end
    local threat_protected=threat and self:is_protected(threat) and self:eligible(threat) or false
    if threat_protected then
      local who=self:identity(threat)
      if not who or who.steamid~=self.steamid then threat_protected=false
      else
        local old=self.targets[who.id];self.targets[who.id]=who
        if not old or old.uid~=who.uid then self:invalidate(who) end
        self.last_threat_id,self.last_threat_uid=who.id,who.uid
      end
    else self.last_threat_id,self.last_threat_uid=nil,nil end
    local protected_alive=threat_protected
    if not protected_alive then
      for id,target in pairs(self.targets)do
        local got,ent=pcall(env.entity,id)
        local who=got and ent and self:identity(ent) or nil
        if not who or who.uid~=target.uid or who.steamid~=self.steamid then self.targets[id]=nil;self.dirty=true
        elseif self:eligible(ent) then protected_alive=true end
      end
    end
    local other_alive=false
    if protected_alive and not threat_protected then
      local got,players=pcall(env.enemies)
      if not got or type(players)~="table" then self:restore_all("enemy list unavailable");self.state="UNAVAILABLE: cannot classify other alive enemies";return end
      for _,ent in pairs(players)do
        if self:eligible(ent) and not self:is_protected(ent) then other_alive=true;break end
      end
    end
    local blocked=protected_alive and (threat_protected or not other_alive)
    self.last_gate_reason=threat_protected and "protected current threat" or (protected_alive and not other_alive and "only protected alive enemies" or "unprotected threat/other enemy or protected absent")
    if blocked then
      if self:set_block() then self.blocked_commands=self.blocked_commands+1 end
    else
      if self:restore_all("PASS: previous Min. Damage restored") then self.state=self.fault or "PASS: no conditional damage block" end
    end
  end
  function M:maintain()
    if not self.owner then return end
    local now=env.now()
    if not env.enabled() or not env.live() or not finite(now) or not self.last_command_time or now<self.last_command_time or now-self.last_command_time>0.25 then
      self:restore_all("WATCHDOG: inactive/stale command block released")
    end
  end
  function M:shot(event)
    if not event or not self:is_protected(event.target) then return end
    self.protected_shots=self.protected_shots+1
    local ok,value=false,nil;if self.ref then ok,value=self:read_override(self.ref) end
    self.last_shot_override=ok and value or nil
    if ok and value==self.block_damage then self.blocked_shots=self.blocked_shots+1 end
    if env.warn then env.warn("SteamID damage gate: protected aim_fire observed; conditional Min. Damage gate did not guarantee exclusion; see Export Report") end
  end
  function M:guard(method,...)
    local ok,why=pcall(method,self,...)
    if not ok then
      self.errors=self.errors+1;self:restore_all("callback failure cleanup")
      self.state="FAULT: SteamID damage gate callback failed"
      if env.warn then env.warn(self.state..": "..tostring(why):gsub("%c"," "):sub(1,160)) end
    end
    return ok
  end
  function M:report_lines()
    local ok,value=false,nil;if self.ref then ok,value=self:read_override(self.ref) end
    return {"SteamID exclusion enabled="..tostring(env.enabled()).." target="..self.steamid.." state="..self.state,
      string.format("SteamID damage gate scans=%d identity_matches=%d commands=%d blocked_commands=%d verified_writes=%d restores=%d conflicts=%d errors=%d protected_aim_fire=%d aim_fire_with_block_value=%d",self.scans,self.matches,self.commands,self.blocked_commands,self.writes,self.restores,self.conflicts,self.errors,self.protected_shots,self.blocked_shots),
      "SteamID damage gate requested=200 actual_override="..tostring(ok and value or nil).." owned="..tostring(self.owner~=nil).." last_command="..tostring(self.last_command_number).." protected_threat_id="..tostring(self.last_threat_id).." SDK_uid="..tostring(self.last_threat_uid),
      "SteamID damage gate last_reason="..tostring(self.last_gate_reason).." last_protected_shot_override="..tostring(self.last_shot_override).." invalidations="..self.invalidations.." invalidation_failures="..self.invalidation_failures,
      "SteamID damage gate scope=GLOBAL temporary Min. Damage when protected current threat OR only protected alive enemies; other targets also constrained while active; threat can differ from final shot target; manual IN_ATTACK untouched; NO immunity writes/server/remote-client protection",
      "SteamID damage gate restore=previous override value, compare-before-restore; externally changed value preserved; early command release and late application; clamped/rejected 200 rolls back and latches unavailable until Lua reload"}
  end
  return M
end

Y.steam_exclusion=create_steam_exclusion({
  identity=Y.steam_identity,
  steamid="76561199583065637",
  enabled=function()return true end,
  live=function()
    if cfg.runtime_paused or ANEMONE_SECOND_COPY or globals.is_in_game~=true or not N:master_enabled() then return false end
    local me=entity.get_local_player();return me and me:is_alive() or false
  end,
  now=clock,
  players=function()return entity.get_players(false,true)end,
  enemies=function()return entity.get_players(true,false)end,
  entity=function(id)return entity.get(id)end,
  threat=function()return entity.get_threat() or entity.get_threat(true)end,
  eligible=function(ent)
    if not ent or not ent:is_alive() or ent:is_dormant() or not ent:is_enemy() then return false end
    local me=entity.get_local_player();return me and ent:get_index()~=me:get_index() or false
  end,
  damage_ref=function()return N:find({"Aimbot","Ragebot","Selection","Min. Damage"})end,
  invalidate=function(id,uid)
    if Y.native_trace then
      local trace=Y.native_trace;trace:cancel_transfer_uid(uid,"protected SteamID damage gate")
      local slots=trace:bridge_stats().slots;local remove={}
      for bucket,d in pairs(slots)do if d.id==id and d.uid==uid then remove[#remove+1]=bucket end end
      for _,bucket in ipairs(remove)do if not trace:bridge_disarm_bucket(bucket,"protected SteamID damage gate")then return false end end
    end
    if Y.native_records then
      local pending=Y.native_records.selector_pending and Y.native_records.selector_pending[id]
      if pending and pending.uid==uid then Y.native_records.selector_pending[id]=nil end
      local receipt=Y.native_records.receipts[id]
      if receipt and receipt.uid==uid then return Y.native_records:selector_release(id)end
    end
    return true
  end,
  warn=function(text)warn_once("steam_damage_gate_"..text:sub(1,48),text)end
})
chain("createmove",function(cmd)Y.steam_exclusion:guard(Y.steam_exclusion.apply,cmd)end)
chain("render",function()Y.steam_exclusion:guard(Y.steam_exclusion.maintain)end)
for _,name in ipairs({"player_spawn","player_death","player_disconnect"})do
  chain(name,function()Y.steam_exclusion.dirty=true end)
end
chain("shutdown",function()
  if not Y.steam_exclusion:restore_all("shutdown")then console_line("[Anemone] SteamID damage gate: Min. Damage restoration pending; check native setting")end
end)
end

do
local function create_steam_marker(env)
  local M={targets={},dirty=true,scans=0,drawn=0,matches=0,anchor_misses=0,last="waiting",font=nil}
  local function finite(v)return type(v)=="number" and v==v and math.abs(v)<math.huge end
  local function identity(ent)
    local who=env.identity:resolve(ent)
    if who and who.steamid==env.steamid then return who.id,who.uid end
  end
  function M:reset()
    self.targets={};self.dirty=true;self.last_scan=nil;self.last="not in live game"
  end
  function M:discover(now)
    local ok,players=pcall(env.players)
    if not ok or type(players)~="table" then self.last="player list unavailable";return end
    local targets={}
    local function add(ent)
      if not ent then return end
      local id,uid=identity(ent)
      if id then targets[id]=uid;self.matches=self.matches+1 end
    end
    for _,ent in pairs(players)do add(ent)end
    if env.local_player then local got,me=pcall(env.local_player);if got then add(me)end end
    self.targets=targets;self.dirty=false;self.last_scan=now;self.scans=self.scans+1
  end
  function M:anchor(ent)
    local ok,bbox=pcall(function()return ent:get_bbox()end)
    if ok and type(bbox)=="table" and bbox.pos1 and bbox.pos2 then
      local good,x,y,alpha=pcall(function()
        local a,b=bbox.pos1,bbox.pos2
        if not finite(a.x) or not finite(a.y) or not finite(b.x) or not finite(b.y) or b.x<=a.x or b.y<=a.y then return nil end
        local alpha=bbox.alpha
        if not finite(alpha) or alpha<=0 then return nil end
        return (a.x+b.x)*0.5,a.y,math.min(1,alpha)
      end)
      if good then return x,y,alpha end
      return nil
    end
    local good,screen=pcall(function()
      local head=ent:get_hitbox_position(0)
      if not head or not finite(head.x) or not finite(head.y) or not finite(head.z) then return nil end
      return env.project(env.vector(head.x,head.y,head.z+10))
    end)
    if good and screen and finite(screen.x) and finite(screen.y) then return screen.x,screen.y,1 end
  end
  function M:draw()
    if not env.live() then if next(self.targets) or self.last_scan then self:reset()end;return end
    local now=env.now();if not finite(now) then return end
    if self.dirty or not self.last_scan or now<self.last_scan or now-self.last_scan>=0.5 then self:discover(now)end
    local screen=env.screen_size()
    if not screen or not finite(screen.x) or not finite(screen.y) or screen.x<1 or screen.y<1 then return end
    for id,uid in pairs(self.targets)do
      local got,ent=pcall(env.entity,id)
      local current_id,current_uid
      if got and ent then current_id,current_uid=identity(ent)end
      if current_id~=id or current_uid~=uid then self.targets[id]=nil;self.dirty=true
      else
        local eligible,alive=pcall(function()return ent:is_alive() and not ent:is_dormant()end)
        if eligible and alive then
          local x,y,alpha=self:anchor(ent)
          if not finite(x) or not finite(y) or not finite(alpha) then self.anchor_misses=self.anchor_misses+1;self.last="exact account matched; no visible screen anchor"end
          if finite(x) and finite(y) and finite(alpha) and x>=0 and x<=screen.x and y>=0 and y<=screen.y then
            if not self.font_attempted then
              self.font_attempted=true
              local ok,font=pcall(env.load_font);self.font=ok and font or 1
              if not self.font then self.font=1 end
              local good,size=pcall(env.measure,self.font,"PWNZ")
              self.text_w=good and size and finite(size.x) and size.x>0 and size.x<200 and size.x or 40
              self.text_h=good and size and finite(size.y) and size.y>0 and size.y<64 and size.y or 14
            end
            local box_y=math.max(self.text_h+7,y-28)
            if box_y+14<=screen.y then
              local a=math.floor(255*alpha)
              local green=env.color(72,255,112,a)
              local black=env.color(0,0,0,math.floor(210*alpha))
              local text_x,text_y=x-self.text_w*0.5,box_y-self.text_h-5
              env.text(self.font,env.vector(text_x+1,text_y+1),black,"PWNZ")
              env.text(self.font,env.vector(text_x,text_y),green,"PWNZ")
              env.rect(env.vector(x-8,box_y-1),env.vector(x+8,box_y+15),black)
              env.rect(env.vector(x-6,box_y+1),env.vector(x+6,box_y+13),env.color(10,24,14,math.floor(210*alpha)))
              env.outline(env.vector(x-7,box_y),env.vector(x+7,box_y+14),green)
              for offset=0,1 do
                env.line(env.vector(x-4,box_y+7+offset),env.vector(x-1,box_y+10+offset),green)
                env.line(env.vector(x-1,box_y+10+offset),env.vector(x+4,box_y+4+offset),green)
              end
              self.drawn=self.drawn+1;self.last="PWNZ + green checked box; last Anemone render callback"
            end
          end
        end
      end
    end
  end
  function M:report()
    return "SteamID="..env.steamid.." scans="..self.scans.." identity_matches="..self.matches.." anchor_misses="..self.anchor_misses.." drawn="..self.drawn.." state="..self.last.."; client-side overlay only; external ESP/Lua layer order not controlled"
  end
  return M
end

Y.steam_marker=create_steam_marker({
  identity=Y.steam_identity,
  steamid="76561199583065637",
  live=function()return not cfg.runtime_paused and not ANEMONE_SECOND_COPY and globals.is_in_game==true end,
  now=clock,
  players=function()return entity.get_players(false,false)end,
  local_player=function()return entity.get_local_player()end,
  entity=function(id)return entity.get(id)end,
  project=function(pos)return render.world_to_screen(pos)end,
  vector=vector,color=color,
  screen_size=function()return render.screen_size()end,
  load_font=function()return render.load_font("Verdana",14,"ab")end,
  measure=function(font,text)return render.measure_text(font,"",text)end,
  text=function(font,pos,c,text)render.text(font,pos,c,"",text)end,
  rect=function(a,b,c)render.rect(a,b,c)end,
  outline=function(a,b,c)render.rect_outline(a,b,c,1,1)end,
  line=function(a,b,c)render.line(a,b,c)end
})
for _,name in ipairs({"player_spawn","player_death","player_disconnect","level_init"})do
  chain(name,function()Y.steam_marker.dirty=true end)
end
chain("shutdown",function()Y.steam_marker:reset()end)
chain("render",function()
  local ok,why=pcall(Y.steam_marker.draw,Y.steam_marker)
  if not ok then warn_once("steam_marker_draw","SteamID visual: "..tostring(why):gsub("%c"," "):sub(1,180))end
end)
end

do
local function create_ffi_service(env)
  local M={targets={},network_runs=0,network_errors=0,first_fires=0,first_hits=0,first_misses=0,shots=0,last="waiting",gap=1.5}
  function M:network_ready()
    if self.busy or not env.enabled()then return end
    local reader,trace=env.reader(),env.trace()
    if not reader or not trace or not trace.running or trace.fault then return end
    local id=env.priority()
    if type(id)~="number"or id%1~=0 or id<1 or id>64 or not reader.selector_pending or not reader.selector_pending[id]then return end
    self.busy=true;self.network_runs=self.network_runs+1
    local started=trace:perf_start()
    local ok,why=pcall(function()
      reader:drain_selector(id,"network_ready")
      trace:prepare_transfers(id)
      trace:publish_transfers(id)
    end)
    self.busy=false;trace:perf_finish("network_ready",started)
    if not ok then
      self.network_errors=self.network_errors+1;self.last="network preparation failed: "..tostring(why):gsub("%c"," "):sub(1,140)
      trace:clear_transfer_pipeline(self.last)
    else self.last="priority target prepared after network observation; remaining targets stay in render queue"end
  end
  function M:fire(shot_id,id,uid)
    if env.audit_enabled and not env.audit_enabled()then return nil end
    local now=env.now()
    if type(now)~="number"or now~=now or type(uid)~="number"or uid<1 or type(id)~="number"or id<1 or id>64 then return nil end
    local state=self.targets[id]
    if state and state.uid==uid and state.shot_id==shot_id then return state.receipt end
    local first=not state or state.uid~=uid or now<state.time or now-state.time>self.gap
    local ordinal=first and 1 or state.ordinal+1
    local reader,trace=env.reader(),env.trace()
    local p=trace and trace:pipeline_stats()
    local pending=reader and reader.selector_pending and reader.selector_pending[id]
    local queued=p and p.candidates[id];local ready=p and p.ready[id]
    local receipt={first=first,ordinal=ordinal,uid=uid,id=id,shot_id=shot_id,time=now,
      selector_pending=pending~=nil,construction_pending=queued~=nil,publication_pending=ready~=nil,
      approval_present=trace and trace:bridge_has_target(id,uid)==true or false,
      last_pipeline=p and p.last or "trace unavailable"}
    self.targets[id]={uid=uid,time=now,ordinal=ordinal,shot_id=shot_id,receipt=receipt}
    self.shots=self.shots+1;if first then self.first_fires=self.first_fires+1 end
    return receipt
  end
  function M:ack(receipt,reason)
    if not receipt or receipt.acked then return end
    receipt.acked=true
    if receipt.first then
      if reason==nil then self.first_hits=self.first_hits+1 else self.first_misses=self.first_misses+1 end
    end
  end
  function M:departure(uid)
    for id,state in pairs(self.targets)do if state.uid==uid then self.targets[id]=nil end end
  end
  function M:report_lines()
    return {string.format("FFI early preparation network_runs=%d errors=%d state=%s; own-matrix mode ONLY, active trace required; exact SDK/native/UID/ring/expiry guards unchanged",self.network_runs,self.network_errors,self.last),
      string.format("FFI first-shot audit fires=%d first_fires=%d first_hits=%d first_misses=%d; first=first shot for SDK UID after >1.5s fire gap or identity/departure reset; pending acks are not misses; approval presence is NOT native consumption",self.shots,self.first_fires,self.first_hits,self.first_misses)}
  end
  return M
end

Y.ffi_service=create_ffi_service({
  enabled=function()return yaw_mode()=="FFI"and Y.native_requested()and globals.is_in_game==true end,
  audit_enabled=function()return yaw_mode()=="FFI"and globals.is_in_game==true and not cfg.runtime_paused and not ANEMONE_SECOND_COPY end,
  now=clock,reader=function()return Y.native_records end,trace=function()return Y.native_trace end,
  priority=function()local target=entity.get_threat();return target and target:get_index()or nil end
})
for _,name in ipairs({"player_death","player_disconnect","player_spawn"})do
  chain(name,function(event)Y.ffi_service:departure(tonumber(event.userid))end)
end
for _,name in ipairs({"round_start","level_init","shutdown"})do
  chain(name,function()Y.ffi_service.targets={}end)
end
end

chain("net_update_end",function()
  if not cfg.runtime_paused and not ANEMONE_SECOND_COPY and get_bool(cfg.forceshot)and N:master_enabled()then
    local ok,err=pcall(FS.sampled_gate,FS,true)
    if not ok then FS.spread_sampler:clear();warn_once("forceshot_prepare",tostring(err))end
  end
end)
 