local hitboxes = {
    0,
    3,
    11,
    12
}

local indicator_draw,indicator_event

local function Indicator_Init()
    local indi = Menu.MultiCombo("Skeet Indicators", "Select to display", {"Fake With Circle", "FL With Circle", "AA With Line", "Shot/Miss Percent", "FL Text indicator", "FOV", "AW (Autowall)", "BUY (Buy Zone Indicator)", "Body Aim", "Safe Points", "Damage", "Hitchance", "Freestand", "At Targets", "Hide Shots", "Dormant Aimbot", "Fake Ping", "Lag Compensation", "Fake Duck", "Bomb Info", "Double Tap"}, 0)
local da_style = Menu.Switch("Skeet Indicators", "Show Dormant Aimbot Indicator Always", false)
local hs_style = Menu.Combo("Skeet Indicators", "Hide Shots Indicator Style", {"ONSHOT", "HS", "OSAA", "HIDE"}, 0)
local fs_style = Menu.Combo("Skeet Indicators", "Freestand Indicator Style", {"FREESTAND", "FS"}, 0)
local dmg_style = Menu.Combo("Skeet Indicators", "Damage Indicator Style", {"Damage: ", "DMG: ", "DMG", "Damage Value", ": DMG"}, 0)
local dmgs = Menu.Switch("Skeet Indicators", "Show Damage Indicator Always", false)
local hc_style = Menu.Combo("Skeet Indicators", "Hitchance Indicator Style", {"Hitchance: ", "HC: ", "HC", "Hitchance Value", ": HC%"}, 0)
local hcs = Menu.Switch("Skeet Indicators", "Show Hitchance Indicator Always", false)
local ba_style = Menu.Combo("Skeet Indicators", "Body Aim Indicator Style", {"BODY", "BAIM", "FB", "BA"}, 0)
local sp_style = Menu.Combo("Skeet Indicators", "Safe Points Indicator Style", {"SAFE", "SP"}, 0)
local hit_style = Menu.Combo("Skeet Indicators", "Shot/Miss Percent Style", {"Style 1", "Style 2", "Style 3"}, 0)
local fake_style = Menu.Combo("Skeet Indicators", "Fake With Circle Style", {"DSY", "FAKE", "AA"}, 1)
local fl_style = Menu.Combo("Skeet Indicators", "FL With Circle Style", {"Choke Value", "FL"}, 1)
local aa_color = Menu.ColorEdit("Skeet Indicators", "AA With Line Color", Color.RGBA(154, 176, 250, 255))

local font = 
{
    calibrib = Render.InitFont("Calibri Bold", 30),
    pixel9 = Render.InitFont("Smallest Pixel-7", 9)
}

local HC = Menu.FindVar("Aimbot","Ragebot","Accuracy","Hit Chance")
local DMG = Menu.FindVar("Aimbot","Ragebot","Accuracy","Minimum Damage")
local AW = Menu.FindVar("Aimbot","Ragebot","Accuracy","Autowall")
local FOV = Menu.FindVar("Aimbot","Ragebot","Main","FOV")
local BA = Menu.FindVar("Aimbot","Ragebot","Misc","Body Aim")
local SP = Menu.FindVar("Aimbot","Ragebot","Misc","Safe Points")
local DT = Menu.FindVar("Aimbot","Ragebot","Exploits","Double Tap")
local SW = Menu.FindVar("Aimbot","Anti Aim","Misc","Slow Walk")
local HS = Menu.FindVar("Aimbot","Ragebot","Exploits","Hide Shots")
local YAW = Menu.FindVar("Aimbot", "Anti Aim", "Main", "Yaw Base")
local PING = Menu.FindVar("Miscellaneous", "Main", "Other", "Fake Ping")
local FD = Menu.FindVar("Aimbot","Anti Aim","Misc","Fake Duck")

local velocity = function(ent)
    local speed_x = ent:GetProp("DT_BasePlayer","m_vecVelocity[0]")
    local speed_y = ent:GetProp("DT_BasePlayer","m_vecVelocity[1]")
    local speed = math.sqrt(speed_x * speed_x + speed_y * speed_y)
    return speed
end

local curTime = GlobalVars.curtime
local interface_ptr = ffi.typeof('void***')
local rawivengineclient = Utils.CreateInterface('engine.dll', 'VEngineClient014')
local ivengineclient = ffi.cast(interface_ptr, rawivengineclient)
local get_net_channel_info, net_channel = ffi.cast('void*(__thiscall*)(void*)', ivengineclient[0][78]), nil
local INetChannelInfo = ffi.cast('void***', get_net_channel_info(ivengineclient)) 
local GetNetChannel = function(INetChannelInfo)
    if INetChannelInfo == nil then
        return end

    return {
        latency = {
            crn = function(flow) return INetChannelInfo:GetLatency(flow) end,
            average = function(flow) return INetChannelInfo:GetAvgLatency(flow) end,
        }
    }
end
local outgoing, incoming, incoming_latency

local id, OldChoke, toDraw0, toDraw1, toDraw2, toDraw3, toDraw4, hitted, reg_shot, on_plant_time, fill, text, planting_site, planting = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, "", "", false

Cheat.RegisterCallback('registered_shot', function(shot) 
    if shot.reason == 0 then hitted = hitted + 1 end 
    reg_shot = reg_shot + 1 
end)

local calcDist = function(pos1, pos2)
	local lx = pos1.x
	local ly = pos1.y
	local lz = pos1.z
	local tx = pos2.x
	local ty = pos2.y
	local tz = pos2.z
	local dx = lx - tx
	local dy = ly - ty
	local dz = lz - tz
	return math.sqrt(dx * dx + dy * dy + dz * dz);
end

local normalize_yaw = function(yaw)
	while yaw > 180 do yaw = yaw - 360 end
	while yaw < -180 do yaw = yaw + 360 end
	return yaw
end

