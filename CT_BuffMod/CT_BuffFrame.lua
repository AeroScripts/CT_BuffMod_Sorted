CT_AddMovable("CT_BuffMod_Drag", CT_BUFFMOD_MOVABLE_BUFFBAR, "BOTTOMLEFT", "BOTTOMLEFT", "MinimapCluster", 10, -20, function(status)
	if ( status ) then
		CT_BuffMod_Drag:Show()
	else
		CT_BuffMod_Drag:Hide();
	end
end, BuffModResetFunction);

CT_ExpireBuffs = { };
CT_MaxTime = { };
CT_BuffNames = { };
CT_LastExpiredBuffs = { };
CT_PlaySound = 0;
CT_SoundPlayed = false;
local CT_UsingTooltip = 0;

CT_BuffMod_BuffSides = "RIGHT";

CT_ShowDuration = 1;
CT_ShowExpire = 1;
CT_ShowRed = 0;
CT_BuffScale = 1;

DebuffTypeColor = { };
DebuffTypeColor["none"]	= { r = 0.50, g = 0, b = 0.50 };
DebuffTypeColor["Magic"]	= { r = 0.20, g = 0.60, b = 1.00 };
DebuffTypeColor["Curse"]	= { r = 0.60, g = 0.00, b = 1.00 };
DebuffTypeColor["Disease"]	= { r = 0.60, g = 0.40, b = 0 };
DebuffTypeColor["Poison"]	= { r = 0.00, g = 0.60, b = 0 };

-- Buffs not to recast
CT_BuffMod_NoRecastBuffs = {
	["Mind Control"] = 1
};

function CT_BuffFrame_OnLoad()
	MinBuffDurationExpireMessage = 51; 							-- Never display an expire message if the buff duration is less than this.
	ExpireMessageTime = 15;												-- How long before the buff expires to display the expire message.
	ExpireMessageColors = { };
	ExpireMessageColors["r"] = 1.0;
	ExpireMessageColors["g"] = 0.0;
	ExpireMessageColors["b"] = 0.0;
	ExpireMessageFrame = DEFAULT_CHAT_FRAME; 		-- The frame in which to display the expire message.

	BuffStartFlashTime = 15;													-- How long before the buff expires to start flashing.
	BuffFlashOn = 0.75;															-- How long to flash.
	BuffFlashOff = 0.75;															-- How long between each flash.
	BuffMinOpacity = 0.30;														-- Minimum level of opacity.

	BuffFlashState = 0;
	BuffFlashTime = 0;
	BuffFlashUpdateTime = 0;
	BuffFrame:Hide();
	CT_BuffFrame:Show();
end

function SetMinMaxBarInfo(button)
	local buffname = CT_GetBuffName("player", button:GetID(), this.buffFilter);
	local timebar = getglobal(button:GetName() .. "BuffStatusBar");
	local maxTime;
			
	if (buffname) then
		local storedMaxTime = CT_MaxTime[buffname]
		if (storedMaxTime and storedMaxTime ~= 0) then
			maxTime = storedMaxTime;
		else
			local buffIndex, untilCancelled = GetPlayerBuff(this:GetID(), this.buffFilter);
			local timeLeft = GetPlayerBuffTimeLeft(buffIndex);
			CT_MaxTime[buffname] = timeLeft;
			maxTime = timeLeft;
		end
		timebar:SetMinMaxValues(0, maxTime);
	end
end

function DeleteStoredBuffInfo(buffname)
	if (buffname) then
		CT_MaxTime[buffname] = 0;
	end
end

local FIRSTRUN = true;

function CT_BuffFrame_OnUpdate(elapsed)
	if FIRSTRUN then
		CT_BuffMod_Drag:Show();
		FIRSTRUN = false;
	end
	local count = 0;
	for i=0, 23 do
		local button = getglobal("CT_BuffButton"..i);
		if (button:IsVisible()) then
			count = count + 1;
		-- ADDED BY SCAMP
		else
			--__AE_CT_DURATIONTABLE[i] = nil; -- bad code is bad
		end
		-- END ADDED BY SCAMP
	end

	if ( BuffFlashUpdateTime > 0 ) then
		BuffFlashUpdateTime = BuffFlashUpdateTime - elapsed;
	else
		BuffFlashUpdateTime = BuffFlashUpdateTime + TOOLTIP_UPDATE_TIME;
	end

	BuffFlashTime = BuffFlashTime - elapsed;

	if ( BuffFlashTime < 0 ) then
		local overtime = -BuffFlashTime;
		if ( BuffFlashState == 1 ) then
			BuffFlashState = 0;
			BuffFlashTime = BuffFlashOff;
		else
			BuffFlashState = 1;
			BuffFlashTime = BuffFlashOn;
		end
		if ( overtime < BuffFlashTime ) then
			BuffFlashTime = BuffFlashTime - overtime;
		end
	end
	-- ADDED BY SCAMP
	__AE_CT_CHECKSORT();
	-- END ADDED BY SCAMP
end

function CT_BuffIsDebuff(id)
	for z=0, 23, 1 do
		local dbIndex, dbTemp = GetPlayerBuff(z, "HARMFUL");
		if ( dbIndex == -1 ) then return 0; end

		if ( dbIndex == id ) then
			return 1;
		end
	end
	return 0;
end

function CT_GetBuffType(unit, i, filter)
	local filter;
	if ( not filt ) then
		filter = "HELPFUL|HARMFUL";
	else
		filter = filt;
	end

	getglobal("BDTooltipTextLeft1"):SetText("");
	getglobal("BDTooltipTextRight1"):SetText("");
	getglobal(this:GetName().."BuffTypeText"):SetText("");

	local buffIndex, untilCancelled = GetPlayerBuff(i, filter);
	local buff;

	if (buffIndex < 24) then
		buff = buffIndex;
		if (buff == -1) then
			buff = nil;
		end
	end

	if (buff) then
		local tooltip = BDTooltip;
		tooltip:SetOwner(UIParent, "ANCHOR_NONE");
		if (unit == "player" and tooltip ) then
			tooltip:SetPlayerBuff(buffIndex);
		end

		local toolTipText = getglobal("BDTooltipTextRight1");
		if (toolTipText) then
			local name = toolTipText:GetText();
			if ( name ~= nil ) then
				return name;
			end
		end
	end
	return nil;
end

function CT_GetBuffName(unit, i, filt)
	CT_UsingTooltip = 1;
	local filter;
	if ( not filt ) then
		filter = "HELPFUL|HARMFUL";
	else
		filter = filt;
	end
	local buffIndex, untilCancelled = GetPlayerBuff(i, filter);
	local buff;

	if ( buffIndex < 24 ) then
		buff = buffIndex;
		if (buff == -1) then
			buff = nil;
		end
	end

	if (buff) then
		local tooltip = BTooltip;
		if (unit == "player" and tooltip ) then
			tooltip:SetPlayerBuff(buffIndex);
		end
		local tooltiptext = getglobal("BTooltipTextLeft1");
		if ( tooltiptext ) then
			local name = tooltiptext:GetText();
			if ( name ~= nil ) then
				CT_UsingTooltip = 0;
				return name;
			end
		end
	end
	CT_UsingTooltip = 0;
	return nil;
