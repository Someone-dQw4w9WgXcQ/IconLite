--!strict

local Icon = {}
Icon.__index = Icon

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Signal"))

local topbarGui = Instance.new("ScreenGui")
topbarGui.DisplayOrder = 0
topbarGui.IgnoreGuiInset = true
topbarGui.ResetOnSpawn = false
topbarGui.Name = "Topbar"
topbarGui.Enabled = true

local playerChatEnabled = true
local playerListEnabled = true

local function calculateLeftPosition()
	if playerChatEnabled then
		return UDim2.new(0,
			44 -- Roblox icon
				+ 44 -- Chat icon
				+ 16, -- Padding from edge of screen
			0, 0
		)
	else
		return UDim2.new(0,
			44 -- Roblox icon
				+ 16, -- Padding from edge of screen
			0, 0
		)
	end
end

local function calculateRightPosition()
	if playerListEnabled then
		return UDim2.new(1,
			-44 -- Player list icon
			-16, -- Padding from edge of screen
			0, 0
		)
	else
		return UDim2.new(1,
			-16, -- Padding from edge of screen
			0, 0
		)
	end
end

local function newAligned(alignment: Enum.HorizontalAlignment)
	local iconContainer = Instance.new("Frame")
	iconContainer.BackgroundTransparency = 1
	iconContainer.Visible = true
	iconContainer.ZIndex = 1
	if alignment == Enum.HorizontalAlignment.Left then
		iconContainer.Position = calculateLeftPosition()
	elseif alignment == Enum.HorizontalAlignment.Right then
		iconContainer.AnchorPoint = Vector2.new(1, 0)
		iconContainer.Position = calculateRightPosition()
	else
		iconContainer.AnchorPoint = Vector2.new(0.5, 0)
		iconContainer.Position = UDim2.new(0.5, 0, 0, 0)
	end
	iconContainer.Size = UDim2.new(1/3, -16, 0, 36)
	iconContainer.Active = false

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = alignment
	layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 12)

	layout.Parent = iconContainer
	iconContainer.Parent = topbarGui
	return iconContainer
end
local aligned = {}
for _, alignment in Enum.HorizontalAlignment:GetEnumItems() do
	aligned[alignment] = newAligned(alignment)
end
task.spawn(function()
	while true do
		local success, result = pcall(StarterGui.GetCoreGuiEnabled, StarterGui, Enum.CoreGuiType.Chat)
		if success then
			if result ~= playerChatEnabled then
				playerChatEnabled = result
				aligned[Enum.HorizontalAlignment.Left].Position = calculateLeftPosition()
			end
		else
			warn(result)
		end

		local success, result = pcall(StarterGui.GetCoreGuiEnabled, StarterGui, Enum.CoreGuiType.PlayerList)
		if success then
			if result ~= playerListEnabled then
				playerListEnabled = result
				aligned[Enum.HorizontalAlignment.Right].Position = calculateRightPosition()
			end
		else
			warn(result)
		end

		task.wait(0.5)
	end
end)

topbarGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local size = UDim2.fromOffset(32, 32)
function Icon.new()	
	local image = Instance.new("ImageButton")
	image.Name = "Icon"
	image.Visible = true
	image.ZIndex = 69
	image.BorderSizePixel = 0
	image.AutoButtonColor = true
	image.Active = true
	image.Size = size
	image.AutomaticSize = Enum.AutomaticSize.X
	image.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	image.BackgroundTransparency = 0.5
	image.Transparency = 0.5

	Instance.new("UICorner", image)

	local label = Instance.new("TextLabel")
	label.Text = ""
	label.Font = Enum.Font.Gotham
	label.TextScaled = true
	label.ZIndex = 70
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.AutomaticSize = Enum.AutomaticSize.X
	label.Position = UDim2.fromScale(0.5, 0.5)
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Active = false
	label.Parent = image

	image.Parent = aligned[Enum.HorizontalAlignment.Left]

	local keybinds = {}

	local self = setmetatable({
		image = image,
		textLabel = label,
		size = size,

		keybinds = keybinds,

		_selected = false,
		Selected = Signal.new(),
		Deselected = Signal.new()
	}, Icon)

	image.Activated:Connect(function()
		self:Toggle()
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if keybinds[input.KeyCode] then
			self:Toggle()
		end
	end)

	return self
end

function Icon:BindToggleItem(gui: GuiBase)
	local property = "Enabled"
	if gui:IsA("GuiObject") then
		property = "Visible"
	end
	gui[property] = self._selected
	self.Selected:Connect(function()
		gui[property] = true
	end)
	self.Deselected:Connect(function()
		gui[property] = false
	end)
end

function Icon:SetIconVisibility(visible: boolean)
	self.image.Visible = visible
	self.textLabel.Visible = visible
end

function Icon:SetSize(size: UDim2)
	self.image.Size = size
	self.image.AutomaticSize = Enum.AutomaticSize.None

	self.textLabel.AutomaticSize = Enum.AutomaticSize.None
end

function Icon:Deselect()
	self._selected = false
	self.Deselected:Fire()
end

function Icon:Select()
	self._selected = true
	self.Selected:Fire()
end

function Icon:Toggle(on: boolean?)
	if on == self._selected then
		return
	end
	local on = if on ~= nil then on else not self._selected
	self._selected = on
	if on then
		self:Select()
	else
		self:Deselect()
	end
end

function Icon:SetAlignment(alignment: Enum.HorizontalAlignment)
	self.image.Parent = aligned[alignment]
end

function Icon:SetOrder(order: number)
	self.image.LayoutOrder = order
end

function Icon:SetImage(image: string)
	self.image.Image = image
end

function Icon:SetText(text: string)
	self.textLabel.Text = text
end

function Icon:BindToggleKey(key: Enum.KeyCode)
	self.keybinds[key] = true
end

function Icon:UnbindToggleKey(key: Enum.KeyCode)
	self.keybinds[key] = nil
end

function Icon:Destroy()
	self.image:Destroy()
	self.textLabel:Destroy()
	table.clear(self)
	setmetatable(self, nil)
end

return Icon