indicator_draw = function()
    fake_style:SetVisible(indi:GetBool(1))
    fl_style:SetVisible(indi:GetBool(2))
    aa_color:SetVisible(indi:GetBool(3))
    hit_style:SetVisible(indi:GetBool(4))
    ba_style:SetVisible(indi:GetBool(9))
    sp_style:SetVisible(indi:GetBool(10))
    dmg_style:SetVisible(indi:GetBool(11))
    dmgs:SetVisible(indi:GetBool(11))
    hc_style:SetVisible(indi:GetBool(12))
    hcs:SetVisible(indi:GetBool(12))
    fs_style:SetVisible(indi:GetBool(13))
    hs_style:SetVisible(indi:GetBool(15))
    da_style:SetVisible(indi:GetBool(16))

    local lp = EntityList.GetClientEntity(EngineClient.GetLocalPlayer())
    if not lp then return end 
    
    local delta_to_draw = math.abs(normalize_yaw(AntiAim.GetCurrentRealRotation() % 360 - AntiAim.GetFakeRotation() % 360)) / 2

    local chocking, invert, fake = ClientState.m_choked_commands, AntiAim.GetInverterState() == false, string.format("%.1f", delta_to_draw)

    local sc = EngineClient.GetScreenSize()
    local x, y = sc.x/100 + 2, sc.y/1.48 - 5
    local ay = 0
    local binds = Cheat.GetBinds()
    local dmg = false
    local hc = false
	local da = false
    for i = 1, #binds do
        local bind = binds[i]
        if bind:GetName() == 'Minimum Damage' and bind:IsActive() then
            dmg = true
            cur_dmg = bind:GetValue()
        end
        if bind:GetName() == 'Hit Chance' and bind:IsActive() then
            hc = true
            cur_hc = bind:GetValue()
        end
		if bind:GetName() == 'Dormant Aimbot' and bind:IsActive() then
            da = true
        end
    end

    local Render_Indicators = function(text, ay, color, size, fonts)
        ts = Render.CalcTextSize(text, size, fonts)
        Render.GradientBoxFilled(Vector2.new(13, y + ay), Vector2.new(13 + (ts.x) / 2, y + ay + 28), Color.RGBA(0, 0, 0, 0), Color.RGBA(0, 0, 0, 65), Color.RGBA(0, 0, 0, 0), Color.RGBA(0, 0, 0, 65))
        Render.GradientBoxFilled(Vector2.new(13 + (ts.x) / 2, y + ay), Vector2.new(13 + (ts.x), y + ay + 28), Color.RGBA(0, 0, 0, 65), Color.RGBA(0, 0, 0, 0), Color.RGBA(0, 0, 0, 65), Color.RGBA(0, 0, 0, 0))
        Render.Text(text, Vector2.new(x, y + 5 + ay), Color.new(0, 0, 0, 255), size, fonts)
        Render.Text(text, Vector2.new(x, y + 4 + ay), color, size, fonts)
    end

    if indi:GetBool(1) and lp:GetPlayer():IsAlive() then
        text = {"DSY", "FAKE", "AA"}
        id = fake_style:GetInt()+1
        ts = Render.CalcTextSize(text[id], 22, font.calibrib)
        clr = Color.RGBA(math.floor(255 - (fake * 2.29824561404)), math.floor(fake * 3.42105263158), math.floor(fake * 0.22807017543), 255)
        Render_Indicators(text[id], ay, clr, 22, font.calibrib)
        Render.Circle(Vector2.new(x + ts.x+13, y+ay+ts.y/2+3), 7, 32, Color.RGBA(0, 0, 0, 255), 5, 0, 365)
        Render.Circle(Vector2.new(x + ts.x+13, y+ay+ts.y/2+3), 7, 32, clr, 4, 0, (fake/60)*360)
        ay = ay - 35
    end

    if indi:GetBool(2) and lp:GetPlayer():IsAlive() then
        text = {chocking, "FL"}
        id = fl_style:GetInt()+1
        ts = Render.CalcTextSize(tostring(text[id]), 22, font.calibrib)
        Render_Indicators(tostring(text[id]), ay, Color.RGBA(135, 147, 255, 255), 22, font.calibrib)
        Render.Circle(Vector2.new(x + ts.x+13, y+ay+ts.y/2+3), 7, 32, Color.RGBA(0, 0, 0, 255), 5, 0, 365)
        Render.Circle(Vector2.new(x + ts.x+13, y+ay+ts.y/2+3), 7, 32, Color.RGBA(135, 147, 255, 255), 4, 0, (chocking/14)*360)
        ay = ay - 35
    end

    if indi:GetBool(3) and lp:GetPlayer():IsAlive() then
        ts = Render.CalcTextSize("AA", 22, font.calibrib)
        clr = Color.new(aa_color:GetColor().r, aa_color:GetColor().g, aa_color:GetColor().b, 1)
        Render_Indicators("AA", ay, Color.RGBA(235 ,235, 235, 255), 22, font.calibrib)
        Render.BoxFilled(Vector2.new(x, y + ts.y + ay - 1), Vector2.new(x + ts.x, y + 4 + ts.y + ay), Color.RGBA(0, 0, 0, 255))
        Render.BoxFilled(invert and Vector2.new(x+ts.x/2, y+ts.y+ay) or Vector2.new(x+ts.x/2-fake/4.4, y+ts.y+ay), invert and Vector2.new(x+ts.x/2+fake/4.4, y+3+ts.y+ay) or Vector2.new(x+ts.x/2, y+3+ts.y+ay), clr)
        ay = ay - 35
    end

    if indi:GetBool(4) and lp:GetPlayer():IsAlive() then
        local percent = hitted > 0 and reg_shot > 0 and (hitted/reg_shot)*100 or 100
        local miss = reg_shot-hitted
        text = {hitted.." / "..reg_shot.." ("..string.format("%.1f", percent)..")", miss.."/"..math.floor(percent).."%", hitted.." / "..reg_shot.." = "..math.floor(percent).."%"}
        id = hit_style:GetInt()+1
        Render_Indicators(text[id], ay, Color.RGBA(235 ,235, 235, 255), 22, font.calibrib)
        if hit_style:GetInt() == 2 then
            ay = ay - 35
            Render_Indicators("hit: "..hitted, ay, Color.RGBA(235 ,235, 235, 255), 22, font.calibrib)
            ay = ay - 35
            Render_Indicators("miss: "..miss, ay, Color.RGBA(235 ,235, 235, 255), 22, font.calibrib)
        end
        ay = ay - 35
    end

    if indi:GetBool(5) and lp:GetPlayer():IsAlive() then
        if chocking < OldChoke then
            toDraw0 = toDraw1
            toDraw1 = toDraw2
            toDraw2 = toDraw3
            toDraw3 = toDraw4
            toDraw4 = OldChoke
        end
        OldChoke = chocking
        Render_Indicators(string.format('%i-%i-%i-%i-%i',toDraw4,toDraw3,toDraw2,toDraw1,toDraw0), ay, Color.RGBA(235 ,235, 235, 255), 22, font.calibrib)
        ay = ay - 35
    end

    if indi:GetBool(6) and lp:GetPlayer():IsAlive() then
        Render_Indicators("FOV: "..FOV:GetInt().."°", ay, Color.RGBA(132, 195, 16, 255), 22, font.calibrib)
        ay = ay - 35
    end

    if indi:GetBool(7) and lp:GetPlayer():IsAlive() then
        Render_Indicators("AW", ay, AW:GetBool() and Color.RGBA(132, 195, 16, 255) or Color.RGBA(255, 0, 0, 255), 22, font.calibrib)
        ay = ay - 35
    end

    if lp:GetProp("m_bInBuyZone") and indi:GetBool(8) and lp:GetPlayer():IsAlive() then
        Render_Indicators("BUY", ay, Color.RGBA(132, 195, 16, 255), 22, font.calibrib)
        Render.Text("YOU HAVE: "..lp:GetProp("m_iAccount"), Vector2.new(x-8, y + 20 + ay), Color.RGBA(235 ,235, 235, 255), 9, font.pixel9, true)
        ay = ay - 35
    end

    if BA:GetInt() == 2 and indi:GetBool(9) then
        text = {"BODY", "BAIM", "FB", "BA"}
        id = ba_style:GetInt()+1
        Render_Indicators(text[id], ay, Color.RGBA(255, 0, 0, 255), 22, font.calibrib)
        ay = ay - 35
	end

    if SP:GetInt() == 2 and indi:GetBool(10) then
        text = {"SAFE", "SP"}
        id = sp_style:GetInt()+1
        Render_Indicators(text[id], ay, Color.RGBA(132, 195, 16, 255), 22, font.calibrib)
        ay = ay - 35
	end

    if indi:GetBool(11) then
        if dmg == true or dmgs:GetBool() then
            if dmgs:GetBool() then dmg_val = DMG:GetInt() else dmg_val = cur_dmg end
            dmg_val = math.floor(dmg_val)
            text = {"Damage: " .. dmg_val, "DMG: " .. dmg_val, "DMG", dmg_val, dmg_val < 101 and ": "..dmg_val or ": HP+"..(dmg_val-100)}
            clr = {Color.RGBA(235, 235, 235, 255), Color.RGBA(255, 255, 255, 150), Color.RGBA(132, 195, 16, 255), Color.RGBA(235, 235, 235, 255), Color.RGBA(80, 255, 80, 255)}
            id = dmg_style:GetInt()+1
            Render_Indicators(tostring(text[id]), ay, clr[id], 22, font.calibrib)
            ay = ay - 35
        end
    end

    if indi:GetBool(12) then
        if hc == true or hcs:GetBool() then
            if hcs:GetBool() then hc_val = HC:GetInt() else hc_val = cur_hc end
            hc_val = math.floor(hc_val)
            text = {"Hitchance: " .. hc_val, "HC: " .. hc_val, "HC", hc_val, ": "..hc_val.."%"}
            clr = {Color.RGBA(235, 235, 235, 255), Color.RGBA(200, 185, 255, 255), Color.RGBA(132, 195, 16, 255), Color.RGBA(235, 235, 235, 255), Color.RGBA(80, 255, 80, 255)}
            id = hc_style:GetInt()+1
            Render_Indicators(tostring(text[id]), ay, clr[id], 22, font.calibrib)
            ay = ay - 35
	    end
    end

	if YAW:GetInt() == 5 and indi:GetBool(13) then
        text = {"FREESTAND", "FS"}
        id = fs_style:GetInt()+1
        Render_Indicators(text[id], ay, Color.RGBA(235 ,235, 235, 255), 22, font.calibrib)
        ay = ay - 35
	end

    if YAW:GetInt() == 4 and indi:GetBool(14) then
        Render_Indicators("AT", ay, Color.RGBA(132, 195, 16, 255), 22, font.calibrib)
        ay = ay - 35
	end

    if HS:GetBool() and indi:GetBool(15) then
        text = {"ONSHOT", "HS", "OSAA", "HIDE"}
        id = hs_style:GetInt()+1
        Render_Indicators(text[id], ay, Color.RGBA(132, 195, 16, 255), 22, font.calibrib)
        ay = ay - 35
	end

    if da == true and indi:GetBool(16) or da_style:GetBool() and indi:GetBool(16) then
        Render_Indicators("DA", ay, Color.RGBA(132, 195, 16, 255), 22, font.calibrib)
        ay = ay - 35
    end   

    if PING:GetInt() > 0 and indi:GetBool(17) then
        INetChannelInfo = EngineClient.GetNetChannelInfo()
        net_channel = GetNetChannel(INetChannelInfo)
        outgoing, incoming = net_channel.latency.crn(0), net_channel.latency.crn(1)
        ping = math.max(0, (incoming-outgoing)*1000)
        Render_Indicators("PING", ay, Color.RGBA(math.floor(255 - ((ping / 189 * 60) * 2.29824561404)), math.floor((ping / 189 * 60) * 3.42105263158), math.floor((ping / 189 * 60) * 0.22807017543), 255), 22, font.calibrib)
        ay = ay - 35
	end

    if bit.band(lp:GetPlayer():GetProp("m_fFlags"), bit.lshift(1,0)) == 0 and indi:GetBool(18) and lp:GetPlayer():IsAlive() then  
        Render_Indicators("LC", ay, DT:GetBool() and Exploits.GetCharge() == 1 and Color.RGBA(255, 0, 0, 255) or velocity(lp)/chocking >= 20.84 and Color.RGBA(132, 195, 16, 255) or Color.RGBA(255, 0, 0, 255), 22, font.calibrib)
        ay = ay - 35
    end  

    if FD:GetBool() and indi:GetBool(19) then
        Render_Indicators("DUCK", ay, Color.RGBA(235 ,235, 235, 255), 22, font.calibrib)
        ay = ay - 35
    end

    if indi:GetBool(20) then 
        local c4 = EntityList.GetEntitiesByClassID(129)[1];
        if c4 ~= nil then
            local time = ((c4:GetProp("m_flC4Blow") - GlobalVars.curtime)*10) / 10
            local timer = string.format("%.1f", time)
            local defused = c4:GetProp("m_bBombDefused")
            if math.floor(timer) > 0 and not defused then
                local defusestart = c4:GetProp("m_hBombDefuser") ~= 4294967295
                local defuselength = c4:GetProp("m_flDefuseLength")
                local defusetimer = defusestart and math.floor((c4:GetProp("m_flDefuseCountDown") - GlobalVars.curtime)*10) / 10 or -1
                if defusetimer > 0 then
                    local color = math.floor(timer) > defusetimer and Color.RGBA(58, 191, 54, 160) or Color.RGBA(252, 18, 19, 125)
                    
                    local barlength = (((sc.y - 50) / defuselength) * (defusetimer))
                    Render.BoxFilled(Vector2.new(0.0, 0.0), Vector2.new(16, sc.y), Color.RGBA(25, 25, 25, 160))
                    Render.Box(Vector2.new(0.0, 0.0), Vector2.new(16, sc.y), Color.RGBA(25, 25, 25, 160))
                    
                    Render.BoxFilled(Vector2.new(0, sc.y - barlength), Vector2.new(16, sc.y), color)
                end
                
                local bombsite = c4:GetProp("m_nBombSite") == 0 and "A" or "B"
                local health = lp:GetProp("m_iHealth")
                local armor = lp:GetProp("m_ArmorValue")
                local willKill = false
                local eLoc = c4:GetProp("m_vecOrigin")
                local lLoc = lp:GetProp("m_vecOrigin")
                local distance = calcDist(eLoc, lLoc)
                local a = 450.7
                local b = 75.68
                local c = 789.2
                local d = (distance - b) / c;

                local damage = a * math.exp(-d * d)
                if armor > 0 then
                    local newDmg = damage * 0.5;
    
                    local armorDmg = (damage - newDmg) * 0.5
                    if armorDmg > armor then
                        armor = armor * (1 / .5)
                        newDmg = damage - armorDmg
                    end
                    damage = newDmg;
                end
                local dmg = math.ceil(damage)
                    if dmg >= health then
                    willKill = true
                else 
                    willKill = false
                end
                Render_Indicators(bombsite.." - "..string.format("%.1f", timer).."s", ay, Color.RGBA(235 ,235, 235, 255), 22, font.calibrib)
                ay = ay - 35
                if lp then
                    if willKill == true then
                        Render_Indicators("FATAL", ay, Color.RGBA(255, 0, 0, 255), 22, font.calibrib)
                        ay = ay - 35
                    elseif damage > 0.5 then
                        Render_Indicators("-"..dmg.." HP", ay, Color.RGBA(210, 216, 112, 255), 22, font.calibrib)
                        ay = ay - 35
                    end
                end
            end
        end
        if planting then
            Render_Indicators(planting_site, ay, Color.RGBA(210, 216, 112, 255), 22, font.calibrib)
            fill = 3.125 - (3.125 + on_plant_time - GlobalVars.curtime)
            if(fill > 3.125) then
                fill = 3.125
            end
            ts = Render.CalcTextSize(planting_site, 22, font.calibrib)
            Render.Circle(Vector2.new(x + ts.x+18, y+ay+ts.y/2+3), 8, 32, Color.RGBA(0, 0, 0, 255), 4, 0, 360)
            Render.Circle(Vector2.new(x + ts.x+18, y+ay+ts.y/2+3), 8, 32, Color.RGBA(235 ,235, 235, 255), 3, 0, (fill/3.3)*360)
            ay = ay - 35
        end
    end        
		
	if DT:GetBool() and indi:GetBool(21) then
        Render_Indicators("DT", ay, Exploits.GetCharge() == 1 and Color.RGBA(235 ,235, 235, 255) or Color.RGBA(255, 0, 0, 255), 22, font.calibrib)
        ay = ay - 35
    end
