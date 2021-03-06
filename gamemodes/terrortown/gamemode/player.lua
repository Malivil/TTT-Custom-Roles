---- Player spawning/dying

local math = math
local table = table
local player = player
local timer = timer
local pairs = pairs

CreateConVar("ttt_bots_are_spectators", "0", FCVAR_ARCHIVE)
CreateConVar("ttt_dyingshot", "0")

CreateConVar("ttt_killer_dna_range", "550")
CreateConVar("ttt_killer_dna_basetime", "100")

-- First spawn on the server
function GM:PlayerInitialSpawn(ply)
    if not GAMEMODE.cvar_init then
        GAMEMODE:InitCvars()
    end

    ply:InitialSpawn()

    local rstate = GetRoundState() or ROUND_WAIT
    -- We should update the traitor list, if we are not about to send it
    if rstate <= ROUND_PREP then
        SendAllLists()
    end

    -- Game has started, tell this guy where the round is at
    if rstate ~= ROUND_WAIT then
        SendRoundState(rstate, ply)
        SendAllLists(ply)
    end

    -- Handle spec bots
    if ply:IsBot() and GetConVar("ttt_bots_are_spectators"):GetBool() then
        ply:SetTeam(TEAM_SPEC)
        ply:SetForceSpec(true)
    end
end

function GM:NetworkIDValidated(name, steamid)
    -- edge case where player authed after initspawn
    for _, p in ipairs(player.GetAll()) do
        if IsValid(p) and p:SteamID() == steamid and p.delay_karma_recall then
            KARMA.LateRecallAndSet(p)
            return
        end
    end
end

function GM:PlayerSpawn(ply)
    -- stop bleeding
    util.StopBleeding(ply)

    -- Some spawns may be tilted
    ply:ResetViewRoll()

    -- Clear out stuff like whether we ordered guns or what bomb code we used
    ply:ResetRoundFlags()

    -- latejoiner, send him some info
    if GetRoundState() == ROUND_ACTIVE then
        SendRoundState(GetRoundState(), ply)
    end

    ply.has_spawned = true

    -- Reset player color, transparency, and render mode
    ply:SetColor(Color(255, 255, 255, 255))
    ply:SetMaterial("models/glass")
    ply:SetRenderMode(RENDERMODE_TRANSALPHA)

    -- let the client do things on spawn
    net.Start("TTT_PlayerSpawned")
    net.WriteBit(ply:IsSpec())
    net.Send(ply)

    if ply:IsSpec() then
        ply:StripAll()
        ply:Spectate(OBS_MODE_ROAMING)
        return
    end

    ply:UnSpectate()

    -- ye olde hooks
    hook.Call("PlayerLoadout", GAMEMODE, ply)
    hook.Call("PlayerSetModel", GAMEMODE, ply)
    hook.Call("TTTPlayerSetColor", GAMEMODE, ply)

    ply:SetupHands()

    SCORE:HandleSpawn(ply)
end

function GM:PlayerSetHandsModel(pl, ent)
    local simplemodel = player_manager.TranslateToPlayerModelName(pl:GetModel())
    local info = player_manager.TranslatePlayerHands(simplemodel)
    if info then
        ent:SetModel(info.model)
        ent:SetSkin(info.skin)
        ent:SetBodyGroups(info.body)
    end
end

function GM:IsSpawnpointSuitable(ply, spwn, force, rigged)
    if not IsValid(ply) or not ply:IsTerror() then return true end
    if not rigged and (not IsValid(spwn) or not spwn:IsInWorld()) then return false end

    -- spwn is normally an ent, but we sometimes use a vector for jury rigged
    -- positions
    local pos = rigged and spwn or spwn:GetPos()

    if not util.IsInWorld(pos) then return false end

    local blocking = ents.FindInBox(pos + Vector(-16, -16, 0), pos + Vector(16, 16, 64))

    for _, p in ipairs(blocking) do
        if IsValid(p) and p:IsPlayer() and p:IsTerror() and p:Alive() then
            if force then
                p:Kill()
            else
                return false
            end
        end
    end

    return true
end

local SpawnTypes = { "info_player_deathmatch", "info_player_combine",
                     "info_player_rebel", "info_player_counterterrorist", "info_player_terrorist",
                     "info_player_axis", "info_player_allies", "gmod_player_start",
                     "info_player_teamspawn" }

function GetSpawnEnts(shuffled, force_all)
    local tbl = {}
    for k, classname in ipairs(SpawnTypes) do
        for _, e in ipairs(ents.FindByClass(classname)) do
            if IsValid(e) and (not e.BeingRemoved) then
                table.insert(tbl, e)
            end
        end
    end

    -- Don't use info_player_start unless absolutely necessary, because eg. TF2
    -- uses it for observer starts that are in places where players cannot really
    -- spawn well. At all.
    if force_all or #tbl == 0 then
        for _, e in ipairs(ents.FindByClass("info_player_start")) do
            if IsValid(e) and (not e.BeingRemoved) then
                table.insert(tbl, e)
            end
        end
    end

    if shuffled then
        table.Shuffle(tbl)
    end

    return tbl
end

-- Generate points next to and above the spawn that we can test for suitability
local function PointsAroundSpawn(spwn)
    if not IsValid(spwn) then return {} end
    local pos = spwn:GetPos()

    local w, h = 36, 72 -- bit roomier than player hull

    -- all rigged positions
    -- could be done without typing them out, but would take about as much time
    return {
        pos + Vector(w, 0, 0),
        pos + Vector(0, w, 0),
        pos + Vector(w, w, 0),
        pos + Vector(-w, 0, 0),
        pos + Vector(0, -w, 0),
        pos + Vector(-w, -w, 0),
        pos + Vector(-w, w, 0),
        pos + Vector(w, -w, 0)
        --pos + Vector( 0,  0,  h) -- just in case we're outside
    };
end

function GM:PlayerSelectSpawn(ply)
    if (not self.SpawnPoints) or (table.IsEmpty(self.SpawnPoints)) or (not IsTableOfEntitiesValid(self.SpawnPoints)) then

        self.SpawnPoints = GetSpawnEnts(true, false)

        -- One might think that we have to regenerate our spawnpoint
        -- cache. Otherwise, any rigged spawn entities would not get reused, and
        -- MORE new entities would be made instead. In reality, the map cleanup at
        -- round start will remove our rigged spawns, and we'll have to create new
        -- ones anyway.
    end

    if table.IsEmpty(self.SpawnPoints) then
        Error("No spawn entity found!\n")
        return
    end

    -- Just always shuffle, it's not that costly and should help spawn
    -- randomness.
    table.Shuffle(self.SpawnPoints)

    -- Optimistic attempt: assume there are sufficient spawns for all and one is
    -- free
    for _, spwn in pairs(self.SpawnPoints) do
        if self:IsSpawnpointSuitable(ply, spwn, false) then
            return spwn
        end
    end

    -- That did not work, so now look around spawns
    local picked = nil

    for _, spwn in pairs(self.SpawnPoints) do
        picked = spwn -- just to have something if all else fails

        -- See if we can jury rig a spawn near this one
        local rigged = PointsAroundSpawn(spwn)
        for _, rig in pairs(rigged) do
            if self:IsSpawnpointSuitable(ply, rig, false, true) then
                local rig_spwn = ents.Create("info_player_terrorist")
                if IsValid(rig_spwn) then
                    rig_spwn:SetPos(rig)
                    rig_spwn:Spawn()

                    ErrorNoHalt("TTT WARNING: Map has too few spawn points, using a rigged spawn for " .. tostring(ply) .. "\n")

                    self.HaveRiggedSpawn = true
                    return rig_spwn
                end
            end
        end
    end

    -- Last attempt, force one
    for _, spwn in pairs(self.SpawnPoints) do
        if self:IsSpawnpointSuitable(ply, spwn, true) then
            return spwn
        end
    end

    return picked
end

function GM:PlayerSetModel(ply)
    local mdl = GAMEMODE.playermodel or "models/player/phoenix.mdl"
    util.PrecacheModel(mdl)
    ply:SetModel(mdl)

    -- Always clear color state, may later be changed in TTTPlayerSetColor
    ply:SetColor(COLOR_WHITE)
end

function GM:TTTPlayerSetColor(ply)
    local clr = COLOR_WHITE
    if GAMEMODE.playercolor then
        -- If this player has a colorable model, always use the same color as all
        -- other colorable players, so color will never be the factor that lets
        -- you tell players apart.
        clr = GAMEMODE.playercolor
    end
    ply:SetPlayerColor(Vector(clr.r / 255.0, clr.g / 255.0, clr.b / 255.0))
end


-- Only active players can use kill cmd
function GM:CanPlayerSuicide(ply)
    return ply:IsTerror()
end

function GM:PlayerSwitchFlashlight(ply, on)
    if not IsValid(ply) then return false end

    -- add the flashlight "effect" here, and then deny the switch
    -- this prevents the sound from playing, fixing the exploit
    -- where weapon sound could be silenced using the flashlight sound
    if (not on) or ply:IsTerror() then
        if on then
            ply:AddEffects(EF_DIMLIGHT)
        else
            ply:RemoveEffects(EF_DIMLIGHT)
        end
    end

    return false
end

function GM:PlayerSpray(ply)
    if not IsValid(ply) or not ply:IsTerror() then
        return true -- block
    end
end

function GM:PlayerUse(ply, ent)
    return ply:IsTerror()
end