end

function CT_BuffButton_Update()
	local buffIndex, untilCancelled = GetPlayerBuff(this:GetID(), "HELPFUL|HARMFUL");
	this.buffIndex = buffIndex;
	this.untilCancelled = untilCancelled;
	
	if ( buffIndex < 0 ) then
		this:Hide();
		return;
	else
		this:SetAlpha(1.0);
		this:Show();
	end

	SetMinMaxBarInfo(this);

	local icon = getglobal(this:GetName().."Icon");
	icon:SetTexCoord(.078, .92, .079, .937);
	icon:SetTexture(GetPlayerBuffTexture(buffIndex, "HELPFUL|HARMFUL"));

	if ( GameTooltip:IsOwned(this) ) then
		GameTooltip:SetPlayerBuff(buffIndex, "HELPFUL|HARMFUL");
	end

	local name = CT_GetBuffName("player", this:GetID(), "HELPFUL|HARMFUL");
	if ( name ) then
		getglobal(this:GetName() .. "DescribeText"):SetText( name );
	end
	CT_BuffNames[this:GetID()] = nil;
end

function CT_BuffButton_OnLoad()
	getglobal(this:GetName() .. "DurationText"):SetTextColor(1, 0.82, 0);

	local bIndex, untilCancelled = GetPlayerBuff(this:GetID(), "HELPFUL|HARMFUL");
	if ( CT_BuffIsDebuff( temp ) == 1 ) then

		if ( CT_ShowRed == 1 ) then
			getglobal(this:GetName() .. "DescribeText"):SetTextColor(1, 0, 0);
		else
			getglobal(this:GetName() .. "DescribeText"):SetTextColor(1, 0.82, 0);
		end
		getglobal(this:GetName() .. "Debuff"):Show();
		this:SetBackdropBorderColor(1, 0, 0);
		this:SetBackdropColor(1, 0, 0,.5);
	else
		getglobal(this:GetName() .. "DescribeText"):SetTextColor(1, 0.82, 0);
		getglobal(this:GetName() .. "Debuff"):Hide();
		this:SetBackdropBorderColor(.25, .5, 1);
		this:SetBackdropColor(.25, .5, 1,.5);
	end

	if ( untilCancelled == 1 or CT_ShowDuration == 0 ) then
		getglobal(this:GetName() .. "DurationText"):SetText("");
	end

	CT_BuffButton_Update();
	this:RegisterForClicks("RightButtonUp");
	this:RegisterEvent("PLAYER_AURAS_CHANGED");

	local descript = getglobal(this:GetName() .. "DescribeText");
	if ( descript ) then descript:Show(); end
end

function CT_BuffButton_OnEvent(event)
	CT_BuffButton_Update();
end

function CT_GetStringTime(seconds)
	local str = "";
	if ( seconds >= 60 ) then
		local minutes = ceil(seconds / 60);
		str = minutes .. " " .. CT_BUFFMOD_MINUTE;
		if ( minutes > 1 ) then
			if ( CT_BuffStyle == 1 ) then
				str = minutes .. "" ..CT_BUFFMOD_SHORTMINUTE;
			else
				str = minutes .. " " .. CT_BUFFMOD_MINUTES;
			end
		else
			if ( CT_BuffStyle == 1 ) then
				str = minutes .. "" ..CT_BUFFMOD_SHORTMINUTE;
			else
				str = minutes .. " " .. CT_BUFFMOD_MINUTE;
			end
		end
	else
		if ( seconds > 1 ) then
			if ( CT_BuffStyle == 1 ) then
				str = floor(seconds) .. "" ..CT_BUFFMOD_SHORTSECOND;
			else
				str = floor(seconds) .. " " .. CT_BUFFMOD_SECONDS;
			end
		else
			if ( CT_BuffStyle == 1 ) then
				str = floor(seconds) .. "" ..CT_BUFFMOD_SHORTSECOND;
			else
				str = floor(seconds) .. " " .. CT_BUFFMOD_SECOND;
			end
		end
	end
	return str;
	
--[[	local str = "";
	local minutes = floor(seconds / 60);
	local secsleft = seconds - (60 * minutes);

	if (seconds >= 60) then
		secsleft = floor(secsleft);
		str = minutes .."m " .. secsleft .. "s";
	else
		if (secsleft < 1) then
			str = string.sub(secsleft, 2, 3);
			str = " ".. str .. "s";
			return str;
		else
			str = floor(seconds) .. " second";
			if(seconds >= 2) then
				str = str .. "s";
			end
		end
	end
	return str;]]
	
end

-- ADDED BY SCAMP
__AE_CT_DURATIONTABLE = {};
__AE_CT_NEEDSSORT = false;
function AE_CT_DURATIONSORT(a, b)
	if not (a['b'] == b['b']) then -- they one is a buff one is a debuff
		if a['b'] == 1 then
			return false; -- buffs before debuffs
		else
			return true;
		end
	end
	return a['d'] > b['d']; -- they are the same compare by remaining time
end
HAXHAXDUMPDUMP = nil;
function __AE_CT_CHECKSORT()
	if __AE_CT_NEEDSSORT then
		__AE_CT_NEEDSSORT = false;
		
		local baseFrame = getglobal("CT_BuffFrame");
		--DEFAULT_CHAT_FRAME:AddMessage(table.getn(__AE_CT_DURATIONTABLE));
		--DEFAULT_CHAT_FRAME:AddMessage(__AE_CT_DURATIONTABLE['b']);
		--DEFAULT_CHAT_FRAME:AddMessage("fack");
		sort(__AE_CT_DURATIONTABLE, AE_CT_DURATIONSORT);
		local height = 0;
		local heightbig = 0;
		local lastid = 0;
		local uggoaddheight = 0;
		for k,v in pairs(__AE_CT_DURATIONTABLE) do
			
			--if v['d'] == nil then
			--	DEFAULT_CHAT_FRAME:AddMessage("isnill");
			--else
			--	DEFAULT_CHAT_FRAME:AddMessage("isntnill");
			--end
			--DEFAULT_CHAT_FRAME:AddMessage(v['d']);
			--DEFAULT_CHAT_FRAME:AddMessage(k);
			--00CT_BuffMod_Drag:Show();
			--DEFAULT_CHAT_FRAME:AddMessage("DERP");
			if(getglobal("CT_BuffButton" .. v['i']):IsVisible()) then
				getglobal("CT_BuffButton" .. v['i']):SetPoint("TOPLEFT", "CT_BuffMod_Drag", "BOTTOMLEFT", -160, -(heightbig));
				getglobal("CT_SimpleBuffButton" .. v['i']):SetPoint("TOPLEFT", "CT_BuffMod_Drag", "BOTTOMLEFT", -160, -height);
				height = height + getglobal("CT_SimpleBuffButton" .. v['i']):GetHeight();
				heightbig = heightbig + getglobal("CT_BuffButton" .. v['i']):GetHeight();
				--uggoaddheight = uggoaddheight + 10;
			--SetPoint("TOPLEFT", "CT_BuffButton" .. i, "TOPLEFT", 5, -4);
			--if lastid == 0 and v['i'] == 0 then
			--	getglobal("CT_BuffButton" .. v['i']):SetPoint("TOPLEFT", "CT_BuffFrame", "BOTTOMLEFT", -150, -1);
			--	getglobal("CT_SimpleBuffButton" .. v['i']):SetPoint("TOPLEFT", "CT_BuffFrame", "BOTTOMLEFT", -150, -1);
			--else 
			--	getglobal("CT_BuffButton" .. v['i']):SetPoint("TOPLEFT", "CT_BuffButton" .. lastid, "BOTTOMLEFT", 0, -1);
			--	getglobal("CT_SimpleBuffButton" .. v['i']):SetPoint("TOPLEFT", "CT_BuffButton" .. lastid, "BOTTOMLEFT", 0, -1);
			--end
				lastid = v['i'];
			end
		end
	end
