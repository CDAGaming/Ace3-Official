--[[-----------------------------------------------------------------------------
Keybinding Widget
Set Keybindings in the Config UI.
-------------------------------------------------------------------------------]]
local Type, Version = "Keybinding", 26
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local pairs = pairs

-- WoW APIs
local IsShiftKeyDown, IsControlKeyDown, IsAltKeyDown = IsShiftKeyDown, IsControlKeyDown, IsAltKeyDown
local CreateFrame, UIParent = CreateFrame, UIParent

local wowMoP, wowClassicRebased, wowTBCRebased, wowWrathRebased, wowCataRebased
do
	local _, build, _, interface = GetBuildInfo()
	interface = interface or tonumber(build)
	wowMoP = (interface >= 50000)
	wowClassicRebased = (interface >= 11300 and interface < 20000)
	wowTBCRebased = (interface >= 20500 and interface < 30000)
	wowWrathRebased = (interface >= 30400 and interface < 40000)
	wowCataRebased = (interface >= 40400 and interface < 50000)
end

--[[-----------------------------------------------------------------------------
Scripts
-------------------------------------------------------------------------------]]

local function Control_OnEnter(frame)
	frame = frame or this
	frame.obj:Fire("OnEnter")
end

local function Control_OnLeave(frame)
	frame = frame or this
	frame.obj:Fire("OnLeave")
end

local function Keybinding_OnClick(frame, button)
	frame = frame or this
	button = button or arg1
	if button == "LeftButton" or button == "RightButton" then
		local self = frame.obj
		if self.waitingForKey then
			frame:EnableKeyboard(false)
			frame:EnableMouseWheel(false)
			self.msgframe:Hide()
			frame:UnlockHighlight()
			self.waitingForKey = nil
		else
			frame:EnableKeyboard(true)
			frame:EnableMouseWheel(true)
			self.msgframe:Show()
			frame:LockHighlight()
			self.waitingForKey = true
		end
	end
	AceGUI:ClearFocus()
end

local ignoreKeys = {
	["BUTTON1"] = true, ["BUTTON2"] = true,
	["UNKNOWN"] = true,
	["LSHIFT"] = true, ["LCTRL"] = true, ["LALT"] = true,
	["RSHIFT"] = true, ["RCTRL"] = true, ["RALT"] = true,
}
local function Keybinding_OnKeyDown(frame, key)
	frame = frame or this
	key = key or arg1
	local self = frame.obj
	if self.waitingForKey then
		local keyPressed = key
		if keyPressed == "ESCAPE" then
			keyPressed = ""
		else
			if ignoreKeys[keyPressed] then return end
			if IsShiftKeyDown() then
				keyPressed = "SHIFT-"..keyPressed
			end
			if IsControlKeyDown() then
				keyPressed = "CTRL-"..keyPressed
			end
			if IsAltKeyDown() then
				keyPressed = "ALT-"..keyPressed
			end
		end

		frame:EnableKeyboard(false)
		frame:EnableMouseWheel(false)
		self.msgframe:Hide()
		frame:UnlockHighlight()
		self.waitingForKey = nil

		if not self.disabled then
			self:SetKey(keyPressed)
			self:Fire("OnKeyChanged", keyPressed)
		end
	end
end

local function Keybinding_OnMouseDown(frame, button)
	frame = frame or this
	button = button or arg1
	if button == "LeftButton" or button == "RightButton" then
		return
	elseif button == "MiddleButton" then
		button = "BUTTON3"
	elseif button == "Button4" then
		button = "BUTTON4"
	elseif button == "Button5" then
		button = "BUTTON5"
	end
	Keybinding_OnKeyDown(frame, button)
end