end

indicator_event = function(e)
    local player_resource = EntityList.GetPlayerResource()
	if e:GetName() == "bomb_abortplant" then
		planting = false
		fill = 0
		on_plant_time = 0
		planting_site = ""
	end
	if e:GetName() == "bomb_defused" then
		planting = false
		fill = 0
		on_plant_time = 0
		planting_site = ""
	end
	if e:GetName() == "bomb_planted" then
		planting = false
		fill = 0
		on_plant_time = 0
		planting_site = ""
	end
	if e:GetName() == "round_prestart" then
		planting = false
		fill = 0
		on_plant_time = 0
		planting_site = ""
	end
	
	if e:GetName() == "bomb_beginplant" then
		on_plant_time = GlobalVars.curtime
		planting = true
		local m_bombsiteCenterA = player_resource:GetProp("DT_CSPlayerResource", "m_bombsiteCenterA")
		local m_bombsiteCenterB = player_resource:GetProp("DT_CSPlayerResource", "m_bombsiteCenterB")
		
		local player = EntityList.GetPlayerForUserID(e:GetInt("userid", 0))
		local localPos = player:GetRenderOrigin()
		local dist_to_a = localPos:DistTo(m_bombsiteCenterA)
		local dist_to_b = localPos:DistTo(m_bombsiteCenterB)
		
		planting_site = dist_to_a < dist_to_b and "Bombsite A" or "Bombsite B"
	end
end

end
Indicator_Init()

local hitsound_register_shot
local function HitSound_Init()
    local ui_text = Menu.Text('Hitsound', 'Filepath: /csgo/sound/hitsounds | Note: Make sure file type is .wav')
local ui_enabled = Menu.Switch('Hitsound', 'Enabled', false)
local ui_sound_one = Menu.TextBox('Hitsound', 'Head shot', 64, 'Sound')
local ui_sound_two = Menu.TextBox('Hitsound', 'Body aim', 64, 'Sound')

    hitsound_register_shot = function (shot)
        local enabled = ui_enabled:Get()
        local headshot = ui_sound_one:Get()
        local bodyaim = ui_sound_two:Get()
    
        if not enabled then return end
    
        local hitbox = shot.hitgroup
        local reason = shot.reason
    
        if shot.reason ~= 0 then return end
    
        if hitbox == 1 then
            EngineClient.ExecuteClientCmd(string.format('playvol hitsounds/%s 1', headshot))
        else
            EngineClient.ExecuteClientCmd(string.format('playvol hitsounds/%s 1', bodyaim))
        end
    end
end

HitSound_Init()

local ffi = require("ffi")
local log_print,log_shot_print,log_main,log_event_reset
local function Log_Init()
    

EngineClient.ExecuteClientCmd('con_filter_text ""')
EngineClient.ExecuteClientCmd('con_filter_enable 2')
EngineClient.ExecuteClientCmd('developer 1')

local h1 = ""
local n1 = ""
local shots = 0
local hits = 0
local misses = 0
local globalshots = 0
local shotdmg = 0
local shothitbox = body
local shothc = 0

ffi.cdef[[
    void* GetProcAddress(void* hModule, const char* lpProcName);
    void* GetModuleHandleA(const char* lpModuleName);
    
    typedef struct {
        uint8_t r;
        uint8_t g;
        uint8_t b;
        uint8_t a;
    } color_struct_t;

    typedef void (*console_color_print)(const color_struct_t&, const char*, ...);

    typedef void* (__thiscall* get_client_entity_t)(void*, int);
]]

local FindElement = ffi.cast("unsigned long(__thiscall*)(void*, const char*)", Utils.PatternScan("client.dll", "55 8B EC 53 8B 5D 08 56 57 8B F9 33 F6 39 77 28"))
local CHudChat = FindElement(ffi.cast("unsigned long**", ffi.cast("uintptr_t", Utils.PatternScan("client.dll", "B9 ? ? ? ? E8 ? ? ? ? 8B 5D 08")) + 1)[0], "CHudChat")
local FFI_ChatPrint = ffi.cast("void(__cdecl*)(int, int, int, const char*, ...)", ffi.cast("void***", CHudChat)[0][27])

local resolverMiss = 0

local function PrintInChat(text)
    FFI_ChatPrint(CHudChat, 0, 0, string.format("%s ", text))
end

local hitgroups = {
	[0] = "body",
	[1] = "head",
	[2] = "chest",
	[3] = "stomach",
	[4] = "left arm",
	[5] = "right arm", 
	[6] = "left leg",
	[7] = "right leg", 
	[10] = "body"
}

-- Color printing function
local ffi_helpers = {
    color_print_fn = ffi.cast("console_color_print", ffi.C.GetProcAddress(ffi.C.GetModuleHandleA("tier0.dll"), "?ConColorMsg@@YAXABVColor@@PBDZZ")),
    color_print = function(self, text, color)
        local col = ffi.new("color_struct_t")

        col.r = color.r * 255
        col.g = color.g * 255
        col.b = color.b * 255
        col.a = color.a * 255

        self.color_print_fn(col, text)
    end
}
function round(num, numDecimalPlaces)
  return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
end


log_print = function(shot)


	local entity = EntityList.GetClientEntity(shot.target_index)
	local player = entity:GetPlayer()

	local reason = ""
	local rst = "unregistered shot"

	local hitbox = ""
                local dead = ""

	if((shot.hitgroup > -1 and shot.hitgroup < 8) or shot.hitgroup == 10) then
		hitbox = hitgroups[shot.hitgroup]
	else
		hitbox = "?"
	end

	if(shot.reason == 0) then
		printShotInfo(shot)
		return

	elseif(shot.reason == 1) then
		reason = " resolver"
		r = " 解析器"
                                rst = "unknown"
		resolverMiss = resolverMiss + 1
		if(Menu.FindVar("Aimbot", "Ragebot", "Main", "Override Resolver"):GetBool()) then
			reason = " resolver"
		r = " 解析器"
                                rst = "unknown"
		resolverMiss = resolverMiss + 1


		end
	
	elseif(shot.reason == 2) then
		reason = " spread"
		r = " 奖励过快导致射击误差"
                                rst = "spread"
		resolverMiss = resolverMiss + 1

            local e1_color = Color.new(1.0, 1.0, 1.0, 1.0)
ffi_helpers.color_print(ffi_helpers, "Missed shot due to spread" .. "" .. "\n", e1_color )

	elseif(shot.reason == 3) then
		reason = " resolver"
			r = " 解析器"
	                                rst = "unknown"
		resolverMiss = resolverMiss + 1

	elseif(shot.reason == 4) then
		reason = " prediction error"
		r = " prediction error"
                                rst = "prediction error"
		resolverMiss = resolverMiss + 1

	end

	if(shot.reason ~= 0 and shot.reason ~= 1 and shot.reason ~= 2 and shot.reason ~= 3 and shot.reason ~= 4) then
                                rst = "unregistered shot"
		r = " unregistered shot"
	ffi_helpers.color_print(ffi_helpers, "[Gamesense] unmanned主炮未命中目标... " .. player:GetName() .. ", 目标 " .. h1 .. "  原因" .. r .. "" .. "\n", l_color )
--	ffi_helpers.color_print(ffi_helpers, "[" .. globalshots .. "]" .. " [" .. misses .. "/" .. shots .. "]" .. " Missed " .. player:GetName() .. "'s " .. h1 .. "(" .. shotdmg .. ")(" .. shothc .. "%%%)" .. " due to " .. rst .. "，sp=false (B) [BT=0 LC=0 TC=1]" .. "\n", e_color )
	end

      if resolverMiss == 7 then
   resolverMiss = 1
end


    local miss
    if resolverMiss == 1 then
    	miss = "unmanned.lua。"
    elseif resolverMiss == 2 then
    	miss = "unmanned.lua。"
    elseif resolverMiss == 3 then
    	miss = "unmanned.lua"
    elseif resolverMiss == 4 then
    	miss = "unmanned.lua。"
    elseif resolverMiss == 5 then
    	miss = "unmanned.lua。"
    elseif resolverMiss == 6 then
    	miss = "unmanned.lua"
end

    local miss1
    if resolverMiss == 1 then
    	miss1 = "Hard work will not betray oneself, although dreams sometimes betray oneself."
    elseif resolverMiss == 2 then
    	miss1 = "If I don't hard work, I won't see you."
    elseif resolverMiss == 3 then
    	miss1 = "I don't believe in human beings...but I am worthy of the 'possibility' of human beings"
    elseif resolverMiss == 4 then
    	miss1 = "As long as you can't learn to die, learn to die."
    elseif resolverMiss == 5 then
    	miss1 = "Even if you can't see the future, even if you can't see the hope, you still believe in yourself."
    elseif resolverMiss == 6 then
    	miss1 = "After all, tomorrow is another day!"
end

            local l_color = Color.new(1.0, 0.99, 0.65, 1.0)

            local e_color = Color.new(1.0, 1.0, 1.0, 1.0)

n1 = player:GetName()