end
-- END ADDED BY SCAMP


function CT_BuffButton_OnUpdate(elapsed)
	local buffname;
	local bIndex, untilCancelled = GetPlayerBuff( this:GetID(), "HELPFUL|HARMFUL" );

	local timebar = getglobal(this:GetName().."BuffStatusBar");
	local isDebuff = CT_BuffIsDebuff(bIndex);
	local buffnum = GetPlayerBuffApplications(bIndex)
	local r, g, b

	-- Set Number of Applications
	if ( buffnum > 1 ) then
		getglobal(this:GetName() .. "Count"):SetText(buffnum);
	else
		getglobal(this:GetName() .. "Count"):SetText("");
	end

	local timeLeft = GetPlayerBuffTimeLeft(bIndex);
	local buffAlphaValue;
	

	-- Set Debuff Text Style text red or normal
	if ( isDebuff == 1 ) then
		r=1; g=0; b=0
		if ( CT_ShowRed == 1 ) then
			getglobal(this:GetName() .. "DescribeText"):SetTextColor(1, 0, 0);
		else
			getglobal(this:GetName() .. "DescribeText"):SetTextColor(1, 0.82, 0);
		end
		getglobal(this:GetName() .. "Debuff"):Show();
		getglobal(this:GetName() .. "Buff"):Hide();
		this:SetBackdropBorderColor(1, 0, 0);
		this:SetBackdropColor(1, 0, 0,.5);
	else
		r=0; g=.25; b=.75
		getglobal(this:GetName() .. "DescribeText"):SetTextColor(1, 0.82, 0);
		getglobal(this:GetName() .. "Debuff"):Hide();
		getglobal(this:GetName() .. "Buff"):Show();
		this:SetBackdropBorderColor(.25, .5, 1);
		this:SetBackdropColor(.25, .5, 1,.5);
		getglobal(this:GetName() .. "StatusBarSpark"):Hide();
	end

	timebar:SetAlpha(1);
	timebar:SetStatusBarColor(r,g,b,.5);
	--DEFAULT_CHAT_FRAME:AddMessage(timeLeft);
	--DEFAULT_CHAT_FRAME:AddMessage(bIndex);
	timebar:SetValue(timeLeft);
	
	-- Clear everything whe cancelled
	if ( untilCancelled == 1 ) then
		timebar:SetAlpha(0);
		getglobal(this:GetName() .. "Dispell"):Hide();
		getglobal(this:GetName() .. "DurationText"):SetText("");
		getglobal(this:GetName() .. "BuffTypeText"):SetText("");
		getglobal(this:GetName() .. "DeBuffIcon"):SetTexture ("");
		return;
	end

	-- Update saved CT_BuffNames
	if ( not CT_BuffNames[this:GetID()] ) then
		buffname = CT_GetBuffName( "player", this:GetID(), this.buffFilter);
		CT_BuffNames[this:GetID()] = buffname;
	else
		buffname = CT_BuffNames[this:GetID()];
	end
	
	-- Update saved CT_MaxTime for StatusBar
	if ( CT_MaxTime[buffname] ~= nil ) then
	if ( timeLeft > CT_MaxTime[buffname] ) then
		CT_MaxTime[buffname]  = timeLeft;
		SetMinMaxBarInfo(this);
	elseif ( timeLeft == 0 ) then
		CT_MaxTime[buffname] = 0;
	end
	end
	
	
	-- ADDED BY SCAMP
	local needsNew = true;
	local rtimeLeft = timeLeft;
	if rtimeleft == 0 or rtimeleft == nil then
		rtimeleft = 1;
	end
	for k,v in pairs(__AE_CT_DURATIONTABLE) do -- bad code is bad
		if v['i'] == bIndex then
			v['d'] = rtimeLeft;
			v['b'] = isDebuff;
			needsNew = false;
		end
	end
	if needsNew then
	table.insert(__AE_CT_DURATIONTABLE, {
		['d'] = rtimeLeft,
		['i'] = bIndex,
		['b'] = isDebuff
	});
	end
	__AE_CT_NEEDSSORT = true;
	--if __AE_CT_DURATIONTABLE[this:GetID()] == nil then -- bad code is bad
	--		__AE_CT_DURATIONTABLE[this:GetID()] = {};
	--end
	--__AE_CT_DURATIONTABLE[this:GetID()]['d'] = timeLeft;
	--__AE_CT_DURATIONTABLE[this:GetID()]['i'] = bIndex;
	--__AE_CT_DURATIONTABLE[this:GetID()]['b'] = isDebuff;
	--__AE_CT_NEEDSSORT = true;
	-- END ADDED BY SCAMP
	
	
	-- Update StatusBarSpark
	if ( CT_MaxTime[buffname] ~= nil  and timeLeft > 0) then
		local width = getglobal(this:GetName() .. "BuffStatusBar"):GetWidth()
		local SparkTimeLeft = ((( timeLeft / 1000) / (CT_MaxTime[buffname] / 1000)) * width) - width
