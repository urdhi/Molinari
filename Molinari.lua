local button = CreateFrame('Button', 'Molinari', UIParent, 'SecureActionButtonTemplate, AutoCastShineTemplate')
button:RegisterForClicks('LeftButtonUp')
button:SetAttribute('*type*', 'macro')
button:Hide()

for _, spark in pairs(button.sparkles) do
	spark:SetHeight(spark:GetHeight() * 3)
	spark:SetWidth(spark:GetWidth() * 3)
end

button:RegisterEvent('PLAYER_LOGIN')
button:RegisterEvent('MODIFIER_STATE_CHANGED')
button:SetScript('OnEvent', function(self, event, ...) self[event](self, event, ...) end)
button:SetScript('OnLeave', function(self)
	if(InCombatLockdown()) then
		self:RegisterEvent('PLAYER_REGEN_ENABLED')
	else
		self:Hide()
		AutoCastShine_AutoCastStop(self)
	end
end)

local macro = '/cast %s\n/use %s %s'
local spells = {}

function button:MODIFIER_STATE_CHANGED(event, key)
	if(self:IsShown() and (key == 'LALT' or key == 'RALT')) then
		self:GetScript('OnLeave')(self)
	end
end

function button:PLAYER_REGEN_ENABLED(event)
	self:UnregisterEvent(event)
	self:GetScript('OnLeave')(self)
end

local function Disenchantable(item)
	local _, _, quality, _, _, type = GetItemInfo(item)
	if ((type == ARMOR or type == ENCHSLOT_WEAPON) and quality > 1 and quality < 5) then
		return GetSpellInfo(13262), 0.5, 0.5, 1
	end
end

local function ScanTooltip()
	for index = 1, GameTooltip:NumLines() do
		local info = spells[_G['GameTooltipTextLeft'..index]:GetText()]
		if(info) then
			return unpack(info)
		end
	end
end

local function Clickable()
	return (not IsAddOnLoaded('Blizzard_AuctionUI') or (AuctionFrame and not AuctionFrame:IsShown())) and not TradeFrame:IsShown() and not BankFrame:IsShown() and not MailFrame:IsShown() and not InCombatLockdown() and IsAltKeyDown()
end

GameTooltip:HookScript('OnTooltipSetItem', function(self)
	local item = self:GetItem()
	if(item and Clickable()) then
		local spell, r, g, b = ScanTooltip()
		if(not spell) then
			spell, r, g, b = Disenchantable(item)
		end

		if(spell) then
			local slot = GetMouseFocus()
			button:SetAttribute('macrotext', macro:format(spell, slot:GetParent():GetID(), slot:GetID()))
			button:SetAllPoints(slot)
			button:SetParent(slot)
			button:Show()
			AutoCastShine_AutoCastStart(button, r, g, b)
		end
	end
end)

function button:PLAYER_LOGIN()
	if(IsSpellKnown(51005)) then
		spells[ITEM_MILLABLE] = {GetSpellInfo(51005), 0.5, 1, 0.5}
	end
	if(IsSpellKnown(31252)) then
		spells[ITEM_PROSPECTABLE] = {GetSpellInfo(31252), 1, 0.5, 0.5}
	end
	if(not IsSpellKnown(13262)) then
		Disenchantable = function() end
	end
end
