include("shared.lua")

local net = net
local util = util
local file = file
local table = table
local string = string

local StringSub = string.sub
local TableInsert = table.insert
local TableRemove = table.remove
local TableRemoveByValue = table.RemoveByValue
local TableHasValue = table.HasValue
local TableShuffle = table.Shuffle
local TableCopy = table.Copy

ROLEPACKS = {}

util.AddNetworkString("TTT_WriteRolePackRoles")
util.AddNetworkString("TTT_WriteRolePackRoles_Part")
util.AddNetworkString("TTT_RequestRolePackRoles")
util.AddNetworkString("TTT_ReadRolePackRoles")
util.AddNetworkString("TTT_ReadRolePackRoles_Part")
util.AddNetworkString("TTT_WriteRolePackRoleBlocks")
util.AddNetworkString("TTT_WriteRolePackRoleBlocks_Part")
util.AddNetworkString("TTT_RequestRolePackRoleBlocks")
util.AddNetworkString("TTT_ReadRolePackRoleBlocks")
util.AddNetworkString("TTT_ReadRolePackRoleBlocks_Part")
util.AddNetworkString("TTT_WriteRolePackWeapons")
util.AddNetworkString("TTT_WriteRolePackWeapons_Part")
util.AddNetworkString("TTT_RequestRolePackWeapons")
util.AddNetworkString("TTT_ReadRolePackWeapons")
util.AddNetworkString("TTT_ReadRolePackWeapons_Part")
util.AddNetworkString("TTT_WriteRolePackConvars")
util.AddNetworkString("TTT_WriteRolePackConvars_Part")
util.AddNetworkString("TTT_RequestRolePackConvars")
util.AddNetworkString("TTT_ReadRolePackConvars")
util.AddNetworkString("TTT_ReadRolePackConvars_Part")
util.AddNetworkString("TTT_RequestRolePackList")
util.AddNetworkString("TTT_SendRolePackList")
util.AddNetworkString("TTT_CreateRolePack")
util.AddNetworkString("TTT_RenameRolePack")
util.AddNetworkString("TTT_DeleteRolePack")
util.AddNetworkString("TTT_SavedRolePack")
util.AddNetworkString("TTT_ApplyRolePack")
util.AddNetworkString("TTT_ClearRolePack")
util.AddNetworkString("TTT_SendRolePackRoleList")
util.AddNetworkString("TTT_RolePackBuyableWeapons")

-- 2^16 bytes - 4 (header) - 2 (UInt length) - 1 (Extra optional byte) - 1 (terminanting byte)
local maxStreamLength = 65528

local function SendStreamToClient(ply, json, networkString, byte)
    if not json or #json == 0 then return end
    local jsonTable = util.Compress(json)
    if #jsonTable == 0 then
        ErrorNoHalt("Table compression failed!\n")
        return
    end

    local len = #jsonTable

    if len <= maxStreamLength then
        net.Start(networkString)
        net.WriteUInt(byte or 0, 8)
        net.WriteUInt(len, 16)
        net.WriteData(jsonTable, len)
        net.Send(ply)
    else
        local curpos = 0

        repeat
            net.Start(networkString .. "_Part")
            net.WriteData(StringSub(jsonTable, curpos + 1, curpos + maxStreamLength + 1), maxStreamLength)
            net.Send(ply)

            curpos = curpos + maxStreamLength + 1
        until (len - curpos <= maxStreamLength)

        net.Start(networkString)
        net.WriteUInt(byte or 0, 8)
        net.WriteUInt(len, 16)
        net.WriteData(StringSub(jsonTable, curpos + 1, len), len - curpos)
        net.Send(ply)
    end
end