function GM:KeyPress(ply, key)
    if not IsValid(ply) then return end

    -- Spectator keys
    if ply:IsSpec() and not ply:GetRagdollSpec() then

        if ply.propspec then
            return PROPSPEC.Key(ply, key)
        end

        if key == IN_RELOAD then
            local tgt = ply:GetObserverTarget()
            if not IsValid(tgt) or not tgt:IsPlayer() then return end

            if not ply.spec_mode or ply.spec_mode == OBS_MODE_CHASE then
                ply.spec_mode = OBS_MODE_IN_EYE
            elseif ply.spec_mode == OBS_MODE_IN_EYE then
                ply.spec_mode = OBS_MODE_CHASE
            end
            -- roam stays roam

            ply:Spectate(ply.spec_mode)
        end

        -- If the dead player is haunting their killer, don't let them switch views
        -- Instead use their button presses to do cool things to their killer
        if ply:GetNWBool("Haunting", false) then
            local killer = ply:GetObserverTarget()
            if not IsValid(killer) or not killer:Alive() then return end

            local action = nil
            -- Translate the key to the action, the undo action, how long it lasts, and how much it costs
            if key == IN_ATTACK then
                action = {"+attack", "-attack", 0.5, GetConVar("ttt_phantom_killer_haunt_attack_cost"):GetInt()}
            elseif key == IN_ATTACK2 then
                action = {"+menu", "-menu", 0.2, GetConVar("ttt_phantom_killer_haunt_drop_cost"):GetInt()}
            elseif key == IN_MOVELEFT or key == IN_MOVERIGHT or key == IN_FORWARD or key == IN_BACK then
                local moveCost = GetConVar("ttt_phantom_killer_haunt_move_cost"):GetInt()
                if key == IN_FORWARD then
                    action = {"+forward", "-forward", 0.5, moveCost}
                elseif key == IN_BACK then
                    action = {"+back", "-back", 0.5, moveCost}
                elseif key == IN_MOVELEFT then
                    action = {"+moveleft", "-moveleft", 0.5, moveCost}
                elseif key == IN_MOVERIGHT then
                    action = {"+moveright", "-moveright", 0.5, moveCost}
                end
            elseif key == IN_JUMP then
                action = {"+jump", "-jump", 0.2, GetConVar("ttt_phantom_killer_haunt_jump_cost"):GetInt()}
            end

            if action == nil then return end

            -- If this cost isn't valid, this action isn't valid
            local cost = action[4]
            if cost <= 0 then return end

            -- Check power level
            local currentpower = ply:GetNWInt("HauntingPower", 0)
            if currentpower < cost then return end

            -- Deduct the cost, run the command, and then run the un-command after the delay
            ply:SetNWInt("HauntingPower", currentpower - cost)
            killer:ConCommand(action[1])
            timer.Simple(action[3], function()
                killer:ConCommand(action[2])
            end)
            return
        end

        ply:ResetViewRoll()

        if key == IN_ATTACK then
            -- snap to random guy
            ply:Spectate(OBS_MODE_ROAMING)
            ply:SetEyeAngles(angle_zero) -- After exiting propspec, this could be set to awkward values
            ply:SpectateEntity(nil)

            local alive = util.GetAlivePlayers()

            if #alive < 1 then return end

            local target = table.Random(alive)
            if IsValid(target) then
                ply:SetPos(target:EyePos())
                ply:SetEyeAngles(target:EyeAngles())
            end
        elseif key == IN_ATTACK2 then
            -- spectate either the next guy or a random guy in chase
            local target = util.GetNextAlivePlayer(ply:GetObserverTarget())

            if IsValid(target) then
                ply:Spectate(ply.spec_mode or OBS_MODE_CHASE)
                ply:SpectateEntity(target)
            end
        elseif key == IN_DUCK then
            local pos = ply:GetPos()
            local ang = ply:EyeAngles()

            -- Only set the spectator's position to the player they are spectating if they are in chase or eye mode
            -- They can use the reload key if they want to return to the person they're spectating
            if ply:GetObserverMode() ~= OBS_MODE_ROAMING then
                local target = ply:GetObserverTarget()
                if IsValid(target) and target:IsPlayer() then
                    pos = target:EyePos()
                    ang = target:EyeAngles()
                end
            end

            -- reset
            ply:Spectate(OBS_MODE_ROAMING)
            ply:SpectateEntity(nil)

            ply:SetPos(pos)
            ply:SetEyeAngles(ang)
            return true
        elseif key == IN_JUMP then
            -- unfuck if you're on a ladder etc
            if ply:GetMoveType() ~= MOVETYPE_NOCLIP then
                ply:SetMoveType(MOVETYPE_NOCLIP)
            end
        end
    end
end

function GM:KeyRelease(ply, key)
    if key == IN_USE and IsValid(ply) and ply:IsTerror() then
        -- see if we need to do some custom usekey overriding
        local tr = util.TraceLine({
            start = ply:GetShootPos(),
            endpos = ply:GetShootPos() + ply:GetAimVector() * 84,
            filter = ply,
            mask = MASK_SHOT
        });

        if tr.Hit and IsValid(tr.Entity) then
            if tr.Entity.CanUseKey and tr.Entity.UseOverride then
                local phys = tr.Entity:GetPhysicsObject()
                if IsValid(phys) and not phys:HasGameFlag(FVPHYSICS_PLAYER_HELD) then
                    tr.Entity:UseOverride(ply)
                    return true
                else
                    -- do nothing, can't +use held objects
                    return true
                end
            elseif tr.Entity.player_ragdoll then
                CORPSE.ShowSearch(ply, tr.Entity, (ply:KeyDown(IN_WALK) or ply:KeyDownLast(IN_WALK)))
                return true
            end
        end
    end

end

-- Normally all dead players are blocked from IN_USE on the server, meaning we
-- can't let them search bodies. This sucks because searching bodies is
-- fun. Hence on the client we override +use for specs and use this instead.
local function SpecUseKey(ply, cmd, arg)
    if IsValid(ply) and ply:IsSpec() then
        -- longer range than normal use
        local tr = util.QuickTrace(ply:GetShootPos(), ply:GetAimVector() * 128, ply)
        if tr.Hit and IsValid(tr.Entity) then
            if tr.Entity.player_ragdoll then
                if not ply:KeyDown(IN_WALK) then
                    CORPSE.ShowSearch(ply, tr.Entity)
                else
                    ply:Spectate(OBS_MODE_IN_EYE)
                    ply:SpectateEntity(tr.Entity)
                end
            elseif tr.Entity:IsPlayer() and tr.Entity:IsActive() then
                ply:Spectate(ply.spec_mode or OBS_MODE_CHASE)
                ply:SpectateEntity(tr.Entity)
            else
                PROPSPEC.Target(ply, tr.Entity)
            end
        end
    end
end
concommand.Add("ttt_spec_use", SpecUseKey)

function GM:PlayerDisconnected(ply)
    -- Prevent the disconnecter from being in the resends
    if IsValid(ply) then
        ply:SetRole(ROLE_NONE)
    end

    if GetRoundState() ~= ROUND_PREP then
        SendAllLists()

        net.Start("TTT_PlayerDisconnected")
        net.WriteString(ply:Nick())
        net.Broadcast()
    end

    if KARMA.IsEnabled() then
        KARMA.Remember(ply)
    end
end

---- Death affairs

local function CreateDeathEffect(ent, marked)
    local pos = ent:GetPos() + Vector(0, 0, 20)

    local jit = 35.0

    local jitter = Vector(math.Rand(-jit, jit), math.Rand(-jit, jit), 0)
    util.PaintDown(pos + jitter, "Blood", ent)

    if marked then
        util.PaintDown(pos, "Cross", ent)
    end
end

local deathsounds = {
    Sound("player/death1.wav"),
    Sound("player/death2.wav"),
    Sound("player/death3.wav"),
    Sound("player/death4.wav"),
    Sound("player/death5.wav"),
    Sound("player/death6.wav"),
    Sound("vo/npc/male01/pain07.wav"),
    Sound("vo/npc/male01/pain08.wav"),
    Sound("vo/npc/male01/pain09.wav"),
    Sound("vo/npc/male01/pain04.wav"),
    Sound("vo/npc/Barney/ba_pain06.wav"),
    Sound("vo/npc/Barney/ba_pain07.wav"),
    Sound("vo/npc/Barney/ba_pain09.wav"),
    Sound("vo/npc/Barney/ba_ohshit03.wav"), --heh
    Sound("vo/npc/Barney/ba_no01.wav"),
    Sound("vo/npc/male01/no02.wav"),
    Sound("hostage/hpain/hpain1.wav"),
    Sound("hostage/hpain/hpain2.wav"),
    Sound("hostage/hpain/hpain3.wav"),
    Sound("hostage/hpain/hpain4.wav"),
    Sound("hostage/hpain/hpain5.wav"),
    Sound("hostage/hpain/hpain6.wav")
};

local function PlayDeathSound(victim)
    if not IsValid(victim) then return end

    sound.Play(table.Random(deathsounds), victim:GetShootPos(), 90, 100)
end

-- See if we should award credits now
local function CheckCreditAward(victim, attacker)
    if GetRoundState() ~= ROUND_ACTIVE then return end
    if not IsValid(victim) then return end

    local valid_attacker = IsValid(attacker) and attacker:IsPlayer()

    -- DETECTIVE AWARD
    if valid_attacker and (victim:IsTraitorTeam() or victim:IsMonsterTeam() or victim:IsKiller() or victim:IsZombie()) then
        local amt = GetConVarNumber("ttt_det_credits_traitordead") or 1
        for _, ply in ipairs(player.GetAll()) do
            if ply:IsActiveDetective() or (ply:IsActiveDeputy() and ply:GetNWBool("HasPromotion", false)) then
                ply:AddCredits(amt)
            end
        end

        LANG.Msg(GetDetectiveFilter(true), "credit_det_all", { num = amt })
    end

    -- TRAITOR AWARD
    if valid_attacker and not (victim:IsTraitorTeam() or victim:IsJesterTeam()) and (not GAMEMODE.AwardedCredits or GetConVar("ttt_credits_award_repeat"):GetBool()) then
        local inno_alive = 0
        local inno_dead = 0
        local inno_total = 0

        for _, ply in ipairs(player.GetAll()) do
            if not ply:IsTraitorTeam() then
                if ply:IsTerror() then
                    inno_alive = inno_alive + 1
                elseif ply:IsDeadTerror() then
                    inno_dead = inno_dead + 1
                end
            end
        end

        -- we check this at the death of an innocent who is still technically
        -- Alive(), so add one to dead count and sub one from living
        inno_dead = inno_dead + 1
        inno_alive = math.max(inno_alive - 1, 0)
        inno_total = inno_dead + inno_alive

        -- Only repeat-award if we have reached the pct again since last time
        if GAMEMODE.AwardedCredits then
            inno_dead = inno_dead - GAMEMODE.AwardedCreditsDead
        end

        local pct = inno_dead / inno_total
        if pct >= GetConVarNumber("ttt_credits_award_pct") then
            -- Traitors have killed sufficient people to get an award
            local amt = GetConVarNumber("ttt_credits_award_size")

            -- If size is 0, awards are off
            if amt > 0 then
                LANG.Msg(GetTraitorTeamFilter(true), "credit_tr_all", { num = amt })

                for _, ply in ipairs(player.GetAll()) do
                    if ply:IsActiveTraitorTeam() and ply:IsActiveShopRole() then
                        ply:AddCredits(amt)
                    end
                end
            end

            GAMEMODE.AwardedCredits = true
            GAMEMODE.AwardedCreditsDead = inno_dead + GAMEMODE.AwardedCreditsDead
        end
    end

    -- VAMPIRE AWARD
    if valid_attacker and not TRAITOR_ROLES[ROLE_VAMPIRE] and attacker:IsActiveVampire() and (not (victim:IsMonsterTeam() or victim:IsJesterTeam())) and (not GAMEMODE.AwardedVampireCredits or GetConVar("ttt_credits_award_repeat"):GetBool()) then
        local ply_alive = 0
        local ply_dead = 0
        local ply_total = 0

        for _, ply in pairs(player.GetAll()) do
            if not ply:IsVampireAlly() then
                if ply:IsTerror() then
                    ply_alive = ply_alive + 1
                elseif ply:IsDeadTerror() then
                    ply_dead = ply_dead + 1
                end
            end
        end

        -- we check this at the death of an innocent who is still technically
        -- Alive(), so add one to dead count and sub one from living
        ply_dead = ply_dead + 1
        ply_alive = math.max(ply_alive - 1, 0)
        ply_total = ply_alive + ply_dead

        -- Only repeat-award if we have reached the pct again since last time
        if GAMEMODE.AwardedVampireCredits then
            ply_dead = ply_dead - GAMEMODE.AwardedVampireCreditsDead
        end

        local pct = ply_dead / ply_total
        if pct >= GetConVarNumber("ttt_credits_award_pct") then
            -- Traitors have killed sufficient people to get an award
            local amt = GetConVarNumber("ttt_credits_award_size")

            -- If size is 0, awards are off
            if amt > 0 then
                LANG.Msg(GetVampireFilter(true), "credit_vam", { num = amt })

                for _, ply in pairs(player.GetAll()) do
                    if ply:IsActiveVampire() then
                        ply:AddCredits(amt)
                    end
                end
            end

            GAMEMODE.AwardedVampireCredits = true
            GAMEMODE.AwardedVampireCreditsDead = ply_dead + GAMEMODE.AwardedVampireCreditsDead
        end
    end

    -- KILLER AWARD
    if valid_attacker and attacker:IsActiveKiller() and (not (victim:IsKiller() or victim:IsJesterTeam())) and (not GAMEMODE.AwardedKillerCredits or GetConVar("ttt_credits_award_repeat"):GetBool()) then
        local ply_alive = 0
        local ply_dead = 0
        local ply_total = 0

        for _, ply in pairs(player.GetAll()) do
            if not ply:IsKiller() then
                if ply:IsTerror() then
                    ply_alive = ply_alive + 1
                elseif ply:IsDeadTerror() then
                    ply_dead = ply_dead + 1
                end
            end
        end

        -- we check this at the death of an innocent who is still technically
        -- Alive(), so add one to dead count and sub one from living
        ply_dead = ply_dead + 1
        ply_alive = math.max(ply_alive - 1, 0)
        ply_total = ply_alive + ply_dead

        -- Only repeat-award if we have reached the pct again since last time
        if GAMEMODE.AwardedKillerCredits then
            ply_dead = ply_dead - GAMEMODE.AwardedKillerCreditsDead
        end

        local pct = ply_dead / ply_total
        if pct >= GetConVarNumber("ttt_credits_award_pct") then
            -- Traitors have killed sufficient people to get an award
            local amt = GetConVarNumber("ttt_credits_award_size")

            -- If size is 0, awards are off
            if amt > 0 then
                LANG.Msg(GetKillerFilter(true), "credit_kil", { num = amt })

                for _, ply in pairs(player.GetAll()) do
                    if ply:IsActiveKiller() then
                        ply:AddCredits(amt)
                    end
                end
            end

            GAMEMODE.AwardedKillerCredits = true
            GAMEMODE.AwardedKillerCreditsDead = ply_dead + GAMEMODE.AwardedKillerCreditsDead
        end
    end
