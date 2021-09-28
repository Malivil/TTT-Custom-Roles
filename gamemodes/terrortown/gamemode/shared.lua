-- Version string for display and function for version checks
CR_VERSION = "1.2.6"

function CRVersion(version)
    local installedVersionRaw = string.Split(CR_VERSION, ".")
    local installedVersion = {
        major = tonumber(installedVersionRaw[1]),
        minor = tonumber(installedVersionRaw[2]),
        patch = tonumber(installedVersionRaw[3])
    }

    local neededVersionRaw = string.Split(version, ".")
    local neededVersion = {
        major = tonumber(neededVersionRaw[1]),
        minor = tonumber(neededVersionRaw[2]),
        patch = tonumber(neededVersionRaw[3])
    }

    if installedVersion.major > neededVersion.major then
        return true
    elseif installedVersion.major == neededVersion.major then
        if installedVersion.minor > neededVersion.minor then
            return true
        elseif installedVersion.minor == neededVersion.minor then
            if installedVersion.patch >= neededVersion.patch then
                return true
            end
        end
    end

    return false
end

GM.Name = "Trouble in Terrorist Town"
GM.Author = "Bad King Urgrain"
GM.Website = "ttt.badking.net"
GM.Version = "Custom Roles for TTT v" .. CR_VERSION

GM.Customized = false

-- Round status consts
ROUND_WAIT = 1
ROUND_PREP = 2
ROUND_ACTIVE = 3
ROUND_POST = 4

-- Player roles
ROLE_NONE = -1
ROLE_INNOCENT = 0
ROLE_TRAITOR = 1
ROLE_DETECTIVE = 2
ROLE_JESTER = 3
ROLE_SWAPPER = 4
ROLE_GLITCH = 5
ROLE_PHANTOM = 6
ROLE_HYPNOTIST = 7
ROLE_REVENGER = 8
ROLE_DRUNK = 9
ROLE_CLOWN = 10
ROLE_DEPUTY = 11
ROLE_IMPERSONATOR = 12
ROLE_BEGGAR = 13
ROLE_OLDMAN = 14
ROLE_MERCENARY = 15
ROLE_BODYSNATCHER = 16
ROLE_VETERAN = 17
ROLE_ASSASSIN = 18
ROLE_KILLER = 19
ROLE_ZOMBIE = 20
ROLE_VAMPIRE = 21
ROLE_DOCTOR = 22
ROLE_QUACK = 23
ROLE_PARASITE = 24
ROLE_TRICKSTER = 25
ROLE_PARAMEDIC = 26
ROLE_MADSCIENTIST = 27
ROLE_PALADIN = 28
ROLE_TRACKER = 29
ROLE_MEDIUM = 30

ROLE_MAX = 30
ROLE_EXTERNAL_START = ROLE_MAX + 1

local function AddRoleAssociations(list, roles)
    -- Use an associative array so we can do a O(1) lookup by role
    -- See: https://wiki.facepunch.com/gmod/table.HasValue
    for _, r in ipairs(roles) do
        list[r] = true
    end
end

function GetTeamRoles(list, excludes)
    local roles = {}
    for r, v in pairs(list) do
        if v and (not excludes or not excludes[r]) then
            table.insert(roles, r)
        end
    end
    return roles
end

SHOP_ROLES = {}
AddRoleAssociations(SHOP_ROLES, {ROLE_TRAITOR, ROLE_DETECTIVE, ROLE_HYPNOTIST, ROLE_DEPUTY, ROLE_IMPERSONATOR, ROLE_JESTER, ROLE_SWAPPER, ROLE_CLOWN, ROLE_MERCENARY, ROLE_ASSASSIN, ROLE_KILLER, ROLE_ZOMBIE, ROLE_VAMPIRE, ROLE_VETERAN, ROLE_DOCTOR, ROLE_QUACK, ROLE_PARASITE, ROLE_PALADIN, ROLE_TRACKER, ROLE_MEDIUM})

DELAYED_SHOP_ROLES = {}
AddRoleAssociations(DELAYED_SHOP_ROLES, {ROLE_CLOWN, ROLE_VETERAN})

TRAITOR_ROLES = {}
AddRoleAssociations(TRAITOR_ROLES, {ROLE_TRAITOR, ROLE_HYPNOTIST, ROLE_IMPERSONATOR, ROLE_ASSASSIN, ROLE_VAMPIRE, ROLE_QUACK, ROLE_PARASITE})

INNOCENT_ROLES = {}
AddRoleAssociations(INNOCENT_ROLES, {ROLE_INNOCENT, ROLE_DETECTIVE, ROLE_GLITCH, ROLE_PHANTOM, ROLE_REVENGER, ROLE_DEPUTY, ROLE_MERCENARY, ROLE_VETERAN, ROLE_DOCTOR, ROLE_TRICKSTER, ROLE_PARAMEDIC, ROLE_PALADIN, ROLE_TRACKER, ROLE_MEDIUM})

JESTER_ROLES = {}
AddRoleAssociations(JESTER_ROLES, {ROLE_JESTER, ROLE_SWAPPER, ROLE_CLOWN, ROLE_BEGGAR, ROLE_BODYSNATCHER})

INDEPENDENT_ROLES = {}
AddRoleAssociations(INDEPENDENT_ROLES, {ROLE_DRUNK, ROLE_OLDMAN, ROLE_KILLER, ROLE_ZOMBIE, ROLE_MADSCIENTIST})

MONSTER_ROLES = {}
AddRoleAssociations(MONSTER_ROLES, {})

DETECTIVE_ROLES = {}
AddRoleAssociations(DETECTIVE_ROLES, {ROLE_DETECTIVE, ROLE_PALADIN, ROLE_TRACKER, ROLE_MEDIUM})

DEFAULT_ROLES = {}
AddRoleAssociations(DEFAULT_ROLES, {ROLE_INNOCENT, ROLE_TRAITOR, ROLE_DETECTIVE})

-- Traitors get this ability by default
TRAITOR_BUTTON_ROLES = {}
AddRoleAssociations(TRAITOR_BUTTON_ROLES, {ROLE_TRICKSTER})

-- Shop roles get this ability by default
CAN_LOOT_CREDITS_ROLES = {}
AddRoleAssociations(CAN_LOOT_CREDITS_ROLES, {ROLE_TRICKSTER})

-- Role colours
COLOR_INNOCENT = {
    ["default"] = Color(25, 200, 25, 255),
    ["simple"] = Color(25, 200, 25, 255),
    ["protan"] = Color(128, 209, 255, 255),
    ["deutan"] = Color(128, 209, 255, 255),
    ["tritan"] = Color(25, 200, 25, 255)
}

COLOR_SPECIAL_INNOCENT = {
    ["default"] = Color(245, 200, 0, 255),
    ["simple"] = Color(25, 200, 25, 255),
    ["protan"] = Color(128, 209, 255, 255),
    ["deutan"] = Color(128, 209, 255, 255),
    ["tritan"] = Color(25, 200, 25, 255)
}

COLOR_TRAITOR = {
    ["default"] = Color(200, 25, 25, 255),
    ["simple"] = Color(200, 25, 25, 255),
    ["protan"] = Color(200, 25, 25, 255),
    ["deutan"] = Color(200, 25, 25, 255),
    ["tritan"] = Color(200, 25, 25, 255)
}

COLOR_SPECIAL_TRAITOR = {
    ["default"] = Color(245, 106, 0, 255),
    ["simple"] = Color(200, 25, 25, 255),
    ["protan"] = Color(200, 25, 25, 255),
    ["deutan"] = Color(200, 25, 25, 255),
    ["tritan"] = Color(200, 25, 25, 255)
}

COLOR_DETECTIVE = {
    ["default"] = Color(25, 25, 200, 255),
    ["simple"] = Color(25, 25, 200, 255),
    ["protan"] = Color(25, 25, 200, 255),
    ["deutan"] = Color(25, 25, 200, 255),
    ["tritan"] = Color(25, 25, 200, 255),
}

