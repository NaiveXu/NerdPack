local _, NeP = ...

local GUI = {

}

local exeOnLoad = function()

end

local exeOnUnload = function()

end

local Keybinds = {
	{'%pause', 'keybind(alt)'}
}

local Interrupts = {

}

local inCombat = {
	{Keybinds},
	{Interrupts, 'interruptAt(43)&.infront&range<=8', 'target'},
    {'Moonfire', '!debuff', 'target'},
    {'Sunfire', '!debuff', 'target'},
    {'Stellar Flare', '!debuff', 'target'},
    {'Solar Wrath', nil, 'target'},
}

local outCombat = {
	{Keybinds},
}

NeP.CR:Add(102, {
	name = '[NeP] Druid | Balance',
	wow_ver = "8.3",
	nep_ver = "1.3",
	ic = inCombat,
	ooc = outCombat,
	gui = GUI,
	load = exeOnLoad,
	unload = exeOnUnload,
	pooling = false,
})