end

local offsets = {}

for i = 0, 360, 15 do
    table.insert(offsets, Vector(math.sin(i), math.cos(i), 0))
end

function FindRespawnLocation(pos)
    local midsize = Vector(33, 33, 74)
    local tstart = pos + Vector(0, 0, midsize.z / 2)

    for i = 1, #offsets do
        local o = offsets[i]
        local v = tstart + o * midsize * 1.5

        local t = {
            start = v,
            endpos = v,
            mins = midsize / -2,
            maxs = midsize / 2
        }

        local tr = util.TraceHull(t)

        if not tr.Hit then return (v - Vector(0, 0, midsize.z / 2)) end
    end

    return false
end

local function ShouldShowJesterNotification(target, mode)
    -- 1 - Only notify Traitors and Detective-likes
    -- 2 - Only notify Traitors
    -- 3 - Only notify Detective-likes
    -- 4 - Notify everyone
    -- Otherwise - Don't notify anyone
    if mode == JESTER_NOTIFY_DETECTIVE_AND_TRAITOR then
        return target:IsDetectiveLike() or target:IsTraitorTeam()
    elseif mode == JESTER_NOTIFY_TRAITOR then
        return target:IsTraitorTeam()
    elseif mode == JESTER_NOTIFY_DETECTIVE then
        return target:IsDetectiveLike()
    elseif mode == JESTER_NOTIFY_EVERYONE then
        return true
    end
    return false
end

local function JesterTeamKilledNotification(role_string, attacker, victim, getkillstring, shouldshow)
    local lower_role = role_string:lower()
    local mode = GetConVar("ttt_" .. lower_role .. "_notify_mode"):GetInt()
    local play_sound = GetConVar("ttt_" .. lower_role .. "_notify_sound"):GetBool()
    local show_confetti = GetConVar("ttt_" .. lower_role .. "_notify_confetti"):GetBool()
    for _, ply in pairs(player.GetAll()) do
        if ply == attacker then
            ply:PrintMessage(HUD_PRINTCENTER, "You killed the " .. role_string .. "!")
        elseif (shouldshow == nil or shouldshow(ply)) and ShouldShowJesterNotification(ply, mode) then
            ply:PrintMessage(HUD_PRINTCENTER, getkillstring(ply))
        end

        if play_sound or show_confetti then
            net.Start("TTT_JesterDeathCelebration")
            net.WriteEntity(victim)
            net.WriteBool(play_sound)
            net.WriteBool(show_confetti)
            net.Send(ply)
        end
    end
end

local function JesterKilledNotification(attacker, victim)
    JesterTeamKilledNotification("Jester", attacker, victim,
        -- getkillstring
        function()
            return attacker:Nick() .. " was dumb enough to kill the Jester!"
        end,
        -- shouldshow
        function()
            -- Don't announce anything if the game doesn't end here and the Jester was killed by a traitor
            return not (not GetConVar("ttt_jester_win_by_traitors"):GetBool() and attacker:IsTraitorTeam())
        end)
end

local function SwapperKilledNotification(attacker, victim)
    JesterTeamKilledNotification("Swapper", attacker, victim,
        -- getkillstring
        function(ply)
            local target = "someone"
            if ply:IsTraitorTeam() or attacker:IsDetectiveLike() then
                target = ROLE_STRINGS_EXT[attacker:GetRole()] .. " (" .. attacker:Nick() .. ")"
            end
            return "The swapper (" .. victim:Nick() .. ") has swapped with " .. target .. "!"
        end)
end

local function BeggarKilledNotification(attacker, victim)
    JesterTeamKilledNotification("Beggar", attacker, victim,
        -- getkillstring
        function()
            return attacker:Nick() .. " cruelly killed the lowly Beggar!"
        end)
end

local deadPhantoms = {}
local deadParasites = {}
hook.Add("TTTPrepareRound", function()
    deadPhantoms = {}
    deadParasites = {}
end)

function GM:DoPlayerDeath(ply, attacker, dmginfo)
    if ply:IsSpec() then return end

    -- Respawn the phantom
    if ply:GetNWBool("Haunted", false) then
        local respawn = false
        local phantomUsers = table.GetKeys(deadPhantoms)
        for _, key in pairs(phantomUsers) do
            local phantom = deadPhantoms[key]
            if phantom.attacker == ply:SteamID64() and IsValid(phantom.player) then
                local deadPhantom = phantom.player
                deadPhantom:SetNWBool("Haunting", false)
                deadPhantom:SetNWString("HauntingTarget", nil)
                deadPhantom:SetNWInt("HauntingPower", 0)
                timer.Remove(deadPhantom:Nick() .. "HauntingPower")
                timer.Remove(deadPhantom:Nick() .. "HauntingSpectate")
                if deadPhantom:IsPhantom() and not deadPhantom:Alive() then
                    -- Find the Phantom's corpse
                    local phantomBody = deadPhantom.server_ragdoll or deadPhantom:GetRagdollEntity()
                    if IsValid(phantomBody) then
                        deadPhantom:SpawnForRound(true)
                        deadPhantom:SetPos(FindRespawnLocation(phantomBody:GetPos()) or phantomBody:GetPos())
                        deadPhantom:SetEyeAngles(Angle(0, phantomBody:GetAngles().y, 0))

                        local health = GetConVar("ttt_phantom_respawn_health"):GetInt()
                        if GetConVar("ttt_phantom_weaker_each_respawn"):GetBool() then
                            -- Don't reduce them the first time since 50 is already reduced
                            for _ = 1, phantom.times - 1 do
                                health = health / 2
                            end
                            health = math.max(1, math.Round(health))
                        end
                        deadPhantom:SetHealth(health)
                        phantomBody:Remove()
                        deadPhantom:PrintMessage(HUD_PRINTCENTER, "Your attacker died and you have been respawned.")
                        respawn = true
                    else
                        deadPhantom:PrintMessage(HUD_PRINTCENTER, "Your attacker died but your body has been destroyed.")
                    end
                end
            end
        end

        if respawn and GetConVar("ttt_phantom_announce_death"):GetBool() then
            for _, v in pairs(player.GetAll()) do
                if v:IsDetectiveLike() and v:Alive() and not v:IsSpec() then
                    v:PrintMessage(HUD_PRINTCENTER, "The phantom has been respawned.")
                end
            end
        end

        ply:SetNWBool("Haunted", false)
        SendFullStateUpdate()
    end

    -- Handle assassin kills
    local attackertarget = attacker:GetNWString("AssassinTarget", "")
    if attacker:IsPlayer() and attacker:IsAssassin() and ply ~= attacker and ply:Nick() ~= attackertarget and (attackertarget ~= "" or timer.Exists(attacker:Nick() .. "AssassinTarget")) then
        timer.Remove(attacker:Nick() .. "AssassinTarget")
        attacker:PrintMessage(HUD_PRINTCENTER, "Contract failed. You killed the wrong player.")
        attacker:PrintMessage(HUD_PRINTTALK, "Contract failed. You killed the wrong player.")
        attacker:SetNWString("AssassinTarget", "")
        attacker:SetNWBool("AssassinFailed", true)
    end

    for _, v in pairs(player.GetAll()) do
        local assassintarget = v:GetNWString("AssassinTarget", "")
        if v:IsAssassin() and ply:Nick() == assassintarget then
            local delay = GetConVar("ttt_assassin_next_target_delay"):GetFloat()
            -- Delay giving the next target if we're configured to do so
            if delay > 0 then
                if v:Alive() and not v:IsSpec() then
                    v:PrintMessage(HUD_PRINTCENTER, "Target eliminated. You will receive your next assignment in " .. tostring(delay) .. " seconds.")
                    v:PrintMessage(HUD_PRINTTALK, "Target eliminated. You will receive your next assignment in " .. tostring(delay) .. " seconds.")
                end
                timer.Create(v:Nick() .. "AssassinTarget", delay, 1, function()
                    AssignAssassinTarget(v, false, true)
                end)
            else
                AssignAssassinTarget(v, false, false)
            end
            -- Reset the target to clear the target overlay from the scoreboard
            v:SetNWString("AssassinTarget", "")
        end
    end

    -- Handle parasite infected death
    if ply:GetNWBool("Infected", false) then
        local parasiteUsers = table.GetKeys(deadParasites)
        for _, key in pairs(parasiteUsers) do
            local parasite = deadParasites[key]
            if parasite.attacker == ply:SteamID64() and IsValid(parasite.player) then
                local deadParasite = parasite.player
                deadParasite:SetNWBool("Infecting", false)
                deadParasite:SetNWString("InfectingTarget", nil)
                deadParasite:SetNWInt("InfectionProgress", 0)
                timer.Remove(deadParasite:Nick() .. "InfectionProgress")
                timer.Remove(deadParasite:Nick() .. "InfectingSpectate")
                if deadParasite:IsParasite() and not deadParasite:Alive() then
                    deadParasite:PrintMessage(HUD_PRINTCENTER, "Your host has died.")
                end
            end
        end

        ply:SetNWBool("Infected", false)
        SendFullStateUpdate()
    end

    -- Experimental: Fire a last shot if ironsighting and not headshot
    if GetConVar("ttt_dyingshot"):GetBool() then
        local wep = ply:GetActiveWeapon()
        if IsValid(wep) and wep.DyingShot and not ply.was_headshot and dmginfo:IsBulletDamage() then
            local fired = wep:DyingShot()
            if fired then
                return
            end
        end

        -- Note that funny things can happen here because we fire a gun while the
        -- player is dead. Specifically, this DoPlayerDeath is run twice for
        -- him. This is ugly, and we have to return the first one to prevent crazy
        -- shit.
    end

    local valid_kill = IsValid(attacker) and attacker:IsPlayer() and attacker ~= ply and GetRoundState() == ROUND_ACTIVE
    -- Don't drop Swapper weapons when they are killed by a player because they are about to be resurrected anyway
    local clear_weapons = not valid_kill or not ply:IsSwapper()
    if clear_weapons then
        -- Don't drop the crowbar when a player dies
        ply:StripWeapon("weapon_zm_improvised")

        -- Drop all weapons
        for _, wep in ipairs(ply:GetWeapons()) do
            if wep ~= nil then
                WEPS.DropNotifiedWeapon(ply, wep, true) -- with ammo in them
                if wep.DampenDrop ~= nil then
                    wep:DampenDrop()
                end
            end
        end

        if IsValid(ply.hat) then
            ply.hat:Drop()
        end
    end

    -- Create ragdoll and hook up marking effects
    local rag = CORPSE.Create(ply, attacker, dmginfo)
    ply.server_ragdoll = rag -- nil if clientside

    CreateDeathEffect(ply, false)

    util.StartBleeding(rag, dmginfo:GetDamage(), 15)

    -- Score only when there is a round active.
    if GetRoundState() == ROUND_ACTIVE then
        SCORE:HandleKill(ply, attacker, dmginfo)

        if IsValid(attacker) and attacker:IsPlayer() then
            attacker:RecordKill(ply)

            if GetConVar("ttt_debug_logkills"):GetBool() then
                DamageLog(Format("KILL:\t %s [%s] killed %s [%s]", attacker:Nick(), attacker:GetRoleString(), ply:Nick(), ply:GetRoleString()))
            end
        elseif GetConVar("ttt_debug_logkills"):GetBool() then
            DamageLog(Format("KILL:\t <something/world> killed %s [%s]", ply:Nick(), ply:GetRoleString()))
        end

        KARMA.Killed(attacker, ply, dmginfo)
    end

    -- Clear out any weapon or equipment we still have
    if clear_weapons then
        ply:StripAll()
    end

    -- Tell the client to send their chat contents
    ply:SendLastWords(dmginfo)

    local killwep = util.WeaponFromDamage(dmginfo)

    -- headshots, knife damage, and weapons tagged as silent all prevent death
    -- sound from occurring
    if not (ply.was_headshot or
            dmginfo:IsDamageType(DMG_SLASH) or
            (IsValid(killwep) and killwep.IsSilent)) then
        PlayDeathSound(ply)
    end

    --- Credits

    CheckCreditAward(ply, attacker)

    -- Check for T killing D or vice versa
    if IsValid(attacker) and attacker:IsPlayer() then
        local reward = 0
        if attacker:IsActiveTraitorTeam() and ply:IsDetective() then
            reward = math.ceil(GetConVar("ttt_credits_detectivekill"):GetInt())
        elseif (attacker:IsActiveDetective() or (attacker:IsActiveDeputy() and attacker:GetNWBool("HasPromotion", false))) and ply:IsTraitorTeam() then
            reward = math.ceil(GetConVar("ttt_det_credits_traitorkill"):GetInt())
        end

        if reward > 0 then
            attacker:AddCredits(reward)

            LANG.Msg(attacker, "credit_kill", { num = reward,
                                                role = LANG.NameParam(ply:GetRoleString()) })
        end
    end

    ply:SetTeam(TEAM_SPEC)
