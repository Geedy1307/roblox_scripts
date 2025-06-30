local Lib = loadstring(game:HttpGet('https://raw.githubusercontent.com/hoangsalty/roblox/refs/heads/main/scripts/Materials/UISource/Mercury_Lib.lua'))()

local Window = Lib:Create{
    Name = 'Mercury',
    Size = UDim2.fromOffset(600, 400),
    Theme = Lib.Themes.Dark,
    Link = 'Pornhub.com'
}

local Tab = Window:Tab{
	Name = 'New Tab',
	Icon = 'rbxassetid://8569322835'
}

--Button
Tab:Button{
	Name = 'Button',
	Description = nil,
	Callback = function() end
}
--Toggle
Tab:Toggle{
	Name = 'Toggle',
	StartingState = false,
	Description = nil,
	Callback = function(state) 
        print(state) 
    end
}:SetState(false)
--Textbox
Tab:Textbox{
	Name = 'Textbox',
	Callback = function(text) end
}
--Dropdown
local MyDropdown = Tab:Dropdown{
	Name = 'Dropdown',
	StartingText = 'Select...',
	Description = nil,
	Items = {
		{'Hello', 1}, 		-- {name, value}
		12,			-- or just value, which is also automatically taken as name
		{'Test', 'bump the thread pls'}
	},
	Callback = function(item) return end
}

MyDropdown:AddItems({
	{'NewItem', 12},		-- {name, value}
	400				-- or just value, which is also automatically taken as name
})

MyDropdown:RemoveItems({
	'NewItem', 'Hello'		-- just the names to get removed (upper/lower case ignored)
})

MyDropdown:Clear()
--Slider
Tab:Slider{
	Name = 'Slider',
	Default = 50,
	Min = 0,
	Max = 100,
	Callback = function() end
}
--Keybind
Tab:Keybind{
	Name = 'Keybind',
	Keybind = nil,
	Description = nil
}
--ColorPicker
Tab:ColorPicker{
	Style = Lib.ColorPickerStyles.Legacy,
	Callback = function(color) end
}
--Prompt
Window:Prompt{
	Followup = false,
	Title = 'Prompt',
	Text = 'Prompts are cool',
	Buttons = {
		['ok'] = function()
			return true
		end,
		['no'] = function()
			return false
		end
	}
}
--Credit
Window:Credit{
	Name = 'Creditor name',
	Description = 'Helped with the script',
	V3rm = 'link/name',
	Discord = 'helo#1234'
}