COLOR_SPECIAL_DETECTIVE = {
    ["default"] = Color(40, 180, 200, 255),
    ["simple"] = Color(25, 25, 200, 255),
    ["protan"] = Color(25, 25, 200, 255),
    ["deutan"] = Color(25, 25, 200, 255),
    ["tritan"] = Color(25, 25, 200, 255),
}

COLOR_JESTER = {
    ["default"] = Color(180, 23, 253, 255),
    ["simple"] = Color(180, 23, 253, 255),
    ["protan"] = Color(255, 194, 5, 255),
    ["deutan"] = Color(93, 247, 0, 255),
    ["tritan"] = Color(255, 194, 5, 255)
}

COLOR_INDEPENDENT = {
    ["default"] = Color(112, 50, 0, 255),
    ["simple"] = Color(112, 50, 0, 255),
    ["protan"] = Color(167, 161, 142, 255),
    ["deutan"] = Color(127, 137, 120, 255),
    ["tritan"] = Color(192, 199, 63, 255)
}

COLOR_MONSTER = {
    ["default"] = Color(69, 97, 0, 255),
    ["simple"] = Color(69, 97, 0, 255),
    ["protan"] = Color(69, 97, 0, 255),
    ["deutan"] = Color(69, 97, 0, 255),
    ["tritan"] = Color(69, 97, 0, 255)
}

local function ColorFromCustomConVars(name)
    local rConVar = GetConVar(name .. "_r")
    local gConVar = GetConVar(name .. "_g")
    local bConVar = GetConVar(name .. "_b")
    if rConVar and gConVar and bConVar then
        local r = tonumber(rConVar:GetString())
        local g = tonumber(gConVar:GetString())
        local b = tonumber(bConVar:GetString())
        return Color(r, g, b, 255)
    end
end

local function ModifyColor(color, type)
    local h, s, l = ColorToHSL(color)
    if type == "dark" then
        l = math.max(l - 0.125, 0.125)
    elseif type == "highlight" or "radar" then
        s = 1
    end

    local c = HSLToColor(h, s, l)
    if type == "scoreboard" then
        c = ColorAlpha(c, 30)
    elseif type == "sprite" then
        c = ColorAlpha(c, 130)
    elseif type == "radar" then
        c = ColorAlpha(c, 230)
    -- HSLToColor doesn't apply the Color metatable so call ColorAlpha to ensure this is actually a "Color"
    else
        c = ColorAlpha(c, 255)
    end

    return c
end

local function FillRoleColors(list, type)
    local modeCVar = GetConVar("ttt_color_mode")
    local mode = modeCVar and modeCVar:GetString() or "default"

    for r = -1, ROLE_MAX do
        local c = nil
        if mode == "custom" then
            if r == ROLE_DETECTIVE then c = ColorFromCustomConVars("ttt_custom_det_color") or COLOR_DETECTIVE["default"]
            elseif DETECTIVE_ROLES[r] then c = ColorFromCustomConVars("ttt_custom_spec_det_color") or COLOR_SPECIAL_DETECTIVE["default"]
            elseif r == ROLE_INNOCENT then c = ColorFromCustomConVars("ttt_custom_inn_color") or COLOR_INNOCENT["default"]
            elseif INNOCENT_ROLES[r] then c = ColorFromCustomConVars("ttt_custom_spec_inn_color") or COLOR_SPECIAL_INNOCENT["default"]
            elseif r == ROLE_TRAITOR then c = ColorFromCustomConVars("ttt_custom_tra_color") or COLOR_TRAITOR["default"]
            elseif TRAITOR_ROLES[r] then c = ColorFromCustomConVars("ttt_custom_spec_tra_color") or COLOR_SPECIAL_TRAITOR["default"]
            elseif JESTER_ROLES[r] then c = ColorFromCustomConVars("ttt_custom_jes_color") or COLOR_JESTER["default"]
            elseif INDEPENDENT_ROLES[r] then c = ColorFromCustomConVars("ttt_custom_ind_color") or COLOR_INDEPENDENT["default"]
            elseif MONSTER_ROLES[r] then c = ColorFromCustomConVars("ttt_custom_mon_color") or COLOR_MONSTER["default"]
            end
        else
            if r == ROLE_DETECTIVE then c = COLOR_DETECTIVE[mode]
            elseif DETECTIVE_ROLES[r] then c = COLOR_SPECIAL_DETECTIVE[mode]
            elseif r == ROLE_INNOCENT then c = COLOR_INNOCENT[mode]
            elseif INNOCENT_ROLES[r] then c = COLOR_SPECIAL_INNOCENT[mode]
            elseif r == ROLE_TRAITOR then c = COLOR_TRAITOR[mode]
            elseif TRAITOR_ROLES[r] then c = COLOR_SPECIAL_TRAITOR[mode]
            elseif JESTER_ROLES[r] then c = COLOR_JESTER[mode]
            elseif INDEPENDENT_ROLES[r] then c = COLOR_INDEPENDENT[mode]
            elseif MONSTER_ROLES[r] then c = COLOR_MONSTER[mode]
            end
        end

        list[r] = ModifyColor(c or COLOR_WHITE, type)
    end
end

if CLIENT then
    function GetRoleTeamColor(role_team, type)
        local modeCVar = GetConVar("ttt_color_mode")
        local mode = modeCVar and modeCVar:GetString() or "default"
        local c = nil
        if mode == "custom" then
            if role_team == ROLE_TEAM_DETECTIVE then c = ColorFromCustomConVars("ttt_custom_spec_det_color") or COLOR_SPECIAL_DETECTIVE["default"]
            elseif role_team == ROLE_TEAM_INNOCENT then c = ColorFromCustomConVars("ttt_custom_spec_inn_color") or COLOR_SPECIAL_INNOCENT["default"]
            elseif role_team == ROLE_TEAM_TRAITOR then c = ColorFromCustomConVars("ttt_custom_spec_tra_color") or COLOR_SPECIAL_TRAITOR["default"]
            elseif role_team == ROLE_TEAM_JESTER then c = ColorFromCustomConVars("ttt_custom_jes_color") or COLOR_JESTER["default"]
            elseif role_team == ROLE_TEAM_INDEPENDENT then c = ColorFromCustomConVars("ttt_custom_ind_color") or COLOR_INDEPENDENT["default"]
            elseif role_team == ROLE_TEAM_MONSTER then c = ColorFromCustomConVars("ttt_custom_mon_color") or COLOR_MONSTER["default"]
            end
        else
            if role_team == ROLE_TEAM_DETECTIVE then c = COLOR_SPECIAL_DETECTIVE[mode]
            elseif role_team == ROLE_TEAM_INNOCENT then c = COLOR_SPECIAL_INNOCENT[mode]
            elseif role_team == ROLE_TEAM_TRAITOR then c = COLOR_SPECIAL_TRAITOR[mode]
            elseif role_team == ROLE_TEAM_JESTER then c = COLOR_JESTER[mode]
            elseif role_team == ROLE_TEAM_INDEPENDENT then c = COLOR_INDEPENDENT[mode]
            elseif role_team == ROLE_TEAM_MONSTER then c = COLOR_MONSTER[mode]
            end
        end

        return ModifyColor(c or COLOR_WHITE, type)
    end