end

local function DoRespawn(ply)
    local body = ply.server_ragdoll or ply:GetRagdollEntity()
    ply:SpawnForRound(true)
    ply:SetHealth(ply:GetMaxHealth())
    if IsValid(body) then
        body:Remove()
    end
end

-- Pre-generate all of this information because we need the owner's weapon info even after they've been destroyed due to (temporary) death
local function GetPlayerWeaponInfo(ply)
    local ply_weapons = {}
    for _, w in ipairs(ply:GetWeapons()) do
        local primary_ammo = nil
        local primary_ammo_type = nil
        if w.Primary and w.Primary.Ammo ~= "none" then
            primary_ammo_type = w.Primary.Ammo
            primary_ammo = ply:GetAmmoCount(primary_ammo_type)
        end

        local secondary_ammo = nil
        local secondary_ammo_type = nil
        if w.Secondary and w.Secondary.Ammo ~= "none" and w.Secondary.Ammo ~= primary_ammo_type then
            secondary_ammo_type = w.Secondary.Ammo
            secondary_ammo = ply:GetAmmoCount(secondary_ammo_type)
        end

        table.insert(ply_weapons, {
            class = WEPS.GetClass(w),
            category = w.Category,
            primary_ammo = primary_ammo,
            primary_ammo_type = primary_ammo_type,
            secondary_ammo = secondary_ammo,
            secondary_ammo_type = secondary_ammo_type
        })
    end
    return ply_weapons
end

local function GivePlayerWeaponAndAmmo(ply, weap_info)
    ply:Give(weap_info.class)
    if weap_info.primary_ammo then
        ply:SetAmmo(weap_info.primary_ammo, weap_info.primary_ammo_type)
    end
    if weap_info.secondary_ammo then
        ply:SetAmmo(weap_info.secondary_ammo, weap_info.secondary_ammo_type)
    end
end

local function StripPlayerWeaponAndAmmo(ply, weap_info)
    ply:StripWeapon(weap_info.class)
    if weap_info.primary_ammo then
        ply:SetAmmo(0, weap_info.primary_ammo_type)
    end
    if weap_info.secondary_ammo then
        ply:SetAmmo(0, weap_info.secondary_ammo_type)
    end
end

