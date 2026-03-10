-- ============================================================
--   PAN HOOK v3.0 | Fish It Webhook + Utility
--   by PanMancing01
--   Update v3.0: Merge ITG Features, Safe Anti-Cheat
-- ============================================================

local HttpService       = game:GetService("HttpService")
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui           = game:GetService("CoreGui")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TextChatService   = game:GetService("TextChatService")
local GuiService        = game:GetService("GuiService")
local Stats             = game:GetService("Stats")

local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request

-- ============================================================
-- KEY SYSTEM
-- ============================================================
local KEY_URL = "https://raw.githubusercontent.com/okmantapsip-max/anuan/main/key.json"

local function CheckKey(key)
    local ok, res = pcall(function()
        return httpRequest({ Url=KEY_URL, Method="GET", Headers={["Cache-Control"]="no-cache"} })
    end)
    if not ok or not res or not res.Body then return false, "Gagal konek ke server!" end
    local parseOk, data = pcall(function() return HttpService:JSONDecode(res.Body) end)
    if not parseOk or not data or not data.keys then return false, "Format database error!" end
    local entry = data.keys[key]
    if not entry then return false, "Kode pembelian tidak ditemukan!" end
    if not entry.roblox_id then return false, "Key belum diaktivasi! Hubungi admin." end
    local localId = tostring(Players.LocalPlayer and Players.LocalPlayer.UserId or 0)
    if tostring(entry.roblox_id) ~= localId then return false, "Key ini bukan milikmu! (ID: "..localId..")" end
    local expiry = entry.expires
    if expiry ~= "lifetime" then
        -- Format jam: "24h", "72h", dst (dihitung dari created_at)
        local hours = expiry:match("^(%d+)h$")
        if hours and entry.created_at then
            local expiryEpoch = entry.created_at + (tonumber(hours) * 3600)
            if os.time() > expiryEpoch then
                return false, "Kode sudah expired! (durasi "..expiry..")"
            end
        -- Format tanggal lama: "2025-12-31" (backward compat)
        elseif not hours then
            local y, m, d = expiry:match("(%d+)-(%d+)-(%d+)")
            if y then
                local expiryEpoch = os.time({year=tonumber(y),month=tonumber(m),day=tonumber(d),hour=23,min=59,sec=59})
                if os.time() > expiryEpoch then return false, "Kode sudah expired! ("..expiry..")" end
            end
        end
    end
    return true, entry.owner or "User"
end

-- ============================================================
-- KEY SCREEN
-- ============================================================
local KeyGui = Instance.new("ScreenGui")
KeyGui.Name = "PH_KeyScreen"
KeyGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() if syn and syn.protect_gui then syn.protect_gui(KeyGui) end end)
KeyGui.Parent = CoreGui

local Card = Instance.new("Frame", KeyGui)
Card.BackgroundColor3 = Color3.fromRGB(10, 14, 22)
Card.BorderSizePixel = 0
Card.Size = UDim2.new(0, 300, 0, 250)
Card.AnchorPoint = Vector2.new(0.5, 0.5)
Card.Position = UDim2.new(0.5, 0, 0.65, 0)
Card.BackgroundTransparency = 1
Card.ZIndex = 2
Card.Active = true; Card.Draggable = true
local cardCorner = Instance.new("UICorner", Card); cardCorner.CornerRadius = UDim.new(0,12)
local cardStroke = Instance.new("UIStroke", Card)
cardStroke.Color = Color3.fromRGB(30,120,255); cardStroke.Thickness = 1.5

local KLogo = Instance.new("TextLabel", Card)
KLogo.BackgroundTransparency=1; KLogo.Size=UDim2.new(1,0,0,30); KLogo.Position=UDim2.new(0,0,0,18)
KLogo.Font=Enum.Font.GothamBold; KLogo.Text="🎣 PAN HOOK"
KLogo.TextColor3=Color3.fromRGB(60,140,255); KLogo.TextSize=18; KLogo.ZIndex=3

local KVer = Instance.new("TextLabel", Card)
KVer.BackgroundTransparency=1; KVer.Size=UDim2.new(1,0,0,16); KVer.Position=UDim2.new(0,0,0,50)
KVer.Font=Enum.Font.Gotham; KVer.Text="v3.0 — Masukkan kode pembelian"
KVer.TextColor3=Color3.fromRGB(120,130,155); KVer.TextSize=10; KVer.ZIndex=3

local InputBg = Instance.new("Frame", Card)
InputBg.BackgroundColor3=Color3.fromRGB(12,16,26); InputBg.BorderSizePixel=0
InputBg.Size=UDim2.new(1,-30,0,38); InputBg.Position=UDim2.new(0,15,0,80); InputBg.ZIndex=3
Instance.new("UICorner", InputBg).CornerRadius=UDim.new(0,8)
local ib_stroke = Instance.new("UIStroke", InputBg)
ib_stroke.Color=Color3.fromRGB(30,40,65); ib_stroke.Thickness=1.5

local KeyInput = Instance.new("TextBox", InputBg)
KeyInput.BackgroundTransparency=1; KeyInput.Size=UDim2.new(1,-20,1,0); KeyInput.Position=UDim2.new(0,10,0,0)
KeyInput.Font=Enum.Font.GothamMedium; KeyInput.PlaceholderText="PANHOOK-XXXX-XXXX-XXXX"
KeyInput.PlaceholderColor3=Color3.fromRGB(60,70,90); KeyInput.Text=""
KeyInput.TextColor3=Color3.fromRGB(230,235,245); KeyInput.TextSize=12
KeyInput.ClearTextOnFocus=false; KeyInput.ZIndex=4
KeyInput.Focused:Connect(function() ib_stroke.Color=Color3.fromRGB(30,120,255) end)
KeyInput.FocusLost:Connect(function() ib_stroke.Color=Color3.fromRGB(30,40,65) end)

local SubmitBtn = Instance.new("TextButton", Card)
SubmitBtn.BackgroundColor3=Color3.fromRGB(30,120,255); SubmitBtn.BorderSizePixel=0
SubmitBtn.Size=UDim2.new(1,-30,0,38); SubmitBtn.Position=UDim2.new(0,15,0,132)
SubmitBtn.Font=Enum.Font.GothamBold; SubmitBtn.Text="✔ Verifikasi"
SubmitBtn.TextColor3=Color3.new(1,1,1); SubmitBtn.TextSize=13; SubmitBtn.ZIndex=3
Instance.new("UICorner", SubmitBtn).CornerRadius=UDim.new(0,8)

local StatusLbl = Instance.new("TextLabel", Card)
StatusLbl.BackgroundTransparency=1; StatusLbl.Size=UDim2.new(1,-20,0,20); StatusLbl.Position=UDim2.new(0,10,0,182)
StatusLbl.Font=Enum.Font.GothamMedium; StatusLbl.Text=""; StatusLbl.TextColor3=Color3.fromRGB(120,130,155)
StatusLbl.TextSize=11; StatusLbl.ZIndex=3

local ProgressBg = Instance.new("Frame", Card)
ProgressBg.BackgroundColor3=Color3.fromRGB(20,25,40); ProgressBg.BorderSizePixel=0
ProgressBg.Size=UDim2.new(1,-30,0,4); ProgressBg.Position=UDim2.new(0,15,0,210); ProgressBg.Visible=false; ProgressBg.ZIndex=3
Instance.new("UICorner", ProgressBg).CornerRadius=UDim.new(0,2)
local ProgressBar = Instance.new("Frame", ProgressBg)
ProgressBar.BackgroundColor3=Color3.fromRGB(30,120,255); ProgressBar.BorderSizePixel=0
ProgressBar.Size=UDim2.new(0,0,1,0); ProgressBar.ZIndex=4
Instance.new("UICorner", ProgressBar).CornerRadius=UDim.new(0,2)

task.spawn(function()
    task.wait(0.05)
    TweenService:Create(Card, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position=UDim2.new(0.5,0,0.5,0), BackgroundTransparency=0
    }):Play()
end)

local loadingThread = nil
local function StartLoading()
    SubmitBtn.Text="⏳ Memeriksa..."; SubmitBtn.BackgroundColor3=Color3.fromRGB(20,80,180); SubmitBtn.Active=false
    StatusLbl.Text="Menghubungi server..."; StatusLbl.TextColor3=Color3.fromRGB(120,130,155)
    ProgressBg.Visible=true; ProgressBar.Size=UDim2.new(0,0,1,0); ProgressBar.BackgroundColor3=Color3.fromRGB(30,120,255)
    TweenService:Create(ProgressBar, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size=UDim2.new(0.85,0,1,0)}):Play()
    local dots=0
    loadingThread=task.spawn(function()
        while true do dots=(dots%3)+1; SubmitBtn.Text="⏳ Memeriksa"..string.rep(".",dots); task.wait(0.4) end
    end)
end
local function StopLoading()
    if loadingThread then task.cancel(loadingThread); loadingThread=nil end
    SubmitBtn.Active=true
end

local function DoVerify()
    local key = KeyInput.Text:match("^%s*(.-)%s*$")
    if key=="" then StatusLbl.Text="⚠️ Masukkan kode dulu!"; StatusLbl.TextColor3=Color3.fromRGB(255,180,40); return end
    StartLoading()
    task.spawn(function()
        local valid, msg = CheckKey(key)
        StopLoading()
        if valid then
            ProgressBar.BackgroundColor3=Color3.fromRGB(50,200,120)
            TweenService:Create(ProgressBar, TweenInfo.new(0.3), {Size=UDim2.new(1,0,1,0)}):Play()
            SubmitBtn.Text="✅ Valid!"; SubmitBtn.BackgroundColor3=Color3.fromRGB(50,200,120)
            StatusLbl.Text="Selamat datang, "..msg.." 👋"; StatusLbl.TextColor3=Color3.fromRGB(50,200,120)
            if getgenv then getgenv().PH_KeyOwner=msg end
            task.wait(1.2)
            TweenService:Create(Card, TweenInfo.new(0.4,Enum.EasingStyle.Quad,Enum.EasingDirection.In), {BackgroundTransparency=1, Position=UDim2.new(0.5,0,0.4,0)}):Play()
            task.wait(0.45); KeyGui:Destroy(); _G.PH_KeyPassed=true
        else
            ProgressBar.BackgroundColor3=Color3.fromRGB(235,70,70)
            TweenService:Create(ProgressBar, TweenInfo.new(0.2), {Size=UDim2.new(1,0,1,0)}):Play()
            task.wait(0.3)
            TweenService:Create(ProgressBg, TweenInfo.new(0.3), {BackgroundTransparency=1}):Play()
            TweenService:Create(ProgressBar, TweenInfo.new(0.3), {BackgroundTransparency=1}):Play()
            task.wait(0.35); ProgressBg.BackgroundTransparency=0; ProgressBar.BackgroundTransparency=0; ProgressBg.Visible=false
            SubmitBtn.Text="✔ Verifikasi"; SubmitBtn.BackgroundColor3=Color3.fromRGB(30,120,255)
            StatusLbl.Text="❌ "..msg; StatusLbl.TextColor3=Color3.fromRGB(235,70,70)
            local origPos=Card.Position
            for i=1,4 do
                TweenService:Create(Card, TweenInfo.new(0.05), {Position=UDim2.new(0.5,-150+(i%2==0 and 6 or -6),0.5,-105)}):Play()
                task.wait(0.06)
            end
            TweenService:Create(Card, TweenInfo.new(0.1), {Position=origPos}):Play()
            cardStroke.Color=Color3.fromRGB(235,70,70); task.wait(1.5); cardStroke.Color=Color3.fromRGB(30,120,255)
        end
    end)
end

SubmitBtn.MouseButton1Click:Connect(DoVerify)
KeyInput.FocusLost:Connect(function(enter) if enter then DoVerify() end end)

repeat task.wait(0.1) until _G.PH_KeyPassed==true
_G.PH_KeyPassed=nil