else
    function CreateCreditConVar(role)
        -- Add explicit ROLE_INNOCENT exclusion here in case shop-for-all is enabled
        if not DEFAULT_ROLES[role] or role == ROLE_INNOCENT then
            local rolestring = ROLE_STRINGS_RAW[role]
            local credits = "0"
            if ROLE_STARTING_CREDITS[role] then credits = ROLE_STARTING_CREDITS[role]
            elseif TRAITOR_ROLES[role] then credits = "1"
            elseif DETECTIVE_ROLES[role] then credits = "1"
            elseif role == ROLE_MERCENARY then credits = "1"
            elseif role == ROLE_DOCTOR then credits = "1" end
            CreateConVar("ttt_" .. rolestring .. "_credits_starting", credits, FCVAR_REPLICATED)
        end
    end

    function CreateShopConVars(role)
        local rolestring = ROLE_STRINGS_RAW[role]
        CreateCreditConVar(role)

        CreateConVar("ttt_" .. rolestring .. "_shop_random_percent", "0", FCVAR_REPLICATED, "The percent chance that a weapon in the shop will not be shown for the " .. rolestring, 0, 100)
        CreateConVar("ttt_" .. rolestring .. "_shop_random_enabled", "0", FCVAR_REPLICATED, "Whether shop randomization should run for the " .. rolestring)

        if (TRAITOR_ROLES[role] and role ~= ROLE_TRAITOR) or (DETECTIVE_ROLES[role] and role ~= ROLE_DETECTIVE) or role == ROLE_ZOMBIE then -- This all happens before we run UpdateRoleState so we need to manually add zombies
            CreateConVar("ttt_" .. rolestring .. "_shop_sync", "0", FCVAR_REPLICATED)
        end

        if role == ROLE_MERCENARY then
            CreateConVar("ttt_" .. rolestring .. "_shop_mode", "2", FCVAR_REPLICATED)
        elseif (INDEPENDENT_ROLES[role] and role ~= ROLE_ZOMBIE) or DELAYED_SHOP_ROLES[role] then
            CreateConVar("ttt_" .. rolestring .. "_shop_mode", "0", FCVAR_REPLICATED)
        end

        if DELAYED_SHOP_ROLES[role] then
            CreateConVar("ttt_" .. rolestring .. "_shop_active_only", "1")
            CreateConVar("ttt_" .. rolestring .. "_shop_delay", "0")
        end
    end

    function SyncShopConVars(role)
        local rolestring = ROLE_STRINGS_RAW[role]
        SetGlobalInt("ttt_" .. rolestring .. "_shop_random_percent", GetConVar("ttt_" .. rolestring .. "_shop_random_percent"):GetInt())
        SetGlobalBool("ttt_" .. rolestring .. "_shop_random_enabled", GetConVar("ttt_" .. rolestring .. "_shop_random_enabled"):GetBool())

        local sync_cvar = "ttt_" .. rolestring .. "_shop_sync"
        if ConVarExists(sync_cvar) then
            SetGlobalBool(sync_cvar, GetConVar(sync_cvar):GetBool())
        end

        local mode_cvar = "ttt_" .. rolestring .. "_shop_mode"
        if ConVarExists(mode_cvar) then
            SetGlobalInt(mode_cvar, GetConVar(mode_cvar):GetInt())
        end

        if DELAYED_SHOP_ROLES[role] then
            SetGlobalBool("ttt_" .. rolestring .. "_shop_active_only", GetConVar("ttt_" .. rolestring .. "_shop_active_only"):GetBool())
            SetGlobalBool("ttt_" .. rolestring .. "_shop_delay", GetConVar("ttt_" .. rolestring .. "_shop_delay"):GetBool())
        end
    end
end

ROLE_COLORS = {}
ROLE_COLORS_DARK = {}
ROLE_COLORS_HIGHLIGHT = {}
ROLE_COLORS_SCOREBOARD = {}
ROLE_COLORS_SPRITE = {}
ROLE_COLORS_RADAR = {}

function UpdateRoleColours()
    ROLE_COLORS = {}
    FillRoleColors(ROLE_COLORS)
    ROLE_COLOURS = ROLE_COLORS

    ROLE_COLORS_DARK = {}
    FillRoleColors(ROLE_COLORS_DARK, "dark")
    ROLE_COLOURS_DARK = ROLE_COLORS_DARK

    ROLE_COLORS_HIGHLIGHT = {}
    FillRoleColors(ROLE_COLORS_HIGHLIGHT, "highlight")
    ROLE_COLOURS_HIGHLIGHT = ROLE_COLORS_HIGHLIGHT

    ROLE_COLORS_SCOREBOARD = {}
    FillRoleColors(ROLE_COLORS_SCOREBOARD, "scoreboard")
    ROLE_COLOURS_SCOREBOARD = ROLE_COLORS_SCOREBOARD

    ROLE_COLORS_SPRITE = {}
    FillRoleColors(ROLE_COLORS_SPRITE, "sprite")
    ROLE_COLOURS_SPRITE = ROLE_COLORS_SPRITE

    ROLE_COLORS_RADAR = {}
    FillRoleColors(ROLE_COLORS_RADAR, "radar")
    ROLE_COLOURS_RADAR = ROLE_COLORS_RADAR
end
UpdateRoleColours()

-- Role strings
ROLE_STRINGS_RAW = {
    [ROLE_INNOCENT] = "innocent",
    [ROLE_TRAITOR] = "traitor",
    [ROLE_DETECTIVE] = "detective",
    [ROLE_JESTER] = "jester",
    [ROLE_SWAPPER] = "swapper",
    [ROLE_GLITCH] = "glitch",
    [ROLE_PHANTOM] = "phantom",
    [ROLE_HYPNOTIST] = "hypnotist",
    [ROLE_REVENGER] = "revenger",
    [ROLE_DRUNK] = "drunk",
    [ROLE_CLOWN] = "clown",
    [ROLE_DEPUTY] = "deputy",
    [ROLE_IMPERSONATOR] = "impersonator",
    [ROLE_BEGGAR] = "beggar",
    [ROLE_OLDMAN] = "oldman",
    [ROLE_MERCENARY] = "mercenary",
    [ROLE_BODYSNATCHER] = "bodysnatcher",
    [ROLE_VETERAN] = "veteran",
    [ROLE_ASSASSIN] = "assassin",
    [ROLE_KILLER] = "killer",
    [ROLE_ZOMBIE] = "zombie",
    [ROLE_VAMPIRE] = "vampire",
    [ROLE_DOCTOR] = "doctor",
    [ROLE_QUACK] = "quack",
    [ROLE_PARASITE] = "parasite",
    [ROLE_TRICKSTER] = "trickster",
    [ROLE_PARAMEDIC] = "paramedic",
    [ROLE_MADSCIENTIST] = "madscientist",
    [ROLE_PALADIN] = "paladin",
    [ROLE_TRACKER] = "tracker",
    [ROLE_MEDIUM] = "medium"
}

ROLE_STRINGS = {
    [ROLE_INNOCENT] = "Innocent",
    [ROLE_TRAITOR] = "Traitor",
    [ROLE_DETECTIVE] = "Detective",
    [ROLE_JESTER] = "Jester",
    [ROLE_SWAPPER] = "Swapper",
    [ROLE_GLITCH] = "Glitch",
    [ROLE_PHANTOM] = "Phantom",
    [ROLE_HYPNOTIST] = "Hypnotist",
    [ROLE_REVENGER] = "Revenger",
    [ROLE_DRUNK] = "Drunk",
    [ROLE_CLOWN] = "Clown",
    [ROLE_DEPUTY] = "Deputy",
    [ROLE_IMPERSONATOR] = "Impersonator",
    [ROLE_BEGGAR] = "Beggar",
    [ROLE_OLDMAN] = "Old Man",
    [ROLE_MERCENARY] = "Mercenary",
    [ROLE_BODYSNATCHER] = "Bodysnatcher",
    [ROLE_VETERAN] = "Veteran",
    [ROLE_ASSASSIN] = "Assassin",
    [ROLE_KILLER] = "Killer",
    [ROLE_ZOMBIE] = "Zombie",
    [ROLE_VAMPIRE] = "Vampire",
    [ROLE_DOCTOR] = "Doctor",
    [ROLE_QUACK] = "Quack",
    [ROLE_PARASITE] = "Parasite",
    [ROLE_TRICKSTER] = "Trickster",
    [ROLE_PARAMEDIC] = "Paramedic",
    [ROLE_MADSCIENTIST] = "Mad Scientist",
    [ROLE_PALADIN] = "Paladin",
    [ROLE_TRACKER] = "Tracker",
    [ROLE_MEDIUM] = "Medium"
}

