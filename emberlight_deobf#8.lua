local menu_label = "emberlight • beta"
local menu_icon = ""
local menu_note = ""
local seen_keys = {}
local function raw_log(text)
  text = tostring(text)
  local ok = pcall(function()
    print_raw(text .. "\n")
  end)
  if not ok then
    pcall(function()
      print(text)
    end)
  end
end
local function log_once(key, text)
  if seen_keys[key] then
    return
  end
  seen_keys[key] = true
  raw_log("[Emberlight] " .. text)
end
local instance_id = tostring({})
local dup_warned = false
local event_subs = {}
local function on_event(name, fn)
  local list = event_subs[name]
  if not list then
    list = {}
    event_subs[name] = list
    local ok, err = pcall(function()
      events[name]:set(function(arg)
        for _, sub in ipairs(list) do
          local sok, serr = pcall(sub, arg)
          if not sok then
            log_once(
                "chain_" .. name,
                name .. ": " .. tostring(serr):gsub("%c", " "))
          end
        end
      end)
    end)
    if not ok then
      event_subs[name] = nil
      log_once(
          "hook_" .. name,
          "Event unavailable: " .. name .. "; see diagnostics.")
      return false
    end
  end
  list[#list + 1] = fn
  return true
end
local function check_duplicate()
  local ok, dup = pcall(function()
    local now = 0
    if globals and type(globals.realtime) == "number" then
      now = globals.realtime
    end
    local holder = _G.__EMBERLIGHT_HOLDER
    if type(holder) == "table" and holder.id ~= instance_id and
      (now - (holder.t or 0)) < 1 then
      return true
    end
    _G.__EMBERLIGHT_HOLDER = { id = instance_id, t = now }
    return false
  end)
  if ok and dup then
    if not dup_warned then
      dup_warned = true
      log_once(
          "second_copy",
          "Duplicate Emberlight instance detected; this copy idles. Unload the extra Emberlight script from the Lua list!")
    end
    return true
  end
  dup_warned = false
  return false
end
pcall(function()
  ui.sidebar(menu_label, "meteor")
end)
pcall(function()
  cvar.clear:call()
end)
local function finite(value)
  if type(value) ~= "number" or value ~= value then
    return nil
  end
  if value == math.huge or value == -math.huge then
    return nil
  end
  return value
end
local function clamp(value, low, high)
  return math.max(low, math.min(high, value))
end
local function game_time()
  return (globals and finite(globals.realtime)) or 0
end
local function item_enabled(item)
  local ok, value = pcall(function()
    return item:get()
  end)
  return ok and value == true
end
local function first_icon(names)
  for i = 1, #names do
    local ok, value = pcall(function()
      return ui.get_icon(names[i])
    end)
    if ok and type(value) == "string" and value ~= "" then
      return value
    end
  end
  return ""
end
local function label_with_icon(ic, text)
  return menu_icon .. (ic ~= "" and (ic .. "  ") or "") .. text
end
local function noop(item, text)
end
local function get_username()
  local ok, value = pcall(function()
    return common.get_username()
  end)
  if ok and type(value) == "string" and value ~= "" then
    return value
  end
  log_once(
         "cheat_username",
         "Neverlose username unavailable; no Steam/workspace nickname substituted.")
  return "Unknown"
end
local function strip_colours(value)
  local text = tostring(value)
  text = text:gsub(string.char(7) .. "%x%x%x%x%x%x%x%x", ""):gsub(
                                                         string.char(7) .. "DEFAULT",
                                                         ""):gsub("%c", " "):gsub(" +", " "):gsub("^%s+", ""):gsub("%s+$", "")
  return text ~= "" and text or "Unknown"
end
local function info_field(group, title, value)
  local names = title == "User" and { "user", "circle-user", "user-circle" } or
    { "cube", "layer-group", "code" }
  local glyph = first_icon(names)
  local prefix = glyph ~= "" and (menu_icon .. glyph .. "  ") or ""
  return group:label(prefix .. menu_icon .. strip_colours(title) ..
    "   " .. menu_icon .. strip_colours(value) .. menu_note)
end
local function info_rows(group, items)
  local segments = {}
  for i, kv in ipairs(items) do
    local title, value = kv[1], kv[2]
    local names = title == "User" and { "user", "circle-user", "user-circle" } or
      { "cube", "layer-group", "code" }
    local glyph = first_icon(names)
    local prefix = glyph ~= "" and (menu_icon .. glyph .. "  ") or ""
    local seg = prefix ..
      menu_icon .. strip_colours(title) .. " " .. menu_icon .. strip_colours(value)
    if i > 1 then
      seg = menu_icon .. "› " .. seg
    end
    segments[i] = seg
  end
  return group:label(table.concat(segments, "") .. menu_note)
end
local app = {}
app.main_tab = first_icon({ "island-tropical", "sunrise", "house" })
if app.main_tab == "" then
  app.main_tab = "Main"
end
local main_panel = ui.create(app.main_tab, "​", 2)
local function icon_label(names, text)
  local glyph = first_icon(names)
  return (glyph ~= "" and (glyph .. "  ") or "") .. text
end
local section_items = {
  icon_label({ "circle-info", "info-circle", "info" }, "Information"),
  icon_label({ "sliders", "gears", "gear", "function" }, "Functions"),
}
app.section = main_panel:list("", section_items)
pcall(function()
  app.section:set(1)
end)
app.workspace_items = {
  icon_label({ "house", "home" }, "Home"),
  icon_label({ "folder-gear", "folder", "floppy-disk", "gear" }, "Configs"),
}
app.workspace = main_panel:list("", app.workspace_items)
pcall(function()
  app.workspace:set(1)
end)
app.version_state = { beta_updated = "27/09/26 - 22:34" }
app.version_state.clean_bind_name = function(value)
  local text, mark = tostring(value or ""), string.char(7)
  text = text:gsub(mark .. "%x%x%x%x%x%x%x%x", ""):gsub(mark .. "%b{}", ""):gsub(
                                                                        mark .. "DEFAULT",
                                                                        "")
  return text:gsub("[%c%z]", ""):gsub("[^%w%s%-%._]", ""):gsub("%s+", " "):gsub(
                                                                       "^%s+",
                                                                       ""):gsub("%s+$", "")
end
app.version_state.sanitize_live_binds = function()
  local ok, binds = pcall(ui.get_binds)
  if not ok or type(binds) ~= "table" then
    return
  end
  for _, bind in pairs(binds) do
    local clean = app.version_state.clean_bind_name(bind.name)
    if clean ~= "" and clean ~= tostring(bind.name or "") then
      pcall(function()
        bind.name = clean
      end)
    end
  end
end
pcall(function()
  events.render(function()
    pcall(app.version_state.sanitize_live_binds)
  end)
end)
app.version_state.tier = function()
  return "beta"
end
app.version_state.tiers = { beta = { "Free", "Beta" } }
app.version_state.tier_modes = function()
  return app.version_state.tiers.beta
end
app.version_state.legacy_modes =
    { Main = "Free", Trial = "Beta", Bypass = "Beta", Test = "Beta" }
app.version_state.normalize_mode = function(value)
  return type(value) == "string" and
    (app.version_state.legacy_modes[value] or value) or nil
end
app.version_state.allowed_mode = function(value)
  value = app.version_state.normalize_mode(value)
  return value == "Beta" and "Beta" or "Free"
end
app.version_state.sync_mode_items = function()
  local modes = app.version_state.tiers.beta
  local ok = pcall(function()
    app.yaw_mode:update(modes)
  end)
  if not ok then
    ok = pcall(function()
      app.yaw_mode:items(modes)
    end)
  end
  if ok then
    app.yaw_mode:set(app.version_state.allowed_mode(app.yaw_mode:get()))
  end
  return ok
end
app.config_panel = ui.create(app.main_tab, "​​​⁠", 1)
app.config_system = { version = 1, active_kind = "builtin", has_users = false, user_names = {}, profile = "beta", stores = { beta = {} }, store = {}, builtin_names = { "PWNZ$CRASH", "666TEST" }, builtins = {
  ["PWNZ$CRASH"] = "{\"name\":\"123\",\"row\":{\"updated\":0.0,\"values\":{\"aspect\":false,\"aspect_value\":100.0,\"assist\":false,\"avoid_collision\":true,\"clantag\":true,\"crosshair_indicator\":true,\"crosshair_indicator_color\":{\"__ember_kind\":\"color\",\"a\":255.0,\"b\":98.0,\"g\":202.0,\"r\":43.0},\"crosshair_indicator_shadow\":true,\"damage_indicator\":true,\"damage_indicator_color\":{\"__ember_kind\":\"color\",\"a\":255.0,\"b\":98.0,\"g\":202.0,\"r\":43.0},\"damage_indicator_font\":\"Pixel\",\"effects\":true,\"effects_mode\":\"CSGO\",\"extrapolation\":true,\"extrapolation_mode\":\"Adaptive\",\"fast_ladder\":true,\"forceshot\":false,\"forceshot_mode\":\"CSGO\",\"fortnite_hit\":true,\"fps_optimizer\":true,\"hit_effect\":true,\"hotkeys\":false,\"interpolation\":true,\"jump_scout\":true,\"kill_particle_amount\":18.0,\"kill_particle_color\":{\"__ember_kind\":\"color\",\"a\":255.0,\"b\":98.0,\"g\":202.0,\"r\":43.0},\"kill_particle_duration\":2.0,\"kill_particles\":true,\"model_changer\":false,\"model_changer_ct\":\"z-piks.ru/gta_crip\",\"model_changer_t\":\"eminem/gta_sa/vwfypro\",\"model_changer_team\":[\"CT\",\"T\"],\"movement\":true,\"no_fall_damage\":true,\"notification_console\":false,\"notification_debug\":false,\"notification_screen\":false,\"notifications\":false,\"opt_list\":[\"Decals\",\"Blood and gibs\",\"Tracers\",\"Breakable debris\",\"3D sky\",\"Ropes\"],\"opt_preset\":\"Maximum FPS\",\"predict_strength\":\"Extreme\",\"presets\":[],\"resolver\":true,\"specs_header\":false,\"spectators\":true,\"unsafe_mode\":\"Unsafe Exploit\",\"unsafe_recharge\":true,\"watermark\":true,\"wm_accent\":{\"__ember_kind\":\"color\",\"a\":255.0,\"b\":43.0,\"g\":202.0,\"r\":159.0},\"wm_elements\":[\"Logo\",\"FPS\",\"Frametime variance\",\"Ping\"],\"wm_eval_accent\":{\"__ember_kind\":\"color\",\"a\":255.0,\"b\":255.0,\"g\":190.0,\"r\":185.0},\"wm_eval_elements\":[\"Version\",\"Username\",\"Latency\",\"Frames\",\"Time\"],\"wm_eval_time_format\":\"24h\",\"wm_eval_username_custom\":\"\",\"wm_eval_username_source\":\"Cheat\",\"wm_nl_accent\":{\"__ember_kind\":\"color\",\"a\":255.0,\"b\":97.0,\"g\":202.0,\"r\":42.0},\"wm_nl_elements\":[\"Avatar\",\"Username\",\"Clock\",\"FPS\",\"Ping\",\"Var\",\"Loss\",\"Build\",\"Blur\"],\"wm_position\":\"Top-right\",\"wm_style\":\"Neverlose\",\"yaw\":true,\"yaw_mode\":\"Bypass\"},\"version\":1.0}}",
  ["666TEST"] = "{\"name\":\"1234\",\"row\":{\"updated\":0.0,\"values\":{\"aspect\":false,\"aspect_value\":100.0,\"assist\":false,\"avoid_collision\":true,\"clantag\":true,\"crosshair_indicator\":true,\"crosshair_indicator_color\":{\"__ember_kind\":\"color\",\"a\":255.0,\"b\":43.0,\"g\":43.0,\"r\":202.0},\"crosshair_indicator_shadow\":true,\"damage_indicator\":true,\"damage_indicator_color\":{\"__ember_kind\":\"color\",\"a\":255.0,\"b\":42.0,\"g\":42.0,\"r\":202.0},\"damage_indicator_font\":\"Pixel\",\"effects\":true,\"effects_mode\":\"CSGO\",\"extrapolation\":true,\"extrapolation_mode\":\"Aggressive\",\"fast_ladder\":true,\"forceshot\":false,\"forceshot_mode\":\"CS2\",\"fortnite_hit\":true,\"fps_optimizer\":true,\"hit_effect\":true,\"hotkeys\":false,\"interpolation\":true,\"jump_scout\":true,\"kill_particle_amount\":18.0,\"kill_particle_color\":{\"__ember_kind\":\"color\",\"a\":255.0,\"b\":43.0,\"g\":43.0,\"r\":202.0},\"kill_particle_duration\":2.0,\"kill_particles\":true,\"model_changer\":false,\"model_changer_ct\":\"z-piks.ru/gta_crip\",\"model_changer_t\":\"eminem/gta_sa/vwfypro\",\"model_changer_team\":[\"CT\",\"T\"],\"movement\":true,\"no_fall_damage\":true,\"notification_console\":false,\"notification_debug\":false,\"notification_screen\":false,\"notifications\":false,\"opt_list\":[\"Decals\",\"Blood and gibs\",\"Tracers\",\"Breakable debris\",\"3D sky\",\"Ropes\"],\"opt_preset\":\"Maximum FPS\",\"predict_strength\":\"Extreme\",\"presets\":[],\"resolver\":true,\"specs_header\":false,\"spectators\":true,\"unsafe_mode\":\"Faster Charge\",\"unsafe_recharge\":true,\"watermark\":true,\"wm_accent\":{\"__ember_kind\":\"color\",\"a\":255.0,\"b\":43.0,\"g\":43.0,\"r\":202.0},\"wm_elements\":[\"Logo\",\"FPS\",\"Frametime variance\",\"Ping\",\"Speed\",\"K/D ratio\",\"Clock\"],\"wm_eval_accent\":{\"__ember_kind\":\"color\",\"a\":255.0,\"b\":255.0,\"g\":190.0,\"r\":185.0},\"wm_eval_elements\":[\"Version\",\"Username\",\"Latency\",\"Frames\",\"Time\"],\"wm_eval_time_format\":\"24h\",\"wm_eval_username_custom\":\"\",\"wm_eval_username_source\":\"Cheat\",\"wm_nl_accent\":{\"__ember_kind\":\"color\",\"a\":255.0,\"b\":97.0,\"g\":202.0,\"r\":42.0},\"wm_nl_elements\":[\"Avatar\",\"Username\",\"Clock\",\"FPS\",\"Ping\",\"Var\",\"Loss\",\"Build\",\"Blur\"],\"wm_position\":\"Top-right\",\"wm_style\":\"Gamesense\",\"yaw\":true,\"yaw_mode\":\"Test\"},\"version\":1.0}}",
} }
app.config_system.profile_name = function()
  return "beta"
end
app.config_system.active_builtins = function()
  return app.config_system.builtin_names
end
app.config_system.switch_profile = function()
  app.config_system.profile = app.config_system.profile_name()
  app.config_system.store =
      app.config_system.stores[app.config_system.profile] or {}
  app.config_system.stores[app.config_system.profile] =
      app.config_system.store
  if app.config_list then
    app.config_system.refresh()
  end
end
app.config_system.notify = function(text)
  pcall(function()
    common.add_notify("Emberlight Configs", tostring(text))
  end)
  raw_log("[Emberlight Configs] " .. tostring(text))
end
app.config_system.clean_name = function(value)
  local name = tostring(value or "")
  name = name:gsub("[%c]", ""):gsub("^%s+", ""):gsub("%s+$", ""):gsub(
                                                             "[/\\:*?\"<>|]",
                                                             "")
  if #name > 32 then
    name = name:sub(1, 32)
  end
  return name
end
app.config_system.colored_icon = function(names, fallback, hex)
  local glyph = first_icon(names)
  if glyph == "" then
    glyph = fallback
  end
  return string.char(7) .. hex .. glyph .. string.char(7) .. "DEFAULT"
end
app.config_system.config_label = function(names, fallback, name)
  return app.config_system.colored_icon(names, fallback, "23B7FFFF") ..
    "  " .. tostring(name)
end
app.config_system.name_conflict = function(name, include_users)
  local needle = tostring(name or ""):lower()
  if needle:match("^%-+$") or needle == "no user configs" then
    return "reserved"
  end
  for _, builtin in ipairs(app.config_system.active_builtins()) do
    if builtin:lower() == needle then
      return "prepared"
    end
  end
  if include_users then
    for existing in pairs(app.config_system.store) do
      if tostring(existing):lower() == needle then
        return "user"
      end
    end
  end
  return nil
end
app.config_system.encode_value = function(value, depth)
  depth = depth or 0
  if depth > 5 then
    return nil
  end
  local kind = type(value)
  if kind == "nil" or kind == "boolean" or kind == "number" or kind == "string" then
    return value
  end
  if kind == "table" then
    local out = {}
    for key, item in pairs(value) do
      local encoded = app.config_system.encode_value(item, depth + 1)
      if encoded ~= nil and (type(key) == "number" or type(key) == "string") then
        out[key] = encoded
      end
    end
    return out
  end
  local ok, r, g, b, a = pcall(function()
    return
        tonumber(value.r),
        tonumber(value.g),
        tonumber(value.b),
        tonumber(value.a)
  end)
  if ok and r and g and b then
    return { __ember_kind = "color", r = r, g = g, b = b, a = a or 255 }
  end
  return nil
end
app.config_system.decode_value = function(value)
  if type(value) == "table" and value.__ember_kind == "color" then
    return color(
        tonumber(value.r) or 255,
        tonumber(value.g) or 255,
        tonumber(value.b) or 255,
        tonumber(value.a) or 255)
  end
  return value
end
app.config_system.is_config_item = function(key, item)
  if key == "section" or key == "workspace" or key == "workspace_items" or
    key == "config_panel" or key == "config_system" then
    return false
  end
  if tostring(key):sub(1, 7) == "config_" or
    tostring(key):sub(1, 8) == "version_" then
    return false
  end
  local ok, item_type = pcall(function()
    return item:type()
  end)
  return ok and item_type ~= "button" and item_type ~= "label" and
    item_type ~= "texture"
end
app.config_system.capture = function()
  local t1 = {}
  for key, item in pairs(app) do
    if app.config_system.is_config_item(key, item) then
      local ok, value = pcall(function()
        return item:get()
      end)
      if ok then
        local encoded = app.config_system.encode_value(value, 0)
        if encoded ~= nil then
          t1[key] = encoded
        end
      end
    end
  end
  return t1
end
app.config_system.set_item = function(key, encoded)
  local item = app[key]
  if not item or not app.config_system.is_config_item(key, item) then
    return
  end
  pcall(function()
    item:set(app.config_system.decode_value(encoded))
  end)
end
app.config_system.apply_resolver_path = function(a1)
  if a1.resolver ~= nil then
    app.config_system.set_item("resolver", a1.resolver)
  end
  if a1.assist ~= nil then
    app.config_system.set_item("assist", a1.assist)
  end
  if a1.yaw ~= nil then
    app.config_system.set_item("yaw", a1.yaw)
  end
  if a1.assist ~= nil then
    app.config_system.set_item("assist", a1.assist)
  end
end
app.config_system.apply = function(a1)
  if type(a1) ~= "table" then
    return false
  end
  for key, value in pairs(a1) do
    if key ~= "resolver" and key ~= "assist" and key ~= "yaw" then
      app.config_system.set_item(key, value)
    end
  end
  app.config_system.apply_resolver_path(a1)
  pcall(function()
    local stored = app.yaw_mode:get()
    local normalized = app.version_state.normalize_mode(stored)
    if normalized and normalized ~= stored then
      app.yaw_mode:set(normalized)
    end
    app.version_state.sync_mode_items()
  end)
  pcall(function()
    utils.execute_after(0.05, function()
      pcall(app.config_system.apply_resolver_path, a1)
    end)
  end)
  return true
end
app.config_system.reset_items = function()
  for key, item in pairs(app) do
    if app.config_system.is_config_item(key, item) then
      pcall(function()
        item:reset()
      end)
    end
  end
end
app.config_system.persist = function()
  app.config_system.stores[app.config_system.profile] =
      app.config_system.store
  pcall(function()
    db.emberlight_user_configs_v1 = app.config_system.store
  end)
end
app.config_system.current_entry = function()
  local ok, value = pcall(function()
    return app.config_list:get()
  end)
  if not ok then
    return nil, nil
  end
  local index = nil
  if type(value) == "number" then
    index = value
  else
    for i, name in ipairs(app.config_system.combined_items or {}) do
      if value == name then
        index = i
        break
      end
    end
  end
  if not index then
    return nil, nil
  end
  return
      app.config_system.combined_kinds[index],
      app.config_system.combined_names[index]
end
app.config_system.sync_actions = function()
  local user_mode =
      app.config_system.active_kind == "user" and app.config_system.has_users
  for _, item in ipairs({ app.config_save, app.config_export, app.config_delete }) do
    if item then
      pcall(function()
        item:disabled(not user_mode)
      end)
    end
  end
end
app.config_system.refresh = function(preferred)
  app.config_system.user_names = {}
  for name, data in pairs(app.config_system.store) do
    if type(name) == "string" and type(data) == "table" then
      app.config_system.user_names[#app.config_system.user_names + 1] = name
    end
  end
  table.sort(app.config_system.user_names, function(a, b)
    return a:lower() < b:lower()
  end)
  app.config_system.has_users = #app.config_system.user_names > 0
  app.config_system.combined_items = {}
  app.config_system.combined_kinds = {}
  app.config_system.combined_names = {}
  local active_builtins = app.config_system.active_builtins()
  for _, name in ipairs(active_builtins) do
    local names =
        name == "PWNZ$CRASH" and { "crown" } or { "star", "asterisk" }
    local fallback = name == "PWNZ$CRASH" and "♛" or "★"
    app.config_system.combined_items[#app.config_system.combined_items + 1] =
        app.config_system.config_label(names, fallback, name)
    app.config_system.combined_kinds[#app.config_system.combined_kinds + 1] =
        "builtin"
    app.config_system.combined_names[#app.config_system.combined_names + 1] =
        name
  end
  if #active_builtins > 0 then
    app.config_system.combined_items[#app.config_system.combined_items + 1] =
        "---------------------------------------"
    app.config_system.combined_kinds[#app.config_system.combined_kinds + 1] =
        "separator"
    app.config_system.combined_names[#app.config_system.combined_names + 1] =
        "__separator__"
  end
  if app.config_system.has_users then
    for _, name in ipairs(app.config_system.user_names) do
      app.config_system.combined_items[#app.config_system.combined_items + 1] = app.config_system.config_label(
                               { "list-ul", "list", "bars-staggered" },
                               "≡",
                               name)
      app.config_system.combined_kinds[#app.config_system.combined_kinds + 1] =
          "user"
      app.config_system.combined_names[#app.config_system.combined_names + 1] =
          name
    end
  else
    app.config_system.combined_items[#app.config_system.combined_items + 1] =
        "No user configs"
    app.config_system.combined_kinds[#app.config_system.combined_kinds + 1] =
        "empty"
    app.config_system.combined_names[#app.config_system.combined_names + 1] =
        "No user configs"
  end
  pcall(function()
    app.config_list:update(app.config_system.combined_items)
  end)
  if preferred and app.config_system.has_users then
    local preferred_index = 1
    for i, name in ipairs(app.config_system.combined_names) do
      if name == preferred then
        preferred_index = i
        break
      end
    end
    pcall(function()
      app.config_list:set(preferred_index)
    end)
    app.config_system.active_kind = "user"
  else
    pcall(function()
      app.config_list:set(1)
    end)
    app.config_system.active_kind = "builtin"
  end
  app.config_system.sync_actions()
end
app.config_system.user_selected = function()
  local kind, name = app.config_system.current_entry()
  return kind == "user" and name or nil
end
app.config_system.load_active = function()
  local kind, name = app.config_system.current_entry()
  if kind == "builtin" then
    local payload = name and app.config_system.builtins[name] or nil
    if not payload then
      app.config_system.notify("Select a prepared config first.")
      return
    end
    local parsed_ok, parsed = pcall(json.parse, payload)
    if not parsed_ok or type(parsed) ~= "table" or type(parsed.row) ~= "table" or
      type(parsed.row.values) ~= "table" then
      app.config_system.notify(
                         "Prepared config is damaged: " .. tostring(name))
      return
    end
    app.config_system.apply(parsed.row.values)
    app.config_system.notify("Loaded prepared config: " .. name)
    return
  end
  if kind ~= "user" then
    app.config_system.notify("Select a config first.")
    return
  end
  local row = name and app.config_system.store[name] or nil
  if not row or type(row.values) ~= "table" then
    app.config_system.notify("Select a user config first.")
    return
  end
  app.config_system.apply(row.values)
  app.config_system.notify("Loaded user config: " .. name)
end
app.config_system.create = function()
  local name = app.config_system.clean_name(app.config_name:get())
  if name == "" then
    app.config_system.notify("Enter a config name.")
    return
  end
  local conflict = app.config_system.name_conflict(name, true)
  if conflict == "prepared" or conflict == "reserved" then
    app.config_system.notify("This name is reserved by a prepared config.")
    return
  elseif conflict == "user" then
    app.config_system.notify("A config with this name already exists.")
    return
  end
  app.config_system.store[name] = {
    version = app.config_system.version,
    updated = os and os.time and os.time() or 0,
    values = app.config_system.capture(),
  }
  app.config_system.persist()
  app.config_system.active_kind = "user"
  app.config_system.refresh(name)
  app.config_system.notify("Created config: " .. name)
end
app.config_system.save = function()
  local name = app.config_system.user_selected()
  if app.config_system.active_kind ~= "user" or not name then
    app.config_system.notify("Prepared configs are read-only.")
    return
  end
  app.config_system.store[name] = {
    version = app.config_system.version,
    updated = os and os.time and os.time() or 0,
    values = app.config_system.capture(),
  }
  app.config_system.persist()
  app.config_system.notify("Saved config: " .. name)
end
app.config_system.delete = function()
  local name = app.config_system.user_selected()
  if app.config_system.active_kind ~= "user" or not name then
    app.config_system.notify("Prepared configs cannot be deleted.")
    return
  end
  app.config_system.store[name] = nil
  app.config_system.persist()
  app.config_system.active_kind = "builtin"
  app.config_system.refresh()
  app.config_system.notify("Deleted config: " .. name)
end
app.config_system.export = function()
  local name = app.config_system.user_selected()
  local row = name and app.config_system.store[name] or nil
  if app.config_system.active_kind ~= "user" or not row then
    app.config_system.notify("Prepared configs cannot be exported.")
    return
  end
  local ok, err = pcall(function()
    local clipboard = require("neverlose/clipboard")
    local prefix = "EMBERLIGHT_CFG_V1:"
    clipboard.set(prefix .. json.stringify({ name = name, row = row }))
  end)
  if not ok then
    app.config_system.notify("Export failed: " .. tostring(err))
    return
  end
  app.config_system.notify("Exported to clipboard: " .. name)
end
app.config_system.import = function()
  local ok, payload = pcall(function()
    local clipboard = require("neverlose/clipboard")
    return clipboard.get()
  end)
  if not ok or type(payload) ~= "string" then
    app.config_system.notify("Could not read the clipboard.")
    return
  end
  local prefix = "EMBERLIGHT_CFG_V1:"
  if payload:sub(1, #prefix) ~= prefix then
    app.config_system.notify("Invalid Emberlight config string.")
    return
  end
  local parsed_ok, parsed = pcall(json.parse, payload:sub(#prefix + 1))
  if not parsed_ok or type(parsed) ~= "table" or type(parsed.row) ~= "table" or
    type(parsed.row.values) ~= "table" then
    app.config_system.notify("The imported config is damaged.")
    return
  end
  local requested = app.config_system.clean_name(app.config_name:get())
  local name =
      requested ~= "" and requested or app.config_system.clean_name(parsed.name)
  if name == "" then
    app.config_system.notify("Enter a name for the imported config.")
    return
  end
  local conflict = app.config_system.name_conflict(name, false)
  if conflict == "prepared" or conflict == "reserved" then
    app.config_system.notify("This name is reserved by a prepared config.")
    return
  end
  app.config_system.store[name] = parsed.row
  app.config_system.persist()
  app.config_system.active_kind = "user"
  app.config_system.refresh(name)
  app.config_system.notify("Imported config: " .. name)
end
app.config_list = app.config_panel:list("", {
  app.config_system.config_label({ "crown" }, "♛", "PWNZ$CRASH"),
  app.config_system.config_label({ "star", "asterisk" }, "★", "666TEST"),
  "---------------------------------------",
  "No user configs",
})
app.config_name = app.config_panel:input("Configs Name")
app.config_create = app.config_panel:button(app.config_system.colored_icon({ "circle-plus", "plus" }, "+", "55D66BFF"), function()
  app.config_system.create()
end, true)
app.config_load = app.config_panel:button("Load", function()
  app.config_system.load_active()
end, true)
app.config_save = app.config_panel:button("Save", function()
  app.config_system.save()
end, true)
app.config_import = app.config_panel:button("Import", function()
  app.config_system.import()
end, true)
app.config_export = app.config_panel:button("Export", function()
  app.config_system.export()
end, true)
app.config_delete = app.config_panel:button(app.config_system.colored_icon({ "trash", "trash-can" }, "×", "FF4D5AFF"), function()
  app.config_system.delete()
end, true)
pcall(function()
  local beta_saved = db.emberlight_user_configs_v1
  if type(beta_saved) == "table" then
    app.config_system.stores.beta = beta_saved
  end
end)
app.config_system.profile = "beta"
app.config_system.store = app.config_system.stores.beta
app.config_system.refresh()
pcall(function()
  app.config_list:set_callback(function()
    local kind, name = app.config_system.current_entry()
    app.config_system.active_kind = kind or "none"
    if kind == "user" and name then
      app.config_name:set(name)
    elseif kind ~= "user" then
      app.config_name:set("")
    end
    app.config_system.sync_actions()
  end, true)
end)
local info_tab = ui.create(app.main_tab, "‌", 1)
local function detail_field(group, title, value)
  local icon_names = title == "User" and { "user", "circle-user", "user-circle" } or
    title == "Build" and { "cube", "layer-group", "code" } or { "clock", "calendar", "rotate" }
  group:label(label_with_icon(first_icon(icon_names), strip_colours(title)))
  local text = " " .. strip_colours(value) .. " "
  local ok, item = pcall(function()
    return group:button(menu_icon .. text .. menu_note, nil, true)
  end)
  if ok then
    return item
  end
  return group:label(menu_icon .. text .. menu_note)
end
local function open_url(url)
  local ok = pcall(function()
    local pano = panorama
    if not pano then
      pano = require("panorama")
    end
    local api = pano.open and pano.open() or pano
    if api and api.SteamOverlayAPI and
      api.SteamOverlayAPI.OpenExternalBrowserURL then
      api.SteamOverlayAPI.OpenExternalBrowserURL(url)
      return
    end
    error("SteamOverlayAPI unavailable")
  end)
  if not ok then
    ok = pcall(function()
      local command = "steam://openurl/" .. tostring(url)
      if client and type(client.exec) == "function" then
        client.exec(command)
        return
      end
      if client and type(client.execute) == "function" then
        client.execute(command)
        return
      end
      if utils and type(utils.console_exec) == "function" then
        utils.console_exec(command)
        return
      end
      error("external URL command unavailable")
    end)
  end
  if not ok then
    log_once(
         "open_url",
         "Could not open the URL through the Steam overlay.")
  end
end
app.version_user_info = detail_field(info_tab, "User", get_username())
app.version_build_info = detail_field(info_tab, "Build", "Beta")
app.version_updated_info =
    detail_field(info_tab, "Updated", app.version_state.beta_updated)
local about_tab = ui.create(app.main_tab, "⁠", 1)
about_tab:label(
                label_with_icon(first_icon({ "user-pen", "pen", "user" }), "Created"))
local about_copy = about_tab:button(" PWNZ ", nil, true)
about_tab:label(
                label_with_icon(first_icon({ "link", "globe", "earth" }), "URL"))
local t1 = {
  { "Discord", "https://discord.gg/cey7mgz75P", { "discord" } },
  { "Telegram", "https://t.me/crackdildo", { "telegram", "paper-plane" } },
  { "YouTube", "https://www.youtube.com/@nos1st3m", { "youtube", "play" } },
}
app.version_social_buttons = {}
for _, social in ipairs(t1) do
  local glyph = first_icon(social[3])
  local caption = glyph ~= "" and glyph or social[1]
  local button = about_tab:button(menu_icon .. " " .. caption .. " " .. menu_note, function()
    open_url(social[2])
  end, true)
  app.version_social_buttons[#app.version_social_buttons + 1] =
      { button, caption }
  noop(button, social[1] .. ": " .. social[2])
end
local v1 = ui.create(app.main_tab, "‍", 1)
local native_api
do
  local ems = rawget(_G, "__EMBERLIGHT_MISS_STATE_V2")
  if type(ems) ~= "table" then
    ems = {}
  end
  if type(ems.miss_log) ~= "table" then
    ems.miss_log = {}
  end
  if type(ems.bucket_stats) ~= "table" then
    ems.bucket_stats = {}
  end
  if type(ems.miss_counts) ~= "table" then
    ems.miss_counts = {}
  end
  if type(ems.ack_stats) ~= "table" then
    ems.ack_stats = { hits = 0, misses = 0, correction = 0, unmatched = 0 }
  end
  if type(ems.mode_stats) ~= "table" then
    ems.mode_stats = {}
  end
  if type(ems.delta_stats) ~= "table" then
    ems.delta_stats = {}
  end
  if type(ems.population) ~= "table" then
    ems.population = {
      acks = 0,
      hits = 0,
      misses = 0,
      correlated = 0,
      matched = 0,
      learned = 0,
      wide_rejects = 0,
    }
  end
  _G.__EMBERLIGHT_MISS_STATE_V2 = ems
end
local yaw_state = {
  miss_owner = {},
  miss_state = _G.__EMBERLIGHT_MISS_STATE_V2,
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
  learn = {},
  shots = {},
  miss_log = _G.__EMBERLIGHT_MISS_STATE_V2.miss_log,
  bucket_stats = _G.__EMBERLIGHT_MISS_STATE_V2.bucket_stats,
  miss_counts = _G.__EMBERLIGHT_MISS_STATE_V2.miss_counts,
  ack_stats = _G.__EMBERLIGHT_MISS_STATE_V2.ack_stats,
  mode_stats = _G.__EMBERLIGHT_MISS_STATE_V2.mode_stats,
  delta_stats = _G.__EMBERLIGHT_MISS_STATE_V2.delta_stats,
  population = _G.__EMBERLIGHT_MISS_STATE_V2.population,
  last_decay = 0,
}
yaw_state.miss_state.owner = yaw_state.miss_owner
yaw_state.print_banner = function()
  local banner = {
    "███████╗███╗   ███╗██████╗ ███████╗██████╗ ██╗     ██╗ ██████╗ ██╗  ██╗████████╗",
    "██╔════╝████╗ ████║██╔══██╗██╔════╝██╔══██╗██║     ██║██╔════╝ ██║  ██║╚══██╔══╝",
    "█████╗  ██╔████╔██║██████╔╝█████╗  ██████╔╝██║     ██║██║  ███╗███████║   ██║   ",
    "██╔══╝  ██║╚██╔╝██║██╔══██╗██╔══╝  ██╔══██╗██║     ██║██║   ██║██╔══██║   ██║   ",
    "███████╗██║ ╚═╝ ██║██████╔╝███████╗██║  ██║███████╗██║╚██████╔╝██║  ██║   ██║   ",
    "╚══════╝╚═╝     ╚═╝╚═════╝ ╚══════╝╚═╝  ╚═╝╚══════╝╚═╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ",
  }
  for i = 1, #banner do
    raw_log(banner[i])
  end
end
local t2 = {
  { "Aimbot", "Ragebot", "Main", "Enabled", "Override Resolver" },
  { "Aimbot", "Ragebot", "Resolver", "Enabled" },
  { "Aimbot", "Ragebot", "Resolver", "Override Resolver" },
  { "Aimbot", "Ragebot", "Resolver" },
  { "Aimbot", "Ragebot", "Override Resolver" },
}
local function native_ref()
  local now = game_time()
  if yaw_state.native_ref and now - yaw_state.last_check < 30 then
    return yaw_state.native_ref
  end
  yaw_state.last_check = now
  for _, path in ipairs(t2) do
    local ok, ref = pcall(function()
      if #path == 1 then
        return ui.find(path[1])
      end
      if #path == 2 then
        return ui.find(path[1], path[2])
      end
      if #path == 3 then
        return ui.find(path[1], path[2], path[3])
      end
      if #path == 4 then
        return ui.find(path[1], path[2], path[3], path[4])
      end
      return ui.find(path[1], path[2], path[3], path[4], path[5])
    end)
    if ok and ref then
      yaw_state.native_ref = ref
      return ref
    end
  end
  yaw_state.native_ref = nil
  return nil
end
local function native_ready()
  local ref = native_ref()
  if not ref then
    return false
  end
  local ok, value = pcall(function()
    return ref:get()
  end)
  return ok and value == true
end
local function get_eye_yaw(ent)
  local ok, ang = pcall(function()
    return ent:get_eye_angles()
  end)
  if ok and ang and finite(ang.y) then
    return finite(ang.y), "eye"
  end
  local ok2, ang2 = pcall(function()
    return ent.m_angEyeAngles
  end)
  if ok2 and ang2 and finite(ang2.y) then
    return finite(ang2.y), "eye"
  end
  local ok3, ang3 = pcall(function()
    return ent:get_angles()
  end)
  if ok3 and ang3 and finite(ang3.y) then
    return finite(ang3.y), "shared"
  end
  return nil, nil
end
local function get_velocity(ent)
  local ok, vel = pcall(function()
    return ent.m_vecVelocity
  end)
  if ok and vel and finite(vel.x) and finite(vel.y) then
    local vx, vy = finite(vel.x), finite(vel.y)
    local speed = math.sqrt(vx * vx + vy * vy)
    if speed > 0.01 then
      return math.deg(math.atan2(vy, vx)), speed
    end
  end
  return nil, 0
end
local function get_lower_yaw(ent)
  local ok, value = pcall(function()
    return ent.m_flLowerBodyYawTarget
  end)
  if ok and finite(value) then
    return finite(value)
  end
  return nil
end
local function normalize_angle(a)
  while a > 180 do
    a = a - 360
  end
  while a < -180 do
    a = a + 360
  end
  return a
end
local function get_pose(ent)
  local ok, value = pcall(function()
    local v = entity.get_prop(ent, "m_flPoseParameter", 11)
    if finite(v) then
      return finite(v)
    end
    local arr = ent.m_flPoseParameter
    if type(arr) == "table" and finite(arr[11]) then
      return finite(arr[11])
    end
    if type(arr) == "table" and finite(arr[12]) then
      return finite(arr[12])
    end
    return nil
  end)
  if not ok or not finite(value) then
    return nil
  end
  if value >= 0 and value <= 1.2 then
    return clamp((value - 0.5) * 120, -60, 60)
  end
  if value >= -1.2 and value <= 1.2 then
    return clamp(value * 60, -60, 60)
  end
  return clamp(value, -60, 60)
end
local function get_duck(ent)
  local ok, value = pcall(function()
    return ent.m_flDuckAmount
  end)
  if ok and finite(value) then
    return clamp(finite(value), 0, 1)
  end
  local ok2, value2 = pcall(function()
    return entity.get_prop(ent, "m_flDuckAmount")
  end)
  if ok2 and finite(value2) then
    return clamp(finite(value2), 0, 1)
  end
  return 0
end
local function direction_from_hist(a1, first)
  if not a1 or #a1 == 0 then
    return nil
  end
  local sx, sy, count = 0, 0, 0
  for i = first or 1, #a1 do
    local r = math.rad(a1[i])
    sx, sy, count = sx + math.cos(r), sy + math.sin(r), count + 1
  end
  if count == 0 or (math.abs(sx) < 0.0001 and math.abs(sy) < 0.0001) then
    return a1[#a1]
  end
  return normalize_angle(math.deg(math.atan2(sy, sx)))
end
local function yaw_from_history(L, yaw_now, a1, state)
  if not yaw_now then
    return
  end
  yaw_now = normalize_angle(yaw_now)
  a1 = tonumber(a1) or 0
  if L.jhist_tick == a1 then
    if L.jhist and #L.jhist > 0 then
      L.jhist[#L.jhist] = yaw_now
    end
    return
  end
  L.jhist_tick = a1
  local h = L.jhist
  if not h then
    h = {}
    L.jhist = h
  end
  h[#h + 1] = yaw_now
  if #h > 12 then
    table.remove(h, 1)
  end
  if #h < 3 then
    L.jitter, L.alternating, L.spin_score = 0, false, 0
    return
  end
  local first = math.max(2, #h - 7)
  local big, total, flips, same, considered, prev_delta, signed =
      0,
      0,
      0,
      0,
      0,
      nil,
      0
  for i = first, #h do
    local d = normalize_angle(h[i] - h[i - 1])
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
  local intervals = #h - first + 1
  local avg = intervals > 0 and total / intervals or 0
  local flip_ratio = considered > 1 and flips / (considered - 1) or 0
  local same_ratio = considered > 1 and same / (considered - 1) or 0
  L.jcenter = direction_from_hist(h, math.max(1, #h - 7))
  local amplitude = 0
  for i = math.max(1, #h - 7), #h do
    amplitude =
        amplitude + math.abs(normalize_angle(h[i] - (L.jcenter or yaw_now)))
  end
  amplitude = amplitude / math.min(8, #h)
  L.jamp = clamp((L.jamp or amplitude) * 0.55 + amplitude * 0.45, 0, 60)
  L.jitter = clamp((big / math.max(1, intervals)) * 0.35 + (avg / 100) * 0.25 +
    flip_ratio * 0.3 + clamp(L.jamp / 55, 0, 1) * 0.1, 0, 1)
  L.phase_conf = flip_ratio
  L.alternating = flip_ratio > 0.6 and L.jamp > 14
  L.spin_score = same_ratio
  L.spin_step = considered > 0 and signed / considered or 0
  local delta = normalize_angle(yaw_now - (L.jcenter or yaw_now))
  if math.abs(delta) > 7 then
    L.jitter_side = delta >= 0 and 1 or -1
  end
end
local function yaw_from_jhist(L, a1)
  local h = L.jhist
  if not h or #h < 4 then
    return nil
  end
  local center = L.jcenter or direction_from_hist(h, math.max(1, #h - 7))
  if not center then
    return nil
  end
  local last = h[#h]
  local amplitude = clamp(L.jamp or 32, 18, 58)
  if L.alternating and (L.phase_conf or 0) > 0.55 then
    local side = normalize_angle(last - center) >= 0 and -1 or 1
    return normalize_angle(center + side * amplitude)
  end
  if (L.spin_score or 0) > 0.7 and math.abs(L.spin_step or 0) > 10 then
    return normalize_angle(last + clamp(L.spin_step, -58, 58))
  end
  local side = L.jitter_side or (a1 % 2 == 0 and 1 or -1)
  return normalize_angle(center + side * clamp(amplitude, 28, 50))
end
local function speed_from_flags(ent, speed, duck, pose_delta)
  local flags = nil
  pcall(function()
    flags = tonumber(ent.m_fFlags)
  end)
  if flags == nil then
    pcall(function()
      flags = tonumber(entity.get_prop(ent, "m_fFlags"))
    end)
  end
  local airborne =
      flags and bit and bit.band and bit.band(flags, 1) == 0 or false
  local speed_factor = clamp(speed / 260, 0, 1)
  local modifier = 1 - 0.5 * speed_factor
  if duck > 0 then
    modifier = modifier + duck * speed_factor * (0.5 - modifier)
  end
  local delta = 58 * modifier
  if pose_delta and math.abs(pose_delta) > 12 then
    delta = delta * 0.7 + math.abs(pose_delta) * 0.3
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
local function vote_lby_break(L, base, pose_delta, lby)
  local vote = 0
  if pose_delta and math.abs(pose_delta) > 5 then
    vote = vote + (pose_delta > 0 and 1 or -1) *
      clamp(math.abs(pose_delta) / 30, 0.55, 1.45)
  end
  if lby then
    local d = normalize_angle(lby - base)
    if math.abs(d) > 10 and math.abs(d) < 150 then
      vote = vote + (d > 0 and 1 or -1)
    end
  end
  if L.jitter_side then
    vote = vote + L.jitter_side * 0.45
  end
  L.side_score = clamp((L.side_score or 0) * 0.72 + vote, -4, 4)
  if math.abs(L.side_score) > 0.35 then
    L.side = L.side_score >= 0 and 1 or -1
  end
  return L.side or 1
end
yaw_state.PLAUSIBLE_AIM =
    { stand = 60, slow = 60, duck = 60, move = 75, air = 95 }
yaw_state.plausible_yaw = function(L, state, yaw)
  local anchor = tonumber(L and L.__base)
  if not anchor or not finite(yaw) then
    return true
  end
  local limit = yaw_state.PLAUSIBLE_AIM[state] or 60
  if math.abs(normalize_angle(yaw - anchor)) <= limit then
    return true
  end
  L.resolve_wide_rejects = (L.resolve_wide_rejects or 0) + 1
  return false
end
yaw_state.filter_wide = function(L, list, state)
  local kept, dropped = 0, 0
  for i = 1, list.n do
    local c = list[i]
    if yaw_state.plausible_yaw(L, state, c.yaw) then
      kept = kept + 1
      list[kept] = c
    else
      dropped = dropped + 1
    end
  end
  list.n = kept
  return dropped
end
yaw_state.gate_clamp = function(L, state, yaw)
  local anchor = tonumber(L and L.__base)
  local limit = yaw_state.PLAUSIBLE_AIM[state] or 60
  if not anchor or not finite(yaw) then
    return normalize_angle(yaw)
  end
  local off = normalize_angle(yaw - anchor)
  if math.abs(off) <= limit then
    return normalize_angle(yaw)
  end
  return normalize_angle(anchor + (off > 0 and 1 or -1) * limit)
end
yaw_state.vel_alignment = function(L, vel_angle)
  local anchor = tonumber(L and L.__base)
  if not anchor or not finite(vel_angle) then
    return 1
  end
  return 1 - clamp(math.abs(normalize_angle(vel_angle - anchor)) / 75, 0, 1)
end
local function make_bucket_list()
  local list = { n = 0, seen = {} }
  list.add = function(bucket, value, prior)
    if value == nil or list.seen[bucket] then
      return
    end
    list.seen[bucket] = true
    list.n = list.n + 1
    list[list.n] =
        { bucket = bucket, yaw = normalize_angle(value), prior = prior or 0 }
  end
  return list
end
local bucket_map = {
  vel = 0.08,
  eye = -0.05,
  eye_side = 0.14,
  eye_opp = 0.08,
  body = 0.18,
  lby = 0.1,
  lby_side = 0.11,
  st_opp = 0.2,
  hyb = 0.14,
  pred = -0.08,
  feedback = 0.04,
  exp_side = -0.06,
  exp_opp = -0.04,
  brute = -0.12,
  ["vel+180"] = -0.8,
  ["eye+180"] = -0.32,
}
local function bucket_value(bucket)
  local exact = bucket_map[bucket]
  if exact ~= nil then
    return exact
  end
  if bucket:sub(1, 5) == "brute" then
    return bucket_map.brute
  end
  local canonical = yaw_state.canonical_bucket and
    yaw_state.canonical_bucket(bucket, "unknown") or bucket
  if canonical ~= bucket then
    local mapped = bucket_map[canonical]
    if mapped ~= nil then
      return mapped
    end
  end
  return 0
end
yaw_state.canonical_buckets = {
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
}
yaw_state.canonical_bucket = function(bucket, state)
  if type(bucket) ~= "string" then
    return bucket
  end
  if bucket == "beta_opp" then
    return state == "air" and "vel_opp" or "eye_opp"
  end
  return yaw_state.canonical_buckets[bucket] or bucket
end
local function pick_best_bucket(L, list, explore, state)
  yaw_state.filter_wide(L, list, state)
  local best, best_score = nil, -1000000000
  local state_stats = L.by_state and L.by_state[state] or nil
  for i = 1, list.n do
    local c = list[i]
    local global = L[c.bucket]
    local rec = state_stats and state_stats[c.bucket] or nil
    local swh = rec and (rec.wh or rec.h or 0) or 0
    local swm = rec and (rec.wm or rec.m or 0) or 0
    local gwh = global and (global.wh or global.h or 0) or 0
    local gwm = global and (global.wm or global.m or 0) or 0
    local wh, wm = swh + gwh * 0.3, swm + gwm * 0.3
    local n = wh + wm
    local accuracy = (wh + 1.25) / (n + 2.5)
    local confidence = math.min(1, n / 7)
    local score =
        accuracy * 1.42 + confidence * 0.1 + bucket_value(c.bucket) + c.prior
    if c.bucket == "vel" or c.bucket == "vel_side" or c.bucket == "vel_opp" then
      if state == "slow" or state == "stand" or state == "duck" then
        score = score - 0.22
      elseif state == "move" then
        score = score + 0.07 * yaw_state.vel_alignment(L, c.yaw)
      elseif state == "air" then
        score = score + 0.28 * yaw_state.vel_alignment(L, c.yaw)
      end
    elseif (c.bucket == "body" or c.bucket == "lby" or c.bucket == "lby_side") and
      (state == "stand" or state == "slow") then
      score = score + 0.09
    end
    if state == "air" and (c.bucket == "body" or c.bucket == "lby" or c.bucket == "lby_side" or
      c.bucket == "micro_lby" or c.bucket == "last_move" or c.bucket == "eye" or c.bucket == "eye_side" or c.bucket == "eye_opp" or c.bucket == "eye+29" or c.bucket == "pred" or c.bucket == "hyb") then
      score = score - 0.6
    end
    if explore then
      score = score + math.sqrt(1.2 / (n + 1)) * 0.03
    end
    local streak =
        rec and (rec.streak or 0) or global and (global.streak or 0) or 0
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
local function current_yaw_mode()
  local ok, v = pcall(function()
    return app.yaw_mode and app.yaw_mode:get()
  end)
  if ok and type(v) == "string" then
    return app.version_state.allowed_mode(v)
  end
  return app.version_state.tier_modes()[1]
end
yaw_state.path_active = function()
  return item_enabled(app.resolver) and item_enabled(app.yaw)
end
yaw_state.mode_label = function()
  if not item_enabled(app.resolver) then
    return "Baseline"
  end
  if item_enabled(app.assist) then
    return "Assist"
  end
  if not item_enabled(app.yaw) then
    return "Baseline"
  end
  return current_yaw_mode()
end
local t3 = {
  ignore_no_impact = true,
  isolate_per_shot = true,
  static_aa_correction = true,
  shot_ttl = 3,
  shot_tick_ttl = 256,
  min_feedback_weight = 0.35,
  min_static_confidence = 0.5,
  max_learning_spread = 1.5,
  ban_ticks = 128,
}
local bands =
    { noise_spread = 0.3, bands = { 3, 8, 15, 25, 40 }, max_rows = 800 }
local function band_of(v)
  local a = tonumber(v)
  if not a then
    return "?"
  end
  a = math.abs(a)
  local prev = 0
  for _, edge in ipairs(bands.bands) do
    if a < edge then
      return string.format("%02d-%02d", prev, edge)
    end
    prev = edge
  end
  return string.format("%02d+", prev)
end
local function shot_side(shot)
  local s = shot and tonumber(shot.yaw_side) or nil
  if s == nil then
    local c = shot and tonumber(shot.yaw_corr) or nil
    s = c and (c >= 0 and 1 or -1) or 0
  end
  return s > 0 and "R" or (s < 0 and "L" or "?")
end
local function update_feedback(L, a1)
  a1 = tonumber(a1) or 0
  local last = tonumber(L.feedback_tick)
  if last and a1 > last then
    local elapsed = math.min(64, a1 - last)
    local factor = math.max(0.55, 1 - elapsed * 0.025)
    L.feedback_bias = (tonumber(L.feedback_bias) or 0) * factor
    if math.abs(L.feedback_bias) < 0.35 then
      L.feedback_bias = 0
    end
  end
  L.feedback_tick = a1
end
local function feedback_offset(L, base, a1, scale)
  update_feedback(L, a1)
  local bias = tonumber(L.feedback_bias) or 0
  if math.abs(bias) < 5 then
    return nil
  end
  return normalize_angle(base + bias * (scale or 1)), bias
end
yaw_state.angel_cycle_size = { Beta = 12 }
yaw_state.angel_feedback = function(L, mode, hit, a1, state)
  if not L or not yaw_state.angel_cycle_size[mode] then
    return
  end
  L.angel = L.angel or {}
  local row = L.angel[mode] or { phase = 0, misses = 0, state = state }
  L.angel[mode] = row
  if hit then
    row.phase, row.misses, row.last_tick = 0, 0, a1
    row.state = state
    return
  end
  if row.state ~= state or
    (row.last_tick and (a1 < row.last_tick or a1 - row.last_tick > 192)) then
    row.phase, row.misses = 0, 0
  end
  row.state = state
  row.misses = math.min(32, (row.misses or 0) + 1)
  local size = yaw_state.angel_cycle_size[mode]
  row.phase = size and (((row.phase or 0) % size) + 1) or 0
  row.last_tick = a1
end
yaw_state.angel_phase_candidate = function(L, mode, base, vel_angle, lby, side, state, delta, a1)
  local row = L and L.angel and L.angel[mode] or nil
  if not row or not finite(row.phase) or row.phase <= 0 then
    return nil
  end
  if row.last_tick and (a1 < row.last_tick or a1 - row.last_tick > 192) then
    row.phase, row.misses = 0, 0
    return nil
  end
  base = finite(base) or 0
  side = finite(side) and (side >= 0 and 1 or -1) or 1
  delta = clamp(finite(delta) or 0, 0, 60)
  local phase = math.floor(row.phase)
  local body = finite(L.body_hint) and L.body_hint or nil
  local yaw
  if phase <= 8 then
    local step = phase <= 2 and delta * 0.25 or phase <= 4 and delta * 0.5 or
      phase <= 6 and delta * 0.75 or delta
    yaw = base + (phase % 2 == 0 and -1 or 1) * step
  elseif phase == 9 then
    yaw = lby or (base + side * delta * 0.875)
  elseif phase == 10 then
    yaw = body or (base - side * delta * 0.375)
  elseif phase == 11 then
    yaw = base
  else
    local raw = finite(vel_angle)
    local bound = delta * 0.625
    yaw = raw and (base + clamp(normalize_angle(raw - base), -bound, bound)) or
      base
  end
  return normalize_angle(yaw), "aw_phase_" .. string.lower(mode)
end
yaw_state.reset_angel_all = function(self)
  for _, L in pairs(self.learn) do
    if type(L) == "table" then
      L.angel = nil
    end
  end
end
yaw_state.reset_angel_event = function(self, event, drop)
  local uid = event and tonumber(event.userid) or nil
  if not uid then
    return
  end
  local ent = nil
  pcall(function()
    ent = entity.get(uid, true)
  end)
  local idx = nil
  if ent then
    pcall(function()
      idx = ent:get_index()
    end)
  end
  if not finite(idx) then
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
yaw_state.evalate_signal = function(L, base, pose_delta, lby, max_delta, a1, state)
  a1 = tonumber(a1) or 0
  local pose = tonumber(pose_delta)
  local goal = finite(lby) and normalize_angle(lby) or
    (pose and normalize_angle(base + pose) or nil)
  if not goal then
    L.evalate_forced, L.evalate_yaw, L.evalate_confidence = nil, nil, 0
    return nil
  end
  local sample =
      { tick = a1, pose = pose, eye_yaw = base, goal_feet_yaw = goal }
  if L.evalate_tick ~= a1 then
    L.evalate_prev = L.evalate_last
    L.evalate_last = sample
    L.evalate_tick = a1
  else
    L.evalate_last = sample
  end
  local previous_pose =
      L.evalate_prev and tonumber(L.evalate_prev.pose) or nil
  local body_pose = previous_pose or pose
  local goal_delta = normalize_angle(goal - base)
  local direction = goal_delta > 0 and 1 or (goal_delta < 0 and -1 or 0)
  local brute = tonumber(L.evalate_brute) or 1
  brute = brute >= 0 and 1 or -1
  L.evalate_brute = brute
  local desync_ratio = clamp((tonumber(max_delta) or 0) / 58, 0, 1)
  if not body_pose or math.abs(body_pose) < 5 or desync_ratio < 0.55 then
    L.evalate_forced, L.evalate_yaw, L.evalate_confidence = nil, nil, 0
    return nil
  end
  local signed = direction ~= 0 and direction or brute
  local forced = clamp(math.abs(body_pose) * signed * brute, -60, 60)
  local static_bonus =
      (state == "stand" or state == "slow" or state == "duck") and 0.2 or 0
  local confidence = clamp(
      math.abs(body_pose) / 42 * 0.45 + desync_ratio * 0.35 + static_bonus,
      0,
      1)
  L.evalate_forced = forced
  L.evalate_yaw = normalize_angle(base + forced)
  L.evalate_confidence = confidence
  return L.evalate_yaw, confidence
end
local function record_stability(L, state, speed, base, lby, a1)
  if L.stability_tick == a1 then
    return
  end
  local gap = L.stability_tick and a1 - L.stability_tick or 1
  local same = L.stability_state == state and gap > 0 and gap <= 3
  L.state_stability =
      same and math.min(12, (L.state_stability or 0) + 1) or 1
  L.stability_state, L.stability_tick = state, a1
  local static = state == "stand" or state == "slow" or state == "duck"
  local body_delta = lby and math.abs(normalize_angle(lby - base)) or 0
  local evidence = math.max(
         clamp((L.body_strength or 0) / 38, 0, 1),
         clamp(body_delta / 44, 0, 1),
         clamp((L.jitter or 0) / 0.72, 0, 1))
  local stable = clamp((L.state_stability or 0) / 6, 0, 1)
  L.static_evidence = static and evidence or 0
  L.static_confidence =
      static and clamp(stable * 0.55 + evidence * 0.45, 0, 1) or 0
  L.break_lc = gap > 3
  L.__speed = speed
end
yaw_state.aim_at_me = function(ent)
  local me = nil
  pcall(function()
    me = entity.get_local_player()
  end)
  if not me or not ent then
    return nil
  end
  local my_origin = nil
  pcall(function()
    my_origin = me:get_origin()
  end)
  if not my_origin or not finite(my_origin.x) or not finite(my_origin.y) then
    return nil
  end
  local en_origin = nil
  pcall(function()
    en_origin = ent:get_origin()
  end)
  if not en_origin or not finite(en_origin.x) or not finite(en_origin.y) then
    return nil
  end
  local dx, dy = my_origin.x - en_origin.x, my_origin.y - en_origin.y
  if math.abs(dx) < 0.01 and math.abs(dy) < 0.01 then
    return nil
  end
  return normalize_angle(math.deg(math.atan2(dy, dx)))
end
yaw_state.distance_sqr = function(ent)
  local me = nil
  pcall(function()
    me = entity.get_local_player()
  end)
  if not me or not ent then
    return nil
  end
  local a, b = nil, nil
  pcall(function()
    a = me:get_origin()
    b = ent:get_origin()
  end)
  if not a or not b or not finite(a.x) or not finite(b.x) then
    return nil
  end
  local dx, dy, dz = a.x - b.x, a.y - b.y, (a.z or 0) - (b.z or 0)
  return dx * dx + dy * dy + dz * dz
end
yaw_state.context_signal = function(L, state, speed, pose_delta, lby, base, a1)
  if L.context_tick == a1 then
    return
  end
  local gap = L.context_tick and a1 - L.context_tick or 1
  L.context_tick = a1
  if finite(lby) then
    local prev = tonumber(L.lby_prev_yaw)
    if prev then
      local d = math.abs(normalize_angle(lby - prev))
      if d > 25 then
        L.lby_break_tick = a1
        L.lby_break_yaw = normalize_angle(lby)
        L.lby_breaks = (L.lby_breaks or 0) + 1
      end
    end
    L.lby_prev_yaw = lby
  end
  L.lby_age = L.lby_break_tick and (a1 - L.lby_break_tick) or 999
  local valid_gap = gap > 0 and gap <= 3
  local pose = tonumber(pose_delta)
  local pose_sign =
      pose and math.abs(pose) >= 7 and (pose >= 0 and 1 or -1) or 0
  if pose_sign ~= 0 and L.pose_sign and L.pose_sign ~= 0 and
    pose_sign ~= L.pose_sign then
    L.side_switch_tick = a1
    L.side_switches = math.min(16, (L.side_switches or 0) + 1)
  end
  if pose_sign ~= 0 then
    L.pose_sign = pose_sign
  end
  L.side_switch = L.side_switch_tick and a1 >= L.side_switch_tick and
    a1 - L.side_switch_tick <= 3 or false
  L.micro_move = state ~= "air" and speed >= 0.5 and speed < 18
  if state == "move" and speed > 40 then
    L.last_move_yaw = lby or (pose and normalize_angle(base + pose)) or base
    L.last_move_tick = a1
  end
  local signal = math.max(
         clamp(math.abs(pose or 0) / 42, 0, 1),
         lby and clamp(math.abs(normalize_angle(lby - base)) / 48, 0, 1) or 0,
         clamp((L.jitter or 0) / 0.75, 0, 1))
  local freshness =
      valid_gap and 1 or (gap > 0 and gap <= 8 and 0.45 or 0.15)
  L.record_quality = clamp(freshness * 0.55 + signal * 0.3 +
    clamp((L.state_stability or 0) / 6, 0, 1) * 0.15, 0, 1)
end
yaw_state.lby_cadence = function(L, state, speed, lby, a1, base)
  if not L then
    return
  end
  local moving = speed and speed > 3
  if moving then
    L.cad_move_yaw = lby or base
    L.cad_move_tick = a1
    L.cad_phase = "moving"
    L.cad_stop_tick = nil
    L.cad_stop_yaw = nil
    L.cad_anchor = nil
    return
  end
  local move_tick = tonumber(L.cad_move_tick)
  local stop_tick = tonumber(L.cad_stop_tick)
  if move_tick and not stop_tick and a1 - move_tick <= 4 then
    L.cad_stop_tick = a1
    L.cad_stop_yaw = L.cad_move_yaw or lby or base
    stop_tick = a1
  end
  if not stop_tick then
    L.cad_phase = "expired"
    L.cad_anchor = nil
    return
  end
  local age = a1 - stop_tick
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
yaw_state.miss_penalty = function(L, state, yaw, a1)
  if not L or not finite(yaw) then
    return 0
  end
  local arcs = L.miss_arcs and L.miss_arcs[state]
  if type(arcs) ~= "table" then
    return 0
  end
  local penalty = 0
  for i = #arcs, 1, -1 do
    local a = arcs[i]
    local age = a1 - (tonumber(a.tick) or a1)
    if age < 0 or age > 192 then
      table.remove(arcs, i)
    else
      local distance =
          math.abs(normalize_angle(yaw - (tonumber(a.yaw) or yaw)))
      if distance < 44 then
        local freshness = 1 - age / 192
        penalty = penalty +
          (tonumber(a.weight) or 1) * (1 - distance / 44) * freshness
      end
    end
  end
  return clamp(penalty, 0, 2.5)
end
yaw_state.remember_miss = function(L, state, yaw, a1, weight, bucket)
  if not L or not finite(yaw) then
    return
  end
  L.miss_arcs = L.miss_arcs or {}
  local arcs = L.miss_arcs[state] or {}
  L.miss_arcs[state] = arcs
  local merged = false
  for i = #arcs, 1, -1 do
    local a = arcs[i]
    if a1 - (tonumber(a.tick) or a1) > 192 then
      table.remove(arcs, i)
    elseif math.abs(normalize_angle(yaw - (tonumber(a.yaw) or yaw))) <= 12 then
      a.yaw = normalize_angle(a.yaw + normalize_angle(yaw - a.yaw) * 0.35)
      a.tick = a1
      a.weight =
          clamp((tonumber(a.weight) or 0) * 0.72 + (weight or 1), 0.2, 2.25)
      a.bucket = bucket
      merged = true
      break
    end
  end
  if not merged then
    arcs[#arcs + 1] = {
      yaw = normalize_angle(yaw),
      tick = a1,
      weight = clamp(weight or 1, 0.2, 1),
      bucket = bucket,
    }
  end
  while #arcs > 6 do
    table.remove(arcs, 1)
  end
end
yaw_state.remember_hit = function(L, state, yaw, a1, bucket)
  if not L or not finite(yaw) then
    return
  end
  L.good_yaw = L.good_yaw or {}
  L.good_yaw[state] =
      { yaw = normalize_angle(yaw), tick = a1, bucket = bucket }
  local arcs = L.miss_arcs and L.miss_arcs[state]
  if type(arcs) ~= "table" then
    return
  end
  for i = #arcs, 1, -1 do
    local a = arcs[i]
    local distance =
        math.abs(normalize_angle(yaw - (tonumber(a.yaw) or yaw)))
    if distance <= 18 then
      a.weight = (tonumber(a.weight) or 1) * 0.28
      if a.weight < 0.18 then
        table.remove(arcs, i)
      end
    end
  end
end
yaw_state.feedback_score = function(L, state, bucket, yaw, a1)
  local state_stats = L.by_state and L.by_state[state] or nil
  local rec = state_stats and state_stats[bucket] or nil
  local global = L[bucket]
  local h = (rec and (rec.wh or rec.h) or 0) +
    (global and (global.wh or global.h) or 0) * 0.2
  local m = (rec and (rec.wm or rec.m) or 0) +
    (global and (global.wm or global.m) or 0) * 0.2
  local canonical = yaw_state.canonical_bucket(bucket, state)
  if canonical and canonical ~= bucket then
    local canonical_rec = state_stats and state_stats[canonical] or nil
    local canonical_global = L[canonical]
    h = h + ((canonical_rec and (canonical_rec.wh or canonical_rec.h) or 0) + (canonical_global and (canonical_global.wh or canonical_global.h) or 0) *
      0.2) * 0.42
    m = m + ((canonical_rec and (canonical_rec.wm or canonical_rec.m) or 0) + (canonical_global and (canonical_global.wm or canonical_global.m) or 0) *
      0.2) * 0.42
  end
  local reliability = (h + 1.1) / (h + m + 2.2) - 0.5
  local score =
      reliability * 0.7 - yaw_state.miss_penalty(L, state, yaw, a1) * 1.35
  local good = L.good_yaw and L.good_yaw[state] or nil
  if good and a1 >= (good.tick or a1) and a1 - (good.tick or a1) <= 128 then
    local distance = math.abs(normalize_angle(yaw - good.yaw))
    if distance <= 24 then
      score = score + (1 - distance / 24) * 0.38
    end
  end
  return score
end
yaw_state.lby_span_track = function(L, base, lby)
  if not L or not finite(base) or not finite(lby) then
    return nil
  end
  local off = normalize_angle(lby - base)
  local m = L.lby_span or { span = 0, mean = 0, n = 0 }
  m.n = m.n + 1
  m.mean = m.mean + (off - m.mean) / math.min(m.n, 32)
  m.span = math.max(math.abs(off), m.span * 0.995)
  L.lby_span = m
  local p = tonumber(L.lby_prev) or lby
  local pm = tonumber(L.lby_mean) or lby
  local delta_s = normalize_angle(lby - p)
  L.lby_mean = normalize_angle(pm + delta_s / math.min(m.n, 24))
  L.lby_prev = lby
  return m
end
yaw_state.add_main_candidates = function(list, L, base, vel_angle, speed, lby, a1, jitter, side, state, delta)
  local airborne = state == "air"
  local quality = tonumber(L.record_quality) or 0
  if airborne and vel_angle then
    base = vel_angle
  end
  if not airborne then
    list.add("commit", base + side * delta, state == "move" and 0.1 or 0.16)
    list.add("eye", base, state == "stand" and 0.06 or -0.04)
    list.add("eye_side", base + side * delta, 0.05)
    list.add(
         "eye_opp",
         base - side * delta,
         L.side_switch and 0.12 or -0.02)
  end
  if L.body_hint and not airborne then
    list.add(
         "body",
         L.body_hint,
         (L.body_strength or 0) > 24 and 0.12 or 0.02)
  end
  if vel_angle and speed > 34 and (airborne or state == "move") then
    list.add(
         "vel",
         vel_angle,
         airborne and 0.24 or (quality >= 0.28 and 0.13 or 0.03))
    if airborne then
      list.add("vel_side", vel_angle + side * math.min(delta, 32), 0.06)
      list.add("vel_opp", vel_angle - side * math.min(delta, 32), 0.09)
    end
  end
  if lby and not airborne then
    list.add(
         "lby",
         lby,
         (state == "stand" or state == "slow") and 0.08 or 0)
    if L.micro_move then
      list.add("micro_lby", lby + side * math.min(delta * 0.35, 20), 0.11)
    end
  end
  if L.last_move_yaw and L.last_move_tick and a1 - L.last_move_tick <= 64 and
    (state == "stand" or state == "slow") then
    list.add("last_move", L.last_move_yaw, 0.11)
  end
  local cad_phase = L.cad_phase
  if (state == "stand" or state == "slow") and cad_phase == "stop" and
    L.cad_anchor then
    list.add("cad_stop", L.cad_anchor, 0.3)
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
  if L.distance_sqr and L.distance_sqr < 1000000 and
    (state == "stand" or state == "slow") then
    list.add("near_eye", base, 0.14)
  end
  if jitter > 0.72 and L.side_switch and not airborne then
    list.add("hvh_jit_eye", base, 0.1)
  end
  if L.side_switch and not airborne then
    list.add("side_switch", base - side * delta, 0.12)
  end
  local pred =
      not L.break_lc and not airborne and yaw_from_jhist(L, a1) or nil
  if pred and jitter > 0.52 and quality >= 0.48 then
    list.add("pred", pred, -0.02)
  end
  local good = L.good_yaw and L.good_yaw[state] or nil
  if good and a1 >= good.tick and a1 - good.tick <= 128 then
    list.add("good_anchor", good.yaw, 0.24)
  end
  return base, airborne
end
yaw_state.resolve_free = function(L, base, vel_angle, speed, lby, a1, jitter, side, state, delta, last_angles, same_target, t, brute)
  local list = make_bucket_list()
  local quality = tonumber(L.record_quality) or 0
  local airborne = state == "air"
  if airborne and vel_angle then
    base = vel_angle
  end
  local eff_side = ((tonumber(brute) or 0) % 2 == 1) and -side or side
  local side_conf = clamp(math.abs(tonumber(L.side_score) or 0) / 2, 0, 1)
  local eff_delta = delta
  local span = L.lby_span and tonumber(L.lby_span.span) or nil
  if span and span > 14 and span < delta then
    eff_delta = span
  end
  local commit_prior = 0.3 + side_conf * 0.4
  if state == "move" then
    commit_prior = 0.1 + side_conf * 0.2
  end
  if not airborne then
    list.add(
         "commit",
         normalize_angle(base + eff_side * eff_delta),
         commit_prior)
  end
  if L.body_hint and not airborne then
    list.add(
         "body",
         L.body_hint,
         (L.body_strength > 24 and 0.22 or 0.05) * (0.55 + quality * 0.45))
  end
  local moving = vel_angle and speed > 34 and (state == "move" or airborne)
  if moving and (airborne or quality >= 0.28) then
    list.add(
         "vel",
         vel_angle,
         airborne and 0.3 or (state == "move" and 0.1 or -0.05))
  end
  local pred =
      not L.break_lc and not airborne and yaw_from_jhist(L, a1) or nil
  if pred and moving and quality >= 0.48 and (L.alternating or jitter > 0.48) then
    local movement_weight = clamp(speed / 260, 0.18, 0.55)
    list.add(
         "hyb",
         pred + normalize_angle(vel_angle - pred) * movement_weight,
         0.06)
  end
  if not airborne then
    list.add("eye", base, state == "stand" and 0.1 or 0)
    list.add("eye_side", base + eff_side * eff_delta, 0.1)
    list.add("eye_opp", base - eff_side * eff_delta, -0.02)
    list.add("eye+29", base + eff_side * 29, -0.04)
  elseif vel_angle then
    list.add("vel_side", vel_angle + side * math.min(eff_delta, 32), 0.12)
    list.add("vel_opp", vel_angle - side * math.min(eff_delta, 32), 0.06)
  end
  if lby and not airborne then
    list.add("lby", lby, state == "stand" and 0.08 or 0)
    list.add("lby_side", lby + eff_side * math.min(eff_delta, 50), -0.02)
    if L.micro_move then
      list.add(
          "micro_lby",
          lby + side * math.min(eff_delta * 0.35, 20),
          0.18)
    end
  end
  if state == "stand" or state == "slow" then
    if L.cad_phase == "stop" and L.cad_anchor then
      list.add("cad_stop", L.cad_anchor, 0.3)
    elseif L.cad_phase == "lby" and lby then
      list.add("cad_lby", lby, 0.18)
    end
  end
  if state == "slow" and speed > 0.5 and lby then
    list.add("cad_slow", lby + side * math.min(28, eff_delta * 0.55), 0.08)
  end
  if L.last_move_yaw and L.last_move_tick and a1 - L.last_move_tick <= 64 and
    (state == "stand" or state == "slow") then
    list.add("last_move", L.last_move_yaw, 0.15)
  end
  if L.side_switch and not airborne then
    list.add("side_switch", base - eff_side * eff_delta, 0.16)
  end
  if pred and jitter > 0.58 and quality >= 0.48 then
    list.add("pred", pred, jitter > 0.78 and 0.04 or -0.08)
  end
  local good = L.good_yaw and L.good_yaw[state] or nil
  if good and a1 >= good.tick and a1 - good.tick <= 128 then
    list.add("good_anchor", good.yaw, 0.24)
  end
  if not airborne and L.lby_break_yaw and L.lby_break_tick and
    a1 - L.lby_break_tick <= 16 and (state == "stand" or state == "slow" or state == "duck") then
    list.add("lby_break", L.lby_break_yaw, 0.3)
  end
  if L.defensive and not airborne and not L.side_switch and not L.micro_move then
    list.add("def_eye", base, 0.16)
    list.add(
         "def_half",
         normalize_angle(base + eff_side * eff_delta * 0.5),
         0.12)
  end
  if not L.defensive and L.aim_delta and L.aim_delta >= 60 and not airborne and
    not L.side_switch and not L.micro_move then
    list.add("side_eye", base, 0.07)
    list.add(
         "side_half",
         normalize_angle(base + eff_side * eff_delta * 0.5),
         0.04)
  end
  if L.distance_sqr and L.distance_sqr < 1000000 and
    (state == "stand" or state == "slow") then
    list.add("near_eye", base, 0.14)
  end
  for i = 1, list.n do
    local c = list[i]
    c.prior =
        (c.prior or 0) + yaw_state.feedback_score(L, state, c.bucket, c.yaw, a1)
  end
  local yaw, mode = pick_best_bucket(L, list, jitter > 0.66, state)
  if not finite(yaw) then
    local vel_ok = airborne and finite(vel_angle) and
      yaw_state.plausible_yaw(L, state, vel_angle)
    local fb = vel_ok and vel_angle or
      ((not airborne and finite(lby)) and lby or (base + eff_side * eff_delta))
    yaw = yaw_state.gate_clamp(L, state, fb)
    mode = vel_ok and "vel_fallback" or "commit_fallback"
  end
  local state_hit =
      L.last_hit_by_state and L.last_hit_by_state[state] or nil
  if state_hit and t - state_hit < 1.1 and last_angles and same_target and
    yaw_state.miss_penalty(L, state, last_angles, a1) < 0.2 then
    yaw =
        normalize_angle(last_angles + normalize_angle(yaw - last_angles) * 0.28)
  end
  return yaw, mode
end
yaw_state.resolve_beta = function(...)
  local t1 = {
    { 2703, 1 },
    { 8565, 0 },
    { 4573, 11 },
    { 2703, 2 },
    { 1752, 1 },
    { 4857, 3 },
    { 7624 },
    { 8565, 1 },
    { 4862 },
    { 4908, 13 },
    { 1490 },
    { 4857, 4 },
    { 4573, 12 },
    { 1752, 9 },
    { 4857, 5 },
    { 8967 },
    { 4573, 13 },
    { 1752, 13 },
    { 4862 },
    { 6995, 23 },
    { 1490 },
    { 1752, 3 },
    { 6995, 26 },
    { 1752, 3 },
    { 4573, 2 },
    { 1752, 10 },
    { 4573, 14 },
    { 1752, 1 },
    { 4857, 6 },
    { 7624 },
    { 4862 },
    { 6995, 41 },
    { 1490 },
    { 2703, 2 },
    { 1752, 1 },
    { 4857, 6 },
    { 7624 },
    { 4857, 7 },
    { 7624 },
    { 8565, 1 },
    { 4862 },
    { 4908, 45 },
    { 1490 },
    { 8480 },
    { 4573, 15 },
    { 1752, 15 },
    { 4862 },
    { 6995, 53 },
    { 1490 },
    { 1752, 15 },
    { 4857, 8 },
    { 2722 },
    { 4862 },
    { 6995, 59 },
    { 1490 },
    { 1752, 15 },
    { 1752, 10 },
    { 8664 },
    { 6995, 62 },
    { 1752, 15 },
    { 4573, 14 },
    { 2703, 9 },
    { 4857, 10 },
    { 7624 },
    { 1752, 11 },
    { 1752, 1 },
    { 1752, 2 },
    { 1752, 3 },
    { 1752, 4 },
    { 1752, 5 },
    { 1752, 6 },
    { 1752, 7 },
    { 1752, 8 },
    { 1752, 9 },
    { 1752, 14 },
    { 8565, 11 },
    { 1490 },
    { 1752, 1 },
    { 4857, 11 },
    { 7624 },
    { 4862 },
    { 6995, 86 },
    { 1490 },
    { 1752, 13 },
    { 8840 },
    { 6995, 101 },
    { 1752, 11 },
    { 4857, 12 },
    { 7624 },
    { 4857, 13 },
    { 1752, 1 },
    { 4857, 11 },
    { 7624 },
    { 4857, 14 },
    { 1752, 12 },
    { 4857, 15 },
    { 3434 },
    { 1451 },
    { 8565, 3 },
    { 1490 },
    { 1752, 5 },
    { 4862 },
    { 6995, 107 },
    { 1490 },
    { 1752, 13 },
    { 8840 },
    { 6995, 177 },
    { 2703, 16 },
    { 4857, 17 },
    { 7624 },
    { 2703, 18 },
    { 1752, 5 },
    { 1752, 2 },
    { 2729 },
    { 8565, 1 },
    { 8565, 1 },
    { 4857, 19 },
    { 1341 },
    { 4573, 16 },
    { 1752, 11 },
    { 4857, 12 },
    { 7624 },
    { 4857, 20 },
    { 1752, 5 },
    { 1752, 9 },
    { 4857, 21 },
    { 8967 },
    { 4862 },
    { 4908, 134 },
    { 1490 },
    { 1752, 9 },
    { 4857, 22 },
    { 8967 },
    { 4862 },
    { 4908, 140 },
    { 1490 },
    { 1752, 9 },
    { 4857, 23 },
    { 8967 },
    { 4862 },
    { 6995, 152 },
    { 1490 },
    { 1752, 16 },
    { 4862 },
    { 6995, 148 },
    { 1490 },
    { 4857, 24 },
    { 4862 },
    { 4908, 152 },
    { 1490 },
    { 4857, 25 },
    { 4862 },
    { 4908, 156 },
    { 1490 },
    { 4857, 26 },
    { 8565, 3 },
    { 1490 },
    { 1752, 11 },
    { 4857, 12 },
    { 7624 },
    { 4857, 27 },
    { 1752, 5 },
    { 1752, 8 },
    { 2703, 16 },
    { 4857, 28 },
    { 7624 },
    { 1752, 14 },
    { 4857, 29 },
    { 3434 },
    { 4857, 30 },
    { 8565, 2 },
    { 3434 },
    { 1451 },
    { 4857, 31 },
    { 8565, 3 },
    { 1490 },
    { 1752, 11 },
    { 4857, 12 },
    { 7624 },
    { 4857, 32 },
    { 1752, 2 },
    { 1752, 8 },
    { 1752, 14 },
    { 3434 },
    { 1451 },
    { 1752, 13 },
    { 4862 },
    { 6995, 191 },
    { 1490 },
    { 4857, 33 },
    { 4862 },
    { 4908, 195 },
    { 1490 },
    { 4857, 34 },
    { 8565, 3 },
    { 1490 },
    { 1752, 11 },
    { 4857, 12 },
    { 7624 },
    { 4857, 35 },
    { 1752, 2 },
    { 1752, 8 },
    { 1752, 14 },
    { 3434 },
    { 2729 },
    { 1752, 1 },
    { 4857, 36 },
    { 7624 },
    { 4862 },
    { 6995, 213 },
    { 1490 },
    { 4857, 14 },
    { 4862 },
    { 4908, 226 },
    { 1490 },
    { 1752, 13 },
    { 4862 },
    { 6995, 221 },
    { 1490 },
    { 4857, 37 },
    { 4862 },
    { 4908, 226 },
    { 1490 },
    { 4857, 26 },
    { 4370 },
    { 8565, 3 },
    { 1490 },
    { 1752, 13 },
    { 8840 },
    { 6995, 250 },
    { 1752, 11 },
    { 4857, 12 },
    { 7624 },
    { 4857, 38 },
    { 1752, 2 },
    { 1752, 9 },
    { 4857, 21 },
    { 8967 },
    { 4862 },
    { 6995, 243 },
    { 1490 },
    { 4857, 39 },
    { 4862 },
    { 4908, 248 },
    { 1490 },
    { 4857, 31 },
    { 4370 },
    { 8565, 3 },
    { 1490 },
    { 1752, 1 },
    { 4857, 40 },
    { 7624 },
    { 4862 },
    { 6995, 257 },
    { 1490 },
    { 1752, 5 },
    { 4862 },
    { 6995, 262 },
    { 1490 },
    { 1752, 13 },
    { 8840 },
    { 6995, 282 },
    { 1752, 11 },
    { 4857, 12 },
    { 7624 },
    { 4857, 41 },
    { 1752, 5 },
    { 1752, 8 },
    { 2703, 16 },
    { 4857, 28 },
    { 7624 },
    { 1752, 14 },
    { 4857, 42 },
    { 3434 },
    { 4857, 43 },
    { 8565, 2 },
    { 3434 },
    { 1451 },
    { 4857, 44 },
    { 8565, 3 },
    { 1490 },
    { 1752, 1 },
    { 4857, 45 },
    { 7624 },
    { 4862 },
    { 6995, 291 },
    { 1490 },
    { 1752, 1 },
    { 4857, 46 },
    { 7624 },
    { 4862 },
    { 6995, 301 },
    { 1490 },
    { 1752, 6 },
    { 1752, 1 },
    { 4857, 46 },
    { 7624 },
    { 2729 },
    { 4857, 47 },
    { 1341 },
    { 4862 },
    { 6995, 313 },
    { 1490 },
    { 1752, 9 },
    { 4857, 21 },
    { 8967 },
    { 4862 },
    { 4908, 313 },
    { 1490 },
    { 1752, 9 },
    { 4857, 22 },
    { 8967 },
    { 6995, 324 },
    { 1752, 11 },
    { 4857, 12 },
    { 7624 },
    { 4857, 48 },
    { 1752, 1 },
    { 4857, 45 },
    { 7624 },
    { 4857, 14 },
    { 8565, 3 },
    { 1490 },
    { 1752, 1 },
    { 4857, 49 },
    { 7624 },
    { 8840 },
    { 4862 },
    { 6995, 333 },
    { 1490 },
    { 1752, 13 },
    { 8840 },
    { 4862 },
    { 6995, 340 },
    { 1490 },
    { 2703, 50 },
    { 1752, 1 },
    { 1752, 6 },
    { 8565, 2 },
    { 4862 },
    { 4908, 344 },
    { 1490 },
    { 8480 },
    { 4573, 17 },
    { 1752, 17 },
    { 4862 },
    { 6995, 352 },
    { 1490 },
    { 1752, 12 },
    { 4857, 51 },
    { 2825 },
    { 4862 },
    { 6995, 358 },
    { 1490 },
    { 1752, 7 },
    { 4857, 52 },
    { 2722 },
    { 6995, 367 },
    { 1752, 11 },
    { 4857, 12 },
    { 7624 },
    { 4857, 53 },
    { 1752, 17 },
    { 4857, 39 },
    { 8565, 3 },
    { 1490 },
    { 1752, 3 },
    { 4862 },
    { 6995, 378 },
    { 1490 },
    { 1752, 13 },
    { 4862 },
    { 4908, 378 },
    { 1490 },
    { 1752, 12 },
    { 4857, 54 },
    { 2825 },
    { 4862 },
    { 6995, 384 },
    { 1490 },
    { 1752, 4 },
    { 4857, 55 },
    { 2722 },
    { 6995, 419 },
    { 1752, 11 },
    { 4857, 12 },
    { 7624 },
    { 4857, 56 },
    { 1752, 3 },
    { 1752, 13 },
    { 4862 },
    { 6995, 395 },
    { 1490 },
    { 4857, 42 },
    { 4862 },
    { 4908, 410 },
    { 1490 },
    { 1752, 9 },
    { 4857, 57 },
    { 8967 },
    { 4862 },
    { 6995, 405 },
    { 1490 },
    { 4857, 39 },
    { 4862 },
    { 4908, 410 },
    { 1490 },
    { 4857, 24 },
    { 4370 },
    { 2703, 9 },
    { 4857, 58 },
    { 7624 },
    { 1752, 1 },
    { 1752, 3 },
    { 8565, 2 },
    { 3434 },
    { 8565, 3 },
    { 1490 },
    { 1752, 1 },
    { 4857, 59 },
    { 7624 },
    { 4862 },
    { 6995, 430 },
    { 1490 },
    { 1752, 1 },
    { 4857, 59 },
    { 7624 },
    { 1752, 9 },
    { 7624 },
    { 4862 },
    { 4908, 434 },
    { 1490 },
    { 8480 },
    { 4573, 18 },
    { 1752, 18 },
    { 4862 },
    { 6995, 444 },
    { 1490 },
    { 1752, 6 },
    { 1752, 18 },
    { 4857, 60 },
    { 7624 },
    { 2825 },
    { 4862 },
    { 6995, 454 },
    { 1490 },
    { 1752, 6 },
    { 1752, 18 },
    { 4857, 60 },
    { 7624 },
    { 2729 },
    { 4857, 61 },
    { 1341 },
    { 6995, 465 },
    { 1752, 11 },
    { 4857, 12 },
    { 7624 },
    { 4857, 62 },
    { 1752, 18 },
    { 4857, 63 },
    { 7624 },
    { 4857, 64 },
    { 8565, 3 },
    { 1490 },
    { 1752, 13 },
    { 8840 },
    { 4862 },
    { 6995, 473 },
    { 1490 },
    { 1752, 1 },
    { 4857, 65 },
    { 7624 },
    { 4862 },
    { 6995, 479 },
    { 1490 },
    { 1752, 1 },
    { 4857, 66 },
    { 7624 },
    { 4862 },
    { 6995, 489 },
    { 1490 },
    { 1752, 6 },
    { 1752, 1 },
    { 4857, 66 },
    { 7624 },
    { 2729 },
    { 4857, 67 },
    { 1341 },
    { 4862 },
    { 6995, 507 },
    { 1490 },
    { 1752, 9 },
    { 4857, 21 },
    { 8967 },
    { 4862 },
    { 4908, 501 },
    { 1490 },
    { 1752, 9 },
    { 4857, 22 },
    { 8967 },
    { 4862 },
    { 4908, 507 },
    { 1490 },
    { 1752, 9 },
    { 4857, 23 },
    { 8967 },
    { 6995, 518 },
    { 1752, 11 },
    { 4857, 12 },
    { 7624 },
    { 4857, 68 },
    { 1752, 1 },
    { 4857, 65 },
    { 7624 },
    { 4857, 69 },
    { 8565, 3 },
    { 1490 },
    { 1752, 1 },
    { 4857, 70 },
    { 7624 },
    { 4862 },
    { 6995, 526 },
    { 1490 },
    { 1752, 13 },
    { 8840 },
    { 4862 },
    { 6995, 533 },
    { 1490 },
    { 1752, 1 },
    { 4857, 36 },
    { 7624 },
    { 8840 },
    { 4862 },
    { 6995, 540 },
    { 1490 },
    { 1752, 1 },
    { 4857, 40 },
    { 7624 },
    { 8840 },
    { 6995, 565 },
    { 1752, 11 },
    { 4857, 12 },
    { 7624 },
    { 4857, 71 },
    { 1752, 2 },
    { 4857, 34 },
    { 8565, 3 },
    { 1490 },
    { 1752, 11 },
    { 4857, 12 },
    { 7624 },
    { 4857, 72 },
    { 2703, 18 },
    { 1752, 2 },
    { 1752, 8 },
    { 1752, 14 },
    { 3434 },
    { 4857, 73 },
    { 3434 },
    { 1451 },
    { 8565, 1 },
    { 4857, 26 },
    { 8565, 3 },
    { 1490 },
    { 2703, 9 },
    { 4857, 74 },
    { 7624 },
    { 1752, 1 },
    { 4857, 75 },
    { 1752, 2 },
    { 1752, 3 },
    { 1752, 5 },
    { 1752, 8 },
    { 1752, 9 },
    { 1752, 14 },
    { 1752, 6 },
    { 1384, 9, 2 },
    { 4573, 20 },
    { 4573, 19 },
    { 1752, 19 },
    { 6995, 590 },
    { 1752, 11 },
    { 4857, 12 },
    { 7624 },
    { 1752, 20 },
    { 1752, 19 },
    { 4857, 76 },
    { 8565, 3 },
    { 1490 },
    { 2703, 9 },
    { 4857, 77 },
    { 7624 },
    { 1752, 1 },
    { 1752, 11 },
    { 1752, 9 },
    { 8565, 3 },
    { 1490 },
    { 1752, 1 },
    { 4857, 78 },
    { 7624 },
    { 4862 },
    { 6995, 609 },
    { 1490 },
    { 1752, 1 },
    { 4857, 78 },
    { 7624 },
    { 1752, 9 },
    { 7624 },
    { 4862 },
    { 4908, 613 },
    { 1490 },
    { 8480 },
    { 4573, 21 },
    { 6179 },
    { 4573, 22 },
    { 4857, 79 },
    { 4573, 23 },
    { 1752, 11 },
    { 4857, 80 },
    { 7624 },
    { 4573, 24 },
    { 4857, 79 },
    { 4573, 25 },
    { 1752, 23 },
    { 4573, 26 },
    { 1752, 25 },
    { 4857, 4 },
    { 2825 },
    { 6995, 635 },
    { 1752, 26 },
    { 1752, 24 },
    { 1341 },
    { 4908, 639 },
    { 3360, 949 },
    { 1752, 26 },
    { 1752, 24 },
    { 2825 },
    { 6995, 949 },
    { 1752, 11 },
    { 1752, 26 },
    { 7624 },
    { 4573, 27 },
    { 1752, 1 },
    { 1752, 27 },
    { 4857, 81 },
    { 7624 },
    { 7624 },
    { 4573, 28 },
    { 1752, 21 },
    { 4862 },
    { 6995, 658 },
    { 1490 },
    { 1752, 21 },
    { 1752, 27 },
    { 4857, 81 },
    { 7624 },
    { 7624 },
    { 4862 },
    { 4908, 662 },
    { 1490 },
    { 8480 },
    { 4573, 29 },
    { 1752, 29 },
    { 4862 },
    { 6995, 676 },
    { 1490 },
    { 1752, 29 },
    { 4857, 82 },
    { 7624 },
    { 4862 },
    { 4908, 676 },
    { 1490 },
    { 1752, 29 },
    { 4857, 83 },
    { 7624 },
    { 4862 },
    { 4908, 680 },
    { 1490 },
    { 4857, 4 },
    { 1752, 28 },
    { 4862 },
    { 6995, 693 },
    { 1490 },
    { 1752, 28 },
    { 4857, 82 },
    { 7624 },
    { 4862 },
    { 4908, 693 },
    { 1490 },
    { 1752, 28 },
    { 4857, 83 },
    { 7624 },
    { 4862 },
    { 4908, 697 },
    { 1490 },
    { 4857, 4 },
    { 4857, 84 },
    { 3434 },
    { 1451 },
    { 4573, 30 },
    { 1752, 29 },
    { 4862 },
    { 6995, 714 },
    { 1490 },
    { 1752, 29 },
    { 4857, 85 },
    { 7624 },
    { 4862 },
    { 4908, 714 },
    { 1490 },
    { 1752, 29 },
    { 4857, 86 },
    { 7624 },
    { 4862 },
    { 4908, 718 },
    { 1490 },
    { 4857, 4 },
    { 1752, 28 },
    { 4862 },
    { 6995, 731 },
    { 1490 },
    { 1752, 28 },
    { 4857, 85 },
    { 7624 },
    { 4862 },
    { 4908, 731 },
    { 1490 },
    { 1752, 28 },
    { 4857, 86 },
    { 7624 },
    { 4862 },
    { 4908, 735 },
    { 1490 },
    { 4857, 4 },
    { 4857, 84 },
    { 3434 },
    { 1451 },
    { 4573, 31 },
    { 1752, 30 },
    { 1752, 31 },
    { 1451 },
    { 4573, 32 },
    { 1752, 30 },
    { 4857, 87 },
    { 1451 },
    { 1752, 32 },
    { 4857, 88 },
    { 1451 },
    { 2883 },
    { 4573, 33 },
    { 4857, 89 },
    { 1752, 33 },
    { 4857, 90 },
    { 3434 },
    { 1451 },
    { 2703, 16 },
    { 4857, 28 },
    { 7624 },
    { 4857, 79 },
    { 1752, 32 },
    { 4857, 91 },
    { 2883 },
    { 8565, 2 },
    { 4857, 34 },
    { 3434 },
    { 1451 },
    { 1752, 27 },
    { 4857, 92 },
    { 7624 },
    { 4862 },
    { 4908, 774 },
    { 1490 },
    { 4857, 4 },
    { 1451 },
    { 2703, 93 },
    { 1752, 27 },
    { 4857, 81 },
    { 7624 },
    { 8565, 1 },
    { 1451 },
    { 2703, 9 },
    { 4857, 94 },
    { 7624 },
    { 1752, 1 },
    { 1752, 9 },
    { 1752, 27 },
    { 4857, 81 },
    { 7624 },
    { 1752, 27 },
    { 4857, 63 },
    { 7624 },
    { 1752, 6 },
    { 8565, 5 },
    { 1451 },
    { 4573, 34 },
    { 1752, 1 },
    { 4857, 49 },
    { 7624 },
    { 4862 },
    { 6995, 804 },
    { 1490 },
    { 1752, 13 },
    { 8840 },
    { 4862 },
    { 6995, 820 },
    { 1490 },
    { 1752, 27 },
    { 4857, 81 },
    { 7624 },
    { 4857, 53 },
    { 8967 },
    { 4862 },
    { 4908, 820 },
    { 1490 },
    { 1752, 27 },
    { 4857, 81 },
    { 7624 },
    { 4857, 56 },
    { 8967 },
    { 6995, 825 },
    { 1752, 34 },
    { 4857, 89 },
    { 3434 },
    { 4573, 34 },
    { 1752, 29 },
    { 4862 },
    { 6995, 836 },
    { 1490 },
    { 1752, 29 },
    { 4857, 95 },
    { 7624 },
    { 4862 },
    { 4908, 836 },
    { 1490 },
    { 4857, 4 },
    { 4862 },
    { 4908, 850 },
    { 1490 },
    { 1752, 28 },
    { 4862 },
    { 6995, 850 },
    { 1490 },
    { 1752, 28 },
    { 4857, 95 },
    { 7624 },
    { 4862 },
    { 4908, 850 },
    { 1490 },
    { 4857, 4 },
    { 4862 },
    { 4908, 854 },
    { 1490 },
    { 4857, 4 },
    { 4573, 35 },
    { 1752, 35 },
    { 4857, 79 },
    { 2825 },
    { 6995, 870 },
    { 1752, 34 },
    { 2703, 16 },
    { 4857, 28 },
    { 7624 },
    { 4857, 96 },
    { 1752, 35 },
    { 8565, 2 },
    { 4857, 84 },
    { 3434 },
    { 2729 },
    { 4573, 34 },
    { 1752, 9 },
    { 4857, 97 },
    { 1752, 27 },
    { 4857, 81 },
    { 7624 },
    { 2822 },
    { 2822 },
    { 4573, 36 },
    { 1752, 1 },
    { 4857, 98 },
    { 7624 },
    { 4862 },
    { 6995, 889 },
    { 1490 },
    { 1752, 1 },
    { 4857, 98 },
    { 7624 },
    { 1752, 36 },
    { 7624 },
    { 4573, 37 },
    { 1752, 37 },
    { 6995, 910 },
    { 1752, 6 },
    { 1752, 37 },
    { 8664 },
    { 6995, 901 },
    { 1752, 34 },
    { 4857, 99 },
    { 2729 },
    { 4573, 34 },
    { 3360, 910 },
    { 8480 },
    { 4573, 38 },
    { 1752, 1 },
    { 4857, 98 },
    { 7624 },
    { 1752, 36 },
    { 1752, 38 },
    { 7811 },
    { 1490 },
    { 6179 },
    { 4862 },
    { 4857, 63 },
    { 1752, 27 },
    { 4857, 63 },
    { 7624 },
    { 7811 },
    { 1490 },
    { 4862 },
    { 4857, 81 },
    { 1752, 27 },
    { 4857, 81 },
    { 7624 },
    { 7811 },
    { 1490 },
    { 4862 },
    { 4857, 100 },
    { 2703, 16 },
    { 4857, 101 },
    { 7624 },
    { 4857, 26 },
    { 1752, 34 },
    { 8565, 2 },
    { 7811 },
    { 1490 },
    { 4573, 39 },
    { 1752, 22 },
    { 1752, 22 },
    { 3245 },
    { 4857, 79 },
    { 1451 },
    { 1752, 39 },
    { 7811 },
    { 1490 },
    { 1752, 26 },
    { 1752, 25 },
    { 1451 },
    { 4573, 26 },
    { 3360, 626 },
    { 1752, 22 },
    { 3245 },
    { 4857, 4 },
    { 8967 },
    { 6995, 974 },
    { 4857, 4 },
    { 4573, 40 },
    { 1752, 1 },
    { 4857, 102 },
    { 1752, 40 },
    { 7811 },
    { 1490 },
    { 2703, 9 },
    { 4857, 103 },
    { 7624 },
    { 1752, 1 },
    { 1752, 9 },
    { 1752, 2 },
    { 1752, 8 },
    { 1752, 14 },
    { 3434 },
    { 1451 },
    { 8565, 3 },
    { 4857, 104 },
    { 2258, 2 },
    { 8480 },
    { 8480 },
    { 4573, 42 },
    { 4573, 41 },
    { 4857, 79 },
    { 4573, 43 },
    { 1752, 22 },
    { 3245 },
    { 4573, 44 },
    { 4857, 79 },
    { 4573, 45 },
    { 1752, 43 },
    { 4573, 46 },
    { 1752, 45 },
    { 4857, 4 },
    { 2825 },
    { 6995, 996 },
    { 1752, 46 },
    { 1752, 44 },
    { 1341 },
    { 4908, 1000 },
    { 3360, 1112 },
    { 1752, 46 },
    { 1752, 44 },
    { 2825 },
    { 6995, 1112 },
    { 1752, 22 },
    { 1752, 46 },
    { 7624 },
    { 4857, 4 },
    { 4573, 48 },
    { 4573, 47 },
    { 4857, 79 },
    { 4573, 49 },
    { 1752, 22 },
    { 3245 },
    { 4573, 50 },
    { 4857, 79 },
    { 4573, 51 },
    { 1752, 49 },
    { 4573, 52 },
    { 1752, 51 },
    { 4857, 4 },
    { 2825 },
    { 6995, 1024 },
    { 1752, 52 },
    { 1752, 50 },
    { 1341 },
    { 4908, 1028 },
    { 3360, 1067 },
    { 1752, 52 },
    { 1752, 50 },
    { 2825 },
    { 6995, 1067 },
    { 2703, 16 },
    { 4857, 17 },
    { 7624 },
    { 2703, 18 },
    { 1752, 22 },
    { 1752, 52 },
    { 7624 },
    { 4857, 63 },
    { 7624 },
    { 1752, 47 },
    { 4857, 63 },
    { 7624 },
    { 2729 },
    { 8565, 1 },
    { 8565, 1 },
    { 4573, 53 },
    { 1752, 53 },
    { 4857, 105 },
    { 1341 },
    { 6995, 1062 },
    { 1752, 48 },
    { 1752, 22 },
    { 1752, 52 },
    { 7624 },
    { 4857, 100 },
    { 7624 },
    { 4857, 79 },
    { 1752, 53 },
    { 4857, 106 },
    { 2883 },
    { 2729 },
    { 3434 },
    { 1451 },
    { 4573, 48 },
    { 1752, 52 },
    { 1752, 51 },
    { 1451 },
    { 4573, 52 },
    { 3360, 1015 },
    { 1752, 48 },
    { 4573, 54 },
    { 1752, 47 },
    { 4857, 107 },
    { 1752, 54 },
    { 7811 },
    { 1490 },
    { 1752, 41 },
    { 8840 },
    { 4862 },
    { 4908, 1086 },
    { 1490 },
    { 1752, 47 },
    { 4857, 107 },
    { 7624 },
    { 1752, 41 },
    { 4857, 107 },
    { 7624 },
    { 2722 },
    { 6995, 1092 },
    { 1752, 41 },
    { 1752, 47 },
    { 4573, 41 },
    { 4573, 42 },
    { 3360, 1107 },
    { 1752, 42 },
    { 8840 },
    { 4862 },
    { 4908, 1104 },
    { 1490 },
    { 1752, 47 },
    { 4857, 107 },
    { 7624 },
    { 1752, 42 },
    { 4857, 107 },
    { 7624 },
    { 2722 },
    { 6995, 1107 },
    { 1752, 47 },
    { 4573, 42 },
    { 1752, 46 },
    { 1752, 45 },
    { 1451 },
    { 4573, 46 },
    { 3360, 987 },
    { 1752, 42 },
    { 4862 },
    { 6995, 1136 },
    { 1490 },
    { 2703, 108 },
    { 1752, 41 },
    { 4857, 107 },
    { 7624 },
    { 1752, 42 },
    { 4857, 107 },
    { 7624 },
    { 2729 },
    { 2703, 16 },
    { 4857, 101 },
    { 7624 },
    { 4857, 76 },
    { 1752, 41 },
    { 4857, 107 },
    { 7624 },
    { 8565, 2 },
    { 2883 },
    { 4857, 4 },
    { 4857, 79 },
    { 8565, 3 },
    { 4862 },
    { 4908, 1140 },
    { 1490 },
    { 4857, 79 },
    { 4573, 55 },
    { 2703, 108 },
    { 1752, 12 },
    { 4857, 109 },
    { 3434 },
    { 1752, 55 },
    { 4857, 109 },
    { 3434 },
    { 1451 },
    { 2703, 16 },
    { 4857, 28 },
    { 7624 },
    { 4857, 79 },
    { 1752, 41 },
    { 4857, 107 },
    { 7624 },
    { 4857, 110 },
    { 2883 },
    { 8565, 2 },
    { 4857, 42 },
    { 3434 },
    { 1451 },
    { 4857, 4 },
    { 4857, 79 },
    { 8565, 3 },
    { 4573, 56 },
    { 1752, 1 },
    { 4857, 102 },
    { 1752, 56 },
    { 7811 },
    { 1490 },
    { 2703, 18 },
    { 1752, 41 },
    { 4857, 63 },
    { 7624 },
    { 8565, 1 },
    { 1752, 41 },
    { 4857, 81 },
    { 7624 },
    { 2258, 2 },
    { 2258, 0 },
  }
  local t2 = {
    "Y_new_list",
    "tonumber",
    "record_quality",
    0,
    "air",
    "lby_span",
    "span",
    14,
    "Y",
    "add_main_candidates",
    "body_hint",
    "add",
    "beta_body",
    0.18,
    0.1,
    "math",
    "abs",
    "Y_norm",
    2,
    "beta_lby",
    "stand",
    "slow",
    "duck",
    0.05,
    0.22,
    0.02,
    "beta_lby_side",
    "min",
    0.65,
    38,
    0.04,
    "beta_side",
    0.16,
    0.12,
    "beta_opp",
    "side_switch",
    0.06,
    "beta_eye",
    0.08,
    "micro_move",
    "beta_micro",
    0.3,
    18,
    0.14,
    "last_move_yaw",
    "last_move_tick",
    64,
    "beta_lastmove",
    "break_lc",
    "Y_predicted",
    0.48,
    0.44,
    "beta_pred",
    0.38,
    34,
    "beta_vel",
    "move",
    "vel_alignment",
    "good_yaw",
    "tick",
    128,
    "beta_good",
    "yaw",
    0.26,
    "lby_break_yaw",
    "lby_break_tick",
    16,
    "beta_lbybreak",
    0.24,
    "defensive",
    "beta_defeye",
    "beta_defhalf",
    0.5,
    "angel_phase_candidate",
    "Beta",
    0.2,
    "filter_wide",
    "by_state",
    1,
    "n",
    "bucket",
    "wh",
    "h",
    0.25,
    "wm",
    "m",
    1.35,
    2.7,
    0.55,
    0.85,
    7,
    "prior",
    "Y_bucket_prior",
    "feedback_score",
    "streak",
    3,
    "|",
    "beta_ban",
    2.5,
    "weight",
    "max",
    "beta_confidence",
    "gate_clamp",
    "beta_fallback",
    22,
    44,
    "score",
    "clamp",
    0.35,
    3.2,
  }
  local t3 = { ... }
  local t4 = {}
  local n1, n2 = 1, 0
  local function f1(v)
    n2 = n2 + 1
    t4[n2] = v
  end
  local function f2()
    local v = t4[n2]
    t4[n2] = nil
    n2 = n2 - 1
    return v
  end
  local v1 = setmetatable({
    Y = yaw_state,
    Y_new_list = make_bucket_list,
    Y_bucket_prior = bucket_value,
    Y_norm = normalize_angle,
    Y_predicted = yaw_from_jhist,
    clamp = clamp,
  }, { __index = _G })
  while true do
    local v1 = t1[n1]
    n1 = n1 + 1
    local v2 = v1[1]
    if v2 == 4857 then
      f1(t2[v1[2]])
    elseif v2 == 8480 then
      f1(nil)
    elseif v2 == 1865 then
      f1(true)
    elseif v2 == 2218 then
      f1(false)
    elseif v2 == 1752 then
      f1(t3[v1[2]])
    elseif v2 == 4573 then
      t3[v1[2]] = f2()
    elseif v2 == 2703 then
      f1(v1[t2[v1[2]]])
    elseif v2 == 7624 then
      local k = f2()
      local v = f2()
      f1(v[k])
    elseif v2 == 7811 then
      local v = f2()
      local k = f2()
      local t = f2()
      t[k] = v
      f1(t)
    elseif v2 == 6179 then
      f1({})
    elseif v2 == 1490 then
      f2()
    elseif v2 == 4862 then
      f1(t4[n2])
    elseif v2 == 8565 then
      local n = v1[2]
      local q = {}
      for i = n, 1, -1 do
        q[i] = f2()
      end
      local f = f2()
      f1(f(unpack(q, 1, n)))
    elseif v2 == 1384 then
      local n, m = v1[2], v1[3]
      local q = {}
      for i = n, 1, -1 do
        q[i] = f2()
      end
      local f = f2()
      local z = { f(unpack(q, 1, n)) }
      for i = 1, m do
        f1(z[i])
      end
    elseif v2 == 3360 then
      n1 = v1[2]
    elseif v2 == 6995 then
      local v = f2()
      if not v then
        n1 = v1[2]
      end
    elseif v2 == 4908 then
      local v = f2()
      if v then
        n1 = v1[2]
      end
    elseif v2 == 2258 then
      local n = v1[2]
      local q = {}
      for i = n, 1, -1 do
        q[i] = f2()
      end
      return unpack(q, 1, n)
    elseif v2 == 1451 then
      local b = f2()
      local a = f2()
      f1(a + b)
    elseif v2 == 2729 then
      local b = f2()
      local a = f2()
      f1(a - b)
    elseif v2 == 3434 then
      local b = f2()
      local a = f2()
      f1(a * b)
    elseif v2 == 2883 then
      local b = f2()
      local a = f2()
      f1(a / b)
    elseif v2 == 8693 then
      local b = f2()
      local a = f2()
      f1(a % b)
    elseif v2 == 3048 then
      local b = f2()
      local a = f2()
      f1(a ^ b)
    elseif v2 == 2822 then
      local b = f2()
      local a = f2()
      f1(a .. b)
    elseif v2 == 8967 then
      local b = f2()
      local a = f2()
      f1(a == b)
    elseif v2 == 7671 then
      local b = f2()
      local a = f2()
      f1(a ~= b)
    elseif v2 == 8664 then
      local b = f2()
      local a = f2()
      f1(a < b)
    elseif v2 == 1341 then
      local b = f2()
      local a = f2()
      f1(a <= b)
    elseif v2 == 2722 then
      local b = f2()
      local a = f2()
      f1(a > b)
    elseif v2 == 2825 then
      local b = f2()
      local a = f2()
      f1(a >= b)
    elseif v2 == 4370 then
      t4[n2] = -t4[n2]
    elseif v2 == 8840 then
      t4[n2] = not t4[n2]
    elseif v2 == 3245 then
      t4[n2] = #t4[n2]
    else
      error("vm", 0)
    end
  end
end
local function set_yaw(ent, yaw)
  local wrote = false
  local ok = pcall(function()
    local ang = ent:get_eye_angles()
    if ang and finite(ang.y) then
      ang.y = yaw
      ent:set_eye_angles(ang)
      wrote = true
    end
  end)
  if ok and wrote then
    return true
  end
  local ok2, wrote2 = pcall(function()
    ent.m_angEyeAngles.y = yaw
    return true
  end)
  return ok2 == true and wrote2 == true
end
yaw_state.update = function(self)
  if self.suspended or dup_warned then
    return
  end
  local resolver_master = item_enabled(app.resolver)
  local yaw_active = resolver_master and item_enabled(app.yaw)
  local assist_active = resolver_master and item_enabled(app.assist)
  if not yaw_active and not assist_active then
    if self.enabled then
      self:reset("switch off")
    end
    return
  end
  local decay_now = game_time()
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
    if game_time() < (self.fault_until or 0) then
      return
    end
    self.fault = nil
  end
  if not globals or globals.is_in_game ~= true then
    self.last_status = "Yaw-Resolver: PAUSE"
    return
  end
  if native_api.master and not native_api:master_enabled() then
    self.last_status = "Yaw-Resolver: native Ragebot off; unchanged"
    return
  end
  if yaw_active and native_ready() then
    self.yielded = true
    self.last_status =
        "Yaw-Resolver: native Override Resolver ON; custom resolver yielded"
    log_once(
         "yaw_native_conflict",
         "Yaw Resolver: native Override Resolver is ON; the custom resolver yields. Disable the native resolver to use Emberlight's own yaw logic.")
    return
  end
  self.yielded = false
  self.enabled = yaw_active
  local ok, threat = pcall(function()
    return entity.get_threat()
  end)
  if not ok or not threat then
    self.last_status = "Yaw-Resolver: no current threat"
    return
  end
  local ok2, alive, dormant, enemy = pcall(function()
    return threat:is_alive(), threat:is_dormant(), threat:is_enemy()
  end)
  if not ok2 or not alive or dormant or not enemy then
    self.last_status = "Yaw-Resolver: threat not a live enemy"
    return
  end
  local base, kind = get_eye_yaw(threat)
  if not base then
    self.last_status = "Yaw-Resolver: eye angles unavailable"
    return
  end
  local vel_angle, speed = get_velocity(threat)
  local lby = get_lower_yaw(threat)
  local t = game_time()
  local ok3, target_id = pcall(function()
    return threat:get_index()
  end)
  if not ok3 or not finite(target_id) then
    local ok_info, info = pcall(function()
      return threat:get_player_info()
    end)
    if ok_info and type(info_tab) == "table" and finite(tonumber(info_tab.userid)) then
      target_id = tonumber(info_tab.userid)
    else
      self.last_status = "Yaw-Resolver: target index unavailable"
      return
    end
  end
  if self.brute_target ~= target_id then
    self.brute, self.brute_target = 0, target_id
  end
  if self.miss_target == target_id and t - self.last_miss <= 2 then
    self.brute = math.min(8, self.brute + 1)
    self.miss_target, self.last_miss = nil, 0
  end
  local L = self.learn[target_id]
  if not L then
    L = {}
    self.learn[target_id] = L
  end
  local v1 = finite(globals.tickcount) or 0
  local pose_delta = get_pose(threat)
  local duck = get_duck(threat)
  local state, delta = speed_from_flags(threat, speed, duck, pose_delta)
  yaw_state.lby_span_track(L, base, lby)
  if state ~= "air" then
  end
  local body_hint =
      lby or (pose_delta and normalize_angle(base + pose_delta)) or base
  if state ~= "air" then
    yaw_from_history(L, body_hint, v1, state)
  end
  local jitter = L.jitter or 0
  local side = vote_lby_break(L, base, pose_delta, lby)
  L.body_hint = pose_delta and normalize_angle(base + pose_delta) or nil
  L.body_strength = pose_delta and math.abs(pose_delta) or 0
  record_stability(L, state, speed, base, lby, v1)
  yaw_state.context_signal(L, state, speed, pose_delta, lby, base, v1)
  yaw_state.evalate_signal(L, base, pose_delta, lby, delta, v1, state)
  local aim_yaw = yaw_state.aim_at_me(threat)
  if aim_yaw then
    L.aim_delta = math.abs(normalize_angle(aim_yaw - base))
    L.defensive = L.aim_delta >= 110
  else
    L.aim_delta = nil
    L.defensive = nil
  end
  L.distance_sqr = yaw_state.distance_sqr(threat)
  L.__state, L.__base, L.__side, L.__delta = state, base, side, delta
  yaw_state.lby_cadence(L, state, speed, lby, v1, base)
  local spinning = jitter > 0.72 and speed < 15 and not L.alternating and
    (L.spin_score or 0) > 0.7
  local rmode =
      (assist_active and not yaw_active) and "Free" or current_yaw_mode()
  local yaw, mode
  if spinning then
    yaw = normalize_angle(base + clamp(L.spin_step or 0, -delta, delta))
    mode = "spin"
  elseif rmode == "Beta" then
    yaw, mode = yaw_state.resolve_beta(
                       L,
                       base,
                       vel_angle,
                       speed,
                       lby,
                       v1,
                       jitter,
                       side,
                       state,
                       delta)
  else
    yaw, mode = yaw_state.resolve_free(
                       L,
                       base,
                       vel_angle,
                       speed,
                       lby,
                       v1,
                       jitter,
                       side,
                       state,
                       delta,
                       self.last_angles,
                       self.last_target == target_id,
                       t,
                       self.brute)
  end
  if not finite(yaw) then
    local safe_base = finite(base) or 0
    local safe_delta = clamp(finite(delta) or 0, 0, 60)
    local safe_side = finite(side) and (side >= 0 and 1 or -1) or 1
    if state == "air" and finite(vel_angle) then
      yaw, mode =
          yaw_state.gate_clamp(L, state, vel_angle),
          "vel_safe_fallback"
    elseif finite(lby) then
      yaw, mode = yaw_state.gate_clamp(L, state, lby), "lby_safe_fallback"
    else
      yaw, mode =
          yaw_state.gate_clamp(L, state, safe_base + safe_side * safe_delta),
          "commit_safe_fallback"
    end
    L.resolve_fallbacks = (L.resolve_fallbacks or 0) + 1
  end
  L.__cur, L.__yaw = mode, yaw
  self.mode = mode
  if assist_active and not yaw_active then
    self.last_status = string.format(
              "Assist Resolver: observing %s / conf %.2f",
              mode,
              tonumber(L.static_confidence) or 0)
    return
  end
  if self.last_target == target_id and self.last_angles and
    math.abs(normalize_angle(yaw - self.last_angles)) < 0.5 then
    self.last_status =
        string.format("Yaw-Resolver: %s -> %.1f (stable)", mode, yaw)
    return
  end
  if set_yaw(threat, yaw) then
    self.writes = self.writes + 1
    self.last_write, self.last_target, self.last_angles = t, target_id, yaw
    self.last_status = string.format(
              "Yaw-Resolver: %s -> %.1f (base %.1f, idx %d)",
              mode,
              yaw,
              base,
              self.brute + 1)
  else
    self.blocked = self.blocked + 1
    self.last_status = "Yaw-Resolver: write blocked (API)"
  end
end
yaw_state.note_miss = function(self, ent)
  if not yaw_state.path_active() or self.fault or self.suspended then
    return
  end
  local ok, id = pcall(function()
    return ent:get_index()
  end)
  if not ok or not finite(id) then
    return
  end
  self.miss_target, self.last_miss = id, game_time()
end
yaw_state.on_shot = function(self, event)
  if self.suspended or self.fault or not yaw_state.path_active() then
    return
  end
  local ok, tid = pcall(function()
    local t = event.target
    if not t then
      return nil
    end
    local idx = t:get_index()
    if finite(idx) then
      return idx
    end
    local info_tab = t:get_player_info()
    return info_tab and tonumber(info_tab.userid) or nil
  end)
  if not ok or not tid then
    return
  end
  local L = self.learn[tid]
  local bucket = (L and L.__cur) or "unknown"
  local st = (L and L.__state) or "unknown"
  local mode = yaw_state.mode_label()
  local now, tick = game_time(), finite(globals.tickcount) or 0
  for id, old in pairs(self.shots) do
    local stale_time =
        old.time and (now < old.time or now - old.time > t3.shot_ttl)
    local stale_tick = old.tick and (tick < old.tick or
      tick - old.tick > t3.shot_tick_ttl)
    if stale_time or stale_tick then
      self.shots[id] = nil
    end
  end
  local base = L and tonumber(L.__base) or nil
  local yaw = L and tonumber(L.__yaw) or nil
  local resolve_side = base and yaw and (normalize_angle(yaw - base) >= 0 and 1 or -1) or
    (L and L.__side) or 1
  self.shots[event.id] = {
    tid = tid,
    bucket = bucket,
    state = st,
    mode = mode,
    base = base,
    yaw = yaw,
    side = resolve_side,
    static_confidence = (L and tonumber(L.static_confidence)) or 0,
    record_quality = (L and tonumber(L.record_quality)) or 0,
    tick = tick,
    time = now,
  }
  local n = 0
  for _ in pairs(self.shots) do
    n = n + 1
  end
  if n > 256 then
    self.shots = {}
  end
end
yaw_state.on_ack = function(self, event)
  if not event or event.id == nil then
    return
  end
  local shot = self.shots[event.id] or self.shots[tostring(event.id)]
  if not shot then
    return
  end
  self.shots[event.id], self.shots[tostring(event.id)] = nil, nil
  local now, now_tick = game_time(), finite(globals.tickcount) or 0
  if shot.time and (now < shot.time or now - shot.time > t3.shot_ttl) then
    return
  end
  if shot.tick and
    (now_tick < shot.tick or now_tick - shot.tick > t3.shot_tick_ttl) then
    return
  end
  local L = self.learn[shot.tid]
  if not L then
    return
  end
  local state, bucket = shot.state or "unknown", shot.bucket or "unknown"
  L.by_state = L.by_state or {}
  L.by_state[state] = L.by_state[state] or {}
  L.state_miss = L.state_miss or {}
  L.last_hit_by_state = L.last_hit_by_state or {}
  local global = L[bucket] or { h = 0, m = 0 }
  L[bucket] = global
  local rec = L.by_state[state][bucket] or { h = 0, m = 0 }
  L.by_state[state][bucket] = rec
  self.population.learned = (self.population.learned or 0) + 1
  local function f1(row, hit, weight)
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
  local v1 = finite(globals.tickcount) or shot.tick or 0
  update_feedback(L, v1)
  if reason == nil then
    f1(global, true, 1)
    f1(rec, true, 1)
    L.consec_miss = 0
    L.state_miss[state] = 0
    L.last_hit, L.last_hit_by_state[state] = now, now
    yaw_state.angel_feedback(L, shot.mode, true, v1, state)
    yaw_state.remember_hit(L, state, shot.yaw, v1, bucket)
    if shot.mode == "Beta" and L.beta_ban then
      for key in pairs(L.beta_ban) do
        if key:sub(1, #state + 1) == state .. "|" then
          L.beta_ban[key] = nil
        end
      end
    end
    return
  end
  local reason_key =
      tostring(reason):lower():gsub("^%s+", ""):gsub("%s+$", "")
  if reason_key == "damage rejection" then
    f1(global, true, 1)
    f1(rec, true, 1)
    L.consec_miss = 0
    yaw_state.remember_hit(L, state, shot.yaw, v1, bucket)
    yaw_state.angel_feedback(L, shot.mode, true, v1, state)
    return
  end
  if reason_key ~= "correction" and reason_key ~= "resolver" and
    reason_key ~= "?" then
    return
  end
  if (tonumber(event.spread) or 0) >= t3.max_learning_spread then
    return
  end
  local bt = tonumber(event.backtrack) or 0
  local weight =
      bt >= 12 and 0.35 or bt >= 8 and 0.5 or bt >= 5 and 0.72 or 1
  local weak = weight <= t3.min_feedback_weight
  f1(global, false, weight)
  f1(rec, false, weight)
  yaw_state.remember_miss(L, state, shot.yaw, v1, weight, bucket)
  if shot.mode == "Beta" and not weak then
    L.beta_ban = L.beta_ban or {}
    L.beta_ban[state .. "|" .. bucket] = v1 + t3.ban_ticks
  end
  if not weak then
    L.consec_miss = (L.consec_miss or 0) + 1
    L.state_miss[state] = (L.state_miss[state] or 0) + 1
    yaw_state.angel_feedback(L, shot.mode, false, v1, state)
  end
end
yaw_state.log_miss_ack = function(self, event, shot)
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
  local spread_masked = spread_value ~= nil and spread_value >= t3.max_learning_spread and (reason_key == "correction" or reason_key == "resolver" or
    reason_key == "?")
  self.ack_stats.misses = (self.ack_stats.misses or 0) + 1
  self.miss_counts[spread_masked and "spread (masked)" or reason_key] = (self.miss_counts[spread_masked and "spread (masked)" or reason_key] or 0) +
    1
  if reason_key == "correction" and not spread_masked then
    self.ack_stats.correction = (self.ack_stats.correction or 0) + 1
  end
  if not shot then
    self.ack_stats.unmatched = (self.ack_stats.unmatched or 0) + 1
  end
  local id = tonumber(event.id) or 0
  local target = event.target
  local target_id, target_name
  pcall(function()
    if target then
      target_id = target:get_index()
      target_name = target:get_name()
    end
  end)
  target_id = tonumber(target_id) or (shot and shot.id) or 0
  target_name = (shot and shot.tag) or target_name or "?"
  target_name = tostring(target_name):gsub("[%c|]", " "):sub(1, 48)
  local L = target_id ~= 0 and self.learn[target_id] or nil
  local bucket = (shot and shot.yaw_bucket) or (L and L.__cur) or "unknown"
  local state = (shot and shot.yaw_state) or (L and L.__state) or "unknown"
  local mode = (shot and shot.yaw_mode) or current_yaw_mode()
  local yaw = shot and shot.yaw_value or nil
  local bt = tonumber(event.backtrack) or (shot and shot.backtrack) or 0
  local interval =
      (shot and shot.interval) or (globals and finite(globals.tickinterval))
  local bt_ms = interval and bt >= 0 and bt * interval * 1000 or nil
  local age =
      shot and math.max(0, game_time() - (shot.time or game_time())) or nil
  local hitchance = tonumber(event.hitchance)
  local spread = tonumber(event.spread)
  local wanted = tonumber(event.wanted_damage)
  local damage = tonumber(event.damage)
  local wanted_hg = event.wanted_hitgroup
  local hitgroup = event.hitgroup
  local safe = shot and tostring(shot.safe_value) or "?"
  local owned = shot and (shot.safe_owned and "emberlight" or "native/external") or
    "unmatched"
  local corr = shot and tonumber(shot.yaw_corr) or nil
  local corr_abs = corr and math.abs(corr) or nil
  local corr_side = shot and tonumber(shot.yaw_side) or nil
  if corr and corr_side == nil then
    corr_side = corr >= 0 and 1 or -1
  end
  local base = shot and tonumber(shot.yaw_base) or nil
  local pose = shot and tonumber(shot.yaw_pose) or nil
  local signal = "?"
  if spread ~= nil then
    signal = spread > bands.noise_spread and "noise" or "clean"
  end
  local details = { string.format("#%d %s", id, target_name), "reason=" .. raw_reason .. (spread_masked and " [spread]" or ""), "signal=" .. signal .. (spread_masked and "/masked" or ""), "correlated=" .. (shot and "yes" or "NO"), "target=" .. tostring(target_id), "mode=" .. tostring(mode), "state=" .. tostring(state), "bucket=" .. tostring(bucket), "yaw=" .. (yaw and string.format("%.2f", yaw) or "unknown"), "corr=" .. (corr and string.format("%+.2f", corr) or "?") .. "/" .. (corr_abs and string.format("%.2f", corr_abs) or "?") .. "/" ..
    tostring((shot and shot.yaw_band) or "?") .. "/side=" .. (corr_side and (corr_side >= 0 and "+" or "-") .. "1" or "?"), "base=" ..
    (base and string.format("%.2f", base) or "?") .. "/pose=" .. (pose and string.format("%.2f", pose) or "?"), "sconf=" .. (shot and string.format("%.2f", tonumber(shot.resolver_confidence) or 0) or
    "?") .. "/econf=" .. (shot and string.format("%.2f", tonumber(shot.evalate_confidence) or 0) or
    "?") .. "/fbias=" ..
    (shot and string.format("%.2f", tonumber(shot.feedback_bias) or 0) or "?"), "evalate=" .. (shot and (shot.evalate_active and "ACTIVE" or "off") or "unmatched") .. "/brute=" .. (shot and tostring(shot.evalate_brute or "?") or "?") .. "/forced=" .. (shot and shot.evalate_forced and
    string.format("%.2f", shot.evalate_forced) or "?") .. "/conf=" .. (shot and string.format("%.2f", tonumber(shot.evalate_confidence) or 0) or
    "?"), "bt=" ..
    tostring(bt) .. "t/" .. (bt_ms and string.format("%.2fms", bt_ms) or "?ms"), "age=" .. (age and string.format("%.3fs", age) or "?s"), "srv=" .. (shot and tostring(shot.server_tick) or "?") .. "/" .. tostring(shot and shot.server_tick_source or "?") .. "/lag=" .. (shot and tonumber(shot.lag) and string.format("%.3fs", tonumber(shot.lag)) or
    "?") .. "/dead=" .. (shot and tonumber(shot.dead_time) and
    string.format("%.3fs", tonumber(shot.dead_time)) or "?") .. "/lat=" .. (shot and tonumber(shot.latency) and
    string.format("%.3fs", tonumber(shot.latency)) or "?") .. "/unlag=" .. (shot and tonumber(shot.max_unlag) and
    string.format("%.3fs", tonumber(shot.max_unlag)) or "?"), "safe=" .. safe .. "/" .. owned, "hc_ack=" .. (hitchance and string.format("%.1f", hitchance) or "?"), "spread=" .. (spread and string.format("%.3f", spread) or "?"), "dmg=" .. tostring(damage or "?") .. "/" .. tostring(wanted or "?"), "hg=" .. tostring(hitgroup or "?") .. "/" .. tostring(wanted_hg or "?") }
  local log = self.miss_log
  log[#log + 1] = table.concat(details, " | ")
  yaw_state.miss_state.miss_log = self.miss_log
  yaw_state.miss_state.bucket_stats = self.bucket_stats
  yaw_state.miss_state.miss_counts = self.miss_counts
  yaw_state.miss_state.ack_stats = self.ack_stats
  yaw_state.miss_state.mode_stats = self.mode_stats
  yaw_state.miss_state.delta_stats = self.delta_stats
  yaw_state.miss_state.population = self.population
  if #log > bands.max_rows then
    table.remove(log, 1)
  end
end
yaw_state.miss_log_lines = function(self)
  local lines, log, a = {}, self.miss_log, self.ack_stats
  lines[#lines + 1] = "==== Emberlight Miss Logs ===="
  lines[#lines + 1] = string.format(
              "acks: hits=%d misses=%d correction=%d unmatched=%d | stored=%d",
              a.hits or 0,
              a.misses or 0,
              a.correction or 0,
              a.unmatched or 0,
              #log)
  local pop = self.population or {}
  lines[#lines + 1] = string.format(
              "population: acks=%d hits=%d misses=%d correlated=%d matched=%d learned=%d wide_rejects=%d | noise_spread=%.2f learn_max_spread=%.1f",
              pop.acks or 0,
              pop.hits or 0,
              pop.misses or 0,
              pop.correlated or 0,
              pop.matched or 0,
              pop.learned or 0,
              pop.wide_rejects or 0,
              bands.noise_spread,
              t3.max_learning_spread)
  lines[#lines + 1] =
      "note: hc_ack/spread are values reported by the ack event, not values used by the firing decision."
  lines[#lines + 1] =
      "note: signal=noise is reporting-only (spread > noise_spread); it never gates learning."
  lines[#lines + 1] =
      "note: wide_rejects counts candidates dropped for sitting further than the per-state aim limit (stand/slow/duck 60, move 75, air 95) from the recorded eye yaw."
  lines[#lines + 1] =
      "note: Baseline = master or Yaw path was off, so the native ragebot resolved. Compare its hitrate against the mode rows to judge the custom resolver."
  lines[#lines + 1] = "---- persistent per-mode totals ----"
  for _, mode in ipairs({ "Baseline", "Free", "Beta", "Assist", "Unmatched" }) do
    local row = self.mode_stats[mode]
    if row then
      local attempts = (row.hits or 0) + (row.misses or 0)
      local hitrate = attempts > 0 and (row.hits or 0) * 100 / attempts or 0
      lines[#lines + 1] = string.format(
              "mode %-9s | hits=%d misses=%d correction=%d attempts=%d hitrate=%.1f%%",
              mode,
              row.hits or 0,
              row.misses or 0,
              row.correction or 0,
              attempts,
              hitrate)
    end
  end
  local reasons = {}
  for reason, count in pairs(self.miss_counts) do
    reasons[#reasons + 1] = { reason = reason, count = count }
  end
  table.sort(reasons, function(a1, second)
    if a1.count ~= second.count then
      return a1.count > second.count
    end
    return a1.reason < second.reason
  end)
  if #reasons == 0 then
    lines[#lines + 1] = "reasons: none captured"
  else
    for _, r in ipairs(reasons) do
      lines[#lines + 1] =
          string.format("reason %-24s | count=%d", r.reason, r.count)
    end
  end
  lines[#lines + 1] =
      "---- applied correction by candidate x magnitude band x side ----"
  local any_delta = false
  local order = {}
  for bucket in pairs(self.delta_stats) do
    order[#order + 1] = bucket
  end
  table.sort(order)
  for _, bucket in ipairs(order) do
    local cells = {}
    for key, rec in pairs(self.delta_stats[bucket]) do
      cells[#cells + 1] = { key = key, h = rec.h or 0, m = rec.m or 0 }
    end
    table.sort(cells, function(x, y)
      return x.key < y.key
    end)
    local parts = {}
    for _, c in ipairs(cells) do
      local attempts = c.h + c.m
      local hitrate = attempts > 0 and c.h * 100 / attempts or 0
      parts[#parts + 1] = string.format(
              "%s h%d/m%d/%d%%",
              c.key,
              c.h,
              c.m,
              math.floor(hitrate + 0.5))
    end
    if #parts > 0 then
      any_delta = true
      lines[#lines + 1] =
          string.format("delta %-14s | %s", bucket, table.concat(parts, "  "))
    end
  end
  if not any_delta then
    lines[#lines + 1] =
        "delta: no rows captured (no shot carried a base/applied yaw pair)"
  end
  lines[#lines + 1] = "---- chronological misses (oldest -> newest) ----"
  for i = 1, #log do
    lines[#lines + 1] = log[i]
  end
  lines[#lines + 1] = string.format(
              "---- per-candidate hit/miss (correlated shots only, %d of %d acks; unmatched acks carry no bucket) ----",
              pop.correlated or 0,
              pop.acks or 0)
  local rows = {}
  for bucket, rec in pairs(self.bucket_stats) do
    rows[#rows + 1] = { bucket = bucket, h = rec.h or 0, m = rec.m or 0 }
  end
  table.sort(rows, function(a1, second)
    if a1.h ~= second.h then
      return a1.h > second.h
    end
    return a1.bucket < second.bucket
  end)
  local cand_h, cand_m = 0, 0
  for _, r in ipairs(rows) do
    lines[#lines + 1] =
        string.format("candidate %-12s | hits=%d misses=%d", r.bucket, r.h, r.m)
    cand_h, cand_m = cand_h + r.h, cand_m + r.m
  end
  lines[#lines + 1] = string.format(
              "candidate %-12s | hits=%d misses=%d",
              "TOTAL",
              cand_h,
              cand_m)
  lines[#lines + 1] = "==== end of Miss Logs ===="
  return lines
end
yaw_state.build_miss_log_text = function(self)
  return table.concat(self:miss_log_lines(), "\r\n")
end
yaw_state.reset = function(self, reason)
  self.enabled = false
  self.last_status = "Yaw-Resolver: OFF"
end
yaw_state.guard = function(self, method, ...)
  local ok, err = pcall(method, self, ...)
  if not ok then
    self.fault = "yaw resolver error"
    local detail = tostring(err):gsub("%c", " "):sub(1, 90)
    self.last_status = "Yaw-Resolver: error: " .. detail
    self.fault_until = game_time() + 5
    log_once("yaw_resolver_fault", self.fault .. ": " .. detail)
  end
end
local v2 = ui.create(app.main_tab, "‎", 2)
app.version_state.resolver_label = label_with_icon(
                first_icon({ "shield-halved", "shield-check", "shield" }),
                "Resolver")
app.resolver = v2:switch(app.version_state.resolver_label, false)
local resolver_menu = app.resolver:create()
app.assist = resolver_menu:switch(label_with_icon(
                first_icon({ "life-ring", "handshake-angle", "user-shield" }),
                "Assist"), false)
noop(
     app.assist,
     "Assist Resolver never writes enemy yaw. It observes resolver geometry and requests native Safe Points Prefer/Force only for fresh, exact risk signals. Enabling Assist disables Yaw Resolver and its mode controls.")
app.yaw = resolver_menu:switch(label_with_icon(
                first_icon({ "rotate", "arrows-rotate", "compass" }),
                "Yaw Resolver"), false)
app.yaw_mode = resolver_menu:combo("Yaw Mode", { "Free", "Beta" })
noop(
     app.yaw_mode,
     "Free is the conservative learned resolver. Beta uses angular-cluster voting over the shared CS:GO evidence set.")
pcall(function()
  local stored = app.yaw_mode:get()
  local normalized = app.version_state.normalize_mode(stored)
  if normalized then
    app.yaw_mode:set(normalized)
  end
end)
app.version_state.sync_mode_items()
noop(
     app.yaw,
     "Free and Beta use exposed Neverlose CS:GO data only. The custom resolver yields while native Override Resolver is ON.")
app.assist:set_callback(function()
  if item_enabled(app.assist) then
    pcall(function()
      app.yaw:set(false)
    end)
    yaw_state.enabled = false
    yaw_state:guard(yaw_state.update)
  else
    pcall(function()
      if native_api then
        native_api:request("safe", nil)
      end
    end)
  end
end)
app.yaw:set_callback(function()
  if item_enabled(app.assist) and item_enabled(app.yaw) then
    pcall(function()
      app.yaw:set(false)
    end)
    return
  end
  if item_enabled(app.yaw) then
    yaw_state.fault = nil
    yaw_state:guard(yaw_state.update)
  else
    yaw_state:reset("user toggle")
  end
end)
noop(
     app.resolver,
     "Master switch for two mutually-exclusive paths: Assist Resolver (native Safe Points risk control) or Yaw Resolver (Main / Trial / Bypass / Test).")
app.forceshot = v2:switch(
          label_with_icon(first_icon({ "crosshairs", "fire", "bolt" }), "ForceShot"),
          false)
local forceshot_menu
do
  forceshot_menu = app.forceshot:create()
  app.forceshot_mode = forceshot_menu:combo("ForceShot Mode", { "CSGO", "CS2" })
  pcall(function()
    app.forceshot_mode:set("CSGO")
  end)
end
noop(
     app.forceshot,
     "CSGO fires while attack is held; CS2-like waits for stopped accuracy using exposed Neverlose CS:GO controls.")
app.version_state.extrapolation_label = label_with_icon(
                first_icon({ "forward", "angles-right", "chart-line" }),
                "Extrapolation")
app.extrapolation = v2:switch(app.version_state.extrapolation_label, false)
local extrapolation_menu = app.extrapolation:create()
app.interpolation = extrapolation_menu:switch("Interpolation (built-in)", true)
pcall(function()
  app.interpolation:set(true)
end)
pcall(function()
  app.interpolation:disabled(true)
end)
pcall(function()
  app.interpolation:visibility(false)
end)
app.version_state.apply_ui = function()
  pcall(function()
    app.version_build_info:name(menu_icon .. " Beta " .. menu_note)
    app.version_user_info:name(
                           menu_icon .. " " .. strip_colours(get_username()) .. " " .. menu_note)
    app.version_updated_info:name(menu_icon ..
      " " .. strip_colours(app.version_state.beta_updated) .. " " .. menu_note)
    about_copy:name(menu_icon .. " PWNZ " .. menu_note)
  end)
  pcall(app.version_state.sync_mode_items)
  pcall(function()
    if set_menu_section then
      set_menu_section()
    end
  end)
end
app.extrapolation_ticks = extrapolation_menu:slider("Ticks", 0, 15, 0, 1, function(v)
  return v == 0 and "Off" or (v .. "t")
end)
app.extrapolation_auto = extrapolation_menu:switch("Auto from ping", true)
app.extrapolation_fake_latency = extrapolation_menu:switch("Include Fake Latency", true)
noop(
     app.extrapolation_ticks,
     "0 disables the feature. 1..15 aims that many ticks ahead. CS2 formula: 1 tick per 15ms of ping. 0-15 ping = 1t, 16-30 = 2t, 31-45 = 3t and so on, capped at 15t.\n\nCS:GO build: Neverlose has no native Extrapolation switch there (it is CS2-only), so this sets the portable movement-simulation horizon used for record validation and native safety requests. Auto from ping still retunes it.\n\nCS2 build: when the native Extrapolation switch is found it is driven directly at this value.\n\nAuto from ping sets the value for you every second from your live ping. Include Fake Latency adds the native Fake Latency value to your ping before the formula.")
noop(
     app.extrapolation_auto,
     "Every second, sets Ticks = clamp(round((ping + fake_latency) / 15), 0, 15). Turn off to set the slider manually.")
noop(
     app.extrapolation_fake_latency,
     "Adds the value of the native Fake Latency switch (Miscellaneous > Main > Other > Fake Latency) to your ping when Auto from ping is on.")
app.extrapolation_rewrite = extrapolation_menu:switch("Rewrite Enemy Origin", false)
noop(
     app.extrapolation_rewrite,
     "CS:GO-only true extrapolation. Every createmove the threat enemy's m_vecOrigin is rewritten to the predicted position from the Extrapolation simulation, so the native aimbot aims where the enemy will be. This is active record rewriting: it shows as a client-side teleport, raises ban risk, and is NOT safe for tournaments. Requires Extrapolation on and tick slider > 0. Disabled by default.")
app.unsafe_recharge = v2:switch(label_with_icon(
                first_icon({ "bolt", "battery-bolt", "gauge-high" }),
                "Unsafe Charge"), false)
local unsafe_recharge_menu
do
  unsafe_recharge_menu = app.unsafe_recharge:create()
  app.unsafe_mode =
      unsafe_recharge_menu:combo("Charge Mode", { "Faster Charge", "Unsafe Exploit" })
  pcall(function()
    app.unsafe_mode:set("Faster Charge")
  end)
end
app.movement = v2:switch(label_with_icon(
                first_icon({ "person-running", "shoe-prints", "arrows-up-down-left-right" }),
                "Movement"), false)
local movement_menu = app.movement:create()
app.fast_ladder = movement_menu:switch("Fast Ladder", false)
app.no_fall_damage = movement_menu:switch("No Fall Damage", false)
app.avoid_collision = movement_menu:switch("Avoid Collision", false)
app.jump_scout = v2:switch(label_with_icon(
                first_icon({ "person-ski-jumping", "crosshairs" }),
                "JumpScout"), false)
local f1 = function() end
local visuals_tab = ui.create(app.main_tab, "‎‌", 2)
app.clantag = visuals_tab:switch(
          label_with_icon(first_icon({ "tag", "signature" }), "ClanTag"),
          false)
noop(app.clantag, "Original synchronized Emberlight clan-tag animation.")
app.trash = visuals_tab:switch(
          label_with_icon(first_icon({ "comments", "comment-dots" }), "TrashTalk"),
          false)
noop(app.trash, "Beta ZXC trash lines on selected triggers.")
do
  local m = app.trash:create()
  app.trash_mode = m:combo("Mode", { "ZXC" })
  pcall(function()
    app.trash_mode:set("ZXC")
  end)
  app.trash_trigger = m:selectable("Trigger", {
    label_with_icon(first_icon({ "skull-crossbones", "skull" }), "On Kill"),
    label_with_icon(first_icon({ "heart-crack", "heart" }), "On Death"),
  })
  pcall(function()
    app.trash_trigger:set({
      label_with_icon(first_icon({ "skull-crossbones", "skull" }), "On Kill"),
      label_with_icon(first_icon({ "heart-crack", "heart" }), "On Death"),
    })
  end)
end
app.fps_optimizer = visuals_tab:switch(
          label_with_icon(first_icon({ "gauge-high", "bolt" }), "FPS Optimizer"),
          false)
do
  local m = app.fps_optimizer:create()
  app.opt_preset = m:combo("Preset", { "Recommended", "Maximum FPS" })
  pcall(function()
    app.opt_preset:set("Recommended")
  end)
  app.opt_list = m:selectable("Optimization", {
    "Decals",
    "Blood and gibs",
    "Tracers",
    "Breakable debris",
    "3D sky",
    "Ropes",
  })
end
noop(
     app.fps_optimizer,
     "Emberlash-style engine optimization. Recommended = Blood/Tracers/Debris. Maximum FPS = all 6 groups. Original cvar values restore on disable/unload.")
local world_tab = ui.create(app.main_tab, "‐", 1)
app.aspect = world_tab:switch(label_with_icon(
                first_icon({ "expand", "arrows-left-right", "desktop" }),
                "Aspect Ratio"), false)
local aspect_menu = app.aspect:create()
app.aspect_value = aspect_menu:slider("Aspect Value", 0, 200, 100, 0.01)
app.presets =
    aspect_menu:selectable("Presets", { "4:3", "3:2", "16:10", "5:4", "16:9" })
noop(
     app.aspect_value,
     "0 = native screen ratio. Deselect Presets to use the slider.")
noop(
     app.presets,
     "The first selected preset wins. Deselect all for the slider.")
app.crosshair_indicator = world_tab:switch(label_with_icon(
                first_icon({ "crosshairs", "bullseye", "location-crosshairs" }),
                "Crosshair Indicator"), false)
local crosshair_menu = app.crosshair_indicator:create()
app.crosshair_indicator_color =
    crosshair_menu:color_picker("Indicator Color", color(185, 190, 255, 255))
app.crosshair_indicator_shadow = crosshair_menu:switch("Shadow Effect", false)
app.damage_indicator = world_tab:switch(label_with_icon(
                first_icon({ "hundred-points", "crosshairs", "burst" }),
                "Damage Indicator"), false)
local damage_menu = app.damage_indicator:create()
app.damage_indicator_color =
    damage_menu:color_picker("Color", color(255, 255, 255, 255))
app.damage_indicator_font =
    damage_menu:combo("Font", { "Default", "Pixel", "Bold", "Museo Sans" })
pcall(function()
  app.damage_indicator_font:set("Pixel")
end)
noop(
     app.crosshair_indicator,
     "Exscord-style centered indicator adapted for Emberlight. Displays EMBERLIGHT BETA, movement state and active combat features.")
noop(
     app.damage_indicator,
     "Exscord Damage Indicator. Shows current native minimum damage; drag it while the menu is open and right-click it to reset position.")
app.scope_overlay = world_tab:switch(label_with_icon(
                first_icon({ "shuffle", "crosshairs", "expand" }),
                "Scope Overlay"), false)
do
  local m = app.scope_overlay:create()
  app.scope_overlay_options = m:selectable("Options", { "Inverted" })
  app.scope_overlay_length = m:slider("Length", 10, 300, 220)
  app.scope_overlay_gap = m:slider("Gap", 1, 300, 12)
  app.scope_overlay_main =
      m:color_picker("Main Accent", color(255, 255, 255, 255))
  app.scope_overlay_edge = m:color_picker("Edge Accent", color(0, 0, 0, 50))
end
noop(
     app.scope_overlay,
     "Scope Overlay ported 1:1 from Billionars. It removes the native scope lines and draws four animated gradients.")
app.side_indicators = world_tab:switch(label_with_icon(
                first_icon({ "object-intersect", "bars-staggered", "list" }),
                "Side Indicators"), false)
do
  local m = app.side_indicators:create()
  app.side_indicators_items = m:selectable("Indicators", {
    "Double Tap",
    "Min Damage",
    "Hit Chance",
    "Force Body",
    "HideShots",
    "Bomb",
    "Freestanding",
    "Force Safe Points",
    "Fake Duck",
    "Ping Spike",
    "Dormant Aimbot",
  })
  pcall(function()
    app.side_indicators_items:set({
      "Double Tap",
      "Min Damage",
      "Hit Chance",
      "Force Body",
      "HideShots",
      "Bomb",
      "Freestanding",
      "Force Safe Points",
      "Fake Duck",
      "Ping Spike",
      "Dormant Aimbot",
    })
  end)
end
noop(
     app.side_indicators,
     "Gamesense-style side indicators for the Beta build.")
app.kill_particles = world_tab:switch(label_with_icon(
                first_icon({ "sparkles", "star", "wand-magic-sparkles" }),
                "Kill Particles"), false)
local kill_particles_menu = app.kill_particles:create()
app.kill_particle_color =
    kill_particles_menu:color_picker("Color", color(235, 245, 255, 255))
app.kill_particle_amount = kill_particles_menu:slider("Particle Amount", 6, 80, 18, 1)
app.kill_particle_duration = kill_particles_menu:slider("Duration", 1, 4, 2, 0.1)
noop(
     app.kill_particles,
     "Creates round glowing particles over an enemy model after your kill. Ported from PrioraClub and distance-optimized for Neverlose CS:GO.")
app.hit_effect = world_tab:switch(label_with_icon(
                first_icon({ "burst", "sparkles", "wand-magic-sparkles" }),
                "Hit Effect"), false)
local hit_effect_menu = app.hit_effect:create()
app.fortnite_hit = hit_effect_menu:switch("Fortnite Hit", false)
app.effects = hit_effect_menu:switch("Effects", false)
app.effects_mode = hit_effect_menu:combo("Mode", { "CSGO", "CS2" })
pcall(function()
  app.effects_mode:set("CSGO")
end)
noop(
     app.hit_effect,
     "Hit feedback adapted from Fortnite Damage, Spark Impact and ParticleCS2. CSGO uses engine sparks; CS2 uses a rendered particle burst.")
do
  local model_paths = _G.__EMBERLIGHT_MODEL_PATHS
  if type(model_paths) ~= "table" then
    model_paths = {}
    _G.__EMBERLIGHT_MODEL_PATHS = model_paths
  end
  local ffi_ok, scan_ffi = pcall(require, "ffi")
  local scan_ready, kernel32 = false, nil
  local function f1()
    if scan_ready then
      return true
    end
    if not ffi_ok or not scan_ffi then
      return false
    end
    pcall(
        scan_ffi.cdef,
        "      typedef unsigned long ember_DWORD;\n      typedef int ember_BOOL;\n      typedef void* ember_HANDLE;\n      typedef struct { ember_DWORD dwLowDateTime; ember_DWORD dwHighDateTime; } ember_FILETIME;\n      typedef struct _WIN32_FIND_DATAA {\n        ember_DWORD dwFileAttributes;\n        ember_FILETIME ftCreationTime;\n        ember_FILETIME ftLastAccessTime;\n        ember_FILETIME ftLastWriteTime;\n        ember_DWORD nFileSizeHigh;\n        ember_DWORD nFileSizeLow;\n        ember_DWORD dwReserved0;\n        ember_DWORD dwReserved1;\n        char cFileName[260];\n        char cAlternateFileName[14];\n      } ember_WIN32_FIND_DATAA;\n      ember_HANDLE FindFirstFileA(const char*, ember_WIN32_FIND_DATAA*);\n      ember_BOOL FindNextFileA(ember_HANDLE, ember_WIN32_FIND_DATAA*);\n      ember_BOOL FindClose(ember_HANDLE);\n    ")
    local ok, lib = pcall(scan_ffi.load, "kernel32")
    if not ok or not lib then
      return false
    end
    kernel32, scan_ready = lib, true
    return true
  end
  local function f2(path)
    return tostring(path or ""):gsub("/", "\\"):gsub("\\+$", "")
  end
  local function f3(root, out, seen, depth)
    if depth > 16 or #out >= 2048 then
      return
    end
    local data = scan_ffi.new("struct _WIN32_FIND_DATAA[1]")
    local handle = kernel32.FindFirstFileA(root .. "\\*", data)
    local invalid = scan_ffi.cast("void*", -1)
    if handle == nil or handle == invalid then
      return
    end
    repeat
      local name = scan_ffi.string(data[0].cFileName)
      if name ~= "." and name ~= ".." then
        local attrs = tonumber(data[0].dwFileAttributes) or 0
        local is_dir = bit.band(attrs, 16) ~= 0
        local is_reparse = bit.band(attrs, 1024) ~= 0
        local full = root .. "\\" .. name
        if is_dir and not is_reparse then
          f3(full, out, seen, depth + 1)
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
  local function f4()
    local found, seen = {}, {}
    if not f1() then
      return found
    end
    local game_dir = ""
    pcall(function()
      game_dir = f2(common.get_game_directory())
    end)
    local roots = {}
    if game_dir ~= "" then
      roots[#roots + 1] = game_dir .. "\\models\\player\\custom_player"
      roots[#roots + 1] =
          game_dir .. "\\csgo\\models\\player\\custom_player"
    end
    local root_seen = {}
    for _, root in ipairs(roots) do
      local key = root:lower()
      if not root_seen[key] then
        root_seen[key] = true
        f3(root, found, seen, 0)
      end
    end
    table.sort(found, function(a, b)
      return a.name:lower() < b.name:lower()
    end)
    return found
  end
  local function f5(item, options)
    local ok = pcall(function()
      item:update(options)
    end)
    if not ok then
      pcall(function()
        item:update((unpack or table.unpack)(options))
      end)
    end
  end
  local initial = f4()
  for k in pairs(model_paths) do
    model_paths[k] = nil
  end
  local initial_names = {}
  for _, entry in ipairs(initial) do
    initial_names[#initial_names + 1] = entry.name
    model_paths[entry.name] = entry.path
  end
  app.model_changer_available = #initial_names > 0
  local initial_options =
      #initial_names > 0 and initial_names or { "No installed models" }
  app.model_changer = world_tab:switch(label_with_icon(
                first_icon({ "person", "shirt", "user-gear" }),
                "Model Changer"), false)
  local m = app.model_changer:create()
  app.model_changer_team = m:selectable("Team", { "CT", "T" })
  app.model_changer_ct = m:combo("CT Model", initial_options)
  app.model_changer_t = m:combo("T Model", initial_options)
  app.model_changer_status = m:label(#initial_names > 0 and ("Installed models: " .. tostring(#initial_names)) or
    "No custom models found")
  local function f6(notify)
    local old_ct, old_t
    pcall(function()
      old_ct = app.model_changer_ct:get()
      old_t = app.model_changer_t:get()
    end)
    local found = f4()
    for k in pairs(model_paths) do
      model_paths[k] = nil
    end
    local names, exists = {}, {}
    for _, entry in ipairs(found) do
      names[#names + 1] = entry.name
      exists[entry.name] = true
      model_paths[entry.name] = entry.path
    end
    local available = #names > 0
    app.model_changer_available = available
    local options = available and names or { "No installed models" }
    f5(app.model_changer_ct, options)
    f5(app.model_changer_t, options)
    if available then
      pcall(function()
        app.model_changer_ct:set(exists[old_ct] and old_ct or names[1])
      end)
      pcall(function()
        app.model_changer_t:set(exists[old_t] and old_t or names[1])
      end)
    else
      pcall(function()
        app.model_changer:set(false)
      end)
    end
    pcall(function()
      app.model_changer:disabled(not available)
    end)
    pcall(function()
      app.model_changer_status:name(available and ("Installed models: " .. tostring(#names)) or
        "No custom models found")
    end)
    _G.__EMBERLIGHT_MODEL_REFRESH_TOKEN =
        (tonumber(_G.__EMBERLIGHT_MODEL_REFRESH_TOKEN) or 0) + 1
    if notify then
      local msg = available and
        ("Model list refreshed: " .. tostring(#names) .. " found") or "No custom models found"
      pcall(common.add_notify, "Emberlight", msg)
      raw_log("[Emberlight] " .. msg)
    end
  end
  app.model_changer_refresh = m:button("Refresh Models", function()
    f6(true)
  end)
  if #initial_names > 0 then
    pcall(function()
      app.model_changer_ct:set(initial_names[1])
      app.model_changer_t:set(initial_names[1])
    end)
  else
    pcall(function()
      app.model_changer:set(false)
      app.model_changer:disabled(true)
    end)
  end
end
noop(
     app.model_changer,
     "Recursively scans models/player/custom_player. Add .mdl files, then press Refresh Models; no hardcoded model catalog is used.")
app.watermark = v1:switch(label_with_icon(
                first_icon({ "droplet", "stamp", "copyright" }),
                "Watermark"), false)
local watermark_menu = app.watermark:create()
app.wm_style = watermark_menu:combo("Style", { "Gamesense", "Neverlose", "Evalate" })
app.wm_elements = watermark_menu:selectable("Elements", {
  "Logo",
  "FPS",
  "Frametime variance",
  "Ping",
  "Speed",
  "K/D ratio",
  "Clock",
})
app.wm_nl_elements = watermark_menu:selectable("NL Elements", {
  "Avatar",
  "Username",
  "Clock",
  "FPS",
  "Ping",
  "Var",
  "Loss",
  "Build",
  "Blur",
})
app.wm_position =
    watermark_menu:combo("Position", { "Top-right", "Top-left", "Bottom-center" })
app.wm_accent = watermark_menu:color_picker("Accent", color(159, 202, 43, 255))
app.wm_nl_accent = watermark_menu:color_picker("NL Accent", color(185, 190, 255, 255))
app.wm_eval_elements = watermark_menu:selectable(
               "Evalate Elements",
               { "Version", "Username", "Latency", "Frames", "Time" })
app.wm_eval_accent =
    watermark_menu:color_picker("Evalate Accent", color(185, 190, 255, 255))
app.wm_eval_username_source =
    watermark_menu:combo("Evalate Username source", { "Cheat", "Steam", "Custom" })
do
  local ok, ref = pcall(function()
    return watermark_menu:input("Evalate Custom username")
  end)
  app.wm_eval_username_custom = ok and ref or nil
end
app.wm_eval_time_format = watermark_menu:combo("Evalate Time format", { "24h", "12h" })
pcall(function()
  app.wm_eval_elements:set(
                         { "Version", "Username", "Latency", "Frames", "Time" })
end)
pcall(function()
  app.wm_eval_username_source:set("Cheat")
end)
pcall(function()
  app.wm_eval_time_format:set("24h")
end)
noop(
     app.watermark,
     "Watermark styles ported 1:1 from PrioraClub: Gamesense (gradient shadow bar with colored metrics) and Neverlose (rounded pill with avatar, icons, animated blocks, optional blur).")
pcall(function()
  app.wm_elements:set({ "Logo", "FPS", "Frametime variance", "Ping" })
end)
pcall(function()
  app.wm_nl_elements:set(
                       { "Avatar", "Username", "Clock", "FPS", "Ping", "Build" })
end)
local function wm_elements_selected(name)
  local ok, sel = pcall(function()
    return app.wm_eval_elements:get()
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
local t4 = { "Gamesense", "Neverlose", "Evalate" }
local function wm_style()
  local ok, v = pcall(function()
    return app.wm_style:get()
  end)
  if ok then
    if type(v) == "string" then
      return v
    end
    if type(v) == "number" then
      return t4[v] or t4[v + 1] or "Gamesense"
    end
  end
  return "Gamesense"
end
local function wm_accent()
  local ok, c = pcall(function()
    return app.wm_eval_accent:get()
  end)
  if ok and c and finite(c.r) and finite(c.g) and finite(c.b) then
    return c
  end
  return color(185, 190, 255, 255)
end
local function apply_wm_style()
  local style = wm_style()
  local gs_like = style == "Gamesense"
  pcall(function()
    app.wm_elements:visibility(gs_like)
  end)
  pcall(function()
    app.wm_accent:visibility(gs_like)
  end)
  pcall(function()
    app.wm_nl_elements:visibility(style == "Neverlose")
  end)
  pcall(function()
    app.wm_nl_accent:visibility(style == "Neverlose")
  end)
  local ev = style == "Evalate"
  pcall(function()
    app.wm_eval_elements:visibility(ev)
  end)
  pcall(function()
    app.wm_eval_accent:visibility(ev)
  end)
  pcall(function()
    app.wm_eval_username_source:visibility(
                                       ev and wm_elements_selected("Username"))
  end)
  pcall(function()
    app.wm_eval_time_format:visibility(ev and wm_elements_selected("Time"))
  end)
  local custom = false
  pcall(function()
    custom = app.wm_eval_username_source:get() == "Custom"
  end)
  pcall(function()
    if app.wm_eval_username_custom then
      app.wm_eval_username_custom:visibility(
                                       ev and wm_elements_selected("Username") and custom)
    end
  end)
end
pcall(function()
  app.wm_style:set_callback(apply_wm_style)
end)
apply_wm_style()
app.hotkeys = v1:switch(
          label_with_icon(first_icon({ "brackets-curly", "keyboard" }), "HotKeys"),
          false)
noop(app.hotkeys, "Evalate-style hotkey list for the Beta build.")
app.spectators = v1:switch(
          label_with_icon(first_icon({ "users", "eye", "binoculars" }), "Spectators"),
          false)
local spectators_menu = app.spectators:create()
app.specs_header = spectators_menu:switch("Header", false)
noop(
     app.spectators,
     "Spectator list ported 1:1 from PrioraClub: rounded rows, round avatars, accent corner, slide animations. Header toggle moves it to a fixed right-side panel.")
app.notifications = v1:switch(label_with_icon(
                first_icon({ "bell", "message", "circle-info" }),
                "Notification"), false)
local notifications_menu = app.notifications:create()
app.notification_debug = notifications_menu:switch("Debug", false)
app.notification_screen = notifications_menu:switch("Screen", false)
app.notification_console = notifications_menu:switch("Console", false)
noop(
     app.notifications,
     "Emberlight Notification port: screen cards, debug output and console output for shots, deaths and utility damage.")
app.report = main_panel:button("Print Diagnostics", function() end)
app.export_logs = main_panel:button("Export Logs", function()
  local text = yaw_state:build_miss_log_text()
  local clip_ok, clip_err = pcall(function()
    local clipboard = require("neverlose/clipboard")
    assert(
        clipboard and type(clipboard.set) == "function",
        "clipboard module unavailable")
    clipboard.set(text)
  end)
  local written, write_err = {}, nil
  local home = os and os.getenv and (os.getenv("USERPROFILE") or os.getenv("HOME")) or
    nil
  local dir = home and (home .. "\\OneDrive\\Desktop") or nil
  local names = {
    string.char(236, 232, 241, 241, 251) .. ".txt",
    "emberlight_miss_logs.txt",
  }
  if dir then
    for _, name in ipairs(names) do
      local ok_w, err_w = pcall(function()
        local f = assert(io.open(dir .. "\\" .. name, "wb"))
        f:write(text, "\r\n")
        f:close()
      end)
      if ok_w then
        written[#written + 1] = dir .. "\\" .. name
      else
        write_err = write_err or err_w
      end
    end
  end
  if #written > 0 then
    pcall(
        common.add_notify,
        "Emberlight",
        "Miss Logs exported to " .. #written .. " file(s)")
    for _, path in ipairs(written) do
      raw_log("[Emberlight] Export Logs: wrote " ..
        tostring(#yaw_state.miss_log) .. " stored misses -> " .. path)
    end
    if clip_ok then
      raw_log("[Emberlight] Export Logs: also copied to clipboard.")
    end
  elseif clip_ok then
    pcall(
        common.add_notify,
        "Emberlight",
        "All stored Miss Logs copied to clipboard")
    raw_log("[Emberlight] Export Logs: copied " ..
      tostring(#yaw_state.miss_log) .. " stored misses to clipboard (disk write unavailable).")
  else
    log_once("export_logs", "Export Logs failed: " ..
      tostring(clip_err) .. " | disk: " .. tostring(write_err))
  end
end)
noop(
     app.report,
     "Prints saved/overridden/effective values, actual requests, live session state and recharge results. Print while alive, after the problem.")
noop(
     app.export_logs,
     "Writes every stored Miss Log entry to the Desktop as 'миссы.txt' (and emberlight_miss_logs.txt), and copies it to the clipboard as a fallback.")
app.version_state.function_labels = { {
  app.clantag,
  label_with_icon(first_icon({ "tag", "signature" }), "ClanTag"),
  true,
  true,
}, {
  app.trash,
  label_with_icon(first_icon({ "comments", "comment-dots" }), "TrashTalk"),
  true,
  true,
}, { app.unsafe_recharge, label_with_icon(
                first_icon({ "bolt", "battery-bolt", "gauge-high" }),
                "Unsafe Charge"), true, true }, {
  app.forceshot,
  label_with_icon(first_icon({ "crosshairs", "fire", "bolt" }), "ForceShot"),
  true,
  true,
}, { app.crosshair_indicator, label_with_icon(
                first_icon({ "crosshairs", "bullseye", "location-crosshairs" }),
                "Crosshair Indicator"), true, true }, { app.scope_overlay, label_with_icon(
                first_icon({ "shuffle", "crosshairs", "expand" }),
                "Scope Overlay"), true, true }, {
  app.hotkeys,
  label_with_icon(first_icon({ "brackets-curly", "keyboard" }), "HotKeys"),
  false,
  true,
}, { app.side_indicators, label_with_icon(
                first_icon({ "object-intersect", "bars-staggered", "list" }),
                "Side Indicators"), false, true } }
local function load_verified_font(cache, size, flags)
  if cache then
    return cache
  end
  local specs = {
    { "Verdana", size, flags },
    { "Arial", size, flags },
    { "Tahoma", size, flags },
    { "Segoe UI", size, flags },
  }
  for i = 1, #specs do
    local ok_font, font = pcall(render.load_font, specs[i][1], specs[i][2], specs[i][3])
    if ok_font and font then
      local ok_measure = pcall(render.measure_text, font, flags, "test")
      if ok_measure then
        cache = font
        return cache
      end
    end
  end
  return nil
end

local side_indicators_render = (
  function()
  local t1 = { bomb = {
    was_defused = false,
    was_bombed = false,
    defuse_time = 0,
    defuse_start = 0,
    is_defusing = false,
    plant_site = 0,
    plant_time = 3.2,
    plant_start = 0,
    planting = false,
  } }
  local function f1(v_name)
    local v_binds = ui.get_binds() or {}
    for _, v_bind in pairs(v_binds) do
      if v_bind.name == v_name and v_bind.active then
        return true, v_bind.value
      end
    end
    return false, nil
  end
  local function f2(v_bomb)
    if not v_bomb then
      return 0
    end
    local v_time = v_bomb.m_flC4Blow - globals.curtime
    return v_time and math.max(v_time, 0) or 0
  end
  local function f3(v_site)
    local v_resource = entity.get_player_resource()
    if not v_resource then
      return "?"
    end
    local v_a = v_resource.m_bombsiteCenterA
    local v_b = v_resource.m_bombsiteCenterB
    local v_ent = entity.get(v_site, false)
    if not v_ent or not v_a or not v_b then
      return "?"
    end
    local v_center = (v_ent.m_vecMins + v_ent.m_vecMaxs) / 2
    return v_a:dist(v_center) < v_b:dist(v_center) and "A" or "B"
  end
  local function f4(v_player, v_bomb)
    if not v_player or not v_bomb then
      return nil
    end
    local v_distance = v_player:get_origin():dist(v_bomb:get_origin())
    local v_armor = v_player.m_ArmorValue or 0
    local v_value = (v_distance - 75.68) / 789.2
    local v_damage = 450.7 * math.exp(-v_value * v_value)
    if v_armor > 0 then
      local v_new = v_damage * 0.5
      if v_armor < (v_damage - v_new) * 0.5 then
        v_new = v_damage - v_armor * 2
      end
      v_damage = v_new
    end
    return v_damage
  end
  local block_font
  local function resolve_block_font()
    if block_font then
      return block_font
    end
    local specs = {
      { "Calibri Bold", vector(24.3, 23.5, 0) },
      { "Verdana", 24 },
      { "Arial", 24 },
      { "Tahoma", 24 },
      { "Calibri", 24 },
    }
    for i = 1, #specs do
      local ok_font, font = pcall(render.load_font, specs[i][1], specs[i][2], "da")
      if ok_font and font then
        local ok_measure = pcall(render.measure_text, font, "da", "test")
        if ok_measure then
          block_font = font
          return block_font
        end
      end
    end
    return nil
  end
  resolve_block_font()
  local function f5(v_rows)
    local v_screen = render.screen_size()
    local v_yoff = 0
    for _, v_row in ipairs(v_rows) do
      if v_row.show then
        local v_font = resolve_block_font()
        local v_size = { x = 0 }
        if v_font then
          local ok_measure, measured = pcall(render.measure_text, v_font, "da", v_row.text)
          if ok_measure and type(measured) == "table" and finite(measured.x) then
            v_size = measured
          end
        end
        local v_y =
            v_screen.y * 0.5 + (v_screen.y * 0.5 * 0.43 - 1) + v_yoff
        local v_left = 31 + v_size.x * 0.5
        pcall(render.gradient, vector(0, v_y), vector(v_left, v_y + 33),
              color(0, 0, 0, 0), color(12, 12, 12, 35),
              color(0, 0, 0, 0), color(12, 12, 12, 35))
        pcall(render.gradient, vector(v_left, v_y),
              vector(v_left + 29 + v_size.x * 0.5, v_y + 33),
              color(12, 12, 12, 35), color(0, 0, 0, 0),
              color(12, 12, 12, 35), color(0, 0, 0, 0))
        if v_font then
          pcall(render.text, v_font, vector(29, v_y + 7),
                color(v_row.r or 230, v_row.g or 230, v_row.b or 230, 235),
                nil, v_row.text)
        end
        if v_row.progress then
          local v_x = 29 + v_size.x + 15
          local v_py = v_screen.y * 0.0125
          pcall(render.circle_outline, vector(v_x, v_y + v_py),
                color(10, 10, 10, 230), 10, 0, 1, 5)
          pcall(render.circle_outline, vector(v_x, v_y + v_py),
                color(205, 205, 205, 255), 9, 0, 1 - v_row.progress, 3)
        end
        v_yoff = v_yoff - 41
      end
    end
  end
  local function f6(name)
    local listed = {}
    pcall(function()
      local list = app.side_indicators_items:get()
      if type(list) == "table" then
        listed = list
      end
    end)
    for _, v in ipairs(listed) do
      if v == name then
        return true
      end
    end
    local ok, value = pcall(function()
      return app.side_indicators_items:get(name)
    end)
    if ok and type(value) == "boolean" then
      return value
    end
    return false
  end
  local function f7(...)
    local aliases = { ... }
    local binds = {}
    pcall(function()
      binds = ui.get_binds() or {}
    end)
    for _, bind in pairs(binds) do
      local name = app.version_state.clean_bind_name(bind.name):lower()
      for _, alias in ipairs(aliases) do
        if not name:find(tostring(alias):lower(), 1, true) then
          break
        end
        if name:find("disable", 1, true) or name:find("hold", 1, true) or
          name:find("toggle", 1, true) then
          return bind.active ~= true, bind.value
        end
        if bind.active or bind.value then
          return true, bind.value
        end
        break
      end
    end
    return false, nil
  end
  local function f8(rows, text, show, r, g, b, progress, value)
    rows[#rows + 1] = {
      text = text,
      show = show == true,
      r = r,
      g = g,
      b = b,
      progress = progress,
      value = value,
    }
  end
  local function f9(player)
    local rows = {}
    local dt = nil
    pcall(function()
      if rawget(_G, "__EMBERLIGHT_DT") then
        dt = rawget(_G, "__EMBERLIGHT_DT")()
      end
    end)
    if dt == nil then
      dt = f7("double tap")
    end
    local hs = f7("hide shots", "on shot anti-aim")
    local fd = f7("fake duck")
    if f6("Double Tap") then
      local ready = false
      pcall(function()
        ready = rage.exploit:get() == 1
      end)
      f8(
          rows,
          "DT",
          dt and not fd,
          ready and 200 or 255,
          ready and 207 or 0,
          ready and 200 or 50)
    end
    if f6("HideShots") then
      f8(rows, "OSAA", hs and not dt and not fd)
    end
    if f6("Fake Duck") then
      f8(rows, "DUCK", fd)
    end
    if f6("Dormant Aimbot") then
      f8(rows, "DA", f7("dormant aimbot"))
    end
    if f6("Force Safe Points") then
      f8(rows, "SAFE", f7("safe point"))
    end
    if f6("Force Body") then
      f8(rows, "BODY", f7("body aim"))
    end
    if f6("Min Damage") then
      local active, value =
          f7("min. damage", "min damage", "damage override")
      f8(rows, "MD", active, nil, nil, nil, nil, value)
    end
    if f6("Hit Chance") then
      f8(rows, "HITCHANCE", f7("hit chance", "hitchance"))
    end
    if f6("Freestanding") then
      f8(rows, "FS", f7("freestanding", "freestand"))
    end
    if f6("Ping Spike") then
      local active, value = f7("ping spike", "fake latency")
      local n = tonumber(value) or 0
      local r, g, b = 230, 230, 230
      if n >= 1 and n <= 100 then
        r, g, b = 189, 199, 118
      elseif n > 100 then
        r, g, b = 169, 203, 82
      end
      f8(rows, "PING", active, r, g, b)
    end
    if f6("Bomb") then
      local b = t1.bomb
      if b.planting then
        local elapsed = (tonumber(globals.curtime) or 0) - b.plant_start
        f8(
            rows,
            f3(b.plant_site),
            true,
            255,
            255,
            120,
            math.max(0, 1 - elapsed / b.plant_time))
      end
      local bombs = {}
      pcall(function()
        bombs = entity.get_entities("CPlantedC4", true) or {}
      end)
      local ent = bombs[1]
      if ent and not ent.m_bBombDefused and f2(ent) > 0 and not b.was_bombed then
        local site = ent.m_nBombSite == 0 and "A" or
          (ent.m_nBombSite == 1 and "B" or "?")
        local timer = string.format("%.1f", f2(ent)) .. "s"
        local pct = nil
        if b.is_defusing and b.defuse_time > 0 then
          pct = math.max(0, 1 - ((tonumber(globals.curtime) or 0) - b.defuse_start) /
            b.defuse_time)
        end
        f8(
            rows,
            site .. " - " .. timer,
            true,
            b.is_defusing and 195 or 210,
            b.is_defusing and 205 or 210,
            b.is_defusing and 75 or 210,
            pct)
        local damage = f4(player, ent)
        if damage and math.floor(damage) > 0 then
          local d = math.floor(damage)
          f8(
              rows,
              player.m_iHealth <= d and "FATAL" or ("-" .. d .. " HP"),
              true,
              255,
              player.m_iHealth <= d and 0 or 245,
              player.m_iHealth <= d and 0 or 104)
        end
      end
    end
    return rows
  end
  local function f10()
    local b = t1.bomb
    b.was_defused = false
    b.was_bombed = false
    b.defuse_time = 0
    b.defuse_start = 0
    b.is_defusing = false
    b.plant_site = 0
    b.plant_time = 3.2
    b.plant_start = 0
    b.planting = false
  end
  on_event("bomb_beginplant", function(e)
    local b = t1.bomb
    b.planting = true
    b.plant_start = globals.curtime
    b.plant_site = e.site
  end)
  on_event("bomb_abortplant", function()
    t1.bomb.planting = false
  end)
  on_event("bomb_planted", function()
    t1.bomb.planting = false
  end)
  on_event("bomb_begindefuse", function(e)
    local b = t1.bomb
    if not b.is_defusing then
      b.defuse_start = globals.curtime
    end
    b.is_defusing = true
    b.defuse_time = e.haskit and 5 or 10
  end)
  on_event("bomb_abortdefuse", function()
    t1.bomb.is_defusing = false
  end)
  on_event("bomb_defused", function()
    local b = t1.bomb
    b.is_defusing = false
    b.was_defused = true
  end)
  on_event("bomb_exploded", function()
    t1.bomb.was_bombed = true
  end)
  on_event("round_start", f10)
  on_event("round_prestart", f10)
  on_event("disconnect", f10)
  return function()
    if not item_enabled(app.side_indicators) then
      return
    end
    local player = entity.get_local_player()
    if not player or not player:is_alive() then
      return
    end
    local rows = f9(player)
    f5(rows)
  end
end
)()
local function set_visible(ref, state)
  if ref then
    pcall(function()
      ref:visibility(state == true)
    end)
  end
end
local function native_cleanup()
  pcall(app.version_state.sanitize_live_binds)
  local resolver_on = item_enabled(app.resolver)
  local resolver_options = resolver_on
  local assist_available = resolver_options
  local assist_on = assist_available and item_enabled(app.assist)
  if assist_on and item_enabled(app.yaw) then
    pcall(function()
      app.yaw:set(false)
    end)
  end
  local yaw_on =
      resolver_options and not assist_on and item_enabled(app.yaw)
  set_visible(app.assist, assist_available)
  set_visible(app.yaw, resolver_options)
  set_visible(app.yaw_mode, resolver_options)
  pcall(function()
    app.yaw:disabled(not resolver_options or assist_on)
  end)
  pcall(function()
    app.yaw_mode:disabled(not yaw_on or assist_on)
  end)
  local extrap_on = item_enabled(app.extrapolation)
  pcall(function()
    app.interpolation:set(true)
    app.interpolation:visibility(false)
  end)
  for _, ref in ipairs({
    app.extrapolation_ticks,
    app.extrapolation_auto,
    app.extrapolation_fake_latency,
    app.extrapolation_rewrite,
  }) do
    set_visible(ref, extrap_on)
  end
  local unsafe_on = item_enabled(app.unsafe_recharge)
  local force_on = item_enabled(app.forceshot)
  set_visible(app.unsafe_mode, unsafe_on)
  set_visible(app.forceshot_mode, force_on)
  pcall(function()
    if app.yaw_mode then
      set_visible(app.yaw_mode, true)
    end
    if app.extrapolation_mode then
      set_visible(app.extrapolation_mode, extrap_on)
    end
  end)
  set_visible(app.opt_preset, item_enabled(app.fps_optimizer))
  set_visible(app.opt_list, item_enabled(app.fps_optimizer))
  local model_available = app.model_changer_available == true
  local model_on = model_available and item_enabled(app.model_changer)
  set_visible(app.model_changer_team, model_on)
  set_visible(app.model_changer_status, true)
  set_visible(app.model_changer_refresh, true)
  local model_teams = {}
  pcall(function()
    model_teams = app.model_changer_team:get() or {}
  end)
  local model_ct, model_t = false, false
  for _, team in ipairs(model_teams) do
    if team == "CT" then
      model_ct = true
    elseif team == "T" then
      model_t = true
    end
  end
  set_visible(app.model_changer_ct, model_on and model_ct)
  set_visible(app.model_changer_t, model_on and model_t)
  local movement_on = item_enabled(app.movement)
  for _, v in ipairs({ app.fast_ladder, app.no_fall_damage, app.avoid_collision }) do
    set_visible(v, movement_on)
  end
  local aspect_on = item_enabled(app.aspect)
  set_visible(app.aspect_value, aspect_on)
  set_visible(app.presets, aspect_on)
  local indicator_on = item_enabled(app.crosshair_indicator)
  set_visible(app.crosshair_indicator_color, indicator_on)
  set_visible(app.crosshair_indicator_shadow, indicator_on)
  set_visible(app.damage_indicator, indicator_on)
  local damage_on = indicator_on and item_enabled(app.damage_indicator)
  set_visible(app.damage_indicator_color, damage_on)
  set_visible(app.damage_indicator_font, damage_on)
  pcall(function()
    app.side_indicators:visibility(true)
  end)
  local side_on = item_enabled(app.side_indicators)
  set_visible(app.side_indicators_items, side_on)
  local particles_on = item_enabled(app.kill_particles)
  for _, v in ipairs({
    app.kill_particle_color,
    app.kill_particle_amount,
    app.kill_particle_duration,
  }) do
    set_visible(v, particles_on)
  end
  local hit_on = item_enabled(app.hit_effect)
  set_visible(app.fortnite_hit, hit_on)
  set_visible(app.effects, hit_on)
  set_visible(app.effects_mode, hit_on and item_enabled(app.effects))
  local watermark_on = item_enabled(app.watermark)
  set_visible(app.wm_style, watermark_on)
  set_visible(app.wm_position, watermark_on)
  local style = wm_style()
  set_visible(app.wm_elements, watermark_on and style == "Gamesense")
  set_visible(app.wm_accent, watermark_on and style == "Gamesense")
  set_visible(app.wm_nl_elements, watermark_on and style == "Neverlose")
  set_visible(app.wm_nl_accent, watermark_on and style == "Neverlose")
  local ev = watermark_on and style == "Evalate"
  set_visible(app.wm_eval_elements, ev)
  set_visible(app.wm_eval_accent, ev)
  set_visible(
            app.wm_eval_username_source,
            ev and wm_elements_selected("Username"))
  set_visible(app.wm_eval_time_format, ev and wm_elements_selected("Time"))
  local custom = false
  pcall(function()
    custom = app.wm_eval_username_source:get() == "Custom"
  end)
  set_visible(
            app.wm_eval_username_custom,
            ev and wm_elements_selected("Username") and custom)
  set_visible(app.specs_header, item_enabled(app.spectators))
  local notify_on = item_enabled(app.notifications)
  for _, v in ipairs({
    app.notification_debug,
    app.notification_screen,
    app.notification_console,
  }) do
    set_visible(v, notify_on)
  end
  local trash_on = item_enabled(app.trash)
  set_visible(app.trash_mode, trash_on)
  set_visible(app.trash_trigger, trash_on)
end
native_cleanup()
pcall(function()
  app.version_state.apply_ui()
end)
set_menu_section = function()
  local ok, active = pcall(function()
    return app.section:get()
  end)
  active = ok and active or 1
  local workspace_ok, workspace = pcall(function()
    return app.workspace:get()
  end)
  workspace = workspace_ok and workspace or 1
  local workspace_text = tostring(workspace or "")
  local show_home = workspace == 1 or workspace == "Home" or
    workspace == app.workspace_items[1] or workspace_text:find("Home", 1, true) ~= nil
  local show_configs = workspace == 2 or workspace == "Configs" or
    workspace == app.workspace_items[2] or workspace_text:find("Configs", 1, true) ~= nil
  if not show_home and not show_configs then
    show_home = true
  end
  local information_selected =
      active == 1 or active == "Information" or active == section_items[1]
  local show_info = show_home and information_selected
  local show_funcs = show_home and
    (active == 2 or active == "Functions" or active == section_items[2])
  if show_home and not show_info and not show_funcs then
    show_info = true
    information_selected = true
  end
  pcall(function()
    app.section:visibility(not show_configs)
  end)
  pcall(function()
    app.workspace:visibility(
                         show_configs or (show_home and information_selected))
  end)
  for _, item in ipairs({ app.report, app.export_logs }) do
    pcall(function()
      item:visibility(show_info)
    end)
  end
  pcall(function()
    app.config_panel:visibility(true)
  end)
  app.config_system.page_visible = show_configs == true
  for _, item in ipairs({
    app.config_list,
    app.config_name,
    app.config_create,
    app.config_load,
    app.config_save,
    app.config_import,
    app.config_export,
    app.config_delete,
  }) do
    pcall(function()
      item:visibility(app.config_system.page_visible)
    end)
  end
  for _, item in ipairs({ info_tab, about_tab }) do
    pcall(function()
      item:visibility(show_info)
    end)
  end
  for _, item in ipairs({ v1, v2, world_tab, visuals_tab }) do
    pcall(function()
      item:visibility(show_funcs)
    end)
  end
end
pcall(function()
  app.section:set_callback(set_menu_section, true)
end)
pcall(function()
  app.workspace:set_callback(function()
    set_menu_section()
    pcall(function()
      utils.execute_after(0, function()
        pcall(set_menu_section)
      end)
    end)
  end, true)
end)
set_menu_section()
app.version_state.force_beta_startup = function()
  if app.version_state.boot_forcing then
    return
  end
  app.version_state.boot_forcing = true
  local white_sections = {
    icon_label({ "circle-info", "info-circle", "info" }, "Information"),
    icon_label({ "sliders", "gears", "gear", "function" }, "Functions"),
  }
  local white_workspace = {
    icon_label({ "house", "home" }, "Home"),
    icon_label({ "folder-gear", "folder", "floppy-disk", "gear" }, "Configs"),
  }
  section_items = white_sections
  app.workspace_items = white_workspace
  pcall(function()
    app.section:update(white_sections)
    app.section:set(1)
  end)
  pcall(function()
    app.workspace:update(white_workspace)
    app.workspace:set(1)
  end)
  pcall(function()
    app.version_build_info:name(menu_icon .. " Beta " .. menu_note)
    app.version_user_info:name(
                           menu_icon .. " " .. strip_colours(get_username()) .. " " .. menu_note)
    app.version_updated_info:name(menu_icon ..
      " " .. strip_colours(app.version_state.beta_updated) .. " " .. menu_note)
    about_copy:name(menu_icon .. " PWNZ " .. menu_note)
    for _, social in ipairs(app.version_social_buttons or {}) do
      social[1]:name(menu_icon .. " " .. social[2] .. " " .. menu_note)
    end
  end)
  app.version_state.intro_active = false
  app.version_state.boot_forcing = false
  pcall(set_menu_section)
end
app.version_state.force_beta_startup()
app.scope_runtime = { master = 0, scoped = 0, native = nil }
pcall(function()
  app.scope_runtime.native =
      ui.find("Visuals", "World", "Main", "Override Zoom", "Scope Overlay")
end)
app.scope_overlay_tick = function()
  local me = entity.get_local_player()
  local alive = false
  pcall(function()
    alive = me ~= nil and me:is_alive()
  end)
  local v1 = alive and item_enabled(app.scope_overlay)
  local scoped = false
  pcall(function()
    scoped = me.m_bIsScoped == true
  end)
  local dt =
      math.min(1, math.max(0.001, tonumber(globals.frametime) or 0.016) * 20)
  app.scope_runtime.master = app.scope_runtime.master +
    ((v1 and 1 or 0) - app.scope_runtime.master) * dt
  app.scope_runtime.scoped = app.scope_runtime.scoped +
    ((v1 and scoped and 1 or 0) - app.scope_runtime.scoped) * dt
  if app.scope_runtime.master <= 0.002 then
    pcall(function()
      if app.scope_runtime.native then
        app.scope_runtime.native:override()
      end
    end)
    return
  end
  pcall(function()
    if app.scope_runtime.native then
      app.scope_runtime.native:override("Remove All")
    end
  end)
  local a = app.scope_runtime.master * app.scope_runtime.scoped
  if a <= 0.002 then
    return
  end
  local screen = render.screen_size()
  local center = screen * 0.5
  local gap = math.floor(app.scope_overlay_gap:get())
  local length = math.floor(app.scope_overlay_length:get())
  local diff = length - gap
  local main, edge =
      app.scope_overlay_main:get(),
      app.scope_overlay_edge:get()
  local inverted = false
  pcall(function()
    inverted = app.scope_overlay_options:get("Inverted") or
      app.scope_overlay_options:get(1)
  end)
  if inverted then
    main, edge = edge, main
  end
  main = color(main.r, main.g, main.b, math.floor(main.a * a))
  edge = color(edge.r, edge.g, edge.b, math.floor(edge.a * a))
  render.gradient(
                vector(center.x, center.y - gap + 1),
                vector(center.x + 1, center.y - length * a),
                main,
                main,
                edge,
                edge)
  render.gradient(
                vector(center.x, center.y + gap),
                vector(center.x + 1, center.y + length * a),
                main,
                main,
                edge,
                edge)
  render.gradient(
                vector(center.x - gap + 1, center.y),
                vector(center.x - gap + 1 - diff * a, center.y + 1),
                main,
                edge,
                main,
                edge)
  render.gradient(
                vector(center.x + gap, center.y),
                vector(center.x + gap + diff * a + 1, center.y + 1),
                main,
                edge,
                main,
                edge)
end
pcall(function()
  events.render(function()
    pcall(app.scope_overlay_tick)
  end)
end)
native_api = { slots = {}, master = nil }
local scope_overlay_modes = { Off = 0, Disabled = 0, Prefer = 1, Force = 2 }
local scope_overlay_config = {
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
native_api.find = function(self, path)
  local unpack_values = unpack or table.unpack
  local ok, ref = pcall(function()
    return ui.find(unpack_values(path))
  end)
  if not ok or not ref then
    return nil
  end
  local readable = pcall(function()
    ref:get()
    ref:get_override()
  end)
  return readable and ref or nil
end
native_api.read = function(self, ref)
  if not ref then
    return false
  end
  local ok, base, forced = pcall(function()
    return ref:get(), ref:get_override()
  end)
  if not ok then
    return false
  end
  return true, base, forced
end
native_api.effective = function(self, ref)
  local ok, base, forced = self:read(ref)
  if not ok then
    return nil
  end
  if forced ~= nil then
    return forced
  end
  return base
end
native_api.master_enabled = function(self)
  return self:effective(self.master) == true
end
native_api.bind_safe = function(self)
  for _, p in ipairs(scope_overlay_config) do
    local ref = self:find(p)
    if ref then
      local readable = self:read(ref)
      local ok, options = pcall(function()
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
      if readable and prefer and scope_overlay_modes[self:effective(ref)] ~= nil then
        return ref, p
      end
    end
  end
  return nil
end
native_api.EXTRAPOLATION_PATHS = {
  { "Aimbot", "Ragebot", "Extrapolation" },
  { "Aimbot", "Ragebot", "Main", "Extrapolation" },
  { "Aimbot", "Ragebot", "Selection", "Extrapolation" },
  { "Aimbot", "Ragebot", "Accuracy", "Extrapolation" },
  { "Aimbot", "Ragebot", "Safety", "Extrapolation" },
  { "Aimbot", "Ragebot", "Extrapolation", "Enabled" },
  { "Aimbot", "Ragebot", "Main", "Extrapolation", "Enabled" },
}
native_api.bind_extrapolation = function(self)
  for _, p in ipairs(native_api.EXTRAPOLATION_PATHS) do
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
native_api.fake_latency_ticks = function(self)
  local ref = self.fake_latency_ref
  if not ref then
    return 0
  end
  local ok, base = self:read(ref)
  if not ok then
    return 0
  end
  local ms = tonumber(base)
  if not ms or ms <= 0 then
    return 0
  end
  return math.floor((ms + 7.5) / 15)
end
native_api.drive_extrapolation = function(self, t)
  local v1 = item_enabled(app.extrapolation)
  if not v1 then
    if self.slots.extrap then
      self:request("extrap", nil)
    end
    return
  end
  local ticks = nil
  local auto = item_enabled(app.extrapolation_auto)
  do
    if auto then
      local now = t or game_time()
      if not self.extrap_auto_at or now - self.extrap_auto_at >= 1 then
        self.extrap_auto_at = now
        local ping_ms = 0
        local ok, lat = pcall(function()
          return net.avg_latency and net.avg_latency[0]
        end)
        if ok and finite(lat) then
          ping_ms = lat * 1000
        end
        local fl = item_enabled(app.extrapolation_fake_latency) and
          self:fake_latency_ticks() or 0
        ticks =
            math.max(0, math.min(15, math.floor((ping_ms + fl * 15) / 15)))
        pcall(function()
          app.extrapolation_ticks:set(ticks)
        end)
      end
    else
      ticks = tonumber(app.extrapolation_ticks:get())
    end
  end
  if not ticks or ticks < 0 or ticks > 15 then
    ticks = 0
  end
  if not self.slots.extrap.ref then
    return
  end
  if ticks <= 0 then
    self:request("extrap", nil)
    return
  end
  local ok, range = pcall(function()
    local minv, maxv = self.slots.extrap.ref:range()
    return minv, maxv
  end)
  if ok and finite(range) and range > 0 then
    ticks = math.max(0, math.min(range, ticks))
  end
  self:request("extrap", ticks)
end
native_api.init = function(self)
  self.master = self:find({ "Aimbot", "Ragebot", "Main", "Enabled" })
  if type(self:effective(self.master)) ~= "boolean" then
    self.master = nil
  end
  local safe, safe_path = self:bind_safe()
  local dormant =
      self:find({ "Aimbot", "Ragebot", "Main", "Enabled", "Dormant Aimbot" })
  if type(self:effective(dormant)) ~= "boolean" then
    dormant = nil
  end
  local extrap = self:bind_extrapolation()
  local fake_latency =
      self:find({ "Miscellaneous", "Main", "Other", "Fake Latency" })
  self.slots.safe = {
    ref = safe,
    kind = "safe",
    owned = false,
    yielded = false,
    applied = 0,
    released = 0,
    conflicts = 0,
    state = "idle",
  }
  self.slots.dormant = {
    ref = dormant,
    kind = "dormant",
    owned = false,
    yielded = false,
    applied = 0,
    released = 0,
    conflicts = 0,
    state = "idle",
  }
  self.slots.extrap = {
    ref = extrap,
    kind = "extrap",
    owned = false,
    yielded = false,
    applied = 0,
    released = 0,
    conflicts = 0,
    state = "idle",
  }
  self.fake_latency_ref = fake_latency
  if not self.master then
    log_once(
         "native_master",
         "Native Ragebot Enabled is unavailable; no combat overrides will be issued.")
  end
  if not dormant then
    log_once(
         "native_dormant",
         "Native Dormant Aimbot unavailable. No custom dormant shots will be substituted.")
  end
end
native_api.retry_bind = function(self)
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
        state = "idle",
      }
    end
  end
  if self.slots.dormant and not self.slots.dormant.ref then
    local dormant =
        self:find({ "Aimbot", "Ragebot", "Main", "Enabled", "Dormant Aimbot" })
    if dormant and type(self:effective(dormant)) == "boolean" then
      self.slots.dormant = {
        ref = dormant,
        kind = "dormant",
        owned = false,
        yielded = false,
        applied = 0,
        released = 0,
        conflicts = 0,
        state = "idle",
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
        state = "idle",
      }
    end
  end
  if not self.fake_latency_ref then
    self.fake_latency_ref =
        self:find({ "Miscellaneous", "Main", "Other", "Fake Latency" })
  end
end
native_api.conflict = function(self, s, reason)
  if not s.yielded then
    s.conflicts = s.conflicts + 1
  end
  s.yielded, s.state = true, reason
  log_once("native_conflict_" .. s.kind, reason ..
    ". Emberlight yielded; check other scripts and then toggle the feature OFF/ON.")
end
native_api.release = function(self, key)
  local s = self.slots[key]
  if not s or not s.owned then
    return true
  end
  local ok, base, current = self:read(s.ref)
  if not ok then
    s.release_failed = true
    s.state = "release read failed; check native menu"
    log_once("release_read_" .. key, s.state)
    return false
  end
  if current ~= s.written then
    s.owned, s.counted = false, false
    s.release_failed = false
    self:conflict(s, "native " .. key .. " changed externally")
    return true
  end
  if s.retry_at and game_time() < s.retry_at then
    return false
  end
  s.retry_at = game_time() + 0.5
  local released = pcall(function()
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
  log_once("release_failed_" .. key, s.state)
  return false
end
native_api.release_all = function(self)
  local safe_ok = self:release("safe")
  local dormant_ok = self:release("dormant")
  local extrap_ok = self:release("extrap")
  return safe_ok and dormant_ok and extrap_ok
end
native_api.reset = function(self, key)
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
native_api.satisfied = function(self, s, base, desired)
  if s.kind == "dormant" then
    return base == desired
  end
  if s.kind == "extrap" then
    return
        type(base) == "number" and type(desired) == "number" and base == desired
  end
  local actual, wanted = scope_overlay_modes[base], scope_overlay_modes[desired]
  return actual ~= nil and wanted ~= nil and actual >= wanted
end
native_api.request = function(self, key, desired)
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
    local base_changed =
        base ~= s.base and (not s.get_is_effective or base ~= s.written)
    if base_changed then
      local released = self:release(key)
      if released then
        self:conflict(s, "native " .. key .. " config changed while active")
      end
      return s.state
    end
    if current == desired then
      s.state = "Emberlight override verified"
      return s.state
    end
    if not self:release(key) then
      return s.state
    end
    ok, base, current = self:read(s.ref)
    if not ok then
      s.state = "native read failed"
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
  if (s.kind == "safe" and scope_overlay_modes[base] == nil) or
    (s.kind == "dormant" and type(base) ~= "boolean") or (s.kind == "extrap" and type(base) ~= "number") then
    s.state = "unknown native value; unchanged"
    return s.state
  end
  s.base, s.written, s.counted = base, desired, false
  s.owned = true
  local changed = pcall(function()
    s.ref:override(desired)
  end)
  local verified, after_base, after = self:read(s.ref)
  if changed and verified and after == desired then
    s.applied, s.counted = s.applied + 1, true
    s.get_is_effective = after_base == desired and base ~= desired
    s.state = "Emberlight override verified"
    return s.state
  end
  if verified and after ~= desired then
    s.owned = false
  end
  self:conflict(s, "native " .. key .. " assignment not verified")
  self:release(key)
  return s.state
end
native_api.fire_state = function(self)
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
native_api:init()
pcall(function()
  native_api:request("dormant", nil)
end)
local aspect_presets = {
  suspended = false,
  fault = nil,
  shots = 0,
  scan_at = -1,
  counts = { 0, 0, 0, 0, 0, 0 },
  in_game = false,
  alive = false,
  shot_hook = false,
}
aspect_presets.sync = function(self)
  pcall(function()
    native_api:request("dormant", nil)
  end)
end
aspect_presets.scan = function(self)
  self.scan_at = game_time()
  self.counts = { 0, 0, 0, 0, 0, 0 }
  self.in_game = globals and globals.is_in_game == true or false
  self.alive = false
end
aspect_presets.fire = function(self, event) end
aspect_presets.guard = function(self, method, ...)
  local ok, err = pcall(method, self, ...)
  if not ok then
    self.fault = "Dormant stub error"
  end
end
local aspect_bind_meta = {
  ["4:3"] = 1.3333333333333333,
  ["3:2"] = 1.5,
  ["16:10"] = 1.6,
  ["5:4"] = 1.25,
  ["16:9"] = 1.7777777777777777,
}
local aspect_preset_order = { "4:3", "3:2", "16:10", "5:4", "16:9" }
local n1 = 9
local pixel_item
local pixel_state = {
  saved = nil,
  current = nil,
  last_write = nil,
  time = nil,
  yielded = false,
}
local function resolve_pixel_item()
  if pixel_item then
    return pixel_item
  end
  pcall(function()
    pixel_item = cvar.r_aspectratio
  end)
  if not pixel_item then
    pcall(function()
      pixel_item = cvar.find and cvar.find("r_aspectratio")
    end)
  end
  return pixel_item
end
resolve_pixel_item()
local function screen_ratio()
  local ok, ratio = pcall(function()
    local size = render.screen_size()
    if finite(size.x) and finite(size.y) and size.x > 0 and size.y > 0 then
      return size.x / size.y
    end
  end)
  return ok and finite(ratio) or nil
end
local function current_preset()
  local ok, selected = pcall(function()
    return app.presets:get()
  end)
  if ok then
    if type(selected) == "string" and aspect_bind_meta[selected] then
      return aspect_bind_meta[selected]
    end
    if type(selected) == "table" then
      for i = 1, #aspect_preset_order do
        for _, value in ipairs(selected) do
          if value == aspect_preset_order[i] then
            return aspect_bind_meta[aspect_preset_order[i]]
          end
        end
        if selected[aspect_preset_order[i]] == true then
          return aspect_bind_meta[aspect_preset_order[i]]
        end
      end
    end
  end
  local valid, raw = pcall(function()
    return app.aspect_value:get()
  end)
  return valid and finite(raw) and clamp(raw, 0, 200) * 0.01 or 0
end
local function reset_pixel()
  pixel_state.saved, pixel_state.current, pixel_state.last_write =
      nil,
      nil,
      nil
end
local function get_pixel()
  local item = resolve_pixel_item()
  if not item then
    return nil
  end
  local ok, value = pcall(function()
    return item:float()
  end)
  if not (ok and finite(value)) then
    pixel_item = nil
    return nil
  end
  return value
end
local function set_pixel(value)
  local item = resolve_pixel_item()
  if not item then
    log_once(
           "aspect_write",
           "Aspect Ratio could not be applied. Check cvar access and other aspect scripts.")
    return false
  end
  local ok = pcall(function()
    item:float(value)
  end)
  if ok then
    pixel_state.last_write = value
    return true
  end
  log_once(
         "aspect_write",
         "Aspect Ratio could not be applied. Check cvar access and other aspect scripts.")
  return false
end
local function sync_pixel()
  if pixel_state.saved == nil or pixel_state.last_write == nil then
    reset_pixel()
    return
  end
  local actual = get_pixel()
  if actual and math.abs(actual - pixel_state.last_write) < 0.0001 then
    set_pixel(pixel_state.saved)
  end
  reset_pixel()
end
local function tick_pixel()
  local t = game_time()
  local dt = pixel_state.time and clamp(t - pixel_state.time, 0, 0.1) or 0
  pixel_state.time = t
  local v1 = item_enabled(app.aspect)
  if not v1 then
    pixel_state.yielded = false
  end
  if not resolve_pixel_item() or pixel_state.yielded then
    return
  end
  if not v1 and pixel_state.saved == nil then
    return
  end
  local actual = get_pixel()
  if actual == nil then
    log_once(
         "aspect_read",
         "Cannot read r_aspectratio. No value was forced.")
    return
  end
  if pixel_state.last_write ~= nil and
    math.abs(actual - pixel_state.last_write) > 0.0001 then
    reset_pixel()
    pixel_state.yielded = true
    log_once(
         "aspect_conflict",
         "Aspect Ratio changed externally; Emberlight yielded. Toggle it OFF/ON to retry.")
    return
  end
  local native = screen_ratio()
  if not native then
    return
  end
  if pixel_state.saved == nil then
    pixel_state.saved = actual
    pixel_state.current = actual > 0 and actual or native
  end
  local raw_target = v1 and current_preset() or pixel_state.saved
  local target = raw_target > 0 and raw_target or native
  pixel_state.current = pixel_state.current +
    (target - pixel_state.current) * (1 - math.exp(-n1 * dt))
  local settled = math.abs(pixel_state.current - target) < 0.0005
  local output = settled and raw_target or pixel_state.current
  if pixel_state.last_write == nil or math.abs(actual - output) > 1e-05 then
    if not set_pixel(output) then
      sync_pixel()
      pixel_state.yielded = true
      return
    end
  end
  if settled then
    pixel_state.current = target
  end
  if settled and not v1 then
    reset_pixel()
  end
end
local trash_lines = {
  beta_kill = { "1", "weak", "sit down" },
  beta_death = { "lucky shot", "not twice" },
}
trash_lines.lines = function(kind)
  return trash_lines["beta_" .. (kind or "kill")] or trash_lines.beta_kill
end
trash_lines.triggered = function(name)
  local wanted = false
  pcall(function()
    if app.trash_trigger:get(name) == true then
      wanted = true
      return
    end
    local list = app.trash_trigger:get()
    if type(list) == "table" then
      for _, value in ipairs(list) do
        if tostring(value):find(name, 1, true) then
          wanted = true
          break
        end
      end
    end
  end)
  return wanted
end
trash_lines.say = function(kind)
  local lines = trash_lines.lines(kind)
  if #lines == 0 then
    return
  end
  local command =
      "say \"" .. tostring(lines[math.random(#lines)]):gsub("\"", "") .. "\""
  if utils and type(utils.console_exec) == "function" then
    utils.console_exec(command)
    return
  end
  if client and type(client.exec) == "function" then
    client.exec(command)
    return
  end
  if client and type(client.execute) == "function" then
    client.execute(command)
    return
  end
end
on_event("player_death", function(event)
  pcall(function()
    if not item_enabled(app.trash) then
      return
    end
    local me = entity.get_local_player()
    if not me then
      return
    end
    local payload = type(event) == "table" and event or nil
    local my_id = nil
    pcall(function()
      my_id = tonumber(me.m_iUserID)
    end)
    local victim, attacker
    pcall(function()
      victim = payload and entity.get(payload.userid, true) or nil
      attacker = payload and entity.get(payload.attacker, true) or nil
    end)
    local i_died, i_killed = nil, nil
    if my_id and payload then
      i_died = tonumber(payload.userid) == my_id
      i_killed = tonumber(payload.attacker) == my_id
    else
      i_died = victim == me
      i_killed = attacker == me
    end
    if i_died then
      if trash_lines.triggered("On Death") then
        pcall(trash_lines.say, "death")
      end
      return
    end
    if i_killed and victim and trash_lines.triggered("On Kill") then
      pcall(trash_lines.say, "kill")
    end
  end)
end)
local trash_timer = { next = 0, active = false }
trash_timer.say = function()
  local command = "say \"emberlight production\""
  if utils and type(utils.console_exec) == "function" then
    utils.console_exec(command)
    return
  end
  if client and type(client.exec) == "function" then
    client.exec(command)
    return
  end
  if client and type(client.execute) == "function" then
    client.execute(command)
    return
  end
  error("console command API unavailable")
end
trash_timer.tick = function()
  local now = game_time()
  if not globals or globals.is_in_game ~= true then
    trash_timer.active = false
    return
  end
  if not trash_timer.active then
    trash_timer.active = true
    trash_timer.next = now + math.random(300, 600)
    return
  end
  if now < trash_timer.next then
    return
  end
  local ok, err = pcall(trash_timer.say)
  trash_timer.next = now + math.random(300, 600)
  if not ok then
    log_once(
         "trash_talk",
         "TrashTalk: " .. tostring(err):gsub("%c", " "):sub(1, 90))
  end
end
local kill_queue = { queue = {}, max = 120 }
local function f2()
  kill_queue.queue = {}
end
local function f3()
  local ok, c = pcall(function()
    return app.kill_particle_color:get()
  end)
  if ok and c then
    local r, g, b, a =
        tonumber(c.r),
        tonumber(c.g),
        tonumber(c.b),
        tonumber(c.a)
    if r and g and b then
      return r, g, b, a or 255
    end
  end
  return 235, 245, 255, 255
end
local function spawn_kill_particles(event)
  if not item_enabled(app.kill_particles) then
    return
  end
  local me = entity.get_local_player()
  if not me then
    return
  end
  local victim, attacker
  pcall(function()
    local payload = type(event) == "table" and event or nil
    if not payload then
      return
    end
    victim = entity.get(payload.userid, true)
    attacker = entity.get(payload.attacker, true)
  end)
  if not victim or not attacker then
    return
  end
  local my_id = nil
  pcall(function()
    my_id = tonumber(me.m_iUserID)
  end)
  local i_died, i_killed = victim == me, attacker == me
  if my_id and type(event) == "table" then
    i_died = tonumber(event.userid) == my_id
    i_killed = tonumber(event.attacker) == my_id
  end
  if i_died or not i_killed then
    return
  end
  local ok_origin, origin = pcall(function()
    return victim:get_origin()
  end)
  if not ok_origin or not origin or not finite(origin.x) then
    return
  end
  local points = {}
  for hitbox = 0, 18 do
    local ok, point = pcall(function()
      return victim:get_hitbox_position(hitbox)
    end)
    if ok and point and finite(point.x) and finite(point.y) and finite(point.z) then
      points[#points + 1] = point
    end
  end
  if #points == 0 then
    points[1] = vector(origin.x, origin.y, (origin.z or 0) + 42)
  end
  local distance = 0
  local ok_me, me_origin = pcall(function()
    return me:get_origin()
  end)
  if ok_me and me_origin and finite(me_origin.x) then
    local dx, dy, dz =
        origin.x - me_origin.x,
        origin.y - me_origin.y,
        (origin.z or 0) - (me_origin.z or 0)
    distance = math.sqrt(dx * dx + dy * dy + dz * dz)
  end
  local scale = distance > 0 and clamp(300 / distance, 0.18, 1) or 1
  local ok_amount, amount = pcall(function()
    return app.kill_particle_amount:get()
  end)
  local ok_duration, duration = pcall(function()
    return app.kill_particle_duration:get()
  end)
  amount =
      clamp(math.floor((ok_amount and tonumber(amount) or 18) + 0.5), 6, 80)
  duration = clamp(ok_duration and tonumber(duration) or 2, 1, 4)
  local now = game_time()
  for i = 1, amount do
    if #kill_queue.queue >= kill_queue.max then
      break
    end
    local point = points[((i - 1) % #points) + 1]
    local angle = math.random() * math.pi * 2
    local spread = 1.5 + math.random() * 4
    kill_queue.queue[#kill_queue.queue + 1] = {
      x = point.x + math.cos(angle) * spread,
      y = point.y + math.sin(angle) * spread,
      z = point.z + (math.random() - 0.5) * 5,
      vx = (math.random() - 0.5) * 7,
      vy = (math.random() - 0.5) * 7,
      vz = 7 + math.random() * 12,
      size = 1 + math.random(),
      scale = scale,
      born = now + math.random() * 0.14,
      life = duration * (0.82 + math.random() * 0.18),
      phase = math.random() * math.pi * 2,
    }
  end
end
local function tick_kill_particles()
  if not item_enabled(app.kill_particles) then
    if #kill_queue.queue > 0 then
      f2()
    end
    return
  end
  local now = game_time()
  local cr, cg, cb, ca = f3()
  local i = 1
  while i <= #kill_queue.queue do
    local p = kill_queue.queue[i]
    local age = now - p.born
    if age > p.life then
      table.remove(kill_queue.queue, i)
    elseif age < 0 then
      i = i + 1
    else
      local progress = age / p.life
      local drag = 1 - progress * 0.28
      local drift = math.sin(age * 4 + p.phase) * 1.2
      local pos = vector(
          p.x + p.vx * age * drag + drift,
          p.y + p.vy * age * drag - drift * 0.5,
          p.z + p.vz * age - 5.5 * age * age + 2 * math.sin(progress * math.pi))
      local ok_screen, screen = pcall(render.world_to_screen, pos)
      if ok_screen and screen and finite(screen.x) and finite(screen.y) then
        local appear = math.min(1, age / 0.12)
        local fade = 1 - math.max(0, (progress - 0.55) / 0.45)
        local alpha = math.floor(ca * appear * fade)
        local pulse = 1 + math.sin(age * 7 + p.phase) * 0.12
        local radius =
            math.max(1, math.floor(p.size * pulse * p.scale + 0.5))
        local center = vector(screen.x, screen.y)
        render.circle(
              center,
              color(cr, cg, cb, math.floor(alpha * 0.07)),
              radius + 3,
              0,
              1)
        render.circle(
              center,
              color(cr, cg, cb, math.floor(alpha * 0.15)),
              radius + 2,
              0,
              1)
        render.circle(
              center,
              color(cr, cg, cb, math.floor(alpha * 0.3)),
              radius + 1,
              0,
              1)
        render.circle(center, color(
            math.min(255, cr + 18),
            math.min(255, cg + 18),
            math.min(255, cb + 18),
            alpha), radius, 0, 1)
        render.circle(
              vector(screen.x - radius * 0.3, screen.y - radius * 0.3),
              color(255, 255, 255, math.floor(alpha * 0.7)),
              math.max(0.6, radius * 0.3),
              0,
              1)
      end
      i = i + 1
    end
  end
end
on_event("player_death", function(event)
  local ok, err = pcall(spawn_kill_particles, event)
  if not ok then
    log_once(
         "kill_particles_death",
         "Kill Particles: " .. tostring(err):gsub("%c", " "):sub(1, 90))
  end
end)
on_event("round_start", f2)
local rand_seed = math.floor(game_time() * 1000) % 2147483646 + 1
local function rand_next()
  rand_seed = (rand_seed * 48271) % 2147483647
  return rand_seed / 2147483647
end
local clantag_patterns = { "::emberlight..", "..emberlight::" }
local clantag_state = { owned = false, failed = false, prev = "" }
local function clear_clantag()
  if clantag_state.owned then
    pcall(function()
      common.set_clan_tag("\0")
    end)
  end
  clantag_state.owned, clantag_state.prev = false, ""
end
local function tick_clantag()
  if not item_enabled(app.clantag) then
    clear_clantag()
    clantag_state.failed = false
    return
  end
  if not globals or not globals.is_in_game or clantag_state.failed then
    return
  end
  local iv = finite(globals.tickinterval) or 0.015625
  local phase = math.floor(
           (finite(globals.tickcount) or 0) / math.max(1, math.floor(0.6 / iv + 0.5)))
  local tag = clantag_patterns[(phase % #clantag_patterns) + 1]
  if tag == clantag_state.prev then
    return
  end
  local ok = pcall(function()
    common.set_clan_tag(tag)
  end)
  if ok then
    clantag_state.prev, clantag_state.owned = tag, true
  else
    clantag_state.failed = true
  end
end
local clantag_state = {
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
  last_shot_time = 0,
}
local clantag_text =
    "One verified native Double Tap force-charge request after a shot. Uses the selected Beta Charge Mode; no packet or attack edits. OFF by default."
noop(app.unsafe_recharge, clantag_text)
clantag_state.log = function(self, text, always)
  if always then
    raw_log("[Emberlight Recharge] " .. text)
  end
end
clantag_state.reset = function(self, reason)
  self.pending, self.watching, self.spent, self.cooldown_until =
      nil,
      nil,
      false,
      0
  self.commands, self.fault, self.scope = nil, nil, nil
  self.read_strikes = 0
  self.state = reason or "reset"
  noop(app.unsafe_recharge, clantag_text)
end
clantag_state.charge = function(self)
  local ok, value = pcall(function()
    return rage.exploit:get()
  end)
  if ok and finite(value) and value >= 0 and value <= 1 then
    return value
  end
  return nil
end
clantag_state.charge_rate = function(self, t, charge)
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
      self.charge_rate_v = (self.charge_rate_v or 0) * 0.7 + rate * 0.3
    end
  end
  return self.charge_rate_v
end
clantag_state.rate_lim = function(rate, base, floor)
  if not rate then
    return base
  end
  if rate > 0.6 then
    return math.max(floor, base - 0.3)
  elseif rate > 0.35 then
    return math.max(floor, base - 0.2)
  elseif rate > 0.15 then
    return math.max(floor, base - 0.1)
  end
  return base
end
clantag_state.tickbase_ready = function(self)
  local ok, ready = pcall(function()
    local me = entity.get_local_player()
    if not me then
      return nil
    end
    local tickbase =
        finite(me.m_nTickBase) or finite(entity.get_prop(me, "m_nTickBase"))
    local v1 = globals and finite(globals.tickcount)
    if not tickbase or not v1 then
      return nil
    end
    local shift = math.floor(tickbase - v1 - 3)
    return shift <= -11
  end)
  return ok and ready or nil
end
clantag_state.context = function(self)
  if self.suspended then
    return nil, "config / unload paused"
  end
  if not globals or globals.is_in_game ~= true then
    return nil, "not in game"
  end
  if not native_api:master_enabled() then
    return nil, "native Ragebot OFF / unavailable"
  end
  if native_api:effective(self.dt) ~= true then
    return nil, "Double Tap OFF / unavailable"
  end
  if self:tickbase_ready() == false then
    return nil, "Double Tap on, tickbase not shifted yet"
  end
  local ok, ctx, reason = pcall(function()
    local me = entity.get_local_player()
    if not me then
      return nil, "no local player"
    end
    if not me:is_alive() then
      return nil, "local player dead"
    end
    local weapon = me:get_player_weapon()
    if not weapon or not weapon:is_weapon() then
      return nil, "no weapon"
    end
    local info_tab = weapon:get_weapon_info()
    if not info_tab or not finite(info_tab.max_clip1) or
      info_tab.max_clip1 <= 1 or info_tab.is_revolver == true then
      return nil, "unsupported weapon (grenade/knife/revolver/single-round)"
    end
    local id, uid = weapon:get_index(), me:get_player_info().userid
    if not finite(id) or not finite(uid) then
      return nil, "weapon/player identity unavailable"
    end
    return { weapon = id, user = uid }
  end)
  if not ok then
    return nil, "context read failed"
  end
  return ctx, reason
end
clantag_state.on_shot = function(self, event)
  if not self.ready or self.fault or self.suspended or
    not item_enabled(app.unsafe_recharge) or not event then
    return
  end
  local now, shot_id = game_time(), tonumber(event.id)
  if shot_id and self.last_shot_id == shot_id and
    now - self.last_shot_time < 0.25 then
    return
  end
  self.last_shot_id, self.last_shot_time = shot_id, now
  self.shot_events = self.shot_events + 1
  local ctx, reason = self:context()
  local charge = self:charge()
  if not ctx or charge == nil then
    self.pending = nil
    self.state = reason or "charge unreadable"
    return
  end
  if charge >= 0.99 and not self.watching then
    self.spent = false
  end
  if self.spent or self.watching or now < self.cooldown_until then
    return
  end
  self.pending = {
    weapon = ctx.weapon,
    user = ctx.user,
    time = now,
    steps = 0,
    initial = charge,
    id = shot_id,
  }
  self.scope = tostring(ctx.user) .. ":" .. tostring(ctx.weapon)
  self.state = "queued; waiting for verified charge expenditure"
end
clantag_state.step = function(self, cmd)
  if not self.ready then
    self.state = "unavailable"
    return
  end
  if self.suspended then
    self.state = "config / unload paused"
    return
  end
  if self.fault then
    self.state = self.fault
    return
  end
  if not item_enabled(app.unsafe_recharge) then
    self.pending, self.watching, self.spent = nil, nil, false
    self.state = "OFF"
    return
  end
  local valid, seq = pcall(function()
    return finite(cmd.command_number)
  end)
  if not valid or not seq then
    self.state = "command number unavailable"
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
    self.pending, self.watching, self.spent, self.scope =
        nil,
        nil,
        false,
        nil
    self.state = reason
    return
  end
  local scope = tostring(ctx.user) .. ":" .. tostring(ctx.weapon)
  if self.scope and self.scope ~= scope then
    self.pending, self.watching, self.spent = nil, nil, false
    self.state = "weapon/player changed; old request cancelled"
  end
  self.scope = scope
  local charge = self:charge()
  self.charge_value = charge
  if charge == nil then
    self.pending, self.watching = nil, nil
    self.read_strikes = (self.read_strikes or 0) + 1
    if self.read_strikes >= 3 then
      self.read_strikes = 0
      self.fault = "Cannot read exploit charge"
      self.state = self.fault
      self:log(
          self.fault .. "; no request issued. Toggle OFF/ON to retry.",
          true)
      return
    end
    self.state =
        string.format("charge read failed (%d/3)", self.read_strikes)
    return
  end
  self.read_strikes = 0
  local t = game_time()
  if self.watching then
    local w = self.watching
    if charge >= 0.99 then
      self.observed_full = self.observed_full + 1
      self.last_result = string.format(
              "full charge observed %.3fs after request (causation not proven)",
              t - w.time)
      self.watching, self.spent = nil, false
    elseif t < w.time or t - w.time > 2 then
      self.timeouts = self.timeouts + 1
      self.last_result =
          "no full charge observed within 2.0s; cycle released, no automatic retry"
      self.watching, self.spent = nil, false
    else
      w.best = math.max(w.best or w.initial or 0, charge)
      if charge < (w.spent_lim or 0.95) and charge < (w.best or 0) - 0.005 then
        self.observed_full = self.observed_full + 1
        self.last_result = string.format(
              "charge expenditure observed %.3fs after request (%.1f%% -> %.1f%%)",
              t - w.time,
              (w.best or 0) * 100,
              charge * 100)
        self.watching, self.spent = nil, false
        return
      end
      self.state =
          string.format("request sent; observed charge %.1f%%", charge * 100)
      return
    end
  elseif charge >= 0.99 then
    self.spent = false
  end
  local p = self.pending
  if not p then
    self.state = self.spent and "cycle spent; waiting for full charge / toggle reset" or (charge >= 0.99 and "charged; waiting for shot" or
      "waiting for ragebot shot")
    return
  end
  if p.weapon ~= ctx.weapon or p.user ~= ctx.user or t < p.time or
    t - p.time > 0.8 then
    self.pending = nil
    self.expired = self.expired + 1
    self.state = "pending request expired / context changed"
    return
  end
  p.steps = p.steps + 1
  local okm, umode = pcall(function()
    return app.unsafe_mode:get()
  end)
  umode = (okm and umode) or "Faster Charge"
  local unsafe = umode == "Unsafe Exploit"
  local spend_lim = unsafe and 0.8 or 0.95
  local min_steps, min_dt, cooldown =
      unsafe and 1 or 2,
      nil,
      unsafe and 0.15 or 0.35
  if charge >= spend_lim then
    self.state = "queued; waiting for verified charge expenditure"
    return
  end
  if not unsafe and p.initial and p.initial < 0.95 and
    math.abs(charge - p.initial) < 0.005 and p.steps < 3 then
    self.state = "queued; confirming stable partial charge"
    return
  end
  local interval = globals and finite(globals.tickinterval)
  if not interval or interval <= 0 or interval > 0.1 then
    self.state = "tick interval unavailable"
    return
  end
  min_dt = min_dt or interval * min_steps
  if p.steps < min_steps or t - p.time < min_dt then
    self.state = "queued; burst separation"
    return
  end
  if self.spent or t < self.cooldown_until then
    self.state = "queued; cycle cooldown"
    return
  end
  self.pending, self.cooldown_until = nil, t + (cooldown or 0.35)
  self.attempts = self.attempts + 1
  local ok, err = pcall(function()
    rage.exploit:force_charge()
  end)
  if not ok then
    self.spent = false
    self.fault = "Native recharge request failed"
    self.state = self.fault
    noop(app.unsafe_recharge, self.fault .. ". Toggle OFF/ON to retry.")
    self:log(self.fault .. ": " .. tostring(err):gsub("%c", " "), true)
    return
  end
  self.spent = true
  self.requests = self.requests + 1
  self.watching =
      { time = t, initial = charge, best = charge, spent_lim = spend_lim }
  self.state = "native request sent; completion not yet observed"
end
clantag_state.idle = function(self)
  if self.suspended or self.fault or not self.ready then
    return
  end
  local ctx, reason = self:context()
  if not item_enabled(app.unsafe_recharge) or not ctx then
    self.pending, self.watching, self.spent, self.scope =
        nil,
        nil,
        false,
        nil
    self.state = not item_enabled(app.unsafe_recharge) and "OFF" or reason
  elseif self.pending and game_time() - self.pending.time > 0.8 then
    self.pending = nil
    self.expired = self.expired + 1
    self.state = "pending request expired"
  end
end
clantag_state.guard = function(self, method, ...)
  local ok, err = pcall(method, self, ...)
  if not ok then
    self.pending, self.watching = nil, nil
    self.fault = "Recharge callback error"
    self.state = self.fault
    log_once("recharge_callback", tostring(err):gsub("%c", " "))
  end
end
do
  clantag_state.dt = native_api:find({ "Aimbot", "Ragebot", "Main", "Double Tap" })
  rawset(_G, "__EMBERLIGHT_DT", function()
    local ref = clantag_state.dt
    if not ref then
      return nil
    end
    local ok, value = pcall(function()
      return native_api:effective(ref)
    end)
    if ok and value ~= nil then
      return value == true
    end
    return nil
  end)
  local api = pcall(function()
    assert(type(rage.exploit.force_charge) == "function")
    assert(type(rage.exploit.get) == "function")
  end)
  clantag_state.api_ready =
      clantag_state.dt ~= nil and type(native_api:effective(clantag_state.dt)) == "boolean" and api
  clantag_state.ready = clantag_state.api_ready
  if not clantag_state.ready then
    app.unsafe_recharge:set(false)
    app.unsafe_recharge:disabled(true)
    noop(
        app.unsafe_recharge,
        "Unavailable: native Double Tap / force-charge API missing.")
    log_once(
         "recharge_unavailable",
         "Unsafe Recharge unavailable in this build.")
  end
  app.unsafe_recharge:set_callback(function()
    clantag_state:reset("switch changed")
  end)
end
local yaw_state_table = {
  players = {},
  shots = {},
  epoch = 1,
  sequence = 0,
  ready = false,
  fault = nil,
  last_clock = game_time(),
  last_command = nil,
  last_step = nil,
  last_frame = -1,
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
  status_cache = {},
  status_at = -1,
  net_count = 0,
  command_count = 0,
}
local extrapolation_status = { count = 0, state = "OFF", hc = {}, active = false }
extrapolation_status.mode = function(self)
  local ok, m = pcall(function()
    return app.forceshot_mode:get()
  end)
  if ok and (m == "CSGO" or m == "CS2") then
    return m
  end
  return "CSGO"
end
extrapolation_status.release_hc = function(self)
  local stuck = 0
  for _, h in ipairs(self.hc) do
    pcall(function()
      h.ref:override()
    end)
    local rok, override = pcall(function()
      return h.ref:get_override()
    end)
    if not rok or override ~= nil then
      stuck = stuck + 1
    end
  end
  if #self.hc == 0 then
    self.hc = {}
  end
  self.active = false
  if stuck > 0 then
    self.state = "hitchance release unverified on " .. stuck .. " slot(s)"
    log_once("forceshot_release", "ForceShot could not clear its native hitchance override on " ..
      stuck .. " slot(s). Native hitchance may stay pinned to 0; check the menu and toggle ForceShot OFF/ON.")
  end
  return stuck == 0
end
extrapolation_status.bind_hc = function(self)
  if #self.hc > 0 then
    return true
  end
  local cands = {
    { "Aimbot", "Ragebot", "Selection", "Hit Chance" },
    { "Aimbot", "Ragebot", "Accuracy", "Hit Chance" },
    { "Aimbot", "Ragebot", "Main", "Hit Chance" },
    { "Aimbot", "Ragebot", "Selection", "Hitchance" },
  }
  local seen, found, bad_value = {}, 0, 0
  for _, p in ipairs(cands) do
    local ok, ref = pcall(function()
      return ui.find(p[1], p[2], p[3], p[4])
    end)
    if ok and ref and not seen[ref] then
      seen[ref] = true
      found = found + 1
      local rok, v = pcall(function()
        return ref:get()
      end)
      if rok and finite(v) then
        self.hc[#self.hc + 1] = { ref = ref }
      else
        bad_value = bad_value + 1
      end
    end
  end
  self.bind_found, self.bind_bad_value = found, bad_value
  if #self.hc == 0 and found > 0 and bad_value == found then
    self.state = string.format(
              "hitchance slot found (%d) but not numeric in this build",
              found)
  end
  return #self.hc > 0
end
extrapolation_status.valid_threat = function(self)
  local ok, threat = pcall(function()
    return entity.get_threat()
  end)
  if not ok or not threat then
    return nil
  end
  local alive, enemy, dormant = false, false, true
  pcall(function()
    alive = threat:is_alive()
  end)
  pcall(function()
    enemy = threat:is_enemy()
  end)
  pcall(function()
    dormant = threat:is_dormant()
  end)
  if not alive or not enemy or dormant then
    return nil
  end
  return threat
end
extrapolation_status.prediction_clean = function(self, threat)
  if not item_enabled(app.extrapolation) then
    return true
  end
  if yaw_state_table.prediction_fault then
    return false
  end
  local slot = nil
  pcall(function()
    slot = threat:get_index()
  end)
  if not finite(slot) then
    return false
  end
  local s = yaw_state_table.players and yaw_state_table.players[slot]
  local p = s and s.prediction
  if not p then
    return false
  end
  if game_time() - (p.time or 0) > 0.1 then
    return false
  end
  if p.collision then
    return false
  end
  if (finite(p.divergence) or 999) > 12 then
    return false
  end
  if (finite(p.velocity_change) or 999) > 220 then
    return false
  end
  return true
end
extrapolation_status.stopped = function(self)
  local ok, me = pcall(function()
    return entity.get_local_player()
  end)
  if not ok or not me then
    return false
  end
  local alive = false
  pcall(function()
    alive = me:is_alive()
  end)
  if not alive then
    return false
  end
  local flags = nil
  pcall(function()
    flags = finite(me.m_fFlags)
  end)
  if flags == nil then
    pcall(function()
      flags = finite(entity.get_prop(me, "m_fFlags"))
    end)
  end
  local ground =
      flags and bit and bit.band and bit.band(flags, 1) == 1 or false
  if not ground then
    return false
  end
  local vel = nil
  pcall(function()
    vel = me.m_vecVelocity
  end)
  if not vel then
    return false
  end
  local sp = math.sqrt((finite(vel.x) or 0) ^ 2 + (finite(vel.y) or 0) ^ 2)
  return sp < 10
end
extrapolation_status.tick = function(self, cmd)
  if not item_enabled(app.forceshot) then
    self.state = "OFF"
    self:release_hc()
    return
  end
  if not native_api:master_enabled() then
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
  if item_enabled(app.extrapolation) and not self:prediction_clean(threat) then
    self.state = "prediction unstable; forced shot refused"
    self:release_hc()
    return
  end
  local mode = self:mode()
  local active = false
  if mode == "CSGO" then
    active = cmd and (cmd.in_attack == 1 or cmd.in_attack == true)
    if not active then
      self.state = "CSGO: waiting fire"
      self:release_hc()
      return
    end
  else
    active = self:stopped()
    if not active then
      self.state = "CS2-like: waiting accuracy"
      self:release_hc()
      return
    end
  end
  if not self:bind_hc() then
    self.state = "hitchance slot unavailable"
    return
  end
  local applied = 0
  for _, h in ipairs(self.hc) do
    pcall(function()
      h.ref:override(0)
    end)
    local aok, override = pcall(function()
      return h.ref:get_override()
    end)
    if aok and override == 0 then
      applied = applied + 1
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
  self.state =
      mode .. (mode == "CS2" and "-like" or "") .. ": force-shot gate active"
end
extrapolation_status.guard = function(self, method, ...)
  local ok, err = pcall(method, self, ...)
  if not ok then
    pcall(function()
      self:release_hc()
    end)
    log_once(
         "forceshot_callback",
         "ForceShot callback error: " .. tostring(err):gsub("%c", " "))
    self.state = "callback error; override released"
  end
end
native_api.EX = { pending = {}, applied = 0, state = "idle" }
native_api.EX.target = function(self)
  if not item_enabled(app.extrapolation) or
    not item_enabled(app.extrapolation_rewrite) then
    return nil
  end
  local me = nil
  local me_alive = false
  pcall(function()
    me = entity.get_local_player()
    me_alive = me ~= nil and me:is_alive() == true
  end)
  if not me_alive then
    return nil
  end
  local ticks = tonumber(app.extrapolation_ticks and app.extrapolation_ticks:get() or 0) or
    0
  if not (ticks > 0) then
    return nil
  end
  local found, threat = pcall(function()
    return entity.get_threat()
  end)
  if not found or not threat then
    return nil
  end
  local alive, enemy, dormant = false, false, true
  pcall(function()
    alive = threat:is_alive()
  end)
  pcall(function()
    enemy = threat:is_enemy()
  end)
  pcall(function()
    dormant = threat:is_dormant()
  end)
  if not alive or not enemy or dormant then
    return nil
  end
  local slot = nil
  pcall(function()
    slot = threat:get_index()
  end)
  if not finite(slot) then
    return nil
  end
  local s = yaw_state_table and yaw_state_table.players and yaw_state_table.players[slot]
  local p = s and s.prediction
  if not p or not (p.x and p.y and p.z) then
    return nil
  end
  if game_time() - (p.time or 0) > 0.1 then
    return nil
  end
  return threat, slot, p
end
native_api.EX.apply = function(self)
  if self.pending[1] and self.pending[2] and self.pending[3] then
    local ent, slot, p = self.pending[1], self.pending[2], self.pending[3]
    local ok, old = pcall(function()
      return ent.m_vecOrigin
    end)
    if not ok or not old then
      pcall(function()
        old = entity.get_prop(ent, "m_vecOrigin")
      end)
    end
    if not old then
      return
    end
    local written = false
    local snap = { x = finite(p.x), y = finite(p.y), z = finite(p.z) }
    pcall(function()
      ent.m_vecOrigin = vector(snap.x, snap.y, snap.z)
      written = true
    end)
    if not written then
      return
    end
    self.applied = self.applied + 1
    self.state = "rewrote " .. slot .. " origin -> predicted"
    local old_snap =
        { x = finite(old.x), y = finite(old.y), z = finite(old.z) }
    if old_snap.x and old_snap.y and old_snap.z then
      utils.execute_after(0.02, function()
        local valid = false
        pcall(function()
          valid = ent ~= nil and ent:is_valid() == true
        end)
        if not valid then
          return
        end
        local restored = false
        pcall(function()
          ent.m_vecOrigin = vector(old_snap.x, old_snap.y, old_snap.z)
          restored = true
        end)
        if not restored then
          pcall(function()
            entity.set_prop(
                ent,
                "m_vecOrigin",
                vector(old_snap.x, old_snap.y, old_snap.z))
          end)
        end
      end)
    end
  end
end
native_api.EX.restore = function(self, ent, old)
  local valid = false
  pcall(function()
    valid = ent ~= nil and ent:is_valid() == true
  end)
  if not valid then
    return
  end
  pcall(function()
    entity.set_prop(ent, "m_vecOrigin", old)
  end)
end
native_api.EX.tick = function(self, cmd)
  self.pending = {}
  local results = { pcall(function()
    return self:target()
  end) }
  if results[1] and results[2] and results[3] and results[4] then
    self.pending = { results[2], results[3], results[4] }
  end
  self:apply()
end
native_api.EX.guard = function(self, method, ...)
  local ok, err = pcall(method, self, ...)
  if not ok then
    self.state =
        "extrapolation rewrite error: " .. tostring(err):gsub("%c", " ")
    log_once("extrap_rewrite", self.state)
  end
end
local aim_ack_stats = {
  max_players = 64,
  max_shots = 128,
  shot_age = 3,
  fresh_age = 0.25,
  simulation_period = 0.04,
  prediction_ticks = 2,
  command_watchdog = 0.2,
  correction_window = 2.5,
  assist_duration = 0.8,
  assist_cooldown = 1.2,
  prediction_fault_limit = 4,
  lag_soft = 0.3,
  lag_hard = 0.45,
}
yaw_state_table.say = function(self, text, always)
  if always then
    raw_log("[Emberlight] " .. tostring(text):gsub("%c", " "):sub(1, 480))
  end
end
yaw_state_table.identity = function(self, ent)
  local ok, id, uid = pcall(function()
    return ent:get_index(), ent:get_player_info().userid
  end)
  if not ok or not finite(id) or not finite(uid) then
    return nil
  end
  if id < 1 or id > aim_ack_stats.max_players or id ~= math.floor(id) or uid < 1 or
    uid ~= math.floor(uid) then
    return nil
  end
  return id, uid
end
yaw_state_table.tag = function(self, ent, id)
  local ok, text = pcall(function()
    return ent:get_name()
  end)
  if not ok or type(text) ~= "string" then
    text = "player " .. tostring(id or "?")
  end
  return text:gsub("[%c|]", " "):sub(1, 72)
end
yaw_state_table.interval = function(self)
  local dt = globals and finite(globals.tickinterval)
  if dt and dt >= 0.001 and dt <= 0.1 then
    return dt
  end
  return nil
end
yaw_state_table.server_tick = function(self)
  local ok, tick = pcall(function()
    local base = tonumber(globals.client_tick)
    local offset = tonumber(globals.clock_offset)
    if base and offset and base + offset > 0 then
      return base + offset, "client_tick"
    end
  end)
  if ok and tonumber(tick) then
    return tick, "client_tick"
  end
  local st = finite(globals.server_tick)
  if st and st > 0 then
    return st, "server_tick"
  end
  local tc = finite(globals.tickcount)
  if tc then
    return tc, "tickcount"
  end
  return nil, "unavailable"
end
yaw_state_table.to_time = function(self, a1)
  local dt = self:interval()
  if not dt or not tonumber(a1) then
    return nil
  end
  return a1 * dt
end
yaw_state_table.to_ticks = function(self, time)
  local dt = self:interval()
  if not dt or dt <= 0 or not tonumber(time) then
    return nil
  end
  return math.floor(time / dt)
end
yaw_state_table.lag_time = function(self, sim)
  local v1, source = self:server_tick()
  local st = self:to_time(v1)
  if source ~= "server_tick" and source ~= "client_tick" then
    return nil, source
  end
  if not st or not tonumber(sim) then
    return nil, source
  end
  return st - sim, source
end
yaw_state_table.dead_time = function(self)
  local v1, source = self:server_tick()
  if source == "unavailable" then
    return nil, source
  end
  local st = self:to_time(v1)
  if not st then
    return nil, source
  end
  local max_unlag = nil
  local got, ref = pcall(function()
    if cvar.sv_maxunlag then
      return cvar.sv_maxunlag
    end
    if cvar.find then
      return cvar.find("sv_maxunlag")
    end
  end)
  if got and ref then
    local read, value = pcall(function()
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
    local l = finite(channel.latency[0])
    if l and l >= 0 then
      latency = l
    end
  end
  return {
    time = st - (latency or 0) - (max_unlag or 0),
    tick = self:to_ticks(st - (latency or 0) - (max_unlag or 0)),
    latency = latency,
    max_unlag = max_unlag,
    source = source,
  }
end
yaw_state_table.context = function(self)
  if not self.ready then
    return nil, "required events unavailable"
  end
  if self.suspended then
    return nil, "config transaction"
  end
  if self.fault then
    if game_time() < (self.fault_until or 0) then
      return nil, self.fault
    end
    self.fault = nil
  end
  if not native_api.master then
    return nil, "native Ragebot switch unavailable"
  end
  if not native_api:master_enabled() then
    return nil, "native Ragebot is off; unchanged"
  end
  local ok, me, uid = pcall(function()
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
yaw_state_table.reset = function(self, reason)
  local released = native_api:reset("safe")
  self.players, self.shots = {}, {}
  self.epoch, self.sequence = self.epoch + 1, 0
  self.local_uid, self.in_session, self.last_command, self.last_step =
      nil,
      false,
      nil,
      nil
  self.next_simulation, self.last_clock = 0, game_time()
  self.prediction_state, self.prediction_fault =
      "waiting for fresh network data",
      nil
  self.prediction_fault_strikes, self.fault_until = 0, nil
  self.plan = reason or "reset; native configuration retained"
  if released then
    self.fault = nil
  else
    self.fault = "native release unverified; check menu"
    self.fault_until = game_time() + 5
  end
  self:status(true)
end
yaw_state_table.ensure_context = function(self)
  local ctx, reason = self:context()
  if not ctx then
    if self.in_session then
      local old_fault, old_until = self.fault, self.fault_until
      self:reset(reason)
      self.fault, self.fault_until = old_fault or self.fault, old_until
    end
    native_api:request("safe", nil)
    self.plan = reason
    return nil
  end
  if self.local_uid and self.local_uid ~= ctx.uid then
    self:reset("local player changed")
  end
  self.local_uid, self.in_session = ctx.uid, true
  return ctx
end
yaw_state_table.snapshot = function(self, ent)
  local ok, d, reason = pcall(function()
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
    local sim, pos, velocity =
        ent:get_simulation_time(),
        ent:get_origin(),
        ent.m_vecVelocity
    if type(sim) ~= "table" then
      return nil, "simulation time unavailable"
    end
    local st, flags = finite(sim.current), finite(ent.m_fFlags)
    if flags == nil then
      pcall(function()
        flags = finite(entity.get_prop(ent, "m_fFlags"))
      end)
    end
    local x, y, z = finite(pos.x), finite(pos.y), finite(pos.z)
    local vx, vy, vz =
        finite(velocity.x),
        finite(velocity.y),
        finite(velocity.z)
    if not (st and st >= 0 and flags and x and y and z and vx and vy and vz) then
      return nil, "non-finite snapshot"
    end
    if flags < 0 or flags ~= math.floor(flags) or math.abs(x) > 10000000 or
      math.abs(y) > 10000000 or math.abs(z) > 10000000 or math.abs(vx) > 4096 or math.abs(vy) > 4096 or math.abs(vz) > 4096 then
      return nil, "invalid snapshot range"
    end
    local lag, lag_source = self:lag_time(st)
    return {
      ent = ent,
      id = id,
      uid = uid,
      sim = st,
      old_sim = finite(sim.old),
      flags = flags,
      x = x,
      y = y,
      z = z,
      vx = vx,
      vy = vy,
      vz = vz,
      speed = math.sqrt(vx * vx + vy * vy),
      lag = lag,
      lag_source = lag_source,
    }, "live"
  end)
  if not ok then
    return
        nil,
        "snapshot read failed: " .. tostring(d):gsub("%c", " "):sub(1, 120)
  end
  return d, reason
end
yaw_state_table.mark = function(self, s, key, reason, duration)
  local t = game_time()
  local item = s.risks[key]
  if item and t < item.rearm then
    return false
  end
  local ttl = duration or aim_ack_stats.assist_duration
  s.risks[key] = {
    until_t = t + ttl,
    rearm = t + ttl + aim_ack_stats.assist_cooldown,
    reason = reason,
  }
  return true
end
yaw_state_table.observe = function(self, ent)
  local id, uid = self:identity(ent)
  if not id then
    return
  end
  local d = self:snapshot(ent)
  if not d then
    self.players[id] = nil
    return
  end
  local t, s = game_time(), self.players[id]
  if not s or s.uid ~= uid then
    s = { uid = uid, risks = {}, good = 0, corrections = 0, seen = t }
    self.players[id] = s
  end
  s.seen = t
  local old = s.data
  if old and math.abs(old.sim - d.sim) <= 0.0001 then
    s.sample_time = t
    return
  end
  local reason
  local clean = true
  if old then
    local dt = d.sim - old.sim
    local distance_sq =
        (d.x - old.x) ^ 2 + (d.y - old.y) ^ 2 + (d.z - old.z) ^ 2
    if d.sim < (s.frontier or old.sim) - 0.0001 then
      reason, clean =
          "network time regression (not proof of defensive desync)",
          false
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
yaw_state_table.trim = function(self)
  local t = game_time()
  for id, s in pairs(self.players) do
    if t - (s.seen or 0) > 1.5 or t < (s.seen or t) then
      self.players[id] = nil
    end
  end
  for id, shot in pairs(self.shots) do
    if t - shot.time > aim_ack_stats.shot_age or t < shot.time then
      self.shots[id] = nil
    end
  end
end
yaw_state_table.net_update = function(self)
  if not self:ensure_context() then
    return
  end
  local ok, players = pcall(function()
    return entity.get_players(true, true)
  end)
  if not ok or type(players) ~= "table" then
    self.plan = "enemy enumeration unavailable"
    return
  end
  local count = 0
  for _, ent in pairs(players) do
    if count >= aim_ack_stats.max_players then
      break
    end
    count = count + 1
    self:observe(ent)
  end
  self.net_count = self.net_count + 1
  self:trim()
end
yaw_state_table.predict = function(self, s, live)
  if not item_enabled(app.extrapolation) then
    self.prediction_state = "OFF"
    return
  end
  if self.prediction_fault then
    self.prediction_state = self.prediction_fault
    return
  end
  if not s.clean or s.good < 2 then
    self.prediction_state = "waiting for consistent samples"
    return
  end
  local t, interval = game_time(), self:interval()
  if not interval then
    self.prediction_state = "tick interval unavailable"
    return
  end
  if s.prediction and s.prediction.sim == live.sim and
    t - s.prediction.time <= 0.12 then
    self.prediction_state = "cached isolated prediction"
    return
  end
  if t < self.next_simulation then
    return
  end
  self.next_simulation = t + aim_ack_stats.simulation_period
  local ticks = 0
  pcall(function()
    local v = app.extrapolation_ticks and tonumber(app.extrapolation_ticks:get()) or
      nil
    if v then
      ticks = math.max(0, math.min(15, math.floor(v)))
    end
  end)
  if ticks <= 0 then
    self.prediction_state = "OFF (0 ticks)"
    return
  end
  local ok, result = pcall(function()
    local sim = live.ent:simulate_movement(
                           vector(live.x, live.y, live.z),
                           vector(live.vx, live.vy, live.vz),
                           live.flags)
    if not sim then
      error("movement context unavailable")
    end
    sim:think(ticks)
    local p, v = sim.origin, sim.velocity
    return {
      x = finite(p.x),
      y = finite(p.y),
      z = finite(p.z),
      vx = finite(v.x),
      vy = finite(v.y),
      vz = finite(v.z),
      collision = sim.did_hit_collision,
    }
  end)
  if not ok then
    self.simulation_skips = self.simulation_skips + 1
    self.prediction_fault_strikes = (self.prediction_fault_strikes or 0) + 1
    if self.prediction_fault_strikes >= aim_ack_stats.prediction_fault_limit then
      self.prediction_fault = "movement simulation unavailable / failed"
      self.prediction_fault_strikes = 0
      log_once("predict_api", self.prediction_fault ..
        "; Extrapolation is paused, native aim is untouched. Toggle OFF/ON to retry.")
    end
    self.prediction_state = string.format(
              "simulation call failed (%d/%d), retries left",
              self.prediction_fault_strikes,
              aim_ack_stats.prediction_fault_limit)
    return
  end
  self.prediction_fault_strikes = 0
  if not (result.x and result.y and result.z and result.vx and result.vy and
    result.vz) or type(result.collision) ~= "boolean" then
    self.prediction_state = "invalid simulation result; skipped"
    self.simulation_skips = self.simulation_skips + 1
    return
  end
  local after = self:snapshot(live.ent)
  if not after or after.uid ~= live.uid or
    math.abs(after.sim - live.sim) > 0.0001 or math.abs(after.x - live.x) > 0.0001 or math.abs(after.y - live.y) > 0.0001 or math.abs(after.z - live.z) > 0.0001 then
    self.prediction_state = "record changed during simulation; skipped"
    self.simulation_skips = self.simulation_skips + 1
    return
  end
  local dt = interval * ticks
  local distance = math.sqrt((result.x - live.x) ^ 2 + (result.y - live.y) ^ 2 +
    (result.z - live.z) ^ 2)
  local maximum =
      math.sqrt(live.vx ^ 2 + live.vy ^ 2 + live.vz ^ 2) * dt + 40
  if distance > maximum then
    self.prediction_state = "unbounded prediction rejected"
    self.simulation_skips = self.simulation_skips + 1
    return
  end
  local expected_x, expected_y =
      live.x + live.vx * dt,
      live.y + live.vy * dt
  local velocity_change = 0
  local prev = s.previous
  if prev and live.sim > prev.sim then
    local sample_dt = live.sim - prev.sim
    if sample_dt > 0.001 and sample_dt < 0.25 then
      local ax = clamp((live.vx - prev.vx) / sample_dt, -1200, 1200)
      local ay = clamp((live.vy - prev.vy) / sample_dt, -1200, 1200)
      expected_x = expected_x + 0.5 * ax * dt * dt
      expected_y = expected_y + 0.5 * ay * dt * dt
      velocity_change =
          math.sqrt((live.vx - prev.vx) ^ 2 + (live.vy - prev.vy) ^ 2)
    end
  end
  local divergence =
      math.sqrt((result.x - expected_x) ^ 2 + (result.y - expected_y) ^ 2)
  s.prediction = {
    sim = live.sim,
    time = t,
    x = result.x,
    y = result.y,
    z = result.z,
    ticks = ticks,
    collision = result.collision,
    divergence = divergence,
    velocity_change = velocity_change,
  }
  self.simulated = self.simulated + 1
  self.prediction_state =
      string.format("isolated %dt prediction: div %.1f", ticks, divergence)
  local div_lim = 4 + math.floor(ticks / 4)
  local vel_lim = 100 + ticks * 8
  if result.collision and live.speed > 35 then
    self:mark(
          s,
          "extrapolation",
          string.format("extrapolation %dt: collision, Prefer", ticks),
          0.45)
  elseif divergence > div_lim then
    self:mark(s, "extrapolation", string.format(
              "extrapolation %dt: non-linear (div %.1f>%d), Prefer",
              ticks,
              divergence,
              div_lim), 0.45)
  elseif velocity_change > vel_lim then
    self:mark(s, "extrapolation", string.format(
              "extrapolation %dt: accel (dv %.1f>%d), Prefer",
              ticks,
              velocity_change,
              vel_lim), 0.45)
  end
end
yaw_state_table.reasons = function(self, s)
  local t, out = game_time(), {}
  local desired = nil
  local keys =
      { "resolver", "resolver_probe", "defensive", "extrapolation" }
  for _, key in ipairs(keys) do
    local v1 = ((key == "resolver" or key == "resolver_probe") and
      item_enabled(app.resolver) and item_enabled(app.assist)) or key == "defensive" or (key == "extrapolation" and item_enabled(app.extrapolation) and
      not self.prediction_fault)
    local item = s.risks[key]
    if v1 and item and t < item.until_t then
      out[#out + 1] = item.reason
      local preference = (key == "extrapolation" or key == "resolver_probe") and "Prefer" or
        "Force"
      if not desired or scope_overlay_modes[preference] > scope_overlay_modes[desired] then
        desired = preference
      end
    end
  end
  return out, desired
end
yaw_state_table.candidate_confidence = function(self, L, state)
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
  local hits = (rec and (rec.wh or rec.h) or 0) +
    (global and (global.wh or global.h) or 0) * 0.25
  local misses = (rec and (rec.wm or rec.m) or 0) +
    (global and (global.wm or global.m) or 0) * 0.25
  local total = hits + misses
  local accuracy = (hits + 1.25) / (total + 2.5)
  return clamp(total / 7, 0, 1) * accuracy, hits, misses
end
yaw_state_table.plan_safety = function(self, predict)
  local t = game_time()
  if not native_api.slots.safe.ref then
    self.plan = item_enabled(app.resolver) and item_enabled(app.assist) and
      "Assist ON but native Safe Points slot unbound (no-op)" or "Assist OFF (no native safety request)"
    native_api:request("safe", nil)
    return
  end
  if not item_enabled(app.resolver) or not item_enabled(app.assist) then
    self.plan = "Assist OFF (master or user toggle)"
    native_api:request("safe", nil)
    return
  end
  local found, ent = pcall(function()
    return entity.get_threat()
  end)
  if not found or not ent then
    self.plan = "native aim; no current threat"
    native_api:request("safe", nil)
    return
  end
  local live, why = self:snapshot(ent)
  if not live then
    self.plan = why
    native_api:request("safe", nil)
    return
  end
  local desired = nil
  local reasons = {}
  local s = self.players[live.id]
  local fresh = s and s.uid == live.uid and s.data and
    t - (s.sample_time or 0) <= aim_ack_stats.fresh_age and t >= (s.sample_time or t) and math.abs(live.sim - s.data.sim) <= 0.0001
  local lag, lag_source = live.lag, live.lag_source
  local lag_hard, lag_soft =
      lag and (lag >= aim_ack_stats.lag_hard),
      lag and (lag >= aim_ack_stats.lag_soft)
  if fresh and lag_hard then
    fresh = false
    reasons[#reasons + 1] = string.format(
              "sample %.3fs behind server time (%s)",
              lag,
              lag_source or "?")
  end
  if fresh then
    if predict and not lag_soft then
      self:predict(s, live)
    end
    local risks, risk_desired = self:reasons(s)
    for _, reason in ipairs(risks) do
      reasons[#reasons + 1] = reason
    end
    if risk_desired then
      desired = risk_desired
    end
    if lag_soft then
      reasons[#reasons + 1] = string.format(
              "server-lag sample %.3fs (%s); extrapolation withheld",
              lag,
              lag_source or "?")
      if not desired or scope_overlay_modes.Prefer > scope_overlay_modes[desired] then
        desired = "Prefer"
      end
    end
    local YL = yaw_state.learn and yaw_state.learn[live.id]
    local state = YL and YL.__state or "unknown"
    local jitter = YL and (finite(YL.jitter) or 0) or 0
    local static_conf = YL and (finite(YL.static_confidence) or 0) or 0
    local learned_conf, hits, misses = self:candidate_confidence(YL, state)
    local stable = YL and (finite(YL.state_stability) or 0) >= 3
    local hot =
        stable and hits >= 2 and learned_conf >= 0.48 and hits > misses * 1.15
    if hot then
      desired = "Force"
      reasons[#reasons + 1] =
          string.format("state candidate confidence %.2f", learned_conf)
    elseif stable and static_conf >= 0.58 and jitter >= 0.68 then
      desired = "Force"
      reasons[#reasons + 1] = "stable static high-jitter evidence"
    elseif YL and YL.side_switch and (YL.record_quality or 0) >= 0.45 then
      if not desired or scope_overlay_modes.Prefer > scope_overlay_modes[desired] then
        desired = "Prefer"
      end
      reasons[#reasons + 1] = "fresh desync side switch"
    elseif YL and YL.micro_move and jitter >= 0.3 then
      if not desired or scope_overlay_modes.Prefer > scope_overlay_modes[desired] then
        desired = "Prefer"
      end
      reasons[#reasons + 1] = "micro-movement resolver uncertainty"
    elseif YL and YL.break_lc then
      if not desired or scope_overlay_modes.Prefer > scope_overlay_modes[desired] then
        desired = "Prefer"
      end
      reasons[#reasons + 1] = "resolver record gap / lag-comp break"
    elseif not desired and
      (static_conf >= 0.34 or jitter >= 0.4 or (s.corrections or 0) > 0) then
      desired = "Prefer"
      reasons[#reasons + 1] = "uncertain resolver geometry: prefer safety"
    end
  else
    reasons[#reasons + 1] = "waiting for exact fresh threat record"
  end
  self.plan = #reasons > 0 and table.concat(reasons, " + ") or
    "native aim; no risk request"
  self.desired_safe = desired
  native_api:request("safe", desired)
  native_api:drive_extrapolation(t)
end
yaw_state_table.step = function(self, cmd)
  local t = game_time()
  if t < self.last_clock then
    self:reset("clock reset")
  end
  self.last_clock = t
  if not self:ensure_context() then
    return
  end
  local ok, sequence = pcall(function()
    return finite(cmd.command_number)
  end)
  if not ok or not sequence then
    self.plan = "command number unavailable"
    native_api:request("safe", nil)
    return
  end
  if sequence == self.last_command then
    return
  end
  self.last_command, self.last_step = sequence, t
  self.command_count = self.command_count + 1
  self:plan_safety(true)
end
yaw_state_table.fire = function(self, event)
  local ok, id, ent, bt = pcall(function()
    return finite(event.id), event.target, finite(event.backtrack)
  end)
  if not ok or not id then
    return
  end
  local slot, uid = self:identity(ent)
  if not slot then
    return
  end
  self:trim()
  local count, oldest, oldest_t = 0, nil, math.huge
  for key, shot in pairs(self.shots) do
    count = count + 1
    if shot.time < oldest_t then
      oldest, oldest_t = key, shot.time
    end
  end
  if count >= aim_ack_stats.max_shots then
    self.shots[oldest] = nil
  end
  self.sequence = self.sequence + 1
  local value, owned = native_api:fire_state()
  local YL = yaw_state.learn and yaw_state.learn[slot] or nil
  local yaw_base = (YL and tonumber(YL.__base)) or nil
  local yaw_applied = (YL and tonumber(YL.__yaw)) or nil
  local yaw_corr = (yaw_base and yaw_applied) and normalize_angle(yaw_applied - yaw_base) or
    nil
  if YL then
    local wide = (tonumber(YL.resolve_wide_rejects) or 0) -
      (tonumber(YL.__wide_reported) or 0)
    if wide > 0 then
      yaw_state.population.wide_rejects =
          (yaw_state.population.wide_rejects or 0) + wide
      YL.__wide_reported = tonumber(YL.resolve_wide_rejects) or 0
    end
  end
  local server_tick, server_source = self:server_tick()
  local server_time = self:to_time(server_tick)
  local dead_info = self:dead_time()
  local rec = self.players[slot]
  local live = rec and rec.data or nil
  self.shots[id] = { id = slot, uid = uid, time = game_time(), sequence = self.sequence, epoch = self.epoch, tag = self:tag(ent, slot), backtrack = bt, interval = self:interval(), safe_value = value, safe_owned = owned, resolver = item_enabled(app.resolver) and item_enabled(app.assist), defensive = true, yaw_bucket = (YL and YL.__cur) or "unknown", yaw_state = (YL and YL.__state) or "unknown", yaw_mode = yaw_state.mode_label(), yaw_value = ((item_enabled(app.resolver) and item_enabled(app.assist)) and YL and
    YL.__yaw) or (yaw_state.last_target == slot and yaw_state.last_angles) or nil, yaw_base = yaw_base, yaw_applied = yaw_applied, yaw_corr = yaw_corr, yaw_band = band_of(yaw_corr), yaw_side = (YL and tonumber(YL.__side)) or nil, yaw_pose = (YL and tonumber(YL.__delta)) or nil, resolver_confidence = (YL and tonumber(YL.static_confidence)) or 0, feedback_bias = (YL and tonumber(YL.feedback_bias)) or 0, server_tick = server_tick, server_tick_source = server_source, server_time = server_time, lag = live and tonumber(live.lag), lag_source = live and live.lag_source, dead_time = dead_info and dead_info.time, dead_tick = dead_info and dead_info.tick, latency = dead_info and dead_info.latency, max_unlag = dead_info and dead_info.max_unlag, evalate_brute = (YL and tonumber(YL.evalate_brute)) or 1, evalate_forced = (YL and tonumber(YL.evalate_forced)) or nil, evalate_confidence = (YL and tonumber(YL.evalate_confidence)) or 0, record_quality = (YL and tonumber(YL.record_quality)) or 0, beta_confidence = (YL and tonumber(YL.beta_confidence)) or 0, ult_confidence = (YL and tonumber(YL.ult_confidence)) or 0, side_switch = YL and YL.side_switch or false, micro_move = YL and YL.micro_move or false, active = self.ready and not self.fault and not self.suspended and
    native_api:master_enabled() }
end
yaw_state_table.ack = function(self, event)
  local ok, id, ent, reason = pcall(function()
    local r = event.state
    if r == nil then
      r = event.reason
    end
    return finite(event.id), event.target, r
  end)
  if not ok then
    return
  end
  local shot = id and self.shots[id] or nil
  if id then
    self.shots[id] = nil
  end
  local stat_mode = "Unmatched"
  if shot then
    if type(shot.yaw_mode) == "string" and shot.yaw_mode ~= "" then
      stat_mode = shot.yaw_mode
    else
      local ok_mode, current_mode = pcall(yaw_state.mode_label)
      if ok_mode and type(current_mode) == "string" and current_mode ~= "" then
        stat_mode = current_mode
      end
    end
  end
  local mode_row = yaw_state.mode_stats[stat_mode] or
    { hits = 0, misses = 0, correction = 0 }
  yaw_state.mode_stats[stat_mode] = mode_row
  if reason ~= nil then
    mode_row.misses = (mode_row.misses or 0) + 1
    yaw_state.population.misses = (yaw_state.population.misses or 0) + 1
    local mode_reason =
        tostring(reason):lower():gsub("^%s+", ""):gsub("%s+$", "")
    if mode_reason == "correction" then
      local ack_spread = tonumber(event.spread)
      if ack_spread == nil or ack_spread < t3.max_learning_spread then
        mode_row.correction = (mode_row.correction or 0) + 1
      end
    end
    yaw_state:guard(yaw_state.log_miss_ack, event, shot)
  else
    mode_row.hits = (mode_row.hits or 0) + 1
    yaw_state.ack_stats.hits = (yaw_state.ack_stats.hits or 0) + 1
    yaw_state.population.hits = (yaw_state.population.hits or 0) + 1
  end
  local pop = yaw_state.population
  pop.acks = (pop.acks or 0) + 1
  if shot then
    pop.correlated = (pop.correlated or 0) + 1
  end
  if shot and shot.active and shot.epoch == self.epoch and not self.suspended and
    not self.fault then
    pop.matched = (pop.matched or 0) + 1
  end
  local hit_bucket =
      (shot and type(shot.yaw_bucket) == "string") and shot.yaw_bucket or ""
  if hit_bucket ~= "" then
    local brow = yaw_state.bucket_stats[hit_bucket] or { h = 0, m = 0 }
    yaw_state.bucket_stats[hit_bucket] = brow
    if reason == nil then
      brow.h = (brow.h or 0) + 1
    else
      brow.m = (brow.m or 0) + 1
    end
    local dkey =
        tostring((shot and shot.yaw_band) or "?") .. "/" .. shot_side(shot)
    local drow = yaw_state.delta_stats[hit_bucket] or {}
    yaw_state.delta_stats[hit_bucket] = drow
    local cell = drow[dkey] or { h = 0, m = 0 }
    drow[dkey] = cell
    if reason == nil then
      cell.h = (cell.h or 0) + 1
    else
      cell.m = (cell.m or 0) + 1
    end
  end
  yaw_state.miss_state.bucket_stats = yaw_state.bucket_stats
  yaw_state.miss_state.delta_stats = yaw_state.delta_stats
  yaw_state.miss_state.population = yaw_state.population
  yaw_state.miss_state.mode_stats = yaw_state.mode_stats
  if not id or not shot or not shot.active or shot.epoch ~= self.epoch or
    self.suspended or self.fault then
    return
  end
  local t = game_time()
  if t < shot.time or t - shot.time > aim_ack_stats.shot_age then
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
    s.correction_since = nil
    s.risks.resolver = nil
    s.risks.resolver_probe = nil
    return
  end
  local reason_key =
      tostring(reason):lower():gsub("^%s+", ""):gsub("%s+$", "")
  if reason_key == "correction" and shot.resolver and
    item_enabled(app.resolver) and item_enabled(app.assist) then
    if not s.correction_since or t - s.correction_since > aim_ack_stats.correction_window then
      s.corrections, s.correction_since = 0, t
    end
    s.corrections = s.corrections + 1
    self.correction_signals = self.correction_signals + 1
    yaw_state:guard(yaw_state.note_miss, ent)
    if s.corrections == 1 then
      self:mark(s, "resolver_probe", "first exact correction miss", 0.45)
    end
    if s.corrections >= 2 then
      self:mark(
          s,
          "resolver",
          "repeated correction misses",
          aim_ack_stats.assist_duration)
      s.corrections, s.correction_since = 0, nil
    end
  elseif (reason_key == "prediction error" or reason_key == "misprediction" or
    reason_key == "backtrack failure") and shot.defensive then
    if self:mark(
          s,
          "defensive",
          "native shot timing / prediction failure",
          0.6) then
      self.defensive_signals = self.defensive_signals + 1
    end
  end
end
yaw_state_table.player_left = function(self, event)
  local ok, uid = pcall(function()
    return finite(event.userid)
  end)
  if not ok or not uid then
    return
  end
  if uid == self.local_uid then
    self:reset("local player death/disconnect")
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
  native_api:request("safe", nil)
end
yaw_state_table.status = function(self, force)
  local t = game_time()
  if not force and self.status_at >= 0 and t - self.status_at < 0.25 then
    return self.status_cache
  end
  self.status_at = t
  local slot = native_api.slots.safe
  self.status_cache = string.format("Assist %s | Safe Points %s | plan: %s", (item_enabled(app.resolver) and item_enabled(app.assist)) and "ON" or
    "OFF", tostring((slot and slot.state) or "unavailable"), tostring(self.plan or "-"))
  return self.status_cache
end
yaw_state_table.frame = function(self)
  local t = game_time()
  if t < self.last_clock then
    self:reset("clock reset")
  end
  self.last_clock = t
  if t >= self.last_frame and t - self.last_frame < 0.1 then
    return
  end
  self.last_frame = t
  native_api:retry_bind()
  if not self:ensure_context() or not self.last_step or
    t - self.last_step > aim_ack_stats.command_watchdog then
    native_api:request("safe", nil)
    if self.in_session then
      self.plan = "idle command watchdog; safety request released"
    end
  else
    self:plan_safety(false)
  end
  self:trim()
  self:status()
end
yaw_state_table.guard = function(self, method, ...)
  local ok, err = pcall(method, self, ...)
  if not ok then
    self.fault = "safety coordinator error; safety request released"
    self.fault_until = game_time() + 5
    native_api:release("safe")
    log_once(
         "coordinator_fault",
         self.fault .. ": " .. tostring(err):gsub("%c", " "))
    self:status(true)
  end
end
yaw_state_table.install = function(self)
  local handlers = { { "net_update_end", function()
    self:guard(self.net_update)
    yaw_state:guard(yaw_state.update)
  end }, { "createmove", function(cmd)
    aspect_presets:guard(aspect_presets.sync)
    f1(cmd)
    self:guard(self.step, cmd)
    native_api.EX:guard(native_api.EX.tick, cmd)
    clantag_state:guard(clantag_state.step, cmd)
    extrapolation_status:guard(extrapolation_status.tick, cmd)
  end }, { "aim_fire", function(event)
    aspect_presets:guard(aspect_presets.fire, event)
    self:guard(self.fire, event)
    clantag_state:guard(clantag_state.on_shot, event)
    yaw_state:guard(yaw_state.on_shot, event)
  end }, { "aim_ack", function(event)
    self:guard(self.ack, event)
    yaw_state:guard(yaw_state.on_ack, event)
  end }, { "round_start", function()
    self:guard(self.reset, "round start")
    clantag_state:reset()
    yaw_state:guard(yaw_state.reset_angel_all)
  end }, { "level_init", function()
    self:guard(self.reset, "map / connection changed")
    clantag_state:reset()
    yaw_state:guard(yaw_state.reset_angel_all)
  end }, { "player_death", function(event)
    self:guard(self.player_left, event)
    yaw_state:guard(yaw_state.reset_angel_event, event, true)
  end }, { "player_spawn", function(event)
    yaw_state:guard(yaw_state.reset_angel_event, event, false)
  end }, { "player_disconnect", function(event)
    self:guard(self.player_left, event)
  end } }
  self.hooks = {}
  for _, h in ipairs(handlers) do
    self.hooks[h[1]] = on_event(h[1], h[2])
  end
  self.ready = self.hooks.createmove and self.hooks.net_update_end and
    self.hooks.aim_fire and self.hooks.aim_ack
  clantag_state.ready =
      clantag_state.api_ready and self.hooks.createmove and self.hooks.aim_fire
  aspect_presets.shot_hook = self.hooks.aim_fire
  if not clantag_state.ready then
    app.unsafe_recharge:set(false)
    app.unsafe_recharge:disabled(true)
    noop(
        app.unsafe_recharge,
        "Unavailable: Double Tap API / required move or shot hook is missing.")
  end
  app.resolver:set_callback(function()
    self:guard(self.reset, "resolver master changed")
  end)
  app.extrapolation:set_callback(function()
    self:guard(self.reset, "feature settings changed")
  end)
  app.report:set_callback(function()
    aspect_presets.scan_at = -1
    aspect_presets:guard(aspect_presets.scan)
    aspect_presets:guard(aspect_presets.sync)
    local s = native_api.slots.safe
    local function f1(ref)
      local ok, base, override = native_api:read(ref)
      return ok and ("base=" .. tostring(base) .. " override=" ..
        tostring(override) .. " effective=" .. tostring(native_api:effective(ref))) or "unavailable"
    end
    local _, context_reason = self:context()
    self:say("REPORT | Alpha ControlFix 2 / TextUI | in_game=" .. tostring(aspect_presets.in_game) .. " alive=" .. tostring(aspect_presets.alive) .. " native master=" .. tostring(native_api:master_enabled()) .. " | context=" ..
      tostring(context_reason or "live") .. " | processed net=" .. self.net_count .. " cmd=" .. self.command_count, true)
    self:say("REPORT | Emberlight Assist=" .. tostring(item_enabled(app.assist)) .. " | Yaw=" .. tostring(item_enabled(app.yaw)) .. " | Defensive=always armed | Yaw Status=" ..
      tostring(yaw_state.last_status), true)
    self:say("REPORT | " .. tostring(self:status(true)), true)
    self:say("REPORT | Yaw writes=" .. yaw_state.writes .. " blocked=" ..
      yaw_state.blocked .. " mode=" .. tostring(yaw_state.mode) .. " brute idx=" .. yaw_state.brute, true)
    self:say("REPORT | Safe Points " .. f1(s.ref) .. " | " .. s.state .. " | set=" ..
      s.applied .. " clear=" .. s.released .. " conflicts=" .. s.conflicts, true)
    self:say("REPORT | Safety plan=" .. tostring(self.plan) .. " | Defensive alerts=" ..
      self.defensive_signals .. " correction signals=" .. self.correction_signals, true)
    self:say("REPORT | Extrapolation simulations=" ..
      self.simulated .. " skips=" .. self.simulation_skips .. " | " .. self.prediction_state, true)
    local srv_tick, srv_source = self:server_tick()
    local srv_info = self:dead_time()
    self:say("REPORT | ServerTick=" .. (srv_tick and tostring(srv_tick) or "?") .. " source=" .. tostring(srv_source) .. " time=" .. (srv_tick and self:to_time(srv_tick) and
      string.format("%.4f", self:to_time(srv_tick)) or "?") .. " | bands soft=" .. aim_ack_stats.lag_soft .. "s hard=" .. aim_ack_stats.lag_hard .. "s | dead=" .. (srv_info and
      (srv_info.time and string.format("%.4f", srv_info.time) or "?") or "?") .. " lat=" .. (srv_info and srv_info.latency and
      string.format("%.4f", srv_info.latency) or "?") .. " unlag=" .. (srv_info and srv_info.max_unlag and
      string.format("%.3f", srv_info.max_unlag) or "?"), true)
    local fl_ok, fl_val = false, nil
    if native_api.fake_latency_ref then
      fl_ok, fl_val = native_api:read(native_api.fake_latency_ref)
    end
    local ping_ms = 0
    local ok_lat, lat = pcall(function()
      return net.avg_latency and net.avg_latency[0]
    end)
    if ok_lat and finite(lat) then
      ping_ms = lat * 1000
    end
    self:say("REPORT | Extrap cfg: on=" .. tostring(item_enabled(app.extrapolation)) .. " auto=" .. tostring(item_enabled(app.extrapolation_auto)) .. " include_fl=" .. tostring(item_enabled(app.extrapolation_fake_latency)) .. " rewrite=" .. tostring(item_enabled(app.extrapolation_rewrite)) .. " | slider=" .. tostring(
         app.extrapolation_ticks and app.extrapolation_ticks:get() or "?") .. " | ping_ms=" .. string.format("%.0f", ping_ms) .. " | native FL ref=" .. tostring(native_api.fake_latency_ref ~= nil) .. " value=" ..
      (fl_ok and tostring(fl_val) or "unavailable") .. " | fl_ticks=" .. native_api:fake_latency_ticks(), true)
    self:say("REPORT | ForceShot switch=" .. tostring(item_enabled(app.forceshot)) .. " | " ..
      tostring((type(extrapolation_status) == "table" and extrapolation_status.state) or "?") .. " | forced=" .. tostring((type(extrapolation_status) == "table" and extrapolation_status.count) or 0), true)
    local charge = clantag_state:charge()
    self:say("REPORT | Recharge switch=" .. tostring(item_enabled(app.unsafe_recharge)) .. " ready=" .. tostring(clantag_state.ready) .. " DT=" .. tostring(native_api:effective(clantag_state.dt)) .. " charge=" ..
      (charge and string.format("%.1f%%", charge * 100) or "unknown") .. " | " .. clantag_state.state, true)
    self:say("REPORT | Recharge shot_events=" .. clantag_state.shot_events .. " attempts=" .. clantag_state.attempts .. " requests=" .. clantag_state.requests .. " observed_full=" .. clantag_state.observed_full .. " timeouts=" ..
      clantag_state.timeouts .. " expired=" .. clantag_state.expired .. " | " .. clantag_state.last_result, true)
  end)
  self:status(true)
end
yaw_state_table:install()
app.sidebar_gradient = nil
pcall(function()
  app.sidebar_gradient = require("neverlose/gradient")
end)
local n2 = -1
local interp_length = nil
local function tick_banner()
  local now = game_time()
  if now >= n2 and now - n2 < 0.04 then
    return
  end
  n2 = now
  local selected, selected_score = nil, -1
  for rank, style_name in ipairs(
       { "Link Active", "Accent", "Text Active", "Button Active", "Active" }) do
    local ok, value = pcall(ui.get_style, style_name)
    if ok and value and finite(tonumber(value.r)) and finite(tonumber(value.g)) and
      finite(tonumber(value.b)) then
      selected, selected_score = value, 200 - rank
      break
    end
  end
  if not selected then
    local ok, styles = pcall(ui.get_style)
    if ok and type(styles) == "table" then
      for style_name, value in pairs(styles) do
        if value and finite(tonumber(value.r)) and finite(tonumber(value.g)) and
          finite(tonumber(value.b)) then
          local key = tostring(style_name):lower()
          local score = key:find("link active", 1, true) and 120 or
            key:find("accent", 1, true) and 110 or key:find("active", 1, true) and 90 or key:find("link", 1, true) and 70 or 10
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
  local display_name = menu_label
  local hex = nil
  if selected then
    pcall(function()
      hex = selected:to_hex()
    end)
    if type(hex) ~= "string" or #hex < 8 then
      hex = string.format(
              "%02X%02X%02X%02X",
              tonumber(selected.r) or 255,
              tonumber(selected.g) or 255,
              tonumber(selected.b) or 255,
              tonumber(selected.a) or 255)
    end
  end
  hex = type(hex) == "string" and hex:sub(1, 8):upper() or nil
  if hex == interp_length and not (app.sidebar_gradient and app.sidebar_gradient.text) then
    return
  end
  interp_length = hex
  local title = hex and
    (string.char(7) .. hex .. display_name .. string.char(7) .. "DEFAULT") or display_name
  if selected and app.sidebar_gradient and app.sidebar_gradient.text then
    local colors = {}
    for i = 1, 5 do
      local wave = (math.sin(now * 4.6 + (i - 1) * 1.3) + 1) * 0.5
      local lift = 0.06 + wave * 0.4
      local r = math.floor((tonumber(selected.r) or 255) +
        (255 - (tonumber(selected.r) or 255)) * lift + 0.5)
      local g = math.floor((tonumber(selected.g) or 255) +
        (255 - (tonumber(selected.g) or 255)) * lift + 0.5)
      local b = math.floor((tonumber(selected.b) or 255) +
        (255 - (tonumber(selected.b) or 255)) * lift + 0.5)
      colors[i] = color(
          clamp(r, 0, 255),
          clamp(g, 0, 255),
          clamp(b, 0, 255),
          tonumber(selected.a) or 255)
    end
    local ok, value = pcall(function()
      return app.sidebar_gradient.text(display_name, false, colors)
    end)
    if ok and type(value) == "string" and value ~= "" then
      title = value
    end
  end
  pcall(function()
    ui.sidebar(title, "meteor")
  end)
end
tick_banner()
local function clean_err(value)
  return tostring(value):gsub("%c", " "):sub(1, 120)
end
local function safe_call(key, fn)
  local ok, err = pcall(fn)
  if not ok then
    log_once(key, key .. ": " .. clean_err(err))
  end
end
local avg_last_time = -1
local avg_band = nil
local function apply_interp_off()
  if not avg_band then
    return
  end
  pcall(function()
    if cvar.cl_interpolate then
      cvar.cl_interpolate:int(avg_band[1])
    end
  end)
  pcall(function()
    if cvar.cl_interp_ratio then
      cvar.cl_interp_ratio:int(avg_band[2])
    end
  end)
  pcall(function()
    if cvar.cl_interp then
      cvar.cl_interp:float(avg_band[3])
    end
  end)
  avg_band = nil
end
local function tick_extrapolation()
  if not item_enabled(app.extrapolation) then
    apply_interp_off()
    return
  end
  pcall(function()
    app.interpolation:set(true)
    app.interpolation:visibility(false)
  end)
  if not avg_band then
    local a, b, c = 1, 2, 0.015625
    pcall(function()
      if cvar.cl_interpolate then
        a = cvar.cl_interpolate:int()
      end
    end)
    pcall(function()
      if cvar.cl_interp_ratio then
        b = cvar.cl_interp_ratio:int()
      end
    end)
    pcall(function()
      if cvar.cl_interp then
        c = cvar.cl_interp:float()
      end
    end)
    avg_band = { a, b, c }
  end
  local interval = finite(globals and globals.tickinterval) or 0.015625
  interval = clamp(interval, 0.0078125, 0.03125)
  pcall(function()
    if cvar.cl_interpolate then
      cvar.cl_interpolate:int(1)
    end
  end)
  pcall(function()
    if cvar.cl_interp_ratio then
      cvar.cl_interp_ratio:int(1)
    end
  end)
  pcall(function()
    if cvar.cl_interp then
      cvar.cl_interp:float(interval)
    end
  end)
end
local mc_ok, mc_error, model_changer_map_reset = (
  function()
  local models = _G.__EMBERLIGHT_MODEL_PATHS or {}
  local initialized, unavailable = false, false
  local ffi, class_ptr, model_info, string_tables
  local get_model_index, find_or_load_model, find_table
  local precached, original_index, original_entity = {}, nil, nil
  local refresh_token = tonumber(_G.__EMBERLIGHT_MODEL_REFRESH_TOKEN) or 0
  local function f1(module, name)
    if not utils or type(utils.create_interface) ~= "function" then
      return nil
    end
    local ok, ptr = pcall(utils.create_interface, module, name)
    return ok and ptr or nil
  end
  local function f2()
    if initialized then
      return true
    end
    if unavailable then
      return false
    end
    local ok, err = pcall(function()
      ffi = require("ffi")
      pcall(
          ffi.cdef,
          "        typedef struct { void* fnHandle; char szName[260]; int nLoadFlags; int nServerCount; int type; int flags; float vecMins[3]; float vecMaxs[3]; float radius; char pad[0x1C]; } ember_model_t;\n        typedef int(__thiscall* ember_get_model_index_t)(void*, const char*);\n        typedef const ember_model_t(__thiscall* ember_find_or_load_model_t)(void*, const char*);\n        typedef int(__thiscall* ember_add_string_t)(void*, bool, const char*, int, const void*);\n        typedef void*(__thiscall* ember_find_table_t)(void*, const char*);\n      ")
      class_ptr = ffi.typeof("void***")
      local raw_model = f1("engine.dll", "VModelInfoClient004")
      local raw_tables = f1("engine.dll", "VEngineClientStringTable001")
      if not raw_model or not raw_tables then
        error("required engine interface unavailable")
      end
      model_info = ffi.cast(class_ptr, raw_model)
      string_tables = ffi.cast(class_ptr, raw_tables)
      get_model_index =
          ffi.cast("ember_get_model_index_t", model_info[0][2])
      find_or_load_model =
          ffi.cast("ember_find_or_load_model_t", model_info[0][39])
      find_table = ffi.cast("ember_find_table_t", string_tables[0][3])
      if not get_model_index or not find_or_load_model or not find_table then
        error("model functions unavailable")
      end
    end)
    initialized = ok
    unavailable = not ok
    if not ok then
      log_once(
          "model_changer_init",
          "Model Changer unavailable: " .. tostring(err))
    end
    return initialized
  end
  local function f3(name)
    local selected = {}
    pcall(function()
      selected = app.model_changer_team:get() or {}
    end)
    for _, value in ipairs(selected) do
      if value == name then
        return true
      end
    end
    return false
  end
  local function f4(path)
    if precached[path] then
      return true
    end
    local ok, result = pcall(function()
      local raw = find_table(string_tables, "modelprecache")
      if raw == nil then
        return false
      end
      local table_ptr = ffi.cast(class_ptr, raw)
      local add_string = ffi.cast("ember_add_string_t", table_ptr[0][8])
      if add_string == nil then
        return false
      end
      find_or_load_model(model_info, path)
      return add_string(table_ptr, false, path, -1, nil) ~= -1
    end)
    if ok and result then
      precached[path] = true
      return true
    end
    return false
  end
  local function f5(ent, model_index)
    if not ent or model_index == nil then
      return false
    end
    local ok = pcall(function()
      ent.m_nModelIndex = model_index
    end)
    if not ok then
      ok = pcall(function()
        ent.m_nModelIndex = model_index
      end)
    end
    return ok
  end
  local function f6()
    if original_index ~= nil then
      local me = entity.get_local_player()
      if me then
        local idx = nil
        pcall(function()
          idx = me:get_index()
        end)
        if idx == original_entity then
          f5(me, original_index)
        end
      end
    end
    original_index, original_entity = nil, nil
  end
  local applied_path, applied_index = nil, nil
  local function f7()
    f6()
    precached, original_index, original_entity = {}, nil, nil
    applied_path, applied_index = nil, nil
    initialized, unavailable = false, false
    model_info, string_tables, get_model_index, find_or_load_model, find_table =
        nil,
        nil,
        nil,
        nil,
        nil
  end
  local function f8()
    local token = tonumber(_G.__EMBERLIGHT_MODEL_REFRESH_TOKEN) or 0
    if token ~= refresh_token then
      refresh_token = token
      precached, applied_path, applied_index = {}, nil, nil
    end
    if not app.model_changer_available or not item_enabled(app.model_changer) then
      if original_index ~= nil then
        f6()
      end
      applied_path, applied_index = nil, nil
      return
    end
    if not f2() then
      return
    end
    local me = entity.get_local_player()
    if not me then
      f6()
      applied_path, applied_index = nil, nil
      return
    end
    local entity_index, team
    pcall(function()
      entity_index = me:get_index()
      team = tonumber(me.m_iTeamNum)
    end)
    if not entity_index or (team ~= 2 and team ~= 3) then
      f6()
      return
    end
    local team_name = team == 2 and "T" or "CT"
    if not f3(team_name) then
      if original_index ~= nil then
        f6()
      end
      applied_path, applied_index = nil, nil
      return
    end
    if original_entity ~= entity_index then
      f6()
      original_entity = entity_index
      pcall(function()
        original_index = tonumber(me.m_nModelIndex)
      end)
    end
    local choice
    pcall(function()
      choice =
          (team == 2 and app.model_changer_t or app.model_changer_ct):get()
    end)
    local path = models[choice]
    if not path then
      return
    end
    if applied_path ~= path then
      if not f4(path) then
        log_once(
            "model_changer_precache_" .. tostring(choice),
            "Model file missing or could not be precached: " .. path)
        return
      end
      local ok, index = pcall(get_model_index, model_info, path)
      if not ok or not tonumber(index) or index < 0 then
        log_once(
            "model_changer_index_" .. tostring(choice),
            "Model index unavailable: " .. path)
        return
      end
      applied_path, applied_index = path, tonumber(index)
    end
    if applied_index then
      f5(me, applied_index)
      pcall(function()
        me.m_nSkin = 0
      end)
      pcall(function()
        me.m_nBody = 0
      end)
      pcall(function()
        me.m_nHitboxSet = 0
      end)
    end
  end
  return f8, f6, f7
end
)()
on_event("level_init", function()
  safe_call("model_changer_map_reset", model_changer_map_reset)
  if item_enabled(app.model_changer) then
    utils.execute_after(2, function()
      safe_call("model_changer_map_reload", mc_ok)
    end)
  end
end)
on_event("pre_render", function()
  safe_call("model_changer_pre_render", mc_ok)
end)
on_event("net_update_end", function()
  if item_enabled(app.model_changer) then
    safe_call("model_changer_net_update", mc_ok)
  end
end)
local optimizer_render = (
  function()
  local PIXEL_FONT = 2
  local alpha, scope_align = 0, 1
  local bind_rows = {}
  local bind_order = {
    DT = 1,
    HS = 2,
    DMG = 3,
    HC = 4,
    BAIM = 5,
    SAFE = 6,
    DUCK = 7,
    PING = 8,
    DA = 9,
  }
  local function f1(text)
    local ok, size =
        pcall(render.measure_text, PIXEL_FONT, "s", tostring(text))
    if not ok or not size then
      ok, size = pcall(render.measure_text, PIXEL_FONT, nil, tostring(text))
    end
    return ok and size or vector(#tostring(text) * 6, 10)
  end
  local function f2(value)
    return app.version_state.clean_bind_name(value)
  end
  local function f3(name)
    local n = f2(name)
    local key = n:lower():gsub("[%s%-%._]", "")
    if key:find("doubletap", 1, true) or key:find("rapidfire", 1, true) then
      return "DT"
    end
    if key:find("hideshot", 1, true) then
      return "HS"
    end
    if key:find("minimumdamage", 1, true) or key:find("mindamage", 1, true) then
      return "DMG"
    end
    if key:find("hitchance", 1, true) then
      return "HC"
    end
    if key:find("bodyaim", 1, true) then
      return "BAIM"
    end
    if key:find("safepoint", 1, true) then
      return "SAFE"
    end
    if key:find("fakeduck", 1, true) then
      return "DUCK"
    end
    if key:find("fakelatency", 1, true) then
      return "PING"
    end
    if key:find("dormant", 1, true) then
      return "DA"
    end
    n = n:upper()
    return #n > 16 and n:sub(1, 16) or n
  end
  local function f4(dt)
    local seen = {}
    local ok, list = pcall(ui.get_binds)
    if ok and type(list) == "table" then
      for _, bind in ipairs(list) do
        local active = false
        pcall(function()
          active = bind.active == true
        end)
        if active then
          local label_with_icon = f3(bind.name)
          if label_with_icon ~= "" and label_with_icon ~= "CROSSHAIR INDICATOR" then
            seen[label_with_icon] = true
            if not bind_rows[label_with_icon] then
              bind_rows[label_with_icon] =
                  { text = label_with_icon, alpha = 0 }
            end
          end
        end
      end
    end
    for label_with_icon, row in pairs(bind_rows) do
      local target = seen[label_with_icon] and 1 or 0
      row.alpha = row.alpha + (target - row.alpha) * math.min(1, dt * 12)
      if row.alpha < 0.005 and not seen[label_with_icon] then
        bind_rows[label_with_icon] = nil
      end
    end
    local out = {}
    for _, row in pairs(bind_rows) do
      out[#out + 1] = row
    end
    table.sort(out, function(a, b)
      local oa, ob = bind_order[a.text] or 100, bind_order[b.text] or 100
      if oa ~= ob then
        return oa < ob
      end
      return a.text < b.text
    end)
    return out
  end
  local function f5()
    local ok, c = pcall(function()
      return app.crosshair_indicator_color:get()
    end)
    return ok and c or color(185, 190, 255, 255)
  end
  local function f6(me)
    if not me then
      return "STANDING"
    end
    local flags, duck, vx, vy = 1, 0, 0, 0
    pcall(function()
      flags = tonumber(me.m_fFlags) or 1
    end)
    pcall(function()
      duck = tonumber(me.m_flDuckAmount) or 0
    end)
    pcall(function()
      local v = me.m_vecVelocity
      if v then
        vx, vy = tonumber(v.x) or 0, tonumber(v.y) or 0
      end
    end)
    if flags % 2 == 0 then
      return "AIR"
    end
    if duck > 0.65 then
      return "CROUCH"
    end
    if math.sqrt(vx * vx + vy * vy) > 8 then
      return "MOVING"
    end
    return "STANDING"
  end
  local function f7(text, y, c, align, xoff)
    local size = f1(text)
    local x =
        render.screen_size().x * 0.5 - size.x * 0.5 * (align or 1) + (xoff or 0)
    render.text(PIXEL_FONT, vector(x, y), c, "s", text)
    return size.y
  end
  local function f8()
    local dt = 0.016
    pcall(function()
      dt = math.min(0.05, math.max(0.001, globals.frametime))
    end)
    local target = item_enabled(app.crosshair_indicator) and 1 or 0
    alpha = alpha + (target - alpha) * math.min(1, dt * 12)
    if alpha < 0.01 then
      return
    end
    local me = entity.get_local_player()
    local alive = false
    pcall(function()
      alive = me and me:is_alive()
    end)
    if not alive then
      return
    end
    local scoped = false
    pcall(function()
      scoped = me.m_bIsScoped == true
    end)
    scope_align =
        scope_align + ((scoped and 0 or 1) - scope_align) * math.min(1, dt * 10)
    local ac = f5()
    local ar, ag, ab, aa = ac:unpack()
    aa = aa or 255
    local pulse = math.max(0.2, math.abs(math.sin(game_time() * 2.5)))
    local base_a = math.floor(255 * alpha)
    local xoff = (1 - scope_align) * 18
    local screen = render.screen_size()
    local y = screen.y * 0.5 + 20
    local brand = "EMBERLIGHT "
    local edition = "BETA"
    local title = brand .. edition
    local ts = f1(title)
    local tx = screen.x * 0.5 - ts.x * 0.5 * scope_align + xoff
    if item_enabled(app.crosshair_indicator_shadow) then
      pcall(
          render.shadow,
          vector(tx, y + ts.y * 0.55),
          vector(tx + ts.x - 1, y + ts.y * 0.55),
          color(ar, ag, ab, math.floor(120 * alpha)),
          20,
          0,
          0)
    end
    render.text(
            PIXEL_FONT,
            vector(tx, y),
            color(255, 255, 255, base_a),
            "s",
            brand)
    local first = f1(brand)
    render.text(
            PIXEL_FONT,
            vector(tx + first.x, y),
            color(ar, ag, ab, math.floor(aa * alpha * pulse)),
            "s",
            edition)
    y = y + ts.y - 4
    local state = f6(me)
    f7(
        state,
        y,
        color(ar, ag, ab, math.floor(aa * alpha)),
        scope_align,
        xoff)
    y = y + f1(state).y - 4
    local rows = f4(dt)
    local offset = 0
    for _, row in ipairs(rows) do
      if row.alpha > 0.01 then
        f7(
            row.text,
            y + offset,
            color(ar, ag, ab, math.floor(aa * alpha * row.alpha)),
            scope_align,
            xoff)
        offset = offset + (f1(row.text).y - 4) * row.alpha
      end
    end
  end
  return f8
end
)()
local crosshair_render = (
  function()
  local alpha, ref, last_find = 0, nil, -100
  local pos = _G.__EMBERLIGHT_DAMAGE_POS or {
    x = nil,
    y = nil,
    drag = false,
    was_left = false,
    was_right = false,
    dx = 0,
    dy = 0,
  }
  local museo
  local function f1()
    if ref then
      return ref
    end
    if game_time() - last_find < 2 then
      return nil
    end
    last_find = game_time()
    local paths = {
      { "Aimbot", "Ragebot", "Selection", "Minimum Damage" },
      { "Aimbot", "Ragebot", "Selection", "Min. Damage" },
      { "Aimbot", "Ragebot", "Accuracy", "Minimum Damage" },
      { "Aimbot", "Ragebot", "Main", "Minimum Damage" },
      { "Aimbot", "Ragebot", "Minimum Damage" },
    }
    for _, p in ipairs(paths) do
      local ok, r = pcall(ui.find, p[1], p[2], p[3], p[4])
      if ok and r then
        local rok = pcall(function()
          r:get()
        end)
        if rok then
          ref = r
          return ref
        end
      end
    end
  end
  local function f2()
    local r = f1()
    if not r then
      return 0
    end
    local ok, v = pcall(function()
      return r:get()
    end)
    if not ok then
      ref = nil
      return 0
    end
    if type(v) == "number" then
      return v
    end
    return tonumber(v) or 0
  end
  local function f3()
    local name = "Pixel"
    pcall(function()
      name = app.damage_indicator_font:get()
    end)
    if name == "Default" then
      return 1
    end
    if name == "Bold" then
      return 4
    end
    if name == "Museo Sans" then
      if not museo then
        local ok, f = pcall(function()
          if render.safe_load_font then
            return render.safe_load_font("museo500", 15, "a")
          end
          return render.load_font("Arial", 15, "a")
        end)
        museo = ok and f or 1
      end
      return museo
    end
    return 2
  end
  local function f4()
    local dt = 0.016
    pcall(function()
      dt = math.min(0.05, math.max(0.001, globals.frametime))
    end)
    local v1 = item_enabled(app.crosshair_indicator) and
      item_enabled(app.damage_indicator)
    local me = entity.get_local_player()
    local alive = false
    pcall(function()
      alive = me and me:is_alive()
    end)
    local target = v1 and alive and 1 or 0
    alpha = alpha + (target - alpha) * math.min(1, dt * 12)
    if alpha < 0.01 then
      return
    end
    local screen = render.screen_size()
    if not pos.x then
      pos.x = screen.x * 0.5 + 5
      pos.y = screen.y * 0.5 - 22
    end
    local v2 = f3()
    local dmg = f2()
    local text = dmg == 0 and "AUTO" or tostring(math.floor(dmg + 0.5))
    local ok, sz = pcall(render.measure_text, v2, "s", text)
    if not ok or not sz then
      sz = vector(#text * 7, 12)
    end
    local w, h = math.max(20, sz.x + 8), math.max(20, sz.y + 8)
    local menu = false
    pcall(function()
      menu = (ui.get_alpha() or 0) > 0.01
    end)
    local mouse
    pcall(function()
      mouse = ui.get_mouse_position()
    end)
    local left, right = false, false
    pcall(function()
      left = common.is_button_down(1) == true
      right = common.is_button_down(2) == true
    end)
    local hover = mouse and mouse.x >= pos.x and mouse.x <= pos.x + w and mouse.y >= pos.y and
      mouse.y <= pos.y + h
    if menu and hover and left and not pos.was_left then
      pos.drag = true
      pos.dx = mouse.x - pos.x
      pos.dy = mouse.y - pos.y
    end
    if pos.drag and left and mouse then
      pos.x = clamp(mouse.x - pos.dx, 0, screen.x - w)
      pos.y = clamp(mouse.y - pos.dy, 0, screen.y - h)
    end
    if not left then
      pos.drag = false
    end
    if menu and hover and right and not pos.was_right then
      pos.x = screen.x * 0.5 + 5
      pos.y = screen.y * 0.5 - 22
    end
    pos.was_left, pos.was_right = left, right
    _G.__EMBERLIGHT_DAMAGE_POS = pos
    local c = color(255, 255, 255, 255)
    pcall(function()
      c = app.damage_indicator_color:get()
    end)
    local r, g, b, a = c:unpack()
    a = math.floor((a or 255) * alpha)
    render.text(
            v2,
            vector(pos.x + w * 0.5, pos.y + h * 0.5),
            color(r, g, b, a),
            "cs",
            text)
  end
  return f4
end
)()
local he_ok, hit_effect_clear = (
  function()
  local damage_items, cs2_particles = {}, {}
  local hit_font
  local spark_ready, spark_failed, spark_fn, spark_vec, spark_angle, spark_material
  local function f1(item)
    return item_enabled(app.hit_effect) and item_enabled(item)
  end
  local function f2(value)
    local ok, ent = pcall(entity.get, value, true)
    return ok and ent or nil
  end
  local function f3(e)
    local me = entity.get_local_player()
    if not me then
      return nil, nil
    end
    local payload = type(e) == "table" and e or {}
    local attacker = f2(payload.attacker or payload.userid)
    if attacker ~= me then
      return nil, me
    end
    return attacker, me
  end
  local function f4()
    local ok, mode = pcall(function()
      return app.effects_mode:get()
    end)
    return ok and mode or "CSGO"
  end
  local function f5()
    if spark_ready then
      return true
    end
    if spark_failed then
      return false
    end
    local ok, result = pcall(function()
      local ffi = require("ffi")
      pcall(
          ffi.cdef,
          "        typedef struct { float x; float y; float z; } EmberHitVector;\n        typedef void(__fastcall* EmberSparkFn)(const EmberHitVector*, int, int, const EmberHitVector*);\n      ")
      local address = utils.opcode_scan(
                  "client.dll",
                  "55 8B EC 83 EC 3C 53 8B D9 89 55 FC 8B 0D ?? ?? ?? ?? 56 57")
      if not address then
        error("spark signature unavailable")
      end
      spark_fn = ffi.cast("EmberSparkFn", address)
      spark_vec = ffi.new("EmberHitVector")
      spark_angle = ffi.new("EmberHitVector", { x = 0, y = 0, z = 0 })
      spark_material = materials.get("effects/spark", true)
      return spark_fn ~= nil
    end)
    spark_ready = ok and result == true
    spark_failed = not spark_ready
    return spark_ready
  end
  local function f6(x, y, z)
    if not f5() then
      return
    end
    spark_vec.x, spark_vec.y, spark_vec.z = x, y, z
    pcall(function()
      if spark_material and spark_material:is_valid() then
        spark_material:alpha_modulate(1)
        spark_material:color_modulate(color(190, 225, 255, 255))
      end
      spark_fn(spark_vec, 6, 4, spark_angle)
    end)
  end
  local function f7(x, y, z)
    local now = game_time()
    for i = 1, 22 do
      local a = math.random() * math.pi * 2
      local speed = 38 + math.random() * 88
      cs2_particles[#cs2_particles + 1] = {
        x = x,
        y = y,
        z = z,
        vx = math.cos(a) * speed,
        vy = math.sin(a) * speed,
        vz = 35 + math.random() * 95,
        born = now,
        life = 0.42 + math.random() * 0.48,
        size = 1.2 + math.random() * 2.4,
        line = (i % 3 == 0),
      }
    end
  end
  local function f8(e)
    if not f1(app.effects) then
      return
    end
    local payload = type(e) == "table" and e or {}
    local attacker = f2(payload.userid)
    local me = entity.get_local_player()
    if not me or attacker ~= me then
      return
    end
    local x, y, z = tonumber(payload.x), tonumber(payload.y), tonumber(payload.z)
    if not x or not y or not z then
      return
    end
    if f4() == "CS2" then
      f7(x, y, z)
    else
      f6(x, y, z)
    end
  end
  local function f9(e)
    if not f1(app.fortnite_hit) then
      return
    end
    local attacker, me = f3(e)
    if not attacker or not me then
      return
    end
    local victim = f2(payload.userid)
    if not victim or victim == me then
      return
    end
    local pos
    pcall(function()
      pos = victim:get_hitbox_position(0)
    end)
    if not pos then
      pcall(function()
        pos = victim:get_origin()
      end)
    end
    if not pos then
      return
    end
    local idx = victim:get_index()
    local now = game_time()
    local old = damage_items[idx]
    damage_items[idx] = { damage = (old and now - old.born < 0.32 and old.damage or 0) +
      (tonumber(payload.dmg_health) or 0),
      born = now,
      pos = pos,
      head = (tonumber(payload.hitgroup) or 0) == 1 }
  end
  local function f10()
    if hit_font then
      return hit_font
    end
    hit_font = load_verified_font(hit_font, 25, "abd")
    return hit_font
  end
  local function f11(now)
    if not f1(app.fortnite_hit) then
      damage_items = {}
      return
    end
    for idx, item in pairs(damage_items) do
      local age = now - item.born
      if age >= 1.15 then
        damage_items[idx] = nil
      else
        local p = render.world_to_screen(item.pos)
        if p then
          local t = math.min(1, age / 0.18)
          local fade =
              age < 0.72 and 1 or math.max(0, 1 - (age - 0.72) / 0.43)
          local bounce = math.sin(t * math.pi) * 20
          local text = tostring(math.floor(item.damage + 0.5))
          local c = item.head and color(255, 220, 45, math.floor(255 * fade)) or
            color(255, 255, 255, math.floor(255 * fade))
          local ok, sz = pcall(render.measure_text, f10(), nil, text)
          local w = ok and sz and sz.x or #text * 14
          render.text(
              f10(),
              vector(p.x - w / 2, p.y - 52 - bounce - age * 26),
              c,
              nil,
              text)
        end
      end
    end
  end
  local function f12(now, dt)
    if not f1(app.effects) or f4() ~= "CS2" then
      cs2_particles = {}
      return
    end
    for i = #cs2_particles, 1, -1 do
      local p = cs2_particles[i]
      local age = now - p.born
      if age >= p.life then
        table.remove(cs2_particles, i)
      else
        p.vz = p.vz - 150 * dt
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.z = p.z + p.vz * dt
        p.vx, p.vy = p.vx * 0.985, p.vy * 0.985
        local screen = render.world_to_screen(vector(p.x, p.y, p.z))
        if screen then
          local fade = math.max(0, 1 - age / p.life)
          local a = math.floor(230 * fade)
          local c = color(
              120 + math.floor(110 * fade),
              190 + math.floor(55 * fade),
              255,
              a)
          if p.line then
            render.line(
                vector(screen.x - 3 * fade, screen.y + 4 * fade),
                vector(screen.x + 3 * fade, screen.y - 4 * fade),
                c)
          else
            render.circle(screen, c, p.size * (0.55 + fade), 0, 1)
          end
        end
      end
    end
  end
  local last = game_time()
  local function f13()
    local now = game_time()
    local dt = math.min(0.05, math.max(0, now - last))
    last = now
    if not item_enabled(app.hit_effect) then
      damage_items, cs2_particles = {}, {}
      return
    end
    f11(now)
    f12(now, dt)
  end
  local function f14()
    damage_items, cs2_particles = {}, {}
  end
  on_event("player_hurt", f9)
  on_event("bullet_impact", f8)
  return f13, f14
end
)()
local header_color = color(185, 190, 255, 255)
local header_font_ok, emberlight_header_font = nil, nil
local function wm_font_style()
  local style = wm_style()
  if style == "Evalate" then
    return wm_accent()
  elseif style == "Neverlose" then
    local ok_c, c = pcall(function()
      return app.wm_nl_accent:get()
    end)
    if ok_c and c and finite(c.r) and finite(c.g) and finite(c.b) then
      return c
    end
  elseif style == "Gamesense" then
    local ok_c, c = pcall(function()
      return app.wm_accent:get()
    end)
    if ok_c and c and finite(c.r) and finite(c.g) and finite(c.b) then
      return c
    end
  end
  return header_color
end
local function wm_font_arial()
  if header_font_ok then
    return header_font_ok
  end
  local ok, f = pcall(render.load_font, "arial", vector(13, 11), "a")
  header_font_ok = ok and f or 2
  return header_font_ok
end
local function wm_font_fallback()
  if cached_font then
    return cached_font
  end
  local ok, f = pcall(render.load_font, "arial", 14, "ad")
  cached_font = ok and f or wm_font_arial()
  return cached_font
end
local function measure_text(text, a1)
  local ok, sz = pcall(
      render.measure_text,
      a1 or wm_font_arial(),
      nil,
      tostring(text or ""))
  if ok and sz then
    return tonumber(sz.x) or 0, tonumber(sz.y) or 12
  end
  return #tostring(text or "") * 7, 12
end
local function ui_visible()
  local ok, a = pcall(ui.get_alpha)
  return ok and type(a) == "number" and a > 0.01
end
local function mouse_pos()
  local ok, p = pcall(ui.get_mouse_position)
  if ok and p and finite(p.x) and finite(p.y) then
    return p.x, p.y
  end
end
local function mouse_down()
  local ok, v = pcall(common.is_button_down, 1)
  return ok and v == true
end
local function draw_circle(x, y, w, h, alpha, radius)
  alpha = clamp(alpha or 1, 0, 1)
  radius = radius or 12
  local v1 = wm_font_style()
  local inner_a = math.floor(65 * alpha)
  local glow = color(v1.r, v1.g, v1.b, inner_a)
  local ix = x + 12.5
  local iy = y + h / 2 - 1
  pcall(function()
    render.rect(vector(ix, iy), vector(x + w - 12.5, iy + 2), glow, radius)
  end)
  pcall(function()
    render.shadow(
              vector(ix, iy),
              vector(x + w - 12.5, iy + 2),
              color(v1.r, v1.g, v1.b, math.floor(255 * alpha)),
              70,
              0,
              radius)
  end)
  pcall(function()
    render.blur(vector(x, y), vector(x + w, y + h), 0, alpha, radius)
  end)
  render.rect(
            vector(x, y),
            vector(x + w, y + h),
            color(150, 150, 150, math.floor(40 * alpha)),
            radius)
  pcall(function()
    render.rect_outline(
                    vector(x, y),
                    vector(x + w, y + h),
                    color(255, 255, 255, math.floor(20 * alpha)),
                    1,
                    radius)
  end)
end
local function drag_box(box, x, y, w, h)
  local down = mouse_down()
  local mx, my = mouse_pos()
  if ui_visible() and down and not box.was and mx and mx >= x and mx <= x + w and
    my >= y and my <= y + h then
    box.drag = true
    box.dx = mx - x
    box.dy = my - y
  end
  if box.drag and down and mx then
    box.x = clamp(mx - box.dx, 0, render.screen_size().x - w)
    box.y = clamp(my - box.dy, 0, render.screen_size().y - h)
  end
  if not down then
    box.drag = false
  end
  box.was = down
  if box == _G.__EMBERLIGHT_HOTKEYS_POS then
    _G.__EMBERLIGHT_HOTKEYS_POS = {
      x = box.x,
      y = box.y,
      was = box.was,
      drag = box.drag,
      dx = box.dx,
      dy = box.dy,
    }
  end
end
local function clean_bind_name(v)
  return app.version_state.clean_bind_name(v)
end
local function is_indicator_bind(name)
  local n = tostring(name or ""):lower():gsub("[%s%-%._]", "")
  return n == "hitchance" or n == "hideshots"
end
local function collect_binds()
  local ok, list = pcall(ui.get_binds)
  if not ok or type(list) ~= "table" then
    return {}
  end
  local out = {}
  for _, bind in ipairs(list) do
    local active = false
    pcall(function()
      active = bind.active == true
    end)
    if active then
      local name = clean_bind_name(bind.name)
      local value = bind.value
      if type(value) == "table" then
        local q = {}
        for _, v in ipairs(value) do
          q[#q + 1] = tostring(v):sub(1, 1)
        end
        value = #q > 0 and table.concat(q, ", ") or ""
      end
      if type(value) == "boolean" then
        value = ({ [1] = "hold", [2] = "toggle" })[bind.mode] or "?"
      end
      if name ~= "" and not is_indicator_bind(name) then
        out[#out + 1] = { name = name, value = tostring(value or "") }
      end
    end
  end
  return out
end
local function lerp_ft(a, b, speed)
  local ft = clamp(finite(globals and globals.frametime) or 0.016, 0, 0.05)
  return a + (b - a) * (1 - math.exp(-speed * ft))
end
local hotkeys_pos = _G.__EMBERLIGHT_HOTKEYS_POS or
  { x = 300, y = 300, was = false, drag = false }
_G.__EMBERLIGHT_HOTKEYS_POS = hotkeys_pos
local hotkeys_state = { rows = {}, serial = 0, master = 0, width = 128 }
local function hotkey_source()
  local v1 = item_enabled(app.hotkeys)
  local source = v1 and collect_binds() or {}
  for _, r in pairs(hotkeys_state.rows) do
    r.target = 0
  end
  for order, row in ipairs(source) do
    local key = row.name:lower()
    local r = hotkeys_state.rows[key]
    if not r then
      hotkeys_state.serial = hotkeys_state.serial + 1
      r = {
        name = row.name,
        value = row.value,
        alpha = 0,
        target = 1,
        order = hotkeys_state.serial,
      }
      hotkeys_state.rows[key] = r
    end
    r.name, r.value, r.target, r.live_order = row.name, row.value, 1, order
  end
  local rows = {}
  for key, r in pairs(hotkeys_state.rows) do
    r.alpha = lerp_ft(r.alpha, r.target, 12)
    if r.target == 0 and r.alpha < 0.012 then
      hotkeys_state.rows[key] = nil
    else
      rows[#rows + 1] = r
    end
  end
  table.sort(rows, function(a, b)
    return (a.live_order or 999) < (b.live_order or 999) or
      ((a.live_order or 999) == (b.live_order or 999) and a.order < b.order)
  end)
  local should_show = v1 and (#rows > 0 or ui_visible())
  hotkeys_state.master = lerp_ft(hotkeys_state.master, should_show and 1 or 0, 10)
  if hotkeys_state.master < 0.01 then
    return
  end
  local content_w = 103
  for _, row in ipairs(rows) do
    local nw = measure_text(row.name)
    local vw = measure_text(row.value)
    content_w = math.max(content_w, nw + vw + 10)
  end
  hotkeys_state.width = lerp_ft(hotkeys_state.width, content_w + 25, 12)
  local final_w = hotkeys_state.width
  local header_h = 25
  local body_y = 30
  local visible_h = 0
  for _, row in ipairs(rows) do
    visible_h = visible_h + 16 * row.alpha
  end
  local body_h = 13 + visible_h
  local x, y = hotkeys_pos.x, hotkeys_pos.y
  drag_box(hotkeys_pos, x, y, final_w, body_y + body_h)
  x, y = hotkeys_pos.x, hotkeys_pos.y
  draw_circle(x, y, final_w, header_h, hotkeys_state.master, 12)
  local title = "Hotkeys"
  local tw, th = measure_text(title)
  local v2 = wm_font_style()
  local title_x = x + final_w / 2 - tw / 2 + 5
  local ma = math.floor(255 * hotkeys_state.master)
  render.text(
            wm_font_arial(),
            vector(title_x, y + (header_h - th) / 2),
            color(240, 240, 240, ma),
            nil,
            title)
  render.text(
            wm_font_arial(),
            vector(title_x - 13, y + (header_h - th) / 2),
            color(v2.r, v2.g, v2.b, ma),
            nil,
            "{}")
  draw_circle(x, y + body_y, final_w, body_h, hotkeys_state.master, 12)
  local yy = y + body_y + 9
  for _, row in ipairs(rows) do
    local alpha = hotkeys_state.master * row.alpha
    local vw = measure_text(row.value)
    local a = math.floor(255 * alpha)
    render.text(
            wm_font_arial(),
            vector(x + 12.5, yy),
            color(240, 240, 240, a),
            nil,
            row.name)
    render.text(
            wm_font_arial(),
            vector(x + final_w - 12.5 - vw, yy),
            color(170, 170, 175, a),
            nil,
            row.value)
    yy = yy + 16 * row.alpha
  end
end
local notifications_render
local notifications_state = _G.__EMBERLIGHT_EN or {
  items = {},
  x = nil,
  y = nil,
  was = false,
  drag = false,
  last_preview = 0,
  burn = {},
}
_G.__EMBERLIGHT_EN = notifications_state
if _G.__EMBERLIGHT_NOTIFY_POS then
  notifications_state.cx, notifications_state.y =
      _G.__EMBERLIGHT_NOTIFY_POS.cx,
      _G.__EMBERLIGHT_NOTIFY_POS.y
end
local notification_fonts = {
  spread = color(237, 196, 119, 255),
  correction = color(255, 93, 82, 255),
  misprediction = color(255, 93, 82, 255),
  ["prediction error"] = color(255, 93, 82, 255),
  ["damage rejection"] = color(255, 93, 82, 255),
  ["backtrack failure"] = color(122, 159, 250, 255),
  death = color(140, 140, 140, 255),
  ["player death"] = color(140, 140, 140, 255),
  ["unregistered shot"] = color(140, 140, 140, 255),
}
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
  [9] = "generic",
  [10] = "gear",
}
local function notify_enabled(ref)
  return item_enabled(app.notifications) and item_enabled(ref)
end
local function send_notify(text)
  if notify_enabled(app.notification_debug) then
    local ok = pcall(function()
      print_dev("emberlight › " .. text)
    end)
    if not ok then
      raw_log("[emberlight debug] " .. text)
    end
  end
  if notify_enabled(app.notification_console) then
    local ok = pcall(function()
      print_raw("emberlight › " .. text)
    end)
    if not ok then
      raw_log("[emberlight] " .. text)
    end
  end
end
local function notify_screen(text, clr, log_text)
  if notify_enabled(app.notification_screen) then
    table.insert(notifications_state.items, 1, {
      text = tostring(text),
      color = clr or wm_font_style(),
      born = game_time(),
    })
    while #notifications_state.items > 5 do
      table.remove(notifications_state.items)
    end
  end
  send_notify(tostring(log_text or text))
end
local function player_name(ent)
  local n = "target"
  if ent then
    pcall(function()
      n = ent:get_name()
    end)
  end
  return tostring(n):gsub("%c", " "):sub(1, 28)
end
local function to_entity(v)
  if type(v) == "userdata" then
    return v
  end
  local e = nil
  pcall(function()
    e = entity.get(v, true)
  end)
  return e
end
local function notify_kill(e)
  if not item_enabled(app.notifications) or not e then
    return
  end
  local target = to_entity(e.target)
  local name = player_name(target)
  local state = e.state
  local hg = hitgroup_names[tonumber(e.hitgroup) or -1] or "?"
  local whg = hitgroup_names[tonumber(e.wanted_hitgroup) or -1] or "?"
  local dmg = tonumber(e.damage) or 0
  local wanted = tonumber(e.wanted_damage) or dmg
  local alive = true
  local hp = 0
  if target then
    pcall(function()
      alive = target:is_alive()
      hp = finite(target.m_iHealth) or 0
    end)
  end
  local main
  if state then
    main =
        string.format("Miss in %s's %s due to %s", name, whg, tostring(state))
  elseif alive then
    main = string.format("Hit %s in %s for %d damage", name, hg, dmg)
  else
    main = string.format("Killed %s in %s", name, hg)
  end
  local extra = string.format(
              " › %dt · %d%% · %.2f°",
              tonumber(e.backtrack) or 0,
              math.floor((tonumber(e.hitchance) or 0) + 0.5),
              tonumber(e.spread) or 0)
  if not state and hp > 0 then
    extra = extra .. string.format(" · %d hp", hp)
  end
  if dmg ~= wanted then
    extra = extra .. string.format(" · %d dmg", wanted)
  end
  notify_screen(main, notification_fonts[state] or wm_font_style(), main .. extra)
end
on_event("aim_ack", notify_kill)
on_event("player_death", function(e)
  if not item_enabled(app.notifications) then
    return
  end
  local me = nil
  pcall(function()
    me = entity.get_local_player()
  end)
  local payload = type(e) == "table" and e or nil
  local victim = payload and to_entity(payload.userid) or nil
  local attacker = payload and to_entity(payload.attacker) or nil
  if me and victim == me and attacker then
    notify_screen("Killed by " .. player_name(attacker), notification_fonts.death)
  end
end)
on_event("player_hurt", function(e)
  if not item_enabled(app.notifications) then
    return
  end
  local me = nil
  pcall(function()
    me = entity.get_local_player()
  end)
  local payload = type(e) == "table" and e or nil
  local attacker = payload and to_entity(payload.attacker) or nil
  local victim = payload and to_entity(payload.userid) or nil
  if not me or attacker ~= me or not victim then
    return
  end
  local map = {
    inferno = { "Burned", "burned out" },
    knife = { "Knifed", "Stabbed" },
    hegrenade = { "Naded", "Exploded" },
    taser = { "Tased", "Tased" },
  }
  local m = map[tostring(payload.weapon or "")]
  if not m then
    return
  end
  local alive = (tonumber(payload.health) or 0) > 0
  notify_screen(string.format("%s %s%s", alive and m[1] or m[2], player_name(victim), alive and (" for " .. tostring(tonumber(payload.dmg_health) or 0) .. " damage") or
    ""), wm_font_style())
end)
notifications_render = function()
  if not item_enabled(app.notifications) or
    not item_enabled(app.notification_screen) then
    notifications_state.items = {}
    return
  end
  local sc = render.screen_size()
  local now = game_time()
  for i = #notifications_state.items, 1, -1 do
    if now - notifications_state.items[i].born > 5 then
      table.remove(notifications_state.items, i)
    end
  end
  local list = notifications_state.items
  local preview = ui_visible() and #list == 0
  if preview then
    list = { {
      text = "your face is like a melody - it won't leave my head",
      color = wm_font_style(),
      born = now,
    }, {
      text = "Glad to see you again, PWNZ!",
      color = wm_font_style(),
      born = now,
    } }
  end
  local maxw = 100
  for _, it in ipairs(list) do
    local w = measure_text(it.text)
    maxw = math.max(maxw, w + 36)
  end
  if not notifications_state.cx then
    notifications_state.cx = sc.x / 2
    notifications_state.y = sc.y / 1.7
  end
  local down = mouse_down()
  local mx, my = mouse_pos()
  local bx = notifications_state.cx - maxw / 2
  local bh = 33 * math.max(1, #list)
  if ui_visible() and down and not notifications_state.was and mx and mx >= bx and
    mx <= bx + maxw and my >= notifications_state.y and my <= notifications_state.y + bh then
    notifications_state.drag = true
    notifications_state.dx = mx - notifications_state.cx
    notifications_state.dy = my - notifications_state.y
  end
  if notifications_state.drag and down and mx then
    notifications_state.cx = clamp(mx - notifications_state.dx, maxw / 2, sc.x - maxw / 2)
    notifications_state.y = clamp(my - notifications_state.dy, 0, sc.y - bh)
  end
  if not down then
    notifications_state.drag = false
  end
  notifications_state.was = down
  _G.__EMBERLIGHT_NOTIFY_POS = { cx = notifications_state.cx, y = notifications_state.y }
  for i, it in ipairs(list) do
    local age = now - it.born
    local alpha = preview and 1 or
      math.min(clamp(age / 0.18, 0, 1), clamp((5 - age) / 0.55, 0, 1))
    local yy = notifications_state.y + (i - 1) * 33
    local tw, th = measure_text(it.text)
    local item_w = math.max(100, tw + 36)
    local item_x = notifications_state.cx - item_w / 2
    draw_circle(item_x, yy, item_w, 29, alpha, 12)
    local clr = it.color or wm_font_style()
    render.circle(
              vector(item_x + 13, yy + 14.5),
              color(clr.r or 185, clr.g or 190, clr.b or 255, math.floor(70 * alpha)),
              4,
              0,
              1)
    render.circle(
              vector(item_x + 13, yy + 14.5),
              color(clr.r or 185, clr.g or 190, clr.b or 255, math.floor(255 * alpha)),
              2,
              0,
              1)
    render.text(
            wm_font_arial(),
            vector(notifications_state.cx - tw / 2 + 5, yy + (29 - th) / 2),
            color(235, 235, 240, math.floor(255 * alpha)),
            nil,
            it.text)
  end
end
f1 = function(cmd)
  if not cmd then
    return
  end
  local ok, me = pcall(entity.get_local_player)
  if not ok or not me then
    return
  end
  local alive = false
  pcall(function()
    alive = me:is_alive()
  end)
  if not alive then
    return
  end
  local on_ladder = false
  do
    local mt = nil
    pcall(function()
      mt = finite(me.m_MoveType)
    end)
    if mt == nil then
      pcall(function()
        mt = finite(entity.get_prop(me, "m_MoveType"))
      end)
    end
    if mt == 9 then
      on_ladder = true
    end
  end
  pcall(function()
    if on_ladder and not _G.__EMBERLIGHT_AA_HELD then
      _G.__EMBERLIGHT_AA_HELD = {}
      local cands = {
        { "Aimbot", "Anti Aim", "Angles", "Enabled" },
        { "Aimbot", "Anti-Aim", "Angles", "Enabled" },
        { "Aimbot", "Anti Aim", "Enabled" },
      }
      for _, p in ipairs(cands) do
        local ok, ref = pcall(function()
          if #p == 4 then
            return ui.find(p[1], p[2], p[3], p[4])
          end
          return ui.find(p[1], p[2], p[3])
        end)
        if ok and ref then
          local rok, base = pcall(function()
            return ref:get()
          end)
          if rok and type(base) == "boolean" and base == true then
            local aok = pcall(function()
              ref:override(false)
            end)
            if aok then
              _G.__EMBERLIGHT_AA_HELD[#_G.__EMBERLIGHT_AA_HELD + 1] =
                  { ref = ref, base = base }
            end
          end
        end
      end
    elseif (not on_ladder) and _G.__EMBERLIGHT_AA_HELD then
      for _, h in ipairs(_G.__EMBERLIGHT_AA_HELD) do
        pcall(function()
          h.ref:override()
        end)
      end
      _G.__EMBERLIGHT_AA_HELD = nil
    end
  end)
  if item_enabled(app.movement) and item_enabled(app.fast_ladder) and on_ladder then
    pcall(function()
      local camx = nil
      pcall(function()
        camx = render.camera_angles().x
      end)
      if camx == nil or camx < 45 then
        if (finite(cmd.forwardmove) or 0) > 0 then
          cmd.view_angles.x = 89
          cmd.in_moveright = 1
          cmd.in_moveleft = 0
          cmd.in_forward = 0
          cmd.in_back = 1
          local sm = finite(cmd.sidemove) or 0
          if sm == 0 then
            cmd.view_angles.y = cmd.view_angles.y + 90
          elseif sm < 0 then
            cmd.view_angles.y = cmd.view_angles.y + 150
          else
            cmd.view_angles.y = cmd.view_angles.y + 30
          end
        elseif (finite(cmd.forwardmove) or 0) < 0 then
          cmd.view_angles.x = 89
          cmd.in_moveleft = 1
          cmd.in_moveright = 0
          cmd.in_forward = 1
          cmd.in_back = 0
          local sm = finite(cmd.sidemove) or 0
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
  pcall(function()
    vel = me.m_vecVelocity
  end)
  if item_enabled(app.movement) and item_enabled(app.no_fall_damage) and vel and
    finite(vel.z) and vel.z <= -500 then
    pcall(function()
      local org = nil
      pcall(function()
        org = me:get_origin()
      end)
      if org == nil then
        pcall(function()
          org = me.m_vecOrigin
        end)
      end
      if not org then
        return
      end
      local function f1(length)
        local TAU = math.pi * 2
        for i = 0, TAU, TAU / 8 do
          local x = org.x + math.cos(i) * 10
          local y = org.y + math.sin(i) * 10
          local s = vector(x, y, org.z)
          local e = vector(x, y, org.z - length)
          local ok, tr = pcall(function()
            return utils.trace_line(s, e, me)
          end)
          if ok and tr and finite(tr.fraction) and tr.fraction < 1 then
            return true
          end
        end
        return false
      end
      local state = false
      if f1(15) then
        state = false
      elseif f1(75) then
        state = true
      end
      cmd.in_duck = state
    end)
  end
  if item_enabled(app.movement) and item_enabled(app.avoid_collision) and vel and
    finite(vel.x) and finite(vel.y) then
    local org = nil
    pcall(function()
      org = me:get_origin()
    end)
    if org == nil then
      pcall(function()
        org = me.m_vecOrigin
      end)
    end
    local sp =
        math.sqrt((vel.x or 0) * (vel.x or 0) + (vel.y or 0) * (vel.y or 0))
    if org and finite(org.x) and sp > 40 and cmd.in_jump and cmd.in_jump ~= 0 then
      local dst =
          vector(org.x + vel.x / sp * 48, org.y + vel.y / sp * 48, org.z + 24)
      local src = vector(org.x, org.y, org.z + 24)
      local oktr, tr = pcall(function()
        return utils.trace_line(src, dst, nil, nil, 1)
      end)
      if oktr and tr and finite(tr.fraction) and tr.fraction < 0.55 then
        cmd.sidemove =
            ((finite(cmd.command_number) or 0) % 2 == 0) and 450 or -450
        cmd.forwardmove = -40
      end
    end
  end
  if item_enabled(app.jump_scout) and vel then
    local flags = nil
    pcall(function()
      flags = finite(me.m_fFlags)
    end)
    if flags == nil then
      pcall(function()
        flags = finite(entity.get_prop(me, "m_fFlags"))
      end)
    end
    local air =
        flags and bit and bit.band and bit.band(flags, 1) == 0 or false
    if air then
      local weapon = nil
      pcall(function()
        weapon = me:get_player_weapon()
      end)
      local info_tab = nil
      if weapon then
        pcall(function()
          info_tab = weapon:get_weapon_info()
        end)
      end
      local name =
          info_tab and tostring(info_tab.console_name or ""):lower() or ""
      local is_scout = name:find("ssg08", 1, true) ~= nil
      if is_scout then
        local hands_off = (not cmd.in_forward or cmd.in_forward == 0) and
          (not cmd.in_back or cmd.in_back == 0) and (not cmd.in_moveleft or cmd.in_moveleft == 0) and (not cmd.in_moveright or cmd.in_moveright == 0)
        if hands_off then
          local vx, vy = finite(vel.x) or 0, finite(vel.y) or 0
          local sp = math.sqrt(vx * vx + vy * vy)
          if sp <= 8 then
            cmd.forwardmove = 0
            cmd.sidemove = 0
          elseif sp < 110 then
            local yaw = nil
            pcall(function()
              yaw = finite(cmd.view_angles.y)
            end)
            if yaw == nil then
              pcall(function()
                yaw = finite(render.camera_angles().y)
              end)
            end
            if yaw ~= nil then
              local r = math.rad(yaw)
              local dx, dy = -vx, -vy
              local f = math.cos(r) * dx + math.sin(r) * dy
              local side = -math.sin(r) * dx + math.cos(r) * dy
              cmd.forwardmove = clamp(f * 4, -180, 180)
              cmd.sidemove = clamp(side * 4, -180, 180)
            end
          end
        end
      end
    end
  end
end
local optimizer_groups = { groups = { Decals = { r_decals = 0, r_drawbatchdecals = 0, r_drawmodeldecals = 0 }, ["Blood and gibs"] = {
  violence_ablood = 0,
  violence_hblood = 0,
  violence_agibs = 0,
  violence_hgibs = 0,
}, Tracers = { muzzleflash_light = 0, r_drawtracers_firstperson = 0 }, ["Breakable debris"] = { func_break_max_pieces = 0, props_break_max_pieces = 0 }, ["3D sky"] = { r_3dsky = 0 }, Ropes = {
  rope_collide = 0,
  rope_smooth = 0,
  rope_subdiv = 0,
  rope_wind_dist = 0,
  r_drawropes = 0,
} }, presets = { Recommended = { "Blood and gibs", "Tracers", "Breakable debris" }, ["Maximum FPS"] = {
  "Decals",
  "Blood and gibs",
  "Tracers",
  "Breakable debris",
  "3D sky",
  "Ropes",
} }, saved = {}, active = false, signature = nil, defaults = {
  r_decals = 2048,
  r_drawbatchdecals = 1,
  r_drawmodeldecals = 1,
  violence_ablood = 1,
  violence_hblood = 1,
  violence_agibs = 1,
  violence_hgibs = 1,
  muzzleflash_light = 1,
  r_drawtracers_firstperson = 1,
  func_break_max_pieces = 15,
  props_break_max_pieces = -1,
  r_3dsky = 1,
  rope_collide = 1,
  rope_smooth = 1,
  rope_subdiv = 2,
  rope_wind_dist = 1000,
  r_drawropes = 1,
} }
optimizer_groups.cvar_ref = function(self, name)
  local ok, ref = pcall(function()
    if cvar[name] then
      return cvar[name]
    end
    if cvar.find then
      return cvar.find(name)
    end
  end)
  if ok and ref then
    return ref
  end
  return nil
end
optimizer_groups.cvar_read = function(self, ref)
  local v = nil
  pcall(function()
    v = ref:int()
  end)
  if finite(v) then
    return v
  end
  pcall(function()
    v = ref:float()
  end)
  if finite(v) then
    return v
  end
  pcall(function()
    v = ref:string()
  end)
  return v
end
optimizer_groups.cvar_write = function(self, ref, value)
  local ok = false
  pcall(function()
    ref:int(math.floor(tonumber(value) or 0))
    ok = true
  end)
  if ok then
    return true
  end
  pcall(function()
    ref:float(tonumber(value) or 0)
    ok = true
  end)
  return ok
end
optimizer_groups.console_write = function(self, name, value)
  local command = tostring(name) .. " " .. tostring(value)
  local ok = false
  if utils and type(utils.console_exec) == "function" then
    ok = pcall(utils.console_exec, command)
  end
  if not ok and client and type(client.exec) == "function" then
    ok = pcall(client.exec, command)
  end
  if not ok and client and type(client.execute) == "function" then
    ok = pcall(client.execute, command)
  end
  return ok
end
optimizer_groups.selection_signature = function(self, groups)
  local copy = {}
  for i, name in ipairs(groups or self:selected()) do
    copy[i] = name
  end
  table.sort(copy)
  return table.concat(copy, "|")
end
optimizer_groups.selected = function(self)
  local out = {}
  local ok, sel = pcall(function()
    return app.opt_list:get()
  end)
  if ok and type(sel) == "table" then
    local any = false
    for _, v in ipairs(sel) do
      if type(v) == "string" and self.groups[v] then
        out[#out + 1] = v
        any = true
      end
    end
    for k, v in pairs(sel) do
      if v == true and type(k) == "string" and self.groups[k] then
        out[#out + 1] = k
        any = true
      end
    end
    if any then
      return out
    end
  end
  local ok2, preset = pcall(function()
    return app.opt_preset:get()
  end)
  preset = (ok2 and preset) or "Recommended"
  local p = self.presets[preset] or self.presets.Recommended
  for _, g in ipairs(p) do
    out[#out + 1] = g
  end
  return out
end
optimizer_groups.apply = function(self, groups)
  groups = groups or self:selected()
  for _, g in ipairs(groups) do
    local cv = self.groups[g]
    if cv then
      for name, _ in pairs(cv) do
        if self.saved[name] == nil then
          local ref = self:cvar_ref(name)
          local value = ref and self:cvar_read(ref) or self.defaults[name]
          self.saved[name] = { ref = ref, value = value }
        end
      end
    end
  end
  for _, g in ipairs(groups) do
    local cv = self.groups[g]
    if cv then
      for name, target in pairs(cv) do
        local state = self.saved[name]
        local written = false
        if state and state.ref then
          written = self:cvar_write(state.ref, target)
        end
        if not written then
          self:console_write(name, target)
        end
      end
    end
  end
  self.signature = self:selection_signature(groups)
  self.active = true
end
optimizer_groups.restore = function(self)
  for name, state in pairs(self.saved) do
    if state and state.value ~= nil then
      local written = false
      if state.ref then
        written = self:cvar_write(state.ref, state.value)
      end
      if not written then
        self:console_write(name, state.value)
      end
    end
  end
  self.saved = {}
  self.signature = nil
  self.active = false
end
optimizer_groups.tick = function(self)
  if not item_enabled(app.fps_optimizer) then
    if self.active then
      self:restore()
    end
    return
  end
  local groups = self:selected()
  local signature = self:selection_signature(groups)
  if not self.active or self.signature ~= signature then
    if self.active then
      self:restore()
    end
    self:apply(groups)
  end
end
pcall(function()
  app.opt_preset:set_callback(function()
    local ok, preset = pcall(function()
      return app.opt_preset:get()
    end)
    local p =
        optimizer_groups.presets[(ok and preset) or "Recommended"] or optimizer_groups.presets.Recommended
    pcall(function()
      app.opt_list:set(p)
    end)
    if item_enabled(app.fps_optimizer) then
      if optimizer_groups.active then
        optimizer_groups:restore()
      end
      optimizer_groups:apply()
    end
  end)
end)
pcall(function()
  app.opt_list:set_callback(function()
    if item_enabled(app.fps_optimizer) then
      if optimizer_groups.active then
        optimizer_groups:restore()
      end
      optimizer_groups:apply()
    end
  end)
end)
local function boot()
  safe_call("menu_section", set_menu_section)
  safe_call("settings_visibility", native_cleanup)
  safe_call("fps_opt", function()
    optimizer_groups:tick()
  end)
  aspect_presets:guard(aspect_presets.sync)
  aspect_presets:guard(aspect_presets.scan)
  yaw_state_table:guard(yaw_state_table.frame)
  safe_call("sidebar_theme", tick_banner)
  safe_call("aspect", tick_pixel)
  safe_call("crosshair_indicator", optimizer_render)
  safe_call("side_indicators", side_indicators_render)
  safe_call("damage_indicator", crosshair_render)
  safe_call("interpolation", tick_extrapolation)
  safe_call("hit_effect", he_ok)
  safe_call("hotkeys", hotkey_source)
  safe_call("clantag", tick_clantag)
  local t = game_time()
  if t < avg_last_time or t - avg_last_time >= 0.25 then
    avg_last_time = t
    clantag_state:guard(clantag_state.idle)
    safe_call("trash_talk", trash_timer.tick)
  end
end
local function set_config_state(state)
  if state == "pre_load" or state == "pre_save" then
    yaw_state_table.suspended, aspect_presets.suspended, clantag_state.suspended = true, true, true
    aspect_presets:guard(aspect_presets.sync)
    yaw_state_table:guard(yaw_state_table.reset, "config transaction; requests released")
    clantag_state:guard(clantag_state.reset)
  elseif state == "post_load" or state == "post_save" then
    yaw_state_table.suspended, aspect_presets.suspended, clantag_state.suspended, yaw_state.suspended =
        false,
        false,
        false,
        false
    yaw_state.fault = nil
    pcall(function()
      native_api:request("dormant", nil)
    end)
    aspect_presets:guard(aspect_presets.sync)
    yaw_state_table:guard(yaw_state_table.reset, "config transaction complete")
    clantag_state:guard(clantag_state.reset)
  end
end
local function boot_beta()
  pcall(function()
    app.version_state.boot_lock = true
  end)
  yaw_state_table.suspended, aspect_presets.suspended, clantag_state.suspended, yaw_state.suspended =
      true,
      true,
      true,
      true
  clantag_state:guard(clantag_state.reset)
  yaw_state:guard(yaw_state.reset, "shutdown; yaw released")
  pcall(function()
    yaw_state.miss_state.miss_log = yaw_state.miss_log
    yaw_state.miss_state.bucket_stats = yaw_state.bucket_stats
    yaw_state.miss_state.miss_counts = yaw_state.miss_counts
    yaw_state.miss_state.ack_stats = yaw_state.ack_stats
    yaw_state.miss_state.mode_stats = yaw_state.mode_stats
    yaw_state.miss_state.delta_stats = yaw_state.delta_stats
    yaw_state.miss_state.population = yaw_state.population
    _G.__EMBERLIGHT_MISS_STATE_V2 = yaw_state.miss_state
    yaw_state.shots, yaw_state.learn = {}, {}
  end)
  safe_call("native_cleanup", function()
    if not native_api:release_all() then
      raw_log("[Emberlight] Native release NOT verified. Check Safe Points in the native menu.")
    end
  end)
  safe_call("aspect_cleanup", sync_pixel)
  safe_call("interpolation_cleanup", apply_interp_off)
  safe_call("kill_particles_cleanup", f2)
  safe_call("hit_effect_cleanup", hit_effect_clear)
  safe_call("model_changer_cleanup", mc_error)
  safe_call("clantag_cleanup", clear_clantag)
  safe_call("optimizer_cleanup", function()
    optimizer_groups:restore()
  end)
  pcall(function()
    if _G.__EMBERLIGHT_AA_HELD then
      for _, h in ipairs(_G.__EMBERLIGHT_AA_HELD) do
        pcall(function()
          h.ref:override()
        end)
      end
      _G.__EMBERLIGHT_AA_HELD = nil
    end
  end)
  pcall(function()
    if type(extrapolation_status) == "table" and extrapolation_status.release_hc then
      extrapolation_status:release_hc()
    end
  end)
end
on_event("shutdown", boot_beta)
local watermark_render, notifications_render_ok, kill_particles_render
do
  local wm = {
    alpha = 0,
    kills = 0,
    deaths = 0,
    fps = 0,
    var = 0,
    ping = 0,
    last_update = 0,
    ft_samples = {},
    ft_count = 0,
  }
  local font_main, font_small
  local function f1()
    if font_main then
      return
    end
    local ok_main, f_main = pcall(render.load_font, "Verdana", 12, "a")
    local ok_small, f_small = pcall(render.load_font, "Verdana", 10, "a")
    font_main = (ok_main and f_main) or 2
    font_small = (ok_small and f_small) or 2
  end
  local function f2(flags)
    return flags == "-" and font_small or font_main
  end
  local function f3(x, y, c, alpha, flags, text)
    render.text(
            f2(flags),
            vector(x, y),
            color(c[1], c[2], c[3], math.floor((c[4] or 255) * alpha)),
            nil,
            text)
  end
  local function f4(flags, text)
    local ok, size = pcall(render.measure_text, f2(flags), nil, text)
    if ok and size then
      return size.x or 0, size.y or 0
    end
    return 0, 0
  end
  local function f5(x, y, w, h, left_a, right_a)
    render.gradient(
                vector(x, y),
                vector(x + w, y + h),
                color(0, 0, 0, left_a),
                color(0, 0, 0, right_a),
                color(0, 0, 0, left_a),
                color(0, 0, 0, right_a))
  end
  local function f6(x, y, w, h, alpha)
    local center = math.floor(0.5 + w * 0.5)
    local edge_a = math.floor(22 * alpha)
    local center_a = math.floor(125 * alpha)
    f5(x, y, center, h, edge_a, center_a)
    f5(x + center, y, w - center, h, center_a, edge_a)
  end
  local function f7(x, y, w, h, alpha)
    local center = math.floor(0.5 + w * 0.5)
    local center_a = math.floor(40 * alpha)
    f5(x, y, center, 1, 0, center_a)
    f5(x + center, y, w - center, 1, center_a, 0)
    f5(x, y + h - 1, center, 1, 0, center_a)
    f5(x + center, y + h - 1, w - center, 1, center_a, 0)
  end
  local function f8(value, good_limit, warning_limit, lower_is_better, good_color)
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
  local function f9(name)
    local ok, sel = pcall(function()
      return app.wm_elements:get()
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
  local function f10()
    local ok, v = pcall(function()
      return app.wm_position:get()
    end)
    return (ok and type(v) == "string") and v or "Top-right"
  end
  local function f11()
    local ok, c = pcall(function()
      return app.wm_accent:get()
    end)
    if ok and c then
      local r, g, b = tonumber(c.r), tonumber(c.g), tonumber(c.b)
      if r and g and b then
        return { r, g, b, 255 }
      end
    end
    return { 159, 202, 43, 255 }
  end
  local function f12()
    local lp = entity.get_local_player()
    if not lp then
      return 0
    end
    local ok, v = pcall(function()
      return lp.m_vecVelocity
    end)
    if not ok or v == nil then
      return 0
    end
    local vx, vy = 0, 0
    pcall(function()
      vx, vy = v.x or 0, v.y or 0
    end)
    return math.floor(math.sqrt(vx * vx + vy * vy))
  end
  local function f13()
    local ok, t = pcall(function()
      return common.get_system_time()
    end)
    if ok and type(t) == "table" then
      local h = tonumber(t.hours) or 0
      local m = tonumber(t.minutes) or 0
      local s = tonumber(t.seconds) or 0
      return string.format("%02d:%02d:%02d", h, m, s)
    end
    local ok2, s = pcall(function()
      return common.get_date("%H:%M:%S")
    end)
    if ok2 and type(s) == "string" then
      return s
    end
    return "--:--:--"
  end
  local function f14(ft)
    wm.ft_count = wm.ft_count + 1
    wm.ft_samples[(wm.ft_count % 100) + 1] = ft
    local now = finite(globals.realtime) or 0
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
  on_event("player_death", function(e)
    pcall(function()
      local me = entity.get_local_player()
      if not me then
        return
      end
      local payload = type(e) == "table" and e or {}
      local victim = entity.get(payload.userid, true)
      local attacker = entity.get(payload.attacker, true)
      if victim == me then
        wm.deaths = wm.deaths + 1
      end
      if attacker == me and victim ~= me then
        wm.kills = wm.kills + 1
      end
    end)
  end)
  watermark_render = function()
    f1()
    local v1 = item_enabled(app.watermark)
    local ft = finite(globals.frametime) or 0
    local target = v1 and 1 or 0
    wm.alpha = wm.alpha + (target - wm.alpha) * math.min(1, ft * 12)
    if not v1 and wm.alpha <= 0.01 then
      wm.alpha = 0
      return
    end
    local alpha = wm.alpha
    local style = wm_style()
    if style == "Evalate" then
      if kill_particles_render then
        kill_particles_render(alpha)
      end
      return
    end
    if style == "Neverlose" then
      notifications_render_ok(alpha)
      return
    end
    f14(ft)
    local v2 = f11()
    local white = { 194, 194, 194, 255 }
    local function main_panel(c, flags, text, shift_x, shift_y)
      return {
        color = c,
        flags = flags or "",
        text = tostring(text or ""),
        shift_x = shift_x or 0,
        shift_y = shift_y or 0,
      }
    end
    local list = {}
    if f9("Logo") then
      list[#list + 1] = {
        main_panel({ 255, 255, 255, 255 }, "", "game"),
        main_panel(v2, "", "sense"),
      }
    end
    if f9("FPS") then
      list[#list + 1] = {
        main_panel(f8(wm.fps, 60, 120, false, v2), "", wm.fps),
        main_panel(white, "-", "FPS", 1, 2),
      }
    end
    if f9("Frametime variance") then
      list[#list + 1] = {
        main_panel(f8(wm.var, 2, 3, true, v2), "", wm.var),
        main_panel(white, "-", "VAR", 1, 2),
      }
    end
    if f9("Ping") then
      list[#list + 1] = {
        main_panel(f8(wm.ping, 40, 100, true, v2), "", wm.ping),
        main_panel(white, "-", "PING", 1, 2),
      }
    end
    if f9("Speed") then
      list[#list + 1] = {
        main_panel(white, "", f12()),
        main_panel(white, "-", "SPEED", 1, 2),
      }
    end
    if f9("K/D ratio") then
      local kd = wm.deaths > 0 and wm.kills / wm.deaths or wm.kills
      local kd_color = kd > 2 and v2 or
        ((kd > 0 and kd < 1) and { 139, 31, 31, 255 } or { 183, 121, 51, 255 })
      list[#list + 1] = {
        main_panel(kd_color, "", string.format("%.1f", kd)),
        main_panel(white, "-", "K/D", 1, 2),
      }
    end
    if f9("Clock") then
      list[#list + 1] = { main_panel(white, "", f13()) }
    end
    if #list == 0 then
      return
    end
    local measures, total_width = {}, 0
    for i = 1, #list do
      measures[i] = {}
      for j = 1, #list[i] do
        local s = list[i][j]
        local tw, th = f4(s.flags, s.text)
        measures[i][j] = { x = tw, y = th }
        total_width = total_width + tw + s.shift_x
      end
      if i ~= #list then
        total_width = total_width + 12
      end
    end
    local height = 20
    local width = total_width + 15
    local screen = render.screen_size()
    local sw, sh = screen.x, screen.y
    local x, y = sw - width - 5, 5
    if f10() == "Bottom-center" then
      x = (sw - width) / 2
      y = sh - height - 5
    end
    f6(x - 10, y, width + 20, height, alpha)
    f7(x - 10, y, width + 20, height, alpha)
    local draw_x = x + 5
    local offset = 0
    for i = 1, #list do
      for j = 1, #list[i] do
        local s = list[i][j]
        local size = measures[i][j]
        local ty = y + math.floor((height - size.y) * 0.5)
        f3(draw_x + offset + s.shift_x, ty, s.color, alpha, s.flags, s.text)
        offset = offset + size.x
      end
      offset = offset + 12
    end
  end
end
do
  local ev = {
    content_alpha = 0,
    fps = 0,
    fps_at = 0,
    header_font = nil,
    content_font = nil,
  }
  local function f1(a, b, speed)
    local ft = finite(globals and (globals.absoluteframetime or globals.frametime)) or
      0.016
    return a + (b - a) * clamp(ft * speed, 0, 1)
  end
  local function f2()
    if ev.header_font and ev.content_font then
      return
    end
    local ok_header_font, f1 = pcall(render.load_font, "arial", 14, "ad")
    local ok2, f2 = pcall(render.load_font, "arial", vector(13, 11), "a")
    ev.header_font = (ok_header_font and f1) or 2
    ev.content_font = (ok2 and f2) or 2
  end
  local function f3(a1, text)
    local ok, v = pcall(render.measure_text, a1, nil, tostring(text or ""))
    return (ok and v and finite(v.x)) or 0, (ok and v and finite(v.y)) or 11
  end
  local function f4(ref, default)
    if not ref then
      return default
    end
    local ok, v = pcall(function()
      return ref:get()
    end)
    return ok and v or default
  end
  local function f5()
    local source = f4(app.wm_eval_username_source, "Cheat")
    if source == "Custom" then
      local v = f4(app.wm_eval_username_custom, "")
      if type(v) == "string" and v ~= "" then
        return v
      end
    elseif source == "Steam" then
      local ok, v = pcall(function()
        local me = entity.get_local_player()
        return me and me:get_name() or nil
      end)
      if ok and type(v) == "string" and v ~= "" then
        return v
      end
    end
    local ok, v = pcall(function()
      return common.get_username()
    end)
    return (ok and type(v) == "string" and v ~= "") and v or "user"
  end
  local function f6()
    local value = 0
    pcall(function()
      local net = utils.net_channel()
      if net and net.avg_latency and finite(net.avg_latency[0]) then
        value = math.floor(net.avg_latency[0] * 1000 + 0.5)
      end
    end)
    return value
  end
  local function f7()
    local fmt =
        f4(app.wm_eval_time_format, "24h") == "12h" and "%I:%M %p" or "%H:%M"
    local ok, v = pcall(function()
      return common.get_date(fmt)
    end)
    return (ok and type(v) == "string") and v:lower() or "--:--"
  end
  local function f8()
    local now = finite(globals and globals.realtime) or 0
    if now - ev.fps_at > 0.8 then
      local ft = finite(globals and (globals.absoluteframetime or globals.frametime)) or
        0
      ev.fps = ft > 0 and math.floor(1 / ft + 0.5) or 0
      ev.fps_at = now
    end
    local out = {}
    local function f1(ic, value)
      out[#out + 1] = { icon = ic, value = tostring(value) }
    end
    if wm_elements_selected("Version") then
      f1("</>", "Beta")
    end
    if wm_elements_selected("Username") then
      f1("@", f5())
    end
    if wm_elements_selected("Latency") and globals and globals.is_connected then
      f1("↻", string.format("%i ms", f6()))
    end
    if wm_elements_selected("Frames") then
      f1("▣", string.format("%i fps", ev.fps))
    end
    if wm_elements_selected("Time") then
      f1("◷", f7())
    end
    return out
  end
  local function f9(x, y, content_w, alpha, a1)
    local padding = vector(25, 13)
    local height, rounding, spread = 12, 12, 70
    local top_left, bottom_right =
        vector(x, y),
        vector(x, y) + padding + vector(content_w, height)
    local center =
        (top_left + vector(padding.x / 2, height / 2 + padding.y / 2)):floor()
    local glow_size = vector(content_w, 2):floor()
    pcall(function()
      render.rect(center, center + glow_size, color(
          a1.r,
          a1.g,
          a1.b,
          math.floor(65 * alpha * ((finite(a1.a) or 255) / 255))), rounding)
    end)
    pcall(function()
      render.shadow(center, center + glow_size, color(
          a1.r,
          a1.g,
          a1.b,
          math.floor(255 * alpha * ((finite(a1.a) or 255) / 255))), spread, 0, rounding)
    end)
    pcall(function()
      render.blur(top_left, bottom_right, 0, alpha, rounding)
    end)
    render.rect(
            top_left,
            bottom_right,
            color(150, 150, 150, math.floor(40 * alpha)),
            rounding)
    pcall(function()
      render.rect_outline(
                    top_left,
                    bottom_right,
                    color(255, 255, 255, math.floor(20 * alpha)),
                    1,
                    rounding)
    end)
    return padding
  end
  local function f10(x, y, alpha, a1)
    local cursor = x
    local now = finite(globals and globals.realtime) or 0
    for i, ch in ipairs({ "𝒆", "𝒗", "𝒂", "𝒍", "𝒂", "𝒕", "𝒆" }) do
      local wave = (math.sin(now * 2.4 - i * 0.72) + 1) * 0.5
      local a = math.floor(255 * alpha * (0.35 + 0.65 * wave))
      render.text(
            ev.header_font,
            vector(cursor, y),
            color(a1.r, a1.g, a1.b, math.floor(a * ((finite(a1.a) or 255) / 255))),
            nil,
            ch)
      cursor = cursor + f3(ev.header_font, ch)
    end
  end
  kill_particles_render = function(alpha)
    if not alpha or alpha <= 0 then
      return
    end
    f2()
    local v1 = wm_accent()
    local items = f8()
    ev.content_alpha = f1(ev.content_alpha, #items > 0 and 1 or 0, 10)
    local header = "𝒆𝒗𝒂𝒍𝒂𝒕𝒆"
    local header_w = f3(ev.header_font, header)
    local content_w, gap = 0, 14
    local sizes = {}
    for i, it in ipairs(items) do
      local iw, ih = f3(ev.content_font, it.icon)
      local vw, vh = f3(ev.content_font, it.value)
      sizes[i] = { iw = iw, ih = ih, vw = vw, vh = vh }
      content_w = content_w + iw + 5 + vw + (i < #items and gap or 0)
    end
    local content_anim_w = content_w * ev.content_alpha
    local total = header_w + 25 + (5 + content_w + 25) * ev.content_alpha
    local screen = render.screen_size()
    local pos = f4(app.wm_position, "Top-right")
    local x, y = screen.x - total - 10, 10 * alpha
    if pos == "Top-left" then
      x = 10
    elseif pos == "Bottom-center" then
      x = screen.x / 2 - total / 2
      y = screen.y - 44 * alpha
    end
    local pad = f9(x, y, header_w, alpha, v1)
    f10(x + pad.x / 2, y + pad.y / 2 - 2, alpha, v1)
    if ev.content_alpha > 0.01 and #items > 0 then
      local cx = x + header_w + 25 + 5
      local ca = alpha * ev.content_alpha
      local cpad = f9(cx, y, content_anim_w, ca, v1)
      local cursor = cx + cpad.x / 2
      for i, it in ipairs(items) do
        local m = sizes[i]
        local ty = y + cpad.y / 2
        render.text(ev.content_font, vector(cursor, ty), color(
            v1.r,
            v1.g,
            v1.b,
            math.floor(255 * ca * ((finite(v1.a) or 255) / 255))), nil, it.icon)
        cursor = cursor + m.iw + 5
        render.text(
            ev.content_font,
            vector(cursor, ty),
            color(240, 240, 240, math.floor(255 * ca)),
            nil,
            it.value)
        cursor = cursor + m.vw + gap
      end
    end
  end
end;
(
  function()
  local nl_ico_raw = {
    user = "iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAQAAAC1QeVaAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAACYktHRAAAqo0jMgAAAAd0SU1FB+oIDwgeLYyV+8EAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjYtMDgtMTVUMDg6MzA6NDUrMDA6MDCfoKOTAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI2LTA4LTE1VDA4OjMwOjQ1KzAwOjAw7v0bLwAAACh0RVh0ZGF0ZTp0aW1lc3RhbXAAMjAyNi0wOC0xNVQwODozMDo0NSswMDowMLnoOvAAAAB1elRYdHN2Zzpjb21tZW50AAAImVN0y88rUXAsTy3Oz01VcCtKTVUw1zPWM1RIqlRwSAPKJUKldBUySkoKiq309ZFE9ZLzcxV8MpNT84rxqNDPgajQTwMZ75xfUFmUmZ5RomBkYGSmALI/Mzk/r1hHwTMvWQ8ABXAx8CqAOMQAAACzSURBVBjTZZC9agJREEbPlQ3+NYFNmTbgG2hrayE+QMDK50iTl3AhD5Eu0UJtBF/DVtDGJXbH5m7ubvIVw8AZvvlmAgBIUyHViJ4ZE9hyTBgQ8cW9qgcH1p1EfLPSewVbvxP5/y7BNVcASlaNbCJmvvrlt3MfKttQO6PPE4ETZXVOFsEjC2bkwJlPCi7JsuvSuj7siRFO/GnAm1Mxph3SaSRsMwLizh1F+hcAG4Dw9+V13QFwg2bHk3mbwgAAAABJRU5ErkJggg==",
    fps = "iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAYAAAAfSC3RAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAcElEQVR4nOWSMQqAMAxFCw6Cg1OX4iC4O4gXcPAq7YUcpKd9EqiYoYMZnPwQyM/P275zXwsYgQnoLNDMo0MHA7ADG9BUwFWBWQenChYLmFUgTwFIZYIFjMpHC5iUT38HfamTTAv0yssut9v715Wr6QJiYqmSoSEP8wAAAABJRU5ErkJggg==",
    ping = "iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAQAAAC1QeVaAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAACYktHRAAAqo0jMgAAAAd0SU1FB+oIDwgiNewKGmgAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjYtMDgtMTVUMDg6MzQ6NTMrMDA6MDA5MTZNAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI2LTA4LTE1VDA4OjM0OjUzKzAwOjAwSGyO8QAAACh0RVh0ZGF0ZTp0aW1lc3RhbXAAMjAyNi0wOC0xNVQwODozNDo1MyswMDowMB95ry4AAAB1elRYdHN2Zzpjb21tZW50AAAImVN0y88rUXAsTy3Oz01VcCtKTVUw1zPWM1RIqlRwSAPKJUKldBUySkoKiq309ZFE9ZLzcxV8MpNT84rxqNDPgajQTwMZ75xfUFmUmZ5RomBkYGSmALI/Mzk/r1hHwTMvWQ8ABXAx8CqAOMQAAACiSURBVBjTbc8/UsJgEIbxX0LQgRlGC6W2omGA23AFGi28AnfA03ihhKGwscgQliIEPzBb7b/32XfpjRCbKIv75jVeTPMe2dhTm/QN3+0MBUUPcGbl8b9yYoLQtGVqKLfF5x+kSIADc5Gud9hnY+HklF7JA0a+fIjUVYt99ePBwq/s/qfct7VGcwvslEtvyGRctFnHKFT2aqXKUYmjSql2UJ0BVLEpJKBtW7EAAAAASUVORK5CYII=",
    loss = "iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAQAAAC1QeVaAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAACYktHRAAAqo0jMgAAAAd0SU1FB+oIDwkOBmspeucAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjYtMDgtMTVUMDk6MTQ6MDYrMDA6MDCmE3fKAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI2LTA4LTE1VDA5OjE0OjA2KzAwOjAw107PdgAAACh0RVh0ZGF0ZTp0aW1lc3RhbXAAMjAyNi0wOC0xNVQwOToxNDowNiswMDowMIBb7qkAAADVSURBVBjTbY8hS0NhGEbPtzvvFEwmBwYt3mBZNZkG02IbmkSFZeN+gbA/sSZrVvEHmMQyGIjJZBLBCbKx7R6Dn5epO+m8nKe8EBFx2aqpyB/ExJY3Nv9FEXd9Uftmv7KIq/acqiM7JnNZxAs//ObZ/SKKmHmnvtt2onZdE2NKvTRXXz1wrI49ESkBsMcxAQhUCEDKEVtQAtY5ZROAMhkBgAaHpJh47g8z38yjP1nDHe+L+OmV0+i513hWbHXkrbPisswjA7bjw4E6k+g5D8ElNlhhEcMvpM27GnDpAHMAAAAASUVORK5CYII=",
    clock = "iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAYAAAAfSC3RAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAzElEQVR4nK2SQQ6CMBBFWekxRG9hDLpy7QrW4plYWMGQeBj1AHoUdPnMT4ak1gYX2uQnzHReO/NpkvxrASvgCFyAM9AAyyFgDJyADnDA1uQs16omBgq6AROL15J9p7bXxtrershyleTFqdVkPqiZ9sFhlQ9a7gDUfuIKlBGwCXI7mfYN3ABPoBgCZbmLGFYYnFtcq12/ILPBpxE4B+bADHgAi7BA/0mWpxFY0F0mhnv9AxCsm+VeaVJ7uknOjz7AoG3NrOcmCXxv75f1AuUNNMS82KlpAAAAAElFTkSuQmCC",
    neverlose = "iVBORw0KGgoAAAANSUhEUgAAABYAAAAWCAMAAADzapwJAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAJMUExURQAAAOXq7PLy9Pj4+v////r6/Pr6+6fBzxFagBZaf1FcYND1/67d8+/z9gmr9AhZfzZ2lVGHopy4xf///zM+QwpXfCdukVGJo5m2xf///wVRcw5dhUB+mmGOo+Lk5fz6+wxsm/f5+fz9/f///wAAAANhkPf6+////wBJcyKBrfH19vv8+/n4+wx7sP7+/v3+/wRqnP///wBKdSWUx/7+/vr6/Ax5r/3+/eHZ1QRpnQBKdyWTx/7+/vr6+wx5r/7+/fn3+AFonABKeCSTx/z7+ymAqySTxvr6/P///YG61ABKegx6r/f8/WXF7gBKewx6r/7+/XvI613D7////wBKef39/v/8/gx6sP3+/OXu9Ram5wBKdfr8+6C8ygAUSQAuXwAGPvz9/Pz69wCS4Um87SSTxu/19nqluV2Rql2Tq3qkt/b39wx6sPT29g+l6ABLdSSTx/39/A+Bt/n8/PP19wCa4zW07f7//gBFbyibzfr8/BWf21zA6YHO653U6vDx9A+i5FO96YDN6o/R6tru9CWm23DH64HO7IHP7ILP7YLP7YLO7IPP7LXg7p/M3+3z9W2x0Ozz9cvk7q3g9f///3jH6t71/a3g9P///v/+/v7//nfG6d30/f7+/f7+/t31/fj8+uv3+nbG6fH6/KXd8/b8/XjH68Dp+Nnv+JjX8vz+/f7///P7/fv+/trw9/v9/dz1/ang9v///f7+/9z0/eb2+6zf9I7W9P7//fX5+vT4+ff6+6rg9P3//dDv+fv+/dnz/P3//vz+/gAAADE0SbgAAACOdFJOUwAAAAAAAAAAAAAAAAAAAMnQymIUAonQyWUXN8zVqTgG9veVBAKq9nJC+v7NGfPxRql8QffcG/S3D6ZA99sa9fpjoz/30cH3Gv74PvT88j7z95fuez7cG/T5UZo/3igNDwj6SSvj+PTKy82cRPZMfkD46Mn6SxrMfSvc7mbw9sQjZvP23kSW9/Ly8vHy8JssXrF2AAAAAWJLR0QAiAUdSAAAAAd0SU1FB+oIDwgxCjuDdscAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjYtMDgtMTVUMDg6NDg6MzcrMDA6MDA4Fu7UAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI2LTA4LTE1VDA4OjQ4OjM3KzAwOjAwSUtWaAAAACh0RVh0ZGF0ZTp0aW1lc3RhbXAAMjAyNi0wOC0xNVQwODo0OToxMCswMDowMHYeJXoAAAExSURBVBjTY2CgIeAXEBQSZhQRFROXkJSSlpGVk2cCCSv09SsqKauoTpiopq6hOUlLW4cZJKw7ecoUPX0Wg6lTphgaGU+bYmLKChI2mz5j5ixzC8vZQGEr6zlTbGzZQMJ202fMnWfv4AgSdnKejyS8YOE8F9dFIGE3oLA7K1R48ZKlHp7LZkwx9AKpdger9p4+w8d3+YwVK1etNvQDCkOt9J8+IyAwaM3adetnBIc4b5gRGsbOwcnFED59RkRk1MZNm1dPCY5227IpJjYuPoEFZEhiUnLK1ilTpgQbpW6YkpaekZmVzZCzbVNiLnfe9rlzdxjmF8yZsWrnrl27CxmK9uwtLuEpLdu3an95ReWBg2sPHVq7v4qhuqa2rp6Xr6GxqbmFpbWtvaOzq7unl5aRAwCBLnQTxYlAtQAAAABJRU5ErkJggg==",
    sqrt = "iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAYAAAAfSC3RAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAmUlEQVR4nM3QMQ4BQRQG4G01NgoaHdFqtEq1zgE0XIALqFxA4wYah3AHN9CQaEgUIj7ZZIolWUYh8SeTTF7mS/43SfKXQRujcIYox6AyDp4ziIEz3NBBBWkMquGEZdGDJnrovswXuKBeBDe5/uMwa+GK+btKKRpY4xzuKxyzvWJ2qmKPLe6YfkQ53A+VdyhFw4An2Wd9hX6eB259snjhlCxcAAAAAElFTkSuQmCC",
  }
  local function f1(data)
    local b =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    data = data:gsub("[^" .. b .. "=]", "")
    return data:gsub(".", function(x)
      if x == "=" then
        return ""
      end
      local r, f = "", (b:find(x, 1, true) - 1)
      for i = 6, 1, -1 do
        r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) >= 1 and "1" or "0")
      end
      return r
    end):gsub("%d%d%d?%d?%d?%d?%d?%d?", function(x)
      if #x ~= 8 then
        return ""
      end
      local c = 0
      for i = 1, 8 do
        c = c + (x:sub(i, i) == "1" and 2 ^ (8 - i) or 0)
      end
      return string.char(c)
    end)
  end
  local nl = { master_alpha = 0, held_w = 0, shrink_start = nil, SHRINK_DELAY = 5, last_vis_count = 0, last_t = nil, order = { "username", "clock", "fps", "ping", "var", "loss", "timeout" }, blocks = {}, prev_block_visible = nil, releasing = false, release_start = nil, loss_hide_timer = nil, loss_was_bad = false, var_hide_timer = nil, var_was_bad = false, HIDE_DELAY = 5, ft_samples = {}, ft_count = 0, cache = {
    uname = "user",
    time_str = "00:00",
    ping = 0,
    fps = 0,
    loss = 0,
    var = 0,
    last_update = 0,
  }, tex = {}, tex_loaded = false, av_tex = nil, av_next_try = 0, font = nil }
  local function f2(a, b, t)
    t = clamp(t or 0, 0, 1)
    return a + (b - a) * t
  end
  local function f3()
    if nl.font then
      return nl.font
    end
    nl.font = load_verified_font(nl.font, 12, "ab")
    return nl.font
  end
  local function f4(text)
    local ok, size =
        pcall(render.measure_text, f3(), nil, tostring(text or ""))
    return (ok and size and size.x) or 0
  end
  local function f5()
    local ok, size = pcall(render.measure_text, f3(), nil, "0")
    return (ok and size and size.y) or 12
  end
  local function f6(x, y, r, g, b, a, text)
    render.text(
            f3(),
            vector(x, y),
            color(r, g, b, a),
            nil,
            tostring(text or ""))
  end
  local function f7(x, y, w, h, radius, clr)
    radius = math.min(w / 2, h / 2, radius)
    render.rect(
            vector(x, y),
            vector(x + w, y + h),
            color(clr[1], clr[2], clr[3], clr[4]),
            radius)
  end
  local NL_DEFAULT_ELEMENTS = {
    Avatar = true,
    Username = true,
    Clock = true,
    FPS = true,
    Ping = true,
    Build = true,
  }
  local function f8(name)
    local ok, sel = pcall(function()
      return app.wm_nl_elements:get()
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
  local function f9(id)
    local label_name = NL_BLOCK_LABEL[id]
    if not label_name then
      return true
    end
    return f8(label_name)
  end
  local function f10()
    local ok, a = pcall(ui.get_alpha)
    return ok and type(a) == "number" and a > 0
  end
  local function f11()
    local ok, c = pcall(function()
      return app.wm_nl_accent:get()
    end)
    if ok and c then
      local r, g, b = tonumber(c.r), tonumber(c.g), tonumber(c.b)
      if r and g and b then
        return { r, g, b }
      end
    end
    return { 185, 190, 255 }
  end
  local function f12()
    local ok, t = pcall(function()
      return common.get_system_time()
    end)
    if ok and type(t) == "table" then
      return string.format(
              "%02d:%02d",
              tonumber(t.hours) or 0,
              tonumber(t.minutes) or 0)
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
    sqrt = 14,
  }
  local function f13()
    if nl.tex_loaded then
      return
    end
    nl.tex_loaded = true
    for name, raw in pairs(nl_ico_raw) do
      local ok, img = pcall(function()
        return render.load_image(
                  f1(raw),
                  vector(NL_ICON_SIZE[name], NL_ICON_SIZE[name]))
      end)
      if ok and img then
        nl.tex[name] = img
      end
    end
  end
  local function f14()
    if nl.av_tex then
      return
    end
    local now = finite(globals.realtime) or 0
    if now < nl.av_next_try then
      return
    end
    nl.av_next_try = now + 2
    local ok, img = pcall(function()
      local lp = entity.get_local_player()
      return lp and lp:get_steam_avatar() or nil
    end)
    if ok and img then
      nl.av_tex = img
    end
  end
  local function f15(x, y, w, h, rad)
    rad = rad or math.floor(h / 2)
    if w <= 0 or h <= 0 then
      return
    end
    if f8("Blur") then
      pcall(function()
        render.blur(vector(x, y), vector(x + w, y + h), 8, 0.9, rad)
      end)
    end
    f7(x, y, w, h, rad, { 10, 10, 10, 150 })
  end
  local function f16(x, y, w, h, alpha)
    if w <= 0 or h <= 0 or alpha <= 0 then
      return
    end
    local rad = math.floor(h / 2)
    f7(
        x - 2,
        y - 2,
        w + 4,
        h + 4,
        rad + 2,
        { 78, 82, 90, math.floor(34 * alpha) })
    f7(
        x - 4,
        y - 4,
        w + 8,
        h + 8,
        rad + 4,
        { 64, 68, 75, math.floor(18 * alpha) })
    f7(
        x - 7,
        y - 7,
        w + 14,
        h + 14,
        rad + 7,
        { 52, 55, 62, math.floor(8 * alpha) })
  end
  local function f17(ft)
    nl.ft_count = nl.ft_count + 1
    nl.ft_samples[(nl.ft_count % 100) + 1] = ft
    local now = finite(globals.realtime) or 0
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
          loss =
              math.floor(((tonumber(lo) or 0) + (tonumber(li) or 0)) * 100)
        end
      end
    end
    nl.cache.ping = ping
    nl.cache.loss = loss
    local ok_u, uname = pcall(function()
      return common.get_username()
    end)
    nl.cache.uname =
        (ok_u and type(uname) == "string" and uname ~= "") and uname or "user"
    nl.cache.time_str = f12()
  end
  local function f18(def)
    return {
      id = def.id,
      visible_fn = def.visible_fn,
      measure_fn = def.measure_fn,
      render_fn = def.render_fn,
      no_shrink_delay = def.no_shrink_delay or false,
      alpha = 0,
      width = 0,
      target_w = 0,
      held_target_w = 0,
      block_shrink_start = nil,
      visible = false,
    }
  end
  local nl_blocks_inited = false
  local function init_blocks()
    if nl_blocks_inited then
      return
    end
    nl_blocks_inited = true
    nl.blocks = { avatar = f18({ id = "avatar", visible_fn = function(ctx)
      return f9("avatar") and nl.av_tex ~= nil
    end, measure_fn = function(ctx)
      return 24
    end, render_fn = function(ctx, x, y, w, h, alpha)
      if alpha <= 0.01 then
        return
      end
      local AV = 20
      local ay = y + math.floor((h - AV) / 2)
      render.texture(
               nl.av_tex,
               vector(x - 6, ay),
               vector(AV, AV),
               color(255, 255, 255, math.floor(255 * alpha)),
               "f",
               AV / 2)
    end }), username = f18({ id = "username", visible_fn = function(ctx)
      return f9("username")
    end, measure_fn = function(ctx)
      return 18 + f4(ctx.uname) + 12
    end, render_fn = function(ctx, x, y, w, h, alpha)
      if alpha <= 0.01 then
        return
      end
      local ICO, IGAP = 14, 4
      local a255 = math.floor(255 * alpha)
      local ay = y + math.floor((h - ICO) / 2)
      local ty = y + math.floor((h - ctx.th0) / 2)
      if nl.tex.user then
        render.texture(
               nl.tex.user,
               vector(x, ay),
               vector(ICO, ICO),
               color(ctx.accent[1], ctx.accent[2], ctx.accent[3], a255),
               "f")
      end
      f6(x + ICO + IGAP, ty, 210, 210, 210, a255, ctx.uname)
    end }), clock = f18({ id = "clock", visible_fn = function(ctx)
      return f9("clock")
    end, measure_fn = function(ctx)
      return 18 + f4(ctx.time_str) + 12
    end, render_fn = function(ctx, x, y, w, h, alpha)
      if alpha <= 0.01 then
        return
      end
      local ICO, IGAP = 14, 4
      local a255 = math.floor(255 * alpha)
      local ay = y + math.floor((h - ICO) / 2)
      local ty = y + math.floor((h - ctx.th0) / 2)
      local cx, cy = x + 7, ay + 7
      local ac = color(ctx.accent[1], ctx.accent[2], ctx.accent[3], a255)
      render.circle_outline(vector(cx, cy), ac, 5, 0, 1, 1)
      render.line(vector(cx, cy), vector(cx, cy - 3), ac)
      render.line(vector(cx, cy), vector(cx + 2, cy + 1), ac)
      f6(x + ICO + IGAP, ty, 210, 210, 210, a255, ctx.time_str)
    end }), fps = f18({ id = "fps", visible_fn = function(ctx)
      return f9("fps")
    end, measure_fn = function(ctx)
      return 18 + f4(tostring(ctx.fps)) + 3 + f4("FPS") + 12
    end, render_fn = function(ctx, x, y, w, h, alpha)
      if alpha <= 0.01 then
        return
      end
      local ICO, IGAP, BGAP = 14, 4, 12
      local a255 = math.floor(255 * alpha)
      local ay = y + math.floor((h - ICO) / 2)
      local ty = y + math.floor((h - ctx.th0) / 2)
      local fr, fg, fb = ctx.accent[1], ctx.accent[2], ctx.accent[3]
      if ctx.fps <= 50 then
        fr, fg, fb = 255, 35, 35
      elseif ctx.fps <= 100 then
        fr, fg, fb = 235, 105, 90
      elseif ctx.fps <= 200 then
        fr, fg, fb = 235, 190, 55
      end
      if nl.tex.fps then
        render.texture(
               nl.tex.fps,
               vector(x, ay),
               vector(ICO, ICO),
               color(fr, fg, fb, a255),
               "f")
      end
      f6(x + ICO + IGAP, ty, 210, 210, 210, a255, tostring(ctx.fps))
      f6(x + w - BGAP - f4("FPS"), ty, 210, 210, 210, a255, "FPS")
    end }), ping = f18({ id = "ping", visible_fn = function(ctx)
      return f9("ping")
    end, measure_fn = function(ctx)
      return 14 + f4(tostring(ctx.ping)) + 3 + f4("MS") + 12
    end, render_fn = function(ctx, x, y, w, h, alpha)
      if alpha <= 0.01 then
        return
      end
      local ICO, IGAP, BGAP = 10, 4, 12
      local a255 = math.floor(220 * alpha)
      local ay = y + math.floor((h - ICO) / 2)
      local ty = y + math.floor((h - ctx.th0) / 2)
      if nl.tex.ping then
        render.texture(
               nl.tex.ping,
               vector(x, ay),
               vector(ICO, ICO),
               color(ctx.accent[1], ctx.accent[2], ctx.accent[3], a255),
               "f")
      end
      f6(x + ICO + IGAP, ty, 210, 210, 210, a255, tostring(ctx.ping))
      f6(x + w - BGAP - f4("MS"), ty, 210, 210, 210, a255, "MS")
    end }), loss = f18({ id = "loss", visible_fn = function(ctx)
      if not f9("loss") then
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
        nl.loss_hide_timer = finite(globals.realtime) or 0
      end
      if ((finite(globals.realtime) or 0) - nl.loss_hide_timer) < nl.HIDE_DELAY then
        return true
      end
      nl.loss_was_bad = false
      return false
    end, measure_fn = function(ctx)
      local val = tostring(ctx.loss) .. "%"
      return 19 + f4(val) + 3 + f4("LOSS") + 12
    end, render_fn = function(ctx, x, y, w, h, alpha)
      if alpha <= 0.01 then
        return
      end
      local ICO, IGAP, BGAP = 14, 4, 12
      local a255 = math.floor(255 * alpha)
      local ay = y + math.floor((h - ICO) / 2)
      local ty = y + math.floor((h - ctx.th0) / 2)
      local val = tostring(ctx.loss) .. "%"
      local lr, lg, lb = ctx.accent[1], ctx.accent[2], ctx.accent[3]
      if ctx.loss > 0 then
        lr, lg, lb = 220, 60, 60
      end
      if nl.tex.loss then
        render.texture(
               nl.tex.loss,
               vector(x, ay),
               vector(ICO, ICO),
               color(lr, lg, lb, a255),
               "f")
      end
      f6(x + ICO + IGAP, ty, lr, lg, lb, a255, val)
      f6(x + w - BGAP - f4("LOSS"), ty, lr, lg, lb, a255, "LOSS")
    end }), var = f18({ id = "var", visible_fn = function(ctx)
      if not f9("var") then
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
        nl.var_hide_timer = finite(globals.realtime) or 0
      end
      if ((finite(globals.realtime) or 0) - nl.var_hide_timer) < nl.HIDE_DELAY then
        return true
      end
      nl.var_was_bad = false
      return true
    end, measure_fn = function(ctx)
      local val = string.format("%.0f", ctx.var)
      return 20 + f4(val) + 3 + f4("VAR") + 12
    end, render_fn = function(ctx, x, y, w, h, alpha)
      if alpha <= 0.01 then
        return
      end
      local ICO, IGAP, BGAP = 16, 4, 12
      local a255 = math.floor(255 * alpha)
      local ay = y + math.floor((h - ICO) / 2)
      local ty = y + math.floor((h - ctx.th0) / 2)
      local val = string.format("%.0f", ctx.var)
      local vr, vg, vb = 210, 210, 210
      if ctx.var >= 5 then
        vr, vg, vb = 220, 60, 60
      elseif ctx.var >= 3 then
        vr, vg, vb = 220, 180, 60
      end
      if nl.tex.sqrt then
        render.texture(
               nl.tex.sqrt,
               vector(x, ay),
               vector(ICO, ICO),
               color(ctx.accent[1], ctx.accent[2], ctx.accent[3], a255),
               "f")
      end
      f6(x + ICO + IGAP, ty, vr, vg, vb, a255, val)
      f6(x + w - BGAP - f4("VAR"), ty, vr, vg, vb, a255, "VAR")
    end }), timeout = f18({ id = "timeout", visible_fn = function(ctx)
      return f9("timeout")
    end, measure_fn = function(ctx)
      return 32
    end, render_fn = function(ctx, x, y, w, h, alpha)
      if alpha <= 0.01 then
        return
      end
      local ICON = 18
      local a255 = math.floor(255 * alpha)
      local iy = y + math.floor((h - ICON) / 2)
      if nl.tex.neverlose then
        render.texture(
               nl.tex.neverlose,
               vector(x - 1, iy),
               vector(ICON, ICON),
               color(255, 255, 255, a255),
               "f")
      end
    end }) }
    for id, block in pairs(nl.blocks) do
      block.alpha, block.width, block.target_w, block.held_target_w =
          0,
          0,
          0,
          0
      block.block_shrink_start = nil
      block.visible = false
    end
  end
  notifications_render_ok = function(alpha)
    if not alpha or alpha <= 0 then
      return
    end
    f13()
    init_blocks()
    f14()
    nl.master_alpha = f2(nl.master_alpha, alpha > 0.01 and 1 or 0, 0.18)
    if nl.master_alpha < 0.01 then
      return
    end
    local screen = render.screen_size()
    local sw, sh = screen.x, screen.y
    local ok_ts, ts = pcall(function()
      return common.get_timestamp()
    end)
    local now = (ok_ts and type(ts) == "number") and ts / 1000 or
      (finite(globals.realtime) or 0)
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
    local ft = finite(globals.frametime) or 0
    f17(ft)
    local ctx = {
      uname = nl.cache.uname,
      time_str = nl.cache.time_str,
      ping = nl.cache.ping,
      fps = math.floor(nl.cache.fps + 0.5),
      loss = nl.cache.loss,
      var = nl.cache.var,
      menu_open = f10(),
      accent = f11(),
      th0 = f5(),
    }
    local H, PAD, GAP = 36, 12, 0
    for id, block in pairs(nl.blocks) do
      local visible = block.visible_fn(ctx) and nl.master_alpha > 0.01
      block.visible = visible
      local target = 0
      if visible then
        target = block.measure_fn(ctx) * nl.master_alpha
      end
      block.alpha = f2(
          block.alpha,
          visible and nl.master_alpha or 0,
          math.min(12 * dt, 1))
      if not visible then
        block.held_target_w = 0
        block.block_shrink_start = nil
      elseif block.no_shrink_delay then
        block.held_target_w = target
        block.block_shrink_start = nil
      else
        if target >= (block.held_target_w or 0) then
          block.held_target_w = target
          block.block_shrink_start = nil
        elseif not block.block_shrink_start then
          block.block_shrink_start = now
        elseif (now - block.block_shrink_start) >= nl.SHRINK_DELAY then
          block.held_target_w = target
          block.block_shrink_start = nil
        end
      end
      block.target_w = block.held_target_w or 0
      block.width = f2(block.width, block.target_w, math.min(14 * dt, 1))
      if block.width < 0.5 then
        block.width = 0
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
      nl.prev_block_visible = {}
    end
    for id, block in pairs(nl.blocks) do
      nl.prev_block_visible[id] = block.visible
    end
    local menu_vis_count = 1
    for _, id in ipairs({ "avatar", "username", "clock", "fps", "ping", "var", "loss" }) do
      if f9(id) then
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
        if nl.release_start and (now - nl.release_start) > 1 then
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
    local ok_pos, pos_v = pcall(function()
      return app.wm_position:get()
    end)
    local pos =
        (ok_pos and type(pos_v) == "string") and pos_v or "Top-right"
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
      f16(x, y, bg_w, H, nl.master_alpha)
      f15(x, y, bg_w, H)
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
end
)();
(
  function()
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
  local SPEC_ICON_B64 =
      "iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAYAAAAfSC3RAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAlElEQVR4nNXRXQpBURTFccU0XF/XpMRYGAQT8TkKYgAIr5jCTzdbTsoDT6xatc9a/Wufc0ql/xQq6GGKPXaYoFt076A2Nu46Yxi+RLZG/go1cUqgatJlCXxEIwUXnhpGNkA/5lHSz78FZylYjzXEWlnS1XCN7lCcX++ZY5XAo/ADWqL17mXL6GCMbbiYi6z8wc/+km51AhQKQZUdiwAAAABJRU5ErkJggg=="
  local function f1(data)
    local b =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    data = data:gsub("[^" .. b .. "=]", "")
    return data:gsub(".", function(x)
      if x == "=" then
        return ""
      end
      local r, f = "", (b:find(x, 1, true) - 1)
      for i = 6, 1, -1 do
        r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) >= 1 and "1" or "0")
      end
      return r
    end):gsub("%d%d%d?%d?%d?%d?%d?%d?", function(x)
      if #x ~= 8 then
        return ""
      end
      local c = 0
      for i = 1, 8 do
        c = c + (x:sub(i, i) == "1" and 2 ^ (8 - i) or 0)
      end
      return string.char(c)
    end)
  end
  local wg = {
    font = nil,
    icon = nil,
    icon_tried = false,
    av_cache = {},
    av_retry = {},
    spec_master = 0,
    spec_alpha = 0,
    spec_header_alpha = 0,
    spec_rows = {},
  }
  local function f2()
    if wg.font then
      return wg.font
    end
    wg.font = load_verified_font(wg.font, 12, "ab")
    return wg.font
  end
  local function f3(text)
    local ok, size =
        pcall(render.measure_text, f2(), nil, tostring(text or ""))
    return (ok and size and size.x) or 0
  end
  local function f4()
    local ok, size = pcall(render.measure_text, f2(), nil, "0")
    return (ok and size and size.y) or 12
  end
  local function f5(x, y, r, g, b, a, text)
    render.text(
            f2(),
            vector(x, y),
            color(r, g, b, a),
            nil,
            tostring(text or ""))
  end
  local function f6(x, y, w, h, rad, clr)
    rad = math.min(w / 2, h / 2, rad)
    render.rect(
            vector(x, y),
            vector(x + w, y + h),
            color(clr[1], clr[2], clr[3], clr[4]),
            rad)
  end
  local function f7(a, b, factor)
    a = a or b or 0
    b = b or a
    local ft = math.max(finite(globals.frametime) or 0, 0)
    local t = 1 - math.pow(1 - clamp(factor or 0.18, 0, 0.99), ft * 60)
    return a + (b - a) * t
  end
  local function f8()
    local ok, a = pcall(ui.get_alpha)
    return ok and type(a) == "number" and a > 0
  end
  local function f9()
    local ok, c = pcall(function()
      return app.wm_nl_accent:get()
    end)
    if ok and c then
      local r, g, b = tonumber(c.r), tonumber(c.g), tonumber(c.b)
      if r and g and b then
        return { r, g, b }
      end
    end
    return { 185, 190, 255 }
  end
  local function f10(x, y, w, h, radius, alpha)
    radius = radius or math.floor(h / 2)
    if w <= 0 or h <= 0 then
      return
    end
    pcall(function()
      render.blur(vector(x, y), vector(x + w, y + h), 8, alpha, radius)
    end)
    f6(x, y, w, h, radius, { 10, 10, 10, math.floor(150 * alpha) })
  end
  local function f11(x, y, w, h, radius, a1, alpha)
    local r, g, b = a1[1], a1[2], a1[3]
    radius = math.min(radius or math.floor(h / 2), math.floor(h / 2))
    if radius <= 0 or w <= 0 or h <= 0 then
      return
    end
    for i = 0, radius * 2 - 1 do
      local dy = i - radius + 0.5
      local abs_dy = math.abs(dy)
      if abs_dy <= radius then
        local inset =
            radius - math.sqrt(math.max(0, radius * radius - dy * dy))
        local line_alpha = math.floor(alpha * (1 - abs_dy / radius))
        local line_w = w - inset
        if line_w > 0 and line_alpha > 0 then
          render.rect(
              vector(x + (w - line_w), y + i),
              vector(x + w, y + i + 1),
              color(r, g, b, line_alpha))
        end
      end
    end
  end
  local function f12()
    if wg.icon_tried then
      return
    end
    wg.icon_tried = true
    local ok, img = pcall(function()
      return render.load_image(f1(SPEC_ICON_B64), vector(14, 14))
    end)
    if ok and img then
      wg.icon = img
    end
  end
  local function f13(idx, ent)
    local cached = wg.av_cache[idx]
    if cached ~= nil then
      return cached or nil
    end
    local now = finite(globals.realtime) or 0
    if (wg.av_retry[idx] or 0) > now then
      return nil
    end
    wg.av_retry[idx] = now + 2
    local ok, img = pcall(function()
      return ent:get_steam_avatar()
    end)
    if ok and img then
      wg.av_cache[idx] = img
      return img
    end
    return nil
  end
  local function f14(ent, lp, lp_idx)
    local ok, t = pcall(function()
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
      local m = bit.band(t, 32767)
      if m == lp_idx or m == lp_idx - 1 then
        return true
      end
    end
    return false
  end
  local function f15()
    local result = {}
    local lp = entity.get_local_player()
    if lp then
      local ok_alive, alive = pcall(function()
        return lp:is_alive()
      end)
      if ok_alive and alive then
        local ok_idx, lp_idx = pcall(function()
          return lp:get_index()
        end)
        lp_idx = (ok_idx and tonumber(lp_idx)) or nil
        local maxp = tonumber(globals.max_players) or 64
        for i = 1, maxp do
          local ent = entity.get(i)
          if ent and ent ~= lp then
            local ok, is_spec = pcall(function()
              if ent:is_alive() then
                return false
              end
              local mode = ent.m_iObserverMode
              if mode ~= 4 and mode ~= 5 then
                return false
              end
              return f14(ent, lp, lp_idx)
            end)
            if ok and is_spec then
              local ok_n, name = pcall(function()
                return ent:get_name()
              end)
              result[#result + 1] = {
                name = (ok_n and name and name ~= "") and name or "unknown",
                avatar = f13(i, ent),
                placeholder = false,
                key = tostring(i),
              }
            end
          end
        end
      end
    end
    if #result == 0 and f8() then
      local preview = "user"
      local ok_n, name = pcall(function()
        return common.get_username()
      end)
      if ok_n and name and name ~= "" then
        preview = name
      end
      local av = nil
      if lp then
        local ok_a, img = pcall(function()
          return lp:get_steam_avatar()
        end)
        if ok_a then
          av = img
        end
      end
      result[1] = {
        name = preview,
        avatar = av,
        placeholder = true,
        key = "placeholder",
      }
    end
    return result
  end
  local function f16(x, y, w, h, title, a1, text_color, alpha)
    local a255 = math.floor(255 * alpha)
    if a255 <= 0 then
      return
    end
    f10(x, y, w, h, 10, alpha)
    local title_w = f3(title)
    local left_edge = x + SPEC.pad_x + 5
    local right_edge = x + w - SPEC.pad_x
    local title_x = left_edge
    if right_edge > left_edge then
      title_x =
          left_edge + math.floor(((right_edge - left_edge) - title_w) / 2 + 0.5)
    end
    local ty = y + math.floor((h - f4()) / 2)
    if wg.icon then
      local iy = y + math.floor((h - 14) / 2)
      render.texture(
               wg.icon,
               vector(x + SPEC.pad_x, iy),
               vector(14, 14),
               color(a1[1], a1[2], a1[3], a255),
               "f")
    end
    f5(
        title_x,
        ty,
        text_color[1],
        text_color[2],
        text_color[3],
        a255,
        title)
  end
  local function f17(x, y, w, entry, a1, text_color, alpha)
    local a255 = math.floor(255 * alpha)
    if a255 <= 0 then
      return
    end
    local pad, av = SPEC.pad_x, SPEC.av_size
    f10(x, y, w, SPEC.row_h, 10, alpha)
    f11(x + 2, y + 3, 5, SPEC.row_h - 4, 10, a1, a255)
    local text_x = x + pad + SPEC.tri_w + SPEC.tri_gap + 4
    local ty = y + math.floor((SPEC.row_h - f4()) / 2)
    f5(
        text_x,
        ty,
        text_color[1],
        text_color[2],
        text_color[3],
        a255,
        tostring(entry.name or "unknown"))
    local avatar_x = x + w - av - 1
    local avatar_y = y + math.floor((SPEC.row_h - av) / 2)
    if entry.avatar then
      render.texture(
               entry.avatar,
               vector(avatar_x, avatar_y),
               vector(av, av),
               color(255, 255, 255, a255),
               "f",
               av / 2)
    else
      render.circle(
              vector(avatar_x + av / 2, avatar_y + av / 2),
              color(30, 30, 30, a255),
              av / 2,
              0,
              1)
    end
  end
  local function f18()
    local v1 = item_enabled(app.spectators)
    wg.spec_master = f7(wg.spec_master, v1 and 1 or 0, 0.18)
    local lp = entity.get_local_player()
    if not lp and not f8() then
      wg.spec_alpha, wg.spec_header_alpha, wg.spec_rows = 0, 0, {}
      return
    end
    local header_enabled = item_enabled(app.specs_header)
    local screen = render.screen_size()
    local sw, sh = screen.x, screen.y
    local specs = v1 and f15() or {}
    local count = #specs
    local content_w = SPEC.min_w
    for _, spec in ipairs(specs) do
      local name_w = f3(spec.name)
      content_w = math.max(content_w, name_w + SPEC.pad_x + SPEC.tri_w + SPEC.tri_gap + SPEC.av_size +
        SPEC.pad_x * 2 + 4)
    end
    if header_enabled then
      content_w = math.max(content_w, f3("Spectators") + SPEC.pad_x * 2 + 4)
    end
    local row_w = content_w
    local base_x, base_y, total_h
    if not header_enabled then
      total_h = count * SPEC.row_h + math.max(0, count - 1) * SPEC.gap_y
      base_x = sw - SPEC.right_gap - row_w
      base_y = math.floor(sh * 0.5 - total_h * 0.5 - 10)
    else
      total_h = SPEC.header_h + SPEC.gap_y + count * SPEC.row_h +
        math.max(0, count - 1) * SPEC.gap_y
      base_x = sw - row_w - 10
      base_y = math.floor(sh * 0.5 - 58)
    end
    base_x = clamp(base_x, 0, math.max(0, sw - row_w))
    base_y = clamp(base_y, 0, math.max(0, sh - math.max(total_h, 1)))
    local v2 = f9()
    local text_color = { 215, 218, 224 }
    local row_step = SPEC.row_h + SPEC.gap_y
    local function f1(entry)
      return f3(entry.name) + SPEC.pad_x + SPEC.tri_w + SPEC.tri_gap + SPEC.av_size +
        SPEC.pad_x * 2 + 4
    end
    local seen = {}
    for i, entry in ipairs(specs) do
      local key = entry.key or tostring(entry.name)
      local target_y = base_y + (header_enabled and SPEC.header_h + SPEC.gap_y or 0) +
        (i - 1) * row_step
      local target_w = header_enabled and row_w or f1(entry)
      seen[key] = true
      local row = wg.spec_rows[key]
      if not row then
        row = {
          alpha = 0,
          y_offset = header_enabled and -SPEC.row_h or 0,
          cur_y = target_y,
          w = target_w,
          removing = false,
          entry = entry,
        }
        wg.spec_rows[key] = row
      else
        row.removing = false
        row.entry = entry
      end
      row.cur_y = f7(row.cur_y, target_y, 0.25)
      row.w = f7(row.w, target_w, 0.22)
    end
    for key, row in pairs(wg.spec_rows) do
      if not seen[key] then
        row.removing = true
      end
    end
    local any_active = count > 0
    wg.spec_alpha =
        f7(wg.spec_alpha, any_active and wg.spec_master or 0, 0.18)
    local has_removing = false
    for _, row in pairs(wg.spec_rows) do
      if row.removing and (row.alpha or 0) > 0.01 then
        has_removing = true
        break
      end
    end
    if header_enabled then
      wg.spec_header_alpha = f7(
          wg.spec_header_alpha,
          (any_active or has_removing) and wg.spec_master or 0,
          0.18)
    else
      wg.spec_header_alpha = f7(wg.spec_header_alpha, 0, 0.18)
    end
    if wg.spec_alpha < 0.01 and wg.spec_header_alpha < 0.01 and not any_active and
      not has_removing then
      wg.spec_rows = {}
      return
    end
    f12()
    local header_bottom = base_y + (header_enabled and SPEC.header_h or 0)
    local render_list = {}
    for key, row in pairs(wg.spec_rows) do
      render_list[#render_list + 1] = { key = key, row = row }
    end
    table.sort(render_list, function(a, b)
      return (a.row.cur_y or 0) < (b.row.cur_y or 0)
    end)
    local to_remove = {}
    for _, data in ipairs(render_list) do
      local key, row = data.key, data.row
      if row.removing then
        if header_enabled then
          row.y_offset = f7(row.y_offset or 0, -SPEC.row_h, 0.22)
        end
        row.alpha = f7(row.alpha or 0, 0, 0.18)
        if row.alpha < 0.01 then
          to_remove[#to_remove + 1] = key
        end
      else
        if header_enabled then
          row.y_offset = f7(row.y_offset or 0, 0, 0.22)
          if (row.y_offset or 0) > -0.5 then
            row.y_offset = 0
          end
        end
        row.alpha = f7(row.alpha or 0, wg.spec_alpha, 0.18)
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
        local row_x =
            header_enabled and base_x or (sw - SPEC.right_gap - draw_w - 2)
        f17(row_x, draw_y, draw_w, row.entry, v2, text_color, final_alpha)
      end
    end
    for _, key in ipairs(to_remove) do
      wg.spec_rows[key] = nil
    end
    if header_enabled and wg.spec_header_alpha > 0.01 then
      f16(
          base_x,
          base_y,
          row_w,
          SPEC.header_h,
          "Spectators",
          v2,
          text_color,
          wg.spec_header_alpha)
    end
  end
  widget_tick = function()
    pcall(f18)
  end
end
)()
local ui_reset_done = false
local function f4()
  if ui_reset_done then
    return
  end
  ui_reset_done = true
  pcall(function()
    app.section:set(1)
  end)
  pcall(function()
    app.workspace:set(1)
  end)
  pcall(function()
    if app.scope_runtime and app.scope_runtime.native then
      app.scope_runtime.native:override()
    end
  end)
  for _, item in ipairs({
    app.resolver,
    app.assist,
    app.yaw,
    app.forceshot,
    app.extrapolation,
    app.unsafe_recharge,
    app.movement,
    app.fast_ladder,
    app.no_fall_damage,
    app.avoid_collision,
    app.jump_scout,
    app.aspect,
    app.crosshair_indicator,
    app.damage_indicator,
    app.side_indicators,
    app.kill_particles,
    app.hit_effect,
    app.fortnite_hit,
    app.effects,
    app.clantag,
    app.fps_optimizer,
    app.watermark,
    app.hotkeys,
    app.spectators,
    app.specs_header,
    app.notifications,
    app.notification_debug,
    app.notification_screen,
    app.notification_console,
    app.model_changer,
  }) do
    if item then
      pcall(function()
        item:set(false)
      end)
    end
  end
  app.version_state.apply_ui()
  set_menu_section()
end
on_event("render", function()
  f4()
  if app.version_state.boot_lock then
    pcall(app.version_state.force_beta_startup)
  end
  if check_duplicate() then
    return
  end
  if not yaw_state.banner_due then
    yaw_state.banner_due = game_time() + 1.35
  end
  if not yaw_state.banner_printed and game_time() >= yaw_state.banner_due then
    yaw_state.banner_printed = true
    yaw_state.print_banner()
  end
  safe_call("render_main", boot)
  safe_call("watermark", watermark_render)
  safe_call("notifications", notifications_render)
  safe_call("kill_particles", tick_kill_particles)
  safe_call("widgets", widget_tick)
end)
on_event("config_state", set_config_state)
aspect_presets:guard(aspect_presets.sync)