-- ============================================================
-- INIT
-- ============================================================
local ScriptActive = true
local Connections = {}
local ScreenGui
local SessionStart = tick()

if getgenv and getgenv().PH_Stop then pcall(getgenv().PH_Stop) end
local function CleanupScript()
    ScriptActive=false
    for _,v in pairs(Connections) do pcall(function() v:Disconnect() end) end
    Connections={}
    if ScreenGui then ScreenGui:Destroy() end
    print("❌ PAN HOOK: Script closed.")
    if getgenv then getgenv().PH_Stop=nil end
end
if getgenv then getgenv().PH_Stop=CleanupScript end

-- ============================================================
-- THEME
-- ============================================================
local Theme = {
    Background  = Color3.fromRGB(10, 14, 22),
    Header      = Color3.fromRGB(14, 18, 28),
    Sidebar     = Color3.fromRGB(8,  12, 20),
    Content     = Color3.fromRGB(16, 20, 32),
    Accent      = Color3.fromRGB(30, 120, 255),
    AccentGlow  = Color3.fromRGB(60, 140, 255),
    Success     = Color3.fromRGB(50, 200, 120),
    Error       = Color3.fromRGB(235, 70, 70),
    Warning     = Color3.fromRGB(255, 180, 40),
    TextPrimary = Color3.fromRGB(230, 235, 245),
    TextSecond  = Color3.fromRGB(120, 130, 155),
    Border      = Color3.fromRGB(30,  40,  65),
    Input       = Color3.fromRGB(12,  16,  26),
}

-- ============================================================
-- STATE
-- ============================================================
local Current_Webhook      = ""
local Current_Log_Webhook  = ""
local Current_Admin_Webhook = ""

local Settings = {
    HideIdentity      = false,
    SecretEnabled     = true,
    ForgottenEnabled  = true,
    RubyEnabled       = false,
    EvolvedEnabled    = false,
    CrystalizedEnabled= false,
    CaveCrystalEnabled= false,
    EpicEnabled       = false,
    LegendaryEnabled  = false,
    MythicEnabled     = false,
    LogEnabled        = false,
    ForeignDetection  = false,
    PingMonitor       = false,
    PlayerNonPSAuto   = false,
    SpoilerName       = false,
    NoAnimation       = false,
    DisablePopups     = false,
}

-- ============================================================
-- WEATHER STATE
-- ============================================================
local RFPurchaseWeatherEvent = nil
pcall(function()
    RFPurchaseWeatherEvent = ReplicatedStorage.Packages
        ._Index["sleitnick_net@0.2.0"].net["RF/PurchaseWeatherEvent"]
end)

local weatherKeyMap = {
    ["Wind (10k)"]        = "Wind",
    ["Snow (15k)"]        = "Snow",
    ["Cloudy (20k)"]      = "Cloudy",
    ["Storm (35k)"]       = "Storm",
    ["Radiant (50k)"]     = "Radiant",
    ["Shark Hunt (300k)"] = "Shark Hunt",
}
local weatherNames = {
    "Wind (10k)", "Snow (15k)", "Cloudy (20k)",
    "Storm (35k)", "Radiant (50k)", "Shark Hunt (300k)"
}
local selectedWeathers = {}
local autoBuyWeather   = false
local buyDelay         = 540   -- detik (default 9 menit)
local weatherThread    = nil

-- Tag List (20 slots, Host 1 & 2 = index 1,2)
local TagList = {}
for i=1,20 do TagList[i]={"",""} end
local TagUIElements = {}

local ToggleRegistry = {}
local ShowNotification

-- ============================================================
-- SECRET FISH DATABASE
-- ============================================================
local ForgottenFishData = {
    ["Sea Eater"] = true,
}

local SecretFishData = {
    ["Crystal Crab"]              = 18335072046,
    ["Orca"]                      = 18335061483,
    ["Zombie Shark"]              = 18335056722,
    ["Zombie Megalodon"]          = 18335056551,
    ["Dead Zombie Shark"]         = 18335056722,
    ["Blob Shark"]                = 18335068212,
    ["Ghost Shark"]               = 18335059639,
    ["Skeleton Narwhal"]          = 18335057177,
    ["Ghost Worm Fish"]           = 18335059511,
    ["Worm Fish"]                 = 18335057406,
    ["Megalodon"]                 = 18335063073,
    ["1x1x1x1 Comet Shark"]      = 18335118712,
    ["Bloodmoon Whale"]           = 18335067980,
    ["Lochness Monster"]          = 18335063708,
    ["Monster Shark"]             = 18335062145,
    ["Eerie Shark"]               = 18335060416,
    ["Great Whale"]               = 18335058867,
    ["Frostborn Shark"]           = 18335059957,
    ["Armored Shark"]             = 18335068417,
    ["Scare"]                     = 18335058097,
    ["Queen Crab"]                = 18335058252,
    ["King Crab"]                 = 18335064431,
    ["Cryoshade Glider"]          = 18335066928,
    ["Panther Eel"]               = 18335060799,
    ["Giant Squid"]               = 18335059345,
    ["Depthseeker Ray"]           = 18335066551,
    ["Robot Kraken"]              = 18335058448,
    ["Mosasaur Shark"]            = 18335061981,
    ["King Jelly"]                = 18335064243,
    ["Bone Whale"]                = 18335067645,
    ["Elshark Gran Maja"]         = 18335060241,
    ["Elpirate Gran Maja"]        = 18335060241,
    ["Ancient Whale"]             = 18335068612,
    ["Cosmic Mutant Shark"]       = 18335064431,
    ["Gladiator Shark"]           = 18335059068,
    ["Ancient Lochness Monster"]  = 18335063708,
    ["Talon Serpent"]             = 18335057777,
    ["Hacker Shark"]              = 18335059223,
    ["ElRetro Gran Maja"]         = 18335060241,
    ["Strawberry Choc Megalodon"] = 18335063073,
    ["Krampus Shark"]             = 18335062145,
    ["Emerald Winter Whale"]      = 18335058867,
    ["Winter Frost Shark"]        = 18335059957,
    ["Icebreaker Whale"]          = 18335067645,
    ["Leviathan"]                 = 18335063983,
    ["Pirate Megalodon"]          = 18335063073,
    ["Viridis Lurker"]            = 18335060799,
    ["Cursed Kraken"]             = 18335058448,
    ["Ancient Magma Whale"]       = 18335068612,
    ["Rainbow Comet Shark"]       = 18335118712,
    ["Love Nessie"]               = 18335063708,
    ["Broken Heart Nessie"]       = 18335063708,
}

-- Crystalized whitelist
local CrystalizedList = {
    "bioluminescent octopus","blossom jelly","cute dumbo","star snail","blue sea dragon"
}

-- Fish cache (tier data)
local fishCache = {}
local ok0, itemsMod = pcall(function() return require(ReplicatedStorage.Items) end)
if ok0 and itemsMod then
    for _,v in pairs(itemsMod) do
        if type(v)=="table" and v.Data and v.Data.Name and v.Data.Tier then
            fishCache[v.Data.Name]=v.Data.Tier
        end
    end
end

local SessionStats = {Secret=0,Ruby=0,Evolved=0,Crystalized=0,CaveCrystal=0,Total=0}
local UI_Stats = {}

-- Teleport areas
local FishingAreas = {
    ["Leviathan Den"]        = {Pos=Vector3.new(3431.640,-287.726,3529.052),  Look=Vector3.new(-0.176,0.444,-0.879)},
    ["Crystal Depths"]       = {Pos=Vector3.new(5820.647,-907.482,15425.794), Look=Vector3.new(0.131,-0.666,0.735)},
    ["Pirate Cove"]          = {Pos=Vector3.new(3479.794,4.192,3451.693),     Look=Vector3.new(0.578,-0.396,-0.713)},
    ["Pirate Tresure"]       = {Pos=Vector3.new(3305.745,-302.160,3028.795),  Look=Vector3.new(-0.331,-0.396,-0.856)},
    ["Maze Door Room"]       = {Pos=Vector3.new(3446.691,-287.845,3402.136),  Look=Vector3.new(0.324,-0.396,0.859)},
    ["Ancient Jungle"]       = {Pos=Vector3.new(1535.639,3.159,-193.352),     Look=Vector3.new(0.505,-0.000,0.863)},
    ["Coral Reef"]           = {Pos=Vector3.new(-3207.538,6.087,2011.079),    Look=Vector3.new(0.973,0.000,0.229)},
    ["Crater Island"]        = {Pos=Vector3.new(1058.976,2.330,5032.878),     Look=Vector3.new(-0.789,0.000,0.615)},
    ["Ancient Ruin"]         = {Pos=Vector3.new(6031.981,-585.924,4713.157),  Look=Vector3.new(0.316,-0.000,-0.949)},
    ["Enchant Room"]         = {Pos=Vector3.new(3255.670,-1301.530,1371.790), Look=Vector3.new(-0.000,-0.000,-1.000)},
    ["Fisherman Island"]     = {Pos=Vector3.new(74.030,9.530,2705.230),       Look=Vector3.new(-0.000,-0.000,-1.000)},
    ["Kohana"]               = {Pos=Vector3.new(-668.732,3.000,681.580),      Look=Vector3.new(0.889,-0.000,0.458)},
    ["Lost Isle"]            = {Pos=Vector3.new(-3804.105,2.344,-904.653),    Look=Vector3.new(-0.901,-0.000,0.433)},
    ["Sacred Temple"]        = {Pos=Vector3.new(1461.815,-22.125,-670.234),   Look=Vector3.new(-0.990,-0.000,0.143)},
    ["Second Enchant Altar"] = {Pos=Vector3.new(1479.587,128.295,-604.224),   Look=Vector3.new(-0.298,0.000,-0.955)},
    ["Sisyphus Statue"]      = {Pos=Vector3.new(-3743.745,-135.074,-1007.554),Look=Vector3.new(0.310,0.000,0.951)},
    ["Treasure Room"]        = {Pos=Vector3.new(-3598.440,-281.274,-1645.855),Look=Vector3.new(-0.065,0.000,-0.998)},
    ["Tropical Island"]      = {Pos=Vector3.new(-2162.920,2.825,3638.445),    Look=Vector3.new(0.381,-0.000,0.925)},
    ["Underground Cellar"]   = {Pos=Vector3.new(2118.417,-91.448,-733.800),   Look=Vector3.new(0.854,0.000,0.521)},
    ["Volcano"]              = {Pos=Vector3.new(-552.797,21.174,186.940),     Look=Vector3.new(-0.251,-0.534,-0.808)},
    ["Volcanic Cavern"]      = {Pos=Vector3.new(1249.005,82.830,-10224.920),  Look=Vector3.new(-0.649,-0.666,0.368)},
}

-- ============================================================
-- UI HELPERS
-- ============================================================
local function AddCorner(inst, rad)
    local c=Instance.new("UICorner",inst); c.CornerRadius=UDim.new(0,rad or 6); return c
end
local function AddStroke(inst, color, thick)
    local old=inst:FindFirstChildOfClass("UIStroke"); if old then old:Destroy() end
    local s=Instance.new("UIStroke",inst); s.Color=color or Theme.Border; s.Thickness=thick or 1
    s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; return s
end
local function AddPad(inst, px)
    local p=Instance.new("UIPadding",inst); local u=UDim.new(0,px)
    p.PaddingLeft=u; p.PaddingRight=u; p.PaddingTop=u; p.PaddingBottom=u
end

-- ============================================================
-- SCREEN GUI
-- ============================================================
local oldGui=CoreGui:FindFirstChild("PanHookV3")
if oldGui then oldGui:Destroy() end

ScreenGui=Instance.new("ScreenGui")
ScreenGui.Name="PanHookV3"
ScreenGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
pcall(function() if syn and syn.protect_gui then syn.protect_gui(ScreenGui) end end)
if not ScreenGui.Parent then ScreenGui.Parent=CoreGui end

