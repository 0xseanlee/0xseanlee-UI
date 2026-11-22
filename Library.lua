-- 0xseanlee UI v0.4.0 | Standalone, independently implemented Roblox UI.
-- No remote assets, network requests, or telemetry.
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local Library = {}
local activeWindow
local BASE = {
    Sidebar = Color3.fromRGB(20, 21, 25),
    Row = Color3.fromRGB(28, 29, 35), Hover = Color3.fromRGB(37, 39, 48),
    Field = Color3.fromRGB(42, 44, 54), Border = Color3.fromRGB(62, 64, 77),
    Text = Color3.fromRGB(250, 250, 250), Muted = Color3.fromRGB(200, 200, 200),
    Dim = Color3.fromRGB(145, 147, 163), Accent = Color3.fromRGB(88, 101, 242),
    Inactive = Color3.fromRGB(61, 67, 135),
}
-- Keep the original desktop dimensions while reflowing the controls on small viewports.
local STYLE = {Width=825, Height=570, Sidebar=240, Header=42, ContentX=255,
    ContentTop=105, CardRadius=9, RowHeight=38, DescriptionHeight=54,
    ControlFont=16, DescriptionFont=12, FieldWidth=225, FieldHeight=27}
local COMPACT = {Inset=12, Header=48, TabHeight=42, TabGap=7, ContentTop=155, FieldHeight=38}
local FONTS={}
local measureFont=Enum.Font.Gotham
pcall(function()
    measureFont=Enum.Font.BuilderSans
    local family="rbxasset://fonts/families/BuilderSans.json"
    FONTS.Regular=Font.new(family,Enum.FontWeight.Regular,Enum.FontStyle.Normal)
    FONTS.Medium=Font.new(family,Enum.FontWeight.Medium,Enum.FontStyle.Normal)
    FONTS.Bold=Font.new(family,Enum.FontWeight.Bold,Enum.FontStyle.Normal)
end)
local function finite(value)
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end
local function pointerBegan(input)
    return input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch
end
local function keycode(value)
    if type(value)=="string" then
        local ok,result=pcall(function() return Enum.KeyCode[value] end)
        value=ok and result or nil
    end
    if typeof(value)=="EnumItem" and value.EnumType==Enum.KeyCode and value~=Enum.KeyCode.Unknown then return value end
end
local function new(class, props, parent)
    local obj = Instance.new(class)
    for key, value in pairs(props or {}) do obj[key] = value end
    if class=="TextLabel" or class=="TextButton" or class=="TextBox" then
        local weight=(props or {}).Font
        local face=weight==Enum.Font.GothamBold and FONTS.Bold or (weight==Enum.Font.GothamMedium and FONTS.Medium or FONTS.Regular)
        if face then obj.FontFace=face end
    end
    obj.Parent = parent
    return obj
end
local function corner(obj, radius)
    return new("UICorner", {CornerRadius = UDim.new(0, radius or 9)}, obj)
end
local function stroke(obj, color, transparency)
    return new("UIStroke", {Color = color, Transparency = transparency or 0, Thickness = 1}, obj)
end
local function text(parent, value, size, color, props)
    local p = {
        Name = "Label", BackgroundTransparency = 1, BorderSizePixel = 0,
        Text = tostring(value or ""), TextSize = size or 14, TextColor3 = color,
        Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd, Size = UDim2.fromScale(1, 1),
    }
    for key, v in pairs(props or {}) do p[key] = v end
    return new("TextLabel", p, parent)
end
local function button(parent, props)
    local p = {Text = "", AutoButtonColor = false, BorderSizePixel = 0, BackgroundTransparency = 1}
    for key, value in pairs(props or {}) do p[key] = value end
    return new("TextButton", p, parent)
end
local function line(parent, x1, y1, x2, y2, color, thickness)
    local dx, dy = x2-x1, y2-y1
    return new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset((x1+x2)/2, (y1+y2)/2),
        Size = UDim2.fromOffset(math.sqrt(dx*dx+dy*dy), thickness or 1.6),
        Rotation = math.deg(math.atan2(dy, dx)), BackgroundColor3 = color, BorderSizePixel = 0,
    }, parent)
end
local function chevron(parent, color, direction)
    local frame = new("Frame", {Name="Chevron", BackgroundTransparency=1, Size=UDim2.fromOffset(16,16)}, parent)
    line(frame, 4,6,8,10,color,1.7); line(frame,8,10,12,6,color,1.7)
    frame.Rotation = direction == "right" and -90 or 0
    return frame
end
local function icon(parent, name, color)
    local frame = new("Frame", {Name="Icon",BackgroundTransparency=1,Size=UDim2.fromOffset(22,22)}, parent)
    local function path(points)
        for i=1,#points-1 do line(frame,points[i][1],points[i][2],points[i+1][1],points[i+1][2],color) end
    end
    if name == "home" then
        path({{2,10},{11,3},{20,10},{19,10},{19,20},{14,20},{14,13},{8,13},{8,20},{3,20},{3,10}})
    elseif name == "chart" then
        for i=0,3 do line(frame,4+i*5,20,4+i*5,17-i*4,color,2) end
    elseif name == "list" then
        for i=0,2 do path({{8,5+i*6},{20,5+i*6}}); path({{2,5+i*6},{3,5+i*6}}) end
    elseif name == "user" then
        local head=new("Frame",{Position=UDim2.fromOffset(7,2),Size=UDim2.fromOffset(8,8),BackgroundTransparency=1},frame)
        corner(head,8); stroke(head,color)
        path({{3,21},{3,17},{6,13},{16,13},{19,17},{19,21}})
    elseif name == "settings" then
        for i,x in ipairs({7,15,9}) do
            line(frame,2,5+(i-1)*6,20,5+(i-1)*6,color)
            local knob=new("Frame",{Position=UDim2.fromOffset(x-2,2+(i-1)*6),Size=UDim2.fromOffset(4,6),BackgroundColor3=color,BorderSizePixel=0},frame)
            corner(knob,2)
        end
    elseif name == "search" then
        local ring=new("Frame",{Position=UDim2.fromOffset(3,3),Size=UDim2.fromOffset(11,11),BackgroundTransparency=1},frame)
        corner(ring,10); stroke(ring,color); line(frame,13,13,19,19,color)
    else
        local ring=new("Frame",{Position=UDim2.fromOffset(2,2),Size=UDim2.fromOffset(18,18),BackgroundTransparency=1},frame)
        corner(ring,20); stroke(ring,color)
        text(frame,"i",13,color,{TextXAlignment=Enum.TextXAlignment.Center,Font=Enum.Font.GothamMedium})
    end
    return frame
end