--		getglobal(this:GetName() .. "StatusBarSpark"):SetVertexColor (r,g,b);
		getglobal(this:GetName() .. "StatusBarSpark"):SetPoint("CENTER", this:GetName() .. "BuffStatusBar","Right",SparkTimeLeft, 0);
		getglobal(this:GetName() .. "StatusBarSpark"):Show();
	else
		getglobal(this:GetName() .. "StatusBarSpark"):Hide();
	end
	
	-- Clear if not isDebuff
	local buffType = CT_GetBuffType( "player", this:GetID(), "HARMFUL" );
	if (isDebuff == 0) then
		getglobal(this:GetName() .. "DeBuffIcon"):SetTexture ("");
		getglobal(this:GetName() .. "Dispell"):Hide();
	end

	-- Clear if no buffType
	if (buffType == nil and isDebuff == 1) then
		getglobal(this:GetName() .. "DeBuffIcon"):SetTexture ("");
		getglobal(this:GetName() .. "Dispell"):Hide();
	end

	-- Show/Hide CT_DebuffIcons Style
	if (buffType ~= nil and isDebuff == 1) then
		if CT_DebuffIcons == 1 then
			getglobal(this:GetName() .. "DeBuffIcon"):Show();
			getglobal(this:GetName().."BuffTypeText"):Hide();
		elseif CT_DebuffIcons == 2 then
			getglobal(this:GetName() .. "DeBuffIcon"):Hide();
			getglobal(this:GetName().."BuffTypeText"):Show();
		else
			getglobal(this:GetName() .. "DeBuffIcon"):Hide();
			getglobal(this:GetName().."BuffTypeText"):Hide();
		end

		local buffTypeicon = getglobal(this:GetName() .. "DeBuffIcon");
		buffTypeicon:SetTexCoord(.078, .92, .079, .937);
		
		-- Set CT_DebuffBorder Style
		if ( CT_DebuffBorder == 1 ) then
			if buffType == "Disease" then
				getglobal("CT_BuffButton" .. this:GetID()):SetBackdropBorderColor(.60, .40, 0);
				getglobal("CT_SimpleBuffButton" .. this:GetID()):SetBackdropBorderColor(.60, .40, 0);
			elseif buffType == "Poison" then
				getglobal("CT_BuffButton" .. this:GetID()):SetBackdropBorderColor(0, .60, 0);
				getglobal("CT_SimpleBuffButton" .. this:GetID()):SetBackdropBorderColor(0, .60, 0);
			elseif buffType == "Magic" then
				getglobal("CT_BuffButton" .. this:GetID()):SetBackdropBorderColor(.20, .60, 1);
				getglobal("CT_SimpleBuffButton" .. this:GetID()):SetBackdropBorderColor(.20, .60, 1);
			elseif buffType == "Curse" then
				getglobal("CT_BuffButton" .. this:GetID()):SetBackdropBorderColor(.60, 0, 1);
				getglobal("CT_SimpleBuffButton" .. this:GetID()):SetBackdropBorderColor(.60, 0, 1);
			else
			getglobal("CT_BuffButton" .. this:GetID()):SetBackdropBorderColor(1, 0, 0);
			getglobal("CT_SimpleBuffButton" .. this:GetID()):SetBackdropBorderColor(1, 0, 0);
			end
		end

		-- Set Dispellable by class
		PlayerClass = UnitClass("player");
		dispelType = GetPlayerBuffDispelType(GetPlayerBuff(this:GetID(), HARMFUL));
		
		if ( dispelType ~= nil  and CT_BuffIsDebuff(bIndex) == 1 ) then
			if ( PlayerClass == "Priest" ) then
				if ( dispelType == "Disease"  or  dispelType == "Magic" ) then
					getglobal(this:GetName() .. "Dispell"):Show();
				else
					getglobal(this:GetName() .. "Dispell"):Hide();
				end
				
			elseif ( PlayerClass == "Shaman" ) then
				if ( dispelType == "Disease"  or  dispelType == "Magic" or  dispelType == "Poison" ) then
					getglobal(this:GetName() .. "Dispell"):Show();
				else
					getglobal(this:GetName() .. "Dispell"):Hide();
				end
				
			elseif ( PlayerClass == "Druid" ) then
				if ( dispelType == "Curse"  or  dispelType == "Poison" ) then
					getglobal(this:GetName() .. "Dispell"):Show();
				else
					getglobal(this:GetName() .. "Dispell"):Hide();
				end
				
			elseif ( PlayerClass == "Mage" ) then
				if ( dispelType == "Curse" ) then
					getglobal(this:GetName() .. "Dispell"):Show();
				else
					getglobal(this:GetName() .. "Dispell"):Hide();
				end
				
			elseif ( PlayerClass == "Paladin" ) then
				if ( dispelType == "Disease"  or  dispelType == "Magic" or  dispelType == "Poison" ) then
					getglobal(this:GetName() .. "Dispell"):Show();
				else
					getglobal(this:GetName() .. "Dispell"):Hide();
				end
				
			elseif ( PlayerClass == "Warlock" ) then
				if ( dispelType == "Magic" ) then
					local pettype = UnitCreatureFamily("pet");
					if (pettype ~= nil and pettype == "Felhunter") then
						getglobal(this:GetName() .. "Dispell"):Show();
					else
						getglobal(this:GetName() .. "Dispell"):Hide();
					end
				end
			else
				getglobal(this:GetName() .. "Dispell"):Hide();
			end
		end
		
		-- Set CT_DebuffIcons Style
		if ( CT_DebuffIcons == 1 or CT_DebuffIcons == 2 ) then
			if buffType == "Disease" then
				if ( CT_BuffStyle == 2 ) then
					buffTypeicon:SetTexture ("Interface\\Icons\\Spell_Holy_Excorcism_02");
					getglobal(this:GetName().."BuffTypeText"):SetTextColor(.64, .40, 0);
				end
			elseif buffType == "Poison" then
				if ( CT_BuffStyle == 2 ) then
					buffTypeicon:SetTexture ("Interface\\Icons\\Spell_Holy_TurnUndead");
					getglobal(this:GetName().."BuffTypeText"):SetTextColor(0, .60, 0);
				end
			elseif buffType == "Magic" then
				if ( CT_BuffStyle == 2 ) then
					buffTypeicon:SetTexture ("Interface\\Icons\\Spell_Holy_SenseUndead");
					getglobal(this:GetName().."BuffTypeText"):SetTextColor(.20, .60, 1);
				end
			elseif buffType == "Curse" then
				if ( CT_BuffStyle == 2 ) then
					buffTypeicon:SetTexture ("Interface\\Icons\\Spell_Shadow_ChillTouch");
					getglobal(this:GetName().."BuffTypeText"):SetTextColor(.60, 0, 1);
				end
			else
				getglobal(this:GetName() .. "DeBuffIcon"):SetTexture ("");
				getglobal(this:GetName().."BuffTypeText"):SetTextColor(1, 0.82, 0);
			end
			if ( CT_BuffStyle == 2 ) then
				getglobal(this:GetName().."BuffTypeText"):SetText(buffType);
			end
			else
		end
	end

	if ( timeLeft >= 1 and CT_ShowDuration == 1 ) then 
		getglobal(this:GetName() .. "DurationText"):SetText(CT_GetStringTime(timeLeft));
	else
		getglobal(this:GetName() .. "DurationText"):SetText("");
	end

	if ( floor(timeLeft) == MinBuffDurationExpireMessage and not CT_ExpireBuffs[buffname] ) then
		CT_ExpireBuffs[buffname] = 1;
	end

	if ( ceil(timeLeft) == ExpireMessageTime and CT_ExpireBuffs[buffname] and CT_BuffIsDebuff(bIndex) == 0 ) then
		if ( CT_ShowExpire == 1 and not CT_BuffMod_NoRecastBuffs[buffname]) then
			if ( CT_PlaySound == 1 ) then
				PlaySound("TellMessage");
			end
			CT_BuffMod_AddToQueue(buffname);
			local message;
			if ( CT_PlayerSpells[buffname] and GetBindingKey("CT_RECASTBUFF") ) then
				message = format(ExpireMessageRecastString, buffname, GetBindingText(GetBindingKey("CT_RECASTBUFF"), "KEY_"));
			else
				message = format(ExpireMessageString, buffname);
			end
			ExpireMessageFrame:AddMessage(message, ExpireMessageColors["r"], ExpireMessageColors["g"], ExpireMessageColors["b"]);
		end
		CT_ExpireBuffs[buffname] = nil;
		CT_BuffNames[this:GetID()] = nil;
	end
	if ( timeLeft < BuffStartFlashTime ) then
		if ( BuffFlashState == 1 ) then
			buffAlphaValue = (BuffFlashOn - BuffFlashTime) / BuffFlashOn;
			buffAlphaValue = buffAlphaValue * (1 - BuffMinOpacity) + BuffMinOpacity;
		else
			buffAlphaValue = BuffFlashTime / BuffFlashOn;
			buffAlphaValue = (buffAlphaValue * (1 - BuffMinOpacity)) + BuffMinOpacity;
			this:SetAlpha(BuffFlashTime / BuffFlashOn);
		end
		this:SetAlpha(buffAlphaValue);
	else
		this:SetAlpha(1.0);
	end

	if ( BuffFlashUpdateTime > 0 ) then
		return;
	end
	if ( GameTooltip:IsOwned(this) ) then
		GameTooltip:SetPlayerBuff(bIndex);
	end
