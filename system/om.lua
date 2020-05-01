local _, NeP = ...

NeP.OM = {
	Memory = {},
	Enemy = {},
	Friendly = {},
	Dead = {},
	Objects = {},
	AreaTriggers = {},
	Critters = {},
	Roster = {},
	max_distance = 100
}

local function MergeTable_Insert(table, Obj, GUID)
	if not table[GUID]
	and NeP.DSL:Get('exists')(Obj.key)
	and NeP._G.UnitInPhase(Obj.key)
	and GUID == NeP.Protected.ObjectGUID(Obj.key) then
		table[GUID] = Obj
		Obj.range = NeP.DSL:Get('range')(Obj.key)
		Obj.distance = NeP.DSL:Get('distance')(Obj.key)
	end
end

local function MergeTable(ref)
	local temp = {}
	for GUID, Obj in pairs(NeP.OM[ref]) do
		MergeTable_Insert(temp, Obj, GUID)
	end
	for GUID, Obj in pairs(NeP.Protected.nPlates[ref]) do
		MergeTable_Insert(temp, Obj, GUID)
	end
	return temp
end

function NeP.OM.Get(_, ref, want_plates)
	if want_plates
	and NeP.Protected.nPlates
	and NeP.Protected.nPlates[ref] then
		return MergeTable(ref)
	end
	return NeP.OM[ref]
end

local forced_role = {
	[72218] = "TANK" -- Oto the Protector (Proving Grounds)
}

function NeP.OM.UpdateObject(_, ref, GUID)
	local Obj = NeP.OM[ref][GUID]
	Obj.distance = NeP.DSL:Get('distance')(Obj.key)
end

function NeP.OM.UpdateUnit(_, ref, GUID)
	local Obj = NeP.OM[ref][GUID]
	Obj.distance = NeP.DSL:Get('distance')(Obj.key)
	Obj.range = NeP.DSL:Get('range')(Obj.key)
	Obj.predicted = NeP.Healing.GetPredictedHealth_Percent(Obj.key)
	Obj.predicted_Raw = NeP.Healing.GetPredictedHealth(Obj.key)
	Obj.health = NeP.Healing.healthPercent(Obj.key)
	Obj.healthRaw = NeP._G.UnitHealth(Obj.key)
	Obj.healthMax = NeP.DSL:Get('health.max')(Obj.key)
	Obj.role = forced_role[Obj.id] or NeP.DSL:Get('role')(Obj.key)
end

local function preLoadBuffs(Obj)
	local i, sName, count, type, duration, expiration, caster, isStealable, spellId, isBoss, sGUID, data = 1, true
	while sName do
		sName, _, count, type, duration, expiration, caster, isStealable,_,spellId,_, isBoss = NeP._G.UnitBuff(Obj.key, i)
		if sName then
			sGUID = caster and NeP._G.UnitGUID(caster) or ''
			data = {
				isCastByPlayer = sGUID == NeP._G.UnitGUID('player'),
				sGUID = sGUID,
				spellId = spellId,
				sName = sName,
				auraType = 'BUFF',
				type = type,
				count = count,
				isStealable = isStealable,
				isBoss = isBoss,
				expiration = expiration,
				duration = duration,
				caster = caster,
			}
			Obj.buffs[sName] = data
			Obj.buffs[spellId] = data
			i=i+1
		end
	end
end

local function preLoadDebuffs(Obj)
	local i, sName, count, type, duration, expiration, caster, isStealable, spellId, isBoss, sGUID, data = 1, true
	while sName do
		sName, _, count, type, duration, expiration, caster, isStealable,_,spellId,_, isBoss = NeP._G.UnitDebuff(Obj.key, i)
		if sName then
			sGUID = caster and NeP._G.UnitGUID(caster) or ''
			data = {
				isCastByPlayer = sGUID == NeP._G.UnitGUID('player'),
				sGUID = sGUID,
				spellId = spellId,
				sName = sName,
				auraType = 'DEBUFF',
				type = type,
				count = count,
				isStealable = isStealable,
				isBoss = isBoss,
				expiration = expiration,
				duration = duration,
				caster = caster,
			}
			Obj.debuffs[sName] = data
			Obj.debuffs[spellId] = data
			i=i+1
		end
	end
end