function Library:CreateWindow(options)
    options=options or {}
    assert(options.Scale==nil or (finite(options.Scale) and options.Scale>0),"Scale must be a positive finite number")
    local toggleKey=keycode(options.ToggleKey or Enum.KeyCode.RightShift)
    assert(toggleKey,"ToggleKey must be a valid keyboard key")
    local env=_G
    if type(getgenv)=="function" then
        local ok,result=pcall(getgenv)
        if ok and type(result)=="table" then env=result end
    end
    local previous=env.__VELVET_UI_WINDOW
    if previous and type(previous.Destroy)=="function" then previous:Destroy() end
    if activeWindow then activeWindow:Destroy() end
    local C={}
    for key,value in pairs(BASE) do C[key]=value end
    C.Accent=options.AccentColor or C.Accent
    C.Selected=C.Row:Lerp(C.Accent,0.16)
    local window={Tabs={},Values={},_controls={},_keybinds={},_connections={},_destroyed=false,_scale=options.Scale or 1,_query="",_reducedMotion=options.ReducedMotion==true}
    activeWindow=window
    local function connect(signal,fn,scope)
        local conn=signal:Connect(fn)
        table.insert(scope or window._connections,conn)
        return conn
    end
    local animations=setmetatable({}, {__mode="k"})
    local function animate(obj,props,duration)
        if animations[obj] then animations[obj]:Cancel(); animations[obj]=nil end
        if window._reducedMotion then
            for key,value in pairs(props) do obj[key]=value end
        else
            local tw=TweenService:Create(obj,TweenInfo.new(duration or 0.16,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),props)
            animations[obj]=tw; tw:Play()
        end
    end
    local gui=new("ScreenGui",{Name="0xseanleeUI",ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,DisplayOrder=100},nil)
    local mounted=false
    if type(gethui)=="function" then
        mounted=pcall(function() local target=gethui(); assert(target,"No UI container"); gui.Parent=target end)
    end
    if not mounted then mounted=pcall(function() gui.Parent=game:GetService("CoreGui") end) end
    if not mounted then gui.Parent=Players.LocalPlayer:WaitForChild("PlayerGui") end
    window.Gui=gui
    local width,height=STYLE.Width,STYLE.Height
    local rowWidth=width-STYLE.ContentX-24
    local compact=false
    local root=new("Frame",{Name="Window",AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(width,height),BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=0.03,BorderSizePixel=0,ClipsDescendants=true,Active=true},gui)
    corner(root,12); stroke(root,C.Border,0.65)
    new("UIGradient",{Rotation=90,Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,Color3.fromRGB(16,17,21)),
        ColorSequenceKeypoint.new(0.5,Color3.fromRGB(23,24,30)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(17,18,22)),
    })},root)
    window.Root=root
    local scaler=new("UIScale",{Scale=1},root)
    local function clampPosition()
        if root.Position.X.Scale==0.5 and root.Position.Y.Scale==0.5 then return end
        local viewport=gui.AbsoluteSize
        local halfW,halfH=width*scaler.Scale/2,height*scaler.Scale/2
        local x=root.Position.X.Scale*viewport.X+root.Position.X.Offset
        local y=root.Position.Y.Scale*viewport.Y+root.Position.Y.Offset
        local minX=math.min(halfW+8,viewport.X/2)
        local minY=math.min(halfH+8,viewport.Y/2)
        root.Position=UDim2.fromOffset(math.clamp(x,minX,viewport.X-minX),math.clamp(y,minY,viewport.Y-minY))
    end
    local toastHost=new("Frame",{Name="Notifications",AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-18,1,-18),Size=UDim2.fromOffset(360,250),BackgroundTransparency=1,ZIndex=50},gui)
    new("UIListLayout",{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder,VerticalAlignment=Enum.VerticalAlignment.Bottom},toastHost)
    function window:SetReducedMotion(value) self._reducedMotion=value==true end
    local header=button(root,{Name="Header",Size=UDim2.new(1,-95,0,STYLE.Header)})
    local headerMark=new("Frame",{Name="BrandMark",Position=UDim2.new(0,15,0.5,-8),Size=UDim2.fromOffset(4,16),BackgroundColor3=C.Accent,BorderSizePixel=0},header)
    corner(headerMark,2)
    local heading=text(header,options.Name or "0xseanlee UI",18,C.Text,{Position=UDim2.fromOffset(28,0),Size=UDim2.new(0.6,-28,1,0),Font=Enum.Font.GothamBold})
    local subtitle=text(header,options.Subtitle or "Your workspace",11,C.Muted,{Position=UDim2.fromScale(0.62,0),Size=UDim2.fromScale(0.36,1)})
    local function headerButton(name,close)
        local b=button(root,{Name=name,AnchorPoint=Vector2.new(1,0),BackgroundColor3=C.Field})
        corner(b,8)
        local symbol=new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(16,16),BackgroundTransparency=1},b)
        if close then line(symbol,3,3,13,13,C.Muted); line(symbol,13,3,3,13,C.Muted)
        else line(symbol,2,8,14,8,C.Muted) end
        connect(b.MouseEnter,function() animate(b,{BackgroundTransparency=0}) end)
        connect(b.MouseLeave,function() animate(b,{BackgroundTransparency=1}) end)
        return b
    end
    local minimize,close=headerButton("Minimize",false),headerButton("Close",true)
    local restore=button(gui,{Name="Restore",Text="0x",Font=Enum.Font.GothamBold,TextSize=16,TextColor3=C.Text,BackgroundTransparency=0,BackgroundColor3=C.Sidebar,Position=UDim2.fromOffset(14,100),Size=UDim2.fromOffset(48,48),Visible=false})
    corner(restore,13); stroke(restore,C.Accent,0.55)
    local function cancelInteraction()
        if window._drag and window._drag.Finish then window._drag.Finish() end
        window._drag=nil
        if window._listening then window._listening:_cancelCapture(); window._listening=nil end
        if window._openDropdown then window._openDropdown:_expand(false) end
    end
    function window:SetVisible(value)
        if self._destroyed then return end
        cancelInteraction()
        root.Visible=value==true; restore.Visible=not root.Visible
        if not root.Visible then
            local focused=UIS:GetFocusedTextBox()
            if focused and focused:IsDescendantOf(gui) then focused:ReleaseFocus(false) end
        end
    end
    function window:Destroy()
        if self._destroyed then return end
        cancelInteraction(); self._destroyed=true
        for _,conn in ipairs(self._connections) do conn:Disconnect() end
        for _,control in ipairs(self._controls) do
            for _,conn in ipairs(control._optionConnections or {}) do conn:Disconnect() end
        end
        for obj,tw in pairs(animations) do tw:Cancel(); animations[obj]=nil end
        gui:Destroy()
        if activeWindow==self then activeWindow=nil end
        if env.__VELVET_UI_WINDOW==self then env.__VELVET_UI_WINDOW=nil end
    end
    connect(gui.Destroying,function() window:Destroy() end)
    connect(minimize.Activated,function() window:SetVisible(false) end)
    connect(restore.Activated,function() window:SetVisible(true) end)
    connect(close.Activated,function() window:Destroy() end)
    local toastSerial=0
    local toasts={}
    function window:Notify(message)
        if self._destroyed then return end
        local opts=type(message)=="table" and message or {Content=tostring(message)}
        local duration=finite(opts.Duration) and math.clamp(opts.Duration,1,30) or 3
        if #toasts>=3 then table.remove(toasts,1):Destroy() end
        toastSerial=toastSerial+1
        local toast=new("Frame",{Name="Toast",LayoutOrder=toastSerial,Size=UDim2.new(1,0,0,70),BackgroundColor3=C.Row,BorderSizePixel=0,ClipsDescendants=true,ZIndex=50},toastHost)
        corner(toast,10); stroke(toast,C.Border)
        text(toast,opts.Title or "0xseanlee UI",12,C.Accent,{Position=UDim2.fromOffset(14,10),Size=UDim2.new(1,-28,0,18),Font=Enum.Font.GothamMedium})
        text(toast,opts.Content or "",12,C.Text,{Position=UDim2.fromOffset(14,30),Size=UDim2.new(1,-28,0,30),TextWrapped=true,TextYAlignment=Enum.TextYAlignment.Top,TextTruncate=Enum.TextTruncate.None})
        local progress=new("Frame",{Position=UDim2.new(0,0,1,-2),Size=UDim2.new(1,0,0,2),BackgroundColor3=C.Accent,BorderSizePixel=0},toast)
        if not self._reducedMotion then animate(progress,{Size=UDim2.new(0,0,0,2)},duration) end
        table.insert(toasts,toast)
        task.delay(duration,function()
            if self._destroyed then return end
            for i,v in ipairs(toasts) do if v==toast then table.remove(toasts,i); toast:Destroy(); break end end
        end)
    end
    local function call(fn,value)
        if type(fn)~="function" or window._destroyed then return end
        local ok,err=pcall(fn,value)
        if not ok then warn("[0xseanlee UI] "..tostring(err)); window:Notify({Title="Callback error",Content="See the console for details."}) end
    end
    -- Navigation stays independent of the scrollable page.
    local rail=new("Frame",{Name="Navigation",Position=UDim2.fromOffset(0,STYLE.Header),Size=UDim2.new(0,STYLE.Sidebar,1,-STYLE.Header),BackgroundColor3=C.Sidebar,BackgroundTransparency=0.35,BorderSizePixel=0},root)
    local sidebar=new("ScrollingFrame",{Name="Sidebar",Position=UDim2.fromOffset(15,15),Size=UDim2.new(1,-30,1,-68),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=2,ScrollBarImageColor3=C.Accent,ScrollBarImageTransparency=0.75,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y},rail)
    local tabLayout=new("UIListLayout",{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder},sidebar)
    local divider=new("Frame",{Name="Divider",BackgroundColor3=C.Border,BackgroundTransparency=0.3,BorderSizePixel=0},root)
    local tabCount=text(rail,"0 tabs",11,C.Dim,{Position=UDim2.new(0,18,1,-44),Size=UDim2.new(1,-36,0,16)})
    local shortcut=text(rail,toggleKey.Name.."  to hide",10,C.Muted,{Position=UDim2.new(0,18,1,-26),Size=UDim2.new(1,-36,0,16)})
    local pageHeader=new("Frame",{Position=UDim2.fromOffset(STYLE.ContentX,STYLE.Header+15),Size=UDim2.new(1,-STYLE.ContentX-15,0,38),BackgroundTransparency=1},root)
    local pageTitle=text(pageHeader,"",18,C.Text,{Size=UDim2.new(0.5,-10,0,23),Font=Enum.Font.GothamBold})
    local pageCount=text(pageHeader,"",10,C.Muted,{Position=UDim2.fromOffset(0,24),Size=UDim2.new(0.5,-10,0,14)})
    local searchWrap=new("Frame",{AnchorPoint=Vector2.new(1,0),Position=UDim2.fromScale(1,0),Size=UDim2.fromOffset(222,34),BackgroundColor3=C.Row,BorderSizePixel=0},pageHeader)
    corner(searchWrap,8); local searchStroke=stroke(searchWrap,C.Border,0.5)
    local searchIcon=icon(searchWrap,"search",C.Dim); searchIcon.Position=UDim2.fromOffset(8,6)
    local search=new("TextBox",{Name="Search",Position=UDim2.fromOffset(35,0),Size=UDim2.new(1,-66,1,0),BackgroundTransparency=1,Text="",PlaceholderText="Search controls...",PlaceholderColor3=C.Dim,TextColor3=C.Text,TextSize=12,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ClearTextOnFocus=false},searchWrap)
    local clear=button(searchWrap,{Name="Clear",Position=UDim2.new(1,-29,0,5),Size=UDim2.fromOffset(24,24),Visible=false})
    line(clear,9,9,15,15,C.Muted); line(clear,15,9,9,15,C.Muted)
    local content=new("Frame",{Name="Content",Position=UDim2.fromOffset(STYLE.ContentX,STYLE.ContentTop),Size=UDim2.new(1,-STYLE.ContentX-15,1,-STYLE.ContentTop-15),BackgroundTransparency=1},root)
    local empty=text(content,"No matching controls",14,C.Muted,{TextXAlignment=Enum.TextXAlignment.Center,Visible=false})
    local function layoutTab(tab)
        if compact then
            tab._nav.Size=UDim2.fromOffset(tab._navWidth,COMPACT.TabHeight)
            tab._indicator.AnchorPoint=Vector2.new(0.5,1)
            tab._indicator.Position=UDim2.new(0.5,0,1,-2)
            tab._indicator.Size=UDim2.fromOffset(24,2)
        else
            tab._nav.Size=UDim2.new(1,-2,0,36)
            tab._indicator.AnchorPoint=Vector2.new(0,0.5)
            tab._indicator.Position=UDim2.fromScale(0,0.5)
            tab._indicator.Size=UDim2.fromOffset(3,16)
        end
        tab._icon.Position=UDim2.fromOffset(12,compact and 10 or 7)
    end
    local function revealTab()
        if not compact or not window.SelectedTab then return end
        local selected=window.SelectedTab
        task.defer(function()
            if window._destroyed or not compact or window.SelectedTab~=selected then return end
            local left=0
            for _,tab in ipairs(window.Tabs) do
                if tab==selected then break end
                left=left+tab._navWidth+COMPACT.TabGap
            end
            local visibleWidth=width-2*COMPACT.Inset
            local right=left+selected._navWidth-visibleWidth
            local canvasX=sidebar.CanvasPosition.X
            if canvasX>left then canvasX=left elseif canvasX<right then canvasX=right end
            sidebar.CanvasPosition=Vector2.new(canvasX,0)
        end)
    end
    local function layoutWindow()
        local headerHeight=compact and COMPACT.Header or STYLE.Header
        local contentX=compact and COMPACT.Inset or STYLE.ContentX
        local rightInset=compact and COMPACT.Inset or 15
        local showsSubtitle=not compact or width>=440
        local buttonSize=compact and 42 or 38
        header.Size=UDim2.new(1,compact and -104 or -100,0,headerHeight)
        heading.Size=showsSubtitle and UDim2.new(0.6,-28,1,0) or UDim2.new(1,-36,1,0)
        subtitle.Visible=showsSubtitle
        minimize.Size=UDim2.fromOffset(buttonSize,buttonSize)
        close.Size=UDim2.fromOffset(buttonSize,buttonSize)
        minimize.Position=UDim2.new(1,-53,0,(headerHeight-buttonSize)/2)
        close.Position=UDim2.new(1,-8,0,(headerHeight-buttonSize)/2)
        tabCount.Visible=not compact
        shortcut.Visible=not compact
        if compact then
            rail.Position=UDim2.fromOffset(0,headerHeight)
            rail.Size=UDim2.new(1,0,0,53)
            sidebar.Position=UDim2.fromOffset(COMPACT.Inset,4)
            sidebar.Size=UDim2.new(1,-2*COMPACT.Inset,0,47)
            divider.Position=UDim2.new(0,COMPACT.Inset,0,102)
            divider.Size=UDim2.new(1,-2*COMPACT.Inset,0,1)
        else
            rail.Position=UDim2.fromOffset(0,headerHeight)
            rail.Size=UDim2.new(0,STYLE.Sidebar,1,-headerHeight)
            sidebar.Position=UDim2.fromOffset(15,15)
            sidebar.Size=UDim2.new(1,-30,1,-68)
            divider.Position=UDim2.fromOffset(STYLE.Sidebar,headerHeight+15)
            divider.Size=UDim2.new(0,1,1,-headerHeight-30)
        end
        sidebar.AutomaticCanvasSize=compact and Enum.AutomaticSize.X or Enum.AutomaticSize.Y
        sidebar.ScrollingDirection=compact and Enum.ScrollingDirection.X or Enum.ScrollingDirection.Y
        tabLayout.FillDirection=compact and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical
        tabLayout.Padding=UDim.new(0,compact and COMPACT.TabGap or 8)
        local searchWidth=compact and math.min(222,math.floor((width-2*COMPACT.Inset)*0.5)) or 222
        pageHeader.Position=UDim2.fromOffset(contentX,compact and 110 or headerHeight+15)
        pageHeader.Size=UDim2.new(1,-contentX-rightInset,0,38)
        pageTitle.Size=UDim2.new(1,-searchWidth-12,0,23)
        pageCount.Size=UDim2.new(1,-searchWidth-12,0,14)
        searchWrap.Size=UDim2.fromOffset(searchWidth,compact and 36 or 34)
        search.PlaceholderText=compact and "Search..." or "Search controls..."
        local top=compact and COMPACT.ContentTop or STYLE.ContentTop
        content.Position=UDim2.fromOffset(contentX,top)
        content.Size=UDim2.new(1,-contentX-rightInset,1,-top-rightInset)
        rowWidth=width-contentX-rightInset-9
        for _,tab in ipairs(window.Tabs) do layoutTab(tab) end
        for _,control in ipairs(window._controls) do control:_layout() end
        revealTab()
    end
    local function fit()
        local viewport=gui.AbsoluteSize
        if viewport.X<=0 or viewport.Y<=0 then return end
        local availableW,availableH=math.max(1,viewport.X-20),math.max(1,viewport.Y-20)
        local desktopScale=math.min(availableW/STYLE.Width,availableH/STYLE.Height)
        local nextCompact=desktopScale<math.min(window._scale,1)*0.9
        local scale=math.min(window._scale,desktopScale)
        local nextWidth,nextHeight=STYLE.Width,STYLE.Height
        if nextCompact then
            scale=math.min(window._scale,availableW/320,availableH/260)
            nextWidth=math.min(STYLE.Width,math.floor(availableW/scale))
            nextHeight=math.min(STYLE.Height,math.floor(availableH/scale))
        end
        scaler.Scale=scale
        root.Size=UDim2.fromOffset(nextWidth,nextHeight)
        toastHost.Size=UDim2.fromOffset(math.clamp(viewport.X-36,1,360),250)
        restore.Position=UDim2.fromOffset(14,math.clamp(viewport.Y*0.18,12,100))
        if nextCompact~=compact then sidebar.CanvasPosition=Vector2.new(0,0) end
        if nextCompact~=compact or width~=nextWidth or height~=nextHeight then
            compact,width,height=nextCompact,nextWidth,nextHeight
            layoutWindow()
        end
        clampPosition()
    end
    connect(gui:GetPropertyChangedSignal("AbsoluteSize"),fit)
    function window:SetScale(value)
        if not finite(value) or value<=0 then return false end
        self._scale=value
        fit()
        return true
    end
    function window:ResetPosition()
        root.Position=UDim2.fromScale(0.5,0.5)
        fit()
    end
    layoutWindow()
    fit()
    local function refreshSearch()
        for _,tab in ipairs(window.Tabs) do
            local count=0
            for _,section in ipairs(tab._sections) do section.Frame.Visible=false end
            for _,control in ipairs(tab._elements) do
                local haystack=string.lower(control._name.." "..control._description.." "..(control._section and control._section._name or ""))
                local match=window._query=="" or string.find(haystack,window._query,1,true)~=nil
                control.Frame.Visible=control._visible and match
                if control.Frame.Visible then
                    count=count+1
                    if control._section then control._section.Frame.Visible=control._section._visible end
                end
            end
            if window._query=="" then for _,section in ipairs(tab._sections) do section.Frame.Visible=section._visible end end
            if tab==window.SelectedTab then
                pageCount.Text=tostring(count)..(count==1 and " control" or " controls")
                empty.Visible=count==0 and window._query~=""
            end
        end
        local focused=UIS:GetFocusedTextBox()
        if focused then
            for _,control in ipairs(window._controls) do
                if focused:IsDescendantOf(control.Frame) and not control:_canUse() then focused:ReleaseFocus(false); break end
            end
        end
    end
    function window:SetSearch(query)
        local nextQuery=string.lower(tostring(query or ""))
        local different=nextQuery~=self._query
        self._query=nextQuery
        if different then cancelInteraction() end
        if search.Text~=tostring(query or "") then search.Text=tostring(query or "") end
        clear.Visible=self._query~=""
        if self._openDropdown then self._openDropdown:_expand(false) end
        if different then
            for _,tab in ipairs(self.Tabs) do tab._page.CanvasPosition=Vector2.new(0,0) end
        end
        refreshSearch()
    end
    connect(search:GetPropertyChangedSignal("Text"),function() window:SetSearch(search.Text) end)
    connect(clear.Activated,function() window:SetSearch("") end)
    connect(search.Focused,function() animate(searchStroke,{Color=C.Accent,Transparency=0.25}) end)
    connect(search.FocusLost,function() animate(searchStroke,{Color=C.Border,Transparency=0.5}) end)
    function window:GetControl(flag)
        for _,control in ipairs(self._controls) do if control.Flag==flag then return control end end
    end
    local function measure(value,width,size)
        return TextService:GetTextSize(tostring(value),size or 12,measureFont,Vector2.new(math.max(1,width),10000)).Y
    end
    function window:CreateTab(name,iconName)
        if type(name)=="table" then iconName=name.Icon; name=name.Name end
        local tab={Name=name or "Tab",_order=0,_elements={},_sections={}}
        local labelWidth=TextService:GetTextSize(tostring(tab.Name),15,measureFont,Vector2.new(200,100)).X
        tab._navWidth=math.clamp(math.ceil(labelWidth)+57,104,200)
        table.insert(self.Tabs,tab); tabCount.Text=tostring(#self.Tabs).." tabs"
        local nav=button(sidebar,{Name=tab.Name,LayoutOrder=#self.Tabs,Size=UDim2.new(1,-2,0,36),BackgroundColor3=C.Row,BackgroundTransparency=0})
        corner(nav,8); local navStroke=stroke(nav,C.Accent,1)
        local navIcon=icon(nav,iconName or "list",C.Muted)
        local navText=text(nav,tab.Name,15,C.Muted,{Position=UDim2.fromOffset(45,0),Size=UDim2.new(1,-54,1,0),Font=Enum.Font.GothamMedium})
        local indicator=new("Frame",{Position=UDim2.new(0,0,0.5,-8),Size=UDim2.fromOffset(3,16),BackgroundColor3=C.Accent,BorderSizePixel=0,Visible=false},nav)
        corner(indicator,2)
        local page=new("ScrollingFrame",{Name=tab.Name,Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=C.Accent,ScrollBarImageTransparency=0.5,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,Visible=false},content)
        new("UIListLayout",{Padding=UDim.new(0,7),SortOrder=Enum.SortOrder.LayoutOrder},page)
        new("UIPadding",{PaddingBottom=UDim.new(0,8),PaddingRight=UDim.new(0,8),PaddingLeft=UDim.new(0,1),PaddingTop=UDim.new(0,1)},page)
        tab._page,tab._nav,tab._text,tab._indicator=page,nav,navText,indicator
        function tab:Select()
            if window._destroyed then return end
            cancelInteraction(); window.SelectedTab=self; pageTitle.Text=self.Name
            for _,other in ipairs(window.Tabs) do
                local selected=other==self
                other._page.Visible=selected; other._indicator.Visible=selected
                animate(other._text,{TextColor3=selected and C.Text or C.Muted})
                animate(other._nav,{BackgroundColor3=selected and C.Selected or C.Row,BackgroundTransparency=0})
                animate(other._navStroke,{Transparency=selected and 0.8 or 1})
                for _,part in ipairs(other._icon:GetDescendants()) do
                    if part:IsA("Frame") and part.BackgroundTransparency~=1 then animate(part,{BackgroundColor3=selected and C.Accent or C.Muted})
                    elseif part:IsA("UIStroke") then animate(part,{Color=selected and C.Accent or C.Muted})
                    elseif part:IsA("TextLabel") then animate(part,{TextColor3=selected and C.Accent or C.Muted}) end
                end
            end
            local focused=UIS:GetFocusedTextBox()
            if focused then
                for _,other in ipairs(window.Tabs) do
                    if other~=self and focused:IsDescendantOf(other._page) then focused:ReleaseFocus(false); break end
                end
            end
            refreshSearch()
            revealTab()
        end
        tab._navStroke,tab._icon=navStroke,navIcon
        layoutTab(tab)
        connect(nav.Activated,function() tab:Select() end)
        connect(nav.MouseEnter,function() if window.SelectedTab~=tab then animate(nav,{BackgroundColor3=C.Hover}) end end)
        connect(nav.MouseLeave,function() if window.SelectedTab~=tab then animate(nav,{BackgroundColor3=C.Row}) end end)
        if #window.Tabs==1 then tab:Select() end
        local function order(obj) tab._order=tab._order+1; obj.LayoutOrder=tab._order end
        local function register(obj,opts,value)
            obj.Value=value
            if opts.Flag then window.Values[opts.Flag]=value end
        end
        local function changed(obj,opts,value,silent)
            local different=obj.Value~=value
            register(obj,opts,value)
            if different and not silent then call(opts.Callback,value) end
        end
        local function row(opts,reserve,canStack)
            local obj={_name=tostring(opts.Name or "Element"),_description=tostring(opts.Description or ""),_visible=true,_disabled=opts.Disabled==true,Flag=opts.Flag,_section=tab._section,_tab=tab}
            local r=new("Frame",{Name=obj._name,BackgroundColor3=C.Row,BorderSizePixel=0},page)
            corner(r,STYLE.CardRadius); local border=stroke(r,C.Border,1); order(r)
            local title=text(r,obj._name,STYLE.ControlFont,C.Text,{Font=Enum.Font.GothamMedium})
            local desc=text(r,obj._description,STYLE.DescriptionFont,C.Muted,{TextWrapped=true,TextYAlignment=Enum.TextYAlignment.Top,TextTruncate=Enum.TextTruncate.None})
            obj.Frame,obj._title,obj._desc=r,title,desc
            function obj:_layout()
                self._stacked=canStack and compact and rowWidth<500
                local padding=14+(self._stacked and 14 or reserve)
                local hasDescription=self._description~=""
                local minHeight=compact and 46 or STYLE.RowHeight
                local descHeight=hasDescription and measure(self._description,rowWidth-padding,STYLE.DescriptionFont) or 0
                local textHeight=hasDescription and math.max(STYLE.DescriptionHeight,29+descHeight+10) or minHeight
                self._height=textHeight+(self._stacked and COMPACT.FieldHeight+8 or 0)
                local fixedTitle=hasDescription or self._stacked
                title.Position=UDim2.fromOffset(14,fixedTitle and 8 or 0)
                title.Size=UDim2.new(1,-padding,fixedTitle and 0 or 1,fixedTitle and 19 or 0)
                desc.Visible=hasDescription
                desc.Position=UDim2.fromOffset(14,29)
                desc.Size=UDim2.new(1,-padding,0,descHeight)
                r.Size=UDim2.new(1,0,0,self._height)
                if self._afterLayout then self:_afterLayout() end
            end
            local function repaint()
                animate(title,{TextColor3=obj._disabled and C.Dim or C.Text})
                animate(desc,{TextColor3=obj._disabled and C.Dim or C.Muted})
                if obj._paint then obj:_paint() end
            end
            function obj:SetDisabled(value)
                self._disabled=value==true
                if self._disabled then
                    local focused=UIS:GetFocusedTextBox()
                    if focused and focused:IsDescendantOf(r) then focused:ReleaseFocus(false) end
                    if window._listening==self then self:_cancelCapture() end
                    if window._openDropdown==self then self:_expand(false) end
                    if window._drag and window._drag.Owner==self then cancelInteraction() end
                end
                repaint()
            end
            function obj:SetVisible(value)
                self._visible=value==true
                if not self._visible then
                    if window._listening==self or window._openDropdown==self or (window._drag and window._drag.Owner==self) then cancelInteraction() end
                end
                refreshSearch()
            end
            function obj:_canUse() return not self._disabled and self._visible and r.Visible and page.Visible and root.Visible and not window._destroyed end
            connect(r.MouseEnter,function() if not obj._disabled then animate(r,{BackgroundColor3=C.Hover}); animate(border,{Transparency=0.65}) end end)
            connect(r.MouseLeave,function() animate(r,{BackgroundColor3=C.Row}); animate(border,{Transparency=1}) end)
            table.insert(tab._elements,obj); table.insert(window._controls,obj)
            obj:_layout()
            obj:SetDisabled(obj._disabled); refreshSearch()
            return obj
        end
        local function field(parent,width,height,y)
            local f=new("Frame",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-12,0,y),Size=UDim2.fromOffset(width,height or STYLE.FieldHeight),BackgroundColor3=C.Field,BorderSizePixel=0},parent)
            corner(f,6); return f,stroke(f,C.Border,1)
        end
        local function layoutField(obj,holder,width,desktopHeight,compactHeight)
            local h=compact and compactHeight or desktopHeight
            local y=obj._stacked and obj._height-8-h/2 or obj._height/2
            holder.Position=UDim2.new(1,-12,0,y)
            holder.Size=UDim2.new(obj._stacked and 1 or 0,obj._stacked and -24 or width,0,h)
        end
        function tab:CreateSection(name)
            local section={_name=tostring(name),_visible=true}
            local frame=new("Frame",{Name="Section",Size=UDim2.new(1,0,0,31),BackgroundTransparency=1},page)
            local label=text(frame,name,23,C.Text,{Position=UDim2.fromOffset(3,5),Size=UDim2.new(1,-15,1,-5),Font=Enum.Font.GothamBold})
            order(frame); section.Frame=frame
            function section:Set(value) self._name=tostring(value); label.Text=self._name; refreshSearch() end
            function section:SetVisible(value) self._visible=value==true; refreshSearch() end
            tab._section=section; table.insert(tab._sections,section); refreshSearch(); return section
        end
        function tab:CreateParagraph(opts)
            local obj=row({Name=opts.Title or opts.Name or "Paragraph",Description=opts.Content},14)
            function obj:Set(value)
                if value.Title~=nil then self._name=tostring(value.Title); self._title.Text=self._name end
                if value.Content~=nil then self._description=tostring(value.Content); self._desc.Text=self._description end
                self:_layout()
                refreshSearch()
            end
            return obj
        end
        function tab:CreateButton(opts)
            local obj=row(opts,46)
            local arrow=chevron(obj.Frame,C.Muted,"right"); arrow.Position=UDim2.new(1,-32,0.5,-8)
            local hit=button(obj.Frame,{Name="Activate",Size=UDim2.fromScale(1,1)})
            obj._hit=hit
            connect(hit.Activated,function() if obj:_canUse() then call(opts.Callback) end end)
            function obj:Set(value) self._name=tostring(value); self._title.Text=self._name; refreshSearch() end
            return obj
        end
        function tab:CreateToggle(opts)
            local obj=row(opts,84)
            local track=new("Frame",{Name="Track",AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-14,0.5,0),Size=UDim2.fromOffset(53,27),BackgroundColor3=C.Field,BorderSizePixel=0},obj.Frame)
            corner(track,20)
            local knob=new("Frame",{Name="Knob",Position=UDim2.fromOffset(4,4),Size=UDim2.fromOffset(19,19),BackgroundColor3=C.Inactive,BorderSizePixel=0},track); corner(knob,20)
            local hit=button(obj.Frame,{Name="Activate",Size=UDim2.fromScale(1,1)}); obj._hit=hit
            function obj:_paint()
                local active=self.Value and not self._disabled
                animate(track,{BackgroundColor3=active and C.Field:Lerp(C.Accent,0.22) or C.Field})
                animate(knob,{Position=UDim2.fromOffset(self.Value and 30 or 4,4),BackgroundColor3=self._disabled and C.Dim or (self.Value and C.Accent or C.Inactive)})
            end
            function obj:Set(value,silent) changed(self,opts,value==true,silent); if not window._destroyed then self:_paint() end end
            connect(hit.Activated,function() if obj:_canUse() then obj:Set(not obj.Value) end end)
            obj:Set(opts.CurrentValue==true,true); return obj
        end
        function tab:CreateSlider(opts)
            local range=opts.Range or {0,100}
            local low,high=range[1],range[2]; local step=opts.Increment or 1
            assert(finite(low) and finite(high) and high>low,"Slider Range must contain two increasing finite numbers")
            assert(finite(step) and step>0,"Slider Increment must be a positive finite number")
            assert(opts.CurrentValue==nil or finite(opts.CurrentValue),"Slider CurrentValue must be finite")
            local obj=row(opts,100)
            local valueField,valueStroke=field(obj.Frame,78,27,23)
            local box=new("TextBox",{Name="Value",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text="",TextColor3=C.Text,TextSize=12,Font=Enum.Font.GothamMedium,ClearTextOnFocus=false},valueField)
            local track=new("Frame",{Name="Track",Position=UDim2.new(0,16,1,-18),Size=UDim2.new(1,-32,0,4),BackgroundColor3=C.Field,BorderSizePixel=0},obj.Frame); corner(track,4)
            local fill=new("Frame",{Size=UDim2.fromScale(0,1),BackgroundColor3=C.Accent,BorderSizePixel=0},track); corner(fill,4)
            local knob=new("Frame",{Name="Knob",AnchorPoint=Vector2.new(0.5,0.5),Size=UDim2.fromOffset(10,10),Position=UDim2.fromScale(0,0.5),BackgroundColor3=C.Text,BorderSizePixel=0},track); corner(knob,12)
            local hit=button(obj.Frame,{Name="SliderHit",Position=UDim2.new(0,6,1,-31),Size=UDim2.new(1,-12,0,29)})
            obj._track,obj._knob,obj._box,obj._hit=track,knob,box,hit
            function obj:_afterLayout()
                local hitHeight=compact and 44 or 32
                self.Frame.Size=UDim2.new(1,0,0,self._height+hitHeight-5)
                self._title.Position=UDim2.fromOffset(14,self._description=="" and 11 or 8)
                self._title.Size=UDim2.new(1,-114,0,19)
                valueField.Size=UDim2.fromOffset(78,compact and 34 or 27)
                track.Position=UDim2.new(0,16,1,-math.floor(hitHeight/2)-2)
                track.Size=UDim2.new(1,-32,0,compact and 6 or 4)
                hit.Position=UDim2.new(0,6,1,-hitHeight)
                hit.Size=UDim2.new(1,-12,0,hitHeight)
            end
            obj:_afterLayout()
            local function display() box.Text=tostring(obj.Value or low)..(opts.Suffix or "") end
            function obj:_paint()
                box.TextEditable=not self._disabled
                animate(fill,{BackgroundColor3=self._disabled and C.Dim or C.Accent})
                animate(knob,{BackgroundColor3=self._disabled and C.Dim or C.Text})
                animate(box,{TextColor3=self._disabled and C.Dim or C.Text})
            end
            function obj:Set(value,silent)
                value=tonumber(value)
                if not finite(value) then return false end
                value=math.clamp(value,low,high)
                if value~=high then value=math.clamp(low+math.floor((value-low)/step+0.5)*step,low,high) end
                value=tonumber(string.format("%.8f",value))
                local ratio=(value-low)/(high-low)
                fill.Size=UDim2.fromScale(ratio,1); knob.Position=UDim2.fromScale(ratio,0.5)
                changed(self,opts,value,silent)
                if not window._destroyed then display() end
                return true
            end
            connect(box.Focused,function()
                if not obj:_canUse() then box:ReleaseFocus(false); return end
                box.Text=tostring(obj.Value); animate(valueStroke,{Color=C.Accent,Transparency=0.3})
            end)
            connect(box.FocusLost,function()
                if obj:_canUse() then obj:Set(box.Text) end
                display(); animate(valueStroke,{Color=C.Border,Transparency=0.7})
            end)
            connect(hit.MouseEnter,function() if obj:_canUse() then animate(knob,{Size=UDim2.fromOffset(13,13)}) end end)
            connect(hit.MouseLeave,function() if not window._drag then animate(knob,{Size=UDim2.fromOffset(10,10)}) end end)
            connect(hit.InputBegan,function(input)
                if not obj:_canUse() or window._drag or not pointerBegan(input) then return end
                cancelInteraction()
                local function update(position)
                    if obj:_canUse() and track.AbsoluteSize.X>0 then obj:Set(low+math.clamp((position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)*(high-low)) end
                end
                local wasScrolling=page.ScrollingEnabled
                page.ScrollingEnabled=false
                window._drag={Owner=obj,Input=input,Update=update,Finish=function() page.ScrollingEnabled=wasScrolling; animate(knob,{Size=UDim2.fromOffset(10,10)}) end}
                animate(knob,{Size=UDim2.fromOffset(14,14)}); update(input.Position)
            end)
            obj:Set(opts.CurrentValue or low,true); obj:_paint(); return obj
        end
        function tab:CreateDropdown(opts)
            local obj=row(opts,STYLE.FieldWidth+24,true)
            obj.Frame.ClipsDescendants=true
            obj._optionConnections={}
            local selectedField,selectedStroke=field(obj.Frame,STYLE.FieldWidth,STYLE.FieldHeight,obj._height/2)
            local selectedText=text(selectedField,"Select...",14,C.Text,{Position=UDim2.fromOffset(10,0),Size=UDim2.new(1,-38,1,0),Font=Enum.Font.GothamMedium})
            local arrow=chevron(selectedField,C.Muted); arrow.Position=UDim2.new(1,-24,0.5,-8)
            local hit=button(obj.Frame,{Name="DropdownHit"})
            obj._hit=hit
            local queryBox=new("TextBox",{Name="OptionSearch",BackgroundColor3=C.Field,BorderSizePixel=0,
                Text="",PlaceholderText="Find an option...",PlaceholderColor3=C.Dim,TextColor3=C.Text,TextSize=12,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ClearTextOnFocus=false,Visible=false},obj.Frame)
            corner(queryBox,6); new("UIPadding",{PaddingLeft=UDim.new(0,10)},queryBox)
            local list=new("ScrollingFrame",{Name="Options",BackgroundTransparency=1,BorderSizePixel=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=2,ScrollBarImageColor3=C.Accent,Visible=false},obj.Frame)
            new("UIListLayout",{Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder},list)
            local noOptions=text(obj.Frame,"No matching options",12,C.Muted,{Size=UDim2.new(1,-36,0,30),Visible=false})
            local values,items={},{}
            local open=false
            local function layoutOptions()
                local q=string.lower(queryBox.Text); local count=0
                for _,item in ipairs(items) do
                    item.Button.Visible=q=="" or string.find(string.lower(tostring(item.Value)),q,1,true)~=nil
                    if item.Button.Visible then count=count+1 end
                end
                local searchable=#values>6
                local searchHeight=compact and COMPACT.FieldHeight or 30
                local itemHeight=compact and 40 or 30
                local top=obj._height+(searchable and searchHeight+10 or 4)
                local listHeight=math.max(1,math.min(count,4))*(itemHeight+4)
                queryBox.Position=UDim2.fromOffset(10,obj._height+4)
                queryBox.Size=UDim2.new(1,-20,0,searchHeight)
                queryBox.Visible=open and searchable; list.Visible=open and count>0
                list.Position=UDim2.fromOffset(10,top); list.Size=UDim2.new(1,-20,0,listHeight)
                noOptions.Position=UDim2.fromOffset(18,top); noOptions.Visible=open and count==0
                obj.Frame.Size=UDim2.new(1,0,0,open and top+listHeight+10 or obj._height)
            end
            function obj:_afterLayout()
                layoutField(self,selectedField,STYLE.FieldWidth,STYLE.FieldHeight,COMPACT.FieldHeight)
                hit.Size=UDim2.new(1,0,0,self._height)
                for _,item in ipairs(items) do
                    item.Button.Size=UDim2.new(1,-5,0,compact and 40 or 30)
                end
                layoutOptions()
            end
            function obj:_paint()
                selectedText.TextColor3=self._disabled and C.Dim or C.Text
                for _,item in ipairs(items) do
                    local selected=item.Value==self.Value
                    animate(item.Button,{BackgroundColor3=selected and C.Selected or C.Field})
                    item.Mark.Visible=selected; item.Label.TextColor3=selected and C.Accent or C.Text
                end
            end
            function obj:_expand(value)
                open=value==true and #values>0 and self:_canUse()
                if open then
                    if window._openDropdown and window._openDropdown~=self then window._openDropdown:_expand(false) end
                    window._openDropdown=self
                elseif window._openDropdown==self then window._openDropdown=nil end
                animate(arrow,{Rotation=open and 180 or 0})
                animate(selectedStroke,{Color=open and C.Accent or C.Border,Transparency=open and 0.35 or 0.7})
                if not open then queryBox.Text=""; if UIS:GetFocusedTextBox()==queryBox then queryBox:ReleaseFocus(false) end end
                layoutOptions()
            end
            function obj:Set(value,silent)
                local valid=false
                for _,v in ipairs(values) do if v==value then valid=true; break end end
                if not valid then return false end
                selectedText.Text=tostring(value)
                changed(self,opts,value,silent)
                if not window._destroyed then self:_paint() end
                return true
            end
            function obj:Refresh(newValues)
                assert(type(newValues)=="table","Dropdown options must be a table")
                for _,conn in ipairs(self._optionConnections) do conn:Disconnect() end
                self._optionConnections={}
                for _,item in ipairs(items) do item.Button:Destroy() end
                values={}; items={}
                for _,value in ipairs(newValues) do table.insert(values,value) end
                for index,value in ipairs(values) do
                    local item=button(list,{Name="Option",LayoutOrder=index,Size=UDim2.new(1,-5,0,compact and 40 or 30),BackgroundTransparency=0,BackgroundColor3=C.Field})
                    corner(item,6)
                    local label=text(item,tostring(value),12,C.Text,{Position=UDim2.fromOffset(11,0),Size=UDim2.new(1,-42,1,0)})
                    local mark=new("Frame",{Position=UDim2.new(1,-25,0.5,-6),Size=UDim2.fromOffset(14,14),BackgroundTransparency=1,Visible=false},item)
                    line(mark,2,7,6,11,C.Accent,1.7); line(mark,6,11,13,3,C.Accent,1.7)
                    table.insert(items,{Value=value,Button=item,Label=label,Mark=mark})
                    connect(item.Activated,function() if obj:_canUse() then obj:Set(value); if not window._destroyed then obj:_expand(false) end end end,self._optionConnections)
                end
                local retained=false
                for _,v in ipairs(values) do if v==self.Value then retained=true end end
                if not retained then
                    if values[1]~=nil then self:Set(values[1],true)
                    else selectedText.Text="No options"; register(self,opts,nil) end
                end
                self:_paint(); self:_expand(false)
            end
            connect(hit.Activated,function() if obj:_canUse() then obj:_expand(not open) end end)
            connect(queryBox:GetPropertyChangedSignal("Text"),layoutOptions)
            obj:_afterLayout()
            obj:Refresh(opts.Options or {})
            if opts.CurrentOption~=nil then obj:Set(opts.CurrentOption,true) end
            return obj
        end
        function tab:CreateInput(opts)
            local obj=row(opts,STYLE.FieldWidth+24,true)
            local holder,border=field(obj.Frame,STYLE.FieldWidth,STYLE.FieldHeight,obj._height/2)
            local box=new("TextBox",{Name="Input",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text=tostring(opts.CurrentValue or ""),PlaceholderText=opts.PlaceholderText or "Type here...",PlaceholderColor3=C.Dim,TextColor3=C.Text,Font=Enum.Font.GothamBold,TextSize=14,TextXAlignment=Enum.TextXAlignment.Left,ClearTextOnFocus=false},holder)
            new("UIPadding",{PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10)},box)
            obj._box=box
            function obj:_afterLayout()
                layoutField(self,holder,STYLE.FieldWidth,STYLE.FieldHeight,COMPACT.FieldHeight)
            end
            obj:_afterLayout()
            function obj:_paint() box.TextEditable=not self._disabled; box.TextColor3=self._disabled and C.Dim or C.Text end
            function obj:Set(value,silent) box.Text=tostring(value); changed(self,opts,box.Text,silent) end
            connect(box.Focused,function()
                if not obj:_canUse() then box:ReleaseFocus(false); return end
                animate(border,{Color=C.Accent,Transparency=0.3})
            end)
            connect(box.FocusLost,function(enterPressed)
                animate(border,{Color=C.Border,Transparency=0.7})
                if obj:_canUse() and (not opts.EnterOnly or enterPressed) then obj:Set(box.Text) else box.Text=tostring(obj.Value or "") end
            end)
            register(obj,opts,box.Text); obj:_paint(); return obj
        end
        function tab:CreateKeybind(opts)
            local obj=row(opts,157,true)
            local holder,border=field(obj.Frame,132,30,obj._height/2)
            local hit=button(holder,{Name="Keybind",Size=UDim2.fromScale(1,1),TextColor3=C.Text,TextSize=11,Font=Enum.Font.GothamMedium})
            obj._hit=hit
            function obj:_afterLayout()
                layoutField(self,holder,132,30,COMPACT.FieldHeight)
            end
            obj:_afterLayout()
            function obj:_paint() hit.TextColor3=self._disabled and C.Dim or C.Text end
            function obj:_cancelCapture()
                if window._listening==self then window._listening=nil end
                hit.Text=self.Value and self.Value.Name or "None"
                animate(border,{Color=C.Border,Transparency=0.7})
            end
            function obj:Set(key)
                key=keycode(key)
                if not key then return false end
                register(self,opts,key); self:_cancelCapture(); return true
            end
            connect(hit.Activated,function()
                if not obj:_canUse() then return end
                cancelInteraction(); window._listening=obj; hit.Text="Press a key..."
                animate(border,{Color=C.Accent,Transparency=0.25})
            end)
            obj._callback=opts.Callback
            assert(obj:Set(opts.CurrentKeybind or Enum.KeyCode.F),"Invalid CurrentKeybind")
            table.insert(window._keybinds,obj)
            obj:_paint(); return obj
        end
        return tab
    end
    -- One input router for all controls, regardless of their count.
    connect(header.InputBegan,function(input)
        if window._drag or not pointerBegan(input) then return end
        cancelInteraction()
        local start=input.Position; local origin=root.Position; local size=gui.AbsoluteSize
        local x,y=origin.X.Scale*size.X+origin.X.Offset,origin.Y.Scale*size.Y+origin.Y.Offset
        window._drag={Input=input,Update=function(position)
            root.Position=UDim2.fromOffset(x+position.X-start.X,y+position.Y-start.Y); clampPosition()
        end}
    end)
    connect(UIS.InputChanged,function(input)
        local drag=window._drag
        if not drag or not root.Visible then return end
        local mouseDrag=drag.Input.UserInputType==Enum.UserInputType.MouseButton1
        if (mouseDrag and input.UserInputType==Enum.UserInputType.MouseMovement) or input==drag.Input then
            drag.Update(input.Position)
        end
    end)
    connect(UIS.InputEnded,function(input)
        local drag=window._drag
        if drag and (input==drag.Input or (drag.Input.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseButton1)) then
            if drag.Finish then drag.Finish() end
            window._drag=nil
        end
    end)
    connect(UIS.InputBegan,function(input,processed)
        if window._listening then
            if input.UserInputType==Enum.UserInputType.Keyboard then
                if input.KeyCode==Enum.KeyCode.Escape then window._listening:_cancelCapture()
                else window._listening:Set(input.KeyCode) end
            end
            return
        end
        if input.KeyCode==Enum.KeyCode.Escape and root.Visible then
            if window._openDropdown then window._openDropdown:_expand(false) end
            local focused=UIS:GetFocusedTextBox()
            if focused and focused:IsDescendantOf(gui) then focused:ReleaseFocus(false) end
            return
        end
        if window._openDropdown and pointerBegan(input) then
            local frame=window._openDropdown.Frame
            local pos,size=frame.AbsolutePosition,frame.AbsoluteSize
            local point=input.Position
            if point.X<pos.X or point.X>pos.X+size.X or point.Y<pos.Y or point.Y>pos.Y+size.Y then window._openDropdown:_expand(false) end
        end
        if processed or UIS:GetFocusedTextBox() then return end
        if input.KeyCode==toggleKey then window:SetVisible(not root.Visible); return end
        if not root.Visible then return end
        for _,control in ipairs(window._keybinds) do
            if control._callback and control.Value==input.KeyCode and control:_canUse() then call(control._callback,input.KeyCode) end
        end
    end)
    connect(UIS.WindowFocusReleased,function() cancelInteraction() end)
    function window:SetTitle(value) heading.Text=tostring(value) end
    function window:SetSubtitle(value) subtitle.Text=tostring(value) end
    env.__VELVET_UI_WINDOW=window
    return window
end
return Library