end

function CT_BuffButton_OnClick()
	local buffname = CT_GetBuffName("player", this.buffIndex, this.buffFilter);
	CT_MaxTime[buffname] = nil;
	CancelPlayerBuff(this.buffIndex);
end

function CT_Buffs_SwapSides(onLoad)
	CT_SetBuffStyleSwap = CT_BuffMod_BuffSides ;
	local i;
	for i = 0, 23, 1 do
		getglobal("CT_BuffButton" .. i .. "DescribeText"):ClearAllPoints();
		getglobal("CT_BuffButton" .. i .. "DurationText"):ClearAllPoints();
		getglobal("CT_BuffButton" .. i .. "Icon"):ClearAllPoints();
		getglobal("CT_BuffButton" .. i .. "DeBuffIcon"):ClearAllPoints();
		getglobal("CT_BuffButton" .. i .. "BuffTypeText"):ClearAllPoints();
		getglobal("CT_BuffButton" .. i .. "Count"):ClearAllPoints();
		getglobal("CT_BuffButton" .. i .. "BuffStatusBar"):ClearAllPoints();
		getglobal("CT_BuffButton" .. i .. "Dispell"):ClearAllPoints();

		getglobal("CT_SimpleBuffButton" .. i .. "DescribeText"):ClearAllPoints();
		getglobal("CT_SimpleBuffButton" .. i .. "DurationText"):ClearAllPoints();
		getglobal("CT_SimpleBuffButton" .. i .. "Icon"):ClearAllPoints();
		getglobal("CT_SimpleBuffButton" .. i .. "DeBuffIcon"):ClearAllPoints();
		getglobal("CT_SimpleBuffButton" .. i .. "BuffTypeText"):ClearAllPoints();
		getglobal("CT_SimpleBuffButton" .. i .. "Count"):ClearAllPoints();
		getglobal("CT_SimpleBuffButton" .. i .. "BuffStatusBar"):ClearAllPoints();
		getglobal("CT_SimpleBuffButton" .. i .. "Dispell"):ClearAllPoints();

			if ( CT_BuffMod_BuffSides == "RIGHT" or onLoad ) then
				getglobal("CT_BuffButton" .. i .. "DescribeText"):SetPoint("RIGHT", "CT_BuffButton" .. i, "RIGHT", -35, 7);
				getglobal("CT_BuffButton" .. i .. "DurationText"):SetPoint("RIGHT", "CT_BuffButton" .. i, "RIGHT", -35, -5);
				getglobal("CT_BuffButton" .. i .. "Icon"):SetPoint("RIGHT", "CT_BuffButton" .. i, "RIGHT", -5, 0);
				getglobal("CT_BuffButton" .. i .. "Count"):SetPoint("CENTER", "CT_BuffButton" .. i .. "Icon", "CENTER", 0, 0);
				getglobal("CT_BuffButton" .. i .. "DeBuffIcon"):SetPoint("LEFT", "CT_BuffButton" .. i, "LEFT", 6, 0);
				getglobal("CT_BuffButton" .. i .. "BuffTypeText"):SetPoint("LEFT", "CT_BuffButton" .. i, "LEFT", 7, -5);
				getglobal("CT_BuffButton" .. i .. "BuffStatusBar"):SetPoint("TOPLEFT", "CT_BuffButton" .. i, "TOPLEFT", 5, -4);
				getglobal("CT_BuffButton" .. i .. "Dispell"):SetPoint("RIGHT", "CT_BuffButton" .. i, "RIGHT", 12, 0);

				getglobal("CT_SimpleBuffButton" .. i .. "DescribeText"):SetPoint("RIGHT", "CT_SimpleBuffButton" .. i, "RIGHT", -20, 0);
				getglobal("CT_SimpleBuffButton" .. i .. "DurationText"):SetPoint("LEFT", "CT_SimpleBuffButton" .. i, "LEFT", 5, 0);
				getglobal("CT_SimpleBuffButton" .. i .. "Icon"):SetPoint("RIGHT", "CT_SimpleBuffButton" .. i, "RIGHT", -3, 0);
				getglobal("CT_SimpleBuffButton" .. i .. "Count"):SetPoint("CENTER", "CT_SimpleBuffButton" .. i .. "Icon", "CENTER", -1, 0);
				getglobal("CT_SimpleBuffButton" .. i .. "DeBuffIcon"):SetPoint("LEFT", "CT_SimpleBuffButton" .. i, "LEFT", 6, 0);
				getglobal("CT_SimpleBuffButton" .. i .. "BuffTypeText"):SetPoint("LEFT", "CT_SimpleBuffButton" .. i, "LEFT", 7, -5);
				getglobal("CT_SimpleBuffButton" .. i .. "BuffStatusBar"):SetPoint("TOPRIGHT", "CT_SimpleBuffButton" .. i, "TOPRIGHT", -16, -3);
				getglobal("CT_SimpleBuffButton" .. i .. "Dispell"):SetPoint("RIGHT", "CT_SimpleBuffButton" .. i, "RIGHT", 12, 0);
				
			elseif ( CT_BuffMod_BuffSides == "LEFT" ) then
				getglobal("CT_BuffButton" .. i .. "DescribeText"):SetPoint("LEFT", "CT_BuffButton" .. i, "LEFT", 35, 7);
				getglobal("CT_BuffButton" .. i .. "DurationText"):SetPoint("LEFT", "CT_BuffButton" .. i, "LEFT", 35, -5);
				getglobal("CT_BuffButton" .. i .. "Icon"):SetPoint("LEFT", "CT_BuffButton" .. i, "LEFT", 5, 0);
				getglobal("CT_BuffButton" .. i .. "Count"):SetPoint("CENTER", "CT_BuffButton" .. i .. "Icon", "CENTER", 0, 0);
				getglobal("CT_BuffButton" .. i .. "DeBuffIcon"):SetPoint("RIGHT", "CT_BuffButton" .. i, "RIGHT", -6, 0);
				getglobal("CT_BuffButton" .. i .. "BuffTypeText"):SetPoint("RIGHT", "CT_BuffButton" .. i, "RIGHT", -8, -5);
				getglobal("CT_BuffButton" .. i .. "BuffStatusBar"):SetPoint("TOPLEFT", "CT_BuffButton" .. i, "TOPLEFT", 30, -4);
				getglobal("CT_BuffButton" .. i .. "Dispell"):SetPoint("LEFT", "CT_BuffButton" .. i, "LEFT", -12, 0);
				
				getglobal("CT_SimpleBuffButton" .. i .. "DescribeText"):SetPoint("LEFT", "CT_SimpleBuffButton" .. i, "LEFT", 20, 0);
				getglobal("CT_SimpleBuffButton" .. i .. "DurationText"):SetPoint("RIGHT", "CT_SimpleBuffButton" .. i, "RIGHT", -5, 0);
				getglobal("CT_SimpleBuffButton" .. i .. "Icon"):SetPoint("TOPLEFT", "CT_SimpleBuffButton" .. i, "TOPLEFT", 3, -3);
				getglobal("CT_SimpleBuffButton" .. i .. "Count"):SetPoint("CENTER", "CT_SimpleBuffButton" .. i .. "Icon", "CENTER", 1, 0);
				getglobal("CT_SimpleBuffButton" .. i .. "DeBuffIcon"):SetPoint("RIGHT", "CT_SimpleBuffButton" .. i, "RIGHT", -6, 0);
				getglobal("CT_SimpleBuffButton" .. i .. "BuffTypeText"):SetPoint("RIGHT", "CT_SimpleBuffButton" .. i, "RIGHT", -8, -5);
				getglobal("CT_SimpleBuffButton" .. i .. "BuffStatusBar"):SetPoint("TOPRIGHT", "CT_SimpleBuffButton" .. i, "TOPRIGHT",0, -3);
				getglobal("CT_SimpleBuffButton" .. i .. "Dispell"):SetPoint("LEFT", "CT_SimpleBuffButton" .. i, "LEFT", -12, 0);
			end
		end
	
	if ( onLoad ) then return; end
	if ( CT_BuffMod_BuffSides == "LEFT" ) then
		CT_BuffMod_BuffSides = "RIGHT";
	else
		CT_BuffMod_BuffSides = "LEFT";
	end