local function Keybinding_OnMouseWheel(frame, direction)
	frame = frame or this
	direction = direction or arg1
	local button
	if direction >= 0 then
		button = "MOUSEWHEELUP"
	else
		button = "MOUSEWHEELDOWN"
	end
	Keybinding_OnKeyDown(frame, button)
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
	["OnAcquire"] = function(self)
		self:SetWidth(200)
		self:SetLabel("")
		self:SetKey("")
		self.waitingForKey = nil
		self.msgframe:Hide()
		self:SetDisabled(false)
		self.button:EnableKeyboard(false)
		self.button:EnableMouseWheel(false)
	end,

	-- ["OnRelease"] = nil,

	["SetDisabled"] = function(self, disabled)
		self.disabled = disabled
		if disabled then
			self.button:Disable()
			self.label:SetTextColor(0.5,0.5,0.5)
		else
			self.button:Enable()
			self.label:SetTextColor(1,1,1)
		end
	end,

	["SetKey"] = function(self, key)
		if (key or "") == "" then
			self.button:SetText(NOT_BOUND)
			if self.button.SetNormalFontObject then
				self.button:SetNormalFontObject("GameFontNormal")
			elseif self.button.SetTextFontObject then
				self.button:SetTextFontObject("GameFontNormal")
			else
				self.button:SetFontObject("GameFontNormal")
			end
		else
			self.button:SetText(key)
			if self.button.SetNormalFontObject then
				self.button:SetNormalFontObject("GameFontHighlight")
			elseif self.button.SetTextFontObject then
				self.button:SetTextFontObject("GameFontHighlight")
			else
				self.button:SetFontObject("GameFontHighlight")
			end
		end
	end,

	["GetKey"] = function(self)
		local key = self.button:GetText()
		if key == NOT_BOUND then
			key = nil
		end
		return key
	end,

	["SetLabel"] = function(self, label)
		self.label:SetText(label or "")
		if (label or "") == "" then
			self.alignoffset = nil
			self:SetHeight(24)
		else
			self.alignoffset = 30
			self:SetHeight(44)
		end
	end,
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]

local ControlBackdrop  = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 16,
	insets = { left = 3, right = 3, top = 3, bottom = 3 }
}

local function keybindingMsgFixWidth(frame)
	frame = frame or this
	frame:SetWidth(frame.msg:GetWidth() + 10)
	frame:SetScript("OnUpdate", nil)
end

local function Constructor()
	local name = "AceGUI30KeybindingButton" .. AceGUI:GetNextWidgetNum(Type)

	local frame = CreateFrame("Frame", nil, UIParent)
	local button = CreateFrame("Button", name, frame, (wowMoP or wowClassicRebased or wowTBCRebased or wowWrathRebased or wowCataRebased) and "UIPanelButtonTemplate" or "UIPanelButtonTemplate2")

	button:EnableMouse(true)
	button:EnableMouseWheel(false)
	button:RegisterForClicks("AnyDown")
	button:SetScript("OnEnter", Control_OnEnter)
	button:SetScript("OnLeave", Control_OnLeave)
	button:SetScript("OnClick", Keybinding_OnClick)
	button:SetScript("OnKeyDown", Keybinding_OnKeyDown)
	button:SetScript("OnMouseDown", Keybinding_OnMouseDown)
	button:SetScript("OnMouseWheel", Keybinding_OnMouseWheel)
	button:SetPoint("BOTTOMLEFT", 0, 0)
	button:SetPoint("BOTTOMRIGHT", 0, 0)
	button:SetHeight(24)
	button:EnableKeyboard(false)

	local text = button:GetFontString()
	text:SetPoint("LEFT", 7, 0)
	text:SetPoint("RIGHT", -7, 0)

	local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	label:SetPoint("TOPLEFT", 0, 0)
	label:SetPoint("TOPRIGHT", 0, 0)
	label:SetJustifyH("CENTER")
	label:SetHeight(18)

	local msgframe = CreateFrame("Frame", nil, UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
	msgframe:SetHeight(30)
	msgframe:SetBackdrop(ControlBackdrop)
	msgframe:SetBackdropColor(0,0,0)
	msgframe:SetFrameStrata("FULLSCREEN_DIALOG")
	msgframe:SetFrameLevel(1000)
	msgframe:SetToplevel(true)

	local msg = msgframe:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	msg:SetText("Press a key to bind, ESC to clear the binding or click the button again to cancel.")
	msgframe.msg = msg
	msg:SetPoint("TOPLEFT", 5, -5)
	msgframe:SetScript("OnUpdate", keybindingMsgFixWidth)
	msgframe:SetPoint("BOTTOM", button, "TOP")
	msgframe:Hide()

	local widget = {
		button      = button,
		label       = label,
		msgframe    = msgframe,
		frame       = frame,
		alignoffset = 30,
		type        = Type
	}
	for method, func in pairs(methods) do
		widget[method] = func
	end
	button.obj = widget

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