-- ============================================================
-- OPEN BUTTON (logo PH, selalu tampil)
-- ============================================================
local OpenBtn=Instance.new("TextButton",ScreenGui)
OpenBtn.Name="PH_OpenBtn"; OpenBtn.BackgroundColor3=Color3.fromRGB(30,80,180)
OpenBtn.Size=UDim2.new(0,64,0,72); OpenBtn.Position=UDim2.new(0,10,0.35,-36)
OpenBtn.Text=""; OpenBtn.BorderSizePixel=0; OpenBtn.Active=true; OpenBtn.Draggable=true
OpenBtn.ZIndex=100
AddCorner(OpenBtn,12); AddStroke(OpenBtn,Color3.fromRGB(100,160,255),1.5)

local PHBig=Instance.new("TextLabel",OpenBtn)
PHBig.BackgroundTransparency=1; PHBig.Size=UDim2.new(1,0,0,38)
PHBig.Position=UDim2.new(0,0,0,6); PHBig.ZIndex=101
PHBig.Font=Enum.Font.GothamBold; PHBig.Text="PH"
PHBig.TextColor3=Color3.fromRGB(255,255,255); PHBig.TextSize=26
PHBig.TextXAlignment=Enum.TextXAlignment.Center

local PHSub=Instance.new("TextLabel",OpenBtn)
PHSub.BackgroundTransparency=1; PHSub.Size=UDim2.new(1,0,0,14)
PHSub.Position=UDim2.new(0,0,0,44); PHSub.ZIndex=101
PHSub.Font=Enum.Font.GothamBold; PHSub.Text="PAN HOOK"
PHSub.TextColor3=Color3.fromRGB(200,220,255); PHSub.TextSize=8
PHSub.TextXAlignment=Enum.TextXAlignment.Center

local PHSub2=Instance.new("TextLabel",OpenBtn)
PHSub2.BackgroundTransparency=1; PHSub2.Size=UDim2.new(1,0,0,12)
PHSub2.Position=UDim2.new(0,0,0,56); PHSub2.ZIndex=101
PHSub2.Font=Enum.Font.Gotham; PHSub2.Text="WEBHOOK"
PHSub2.TextColor3=Color3.fromRGB(150,180,230); PHSub2.TextSize=7
PHSub2.TextXAlignment=Enum.TextXAlignment.Center

-- ============================================================
-- NOTIFICATION
-- ============================================================
function ShowNotification(msg, isError)
    if not ScriptActive then return end
    local f=Instance.new("Frame",ScreenGui)
    f.BackgroundColor3=Theme.Background; f.BorderSizePixel=0
    f.Size=UDim2.new(0,220,0,38); f.Position=UDim2.new(0.5,-110,0.08,0); f.ZIndex=300
    AddCorner(f,8); AddStroke(f,isError and Theme.Error or Theme.Accent,1.5)
    local bar=Instance.new("Frame",f)
    bar.BackgroundColor3=isError and Theme.Error or Theme.Accent
    bar.Size=UDim2.new(0,3,1,-10); bar.Position=UDim2.new(0,6,0.5,-14); bar.BorderSizePixel=0; AddCorner(bar,2)
    local lbl=Instance.new("TextLabel",f)
    lbl.BackgroundTransparency=1; lbl.Position=UDim2.new(0,16,0,0); lbl.Size=UDim2.new(1,-22,1,0)
    lbl.Font=Enum.Font.GothamBold; lbl.Text=msg; lbl.TextColor3=Theme.TextPrimary; lbl.TextSize=12; lbl.ZIndex=301
    lbl.TextXAlignment=Enum.TextXAlignment.Left
    f.BackgroundTransparency=1; lbl.TextTransparency=1; bar.BackgroundTransparency=1
    TweenService:Create(f,TweenInfo.new(0.25,Enum.EasingStyle.Quad),{BackgroundTransparency=0.05}):Play()
    TweenService:Create(lbl,TweenInfo.new(0.25),{TextTransparency=0}):Play()
    TweenService:Create(bar,TweenInfo.new(0.25),{BackgroundTransparency=0}):Play()
    TweenService:Create(f,TweenInfo.new(0.3,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=UDim2.new(0.5,-110,0.12,0)}):Play()
    task.delay(2.5, function()
        if not f or not f.Parent then return end
        TweenService:Create(f,TweenInfo.new(0.25),{BackgroundTransparency=1,Position=UDim2.new(0.5,-110,0.08,0)}):Play()
        TweenService:Create(lbl,TweenInfo.new(0.25),{TextTransparency=1}):Play()
        task.wait(0.3); if f and f.Parent then f:Destroy() end
    end)
end

-- ============================================================
-- MAIN FRAME
-- ============================================================
local Main=Instance.new("Frame",ScreenGui)
Main.Name="Main"; Main.BackgroundColor3=Theme.Background; Main.BorderSizePixel=0
Main.Size=UDim2.new(0,540,0,330); Main.Position=UDim2.new(0.5,-270,0.5,-165)
Main.Active=true; Main.Draggable=true
AddCorner(Main,10); AddStroke(Main,Theme.Border,1)

local Shadow=Instance.new("ImageLabel",Main)
Shadow.BackgroundTransparency=1; Shadow.AnchorPoint=Vector2.new(0.5,0.5)
Shadow.Position=UDim2.new(0.5,0,0.5,0); Shadow.Size=UDim2.new(1,60,1,60); Shadow.ZIndex=-1
Shadow.Image="rbxassetid://6014261993"; Shadow.ImageColor3=Color3.new(0,0,0)
Shadow.ImageTransparency=0.45; Shadow.SliceCenter=Rect.new(49,49,450,450); Shadow.ScaleType=Enum.ScaleType.Slice

-- Header
local Header=Instance.new("Frame",Main)
Header.BackgroundColor3=Theme.Header; Header.Size=UDim2.new(1,0,0,34); Header.BorderSizePixel=0; Header.ZIndex=5
AddCorner(Header,10)
local HFix=Instance.new("Frame",Header); HFix.BackgroundColor3=Theme.Header; HFix.BorderSizePixel=0
HFix.Position=UDim2.new(0,0,1,-8); HFix.Size=UDim2.new(1,0,0,8)
local HDivider=Instance.new("Frame",Header); HDivider.BackgroundColor3=Theme.Border; HDivider.BorderSizePixel=0
HDivider.Position=UDim2.new(0,0,1,0); HDivider.Size=UDim2.new(1,0,0,1); HDivider.ZIndex=6

local LogoLabel=Instance.new("TextLabel",Header)
LogoLabel.BackgroundTransparency=1; LogoLabel.Position=UDim2.new(0,14,0,0); LogoLabel.Size=UDim2.new(0,160,1,0)
LogoLabel.Font=Enum.Font.GothamBold; LogoLabel.Text="🎣 PAN HOOK"
LogoLabel.TextColor3=Theme.AccentGlow; LogoLabel.TextSize=14; LogoLabel.TextXAlignment=Enum.TextXAlignment.Left; LogoLabel.ZIndex=6

local VerLabel=Instance.new("TextLabel",Header)
VerLabel.BackgroundTransparency=1; VerLabel.Position=UDim2.new(0,100,0,0); VerLabel.Size=UDim2.new(0,60,1,0)
VerLabel.Font=Enum.Font.Gotham; VerLabel.Text="v3.0"; VerLabel.TextColor3=Theme.TextSecond
VerLabel.TextSize=10; VerLabel.TextXAlignment=Enum.TextXAlignment.Left; VerLabel.ZIndex=6

local MinBtn=Instance.new("TextButton",Header)
MinBtn.BackgroundTransparency=1; MinBtn.Position=UDim2.new(1,-58,0,0); MinBtn.Size=UDim2.new(0,28,1,0)
MinBtn.Font=Enum.Font.GothamBold; MinBtn.Text="−"; MinBtn.TextColor3=Theme.TextSecond; MinBtn.TextSize=20; MinBtn.ZIndex=6
MinBtn.MouseEnter:Connect(function() MinBtn.TextColor3=Theme.TextPrimary end)
MinBtn.MouseLeave:Connect(function() MinBtn.TextColor3=Theme.TextSecond end)

local CloseBtn=Instance.new("TextButton",Header)
CloseBtn.BackgroundTransparency=1; CloseBtn.Position=UDim2.new(1,-28,0,0); CloseBtn.Size=UDim2.new(0,28,1,0)
CloseBtn.Font=Enum.Font.GothamBold; CloseBtn.Text="×"; CloseBtn.TextColor3=Theme.TextSecond; CloseBtn.TextSize=22; CloseBtn.ZIndex=6
CloseBtn.MouseEnter:Connect(function() CloseBtn.TextColor3=Theme.Error end)
CloseBtn.MouseLeave:Connect(function() CloseBtn.TextColor3=Theme.TextSecond end)
CloseBtn.MouseButton1Click:Connect(function() CleanupScript() end)
MinBtn.MouseButton1Click:Connect(function() Main.Visible=false end)
OpenBtn.MouseButton1Click:Connect(function() Main.Visible=not Main.Visible end)

-- Sidebar
local Sidebar=Instance.new("Frame",Main)
Sidebar.BackgroundColor3=Theme.Sidebar; Sidebar.BorderSizePixel=0
Sidebar.Position=UDim2.new(0,0,0,34); Sidebar.Size=UDim2.new(0,108,1,-34); Sidebar.ZIndex=2
AddCorner(Sidebar,10)
local SFix=Instance.new("Frame",Sidebar); SFix.BackgroundColor3=Theme.Sidebar; SFix.BorderSizePixel=0
SFix.Position=UDim2.new(1,-8,0,0); SFix.Size=UDim2.new(0,8,1,0)
local SDivider=Instance.new("Frame",Sidebar); SDivider.BackgroundColor3=Theme.Border; SDivider.BorderSizePixel=0
SDivider.Position=UDim2.new(1,-1,0,0); SDivider.Size=UDim2.new(0,1,1,0); SDivider.ZIndex=3

local MenuContainer=Instance.new("Frame",Sidebar)
MenuContainer.BackgroundTransparency=1; MenuContainer.Size=UDim2.new(1,0,1,-10); MenuContainer.Position=UDim2.new(0,0,0,5); MenuContainer.ZIndex=5
local mcLayout=Instance.new("UIListLayout",MenuContainer)
mcLayout.Padding=UDim.new(0,2); mcLayout.HorizontalAlignment=Enum.HorizontalAlignment.Center
AddPad(MenuContainer,5)

-- Content area
local ContentArea=Instance.new("Frame",Main)
ContentArea.BackgroundTransparency=1; ContentArea.Position=UDim2.new(0,115,0,38); ContentArea.Size=UDim2.new(1,-121,1,-44); ContentArea.ZIndex=3

-- ============================================================
-- PAGE & TAB FACTORY
-- ============================================================
local pages={}
local function CreatePage(name)
    local p=Instance.new("ScrollingFrame",ContentArea)
    p.Name="Page_"..name; p.BackgroundTransparency=1; p.Size=UDim2.new(1,0,1,0)
    p.ScrollBarThickness=3; p.ScrollBarImageColor3=Theme.Accent; p.Visible=false
    p.CanvasSize=UDim2.new(0,0,0,0); p.AutomaticCanvasSize=Enum.AutomaticSize.Y; p.ZIndex=4
    local lay=Instance.new("UIListLayout",p); lay.Padding=UDim.new(0,5); lay.SortOrder=Enum.SortOrder.LayoutOrder
    AddPad(p,2); pages[name]=p; return p
end

local Page_Info     = CreatePage("Info")
local Page_Webhook  = CreatePage("Webhook")
local Page_Admin    = CreatePage("Admin")
local Page_Teleport = CreatePage("Teleport")
local Page_Misc     = CreatePage("Misc")
local Page_Weather  = CreatePage("Weather")