function GM:PlayerDeath(victim, infl, attacker)
    local valid_kill = IsValid(attacker) and attacker:IsPlayer() and attacker ~= victim and GetRoundState() == ROUND_ACTIVE
    -- Handle phantom death
    if valid_kill and victim:IsPhantom() and not victim:GetNWBool("IsZombifying", false) then
        attacker:SetNWBool("Haunted", true)

        if GetConVar("ttt_phantom_killer_haunt"):GetBool() then
            victim:SetNWBool("Haunting", true)
            victim:SetNWString("HauntingTarget", attacker:SteamID64())
            victim:SetNWInt("HauntingPower", 0)
            timer.Create(victim:Nick() .. "HauntingPower", 1, 0, function()
                -- Make sure the victim is still in the correct spectate mode
                local spec_mode = victim:GetNWInt("SpecMode", OBS_MODE_ROAMING)
                if spec_mode ~= OBS_MODE_CHASE and spec_mode ~= OBS_MODE_IN_EYE then
                    victim:Spectate(OBS_MODE_CHASE)
                end

                local power = victim:GetNWInt("HauntingPower", 0)
                local power_rate = GetConVar("ttt_phantom_killer_haunt_power_rate"):GetInt()
                local new_power = math.Clamp(power + power_rate, 0, GetConVar("ttt_phantom_killer_haunt_power_max"):GetInt())
                victim:SetNWInt("HauntingPower", new_power)
            end)
        end

        -- Delay this message so the Assassin can see the target update message
        if attacker:IsAssassin() then
            timer.Simple(3, function()
                attacker:PrintMessage(HUD_PRINTCENTER, "You have been haunted.")
            end)
        else
            attacker:PrintMessage(HUD_PRINTCENTER, "You have been haunted.")
        end
        victim:PrintMessage(HUD_PRINTCENTER, "Your attacker has been haunted.")
        if GetConVar("ttt_phantom_announce_death"):GetBool() then
            for _, v in pairs(player.GetAll()) do
                if v ~= attacker and v:IsDetectiveLike() and v:Alive() and not v:IsSpec() then
                    v:PrintMessage(HUD_PRINTCENTER, "The phantom has been killed.")
                end
            end
        end

        local sid = victim:SteamID64()
        -- Keep track of how many times this Phantom has been killed and by who
        if not deadPhantoms[sid] then
            deadPhantoms[sid] = {times = 1, player = victim, attacker = attacker:SteamID64()}
        else
            deadPhantoms[sid] = {times = deadPhantoms[sid].times + 1, player = victim, attacker = attacker:SteamID64()}
        end

        net.Start("TTT_PhantomHaunt")
        net.WriteString(victim:Nick())
        net.WriteString(attacker:Nick())
        net.Broadcast()
    end

    -- Handle revenger lover death
    for _, v in pairs(player.GetAll()) do
        if v:IsRevenger() and v:GetNWString("RevengerLover", "") == victim:SteamID64() then
            if v == attacker then
                v:PrintMessage(HUD_PRINTTALK, "Your love has died by your hand.")
                v:PrintMessage(HUD_PRINTCENTER, "Your love has died by your hand.")
            elseif valid_kill then
                v:PrintMessage(HUD_PRINTTALK, "Your love has died. Track down their killer.")
                v:PrintMessage(HUD_PRINTCENTER, "Your love has died. Track down their killer.")
                v:SetNWString("RevengerKiller", attacker:SteamID64())
                timer.Simple(1, function() -- Slight delay needed for NW variables to be sent
                    net.Start("TTT_RevengerLoverKillerRadar")
                    net.WriteBool(true)
                    net.Send(v)
                end)
            else
                v:PrintMessage(HUD_PRINTTALK, "Your love has died, but you cannot determine the cause.")
                v:PrintMessage(HUD_PRINTCENTER, "Your love has died, but you cannot determine the cause.")
            end
        end
    end

    -- Handle jester death
    if valid_kill and victim:IsJester() then
        JesterKilledNotification(attacker, victim)
        victim:SetNWString("JesterKiller", attacker:Nick())
    end

    -- Handle killer smoke
    if valid_kill and attacker:IsKiller() then
        attacker:SetNWBool("KillerSmoke", false)
        ResetKillerKillCheckTimer()
    end

    -- Handle swapper death
    if valid_kill and victim:IsSwapper() then
        SwapperKilledNotification(attacker, victim)
        attacker:SetNWString("SwappedWith", victim:Nick())
        attacker:PrintMessage(HUD_PRINTCENTER, "You killed the swapper!")

        -- Only bother saving the attacker weapons if we're going to do something with them
        local weapon_mode = GetConVar("ttt_swapper_weapon_mode"):GetInt()
        local attacker_weapons = nil
        if weapon_mode > SWAPPER_WEAPON_NONE then
            attacker_weapons = GetPlayerWeaponInfo(attacker)
        end
        local victim_weapons = GetPlayerWeaponInfo(victim)

        -- Swap prime status
        if attacker:IsZombiePrime() then
            attacker:SetZombiePrime(false)
            victim:SetZombiePrime(true)
        elseif attacker:IsVampirePrime() then
            attacker:SetVampirePrime(false)
            victim:SetVampirePrime(true)
        end

        victim:SetRole(attacker:GetRole())
        attacker:SetRole(ROLE_SWAPPER)
        local health = GetConVar("ttt_swapper_killer_health"):GetInt()
        if health == 0 then
            attacker:Kill()
        else
            attacker:SetHealth(health)
        end
        SendFullStateUpdate()

        timer.Simple(0.01, function()
            local body = victim.server_ragdoll or victim:GetRagdollEntity()
            victim:SpawnForRound(true)
            victim:SetHealth(GetConVar("ttt_swapper_respawn_health"):GetInt())
            if IsValid(body) then
                victim:SetPos(FindRespawnLocation(body:GetPos()) or body:GetPos())
                victim:SetEyeAngles(Angle(0, body:GetAngles().y, 0))
                body:Remove()
            end
            SendFullStateUpdate()

            timer.Simple(0.2, function()
                if weapon_mode == SWAPPER_WEAPON_ALL then
                    -- Strip everything but the sure-thing weapons
                    for _, w in ipairs(attacker_weapons) do
                        if w.class ~= "weapon_ttt_unarmed" and w.class ~= "weapon_zm_carry" then
                            StripPlayerWeaponAndAmmo(attacker, w)
                        end
                    end

                    -- Give the opposite player's weapons back
                    for _, w in ipairs(attacker_weapons) do
                        GivePlayerWeaponAndAmmo(victim, w)
                    end
                    for _, w in ipairs(victim_weapons) do
                        GivePlayerWeaponAndAmmo(attacker, w)
                    end
                else
                    if weapon_mode == SWAPPER_WEAPON_ROLE then
                        -- Remove all role weapons from the attacker and give them to the victim
                        for _, w in ipairs(attacker_weapons) do
                            if w.category == WEAPON_CATEGORY_ROLE then
                                StripPlayerWeaponAndAmmo(attacker, w)
                                -- Give the attacker a regular crowbar to compensate for the killer crowbar that was removed
                                if w.class == "weapon_kil_crowbar" then
                                    attacker:Give("weapon_zm_improvised")
                                end
                                GivePlayerWeaponAndAmmo(victim, w)
                            end
                        end
                    end

                    -- Give the victim all their weapons back
                    for _, w in ipairs(victim_weapons) do
                        GivePlayerWeaponAndAmmo(victim, w)
                    end
                end

                -- Have each player select their crowbar to hide role weapons
                attacker:SelectWeapon("weapon_zm_improvised")
                victim:SelectWeapon("weapon_zm_improvised")
            end)
        end)

        net.Start("TTT_SwapperSwapped")
        net.WriteString(victim:Nick())
        net.WriteString(attacker:Nick())
        net.Broadcast()
    end

    -- Handle beggar death
    if valid_kill and victim:IsBeggar() then
        BeggarKilledNotification(attacker, victim)

        if GetConVar("ttt_beggar_respawn"):GetBool() then
            local delay = GetConVar("ttt_beggar_respawn_delay"):GetInt()
            if delay > 0 then
                victim:PrintMessage(HUD_PRINTCENTER, "You were killed but will respawn in " .. delay .. " seconds.")
            else
                victim:PrintMessage(HUD_PRINTCENTER, "You were killed but are about to respawn.")
                -- Introduce a slight delay to prevent player getting stuck as a spectator
                delay = 0.1
            end
            timer.Create(victim:Nick() .. "BeggarRespawn", delay, 1, function() DoRespawn(victim) end)

            net.Start("TTT_BeggarKilled")
            net.WriteString(victim:Nick())
            net.WriteString(attacker:Nick())
            net.WriteUInt(delay, 8)
            net.Broadcast()
        end
    end

    -- Handle parasite death
    if valid_kill and victim:IsParasite() and not victim:GetNWBool("IsZombifying", false) then
        attacker:SetNWBool("Infected", true)
        victim:SetNWBool("Infecting", true)
        victim:SetNWString("InfectingTarget", attacker:SteamID64())
        victim:SetNWInt("InfectionProgress", 0)
        timer.Create(victim:Nick() .. "InfectionProgress", 1, 0, function()
            -- Make sure the victim is still in the correct spectate mode
            local spec_mode = victim:GetNWInt("SpecMode", OBS_MODE_ROAMING)
            if spec_mode ~= OBS_MODE_CHASE and spec_mode ~= OBS_MODE_IN_EYE then
                victim:Spectate(OBS_MODE_CHASE)
            end

            local progress = victim:GetNWInt("InfectionProgress", 0) + 1
            if progress >= GetConVar("ttt_parasite_infection_time"):GetInt() then -- respawn the parasite
                if victim:IsParasite() and not victim:Alive() then
                    attacker:SetNWBool("Infected", false)
                    victim:SetNWBool("Infecting", false)
                    victim:SetNWString("InfectingTarget", nil)
                    victim:SetNWInt("InfectionProgress", 0)
                    timer.Remove(victim:Nick() .. "InfectionProgress")
                    timer.Remove(victim:Nick() .. "InfectingSpectate")

                    local parasiteBody = victim.server_ragdoll or victim:GetRagdollEntity()

                    local respawnMode = GetConVar("ttt_parasite_respawn_mode"):GetInt()
                    if respawnMode == PARASITE_RESPAWN_HOST then
                        victim:PrintMessage(HUD_PRINTCENTER, "You have taken control of your host.")
                        victim:SpawnForRound(true)
                        victim:SetPos(attacker:GetPos())
                        victim:SetEyeAngles(Angle(0, attacker:GetAngles().y, 0))

                        local weapons = attacker:GetWeapons()
                        local currentWeapon = attacker:GetActiveWeapon() or "weapon_zm_improvised"
                        attacker:StripAll()
                        victim:StripAll()
                        for _, v in ipairs(weapons) do
                            local wep_class = WEPS.GetClass(v)
                            victim:Give(wep_class)
                        end
                        victim:SelectWeapon(currentWeapon)
                    elseif respawnMode == PARASITE_RESPAWN_BODY then
                        if IsValid(parasiteBody) then
                            victim:PrintMessage(HUD_PRINTCENTER, "You have drained your host of energy and regenerated your old body.")
                            victim:SpawnForRound(true)
                            victim:SetPos(FindRespawnLocation(parasiteBody:GetPos()) or parasiteBody:GetPos())
                            victim:SetEyeAngles(Angle(0, parasiteBody:GetAngles().y, 0))
                        else
                            victim:PrintMessage(HUD_PRINTCENTER, "You have drained your host of energy and created a new body.")
                            -- Introduce a slight delay to prevent player getting stuck as a spectator
                            timer.Create(victim:Nick() .. "ParasiteRespawn", 0.1, 1, function()
                                DoRespawn(victim)
                                local health = GetConVar("ttt_parasite_respawn_health"):GetInt()
                                victim:SetHealth(health)
                            end)
                        end
                    elseif respawnMode == PARASITE_RESPAWN_RANDOM then
                        victim:PrintMessage(HUD_PRINTCENTER, "You have drained your host of energy and created a new body.")
                        -- Introduce a slight delay to prevent player getting stuck as a spectator
                        timer.Create(victim:Nick() .. "ParasiteRespawn", 0.1, 1, function()
                            DoRespawn(victim)
                            local health = GetConVar("ttt_parasite_respawn_health"):GetInt()
                            victim:SetHealth(health)
                        end)
                    end

                    local health = GetConVar("ttt_parasite_respawn_health"):GetInt()
                    victim:SetHealth(health)
                    if IsValid(parasiteBody) then parasiteBody:Remove() end
                    attacker:Kill()
                end
            else
                victim:SetNWInt("InfectionProgress", progress)
            end
        end)

        -- Delay this message so the Assassin can see the target update message
        if GetConVar("ttt_parasite_announce_infection"):GetBool() then
            if attacker:IsAssassin() then
                timer.Simple(3, function()
                    attacker:PrintMessage(HUD_PRINTCENTER, "You have been infected with a parasite.")
                end)
            else
                attacker:PrintMessage(HUD_PRINTCENTER, "You have been infected with a parasite.")
            end
        end
        victim:PrintMessage(HUD_PRINTCENTER, "Your attacker has been infected.")

        local sid = victim:SteamID64()
        -- Keep track of who killed this parasite
        deadParasites[sid] = {player = victim, attacker = attacker:SteamID64()}

        net.Start("TTT_ParasiteInfect")
        net.WriteString(victim:Nick())
        net.WriteString(attacker:Nick())
        net.Broadcast()
    end

    -- Handle detective death
    if victim:IsDetective() and GetRoundState() == ROUND_ACTIVE then
        local detectiveAlive = false
        for _, ply in pairs(player.GetAll()) do
            if not ply:IsSpec() and ply:Alive() and ply:IsDetective() and ply ~= victim then
                detectiveAlive = true
                break
            end
        end
        if not detectiveAlive then
            for _, ply in pairs(player.GetAll()) do
                if (ply:IsDeputy() or ply:IsImpersonator()) and not ply:GetNWBool("HasPromotion", false) then
                    ply:SetNWBool("HasPromotion", true)
                    ply:PrintMessage(HUD_PRINTTALK, "You have been promoted to Detective!")
                    ply:PrintMessage(HUD_PRINTCENTER, "You have been promoted to Detective!")

                    -- If the player is an Impersonator, tell all their team members when they get promoted
                    if ply:IsImpersonator() then
                        for _, v in pairs(player.GetAll()) do
                            if v ~= ply and v:IsTraitorTeam() and v:Alive() and not v:IsSpec() then
                                v:PrintMessage(HUD_PRINTTALK, "The Impersonator has been promoted to Detective!")
                                v:PrintMessage(HUD_PRINTCENTER, "The Impersonator has been promoted to Detective!")
                            end
                        end
                    end

                    net.Start("TTT_Promotion")
                    net.WriteString(ply:Nick())
                    net.Broadcast()

                    -- The player has been promoted so we need to update their shop
                    net.Start("TTT_ResetBuyableWeaponsCache")
                    net.Send(ply)
                end
            end
        end
    end

    -- Check veteran status
    local innocents_alive = 0
    local veterans = {}
    for _, v in pairs(player.GetAll()) do
        if v:IsActiveInnocentTeam() then innocents_alive = innocents_alive + 1 end
        if v:IsActiveVeteran() then table.insert(veterans, v) end
    end
    if #veterans > 0 and innocents_alive == 1 then
        for _, v in pairs(veterans) do
            if not v:GetNWBool("VeteranActive", false) then
                v:SetNWBool("VeteranActive", true)
                v:PrintMessage(HUD_PRINTTALK, "You are the last innocent alive!")
                v:PrintMessage(HUD_PRINTCENTER, "You are the last innocent alive!")
                if GetConVar("ttt_veteran_full_heal"):GetBool() then
                    v:SetHealth(math.min(v:GetMaxHealth(), 100))
                    v:PrintMessage(HUD_PRINTTALK, "You have been fully healed!")
                end
            end
        end
    end

    -- stop bleeding
    util.StopBleeding(victim)

    -- tell no one
    self:PlayerSilentDeath(victim)

    victim:Freeze(false)

    -- Haunt/infect the (non-Swapper) attacker if that functionality is enabled
    if valid_kill and victim:IsPhantom() and not attacker:IsSwapper() and attacker:GetNWBool("Haunted", true) and GetConVar("ttt_phantom_killer_haunt"):GetBool() then
        timer.Create(victim:Nick() .. "HauntingSpectate", 1, 1, function()
            victim:Spectate(OBS_MODE_CHASE)
            victim:SpectateEntity(attacker)
        end)
    elseif valid_kill and victim:IsParasite() and not attacker:IsSwapper() and attacker:GetNWBool("Infected", true) then
        timer.Create(victim:Nick() .. "InfectingSpectate", 1, 1, function()
            victim:Spectate(OBS_MODE_CHASE)
            victim:SpectateEntity(attacker)
        end)
    else
        victim:SetRagdollSpec(true)
        victim:Spectate(OBS_MODE_IN_EYE)

        local rag_ent = victim.server_ragdoll or victim:GetRagdollEntity()
        victim:SpectateEntity(rag_ent)
    end

    victim:Flashlight(false)

    victim:Extinguish()

    net.Start("TTT_PlayerDied")
    net.Send(victim)

    if HasteMode() and GetRoundState() == ROUND_ACTIVE then
        IncRoundEnd(GetConVar("ttt_haste_minutes_per_death"):GetFloat() * 60)
    end