ROLE_STRINGS_PLURAL = {
    [ROLE_INNOCENT] = "Innocents",
    [ROLE_TRAITOR] = "Traitors",
    [ROLE_DETECTIVE] = "Detectives",
    [ROLE_JESTER] = "Jesters",
    [ROLE_SWAPPER] = "Swappers",
    [ROLE_GLITCH] = "Glitches",
    [ROLE_PHANTOM] = "Phantoms",
    [ROLE_HYPNOTIST] = "Hypnotists",
    [ROLE_REVENGER] = "Revengers",
    [ROLE_DRUNK] = "Drunks",
    [ROLE_CLOWN] = "Clowns",
    [ROLE_DEPUTY] = "Deputies",
    [ROLE_IMPERSONATOR] = "Impersonators",
    [ROLE_BEGGAR] = "Beggars",
    [ROLE_OLDMAN] = "Old Men",
    [ROLE_MERCENARY] = "Mercenaries",
    [ROLE_BODYSNATCHER] = "Bodysnatchers",
    [ROLE_VETERAN] = "Veterans",
    [ROLE_ASSASSIN] = "Assassins",
    [ROLE_KILLER] = "Killers",
    [ROLE_ZOMBIE] = "Zombies",
    [ROLE_VAMPIRE] = "Vampires",
    [ROLE_DOCTOR] = "Doctors",
    [ROLE_QUACK] = "Quacks",
    [ROLE_PARASITE] = "Parasites",
    [ROLE_TRICKSTER] = "Tricksters",
    [ROLE_PARAMEDIC] = "Paramedics",
    [ROLE_MADSCIENTIST] = "Mad Scientists",
    [ROLE_PALADIN] = "Paladins",
    [ROLE_TRACKER] = "Trackers",
    [ROLE_MEDIUM] = "Mediums"
}

ROLE_STRINGS_EXT = {
    [ROLE_NONE] = "a hidden role",
    [ROLE_INNOCENT] = "an Innocent",
    [ROLE_TRAITOR] = "a Traitor",
    [ROLE_DETECTIVE] = "a Detective",
    [ROLE_JESTER] = "a Jester",
    [ROLE_SWAPPER] = "a Swapper",
    [ROLE_GLITCH] = "a Glitch",
    [ROLE_PHANTOM] = "a Phantom",
    [ROLE_HYPNOTIST] = "a Hypnotist",
    [ROLE_REVENGER] = "a Revenger",
    [ROLE_DRUNK] = "a Drunk",
    [ROLE_CLOWN] = "a Clown",
    [ROLE_DEPUTY] = "a Deputy",
    [ROLE_IMPERSONATOR] = "an Impersonator",
    [ROLE_BEGGAR] = "a Beggar",
    [ROLE_OLDMAN] = "an Old Man",
    [ROLE_MERCENARY] = "a Mercenary",
    [ROLE_BODYSNATCHER] = "a Bodysnatcher",
    [ROLE_VETERAN] = "a Veteran",
    [ROLE_ASSASSIN] = "an Assassin",
    [ROLE_KILLER] = "a Killer",
    [ROLE_ZOMBIE] = "a Zombie",
    [ROLE_VAMPIRE] = "a Vampire",
    [ROLE_DOCTOR] = "a Doctor",
    [ROLE_QUACK] = "a Quack",
    [ROLE_PARASITE] = "a Parasite",
    [ROLE_TRICKSTER] = "a Trickster",
    [ROLE_PARAMEDIC] = "a Paramedic",
    [ROLE_MADSCIENTIST] = "a Mad Scientist",
    [ROLE_PALADIN] = "a Paladin",
    [ROLE_TRACKER] = "a Tracker",
    [ROLE_MEDIUM] = "a Medium"
}

ROLE_STRINGS_SHORT = {
    [ROLE_INNOCENT] = "inn",
    [ROLE_TRAITOR] = "tra",
    [ROLE_DETECTIVE] = "det",
    [ROLE_JESTER] = "jes",
    [ROLE_SWAPPER] = "swa",
    [ROLE_GLITCH] = "gli",
    [ROLE_PHANTOM] = "pha",
    [ROLE_HYPNOTIST] = "hyp",
    [ROLE_REVENGER] = "rev",
    [ROLE_DRUNK] = "dru",
    [ROLE_CLOWN] = "clo",
    [ROLE_DEPUTY] = "dep",
    [ROLE_IMPERSONATOR] = "imp",
    [ROLE_BEGGAR] = "beg",
    [ROLE_OLDMAN] = "old",
    [ROLE_MERCENARY] = "mer",
    [ROLE_BODYSNATCHER] = "bod",
    [ROLE_VETERAN] = "vet",
    [ROLE_ASSASSIN] = "asn",
    [ROLE_KILLER] = "kil",
    [ROLE_ZOMBIE] = "zom",
    [ROLE_VAMPIRE] = "vam",
    [ROLE_DOCTOR] = "doc",
    [ROLE_QUACK] = "qua",
    [ROLE_PARASITE] = "par",
    [ROLE_TRICKSTER] = "tri",
    [ROLE_PARAMEDIC] = "med",
    [ROLE_MADSCIENTIST] = "mad",
    [ROLE_PALADIN] = "pal",
    [ROLE_TRACKER] = "trk",
    [ROLE_MEDIUM] = "mdm"
}

function StartsWithVowel(word)
    local firstletter = string.sub(word, 1, 1)
    return firstletter == "a" or
        firstletter == "e" or
        firstletter == "i" or
        firstletter == "o" or
        firstletter == "u"
end

function UpdateRoleStrings()
    for role = 0, ROLE_MAX do
        local name = GetGlobalString("ttt_" .. ROLE_STRINGS_RAW[role] .. "_name", "")
        if name ~= "" then
            ROLE_STRINGS[role] = name

            local plural = GetGlobalString("ttt_" .. ROLE_STRINGS_RAW[role] .. "_name_plural", "")
            if plural == "" then -- Fallback if no plural is given. Does NOT handle all cases properly
                local lastChar = string.sub(name, name:len(), name:len()):lower()
                if lastChar == "s" then
                    ROLE_STRINGS_PLURAL[role] = name .. "es"
                elseif lastChar == "y" then
                    ROLE_STRINGS_PLURAL[role] = string.sub(name, 1, name:len() - 1) .. "ies"
                else
                    ROLE_STRINGS_PLURAL[role] = name .. "s"
                end
            else
                ROLE_STRINGS_PLURAL[role] = plural
            end

            local article = GetGlobalString("ttt_" .. ROLE_STRINGS_RAW[role] .. "_name_article", "")
            if article == "" then -- Fallback if no article is given. Does NOT handle all cases properly
                if StartsWithVowel(name) then
                    ROLE_STRINGS_EXT[role] = "an " .. name
                else
                    ROLE_STRINGS_EXT[role] = "a " .. name
                end
            else
                ROLE_STRINGS_EXT[role] = article .. " " .. name
            end
        end
    end
end
if CLIENT then net.Receive("TTT_UpdateRoleNames", UpdateRoleStrings) end

ROLE_TEAM_INNOCENT = 0
ROLE_TEAM_TRAITOR = 1
ROLE_TEAM_JESTER = 2
ROLE_TEAM_INDEPENDENT = 3
ROLE_TEAM_MONSTER = 4
ROLE_TEAM_DETECTIVE = 5

ROLE_TRANSLATIONS = {}
ROLE_SHOP_ITEMS = {}
ROLE_LOADOUT_ITEMS = {}
ROLE_CONVARS = {}
ROLE_STARTING_CREDITS = {}
ROLE_STARTING_HEALTH = {}
ROLE_MAX_HEALTH = {}
ROLE_IS_ACTIVE = {}
ROLE_SHOULD_ACT_LIKE_JESTER = {}

ROLE_CONVAR_TYPE_NUM = 0
ROLE_CONVAR_TYPE_BOOL = 1
ROLE_CONVAR_TYPE_TEXT = 2

