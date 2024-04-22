local hook = hook

-------------
-- CONVARS --
-------------

local impersonator_damage_penalty = GetConVar("ttt_impersonator_damage_penalty")

------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "Impersonator_Translations_Initialize", function()
    -- Cheat Sheet
    LANG.AddToLanguage("english", "cheatsheet_desc_impersonator", "Promoted to replace the detective in the event of their death, but they are still a member of the traitor team.")

    -- Popup
    LANG.AddToLanguage("english", "info_popup_impersonator", [[You are {role}! {comrades}

If the {detective} dies you will appear to become a new {detective} and gain their
abilities just like the {deputy}. However you are still working for the {traitors}.

Press {menukey} to receive your special equipment!]])
end)

--------------
-- TUTORIAL --
--------------

hook.Add("TTTTutorialRoleText", "Impersonator_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_IMPERSONATOR then
        local roleColor = ROLE_COLORS[ROLE_TRAITOR]
        local html = "The " .. ROLE_STRINGS[ROLE_IMPERSONATOR] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>traitor team</span> whose goal is to wait for the " .. ROLE_STRINGS[ROLE_DETECTIVE] .. " to die (or <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>kill them</span>)."

        -- Promotion
        html = html .. "<span style='display: block; margin-top: 10px;'>After the " .. ROLE_STRINGS[ROLE_DETECTIVE] .. " is killed, <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>the " .. ROLE_STRINGS[ROLE_IMPERSONATOR] .. " is \"promoted\"</span> and then must pretend to be the new " .. ROLE_STRINGS[ROLE_DETECTIVE] .. ".</span>"
        html = html .. "<span style='display: block; margin-top: 10px;'>They have <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>all the powers of " .. ROLE_STRINGS_EXT[ROLE_DETECTIVE] .. "</span> including " .. ROLE_STRINGS[ROLE_DETECTIVE] .. "-only weapons and the ability to search bodies.</span>"

        -- Damage penalty
        if impersonator_damage_penalty:GetFloat() > 0 then
            html = html .. "<span style='display: block; margin-top: 10px;'>Be careful though! Before the " .. ROLE_STRINGS[ROLE_IMPERSONATOR] .. " has been promoted, they <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>do less damage</span>.</span>"
        end

        local impersonator_use_detective_icon = GetConVar("ttt_impersonator_use_detective_icon"):GetBool()
        local deputy_use_detective_icon = GetConVar("ttt_deputy_use_detective_icon"):GetBool()

        -- Detective Icon for Everyone
        if impersonator_use_detective_icon and  deputy_use_detective_icon then
            html = html .. "<span style='display: block; margin-top: 10px;'>Once promoted, <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>all players</span> will see the " .. ROLE_STRINGS[ROLE_DETECTIVE] .. " icon over the " .. ROLE_STRINGS[ROLE_IMPERSONATOR] .. "'s head.</span>"
        else
            -- Icon for Traitors
            html = html .. "<span style='display: block; margin-top: 10px;'>Once promoted, <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>traitor team members</span> will see the "
            if impersonator_use_detective_icon then
                html = html .. ROLE_STRINGS[ROLE_DETECTIVE]
            else
                html = html .. ROLE_STRINGS[ROLE_IMPERSONATOR]
            end
            html = html .. " icon over the " .. ROLE_STRINGS[ROLE_IMPERSONATOR] .. "'s head.</span>"

            -- Icon for Everyone Else
            html = html .. "<span style='display: block; margin-top: 10px;'><span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>All other players</span> will see the "
            if deputy_use_detective_icon then
                html = html .. ROLE_STRINGS[ROLE_DETECTIVE]
            else
                html = html .. ROLE_STRINGS[ROLE_DEPUTY]
            end
            html = html .. " icon over the " .. ROLE_STRINGS[ROLE_IMPERSONATOR] .. "'s head.</span>"
        end

        return html
    end
end)