end

-- kill hl2 beep
function GM:PlayerDeathSound() return true end

function GM:SpectatorThink(ply)
    -- when spectating a ragdoll after death
    if ply:GetRagdollSpec() then
        local to_switch, to_chase, to_roam = 2, 5, 8
        local elapsed = CurTime() - ply.spec_ragdoll_start
        local clicked = ply:KeyPressed(IN_ATTACK)

        -- After first click, go into chase cam, then after another click, to into
        -- roam. If no clicks made, go into chase after X secs, and roam after Y.
        -- Don't switch for a second in case the player was shooting when he died,
        -- this would make him accidentally switch out of ragdoll cam.

        local m = ply:GetObserverMode()
        if (m == OBS_MODE_CHASE and clicked) or elapsed > to_roam then
            -- free roam mode
            ply:SetRagdollSpec(false)
            ply:Spectate(OBS_MODE_ROAMING)

            -- move to spectator spawn if mapper defined any
            local spec_spawns = ents.FindByClass("ttt_spectator_spawn")
            if spec_spawns and #spec_spawns > 0 then
                local spawn = table.Random(spec_spawns)
                ply:SetPos(spawn:GetPos())
                ply:SetEyeAngles(spawn:GetAngles())
            end
        elseif (m == OBS_MODE_IN_EYE and clicked and elapsed > to_switch) or elapsed > to_chase then
            -- start following ragdoll
            ply:Spectate(OBS_MODE_CHASE)
        end

        if not IsValid(ply.server_ragdoll) then ply:SetRagdollSpec(false) end

        -- when roaming and messing with ladders
    elseif ply:GetMoveType() < MOVETYPE_NOCLIP and ply:GetMoveType() > 0 or ply:GetMoveType() == MOVETYPE_LADDER then
        ply:Spectate(OBS_MODE_ROAMING)
    end

    -- when speccing a player
    if ply:GetObserverMode() ~= OBS_MODE_ROAMING and (not ply.propspec) and (not ply:GetRagdollSpec()) then
        local tgt = ply:GetObserverTarget()
        if IsValid(tgt) and tgt:IsPlayer() then
            if (not tgt:IsTerror()) or (not tgt:Alive()) then
                -- stop speccing as soon as target dies
                ply:Spectate(OBS_MODE_ROAMING)
                ply:SpectateEntity(nil)
            elseif GetRoundState() == ROUND_ACTIVE then
                -- Sync position to target. Uglier than parenting, but unlike
                -- parenting this is less sensitive to breakage: if we are
                -- no longer spectating, we will never sync to their position.
                ply:SetPos(tgt:GetPos())
            end
        end
    end
end

GM.PlayerDeathThink = GM.SpectatorThink

function GM:PlayerTraceAttack(ply, dmginfo, dir, trace)
    if IsValid(ply.hat) and trace.HitGroup == HITGROUP_HEAD then
        ply.hat:Drop(dir)
    end

    ply.hit_trace = trace

    return false
end

function GM:ScalePlayerDamage(ply, hitgroup, dmginfo)
    -- Body armor nets you a damage reduction.
    if dmginfo:IsBulletDamage() and ply:HasEquipmentItem(EQUIP_ARMOR) then
        dmginfo:ScaleDamage(0.7)
    end

    local att = dmginfo:GetAttacker()
    if IsValid(att) and att:IsPlayer() then
        -- Only apply damage scaling after the round starts
        if GetRoundState() >= ROUND_ACTIVE then
            -- Jesters can't deal damage
            if att:IsJesterTeam() and not att:GetNWBool("KillerClownActive", false) then
                dmginfo:ScaleDamage(0)
            end

            -- Clowns deal extra damage when they are active
            if att:IsClown() and att:GetNWBool("KillerClownActive", false) then
                local bonus = GetConVar("ttt_clown_damage_bonus"):GetFloat()
                dmginfo:ScaleDamage(1 + bonus)
            end

            -- Deputies deal less damage before they are promoted
            if att:IsDeputy() and not att:GetNWBool("HasPromotion", false) then
                local penalty = GetConVar("ttt_deputy_damage_penalty"):GetFloat()
                dmginfo:ScaleDamage(1 - penalty)
            end

            -- Impersonators deal less damage before they are promoted
            if att:IsImpersonator() and not att:GetNWBool("HasPromotion", false) then
                local penalty = GetConVar("ttt_impersonator_damage_penalty"):GetFloat()
                dmginfo:ScaleDamage(1 - penalty)
            end

            -- Revengers deal extra damage to their lovers killer
            if att:IsRevenger() and ply:SteamID64() == att:GetNWString("RevengerKiller", "") then
                local bonus = GetConVar("ttt_revenger_damage_bonus"):GetFloat()
                dmginfo:ScaleDamage(1 + bonus)
            end

            -- Veterans deal extra damage if they are the last innocent alive
            if att:IsVeteran() and att:GetNWBool("VeteranActive", false) then
                local bonus = GetConVar("ttt_veteran_damage_bonus"):GetFloat()
                dmginfo:ScaleDamage(1 + bonus)
            end

            -- Assassins deal extra damage to their target, less damage to other players, and less damage if they fail their contract
            -- Don't apply the scaling to the Jester team to specifically allow doing 100% damage to the active killer clown
            if att:IsAssassin() and ply ~= att and not ply:IsJesterTeam() then
                local scale = 0
                if att:GetNWBool("AssassinFailed", false) then
                    scale = -GetConVar("ttt_assassin_failed_damage_penalty"):GetFloat()
                elseif ply:Nick() == att:GetNWString("AssassinTarget", "") then
                    scale = GetConVar("ttt_assassin_target_damage_bonus"):GetFloat()
                else
                    scale = -GetConVar("ttt_assassin_wrong_damage_penalty"):GetFloat()
                end
                dmginfo:ScaleDamage(1 + scale)
            end

            -- Killers do less damage to encourage using the knife
            if dmginfo:IsBulletDamage() and att:IsKiller() then
                local penalty = GetConVar("ttt_killer_damage_penalty"):GetFloat()
                dmginfo:ScaleDamage(1 - penalty)
            end

            -- Killers take less bullet damage
            if dmginfo:IsBulletDamage() and ply:IsKiller() then
                local reduction = GetConVar("ttt_killer_damage_reduction"):GetFloat()
                dmginfo:ScaleDamage(1 - reduction)
            end

            -- Monsters take less bullet damage
            if dmginfo:IsBulletDamage() and ply:IsZombie() then
                local reduction = GetConVar("ttt_zombie_damage_reduction"):GetFloat()
                dmginfo:ScaleDamage(1 - reduction)
            end
            if dmginfo:IsBulletDamage() and ply:IsVampire() then
                local reduction = GetConVar("ttt_vampire_damage_reduction"):GetFloat()
                dmginfo:ScaleDamage(1 - reduction)
            end

            -- Zombies do less damage when using non-claw weapons
            if att:IsZombie() and att:GetActiveWeapon():GetClass() ~= "weapon_zom_claws" then
                local penalty = GetConVar("ttt_zombie_damage_penalty"):GetFloat()
                dmginfo:ScaleDamage(1 - penalty)
            end
        -- Players cant deal damage to eachother before the round starts
        else
            dmginfo:ScaleDamage(0)
        end
    end

    ply.was_headshot = false
    -- actual damage scaling
    if hitgroup == HITGROUP_HEAD then
        -- headshot if it was dealt by a bullet
        ply.was_headshot = dmginfo:IsBulletDamage()

        local wep = util.WeaponFromDamage(dmginfo)

        if IsValid(wep) and not GetConVar("ttt_disable_headshots"):GetBool() then
            local s = wep:GetHeadshotMultiplier(ply, dmginfo) or 2
            dmginfo:ScaleDamage(s)
        end
    elseif (hitgroup == HITGROUP_LEFTARM or
            hitgroup == HITGROUP_RIGHTARM or
            hitgroup == HITGROUP_LEFTLEG or
            hitgroup == HITGROUP_RIGHTLEG or
            hitgroup == HITGROUP_GEAR) then

        dmginfo:ScaleDamage(0.55)
    end

    -- Keep ignite-burn damage etc on old levels
    if (dmginfo:IsDamageType(DMG_DIRECT) or
            dmginfo:IsExplosionDamage() or
            dmginfo:IsDamageType(DMG_FALL) or
            dmginfo:IsDamageType(DMG_PHYSGUN)) then
        dmginfo:ScaleDamage(2)
    end
end

-- The GetFallDamage hook does not get called until around 600 speed, which is a
-- rather high drop already. Hence we do our own fall damage handling in
-- OnPlayerHitGround.
function GM:GetFallDamage(ply, speed)
    return 0
end

local fallsounds = {
    Sound("player/damage1.wav"),
    Sound("player/damage2.wav"),
    Sound("player/damage3.wav")
};

function GM:OnPlayerHitGround(ply, in_water, on_floater, speed)
    if ((ply:IsJesterTeam() and not ply:GetNWBool("KillerClownActive", false)) or ply:IsZombie()) and GetRoundState() >= ROUND_ACTIVE then
        -- Jester team and Zombie don't take fall damage
    else
        if in_water or speed < 450 or not IsValid(ply) then return end

        -- Everything over a threshold hurts you, rising exponentially with speed
        local damage = math.pow(0.05 * (speed - 420), 1.75)

        -- I don't know exactly when on_floater is true, but it's probably when
        -- landing on something that is in water.
        if on_floater then damage = damage / 2 end

        -- if we fell on a dude, that hurts (him)
        local ground = ply:GetGroundEntity()
        if IsValid(ground) and ground:IsPlayer() then
            if math.floor(damage) > 0 then
                local att = ply

                -- if the faller was pushed, that person should get attrib
                local push = ply.was_pushed
                if push then
                    if math.max(push.t or 0, push.hurt or 0) > CurTime() - 4 then
                        att = push.att
                    end
                end

                local dmg = DamageInfo()

                if att == ply then
                    -- hijack physgun damage as a marker of this type of kill
                    dmg:SetDamageType(DMG_CRUSH + DMG_PHYSGUN)
                else
                    -- if attributing to pusher, show more generic crush msg for now
                    dmg:SetDamageType(DMG_CRUSH)
                end

                dmg:SetAttacker(att)
                dmg:SetInflictor(att)
                dmg:SetDamageForce(Vector(0, 0, -1))
                dmg:SetDamage(damage)

                ground:TakeDamageInfo(dmg)
            end

            -- our own falling damage is cushioned
            damage = damage / 3
        end

        if math.floor(damage) > 0 then
            local dmg = DamageInfo()
            dmg:SetDamageType(DMG_FALL)
            dmg:SetAttacker(game.GetWorld())
            dmg:SetInflictor(game.GetWorld())
            dmg:SetDamageForce(Vector(0, 0, 1))
            dmg:SetDamage(damage)

            ply:TakeDamageInfo(dmg)

            -- play CS:S fall sound if we got somewhat significant damage
            if damage > 5 then
                sound.Play(table.Random(fallsounds), ply:GetShootPos(), 55 + math.Clamp(damage, 0, 50), 100)
            end
        end
    end
