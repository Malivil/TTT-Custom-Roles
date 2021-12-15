AddCSLuaFile()

local hook = hook

-- Initialize role features

-- HandleDetectiveLikePromotion and ROLE_MOVE_ROLE_STATE are defined in detectivelike/shared.lua
-- ROLE_ON_ROLE_ASSIGNED is defined in detectivelike/detectivelike.lua

ROLE_IS_ACTIVE[ROLE_DEPUTY] = function(ply)
    return ply:GetNWBool("HasPromotion", false)
end

local function InitializeEquipment()
    if EquipmentItems then
        local mat_dir = "vgui/ttt/"
        EquipmentItems[ROLE_DEPUTY] = {
            -- body armor
            { id = EQUIP_ARMOR,
              type = "item_passive",
              material = mat_dir .. "icon_armor",
              name = "item_armor",
              desc = "item_armor_desc"
            },

            -- radar
            { id = EQUIP_RADAR,
              type = "item_active",
              material = mat_dir .. "icon_radar",
              name = "item_radar",
              desc = "item_radar_desc"
            }
        }
    end

    if DefaultEquipment then
        DefaultEquipment[ROLE_DEPUTY] = {
            EQUIP_ARMOR,
            EQUIP_RADAR
        }
    end
end
InitializeEquipment()

hook.Add("Initialize", "Deputy_Shared_Initialize", function()
    InitializeEquipment()
end)
hook.Add("TTTPrepareRound", "Deputy_Shared_TTTPrepareRound", function()
    InitializeEquipment()
end)