local function CreateTab(label, page, isDefault)
    local btn=Instance.new("TextButton",MenuContainer)
    btn.BackgroundColor3=Theme.Content; btn.BackgroundTransparency=1
    btn.Size=UDim2.new(1,-8,0,26); btn.Font=Enum.Font.GothamMedium; btn.Text=label
    btn.TextColor3=Theme.TextSecond; btn.TextSize=11; btn.ZIndex=3
    AddCorner(btn,5)
    local ind=Instance.new("Frame",btn); ind.Name="Ind"; ind.BackgroundColor3=Theme.Accent
    ind.BorderSizePixel=0; ind.Position=UDim2.new(0,2,0.5,-8); ind.Size=UDim2.new(0,3,0,16); ind.Visible=false
    AddCorner(ind,2)
    btn.MouseButton1Click:Connect(function()
        for _,pg in pairs(pages) do pg.Visible=false end
        page.Visible=true
        for _,child in pairs(MenuContainer:GetChildren()) do
            if child:IsA("TextButton") then
                child.TextColor3=Theme.TextSecond; child.Font=Enum.Font.GothamMedium; child.BackgroundTransparency=1
                local i=child:FindFirstChild("Ind"); if i then i.Visible=false end
            end
        end
        btn.TextColor3=Theme.TextPrimary; btn.Font=Enum.Font.GothamBold
        btn.BackgroundTransparency=0.92; btn.BackgroundColor3=Theme.TextPrimary; ind.Visible=true
    end)
    if isDefault then
        btn.TextColor3=Theme.TextPrimary; btn.Font=Enum.Font.GothamBold
        btn.BackgroundTransparency=0.92; btn.BackgroundColor3=Theme.TextPrimary; ind.Visible=true; page.Visible=true
    end
    return btn
end

CreateTab("📊 Info",     Page_Info,    true)
CreateTab("🔔 Webhook",  Page_Webhook)
CreateTab("🛡️ Admin",   Page_Admin)
CreateTab("📍 Teleport", Page_Teleport)
CreateTab("🌤️ Weather",  Page_Weather)
CreateTab("⚙️ Misc",    Page_Misc)

-- ============================================================
-- UI COMPONENTS
-- ============================================================
local function CreateSectionLabel(parent, text)
    local lbl=Instance.new("TextLabel",parent)
    lbl.BackgroundTransparency=1; lbl.Size=UDim2.new(1,-4,0,18)
    lbl.Font=Enum.Font.GothamBold; lbl.Text=text; lbl.TextColor3=Theme.TextSecond
    lbl.TextSize=10; lbl.TextXAlignment=Enum.TextXAlignment.Left; return lbl
end

local function CreateToggle(parent, labelText, settingKey, defaultVal, callback)
    local Frame=Instance.new("Frame",parent)
    Frame.BackgroundColor3=Theme.Content; Frame.Size=UDim2.new(1,-4,0,34); Frame.BorderSizePixel=0
    AddCorner(Frame,6); AddStroke(Frame,Theme.Border,1)
    local Lbl=Instance.new("TextLabel",Frame)
    Lbl.BackgroundTransparency=1; Lbl.Position=UDim2.new(0,10,0,0); Lbl.Size=UDim2.new(1,-60,1,0)
    Lbl.Font=Enum.Font.GothamBold; Lbl.Text=labelText; Lbl.TextColor3=Theme.TextPrimary
    Lbl.TextSize=12; Lbl.TextXAlignment=Enum.TextXAlignment.Left
    local state=(Settings[settingKey]~=nil) and Settings[settingKey] or (defaultVal or false)
    local Switch=Instance.new("TextButton",Frame)
    Switch.BackgroundColor3=state and Theme.Success or Theme.Input
    Switch.Position=UDim2.new(1,-46,0.5,-10); Switch.Size=UDim2.new(0,36,0,20); Switch.Text=""; Switch.BorderSizePixel=0
    AddCorner(Switch,10)
    local Knob=Instance.new("Frame",Switch)
    Knob.BackgroundColor3=Color3.new(1,1,1); Knob.BorderSizePixel=0
    Knob.Position=state and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8); Knob.Size=UDim2.new(0,16,0,16)
    AddCorner(Knob,8)
    local function UpdateUI(val)
        TweenService:Create(Switch,TweenInfo.new(0.18),{BackgroundColor3=val and Theme.Success or Theme.Input}):Play()
        TweenService:Create(Knob,TweenInfo.new(0.18),{Position=val and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8)}):Play()
    end
    if settingKey then
        ToggleRegistry[settingKey]=function(val)
            if settingKey then Settings[settingKey]=val end
            UpdateUI(val)
            if callback then callback(val) end
        end
    end
    Switch.MouseButton1Click:Connect(function()
        local newVal=not(Switch.BackgroundColor3==Theme.Success)
        if settingKey then Settings[settingKey]=newVal end
        UpdateUI(newVal)
        if callback then callback(newVal) end
        ShowNotification(labelText..(newVal and " ✅ ON" or " ⛔ OFF"),not newVal)
    end)
    return Frame
end

local function CreateInput(parent, labelText, placeholder, defaultVal, callback)
    local Frame=Instance.new("Frame",parent)
    Frame.BackgroundColor3=Theme.Content; Frame.Size=UDim2.new(1,-4,0,34); Frame.BorderSizePixel=0
    AddCorner(Frame,6); AddStroke(Frame,Theme.Border,1)
    local Lbl=Instance.new("TextLabel",Frame)
    Lbl.BackgroundTransparency=1; Lbl.Position=UDim2.new(0,10,0,0); Lbl.Size=UDim2.new(0,110,1,0)
    Lbl.Font=Enum.Font.GothamBold; Lbl.Text=labelText; Lbl.TextColor3=Theme.TextSecond
    Lbl.TextSize=11; Lbl.TextXAlignment=Enum.TextXAlignment.Left
    local InputBg2=Instance.new("Frame",Frame)
    InputBg2.BackgroundColor3=Theme.Input; InputBg2.Position=UDim2.new(0,118,0.5,-10)
    InputBg2.Size=UDim2.new(1,-128,0,20); InputBg2.ClipsDescendants=true; InputBg2.BorderSizePixel=0
    AddCorner(InputBg2,4); AddStroke(InputBg2,Theme.Border,1)
    local TB=Instance.new("TextBox",InputBg2)
    TB.BackgroundTransparency=1; TB.Position=UDim2.new(0,6,0,0); TB.Size=UDim2.new(1,-12,1,0)
    TB.Font=Enum.Font.Gotham; TB.Text=defaultVal or ""; TB.PlaceholderText=placeholder or ""
    TB.PlaceholderColor3=Theme.TextSecond; TB.TextColor3=Theme.TextPrimary; TB.TextSize=11
    TB.TextXAlignment=Enum.TextXAlignment.Left; TB.ClearTextOnFocus=false
    TB.Focused:Connect(function() AddStroke(InputBg2,Theme.Accent,1.5) end)
    TB.FocusLost:Connect(function() AddStroke(InputBg2,Theme.Border,1); if callback then callback(TB.Text,TB) end end)
    return TB
end

local function CreateButton(parent, labelText, color, callback)
    local Wrap=Instance.new("Frame",parent)
    Wrap.BackgroundTransparency=1; Wrap.Size=UDim2.new(1,-4,0,30); Wrap.BorderSizePixel=0
    local Btn=Instance.new("TextButton",Wrap)
    Btn.BackgroundColor3=color or Theme.Accent; Btn.Size=UDim2.new(1,0,1,0)
    Btn.Font=Enum.Font.GothamBold; Btn.Text=labelText; Btn.TextColor3=Color3.new(1,1,1)
    Btn.TextSize=12; Btn.BorderSizePixel=0
    AddCorner(Btn,6); Btn.MouseButton1Click:Connect(callback); return Btn
end

local function CreateStatRow(parent, labelText, key)
    local Frame=Instance.new("Frame",parent)
    Frame.BackgroundColor3=Theme.Content; Frame.Size=UDim2.new(1,-4,0,26); Frame.BorderSizePixel=0
    AddCorner(Frame,5)
    local Lbl=Instance.new("TextLabel",Frame)
    Lbl.BackgroundTransparency=1; Lbl.Position=UDim2.new(0,10,0,0); Lbl.Size=UDim2.new(0.65,0,1,0)
    Lbl.Font=Enum.Font.GothamMedium; Lbl.Text=labelText; Lbl.TextColor3=Theme.TextSecond; Lbl.TextSize=11; Lbl.TextXAlignment=Enum.TextXAlignment.Left
    local Val=Instance.new("TextLabel",Frame)
    Val.BackgroundTransparency=1; Val.Position=UDim2.new(0.65,0,0,0); Val.Size=UDim2.new(0.35,-8,1,0)
    Val.Font=Enum.Font.GothamBold; Val.Text="0"; Val.TextColor3=Theme.AccentGlow; Val.TextSize=11; Val.TextXAlignment=Enum.TextXAlignment.Right
    UI_Stats[key]=Val
end

-- ============================================================
-- PAGE: INFO
-- ============================================================
CreateSectionLabel(Page_Info,"  SESSION")

local keyRow=Instance.new("Frame",Page_Info)
keyRow.BackgroundColor3=Theme.Content; keyRow.Size=UDim2.new(1,-4,0,26); keyRow.BorderSizePixel=0
AddCorner(keyRow,5); AddStroke(keyRow,Theme.Border,1)
local keyLbl=Instance.new("TextLabel",keyRow); keyLbl.BackgroundTransparency=1
keyLbl.Position=UDim2.new(0,10,0,0); keyLbl.Size=UDim2.new(0.5,0,1,0)
keyLbl.Font=Enum.Font.GothamBold; keyLbl.Text="🔑 Key Owner"; keyLbl.TextColor3=Theme.TextSecond; keyLbl.TextSize=11; keyLbl.TextXAlignment=Enum.TextXAlignment.Left
local keyVal=Instance.new("TextLabel",keyRow); keyVal.BackgroundTransparency=1
keyVal.Position=UDim2.new(0.5,0,0,0); keyVal.Size=UDim2.new(0.5,-8,1,0)
keyVal.Font=Enum.Font.GothamBold; keyVal.Text=(getgenv and getgenv().PH_KeyOwner) or "Unknown"
keyVal.TextColor3=Theme.Success; keyVal.TextSize=11; keyVal.TextXAlignment=Enum.TextXAlignment.Right

local UptimeRow=Instance.new("Frame",Page_Info)
UptimeRow.BackgroundColor3=Theme.Content; UptimeRow.Size=UDim2.new(1,-4,0,30); UptimeRow.BorderSizePixel=0; AddCorner(UptimeRow,6)
local UptimeLbl=Instance.new("TextLabel",UptimeRow); UptimeLbl.BackgroundTransparency=1
UptimeLbl.Position=UDim2.new(0,10,0,0); UptimeLbl.Size=UDim2.new(0.5,0,1,0)
UptimeLbl.Font=Enum.Font.GothamBold; UptimeLbl.Text="⏱ Uptime"; UptimeLbl.TextColor3=Theme.TextSecond; UptimeLbl.TextSize=12; UptimeLbl.TextXAlignment=Enum.TextXAlignment.Left
local UptimeVal=Instance.new("TextLabel",UptimeRow); UptimeVal.BackgroundTransparency=1
UptimeVal.Position=UDim2.new(0.5,0,0,0); UptimeVal.Size=UDim2.new(0.5,-10,1,0)
UptimeVal.Font=Enum.Font.GothamBold; UptimeVal.Text="00h 00m 00s"; UptimeVal.TextColor3=Theme.AccentGlow; UptimeVal.TextSize=12; UptimeVal.TextXAlignment=Enum.TextXAlignment.Right
UI_Stats["Uptime"]=UptimeVal

CreateSectionLabel(Page_Info,"  STATS")
CreateStatRow(Page_Info,"🔔 Total Webhook Sent","Total")
CreateStatRow(Page_Info,"⚓ Secret Fish","Secret")
CreateStatRow(Page_Info,"💎 Ruby Gemstone","Ruby")