function RegisterRole(tbl)
    -- Unsigned 8-bit max
    local maximum_role_count = (2^7) - 1
    if ROLE_MAX == maximum_role_count then
        error("Too many roles (more than " .. maximum_role_count .. ") have been defined.")
        return
    end

    if table.HasValue(ROLE_STRINGS_RAW, tbl.nameraw) then
        error("Attempting to define role with a duplicate raw name value: " .. tbl.nameraw)
        return
    end

    if table.HasValue(ROLE_STRINGS_SHORT, tbl.nameshort) then
        error("Attempting to define role with a duplicate short name value: " .. tbl.nameshort)
        return
    end

    local roleID = ROLE_MAX + 1
    _G["ROLE_" .. string.upper(tbl.nameraw)] = roleID
    ROLE_MAX = roleID

    ROLE_STRINGS_RAW[roleID] = tbl.nameraw
    ROLE_STRINGS[roleID] = tbl.name
    ROLE_STRINGS_PLURAL[roleID] = tbl.nameplural
    ROLE_STRINGS_EXT[roleID] = tbl.nameext
    ROLE_STRINGS_SHORT[roleID] = tbl.nameshort

    if tbl.team == ROLE_TEAM_INNOCENT then
        AddRoleAssociations(INNOCENT_ROLES, {roleID})
    elseif tbl.team == ROLE_TEAM_TRAITOR then
        AddRoleAssociations(TRAITOR_ROLES, {roleID})
    elseif tbl.team == ROLE_TEAM_JESTER then
        AddRoleAssociations(JESTER_ROLES, {roleID})
    elseif tbl.team == ROLE_TEAM_INDEPENDENT then
        AddRoleAssociations(INDEPENDENT_ROLES, {roleID})
    elseif tbl.team == ROLE_TEAM_MONSTER then
        AddRoleAssociations(MONSTER_ROLES, {roleID})
    elseif tbl.team == ROLE_TEAM_DETECTIVE then
        AddRoleAssociations(DETECTIVE_ROLES, {roleID})
        AddRoleAssociations(INNOCENT_ROLES, {roleID})
    end

    -- Allow roles to have translations automatically added for them
    if type(tbl.translations) == "table" then
        ROLE_TRANSLATIONS[roleID] = tbl.translations
    else
        ROLE_TRANSLATIONS[roleID] = {}
    end

    -- Ensure that at least english is present
    if not ROLE_TRANSLATIONS[roleID]["english"] then
        ROLE_TRANSLATIONS[roleID]["english"] = {}
    end

    -- Create the role description translation automatically
    ROLE_TRANSLATIONS[roleID]["english"]["info_popup_" .. tbl.nameraw] = tbl.desc

    if tbl.shop then
        ROLE_SHOP_ITEMS[roleID] = tbl.shop
        AddRoleAssociations(SHOP_ROLES, {roleID})
    end

    if type(tbl.startingcredits) == "number" then
        ROLE_STARTING_CREDITS[roleID] = tbl.startingcredits
    end

    if type(tbl.startinghealth) == "number" then
        ROLE_STARTING_HEALTH[roleID] = tbl.startinghealth
    end

    if type(tbl.maxhealth) == "number" then
        ROLE_MAX_HEALTH[roleID] = tbl.maxhealth
    end

    if type(tbl.canlootcredits) == "boolean" then
        CAN_LOOT_CREDITS_ROLES[roleID] = tbl.canlootcredits
    end

    if type(tbl.canusetraitorbuttons) == "boolean" then
        TRAITOR_BUTTON_ROLES[roleID] = tbl.canusetraitorbuttons
    end

    if type(tbl.shoulddelayshop) == "boolean" then
        DELAYED_SHOP_ROLES[roleID] = tbl.shoulddelayshop
    end

    if tbl.loadout then
        ROLE_LOADOUT_ITEMS[roleID] = tbl.loadout
    end

    if type(tbl.isactive) == "function" then
        ROLE_IS_ACTIVE[roleID] = tbl.isactive
    end

    if type(tbl.shouldactlikejester) == "function" then
        ROLE_SHOULD_ACT_LIKE_JESTER[roleID] = tbl.shouldactlikejester
    end

    -- List of objects that describe convars for ULX support, in the following format:
    -- {
    --     cvar = "ttt_test_slider",    -- The name of the convar
    --     decimal = 2,                 -- How many decimal places this number will use
    --     type = ROLE_CONVAR_TYPE_NUM  -- The type of convar (will be used to determine the control, in this case a number slider)
    -- },
    -- {
    --     cvar = "ttt_test_checkbox",  -- The name of the convar
    --     type = ROLE_CONVAR_TYPE_BOOL -- The type of convar (will be used to determine the control, in this case a checkbox)
    -- },
    -- {
    --     cvar = "ttt_test_textbox",   -- The name of the convar
    --     type = ROLE_CONVAR_TYPE_TEXT -- The type of convar (will be used to determine the control, in this case a textbox)
    -- }
    if tbl.convars then
        ROLE_CONVARS[roleID] = tbl.convars
    end
end

local function AddInternalRoles()
    local root = "terrortown/gamemode/roles/"
    local _, dirs = file.Find(root .. "*", "LUA")
    for _, dir in ipairs(dirs) do
        local files, _ = file.Find(root .. dir .. "/*.lua", "LUA")
        for _, fil in ipairs(files) do
            local isClientFile = string.find(fil, "cl_")
            local isSharedFile = fil == "shared.lua" or string.find(fil, "sh_")

            if SERVER then
                -- Send client and shared files to clients
                if isClientFile or isSharedFile then AddCSLuaFile(root .. dir .. "/" .. fil) end
                -- Include non-client files
                if not isClientFile then include(root .. dir .. "/" .. fil) end
            end
            -- Include client and shared files
            if CLIENT and (isClientFile or isSharedFile) then include(root .. dir .. "/" .. fil) end
        end
    end
end
AddInternalRoles()

local function AddExternalRoles()
    local files, _ = file.Find("customroles/*.lua", "LUA")
    for _, fil in ipairs(files) do
        if SERVER then AddCSLuaFile("customroles/" .. fil) end
        include("customroles/" .. fil)
    end
end
AddExternalRoles()

-- Game event log defs
EVENT_KILL = 1
EVENT_SPAWN = 2
EVENT_GAME = 3
EVENT_FINISH = 4
EVENT_SELECTED = 5
EVENT_BODYFOUND = 6
EVENT_C4PLANT = 7
EVENT_C4EXPLODE = 8
EVENT_CREDITFOUND = 9
EVENT_C4DISARM = 10
EVENT_HYPNOTISED = 11
EVENT_DEFIBRILLATED = 12
EVENT_DISCONNECTED = 13
EVENT_ROLECHANGE = 14
EVENT_SWAPPER = 15
EVENT_PROMOTION = 16
EVENT_CLOWNACTIVE = 17
EVENT_DRUNKSOBER = 18
EVENT_HAUNT = 19
EVENT_BODYSNATCH = 20
EVENT_LOG = 21
EVENT_ZOMBIFIED = 22
EVENT_VAMPIFIED = 23
EVENT_VAMPPRIME_DEATH = 24
EVENT_BEGGARCONVERTED = 25
EVENT_BEGGARKILLED = 26
EVENT_INFECT = 27

-- Don't redefine this every time we load this file
if not EVENT_MAX then
    EVENT_MAX = 27
end

function GenerateNewEventID()
    EVENT_MAX = EVENT_MAX + 1
    return EVENT_MAX
end

WIN_NONE = 1
WIN_TRAITOR = 2
WIN_INNOCENT = 3
WIN_TIMELIMIT = 4
WIN_JESTER = 5
WIN_CLOWN = 6
WIN_OLDMAN = 7
WIN_KILLER = 8
WIN_ZOMBIE = 9
WIN_MONSTER = 10
WIN_VAMPIRE = 11

-- Don't redefine this every time we load this file
if not WIN_MAX then
    WIN_MAX = 11
end

function GenerateNewWinID()
    WIN_MAX = WIN_MAX + 1
    return WIN_MAX
end

-- Weapon categories, you can only carry one of each
WEAPON_NONE = 0
WEAPON_MELEE = 1
WEAPON_PISTOL = 2
WEAPON_HEAVY = 3
WEAPON_NADE = 4
WEAPON_CARRY = 5
WEAPON_EQUIP1 = 6
WEAPON_EQUIP2 = 7
WEAPON_ROLE = 8

WEAPON_EQUIP = WEAPON_EQUIP1
WEAPON_UNARMED = -1

