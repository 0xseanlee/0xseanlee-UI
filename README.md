# 0xseanlee UI

舊 API 和新 API 共用新版介面。已使用 `main/Library.lua`（包含 `refs/heads/main/Library.lua`）的腳本可保留原有呼叫。固定版本或本機副本會維持所用版本。

```lua
local UI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/0xseanlee/0xseanlee-UI/main/Library.lua"
))()

-- 舊程式可繼續這樣用。
local Window = UI:CreateWindow({Name = "My UI"})
local Main = Window:CreateTab("Main", "home")
Main:CreateToggle({Name = "Example", CurrentValue = false, Callback = print})
```

新程式也可以從同一個網址載入，改用 `MakeWindow`、`MakeTab` 和 `AddToggle`。兩套呼叫共用同一套元件。舊版 `SetSearch` 仍可從程式呼叫，畫面使用新版原有的版面。舊版 `Notify` 使用 Roblox 的通知。

每個視窗都會加上 **Settings**。在 **UI Size** 的 **Size** 下拉選單可選 Small、Medium、Large。在 **Color Theme** 的 **Theme** 下拉選單可選 Red 或 Blue。拖曳視窗頂欄可移動視窗，浮動按鈕也能直接拖曳。設定在這次載入的函式庫中有效。

將 [Demo.client.lua](Demo.client.lua) 放進 Roblox Studio 的 `StarterPlayerScripts`，以 Play 開啟空白 Main 分頁與固定的 Settings 分頁。左上的浮動 `0x` 可以切換視窗。要自行建立元件，可把 [Library.lua](Library.lua) 放進 `ReplicatedStorage` 的 ModuleScript，例如命名為 `SeanUI`，然後由 LocalScript 呼叫：

```lua
local UI = require(game:GetService("ReplicatedStorage"):WaitForChild("SeanUI"))
local Window = UI:MakeWindow({ Title = "0xseanlee Hub", SubTitle = "by 0xseanlee" })
local Main = Window:MakeTab({ "Main", "home" })
Main:AddSection({ "Actions" })
Main:AddButton({
    Name = "Hello",
    Callback = function()
        print("Hello")
    end,
})
```

函式庫原始來源固定在 [這個提交](https://github.com/farehamhz/RedzLib/blob/5a5af3e0b1ad13f996a0c3d4a3bf0b35491bedb1/RedzLib)。本專案以 PlayerGui 掛載，Demo 搭配原腳本的文字浮標備援和空白 Main。

執行 `python3 build.py` 重建單檔。用 `luac -p Library.lua` 和 `luac -p Demo.client.lua` 檢查語法。

用 `lua test.lua` 執行新舊 API 的模擬驗證。