misses = misses + 1
globalshots = globalshots + 1

	--PrintInChat("\x01 \x01[Game\x07sense\x01] \x01 unmanned主炮未命中目标... \x01 \x07".. player:GetName() .."\x01, \x01 原因"..reason)
	ffi_helpers.color_print(ffi_helpers, "[Gamesense] unmanned主炮未命中目标... " .. player:GetName() .. ", 目标 " .. h1 .. "  原因" .. r .. "" .. "\n", l_color )
  --	ffi_helpers.color_print(ffi_helpers, "[" .. globalshots .. "]" .. " [" .. misses .. "/" .. shots .. "]" .. " Missed " .. player:GetName() .. "'s " .. h1 .. "(" .. shotdmg .. ")(" .. shothc .. "%%%)" .. " due to " .. rst .. "，sp=false (B) [BT=0 LC=0 TC=1]" .. "\n", e_color )
  	ffi_helpers.color_print(ffi_helpers, miss .. "" .. "\n", e_color )
  --                   Cheat.AddEvent("[Bronyaware] missed " .. player:GetName() .. ", hb: " .. hitbox .. "  r:" .. reason)

end

log_main = function(shot)

h1 = hitgroups[shot.hitgroup]


            local a_color = Color.new(0.57, 0.44, 0.85, 1.0)

	local hitbox = ""

	if((shot.hitgroup > -1 and shot.hitgroup < 8) or shot.hitgroup == 10) then
		hitbox = hitgroups[shot.hitgroup]

	else
		hitbox = "?"
	end

shots = shots + 1
shotdmg = tostring(shot.damage)
shothitbox = hitgroups[shot.hitgroup]
shothc = tostring(shot.hitchance)

	ffi_helpers.color_print(ffi_helpers, "[Gamesense] unmanned主炮充能完毕 开始射击 " .. "目标: " .. hitbox .. "  伤害: " .. tostring(shot.damage) .. "  命中概率: " .. tostring(shot.hitchance) .. "  bt: 0 (0 tks)  hp: false" .. "" .. "\n", a_color )
end

log_shot_print = function(shot)

	if shot.reason > 0 and shot.reason < 5  then
		log_print(shot)
		return
	end

	local entity = EntityList.GetClientEntity(shot.target_index)
	local player = entity:GetPlayer()
	local hitbox = ""
                local dead = ""
     if entity:GetProp('m_iHealth') <= 0 then
           dead = " (死亡)"
end

                local d = ""
     if entity:GetProp('m_iHealth') <= 0 then
           d= " (dead)"
end
	if((shot.hitgroup > -1 and shot.hitgroup < 8) or shot.hitgroup == 10) then
		hitbox = hitgroups[shot.hitgroup]
	else
		hitbox = "neck"
	end

            local b_color = Color.new(0.39, 0.58, 0.92, 1.0)

            local ccc_color = Color.new(1.0, 1.0, 1.0, 1.0)

hits = hits + 1
globalshots = globalshots + 1
	--PrintInChat("\x01 \x01[Game\x06sense\x01] \x01unmanned主炮命中目标! \x01 \x06".. player:GetName() .."\x01, \x01部位: \x01 \x06".. hitbox .."\x01 \x01 伤害: \x06".. shot.damage .." \x01 剩余血量: \x06".. entity:GetProp('m_iHealth') .. dead)
	  ffi_helpers.color_print(ffi_helpers, "[Gamesense] unmanned主炮命中目标! " .. player:GetName() .. ", 部位: " .. hitbox .. "  伤害: " .. shot.damage .. "  剩余血量: " .. entity:GetProp('m_iHealth') .. dead .. "" .. "\n", b_color )
--	  ffi_helpers.color_print(ffi_helpers, "[" .. globalshots .. "]" .. " [" .. hits .. "/" .. shots .. "]" .. " Hit " .. player:GetName() .. "'s " .. hitbox .. " for " .. shot.damage .. "(" .. shotdmg .. ") (" .. entity:GetProp('m_iHealth') .. " remaining) aimed=" .. shothitbox .. "(" .. shothc .. "%%%" .. ") sp=false (B) [BT=0 LC=0 TC=1]" ..  "\n", ccc_color )
	  ffi_helpers.color_print(ffi_helpers, "Hit " .. player:GetName() .. " in the " .. hitbox .. " for " .. shot.damage .. " damage (" .. entity:GetProp('m_iHealth') .. " health remaining)" .. "" .. "\n", ccc_color )
         --               Cheat.AddEvent("[Bronyaware] hit " .. player:GetName() .. ", hb: " .. hitbox .. "  dmg: " .. shot.damage .. "  rhp: " .. entity:GetProp('m_iHealth') .. d)

           --            Cheat.AddEvent("Hit " .. player:GetName() .. " in the " .. hitbox .. " for " .. shot.damage .. " damage (" .. entity:GetProp('m_iHealth') .. " health remaining)")
end

log_event_reset = function (e)
    resolverMiss = 0
end

end

Log_Init()

local skeet_indicator_draw
local function Skeet_Indicator()
    local screen = EngineClient.GetScreenSize()

local keybindscheck = Menu.SwitchColor("Keybinds", "Enable Keybinds", false, Color.new(1.0, 1.0, 1.0, 1.0))
local gradientcheck = Menu.Switch("Keybinds", "Gradient", false, "Gradient")
local key2 = {Menu.SliderInt("Keybinds", "keybinds x", 300, 1, screen.x), Menu.SliderInt("Keybinds", "keybinds y", 10, 1, screen.y)}
	
local function render_conteiner(x, y, w, h, name, color, box_alpha, font_size, font)
	local name_size = Render.CalcTextSize(name, font_size, font)
	local line_col = keybindscheck:GetColor()
	
	local r, g, b
	r = (math.floor(math.sin(GlobalVars.realtime * 1) * 127 + 128)) / 1000 * 3.92
	g = (math.floor(math.sin(GlobalVars.realtime * 1 + 2) * 127 + 128)) / 1000 * 3.92
	b = (math.floor(math.sin(GlobalVars.realtime * 1 + 4) * 127 + 128)) / 1000 * 3.92

	local color = keybindscheck:GetColor()	
	
	local add_y_box = 0
	
	local binds = Cheat.GetBinds()
    for i = 1, #binds do
		add_y_box = add_y_box + 16
    end

	if gradientcheck:GetBool() then

	else

	end
end


local font_size = 10
local font = Render.InitFont("Smallest Pixel-7", 10)
local drag = false
local width = 0
local m_alpha = 0

skeet_indicator_draw = function()
	local x, y = key2[1]:GetInt(), key2[2]:GetInt()
	local max_width = 0

	local add_y = 0
	
	local mouse = Cheat.GetMousePos()
	
	width = math.max(200, max_width)	
	if keybindscheck:GetBool() then
		render_conteiner(x, y, width, 12, "keybinds", color, Color.new(0, 0, 0, 0.3), font_size, font, add_pizda)
	end

	if Cheat.IsKeyDown(1) then
		if mouse.x >= x and mouse.y >= y and mouse.x <= x + width and mouse.y <= y + 18 or drag then
			if not drag then
				drag = true
			else
				key2[1]:SetInt(mouse.x - math.floor(width / 2))
				key2[2]:SetInt(mouse.y - 8)
			end
		end
	else
		drag = false
	end
	
	if keybindscheck:GetBool() then
		local function render_binds(binds)
			if not binds:IsActive() then return end
			local bind_name = binds:GetName()
			local bind_state = binds:GetMode()
			
			local statetext = string.format("")
			
			if bind_state == 0 then
				statetext = string.format("toggled")
			else
				statetext = string.format("hold")
			end

			add_y = add_y + 16
			
			local bind_state_size = Render.CalcTextSize(statetext, font_size, font)
			local bind_name_size = Render.CalcTextSize(bind_name, font_size, font)
			
			local color = keybindscheck:GetColor()	
			
			if gradientcheck:GetBool() then
				Render.Text(bind_name, Vector2.new(x + 5, y + add_y + 2), Color.RGBA(100, 200, 255, 255), font_size, font, false)
				Render.Text(statetext, Vector2.new(x - 10 + (width - bind_state_size.x), y + add_y + 2), Color.RGBA(175, 255, 0, 255), font_size, font, false)
			else
				Render.Text(bind_name, Vector2.new(x + 5, y + add_y + 2), color, font_size, font, false)
				Render.Text(statetext, Vector2.new(x - 10 + (width - bind_state_size.x), y + add_y + 2), Color.new(1, 1, 1, 1), font_size, font, false)
			end

			local bind_width = bind_state_size.x + bind_name_size.x + 10
			if bind_width > 80 then
				if bind_width > max_width then
					max_width = bind_width
				end
			end
		end

		local binds = Cheat.GetBinds()
		for i = 1, #binds do
			render_binds(binds[i])
		end
	end
end

local ui_callback = function()
	if keybindscheck:GetBool() then
		gradientcheck:SetVisible(true)
		key2[1]:SetVisible(true)
		key2[2]:SetVisible(true)
	else
		gradientcheck:SetVisible(false)
		key2[1]:SetVisible(false)
		key2[2]:SetVisible(false)
	end
end

ui_callback()

keybindscheck:RegisterCallback(ui_callback)
end
Skeet_Indicator()

local unnamed_jz_createmove,unnamed_prediction
local function Unnameed_Yaw_Init()
    local LegitEnable = Menu.Switch("Main","[1]Legit AA",false)
local LegitMode = Menu.Combo("Main","[1]Legit Mode",{"HVH","GP"},0)

local refs = {
    OPEN = Menu.FindVar("Aimbot","Anti Aim","Main","Enable Anti Aim"),
    PITCH = Menu.FindVar("Aimbot","Anti Aim","Main","Pitch"),

    YAW_BASE = Menu.FindVar("Aimbot","Anti Aim","Main","Yaw Base"),
    YAW_ADD = Menu.FindVar("Aimbot","Anti Aim","Main","Yaw Add"),
    YAW_MODIFIER = Menu.FindVar("Aimbot","Anti Aim","Main","Yaw Modifier"),

    FAKE_OPEN = Menu.FindVar("Aimbot","Anti Aim","Fake Angle","Enable Fake Angle"),

    LLIMIT = Menu.FindVar("Aimbot","Anti Aim","Fake Angle","Left Limit"),
    RLIMIT = Menu.FindVar("Aimbot","Anti Aim","Fake Angle","Right Limit"),

    INVERTER = Menu.FindVar("Aimbot","Anti Aim","Fake Angle","Inverter"),
    FAKE_OPTIONS = Menu.FindVar("Aimbot","Anti Aim","Fake Angle","Fake Options"),
    LBY_MODE = Menu.FindVar("Aimbot","Anti Aim","Fake Angle","LBY Mode"),
    FREESTANDING_DESYNC = Menu.FindVar("Aimbot","Anti Aim","Fake Angle","Freestanding Desync"),
    DESYNC_ON_SHOT = Menu.FindVar("Aimbot","Anti Aim","Fake Angle","Desync On Shot"),
    DT_ENABLED = Menu.FindVar("Aimbot","Ragebot","Exploits","Double Tap"),
}