end

local ttt_postdm = CreateConVar("ttt_postround_dm", "0", FCVAR_NOTIFY)

function GM:AllowPVP()
    local rs = GetRoundState()
    return not (rs == ROUND_PREP or (rs == ROUND_POST and not ttt_postdm:GetBool()))
end

-- No damage during prep, etc
function GM:EntityTakeDamage(ent, dmginfo)
    if not IsValid(ent) then return end

    local att = dmginfo:GetAttacker()
    if GetRoundState() >= ROUND_ACTIVE and ent:IsPlayer() then
        -- Jesters don't take environmental damage
        if ent:IsJesterTeam() and not ent:GetNWBool("KillerClownActive", false) then
            -- Damage type DMG_GENERIC is "0" which doesn't seem to work with IsDamageType
            if dmginfo:IsExplosionDamage() or dmginfo:IsDamageType(DMG_BURN) or dmginfo:IsDamageType(DMG_CRUSH) or dmginfo:IsFallDamage() or dmginfo:IsDamageType(DMG_DROWN) or dmginfo:GetDamageType() == 0 or dmginfo:IsDamageType(DMG_DISSOLVE) then
                dmginfo:ScaleDamage(0)
                dmginfo:SetDamage(0)
            end
        end

        -- Quacks are immune to explosions
        if ent:IsQuack() then
            if dmginfo:IsExplosionDamage() then
                dmginfo:ScaleDamage(0)
                dmginfo:SetDamage(0)
            end
        end

        -- No zombie team killing
        -- This can be funny, but it can also be used by frustrated players who didn't appreciate being zombified
        if ent:IsPlayer() and ent:IsZombie() and att:IsPlayer() and att:IsZombieAlly() then
            dmginfo:ScaleDamage(0)
            dmginfo:SetDamage(0)
        end

        -- Prevent damage from non-bullet weapons
        if att:IsPlayer() and att:IsJesterTeam() and not att:GetNWBool("KillerClownActive", false) then
            dmginfo:ScaleDamage(0)
            dmginfo:SetDamage(0)
        end
    end

    if not GAMEMODE:AllowPVP() then
        -- if player vs player damage, or if damage versus a prop, then zero
        if ent:IsExplosive() or (ent:IsPlayer() and IsValid(att) and att:IsPlayer()) then
            dmginfo:ScaleDamage(0)
            dmginfo:SetDamage(0)
        end
    elseif ent:IsPlayer() then
        GAMEMODE:PlayerTakeDamage(ent, dmginfo:GetInflictor(), att, dmginfo:GetDamage(), dmginfo)
    elseif ent:IsExplosive() then
        -- When a barrel hits a player, that player damages the barrel because
        -- Source physics. This gives stupid results like a player who gets hit
        -- with a barrel being blamed for killing himself or even his attacker.
        if IsValid(att) and att:IsPlayer() and
                dmginfo:IsDamageType(DMG_CRUSH) and
                IsValid(ent:GetPhysicsAttacker()) then

            dmginfo:SetAttacker(ent:GetPhysicsAttacker())
            dmginfo:ScaleDamage(0)
            dmginfo:SetDamage(0)
        end
    elseif ent.is_pinned and ent.OnPinnedDamage then
        ent:OnPinnedDamage(dmginfo)
        dmginfo:SetDamage(0)
    end
end

function GM:PlayerTakeDamage(ent, infl, att, amount, dmginfo)
    -- Change damage attribution if necessary
    if infl or att then
        local hurter, owner, owner_time

        -- fall back to the attacker if there is no inflictor
        if IsValid(infl) then
            hurter = infl
        elseif IsValid(att) then
            hurter = att
        end

        -- have a damage owner?
        if hurter and IsValid(hurter:GetDamageOwner()) then
            owner, owner_time = hurter:GetDamageOwner()

            -- barrel bangs can hurt us even if we threw them, but that's our fault
        elseif hurter and ent == hurter:GetPhysicsAttacker() and dmginfo:IsDamageType(DMG_BLAST) then
            owner = ent
        elseif hurter and hurter:IsVehicle() and IsValid(hurter:GetDriver()) then
            owner = hurter:GetDriver()
        end


        -- if we were hurt by a trap OR by a non-ply ent, and we were pushed
        -- recently, then our pusher is the attacker
        if owner_time or (not IsValid(att)) or (not att:IsPlayer()) then
            local push = ent.was_pushed

            if push and IsValid(push.att) and push.t then
                -- push must be within the last 5 seconds, and must be done
                -- after the trap was enabled (if any)
                owner_time = owner_time or 0
                local t = math.max(push.t or 0, push.hurt or 0)
                if t > owner_time and t > CurTime() - 4 then
                    owner = push.att

                    -- pushed by a trap?
                    if IsValid(push.infl) then
                        dmginfo:SetInflictor(push.infl)
                    end

                    -- for slow-hurting traps we do leech-like damage timing
                    push.hurt = CurTime()
                end
            end
        end

        -- if we are being hurt by a physics object, we will take damage from
        -- the world entity as well, which screws with damage attribution so we
        -- need to detect and work around that
        if IsValid(owner) and dmginfo:IsDamageType(DMG_CRUSH) then
            -- we should be able to use the push system for this, as the cases are
            -- similar: event causes future damage but should still be attributed
            -- physics traps can also push you to your death, for example
            local push = ent.was_pushed or {}

            -- if we already blamed this on a pusher, no need to do more
            -- else we override whatever was in was_pushed with info pointing
            -- at our damage owner
            if push.att ~= owner then
                owner_time = owner_time or CurTime()

                push.att = owner
                push.t = owner_time
                push.hurt = CurTime()

                -- store the current inflictor so that we can attribute it as the
                -- trap used by the player in the event
                if IsValid(infl) then
                    push.infl = infl
                end

                -- make sure this is set, for if we created a new table
                ent.was_pushed = push
            end
        end

        -- make the owner of the damage the attacker
        att = IsValid(owner) and owner or att
        dmginfo:SetAttacker(att)
    end

    -- scale phys damage caused by props
    if dmginfo:IsDamageType(DMG_CRUSH) and IsValid(att) then

        -- player falling on player, or player hurt by prop?
        if not dmginfo:IsDamageType(DMG_PHYSGUN) then

            -- this is prop-based physics damage
            dmginfo:ScaleDamage(0.25)

            -- if the prop is held, no damage
            if IsValid(infl) and IsValid(infl:GetOwner()) and infl:GetOwner():IsPlayer() then
                dmginfo:ScaleDamage(0)
                dmginfo:SetDamage(0)
            end
        end
    end

    -- Get the active entity fire info
    local ignite_info = ent.ignite_info

    -- Check if we have extended info
    if ent.ignite_info_ext then
        -- If we have extended info but not regular info
        if not ignite_info then
            -- Check that the extended info is still valid and use it, if so
            if ent.ignite_info_ext.end_time > CurTime() then
                ignite_info = ent.ignite_info_ext
            -- Otherwise clear it out
            else
                ent.ignite_info_ext = nil
            end
        else
            -- If we have both regular and extended info, save the attacker and inflictor to the extended info for later
            if not ent.ignite_info_ext.att then
                ent.ignite_info_ext.att = ent.ignite_info.att
            end
            if not ent.ignite_info_ext.infl then
                ent.ignite_info_ext.infl = ent.ignite_info.infl
            end
        end
    end

    -- Handle fire attacker
    if ignite_info and dmginfo:IsDamageType(DMG_DIRECT) then
        local datt = dmginfo:GetAttacker()
        if (not IsValid(datt) or not datt:IsPlayer()) and IsValid(ignite_info.att) and IsValid(ignite_info.infl) then
            dmginfo:SetAttacker(ignite_info.att)
            dmginfo:SetInflictor(ignite_info.infl)

            -- Set burning damage from jester team to zero, regardless of source
            if ignite_info.att:IsJesterTeam() and not ignite_info.att:GetNWBool("KillerClownActive", false) then
                dmginfo:ScaleDamage(0)
                dmginfo:SetDamage(0)
            end
        end
    end

    -- try to work out if this was push-induced leech-water damage (common on
    -- some popular maps like dm_island17)
    if ent.was_pushed and ent == att and dmginfo:GetDamageType() == DMG_GENERIC and util.BitSet(util.PointContents(dmginfo:GetDamagePosition()), CONTENTS_WATER) then
        local t = math.max(ent.was_pushed.t or 0, ent.was_pushed.hurt or 0)
        if t > CurTime() - 3 then
            dmginfo:SetAttacker(ent.was_pushed.att)
            ent.was_pushed.hurt = CurTime()
        end
    end

    -- start painting blood decals
    util.StartBleeding(ent, dmginfo:GetDamage(), 5)

    -- general actions for pvp damage
    if ent ~= att and IsValid(att) and att:IsPlayer() and GetRoundState() == ROUND_ACTIVE and math.floor(dmginfo:GetDamage()) > 0 then

        -- scale everything to karma damage factor except the knife, because it
        -- assumes a kill
        if not dmginfo:IsDamageType(DMG_SLASH) then
            dmginfo:ScaleDamage(att:GetDamageFactor())
        end

        -- process the effects of the damage on karma
        KARMA.Hurt(att, ent, dmginfo)

        if GetConVar("ttt_debug_logkills"):GetBool() then
            DamageLog(Format("DMG: \t %s [%s] damaged %s [%s] for %d dmg", att:Nick(), att:GetRoleString(), ent:Nick(), ent:GetRoleString(), math.Round(dmginfo:GetDamage())))
        end
    end

end

function GM:OnNPCKilled() end

local function HandleRoleForcedWeapons(ply)
    if not IsValid(ply) or ply:IsSpec() or GetRoundState() ~= ROUND_ACTIVE then return end

    if ply:IsKiller() then
        -- Ensure the Killer has their knife, if its enabled
        if not ply:HasWeapon("weapon_kil_knife") and GetConVar("ttt_killer_knife_enabled"):GetBool() then
            ply:Give("weapon_kil_knife")
        end
        if ply:HasWeapon("weapon_zm_improvised") and not ply:HasWeapon("weapon_kil_crowbar") and GetConVar("ttt_killer_crowbar_enabled"):GetBool() then
            ply:StripWeapon("weapon_zm_improvised")
            ply:Give("weapon_kil_crowbar")
            ply:SelectWeapon("weapon_kil_crowbar")
        end
    elseif ply:IsZombie() then
        if ply.GetActiveWeapon and IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon():GetClass() == "weapon_zom_claws" then
            ply:SetColor(Color(70, 100, 25, 255))
            ply:SetRenderMode(RENDERMODE_NORMAL)
        elseif ply:GetRenderMode() ~= RENDERMODE_TRANSALPHA then
            ply:SetColor(Color(255, 255, 255, 255))
            ply:SetRenderMode(RENDERMODE_TRANSALPHA)
        end

        -- Strip all non-claw weapons for non-prime zombies if that feature is enabled
        -- Strip individual weapons instead of all because otherwise the player will have their claws added and removed constantly
        if GetConVar("ttt_zombie_prime_only_weapons"):GetBool() and not ply:GetZombiePrime() then
            local weapons = ply:GetWeapons()
            for _, v in pairs(weapons) do
                local weapclass = WEPS.GetClass(v)
                if weapclass ~= "weapon_zom_claws" then
                    ply:StripWeapon(weapclass)
                end
            end
        end

        -- If this zombie doesn't have claws, give them claws
        if not ply:HasWeapon("weapon_zom_claws") then
            ply:Give("weapon_zom_claws")
        end
    elseif ply:IsVampire() then
        if not ply:HasWeapon("weapon_vam_fangs") then
            ply:Give("weapon_vam_fangs")
        end
    elseif ply:GetRenderMode() ~= RENDERMODE_TRANSALPHA then
        ply:SetColor(Color(255, 255, 255, 255))
        ply:SetRenderMode(RENDERMODE_TRANSALPHA)
    end
