local chat = chat
local net = net

local AddHook = hook.Add
local GetTranslation = LANG.GetTranslation

-- Death messages

AddHook("Initialize", "DeathNotify_Initialize", function()
    LANG.AddToLanguage("english", "deathnotify_suicide", "You killed yourself!")
    LANG.AddToLanguage("english", "deathnotify_burned", "You burned to death!")
    LANG.AddToLanguage("english", "deathnotify_prop", "You were killed by a prop!")
    LANG.AddToLanguage("english", "deathnotify_ply_start", "You were killed by ")
    LANG.AddToLanguage("english", "deathnotify_ply_mid", ", they were ")
    LANG.AddToLanguage("english", "deathnotify_ply_end", "!")
    LANG.AddToLanguage("english", "deathnotify_team_mid", ", they were on the ")
    LANG.AddToLanguage("english", "deathnotify_team_mid_hidden", ", they were on a ")
    LANG.AddToLanguage("english", "deathnotify_team_mid_hidden_name", "hidden")
    LANG.AddToLanguage("english", "deathnotify_team_end", " team!")
    LANG.AddToLanguage("english", "deathnotify_fell", "You fell to your death!")
    LANG.AddToLanguage("english", "deathnotify_water", "You drowned!")
    LANG.AddToLanguage("english", "deathnotify_nil", "You died!")
end)

net.Receive("TTT_ClientDeathNotify", function()
    -- Read the variables from the message
    local name = net.ReadString()
    local role = net.ReadInt(8)
    local reason = net.ReadString()

    -- Format the reason for their death
    if reason == "ply" then
        -- Format the number role into a human readable role and identifying color
        local roleString = ROLE_STRINGS_EXT[role]
        local col = ROLE_COLORS_HIGHLIGHT[role]
        chat.AddText(COLOR_WHITE, GetTranslation("deathnotify_ply_start"), col, name, COLOR_WHITE, GetTranslation("deathnotify_ply_mid"), col, roleString, COLOR_WHITE, GetTranslation("deathnotify_ply_end"))
    elseif reason == "team" then
        local midTranslation = "deathnotify_team_mid"
        local teamName, teamColor
        -- Special logic for if the role of the player is hidden
        if role == ROLE_NONE then
            midTranslation = midTranslation .. "_hidden"
            teamName = GetTranslation("deathnotify_team_mid_hidden_name")
            teamColor = ROLE_COLORS_HIGHLIGHT[role]
        else
            teamName, teamColor = GetRoleTeamInfo(role, true)
        end

        chat.AddText(COLOR_WHITE, GetTranslation("deathnotify_ply_start"), teamColor, name, COLOR_WHITE, GetTranslation(midTranslation), teamColor, teamName, COLOR_WHITE, GetTranslation("deathnotify_team_end"))
    else
        chat.AddText(COLOR_WHITE, GetTranslation("deathnotify_" .. reason))
    end
end)