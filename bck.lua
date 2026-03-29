--// ================================
--// CONFIG
--// ================================
local INVENTORY_FOLDER = "Inventory"
local REMOTE_FOLDER_PATH = "RemoteEvents"

local REMOTE_TRADE_REQUEST = "TradeRequest"
local REMOTE_TRADE_ACCEPT = "AcceptTrade"
local REMOTE_ADD_ITEM = "AddItemToTrade"
local REMOTE_CONFIRM_TRADE = "ConfirmTrade"

local LOOP_DELAY = 0.5
local ACTION_DELAY = 0.3

--// ================================
--// SERVICES
--// ================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

--// ================================
--// STATE
--// ================================
local State = {
    TargetUsername = "",
    AutoAccept = false,
    AutoAdd = false,
    AutoConfirm = false,
    TradeActive = false,
}

local SelectedFish = {}
local FishToggles = {}

--// ================================
--// REMOTE HELPER
--// ================================
local function GetRemote(name)
    local folder = ReplicatedStorage:FindFirstChild(REMOTE_FOLDER_PATH)
    if folder then
        return folder:FindFirstChild(name)
    end
    return ReplicatedStorage:FindFirstChild(name)
end

--// ================================
--// INVENTORY SCAN
--// ================================
local function GetAllFish()
    local counts = {}

    local playerData = LocalPlayer:FindFirstChild("PlayerData")
                    or LocalPlayer:FindFirstChild("Data")
                    or LocalPlayer:FindFirstChild(INVENTORY_FOLDER)

    if not playerData then
        playerData = LocalPlayer:FindFirstChildOfClass("Folder")
    end

    if playerData then
        local inv = playerData:FindFirstChild(INVENTORY_FOLDER) or playerData

        for _, item in ipairs(inv:GetChildren()) do
            counts[item.Name] = (counts[item.Name] or 0) + 1
        end
    end

    return counts
end

local function GetTargetItems()
    local items = {}

    local playerData = LocalPlayer:FindFirstChild("PlayerData")
                    or LocalPlayer:FindFirstChild("Data")
                    or LocalPlayer:FindFirstChild(INVENTORY_FOLDER)

    if not playerData then
        playerData = LocalPlayer:FindFirstChildOfClass("Folder")
    end

    if playerData then
        local inv = playerData:FindFirstChild(INVENTORY_FOLDER) or playerData

        for _, item in ipairs(inv:GetChildren()) do
            if SelectedFish[item.Name] then
                table.insert(items, item)
            end
        end
    end

    return items
end

--// ================================
--// LOAD RAYFIELD
--// ================================
local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Rayfield/main/source"))()

local Window = Rayfield:CreateWindow({
    Name = "Fish It Auto Trade",
    LoadingTitle = "DVN Script",
    LoadingSubtitle = "by cit 😎",
    ConfigurationSaving = {
        Enabled = false
    }
})

local Tab = Window:CreateTab("Trading")

--// ================================
--// BUILD FISH UI
--// ================================
local function BuildFishUI()
    for _, v in pairs(FishToggles) do
        pcall(function() v:Destroy() end)
    end
    FishToggles = {}

    local data = GetAllFish()

    for name, count in pairs(data) do
        FishToggles[name] = Tab:CreateToggle({
            Name = name .. " (" .. count .. ")",
            CurrentValue = SelectedFish[name] or false,
            Callback = function(val)
                SelectedFish[name] = val
            end
        })
    end
end

--// ================================
--// UI CONTROLS
--// ================================
Tab:CreateInput({
    Name = "Target Username",
    PlaceholderText = "Masukkan username...",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        State.TargetUsername = text
    end
})

Tab:CreateToggle({
    Name = "Auto Accept",
    CurrentValue = false,
    Callback = function(v) State.AutoAccept = v end
})

Tab:CreateToggle({
    Name = "Auto Add Selected Fish",
    CurrentValue = false,
    Callback = function(v) State.AutoAdd = v end
})

Tab:CreateToggle({
    Name = "Auto Confirm",
    CurrentValue = false,
    Callback = function(v) State.AutoConfirm = v end
})

Tab:CreateButton({
    Name = "🔄 Refresh Fish",
    Callback = function()
        BuildFishUI()
    end
})

--// ================================
--// TRADE LOGIC
--// ================================
local function TryAcceptTrade(player)
    if not State.AutoAccept then return end
    if player.Name ~= State.TargetUsername then return end

    local remote = GetRemote(REMOTE_TRADE_ACCEPT)
    if remote then
        remote:FireServer(player)
        State.TradeActive = true
    end
end

local function TryAddItems()
    if not State.AutoAdd then return end
    if not State.TradeActive then return end

    local items = GetTargetItems()
    local remote = GetRemote(REMOTE_ADD_ITEM)

    if remote then
        for _, item in ipairs(items) do
            task.wait(ACTION_DELAY)
            remote:FireServer(item.Name)
        end
    end
end

local function TryConfirm()
    if not State.AutoConfirm then return end
    if not State.TradeActive then return end

    local remote = GetRemote(REMOTE_CONFIRM_TRADE)
    if remote then
        task.wait(ACTION_DELAY)
        remote:FireServer()
        State.TradeActive = false
    end
end

--// ================================
--// LISTENER
--// ================================
task.spawn(function()
    local remote = GetRemote(REMOTE_TRADE_REQUEST)
    if remote then
        remote.OnClientEvent:Connect(function(sender)
            if typeof(sender) == "Instance" then
                TryAcceptTrade(sender)
            end
        end)
    end
end)

--// ================================
--// LOOP
--// ================================
task.spawn(function()
    while true do
        task.wait(LOOP_DELAY)

        if State.TradeActive then
            TryAddItems()
            TryConfirm()
        end
    end
end)

--// ================================
--// AUTO LOAD
--// ================================
task.spawn(function()
    task.wait(1)
    BuildFishUI()
end)
