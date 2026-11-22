-- The window title and floating control use the same branding as the reference hub.
local Window = Library:MakeWindow({
    Title = "0xseanlee Hub",
    SubTitle = "by 0xseanlee",
})

local launcher = Window:AddMinimizeButton({
    Corner = { CornerRadius = UDim.new(0.25, 0) },
    Button = { Name = "0xseanleeLauncher" },
})
local label = Instance.new("TextLabel")
label.Name = "0xseanleeIconFallback"
label.Size = UDim2.fromScale(1, 1)
label.Text = "0x"
label.TextScaled = true
label.Font = Enum.Font.GothamBold
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.BackgroundColor3 = Color3.fromRGB(24, 29, 33)
label.BorderSizePixel = 0
label.Parent = launcher.Button
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0.25, 0)
corner.Parent = label

Window:MakeTab({ "Main", "home" })
