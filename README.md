# 0xseanlee UI

**v1.0.0** 使用 Blox Fruit 腳本所載入的原始介面函式庫。舊版的自製視窗及元件已替換。這是主要版本更新，新的入口是 `MakeWindow`、`MakeTab` 和 `Add…` 系列。需要舊 API 的專案可固定在 [v0.5.0](https://github.com/0xseanlee/0xseanlee-UI/tree/v0.5.0)。

將 [Demo.client.lua](Demo.client.lua) 放進 Roblox Studio 的 `StarterPlayerScripts`，以 Play 開啟空白 Main 分頁。左上的浮動 `0x` 可以切換視窗。要自行建立元件，可把 [Library.lua](Library.lua) 放進 `ReplicatedStorage` 的 ModuleScript，例如命名為 `SeanUI`，然後由 LocalScript 呼叫：

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