end

expirefunction = function(modId, count)
	local val = CT_Mods[modId]["modValue"];
	if ( val == "1min" ) then
		CT_Mods[modId]["modValue"] = "Off";
		if ( count ) then count:SetText("Off"); end
		CT_ShowExpire = 0;
		CT_Print(CT_BUFFMOD_ON_EXPIRE, 1.0, 1.0, 0.0);
	else
		CT_ShowExpire = 1;
		if ( val == "15sec" ) then
			CT_Mods[modId]["modValue"] = "1min";
			if ( count ) then count:SetText("1min"); end
			CT_Print(CT_BUFFMOD_MIN_EXPIRE, 1.0, 1.0, 0.0);
			ExpireMessageTime = 60;
			MinBuffDurationExpireMessage = 120;
		elseif ( val == "Off" ) then
			CT_Mods[modId]["modValue"] = "15sec";
			if ( count ) then count:SetText("15sec"); end
			CT_Print(CT_BUFFMOD_SEC_EXPIRE, 1.0, 1.0, 0.0);
			ExpireMessageTime = 15;
			MinBuffDuratioonExpireMessage = 51;
		end
	end
end

durationfunction = function(modId)
	if ( CT_ShowDuration == 1 ) then
		CT_ShowDuration = 0;
		CT_SetModStatus(modId, "off");
		CT_Print(CT_BUFFMOD_OFF_DURATION, 1.0, 1.0, 0.0);
	else
		CT_ShowDuration = 1;
		CT_SetModStatus(modId, "on");
		CT_Print(CT_BUFFMOD_ON_DURATION, 1.0, 1.0, 0.0);
	end
end

expireinitfunction = function(modId)
	local val = CT_Mods[modId]["modValue"];
	if ( val == "Off" ) then
		CT_ShowExpire = 0;
	else
		CT_ShowExpire = 1;
		if ( val == "1min" ) then
			ExpireMessageTime = 60;
			MinBuffDurationExpireMessage = 120;
		elseif ( val == "15sec" ) then
			ExpireMessageTime = 15;
			MinBuffDurationExpireMessage = 51;
		end
	end
end
durationinitfunction = function(modId)
	local val = CT_Mods[modId]["modStatus"];
	if ( val == "on" ) then
		CT_ShowDuration = 1;
	else
		CT_ShowDuration = 0;
	end
end

debuffnamesfunction = function(modId)
	local val = CT_Mods[modId]["modStatus"];
	if ( val == "on" ) then
		CT_ShowRed = 1;
		CT_Print(CT_BUFFMOD_ON_DEBUFF, 1.0, 1.0, 0.0);
	else
		CT_ShowRed = 0;
		CT_Print(CT_BUFFMOD_OFF_DEBUFF, 1.0, 1.0, 0.0);
	end
end

debuffnamesinitfunction = function(modId)
	local val = CT_Mods[modId]["modStatus"];
	if ( val == "on" ) then
		CT_ShowRed = 1;
	else
		CT_ShowRed = 0;
	end
end

debuffborderfunction = function(modId)
	local val = CT_Mods[modId]["modStatus"];
	if ( val == "on" ) then
		CT_DebuffBorder = 1;
		CT_Print(CT_BUFFMOD_ON_DEBUFFBORDER, 1.0, 1.0, 0.0);
	else
		CT_DebuffBorder = 0;
		CT_Print(CT_BUFFMOD_OFF_DEBUFFBORDER, 1.0, 1.0, 0.0);
	end
end

debuffborderinitfunction = function(modId)
	local val = CT_Mods[modId]["modStatus"];
	if ( val == "on" ) then
		CT_DebuffBorder = 1;
	else
		CT_DebuffBorder = 0;
	end
end

debufficonsfunction = function(modId, count)
	local val = CT_Mods[modId]["modValue"];
	if ( val == "Text" ) then
		CT_Mods[modId]["modValue"] = "Off";
		if ( count ) then count:SetText("Off"); end
		CT_DebuffIcons = 0;
		CT_Print(CT_BUFFICONSMOD_OFF_DEBUFF, 1.0, 1.0, 0.0);
	else
		if ( val == "Off" ) then
		CT_Mods[modId]["modValue"] = "Icon";
		if ( count ) then count:SetText("Icon"); end	
		if ( CT_BuffStyle == 1 ) then
			CT_Print(CT_BUFFICONSMOD_SIMPLE_DEBUFF, 1.0, 1.0, 0.0);
			CT_DebuffIcons = 0;
		else
			CT_DebuffIcons = 1;
			CT_Print(CT_BUFFICONSMOD_ICON_DEBUFF, 1.0, 1.0, 0.0);
		end

		elseif ( val == "Icon" ) then
		CT_Mods[modId]["modValue"] = "Text";
		if ( count ) then count:SetText("Text"); end
		if ( CT_BuffStyle == 1 ) then
			CT_Print(CT_BUFFICONSMOD_SIMPLE_DEBUFF, 1.0, 1.0, 0.0);
			CT_DebuffIcons = 0;
		else
			CT_DebuffIcons = 2;
			CT_Print(CT_BUFFICONSMOD_TEXT_DEBUFF, 1.0, 1.0, 0.0);
		end
		end
	end