--------------------------
local AA=Menu.Switch("Yaw Mode","[YAW] Open",true)
local DAA=Menu.Switch("Desync Mode","[DESYNC] Open",true)
local LAA=Menu.Switch("Lby Mode","[LBY] Open",true)

local FakeHeadEnable = Menu.Switch("Main","[2]Fake Head[DT]",false)
local FakeHeadKey = Menu.Switch("Main","[2]Check[DT]",false)

local FakeHeadAngle = Menu.SliderInt("Main","[2]Delta",90, 35, 120)

local AA1=Menu.Combo("Yaw Mode","[YAW] Direction",{"Default","Down"},0)
local AA2=Menu.Combo("Yaw Mode","[YAW] Mode",refs.YAW_BASE:GetList(),0)
local AA3=Menu.SliderInt("Yaw Mode","[YAW] Yaw",0,-180,180)

local DAAI=Menu.Switch("Desync Mode","[DESYNC] Inverter",true,"AA Direction",function(v)
    refs.INVERTER:Set(v)
end)

local fakelag_enable = Menu.Switch("DT & FL","[FL]Enable FL",false)

local DAA3=Menu.SliderInt("Desync Mode","[DESYNC] Limit Left",0,0,58)
local DAA4=Menu.SliderInt("Desync Mode","[DESYNC] Limit Right",0,0,58)
local DAA5=Menu.MultiCombo("Desync Mode","[DESYNC] Options",refs.FAKE_OPTIONS:GetList(),0)
local DAA6=Menu.Combo("Desync Mode","[DESYNC] LBY Mode",refs.LBY_MODE:GetList(),0)
local DAA7=Menu.Combo("Desync Mode","[DESYNC] FreeStand",refs.FREESTANDING_DESYNC:GetList(),0)
local DAA8=Menu.Combo("Desync Mode","[DESYNC] On Shot",{"Disableed","Left","Right","Async","Opposite"},0)

local LAA3=Menu.SliderInt("Lby Mode","[LBY] Limit Left",0,-58,58)
local LAA4=Menu.SliderInt("Lby Mode","[LBY] Limit Right",0,-58,58)

local modes = {
    "Stand",
    "Move",
    "Jump",
    "SlowWalk"
}

local yaw_modes = {
    "Close",
    "Center",
    "Offset",
    "Random"
}

local UI = {}
local LBY_UI = {}
local FAKE_UI = {}
local FL_UI = {}
local function INIT_UI()
    for i = 1,#modes do
        local str = modes[i]
        table.insert(UI,{
            current = str,
            yaw_mode = Menu.Combo("Yaw Mode","[YAW] " .. str, yaw_modes,0),
            swap_speed = Menu.SliderInt("Yaw Mode",str .. " Speed",3,1,10),
            one_ang = Menu.SliderInt("Yaw Mode",str .. " Angle Swap",0,-180,180),
            left_ang_swap = Menu.SliderInt("Yaw Mode",str .. " Left",0,-180,180),
            right_ang_swap = Menu.SliderInt("Yaw Mode",str .. " Right",0,-180,180)
        })

        table.insert(FL_UI,{
            current = str,
            fakelag_value = Menu.SliderInt("DT & FL", "[FL][" .. str .. "]Value",5,1,14)
        })

        table.insert(LBY_UI,{
            current = str,
            lby_mode = Menu.Combo("Lby Mode","[LBY] " .. str, yaw_modes,0),
            swap_speed = Menu.SliderInt("Lby Mode",str .. " Speed",3,1,10),
            one_ang = Menu.SliderInt("Lby Mode",str .. " Angle Swap",0,-58,58),
            left_ang_swap = Menu.SliderInt("Lby Mode",str .. " Left",0,-58,58),
            right_ang_swap = Menu.SliderInt("Lby Mode",str .. " Right",0,-58,58)
        })

        table.insert(FAKE_UI,{
            current = str,
            desync_mode = Menu.Combo("Desync Mode","[DESYNC] " .. str, yaw_modes,0),
            swap_speed = Menu.SliderInt("Desync Mode",str .. " Speed",3,1,10),
            one_ang = Menu.SliderInt("Desync Mode",str .. " Angle Swap",0,0,58),
            left_ang_swap = Menu.SliderInt("Desync Mode",str .. " Left",0,0,58),
            right_ang_swap = Menu.SliderInt("Desync Mode",str .. " Right",0,0,58)
        })
    end
end
INIT_UI()


local DT_ENABLE = Menu.Switch("DT & FL","[DT] Enable DT",false)
local DT_MODES = Menu.Combo("DT & FL","[DT] Mode",{"GP","HVH","Custom"},0)
local DT_FLASH = Menu.Switch("DT & FL","[DT] Flash",false)
local DT_CUSTOM = Menu.SliderInt("DT & FL","[DT] Ticks",13,3,32)
local dt_force_teleport = Menu.Switch("DT & FL","[DT]Force Teleport",false)

local function async_func()
    refs.PITCH:Set(AA1:Get())
    refs.YAW_ADD:Set(0)
    refs.YAW_BASE:Set(1)
    for i = 1,#refs.FAKE_OPTIONS:GetList() do
        refs.FAKE_OPTIONS:Set(i,false)
    end

    refs.LBY_MODE:Set(1)
    refs.FREESTANDING_DESYNC:Set(1)
    refs.DESYNC_ON_SHOT:Set(0)
end

local function REGISTER_UICALLBACKS()
    refs.OPEN:Set(AA:GetBool())
    refs.FAKE_OPEN:Set(DAA:GetBool())

    local fchk = FakeHeadEnable:GetBool()
    FakeHeadKey:SetVisible(fchk)
    FakeHeadAngle:SetVisible(fchk)

    if FakeHeadEnable:GetBool() and FakeHeadKey:GetBool() then
        async_func()
    elseif LegitEnable:GetBool() then

        refs.PITCH:Set(0)
        refs.YAW_BASE:Set(LegitMode:Get())
        refs.YAW_ADD:Set(0)

        refs.LBY_MODE:Set(1)
        refs.FREESTANDING_DESYNC:Set(1)
        refs.DESYNC_ON_SHOT:Set(0)
    
        refs.LLIMIT:Set(60)
        refs.RLIMIT:Set(60)
    
        for i = 1,#refs.FAKE_OPTIONS:GetList() do
            refs.FAKE_OPTIONS:Set(i,false)
        end
    else
        refs.YAW_BASE:Set(AA2:Get())
        refs.PITCH:Set(AA1:Get())
        for i = 1,#refs.FAKE_OPTIONS:GetList() do
            refs.FAKE_OPTIONS:Set(i,DAA5:Get(i))
        end

        refs.LBY_MODE:Set(DAA6:Get())
        refs.FREESTANDING_DESYNC:Set(DAA7:Get())

    end

    DT_CUSTOM:SetVisible(DT_MODES:Get() == 2 and DT_ENABLE:GetBool())
    DT_MODES:SetVisible(DT_ENABLE:GetBool())
    DT_FLASH:SetVisible(DT_ENABLE:GetBool())

    for tind, t in pairs(UI) do
    local chk = t.current == modes[tind]
        t.yaw_mode:SetVisible(chk)
        chk = chk and t.yaw_mode:Get() > 0
        t.swap_speed:SetVisible(chk)

        t.one_ang:SetVisible(chk and t.yaw_mode:Get() == 2)

        chk = chk and t.yaw_mode:Get() ~= 2
        t.left_ang_swap:SetVisible(chk) 
        t.right_ang_swap:SetVisible(chk)
    end

    for tind, t in pairs(LBY_UI) do
        local chk = t.current == modes[tind]
            t.lby_mode:SetVisible(chk)
            chk = chk and t.lby_mode:Get() > 0
            t.swap_speed:SetVisible(chk) 

            t.one_ang:SetVisible(chk and t.lby_mode:Get() == 2)
            chk = chk and t.lby_mode:Get() ~= 2
            t.left_ang_swap:SetVisible(chk) 
            t.right_ang_swap:SetVisible(chk) 
    end

    for tind, t in pairs(FAKE_UI) do
        local chk = t.current == modes[tind]
            t.desync_mode:SetVisible(chk)
            chk = chk and t.desync_mode:Get() > 0
            t.swap_speed:SetVisible(chk)
            t.one_ang:SetVisible(chk and t.desync_mode:Get() == 2)
            chk = chk and t.desync_mode:Get() ~= 2
            t.left_ang_swap:SetVisible(chk)
            t.right_ang_swap:SetVisible(chk)
    end

    for tind, t in pairs(FL_UI) do
        local chk = fakelag_enable:GetBool()
        t.fakelag_value:SetVisible(chk)
    end
end
REGISTER_UICALLBACKS()

