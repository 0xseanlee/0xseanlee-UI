# 0xseanlee UI

Roblox Lua UI 函式庫，提供深色面板、藍紫色強調色、分頁、開關、滑桿、下拉選單、輸入框和快捷鍵。透過設定表建立元件，使用自己的 Callback 接上功能。

目前版本：**v0.3.0**。介面與事件處理由本函式庫實作；沒有內建遊戲自動化功能、遙測或第三方 Logo。

## 1. 最快測試完整 UI

在支援 `game:HttpGet` 和 `loadstring` 的 Lua 執行環境中執行：

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/0xseanlee/0xseanlee-UI/main/Demo.client.lua"))()
```

這會打開包含 Main、Components、Overview 和 Settings 的完整展示介面。也可以直接複製 [Demo.client.lua](Demo.client.lua) 全部內容執行；單檔已包含函式庫，這種方式不需要遠端載入。

操作：

- 拖曳標題列移動視窗。
- 右上角 `−` 收合，按浮動 `V` 按鈕或 `Right Shift` 還原。
- `Right Shift` 隱藏／顯示，輸入文字時不觸發。
- `×` 關閉並清理事件。重複執行會移除前一個視窗。
- 右上方搜尋列可搜尋目前分頁的元件標題、說明與區塊名稱。
- 滑桿可以拖曳，也可以點數值直接輸入。
- 下拉選單超過六個選項會出現選項搜尋。Escape 或點選外部可收合。

## 2. 建立自己的 UI

下面是最小完整範例，複製後即可使用：

```lua
local UI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/0xseanlee/0xseanlee-UI/main/Library.lua"
))()

local Window = UI:CreateWindow({
    Name = "0xseanlee UI",
    Subtitle = "My Script",
    Scale = 1,
    ToggleKey = Enum.KeyCode.RightShift,
    AccentColor = Color3.fromRGB(88, 101, 242),
    ReducedMotion = false,
})

local Main = Window:CreateTab("Main", "home")
Main:CreateSection("Actions")
Main:CreateButton({
    Name = "Say Hello",
    Description = "Click this button to run your own function.",
    Callback = function()
        Window:Notify("Hello!")
        -- 在這裡加入你自己的功能。
    end,
})
```

`Library.lua` 回傳函式庫 table；`CreateWindow` 回傳視窗，`CreateTab` 回傳分頁，各個 `Create...` 方法回傳可更新的元件物件。

若要固定在目前版本、不跟隨 main 的更新，將網址中的 `/main/` 改成 `/v0.3.0/`：

```lua
local UI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/0xseanlee/0xseanlee-UI/v0.3.0/Library.lua"
))()
```

## 3. 所有元件範例

以下程式接在前面的 `Window` 與 `Main` 建立後面：

### 開關

```lua
local MyToggle = Main:CreateToggle({
    Name = "My Toggle",
    Description = "Optional description",
    CurrentValue = false,
    Flag = "my_toggle",
    Callback = function(value)
        print("Toggle:", value) -- boolean
    end,
})

