_DEBUG = true

local t1 = {
	TRIAL = "Trial",
	STABLE = "Base",
	PRO = "Pro"
}
local s1 = "evalate"
local PRO = t1.PRO
local t3, u16, t4, t5, base64, gradient, clipboard, u28, pui, v35, v37, v38, v39, u40, u47, t14, t15, t18, u58, v78, t22, u135, u179, u183, u184, u185, u187, u188, t61, v214, t81

do
	local smoothy, v33, v36, v43, v59, v271, t107, t108, t109

	do
		local v4 = PRO:lower();

		("%s %s"):format(s1, PRO):lower()

		local v18, t46, v192, v241

		do
			local t20

			do
				local v17, u155, t52, v158, t54

				do
					local OpenExternalBrowserURL, v42

					do
						local s2 = "1.1"
						local v6 = PRO
						local v7 = common.get_username()
						local s3, t2, v32

						do
							local s4, v60, v61

							do
								local sha256, t16, v55

								do
									local localize

									do
										local s5

										do
											local v8 = (function(p1)
												return string.find(_NAME, p1) ~= nil
											end)(({
												DEBUG = "-d"
											}).DEBUG)

											s3 = "https://evalate.com/api"
											s4 = "wss://evalate.com/api"
											s5 = "cefb5eaeb"
											t2 = {
												["content-type"] = "application/json",
												cheat = "neverlose"
											}

											do
												local n1 = 0

												t3 = {
													start = function()
														-- upvalues: n1 (ref)
														n1 = common.get_timestamp()
													end,
													stop = function()
														-- upvalues: n1 (ref)
														return common.get_timestamp() - n1
													end
												}
											end

											t3.start()

											local s6 = "evalate debug > "

											function u16(...)
												-- upvalues: v8 (copy), s6 (copy)
												if v8 == true then
													print_raw(s6, ...)
													print_dev(s6, ...)
												end
											end
										end

										v17 = common.get_username()
										v18 = render.screen_size()
										t4 = {
											state = "?"
										}
										t5 = {}
										base64 = require("neverlose/base64")
										smoothy = require("neverlose/smoothy")
										localize = require("neverlose/localize")
										gradient = require("neverlose/gradient")
										clipboard = require("neverlose/clipboard")

										do
											local _, result = xpcall(require, function(err)
												print("Failed to load neverlose/websockets library. Error: ", err)
												print("Don't worry, the script remains fully functional. The only thing is that the online counter won't be displayed in the script.")
												print("This error has only occurred for three people recently. There might be something wrong with your version of the game.")
											end, "neverlose/websockets")

											u28 = result
										end

										pui = require("neverlose/pui")
										pui.colors.red = color(255, 125, 125)
										pui.colors.inactive = color(200)
										pui.colors.grey = color("727272FF")
										pui.colors.green = color("A9B651")
										sha256 = require("neverlose/hashing").sha256

										function generate_signature(p2, p3)
											-- upvalues: sha256 (copy)
											local t6 = {}

											for k, _ in next, p2 do
												table.insert(t6, k)
											end

											table.sort(t6)

											local s7 = ""

											for _, v in next, t6 do
												s7 = s7 .. v .. tostring(p2[v])
											end

											return sha256(s7 .. p3)
										end

										local function v31(p4)
											local s8 = "abcdefghijklmnopqrstuvwxyz0123456789"
											local s9 = ""

											for _ = 1, p4 do
												local v398 = math.random(1, #s8)

												s9 = s9 .. s8:sub(v398, v398)
											end

											return s9
										end

										function v32(p5)
											-- upvalues: v7 (copy), v6 (copy), s2 (copy), v31 (copy), s5 (copy)
											p5.username = v7
											p5.script_cheat = "NL"
											p5.script_build = v6
											p5.script_version = s2
											p5.timestamp = common.get_unixtime() * 1000
											p5.request_id = v31(16)
											p5.signature = generate_signature(p5, s5)

											return p5
										end
										function v33(p6, p7, p8)
											if not (p6 < p7) then
												if not (p8 < p6) then
													return p6
												end

												return p8
											end

											return p7
										end

										local function v34(p9)
											local t7 = {}

											for k, v in next, p9 do
												t7[k] = v
											end

											return t7
										end

										v35 = v34(render)
										v36 = v34(common)
										v37 = v34(utils)
										v38 = v34(math)
										v39 = v34(table)

										function v39.has(p10, p11)
											for _, v in next, p10 do
												if p11 == v then
													return true
												end
											end

											return false
										end
										function v39.delete(p12, p13)
											-- upvalues: v39 (copy)
											local t8 = {}

											for _, v in next, p12 do
												if v ~= p13 then
													v39.insert(t8, v)
												end
											end

											return t8
										end
										function v39.change(p14, p15, p16)
											-- upvalues: v39 (copy)
											local t9 = {}

											for _, v in next, p14 do
												if v ~= p15 then
													v39.insert(t9, v)
												else
													v39.insert(t9, p16)
												end
											end

											return t9
										end

										u40 = v34(string)
									end

									function u40.limit(p17, p18)
										-- upvalues: u40 (ref)
										return p18 < #p17 and u40.format("%s...", u40.sub(p17, 1, p18)) or p17
									end
									function u40.upper(p19, p20)
										local str = tostring(p19)

										if not p20 then
											return str:upper()
										end

										return str:sub(1, 1):upper() .. str:sub(2):lower()
									end

									u40 = setmetatable(u40, {
										__call = function(_, p22, ...)
											-- upvalues: u40 (ref), pui (copy)
											if not ... then
												return pui.string(p22)
											end

											return u40.format(pui.string(p22), ...)
										end
									})
									OpenExternalBrowserURL = panorama.SteamOverlayAPI.OpenExternalBrowserURL

									function v42(p23)
										-- upvalues: OpenExternalBrowserURL (copy)
										return function()
											-- upvalues: OpenExternalBrowserURL (copy), p23 (copy)
											OpenExternalBrowserURL(p23)
										end
									end
									function v43(p24, p25, ...)
										-- upvalues: v39 (copy), PRO (copy)
										if not v39.has({ ... }, PRO) then
											p24:disabled(true)
											p24:set_callback(function(p26)
												if p26[0].type == "switch" then
													p26:set(false)
												end
											end, true)

											return function()
											end
										end

										return p25
									end

									do
										local t10 = {}
										local t11 = {}
										local t12 = {
											get = function(p27)
												-- upvalues: t11 (copy)
												if p27 ~= nil then
													return t11[p27]
												end

												return t11
											end,
											set_callback_list = function(p28, p29)
												-- upvalues: t10 (copy), u40 (ref), pui (copy), v39 (copy)
												local v435 = p28:id()

												t10[v435] = { p28:list() }

												local function v436()
													-- upvalues: p28 (copy), t10 (copy), v435 (copy), u40 (ref), p29 (copy), pui (copy), v39 (copy)
													local v1862 = p28:get()
													local v1863 = t10[v435][1]

													if v1863[v1862] then
														local v1864 = v1863[v1862]:sub(1, 3)
														local v1865 = u40("\v" .. v1864 .. "\r ") .. v1863[v1862]:sub(5)

														if p29 then
															v1865 = pui.string("\v•  \r") .. v1863[v1862]
														end

														local v1866 = v39.change(v1863, v1863[v1862], v1865)

														p28:update(v1866)

														return
													end
												end

												t10[v435][2] = v436
												p28:set_callback(v436, true)
											end
										}

										function t12.new(p30, p31, ...)
											-- upvalues: t11 (copy), t12 (copy)
											assert(t11[p30] == nil, "menu.new - element with same name already exist")

											if ... then
												p31:depend(...)
											end

											if p31:type() == "list" then
												t12.set_callback_list(p31)
											end

											t11[p30] = p31

											return p31
										end

										u47 = t12
									end

									local t13 = {}

									local function v49(...)
										-- upvalues: t13 (copy)
										for _, v in next, t13 do
											v(...)
										end
									end

									local u50 = nil
									local tickcount = nil

									events.player_hurt(function(p32)
										-- upvalues: u50 (ref), v38 (copy)
										local v442 = entity.get_local_player()
										local v443 = entity.get(p32.userid, true)
										local v444 = entity.get(p32.attacker, true)

										if v442 == v443 and v442 ~= v444 then
											u50 = v38.floor(globals.curtime)
										end
									end)
									events.bullet_impact(function(p33)
										-- upvalues: u50 (ref), v38 (copy), tickcount (ref), v49 (copy)
										if u50 ~= v38.floor(globals.curtime) and tickcount ~= globals.tickcount then
											local v446 = entity.get_local_player()
											local v447 = entity.get(p33.userid, true)

											if v446 and v446:is_alive() and v447 and not v447:is_dormant() and v447:is_enemy() then
												local v448 = v446:get_eye_position()
												local v449 = v447:get_eye_position()

												if v448 and v449 then
													local v450 = vector(p33.x, p33.y, p33.z)
													local v451 = v448:closest_ray_point(v449, v450):dist(v448)

													if v451 < 60 then
														v49({
															distance = v451,
															entity = v447,
															impact = v450
														})
														tickcount = globals.tickcount
													end

													return
												end

												return
											end

											return
										end
									end)

									function events.close_shot(p34)
										-- upvalues: t13 (copy)
										t13[p34] = p34
									end

									t14 = {
										auto_stop = pui.find("Aimbot", "Ragebot", "Accuracy", "SSG-08", "Auto Stop", {
											options = "Options",
											double_tab = "Double Tap"
										}),
										freestanding = pui.find("Aimbot", "Anti Aim", "Angles", "Freestanding", {
											yaw = "Disable Yaw Modifiers",
											body = "Body Freestanding"
										}),
										double_tap = pui.find("Aimbot", "Ragebot", "Main", "Double Tap", {
											quick_switch = "Quick-Switch",
											options = "Lag Options",
											lag_limit = "Fake Lag Limit"
										}),
										hide_shots = pui.find("Aimbot", "Ragebot", "Main", "Hide Shots", {
											options = "Options"
										}),
										weapon_actions = pui.find("Miscellaneous", "Main", "Other", "Weapon Actions"),
										air_strafe = ui.find("Miscellaneous", "Main", "Movement", "Air Strafe"),
										strafe_assist = ui.find("Miscellaneous", "Main", "Movement", "Strafe Assist"),
										body_aim = pui.find("Aimbot", "Ragebot", "Safety", "Body Aim"),
										safe_points = pui.find("Aimbot", "Ragebot", "Safety", "Safe Points"),
										peek_assist = pui.find("Aimbot", "Ragebot", "Main", "Peek Assist"),
										scope_overlay = pui.find("Visuals", "World", "Main", "Override Zoom", "Scope Overlay"),
										hitchance = pui.find("Aimbot", "Ragebot", "Selection", "Hit Chance"),
										damage = pui.find("Aimbot", "Ragebot", "Selection", "Min. Damage"),
										slow_walk = ui.find("Aimbot", "Anti Aim", "Misc", "Slow Walk"),
										fake_lag = ui.find("Aimbot", "Anti Aim", "Fake Lag", "Enabled"),
										unlock_cvars = ui.find("Miscellaneous", "Main", "Other", "Unlock Hidden Cvars"),
										avoid_backstab = pui.find("Aimbot", "Anti Aim", "Angles", "Yaw", "Avoid Backstab"),
										is_min_damage = function(p35)
											for _, v in next, ui.get_binds() do
												if v.reference:id() == p35.damage:id() and v.active then
													return true
												end
											end

											return false
										end
									}
									t15 = {
										home = pui.create("\v\f<house>", {
											[1] = {
												[1] = "main",
												[2] = "## main",
												[3] = 1
											},
											[2] = {
												[1] = "user_data",
												[2] = "\n\n\n",
												[3] = 1
											},
											[3] = {
												[1] = "statistics",
												[2] = "\n\n\n\n",
												[3] = 2
											},
											[4] = {
												[1] = "leaderboard",
												[2] = "## leaderboard",
												[3] = 2
											},
											[5] = {
												[1] = "discord",
												[2] = "\n\n\n\n\n\n\n\n",
												[3] = 2
											},
											[6] = {
												[1] = "free_config",
												[2] = "\n\n\n\n\n\n\n\n\n",
												[3] = 2
											},
											[7] = {
												[1] = "styles",
												[2] = "\n\n\n\n\n\n\n\n\n\n",
												[3] = 2
											},
											[8] = {
												[1] = "website_links",
												[2] = "## website links",
												[3] = 2
											},
											[9] = {
												[1] = "products",
												[2] = "\n\n\n\n\n\n\n\n\n\n\n",
												[3] = 2
											},
											[10] = {
												[1] = "configs",
												[2] = "## configs",
												[3] = 2
											},
											[11] = {
												[1] = "presets_setup",
												[2] = "## presets setup",
												[3] = 1
											},
											[12] = {
												[1] = "preset_information",
												[2] = "## preset information ",
												[3] = 1
											},
											[13] = {
												[1] = "preset_creation",
												[2] = "## preset creation",
												[3] = 2
											},
											[14] = {
												[1] = "preset_actions",
												[2] = "## preset actions",
												[3] = 2
											},
											[15] = {
												[1] = "local_presets",
												[2] = "## local presets",
												[3] = 2
											},
											[16] = {
												[1] = "cloud_presets",
												[2] = "## cloud presets",
												[3] = 2
											}
										}),
										features = pui.create("\v\f<layer-group>", {
											[1] = {
												[1] = "main",
												[2] = "\n",
												[3] = 1
											},
											[2] = {
												[1] = "rage",
												[2] = "\n\n",
												[3] = 2
											},
											[3] = {
												[1] = "hitchances",
												[2] = "\n\n\n",
												[3] = 2
											},
											[4] = {
												[1] = "gameplay",
												[2] = "\n\n\n\n",
												[3] = 1
											},
											[5] = {
												[1] = "widgets",
												[2] = "\n\n\n\n\n",
												[3] = 2
											},
											[6] = {
												[1] = "indicators",
												[2] = "\n\n\n\n\n\n",
												[3] = 2
											},
											[7] = {
												[1] = "world",
												[2] = "\n\n\n\n\n\n\n",
												[3] = 1
											},
											[8] = {
												[1] = "movement",
												[2] = "\n\n\n\n\n\n\n\n",
												[3] = 2
											},
											[9] = {
												[1] = "scoreboard",
												[2] = "\n\n\n\n\n\n\n\n\n",
												[3] = 2
											},
											[10] = {
												[1] = "other",
												[2] = "\n\n\n\n\n\n\n\n\n\n",
												[3] = 1
											}
										}),
										antiaim = pui.create("\v\f<rotate>", {
											[1] = {
												[1] = "main",
												[2] = "## main",
												[3] = 1
											},
											[2] = {
												[1] = "states",
												[2] = "## states",
												[3] = 1
											},
											[3] = {
												[1] = "binds",
												[2] = "## binds",
												[3] = 1
											},
											[4] = {
												[1] = "options",
												[2] = "## options",
												[3] = 2
											},
											[5] = {
												[1] = "important",
												[2] = "\n\n\n\n",
												[3] = 2
											},
											[6] = {
												[1] = "other",
												[2] = "\n\n\n\n\n\n",
												[3] = 1
											}
										})
									}
									t16 = {}
									v55 = "^" .. localize("SFUI_Scoreboard_ServerName", {
										s1 = "(.*)"
									}) .. "$"
								end

								local GetServerName = panorama.GameStateAPI.GetServerName

								function t16.get_server_name(_)
									-- upvalues: GetServerName (copy), v55 (copy)
									return (GetServerName():match(v55))
								end
								function t16.get_map_name(_)
									-- upvalues: v36 (copy)
									local v458 = v36.get_map_data()

									if v458 then
										return v458.shortname
									end
								end
								function t16.get_server_ip(_)
									-- upvalues: v37 (copy)
									local v460 = v37.net_channel()

									if v460 and not v460.is_loopback then
										local v461 = v460:get_server_info()

										if v461 then
											return v461.address
										end

										return
									end
								end
								function t16.get_max_players(_)
									return globals.max_players
								end
								function t16.get_players(_)
									return #entity.get_players()
								end
								function t16.websocket_send_server_data(p41, p42)
									-- upvalues: v37 (copy), u16 (ref)
									v37.net_channel()

									if p42 then
										local t17 = {
											ip = p41:get_server_ip(),
											map = p41:get_map_name(),
											name = p41:get_server_name(),
											players = p41:get_players(),
											max_players = p41:get_max_players()
										}

										if t17.ip ~= nil then
											local v467 = json.stringify(t17)

											u16("sent ", p42:send(v467))

											return
										end

										return u16("[ws] Server Address is none. The message won't be sent.")
									end

									return u16("not websocket")
								end

								u47.new("home:subtab", t15.home.main:list("", {
									[1] = "\f<chart-line>    Statistics",
									[2] = "\f<file>     Presets",
									[3] = "\f<link>   Links"
								}, nil, false))
								u47.new("features:subtab", t15.features.main:list("", {
									[1] = "\f<wave-sine>   Aimbot",
									[2] = "\f<paintbrush>    Visual",
									[3] = "\f<bars-sort>     Misc"
								}, nil, false))
								u47.new("antiaim:subtab", t15.antiaim.main:list("", {
									[1] = "\f<bars-staggered>    Setup",
									[2] = "\f<slider>    Builder",
									[3] = "\f<shuffle>    Defensive"
								}, nil, false))
								t18 = {
									home = {
										statistics = {
											[1] = nil,
											[2] = 1,
											[1] = u47.get("home:subtab")
										},
										presets = {
											[1] = nil,
											[2] = 2,
											[1] = u47.get("home:subtab")
										},
										other = {
											[1] = nil,
											[2] = 3,
											[1] = u47.get("home:subtab")
										},
										not_presets = {
											[1] = nil,
											[2] = 2,
											[3] = true,
											[1] = u47.get("home:subtab")
										}
									},
									features = {
										rage = {
											[1] = nil,
											[2] = 1,
											[1] = u47.get("features:subtab")
										},
										visual = {
											[1] = nil,
											[2] = 2,
											[1] = u47.get("features:subtab")
										},
										misc = {
											[1] = nil,
											[2] = 3,
											[1] = u47.get("features:subtab")
										}
									},
									antiaim = {
										not_options = {
											[1] = nil,
											[2] = 1,
											[3] = true,
											[1] = u47.get("antiaim:subtab")
										},
										options = {
											[1] = nil,
											[2] = 1,
											[1] = u47.get("antiaim:subtab")
										},
										builder = {
											[1] = nil,
											[2] = 2,
											[1] = u47.get("antiaim:subtab")
										},
										defensive = {
											[1] = nil,
											[2] = 3,
											[1] = u47.get("antiaim:subtab")
										}
									}
								};
								({}).update = function(p43, p44, p45)
									-- upvalues: u47 (ref), t18 (copy)
									p43.place = p44
									p43.points = p45
									u47.get("place_element"):name(("%s Place"):format(p44))
									u47.get("points_element"):name(("%s Points"):format(p45))
									t18.home.not_presets[1]:set(t18.home.not_presets[1].value)
								end
								u58 = nil

								function v59(p46)
									-- upvalues: sha256 (copy), u40 (ref)
									return sha256(u40.format("%sua", p46))
								end

								v60 = t15.home.user_data:switch("полотенчег")
								v60:visibility(false)

								function v61()
									-- upvalues: v60 (copy)
									v60:set(not v60:get())
								end

								u47.new("whats up", t15.home.user_data:label("\v\f<user>     \rWhat's up"), t18.home.not_presets)
								u47.new("username", t15.home.user_data:button(v17, nil, true), t18.home.not_presets)
								u47.new("build", t15.home.user_data:label("\v\f<code>    \rBuild"), t18.home.not_presets)
								u47.new("_build", t15.home.user_data:button(u40.upper(v4, true), nil, true), t18.home.not_presets)
								t15.home.user_data:button(s2, nil, true):depend(t18.home.not_presets)

								local u62 = false

								local function v63()
									-- upvalues: u62 (ref)
									return u62
								end

								t15.home.user_data:label(" \v\f<fire-flame-curved>     \rStreak"):depend(t18.home.not_presets, {
									[1] = v60,
									[2] = v63
								})

								local v64 = t15.home.user_data:button("", nil, true):depend(t18.home.not_presets, {
									[1] = v60,
									[2] = v63
								})

								v64:tooltip("\v\f<circle-info>   \rYour streak loves daily attention!")

								local v65 = v32({})

								network.post(s3 .. "/streak/", v65, t2, function(p47)
									-- upvalues: v64 (copy), u62 (ref), v61 (copy)
									local ok, result = pcall(json.parse, p47)

									if ok and result and result.streak then
										v64:name(("%sx"):format(result.streak))
										u62 = true
										v61()

										return
									end

									return print("Streak request failed. Response: ", p47)
								end)
							end

							if u28 then
								local u66, u69, u70, n2, u72, v74, t19

								do
									local v68

									do
										u66 = false

										local function v67()
											-- upvalues: u66 (ref)
											return u66
										end

										t15.home.user_data:label("\v\f<tower-broadcast>    \rOnline"):depend(t18.home.not_presets, {
											[1] = v60,
											[2] = v67
										})
										v68 = t15.home.user_data:button("", nil, true):depend(t18.home.not_presets, {
											[1] = v60,
											[2] = v67
										})
									end

									u69 = nil
									u70 = nil
									n2 = 0
									u72 = false

									local function v73()
										-- upvalues: v37 (copy)
										local v475 = v37.net_channel()

										if v475 and not v475.is_loopback then
											local v476 = v475:get_server_info()

											if v476 then
												return v476.address
											end

											return
										end
									end

									function v74()
										-- upvalues: v37 (copy), u70 (ref), v73 (copy)
										v37.execute_after(1, function()
											-- upvalues: u70 (ref), v73 (copy)
											if u70 then
												u70:send(v73() or "")

												return
											end
										end)
									end

									t19 = {
										open = function(p48)
											-- upvalues: n2 (ref), u70 (ref), v74 (copy)
											n2 = 0
											u70 = p48
											v74()
										end,
										message = function(_, p50)
											-- upvalues: v68 (copy), u66 (ref), v61 (copy), u58 (ref)
											local ok, result = pcall(json.parse, p50)

											if not ok then
												v68:name("")
												u66 = false
												v61()
											else
												v68:name(tostring(#result))
												u66 = true
												v61()
												u58 = result
											end
										end,
										error = function(_, _)
											-- upvalues: u70 (ref), u69 (ref)
											u70 = nil
											u69()
										end,
										close = function(_, _, _, _)
											-- upvalues: u70 (ref), u69 (ref)
											u70 = nil
											u69()
										end
									}
								end

								local function v76()
									-- upvalues: n2 (ref), u72 (ref), v59 (copy), v32 (copy), u28 (ref), s4 (copy), t19 (copy), s3 (copy), t2 (copy)
									if not (n2 > 2) then
										n2 = n2 + 1
										u72 = false

										local v488 = v59(panorama.MyPersonaAPI.GetXuid())
										local v489 = v32({
											secret = v488
										})

										network.post(s3 .. "/communication/register-key", v489, t2, function(p57)
											-- upvalues: u28 (ref), s4 (copy), t19 (copy)
											local ok, result = pcall(json.parse, p57)

											if ok and result and result.key then
												u28.connect(s4 .. "/communication/" .. result.key, t19)

												return
											end

											return print("Failed to register websocket key. Response: ", p57)
										end)

										return
									end

									return print("unable to reconnect after 3 attempts")
								end

								function u69()
									-- upvalues: u70 (ref), u72 (ref), v37 (copy), v76 (copy)
									if not u70 and not u72 then
										u72 = true
										v37.execute_after(5, v76)

										return
									end

									return print("attempted futile reconnection stopped")
								end

								v76()
								events.level_init(v74)
								events.round_start(v74)

								local u77 = false

								events.render(function()
									-- upvalues: u77 (ref), v74 (copy)
									local is_in_game = globals.is_in_game

									if is_in_game ~= u77 then
										if not is_in_game then
											v74()
										end

										u77 = is_in_game
									end
								end)
							end

							if PRO == t1.TRIAL then
								u47.new("trial", t15.home.user_data:label("\v\f<lock-open>    \rExpires in"), t18.home.not_presets)
								u47.new("_trial", t15.home.user_data:button("1 day", nil, true), t18.home.not_presets)
							end

							function v78(p58, p59)
								local v493 = entity.get_threat()

								if p59 ~= 0 then
									if v493 ~= nil and p58 ~= nil and not v493:is_dormant() then
										local v494 = p58:get_origin()
										local v495 = v493:get_origin()

										return v494.z ~= nil and (v495.z ~= nil and not (v494.z - p59 <= v495.z))
									end

									return
								end

								return true
							end

							t20 = {}

							local n3 = 0

							function t20.get()
								-- upvalues: v37 (copy), n3 (ref), v38 (copy)
								local v496 = entity.get_local_player()

								if v496 then
									local v497 = v37.net_channel()
									local v498 = v496:get_simulation_time()
									local v499 = to_ticks(v498.current - v498.old)

									if v499 < 0 then
										n3 = globals.tickcount + v38.abs(v499) - to_ticks(v497.latency[0])
									end

									return not (n3 <= globals.tickcount)
								end
							end
						end

						local t24, v95, t26

						do
							local t23, v96

							do
								local v81 = s1 .. "_activity"
								local v82 = db[v81] or {
									total_time = 0,
									game = {
										headshots = 0,
										total_kills = 0,
										misses_at_you = 0
									}
								}
								local v83 = v32({
									time = v82.total_time,
									kills = v82.game.total_kills,
									misses = v82.game.misses_at_you,
									headshots = v82.game.headshots
								})

								network.post(s3 .. "/statistics/neverlose/update", v83, t2, function(_)
								end)

								local v84 = v36.get_timestamp()

								local function v85()
									-- upvalues: v36 (copy), v84 (copy)
									return v36.get_timestamp() - v84
								end
								local function v86(p61)
									-- upvalues: v38 (copy)
									local v502 = v38.floor(p61 / 1000)
									local v503 = v38.floor(v502 / 60)
									local v504 = v503 / 60

									if not (v38.floor(v504) > 0) then
										if not (v503 > 0) then
											return v502 .. " Seconds"
										end

										return v503 .. " Minutes"
									end

									return ("%.1f Hours"):format(v504)
								end

								local t21 = {}

								local function v88(p62, p63)
									-- upvalues: t15 (copy), t18 (copy), u40 (ref), v39 (copy), t21 (copy)
									t15.home.statistics:label(p62):depend(t18.home.statistics)

									local v507 = t15.home.statistics:button(u40("%s", p63()), nil, true):depend(t18.home.statistics)

									v39.insert(t21, {
										name = p62,
										button = v507,
										callback = p63,
										old = p63()
									})
								end

								v88("\v\f<clock>     \rTotal", function()
									-- upvalues: v86 (copy), v82 (copy), v85 (copy)
									return v86(v82.total_time + v85())
								end)
								v88("\v\f<timer>     \rThis session", function()
									-- upvalues: v86 (copy), v85 (copy)
									return v86(v85())
								end)
								v88("\v\f<skull>     \rHeadshots", function()
									-- upvalues: v82 (copy), u40 (ref), v38 (copy)
									local v514 = v82.game.headshots / v82.game.total_kills

									return u40("%s%%", v514 > 0 and v38.floor(100 * v514) or 0)
								end)
								v88("\v\f<user-slash>    \rEnemy killed", function()
									-- upvalues: v82 (copy)
									return v82.game.total_kills
								end)
								v88("\v\f<user-xmark>    \rMisses at me", function()
									-- upvalues: v82 (copy)
									return v82.game.misses_at_you
								end)
								events.render(function()
									-- upvalues: t21 (copy), u40 (ref)
									if ui.get_alpha() > 0 then
										for _, v in next, t21 do
											if v.old ~= v.callback() then
												v.button:name(u40("%s", v.callback()))
												v.old = v.callback()
											end
										end
									end
								end)
								events.player_death(function(p64)
									-- upvalues: v82 (copy)
									local v511 = entity.get_local_player()
									local v512 = entity.get(p64.userid, true)

									if v511 == entity.get(p64.attacker, true) and v512 ~= v511 and not v512:is_bot() then
										v82.game.total_kills = v82.game.total_kills + 1

										if p64.headshot then
											v82.game.headshots = v82.game.headshots + 1
										end
									end
								end)
								events.close_shot(function(p65)
									-- upvalues: v82 (copy)
									if not p65.entity:is_bot() then
										v82.game.misses_at_you = v82.game.misses_at_you + 1
									end
								end)
								events.shutdown(function()
									-- upvalues: v82 (copy), v85 (copy), v81 (copy)
									v82.total_time = v82.total_time + v85()
									db[v81] = v82
								end)
								t22 = {}
								_menu = {}
								_depend = {}
								_menu.preset_information = {}
								_menu.storage = t15.home.presets_setup:combo("\v\f<database>    \rStorage", {
									[1] = "\v\f<cloud>   \rCloud",
									[2] = "\v\f<desktop>    \rLocal"
								}):depend(t18.home.presets)
								_depend.storage = {
									cloud = {
										[1] = _menu.storage,
										[2] = _menu.storage:list()[1]
									},
									["local"] = {
										[1] = _menu.storage,
										[2] = _menu.storage:list()[2]
									}
								}
								_menu.settings = t15.home.presets_setup:label("\v\f<gear>   \rSettings", nil, function(p66)
									return {
										sort = p66:combo("\v\f<bars-sort>    \rSort", {
											[1] = "\v\f<floppy-disk>    \rLast Update",
											[2] = "\v\f<heart>   \rMost Liked",
											[3] = " \v\f<play>   \rMost Loaded"
										}),
										filter = p66:combo("\v\f<bars-filter>    \rFilter", {
											[1] = "\v\f<list>   \rNone",
											[2] = "\v\f<user>   \rMy",
											[3] = "\v\f<heart>   \rLiked"
										}),
										show_info = p66:switch("\v\f<bars>    \rShow Information", true)
									}
								end)
								_menu.settings:depend(t18.home.presets)
								_menu.settings.sort:depend(_depend.storage.cloud)
								_menu.settings.filter:depend(_depend.storage.cloud)
								t23 = { pui.string("\v\f<spinner>   \rLoading...") }
								t24 = { pui.string("\v\f<face-frown-slight>    \rNo presets found") }
								_menu.local_actions = {}
								_menu.local_actions.load = t15.home.local_presets:button("   \f<play>  ", nil, false, "Load"):depend(t18.home.presets, _depend.storage["local"])
								_menu.local_actions.load_antiaims = t15.home.local_presets:button("  \f<shield>  ", nil, false, "Load only anti-aim's"):depend(t18.home.presets, _depend.storage["local"])
								_menu.local_actions.copy = t15.home.local_presets:button("  \f<copy>  ", nil, true, "Copy to clipboard"):depend(t18.home.presets, _depend.storage["local"])
								_menu.local_actions.save = t15.home.local_presets:button("  \f<floppy-disk>  ", nil, true, "Save"):depend(t18.home.presets, _depend.storage["local"])
								_menu.local_actions.delete = t15.home.local_presets:button("  \a[red]\f<trash>  ", nil, true, "Delete"):depend(t18.home.presets, _depend.storage["local"])
								_menu.local_presets = t15.home.local_presets:list("", t23):depend(t18.home.presets, _depend.storage["local"])
								_menu.cloud_actions = {}
								_menu.cloud_actions.load = t15.home.cloud_presets:button("   \f<play>  ", nil, false, "Load"):depend(t18.home.presets, _depend.storage.cloud)
								_menu.cloud_actions.load_antiaims = t15.home.cloud_presets:button("  \f<shield>  ", nil, false, "Load only anti-aim's"):depend(t18.home.presets, _depend.storage.cloud)
								_menu.cloud_actions.like = t15.home.cloud_presets:button("  \f<heart>  ", nil, true, "Like"):depend(t18.home.presets, _depend.storage.cloud)
								_menu.cloud_actions.save = t15.home.cloud_presets:button("  \f<floppy-disk>  ", nil, true, "Save"):depend(t18.home.presets, _depend.storage.cloud)
								_menu.cloud_actions.delete = t15.home.cloud_presets:button("  \a[red]\f<trash>  ", nil, true, "Delete"):depend(t18.home.presets, _depend.storage.cloud)
								_menu.cloud_presets = t15.home.cloud_presets:list("", t23):depend(t18.home.presets, _depend.storage.cloud)
								t15.home.preset_actions:label("\v\f<arrow-pointer>    \rActions"):depend(t18.home.presets, _depend.storage.cloud)
								_menu.upload = t15.home.preset_actions:button(" \v\f<cloud-arrow-up>   \rUpload ", nil, true):depend(t18.home.presets, _depend.storage.cloud):disabled(v6 == t1.TRIAL)
								_menu.actions_label = t15.home.preset_actions:label("\v\f<arrow-pointer>    \rActions "):depend(t18.home.presets, _depend.storage["local"])
								_menu.create = t15.home.preset_actions:button(" \v\f<file>   \rCreate ", nil, true):depend(t18.home.presets, _depend.storage["local"])
								_menu.import = t15.home.preset_actions:button(" \v\f<file-import>   \rImport ", nil, true):depend(t18.home.presets, _depend.storage["local"])
								_menu.name = t15.home.preset_creation:input(""):depend(t18.home.presets, _depend.storage["local"], _menu.create)
								_menu.create_final = t15.home.preset_creation:button("    \rCreate    "):depend(t18.home.presets, _depend.storage["local"], _menu.create)
								_menu.create_cancel = t15.home.preset_creation:button("    \rCancel    ", nil, true):depend(t18.home.presets, _depend.storage["local"], _menu.create)

								local function v92(p67)
									_menu.name:visibility(p67)
									_menu.create_final:visibility(p67)
									_menu.create_cancel:visibility(p67)

									local t25 = {
										[1] = _menu.storage,
										[2] = _menu.settings,
										[3] = _menu.local_presets,
										[4] = _menu.local_actions.load,
										[5] = _menu.local_actions.load_antiaims,
										[6] = _menu.local_actions.copy,
										[7] = _menu.local_actions.save,
										[8] = _menu.local_actions.delete,
										[9] = _menu.actions_label,
										[10] = _menu.create,
										[11] = _menu.import
									}

									for _, v in next, t25 do
										v:visibility(not p67)
									end

									for _, v in next, _menu.preset_information do
										v.label:visibility(not p67)
										v.button:visibility(not p67)
									end
								end
								local function v93()
									-- upvalues: v92 (copy)
									v92(false)
								end

								_menu.create:set_callback(function()
									-- upvalues: v92 (copy)
									v92(true)
								end)
								_menu.create_final:set_callback(v93)
								_menu.create_cancel:set_callback(v93)

								local v94 = _menu.storage:list()

								function v95()
									-- upvalues: v94 (copy)
									return _menu.storage.value == v94[1]
								end
								function v96()
									-- upvalues: v94 (copy)
									return _menu.storage.value == v94[2]
								end

								t26 = {}

								local t27 = {}

								function t26.create(_, p69, p70)
									-- upvalues: t27 (copy), t15 (copy), t18 (copy)
									assert(t27[p69] == nil, "same key already exist")

									local v525 = t15.home.preset_information:label(p70)
									local v526 = t15.home.preset_information:button("", nil, true)

									t27[p69] = {}
									_menu.preset_information[p69] = {
										label = v525,
										button = v526
									}

									local function v527()
										-- upvalues: t27 (copy), p69 (copy)
										return t27[p69] and t27[p69].value ~= nil
									end

									local t28 = {
										[1] = t18.home.presets,
										[2] = _menu.settings.show_info,
										[3] = {
											[1] = _menu.storage,
											[2] = v527
										},
										[4] = {
											[1] = _menu.cloud_presets,
											[2] = v527
										},
										[5] = {
											[1] = _menu.local_presets,
											[2] = v527
										}
									}

									v525:depend(unpack(t28))
									v526:depend(unpack(t28))
								end
								function t26.update(_, p72, p73)
									-- upvalues: t27 (copy), v96 (copy), v95 (copy)
									assert(t27[p72] ~= nil, "key not found")
									t27[p72].value = p73
									_menu.preset_information[p72].button:name(p73 == nil and "" or tostring(p73))

									if v96() then
										_menu.local_presets:set(_menu.local_presets.value)
									end

									if v95() then
										_menu.cloud_presets:set(_menu.cloud_presets.value)
									end
								end
							end

							t26:create("likes", "\v\f<heart>    \rLikes")
							t26:create("loads", " \v\f<play>    \rLoads")
							t26:create("author", "\v\f<user>    \rAuthor")
							t26:create("script", "\v\f<brackets-curly>   \rScript")
							t26:create("relevance", "\v\f<code-branch>    \rRelevance")
							t26:create("last_update", "\v\f<floppy-disk>    \rLast Update")

							local function v99()
								-- upvalues: base64 (copy), t22 (copy)
								local _, result = pcall(function()
									-- upvalues: base64 (copy), t22 (copy)
									return base64.encode(json.stringify(t22.package:save()))
								end)

								return result
							end

							local t29 = {}
							local t30 = {}

							local function v102()
								-- upvalues: t30 (ref)
								local v536 = _menu.cloud_presets:get()

								return t30[v536], v536
							end
							local function v103()
								-- upvalues: v102 (copy), t26 (copy), v36 (copy), pui (copy), s2 (copy)
								local v537 = v102() or {}

								t26:update("author", v537.username)
								t26:update("script", v537.script_build)
								t26:update("likes", v537.likes)
								t26:update("loads", v537.loads)
								t26:update("last_update", v537.last_updated_at and v36.get_date("%d.%m.%y %H:%M", v537.last_updated_at) or nil)
								t26:update("relevance", v537.script_version and pui.string(v537.script_version == s2 and " \a[green]\f<check>  \rUpdated " or " \a[red]\f<xmark>  \rOutdated ") or nil)
							end

							v103()
							_menu.storage:set_callback(v103)
							_menu.cloud_presets:set_callback(v103)

							local function v104()
								-- upvalues: v102 (copy), v7 (copy)
								local v538, _ = v102()
								local v540 = v538 and v538.username == v7

								_menu.cloud_actions.like:disabled(v538 == nil)
								_menu.cloud_actions.load:disabled(v538 == nil)
								_menu.cloud_actions.load_antiaims:disabled(v538 == nil)
								_menu.cloud_actions.save:disabled(v538 == nil or not v540)
								_menu.cloud_actions.delete:disabled(v538 == nil or not v540)
								_menu.cloud_actions.like:name(v538 and v538.liked and " ❤\239\184\143 " or "  \f<heart>  ")
							end

							_menu.cloud_presets:set_callback(v104)

							local function v105()
								-- upvalues: t30 (ref), t24 (copy)
								local t31 = {}

								for _, v in next, t30 do
									t31[#t31 + 1] = v.username
								end

								_menu.cloud_presets:update(#t31 > 0 and t31 or t24)
							end
							local function v106(p74)
								-- upvalues: t30 (ref), v105 (copy), v104 (copy), v103 (copy)
								t30 = p74 or {}
								v105()
								v104()
								v103()
							end
							local function v107(p75)
								-- upvalues: v7 (copy), v39 (copy)
								local v546 = _menu.settings.filter:list()
								local v547 = _menu.settings.filter:get()

								if v547 ~= v546[1] then
									local t32 = {}

									for _, v in next, p75 do
										if v547 == v546[2] and v.username == v7 then
											t32[#t32 + 1] = v
										end

										if v547 == v546[3] and v.liked then
											t32[#t32 + 1] = v
										end
									end

									p75 = t32
								end

								local v551 = _menu.settings.sort:list()
								local v552 = _menu.settings.sort:get()

								if v552 == v551[1] then
									v39.sort(p75, function(p76, p77)
										return not (p76.last_updated_at <= p77.last_updated_at)
									end)
								end

								if v552 == v551[2] then
									v39.sort(p75, function(p78, p79)
										return not (p78.likes <= p79.likes)
									end)
								end

								if v552 == v551[3] then
									v39.sort(p75, function(p80, p81)
										return not (p80.loads <= p81.loads)
									end)
								end

								return p75
							end
							local function v108()
								-- upvalues: v106 (copy), v107 (copy), t29 (ref)
								v106(v107(t29))
							end

							_menu.settings.sort:set_callback(v108)
							_menu.settings.filter:set_callback(v108)

							local function v109()
								-- upvalues: v96 (copy), v106 (copy), t23 (copy), v32 (copy), s3 (copy), t2 (copy), t29 (ref), v107 (copy)
								if not v96() then
									v106({})
									_menu.cloud_presets:update(t23)

									local v553 = v32({})

									network.post(s3 .. "/presets/neverlose-legacy/get", v553, t2, function(p82)
										-- upvalues: t29 (ref), v106 (copy), v107 (copy)
										local ok, result = pcall(json.parse, p82)

										if ok and result then
											t29 = result
											v106(v107(result))

											return
										end

										return print("Failed to fetch presets. Response: ", p82)
									end)

									return
								end
							end

							_menu.storage:set_callback(v109, true)

							local function v110(p83)
								-- upvalues: v102 (copy), v36 (copy), t22 (copy), base64 (copy), v32 (copy), s3 (copy), t2 (copy)
								local v555 = v102()

								if v555 then
									local v556 = v32({
										preset_author = v555.username
									})

									network.post(s3 .. "/presets/neverlose-legacy/load", v556, t2, function(p84)
										-- upvalues: v36 (copy), t22 (copy), base64 (copy), p83 (copy)
										local ok, result = pcall(json.parse, p84)

										if not ok or (not result or not result.status) then
											if not result.message then
												return print("Request failed. Response: ", p84)
											end

											v36.add_notify("Presets", result.message)
										end

										local ok2 = pcall(function()
											-- upvalues: t22 (copy), base64 (copy), result (copy), p83 (copy)
											return t22.package:load(json.parse(base64.decode(result.data)), p83 and "antiaim" or nil)
										end)

										if not p83 then
											v36.add_notify("Presets", ok2 and "Preset successfully loaded." or "Failed to load preset.")
										else
											v36.add_notify("Presets", ok2 and "Anti-aim's successfully loaded from preset." or "Failed to load anti-aim's from preset.")
										end
									end)

									return
								end

								return v36.add_notify("Presets", "Preset not found.")
							end

							_menu.cloud_actions.load:set_callback(function()
								-- upvalues: v110 (copy)
								v110()
							end)
							_menu.cloud_actions.load_antiaims:set_callback(function()
								-- upvalues: v110 (copy)
								v110(true)
							end)
							_menu.upload:set_callback(function()
								-- upvalues: v32 (copy), v99 (copy), s3 (copy), t2 (copy), v109 (copy), v36 (copy)
								local v557 = v32({
									data = v99()
								})

								network.post(s3 .. "/presets/neverlose-legacy/create", v557, t2, function(p85)
									-- upvalues: v109 (copy), v36 (copy)
									local ok, result = pcall(json.parse, p85)

									if ok and (result and result.status) or result.message then
										if result.status then
											v109()
										end

										pcall(function()
											-- upvalues: v36 (copy), result (copy)
											v36.add_notify("Presets", tostring(result.message))
										end)

										return
									end

									return print("Request failed. Response: ", raw)
								end)
							end)
							_menu.cloud_actions.delete:set_callback(function()
								-- upvalues: v32 (copy), s3 (copy), t2 (copy), v109 (copy), v36 (copy)
								local v558 = v32({})

								network.post(s3 .. "/presets/neverlose-legacy/delete", v558, t2, function(p86)
									-- upvalues: v109 (copy), v36 (copy)
									local ok, result = pcall(json.parse, p86)

									if ok and (result and result.status) or result.message then
										v109()
										pcall(function()
											-- upvalues: v36 (copy), result (copy)
											v36.add_notify("Presets", tostring(result.message))
										end)

										return
									end

									return print("Request failed. Response: ", raw)
								end)
							end)
							_menu.cloud_actions.save:set_callback(function()
								-- upvalues: v32 (copy), v99 (copy), s3 (copy), t2 (copy), v109 (copy), v36 (copy)
								local v559 = v32({
									data = v99()
								})

								network.post(s3 .. "/presets/neverlose-legacy/update", v559, t2, function(p87)
									-- upvalues: v109 (copy), v36 (copy)
									local ok, result = pcall(json.parse, p87)

									if ok and (result and result.status) or result.message then
										v109()
										pcall(function()
											-- upvalues: v36 (copy), result (copy)
											v36.add_notify("Presets", tostring(result.message))
										end)

										return
									end

									return print("Request failed. Response: ", raw)
								end)
							end)
							_menu.cloud_actions.like:set_callback(function()
								-- upvalues: v102 (copy), v32 (copy), s3 (copy), t2 (copy), v109 (copy), v36 (copy)
								local v560 = v102()

								if v560 then
									local v561 = v32({
										preset_author = v560.username
									})

									network.post(s3 .. "/presets/neverlose-legacy/like", v561, t2, function(p88)
										-- upvalues: v109 (copy), v36 (copy)
										local ok, result = pcall(json.parse, p88)

										if ok and (result and result.status) or result.message then
											v109()
											pcall(function()
												-- upvalues: v36 (copy), result (copy)
												v36.add_notify("Presets", tostring(result.message))
											end)

											return
										end

										return print("Request failed. Response: ", raw)
									end)

									return
								end
							end)
						end

						local s10 = "evalate_presets_19082378980123"
						local t33 = {}

						local function v113()
							-- upvalues: s10 (copy)
							return db[s10] or {}
						end
						local function v114(p89)
							-- upvalues: s10 (copy)
							events.database_pre_save:call()
							db[s10] = p89
							events.database_pre_save:call()
						end
						local function v115()
							-- upvalues: t33 (ref)
							local v563 = _menu.local_presets:get()

							return t33[v563], v563
						end
						local function v116()
							-- upvalues: v115 (copy), t26 (copy), v36 (copy), pui (copy), s2 (copy)
							local v564 = v115() or {}

							t26:update("author", v564.username)
							t26:update("script", v564.build_name)
							t26:update("likes")
							t26:update("loads")
							t26:update("last_update", v564.last_updated_at and v36.get_date("%d.%m.%y %H:%M", v564.last_updated_at) or nil)
							t26:update("relevance", v564.build_version and pui.string(v564.build_version == s2 and " \a[green]\f<check>  \rUpdated " or " \a[red]\f<xmark>  \rOutdated ") or nil)
						end

						_menu.local_presets:set_callback(v116, true)

						local function v117()
							-- upvalues: v115 (copy)
							local v565 = v115()

							_menu.local_actions.copy:disabled(v565 == nil)
							_menu.local_actions.load:disabled(v565 == nil)
							_menu.local_actions.load_antiaims:disabled(v565 == nil)
							_menu.local_actions.save:disabled(v565 == nil)
							_menu.local_actions.delete:disabled(v565 == nil)
						end

						_menu.local_presets:set_callback(v117)

						local function v118()
							-- upvalues: t33 (ref), t24 (copy)
							local t34 = {}

							for _, v in next, t33 do
								t34[#t34 + 1] = v.name
							end

							_menu.local_presets:update(#t34 > 0 and t34 or t24)
						end
						local function v119(p90)
							-- upvalues: t33 (ref), v118 (copy), v117 (copy), v116 (copy)
							t33 = p90 or {}
							v118()
							v117()
							v116()
						end

						_menu.storage:set_callback(function()
							-- upvalues: v95 (copy), v119 (copy), v113 (copy)
							if not v95() then
								v119(v113())

								return
							end
						end, true)
						_menu.create_final:set_callback(function()
							-- upvalues: v113 (copy), u40 (ref), t22 (copy), v36 (copy), v7 (copy), v6 (copy), s2 (copy), v39 (copy), v114 (copy), v119 (copy)
							local ok = pcall(function()
								-- upvalues: v113 (copy), u40 (ref), t22 (copy), v36 (copy), v7 (copy), v6 (copy), s2 (copy), v39 (copy), v114 (copy), v119 (copy)
								local v1895 = v113()
								local t35 = {
									name = #_menu.name.value > 0 and _menu.name.value or u40.format("Preset %s", #v1895 + 1),
									data = t22.package:save(),
									last_updated_at = v36.get_unixtime(),
									username = v7,
									build_name = v6,
									build_version = s2
								}

								v39.insert(v1895, 1, t35)
								v114(v1895)
								v119(v113())
								_menu.name:set("")
							end)

							v36.add_notify("Presets", ok and "Preset successfully created." or "Failed to create preset.")
						end)
						_menu.local_actions.save:set_callback(function()
							-- upvalues: v115 (copy), t33 (ref), v36 (copy), t22 (copy), v114 (copy), v119 (copy)
							local _, v572 = v115()

							if t33[v572] then
								local ok = pcall(function()
									-- upvalues: t33 (ref), v572 (copy), t22 (copy), v36 (copy), v114 (copy), v119 (copy)
									t33[v572].data = t22.package:save()
									t33[v572].last_updated_at = v36.get_unixtime()
									v114(t33)
									v119(t33)
								end)

								v36.add_notify("Presets", ok and "Preset successfully saved." or "Failed to save preset.")

								return
							end

							return v36.add_notify("Presets", "Preset not found.")
						end)
						_menu.local_actions.delete:set_callback(function()
							-- upvalues: v115 (copy), v39 (copy), t33 (ref), v114 (copy), v119 (copy), v113 (copy), v36 (copy)
							local ok = pcall(function()
								-- upvalues: v115 (copy), v39 (copy), t33 (ref), v114 (copy), v119 (copy), v113 (copy)
								local _, v1898 = v115()

								v39.remove(t33, v1898)
								v114(t33)
								v119(v113())
							end)

							v36.add_notify("Presets", ok and "Preset successfully deleted." or "Failed to delete preset.")
						end)
						_menu.local_actions.copy:set_callback(function()
							-- upvalues: v115 (copy), v36 (copy), clipboard (copy), base64 (copy)
							local v575 = v115()

							if v575 then
								local ok = pcall(function()
									-- upvalues: clipboard (copy), base64 (copy), v575 (copy)
									clipboard.set(("evalate>%s<"):format(base64.encode(json.stringify(v575))))
								end)

								v36.add_notify("Presets", ok and "Preset successfully copied." or "Failed to copy preset.")

								return
							end

							return v36.add_notify("Presets", "Preset not found.")
						end)
						_menu.import:set_callback(function()
							-- upvalues: base64 (copy), clipboard (copy), v113 (copy), v39 (copy), v114 (copy), v119 (copy), v36 (copy)
							local ok = pcall(function()
								-- upvalues: base64 (copy), clipboard (copy), v113 (copy), v39 (copy), v114 (copy), v119 (copy)
								local v1899 = json.parse(base64.decode(clipboard.get():match("evalate>(.-)<")))
								local v1900 = v113()

								v39.insert(v1900, 1, v1899)
								v114(v1900)
								v119(v113())
							end)

							v36.add_notify("Presets", ok and "Preset successfully imported." or "Failed to import preset.")
						end)
						_menu.local_actions.load:set_callback(function()
							-- upvalues: v115 (copy), v36 (copy), t22 (copy)
							local v578 = v115()

							if v578 then
								local ok = pcall(function()
									-- upvalues: t22 (copy), v578 (copy)
									return t22.package:load(v578.data)
								end)

								v36.add_notify("Presets", ok and "Preset successfully loaded." or "Failed to load preset.")

								return
							end

							return v36.add_notify("Presets", "Preset not found.")
						end)
						_menu.local_actions.load_antiaims:set_callback(function()
							-- upvalues: v115 (copy), v36 (copy), t22 (copy)
							local v580 = v115()

							if v580 then
								local ok = pcall(function()
									-- upvalues: t22 (copy), v580 (copy)
									return t22.package:load(v580.data, "antiaim")
								end)

								v36.add_notify("Presets", ok and "Anti-aim's from preset successfully loaded." or "Failed to anti-aim's from preset.")

								return
							end

							return v36.add_notify("Presets", "Preset not found.")
						end)
						t15.home.discord:label("\v\f<discord>    \rJoin community"):depend(t18.home.other)
						t15.home.discord:button(" \v\f<arrow-up-right-from-square> ", nil, true):depend(t18.home.other):set_callback(function()
							-- upvalues: OpenExternalBrowserURL (copy)
							OpenExternalBrowserURL("https://discord.gg/Rn5VE7S6Gx")
						end)

						local v120 = t15.home.discord:label("\v\f<user-tag>    \rUnlock discord channels"):depend(t18.home.other)
						local v121 = t15.home.discord:button(" \v\f<arrow-up-right-from-square> ", nil, true):depend(t18.home.other)
						local s11 = "\v\f<circle-info>   \rHow to get role on the server:\n\n1. Press the   \v\f<key>  \rbutton\n\n2. Authorize through Discord in the opened browser tab\n\n3. The role and access will be granted automatically"

						v120:tooltip(s11)
						v121:tooltip(s11)

						local function v123(p91)
							-- upvalues: OpenExternalBrowserURL (copy), v36 (copy)
							local ok, result = pcall(json.parse, p91)

							if ok and result and result.url then
								OpenExternalBrowserURL(result.url)
								v36.add_notify("Discord", "Browser opened, confirm login through Discord")

								return
							end

							return print("Failed to start verification: Response: ", p91)
						end

						v121:set_callback(function()
							-- upvalues: v32 (copy), s3 (copy), t2 (copy), v123 (copy)
							local v585 = v32({})

							network.post(s3 .. "/discord-verification/start", v585, t2, v123)
						end)
						u47.new("styles::light::label", t15.home.styles:label("\v\f<fill-drip>    \rMenu Themes"), t18.home.other)

						local v124 = v42("https://neverlose.cc/getitem?c=3K6mG9sCwXjjSdAQ-4rg7Cz9dRb")

						t15.home.styles:button("  \aFFB3FFFF\f<circle-dot>  ", v124, true):depend(t18.home.other)

						local v125 = v42("https://neverlose.cc/getitem?c=GvCXWid5VTxOUdNE-rXfl51UEeo")

						t15.home.styles:button("  \aA90000FF\f<circle-dot>  \n", v125, true):depend(t18.home.other)

						local v126 = v42("https://neverlose.cc/getitem?c=GWCNl3rkvi00iqaw-J9K2520pJ-")

						t15.home.styles:button("  \a8FABC4FF\f<circle-dot>  \n\n", v126, true):depend(t18.home.other)
					end

					t15.home.website_links:label("\v\f<trophy>    \revalate.com"):depend(t18.home.other)

					local v127 = v42("https://evalate.com/play-together")

					t15.home.website_links:button("  \v\f<arrow-up-right-from-square>  ", v127, true):depend(t18.home.other)
					t15.home.website_links:label("\v\f<sparkles>     \revalate Recode"):depend(t18.home.other)

					local v128 = v42("http://market.neverlose.cc/15LFCw")

					t15.home.website_links:button("  \v\f<arrow-up-right-from-square>  ", v128, true):depend(t18.home.other)
					u47.new("products::solus::label", t15.home.products:label("\v\f<paintbrush>    \rSolus"), t18.home.other)

					local v129 = v42("http://market.neverlose.cc/XjP7t5")

					u47.new("products::solus::link", t15.home.products:button("  \v\f<arrow-up-right-from-square>  ", v129, true), t18.home.other)
					t15.home.products:label("\v\f<trophy>     \rGreatest config for evalate"):depend(t18.home.other)
					t15.home.products:button(" \v\f<arrow-up-right-from-square> ", function()
						-- upvalues: OpenExternalBrowserURL (copy)
						OpenExternalBrowserURL("https://neverlose.cc/market/item?id=I7FKHv")
					end, true):depend(t18.home.other)

					if PRO == t1.STABLE then
						u47.new("products::beta::label", t15.home.products:label("\v\f<flask>     \rUnlock more features"), t18.home.other)

						local v130 = v42("http://market.neverlose.cc/b83thf")

						u47.new("products::beta::link", t15.home.products:button("  \v\f<arrow-up-right-from-square>  ", v130, true), t18.home.other)
					end

					if PRO == t1.TRIAL then
						u47.new("products::beta::label", t15.home.products:label("\v\f<star>    \rGet lifetime version"), t18.home.other)

						local v131 = v42("http://market.neverlose.cc/b83thf")

						u47.new("products::beta::link", t15.home.products:button("  \v\f<arrow-up-right-from-square>  ", v131, true), t18.home.other)
					end

					local v132 = u40("\v\f<circle-info>   \rJust leave a good review for evalate on the market.\n\n\v\f<note-sticky>   \rThe bot will automatically gift the config within 5 minutes.\n\n\v\f<circle-exclamation>   \rIf it doesn't, join discord server & open a ticket.")

					t15.home.free_config:label("\v\f<gift>     \rConfig for Review"):depend(t18.home.other):tooltip(v132)

					local v133 = v42(u40.format("http://market.neverlose.cc/%s", PRO == t1.PRO and "b83thf" or "Vrr2ot"))

					t15.home.free_config:button("  \v\f<arrow-up-right-from-square>  ", v133, true):depend(t18.home.other):disabled(PRO == t1.TRIAL):tooltip(v132)
					t14.ex_backtrack = ui.find("Aimbot", "Ragebot", "Main", "Enabled", "Extended Backtrack")

					local t36 = {
						air_stop = false
					}

					u47.new("peek_assist", t15.features.rage:switch("\v\f<star>    \rPeek assist", false, nil, function(p92, p93)
						local t37 = {
							info = p92:label("\v\f<circle-info>  \rBind the main switch to a comfortable button for you"),
							air_stop = p92:switch("Air stop"),
							auto_peek = p92:switch("Auto peek"),
							freestanding = p92:switch("Freestanding"),
							ex_backtrack = p92:switch("Extended backtrack")
						}

						p93:tooltip("\v\f<circle-info>  \rAll the functions you need for a peek in one switch!")

						return t37
					end), t18.features.rage)
					events.createmove(function(p94)
						-- upvalues: t14 (copy), t36 (copy), u47 (ref)
						t14.auto_stop.options:override()
						t14.auto_stop.double_tab:override()
						t14.peek_assist:override()
						t14.ex_backtrack:override()
						t14.freestanding:override()
						t36.air_stop = false

						local v587 = u47.get("peek_assist")
						local v588 = entity.get_local_player()

						if v587.value and v588 and v588:is_alive() then
							local v589 = v588:get_anim_state()
							local v590 = not v589.on_ground or p94.in_jump

							if v587.air_stop:get() and v590 then
								t36.air_stop = true
								t14.auto_stop.options:override({
									[1] = "In Air",
									[2] = "Full Stop"
								})
								t14.auto_stop.double_tab:override({})
							end

							if v587.auto_peek:get() then
								t14.peek_assist:override(true)
							end

							if v587.freestanding:get() and not t14.freestanding:get() and not t14.freestanding:get_override() and v589.on_ground then
								t14.freestanding:override(true)
							end

							if v587.ex_backtrack:get() then
								t14.ex_backtrack:override(true)
							end

							return
						end
					end)
					u135 = true

					local function v136(p95, p96, p97)
						local m_vecVelocity = p95.m_vecVelocity

						for _ = 0, p97 do
							p96.x = p96.x + m_vecVelocity.x * globals.tickinterval
							p96.y = p96.y + m_vecVelocity.y * globals.tickinterval
							p96.z = p96.z + m_vecVelocity.z * globals.tickinterval
						end

						return p96
					end

					local t38 = {
						[9] = 1,
						[40] = 2,
						[31] = 3
					}

					local function v138(p98, p99, _, p101, p102)
						-- upvalues: t14 (copy), t38 (copy), v136 (copy), v37 (copy)
						if t14.double_tap:get() and rage.exploit:get() == 1 then
							local v604 = p101:get_weapon_index()

							if v604 ~= nil then
								local v605 = t38[v604]

								if v605 ~= nil then
									if p102.weapons:get(v605) then
										if not p98.in_jump or p102.on_cross:get() then
											local v606 = p99:get_eye_position()
											local v607 = v136(p99, v606, 6)

											entity.get_players(true, false, function(p103)
												-- upvalues: v37 (copy), p99 (copy), v607 (copy)
												if p103:is_alive() then
													local v1902 = p103:get_hitbox_position(3)
													local v1903, v1904 = v37.trace_bullet(p99, v607, v1902)

													if v1903 > 10 and v1904.entity and p103 == v1904.entity then
														rage.exploit:force_teleport()
													end

													return
												end
											end)

											return
										end

										return
									end

									return
								end

								return
							end

							return
						end
					end
					local function v139(p104, _, _, p107, p108)
						-- upvalues: t14 (copy), v38 (copy)
						t14.double_tap.lag_limit:override()

						local v613 = p107:get_weapon_info()

						if v613 then
							if v613.weapon_type ~= 9 then
								if rage.exploit:get() ~= 1 or globals.tickcount % p108.ticks:get() ~= 0 then
									rage.exploit:force_charge()
								else
									p104.force_defensive = true
									t14.double_tap.lag_limit:override(v38.random(7))
									rage.exploit:force_teleport()
								end

								return
							end

							return
						end
					end

					u47.new("air_teleport", t15.features.rage:switch("\v\f<share>    \rAir teleport", false, nil, function(p109)
						-- upvalues: u47 (ref)
						local t39 = {
							_type = p109:list("\n", {
								[1] = "On enemy",
								[2] = "Exploit"
							})
						}

						u47.set_callback_list(t39._type, true)
						t39.on_cross = p109:switch("Allow on cross"):depend({
							[1] = nil,
							[2] = 1,
							[1] = t39._type
						})
						t39.weapons = p109:listable("", "Awp", "Scout", "Taser"):depend({
							[1] = nil,
							[2] = 1,
							[1] = t39._type
						})
						t39.ticks = p109:slider("Ticks", 10, 30):depend({
							[1] = nil,
							[2] = 2,
							[1] = t39._type
						})

						return t39, true
					end), t18.features.rage)
					u47.get("air_teleport"):tooltip("\v•  \rOn enemy - Predict your position and allows you to teleport to your opponents\n\n\v•  \rExploit - Allows for perfectly Break LC")
					u47.get("air_teleport"):set_event("createmove", function(p110)
						-- upvalues: u135 (ref), t36 (copy), u47 (ref), v138 (copy), v139 (copy)
						if u135 and not t36.air_stop then
							local v615 = entity.get_local_player()

							if v615 and v615:is_alive() then
								local v616 = v615:get_anim_state()

								if v616 then
									if not v616.on_ground then
										local v617 = v615:get_player_weapon()

										if v617 then
											local v618 = u47.get("air_teleport")

											if v618._type:get() ~= 1 then
												v139(p110, v615, v616, v617, v618)
											else
												v138(p110, v615, v616, v617, v618)
											end

											return
										end

										return
									end

									return
								end

								return
							end

							return
						end
					end)
					u47.new("jump_scout", t15.features.rage:switch("\v\f<wind>    \rJump scout"), t18.features.rage)
					u47.get("jump_scout"):tooltip("\v\f<circle-info>  \rIf you stand and do not move, you can jump with a scout or a revolver and shoot your opponent\n\n\v\f<triangle-exclamation>  \rAdvised to turn it off while using grenade helper")
					events.createmove(function(p111)
						-- upvalues: u135 (ref), t14 (copy)
						if u135 == false then
							t14.air_strafe:override()
						end

						u135 = true

						local v622 = entity.get_local_player()

						if v622 and v622:is_alive() then
							local v623 = v622:get_anim_state()

							if v623 then
								local v624 = v622:get_player_weapon()
								local v625 = v624 ~= nil and v624:get_name() or "nil"
								local v626 = p111.forwardmove + p111.sidemove
								local v627 = p111.in_jump or not v623.on_ground
								local v628 = v623.velocity:length()
								local v629 = p111.in_moveleft or (p111.in_moveright or (p111.in_forward or (p111.in_back or (p111.in_left or p111.in_right))))

								if (v625 == "SSG 08" or v625 == "R8 Revolver") and v627 and not v629 and v626 == 0 and not (v628 >= 1.2) then
									u135 = false
									t14.air_strafe:override(false)
									t14.auto_stop.options:override({
										[1] = "In Air"
									})

									return
								end

								return
							end

							return
						end
					end)

					local t40 = {
						data = {},
						names = {},
						new = function(p112, p113, p114)
							-- upvalues: v39 (copy)
							p112.data[p113] = p114
							v39.insert(p112.names, p113)
						end
					}

					t40:new("Stand", function(p115, _, p117, p118)
						return p117.on_ground and (p118 < 2 and not p115.in_duck)
					end)
					t40:new("Crouch", function(p119, _, p121, _)
						return p121.on_ground and p119.in_duck
					end)
					t40:new("Slow walk", function(_, _, _, _)
						-- upvalues: t14 (copy)
						return t14.slow_walk:get()
					end)

					local t41 = {
						data = {},
						names = {},
						new = function(p127, p128, p129)
							-- upvalues: v39 (copy)
							p127.data[p128] = p129
							v39.insert(p127.names, p128)
						end
					}

					t41:new("Pistols", function(p130, p131, _, _, _, _)
						return p131.weapon_type == 1 and p130 ~= "Desert Eagle"
					end)
					t41:new("Desert Eagle", function(p136, _, p138, _, p140, _)
						return p136 == "Desert Eagle" and (not p140.on_ground or not p138.in_duck)
					end)
					t41:new("Auto Snipers", function(p142, _, _, _, _, _)
						return p142 == "SCAR-20" or p142 == "G3SG1"
					end)
					t41:new("Desert Eagle & Crouch", function(p148, _, p150, _, p152, _)
						return p148 == "Desert Eagle" and (p152.on_ground and p150.in_duck)
					end)

					local v142 = t15.features.gameplay:switch("\v\f<shield>    \rAuto OS", false, nil, function(p154, p155)
						-- upvalues: t40 (copy), t41 (copy)
						local t42 = {
							states = p154:listable("\v\f<wave-pulse>   \rStates", t40.names),
							avoid_states = p154:listable("\v\f<arrow-rotate-right>   \rAvoid", t41.names)
						}

						p155:tooltip("\v\f<circle-info>   \rEnables hide shots in certain situations with double tap.")
						t42.avoid_states:tooltip("\v\f<circle-info>   \rSelect a state from the list that you would not want the function to work with.\n\n\v\f<lightbulb>   \rFor example, if you select \vPistols\r, then \vAuto OS\r will not work if you are holding a pistol.")
						t42.avoid_states:depend({
							[1] = t42.states,
							[2] = function()
								-- upvalues: t42 (copy)
								return not (#t42.states.value <= 0)
							end
						})

						return t42, true
					end)

					u47.new("auto_hide_shots", v142, t18.features.rage)

					function t41.get_active(p156, p157, p158, p159, p160, p161, p162)
						-- upvalues: v142 (copy)
						if p157 ~= "R8 Revolver" then
							for k, v in next, p156.names do
								local v684 = p156.data[v]

								if v142.avoid_states:get(k) and v684 and v684(p157, p158, p159, p160, p161, p162) then
									return true
								end
							end

							return false
						end

						return true
					end
					function t40.get_active(p163, p164, p165, p166, p167)
						-- upvalues: v142 (copy)
						for k, v in next, p163.names do
							local v692 = p163.data[v]

							if v142.states:get(k) and v692 and v692(p164, p165, p166, p167) then
								return true
							end
						end

						return false
					end

					local function v143()
						-- upvalues: t14 (copy)
						t14.hide_shots:override()
						t14.double_tap:override()
					end

					v142:set_callback(v143)
					v142:set_event("createmove", v43(v142, function(p168)
						-- upvalues: t14 (copy), t40 (copy), t41 (copy), v143 (copy)
						local v694 = entity.get_local_player()

						if v694 then
							local v695 = v694:get_anim_state()

							if v695 then
								local v696 = v694:get_player_weapon()
								local v697 = v696:get_name()
								local v698 = v696:get_weapon_info()
								local v699 = v695.velocity:length()

								if not t14.double_tap:get() or t14.hide_shots:get() or rage.exploit:get() ~= 1 or t14.peek_assist:get_override() or t14.peek_assist:get() or not t40:get_active(p168, v694, v695, v699) or t41:get_active(v697, v698, p168, v694, v695, v699) then
									v143()

									return
								end

								t14.hide_shots:override(true)
								t14.double_tap:override(false)

								return
							end

							return
						end
					end, t1.PRO, t1.TRIAL))

					local t43 = {}
					local t44 = {}
					local t45 = {}

					local function v147(p169, p170, p171)
						-- upvalues: v39 (copy), t43 (copy), t45 (copy), t44 (copy)
						v39.insert(t43, p170)
						v39.insert(t45, p169 .. p170)
						t44[p170] = p171
					end

					v147(" \v\f<hourglass>   \r", "Stand", function(p172, _)
						return p172.velocity:length() < 2 and (p172.on_ground and not (p172.anim_duck_amount >= 0.8))
					end)
					v147("\v\f<knife-kitchen>  \r", "DT Knife", function(_, p175)
						-- upvalues: t14 (copy)
						return (not not t14.double_tap:get() or t14.double_tap:get_override()) and p175:get_classname() == "CKnife"
					end)
					v147("\v\f<gun>  \r", "DT Revolver", function(_, p177)
						-- upvalues: t14 (copy)
						return (not not t14.double_tap:get() or t14.double_tap:get_override()) and p177:get_name() == "R8 Revolver"
					end)
					v147("\v\f<triangle-exclamation>   \r", "DT Discharge", function()
						-- upvalues: t14 (copy)
						return rage.exploit:get() < 1 and (t14.double_tap:get() or t14.double_tap:get_override())
					end)
					u47.new("lag_disablers", t15.features.gameplay:switch("\v\f<wand-magic-sparkles>    \rLag disablers", false, nil, function(p178)
						-- upvalues: t45 (copy)
						return {
							states = p178:listable("", t45)
						}, true
					end), t18.features.rage)
					u47.get("lag_disablers"):set_event("createmove", function()
						-- upvalues: t14 (copy), u47 (ref), t43 (copy), t44 (copy)
						t14.fake_lag:override()

						local v709 = entity.get_local_player()

						if v709 ~= nil then
							local v710 = v709:get_anim_state()

							if v710 ~= nil then
								local v711 = v709:get_player_weapon()

								if v711 ~= nil then
									local v712 = u47.get("lag_disablers")

									for k, v in next, t43 do
										local v715 = t44[v]

										if v712.states:get(k) and v715 and v715(v710, v711) then
											t14.fake_lag:override(false)

											return
										end
									end

									return
								end

								return
							end

							return
						end
					end)
					t46 = {
						enabled = false
					}

					local v149 = t15.features.hitchances:switch("\v\f<syringe>    \rDormant aimbot", false, nil, function(p179)
						return {
							min_damage = p179:slider("Damage", 0, 100, 20),
							min_inaccuracy = p179:slider("Inaccuracy", 0, 100, 80)
						}
					end)

					u47.new("dormant_aimbot", v149, t18.features.rage)
					v149:set_callback(function()
						-- upvalues: t46 (copy), v149 (copy)
						t46.enabled = v149:get()
					end, true)

					local function v150(p180, p181)
						-- upvalues: v38 (copy)
						local v722 = v38.sqrt(p180.forwardmove * p180.forwardmove + p180.sidemove * p180.sidemove)

						if p181 > 0 and not (v722 <= 0) then
							if p180.in_duck then
								p181 = p181 * 2.94117647
							end

							if not (v722 <= p181) then
								local v723 = p181 / v722

								p180.forwardmove = p180.forwardmove * v723
								p180.sidemove = p180.sidemove * v723

								return
							end

							return
						end
					end

					local t47 = {
						[1] = "100% info",
						[2] = "updated by shared esp",
						[3] = "updated by sounds",
						[4] = "not updated",
						[5] = "data is unavailable or too old"
					}

					local function v152(p182)
						-- upvalues: v37 (copy), v149 (copy), t47 (copy)
						local v725 = entity.get_players(true, true)
						local v726 = p182:get_eye_position()
						local t48 = nil

						for _, v in next, v725 do
							local v730 = v:get_network_state()
							local v731 = v:get_bbox()

							if v:is_alive() and v:is_dormant() and v730 ~= 0 and v731.alpha > 0 then
								local v732 = v:get_origin() + vector(0, 0, 35) + vector(v37.random_float(-7, 7), v37.random_float(-7, 7), v37.random_float(-10, 25))
								local v733, _ = v37.trace_bullet(p182, v726, v732, function(p183)
									return p183:is_player() and p183:is_enemy()
								end)

								if v733 >= v149.min_damage.value then
									t48 = {
										player = v,
										damage = v733,
										angles = v726:to(v732):angles(),
										network_state = t47[v730] or v730
									}
								end
							end
						end

						return t48
					end

					local t49 = {}
					local n4 = 0

					events.aim_fire(function()
						-- upvalues: n4 (ref), v38 (copy)
						n4 = v38.floor(globals.realtime)
					end)
					events.weapon_fire(v43(v149, function(p184)
						-- upvalues: n4 (ref), v38 (copy), t49 (copy), t5 (ref), pui (copy)
						if entity.get(p184.userid, true) == entity.get_local_player() and n4 ~= v38.floor(globals.realtime) then
							local v746 = t49[v38.floor(globals.realtime)]

							if v746 then
								local v747 = t5.build(nil, "Dormant shot at {name} › damage: {damage} · state: {state} ‹", {
									name = v746.player:get_name(),
									damage = v746.damage,
									hitbox = v746.hitbox,
									state = v746.network_state
								})

								t5.print(v747)

								local v748 = t5.build(nil, "Shot at {name} › {damage} dmg · {state} ‹", {
									name = v746.player:get_name(),
									damage = v746.damage,
									hitbox = v746.hitbox,
									state = v746.network_state
								})

								t5.screen(function(p185, p186)
									-- upvalues: t5 (ref), v748 (copy), pui (copy)
									t5.center(p186, v748, (pui.colors.active or color()):alpha_modulate(p185.alpha))
								end)

								return
							end

							return
						end
					end, t1.PRO, t1.TRIAL))
					v149:set_event("createmove", v43(v149, function(p187)
						-- upvalues: v38 (copy), v152 (copy), v150 (copy), v149 (copy), t49 (copy)
						local v736 = entity.get_local_player()

						if v736 and v736:is_alive() then
							if v736:get_anim_state().on_ground and not p187.in_jump then
								local v737 = v736:get_player_weapon()

								if v737 then
									local v738 = 1 / v737:get_inaccuracy()
									local v739 = v38.clamp(v738, 0, 666)
									local v740 = v737:get_weapon_info()

									if not (v740.bullets < 1) then
										local v741 = v740.weapon_type == 5
										local v742 = false

										if v741 or v740.is_revolver then
											v742 = globals.curtime + 0.3 > v736.m_flNextAttack and not (globals.curtime + 0.3 <= v737.m_flNextPrimaryAttack)
										end

										if v742 then
											local v743 = v152(v736)

											if v743 then
												if v741 and not v736.m_bIsScoped then
													p187.in_attack2 = true
												end

												v150(p187, (v736.m_bIsScoped and v740.max_player_speed_alt or v740.max_player_speed) * 0.1)

												if not (v739 < v149.min_inaccuracy.value) then
													local v744 = v736.m_aimPunchAngle * cvar.weapon_recoil_scale:float()

													p187.view_angles = v743.angles - v744
													p187.in_attack = true
													t49[v38.floor(globals.realtime)] = v743

													return
												end

												return
											end

											return
										end

										return
									end

									return
								end

								return
							end

							return
						end
					end, t1.PRO, t1.TRIAL))
					u155 = nil

					local t51 = {
						data = {
							Head = {
								[1] = 0
							},
							Chest = {
								[1] = 5,
								[2] = 6
							},
							Stomach = {
								[1] = 2,
								[2] = 3,
								[3] = 4
							},
							Arms = {
								[1] = 13,
								[2] = 14,
								[3] = 15,
								[4] = 16,
								[5] = 17,
								[6] = 18
							},
							Legs = {
								[1] = 7,
								[2] = 8,
								[3] = 9,
								[4] = 10
							},
							Feet = {
								[1] = 11,
								[2] = 12
							}
						},
						get_hitbox_indexes = function(p188, p189)
							local t50 = {}

							for _, v in next, p189 do
								local v754 = p188.data[v]

								if v754 then
									for _, v2 in next, v754 do
										t50[#t50 + 1] = v2
									end
								end
							end

							return t50
						end
					}

					t52 = {
						data = {},
						names = {},
						new = function(p190, p191, p192)
							p190.data[p191] = p192
							p190.names[#p190.names + 1] = p191
						end,
						is_weapon_selected = function(p193, p194, p195)
							local v763 = p194:get_player_weapon()

							if v763 then
								local v764 = v763:get_name()
								local v765 = v763:get_weapon_info()

								for _, v in next, p195 do
									local v768 = p193.data[v]

									if v768 and v768(v764, v765) then
										return true
									end
								end
							end

							return false
						end
					}
					t52:new("Scout", function(p196, _)
						return p196 == "SSG 08"
					end)
					t52:new("Pistols", function(p198, p199)
						return p199.weapon_type == 1 and p198 ~= "Desert Eagle"
					end)
					t52:new("Desert Eagle", function(p200, _)
						return p200 == "Desert Eagle"
					end)
					v158 = t15.features.hitchances:switch("\v\f<person-walking-arrow-right>   \rAI Peek", false, nil, function(p202)
						-- upvalues: t52 (copy)
						local t53 = {
							target = p202:combo("\v\f<user>    \rTarget", {
								[1] = "Cyrcle",
								[2] = "Closest Crosshair"
							}),
							target_limit = p202:slider(" \a[grey]\f<angle-right>     \rLimit", 0, 10, 2, 1, function(p203)
								if p203 ~= 0 then
									return
								end

								return "Off"
							end),
							distance = p202:slider("\v\f<ruler>    \rDistance", 10, 50, 27),
							weapons = p202:selectable("\v\f<shield>    \rWeapons", t52.names),
							hitboxes = p202:selectable("\v\f<eye>    \rHitboxes", {
								[1] = "Head",
								[2] = "Chest",
								[3] = "Stomach",
								[4] = "Arms",
								[5] = "Legs",
								[6] = "Feet"
							}),
							_ = p202:label("\v\f<sparkles>     \rPreset"),
							load_preset = p202:button("     \v\f<play>     ", nil, true)
						}

						t53.target_limit:depend({
							[1] = nil,
							[2] = "Cyrcle",
							[1] = t53.target
						})
						t53.load_preset:set_callback(function()
							-- upvalues: t53 (copy)
							pcall(function()
								-- upvalues: t53 (copy)
								t53.target:set("Cyrcle")
								t53.target_limit:set(2)
								t53.distance:set(29)
								t53.weapons:set({
									[1] = "Scout"
								})
								t53.hitboxes:set({
									[1] = "Stomach"
								})
							end)
						end)

						return t53
					end)
					u47.new("ai_peek", v158, t18.features.rage)
					v158:tooltip("\v\f<circle-info>   \rAutomatically peek at the opponent to hit him when possible.\n\n\v\f<note>   \rWe recommend bind this button.")
					v158.hitboxes:tooltip("\v\f<circle-info>   \rIf you are experiencing large FPS drops, we recommend leaving only \vChest\r, \vStomach \rand maybe \vFeet\r.")
					v158.target_limit:tooltip("\v\f<circle-info>   \rMaximum number of targets that will be processed in one tick. Saves your FPS.")
					t54 = {}
					v158.hitboxes:set_callback(function(p204)
						-- upvalues: t54 (ref), t51 (copy)
						t54 = t51:get_hitbox_indexes(p204:get())
					end, true)
				end

				local function v160(p205, p206)
					local v780 = not (p206.m_flVelocityModifier >= 0.9)
					local v781 = p205.in_moveleft or (p205.in_moveright or (p205.in_back or (p205.in_forward or p205.in_jump)))
					local v782 = false
					local v783 = p206:get_player_weapon()

					if v783 then
						local v784 = v783.m_bInReload == 1
						local v785 = not (p206.m_flNextAttack >= globals.curtime)
						local v786 = not (v783.m_flNextPrimaryAttack >= globals.curtime)

						v782 = v785 and (v786 and not v784)
					end

					return v782 and (not v781 and not v780)
				end
				local function v161(p207, p208, p209, p210)
					-- upvalues: v38 (copy)
					local v791 = p209:dist(p210) + 5
					local v792 = p209 + (p210 - p209):normalized() * (v791 + 5)
					local v793 = p208:get_anim_state()

					if p207.forwardmove == 0 and p207.sidemove == 0 and not p207.in_forward and not p207.in_back and not p207.in_moveleft and not p207.in_moveright and not p207.in_jump and v793 and v793.on_ground then
						if not (v791 < 0.5) then
							local y = (v792 + (v792 - p209):normalized() * 10 - p209):angles().y

							if y ~= nil then
								p207.move_yaw = y
								p207.in_speed = 0
								p207.in_moveright = 0
								p207.in_moveleft = 0
								p207.sidemove = 0

								if not (v791 > 8) then
									local v795 = v38.min(450, v38.max(1.1 + p208.m_flDuckAmount * 10, v791 * 9))
									local v796 = p208.m_vecAbsVelocity:length2d()

									if not (v796 >= v38.min(250, v795) + 15) then
										p207.forwardmove = v38.max(6, v796 >= v38.min(250, v795) and v795 * 0.9 or v795)
										p207.in_forward = 1
									else
										p207.forwardmove = 0
										p207.in_forward = 0
									end
								else
									p207.forwardmove = 900000
								end

								return
							end

							return
						end

						return
					end
				end
				local function v162(p211, p212, p213, p214)
					-- upvalues: v35 (copy), v38 (copy), v37 (copy)
					local y = v35.camera_angles().y
					local v802 = p212.z - p213.z
					local t55 = {}

					for i = -1, 1, 2 do
						local v805 = y + 90 * i
						local v806 = vector(v38.cos(v38.rad(v805)), v38.sin(v38.rad(v805)), 0)
						local v807 = p212 + v806 + v806 * p214
						local v808 = v37.trace_line(v807, v807 + vector(0, 0, -200), p211)

						if v808.fraction < 1 then
							v807 = v808.end_pos + vector(0, 0, v802)
						end

						local v809 = v37.trace_line(p212, v807, entity.get_players())

						if v809.fraction ~= 1 then
							local v810 = p212 + (v806 + v806 * p214) * v809.fraction - v806

							if (v810 - p213):length2d() > 25 then
								t55[#t55 + 1] = v810
							end
						else
							t55[#t55 + 1] = v807
						end
					end

					return t55
				end
				local function v163(p215, p216, p217, p218, p219)
					-- upvalues: v37 (copy)
					for _, v in next, p219 do
						local v818 = p216:get_hitbox_position(v)
						local v819, v820 = v37.trace_bullet(p215, p217, v818, function(p220)
							return p220:is_player() and p220:is_enemy()
						end)

						if v820.entity and p216 == v820.entity and p218 <= v819 then
							return true
						end
					end
				end
				local function v164()
					-- upvalues: v35 (copy), v38 (copy)
					local v821 = v35.camera_angles()
					local v822 = v35.camera_position()
					local v823 = vector():angles(v821)
					local huge = v38.huge
					local v825 = nil

					for _, v in ipairs(entity.get_players(true)) do
						local v828 = v:get_hitbox_position(1):dist_to_ray(v822, v823)

						if v828 < huge then
							huge = v828
							v825 = v
						end
					end

					return v825
				end
				local function v165()
					local t56 = {}
					local v830 = entity.get_players(true, false)

					for _, v in next, v830 do
						if v:is_alive() then
							local v833 = v:get_origin():to_screen()

							if v833 and v833.x and v833.y then
								t56[#t56 + 1] = v
							end
						end
					end

					return t56
				end

				local v166 = ui.find("Aimbot", "Ragebot", "Selection", "Min. Damage")

				ui.find("Aimbot", "Ragebot", "Main", "Peek Assist")

				local v167 = ui.find("Aimbot", "Ragebot", "Main", "Double Tap")
				local t57 = {}
				local u169 = nil
				local u170 = nil
				local u171 = false

				local function v172()
					-- upvalues: u171 (ref)
					u171 = true
				end
				local function v173()
					-- upvalues: u171 (ref)
					u171 = false
				end

				local t58 = {
					tickcount = 0,
					position = vector()
				}
				local u175 = false

				local function v176()
					-- upvalues: v167 (copy)
					return v167:get() and rage.exploit:get() == 1
				end

				v158:set_event("render", v43(v158, function()
					-- upvalues: u171 (ref), t57 (ref), v35 (copy), u169 (ref)
					if u171 then
						local v848 = entity.get_local_player()

						if v848 and v848:is_alive() then
							for _, v in next, t57 do
								v35.circle(v:to_screen(), v == u169 and color(0, 255, 0) or color(100, 100, 100), 3, 0, 1)
							end

							return
						end

						return
					end
				end, t1.PRO, t1.TRIAL))
				events.createmove(v43(v158, function(p221)
					-- upvalues: v158 (copy), t52 (copy), v173 (copy), v172 (copy), t57 (ref), v162 (copy), u170 (ref), t58 (copy), v160 (copy), u175 (ref), v161 (copy), u169 (ref), v176 (copy), v166 (copy), v164 (copy), v163 (copy), t54 (ref), v165 (copy), u155 (ref)
					local v835 = entity.get_local_player()

					if v835 and v835:is_alive() then
						local v836 = v158.weapons:get()

						if t52:is_weapon_selected(v835, v836) then
							v172()

							local v837 = v835:get_eye_position()
							local v838 = v835:get_origin()

							if v158:get() then
								if v158:get() and (not t57 or not u170) then
									t57 = t57 and t57 or v162(v835, v837, v838, distance)
									u170 = u170 or v838
								end

								if not t58.position or not (t58.tickcount + 30 >= globals.tickcount) or not v160(p221, v835) or u175 then
									if not ((u170 - v838):length2d() > 5) then
										u175 = false
										u169 = nil

										if v176() then
											local v839 = v166:get()

											if v158.target:get() ~= "Closest Crosshair" then
												local v840 = v165()
												local value = v158.target_limit.value

												local function v842()
													-- upvalues: v840 (copy), t57 (ref), v163 (copy), v835 (copy), v839 (copy), t54 (ref), u169 (ref), t58 (copy), value (copy)
													for _, v in ipairs(v840) do
														for _, v3 in ipairs(t57) do
															if v163(v835, v, v3, v839, t54) then
																u169 = v3
																t58.tickcount = globals.tickcount
																t58.position = v3

																return
															end
														end

														if value > 0 then
															coroutine.yield()
														end
													end
												end

												if value > 0 and (not u155 or coroutine.status(u155) == "dead") then
													u155 = coroutine.create(v842)
												end

												if not (value > 0) then
													v842()
												else
													for _ = 1, value do
														if coroutine.status(u155) == "dead" then
															return
														end

														coroutine.resume(u155)
													end
												end
											else
												local v844 = v164()

												for _, v in ipairs(t57) do
													if v163(v835, v844, v, v839, t54) then
														u169 = v
														t58.tickcount = globals.tickcount
														t58.position = v

														return
													end
												end
											end

											return
										end

										return
									end

									return v161(p221, v835, v838, vector(u170.x, u170.y, v838.z))
								end

								return v161(p221, v835, v837, vector(t58.position.x, t58.position.y, v837.z))
							end

							local v847 = v158.distance:get()

							t57 = v162(v835, v837, v838, v847)
							u170 = v838
							t58.position = nil

							return
						end

						return v173()
					end
				end, t1.PRO, t1.TRIAL))
				events.weapon_fire(v43(v158, function(p222)
					-- upvalues: u175 (ref)
					if entity.get(p222.userid, true) == entity.get_local_player() then
						u175 = true
					end
				end, t1.PRO, t1.TRIAL))

				local t59 = {}
				local n5 = 0.05

				function u179(p223, p224, p225)
					-- upvalues: t59 (copy), smoothy (copy), n5 (copy), v38 (copy)
					local v855 = nil
					local v856 = nil

					if type(p224) == "table" then
						v855 = p224[2]
						v856 = p224[3]
						p224 = p224[1]
					end

					if t59[p223] == nil then
						t59[p223] = smoothy.new(p224)
					end

					local v857 = t59[p223](p225 or n5, p224)

					if v855 == nil or v856 == nil then
						return v857
					end

					return v38.clamp(v857, v855, v856)
				end

				local v180 = pui.accent:clone()
				local t60 = {
					Static = {
						[1] = v180
					},
					Rainbow = {
						[1] = v180
					}
				}
				local v182 = t15.features.main:switch("\v\f<paintbrush>   \rAccent color", false, "Enable to use custom color", t60)

				v182.color:depend(v182)
				u47.new("accent", v182, t18.features.visual)
				events.render(function()
					-- upvalues: v182 (copy)
					local v858, v859 = v182.color:get()

					if v858 == "Rainbow" then
						local _, v861, v862 = v859:to_hsv()
						local v863 = color():as_hsv(globals.realtime % 3 / 3, v861, v862, v859.a / 255)

						v182.color:set("Rainbow", {
							[1] = v863
						})
					end
				end)

				function u183()
					-- upvalues: v182 (copy), pui (copy)
					local _, v865 = v182.color:get()

					return v182:get() and v865:clone() or pui.accent:clone()
				end

				events.render(function()
					-- upvalues: pui (copy), u183 (ref)
					pui.colors.accent = u183()
				end)
				u184 = true
				u185 = true

				local v186 = t15.features.main:label("\v\f<bars>    \rSettings", nil, function(p226)
					return {
						dpi = p226:switch("\v\f<font>   \rScaling"),
						blur = p226:switch("\v\f<droplet>    \rBlur"),
						shadow = p226:switch("\v\f<brightness>   \rGlow", true)
					}
				end)

				v186:depend(t18.features.visual)
				v186.blur:tooltip("\v\f<circle-info>   \rProblems with FPS? Turn it off!")
				v186.blur:set_callback(function()
					-- upvalues: u184 (ref), v186 (copy)
					u184 = v186.blur.value
				end, true)
				v186.shadow:set_callback(function()
					-- upvalues: u185 (ref), v186 (copy)
					u185 = v186.shadow.value
				end, true)

				function u187()
					-- upvalues: v186 (copy), v35 (copy)
					return v186.dpi.value and v35.get_scale(2) or 1
				end
				function u188(p227)
					-- upvalues: v186 (copy)
					local str = tostring(p227)

					return v186.dpi.value and str .. "s" or str:gsub("s", "")
				end

				local blur = v35.blur

				function v35.blur(...)
					-- upvalues: u184 (ref), blur (copy)
					if u184 then
						blur(...)
					end
				end

				local shadow = v35.shadow

				function v35.shadow(...)
					-- upvalues: u185 (ref), shadow (copy)
					if u185 then
						shadow(...)
					end
				end

				t61 = {
					font = {
						title = v35.load_font("arial", vector(14, 12), "ad"),
						content = v35.load_font("arial", vector(12, 10), "a")
					},
					box = function(_, p229, p230, p231, p232, p233)
						-- upvalues: v35 (copy)
						v35.blur(p229, p229 + p230, 1, p232, p233)
						p231.a = p231.a * (p232 / 255)
						v35.rect(p229, p229 + p230, p231, p233)
					end,
					new = function(p234, p235, p236, p237, p238, p239)
						-- upvalues: pui (copy), v35 (copy), u188 (ref), u187 (ref), v38 (copy), v18 (copy), u184 (ref)
						if type(p238) == "string" then
							p238 = pui.string(p238)
						end

						if type(p237) == "string" then
							p237 = pui.string(p237)
						end

						local v881 = type(p238) == "string" and v35.measure_text(p234.font.title, u188(), p238).x + 15 * u187() or (type(p238) == "number" and p238 or 0)
						local v882 = type(p237) == "string" and v35.measure_text(p234.font.content, u188(), p237).x + 15 * u187() or (type(p237) == "number" and p237 or 0)
						local v883 = v38.floor(v881)
						local v884 = v38.floor(v882)
						local v885 = 5 * u187()
						local v886 = 2 * u187()
						local v887 = 4 * u187()
						local a = p236.a
						local v889 = color(20, a * 0.5)
						local v890 = (vector(13, 13) * u187()):floor()
						local v891 = (vector(4, 19) * u187()):floor()
						local v892 = v38.floor(3 * u187())
						local y = v891.y
						local v894 = p239 and p234.avatar

						if v894 then
							v884 = v884 + v890.x + 3
						end

						local v895 = vector(v883 + v884 + (v883 > 0 and v885 + v886 or 0), y)

						if p235 == nil then
							p235 = vector(v18.x - (v895.x + 15), 10)
						end

						if type(p235) == "table" and p235[2] == true then
							p235 = p235[1] - v895 / 2
						end

						local v896 = y / 2
						local v897 = 3 * u187()

						v35.shadow(p235 + vector(0, v896 - v897), p235 + vector(0, v896 + v897), p236, 30 * u187())
						v35.shadow(p235 + vector(v895.x, v896 - v897), p235 + vector(v895.x, v896 + v897), p236, 30 * u187())

						if u184 then
							v35.rect(p235 - vector(v891.x + 1 - v892, 0), p235 + v891 - vector(v891.x + 1 - v892, 0), p236, {
								[1] = nil,
								[2] = 0,
								[3] = 0,
								[1] = v887,
								[4] = v887
							})
							v35.rect(p235 + vector(v895.x - v892 + 1, 0), p235 + vector(v895.x - v892 + 1, 0) + v891, p236, {
								[1] = 0,
								[2] = nil,
								[3] = nil,
								[4] = 0,
								[2] = v887,
								[3] = v887
							})
						end

						v35.blur(p235, p235 + v895, 1, p236.a / 255, v887)

						if v883 > 0 then
							v35.rect(p235, p235 + vector(v883, y), v889, {
								[1] = nil,
								[2] = 0,
								[3] = 0,
								[1] = v887,
								[4] = v887
							})

							if type(p238) == "string" then
								v35.text(p234.font.title, p235 + vector(7, 2) * u187(), color(222, a), u188(), p238)
							end

							p235.x = p235.x + v883
							v35.poly(v889, p235, p235 + vector(v885, 0), p235 + vector(0, y))
							p235.x = p235.x + v885 + v886
							v35.poly(v889, p235, p235 + vector(-v885, y), p235 + vector(0, y))
						end

						v35.rect(p235, p235 + vector(v884, y), v889, v883 > 0 and {
							[1] = 0,
							[2] = nil,
							[3] = nil,
							[4] = 0,
							[2] = v887,
							[3] = v887
						} or v887)

						if type(p237) == "string" then
							v35.text(p234.font.content, p235 + (v894 and vector(v890.x + 3, 0) or 0) + vector(7, 3) * u187(), color(222, a), u188(), p237)
						end

						return p235
					end
				}

				function v192(p240, p241)
					-- upvalues: pui (copy), v36 (copy), v35 (copy), v38 (copy)
					local str = tostring(p240)
					local v901 = p241 or vector()
					local v902 = pui.create("Drags")
					local t62 = {}
					local t64 = {
						dragging = false,
						mouse_pos = vector(0, 0),
						mouse_pos_diff = vector(0, 0),
						reference = (function()
							-- upvalues: v902 (copy), str (copy), v901 (copy)
							local t63 = {
								v902:slider(("%s.x"):format(str), -16384, 16384, v901.x),
								v902:slider(("%s.y"):format(str), -16384, 16384, v901.y)
							}

							local function v1915()
								-- upvalues: t63 (copy)
								t63[1]:visibility(false)
								t63[2]:visibility(false)
							end

							t63[1]:set_callback(v1915)
							t63[1]:set_callback(v1915, true)

							return t63
						end)()
					}

					function t62.intersects(_, p243, p244, p245)
						return p243.x >= p244.x and (p243.x <= p244.x + p245.x and (p243.y >= p244.y and not (p243.y > p244.y + p245.y)))
					end
					function t62.get_position(p246)
						return vector(p246.reference[1]:get(), p246.reference[2]:get())
					end
					function t62.is_dragging(p247)
						return p247.dragging
					end
					function t62.update(p248, p249)
						-- upvalues: v36 (copy), v35 (copy), v38 (copy)
						local v1924 = ui.get_mouse_position()
						local v1925 = ui.get_position()
						local v1926 = ui.get_size()
						local v1927 = ui.get_alpha() > 0 and v36.is_button_down(1)
						local v1928 = p248:intersects(v1924, p248:get_position(), p249) and not p248:intersects(v1924, v1925, v1926)

						p248.mouse_pos_diff = -(p248.mouse_pos - v1924)

						if v1927 and p248.intersected == nil then
							p248.intersected = v1928
						end

						if not v1927 or not p248.intersected then
							if not v1927 then
								p248.dragging = false
								p248.intersected = nil
							end
						else
							p248.dragging = true
						end

						if p248.dragging then
							local v1929 = v35.screen_size()
							local v1930 = p249 * 0.5
							local v1931 = vector(p248.reference[1]:get() + p248.mouse_pos_diff.x, p248.reference[2]:get() + p248.mouse_pos_diff.y)

							p248.reference[1]:set(v38.max(-v1930.x, v38.min(v1929.x - v1930.x, v1931.x)))
							p248.reference[2]:set(v38.max(-v1930.y, v38.min(v1929.y - v1930.y, v1931.y)))
						end

						p248.mouse_pos = v1924
						p248.mi_intersection = v1928 or p248.dragging

						return p248:get_position(), p248.dragging
					end

					local v905 = setmetatable(t62, {
						__index = t64
					})

					events.mouse_input:set(function()
						-- upvalues: v905 (copy)
						if not v905.mi_intersection or not (ui.get_alpha() > 0) then
							return
						end

						return false
					end)

					return v905
				end

				local v193 = t15.features.widgets:switch("\v\f<bookmark>   \rWatermark", true, nil, function(p250)
					-- upvalues: u47 (ref)
					local t65 = {
						name_type = p250:list("\v\f<user>  \rUsername", {
							[1] = "Cheat",
							[2] = "Steam",
							[3] = "Custom "
						})
					}

					u47.set_callback_list(t65.name_type, true)
					t65.name_input = p250:input(""):depend({
						[1] = nil,
						[2] = 3,
						[1] = t65.name_type
					})
					t65.time_format = p250:list("\v\f<clock>  \rTime format", {
						[1] = "24h",
						[2] = "12h"
					})
					u47.set_callback_list(t65.time_format, true)

					return t65, true
				end)

				u47.new("watermark", v193, t18.features.visual)

				local n6 = 0
				local n7 = 0
				local GetName = panorama.MyPersonaAPI.GetName

				local function v197()
					-- upvalues: v193 (copy), v39 (copy), GetName (copy), v17 (copy), v37 (copy), u40 (ref), n7 (ref), n6 (ref), v36 (copy)
					local t66 = {}
					local value = v193.name_type.value

					v39.insert(t66, "\a[accent]\f<user>  \r" .. (value == 2 and GetName() or (value == 3 and v193.name_input.value or v17)))

					local v910 = v37.net_channel()

					if v910 ~= nil and v910:get_server_info().address ~= "loopback" then
						v39.insert(t66, u40.format("\a[accent]\f<arrows-rotate>  \r%i ms", v910.latency[1] * 1000))
					end

					if globals.realtime > n7 + 0.8 then
						n6 = 1 / globals.absoluteframetime
						n7 = globals.realtime
					end

					v39.insert(t66, u40.format("\a[accent]\f<layer-group>  \r%i fps", n6))
					v39.insert(t66, "\a[accent]\f<clock>  \r" .. v36.get_date(v193.time_format.value == 1 and "%H:%M" or "%I:%M %p"):lower())

					return v39.concat(t66, "   ")
				end

				local v198 = gradient.text_animate("𝒆𝒗𝒂𝒍𝒂𝒕𝒆", -1.3, { color() })

				events.render(function()
					-- upvalues: v193 (copy), u179 (ref), u183 (ref), v198 (copy), t61 (copy), v197 (copy)
					local value = v193.value
					local v912 = u179("watermark_alpha", {
						[1] = value and 275 or -25
					})

					if value or not (v912 < 1) then
						local v913 = u183()

						v198:set_colors({
							v913,
							v913:alpha_modulate(50)
						})
						v198:animate()
						t61:new(nil, v913:alpha_modulate(v912), v197(), "\a[accent]\f<stars> " .. v198:get_animated_text(), true)

						return
					end
				end)

				local v199 = t15.features.widgets:switch("\v\f<gauge-simple-low>   \rSlow down", false, nil, function(p251)
					return {
						offset = p251:slider(" \a[grey]\f<angle-right>    \rOffset", 0, 100, 40, 1, "%")
					}, true
				end)

				u47.new("slow_down", v199, t18.features.visual)

				local function v200()
					local v915 = entity.get_local_player()

					if not v915 or not v915:is_alive() then
						return 1
					end

					return v915.m_flVelocityModifier
				end

				events.render(function()
					-- upvalues: v200 (copy), v199 (copy), u179 (ref), v18 (copy), t61 (copy), u40 (ref)
					local v916 = v200()
					local v917 = v199.value and (not (v916 >= 1) or not (ui.get_alpha() <= 0))
					local v918 = u179("slow_down_alpha", v917, 0.03)

					if v917 or not (v918 < 0.05) then
						local v919 = color(255, 0, 0):lerp(color(), v916):alpha_modulate(255 * v918)
						local v920 = u179("slow_down_offset", v199.offset.value * 0.01, 0.1)
						local v921 = vector(v18.x / 2, v18.y / 2 * v920 + 30 * v918)

						t61:new({
							[1] = nil,
							[2] = true,
							[1] = v921
						}, v919, u40.format("Slowed for %i%%", 100 * (1 - v916)))

						return
					end
				end)
			end

			local v201 = t15.features.widgets:switch("\v\f<magnifying-glass>   \rKeybinds")

			u47.new("keybinds", v201, t18.features.visual)

			local v202 = v192("keybinds", vector(100, v18.y / 5))
			local t67 = {}
			local t68 = {
				[1] = "hold",
				[2] = "toggle"
			}

			local function v205(p252)
				return p252:gsub("\aDEFAULT", ""):gsub("\a%b{}", ""):gsub("\a%x%x%x%x%x%x%x%x", ""):gsub("[^%w%s]", ""):gsub("^%s+", ""):gsub("%s+$", "")
			end
			local function v206()
				-- upvalues: v205 (copy), v39 (copy), t68 (copy), t67 (copy), smoothy (copy), v38 (copy)
				local v923 = false
				local t69 = {}

				for _, v in next, ui.get_binds() do
					local active = v.active
					local v928 = v205(tostring(v.name))
					local value = v.value

					if type(value) == "table" then
						local t70 = {}

						for _, v5 in next, value do
							v39.insert(t70, tostring(v5:sub(1, 1)))
						end

						value = not (#t70 > 0) or v39.concat(t70, ", ")
					end

					if type(value) == "boolean" then
						value = t68[v.mode] or "?"
					end

					if active then
						v923 = true
					end

					t67[v928] = t67[v928] or {
						alpha = 0,
						name = v928,
						value = value,
						smoothy = smoothy.new(0)
					}

					if value ~= t67[v928].value then
						t67[v928].value = value
					end

					t67[v928].alpha = v38.clamp(t67[v928].smoothy(0.05, active and 275 or -25), 0, 255)

					if t67[v928].alpha > 0 then
						v39.insert(t69, 1, t67[v928])
					end
				end

				return v923, t69
			end

			local n8 = 95

			events.render(function()
				-- upvalues: v206 (copy), v201 (copy), u179 (ref), u183 (ref), n8 (ref), u187 (ref), v202 (copy), t61 (copy), v35 (copy), u188 (ref), u40 (ref), v38 (copy)
				local v933, v934 = v206()
				local v935 = v201.value and (v933 or not (ui.get_alpha() <= 0))
				local v936 = u179("keybinds_alpha", v935, 0.05)

				if v935 or not (v936 < 0.05) then
					local v937 = u183():alpha_modulate(255 * v936)
					local v938 = vector(n8, 23 * u187())
					local v939 = v202:get_position()

					t61:new(v939, v937, v938.x)
					v35.text(t61.font.content, v939 + vector(v938.x / 2, 9 * u187()), color(210, v937.a), u188("c"), u40("\a[accent]\f<bars>  \rHotkeys"))

					local n9 = 1.3
					local n10 = 0
					local v942 = 19 * u187()

					for _, v in next, v934 do
						v.name = u40.upper(v.name, true)
						v.value = v.value

						local v945 = v35.measure_text(t61.font.content, u188(), v.name)
						local v946 = v35.measure_text(t61.font.content, u188(), v.value)
						local v947 = v945.x + v946.x + 20 * u187()

						t61:box(v939 + vector(0, v942 * n9 - 1 * u187()), vector(v938.x, 16 * u187()), color(20, 76.5), v.alpha * v936, 4 * u187())
						v35.text(t61.font.content, v939 + vector(5 * u187(), v942 * n9 + 1 * u187()), color(200, v.alpha * v936), u188(), v.name)
						v35.text(t61.font.content, v939 + vector(v938.x - v946.x - 5 * u187(), v942 * n9 + 1 * u187()), color(200, v.alpha * v936 * 0.4), u188(), v.value)

						if n10 < v947 and v947 > 95 * u187() then
							n10 = v947
						end

						n9 = n9 + v.alpha * v936 / 255
					end

					n8 = v38.floor(u179("keybinds_width", v38.max(n10, 95 * u187())) + 0.5)
					v202:update(v938)

					return
				end
			end)

			local v208 = t15.features.widgets:switch("\v\f<user>   \rSpectators")

			u47.new("spectators", v208, t18.features.visual)

			local v209 = v192("spectators", vector(300, v18.y / 5))
			local t71 = {}

			local function v211()
				-- upvalues: u40 (ref), t71 (copy), smoothy (copy), v38 (copy), v39 (copy)
				local u948 = false
				local t72 = {}
				local v950 = entity.get_local_player()

				if v950 then
					entity.get_players(false, false, function(p253)
						-- upvalues: u40 (ref), t71 (copy), smoothy (copy), v950 (copy), u948 (ref), v38 (copy), v39 (copy), t72 (copy)
						local v1933 = p253:get_player_info()

						if v1933 then
							local v1934 = u40.limit(p253:get_name(), 17)
							local v1935 = u40.format("%s&%s&%s", v1934, v1933.steamid64, p253:get_index())

							t71[v1935] = t71[v1935] or {
								alpha = 0,
								smoothy = smoothy.new(0),
								name = v1934,
								player = p253
							}
							t71[v1935].player = p253

							local v1936 = p253.m_hObserverTarget == (v950:is_alive() and v950 or v950.m_hObserverTarget)

							if v1936 then
								u948 = true
							end

							t71[v1935].alpha = v38.clamp(t71[v1935].smoothy(0.05, v1936 and 275 or -25), 0, 255)

							if t71[v1935].alpha > 1 then
								v39.insert(t72, 1, t71[v1935])
							end

							return
						end
					end)

					return u948, t72
				end

				return u948, t72
			end

			local n11 = 95
			local v213 = v35.load_image("\255\216\255\224\000\016JFIF\000\001\001\000\000\001\000\001\000\000\255\254\000;CREATOR: gd-jpeg v1.0 (using IJG JPEG v62), quality = 80\n\255\219\000C\000\006\004\005\006\005\004\006\006\005\006\a\a\006\b\n\016\n\n\t\t\n\020\014\015\f\016\023\020\024\024\023\020\022\022\026\029%\031\026\027#\028\022\022 , #&')*)\025\031-0-(0%()(\255\219\000C\001\a\a\a\n\b\n\019\n\n\019(\026\022\026((((((((((((((((((((((((((((((((((((((((((((((((((\255\192\000\017\b\000\184\000\184\003\001\"\000\002\017\001\003\017\001\255\196\000\031\000\000\001\005\001\001\001\001\001\001\000\000\000\000\000\000\000\000\001\002\003\004\005\006\a\b\t\n\v\255\196\000\181\016\000\002\001\003\003\002\004\003\005\005\004\004\000\000\001}\001\002\003\000\004\017\005\018!1A\006\019Qa\a\"q\0202\129\145\161\b#B\177\193\021R\209\240$3br\130\t\n\022\023\024\025\026%&'()*456789:CDEFGHIJSTUVWXYZcdefghijstuvwxyz\131\132\133\134\135\136\137\138\146\147\148\149\150\151\152\153\154\162\163\164\165\166\167\168\169\170\178\179\180\181\182\183\184\185\186\194\195\196\197\198\199\200\201\202\210\211\212\213\214\215\216\217\218\225\226\227\228\229\230\231\232\233\234\241\242\243\244\245\246\247\248\249\250\255\196\000\031\001\000\003\001\001\001\001\001\001\001\001\001\000\000\000\000\000\000\001\002\003\004\005\006\a\b\t\n\v\255\196\000\181\017\000\002\001\002\004\004\003\004\a\005\004\004\000\001\002w\000\001\002\003\017\004\005!1\006\018AQ\aaq\019\"2\129\b\020B\145\161\177\193\t#3R\240\021br\209\n\022$4\225%\241\023\024\025\026&'()*56789:CDEFGHIJSTUVWXYZcdefghijstuvwxyz\130\131\132\133\134\135\136\137\138\146\147\148\149\150\151\152\153\154\162\163\164\165\166\167\168\169\170\178\179\180\181\182\183\184\185\186\194\195\196\197\198\199\200\201\202\210\211\212\213\214\215\216\217\218\226\227\228\229\230\231\232\233\234\242\243\244\245\246\247\248\249\250\255\218\000\f\003\001\000\002\017\003\017\000?\000\241]F\246\238\029B\230(ng\1424\149\149Ud \000\t\247\170\223\2187\223\243\251s\255\000\127[\252h\213\191\228+{\255\000]\159\255\000B5V\128-\127h\223\127\207\237\207\253\253o\241\163\251F\251\254\127n\127\239\235\127\141U\162\128-\127h\223\127\207\237\207\253\253o\241\163\251F\251\254\127n\127\239\235\127\141U\162\128-\127h\223\127\207\237\207\253\253o\241\163\251F\251\254\127n\127\239\235\127\141U\162\128-\127h\223\127\207\237\207\253\253o\241\163\251F\251\254\127n\127\239\235\127\141U\162\128-\127h\223\127\207\237\207\253\253o\241\163\251F\251\254\127n\127\239\235\127\141U\162\128-\127h\223\127\207\237\207\253\253o\241\163\251F\251\254\127n\127\239\235\127\141U\162\128-\127h\223\127\207\237\207\253\253o\241\163\251F\251\254\127n\127\239\235\127\141U\162\128-\127h\223\127\207\237\207\253\253o\241\163\251F\251\254\127n\127\239\235\127\141U\162\128-\127h\223\127\207\237\207\253\253o\241\163\251F\251\254\127n\127\239\235\127\141U\162\128-\127h\223\127\207\237\207\253\253o\241\163\251F\251\254\127n\127\239\235\127\141U\162\1284\244\235\219\185\181\vh\166\185\158H\222UVV\144\144A#\222\138\173\164\255\000\200V\203\254\187'\254\132(\160\003V\255\000\144\173\239\253v\127\253\b\213Z\181\171\127\200V\247\254\187?\254\132j\173\000\020QE\000\020QE\000\020QE\000\020QE\000\020QE\000\020QE\000\020QE\000\020QE\000\020QE\000\020QE\000Z\210\127\228+e\255\000]\147\255\000B\020Q\164\255\000\200V\203\254\187'\254\132(\160\003V\255\000\144\173\239\253v\127\253\b\213Z\181\171\127\200V\247\254\187?\254\132j\173\000\020QE\000\020QE\000\020QE\000\020Q[^\020\240\190\175\226\173DYh\150\143;\140\025\028\240\145\015Vn\195\245=\179@\024\180W\210\030\025\248\001\166A\018I\226=Fk\187\140d\197k\136\227\a\184\220Af\250\241]j\252\028\240*\168\aD,GRn\231\201\255\000\199\232\003\228*+\234\rs\224/\134\239#'J\185\189\211\166\199\203\243\t\147\241V\228\254\004W\137\248\247\225\190\187\224\198\243ob\023:q8[\2002S=\131\feO\215\143Bh\003\139\162\138(\000\162\138(\000\162\138(\000\162\138(\002\214\147\255\000![/\250\236\159\250\016\162\141'\254B\182_\245\217?\244!E\000\026\183\252\133o\127\235\179\255\000\232F\170\213\173[\254B\183\191\245\217\255\000\244#Uh\000\162\138(\000\162\138(\000\162\138(\003o\193\158\028\187\241_\136\2374\155\031\149\230l\188\132dD\131\150c\244\253O\021\246W\132\1887\167xWE\135M\210a\t\018\000]\200\027\229|`\179\030\228\227\250\014+\202\255\000f\029\005-\244\029G\\\145?\127w/\217\227'\180h\0018\250\177\255\000\199k\219h\000\162\188S\227\127\197+\191\015\222\157\003\195\142\145\223\132\rsr@c\b#!T\127{\a9#\128x\231\167\128\220x\147\\\184\156\207>\177\168\188\196\231{\\\1859\250\230\128>\233\168\238`\138\234\222K{\152\163\154\tT\171\199\"\130\172\b\193\004w\021\243/\195\015\140z\158\149\127\r\143\138.d\191\210\164!L\242\146\210\192zn-\213\151\212\028\159OC\244\234:\186+\163\006R\003\002\167 \142\185\006\128>K\248\215\240\255\000\254\016\237e.\180\229'E\189c\229\003\146a~\241\147\233\220\019\219\233\154\243j\251K\226\174\130\158\"\240\030\173dWt\201\017\158\003\220H\131r\227\2118#\232k\226\218\000(\162\138\000(\162\138\000(\162\138\000\181\164\255\000\200V\203\254\187'\254\132(\163I\255\000\144\173\151\253vO\253\bQ@\006\173\255\000![\223\250\236\255\000\250\017\170\181kV\255\000\144\173\239\253v\127\253\b\213Z\000(\162\138\000(\162\138\000(\162\138\000\250\227\224=\197\180_\n\180Uy\161G&r\192\176\a>{\245\231\211\021\223}\182\215\254~a\255\000\190\199\248\215\1934P\006\191\140/\155R\241^\177z\237\188\207w+\131\156\140\0228\000\250c\138\200\162\138\000+\237?\1333O?\195\143\015=\206|\207\177\162\228\245*\006\020\254@W\202\031\015\252)w\227\031\018\219\233\150\160\172D\239\184\152\014!\140\017\185\190\189\128\238k\237K\027Xll\173\237-P$\016F\177F\131\162\162\128\000\253(\002VP\202U\128ea\130\015 \138\248\n\190\228\241\174\174\154\023\132\181}I\216)\183\182vRx\203\227\b?\022*+\225\186\000(\162\138\000(\162\138\000(\162\138\000\181\164\255\000\200V\203\254\187'\254\132(\163I\255\000\144\173\151\253vO\253\bQ@\006\173\255\000![\223\250\236\255\000\250\017\170\181kV\255\000\144\173\239\253v\127\253\b\213Z\000(\162\138\000(\162\138\000(\162\138\000(\162\138\000*[[y\174\238\161\183\181\141\229\184\149\196q\198\131%\216\158\000\029\206ME_C\254\206\222\001\242\"_\021\234\208\254\246E\"\1947\028\170\247\151\030\167\160\246\201\238(\003\208\190\020x&\031\005xm p\143\169\220bK\185W\156\1908P\127\186\185\199\191'\189v\180W\154\252m\241\240\240\142\135\246=>O\248\157_!X\177\214\020\232d>\253\135\191=\141\000y\207\237\021\227\164\212\175\a\1344\2017[Z\201\186\238E<<\1638A\236\185\231\223\253\218\241\026Vb\204Y\137fc\146O$\159SI@\005\020Q@\005\020Q@\005\020Q@\022\180\159\249\n\217\127\215d\255\000\208\133\020i?\242\021\178\255\000\174\201\255\000\161\n(\000\213\191\228+{\255\000]\159\255\000B5V\173j\223\242\021\189\255\000\174\207\255\000\161\026\171@\005\020Q@\005\020Q@\005\020Q@\005\020Q@\029\015\195\237\r|I\227M#I\147>M\196\195\205\003\169\141Ag\000\250\237S_m\197\026C\018G\018\004\141\020*\170\140\005\000`\000;\fW\201_\179\216\255\000\139\165\166\255\000\215)\191\244[W\214\244\001\141\227\015\017Y\248W\195\215Z\182\160s\020+\242\16082\185\225T{\147\249\014{W\197\222'\215o|I\174]j\186\148\155\238.\031q\0038A\208*\142\192\014+\221\127j\155\183M/\195\214a\136If\154b\189\137EP\t\255\000\190\205|\237@\005\020Q@\005\020Q@\005\020Q@\005\020Q@\022\180\159\249\n\217\127\215d\255\000\208\133\020i?\242\021\178\255\000\174\201\255\000\161\n(\000\213\191\228+{\255\000]\159\255\000B5V\173j\223\242\021\189\255\000\174\207\255\000\161\026\171@\005\020Q@\005\020Q@\005\020Q@\005\020Q@\029\215\193MZ\199E\248\133c{\170\220\199mh\145\204\026Y8\000\152\200\031\169\175\165\127\225e\2487\254\134\027\031\251\232\255\000\133|aE\000{?\237\027\226m\027\196_\240\143\127bj0\222\249\031h\243|\178N\205\222V\220\241\254\201\175\024\162\138\000(\162\138\000(\162\138\000(\162\138\000(\162\138\000\181\164\255\000\200V\203\254\187'\254\132(\163I\255\000\144\173\151\253vO\253\bQ@\006\173\255\000![\223\250\236\255\000\250\017\170\181kV\255\000\144\173\239\253v\127\253\b\213Z\000(\162\138\000(\162\138\000(\162\138\000(\162\138\000\244?\128pCs\2417O\138\230(\229\140\1991)\"\134\a\247d\142+\234\191\236]+\254\129\150?\248\014\191\225_'\252\f\191\179\211~$X\\\2347v\246\150\203\028\193\165\158A\026\002c \002\196\1289\175\168?\2255\240\183\253\f\186'\254\f\"\255\000\226\168\003\198?j++K?\248F~\201m\f\027\190\213\187\203@\187\191\213c8\028\245\175\b\175o\253\165\245\173+X\255\000\132s\251#S\177\191\242\190\211\230}\150\225e\217\159+\027\182\147\140\224\245\244\175\016\160\002\138(\160\002\138(\160\002\138(\160\002\138(\160\vZO\252\133l\191\235\178\127\232B\1384\159\249\n\217\127\215d\255\000\208\133\020\000j\223\242\021\189\255\000\174\207\255\000\161\026\171V\181o\249\n\222\255\000\215g\255\000\208\141U\160\002\138(\160\002\138(\160\002\138(\160\002\138(\160\002\138(\160\002\138(\160\002\138(\160\002\138(\160\002\138(\160\002\138(\160\vZO\252\133l\191\235\178\127\232B\1384\159\249\n\217\127\215d\255\000\208\133\020\000j\223\242\021\189\255\000\174\207\255\000\161\026\171V\181o\249\n\222\255\000\215g\255\000\208\141U\160\002\138(\160\002\138(\160\002\138(\160\002\138(\160\002\138(\160\002\138(\160\002\138(\160\002\138(\160\002\138(\160\002\138(\160\vZO\252\133l\191\235\178\127\232B\1384\159\249\n\217\127\215d\255\000\208\133\020\001gQ\178\187\155P\185\150\027i\228\141\229fVX\201\004\018}\170\183\246u\247\252\249\\\255\000\223\166\255\000\n(\160\003\251:\251\254|\174\127\239\211\127\133\031\217\215\223\243\229s\255\000~\155\252(\162\128\015\236\235\239\249\242\185\255\000\191M\254\020\127g_\127\207\149\207\253\250o\240\162\138\000?\179\175\191\231\202\231\254\2537\248Q\253\157}\255\000>W?\247\233\191\194\138(\000\254\206\190\255\000\159+\159\251\244\223\225G\246u\247\252\249\\\255\000\223\166\255\000\n(\160\003\251:\251\254|\174\127\239\211\127\133\031\217\215\223\243\229s\255\000~\155\252(\162\128\015\236\235\239\249\242\185\255\000\191M\254\020\127g_\127\207\149\207\253\250o\240\162\138\000?\179\175\191\231\202\231\254\2537\248Q\253\157}\255\000>W?\247\233\191\194\138(\000\254\206\190\255\000\159+\159\251\244\223\225G\246u\247\252\249\\\255\000\223\166\255\000\n(\160\003\251:\251\254|\174\127\239\211\127\133\031\217\215\223\243\229s\255\000~\155\252(\162\128\015\236\235\239\249\242\185\255\000\191M\254\020\127g_\127\207\149\207\253\250o\240\162\138\000\179\167Y]\195\168[K5\180\241\198\146\17134d\000\001\030\212QE\000\127\255\217", vector(30, 30))

			events.render(function()
				-- upvalues: v211 (copy), v208 (copy), u179 (ref), u183 (ref), n11 (ref), u187 (ref), v209 (copy), t61 (copy), v35 (copy), u188 (ref), u40 (ref), v213 (copy), v38 (copy)
				local v951, v952 = v211()
				local v953 = v208.value and (v951 or not (ui.get_alpha() <= 0))
				local v954 = u179("spectators_alpha", v953, 0.05)

				if v953 or not (v954 < 0.05) then
					local v955 = u183():alpha_modulate(255 * v954)
					local v956 = vector(n11, 23 * u187())
					local v957 = v209:get_position()

					t61:new(v957, v955, v956.x)
					v35.text(t61.font.content, v957 + vector(v956.x / 2, 9 * u187()), color(222, v955.a), u188("c"), u40("\a[accent]\f<eye>  \rSpectators"))

					local n12 = 1.3
					local n13 = 0
					local v960 = 19 * u187()

					for _, v in next, v952 do
						local v963 = v35.measure_text(t61.font.content, u188(), v.name).x + 25 * u187()

						t61:box(v957 + vector(17 * u187(), v960 * n12 - 1 * u187()), vector(v956.x - 17 * u187(), 16 * u187()), color(20, 76.5), v.alpha * v954, 4 * u187())
						v35.text(t61.font.content, v957 + vector(22 * u187(), v960 * n12 + 1 * u187()), color(200, v.alpha * v954), u188(), v.name)

						local v964 = v.player:get_steam_avatar()

						if not v964 or v964.resolution < 1 then
							v964 = v213
						end

						v35.texture(v964, v957 + vector(0, v960 * n12), vector(13, 13) * u187(), color(255, v.alpha * v954), 10 * u187())

						if n13 < v963 and v963 > 95 * u187() then
							n13 = v963
						end

						n12 = n12 + v.alpha * v954 / 255
					end

					n11 = v38.floor(u179("spectators_width", v38.max(n13, 95 * u187())) + 0.5)
					v209:update(v956)

					return
				end
			end)

			function v214(p254)
				-- upvalues: u40 (ref), s1 (copy)
				print_raw(u40("\a[accent]" .. s1 .. "\a[inactive] › \r" .. p254))
			end

			t5 = {}

			local v215 = t15.features.widgets:switch("\v\f<bell>   \rNotifications", false, nil, function(p255)
				local t73 = {
					render = p255:listable("\n", {
						[1] = "\v\f<screencast>   \rScreen",
						[2] = "\v\f<fingerprint>    \rDebug",
						[3] = "\v\f<terminal>   \rConsole"
					}),
					offset = p255:slider(" \a[grey]\f<angle-right>    \rOffset", 17, 100, 40, 1, "%")
				}

				t73.offset:depend({
					[1] = nil,
					[2] = 1,
					[1] = t73.render
				})

				return t73, true
			end)

			u47.new("notifications", v215, t18.features.visual)

			local t74 = {}
			local n14 = 6
			local n15 = 5

			local function v219(p256, p257, p258)
				-- upvalues: v35 (copy), t61 (copy), u188 (ref), u187 (ref)
				local v971 = v35.measure_text(t61.font.content, u188(), p257)
				local v972 = vector(v971.x + 10 * u187(), v971.y + 6 * u187())

				t61:new(p256 - v972 / 2, p258, p257)
			end

			t5.center = v219

			function t5.screen(p259)
				-- upvalues: v215 (copy), v39 (copy), t74 (copy), smoothy (copy)
				if v215.value and v215.render:get(1) then
					v39.insert(t74, 1, {
						alpha = 0,
						func = p259,
						smoothy = smoothy.new(0),
						realtime = globals.realtime
					})

					return t74[1]
				end
			end

			events.render(function()
				-- upvalues: v215 (copy), u179 (ref), v38 (copy), v18 (copy), t74 (copy), n15 (copy), u187 (ref), n14 (copy), v39 (copy)
				local v974 = entity.get_local_player()
				local v975 = v215.value and (v215.render:get(1) and v974 ~= nil)
				local v976 = u179("notifications_alpha", v975)

				if v975 or not (v976 < 0.05) then
					local v977 = v38.floor(u179("notifications_offset", v215.offset.value) + 0.5)
					local v978 = vector(v18.x / 2, v18.y / (1 + v977 * 0.01))
					local n16 = 0

					for k, v in next, t74 do
						local v982 = not (v.realtime + n15 <= globals.realtime)

						v:func(vector(v978.x, v978.y + 27 * u187() * n16))
						v.alpha = v38.clamp(v.smoothy(0.05, v982 and 275 or -25), 0, 255) * v976
						n16 = n16 + v.alpha / 255

						if #t74 > n14 then
							v39.remove(t74)
						end

						if v982 == false and v.alpha < 1 then
							v39.remove(t74, k)
						end
					end

					return
				end
			end)

			local function v220(p260, p261, p262)
				-- upvalues: pui (copy), u183 (ref), u40 (ref)
				local v986 = "\a[inactive]" .. p261

				pui.colors.active = p260 or u183()

				for k, v in next, p262 do
					v986 = v986:gsub(("{%s}"):format(k), ("\a[active]%s\a[inactive]"):format(v))
				end

				return u40(v986)
			end

			t5.build = v220

			function t5.print(p263)
				-- upvalues: v215 (copy), v214 (copy)
				if v215.value then
					if v215.render:get(3) then
						v214(p263)
					end

					if v215.render:get(2) then
						print_dev(p263)
					end

					return
				end
			end

			local t75 = {
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

			local function v222(p264)
				-- upvalues: u183 (ref)
				local t76 = {
					["nil"] = u183(),
					spread = color("edc477"),
					correction = color("ff5d52"),
					misprediction = color("ff5d52"),
					["backtrack failure"] = color("7a9ffa"),
					["prediction error"] = color("ff5d52"),
					death = color("8c8c8c"),
					["player death"] = color("8c8c8c"),
					["unregistered shot"] = color("8c8c8c")
				}

				return t76[p264] or t76["nil"]
			end

			t5.state_colors = v222

			local function v223(p265)
				-- upvalues: t75 (copy), v38 (copy), v39 (copy), u40 (ref)
				local t77 = {}
				local v994 = t75[p265.hitgroup] or "?"
				local v995 = t75[p265.wanted_hitgroup] or "?"

				if v38.abs(p265.backtrack) > 0 then
					v39.insert(t77, "history: {backtrack}t")
				end

				local v996 = v994 ~= v995
				local v997 = p265.damage ~= p265.wanted_damage

				if v996 or v997 then
					local s12 = "wanted: "
					local v999 = false

					if v996 then
						s12 = s12 .. "{wanted_hitgroup}"
						v999 = true
					end

					if v997 then
						s12 = s12 .. (v999 and ":{wanted_damage}" or "{wanted_damage} dmg")
					end

					v39.insert(t77, s12)
				end

				if not (#t77 > 0) then
					return ""
				end

				return u40.format(" › %s ‹", v39.concat(t77, " · "))
			end

			events.aim_ack(function(p266)
				-- upvalues: u40 (ref), v38 (copy), t75 (copy), v222 (copy), v220 (copy), v223 (copy), t5 (ref), v219 (copy)
				local v1001 = entity.get_local_player()

				if p266.target and (p266.target:is_player() and v1001) then
					local v1002 = v1001:get_player_weapon()

					if v1002 == nil or v1002:get_name() ~= "Zeus x27" or p266.state ~= nil then
						local v1003 = u40.limit(p266.target:get_name(), 17)
						local v1004 = v38.floor(p266.hitchance + 0.5)
						local v1005 = t75[p266.hitgroup] or "?"
						local v1006 = t75[p266.wanted_hitgroup] or "?"
						local v1007 = v222(tostring(p266.state))
						local v1008 = v220(v1007, "Killed {name} in {hitgroup}" .. v223(p266), {
							name = v1003,
							hitgroup = v1005,
							backtrack = p266.backtrack,
							wanted_damage = p266.wanted_damage,
							wanted_hitgroup = v1006
						})
						local v1009 = v220(v1007, "Hit {name} in {hitgroup} for {damage} damage" .. v223(p266), {
							name = v1003,
							damage = p266.damage,
							hitgroup = v1005,
							backtrack = p266.backtrack,
							wanted_damage = p266.wanted_damage,
							wanted_hitgroup = v1006
						})
						local v1010 = v220(v1007, "Missed in {name}'s {wanted_hitgroup} due to {reason}" .. (p266.state == "spread" and " › hitchance {hitchance}% ‹" or ""), {
							name = v1003,
							reason = p266.state,
							hitchance = v1004,
							wanted_hitgroup = v1006
						})
						local v1011 = p266.state == nil and (p266.target:is_alive() and v1009 or v1008) or v1010

						t5.print(v1011)

						local v1012 = v220(v1007, "Killed {name} in {hitgroup}", {
							name = v1003,
							hitgroup = v1005,
							backtrack = p266.backtrack,
							wanted_damage = p266.wanted_damage,
							wanted_hitgroup = v1006
						})
						local v1013 = v220(v1007, "Hit {name} in {hitgroup} for {damage} damage", {
							name = v1003,
							damage = p266.damage,
							hitgroup = v1005,
							backtrack = p266.backtrack,
							wanted_damage = p266.wanted_damage,
							wanted_hitgroup = v1006
						})
						local v1014 = v220(v1007, "Missed in {name}'s {wanted_hitgroup} due to {reason}", {
							name = v1003,
							reason = p266.state,
							hitchance = v1004,
							wanted_hitgroup = v1006
						})
						local v1015 = p266.state == nil and (p266.target:is_alive() and v1013 or v1012) or v1014

						t5.screen(function(p267, p268)
							-- upvalues: v219 (copy), v1015 (copy), v1007 (copy)
							v219(p268, v1015, v1007:alpha_modulate(p267.alpha))
						end)

						return
					end

					return
				end
			end)
			events.player_death(function(p269)
				-- upvalues: u40 (ref), v222 (copy), v220 (copy), t5 (ref), v219 (copy)
				local v1017 = entity.get_local_player()
				local v1018 = entity.get(p269.userid, true)
				local v1019 = entity.get(p269.attacker, true)

				if v1017 == v1018 and v1019 then
					local v1020 = u40.limit(v1019:get_name(), 17)
					local v1021 = v222()
					local v1022 = v220(v1021, v1017 == v1019 and "You're suicidal" or "Killed by {name}", {
						name = v1020,
						reason = p269.state,
						hitchance = hitchance,
						wanted_hitgroup = w_hitgroup
					})

					t5.print(v1022)
					t5.screen(function(p270, p271)
						-- upvalues: v219 (copy), v1022 (copy), v1021 (copy)
						v219(p271, v1022, v1021:alpha_modulate(p270.alpha))
					end)

					return
				end
			end)

			local t78 = {
				taser = "Tased",
				inferno = "Burned",
				knife = "Knifed",
				hegrenade = "Naded"
			}
			local t79 = {
				taser = "Tased",
				inferno = "Burned",
				knife = "Stabbed",
				hegrenade = "Exploded"
			}
			local t80 = {}

			local function v227(p272, p273)
				-- upvalues: u40 (ref), t80 (copy), t5 (ref), v222 (copy), v220 (copy), v219 (copy)
				local v1025 = p273:get_index()
				local v1026 = u40.limit(p273:get_name(), 17)
				local v1027 = u40.format("key:%s:%s", v1025, v1026)

				t80[v1027] = t80[v1027] or {
					damage = 0,
					text = "",
					notify = t5.screen(function()
					end)
				}

				if t80[v1027].notify ~= nil then
					t80[v1027].damage = t80[v1027].damage + p272.dmg_health

					local v1028 = v222()
					local v1029 = v220(v1028, p272.health > 0 and "{name} was burned for {damage} hp" or "{name} burned out", {
						name = v1026,
						damage = t80[v1027].damage
					})

					if p272.health <= 0 then
						t80[v1027].damage = 0
					end

					t80[v1027].text = v1029
					t80[v1027].notify.realtime = globals.realtime
					t80[v1027].notify.func = function(p274, p275)
						-- upvalues: v219 (copy), v1029 (copy), v1028 (copy)
						v219(p275, v1029, v1028:alpha_modulate(p274.alpha))
					end

					return
				end
			end

			events.render(function()
				-- upvalues: t80 (copy), n15 (copy), t5 (ref)
				for k, v in next, t80 do
					if v.notify ~= nil and v.notify.realtime + n15 < globals.realtime then
						t5.print(v.text)
						t80[k] = nil
					end
				end
			end)
			events.player_hurt(function(p276)
				-- upvalues: t78 (copy), t79 (copy), v227 (copy), u40 (ref), v222 (copy), v220 (copy), t5 (ref), v219 (copy)
				local v1033 = entity.get_local_player()
				local v1034 = entity.get(p276.userid, true)
				local v1035 = entity.get(p276.attacker, true)
				local v1036 = t78[p276.weapon]
				local v1037 = t79[p276.weapon]

				if v1037 ~= nil and (v1036 ~= nil and v1033 ~= nil and v1033 == v1035) then
					if p276.weapon ~= "inferno" then
						local v1038 = u40.limit(v1034:get_name(), 17)
						local dmg_health = p276.dmg_health
						local v1040 = v222()
						local v1041 = v220(v1040, v1037 .. " {name}", {
							name = v1038
						})
						local v1042 = v220(v1040, v1036 .. " {name} for {damage} damage", {
							name = v1038,
							damage = dmg_health
						})
						local v1043 = p276.health > 0 and v1042 or v1041

						t5.print(v1043)
						t5.screen(function(p277, p278)
							-- upvalues: v219 (copy), v1043 (copy), v1040 (copy)
							v219(p278, v1043, v1040:alpha_modulate(p277.alpha))
						end)

						return
					end

					return v227(p276, v1034, v1035)
				end
			end)
			events.round_start(function()
				-- upvalues: v215 (copy)
				if v215.value and v215.render:get(2) then
					print_raw("")
				end
			end)
			t81 = {}

			local v229 = t15.features.widgets:switch("\v\f<code>  \rDebug panel", false, nil, function(p279)
				return {
					features = p279:listable("", {
						[1] = "\v\f<user>   \rTarget",
						[2] = "\v\f<triangle>   \rExploit",
						[3] = "\v\f<rotate>   \rAnti-Aim",
						[4] = "\v\f<gauge-simple-low>   \rSlow down",
						[5] = "\v\f<layer-group>   \rAnti-Brute"
					})
				}, true
			end)

			u47.new("debug_panel", v229, t18.features.visual)

			local v230 = v192("debug_panel", vector(500, v18.y / 5))

			local function v231(p280, p281, ...)
				-- upvalues: v35 (copy)
				v35.rect(p280, p280 + p281, ...)
			end

			local t82 = {}

			local function v233(p282)
				-- upvalues: v39 (copy), t82 (copy), smoothy (copy), v38 (copy)
				v39.insert(t82, setmetatable(p282, {
					__index = {
						alpha = 0,
						smoothy = smoothy.new(0),
						size = vector(),
						get = function()
							return true
						end,
						update = function(p283)
							-- upvalues: v38 (copy)
							p283.alpha = v38.clamp(p283.smoothy(0.05, p283:get() and 275 or -25), 0, 255)
						end,
						paint_title = function()
						end,
						paint_value = function()
						end
					}
				}))
			end

			v233({
				get_target = function(_)
					return entity.get_threat()
				end,
				get = function(p285)
					-- upvalues: v229 (copy)
					return v229.features:get(1) and (p285:get_target() or not (ui.get_alpha() <= 0))
				end,
				paint_title = function(p286, p287)
					-- upvalues: v35 (copy), t61 (copy), u188 (ref)
					local s13 = "Target"

					p286.size = v35.measure_text(t61.font.content, u188(), s13)
					v35.text(t61.font.content, p287, color(200, p286.alpha), u188(), s13)
				end,
				paint_value = function(p288, p289)
					-- upvalues: u40 (ref), v35 (copy), t61 (copy), u188 (ref)
					local v1055 = p288:get_target()
					local v1056 = u40.limit(v1055 and v1055:get_name() or "none", 9)
					local v1057 = v35.measure_text(t61.font.content, u188(), v1056)

					v35.text(t61.font.content, vector(p289.x - v1057.x, p289.y), color(200, p288.alpha * 0.4), u188(), v1056)
				end
			})
			v233({
				get_value = function()
					-- upvalues: u179 (ref), t20 (copy)
					local v1058 = u179("debug_def_act", {
						[1] = nil,
						[2] = 0,
						[3] = 1,
						[1] = t20:get() and 1.2 or 0
					})
					local v1059 = u179("debug_dt_c", rage.exploit:get(), 0.08)

					return v1059 == 1 and v1059 - v1058 or v1059
				end,
				get_state = function()
					-- upvalues: t14 (copy)
					if not t14.double_tap:get() or t14.double_tap:get_override() ~= nil then
						if not t14.hide_shots:get() and not t14.hide_shots:get_override() then
							return "Off"
						end

						return "OS"
					end

					return "DT"
				end,
				get = function(p290)
					-- upvalues: v229 (copy)
					return v229.features:get(2) and (p290:get_state() ~= "Off" or not (ui.get_alpha() <= 0))
				end,
				y = smoothy.new(0),
				paint_title = function(p291, p292)
					-- upvalues: v35 (copy), t61 (copy), u188 (ref), v38 (copy), u187 (ref)
					local s14 = "Exploit"

					p291.size = v35.measure_text(t61.font.content, u188(), s14)
					p291.size.y = v38.clamp(p291.y(0.05, p291:get_state() == "Off" and p291.size.y - 1 or 23 * u187()), p291.size.y, 20 * u187())
					v35.text(t61.font.content, p292, color(200, p291.alpha), u188(), s14)
				end,
				paint_value = function(p293, p294)
					-- upvalues: v35 (copy), t61 (copy), u188 (ref), v231 (copy), u187 (ref)
					local v1066 = p293:get_state()
					local v1067 = p293:get_value()
					local v1068 = v35.measure_text(t61.font.content, u188(), v1066)

					v35.text(t61.font.content, vector(p294.x - v1068.x, p294.y), color(200, p293.alpha * 0.4), u188(), v1066)

					if v1067 > 0.05 then
						v231(p294 - vector(p293.size.x, -16 * u187()), vector(p293.size.x * v1067, 2 * u187()), color(200, p293.alpha * 0.4), 2 * u187())
					end
				end
			})
			v233({
				get_value = function()
					local v1069 = entity.get_local_player()

					return v1069 and (v1069:is_alive() and v1069.m_flVelocityModifier) or 1
				end,
				get = function(p295)
					-- upvalues: v229 (copy)
					return v229.features:get(4) and (not (p295:get_value() >= 1) or not (ui.get_alpha() <= 0))
				end,
				paint_title = function(p296, p297)
					-- upvalues: v35 (copy), t61 (copy), u188 (ref), u187 (ref)
					local s15 = "Slow down"

					p296.size = v35.measure_text(t61.font.content, u188(), s15)
					p296.size.y = 20 * u187()
					v35.text(t61.font.content, p297, color(200, p296.alpha), u188(), s15)
				end,
				paint_value = function(p298, p299)
					-- upvalues: u40 (ref), v35 (copy), t61 (copy), u188 (ref), v231 (copy), u187 (ref)
					local v1076 = p298:get_value()
					local v1077 = u40.format("%i%%", 100 * v1076)
					local v1078 = v35.measure_text(t61.font.content, u188(), v1077)

					v35.text(t61.font.content, vector(p299.x - v1078.x, p299.y), color(200, p298.alpha * 0.4), u188(), v1077)
					v231(p299 - vector(p298.size.x, -16 * u187()), vector(p298.size.x * v1076, 2 * u187()), color(200, p298.alpha * 0.4), 2 * u187())
				end
			})
			v233({
				get = function(_)
					-- upvalues: v229 (copy)
					return v229.features:get(3) and (entity.get_local_player() or not (ui.get_alpha() <= 0))
				end,
				paint_title = function(p301, p302)
					-- upvalues: v35 (copy), t61 (copy), u188 (ref)
					local s16 = "Anti-Aim"

					p301.size = v35.measure_text(t61.font.content, u188(), s16)
					v35.text(t61.font.content, p302, color(200, p301.alpha), u188(), s16)
				end,
				paint_value = function(p303, p304)
					-- upvalues: t4 (ref), v35 (copy), t61 (copy), u188 (ref)
					local v1085 = t4.state or "none"
					local v1086 = v35.measure_text(t61.font.content, u188(), v1085)

					v35.text(t61.font.content, vector(p304.x - v1086.x, p304.y), color(200, p303.alpha * 0.4), u188(), v1085)
				end
			})

			local function v234()
				-- upvalues: t82 (copy)
				for _, v in next, t82 do
					if v:get() then
						return true
					end
				end

				return false
			end

			events.render(v43(v229, function()
				-- upvalues: v229 (copy), v234 (copy), v38 (copy), u179 (ref), u183 (ref), u187 (ref), v230 (copy), t61 (copy), v35 (copy), u188 (ref), u40 (ref), t82 (copy)
				local v1089 = v229.value and (v234() or not (ui.get_alpha() <= 0))
				local v1090 = v38.clamp(u179("debug_panel_alpha", v1089 and 265 or -10, 0.05), 0, 255)

				if v1089 or not (v1090 < 1) then
					local v1091 = u183():alpha_modulate(v1090)
					local v1092 = 110 * u187()
					local v1093 = vector(v1092, 23 * u187())
					local v1094 = v230:get_position()

					t61:new(v1094, v1091, v1093.x)
					v35.text(t61.font.content, v1094 + vector(v1093.x / 2, 9 * u187()), color(210, v1091.a), u188("c"), u40("\a[accent]\f<code>  \rDebug"))
					v1094.y = v1094.y + v1093.y

					local v1095 = vector(0, 4) * u187()
					local v1096 = vector(5, 4) * u187()
					local n17 = 0

					for _, v in next, t82 do
						v:update()
						v.size.x = v1092
						v.alpha = v.alpha * (v1090 / 255)

						if v.alpha > 0 then
							local v1100 = vector(v1094.x, v1094.y + n17)

							t61:box(v1100, vector(v.size.x, v.size.y + 1 + v1096.y * 2), color(20, 76.5), v.alpha * (v1090 / 255), 4 * u187())

							local size = v.size

							v.size.x = v.size.x - 10 * u187()
							v:paint_value(v1100 + v1096 + vector(v.size.x, 0))
							v.size = size
							v:paint_title(v1100 + v1096)
							n17 = n17 + (v.size.y + v1095.y + v1096.y * 2) * (v.alpha / 255)
						end
					end

					v230:update(v1093)

					return
				end
			end, t1.PRO, t1.TRIAL))

			function t81.create(_, ...)
				-- upvalues: v233 (copy)
				v233(...)
			end

			local function v235(p306)
				-- upvalues: v38 (copy)
				local v1104 = rage.antiaim:get_max_desync()
				local v1105 = v38.min(v38.abs(v38.normalize_yaw(rage.antiaim:get_rotation(true) - rage.antiaim:get_rotation())), v1104)

				return p306 and v1105 / v1104 or v1105
			end

			u47.new("crosshair", t15.features.indicators:switch("\v\f<triangle>    \rCrosshair", false, nil, function(p307)
				-- upvalues: u47 (ref)
				local t83 = {
					style = p307:list("", {
						[1] = "\f<star>  Star",
						[2] = "\f<moon>  Moon"
					}),
					offset = p307:slider(" \a[grey]\f<angle-right>    \rOffset", 0, 40, 20, 1, "px")
				}

				u47.set_callback_list(t83.style)

				return t83, true
			end), t18.features.visual)

			local t84 = {}
			local t85 = {
				alpha = 0,
				get = function(_)
					return true
				end,
				paint = function(_)
				end
			}

			local function v238(p310, p311)
				-- upvalues: t84 (copy), v39 (copy), t85 (copy)
				t84[p310] = {
					data = {},
					offset = p311 or 0,
					create = function(p312, p313)
						-- upvalues: v39 (copy), t85 (copy)
						v39.insert(p312.data, setmetatable(p313, {
							__index = t85
						}))
					end
				}

				return t84[p310]
			end

			events.render(function()
				-- upvalues: u47 (ref), u179 (ref), v38 (copy), u187 (ref), v18 (copy), t84 (copy), u40 (ref)
				local v1112 = entity.get_local_player()
				local v1113 = u47.get("crosshair")
				local v1114 = v1113.value and (v1112 ~= nil and v1112:is_alive())
				local v1115 = u179("crosshair_alpha", {
					[1] = nil,
					[2] = 0,
					[3] = 1,
					[1] = v1114 and 1.2 or 0
				})

				if v1114 or not (v1115 < 0.05) then
					local v1116 = u179("crosshair_scoped", {
						[1] = nil,
						[2] = 0,
						[3] = 1,
						[1] = v1112 ~= nil and v1112.m_bIsScoped and 1.2 or 0
					})
					local v1117 = v38.floor(u179("crosshair_offset", v1113.offset.value * u187()) + 0.5)
					local v1118 = v18 / 2
					local v1119 = u47.get("scope_lines")
					local v1120 = 40 * u187()
					local v1121 = v1119 ~= nil and v1119.options:get(2)
					local v1122 = vector(v1118.x, v1118.y + v1117 + (v1120 < v1117 and 0 or (v1120 - v1117) * v1116))
					local v1123 = vector(v1118.x + 30 * u187() * v1116, v1118.y + v1117)
					local v1124 = (u179("crosshair_position", v1121 and v1122 or v1123, 0.03) + 0.3):floor()
					local t86 = {
						[1] = 0,
						[2] = 0,
						[3] = 0,
						[4] = 0,
						[5] = 0
					}

					for k, v in next, t84 do
						for k2, v9 in next, v.data do
							local v1130 = v9:get() and k == v1113.style.value

							v9.alpha = u179(u40("crosshair_element(%s:%s)", k2, k), {
								[1] = nil,
								[2] = 0,
								[3] = 255,
								[1] = v1130 and 300 or -30
							}, 0.06) * v1115

							if v9.alpha > 0 then
								v9:paint(vector(v1124.x + 1, v1124.y + v.offset * u187() * t86[k]))
							end

							t86[k] = t86[k] + v9.alpha / 255
						end
					end

					return
				end
			end)

			local v239 = v238(1, 10)
			local v240 = v35.load_font("times new roman", 14, "ad")

			v239:create({
				text = gradient.text_animate("𝒆𝒗𝒂𝒍𝒂𝒕𝒆", -1, { color() }),
				paint = function(p314, p315)
					-- upvalues: u187 (ref), u183 (ref), v35 (copy), v240 (copy), u188 (ref), u179 (ref), v235 (copy)
					p315.y = p315.y - 5 * u187()

					local v1133 = u183()

					p314.text:set_colors({
						v1133,
						v1133:alpha_modulate(50)
					})
					p314.text:animate()

					local v1134 = p314.text:get_animated_text()
					local v1135 = v35.measure_text(v240, u188(), v1134)
					local v1136 = vector(p315.x - v1135.x / 2, p315.y + 8 * u187())

					v35.shadow(v1136, v1136 + vector(v1135.x, 0), v1133:alpha_modulate(p314.alpha), 40 * u187())
					v35.text(v240, vector(p315.x - v1135.x / 2, p315.y), color(255, p314.alpha), u188(), v1134)

					local v1137 = u179("star_desync", v235(true))

					if not (v1137 < 0.09) then
						local v1138 = vector(v1135.x, 1 * u187())
						local v1139 = v1133:alpha_modulate(p314.alpha)
						local v1140 = v1133:alpha_modulate(0)

						local function v1141(p316, p317, p318, p319, ...)
							-- upvalues: v35 (copy)
							v35.gradient(vector(p316, p317), vector(p316 + p318, p317 + p319), ...)
						end

						v1141(v1136.x + v1138.x / 2, v1136.y + 5 * u187(), v1138.x / 2 * v1137, 1 * u187(), v1139, v1140, v1139, v1140)
						v1141(v1136.x + v1138.x / 2, v1136.y + 5 * u187(), -(v1138.x / 2 * v1137), 1 * u187(), v1139, v1140, v1139, v1140)

						return
					end
				end
			})
			v239:create({
				get = function(_)
					-- upvalues: t14 (copy)
					return t14.double_tap:get()
				end,
				paint = function(p321, p322)
					-- upvalues: u179 (ref), t20 (copy), v38 (copy), t14 (copy), v35 (copy), u188 (ref), u187 (ref), u183 (ref)
					local v1145 = u179("star_def_dif", {
						[1] = nil,
						[2] = 0,
						[3] = 1,
						[1] = t20:get() and 1.2 or 0
					})
					local v1146 = u179("star_dt_c", rage.exploit:get(), 0.08)
					local v1147 = v38.clamp(v1146, 0.2, 1)
					local v1148 = t14.double_tap:get_override()

					if v1148 ~= nil and v1148 == false then
						v1147 = 0.2
					end

					local v1149 = v35.measure_text(2, u188(), "DT")

					v35.text(2, vector(p322.x - v1149.x / 2 - 4 * u187(), p322.y), color(222, p321.alpha * v1147), u188(), "DT")
					v35.circle_outline(vector(p322.x + 5 * u187(), p322.y + 6 * u187()), color(0, p321.alpha / 3), 3.4 * u187(), 0, 1, u187())
					v35.circle_outline(vector(p322.x + 5 * u187(), p322.y + 6 * u187()), u183():alpha_modulate(p321.alpha), 3.4 * u187(), 0, v1146 == 1 and v1146 - v1145 or v1146, u187())
				end
			})
			v239:create({
				get = function(_)
					-- upvalues: t14 (copy)
					return t14.hide_shots:get_override() or t14.hide_shots:get()
				end,
				paint = function(p324, p325)
					-- upvalues: u179 (ref), t14 (copy), v35 (copy), u188 (ref)
					local v1153 = u179("star_hs_a", t14.double_tap:get() and t14.double_tap:get_override() == nil and 0.2 or 1)
					local v1154 = v35.measure_text(2, u188(), "HS")

					v35.text(2, vector(p325.x - v1154.x / 2, p325.y), color(222, p324.alpha * v1153), u188(), "HS")
				end
			})
			v239:create({
				get = function(_)
					-- upvalues: t14 (copy)
					return t14:is_min_damage()
				end,
				paint = function(p327, p328)
					-- upvalues: v35 (copy), u188 (ref)
					local v1158 = v35.measure_text(2, u188(), "DMG")

					v35.text(2, vector(p328.x - v1158.x / 2, p328.y), color(222, p327.alpha), u188(), "DMG")
				end
			})
			v239:create({
				get = function(_)
					-- upvalues: t14 (copy)
					return t14.freestanding:get() or (t14.freestanding:get_override() or (t14.safe_points:get() == "Force" or t14.body_aim:get() == "Force"))
				end,
				paint = function(p330, p331)
					-- upvalues: pui (copy), u179 (ref), t14 (copy), u187 (ref), u40 (ref), v35 (copy), u188 (ref)
					local v1162 = color(222)
					local v1163 = v1162:alpha_modulate(v1162.a * 0.2)

					pui.colors.sp = u179("star_a_sp", t14.safe_points:get() == "Force" and v1162 or v1163)
					pui.colors.ba = u179("star_a_ba", t14.body_aim:get() == "Force" and v1162 or v1163)
					pui.colors.fs = u179("star_a_fs", (not not t14.freestanding:get() or t14.freestanding:get_override()) and v1162 or v1163)

					local v1164 = u187() > 1 and u40("\a[sp]SP \a[ba]BA \a[fs]FS") or u40("\a[sp]SP   \a[ba]BA   \a[fs]FS")
					local v1165 = v35.measure_text(2, u188(), v1164)

					v35.text(2, vector(p331.x - v1165.x / 2, p331.y), color(255, p330.alpha), u188(), v1164)
				end
			})
			v241 = v238(2, 10)
		end

		v241:create({
			paint = function(p332, p333)
				-- upvalues: u183 (ref), v38 (copy), u40 (ref), s1 (copy), v4 (copy), v35 (copy), u188 (ref), u187 (ref)
				local v1168 = u183():alpha_modulate(p332.alpha)
				local v1169 = color(v1168.r, v1168.g, v1168.b, v38.floor(v38.sin(v38.abs(-v38.pi + globals.curtime * 2 % (v38.pi * 2))) * 255))
				local v1170 = u40.format("%s\a%s%s", u40.upper(s1), v1169:to_hex(), v4:upper())
				local v1171 = v35.measure_text(2, u188(), v1170)

				v35.text(2, vector(p333.x - v1171.x / 2, p333.y), color(255, p332.alpha), u188(), v1170)

				local v1172 = vector(p333.x - v1171.x / 2, p333.y + 8 * u187())

				v35.shadow(v1172, v1172 + vector(v1171.x, 0), v1168, 35 * u187())
			end
		})
		v241:create({
			get = function(_)
				-- upvalues: t4 (ref)
				return t4.state ~= nil
			end,
			paint = function(p335, p336)
				-- upvalues: u183 (ref), u40 (ref), t4 (ref), v35 (copy), u188 (ref), u179 (ref)
				local v1176 = u183()

				v1176.a = p335.alpha

				local v1177 = u40.format("*%s*", t4.state):upper()
				local v1178 = v35.measure_text(2, u188(), v1177)
				local v1179 = (u179("moon_state", v1178) + 0.3):floor()
				local v1180 = vector(p336.x - v1179.x / 2, p336.y)

				v35.push_clip_rect(vector(p336.x - v1179.x / 2, p336.y), v1180 + v1179)
				v35.text(2, vector(p336.x - v1179.x / 2, p336.y), v1176, u188(), v1177)
				v35.pop_clip_rect()
			end
		})
		v241:create({
			get = function(_)
				-- upvalues: t14 (copy)
				return t14.double_tap:get() or (t14.hide_shots:get() or t14.hide_shots:get_override())
			end,
			paint = function(p338, p339)
				-- upvalues: u183 (ref), t14 (copy), u40 (ref), v35 (copy), u188 (ref), u179 (ref)
				u183()

				local function v1184()
					local v1952 = rage.exploit:get()

					if v1952 ~= 1 then
						if v1952 ~= 0 then
							return {
								"CHARGING",
								color("99CEEEFF")
							}
						end

						return {
							"WAITING",
							color("DF6B6BFF")
						}
					end

					return {
						"READY",
						color("B2D07FFF")
					}
				end

				local v1185 = u40.format("%s:\a%s%s", (function()
					-- upvalues: t14 (copy)
					if not t14.double_tap:get() or t14.double_tap:get_override() ~= nil then
						if not t14.hide_shots:get() and not t14.hide_shots:get_override() then
							return "?"
						end

						return "HIDE"
					end

					return "DT"
				end)(), v1184()[2]:to_hex(), v1184()[1])
				local v1186 = v35.measure_text(2, u188(), v1185)

				v1186.x = v1186.x * (p338.alpha / 255)

				local v1187 = (u179("moon_dt", v1186) + 0.3):floor()
				local v1188 = vector(p339.x - v1187.x / 2, p339.y)

				v35.push_clip_rect(vector(p339.x - v1187.x / 2, p339.y), v1188 + v1187)
				v35.text(2, vector(p339.x - v1187.x / 2, p339.y), color(255, p338.alpha), u188(), v1185)
				v35.pop_clip_rect()
			end
		})
		v241:create({
			get = function(_)
				-- upvalues: t14 (copy)
				return t14:is_min_damage()
			end,
			paint = function(p341, p342)
				-- upvalues: v35 (copy), u188 (ref), u179 (ref)
				local v1192 = color(155, p341.alpha / 2)
				local s17 = "DAMAGE"
				local v1194 = v35.measure_text(2, u188(), s17)

				v1194.x = v1194.x * (p341.alpha / 255)

				local v1195 = (u179("moon_dmg", v1194) + 0.3):floor()
				local v1196 = vector(p342.x - v1195.x / 2, p342.y)

				v35.push_clip_rect(vector(p342.x - v1195.x / 2, p342.y), v1196 + v1195)
				v35.text(2, vector(p342.x - v1195.x / 2, p342.y), v1192, u188(), s17)
				v35.pop_clip_rect()
			end
		})
		v241:create({
			get = function(_)
				-- upvalues: t14 (copy)
				return t14.body_aim:get() == "Force"
			end,
			paint = function(p344, p345)
				-- upvalues: v35 (copy), u188 (ref), u179 (ref)
				local v1200 = color(155, p344.alpha / 2)
				local s18 = "BAIM"
				local v1202 = v35.measure_text(2, u188(), s18)

				v1202.x = v1202.x * (p344.alpha / 255)

				local v1203 = (u179("moon_baim", v1202) + 0.3):floor()
				local v1204 = vector(p345.x - v1203.x / 2, p345.y)

				v35.push_clip_rect(vector(p345.x - v1203.x / 2, p345.y), v1204 + v1203)
				v35.text(2, vector(p345.x - v1203.x / 2, p345.y), v1200, u188(), s18)
				v35.pop_clip_rect()
			end
		})
		v241:create({
			get = function(_)
				-- upvalues: t14 (copy)
				return t14.safe_points:get() == "Force"
			end,
			paint = function(p347, p348)
				-- upvalues: v35 (copy), u188 (ref), u179 (ref)
				local v1208 = color(155, p347.alpha / 2)
				local s19 = "SAFE"
				local v1210 = v35.measure_text(2, u188(), s19)

				v1210.x = v1210.x * (p347.alpha / 255)

				local v1211 = (u179("moon_safe", v1210) + 0.3):floor()
				local v1212 = vector(p348.x - v1211.x / 2, p348.y)

				v35.push_clip_rect(vector(p348.x - v1211.x / 2, p348.y), v1212 + v1211)
				v35.text(2, vector(p348.x - v1211.x / 2, p348.y), v1208, u188(), s19)
				v35.pop_clip_rect()
			end
		})

		local v242 = t15.features.indicators:switch("\v\f<raindrops>     \rDamage", false, nil, function(p349)
			return {
				while_override = p349:switch("While override")
			}, true
		end)

		u47.new("damage_indicator", v242, t18.features.visual)

		local v243 = v192("damage", vector(v18.x / 2, v18.y / 2 - 15))
		local v244 = v35.load_font("verdana", 9, "a")

		events.render(function()
			-- upvalues: v242 (copy), t14 (copy), u179 (ref), v243 (copy), v38 (copy), v35 (copy), v244 (copy), u188 (ref), u187 (ref)
			local v1214 = entity.get_local_player()
			local v1215 = v242.value and (v1214 ~= nil and v1214:is_alive())

			if v242.while_override:get() and v1215 then
				v1215 = t14:is_min_damage() or not (ui.get_alpha() <= 0)
			end

			local v1216 = u179("damage_alpha", v1215, 0.06)

			if v1215 or not (v1216 < 0.05) then
				local v1217 = v243:get_position()
				local v1218 = v38.floor(u179("damage", t14.damage:get_override() or t14.damage:get(), 0.03) + 0.5)

				if v1218 == 0 then
					v1218 = "A"
				end

				local v1219 = v35.measure_text(v244, u188(), tostring(v1218)) + vector(8, 7) * u187()

				v35.rect_outline(v1217, v1217 + v1219, color(255, 30 * ui.get_alpha() * v1216), 1, 3)

				local v1220 = u179("damage_color", t14:is_min_damage() and color() or color(255, 50))

				v35.text(v244, v1217 + vector(4, 3) * u187(), v1220:alpha_modulate(v1220.a * v1216), u188(), tostring(v1218))
				v243:update(v1219)

				return
			end
		end)
		u47.new("manual_arrows", t15.features.indicators:switch("\v\f<angle>     \rArrows", false, nil, function(p350)
			-- upvalues: u47 (ref)
			local t87 = {
				_type = p350:list("", {
					[1] = "\v\f<location-arrow>  \rPrimed",
					[2] = "\v\f<angles-right>  \rDelicate"
				}),
				offset = p350:slider(" \a[grey]\f<angle-right>    \rOffset", 0, 60, 25, 1, "px")
			}

			u47.set_callback_list(t87._type)

			return t87, true
		end), t18.features.visual)

		local _ = {
			[1] = {
				left = v35.load_image("<svg width=\"39\" height=\"45\" viewBox=\"0 0 39 45\" fill=\"none\" xmlns=\"http://www.w3.org/2000/svg\"> <path d=\"M34.41 1.07819C36.8485 -0.329653 39.7081 2.09415 38.7188 4.73032L32.3794 21.6229C32.1244 22.3024 32.1244 23.0514 32.3794 23.731L38.7188 40.6235C39.7081 43.2597 36.8485 45.6835 34.41 44.2756L1.49996 25.275C-0.500042 24.1203 -0.500043 21.2335 1.49996 20.0788L34.41 1.07819Z\" fill=\"white\"/> </svg>", vector() + 10),
				right = v35.load_image("<svg width=\"39\" height=\"45\" viewBox=\"0 0 39 45\" fill=\"none\" xmlns=\"http://www.w3.org/2000/svg\"> <path d=\"M4.58032 44.3833C2.14187 45.7912 -0.717708 43.3674 0.271586 40.7312L6.61098 23.8387C6.866 23.1591 6.866 22.4101 6.61098 21.7306L0.271582 4.83803C-0.717712 2.20186 2.14186 -0.221952 4.58031 1.18589L37.4904 20.1865C39.4904 21.3412 39.4904 24.228 37.4904 25.3827L4.58032 44.3833Z\" fill=\"white\"/> </svg>", vector() + 10)
			},
			[2] = {
				left = v35.load_image("<svg width=\"5\" height=\"10\" viewBox=\"0 0 5 10\" fill=\"none\" xmlns=\"http://www.w3.org/2000/svg\"><path d=\"M5 0L2 0L0 4.5L0 5.5L2 10H5L3 5.5L3 5L3 4.5L5 0Z\" fill=\"white\"/></svg>", vector(5, 10)),
				right = v35.load_image("<svg width=\"5\" height=\"10\" viewBox=\"0 0 5 10\" fill=\"none\" xmlns=\"http://www.w3.org/2000/svg\"><path d=\"M0 10L3 10L5 5.5L5 4.5L3 -1.74846e-07L8.74228e-07 -4.37114e-07L2 4.5L2 5L2 5.5L0 10Z\" fill=\"white\"/></svg>", vector(5, 10))
			}
		}
		local t88 = {}

		local function v247(p351, p352)
			-- upvalues: t88 (copy)
			t88[p351] = p352
		end

		v247(1, {
			left = v35.load_image("<svg width=\"39\" height=\"45\" viewBox=\"0 0 39 45\" fill=\"none\" xmlns=\"http://www.w3.org/2000/svg\"> <path d=\"M34.41 1.07819C36.8485 -0.329653 39.7081 2.09415 38.7188 4.73032L32.3794 21.6229C32.1244 22.3024 32.1244 23.0514 32.3794 23.731L38.7188 40.6235C39.7081 43.2597 36.8485 45.6835 34.41 44.2756L1.49996 25.275C-0.500042 24.1203 -0.500043 21.2335 1.49996 20.0788L34.41 1.07819Z\" fill=\"white\"/> </svg>", vector() + 20),
			right = v35.load_image("<svg width=\"39\" height=\"45\" viewBox=\"0 0 39 45\" fill=\"none\" xmlns=\"http://www.w3.org/2000/svg\"> <path d=\"M4.58032 44.3833C2.14187 45.7912 -0.717708 43.3674 0.271586 40.7312L6.61098 23.8387C6.866 23.1591 6.866 22.4101 6.61098 21.7306L0.271582 4.83803C-0.717712 2.20186 2.14186 -0.221952 4.58031 1.18589L37.4904 20.1865C39.4904 21.3412 39.4904 24.228 37.4904 25.3827L4.58032 44.3833Z\" fill=\"white\"/> </svg>", vector() + 20),
			paint = function(p353, p354, p355, p356, p357, p358, p359)
				-- upvalues: u187 (ref), v35 (copy)
				local v1240 = vector(p353.left.width, p353.right.height) * 0.5 * u187()
				local v1241 = p355 == "Left" and color(p358.r, p358.g, p358.b, 255 * p356) or color(0, 50 * p356)
				local v1242 = p355 == "Right" and color(p358.r, p358.g, p358.b, 255 * p356) or color(0, 50 * p356)

				p354.y = p354.y - v1240.y * p357
				v35.texture(p353.left, vector(p354.x - v1240.x - p359, p354.y - v1240.y / 2), v1240, v1241)
				v35.texture(p353.right, vector(p354.x + p359, p354.y - v1240.y / 2), v1240, v1242)
			end
		})
		v247(2, {
			left = v35.load_image("<svg width=\"5\" height=\"10\" viewBox=\"0 0 5 10\" fill=\"none\" xmlns=\"http://www.w3.org/2000/svg\"><path d=\"M5 0L2 0L0 4.5L0 5.5L2 10H5L3 5.5L3 5L3 4.5L5 0Z\" fill=\"white\"/></svg>", vector(5, 10) * 2),
			right = v35.load_image("<svg width=\"5\" height=\"10\" viewBox=\"0 0 5 10\" fill=\"none\" xmlns=\"http://www.w3.org/2000/svg\"><path d=\"M0 10L3 10L5 5.5L5 4.5L3 -1.74846e-07L8.74228e-07 -4.37114e-07L2 4.5L2 5L2 5.5L0 10Z\" fill=\"white\"/></svg>", vector(5, 10) * 2),
			paint = function(p360, p361, p362, p363, p364, p365, p366)
				-- upvalues: u187 (ref), v35 (copy)
				local v1250 = vector(p360.left.width, p360.right.height) * 0.5 * u187()
				local v1251 = p362 == "Left" and color(p365.r, p365.g, p365.b, 255 * p363) or color(0, 50 * p363)
				local v1252 = p362 == "Right" and color(p365.r, p365.g, p365.b, 255 * p363) or color(0, 50 * p363)

				p361.y = p361.y - v1250.y * p364
				v35.texture(p360.left, vector(p361.x - v1250.x - p366, p361.y - v1250.y / 2), v1250, v1251)
				v35.texture(p360.right, vector(p361.x + p366, p361.y - v1250.y / 2), v1250, v1252)
			end
		})
		events.render(function()
			-- upvalues: u47 (ref), u179 (ref), v38 (copy), u187 (ref), v18 (copy), t4 (ref), t88 (copy), u183 (ref)
			local v1225 = entity.get_local_player()
			local v1226 = u47.get("manual_arrows")
			local v1227 = v1226.value and (v1225 ~= nil and v1225:is_alive())
			local v1228 = u179("arrows_alpha", v1227)

			if v1227 or not (v1228 < 0.05) then
				local v1229 = v38.floor(u179("arrows_distance", v1226.offset.value * u187()) + 0.5)
				local v1230 = v18 / 2
				local v1231 = t4.elements and (t4.elements.manual and t4.elements.manual.value) or "None"
				local v1232 = t88[v1226._type.value]

				if v1232 ~= nil then
					v1232:paint(v1230, v1231, v1228, u179("arrows_scoped", {
						[1] = nil,
						[2] = 0,
						[3] = 1,
						[1] = v1225 ~= nil and v1225.m_bIsScoped and 1.2 or -0.2
					}), u183():alpha_modulate(255 * v1228), v1229)

					return
				end

				return
			end
		end)
		u47.new("scope_lines", t15.features.indicators:switch("\v\f<scribble>    \rScope lines", false, nil, function(p367)
			return {
				offset = p367:slider("Offset", 0, 100, 5, 1, "px"),
				length = p367:slider("Length", 0, 300, 55, 1, "px"),
				options = p367:listable("Color", {
					[1] = "Invert",
					[2] = "Rotate",
					[3] = "Spread based"
				}, color(255, 121))
			}, true
		end), t18.features.visual)
		events.render(function()
			-- upvalues: t14 (copy), u47 (ref), u179 (ref), v18 (copy), v38 (copy), u187 (ref), v35 (copy)
			t14.scope_overlay:override()

			local v1253 = entity.get_local_player()
			local v1254 = u47.get("scope_lines")

			if v1254.value then
				t14.scope_overlay:override("Remove All")
			end

			local v1255 = v1254:get() and (v1253 ~= nil and (v1253:is_alive() and v1253.m_bIsScoped))
			local v1256 = u179("scope_lines_alpha", {
				[1] = nil,
				[2] = 0,
				[3] = 1,
				[1] = v1255 and 1.3 or 0
			}, 0.1)

			if v1255 or not (v1256 < 0.05) then
				local n18 = 0

				if v1254.options:get(3) and v1253 then
					local v1258 = v1253:get_player_weapon()

					if v1258 and v1253.m_bIsScoped then
						n18 = u179("scope_lines_spread", (v1258:get_inaccuracy() + v1258:get_spread()) * v1258:get_max_speed() / 2)
					end
				end

				local v1259 = v18 / 2
				local v1260 = v38.max(u187(), 1)
				local v1261 = v1254.offset.value * v1256 + v38.floor(n18)
				local v1262 = v1254.length.value * v1256
				local v1263 = v1254.options:get(1)
				local v1264 = v1254.options.color.value:clone()
				local v1265 = v1264:alpha_modulate(v1264.a * v1256 * u179("scope_one", not v1263, 0.15))
				local v1266 = v1264:alpha_modulate(v1264.a * v1256 * u179("scope_two", v1263, 0.15))
				local v1267 = u179("scope_rotate", {
					[1] = nil,
					[2] = 90,
					[3] = 134,
					[1] = v1254.options:get(2) and 140 or 85
				}, 0.1)

				v35.push_rotation(v1267)
				v35.gradient(vector(v1259.x - v1261 + v1260, v1259.y), vector(v1259.x - v1261 - v1262 + v1260, v1259.y + v1260), v1265, v1266, v1265, v1266)
				v35.gradient(vector(v1259.x + v1261, v1259.y), vector(v1259.x + v1261 + v1262, v1259.y + v1260), v1265, v1266, v1265, v1266)
				v35.gradient(vector(v1259.x, v1259.y + v1261), vector(v1259.x + v1260, v1259.y + v1261 + v1262), v1265, v1265, v1266, v1266)
				v35.gradient(vector(v1259.x, v1259.y - v1261 + v1260), vector(v1259.x + v1260, v1259.y - v1261 - v1262 + v1260), v1265, v1265, v1266, v1266)
				v35.pop_rotation()

				return
			end
		end)

		local t89 = {
			cvar_timer = cvar.mp_c4timer,
			get_site = function(_)
				local v1270 = entity.get_entities("CPlantedC4")[1]
				local s20 = "?"

				if v1270 ~= nil and v1270.m_nBombSite ~= nil then
					s20 = v1270.m_nBombSite == 0 and "A" or "B"
				end

				return s20
			end
		}

		function t89.get_timer(_)
			-- upvalues: t89 (copy)
			local v1273 = entity.get_entities("CPlantedC4")[1]
			local n19 = 0
			local n20 = 1

			if v1273 ~= nil and v1273.m_flC4Blow ~= nil then
				t89.cvar_timer:float()

				local v1276 = v1273.m_flC4Blow - globals.curtime

				if v1276 > 0 then
					n19 = v1276
					n20 = 1 / v1273.m_flTimerLength * v1276
				end
			end

			return n19, n20
		end
		function t89.get_damage(_)
			-- upvalues: v38 (copy)
			local v1278 = entity.get_entities("CPlantedC4")[1]
			local v1279 = false
			local n21 = 0
			local v1281 = entity.get_local_player()

			if v1281 ~= nil and v1278 ~= nil then
				local v1282 = (v1281:get_origin():dist((v1278:get_origin())) - 75.68) / 789.2
				local v1283 = 450.7 * v38.exp(-v1282 * v1282)
				local m_ArmorValue = v1281.m_ArmorValue

				if m_ArmorValue > 0 then
					local v1285 = v1283 * 0.5
					local v1286 = (v1283 - v1285) * 0.5

					if m_ArmorValue < v1286 then
						local _ = m_ArmorValue * 2

						v1285 = v1283 - v1286
					end

					v1283 = v1285
				end

				n21 = v38.floor(v1283)
				v1279 = not (n21 < v1281.m_iHealth)
			end

			return v1279, n21
		end
		function t89.get_defuse_time(p371)
			local v1289 = entity.get_entities("CPlantedC4")[1]
			local v1290 = false
			local n22 = 0
			local v1292 = false
			local n23 = 1
			local v1294 = p371:get_timer()

			if v1289 ~= nil then
				local _ = v1289.m_bBombDefused
				local m_hBombDefuser = v1289.m_hBombDefuser
				local m_flDefuseLength = v1289.m_flDefuseLength

				n22 = m_hBombDefuser and v1289.m_flDefuseCountDown - globals.curtime or -1
				v1290 = not (n22 <= 0)
				v1292 = not (n22 >= v1294)
				n23 = 1 / m_flDefuseLength * n22
			end

			return v1290, n22, v1292, n23
		end
		function t89.get_state(p372)
			local v1299 = entity.get_entities("CPlantedC4")[1]
			local v1300 = false
			local v1301 = false
			local v1302 = p372:get_timer()

			if v1299 ~= nil then
				v1300 = v1299.m_bBombTicking and not (v1302 <= 0)
				v1301 = v1299.m_bBombDefused
			end

			return v1300, v1301
		end
		function t89.planting(_)
			local u1304 = false
			local n24 = 0

			entity.get_entities("CC4", true, function(p374)
				-- upvalues: u1304 (ref), n24 (ref)
				u1304 = p374.m_bStartedArming
				n24 = u1304 and p374.m_fArmedTime - globals.curtime or 0
			end)

			return u1304, n24
		end

		local t90 = {
			hit = 0,
			miss = 0
		}

		events.aim_ack(function(p375)
			-- upvalues: t90 (copy)
			if p375.state ~= nil then
				t90.miss = t90.miss + 1

				return
			end

			t90.hit = t90.hit + 1
		end)
		events.player_connect_full(function(p376)
			-- upvalues: t90 (copy)
			if entity.get_local_player() == entity.get(p376.userid, true) then
				t90.hit = 0
				t90.miss = 0
			end
		end)

		local v250 = v35.load_font("Calibri Bold", 25, "ad")
		local n25 = 45
		local v252 = vector(15, 10)
		local v253 = vector(25, v18.y / 2.3)
		local t91 = {
			base = color("C4C4C4"),
			red = color("FF0000"),
			green = color("A2D01E"),
			yellow = color("FCF369"),
			background = {
				outline = color(100, 75),
				background = color(100, 50)
			}
		}
		local v255 = t15.features.indicators:switch("\v\f<thought-bubble>    \rSide", false, nil, function(p377)
			return {
				division = p377:slider("\v\f<square-root-variable>   \rScreen division", 100, 300, 150, 0.01),
				items = p377:listable("", {
					[1] = "Fake",
					[2] = "Ping",
					[3] = "Fake Duck",
					[4] = "Body Aim",
					[5] = "Safe Points",
					[6] = "Hitchance",
					[7] = "Double Tap",
					[8] = "Hide Shots",
					[9] = "Min. Damage",
					[10] = "Freestanding",
					[11] = "Dormant Aimbot",
					[12] = "Aimbot Stats",
					[13] = "Bomb Info",
					[14] = "Bomb Defusing"
				})
			}, true
		end)

		u47.new("side_indicators", v255, t18.features.visual)

		local function v256(p378)
			-- upvalues: v255 (copy)
			for k, v in next, v255.items:list() do
				if p378 == v then
					return v255.items:get(k)
				end
			end

			return false
		end

		local t92 = {}

		local function v258(p379)
			-- upvalues: v39 (copy), t92 (copy)
			local t93 = {
				get = function()
				end,
				paint = function()
				end
			}

			v39.insert(t92, 1, setmetatable(p379, {
				__index = t93
			}))
		end
		local function v259(p380, p381, p382, p383)
			-- upvalues: v35 (copy), v250 (copy), v252 (copy), t91 (copy), v38 (copy)
			local v1318 = v35.measure_text(v250, "", p382) + v252 + (p383 ~= nil and vector(20, 0) or vector())

			v35.rect(p380, p380 + v1318, t91.background.background, 8)
			v35.rect_outline(p380, p380 + v1318, t91.background.outline, 1, 8)
			v35.text(v250, vector(p380.x + v252.x / 2, p380.y + v252.y / 2 + 1), p381, "", p382)

			if p383 ~= nil then
				local n26 = 8

				v35.circle_outline(vector(p380.x + v1318.x - 15, p380.y + 19), t91.background.outline, n26, 0, 1, 4)
				v35.circle_outline(vector(p380.x + v1318.x - 15, p380.y + 19), p381, n26, 0, v38.clamp(p383, 0, 1), 3)
			end
		end
		local function v260()
			-- upvalues: t92 (copy), v39 (copy)
			local t94 = {}

			for _, v in ipairs(t92) do
				if v:get() then
					v39.insert(t94, v)
				end
			end

			return t94
		end

		v255:set_event("render", v43(v255, function()
			-- upvalues: v255 (copy), v260 (copy), v253 (copy), v18 (copy), n25 (copy)
			local v1323 = entity.get_local_player()

			if v1323 and v1323:is_alive() then
				local v1324 = v255.division.value * 0.01

				for k, v in next, v260() do
					v:paint(vector(v253.x, v18.y / v1324 - n25 * (k - 1)))
				end

				return
			end
		end, t1.PRO, t1.TRIAL))
		v258({
			menu_double_tap = ui.find("Aimbot", "Ragebot", "Main", "Double Tap"),
			get = function(p384)
				-- upvalues: v256 (copy)
				return v256("Double Tap") and (p384.menu_double_tap:get_override() or p384.menu_double_tap:get())
			end,
			paint = function(_, p386)
				-- upvalues: t91 (copy), v259 (copy)
				local v1330 = rage.exploit:get() == 1 and t91.base or t91.red

				v259(p386, v1330, "DT")
			end
		})
		v258({
			menu_fake_duck = ui.find("Aimbot", "Anti Aim", "Misc", "Fake Duck"),
			get = function(p387)
				-- upvalues: v256 (copy)
				return v256("Fake Duck") and (p387.menu_fake_duck:get_override() or p387.menu_fake_duck:get())
			end,
			paint = function(_, p389)
				-- upvalues: t91 (copy), v259 (copy)
				local base = t91.base

				v259(p389, base, "DUCK")
			end
		})
		v258({
			desync_smoothy = smoothy.new(0),
			get = function(_)
				-- upvalues: v256 (copy)
				return v256("Fake")
			end,
			paint = function(p391, p392)
				-- upvalues: v38 (copy), t91 (copy), v259 (copy)
				local v1338 = v38.clamp(v38.min(v38.abs(rage.antiaim:get_rotation(true) - rage.antiaim:get_rotation()), rage.antiaim:get_max_desync()), 0, 58)
				local v1339 = p391.desync_smoothy(0.04, v1338)
				local v1340 = t91.red:lerp(t91.green, v1339 / 60)

				v259(p392, v1340, "FAKE")
			end
		})
		v258({
			menu_fake_latency = ui.find("Miscellaneous", "Main", "Other", "Fake Latency"),
			get_ping = function()
				-- upvalues: v38 (copy), v37 (copy)
				if not globals.is_connected then
					return 0
				end

				return v38.floor(v37.net_channel().latency[0] * 1000)
			end,
			get = function(p393)
				-- upvalues: v256 (copy)
				return v256("Ping") and not (p393.menu_fake_latency:get() <= 0)
			end,
			paint = function(p394, p395)
				-- upvalues: v38 (copy), t91 (copy), v259 (copy)
				local v1344 = v38.clamp(p394.get_ping() / p394.menu_fake_latency:get(), 0, 1)
				local v1345 = t91.red:lerp(t91.green, v1344)

				v259(p395, v1345, "PING")
			end
		})
		v258({
			menu_min_damage = ui.find("Aimbot", "Ragebot", "Selection", "Min. Damage"),
			get = function(p396)
				-- upvalues: v256 (copy)
				if v256("Min. Damage") then
					for _, v in next, ui.get_binds() do
						if v.reference:id() == p396.menu_min_damage:id() and v.active then
							return true
						end
					end

					return false
				end

				return false
			end,
			paint = function(p397, p398)
				-- upvalues: t91 (copy), v259 (copy), u40 (ref)
				local base = t91.base
				local v1352 = p397.menu_min_damage:get()

				v259(p398, base, ("MD: %s"):format(v1352 > 100 and u40.format("+%s", v1352 - 100) or v1352))
			end
		})
		v258({
			menu_hit_chance = ui.find("Aimbot", "Ragebot", "Selection", "Hit Chance"),
			get = function(p399)
				-- upvalues: v256 (copy)
				if v256("Hitchance") then
					for _, v in next, ui.get_binds() do
						if v.reference:id() == p399.menu_hit_chance:id() and v.active then
							return true
						end
					end

					return false
				end

				return false
			end,
			paint = function(p400, p401)
				-- upvalues: t91 (copy), v259 (copy)
				local base = t91.base

				v259(p401, base, ("HC: %i%%"):format(p400.menu_hit_chance:get()))
			end
		})
		v258({
			menu_body_aim = ui.find("Aimbot", "Ragebot", "Safety", "Body Aim"),
			get = function(p402)
				-- upvalues: v256 (copy)
				return v256("Body Aim") and p402.menu_body_aim:get() == "Force"
			end,
			paint = function(_, p404)
				-- upvalues: t91 (copy), v259 (copy)
				local base = t91.base

				v259(p404, base, "BAIM")
			end
		})
		v258({
			menu_safe_points = ui.find("Aimbot", "Ragebot", "Safety", "Safe Points"),
			get = function(p405)
				-- upvalues: v256 (copy)
				return v256("Safe Points") and p405.menu_safe_points:get() == "Force"
			end,
			paint = function(_, p407)
				-- upvalues: t91 (copy), v259 (copy)
				local base = t91.base

				v259(p407, base, "SAFE")
			end
		})
		v258({
			menu_freestanding = ui.find("Aimbot", "Anti Aim", "Angles", "Freestanding"),
			get = function(p408)
				-- upvalues: v256 (copy)
				return v256("Freestanding") and (p408.menu_freestanding:get_override() or p408.menu_freestanding:get())
			end,
			paint = function(_, p410)
				-- upvalues: t91 (copy), v259 (copy)
				local base = t91.base

				v259(p410, base, "FS")
			end
		})
		v258({
			menu_dormant_aimbot = ui.find("Aimbot", "Ragebot", "Main", "Enabled", "Dormant Aimbot"),
			get = function(p411)
				-- upvalues: v256 (copy), t46 (copy)
				return v256("Dormant Aimbot") and (t46.enabled or (p411.menu_dormant_aimbot:get_override() or p411.menu_dormant_aimbot:get()))
			end,
			paint = function(_, p413)
				-- upvalues: t91 (copy), v259 (copy)
				local base = t91.base

				v259(p413, base, "DA")
			end
		})
		v258({
			menu_hide_shots = ui.find("Aimbot", "Ragebot", "Main", "Hide Shots"),
			get = function(p414)
				-- upvalues: v256 (copy)
				return v256("Hide Shots") and (p414.menu_hide_shots:get_override() or p414.menu_hide_shots:get())
			end,
			paint = function(_, p416)
				-- upvalues: t91 (copy), v259 (copy)
				local base = t91.base

				v259(p416, base, "OS")
			end
		})
		v258({
			get = function(_)
				-- upvalues: v256 (copy)
				return v256("Aimbot Stats")
			end,
			paint = function(_, p419)
				-- upvalues: t91 (copy), t90 (copy), v38 (copy), v259 (copy)
				local base = t91.base
				local v1383 = t90.hit + t90.miss
				local v1384 = t90.hit / v1383
				local n27 = 0

				if v1384 > 0 then
					n27 = v38.floor(v1384 * 100)
				end

				local v1386 = ("%s/%s (%s%%)"):format(t90.hit, t90.miss, n27)

				v259(p419, base, v1386)
			end
		})
		v258({
			get = function(_)
				-- upvalues: t89 (copy), v256 (copy)
				local v1388 = t89:planting()

				return v256("Bomb Info") and v1388
			end,
			paint = function(_, p422)
				-- upvalues: t91 (copy), v259 (copy)
				local yellow = t91.yellow

				v259(p422, yellow, "Planting")
			end
		})
		v258({
			get = function(_)
				-- upvalues: t89 (copy), v256 (copy)
				local v1393, v1394 = t89:get_state()

				return v256("Bomb Info") and (v1393 and not v1394)
			end,
			paint = function(_, p425)
				-- upvalues: t89 (copy), t91 (copy), v259 (copy)
				local v1397, v1398 = t89:get_damage()
				local v1399 = v1397 and t91.red or t91.yellow
				local v1400 = v1397 and "FATAL" or ("-%s HP"):format(v1398)

				v259(p425, v1399, v1400)
			end
		})
		v258({
			get = function(_)
				-- upvalues: t89 (copy), v256 (copy)
				local v1402, v1403 = t89:get_state()

				return v256("Bomb Info") and (v1402 and not v1403)
			end,
			paint = function(_, p428)
				-- upvalues: t89 (copy), t91 (copy), v259 (copy)
				local v1406 = t89:get_site()
				local v1407, _ = t89:get_timer()
				local base = t91.base
				local v1410 = ("%s - %.1fs"):format(v1406, v1407)

				v259(p428, base, v1410)
			end
		})
		v258({
			get = function(_)
				-- upvalues: t89 (copy), v256 (copy)
				local v1412, _, _, _ = t89:get_defuse_time()

				return v256("Bomb Defusing") and v1412
			end,
			paint = function(_, p431)
				-- upvalues: t89 (copy), t91 (copy), v259 (copy)
				local _, _, v1420, v1421 = t89:get_defuse_time()
				local v1422 = v1420 and t91.yellow or t91.red

				v259(p431, v1422, "Defusing", v1421)
			end
		})

		local t95 = {}
		local t96 = {}

		local function v263(p432, p433)
			-- upvalues: v39 (copy), t96 (copy), t95 (copy)
			v39.insert(t96, p432)
			v39.insert(t95, p433)
		end

		v263("\v\f<star>  \rStar", "\f<star>")
		v263("\v\f<moon>  \rMoon", "\f<moon>")
		v263("\v\f<heart>  \rHeart", "\f<heart>")
		v263("\v\f<sparkles>  \rSparkles", "\f<sparkles>")

		local v264 = t15.features.world:switch("\v\f<sparkles>    \rHitmarker", false, nil, function(p434)
			-- upvalues: t96 (copy), u47 (ref)
			local t97 = {
				duration = p434:slider("Duration", 1, 10, 2, 1, "s"),
				style = p434:list("", t96),
				font = p434:list("", {
					[1] = "\v\f<circle>  \rDefault",
					[2] = "\v\f<square>  \rPixel"
				})
			}

			u47.set_callback_list(t97.font)
			u47.set_callback_list(t97.style)

			return t97, true
		end)

		u47.new("hitmarker", v264, t18.features.visual)

		local t98 = {}

		events.render(function()
			-- upvalues: v264 (copy), u179 (ref), t98 (ref), u40 (ref), t95 (copy), u183 (ref), t5 (ref), u188 (ref), v35 (copy), v39 (copy)
			local v1427 = entity.get_local_player()
			local v1428 = v264.value and v1427 ~= nil
			local v1429 = u179("hitmarker_alpha", v1428)

			if v1428 or not (v1429 < 0.05) then
				for k, v in next, t98 do
					local state = v.state
					local t99 = {
						HIT = u40(t95[v264.style:get()] or "?"),
						MISS = u40("\f<xmark> %s", state)
					}
					local t100 = {
						HIT = u183(),
						MISS = t5.state_colors(state)
					}
					local t101 = {
						HIT = u188("c"),
						MISS = u188()
					}
					local v1436 = v264.font:get()
					local v1437 = not (v.realtime + v264.duration:get() <= globals.realtime)

					v.alpha = v.smoothy(0.05, v1437 and 255 or -10) * v1429
					v35.text(v1436, v.aim:to_screen(), (state and t100.MISS or t100.HIT):alpha_modulate(v.alpha), state and t101.MISS or t101.HIT, u40[v1436 == 2 and "upper" or "lower"](state and t99.MISS or t99.HIT))

					if not v1437 and v.alpha < 3 then
						v39.remove(t98, k)
					end
				end

				return
			end
		end)
		events.round_start(function(_)
			-- upvalues: t98 (ref)
			t98 = {}
		end)
		events.aim_ack(function(p436)
			-- upvalues: v39 (copy), t98 (ref), smoothy (copy)
			v39.insert(t98, {
				alpha = 0,
				smoothy = smoothy.new(0),
				realtime = globals.realtime,
				aim = p436.aim,
				state = p436.state
			})
		end)

		local r_aspectratio = cvar.r_aspectratio

		local function v267()
			-- upvalues: r_aspectratio (copy)
			r_aspectratio:int(0)
		end

		u47.new("aspect_ratio", t15.features.world:switch("\v\f<expand-wide>    \rAspect ratio", false, nil, function(p437)
			return {
				amount = p437:slider("", 100, 250, 140, 0.01)
			}, true
		end), t18.features.visual)
		events.render(function()
			-- upvalues: u47 (ref), t14 (copy), u179 (ref), v267 (copy), r_aspectratio (copy)
			local v1440 = u47.get("aspect_ratio")

			t14.unlock_cvars:override(true)

			local v1441 = v1440.value and v1440.amount.value * 0.01 or 1.78
			local v1442 = u179("aspect_ratio", v1441, 0.1)

			if v1440.value or v1441 ~= v1442 then
				if v1442 ~= r_aspectratio:float() then
					r_aspectratio:float(v1442)
				end

				return
			end

			return v267()
		end)
		events.shutdown(v267)

		local v268 = setmetatable({
			fov = cvar.viewmodel_fov:int(),
			offset_x = cvar.viewmodel_offset_x:float(),
			offset_y = cvar.viewmodel_offset_y:float(),
			offset_z = cvar.viewmodel_offset_z:float()
		}, {
			__call = function(p438)
				for k, v in next, p438 do
					cvar["viewmodel_" .. k]:float(v, true)
				end
			end
		})
		local v269 = smoothy.new({
			fov = v268.fov,
			offset_x = v268.offset_x,
			offset_y = v268.offset_y,
			offset_z = v268.offset_z
		})

		u47.new("viewmodel", t15.features.world:switch("\v\f<hand>    \rViewmodel", false, nil, function(p439)
			local t102 = {
				fov = p439:slider("FOV", 0, 1500, 680, 0.1),
				offset_x = p439:slider("X", -100, 100, 25, 0.1),
				offset_y = p439:slider("Y", -100, 100, 0, 0.1),
				offset_z = p439:slider("Z", -100, 100, -20, 0.1),
				reset = p439:button("                          \v\f<rotate-right>  \rReset                          ", nil, true)
			}
			local t103 = {
				[1] = "fov",
				[2] = "offset_x",
				[3] = "offset_y",
				[4] = "offset_z"
			}

			t102.reset:set_callback(function()
				-- upvalues: t103 (copy), t102 (copy)
				for _, v in next, t103 do
					t102[v]:reset()
				end
			end)

			return t102, true
		end), t18.features.visual)
		events.render(function()
			-- upvalues: u47 (ref), v268 (copy), v269 (copy)
			local v1447 = u47.get("viewmodel")

			for k, v in next, v268 do
				local v1450 = v1447.value and v1447[k].value * 0.1 or v
				local v1451 = v269(0.1, {
					[k] = v1450
				})

				if v1451 ~= v1450 then
					cvar["viewmodel_" .. k]:float(v1451[k], true)
				end
			end
		end)
		events.shutdown(function()
			-- upvalues: v268 (copy)
			v268()
		end)
		u47.new("grenade_radius", t15.features.world:switch("\v\f<circle>    \rGrenade radius", false, nil, function(p440)
			local t104 = {
				smoke = p440:switch("Smoke", false, nil, {
					[1] = nil,
					[2] = true,
					[1] = color(122, 180, 255, 122)
				}),
				molotov = p440:switch("Molotov", false, {
					Safe = { color(133, 255, 122, 122) },
					Danger = { color(255, 122, 122, 122) }
				})
			}

			t104.molotov.color:depend(t104.molotov)

			return t104, true
		end), t18.features.visual)

		local function v270(p441, p442, p443, p444)
			-- upvalues: v35 (copy)
			v35.circle_3d_outline(p441, p442, p443, 0, p444, 2)
			v35.circle_3d_gradient(p441, p442:alpha_modulate(p442.a * 0.4), p442:alpha_modulate(0), p443, 0, 1)
		end

		events.render(function()
			-- upvalues: u47 (ref), u179 (ref), u40 (ref), v270 (copy)
			local v1461 = u47.get("grenade_radius")

			if v1461:get() and v1461.smoke:get() then
				local v1462 = entity.get_local_player()

				entity.get_entities("CSmokeGrenadeProjectile", false, function(p445)
					-- upvalues: v1462 (copy), u179 (ref), u40 (ref), v1461 (copy), v270 (copy)
					local v1957 = p445:get_origin()
					local v1958 = v1462:get_origin():dist2d(v1957)
					local v1959 = 1 - (globals.tickcount - p445.m_nSmokeEffectTickBegin) / 1155
					local v1960 = p445.m_bDidSmokeEffect and (v1958 < 1300 and not (v1959 <= 0.05))
					local v1961 = u179(u40("smoke(%s)", p445:get_index()), v1960, 0.1)
					local v1962 = v1461.smoke.color.value:clone()

					if p445.m_bDidSmokeEffect then
						v270(v1957, v1962:alpha_modulate(v1962.a * v1961), 125 * v1961, v1959)
					end
				end)

				return
			end
		end)
		events.render(function()
			-- upvalues: u47 (ref), u179 (ref), u40 (ref), v39 (copy), v270 (copy)
			local v1463 = u47.get("grenade_radius")

			if v1463:get() and v1463.molotov:get() then
				local v1464 = entity.get_local_player()

				entity.get_entities("CInferno", false, function(p446)
					-- upvalues: v1464 (copy), u179 (ref), u40 (ref), v1463 (copy), v39 (copy), v270 (copy)
					local v1964 = p446:get_origin()
					local v1965 = v1464:get_origin():dist2d(v1964)
					local v1966 = 1 - (globals.tickcount - p446.m_nFireEffectTickBegin) / 453
					local v1967 = p446.m_bFireIsBurning and (v1965 < 570 and not (v1966 <= 0.05))
					local v1968 = u179(u40("molotov(%s)", p446:get_index()), v1967, 0.1)
					local m_hOwnerEntity = p446.m_hOwnerEntity
					local v1970 = m_hOwnerEntity ~= nil and (tonumber(cvar.mp_friendlyfire:int()) == 0 and (m_hOwnerEntity ~= v1464 and not m_hOwnerEntity:is_enemy())) and v1463.molotov.color:get("Safe")[1]:clone() or v1463.molotov.color:get("Danger")[1]:clone()
					local t105 = {}
					local n28 = 0
					local v1973 = nil
					local v1974 = nil

					for i = 1, 64 do
						if p446.m_bFireIsBurning[i] then
							v39.insert(t105, vector(p446.m_fireXDelta[i], p446.m_fireYDelta[i], p446.m_fireZDelta[i]))
						end
					end

					for i = 1, #t105 do
						for j = 1, #t105 do
							local v1978 = t105[i]:dist2d(t105[j])

							if n28 < v1978 then
								n28 = v1978
								v1973 = t105[i]
								v1974 = t105[j]
							end
						end
					end

					if v1973 ~= nil and v1974 ~= nil then
						local v1979 = v1964 + v1973:lerp(v1974, 0.5)
						local v1980 = u179(u40("molotov_radius(%s)", p446:get_index()), n28 / 2 + 40, 0.1)

						if p446.m_bFireIsBurning then
							v270(v1979, v1970:alpha_modulate(v1970.a * v1968), v1980 * v1968, v1966)
						end
					end
				end)

				return
			end
		end)
		v271 = t15.features.world:switch("\v\f<moon-stars>    \rWorld modulate", false, nil, function(p447)
			local t106 = {
				bloom = p447:slider("Bloom", 0, 100, 0, 1, function(p448)
					return p448 == 0 and "Off" or p448 .. "%"
				end),
				exposure = p447:slider("Exposure", 0, 100, 0, 1, function(p449)
					return p449 == 0 and "Off" or p449 .. "%"
				end),
				model_brightness = p447:slider("Model brightness", 0, 200, 0, 1, function(p450)
					return p450 == 0 and "Off" or p450 .. "%"
				end),
				model_transparency = p447:switch("Model transparency")
			}

			t106.model_transparency:tooltip("\v\f<circle-info>  \rKeeps model transparent after shooting with snipers and adds animation")

			return t106, true
		end)
		u47.new("world_modulate", v271, t18.features.visual)
		t107 = {}

		local m_bUseCustomBloomScale = nil
		local m_flCustomBloomScale = nil

		local function v275(p451, p452)
			-- upvalues: m_bUseCustomBloomScale (ref), m_flCustomBloomScale (ref)
			entity.get_entities("CEnvTonemapController", false, function(p453)
				-- upvalues: m_bUseCustomBloomScale (ref), m_flCustomBloomScale (ref), p451 (copy), p452 (copy)
				if m_bUseCustomBloomScale == nil or m_flCustomBloomScale == nil then
					m_bUseCustomBloomScale = p453.m_bUseCustomBloomScale
					m_flCustomBloomScale = p453.m_flCustomBloomScale
				else
					p453.m_bUseCustomBloomScale = p451
					p453.m_flCustomBloomScale = p452
				end
			end)
		end

		function t107.shutdown()
			-- upvalues: m_bUseCustomBloomScale (ref), m_flCustomBloomScale (ref), v275 (copy)
			if m_bUseCustomBloomScale ~= nil and m_flCustomBloomScale ~= nil then
				v275(m_bUseCustomBloomScale, m_flCustomBloomScale)
			end
		end
		function t107.paint()
			-- upvalues: v271 (copy), t107 (copy), v275 (copy)
			local v1469 = v271.bloom.value / 10

			if v1469 ~= 0 then
				v275(true, v1469)

				return
			end

			return t107.shutdown()
		end

		t108 = {}

		local m_bUseCustomAutoExposureMin = nil
		local m_bUseCustomAutoExposureMax = nil
		local m_flCustomAutoExposureMin = nil
		local m_flCustomAutoExposureMax = nil

		local function v281(p454, p455, p456, p457)
			-- upvalues: m_flCustomAutoExposureMin (ref), m_flCustomAutoExposureMax (ref), m_bUseCustomAutoExposureMin (ref), m_bUseCustomAutoExposureMax (ref)
			entity.get_entities("CEnvTonemapController", false, function(p458)
				-- upvalues: m_flCustomAutoExposureMin (ref), m_flCustomAutoExposureMax (ref), m_bUseCustomAutoExposureMin (ref), m_bUseCustomAutoExposureMax (ref), p454 (copy), p455 (copy), p456 (copy), p457 (copy)
				if m_flCustomAutoExposureMin ~= nil or m_flCustomAutoExposureMax ~= nil or m_bUseCustomAutoExposureMin ~= nil or m_bUseCustomAutoExposureMax ~= nil then
					p458.m_bUseCustomAutoExposureMin = p454
					p458.m_bUseCustomAutoExposureMax = p455
					p458.m_flCustomAutoExposureMin = p456
					p458.m_flCustomAutoExposureMax = p457
				else
					m_bUseCustomAutoExposureMin = p458.m_bUseCustomAutoExposureMin
					m_bUseCustomAutoExposureMax = p458.m_bUseCustomAutoExposureMax
					m_flCustomAutoExposureMin = p458.m_flCustomAutoExposureMin
					m_flCustomAutoExposureMax = p458.m_flCustomAutoExposureMax
				end
			end)
		end

		function t108.shutdown()
			-- upvalues: m_flCustomAutoExposureMin (ref), m_flCustomAutoExposureMax (ref), m_bUseCustomAutoExposureMin (ref), m_bUseCustomAutoExposureMax (ref), v281 (copy)
			if m_flCustomAutoExposureMin ~= nil and m_flCustomAutoExposureMax ~= nil and m_bUseCustomAutoExposureMin ~= nil and m_bUseCustomAutoExposureMax ~= nil then
				v281(m_bUseCustomAutoExposureMin, m_bUseCustomAutoExposureMax, m_flCustomAutoExposureMin, m_flCustomAutoExposureMax)
			end
		end
		function t108.paint()
			-- upvalues: v271 (copy), t108 (copy), v281 (copy)
			local v1474 = true
			local v1475 = v271.exposure.value / 100

			if v1475 ~= 0 then
				v281(v1474, v1474, v1475, v1475)

				return
			end

			return t108.shutdown()
		end

		t109 = {}

		local r_modelAmbientMin = cvar.r_modelAmbientMin
		local v284 = r_modelAmbientMin:float()

		function t109.shutdown()
			-- upvalues: r_modelAmbientMin (copy), v284 (copy)
			r_modelAmbientMin:float(v284, true)
		end
		function t109.paint()
			-- upvalues: v271 (copy), t109 (copy), r_modelAmbientMin (copy)
			local v1476 = v271.model_brightness.value / 5

			if v1476 ~= 0 then
				if v1476 ~= r_modelAmbientMin:float() then
					r_modelAmbientMin:float(v1476, true)
				end

				return
			end

			return t109.shutdown()
		end
	end

	local v285 = smoothy.new(255)

	v271.model_transparency:set_event("localplayer_transparency", function(p459)
		-- upvalues: v285 (copy)
		local v1478 = entity.get_local_player()
		local v1479 = v1478.m_bResumeZoom or v1478.m_bIsScoped
		local v1480 = v285(0.07, v1479 and 59 or p459)

		if p459 == v1480 then
			return
		end

		return v1480
	end)

	local function v286()
		-- upvalues: t107 (copy), t108 (copy), t109 (copy)
		t107.shutdown()
		t108.shutdown()
		t109.shutdown()
	end

	v271:set_event("render", function()
		-- upvalues: t107 (copy), t108 (copy), t109 (copy)
		t107.paint()
		t108.paint()
		t109.paint()
	end)
	v271:set_callback(function()
		-- upvalues: v271 (copy), v286 (copy)
		if not v271.value then
			v286()
		end
	end)
	events.shutdown(v286)
	u47.new("fast_ladder", t15.features.movement:switch("\v\f<line-height>    \rFast ladder"), t18.features.misc)
	u47.get("fast_ladder"):tooltip("\v\f<circle-info>  \rAllow you to climb ladders more quickly")
	u47.get("fast_ladder"):set_event("createmove", function(p460)
		-- upvalues: u47 (ref), v38 (copy)
		if u47.get("fast_ladder").value then
			if entity.get_local_player().m_MoveType == 9 then
				p460.view_angles.y = v38.floor(p460.view_angles.y + 0.5)
				p460.roll = 0

				if p460.forwardmove == 0 and p460.sidemove ~= 0 then
					p460.view_angles.x = 89
					p460.view_angles.y = p460.view_angles.y + 180

					if p460.sidemove < 0 then
						p460.in_moveleft = 0
						p460.in_moveright = 1
					end

					if p460.sidemove > 0 then
						p460.in_moveleft = 1
						p460.in_moveright = 0
					end
				end

				if p460.forwardmove > 0 then
					p460.view_angles.x = 89
					p460.in_moveright = 1
					p460.in_moveleft = 0
					p460.in_forward = 0
					p460.in_back = 1

					if p460.sidemove == 0 then
						p460.view_angles.y = p460.view_angles.y + 90
					end

					if p460.sidemove < 0 then
						p460.view_angles.y = p460.view_angles.y + 150
					end

					if p460.sidemove > 0 then
						p460.view_angles.y = p460.view_angles.y + 30
					end
				end

				if p460.forwardmove < 0 then
					p460.view_angles.x = 89
					p460.in_moveleft = 1
					p460.in_moveright = 0
					p460.in_forward = 1
					p460.in_back = 0

					if p460.sidemove == 0 then
						p460.view_angles.y = p460.view_angles.y + 90
					end

					if p460.sidemove > 0 then
						p460.view_angles.y = p460.view_angles.y + 150
					end

					if p460.sidemove < 0 then
						p460.view_angles.y = p460.view_angles.y + 30
					end
				end
			end

			return
		end
	end)

	local u287 = false

	local function v288(p461, p462)
		-- upvalues: v38 (copy), v37 (copy)
		local v1484 = p461:get_origin()
		local x = v1484.x
		local y = v1484.y
		local z = v1484.z

		for i = 0, v38.pi * 2, v38.pi * 2 / 8 do
			if v37.trace_line(vector(10 * v38.cos(i) + x, 10 * v38.sin(i) + y, z), vector(10 * v38.cos(i) + x, 10 * v38.sin(i) + y, z - p462), p461).fraction ~= 1 then
				return true
			end
		end

		return false
	end

	u47.new("no_fall_damage", t15.features.movement:switch(" \v\f<person-falling>    \rNo fall damage", false, "\v\f<circle-info>  \rThis can help you avoid getting hit when falling from a height whenever possible"), t18.features.misc)
	u47.get("no_fall_damage"):set_event("createmove_run", function()
		-- upvalues: u47 (ref), u287 (ref), v288 (copy)
		if u47.get("no_fall_damage").value then
			local v1489 = entity.get_local_player()

			if v1489 ~= nil then
				if not (v1489.m_vecVelocity.z >= -500) then
					if not v288(v1489, 15) then
						if v288(v1489, 75) then
							u287 = true
						end
					else
						u287 = false
					end
				else
					u287 = false
				end

				return
			end

			return
		end
	end)
	u47.get("no_fall_damage"):set_event("createmove", function(p463)
		-- upvalues: u47 (ref), u287 (ref)
		if u47.get("no_fall_damage").value then
			local v1491 = entity.get_local_player()

			if v1491 ~= nil then
				if v1491.m_vecVelocity.z < -500 then
					if not u287 then
						p463.in_duck = 0
					else
						p463.in_duck = 1
					end
				end

				return
			end

			return
		end
	end)

	local function v289(p464, p465)
		return vector():angles(p464, p465)
	end

	u47.new("avoid_collisions", t15.features.movement:switch("\v\f<person-walking-arrow-loop-left>    \rAvoid collisions"), t18.features.misc)
	u47.get("avoid_collisions"):set_event("createmove", function(p466)
		-- upvalues: v35 (copy), v38 (copy), v289 (copy), v37 (copy)
		local v1495 = entity.get_local_player()

		if v1495 then
			local n29 = 7
			local v1497 = v35.camera_angles()
			local m_vecOrigin = v1495.m_vecOrigin
			local huge = v38.huge
			local huge2 = v38.huge

			for i = 20, 180, 20 do
				local x = v289(0, v1497.y + i - 90).x
				local y = v289(0, v1497.y + i - 90).y
				local _ = v289(0, v1497.y).z
				local v1505 = m_vecOrigin.x + x * 70
				local v1506 = m_vecOrigin.y + y * 70
				local v1507 = m_vecOrigin.z + 60
				local v1508 = v37.trace_line(m_vecOrigin, vector(v1505, v1506, v1507), nil, nil, 1)

				if huge > m_vecOrigin:dist(v1508.end_pos) then
					huge = m_vecOrigin:dist(v1508.end_pos)
					huge2 = i
				end
			end

			if huge < 25 + n29 and p466.in_jump and not p466.in_moveright and not p466.in_moveleft and not p466.in_back then
				p466.forwardmove = v38.abs(v1495.m_vecVelocity:length() * v38.cos(v38.rad(huge2)))

				if not (v38.abs(huge2 - 90) < 40) then
					side_velo = v1495.m_vecVelocity:length() * v38.sin(v38.rad(huge2))
				else
					side_velo = v1495.m_vecVelocity:length() * v38.sin(v38.rad(huge2)) * (25 + n29 - huge) / 15
				end

				if not (huge2 >= 90) then
					p466.sidemove = side_velo * -1
				else
					p466.sidemove = side_velo
				end
			end

			return
		end
	end)

	local v290 = t15.features.other:label("\v\f<sword>    \rGame focus", false, nil, function(p467)
		local t110 = {
			switch_to_game = p467:switch("\v\f<window>    \rSwitch to game"),
			flask_game_icon = p467:switch("\v\f<lightbulb-on>   \rFlash game icon"),
			client_nickname = p467:switch(" \v\f<user>    \rClient nickname"),
			nickname = p467:input("")
		}

		t110.nickname:depend(t110.client_nickname)
		t110.client_nickname:tooltip("\v\f<circle-info>  \rThis nickname will only be visible to you in the kill-feed, scoreboard, etc.")

		return t110
	end)

	u47.new("game_focus", v290, t18.features.misc)

	local function v291()
		-- upvalues: v290 (copy), v37 (copy)
		ffi.cdef("            int GetForegroundWindow();\n            bool FlashWindow(int hwnd, bool invert);\n            void SwitchToThisWindow(int hwnd, bool unknown);\n            int FindWindowA(const char* class, const char* name);\n        ")

		local v1511 = ffi.load("user32")
		local v1512 = v1511.FindWindowA("Valve001", "Counter-Strike: Global Offensive - Direct3D 9")

		local function v1513()
			-- upvalues: v1511 (copy), v1512 (copy)
			return v1511.GetForegroundWindow() == v1512
		end
		local function v1514()
			-- upvalues: v1513 (copy), v1511 (copy), v1512 (copy)
			if not v1513() then
				v1511.FlashWindow(v1512, true)
			end
		end
		local function v1515()
			-- upvalues: v1513 (copy), v1511 (copy), v1512 (copy)
			if not v1513() then
				v1511.SwitchToThisWindow(v1512, false)
			end
		end

		events.round_start(function()
			-- upvalues: v290 (copy), v1514 (copy), v37 (copy), v1515 (copy)
			if v290.flask_game_icon.value then
				v1514()
			end

			if v290.switch_to_game.value then
				v37.execute_after(1, v1515)
			end
		end)
	end

	local u292 = false

	local function v293()
		-- upvalues: v290 (copy), u292 (ref), v291 (copy)
		if (v290.switch_to_game.value or v290.flask_game_icon.value) and not u292 then
			u292 = true
			v291()
		end
	end

	v293()
	v290.switch_to_game:set_callback(v293)
	v290.flask_game_icon:set_callback(v293)

	local v294 = u47.get("game_focus")
	local t111 = {
		local_client_base = ffi.cast("uintptr_t**", v37.opcode_scan("engine.dll", "A1 ? ? ? ? 0F 28 C1 F3 0F 5C 80 ? ? ? ? F3 0F 11 45 ? A1 ? ? ? ? 56 85 C0 75 04 33 F6 EB 26 80 78 14 00 74 F6 8B 4D 08 33 D2 E8 ? ? ? ? 8B F0 85 F6", 1)),
		player_struct = ffi.typeof("            struct {\n                int64_t         unknown;\n                int64_t         steamID64;\n                char            szName[128];\n                int             userId;\n                char            szSteamID[20];\n                char            pad_0x00A8[0x10];\n                unsigned long   iSteamID;\n                char            szFriendsName[128];\n                bool            fakeplayer;\n                bool            ishltv;\n                unsigned int    customfiles[4];\n                unsigned char   filesdownloaded;\n            }\n        ")
	}

	t111.get_userdata = v37.get_vfunc(11, ffi.typeof("$*(__thiscall*)(void*, int, int*)", t111.player_struct))

	local function v296(p468)
		-- upvalues: t111 (copy)
		local v1517 = entity.get_local_player()

		if v1517 then
			t111.local_client = t111.local_client_base[0][0]

			if t111.local_client then
				t111.userinfo = ffi.cast("void***", t111.local_client + 21184)[0]

				if t111.userinfo then
					local v1518 = t111.get_userdata(t111.userinfo, v1517:get_index() - 1, nil)

					if v1518 then
						if p468 ~= ffi.string(v1518[0].szName) then
							v1518[0].szName = ffi.new("char[128]", p468)
						end

						return
					end

					return
				end

				return
			end

			return
		end
	end
	local function v297()
		-- upvalues: v296 (copy)
		v296(panorama.MyPersonaAPI.GetName())
	end
	local function v298()
		-- upvalues: v294 (copy), v296 (copy), v297 (copy)
		if not v294.client_nickname.value or not (#v294.nickname.value > 0) then
			v297()

			return
		end

		return v296(v294.nickname.value)
	end

	v298()
	v294.client_nickname:set_callback(v298)
	v294.nickname:set_callback(v298)
	events.shutdown(v297)
	events.round_prestart(v298)
	events.player_connect_full(v298)

	local v299 = t15.features.other:label("\v\f<bomb>    \rGrenade features", nil, function(p469)
		local t112 = {
			drop_all = p469:switch("Drop all\ac2a04aff*")
		}

		t112.drop_all:tooltip("\ac2a04affBind to hold\n\v\f<circle-info>  \rThrows out all grenades")
		t112.fix_throw = p469:switch("Throw fix")
		t112.super_toss = p469:switch("Super toss")
		t112.auto_release = p469:switch("Auto release")
		t112.release_damage = p469:slider(" \a[grey]\f<angle-right>    \rMin. damage", 1, 60, 20):depend(t112.auto_release)
		t112.auto_release:tooltip("\v\f<circle-info>  \rWill throw grenade when damage reaches min. damage")

		return t112
	end)

	u47.new("grenade_features", v299, t18.features.misc)

	local u300 = false

	local function v301(p470, p471, p472, p473)
		-- upvalues: v38 (copy), v33 (copy)
		local v1525 = vector():angles(p470.x - 10 + v38.abs(p470.x) / 9, p470.y)
		local v1526 = v33(p472 * 0.9, 15, 750) * (v33(p473, 0, 1) * 0.7 + 0.3)
		local v1527 = v1525

		for _ = 1, 8 do
			v1527 = (v1525 * (v1527 * v1526 + p471 * 1.25):length() - p471 * 1.25) / v1526
			v1527:normalize()
		end

		local v1529 = v1527:angles()

		if not (v1529.x > -10) then
			v1529.x = 1.125 * v1529.x + 11.25
		else
			v1529.x = 0.9 * v1529.x + 9
		end

		return v1529
	end

	v43(v299.super_toss, nil, t1.PRO, t1.TRIAL)

	if PRO == t1.PRO or PRO == t1.TRIAL then
		v299.super_toss:set_callback(function(p474)
			-- upvalues: t14 (copy)
			if not p474:get() then
				t14.air_strafe:override()
				t14.strafe_assist:override()
			end
		end)
		v299.super_toss:set_event("createmove", function(p475)
			-- upvalues: u300 (ref), t14 (copy), v301 (copy)
			if u300 then
				u300 = false
				t14.air_strafe:override()
				t14.strafe_assist:override()
			end

			if p475.jitter_move then
				local v1535 = entity.get_local_player()

				if v1535 and v1535:is_alive() then
					local v1536 = v1535:get_player_weapon()

					if v1535 then
						local v1537 = v1536:get_weapon_info()

						if v1537 then
							if v1537.weapon_type == 9 then
								if v1536.m_fThrowTime > 0 and not (v1536.m_fThrowTime - 0.1 * rage.exploit:get() > globals.curtime) then
									u300 = true
									t14.air_strafe:override(false)
									t14.strafe_assist:override(false)

									local v1538 = v1535:simulate_movement()

									v1538:think()
									p475.view_angles = v301(p475.view_angles, v1538.velocity, v1537.throw_velocity, v1536.m_flThrowStrength)

									return
								end

								return
							end

							return
						end

						return
					end

					return
				end

				return
			end
		end)
		v299.super_toss:set_event("grenade_override_view", function(p476)
			-- upvalues: v301 (copy)
			local v1531 = entity.get_local_player()

			if v1531 and v1531:is_alive() then
				local v1532 = v1531:get_player_weapon()

				if v1531 then
					local v1533 = v1532:get_weapon_info()

					if v1533 then
						p476.angles = v301(p476.angles, p476.velocity, v1533.throw_velocity, v1532.m_flThrowStrength)

						return
					end

					return
				end

				return
			end
		end)
	end

	local u302 = false
	local t113 = {
		["High Explosive Grenade"] = "weapon_hegrenade",
		Molotov = "weapon_molotov",
		["Incendiary Grenade"] = "weapon_incgrenade",
		["Smoke Grenade"] = "weapon_smokegrenade"
	}

	events.createmove(function(p477)
		-- upvalues: v299 (copy), u302 (ref), t113 (copy), v37 (copy)
		local v1541 = entity.get_local_player()

		if v1541 then
			local v1542 = v1541:get_player_weapon(true)

			if v1542 then
				if v299.drop_all:get() then
					p477.in_use = true

					if not u302 then
						local n30 = 1

						for _, v in next, v1542 do
							local v1546 = t113[v:get_name()]

							if v1546 ~= nil then
								v37.execute_after(0.02 * n30, function()
									-- upvalues: v37 (copy), v1546 (copy)
									v37.console_exec("use " .. v1546 .. "; drop")
								end)
							end

							n30 = n30 + 1
						end
					end
				end

				u302 = v299.drop_all:get()

				return
			end

			return
		end
	end)

	local n31 = 0

	events.grenade_prediction(function(p478)
		-- upvalues: n31 (ref)
		if p478.type ~= "Frag" and p478.type ~= "Molly" then
			n31 = 0

			return
		end

		n31 = p478.damage
	end)
	v299.auto_release:set_event("createmove", function(p479)
		-- upvalues: n31 (ref), v299 (copy)
		local v1549 = entity.get_local_player()

		if v1549 ~= nil then
			local v1550 = v1549:get_player_weapon()

			if v1550 ~= nil then
				local v1551 = v1550:get_name()

				if v1551 == "Molotov" or v1551 == "High Explosive Grenade" then
					if p479.in_attack and v1550.m_bPinPulled and n31 >= v299.release_damage.value then
						p479.in_attack = false
					end

					return
				end

				return
			end

			return
		end
	end)
	v299.fix_throw:set_event("createmove", function(_)
		-- upvalues: t14 (copy), v39 (copy)
		t14.double_tap.quick_switch:override()
		t14.weapon_actions:override()

		local v1553 = entity.get_local_player()

		if v1553 ~= nil then
			local v1554 = v1553:get_player_weapon()

			if v1554 ~= nil then
				local v1555 = v1554:get_weapon_info()

				if v1555 ~= nil and v1555.weapon_type == 9 and v1554.m_bPinPulled == true then
					rage.exploit:allow_defensive(false)
					t14.double_tap.quick_switch:override(false)
					t14.weapon_actions:override(v39.delete(t14.weapon_actions:get(), "Quick Switch"))
				end

				return
			end

			return
		end
	end)

	local v305 = v37.get_vfunc("engine.dll", "VEngineClient014", 11, "bool(__thiscall*)(void*)")
	local t114 = {}
	local t115 = {
		[1] = "vgui_white",
		[2] = "vgui/hud/800corner1",
		[3] = "vgui/hud/800corner2",
		[4] = "vgui/hud/800corner3",
		[5] = "vgui/hud/800corner4"
	}
	local u308 = nil

	local function v309(p481)
		-- upvalues: v305 (copy), u308 (ref), t114 (ref)
		if not v305() then
			p481 = color()
		end

		if p481 ~= u308 then
			for _, v in next, t114 do
				v:alpha_modulate(p481.a / 255)
				v:color_modulate(color(p481.r, p481.g, p481.b))
			end

			u308 = p481

			return
		end
	end
	local function v310()
		-- upvalues: v309 (copy)
		v309(color())
	end;

	(function()
		-- upvalues: t114 (ref), t115 (copy)
		t114 = {}

		for _, v in next, t115 do
			local v1558 = materials.get(v)

			if v1558 == nil then
				v1558 = materials.get_materials(v)[1]
			end

			if v1558 ~= nil and v1558:is_valid() then
				t114[v] = v1558
			end
		end
	end)()
	u47.new("console_color", t15.features.other:switch("\v\f<terminal>    \rConsole color", false, nil, {
		[1] = nil,
		[2] = true,
		[1] = color("3838389A")
	}), t18.features.misc)
	events.render(function()
		-- upvalues: u47 (ref), v309 (copy)
		local v1562 = u47.get("console_color")

		if v1562.value then
			local value = v1562.color.value

			v309(value)

			return
		end
	end)
	events.shutdown(v310)
	u47.get("console_color"):set_callback(v310)

	local v311 = t15.features.other:switch("\v\f<link>    \rUnlock latency")

	u47.new("unlock_latency", v311, t18.features.misc)
	v311:tooltip("\v\f<circle-info>   \rUnlocks the Fake latency value and allows you to set the value higher.\n\n\v\f<folder>   \rMiscellaneous > Main > Other > Fake Latency")

	local v312 = cvar.sv_maxunlag:float()

	local function v313()
		-- upvalues: v312 (copy)
		cvar.sv_maxunlag:float(v312)
	end

	v311:set_callback(v43(v311, function()
		-- upvalues: v311 (copy), v313 (copy)
		if not v311:get() then
			v313()

			return
		end

		return cvar.sv_maxunlag:float(1)
	end, t1.PRO, t1.TRIAL))
	events.shutdown(v313)

	local t116 = {}

	events.render(function()
		-- upvalues: t116 (copy)
		for _, v in next, t116 do
			if v.realtime + v.delay < globals.realtime and v.state then
				v.callback(unpack(v.arguments))
				v.realtime = v.delay + globals.realtime
			end
		end
	end)

	local v315 = t15.features.scoreboard:switch("\v\f<screencast>    \rShared icon")

	u47.new("icon", v315, t18.features.misc)

	local t117 = {
		["NL Pro"] = "https://raw.githubusercontent.com/kissprince/evalate-shared-logo/refs/heads/main/nl-evalate-pro.png",
		["GS Legacy"] = "https://raw.githubusercontent.com/kissprince/evalate-shared-logo/refs/heads/main/gs-evalate-legacy.png",
		["NL Base"] = "https://raw.githubusercontent.com/kissprince/evalate-shared-logo/refs/heads/main/nl-evalate.png",
		["GS Base"] = "https://raw.githubusercontent.com/kissprince/evalate-shared-logo/refs/heads/main/gs-evalate.png",
		["NL Trial"] = "https://raw.githubusercontent.com/kissprince/evalate-shared-logo/refs/heads/main/nl-evalate-trial.png",
		["GS Pro"] = "https://raw.githubusercontent.com/kissprince/evalate-shared-logo/refs/heads/main/gs-debug-pro.png",
		["NL Recode"] = "https://raw.githubusercontent.com/kissprince/evalate-shared-logo/refs/heads/main/nl-evalate-recode.png",
		["GS Debug"] = "https://raw.githubusercontent.com/kissprince/evalate-shared-logo/refs/heads/main/gs-evalate-debug.png"
	}

	local function v317()
		for _, v in ipairs(entity.get_players(false, true)) do
			v:set_icon()
		end
	end

	v315:set_event("net_update_end", function()
		-- upvalues: u58 (ref), u40 (ref), v59 (copy), t117 (copy)
		if globals.tickcount % 64 == 0 then
			if u58 then
				local t118 = {}

				for _, v in ipairs(u58) do
					t118[v.secret] = u40.format("%s %s", v.cheat, v.build_name)
				end

				for _, v in ipairs(entity.get_players(false, true)) do
					local v1573 = v:get_player_info()

					if v1573 then
						local v1574 = t118[v59(v1573.steamid64)]

						if v1574 then
							local v1575 = t117[v1574]

							if v1575 then
								v:set_icon(v1575)
							end
						end
					end
				end

				return
			end

			return
		end
	end)
	v315:set_callback(function(p482)
		-- upvalues: v317 (copy)
		if not p482.value then
			v317()
		end
	end)

	local v318 = t15.features.scoreboard:switch("\v\f<tag>     \rClantag")

	u47.new("clantag", v318, t18.features.misc)

	local t119 = {
		[1] = "",
		[2] = "6",
		[3] = "e7",
		[4] = "ev4",
		[5] = "eva7",
		[6] = "eval2",
		[7] = "evala5",
		[8] = "evalat3",
		[9] = "evalate$",
		[10] = "evalate.7",
		[11] = "evalate.c9",
		[12] = "evalate.co#",
		[13] = "evalate.com",
		[14] = "evalate.com",
		[15] = "evalate.com",
		[16] = "evalate.com",
		[17] = "evalate.com",
		[18] = "evalate.co#",
		[19] = "evalate.c9",
		[20] = "evalate.7",
		[21] = "evalate$",
		[22] = "evalat3",
		[23] = "evala5",
		[24] = "eval2",
		[25] = "eva7",
		[26] = "ev4",
		[27] = "e7",
		[28] = "6",
		[29] = ""
	}
	local s21 = ""
	local n32 = 17

	local function v322(p483)
		-- upvalues: s21 (ref), v36 (copy)
		if p483 ~= s21 then
			s21 = p483
			v36.set_clan_tag(p483)
		end
	end
	local function v323()
		-- upvalues: v322 (copy)
		v322("")
	end

	v318:set_event("render", function()
		-- upvalues: v37 (copy), v38 (copy), n32 (copy), t119 (copy), v322 (copy)
		if globals.is_connected then
			local v1580 = v37.net_channel()

			if v1580 then
				local v1581 = v1580.latency[1] or 0
				local v1582 = to_ticks(v1581)
				local v1583 = globals.tickcount + v1582
				local v1584 = v38.floor(v1583 / n32) % #t119 + 1

				v322(t119[v1584])

				return
			end

			return
		end
	end)
	v318:set_event("shutdown", v323)
	v318:set_callback(v323)

	local t120 = {}
	local t121 = {
		mute = v37.get_vfunc("client.dll", "GameClientExports001", 2, "void(__thiscall*)(void*, int playerIndex)"),
		unmute = v37.get_vfunc("client.dll", "GameClientExports001", 3, "void(__thiscall*)(void*, int playerIndex)"),
		is_muted = v37.get_vfunc("client.dll", "GameClientExports001", 1, "bool(__thiscall*)(void*, int playerIndex)")
	}
	local v326 = t15.features.scoreboard:switch("\v\f<microphone-slash>    \rVoice state", false, nil, function(p484)
		return {
			state = p484:list("", "\f<microphone>     Unmute", "\f<microphone-slash>   Mute")
		}, true
	end)

	u47.set_callback_list(v326.state)
	u47.new("voice_state", v326, t18.features.misc)

	local function v327()
		-- upvalues: t120 (ref), t121 (copy)
		t120 = {}
		entity.get_players(false, true, function(p485)
			-- upvalues: t121 (copy)
			t121.unmute(p485:get_index())
		end)
	end
	local function v328()
		-- upvalues: v326 (copy)
		v326:name(v326.state:get() == 2 and "\v\f<microphone-slash>    \rVoice state" or " \v\f<microphone>     \rVoice state")
	end

	events.shutdown(v327)
	events.level_init(v327)
	v326:set_event("render", function()
		-- upvalues: u40 (ref), v326 (copy), t121 (copy), t120 (ref)
		local v1586 = entity.get_local_player()

		if v1586 then
			entity.get_players(false, true, function(p486)
				-- upvalues: v1586 (copy), u40 (ref), v326 (copy), t121 (copy), t120 (ref)
				if p486 ~= v1586 then
					local v1987 = p486:get_name()
					local v1988 = p486:get_index()
					local v1989 = u40.format("%s::%s", v1987, v1988)

					if v326.state:get() == 1 and t121.is_muted(v1988) == true and t120[v1989] ~= "unmuted" then
						t121.unmute(v1988)
						t120[v1989] = "unmuted"
					end

					if v326.state:get() == 2 and t121.is_muted(v1988) == false and t120[v1989] ~= "muted" then
						t121.mute(v1988)
						t120[v1989] = "muted"
					end

					return
				end
			end)

			return
		end
	end)
	v326.state:set_callback(v328, true)
	v326:set_callback(function()
		-- upvalues: v327 (copy), v328 (copy)
		v327()
		v328()
	end)
	v326:tooltip("\v\f<circle-info>  \rYou can unmute players, also mute everyone")
end

local n33 = 2
local v330 = t15.features.scoreboard:switch("\v\f<trash>     \rTrashtalk", false, nil, function(p487)
	local t122 = {
		events = p487:listable("\v\f<check>   \rEvents", {
			[1] = "On Kill",
			[2] = "On Death"
		}),
		style = p487:list("\v\f<font>   \rStyle", {
			[1] = "Simple",
			[2] = "Russian",
			[3] = "English"
		})
	}

	t122.style:depend({
		[1] = t122.events,
		[2] = function()
			-- upvalues: t122 (copy)
			return not (#t122.events.value <= 0)
		end
	})

	return t122, true
end)

u47.set_callback_list(v330.style, true)
u47.new("trashtalk", v330, t18.features.misc)

local t123 = {
	[1] = {
		on_kill = {
			[1] = "1"
		},
		on_death = {}
	},
	[2] = {
		on_kill = {
			[1] = "evalate.com/competition",
			[2] = "я на первом месте чекай  evalate.com/leaderboard",
			[3] = "ты видел мои огромные яйца?!?!?!?!...",
			[4] = "вх рипнулось сори что убил",
			[5] = "вся консоль в твоих смертях",
			[6] = nil,
			[7] = "ибо нехуй тебе тыркать по клавиатуре и надеется на удачу",
			[8] = "ха, обезьянка, убил тебя",
			[9] = nil,
			[10] = "тебе время для триал версии evalate выдать или что?",
			[11] = "поиграй с триалом евалейта я хз market.neverlose.cc/k3jdRt",
			[12] = "♛ 𝐎𝐖𝐍𝐄𝐃 𝐁𝐘 𝐄𝐕𝐀𝐋𝐀𝐓𝐄 𝐋𝐔𝐎 ♛",
			[13] = nil,
			[14] = "кто контролирует пятерочку в судже - тот правит миром",
			[15] = "у тебя лаги или ты по жизни такой медленный?",
			[16] = "Ты стреляешь как моя бабуля, а она слепая!",
			[17] = "во дебил умер опять",
			[6] = {
				[1] = "такой тупорылый",
				[2] = "я вахуе"
			},
			[9] = {
				[1] = "иди диспутни свою хуйню",
				[2] = "не бустит тебя"
			},
			[13] = {
				[1] = "моча твоя луа, гетни 𝒆𝒗𝒂𝒍𝒂𝒕𝒆",
				[2] = "если конечно денег хватит хахахаа)"
			}
		},
		on_death = {
			[1] = nil,
			[2] = nil,
			[3] = "ну фу блять",
			[4] = "ну ебанат блядь",
			[5] = "ну маму ебал ты как убил меня",
			[6] = "фу блядота с нлом убивает опять",
			[7] = "а тимейт как всегда на Б",
			[8] = "КАК ТЫ ТУТ ВЫСТРЕЛИЛ ДАУН",
			[9] = "это ты сколько кнопок прожал чтобы убить меня?",
			[10] = "это в сколько тиков?",
			[11] = "𝐞𝐛𝐚𝐧𝐚𝐭...",
			[12] = "потужно",
			[13] = "ты так кемперишь что пора уже палатку ставить",
			[14] = "урод",
			[15] = nil,
			[16] = "чит еще не научился предиктить мувы такого долбаеба",
			[1] = {
				[1] = "подсос ебаный",
				[2] = "а теперь думай, это я пишу или трештолк",
				[3] = "хуеглот блядь"
			},
			[2] = {
				[1] = "ну не не",
				[2] = "ну такой пидорас меня убил"
			},
			[15] = {
				[1] = "долбаеб фейк флик вжал и ходит",
				[2] = "ебаната кусок"
			},
			[17] = {
				[1] = "тупой хуесос",
				[2] = "",
				[3] = "",
				[4] = "а теперь думай, это трештолк пишет или я"
			}
		}
	},
	[3] = {
		on_kill = {
			[1] = "evalate.com/competition",
			[2] = "Bruh, you aiming or praying?",
			[3] = "Is your mouse broken or are you just that bad?",
			[4] = "Choose your excuse: 1.Lags | 2.New mouse | 3.Low FPS | 4.Low team | 5.Hacker | 6.Lucker | 7.Smurf | 8.Hitbox | 9.Tickrate",
			[5] = "ez",
			[6] = "𝒕𝒖𝒓𝒏 𝒆𝒗𝒆𝒓𝒚 𝒎𝒂𝒕𝒄𝒉 𝒊𝒏𝒕𝒐 𝒚𝒐𝒖𝒓 𝒉𝒊𝒈𝒉𝒍𝒊𝒈𝒉𝒕 𝒓𝒆𝒆𝒍 𝒘𝒊𝒕𝒉 𝒆𝒗𝒂𝒍𝒂𝒕𝒆",
			[7] = "♛ 𝐎𝐖𝐍𝐄𝐃 𝐁𝐘 𝐄𝐕𝐀𝐋𝐀𝐓𝐄 𝐋𝐔𝐎 ♛",
			[8] = "bruh, your aim is like a potato on a spin cycle",
			[9] = "you sure you're not playing with your feet?",
			[10] = "are you lagging, or just naturally slow?",
			[11] = "you aim like my grandma, and she's blind!"
		},
		on_death = {
			[1] = "mcdonalds resolver"
		}
	}
}

local function v332(p488, p489)
	-- upvalues: v37 (copy)
	v37.execute_after(p488, function()
		-- upvalues: v37 (copy), p489 (copy)
		v37.console_exec("say " .. p489)
	end)
end
local function v333(p490)
	-- upvalues: n33 (copy), v332 (copy)
	local v1592 = n33

	if type(p490) ~= "string" then
		for _, v in next, p490 do
			v332(v1592, v)
			v1592 = v1592 + n33
		end

		return
	end

	return v332(v1592, p490)
end
local function v334(p491)
	-- upvalues: t123 (copy), v330 (copy), v37 (copy), v333 (copy)
	local v1596 = t123[v330.style.value]

	if v1596 then
		local v1597 = v1596[p491]

		if v1597 and not (#v1597 < 1) then
			local v1598 = v1597[v37.random_int(1, #v1597)]

			if v1598 then
				v333(v1598)

				return
			end

			return
		end

		return
	end
end

v330:set_event("player_death", function(p492)
	-- upvalues: v330 (copy), v334 (copy)
	local v1600 = entity.get(p492.attacker, true)
	local v1601 = entity.get(p492.userid, true)
	local v1602 = entity.get_local_player()

	if v330.events:get("On Death") and (v1600 ~= v1602 and v1601 == v1602) then
		v334("on_death")
	end

	if v330.events:get("On Kill") and v1600 == v1602 and v1601 ~= v1602 then
		v334("on_kill")
	end
end)

local u335 = false
local n34 = 1
local n35 = 1

events.createmove(function()
	-- upvalues: n34 (ref), n35 (ref), u335 (ref)
	if globals.choked_commands == 0 then
		if not (n34 > 1) then
			u335 = not u335
		elseif not (n35 >= n34) then
			n35 = n35 + 1
		else
			n35 = 1
			u335 = not u335
		end
	end
end)

local u338 = setmetatable({
	get_last = function()
		-- upvalues: u335 (ref)
		return u335
	end
}, {
	__call = function(_, p494)
		-- upvalues: n34 (ref), u335 (ref)
		n34 = p494 or 1

		return u335
	end
})
local n36 = 1
local n37 = 3

events.createmove(function()
	-- upvalues: n36 (ref), n37 (ref)
	if globals.choked_commands == 0 then
		if n36 >= n37 then
			n36 = 0
		end

		n36 = n36 + 1
	end
end)

local function u341(p495, _)
	-- upvalues: n37 (ref), v38 (copy), n36 (ref)
	n37 = p495 or 3

	return v38.clamp(n36, 1, n37)
end
local function v342()
	local u1607 = false
	local n38 = 1
	local n39 = 1

	events.createmove(function()
		-- upvalues: n38 (ref), n39 (ref), u1607 (ref)
		if globals.choked_commands == 0 then
			if not (n38 > 1) then
				u1607 = not u1607
			elseif not (n39 >= n38) then
				n39 = n39 + 1
			else
				n39 = 1
				u1607 = not u1607
			end
		end
	end)

	return function(p497)
		-- upvalues: n38 (ref), u1607 (ref)
		if p497 then
			n38 = p497
		end

		return u1607
	end
end

local t124 = {
	limits = {
		max = 10,
		min = 2
	}
}

t4 = {}

local t125 = {}
local t126 = {}
local t127 = {}
local t128 = {}
local t129 = {}
local u349 = false
local t130 = {
	circle = {},
	target = {}
}
local n40 = -1

local function v352(p498)
	-- upvalues: u40 (ref)
	if p498 then
		local v1611 = p498:get_name()
		local v1612 = p498:get_index()
		local steamid64 = p498:get_player_info().steamid64

		return u40("%s:%s:%s", v1611, v1612, steamid64)
	end

	return ""
end

function t124.get_state_data(_)
	-- upvalues: t4 (ref), t130 (copy), t126 (copy), v352 (copy)
	local state = t4.state

	if state then
		local v1616 = t130.circle[state]

		if t126[state].antibrute_manager.system.value == "Target" then
			local v1617 = entity.get_threat()

			if not v1617 then
				return
			end

			local v1618 = v352(v1617)

			if not t130.target[v1618] then
				return
			end

			v1616 = t130.target[v1618][state]
		end

		if v1616 and v1616.phase ~= nil then
			if v1616.is_inf or not (globals.realtime > v1616.expired_at) then
				return v1616
			end

			return
		end

		return
	end
end

local function v353(p500)
	-- upvalues: t4 (ref), n40 (ref), t126 (copy), t130 (copy), v352 (copy), u40 (ref), t5 (ref), pui (copy)
	local state = t4.state

	if n40 ~= globals.tickcount then
		if state then
			if t126[state].options.custom_anti_brute.value then
				if not t130.circle[state] then
					t130.circle[state] = {}
				end

				local v1621 = v352(p500)

				if not t130.target[v1621] or not t130.target[v1621][state] then
					t130.target[v1621] = {
						[state] = {}
					}
				end

				local value = t126[state].antibrute_manager.duration.value
				local value2 = t126[state].antibrute_manager.counter.value

				n40 = globals.tickcount
				t130.circle[state] = {
					target = p500,
					phase = (t130.circle[state].phase or 0) + 1,
					duration = value,
					is_inf = value == 0,
					expired_at = globals.realtime + value
				}
				t130.target[v1621] = {
					[state] = {
						target = p500,
						phase = (t130.target[v1621][state].phase or 0) + 1,
						duration = value,
						is_inf = value == 0,
						expired_at = globals.realtime + value
					}
				}

				if value2 < t130.circle[state].phase then
					t130.circle[state].phase = 1
				end

				if value2 < t130.target[v1621][state].phase then
					t130.target[v1621][state].phase = 1
				end

				local value3 = t126[state].antibrute_manager.system.value
				local v1625 = value3 == "Target" and t130.target[v1621][state] or t130.circle[state]

				if v1625 then
					local v1626 = u40.limit(v1625.target:get_name(), 17)
					local v1627 = t5.build(nil, "Anti-Bruteforce › Phase: {phase} · State: {state} · Target: {name} · System: {system} ‹", {
						phase = v1625.phase,
						name = v1626,
						state = state,
						system = value3
					})

					t5.print(v1627)

					local v1628 = t5.build(nil, "Switch phase to {phase} due to {name} shot", {
						phase = v1625.phase,
						name = v1626
					})

					t5.screen(function(p501, p502)
						-- upvalues: t5 (ref), v1628 (copy), pui (copy)
						t5.center(p502, v1628, (pui.colors.active or color()):alpha_modulate(p501.alpha))
					end)

					return
				end

				return
			end

			return
		end

		return
	end
end

if PRO == t1.PRO or PRO == t1.TRIAL then
	events.close_shot(function(p503)
		-- upvalues: t4 (ref), t126 (copy), v353 (copy)
		if t4.state and t126[t4.state].antibrute_manager.events:get(1) then
			v353(p503.entity)
		end
	end)
	events.player_hurt(function(p504)
		-- upvalues: t4 (ref), t126 (copy), v353 (copy)
		if t4.state and t126[t4.state].antibrute_manager.events:get(2) then
			local v1631 = entity.get(p504.userid, true)
			local v1632 = entity.get(p504.attacker, true)
			local v1633 = entity.get_local_player()

			if v1631 == v1633 and v1632 ~= v1633 then
				v353(v1632)
			end
		end
	end)
	t81:create({
		get = function(_)
			-- upvalues: u47 (ref), t124 (copy)
			local v1635 = u47.get("debug_panel")

			return v1635 and (v1635.features:get(5) and (t124:get_state_data() or not (ui.get_alpha() <= 0)))
		end,
		paint_title = function(p506, p507)
			-- upvalues: v35 (copy), t61 (copy), u188 (ref)
			local s22 = "Anti-Brute"

			p506.size = v35.measure_text(t61.font.content, u188(), s22)
			v35.text(t61.font.content, p507, color(200, p506.alpha), u188(), s22)
		end,
		paint_value = function(p508, p509)
			-- upvalues: t124 (copy), v35 (copy), t61 (copy), u188 (ref)
			local v1641 = t124:get_state_data()
			local v1642 = v1641 and v1641.phase or "none"
			local v1643 = v35.measure_text(t61.font.content, u188(), v1642)

			v35.text(t61.font.content, vector(p509.x - v1643.x, p509.y), color(200, p508.alpha * 0.4), u188(), v1642)
		end
	})
	t81:create({
		get = function(_)
			-- upvalues: u47 (ref), t124 (copy)
			local v1645 = u47.get("debug_panel")

			return v1645 and (v1645.features:get(5) and (t124:get_state_data() or not (ui.get_alpha() <= 0)))
		end,
		paint_title = function(p511, p512)
			-- upvalues: v35 (copy), t61 (copy), u188 (ref)
			local s23 = "Duration"

			p511.size = v35.measure_text(t61.font.content, u188(), s23)
			v35.text(t61.font.content, p512, color(200, p511.alpha), u188(), s23)
		end,
		paint_value = function(p513, p514)
			-- upvalues: t124 (copy), u40 (ref), v38 (copy), v35 (copy), t61 (copy), u188 (ref), u187 (ref), u183 (ref)
			local v1651 = t124:get_state_data()
			local s24 = "none"
			local n41 = 0

			if v1651 then
				local v1654 = v1651.expired_at - globals.realtime
				local v1655 = not (globals.realtime <= v1651.expired_at) and "expired" or u40.format("%.1fs", v1654)

				s24 = v1651.is_inf and "inf" or v1655
				n41 = v1651.is_inf and 1 or v38.clamp(v1654 / v1651.duration, 0, 1)
			end

			local v1656 = v35.measure_text(t61.font.content, u188(), s24)

			v35.text(t61.font.content, vector(p514.x - v1656.x, p514.y), color(200, p513.alpha * 0.4), u188(), s24)
			v35.circle_outline(vector(p514.x - v1656.x - 7 * u187(), p514.y + 6 * u187()), color(0, p513.alpha / 3), 4 * u187(), 0, 1, u187())
			v35.circle_outline(vector(p514.x - v1656.x - 7 * u187(), p514.y + 6 * u187()), u183():alpha_modulate(p513.alpha), 4 * u187(), 0, n41, u187())
		end
	})
	t81:create({
		get = function(_)
			-- upvalues: u47 (ref), t124 (copy)
			local v1658 = u47.get("debug_panel")

			return v1658 and (v1658.features:get(5) and (t124:get_state_data() or not (ui.get_alpha() <= 0)))
		end,
		paint_title = function(p516, p517)
			-- upvalues: v35 (copy), t61 (copy), u188 (ref)
			local s25 = "Target"

			p516.size = v35.measure_text(t61.font.content, u188(), s25)
			v35.text(t61.font.content, p517, color(200, p516.alpha), u188(), s25)
		end,
		paint_value = function(p518, p519)
			-- upvalues: t124 (copy), v35 (copy), t61 (copy), u188 (ref)
			local v1664 = t124:get_state_data()
			local v1665 = v1664 and (v1664.target and v1664.target:get_name()) or "none"
			local v1666 = v35.measure_text(t61.font.content, u188(), v1665)

			v35.text(t61.font.content, vector(p519.x - v1666.x, p519.y), color(200, p518.alpha * 0.4), u188(), v1665)
		end
	})
end

t125.allow_on_use = t15.antiaim.options:switch("\v\f<sparkles>    \rAllow on use"):depend(t18.antiaim.options)
t125.avoid_backstab = t15.antiaim.options:switch("\v\f<knife-kitchen>    \rAvoid backstab"):depend(t18.antiaim.options)
t125.view = t15.antiaim.binds:combo("View", {
	[1] = "Local view",
	[2] = "At target"
})
t125.view:depend(t18.antiaim.options)

local t131 = {
	[1] = "Backward",
	[2] = "Forward",
	[3] = "Right",
	[4] = "Left"
}

t125.manual = t15.antiaim.binds:combo("Manual", t131, nil, function(p520)
	return {
		static = p520:switch("\v\f<lock>    \rStatic")
	}
end)
t125.manual:depend(t18.antiaim.options)
t125.freestanding = t15.antiaim.binds:switch("Freestand", false, nil, function(p521)
	return {
		static = p521:switch("\v\f<lock>    \rStatic")
	}
end)
t125.freestanding:depend(t18.antiaim.options)
t125.safe_head = t15.antiaim.options:switch("\v\f<stethoscope>    \rSafe head", false, nil, function(p522, p523)
	local t132 = {
		states = p522:listable("\v\f<wave-pulse>   \rStates", {
			[1] = "Air",
			[2] = "Stand",
			[3] = "Crouch"
		})
	}

	t132.options = p522:listable("\v\f<vial>   \rAir options", {
		[1] = "Zeus",
		[2] = "Knife"
	}):depend({
		[1] = nil,
		[2] = 1,
		[1] = t132.states
	})
	t132.height_difference = p522:slider("Height difference", 0, 100, 35, 1, function(p524)
		return p524 == 0 and "None" or p524
	end)
	p523:tooltip("\v\f<circle-info>   \rAllows to use safe presets on different states to hide head behind body")

	return t132, true
end):depend(t18.antiaim.options)

function v38.lerp(p525, p526, p527)
	return (p526 - p525) * p527 + p525
end

local function v355(p528, p529, p530)
	-- upvalues: v38 (copy)
	local v1683 = globals.realtime % p528 / p528
	local v1684 = v38.abs(v1683 * 2 - 1)

	return v38.lerp(p529, p530, v1684)
end
local function v356(p531, p532, p533)
	-- upvalues: v38 (copy)
	local v1688 = globals.realtime % p531 / p531

	return v38.lerp(p532, p533, v1688)
end
local function v357(p534, p535, p536)
	-- upvalues: v39 (copy), v38 (copy)
	local v1692 = p534 - 1
	local t133 = {}

	for i = 0, v1692 do
		v39.insert(t133, v38.lerp(p535, p536, i / v1692))
	end

	return t133
end

local t134 = {}
local t135 = {}
local t136 = {}

local function v361(p537, p538)
	-- upvalues: v39 (copy), t135 (copy), t136 (copy)
	v39.insert(t135, p537)
	t136[p537] = p538
end

v361("Manual", function(_)
	-- upvalues: t125 (copy), t14 (copy)
	return t125.manual.value ~= "Backward" or (t14.freestanding:get_override() or t14.freestanding:get())
end)
v361("Warmup", function(_)
	return entity.get_game_rules().m_bWarmupPeriod == true
end)
v361("Stand", function(p541, p542, p543)
	return p543 < 2 and (not p541.in_jump and (not not p542.on_ground and not (p542.anim_duck_amount >= 0.7)))
end)
v361("Air crouch", function(p544, p545, _)
	return p545.anim_duck_amount > 0.8 and (p544.in_jump or not p545.on_ground)
end)
v361("Air", function(p547, p548, _)
	return p548.anim_duck_amount < 0.8 and (p547.in_jump or not p548.on_ground)
end)
v361("Creeping", function(p550, p551, p552)
	return p551.anim_duck_amount > 0.8 and (not p550.in_jump and (not not p551.on_ground and not (p552 <= 2)))
end)
v361("Crouch", function(p553, p554, p555)
	return p554.anim_duck_amount > 0.8 and (not p553.in_jump and (not not p554.on_ground and not (p555 >= 2)))
end)
v361("Run", function(p556, p557, p558)
	-- upvalues: t14 (copy)
	return p558 > 2 and (not p556.in_jump and (not not p557.on_ground and not t14.slow_walk:get()))
end)
v361("Walk", function(p559, p560, _)
	-- upvalues: t14 (copy)
	return t14.slow_walk:get() and (not p559.in_jump and not not p560.on_ground)
end)

local u362 = nil

events.createmove(function(p562)
	-- upvalues: u362 (ref), t136 (copy), t127 (copy)
	u362 = nil

	local v1721 = entity.get_local_player()

	if v1721 ~= nil then
		local v1722 = v1721:get_anim_state()
		local v1723 = v1722.velocity:length()

		for k, v in next, t136 do
			local v1726 = v and v(p562, v1722, v1723)
			local v1727 = t127 and (t127[k] and (t127[k].force_break_lc and t127[k].force_break_lc.value))

			if v1726 and v1727 then
				u362 = k

				return
			end
		end

		return
	end
end)

function t134.get_states(_)
	-- upvalues: t135 (copy)
	return t135
end
function t134.get_active_state(_)
	-- upvalues: u362 (ref)
	return u362
end

t134.pitch = {
	names = {},
	callbacks = {},
	new = function(p565, p566, p567)
		-- upvalues: v39 (copy)
		v39.insert(p565.names, p566)
		p565.callbacks[p566] = p567
	end,
	init = function(p568)
		-- upvalues: v355 (copy), v342 (copy), v38 (copy)
		p568:new("None")
		p568:new("Sway", function(p569, p570, p571, p572, p573)
			-- upvalues: v355 (copy)
			return v355(p573, p569 and p571 or -p570, p569 and p572 or p570)
		end)
		p568:new("Static", function(_, p575, _, _, _)
			return p575
		end)

		local v1734 = v342()

		p568:new("Switch", function(p579, p580, p581, p582, p583)
			-- upvalues: v1734 (copy)
			return v1734(p583) and (p579 and p581 or p580) or (p579 and p582 or -p580)
		end)
		p568:new("Random", function(p584, p585, p586, p587, _)
			-- upvalues: v38 (copy)
			return v38.random(p584 and p586 or -p585, p584 and p587 or p585)
		end)
	end
}
t134.yaw = {
	names = {},
	callbacks = {},
	new = function(p589, p590, p591)
		-- upvalues: v39 (copy)
		v39.insert(p589.names, p590)
		p589.callbacks[p590] = p591
	end,
	init = function(p592)
		-- upvalues: v356 (copy), v355 (copy), v342 (copy), v38 (copy)
		p592:new("None", function(_, _, _, _, _)
			return 0
		end)
		p592:new("Spin", function(p598, p599, p600, p601, p602)
			-- upvalues: v356 (copy)
			return v356(p602, p598 and p600 or 0, p598 and p601 or p599)
		end)
		p592:new("Sway", function(p603, p604, p605, p606, p607)
			-- upvalues: v355 (copy)
			return v355(p607, p603 and p605 or 0, p603 and p606 or p604)
		end)
		p592:new("Static", function(_, p609, _, _, _)
			return p609
		end)

		local v1739 = v342()

		p592:new("Switch", function(p613, p614, p615, p616, p617)
			-- upvalues: v1739 (copy)
			return v1739(p617) and (p613 and p615 or p614) or (p613 and p616 or -p614)
		end)
		p592:new("Random", function(p618, p619, p620, p621, _)
			-- upvalues: v38 (copy)
			return v38.random(p618 and p620 or -p619, p618 and p621 or p619)
		end)
	end
}
t134.yaw:init()
t134.pitch:init()
t125.defensive_state = t15.antiaim.states:combo(" \v\f<person-walking>    \rState ## defensive", t134:get_states()):depend(t18.antiaim.defensive)

local t137 = {
	enabled = ui.find("Aimbot", "Anti Aim", "Angles", "Enabled"),
	pitch = ui.find("Aimbot", "Anti Aim", "Angles", "Pitch"),
	yaw = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw"),
	base = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw", "Base"),
	["yaw offset"] = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw", "Offset"),
	["yaw modifier"] = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw Modifier"),
	["modifier degree"] = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw Modifier", "Offset"),
	["body yaw"] = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw"),
	inverter = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Inverter"),
	["left limit"] = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Left Limit"),
	["right limit"] = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Right Limit"),
	options = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Options"),
	freestanding = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Freestanding"),
	hidden = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw", "Hidden"),
	break_doubletap = t14.double_tap.options,
	break_hideshots = t14.hide_shots.options
}

local function v364()
	-- upvalues: t14 (copy), t125 (copy)
	t14.avoid_backstab:override()

	if not t125.avoid_backstab.value then
		return
	end

	return t14.avoid_backstab:override(true)
end
local function v365()
	-- upvalues: v35 (copy), v37 (copy), u40 (ref), v39 (copy), v38 (copy)
	local v1740 = entity.get_local_player()

	if v1740 ~= nil then
		local v1741 = v1740:get_player_weapon()

		if v1741 ~= nil then
			if v1741:get_classname() ~= "CC4" then
				local v1742 = v35.camera_angles()
				local v1743 = vector():angles(v1742)
				local v1744 = v1740:get_eye_position()
				local v1745 = v37.trace_line(v1744, v1744 + v1743 * 200, v1740, 1174421515)

				if v1745.entity ~= nil then
					local v1746 = u40.lower(v1745.entity:get_classname())

					if v1746:match("weapon") or v1746:match("deagle") or v1746:match("door") or v1746:match("button") then
						return true
					end
				end

				if v1740.m_iTeamNum == 3 then
					local t138 = {
						[1] = 1337
					}

					entity.get_entities("CHostage", false, function(p623)
						-- upvalues: v39 (copy), t138 (copy), v1744 (copy)
						if p623.m_nHostageState ~= 3 then
							v39.insert(t138, p623.m_vecOrigin:dist(v1744))
						end
					end)
					entity.get_entities("CPlantedC4", false, function(p624)
						-- upvalues: v39 (copy), t138 (copy), v1744 (copy)
						v39.insert(t138, p624.m_vecOrigin:dist(v1744))
					end)

					if not (v38.min(unpack(t138)) < 125) then
						return false
					end

					return true
				end

				return false
			end

			return true
		end

		return
	end
end
local function v366(p625)
	-- upvalues: u349 (ref), t125 (copy), u47 (ref), v365 (copy), t14 (copy)
	u349 = t125.allow_on_use.value and (not u47.get("grenade_features").drop_all.value and (not v365() and p625.in_use))

	if u349 then
		p625.in_use = not p625.in_use
		t14.freestanding:override(false)
	end
end

local s26 = "Global"

local function v368()
	-- upvalues: t125 (copy), t15 (copy), t18 (copy), t134 (copy), pui (copy), t127 (copy)
	t125.defensive_safety = t15.antiaim.states:selectable("\v\f<shield>    \rSafety", {
		[1] = "Peek",
		[2] = "Safe head",
		[3] = "Low-ping target",
		[4] = "Disable modifier"
	})
	t125.defensive_safety:depend(t18.antiaim.defensive)

	for _, v in next, t134:get_states() do
		local t139 = {
			main = pui.create(t15.antiaim.main.par:name(), ("## Main › %s\n"):format(v), 2),
			yaw = pui.create(t15.antiaim.main.par:name(), ("## Yaw › %s\n"):format(v), 2),
			pitch = pui.create(t15.antiaim.main.par:name(), ("## Pitch › %s\n"):format(v), 2)
		}

		t127[v] = {
			force_break_lc = t15.antiaim.states:switch("\v\f<power-off>    \rBreak LC ##" .. v),
			pitch = t139.pitch:combo(" \v\f<arrows-up-down>    \rPitch", t134.pitch.names, nil, function(p626)
				return {
					min_max = p626:switch("\v\f<split>    \rMin Max")
				}
			end),
			pitch_delay = t139.pitch:slider(" \a[grey]\f<angle-right>    \rDelay\n", 1, 40, 1, 1, "t"),
			pitch_speed = t139.pitch:slider(" \a[grey]\f<angle-right>    \rSpeed", 1, 100, 10, 1, "ms"),
			pitch_offset = t139.pitch:slider(" \a[grey]\f<angle-right>    \rOffset", -89, 89, 0, 1, "°"),
			pitch_min_offset = t139.pitch:slider(" \a[grey]\f<angle-right>    \rMin", -89, 89, 0, 1, "°"),
			pitch_max_offset = t139.pitch:slider(" \a[grey]\f<angle-right>    \rMax", -89, 89, 0, 1, "°"),
			yaw = t139.yaw:combo("\v\f<arrows-left-right>   \rYaw", t134.yaw.names, nil, function(p627)
				return {
					min_max = p627:switch("\v\f<split>    \rMin Max")
				}
			end),
			yaw_delay = t139.yaw:slider(" \a[grey]\f<angle-right>    \rDelay\n", 1, 40, 1, 1, "t"),
			yaw_speed = t139.yaw:slider(" \a[grey]\f<angle-right>    \rSpeed\n", 1, 100, 10, 1, "ms"),
			yaw_offset = t139.yaw:slider(" \a[grey]\f<angle-right>    \rOffset\n", -180, 180, 0, 1, "°"),
			yaw_min_offset = t139.yaw:slider(" \a[grey]\f<angle-right>    \rMin\n", -180, 180, 0, 1, "°"),
			yaw_max_offset = t139.yaw:slider(" \a[grey]\f<angle-right>    \rMax\n", -180, 180, 0, 1, "°")
		}

		local t140 = {
			[1] = t125.defensive_state,
			[2] = v
		}
		local t141 = {
			[1] = t18.antiaim.defensive,
			[2] = t140
		}

		local function v1754(p628)
			-- upvalues: t127 (copy), v (copy)
			return function(...)
				-- upvalues: t127 (copy), v (copy), p628 (copy)
				local value = t127[v][p628].min_max.value

				if not value or t127[v][p628].value ~= "Static" then
					return value
				end

				return false
			end
		end
		local function v1755(p629)
			-- upvalues: t127 (copy), v (copy)
			return function(...)
				-- upvalues: t127 (copy), v (copy), p629 (copy)
				return t127[v][p629].value == "Static" or not t127[v][p629].min_max.value
			end
		end

		t127[v].force_break_lc:depend(unpack(t141))
		t127[v].pitch:depend(unpack(t141))
		t127[v].pitch.min_max:depend({
			[1] = nil,
			[2] = "None",
			[3] = true,
			[1] = t127[v].pitch
		}, {
			[1] = nil,
			[2] = "Static",
			[3] = true,
			[1] = t127[v].pitch
		}, unpack(t141))
		t127[v].pitch_delay:depend({
			[1] = nil,
			[2] = "Switch",
			[1] = t127[v].pitch
		}, unpack(t141))
		t127[v].pitch_speed:depend({
			[1] = nil,
			[2] = "Sway",
			[3] = "Spin",
			[1] = t127[v].pitch
		}, unpack(t141))
		t127[v].pitch_offset:depend({
			[1] = nil,
			[2] = "None",
			[3] = true,
			[1] = t127[v].pitch
		}, {
			t127[v].pitch.min_max,
			v1755("pitch")
		}, unpack(t141))
		t127[v].pitch_min_offset:depend({
			[1] = nil,
			[2] = "None",
			[3] = true,
			[1] = t127[v].pitch
		}, {
			t127[v].pitch.min_max,
			v1754("pitch")
		}, unpack(t141))
		t127[v].pitch_max_offset:depend({
			[1] = nil,
			[2] = "None",
			[3] = true,
			[1] = t127[v].pitch
		}, {
			t127[v].pitch.min_max,
			v1754("pitch")
		}, unpack(t141))
		t127[v].yaw:depend(unpack(t141))
		t127[v].yaw.min_max:depend({
			[1] = nil,
			[2] = "None",
			[3] = true,
			[1] = t127[v].yaw
		}, {
			[1] = nil,
			[2] = "Static",
			[3] = true,
			[1] = t127[v].yaw
		}, unpack(t141))
		t127[v].yaw_delay:depend({
			[1] = nil,
			[2] = "Switch",
			[1] = t127[v].yaw
		}, unpack(t141))
		t127[v].yaw_speed:depend({
			[1] = nil,
			[2] = "Sway",
			[3] = "Spin",
			[1] = t127[v].yaw
		}, unpack(t141))
		t127[v].yaw_offset:depend({
			[1] = nil,
			[2] = "None",
			[3] = true,
			[1] = t127[v].yaw
		}, {
			t127[v].yaw.min_max,
			v1755("yaw")
		}, unpack(t141))
		t127[v].yaw_min_offset:depend({
			[1] = nil,
			[2] = "None",
			[3] = true,
			[1] = t127[v].yaw
		}, {
			t127[v].yaw.min_max,
			v1754("yaw")
		}, unpack(t141))
		t127[v].yaw_max_offset:depend({
			[1] = nil,
			[2] = "None",
			[3] = true,
			[1] = t127[v].yaw
		}, {
			t127[v].yaw.min_max,
			v1754("yaw")
		}, unpack(t141))
	end
end
local function v369()
	-- upvalues: v368 (copy), t128 (copy), pui (copy), t15 (copy), t126 (copy), t129 (copy), u40 (ref), t124 (copy), PRO (copy), t1 (copy), u47 (ref), t18 (copy)
	v368()

	for _, v in next, t128 do
		local v1758 = pui.create(t15.antiaim.main.par:name(), "## Yaw:" .. v, 2)
		local v1759 = pui.create(t15.antiaim.main.par:name(), "## Desync:" .. v, 2)
		local v1760 = pui.create(t15.antiaim.main.par:name(), "## Extra:" .. v, 2)
		local v1761 = pui.create(t15.antiaim.main.par:name(), "## Anti-Brute:" .. v, 1)

		t126[v] = {
			enable = t129[v] ~= nil and t15.antiaim.states:switch("\v\f<check>    \rEnable ## " .. v) or nil,
			offset = v1758:slider("\v\f<ruler-triangle>   \rOffset", -180, 180, 0, 1, "°", function(p630)
				return {
					add_left = p630:slider("\v\f<arrow-left-long>    \rAdd left", -90, 90, 0, 1, "°"),
					add_right = p630:slider("\v\f<arrow-right-long>    \rAdd right", -90, 90, 0, 1, "°"),
					add_random = p630:slider("\v\f<shuffle>    \rAdd random", 0, 50, 0, 1, "°")
				}
			end),
			modifier = v1758:combo("\v\f<angle>    \rModifier", {
				[1] = "None",
				[2] = "Center",
				[3] = "Offset",
				[4] = "Random",
				[5] = "Spin",
				[6] = "Sway",
				[7] = "X-Way"
			}, nil, function(p631, _)
				return {
					min_max = p631:switch("\v\f<split>    \rMin Max")
				}
			end),
			ways = v1758:slider("  \a[grey]\f<angle-right>    \rWays", 3, 9, 3),
			speed = v1758:slider("  \a[grey]\f<angle-right>    \rSpeed", 1, 100, 50, 1, "%"),
			degree = v1758:slider("  \a[grey]\f<angle-right>    \rDegree", -180, 180, 0, 1, "°"),
			degree_min = v1758:slider("  \a[grey]\f<angle-right>    \rMin", -180, 180, 0, 1, "°"),
			degree_max = v1758:slider("  \a[grey]\f<angle-right>    \rMax", -180, 180, 0, 1, "°"),
			desync = v1759:switch("\v\f<wave-sine>   \rDesync", false, nil, function(p633)
				return {
					adaptive = p633:switch("\v\f<arrow-down-left-and-arrow-up-right-to-center>    \rAdaptive limits")
				}
			end),
			left = v1759:slider("  \a[grey]\f<angle-right>    \rLeft limit", 0, 58, 58, 1, "°"),
			right = v1759:slider("  \a[grey]\f<angle-right>    \rRight limit", 0, 58, 58, 1, "°"),
			left_max = v1759:slider("  \a[grey]\f<angle-right>    \rLeft max", 0, 100, 100, 1, function(p634)
				-- upvalues: u40 (ref)
				return p634 == 100 and "Max" or (p634 == 0 and "Min" or u40.format("%s%%", p634))
			end),
			right_max = v1759:slider("  \a[grey]\f<angle-right>    \rRight max", 0, 100, 100, 1, function(p635)
				-- upvalues: u40 (ref)
				return p635 == 100 and "Max" or (p635 == 0 and "Min" or u40.format("%s%%", p635))
			end),
			options = v1759:label("\v\f<wand-magic-sparkles>   \rOptions", nil, function(p636)
				return {
					jitter = p636:switch("\v\f<right-left>   \rJitter"),
					inverter = p636:switch("\v\f<location-arrow>    \rInverter"),
					custom_anti_brute = p636:switch("\v\f<layer-group>    \rAnti-Brute"),
					freestanding = p636:combo(" \v\f<arrow-left-to-line>    \rFreestanding", {
						[1] = "Off",
						[2] = "Peek Real",
						[3] = "Peek Fake"
					})
				}
			end),
			limitation = v1759:switch("\v\f<timer>    \rLimitation", false, nil, function(p637, p638)
				local t142 = {
					randomize = p637:switch("\v\f<shuffle>    \rRandomize"),
					min = p637:slider("  \a[grey]\f<angle-right>    \rMin", 1, 15, 2, 1, "t"),
					max = p637:slider("  \a[grey]\f<angle-right>    \rMax", 1, 15, 2, 1, "t")
				}

				t142.min:depend(t142.randomize)
				p638:tooltip("\v\f<circle-info>   \rThis function will slow down the jitter of your offset and body yaw.")

				return t142, true
			end),
			force_disable = v1760:selectable(" \v\f<xmark>    \rForce disable ## " .. v, {
				[1] = "Manual",
				[2] = "Freestand"
			}),
			antibrute_manager = v1761:label("\v\f<layer-group>    \rAnti-Brute Setup", nil, function(p639)
				-- upvalues: u40 (ref), t124 (copy)
				local t143 = {
					events = p639:selectable("\v\f<headphones>    \rEvents", {
						[1] = "On Miss",
						[2] = "On Hit"
					}),
					system = p639:combo("\v\f<microchip>    \rType", {
						[1] = "Circle",
						[2] = "Target"
					}),
					duration = p639:slider("\v\f<timer>    \rDuration", 0, 30, 0, 1, function(p640)
						-- upvalues: u40 (ref)
						if p640 ~= 0 then
							return u40("%ss", p640)
						end

						return "inf"
					end),
					phase_label = p639:label("\v\f<layer-group>    \rPhase"),
					create_phase = p639:button("   \v\f<plus-large>   ", nil, true),
					delete_phase = p639:button("   \v\f<dash>   ", nil, true),
					counter = p639:slider("Counter", t124.limits.min, t124.limits.max)
				}

				t143.create_phase:tooltip("\v\f<circle-info>   \rCreate phase")
				t143.delete_phase:tooltip("\v\f<circle-info>   \rDelete phase")
				t143.counter:visibility(false)

				return t143
			end)
		}

		if PRO ~= t1.PRO and PRO ~= t1.TRIAL then
			t126[v].options.custom_anti_brute:disabled(true)
			t126[v].options.custom_anti_brute:set_callback(function(p641)
				if p641[0].type == "switch" then
					p641:set(false)
				end
			end, true)
		end

		t126[v].antibrute_manager.create_phase:set_callback(function()
			-- upvalues: t126 (copy), v (copy), t124 (copy)
			if t126[v].antibrute_manager.counter.value < t124.limits.max then
				t126[v].antibrute_manager.counter:set(t126[v].antibrute_manager.counter.value + 1)
			end
		end)
		t126[v].antibrute_manager.delete_phase:set_callback(function()
			-- upvalues: t126 (copy), v (copy), t124 (copy)
			if t126[v].antibrute_manager.counter.value > t124.limits.min then
				t126[v].antibrute_manager.counter:set(t126[v].antibrute_manager.counter.value - 1)
			end
		end)
		t126[v].phases = {}

		local t144 = {
			[1] = u47.get("states"),
			[2] = v
		}
		local v1763 = t129[v] ~= nil and {
			[1] = nil,
			[2] = true,
			[1] = t126[v].enable
		} or nil

		if t129[v] ~= nil then
			t126[v].enable:depend(t18.antiaim.builder, t144)
		end

		local t145 = {
			[1] = t18.antiaim.builder,
			[2] = t144,
			[3] = v1763
		}
		local t146 = {
			[1] = t18.antiaim.builder,
			[2] = t144,
			[3] = v1763,
			[4] = t126[v].options.custom_anti_brute
		}

		t126[v].antibrute_manager:depend(unpack(t146))

		for i = 1, t124.limits.max do
			(function(p642, p643)
				-- upvalues: t126 (copy), v (copy), v1761 (copy), u40 (ref)
				t126[v].phases[p642] = v1761:label(u40("  \a[grey]\f<angle-right>    \rPhase  \v%s", p642), nil, function(p644)
					-- upvalues: u40 (ref), t126 (copy), v (copy)
					local t147 = {
						offset = p644:slider("\v\f<ruler-triangle>   \rOffset", -180, 180, 0, 1, "°"),
						offset_add_left = p644:slider("  \a[grey]\f<angle-right>    \rAdd left", -90, 90, 0, 1, "°"),
						offset_add_right = p644:slider("  \a[grey]\f<angle-right>    \rAdd right", -90, 90, 0, 1, "°"),
						offset_add_random = p644:slider("  \a[grey]\f<angle-right>    \rAdd random", 0, 50, 0, 1, "°"),
						modifier = p644:combo("\v\f<angle>    \rModifier", {
							[1] = "None",
							[2] = "Center",
							[3] = "Offset",
							[4] = "Random",
							[5] = "Spin",
							[6] = "Sway",
							[7] = "X-Way"
						}),
						modifier_min_max = p644:switch("  \a[grey]\f<angle-right>    \rMin Max"),
						modifier_ways = p644:slider("  \a[grey]\f<angle-right>    \rWays", 3, 9, 3),
						modifier_speed = p644:slider("  \a[grey]\f<angle-right>    \rSpeed", 1, 100, 50, 1, "%"),
						modifier_degree = p644:slider("  \a[grey]\f<angle-right>    \rDegree", -180, 180, 0, 1, "°"),
						modifier_degree_min = p644:slider("  \a[grey]\f<angle-right>    \rMin", -180, 180, 0, 1, "°"),
						modifier_degree_max = p644:slider("  \a[grey]\f<angle-right>    \rMax", -180, 180, 0, 1, "°"),
						desync = p644:label("\v\f<wave-sine>   \rDesync"),
						options_jitter = p644:switch("  \a[grey]\f<angle-right>    \rJitter"),
						options_inverter = p644:switch("  \a[grey]\f<angle-right>    \rInverter"),
						desync_left = p644:slider("  \a[grey]\f<angle-right>    \rLeft limit", 0, 58, 58, 1, "°"),
						desync_right = p644:slider("  \a[grey]\f<angle-right>    \rRight limit", 0, 58, 58, 1, "°"),
						desync_left_max = p644:slider("  \a[grey]\f<angle-right>    \rLeft max", 0, 100, 100, 1, function(p645)
							-- upvalues: u40 (ref)
							return p645 == 100 and "Max" or (p645 == 0 and "Min" or u40.format("%s%%", p645))
						end),
						desync_right_max = p644:slider("  \a[grey]\f<angle-right>    \rRight max", 0, 100, 100, 1, function(p646)
							-- upvalues: u40 (ref)
							return p646 == 100 and "Max" or (p646 == 0 and "Min" or u40.format("%s%%", p646))
						end),
						limitation = p644:switch("\v\f<timer>    \rLimitation"),
						limitation_randomize = p644:switch("  \a[grey]\f<angle-right>    \rRandomize"),
						limitation_min = p644:slider("  \a[grey]\f<angle-right>    \rMin", 1, 15, 2, 1, "t"),
						limitation_max = p644:slider("  \a[grey]\f<angle-right>    \rMax", 1, 15, 2, 1, "t")
					}

					t147.modifier_min_max:depend({
						[1] = nil,
						[2] = "None",
						[3] = true,
						[1] = t147.modifier
					})
					t147.modifier_degree:depend({
						[1] = nil,
						[2] = "None",
						[3] = true,
						[1] = t147.modifier
					}, {
						[1] = nil,
						[2] = false,
						[1] = t147.modifier_min_max
					})
					t147.modifier_degree_min:depend({
						[1] = nil,
						[2] = "None",
						[3] = true,
						[1] = t147.modifier
					}, {
						[1] = nil,
						[2] = true,
						[1] = t147.modifier_min_max
					})
					t147.modifier_degree_max:depend({
						[1] = nil,
						[2] = "None",
						[3] = true,
						[1] = t147.modifier
					}, {
						[1] = nil,
						[2] = true,
						[1] = t147.modifier_min_max
					})
					t147.modifier_speed:depend({
						[1] = nil,
						[2] = "Spin",
						[3] = "Sway",
						[1] = t147.modifier
					})
					t147.modifier_ways:depend({
						[1] = nil,
						[2] = "X-Way",
						[1] = t147.modifier
					})
					t147.desync:depend(t126[v].desync)
					t147.desync_left:depend(t126[v].desync, {
						[1] = nil,
						[2] = false,
						[1] = t126[v].desync.adaptive
					})
					t147.desync_right:depend(t126[v].desync, {
						[1] = nil,
						[2] = false,
						[1] = t126[v].desync.adaptive
					})
					t147.desync_left_max:depend(t126[v].desync, {
						[1] = nil,
						[2] = true,
						[1] = t126[v].desync.adaptive
					})
					t147.desync_right_max:depend(t126[v].desync, {
						[1] = nil,
						[2] = true,
						[1] = t126[v].desync.adaptive
					})
					t147.options_jitter:depend(t126[v].desync)
					t147.options_inverter:depend(t126[v].desync)
					t147.limitation_randomize:depend(t147.limitation)
					t147.limitation_min:depend(t147.limitation, t147.limitation_randomize)
					t147.limitation_max:depend(t147.limitation)

					return t147
				end)
				t126[v].phases[p642]:depend({
					[1] = t126[v].antibrute_manager.counter,
					[2] = function(p647)
						-- upvalues: p642 (copy)
						return not (p642 > p647.value)
					end
				}, unpack(p643))
			end)(i, t146)
		end

		t126[v].force_disable:depend(unpack(t145))
		t126[v].offset:depend(unpack(t145))
		t126[v].modifier:depend(unpack(t145))
		t126[v].modifier.min_max:depend({
			[1] = nil,
			[2] = "None",
			[3] = true,
			[1] = t126[v].modifier
		}, unpack(t145))
		t126[v].degree:depend({
			[1] = nil,
			[2] = "None",
			[3] = true,
			[1] = t126[v].modifier
		}, {
			[1] = nil,
			[2] = false,
			[1] = t126[v].modifier.min_max
		}, unpack(t145))
		t126[v].degree_min:depend({
			[1] = nil,
			[2] = "None",
			[3] = true,
			[1] = t126[v].modifier
		}, {
			[1] = nil,
			[2] = true,
			[1] = t126[v].modifier.min_max
		}, unpack(t145))
		t126[v].degree_max:depend({
			[1] = nil,
			[2] = "None",
			[3] = true,
			[1] = t126[v].modifier
		}, {
			[1] = nil,
			[2] = true,
			[1] = t126[v].modifier.min_max
		}, unpack(t145))
		t126[v].speed:depend({
			[1] = nil,
			[2] = "Spin",
			[3] = "Sway",
			[1] = t126[v].modifier
		}, unpack(t145))
		t126[v].ways:depend({
			[1] = nil,
			[2] = "X-Way",
			[1] = t126[v].modifier
		}, unpack(t145))
		t126[v].desync:depend(unpack(t145))
		t126[v].desync.adaptive:depend({
			[1] = nil,
			[2] = true,
			[1] = t126[v].desync
		}, unpack(t145))
		t126[v].left:depend({
			[1] = nil,
			[2] = true,
			[1] = t126[v].desync
		}, {
			[1] = nil,
			[2] = false,
			[1] = t126[v].desync.adaptive
		}, unpack(t145))
		t126[v].right:depend({
			[1] = nil,
			[2] = true,
			[1] = t126[v].desync
		}, {
			[1] = nil,
			[2] = false,
			[1] = t126[v].desync.adaptive
		}, unpack(t145))
		t126[v].left_max:depend({
			[1] = nil,
			[2] = true,
			[1] = t126[v].desync
		}, {
			[1] = nil,
			[2] = true,
			[1] = t126[v].desync.adaptive
		}, unpack(t145))
		t126[v].right_max:depend({
			[1] = nil,
			[2] = true,
			[1] = t126[v].desync
		}, {
			[1] = nil,
			[2] = true,
			[1] = t126[v].desync.adaptive
		}, unpack(t145))
		t126[v].options:depend({
			[1] = nil,
			[2] = true,
			[1] = t126[v].desync
		}, unpack(t145))
		t126[v].limitation:depend(unpack(t145))
	end
end

local t148 = {
	Forward = 180,
	Backward = 0,
	Right = 90,
	Left = -90
}

local function v371()
	local v1767 = entity.get_threat()

	if v1767 then
		if not v1767:is_bot() then
			local v1768 = v1767:get_resource()

			if v1768 then
				local m_iPing = v1768.m_iPing

				if m_iPing then
					return not (m_iPing >= 30)
				end

				return
			end

			return
		end

		return
	end
end

local t149 = {}
local t150 = {}

v39.insert(t150, {
	setts = {
		base = "at target",
		enabled = true,
		freestanding = "Off",
		yaw = "backward",
		["right limit"] = 0,
		pitch = "down",
		["left limit"] = 0,
		inverter = true,
		["body yaw"] = true,
		["yaw modifier"] = "Disabled",
		["yaw offset"] = 0,
		options = {}
	},
	callback = function(p648, p649, p650, _)
		-- upvalues: t125 (copy), v78 (copy)
		local v1774 = p649:get_player_weapon()
		local v1775 = t125.safe_head.options:get(1) and (v1774 ~= nil and v1774:get_classname() == "CWeaponTaser")
		local v1776 = t125.safe_head.options:get(2) and (v1774 ~= nil and v1774:get_classname() == "CKnife")

		return t125.safe_head.states:get(1) and ((not not v78(p649, t125.safe_head.height_difference.value) or (not not v1775 or v1776)) and (p648.in_jump or not p650.on_ground))
	end
})
v39.insert(t150, {
	setts = {
		base = "at target",
		enabled = true,
		freestanding = "Off",
		yaw = "backward",
		["right limit"] = 0,
		pitch = "down",
		["left limit"] = 0,
		inverter = false,
		["body yaw"] = true,
		["yaw modifier"] = "Disabled",
		["yaw offset"] = 0,
		options = {
			[1] = "Jitter"
		}
	},
	callback = function(p652, p653, p654, p655)
		-- upvalues: t125 (copy), v78 (copy)
		return t125.safe_head.states:get(2) and (v78(p653, t125.safe_head.height_difference.value) and (p654.on_ground and (p655 < 2 and not p652.in_duck)))
	end
})
v39.insert(t150, {
	setts = {
		base = "at target",
		enabled = true,
		freestanding = "Off",
		yaw = "backward",
		["right limit"] = 0,
		pitch = "down",
		["left limit"] = 0,
		inverter = true,
		["body yaw"] = true,
		["yaw modifier"] = "Disabled",
		["yaw offset"] = 0,
		options = {}
	},
	callback = function(p656, p657, p658, _)
		-- upvalues: t125 (copy), v78 (copy)
		return t125.safe_head.states:get(3) and (v78(p657, t125.safe_head.height_difference.value) and (p658.on_ground and p656.in_duck))
	end
})

function t149.get(p660)
	-- upvalues: t150 (copy)
	local v1786 = entity.get_local_player()

	if v1786 then
		local v1787 = v1786:get_anim_state()

		if v1787 then
			local v1788 = v1787.velocity:length()

			for _, v in next, t150 do
				if v.callback(p660, v1786, v1787, v1788) then
					return true, v.setts
				end
			end

			return false, {}
		end

		return
	end
end

local t151 = {
	degree = "modifier_degree",
	degree_max = "modifier_degree_max",
	modifier = "modifier",
	left_max = "desync_left_max",
	right = "desync_right",
	degree_min = "modifier_degree_min",
	left = "desync_left",
	["limitation.min"] = "limitation_min",
	["limitation.randomize"] = "limitation_randomize",
	ways = "modifier_ways",
	["options.jitter"] = "options_jitter",
	["modifier.min_max"] = "modifier_min_max",
	["offset.add_random"] = "offset_add_random",
	speed = "modifier_speed",
	["offset.add_left"] = "offset_add_left",
	["options.inverter"] = "options_inverter",
	["offset.add_right"] = "offset_add_right",
	["limitation.max"] = "limitation_max",
	limitation = "limitation",
	offset = "offset",
	right_max = "desync_right_max"
}

local function v375(p661, p662)
	-- upvalues: t14 (copy), t137 (copy), t124 (copy), t151 (copy), t126 (copy), t125 (copy), t149 (copy), u349 (ref), t4 (ref), v38 (copy), u338 (ref), v37 (copy), v356 (copy), v355 (copy), v357 (copy), u341 (ref), t148 (copy), t134 (copy), t127 (copy), v371 (copy)
	t14.freestanding.yaw:override()
	t14.freestanding.body:override()

	local function u1800(p663, p664, p665)
		-- upvalues: u1800 (ref), t137 (copy)
		if type(p663) ~= "table" then
			local v2069 = t137[p663]

			if not p665 then
				v2069:disabled(true)
			end

			v2069:override(p664())

			return
		end

		for k, v in next, p663 do
			u1800(k, function()
				-- upvalues: v (copy)
				return v
			end)
		end
	end
	local function v1801(p666, p667)
		-- upvalues: t124 (copy), p662 (copy), t151 (copy), t126 (copy)
		local v2074 = p667 and p666 .. "." .. p667 or p666
		local v2075 = t124:get_state_data(p662)

		if v2075 and (v2075.phase and v2075.phase > 0) then
			local phase = v2075.phase
			local v2077 = t151[v2074]

			if v2077 and t126[p662].phases[phase][v2077] then
				return t126[p662].phases[phase][v2077].value
			end
		end

		if not p667 then
			return t126[p662][p666].value
		end

		return t126[p662][p666][p667].value
	end

	local n42 = 0
	local v1803 = t126[p662].force_disable:get(1) and "Backward" or t125.manual.value
	local v1804, v1805 = t149.get(p661)
	local v1806 = v1803 == "Left" or (v1803 == "Right" or v1803 == "Forward")

	if t125.freestanding.static.value and (t125.freestanding.value or (t14.freestanding:get_override() or t14.freestanding:get())) then
		t14.freestanding.yaw:override(true)
		t14.freestanding.body:override(true)
	end

	if not t125.freestanding.value or t126[p662].force_disable:get(2) or u349 or v1803 == "Left" or v1803 == "Right" then
		if (v1803 == "Left" or v1803 == "Right") and (t14.freestanding:get_override() or t14.freestanding:get()) then
			t14.freestanding:override(false)
		end
	else
		t14.freestanding:override(true)
	end

	if t126[p662].force_disable:get(2) and (t14.freestanding:get_override() or t14.freestanding:get()) then
		t14.freestanding:override(false)
	end

	t4.safe_head = false

	if not t125.safe_head.value or not v1804 or v1806 or u349 then
		local n43 = 0

		if v1801("limitation") then
			if not v1801("limitation", "randomize") then
				n43 = v1801("limitation", "max")
			else
				n43 = v38.random(v1801("limitation", "min"), v1801("limitation", "max"))
			end
		end

		local v1808 = u338(n43)

		u1800("enabled", function()
			return true
		end)
		u1800("yaw", function()
			return "backward"
		end)
		u1800("pitch", function()
			-- upvalues: u349 (ref)
			return u349 and "disabled" or "down"
		end)
		u1800("base", function()
			-- upvalues: u349 (ref), v1803 (copy), t125 (copy)
			if not u349 and v1803 ~= "Left" and v1803 ~= "Right" and v1803 ~= "Forward" then
				return t125.view.value
			end

			return "local view"
		end)
		u1800("yaw modifier", function()
			return "Disabled"
		end)

		local v1809 = t125.manual.static.value and (v1803 == "Left" or v1803 == "Right")

		u1800("yaw offset", function()
			-- upvalues: v37 (copy), v1801 (copy), v1808 (copy), v38 (copy), v356 (copy), v355 (copy), v357 (copy), u341 (ref), n42 (ref), u349 (ref), v1803 (copy), t148 (copy), t125 (copy)
			local t152 = {}

			local function v2079(p668, p669)
				-- upvalues: t152 (copy)
				t152[p668] = type(p669) == "function" and p669() or p669
			end

			local v2080 = v37.random_int(v1801("offset", "add_random"), -v1801("offset", "add_random"))
			local v2081 = v1801("offset") + v2080 + (rage.antiaim:inverter() and v1801("offset", "add_right") or v1801("offset", "add_left"))
			local v2082 = v1801("modifier", "min_max") and v1801("degree_min") or v1801("degree")
			local v2083 = v1801("modifier", "min_max") and v1801("degree_max") or -v1801("degree")

			v2079("Center", v1808 and v2082 or v2083)
			v2079("Offset", function()
				-- upvalues: v2082 (copy), v1801 (copy), v2083 (copy), v1808 (copy)
				local v2136 = v2082
				local v2137 = v1801("modifier", "min_max") and v2083 or 0

				return v1808 and v2136 or v2137
			end)
			v2079("Random", v38.random(v2083, v2082))
			v2079("Spin", v356(v1801("speed") / 100, v2082, v2083))
			v2079("Sway", v355(v1801("speed") / 100, v2082, v2083))
			v2079("X-Way", function()
				-- upvalues: v357 (copy), v1801 (copy), v2082 (copy), v2083 (copy), u341 (ref)
				local v2138 = v357(v1801("ways"), v2082, v2083)

				return v2138[u341(#v2138)]
			end)
			n42 = v2081 + (t152[v1801("modifier")] or 0)

			if not u349 then
				if v1803 ~= "Left" and v1803 ~= "Right" then
					return t148[v1803] + v2081 + (t152[v1801("modifier")] or 0)
				end

				return t148[v1803] + (t125.manual.static.value and 0 or v2081 + (t152[v1801("modifier")] or 0))
			end

			return 180 + v2081 + (t152[v1801("modifier")] or 0)
		end)
		u1800("body yaw", function()
			-- upvalues: v1801 (copy)
			return v1801("desync")
		end)
		u1800("inverter", function()
			-- upvalues: v1809 (copy), v1801 (copy), v1808 (copy)
			if v1809 or not v1801("options", "jitter") then
				return v1801("options", "inverter")
			end

			return v1808
		end)

		local v1810 = rage.antiaim:get_max_desync()

		local function v1811()
			-- upvalues: v1801 (copy), v1810 (copy)
			local v2084 = v1801("desync", "adaptive") and v1801("left_max") or v1801("left")
			local v2085 = v1801("desync", "adaptive") and v1801("right_max") or v1801("right")

			if v1801("desync", "adaptive") then
				v2084 = v1810 * (v2084 / 100)
				v2085 = v1810 * (v2085 / 100)
			end

			return v2084, v2085
		end

		u1800("left limit", function()
			-- upvalues: v1811 (copy)
			local v2086, _ = v1811()

			return v2086
		end)
		u1800("right limit", function()
			-- upvalues: v1811 (copy)
			local _, v2089 = v1811()

			return v2089
		end)
		u1800("options", function()
			return {}
		end)
		u1800("freestanding", function()
			-- upvalues: v1801 (copy)
			return v1801("options", "freestanding")
		end)
	else
		u1800(v1805)
		t4.safe_head = true
	end

	local v1812 = t134:get_active_state()
	local defensive_safety = t125.defensive_safety

	if v1812 ~= nil then
		function d_get(p670, p671)
			-- upvalues: t127 (copy), v1812 (copy)
			if not p671 then
				return t127[v1812][p670].value
			end

			return t127[v1812][p670][p671].value
		end

		break_lc_state = d_get("force_break_lc")

		local v1814 = d_get("yaw")
		local v1815 = t134.yaw.callbacks[v1814]

		if v1815 then
			local v1816 = d_get("yaw", "min_max")
			local v1817 = d_get("yaw_speed")
			local v1818 = d_get("yaw_delay")
			local v1819 = v1815(v1816, d_get("yaw_offset"), d_get("yaw_min_offset"), d_get("yaw_max_offset"), v1814 == "Switch" and v1818 or v1817 * 0.01)

			rage.antiaim:override_hidden_yaw_offset((defensive_safety:get(4) and n42 or 0) - v1819)
		end

		local v1820 = d_get("pitch")
		local v1821 = t134.pitch.callbacks[v1820]

		if v1821 then
			local v1822 = d_get("pitch", "min_max")
			local v1823 = d_get("pitch_speed")
			local v1824 = d_get("pitch_delay")
			local v1825 = v1821(v1822, d_get("pitch_offset"), d_get("pitch_min_offset"), d_get("pitch_max_offset"), v1820 == "Switch" and v1824 or v1823 * 0.01)

			rage.antiaim:override_hidden_pitch(v1825)
		end
	end

	u1800("hidden", function()
		-- upvalues: v1803 (copy), t125 (copy), defensive_safety (copy), v371 (copy), t4 (ref), t14 (copy), v1812 (copy)
		local v2092 = v1803 == "Left" or (v1803 == "Right" or t125.freestanding.value)
		local v2093 = defensive_safety:get(3) and v371()
		local v2094 = defensive_safety:get(2) and t4.safe_head
		local v2095 = (t14.double_tap.options:get_override() or t14.double_tap.options:get()) == "Always On" or (t14.hide_shots.options:get_override() or t14.hide_shots.options:get()) == "Break LC"
		local v2096 = v1812 ~= nil and ((not v2092 or t4.state == "Manual") and (not v2093 and not v2094))

		if not defensive_safety:get(1) then
			return v2096
		end

		return v2096 and (v2095 and break_lc_state)
	end)
	u1800("break_doubletap", function()
		-- upvalues: v1812 (copy)
		if break_lc_state ~= true or v1812 == nil then
			return
		end

		return "always on"
	end, true)
	u1800("break_hideshots", function()
		-- upvalues: v1812 (copy)
		if break_lc_state ~= true or v1812 == nil then
			return
		end

		return "break lc"
	end, true)
end
local function v376(p672, p673)
	-- upvalues: v39 (copy), t128 (copy), t129 (copy)
	v39.insert(t128, p672)
	t129[p672] = p673
end;

(function()
	-- upvalues: v376 (copy), s26 (copy), u349 (ref), t125 (copy), t14 (copy), u47 (ref), t15 (copy), t128 (copy), t127 (copy), t126 (copy), t18 (copy), v369 (copy)
	v376(s26)
	v376("On use", function(_)
		-- upvalues: u349 (ref)
		return u349
	end)
	v376("Manual", function(_)
		-- upvalues: t125 (copy), t14 (copy)
		return t125.manual.value ~= "Backward" or (t14.freestanding:get_override() or t14.freestanding:get())
	end)
	v376("Warmup", function(_)
		return entity.get_game_rules().m_bWarmupPeriod == true
	end)
	v376("No exploit", function(_)
		-- upvalues: t14 (copy)
		return not t14.double_tap:get() and not t14.hide_shots:get()
	end)
	v376("Stand", function(p678, p679, p680)
		return p680 < 2 and (not p678.in_jump and (not not p679.on_ground and not (p679.anim_duck_amount >= 0.7)))
	end)
	v376("Air crouch", function(p681, p682, _)
		return p682.anim_duck_amount > 0.8 and (p681.in_jump or not p682.on_ground)
	end)
	v376("Air", function(p684, p685, _)
		return p685.anim_duck_amount < 0.8 and (p684.in_jump or not p685.on_ground)
	end)
	v376("Creeping", function(p687, p688, p689)
		return p688.anim_duck_amount > 0.8 and (not p687.in_jump and (not not p688.on_ground and not (p689 <= 2)))
	end)
	v376("Crouch", function(p690, p691, p692)
		return p691.anim_duck_amount > 0.8 and (not p690.in_jump and (not not p691.on_ground and not (p692 >= 2)))
	end)
	v376("Run", function(p693, p694, p695)
		-- upvalues: t14 (copy)
		return p695 > 2 and (not p693.in_jump and (not not p694.on_ground and not t14.slow_walk:get()))
	end)
	v376("Walk", function(p696, p697, _)
		-- upvalues: t14 (copy)
		return t14.slow_walk:get() and (not p696.in_jump and not not p697.on_ground)
	end)
	u47.new("states", t15.antiaim.states:combo(" \v\f<person-walking>    \rState", t128, nil, function(p699, p700)
		-- upvalues: u47 (ref), t127 (copy), t126 (copy)
		local t153 = {
			_export = p699:button("      \v\f<file-export>    \rCopy      ", nil, true),
			_import = p699:button("      \v\f<file-import>    \rPaste      ", nil, true),
			_reset = p699:button("      \v\f<rotate-right>    \rReset      ", function()
				-- upvalues: u47 (ref), t127 (copy), t126 (copy), p700 (copy)
				local v2139 = u47.get("antiaim:subtab").value == 3 and t127 or t126

				for _, v in next, v2139[p700.value] do
					pcall(v.reset, v)
				end
			end, true),
			log = p699:label(">.<")
		}

		t153.log:visibility(false)
		t153._reset:tooltip("\v\f<circle-info>  \rYou can reset the current state to the default values")

		return t153
	end), t18.antiaim.builder)
	v369()
end)()

local u377 = s26

events.createmove(function(p701)
	-- upvalues: s26 (copy), t128 (copy), t129 (copy), t126 (copy), t4 (ref), u377 (ref), v366 (copy), v364 (copy), v375 (copy)
	local v1829 = entity.get_local_player()

	if v1829 ~= nil then
		local v1830 = v1829:get_anim_state()
		local v1831 = v1830.velocity:length()
		local v1832 = s26

		for _, v in next, t128 do
			local v1835 = t129[v]
			local v1836 = t126[v].enable and t126[v].enable.value

			if v1835 and v1835(p701, v1830, v1831) and v1836 then
				v1832 = v

				break
			end
		end

		t4.state = v1832
		u377 = v1832
		v366(p701)
		v364()
		v375(p701, v1832)

		return
	end
end)

local function v378(p702, p703)
	-- upvalues: clipboard (copy), s1 (copy), base64 (copy), t22 (copy)
	local v1839 = p703 and "def_states" or "states"
	local ok = pcall(function()
		-- upvalues: clipboard (copy), s1 (copy), p702 (copy), base64 (copy), t22 (copy), v1839 (copy)
		clipboard.set((s1 .. "[%s]>%s<"):format(p702, base64.encode(json.stringify(t22.package:save("antiaim", v1839, p702)))))
	end)
	local v1841 = p703 and "defensive" or "legacy"

	return ok and ("\v\f<badge-check>  %s \r%s preset successfully copied"):format(p702, v1841) or ("\v\f<triangle-exclamation>  \rFailed to copy \v%s \rpreset"):format(p702)
end
local function v379(p704, p705)
	-- upvalues: base64 (copy), clipboard (copy), t22 (copy)
	local ok, result = pcall(function()
		-- upvalues: base64 (copy), clipboard (copy), p705 (copy), p704 (copy), t22 (copy)
		local v2125 = json.parse(base64.decode(clipboard.get():match(">(.-)<")))
		local v2126 = clipboard.get():match("%[(.-)%]")
		local v2127 = p705 and "def_states" or "states"

		if v2125.antiaim[v2127][v2126].enable == nil then
			v2125.antiaim[v2127][v2126].enable = true
		end

		local t154 = {
			antiaim = {
				[v2127] = {
					[p704] = v2125.antiaim[v2127][v2126]
				}
			}
		}

		t22.package:load(t154, "antiaim", v2127, p704)

		return v2126
	end)
	local v1846 = p705 and "defensive" or "legacy"

	return ok and ("\v\f<badge-check>  %s \r%s preset successfully imported to \v%s"):format(result, v1846, p704) or "\v\f<triangle-exclamation>  \rFailed to import this preset"
end
local function v380(p706, p707, p708)
	-- upvalues: v37 (copy)
	p706:name(p708)
	p706:visibility(true)
	v37.execute_after(p707, function()
		-- upvalues: p706 (copy)
		p706:visibility(false)
	end)
end

u47.get("states")._export:set_callback(function()
	-- upvalues: v378 (copy), u47 (ref), v380 (copy)
	local v1850 = v378(u47.get("states").value, u47.get("antiaim:subtab").value == 3)

	v380(u47.get("states").log, 2, v1850)
end)
u47.get("states")._import:set_callback(function()
	-- upvalues: v379 (copy), u47 (ref), v380 (copy)
	local v1851 = v379(u47.get("states").value, u47.get("antiaim:subtab").value == 3)

	v380(u47.get("states").log, 2, v1851)
end)
t4.elements = t125
t4.states = t126
t4.def_states = t127
t14.movement = ui.find("Aimbot", "Anti Aim", "Misc", "Leg Movement")

local v381 = ffi.typeof("        struct {\t\t\t\t\t\t\t\t\t\tchar pad_0x0000[0x18];\n            int\tsequence;\n            float\t\tprev_cycle;\n            float\t\tweight;\n            float\t\tweight_delta_rate;\n            float\t\tplayback_rate;\n            float\t\tcycle;\n            void\t\t*entity;\t\t\t\t\t\tchar pad_0x0038[0x4];\n        } **\n    ")
local v382 = t15.antiaim.options:switch("\v\f<seedling>     \rAnim. breaker", false, nil, function(p709)
	local t155 = {
		air = p709:combo("\v\f<arrow-up>    \rAir", {
			[1] = "None",
			[2] = "Static",
			[3] = "Walking"
		}),
		move = p709:combo("\v\f<arrow-down>    \rGround", {
			[1] = "None",
			[2] = "Slide",
			[3] = "Shake",
			[4] = "Walking"
		}),
		other = p709:selectable("\v\f<code-compare>    \rOther", {
			[1] = "Flashed",
			[2] = "Move lean",
			[3] = "Landing pitch",
			[4] = "Static creeping"
		})
	}

	t155.lean_weight = p709:slider("  \a[grey]\f<angle-right>     \rLean weight", 0, 100, 100, 1, "%"):depend({
		[1] = nil,
		[2] = "Move lean",
		[1] = t155.other
	})

	return t155, true
end)

u47.new("anim_breaker", v382, t18.antiaim.options)
v382:set_event("post_update_clientside_animation", function(p710)
	-- upvalues: t14 (copy), v381 (copy), v382 (copy)
	local v1855 = entity.get_local_player()

	if p710 == v1855 then
		t14.movement:override()

		local v1856 = ffi.cast(v381, ffi.cast("uintptr_t", p710[0]) + 10640)[0]
		local v1857 = v1855:get_anim_state()
		local v1858 = not v1857.on_ground

		if v382.move.value == "Slide" then
			t14.movement:override("Sliding")
			v1855.m_flPoseParameter[0] = 0
		end

		if v382.move.value == "Walking" then
			t14.movement:override("Walking")
			v1855.m_flPoseParameter[7] = 0
		end

		if v382.move.value == "Shake" then
			t14.movement:override("Sliding")
			v1855.m_flPoseParameter[0] = globals.tickcount % 4 > 1 and 0.5 or 0
		end

		if v382.air.value == "Static" then
			v1855.m_flPoseParameter[6] = 1
		end

		if v382.air.value == "Walking" and v1858 then
			v1856[6].weight = 1
			v1855.m_flPoseParameter[7] = 0
		end

		if v382.other:get(1) then
			v1856[0].sequence = 227
		end

		if v382.other:get(2) then
			v1856[12].weight = v382.lean_weight.value * 0.01
		end

		if v382.other:get(3) and v1857.landing and not v1858 then
			v1855.m_flPoseParameter[12] = 0.5
		end

		if v382.other:get(4) then
			v1855.m_flPoseParameter[8] = 0
		end

		return
	end
end)
events.shutdown(function()
	-- upvalues: t14 (copy)
	t14.movement:override()
end)
v382:set_callback(function()
	-- upvalues: t14 (copy)
	t14.movement:override()
end)
t22.package = pui.setup({
	other = u47.get(),
	antiaim = {
		states = t4.states,
		def_states = t4.def_states,
		other = t4.elements
	}
}, true)

local v383 = gradient.text_animate(" 𝒆𝒗𝒂𝒍𝒂𝒕𝒆", 1.5, {
	color(),
	color(255, 0)
})

events.render(function()
	-- upvalues: v383 (copy), pui (copy), u40 (ref)
	local v1859 = ui.get_style("Link Active")
	local v1860 = v1859:alpha_modulate(v1859.a * 0.5)

	v383:animate()
	v383:set_colors({
		[1] = v1859,
		[2] = v1860
	})
	pui.sidebar(u40.sub(v383:get_animated_text(), 11), u40.sub(v383:get_animated_text(), 1, 9) .. "\f<stars>")
end)
v214("Load time is " .. t3.stop() .. "ms")