end

debufficonsinitfunction = function(modId)
	local val = CT_Mods[modId]["modValue"];
	if ( val == "Off" ) then
		CT_DebuffIcons = 0;
	else
		if ( val == "Icon" ) then
		CT_DebuffIcons = 1;
		
		elseif ( val == "Text" ) then
		CT_DebuffIcons = 2;
		end
	end
end

buffscalefunction = function(modId, count)
	local val = CT_Mods[modId]["modValue"];
	if ( val == "90" ) then
		CT_Mods[modId]["modValue"] = "100";
		if ( count ) then count:SetText("100%"); end
		CT_BuffScale = 1;
		CT_Print(CT_BUFFSCALE_100, 1.0, 1.0, 0.0);
	else
		if ( val == "100" ) then
		CT_Mods[modId]["modValue"] = "60";
		if ( count ) then count:SetText("60%"); end
		CT_BuffScale = .6;
		CT_Print(CT_BUFFSCALE_60, 1.0, 1.0, 0.0);

		elseif ( val == "60" ) then
		CT_Mods[modId]["modValue"] = "70";
		if ( count ) then count:SetText("70%"); end
		CT_BuffScale = .7;
		CT_Print(CT_BUFFSCALE_70, 1.0, 1.0, 0.0);

		elseif ( val == "70" ) then
		CT_Mods[modId]["modValue"] = "80";
		if ( count ) then count:SetText("80%"); end
		CT_BuffScale = .8;
		CT_Print(CT_BUFFSCALE_80, 1.0, 1.0, 0.0);

		elseif ( val == "80" ) then
		CT_Mods[modId]["modValue"] = "90";
		if ( count ) then count:SetText("90%"); end
		CT_BuffScale = .9;
		CT_Print(CT_BUFFSCALE_90, 1.0, 1.0, 0.0);
		end
	end

	local i;
	for i = 0, 23, 1 do
		getglobal("CT_SimpleBuffButton" .. i):SetScale (CT_BuffScale);
		getglobal("CT_BuffButton" .. i):SetScale (CT_BuffScale);
	end
end

buffscaleinitfunction = function(modId)
	local val = CT_Mods[modId]["modValue"];
	if ( val == "100" ) then
		CT_BuffScale = 1;
	else
		if ( val == "90" ) then
		CT_BuffScale = .9;
		
		elseif ( val == "80" ) then
		CT_BuffScale = .8;

		elseif ( val == "70" ) then
		CT_BuffScale = .7;

		elseif ( val == "60" ) then
		CT_BuffScale = .6;
		end
	end

	local i;
	for i = 0, 23, 1 do
		getglobal("CT_SimpleBuffButton" .. i):SetScale (CT_BuffScale);
		getglobal("CT_BuffButton" .. i):SetScale (CT_BuffScale);
	end
end

lockframefunction = function(modId)
	local val = CT_Mods[modId]["modStatus"];
	if ( val == "off" ) then
		CT_Print(CT_BUFFMOD_OFF_LOCK, 1, 1, 0);
		CT_BuffMod_Drag:Hide();
	else
		CT_Print(CT_BUFFMOD_ON_LOCK, 1, 1, 0);
		CT_BuffMod_Drag:Show();
	end
end

lockframeinitfunction = function(modId)
	local val = CT_Mods[modId]["modStatus"];
	if ( val == "off" ) then
		CT_BuffMod_Drag:Hide();
	else
		CT_BuffMod_Drag:Show();
	end
end

buffmodfunction = function(modId,count)
	local val = CT_Mods[modId]["modValue"];
	
	if ( val == "Full" ) then
		CT_Mods[modId]["modValue"] = "Default";
		if ( count ) then count:SetText("Default"); end
		CT_BuffStyle= 0;
		CT_Print(CT_BUFFMOD_OFF_TOGGLE, 1, 1, 0);
		CT_BuffFrame:Hide();
		CT_SimpleBuffFrame:Hide();
		CT_ItemBuffFrame:Hide();
		BuffFrame:Show();
		if ( TemporaryEnchantFrame ) then
			TemporaryEnchantFrame:Show();
		end	
	else
	
		if ( val == "Default" ) then
		CT_Mods[modId]["modValue"] = "Simple";
		if ( count ) then count:SetText("Simple"); end
		CT_BuffStyle= 1;
		CT_Print(CT_BUFFMOD_SIMPLE_TOGGLE, 1, 1, 0);
		CT_BuffMod_Drag:SetParent("CT_SimpleBuffFrame");
		CT_ItemBuffFrame:SetParent("CT_SimpleBuffFrame");
		CT_BuffFrame:Hide();
		CT_SimpleBuffFrame:Show();
		CT_ItemBuffFrame:Show();
		BuffFrame:Hide();
			if ( TemporaryEnchantFrame and CT_ItemBuffFrame ) then
				TemporaryEnchantFrame:Hide();
			elseif ( TemporaryEnchantFrame ) then
				TemporaryEnchantFrame:Show();
			end
		
		elseif ( val == "Simple" ) then
		CT_Mods[modId]["modValue"] = "Full";
		if ( count ) then count:SetText("Full"); end
		CT_BuffStyle= 2;
		CT_Print(CT_BUFFMOD_FULL_TOGGLE , 1, 1, 0);
		CT_BuffMod_Drag:SetParent("CT_BuffFrame");
		CT_ItemBuffFrame:SetParent("CT_BuffFrame");
		CT_BuffFrame:Show();
		CT_ItemBuffFrame:Show();
		CT_SimpleBuffFrame:Hide();
		BuffFrame:Hide();
			if ( TemporaryEnchantFrame and CT_ItemBuffFrame ) then
				TemporaryEnchantFrame:Hide();
			elseif ( TemporaryEnchantFrame ) then
				TemporaryEnchantFrame:Show();
			end
	end
	
end
	CT_SetItemBuffStyle();
end

