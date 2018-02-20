
-- Copyright (C) 2017-2018 DBot

-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at

--     http://www.apache.org/licenses/LICENSE-2.0

-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

local vgui = vgui
local hook = hook
local IsValid = IsValid
local DLib = DLib
local RealTime = RealTime
local color_white = color_white
local Color = Color
local color_dlib = color_dlib
local tonumber = tonumber

local PANEL = {}
DLib.VGUI.TextEntry = PANEL

surface.CreateFont('DLib_TextEntry', {
	font = 'PT Serif',
	size = 16,
	weight = 500,
	extended = true
})

function PANEL:Init()
	self:SetText('')
	self:SetKeyboardInputEnabled(true)
	self:SetMouseInputEnabled(true)
	self:SetFont('DLib_TextEntry')
end

function PANEL:OnEnter(value)

end

function PANEL:OnKeyCodeTyped(key)
	if key == KEY_FIRST or key == KEY_NONE or key == KEY_TAB then
		return true
	elseif key == KEY_ENTER then
		self:OnEnter((self:GetValue() or ''):Trim())
		self:KillFocus()
		return true
	end

	if DTextEntry.OnKeyCodeTyped then
		return DTextEntry.OnKeyCodeTyped(self, key)
	end

	return false
end

function PANEL:GetValueBeforeCaret()
	local value = self:GetValue() or ''
	return value:sub(1, self:GetCaretPos())
end

function PANEL:GetValueAfterCaret()
	local value = self:GetValue() or ''
	return value:sub(self:GetCaretPos() + 1)
end

vgui.Register('DLib_TextEntry', PANEL, 'DTextEntry')
local TEXTENTRY = PANEL

PANEL = {}
DLib.VGUI.TextEntry_Configurable = PANEL

DLib.util.AccessorFuncJIT(PANEL, 'lengthLimit', 'LengthLimit')
DLib.util.AccessorFuncJIT(PANEL, 'tooltipTime', 'TooltipTime')
DLib.util.AccessorFuncJIT(PANEL, 'tooltip', 'TooltipShown')
DLib.util.AccessorFuncJIT(PANEL, 'whitelistMode', 'IsWhitelistMode')
DLib.util.AccessorFuncJIT(PANEL, 'disallowed', 'DisallowedHashSet')
DLib.util.AccessorFuncJIT(PANEL, 'allowed', 'AllowedHashSet')
DLib.util.AccessorFuncJIT(PANEL, 'defaultReason', 'DefaultReason')

function PANEL:Init()
	self.allowed = DLib.HashSet()
	self.disallowedMap = DLib.HashSet()
	self.whitelistMode = false
	self.tooltipTime = 0
	self.tooltip = false
	self.lengthLimit = 0
	self.tooltipReason = 'Not allowed symbol.'
	self.defaultReason = 'Not allowed symbol.'

	hook.Add('PostRenderVGUI', self, self.PostRenderVGUI)
end

function PANEL:OnKeyCodeTyped(key)
	local reply = TEXTENTRY.OnKeyCodeTyped(self, key)
	if reply == false then return reply end

	if self.whitelistMode then
		if not self.allowed:has(key) then
			self:Ding()
			return false
		end
	else
		if self.disallowed:has(key) then
			self:Ding()
			return false
		end
	end

	if self.lengthLimit > 0 and #(self:GetValue() or '') + 1 > self.lengthLimit then
		self:Ding('Field limit exceeded')
		return
	end

	return true
end

function PANEL:AddToBlacklist(value)
	return self.disallowed:add(value)
end

function PANEL:AddToWhitelist(value)
	return self.allowed:add(value)
end

function PANEL:RemoveFromBlacklist(value)
	return self.disallowed:remove(value)
end

function PANEL:RemoveFromWhitelist(value)
	return self.allowed:remove(value)
end

function PANEL:InBlacklist(value)
	return self.disallowed:has(value)
end

function PANEL:InWhitelist(value)
	return self.allowed:add(value)
end

function PANEL:Ding(reason)
	reason = reason or self.defaultReason
	self.tooltipReason = reason

	if self.tooltipTime - 0.95 > RealTime() then
		self.tooltipTime = RealTime() + 1
		self.tooltip = true
		return
	end

	self.tooltipTime = RealTime() + 1
	surface.PlaySound('resource/warning.wav')
	self.tooltip = true
end

surface.CreateFont('DLib_TextEntry_Warning', {
	font = 'Open Sans',
	size = 20,
	weight = 500
})

function PANEL:PostRenderVGUI()
	if not IsValid(self) then return end
	if not self.tooltip then return end
	local time = RealTime()

	if self.tooltipTime < time then
		self.tooltip = false
		return
	end

	local x, y = self:LocalToScreen(0, 0)
	local w, h = self:GetSize()

	y = y + h + 2
	local fade = math.min(1, (self.tooltipTime - time) * 1.25 + 0.3)

	surface.SetDrawColor(color_dlib)
	DLib.HUDCommons.DrawTriangle(x + 3, y, 15, 20)
	DLib.HUDCommons.WordBox(self.tooltipReason, 'DLib_TextEntry_Warning', x, y + 20, color_white)
end

vgui.Register('DLib_TextEntry_Configurable', PANEL, 'DLib_TextEntry')

local TEXTENTRY_CUSTOM = PANEL
PANEL = {}
DLib.VGUI.TextEntry_Number = PANEL
DLib.util.AccessorFuncJIT(PANEL, 'defaultNumber', 'DefaultNumber')
DLib.util.AccessorFuncJIT(PANEL, 'allowFloats', 'IsFloatAllowed')
DLib.util.AccessorFuncJIT(PANEL, 'allowNegative', 'IsNegativeValueAllowed')

function PANEL:Init()
	self:SetIsWhitelistMode(true)
	self:SetDefaultReason('Only numbers are allowed.')
	self.defaultNumber = 0
	self.allowFloats = true
	self.allowNegative = true

	for i, number in ipairs(DLib.KeyMap.NUMBERS_LIST) do
		self:AddToWhitelist(number)
	end
end

function PANEL:GetNumber()
	return tonumber(self:GetValue() or '') or self.self.defaultNumber
end

function PANEL:OnKeyCodeTyped(key)
	local reply = TEXTENTRY_CUSTOM.OnKeyCodeTyped(self, key)
	if reply == false then return reply end

	if not self.allowNegative and (key == KEY_MINUS or key == KEY_PAD_MINUS) then
		self:Ding('Negative values are not allowed here')
		return
	end

	if not self.allowFloats and (key == KEY_PAD_DECIMAL) then
		self:Ding('Floating point values are not allowed here')
		return
	end

	local value1 = self:GetValueBeforeCaret()
	local value2 = self:GetValueAfterCaret()
	local char = DLib.KeyMap.KEY[value]

	if char and not tonumber(value1 .. char .. value2) then
		self:Ding('Inputting ' .. char .. ' here will mangle the current value')
		return false
	end

	return true
end

vgui.Register('DLib_TextEntry_Number', PANEL, 'DLib_TextEntry_Configurable')