MyToggle:Set(true)        -- 更新並觸發 Callback
MyToggle:Set(false, true) -- 第二個參數 true：靜默更新
print(MyToggle.Value)
```

### 滑桿

```lua
local Speed = Main:CreateSlider({
    Name = "Speed",
    Description = "Drag or type a value",
    Range = {0, 100},
    Increment = 1,
    CurrentValue = 16,
    Suffix = "",
    Flag = "speed",
    Callback = function(value)
        print("Speed:", value) -- number
    end,
})
Speed:Set(25)
```

`Range` 必須遞增，`Increment` 必須大於 0；支援小數步距。數值會按步距取整並限制在範圍內。`Set` 收到無效數值時回傳 false，不改變原值。

### 下拉選單

```lua
local Choice = Main:CreateDropdown({
    Name = "Mode",
    Description = "Choose one option",
    Options = {"One", "Two", "Three"},
    CurrentOption = "Two",
    Flag = "mode",
    Callback = function(value)
        print("Mode:", value)
    end,
})
Choice:Set("Three")
Choice:Refresh({"Apple", "Orange", "Mango"})
```

目前為單選，`CurrentOption` 傳入單一值。沒有指定時選第一個選項；`Refresh` 優先保留仍有效的選項，否則選新清單第一項；空清單會清空值。刷新不觸發 Callback。`Set` 收到清單以外的值回傳 false。

### 輸入框

```lua
local Input = Main:CreateInput({
    Name = "Item Name",
    PlaceholderText = "Type here...",
    CurrentValue = "",
    EnterOnly = false,
    Flag = "item_name",
    Callback = function(value)
        print("Input:", value) -- string
    end,
})
Input:Set("Example")
```

預設離開輸入框時提交；`EnterOnly = true` 時必須按 Enter，未提交的文字會還原。不要將密碼或 token 寫入公開範例。

### 快捷鍵

```lua
local Hotkey = Main:CreateKeybind({
    Name = "Notify Hotkey",
    CurrentKeybind = "F", -- 也可用 Enum.KeyCode.F
    Flag = "notify_key",
    Callback = function(key)
        Window:Notify("Pressed: " .. key.Name)
    end,
})
Hotkey:Set("G")
```

點右側按鍵欄位開始重新綁定，Escape 取消。Callback 只會在元件所在分頁、視窗顯示、元件可用且未輸入文字時觸發。重新綁定本身不觸發 Callback。視窗隱藏快捷鍵由 `CreateWindow.ToggleKey` 設定，與元件綁鍵分開。

### 文字段落與區塊

```lua
local Section = Main:CreateSection("Information")
local Paragraph = Main:CreateParagraph({
    Title = "About",
    Content = "Your description. Long text wraps automatically.",
})
Section:Set("New Title")
Paragraph:Set({Title = "Updated", Content = "New content"})
```

## 4. 狀態與更新

```lua
print(Window.Values.speed)              -- 讀取 Flag 對應的值
local Control = Window:GetControl("speed")
Control:Set(40, true)                   -- 靜默更新
Control:SetDisabled(true)               -- 阻止使用者操作
Control:SetDisabled(false)
Control:SetVisible(false)
Control:SetVisible(true)
```

- 開關、滑桿、選單、輸入框支援 `Set(value, silent)`。
- 按鍵綁定支援 `Set(key)`；按鈕支援 `Set(text)` 更新標題。
- 元件提供 `Value` 和 `Frame`；`Frame` 是底層 GUI 元件。
- 建立元件、設定相同值、靜默更新時不觸發 Callback。
- `Flag` 請使用不重複的字串，對應 `Window.Values`。
- 值只保留於本次執行，沒有設定檔自動儲存。
- 區塊的 `SetVisible` 只控制標題，不會隱藏其下方所有元件。

## 5. 視窗 API

| 方法 | 用途 |
| --- | --- |
| `Window:CreateTab(name, icon)` | 建立分頁 |
| `Tab:Select()` | 切換到該分頁 |
| `Window:SetSearch(text)` | 搜尋目前分頁，空字串清除搜尋 |
| `Window:GetControl(flag)` | 取得對應 Flag 的元件 |
| `Window:SetTitle(text)` | 更新視窗標題 |
| `Window:SetSubtitle(text)` | 更新副標題 |
| `Window:SetScale(number)` | 改變縮放，仍限制在可見畫面內 |
| `Window:ResetPosition()` | 視窗置中 |
| `Window:SetReducedMotion(boolean)` | 減少元件轉場動畫 |
| `Window:SetVisible(boolean)` | 顯示或隱藏視窗 |
| `Window:Notify(text)` | 顯示短通知 |
| `Window:Notify({Title=..., Content=..., Duration=3})` | 自訂通知，時間 1–30 秒 |
| `Window:Destroy()` | 關閉並清理事件 |

分頁圖示可用：`home`、`list`、`chart`、`user`、`settings`、`info`。圖示由本函式庫繪製，不下載遠端圖片。

## 6. Roblox Studio 使用

遠端 `loadstring(game:HttpGet(...))` 載入方式需要執行環境支援，不能直接當成一般 LocalScript 的載入方法。

在 Studio 中可使用 ModuleScript：

1. 在 `ReplicatedStorage` 新增 ModuleScript，命名 `SeanUI`。
2. 將 [Library.lua](Library.lua) 全部內容放進該 ModuleScript。
3. 在 `StarterPlayer > StarterPlayerScripts` 新增 LocalScript：

```lua
local UI = require(game:GetService("ReplicatedStorage"):WaitForChild("SeanUI"))
local Window = UI:CreateWindow({Name = "My Game"})
local Main = Window:CreateTab("Main", "home")
Main:CreateButton({Name = "Hello", Callback = function()
    print("Hello from the client")
end})
```

函式庫會嘗試可用的 GUI 容器；一般客戶端環境回退到 PlayerGui。Callback 在客戶端執行；需要伺服器資料的功能應自行設計與驗證遊戲端邏輯。

## 7. 檔案與本機開發

| 檔案 | 說明 |
| --- | --- |
| [Library.lua](Library.lua) | 可重用的 UI 函式庫 |
| [Demo.client.lua](Demo.client.lua) | 包含函式庫的完整展示，直接執行此檔 |
| [Example.lua](Example.lua) | 展示內容原始碼，由 build.py 包入 Library 變數後使用 |
| [build.py](build.py) | 使用 Python 3 產生單檔展示 |
| [test.lua](test.lua) | 模擬 Roblox API 的 Lua 測試 |
| [STYLE.md](STYLE.md) | 尺寸、色彩與字體規格 |

在 repo 根目錄執行：

```sh
python3 build.py
lua test.lua
```

更改 `Library.lua` 或 `Example.lua` 後，應重新執行 build.py，讓展示檔保持一致。

## 8. 常見問題與驗證範圍

- **執行後沒有畫面**：先看執行環境 Console 是否支援 HttpGet、loadstring 及 GUI 存取；也可直接執行完整 Demo 檔排除遠端載入問題。
- **介面隱藏了**：按 Right Shift 或左側 V 按鈕；輸入框有焦點時先離開輸入框。
- **快捷鍵沒反應**：切換到綁定元件所在的分頁，確認視窗顯示、未輸入文字、元件未停用。
- **Callback 報錯**：Console 會印出錯誤，並顯示簡短通知。
- **無法選取多個項目或找不到色彩選擇器**：目前尚未提供多選、色彩選擇器及設定檔儲存。

已通過 Lua 語法、元件狀態、Callback、搜尋、焦點、快捷鍵、滑鼠／觸控事件路由及清理的模擬測試。**v0.3.0 尚未在 Roblox／MacSploit 實測**；模擬測試不代表實際字型、排版或所有執行環境都已驗證。