local function REGISTER_ALL_CALBACKS()
    AA:RegisterCallback(REGISTER_UICALLBACKS)
    DAA:RegisterCallback(REGISTER_UICALLBACKS)
    LAA:RegisterCallback(REGISTER_UICALLBACKS)
    AA1:RegisterCallback(REGISTER_UICALLBACKS)
    AA2:RegisterCallback(REGISTER_UICALLBACKS)
    refs.OPEN:RegisterCallback(REGISTER_UICALLBACKS)
    refs.PITCH:RegisterCallback(REGISTER_UICALLBACKS)
    refs.YAW_ADD:RegisterCallback(REGISTER_UICALLBACKS)
    refs.YAW_BASE:RegisterCallback(REGISTER_UICALLBACKS)
    refs.FAKE_OPEN:RegisterCallback(REGISTER_UICALLBACKS)
    LegitEnable:RegisterCallback(REGISTER_UICALLBACKS)

    FakeHeadEnable:RegisterCallback(REGISTER_UICALLBACKS)
    FakeHeadKey:RegisterCallback(REGISTER_UICALLBACKS)

    refs.FAKE_OPTIONS:RegisterCallback(REGISTER_UICALLBACKS)
    refs.LBY_MODE:RegisterCallback(REGISTER_UICALLBACKS)
    refs.FREESTANDING_DESYNC:RegisterCallback(REGISTER_UICALLBACKS)
    DAA5:RegisterCallback(REGISTER_UICALLBACKS)
    DAA6:RegisterCallback(REGISTER_UICALLBACKS)
    DAA7:RegisterCallback(REGISTER_UICALLBACKS)

    DT_FLASH:RegisterCallback(REGISTER_UICALLBACKS)
    DT_ENABLE:RegisterCallback(REGISTER_UICALLBACKS)
    DT_MODES:RegisterCallback(REGISTER_UICALLBACKS)
    fakelag_enable:RegisterCallback(REGISTER_UICALLBACKS)

    refs.YAW_MODIFIER:RegisterCallback(REGISTER_UICALLBACKS)
    for tind, t in pairs(UI) do
        t.yaw_mode:RegisterCallback(REGISTER_UICALLBACKS)
        t.swap_speed:RegisterCallback(REGISTER_UICALLBACKS)
        t.left_ang_swap:RegisterCallback(REGISTER_UICALLBACKS)
        t.right_ang_swap:RegisterCallback(REGISTER_UICALLBACKS)
        t.one_ang:RegisterCallback(REGISTER_UICALLBACKS)
    end

    for tind, t in pairs(LBY_UI) do
        t.lby_mode:RegisterCallback(REGISTER_UICALLBACKS)
        t.swap_speed:RegisterCallback(REGISTER_UICALLBACKS)
        t.left_ang_swap:RegisterCallback(REGISTER_UICALLBACKS)
        t.right_ang_swap:RegisterCallback(REGISTER_UICALLBACKS)
        t.one_ang:RegisterCallback(REGISTER_UICALLBACKS)
    end

    for tind, t in pairs(FAKE_UI) do
        t.desync_mode:RegisterCallback(REGISTER_UICALLBACKS)
        t.swap_speed:RegisterCallback(REGISTER_UICALLBACKS)
        t.left_ang_swap:RegisterCallback(REGISTER_UICALLBACKS)
        t.right_ang_swap:RegisterCallback(REGISTER_UICALLBACKS)
        t.one_ang:RegisterCallback(REGISTER_UICALLBACKS)
    end

    for tind, t in pairs(FL_UI) do
        t.fakelag_value:RegisterCallback(REGISTER_UICALLBACKS)
    end
end
REGISTER_ALL_CALBACKS()

local Slow_motion = Menu.Switch('Main', "[3]Slow Walk", false)
local limit_reference = Menu.SliderInt("Main", "[3]Slow Walk Speed", 1, 1, 60)
local function modify_velocity(cmd, goalspeed)
	if goalspeed <= 0 then
		return
	end
	
	local minimalspeed = math.sqrt((cmd.forwardmove * cmd.forwardmove) + (cmd.sidemove * cmd.sidemove))
	
	if minimalspeed <= 0 then
		return
	end
	
	if cmd.in_duck == 1 then
		goalspeed = goalspeed * 2.94117647
	end
	
	if minimalspeed <= goalspeed then
		return
	end
	
	local speedfactor = goalspeed / minimalspeed
	cmd.forwardmove = cmd.forwardmove * speedfactor
	cmd.sidemove = cmd.sidemove * speedfactor
end

local unbind_e = false
EngineClient.ExecuteClientCmd("bind h +use")

Cheat.RegisterCallback("destroy", function()
    EngineClient.ExecuteClientCmd("unbind h")
    EngineClient.ExecuteClientCmd("bind e +use")
end)

local last_realtime = GlobalVars.realtime
local mode_last = 1
local should_back,ltick = false,GlobalVars.tickcount
unnamed_jz_createmove = function(cmd)
    local lplayer = EntityList.GetLocalPlayer()
    if not lplayer or lplayer:GetProp("m_iHealth") <= 0 then
        last_realtime = 0
        return
    end

	local limit = limit_reference:GetInt()
	
	if limit >= 57 then
		return
	end
	
	if Slow_motion:GetBool() then
		modify_velocity(cmd, limit)
	end

    if AA2:Get() ~= 2 and AA2:Get() ~= 3 then
        mode_last = AA2:Get()
    end

    if DT_ENABLE:GetBool() and DT_FLASH:GetBool() then
        Exploits.ForceTeleport()
    end

    local binds = Cheat.GetBinds()
    local legit_enabled = false
    local mode = false

    for i = 1, #binds do
        legit_enabled = binds[i]:GetName() == "[1]Legit AA"
        mode = binds[i]:GetMode() == 1
    end

    if legit_enabled then
        if mode then
            if not unbind_e then
                EngineClient.ExecuteClientCmd("unbind e;-use")
                unbind_e = true
            end
        else
            if unbind_e then
                EngineClient.ExecuteClientCmd("bind e +use;-use")
                unbind_e = false
            end
        end
    else
        if unbind_e then
            EngineClient.ExecuteClientCmd("bind e +use;-use")
            unbind_e = false
        end
    end
end

local function hsv_to_rgb(h, s, v)
    local r, g, b

    local i = math.floor(h * 6);
    local f = h * 6 - i;
    local p = v * (1 - s);
    local q = v * (1 - f * s);
    local t = v * (1 - (1 - f) * s);

    i = i % 6

    if i == 0 then r, g, b = v, t, p
    elseif i == 1 then r, g, b = q, v, p
    elseif i == 2 then r, g, b = p, v, t
    elseif i == 3 then r, g, b = p, q, v
    elseif i == 4 then r, g, b = t, p, v
    elseif i == 5 then r, g, b = v, p, q
    end

    return r * 255, g * 255, b * 255
end
local clolorscache= Color.new
clolorscache = function (r,g,b,a)
    return Color.new(r/255,g/255,b/255,a/255)
end

local screen_size = EngineClient.GetScreenSize()

local leg_improvement_chk = Menu.Switch("DT & FL","[Leg]Enable Leg",false)
local leg_improvement_speed = Menu.SliderInt("DT & FL","[Leg]Speed",2,1,20)

local current_ang,current_desync,current_lby = 0,0,0
local switch_bool,switch_bool1,switch_bool2 = false,false,false
local switch_booooool,fl_switch_bool = false,false

local function Sway(num,add,min,max)
    if num == nil then
        return math.ceil((max + min) / 2),add
    end

    local add_res = add
    local result = num + add
    if num == max - 1 then
        add_res = -1
    elseif num == min + 1 then
        add_res = 1
    end
    
    if num > max or num < min then
        return math.ceil((max + min) / 2),add
    end

    return result,add_res
end

local a = 0.0;
local b = true;

unnamed_prediction = function(cmd)
    local lplayer = EntityList.GetLocalPlayer()
    if not lplayer or lplayer:GetProp("m_iHealth") <= 0 then
        return
    end

    if leg_improvement_chk:GetBool() then

        local speed = 21 - leg_improvement_speed:Get()

        if GlobalVars.tickcount % speed == 0 then
            switch_booooool = not switch_booooool
        end

        Menu.FindVar("Aimbot","Anti Aim","Misc","Leg Movement"):Set(switch_booooool and 0 or 1)
    end

    if DT_ENABLE:GetBool() then
        if DT_MODES:Get() == 2 then
            Exploits.OverrideDoubleTapSpeed(DT_CUSTOM:Get())
        elseif DT_MODES:Get() == 1 then
            Exploits.OverrideDoubleTapSpeed(16)
        elseif DT_MODES:Get() == 0 then
            Exploits.OverrideDoubleTapSpeed(8)
        end
    end

    if dt_force_teleport:GetBool() and refs.DT_ENABLED:GetBool() then
        local players = EntityList.GetPlayers()

        for i = 1,#players do
            local player_pointer = players[i]
            if not player_pointer or player_pointer:IsTeamMate() or not player_pointer:IsAlive() or player_pointer:IsDormant() then 
                goto skip
            end

            for j = 1,#hitboxes do
                local hitbox_pos = player_pointer:GetHitboxCenter(hitboxes[j])
                local trace = Cheat.FireBullet(lplayer, lplayer:GetRenderOrigin() + Vector.new(0,0,64), hitbox_pos)

                if trace.damage > 0 and Exploits.GetCharge() == 0 then
                    Exploits.ForceCharge()
                end
            end

            ::skip::
        end
    end

    local legitEnable = LegitEnable:GetBool()

    if FakeHeadEnable:GetBool() and FakeHeadKey:Get() and lplayer:GetProp('m_vecVelocity'):Length2D() <= 5 then
        async_func()
        local angle = FakeHeadAngle:Get()

        if GlobalVars.realtime - a >= 0.22 + (b and 0.01 or -0.01) then
            AntiAim.OverrideYawOffset(angle * (AntiAim.GetInverterState() and -1 or 1));
            a = GlobalVars.realtime;
            b = not b;
        end

    elseif not legitEnable then
        local flag = lplayer:GetProp("m_fFlags")
        local vel = lplayer:GetProp("m_vecVelocity")
        vel = vel:Length2D()
        local air,moving,land,slowwalking = bit.band(flag,bit.lshift(1,0)) == 0,vel > 5,false,Slow_motion:GetBool()
        land = moving == false
        local CIND = air and 3 or (slowwalking and 4 or (moving and 2 or 1))
        AntiAim.OverrideDesyncOnShot(DAA8:Get())

        if AA:GetBool() then
            local yaw_ang = AA3:Get()
            local t = UI[CIND]
            local ctype = t.yaw_mode:Get()
            current_ang = ctype ~= 3 and yaw_ang or current_ang
    
            local speed = t.swap_speed:Get()
            local tickok = GlobalVars.tickcount % speed == 0
    
                if ctype == 1 then
                    if tickok then
                        switch_bool = not switch_bool
                    end
                    current_ang = yaw_ang + (switch_bool and t.left_ang_swap:Get() or t.right_ang_swap:Get())
                elseif ctype == 2 then
                    if tickok then
                        switch_bool = not switch_bool
                    end
                    current_ang = yaw_ang + (switch_bool and 0 or t.one_ang:Get())
                elseif ctype == 3 then
                    if tickok then
                        current_ang = math.random(yaw_ang + t.left_ang_swap:Get(),yaw_ang + t.right_ang_swap:Get())
                    end
                end
    
                AntiAim.OverrideYawOffset(current_ang)
        end
    
        if DAA:GetBool() then
            local desync_ang_l,desync_ang_r = DAA3:Get(),DAA4:Get()
            local desync_ang = AntiAim.GetInverterState() and desync_ang_r or desync_ang_l
            local t = FAKE_UI[CIND]
            local dtype = t.desync_mode:Get()
            current_desync = dtype ~= 3 and desync_ang or current_desync
            local speed = t.swap_speed:Get()
            local tickok = GlobalVars.tickcount % speed == 0
            if dtype == 1 then
                if tickok then
                    switch_bool1 = not switch_bool1
                end
                current_desync = desync_ang + (switch_bool1 and t.left_ang_swap:Get() or t.right_ang_swap:Get())
            elseif dtype == 2 then
                if tickok then
                    switch_bool1 = not switch_bool1
                end
                current_desync = desync_ang + (switch_bool1 and 0 or t.one_ang:Get())
            elseif dtype == 3 then
                if tickok then
                    current_desync = math.random(desync_ang + t.left_ang_swap:Get(),desync_ang + t.right_ang_swap:Get())
                end
            end
    
            AntiAim.OverrideLimit(current_desync)
        end
    
        if LAA:GetBool() then
            local lby_ang_l,lby_ang_r = LAA3:Get(),LAA4:Get()
            local lby_ang = AntiAim.GetInverterState() and lby_ang_r or lby_ang_l
            local t = LBY_UI[CIND]
            local ltype = t.lby_mode:Get()
            current_lby = ltype ~= 3 and lby_ang or current_lby
    
            local speed = t.swap_speed:Get()
            local tickok = GlobalVars.tickcount % speed == 0
    
            if ltype == 1 then
                if tickok then
                    switch_bool2 = not switch_bool2
                end
                current_lby = lby_ang + (switch_bool2 and t.left_ang_swap:Get() or t.right_ang_swap:Get())
            elseif ltype == 2 then
                if tickok then
                    switch_bool2 = not switch_bool2
                end
                current_lby = lby_ang + (switch_bool2 and 0 or t.one_ang:Get())
            elseif ltype == 3 then
                if tickok then
                    current_lby = math.random(lby_ang + t.left_ang_swap:Get(),lby_ang + t.right_ang_swap:Get())
                end
            end
    
            AntiAim.OverrideLBYOffset(current_lby)
        end

        if fakelag_enable:GetBool() then

            local limit = nil
            limit = FL_UI[CIND].fakelag_value:Get()
    
            if limit ~= nil then
                Menu.FindVar("Aimbot","Anti Aim","Fake Lag","Limit"):Set(limit)
            end
        end
    end
