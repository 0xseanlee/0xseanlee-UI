-- Demo body. Demo.client.lua includes both this file and the library.
local Window = Library:CreateWindow({
    Name = "0xseanlee UI UI",
    Subtitle = "Interface library / v0.3",
    Scale = 1,
    ToggleKey = Enum.KeyCode.RightShift,
})

local Home = Window:CreateTab("Overview", "info")
local Main = Window:CreateTab("Main", "home")
local Components = Window:CreateTab("Components", "list")
local Settings = Window:CreateTab("Settings", "settings")

Home:CreateSection("Welcome")
Home:CreateParagraph({Title = "A quieter workspace", Content = "A compact interface with clear controls, subtle motion, and room for your own features. Search any page using the field above."})
Home:CreateButton({Name = "Explore the components", Description = "Try inputs, sliders, dropdowns, and keyboard shortcuts.", Callback = function() Components:Select() end})
Home:CreateSection("Make it yours")
Home:CreateParagraph({Title = "Simple to build on", Content = "Create a window, add a tab, then pass a name, description, and callback to each control. Controls expose simple methods to update their values and visibility."})
Home:CreateButton({Name = "Preview a notification", Callback = function()
    Window:Notify({Title = "Everything is ready", Content = "Add your own features with callbacks.", Duration = 4})
end})

Main:CreateDropdown({Name = "Select Tool", Description = "Choose a tool for your workspace.", Options = {"Melee", "Sword", "Fruit", "Gun"}, CurrentOption = "Sword", Flag = "tool", Callback = function(value)
    Window:Notify({Title = "Tool updated", Content = "Selected: " .. value})
end})
Main:CreateDropdown({Name = "Interface Scale", Options = {"Compact", "Comfortable", "Large"}, CurrentOption = "Comfortable", Callback = function(value)
    Window:SetScale(({Compact = 0.8, Comfortable = 1, Large = 1.15})[value])
end})
Main:CreateSection("General")
Main:CreateToggle({Name = "Nearby Mode", Description = "An independent example control.", Flag = "nearby"})
Main:CreateToggle({Name = "Compact Notifications", CurrentValue = false})
Main:CreateSection("Appearance")
Main:CreateToggle({Name = "Reduced Motion", Description = "Apply control state changes without transitions.", Flag = "reduced_motion", Callback = function(value) Window:SetReducedMotion(value) end})
Main:CreateSection("Actions")
Main:CreateButton({Name = "Refresh List", Description = "Buttons can include a short secondary description.", Callback = function() Window:Notify("List refreshed") end})

Components:CreateSection("Controls")
local toggle = Components:CreateToggle({Name = "Example Toggle", Description = "Click anywhere on this row.", Flag = "demo_toggle"})
Components:CreateSlider({Name = "Speed", Range = {0, 100}, CurrentValue = 16, Increment = 1, Flag = "speed"})
Components:CreateSlider({Name = "Volume", Description = "Drag the slider or click the number to type a value.", Range = {0, 100}, CurrentValue = 65, Increment = 5, Suffix = "%", Flag = "volume"})
local dropdown = Components:CreateDropdown({Name = "Players List", Description = "Long lists include an option search field.", Options = {"one", "two", "three", "four", "five", "six", "seven", "eight"}, CurrentOption = "two", Flag = "player"})
Components:CreateInput({Name = "Item Name", PlaceholderText = "Enter a name...", Flag = "item", Callback = function(value)
    Window:Notify({Title = "Input updated", Content = value=="" and "The input is empty." or value})
end})
Components:CreateKeybind({Name = "Preview Notification", Description = "Click to rebind. Escape cancels. Active on this page.", CurrentKeybind = "F", Callback = function() Window:Notify("Keyboard shortcut pressed") end})
Components:CreateSection("Programmatic updates")
Components:CreateButton({Name = "Set toggle ON", Callback = function() toggle:Set(true) end})
Components:CreateButton({Name = "Replace dropdown options", Callback = function() dropdown:Refresh({"Apple", "Orange", "Mango"}) end})
Components:CreateButton({Name = "Print current values", Callback = function()
    for flag, value in pairs(Window.Values) do print("[0xseanlee UI]", flag, value) end
    Window:Notify("Current values printed to the console.")
end})

Settings:CreateSection("Window")
Settings:CreateParagraph({Title = "Stay in control", Content = "Drag the header to move. Right Shift hides or restores the window. The V button restores a minimized window. Closing the window removes its listeners."})
Settings:CreateButton({Name = "Center Window", Callback = function() Window:ResetPosition() end})
Settings:CreateButton({Name = "Reset Scale", Callback = function() Window:SetScale(1) end})
Settings:CreateButton({Name = "Minimize Window", Callback = function() Window:SetVisible(false) end})
Settings:CreateSection("About")
Settings:CreateParagraph({Title = "0xseanlee UI / 0.3", Content = "Standalone UI with locally drawn icons. No external assets or downloads. State lasts for the current run."})
Main:Select()
