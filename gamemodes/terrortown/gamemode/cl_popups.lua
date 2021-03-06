-- Some popup window stuff

local GetTranslation = LANG.GetTranslation
local GetPTranslation = LANG.GetParamTranslation

---- Round start

local function GetTextForLocalPlayer()
    local menukey = Key("+menu_context", "C")

    local client = LocalPlayer()
    if client:IsRevenger() then
        local sid = LocalPlayer():GetNWString("RevengerLover", "")
        local lover = player.GetBySteamID64(sid)
        local name = "someone"
        if IsValid(lover) and lover:IsPlayer() then name = lover:Nick() end
        return GetPTranslation("info_popup_revenger", { lover = name })

    elseif client:IsMonsterTeam() then
        local allies = {}
        for _, ply in ipairs(player.GetAll()) do
            if ply:IsMonsterTeam() then
                table.insert(allies, ply)
            end
        end

        local roleString = client:GetRoleStringRaw()
        local text
        if #allies > 1 then
            local allylist = ""

            for _, ply in ipairs(allies) do
                if ply ~= client then
                    allylist = allylist .. string.rep(" ", 42) .. ply:Nick() .. "\n"
                end
            end

            text = GetPTranslation("info_popup_" .. roleString, { menukey = menukey, allylist = allylist })
        else
            text = GetPTranslation("info_popup_" .. roleString.. "_alone", { menukey = menukey })
        end

        return text

    elseif client:IsTraitorTeam() then
        local traitors = {}
        local glitches = {}
        for _, ply in ipairs(player.GetAll()) do
            if ply:IsTraitorTeam() then
                table.insert(traitors, ply)
            elseif ply:IsGlitch() then
                table.insert(traitors, ply)
                table.insert(glitches, ply)
            end
        end

        local assassintarget = nil
        if client:IsAssassin() then
            assassintarget = string.rep(" ", 42) .. client:GetNWString("AssassinTarget", "")
        end

        local roleString = client:GetRoleStringRaw()
        local text
        if #traitors > 1 then
            local traitorlist = ""

            for _, ply in ipairs(traitors) do
                if ply ~= client then
                    traitorlist = traitorlist .. string.rep(" ", 42) .. ply:Nick() .. "\n"
                end
            end

            if #glitches > 0 then
                text = GetPTranslation("info_popup_" .. roleString.. "_glitch", { menukey = menukey, traitorlist = traitorlist, allylist = traitorlist, assassintarget = assassintarget })
            else
                text = GetPTranslation("info_popup_" .. roleString, { menukey = menukey, traitorlist = traitorlist, allylist = traitorlist, assassintarget = assassintarget })
            end
        else
            text = GetPTranslation("info_popup_" .. roleString.. "_alone", { menukey = menukey, assassintarget = assassintarget })
        end

        return text
    -- Zombies not on Traitor or Monster teams have a different message
    elseif client:IsZombie() then
        return GetPTranslation("info_popup_zombie_indep", { menukey = menukey })
    else
        return GetPTranslation("info_popup_" .. client:GetRoleStringRaw(), { menukey = menukey })
    end
end

local startshowtime = CreateConVar("ttt_startpopup_duration", "17", FCVAR_ARCHIVE)
-- shows info about goal and fellow traitors (if any)
local function RoundStartPopup()
    -- based on Derma_Message

    if startshowtime:GetInt() <= 0 then return end

    if not LocalPlayer() then return end

    local dframe = vgui.Create("Panel")
    dframe:SetDrawOnTop(true)
    dframe:SetMouseInputEnabled(false)
    dframe:SetKeyboardInputEnabled(false)

    local color = Color(0, 0, 0, 200)
    dframe.Paint = function(s)
        draw.RoundedBox(8, 0, 0, s:GetWide(), s:GetTall(), color)
    end

    local text = GetTextForLocalPlayer()

    local dtext = vgui.Create("DLabel", dframe)
    dtext:SetFont("TabLarge")
    dtext:SetText(text)
    dtext:SizeToContents()
    dtext:SetContentAlignment(5)
    dtext:SetTextColor(color_white)

    local w, h = dtext:GetSize()
    local m = 10

    dtext:SetPos(m, m)

    dframe:SetSize(w + m * 2, h + m * 2)
    dframe:Center()

    dframe:AlignBottom(10)

    timer.Simple(startshowtime:GetInt(), function() dframe:Remove() end)
end
concommand.Add("ttt_cl_startpopup", RoundStartPopup)

--- Idle message

local function IdlePopup()
    local w, h = 300, 180

    local dframe = vgui.Create("DFrame")
    dframe:SetSize(w, h)
    dframe:Center()
    dframe:SetTitle(GetTranslation("idle_popup_title"))
    dframe:SetVisible(true)
    dframe:SetMouseInputEnabled(true)

    local inner = vgui.Create("DPanel", dframe)
    inner:StretchToParent(5, 25, 5, 45)

    local idle_limit = GetGlobalInt("ttt_idle_limit", 300) or 300

    local text = vgui.Create("DLabel", inner)
    text:SetWrap(true)
    text:SetText(GetPTranslation("idle_popup", { num = idle_limit, helpkey = Key("gm_showhelp", "F1") }))
    text:SetDark(true)
    text:StretchToParent(10, 5, 10, 5)

    local bw, bh = 75, 25
    local cancel = vgui.Create("DButton", dframe)
    cancel:SetPos(10, h - 40)
    cancel:SetSize(bw, bh)
    cancel:SetText(GetTranslation("idle_popup_close"))
    cancel.DoClick = function() dframe:Close() end

    local disable = vgui.Create("DButton", dframe)
    disable:SetPos(w - 185, h - 40)
    disable:SetSize(175, bh)
    disable:SetText(GetTranslation("idle_popup_off"))
    disable.DoClick = function()
        RunConsoleCommand("ttt_spectator_mode", "0")
        dframe:Close()
    end

    dframe:MakePopup()

end
concommand.Add("ttt_cl_idlepopup", IdlePopup)