local function ReceiveStreamFromClient(networkString, callback)
    local buff = ""
    net.Receive(networkString .. "_Part", function(len, ply)
        if not ply:IsAdmin() and not ply:IsSuperAdmin() then
            ErrorNoHalt("ERROR: You must be an administrator to configure Role Packs\n")
            return
        end

        buff = buff .. net.ReadData(maxStreamLength)
    end)

    net.Receive(networkString, function(len, ply)
        if not ply:IsAdmin() and not ply:IsSuperAdmin() then
            ErrorNoHalt("ERROR: You must be an administrator to configure Role Packs\n")
            return
        end

        local jsonTable = util.Decompress(buff .. net.ReadData(net.ReadUInt(16)))
        buff = ""

        if #jsonTable == 0 then
            ErrorNoHalt("Table decompression failed!\n")
            return
        end

        callback(jsonTable)
    end)
end

local function WriteRolePackRoles(json)
    local jsonTable = util.JSONToTable(json)
    local name = jsonTable.name
    file.Write("rolepacks/" .. name .. "/roles.json", json)
end
ReceiveStreamFromClient("TTT_WriteRolePackRoles", WriteRolePackRoles)

net.Receive("TTT_RequestRolePackRoles", function(len, ply)
    if not ply:IsAdmin() and not ply:IsSuperAdmin() then
        ErrorNoHalt("ERROR: You must be an administrator to configure Role Packs\n")
        return
    end

    local name = net.ReadString()
    local json = file.Read("rolepacks/" .. name .. "/roles.json", "DATA")
    if not json then return end
    SendStreamToClient(ply, json, "TTT_ReadRolePackRoles")
end)

local function WriteRolePackRoleBlocks(json)
    local jsonTable = util.JSONToTable(json)
    local name = jsonTable.name
    file.Write("rolepacks/" .. name .. "/roleblocks.json", json)
end
ReceiveStreamFromClient("TTT_WriteRolePackRoleBlocks", WriteRolePackRoleBlocks)

net.Receive("TTT_RequestRolePackRoleBlocks", function(len, ply)
    if not ply:IsAdmin() and not ply:IsSuperAdmin() then
        ErrorNoHalt("ERROR: You must be an administrator to configure Role Packs\n")
        return
    end

    local name = net.ReadString()
    local json = file.Read("rolepacks/" .. name .. "/roleblocks.json", "DATA")
    if not json then return end
    SendStreamToClient(ply, json, "TTT_ReadRolePackRoleBlocks")
end)

local function WriteRolePackWeapons(json)
    local jsonTable = util.JSONToTable(json)
    if not jsonTable then
        ErrorNoHalt("Table decoding failed!\n")
        return
    end

    local name = jsonTable.name

    for role, tbl in pairs(jsonTable.weapons) do
        local roleJson = util.TableToJSON(tbl)
        if not roleJson then
            ErrorNoHalt("Table encoding failed!\n")
            return
        end

        file.Write("rolepacks/" .. name .. "/weapons/" .. ROLE_STRINGS_RAW[role] .. ".json", roleJson)
    end
end
ReceiveStreamFromClient("TTT_WriteRolePackWeapons", WriteRolePackWeapons)

net.Receive("TTT_RequestRolePackWeapons", function(len, ply)
    if not ply:IsAdmin() and not ply:IsSuperAdmin() then
        ErrorNoHalt("ERROR: You must be an administrator to configure Role Packs\n")
        return
    end

    local name = net.ReadString()
    local role = net.ReadUInt(8)
    local json = file.Read("rolepacks/" .. name .. "/weapons/" .. ROLE_STRINGS_RAW[role] .. ".json", "DATA")
    if not json then return end
    SendStreamToClient(ply, json, "TTT_ReadRolePackWeapons", role)
end)

local function WriteRolePackConvars(json)
    local jsonTable = util.JSONToTable(json)
    local name = jsonTable.name
    file.Write("rolepacks/" .. name .. "/convars.json", json)
end
ReceiveStreamFromClient("TTT_WriteRolePackConvars", WriteRolePackConvars)

net.Receive("TTT_RequestRolePackConvars", function(len, ply)
    if not ply:IsAdmin() and not ply:IsSuperAdmin() then
        ErrorNoHalt("ERROR: You must be an administrator to configure Role Packs\n")
        return
    end

    local name = net.ReadString()
    local json = file.Read("rolepacks/" .. name .. "/convars.json", "DATA")
    if not json then return end
    SendStreamToClient(ply, json, "TTT_ReadRolePackConvars")
end)