task.spawn(function()
    while ScriptActive do
        local d=tick()-SessionStart
        local h=math.floor(d/3600); local m=math.floor((d%3600)/60); local s=math.floor(d%60)
        if UptimeVal then UptimeVal.Text=string.format("%02dh %02dm %02ds",h,m,s) end
        task.wait(1)
    end
end)

-- ============================================================
-- PAGE: WEBHOOK
-- ============================================================
CreateSectionLabel(Page_Webhook,"  DISCORD WEBHOOK")
local webhookInput=CreateInput(Page_Webhook,"Fish Hook","https://discord.com/api/webhooks/...","",function(v) Current_Webhook=v end)
local webhookLogInput=CreateInput(Page_Webhook,"Log Hook","https://discord.com/api/webhooks/...","",function(v) Current_Log_Webhook=v end)

CreateSectionLabel(Page_Webhook,"  PLAYER LOG")
CreateToggle(Page_Webhook,"👋 Player Join & Leave","LogEnabled",false,function(v) Settings.LogEnabled=v end)

CreateSectionLabel(Page_Webhook,"  SPECIAL")
CreateToggle(Page_Webhook,"💎 Ruby + Gemstone","RubyEnabled",false,nil)
CreateToggle(Page_Webhook,"✨ Secret Fish","SecretEnabled",true,nil)
CreateToggle(Page_Webhook,"👁️ Forgotten","ForgottenEnabled",true,nil)
CreateToggle(Page_Webhook,"🧬 Mutation Crystalized","CrystalizedEnabled",false,nil)

CreateSectionLabel(Page_Webhook,"  RARITY FILTER")
local rarityToggles={{key="EpicEnabled",label="🟣 Epic"},{key="LegendaryEnabled",label="🟡 Legendary"},{key="MythicEnabled",label="🔴 Mythic"}}
for _,r in ipairs(rarityToggles) do
    Settings[r.key]=false
    CreateToggle(Page_Webhook,r.label,r.key,false,nil)
end

CreateButton(Page_Webhook,"🔧 Test Webhook",Theme.Accent,function()
    if Current_Webhook=="" then ShowNotification("❌ Masukkan webhook URL dulu!",true) return end
    ShowNotification("⏳ Mengirim test...",false)
    task.spawn(function()
        local payload={username="PAN HOOK",embeds={{title="🔧 Test Webhook!",color=0x1E78FF,
            fields={{name="Status",value="✅ Webhook connected!",inline=true},{name="Script",value="PAN HOOK v3.0",inline=true}},
            footer={text="PAN HOOK v3.0"}}}}
        local ok2=pcall(function() httpRequest({Url=Current_Webhook,Method="POST",Headers={["Content-Type"]="application/json"},Body=HttpService:JSONEncode(payload)}) end)
        if ok2 then ShowNotification("✅ Test berhasil!",false) else ShowNotification("❌ Gagal! Cek URL",true) end
    end)
end)

