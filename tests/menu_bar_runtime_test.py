#!/usr/bin/env python3
"""Execute the Dominos menu bar against a WoW 3.3.5-style Lua UI double."""

from pathlib import Path

try:
    from lupa.lua51 import LuaRuntime
except ImportError:
    print("menu_bar_runtime: SKIP (lupa.lua51 unavailable)")
    raise SystemExit(0)


root = Path(__file__).resolve().parents[1]
lua = LuaRuntime()
lua.execute(r'''
local function Button(name, predecessor)
 local button={name=name,predecessor=predecessor,width=28,height=58,shown=false}
 function button:GetName() return self.name end
 function button:GetNumPoints() return self.predecessor and 1 or 0 end
 function button:GetPoint() return "LEFT",self.predecessor,"RIGHT",-3,0 end
 function button:SetParent(parent) self.parent=parent end
 function button:Show() self.shown=true end
 function button:Hide() self.shown=false end
 function button:ClearAllPoints() self.point=nil end
 function button:SetPoint(...) self.point={...} end
 function button:GetWidth() return self.width end
 function button:GetHeight() return self.height end
 function button:SetScript() end
 function button:UnregisterAllEvents() end
 function button:RegisterEvent() end
 return button
end

CharacterMicroButton=Button("CharacterMicroButton")
LFDMicroButton=Button("LFDMicroButton",CharacterMicroButton)
ContentExtensionMicroButton=Button("ContentExtensionMicroButton",LFDMicroButton)
MainMenuMicroButton=Button("MainMenuMicroButton",ContentExtensionMicroButton)
HelpMicroButton=Button("HelpMicroButton",MainMenuMicroButton)
-- GetChildren returns creation order: the native extension was created last.
MainMenuBarArtFrame={GetChildren=function()
 return CharacterMicroButton,LFDMicroButton,MainMenuMicroButton,
        HelpMicroButton,ContentExtensionMicroButton
end}

TalentMicroButton=Button("TalentMicroButton")
AchievementMicroButton=Button("AchievementMicroButton")
CharacterFrame={IsShown=function() return false end}
function UnitCharacterPoints() return 0 end
function SetButtonPulse() end
function MicroButtonTooltipText(text) return text end
TALENTS_BUTTON="Talents"

min, max, ceil = math.min, math.max, math.ceil
Dominos={}
Dominos.Frame={}
function Dominos.Frame.New(class,id)
 local frame=setmetatable({id=id,buttons={},sets={columns=1},header={}}, {__index=class})
 return frame
end
function Dominos.Frame.LoadButtons(self)
 for i=1,self:NumButtons() do self:AddButton(i) end
end
function Dominos.Frame.NumColumns(self) return self.sets.columns or self:NumButtons() end
function Dominos.Frame.GetPadding() return 0,0 end
function Dominos.Frame.GetSpacing() return 0,0 end
function Dominos.Frame.SetWidth(self,width) self.width=width end
function Dominos.Frame.SetHeight(self,height) self.height=height end
function Dominos:CreateClass(_,parent)
 local class=setmetatable({}, {__index=parent})
 class.__index=class
 class.super=parent
 return class
end
''')
lua.execute((root / "Dominos/modules/menuBar.lua").read_text(encoding="utf-8"))
lua.execute(r'''
local bar=Dominos.MenuBar:New()
assert(bar:NumButtons()==5)
assert(bar.buttons[1]==CharacterMicroButton)
assert(bar.buttons[2]==LFDMicroButton)
assert(bar.buttons[3]==ContentExtensionMicroButton)
assert(bar.buttons[4]==MainMenuMicroButton)
assert(bar.buttons[5]==HelpMicroButton)
assert(ContentExtensionMicroButton.parent==bar.header)
assert(ContentExtensionMicroButton.point[1]=="TOPLEFT")
assert(MainMenuMicroButton.point[1]=="TOPLEFT")
assert(bar.sets.columns==1)
''')
print("menu_bar_runtime: PASS")
