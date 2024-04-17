AddCSLuaFile()

local table = table

-- Initialize role features
hook.Add("TTTIsPlayerRespawning", "Infected_TTTIsPlayerRespawning", function(ply)
    if not IsPlayer(ply) then return end
    if ply:Alive() then return end

    if ply:GetNWBool("InfectedIsZombifying", false) then
        return true
    end
end)

------------------
-- ROLE CONVARS --
------------------

CreateConVar("ttt_infected_prime", "1", FCVAR_NONE, "Whether the infected will become a prime zombie", 0, 1)
CreateConVar("ttt_infected_cough_enabled", "1", FCVAR_REPLICATED, "Whether the infected coughs periodically", 0, 1)
CreateConVar("ttt_infected_respawn_enabled", "0", FCVAR_REPLICATED, "Whether the infected will respawn as a zombie when killed", 0, 1)
CreateConVar("ttt_infected_show_icon", "1", FCVAR_REPLICATED, "Whether to show the infected icon over their head for zombies and zombie allies", 0, 1)
CreateConVar("ttt_infected_succumb_time", "180", FCVAR_REPLICATED, "Time in seconds for the infected to succumb to their disease", 0, 300)
CreateConVar("ttt_infected_full_health", "1", FCVAR_REPLICATED, "Whether the infected's health is refilled when they become a zombie", 0, 1)

ROLE_CONVARS[ROLE_INFECTED] = {}
table.insert(ROLE_CONVARS[ROLE_INFECTED], {
    cvar = "ttt_infected_succumb_time",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_INFECTED], {
    cvar = "ttt_infected_full_health",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_INFECTED], {
    cvar = "ttt_infected_prime",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_INFECTED], {
    cvar = "ttt_infected_respawn_enabled",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_INFECTED], {
    cvar = "ttt_infected_show_icon",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_INFECTED], {
    cvar = "ttt_infected_cough_enabled",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_INFECTED], {
    cvar = "ttt_infected_cough_timer_min",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_INFECTED], {
    cvar = "ttt_infected_cough_timer_max",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})