assert(Dominos, "Dominos not found!")
local Dominos = Dominos

--[[
local menuButtons = {
	CharacterMicroButton,
	SpellbookMicroButton,
	TalentMicroButton,
	AchievementMicroButton,
	QuestLogMicroButton,
	SocialsMicroButton,
	PVPMicroButton,
	LFDMicroButton,
	MainMenuMicroButton,
	HelpMicroButton
}
--]]
local menuButtons
do
	local loadButtons = function(...)
		menuButtons = {}
		local discovered = {}
		local isMenuButton = {}

		for i = 1, select("#", ...) do
			local b = select(i, ...)
			local name = b:GetName()
			if name and name:match("(%w+)MicroButton$") then
				table.insert(discovered, b)
				isMenuButton[b] = true
			end
		end

		-- GetChildren() normally returns the stock buttons in layout order, but
		-- native UI extensions are created later and therefore appear at the end
		-- of that list.  Follow their existing anchor chain so an extension
		-- inserted between two stock buttons keeps that position under Dominos.
		local predecessor = {}
		for _, b in ipairs(discovered) do
			for point = 1, b:GetNumPoints() do
				local _, relativeTo = b:GetPoint(point)
				if isMenuButton[relativeTo] then
					predecessor[b] = relativeTo
					break
				end
			end
		end

		local added = {}
		local remaining = #discovered
		while remaining > 0 do
			local progressed
			for _, b in ipairs(discovered) do
				if not added[b] and (not predecessor[b] or added[predecessor[b]]) then
					table.insert(menuButtons, b)
					added[b] = true
					remaining = remaining - 1
					progressed = true
				end
			end

			-- Preserve discovery order for malformed or cyclic third-party anchors.
			if not progressed then
				for _, b in ipairs(discovered) do
					if not added[b] then
						table.insert(menuButtons, b)
						added[b] = true
						remaining = remaining - 1
					end
				end
			end
		end
	end
	loadButtons(_G["MainMenuBarArtFrame"]:GetChildren())
end

do
	TalentMicroButton:SetScript("OnEvent", function(self, event)
		if (event == "PLAYER_LEVEL_UP" or event == "PLAYER_LOGIN") then
			if UnitCharacterPoints("player") > 0 and not CharacterFrame:IsShown() then
				SetButtonPulse(self, 60, 1)
			end
		elseif event == "UPDATE_BINDINGS" then
			self.tooltipText = MicroButtonTooltipText(TALENTS_BUTTON, "TOGGLETALENTS")
		end
	end)
	TalentMicroButton:UnregisterAllEvents()
	TalentMicroButton:RegisterEvent("PLAYER_LEVEL_UP")
	TalentMicroButton:RegisterEvent("PLAYER_LOGIN")
	TalentMicroButton:RegisterEvent("UPDATE_BINDINGS")

	--simialr thing, but the achievement button
	AchievementMicroButton:UnregisterAllEvents()
end

--[[ Menu Bar ]]
local MenuBar = Dominos:CreateClass("Frame", Dominos.Frame)
Dominos.MenuBar = MenuBar

function MenuBar:New()
	local f = self.super.New(self, "menu")
	f:LoadButtons()
	f:Layout()

	return f
end

function MenuBar:GetDefaults()
	return {point = "BOTTOMRIGHT", x = -244, y = 0}
end

function MenuBar:NumButtons()
	return #menuButtons
end

function MenuBar:AddButton(i)
	local b = menuButtons[i]
	if b then
		b:SetParent(self.header)
		b:Show()

		self.buttons[i] = b
	end
end

function MenuBar:RemoveButton(i)
	local b = self.buttons[i]
	if b then
		b:SetParent(nil)
		b:Hide()

		self.buttons[i] = nil
	end
end

--override, because the menu bar has weird button sizes
local WIDTH_OFFSET = 2
local HEIGHT_OFFSET = 20

function MenuBar:Layout()
	if #self.buttons > 0 then
		local cols = min(self:NumColumns(), #self.buttons)
		local rows = ceil(#self.buttons / cols)
		local pW, pH = self:GetPadding()
		local spacing = self:GetSpacing()

		local b = self.buttons[1]
		local w = b:GetWidth() + spacing - WIDTH_OFFSET
		local h = b:GetHeight() + spacing - HEIGHT_OFFSET

		for i, btn in pairs(self.buttons) do
			local col = (i - 1) % cols
			local row = ceil(i / cols) - 1
			btn:ClearAllPoints()
			btn:SetPoint("TOPLEFT", w * col + pW, -(h * row + pH) + HEIGHT_OFFSET)
		end

		self:SetWidth(max(w * cols - spacing + pW * 2 + WIDTH_OFFSET, 8))
		self:SetHeight(max(h * ceil(#self.buttons / cols) - spacing + pH * 2, 8))
	else
		self:SetWidth(30)
		self:SetHeight(30)
	end
end
