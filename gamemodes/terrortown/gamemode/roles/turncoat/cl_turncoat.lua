local hook = hook

-------------
-- CONVARS --
-------------

local turncoat_change_health = GetConVar("ttt_turncoat_change_health")
local turncoat_change_innocent_kill = GetConVar("ttt_turncoat_change_innocent_kill")

------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "Turncoat_Translations_Initialize", function()
    -- Events
    LANG.AddToLanguage("english", "ev_turncoat", "{nick} is {role} and has joined the {traitors}")

    -- Weapons
    LANG.AddToLanguage("english", "tur_changer", "Team Changer")
    LANG.AddToLanguage("english", "tur_changer_help_pri", "Press {primaryfire} to change teams.")
    LANG.AddToLanguage("english", "tur_changer_help_sec", "Be careful! Everyone will be told.")

    -- Cheat Sheet
    LANG.AddToLanguage("english", "cheatsheet_desc_turncoat", "Can switch sides and join the traitor team.")

    -- Popup
    LANG.AddToLanguage("english", "info_popup_turncoat", [[You are {role}! You are {aninnocent} who has a device
which will switch you to the {traitor} team but
announce it to everyone. Use it wisely!]])
end)

------------
-- EVENTS --
------------

hook.Add("Initialize", "Turncoat_Scoring_Initialize", function()
    local traitor_icon = Material("icon16/user_red.png")
    local Event = CLSCORE.DeclareEventDisplay
    local T = LANG.GetTranslation
    local PT = LANG.GetParamTranslation

    Event(EVENT_TURNCOATCHANGED, {
        text = function(e)
            return PT("ev_turncoat", {
                nick = e.nic,
                role = ROLE_STRINGS_EXT[ROLE_TURNCOAT],
                traitors = T("traitors")
            })
        end,
        icon = function(e)
            return traitor_icon, "Changed Teams"
        end})
end)

--------------
-- TUTORIAL --
--------------

hook.Add("TTTTutorialRoleText", "Turncoat_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_TURNCOAT then
        local roleColor = ROLE_COLORS[ROLE_INNOCENT]
        local html = "The " .. ROLE_STRINGS[ROLE_TURNCOAT] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>innocent team</span>."

        local traitorColor = ROLE_COLORS[ROLE_TRAITOR]
        html = html .. "<span style='display: block; margin-top: 10px;'>They are given a one-time-use Team Changer device which moves them to the <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>traitor team</span> and <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>announces their role to everyone</span>.</span>"

        if turncoat_change_innocent_kill:GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>If they kill a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>innocent team</span> then they will change teams automatically.</span>"
        end

        local health = turncoat_change_health:GetInt()
        return html .. "<span style='display: block; margin-top: 10px;'>At the same time, their <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>health is changed to</span> " .. health .. ".</span>"
    end
end)