WEAPON_CATEGORY_ROLE = "CR-RoleWeapon"

-- Kill types discerned by last words
KILL_NORMAL = 0
KILL_SUICIDE = 1
KILL_FALL = 2
KILL_BURN = 3

-- Entity types a crowbar might open
OPEN_NO = 0
OPEN_DOOR = 1
OPEN_ROT = 2
OPEN_BUT = 3
OPEN_NOTOGGLE = 4 --movelinear

-- Mute types
MUTE_NONE = 0
MUTE_TERROR = 1
MUTE_ALL = 2
MUTE_SPEC = 1002

-- Jester notify modes
JESTER_NOTIFY_DETECTIVE_AND_TRAITOR = 1
JESTER_NOTIFY_TRAITOR = 2
JESTER_NOTIFY_DETECTIVE = 3
JESTER_NOTIFY_EVERYONE = 4

-- Vampire prime death modes
VAMPIRE_DEATH_NONE = 0
VAMPIRE_DEATH_KILL_CONVERED = 1
VAMPIRE_DEATH_REVERT_CONVERTED = 2

-- Parasite respawn modes
PARASITE_RESPAWN_HOST = 0
PARASITE_RESPAWN_BODY = 1
PARASITE_RESPAWN_RANDOM = 2

-- Parasite infection suicide respawn modes
PARASITE_SUICIDE_NONE = 0
PARASITE_SUICIDE_RESPAWN_ALL = 1
PARASITE_SUICIDE_RESPAWN_CONSOLE = 2

-- Swapper weapon modes
SWAPPER_WEAPON_NONE = 0
SWAPPER_WEAPON_ROLE = 1
SWAPPER_WEAPON_ALL = 2

-- Glitch modes
GLITCH_SHOW_AS_TRAITOR = 0
GLITCH_SHOW_AS_SPECIAL_TRAITOR = 1
GLITCH_HIDE_SPECIAL_TRAITOR_ROLES = 2

-- Beggar reveal modes
BEGGAR_REVEAL_NONE = 0
BEGGAR_REVEAL_ALL = 1
BEGGAR_REVEAL_TRAITORS = 2
BEGGAR_REVEAL_INNOCENTS = 3

-- Bodysnatcher reveal modes
BODYSNATCHER_REVEAL_NONE = 0
BODYSNATCHER_REVEAL_ALL = 1
BODYSNATCHER_REVEAL_TEAM = 2

COLOR_WHITE = Color(255, 255, 255, 255)
COLOR_BLACK = Color(0, 0, 0, 255)
COLOR_GREEN = Color(0, 255, 0, 255)
COLOR_DGREEN = Color(0, 100, 0, 255)
COLOR_RED = Color(255, 0, 0, 255)
COLOR_YELLOW = Color(200, 200, 0, 255)
COLOR_LGRAY = Color(200, 200, 200, 255)
COLOR_BLUE = Color(0, 0, 255, 255)
COLOR_NAVY = Color(0, 0, 100, 255)
COLOR_PINK = Color(255, 0, 255, 255)
COLOR_ORANGE = Color(250, 100, 0, 255)
COLOR_OLIVE = Color(100, 100, 0, 255)

include("util.lua")
include("lang_shd.lua") -- uses some of util
include("equip_items_shd.lua")

function DetectiveMode() return GetGlobalBool("ttt_detective", false) end
function HasteMode() return GetGlobalBool("ttt_haste", false) end

-- Create teams
TEAM_TERROR = 1
TEAM_SPEC = TEAM_SPECTATOR

function GM:CreateTeams()
    team.SetUp(TEAM_TERROR, "Terrorists", Color(0, 200, 0, 255), false)
    team.SetUp(TEAM_SPEC, "Spectators", Color(200, 200, 0, 255), true)

    -- Not that we use this, but feels good
    team.SetSpawnPoint(TEAM_TERROR, "info_player_deathmatch")
    team.SetSpawnPoint(TEAM_SPEC, "info_player_deathmatch")
end

-- Everyone's model
local ttt_playermodels = {
    Model("models/player/phoenix.mdl"),
    Model("models/player/arctic.mdl"),
    Model("models/player/guerilla.mdl"),
    Model("models/player/leet.mdl")
};

function GetRandomPlayerModel()
    return table.Random(ttt_playermodels)
end

local ttt_playercolors = {
    all = {
        COLOR_WHITE,
        COLOR_BLACK,
        COLOR_GREEN,
        COLOR_DGREEN,
        COLOR_RED,
        COLOR_YELLOW,
        COLOR_LGRAY,
        COLOR_BLUE,
        COLOR_NAVY,
        COLOR_PINK,
        COLOR_OLIVE,
        COLOR_ORANGE
    },

    serious = {
        COLOR_WHITE,
        COLOR_BLACK,
        COLOR_NAVY,
        COLOR_LGRAY,
        COLOR_DGREEN,
        COLOR_OLIVE
    }
};

CreateConVar("ttt_playercolor_mode", "1")
function GM:TTTPlayerColor(model)
    local mode = GetConVar("ttt_playercolor_mode"):GetInt()
    if mode == 1 then
        return table.Random(ttt_playercolors.serious)
    elseif mode == 2 then
        return table.Random(ttt_playercolors.all)
    elseif mode == 3 then
        -- Full randomness
        return Color(math.random(0, 255), math.random(0, 255), math.random(0, 255))
    end
    -- No coloring
    return COLOR_WHITE
end

function GM:PlayerFootstep(ply, pos, foot, sound, volume, rf)
    if not IsValid(ply) or ply:IsSpec() or not ply:Alive() then return true end

    if SERVER and ply:WaterLevel() == 0 then
        -- This player killed a Phantom. Tell everyone where their foot steps should go
        local phantom_killer_footstep_time = GetConVar("ttt_phantom_killer_footstep_time"):GetInt()
        local tracker_footstep_time = GetConVar("ttt_tracker_footstep_time"):GetInt()
        if phantom_killer_footstep_time > 0 and ply:GetNWBool("Haunted", false) then
            net.Start("TTT_PlayerFootstep")
            net.WriteEntity(ply)
            net.WriteVector(pos)
            net.WriteAngle(ply:GetAimVector():Angle())
            net.WriteBit(foot)
            net.WriteTable(Color(138, 4, 4))
            net.WriteUInt(phantom_killer_footstep_time, 8)
            net.Broadcast()
        elseif tracker_footstep_time > 0 and not ply:IsTracker() then
            net.Start("TTT_PlayerFootstep")
            net.WriteEntity(ply)
            net.WriteVector(pos)
            net.WriteAngle(ply:GetAimVector():Angle())
            net.WriteBit(foot)
            local col = Vector(1, 1, 1)
            if GetConVar("ttt_tracker_footstep_color"):GetBool() then
                col = ply:GetNWVector("PlayerColor", Vector(1, 1, 1))
            end
            net.WriteTable(Color(col.x * 255, col.y * 255, col.z * 255))
            net.WriteUInt(tracker_footstep_time, 8)
            local tab = {}
            for k, p in pairs(player.GetAll()) do
                if p:IsActiveTracker() then
                    table.insert(tab, p)
                end
            end
            net.Send(tab)
        end
    end

    -- Kill footsteps on player and client
    if ply:Crouching() or ply:GetMaxSpeed() < 150 then
        -- do not play anything, just prevent normal sounds from playing
        return true
    end

    if hook.Run("TTTBlockPlayerFootstepSound", ply) then
        return true
    end
end

-- Predicted move speed changes
function GM:Move(ply, mv)
    if ply:IsTerror() then
        local basemul = 1
        local slowed = false
        -- Slow down ironsighters
        local wep = ply:GetActiveWeapon()
        if IsValid(wep) and wep.GetIronsights and wep:GetIronsights() then
            basemul = 120 / 220
            slowed = true
        end
        local mul = hook.Call("TTTPlayerSpeedModifier", GAMEMODE, ply, slowed, mv) or 1
        mul = basemul * mul
        mv:SetMaxClientSpeed(mv:GetMaxClientSpeed() * mul)
        mv:SetMaxSpeed(mv:GetMaxSpeed() * mul)
    end
