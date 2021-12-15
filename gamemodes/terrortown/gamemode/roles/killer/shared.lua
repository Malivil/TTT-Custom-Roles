AddCSLuaFile()

local hook = hook

-- Initialize role features
ROLE_STARTING_HEALTH[ROLE_KILLER] = 150
ROLE_MAX_HEALTH[ROLE_KILLER] = 150
ROLE_STARTING_CREDITS[ROLE_KILLER] = 2

local function InitializeEquipment()
    if EquipmentItems then
        local mat_dir = "vgui/ttt/"
        EquipmentItems[ROLE_KILLER] = {
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
            },

            -- disguiser
            { id = EQUIP_DISGUISE,
              type = "item_active",
              material = mat_dir .. "icon_disguise",
              name = "item_disg",
              desc = "item_disg_desc"
            }
        }
    end

    if DefaultEquipment then
        DefaultEquipment[ROLE_KILLER] = {
            "weapon_ttt_health_station",
            "weapon_ttt_teleport",
            "weapon_ttt_confgrenade",
            "weapon_ttt_m16",
            "weapon_ttt_smokegrenade",
            "weapon_zm_mac10",
            "weapon_zm_molotov",
            "weapon_zm_pistol",
            "weapon_zm_revolver",
            "weapon_zm_rifle",
            "weapon_zm_shotgun",
            "weapon_zm_sledge",
            "weapon_ttt_glock",
            "weapon_kil_crowbar",
            "weapon_kil_knife",
            EQUIP_ARMOR,
            EQUIP_RADAR,
            EQUIP_DISGUISE
        }
    end
end
InitializeEquipment()

hook.Add("Initialize", "Killer_Shared_Initialize", function()
    InitializeEquipment()
end)
hook.Add("TTTPrepareRound", "Killer_Shared_TTTPrepareRound", function()
    InitializeEquipment()
end)