end

-- Drowning and such
function GM:Tick()
    -- three cheers for micro-optimizations
    local plys = player.GetAll()
    local tm = nil
    local ply = nil
    for i = 1, #plys do
        ply = plys[i]
        tm = ply:Team()
        if tm == TEAM_TERROR and ply:Alive() then
            -- Drowning
            if ply:WaterLevel() == 3 then
                if ply:IsOnFire() then
                    ply:Extinguish()
                end

                if ply.drowning then
                    if ply.drowning < CurTime() then
                        local dmginfo = DamageInfo()
                        dmginfo:SetDamage(15)
                        dmginfo:SetDamageType(DMG_DROWN)
                        dmginfo:SetAttacker(game.GetWorld())
                        dmginfo:SetInflictor(game.GetWorld())
                        dmginfo:SetDamageForce(Vector(0, 0, 1))

                        ply:TakeDamageInfo(dmginfo)

                        -- have started drowning properly
                        ply.drowning = CurTime() + 1
                    end
                else
                    -- will start drowning soon
                    ply.drowning = CurTime() + 8
                end
            else
                ply.drowning = nil
            end

            -- Run DNA Scanner think also when it is not deployed
            if IsValid(ply.scanner_weapon) and ply:GetActiveWeapon() ~= ply.scanner_weapon then
                ply.scanner_weapon:Think()
            end

            HandleRoleForcedWeapons(ply)
        elseif tm == TEAM_SPEC then
            if ply.propspec then
                PROPSPEC.Recharge(ply)

                if IsValid(ply:GetObserverTarget()) then
                    ply:SetPos(ply:GetObserverTarget():GetPos())
                end
            end

            -- if spectators are alive, ie. they picked spectator mode, then
            -- DeathThink doesn't run, so we have to SpecThink here
            if ply:Alive() then
                self:SpectatorThink(ply)
            end
        end
    end
end

function GM:ShowHelp(ply)
    if IsValid(ply) then
        ply:ConCommand("ttt_helpscreen")
    end
end

function GM:PlayerRequestTeam(ply, teamid)
end

-- Implementing stuff that should already be in gmod, chpt. 389
function GM:PlayerEnteredVehicle(ply, vehicle, role)
    if IsValid(vehicle) then
        vehicle:SetNWEntity("ttt_driver", ply)
    end
end

function GM:PlayerLeaveVehicle(ply, vehicle)
    if IsValid(vehicle) then
        -- setting nil will not do anything, so bogusify
        vehicle:SetNWEntity("ttt_driver", vehicle)
    end
end

function GM:AllowPlayerPickup(ply, obj)
    return false
end

function GM:PlayerShouldTaunt(ply, actid)
    -- Disable taunts, we don't have a system for them (camera freezing etc).
    -- Mods/plugins that add such a system should override this.
    return false
end

local function GetKillerPlayer()
    for _, v in pairs(player.GetAll()) do
        if v:Team() == TEAM_TERROR and v:IsTerror() and v:IsKiller() then
            return v
        end
    end
    return nil
end

local function HasKillerPlayer()
    return GetKillerPlayer() ~= nil
end

local killerSmokeTime = 0
function ResetKillerKillCheckTimer()
    killerSmokeTime = 0
    timer.Start("KillerKillCheckTimer")
end

local function HandleKillerSmokeTick()
    timer.Stop("KillerKillCheckTimer")
    if GetRoundState() ~= ROUND_ACTIVE then
        ResetKillerKillCheckTimer()
    end

    timer.Create("KillerTick", 0.1, 0, function()
        if GetRoundState() == ROUND_ACTIVE then
            if killerSmokeTime >= GetConVar("ttt_killer_smoke_timer"):GetInt() then
                for _, v in pairs(player.GetAll()) do
                    if not IsValid(v) then return end
                    if v:IsKiller() and v:Alive() and not v:GetNWBool("KillerSmoke", false) then
                        v:SetNWBool("KillerSmoke", true)
                        v:PrintMessage(HUD_PRINTCENTER, "Your evil is showing")
                        v:PrintMessage(HUD_PRINTTALK, "Your evil is showing")
                    elseif (v:IsKiller() and not v:Alive()) or not HasKillerPlayer() then
                        timer.Remove("KillerKillCheckTimer")
                    end
                end
            end
        else
            killerSmokeTime = 0
        end
    end)
end

timer.Create("KillerKillCheckTimer", 1, 0, function()
    local killer = GetKillerPlayer();
    if GetRoundState() == ROUND_ACTIVE and GetConVar("ttt_killer_smoke_enabled"):GetBool() and killer ~= nil then
        killerSmokeTime = killerSmokeTime + 1

        -- Warn the killer that they need to kill at 1/2 time remaining, 1/4 time remaining, 10 seconds remaining, and 5 seconds remaining
        local smoke_timer = GetConVar("ttt_killer_smoke_timer"):GetInt()
        local timer_remaining = smoke_timer - killerSmokeTime
        local timer_fraction = (timer_remaining / smoke_timer)
        -- Don't do the 1/2 and 1/4 checks if they represent < 10 seconds
        if (timer_fraction == 0.5 and timer_remaining > 10) or
            (timer_fraction == 0.25 and timer_remaining > 10) or
            timer_remaining == 10 or timer_remaining == 5 then
            killer:PrintMessage(HUD_PRINTTALK, "Your evil grows impatient. Kill someone in the next " .. timer_remaining .. " seconds or you will be revealed!")
        end

        if killerSmokeTime >= smoke_timer then
            HandleKillerSmokeTick()
        else
            timer.Remove("KillerTick")
        end
    else
        killerSmokeTime = 0
    end
end)

local function PlayerAutoComplete(cmd, args)
    -- Split all the arguments out so we can keep track of them
    local arg_split = {}
    for _, v in ipairs(string.Explode("\"", args, false)) do
        local trimmed = string.Trim(v)
        if string.len(trimmed) > 0 then
            table.insert(arg_split, trimmed)
        end
    end

    -- Clean up the current and all previous arguments
    local name = ""
    local other_args = ""
    if not table.IsEmpty(arg_split) then
        name = string.Trim(string.lower(arg_split[#arg_split]))
        other_args = table.concat(arg_split, " ", 1, #arg_split - 1)
        if string.len(other_args) > 0 then
            other_args = " " .. other_args
        end
    end

    -- Find player options that match the given value (or all if there is no given value)
    local options = {}
    for _, v in ipairs(player.GetAll()) do
        if string.len(name) == 0 or string.find(string.lower(v:Nick()), name) then
            table.insert(options, cmd .. other_args .. " \"" .. v:Nick() .. "\"")
        end
    end
    return options
end

local function KillFromPlayer(victim, killer, remove_body)
    if not IsValid(victim) or not victim:Alive() then return end
    if not IsValid(killer) or not killer:Alive() then return end

    print("Killing " .. victim:Nick() .. " by " .. killer:Nick())

    -- Kill the player with a "bullet"
    local dmginfo = DamageInfo()
    dmginfo:SetDamage(1000)
    dmginfo:SetAttacker(killer)
    dmginfo:SetInflictor(killer)
    dmginfo:SetDamageType(DMG_BULLET)
    victim:TakeDamageInfo(dmginfo)

    if remove_body then
        timer.Simple(0.25, function()
            local body = victim.server_ragdoll or victim:GetRagdollEntity()
            if IsValid(body) then
                print("and removing body")
                body:Remove()
            end
        end)
    end
end

concommand.Add("ttt_kill_from_random", function(ply, cmd, args)
    if not IsValid(ply) or not ply:Alive() then return end

    local killer = nil
    for _, v in RandomPairs(player.GetAll()) do
        if IsValid(v) and v:Alive() and not v:IsSpec() and v ~= ply and not (v:IsJesterTeam() and not v:GetNWBool("KillerClownActive", false)) then
            killer = v
            break
        end
    end

    local remove_body = #args > 0 and tobool(args[1])
    KillFromPlayer(ply, killer, remove_body)
end, PlayerAutoComplete, "Kills the local player from a random target", FCVAR_CHEAT)

concommand.Add("ttt_kill_from_player", function(ply, cmd, args)
    if not IsValid(ply) or not ply:Alive() then return end
    if #args == 0 then return end

    local killer_name = args[1]
    local killer = nil
    for _, v in RandomPairs(player.GetAll()) do
        if IsValid(v) and v:Alive() and not v:IsSpec() and v ~= ply and not (v:IsJesterTeam() and not v:GetNWBool("KillerClownActive", false)) and v:Nick() == killer_name then
            killer = v
            break
        end
    end

    if killer == nil then
        print("No player named " .. killer_name .. " found")
        return
    end

    local remove_body = #args > 1 and tobool(args[2])
    KillFromPlayer(ply, killer, remove_body)
end, PlayerAutoComplete, "Kills the local player from a specific target", FCVAR_CHEAT)

concommand.Add("ttt_kill_target_from_random", function(ply, cmd, args)
    if #args ~= 1 then return end

    local victim_name = args[1]
    local victim = nil
    for _, v in RandomPairs(player.GetAll()) do
        if IsValid(v) and v:Alive() and not v:IsSpec() and v ~= ply and v:Nick() == victim_name then
            victim = v
            break
        end
    end

    local killer = nil
    for _, v in RandomPairs(player.GetAll()) do
        if IsValid(v) and v:Alive() and not v:IsSpec() and v ~= ply and not (v:IsJesterTeam() and not v:GetNWBool("KillerClownActive", false)) then
            killer = v
            break
        end
    end

    local remove_body = #args > 1 and tobool(args[2])
    KillFromPlayer(victim, killer, remove_body)
end, PlayerAutoComplete, "Kills a target from a random target", FCVAR_CHEAT)

concommand.Add("ttt_kill_target_from_player", function(ply, cmd, args)
    if #args ~= 2 then return end

    local victim_name = args[1]
    local victim = nil
    for _, v in RandomPairs(player.GetAll()) do
        if IsValid(v) and v:Alive() and not v:IsSpec() and v ~= ply and v:Nick() == victim_name then
            victim = v
            break
        end
    end

    local killer_name = args[2]
    local killer = nil
    for _, v in RandomPairs(player.GetAll()) do
        if IsValid(v) and v:Alive() and not v:IsSpec() and v ~= ply and not (v:IsJesterTeam() and not v:GetNWBool("KillerClownActive", false)) and v:Nick() == killer_name then
            killer = v
            break
        end
    end

    if killer == nil then
        print("No player named " .. killer_name .. " found")
        return
    end

    local remove_body = #args > 2 and tobool(args[3])
    KillFromPlayer(victim, killer, remove_body)
end, PlayerAutoComplete, "Kills a target from another target", FCVAR_CHEAT)