end

function GetSprintMultiplier(ply, sprinting)
    local mult = 1
    if IsValid(ply) then
        local mults = {}
        hook.Run("TTTSpeedMultiplier", ply, mults)
        for _, m in pairs(mults) do
            mult = mult * m
        end

        if sprinting and ply.mult then
            mult = mult * ply.mult
        end

        local wep = ply:GetActiveWeapon()
        if IsValid(wep) then
            local weaponClass = wep:GetClass()
            if weaponClass == "genji_melee" then
                return 1.4 * mult
            elseif weaponClass == "weapon_ttt_homebat" then
                return 1.25 * mult
            elseif weaponClass == "weapon_vam_fangs" and wep:Clip1() < 15 then
                return 3 * mult
            elseif weaponClass == "weapon_zom_claws" then
                local speed_bonus = 1
                if ply:IsZombiePrime() then
                    speed_bonus = speed_bonus + GetGlobalFloat("ttt_zombie_prime_speed_bonus", 0.35)
                else
                    speed_bonus = speed_bonus + GetGlobalFloat("ttt_zombie_thrall_speed_bonus", 0.15)
                end

                if ply:HasEquipmentItem(EQUIP_SPEED) then
                    speed_bonus = speed_bonus + 0.15
                end
                return speed_bonus * mult
            end
        end
    end

    return mult
end

function UpdateRoleWeaponState()
    -- If the parasite is not enabled, don't let anyone buy the cure
    local parasite_cure = weapons.GetStored("weapon_par_cure")
    local fake_cure = weapons.GetStored("weapon_qua_fake_cure")
    if GetGlobalBool("ttt_parasite_enabled", false) then
        parasite_cure.CanBuy = table.Copy(parasite_cure.CanBuyDefault)
        fake_cure.CanBuy = table.Copy(fake_cure.CanBuyDefault)
    else
        table.Empty(parasite_cure.CanBuy)
        table.Empty(fake_cure.CanBuy)
    end

    -- Hypnotist
    local hypnotist_defib = weapons.GetStored("weapon_hyp_brainwash")
    if GetGlobalBool("ttt_hypnotist_device_loadout", false) then
        hypnotist_defib.InLoadoutFor = table.Copy(hypnotist_defib.InLoadoutForDefault)
    else
        table.Empty(hypnotist_defib.InLoadoutFor)
    end
    if GetGlobalBool("ttt_hypnotist_device_shop", false) then
        hypnotist_defib.CanBuy = {ROLE_HYPNOTIST}
    else
        hypnotist_defib.CanBuy = nil
    end

    -- Paramedic
    local paramedic_defib = weapons.GetStored("weapon_med_defib")
    if GetGlobalBool("ttt_paramedic_device_loadout", false) then
        paramedic_defib.InLoadoutFor = table.Copy(paramedic_defib.InLoadoutForDefault)
    else
        table.Empty(paramedic_defib.InLoadoutFor)
    end
    if GetGlobalBool("ttt_paramedic_device_shop", false) then
        paramedic_defib.CanBuy = {ROLE_PARAMEDIC}
    else
        paramedic_defib.CanBuy = nil
    end

    -- Phantom
    local phantom_device = weapons.GetStored("weapon_pha_exorcism")
    local phantom_device_roles = {}
    if GetGlobalBool("ttt_traitor_phantom_cure", false) then
        table.insert(phantom_device_roles, ROLE_TRAITOR)
    end
    if GetGlobalBool("ttt_quack_phantom_cure", false) then
        table.insert(phantom_device_roles, ROLE_QUACK)
    end

    if #phantom_device_roles > 0 then
        phantom_device.CanBuy = phantom_device_roles
    else
        table.Empty(phantom_device.CanBuy)
    end

    if SERVER then
        net.Start("TTT_ResetBuyableWeaponsCache")
        net.Broadcast()
    end
end

function UpdateRoleState()
    local zombies_are_monsters = GetGlobalBool("ttt_zombies_are_monsters", false)
    -- Zombies cannot be both Monsters and Traitors so don't make them Traitors if they are already Monsters
    local zombies_are_traitors = not zombies_are_monsters and GetGlobalBool("ttt_zombies_are_traitors", false)
    MONSTER_ROLES[ROLE_ZOMBIE] = zombies_are_monsters
    TRAITOR_ROLES[ROLE_ZOMBIE] = zombies_are_traitors
    INDEPENDENT_ROLES[ROLE_ZOMBIE] = not zombies_are_monsters and not zombies_are_traitors

    local vampires_are_monsters = GetGlobalBool("ttt_vampires_are_monsters", false)
    -- Vampires cannot be both Monsters and Independents so don't make them Independents if they are already Monsters
    local vampires_are_independent = not vampires_are_monsters and GetGlobalBool("ttt_vampires_are_independent", false)
    MONSTER_ROLES[ROLE_VAMPIRE] = vampires_are_monsters
    TRAITOR_ROLES[ROLE_VAMPIRE] = not vampires_are_monsters and not vampires_are_independent
    INDEPENDENT_ROLES[ROLE_VAMPIRE] = vampires_are_independent

    local bodysnatchers_are_independent = GetGlobalBool("ttt_bodysnatchers_are_independent", false)
    INDEPENDENT_ROLES[ROLE_BODYSNATCHER] = bodysnatchers_are_independent
    JESTER_ROLES[ROLE_BODYSNATCHER] = not bodysnatchers_are_independent

    -- Role Features
    local glitch_use_traps = GetGlobalBool("ttt_glitch_use_traps", false)
    CAN_LOOT_CREDITS_ROLES[ROLE_GLITCH] = glitch_use_traps
    TRAITOR_BUTTON_ROLES[ROLE_GLITCH] = glitch_use_traps

    local disable_looting = GetGlobalBool("ttt_detective_disable_looting", false)
    for r, e in pairs(DETECTIVE_ROLES) do
        if e then
            CAN_LOOT_CREDITS_ROLES[r] = not disable_looting
        end
    end

    -- Update role colors to make sure team changes have taken effect
    UpdateRoleColours()

    -- Update which weapons are available based on role state
    UpdateRoleWeaponState()

    -- Enable the shop for all roles if configured to do so
    if GetGlobalBool("ttt_shop_for_all", false) then
        for role = 0, ROLE_MAX do
            if not SHOP_ROLES[role] then
                SHOP_ROLES[role] = true
            end
        end
    end

    hook.Run("TTTUpdateRoleState")
end

function GetWinningMonsterRole()
    local monsters = GetTeamRoles(MONSTER_ROLES)
    local monster = monsters[1]
    -- If Zombies or Vampires just won on a team by themselves, use their role as the label
    if #monsters == 1 and (monster == ROLE_ZOMBIE or monster == ROLE_VAMPIRE) then
        return monster
    end
    -- Otherwise just use the "Monsters" team name
    return nil
end

function ShouldHideJesters(p)
    -- TODO: Remove this in the next beta release after 1.2.5 is released to non-beta
    ErrorNoHaltWithStack("WARNING: ShouldHideJesters(ply) is deprecated. Please switch to ply:ShouldHideJesters()")
    return p:ShouldHideJesters()
end