end
end

Unnameed_Yaw_Init()
local visible_points_draw
local function Visible_Points_Init()
    local radius = Menu.SliderInt("Main","Radius", 5, 1, 15 )

local color_head = Menu.ColorEdit( "Main","Color Head", Color.new(1.0,1.0,1.0,1.0))
local color_body = Menu.ColorEdit( "Main","Color Body", Color.new(1.0,1.0,1.0,1.0))
local color_feet = Menu.ColorEdit( "Main","Color Feet", Color.new(1.0,1.0,1.0,1.0))

local function RenderFadeCircle(x,y,radius,r,g,b,al)
    
    local a = al * 6 
    local ra = radius / 6
    for i = 1, 5 do
        local alpha = a / i
        local radi = ra * i
        Render.CircleFilled(Vector2.new(x,y), radi, 30, Color.new(r,g,b,alpha))
    end
end


visible_points_draw = function()
    
    local local_player = EntityList.GetLocalPlayer()
    if not local_player or not local_player:IsAlive() then 
        return
    end

    local players = EntityList.GetPlayers()

    for i = 1,#players do
        local player_pointer = players[i]
        if not player_pointer or player_pointer:IsTeamMate() or not player_pointer:IsAlive() or player_pointer:IsDormant() then 
            goto skip
        end

            for j = 1,#hitboxes do
                local hitbox_pos = player_pointer:GetHitboxCenter(hitboxes[j])
                local screen_pos = Render.WorldToScreen(hitbox_pos)
                local sx,sy = screen_pos.x,screen_pos.y
    
                local trace = Cheat.FireBullet(local_player, local_player:GetRenderOrigin() + Vector.new(0,0,64), hitbox_pos)

                local clr = j == 1 and color_head:Get() or (j == 2 and color_body:Get() or color_feet:Get())

                local r,g,b,a = clr.r,clr.g,clr.b,clr.a
                if trace.damage > 0 then
                    RenderFadeCircle(sx,sy,radius:Get(),r,g,b,a)
                end

            end

        ::skip::
    end
end
end
Visible_Points_Init()

local constrli_draw
local function Consteli_Init()
    local scv = EngineClient.GetScreenSize()
local x = Menu.SliderInt("Main","X Pos",200,0,scv.x)
local y = Menu.SliderInt("Main","Y Pos",200,0,scv.y)

local w = Menu.SliderInt("Main","Width",200,0,scv.x)
local h = Menu.SliderInt("Main","Height",200,0,scv.y)

local name = Menu.TextBox("Main", "Path", 64, "C:\\")
local image = nil 

local button = Menu.Button("Main", "Refresh Texture", "Refresh",function()
    image = Render.LoadImageFromFile(name:Get(), Vector.new(w:Get(),h:Get()))
end)

local alpha = Menu.SliderInt( "Main", "Alpha", 255, 0, 255 )

local offset_x = Menu.SliderInt( "Main", "OFFSET X", 30, 0, 150 )

local function Draw_Lines(x,y,ang,radius,thickness,clr)
    
    thickness = thickness or 1
    local start = 1
    local segments = 1
    if thickness > 1 then
        thickness = thickness / 2
        start = -thickness
        segments = 0.1
    end
    for t = start,thickness,segments do
        for i = 1,radius do
            local x1 = x + t + math.cos(math.rad(ang)) * i
            local y1 = y + t + math.sin(math.rad(ang)) * i
            local x2 = x + t + math.cos(math.rad(ang)) * (i + 1)
            local y2 = y + t + math.sin(math.rad(ang)) * (i + 1)

            if x1 and x2 then
                Render.Line(Vector2.new(x1,y1),Vector2.new(x2,y2),clr)

                if i == radius - 1 and t + 0.1 >= thickness then
                    return x2,y2
                end
            end
        end
    end
end

local before_health = nil
local after_health = nil
local saved_health = nil
local dnm = false
local first = true

constrli_draw = function()
    local lplayer = EntityList.GetLocalPlayer()
    if lplayer and lplayer:GetProp("m_iHealth") > 0 then

        if image ~= nil then
            Render.Image(image, Vector2.new(x:Get() - w:Get() - offset_x:Get(),y:Get() - h:Get() / 2), Vector2.new(x:Get() - offset_x:Get(),y:Get() + h:Get() / 2),Color.new(1.0,1.0,1.0,alpha:Get() / 255))
        end

        local health = lplayer:GetProp("m_iHealth")

        if first then

            if saved_health == nil then
                saved_health = 0
            end
            
            saved_health = saved_health + 1

            if saved_health > health then
                first = false
                saved_health = nil
            end

            health = saved_health
            if health == nil then
                health = 100
            end
        end

        if before_health == nil then
            before_health = health
        end

        if before_health > health and not dnm then
            after_health = health
            saved_health = before_health
            dnm = true
        elseif before_health < health then
            before_health = health
        end

        if dnm then
            local sub_value = before_health - after_health

            if GlobalVars.tickcount % 2 == 0 then
                saved_health = saved_health - 1
            end

            if saved_health <= after_health then
                dnm = false
                before_health = lplayer:GetProp("m_iHealth")
                after_health = nil
                saved_health = nil
            end

            health = saved_health
        end

        local px,py = x:Get(),y:Get()

        local current_status = 1
        local circle_radius = 4
        local circle_radius2 = 3
        local thickness_lines = 1

        local line_one = { x:Get() + 60, y:Get() - 30 }
        local line_two = { x:Get() + 200, y:Get() + 12 }
        local line_three = { x:Get() + 360, y:Get() + 0 }

        Render.CircleFilled(Vector2.new(line_one[1],line_one[2]) ,circle_radius2,30,Color.new(1.0,1.0,1.0,1.0) )
        Render.CircleFilled(Vector2.new(line_two[1],line_two[2]) ,circle_radius2,30,Color.new(1.0,1.0,1.0,1.0) )
        Render.CircleFilled(Vector2.new(line_three[1],line_three[2]) ,circle_radius2,30,Color.new(1.0,1.0,1.0,1.0) )

        if health and health > 0 then
            --0
            Render.CircleFilled(Vector2.new(px,py) ,circle_radius,30,Color.new(1.0,1.0,1.0,1.0) )
            local scale = 2
            local value = 15
            if health < 20 then
                value = health
            end

            px,py = Draw_Lines(px,py,325,value * scale,thickness_lines,Color.new(1.0,1.0,1.0,1.0))

            if health >= 15 then
                --15
                scale = 3

                if health < 30 then
                    value = health - 15
                end
                Render.Line(Vector2.new(px,py),Vector2.new( line_one[1],line_one[2]),Color.new(1.0,1.0,1.0,100 / 255))

                Render.CircleFilled(Vector2.new(px,py),circle_radius,30,Color.new(1.0,1.0,1.0,1.0))
                px,py = Draw_Lines(px,py,30,value * scale,thickness_lines,Color.new(1.0,1.0,1.0,1.0))

                if health >= 30 then
                    --30
                    scale = 5
    
                    if health < 45 then
                        value = health - 30
                    end

                    Render.Line(Vector2.new(px,py),Vector2.new( line_one[1],line_one[2]),Color.new(1.0,1.0,1.0,100 / 255))
                    Render.CircleFilled(Vector2.new(px,py),circle_radius,30,Color.new(1.0,1.0,1.0,1.0))

                    px,py = Draw_Lines(px,py,350,value * scale,thickness_lines,Color.new(1.0,1.0,1.0,1.0))

                    if health >= 45 then
                        scale = 5
    
                        if health < 60 then
                            value = health - 45
                        end

                        Render.Line(Vector2.new(px,py),Vector2.new( line_two[1],line_two[2]),Color.new(1.0,1.0,1.0,100 / 255))
                        Render.CircleFilled(Vector2.new(px,py),circle_radius,30,Color.new(1.0,1.0,1.0,1.0))

                        px,py = Draw_Lines(px,py,358,value * scale,thickness_lines,Color.new(1.0,1.0,1.0,1.0))

                        if health >= 60 then
                            --60
                            scale = 8
    
                            if health < 75 then
                                value = health - 60
                            end
        
                            Render.Line(Vector2.new(px,py),Vector2.new( line_two[1],line_two[2]),Color.new(1.0,1.0,1.0,100 / 255))
                            Render.CircleFilled(Vector2.new(px,py),circle_radius,30,Color.new(1.0,1.0,1.0,1.0))

                            px,py = Draw_Lines(px,py,15,value * scale,thickness_lines,Color.new(1.0,1.0,1.0,1.0))
                            if health >= 75 then
                                --75
                                scale = 1
    
                                if health < 80 then
                                    value = health - 75
                                end

                                Render.CircleFilled(Vector2.new(px,py),circle_radius,30,Color.new(1.0,1.0,1.0,1.0))
                                px,py = Draw_Lines(px,py,355,value * scale,thickness_lines,Color.new(1.0,1.0,1.0,1.0))
                                if health >= 80 then
                                    --80
                                    scale = 5
                                    if health < 90 then
                                        value = health - 80
                                    end

                                    Render.Line(Vector2.new(px,py),Vector2.new( line_three[1],line_three[2]),Color.new(1.0,1.0,1.0,100 / 255))
                                    Render.CircleFilled(Vector2.new(px,py),circle_radius,30,Color.new(1.0,1.0,1.0,1.0))

                                    px,py = Draw_Lines(px,py,10,value * scale,thickness_lines,Color.new(1.0,1.0,1.0,1.0))
                                        if health >= 90 then

                                            scale = 5
                                            value = health - 95

                                            Render.Line(Vector2.new(px,py),Vector2.new( line_three[1],line_three[2]),Color.new(1.0,1.0,1.0,100 / 255))
                                            
                                            Render.CircleFilled(Vector2.new(px,py),circle_radius,30,Color.new(1.0,1.0,1.0,1.0))
                                            
                                            px,py = Draw_Lines(px,py,10,value * scale,thickness_lines,Color.new(1.0,1.0,1.0,1.0))
                                           
                                            --Render.CircleFilled(Vector2.new(px,py),circle_radius,30,Color.new(1.0,1.0,1.0,1.0))
                                            
                                        end
                                end
                            end
                        end
                    end
                end
            end
        end

    end