buffmodinitfunction = function(modId)
	local val = CT_Mods[modId]["modValue"];
	
	if ( val == "Default" ) then
		CT_BuffStyle = 0;
		CT_BuffFrame:Hide();
		CT_SimpleBuffFrame:Hide();
		BuffFrame:Show();
		if ( TemporaryEnchantFrame ) then
			TemporaryEnchantFrame:Show();
		end
	else
	
	if ( val == "Full" ) then
		CT_BuffStyle = 2;
		CT_BuffMod_Drag:SetParent("CT_BuffFrame");
		CT_ItemBuffFrame:SetParent("CT_BuffFrame");
		CT_ItemBuffFrame:Show();
		CT_BuffFrame:Show();
		CT_SimpleBuffFrame:Hide();
		BuffFrame:Hide();
		if ( TemporaryEnchantFrame and CT_ItemBuffFrame ) then
			TemporaryEnchantFrame:Hide();
		elseif ( TemporaryEnchantFrame ) then
			TemporaryEnchantFrame:Show();
		end

	elseif ( val == "Simple" ) then
		CT_BuffStyle = 1;
		CT_BuffMod_Drag:SetParent("CT_SimpleBuffFrame");
		CT_ItemBuffFrame:SetParent("CT_SimpleBuffFrame");
		CT_ItemBuffFrame:Show();
		CT_BuffFrame:Hide();
		CT_SimpleBuffFrame:Show();
		BuffFrame:Hide();
		if ( TemporaryEnchantFrame and CT_ItemBuffFrame ) then
			TemporaryEnchantFrame:Hide();
		elseif ( TemporaryEnchantFrame ) then
			TemporaryEnchantFrame:Show();
		end
	end
	end
	CT_SetItemBuffStyle();
end

CT_RegisterMod(CT_BUFFMOD_MODNAME_DEBUFFBORDER, CT_BUFFMOD_MODNAME_SUB_DEBUFFBORDER, 4, "Interface\\Icons\\INV_Misc_Note_02", CT_BUFFMOD_MODNAME_TOOLTIP_DEBUFFBORDER, "off", nil, debuffborderfunction, debuffborderinitfunction);
CT_RegisterMod(CT_BUFFMOD_MODNAME_DEBUFFICONS, CT_BUFFMOD_MODNAME_SUB_DEBUFFICONS, 4, "Interface\\Icons\\Spell_Holy_TurnUndead", CT_BUFFMOD_MODNAME_TOOLTIP_DEBUFFICONS, "switch", "Off", debufficonsfunction, debufficonsinitfunction);
CT_RegisterMod(CT_BUFFMOD_MODNAME_BUFFSCALE, CT_BUFFMOD_MODNAME_SUB_BUFFSCALE, 4, "Interface\\Icons\\Ability_Repair", CT_BUFFMOD_MODNAME_TOOLTIP_BUFFSCALE, "switch", "100", buffscalefunction, buffscaleinitfunction);
CT_RegisterMod(CT_BUFFMOD_MODNAME_TOGGLE, CT_BUFFMOD_MODNAME_SUB_TOGGLE, 4, "Interface\\Icons\\Spell_Holy_Renew", CT_BUFFMOD_MODNAME_TOOLTIP_TOGGLE, "switch", "Full", buffmodfunction, buffmodinitfunction);
CT_RegisterMod(CT_BUFFMOD_MODNAME_EXPIRE, CT_BUFFMOD_MODNAME_SUB_EXPIRE, 4, "Interface\\Icons\\INV_Misc_Note_03", CT_BUFFMOD_MODNAME_TOOLTIP_EXPIRE, "switch", "15sec", expirefunction, expireinitfunction);
CT_RegisterMod(CT_BUFFMOD_MODNAME_DURATION, CT_BUFFMOD_MODNAME_SUB_DURATION, 4, "Interface\\Icons\\INV_Misc_PocketWatch_01", CT_BUFFMOD_MODNAME_TOOLTIP_DURATION, "on", nil, durationfunction, durationinitfunction);
CT_RegisterMod(CT_BUFFMOD_MODNAME_DEBUFF, CT_BUFFMOD_MODNAME_SUB_DEBUFF, 4, "Interface\\Icons\\Spell_Holy_SealOfSacrifice", CT_BUFFMOD_MODNAME_TOOLTIP_DEBUFF, "off", nil, debuffnamesfunction, debuffnamesinitfunction);

function CT_BuffMod_RecastLastBuff()
	local buff = CT_BuffMod_GetExpiredBuff();
	if ( buff and CT_PlayerSpells[buff] ) then
		if ( CT_PlayerSpells[buff] ) then
			CT_BuffMod_LastCastSpell = buff;
			CT_BuffMod_LastCast = GetTime();
			if ( UnitExists("target") and UnitIsFriend("player", "target") ) then
				TargetUnit("player");
			end
			CastSpell(CT_PlayerSpells[buff]["spell"], CT_PlayerSpells[buff]["tab"]+1);
			if ( SpellIsTargeting() and SpellCanTargetUnit("player") ) then
				SpellTargetUnit("player");
			end
		end
	end
end

function CT_BuffButton_OnEnter()
	if ( this:GetCenter() < UIParent:GetCenter() ) then
		GameTooltip:SetOwner(this, "ANCHOR_RIGHT");
	else
		GameTooltip:SetOwner(this, "ANCHOR_LEFT");
	end
	GameTooltip:SetPlayerBuff(this.buffIndex);
end

function CT_BuffMod_AddToQueue(name)
	local hKey = 0;
	local hVal = 0;
	for key, val in CT_LastExpiredBuffs do
		if ( val > hVal ) then
			hKey = key; hVal = val;
		end
	end
	if ( hKey == name ) then return; end
	
	CT_LastExpiredBuffs[name] = hVal+1;
end

function CT_BuffMod_GetExpiredBuff()
	local hKey = 0;
	local hVal = 0;
	for key, val in CT_LastExpiredBuffs do
		if ( val > hVal ) then
			hKey = key; hVal = val;
		end
	end
	if ( hKey ~= 0 and hVal ~= 0 ) then
		CT_LastExpiredBuffs[hKey] = nil;
		return hKey;
	else
		return nil;
	end
end

function CT_BuffMod_OnEvent(event)
	if ( CT_BuffMod_LastCast and (GetTime()-CT_BuffMod_LastCast) <= 0.1 ) then
		CT_BuffMod_AddToQueue(CT_BuffMod_LastCastSpell);
		CT_BuffMod_LastCast = nil;
		CT_BuffMod_LastCastSpell = nil;
	end
end

 function BuffModResetFunction()
	if ( CT_BuffMod_BuffSides == "LEFT" ) then
		CT_Buffs_SwapSides();
	end
end

ChirpFunction = function(modId)
	local val = CT_Mods[modId]["modStatus"];
	if ( val == "off" ) then
		CT_Print(CT_BUFFMOD_OFF_CHIRP, 1, 1, 0);
		CT_PlaySound = 0;
	else
		CT_Print(CT_BUFFMOD_ON_CHIRP, 1, 1, 0);
		CT_PlaySound = 1;
	end
end

ChirpInitFunction = function(modId)
	local val = CT_Mods[modId]["modStatus"];
	if ( val == "off" ) then
		CT_PlaySound = 0;
	else
		CT_PlaySound = 1;
	end
end

CT_RegisterMod(CT_BUFFMOD_MODNAME_SOUND, CT_BUFFMOD_SUB_SOUND, 4, "Interface\\Icons\\INV_Misc_Bell_01", CT_BUFFMOD_TOOLTIP_SOUND, "off", nil, ChirpFunction, ChirpInitFunction);