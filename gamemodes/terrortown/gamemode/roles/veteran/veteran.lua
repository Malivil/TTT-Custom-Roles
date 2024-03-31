AddCSLuaFile()

local hook = hook
local math = math
local pairs = pairs
local player = player
local table = table

local PlayerIterator = player.Iterator

-------------
-- CONVARS --
-------------

local veteran_damage_bonus = CreateConVar("ttt_veteran_damage_bonus", "0.5", FCVAR_NONE, "Damage bonus that the veteran has when they are the last innocent alive (e.g. 0.5 = 50% more damage)", 0, 1)
local veteran_heal_bonus = CreateConVar("ttt_veteran_heal_bonus", "0", FCVAR_NONE, "The amount of bonus health to give the veteran when they are healed as the last remaining innocent", 0, 100)
local veteran_activation_credits = CreateConVar("ttt_veteran_activation_credits", "0", FCVAR_NONE, "The number of credits to give the veteran when they are activated", 0, 10)

local veteran_full_heal = GetConVar("ttt_veteran_full_heal")
local veteran_announce = GetConVar("ttt_veteran_announce")

-----------------
-- ROLE STATUS --
-----------------

hook.Add("PlayerDeath", "Veteran_RoleFeatures_PlayerDeath", function(victim, infl, attacker)
    local innocents_alive = 0
    local veterans = {}
    for _, v in PlayerIterator() do
        if v:IsActiveInnocentTeam() then innocents_alive = innocents_alive + 1 end
        if v:IsActiveVeteran() then table.insert(veterans, v) end
    end
    if #veterans > 0 and innocents_alive == #veterans then
        for _, v in pairs(veterans) do
            if not v:IsRoleActive() then
                v:SetNWBool("VeteranActive", true)
                v:AddCredits(veteran_activation_credits:GetInt())

                v:QueueMessage(MSG_PRINTBOTH, "You are the last " .. ROLE_STRINGS[ROLE_INNOCENT] .. " alive!")
                if veteran_announce:GetBool() then
                    for _, p in PlayerIterator() do
                        if p ~= v and p:IsActive() then
                            p:QueueMessage(MSG_PRINTBOTH, "The last " .. ROLE_STRINGS[ROLE_INNOCENT] .. " alive is " .. ROLE_STRINGS_EXT[ROLE_VETERAN] .. "!")
                        end
                    end
                end

                if veteran_full_heal:GetBool() then
                    local heal_bonus = veteran_heal_bonus:GetInt()
                    local health = math.min(v:GetMaxHealth(), 100) + heal_bonus

                    v:SetHealth(health)
                    if heal_bonus > 0 then
                        v:PrintMessage(HUD_PRINTTALK, "You have been fully healed (with a bonus)!")
                    else
                        v:PrintMessage(HUD_PRINTTALK, "You have been fully healed!")
                    end
                end

                -- Give the veteran their shop items if purchase was delayed
                if v.bought and GetConVar("ttt_veteran_shop_delay"):GetBool() then
                    v:GiveDelayedShopItems()
                end
            end
        end
    end
end)

hook.Add("ScalePlayerDamage", "Veteran_ScalePlayerDamage", function(ply, hitgroup, dmginfo)
    local att = dmginfo:GetAttacker()
    if IsPlayer(att) and GetRoundState() >= ROUND_ACTIVE then
        -- Veterans deal extra damage if they are the last innocent alive
        if att:IsVeteran() and att:IsRoleActive() then
            local bonus = veteran_damage_bonus:GetFloat()
            dmginfo:ScaleDamage(1 + bonus)
        end
    end
end)

hook.Add("TTTPrepareRound", "Veteran_RoleFeatures_PrepareRound", function()
    for _, v in PlayerIterator() do
        v:SetNWBool("VeteranActive", false)
    end
end)

hook.Add("TTTPlayerRoleChanged", "Veteran_TTTPlayerRoleChanged", function(ply, oldRole, newRole)
    if oldRole == ROLE_VETERAN and newRole ~= ROLE_VETERAN then
        ply:SetNWBool("VeteranActive", false)
    end
end)