function NeP.OM.InsertObject(_, ref, Obj)
	local GUID = NeP.Protected.ObjectGUID(Obj)
	if GUID then
		if NeP.OM[ref][GUID] then
			NeP.OM:UpdateObject(ref, GUID)
			return
		end
		--restore a unit
		if NeP.OM.Memory[GUID] then
			NeP.OM[ref][GUID] = NeP.OM.Memory[GUID]
			local xobj = NeP.OM[ref][GUID]
			xobj.key = Obj
			xobj.tbl = ref
			NeP.OM:UpdateObject(ref, GUID)
			return
		end
		local distance = NeP.DSL:Get('distance')(Obj) or 999
		if distance > NeP.OM.max_distance then
			NeP.OM[ref][GUID] = nil
			return
		end
		local ObjID = select(6, NeP._G.strsplit('-', GUID))
		NeP.OM[ref][GUID] = {
			key = Obj,
			name = NeP.DSL:Get('name')(Obj),
			distance = distance,
			id = tonumber(ObjID or 0),
			guid = GUID,
			tbl = ref,
			--buffs
			buffs = {},
			debuffs = {},
		}
		NeP.OM.Memory[GUID] = data
	end
end

-- they are the same for now, but i might need to change latter.
NeP.OM.InsertCritter = NeP.OM.InsertObject

function NeP.OM.Insert(_, ref, Obj)
	local GUID = NeP.Protected.ObjectGUID(Obj)
	if GUID then
		if NeP.OM[ref][GUID] then
			NeP.OM:UpdateUnit(ref, GUID)
			return
		end
		--restore a unit
		if NeP.OM.Memory[GUID] then
			NeP.OM[ref][GUID] = NeP.OM.Memory[GUID]
			local xobj = NeP.OM[ref][GUID]
			xobj.key = Obj
			xobj.tbl = ref
			wipe(xobj.buffs)
			wipe(xobj.debuffs)
			NeP.OM:UpdateObject(ref, GUID)
			preLoadBuffs(xobj)
			preLoadDebuffs(xobj)
			return
		end
		local range = NeP.DSL:Get('range')(Obj) or 999
		if range > NeP.OM.max_distance then
			NeP.OM[ref][GUID] = nil
			return
		end
		if not NeP.DSL:Get('los')(Obj) then
			return
		end
		local ObjID = select(6, NeP._G.strsplit('-', GUID))
		local data = {
			key = Obj,
			name = NeP.DSL:Get('name')(Obj),
			distance = NeP.DSL:Get('distance')(Obj),
			range = range,
			id = tonumber(ObjID or 0),
			guid = GUID,
			isdummy = NeP.DSL:Get('isdummy')(Obj),
			tbl = ref,
			--healing
			predicted = NeP.Healing.GetPredictedHealth_Percent(Obj),
			predicted_Raw = NeP.Healing.GetPredictedHealth(Obj),
			health = NeP.Healing.healthPercent(Obj),
			healthRaw = NeP.DSL:Get('health.actual')(Obj),
			healthMax = NeP.DSL:Get('health.max')(Obj),
			role = forced_role[ObjID] or NeP.DSL:Get('role')(Obj),
			combat_tack_enable = true,
			-- Damage Taken
			dmgTaken = 0,
			dmgTaken_P = 0,
			dmgTaken_M = 0,
			hits_taken = 0,
			lastHit_taken = 0,
			-- Damage Done
			dmgDone = 0,
			dmgDone_P = 0,
			dmgDone_M = 0,
			hits_done = 0,
			lastHit_done = 0,
			-- Healing taken
			heal_taken = 0,
			heal_hits_taken = 0,
			-- Healing Done
			heal_done = 0,
			heal_hits_done = 0,
			--shared
			last_hit_taken_time = 0,
			last_hit_done_time = 0,
			combat_time = 0,
			spell_value = {},
			--buffs
			buffs = {},
			debuffs = {},
		}
		preLoadBuffs(data)
		preLoadDebuffs(data)
		NeP.OM[ref][GUID] = data
		NeP.OM.Memory[GUID] = data
	end
end

local critters ={
	["Non-combat Pet"]=true,
	["Wild Pet"]=true,
	["Critter"]=true,
	["Totem"]=true
  }