local function SendRolePackList(ply)
    net.Start("TTT_SendRolePackList")
    local _, directories = file.Find("rolepacks/*", "DATA")
    net.WriteUInt(#directories, 8)
    for _, v in pairs(directories) do
        net.WriteString(v)
    end
    net.Send(ply)
end

net.Receive("TTT_RequestRolePackList", function(len, ply)
    if not ply:IsAdmin() and not ply:IsSuperAdmin() then
        ErrorNoHalt("ERROR: You must be an administrator to configure Role Packs\n")
        return
    end

    SendRolePackList(ply)
end)

net.Receive("TTT_CreateRolePack", function(len, ply)
    if not ply:IsAdmin() and not ply:IsSuperAdmin() then
        ErrorNoHalt("ERROR: You must be an administrator to configure Role Packs\n")
        return
    end

    local name = net.ReadString()
    if not file.IsDir("rolepacks", "DATA") then
        if file.Exists("rolepacks", "DATA") then
            ErrorNoHalt("Item named 'rolepacks' already exists in garrysmod/data but it is not a directory\n")
            return
        end

        file.CreateDir("rolepacks")
    end
    file.CreateDir("rolepacks/" .. name)
    file.Write("rolepacks/" .. name .. "/roles.json", "{}")
    file.CreateDir("rolepacks/" .. name .. "/weapons")
    file.Write("rolepacks/" .. name .. "/convars.json", "{}")
end)

net.Receive("TTT_RenameRolePack", function(len, ply)
    if not ply:IsAdmin() and not ply:IsSuperAdmin() then
        ErrorNoHalt("ERROR: You must be an administrator to configure Role Packs\n")
        return
    end

    local oldName = net.ReadString()
    local newName = net.ReadString()
    local newPath = "rolepacks/" .. newName
    if file.Exists(newPath, "DATA") then
        ErrorNoHalt("Role pack named '" .. newName .. "' already exists!\n")
        return
    end

    local oldPath = "rolepacks/" .. oldName
    if file.Exists(oldPath, "DATA") then
        file.Rename(oldPath, newPath)
    end

    SendRolePackList(ply)
end)

net.Receive("TTT_DeleteRolePack", function(len, ply)
    if not ply:IsAdmin() and not ply:IsSuperAdmin() then
        ErrorNoHalt("ERROR: You must be an administrator to configure Role Packs\n")
        return
    end

    local name = net.ReadString()
    local path = "rolepacks/" .. name
    if file.Exists(path, "DATA") then
        file.Delete(path .. "/roles.json")
        file.Delete(path .. "/roleblocks.json")
        file.Delete(path .. "/convars.json")
        for _, v in pairs(file.Find(path .. "/weapons/*.json", "DATA")) do
            file.Delete(path .. "/weapons/" .. v)
        end
        file.Delete(path .. "/weapons")
        file.Delete(path)
    end

    SendRolePackList(ply)
end)

net.Receive("TTT_SavedRolePack", function(len, ply)
    if not ply:IsAdmin() and not ply:IsSuperAdmin() then
        ErrorNoHalt("ERROR: You must be an administrator to configure Role Packs\n")
        return
    end

    local savedPack = net.ReadString()
    local currentPack = GetConVar("ttt_role_pack"):GetString()
    if savedPack == currentPack then
        ROLEPACKS.SendRolePackRoleList()
        ROLEPACKS.ApplyRolePackConVars()
        ROLEPACKS.FillRolePackWeaponTables()
    end
end)

net.Receive("TTT_ApplyRolePack", function(len, ply)
    if not ply:IsAdmin() and not ply:IsSuperAdmin() then
        ErrorNoHalt("ERROR: You must be an administrator to configure Role Packs\n")
        return
    end

    local name = net.ReadString()
    GetConVar("ttt_role_pack"):SetString(name)
end)

net.Receive("TTT_ClearRolePack", function(len, ply)
    if not ply:IsAdmin() and not ply:IsSuperAdmin() then
        ErrorNoHalt("ERROR: You must be an administrator to configure Role Packs\n")
        return
    end

    GetConVar("ttt_role_pack"):SetString("")
end)

function ROLEPACKS.SendRolePackRoleList(ply)
    ROLE_PACK_ROLES = {}

    net.Start("TTT_SendRolePackRoleList")
    local name = GetConVar("ttt_role_pack"):GetString()
    local json = file.Read("rolepacks/" .. name .. "/roles.json", "DATA")
    if not json then
        net.WriteUInt(0, 8)
        net.Broadcast()
        return
    end

    local jsonTable = util.JSONToTable(json)
    if jsonTable == nil then
        ErrorNoHalt("Table decoding failed!\n")
        net.WriteUInt(0, 8)
        net.Broadcast()
        return
    end

    local roles = {}
    if jsonTable.slots then
        for _, slot in pairs(jsonTable.slots) do
            for _, roleslot in pairs(slot) do
                local role = ROLE_NONE
                for r = ROLE_INNOCENT, ROLE_MAX do
                    if ROLE_STRINGS_RAW[r] == roleslot.role then
                        role = r
                        break
                    end
                end
                if role ~= ROLE_NONE and not TableHasValue(roles, role) then
                    TableInsert(roles, role)
                end
            end
        end
    end

    net.WriteUInt(#roles, 8)
    for _, role in pairs(roles) do
        net.WriteUInt(role, 8)
        ROLE_PACK_ROLES[role] = true
    end
    if ply then
        net.Send(ply)
    else
        net.Broadcast()
    end
end

function ROLEPACKS.GetRolePackBlockedRoles()
    local name = GetConVar("ttt_role_pack"):GetString()
    local json = file.Read("rolepacks/" .. name .. "/roleblocks.json", "DATA")
    if not json then return end

    local jsonTable = util.JSONToTable(json)
    if jsonTable == nil then
        ErrorNoHalt("Table decoding failed!\n")
        return
    end

    return jsonTable
end

function ROLEPACKS.SendRolePackWeapons(ply)
    local rolePackName = GetConVar("ttt_role_pack"):GetString()
    if #rolePackName == 0 then return end

    for id, _ in pairs(ROLE_STRINGS_RAW) do
        local roleBuyables = WEPS.RolePackBuyableWeapons[id]
        local roleExcludes = WEPS.RolePackExcludeWeapons[id]
        local roleNoRandoms = WEPS.RolePackBypassRandomWeapons[id]
        local roleLoadouts = WEPS.RolePackLoadoutWeapons[id]

        if #roleBuyables > 0 or #roleExcludes > 0 or #roleNoRandoms > 0 or #roleLoadouts > 0 then
            net.Start("TTT_RolePackBuyableWeapons")
            net.WriteInt(id, 16)
            net.WriteTable(roleBuyables, true)
            net.WriteTable(roleExcludes, true)
            net.WriteTable(roleNoRandoms, true)
            net.WriteTable(roleLoadouts, true)
            net.Send(ply)
        end
    end
end

function ROLEPACKS.AssignRoles(choices)
    local rolePackName = GetConVar("ttt_role_pack"):GetString()
    if #rolePackName == 0 then return end

    local json = file.Read("rolepacks/" .. rolePackName .. "/roles.json", "DATA")
    if not json then
        ErrorNoHalt("No role pack named '" .. rolePackName .. "' found!\n")
        return
    end

    local jsonTable = util.JSONToTable(json)
    if not jsonTable then
        ErrorNoHalt("Table decoding failed!\n")
        return
    end

    local blockedRoles = {}
    local toBlockRoles = {}
    local roleblocks = ROLEBLOCKS.GetBlockedRoles()

    local rolePackChoices = table.Copy(choices)
    local forcedRoles = {}
    for k, v in ipairs(rolePackChoices) do
        if v.forcedRole and v.forcedRole ~= ROLE_NONE then
            TableInsert(forcedRoles, v.forcedRole)
            TableRemove(rolePackChoices, k)
            if roleblocks and #roleblocks > 0 then
                for _, group in ipairs(roleblocks) do
                    for i, groupRole in ipairs(group) do
                        if groupRole.role == ROLE_STRINGS_RAW[v.forcedRole] then
                            local blockGroup = TableCopy(group)
                            TableRemove(blockGroup, i)
                            for _, blockRole in ipairs(blockGroup) do
                                local toBlock = ROLE_NONE
                                for r = ROLE_INNOCENT, ROLE_MAX do
                                    if ROLE_STRINGS_RAW[r] == blockRole.role then
                                        toBlock = r
                                        break
                                    end
                                end
                                blockedRoles[toBlock] = true
                            end
                            break
                        end
                    end
                end
            end
        end
    end

    if roleblocks and #roleblocks > 0 then
        for _, group in ipairs(roleblocks) do
            if #group == 2 and group[1].role == group[2].role then
                local role = ROLE_NONE
                for r = ROLE_INNOCENT, ROLE_MAX do
                    if ROLE_STRINGS_RAW[r] == group[1].role then
                        role = r
                        break
                    end
                end
                toBlockRoles[role] = true
            else
                local groupRoles = {}
                for _, groupRole in ipairs(group) do
                    local role = ROLE_NONE
                    for r = ROLE_INNOCENT, ROLE_MAX do
                        if ROLE_STRINGS_RAW[r] == groupRole.role then
                            role = r
                            break
                        end
                    end
                    if role ~= ROLE_NONE and not blockedRoles[role] then
                        for _ = 1, groupRole.weight do
                            TableInsert(groupRoles, role)
                        end
                    end
                end
                TableShuffle(groupRoles)
                local chosenRole = groupRoles[1]
                for _, role in ipairs(groupRoles) do
                    if role ~= chosenRole then
                        blockedRoles[role] = true
                    end
                end
            end
        end
    end

    if jsonTable.config then
        local allowDuplicates = jsonTable.config.allowduplicates

        local chosenRoles = {}
        for _, slot in ipairs(jsonTable.slots) do
            if #rolePackChoices <= 0 then break end

            local possibleRoles = {}
            local skipSlot = false
            for _, roleslot in ipairs(slot) do
                local role = ROLE_NONE
                for r = ROLE_INNOCENT, ROLE_MAX do
                    if ROLE_STRINGS_RAW[r] == roleslot.role then
                        role = r
                        break
                    end
                end

                if role == ROLE_NONE then continue end

                if TableHasValue(forcedRoles, role) then
                    TableRemoveByValue(forcedRoles, role)
                    TableInsert(chosenRoles, role)
                    skipSlot = true
                    break
                end

                if not allowDuplicates and TableHasValue(chosenRoles, role) then continue end

                if blockedRoles[role] then continue end

                for _ = 1, roleslot.weight do
                    TableInsert(possibleRoles, role)
                end
            end

            if skipSlot then continue end

            if #possibleRoles <= 0 then
                TableRemove(rolePackChoices) -- We still need to remove a player in the case of an empty slot
                continue
            end

            TableShuffle(possibleRoles)
            local role = TableRemove(possibleRoles)

            if toBlockRoles[role] then
                blockedRoles[role] = true
            end

            local ply
            if DETECTIVE_ROLES[role] then
                local minKarma = GetConVar("ttt_detective_karma_min"):GetInt()
                local willingDetectiveChoices = {}
                local goodKarmaChoices = {}
                for _, p in ipairs(rolePackChoices) do
                    if not KARMA.IsEnabled() or p:GetBaseKarma() >= minKarma then
                        if not p:ShouldAvoidDetective() then
                            TableInsert(willingDetectiveChoices, p)
                        end
                        TableInsert(goodKarmaChoices, p)
                    end
                end

                if #willingDetectiveChoices > 0 then
                    ply = TableRemove(willingDetectiveChoices)
                    TableRemoveByValue(rolePackChoices, ply)
                elseif #goodKarmaChoices > 0 then
                    ply = TableRemove(goodKarmaChoices)
                    TableRemoveByValue(rolePackChoices, ply)
                else
                    ply = TableRemove(rolePackChoices)
                end
            else
                ply = TableRemove(rolePackChoices)
            end

            ply:SetRole(role)
            table.insert(chosenRoles, role)
        end
    end

    ROLEPACKS.SendRolePackRoleList()
end

ROLEPACKS.OldConVars = {}

function ROLEPACKS.ApplyRolePackConVars()
    for cvar, value in pairs(ROLEPACKS.OldConVars) do
        GetConVar(cvar):SetString(value)
        ROLEPACKS.OldConVars[cvar] = nil
    end

    local rolePackName = GetConVar("ttt_role_pack"):GetString()
    if #rolePackName == 0 then return end

    local json = file.Read("rolepacks/" .. rolePackName .. "/convars.json", "DATA")
    if not json then
        ErrorNoHalt("No role pack named '" .. rolePackName .. "' found!\n")
        return
    end

    local jsonTable = util.JSONToTable(json)
    if not jsonTable then
        ErrorNoHalt("Table decoding failed!\n")
        return
    end

    local cvarsToChange = {}
    if jsonTable.convars then
        for _, v in ipairs(jsonTable.convars) do
            if not v.cvar or not v.value or v.cvar == "ttt_role_pack" then continue end
            local cvar = GetConVar(v.cvar)
            if cvar == nil then
                v.invalid = true
                continue
            else
                v.invalid = false
                local oldValue = cvar:GetString()
                local newValue = v.value
                if oldValue ~= newValue then
                    cvarsToChange[v.cvar] = {oldValue = oldValue, newValue = newValue}
                end
            end
        end
    end

    json = util.TableToJSON(jsonTable)
    if not json then
        ErrorNoHalt("Table encoding failed!\n")
        return
    end
    file.Write("rolepacks/" .. rolePackName .. "/convars.json", json)

    for cvar, value in pairs(cvarsToChange) do
        GetConVar(cvar):SetString(value.newValue)
        ROLEPACKS.OldConVars[cvar] = value.oldValue
    end
end

function ROLEPACKS.FillRolePackWeaponTables()
    local rolePackName = GetConVar("ttt_role_pack"):GetString()
    if #rolePackName == 0 then return end

    local handled = false
    for id, name in pairs(ROLE_STRINGS_RAW) do
        WEPS.PrepWeaponsLists(id)

        local roleBuyables = {}
        local roleExcludes = {}
        local roleNoRandoms = {}
        local roleLoadouts = {}

        local roleJson = file.Read("rolepacks/" .. rolePackName .. "/weapons/" .. name .. ".json", "DATA")
        if roleJson then
            local roleData = util.JSONToTable(roleJson)
            if roleData then
                roleBuyables = roleData.Buyables or {}
                roleExcludes = roleData.Excludes or {}
                roleNoRandoms = roleData.NoRandoms or {}
                roleLoadouts = roleData.Loadouts or {}
            end
        end

        -- Copy the loaded table into the global table for this role
        WEPS.RolePackBuyableWeapons[id] = roleBuyables
        WEPS.RolePackExcludeWeapons[id] = roleExcludes
        WEPS.RolePackBypassRandomWeapons[id] = roleNoRandoms
        WEPS.RolePackLoadoutWeapons[id] = roleLoadouts

        if #roleBuyables > 0 or #roleExcludes > 0 or #roleNoRandoms > 0 or #roleLoadouts > 0 then
            net.Start("TTT_RolePackBuyableWeapons")
            net.WriteInt(id, 16)
            net.WriteTable(roleBuyables, true)
            net.WriteTable(roleExcludes, true)
            net.WriteTable(roleNoRandoms, true)
            net.WriteTable(roleLoadouts, true)
            net.Broadcast()
            handled = true
        end
    end

    -- Send this once if the rolepack weapons feature wasn't used (which resets the cache on its own)
    if not handled then
        net.Start("TTT_ResetBuyableWeaponsCache")
        net.Broadcast()
    end
end

cvars.AddChangeCallback("ttt_role_pack", function(cvar, old, new)
    ROLEPACKS.SendRolePackRoleList()
    ROLEPACKS.ApplyRolePackConVars()
    ROLEPACKS.FillRolePackWeaponTables()
end)