local Library = loadstring(game:HttpGet('https://raw.githubusercontent.com/Loco-CTO/UI-Library/main/VisionLibV2/source.lua'))()

Window = Library:Create({
	Name = "Vision UI Lib v2",
	Footer = "By Loco_CTO, Sius and BruhOOFBoi",
	ToggleKey = Enum.KeyCode.RightShift,
	LoadedCallback = function()
		Window:TaskBarOnly(false)
	end,
	KeySystem = false,
	Key = "123456",
	MaxAttempts = 5,
	DiscordLink = nil,
})

Window:ChangeTogglekey(Enum.KeyCode.RightShift)

local Tab = Window:Tab({
	Name = "Main",
	-- Icon = "rbxassetid://11396131982",
	Color = Color3.new(1, 0, 0)
})

local Section1 = Tab:Section({
	Name = "Basic controls"
})

local Label = Section1:Label({
	Name = "Lame\nTest",
})

Label:SetName("LMAOOOOOOOO\n\n\n\n\nXD")

local Label = Section1:Label({
	Name = "Holy jesus loco is so handsome because i said so and he have not got a girlfriend what a shamelss sucker but idk i wanna have fun but minecraft doesnt let me",
})

local Button = Section1:Button({
	Name = "Real Button",
	Callback = function()
		Library:Notify({
			Name = "Button",
			Text = "Clicked",
			Icon = "rbxassetid://11401835376",
			Duration = 3
		})
	end
})

local Toggle = Section1:Toggle({
	Name = "Real Toggle",
	Default = false,
	Callback = function(Bool)
		Library:Notify({
			Name = "Toggle",
			Text = tostring(Bool),
			Icon = "rbxassetid://11401835376",
			Duration = 3
		})
	end
})

local Section2 = Tab:Section({
	Name = "Advance controls"
})

local Slider = Section2:Slider({
	Name = "Real Slider",
	Max = 50,
	Min = 0,
	Default = 25,
	Callback = function(Number)
		Library:Notify({
			Name = "Slider",
			Text = tostring(Number),
			Icon = "rbxassetid://11401835376",
			Duration = 3
		})
	end
})

local Slider = Section2:Slider({
	Name = "Real Slider",
	Max = 50,
	Min = 0,
	Default = 25,
	Callback = function(Number)
		Library:Notify({
			Name = "Slider",
			Text = tostring(Number),
			Icon = "rbxassetid://11401835376",
			Duration = 3
		})
	end
})

local Keybind = Section2:Keybind({
	Name = "Real Keybind",
	Default = Enum.KeyCode.Return,
	Callback = function()
		Library:Notify({
			Name = "Keybind pressed",
			Text = "Idk sth here",
			Icon = "rbxassetid://11401835376",
			Duration = 3,
		})
	end,
	UpdateKeyCallback = function(Key)
		Library:Notify({
			Name = "Keybind updated",
			Text = tostring(Key),
			Icon = "rbxassetid://11401835376",
			Duration = 3,
		})
	end
})

local SmallTextbox = Section2:SmallTextbox({
	Name = "Real Small Textbox",
	Default = "Default Text",
	Callback = function(Text)
		Library:Notify({
			Name = "Small Textbox updated",
			Text = Text,
			Icon = "rbxassetid://11401835376",
			Duration = 3,
		})
	end
})

local Dropdown = Section2:Dropdown({
	Name = "Real Dropdown",
	Items = {1, 2, 3, 4, "XD"},
	Callback = function(item)
		Library:Notify({
			Name = "Dropdown",
			Text = item,
			Icon = "rbxassetid://11401835376",
			Duration = 3,
		})
	end
})

local Button = Section2:Button({
	Name = "Clear dropdown",
	Callback = function()
		Dropdown:Clear()
	end
})

local Button = Section2:Button({
	Name = "Update dropdown",
	Callback = function()
		Dropdown:UpdateList({
			Items = {"bruh", 1, 2, 3},
			Replace = true
		})
	end
})

local Button = Section2:Button({
	Name = "Additem",
	Callback = function()
		Dropdown:AddItem("Item")
	end
})

local Colorpicker = Section2:Colorpicker({
	Name = "Real Colorpicker",
	DefaultColor = Color3.new(1, 1, 1),
	Callback = function(Color)
		Library:Notify({
			Name = "Small Textbox updated",
			Text = "Color: "..tostring(Color),
			Icon = "rbxassetid://11401835376",
			Duration = 3,
		})
	end
})

local Button = Section2:Button({
	Name = "Random Color",
	Callback = function()
		Colorpicker:SetColor(Color3.fromRGB(math.random(1,256),math.random(1,256),math.random(1,256)))
	end
})

Library:Notify({
	Name = "Test",
	Text = "This is just a test",
	Icon = "rbxassetid://11401835376",
	Duration = 3,
	Callback = function()
		Library:Notify({
			Name = "Em",
			Text = "Notify Callback",
			Icon = "rbxassetid://11401835376",
			Duration = 3,
		})
	end
})

local Tab = Window:Tab({
	Name = "Others",
	Icon = "rbxassetid://11476626403",
	Color = Color3.new(0.474509, 0.474509, 0.474509)
})

local Section = Tab:Section({
	Name = "Miscs"
})

local Button = Section:Button({
	Name = "Destroy library",
	Callback = function()
		Library:Destroy()
	end
})

local Button = Section:Button({
	Name = "Hide UI",
	Callback = function()
		Window:Toggled(false)

		task.wait(3)

		Window:Toggled(true)
	end
})

local Button = Section:Button({
	Name = "Task Bar Only",
	Callback = function()
		Window:TaskBarOnly(true)

		task.wait(3)

		Window:TaskBarOnly(false)
	end
})