CreateButton(Page_Webhook,"🐟 Test Secret (Cek Gambar)",Color3.fromRGB(50,180,120),function()
    if Current_Webhook=="" then ShowNotification("❌ Masukkan webhook URL dulu!",true) return end
    ShowNotification("⏳ Mengirim test secret...",false)
    task.spawn(function()
        local names={}; for k in pairs(SecretFishData) do table.insert(names,k) end
        local randomFish=names[math.random(1,#names)]
        local fields={
            {name="👤 Player",  value="**TestUser** (@TestUser)", inline=false},
            {name="🐟 Ikan",    value="`"..randomFish.."`", inline=true},
            {name="⭐ Rarity",  value="`SECRET`", inline=true},
            {name="⚖️ Berat",  value="`999.9kg`", inline=true},
            {name="✨ Mutasi",  value="`N/A`", inline=true},
        }
        local embed={title="WIH ANAK ANJ DAPAT SIKRITTT!!!! [TEST]",color=65431,fields=fields,footer={text="PAN HOOK v3.0 • TEST"},timestamp=os.date("!%Y-%m-%dT%H:%M:%SZ")}
        local ok2,err2=pcall(function()
            httpRequest({Url=Current_Webhook,Method="POST",Headers={["Content-Type"]="application/json"},Body=HttpService:JSONEncode({username="PAN HOOK",embeds={embed}})})
        end)
        if ok2 then ShowNotification("✅ Terkirim! ("..randomFish..")",false)
        else ShowNotification("❌ Gagal: "..tostring(err2),true) end
    end)
end)

CreateButton(Page_Webhook,"👁️ Test Forgotten",Color3.fromRGB(180,0,180),function()
    if Current_Webhook=="" then ShowNotification("❌ Masukkan webhook URL dulu!",true) return end
    ShowNotification("⏳ Mengirim test forgotten...",false)
    task.spawn(function()
        local fields={
            {name="👤 Player",value="**TestUser** (@TestUser)",inline=false},
            {name="🐟 Ikan",value="`Sea Eater`",inline=true},
            {name="⭐ Tier",value="`FORGOTTEN`",inline=true},
            {name="⚖️ Berat",value="`999.9kg`",inline=true},
            {name="✨ Mutasi",value="`N/A`",inline=true},
        }
        local embed={title="KELASS KINK CAIR CAIR 💀🔥 [TEST]",color=0xFF00FF,fields=fields,footer={text="PAN HOOK v3.0 • TEST"},timestamp=os.date("!%Y-%m-%dT%H:%M:%SZ")}
        local ok,err=pcall(function()
            httpRequest({Url=Current_Webhook,Method="POST",Headers={["Content-Type"]="application/json"},Body=HttpService:JSONEncode({username="PAN HOOK 💀",content="🔥**FORGOTTEN ☠️ DETECTED**🔥 @everyone",embeds={embed}})})
        end)
        if ok then ShowNotification("✅ Test Forgotten terkirim!",false)
        else ShowNotification("❌ Gagal: "..tostring(err),true) end
    end)
end)

-- ============================================================
-- PAGE: ADMIN
-- ============================================================
CreateSectionLabel(Page_Admin,"  ADMIN WEBHOOK")
local adminInput=CreateInput(Page_Admin,"Admin Hook","https://discord.com/api/webhooks/...","",function(v) Current_Admin_Webhook=v end)

CreateButton(Page_Admin,"🔧 Test Admin Hook",Theme.Accent,function()
    if Current_Admin_Webhook=="" then ShowNotification("❌ Masukkan admin hook dulu!",true) return end
    task.spawn(function()
        local payload={username="PAN HOOK",embeds={{title="🔧 Test Admin Hook!",color=0x1E78FF,footer={text="PAN HOOK v3.0"}}}}
        pcall(function() httpRequest({Url=Current_Admin_Webhook,Method="POST",Headers={["Content-Type"]="application/json"},Body=HttpService:JSONEncode(payload)}) end)
        ShowNotification("✅ Test berhasil!",false)
    end)
end)

CreateSectionLabel(Page_Admin,"  MONITOR")
CreateToggle(Page_Admin,"🕵️ Deteksi Player Asing","ForeignDetection",false,nil)
CreateToggle(Page_Admin,"📡 Ping Monitor (>500ms)","PingMonitor",false,nil)
CreateToggle(Page_Admin,"⏰ Player NOT On Server (30 min)","PlayerNonPSAuto",false,nil)
CreateToggle(Page_Admin,"🚪 Player Leave Webhook","LogEnabled",false,nil)
CreateToggle(Page_Admin,"🙈 Hide Player Name (Spoiler)","SpoilerName",false,nil)

CreateSectionLabel(Page_Admin,"  LIST PLAYER (20 SLOT)")
local listInfoLbl=Instance.new("TextLabel",Page_Admin)
listInfoLbl.BackgroundTransparency=1; listInfoLbl.Size=UDim2.new(1,-4,0,24)
listInfoLbl.Font=Enum.Font.Gotham; listInfoLbl.Text="Slot 1-2 = Host. Isi username Roblox + Discord ID (opsional)."
listInfoLbl.TextColor3=Theme.TextSecond; listInfoLbl.TextSize=10; listInfoLbl.TextWrapped=true
listInfoLbl.TextXAlignment=Enum.TextXAlignment.Left

for i=1,20 do
    local rowData=TagList[i]
    local Row=Instance.new("Frame",Page_Admin)
    Row.BackgroundColor3=Theme.Content; Row.Size=UDim2.new(1,-4,0,28); Row.BorderSizePixel=0
    AddCorner(Row,5)
    local labelText= i==1 and "Host 1:" or (i==2 and "Host 2:" or "List "..i..":")
    local Num=Instance.new("TextLabel",Row); Num.BackgroundTransparency=1
    Num.Position=UDim2.new(0,8,0,0); Num.Size=UDim2.new(0,50,1,0)
    Num.Font=Enum.Font.GothamBold; Num.Text=labelText
    Num.TextColor3=(i<=2) and Theme.AccentGlow or Theme.TextSecond; Num.TextSize=11; Num.TextXAlignment=Enum.TextXAlignment.Left
    local UserInput=Instance.new("TextBox",Row)
    UserInput.BackgroundTransparency=1; UserInput.Position=UDim2.new(0,58,0,0); UserInput.Size=UDim2.new(0.42,0,1,0)
    UserInput.Font=Enum.Font.GothamBold; UserInput.Text=rowData[1]; UserInput.PlaceholderText="Username"
    UserInput.TextColor3=Theme.TextPrimary; UserInput.TextSize=12; UserInput.TextXAlignment=Enum.TextXAlignment.Left; UserInput.ClearTextOnFocus=false
    local IDInput=Instance.new("TextBox",Row)
    IDInput.BackgroundTransparency=1; IDInput.Position=UDim2.new(0.5,5,0,0); IDInput.Size=UDim2.new(0.5,-10,1,0)
    IDInput.Font=Enum.Font.GothamBold; IDInput.Text=rowData[2]; IDInput.PlaceholderText="Discord ID (opsional)"
    IDInput.TextColor3=Theme.TextSecond; IDInput.TextSize=11; IDInput.TextXAlignment=Enum.TextXAlignment.Left; IDInput.ClearTextOnFocus=false
    TagUIElements[i]={User=UserInput,ID=IDInput}
    local function Sync() TagList[i]={UserInput.Text,IDInput.Text} end
    UserInput.FocusLost:Connect(Sync); IDInput.FocusLost:Connect(Sync)
end

CreateSectionLabel(Page_Admin,"  ACTIONS")
CreateButton(Page_Admin,"📋 Send Player On Server",Theme.Accent,function()
    if Current_Admin_Webhook=="" then ShowNotification("❌ Admin Hook kosong!",true) return end
    local all=Players:GetPlayers(); local str="Current Players ("..#all.."):\n\n"
    for i,p in ipairs(all) do str=str..i..". "..p.DisplayName.." (@"..p.Name..")\n" end
    task.spawn(function()
        local payload={username="PAN HOOK",embeds={{title="👥 Player On Server",description="```\n"..str.."\n```",color=0x1E78FF,footer={text="PAN HOOK v3.0"}}}}
        pcall(function() httpRequest({Url=Current_Admin_Webhook,Method="POST",Headers={["Content-Type"]="application/json"},Body=HttpService:JSONEncode(payload)}) end)
    end)
    ShowNotification("✅ Terkirim!",false)
end)

CreateButton(Page_Admin,"⚠️ Send Player NOT On Server",Color3.fromRGB(200,100,50),function()
    if Current_Admin_Webhook=="" then ShowNotification("❌ Admin Hook kosong!",true) return end
    local current={}
    for _,p in ipairs(Players:GetPlayers()) do current[p.Name:lower()]=true end
    local missing={}
    for i=1,20 do
        local name=TagList[i][1]
        if name~="" and not current[name:lower()] then table.insert(missing,name) end
    end
    local txt= #missing==0 and "Semua player tagged ada di server!" or "Missing ("..#missing.."):\n"
    for i,v in ipairs(missing) do txt=txt..i..". "..v.."\n" end
    task.spawn(function()
        local payload={username="PAN HOOK",embeds={{title="⚠️ Player NOT On Server",description="```\n"..txt.."\n```",color=0xFF8C00,footer={text="PAN HOOK v3.0"}}}}
        pcall(function() httpRequest({Url=Current_Admin_Webhook,Method="POST",Headers={["Content-Type"]="application/json"},Body=HttpService:JSONEncode(payload)}) end)
    end)
    ShowNotification("✅ Terkirim!",false)
end)

-- ============================================================
-- PAGE: TELEPORT
-- ============================================================
CreateSectionLabel(Page_Teleport,"  FISHING AREAS")

local tpInfoLbl=Instance.new("TextLabel",Page_Teleport)
tpInfoLbl.BackgroundTransparency=1; tpInfoLbl.Size=UDim2.new(1,-4,0,18)
tpInfoLbl.Font=Enum.Font.Gotham; tpInfoLbl.Text="Tap area untuk teleport ke sana."
tpInfoLbl.TextColor3=Theme.TextSecond; tpInfoLbl.TextSize=10; tpInfoLbl.TextXAlignment=Enum.TextXAlignment.Left

local sortedAreas={}
for name in pairs(FishingAreas) do table.insert(sortedAreas,name) end
table.sort(sortedAreas)

local function TeleportToArea(pos, look)
    local char=Players.LocalPlayer.Character
    if not char then ShowNotification("❌ Character tidak ada!",true) return end
    local hrp=char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame=CFrame.new(pos, pos+look)*CFrame.new(0,3,0)
        ShowNotification("✅ Teleported!",false)
    else
        ShowNotification("❌ HRP tidak ditemukan!",true)
    end
end

for i=1,#sortedAreas,2 do
    local name1=sortedAreas[i]; local name2=sortedAreas[i+1]
    local Row=Instance.new("Frame",Page_Teleport)
    Row.BackgroundTransparency=1; Row.Size=UDim2.new(1,-4,0,32); Row.BorderSizePixel=0
    local rl=Instance.new("UIListLayout",Row); rl.FillDirection=Enum.FillDirection.Horizontal; rl.Padding=UDim.new(0,4)

    local data1=FishingAreas[name1]
    local Btn1=Instance.new("TextButton",Row)
    Btn1.BackgroundColor3=Theme.Content; Btn1.Size=UDim2.new(0.5,-2,1,0); Btn1.BorderSizePixel=0
    Btn1.Font=Enum.Font.GothamMedium; Btn1.Text=name1; Btn1.TextColor3=Theme.TextPrimary; Btn1.TextSize=10
    AddCorner(Btn1,5); AddStroke(Btn1,Theme.Border,1)
    Btn1.MouseButton1Click:Connect(function() TeleportToArea(data1.Pos,data1.Look) end)

    if name2 then
        local data2=FishingAreas[name2]
        local Btn2=Instance.new("TextButton",Row)
        Btn2.BackgroundColor3=Theme.Content; Btn2.Size=UDim2.new(0.5,-2,1,0); Btn2.BorderSizePixel=0
        Btn2.Font=Enum.Font.GothamMedium; Btn2.Text=name2; Btn2.TextColor3=Theme.TextPrimary; Btn2.TextSize=10
        AddCorner(Btn2,5); AddStroke(Btn2,Theme.Border,1)
        Btn2.MouseButton1Click:Connect(function() TeleportToArea(data2.Pos,data2.Look) end)
    end
end

-- ============================================================
-- PAGE: MISC
-- ============================================================
CreateSectionLabel(Page_Misc,"  IDENTITY")
local hideInfoLbl=Instance.new("TextLabel",Page_Misc)
hideInfoLbl.BackgroundTransparency=1; hideInfoLbl.Size=UDim2.new(1,-4,0,28)
hideInfoLbl.Font=Enum.Font.Gotham; hideInfoLbl.Text="Nama player di webhook disensor (e.g. Pan***)"
hideInfoLbl.TextColor3=Theme.TextSecond; hideInfoLbl.TextSize=10; hideInfoLbl.TextWrapped=true; hideInfoLbl.TextXAlignment=Enum.TextXAlignment.Left
CreateToggle(Page_Misc,"🕵️ Hide Identity","HideIdentity",false,nil)

local previewFrame=Instance.new("Frame",Page_Misc)
previewFrame.BackgroundColor3=Theme.Content; previewFrame.Size=UDim2.new(1,-4,0,28); previewFrame.BorderSizePixel=0
AddCorner(previewFrame,6); AddStroke(previewFrame,Theme.Border,1)
local previewLbl=Instance.new("TextLabel",previewFrame)
previewLbl.BackgroundTransparency=1; previewLbl.Position=UDim2.new(0,10,0,0); previewLbl.Size=UDim2.new(1,-20,1,0)
previewLbl.Font=Enum.Font.Gotham; previewLbl.TextColor3=Theme.TextSecond; previewLbl.TextSize=11; previewLbl.TextXAlignment=Enum.TextXAlignment.Left

local localName=Players.LocalPlayer and Players.LocalPlayer.Name or "Player"
local function UpdatePreview()
    if Settings.HideIdentity then
        previewLbl.Text="👁 Preview: "..(localName and localName~="" and (localName:sub(1,3)..string.rep("*",math.max(0,#localName-3))) or "???")
        previewLbl.TextColor3=Theme.Warning
    else
        previewLbl.Text="👁 Preview: "..localName; previewLbl.TextColor3=Theme.TextSecond
    end
end
UpdatePreview()
local origHide=ToggleRegistry["HideIdentity"]
ToggleRegistry["HideIdentity"]=function(val) if origHide then origHide(val) end; UpdatePreview() end

CreateSectionLabel(Page_Misc,"  UTILITY")
CreateToggle(Page_Misc,"🚫 Remove Fish Pop-up","DisablePopups",false,function(state)
    local PlayerGui=Players.LocalPlayer:WaitForChild("PlayerGui")
    local SmallNotif=PlayerGui:FindFirstChild("Small Notification")
    if not SmallNotif then SmallNotif=PlayerGui:WaitForChild("Small Notification",5) end
    if state and SmallNotif then
        task.spawn(function()
            while Settings.DisablePopups and ScriptActive do
                if SmallNotif and SmallNotif.Parent then SmallNotif.Enabled=false end
                task.wait(0.1)
            end
            if SmallNotif and SmallNotif.Parent then SmallNotif.Enabled=true end
        end)
    elseif SmallNotif then SmallNotif.Enabled=true end
end)

local isNoAnim=false; local origAnimScript=nil; local origAnimator=nil
CreateToggle(Page_Misc,"🤸 No Animation","NoAnimation",false,function(state)
    isNoAnim=state
    local char=Players.LocalPlayer.Character
    if state and char then
        local animScript=char:FindFirstChild("Animate")
        if animScript and animScript:IsA("LocalScript") then origAnimScript=animScript.Enabled; animScript.Enabled=false end
        local humanoid=char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            local animator=humanoid:FindFirstChildOfClass("Animator")
            if animator then origAnimator=animator; animator:Destroy() end
        end
    elseif not state and char then
        local animScript=char:FindFirstChild("Animate")
        if animScript and origAnimScript~=nil then animScript.Enabled=origAnimScript end
        local humanoid=char:FindFirstChildOfClass("Humanoid")
        if humanoid and not humanoid:FindFirstChildOfClass("Animator") then
            if origAnimator then origAnimator.Parent=humanoid else Instance.new("Animator",humanoid) end
        end
    end
end)

table.insert(Connections,Players.LocalPlayer.CharacterAdded:Connect(function(newChar)
    if isNoAnim then
        task.wait(0.2)
        local animScript=newChar:FindFirstChild("Animate")
        if animScript and animScript:IsA("LocalScript") then animScript.Enabled=false end
        local humanoid=newChar:FindFirstChildOfClass("Humanoid")
        if humanoid then
            local animator=humanoid:FindFirstChildOfClass("Animator")
            if animator then animator:Destroy() end
        end
    end
end))

-- ============================================================
-- PAGE: WEATHER
-- ============================================================
CreateSectionLabel(Page_Weather, "  AUTO BUY WEATHER")

-- Info label
local wInfoLbl = Instance.new("TextLabel", Page_Weather)
wInfoLbl.BackgroundTransparency = 1
wInfoLbl.Size = UDim2.new(1, -4, 0, 30)
wInfoLbl.Font = Enum.Font.Gotham
wInfoLbl.Text = "Centang cuaca yang ingin dibeli otomatis, lalu aktifkan toggle."
wInfoLbl.TextColor3 = Theme.TextSecond
wInfoLbl.TextSize = 10
wInfoLbl.TextWrapped = true
wInfoLbl.TextXAlignment = Enum.TextXAlignment.Left

-- ── Multi-select checkbox list ─────────────────────────────
CreateSectionLabel(Page_Weather, "  PILIH CUACA")

local weatherCheckStates = {}

local function CreateWeatherCheckbox(parent, displayName)
    local Row = Instance.new("Frame", parent)
    Row.BackgroundColor3 = Theme.Content
    Row.Size = UDim2.new(1, -4, 0, 32)
    Row.BorderSizePixel = 0
    AddCorner(Row, 6)
    AddStroke(Row, Theme.Border, 1)

    -- nama cuaca
    local Lbl = Instance.new("TextLabel", Row)
    Lbl.BackgroundTransparency = 1
    Lbl.Position = UDim2.new(0, 10, 0, 0)
    Lbl.Size = UDim2.new(1, -56, 1, 0)
    Lbl.Font = Enum.Font.GothamBold
    Lbl.Text = displayName
    Lbl.TextColor3 = Theme.TextPrimary
    Lbl.TextSize = 12
    Lbl.TextXAlignment = Enum.TextXAlignment.Left

    -- checkbox button
    local CheckBg = Instance.new("TextButton", Row)
    CheckBg.BackgroundColor3 = Theme.Input
    CheckBg.Position = UDim2.new(1, -42, 0.5, -11)
    CheckBg.Size = UDim2.new(0, 22, 0, 22)
    CheckBg.Text = ""
    CheckBg.BorderSizePixel = 0
    AddCorner(CheckBg, 4)
    AddStroke(CheckBg, Theme.Border, 1.5)

    local Tick = Instance.new("TextLabel", CheckBg)
    Tick.BackgroundTransparency = 1
    Tick.Size = UDim2.new(1, 0, 1, 0)
    Tick.Font = Enum.Font.GothamBold
    Tick.Text = "✓"
    Tick.TextColor3 = Color3.new(1, 1, 1)
    Tick.TextSize = 14
    Tick.Visible = false

    weatherCheckStates[displayName] = false

    local function Toggle()
        local newVal = not weatherCheckStates[displayName]
        weatherCheckStates[displayName] = newVal

        -- sync ke selectedWeathers (array ordered)
        selectedWeathers = {}
        for _, name in ipairs(weatherNames) do
            if weatherCheckStates[name] then
                table.insert(selectedWeathers, name)
            end
        end

        TweenService:Create(CheckBg, TweenInfo.new(0.15), {
            BackgroundColor3 = newVal and Theme.Success or Theme.Input
        }):Play()
        Tick.Visible = newVal
        ShowNotification(displayName .. (newVal and " ✅ dipilih" or " ⛔ dihapus"), not newVal)
    end

    CheckBg.MouseButton1Click:Connect(Toggle)
    Row.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then Toggle() end
    end)
end

for _, name in ipairs(weatherNames) do
    CreateWeatherCheckbox(Page_Weather, name)
end

-- ── Delay input ────────────────────────────────────────────
CreateSectionLabel(Page_Weather, "  PENGATURAN")

local delayInput = CreateInput(
    Page_Weather,
    "⏱ Delay (menit)",
    "Default: 9",
    "9",
    function(v)
        local num = tonumber(v)
        if num and num > 0 then
            buyDelay = num * 60
            ShowNotification("⏱ Delay diset ke " .. num .. " menit", false)
        else
            ShowNotification("❌ Masukkan angka valid!", true)
        end
    end
)

-- ── Status label ───────────────────────────────────────────
local wStatusFrame = Instance.new("Frame", Page_Weather)
wStatusFrame.BackgroundColor3 = Theme.Content
wStatusFrame.Size = UDim2.new(1, -4, 0, 26)
wStatusFrame.BorderSizePixel = 0
AddCorner(wStatusFrame, 5)
AddStroke(wStatusFrame, Theme.Border, 1)

local wStatusLbl = Instance.new("TextLabel", wStatusFrame)
wStatusLbl.BackgroundTransparency = 1
wStatusLbl.Position = UDim2.new(0, 10, 0, 0)
wStatusLbl.Size = UDim2.new(1, -16, 1, 0)
wStatusLbl.Font = Enum.Font.GothamMedium
wStatusLbl.Text = "⏸ Auto Buy: OFF"
wStatusLbl.TextColor3 = Theme.TextSecond
wStatusLbl.TextSize = 11
wStatusLbl.TextXAlignment = Enum.TextXAlignment.Left

-- ── Auto buy loop ──────────────────────────────────────────
local function StartWeatherBuy()
    if weatherThread then task.cancel(weatherThread) end
    weatherThread = task.spawn(function()
        while autoBuyWeather and ScriptActive do
            if #selectedWeathers == 0 then
                wStatusLbl.Text = "⚠️ Belum ada cuaca dipilih!"
                wStatusLbl.TextColor3 = Theme.Warning
                task.wait(5); break
            end

            for _, displayName in ipairs(selectedWeathers) do
                if not autoBuyWeather then break end
                local key = weatherKeyMap[displayName]
                if key then
                    local ok, err = pcall(function()
                        RFPurchaseWeatherEvent:InvokeServer(key)
                    end)
                    if ok then
                        wStatusLbl.Text = "✅ Beli: " .. displayName
                        wStatusLbl.TextColor3 = Theme.Success
                        ShowNotification("🌤️ Beli " .. displayName, false)
                    else
                        wStatusLbl.Text = "❌ Gagal: " .. displayName
                        wStatusLbl.TextColor3 = Theme.Error
                    end
                    task.wait(1.5)
                end
            end

            -- countdown
            local remaining = buyDelay
            while remaining > 0 and autoBuyWeather and ScriptActive do
                local m = math.floor(remaining / 60)
                local s = remaining % 60
                wStatusLbl.Text = string.format("⏳ Next buy: %02dm %02ds", m, s)
                wStatusLbl.TextColor3 = Theme.AccentGlow
                task.wait(1)
                remaining = remaining - 1
            end
        end

        if not autoBuyWeather then
            wStatusLbl.Text = "⏸ Auto Buy: OFF"
            wStatusLbl.TextColor3 = Theme.TextSecond
        end
    end)
end

-- ── Auto Buy toggle ────────────────────────────────────────
Settings["WeatherAutoBuy"] = false
CreateToggle(Page_Weather, "🌤️ Auto Buy Weather", "WeatherAutoBuy", false, function(state)
    autoBuyWeather = state
    if not RFPurchaseWeatherEvent then
        ShowNotification("❌ Weather event tidak ditemukan!", true)
        autoBuyWeather = false
        Settings["WeatherAutoBuy"] = false
        return
    end
    if state then
        StartWeatherBuy()
    else
        if weatherThread then task.cancel(weatherThread); weatherThread = nil end
        wStatusLbl.Text = "⏸ Auto Buy: OFF"
        wStatusLbl.TextColor3 = Theme.TextSecond
    end
end)

-- ── Manual buy button ──────────────────────────────────────
CreateButton(Page_Weather, "🛒 Beli Sekarang (Manual)", Theme.Accent, function()
    if not RFPurchaseWeatherEvent then
        ShowNotification("❌ Weather event tidak ditemukan!", true); return
    end
    if #selectedWeathers == 0 then
        ShowNotification("⚠️ Pilih cuaca dulu!", true); return
    end
    task.spawn(function()
        for _, displayName in ipairs(selectedWeathers) do
            local key = weatherKeyMap[displayName]
            if key then
                local ok = pcall(function() RFPurchaseWeatherEvent:InvokeServer(key) end)
                ShowNotification((ok and "✅ Beli " or "❌ Gagal ") .. displayName, not ok)
                task.wait(1)
            end
        end
    end)
end)

-- ============================================================
-- OPEN BUTTON
-- ============================================================



-- ============================================================
-- IDENTITY HELPER
-- ============================================================
local function MaskName(name)
    if not name or name=="" then return "???" end
    if not Settings.HideIdentity then return name end
    return name:sub(1,3)..string.rep("*",math.max(0,#name-3))
end
local function SpoilerWrap(name)
    if Settings.SpoilerName then return "||`"..name.."`||" else return "`"..name.."`" end
end

-- ============================================================
-- WEBHOOK SENDERS
-- ============================================================
local rarityInfo={
    [4]={name="Epic",      color=0xB24BF3},
    [5]={name="Legendary", color=0xFFD700},
    [6]={name="Mythic",    color=0xFF4444},
}
local chatTierKeys={[4]="EpicEnabled",[5]="LegendaryEnabled",[6]="MythicEnabled"}
local RARITY_EMOJI="https://cdn.discordapp.com/emojis/1404790745914913370.gif"

local function GetPlayerAvatar(userId)
    return "https://www.roblox.com/headshot-thumbnail/image?userId="..tostring(userId).."&width=420&height=420&format=png"
end


local function GetDiscordId(playerName)
    for i=1,20 do
        if TagList[i][1]~="" and TagList[i][1]:lower()==playerName:lower() then
            return TagList[i][2]
        end
    end
    return nil
end

local function SendWebhookRaw(url, payload)
    if not url or url=="" then return end
    pcall(function()
        httpRequest({Url=url,Method="POST",Headers={["Content-Type"]="application/json"},Body=HttpService:JSONEncode(payload)})
    end)
    SessionStats.Total=SessionStats.Total+1
    if UI_Stats["Total"] then UI_Stats["Total"].Text=tostring(SessionStats.Total) end
end

local function UpdateStat(key)
    SessionStats[key]=(SessionStats[key] or 0)+1
    if UI_Stats[key] then UI_Stats[key].Text=tostring(SessionStats[key]) end
end

-- ============================================================
-- CHAT PARSER (logic dari ITG)
-- ============================================================
local function StripTags(str) return str:gsub("<[^>]+>","") end

local function ParseDataSmart(cleanMsg)
    local msg = cleanMsg:gsub("%[Server%]: ","")
    local p,f,w = msg:match("^(.*) obtained an? (.*) %((.*)%)")
    if not p then p,f = msg:match("^(.*) obtained an? (.*)"); w="N/A" end
    if not p or not f then return nil end

    -- strip trailing ! or .
    if f:sub(-1)=="!" or f:sub(-1)=="." then f=f:sub(1,-2) end
    f=f:match("^%s*(.-)%s*$")

    local mutation=nil; local finalItem=f
    local allTargets={}
    for name,_ in pairs(SecretFishData) do table.insert(allTargets,name) end
    table.insert(allTargets,"Ruby"); table.insert(allTargets,"Evolved Enchant Stone")

    local lowerF=f:lower()
    for _,baseName in pairs(allTargets) do
        local lowerBase=baseName:lower()
        if lowerF:find(lowerBase.."$") then
            local s,e=lowerF:find(lowerBase.."$")
            if s and s>1 then
                local prefixRaw=f:sub(1,s-1)
                local checkMut=prefixRaw
                checkMut=checkMut:gsub("Big%s*",""):gsub("Shiny%s*",""):gsub("Sparkling%s*",""):gsub("Giant%s*","")
                checkMut=checkMut:match("^%s*(.-)%s*$")
                if checkMut=="" then mutation=nil; finalItem=f
                else mutation=checkMut; finalItem=f:gsub(prefixRaw,""); finalItem=finalItem:match("^%s*(.-)%s*$") end
            else mutation=nil; finalItem=f end
            break
        end
    end
    return {Player=p, Item=finalItem, Mutation=mutation, Weight=w}
end

local recentMessages={}
local function CheckAndSend(msg)
    if not ScriptActive then return end
    local cleanMsg=StripTags(msg)
    local lowerMsg=cleanMsg:lower()

    -- Dedupe
    local dedupeKey=cleanMsg:sub(1,80)
    if recentMessages[dedupeKey] then return end
    recentMessages[dedupeKey]=true
    task.delay(3,function() recentMessages[dedupeKey]=nil end)

    -- Evolved Enchant Stone
    if lowerMsg:find("evolved enchant stone") then
        if not Settings.EvolvedEnabled then return end
        local tempMsg=cleanMsg:gsub("^%[Server%]:%s*","")
        local p=tempMsg:match("^(.*) obtained an?")
        p=p and p:match("^%s*(.-)%s*$") or "Unknown"
        local maskedName=MaskName(p); local spoiledName=SpoilerWrap(maskedName)
        local playerObj=Players:FindFirstChild(p)
        local userId=playerObj and playerObj.UserId or 0
        local avatarUrl=GetPlayerAvatar(userId)
        local pingContent=GetDiscordId(p) and "GG! <@"..GetDiscordId(p)..">" or ""
        local fields={{name="👤 Player",value="**"..spoiledName.."**",inline=false},{name="🔮 Item",value="`Evolved Enchant Stone`",inline=true}}
        SendWebhookRaw(Current_Webhook,{username="PAN HOOK",content=pingContent,embeds={{title="🔮 EVOLVED ENCHANT STONE!",color=0xA855F7,fields=fields,thumbnail={url=avatarUrl},footer={text="PAN HOOK v3.0"},timestamp=os.date("!%Y-%m-%dT%H:%M:%SZ")}}})
        UpdateStat("Evolved"); return
    end

    -- Crystalized
    if lowerMsg:find("crystalized") then
        if not Settings.CrystalizedEnabled then return end
        local tempMsg=cleanMsg:gsub("^%[Server%]:%s*","")
        local p,item_full,w=tempMsg:match("^(.*) obtained an? (.*) %((.*)%)")
        if not p then p,item_full=tempMsg:match("^(.*) obtained an? (.*)"); w="N/A" end
        if p and item_full then
            local finalItem=item_full
            local s,e=item_full:lower():find("crystalized")
            if s then finalItem=item_full:sub(e+1):gsub("^%s+","") end
            local check=finalItem:lower()
            local allowed={"bioluminescent octopus","blossom jelly","cute dumbo","star snail","blue sea dragon"}
            local isAllowed=false
            for _,v in ipairs(allowed) do if check:find(v) then isAllowed=true; break end end
            if isAllowed then
                local maskedName=MaskName(p); local spoiledName=SpoilerWrap(maskedName)
                local playerObj=Players:FindFirstChild(p); local userId=playerObj and playerObj.UserId or 0
                local avatarUrl=GetPlayerAvatar(userId); local pingContent=GetDiscordId(p) and "GG! <@"..GetDiscordId(p)..">" or ""
                local fields={{name="👤 Player",value="**"..spoiledName.."**",inline=false},{name="🐟 Ikan",value="`"..finalItem.."`",inline=true},{name="✨ Mutasi",value="`Crystalized`",inline=true},{name="⚖️ Berat",value="`"..w.."`",inline=true}}
                SendWebhookRaw(Current_Webhook,{username="PAN HOOK",content=pingContent,embeds={{title="✨ CRYSTALIZED MUTATION!",color=0x3BA5FF,fields=fields,thumbnail={url=avatarUrl},footer={text="PAN HOOK v3.0"},timestamp=os.date("!%Y-%m-%dT%H:%M:%SZ")}}})
                UpdateStat("Crystalized"); return
            end
        end
    end

    if not (lowerMsg:find("obtained an?") or lowerMsg:find("obtained a ") or lowerMsg:find("chance!")) then return end

    local data=ParseDataSmart(cleanMsg)
    if not data then return end

    local maskedName=MaskName(data.Player); local spoiledName=SpoilerWrap(maskedName)
    local playerObj=Players:FindFirstChild(data.Player); local userId=playerObj and playerObj.UserId or 0
    local avatarUrl=GetPlayerAvatar(userId)
    local pingContent=GetDiscordId(data.Player) and "GG! <@"..GetDiscordId(data.Player)..">" or ""
    local mutDisplay=(data.Mutation and data.Mutation~="") and data.Mutation or "N/A"
    local lowerItem=data.Item:lower()

    -- Forgotten Fish (paling langka, cek pertama)
    local isForgotten=false
    for name,_ in pairs(ForgottenFishData) do
        if name:lower()==lowerItem then isForgotten=true; break end
    end
    if isForgotten then
        if Settings.ForgottenEnabled then
            local fields={
                {name="👤 Player",value="**"..spoiledName.."**",inline=false},
                {name="🐟 Ikan",value="`"..data.Item.."`",inline=true},
                {name="⭐ Tier",value="`FORGOTTEN`",inline=true},
                {name="⚖️ Berat",value="`"..data.Weight.."`",inline=true},
                {name="✨ Mutasi",value="`"..mutDisplay.."`",inline=true},
            }
            local embed={
                title="KELASS KINK CAIR CAIR 💀🔥",
                color=0xFF00FF,
                fields=fields,
                thumbnail={url=avatarUrl},
                footer={text="PAN HOOK v3.0 • FORGOTTEN TIER"},
                timestamp=os.date("!%Y-%m-%dT%H:%M:%SZ")
            }
            SendWebhookRaw(Current_Webhook,{username="PAN HOOK 💀",content="🔥**FORGOTTEN ☠️ DETECTED**🔥 @everyone",embeds={embed}})
            UpdateStat("Secret")
        end
        return
    end

    -- Secret Fish (cek dulu sebelum rarity)
    local isSecret=false
    for name,_ in pairs(SecretFishData) do
        if name:lower()==lowerItem then isSecret=true; break end
    end
    if isSecret then
        if Settings.SecretEnabled then
            local fields={{name="👤 Player",value="**"..spoiledName.."**",inline=false},{name="🐟 Ikan",value="`"..data.Item.."`",inline=true},{name="⭐ Rarity",value="`SECRET`",inline=true},{name="⚖️ Berat",value="`"..data.Weight.."`",inline=true},{name="✨ Mutasi",value="`"..mutDisplay.."`",inline=true}}
            SendWebhookRaw(Current_Webhook,{username="PAN HOOK",content=pingContent,embeds={{title="WIH ANAK ANJ DAPAT SIKRITTT!!!!",color=65431,fields=fields,thumbnail={url=avatarUrl},footer={text="PAN HOOK v3.0"},timestamp=os.date("!%Y-%m-%dT%H:%M:%SZ")}}})
            UpdateStat("Secret")
        end
        return
    end

    -- Ruby Gemstone
    if Settings.RubyEnabled and lowerItem:find("ruby") and data.Mutation and data.Mutation:lower():find("gemstone") then
        local fields={{name="👤 Player",value="**"..spoiledName.."**",inline=false},{name="🐟 Ikan",value="`"..data.Item.."`",inline=true},{name="⚖️ Berat",value="`"..data.Weight.."`",inline=true},{name="🧬 Mutasi",value="`Gemstone`",inline=true}}
        SendWebhookRaw(Current_Webhook,{username="PAN HOOK",content=pingContent,embeds={{title="💎 Ruby Gemstone!",color=0x32DCBC,fields=fields,thumbnail={url=avatarUrl},footer={text="PAN HOOK v3.0"},timestamp=os.date("!%Y-%m-%dT%H:%M:%SZ")}}})
        UpdateStat("Ruby"); return
    end

    -- Rarity Epic/Legendary/Mythic (dari chance di pesan)
    local chanceStr=cleanMsg:match("1 in ([%d%.]+)([KkMm]?)%s*chance")
    if chanceStr then
        local numStr=cleanMsg:match("1 in ([%d%.]+)[KkMm]?%s*chance") or "0"
        local suffix=cleanMsg:match("1 in [%d%.]+([KkMm])%s*chance") or ""
        local base=tonumber(numStr) or 0
        local num=base
        if suffix=="K" or suffix=="k" then num=base*1000
        elseif suffix=="M" or suffix=="m" then num=base*1000000 end
        local tier=nil
        if num>=1000000 then tier=6
        elseif num>=10000 then tier=5
        elseif num>=1000 then tier=4 end
        if tier and chatTierKeys[tier] and Settings[chatTierKeys[tier]] then
            local info=rarityInfo[tier]
            local fields={{name="👤 Player",value="**"..maskedName.."**",inline=false},{name="🐟 Ikan",value="`"..data.Item.."`",inline=true},{name="⭐ Rarity",value="`"..info.name.."`",inline=true},{name="⚖️ Berat",value="`"..data.Weight.."`",inline=true},{name="✨ Mutasi",value="`"..mutDisplay.."`",inline=true}}
            local payload={username="PAN HOOK",embeds={{title="**DAPATNYA AMPAS DEK, MENDING GALER AJA**",color=info.color,fields=fields,thumbnail={url=avatarUrl},footer={text="PAN HOOK v3.0"},timestamp=os.date("!%Y-%m-%dT%H:%M:%SZ")}}}
            SendWebhookRaw(Current_Webhook,payload)
        end
    end
end

-- ============================================================
-- CHAT HOOKS
-- ============================================================

-- Metode 1: OnIncomingMessage - khusus system messages (TextSource == nil)
if TextChatService then
    TextChatService.OnIncomingMessage = function(m)
        pcall(function()
            if not ScriptActive then return end
            if m and m.TextSource == nil and m.Text then
                CheckAndSend(m.Text)
            end
        end)
    end
end

-- Metode 2: Legacy chat fallback
local ChatEvents = ReplicatedStorage:WaitForChild("DefaultChatSystemChatEvents", 3)
if ChatEvents then
    local OnMessage = ChatEvents:WaitForChild("OnMessageDoneFiltering", 3)
    if OnMessage then
        table.insert(Connections, OnMessage.OnClientEvent:Connect(function(d)
            if not ScriptActive then return end
            if d and d.Message then CheckAndSend(d.Message) end
        end))
    end
end

-- ============================================================
-- CAVE CRYSTAL (Backpack monitor - aman karena cuma ChildAdded)
-- ============================================================
local CaveCrystalDebounce=0
local function WatchBackpack(bp)
    table.insert(Connections,bp.ChildAdded:Connect(function(child)
        if not ScriptActive then return end
        if child.Name=="Cave Crystal" and Settings.CaveCrystalEnabled then
            if tick()-CaveCrystalDebounce>10 then
                CaveCrystalDebounce=tick()
                local fields={{name="👤 Player",value="**"..MaskName(Players.LocalPlayer.Name).."**",inline=false},{name="⛏️ Event",value="`Cave Crystal Ditemukan!`",inline=true}}
                SendWebhookRaw(Current_Webhook,{username="PAN HOOK",embeds={{title="⛏️ Cave Crystal Event!",color=0xFFD700,fields=fields,footer={text="PAN HOOK v3.0"},timestamp=os.date("!%Y-%m-%dT%H:%M:%SZ")}}})
                UpdateStat("CaveCrystal")
            end
        end
    end))
end

task.spawn(function()
    local bp=Players.LocalPlayer:WaitForChild("Backpack",10)
    if bp then WatchBackpack(bp) end
end)

-- ============================================================
-- PLAYER JOIN/LEAVE
-- ============================================================
table.insert(Connections,Players.PlayerAdded:Connect(function(player)
    if not ScriptActive then return end
    -- Join webhook
    if Settings.LogEnabled and Current_Log_Webhook~="" then
        task.spawn(function()
            local avatarUrl=GetPlayerAvatar(player.UserId)
            local payload={username="PAN HOOK",embeds={{title="👋 Player Joined",description="**@"..MaskName(player.Name).."** bergabung ke server.",color=0x32DC32,thumbnail={url=avatarUrl},footer={text="PAN HOOK v3.0"},timestamp=os.date("!%Y-%m-%dT%H:%M:%SZ")}}}
            SendWebhookRaw(Current_Log_Webhook,payload)
        end)
    end
    -- Foreign detection
    if Settings.ForeignDetection and Current_Admin_Webhook~="" then
        local isWhitelisted=false
        for i=1,20 do
            if TagList[i][1]~="" and TagList[i][1]:lower()==player.Name:lower() then isWhitelisted=true; break end
        end
        if not isWhitelisted then
            task.spawn(function()
                local id1=(TagList[1] and TagList[1][2]) or ""; local id2=(TagList[2] and TagList[2][2]) or ""
                local tags= (id1~="" and "<@"..id1.."> " or "")..(id2~="" and "<@"..id2..">" or "")
                local payload={username="PAN HOOK",content="⚠️ Foreign Player! "..tags,embeds={{title="🕵️ Player Asing Terdeteksi!",description="```\nName: "..player.DisplayName.."\nUsername: "..player.Name.."\n```",color=0xFF4444,thumbnail={url=GetPlayerAvatar(player.UserId)},footer={text="PAN HOOK v3.0"},timestamp=os.date("!%Y-%m-%dT%H:%M:%SZ")}}}
                SendWebhookRaw(Current_Admin_Webhook,payload)
            end)
        end
    end
end))

table.insert(Connections,Players.PlayerRemoving:Connect(function(p)
    if not ScriptActive then return end
    if Settings.LogEnabled and Current_Log_Webhook~="" then
        task.spawn(function()
            local payload={username="PAN HOOK",embeds={{title="🚪 Player Left",description="**@"..MaskName(p.Name).."** meninggalkan server.",color=0xFF4444,thumbnail={url=GetPlayerAvatar(p.UserId)},footer={text="PAN HOOK v3.0"},timestamp=os.date("!%Y-%m-%dT%H:%M:%SZ")}}}
            SendWebhookRaw(Current_Log_Webhook,payload)
        end)
    end
end))

-- ============================================================
-- PING MONITOR
-- ============================================================
local LastPingAlert=0
task.spawn(function()
    while ScriptActive do
        task.wait(5)
        if Settings.PingMonitor and Current_Admin_Webhook~="" then
            local ok2,ping=pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
            if ok2 and ping>500 and tick()-LastPingAlert>60 then
                LastPingAlert=tick()
                local payload={username="PAN HOOK",content="⚠️ **HIGH PING DETECTED!**",embeds={{title="📡 Server Lag Alert",description="```\nPing: "..math.floor(ping).." ms\n```",color=0xFFFF00,footer={text="PAN HOOK v3.0"}}}}
                SendWebhookRaw(Current_Admin_Webhook,payload)
            end
        end
    end
end)

-- ============================================================
-- PLAYER NOT ON SERVER (30 menit)
-- ============================================================
task.spawn(function()
    while ScriptActive do
        task.wait(1800)
        if Settings.PlayerNonPSAuto and Current_Admin_Webhook~="" then
            local current={}
            for _,p in ipairs(Players:GetPlayers()) do current[p.Name:lower()]=true end
            local missing={}
            for i=1,20 do
                local name=TagList[i][1]
                if name~="" and not current[name:lower()] then table.insert(missing,name) end
            end
            if #missing>0 then
                local txt="Missing ("..#missing.."):\n"
                for i,v in ipairs(missing) do txt=txt..i..". "..v.."\n" end
                local payload={username="PAN HOOK",embeds={{title="⏰ Player NOT On Server",description="```\n"..txt.."\n```",color=0xFF8C00,footer={text="PAN HOOK v3.0"}}}}
                SendWebhookRaw(Current_Admin_Webhook,payload)
            end
        end
    end
end)

-- ============================================================
-- AUTO SAVE / LOAD DEFAULT CONFIG
-- ============================================================

-- ============================================================
print("✅ PAN HOOK v3.0 Loaded!")
ShowNotification("🎣 PAN HOOK v3.0 Ready!",false)
