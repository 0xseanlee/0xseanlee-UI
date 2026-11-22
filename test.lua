local testDirectory = (debug.getinfo(1, "S").source:sub(2)):match("^(.*)/") or "."
-- UI compatibility tests using a minimal Roblox API double.
-- These verify state, routing and cleanup; they do not render or validate Roblox UI.
math.atan2 = math.atan2 or function(y, x) return math.atan(y, x) end
math.clamp = math.clamp or function(x, a, b) return math.max(a, math.min(b, x)) end
local function check(value, message)
    assert(value, message or "Assertion failed")
end
local function signal()
    local s = {listeners = {}}
    function s:Connect(fn)
        local conn = {Connected = true}
        function conn:Disconnect() self.Connected = false end
        table.insert(self.listeners, {fn = fn, conn = conn})
        return conn
    end
    function s:Once(fn)
        local conn
        conn = self:Connect(function(...)
            conn:Disconnect()
            fn(...)
        end)
        return conn
    end
    function s:Fire(...)
        -- Snapshot so listeners created by callbacks don't run in the same event.
        local snapshot = {}
        for _, entry in ipairs(self.listeners) do snapshot[#snapshot + 1] = entry end
        for _, entry in ipairs(snapshot) do
            if entry.conn.Connected then entry.fn(...) end
        end
    end
    function s:Count()
        local count = 0
        for _, entry in ipairs(self.listeners) do
            if entry.conn.Connected then count = count + 1 end
        end
        return count
    end
    return s
end
local vecMeta = {}
Vector2 = {new = function(x, y)
    return setmetatable({X = x, Y = y, Magnitude = math.sqrt(x*x + y*y), _kind = "Vector2"}, vecMeta)
end}
vecMeta.__add = function(a, b) return Vector2.new(a.X + b.X, a.Y + b.Y) end
vecMeta.__sub = function(a, b) return Vector2.new(a.X - b.X, a.Y - b.Y) end
vecMeta.__mul = function(a, b)
    if type(a) == "number" then return Vector2.new(a*b.X, a*b.Y) end
    return Vector2.new(a.X*b, a.Y*b)
end
Vector3 = {new = function(x, y, z) return {X = x, Y = y, Z = z, _kind = "Vector3"} end}
local function dimension(s, o) return {Scale = s or 0, Offset = o or 0, _kind = "UDim"} end
UDim = {new = dimension}
UDim2 = {new = function(xs, xo, ys, yo) return {X = dimension(xs, xo), Y = dimension(ys, yo), _kind = "UDim2"} end}
UDim2.fromOffset = function(x, y) return UDim2.new(0, x, 0, y) end
UDim2.fromScale = function(x, y) return UDim2.new(x, 0, y, 0) end
local colorMeta = {}
local function color(r, g, b) return setmetatable({R = r, G = g, B = b, _kind = "Color3"}, colorMeta) end
Color3 = {new = color, fromRGB = function(r, g, b) return color(r/255, g/255, b/255) end}
function colorMeta:Lerp(other, alpha)
    return color(self.R + (other.R-self.R)*alpha, self.G + (other.G-self.G)*alpha, self.B + (other.B-self.B)*alpha)
end
colorMeta.__index = colorMeta
Enum = setmetatable({}, {__index = function(self, key)
    local values = setmetatable({}, {__index = function(t, name)
        local value = {Name = name, EnumType = t, _kind = "EnumItem"}
        rawset(t, name, value)
        return value
    end})
    rawset(self, key, values)
    return values
end})
TweenInfo = {new = function(...) return {...} end}
Font = {new = function(family, weight, style)
    return {Family = family, Weight = weight, Style = style, _kind = "Font"}
end}
ColorSequence = {new = function(...) return {...} end}
NumberSequence = {new = function(...) return {...} end}
NumberSequenceKeypoint = {new = function(...) return {...} end}
ColorSequenceKeypoint = {new = function(...) return {...} end}
function typeof(value)
    return type(value) == "table" and (value._kind or "table") or type(value)
end
local events = {
    Activated = true, InputBegan = true, InputChanged = true, InputEnded = true,
    MouseEnter = true, MouseLeave = true, Focused = true, FocusLost = true,
    Destroying = true, AncestryChanged = true,
}
local objects = {}
local methods = {}
local input = {
    InputBegan = signal(), InputChanged = signal(), InputEnded = signal(),
    WindowFocusReleased = signal(), TouchEnabled = false, MouseEnabled = true,
    KeyboardEnabled = true,
}
function input:GetFocusedTextBox() return self._focused end
function input:GetMouseLocation() return Vector2.new(150, 150) end
function methods:GetChildren()
    local children = {}
    for _, obj in ipairs(objects) do
        if not obj._dead and obj.Parent == self then children[#children + 1] = obj end
    end
    return children
end
function methods:GetDescendants()
    local all = {}
    for _, child in ipairs(self:GetChildren()) do
        all[#all + 1] = child
        for _, nested in ipairs(child:GetDescendants()) do all[#all + 1] = nested end
    end
    return all
end
function methods:FindFirstChild(name, recursive)
    for _, child in ipairs(recursive and self:GetDescendants() or self:GetChildren()) do
        if child.Name == name then return child end
    end
end
function methods:WaitForChild(name) return assert(self:FindFirstChild(name), "Missing mock child "..name) end
function methods:FindFirstChildOfClass(class)
    for _, child in ipairs(self:GetChildren()) do if child:IsA(class) then return child end end
end
function methods:IsA(class)
    return self.ClassName == class or (class == "GuiObject" and self.ClassName ~= "ScreenGui" and not self.ClassName:match("^UI"))
end
function methods:IsDescendantOf(ancestor)
    local current = self.Parent
    while current do
        if current == ancestor then return true end
        current = current.Parent
    end
    return false
end
function methods:Destroy()
    if self._dead then return end
    self.Destroying:Fire()
    for _, child in ipairs(self:GetChildren()) do child:Destroy() end
    for _, event in pairs(self._signals) do
        for _, entry in ipairs(event.listeners) do entry.conn:Disconnect() end
    end
    for key in pairs(events) do
        local event = rawget(self, key)
        if event then for _, entry in ipairs(event.listeners) do entry.conn:Disconnect() end end
    end
    if input._focused == self then input._focused = nil end
    self._dead = true
    self.Parent = nil
end
function methods:GetPropertyChangedSignal(name)
    self._signals[name] = self._signals[name] or signal()
    return self._signals[name]
end
function methods:CaptureFocus()
    if input._focused and input._focused ~= self then input._focused:ReleaseFocus() end
    input._focused = self
    self.Focused:Fire()
end
function methods:ReleaseFocus(enter)
    if input._focused == self then input._focused = nil end
    self.FocusLost:Fire(enter == true)
end
function methods:SetAttribute(name, value) self._attributes[name] = value end
function methods:GetAttribute(name) return self._attributes[name] end
Instance = {new = function(class)
    local obj = setmetatable({
        ClassName = class, _kind = "Instance", _signals = {}, _attributes = {}, Name = class,
        AbsoluteSize = Vector2.new(1280, 800), AbsolutePosition = Vector2.new(100, 100),
        Visible = true, Text = "", Size = UDim2.new(), Position = UDim2.new(),
        CanvasPosition = Vector2.new(0, 0), AbsoluteContentSize = Vector2.new(400, 600),
    }, {__index = function(self, key)
        if methods[key] then return methods[key] end
        if events[key] then
            local event = signal()
            rawset(self, key, event)
            return event
        end
    end})
    objects[#objects + 1] = obj
    return obj
end}
local core = Instance.new("CoreGui")
local player = Instance.new("Player")
local playerGui = Instance.new("PlayerGui"); playerGui.Parent = player
local services = {
    UserInputService = input, CoreGui = core, Players = {LocalPlayer = player},
    TextService = {GetTextSize = function(_, value, size, _, bounds)
        local width = math.max(1, bounds.X)
        local natural = #tostring(value)*size*0.52
        return Vector2.new(math.min(natural, width), size*math.max(1, math.ceil(natural/width)))
    end},
    GuiService = {GetGuiInset = function() return Vector2.new(0, 0), Vector2.new(0, 0) end},
    TweenService = {Create = function(_, obj, _, props)
        local tween = {Completed = signal()}
        function tween:Play()
            for k, v in pairs(props) do obj[k] = v end
            self.Completed:Fire()
        end
        function tween:Cancel() end
        return tween
    end},
}
game = {GetService = function(_, name) return assert(services[name], "Missing mock service "..name) end}
local delayed = {}
task = {
    delay = function(_, fn) delayed[#delayed + 1] = fn end,
    defer = function(fn, ...) return fn(...) end,
    spawn = function(fn, ...) return fn(...) end,
    cancel = function() end,
}
warn = function(message) print("warning: "..message) end
local function keyboard(key)
    return {KeyCode = Enum.KeyCode[key], UserInputType = Enum.UserInputType.Keyboard, Position = Vector3.new(0, 0, 0)}
end
-- Exercise both APIs against the renderer with Roblox services and signals mocked.
-- PUC Lua needs shims for the handful of Roblox/Luau-only globals used here.
unpack = table.unpack
tick = os.clock
table.foreach = function(t, fn) for k, v in pairs(t) do fn(k, v) end end
table.clear = function(t) for k in pairs(t) do t[k] = nil end end
table.find = function(t, v) for k, item in pairs(t) do if v == item then return k end end end
workspace = {CurrentCamera = {ViewportSize = Vector2.new(1280, 800)}}
services.RunService = {Heartbeat = signal()}
services.HttpService, services.MarketplaceService = {}, {}
function player:GetMouse() return {X = 0, Y = 0} end
function input:IsMouseButtonPressed() return false end
local oldNew = Instance.new
function Instance.new(class)
    local object = oldNew(class)
    local mt = getmetatable(object)
    local index = mt.__index
    mt.__index = function(self, key)
        if key == "MouseButton1Down" or key == "MouseButton1Click" or key == "ChildAdded" or key == "ChildRemoved" then
            events[key] = true
        end
        local value = index(self, key)
        if value == nil and type(key) == "string" and key:match("^[A-Z]") and key ~= "Parent" then
            return methods.FindFirstChild(self, key)
        end
        return value
    end
    return object
end
function methods:Clone()
    local copy = Instance.new(self.ClassName)
    for k,v in pairs(self) do
        if k:sub(1,1) ~= "_" and k ~= "Parent" and not events[k] then copy[k] = v end
    end
    for _, child in ipairs(self:GetChildren()) do child:Clone().Parent = copy end
    return copy
end
local function signalWait() end
local tweenCreate = services.TweenService.Create
function services.TweenService:Create(...)
    local tween = tweenCreate(self, ...)
    tween.Completed.Wait = signalWait
    return tween
end
local file = assert(io.open(testDirectory .. "/Library.lua"))
local source = file:read("*a"); file:close()
source = source:gsub("in self%.Icons do", "in pairs(self.Icons) do")
local Library = assert(load(source, "@Library.lua"))()
local current = Library:MakeWindow({Title = "Current API"})
local currentTab = current:MakeTab({"Current", "home"})
check(currentTab:AddButton({Name = "Current button"}).Frame, "Native control still works")
local settings = current:MakeTab({"settings"})
check(settings == current.SettingsTab and currentTab.Cont.Parent, "Settings is fixed and first app tab stays selected")
local function clickSetting(name)
    for _, label in ipairs(settings.Cont:GetDescendants()) do
        if label:IsA("TextLabel") and label.Text == name then
            label.Parent.Parent.Activated:Fire()
            return
        end
    end
    error("Missing setting: " .. name)
end
local nativeGui = current.Root.Parent
local function selectSize(name)
    for _, label in ipairs(nativeGui.Dropdown:GetDescendants()) do
        if label:IsA("TextLabel") and label.Text == name and label.Parent.Name == "Option" then
            label.Parent.Activated:Fire()
            return
        end
    end
    error("Missing size option: " .. name)
end
local medium = nativeGui.Scale.Scale
selectSize("Small")
check(nativeGui.Scale.Scale < medium, "Small reduces visible size")
selectSize("Large")
check(nativeGui.Scale.Scale > medium, "Large increases visible size")
clickSetting("Red · Redz")
local accent = Library.Themes.Red["Color Theme"]
check(Library.Save.Theme == "Red" and currentTab.Cont.ScrollBarImageColor3 == accent, "Settings repaints existing controls")
clickSetting("Blue · 0xseanlee")
check(currentTab.Cont.ScrollBarImageColor3 == Library.Themes.Blue["Color Theme"])
selectSize("Medium")

local header = current.Root:FindFirstChild("Top Bar", true)
current.Root.AbsoluteSize = Vector2.new(550 * medium, 380 * medium)
local initial = current.Root.Position
local touch = {UserInputType = Enum.UserInputType.Touch, Position = Vector3.new(120, 120, 0)}
local other = {UserInputType = Enum.UserInputType.Touch, Position = Vector3.new(200, 150, 0)}
header.InputBegan:Fire(touch)
header.InputBegan:Fire(other)
input.InputChanged:Fire(other)
check(current.Root.Position == initial, "Second touch cannot move window")
touch.Position = Vector3.new(160, 144, 0)
input.InputChanged:Fire(touch)
check(math.abs(current.Root.Position.X.Offset - initial.X.Offset - 40/medium) < 0.01, "Drag follows the finger at rendered scale")
input.InputEnded:Fire(touch)
local after = current.Root.Position
touch.Position = Vector3.new(250, 170, 0)
input.InputChanged:Fire(touch)
check(current.Root.Position == after, "Released touch stops moving the window")

current.Root.Parent:Destroy()

local window = Library:CreateWindow({ReducedMotion = true})
local tab = window:CreateTab({Name = "Legacy", Icon = "home"})
local second = window:CreateTab("Second", "list")
check(window.SelectedTab == tab and #window.Tabs == 2)
tab:CreateSection("General")
local calls = 0
local function changed() calls = calls + 1 end
local toggle = tab:CreateToggle({Name = "Toggle", CurrentValue = true, Flag = "enabled", Callback = changed})
check(window.Values.enabled == true and window:GetControl("enabled") == toggle)
check(calls == 0, "Silent initialization")
toggle:Set(false)
toggle:Set(false)
toggle:Set(true, true)
check(calls == 1 and toggle.Value == true, "Only changed, nonsilent values fire")
toggle:SetDisabled(true); toggle.Frame.Activated:Fire()
check(toggle.Value == true and calls == 1)
toggle:SetDisabled(false); toggle.Frame.Activated:Fire()
check(toggle.Value == false and calls == 2)

local slider = tab:CreateSlider({Name = "Slider", Range = {-10, 0}, Increment = 3, CurrentValue = -8, Callback = changed})
check(slider.Value == -7 and calls == 2)
check(slider:Set(0) and slider.Value == 0 and calls == 3)
check(not slider:Set(math.huge) and calls == 3)
local choice = tab:CreateDropdown({Name = "Choice", Options = {"A", "B"}, CurrentOption = "B", Flag = "choice", Callback = changed})
check(choice.Value == "B" and calls == 3)
choice:Refresh({"B", "C"})
check(choice.Value == "B")
choice:Refresh({"D"})
check(choice.Value == "D")
choice:Refresh({})
check(choice.Value == nil and window.Values.choice == nil and calls == 3)
check(not choice:Set("A"))

local field = tab:CreateInput({Name = "Input", CurrentValue = "initial", EnterOnly = true, Callback = changed})
field._box.Text = "draft"; field._box.FocusLost:Fire(false)
check(field.Value == "initial" and field._box.Text == "initial")
field._box.Text = ""; field._box.FocusLost:Fire(true)
check(field.Value == "" and calls == 4)
local hotkey = tab:CreateKeybind({Name = "Shortcut", CurrentKeybind = "F", Callback = changed})
input.InputBegan:Fire(keyboard("F"), false)
check(calls == 5)
second:Select(); input.InputBegan:Fire(keyboard("F"), false)
check(calls == 5)
tab:Select()
hotkey.Frame.Activated:Fire(); input.InputBegan:Fire(keyboard("G"), false)
check(hotkey.Value == Enum.KeyCode.G and calls == 5)
window:SetSearch("toggle")
check(toggle.Frame.Visible and not slider.Frame.Visible)
window:SetSearch("")
check(slider.Frame.Visible)
window:Destroy()
check(input.InputBegan:Count() == 0)
local replacement = Library:CreateWindow({})
check(replacement.Gui ~= window.Gui and replacement:CreateTab("Again"))
replacement:Destroy()
local nativeAgain = Library:MakeWindow({Title = "Native again"})
check(nativeAgain:MakeTab({"Again", "home"}))
nativeAgain.Root.Parent:Destroy()
print("PASS: settings, theme, drag, both APIs, callbacks, dropdown refresh, keybind, remount")