if SERVER then
    -- Centralize this so it can be handled on round start and on player death
    function AssignAssassinTarget(ply, start, delay)
        -- Don't let dead players, spectators, non-assassins, or failed assassins get another target
        -- And don't assign targets if the round isn't currently running
        if not IsValid(ply) or GetRoundState() > ROUND_ACTIVE or
            not ply:IsAssassin() or ply:GetNWBool("AssassinFailed", false)
        then
            return
        end

        -- Reset the target to empty in case there are no valid targets
        ply:SetNWString("AssassinTarget", "")

        local enemies = {}
        local shops = {}
        local detectives = {}
        local independents = {}
        local beggarMode = GetConVar("ttt_beggar_reveal_innocent"):GetInt()
        local shopRolesFirst = GetConVar("ttt_assassin_shop_roles_last"):GetBool()
        local bodysnatcherModeInno = GetConVar("ttt_bodysnatcher_reveal_innocent"):GetInt()
        local bodysnatcherModeMon = GetConVar("ttt_bodysnatcher_reveal_monster"):GetInt()
        local bodysnatcherModeIndep = GetConVar("ttt_bodysnatcher_reveal_independent"):GetInt()

        local function AddEnemy(p, bodysnatcherMode)
            -- Don't add the former beggar to the list of enemies unless the "reveal" setting is enabled
            if p:IsInnocent() and p:GetNWBool("WasBeggar", false) and beggarMode ~= BEGGAR_REVEAL_ALL and beggarMode ~= BEGGAR_REVEAL_TRAITORS then return end
            if p:GetNWBool("WasBodysnatcher", false) and bodysnatcherMode ~= BODYSNATCHER_REVEAL_ALL then return end

            -- Put shop roles into a list if they should be targeted last
            if shopRolesFirst and p:IsShopRole() then
                table.insert(shops, p:Nick())
            else
                table.insert(enemies, p:Nick())
            end
        end

        for _, p in pairs(player.GetAll()) do
            if p:Alive() and not p:IsSpec() then
                if p:IsDetectiveTeam() then
                    table.insert(detectives, p:Nick())
                -- Exclude Glitch from these lists so they don't get discovered immediately
                elseif p:IsInnocentTeam() and not p:IsGlitch() then
                    AddEnemy(p, bodysnatcherModeInno)
                elseif p:IsMonsterTeam() and not p:IsGlitch() then
                    AddEnemy(p, bodysnatcherModeMon)
                -- Exclude the Old Man because they just want to survive
                elseif p:IsIndependentTeam() and not p:IsOldMan() then
                    -- Also exclude bodysnatchers turned into an independent if their role hasn't been revealed
                    if not p:GetNWBool("WasBodysnatcher", false) or bodysnatcherModeIndep == BODYSNATCHER_REVEAL_ALL then
                        table.insert(independents, p:Nick())
                    end
                end
            end
        end

        local target = nil
        if #enemies > 0 then
            target = enemies[math.random(#enemies)]
        elseif #shops > 0 then
            target = shops[math.random(#shops)]
        elseif #detectives > 0 then
            target = detectives[math.random(#detectives)]
        elseif #independents > 0 then
            target = independents[math.random(#independents)]
        end

        local targetMessage = ""
        if target ~= nil then
            ply:SetNWString("AssassinTarget", target)

            local targets = #enemies + #shops + #detectives + #independents
            local targetCount
            if targets > 1 then
                targetCount = start and "first" or "next"
            elseif targets == 1 then
                targetCount = "final"
            end
            targetMessage = "Your " .. targetCount .. " target is " .. target .. "."
        else
            targetMessage = "No further targets available."
        end

        if ply:Alive() and not ply:IsSpec() then
            if not delay and not start then targetMessage = "Target eliminated. " .. targetMessage end
            ply:PrintMessage(HUD_PRINTCENTER, targetMessage)
            ply:PrintMessage(HUD_PRINTTALK, targetMessage)
        end
    end

    function SetRoleStartingHealth(ply)
        if not IsValid(ply) or not ply:Alive() or ply:IsSpec() then return end
        local role = ply:GetRole()
        if role <= ROLE_NONE or role > ROLE_MAX then return end

        local health = GetConVar("ttt_" .. ROLE_STRINGS_RAW[role] .. "_starting_health"):GetInt()
        ply:SetHealth(health)
    end

    function SetRoleMaxHealth(ply)
        if not IsValid(ply) or not ply:Alive() or ply:IsSpec() then return end
        local role = ply:GetRole()
        if role <= ROLE_NONE or role > ROLE_MAX then return end

        local maxhealth = GetConVar("ttt_" .. ROLE_STRINGS_RAW[role] .. "_max_health"):GetInt()
        ply:SetMaxHealth(maxhealth)
    end

    function SetRoleHealth(ply)
        SetRoleMaxHealth(ply)
        SetRoleStartingHealth(ply)
    end

    function ShouldPromoteDetectiveLike()
        local alive, dead = 0, 0
        for _, p in ipairs(player.GetAll()) do
            if p:IsDetectiveTeam() then
                if not p:IsSpec() and p:Alive() then
                    alive = alive + 1
                else
                    dead = dead + 1
                end
            end
        end

        -- If they should be promoted when any detective has died, just check that there is a dead detective
        if GetConVar("ttt_deputy_impersonator_promote_any_death"):GetBool() then
            return dead > 0
        end

        -- Otherwise, only promote if there are no living detectives
        return alive == 0
    end
end

-- Weapons and items that come with TTT. Weapons that are not in this list will
-- get a little marker on their icon if they're buyable, showing they are custom
-- and unique to the server.
DefaultEquipment = {
    -- traitor-buyable by default
    [ROLE_TRAITOR] = {
        "weapon_ttt_c4",
        "weapon_ttt_flaregun",
        "weapon_ttt_knife",
        "weapon_ttt_phammer",
        "weapon_ttt_push",
        "weapon_ttt_radio",
        "weapon_ttt_sipistol",
        "weapon_ttt_teleport",
        "weapon_ttt_decoy",
        "weapon_pha_exorcism",
        EQUIP_ARMOR,
        EQUIP_RADAR,
        EQUIP_DISGUISE
    },

    -- detective-buyable by default
    [ROLE_DETECTIVE] = {
        "weapon_ttt_binoculars",
        "weapon_ttt_defuser",
        "weapon_ttt_health_station",
        "weapon_ttt_stungun",
        "weapon_ttt_cse",
        "weapon_ttt_teleport",
        EQUIP_ARMOR,
        EQUIP_RADAR
    },

    [ROLE_MERCENARY] = {
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
        EQUIP_ARMOR,
        EQUIP_RADAR
    },

    [ROLE_HYPNOTIST] = {
        "weapon_hyp_brainwash",
        EQUIP_ARMOR,
        EQUIP_RADAR,
        EQUIP_DISGUISE
    },

    [ROLE_IMPERSONATOR] = {
        EQUIP_ARMOR,
        EQUIP_RADAR,
        EQUIP_DISGUISE
    },

    [ROLE_ASSASSIN] = {
        EQUIP_ARMOR,
        EQUIP_RADAR,
        EQUIP_DISGUISE
    },

    [ROLE_ZOMBIE] = {
        EQUIP_ARMOR,
        EQUIP_RADAR,
        EQUIP_DISGUISE,
        EQUIP_SPEED,
        EQUIP_REGEN
    },

    [ROLE_VAMPIRE] = {
        EQUIP_ARMOR,
        EQUIP_RADAR,
        EQUIP_DISGUISE
    },

    [ROLE_QUACK] = {
        "weapon_ttt_health_station",
        "weapon_par_cure",
        "weapon_pha_exorcism",
        "weapon_qua_bomb_station",
        "weapon_qua_fake_cure",
        EQUIP_ARMOR,
        EQUIP_RADAR,
        EQUIP_DISGUISE
    },

    [ROLE_PARASITE] = {
        EQUIP_ARMOR,
        EQUIP_RADAR,
        EQUIP_DISGUISE
    },

    [ROLE_DOCTOR] = {
        "weapon_ttt_health_station",
        "weapon_par_cure",
        "weapon_qua_fake_cure"
    },

    [ROLE_PARAMEDIC] = {
        "weapon_med_defib"
    },

    -- non-buyable
    [ROLE_NONE] = {
        "weapon_ttt_confgrenade",
        "weapon_ttt_m16",
        "weapon_ttt_smokegrenade",
        "weapon_ttt_unarmed",
        "weapon_ttt_wtester",
        "weapon_tttbase",
        "weapon_tttbasegrenade",
        "weapon_zm_carry",
        "weapon_zm_improvised",
        "weapon_zm_mac10",
        "weapon_zm_molotov",
        "weapon_zm_pistol",
        "weapon_zm_revolver",
        "weapon_zm_rifle",
        "weapon_zm_shotgun",
        "weapon_zm_sledge",
        "weapon_ttt_glock"
    }
};