end

end

Consteli_Init()

local nn_indicator_draw
local function NN_Indicator_Init()
    local pixel = Render.InitFont("Smallest Pixel-7", 10)

--binds
local isMD = Menu.FindVar("Aimbot","Ragebot","Accuracy","Minimum Damage")
local isBA = Menu.FindVar("Aimbot","Ragebot","Misc","Body Aim")
local isSP = Menu.FindVar("Aimbot","Ragebot","Misc","Safe Points")
local isDT = Menu.FindVar("Aimbot","Ragebot","Exploits","Double Tap")
local isAP = Menu.FindVar("Miscellaneous","Main","Movement","Auto Peek")
local isSW = Menu.FindVar("Aimbot","Anti Aim","Misc","Slow Walk")
local isHS = Menu.FindVar("Aimbot","Ragebot","Exploits","Hide Shots")
local yaw_base = Menu.FindVar("Aimbot","Anti Aim","Main","Yaw Base")
local NN_Enable = Menu.Switch("UNMANNED Indicator","Enable",false)

--indicators
function desync_delta()
    local desync_rotation = AntiAim.GetFakeRotation()
    local real_rotation = AntiAim.GetCurrentRealRotation()
    local delta_to_draw = math.min(math.abs(real_rotation - desync_rotation) / 2, 60)
    return string.format("%.1f", delta_to_draw)
end
local fake = desync_delta()
local currentTime = GlobalVars.curtime
local indicators = function()
    --screen size
    local x = EngineClient.GetScreenSize().x
    local y = EngineClient.GetScreenSize().y

    --invert state
    if AntiAim.GetInverterState() == false then
        invert ="R"
    else
        invert ="L"
    end

    --binds
    local mdmg = false
    local binds = Cheat.GetBinds()
    for i = 1, #binds do
        local bind = binds[i]
        if bind:GetName() == 'Minimum Damage' then
            mdmg = true
        end
    end

    --fake
    if currentTime + 0.38 < GlobalVars.curtime then
        currentTime = GlobalVars.curtime
        fake = desync_delta()
    end

    --screen size
    local ay = 40
    local alpha = math.min(math.floor(math.sin((GlobalVars.realtime%3) * 4) * 175 + 50), 255)

    --render
    local eternal_ts = Render.CalcTextSize("unmanned ", 10, pixel)
    Render.Text("unmanned", Vector2.new(x/2, y/2+ay), Color.RGBA(130, 130, 255, 255), 10, pixel, true)
    Render.Text("YAW", Vector2.new(x/2+eternal_ts.x-2, y/2+ay), Color.RGBA(130, 130, 255, 255), 10, pixel, true)                                                                                                                                                                     
    ay = ay + 10.5
    
    local text_ =""
    local clr0 = Color.RGBA(0, 0, 0, 0)
    if isSW:GetBool() then
        text_ ="DANGEROUS+ "
        clr0 = Color.RGBA(130, 130, 255, 255)
    else
        text_ ="DYNAMIC- "
        clr0 = Color.RGBA(130, 130, 255, 255)
    end

    local d_ts = Render.CalcTextSize(text_, 10, pixel)
    Render.Text(text_, Vector2.new(x/2, y/2+ay), clr0, 10, pixel, true)
    Render.Text(math.floor(fake).."°", Vector2.new(x/2+d_ts.x, y/2+ay), Color.RGBA(130, 130, 255, 255), 10, pixel, true)
    ay = ay + 10.5
    
    local fake_ts = Render.CalcTextSize("FAKE YAW: ", 10, pixel)
    Render.Text("FAKE YAW:", Vector2.new(x/2, y/2+ay), Color.RGBA(130, 130, 255, 255), 10, pixel, true)
    Render.Text(invert, Vector2.new(x/2+fake_ts.x, y/2+ay), Color.RGBA(130, 130, 255, 255), 10, pixel, true)
    ay = ay + 10.5

    local asadsa = math.min(math.floor(math.sin((Exploits.GetCharge()%2) * 1) * 122), 100)
    if isAP:GetBool() and isDT:GetBool() then 
        local ts_tick = Render.CalcTextSize("IDEALTICK ", 10, pixel)
        Render.Text("IDEALTICK", Vector2.new(x/2, y/2+ay), Color.RGBA(255, 255, 255, 255), 10, pixel, true)
        Render.Text("x"..asadsa, Vector2.new(x/2+ts_tick.x, y/2+ay), Exploits.GetCharge() == 1 and Color.RGBA(0, 255, 0, 255) or Color.RGBA(255, 0, 0, 255), 10, pixel, true)
        ay = ay + 10.5
    else
        if isAP:GetBool() then
            Render.Text("PEEK", Vector2.new(x/2, y/2+ay), Color.RGBA(130, 130, 255, 255), 10, pixel, true)
            ay = ay + 10.5
        end
        if isDT:GetBool() then
            Render.Text("DT", Vector2.new(x/2, y/2+ay), Exploits.GetCharge() == 1 and Color.RGBA(130, 130, 255, 255) or Color.RGBA(255, 255, 255, 255), 10, pixel, true)
            ay = ay + 10.5
        end
    end

    if mdmg == true then
        Render.Text("MD: "..tostring(isMD:GetInt()), Vector2.new(x/2, y/2+ay), Color.RGBA(130, 130, 255, 255), 10, pixel, true)
        ay = ay + 10.5
    end

    local ax = 0
    if isHS:GetBool() then
        Render.Text("ONSHOT", Vector2.new(x/2, y/2+ay), Color.RGBA(130, 130, 255, 255), 10, pixel, true)
        ay = ay + 10.5
    end

    Render.Text("BAIM", Vector2.new(x/2, y/2+ay), isBA:GetInt() == 2 and Color.RGBA(130, 130, 255, 255) or Color.RGBA(255, 255, 255, 128), 10, pixel, true)
    ax = ax + Render.CalcTextSize("BAIM ", 10, pixel).x

    Render.Text("SP", Vector2.new(x/2+ax, y/2+ay), isSP:GetInt() == 2 and Color.RGBA(130, 130, 255, 255) or Color.RGBA(255, 255, 255, 128), 10, pixel, true)
    ax = ax + Render.CalcTextSize("SP ", 10, pixel).x

    Render.Text("FS", Vector2.new(x/2+ax, y/2+ay), yaw_base:GetInt() == 5 and Color.RGBA(130, 130, 255, 255) or Color.RGBA(255, 255, 255, 128), 10, pixel, true)
end

nn_indicator_draw = function()
    local lp = EntityList.GetClientEntity(EngineClient.GetLocalPlayer())
    if lp == nil then return end
    if not EngineClient.IsConnected() then return end
    if lp:GetProp("m_iHealth") > 0 and NN_Enable:GetBool() then
        indicators()
    end
end
end
NN_Indicator_Init()

local damage_draw,damage_register_shot
local function Damage_Indicator()
    local damage_enable = Menu.Switch("Damage Indicator","Enable",false)
local damage_clr = Menu.ColorEdit("Damage Indicator","Color",Color.new(1.0,1.0,1.0,1.0))
local damage_font = Menu.SliderFloat("Damage Indicator","Size",15.0,8.0,40.0)
local damage_saves = {}

local function clamp(v,min,max)
    if v > max then
        return max
    elseif v < min then
        return min
    end

    return v
end

damage_draw = function()
    local lplayer = EntityList.GetLocalPlayer()
    if not lplayer or not damage_enable:GetBool() then
        damage_saves = {}
        return
    end

    for i = 1,#damage_saves do
        local t = damage_saves[i]
        if t == nil then
            return
        end
        
        if t.alpha == 0 then
            table.remove(damage_saves,i)
            goto skip
        end

        local screen_pos = Render.WorldToScreen(t.hit_origin)
        local clr = damage_clr:Get()
  
        clr.a = t.alpha
        Render.Text(tostring(t.hit_damage),screen_pos,clr,11.0)
        t.alpha = t.alpha - 0.01
        t.alpha = clamp(t.alpha,0,1)
        ::skip::
    end
end

damage_register_shot = function(shot)
    local lplayer = EntityList.GetLocalPlayer()
    if not lplayer or not (lplayer:GetProp("m_iHealth") > 0) or not damage_enable:GetBool() or shot.reason ~= 0 then
        return
    end

    table.insert(damage_saves,{
        hit_damage = shot.damage,
        hit_origin = EntityList.GetClientEntity(shot.target_index):GetPlayer():GetHitboxCenter(shot.hitgroup),
        alpha = 1.0
    })
end
end
Damage_Indicator()

Cheat.RegisterCallback("prediction",function (cmd)
    unnamed_prediction(cmd)
end)

Cheat.RegisterCallback("createmove",function (cmd)
    unnamed_jz_createmove(cmd)
end)

Cheat.RegisterCallback("draw", function()
    indicator_draw()
    skeet_indicator_draw()
    visible_points_draw()
    constrli_draw()
    nn_indicator_draw()
    damage_draw()
end)

Cheat.RegisterCallback("events", function(e)
	indicator_event(e)
    log_event_reset(e)
end)

Cheat.RegisterCallback("registered_shot", function (info)
    log_shot_print(info)
    hitsound_register_shot(info)
    damage_register_shot(info)
end)

Cheat.RegisterCallback("ragebot_shot", function(shot)
    log_main(shot)
end)
