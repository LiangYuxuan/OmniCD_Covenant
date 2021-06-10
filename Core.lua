local addon, Engine = ...
local OC = LibStub('AceAddon-3.0'):NewAddon(addon, 'AceEvent-3.0')
local E = LibStub("AceAddon-3.0"):GetAddon('OmniCD')
local P = E.Party

Engine.Core = OC
_G[addon] = Engine

local DETAILS_COVENANTS = 'DCOribos'
local ZENTRACKER = 'ZenTracker'
local EXRT = 'EXRTADD'

local utilityMap = {
    [324739] = 1,
    [300728] = 2,
    [310143] = 3,
    [324631] = 4,
}

local abilityMap = {
    ['DEATHKNIGHT'] = {
        [315443] = 4,
        [312202] = 1,
        [311648] = 2,
        [324128] = 3,
    },
    ['DEMONHUNTER'] = {
        [306830] = 1,
        [329554] = 4,
        [323639] = 3,
        [317009] = 2,
    },
    ['DRUID'] = {
        [338142] = 1,
        [326462] = 1,
        [326446] = 1,
        [338035] = 1,
        [338018] = 1,
        [338411] = 1,
        [326434] = 1,
        [325727] = 4,
        [323764] = 3,
        [323546] = 2,
    },
    ['HUNTER'] = {
        [308491] = 1,
        [325028] = 4,
        [328231] = 3,
        [324149] = 2,
    },
    ['MAGE'] = {
        [307443] = 1,
        [324220] = 4,
        [314791] = 3,
        [314793] = 2,
    },
    ['MONK'] = {
        [310454] = 1,
        [325216] = 4,
        [327104] = 3,
        [326860] = 2,
    },
    ['PALADIN'] = {
        [304971] = 1,
        [328204] = 4,
        [328282] = 3,
        [328620] = 3,
        [328622] = 3,
        [328281] = 3,
        [316958] = 2,
    },
    ['PRIEST'] = {
        [325013] = 1,
        [324724] = 4,
        [327661] = 3,
        [323673] = 2,
    },
    ['ROGUE'] = {
        [323547] = 1,
        [328547] = 4,
        [328305] = 3,
        [323654] = 2,
    },
    ['SHAMAN'] = {
        [324519] = 1,
        [324386] = 1,
        [326059] = 4,
        [328923] = 3,
        [320674] = 2,
    },
    ['WARLOCK'] = {
        [312321] = 1,
        [325289] = 4,
        [325640] = 3,
        [321792] = 2,
    },
    ['WARRIOR'] = {
        [307865] = 1,
        [324143] = 4,
        [325886] = 3,
        [330334] = 2,
        [317349] = 2,
        [317488] = 2,
        [330325] = 2,
    },
}

local function OnInspectUnit(_, unitGUID)
    if not OC.covenantMap[unitGUID] then return end

    local info = P.groupInfo[unitGUID]
    if not info or info.shadowlandsData.covenantID then return end

    OC:ApplyCovenant(unitGUID, OC.covenantMap[unitGUID])
end

function OC:ApplyCovenant(unitGUID, covenantID)
    self.covenantMap[unitGUID] = covenantID

    local info = P.groupInfo[unitGUID]
    if not info then return end

    local spellID = E.covenant_IDToSpellID[covenantID]
    if spellID then
        info.shadowlandsData.covenantID = spellID
        info.talentData[spellID] = 'C'

        P:UpdateUnitBar(unitGUID)
    end
end

function OC:CHAT_MSG_ADDON(_, prefix, text, _, sender)
    local unitName = strsplit('-', sender)
    if unitName == E.userName then return end

    if prefix == DETAILS_COVENANTS then
        local playerName, covenantID = strsplit(':', text)
        covenantID = covenantID and tonumber(covenantID)
        if playerName == 'ASK' or not covenantID then return end

        local unitGUID = UnitGUID(sender) or UnitGUID(unitName)
        if not unitGUID then return end

        self:ApplyCovenant(unitGUID, covenantID)
    elseif prefix == ZENTRACKER then
        local version, type, unitGUID, _, _, _, _, covenantID = strsplit(':', text)
        covenantID = covenantID and tonumber(covenantID)
        if version ~= '4' or type ~= 'H' or not unitGUID or not covenantID then return end

        self:ApplyCovenant(unitGUID, covenantID)
    elseif prefix == EXRT then
        if not strmatch(text, '^inspect\tR\t') then return end

        local covenantID = strmatch(text, '%^S:(%d+):') or strmatch(text, '^inspect\tR\tS:(%d+):')
        covenantID = covenantID and tonumber(covenantID)
        if not covenantID then return end

        local unitGUID = UnitGUID(sender) or UnitGUID(unitName)
        if not unitGUID then return end

        self:ApplyCovenant(unitGUID, covenantID)
    end
end

do
    local IN_GROUP = bit.bor(COMBATLOG_OBJECT_AFFILIATION_RAID, COMBATLOG_OBJECT_AFFILIATION_PARTY)

    function OC:COMBAT_LOG_EVENT_UNFILTERED()
        local _, subEvent, _, sourceGUID, sourceName, sourceFlags, _, _, _, _, _, spellID = CombatLogGetCurrentEventInfo()
        if (
            subEvent ~= 'SPELL_CAST_SUCCESS' or not sourceGUID or not sourceName or
            sourceGUID == E.userGUID or bit.band(sourceFlags, IN_GROUP) == 0
        ) then return end

        local classFilename = select(2, UnitClass(sourceName))
        local covenantID =
            (classFilename and abilityMap[classFilename] and abilityMap[classFilename][spellID]) or utilityMap[spellID]

        if covenantID then
            self:ApplyCovenant(sourceGUID, covenantID)
        end
    end
end

function OC:OnInitialize()
    self.covenantMap = {}

    self:RegisterEvent('CHAT_MSG_ADDON')
    self:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED')

    hooksecurefunc(E.Comms, 'InspectUnit', OnInspectUnit)

    C_ChatInfo.RegisterAddonMessagePrefix(DETAILS_COVENANTS)
    C_ChatInfo.RegisterAddonMessagePrefix(ZENTRACKER)
    C_ChatInfo.RegisterAddonMessagePrefix(EXRT)
end
