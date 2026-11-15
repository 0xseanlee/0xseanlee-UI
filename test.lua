local testDirectory = (debug.getinfo(1, "S").source:sub(2)):match("^(.*)/") or "."
-- Velvet UI smoke tests using a minimal Roblox API double.
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
local function countConnections(window)
    local count = 0
    for _, conn in pairs(window._connections) do if conn.Connected then count = count + 1 end end
    return count
end
local Library = assert(loadfile(testDirectory .. "/Library.lua"))()
local window = Library:CreateWindow({Name = "Test"})
local first = window:CreateTab("First", "home")
local second = window:CreateTab("Second", "settings")
check(window.SelectedTab == first, "First tab selected automatically")
second:Select()
check(not first._page.Visible and second._page.Visible, "Switch tabs")
local calls = 0
local toggle = second:CreateToggle({Name = "Toggle", Flag = "toggle", Callback = function(value)
    calls = calls + 1; check(type(value) == "boolean")
end})
-- The normalized appearance contract comes from the supplied snapshots.
check(window.Root.Size.X.Offset / window.Root.Size.Y.Offset == 550/380, "Captured window proportions")
local rail = window.Root:FindFirstChild("Navigation")
check(rail.Size.X.Offset / window.Root.Size.X.Offset == 160/550, "Captured sidebar proportions")
check(toggle._title.FontFace.Family == "rbxasset://fonts/families/BuilderSans.json", "Native font family")
check(toggle.Frame.Size.Y.Offset >= 25*1.5, "Normalized row keeps adequate height")
check(calls == 0 and window.Values.toggle == false, "Silent initialization")
toggle:Set(true); check(calls == 1 and window.Values.toggle == true)
toggle:Set(false, true); check(calls == 1, "Silent programmatic update")
local slider = second:CreateSlider({Name = "Speed", Range = {10, 20}, Increment = 2, CurrentValue = 11, Flag = "speed"})
check(slider.Value == 12, "Quantize slider")
slider:Set(100); check(slider.Value == 20, "Clamp maximum")
slider:Set(-10); check(slider.Value == 10, "Clamp minimum")
local selected = second:CreateDropdown({Name = "Select", Options = {"one", "two"}, CurrentOption = "two", Flag = "selected"})
check(selected.Value == "two")
check(selected:Set("missing") == false, "Reject option not in list")
selected:Refresh({"three"}); check(selected.Value == "three" and window.Values.selected == "three")
selected:Refresh({}); check(selected.Value == nil and window.Values.selected == nil)
local field = second:CreateInput({Name = "Input", CurrentValue = "a", Flag = "input"})
check(field._box.Parent.Size.X.Offset == 150*1.5, "Shared captured input width")
check(field._box.Parent.Size.Y.Offset == 18*1.5, "Shared captured input height")
field:Set("b", true); check(window.Values.input == "b")
local keyCalls = 0
local keybind = second:CreateKeybind({Name = "Key", CurrentKeybind = "F", Flag = "key", Callback = function() keyCalls = keyCalls + 1 end})
input.InputBegan:Fire(keyboard("F"), false); check(keyCalls == 1, "Hotkey routing")
window:SetVisible(false)
input.InputBegan:Fire(keyboard("F"), false); check(keyCalls == 1, "Hidden window hotkey blocked")
window:SetVisible(true)
field._box:CaptureFocus()
input.InputBegan:Fire(keyboard("F"), false); check(keyCalls == 1, "Text focus blocks hotkey")
field._box:ReleaseFocus()
field._box:CaptureFocus()
first:Select()
check(input:GetFocusedTextBox() == nil, "Tab switch releases hidden textbox focus")
input.InputBegan:Fire(keyboard("F"), false)
check(keyCalls == 1, "Inactive tab hotkey blocked")
second:Select()
window:SetScale(0.75)
local beforeScale = window._scale
pcall(function() window:SetScale(0/0) end)
check(window._scale == beforeScale, "Reject NaN scale")
pcall(function() window:SetScale(math.huge) end)
check(window._scale == beforeScale, "Reject infinite scale")
local beforeValue = slider.Value
pcall(function() slider:Set(0/0) end)
check(slider.Value == beforeValue, "Reject NaN slider value")
pcall(function() slider:Set(math.huge) end)
check(slider.Value == beforeValue, "Reject infinite slider value")
slider._track.AbsolutePosition = Vector2.new(100, 100)
slider._track.AbsoluteSize = Vector2.new(200, 4)
local mouse = {UserInputType = Enum.UserInputType.MouseButton1, KeyCode = Enum.KeyCode.Unknown, Position = Vector3.new(100, 100, 0)}
local scrollingBefore = second._page.ScrollingEnabled
slider._hit.InputBegan:Fire(mouse)
check(slider.Value == 10 and second._page.ScrollingEnabled == false, "Slider captures pointer and suspends page scrolling")
input.InputChanged:Fire({UserInputType = Enum.UserInputType.MouseMovement, Position = Vector3.new(200, 100, 0)})
check(slider.Value == 16, "Slider pointer quantization")
input.InputEnded:Fire({UserInputType = Enum.UserInputType.MouseButton1})
check(window._drag == nil and second._page.ScrollingEnabled == scrollingBefore, "Mouse release restores scrolling")
local touch = {UserInputType = Enum.UserInputType.Touch, KeyCode = Enum.KeyCode.Unknown, Position = Vector3.new(300, 100, 0)}
slider._hit.InputBegan:Fire(touch)
check(slider.Value == 20, "Touch slider reaches maximum")
input.WindowFocusReleased:Fire()
check(window._drag == nil and second._page.ScrollingEnabled == scrollingBefore, "Focus loss cancels drag")
local invalidSlider = pcall(function() second:CreateSlider({Name = "Invalid", Range = {0, 10}, Increment = 0}) end)
check(not invalidSlider, "Reject nonpositive slider increment")
local stable = countConnections(window)
local tracked = #window._connections
for i = 1, 20 do selected:Refresh({"new-"..i, "retained"}) end
check(countConnections(window) == stable, "Dropdown refresh retains no global connections")
check(#window._connections == tracked, "Dropdown refresh doesn't retain obsolete handles")
check(window:GetControl("toggle") == toggle, "Control flag lookup")
toggle:SetDisabled(true)
local disabledValue = toggle.Value
toggle._hit.Activated:Fire()
check(toggle.Value == disabledValue, "Disabled toggle blocks click")
toggle:SetDisabled(false)
toggle._hit.Activated:Fire()
check(toggle.Value ~= disabledValue, "Re-enabled toggle responds")
toggle:SetVisible(false); check(toggle.Frame.Visible == false, "Control hide")
toggle:SetVisible(true); check(toggle.Frame.Visible == true)
window:SetSearch("Toggle")
check(toggle.Frame.Visible and not slider.Frame.Visible, "Search filters controls")
window:SetSearch(""); check(slider.Frame.Visible, "Clear search restores controls")
field._box:CaptureFocus()
window:SetSearch("Toggle")
check(input:GetFocusedTextBox() == nil, "Filtering releases hidden textbox focus")
window:SetSearch("")
field._box:CaptureFocus()
field:SetDisabled(true)
check(input:GetFocusedTextBox() == nil, "Disabling releases textbox focus")
field:SetDisabled(false)
field._box:CaptureFocus()
field:SetVisible(false)
check(input:GetFocusedTextBox() == nil, "Hiding releases textbox focus")
field:SetVisible(true)
window:SetReducedMotion(true)
window:SetReducedMotion(false)
window:ResetPosition()
-- Only the newest capture target can change; capture event does not trigger action.
local otherKey = second:CreateKeybind({Name = "Other key", CurrentKeybind = "G"})
keybind._hit.Activated:Fire()
otherKey._hit.Activated:Fire()
input.InputBegan:Fire(keyboard("J"), false)
check(keybind.Value == Enum.KeyCode.F and otherKey.Value == Enum.KeyCode.J, "Exclusive key capture")
check(keyCalls == 1, "Capture doesn't trigger another binding")
otherKey._hit.Activated:Fire()
window:SetSearch("Toggle")
input.InputBegan:Fire(keyboard("H"), false)
check(otherKey.Value == Enum.KeyCode.J, "Filtering hidden keybind cancels capture")
window:SetSearch("")
-- Hide cancels capture, preserving the binding.
otherKey._hit.Activated:Fire()
window:SetVisible(false)
input.InputBegan:Fire(keyboard("H"), false)
check(otherKey.Value == Enum.KeyCode.J, "Hide cancels capture")
window:SetVisible(true)
check(input.InputBegan:Count() == 1 and input.InputChanged:Count() == 1 and input.InputEnded:Count() == 1, "One shared router per input signal")
-- Re-running should clean every tracked connection and destroy the prior hierarchy.
local oldConnections, oldGui = window._connections, window.Gui
local newLibrary = assert(loadfile(testDirectory .. "/Library.lua"))()
local replacement = newLibrary:CreateWindow({})
check(window._destroyed, "Re-running destroys prior window")
for _, conn in pairs(oldConnections) do check(not conn.Connected, "Leaked event listener") end
check(oldGui._dead and #oldGui:GetDescendants() == 0, "GUI hierarchy cleanup")
replacement:Destroy(); replacement:Destroy()
check(_G.__VELVET_UI_WINDOW == nil, "Environment reference cleanup")
check(input.InputBegan:Count() == 0 and input.InputChanged:Count() == 0 and input.InputEnded:Count() == 0, "Input router cleanup")
check(input.WindowFocusReleased:Count() == 0, "Window focus router cleanup")
-- Run the generated standalone demo against the same API double.
assert(loadfile(testDirectory .. "/Demo.client.lua"))()
check(_G.__VELVET_UI_WINDOW ~= nil, "Demo mounts")
_G.__VELVET_UI_WINDOW:Destroy()
print("PASS: state, callbacks, tabs, numeric validation, refresh cleanup, hidden/focused input, control states, search, exclusive capture, re-run cleanup, standalone demo")