function NeP.OM.Add(_, Obj, isObject, isAreaTrigger)
	-- Objects
	if isObject then
		NeP.OM:InsertObject('Objects', Obj)
	elseif isAreaTrigger then
		NeP.OM:InsertObject('AreaTriggers', Obj)
	-- Units
	elseif NeP.DSL:Get("exists")(Obj)
	and NeP._G.UnitInPhase(Obj) then
		-- Critters
		if critters[NeP._G.UnitCreatureType(Obj)] then
			NeP.OM:InsertCritter('Critters', Obj)
		-- Units
		elseif NeP._G.UnitIsDeadOrGhost(Obj) then
			NeP.OM:Insert('Dead', Obj)
		elseif NeP._G.UnitIsFriend('player', Obj) then
			NeP.OM:Insert('Friendly', Obj)
		elseif NeP._G.UnitCanAttack('player', Obj) then
			NeP.OM:Insert('Enemy', Obj)
		end
	end
end

local function cleanObjects()
	for _, ref in pairs({"Objects", "AreaTriggers"}) do
		for GUID, Obj in pairs(NeP.OM[ref]) do
			if Obj.distance > NeP.OM.max_distance
			or not NeP.DSL:Get('exists')(Obj.key)
			or GUID ~= NeP.Protected.ObjectGUID(Obj.key) then
				NeP.OM.Objects[GUID] = nil
			end
		end
	end
end

local function cleanCritters(ref)
	for GUID, Obj in pairs(NeP.OM[ref]) do
		-- remove invalid units
		if Obj.distance > NeP.OM.max_distance
		or not NeP.DSL:Get('exists')(Obj.key)
		or not NeP._G.UnitInPhase(Obj.key)
		or GUID ~= NeP.Protected.ObjectGUID(Obj.key) then
			NeP.OM[ref][GUID] = nil
		end
	end
end

local function cleanOthers(ref)
	local ctime = NeP._G.GetTime()
	for GUID, Obj in pairs(NeP.OM[ref]) do
		-- remove invalid units
		if Obj.range > NeP.OM.max_distance
		or not NeP.DSL:Get('exists')(Obj.key)
		or not NeP._G.UnitInPhase(Obj.key)
		or GUID ~= NeP.Protected.ObjectGUID(Obj.key)
		or not NeP.DSL:Get('los')(Obj.key)
		or ref ~= 'Dead' and NeP._G.UnitIsDeadOrGhost(Obj.key)
		or ref == 'Dead' and not NeP._G.UnitIsDeadOrGhost(Obj.key) then
			NeP.OM[ref][GUID] = nil
		-- check stuff
		else
			if (ctime - Obj.last_hit_taken_time) > 15
			and (ctime - Obj.last_hit_done_time) > 15 then
				Obj.combat_time = 0
				Obj.dmgTaken = 0
				Obj.dmgTaken_P = 0
				Obj.dmgTaken_M = 0
				Obj.hits_taken = 0
				Obj.lastHit_taken = 0
				Obj.dmgDone = 0
				Obj.dmgDone_P = 0
				Obj.dmgDone_M = 0
				Obj.hits_done = 0
				Obj.lastHit_done = 0
				Obj.heal_taken = 0
				Obj.heal_hits_taken = 0
				Obj.heal_done = 0
				Obj.heal_hits_done = 0
				Obj.last_hit_taken_time = 0
				Obj.last_hit_done_time = 0
			end
		end
	end
end

local function CleanStart()
	if NeP.DSL:Get("toggle")(nil, "mastertoggle") then
		cleanObjects()
		cleanOthers("Dead")
		cleanOthers("Friendly")
		cleanOthers("Enemy")
		cleanCritters("Critters")
	else
		NeP._G.wipe(NeP.OM['Objects'])
		NeP._G.wipe(NeP.OM['AreaTriggers'])
		NeP._G.wipe(NeP.OM['Dead'])
		NeP._G.wipe(NeP.OM['Friendly'])
		NeP._G.wipe(NeP.OM['Enemy'])
		NeP._G.wipe(NeP.OM['Critters'])
	end
end

local function MakerStart()
	if NeP.DSL:Get("toggle")(nil, "mastertoggle") then
		NeP.Protected:OM_Maker()
	end
end

function NeP.OM.FindObjectByGuid(_, guid)
	return NeP.OM.Memory[guid]
end

function NeP.OM.RemoveObjectByGuid(_, guid)
	local Obj = NeP.OM:FindObjectByGuid(guid)
	if not Obj then return end
	NeP.OM[Obj.tbl][Obj.guid] = nil
end

NeP.Debug:Add("OM_Clean", CleanStart, true)
NeP.Debug:Add("OM_Maker", MakerStart, true)

NeP._G.C_Timer.NewTicker(0.5, CleanStart)
NeP._G.C_Timer.NewTicker(1, MakerStart)
