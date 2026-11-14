Created At: 2026-11-14T04:29:48Z
Completed At: 2026-11-14T04:30:14Z
Command exited with code 0.

Command output:
-- [SkyP Cracked] Status ping removed


local G = (getgenv and getgenv()) or _G
for _, key in ipairs({ "__Alfian", "__KzoyzOpus", "__GTFarm" }) do -- versi lama ikut dibersihkan
    if G[key] and G[key].Cleanup then pcall(G[key].Cleanup) end
    G[key] = nil
end
local Session = {}
G.__Alfian = Session
local function alive()
    return G.__Alfian == Session
end

---------------------------------------------------------------------
-- LISENSI: key dicek ke server saat mulai & tiap 2 menit
---------------------------------------------------------------------
-- Server (Worker /hb) yang memutuskan: key valid? device cocok? sedang dipakai di tempat lain? dimatikan admin?
--   "ok"   = boleh jalan            "stop" = ditolak server: script berhenti
--   "fail" = tidak bisa konek (5x berturut-turut = berhenti)
--   "off"  = server belum punya rute /hb (pengecekan belum dipasang): script jalan seperti biasa
-- Tidak ada rahasia di sini. Menu Admin hanya muncul untuk key yang ditandai admin di server,
-- dan tiap aksi admin tetap dicek server memakai ADMIN_KEY yang diketik sendiri.
Session.Lic = { Api = "https://skyp-api.koplak132asu.workers.dev", Ver = "2.5", Admin = true, Fails = 0, Off = true }
do
    local Lic = Session.Lic
    Lic.Admin = true
    Lic.Off = true
    Lic.Key = "CRACKED"
    -- License check removed - always admin
    function Lic.get(url, headers) return '{"ok":true}', 200 end
    function Lic.beat() return "off" end
    function Lic.admin(path, params) return {ok=true}, nil end
    function Lic.trialInfo() end
end

do
    local getId = getthreadidentity or get_thread_identity or getidentity or (syn and syn.get_thread_identity)
    if type(getId) == "function" then pcall(function() Session.Ident = getId() end) end
    Session.Exec = coroutine.create(function(job)
        while true do
            local ok, err = pcall(job)
            job = coroutine.yield(ok, err)
        end
    end)
end

---------------------------------------------------------------------
-- SERVICES & MODULE GAME
---------------------------------------------------------------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- PATCH: game diupdate, nama modul diacak dan folder Shared hilang.
-- Modul sekarang dicari lewat ISI-nya (sidik jari), bukan lewat nama. Semua WaitForChild diberi timeout.
local Shared = ReplicatedStorage:FindFirstChild("Shared") -- bisa nil (game baru)
local WorldRemotes = ReplicatedStorage:WaitForChild("WorldRemotes", 10) or Instance.new("Folder")
-- Remote lama (versi game sebelum ByteNet). Hanya dipakai kalau fungsi baru tidak ada.
local SetTileRemote = WorldRemotes:FindFirstChild("SetTile")

Session.Found = {}
do
    local Found = Session.Found
    local function field(t, k)
        local ok, v = pcall(function() return t[k] end)
        return ok and v or nil
    end
    local function isFn(t, k) return type(field(t, k)) == "function" end
    -- PATCH ItemDB: item cukup punya "name" (kind jadi nilai tambah), boleh array berisi field id
    local function itemOk(v)
        return type(v) == "table" and type(field(v, "name")) == "string"
    end
    local function itemScore(t)
        if type(t) ~= "table" then return 0 end
        local good = 0
        pcall(function()
            local a = field(t, 2) or field(t, 1) or field(t, 3)
            if not itemOk(a) then
                local _, f = next(t)
                if not itemOk(f) then return end
            end
            local n = 0
            for _, v in pairs(t) do
                n = n + 1
                if itemOk(v) then
                    good = good + 1
                    if field(v, "kind") ~= nil then good = good + 1 end
                end
                if n > 1500 then break end
            end
        end)
        return good
    end
    Found.itemScore = itemScore
    local mods = {}
    if getloadedmodules then pcall(function() mods = getloadedmodules() end) end
    local bestItems = 0
    for _, m in ipairs(mods) do
        local ok, v = pcall(require, m)
        if ok and type(v) == "table" then
            if not Found.Net and isFn(v, "call") and type(field(v, "act")) == "table" and type(field(v, "tile")) == "table" then
                Found.Net = v
            elseif not Found.Roles and isFn(v, "titlesOf") and isFn(v, "isModerator") then
                Found.Roles = v
            elseif not Found.Sfx and isFn(v, "play") and isFn(v, "playAt") then
                Found.Sfx = v
            elseif not Found.Inventory and isFn(v, "room") and isFn(v, "used") and isFn(v, "select")
                and isFn(v, "count") and isFn(v, "add") and isFn(v, "new") then
                Found.Inventory = v
            elseif not Found.Splice and isFn(v, "result") and field(v, "SETS") ~= nil then
                Found.Splice = v
            elseif not Found.Menu and isFn(v, "isDown") and field(v, "KEYS") ~= nil then
                Found.Menu = v
            elseif not Found.Particles and isFn(v, "spawn") and not isFn(v, "play") then
                Found.Particles = v
            else
                local sc = itemScore(v)
                if sc > bestItems then bestItems = sc; Found.ItemDB = v end
                -- data item bisa ada di sub-tabel modul (mis. M.items / M.list)
                pcall(function()
                    for _, sub in pairs(v) do
                        if type(sub) == "table" then
                            local s2 = itemScore(sub)
                            if s2 > bestItems then bestItems = s2; Found.ItemDB = sub end
                        end
                    end
                end)
            end
        end
    end
    if bestItems < 50 then Found.ItemDB = nil end

    local report = {}
    for _, n in ipairs({ "Net", "Roles", "Sfx", "Inventory", "Splice", "Menu", "Particles", "ItemDB" }) do
        report[#report + 1] = n .. "=" .. (Found[n] and "ok" or "HILANG")
    end
    Session.ResolveReport = table.concat(report, " ")
    print("[SkyP] resolver modul: " .. Session.ResolveReport)
    if not Found.ItemDB then warn("[SkyP] ItemDB tidak ditemukan, nama item tidak tersedia") end
    if not Found.Inventory then warn("[SkyP] modul Inventory tidak ditemukan, fitur inventori bisa tidak jalan") end
end

-- PATCH ItemDB: tabel lokal diisi dari sumber yang ketemu (modul / sub-tabel / getgc).
-- Kalau belum ketemu saat start, dicari ulang otomatis (maks tiap 8 dtk) saat item dibaca.
local ItemDB = {}
do
    local Found = Session.Found
    local function fill(src)
        if type(src) ~= "table" then return false end
        local n = 0
        pcall(function()
            for k, v in pairs(src) do
                if type(v) == "table" and type(v.name) == "string" then
                    local id = (type(v.id) == "number" and v.id) or tonumber(k)
                    if id then rawset(ItemDB, id, v); n += 1 end
                end
            end
        end)
        return n > 0
    end
    local function scan()
        if next(ItemDB) ~= nil then return true end
        if Found.ItemDB and fill(Found.ItemDB) then return true end
        -- nama lama masih ada?
        pcall(function()
            local m = ReplicatedStorage:FindFirstChild("ItemDB", true)
            if m and m:IsA("ModuleScript") then
                local ok, v = pcall(require, m)
                if ok and Found.itemScore(v) >= 50 then Found.ItemDB = v end
            end
        end)
        if Found.ItemDB and fill(Found.ItemDB) then return true end
        if not getgc then return false end
        local best, bestSc = nil, 0
        pcall(function()
            for _, v in ipairs(getgc(true)) do
                if type(v) == "table" then
                    local a = rawget(v, 2) or rawget(v, 1)
                    if type(a) == "table" and type(rawget(a, "name")) == "string" then
                        local sc = Found.itemScore(v)
                        if sc > bestSc then best, bestSc = v, sc end
                    end
                end
            end
        end)
        if best and bestSc >= 50 then
            Found.ItemDB = best
            return fill(best)
        end
        return false
    end
    Session.scanItemDB = scan
    -- cocokkan ulang pakai id yang benar-benar ada di tas (kalau tabel yang ketemu ternyata salah)
    local lastFix = 0
    function Session.fixItemDB(ids)
        if #ids == 0 or os.clock() - lastFix < 15 then return false end
        lastFix = os.clock()
        local function score(t)
            local sc = 0
            for _, id in ipairs(ids) do
                local it = rawget(t, id)
                if type(it) == "table" and type(rawget(it, "name")) == "string" then
                    sc += (rawget(it, "kind") ~= nil) and 2 or 1
                end
            end
            return sc
        end
        local best, bestSc = nil, 0
        for _, m in pairs(Found) do
            if type(m) == "table" then
                local ok, sc = pcall(score, m)
                if ok and sc > bestSc then best, bestSc = m, sc end
            end
        end
        if getgc then
            pcall(function()
                for i, v in ipairs(getgc(true)) do
                    if type(v) == "table" then
                        local ok, sc = pcall(score, v)
                        if ok and sc > bestSc then best, bestSc = v, sc end
                    end
                end
            end)
        end
        if best and bestSc > 0 then
            table.clear(ItemDB)
            Found.ItemDB = best
            fill(best)
            for _, id in ipairs(ids) do -- pastikan id di tas terisi walau tabelnya array
                local it = rawget(best, id)
                if type(it) == "table" then rawset(ItemDB, id, it) end
            end
            print("[SkyP] ItemDB dicocokkan ulang dari isi tas (skor " .. bestSc .. "/" .. (#ids * 2) .. ")")
            return true
        end
        warn("[SkyP] ItemDB tidak cocok dengan isi tas")
        return false
    end
    local last = os.clock()
    setmetatable(ItemDB, { __index = function(_, id)
        if next(ItemDB) == nil and os.clock() - last > 8 then
            last = os.clock()
            if scan() then return rawget(ItemDB, id) end
        end
        return nil
    end })
    if not scan() then
        task.delay(3, function()
            if scan() then print("[SkyP] ItemDB ketemu (cari ulang)") else
                warn("[SkyP] ItemDB masih belum ketemu, item ditampilkan sebagai Item #id") end
        end)
    end
end
local InventoryModule = Session.Found.Inventory or {}
local NetOk, Net = Session.Found.Net ~= nil, Session.Found.Net

local GameGui = PlayerGui:WaitForChild("GameGui", 10) or PlayerGui
local ParticlesOk, ParticlesModule = Session.Found.Particles ~= nil, Session.Found.Particles
local MenuModOk, MenuModule = Session.Found.Menu ~= nil, Session.Found.Menu
local RolesOk, RolesModule = Session.Found.Roles ~= nil, Session.Found.Roles
local SfxOk, SfxModule = Session.Found.Sfx ~= nil, Session.Found.Sfx

-- UI: library bawaan (SkyUI, tema biru), tidak lagi download dari luar
local WindUI = (function()
-- SkyUI: library UI bawaan SkyP (tema biru). API kompatibel dengan pemanggilan lama.
-- Window / Section / Tab / Toggle / Button / Input / Slider / Dropdown / Paragraph, Notify, Popup.
local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

local Lib = { _guis = {}, _conns = {}, _open = nil, Text = {}, Logo = "" }

local K = {
    bg = Color3.fromRGB(13, 15, 20),
    side = Color3.fromRGB(17, 19, 26),
    card = Color3.fromRGB(23, 26, 35),
    card2 = Color3.fromRGB(32, 36, 48),
    line = Color3.fromRGB(44, 49, 64),
    accent = Color3.fromRGB(62, 150, 255),
    accentHi = Color3.fromRGB(132, 196, 255),
    accentLo = Color3.fromRGB(24, 58, 110),
    text = Color3.fromRGB(236, 240, 247),
    sub = Color3.fromRGB(139, 148, 167),
    white = Color3.new(1, 1, 1),
    ok = Color3.fromRGB(70, 210, 130),
}
local F, FM, FB = Enum.Font.Gotham, Enum.Font.GothamMedium, Enum.Font.GothamBold
local LEFT, RIGHT = Enum.TextXAlignment.Left, Enum.TextXAlignment.Right
local AUTO_Y, AUTO_X = Enum.AutomaticSize.Y, Enum.AutomaticSize.X

local function mk(class, props, parent)
    local o = Instance.new(class)
    if props then
        for k, v in pairs(props) do o[k] = v end
    end
    if parent then o.Parent = parent end
    return o
end

local function round(o, r) return mk("UICorner", { CornerRadius = UDim.new(0, r) }, o) end

local function outline(o, col, th, tr)
    return mk("UIStroke", {
        Color = col, Thickness = th or 1, Transparency = tr or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, o)
end

local function pad(o, l, t, r, b)
    return mk("UIPadding", {
        PaddingLeft = UDim.new(0, l), PaddingTop = UDim.new(0, t),
        PaddingRight = UDim.new(0, r), PaddingBottom = UDim.new(0, b),
    }, o)
end

local function vlist(o, gap)
    return mk("UIListLayout", { Padding = UDim.new(0, gap or 0), SortOrder = Enum.SortOrder.LayoutOrder }, o)
end

local function tween(o, t, props)
    local tw = TS:Create(o, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
    tw:Play()
    return tw
end

local function text(parent, props)
    local p = {
        BackgroundTransparency = 1, Font = F, TextSize = 12, TextColor3 = K.text,
        TextXAlignment = LEFT, Text = "", BorderSizePixel = 0,
    }
    for k, v in pairs(props) do p[k] = v end
    return mk("TextLabel", p, parent)
end

local function track(c)
    Lib._conns[#Lib._conns + 1] = c
    return c
end

local function fire(cb, a)
    if type(cb) ~= "function" then return end
    task.spawn(function()
        local ok, e = pcall(cb, a)
        if not ok then warn("[SkyP] UI callback: " .. tostring(e)) end
    end)
end

local function hostParent()
    local ok, h = pcall(function() return gethui and gethui() end)
    if ok and h then return h end
    return game:GetService("CoreGui")
end

local function newGui(name, order)
    local sg = mk("ScreenGui", {
        Name = name, ResetOnSpawn = false, IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = order or 998,
    })
    if syn and syn.protect_gui then pcall(syn.protect_gui, sg) end
    sg.Parent = hostParent()
    Lib._guis[#Lib._guis + 1] = sg
    return sg
end

local function closeOpen()
    local o = Lib._open
    Lib._open = nil
    if o then pcall(o) end
end

local function strOf(v)
    if v == nil then return "" end
    return tostring(v)
end

local function T(key, fallback)
    local v = Lib.Text[key]
    if type(v) == "string" and v ~= "" then return v end
    return fallback
end

-- Geser: handle ditarik, target ikut bergerak
local function makeDraggable(handle, target, threshold, onTap)
    local dragging, startIn, startPos, moved = false, nil, nil, false
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging, moved = true, false
            startIn, startPos = input.Position, target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    if dragging and not moved and onTap then onTap() end
                    dragging = false
                end
            end)
        end
    end)
    track(UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - startIn
            if not moved and d.Magnitude > (threshold or 0) then moved = true end
            if moved then
                target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                    startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end
    end))
end

local function resolveLogo()
    local l = Lib.Logo
    if type(l) ~= "string" or l == "" then return nil end
    if Lib._logoSrc == l then return Lib._logoImg end
    Lib._logoSrc = l
    local img
    if l:match("^%d+$") then
        img = "rbxassetid://" .. l
    elseif l:match("^rbxassetid://") or l:match("^rbxasset://") then
        img = l
    elseif l:match("^https?://") then
        pcall(function()
            local data = game:HttpGet(l)
            local name = "skyp_logo_" .. tostring(#l) .. ".png"
            writefile(name, data)
            img = getcustomasset(name)
        end)
    end
    Lib._logoImg = img
    return img
end

local function badge(parent, size, textSize)
    local b = mk("Frame", { Size = UDim2.fromOffset(size, size), BackgroundColor3 = K.accent, BorderSizePixel = 0 }, parent)
    round(b, math.floor(size * 0.3))
    local img = resolveLogo()
    if img then
        b.BackgroundColor3 = K.bg
        local il = mk("ImageLabel", {
            Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = img,
            ScaleType = Enum.ScaleType.Crop, BorderSizePixel = 0,
        }, b)
        round(il, math.floor(size * 0.3))
        return b
    end
    mk("UIGradient", {
        Color = ColorSequence.new(K.accentHi, K.accent), Rotation = 45,
    }, b)
    text(b, {
        Size = UDim2.fromScale(1, 1), Text = "S", Font = FB, TextSize = textSize or 15,
        TextColor3 = K.white, TextXAlignment = Enum.TextXAlignment.Center,
    })
    return b
end

---------------------------------------------------------------------
-- NOTIFIKASI
---------------------------------------------------------------------
local toastHolder
function Lib:Notify(cfg)
    cfg = cfg or {}
    if not toastHolder or not toastHolder.Parent then
        local g = newGui("SkyP_Toast", 1000)
        toastHolder = mk("Frame", {
            BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -14, 0, 56), Size = UDim2.fromOffset(280, 0), AutomaticSize = AUTO_Y,
        }, g)
        local l = vlist(toastHolder, 8)
        l.HorizontalAlignment = Enum.HorizontalAlignment.Right
    end
    local kids = {}
    for _, c in ipairs(toastHolder:GetChildren()) do
        if c:IsA("Frame") then kids[#kids + 1] = c end
    end
    if #kids >= 4 then kids[1]:Destroy() end

    local dur = tonumber(cfg.Duration) or 3
    local toast = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, BackgroundColor3 = K.card,
        BackgroundTransparency = 1, ClipsDescendants = true, BorderSizePixel = 0,
    }, toastHolder)
    round(toast, 10)
    local st = outline(toast, K.line, 1, 1)
    local inner = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, BackgroundTransparency = 1, BorderSizePixel = 0,
    }, toast)
    pad(inner, 14, 10, 12, 12)
    vlist(inner, 2)
    mk("Frame", { Size = UDim2.new(0, 3, 1, 0), BackgroundColor3 = K.accent, BorderSizePixel = 0 }, toast)
    local tl = text(inner, {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, Font = FB, TextSize = 13,
        Text = strOf(cfg.Title), TextWrapped = true, TextTransparency = 1, LayoutOrder = 1,
    })
    local cl = text(inner, {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, TextSize = 12, TextColor3 = K.sub,
        Text = strOf(cfg.Content), TextWrapped = true, TextTransparency = 1, LayoutOrder = 2,
        Visible = strOf(cfg.Content) ~= "",
    })
    local bar = mk("Frame", {
        AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = K.accent, BorderSizePixel = 0, BackgroundTransparency = 0.2, ZIndex = 5,
    }, toast)

    tween(toast, 0.2, { BackgroundTransparency = 0.04 })
    tween(st, 0.2, { Transparency = 0.2 })
    tween(tl, 0.2, { TextTransparency = 0 })
    tween(cl, 0.2, { TextTransparency = 0 })
    TS:Create(bar, TweenInfo.new(dur, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 2) }):Play()

    task.delay(dur, function()
        if not toast.Parent then return end
        tween(toast, 0.25, { BackgroundTransparency = 1 })
        tween(st, 0.25, { Transparency = 1 })
        tween(tl, 0.25, { TextTransparency = 1 })
        tween(cl, 0.25, { TextTransparency = 1 })
        tween(bar, 0.25, { BackgroundTransparency = 1 })
        task.delay(0.3, function()
            if toast.Parent then toast:Destroy() end
        end)
    end)
end

---------------------------------------------------------------------
-- POPUP (dialog tengah layar)
---------------------------------------------------------------------
function Lib:Popup(cfg)
    cfg = cfg or {}
    local g = newGui("SkyP_Popup", 1001)
    local dim = mk("TextButton", {
        Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1,
        Text = "", AutoButtonColor = false, BorderSizePixel = 0,
    }, g)
    tween(dim, 0.2, { BackgroundTransparency = 0.5 })
    local card = mk("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(330, 0), AutomaticSize = AUTO_Y, BackgroundColor3 = K.bg,
        BorderSizePixel = 0, Active = true,
    }, dim)
    round(card, 14)
    outline(card, K.line, 1)
    pad(card, 18, 18, 18, 16)
    vlist(card, 12)
    local sc = mk("UIScale", { Scale = 0.92 }, card)
    tween(sc, 0.18, { Scale = 1 })

    local head = mk("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, LayoutOrder = 1 }, card)
    local b = badge(head, 28, 15)
    b.Position = UDim2.fromOffset(0, 1)
    text(head, {
        Position = UDim2.fromOffset(38, 0), Size = UDim2.new(1, -38, 1, 0), Font = FB, TextSize = 16,
        Text = strOf(cfg.Title),
    })
    local content = strOf(cfg.Content)
    if content ~= "" then
        text(card, {
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, TextSize = 13, TextColor3 = K.sub,
            TextWrapped = true, Text = content, LayoutOrder = 2,
        })
    end
    local buttons = cfg.Buttons or {}
    local n = #buttons
    if n > 0 then
        local rowf = mk("Frame", { Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1, LayoutOrder = 3 }, card)
        mk("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, rowf)
        for i, bd in ipairs(buttons) do
            local primary = bd.Variant == "Primary"
            local btn = mk("TextButton", {
                Size = UDim2.new(1 / n, -math.floor(8 * (n - 1) / n), 1, 0), LayoutOrder = i,
                BackgroundColor3 = primary and K.accent or K.card2, AutoButtonColor = false,
                Text = strOf(bd.Title), Font = FB, TextSize = 13, TextColor3 = K.white, BorderSizePixel = 0,
            }, rowf)
            round(btn, 9)
            if not primary then outline(btn, K.line, 1) end
            btn.MouseEnter:Connect(function()
                tween(btn, 0.12, { BackgroundColor3 = primary and K.accentHi or K.line })
            end)
            btn.MouseLeave:Connect(function()
                tween(btn, 0.12, { BackgroundColor3 = primary and K.accent or K.card2 })
            end)
            btn.MouseButton1Click:Connect(function()
                fire(bd.Callback)
                if g.Parent then g:Destroy() end
            end)
        end
    end
end

---------------------------------------------------------------------
-- ELEMEN (dipakai Tab dan Section)
---------------------------------------------------------------------
local Methods = {}

local function nextOrder(self)
    self._n = self._n + 1
    return self._n
end

-- baris dasar: kartu dengan judul + deskripsi, area kontrol di kanan
-- return: row, titleLabel, descLabel, top (tempat kontrol kanan)
local function baseRow(self, cfg, rightW)
    local row = mk("Frame", {
        BackgroundColor3 = self._rowColor, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y,
        LayoutOrder = nextOrder(self), BorderSizePixel = 0,
    }, self._holder)
    round(row, 8)
    outline(row, K.line, 1, 0.45)
    pad(row, 12, 9, 12, 9)
    vlist(row, 8)

    local topf = mk("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, LayoutOrder = 1,
    }, row)
    mk("UISizeConstraint", { MinSize = Vector2.new(0, 26) }, topf)
    local info = mk("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, -(rightW or 0), 0, 0), AutomaticSize = AUTO_Y,
    }, topf)
    vlist(info, 2)
    local title, desc = strOf(cfg.Title), strOf(cfg.Desc)
    local tl = text(info, {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, Font = FM, TextSize = 13,
        TextWrapped = true, Text = title, LayoutOrder = 1,
    })
    local dl = text(info, {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, TextSize = 11, TextColor3 = K.sub,
        TextWrapped = true, Text = desc, Visible = desc ~= "", LayoutOrder = 2,
    })
    return row, tl, dl, topf
end

-- daftarkan ke pencarian + pasang SetTitle / SetDesc / Destroy
local function finish(self, obj, row, tl, dl)
    local it = { frame = row, title = tl.Text, desc = dl.Text }
    it.key = (it.title .. " " .. it.desc):lower()
    local tab = self._tab
    tab._items[#tab._items + 1] = it
    if self._sec then
        local s = self._sec._items
        s[#s + 1] = it
    end
    function obj:SetTitle(t)
        t = strOf(t)
        if tl.Text ~= t then
            tl.Text = t
            it.title = t
            it.key = (t .. " " .. it.desc):lower()
        end
    end
    function obj:SetDesc(t)
        t = strOf(t)
        if dl.Text ~= t then
            dl.Text = t
            dl.Visible = t ~= ""
            it.desc = t
            it.key = (it.title .. " " .. t):lower()
        end
    end
    function obj:Destroy()
        if row.Parent then row:Destroy() end
    end
    obj.Frame = row
    return obj
end

-- kotak transparan yang menutupi seluruh baris (untuk klik)
local function hitbox(topf)
    return mk("TextButton", {
        Text = "", AutoButtonColor = false, BackgroundTransparency = 1,
        Position = UDim2.fromOffset(-12, -9), Size = UDim2.new(1, 24, 1, 18),
    }, topf)
end

function Methods:Paragraph(cfg)
    cfg = cfg or {}
    local row, tl, dl, topf = baseRow(self, cfg, 0)
    tl.TextColor3 = K.accentHi
    tl.Font = FB
    tl.TextSize = 12
    dl.TextSize = 12
    dl.TextColor3 = K.text
    mk("Frame", {
        Size = UDim2.new(0, 3, 1, 0), Position = UDim2.new(0, -12, 0, 0),
        BackgroundColor3 = K.accent, BorderSizePixel = 0,
    }, topf)
    return finish(self, {}, row, tl, dl)
end

function Methods:Toggle(cfg)
    cfg = cfg or {}
    local row, tl, dl, topf = baseRow(self, cfg, 54)
    local hit = hitbox(topf)
    local trk = mk("Frame", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(42, 22), BackgroundColor3 = K.bg, BorderSizePixel = 0,
    }, topf)
    round(trk, 11)
    local trkLine = outline(trk, K.line, 1)
    local knob = mk("Frame", {
        Size = UDim2.fromOffset(16, 16), Position = UDim2.fromOffset(3, 3),
        BackgroundColor3 = K.sub, BorderSizePixel = 0,
    }, trk)
    round(knob, 8)

    local obj = { Value = cfg.Value == true, Callback = cfg.Callback }
    local function paint(instant)
        local on = obj.Value
        local tp = { BackgroundColor3 = on and K.accent or K.bg }
        local kp = {
            Position = on and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3),
            BackgroundColor3 = on and K.white or K.sub,
        }
        if instant then
            for k, v in pairs(tp) do trk[k] = v end
            for k, v in pairs(kp) do knob[k] = v end
        else
            tween(trk, 0.15, tp)
            tween(knob, 0.15, kp)
        end
        trkLine.Color = on and K.accentHi or K.line
    end
    paint(true)

    function obj:Set(v, silent)
        v = v and true or false
        local changed = v ~= self.Value
        self.Value = v
        paint(false)
        if changed and not silent then fire(self.Callback, v) end
    end
    hit.MouseButton1Click:Connect(function() obj:Set(not obj.Value) end)
    return finish(self, obj, row, tl, dl)
end

function Methods:Button(cfg)
    cfg = cfg or {}
    local row, tl, dl, topf = baseRow(self, cfg, 26)
    local base = (self._rowColor == K.card) and K.card2 or Color3.fromRGB(44, 49, 64)
    row.BackgroundColor3 = base
    local hit = hitbox(topf)
    text(topf, {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(20, 24),
        Text = "›", Font = FB, TextSize = 22, TextColor3 = K.accentHi, TextXAlignment = RIGHT,
    })
    local obj = { Callback = cfg.Callback }
    hit.MouseEnter:Connect(function() tween(row, 0.12, { BackgroundColor3 = K.accentLo }) end)
    hit.MouseLeave:Connect(function() tween(row, 0.12, { BackgroundColor3 = base }) end)
    hit.MouseButton1Click:Connect(function()
        row.BackgroundColor3 = K.accent
        tween(row, 0.25, { BackgroundColor3 = base })
        fire(obj.Callback)
    end)
    function obj:Click() fire(self.Callback) end
    return finish(self, obj, row, tl, dl)
end

function Methods:Input(cfg)
    cfg = cfg or {}
    local narrow = self._win._narrow
    local row, tl, dl, topf = baseRow(self, cfg, narrow and 0 or 172)
    local slot = topf
    if narrow then
        slot = mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 28), LayoutOrder = 2 }, row)
    end
    local box = mk("TextBox", {
        AnchorPoint = narrow and Vector2.new(0, 0) or Vector2.new(1, 0.5),
        Position = narrow and UDim2.new() or UDim2.new(1, 0, 0.5, 0),
        Size = narrow and UDim2.new(1, 0, 1, 0) or UDim2.fromOffset(160, 28),
        BackgroundColor3 = K.bg, Text = strOf(cfg.Value), PlaceholderText = strOf(cfg.Placeholder),
        PlaceholderColor3 = K.sub, TextColor3 = K.text, Font = FM, TextSize = 12, ClearTextOnFocus = false,
        TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, BorderSizePixel = 0,
    }, slot)
    round(box, 6)
    local st = outline(box, K.line, 1)
    pad(box, 8, 0, 8, 0)
    box.Focused:Connect(function() st.Color = K.accent end)
    local obj = { Value = box.Text, Callback = cfg.Callback }
    box.FocusLost:Connect(function()
        st.Color = K.line
        obj.Value = box.Text
        fire(obj.Callback, box.Text)
    end)
    function obj:Set(t)
        box.Text = strOf(t)
        self.Value = box.Text
    end
    return finish(self, obj, row, tl, dl)
end

function Methods:Slider(cfg)
    cfg = cfg or {}
    local vc = type(cfg.Value) == "table" and cfg.Value or {}
    local min, max = tonumber(vc.Min) or 0, tonumber(vc.Max) or 100
    if max <= min then max = min + 1 end
    local step = tonumber(cfg.Step) or 1
    if step <= 0 then step = 1 end
    local def = math.clamp(tonumber(vc.Default) or min, min, max)

    local row, tl, dl, topf = baseRow(self, cfg, 66)
    local vl = text(topf, {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(60, 20),
        Font = FB, TextSize = 13, TextColor3 = K.accentHi, TextXAlignment = RIGHT,
    })
    local holder = mk("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), LayoutOrder = 2, Active = true,
    }, row)
    local bar = mk("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(1, 0, 0, 6),
        BackgroundColor3 = K.bg, BorderSizePixel = 0,
    }, holder)
    round(bar, 3)
    local fill = mk("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = K.accent, BorderSizePixel = 0 }, bar)
    round(fill, 3)
    local knob = mk("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(14, 14),
        BackgroundColor3 = K.white, BorderSizePixel = 0,
    }, bar)
    round(knob, 7)
    outline(knob, K.accent, 2)

    local obj = { Value = def, Callback = cfg.Callback }
    local function paint()
        local a = (obj.Value - min) / (max - min)
        fill.Size = UDim2.new(a, 0, 1, 0)
        knob.Position = UDim2.new(a, 0, 0.5, 0)
        vl.Text = tostring(obj.Value)
    end
    paint()
    local function snap(v)
        v = math.floor((v - min) / step + 0.5) * step + min
        v = math.clamp(v, min, max)
        return math.floor(v * 10000 + 0.5) / 10000
    end
    function obj:Set(v, silent)
        v = tonumber(v)
        if not v then return end
        v = snap(v)
        local changed = v ~= self.Value
        self.Value = v
        paint()
        if changed and not silent then fire(self.Callback, v) end
    end
    local dragging = false
    local page = self._page
    local function fromX(x)
        local w = bar.AbsoluteSize.X
        if w <= 0 then return end
        local a = math.clamp((x - bar.AbsolutePosition.X) / w, 0, 1)
        obj:Set(min + a * (max - min))
    end
    holder.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            if page then page.ScrollingEnabled = false end
            fromX(input.Position.X)
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if page then page.ScrollingEnabled = true end
                end
            end)
        end
    end)
    track(UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            fromX(input.Position.X)
        end
    end))
    return finish(self, obj, row, tl, dl)
end

function Methods:Divider()
    local d = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = K.line, BorderSizePixel = 0, LayoutOrder = nextOrder(self),
    }, self._holder)
    return { Destroy = function() d:Destroy() end }
end

function Methods:Space(cfg)
    local h = (type(cfg) == "table" and tonumber(cfg.Columns)) or 6
    local s = mk("Frame", {
        Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, LayoutOrder = nextOrder(self),
    }, self._holder)
    return { Destroy = function() s:Destroy() end }
end

function Methods:Dropdown(cfg)
    cfg = cfg or {}
    local narrow = self._win._narrow
    local row, tl, dl, topf = baseRow(self, cfg, narrow and 0 or 172)
    local slot = topf
    if narrow then
        slot = mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 28), LayoutOrder = 2 }, row)
    end
    local btn = mk("TextButton", {
        AnchorPoint = narrow and Vector2.new(0, 0) or Vector2.new(1, 0.5),
        Position = narrow and UDim2.new() or UDim2.new(1, 0, 0.5, 0),
        Size = narrow and UDim2.new(1, 0, 1, 0) or UDim2.fromOffset(160, 28),
        BackgroundColor3 = K.bg, Text = "", AutoButtonColor = false, BorderSizePixel = 0,
    }, slot)
    round(btn, 6)
    local st = outline(btn, K.line, 1)
    local vl = text(btn, {
        Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -26, 1, 0), Font = FM, TextSize = 12,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
    text(btn, {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(10, 10),
        Text = "▼", TextSize = 8, TextColor3 = K.accentHi, TextXAlignment = Enum.TextXAlignment.Center,
    })

    local obj = {
        Values = {}, Value = nil, Multi = cfg.Multi == true, Callback = cfg.Callback,
        Placeholder = cfg.Placeholder,
    }
    local sel = {} -- daftar pilihan (urut)

    local function has(list, v)
        for _, x in ipairs(list) do
            if x == v then return true end
        end
        return false
    end
    local function sigOf(list) return table.concat(list, "\0") end

    local function sync()
        if obj.Multi then
            local c = {}
            for i, v in ipairs(sel) do c[i] = v end
            obj.Value = c
        else
            obj.Value = sel[1]
        end
        local n = #sel
        local txt
        if n == 0 then
            txt = strOf(obj.Placeholder) ~= "" and obj.Placeholder or T("Pick", "Pilih...")
        elseif n == 1 then
            txt = sel[1]
        else
            txt = sel[1] .. "  +" .. (n - 1)
        end
        vl.Text = txt
        vl.TextColor3 = (n == 0) and K.sub or K.text
    end

    local function normalize(x)
        local out = {}
        if type(x) == "table" then
            for _, v in ipairs(x) do
                v = tostring(v)
                if has(obj.Values, v) and not has(out, v) then out[#out + 1] = v end
            end
        elseif x ~= nil then
            x = tostring(x)
            if has(obj.Values, x) then out[1] = x end
        end
        if not obj.Multi and #out > 1 then out = { out[1] } end
        return out
    end

    local repaintPopup -- diisi saat popup terbuka
    local function apply(list, silent)
        local changed = sigOf(list) ~= sigOf(sel)
        sel = list
        sync()
        if repaintPopup then repaintPopup() end
        if changed and not silent then
            fire(obj.Callback, obj.Value)
        end
    end

    function obj:Select(x) apply(normalize(x), false) end
    obj.Set = obj.Select
    function obj:Refresh(list)
        local vals = {}
        if type(list) == "table" then
            for _, v in ipairs(list) do vals[#vals + 1] = tostring(v) end
        end
        self.Values = vals
        local keep = {}
        for _, v in ipairs(sel) do
            if has(vals, v) then keep[#keep + 1] = v end
        end
        sel = keep
        sync()
        if repaintPopup then repaintPopup() end
    end
    obj.SetValues = obj.Refresh

    -- popup daftar
    local function open()
        closeOpen()
        local win = self._win
        local blocker = mk("TextButton", {
            Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
            ZIndex = 200, BorderSizePixel = 0,
        }, win._gui)
        local vals = obj.Values
        local rowH = 28
        local showSearch = #vals > 8
        local listH = math.min(#vals * rowH + 8, 208)
        if #vals == 0 then listH = 36 end
        local ph = listH + (showSearch and 38 or 0)
        local pw = math.max(btn.AbsoluteSize.X, 200)
        local pos, sz = btn.AbsolutePosition, win._gui.AbsoluteSize
        local x = math.clamp(pos.X + btn.AbsoluteSize.X - pw, 6, math.max(6, sz.X - pw - 6))
        local y = pos.Y + btn.AbsoluteSize.Y + 4
        if y + ph > sz.Y - 6 then y = math.max(6, pos.Y - ph - 4) end
        local pop = mk("Frame", {
            Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(pw, ph), BackgroundColor3 = K.card,
            BorderSizePixel = 0, Active = true, ClipsDescendants = true,
        }, blocker)
        round(pop, 9)
        outline(pop, K.accent, 1, 0.3)

        local filter = ""
        local scroller = mk("ScrollingFrame", {
            BackgroundTransparency = 1, BorderSizePixel = 0,
            Position = UDim2.fromOffset(0, showSearch and 38 or 0), Size = UDim2.new(1, 0, 1, showSearch and -38 or 0),
            CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3,
            ScrollBarImageColor3 = K.accent, ScrollingDirection = Enum.ScrollingDirection.Y,
        }, pop)
        pad(scroller, 4, 4, 4, 4)
        vlist(scroller, 0)

        local function build()
            for _, c in ipairs(scroller:GetChildren()) do
                if c:IsA("GuiObject") then c:Destroy() end
            end
            local shown = 0
            for i, v in ipairs(obj.Values) do
                if filter == "" or v:lower():find(filter, 1, true) then
                    shown = shown + 1
                    local on = has(sel, v)
                    local it = mk("TextButton", {
                        Size = UDim2.new(1, 0, 0, rowH), LayoutOrder = i, Text = "", AutoButtonColor = false,
                        BackgroundColor3 = on and K.accentLo or K.card, BackgroundTransparency = on and 0.2 or 1,
                        BorderSizePixel = 0,
                    }, scroller)
                    round(it, 6)
                    if on then
                        local dot = mk("Frame", {
                            AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 8, 0.5, 0),
                            Size = UDim2.fromOffset(6, 6), BackgroundColor3 = K.accentHi, BorderSizePixel = 0,
                        }, it)
                        round(dot, 3)
                    end
                    text(it, {
                        Position = UDim2.fromOffset(22, 0), Size = UDim2.new(1, -28, 1, 0), Text = v, Font = FM,
                        TextSize = 12, TextColor3 = on and K.white or K.text,
                        TextTruncate = Enum.TextTruncate.AtEnd,
                    })
                    it.MouseEnter:Connect(function()
                        if not has(sel, v) then
                            it.BackgroundColor3 = K.card2
                            it.BackgroundTransparency = 0
                        end
                    end)
                    it.MouseLeave:Connect(function()
                        if not has(sel, v) then it.BackgroundTransparency = 1 end
                    end)
                    it.MouseButton1Click:Connect(function()
                        if obj.Multi then
                            local nl = {}
                            local found = false
                            for _, s in ipairs(sel) do
                                if s == v then found = true else nl[#nl + 1] = s end
                            end
                            if not found then nl[#nl + 1] = v end
                            apply(nl, false)
                        else
                            apply({ v }, false)
                            closeOpen()
                        end
                    end)
                end
            end
            if shown == 0 then
                text(scroller, {
                    Size = UDim2.new(1, 0, 0, 28), Text = T("NoResult", "Tidak ada"), TextColor3 = K.sub,
                    TextXAlignment = Enum.TextXAlignment.Center,
                })
            end
        end
        build()
        repaintPopup = build

        if showSearch then
            local sb = mk("TextBox", {
                Position = UDim2.fromOffset(6, 6), Size = UDim2.new(1, -12, 0, 26), BackgroundColor3 = K.bg,
                Text = "", PlaceholderText = T("Search", "Cari..."), PlaceholderColor3 = K.sub, TextColor3 = K.text,
                Font = FM, TextSize = 12, ClearTextOnFocus = false, TextXAlignment = LEFT, BorderSizePixel = 0,
            }, pop)
            round(sb, 6)
            pad(sb, 8, 0, 8, 0)
            sb:GetPropertyChangedSignal("Text"):Connect(function()
                filter = sb.Text:lower()
                build()
            end)
        end

        st.Color = K.accent
        local function close()
            repaintPopup = nil
            st.Color = K.line
            if blocker.Parent then blocker:Destroy() end
        end
        Lib._open = close
        blocker.MouseButton1Click:Connect(closeOpen)
    end
    btn.MouseButton1Click:Connect(function()
        if Lib._open then closeOpen() else open() end
    end)

    obj.Values = {}
    if type(cfg.Values) == "table" then
        for _, v in ipairs(cfg.Values) do obj.Values[#obj.Values + 1] = tostring(v) end
    end
    sel = normalize(cfg.Value)
    sync()
    return finish(self, obj, row, tl, dl)
end

-- kotak yang bisa dibuka / ditutup
function Methods:Section(cfg)
    cfg = cfg or {}
    local sec = setmetatable({}, { __index = Methods })
    local root = mk("Frame", {
        BackgroundColor3 = K.card, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y,
        LayoutOrder = nextOrder(self), BorderSizePixel = 0,
    }, self._holder)
    round(root, 10)
    outline(root, K.line, 1, 0.2)
    vlist(root, 0)
    local head = mk("TextButton", {
        Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
        LayoutOrder = 1,
    }, root)
    mk("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, 0), Size = UDim2.fromOffset(3, 14),
        BackgroundColor3 = K.accent, BorderSizePixel = 0,
    }, head)
    text(head, {
        Position = UDim2.fromOffset(24, 0), Size = UDim2.new(1, -50, 1, 0), Font = FB, TextSize = 13,
        Text = strOf(cfg.Title),
    })
    local arrow = text(head, {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(14, 14),
        TextSize = 9, TextColor3 = K.accentHi, TextXAlignment = Enum.TextXAlignment.Center,
    })
    local content = mk("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, LayoutOrder = 2,
    }, root)
    pad(content, 8, 0, 8, 8)
    vlist(content, 6)

    sec._holder, sec._tab, sec._sec, sec._win, sec._page = content, self._tab, sec, self._win, self._page
    sec._n, sec._items, sec._rowColor = 0, {}, K.card2
    sec.root = root
    sec.opened = cfg.Opened == true
    function sec:_apply(open)
        content.Visible = open
        arrow.Text = open and "▼" or "▶"
    end
    function sec:Open(v)
        self.opened = v ~= false
        self:_apply(self.opened)
    end
    sec:_apply(sec.opened)
    head.MouseButton1Click:Connect(function()
        sec.opened = not sec.opened
        sec:_apply(sec.opened)
    end)
    local tab = self._tab
    tab._sections[#tab._sections + 1] = sec
    return sec
end

---------------------------------------------------------------------
-- WINDOW
---------------------------------------------------------------------
function Lib:CreateWindow(cfg)
    -- Tampilan: HALAMAN DEPAN berisi kotak ikon (menu). Ketuk ikon -> isi menu, tombol "<" untuk kembali.
    -- Window:Section = 1 ikon di halaman depan. Section:Tab = bagian di dalam menu itu
    -- (lebih dari 1 bagian -> muncul deretan tombol kecil di atas untuk berpindah).
    cfg = cfg or {}
    if type(cfg.Text) == "table" then
        for k, v in pairs(cfg.Text) do Lib.Text[k] = v end
    end
    local Win = { Visible = true, _tabs = {}, _groups = {}, _query = "", ToggleKey = cfg.ToggleKey }
    local gui = newGui("SkyP_UI", 998)
    Win._gui = gui

    local cam = workspace.CurrentCamera
    local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
    local bw = (cfg.Size and cfg.Size.X.Offset) or 640
    local bh = (cfg.Size and cfg.Size.Y.Offset) or 380
    local W = math.clamp(bw + 50, 340, math.max(340, vp.X - 24))
    local H = math.clamp(bh + 50, 260, math.max(260, vp.Y - 24))
    Win._narrow = (W - 16) < 330
    local CENTER = Enum.TextXAlignment.Center
    local homeTitle = strOf(cfg.Title)
    local author = strOf(cfg.Author):gsub("^https?://", "")

    local main = mk("Frame", {
        Name = "Main", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(W, H), BackgroundColor3 = K.bg, BorderSizePixel = 0, Active = true,
    }, gui)
    round(main, 14)
    outline(main, K.line, 1)
    local scale = mk("UIScale", { Scale = 1 }, main)

    -- header: logo / tombol kembali, judul, cari, minimize
    local header = mk("Frame", { Size = UDim2.new(1, 0, 0, 48), BackgroundTransparency = 1, Active = true }, main)
    local lg = badge(header, 30, 16)
    lg.Position = UDim2.fromOffset(12, 9)
    local backBtn = mk("TextButton", {
        Position = UDim2.fromOffset(12, 9), Size = UDim2.fromOffset(30, 30), BackgroundColor3 = K.card2,
        Text = "<", Font = FB, TextSize = 16, TextColor3 = K.text, AutoButtonColor = false, BorderSizePixel = 0,
        Visible = false,
    }, header)
    round(backBtn, 8)
    backBtn.MouseEnter:Connect(function() tween(backBtn, 0.12, { BackgroundColor3 = K.accentLo }) end)
    backBtn.MouseLeave:Connect(function() tween(backBtn, 0.12, { BackgroundColor3 = K.card2 }) end)
    local SEARCH_W = math.clamp(math.floor(W * 0.3), 96, 190)
    local titleL = text(header, {
        Position = UDim2.fromOffset(52, 7), Size = UDim2.new(1, -(52 + SEARCH_W + 58), 0, 18), Font = FB, TextSize = 15,
        Text = homeTitle, TextTruncate = Enum.TextTruncate.AtEnd,
    })
    local subL = text(header, {
        Position = UDim2.fromOffset(52, 25), Size = UDim2.new(1, -(52 + SEARCH_W + 58), 0, 14), TextSize = 10,
        TextColor3 = K.sub, Text = author, TextTruncate = Enum.TextTruncate.AtEnd,
    })
    local minBtn = mk("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(30, 30),
        BackgroundColor3 = K.card2, Text = "–", Font = FB, TextSize = 18, TextColor3 = K.text,
        AutoButtonColor = false, BorderSizePixel = 0,
    }, header)
    round(minBtn, 8)
    minBtn.MouseEnter:Connect(function() tween(minBtn, 0.12, { BackgroundColor3 = K.accentLo }) end)
    minBtn.MouseLeave:Connect(function() tween(minBtn, 0.12, { BackgroundColor3 = K.card2 }) end)
    local search = mk("TextBox", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -50, 0.5, 0), Size = UDim2.fromOffset(SEARCH_W, 30),
        BackgroundColor3 = K.card, Text = "",
        PlaceholderText = strOf(cfg.SearchPlaceholder) ~= "" and cfg.SearchPlaceholder or T("Search", "Cari fitur..."),
        PlaceholderColor3 = K.sub, TextColor3 = K.text, Font = FM, TextSize = 12, ClearTextOnFocus = false,
        TextXAlignment = LEFT, BorderSizePixel = 0,
    }, header)
    round(search, 15)
    local searchLine = outline(search, K.line, 1)
    pad(search, 12, 0, 12, 0)
    search.Focused:Connect(function() searchLine.Color = K.accent end)
    search.FocusLost:Connect(function() searchLine.Color = K.line end)
    makeDraggable(header, main, 0)

    local body = mk("Frame", {
        Position = UDim2.fromOffset(8, 48), Size = UDim2.new(1, -16, 1, -56), BackgroundTransparency = 1,
        ClipsDescendants = true,
    }, main)

    -- halaman depan: kotak ikon
    local home = mk("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3,
        ScrollBarImageColor3 = K.accent, ScrollingDirection = Enum.ScrollingDirection.Y,
    }, body)
    pad(home, 1, 1, 5, 1)
    local COLS, GAP = ((W - 16) >= 420) and 3 or 2, 8
    local grid = mk("UIGridLayout", {
        CellPadding = UDim2.fromOffset(GAP, GAP), CellSize = UDim2.fromOffset(100, 96),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, home)
    local curW, curH = W, H
    local function regrid()
        local rows = math.max(1, math.ceil(#Win._groups / COLS))
        local cw = math.floor((curW - 16 - 6 - GAP * (COLS - 1)) / COLS)
        local ch = math.clamp(math.floor((curH - 56 - 4 - GAP * (rows - 1)) / rows), 86, 132)
        grid.CellSize = UDim2.fromOffset(math.max(60, cw), ch)
    end

    -- isi menu: deretan bagian (kalau lebih dari 1) + panel isi
    local menu = mk("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false }, body)
    local panel = mk("Frame", {
        Size = UDim2.fromScale(1, 1), BackgroundColor3 = K.side, BorderSizePixel = 0, ClipsDescendants = true,
    }, menu)
    round(panel, 10)
    outline(panel, K.line, 1, 0.3)

    local orderN = 0
    local function nextSide()
        orderN = orderN + 1
        return orderN
    end

    local function tabMatches(t, q)
        if t.title:lower():find(q, 1, true) then return true end
        for _, it in ipairs(t._items) do
            if it.key:find(q, 1, true) then return true end
        end
        return false
    end

    local function filterHome()
        local q = Win._query:lower()
        for _, g in ipairs(Win._groups) do
            local show = q == "" or g.title:lower():find(q, 1, true) ~= nil
            if not show then
                for _, t in ipairs(g.tabs) do
                    if tabMatches(t, q) then
                        show = true
                        break
                    end
                end
            end
            g.card.Visible = show
        end
    end

    -- tab = nil -> halaman depan
    function Win:_select(tab)
        closeOpen()
        self._active = tab
        local grp = tab and tab.group
        if grp then grp.last = tab end
        for _, t in ipairs(self._tabs) do
            local on = t == tab
            t.page.Visible = on
            t.btn.BackgroundColor3 = on and K.accent or K.card2
            t.btn.TextColor3 = on and K.white or K.sub
            t.btn.Font = on and FB or FM
        end
        local pills = grp ~= nil and #grp.tabs > 1
        for _, g in ipairs(self._groups) do g.pills.Visible = pills and g == grp end
        panel.Position = UDim2.fromOffset(0, pills and 36 or 0)
        panel.Size = UDim2.new(1, 0, 1, pills and -36 or 0)
        home.Visible = tab == nil
        menu.Visible = tab ~= nil
        backBtn.Visible = tab ~= nil
        lg.Visible = tab == nil
        titleL.Text = grp and (grp.emoji .. "  " .. grp.title) or homeTitle
        subL.Text = tab and ((pills and tab.title or grp.desc) or "") or author
        if tab then
            tab:_filter(self._query)
            menu.Position = UDim2.fromOffset(0, 8)
            tween(menu, 0.14, { Position = UDim2.fromOffset(0, 0) })
        else
            filterHome()
        end
    end

    function Win:_openGroup(grp)
        local tab = grp.last or grp.tabs[1]
        local q = self._query:lower()
        if q ~= "" then
            for _, t in ipairs(grp.tabs) do
                if tabMatches(t, q) then
                    tab = t
                    break
                end
            end
        end
        if tab then self:_select(tab) end
    end

    function Win:_newTab(tcfg, grp)
        tcfg = tcfg or {}
        local tab = setmetatable({}, { __index = Methods })
        tab.title = strOf(tcfg.Title)
        tab.order = tonumber(tcfg.Order) or (50 + #grp.tabs)
        local btn = mk("TextButton", {
            Size = UDim2.fromOffset(0, 28), AutomaticSize = AUTO_X, BackgroundColor3 = K.card2,
            Text = tab.title, Font = FM, TextSize = 12, TextColor3 = K.sub, AutoButtonColor = false,
            BorderSizePixel = 0, LayoutOrder = tab.order,
        }, grp.pills)
        round(btn, 14)
        pad(btn, 14, 0, 14, 0)
        local page = mk("ScrollingFrame", {
            Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false,
            CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3,
            ScrollBarImageColor3 = K.accent, ScrollingDirection = Enum.ScrollingDirection.Y,
        }, panel)
        pad(page, 10, 10, 12, 12)
        vlist(page, 8)

        tab._holder, tab._page, tab._win, tab._tab = page, page, self, tab
        tab._n, tab._items, tab._sections, tab._rowColor = 0, {}, {}, K.card
        tab.btn, tab.label, tab.page, tab.group = btn, btn, page, grp

        function tab:_filter(q)
            q = (q or ""):lower()
            for _, it in ipairs(self._items) do
                it.frame.Visible = (q == "") or (it.key:find(q, 1, true) ~= nil)
            end
            for _, s in ipairs(self._sections) do
                if q == "" then
                    s.root.Visible = true
                    s:_apply(s.opened)
                else
                    local n = 0
                    for _, it in ipairs(s._items) do
                        if it.frame.Visible then n = n + 1 end
                    end
                    s.root.Visible = n > 0
                    s:_apply(n > 0)
                end
            end
        end
        function tab:Select() Win:_select(self) end

        btn.MouseButton1Click:Connect(function() Win:_select(tab) end)

        self._tabs[#self._tabs + 1] = tab
        grp.tabs[#grp.tabs + 1] = tab
        table.sort(grp.tabs, function(x, y) return x.order < y.order end)
        grp:_refresh()
        return tab
    end

    function Win:Section(scfg)
        scfg = scfg or {}
        local grp = { tabs = {}, title = strOf(scfg.Title), desc = strOf(scfg.Desc) }
        local icon = strOf(scfg.Icon)
        if icon == "" or icon:match("^[%w%-_ ]+$") then icon = "📁" end -- nama ikon lama (bukan emoji)
        grp.emoji = icon
        local tint = (typeof(scfg.Color) == "Color3") and scfg.Color or K.accent

        local card = mk("TextButton", {
            BackgroundColor3 = K.card, Text = "", AutoButtonColor = false, BorderSizePixel = 0,
            LayoutOrder = nextSide(),
        }, home)
        round(card, 12)
        local cst = outline(card, K.line, 1, 0.35)
        local inner = mk("Frame", {
            AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, 0), Size = UDim2.new(1, -24, 0, 72),
            BackgroundTransparency = 1,
        }, card)
        local tile = mk("Frame", {
            Size = UDim2.fromOffset(36, 36), BackgroundColor3 = tint, BackgroundTransparency = 0.8, BorderSizePixel = 0,
        }, inner)
        round(tile, 10)
        text(tile, { Size = UDim2.fromScale(1, 1), Text = icon, TextSize = 20, TextXAlignment = CENTER })
        text(inner, {
            Position = UDim2.fromOffset(0, 41), Size = UDim2.new(1, 0, 0, 16), Font = FB, TextSize = 14,
            Text = grp.title, TextTruncate = Enum.TextTruncate.AtEnd,
        })
        local sl = text(inner, {
            Position = UDim2.fromOffset(0, 58), Size = UDim2.new(1, 0, 0, 14), TextSize = 11, TextColor3 = K.sub,
            Text = grp.desc, TextTruncate = Enum.TextTruncate.AtEnd,
        })
        -- tanda fitur sedang jalan
        local run = text(card, {
            AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 10), Size = UDim2.fromOffset(0, 18),
            AutomaticSize = AUTO_X, BackgroundColor3 = K.ok, BackgroundTransparency = 0.82, Font = FB, TextSize = 9,
            TextColor3 = K.ok, Text = T("Running", "JALAN"), TextXAlignment = CENTER, Visible = false,
        })
        round(run, 9)
        pad(run, 7, 0, 7, 0)

        local pills = mk("ScrollingFrame", {
            Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false,
            CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.X, ScrollBarThickness = 0,
            ScrollingDirection = Enum.ScrollingDirection.X,
        }, menu)
        mk("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6),
            VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder,
        }, pills)
        grp.card, grp.pills = card, pills

        function grp:_refresh()
            if #self.tabs > 1 then
                local names = {}
                for _, t in ipairs(self.tabs) do names[#names + 1] = t.title end
                sl.Text = table.concat(names, " · ")
            else
                sl.Text = self.desc
            end
        end
        -- on = fitur di menu ini sedang jalan (muncul tanda hijau di ikon)
        function grp:SetActive(on)
            on = on == true
            if self.active == on then return end
            self.active = on
            run.Visible = on
            cst.Color = on and K.ok or K.line
        end
        function grp:Open() end -- (kompatibel dengan versi lama)
        function grp:Tab(tcfg) return Win:_newTab(tcfg, grp) end

        card.MouseEnter:Connect(function()
            tween(card, 0.12, { BackgroundColor3 = K.card2 })
            if not grp.active then cst.Color = K.accent end
        end)
        card.MouseLeave:Connect(function()
            tween(card, 0.12, { BackgroundColor3 = K.card })
            cst.Color = grp.active and K.ok or K.line
        end)
        card.MouseButton1Click:Connect(function() Win:_openGroup(grp) end)

        self._groups[#self._groups + 1] = grp
        regrid()
        return grp
    end

    -- tab tanpa menu: dibuatkan ikon sendiri
    function Win:Tab(tcfg)
        tcfg = tcfg or {}
        local grp = self:Section({ Title = tcfg.Title, Icon = tcfg.Icon })
        return grp:Tab(tcfg)
    end

    backBtn.MouseButton1Click:Connect(function() Win:_select(nil) end)

    search:GetPropertyChangedSignal("Text"):Connect(function()
        Win._query = search.Text
        if Win._active then Win._active:_filter(Win._query) else filterHome() end
    end)

    -- tombol buka / tutup (melayang, bisa digeser)
    local openBtn = mk("TextButton", {
        AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 10), Size = UDim2.fromOffset(0, 36),
        AutomaticSize = AUTO_X, BackgroundColor3 = K.side, Text = "", AutoButtonColor = false,
        BorderSizePixel = 0, ZIndex = 150,
    }, gui)
    round(openBtn, 18)
    outline(openBtn, K.accent, 1, 0.2)
    pad(openBtn, 8, 0, 16, 0)
    mk("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8),
        VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder,
    }, openBtn)
    local ob = badge(openBtn, 22, 12)
    ob.LayoutOrder = 1
    local openLabel = text(openBtn, {
        Size = UDim2.fromOffset(0, 36), AutomaticSize = AUTO_X, Font = FB, TextSize = 13, Text = strOf(cfg.Title),
        LayoutOrder = 2,
    })
    Win._openBtn = openBtn

    function Win:Toggle(v)
        if v == nil then v = not main.Visible end
        closeOpen()
        self.Visible = v
        if v then
            main.Visible = true
            scale.Scale = 0.94
            tween(scale, 0.18, { Scale = 1 })
        else
            main.Visible = false
        end
    end
    function Win:Open() self:Toggle(true) end
    function Win:Close() self:Toggle(false) end

    makeDraggable(openBtn, openBtn, 6, function() Win:Toggle() end)
    minBtn.MouseButton1Click:Connect(function() Win:Toggle(false) end)

    function Win:EditOpenButton(o)
        o = o or {}
        if o.Title then openLabel.Text = strOf(o.Title) end
        if o.OnlyMobile ~= nil then
            openBtn.Visible = (not o.OnlyMobile) or UIS.TouchEnabled
        end
    end

    function Win:SetToggleKey(k) self.ToggleKey = k end

    track(UIS.InputBegan:Connect(function(input)
        if Win.ToggleKey and input.KeyCode == Win.ToggleKey and not UIS:GetFocusedTextBox() then
            Win:Toggle()
        end
    end))

    function Win:Destroy()
        closeOpen()
        for _, c in ipairs(Lib._conns) do pcall(function() c:Disconnect() end) end
        Lib._conns = {}
        for _, g in ipairs(Lib._guis) do pcall(function() g:Destroy() end) end
        Lib._guis = {}
        toastHolder = nil
    end

    -- layar berubah ukuran (rotasi HP): jaga window tetap muat
    if cam then
        track(cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            local v = cam.ViewportSize
            curW = math.clamp(W, 340, math.max(340, v.X - 24))
            curH = math.clamp(H, 260, math.max(260, v.Y - 24))
            main.Size = UDim2.fromOffset(curW, curH)
            regrid()
        end))
    end

    Win:Toggle(true)
    return Win
end

return Lib
end)()
-- LOGO: isi dengan ID aset Roblox (contoh "rbxassetid://123456789" atau "123456789") atau link gambar png/jpg.
-- Kosong = pakai huruf S.
WindUI.Logo = "https://raw.githubusercontent.com/Mizoree-ux/UI/main/file_00000000f794820797aa0933609c9c7c.png"

---------------------------------------------------------------------
-- PENGATURAN & DATA
---------------------------------------------------------------------
local State = {
    Running = false,
    Mode = "Place + Break",       -- "Place + Break" | "Break saja" | "Place saja"
    PlaceMs = 250,                -- jeda setelah tiap place
    BreakMs = 220,                -- jeda tiap pukulan (normal 220)
    AfterBreakMs = 300,           -- jeda setelah block hancur
    HitsOverride = 0,             -- jumlah pukulan manual (0 = otomatis)
    BreakBackground = true,       -- selalu ikut pecah background (tanpa tombol)
    MultiTarget = 1,              -- jumlah tile dipukul bergantian (1 = biasa)
    Fast = true,                  -- Break Cepat: jadwal pukulan tanpa drift, tanpa jeda setelah hancur
    NextHitAt = 0,                -- waktu (os.clock) pukulan berikutnya boleh dikirim
    SelectedId = nil,
    Offsets = {},                 -- tile yang dipilih di Grid
    CalibX = 0,
    CalibY = 0,
    AntiAfk = true,
    Role = "none",                -- title/role yang dipakai (menu Staff)
    MutePunch = true,
    Visual = true,                -- animasi tangan saat break / place / tanam / panen (tampilan saja)
    LiteMode = false,
    AutoCollect = true,           -- ambil drop di tile yang dipilih
    CollectAround = false,        -- ambil drop di sekitar karakter (radius) kapan saja
    CollectRadius = 3,            -- jari-jari collect (tile), dipakai mode Remote
    CollectAuto = true,           -- Otomatis: pakai Remote kalau server menerima, kalau ditolak pindah ke Sentuhan
    CollectMode = "Sentuhan",     -- "Sentuhan" (badan, seperti main manual) / "Remote" (ambil dari jauh, cara lama)
                                  -- / "Jemput" (Sentuhan + karakter jalan sendiri mendatangi drop di sekitar)
    RemoteReach = 2,              -- jarak maksimal permintaan Remote ke server (tile). Di atas ini = ditolak server
    RemoteChase = true,           -- drop di luar RemoteReach (tapi dalam radius) dijemput dengan berjalan
    Override = nil,               -- Pabrik memakai tile & block sendiri
    Quiet = false,                -- tanpa notifikasi (dipakai Pabrik)
    Cycles = 0,
    Placed = 0,
    Broken = 0,
    Collected = 0,                -- jumlah drop yang diambil
    CollectFail = 0,              -- jumlah drop yang ditolak server
    LastAction = "-",
    SeedDrop = false,             -- seed hasil break sudah banyak -> drop ke titik drop
    AutoRefill = true,            -- block habis -> ambil block di sekitar
    RefillRadius = 10,            -- jarak cari block (tile)
    AutoReturn = true,            -- balik ke posisi farm setelah refill / bergeser
    Home = nil,                   -- posisi farm {x,y}
    SeedDropAt = 190,             -- drop kalau seed sudah sebanyak ini
    SeedKeep = 0,                 -- seed yang disisakan
    Dropped = 0,
    DropPause = false,            -- Auto Farm dijeda sementara (sedang pergi drop)
}

local Misc = {
    Speed = 100,      -- walkspeed % (100 = normal)
    InfJump = false,
    Ghost = false,    -- fly + tembus block
    UpHeld = false,   -- tombol ▲ di layar ditahan
    DownHeld = false, -- tombol ▼ di layar ditahan
    CustomName = true,          -- watermark nama (selalu aktif, mati hanya saat script ditutup)
    NameText = "@SkyP",  -- teks watermark
}

-- Auto Clear World
local Clear = {
    Running = false,
    IncludeBg = true,         -- ikut pecah background
    UseBlock = true,          -- taruh block kalau tidak ada pijakan
    ScaffoldId = nil,         -- block yang dipakai untuk pijakan
    Collect = true,           -- ambil drop tiap habis pecah
    Sweep = "Kiri → Kanan",   -- "Kiri → Kanan" atau "Zig-zag"
    Skip = {},                -- tile yang dilewati sementara
    TopRow = -1,              -- baris yang sedang dibersihkan
    DirRow = nil,             -- arah zig-zag untuk baris ini
    Dir = nil,
    Broken = 0,
    Remaining = -1,
    Status = "-",
}

-- Auto Splice: tanam Seed A lalu splice Seed B
local Splice = {
    Running = false,
    Roam = true,        -- keliling world pakai A* (false = hanya tile Grid)
    Roaming = false,
    A = nil,
    B = nil,
    Ms = 300,
    Made = 0,
    Planted = 0,
    Fail = {},
    Skip = {},
    Status = "-",
    Row = {},           -- baris yang sedang dikerjakan (rapi per baris)
}

-- Vending: isi stock dari drop / kosongkan sampai habis
local Vend = {
    Running = false,
    Mode = "Isi stock dari drop",  -- atau "Kosongkan sampai habis"
    Point = "",                    -- titik drop vending: "WORLD" / "WORLD:ID" (kosong = world ini)
    Status = "-",
    Stocked = 0, Taken = 0, Dropped = 0,
    Picked = {},                   -- [id] = jumlah hasil pungut yang belum masuk vending
    Items = {},                    -- item yang boleh diambil / di-stock / dikosongkan (kosong = semua)
    Kind = "Semua",                -- "Semua" / "Block saja" / "Seed saja"
    Seen = {},                     -- item yang pernah terlihat (vending, tas, drop) untuk daftar pilihan
    DropX = -1, DropY = -1,        -- posisi berdiri di titik drop vending (-1 = titik kedatangan)
    Carry = {},                    -- [id] = jumlah yang diambil dari vending (mode kosongkan)
}

-- Pabrik: panen + tanam mengikuti rute lantai pilihan -> break -> tunggu, seed lebihan di-drop
local Pabrik = {
    Running = false,
    SeedId = nil,
    BlockId = nil,
    Tiles = {},          -- tile break, relatif ke titik break ("dx,dy"), milik world aktif
    BreakX = -1, BreakY = -1, -- titik berdiri saat break (-1 = otomatis), milik world aktif
    Breaks = {},         -- [NAMA_WORLD] = { x, y, tiles } : titik & tile break tersimpan per world
    Drop = true,
    Keep = 50,           -- seed yang disisakan untuk ditanam lagi
    DropAt = 200,        -- drop kalau seed sudah sebanyak ini
    DropWorld = "",      -- "" = world ini | "WORLD" | "WORLD:ID"
    DropX = -1, DropY = -1,
    Harvested = 0,
    Planted = 0,
    Dropped = 0,
    Skip = {},
    Status = "-",
    Traveling = false,
    Home = "",
    Zone = nil,          -- tempat drop (tidak ikut di-collect), dipakai semua fitur drop
    Fast = true,         -- pakai Break Cepat saat break
    Route = {},          -- rute tetap: daftar titik berdiri { x, y, lo, hi, key }
    Bad = {},            -- ["x,y"] = waktu: titik berdiri yang tidak terjangkau (merah di peta)
    BreakBad = {},       -- ["x,y"] = true: titik break yang gagal dipakai (sesi ini)
    PlantN = {},         -- [idx] = berapa kali ditanam tanpa pernah dipanen (deteksi ditolak server)
    Pick = {},           -- ["y,x0,x1"] = true : lantai world yang dipilih di peta, milik world aktif
    Picks = {},          -- [NAMA_WORLD] = Pick : pilihan tile tersimpan per world
    PickWorld = "",      -- world pemilik Pabrik.Pick sekarang
    Detail = false,      -- status pabrik: tampilkan detail (mati = 1 baris ringkas)
    Order = "Atas ke bawah", -- urutan rute: "Atas ke bawah" | "Bawah ke atas" | "Terdekat dulu"
    Full = false,        -- Full world: semua lantai world dipakai, tidak perlu memilih di peta
    FullPick = {},       -- (Full world) hasil pindai: ["y,x0,x1"] = true
    FullWorld = "",      -- world pemilik FullPick
    FullAt = 0,          -- kapan FullPick terakhir dipindai
    ReadyPct = 70,       -- panen dimulai kalau pohon siap sudah segini persen
}

local Guard = {
    On = false,
    Who = "Staff (Mod/Dev)",   -- "Staff (Mod/Dev)" | "Semua pemain"
    StopAll = true,            -- diam semua aktivitas
    Leave = false,             -- keluar world
    AutoBack = true,           -- lanjut lagi setelah aman
    BackSec = 60,              -- (keluar world) tunggu sebelum masuk lagi
    CalmSec = 5,               -- (diam) tunggu sepi dulu sebelum lanjut
    Mode = "idle",             -- idle | pause | away | out | back
    Allow = {},                -- pemain biasa yang sudah ada saat Penjaga dinyalakan (diabaikan)
    Alerted = {},              -- sudah diberi peringatan
    Saved = nil,               -- aktivitas sebelum dihentikan
    Token = 0,
    BackAt = 0,
    CalmAt = nil,
    LeftFg = nil,
    BackText = nil,
    Status = "Mati",
    Detected = 0,
    -- Keamanan tambahan (jalan walau Penjaga mati)
    JitOn = false, JitPct = 15,                  -- jeda acak: tiap jeda aksi ditambah 0..JitPct persen
    RestOn = false, RestEvery = 45, RestFor = 3, -- istirahat berkala (menit jalan / menit istirahat, diacak ±20%)
    MaxOn = false, MaxHours = 6,                 -- batas waktu jalan: semua aktivitas berhenti setelah sekian jam
    ActiveSec = 0, SinceRest = 0,                -- lama aktivitas jalan (total / sejak istirahat terakhir)
}

-- Jeda acak: hanya MENAMBAH jeda (tidak pernah lebih cepat dari batas server)
function Guard.jit(ms)
    if not Guard.JitOn then return ms end
    return ms * (1 + math.random() * math.clamp(tonumber(Guard.JitPct) or 15, 0, 60) / 100)
end

-- Farmer: panen & tanam otomatis
local Farmer = {
    Running = false,
    Harvest = true,
    Plant = true,
    Collect = true,
    UseBlock = false,   -- taruh block kalau tidak ada jalan
    ScaffoldId = nil,
    HarvestMs = 250,    -- jeda setelah tiap panen
    PlantMs = 250,      -- jeda setelah tiap tanam
    SeedId = nil,
    Skip = {},
    Harvested = 0,
    Planted = 0,
    Status = "-",
    Drop = false,       -- inventori hampir penuh -> drop hasil panen ke titik drop
    DropAt = 190,       -- drop kalau item hasil panen sudah sebanyak ini
    Keep = 50,          -- seed tanam yang disisakan
    Dropped = 0,
    Got = {},           -- seed pohon yang pernah dipanen (untuk cari item hasil panen)
    Row = {},           -- baris tanam yang sedang dikerjakan (tanam rapi per baris)
}

-- Tombol gerak buatan (dipakai Clear & Farmer)
local AutoInput = { active = false, left = false, right = false, jump = false, down = false }

-- Auto Chat
local Spam = {
    On = false,
    Texts = {},         -- daftar pesan, dikirim bergantian
    IntervalSec = 6,
    Index = 1,
    Sent = 0,
    Last = "-",
}

local Refs = {
    World = nil,      -- data world (fg, bg, ukuran)
    Inv = nil,        -- inventori
    SetTile = nil,    -- fungsi place game
    State = nil,      -- posisi karakter
    Punch = nil,      -- fungsi pukul game
    Particles = {},   -- particle (untuk mode Lite)
    Menu = nil,       -- menu game (keluar / masuk world)
    Gems = nil,       -- update angka gems
    Hud = nil,        -- jangkauan pukul & place
    Trees = nil,      -- data pohon (waktu tanam)
    Others = nil,     -- daftar pemain lain di world (untuk Penjaga)
}

-- Daftar drop di world (diambil dari game)
local Drops = { list = nil, update = nil, brokeAt = {} }
-- Animasi aksi: fungsi gambar tangan game + nomor upvalue "aksi terakhir" (diisi saat hubungkan)
local Anim = { fn = nil, idx = nil, set = nil }
local DropFailUntil = {}   -- drop yang ditolak, dicoba lagi nanti

local UI = {}

-- Jalankan fn dengan izin penuh. Hasil: ok, err (seperti pcall)
function UI.ident()
    local getId = getthreadidentity or get_thread_identity or getidentity or (syn and syn.get_thread_identity)
    if type(getId) ~= "function" then return nil end
    local ok, v = pcall(getId)
    return ok and v or nil
end
function UI.exec(fn)
    local setId = setthreadidentity or set_thread_identity or setidentity or (syn and syn.set_thread_identity)
    local function elevate()
        if Session.Ident and type(setId) == "function" then pcall(setId, Session.Ident) end
    end
    local err1 = nil
    local co = Session.Exec
    if co and coroutine.status(co) == "suspended" then
        local okR, ok, err = coroutine.resume(co, function()
            elevate()
            fn()
        end)
        if okR and ok ~= false then return true end
        err1 = okR and err or ok
    end
    -- cadangan: jalankan di thread ini (setelah identitasnya dikembalikan)
    elevate()
    local ok2, err2 = pcall(fn)
    if ok2 then return true end
    return false, tostring(err2 or err1)
end
UI.Jobs = {}
function UI.later(key, fn, delay)
    UI.Jobs[key] = { fn = fn, at = os.clock() + (delay or 0) }
end
-- Jalankan pekerjaan UI yang sudah waktunya (dipanggil oleh thread INIT, lihat bagian INIT)
function UI.runJobs()
    local now = os.clock()
    local due = {}
    for key, job in pairs(UI.Jobs) do
        if now >= job.at then due[#due + 1] = key end
    end
    for _, key in ipairs(due) do
        local job = UI.Jobs[key]
        if job and now >= job.at then
            UI.Jobs[key] = nil
            local ok, err = pcall(job.fn)
            if not ok then warn("[SkyP] UI job " .. tostring(key) .. ": " .. tostring(err)) end
        end
    end
end
local Connections = {}
local HitCount = {}   -- hitung pukulan (cadangan)
local PlacedAt = {}   -- kapan tile di-place

---------------------------------------------------------------------
-- BAHASA (Indonesia / English)
---------------------------------------------------------------------
-- Cara kerja:
--   - Semua teks script ditulis dalam Bahasa Indonesia.
--   - Kalau English dipilih, I18N.T(teks) menerjemahkan:
--       1. teks utuh (judul & deskripsi menu) dari daftar EN
--       2. teks yang berubah-ubah (status, notifikasi) per frasa dari daftar PH
--   - Menu WindUI dibungkus (I18N.wrap) supaya judul, deskripsi & isi status ikut diterjemahkan.
local I18N = { Lang = "id", Saved = "id", Ask = false }
function I18N.T(s) return s end
function I18N.V(s) return s end
function I18N.wrap(o) return o end

local function notify(title, content, dur)
    task.defer(function()
        pcall(function()
            WindUI:Notify({ Title = I18N.T(title), Content = I18N.T(content), Duration = dur or 3, Icon = "info" })
        end)
    end)
end

---------------------------------------------------------------------
-- CONFIG: simpan & muat pengaturan otomatis
---------------------------------------------------------------------
-- Cara kerja:
--   1. Saat execute, file config dibaca lalu nilainya dipasang ke pengaturan
--      SEBELUM UI dibuat, jadi tombol & slider langsung tampil sesuai config.
--   2. Tiap 3 detik pengaturan sekarang dibandingkan dengan yang terakhir disimpan.
--      Ada yang berubah -> langsung disimpan (auto save).
--   3. File per akun: workspace/Alfian/config_<UserId>.json
--   Yang tidak disimpan: tombol jalan (Auto Farm / Clear / Farmer / Chat), fly & inf jump.
local Config = {
    AutoSave = true,
    Paused = false,      -- true setelah reset (supaya file tidak dibuat lagi)
    Folder = "Alfian",
    Data = {},           -- isi file saat execute
    List = {},           -- tabel pengaturan yang disimpan
    LastJson = nil,
    Status = "-",
}

do (function() -- fungsi sendiri: variabel di dalam tidak ikut batas 200 local
    local HttpService = game:GetService("HttpService")
    local canFile = type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
    Config.CanFile = canFile
    Config.Path = Config.Folder .. "/config_" .. tostring(LocalPlayer.UserId) .. ".json"

    local function read()
        if not canFile then return nil end
        local okE, exists = pcall(isfile, Config.Path)
        if not okE or not exists then return nil end
        local okR, raw = pcall(readfile, Config.Path)
        if not okR or type(raw) ~= "string" then return nil end
        local okD, data = pcall(HttpService.JSONDecode, HttpService, raw)
        if okD and type(data) == "table" then return data end
        return nil
    end

    local loaded = read()
    Config.Found = loaded ~= nil
    Config.Data = loaded or {}
    if Config.Data.AutoSave == false then Config.AutoSave = false end
    Config.Status = Config.Found and "Config dimuat" or (canFile and "Belum ada config" or "Executor tidak bisa simpan file")

    -- Daftarkan tabel pengaturan. Nilai dari file langsung dipasang
    -- (kecuali key di 'later', dipasang sendiri setelah terhubung ke game).
    function Config.add(name, tbl, keys, later)
        table.insert(Config.List, { name = name, tbl = tbl, keys = keys })
        local saved = Config.Data[name]
        if type(saved) ~= "table" then return end
        for _, k in ipairs(keys) do
            local v, cur = saved[k], tbl[k]
            if v ~= nil and not (later and later[k]) and (cur == nil or type(v) == type(cur)) then
                tbl[k] = v
            end
        end
    end

    function Config.saved(name, key)
        local t = Config.Data[name]
        return type(t) == "table" and t[key] or nil
    end

    local function collect()
        local out = { AutoSave = Config.AutoSave, Version = 1 }
        for _, e in ipairs(Config.List) do
            local t = {}
            for _, k in ipairs(e.keys) do t[k] = e.tbl[k] end
            out[e.name] = t
        end
        return out
    end

    function Config.save(force)
        if not canFile then
            Config.Status = "Executor tidak bisa simpan file"
            return false
        end
        if Config.Paused and not force then return false end
        local okJ, json = pcall(HttpService.JSONEncode, HttpService, collect())
        if not okJ then
            Config.Status = "Gagal membaca pengaturan"
            return false
        end
        if not force and json == Config.LastJson then return true end
        if type(isfolder) == "function" and type(makefolder) == "function" then
            local okF, has = pcall(isfolder, Config.Folder)
            if okF and not has then pcall(makefolder, Config.Folder) end
        end
        local ok = pcall(writefile, Config.Path, json)
        if ok then
            Config.LastJson = json
            Config.Paused = false
            Config.Status = "Tersimpan " .. os.date("%H:%M:%S")
        else
            Config.Status = "Gagal simpan file"
        end
        return ok
    end

    -- Hapus file config (execute ulang = kembali ke default)
    function Config.reset()
        Config.Paused = true
        Config.LastJson = nil
        if canFile and type(delfile) == "function" then
            local ok = pcall(delfile, Config.Path)
            Config.Status = ok and "Config dihapus. Execute ulang untuk default" or "Gagal hapus file"
            return ok
        end
        Config.Status = "Executor tidak bisa hapus file"
        return false
    end

    function Config.start()
        -- tandai kondisi sekarang sebagai "sudah tersimpan" kalau sama dengan file
        if Config.Found then
            local okJ, json = pcall(HttpService.JSONEncode, HttpService, collect())
            if okJ then Config.LastJson = json end
        end
        task.spawn(function()
            while alive() do
                task.wait(3)
                if Config.AutoSave and alive() then Config.save(false) end
            end
        end)
    end
end)() end

Config.add("Farm", State, {
    "Mode", "PlaceMs", "BreakMs", "AfterBreakMs", "HitsOverride", "SelectedId", "Offsets",
    "CalibX", "CalibY", "AntiAfk", "MutePunch", "Visual", "LiteMode", "AutoCollect", "MultiTarget", "Fast",
    "CollectAround", "CollectRadius", "CollectMode", "RemoteReach", "RemoteChase", "CollectAuto",
    "SeedDrop", "SeedDropAt", "SeedKeep", "AutoRefill", "RefillRadius", "AutoReturn",
})
Config.add("Clear", Clear, { "UseBlock", "ScaffoldId", "Collect", "Sweep" })
Config.add("Farmer", Farmer, {
    "Harvest", "Plant", "Collect", "UseBlock", "ScaffoldId", "HarvestMs", "PlantMs", "SeedId",
})
-- update 1084: game memberi jeda minimal antar aksi (place ~0.135 dtk, pukul ~0.19 dtk)
State.PlaceMs = math.max(State.PlaceMs, 140)
State.BreakMs = math.max(State.BreakMs, 200)
Farmer.HarvestMs = math.max(Farmer.HarvestMs, 140)
Farmer.PlantMs = math.max(Farmer.PlantMs, 140)
Config.add("Misc", Misc, { "Speed" })
Config.add("Chat", Spam, { "Texts", "IntervalSec" })
Config.add("Vending", Vend, { "Mode", "Point", "Items", "DropX", "DropY" })
Config.add("Pabrik", Pabrik, {
    "SeedId", "Tiles", "BreakX", "BreakY", "Breaks",
    "Drop", "Keep", "DropAt", "DropWorld", "DropX", "DropY",
    "Fast", "Picks", "Detail", "Order", "Full", "ReadyPct",
})
Pabrik.ORDERS = { "Atas ke bawah", "Bawah ke atas", "Terdekat dulu" }
if not table.find(Pabrik.ORDERS, Pabrik.Order) then Pabrik.Order = "Atas ke bawah" end -- config rusak / lama
Pabrik.Full = Pabrik.Full == true
Pabrik.ReadyPct = math.clamp(tonumber(Pabrik.ReadyPct) or 70, 10, 100)
if Config.saved("Pabrik", "SmartFast") == false and Config.saved("Pabrik", "Fast") == nil then Pabrik.Fast = false end -- config lama
do -- config lama: 1 pilihan tile untuk semua world -> dipindah ke world pertama yang cocok (lihat Pabrik.syncPick)
    local old = Config.saved("Pabrik", "Pick")
    if type(old) == "table" and next(old) ~= nil and next(Pabrik.Picks) == nil then Pabrik.LegacyPick = old end
end

---------------------------------------------------------------------
-- STATISTIK SESI & NOTIFIKASI DISCORD (data; tampilan ada di tab Statistik / Discord)
---------------------------------------------------------------------
local Stats = { T0 = os.clock(), Gems0 = nil, Items = {}, Base = {} }

-- Cara kerja webhook:
--   Hook.send(jenis, teks) memasukkan pesan ke antrian.
--   Antrian dikirim satu per satu tiap 2.5 detik (supaya tidak kena batas Discord).
local Hook = {
    On = false,
    Url = "",
    Penjaga = true,   -- mod / dev / pemain masuk world
    Stop = true,      -- aktivitas berhenti (block habis, error)
    Full = true,      -- inventori penuh
    Bonus = true,     -- quest diklaim / redeem berhasil
    Rejoin = true,    -- terlempar / masuk lagi
    Pabrik = true,    -- pabrik drop / berhenti
    ReportMin = 0,    -- laporan statistik tiap X menit (0 = mati)
    Queue = {},
    LastFull = {},
    Status = "-",
}

do (function()
    local HttpService = game:GetService("HttpService")

    local function requester()
        return (syn and syn.request) or (http and http.request) or http_request or request
            or (fluxus and fluxus.request)
    end

    function Hook.valid(url)
        url = tostring(url or "")
        for _, host in ipairs({ "discord.com", "discordapp.com", "ptb.discord.com", "canary.discord.com" }) do
            if string.sub(url, 1, #host + 22) == "https://" .. host .. "/api/webhooks/" then return true end
        end
        return false
    end

    -- jenis: "penjaga" | "stop" | "full" | "bonus" | "rejoin" | "report" | "test"
    function Hook.send(kind, text)
        if kind == "rejoin" and Hook.onRejoin then pcall(Hook.onRejoin, text) end -- webhook khusus rejoin
        if not Hook.On or not Hook.valid(Hook.Url) then return end
        local allow = kind == "test" or kind == "report"
            or (kind == "penjaga" and Hook.Penjaga) or (kind == "stop" and Hook.Stop)
            or (kind == "full" and Hook.Full) or (kind == "bonus" and Hook.Bonus)
            or (kind == "rejoin" and Hook.Rejoin) or (kind == "pabrik" and Hook.Pabrik)
        if not allow or #Hook.Queue >= 20 then return end
        table.insert(Hook.Queue, I18N.T(tostring(text)))
    end

    task.spawn(function()
        while alive() do
            local text = table.remove(Hook.Queue, 1)
            if not text then
                task.wait(0.5)
            else
                local req = requester()
                if not req then
                    Hook.Status = "Executor tidak punya fungsi request"
                else
                    local body = HttpService:JSONEncode({
                        username = "SkyP",
                        content = ("**[%s]** %s"):format(LocalPlayer.Name, text),
                    })
                    local ok, res = pcall(req, {
                        Url = Hook.Url, Method = "POST",
                        Headers = { ["Content-Type"] = "application/json" }, Body = body,
                    })
                    local code = ok and type(res) == "table" and tonumber(res.StatusCode or res.Status) or nil
                    if ok and (code == nil or code < 300) then
                        Hook.Status = "Terkirim " .. os.date("%H:%M:%S")
                    else
                        Hook.Status = "Gagal kirim (" .. tostring(code or res) .. ")"
                    end
                end
                task.wait(2.5)
            end
        end
    end)
end)() end

---------------------------------------------------------------------
-- CARI DATA & FUNGSI GAME (getgc)
---------------------------------------------------------------------
local getconsts = (debug and debug.getconstants) or getconstants

-- Fungsi place game: satu-satunya yang memakai "placedAt" + "flips" sekaligus.
-- Kirimnya "tile" (game baru, ByteNet) atau "SetTile" (game lama).
local function isSetTileFn(fn)
    if not getconsts then return false end
    if islclosure and not islclosure(fn) then return false end
    local ok, consts = pcall(getconsts, fn)
    if not ok or type(consts) ~= "table" then return false end
    local hasSend, hasPlaced, hasFlips = false, false, false
    for _, c in pairs(consts) do
        if c == "tile" or c == "SetTile" then hasSend = true
        elseif c == "placedAt" then hasPlaced = true
        elseif c == "flips" then hasFlips = true end
    end
    return hasSend and hasPlaced and hasFlips
end

-- Fungsi pukul game: teks "Empty the Vending Machine first!" + "newCrack"
-- (game lama: "HarvestProvider")
local function isPunchFn(fn)
    if not getconsts then return false end
    if islclosure and not islclosure(fn) then return false end
    local ok, consts = pcall(getconsts, fn)
    if not ok or type(consts) ~= "table" then return false end
    local hasVend, hasMark = false, false
    for _, c in pairs(consts) do
        if c == "Empty the Vending Machine first!" then hasVend = true
        elseif c == "newCrack" or c == "HarvestProvider" then hasMark = true end
    end
    return hasVend and hasMark
end

-- Fungsi game yang menggambar tangan karakter saat memukul / memasang
function Anim.isArmFn(fn)
    if not getconsts then return false end
    if islclosure and not islclosure(fn) then return false end
    local ok, consts = pcall(getconsts, fn)
    if not ok or type(consts) ~= "table" then return false end
    local a, b, c = false, false, false
    for _, k in pairs(consts) do
        if k == "forearm" then a = true
        elseif k == "heldReach" then b = true
        elseif k == "punchReach" then c = true end
    end
    return a and b and c
end

-- Cari nomor upvalue "aksi terakhir" (tabel {t, x, y, facing} atau nil) di fungsi tangan.
-- Upvalue ini dipakai bersama oleh kode input & gambar karakter game, jadi cukup diganti sekali.
function Anim.bind(fn)
    local gu = (debug and debug.getupvalue) or getupvalue
    local su = (debug and debug.setupvalue) or setupvalue
    if not (gu and su) then return false end
    local vals, last = {}, 0
    for i = 1, 16 do
        local ok, v = pcall(gu, fn, i)
        if not ok then break end
        vals[i] = v
        if v ~= nil then last = i end
    end
    for i = 1, last - 1 do
        local v = vals[i]
        if v == nil or (type(v) == "table" and rawget(v, "t") ~= nil and rawget(v, "facing") ~= nil) then
            Anim.fn, Anim.idx, Anim.set = fn, i, su
            return true
        end
    end
    return false
end

local function isStateHolder(v)
    local fn = rawget(v, "state")
    if type(fn) ~= "function" then return false end
    local ok, s = pcall(fn)
    return ok and type(s) == "table" and type(s.x) == "number" and type(s.y) == "number"
        and s.facing ~= nil and s.vx ~= nil
end

-- Pastikan fungsi milik game, bukan milik script ini
local function isGameFn(fn)
    if fn == isSetTileFn or fn == isPunchFn then return false end
    if isexecutorclosure then
        local ok, res = pcall(isexecutorclosure, fn)
        if ok and res then return false end
    end
    -- update game: nama script diacak (bukan lagi "GameGui"), jadi syarat nama dibuang.
    -- Fungsi milik script ini sudah tersaring lewat isexecutorclosure di atas; di sini cukup buang kode inti Roblox.
    local ok, src = pcall(debug.info, fn, "s")
    if ok and type(src) == "string"
        and (string.find(src, "CoreGui", 1, true) or string.find(src, "CorePackages", 1, true)) then
        return false
    end
    return true
end

local function findRefs()
    Refs.World, Refs.Inv, Refs.SetTile, Refs.State, Refs.Punch, Refs.Menu = nil, nil, nil, nil, nil, nil
    Refs.Gems = nil
    Refs.Hud = nil
    Refs.Others = nil
    Refs.Arm = nil
    Refs.Particles = {}
    Anim.Particles = nil
    if not getgc then
        return false, "Executor tidak punya getgc()"
    end
    local invLoose, punchLoose = nil, nil -- cadangan kalau game update mengubah ciri lama
    for gi, v in ipairs(getgc(true)) do
        if gi % 3000 == 0 then task.wait() end -- jeda berkala seperti versi Sky lama (anti freeze)
        local tv = type(v)
        if tv == "table" then
            if not Refs.World then
                local ok, isWorld = pcall(function()
                    return type(rawget(v, "fg")) == "table" and type(rawget(v, "bg")) == "table"
                        and type(rawget(v, "w")) == "number" and type(rawget(v, "h")) == "number"
                        and rawget(v, "spawn") ~= nil
                end)
                if ok and isWorld then Refs.World = v end
            end
            if not Refs.Inv then
                local ok, isInv = pcall(function()
                    return getmetatable(v) == InventoryModule and type(rawget(v, "slots")) == "table"
                        and rawget(v, "capacity") ~= nil
                end)
                if ok and isInv then Refs.Inv = v end
            end
            if not Refs.Inv and not invLoose then
                local ok, isLoose = pcall(function()
                    return type(rawget(v, "slots")) == "table" and type(v.count) == "function"
                        and type(v.room) == "function" and type(v.add) == "function" and type(v.remove) == "function"
                end)
                if ok and isLoose then invLoose = v end
            end
            if not Refs.State then
                local ok, isHolder = pcall(isStateHolder, v)
                if ok and isHolder then Refs.State = rawget(v, "state") end
            end
            if not Refs.Menu then
                local ok, isMenu = pcall(function()
                    return type(rawget(v, "openBackpack")) == "function" and type(rawget(v, "ui")) == "table"
                end)
                if ok and isMenu then Refs.Menu = v end
            end
            if not Refs.Gems then
                local ok, isG = pcall(function() return type(rawget(v, "addGems")) == "function" end)
                if ok and isG then Refs.Gems = v end
            end
            if not Refs.Hud then
                local ok, isH = pcall(function()
                    return type(rawget(v, "punchRange")) == "function" and type(rawget(v, "handPower")) == "function"
                end)
                if ok and isH then Refs.Hud = v end
            end
            if not Refs.Others then
                -- data pemain lain: punya list(), where(), playerAt()
                local ok, isO = pcall(function()
                    return type(rawget(v, "list")) == "function" and type(rawget(v, "where")) == "function"
                        and type(rawget(v, "playerAt")) == "function"
                end)
                if ok and isO then Refs.Others = v end
            end
            if ParticlesOk then
                local ok, isP = pcall(function()
                    return getmetatable(v) == ParticlesModule and type(rawget(v, "live")) == "table"
                        and type(rawget(v, "free")) == "table"
                end)
                if ok and isP then table.insert(Refs.Particles, v) end
            end
        elseif tv == "function" and (not Refs.SetTile or not Refs.Punch) and isGameFn(v) then
            if not Refs.SetTile and isSetTileFn(v) then
                Refs.SetTile = v
            elseif not Refs.Punch and isPunchFn(v) then
                Refs.Punch = v
            elseif not Refs.Punch and not punchLoose and Misc.isPunchLoose(v) then
                punchLoose = v
            end
        end
        if Refs.World and Refs.Inv and Refs.SetTile and Refs.State and Refs.Punch
            and Refs.Menu and Refs.Gems and Refs.Hud and Refs.Others then break end
    end
    if not Refs.Inv and invLoose then Refs.Inv = invLoose end
    if not Refs.Punch and punchLoose then Refs.Punch = punchLoose end
    return Refs.World ~= nil
end

-- Cadangan: fungsi pukul = punya teks "Empty the Vending Machine first!" saja
function Misc.isPunchLoose(fn)
    if not getconsts then return false end
    if islclosure and not islclosure(fn) then return false end
    local ok, consts = pcall(getconsts, fn)
    if not ok or type(consts) ~= "table" then return false end
    for _, c in pairs(consts) do
        if c == "Empty the Vending Machine first!" then return true end
    end
    return false
end

local function refsText()
    return "World: " .. (Refs.World and "OK" or "TIDAK")
        .. " | Inventori: " .. (Refs.Inv and "OK" or "TIDAK")
        .. " | setTile: " .. (Refs.SetTile and "OK" or "cadangan")
        .. " | Posisi: " .. (Refs.State and "OK" or "cadangan")
        .. " | Pukul: " .. (Refs.Punch and "OK" or "TIDAK")
        .. " | Drop: " .. (Drops.list and "OK" or "TIDAK")
        .. " | Pohon: " .. (Refs.Trees and "OK" or "TIDAK")
        .. " | Pemain: " .. (Refs.Others and "OK" or "TIDAK")
        .. " | Animasi: " .. (Anim.fn and "OK" or "TIDAK")
        .. " | Dropdown: " .. (UI.DropErr and ("ERROR " .. tostring(UI.DropErr)) or (UI.DropOk and "OK" or "-"))
end
Session.refsText = refsText

---------------------------------------------------------------------
-- ITEM & INVENTORI
---------------------------------------------------------------------
local function itemName(id)
    local it = ItemDB[id]
    return (it and it.name) or ("Item #" .. tostring(id))
end

local function invCount(id)
    if not Refs.Inv then return 0 end
    local ok, n = pcall(function() return Refs.Inv:count(id) end)
    return ok and n or 0
end

-- PATCH: baca slot tas apa pun bentuknya (bolong / map / nama field beda)
function UI.invSlotIds()
    local out, seen = {}, {}
    local inv = Refs.Inv
    if not inv then return out end
    local okS, slots = pcall(function() return inv.slots end)
    if not okS or type(slots) ~= "table" then return out end
    for k, slot in pairs(slots) do
        local id, n
        if type(slot) == "table" then
            id = tonumber(slot.id or slot.item or slot.itemId or slot[1])
            n = tonumber(slot.n or slot.count or slot.amount or slot.qty or slot[2])
        elseif type(slot) == "number" and type(k) == "number" then
            id, n = k, slot -- bentuk map: [id] = jumlah
        end
        if id and id ~= 0 and not seen[id] then
            if n == nil then n = invCount(id) end
            if n > 0 then seen[id] = true; out[#out + 1] = id end
        end
    end
    local miss = false
    for _, id in ipairs(out) do if not rawget(ItemDB, id) then miss = true break end end
    if miss and Session.fixItemDB then pcall(Session.fixItemDB, out) end
    return out
end

local function isPlaceable(id)
    local it = ItemDB[id]
    if not it then return true end -- data item tidak ada: tetap tampilkan di dropdown
    if it.kind == "tool" or it.kind == "cloth" or it.kind == "clothes" or it.kind == "consumable" then
        return false
    end
    if it.lock or it.area then return false end
    return true
end

local function placeableIds()
    local ids = {}
    for _, id in ipairs(UI.invSlotIds()) do
        if isPlaceable(id) then ids[#ids + 1] = id end
    end
    table.sort(ids)
    return ids
end

local function inventoryLabels(ids)
    local out = {}
    for _, id in ipairs(ids or placeableIds()) do
        out[#out + 1] = string.format("%s [%d]", itemName(id), id)
    end
    if #out == 0 then out = { "(inventori kosong / belum terbaca)" } end
    return out
end

-- Dropdown cuma di-refresh kalau jenis item berubah (biar tidak lag)
local lastInvSig = nil
local invRefreshPending = false

local lastSeedSig = nil
local lastBlockSig = nil

-- Seed di inventori (untuk Farmer)
local function seedIds()
    local ids = {}
    for _, id in ipairs(UI.invSlotIds()) do
        local it = ItemDB[id]
        if it and (it.kind == "seed" or (type(it.name) == "string" and it.name:lower():find("seed"))) then
            ids[#ids + 1] = id
        end
    end
    table.sort(ids)
    return ids
end

-- Setelah daftar di-refresh, pilih lagi item yang sedang dipakai (dari config / pilihan lama)
local function selectSaved(dd, labels, id)
    if not dd or not id then return end
    local want = "[" .. tostring(id) .. "]"
    for _, label in ipairs(labels) do
        if string.sub(label, -#want) == want then
            UI.exec(function() dd:Select(label) end)
            return
        end
    end
end

-- Refresh 1 dropdown; error dicatat (tampil di tab Koneksi)
function UI.ddRefresh(dd, labels)
    if not dd then return end
    local ok, err = UI.exec(function() dd:Refresh(labels) end)
    if ok then
        UI.DropOk = os.clock()
    else
        UI.DropErr = ("%s (id %s/%s)"):format(tostring(err), tostring(UI.ident()), tostring(Session.Ident))
        UI.DropErrAt = os.clock()
    end
end

local function doInvRefresh(force)
    UI.DropErr = nil
    if Vend.refreshItems and not Vend.Running then pcall(Vend.refreshItems, false) end
    local ids = placeableIds()
    local sig = table.concat(ids, ",")
    if force or sig ~= lastInvSig then
        lastInvSig = sig
        local labels = inventoryLabels(ids)
        UI.ddRefresh(UI.InvDropdown, labels)
        selectSaved(UI.InvDropdown, labels, State.SelectedId)
    end
    local sids = seedIds()
    local ssig = table.concat(sids, ",")
    if force or ssig ~= lastSeedSig then
        lastSeedSig = ssig
        local labels = {}
        for _, id in ipairs(sids) do
            labels[#labels + 1] = string.format("%s [%d]", itemName(id), id)
        end
        if #labels == 0 then labels = { "(tidak ada seed di inventori)" } end
        UI.ddRefresh(UI.SeedDropdown, labels)
        selectSaved(UI.SeedDropdown, labels, Farmer.SeedId)
        if UI.PabrikSeedDropdown then
            UI.ddRefresh(UI.PabrikSeedDropdown, labels)
            selectSaved(UI.PabrikSeedDropdown, labels, Pabrik.SeedId)
        end
    end
    -- block padat untuk pijakan
    local bids = {}
    for _, id in ipairs(ids) do
        local it = ItemDB[id]
        if it and it.solid and it.kind ~= "seed" then bids[#bids + 1] = id end
    end
    local bsig = table.concat(bids, ",")
    if force or bsig ~= lastBlockSig then
        lastBlockSig = bsig
        local labels = {}
        for _, id in ipairs(bids) do
            labels[#labels + 1] = string.format("%s [%d]", itemName(id), id)
        end
        if #labels == 0 then labels = { "(tidak ada block padat di inventori)" } end
        UI.ddRefresh(UI.ClearBlockDropdown, labels)
        UI.ddRefresh(UI.FarmerBlockDropdown, labels)
        selectSaved(UI.ClearBlockDropdown, labels, Clear.ScaffoldId)
        selectSaved(UI.FarmerBlockDropdown, labels, Farmer.ScaffoldId)
    end
    -- daftar Splice & Tas (dibuat di bagian bawah script)
    if UI.SpliceRefresh then pcall(UI.SpliceRefresh, force) end
    if UI.TrashRefresh then pcall(UI.TrashRefresh, force) end
end

local function refreshInvDropdown(force)
    if force then UI.InvForce = true end
    if not force and invRefreshPending then return end
    invRefreshPending = true
    UI.later("inv", function()
        invRefreshPending = false
        local f = UI.InvForce == true
        UI.InvForce = false
        if alive() then doInvRefresh(f) end
    end, force and 0 or 0.3)
end

local invConn
local function watchInventory()
    if invConn then pcall(function() invConn:Disconnect() end) end
    if Refs.Inv and typeof(Refs.Inv.changed) == "Instance" then
        invConn = Refs.Inv.changed.Event:Connect(function()
            if alive() then refreshInvDropdown(false) end
        end)
        table.insert(Connections, invConn)
    end
end

---------------------------------------------------------------------
-- WORLD: tile & posisi karakter
---------------------------------------------------------------------
local function tileAt(layer, x, y)
    local w = Refs.World
    if not w or x < 0 or y < 0 or x >= w.w or y >= w.h then return nil end
    local grid = w[layer]
    local row = grid and grid[y]
    return row and (row[x] or 0) or nil
end

local function getView()
    local gg = PlayerGui:FindFirstChild("GameGui")
    local cam = gg and gg:FindFirstChild("World") and gg.World:FindFirstChild("Camera")
    local tiles = cam and cam:FindFirstChild("Tiles")
    local pv = cam and cam:FindFirstChild("PlayerView")
    if not (tiles and pv) then return nil end
    local sample = tiles:FindFirstChildWhichIsA("ImageLabel")
    if not sample or sample.AbsoluteSize.X <= 0 then return nil end
    return { tiles = tiles, pv = pv, ts = sample.AbsoluteSize.X }
end

local function getPlayerTile()
    if Refs.State then
        local ok, s = pcall(Refs.State)
        if ok and type(s) == "table" and type(s.x) == "number" then
            if s.active == false then return nil end
            return math.floor(s.x) + State.CalibX, math.floor(s.y - 0.475) + State.CalibY
        end
    end
    local v = getView()
    if not v then return nil end
    local center = v.pv.AbsolutePosition + v.pv.AbsoluteSize / 2
    local rel = center - v.tiles.AbsolutePosition
    return math.floor(rel.X / v.ts) + State.CalibX, math.floor(rel.Y / v.ts) + State.CalibY
end

-- Tile, block & mode Auto Farm yang dipakai sekarang (Pabrik memakai miliknya sendiri)
local function farmOffsets()
    local o = State.Override
    return (o and o.offsets) or State.Offsets
end
local function farmBlock()
    local o = State.Override
    if o then return o.block end
    return State.SelectedId
end
local function farmMode()
    local o = State.Override
    return (o and o.mode) or State.Mode
end

local function sortedOffsets()
    local list = {}
    for key in pairs(farmOffsets()) do
        local dx, dy = string.match(key, "^(-?%d+),(-?%d+)$")
        table.insert(list, { dx = tonumber(dx), dy = tonumber(dy) })
    end
    table.sort(list, function(a, b)
        if a.dy ~= b.dy then return a.dy < b.dy end
        return a.dx < b.dx
    end)
    return list
end

---------------------------------------------------------------------
-- AKSI DASAR: place & pukul
---------------------------------------------------------------------
local function sendSetTile(layer, x, y, id)
    if id ~= 0 and State.Visual and Anim.place then Anim.place(x, y, id) end
    if Refs.SetTile then
        local ok, err = pcall(Refs.SetTile, layer, x, y, id, false, false)
        if ok then return true end
        warn("[SkyP] setTile game gagal, pakai remote langsung: " .. tostring(err))
    end
    if NetOk and type(Net) == "table" and type(Net.tile) == "table" then
        -- sama seperti game: layer 1 = fg, 2 = bg
        local ok = pcall(Net.tile.send, {
            layer = (layer == "bg") and 2 or 1, x = x, y = y, id = id, flip = false,
        })
        if not ok then return false end
    elseif SetTileRemote then
        SetTileRemote:FireServer(layer, x, y, id, false)
    else
        return false
    end
    local grid = Refs.World and Refs.World[layer]
    if grid and grid[y] then grid[y][x] = id end
    return true
end

local function sendHitFx(x, y)
    if NetOk and type(Net) == "table" and Net.act then
        pcall(Net.act.send, { x = x + 0.5, y = y + 0.5 })
    end
end

local function hitsNeeded(id)
    if State.HitsOverride > 0 then return State.HitsOverride end
    local it = ItemDB[id]
    if not it then return 4 end
    local h = (it.kind == "seed") and 20 or it.hits
    return tonumber(h) or 4
end

local function canBreak(id)
    if id == 0 then return false end
    local it = ItemDB[id]
    if not it then return true end
    if it.lock or it.area or it.vend or it.display then return false end
    local h = (it.kind == "seed") and 20 or it.hits
    return h == nil or h > 0
end

-- Game abaikan pukulan ke tile yang baru di-place (< 0.3 detik)
local PLACE_GUARD = 0.32

-- Place 1 tile kalau kosong. Hasil: "place" / "habis" / nil
local function tryPlace(x, y)
    local sel = farmBlock()
    if not sel then return nil end
    local fg = tileAt("fg", x, y)
    if fg == nil then return nil end
    local bg = tileAt("bg", x, y)
    local it = ItemDB[sel]
    local layer = (it and it.background) and "bg" or "fg"
    local cur = (layer == "bg") and bg or fg
    if not (cur == 0 and (layer == "bg" or fg == 0)) then return nil end
    if invCount(sel) <= 0 then return "habis" end

    sendSetTile(layer, x, y, sel)
    if Refs.Inv then pcall(function() Refs.Inv:remove(sel, 1) end) end
    local key = x .. "," .. y
    HitCount[key] = nil
    PlacedAt[key] = os.clock()
    State.Placed += 1
    State.LastAction = "Place " .. itemName(sel) .. " (" .. x .. "," .. y .. ")"
    return "place"
end

-- Masih ada yang bisa dipecah di tile ini? (block depan / background)
local function breakableAt(x, y)
    local fg = tileAt("fg", x, y)
    if fg == nil then return false end
    if fg ~= 0 then return canBreak(fg) end
    local bg = tileAt("bg", x, y)
    return State.BreakBackground and bg ~= nil and bg ~= 0 and canBreak(bg)
end

-- Pukul 1 kali. Hasil: "hit" / "broke" / nil
-- includeBg = ikut pecah background
local function tryBreak(x, y, includeBg)
    if includeBg == nil then includeBg = State.BreakBackground end
    local key = x .. "," .. y
    local fg = tileAt("fg", x, y)
    if fg == nil then return nil end
    local bg = tileAt("bg", x, y)
    local layer, id
    if fg ~= 0 then
        layer, id = "fg", fg
    elseif includeBg and bg ~= 0 then
        layer, id = "bg", bg
    end
    if not layer or not canBreak(id) then return nil end

    -- tunggu sebentar kalau tile baru di-place
    local t = PlacedAt[key]
    if t then
        local age = os.clock() - t
        if age < PLACE_GUARD then task.wait(PLACE_GUARD - age) end
        PlacedAt[key] = nil
    end

    if Refs.Punch then
        local ok, err = pcall(Refs.Punch, x, y, State.MutePunch or nil, nil)
        if not ok then
            State.LastAction = "Error pukul: " .. tostring(err)
            return nil
        end
        if State.Visual then Anim.swing(x, y, "punch") end
        if tileAt(layer, x, y) ~= id then
            Drops.brokeAt[key] = os.clock()
            State.Broken += 1
            State.LastAction = "Break " .. itemName(id) .. " (" .. x .. "," .. y .. ")"
            return "broke"
        end
        State.LastAction = "Pukul " .. itemName(id) .. " (" .. x .. "," .. y .. ")"
        State.HitAt = os.clock()
        return "hit"
    end

    -- Cadangan: hitung pukulan sendiri
    local hc = HitCount[key]
    if not hc or hc.id ~= id or hc.layer ~= layer then
        hc = { id = id, layer = layer, n = 0 }
        HitCount[key] = hc
    end
    hc.n += 1
    sendHitFx(x, y)
    if State.Visual then Anim.swing(x, y, "punch") end
    local need = hitsNeeded(id)
    if hc.n >= need then
        sendSetTile(layer, x, y, 0)
        HitCount[key] = nil
        Drops.brokeAt[key] = os.clock()
        State.Broken += 1
        State.LastAction = "Break " .. itemName(id) .. " (" .. x .. "," .. y .. ")"
        return "broke"
    end
    State.LastAction = "Pukul " .. itemName(id) .. " " .. hc.n .. "/" .. need
    return "hit"
end

---------------------------------------------------------------------
-- AUTO COLLECT
---------------------------------------------------------------------
-- Cara game: World.takeDrop(uid, jumlah) -> server balas jumlahnya -> masuk inventori.
-- Game cuma ambil drop yang disentuh badan; di sini drop diambil langsung.
local TakeDropRemote = WorldRemotes:FindFirstChild("TakeDrop") -- game lama saja

local getUpvalues -- (didefinisikan di bawah)

-- Fungsi tangan game dipanggil dari fungsi gambar yang terhubung ke RenderStepped:
-- cukup periksa upvalue fungsi-fungsi itu (jauh lebih ringan dari scan getgc).
function Anim.findFast()
    if not getconnections or Anim.fn then return Anim.fn ~= nil end
    for _, name in ipairs({ "RenderStepped", "Heartbeat", "PreRender", "Stepped" }) do
        local okS, sig = pcall(function() return RunService[name] end)
        if okS and sig then
            local ok, conns = pcall(getconnections, sig)
            if ok and type(conns) == "table" then
                for _, c in ipairs(conns) do
                    local okf, fn = pcall(function() return c.Function end)
                    if okf and type(fn) == "function" then
                        for _, u in pairs(getUpvalues(fn)) do
                            if type(u) == "function" and Anim.isArmFn(u) then
                                Refs.Arm = u
                                return Anim.bind(u)
                            end
                        end
                    end
                end
            end
        end
    end
    return false
end

-- Cari data world & isi tas cepat: telusuri upvalue fungsi game yang terhubung ke RunService
-- (fungsi gambar / update game memegang tabel-tabel itu). Maks 400 fungsi, tanpa getgc.
function Anim.quickRefs()
    if not getconnections then return false end
    local queue, seen, n = {}, {}, 0
    for _, name in ipairs({ "RenderStepped", "Heartbeat", "Stepped" }) do
        local okS, sig = pcall(function() return RunService[name] end)
        if okS and sig then
            local ok, conns = pcall(getconnections, sig)
            if ok and type(conns) == "table" then
                for _, c in ipairs(conns) do
                    local okf, fn = pcall(function() return c.Function end)
                    if okf and type(fn) == "function" then queue[#queue + 1] = fn end
                end
            end
        end
    end
    local i = 1
    while i <= #queue and n < 400 and not (Refs.Inv and Refs.World) do
        local fn = queue[i]
        i += 1
        if not seen[fn] then
            seen[fn] = true
            n += 1
            for _, u in pairs(getUpvalues(fn)) do
                local tu = type(u)
                if tu == "table" then
                    if not Refs.Inv then
                        local ok, isInv = pcall(function()
                            return getmetatable(u) == InventoryModule and type(rawget(u, "slots")) == "table"
                        end)
                        if ok and isInv then Refs.Inv = u end
                    end
                    if not Refs.World then
                        local ok, isWorld = pcall(function()
                            return type(rawget(u, "fg")) == "table" and type(rawget(u, "bg")) == "table"
                                and type(rawget(u, "w")) == "number" and rawget(u, "spawn") ~= nil
                        end)
                        if ok and isWorld then Refs.World = u end
                    end
                elseif tu == "function" and not seen[u] then
                    queue[#queue + 1] = u
                end
            end
        end
    end
    return Refs.Inv ~= nil
end

function getUpvalues(fn)
    if debug and debug.getupvalues then
        local ok, ups = pcall(debug.getupvalues, fn)
        if ok and type(ups) == "table" then return ups end
    end
    local out = {}
    local gu = (debug and debug.getupvalue) or getupvalue
    if gu then
        for i = 1, 60 do
            local ok, v = pcall(gu, fn, i)
            if not ok then break end
            out[i] = v
        end
    end
    return out
end

-- Cek apakah tabel ini daftar drop game
local function isDropList(t)
    if type(t) ~= "table" or t == Refs.World then return false end
    local first = rawget(t, 1)
    if first == nil then return next(t) == nil end
    return type(first) == "table" and rawget(first, "uid") ~= nil and rawget(first, "frame") ~= nil
end

-- deep = true: boleh pakai getgc (berat, bisa bikin lag / crash di HP) -> hanya dari tombol "Hubungkan ke game"
local function findDropRefs(deep)
    -- 0) fungsi game World.dropList(): daftar drop yang sama untuk semua world (paling ringan)
    local w0 = Refs.World
    local dl = w0 and rawget(w0, "dropList")
    if type(dl) == "function" then
        local okl, l = pcall(dl)
        if okl and isDropList(l) then
            if Drops.list ~= l then Drops.update = nil end
            Drops.list = l
            -- v5.9.0: fungsi update (kurangi / hapus drop) juga wajib dicari. Dulu langsung
            -- return di sini, jadi Drops.update kosong -> drop hasil mode Remote tidak dihapus.
            if not Drops.update then Drops.findUpdate() end
            return true
        end
    end
    if Drops.list and not deep then return true end -- yang lama masih dipakai
    Drops.list, Drops.update = nil, nil
    -- 1) dari fungsi World.dropTaken (isinya: daftar drop + fungsi update)
    local wd = Refs.World and rawget(Refs.World, "dropTaken")
    if type(wd) == "function" then
        for _, u in pairs(getUpvalues(wd)) do
            if not Drops.list and isDropList(u) then
                Drops.list = u
            elseif not Drops.update and type(u) == "function" then
                Drops.update = u
            end
        end
    end
    -- 2) dari handler DropTaken game
    local ev = WorldRemotes:FindFirstChild("DropTaken")
    if not Drops.list and ev and getconnections then
        local ok, conns = pcall(getconnections, ev.OnClientEvent)
        if ok and type(conns) == "table" then
            for _, c in ipairs(conns) do
                local okf, fn = pcall(function() return c.Function end)
                if okf and type(fn) == "function" then
                    for _, u in pairs(getUpvalues(fn)) do
                        if not Drops.list and isDropList(u) then
                            Drops.list = u
                        elseif not Drops.update and type(u) == "function" then
                            Drops.update = u
                        end
                    end
                end
                if Drops.list then break end
            end
        end
    end
    -- 3) cadangan: cari lewat getgc (hanya kalau diminta: berat)
    if not Drops.list and deep and getgc then
        for _, v in ipairs(getgc(true)) do
            if type(v) == "table" then
                local e = rawget(v, 1)
                if type(e) == "table" and rawget(e, "uid") ~= nil and rawget(e, "frame") ~= nil
                    and rawget(e, "born") ~= nil then
                    Drops.list = v
                    break
                end
            end
        end
    end
    return Drops.list ~= nil
end

-- Cari fungsi game yang mengurangi / menghapus drop (dipakai World.dropTaken).
-- Ciri: upvalue World.dropTaken, dan fungsi itu sendiri memegang daftar drop yang sama.
function Drops.findUpdate()
    local w, list = Refs.World, Drops.list
    local wd = w and rawget(w, "dropTaken")
    if type(wd) ~= "function" or not list then return false end
    for _, u in pairs(getUpvalues(wd)) do
        if type(u) == "function" then
            for _, uu in pairs(getUpvalues(u)) do
                if rawequal(uu, list) then
                    Drops.update = u
                    return true
                end
            end
        end
    end
    return false
end

-- Terapkan hasil ambil drop ke tampilan, sama seperti game:
--   sisa > 0 -> angka drop dikurangi; sisa 0 -> keluar dari daftar + frame dihapus.
-- Tanpa ini, loop gambar game menampilkan drop lagi (flown di-reset saat badan tidak menyentuh).
function Drops.applyTaken(d, left)
    local list = Drops.list
    if not list or not table.find(list, d) then return end
    if not Drops.update then Drops.findUpdate() end
    if Drops.update then
        local ok = pcall(Drops.update, d, left)
        if ok then
            if left > 0 then
                d.flown = nil
                if typeof(d.frame) == "Instance" then pcall(function() d.frame.Visible = not d.culled end) end
            end
            return
        end
    end
    -- cadangan manual (fungsi game tidak ketemu)
    d.n = left
    if left > 0 then
        pcall(function()
            if d.setGem then d.setGem(left) elseif d.count then d.count:set(left > 1 and tostring(left) or "") end
        end)
        d.flown = nil
        if typeof(d.frame) == "Instance" then pcall(function() d.frame.Visible = not d.culled end) end
    else
        local i = table.find(list, d)
        if i then table.remove(list, i) end
        if typeof(d.frame) == "Instance" then pcall(function() d.frame:Destroy() end) end
    end
end

-- Catat jarak (badan -> drop) tiap percobaan ambil drop, untuk mengukur batas jarak server.
Drops.Probe = { ok = {}, fail = {}, okMax = nil, failMin = nil, nOk = 0, nFail = 0 }
function Drops.probe(dist, good)
    if not dist then return end
    local P = Drops.Probe
    local b = math.floor(dist * 2) / 2
    local t = good and P.ok or P.fail
    t[b] = (t[b] or 0) + 1
    if good then
        P.nOk += 1
        if not P.okMax or dist > P.okMax then P.okMax = dist end
    else
        P.nFail += 1
        if not P.failMin or dist < P.failMin then P.failMin = dist end
    end
end

-- PATCH v1.4: jalur ambil-drop dicari otomatis (tidak lagi bergantung pada satu nama fungsi).
-- Urutan: World.takeDrop -> remote lama TakeDrop -> Net.call("TakeDrop") (game ByteNet).
-- Dulu kalau World.takeDrop hilang karena update game, takeDrop() langsung return false
-- tanpa pesan -> Remote tidak mengambil apa pun (seed ikut tidak terambil).
Drops.NetTakeBad = 0
function Drops.takePath()
    local w = Refs.World
    local wt = w and rawget(w, "takeDrop")
    if type(wt) == "function" then return "world", wt end
    if TakeDropRemote then return "remote", TakeDropRemote end
    if NetOk and type(Net) == "table" and type(Net.call) == "function" and Drops.NetTakeBad < 3 then
        return "net", Net.call
    end
    return nil
end
function Drops.hasTake() return Drops.takePath() ~= nil end
function Drops.sendTake(uid, amount)
    local kind, f = Drops.takePath()
    Drops.TakeKind = kind
    if kind == "world" then
        return pcall(f, uid, amount)
    elseif kind == "remote" then
        return pcall(f.InvokeServer, f, uid, amount)
    elseif kind == "net" then
        local ok, res = pcall(f, "TakeDrop", uid, amount)
        if not ok then Drops.NetTakeBad += 1 else Drops.NetTakeBad = 0 end
        return ok, res
    end
    return false, "tidak ada jalur ambil-drop"
end

local function takeDrop(d)
    if not Drops.hasTake() then return false end
    if d.taking or d.pending or d.display or (d.n or 0) <= 0 then return false end
    -- drop yang kamu buang sendiri belum boleh dipungut lagi (aturan game), kecuali gems
    if d.armed == false and d.id ~= 112 then return false end
    local now = os.clock()
    if DropFailUntil[d.uid] and now < DropFailUntil[d.uid] then return false end

    local amount = d.n
    if d.id ~= 112 and Refs.Inv then -- 112 = gems, tidak makan slot
        local okr, room = pcall(function() return Refs.Inv:room(d.id) end)
        if okr and type(room) == "number" then amount = math.min(amount, room) end
    end
    if amount <= 0 then -- inventori penuh: coba lagi 1 detik lagi
        DropFailUntil[d.uid] = now + 1
        local last = Hook.LastFull[d.id]
        if not last or now - last > 120 then
            Hook.LastFull[d.id] = now
            Hook.send("full", "Inventori penuh: " .. itemName(d.id) .. " tidak bisa diambil lagi")
        end
        return false
    end

    local probeDist
    do
        local okS, ps = false, nil
        if Refs.State then okS, ps = pcall(Refs.State) end
        if okS and type(ps) == "table" and type(ps.x) == "number" and type(d.x) == "number" and type(d.y) == "number" then
            probeDist = math.max(math.abs(d.x - ps.x), math.abs(d.y - (ps.y - 0.475)))
        end
    end

    d.taking = true -- cegah diambil dobel
    -- langsung hilang dari layar selama menunggu jawaban server.
    -- Tidak pakai d.flown: loop gambar game me-reset flown + memunculkan drop lagi
    -- tiap frame kalau badan tidak menyentuhnya (mode Remote = ambil dari jauh).
    if typeof(d.frame) == "Instance" then pcall(function() d.frame.Visible = false end) end
    local ok, taken = Drops.sendTake(d.uid, amount)
    d.taking = false

    local good = ok and type(taken) == "number" and taken > 0
    -- drop yang baru muncul (< 1 dtk) sering ditolak server karena belum sinkron: jangan dihitung
    -- sebagai penolakan (dulu ini bikin mode Otomatis salah pindah ke Sentuhan, seed tidak terambil)
    local young = d.seenAt and (os.clock() - d.seenAt) < 1.0
    if good or not young then Drops.probe(probeDist, good) end
    if not good then
        if not ok then Drops.LastErr = tostring(taken) end
        if young then
            DropFailUntil[d.uid] = os.clock() + 0.3
            d.flown = nil
            if typeof(d.frame) == "Instance" then pcall(function() d.frame.Visible = not d.culled end) end
            return false
        end
        State.CollectFail += 1
        d.refused = os.clock() -- tanda ditolak, sama seperti game
        d.failN = (d.failN or 0) + 1
        DropFailUntil[d.uid] = os.clock() + math.min(8, d.failN) -- 1, 2, 3.. detik (yang terus ditolak makin jarang)
        d.flown = nil
        if typeof(d.frame) == "Instance" then pcall(function() d.frame.Visible = not d.culled end) end
        return false
    end
    DropFailUntil[d.uid] = nil

    if d.id == 112 then
        if Refs.Gems then pcall(Refs.Gems.addGems, taken) end
    elseif Refs.Inv then
        pcall(function() Refs.Inv:add(d.id, taken) end)
    end
    Drops.applyTaken(d, math.max(0, (d.n or 0) - taken)) -- kurangi / hapus drop seperti game
    State.Collected += taken
    Stats.Items[d.id] = (Stats.Items[d.id] or 0) + taken
    State.LastAction = "Collect " .. itemName(d.id) .. " x" .. taken
    return true
end

local function inTile(t, x, y)
    return x >= t.x - 0.15 and x < t.x + 1.15 and y >= t.y - 0.15 and y < t.y + 1.15
end

-- ---------- Collector cepat ----------
-- Cek daftar drop TIAP FRAME. Drop di area langsung diambil, semuanya sekaligus
-- (paralel), jadi tidak antri menunggu balasan server satu per satu.
--   Auto Farm  : drop di tile yang dipilih di Grid
--   Clear / Farmer : drop di sekitar karakter
local OffsetParse = {}
local nextDropScan = 0

local function canTry(d, now)
    if type(d) ~= "table" or d.taking or (d.n or 0) <= 0 or type(d.x) ~= "number" then return false end
    if d.armed == false and d.id ~= 112 then return false end
    local fail = DropFailUntil[d.uid]
    return not (fail and now < fail)
end

-- Drop TIDAK diambil lewat remote oleh script: drop terambil oleh game sendiri saat badan
-- menyentuhnya (fisika game, seperti main manual). Di sini cuma cari daftar drop & hitung
-- drop yang terambil di dekat badan (untuk status).
-- Mode Remote (cara lama): drop di tile grid / di sekitar karakter diambil lewat fungsi ambil-drop game
function Drops.remoteTick(list, s)
    local offs = farmOffsets()
    local farmArea = (State.AutoCollect or State.Override ~= nil) and next(offs) ~= nil
    local nearArea = State.CollectAround or (Clear.Running and Clear.Collect) or (Farmer.Running and Farmer.Collect)
        or Pabrik.Running or Splice.Roaming
    if not farmArea and not nearArea then return end
    local cx, cy = s.x, s.y - 0.475
    local ptx, pty = getPlayerTile()
    local anchor = State.Override and State.Override.anchor
    if anchor then ptx, pty = anchor.x, anchor.y end -- Pabrik: tile break dikunci ke titik break
    local now = os.clock()
    local R = (State.CollectRadius or 3) + 0.2
    local reach = (State.RemoteReach or 2) + 0.2 -- lebih jauh dari ini ditolak server: jangan ditembak
    local movers = Clear.Running or Farmer.Running or Pabrik.Running or Splice.Running
        or Splice.Roaming or Vend.Running or State.Running or (Session.RT and Session.RT.Running)
    local canChase = nearArea and State.RemoteChase ~= false and not movers and not Drops.chasing
    local far, farDist = nil, nil
    local fars = {} -- semua drop di luar jangkauan Remote (dijemput sekali jalan)
    local toTake = {}
    local z = Pabrik.Zone -- tempat drop pabrik tidak ikut diambil lagi
    if z and z.world ~= (Refs.World and rawget(Refs.World, "name")) then z = nil end
    for i = #list, 1, -1 do
        local d = list[i]
        if type(d) == "table" and not d.seenAt then d.seenAt = now end
        if canTry(d, now) and now - d.seenAt >= 0.15
            and not (z and math.abs(d.x - z.x) <= 2.5 and math.abs(d.y - z.y) <= 2.5) then
            local dist = math.max(math.abs(d.x - cx), math.abs(d.y - cy))
            if dist > reach then
                if canChase and dist <= R then
                    fars[#fars + 1] = d
                    if not farDist or dist < farDist then far, farDist = d, dist end
                end
                continue
            end
            local hit = nearArea and math.abs(d.x - cx) <= R and math.abs(d.y - cy) <= R
            if not hit and farmArea and ptx then
                for key in pairs(offs) do
                    local o = OffsetParse[key]
                    if not o then
                        local dx, dy = string.match(key, "^(-?%d+),(-?%d+)$")
                        o = { tonumber(dx), tonumber(dy) }
                        OffsetParse[key] = o
                    end
                    if o[1] and inTile({ x = ptx + o[1], y = pty + o[2] }, d.x, d.y) then
                        hit = true
                        break
                    end
                end
            end
            if hit then
                local it = ItemDB[d.id]
                toTake[#toTake + 1] = { d = d, dist = dist, seed = (it and it.kind == "seed") and 0 or 1 }
            end
        end
    end
    table.sort(toTake, function(a, b) -- seed duluan, lalu yang terdekat
        if a.seed ~= b.seed then return a.seed < b.seed end
        return a.dist < b.dist
    end)
    for _, e in ipairs(toTake) do task.spawn(takeDrop, e.d) end
    if far and Drops.chaseFar then task.spawn(Drops.chaseFar, far, fars) end
end

-- PATCH Collect Otomatis (pintar):
--   coba Remote dulu (paling cepat). Jarak Remote diukur sendiri dari hasil server (Drops.Probe).
--   Kalau Remote terus ditolak / fungsi ambil-drop game tidak ada -> pindah Sentuhan, dicoba lagi 90 dtk kemudian.
task.spawn(function()
    local lastOk, lastFail = 0, 0
    while alive() do
        task.wait(2)
        if State.CollectAuto then
            local P = Drops.Probe
            local canRemote = Drops.hasTake()
            local dOk, dFail = P.nOk - lastOk, P.nFail - lastFail
            lastOk, lastFail = P.nOk, P.nFail
            if not canRemote then
                State.CollectMode = "Sentuhan"
            elseif State.CollectMode == "Remote" then
                if dFail >= 6 and dOk == 0 then
                    State.CollectMode = "Sentuhan"
                    Drops.AutoBack = os.clock() + 90
                    State.LastAction = "Collect: Remote ditolak server, pindah ke Sentuhan"
                end
            elseif os.clock() >= (Drops.AutoBack or 0) then
                State.CollectMode = "Remote"
            end
            -- jarak Remote terjauh yang masih diterima server
            if P.nOk >= 8 and P.okMax then
                local lim = P.okMax
                if P.failMin and P.failMin < lim then lim = P.failMin - 0.25 end
                local r = math.clamp(math.floor(lim), 1, 5)
                if r ~= State.RemoteReach then State.RemoteReach = r end
            end
        end
    end
end)

-- Pakai Remote sekarang?
--   Pabrik: panen = sentuhan badan; BREAK = Remote ke semua tile break + sekitar badan
--           (kecuali mode Otomatis sudah mendeteksi Remote ditolak server -> sentuhan).
--   Lainnya: ikut Mode collect.
function Drops.useRemote()
    if Pabrik.Running then
        if State.Override == nil or not Drops.hasTake() then return false end
        return not (State.CollectAuto and State.CollectMode ~= "Remote")
    end
    return State.CollectMode == "Remote"
end

local function collectTick()
    -- sedang pergi drop (Pabrik / Farmer / Auto Farm / Vending kosongkan): script TIDAK mengambil drop apa pun,
    -- supaya barang di titik drop tidak terpungut lagi
    if Pabrik.Traveling or (Vend.Running and Vend.Mode == "Kosongkan sampai habis") then return end
    local busy = State.AutoCollect or State.CollectAround or State.Override ~= nil or (Clear.Running and Clear.Collect)
        or (Farmer.Running and Farmer.Collect) or Pabrik.Running or Splice.Roaming or Vend.Running
    if not busy then return end
    local tnow = os.clock()
    if tnow < (Drops.nextTick or 0) then return end -- 5-10x per detik cukup (hemat FPS)
    Drops.nextTick = tnow + (Drops.useRemote() and 0.1 or 0.2)
    local list = Drops.list
    if not list then
        local now = os.clock()
        if now >= nextDropScan then -- cari daftar drop paling sering tiap 5 detik
            nextDropScan = now + 5
            findDropRefs()
        end
        return
    end
    local ok, s = false, nil
    if Refs.State then ok, s = pcall(Refs.State) end
    if not (ok and type(s) == "table" and type(s.x) == "number") then return end
    if Drops.useRemote() then
        Drops.remoteTick(list, s) -- jumlah terambil dihitung oleh takeDrop
        return
    end
    local cx, cy = s.x, s.y - 0.475
    local seen = {}
    for _, d in ipairs(list) do
        if type(d) == "table" and type(d.x) == "number" and math.abs(d.x - cx) <= 1.5 and math.abs(d.y - cy) <= 1.5 then
            seen[d] = d.n or 0
        end
    end
    for d, n in pairs(Drops.seen or {}) do
        if seen[d] == nil and not table.find(list, d) and d.id and n > 0 then -- hilang di dekat badan = terambil
            State.Collected += n
            Stats.Items[d.id] = (Stats.Items[d.id] or 0) + n
        end
    end
    Drops.seen = seen
    if State.CollectMode == "Jemput" and Drops.fetchTick then Drops.fetchTick(list, s) end
end

table.insert(Connections, RunService.Heartbeat:Connect(function()
    if alive() then collectTick() end
end))

-- Tunggu sebentar sampai drop di tile ini terambil (supaya tidak tertimpa block baru)
local function waitTileDrops(t, maxSec)
    local list = Drops.list
    if not list then return end
    local t0 = os.clock()
    while os.clock() - t0 < maxSec and alive() do
        local now, busy = os.clock(), false
        for _, d in ipairs(list) do
            if type(d) == "table" and type(d.x) == "number" and (d.n or 0) > 0 and inTile(t, d.x, d.y)
                and (d.taking or canTry(d, now)) then
                busy = true
                break
            end
        end
        if not busy then return end
        task.wait()
    end
end

-- Tunggu sampai drop yang menempel badan selesai dipungut game (sentuhan, bukan remote)
local function waitNearDrops(maxSec)
    local list = Drops.list
    if not list then return end
    task.wait(0.15) -- drop baru muncul sedikit terlambat
    local t0 = os.clock()
    while os.clock() - t0 < maxSec and alive() do
        local ok, s = false, nil
        if Refs.State then ok, s = pcall(Refs.State) end
        if not (ok and type(s) == "table" and type(s.x) == "number") then return end
        local cx, cy = s.x, s.y - 0.475
        local busy = false
        for _, d in ipairs(list) do
            -- sama dengan aturan game: < 0.6 tile mendatar & setinggi badan (kaki s.y, kepala s.y - 0.95)
            if type(d) == "table" and type(d.x) == "number" and (d.n or 0) > 0 and d.armed ~= false
                and math.abs(d.x - s.x) < 0.6 and d.y + 0.3 > s.y - 0.95 and d.y - 0.3 < s.y then
                local room = true
                if d.id ~= 112 and Refs.Inv then -- inventori penuh: tidak akan terpungut
                    local okr, r = pcall(function() return Refs.Inv:room(d.id) end)
                    if okr and type(r) == "number" and r <= 0 then room = false end
                end
                if room then
                    busy = true
                    break
                end
            end
        end
        if not busy then return end
        task.wait()
    end
end

---------------------------------------------------------------------
-- STATUS
---------------------------------------------------------------------
local function offsetsText()
    local list = {}
    for _, o in ipairs(sortedOffsets()) do
        table.insert(list, "(" .. o.dx .. "," .. o.dy .. ")")
    end
    return #list > 0 and table.concat(list, " ") or "-"
end

local lastStatusText = nil

local function updateStatus()
    if not UI.Status then return end
    local px, py = getPlayerTile()
    local sel = State.SelectedId
    local txt = "Status   : " .. (State.Running and "JALAN" or "BERHENTI")
        .. "\nBlock    : " .. (sel and (itemName(sel) .. " x" .. invCount(sel)) or "-")
        .. "\nKarakter : " .. (px and ("(" .. px .. "," .. py .. ")") or "tidak di world")
        .. "\nTile     : " .. offsetsText()
        .. "\nPlace/Break/Collect : " .. State.Placed .. " / " .. State.Broken .. " / " .. State.Collected
        .. (State.CollectFail > 0 and (" (ditolak " .. State.CollectFail .. ")") or "")
        .. ("\nCollect  : " .. tostring(State.CollectMode) .. " via " .. tostring(Drops.TakeKind or (Drops.hasTake() and "?" or "tidak ada (sentuhan)")))
        .. (Drops.LastErr and ("\nError take: " .. Drops.LastErr) or "")
        .. (State.Dropped > 0 and ("\nDrop seed: di-drop " .. State.Dropped) or "")
        .. "\nPosisi farm: " .. (State.Home and ("(" .. State.Home.x .. "," .. State.Home.y .. ")") or "-")
        .. " | refill " .. (State.AutoRefill and "on" or "off") .. " | return " .. (State.AutoReturn and "on" or "off")
        .. " | drop seed " .. (State.SeedDrop and "on" or "off")
        .. "\nAksi     : " .. State.LastAction
    if txt == lastStatusText then return end
    lastStatusText = txt
    task.defer(function()
        pcall(function() UI.Status:SetDesc(txt) end)
    end)
end

---------------------------------------------------------------------
-- MODE LITE (matikan particle + suara)
---------------------------------------------------------------------
local DummyLabel = setmetatable({}, { __index = function() return 0 end, __newindex = function() end })
local DummyParticle = setmetatable({ l = DummyLabel, k = {} }, { __index = function() return 0 end, __newindex = function() end })
local NullSound
NullSound = setmetatable({}, {
    __index = function() return NullSound end,
    __newindex = function() end,
    __call = function() return NullSound end,
})
local LiteSaved = {}

local function liteOverride(tbl, key, repl)
    if type(tbl) == "table" and type(rawget(tbl, key)) == "function" then
        table.insert(LiteSaved, { tbl, key, rawget(tbl, key) })
        tbl[key] = repl
    end
end

local function setLite(on)
    State.LiteMode = on
    if on then
        if #LiteSaved == 0 then
            if ParticlesOk then liteOverride(ParticlesModule, "spawn", function() return DummyParticle end) end
            if SfxOk then
                liteOverride(SfxModule, "play", function() return NullSound end)
                liteOverride(SfxModule, "playAt", function() return NullSound end)
            end
        end
        for _, p in ipairs(Refs.Particles) do
            pcall(function()
                for _, e in ipairs(p.live) do
                    if typeof(e.l) == "Instance" then e.l.Visible = false end
                end
            end)
        end
    else
        for _, s in ipairs(LiteSaved) do
            pcall(function() s[1][s[2]] = s[3] end)
        end
        table.clear(LiteSaved)
    end
end

---------------------------------------------------------------------
-- MISC: walkspeed, infinite jump, fly + tembus block
---------------------------------------------------------------------
-- Infinite jump: game dibuat mengira ada Antigravity Generator, jadi bisa lompat di udara
local OrigJammerOn = nil
local function infJumpWrapper(id, ...)
    -- dimatikan saat Clear / Farmer jalan (lompat harus normal)
    if Misc.InfJump and id == 4992 and not AutoInput.active then
        return true
    end
    if OrigJammerOn then return OrigJammerOn(id, ...) end
    return false
end

local function hookJammer()
    local w = Refs.World
    if not w then return end
    local cur = rawget(w, "jammerOn")
    if cur == infJumpWrapper or type(cur) ~= "function" then return end
    OrigJammerOn = cur
    w.jammerOn = infJumpWrapper
end

local function unhookJammer()
    local w = Refs.World
    if w and rawget(w, "jammerOn") == infJumpWrapper and OrigJammerOn then
        w.jammerOn = OrigJammerOn
    end
end

local function setInfJump(on)
    Misc.InfJump = on
    if on then hookJammer() else unhookJammer() end
end

local function setGhost(on)
    Misc.Ghost = on
    if not on then
        Misc.UpHeld, Misc.DownHeld = false, false
        if Refs.World then Refs.World.ghost = false end
    end
    if UI.FlyPad then UI.FlyPad.Enabled = on end
end

local function setSpeed(pct)
    Misc.Speed = math.clamp(math.floor(tonumber(pct) or 100), 50, 500)
    if Misc.Speed == 100 and Refs.World then Refs.World.speedScale = 1 end
end

-- Tombol gerak game dibaca dari WorldMenu.isDown. Dibungkus supaya
-- tombol ▲/▼ Fly bisa dipakai, dan Clear / Farmer bisa "menekan" tombol sendiri.
local OrigIsDown = nil
local function isDownWrapper(saved, key, ...)
    if AutoInput.active then
        if key == "keyLeft" then return AutoInput.left end
        if key == "keyRight" then return AutoInput.right end
        if key == "keyJump" then return AutoInput.jump end
        if key == "keyDown" then return AutoInput.down end
    end
    if Misc.Ghost then
        if key == "keyDown" and Misc.DownHeld then return true end
        if key == "keyJump" and Misc.UpHeld then return true end
    end
    return OrigIsDown(saved, key, ...)
end

if MenuModOk and type(MenuModule) == "table" and type(rawget(MenuModule, "isDown")) == "function" then
    OrigIsDown = rawget(MenuModule, "isDown")
    MenuModule.isDown = isDownWrapper
end

-- Pasang walkspeed & fly tiap frame (game bisa menimpanya)
table.insert(Connections, RunService.Heartbeat:Connect(function()
    local w = Refs.World
    if not w or not alive() then return end
    if Misc.Speed ~= 100 then w.speedScale = Misc.Speed / 100 end
    if Misc.Ghost and w.ghost ~= true then w.ghost = true end
end))

---------------------------------------------------------------------
-- FARM LOOP: place semua dulu, baru break satu per satu
---------------------------------------------------------------------
local stopFarm
local Auto = {} -- PATCH: dideklarasikan lebih awal (dipakai farmLoop/startFarm)

local function waitMs(ms)
    task.wait(Guard.jit(math.max(ms or 0, 10)) / 1000)
    return State.Running and alive()
end

local function validate()
    local doPlace = farmMode() ~= "Break saja"
    if not Refs.World then return "Data world belum ketemu. Tekan 'Hubungkan ke game'" end
    if State.Fast and not Refs.Punch then
        pcall(findRefs) -- cari ulang referensi fungsi pukul (game update bisa mengacak nama)
        if not Refs.Punch then return "Break Cepat butuh fungsi Pukul. Referensi 'Pukul' belum ketemu: jalankan Diagnosa di tab Observasi" end
    end
    if next(farmOffsets()) == nil then return "Pilih tile dulu di Grid Tile" end
    if not getPlayerTile() then return "Kamu belum masuk world" end
    if doPlace and not farmBlock() then return "Pilih block dari inventori" end
    return nil
end

-- Rayman's Fist sedang dipakai? (fungsi asli game)
local function raymanOn()
    local w = Refs.World
    local f = w and rawget(w, "raymanOn")
    if type(f) ~= "function" then return false end
    local ok, on = pcall(f)
    return ok and on == true
end

-- Cari 2-3 tile target yang segaris dari karakter (8 arah, jarak 1-3),
-- sama seperti pukulan Rayman di game.
local RAY_DIRS = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 }, { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } }
local function raymanLine(px, py, active)
    local byKey = {}
    for _, a in ipairs(active) do byKey[a.x .. "," .. a.y] = a end
    local best, bestDir = nil, nil
    for _, d in ipairs(RAY_DIRS) do
        local line = {}
        for i = 1, 3 do
            local a = byKey[(px + d[1] * i) .. "," .. (py + d[2] * i)]
            if a then line[#line + 1] = a end
        end
        if #line >= 2 and #line > (best and #best or 0) then best, bestDir = line, d end
    end
    return best, bestDir
end

-- Kabarkan gerakan Rayman ke server (paket yang sama dengan game saat pukulan Rayman)
local function raymanAct(dir)
    local ok, s = pcall(Refs.State)
    if not ok or type(s) ~= "table" or not s.x then return end
    if NetOk and type(Net) == "table" and Net.act then
        pcall(Net.act.send, { kind = 4, x = s.x + dir[1], y = s.y - 0.475 + dir[2] })
    end
end

local function farmLoop(runId)
    local lastStatus = 0
    while State.Running and alive() and State.RunId == runId do
        if State.DropPause then -- sedang pergi drop seed
            task.wait(0.2)
            continue
        end
        local doPlace = farmMode() ~= "Break saja"
        local doBreak = farmMode() ~= "Place saja"

        if State.AutoReturn and State.Home and not State.Override and Auto.walkTo
            and os.clock() >= (State.ReturnFailAt or 0) then
            local hx, hy = Auto.here()
            if hx and (hx ~= State.Home.x or hy ~= State.Home.y) then
                State.LastAction = ("Kembali ke posisi farm (%d,%d)"):format(State.Home.x, State.Home.y)
                if not Auto.walkTo(State.Home.x, State.Home.y, 30) then
                    State.ReturnFailAt = os.clock() + 20
                end
                if not (State.Running and alive() and State.RunId == runId) then break end
            end
        end

        local px, py = getPlayerTile()
        if not px then
            stopFarm("Karakter tidak ditemukan (keluar world?)")
            return
        end

        -- Pabrik: tile break DIKUNCI ke titik break (anchor), bukan ke posisi badan saat ini.
        -- Kalau badan bergeser (habis ambil drop / terdorong), balik dulu ke titik itu baru lanjut.
        local anchor = State.Override and State.Override.anchor
        if anchor then
            local ax, ay = Auto.here()
            if ax ~= anchor.x or ay ~= anchor.y then
                State.LastAction = ("Kembali ke titik break (%d,%d)"):format(anchor.x, anchor.y)
                local back = Auto.walkTo(anchor.x, anchor.y, 20)
                if not (State.Running and alive() and State.RunId == runId) then break end
                if not back then
                    State.AnchorFail = (State.AnchorFail or 0) + 1
                    if State.AnchorFail >= 3 then -- tidak bisa balik: akhiri sesi, Pabrik yang memutuskan
                        State.AnchorFail = 0
                        State.Running = false
                        break
                    end
                    task.wait(0.3)
                    continue
                end
            end
            State.AnchorFail = 0
            px, py = anchor.x, anchor.y
        end

        local tiles = {}
        for _, o in ipairs(sortedOffsets()) do
            tiles[#tiles + 1] = { x = px + o.dx, y = py + o.dy }
        end

        local acted, outOfBlock = false, false

        -- 0) Ambil drop di semua tile grid dengan sentuhan badan (sekali sapu), lalu balik ke posisi
        if (State.AutoCollect or State.Override) and not State.DropPause then
            Drops.waitSpawn(tiles) -- drop pecahan barusan datang dari server: tunggu muncul dulu
            if Drops.useRemote() then
                for _, t in ipairs(tiles) do waitTileDrops(t, 0.4) end -- diambil lewat remote (collectTick)
                -- PATCH v1.4: drop yang masih tersisa (di luar jangkauan / ditolak server) disapu dengan badan
                if Drops.touchAll then Drops.touchAll(tiles, px, py) end
            elseif Drops.touchAll then
                Drops.touchAll(tiles, px, py)
            end
        end

        -- 1) Place semua tile kosong
        if doPlace then
            for _, t in ipairs(tiles) do
                if not State.Running or State.DropPause then break end
                local r = tryPlace(t.x, t.y)
                if r == "habis" then
                    outOfBlock = true
                    break
                elseif r == "place" then
                    acted = true
                    if not waitMs(State.PlaceMs) then break end
                end
            end
        end

        -- 2) Pukul tile sampai habis (block depan lalu background).
        --    Server hanya terima 1 pukulan tiap ~0.22 detik (tangan biasa), jadi multi target
        --    = beberapa tile dipukul BERGANTIAN (sama seperti 2 jari). Semua tile benar-benar pecah.
        --    Pakai Rayman's Fist: 2-3 tile segaris dipukul sekali jalan (seperti Rayman asli).
        if doBreak then
            local K = math.clamp(math.floor(State.MultiTarget or 1), 1, 5)
            local nextI, active = 1, {}
            while State.Running and alive() and not State.DropPause do
                while #active < K and nextI <= #tiles do
                    local t = tiles[nextI]
                    nextI += 1
                    active[#active + 1] = { x = t.x, y = t.y, n = 0 }
                end
                if #active == 0 then break end

                -- pilih tile yang dipukul sekarang
                local hits, rayDir = nil, nil
                if K > 1 and raymanOn() then
                    hits, rayDir = raymanLine(px, py, active)
                end
                if not rayDir then hits = { active[1] } end -- giliran depan antrian

                local t0 = os.clock()
                if rayDir then raymanAct(rayDir) end
                local hit, broke = false, false
                for i, a in ipairs(hits) do
                    if not State.Running then break end
                    if i > 1 then task.wait(0.05) end -- jarak antar tile seperti animasi Rayman
                    local r = tryBreak(a.x, a.y)
                    a.n += 1
                    if r then hit, acted = true, true end
                    if r == "broke" then broke = true end
                    -- selesai kalau kosong / tidak bisa dipecah / sudah habis sampai background
                    if r == nil or a.n > 80 or (r == "broke" and not breakableAt(a.x, a.y)) then
                        a.done = true
                    end
                    a.used = true
                end

                -- tile yang barusan dipukul pindah ke belakang antrian (bergantian)
                local nextActive = {}
                for _, a in ipairs(active) do
                    if not a.done and not a.used then nextActive[#nextActive + 1] = a end
                end
                for _, a in ipairs(hits) do
                    a.used = nil
                    if not a.done then nextActive[#nextActive + 1] = a end
                end
                active = nextActive

                if hit then
                    local gap = Guard.jit(math.max(State.BreakMs, 200)) / 1000 -- server hanya terima ~1 pukulan / 0.22 dtk
                    if rayDir then gap = math.max(gap, 0.35) end -- jeda Rayman asli
                    if State.Fast then
                        -- jadwal absolut: pukulan berikutnya tepat gap setelah pukulan SEBELUMNYA,
                        -- bukan gap setelah selesai proses (tidak ada drift / waktu terbuang)
                        local due = (State.NextHitAt > 0 and State.NextHitAt or t0) + gap
                        local now = os.clock()
                        if due < now - gap then due = now end -- ketinggalan jauh: jangan menumpuk
                        State.NextHitAt = due
                        local rest = due - now
                        if rest > 0.002 then task.wait(rest) end
                    else
                        local rest = gap - (os.clock() - t0)
                        if rest > 0.005 then task.wait(rest) end
                    end
                    if not (State.Running and alive()) then break end
                end
                -- drop diambil otomatis oleh collector cepat
                if broke and not State.Fast and State.AfterBreakMs > 0 then task.wait(State.AfterBreakMs / 1000) end
            end
        end

        if not State.Running or not alive() then break end
        if State.DropPause then continue end

        local selNow = farmBlock()
        if acted and doPlace and selNow and invCount(selNow) <= 0 then acted = false end -- block habis: langsung refill
        if not acted then
            local sel = farmBlock()
            if outOfBlock or (doPlace and sel and invCount(sel) <= 0) then
                if State.AutoRefill and not State.Override and Auto.refillBlock and sel then
                    State.DropPause = true
                    State.LastAction = "Block habis: ambil block di sekitar"
                    local got = Auto.refillBlock(sel, function() return State.Running and alive() and State.RunId == runId end)
                    State.DropPause = false
                    if got then continue end
                end
                stopFarm("Block " .. itemName(sel) .. " habis" .. (State.AutoRefill and (" (tidak ada di radius " .. (State.RefillRadius or 10) .. " tile)") or ""))
                return
            end
            if not waitMs(State.BreakMs) then break end
        end

        State.Cycles += 1
        if os.clock() - lastStatus > 1 then
            lastStatus = os.clock()
            updateStatus()
        end
    end
    updateStatus()
end

local function setRunningVisual()
    if State.Override then return end -- dijalankan Pabrik: tombol Auto Farm tidak diubah
    if UI.FarmToggle then pcall(function() UI.FarmToggle:Set(State.Running) end) end
    if UI.GridStart then
        UI.GridStart.Text = State.Running and "STOP" or "START"
        UI.GridStart.BackgroundColor3 = State.Running and Color3.fromRGB(232, 84, 104) or Color3.fromRGB(62, 150, 255)
    end
end

stopFarm = function(reason)
    State.Running = false
    setRunningVisual()
    if reason and not State.Quiet then
        notify("Auto Farm berhenti", reason, 4)
        Hook.send("stop", "Auto Farm berhenti: " .. reason)
    end
    updateStatus()
end

-- Auto Farm, Clear & Farmer tidak boleh jalan bersamaan
local stopClear, stopFarmer

local function startFarm()
    if State.Running then return end
    State.NextHitAt = 0
    local err = validate()
    if err then
        stopFarm(err)
        return
    end
    if Splice.Running and Splice.stop then Splice.stop("Dihentikan karena Auto Farm dimulai") end
    if Pabrik.Running and Pabrik.stop then Pabrik.stop("Dihentikan karena Auto Farm dimulai") end
    if Clear.Running and stopClear then stopClear("Dihentikan karena Auto Farm dimulai") end
    if Farmer.Running and stopFarmer then stopFarmer("Dihentikan karena Auto Farm dimulai") end
    table.clear(HitCount)
    table.clear(PlacedAt)
    State.DropPause = false
    State.ReturnFailAt = 0
    State.Home = nil
    if Auto.here then
        local hx, hy = Auto.here()
        if hx then State.Home = { x = hx, y = hy } end
    end
    State.Running = true
    State.RunId = (State.RunId or 0) + 1
    setRunningVisual()
    updateStatus()
    task.spawn(function(id)
        local ok, e = pcall(farmLoop, id)
        if not ok then
            warn("[SkyP] farmLoop: " .. tostring(e))
            stopFarm("Error: " .. tostring(e))
        end
    end, State.RunId)
end
-- PATCH: error saat start tampil di notifikasi (bukan diam saja)
do
    local raw = startFarm
    startFarm = function()
        local ok, e = pcall(raw)
        if not ok then
            warn("[SkyP] startFarm: " .. tostring(e))
            State.Running = false
            notify("Auto Farm error", tostring(e), 10)
        end
    end
end


-- Fungsi untuk UI dikumpulkan di sini (Luau batasi 200 variabel per file)
-- (Auto sudah dideklarasikan di atas)
do (function() -- fungsi sendiri: variabel di dalam tidak ikut batas 200 local
---------------------------------------------------------------------
-- GERAK OTOMATIS (dipakai Clear World & Farmer)
---------------------------------------------------------------------
-- Cara kerja:
--   - Jalan dicari pakai A* sesuai fisika game (jalan, jatuh, lompat naik 1-3 tile).
--   - Karakter digerakkan dengan "menekan" tombol, sama seperti main biasa.
--   - Tidak pakai fly / noclip karena server me-rollback.
--   - Kalau tidak ada pijakan, taruh block dari inventori (jembatan / tangga).
local floor, abs = math.floor, math.abs

local Move = { Placed = 0 }  -- jumlah block pijakan yang dipasang
local BadEdge = {}           -- jalur yang barusan gagal (dihindari dulu)
local ClearFail, FarmerFail = {}, {}
local BreakTimes = {}        -- tile yang terus balik lagi setelah pecah
local Reach = nil            -- daftar tile yang bisa dijangkau (cache)

local function autoOn()
    return (Clear.Running or Farmer.Running or Splice.Roaming or Pabrik.Running or Move.Homing
        or Vend.Running) and alive()
end

local function setMoveStatus(text)
    if Clear.Running then
        Clear.Status = text
    elseif Farmer.Running then
        Farmer.Status = text
    elseif Splice.Roaming then
        Splice.Status = text
    elseif Pabrik.Running then
        Pabrik.Status = text
    elseif Vend.Running then
        Vend.Status = text
    end
end

local function skipTile(tbl, idx, sec)
    tbl[idx] = os.clock() + (sec or 30)
end

local function skipped(tbl, idx, now)
    local t = tbl[idx]
    if not t then return false end
    if (now or os.clock()) >= t then
        tbl[idx] = nil
        return false
    end
    return true
end

local function skippedCount(tbl)
    local n, now = 0, os.clock()
    for _, t in pairs(tbl) do
        if t > now then n += 1 end
    end
    return n
end

local function hudRange(name, def)
    local f = Refs.Hud and Refs.Hud[name]
    if type(f) == "function" then
        local ok, r = pcall(f)
        if ok and type(r) == "number" and r > 0 then return r end
    end
    return def
end

local function punchReach() return hudRange("punchRange", 2.5) end
local function buildReach() return hudRange("buildRange", 2.5) end

local function playerState()
    if not Refs.State then return nil end
    local ok, s = pcall(Refs.State)
    if ok and type(s) == "table" and type(s.x) == "number" and type(s.y) == "number" and s.active ~= false then
        return s
    end
    return nil
end

local function fgIdAt(x, y)
    local w = Refs.World
    local row = w and w.fg[y]
    return (row and row[x]) or 0
end

local function fgItemAt(x, y)
    local id = fgIdAt(x, y)
    if id ~= 0 then return ItemDB[id] end
    return nil
end

-- Tile padat? (sama dengan cek tabrakan game)
local function solidAt(x, y)
    local w = Refs.World
    if not w then return true end
    if x < 0 or x >= w.w or y >= w.h then return true end
    if y < 0 then return false end
    local it = fgItemAt(x, y)
    if not it then return false end
    if it.combiner then
        local ok, shut = pcall(w.combinerShut, x, y)
        return (not ok) or (shut and true or false)
    end
    if it.vip then -- pintu VIP: padat kalau kamu tidak punya akses
        local ok, may = pcall(w.vipMay, x, y)
        return not (ok and may)
    end
    if it.entrance then
        local sw = w.switches and w.switches[y * w.w + x]
        if it.gate then
            return not (sw and sw.off == true)
        end
        if sw and sw.public then return false end
        local ok, may = pcall(function() return w.areas.mayBuild(w.lock, x, y) end)
        return not (ok and may)
    end
    return it.solid and true or false
end

-- Tile berbahaya (lava, duri, laser)
local function hazardAt(x, y)
    local it = fgItemAt(x, y)
    return it ~= nil and (it.deadly or it.hurts or it.laser) and true or false
end

local function platformAt(x, y)
    local it = fgItemAt(x, y)
    return it ~= nil and it.platform and true or false
end

local function openAt(x, y)
    return not solidAt(x, y) and not hazardAt(x, y)
end

-- Ada pijakan aman di bawah tile ini?
local function realSupport(x, y)
    return not hazardAt(x, y + 1) and (solidAt(x, y + 1) or platformAt(x, y + 1))
end

-- Target kelihatan dari badan? (tidak terhalang lantai / atap padat di antaranya)
-- Panen lewat block bisa, tapi drop-nya jatuh di balik block dan tidak terambil.
function Move.los(nx, ny, tx, ty)
    if ty - ny >= 2 then
        for y = ny + 1, ty - 1 do
            if solidAt(tx, y) then return false end
        end
    elseif ny - ty >= 2 then
        for y = ty + 1, ny - 1 do
            if solidAt(tx, y) then return false end
        end
    end
    return true
end

-- Tile masuk jangkauan? (bentuk kotak di sekitar badan)
local function stateReaches(s, tx, ty, R)
    return abs(tx + 0.5 - s.x) <= R and abs(ty + 0.5 - (s.y - 0.475)) <= R
end

-- Boleh pecah di sini? (cek lock)
local function canWorkAt(x, y)
    local w = Refs.World
    local ok, res = pcall(function()
        if w.areas and type(w.areas.mayBuild) == "function" and not w.areas.mayBuild(w.lock, x, y) then
            return false
        end
        if type(w.builderOk) == "function" and not w.builderOk(x, y, false) then
            return false
        end
        return true
    end)
    return (not ok) or res
end

-- ---------- Block pijakan ----------
local function scaffoldId()
    local id, use
    if Clear.Running then
        id, use = Clear.ScaffoldId, Clear.UseBlock
    elseif Farmer.Running then
        id, use = Farmer.ScaffoldId, Farmer.UseBlock
    end
    if use and id and invCount(id) > 0 then return id end
    return nil
end

-- Boleh taruh block di sini? (kosong + izin bangun)
local function placeOk(x, y)
    local w = Refs.World
    if not w or x < 0 or y < 0 or x >= w.w or y >= w.h then return false end
    if fgIdAt(x, y) ~= 0 then return false end
    local ok, res = pcall(function()
        if w.areas and type(w.areas.canEdit) == "function" and not w.areas.canEdit(x, y) then return false end
        if type(w.builderOk) == "function" and not w.builderOk(x, y, true) then return false end
        return true
    end)
    return (not ok) or res
end

local function placeScaffold(x, y)
    local id = scaffoldId()
    if not id or not placeOk(x, y) then return false end
    local s = playerState()
    if not s or not stateReaches(s, x, y, buildReach() - 0.05) then return false end
    sendSetTile("fg", x, y, id) -- place lewat fungsi game
    if Refs.Inv then pcall(function() Refs.Inv:remove(id, 1) end) end
    Move.Placed += 1
    return true
end

local function worldVersion()
    -- berubah tiap ada block / pohon yang berubah, supaya cache jangkauan tidak basi
    return Clear.Broken + Farmer.Harvested + Farmer.Planted + Move.Placed + Splice.Planted
        + Pabrik.Harvested + Pabrik.Planted
        + State.Placed + State.Broken
end

local function startNode(s)
    local ny = floor(s.y - 0.475)
    local nx = floor(s.x)
    if realSupport(nx, ny) then return nx, ny end
    local a, b = floor(s.x - 0.3), floor(s.x + 0.3 - 0.0001)
    for _, c in ipairs({ a, b }) do
        if c ~= nx and realSupport(c, ny) then return c, ny end
    end
    return nx, ny
end

-- ---------- Antrian prioritas untuk A* ----------
local function heapPush(hf, hi, n, f, i)
    n += 1
    local k = n
    while k > 1 do
        local p = k // 2
        if hf[p] <= f then break end
        hf[k], hi[k] = hf[p], hi[p]
        k = p
    end
    hf[k], hi[k] = f, i
    return n
end

local function heapPop(hf, hi, n)
    local top = hi[1]
    local lf, li = hf[n], hi[n]
    hf[n], hi[n] = nil, nil
    n -= 1
    if n > 0 then
        local k = 1
        while true do
            local c = k * 2
            if c > n then break end
            if c < n and hf[c + 1] < hf[c] then c += 1 end
            if lf <= hf[c] then break end
            hf[k], hi[k] = hf[c], hi[c]
            k = c
        end
        hf[k], hi[k] = lf, li
    end
    return top, n
end

-- ---------- A* ----------
-- Cari jalan termurah ke tempat yang bisa memukul salah satu target.
-- Langkah yang bisa dipakai:
--   walk   : geser 1 tile (+ taruh block kalau perlu)
--   fall   : jalan ke pinggir lalu jatuh
--   jump   : lompat naik 1-3 tile
--   gap    : lompati lubang 1-2 tile
--   stair  : tangga lahan: lompat naik 2 lewat lubang ke lorong setinggi 1 tile
--   pillar : lompat lalu taruh block di bawah kaki (naik 1)
local MAX_EXPAND = 8000
local BLOCK_COST = 2

local function reachOffsets(R)
    return floor(R), math.ceil(-R + 0.025), floor(R + 0.025)
end

local function astar(sx, sy, goals, gx, gy, R, useBlock)
    local w = Refs.World
    if not w then return nil, false, {} end
    local W, H = w.w, w.h
    local WH = W * H
    local dxm, dyLo, dyHi = reachOffsets(R)
    local oC, sC, bC = {}, {}, {}

    local function open(x, y)
        if x < 0 or x >= W or y >= H then return false end
        if y < 0 then return true end
        local i = y * W + x
        local v = oC[i]
        if v == nil then
            v = openAt(x, y)
            oC[i] = v
        end
        return v
    end

    local function sup(x, y)
        if x < 0 or x >= W or y < 0 or y >= H then return false end
        local i = y * W + x
        local v = sC[i]
        if v == nil then
            v = realSupport(x, y)
            sC[i] = v
        end
        return v
    end

    local function buildable(x, y)
        if not useBlock or x < 0 or x >= W or y < 0 or y >= H then return false end
        local i = y * W + x
        local v = bC[i]
        if v == nil then
            v = placeOk(x, y)
            bC[i] = v
        end
        return v
    end

    local function h(x, y)
        local dx = abs(gx - x) - R
        local dyRaw = gy - y
        local dy = abs(dyRaw) - R
        local vw = (dyRaw < 0) and 1.5 or 0.5
        return (dx > 0 and dx or 0) + vw * (dy > 0 and dy or 0)
    end

    local function isGoal(nx, ny)
        -- goals.maxY: tempat berdiri tidak boleh lebih bawah dari ini (Bangun Lahan)
        if goals.maxY and ny > goals.maxY then return false end
        for ty = ny + dyLo, ny + dyHi do
            if ty >= 0 and ty < H then
                local base = ty * W
                for tx = nx - dxm, nx + dxm do
                    -- jangan berdiri tepat di atas target (noSelf: juga jangan di dalam tile target)
                    if tx >= 0 and tx < W and goals[base + tx] and not (tx == nx and ty == ny + 1)
                        and not (goals.noSelf and tx == nx and ty == ny)
                        and not (goals.los and ty - ny >= 2 and not open(tx, ny + 1))
                        and not (goals.los and ny - ty >= 2 and not open(tx, ny - 1)) then
                        return true
                    end
                end
            end
        end
        return false
    end

    local ex, ey, ek, ec, eb = {}, {}, {}, {}, {}
    local n = 0
    local function add(x, y, kind, cost, build)
        n += 1
        ex[n], ey[n], ek[n], ec[n], eb[n] = x, y, kind, cost, build
    end

    local function expand(x, y)
        n = 0
        for s = -1, 1, 2 do
            local ax = x + s
            if open(ax, y) then
                if sup(ax, y) then
                    add(ax, y, "walk", 1, false)
                else
                    if buildable(ax, y + 1) then
                        add(ax, y, "walk", 1 + BLOCK_COST, true)
                    end
                    -- jatuh sampai ketemu pijakan
                    local fy = y + 1
                    while fy < H and fy - y <= 40 and open(ax, fy) and not sup(ax, fy) do
                        fy += 1
                    end
                    if fy < H and open(ax, fy) and sup(ax, fy) then
                        add(ax, fy, "fall", 1 + 0.5 * (fy - y), false)
                    end
                    -- lompati lubang 1-2 tile
                    if open(x, y - 1) and open(x, y - 2) then
                        for dist = 2, 3 do
                            local mx = x + (dist - 1) * s
                            if not (open(mx, y) and open(mx, y - 1) and open(mx, y - 2)) then break end
                            if dist == 3 and sup(mx, y) then break end
                            local bx = x + dist * s
                            if open(bx, y - 1) and open(bx, y - 2) then
                                for k = 0, 2 do
                                    if not open(bx, y + k) then break end
                                    if sup(bx, y + k) then
                                        add(bx, y + k, "gap", dist + 0.5 + 0.5 * k, false)
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end
            -- lompat naik (atas kepala harus kosong)
            for dy = 1, 3 do
                if not open(x, y - dy) then break end
                if open(x, y - dy - 1) and open(ax, y - dy) and sup(ax, y - dy) and open(ax, y - dy - 1) then
                    add(ax, y - dy, "jump", 1 + 1.5 * dy, false)
                end
            end
            -- tangga lahan: naik 1-2 tile ke lorong setinggi 1 tile (atapnya pas di atas kepala,
            -- jadi lompat biasa tidak muat). Rapat ke dinding, lompat, geser masuk di puncak.
            for dy = 1, 2 do
                if open(x, y - 1) and (dy == 1 or open(x, y - 2)) and open(ax, y - dy) and sup(ax, y - dy)
                    and not (open(x, y - dy - 1) and open(ax, y - dy - 1)) then
                    add(ax, y - dy, "stair", 3 + 1.5 * dy, false)
                end
            end
        end
        -- naik 1 pakai block
        if useBlock and open(x, y - 1) and open(x, y - 2) and open(x, y - 3) and buildable(x, y) then
            add(x, y - 1, "pillar", 2 + BLOCK_COST, true)
        end
        return n
    end

    local startI = sy * W + sx
    local g, came, kind, buildOf, closed = { [startI] = 0 }, {}, {}, {}, {}
    local hf, hi, hn = {}, {}, 0
    hn = heapPush(hf, hi, hn, h(sx, sy), startI)
    local expanded = 0
    local now = os.clock()

    while hn > 0 do
        local cur
        cur, hn = heapPop(hf, hi, hn)
        if not closed[cur] then
            closed[cur] = true
            local cx, cy = cur % W, cur // W
            if isGoal(cx, cy) then
                local path = {}
                local i = cur
                while i ~= startI do
                    local p = came[i]
                    table.insert(path, 1, {
                        fx = p % W, fy = p // W, x = i % W, y = i // W,
                        kind = kind[i], build = buildOf[i], key = p * WH + i,
                    })
                    i = p
                end
                return path, false, closed
            end
            expanded += 1
            if expanded > MAX_EXPAND then return nil, false, closed end
            if expanded % 400 == 0 then
                task.wait()
                if not autoOn() then return nil, false, closed end
            end
            local gc = g[cur]
            local cnt = expand(cx, cy)
            for k = 1, cnt do
                local ni = ey[k] * W + ex[k]
                if not closed[ni] then
                    local bad = BadEdge[cur * WH + ni]
                    if not (bad and bad > now) then
                        local ng = gc + ec[k]
                        local old = g[ni]
                        if old == nil or ng < old then
                            g[ni], came[ni], kind[ni], buildOf[ni] = ng, cur, ek[k], eb[k]
                            hn = heapPush(hf, hi, hn, ng + h(ex[k], ey[k]), ni)
                        end
                    end
                end
            end
        end
    end
    return nil, true, closed -- tidak ada jalan sama sekali
end

-- Semua tile yang bisa dijangkau dari area ini
local function reachableTileSet(closed, W, R)
    local set = {}
    local dxm, dyLo, dyHi = reachOffsets(R)
    local n = 0
    for i in pairs(closed) do
        local x, y = i % W, i // W
        for dy = dyLo, dyHi do
            local ty = y + dy
            if ty >= 0 then
                local base = ty * W
                for dx = -dxm, dxm do
                    local tx = x + dx
                    if tx >= 0 and tx < W then set[base + tx] = true end
                end
            end
        end
        n += 1
        if n % 500 == 0 then task.wait() end
    end
    return set
end

-- Simpan daftar tile terjangkau, supaya tile di seberang jurang langsung dilewati
-- (tidak cari jalan berulang yang bikin karakter diam).
local function reachFilter(startI, R, useBlock)
    local c = Reach
    if c and c.world == Refs.World and c.start == startI and c.R == R and c.block == useBlock
        and c.ver == worldVersion() and os.clock() - c.at < 30 then
        return c.set
    end
    return nil
end

local function storeReach(startI, R, useBlock, closed)
    Reach = {
        world = Refs.World, start = startI, R = R, block = useBlock, ver = worldVersion(), at = os.clock(),
        set = reachableTileSet(closed, Refs.World.w, R),
    }
end

-- ---------- Gerakkan karakter ----------
local function releaseInput()
    AutoInput.left, AutoInput.right, AutoInput.jump, AutoInput.down = false, false, false, false
end

local function frame()
    task.wait()
    return autoOn()
end

local function waitAuto(ms)
    task.wait(Guard.jit(math.max(ms or 0, 30)) / 1000)
    return autoOn()
end

-- ===== ANIMASI AKSI (hanya tampilan di layar sendiri, tidak mengirim apa pun ke server) =====
-- Tangan karakter mengarah ke tile (sama seperti saat pemain memukul / memasang sendiri).
function Anim.swing(x, y, kind)
    if not (Anim.fn and Anim.idx and Anim.set) then return end
    local s = playerState()
    local facing = (s and x + 0.5 < s.x) and -1 or 1
    pcall(Anim.set, Anim.fn, Anim.idx, { t = os.clock(), x = x + 0.5, y = y + 0.5, facing = facing, kind = kind })
end

-- Efek asap kecil saat block dipasang (pakai efek "place" game)
function Anim.puff(x, y)
    local list = Refs.Particles
    if not list or #list == 0 then return end
    local pick = Anim.Particles
    if not pick then
        local worldGui = PlayerGui:FindFirstChild("GameGui")
        worldGui = worldGui and worldGui:FindFirstChild("World")
        for _, p in ipairs(list) do
            local ok, inWorld = pcall(function()
                return worldGui ~= nil and typeof(p.parent) == "Instance" and p.parent:IsDescendantOf(worldGui)
            end)
            if ok and inWorld then
                pick = p
                break
            end
        end
        pick = pick or list[1]
        Anim.Particles = pick
    end
    pcall(function() pick:place(x + 0.5, y + 0.5) end)
end

function Anim.place(x, y, id)
    local it = ItemDB[id]
    local seed = it and it.kind == "seed"
    Anim.swing(x, y, "build")
    if not seed then Anim.puff(x, y) end
end

-- Jalan ke targetX, lepas tombol saat sudah cukup dekat untuk berhenti
local function steerX(s, targetX, tol)
    local dx = targetX - s.x
    local vx = s.vx or 0
    local decel = s.grounded and 48 or 17
    local dir = 0
    if abs(dx) > tol then
        dir = dx > 0 and 1 or -1
        if vx * dir > 0 and (vx * vx) / (2 * decel) >= abs(dx) - tol * 0.5 then
            dir = 0
        end
    end
    AutoInput.left = dir < 0
    AutoInput.right = dir > 0
end

-- Jalan sampai berdiri di tengah tile tujuan
local function execWalk(tx, ty)
    local cx = tx + 0.5
    local s0 = playerState()
    if not s0 then return false end
    local limit = 1.5 + abs(cx - s0.x) * 0.35
    local t0 = os.clock()
    while frame() do
        local s = playerState()
        if not s or s.dead then return false end
        local nx, ny = floor(s.x), floor(s.y - 0.475)
        if s.grounded and ny ~= ty then return false end
        steerX(s, cx, 0.1)
        if nx == tx and abs(s.x - cx) <= 0.2 and s.grounded and abs(s.vx or 0) < 2 then
            AutoInput.left, AutoInput.right = false, false
            return true
        end
        if os.clock() - t0 > limit then return false end
    end
    return false
end

-- Jalan ke pinggir lalu jatuh ke tile tujuan
local function execFall(e)
    local cx = e.x + 0.5
    local limit = 1.5 + 0.3 * (e.y - e.fy)
    local t0 = os.clock()
    while frame() do
        local s = playerState()
        if not s or s.dead then return false end
        steerX(s, cx, 0.1)
        if s.grounded then
            local nx, ny = floor(s.x), floor(s.y - 0.475)
            if ny == e.y then
                if nx == e.x and abs(s.x - cx) <= 0.25 then return true end
            elseif ny ~= e.fy then
                return false
            end
        end
        if os.clock() - t0 > limit then return false end
    end
    return false
end

-- Lompat naik ke tile sebelah
local function execJump(e)
    if not execWalk(e.fx, e.fy) then return false end
    local dy = e.fy - e.y
    local top = e.y + 1                               -- tinggi kaki di tujuan
    local releaseY = top - ((dy == 1) and 0 or 0.4)   -- lepas lompat di sini (kepala tidak kebentur)
    local cx = e.x + 0.5
    releaseInput()
    if not frame() then return false end              -- lepas 1 frame supaya lompat terbaca
    AutoInput.jump = true
    local t0 = os.clock()
    local airborne = false
    while frame() do
        local s = playerState()
        if not s or s.dead then return false end
        if not s.grounded then airborne = true end
        if AutoInput.jump and (s.y <= releaseY or (airborne and (s.vy or 0) >= 0)) then
            AutoInput.jump = false
        end
        if s.y <= top + 0.25 then
            steerX(s, cx, 0.1)
        else
            steerX(s, e.fx + 0.5, 0.15)
        end
        if airborne and s.grounded then
            local nx, ny = floor(s.x), floor(s.y - 0.475)
            if ny == e.y then
                if nx == e.x and abs(s.x - cx) <= 0.25 then
                    AutoInput.jump = false
                    return true
                end
            else
                return false
            end
        end
        if not airborne and os.clock() - t0 > 0.35 then return false end
        if os.clock() - t0 > 1.8 then return false end
    end
    return false
end

-- Lompati lubang: ancang-ancang, lompat di ujung, rem di udara
local function execGap(e)
    if not execWalk(e.fx, e.fy) then return false end
    local s0 = playerState()
    if not s0 then return false end
    local dir = (e.x > e.fx) and 1 or -1
    local takeoff = e.fx + 0.5 + dir * 0.6
    local startY = s0.y
    local cx = e.x + 0.5
    releaseInput()
    local t0 = os.clock()
    local jumped, airborne, jumpAt = false, false, 0
    while frame() do
        local s = playerState()
        if not s or s.dead then return false end
        if not jumped then
            AutoInput.left, AutoInput.right = dir < 0, dir > 0
            if (s.x - takeoff) * dir >= 0 or not s.grounded then
                jumped, jumpAt = true, os.clock()
                AutoInput.jump = s.grounded
            end
        else
            if not s.grounded then airborne = true end
            if AutoInput.jump and (s.y <= startY - 1 or (airborne and (s.vy or 0) >= 0)) then
                AutoInput.jump = false
            end
            steerX(s, cx, 0.1)
            if airborne and s.grounded then
                local nx, ny = floor(s.x), floor(s.y - 0.475)
                if ny == e.y then
                    if nx == e.x and abs(s.x - cx) <= 0.25 then return true end
                else
                    return false
                end
            end
            if not airborne and os.clock() - jumpAt > 0.35 then return false end
        end
        if os.clock() - t0 > 2.2 then return false end
    end
    return false
end

-- Tangga lahan: naik 1-2 tile ke lorong setinggi 1 tile (lewat lubang tangga / keluar dari lubang).
-- Cara main manual: berdiri rapat ke sisi tujuan, lompat, tekan arah tujuan SETELAH badan naik
-- (kalau ditekan terlalu cepat badan masuk ke bawah block tujuan -> kepala kebentur -> jatuh),
-- saat kepala menempel atap lorong kaki sudah di atas block tujuan -> geser masuk. 3 cara dicoba.
function Move.execStair(e)
    if not execWalk(e.fx, e.fy) then return false end
    local dir = (e.x > e.fx) and 1 or -1
    local top = e.y + 1 -- tinggi kaki di tujuan (atas block pijakan)
    local hug = e.fx + 0.5 + dir * 0.17
    for try = 1, 3 do
        -- rapat ke dinding sisi tujuan
        local t0 = os.clock()
        while frame() do
            local s = playerState()
            if not s or s.dead then return false end
            steerX(s, hug, 0.03)
            if abs(s.x - hug) <= 0.06 and abs(s.vx or 0) < 1 then break end
            if os.clock() - t0 > 0.8 then break end
        end
        releaseInput()
        if not frame() then return false end
        local s0 = playerState()
        if not s0 then return false end
        local y0 = s0.y
        AutoInput.jump = true
        t0 = os.clock()
        local airborne, landed = false, nil
        while frame() do
            local s = playerState()
            if not s or s.dead then return false end
            if not s.grounded then airborne = true end
            if AutoInput.jump and (s.y <= top - 0.1 or (airborne and (s.vy or 0) >= 0)) then
                AutoInput.jump = false -- sudah setinggi tujuan / kena atap
            end
            -- Saat lompat di bawah atap lorong, kepala menempel di atap +-0.18 dtk dan kaki sudah di atas block
            -- tujuan: tekan arah di saat itu -> badan langsung masuk lorong (tidak perlu diangkat game).
            -- Tombol arah JANGAN ditekan di lantai: badan masuk ke bawah block tujuan -> kepala kebentur -> jatuh.
            -- coba 1: saat kaki sudah setinggi atas block tujuan (menempel atap)
            -- coba 2: setelah naik 0.15 tile (menempel sisi block, game mengangkat badan s/d 0.3 tile)
            -- coba 3: saat kaki 0.25 tile di bawah atas block
            local press = (try == 1 and s.y <= top + 0.02) or (try == 2 and s.y <= y0 - 0.15) or (try == 3 and s.y <= top + 0.25)
            if airborne and press then
                AutoInput.right, AutoInput.left = dir > 0, dir < 0
            else
                steerX(s, hug, 0.03)
            end
            if airborne and s.grounded then
                landed = floor(s.y - 0.475)
                break
            end
            if not airborne and os.clock() - t0 > 0.35 then break end
            if os.clock() - t0 > 1.8 then break end
        end
        releaseInput()
        if landed == e.y then
            return execWalk(e.x, e.y) -- sudah di lorong atas: ke tengah tile tujuan
        end
        if landed ~= nil and landed ~= e.fy then return false end -- jatuh ke tempat lain
        if not execWalk(e.fx, e.fy) then return false end
    end
    return false
end

-- Naik 1 tile: lompat, taruh block di bawah kaki, lalu mendarat di atasnya.
-- Block ditaruh agak telat supaya posisi di server sudah ikut naik.
local function execPillar(e)
    if not execWalk(e.fx, e.fy) then return false end
    if fgIdAt(e.fx, e.fy) ~= 0 then return false end
    releaseInput()
    if not frame() then return false end
    AutoInput.jump = true
    local t0 = os.clock()
    local placed, airborne = false, false
    while frame() do
        local s = playerState()
        if not s or s.dead then return false end
        if not s.grounded then airborne = true end
        steerX(s, e.fx + 0.5, 0.12)
        if AutoInput.jump and (s.y < e.fy - 0.9 or (airborne and (s.vy or 0) >= 0)) then
            AutoInput.jump = false
        end
        if not placed and airborne and s.y < e.fy - 0.25 and ((s.vy or 0) > -6 or s.y < e.fy - 0.8) then
            placed = placeScaffold(e.fx, e.fy)
            if not placed then return false end
        end
        if s.grounded and airborne then
            local nx, ny = floor(s.x), floor(s.y - 0.475)
            return placed and nx == e.x and ny == e.y
        end
        if not airborne and os.clock() - t0 > 0.35 then return false end
        if os.clock() - t0 > 1.8 then return false end
    end
    return false
end

local function followPath(path)
    local i = 1
    while i <= #path do
        if not autoOn() then return false end
        local e = path[i]
        local last, ok = i, false
        if e.kind == "walk" then
            -- langkah searah digabung jadi satu gerakan
            local dir = e.x - e.fx
            while path[last + 1] and path[last + 1].kind == "walk" and (path[last + 1].x - path[last + 1].fx) == dir do
                last += 1
            end
            local anyBuild = false
            for j = i, last do
                if path[j].build then
                    anyBuild = true
                    break
                end
            end
            if anyBuild then
                -- perlu block: taruh block di depan, lalu melangkah
                ok = true
                for j = i, last do
                    local st = path[j]
                    if st.build and not realSupport(st.x, st.y) then
                        setMoveStatus(("Taruh block pijakan (%d,%d)"):format(st.x, st.y + 1))
                        if not placeScaffold(st.x, st.y + 1) or not waitAuto(120) then
                            ok = false
                            break
                        end
                    end
                    if not execWalk(st.x, st.y) then
                        ok = false
                        break
                    end
                end
            else
                setMoveStatus(("Jalan ke (%d,%d)"):format(path[last].x, path[last].y))
                ok = execWalk(path[last].x, path[last].y)
            end
        elseif e.kind == "pillar" then
            setMoveStatus(("Naik pakai block ke (%d,%d)"):format(e.x, e.y))
            ok = execPillar(e)
        elseif e.kind == "fall" then
            setMoveStatus(("Turun ke (%d,%d)"):format(e.x, e.y))
            ok = execFall(e)
        elseif e.kind == "jump" then
            setMoveStatus(("Lompat ke (%d,%d)"):format(e.x, e.y))
            ok = execJump(e)
        elseif e.kind == "gap" then
            setMoveStatus(("Lompati lubang ke (%d,%d)"):format(e.x, e.y))
            ok = execGap(e)
        elseif e.kind == "stair" then
            setMoveStatus(("Naik tangga ke (%d,%d)"):format(e.x, e.y))
            ok = Move.execStair(e)
        end
        releaseInput()
        if not ok then
            -- hindari jalur ini sementara (tangga cuma sebentar, supaya tidak memutar jauh ke tangga lain)
            BadEdge[e.key] = os.clock() + ((e.kind == "stair") and 5 or 20)
            return false
        end
        i = last + 1
    end
    return true
end

-- Cari jalan ke grup target, lalu jalan ke sana
local function travelGroup(sx, sy, group, R, useBlock, skipTbl, failTbl)
    local w = Refs.World
    local goals = {}
    goals.maxY = group.maxY
    goals.los = group.los
    for _, t in ipairs(group) do goals[t.idx] = true end
    local first = group[1]
    setMoveStatus(("Cari jalan A* ke (%d,%d)"):format(first.x, first.y))
    local path, exhausted, closed = astar(sx, sy, goals, first.x, first.y, R, useBlock)
    if path then
        if #path == 0 then
            for _, t in ipairs(group) do skipTile(skipTbl, t.idx, 20) end
        elseif not followPath(path) then
            failTbl[first.idx] = (failTbl[first.idx] or 0) + 1
            if failTbl[first.idx] >= 3 then
                for _, t in ipairs(group) do skipTile(skipTbl, t.idx, 40) end
            end
        end
        releaseInput()
        return true
    end
    -- tidak ada jalan ke grup ini
    for _, t in ipairs(group) do skipTile(skipTbl, t.idx, exhausted and 60 or 30) end
    if exhausted and w then storeReach(sy * w.w + sx, R, useBlock, closed) end
    releaseInput()
    return false
end

-- ---------- Datangi drop yang belum terambil ----------
-- Hasil panen kadang jatuh di luar jangkauan collect. Drop dicari dari daftar drop game
-- (sama seperti Growscan), lalu karakter jalan mendekat (A*, tanpa pijakan) sampai drop
-- itu benar-benar terambil. Drop yang tidak ada jalannya dilewati sebentar.
-- Ambil drop di tile kerja dengan sentuhan badan (Auto Farm, Pabrik), tanpa remote.
-- Aturan game: drop terpungut kalau jaraknya < 0.6 tile dari tengah badan (mendatar) dan setinggi badan.
--   - tile sebaris (kiri / kanan, sampai 3 tile): disusuri sampai tile terjauh tiap sisi
--   - tile baris atas (kiri, tengah, kanan): berdiri di bawahnya lalu lompat kecil (tap); selama di udara
--     geser ke tile atas berikutnya yang masih ada drop-nya (bisa kena 2 sekaligus)
-- lalu balik lagi ke posisi kerja (hx, hy). Hasil: true = sudah balik ke posisi kerja.
function Drops.touchAll(tiles, hx, hy)
    local list = Drops.list
    if not list or not OrigIsDown then return false end
    local function dropsAt(t)
        for _, d in ipairs(list) do
            if type(d) == "table" and type(d.x) == "number" and (d.n or 0) > 0 and d.armed ~= false
                and not d.taking and inTile(t, d.x, d.y) then
                return true
            end
        end
        return false
    end
    local has = {}
    for _, t in ipairs(tiles) do
        if not solidAt(t.x, t.y) and dropsAt(t) then has[#has + 1] = t end
    end
    if #has == 0 then return false end
    local s0 = playerState()
    if not s0 or s0.dead or not s0.grounded then return false end
    local function ground(c) return openAt(c, hy) and realSupport(c, hy) end
    local function walkable(a, b)
        local st = (b >= a) and 1 or -1
        for c = a, b, st do
            if not ground(c) then return false end
        end
        return true
    end
    local was = AutoInput.active
    AutoInput.active = true
    local function moveTo(cx, maxT)
        local t0 = os.clock()
        while alive() and os.clock() - t0 < (maxT or 1.2) do
            task.wait()
            local c = playerState()
            if not c or c.dead then break end
            steerX(c, cx, 0.1)
            if c.grounded and abs(c.x - cx) <= 0.15 and abs(c.vx or 0) < 1.5 then
                AutoInput.left, AutoInput.right = false, false
                return true
            end
        end
        AutoInput.left, AutoInput.right = false, false
        return false
    end
    -- lompat kecil (tap = naik +-1.4 tile, tidak sampai naik ke atas baris block), di udara geser ke toX
    local function hop(toX)
        AutoInput.left, AutoInput.right = false, false
        local c0 = playerState()
        if not c0 then return end
        local y0 = c0.y
        AutoInput.jump = true
        local t0, air = os.clock(), false
        while alive() and os.clock() - t0 < 1.4 do
            task.wait()
            local c = playerState()
            if not c or c.dead then break end
            if not c.grounded then
                air = true
                AutoInput.jump = false -- tap: lepas begitu lepas dari tanah
            end
            if toX and air and c.y <= y0 - 0.25 then steerX(c, toX, 0.1) else AutoInput.left, AutoInput.right = false, false end
            if air and c.grounded then break end
            if not air and os.clock() - t0 > 0.35 then break end
        end
        AutoInput.jump, AutoInput.left, AutoInput.right = false, false, false
    end
    -- baris badan: susuri sampai tile terjauh tiap sisi
    local lo, hi = hx, hx
    for _, t in ipairs(has) do
        if t.y == hy and abs(t.x - hx) <= 3 then
            if t.x < lo then lo = t.x end
            if t.x > hi then hi = t.x end
        end
    end
    if lo < hx and walkable(hx - 1, lo) then moveTo(lo + 0.5) end
    if hi > hx and walkable(hx + 1, hi) then moveTo(hi + 0.5) end
    -- baris atas: lompat di bawah tile yang masih ada drop-nya (maks 4 lompatan)
    for _ = 1, 4 do
        local cs = playerState()
        if not cs or not alive() then break end
        local cur = floor(cs.x)
        local cols = {}
        for _, t in ipairs(has) do
            if t.y == hy - 1 and abs(t.x - hx) <= 1 and ground(t.x) and walkable(cur, t.x)
                and not solidAt(t.x, t.y) and dropsAt(t) then
                cols[#cols + 1] = t.x
            end
        end
        if #cols == 0 then break end
        table.sort(cols, function(p, q) return abs(p - cur) < abs(q - cur) end)
        local a = cols[1]
        if a ~= cur then moveTo(a + 0.5) end
        hop(cols[2] and (cols[2] + 0.5) or nil) -- sambil geser ke tile berikutnya
    end
    -- balik ke posisi kerja
    local ok = moveTo(hx + 0.5, 2)
    AutoInput.left, AutoInput.right, AutoInput.jump = false, false, false
    AutoInput.active = was
    waitNearDrops(0.2)
    return ok
end

function Drops.touch(t, hx, hy)
    return Drops.touchAll({ t }, hx, hy)
end

-- Remote cuma bisa sampai jangkauan server (State.RemoteReach). Drop yang lebih jauh dijemput:
-- karakter jalan mendekat sampai masuk jangkauan, Remote mengambilnya, lalu balik ke posisi semula.
-- Hanya drop sebaris dengan badan, jalurnya harus bisa dilewati, dan hanya kalau tidak ada fitur lain yang menggerakkan karakter.
-- JEMPUT CEPAT: semua drop jauh di baris yang sama diambil dalam SATU kali jalan (tidak pulang dulu
-- tiap 1 drop), dan karakter langsung lanjut begitu drop terambil (tidak menunggu jeda tetap).
-- more = daftar drop jauh lain dari Drops.remoteTick (boleh kosong).
-- touch = true (mode Jemput): tanpa Remote, karakter berjalan sampai badan menyentuh drop.
function Drops.chaseFar(d, more, touch)
    if Drops.chasing or not OrigIsDown then return end
    if type(d) ~= "table" or type(d.x) ~= "number" or type(d.y) ~= "number" then return end
    local s0 = playerState()
    if not s0 or s0.dead or not s0.grounded then return end
    local by = s0.y - 0.475
    if abs(d.y - by) > 1.2 then
        DropFailUntil[d.uid] = os.clock() + 5 -- beda baris: tidak dijemput
        return
    end
    local hy = floor(by)
    local function pathOk(fromX, toX)
        local c0, c1 = floor(fromX), floor(toX)
        for c = c0, c1, (c1 >= c0) and 1 or -1 do
            if not (openAt(c, hy) and realSupport(c, hy)) then return false end
        end
        return true
    end
    if not pathOk(s0.x, d.x) then
        DropFailUntil[d.uid] = os.clock() + 5 -- jalur tidak bisa dilewati
        return
    end
    Drops.chasing = true
    local homeX = s0.x
    local was = AutoInput.active
    -- Remote: berhenti sedikit di dalam jangkauan. Sentuhan: sampai badan menyentuh drop (< 0.6 tile)
    local reach = touch and 0.3 or math.max(0.5, (State.RemoteReach or 2) - 0.6)

    -- drop sudah terambil? (jumlah jadi 0, atau hilang dari daftar drop game)
    local function gone(t)
        if t.n ~= nil and t.n <= 0 then return true end
        local list = Drops.list
        return type(list) == "table" and table.find(list, t) == nil
    end

    -- jalan sampai drop masuk jangkauan, lalu tunggu HANYA sampai drop terambil
    local function goTake(t)
        local t0 = os.clock()
        while alive() and os.clock() - t0 < 2.5 do
            task.wait()
            local c = playerState()
            if not c or c.dead then return false end
            if gone(t) then return true end
            if abs(t.x - c.x) <= reach then break end
            steerX(c, touch and t.x or (t.x + ((c.x > t.x) and 1 or -1) * reach * 0.8), 0.1)
        end
        AutoInput.left, AutoInput.right = false, false
        local t1 = os.clock()
        local maxWait = touch and 0.6 or 0.45
        while alive() and os.clock() - t1 < maxWait and not gone(t) do task.wait() end
        if not gone(t) and t.uid ~= nil then
            -- masih ada (tas penuh / drop sendiri / ditolak): jangan dijemput terus-terusan
            DropFailUntil[t.uid] = os.clock() + (touch and 15 or 3)
        end
        return true
    end

    local function run()
        AutoInput.active = true
        local tStart = os.clock()
        local alive0 = goTake(d)
        -- drop jauh lainnya di baris ini: sisi yang sama dulu (terdekat -> terjauh), baru sisi sebaliknya
        if alive0 and type(more) == "table" then
            local side = (d.x >= homeX) and 1 or -1
            local rest = {}
            for _, e in ipairs(more) do
                if e ~= d and type(e) == "table" and type(e.x) == "number" and type(e.y) == "number"
                    and not gone(e) and abs(e.y - by) <= 1.2 then
                    rest[#rest + 1] = e
                end
            end
            table.sort(rest, function(p, q)
                local sp = ((p.x - homeX) * side >= 0) and 0 or 1
                local sq = ((q.x - homeX) * side >= 0) and 0 or 1
                if sp ~= sq then return sp < sq end
                return abs(p.x - homeX) < abs(q.x - homeX)
            end)
            local n = 0
            for _, e in ipairs(rest) do
                if n >= 6 or os.clock() - tStart > 6 then break end
                local c = playerState()
                if not c or c.dead then break end
                if not gone(e) and pathOk(c.x, e.x) then
                    n += 1
                    if not goTake(e) then break end
                end
            end
        end
        local t1 = os.clock()
        while alive() and os.clock() - t1 < 3.5 do
            task.wait()
            local c = playerState()
            if not c or c.dead then break end
            steerX(c, homeX, 0.15)
            if c.grounded and abs(c.x - homeX) <= 0.2 and abs(c.vx or 0) < 1.5 then break end
        end
    end
    local ok, err = pcall(run)
    AutoInput.left, AutoInput.right, AutoInput.jump = false, false, false
    AutoInput.active = was
    Drops.chasing = false
    if not ok then warn("[SkyP] jemput drop: " .. tostring(err)) end
end

-- MODE COLLECT "JEMPUT": tanpa Remote. Drop di sekitar karakter (dalam Radius collect, sebaris dengan badan)
-- didatangi dengan berjalan sampai tersentuh badan, semuanya sekali jalan, lalu karakter pulang ke posisi awal.
-- Hanya saat "Collect di sekitar karakter" nyala dan tidak ada fitur lain yang sedang menggerakkan karakter.
function Drops.fetchTick(list, s)
    if Drops.chasing or State.CollectAround ~= true then return end
    if Clear.Running or Farmer.Running or Pabrik.Running or Splice.Running
        or Splice.Roaming or Vend.Running or State.Running or (Session.RT and Session.RT.Running) then return end
    local now = os.clock()
    if now < (Drops.fetchAt or 0) then return end
    Drops.fetchAt = now + 0.3
    local cx, cy = s.x, s.y - 0.475
    local R = (State.CollectRadius or 3) + 0.2
    local z = Pabrik.Zone -- tempat drop pabrik tidak ikut diambil lagi
    if z and z.world ~= (Refs.World and rawget(Refs.World, "name")) then z = nil end
    local best, bestDist, all = nil, nil, {}
    for _, d in ipairs(list) do
        if type(d) == "table" and type(d.x) == "number" and type(d.y) == "number"
            and (d.n == nil or d.n > 0)
            and now >= ((d.uid ~= nil and DropFailUntil[d.uid]) or 0)
            and not (z and abs(d.x - z.x) <= 2.5 and abs(d.y - z.y) <= 2.5) then
            local dx = abs(d.x - cx)
            if dx > 0.5 and dx <= R and abs(d.y - cy) <= 1.2 then
                all[#all + 1] = d
                if not bestDist or dx < bestDist then best, bestDist = d, dx end
            end
        end
    end
    if best then task.spawn(Drops.chaseFar, best, all, true) end
end

-- Tile yang barusan pecah: drop-nya datang dari server (sesuai ping). Tunggu sampai drop baru
-- muncul di tile itu (atau batas waktu), supaya tidak keburu ketimpa block baru / tidak tersentuh.
function Drops.waitSpawn(tiles)
    local ping = 0.1
    pcall(function() ping = LocalPlayer:GetNetworkPing() end)
    local limit = math.clamp(0.15 + 2.5 * ping, 0.25, 0.8)
    local newest = nil
    for _, t in ipairs(tiles) do
        local b = Drops.brokeAt[t.x .. "," .. t.y]
        if b and os.clock() - b < limit and (not newest or b > newest) then newest = b end
    end
    if not newest then return end
    local list = Drops.list
    while os.clock() - newest < limit and alive() do
        if list then
            for _, d in ipairs(list) do
                if type(d) == "table" and type(d.x) == "number" and (d.born or 0) >= newest then
                    for _, t in ipairs(tiles) do
                        if inTile(t, d.x, d.y) then
                            task.wait(0.05) -- drop lain dari pecahan yang sama
                            return
                        end
                    end
                end
            end
        end
        task.wait()
    end
end

-- Datangi 1 drop sampai terambil (berdiri di tile drop-nya; kalau tile itu tidak bisa dipijak,
-- misal lubang tangga: berdiri tepat di bawahnya lalu lompat sekali). Hasil: true = terambil.
function Move.visitDrop(d)
    local w = Refs.World
    local s = playerState()
    if not w or not s then return false, "nopath" end
    local W = w.w
    local tx, ty = floor(d.x), floor(d.y)
    if solidAt(tx, ty) then return false, "nopath" end -- terkubur di dalam block: tidak bisa disentuh
    local sx, sy = startNode(s)
    local goal = { [ty * W + tx] = true }
    local path = astar(sx, sy, goal, tx, ty, 0.5, false)
    if not path and ty + 1 < w.h then
        path = astar(sx, sy, { [(ty + 1) * W + tx] = true }, tx, ty + 1, 0.5, false)
    end
    if not path then path = astar(sx, sy, goal, tx, ty, 1.2, false) end
    if not path then return false, "nopath" end
    if #path > 0 then
        local ok = followPath(path)
        releaseInput()
        if not ok then return false, "nopath" end
    end
    local ping = 0.1
    pcall(function() ping = LocalPlayer:GetNetworkPing() end)
    waitNearDrops(math.clamp(0.6 + 3 * ping, 1, 2.5))
    local function left() return (d.n or 0) > 0 and table.find(Drops.list or {}, d) ~= nil end
    local cur = playerState()
    if left() and cur and cur.grounded and abs(d.x - cur.x) <= 0.9 and d.y < cur.y - 0.9 and d.y > cur.y - 2.6 then
        -- drop di atas kepala: lompat sekali supaya kena badan
        AutoInput.active = true
        AutoInput.jump = true
        task.wait(0.25)
        AutoInput.jump = false
        local t0 = os.clock()
        repeat
            task.wait(0.05)
            local c = playerState()
        until not c or c.grounded or os.clock() - t0 > 1.5
        waitNearDrops(0.5)
    end
    if left() then return false, "left" end
    return true
end

-- Susuri 1 baris (tile badan ry) dari kolom xa ke xb tanpa berhenti di tiap drop:
-- drop di jalan terambil sambil lewat, sama seperti main manual.
function Move.walkRow(ry, xa, xb)
    local w = Refs.World
    if not w then return false end
    for _, tx in ipairs({ xa, xb }) do
        local s = playerState()
        if not s or s.dead then return false end
        local sx, sy = startNode(s)
        if not (sx == tx and sy == ry) then
            local goal = { [ry * w.w + tx] = true }
            local path = astar(sx, sy, goal, tx, ry, 0.5, false) or astar(sx, sy, goal, tx, ry, 1.2, false)
            if not path then
                releaseInput()
                return false
            end
            if #path > 0 and not followPath(path) then
                releaseInput()
                return false
            end
        end
    end
    releaseInput()
    return true
end

-- Ambil drop yang belum terambil, PER BARIS (seperti main manual):
--   pilih drop terdekat (baris sendiri didahulukan), lalu susuri baris itu dari ujung terdekat
--   ke ujung lainnya tanpa berhenti. Yang masih tertinggal (mis. di lubang tangga) baru didatangi
--   satu-satu, dan yang tetap tidak terambil tidak dicoba lagi sebentar.
-- filter(d) = true: drop ini boleh diambil (nil = semua). maxSec = batas waktu (20 dtk).
Move.FetchFail = {}
function Move.fetchDrops(live, maxDist, filter, maxSec)
    local list = Drops.list
    local w = Refs.World
    if not list or not w then return 0 end
    maxDist = maxDist or 8
    local got, t0 = 0, os.clock()
    local function want(d, now)
        if not (canTry(d, now) and d.id) then return false end
        if Move.FetchFail[d.uid] and now < Move.FetchFail[d.uid] then return false end
        if solidAt(floor(d.x), floor(d.y)) then -- terkubur di dalam block: tidak bisa disentuh
            Move.FetchFail[d.uid] = now + 300
            return false
        end
        local z = Pabrik.Zone
        if z and not Move.NoZone and z.world == rawget(w, "name") and abs(d.x - z.x) <= 2.5 and abs(d.y - z.y) <= 2.5 then
            return false
        end
        if filter and not filter(d) then return false end
        if d.id ~= 112 and Refs.Inv then -- inventori penuh: tidak usah diambil
            local okr, r = pcall(function() return Refs.Inv:room(d.id) end)
            if okr and type(r) == "number" and r <= 0 then return false end
        end
        return true
    end
    while live() and alive() and os.clock() - t0 < (maxSec or 20) do
        local s = playerState()
        if not s or s.dead then break end
        if not s.grounded then
            task.wait(0.05)
            continue
        end
        local cx, cy = s.x, s.y - 0.475
        local now = os.clock()
        local best, bd = nil, nil
        for _, d in ipairs(list) do
            if want(d, now) then
                local dx, dy = d.x - cx, d.y - cy
                if abs(dx) <= maxDist and abs(dy) <= maxDist and (abs(dx) >= 0.6 or abs(dy) >= 0.75) then
                    local dd = dx * dx + 9 * dy * dy -- baris sendiri didahulukan
                    if not bd or dd < bd then best, bd = d, dd end
                end
            end
        end
        if not best then break end
        local ry = floor(best.y)
        if best.x < 0 or ry < 0 or best.x >= w.w or ry >= w.h then
            Move.FetchFail[best.uid] = now + 30
        else
            -- semua drop di baris itu: susuri dari ujung terdekat ke ujung lainnya
            local inRow, lo, hi = {}, best.x, best.x
            for _, d in ipairs(list) do
                if floor(d.y) == ry and abs(d.x - cx) <= maxDist and want(d, now) then
                    inRow[#inRow + 1] = d
                    if d.x < lo then lo = d.x end
                    if d.x > hi then hi = d.x end
                end
            end
            local xa, xb = floor(lo), floor(hi)
            if abs(hi - cx) < abs(lo - cx) then xa, xb = xb, xa end
            setMoveStatus(("Ambil drop baris y %d (x %d-%d)"):format(ry, math.min(xa, xb), math.max(xa, xb)))
            local ok = Move.walkRow(ry, xa, xb)
            -- pungutan dikirim ke server: tunggu balasannya (ping) sebelum menilai drop tertinggal
            local ping = 0.1
            pcall(function() ping = LocalPlayer:GetNetworkPing() end)
            local tw = os.clock()
            repeat
                task.wait(0.05)
                local busy = false
                for _, d in ipairs(inRow) do
                    if d.taking then
                        busy = true
                        break
                    end
                end
            until not busy or os.clock() - tw > math.clamp(0.3 + 3 * ping, 0.5, 2.5)
            got += 1
            Move.FetchTry = Move.FetchTry or {}
            for _, d in ipairs(inRow) do
                if (d.n or 0) > 0 and table.find(list, d) then
                    local okv, why = false, "nopath"
                    if ok then okv, why = Move.visitDrop(d) end
                    if not okv then
                        local tries = (Move.FetchTry[d.uid] or 0) + 1
                        Move.FetchTry[d.uid] = tries
                        if why == "left" and tries < 4 then
                            Move.FetchFail[d.uid] = os.clock() + 1.5 -- sudah didatangi (balasan server telat / sisa sebagian): coba lagi sebentar lagi
                        else
                            Move.FetchFail[d.uid] = os.clock() + 30 -- tidak ada jalan / tetap tidak terambil
                        end
                    else
                        Move.FetchTry[d.uid] = nil
                    end
                end
            end
        end
    end
    releaseInput()
    return got
end

local function autoBegin()
    AutoInput.active = true
    releaseInput()
    Reach = nil
    if Misc.Ghost then
        setGhost(false) -- fly dimatikan (kena rollback)
        if UI.GhostToggle then pcall(function() UI.GhostToggle:Set(false) end) end
    end
end

local function autoEnd()
    if Clear.Running or Farmer.Running or Splice.Roaming or Pabrik.Running or Move.Homing
        or Vend.Running then
        return
    end
    AutoInput.active = false
    releaseInput()
end

local function blockText(useBlock, id)
    if not useBlock then return "mati" end
    if not id then return "belum dipilih" end
    local n = invCount(id)
    return itemName(id) .. " x" .. n .. (n <= 0 and " (habis)" or "")
end

---------------------------------------------------------------------
-- CLEAR WORLD: bersihkan dari baris atas ke bawah, 2 baris sekali sapu
---------------------------------------------------------------------
-- Boleh dipecah? (lock, vending, display tidak disentuh)
local function clearCanBreak(id)
    if not id or id == 0 then return false end
    local it = ItemDB[id]
    if not it then return false end
    if it.lock or it.area or it.guildLock or it.vend or it.display then return false end
    local h = (it.kind == "seed") and 20 or it.hits
    if type(h) == "number" and h > 0 then return true end
    local w = Refs.World
    return (it.staffHits and w and w.areas and w.areas.staff) and true or false
end

-- Layer yang dipecah: fg dulu, lalu bg
local function clearLayerAt(x, y)
    local w = Refs.World
    local sp = w and w.spawn
    if sp ~= nil and (typeof(sp) == "Vector2" or type(sp) == "table") and x == sp.X and y == sp.Y then
        return nil
    end
    local fg = tileAt("fg", x, y)
    if fg == nil then return nil end
    if fg ~= 0 then
        if clearCanBreak(fg) then return "fg", fg end
        return nil -- fg tidak bisa dipecah, bg juga tidak
    end
    if Clear.IncludeBg then
        local bg = tileAt("bg", x, y)
        if bg and bg ~= 0 and clearCanBreak(bg) then return "bg", bg end
    end
    return nil
end

-- Cari baris paling atas yang masih ada block
local function scanTopRow()
    local w = Refs.World
    local W, H = w.w, w.h
    local now = os.clock()
    for y = 0, H - 1 do
        local frow, brow = w.fg[y], w.bg[y]
        for x = 0, W - 1 do
            local fid = frow and frow[x] or 0
            local bid = brow and brow[x] or 0
            if (fid ~= 0 or (Clear.IncludeBg and bid ~= 0)) and clearLayerAt(x, y)
                and not skipped(Clear.Skip, y * W + x, now) then
                return y
            end
        end
    end
    return nil
end

local function countRemaining()
    local w = Refs.World
    if not w then return -1 end
    local W, H = w.w, w.h
    local n, scanned = 0, 0
    for y = 0, H - 1 do
        local frow, brow = w.fg[y], w.bg[y]
        for x = 0, W - 1 do
            local fid = frow and frow[x] or 0
            local bid = brow and brow[x] or 0
            if (fid ~= 0 or (Clear.IncludeBg and bid ~= 0)) and clearLayerAt(x, y) then n += 1 end
        end
        scanned += W
        if scanned >= 8000 then
            scanned = 0
            task.wait()
        end
    end
    return n
end

-- Arah sapu. Zig-zag: arah dipilih sekali per baris (dari ujung terdekat),
-- lalu dipegang sampai baris selesai supaya tidak bolak-balik.
local function bandDir(topRow, s)
    if Clear.Sweep ~= "Zig-zag" then return 1 end
    if Clear.DirRow == topRow and Clear.Dir then return Clear.Dir end
    local w = Refs.World
    local now = os.clock()
    local minX, maxX
    for y = topRow, math.min(topRow + 1, w.h - 1) do
        for x = 0, w.w - 1 do
            if clearLayerAt(x, y) and not skipped(Clear.Skip, y * w.w + x, now) then
                if not minX or x < minX then minX = x end
                if not maxX or x > maxX then maxX = x end
            end
        end
    end
    local dir = 1
    if minX and maxX and abs(s.x - maxX) < abs(s.x - minX) then dir = -1 end
    Clear.DirRow, Clear.Dir = topRow, dir
    return dir
end

-- Semua target di baris ini, urut sesuai arah sapu.
-- Tile yang tidak terjangkau langsung dilewati.
local function bandTargets(top, bottom, dir, filter)
    local w = Refs.World
    local W = w.w
    local list = {}
    local now = os.clock()
    for y = top, math.min(bottom, w.h - 1) do
        for x = 0, W - 1 do
            local idx = y * W + x
            if clearLayerAt(x, y) and not skipped(Clear.Skip, idx, now) then
                if filter and not filter[idx] then
                    skipTile(Clear.Skip, idx, 60) -- di seberang jurang / tidak ada jalan
                elseif canWorkAt(x, y) then
                    list[#list + 1] = { x = x, y = y, idx = idx }
                else
                    skipTile(Clear.Skip, idx, 300) -- tidak ada izin
                end
            end
        end
    end
    table.sort(list, function(a, b)
        if a.x ~= b.x then return a.x * dir < b.x * dir end
        return a.y < b.y
    end)
    return list
end

-- Tile yang bisa dipukul dari sini. Pijakan kaki dipecah paling akhir.
local function clearInReach(s, bottom, dir)
    local w = Refs.World
    local W = w.w
    local R = punchReach() - 0.08
    local cx, cy = s.x, s.y - 0.475
    local footRow = floor(s.y + 0.01)
    local colA, colB = floor(s.x - 0.3), floor(s.x + 0.3 - 0.0001)
    local now = os.clock()
    local list = {}
    for ty = math.max(0, floor(cy - R - 0.5)), math.min(floor(cy + R + 0.5), bottom, w.h - 1) do
        for tx = math.max(0, floor(cx - R - 0.5)), math.min(floor(cx + R + 0.5), W - 1) do
            if stateReaches(s, tx, ty, R) then
                local idx = ty * W + tx
                if not skipped(Clear.Skip, idx, now) and clearLayerAt(tx, ty) then
                    if canWorkAt(tx, ty) then
                        list[#list + 1] = {
                            x = tx, y = ty, idx = idx,
                            support = (ty == footRow and tx >= colA and tx <= colB),
                        }
                    else
                        skipTile(Clear.Skip, idx, 300)
                    end
                end
            end
        end
    end
    table.sort(list, function(a, b)
        if a.support ~= b.support then return not a.support end
        if a.x ~= b.x then return a.x * dir < b.x * dir end
        return a.y < b.y
    end)
    return list
end

-- Kalau pijakan dipecah, jatuh berapa tile? (nil = jatuh ke lava/duri)
local function fallAfterBreak(s, x, footRow)
    local colA, colB = floor(s.x - 0.3), floor(s.x + 0.3 - 0.0001)
    for c = colA, colB do
        if c ~= x and (solidAt(c, footRow) or platformAt(c, footRow)) then return 0 end -- masih menapak kolom lain
    end
    local w = Refs.World
    for y = footRow + 1, math.min(w.h - 1, footRow + 60) do
        if hazardAt(x, y) then return nil end
        if solidAt(x, y) or platformAt(x, y) then return y - footRow end
    end
    return 60
end

-- Pukul satu tile sampai bersih (fg lalu bg)
local function clearBreakTile(t)
    local x, y, idx = t.x, t.y, t.idx
    local layer, id = clearLayerAt(x, y)
    if not layer then return end
    local hits, maxHits = 0, hitsNeeded(id) * 3 + 6
    while Clear.Running and alive() do
        layer, id = clearLayerAt(x, y)
        if not layer then return end
        local r = tryBreak(x, y, Clear.IncludeBg)
        if r == nil then
            skipTile(Clear.Skip, idx, 60)
            return
        end
        if r == "broke" then
            Clear.Broken += 1
            Clear.Status = "Pecah " .. itemName(id) .. " (" .. x .. "," .. y .. ")"
            BreakTimes[idx] = (BreakTimes[idx] or 0) + 1
            if BreakTimes[idx] > 6 then -- server terus mengembalikan tile ini
                skipTile(Clear.Skip, idx, 120)
                return
            end
            hits = 0
            local _, nid = clearLayerAt(x, y)
            if nid then maxHits = hitsNeeded(nid) * 3 + 6 end
        else
            hits += 1
            Clear.Status = "Pukul " .. itemName(id) .. " (" .. x .. "," .. y .. ")"
            if hits > maxHits then
                skipTile(Clear.Skip, idx, 45)
                return
            end
        end
        if not waitAuto(State.BreakMs) then return end
        if r == "broke" then
            local s = playerState()
            if not s or not s.grounded then return end -- jatuh, cek ulang posisi
        end
    end
end

local function clearBreakList(list, s0)
    local footY = floor(s0.y - 0.475)
    local R = punchReach() - 0.08
    local done = 0
    for _, t in ipairs(list) do
        if not Clear.Running or not alive() then break end
        local s = playerState()
        if not s or s.dead or not stateReaches(s, t.x, t.y, R) then break end
        if not s.grounded or floor(s.y - 0.475) ~= footY then break end
        local skipIt = false
        if t.support then
            local d = fallAfterBreak(s, t.x, floor(s.y + 0.01))
            if d == nil then
                skipIt = true
                Clear.Status = ("Lewati (%d,%d): di bawahnya berbahaya"):format(t.x, t.y)
            elseif d > 3 then
                -- di bawahnya jurang: pecah nanti dari samping
                skipIt = true
                Clear.Status = ("Lewati pijakan (%d,%d): di bawahnya jurang"):format(t.x, t.y)
            end
        end
        if skipIt then
            skipTile(Clear.Skip, t.idx, 20)
        else
            clearBreakTile(t)
            done += 1
        end
    end
    return done
end

local lastClearText = nil
local function updateClearStatus()
    if not UI.ClearStatus then return end
    local txt = "Status   : " .. (Clear.Running and "JALAN" or "BERHENTI")
        .. "\nBaris    : " .. (Clear.TopRow >= 0 and (Clear.TopRow .. "-" .. (Clear.TopRow + 1)) or "-")
        .. "  | arah: " .. ((Clear.Dir == -1 and Clear.Sweep == "Zig-zag") and "kanan→kiri" or "kiri→kanan")
        .. "\nDipecah  : " .. Clear.Broken .. "  | collect: " .. State.Collected
        .. "\nSisa     : " .. (Clear.Remaining >= 0 and tostring(Clear.Remaining) or "-")
        .. "  | dilewati: " .. skippedCount(Clear.Skip)
        .. "\nPijakan  : " .. blockText(Clear.UseBlock, Clear.ScaffoldId) .. "  | dipasang: " .. Move.Placed
        .. "\nAksi     : " .. Clear.Status
    if txt == lastClearText then return end
    lastClearText = txt
    task.defer(function()
        pcall(function() UI.ClearStatus:SetDesc(txt) end)
    end)
end

local function clearLoop()
    local idle, lastUi, lastCount = 0, 0, -10
    while Clear.Running and alive() do
        task.wait()
        local now = os.clock()
        if now - lastCount > 3 then
            lastCount = now
            Clear.Remaining = countRemaining()
            if not Clear.Running or not alive() then break end
        end
        if now - lastUi > 0.5 then
            lastUi = now
            updateClearStatus()
        end
        local w = Refs.World
        local s = playerState()
        if not w or not s or s.dead then
            releaseInput()
            Clear.Status = "Menunggu karakter / world..."
            task.wait(0.5)
            continue
        end
        if not s.grounded then
            releaseInput() -- masih di udara, tunggu mendarat
            continue
        end
        releaseInput()

        local topRow = scanTopRow()
        if not topRow then
            local remaining = countRemaining()
            Clear.Remaining = remaining
            if remaining == 0 then
                stopClear("World sudah bersih!")
                return
            end
            idle += 1
            if idle >= 3 then
                stopClear(("Selesai. Sisa %d tile tidak bisa dijangkau / dipecah"):format(remaining))
                return
            end
            Clear.Status = ("Sisa %d tile dilewati, coba ulang (%d/3)..."):format(remaining, idle)
            updateClearStatus()
            table.clear(Clear.Skip)
            table.clear(ClearFail)
            table.clear(BadEdge)
            Reach = nil
            if not waitAuto(2000) then break end
            continue
        end

        Clear.TopRow = topRow
        local bottom = topRow + 1 -- 2 baris dibersihkan dulu sebelum turun
        local dir = bandDir(topRow, s)

        -- 1) Pecahkan yang terjangkau
        local list = clearInReach(s, bottom, dir)
        if #list > 0 then
            if clearBreakList(list, s) > 0 then idle = 0 end
            continue
        end

        -- 2) Ambil drop di sekitar dengan menyusurinya (sentuhan badan), lalu jalan ke bagian berikutnya
        if Clear.Collect then
            local band0 = topRow - 1
            if Move.fetchDrops(function() return Clear.Running end, 5, function(d)
                return d.y >= band0 and d.y < bottom + 2
            end, 8) > 0 then
                continue
            end
        end
        local R = punchReach() - 0.35
        local useBlock = scaffoldId() ~= nil
        local sx, sy = startNode(s)
        local band = bandTargets(topRow, bottom, dir, reachFilter(sy * w.w + sx, R, useBlock))
        if #band > 0 then
            -- tujuan: 5 kolom berikutnya sesuai arah sapu
            local group = {}
            for _, t in ipairs(band) do
                if (t.x - band[1].x) * dir <= 4 then group[#group + 1] = t end
            end
            travelGroup(sx, sy, group, R, useBlock, Clear.Skip, ClearFail)
        end
    end
    releaseInput()
end

local function setClearVisual()
    if UI.ClearToggle then pcall(function() UI.ClearToggle:Set(Clear.Running) end) end
end

stopClear = function(reason)
    Clear.Running = false
    autoEnd()
    setClearVisual()
    Clear.Status = reason or "Dihentikan"
    if reason then
        notify("Auto Clear", reason, 5)
        if not string.find(reason, "^Dihentikan") then Hook.send("stop", "Auto Clear berhenti: " .. reason) end
    end
    updateClearStatus()
end

local function checkAutoStart()
    if not Refs.World then return "Data world belum ketemu. Tekan 'Hubungkan ke game'" end
    if not Refs.Punch then return "Fungsi pukul game belum ketemu. Tekan 'Hubungkan ke game'" end
    if not OrigIsDown then return "Kontrol gerak game (WorldMenu.isDown) tidak ketemu" end
    if not playerState() then return "Kamu belum masuk world" end
    return nil
end

local function startClear()
    if Clear.Running then return end
    local err = checkAutoStart()
    if err then
        notify("Auto Clear", err, 4)
        setClearVisual()
        return
    end
    if Clear.UseBlock and (not Clear.ScaffoldId or invCount(Clear.ScaffoldId) <= 0) then
        notify("Auto Clear", "Block pijakan belum dipilih / habis: jalan tanpa block pijakan", 5)
    end
    if Splice.Running and Splice.stop then Splice.stop("Dihentikan karena Auto Clear dimulai") end
    if Pabrik.Running and Pabrik.stop then Pabrik.stop("Dihentikan karena Auto Clear dimulai") end
    if State.Running then stopFarm("Dihentikan karena Auto Clear dimulai") end
    if Farmer.Running then stopFarmer("Dihentikan karena Auto Clear dimulai") end
    table.clear(Clear.Skip)
    table.clear(ClearFail)
    table.clear(BadEdge)
    table.clear(BreakTimes)
    Clear.Broken = 0
    Clear.Remaining = -1
    Clear.TopRow = -1
    Clear.DirRow, Clear.Dir = nil, nil
    Clear.Status = "Mulai..."
    Clear.Running = true
    autoBegin()
    setClearVisual()
    updateClearStatus()
    task.spawn(function()
        local ok, e = pcall(clearLoop)
        if not ok then
            warn("[SkyP] Auto Clear error: " .. tostring(e))
            if Clear.Running then stopClear("Error: " .. tostring(e)) end
        end
    end)
end

---------------------------------------------------------------------
-- FARMER: panen pohon yang siap + tanam seed
---------------------------------------------------------------------
-- Pohon siap kalau: waktu server >= waktu tanam + lama tumbuh (sama dengan game).
-- Seed ditanam di tile kosong yang di bawahnya ada block.
local function findTreeRefs()
    Refs.Trees, Refs.TreeMode, Refs.TreeP = nil, nil, nil
    -- 1) cara utama (game v1159+): ikuti fungsi World.tileChanged -> fungsi simpan pohon.
    --    Tetap jalan walau world belum punya pohon (tabel kosong).
    local okS, foundS = pcall(function() return Auto.findTreesStruct and Auto.findTreesStruct() end)
    if okS and foundS == true then return true end
    Refs.Trees, Refs.TreeMode, Refs.TreeP = nil, nil, nil
    -- 2) game lama: handler remote WorldRemotes.TreeChanged
    local ev = WorldRemotes:FindFirstChild("TreeChanged")
    if ev and ev:IsA("RemoteEvent") and getconnections then
        local ok, conns = pcall(getconnections, ev.OnClientEvent)
        if ok and type(conns) == "table" then
            for _, c in ipairs(conns) do
                local okf, fn = pcall(function() return c.Function end)
                if okf and type(fn) == "function" then
                    for _, u in pairs(getUpvalues(fn)) do
                        if type(u) == "table" and u ~= Refs.World and rawget(u, "fg") == nil then
                            local _, v = next(u)
                            if type(v) == "table" and type(rawget(v, "p")) == "number" then
                                Refs.Trees, Refs.TreeMode, Refs.TreeP = u, "idx", "p"
                                break
                            end
                        end
                    end
                end
                if Refs.Trees then return true end
            end
        end
    end
    -- 3) cadangan: telusuri upvalue lebih dalam (butuh world yang sudah ada pohonnya)
    if Auto.findTreesDeep then pcall(Auto.findTreesDeep) end
    return Refs.Trees ~= nil
end

-- Tabel ini cocok jadi data pohon? Kosong = boleh (world tanpa pohon).
-- Isi = [y*W+x] -> { p = waktu tanam (waktu server), f = buah, s = sudah di-splice }
function Auto.treeTableOk(t)
    local w = Refs.World
    if type(t) ~= "table" or t == w or getmetatable(t) ~= nil or rawget(t, "fg") ~= nil then return false end
    local n = 0
    for k, v in pairs(t) do
        n += 1
        if n > 6 then break end
        if type(k) ~= "number" or type(v) ~= "table" or type(rawget(v, "p")) ~= "number" then return false end
        if w and type(w.w) == "number" and type(w.h) == "number" and (k < 0 or k >= w.w * w.h) then return false end
    end
    return true
end

-- Cari data pohon dari struktur kode game (tanpa getgc, tanpa remote):
--   World.tileChanged memegang (upvalue) tabel pohon + fungsi simpan pohon.
--   Fungsi simpan pohon memegang World + tabel pohon + tabel gambar pohon.
--   Tabel yang dipegang KEDUANYA = tabel pohon.
function Auto.findTreesStruct()
    local w = Refs.World
    if not w or not getUpvalues then return false end
    local roots = {}
    for _, name in ipairs({ "tileChanged", "treeChanged", "setTree" }) do
        local f = rawget(w, name)
        if type(f) == "function" then roots[#roots + 1] = f end
    end
    for _, root in ipairs(roots) do
        local ups = getUpvalues(root)
        local tset = {}
        for _, u in pairs(ups) do
            if type(u) == "table" and u ~= w then tset[u] = true end
        end
        for _, g in pairs(ups) do
            if type(g) == "function" then
                local gu = getUpvalues(g)
                local hasW, nT, shared = false, 0, {}
                for _, v in pairs(gu) do
                    if rawequal(v, w) then
                        hasW = true
                    elseif type(v) == "table" then
                        nT += 1
                        if tset[v] then shared[#shared + 1] = v end
                    end
                end
                -- fungsi simpan pohon: upvalue sedikit (World + 2 tabel), satu tabel sama dengan tileChanged
                if hasW and nT <= 3 and #shared == 1 and Auto.treeTableOk(shared[1]) then
                    Refs.Trees, Refs.TreeMode, Refs.TreeP = shared[1], "idx", "p"
                    return true
                end
            end
        end
        -- cadangan: tabel milik tileChanged yang isinya jelas data pohon
        for t in pairs(tset) do
            if next(t) ~= nil and Auto.treeTableOk(t) and Auto.treeShape(t) == "idx" then
                Refs.Trees, Refs.TreeMode, Refs.TreeP = t, "idx", "p"
                return true
            end
        end
    end
    return false
end

-- Data pohon di tile (x,y): { p = waktu tanam (waktu server), s = sudah di-splice }.
-- Bentuk tabel bisa beda tergantung versi game (lihat Auto.findTreesDeep).
function Auto.treeEntry(x, y)
    local t, w = Refs.Trees, Refs.World
    if not t or not w then return nil end
    local mode = Refs.TreeMode or "idx"
    local e
    if mode == "xy" then
        e = t[x .. "," .. y]
    elseif mode == "rows" then
        local r = t[y]
        e = type(r) == "table" and r[x] or nil
    else
        e = t[y * w.w + x]
    end
    if type(e) == "number" then return { p = e } end
    if type(e) ~= "table" then return nil end
    local pk = Refs.TreeP or "p"
    if pk ~= "p" then return { p = rawget(e, pk), s = rawget(e, "s") } end
    return e
end

-- Tabel ini data pohon? Hasil: mode ("idx" / "xy" / "rows"), nama field waktu tanam
function Auto.treeShape(t)
    local w = Refs.World
    if type(t) ~= "table" or not w or t == w or rawget(t, "fg") ~= nil then return nil end
    local W, H = w.w, w.h
    local okT, st = pcall(function() return workspace:GetServerTimeNow() end)
    if not okT then st = os.time() end
    local function timeKey(e)
        if type(e) == "number" then
            return (math.abs(e - st) < 86400 * 90) and "#" or nil
        end
        if type(e) ~= "table" then return nil end
        local pv = rawget(e, "p")
        if type(pv) == "number" and math.abs(pv - st) < 86400 * 90 then return "p" end
        for fk, fv in pairs(e) do
            if type(fv) == "number" and math.abs(fv - st) < 86400 * 90 then return fk end
        end
        return nil
    end
    local function seedAt(x, y)
        local row = w.fg[y]
        local id = row and row[x]
        local it = id and ItemDB[id]
        return it ~= nil and it.kind == "seed"
    end
    local checked, good, bad, mode, pk = 0, 0, 0, nil, nil
    for k, v in pairs(t) do
        checked += 1
        if checked > 10 then break end
        local x, y, e, m = nil, nil, nil, nil
        if type(k) == "number" and k % 1 == 0 and k >= 0 then
            if type(v) == "table" and k < H and timeKey(v) == nil then
                -- baris: t[y][x]
                local kx, ve = next(v)
                if type(kx) == "number" and kx >= 0 and kx < W then x, y, e, m = kx, k, ve, "rows" end
            elseif k < W * H then
                x, y, e, m = k % W, k // W, v, "idx"
            end
        elseif type(k) == "string" then
            local a, b = string.match(k, "^(%d+),(%d+)$")
            if a then x, y, e, m = tonumber(a), tonumber(b), v, "xy" end
        end
        if not x then return nil end
        if mode and mode ~= m then return nil end
        mode = m
        local tk = timeKey(e)
        if tk and seedAt(x, y) then
            good += 1
            pk = (tk == "#") and "p" or tk
        else
            bad += 1 -- data lama (pohon sudah dipanen) masih tersimpan: boleh sedikit
        end
    end
    if good == 0 or bad > good then return nil end
    return mode, pk
end

-- Cari data pohon lewat upvalue fungsi game (remote world, fungsi World, RunService, Net). Tanpa getgc.
function Auto.findTreesDeep()
    local w = Refs.World
    if not w or not getUpvalues then return false end
    local queue, seenF, seenT, nF = {}, {}, {}, 0
    local function addFn(fn)
        if type(fn) == "function" and not seenF[fn] then queue[#queue + 1] = fn end
    end
    local function tryTable(t)
        if seenT[t] then return false end
        seenT[t] = true
        local mode, pk = Auto.treeShape(t)
        if mode then
            Refs.Trees, Refs.TreeMode, Refs.TreeP = t, mode, pk
            return true
        end
        return false
    end
    -- 1) isi World langsung (tabel & fungsi)
    for _, v in pairs(w) do
        if type(v) == "table" then
            if tryTable(v) then return true end
        elseif type(v) == "function" then
            addFn(v)
        end
    end
    -- 2) handler remote world
    if getconnections then
        for _, ev in ipairs(WorldRemotes:GetChildren()) do
            if ev:IsA("RemoteEvent") then
                local ok, conns = pcall(getconnections, ev.OnClientEvent)
                if ok and type(conns) == "table" then
                    for _, c in ipairs(conns) do
                        local okf, fn = pcall(function() return c.Function end)
                        if okf then addFn(fn) end
                    end
                end
            end
        end
        for _, name in ipairs({ "RenderStepped", "Heartbeat", "Stepped" }) do
            local okS, sig = pcall(function() return RunService[name] end)
            local ok, conns = pcall(getconnections, sig)
            if okS and ok and type(conns) == "table" then
                for _, c in ipairs(conns) do
                    local okf, fn = pcall(function() return c.Function end)
                    if okf then addFn(fn) end
                end
            end
        end
    end
    -- 3) telusuri upvalue (maks 1500 fungsi)
    local i = 1
    while i <= #queue and nF < 1500 do
        local fn = queue[i]
        i += 1
        if not seenF[fn] then
            seenF[fn] = true
            nF += 1
            for _, u in pairs(getUpvalues(fn)) do
                if type(u) == "table" then
                    if tryTable(u) then return true end
                elseif type(u) == "function" then
                    addFn(u)
                end
            end
        end
    end
    return false
end

local function farmReach()
    return math.min(punchReach(), buildReach())
end

local function seedCount()
    return Farmer.SeedId and invCount(Farmer.SeedId) or 0
end

-- Kapan pohon ini siap panen (nil = bukan pohon)
local function treeReadyAt(x, y, id)
    if not Refs.Trees or not Refs.World then return nil end
    local it = ItemDB[id]
    if not (it and it.kind == "seed") then return nil end
    local t = Auto.treeEntry(x, y)
    if type(t) ~= "table" or type(t.p) ~= "number" then return nil end
    return t.p + (it.grow or 0)
end

-- Bisa tanam seed di sini? (seedId kosong = seed Farmer)
local function plantSpotOk(x, y, seedId)
    local w = Refs.World
    if not w or x < 0 or y < 0 or x >= w.w or y + 1 >= w.h then return false end
    if fgIdAt(x, y) ~= 0 then return false end
    local below = fgIdAt(x, y + 1)
    if below == 0 then return false end
    local it = ItemDB[below]
    if not it or it.kind == "seed" then return false end
    if not (solidAt(x, y + 1) or it.platform) then return false end
    local ok, res = pcall(function()
        if w.areas and type(w.areas.canEdit) == "function" and not w.areas.canEdit(x, y) then return false end
        if type(w.builderOk) == "function" and not w.builderOk(x, y, true) then return false end
        local sid = seedId or Farmer.SeedId
        local seed = sid and ItemDB[sid]
        if seed and type(w.needsWay) == "function" and w.needsWay(seed)
            and type(w.wayBlocked) == "function" and w.wayBlocked(x, y) then
            return false
        end
        return true
    end)
    return (not ok) or res
end

-- Mesin panen & tanam dipakai bersama oleh Farmer dan Pabrik.
-- FC = pengaturan yang sedang dipakai (seed, area, kecepatan, dll).
local FC = nil
local function farmerCfg()
    return {
        run = function() return Farmer.Running end,
        harvest = Farmer.Harvest,
        plant = Farmer.Plant,
        seed = Farmer.SeedId,
        skip = Farmer.Skip,
        hms = Farmer.HarvestMs,
        pms = Farmer.PlantMs,
        area = nil,      -- function(x, y): boleh panen di sini?
        plantSet = nil,  -- [idx] = true: hanya tanam di tile ini
        exclude = nil,   -- [idx] = true: jangan tanam di tile ini
        row = Farmer.Row,        -- tanam rapi per baris
        collect = Farmer.Collect, -- ambil drop panen dulu sebelum lanjut
        status = function(t) Farmer.Status = t end,
        onHarvest = function(id)
            Farmer.Harvested += 1
            if id then Farmer.Got[id] = true end
        end,
        onPlant = function() Farmer.Planted += 1 end,
    }
end

local function fcSeeds()
    return FC.seed and invCount(FC.seed) or 0
end

local function fcHarvestOk(x, y)
    return FC.harvest and (not FC.area or FC.area(x, y))
end

local function fcPlantOk(idx)
    return (not FC.plantSet or FC.plantSet[idx]) and not (FC.exclude and FC.exclude[idx])
end

local function plantSeed(x, y)
    local id = FC.seed
    if not id or invCount(id) <= 0 then return false end
    sendSetTile("fg", x, y, id)
    if Refs.Inv then pcall(function() Refs.Inv:remove(id, 1) end) end
    FC.onPlant()
    FC.status("Tanam " .. itemName(id) .. " (" .. x .. "," .. y .. ")")
    return true
end

-- Panen & tanam semua yang terjangkau dari sini
local function farmerWorkInReach(s)
    local w = Refs.World
    local W = w.w
    local R = farmReach() - 0.08
    local cx, cy = s.x, s.y - 0.475
    local now = os.clock()
    local st = workspace:GetServerTimeNow()
    local doPlant = FC.plant and fcSeeds() > 0
    local harvest, plant = {}, {}
    local bx, by = floor(s.x), floor(cy)
    for ty = math.max(0, floor(cy - R - 0.5)), math.min(floor(cy + R + 0.5), w.h - 1) do
        for tx = math.max(0, floor(cx - R - 0.5)), math.min(floor(cx + R + 0.5), W - 1) do
            if stateReaches(s, tx, ty, R) then
                local idx = ty * W + tx
                if not skipped(FC.skip, idx, now) then
                    local id = fgIdAt(tx, ty)
                    if id ~= 0 and fcHarvestOk(tx, ty) and (not FC.only or id == FC.only) then
                        local ra = treeReadyAt(tx, ty, id)
                        if ra and st >= ra and Move.los(bx, by, tx, ty) then
                            if canWorkAt(tx, ty) then
                                harvest[#harvest + 1] = { x = tx, y = ty, idx = idx }
                            else
                                skipTile(FC.skip, idx, 120)
                            end
                        end
                    elseif doPlant and id == 0 and fcPlantOk(idx) and (not FC.row or FC.row.y == ty)
                        and plantSpotOk(tx, ty, FC.seed) then
                        plant[#plant + 1] = { x = tx, y = ty, idx = idx }
                    end
                end
            end
        end
    end
    local function byX(a, b)
        if a.x ~= b.x then return a.x < b.x end
        return a.y < b.y
    end
    table.sort(harvest, byX)
    table.sort(plant, byX)

    local done, got = 0, 0
    for _, t in ipairs(harvest) do
        if not FC.run() or not alive() then return done end
        local cur = playerState()
        if not cur or not stateReaches(cur, t.x, t.y, R) then break end
        local id = fgIdAt(t.x, t.y)
        local r = tryBreak(t.x, t.y, false) -- pohon siap: 1 pukulan = panen
        if r == "broke" then
            FC.onHarvest(id)
            got += 1
            FC.status("Panen " .. itemName(id) .. " (" .. t.x .. "," .. t.y .. ")")
        else
            skipTile(FC.skip, t.idx, 30)
        end
        done += 1
        if not waitAuto(FC.hms) then return done end
    end
    -- ambil hasil panen dulu sebelum pindah / tanam
    if got > 0 and FC.collect then
        FC.status("Ambil hasil panen...")
        task.wait(0.25) -- drop panen muncul sedikit terlambat
        if not FC.run() or not alive() then return done end
        -- susuri baris ini sampai drop terjauh (terambil sambil lewat, tanpa berhenti)
        if Move.fetchDrops(FC.run, 8, function(d) return abs(d.y - cy) <= 1.6 end, 10) > 0 then return done end
    end
    for _, t in ipairs(plant) do
        if not FC.run() or not alive() then return done end
        if fcSeeds() <= 0 then break end
        local cur = playerState()
        if not cur or not stateReaches(cur, t.x, t.y, R) then return done end
        if fgIdAt(t.x, t.y) == 0 then
            if not plantSeed(t.x, t.y) then break end
            done += 1
            if not waitAuto(FC.pms) then return done end
        end
    end
    return done
end

-- Cari target + kapan pohon berikutnya siap.
--   Panen : pohon siap terdekat (didahulukan).
--   Tanam : rapi per baris. Selesaikan 1 baris dulu (baris yang sedang dikerjakan,
--           atau baris terdekat dengan karakter), dari tile paling kiri ke kanan.
local function farmerScan(px, py, maxN, filter)
    local w = Refs.World
    local W, H = w.w, w.h
    local best = {}
    local now = os.clock()
    local st = workspace:GetServerTimeNow()
    local nextReady = nil
    local doPlant = FC.plant and fcSeeds() > 0
    local rows = {} -- [y] = daftar tempat tanam di baris itu
    local scanned = 0
    for y = 0, H - 1 do
        local frow, below = w.fg[y], w.fg[y + 1]
        for x = 0, W - 1 do
            local id = frow and frow[x] or 0
            if id ~= 0 then
                if fcHarvestOk(x, y) and (not FC.only or id == FC.only) then
                    local ra = treeReadyAt(x, y, id)
                    if ra and st >= ra then
                        local idx = y * W + x
                        if not skipped(FC.skip, idx, now) then
                            if filter and not filter[idx] then
                                skipTile(FC.skip, idx, 60)
                            else
                                local dx, dy = x - px, (y - py) * 1.3
                                local d = dx * dx + dy * dy
                                if #best < maxN or d < best[#best].d then
                                    if canWorkAt(x, y) then
                                        local pos = #best + 1
                                        while pos > 1 and best[pos - 1].d > d do pos -= 1 end
                                        table.insert(best, pos, { x = x, y = y, idx = idx, d = d, kind = "harvest" })
                                        if #best > maxN then best[#best] = nil end
                                    else
                                        skipTile(FC.skip, idx, 120)
                                    end
                                end
                            end
                        end
                    elseif ra and (not nextReady or ra - st < nextReady) then
                        nextReady = ra - st
                    end
                end
            elseif doPlant then
                local b = below and below[x] or 0
                local idx = y * W + x
                if b ~= 0 and fcPlantOk(idx) and not skipped(FC.skip, idx, now) then
                    if filter and not filter[idx] then
                        skipTile(FC.skip, idx, 60)
                    else
                        local r = rows[y]
                        if not r then
                            r = {}
                            rows[y] = r
                        end
                        r[#r + 1] = { x = x, y = y, idx = idx, kind = "plant" }
                    end
                end
            end
        end
        scanned += W
        if scanned >= 6000 then
            scanned = 0
            task.wait()
            if not FC.run() or not alive() then break end
        end
    end
    if #best > 0 or not doPlant then return best, nextReady end

    -- tanam rapi: baris yang sedang dikerjakan dulu, lalu baris terdekat
    local lock = FC.row and FC.row.y
    local order = {}
    for y in pairs(rows) do order[#order + 1] = y end
    local function rowKey(y) return (y == lock) and -1 or math.abs(y - py) end
    table.sort(order, function(a, b)
        local ka, kb = rowKey(a), rowKey(b)
        if ka ~= kb then return ka < kb end
        return a < b
    end)
    for _, y in ipairs(order) do
        local list = rows[y]
        table.sort(list, function(a, b) return a.x < b.x end) -- dari kiri ke kanan
        for _, t in ipairs(list) do
            if plantSpotOk(t.x, t.y, FC.seed) then
                if FC.row then FC.row.y = y end
                return { t }, nextReady
            end
            skipTile(FC.skip, t.idx, 120)
        end
    end
    if FC.row then FC.row.y = nil end
    return best, nextReady
end

local lastFarmerText = nil
local function updateFarmerStatus()
    if Refs.World and not Refs.Trees and os.clock() >= (Auto.nextTreeScan or 0) then
        Auto.nextTreeScan = os.clock() + 15
        pcall(findTreeRefs)
    end
    if not UI.FarmerStatus then return end
    local seed = Farmer.SeedId
    local txt = "Status  : " .. (Farmer.Running and "JALAN" or "BERHENTI")
        .. "\nPanen   : " .. Farmer.Harvested .. "  | tanam: " .. Farmer.Planted .. "  | collect: " .. State.Collected
        .. "\nSeed    : " .. (seed and (itemName(seed) .. " x" .. invCount(seed)) or "-")
        .. "\nPohon   : " .. (Refs.Trees and "terbaca" or "TIDAK terbaca (harvest mati)")
        .. "\nPijakan : " .. blockText(Farmer.UseBlock, Farmer.ScaffoldId)
        .. "\nDrop    : " .. ((Pabrik.pointSet and Pabrik.pointSet()) and ("otomatis saat >= " .. Farmer.DropAt
            .. " | di-drop " .. Farmer.Dropped) or "titik drop belum diatur")
        .. "\nAksi    : " .. Farmer.Status
    if txt == lastFarmerText then return end
    lastFarmerText = txt
    task.defer(function()
        pcall(function() UI.FarmerStatus:SetDesc(txt) end)
    end)
end

-- 1 langkah mesin panen/tanam (pakai FC):
--   kerjakan yang terjangkau, atau jalan ke target terdekat.
-- Hasil: "work" | "move" | "wait" | "idle" (+ detik ke pohon siap berikutnya)
-- Tersangkut lama di udara / pinggir block (bikin karakter diam): dorong sedikit ke samping
function Move.airCheck(s)
    if s.grounded then
        Move.AirAt = nil
        return
    end
    if not Move.AirAt then
        Move.AirAt = os.clock()
    elseif os.clock() - Move.AirAt > 3 then
        Move.AirAt = nil
        local right = (s.facing or 1) < 0 -- ke arah sebaliknya
        AutoInput.active = true
        AutoInput.right, AutoInput.left = right, not right
        task.wait(0.2)
        AutoInput.right, AutoInput.left = false, false
    end
end

local function fieldStep()
    local w = Refs.World
    local s = playerState()
    if not w or not s or s.dead then
        releaseInput()
        task.wait(0.5)
        return "wait"
    end
    if not s.grounded then
        releaseInput()
        Move.airCheck(s)
        task.wait()
        return "wait"
    end
    Move.AirAt = nil
    releaseInput()
    if farmerWorkInReach(s) > 0 then return "work" end
    local R = farmReach() - 0.35
    local useBlock = scaffoldId() ~= nil
    local sx, sy = startNode(s)
    local px, py = floor(s.x), floor(s.y - 0.475)
    local targets, nextReady = farmerScan(px, py, 8, reachFilter(sy * w.w + sx, R, useBlock))
    if not FC.run() or not alive() then return "wait" end
    if #targets == 0 then return "idle", nextReady end
    targets.los = targets[1].kind == "harvest" -- panen: berdiri di baris pohon (drop terambil)
    travelGroup(sx, sy, targets, R, useBlock, FC.skip, FarmerFail)
    return "move"
end

-- Item hasil panen yang sudah hampir penuh: seed pohon & block-nya
function Farmer.dropList()
    local out = {}
    for sid in pairs(Farmer.Got) do
        for _, id in ipairs({ sid, sid - 1 }) do
            local it = ItemDB[id]
            if it and (id == sid or it.kind ~= "seed") then
                local n = invCount(id)
                local keep = (id == Farmer.SeedId) and Farmer.Keep or 0
                if n >= Farmer.DropAt and n > keep then
                    out[#out + 1] = { id = id, n = n - keep }
                end
            end
        end
    end
    return out
end

local function farmerLoop()
    local lastUi = 0
    while Farmer.Running and alive() do
        task.wait()
        if os.clock() - lastUi > 0.5 then
            lastUi = os.clock()
            updateFarmerStatus()
        end
        FC = farmerCfg()
        if not Refs.World then
            Farmer.Status = "Menunggu karakter / world..."
            task.wait(0.5)
            continue
        end
        -- inventori hampir penuh -> drop hasil panen ke titik drop
        if Pabrik.pointSet and Pabrik.pointSet() and Auto.dropTrip and os.clock() >= (Farmer.DropOffUntil or 0)
            and os.clock() - (Farmer.DropCheck or 0) > 2 then
            Farmer.DropCheck = os.clock()
            local items = Farmer.dropList()
            if #items > 0 then
                releaseInput()
                local ok, why = Auto.dropTrip(items, function() return Farmer.Running and alive() end,
                    function(t) Farmer.Status = t end)
                for _, it in ipairs(items) do Farmer.Dropped += it.got or 0 end
                if why == "home" then
                    stopFarmer("Gagal pulang ke world farmer")
                    break
                end
                if not ok then Farmer.DropOffUntil = os.clock() + ((why == "nopoint") and 60 or 120) end
                continue
            end
        end
        local r, nextReady = fieldStep()
        if r == "wait" and not playerState() then
            Farmer.Status = "Menunggu karakter / world..."
        end
        if r == "idle" then
            local parts = {}
            if Farmer.Harvest then
                parts[#parts + 1] = nextReady and ("pohon siap ±" .. math.ceil(nextReady) .. " dtk") or "tidak ada pohon"
            end
            if Farmer.Plant then
                parts[#parts + 1] = (seedCount() <= 0) and "seed habis / belum dipilih" or "tidak ada tempat tanam"
            end
            Farmer.Status = "Menunggu: " .. table.concat(parts, ", ")
            if not waitAuto(1000) then break end
        end
    end
    releaseInput()
end

local function setFarmerVisual()
    if UI.FarmerToggle then pcall(function() UI.FarmerToggle:Set(Farmer.Running) end) end
end

stopFarmer = function(reason)
    Farmer.Running = false
    autoEnd()
    setFarmerVisual()
    Farmer.Status = reason or "Dihentikan"
    if reason then
        notify("Farmer", reason, 5)
        if not string.find(reason, "^Dihentikan") then Hook.send("stop", "Farmer berhenti: " .. reason) end
    end
    updateFarmerStatus()
end

local function startFarmer()
    if Farmer.Running then return end
    local err = checkAutoStart()
    if not err and not Farmer.Harvest and not Farmer.Plant then
        err = "Aktifkan Auto Harvest atau Auto Plant"
    end
    if not err and not Farmer.Harvest and not Farmer.SeedId then
        err = "Pilih seed dulu untuk Auto Plant"
    end
    if err then
        notify("Farmer", err, 4)
        setFarmerVisual()
        return
    end
    if Farmer.Harvest and not Refs.Trees and not findTreeRefs() then
        notify("Farmer", "Data pohon tidak ketemu: Auto Harvest tidak bisa cek pohon siap", 5)
    end
    if Splice.Running and Splice.stop then Splice.stop("Dihentikan karena Farmer dimulai") end
    if Pabrik.Running and Pabrik.stop then Pabrik.stop("Dihentikan karena Farmer dimulai") end
    if State.Running then stopFarm("Dihentikan karena Farmer dimulai") end
    if Clear.Running then stopClear("Dihentikan karena Farmer dimulai") end
    table.clear(Farmer.Skip)
    table.clear(FarmerFail)
    table.clear(BadEdge)
    table.clear(Farmer.Row)
    Farmer.DropOffUntil = 0
    Farmer.Status = "Mulai..."
    Farmer.Running = true
    autoBegin()
    setFarmerVisual()
    updateFarmerStatus()
    task.spawn(function()
        local ok, e = pcall(farmerLoop)
        if not ok then
            warn("[SkyP] Farmer error: " .. tostring(e))
            if Farmer.Running then stopFarmer("Error: " .. tostring(e)) end
        end
    end)
end

---------------------------------------------------------------------
-- SPLICE KELILING: tanam Seed A + splice Seed B di seluruh world
---------------------------------------------------------------------
-- Cara kerja (sama seperti Farmer, tapi aksinya splice):
--   1. Kerjakan semua tile yang terjangkau dari posisi sekarang:
--        tile kosong (di bawahnya block) -> tanam A, lalu splice B ke pohon A itu
--        pohon A yang belum di-splice     -> splice B
--   2. Kalau tidak ada lagi yang terjangkau: cari tile terdekat, jalan ke sana pakai A*.
--   Pohon yang sudah siap panen tidak bisa di-splice (aturan game), jadi dilewati.
local SpliceFail = {}

local function spliceInv()
    return invCount(Splice.A or 0), invCount(Splice.B or 0)
end

-- Jenis kerja di tile ini: "plant" | "splice" | nil
local function spliceKind(x, y, st)
    local A = Splice.A
    local id = fgIdAt(x, y)
    if id == 0 then
        local a, b = spliceInv()
        if a > 0 and b > 0 and plantSpotOk(x, y, A) then return "plant" end
        return nil
    end
    if id ~= A then return nil end
    local t = Auto.treeEntry(x, y)
    if type(t) == "table" and t.s == true then return nil end -- sudah di-splice
    local ra = treeReadyAt(x, y, id)
    if ra and st >= ra then return nil end -- sudah siap panen
    local _, b = spliceInv()
    if b > 0 and canWorkAt(x, y) then return "splice" end
    return nil
end

local function spliceOnce(x, y)
    local w = Refs.World
    local f = w and rawget(w, "spliceSeed")
    if type(f) ~= "function" then return false, "fungsi splice game tidak ketemu" end
    local ok, made = pcall(f, x, y, Splice.B)
    if ok and made and ItemDB[made] then
        pcall(function() Refs.Inv:remove(Splice.B, 1) end)
        if Refs.SetTile then pcall(Refs.SetTile, "fg", x, y, made, true) end -- ganti di layar saja
        Splice.Made += 1
        Splice.Status = ("Splice jadi %s (%d,%d)"):format(itemName(made), x, y)
        return true
    end
    return false, "ditolak server"
end

-- Kerjakan 1 tile: tanam A (kalau kosong) lalu splice B
local function spliceTile(t)
    local A = Splice.A
    if fgIdAt(t.x, t.y) == 0 then
        if invCount(A) <= 0 then return false end
        sendSetTile("fg", t.x, t.y, A)
        pcall(function() Refs.Inv:remove(A, 1) end)
        Splice.Planted += 1
        Splice.Status = ("Tanam %s (%d,%d)"):format(itemName(A), t.x, t.y)
        if not waitAuto(Splice.Ms) then return false end
    end
    if fgIdAt(t.x, t.y) ~= A then
        skipTile(Splice.Skip, t.idx, 30)
        return true
    end
    local ok, why = spliceOnce(t.x, t.y)
    if not ok then
        SpliceFail[t.idx] = (SpliceFail[t.idx] or 0) + 1
        skipTile(Splice.Skip, t.idx, 60)
        Splice.Status = ("Gagal splice (%d,%d): %s"):format(t.x, t.y, tostring(why))
    end
    waitAuto(Splice.Ms)
    return true
end

local function spliceWorkInReach(s)
    local w = Refs.World
    local W = w.w
    local R = farmReach() - 0.08
    local cx, cy = s.x, s.y - 0.475
    local now = os.clock()
    local st = workspace:GetServerTimeNow()
    local list = {}
    for ty = math.max(0, floor(cy - R - 0.5)), math.min(floor(cy + R + 0.5), w.h - 1) do
        for tx = math.max(0, floor(cx - R - 0.5)), math.min(floor(cx + R + 0.5), W - 1) do
            if stateReaches(s, tx, ty, R) then
                local idx = ty * W + tx
                if Splice.Row.y == ty and not skipped(Splice.Skip, idx, now) and spliceKind(tx, ty, st) then
                    list[#list + 1] = { x = tx, y = ty, idx = idx }
                end
            end
        end
    end
    table.sort(list, function(a, b)
        if a.x ~= b.x then return a.x < b.x end
        return a.y < b.y
    end)
    local done = 0
    for _, t in ipairs(list) do
        if not Splice.Roaming or not alive() then return done end
        local cur = playerState()
        if not cur or not stateReaches(cur, t.x, t.y, R) then return done end
        if not spliceTile(t) then return done end
        done += 1
    end
    return done
end

-- Tile kerja berikutnya: rapi per baris (baris yang sedang dikerjakan / terdekat),
-- dari kiri ke kanan
local function spliceScan(px, py, maxN, filter)
    local w = Refs.World
    local W, H = w.w, w.h
    local now = os.clock()
    local st = workspace:GetServerTimeNow()
    local rows = {} -- [y] = tile kerja paling kiri di baris itu
    local scanned = 0
    for y = 0, H - 1 do
        for x = 0, W - 1 do
            local idx = y * W + x
            if not rows[y] and not skipped(Splice.Skip, idx, now) and spliceKind(x, y, st) then
                if filter and not filter[idx] then
                    skipTile(Splice.Skip, idx, 60)
                else
                    rows[y] = { x = x, y = y, idx = idx }
                end
            end
        end
        scanned += W
        if scanned > 6000 then
            scanned = 0
            task.wait()
            if not Splice.Roaming then return {} end
        end
    end
    local lock, pick, pk = Splice.Row.y, nil, nil
    for y, t in pairs(rows) do
        local k = (y == lock) and -1 or math.abs(y - py)
        if not pick or k < pk or (k == pk and y < pick.y) then pick, pk = t, k end
    end
    Splice.Row.y = pick and pick.y or nil
    return pick and { pick } or {}
end

local function spliceRoamLoop(runId)
    while Splice.Roaming and Splice.Running and alive() and Splice.RunId == runId do
        task.wait()
        local w = Refs.World
        local s = playerState()
        if not w or not s or s.dead then
            releaseInput()
            Splice.Status = "Menunggu karakter / world..."
            task.wait(0.5)
            continue
        end
        if not s.grounded then
            releaseInput()
            continue
        end
        releaseInput()
        local a, b = spliceInv()
        if b <= 0 then
            if Splice.stop then Splice.stop("Seed habis") end
            break
        end
        -- 1) kerjakan yang terjangkau
        if spliceWorkInReach(s) > 0 then continue end
        -- 2) jalan ke tile terdekat
        local R = farmReach() - 0.35
        local sx, sy = startNode(s)
        local px, py = floor(s.x), floor(s.y - 0.475)
        local targets = spliceScan(px, py, 8, reachFilter(sy * w.w + sx, R, false))
        if not Splice.Roaming or not alive() then break end
        if #targets == 0 then
            Splice.Status = (a <= 0) and "Seed A habis, tidak ada pohon A yang bisa di-splice"
                or "Menunggu: tidak ada tempat tanam / pohon untuk di-splice"
            if not waitAuto(1000) then break end
            continue
        end
        travelGroup(sx, sy, targets, R, false, Splice.Skip, SpliceFail)
    end
    releaseInput()
end

local function startSpliceRoam()
    if not OrigIsDown then return "Kontrol gerak game (WorldMenu.isDown) tidak ketemu" end
    table.clear(Splice.Row)
    if not playerState() then return "Kamu belum masuk world" end
    if not Refs.Trees then findTreeRefs() end
    table.clear(Splice.Skip)
    table.clear(SpliceFail)
    table.clear(BadEdge)
    Splice.Roaming = true
    autoBegin()
    local id = Splice.RunId
    task.spawn(function()
        local ok, e = pcall(spliceRoamLoop, id)
        if not ok then
            warn("[SkyP] Splice error: " .. tostring(e))
            if Splice.Running and Splice.stop then Splice.stop("Error: " .. tostring(e)) end
        end
    end)
    return nil
end

local function stopSpliceRoam()
    Splice.Roaming = false
    autoEnd()
    releaseInput()
end

-- Jalan ke 1 tile tertentu (dipakai Penjaga: balik ke posisi Auto Farm).
-- Pakai A* yang sama, tanpa taruh block.
local function walkTo(tx, ty, maxSec)
    local w = Refs.World
    if not w or not OrigIsDown then return false end
    if tx < 0 or ty < 0 or tx >= w.w or ty >= w.h then return false end
    Move.Homing = true
    autoBegin()
    local goal = { [ty * w.w + tx] = true }
    local t0, ok = os.clock(), false
    while alive() and Move.Homing and os.clock() - t0 < (maxSec or 30) do
        local s = playerState()
        if not s or s.dead then
            task.wait(0.3) -- tunggu respawn / world selesai dimuat
        else
            local sx, sy = startNode(s)
            if sx == tx and sy == ty and s.grounded then
                ok = true
                break
            end
            local path = astar(sx, sy, goal, tx, ty, 0.5, false)
            if not path then break end -- tidak ada jalan
            if #path > 0 then followPath(path) end
            releaseInput()
            task.wait(0.15)
        end
    end
    Move.Homing = false
    autoEnd()
    return ok
end

---------------------------------------------------------------------
-- PABRIK (v2: hanya tile pilihan di peta, rute tetap)
---------------------------------------------------------------------
-- Cara kerja:
--   1. Kamu memilih LANTAI di peta. Pohon ditanam di tile tepat di atas lantai terpilih.
--   2. Dari lantai terpilih dibuat RUTE TETAP: lantai paling atas dulu, tiap lantai disapu
--      bergantian arah (kiri->kanan, lalu kanan->kiri). Di rute ada TITIK BERDIRI tiap 5 tile.
--   3. Siklus (berputar terus):
--        PANEN+TANAM : jalan mengikuti rute. Di tiap titik: panen yang siap -> ambil drop
--                      (sentuhan badan, di lantai itu saja) -> langsung tanam lagi.
--                      Titik tanpa pekerjaan dilewati. Titik yang tidak terjangkau ditandai merah di peta.
--        BREAK       : jalan ke titik break, pasang-pecah block. Tile break DIKUNCI ke koordinat
--                      tetap (tidak ikut bergeser kalau badan bergeser).
--        TUNGGU      : tunggu sampai banyak pohon siap (tidak bolak-balik untuk 1 pohon).
--      Drop seed lebihan hanya dilakukan DI ANTARA fase, tidak di tengah rute.
-- Inventori maksimal 200 per item, jadi semua fase dijaga supaya tidak penuh.
local CAP = 190       -- batas aman jumlah item (maksimal 200 per item)

-- Seed <-> block (seed biasanya id block + 1, kecuali item khusus yang punya seedId)
local function seedOfBlock(block)
    local it = block and ItemDB[block]
    if not it then return nil end
    local sid = it.seedId or (block + 1)
    local sd = ItemDB[sid]
    if sd and sd.kind == "seed" then return sid end
    return nil
end

local function blockOfSeed(seed)
    if not seed then return nil end
    local b = seed - 1
    local it = ItemDB[b]
    if it and it.kind ~= "seed" and (it.seedId == nil or it.seedId == seed) then return b end
    return nil
end

-- Tile ini lantai yang bisa ditanami di atasnya? (block padat apa saja, bukan pohon / lava / duri)
function Pabrik.floorOk(x, y)
    local id = fgIdAt(x, y)
    if id == 0 then return false end
    local it = ItemDB[id]
    if not it or it.kind == "seed" or not it.solid then return false end
    return not (it.deadly or it.hurts or it.laser)
end

-- Simpan titik & tile break world aktif (disimpan per world, ikut auto save config)
function Pabrik.saveBreak()
    local name = Pabrik.PickWorld
    Pabrik._setAt = 0 -- tile tanam dihitung ulang (titik & tile break tidak ditanami)
    if name == "" then return end
    if Pabrik.BreakX < 0 then
        Pabrik.Breaks[name] = nil
        return
    end
    local tiles = {}
    for key in pairs(Pabrik.Tiles) do tiles[key] = true end
    Pabrik.Breaks[name] = { x = Pabrik.BreakX, y = Pabrik.BreakY, tiles = tiles }
end

-- Pilihan lantai & titik break disimpan PER WORLD:
--   Pabrik.Picks[NAMA_WORLD]  = { ["y,x0,x1"] = true }   (y = baris lantai)
--   Pabrik.Breaks[NAMA_WORLD] = { x, y, tiles }
-- Pabrik.Pick selalu menunjuk tabel milik world aktif, jadi mengubah pilihan = langsung ikut tersimpan.
-- Selama pabrik jalan, world aktif = world pabrik (pergi drop ke world lain tidak mengganti pilihan).
-- Hasil: true kalau pilihan baru saja diganti ke world lain.
function Pabrik.syncPick()
    local name = Guard.worldName and Guard.worldName() or ""
    if Pabrik.Running and (Pabrik.Home or "") ~= "" then name = Pabrik.Home end
    name = string.upper(name)
    if name == "" or name == Pabrik.PickWorld then return false end
    local old = Pabrik.PickWorld
    if old ~= "" and type(Pabrik.Picks[old]) == "table" and next(Pabrik.Picks[old]) == nil then
        Pabrik.Picks[old] = nil -- world tanpa pilihan tidak perlu dicatat
    end
    local pick = Pabrik.Picks[name]
    if type(pick) ~= "table" then
        pick = {}
        local legacy = Pabrik.LegacyPick
        if legacy and Refs.World then
            -- pilihan dari config lama dipakai hanya kalau lantainya memang ada di world ini
            local hit = false
            for key in pairs(legacy) do
                local y, x0, x1 = string.match(tostring(key), "^(%d+),(%d+),(%d+)$")
                y, x0, x1 = tonumber(y), tonumber(x0), tonumber(x1)
                if y and Pabrik.floorOk(x0, y) and Pabrik.floorOk(x1, y) then hit = true break end
            end
            if hit then
                for key in pairs(legacy) do pick[key] = true end
                Pabrik.LegacyPick = nil
            end
        end
        Pabrik.Picks[name] = pick
    end
    Pabrik.Pick = pick
    -- titik break: yang lama disimpan untuk world lama, world baru memuat miliknya
    if old ~= "" then
        Pabrik.saveBreak()
        local b = Pabrik.Breaks[name]
        table.clear(Pabrik.Tiles)
        if type(b) == "table" and tonumber(b.x) and tonumber(b.y) then
            Pabrik.BreakX, Pabrik.BreakY = tonumber(b.x), tonumber(b.y)
            if type(b.tiles) == "table" then
                for key in pairs(b.tiles) do Pabrik.Tiles[key] = true end
            end
        else
            Pabrik.BreakX, Pabrik.BreakY = -1, -1
        end
    else
        -- pertama kali (baru execute): pakai catatan world ini kalau ada, kalau tidak pakai config lama
        local b = Pabrik.Breaks[name]
        if type(b) == "table" and tonumber(b.x) and tonumber(b.y) then
            table.clear(Pabrik.Tiles)
            Pabrik.BreakX, Pabrik.BreakY = tonumber(b.x), tonumber(b.y)
            if type(b.tiles) == "table" then
                for key in pairs(b.tiles) do Pabrik.Tiles[key] = true end
            end
        end
    end
    Pabrik.PickWorld = name
    Pabrik.FullPick, Pabrik.FullWorld, Pabrik.FullAt = {}, "", 0 -- pindai Full world milik world lama dibuang
    Pabrik._setAt = 0
    Pabrik.Route = {}
    table.clear(Pabrik.Bad)
    return true
end

-- Cari semua deretan lantai (min 3 tile) yang di atasnya kosong / ada pohon
-- all = true (Full world): tanpa batas jumlah, dan block di tile break tidak memotong lantai di bawahnya
function Pabrik.scanSegments(all)
    local w = Refs.World
    local out = {}
    if not w then return out end
    local brk = {} -- tile break (block pabrik sedang dipasang di sana): dianggap kosong
    if all and Pabrik.BreakX >= 0 then
        for key in pairs(Pabrik.Tiles) do
            local dx, dy = string.match(tostring(key), "^(-?%d+),(-?%d+)$")
            if dx then brk[(Pabrik.BreakY + tonumber(dy)) * w.w + Pabrik.BreakX + tonumber(dx)] = true end
        end
    end
    local function topOk(x, y)
        local a = fgIdAt(x, y - 1)
        if a == 0 then return true end
        local it = ItemDB[a]
        if it ~= nil and it.kind == "seed" then return true end
        return brk[(y - 1) * w.w + x] == true
    end
    local n = 0
    for y = 1, w.h - 1 do
        local x0 = nil
        for x = 0, w.w do -- x = w.w hanya penutup deretan
            n += 1
            if n % 3000 == 0 then task.wait() end
            local ok = x < w.w and Pabrik.floorOk(x, y) and topOk(x, y)
            if ok then
                if not x0 then x0 = x end
            elseif x0 then
                if x - x0 >= 3 then
                    out[#out + 1] = { y = y, x0 = x0, x1 = x - 1, n = x - x0, key = y .. "," .. x0 .. "," .. (x - 1) }
                end
                x0 = nil
            end
        end
    end
    if not all and #out > 400 then -- terlalu banyak untuk peta: ambil 400 terpanjang
        table.sort(out, function(a, b) return a.n > b.n end)
        for i = #out, 401, -1 do out[i] = nil end
    end
    table.sort(out, function(a, b)
        if a.y ~= b.y then return a.y < b.y end
        return a.x0 < b.x0
    end)
    return out
end

-- Lantai yang dipakai pabrik: pilihan di peta, atau SEMUA lantai world (Full world)
function Pabrik.activePick()
    if Pabrik.Full then return Pabrik.FullPick end
    return Pabrik.Pick
end

-- Full world: pindai semua lantai world pabrik (tiap 20 detik, atau force = sekarang juga).
-- Fungsi ini bisa menunggu (task.wait), jadi hanya dipanggil dari loop / task sendiri.
-- Hasil: true kalau daftar lantai baru saja diperbarui
function Pabrik.refreshFull(force)
    if not Pabrik.Full or Pabrik._fullBusy or Pabrik.Traveling or not Refs.World then return false end
    local here = string.upper(Guard.worldName and Guard.worldName() or "")
    if here == "" or here ~= Pabrik.PickWorld then return false end -- sedang di world lain (misal pergi drop)
    if not force and Pabrik.FullWorld == here and os.clock() - (Pabrik.FullAt or 0) < 20 then return false end
    Pabrik._fullBusy = true
    local w = Refs.World
    local ok, res = pcall(Pabrik.scanSegments, true)
    Pabrik._fullBusy = false
    if not ok or type(res) ~= "table" then return false end
    -- selama memindai sempat pindah world: hasilnya tidak dipakai
    if Refs.World ~= w or here ~= Pabrik.PickWorld or string.upper(Guard.worldName and Guard.worldName() or "") ~= here then
        return false
    end
    local pick = {}
    for _, sg in ipairs(res) do pick[sg.key] = true end
    Pabrik.FullPick, Pabrik.FullWorld, Pabrik.FullAt = pick, here, os.clock()
    Pabrik._setAt = 0
    return true
end

-- Tile tanam dari lantai terpilih: [idx] = true (tile tepat di atas lantai). Di-cache 3 detik.
function Pabrik.smartSet()
    local w = Refs.World
    local now = os.clock()
    if Pabrik._set and Pabrik._setW == w and now - (Pabrik._setAt or 0) < 3 then return Pabrik._set end
    local set = {}
    if w then
        for key in pairs(Pabrik.activePick()) do
            local y, x0, x1 = string.match(tostring(key), "^(%d+),(%d+),(%d+)$")
            y, x0, x1 = tonumber(y), tonumber(x0), tonumber(x1)
            if y and x0 and x1 and y >= 1 then
                for x = math.max(0, x0), math.min(w.w - 1, x1) do
                    if Pabrik.floorOk(x, y) then set[(y - 1) * w.w + x] = true end
                end
            end
        end
        -- titik berdiri & tile break tidak ditanami (boleh berada di atas lantai terpilih)
        if Pabrik.BreakX >= 0 then
            set[Pabrik.BreakY * w.w + Pabrik.BreakX] = nil
            for key in pairs(Pabrik.Tiles) do
                local dx, dy = string.match(tostring(key), "^(-?%d+),(-?%d+)$")
                if dx then set[(Pabrik.BreakY + tonumber(dy)) * w.w + Pabrik.BreakX + tonumber(dx)] = nil end
            end
        end
    end
    Pabrik._set, Pabrik._setW, Pabrik._setAt = set, w, now
    return set
end

-- Titik & tile break masih sah? Hasil: true / false, alasan, bagian yang salah ("stand" / "tile")
--   titik berdiri: bisa dipijak
--   tile break   : maksimal 2 tile dari titik berdiri, bukan titik berdiri
-- (titik & tile break boleh di atas lantai terpilih: tile itu otomatis tidak ditanami)
function Pabrik.breakValid()
    local w = Refs.World
    if not w then return false, "world belum terbaca", "stand" end
    if Pabrik.BreakX < 0 then return false, "titik break belum diatur", "stand" end
    local bx, by = Pabrik.BreakX, Pabrik.BreakY
    if bx >= w.w or by >= w.h or by < 0 then return false, "titik break di luar world", "stand" end
    if not (openAt(bx, by) and realSupport(bx, by)) then return false, "titik break tidak bisa dipijak", "stand" end
    if next(Pabrik.Tiles) == nil then return false, "tile break belum dipilih", "tile" end
    for key in pairs(Pabrik.Tiles) do
        local dx, dy = string.match(tostring(key), "^(-?%d+),(-?%d+)$")
        dx, dy = tonumber(dx), tonumber(dy)
        if not dx or (dx == 0 and dy == 0) or abs(dx) > 2 or abs(dy) > 2 then
            return false, "tile break terlalu jauh dari titik berdiri", "tile"
        end
        local x, y = bx + dx, by + dy
        if x < 0 or y < 0 or x >= w.w or y >= w.h then return false, "tile break di luar world", "tile" end
    end
    return true
end

-- Titik & tile break otomatis kalau belum diatur / tidak sah (force = cari tempat baru walau yang lama sah).
--   Hanya tempat yang BISA DIDATANGI dari posisi sekarang, bukan yang pernah gagal (Pabrik.BreakBad).
--   Urutan pilihan: 3 tile kosong di luar tile tanam -> di lantai terpilih yang kosong -> yang berisi pohon
--   (3 tile itu otomatis tidak ditanami; pohon di tile break dipecah sendiri).
function Pabrik.prepareBreak(force)
    local w, s = Refs.World, playerState()
    if not (w and s) then return false end
    if not force and Pabrik.breakValid() then return true end
    local oldX, oldY, oldTiles = Pabrik.BreakX, Pabrik.BreakY, {}
    for key in pairs(Pabrik.Tiles) do oldTiles[key] = true end
    Pabrik.BreakX, Pabrik.BreakY = -1, -1
    table.clear(Pabrik.Tiles)
    Pabrik._setAt = 0
    local set = Pabrik.smartSet()
    local px, py = startNode(s)
    local reach = nil -- tempat yang bisa didatangi (A* tanpa tujuan)
    if px and s.grounded then
        local _, exhausted, closed = astar(px, py, {}, px, py, 0.5, false)
        if exhausted and type(closed) == "table" then reach = closed end
    end
    local function free(x, y)
        local id = fgIdAt(x, y)
        if id == 0 then return true end
        local it = ItemDB[id]
        return it ~= nil and it.kind == "seed"
    end
    local best, bestCost = nil, nil
    local n = 0
    if px then
        for y = 1, w.h - 2 do
            for x = 0, w.w - 3 do
                n += 1
                if n % 3000 == 0 then task.wait() end
                local i = y * w.w + x
                if not Pabrik.BreakBad[x .. "," .. y] and (not reach or reach[i])
                    and free(x, y) and free(x + 1, y) and free(x + 2, y)
                    and Pabrik.floorOk(x, y + 1) and Pabrik.floorOk(x + 1, y + 1) and Pabrik.floorOk(x + 2, y + 1) then
                    local inSet = set[i] or set[i + 1] or set[i + 2]
                    local trees = (fgIdAt(x + 1, y) ~= 0 and 1 or 0) + (fgIdAt(x + 2, y) ~= 0 and 1 or 0)
                    local c = math.abs(x - px) + math.abs(y - py) * 2 + (inSet and 1000 or 0) + trees * 3000
                    if not bestCost or c < bestCost then best, bestCost = { x = x, y = y, inSet = inSet }, c end
                end
            end
        end
    end
    if not best then
        -- tidak ketemu: yang lama dikembalikan
        Pabrik.BreakX, Pabrik.BreakY = oldX, oldY
        for key in pairs(oldTiles) do Pabrik.Tiles[key] = true end
        Pabrik._setAt = 0
        notify("Pabrik", "Tidak ada tempat break yang terjangkau (butuh 3 tile lantai berjajar). Atur di peta", 6)
        return false
    end
    Pabrik.BreakX, Pabrik.BreakY = best.x, best.y
    Pabrik.Tiles["1,0"] = true
    Pabrik.Tiles["2,0"] = true
    Pabrik.saveBreak()
    notify("Pabrik", ("Titik break otomatis (%d,%d)%s"):format(best.x, best.y,
        best.inSet and " di lantai terpilih (3 tile itu tidak ditanami)" or ""), 5)
    return true
end

local function breakReady()
    return Pabrik.BreakX >= 0 and next(Pabrik.Tiles) ~= nil and os.clock() >= (Pabrik.BreakFailUntil or 0)
end

-- Break gagal: catat alasannya. 2x berturut-turut -> tempat itu ditandai buruk & dicari tempat break lain.
local function breakFailed(why, sec)
    Pabrik.BreakWhy = why
    Pabrik.BreakFails = (Pabrik.BreakFails or 0) + 1
    Pabrik.BreakFailUntil = os.clock() + sec
    Pabrik.Status = "Break gagal: " .. why
    if Pabrik.BreakFails >= 2 and Pabrik.BreakX >= 0 then
        local ox, oy = Pabrik.BreakX, Pabrik.BreakY
        Pabrik.BreakBad[ox .. "," .. oy] = true
        local ok, found = pcall(Pabrik.prepareBreak, true)
        if ok and found and (Pabrik.BreakX ~= ox or Pabrik.BreakY ~= oy) then
            Pabrik.BreakFails = 0
            Pabrik.BreakFailUntil = 0
            Pabrik.BreakWhy = ("titik (%d,%d) gagal, pindah ke (%d,%d)"):format(ox, oy, Pabrik.BreakX, Pabrik.BreakY)
        end
    end
end

-- Batas seed untuk drop (tidak boleh di atas batas aman tas)
local function pabrikDropAt()
    return math.min(Pabrik.DropAt, CAP)
end

-- Break block di titik break (mesin Auto Farm dengan tile & block pabrik).
-- Tile break dikunci ke koordinat titik break (anchor): kalau badan bergeser, bot balik dulu ke titik itu.
local function pabrikBreak(o)
    if os.clock() < (Pabrik.BreakFailUntil or 0) then return false end
    local s = playerState()
    if not s then return false end
    local hx, hy = startNode(s)
    if hx ~= Pabrik.BreakX or hy ~= Pabrik.BreakY then
        Pabrik.Status = ("Jalan ke titik break (%d,%d)"):format(Pabrik.BreakX, Pabrik.BreakY)
        if not walkTo(Pabrik.BreakX, Pabrik.BreakY, 45) then
            if o.live() then
                breakFailed(("tidak bisa jalan ke titik break (%d,%d)"):format(Pabrik.BreakX, Pabrik.BreakY), 15)
            end
            return false
        end
    end
    if not o.live() then return false end
    State.Override = {
        offsets = Pabrik.Tiles, block = o.block, mode = "Place + Break",
        anchor = { x = Pabrik.BreakX, y = Pabrik.BreakY },
    }
    State.Quiet = true
    table.clear(HitCount)
    table.clear(PlacedAt)
    State.Running = true
    State.RunId = (State.RunId or 0) + 1
    local id = State.RunId
    local acts0 = State.Placed + State.Broken
    local lastActs, lastActAt = acts0, os.clock()
    local hit0 = os.clock()
    State.HitAt = 0
    local dropOn = Pabrik.Drop and Pabrik.pointSet()
    task.spawn(function() -- pengawas sesi break
        while State.Running and State.RunId == id do
            task.wait(1)
            local sd = invCount(o.seed)
            local acts = State.Placed + State.Broken
            if acts ~= lastActs then lastActs, lastActAt = acts, os.clock() end
            if (State.HitAt or 0) > lastActAt then lastActAt = State.HitAt end -- pukulan juga dihitung aktivitas
            -- break terus sampai block habis (tanpa batas waktu sesi)
            if not o.live() or sd >= CAP
                or (dropOn and sd >= pabrikDropAt())
                or os.clock() - lastActAt > 8 then -- 8 detik tidak ada place / pukul: jangan diam di sini
                State.Running = false
            end
        end
    end)
    local fastOld = State.Fast
    if Pabrik.Fast then
        if not Refs.Punch then pcall(findRefs) end
        if Refs.Punch then State.Fast = true end
        State.NextHitAt = 0
    end
    Pabrik.Status = "Break " .. itemName(o.block) .. " di titik break" .. (State.Fast and " (Break Cepat)" or "")
    local ok, e = pcall(farmLoop, id)
    State.Fast = fastOld
    if not ok then warn("[SkyP] Pabrik break error: " .. tostring(e)) end
    State.Running = false
    State.Override = nil
    State.Quiet = false
    -- v2.3: jalur yang sempat gagal selama break (balik ke titik break / ambil drop) jangan ikut
    -- menghalangi jalan ke rute panen sesudahnya
    table.clear(BadEdge)
    Reach = nil
    releaseInput()
    if State.Placed + State.Broken == acts0 and (State.HitAt or 0) < hit0 then
        if o.live() and invCount(o.block) > 0 and invCount(o.seed) < CAP then
            breakFailed("tidak ada block yang bisa dipasang / dipukul di tile break (" .. tostring(State.LastAction) .. ")", 20)
        end
    else
        Pabrik.BreakFails = 0
        Pabrik.BreakWhy = nil
    end
    return true
end

-- "WORLD" / "WORLD:ID" / ":ID" -> nama world, id pintu
local function parseDropTarget()
    local raw = tostring(Pabrik.DropWorld or ""):gsub("%s", "")
    local name, door = string.match(raw, "^([^:]*):(.+)$")
    if not name then name = raw end
    name = string.upper(name):gsub("[^A-Z0-9]", "")
    if door == "" then door = nil end
    return name, door
end

-- Pindah world (lewat menu game), bisa langsung ke pintu tertentu
local function goWorld(name, door)
    if Guard.inWorld() then
        Guard.leaveWorld()
        task.wait(2)
    end
    if door and Refs.World then rawset(Refs.World, "arriveDoor", door) end
    local ok, err = Guard.enterWorld(name)
    if ok then
        task.wait(1.5)
        Guard.afterEnter()
    end
    return ok, err
end

-- Drop pakai fungsi drop game (item jatuh di depan karakter)
local function dropItems(id, n, live)
    local hud = Refs.Hud
    local f = hud and rawget(hud, "onDrop")
    if type(f) ~= "function" then return 0, "fungsi drop game tidak ketemu" end
    local left, flipped = n, false
    while left > 0 and live() do
        local before = invCount(id)
        pcall(f, id, math.min(left, 200))
        task.wait(0.7) -- game menolak drop yang terlalu cepat (0.3 dtk)
        local got = before - invCount(id)
        if got > 0 then
            left -= got
        elseif not flipped then
            -- di depan tembok / tidak boleh drop: hadap ke arah lain lalu coba lagi
            flipped = true
            local st = playerState()
            local right = st and (st.facing or 1) < 0
            AutoInput.active = true
            AutoInput.right, AutoInput.left = right, not right
            task.wait(0.06)
            AutoInput.right, AutoInput.left = false, false
            task.wait(0.3)
        else
            return n - left, "tidak bisa drop di posisi ini"
        end
    end
    return n - left, nil
end

-- Titik drop bersama (dipakai Pabrik, Farmer, Auto Farm):
-- pergi ke titik drop (bisa world lain / WORLD:ID), drop item, lalu pulang ke world asal.
-- items = { { id =, n = }, ... }  -> it.got diisi jumlah yang berhasil di-drop
-- Hasil: ok, alasan ("nopoint" | "home" | teks error)
local function dropTrip(items, live, say)
    say = say or function() end
    local name, door = parseDropTarget()
    local home = Guard.worldName()
    if name == "" then name = home end
    if Pabrik.DropX < 0 and not door and name == home then
        say("Titik drop belum diatur (tab Titik Drop), drop dilewati")
        return false, "nopoint"
    end
    Pabrik.Traveling = true
    Pabrik.TravelAt = os.clock()
    local away = name ~= home
    local ok, why = true, nil
    if away or door then
        say("Pergi ke " .. name .. (door and (":" .. door) or "") .. " untuk drop")
        local okw, err = goWorld(name, door)
        if not okw then ok, why = false, "gagal masuk " .. name .. " (" .. tostring(err) .. ")" end
    end
    if ok and live() and Pabrik.DropX >= 0 then
        say(("Jalan ke posisi drop (%d,%d)"):format(Pabrik.DropX, Pabrik.DropY))
        if not walkTo(Pabrik.DropX, Pabrik.DropY, 60) then ok, why = false, "tidak bisa jalan ke posisi drop" end
    end
    if ok and live() then
        local s = playerState()
        if s then Pabrik.Zone = { world = Guard.worldName(), x = s.x, y = s.y - 0.475 } end
        for _, it in ipairs(items) do
            if not live() then break end
            local got, err = dropItems(it.id, it.n, live)
            it.got = got
            if got > 0 then
                local msg = ("Drop %s x%d di %s"):format(itemName(it.id), got, Guard.worldName())
                say(msg)
                notify("Drop", msg, 4)
                Hook.send("pabrik", msg)
            end
            if err then
                ok, why = false, err
                break
            end
        end
    end
    if not ok then
        say("Drop gagal: " .. tostring(why))
        notify("Drop", "Drop gagal: " .. tostring(why), 5)
        Hook.send("pabrik", "Drop gagal: " .. tostring(why))
    end
    -- pulang ke world asal
    if away and home ~= "" and live() then
        say("Pulang ke " .. home)
        local okh = goWorld(home, nil)
        if not okh and live() then
            task.wait(5)
            okh = goWorld(home, nil)
        end
        if not okh then
            Pabrik.Traveling = false
            autoEnd()
            return false, "home"
        end
    end
    Pabrik.Traveling = false
    autoEnd()
    return ok, why
end
Auto.dropTrip = dropTrip

-- Titik drop sudah diatur? (posisi, WORLD:ID, atau world lain)
function Pabrik.pointSet()
    if Pabrik.DropX >= 0 then return true end
    local name, door = parseDropTarget()
    if door then return true end
    return name ~= "" and name ~= Guard.worldName()
end

local function pabrikDrop(seed, n, live)
    local items = { { id = seed, n = n } }
    local ok, why = dropTrip(items, live, function(t) Pabrik.Status = t end)
    Pabrik.Dropped += items[1].got or 0
    if why == "home" then
        if Pabrik.stop then Pabrik.stop("Gagal pulang ke world pabrik " .. tostring(Pabrik.Home)) end
    elseif not ok then
        Pabrik.DropOffUntil = os.clock() + ((why == "nopoint") and 60 or 120)
    end
end

-- Auto Farm: seed hasil break sudah banyak -> jeda, drop seed ke titik drop,
-- balik ke posisi farm, lalu lanjut lagi (dicek tiap 2 detik)
task.spawn(function()
    while alive() do
        task.wait(2)
        local seed = State.SelectedId and seedOfBlock(State.SelectedId)
        if State.Running and State.SeedDrop and not State.Override and Pabrik.pointSet() and not State.DropPause and seed
            and os.clock() >= (State.DropOffUntil or 0) then
            local n = invCount(seed)
            local s = playerState()
            if s and n >= State.SeedDropAt and n > State.SeedKeep then
                local hx, hy = startNode(s)
                if State.Home then hx, hy = State.Home.x, State.Home.y end
                local runId = State.RunId
                local function live() return State.Running and alive() and State.RunId == runId end
                State.DropPause = true
                task.wait(0.8) -- tunggu pukulan terakhir selesai
                local items = { { id = seed, n = n - State.SeedKeep } }
                local ok, why = dropTrip(items, live, function(t) State.LastAction = t end)
                State.Dropped += items[1].got or 0
                if not ok then State.DropOffUntil = os.clock() + ((why == "nopoint") and 60 or 120) end
                if why == "home" then
                    stopFarm("Gagal pulang ke world farm")
                elseif live() then
                    State.LastAction = ("Jalan balik ke posisi farm (%d,%d)"):format(hx, hy)
                    if not walkTo(hx, hy, 60) then
                        stopFarm("Gagal balik ke posisi farm, Auto Farm dihentikan")
                    else
                        State.LastAction = "Lanjut Auto Farm"
                    end
                end
                State.DropPause = false
            end
        end
    end
end)

local function waitText(sec)
    sec = math.max(0, math.ceil(sec or 0))
    if sec >= 60 then return ("%dm %dd"):format(sec // 60, sec % 60) end
    return sec .. " dtk"
end

-- Dipakai status ringkas di tab Pabrik: jumlah pohon siap, detik ke pohon siap berikutnya, jumlah tile tanam
function Pabrik.summary()
    local w = Refs.World
    if not w then return nil end
    local st = workspace:GetServerTimeNow()
    local n, nxt, nPlant = 0, nil, 0
    for idx in pairs(Pabrik.smartSet()) do
        nPlant += 1
        local x, y = idx % w.w, idx // w.w
        local id = fgIdAt(x, y)
        if id ~= 0 then
            local ra = treeReadyAt(x, y, id)
            if ra then
                if st >= ra then
                    n += 1
                elseif not nxt or ra - st < nxt then
                    nxt = ra - st
                end
            end
        end
    end
    return n, nxt, nPlant
end

-- Tanda pilihan lantai (untuk tahu kapan rute harus dibuat ulang)
function Pabrik.pickSig()
    local n, sum = 0, 0
    for key in pairs(Pabrik.activePick()) do
        n += 1
        sum += #tostring(key) * 31
        local y, x0, x1 = string.match(tostring(key), "^(%d+),(%d+),(%d+)$")
        if y then sum += tonumber(y) * 7919 + tonumber(x0) * 104729 + tonumber(x1) * 1299709 end
    end
    return (Pabrik.Full and "F" or "P") .. tostring(Pabrik.Order) .. n .. ":" .. sum
end

-- RUTE TETAP dari lantai terpilih.
--   Urutan baris (Pabrik.Order): "Atas ke bawah" = lantai paling atas dulu, "Bawah ke atas" = paling bawah dulu,
--   "Terdekat dulu" = mulai dari ujung (atas / bawah) yang paling dekat dengan karakter.
--   Tiap baris lantai arah sapunya dibalik (serpentin); baris pertama mulai dari sisi yang dekat karakter.
--   Titik berdiri: di tile tanam (tepat di atas lantai), tiap titik melayani tile lo..hi (maks 5 tile).
-- check = true: sekali periksa titik mana yang tidak terjangkau dari posisi sekarang (ditandai merah di peta).
-- Hasil: daftar { x, y, lo, hi, key }  (y = baris tanam)
function Pabrik.buildRoute(check)
    local w = Refs.World
    local route = {}
    if not w then
        Pabrik.Route = route
        return route
    end
    local span = math.max(1, floor(farmReach() - 0.3)) -- tile yang terjangkau ke kiri / kanan dari titik berdiri
    local width = span * 2 + 1
    local segs = {}
    for key in pairs(Pabrik.activePick()) do
        local y, x0, x1 = string.match(tostring(key), "^(%d+),(%d+),(%d+)$")
        y, x0, x1 = tonumber(y), tonumber(x0), tonumber(x1)
        if y and x0 and x1 and y >= 1 and y < w.h then
            x0, x1 = math.max(0, x0), math.min(w.w - 1, x1)
            local a = nil -- lantai yang sudah bolong dipotong jadi deretan sendiri
            for x = x0, x1 + 1 do
                if x <= x1 and Pabrik.floorOk(x, y) then
                    a = a or x
                elseif a then
                    segs[#segs + 1] = { y = y, x0 = a, x1 = x - 1 }
                    a = nil
                end
            end
        end
    end
    table.sort(segs, function(p, q)
        if p.y ~= q.y then return p.y < q.y end
        return p.x0 < q.x0
    end)
    local rows, i = {}, 1 -- rows[n] = titik berdiri 1 baris lantai (kiri -> kanan), dari atas ke bawah
    while i <= #segs do
        local j = i
        while segs[j + 1] and segs[j + 1].y == segs[i].y do j += 1 end
        local row = {}
        for k = i, j do
            local sg = segs[k]
            local lo = sg.x0
            while lo <= sg.x1 do
                local hi = math.min(sg.x1, lo + width - 1)
                local sx = (lo + hi) // 2
                row[#row + 1] = { x = sx, y = sg.y - 1, lo = lo, hi = hi, key = sx .. "," .. (sg.y - 1) }
                lo = hi + 1
            end
        end
        if #row > 0 then rows[#rows + 1] = row end
        i = j + 1
    end
    if #rows > 0 then
        local px, py = Auto.here()
        local fromBottom = Pabrik.Order == "Bawah ke atas"
        if Pabrik.Order == "Terdekat dulu" and py then
            fromBottom = math.abs(py - rows[#rows][1].y) < math.abs(py - rows[1][1].y)
        end
        local a, b, step = 1, #rows, 1
        if fromBottom then a, b, step = #rows, 1, -1 end
        -- baris pertama disapu mulai dari sisi yang lebih dekat karakter
        local first = rows[a]
        local dir = 1
        if px and math.abs(px - first[#first].x) < math.abs(px - first[1].x) then dir = -1 end
        for r = a, b, step do
            local row = rows[r]
            if dir == 1 then
                for k = 1, #row do route[#route + 1] = row[k] end
            else
                for k = #row, 1, -1 do route[#route + 1] = row[k] end
            end
            dir = -dir
        end
    end
    if check and #route > 0 then
        local s = playerState()
        if s and s.grounded then
            local sx, sy = startNode(s)
            -- A* tanpa tujuan = menjelajah semua tempat yang bisa didatangi dari sini
            local _, exhausted, closed = astar(sx, sy, {}, sx, sy, 0.5, false)
            if exhausted and type(closed) == "table" then
                local bad = {}
                for _, st in ipairs(route) do
                    if not closed[st.y * w.w + st.x] then bad[#bad + 1] = st end
                end
                -- semua titik "tidak terjangkau" = hasil periksa tidak bisa dipercaya: biarkan dicoba langsung
                if #bad < #route then
                    local now = os.clock()
                    for _, st in ipairs(bad) do Pabrik.Bad[st.key] = now + 300 end
                end
            end
        end
    end
    Pabrik.Route = route
    return route
end

-- Pekerjaan di 1 titik berdiri: pohon siap panen & tempat tanam kosong.
-- Hasil: daftar panen, daftar tanam, jumlah pohon siap, jumlah pohon, detik ke pohon siap berikutnya, jumlah tile terisi
function Pabrik.stopTiles(stp, o, set, canHarvest)
    local w = Refs.World
    local st = workspace:GetServerTimeNow()
    local now = os.clock()
    local harvest, plant = {}, {}
    local ripe, trees, nxt, used = 0, 0, nil, 0
    for x = stp.lo, stp.hi do
        local idx = stp.y * w.w + x
        if set[idx] then
            local id = fgIdAt(x, stp.y)
            if id == 0 then
                if not skipped(Pabrik.Skip, idx, now) and plantSpotOk(x, stp.y, o.seed) then
                    plant[#plant + 1] = { x = x, y = stp.y, idx = idx }
                end
            else
                used += 1
                local ra = treeReadyAt(x, stp.y, id)
                if ra then
                    trees += 1
                    if st >= ra then
                        if not skipped(Pabrik.Skip, idx, now) then
                            ripe += 1
                            if canHarvest then harvest[#harvest + 1] = { x = x, y = stp.y, idx = idx } end
                        end
                    elseif not nxt or ra - st < nxt then
                        nxt = ra - st
                    end
                end
            end
        end
    end
    return harvest, plant, ripe, trees, nxt, used
end

-- Hitung keadaan semua titik rute (titik merah / tidak terjangkau dihitung terpisah)
function Pabrik.scan(o, set, route)
    local now = os.clock()
    local sc = { ready = 0, badReady = 0, plantable = 0, trees = 0, used = 0, nxt = nil, bad = 0 }
    for _, stp in ipairs(route) do
        local bad = (Pabrik.Bad[stp.key] or 0) > now
        local _, plant, ripe, trees, nxt, used = Pabrik.stopTiles(stp, o, set, false)
        sc.trees += trees
        sc.used += used
        if nxt and (not sc.nxt or nxt < sc.nxt) then sc.nxt = nxt end
        if bad then
            sc.bad += 1
            sc.badReady += ripe
        else
            sc.ready += ripe
            sc.plantable += #plant
        end
    end
    return sc
end

-- Kerjakan 1 titik berdiri: panen -> ambil drop (sentuhan) -> tanam. Hasil: jumlah aksi
function Pabrik.workStop(stp, o, set, canHarvest)
    local R = farmReach() - 0.08
    local done = 0
    local harvest = Pabrik.stopTiles(stp, o, set, canHarvest)
    local got = {}
    for _, t in ipairs(harvest) do
        if not o.live() then return done end
        local cur = playerState()
        if not cur or cur.dead then return done end
        if stateReaches(cur, t.x, t.y, R) and canWorkAt(t.x, t.y) then
            local id = fgIdAt(t.x, t.y)
            local r = tryBreak(t.x, t.y, false) -- pohon siap: 1 pukulan = panen
            if r == "broke" then
                Pabrik.Harvested += 1
                Pabrik.PlantN[t.idx] = nil
                got[#got + 1] = t
                done += 1
                Pabrik.Status = "Panen " .. itemName(id) .. " (" .. t.x .. "," .. t.y .. ")"
            else
                skipTile(Pabrik.Skip, t.idx, 30)
            end
            if not waitAuto(Farmer.HarvestMs) then return done end
        else
            skipTile(Pabrik.Skip, t.idx, 60)
        end
    end
    -- ambil hasil panen dengan sentuhan badan, hanya di lantai ini (lalu balik ke titik berdiri)
    if #got > 0 then
        local before = invCount(o.seed)
        Pabrik.Status = "Ambil hasil panen (sentuhan)"
        Drops.waitSpawn(got)
        if not o.live() then return done end
        local back = Drops.touchAll(got, stp.x, stp.y)
        if not o.live() then return done end
        -- pungutan dibalas server sesuai ping: tunggu sebentar supaya seed-nya bisa langsung ditanam
        local ping = 0.1
        pcall(function() ping = LocalPlayer:GetNetworkPing() end)
        local t0 = os.clock()
        while o.live() and invCount(o.seed) <= before and os.clock() - t0 < math.clamp(0.2 + 3 * ping, 0.3, 1.2) do
            task.wait(0.05)
        end
        if not back then
            local hx, hy = Auto.here()
            if hx ~= stp.x or hy ~= stp.y then walkTo(stp.x, stp.y, 10) end
        end
    end
    local _, plant = Pabrik.stopTiles(stp, o, set, false)
    for _, t in ipairs(plant) do
        if not o.live() then return done end
        if invCount(o.seed) <= 0 then break end
        local cur = playerState()
        if not cur or cur.dead then return done end
        if stateReaches(cur, t.x, t.y, R) and fgIdAt(t.x, t.y) == 0 then
            local n = (Pabrik.PlantN[t.idx] or 0) + 1
            Pabrik.PlantN[t.idx] = n
            if n > 3 then
                -- sudah 3x ditanam tapi kosong lagi (ditolak server): lewati dulu
                Pabrik.PlantN[t.idx] = nil
                skipTile(Pabrik.Skip, t.idx, 300)
            else
                sendSetTile("fg", t.x, t.y, o.seed)
                pcall(function() Refs.Inv:remove(o.seed, 1) end)
                Pabrik.Planted += 1
                done += 1
                Pabrik.Status = "Tanam " .. itemName(o.seed) .. " (" .. t.x .. "," .. t.y .. ")"
                if not waitAuto(Farmer.PlantMs) then return done end
            end
        end
    end
    return done
end

-- v2.3: berapa titik rute (selain tempat berdiri sekarang) yang bisa didatangi dari posisi sekarang.
-- Untuk membedakan "titik itu tidak terjangkau" dengan "karakter yang terjebak". nil = tidak bisa dicek.
function Pabrik.reachableSteps(route)
    local w, s = Refs.World, playerState()
    if not (w and s) then return nil end
    local sx, sy = startNode(s)
    local _, exhausted, closed = astar(sx, sy, {}, sx, sy, 0.5, false)
    if type(closed) ~= "table" then return nil end
    if not exhausted then return math.huge end -- area terlalu luas untuk dihitung: jelas tidak terjebak
    local n = 0
    for _, st in ipairs(route) do
        if not (st.x == sx and st.y == sy) and closed[st.y * w.w + st.x] then n += 1 end
    end
    return n
end

-- 1x jalan mengikuti rute. Titik tanpa pekerjaan & titik merah dilewati. Hasil: jumlah aksi
function Pabrik.runPass(o, route, set)
    local did = 0
    for i, stp in ipairs(route) do
        if not o.live() then break end
        if Pabrik.Home ~= "" and Guard.worldName() ~= Pabrik.Home then break end
        if not ((Pabrik.Bad[stp.key] or 0) > os.clock()) then
            local canHarvest = invCount(o.block) < CAP - 20 and invCount(o.seed) < CAP - 20
            local harvest, plant = Pabrik.stopTiles(stp, o, set, canHarvest)
            if #harvest > 0 or (#plant > 0 and invCount(o.seed) > 0) then
                Pabrik.Progress = ("Rute %d/%d, lantai y=%d"):format(i, #route, stp.y + 1)
                local hx, hy = Auto.here()
                local ok = hx == stp.x and hy == stp.y
                if not ok then
                    Pabrik.Status = ("Jalan ke titik (%d,%d)"):format(stp.x, stp.y)
                    ok = walkTo(stp.x, stp.y, 30)
                end
                if not o.live() then break end
                if ok then
                    Pabrik.StuckN = 0
                    did += Pabrik.workStop(stp, o, set, canHarvest)
                else
                    -- v2.3: sebelum menandai merah, cek dulu: titik itu memang tidak terjangkau,
                    -- atau KARAKTER yang terjebak / jalur keluarnya barusan macet (sering habis break).
                    -- Dulu langsung ditandai merah, jadi sekali macet SEMUA titik rute ikut merah.
                    table.clear(BadEdge)
                    Reach = nil
                    releaseInput()
                    local n = Pabrik.reachableSteps(route)
                    if not o.live() then break end
                    local trapped = n ~= nil and n < math.max(3, math.floor(#route * 0.2))
                    local rejoinedLately = os.clock() - (Pabrik.StuckRejoinAt or -1e9) < 600
                    if trapped and not rejoinedLately then
                        Pabrik.StuckN = (Pabrik.StuckN or 0) + 1
                        local hx2, hy2 = Auto.here()
                        if Pabrik.StuckN >= 3 and Session.rejoinNow then
                            -- 3x berturut-turut terjebak: masuk ulang world (karakter muncul di pintu), Pabrik dilanjutkan
                            Pabrik.StuckN = 0
                            Pabrik.StuckRejoinAt = os.clock()
                            Pabrik.Status = ("Karakter terjebak di (%s,%s), masuk ulang world..."):format(tostring(hx2), tostring(hy2))
                            Hook.send("pabrik", Pabrik.Status)
                            Session.rejoinNow()
                        else
                            Pabrik.Status = ("Jalan buntu dari (%s,%s), dicoba lagi (%d/3)"):format(tostring(hx2), tostring(hy2), Pabrik.StuckN)
                            task.wait(1)
                        end
                        break
                    end
                    -- titik itu memang tidak terjangkau: tandai merah, dicoba lagi 3 menit kemudian
                    Pabrik.Bad[stp.key] = os.clock() + 180
                    Pabrik.Status = ("Titik (%d,%d) tidak terjangkau, dilewati"):format(stp.x, stp.y)
                end
            end
        end
    end
    Pabrik.Progress = nil
    releaseInput()
    return did
end

-- Panen dimulai kalau pohon siap sudah Pabrik.ReadyPct persen (atau tidak ada lagi yang hampir siap)

local function pabrikLoop(runId)
    local function live() return Pabrik.Running and alive() and Pabrik.RunId == runId end
    local o = { seed = Pabrik.SeedId, block = Pabrik.BlockId, live = live }
    if Pabrik.Full then -- Full world: pindai semua lantai dulu (tunggu kalau tab Pabrik sedang memindai)
        local t0 = os.clock()
        while live() and Pabrik._fullBusy and os.clock() - t0 < 10 do task.wait(0.1) end
        pcall(Pabrik.refreshFull, true)
    end
    pcall(Pabrik.prepareBreak)
    Pabrik.buildRoute(true)
    local pickSig = Pabrik.pickSig()
    while live() do
        task.wait()
        if not Pabrik.Traveling and Guard.pickerOpen and Guard.pickerOpen() then
            releaseInput()
            Pabrik.Status = "Di layar pilih world, menunggu masuk world lagi..."
            task.wait(2)
            continue
        end
        if not Pabrik.Traveling and Pabrik.Home ~= "" and Guard.worldName() ~= Pabrik.Home then
            Pabrik.Status = "Bukan di world pabrik (" .. Pabrik.Home .. "), menunggu..."
            task.wait(2)
            continue
        end
        local s = playerState()
        if not s or s.dead then
            releaseInput()
            Pabrik.Status = "Menunggu karakter / world..."
            task.wait(0.5)
            continue
        end
        pcall(Pabrik.refreshFull) -- Full world: lantai dipindai ulang berkala
        -- pilihan lantai / urutan rute diubah saat pabrik jalan: rute dibuat ulang
        local sig = Pabrik.pickSig()
        if sig ~= pickSig then
            pickSig = sig
            Pabrik._setAt = 0
            table.clear(Pabrik.Bad)
            Pabrik.buildRoute(true)
            pcall(Pabrik.prepareBreak)
        end
        local set = Pabrik.smartSet()
        local seeds, blocks = invCount(o.seed), invCount(o.block)
        local now = os.clock()
        Pabrik.Warn = nil

        -- 1) DROP seed lebihan (hanya di antara fase)
        local dropOn = Pabrik.Drop and Pabrik.pointSet()
        if dropOn and seeds >= pabrikDropAt() and seeds > Pabrik.Keep and now >= (Pabrik.DropOffUntil or 0) then
            Pabrik.Phase = "DROP"
            pabrikDrop(o.seed, seeds - Pabrik.Keep, live)
            continue
        end

        -- 2) PANEN + TANAM mengikuti rute
        local route = Pabrik.buildRoute(false)
        local sc = Pabrik.scan(o, set, route)
        local canHarvest = blocks < CAP - 20 and seeds < CAP - 20
        if sc.ready > 0 then o.readySince = o.readySince or now else o.readySince = nil end
        local harvestGo = canHarvest and sc.ready > 0
            and (sc.ready >= math.ceil(sc.trees * math.clamp(tonumber(Pabrik.ReadyPct) or 70, 10, 100) / 100) or sc.nxt == nil or sc.nxt > 20
                or now - (o.readySince or now) > 45)
        local plantGo = sc.plantable > 0 and seeds > 0 and now - (o.plantAt or 0) > 10
        if (harvestGo or plantGo) and now >= (o.passOffUntil or 0) then
            Pabrik.Phase = "PANEN+TANAM"
            local did = Pabrik.runPass(o, route, set)
            o.plantAt = os.clock()
            o.readySince = nil
            if did == 0 then o.passOffUntil = os.clock() + 5 end
            continue
        end

        -- 3) BREAK sampai block habis
        if blocks > 0 and (Pabrik.BreakX < 0 or next(Pabrik.Tiles) == nil) and now - (o.prepAt or -99) > 15 then
            o.prepAt = now -- titik break belum ada: cari otomatis lagi
            if select(2, pcall(Pabrik.prepareBreak)) == true then continue end
        end
        if blocks > 0 and seeds < CAP and not (dropOn and seeds >= pabrikDropAt()) and breakReady() then
            Pabrik.Phase = "BREAK"
            if pabrikBreak(o) then continue end
            if not live() then break end
        end

        -- 3b) Seed sudah menahan panen (>= CAP - 20) tapi belum sampai batas drop, dan tidak ada yang bisa di-break
        --     untuk menaikkannya: drop sekarang. Tanpa ini bot macet (panen ditunda, drop tidak pernah jalan).
        if dropOn and seeds >= CAP - 20 and seeds > Pabrik.Keep and now >= (Pabrik.DropOffUntil or 0) then
            Pabrik.Phase = "DROP"
            pabrikDrop(o.seed, seeds - Pabrik.Keep, live)
            continue
        end

        -- 4) TUNGGU
        Pabrik.Phase = "TUNGGU"
        if sc.used == 0 and sc.plantable == 0 and seeds <= 0 and blocks <= 0
            and not (Pabrik.Full and Pabrik.FullWorld ~= Pabrik.PickWorld) then -- Full world belum selesai memindai: jangan berhenti dulu
            if Pabrik.stop then Pabrik.stop("Seed & block habis, tidak ada pohon di tile terpilih") end
            break
        end
        if #route == 0 then
            Pabrik.Status = (Pabrik.Full and Pabrik.FullWorld ~= Pabrik.PickWorld) and "Full world: memindai lantai..."
                or Pabrik.Full and "Full world: tidak ada lantai (min 3 tile) yang bisa ditanami di world ini"
                or "Lantai terpilih sudah tidak ada. Buka peta lalu pilih lagi"
            Pabrik.Warn = Pabrik.Full and "tidak ada lantai di world ini" or "lantai terpilih hilang"
        elseif sc.bad >= #route then
            Pabrik.Status = "Semua tile terpilih tidak terjangkau dari sini (merah di peta), dicoba lagi nanti"
            Pabrik.Warn = "tile tidak terjangkau"
        elseif not Refs.Trees then
            Pabrik.Status = "Data pohon belum terbaca (tekan 'Hubungkan ke game'), panen menunggu"
            Pabrik.Warn = "data pohon belum terbaca"
        elseif seeds >= CAP - 20 and not dropOn then
            Pabrik.Status = ("Seed hampir penuh (%d): atur titik drop & nyalakan Auto drop seed"):format(seeds)
            Pabrik.Warn = "seed hampir penuh, atur titik drop"
        elseif sc.ready > 0 and not canHarvest then
            if seeds >= CAP - 20 and seeds <= Pabrik.Keep then
                Pabrik.Status = ("Seed %d menahan panen, tapi 'Sisakan seed' = %d jadi tidak ada yang di-drop. Kecilkan Sisakan seed"):format(seeds, Pabrik.Keep)
                Pabrik.Warn = "Sisakan seed terlalu besar"
            elseif seeds >= CAP - 20 and dropOn then
                Pabrik.Status = ("Seed %d menahan panen, drop gagal: dicoba lagi %d dtk (cek tab Titik Drop)"):format(seeds,
                    math.max(0, math.ceil((Pabrik.DropOffUntil or 0) - os.clock())))
                Pabrik.Warn = "drop seed gagal"
            else
                Pabrik.Status = "Tas hampir penuh, panen ditunda"
                Pabrik.Warn = "tas hampir penuh"
            end
        elseif blocks > 0 and (Pabrik.BreakX < 0 or next(Pabrik.Tiles) == nil) then
            Pabrik.Status = ("Ada %d block tapi titik / tile break belum diatur (peta: Mode Berdiri & Tile break)"):format(blocks)
            Pabrik.Warn = "titik break belum diatur"
        elseif blocks > 0 and seeds >= CAP then
            Pabrik.Status = ("Seed penuh (%d), break ditunda%s"):format(seeds, dropOn and ": drop seed gagal, dicoba lagi" or "")
            Pabrik.Warn = "seed penuh, break ditunda"
        elseif blocks > 0 and dropOn and seeds >= pabrikDropAt() then
            Pabrik.Status = ("Seed %d sudah batas drop tapi drop gagal, break ditunda (cek tab Titik Drop)"):format(seeds)
            Pabrik.Warn = "drop seed gagal"
        elseif blocks > 0 and not breakReady() then
            Pabrik.Status = "Break gagal: " .. tostring(Pabrik.BreakWhy or "?") .. ". Dicoba lagi "
                .. math.max(0, math.ceil((Pabrik.BreakFailUntil or 0) - os.clock())) .. " dtk"
            Pabrik.Warn = "break gagal"
        elseif sc.ready > 0 then
            Pabrik.Status = ("%d pohon siap, menunggu yang lain (±%s)"):format(sc.ready, waitText(sc.nxt or 0))
        elseif sc.nxt then
            Pabrik.Status = ("%s di tas: %d (habis), menunggu pohon siap ±%s"):format(itemName(o.block), blocks, waitText(sc.nxt))
        else
            Pabrik.Status = "Menunggu..."
        end
        if sc.badReady > 0 and not Pabrik.Warn then
            Pabrik.Warn = sc.badReady .. " pohon tidak terjangkau (merah di peta)"
        end
        if not waitAuto(1000) then break end
    end
    releaseInput()
end

function Pabrik.stop(reason)
    Pabrik.Running = false
    Pabrik.Traveling = false
    Pabrik.Warn = nil
    Pabrik.Progress = nil
    if State.Override then State.Running = false end
    Auto.stopWalk()
    autoEnd()
    releaseInput()
    Pabrik.Status = reason or "Dihentikan"
    if UI.PabrikToggle then pcall(function() UI.PabrikToggle:Set(false) end) end
    if reason then
        notify("Pabrik", reason, 5)
        if not string.find(reason, "^Dihentikan") then Hook.send("pabrik", "Pabrik berhenti: " .. reason) end
    end
end

function Pabrik.start()
    if Pabrik.Running then return end
    pcall(Pabrik.syncPick) -- pakai pilihan lantai milik world ini
    local err
    local block = blockOfSeed(Pabrik.SeedId)
    if not Refs.World then
        err = "Data world belum ketemu. Tekan 'Hubungkan ke game'"
    elseif not OrigIsDown then
        err = "Kontrol gerak game (WorldMenu.isDown) tidak ketemu"
    elseif not playerState() then
        err = "Kamu belum masuk world"
    elseif not Pabrik.SeedId then
        err = "Pilih seed pabrik dulu"
    elseif not block then
        err = "Block dari seed ini tidak ketemu"
    elseif not Pabrik.Full and next(Pabrik.Pick) == nil then
        err = "Pilih lantai dulu di peta (ketuk lantai tempat pohon ditanam), atau nyalakan Full world"
        if UI.openSmartMenu then pcall(UI.openSmartMenu) end
    end
    if err then
        notify("Pabrik", err, 4)
        if UI.PabrikToggle then pcall(function() UI.PabrikToggle:Set(false) end) end
        return
    end
    if State.Running and not State.Override then stopFarm("Dihentikan karena Pabrik dimulai") end
    if Clear.Running then stopClear("Dihentikan karena Pabrik dimulai") end
    if Farmer.Running then stopFarmer("Dihentikan karena Pabrik dimulai") end
    if Splice.Running and Splice.stop then Splice.stop("Dihentikan karena Pabrik dimulai") end
    if not Refs.Trees then findTreeRefs() end
    Pabrik.BlockId = block
    Pabrik.Home = Guard.worldName()
    Pabrik._setAt = 0
    table.clear(Pabrik.Skip)
    table.clear(Pabrik.Bad)
    table.clear(Pabrik.PlantN)
    table.clear(BadEdge)
    Pabrik.DropOffUntil, Pabrik.BreakFailUntil = 0, 0
    Pabrik.BreakFails, Pabrik.BreakWhy = 0, nil
    table.clear(Pabrik.BreakBad)
    Pabrik.Running = true
    Pabrik.RunId = (Pabrik.RunId or 0) + 1
    Pabrik.Status = "Mulai..."
    Pabrik.Phase = "TUNGGU"
    autoBegin()
    if UI.PabrikToggle then pcall(function() UI.PabrikToggle:Set(true) end) end
    local id = Pabrik.RunId
    task.spawn(function()
        local ok, e = pcall(pabrikLoop, id)
        if not ok then
            warn("[SkyP] Pabrik error: " .. tostring(e))
            if Pabrik.Running then Pabrik.stop("Error: " .. tostring(e)) end
        end
    end)
end

---------------------------------------------------------------------
-- VENDING
---------------------------------------------------------------------
-- Mode "Isi stock dari drop":
--   1. Pergi ke titik drop vending (WORLD / WORLD:ID, kosong = world ini), tunggu di sana sampai ada drop
--      item yang dijual vending-mu (atau item apa saja kalau ada vending kosong), pungut (sentuhan badan).
--   2. Pulang ke world vending, tambah stock ke vending yang menjual item itu / masukkan ke vending kosong.
--   3. Ulangi. Pindah world hanya kalau ada yang dibawa (hemat, tidak bolak-balik terus).
-- Mode "Kosongkan sampai habis":
--   Ambil isi semua vending milikmu. Tas penuh / semua sudah diambil -> pergi ke titik drop vending,
--   drop semua, pulang, lanjut sampai semua vending kosong.
-- Aksi vending lewat fungsi game (World.vendCall), karakter harus berdiri di depan mesin.
local VEND_STOCK, VEND_EMPTY = "Isi stock dari drop", "Kosongkan sampai habis"
Vend.Fail = {} -- vending yang gagal diambil isinya: [x,y] = jumlah gagal

function Vend.point()
    local raw = tostring(Vend.Point or ""):gsub("%s", "")
    local name, door = string.match(raw, "^([^:|]*)[:|](.+)$")
    if not name then name = raw end
    name = string.upper(name):gsub("[^A-Z0-9]", "")
    if door == "" then door = nil end
    return name, door
end

-- Vending milikmu di world ini: { x, y, fg, id, stock, cap }
function Vend.machines()
    local w = Refs.World
    local out = {}
    if not w then return out end
    local vends = rawget(w, "vends")
    local owner = rawget(w, "vendOwner")
    for y = 0, w.h - 1 do
        local row = w.fg[y]
        if row then
            for x = 0, w.w - 1 do
                local id = row[x] or 0
                local it = id ~= 0 and ItemDB[id]
                if it and it.vend then
                    local okO, mine = true, true
                    if type(owner) == "function" then okO, mine = pcall(owner, x, y) end
                    if okO and mine then
                        local d = nil
                        if type(vends) == "table" and type(vends.get) == "function" then
                            local okD, v = pcall(vends.get, x, y)
                            if okD and type(v) == "table" then d = v end
                        end
                        d = d or {}
                        if not d.shop then
                            out[#out + 1] = {
                                x = x, y = y, fg = id, id = d.id, stock = tonumber(d.stock) or 0,
                                cap = (id == 9268) and 10398 or 5199,
                            }
                        end
                    end
                end
            end
        end
    end
    return out
end

-- Item ini boleh diproses? (pilihan jenis + daftar item; tool & lock tidak pernah)
-- Bisa masuk vending? (gems, tool, lock, item tidak bisa ditrade, mesin vending: tidak)
function Vend.sellable(id)
    if type(id) ~= "number" or id == 112 then return false end
    local it = ItemDB[id]
    if not it or it.kind == "tool" then return false end
    if it.lock or it.area or it.guildLock or it.untradeable or it.vend or it.hub then return false end
    local nm = tostring(it.name or ""):lower()
    if nm == "gems" or nm == "gem" then return false end
    return true
end

function Vend.allow(id)
    if not Vend.sellable(id) then return false end
    if #Vend.Items > 0 and not table.find(Vend.Items, id) then return false end
    return true
end

function Vend.filtered()
    return #Vend.Items > 0
end

-- Pilihan item untuk dropdown: item di vending, di tas, drop yang pernah terlihat, dan yang sudah dipilih
function Vend.labels(machines)
    local seen = Vend.Seen
    local st = { inv = 0, drop = 0, vend = 0 }
    for _, m in ipairs(machines or {}) do
        if m.id then
            seen[m.id] = true
            st.vend += 1
        end
    end
    -- isi tas: baca slot inventori (sama seperti dropdown block / seed)
    if Refs.Inv then
        local okS, slots = pcall(function() return Refs.Inv.slots end)
        if okS and type(slots) == "table" then
            for _, slot in pairs(slots) do
                local id = type(slot) == "table" and tonumber(slot.id) or nil
                if id and (tonumber(slot.n) or 1) > 0 then
                    seen[id] = true
                    st.inv += 1
                end
            end
        end
    end
    -- drop di world ini
    local list = Drops.list
    if type(list) == "table" then
        local n, ids = 0, {}
        for _, d in pairs(list) do
            n += 1
            if n > 600 then break end
            local id = type(d) == "table" and tonumber(d.id) or nil
            if id and not ids[id] then
                ids[id] = true
                seen[id] = true
                st.drop += 1
            end
        end
    end
    for _, id in ipairs(Vend.Items) do seen[id] = true end
    local ids = {}
    for id in pairs(seen) do
        if Vend.sellable(id) then ids[#ids + 1] = id end
    end
    table.sort(ids)
    local labels, picked = {}, {}
    for _, id in ipairs(ids) do
        local label = ("%s [%d]"):format(tostring(itemName(id)), id)
        labels[#labels + 1] = label
        if table.find(Vend.Items, id) then picked[#picked + 1] = label end
    end
    return labels, picked, st
end

function Vend.call(...)
    local w = Refs.World
    local f = w and rawget(w, "vendCall")
    if type(f) ~= "function" then return false end
    local ok, res = pcall(f, ...)
    return ok and res == true
end

-- Berdiri di depan vending (aturan game: <= 0.85 tile mendatar, sebaris)
function Vend.goTo(m)
    local function near(c)
        return c ~= nil and math.abs(c.x - (m.x + 0.5)) <= 0.84 and math.abs((c.y - 0.5) - (m.y + 0.5)) <= 0.58
    end
    if near(playerState()) then return true end
    if walkTo(m.x, m.y, 40) and near(playerState()) then return true end
    for _, dx in ipairs({ -1, 1 }) do
        if walkTo(m.x + dx, m.y, 30) then
            local t0 = os.clock()
            AutoInput.active = true
            while alive() and os.clock() - t0 < 1 do
                task.wait()
                local c = playerState()
                if not c then break end
                steerX(c, m.x + 0.5 + dx * 0.55, 0.06)
                if near(c) and c.grounded then break end
            end
            releaseInput()
            if near(playerState()) then return true end
        end
    end
    return false
end

function Vend.sortNear(list)
    local s = playerState()
    if not s then return list end
    table.sort(list, function(a, b)
        local da = math.abs(a.x + 0.5 - s.x) + 2 * math.abs(a.y + 1 - s.y)
        local db = math.abs(b.x + 0.5 - s.x) + 2 * math.abs(b.y + 1 - s.y)
        return da < db
    end)
    return list
end

-- Tambah stock HANYA dari item hasil pungut (Vend.Picked = jumlahnya), bukan barang lain di tas.
-- Item hasil pungut yang belum punya vending -> vending kosong.
function Vend.stockAll(live)
    local list = Vend.sortNear(Vend.machines())
    local selling = {}
    for _, m in ipairs(list) do
        if m.id and m.stock > 0 then selling[m.id] = true end
    end
    local done, tried = 0, 0
    for _, m in ipairs(list) do
        if not live() then break end
        local id = (m.id and m.stock > 0) and m.id or nil
        if id and not Vend.allow(id) then id = nil end
        local n = 0
        if id then
            -- vending yang sudah menjual item ini: semua isi tas ikut di-stock
            n = math.min(invCount(id), m.cap - m.stock)
        elseif not (m.id and m.stock > 0) then
            -- vending kosong: item pilihan yang ada di tas, atau (tanpa pilihan) item hasil pungut
            local cands = {}
            if #Vend.Items > 0 then
                for _, pid in ipairs(Vend.Items) do cands[#cands + 1] = pid end
            else
                for pid, cnt in pairs(Vend.Picked) do
                    if cnt > 0 then cands[#cands + 1] = pid end
                end
                table.sort(cands)
            end
            for _, pid in ipairs(cands) do
                if not selling[pid] and Vend.allow(pid) and invCount(pid) > 0 then
                    id = pid
                    break
                end
            end
            if id then
                n = math.min(invCount(id), m.cap)
                if #Vend.Items == 0 then n = math.min(n, Vend.Picked[id] or 0) end
            end
        end
        if id and n > 0 then
            tried += 1
            Vend.Status = ("Ke vending (%d,%d): tambah %s x%d"):format(m.x, m.y, itemName(id), n)
            if Vend.goTo(m) then
                if Vend.call("stock", m.x, m.y, id, n) then
                    selling[id] = true
                    if Vend.Picked[id] then
                        Vend.Picked[id] -= n
                        if Vend.Picked[id] <= 0 then Vend.Picked[id] = nil end
                    end
                    Vend.Stocked += n
                    done += n
                    Vend.Status = ("Stock %s +%d di (%d,%d)"):format(itemName(id), n, m.x, m.y)
                    task.wait(0.3)
                else
                    Vend.Status = ("Gagal tambah stock di (%d,%d)"):format(m.x, m.y)
                    task.wait(0.5)
                end
            else
                Vend.Status = ("Tidak bisa ke vending (%d,%d)"):format(m.x, m.y)
            end
        end
    end
    return done, tried
end

-- Item yang dicari untuk diisi: yang dijual vending & belum penuh.
-- Vending kosong: boleh diisi item baru (maksimal sejumlah vending kosong, item yang vendingnya penuh tidak diambil).
function Vend.wanted()
    local want, sold, empty = {}, {}, 0
    for _, m in ipairs(Vend.machines()) do
        if m.id and m.stock > 0 then
            sold[m.id] = true
            if m.stock < m.cap and Vend.allow(m.id) then want[m.id] = true end
        else
            empty += 1
        end
    end
    return want, empty, sold
end

-- Pindah world (lewat menu game); world sama & tanpa pintu = tidak pindah
function Vend.travel(name, door)
    if name == Guard.worldName() and not door then return true end
    local ok, err = goWorld(name, door)
    if ok then
        -- tunggu karakter muncul di world tujuan (bukan jeda tetap)
        local t0 = os.clock()
        while os.clock() - t0 < 4 and not (playerState() and Guard.worldName() == name) do task.wait(0.1) end
        task.wait(0.2)
    end
    return ok, err
end

-- Pungut drop item yang dicari di world ini (sentuhan badan, per baris). Hasil: jumlah item terambil.
function Vend.pickHere(live, want, empty, sold)
    local before = {} -- jumlah di tas sebelum item itu dipungut (dicatat saat drop-nya pertama dilihat)
    local newIds = 0
    for id, cnt in pairs(Vend.Picked) do
        if not sold[id] and cnt > 0 and invCount(id) > 0 then newIds += 1 end
    end
    local function wantId(d)
        if not Vend.allow(d.id) then return false end
        if not want[d.id] then
            if sold[d.id] or empty <= 0 then return false end -- vending item ini penuh / tidak ada vending kosong
            if before[d.id] == nil and not (Vend.Picked[d.id] and invCount(d.id) > 0) then
                if newIds >= empty then return false end -- vending kosong sudah "dipesan" item lain
                newIds += 1
            end
        end
        if before[d.id] == nil then before[d.id] = invCount(d.id) end
        return true
    end
    Move.NoZone = true -- drop yang di-drop Pabrik di titik drop boleh diambil
    Move.fetchDrops(live, 999, wantId, 240)
    Move.NoZone = false
    local got = 0
    for id, n in pairs(before) do
        local diff = invCount(id) - n
        if diff > 0 then
            got += diff
            Vend.Picked[id] = (Vend.Picked[id] or 0) + diff
        end
    end
    return got
end

-- Drop semua hasil kosongkan vending di titik drop vending, lalu pulang
function Vend.dropTrip(live, home)
    local name, door = Vend.point()
    if name == "" then name = home end
    local items = {}
    for id, cnt in pairs(Vend.Carry) do -- hanya jumlah yang diambil dari vending (barang lain di tas tidak ikut)
        local n = math.min(cnt, invCount(id))
        if n > 0 then items[#items + 1] = { id = id, n = n } end
    end
    if #items == 0 then return true end
    Vend.Status = "Pergi ke titik drop " .. name .. (door and (":" .. door) or "")
    local ok, err = Vend.travel(name, door)
    if not ok then
        Vend.Status = "Gagal ke titik drop: " .. tostring(err)
        return false
    end
    if not Vend.goSpot(live) then return false end
    for _, it in ipairs(items) do
        if not live() then break end
        local got, derr = dropItems(it.id, it.n, live)
        Vend.Dropped += got
        if got > 0 then
            local msg = ("Drop %s x%d di %s"):format(itemName(it.id), got, Guard.worldName())
            Vend.Status = msg
            Hook.send("pabrik", "Vending: " .. msg)
        end
        if derr then Vend.Status = "Drop: " .. tostring(derr) end
    end
    if Guard.worldName() ~= home and live() then
        Vend.Status = "Pulang ke " .. home
        local okh = Vend.travel(home, nil)
        if not okh and live() then
            task.wait(5)
            okh = Vend.travel(home, nil)
        end
        if not okh then return false, "home" end
    end
    return true
end

-- Jalan ke posisi drop vending yang disimpan (kalau diatur)
function Vend.goSpot(live)
    if Vend.DropX < 0 or not live() then return true end
    local s = playerState()
    if s then
        local hx, hy = startNode(s)
        if hx == Vend.DropX and hy == Vend.DropY then return true end
    end
    Vend.Status = ("Jalan ke posisi drop vending (%d,%d)"):format(Vend.DropX, Vend.DropY)
    if walkTo(Vend.DropX, Vend.DropY, 60) then return true end
    Vend.Status = ("Tidak bisa jalan ke posisi drop vending (%d,%d)"):format(Vend.DropX, Vend.DropY)
    return false
end

-- Drop yang kamu buang sendiri baru bisa dipungut setelah karakter menjauh (aturan game: armed).
-- Kalau berdiri di atas / dekat drop sendiri item yang dicari: geser 2-4 tile, tunggu sebentar.
function Vend.stepAway(live)
    local s = playerState()
    local list = Drops.list
    if not s or type(list) ~= "table" or not live() then return false end
    local near = false
    for _, d in pairs(list) do
        if type(d) == "table" and d.armed == false and type(d.x) == "number" and type(d.y) == "number"
            and Vend.allow(d.id) and math.abs(d.x - s.x) < 1.8 and math.abs(d.y - (s.y - 0.5)) < 1.8 then
            near = true
            break
        end
    end
    if not near then return false end
    local hx, hy = startNode(s)
    for _, dx in ipairs({ 3, -3, 2, -2, 4, -4 }) do
        if not live() then return false end
        Vend.Status = "Menjauh dari drop sendiri supaya bisa dipungut"
        if walkTo(hx + dx, hy, 8) then
            Vend.sleep(0.6, live)
            return true
        end
    end
    return false
end

-- Setelah pindah world: tunggu data world & vending termuat (maks 12 dtk). Hasil: daftar vending
function Vend.waitWorld(home, live)
    local t0 = os.clock()
    local list = {}
    while live() and os.clock() - t0 < 25 do
        if Guard.worldName() == home and playerState() then
            list = Vend.machines()
            if #list > 0 then return list end
        end
        task.wait(0.5)
    end
    return list
end

-- Titik drop diatur? (world lain / pintu / posisi XY)
function Vend.hasPoint()
    local name, door = Vend.point()
    return name ~= "" or door ~= nil or Vend.DropX >= 0
end

-- Gangguan sementara (ping tinggi, server telat, gagal pindah world): coba lagi dengan jeda
-- yang makin panjang. Baru berhenti setelah 8x gagal berturut-turut. Hasil: true = lanjut.
function Vend.soft(reason, live)
    Vend.Soft = (Vend.Soft or 0) + 1
    if Vend.Soft > 8 then
        Vend.stop(reason)
        return false
    end
    Vend.Status = reason .. (" - coba lagi %d/8"):format(Vend.Soft)
    Vend.sleep(math.min(2 + Vend.Soft * 2, 15), live)
    return live()
end

-- tunggu (bisa dihentikan)
function Vend.sleep(sec, live)
    local t0 = os.clock()
    while live() and os.clock() - t0 < sec do task.wait(0.25) end
end

local function vendLoop(runId)
    local function live() return Vend.Running and alive() and Vend.RunId == runId end
    local home = Guard.worldName()
    Vend.Home = home
    Vend.Soft = 0
    if #Vend.waitWorld(home, live) == 0 then
        if live() then Vend.stop("Tidak ada vending milikmu di world ini (jalankan di world vending)") end
        return
    end
    while live() do
        task.wait()
        if Vend.Mode == VEND_EMPTY then
            -- ===== kosongkan =====
            if Guard.worldName() ~= home then
                if not Vend.travel(home, nil) then
                    if not Vend.soft("Gagal pulang ke world vending " .. home, live) then break end
                    continue
                end
            end
            local hasPoint = Vend.hasPoint()
            local list = {}
            local all = Vend.waitWorld(home, live)
            if #all == 0 and live() then
                if not Vend.soft("Vending milikmu di " .. home .. " tidak terbaca", live) then break end
                pcall(goWorld, home, nil) -- masuk ulang supaya data world termuat
                continue
            end
            local skipped = {}
            for _, m in ipairs(all) do
                if m.id and m.stock > 0 then
                    if not Vend.allow(m.id) then
                        skipped[#skipped + 1] = itemName(m.id) .. " x" .. m.stock
                    elseif (Vend.Fail[m.x .. "," .. m.y] or 0) < 4 then
                        list[#list + 1] = m
                    end
                end
            end
            if #list == 0 and not Vend.Confirm then
                -- cek sekali lagi sebentar lagi (data stock dari server bisa telat)
                Vend.Confirm = true
                Vend.Status = "Cek ulang isi vending..."
                Vend.sleep(1.5, live)
                continue
            end
            Vend.Confirm = false
            if #list == 0 then
                -- selesai: bawa sisa ke titik drop (kalau diatur)
                if hasPoint and next(Vend.Carry) then
                    local ok, why = Vend.dropTrip(live, home)
                    if why == "home" or not ok then
                        if not Vend.soft(why == "home" and ("Gagal pulang ke world vending " .. home)
                            or ("Vending kosong, tapi drop gagal: " .. Vend.Status), live) then break end
                        continue
                    end
                    Vend.Soft = 0
                end
                table.clear(Vend.Carry)
                if next(Vend.Fail) then
                    Vend.stop("Selesai, ada vending yang gagal diambil")
                elseif #skipped > 0 then
                    Vend.stop("Item terpilih sudah habis. Tidak diambil (bukan item terpilih): "
                        .. table.concat(skipped, ", ", 1, math.min(#skipped, 4))
                        .. ((#skipped > 4) and (" +" .. (#skipped - 4)) or "")
                        .. ". Hapus pilihan item untuk ambil semua")
                else
                    Vend.stop("Semua vending sudah kosong")
                end
                break
            end
            local full = false
            for _, m in ipairs(Vend.sortNear(list)) do
                if not live() then break end
                local room = 200
                if Refs.Inv then
                    local okr, r = pcall(function() return Refs.Inv:room(m.id) end)
                    if okr and type(r) == "number" then room = r end
                end
                if room <= 0 then
                    full = true
                    break
                end
                Vend.Status = ("Ke vending (%d,%d): ambil %s"):format(m.x, m.y, itemName(m.id))
                local key = m.x .. "," .. m.y
                if Vend.goTo(m) then
                    local before = invCount(m.id)
                    local okc = Vend.call("empty", m.x, m.y)
                    task.wait(0.4)
                    local got = invCount(m.id) - before
                    if got > 0 then
                        Vend.Soft = 0
                        Vend.Taken += got
                        Vend.Carry[m.id] = (Vend.Carry[m.id] or 0) + got
                        Vend.Fail[key] = nil
                        Vend.Status = ("Ambil %s x%d dari (%d,%d)"):format(itemName(m.id), got, m.x, m.y)
                        if got < m.stock then
                            -- tas tidak muat semua: buang dulu ke titik drop, lalu ambil sisanya
                            full = true
                            break
                        end
                    else
                        Vend.Fail[key] = (Vend.Fail[key] or 0) + 1
                        if not okc and next(Vend.Carry) then
                            full = true -- kemungkinan tas penuh: buang dulu ke titik drop
                            break
                        end
                        Vend.sleep(1, live) -- server telat (ping): jeda sebelum coba lagi
                    end
                else
                    Vend.Fail[key] = (Vend.Fail[key] or 0) + 1
                    Vend.Status = ("Tidak bisa ke vending (%d,%d)"):format(m.x, m.y)
                end
            end
            if not live() then break end
            if full then
                if not hasPoint then
                    Vend.stop("Tas penuh: atur titik drop vending (WORLD / WORLD:ID / simpan posisi XY)")
                    break
                end
                if not next(Vend.Carry) then
                    Vend.stop("Tas penuh oleh item lain, kosongkan tas dulu")
                    break
                end
                local ok, why = Vend.dropTrip(live, home)
                if why == "home" or not ok then
                    -- barang tetap dicatat, dicoba drop lagi di putaran berikutnya
                    if not Vend.soft(why == "home" and ("Gagal pulang ke world vending " .. home)
                        or ("Drop gagal: " .. Vend.Status), live) then break end
                    continue
                end
                Vend.Soft = 0
                table.clear(Vend.Carry)
                table.clear(Vend.Fail)
            end
        else
            -- ===== isi stock dari drop =====
            if Guard.worldName() == home then
                Vend.waitWorld(home, live)
                local done, tried = Vend.stockAll(live)
                if not live() then break end
                if tried > 0 and done == 0 then
                    if not Vend.soft("Tambah stock gagal: " .. Vend.Status, live) then break end
                    continue
                else
                    if done > 0 then Vend.Soft = 0 end
                end
            end
            local want, empty, sold = Vend.wanted()
            if not next(want) and empty == 0 then
                Vend.Status = Vend.filtered() and "Vending item terpilih penuh / belum ada yang menjual item terpilih"
                    or "Semua vending penuh / belum ada vending yang menjual item"
                Vend.sleep(4, live)
                continue
            end
            local name, door = Vend.point()
            if name == "" then name = home end
            if Guard.worldName() ~= name or door then
                if not (Guard.worldName() == name and Vend.AtPoint) then
                    Vend.Status = "Pergi ke " .. name .. (door and (":" .. door) or "") .. " ambil drop"
                    local ok, err = Vend.travel(name, door)
                    if not ok then
                        Vend.Status = "Gagal ke titik drop: " .. tostring(err)
                        Vend.sleep(10, live)
                        continue
                    end
                    Vend.AtPoint = true
                end
            end
            Vend.goSpot(live)
            -- tunggu di titik drop sampai ada yang bisa diambil (tidak bolak-balik world)
            local got = 0
            while live() do
                Vend.stepAway(live)
                got += Vend.pickHere(live, want, empty, sold)
                local carry = false
                for id in pairs(want) do
                    if invCount(id) > 0 then
                        carry = true
                        break
                    end
                end
                if not carry then
                    for id, cnt in pairs(Vend.Picked) do
                        if cnt > 0 and invCount(id) > 0 then
                            carry = true
                            break
                        end
                    end
                end
                if carry then break end
                Vend.Status = "Menunggu drop baru di " .. Guard.worldName() .. "..."
                Vend.sleep(0.5, live)
            end
            if not live() then break end
            Vend.AtPoint = false
            if Guard.worldName() ~= home then
                Vend.Status = "Pulang ke " .. home .. " untuk isi stock"
                local okh = Vend.travel(home, nil)
                if not okh then
                    if not Vend.soft("Gagal pulang ke world vending " .. home, live) then break end
                    continue
                end
            end
        end
    end
    releaseInput()
end

function Vend.stop(reason)
    Vend.Running = false
    Vend.AtPoint = false
    Move.NoZone = false
    autoEnd()
    releaseInput()
    Vend.Status = reason or "Dihentikan"
    Vend.Confirm = false
    if UI.VendToggle then UI.later("vendToggle", function() UI.VendToggle:Set(false) end) end
    if reason then
        notify("Vending", reason, 5)
        if not string.find(reason, "^Dihentikan") then Hook.send("pabrik", "Vending: " .. reason) end
    end
end

function Vend.start()
    if Vend.Running then return end
    local err
    if not Refs.World then
        err = "Data world belum ketemu. Tekan 'Hubungkan ke game'"
    elseif not OrigIsDown then
        err = "Kontrol gerak game (WorldMenu.isDown) tidak ketemu"
    elseif not playerState() then
        err = "Kamu belum masuk world"
    elseif type(rawget(Refs.World, "vendCall")) ~= "function" then
        err = "Fungsi vending game tidak ketemu"
    end
    if err then
        notify("Vending", err, 4)
        if UI.VendToggle then pcall(function() UI.VendToggle:Set(false) end) end
        return
    end
    if State.Running and not State.Override then stopFarm("Dihentikan karena Vending dimulai") end
    if Clear.Running then stopClear("Dihentikan karena Vending dimulai") end
    if Farmer.Running then stopFarmer("Dihentikan karena Vending dimulai") end
    if Splice.Running and Splice.stop then Splice.stop("Dihentikan karena Vending dimulai") end
    if Pabrik.Running then Pabrik.stop("Dihentikan karena Vending dimulai") end
    table.clear(Vend.Carry)
    table.clear(Vend.Picked)
    table.clear(Vend.Fail)
    table.clear(BadEdge)
    Vend.FailRuns = 0
    Vend.AtPoint = false
    Vend.Running = true
    Vend.RunId = (Vend.RunId or 0) + 1
    Vend.Status = "Mulai..."
    autoBegin()
    if UI.VendToggle then pcall(function() UI.VendToggle:Set(true) end) end
    local id = Vend.RunId
    task.spawn(function()
        local ok, e = pcall(vendLoop, id)
        if not ok then
            warn("[SkyP] Vending error: " .. tostring(e))
            if Vend.Running then Vend.stop("Error: " .. tostring(e)) end
        end
    end)
end
Auto.VEND_MODES = { VEND_STOCK, VEND_EMPTY }

Auto.seedOfBlock = seedOfBlock
Auto.blockOfSeed = blockOfSeed
Auto.parseDropTarget = parseDropTarget

Auto.walkTo = walkTo
Auto.startSpliceRoam = startSpliceRoam
Auto.stopSpliceRoam = stopSpliceRoam
Auto.treeReadyAt = treeReadyAt
Auto.plantSpotOk = plantSpotOk
Auto.stopWalk = function() Move.Homing = false end
Auto.here = function()
    local s = playerState()
    if s then return startNode(s) end
    return nil
end
Auto.startClear = startClear
-- Ambil block (drop) di sekitar sampai punya lagi. Hasil: true kalau block sudah ada.
function Auto.refillBlock(id, live)
    -- PATCH refill: ambil SEMUA block itu di radius (bukan cuma sampai punya 1),
    -- tunggu inventori ter-update dari server (ping), baru kembali ke posisi farm.
    local R = State.RefillRadius or 10
    local before = invCount(id)
    local ping = 0.1
    pcall(function() ping = LocalPlayer:GetNetworkPing() end)
    local function waitInv(base, sec)
        local t = os.clock()
        while os.clock() - t < sec and live() do
            if invCount(id) > base then return true end
            task.wait(0.1)
        end
        return invCount(id) > base
    end
    local function roomLeft()
        local ok, r = pcall(function() return Refs.Inv:room(id) end)
        return not (ok and type(r) == "number" and r <= 0)
    end
    Move.Homing = true
    autoBegin()
    for _ = 1, 6 do
        if not live() or not roomLeft() then break end
        local okF, n = pcall(Move.fetchDrops, live, R, function(d) return d.id == id end, 25)
        if not okF then warn("[SkyP] refill: " .. tostring(n)) break end
        if (n or 0) == 0 then break end -- tidak ada lagi block itu di sekitar
        waitInv(before, math.clamp(0.5 + 4 * ping, 0.8, 3))
        before = math.max(before, invCount(id))
    end
    Move.Homing = false
    autoEnd()
    if invCount(id) <= 0 then waitInv(0, math.clamp(0.5 + 4 * ping, 0.8, 3)) end
    local got = invCount(id) > 0
    if not got then
        State.LastAction = ("Refill gagal: tidak ada %s dalam radius %d tile"):format(itemName(id), R)
    end
    if got and State.AutoReturn and State.Home and live() then
        State.LastAction = ("Kembali ke posisi farm (%d,%d)"):format(State.Home.x, State.Home.y)
        local okW = false
        for _ = 1, 2 do
            okW = walkTo(State.Home.x, State.Home.y, 40)
            if okW or not live() then break end
            task.wait(0.3)
        end
        if not okW then State.ReturnFailAt = os.clock() + 20 end
    end
    return got and live()
end
Auto.startFarmer = startFarmer
Auto.updateClearStatus = updateClearStatus
Auto.updateFarmerStatus = updateFarmerStatus
Auto.findTreeRefs = findTreeRefs
Auto.releaseInput = releaseInput
Auto.BadEdge = BadEdge
Auto.ClearFail = ClearFail
Auto.resetReach = function() Reach = nil end
-- v7.3: lompat LURUS ke atas di kolom x ke tile berdiri (x, toY) yang lantainya platform
-- (pathfinder A* hanya mengenal lompat ke kolom sebelah, bukan naik di kolom yang sama).
-- Meniru langkah "jump" milik walkTo. return true kalau mendarat tepat di (x, toY).
Auto.jumpUp = function(x, toY)
    if not Refs.World or not OrigIsDown then
        return false
    end
    local s0 = playerState()
    if not s0 then
        return false
    end
    local _, fy = startNode(s0)
    if fy <= toY or fy - toY > 3 then
        return false
    end
    Move.Homing = true
    autoBegin()
    local ok = false
    local floorY = toY + 1
    local releaseY = floorY - ((fy - toY == 1) and 0 or 0.4)
    releaseInput()
    if frame() then
        AutoInput.jump = true
        local t0 = os.clock()
        local airborne = false
        while frame() do
            local s = playerState()
            if not s or s.dead then
                break
            end
            if not s.grounded then
                airborne = true
            end
            if AutoInput.jump and (s.y <= releaseY or (airborne and (s.vy or 0) >= 0)) then
                AutoInput.jump = false
            end
            steerX(s, x + 0.5, 0.12)
            if airborne and s.grounded then
                local tx, ty = startNode(s)
                ok = (tx == x and ty == toY)
                break
            end
            if not airborne and os.clock() - t0 > 0.4 then
                break
            end
            if os.clock() - t0 > 2.2 then
                break
            end
        end
    end
    releaseInput()
    Move.Homing = false
    autoEnd()
    return ok
end
-- v7.6: turun dari tangga platform = jalan keluar dari tepi platform ke kolom tetangga
-- yang kosong (kolom 0 / 99), lalu jatuh. side: -1 kiri, +1 kanan; col = kolom tangga.
-- return true kalau mendarat di kolom tetangga.
Auto.dropOff = function(col, side)
    if not Refs.World or not OrigIsDown then
        return false
    end
    local s0 = playerState()
    if not s0 then
        return false
    end
    local outer = col + side
    local tx = outer + 0.5
    Move.Homing = true
    autoBegin()
    releaseInput()
    local ok = false
    if frame() then
        local t0 = os.clock()
        local fell = false
        while frame() do
            local s = playerState()
            if not s or s.dead then
                break
            end
            -- jalan ke arah kolom luar; begitu melewati tepi platform karakter jatuh
            AutoInput.left = side < 0 and s.x > tx
            AutoInput.right = side > 0 and s.x < tx
            if not s.grounded then
                fell = true
            end
            if fell and s.grounded and floor(s.x) == outer then
                ok = true
                break
            end
            if fell and s.grounded and floor(s.x) ~= outer then
                break
            end
            if not fell and os.clock() - t0 > 2.5 then
                break
            end
            if os.clock() - t0 > 12 then
                break
            end
        end
    end
    releaseInput()
    Move.Homing = false
    autoEnd()
    return ok
end
end)() end -- do (gerak otomatis)

---------------------------------------------------------------------
-- AUTO CHAT
---------------------------------------------------------------------
-- Pesan dikirim ke chat world, bergantian sesuai urutan
local TextChatService = game:GetService("TextChatService")

local function worldChannel()
    local folder = TextChatService:FindFirstChild("WorldChannels")
    if not folder then return nil end
    local name = Refs.World and Refs.World.name
    if type(name) == "string" and name ~= "" then
        local ch = folder:FindFirstChild(name)
        if ch then return ch end
    end
    -- cadangan: cari channel yang ada kita
    for _, ch in ipairs(folder:GetChildren()) do
        if ch:IsA("TextChannel") then
            for _, src in ipairs(ch:GetChildren()) do
                if src:IsA("TextSource") and src.UserId == LocalPlayer.UserId then return ch end
            end
        end
    end
    return nil
end

local function parseSpamTexts(raw)
    local out = {}
    for part in string.gmatch(raw or "", "[^|\n]+") do
        part = part:gsub("^%s+", ""):gsub("%s+$", "")
        if part ~= "" then out[#out + 1] = part end
    end
    return out
end

local lastSpamText = nil
local function updateSpamStatus()
    if not UI.SpamStatus then return end
    local txt = "Status   : " .. (Spam.On and "JALAN" or "BERHENTI")
        .. "\nPesan    : " .. #Spam.Texts .. " (bergantian)"
        .. "\nTerkirim : " .. Spam.Sent
        .. "\nTerakhir : " .. Spam.Last
    if txt == lastSpamText then return end
    lastSpamText = txt
    task.defer(function()
        pcall(function() UI.SpamStatus:SetDesc(txt) end)
    end)
end

-- Kirim pesan berikutnya
local function sendNextChat()
    if #Spam.Texts == 0 then
        Spam.Last = "Daftar pesan kosong"
        return false
    end
    local ch = worldChannel()
    if not ch then
        Spam.Last = "Channel chat world belum ada (masuk world dulu)"
        return false
    end
    if Spam.Index > #Spam.Texts then Spam.Index = 1 end
    local msg = Spam.Texts[Spam.Index]
    Spam.Index = Spam.Index % #Spam.Texts + 1
    local ok, err = pcall(ch.SendAsync, ch, msg)
    if ok then
        Spam.Sent += 1
        Spam.Last = msg
    else
        Spam.Last = "Gagal: " .. tostring(err)
    end
    return ok
end

Spam.NextAt = 0
task.spawn(function()
    while alive() do
        if Spam.On and os.clock() >= Spam.NextAt then
            sendNextChat()
            Spam.NextAt = os.clock() + math.max(3, Spam.IntervalSec)
            updateSpamStatus()
        end
        task.wait(0.25)
    end
end)

---------------------------------------------------------------------
-- WATERMARK NAMA + BENDERA (hanya di layar sendiri)
---------------------------------------------------------------------
-- Nama asli (huruf gambar "BitmapText") disembunyikan, diganti teks beranimasi:
-- warna gradient mengalir + denyut halus. Pemain lain tetap melihat nama asli.
-- Selalu aktif sebagai penanda script (tidak ada tombol on/off).
local TextService = game:GetService("TextService")
local NameFx = { t0 = os.clock() }

local NAME_COLORS = ColorSequence.new({
    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(170, 90, 255)),  -- ungu
    ColorSequenceKeypoint.new(0.25, Color3.fromRGB(60, 205, 255)),  -- biru muda
    ColorSequenceKeypoint.new(0.50, Color3.fromRGB(255, 110, 210)), -- pink
    ColorSequenceKeypoint.new(0.75, Color3.fromRGB(60, 205, 255)),
    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(170, 90, 255)),
})
local NAME_FONT = Enum.Font.FredokaOne

-- GAMBAR PENGGANTI BENDERA (hanya terlihat di layar sendiri, pemain lain tetap melihat bendera asli).
-- Isi dengan link gambar png / jpg, atau ID aset Roblox ("rbxassetid://123" / "123"). Kosong = bendera tidak diubah.
-- Sengaja ditaruh di sini (bukan di menu) supaya tidak bisa diubah-ubah dari dalam game.
NameFx.FLAG = "https://raw.githubusercontent.com/Mizoree-ux/UI/main/file_00000000f794820797aa0933609c9c7c.png"
NameFx.HIDE_TITLE = true -- sembunyikan kotak title di atas nama (hanya di layar sendiri)

NameFx.titles = {}  -- [kotak title] = true : yang disembunyikan
NameFx.flag = nil   -- { o = bendera asli, old = {...} } atau { o =, cover = gambar pengganti }

-- Cari huruf-gambar nama di dalam tag (nama anak bisa berubah saat game update)
function NameFx.findBitmap(holder)
    local b = holder:FindFirstChild("BitmapText")
    if b then return b end
    for _, c in ipairs(holder:GetChildren()) do
        if c.Name ~= "FianName" and string.find(string.lower(c.Name), "bitmap", 1, true) then return c end
    end
    return nil
end

-- Jumlah huruf-gambar di teks bitmap
function NameFx.lettersOf(bm)
    local n = 0
    for _, c in ipairs(bm:GetDescendants()) do
        if c:IsA("ImageLabel") or c:IsA("ImageButton") then n += 1 end
    end
    return n
end

-- Titik karakter di layar (kamera mengikuti karakter: kalau tidak ketemu, pakai tengah layar)
function NameFx.center()
    local ok, v = pcall(getView)
    if ok and v and v.pv then
        local p, sz = v.pv.AbsolutePosition, v.pv.AbsoluteSize
        return p.X + sz.X / 2, p.Y + sz.Y / 2
    end
    local cam = workspace.CurrentCamera
    local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
    return vp.X / 2, vp.Y / 2
end

-- Layar world game. Nama wadah di dalamnya diacak tiap update, tapi "GameGui" & "BitmapText" tetap.
function NameFx.worldGuis()
    local gg = PlayerGui:FindFirstChild("GameGui")
    if gg then return { gg } end
    local skip = { ChatGui = true, MenuGui = true, InventoryGui = true, MobileGui = true, PingGui = true,
        VersionGui = true, TextureKeep = true }
    local out = {}
    for _, top in ipairs(PlayerGui:GetChildren()) do
        if top:IsA("LayerCollector") and not skip[top.Name] then out[#out + 1] = top end
    end
    return out
end

-- Semua teks bitmap di layar world: { o = induk, bm = teks bitmap, n = jumlah huruf }
function NameFx.scanTexts()
    local out = {}
    for _, top in ipairs(NameFx.worldGuis()) do
        for _, bm in ipairs(top:GetDescendants()) do
            if bm.Name == "BitmapText" and bm:IsA("GuiObject") then
                local o = bm.Parent
                if o and o:IsA("GuiObject") and bm.Visible and o.Visible and bm.AbsoluteSize.X > 0 then
                    out[#out + 1] = { o = o, bm = bm, n = NameFx.lettersOf(bm) }
                end
            end
        end
    end
    return out
end

-- Nametag sendiri = kotak berisi "BitmapText" + ikon bendera, yang berada TEPAT di atas karakter sendiri.
-- (nama di dalam game bisa beda dengan nama akun Roblox, jadi tidak dicocokkan lewat jumlah huruf)
-- Tidak ada yang cocok -> nil: nama asli dibiarkan, tidak ditempel ke tempat lain.
function NameFx.pickOwn(list)
    local cx, cy = NameFx.center()
    local cam = workspace.CurrentCamera
    local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
    local best, bestScore = nil, nil
    for _, c in ipairs(list) do
        local o = c.o
        local sz, pos = o.AbsoluteSize, o.AbsolutePosition
        local hasIcon = false -- nametag pemain punya ikon (bendera) di samping teksnya
        for _, k in ipairs(o:GetChildren()) do
            if k ~= c.bm and (k:IsA("ImageLabel") or k:IsA("ImageButton")) then
                hasIcon = true
                break
            end
        end
        if hasIcon and c.n >= 1 and sz.Y >= 8 and sz.Y <= vp.Y * 0.15 then
            local dx = math.abs(pos.X + sz.X / 2 - cx)
            local dy = cy - (pos.Y + sz.Y / 2) -- positif = di atas karakter
            if dx <= vp.X * 0.05 and dy > vp.Y * 0.05 and dy < vp.Y * 0.35 then
                local score = dx * 3 + dy
                if not bestScore or score < bestScore then best, bestScore = c, score end
            end
        end
    end
    return best
end

-- Cari nametag sendiri (dicari ulang paling sering tiap 0.5 detik; yang sudah ketemu dipakai terus selama masih ada)
function NameFx.findOwnTag()
    local c = NameFx.tagCache
    if c and c.o.Parent and c.bm.Parent == c.o and c.o:IsDescendantOf(PlayerGui) and c.o.Visible then return c end
    NameFx.tagCache = nil
    local now = os.clock()
    if now - (NameFx.tagScanAt or 0) < 0.5 then return nil end
    NameFx.tagScanAt = now
    NameFx.tagCache = NameFx.pickOwn(NameFx.scanTexts())
    return NameFx.tagCache
end

function NameFx.textWidth(text, size)
    local ok, v = pcall(TextService.GetTextSize, TextService, text, size, NAME_FONT, Vector2.new(2000, 200))
    return (ok and v.X or #text * size * 0.55) + 6 -- +6 untuk garis tepi
end

function NameFx.newLabel(holder, size)
    local lb = Instance.new("TextLabel")
    lb.Name = "FianName"
    lb.BackgroundTransparency = 1
    lb.BorderSizePixel = 0
    lb.Font = NAME_FONT
    lb.TextSize = size
    lb.TextColor3 = Color3.new(1, 1, 1)
    lb.Text = Misc.NameText
    local st = Instance.new("UIStroke")
    st.Thickness = 2
    st.Color = Color3.fromRGB(25, 12, 40)
    st.Transparency = 0.1
    st.Parent = lb
    local gr = Instance.new("UIGradient")
    gr.Color = NAME_COLORS
    gr.Rotation = 12
    gr.Parent = lb
    local sc = Instance.new("UIScale")
    sc.Parent = lb
    lb.Parent = holder
    return { holder = holder, label = lb, gr = gr, sc = sc, size = size, text = nil, w = 0 }
end

local function dropEntry(e)
    if not e then return end
    pcall(function() e.label:Destroy() end)
    if e.bitmap then pcall(function() e.bitmap.Visible = true end) end
end

-- Nama di ATAS KARAKTER: label ditaruh persis di tempat huruf-gambar nama asli (posisi & jangkar disalin),
-- nama asli disembunyikan. Ukuran kotak milik game TIDAK diubah.
function NameFx.keepTag(e, cand)
    if not cand then
        dropEntry(e)
        return nil
    end
    local holder, bm = cand.o, cand.bm
    if not e or e.holder ~= holder or e.bitmap ~= bm or e.label.Parent ~= holder then
        dropEntry(e)
        local h = bm.Size.Y.Offset
        if h <= 0 then h = holder.Size.Y.Offset end
        local size = (h > 0) and math.clamp(math.floor(h * 1.15), 14, 34) or 22
        e = NameFx.newLabel(holder, size)
        e.bitmap = bm
        e.label.ZIndex = math.max(bm.ZIndex, holder.ZIndex) + 1
        e.label.LayoutOrder = bm.LayoutOrder
        e.label.AnchorPoint = bm.AnchorPoint
        e.label.Position = bm.Position
        e.label.TextXAlignment = (bm.AnchorPoint.X >= 0.75 and Enum.TextXAlignment.Right)
            or (bm.AnchorPoint.X >= 0.25 and Enum.TextXAlignment.Center) or Enum.TextXAlignment.Left
    end
    if not e.label.Visible then e.label.Visible = true end
    if e.text ~= Misc.NameText then
        e.text = Misc.NameText
        e.label.Text = Misc.NameText
        e.w = NameFx.textWidth(Misc.NameText, e.size)
    end
    local bs = bm.Size
    local hOff = (bs.Y.Scale == 0 and bs.Y.Offset <= 0) and (e.size + 6) or bs.Y.Offset
    local want = UDim2.new(0, e.w, bs.Y.Scale, hOff)
    if e.label.Size ~= want then e.label.Size = want end
    if e.label.Position ~= bm.Position then e.label.Position = bm.Position end -- game menggeser nama: ikut
    if bm.Visible then bm.Visible = false end
    return e
end

-- Nama di PANEL kiri atas
function NameFx.keepPanel(e, holder)
    if not holder then
        dropEntry(e)
        return nil
    end
    if not e or e.holder ~= holder or e.label.Parent ~= holder then
        dropEntry(e)
        e = NameFx.newLabel(holder, 21)
        e.label.ZIndex = 10
        e.label.AnchorPoint = Vector2.new(0, 0.5)
        e.label.Position = UDim2.new(0, 3, 0.5, 0)
        e.label.TextXAlignment = Enum.TextXAlignment.Left
        e.label.Size = UDim2.new(1, -6, 1, 0)
    end
    if not e.label.Visible then e.label.Visible = true end
    if e.text ~= Misc.NameText then
        e.text = Misc.NameText
        e.label.Text = Misc.NameText
    end
    if not (e.bitmap and e.bitmap.Parent) then e.bitmap = NameFx.findBitmap(holder) end
    if e.bitmap and e.bitmap.Visible then e.bitmap.Visible = false end
    return e
end

---------------------------------------------------------------------
-- BENDERA & TITLE (hanya di layar sendiri)
---------------------------------------------------------------------
-- Gambar pengganti bendera dimuat sekali di belakang layar (link -> file -> aset)
function NameFx.flagImage()
    if NameFx.flagImg then return NameFx.flagImg end
    local l = NameFx.FLAG
    if type(l) ~= "string" or l == "" or NameFx.flagLoading or os.clock() < (NameFx.flagTryAt or 0) then return nil end
    NameFx.flagTryAt = os.clock() + 60
    if string.match(l, "^%d+$") then
        NameFx.flagImg = "rbxassetid://" .. l
    elseif string.match(l, "^rbxassetid://") or string.match(l, "^rbxasset://") then
        NameFx.flagImg = l
    elseif string.match(l, "^https?://") then
        NameFx.flagLoading = true
        task.spawn(function()
            local ok, err = pcall(function()
                local data = game:HttpGet(l)
                local name = "skyp_flag_" .. tostring(#l) .. "_" .. tostring(#data) .. ".png"
                writefile(name, data)
                NameFx.flagImg = getcustomasset(name)
            end)
            NameFx.flagLoading = false
            if not ok and not NameFx.flagWarned then
                NameFx.flagWarned = true
                warn("[SkyP] gambar bendera gagal dimuat: " .. tostring(err))
            end
        end)
    end
    return NameFx.flagImg
end

function NameFx.flagIsCand(o)
    local n = string.lower(o.Name)
    return string.find(n, "flag", 1, true) or string.find(n, "country", 1, true) or string.find(n, "bendera", 1, true)
        or string.find(n, "nation", 1, true) or string.find(n, "region", 1, true)
end

-- Cari bendera & title di nametag sendiri.
--   bendera: gambar kecil DI DALAM kotak nametag, tepat di kiri nama
--   title  : kotak berisi "BitmapText" lain tepat di atas nama (di dalam nametag / saudaranya)
function NameFx.findExtras(e)
    local lb = e.label
    local np, ns = lb.AbsolutePosition, lb.AbsoluteSize
    local H = ns.Y
    if H < 4 then return nil, {} end
    local holder, bm = e.holder, e.bitmap
    -- tepi kiri & lebar memakai nama ASLI (bendera menempel ke nama asli, bukan ke teks pengganti)
    if bm.AbsoluteSize.X > 0 and math.abs(bm.AbsolutePosition.Y - np.Y) <= H * 2 then
        np = Vector2.new(bm.AbsolutePosition.X, np.Y)
        ns = Vector2.new(bm.AbsoluteSize.X, ns.Y)
    end
    local flag, flagScore = nil, nil
    for _, o in ipairs(holder:GetDescendants()) do
        if (o:IsA("ImageLabel") or o:IsA("ImageButton")) and o.Name ~= "FianFlag" and not o:IsDescendantOf(bm) then
            local p, sz = o.AbsolutePosition, o.AbsoluteSize
            local gap = np.X - (p.X + sz.X)
            local midY = p.Y + sz.Y / 2
            if sz.X >= H * 0.3 and sz.X <= H * 3.5 and sz.Y >= H * 0.3 and sz.Y <= H * 2.5
                and gap >= -H * 0.5 and gap <= H * 3 and midY >= np.Y - H * 0.5 and midY <= np.Y + H * 1.5 then
                if not flagScore or gap < flagScore then flag, flagScore = o, gap end
            end
        end
    end
    local titles = {}
    if NameFx.HIDE_TITLE then
        local function check(o)
            if o == holder or not o:IsA("GuiObject") or o.Name == "FianName" then return end
            local tb = o:FindFirstChild("BitmapText")
            if not tb or tb == bm then return end
            local p, sz = o.AbsolutePosition, o.AbsoluteSize
            if sz.X <= 0 or sz.Y <= 0 then return end
            local bottom = p.Y + sz.Y
            local mid = p.X + sz.X / 2
            local nameMid = np.X + ns.X / 2
            if p.Y < np.Y - H * 0.3 and bottom >= np.Y - H * 3 and bottom <= np.Y + H * 0.7
                and math.abs(mid - nameMid) <= H * 1.5 then
                titles[#titles + 1] = o
            end
        end
        for _, o in ipairs(holder:GetDescendants()) do check(o) end
        local par = holder.Parent
        if par then
            for _, o in ipairs(par:GetChildren()) do check(o) end
        end
    end
    return flag, titles
end

function NameFx.flagRestore()
    local f = NameFx.flag
    NameFx.flag = nil
    if f then
        pcall(function()
            if f.cover then f.cover:Destroy() end
            if f.old then
                f.o.Image, f.o.ImageRectOffset, f.o.ImageRectSize = f.old[1], f.old[2], f.old[3]
                f.o.ScaleType, f.o.ImageColor3 = f.old[4], f.old[5]
            else
                f.o.Visible = true
            end
        end)
    end
    for o in pairs(NameFx.titles) do pcall(function() o.Visible = true end) end
    NameFx.titles = {}
end

-- Ganti gambar bendera. Bendera berupa gambar: gambarnya ditukar. Bentuk lain: ditutup gambar pengganti.
function NameFx.flagSet(o, img)
    local f = NameFx.flag
    if f and f.o == o then return end
    if f then
        local keep = NameFx.titles
        NameFx.titles = {}
        NameFx.flagRestore()
        NameFx.titles = keep
    end
    if o:IsA("ImageLabel") or o:IsA("ImageButton") then
        NameFx.flag = { o = o, img = img, old = { o.Image, o.ImageRectOffset, o.ImageRectSize, o.ScaleType, o.ImageColor3 } }
    else
        local c = Instance.new("ImageLabel")
        c.Name = "FianFlag"
        c.BackgroundTransparency = 1
        c.BorderSizePixel = 0
        c.Image = img
        c.ScaleType = Enum.ScaleType.Fit
        c.Size, c.Position, c.AnchorPoint = o.Size, o.Position, o.AnchorPoint
        c.LayoutOrder, c.ZIndex, c.Rotation = o.LayoutOrder, o.ZIndex + 1, o.Rotation
        c.Parent = o.Parent
        NameFx.flag = { o = o, img = img, cover = c }
    end
end

-- Dijaga tiap frame: game bisa menimpa gambar / memunculkan title lagi
function NameFx.extrasKeep()
    local f = NameFx.flag
    if f then
        local o = f.o
        if not o.Parent then
            if f.cover then pcall(function() f.cover:Destroy() end) end
            NameFx.flag = nil
        elseif f.cover then
            if o.Visible then o.Visible = false end
            if f.cover.Position ~= o.Position then f.cover.Position = o.Position end
        elseif o.Image ~= f.img or o.ImageRectSize.X ~= 0 or o.ImageRectSize.Y ~= 0 then
            o.Image = f.img
            o.ImageRectOffset, o.ImageRectSize = Vector2.new(0, 0), Vector2.new(0, 0)
            o.ScaleType = Enum.ScaleType.Fit
            o.ImageColor3 = Color3.new(1, 1, 1)
        end
    end
    for o in pairs(NameFx.titles) do
        if not o.Parent then
            NameFx.titles[o] = nil
        elseif o.Visible then
            o.Visible = false
        end
    end
end

-- Dicari ulang tiap 1 detik (bendera / title bisa dibuat ulang oleh game)
function NameFx.extrasScan(e)
    local now = os.clock()
    if now - (NameFx.extraAt or 0) < 1 then return end
    NameFx.extraAt = now
    local flag, titles = NameFx.findExtras(e)
    local fresh = {}
    for _, o in ipairs(titles) do fresh[o] = true end
    for o in pairs(NameFx.titles) do -- sudah tidak di atas nama (mis. nama pemain lain yang lewat): tampilkan lagi
        if not fresh[o] then pcall(function() o.Visible = true end) end
    end
    NameFx.titles = fresh
    if flag then
        local img = NameFx.flagImage()
        if img then NameFx.flagSet(flag, img) end
    end
end

local function nameRestore()
    pcall(NameFx.flagRestore)
    dropEntry(NameFx.tag)
    dropEntry(NameFx.panel)
    NameFx.tag, NameFx.panel = nil, nil
    NameFx.tagCache = nil
end

-- Diagnosa: salin struktur nametag ke clipboard (dikirim ke developer kalau nama / bendera masih salah)
function Misc.DumpNameTag()
    local out = {}
    local function add(x) out[#out + 1] = x end
    local function rect(o)
        return ("%dx%d @%d,%d vis=%s"):format(o.AbsoluteSize.X, o.AbsoluteSize.Y, o.AbsolutePosition.X,
            o.AbsolutePosition.Y, tostring(o.Visible))
    end
    local cx, cy = NameFx.center()
    local cam = workspace.CurrentCamera
    add("Nametag v7 | nama: " .. tostring(LocalPlayer.DisplayName) .. " / " .. tostring(LocalPlayer.Name))
    add(("Karakter di layar: %d,%d | layar %s"):format(cx, cy, tostring(cam and cam.ViewportSize)))
    local okL, list = pcall(NameFx.scanTexts)
    if not okL then
        add("scanTexts ERROR: " .. tostring(list))
        list = {}
    end
    local own = NameFx.tagCache or NameFx.pickOwn(list)
    add("Teks bitmap (" .. #list .. "):")
    for i, c in ipairs(list) do
        if i > 25 then
            add("  ...")
            break
        end
        add(("  [%d]%s huruf %d | %s | %s"):format(i, (own and c.o == own.o) and " <-- NAMA SENDIRI" or "", c.n, rect(c.o),
            c.o:GetFullName()))
    end
    if own then
        local h = own.o
        add("Tag sendiri: " .. h:GetFullName() .. " (" .. h.ClassName .. ")")
        add("  bitmap: " .. own.bm.Name .. " | Size " .. tostring(own.bm.Size) .. " | Pos " .. tostring(own.bm.Position)
            .. " | Anchor " .. tostring(own.bm.AnchorPoint))
        local okN, near = pcall(function() return h:GetDescendants() end)
        if okN then
            add("Sekitar tag (" .. #near .. "):")
            for i, o in ipairs(near) do
                if i > 60 then
                    add("  ...")
                    break
                end
                local extra = ""
                if o:IsA("ImageLabel") or o:IsA("ImageButton") then extra = " img=" .. tostring(o.Image) end
                if o:IsA("GuiObject") then
                    add(("  %s : %s | %s | induk %s%s"):format(o.ClassName, o.Name, rect(o), o.Parent and o.Parent.Name or "?", extra))
                end
            end
        end
    else
        add("Tag sendiri: TIDAK KETEMU (tidak ada kotak BitmapText + ikon tepat di atas karakter)")
    end
    -- SEMUA benda di area atas karakter (apa pun jenisnya), supaya struktur nametag terlihat walau bukan teks bitmap
    local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
    local x0, x1 = cx - vp.X * 0.16, cx + vp.X * 0.16
    local y0, y1 = cy - vp.Y * 0.32, cy + vp.Y * 0.04
    local tops = {}
    for _, top in ipairs(PlayerGui:GetChildren()) do tops[#tops + 1] = top.Name .. "(" .. top.ClassName .. ")" end
    add("PlayerGui: " .. table.concat(tops, ", "))
    add(("Area atas karakter x %d..%d, y %d..%d:"):format(x0, x1, y0, y1))
    local shown, skippedBig = 0, 0
    for _, top in ipairs(PlayerGui:GetChildren()) do
        for _, o in ipairs(top:GetDescendants()) do
            if o:IsA("GuiObject") and o.Visible then
                local p, sz = o.AbsolutePosition, o.AbsoluteSize
                if sz.X > 0 and sz.Y > 0 and sz.X <= vp.X * 0.5 and sz.Y <= vp.Y * 0.3
                    and p.X + sz.X >= x0 and p.X <= x1 and p.Y + sz.Y >= y0 and p.Y <= y1 then
                    local par = o.Parent
                    if par and #par:GetChildren() > 120 then
                        skippedBig += 1 -- tile world dll
                    elseif shown < 140 then
                        shown += 1
                        local extra = ""
                        if o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox") then
                            extra = ' text="' .. string.sub(tostring(o.Text), 1, 40) .. '"'
                        elseif o:IsA("ImageLabel") or o:IsA("ImageButton") then
                            extra = " img=" .. tostring(o.Image) .. " rect=" .. tostring(o.ImageRectOffset) .. "/" .. tostring(o.ImageRectSize)
                        end
                        local chain, q = {}, o
                        for _ = 1, 5 do
                            if not q or q == PlayerGui then break end
                            table.insert(chain, 1, q.Name)
                            q = q.Parent
                        end
                        add(("  %s %dx%d @%d,%d anak=%d bg=%.1f | %s%s"):format(o.ClassName, sz.X, sz.Y, p.X, p.Y,
                            #o:GetChildren(), o.BackgroundTransparency, table.concat(chain, "/"), extra))
                    end
                end
            end
        end
    end
    add(("  (ditampilkan %d, dilewati %d benda di wadah besar)"):format(shown, skippedBig))
    local nBill = 0
    pcall(function()
        for _, o in ipairs(workspace:GetDescendants()) do
            if o:IsA("BillboardGui") or o:IsA("SurfaceGui") then nBill += 1 end
        end
    end)
    add("BillboardGui / SurfaceGui di workspace: " .. nBill)
    local f = NameFx.flag
    add("Bendera: " .. (f and (f.o:GetFullName() .. (f.cover and " (ditutup)" or " (gambar ditukar)")) or "tidak ketemu")
        .. " | gambar: " .. tostring(NameFx.flagImg or (NameFx.flagLoading and "memuat..." or "belum / gagal dimuat")))
    local nT = 0
    for o in pairs(NameFx.titles) do
        nT += 1
        add("Title disembunyikan: " .. o:GetFullName())
    end
    if nT == 0 then add("Title disembunyikan: tidak ada") end
    local txt = table.concat(out, "\n")
    Misc.LastNameDump = txt
    warn("[SkyP] struktur nametag:\n" .. txt)
    pcall(function()
        local clip = setclipboard or toclipboard
        if clip then clip(txt) end
    end)
    return #out
end

-- Animasi tiap frame: gradient mengalir + denyut halus
function NameFx.step()
    local chat = PlayerGui:FindFirstChild("ChatGui")
    local hud = chat and chat:FindFirstChild("HUD")
    local panel = hud and hud:FindFirstChild("PlayerPanel")
    local panelName = panel and panel:FindFirstChild("Name")
    if not panelName and NameFx.panel and NameFx.panel.holder.Parent then panelName = NameFx.panel.holder end
    NameFx.panel = NameFx.keepPanel(NameFx.panel, panelName)

    local had = NameFx.tag ~= nil
    NameFx.tag = NameFx.keepTag(NameFx.tag, NameFx.findOwnTag())
    local tg, pn = NameFx.tag, NameFx.panel
    if tg then
        NameFx.extrasScan(tg)
        NameFx.extrasKeep()
    elseif had then
        NameFx.flagRestore() -- nametag hilang (pindah world / respawn): bendera & title dikembalikan
    end

    local t = os.clock() - NameFx.t0
    local offset = Vector2.new(((t * 0.45) % 2) - 1, 0)
    local pulse = 1 + 0.045 * math.sin(t * 3.2)
    if tg then
        tg.gr.Offset = offset
        tg.sc.Scale = pulse
    end
    if pn then
        pn.gr.Offset = offset
        pn.sc.Scale = pulse
    end
end

-- Satu error nametag tidak boleh mematikan yang lain: dibungkus pcall, pesan ditampilkan sekali,
-- tag atas dilepas (nama asli kembali) lalu dicoba lagi setengah detik kemudian.
table.insert(Connections, RunService.RenderStepped:Connect(function()
    if not alive() or not Misc.CustomName then return end
    if os.clock() < (NameFx.retryAt or 0) then return end
    local ok, err = pcall(NameFx.step)
    if not ok then
        err = tostring(err)
        pcall(function() dropEntry(NameFx.tag) end)
        pcall(NameFx.flagRestore)
        NameFx.tag = nil
        NameFx.tagCache = nil
        NameFx.retryAt = os.clock() + 0.5
        if NameFx.lastErr ~= err then
            NameFx.lastErr = err
            warn("[SkyP] nametag error: " .. err)
            notify("Nametag error", err, 8)
        end
    end
end))

---------------------------------------------------------------------
-- ANTI AFK
---------------------------------------------------------------------
table.insert(Connections, LocalPlayer.Idled:Connect(function()
    if State.AntiAfk and alive() then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end))

---------------------------------------------------------------------
-- GUI TAMBAHAN: Grid Tile 5x5 + tombol Fly ▲/▼
---------------------------------------------------------------------
local guiParent = (gethui and gethui()) or game:GetService("CoreGui")

local function newScreenGui(name)
    local sg = Instance.new("ScreenGui")
    sg.Name = name
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder = 999
    sg.Enabled = false
    if syn and syn.protect_gui then pcall(syn.protect_gui, sg) end
    sg.Parent = guiParent
    return sg
end

local GRID_RADIUS = 2
local CELL = 38
local GAP = 4

local GridGui = newScreenGui("FianGrid")
UI.GridGui = GridGui

local side = GRID_RADIUS * 2 + 1
local gridSize = side * CELL + (side - 1) * GAP

local Panel = Instance.new("Frame")
Panel.Size = UDim2.fromOffset(gridSize + 20, gridSize + 96)
Panel.Position = UDim2.fromOffset(20, 80)
Panel.BackgroundColor3 = Color3.fromRGB(13, 15, 20)
Panel.BorderSizePixel = 0
Panel.Parent = GridGui
Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, 14)
local pStroke = Instance.new("UIStroke", Panel)
pStroke.Color = Color3.fromRGB(62, 150, 255)
pStroke.Transparency = 0.45

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 0, 28)
Title.Position = UDim2.fromOffset(10, 4)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.TextColor3 = Color3.fromRGB(236, 240, 247)
Title.Text = I18N.T("Grid Tile")
Title.Parent = Panel

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.fromOffset(24, 24)
CloseBtn.Position = UDim2.new(1, -30, 0, 6)
CloseBtn.BackgroundColor3 = Color3.fromRGB(32, 36, 48)
CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 12
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.Parent = Panel
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
CloseBtn.MouseButton1Click:Connect(function()
    GridGui.Enabled = false
end)

local GridHolder = Instance.new("Frame")
GridHolder.Size = UDim2.fromOffset(gridSize, gridSize)
GridHolder.Position = UDim2.fromOffset(10, 36)
GridHolder.BackgroundTransparency = 1
GridHolder.Parent = Panel

local COLOR_OFF = Color3.fromRGB(28, 32, 43)
local COLOR_ON = Color3.fromRGB(62, 150, 255)
local COLOR_ME = Color3.fromRGB(24, 58, 110)
local CellButtons = {}

-- Grid hanya untuk tile Auto Farm (tile break Pabrik diatur di peta Pabrik)
UI.gridTarget = function()
    return State.Offsets
end

local function paintCell(key)
    local b = CellButtons[key]
    if b then b.BackgroundColor3 = UI.gridTarget()[key] and COLOR_ON or COLOR_OFF end
end

for row = 0, side - 1 do
    for col = 0, side - 1 do
        local dx, dy = col - GRID_RADIUS, row - GRID_RADIUS
        local key = dx .. "," .. dy
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.fromOffset(CELL, CELL)
        btn.Position = UDim2.fromOffset(col * (CELL + GAP), row * (CELL + GAP))
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Parent = GridHolder
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

        if dx == 0 and dy == 0 then
            btn.Text = "ME"
            btn.BackgroundColor3 = COLOR_ME
            btn.AutoButtonColor = false
            local meStroke = Instance.new("UIStroke", btn)
            meStroke.Color = Color3.fromRGB(132, 196, 255)
            meStroke.Thickness = 2
        else
            btn.Text = ""
            btn.BackgroundColor3 = UI.gridTarget()[key] and COLOR_ON or COLOR_OFF
            CellButtons[key] = btn
            btn.MouseButton1Click:Connect(function()
                local tgt = UI.gridTarget()
                tgt[key] = (not tgt[key]) or nil
                paintCell(key)
                updateStatus()
            end)
        end
    end
end

local GridStart = Instance.new("TextButton")
GridStart.Size = UDim2.new(1, -20, 0, 30)
GridStart.Position = UDim2.new(0, 10, 1, -54)
GridStart.BackgroundColor3 = COLOR_ON
GridStart.Font = Enum.Font.GothamBold
GridStart.TextSize = 14
GridStart.TextColor3 = Color3.new(1, 1, 1)
GridStart.Text = "START"
GridStart.Parent = Panel
Instance.new("UICorner", GridStart).CornerRadius = UDim.new(0, 8)
UI.GridStart = GridStart
GridStart.MouseButton1Click:Connect(function()
    if State.Running and not State.Override then
        stopFarm()
    else
        startFarm()
    end
end)

local ClearBtn = Instance.new("TextButton")
ClearBtn.Size = UDim2.new(1, -20, 0, 18)
ClearBtn.Position = UDim2.new(0, 10, 1, -22)
ClearBtn.BackgroundTransparency = 1
ClearBtn.Font = Enum.Font.Gotham
ClearBtn.TextSize = 12
ClearBtn.TextColor3 = Color3.fromRGB(139, 148, 167)
ClearBtn.Text = I18N.T("Bersihkan pilihan")
ClearBtn.Parent = Panel
ClearBtn.MouseButton1Click:Connect(function()
    local tgt = UI.gridTarget()
    for key in pairs(tgt) do
        tgt[key] = nil
        paintCell(key)
    end
    updateStatus()
end)

-- Panel bisa digeser lewat judul
do (function() -- fungsi sendiri: variabel di dalam tidak ikut batas 200 local
    local dragging, dragStart, startPos
    Title.Active = true
    Title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Panel.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            Panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end))
end)() end

task.spawn(function()
    while alive() do
        if GridGui.Enabled then
            local px, py = getPlayerTile()
            local t = px and ("ME (" .. px .. "," .. py .. ")") or I18N.T("Grid Tile | tidak di world")
            if Title.Text ~= t then Title.Text = t end
        end
        task.wait(0.5)
    end
end)

-- Tombol ▲/▼ untuk Fly (muncul saat Fly aktif)
local FlyPad = newScreenGui("FianFlyPad")
UI.FlyPad = FlyPad

local function flyButton(text, yOffset, onHold)
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromOffset(64, 64)
    b.AnchorPoint = Vector2.new(1, 0.5)
    b.Position = UDim2.new(1, -24, 0.5, yOffset)
    b.BackgroundColor3 = Color3.fromRGB(17, 19, 26)
    b.BackgroundTransparency = 0.15
    b.Text = text
    b.Font = Enum.Font.GothamBold
    b.TextSize = 28
    b.TextColor3 = Color3.fromRGB(132, 196, 255)
    b.AutoButtonColor = true
    b.Parent = FlyPad
    Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)
    local st = Instance.new("UIStroke", b)
    st.Color = Color3.fromRGB(62, 150, 255)
    st.Thickness = 2
    -- dilepas saat jari diangkat (walau sudah geser keluar), supaya tidak nyangkut
    local heldInput = nil
    b.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseButton1 then
            heldInput = input
            onHold(true)
        end
    end)
    table.insert(Connections, UserInputService.InputEnded:Connect(function(input)
        if heldInput and (input == heldInput
            or (input.UserInputType == Enum.UserInputType.MouseButton1
                and heldInput.UserInputType == Enum.UserInputType.MouseButton1)) then
            heldInput = nil
            onHold(false)
        end
    end))
    return b
end

flyButton("▲", -40, function(v) Misc.UpHeld = v end)
flyButton("▼", 40, function(v) Misc.DownHeld = v end)

---------------------------------------------------------------------
-- UI WINDUI
---------------------------------------------------------------------
local Window = I18N.wrap(WindUI:CreateWindow({
    Title = "SkyP",
    Icon = "cloud-lightning",
    Author = "https://discord.gg/s5ajQ2Cpdp",
    Folder = "AlSkyP",
    Size = UDim2.fromOffset(640, 380),
    SideBarWidth = 150,
    SearchPlaceholder = I18N.T("Cari fitur..."),
    Text = { Pick = I18N.T("Pilih..."), Search = I18N.T("Cari fitur..."), NoResult = I18N.T("Tidak ada hasil") },
    ToggleKey = Enum.KeyCode.Insert,  -- PC: tekan Insert untuk buka/tutup menu
}))
-- Tombol minimize muncul di mobile DAN PC (OnlyMobile=false), bisa digeser.
-- Cadangan PC: kalau tombol susah dicari, tekan Insert.
pcall(function()
    Window:EditOpenButton({
        Title = "SkyP",
        Icon = "cloud-lightning",
        Draggable = true,
        OnlyMobile = false,
    })
end)

-- Kalau 1 elemen error, tab lain tetap dibuat
local function safe(fn)
    local ok, err = pcall(fn)
    if not ok then warn("[SkyP] UI error: " .. tostring(err)) end
end

-- HALAMAN DEPAN: 9 ikon menu. Tab-tab lama digabung ke menu sejenis (jadi bagian di dalam menu).
local Groups = {}
for _, g in ipairs({
    { key = "pabrik", title = "Pabrik", icon = "🏭", color = Color3.fromRGB(62, 150, 255), desc = "Farming otomatis penuh" },
    { key = "farm", title = "Farm", icon = "🧱", color = Color3.fromRGB(255, 170, 60), desc = "Place & break block" },
    { key = "farmer", title = "Farmer", icon = "🌱", color = Color3.fromRGB(70, 200, 120), desc = "Panen & tanam" },
    { key = "vending", title = "Vending", icon = "🏪", color = Color3.fromRGB(255, 110, 150), desc = "Isi & kosongkan stock" },
    { key = "world", title = "World", icon = "🌍", color = Color3.fromRGB(60, 200, 220), desc = "Clear & scan world" },
    { key = "ekstra", title = "Ekstra", icon = "🎒", color = Color3.fromRGB(170, 120, 255), desc = "Tas, bonus, chat" },
    { key = "aman", title = "Keamanan", icon = "🚨", color = Color3.fromRGB(240, 90, 100), desc = "Penjaga, staff & rejoin" },
    { key = "pantau", title = "Pantau", icon = "📊", color = Color3.fromRGB(250, 200, 70), desc = "Statistik & notifikasi" },
    { key = "setel", title = "Setelan", icon = "🔧", color = Color3.fromRGB(150, 160, 180), desc = "Pengaturan & koneksi" },
}) do
    local ok, sec = pcall(function()
        return Window:Section({ Title = g.title, Icon = g.icon, Color = g.color, Desc = g.desc })
    end)
    if ok and type(sec) == "table" and type(sec.Tab) == "function" then Groups[g.key] = sec end
end

-- Tab lama -> { menu, urutan di dalam menu }
UI.TabInfo = {
    ["Pabrik"] = { "pabrik", 1 }, ["Titik Drop"] = { "pabrik", 2 },
    ["Farm"] = { "farm", 1 }, ["Dirt Farm"] = { "farm", 2 },
    ["Farmer"] = { "farmer", 1 }, ["Splice"] = { "farmer", 2 },
    ["Vending"] = { "vending", 1 },
    ["Clear World"] = { "world", 1 }, ["Growscan"] = { "world", 2 },
    ["Tas"] = { "ekstra", 1 }, ["Bonus"] = { "ekstra", 2 }, ["Auto Chat"] = { "ekstra", 3 },
    ["Penjaga"] = { "aman", 1 }, ["Staff"] = { "aman", 2 }, ["Auto Rejoin"] = { "aman", 3 },
    ["Statistik"] = { "pantau", 1 }, ["Discord"] = { "pantau", 2 }, ["Observasi"] = { "pantau", 3 },
    ["Pengaturan"] = { "setel", 1 }, ["Koneksi"] = { "setel", 2 }, ["Admin"] = { "setel", 3 },
}
UI.OldGroup = { farm = "farm", fitur = "ekstra", aman = "aman", setel = "setel" } -- tab yang belum terdaftar

local function makeTab(title, icon, group)
    local info = UI.TabInfo[title]
    local key = (info and info[1]) or UI.OldGroup[group or ""] or "ekstra"
    local parent = Groups[key] or Window
    local ok, tab = pcall(function() return parent:Tab({ Title = title, Icon = icon, Order = info and info[2] }) end)
    if ok and tab then return tab end
    return Window:Tab({ Title = title })
end

-- Tanda "JALAN" di ikon menu yang fiturnya sedang aktif
task.spawn(function()
    local function set(key, on)
        local g = Groups[key]
        if g and g.SetActive then pcall(g.SetActive, g, on == true) end
    end
    while alive() do
        set("pabrik", Pabrik.Running)
        set("farm", State.Running and not State.Override)
        set("farmer", Farmer.Running or Splice.Running)
        set("vending", Vend.Running)
        set("world", Clear.Running)
        set("ekstra", Spam.On)
        set("aman", Guard.On)
        task.wait(1)
    end
end)

-- Kotak di dalam tab yang bisa dibuka / ditutup (supaya tab tidak terlihat penuh).
-- WindUI lama tanpa fitur ini: cuma judul, elemen tetap di tab.
local function box(tab, title, opened)
    local ok, sec = pcall(function()
        return tab:Section({ Title = title, Box = true, BoxBorder = true, Opened = opened == true })
    end)
    if ok and type(sec) == "table" and type(sec.Toggle) == "function" then return sec end
    pcall(function() tab:Section({ Title = title }) end)
    return tab
end
local Box = {}

-- Angka pakai Slider; kalau gagal, pakai kotak input
local function addNumber(tab, o)
    local ok = pcall(function()
        tab:Slider({
            Title = o.Title,
            Desc = o.Desc,
            Step = o.Step or 1,
            Value = { Min = o.Min, Max = o.Max, Default = o.Default },
            Callback = function(v)
                v = tonumber(v)
                if v then o.Callback(v) end
            end,
        })
    end)
    if ok then return end
    safe(function()
        tab:Input({
            Title = o.Title,
            Desc = (o.Desc and (o.Desc .. " ") or "") .. "(" .. o.Min .. "-" .. o.Max .. ")",
            Value = tostring(o.Default),
            Placeholder = tostring(o.Default),
            Callback = function(text)
                local v = tonumber(text)
                if v then o.Callback(math.clamp(v, o.Min, o.Max)) end
            end,
        })
    end)
end

-- ===== TAB: FARM =====
local FarmTab = makeTab("Farm", "pickaxe", "farm")

safe(function()
    UI.Status = FarmTab:Paragraph({ Title = "Status", Desc = "-" })
end)

Box.FarmCtl = box(FarmTab, "Kontrol", true)
Box.FarmBlock = box(FarmTab, "Block", true)
Box.FarmAuto = box(FarmTab, "Otomatis", true)
Box.FarmSpeed = box(FarmTab, "Lanjutan", false)

safe(function()
    UI.FarmToggle = Box.FarmCtl:Toggle({
        Title = "Auto Farm",
        Desc = "Bisa juga lewat tombol START di Grid",
        Value = false,
        Callback = function(on)
            if on then startFarm() elseif State.Running then stopFarm() end
        end,
    })
end)

safe(function()
    UI.FastToggle = Box.FarmCtl:Toggle({
        Title = "Break Cepat",
        Desc = "Break secepat batas server, tanpa jeda terbuang",
        Value = State.Fast,
        Callback = function(on)
            State.Fast = on
            State.NextHitAt = 0
            if on then
                if State.BreakMs > 220 then State.BreakMs = 220 end
                if not Refs.Punch then notify("Break Cepat", "Referensi Pukul belum ada. Tekan 'Hubungkan ke game' dulu", 4) end
            end
        end,
    })
end)

safe(function()
    Box.FarmCtl:Button({
        Title = "Break Kilat (1 block secepatnya)",
        Desc = "Bukan 1 hit: tiap block dipukul beruntun tanpa jeda terbuang sampai pecah, tepat di batas server. "
            .. "Sekali tekan = Break Cepat nyala, jeda pukul 200 ms, fokus 1 block",
        Callback = function()
            if UI.FastToggle then pcall(function() UI.FastToggle:Set(true) end) end
            State.Fast = true
            State.NextHitAt = 0
            State.BreakMs = 200
            State.MultiTarget = 1
            State.AfterBreakMs = 0
            notify("Break Kilat", Refs.Punch and "Aktif: jeda 200 ms, fokus 1 block"
                or "Aktif, tapi referensi Pukul belum ada. Tekan 'Hubungkan ke game' dulu", 4)
        end,
    })
end)

safe(function()
    Box.FarmCtl:Dropdown({
        Title = "Mode",
        Desc = "Place + Break / Break saja / Place saja",
        Values = { "Place + Break", "Break saja", "Place saja" },
        Value = State.Mode,
        Callback = function(opt) State.Mode = opt end,
    })
end)

safe(function()
    Box.FarmCtl:Toggle({
        Title = "Auto Collect",
        Desc = "Ambil drop di semua tile grid (caranya ikut Mode collect)",
        Value = State.AutoCollect,
        Callback = function(on) State.AutoCollect = on end,
    })
end)

safe(function()
    Box.FarmSpeed:Dropdown({
        Title = "Mode collect",
        Desc = "Berlaku untuk semua fitur. Sentuhan = seperti main manual. Remote = ambil dari jauh (cara lama, cepat). "
            .. "Jemput = tanpa Remote, karakter jalan sendiri mengambil drop di sekitar (nyalakan Collect di sekitar karakter)",
        Values = { "Otomatis (pintar)", "Sentuhan", "Remote", "Jemput" },
        Value = State.CollectAuto and "Otomatis (pintar)" or State.CollectMode,
        Callback = function(v)
            if type(v) == "table" then v = v[1] end
            if v == "Otomatis (pintar)" then
                State.CollectAuto = true
                State.CollectMode = "Remote"
                Drops.AutoBack = 0
            elseif v == "Sentuhan" or v == "Remote" or v == "Jemput" then
                State.CollectAuto = false
                State.CollectMode = v
            end
        end,
    })
end)

safe(function()
    Box.FarmSpeed:Toggle({
        Title = "Collect di sekitar karakter",
        Desc = "Mode Remote: ambil semua drop dalam radius, kapan saja. Mode Jemput: didatangi dengan berjalan",
        Value = State.CollectAround,
        Callback = function(on) State.CollectAround = on end,
    })
end)

addNumber(Box.FarmSpeed, {
    Title = "Radius collect (mode Remote)",
    Desc = "Jarak ambil drop di sekitar karakter (tile)",
    Min = 1, Max = 5, Step = 1, Default = State.CollectRadius,
    Callback = function(v) State.CollectRadius = math.floor(v) end,
})

addNumber(Box.FarmSpeed, {
    Title = "Jangkauan Remote (tile)",
    Desc = "Jarak maksimal permintaan Remote. Drop yang lebih jauh tidak ditembak (ditolak server), tapi dijemput",
    Min = 1, Max = 5, Step = 1, Default = State.RemoteReach,
    Callback = function(v) State.RemoteReach = math.floor(v) end,
})

safe(function()
    Box.FarmSpeed:Toggle({
        Title = "Jemput drop yang jauh",
        Desc = "Drop di luar jangkauan Remote tapi dalam radius: karakter jalan mendekat lalu balik. Hanya saat tidak ada fitur lain yang menggerakkan karakter",
        Value = State.RemoteChase,
        Callback = function(on) State.RemoteChase = on end,
    })
end)


safe(function()
    Box.FarmCtl:Button({
        Title = "Buka Grid Tile",
        Desc = "Kotak 5x5, tengah = karakter",
        Callback = function() GridGui.Enabled = true end,
    })
end)

-- ===== FARM TERPADU =====
safe(function()
    Box.FarmAuto:Toggle({
        Title = "Auto Drop Seed",
        Desc = "Seed hasil break di-drop otomatis kalau sudah mencapai jumlah di bawah",
        Value = State.SeedDrop,
        Callback = function(on)
            State.SeedDrop = on
            if on and Pabrik.pointSet and not Pabrik.pointSet() then
                notify("Auto Drop Seed", "Atur lokasi drop dulu di bawah", 4)
            end
        end,
    })
end)
addNumber(Box.FarmSpeed, {
    Title = "Drop kalau seed sudah",
    Desc = "Contoh 200",
    Min = 2, Max = 200, Step = 1, Default = State.SeedDropAt,
    Callback = function(v) State.SeedDropAt = math.floor(v) end,
})
addNumber(Box.FarmSpeed, {
    Title = "Sisakan seed",
    Min = 0, Max = 199, Step = 1, Default = State.SeedKeep,
    Callback = function(v) State.SeedKeep = math.floor(v) end,
})
safe(function()
    UI.UniDropWorld = Box.FarmSpeed:Input({
        Title = "Lokasi drop (world)",
        Desc = "Kosong = world ini | WORLD | WORLD:ID (pintu)",
        Value = Pabrik.DropWorld,
        Placeholder = "STORAGE:1",
        Callback = function(t)
            Pabrik.DropWorld = tostring(t or "")
            if UI.DropWorldInput then pcall(function() UI.DropWorldInput:Set(Pabrik.DropWorld) end) end
        end,
    })
end)
safe(function()
    Box.FarmSpeed:Button({
        Title = "Simpan posisi karakter sebagai lokasi drop",
        Desc = "Berdiri di tempat drop (boleh di world lain), lalu tekan",
        Callback = function()
            local x, y = Auto.here()
            if not x then
                notify("Auto Drop Seed", "Kamu belum masuk world", 3)
                return
            end
            Pabrik.DropX, Pabrik.DropY = x, y
            if not string.find(Pabrik.DropWorld or "", ":", 1, true) then
                Pabrik.DropWorld = Guard.worldName()
                if UI.UniDropWorld then pcall(function() UI.UniDropWorld:Set(Pabrik.DropWorld) end) end
                if UI.DropWorldInput then pcall(function() UI.DropWorldInput:Set(Pabrik.DropWorld) end) end
            end
            notify("Auto Drop Seed", ("Lokasi drop (%d,%d) di %s"):format(x, y, Pabrik.DropWorld), 4)
        end,
    })
end)
safe(function()
    Box.FarmAuto:Toggle({
        Title = "Auto Refill Block",
        Desc = "Block habis: ambil block yang tersedia di sekitar, lalu lanjut",
        Value = State.AutoRefill,
        Callback = function(on) State.AutoRefill = on end,
    })
end)
addNumber(Box.FarmSpeed, {
    Title = "Jarak cari block (tile)",
    Min = 3, Max = 30, Step = 1, Default = State.RefillRadius,
    Callback = function(v) State.RefillRadius = math.floor(v) end,
})
safe(function()
    Box.FarmAuto:Toggle({
        Title = "Auto Return",
        Desc = "Kembali ke posisi awal farm (posisi saat START) setelah refill / drop / bergeser",
        Value = State.AutoReturn,
        Callback = function(on) State.AutoReturn = on end,
    })
end)

-- ===== TAB: CLEAR WORLD =====
local ClearTab = makeTab("Clear World", "eraser", "farm")

safe(function()
    UI.ClearStatus = ClearTab:Paragraph({ Title = "Status Clear", Desc = "-" })
end)

Box.ClearCtl = box(ClearTab, "Kontrol", true)
Box.ClearSet = box(ClearTab, "Pengaturan", false)

safe(function()
    UI.ClearToggle = Box.ClearCtl:Toggle({
        Title = "Auto Clear World",
        Desc = "Bersihkan dari baris atas ke bawah",
        Value = false,
        Callback = function(on)
            if on then Auto.startClear() elseif Clear.Running then stopClear() end
        end,
    })
end)

safe(function()
    Box.ClearSet:Dropdown({
        Title = "Arah sapu",
        Desc = "Zig-zag lebih cepat (tidak balik ke kiri)",
        Values = { "Kiri → Kanan", "Zig-zag" },
        Value = Clear.Sweep,
        Callback = function(opt) Clear.Sweep = opt end,
    })
end)

safe(function()
    Box.ClearSet:Toggle({
        Title = "Pakai block pijakan",
        Desc = "Taruh block untuk lewat jurang / naik ke block melayang",
        Value = Clear.UseBlock,
        Callback = function(on)
            Clear.UseBlock = on
            Auto.resetReach()
        end,
    })
end)

safe(function()
    UI.ClearBlockDropdown = Box.ClearSet:Dropdown({
        Title = "Block pijakan",
        Desc = "Block yang dipakai untuk pijakan",
        Values = { "(memuat...)" },
        Callback = function(opt)
            local id = tonumber(string.match(opt or "", "%[(%d+)%]$"))
            if id then
                Clear.ScaffoldId = id
                Auto.resetReach()
            end
        end,
    })
end)

safe(function()
    Box.ClearSet:Toggle({
        Title = "Auto collect tiap habis pecah",
        Desc = "Drop di sekitar disusuri sampai tersentuh badan (tanpa remote)",
        Value = Clear.Collect,
        Callback = function(on) Clear.Collect = on end,
    })
end)

safe(function()
    Box.ClearCtl:Button({
        Title = "Reset tile yang dilewati",
        Desc = "Coba lagi tile yang tadi gagal",
        Callback = function()
            table.clear(Clear.Skip)
            table.clear(Auto.BadEdge)
            table.clear(Auto.ClearFail)
            Auto.updateClearStatus()
        end,
    })
end)

-- ===== TAB: FARMER =====
local FarmerTab = makeTab("Farmer", "leaf", "farm")

safe(function()
    UI.FarmerStatus = FarmerTab:Paragraph({ Title = "Status Farmer", Desc = "-" })
end)

Box.FarmerCtl = box(FarmerTab, "Kontrol", true)
Box.FarmerSeed = box(FarmerTab, "Seed", true)
Box.FarmerSpeed = box(FarmerTab, "Kecepatan", false)
Box.FarmerBlock = box(FarmerTab, "Block pijakan", false)

safe(function()
    UI.FarmerToggle = Box.FarmerCtl:Toggle({
        Title = "Jalankan Farmer",
        Desc = "Panen pohon siap & tanam seed otomatis",
        Value = false,
        Callback = function(on)
            if on then Auto.startFarmer() elseif Farmer.Running then stopFarmer() end
        end,
    })
end)

safe(function()
    UI.SeedDropdown = Box.FarmerSeed:Dropdown({
        Title = "Seed untuk ditanam",
        Desc = "Hanya seed yang ada di inventori",
        Values = { "(memuat...)" },
        Callback = function(opt)
            local id = tonumber(string.match(opt or "", "%[(%d+)%]$"))
            if id then
                Farmer.SeedId = id
                table.clear(Farmer.Skip)
                Auto.updateFarmerStatus()
            end
        end,
    })
end)

safe(function()
    Box.FarmerSeed:Button({
        Title = "Refresh daftar seed",
        Callback = function() UI.later("invForce", function() doInvRefresh(true) end) end,
    })
end)

safe(function()
    Box.FarmerCtl:Toggle({
        Title = "Auto Harvest",
        Desc = "Hanya pohon yang sudah siap",
        Value = Farmer.Harvest,
        Callback = function(on) Farmer.Harvest = on end,
    })
end)

safe(function()
    Box.FarmerCtl:Toggle({
        Title = "Auto Plant",
        Desc = "Tanam di atas block yang kosong",
        Value = Farmer.Plant,
        Callback = function(on) Farmer.Plant = on end,
    })
end)

safe(function()
    Box.FarmerCtl:Toggle({
        Title = "Auto Collect",
        Desc = "Ambil hasil panen di sekitar karakter",
        Value = Farmer.Collect,
        Callback = function(on) Farmer.Collect = on end,
    })
end)

addNumber(Box.FarmerSpeed, {
    Title = "Speed Harvest (ms)",
    Desc = "Jeda setelah tiap panen",
    Min = 140, Max = 2000, Step = 10, Default = Farmer.HarvestMs,
    Callback = function(v) Farmer.HarvestMs = math.floor(v) end,
})

addNumber(Box.FarmerSpeed, {
    Title = "Speed Plant (ms)",
    Desc = "Jeda setelah tiap tanam seed",
    Min = 140, Max = 2000, Step = 10, Default = Farmer.PlantMs,
    Callback = function(v) Farmer.PlantMs = math.floor(v) end,
})

safe(function()
    Box.FarmerBlock:Toggle({
        Title = "Pakai block pijakan",
        Desc = "Taruh block kalau tidak ada jalan (block tetap tertinggal)",
        Value = Farmer.UseBlock,
        Callback = function(on)
            Farmer.UseBlock = on
            Auto.resetReach()
        end,
    })
end)

safe(function()
    UI.FarmerBlockDropdown = Box.FarmerBlock:Dropdown({
        Title = "Block pijakan",
        Desc = "Block yang dipakai untuk pijakan",
        Values = { "(memuat...)" },
        Callback = function(opt)
            local id = tonumber(string.match(opt or "", "%[(%d+)%]$"))
            if id then
                Farmer.ScaffoldId = id
                Auto.resetReach()
            end
        end,
    })
end)

-- ===== FARM: MODE & KECEPATAN =====
local SpeedTab = Box.FarmSpeed -- digabung ke tab Farm (kotak "Lanjutan")

addNumber(SpeedTab, {
    Title = "Speed Place (ms)",
    Desc = "Jeda setelah tiap place",
    Min = 140, Max = 1000, Step = 10, Default = State.PlaceMs,
    Callback = function(v) State.PlaceMs = math.floor(v) end,
})

addNumber(SpeedTab, {
    Title = "Speed Break (ms)",
    Desc = "Jeda tiap pukulan (normal 220). Dipakai juga Clear",
    Min = 200, Max = 1000, Step = 10, Default = State.BreakMs,
    Callback = function(v) State.BreakMs = math.floor(v) end,
})

addNumber(SpeedTab, {
    Title = "Multi target break",
    Desc = "Auto Farm: tile dipukul bergantian (seperti 2 jari). Pakai Rayman's Fist = 2-3 tile segaris sekali pukul",
    Min = 1, Max = 5, Step = 1, Default = State.MultiTarget,
    Callback = function(v) State.MultiTarget = math.clamp(math.floor(v), 1, 5) end,
})

addNumber(SpeedTab, {
    Title = "Jeda setelah hancur (ms)",
    Desc = "Tunggu sebelum lanjut ke tile berikutnya",
    Min = 0, Max = 1500, Step = 50, Default = State.AfterBreakMs,
    Callback = function(v) State.AfterBreakMs = math.floor(v) end,
})

-- ===== TAB: PENGATURAN (Opsi + Misc digabung) =====
local SetTab = makeTab("Pengaturan", "sliders-horizontal", "setel")
Box.SetChar = box(SetTab, "Karakter", true)
Box.SetOpt = box(SetTab, "Opsi", true)
local OptTab = Box.SetOpt

safe(function()
    OptTab:Toggle({
        Title = "Mode Lite",
        Desc = "Matikan particle & suara (HP low-end)",
        Value = State.LiteMode,
        Callback = function(on) setLite(on) end,
    })
end)

safe(function()
    OptTab:Toggle({
        Title = "Mute suara pukulan",
        Value = State.MutePunch,
        Callback = function(on) State.MutePunch = on end,
    })
end)

safe(function()
    OptTab:Toggle({
        Title = "Animasi aksi",
        Desc = "Tangan bergerak saat break / place / tanam / panen + efek place. Matikan untuk hemat FPS",
        Value = State.Visual,
        Callback = function(on)
            State.Visual = on
            if on and not Anim.fn and Refs.World then
                notify("Animasi", "Fungsi animasi game tidak ketemu (tekan 'Hubungkan ke game')", 4)
            end
        end,
    })
end)

safe(function()
    OptTab:Toggle({
        Title = "Anti AFK",
        Value = State.AntiAfk,
        Callback = function(on) State.AntiAfk = on end,
    })
end)

addNumber(OptTab, {
    Title = "Pukulan per block (cadangan)",
    Desc = "Dipakai kalau 'Pukul: TIDAK'. 0 = otomatis",
    Min = 0, Max = 20, Step = 1, Default = State.HitsOverride,
    Callback = function(v) State.HitsOverride = math.floor(v) end,
})

-- ===== FARM: PILIH BLOCK =====
local InvTab = Box.FarmBlock -- digabung ke tab Farm

safe(function()
    UI.InvDropdown = InvTab:Dropdown({
        Title = "Pilih Block",
        Desc = "Hanya item yang bisa di-place",
        Values = { "(memuat...)" },
        Callback = function(opt)
            local id = tonumber(string.match(opt or "", "%[(%d+)%]$"))
            if id then
                State.SelectedId = id
                updateStatus()
            end
        end,
    })
end)

safe(function()
    InvTab:Button({
        Title = "Refresh daftar",
        Callback = function() UI.later("invForce", function() doInvRefresh(true) end) end,
    })
end)

-- ===== PENGATURAN: KARAKTER =====
local MiscTab = Box.SetChar

addNumber(MiscTab, {
    Title = "Walkspeed (%)",
    Desc = "100 = normal",
    Min = 50, Max = 500, Step = 10, Default = Misc.Speed,
    Callback = function(v) setSpeed(v) end,
})

safe(function()
    MiscTab:Toggle({
        Title = "Infinite Jump",
        Desc = "Lompat di udara (bisa kena rollback)",
        Value = false,
        Callback = function(on) setInfJump(on) end,
    })
end)

safe(function()
    UI.GhostToggle = MiscTab:Toggle({
        Title = "Fly + Tembus Block",
        Desc = "Tembus block, pakai tombol ▲/▼ (bisa kena rollback)",
        Value = false,
        Callback = function(on) setGhost(on) end,
    })
end)

-- ===== TAB: AUTO CHAT =====
local ChatTab = makeTab("Auto Chat", "message-circle", "fitur")

safe(function()
    UI.SpamStatus = ChatTab:Paragraph({ Title = "Status Chat", Desc = "-" })
end)

Box.ChatCtl = box(ChatTab, "Kontrol", true)
Box.ChatMsg = box(ChatTab, "Pesan", true)

safe(function()
    Box.ChatMsg:Input({
        Title = "Daftar pesan",
        Desc = "Pisahkan dengan |   contoh: halo|jual dirt",
        Value = table.concat(Spam.Texts, "|"),
        Placeholder = "pesan 1|pesan 2|pesan 3",
        Callback = function(text)
            Spam.Texts = parseSpamTexts(text)
            Spam.Index = 1
            updateSpamStatus()
        end,
    })
end)

addNumber(Box.ChatMsg, {
    Title = "Interval (detik)",
    Desc = "Jeda antar pesan (min 3 detik)",
    Min = 3, Max = 120, Step = 1, Default = Spam.IntervalSec,
    Callback = function(v) Spam.IntervalSec = math.max(3, math.floor(v)) end,
})

safe(function()
    UI.SpamToggle = Box.ChatCtl:Toggle({
        Title = "Auto Chat",
        Desc = "Kirim pesan bergantian sesuai urutan",
        Value = false,
        Callback = function(on)
            Spam.On = on
            if on then
                if #Spam.Texts == 0 then notify("Auto Chat", "Isi daftar pesan dulu (tekan Enter setelah mengetik)", 4) end
                Spam.NextAt = 0 -- langsung kirim pesan pertama
            end
            updateSpamStatus()
        end,
    })
end)

safe(function()
    Box.ChatCtl:Button({
        Title = "Kirim 1 pesan sekarang",
        Desc = "Tes kirim pesan berikutnya",
        Callback = function()
            task.spawn(function()
                sendNextChat()
                updateSpamStatus()
            end)
        end,
    })
end)

do
    local function roleList()
        local _Gi, _Gj = {"none"}, {none = true}
        if RolesOk and type(RolesModule) == "table" and type(RolesModule.titlesOf) == "function" then
            local _Gk, _Gl = pcall(RolesModule.titlesOf, LocalPlayer.UserId)
            if _Gk and type(_Gl) == "table" then
                for _Gm, _Gn in ipairs(_Gl) do
                    if type(_Gn) == "string" and not _Gj[_Gn] then
                        _Gj[_Gn] = true
                        local _Go = _Gn
                        if type(RolesModule.titleName) == "function" then
                            local _Gp, _Gq = pcall(RolesModule.titleName, _Gn)
                            if _Gp and type(_Gq) == "string" and _Gq ~= "" and _Gq ~= _Gn then
                                _Go = _Gq .. " [" .. _Gn .. "]"
                            end
                        end
                        table.insert(_Gi, _Go)
                    end
                end
            end
        end
        return _Gi
    end

    local function roleKey(_Gs)
        return string.match(_Gs or "", "%[(.-)%]$") or _Gs
    end

    local function roleRefresh()
        if UI.RoleDropdown then
            pcall(function()
                UI.RoleDropdown:Refresh(roleList())
            end)
        end
    end
    local StaffTab = makeTab("Staff", "user-cog", "aman")
    safe(function()
        StaffTab:Button({
            Title = "Buka Staff Backpack",
            Desc = "UI staff bawaan game (dikunci server)",
            Callback = function()
                if Refs.Menu and type(Refs.Menu.openBackpack) == "function" then
                    local _Gv = {name = LocalPlayer.DisplayName or LocalPlayer.Name, userId = LocalPlayer.UserId}
                    local _Gw, _Gx = pcall(Refs.Menu.openBackpack, _Gv)
                    if not _Gw then
                        notify("Staff", "Gagal buka: " .. tostring(_Gx), 4)
                    end
                else
                    notify("Staff", "Menu game belum ketemu. Tekan 'Hubungkan ke game' dulu", 4)
                end
            end,
        })
    end)
    safe(function()
        UI.RoleDropdown = StaffTab:Dropdown({
            Title = "Role / Title",
            Desc = "Title yang kamu punya",
            Values = {"none"},
            Callback = function(_Gy)
                State.Role = roleKey(_Gy)
            end,
        })
    end)
    safe(function()
        StaffTab:Button({Title = "Refresh daftar role", Callback = roleRefresh,})
    end)
    safe(function()
        StaffTab:Button({
            Title = "Pakai Role",
            Desc = "Sama seperti menu Title game",
            Callback = function()
                local _Gz = (State.Role ~= "" and State.Role) or "none"
                if NetOk and type(Net) == "table" and type(Net.call) == "function" then
                    task.spawn(function()
                        local _GA, _GB = pcall(Net.call, "PickTitle", _Gz)
                        notify("Staff", _GA and ("Role dikirim: " .. _Gz) or ("Gagal: " .. tostring(_GB)), 4)
                    end)
                else
                    local _GC = WorldRemotes:FindFirstChild("PickTitle")
                    if _GC then
                        pcall(function()
                            _GC:FireServer(_Gz)
                        end)
                        notify("Staff", "Role dikirim: " .. _Gz)
                    else
                        notify("Staff", "Fungsi PickTitle tidak ada")
                    end
                end
            end,
        })
    end)
    Session.refreshRoles = roleRefresh
end

---------------------------------------------------------------------
-- PENJAGA: deteksi Mod / Dev / pemain yang masuk world
---------------------------------------------------------------------
-- Cara kerja:
--   1. Tiap 0.5 detik baca daftar pemain di world (data game "Others").
--   2. Role dicek pakai modul Roles game (Developer / Moderator, undercover juga ketahuan).
--   3. Ada yang dicari -> semua aktivitas dihentikan, bisa juga langsung keluar world.
--   4. Setelah aman -> aktivitas sebelumnya dilanjutkan.
--      Mode keluar: tunggu X detik, masuk world lagi, cek lagi.
--      Masih ada orangnya -> keluar lagi. Sudah aman -> lanjut (Auto Farm jalan balik ke posisi awal).

do (function() -- fungsi sendiri: variabel di dalam tidak ikut batas 200 local
    local function strip(s) return (tostring(s or ""):gsub("`.", "")) end

    local function roleOf(uid)
        if not (RolesOk and type(RolesModule) == "table") then return nil end
        local okD, dev = pcall(RolesModule.isDeveloper, uid)
        if okD and dev then return "Developer" end
        local okM, mod = pcall(RolesModule.isModerator, uid)
        if okM and mod then return "Moderator" end
        return nil
    end

    local function worldName()
        local n = Refs.World and rawget(Refs.World, "name")
        return type(n) == "string" and n or ""
    end

    -- v2.2: layar pilih world ("World Name" / tombol "Enter World") sedang tampil?
    -- Saat terlempar ke layar ini, game TIDAK mengosongkan data world (nama, posisi karakter),
    -- jadi worldName() saja tidak cukup: script mengira masih di world padahal di menu.
    local pickList, pickScanAt = {}, -100
    local function guiShown(g)
        local cur = g
        while cur and cur ~= game do
            if cur:IsA("GuiObject") and not cur.Visible then return false end
            if cur:IsA("LayerCollector") then return cur.Enabled == true end
            cur = cur.Parent
        end
        return false
    end
    local function isPickBtn(d)
        if not (d:IsA("TextButton") or d:IsA("TextLabel")) then return false end
        local t = string.lower(tostring(d.Text or ""))
        return string.find(t, "^%s*enter%s+world%s*$") ~= nil
    end
    local function pickerOpen()
        local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if not pg then return false end
        for i = #pickList, 1, -1 do
            local b = pickList[i]
            if not b.Parent or not b:IsDescendantOf(pg) then table.remove(pickList, i) end
        end
        -- cari ulang tombolnya (GUI menu bisa dibuat ulang game) paling cepat tiap 6 detik
        if os.clock() - pickScanAt > 6 and (#pickList == 0 or os.clock() - pickScanAt > 30) then
            pickScanAt = os.clock()
            local found = {}
            pcall(function()
                for _, d in ipairs(pg:GetDescendants()) do
                    if isPickBtn(d) then found[#found + 1] = d end
                end
            end)
            pickList = found
        end
        for _, b in ipairs(pickList) do
            local ok, vis = pcall(function()
                if not guiShown(b) or b.AbsoluteSize.X <= 4 or b.AbsoluteSize.Y <= 4 then return false end
                -- harus benar-benar di layar (bukan disembunyikan dengan digeser keluar layar)
                local cam = workspace.CurrentCamera
                if not cam then return true end
                local vp = cam.ViewportSize
                local c = b.AbsolutePosition + b.AbsoluteSize / 2
                return c.X > -50 and c.Y > -100 and c.X < vp.X + 50 and c.Y < vp.Y + 50
            end)
            if ok and vis then return true end
        end
        return false
    end
    -- benar-benar di dalam world (bukan di layar pilih world)
    local function inWorld()
        return worldName() ~= "" and not pickerOpen()
    end

    -- Pemain lain di world ini: { id, name, role }
    local function playersHere()
        local out = {}
        local o = Refs.Others
        if not o or type(rawget(o, "list")) ~= "function" then return out end
        local ok, list = pcall(o.list)
        if not ok or type(list) ~= "table" then return out end
        for _, e in ipairs(list) do
            local uid = type(e) == "table" and tonumber(e[1] or e.userId)
            if uid and uid ~= LocalPlayer.UserId then
                out[#out + 1] = { id = uid, name = strip(e[2] or e.name or uid), role = roleOf(uid) }
            end
        end
        return out
    end
    Guard.playersHere = playersHere

    local function threatsOf(list)
        local out = {}
        for _, p in ipairs(list) do
            if p.role or (Guard.Who == "Semua pemain" and not Guard.Allow[p.id]) then
                out[#out + 1] = p
            end
        end
        return out
    end

    local function label(p)
        local under = false
        if p.role and type(RolesModule.isUndercover) == "function" then
            local ok, u = pcall(RolesModule.isUndercover, p.id)
            under = ok and u == true
        end
        return p.name .. " (" .. (p.role or "Pemain") .. (under and ", undercover" or "") .. ")"
    end

    local function names(list, max)
        local t = {}
        for i, p in ipairs(list) do
            if i > (max or 4) then
                t[#t + 1] = "+" .. (#list - i + 1) .. " lagi"
                break
            end
            t[#t + 1] = label(p)
        end
        return table.concat(t, ", ")
    end

    local function anyRunning()
        return State.Running or Clear.Running or Farmer.Running or Splice.Running or Spam.On
            or Pabrik.Running
    end

    -- Catat aktivitas yang sedang jalan (untuk dilanjutkan nanti)
    local function snapshot()
        local tx, ty = Auto.here()
        return {
            farm = State.Running and not State.Override, clear = Clear.Running, farmer = Farmer.Running,
            spam = Spam.On, splice = Splice.Running, pabrik = Pabrik.Running,
            world = worldName(), tx = tx, ty = ty,
        }
    end

    local function stopAll()
        Auto.stopWalk()
        if Pabrik.Running then Pabrik.stop() end
        if State.Running then stopFarm() end
        if Clear.Running then
            stopClear()
            Clear.Status = "Dijeda Penjaga"
        end
        if Farmer.Running then
            stopFarmer()
            Farmer.Status = "Dijeda Penjaga"
        end
        if Splice.Running and Splice.stop then Splice.stop() end
        if Vend.Running and Vend.stop then Vend.stop() end
        if Spam.On then
            Spam.On = false
            if UI.SpamToggle then pcall(function() UI.SpamToggle:Set(false) end) end
        end
        Auto.releaseInput()
    end

    -- Keluar world = sama seperti tombol "Exit World" game
    local function leaveWorld()
        local m = Refs.Menu
        if m and type(rawget(m, "openPicker")) == "function" and pcall(m.openPicker) then
            return true
        end
        local w = Refs.World
        if w and type(rawget(w, "call")) == "function" then
            return (pcall(w.call, "LeaveWorld"))
        end
        return false
    end

    -- Masuk world lewat menu game (sama seperti ketik nama world lalu Enter)
    local function enterWorld(name)
        local w = Refs.World
        if not w or name == "" then return false, "nama world tidak diketahui" end
        local oldFg = rawget(w, "fg")
        local wasPicker = pickerOpen()
        local want = string.upper(name)
        local m = Refs.Menu
        if m and type(rawget(m, "enter")) == "function" then
            pcall(m.enter, name)
        elseif type(rawget(w, "enter")) == "function" then
            local ok, res, msg = pcall(w.enter, name)
            if ok and not res then return false, strip(msg) end
        else
            return false, "fungsi masuk world tidak ketemu"
        end
        -- v2.2: berhasil kalau data world sudah baru, namanya world tujuan, layar pilih world
        -- sudah tertutup, dan keadaan itu bertahan 1.5 dtk (dulu cukup data world berubah,
        -- sehingga "berhasil" padahal karakter masih / kembali di layar pilih world)
        local t0, okSince = os.clock(), nil
        while alive() and os.clock() - t0 < 15 do
            local changed = rawget(w, "fg") ~= oldFg
            local good = (changed or wasPicker) and string.upper(worldName()) == want and not pickerOpen()
            if good then
                okSince = okSince or os.clock()
                if os.clock() - okSince >= 1.5 then return true end
            else
                okSince = nil
            end
            task.wait(0.25)
        end
        if pickerOpen() then return false, "masih di layar pilih world (penuh / dikunci / gagal)" end
        return false, "world penuh / dikunci / gagal"
    end

    local function stillBack(token)
        return alive() and Guard.Token == token and Guard.Mode == "back"
    end

    -- Lanjutkan aktivitas yang tadi dihentikan
    local function resumeAll(saved, token)
        if not saved then return end
        if saved.world ~= "" and worldName() ~= saved.world then
            notify("Penjaga", "World sudah beda, aktivitas tidak dilanjutkan", 5)
            return
        end
        if saved.spam and not Spam.On and stillBack(token) then
            if UI.SpamToggle then pcall(function() UI.SpamToggle:Set(true) end) end
            Spam.On = true
        end
        if saved.pabrik then
            if stillBack(token) then Pabrik.start() end
        elseif saved.farm then
            -- Auto Farm memakai tile di sekitar karakter, jadi harus balik ke posisi awal
            local hx, hy = Auto.here()
            if saved.tx and (hx ~= saved.tx or hy ~= saved.ty) then
                Guard.BackText = ("Jalan balik ke posisi farm (%d,%d)"):format(saved.tx, saved.ty)
                local ok = Auto.walkTo(saved.tx, saved.ty, 45)
                if not ok and stillBack(token) then ok = Auto.walkTo(saved.tx, saved.ty, 30) end
                if not ok then
                    if stillBack(token) then
                        notify("Penjaga", "Gagal balik ke posisi farm. Auto Farm tidak dilanjutkan", 6)
                    end
                    return
                end
            end
            if stillBack(token) then startFarm() end
        elseif saved.clear then
            if stillBack(token) then Auto.startClear() end
        elseif saved.farmer then
            if stillBack(token) then Auto.startFarmer() end
        elseif saved.splice then
            if stillBack(token) and Splice.start then Splice.start() end
        end
    end

    local function beginResume()
        local saved = Guard.Saved
        Guard.Token += 1
        local token = Guard.Token
        Guard.Mode = "back"
        Guard.BackText = nil
        task.spawn(function()
            local ok, err = pcall(resumeAll, saved, token)
            if not ok then warn("[SkyP] Penjaga lanjut error: " .. tostring(err)) end
            if Guard.Token == token and Guard.Mode == "back" then
                Guard.Mode, Guard.Saved, Guard.BackText = "idle", nil, nil
            end
        end)
    end

    local function goAway()
        if not leaveWorld() then
            notify("Penjaga", "Gagal keluar world, aktivitas hanya dijeda", 5)
            Guard.Mode = "pause"
            return
        end
        task.wait(0.3)
        Guard.LeftFg = Refs.World and rawget(Refs.World, "fg")
        Guard.BackAt = os.clock() + Guard.BackSec
        Guard.Mode = Guard.AutoBack and "away" or "out"
        Guard.Status = "Keluar world"
    end

    -- Ada orang baru yang dicari masuk world
    local function trigger(fresh)
        Guard.Detected += #fresh
        notify("Penjaga", "Masuk world: " .. names(fresh), 6)
        Hook.send("penjaga", "Masuk world " .. worldName() .. ": " .. names(fresh))
        if not Guard.StopAll and not Guard.Leave then return end -- hanya peringatan
        -- simpan aktivitas (kalau sedang jalan balik, pakai catatan lama)
        if Guard.Mode ~= "back" and (anyRunning() or not Guard.Saved) then
            Guard.Saved = snapshot()
        end
        Guard.Token += 1
        stopAll()
        Guard.CalmAt = nil
        if Guard.Leave then
            goAway()
            if Guard.Mode == "away" then
                notify("Penjaga", "Keluar world. Masuk lagi dalam " .. Guard.BackSec .. " detik", 5)
                Hook.send("penjaga", "Keluar world, masuk lagi dalam " .. Guard.BackSec .. " detik")
            elseif Guard.Mode == "out" then
                notify("Penjaga", "Keluar world", 4)
            end
        else
            Guard.Mode = "pause"
        end
    end

    -- Setelah masuk world lagi: cek dulu, masih ada orangnya atau tidak
    local function checkAfterEnter()
        Auto.resetReach()
        pcall(findDropRefs)
        pcall(Auto.findTreeRefs)
        table.clear(DropFailUntil)
        task.wait(1.5) -- tunggu daftar pemain terisi
        local th = threatsOf(playersHere())
        if #th > 0 then
            for _, p in ipairs(th) do Guard.Alerted[p.id] = true end
            notify("Penjaga", "Masih ada " .. names(th) .. ". Keluar lagi", 5)
            goAway()
            return
        end
        notify("Penjaga", "World aman, lanjut aktivitas", 4)
        Hook.send("penjaga", "World " .. worldName() .. " aman, lanjut aktivitas")
        beginResume()
    end

    -- Staff yang online di server (bukan hanya di world ini)
    local lastScan, staffText = -10, "-"
    local function serverStaff()
        if os.clock() - lastScan < 3 then return staffText end
        lastScan = os.clock()
        local t = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local r = roleOf(plr.UserId)
                if r then t[#t + 1] = (plr.DisplayName or plr.Name) .. " (" .. r .. ")" end
            end
        end
        staffText = (#t > 0) and table.concat(t, ", ") or "tidak ada"
        return staffText
    end

    function Guard.tick(here)
        if not Guard.On then
            Guard.Status = "Mati"
            return
        end
        local now = os.clock()
        local mode = Guard.Mode

        -- ===== sedang di luar world =====
        if mode == "away" or mode == "out" then
            local fgNow = Refs.World and rawget(Refs.World, "fg")
            if Guard.LeftFg and fgNow ~= Guard.LeftFg then
                -- sudah masuk world lagi secara manual
                if mode == "away" and Guard.Saved and worldName() == Guard.Saved.world then
                    checkAfterEnter()
                else
                    Guard.Mode, Guard.Saved = "idle", nil
                end
                return
            end
            local name = Guard.Saved and Guard.Saved.world or ""
            if mode == "out" or name == "" then
                Guard.Status = "Sudah keluar world (lanjut otomatis mati)"
                return
            end
            local left = Guard.BackAt - now
            if left > 0 then
                Guard.Status = ("Di luar world. Masuk lagi ke %s dalam %d detik"):format(name, math.ceil(left))
                return
            end
            Guard.Status = "Masuk lagi ke " .. name .. "..."
            Guard.updateStatus({})
            local ok, err = enterWorld(name)
            if not ok then
                Guard.BackAt = os.clock() + math.max(15, Guard.BackSec)
                notify("Penjaga", "Gagal masuk " .. name .. ": " .. tostring(err) .. ". Dicoba lagi nanti", 5)
                return
            end
            checkAfterEnter()
            return
        end

        -- ===== di dalam world =====
        local present = {}
        for _, p in ipairs(here) do present[p.id] = true end
        for id in pairs(Guard.Alerted) do
            if not present[id] then Guard.Alerted[id] = nil end -- sudah pergi
        end
        local threats = threatsOf(here)
        local fresh = {}
        for _, p in ipairs(threats) do
            if not Guard.Alerted[p.id] then
                Guard.Alerted[p.id] = true
                fresh[#fresh + 1] = p
            end
        end
        if #fresh > 0 then
            trigger(fresh)
            if Guard.Mode == "away" or Guard.Mode == "out" then return end
        end

        if #threats > 0 then
            Guard.CalmAt = nil
            Guard.Status = (Guard.Mode == "pause" and "Dijeda. Ada: " or "Waspada. Ada: ") .. names(threats)
            return
        end

        if Guard.Mode == "pause" then
            Guard.CalmAt = Guard.CalmAt or now
            local wait = Guard.CalmSec - (now - Guard.CalmAt)
            if wait > 0 then
                Guard.Status = ("Mereka sudah pergi. Lanjut dalam %d detik"):format(math.ceil(wait))
                return
            end
            Guard.CalmAt = nil
            if Guard.AutoBack and Guard.Saved then
                notify("Penjaga", "Sudah aman, lanjut aktivitas", 4)
                beginResume()
            else
                Guard.Mode, Guard.Saved = "idle", nil
            end
            return
        end

        if Guard.Mode == "back" then
            Guard.Status = Guard.BackText or "Lanjut aktivitas..."
            return
        end
        Guard.Status = "Aman"
    end

    function Guard.updateStatus(here)
        local txt = table.concat({
            "Status: " .. Guard.Status .. (Refs.Others and "" or " (data pemain belum ketemu: tekan 'Hubungkan ke game')"),
            "Pemain di world: " .. ((#here == 0) and "tidak ada" or names(here, 6)),
            "Staff online di server: " .. serverStaff(),
            "Terdeteksi: " .. Guard.Detected .. " kali",
        }, "\n")
        if txt ~= Guard.LastTxt then
            Guard.LastTxt = txt
            if UI.GuardStatus then pcall(function() UI.GuardStatus:SetDesc(txt) end) end
        end
    end

    -- Nyalakan / matikan Penjaga
    function Guard.set(on)
        Guard.On = on
        Guard.Token += 1
        Auto.stopWalk()
        Guard.Mode, Guard.Saved, Guard.CalmAt, Guard.BackText = "idle", nil, nil, nil
        table.clear(Guard.Alerted)
        table.clear(Guard.Allow)
        if on then
            -- pemain biasa yang sudah ada sekarang diabaikan (teman / akun sendiri)
            for _, p in ipairs(playersHere()) do
                if not p.role then Guard.Allow[p.id] = true end
            end
        end
    end

    -- dipakai fitur lain (Auto Reconnect)
    Guard.snapshot = snapshot
    Guard.stopAll = stopAll
    Guard.enterWorld = enterWorld
    Guard.leaveWorld = leaveWorld
    Guard.worldName = worldName
    Guard.pickerOpen = pickerOpen
    Guard.inWorld = inWorld
    Guard.anyRunning = anyRunning
    function Guard.afterEnter()
        Auto.resetReach()
        pcall(findDropRefs)
        pcall(Auto.findTreeRefs)
        table.clear(DropFailUntil)
    end
    function Guard.resumeSaved(saved)
        Guard.Saved = saved
        beginResume()
    end

    function Guard.allowNow()
        local n = 0
        for _, p in ipairs(playersHere()) do
            if not p.role then
                Guard.Allow[p.id] = true
                n += 1
            end
        end
        return n
    end

    -- ===== KEAMANAN TAMBAHAN: istirahat berkala & batas waktu jalan (jalan walau Penjaga mati) =====
    local function span(min) -- menit -> detik, diacak ±20% supaya polanya tidak selalu sama
        return math.max(30, (tonumber(min) or 1) * 60 * (0.8 + math.random() * 0.4))
    end
    local function dur(sec)
        sec = math.max(0, math.floor(sec or 0))
        if sec >= 3600 then return ("%dj %dm"):format(sec // 3600, (sec % 3600) // 60) end
        if sec >= 60 then return ("%dm %dd"):format(sec // 60, sec % 60) end
        return sec .. " dtk"
    end
    local lastAt, idleSec = os.clock(), 0

    function Guard.restTick()
        local now = os.clock()
        local dt = math.min(now - lastAt, 2)
        lastAt = now
        -- sedang istirahat
        if Guard.RestSaved then
            if Guard.Mode ~= "idle" then
                -- Penjaga mengambil alih (ada yang masuk world): aktivitas dilanjutkan oleh Penjaga
                Guard.Saved = Guard.RestSaved
                Guard.RestSaved = nil
            elseif anyRunning() then
                Guard.RestSaved = nil -- dijalankan manual saat istirahat: istirahat selesai
            elseif not Guard.RestOn or now >= (Guard.RestUntil or 0) then
                local saved = Guard.RestSaved
                Guard.RestSaved = nil
                notify("Keamanan", "Istirahat selesai, lanjut aktivitas", 4)
                Hook.send("penjaga", "Istirahat selesai, lanjut aktivitas")
                Guard.resumeSaved(saved)
            end
            return
        end
        if Guard.Mode ~= "idle" then return end
        if not anyRunning() then
            idleSec += dt
            if idleSec > 900 then Guard.ActiveSec, Guard.SinceRest, Guard.RestDue = 0, 0, nil end -- 15 menit diam: hitungan mulai lagi
            return
        end
        idleSec = 0
        Guard.ActiveSec += dt
        Guard.SinceRest += dt
        if Pabrik.Traveling or Vend.Running then return end -- jangan memotong perjalanan drop / vending
        -- batas waktu jalan
        if Guard.MaxOn and Guard.ActiveSec >= (tonumber(Guard.MaxHours) or 6) * 3600 then
            local txt = ("Batas waktu jalan %s jam tercapai, semua aktivitas dihentikan"):format(tostring(Guard.MaxHours))
            Guard.ActiveSec, Guard.SinceRest, Guard.RestDue = 0, 0, nil
            stopAll()
            notify("Keamanan", txt, 8)
            Hook.send("stop", txt)
            return
        end
        -- istirahat berkala
        if not Guard.RestOn then
            Guard.RestDue = nil
            return
        end
        Guard.RestDue = Guard.RestDue or span(Guard.RestEvery)
        if Guard.SinceRest >= Guard.RestDue then
            local rest = span(Guard.RestFor)
            Guard.RestSaved = snapshot()
            Guard.RestUntil = now + rest
            Guard.SinceRest, Guard.RestDue = 0, nil
            stopAll()
            notify("Keamanan", "Istirahat " .. dur(rest) .. ", nanti lanjut sendiri", 5)
            Hook.send("penjaga", "Istirahat " .. dur(rest) .. ", nanti lanjut sendiri")
        end
    end

    function Guard.safeText()
        local now = os.clock()
        local rest
        if Guard.RestSaved then
            rest = "SEDANG ISTIRAHAT, lanjut " .. dur((Guard.RestUntil or now) - now) .. " lagi"
        elseif not Guard.RestOn then
            rest = "mati"
        elseif Guard.RestDue then
            rest = "berikutnya ±" .. dur(Guard.RestDue - Guard.SinceRest) .. " lagi (waktu jalan)"
        else
            rest = "nyala, dihitung saat ada aktivitas"
        end
        return table.concat({
            "Jeda acak : " .. (Guard.JitOn and ("nyala, jeda +0 sampai " .. tostring(Guard.JitPct) .. "%") or "mati"),
            "Istirahat : " .. rest,
            "Waktu jalan: " .. dur(Guard.ActiveSec)
                .. (Guard.MaxOn and (" dari batas " .. tostring(Guard.MaxHours) .. " jam") or " (batas mati)"),
        }, "\n")
    end

    task.spawn(function()
        while alive() do
            local here = (Guard.Mode ~= "away" and Guard.Mode ~= "out") and playersHere() or {}
            local ok, err = pcall(Guard.tick, here)
            if not ok then warn("[SkyP] Penjaga error: " .. tostring(err)) end
            Guard.updateStatus(here)
            local okR, errR = pcall(Guard.restTick)
            if not okR then warn("[SkyP] Keamanan error: " .. tostring(errR)) end
            local okT, sTxt = pcall(Guard.safeText)
            if okT and sTxt ~= Guard.SafeShown and UI.SafeStatus then
                Guard.SafeShown = sTxt
                pcall(function() UI.SafeStatus:SetDesc(sTxt) end)
            end
            task.wait(0.5)
        end
    end)
end)() end

Config.add("Penjaga", Guard, { "On", "Who", "StopAll", "Leave", "AutoBack", "BackSec", "CalmSec",
    "JitOn", "JitPct", "RestOn", "RestEvery", "RestFor", "MaxOn", "MaxHours" }, { On = true })
Guard.JitOn, Guard.RestOn, Guard.MaxOn = Guard.JitOn == true, Guard.RestOn == true, Guard.MaxOn == true
Guard.JitPct = math.clamp(tonumber(Guard.JitPct) or 15, 5, 60)
Guard.RestEvery = math.clamp(tonumber(Guard.RestEvery) or 45, 10, 240)
Guard.RestFor = math.clamp(tonumber(Guard.RestFor) or 3, 1, 30)
Guard.MaxHours = math.clamp(tonumber(Guard.MaxHours) or 6, 1, 24)

-- ===== TAB: ADMIN (hanya dibuat untuk key yang ditandai admin di server) =====
do (function()
    local Lic = Session.Lic
    -- [Cracked] Admin check removed, always shown
    local ATab = makeTab("Admin", "shield", "setel")
    local canFile = type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
    if canFile then
        pcall(function()
            if isfile("SkyP_Admin.txt") then Lic.AdminKey = (string.gsub(readfile("SkyP_Admin.txt"), "%s+", "")) end
        end)
    end
    local target, annText, killMsg, minVer, genN = "", "", "", "", 1
    local confirm = {} -- aksi berbahaya: tekan 2x dalam 6 detik

    local function show(text)
        if UI.AdminOut then pcall(function() UI.AdminOut:SetDesc(text) end) end
    end
    local function ago(t)
        local sec = math.max(0, os.time() - math.floor((tonumber(t) or 0) / 1000))
        if sec < 90 then return sec .. " dtk lalu" end
        if sec < 5400 then return math.floor(sec / 60) .. " mnt lalu" end
        return math.floor(sec / 3600) .. " jam lalu"
    end
    -- jalankan aksi di task sendiri supaya menu tidak macet menunggu server
    local function run(label, path, params, fmt)
        task.spawn(function()
            show(label .. "...")
            local d, err = Lic.admin(path, params)
            if not d then
                show(label .. " GAGAL: " .. tostring(err))
                return
            end
            local ok, txt = pcall(fmt or function() return "berhasil" end, d)
            show(label .. ": " .. (ok and tostring(txt) or "berhasil"))
        end)
    end
    local function twice(id, label)
        local now = os.clock()
        if (confirm[id] or 0) > now then
            confirm[id] = nil
            return true
        end
        confirm[id] = now + 6
        notify("Admin", "Tekan sekali lagi untuk: " .. label, 5)
        return false
    end
    local function needKey()
        target = string.gsub(target, "%s+", "")
        if target == "" then
            show("Isi kolom 'Key buyer' dulu")
            return false
        end
        return true
    end
    local function cfgText(d)
        local c = type(d.cfg) == "table" and d.cfg or {}
        return table.concat({
            "",
            "Tombol darurat : " .. (c.kill and ("NYALA (" .. tostring(c.killMsg or "") .. ")") or "mati"),
            "Versi minimum  : " .. ((c.minVer and c.minVer ~= "") and tostring(c.minVer) or "tidak ada"),
            "Pengumuman     : " .. ((type(c.ann) == "table" and c.ann.text) and tostring(c.ann.text) or "tidak ada"),
            "Key admin      : " .. (type(c.admins) == "table" and #c.admins or 0),
        }, "\n")
    end

    safe(function()
        UI.AdminOut = ATab:Paragraph({ Title = "Hasil", Desc = "Isi Admin key, lalu pilih aksi. Tab ini hanya muncul di key admin" })
    end)
    safe(function()
        ATab:Input({
            Title = "Admin key",
            Desc = "ADMIN_KEY Worker. Disimpan hanya di perangkat ini (SkyP_Admin.txt), tidak ada di script",
            Value = Lic.AdminKey or "",
            Placeholder = "ADMIN_KEY",
            Callback = function(text)
                Lic.AdminKey = (string.gsub(tostring(text or ""), "%s+", ""))
                if canFile then pcall(writefile, "SkyP_Admin.txt", Lic.AdminKey) end
            end,
        })
    end)

    local aMon = box(ATab, "Pantau", true)
    local aKey = box(ATab, "Kelola key", true)
    local aAnn = box(ATab, "Pengumuman", false)
    local aKill = box(ATab, "Darurat & versi", false)

    safe(function()
        aMon:Button({
            Title = "Siapa yang online",
            Desc = "Key yang aktif dalam 21 menit terakhir",
            Callback = function()
                run("Online", "/adm", { act = "online" }, function(d)
                    local t = { (d.total or 0) .. " key aktif" }
                    for i, r in ipairs(d.rows or {}) do
                        if i > 25 then
                            t[#t + 1] = "... dan " .. (#d.rows - 25) .. " lagi"
                            break
                        end
                        t[#t + 1] = ("%s | akun %s | %s IP | v%s | %s"):format(tostring(r.key),
                            type(r.uids) == "table" and table.concat(r.uids, ",") or "-", tostring(r.ips or "?"),
                            tostring(r.ver or "?"), ago(r.t))
                    end
                    return table.concat(t, "\n")
                end)
            end,
        })
    end)
    safe(function()
        aMon:Button({
            Title = "Key yang dicurigai dibagi",
            Desc = "Key yang dicoba dari IP & akun lain saat masih dipakai (7 hari terakhir)",
            Callback = function()
                run("Dicurigai", "/adm", { act = "flags" }, function(d)
                    local t = { (d.total or 0) .. " key" }
                    for i, r in ipairs(d.rows or {}) do
                        if i > 25 then break end
                        t[#t + 1] = ("%s | dicoba akun %s | %s"):format(tostring(r.key), tostring(r.uid or "?"), ago(r.t))
                    end
                    return table.concat(t, "\n")
                end)
            end,
        })
    end)
    safe(function()
        aMon:Button({
            Title = "Lihat pengaturan server",
            Desc = "Tombol darurat, versi minimum, pengumuman",
            Callback = function() run("Pengaturan", "/adm", { act = "cfg" }, cfgText) end,
        })
    end)

    safe(function()
        aKey:Input({
            Title = "Key buyer",
            Desc = "Key yang mau dicek / reset / dicabut",
            Value = "",
            Placeholder = "SKYP-XXXXXXXXXXXXXXXX",
            Callback = function(text) target = tostring(text or "") end,
        })
    end)
    safe(function()
        aKey:Button({
            Title = "Info key",
            Desc = "Sudah terikat device atau belum, dan sesi aktifnya",
            Callback = function()
                if not needKey() then return end
                run("Info " .. target, "/adm", { act = "info", key = target }, function(d)
                    if type(d.data) ~= "table" then return "key tidak ada (atau trial sudah habis)" end
                    local s = type(d.ses) == "table" and d.ses or nil
                    local tr = ""
                    if d.data.trial then
                        local exp = tonumber(d.data.exp)
                        tr = exp and ("TRIAL, sisa " .. math.max(0, math.ceil((exp / 1000 - os.time()) / 60)) .. " menit | ")
                            or "TRIAL, belum dipakai | "
                    end
                    return tr .. (d.data.hwid and "terikat device" or "belum dipakai / sudah di-reset")
                        .. (s and ("\nSesi: akun " .. table.concat(s.uids or {}, ",") .. " | " .. #(s.ips or {}) .. " IP | v"
                            .. tostring(s.ver or "?") .. " | " .. ago(s.t)) or "\nSesi: tidak ada")
                end)
            end,
        })
    end)
    safe(function()
        aKey:Button({
            Title = "Reset key (lepas device)",
            Desc = "Sama seperti link reset: key bisa dipakai di device baru",
            Callback = function()
                if not needKey() then return end
                run("Reset " .. target, "/reset", { key = target })
            end,
        })
    end)
    safe(function()
        aKey:Button({
            Title = "Buka kunci sesi",
            Desc = "Kalau buyer tertolak 'sedang dipakai di tempat lain' padahal itu dia sendiri",
            Callback = function()
                if not needKey() then return end
                run("Buka kunci " .. target, "/adm", { act = "unlock", key = target })
            end,
        })
    end)
    safe(function()
        aKey:Button({
            Title = "Cabut key (hapus permanen)",
            Desc = "Tekan 2x. Script buyer berhenti paling lama 2 menit kemudian",
            Callback = function()
                if not needKey() or not twice("del", "cabut " .. target) then return end
                run("Cabut " .. target, "/adm", { act = "del", key = target })
            end,
        })
    end)
    addNumber(aKey, {
        Title = "Jumlah key baru",
        Min = 1, Max = 40, Step = 1, Default = 1,
        Callback = function(v) genN = math.floor(v) end,
    })
    safe(function()
        aKey:Button({
            Title = "Buat key baru",
            Desc = "Memakai rute /gen yang sudah ada. Hasilnya disalin ke clipboard",
            Callback = function()
                run("Buat key", "/gen", { count = genN, n = genN, jumlah = genN }, function(d)
                    local keys = {}
                    if type(d.keys) == "table" then
                        for _, k in ipairs(d.keys) do keys[#keys + 1] = tostring(type(k) == "table" and k.key or k) end
                    elseif d.key then
                        keys[1] = tostring(d.key)
                    end
                    local txt = table.concat(keys, "\n")
                    local clip = setclipboard or toclipboard
                    if clip and txt ~= "" then pcall(clip, txt) end
                    return #keys .. " key" .. ((clip and txt ~= "") and " (disalin)" or "") .. "\n" .. txt
                end)
            end,
        })
    end)

    safe(function()
        aKey:Button({
            Title = "Buat key trial (2 jam)",
            Desc = "Jumlah ikut slider di atas (maks 20). Waktu mulai dihitung saat pertama dipakai. Jeda 2 hari per device & akun",
            Callback = function()
                run("Buat key trial", "/adm", { act = "trial", n = math.min(genN, 20) }, function(d)
                    local keys = {}
                    for _, k in ipairs(type(d.keys) == "table" and d.keys or {}) do keys[#keys + 1] = tostring(k) end
                    local txt = table.concat(keys, "\n")
                    local clip = setclipboard or toclipboard
                    if clip and txt ~= "" then pcall(clip, txt) end
                    return #keys .. " key trial" .. ((clip and txt ~= "") and " (disalin)" or "") .. "\n" .. txt
                end)
            end,
        })
    end)

    safe(function()
        aAnn:Input({
            Title = "Isi pengumuman",
            Desc = "Maksimal 300 huruf. Muncul sebagai notifikasi di script semua buyer (paling lama 2 menit)",
            Value = "",
            Placeholder = "Contoh: update v1.8 sudah rilis, jalankan ulang loader",
            Callback = function(text) annText = tostring(text or "") end,
        })
    end)
    safe(function()
        aAnn:Button({
            Title = "Kirim pengumuman",
            Callback = function()
                if annText == "" then
                    show("Isi pengumuman dulu")
                    return
                end
                run("Pengumuman", "/adm", { act = "announce", text = annText }, function() return "terkirim" end)
            end,
        })
    end)
    safe(function()
        aAnn:Button({
            Title = "Hapus pengumuman",
            Callback = function()
                run("Pengumuman", "/adm", { act = "announce", text = "" }, function() return "dihapus" end)
            end,
        })
    end)

    safe(function()
        aKill:Input({
            Title = "Pesan tombol darurat",
            Desc = "Alasan yang dilihat buyer saat script dimatikan",
            Value = "",
            Placeholder = "Contoh: game baru update, tunggu versi baru",
            Callback = function(text) killMsg = tostring(text or "") end,
        })
    end)
    safe(function()
        aKill:Button({
            Title = "MATIKAN SkyP untuk semua buyer",
            Desc = "Tekan 2x. Script semua buyer berhenti paling lama 2 menit, dan tidak bisa dijalankan. Key admin tetap jalan",
            Callback = function()
                if not twice("kill", "matikan SkyP untuk semua") then return end
                run("Tombol darurat", "/adm", { act = "kill", on = 1, msg = killMsg }, function() return "NYALA, SkyP dimatikan untuk semua" end)
            end,
        })
    end)
    safe(function()
        aKill:Button({
            Title = "Nyalakan lagi",
            Callback = function()
                run("Tombol darurat", "/adm", { act = "kill", on = 0 }, function() return "mati, SkyP bisa dipakai lagi" end)
            end,
        })
    end)
    safe(function()
        aKill:Input({
            Title = "Versi minimum",
            Desc = "Contoh 1.7. Versi di bawahnya ditolak. Kosongkan = tidak ada batas",
            Value = "",
            Placeholder = Lic.Ver,
            Callback = function(text) minVer = (string.gsub(tostring(text or ""), "[^%d%.]", "")) end,
        })
    end)
    safe(function()
        aKill:Button({
            Title = "Simpan versi minimum",
            Desc = "Versi script ini: " .. Lic.Ver,
            Callback = function()
                run("Versi minimum", "/adm", { act = "minver", v = minVer }, function()
                    return minVer ~= "" and ("diset ke " .. minVer) or "dihapus"
                end)
            end,
        })
    end)
end)() end

-- ===== TAB: PENJAGA =====
do (function() -- fungsi sendiri: variabel di dalam tidak ikut batas 200 local
    local GuardTab = makeTab("Penjaga", "eye", "aman")

    safe(function()
        UI.GuardStatus = GuardTab:Paragraph({ Title = "Status Penjaga", Desc = "Mati" })
    end)

    local gCtl = box(GuardTab, "Kontrol", true)
    local gAct = box(GuardTab, "Aksi saat terdeteksi", true)
    local gTime = box(GuardTab, "Waktu", false)
    local gMore = box(GuardTab, "Lainnya", false)
    local gSafe = box(GuardTab, "Keamanan tambahan", true)

    safe(function()
        UI.SafeStatus = gSafe:Paragraph({ Title = "Status keamanan", Desc = "-" })
    end)

    safe(function()
        gSafe:Toggle({
            Title = "Jeda acak",
            Desc = "Tiap jeda aksi (pukul, pasang, panen, tanam) ditambah sedikit secara acak. Hanya menambah, jadi sedikit lebih lambat",
            Value = Guard.JitOn,
            Callback = function(on) Guard.JitOn = on end,
        })
    end)

    addNumber(gSafe, {
        Title = "Besar jeda acak (%)",
        Desc = "15 = jeda 200 ms jadi 200 sampai 230 ms. Berlaku juga untuk Break Cepat",
        Min = 5, Max = 60, Step = 5, Default = Guard.JitPct,
        Callback = function(v) Guard.JitPct = math.floor(v) end,
    })

    safe(function()
        gSafe:Toggle({
            Title = "Istirahat berkala",
            Desc = "Semua aktivitas dijeda sebentar tiap sekian menit, lalu lanjut sendiri (Vending tidak ikut)",
            Value = Guard.RestOn,
            Callback = function(on) Guard.RestOn = on end,
        })
    end)

    addNumber(gSafe, {
        Title = "Istirahat tiap (menit jalan)",
        Desc = "Diacak ±20% supaya tidak selalu sama",
        Min = 10, Max = 240, Step = 5, Default = Guard.RestEvery,
        Callback = function(v)
            Guard.RestEvery = math.floor(v)
            Guard.RestDue = nil
        end,
    })

    addNumber(gSafe, {
        Title = "Lama istirahat (menit)",
        Desc = "Diacak ±20%",
        Min = 1, Max = 30, Step = 1, Default = Guard.RestFor,
        Callback = function(v) Guard.RestFor = math.floor(v) end,
    })

    safe(function()
        gSafe:Toggle({
            Title = "Batas waktu jalan",
            Desc = "Semua aktivitas berhenti total setelah jalan sekian jam (ada notifikasi Discord)",
            Value = Guard.MaxOn,
            Callback = function(on) Guard.MaxOn = on end,
        })
    end)

    addNumber(gSafe, {
        Title = "Batas waktu jalan (jam)",
        Desc = "Dihitung hanya saat ada aktivitas. Diam 15 menit = hitungan mulai lagi",
        Min = 1, Max = 24, Step = 1, Default = Guard.MaxHours,
        Callback = function(v) Guard.MaxHours = math.floor(v) end,
    })

    safe(function()
        gSafe:Button({
            Title = "Akhiri istirahat / reset waktu jalan",
            Desc = "Sedang istirahat: langsung lanjut. Selain itu: hitungan waktu jalan kembali ke 0",
            Callback = function()
                if Guard.RestSaved then
                    Guard.RestUntil = 0
                    notify("Keamanan", "Istirahat diakhiri", 3)
                else
                    Guard.ActiveSec, Guard.SinceRest, Guard.RestDue = 0, 0, nil
                    notify("Keamanan", "Waktu jalan direset", 3)
                end
            end,
        })
    end)

    safe(function()
        UI.GuardToggle = gCtl:Toggle({
            Title = "Aktifkan Penjaga",
            Desc = "Pantau Mod / Dev / pemain yang masuk world",
            Value = false,
            Callback = function(on) Guard.set(on) end,
        })
    end)

    safe(function()
        gCtl:Dropdown({
            Title = "Yang dideteksi",
            Desc = "Semua pemain: yang sudah ada saat dinyalakan diabaikan",
            Values = { "Staff (Mod/Dev)", "Semua pemain" },
            Value = Guard.Who,
            Callback = function(opt) Guard.Who = opt end,
        })
    end)

    safe(function()
        gAct:Toggle({
            Title = "Diam semua aktivitas",
            Desc = "Stop Auto Farm, Clear, Farmer & Auto Chat",
            Value = Guard.StopAll,
            Callback = function(on) Guard.StopAll = on end,
        })
    end)

    safe(function()
        gAct:Toggle({
            Title = "Keluar world",
            Desc = "Langsung keluar world saat terdeteksi",
            Value = Guard.Leave,
            Callback = function(on) Guard.Leave = on end,
        })
    end)

    safe(function()
        gAct:Toggle({
            Title = "Lanjut otomatis setelah aman",
            Desc = "Keluar world: masuk lagi, cek, lalu lanjut aktivitas sebelumnya",
            Value = Guard.AutoBack,
            Callback = function(on) Guard.AutoBack = on end,
        })
    end)

    addNumber(gTime, {
        Title = "Masuk world lagi setelah (detik)",
        Desc = "Untuk mode keluar world",
        Min = 20, Max = 600, Step = 5, Default = Guard.BackSec,
        Callback = function(v) Guard.BackSec = math.floor(v) end,
    })

    addNumber(gTime, {
        Title = "Tunggu aman (detik)",
        Desc = "Untuk mode diam: jeda setelah mereka pergi",
        Min = 2, Max = 60, Step = 1, Default = Guard.CalmSec,
        Callback = function(v) Guard.CalmSec = math.floor(v) end,
    })

    safe(function()
        gMore:Button({
            Title = "Abaikan pemain yang ada sekarang",
            Desc = "Untuk teman / akun sendiri (staff tetap dideteksi)",
            Callback = function()
                notify("Penjaga", Guard.allowNow() .. " pemain diabaikan", 3)
            end,
        })
    end)

    safe(function()
        gMore:Button({
            Title = "Batalkan tunggu / lanjut",
            Desc = "Hentikan proses keluar-masuk & lanjut otomatis",
            Callback = function()
                Guard.set(Guard.On)
                notify("Penjaga", "Dibatalkan", 3)
            end,
        })
    end)
end)() end

---------------------------------------------------------------------
-- BONUS: auto klaim quest & auto redeem code
---------------------------------------------------------------------
-- Pakai panggilan yang sama dengan menu Quest & Redeem game:
--   Net.call("Quests", "list")            -> daftar quest hari ini
--   Net.call("Quests", "claim", id)       -> klaim hadiah (server yang cek syaratnya)
--   Net.call("ActiveCodes")               -> daftar code aktif
--   Net.call("ModCommand", "redeemcode", code) -> tukar code (dipakai menu Redeem game)
local Bonus = {
    Quest = false,
    Redeem = false,
    QuestEvery = 30,   -- cek quest tiap 30 detik
    CodeEvery = 300,   -- cek code tiap 5 menit
    NextQuest = 0,
    NextCode = 0,
    Claimed = 0,
    Redeemed = 0,
    Tried = {},        -- code yang sudah dicoba
    QuestFail = {},    -- quest yang ditolak server (dicoba lagi nanti)
    QuestText = "-",
    CodeText = "-",
    ResetAt = nil,
}

do (function() -- fungsi sendiri: variabel di dalam tidak ikut batas 200 local
    local function strip(s) return (tostring(s or ""):gsub("`.", "")) end

    local function netCall(...)
        if NetOk and type(Net) == "table" and type(Net.call) == "function" then
            return pcall(Net.call, ...)
        end
        return false, "Net.call tidak ada"
    end

    local function timeText(sec)
        sec = math.max(0, math.floor(sec or 0))
        if sec >= 3600 then return ("%dj %dm"):format(sec // 3600, sec % 3600 // 60) end
        return ("%dm %dd"):format(sec // 60, sec % 60)
    end

    local function setGems(n)
        local g = Refs.Gems
        if type(n) == "number" and g and type(rawget(g, "setGems")) == "function" then
            pcall(g.setGems, n)
        end
    end

    function Bonus.checkQuests()
        if Bonus.BusyQ then return end
        Bonus.BusyQ = true
        local ok, good, data = netCall("Quests", "list")
        if not ok then
            Bonus.QuestText = "Gagal ambil quest: " .. strip(good)
        elseif not good or type(data) ~= "table" or type(data.quests) ~= "table" then
            Bonus.QuestText = "Quest belum bisa diambil" .. (type(data) == "string" and (": " .. strip(data)) or "")
        else
            local total, done, wait = 0, 0, 0
            local now = os.clock()
            for _, q in ipairs(data.quests) do
                total += 1
                local have, need = tonumber(q.have) or 0, tonumber(q.need) or math.huge
                if q.claimed then
                    done += 1
                elseif have >= need and not ((Bonus.QuestFail[q.id] or 0) > now) then
                    -- syarat sama seperti tombol Claim game
                    local okc, success, msg, _, gems = netCall("Quests", "claim", q.id)
                    if okc and success then
                        done += 1
                        Bonus.Claimed += 1
                        local reward = q.xp and (tostring(q.reward) .. " XP") or (tostring(q.reward) .. " gems")
                        notify("Quest diklaim", strip(q.text or q.id) .. "  +" .. reward, 4)
                        Hook.send("bonus", "Quest diklaim: " .. strip(q.text or q.id) .. " +" .. reward)
                        setGems(gems)
                    else
                        wait += 1
                        Bonus.QuestFail[q.id] = now + 120
                        if okc and msg then Bonus.LastQuestMsg = strip(msg) end
                    end
                    task.wait(0.6)
                elseif have >= need then
                    wait += 1
                end
            end
            Bonus.ResetAt = os.clock() + (tonumber(data.resetIn) or 0)
            Bonus.QuestText = ("Selesai %d/%d | diklaim script: %d"):format(done, total, Bonus.Claimed)
                .. ((wait > 0) and (" | ditolak: " .. wait) or "")
        end
        Bonus.BusyQ = false
    end

    -- Tukar 1 code. Berhasil kalau balasan server diawali warna hijau (`2)
    function Bonus.redeem(code)
        local ok, res = netCall("ModCommand", "redeemcode", code)
        if not ok then return nil, "tidak bisa ke server" end
        local lines = type(res) == "table" and type(res.lines) == "table" and res.lines or nil
        if not lines then return false, "balasan kosong" end
        local first = tostring(lines[1] or "")
        local parts = {}
        for _, l in ipairs(lines) do parts[#parts + 1] = strip(l) end
        return string.sub(first, 1, 2) == "`2", table.concat(parts, " ")
    end

    function Bonus.checkCodes()
        if Bonus.BusyR then return end
        Bonus.BusyR = true
        local ok, list = netCall("ActiveCodes")
        if not ok or type(list) ~= "table" then
            Bonus.CodeText = "Gagal ambil daftar code"
        elseif list.note ~= nil then
            Bonus.CodeText = "Redeem sedang ditutup: " .. strip(list.note)
        else
            local total, have, newOk = 0, 0, 0
            for _, c in ipairs(list) do
                total += 1
                local code = c.code and tostring(c.code)
                if c.done then
                    have += 1
                elseif code and not Bonus.Tried[code] and not (type(c.uses) == "number" and c.uses == 0) then
                    local success, msg = Bonus.redeem(code)
                    if success ~= nil then Bonus.Tried[code] = true end -- server sudah jawab
                    if success then
                        have += 1
                        newOk += 1
                        Bonus.Redeemed += 1
                        notify("Redeem berhasil", code .. ": " .. tostring(msg), 5)
                        Hook.send("bonus", "Redeem berhasil " .. code .. ": " .. tostring(msg))
                    elseif success == false then
                        Bonus.LastCodeMsg = code .. ": " .. tostring(msg)
                    end
                    task.wait(1)
                end
            end
            Bonus.CodeText = ("Code aktif: %d | sudah ditukar: %d | ditukar script: %d"):format(total, have, Bonus.Redeemed)
        end
        Bonus.BusyR = false
    end

    function Bonus.updateStatus()
        local now = os.clock()
        local q = Bonus.QuestText
        if Bonus.ResetAt then q = q .. "\nQuest baru dalam " .. timeText(Bonus.ResetAt - now) end
        if Bonus.LastQuestMsg then q = q .. "\nPesan terakhir: " .. Bonus.LastQuestMsg end
        q = q .. "\n" .. (Bonus.Quest and ("Cek lagi dalam " .. math.max(0, math.ceil(Bonus.NextQuest - now)) .. " detik") or "Auto klaim mati")
        local c = Bonus.CodeText
        if Bonus.LastCodeMsg then c = c .. "\nPesan terakhir: " .. Bonus.LastCodeMsg end
        c = c .. "\n" .. (Bonus.Redeem and ("Cek lagi dalam " .. timeText(Bonus.NextCode - now)) or "Auto redeem mati")
        if UI.QuestStatus then pcall(function() UI.QuestStatus:SetDesc(q) end) end
        if UI.CodeStatus then pcall(function() UI.CodeStatus:SetDesc(c) end) end
    end

    task.spawn(function()
        while alive() do
            local now = os.clock()
            if Bonus.Quest and now >= Bonus.NextQuest then
                Bonus.NextQuest = now + Bonus.QuestEvery
                pcall(Bonus.checkQuests)
            end
            if Bonus.Redeem and now >= Bonus.NextCode then
                Bonus.NextCode = now + Bonus.CodeEvery
                pcall(Bonus.checkCodes)
            end
            Bonus.updateStatus()
            task.wait(1)
        end
    end)
end)() end

Config.add("Bonus", Bonus, { "Quest", "Redeem" })

-- ===== TAB: BONUS =====
do (function() -- fungsi sendiri: variabel di dalam tidak ikut batas 200 local
    local BonusTab = makeTab("Bonus", "gift", "fitur")
    local bQuest = box(BonusTab, "Quest Harian", true)
    local bCode = box(BonusTab, "Redeem Code", true)

    safe(function()
        UI.QuestStatus = bQuest:Paragraph({ Title = "Status", Desc = "-" })
    end)

    safe(function()
        bQuest:Toggle({
            Title = "Auto Claim Quest",
            Desc = "Klaim hadiah quest yang sudah selesai",
            Value = Bonus.Quest,
            Callback = function(on)
                Bonus.Quest = on
                if on then Bonus.NextQuest = 0 end
            end,
        })
    end)

    safe(function()
        bQuest:Button({
            Title = "Cek quest sekarang",
            Callback = function() task.spawn(Bonus.checkQuests) end,
        })
    end)

    safe(function()
        UI.CodeStatus = bCode:Paragraph({ Title = "Status", Desc = "-" })
    end)

    safe(function()
        bCode:Toggle({
            Title = "Auto Redeem Code",
            Desc = "Tukar semua code aktif yang belum dipakai",
            Value = Bonus.Redeem,
            Callback = function(on)
                Bonus.Redeem = on
                if on then Bonus.NextCode = 0 end
            end,
        })
    end)

    safe(function()
        bCode:Button({
            Title = "Cek code sekarang",
            Callback = function()
                table.clear(Bonus.Tried)
                task.spawn(Bonus.checkCodes)
            end,
        })
    end)

    safe(function()
        bCode:Input({
            Title = "Redeem code manual",
            Desc = "Ketik code lalu tekan Enter",
            Value = "",
            Placeholder = "KODE",
            Callback = function(text)
                local code = tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "")
                if code == "" then return end
                task.spawn(function()
                    local success, msg = Bonus.redeem(code)
                    if success then Bonus.Redeemed += 1 end
                    notify(success and "Redeem berhasil" or "Redeem gagal", code .. ": " .. tostring(msg), 5)
                end)
            end,
        })
    end)
end)() end

---------------------------------------------------------------------
-- GROWSCAN: Floating Items & World Blocks (seperti Growscan 9000 di Growtopia)
---------------------------------------------------------------------
-- Cara kerja:
--   - Floating Items: daftar drop di world (data drop game), dijumlah per item.
--   - World Blocks: semua tile world dihitung per item (block depan + background).
--     Seed yang tertanam di block depan = pohon.
--   - Auto Scan: diulang tiap 2 detik. Hasil diurutkan dari jumlah terbanyak.
local Scan = {
    Auto = false,
    Layer = "Semua",      -- "Semua" | "Depan" | "Background"
    Filter = "",          -- cari nama item
    Every = 2,
    Limit = 60,           -- maksimal baris per daftar
    Last = nil,
}

do (function() -- fungsi sendiri: variabel di dalam tidak ikut batas 200 local
    local function fmtNum(n)
        local str = tostring(math.floor(n))
        local out = str:reverse():gsub("(%d%d%d)", "%1."):reverse()
        return (out:gsub("^%.", ""))
    end

    local function blockName(id)
        local it = ItemDB[id]
        local nm = itemName(id)
        if it and it.kind == "seed" then nm = nm .. " (pohon)" end
        return nm
    end

    -- Ubah hitungan {id = jumlah} jadi teks, urut dari terbanyak
    local function listText(counts, nameFn)
        local list = {}
        for id, n in pairs(counts) do list[#list + 1] = { id = id, n = n } end
        table.sort(list, function(a, b)
            if a.n ~= b.n then return a.n > b.n end
            return a.id < b.id
        end)
        local filter = string.lower(Scan.Filter or "")
        local lines, total = {}, 0
        for _, e in ipairs(list) do
            local name = nameFn(e.id)
            if filter == "" or string.find(string.lower(name), filter, 1, true) then
                total += 1
                if total <= Scan.Limit then
                    lines[#lines + 1] = name .. "  x" .. fmtNum(e.n)
                end
            end
        end
        if total > Scan.Limit then lines[#lines + 1] = ("... +%d item lain (pakai Cari item)"):format(total - Scan.Limit) end
        if #lines == 0 then lines[1] = (filter ~= "") and "Tidak ada yang cocok" or "Kosong" end
        return table.concat(lines, "\n"), total
    end

    local function scanFloating()
        local counts, total, piles = {}, 0, 0
        local list = Drops.list
        if type(list) ~= "table" then return nil end
        for _, d in pairs(list) do
            if type(d) == "table" and type(d.id) == "number" then
                local n = tonumber(d.n) or 1
                if n > 0 then
                    counts[d.id] = (counts[d.id] or 0) + n
                    total += n
                    piles += 1
                end
            end
        end
        return counts, total, piles
    end

    local function scanBlocks()
        local w = Refs.World
        if not w or type(w.fg) ~= "table" or type(w.w) ~= "number" then return nil end
        local fgC, bgC, nf, nb = {}, {}, 0, 0
        local trees = {} -- [seed] = { r = siap, g = tumbuh, nxt = detik ke panen berikutnya }
        local st = workspace:GetServerTimeNow()
        local readyAt = Auto.treeReadyAt
        for y = 0, w.h - 1 do
            local rf = w.fg[y]
            local rb = w.bg and w.bg[y]
            for x = 0, w.w - 1 do
                local a = rf and rf[x] or 0
                if a ~= 0 then
                    fgC[a] = (fgC[a] or 0) + 1
                    nf += 1
                    local it = ItemDB[a]
                    if readyAt and it and it.kind == "seed" then
                        local ra = readyAt(x, y, a)
                        if ra then
                            local e = trees[a]
                            if not e then
                                e = { r = 0, g = 0 }
                                trees[a] = e
                            end
                            if st >= ra then
                                e.r += 1
                            else
                                e.g += 1
                                if not e.nxt or ra - st < e.nxt then e.nxt = ra - st end
                            end
                        end
                    end
                end
                local b = rb and rb[x] or 0
                if b ~= 0 then
                    bgC[b] = (bgC[b] or 0) + 1
                    nb += 1
                end
            end
            if y % 64 == 63 then task.wait() end -- world besar: jangan bikin lag
        end
        return fgC, bgC, nf, nb, trees
    end

    local function waitText(sec)
        sec = math.max(0, math.floor(sec or 0))
        if sec >= 3600 then return ("%dj %dm"):format(sec // 3600, sec % 3600 // 60) end
        return ("%dm %dd"):format(sec // 60, sec % 60)
    end

    -- Daftar pohon: siap panen dulu, lalu yang paling cepat siap
    local function treeText(trees)
        local list, totalR, totalG = {}, 0, 0
        local filter = string.lower(Scan.Filter or "")
        for id, e in pairs(trees) do
            totalR += e.r
            totalG += e.g
            local name = itemName(id)
            if filter == "" or string.find(string.lower(name), filter, 1, true) then
                list[#list + 1] = { name = name, e = e }
            end
        end
        table.sort(list, function(a, b)
            if a.e.r ~= b.e.r then return a.e.r > b.e.r end
            return (a.e.nxt or math.huge) < (b.e.nxt or math.huge)
        end)
        local lines = {}
        for i, v in ipairs(list) do
            if i > Scan.Limit then
                lines[#lines + 1] = ("... +%d jenis lain"):format(#list - Scan.Limit)
                break
            end
            local line = ("%s: %d siap | %d tumbuh"):format(v.name, v.e.r, v.e.g)
            if v.e.nxt then line = line .. " (berikut " .. waitText(v.e.nxt) .. ")" end
            lines[#lines + 1] = line
        end
        if #lines == 0 then lines[1] = (filter ~= "") and "Tidak ada yang cocok" or "Tidak ada pohon" end
        return table.concat(lines, "\n"), totalR, totalG
    end

    local function setDesc(el, txt, key)
        if Scan[key] == txt then return end
        Scan[key] = txt
        if el then pcall(function() el:SetDesc(txt) end) end
    end

    function Scan.run()
        if Scan.Busy then return end
        Scan.Busy = true
        local w = Refs.World
        local fl, flTotal, piles = scanFloating()
        local fgC, bgC, nf, nb, trees = scanBlocks()
        local treeTxt, treeR, treeG = "Data pohon belum ketemu", nil, nil
        if trees then treeTxt, treeR, treeG = treeText(trees) end

        local floatText = fl and select(1, listText(fl, itemName)) or "Data drop belum ketemu. Tekan 'Hubungkan ke game'"
        local blockText = "Data world belum ketemu. Tekan 'Hubungkan ke game'"
        if fgC then
            local pick
            if Scan.Layer == "Depan" then
                pick = fgC
            elseif Scan.Layer == "Background" then
                pick = bgC
            else
                pick = {}
                for id, n in pairs(fgC) do pick[id] = (pick[id] or 0) + n end
                for id, n in pairs(bgC) do pick[id] = (pick[id] or 0) + n end
            end
            blockText = select(1, listText(pick, blockName))
        end

        local name = w and rawget(w, "name")
        local info = table.concat({
            "World: " .. ((type(name) == "string" and name ~= "") and name or "-")
                .. (w and type(w.w) == "number" and (" (" .. w.w .. "x" .. w.h .. ")") or ""),
            "Block depan: " .. (nf and fmtNum(nf) or "-") .. " | Background: " .. (nb and fmtNum(nb) or "-"),
            "Floating: " .. (flTotal and (fmtNum(flTotal) .. " item (" .. piles .. " tumpukan)") or "-"),
            "Pohon: " .. (treeR and (fmtNum(treeR) .. " siap panen | " .. fmtNum(treeG) .. " tumbuh") or "-"),
            "Scan terakhir: " .. os.date("%H:%M:%S"),
        }, "\n")

        setDesc(UI.ScanInfo, info, "_info")
        setDesc(UI.ScanFloat, floatText, "_float")
        setDesc(UI.ScanBlocks, blockText, "_blocks")
        setDesc(UI.ScanTrees, treeTxt, "_trees")
        Scan.Busy = false
    end

    task.spawn(function()
        local last = 0
        while alive() do
            if Scan.Auto and os.clock() - last >= Scan.Every then
                last = os.clock()
                pcall(Scan.run)
            end
            task.wait(0.5)
        end
    end)
end)() end

Config.add("Growscan", Scan, { "Auto", "Layer" })

-- ===== TAB: GROWSCAN =====
do (function() -- fungsi sendiri: variabel di dalam tidak ikut batas 200 local
    local ScanTab = makeTab("Growscan", "scan-search", "fitur")

    safe(function()
        UI.ScanInfo = ScanTab:Paragraph({ Title = "Info World", Desc = "Tekan Scan sekarang" })
    end)

    local sCtl = box(ScanTab, "Kontrol", true)
    local sFloat = box(ScanTab, "Floating Items", true)
    local sBlock = box(ScanTab, "World Blocks", false)
    local sTree = box(ScanTab, "Pohon (siap panen)", true)

    safe(function()
        sCtl:Toggle({
            Title = "Auto Scan",
            Desc = "Update otomatis tiap 2 detik",
            Value = Scan.Auto,
            Callback = function(on)
                Scan.Auto = on
                if on then task.spawn(Scan.run) end
            end,
        })
    end)

    safe(function()
        sCtl:Button({
            Title = "Scan sekarang",
            Callback = function() task.spawn(Scan.run) end,
        })
    end)

    safe(function()
        sCtl:Input({
            Title = "Cari item",
            Desc = "Saring nama item (kosongkan = semua)",
            Value = "",
            Placeholder = "contoh: seed",
            Callback = function(text)
                Scan.Filter = tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "")
                task.spawn(Scan.run)
            end,
        })
    end)

    safe(function()
        UI.ScanFloat = sFloat:Paragraph({ Title = "Daftar", Desc = "-" })
    end)

    safe(function()
        sBlock:Dropdown({
            Title = "Layer",
            Values = { "Semua", "Depan", "Background" },
            Value = Scan.Layer,
            Callback = function(opt)
                Scan.Layer = opt
                task.spawn(Scan.run)
            end,
        })
    end)

    safe(function()
        UI.ScanBlocks = sBlock:Paragraph({ Title = "Daftar", Desc = "-" })
    end)

    safe(function()
        UI.ScanTrees = sTree:Paragraph({ Title = "Daftar", Desc = "-" })
    end)
end)() end

---------------------------------------------------------------------
-- STATISTIK SESI
---------------------------------------------------------------------
-- Cara kerja:
--   - Saat execute (atau tombol Reset), angka awal dicatat.
--   - Tiap detik: angka sekarang - angka awal = hasil sesi. Dibagi lama sesi = per jam.
--   - Gems dibaca dari angka gems di HUD game (nilai di dalam fungsi addGems).
do (function()
    local function gemsNow()
        local g = Refs.Gems
        local f = g and rawget(g, "addGems")
        if type(f) ~= "function" then return nil end
        for _, v in pairs(getUpvalues(f)) do
            if type(v) == "number" then return v end
        end
        return nil
    end
    Stats.gemsNow = gemsNow

    local function fmt(n)
        local str = tostring(math.floor(n or 0))
        local neg = string.sub(str, 1, 1) == "-"
        if neg then str = string.sub(str, 2) end
        local out = str:reverse():gsub("(%d%d%d)", "%1."):reverse()
        out = out:gsub("^%.", "")
        return (neg and "-" or "") .. out
    end

    local function dur(sec)
        sec = math.max(0, math.floor(sec))
        return ("%dj %dm %dd"):format(sec // 3600, sec % 3600 // 60, sec % 60)
    end

    -- angka yang dihitung (semuanya naik terus selama script jalan)
    local function counters()
        return {
            broken = State.Broken, placed = State.Placed, collected = State.Collected,
            harvested = Farmer.Harvested, planted = Farmer.Planted,
        }
    end

    function Stats.reset()
        Stats.T0 = os.clock()
        Stats.Gems0 = gemsNow()
        Stats.Items = {}
        Stats.Base = counters()
    end
    Stats.Base = counters()

    function Stats.text()
        local hours = math.max((os.clock() - Stats.T0) / 3600, 1 / 3600)
        local now, base = counters(), Stats.Base
        local function line(label, key)
            local v = now[key] - (base[key] or 0)
            return ("%s: %s  (%s/jam)"):format(label, fmt(v), fmt(v / hours))
        end
        local g = gemsNow()
        if g and not Stats.Gems0 then Stats.Gems0 = g end
        local gemLine = "Gems: -"
        if g and Stats.Gems0 then
            local d = g - Stats.Gems0
            gemLine = ("Gems: %s  (%s%s, %s/jam)"):format(fmt(g), d >= 0 and "+" or "", fmt(d), fmt(d / hours))
        end
        -- 5 item terbanyak yang terkumpul
        local top = {}
        for id, n in pairs(Stats.Items) do top[#top + 1] = { id = id, n = n } end
        table.sort(top, function(a, b) return a.n > b.n end)
        local tops = {}
        for i = 1, math.min(5, #top) do tops[i] = itemName(top[i].id) .. " x" .. fmt(top[i].n) end
        return table.concat({
            "Lama sesi: " .. dur(os.clock() - Stats.T0),
            gemLine,
            line("Block pecah", "broken"),
            line("Block di-place", "placed"),
            line("Drop diambil", "collected"),
            line("Panen", "harvested"),
            line("Tanam", "planted"),
            "Item terbanyak: " .. ((#tops > 0) and table.concat(tops, ", ") or "-"),
        }, "\n")
    end

    task.spawn(function()
        local lastReport = os.clock()
        while alive() do
            local ok, txt = pcall(Stats.text)
            if ok and UI.StatsText and txt ~= Stats.Shown then
                Stats.Shown = txt
                pcall(function() UI.StatsText:SetDesc(txt) end)
            end
            -- laporan berkala ke Discord
            if Hook.ReportMin > 0 and os.clock() - lastReport >= Hook.ReportMin * 60 then
                lastReport = os.clock()
                if ok then Hook.send("report", "Laporan statistik\n```\n" .. txt .. "\n```") end
            elseif Hook.ReportMin <= 0 then
                lastReport = os.clock()
            end
            task.wait(1)
        end
    end)
end)() end

-- ===== TAB: STATISTIK =====
do (function()
    local StatTab = makeTab("Statistik", "bar-chart-3", "fitur")

    safe(function()
        UI.StatsText = StatTab:Paragraph({ Title = "Sesi ini", Desc = "-" })
    end)

    safe(function()
        StatTab:Button({
            Title = "Reset statistik",
            Desc = "Mulai hitung dari nol",
            Callback = function()
                Stats.reset()
                notify("Statistik", "Direset", 2)
            end,
        })
    end)

    safe(function()
        StatTab:Button({
            Title = "Kirim ke Discord sekarang",
            Desc = "Perlu webhook di tab Discord",
            Callback = function()
                local ok, txt = pcall(Stats.text)
                if not (Hook.On and Hook.valid(Hook.Url)) then
                    notify("Statistik", "Aktifkan webhook Discord dulu", 3)
                elseif ok then
                    Hook.send("report", "Laporan statistik\n```\n" .. txt .. "\n```")
                    notify("Statistik", "Masuk antrian kirim", 2)
                end
            end,
        })
    end)
end)() end

---------------------------------------------------------------------
-- TAS: auto recycle item sampah & auto convert lock
---------------------------------------------------------------------
-- Cara kerja (sama seperti tombol di inventori game):
--   Recycle : hapus dari inventori lalu World.call("Recycle", id, jumlah)
--   Convert : 100 World Lock -> 1 Diamond Lock, 100 Diamond Lock -> 1 Blue Gem Lock
--             lewat World.call("ConvertLock", dari, ke)
-- Tool & lock tidak bisa dipilih untuk recycle (supaya tidak terbuang tidak sengaja).
local Bag = {
    TrashOn = false,
    TrashList = {},    -- daftar id item yang di-recycle
    TrashAt = 150,     -- recycle kalau jumlahnya sudah segini
    Keep = 0,          -- sisakan sebanyak ini
    LockOn = false,
    Recycled = 0,
    Converted = 0,
    Status = "-",
}

do (function()
    local LOCK_IDS = { [242] = true, [1796] = true, [7188] = true }
    local LOCK_STEPS = {
        { from = 242, to = 1796, name = "Diamond Lock" },
        { from = 1796, to = 7188, name = "Blue Gem Lock" },
    }

    local function worldCall(...)
        local w = Refs.World
        local f = w and rawget(w, "call")
        if type(f) ~= "function" then return false end
        return pcall(f, ...)
    end

    local function trashable(id)
        local it = ItemDB[id]
        return it ~= nil and it.kind ~= "tool" and not LOCK_IDS[id]
    end

    function Bag.recycle(id, n)
        if not Refs.Inv or n <= 0 or not trashable(id) then return false end
        n = math.min(n, invCount(id))
        if n <= 0 then return false end
        pcall(function() Refs.Inv:remove(id, n) end)
        local ok = worldCall("Recycle", id, n)
        if ok then
            Bag.Recycled += n
            Bag.Status = ("Recycle %s x%d"):format(itemName(id), n)
        end
        return ok
    end

    -- sama seperti cek tombol convert di game (muat atau tidak)
    local function convertLock(step)
        local inv = Refs.Inv
        if not inv or invCount(step.from) < 100 then return false end
        local okU, used = pcall(function() return inv:used() end)
        local okC, cap = pcall(function() return inv.capacity end)
        if invCount(step.to) + 1 > 200 then return false end
        if invCount(step.to) == 0 and invCount(step.from) ~= 100 and okU and okC
            and type(used) == "number" and type(cap) == "number" and used >= cap then
            return false
        end
        pcall(function()
            inv:remove(step.from, 100)
            inv:add(step.to, 1)
        end)
        local ok = worldCall("ConvertLock", step.from, step.to)
        if ok then
            Bag.Converted += 1
            Bag.Status = "Convert ke " .. step.name
        end
        return ok
    end

    function Bag.tick()
        if Bag.TrashOn then
            for _, id in ipairs(Bag.TrashList) do
                local n = invCount(id)
                if n >= Bag.TrashAt and n > Bag.Keep then
                    Bag.recycle(id, n - Bag.Keep)
                    task.wait(0.5)
                end
            end
        end
        if Bag.LockOn then
            for _, step in ipairs(LOCK_STEPS) do
                if convertLock(step) then task.wait(0.5) end
            end
        end
    end

    -- label dropdown: item di inventori yang boleh di-recycle
    function Bag.labels()
        local out, seen = {}, {}
        if Refs.Inv then
            for _, slot in ipairs(Refs.Inv.slots) do
                local id = slot.id
                if id and not seen[id] and (slot.n or 0) > 0 and trashable(id) then
                    seen[id] = true
                    out[#out + 1] = { id = id, label = ("%s [%d]"):format(itemName(id), id) }
                end
            end
        end
        -- item yang sudah dipilih tetap tampil walau sedang habis
        for _, id in ipairs(Bag.TrashList) do
            if not seen[id] then
                seen[id] = true
                out[#out + 1] = { id = id, label = ("%s [%d]"):format(itemName(id), id) }
            end
        end
        table.sort(out, function(a, b) return a.id < b.id end)
        local labels, picked = {}, {}
        for _, e in ipairs(out) do
            labels[#labels + 1] = e.label
            if table.find(Bag.TrashList, e.id) then picked[#picked + 1] = e.label end
        end
        return labels, picked
    end

    task.spawn(function()
        while alive() do
            pcall(Bag.tick)
            if UI.BagStatus then
                local txt = ("Status: %s\nDi-recycle: %d item | Convert lock: %d kali\nItem dipilih: %d"):format(
                    Bag.Status, Bag.Recycled, Bag.Converted, #Bag.TrashList)
                if txt ~= Bag.Shown then
                    Bag.Shown = txt
                    pcall(function() UI.BagStatus:SetDesc(txt) end)
                end
            end
            task.wait(3)
        end
    end)
end)() end

Config.add("Tas", Bag, { "TrashOn", "TrashList", "TrashAt", "Keep", "LockOn" })

-- ===== TAB: TAS =====
do (function()
    local BagTab = makeTab("Tas", "backpack", "fitur")

    safe(function()
        UI.BagStatus = BagTab:Paragraph({ Title = "Status", Desc = "-" })
    end)

    local bTrash = box(BagTab, "Auto Recycle (buang item)", true)
    local bLock = box(BagTab, "Auto Convert Lock", false)

    safe(function()
        bTrash:Toggle({
            Title = "Auto Recycle",
            Desc = "Item yang dipilih di-recycle otomatis",
            Value = Bag.TrashOn,
            Callback = function(on) Bag.TrashOn = on end,
        })
    end)

    safe(function()
        local labels, picked = Bag.labels()
        UI.TrashDropdown = bTrash:Dropdown({
            Title = "Item yang di-recycle",
            Desc = "Bisa pilih banyak. Tool & lock tidak ditampilkan",
            Values = (#labels > 0) and labels or { "(inventori belum terbaca)" },
            Value = picked,
            Multi = true,
            AllowNone = true,
            Callback = function(opts)
                local list = {}
                for _, label in ipairs(type(opts) == "table" and opts or { opts }) do
                    local id = tonumber(string.match(tostring(label), "%[(%d+)%]$"))
                    if id then list[#list + 1] = id end
                end
                Bag.TrashList = list
            end,
        })
    end)

    -- dipanggil saat inventori berubah
    local lastSig = nil
    UI.TrashRefresh = function(force)
        local labels, picked = Bag.labels()
        local sig = table.concat(labels, "|")
        if not force and sig == lastSig then return end
        lastSig = sig
        if not UI.TrashDropdown then return end
        UI.exec(function() UI.TrashDropdown:Refresh((#labels > 0) and labels or { "(inventori kosong)" }) end)
        if #picked > 0 then UI.exec(function() UI.TrashDropdown:Select(picked) end) end
    end

    addNumber(bTrash, {
        Title = "Recycle kalau jumlah >=",
        Desc = "200 = hanya saat penuh 1 slot",
        Min = 1, Max = 200, Step = 1, Default = Bag.TrashAt,
        Callback = function(v) Bag.TrashAt = math.floor(v) end,
    })

    addNumber(bTrash, {
        Title = "Sisakan",
        Desc = "Jumlah yang tidak ikut di-recycle",
        Min = 0, Max = 199, Step = 1, Default = Bag.Keep,
        Callback = function(v) Bag.Keep = math.floor(v) end,
    })

    safe(function()
        bTrash:Button({
            Title = "Refresh daftar item",
            Callback = function() UI.later("trash", function() UI.TrashRefresh(true) end) end,
        })
    end)

    safe(function()
        bLock:Toggle({
            Title = "Auto Convert Lock",
            Desc = "100 WL -> 1 DL, 100 DL -> 1 BGL (sama seperti game)",
            Value = Bag.LockOn,
            Callback = function(on) Bag.LockOn = on end,
        })
    end)
end)() end

---------------------------------------------------------------------
-- AUTO SPLICE
---------------------------------------------------------------------
-- Cara kerja (sama seperti splice manual di game):
--   1. Tanam Seed A di tile Grid yang kosong (di bawahnya harus ada block).
--   2. Taruh Seed B di atas pohon A -> World.spliceSeed(x, y, B).
--   3. Server membalas id pohon hasil splice, tile langsung diganti di layar.
--   Hasil splice diperkirakan dulu pakai modul Splice game; kalau tidak bisa, tidak dijalankan.
do (function()
    local SpliceMod = Session.Found.Splice
    local okMod = SpliceMod ~= nil

    function Splice.result(a, b)
        if not (okMod and type(SpliceMod) == "table" and type(SpliceMod.result) == "function") then return nil end
        if not (a and b) then return nil end
        local ok, r = pcall(SpliceMod.result, a, b)
        return ok and r or nil
    end

    local function setVisual()
        if UI.SpliceToggle then pcall(function() UI.SpliceToggle:Set(Splice.Running) end) end
    end

    function Splice.stop(reason)
        Splice.Running = false
        if Splice.Roaming then Auto.stopSpliceRoam() end
        Splice.Status = reason or "Dihentikan"
        setVisual()
        if reason then notify("Auto Splice", reason, 4) end
    end

    local function treeSpliced(x, y)
        local t = Auto.treeEntry(x, y)
        return type(t) == "table" and t.s == true
    end

    local function spliceAt(x, y)
        local w = Refs.World
        local f = w and rawget(w, "spliceSeed")
        if type(f) ~= "function" then return false, "fungsi splice game tidak ketemu" end
        local ok, made = pcall(f, x, y, Splice.B)
        if ok and made and ItemDB[made] then
            pcall(function() Refs.Inv:remove(Splice.B, 1) end)
            if Refs.SetTile then pcall(Refs.SetTile, "fg", x, y, made, true) end -- ganti di layar saja
            Splice.Made += 1
            Splice.Status = ("Splice jadi %s (%d,%d)"):format(itemName(made), x, y)
            return true
        end
        return false, "ditolak server"
    end

    local function loop(runId)
        while Splice.Running and alive() and Splice.RunId == runId do
            local px, py = getPlayerTile()
            if not px then
                Splice.stop("Karakter tidak ditemukan (keluar world?)")
                return
            end
            local A, B = Splice.A, Splice.B
            local acted = false
            local now = os.clock()
            for _, o in ipairs(sortedOffsets()) do
                if not Splice.Running then break end
                local x, y = px + o.dx, py + o.dy
                local key = x .. "," .. y
                if not (Splice.Fail[key] and Splice.Fail[key] > now) then
                    local fg = tileAt("fg", x, y)
                    -- 1) tanam Seed A
                    if fg == 0 and invCount(A) > 0 and invCount(B) > 0 and Auto.plantSpotOk(x, y, A) then
                        sendSetTile("fg", x, y, A)
                        pcall(function() Refs.Inv:remove(A, 1) end)
                        Splice.Planted += 1
                        Splice.Status = ("Tanam %s (%d,%d)"):format(itemName(A), x, y)
                        acted = true
                        task.wait(Splice.Ms / 1000)
                        fg = tileAt("fg", x, y)
                    end
                    -- 2) splice Seed B ke pohon A
                    if fg == A and invCount(B) > 0 and not treeSpliced(x, y) then
                        local ok, why = spliceAt(x, y)
                        if not ok then
                            Splice.Fail[key] = os.clock() + 30
                            Splice.Status = ("Gagal splice (%d,%d): %s"):format(x, y, why)
                        end
                        acted = true
                        task.wait(Splice.Ms / 1000)
                    end
                end
            end
            if not acted then
                if invCount(A) <= 0 or invCount(B) <= 0 then
                    Splice.stop("Seed habis")
                    return
                end
                Splice.Status = "Menunggu tile Grid kosong (panen dulu pohonnya)"
                task.wait(1)
            end
        end
    end

    function Splice.start()
        if Splice.Running then return end
        local err
        if not Refs.World then
            err = "Data world belum ketemu. Tekan 'Hubungkan ke game'"
        elseif not (Splice.A and Splice.B) then
            err = "Pilih Seed A dan Seed B dulu"
        elseif Splice.A == Splice.B then
            err = "Seed A dan Seed B harus beda"
        elseif not Splice.result(Splice.A, Splice.B) then
            err = "Kombinasi ini tidak bisa di-splice"
        elseif not Splice.Roam and next(State.Offsets) == nil then
            err = "Pilih tile dulu di Grid Tile (tab Farm), atau nyalakan Keliling world"
        elseif State.Running or Clear.Running or Farmer.Running then
            err = "Hentikan Auto Farm / Clear / Farmer dulu"
        end
        if err then
            notify("Auto Splice", err, 4)
            setVisual()
            return
        end
        table.clear(Splice.Fail)
        Splice.Running = true
        Splice.RunId = (Splice.RunId or 0) + 1
        setVisual()
        if Splice.Roam then
            local e = Auto.startSpliceRoam()
            if e then Splice.stop(e) end
        else
            task.spawn(loop, Splice.RunId)
        end
    end

    function Splice.resultText()
        if not (Splice.A and Splice.B) then return "Pilih Seed A dan Seed B" end
        local r = Splice.result(Splice.A, Splice.B)
        if not r then return "Hasil: tidak bisa di-splice" end
        return "Hasil: " .. itemName(r)
    end

    task.spawn(function()
        while alive() do
            if UI.SpliceStatus then
                local txt = ("Status: %s\n%s\nSeed A: %s (x%d) | Seed B: %s (x%d)\nDitanam: %d | Splice jadi: %d"):format(
                    Splice.Running and Splice.Status or ("BERHENTI - " .. Splice.Status), Splice.resultText(),
                    Splice.A and itemName(Splice.A) or "-", Splice.A and invCount(Splice.A) or 0,
                    Splice.B and itemName(Splice.B) or "-", Splice.B and invCount(Splice.B) or 0,
                    Splice.Planted, Splice.Made)
                if txt ~= Splice.Shown then
                    Splice.Shown = txt
                    pcall(function() UI.SpliceStatus:SetDesc(txt) end)
                end
            end
            task.wait(1)
        end
    end)
end)() end

Config.add("Splice", Splice, { "A", "B", "Ms", "Roam" })
Splice.Ms = math.max(Splice.Ms, 140)

-- ===== TAB: SPLICE =====
do (function()
    local SpTab = makeTab("Splice", "git-merge", "farm")

    safe(function()
        UI.SpliceStatus = SpTab:Paragraph({ Title = "Status Splice", Desc = "-" })
    end)

    local sCtl = box(SpTab, "Kontrol", true)
    local sSeed = box(SpTab, "Seed", true)
    local sSpeed = box(SpTab, "Kecepatan", false)

    safe(function()
        UI.SpliceToggle = sCtl:Toggle({
            Title = "Auto Splice",
            Desc = "Tanam Seed A lalu splice Seed B",
            Value = false,
            Callback = function(on)
                if on then Splice.start() elseif Splice.Running then Splice.stop() end
            end,
        })
    end)

    local function seedLabels()
        local labels = {}
        for _, id in ipairs(seedIds()) do labels[#labels + 1] = ("%s [%d]"):format(itemName(id), id) end
        if #labels == 0 then labels = { "(tidak ada seed di inventori)" } end
        return labels
    end
    local function idOf(opt) return tonumber(string.match(tostring(opt or ""), "%[(%d+)%]$")) end

    safe(function()
        UI.SpliceA = sSeed:Dropdown({
            Title = "Seed A (ditanam)",
            Values = { "(memuat...)" },
            Callback = function(opt)
                local id = idOf(opt)
                if id then Splice.A = id end
            end,
        })
    end)

    safe(function()
        UI.SpliceB = sSeed:Dropdown({
            Title = "Seed B (di-splice)",
            Values = { "(memuat...)" },
            Callback = function(opt)
                local id = idOf(opt)
                if id then Splice.B = id end
            end,
        })
    end)

    -- dipanggil saat inventori berubah
    local lastSig = nil
    UI.SpliceRefresh = function(force)
        local labels = seedLabels()
        local sig = table.concat(labels, "|")
        if not force and sig == lastSig then return end
        lastSig = sig
        for _, pair in ipairs({ { UI.SpliceA, Splice.A }, { UI.SpliceB, Splice.B } }) do
            local dd, id = pair[1], pair[2]
            if dd then
                UI.exec(function() dd:Refresh(labels) end)
                if id then
                    local want = "[" .. id .. "]"
                    for _, l in ipairs(labels) do
                        if string.sub(l, -#want) == want then
                            UI.exec(function() dd:Select(l) end)
                            break
                        end
                    end
                end
            end
        end
    end

    safe(function()
        sSeed:Button({
            Title = "Refresh daftar seed",
            Callback = function() UI.later("splice", function() UI.SpliceRefresh(true) end) end,
        })
    end)

    safe(function()
        sCtl:Toggle({
            Title = "Keliling world (A*)",
            Desc = "Nyala: jalan ke seluruh world. Mati: hanya tile Grid 5x5",
            Value = Splice.Roam,
            Callback = function(on)
                if Splice.Running then Splice.stop("Mode diganti, nyalakan lagi") end
                Splice.Roam = on
            end,
        })
    end)

    addNumber(sSpeed, {
        Title = "Jeda tanam / splice (ms)",
        Min = 140, Max = 2000, Step = 10, Default = Splice.Ms,
        Callback = function(v) Splice.Ms = math.floor(v) end,
    })
end)() end

-- ===== TAB: VENDING =====
do (function()
    local VTab = makeTab("Vending", "store", "farm")

    safe(function()
        UI.VendStatus = VTab:Paragraph({ Title = "Status Vending", Desc = "-" })
    end)

    local vCtl = box(VTab, "Kontrol", true)
    local vItem = box(VTab, "Pilih item", true)
    local vDrop = box(VTab, "Titik drop vending", true)

    safe(function()
        UI.VendToggle = vCtl:Toggle({
            Title = "Jalankan Vending",
            Desc = "Jalankan di world vending milikmu",
            Value = false,
            Callback = function(on)
                if on then Vend.start() elseif Vend.Running then Vend.stop() end
            end,
        })
    end)

    safe(function()
        vCtl:Dropdown({
            Title = "Mode",
            Values = Auto.VEND_MODES,
            Value = Vend.Mode,
            Callback = function(v)
                if type(v) == "table" then v = v[1] end
                if type(v) == "string" then Vend.Mode = v end
            end,
        })
    end)

    safe(function()
        local labels, picked = Vend.labels(Refs.World and Vend.machines() or nil)
        UI.VendItems = vItem:Dropdown({
            Title = "Item yang diambil",
            Desc = "Bisa pilih banyak. Kosong = semua item. Daftar: isi vending, tas & drop yang terlihat",
            Values = (#labels > 0) and labels or { "(belum ada item)" },
            Value = picked,
            Multi = true,
            AllowNone = true,
            Callback = function(opts)
                local list = {}
                for _, label in ipairs(type(opts) == "table" and opts or { opts }) do
                    local id = tonumber(string.match(tostring(label), "%[(%d+)%]$"))
                    if id then list[#list + 1] = id end
                end
                Vend.Items = list
            end,
        })
    end)

    -- isi ulang daftar item kalau ada item baru (vending / tas / drop di world ini)
    -- Hasil: jumlah item di daftar, teks rincian (tas / drop / vending) atau pesan error
    function Vend.refreshItems(force, machines)
        if not UI.VendItems then return 0, "dropdown belum dibuat" end
        local ok, labels, picked, st = pcall(function()
            local m = machines
            if not m and Refs.World then
                local okM, res = pcall(Vend.machines)
                m = okM and res or nil
            end
            return Vend.labels(m)
        end)
        if not ok then
            warn("[SkyP] daftar item vending error: " .. tostring(labels))
            return 0, "error: " .. tostring(labels)
        end
        local info = ("tas %d | drop %d | vending %d"):format(st.inv, st.drop, st.vend)
        local sig = table.concat(labels, "|")
        if not force and sig == Vend.ItemSig then return #labels, info end
        Vend.ItemSig = sig
        UI.later("vendItems", function()
            local okR, errR = UI.exec(function()
                UI.VendItems:Refresh((#labels > 0) and labels or { "(belum ada item)" })
            end)
            if not okR then
                Vend.ItemSig = nil
                warn("[SkyP] refresh dropdown item vending gagal: " .. tostring(errR))
                notify("Vending", "Daftar item gagal dimuat: " .. tostring(errR), 6)
                return
            end
            if #picked > 0 then UI.exec(function() UI.VendItems:Select(picked) end) end
        end)
        return #labels, info
    end

    safe(function()
        vItem:Button({
            Title = "Muat ulang daftar item",
            Desc = "Ambil item dari vending, tas & drop di world ini",
            Callback = function()
                local n, info = Vend.refreshItems(true)
                notify("Vending", ("Daftar item: %d item (%s)"):format(n, tostring(info)), 5)
            end,
        })
    end)

    safe(function()
        vItem:Button({
            Title = "Tambah item yang dipegang",
            Desc = "Pilih item di tas game (dipegang), lalu tekan. Masuk ke daftar item yang diambil",
            Callback = function()
                local id = nil
                if Refs.Inv then pcall(function() id = tonumber(Refs.Inv.selected) end) end
                local it = id and ItemDB[id]
                if not it or it.kind == "tool" or it.lock then
                    notify("Vending", "Pegang dulu block / seed di tas game (bukan tool)", 4)
                    return
                end
                if not table.find(Vend.Items, id) then table.insert(Vend.Items, id) end
                Vend.Seen[id] = true
                Vend.refreshItems(true)
                notify("Vending", "Item dipilih: " .. itemName(id), 3)
            end,
        })
    end)

    safe(function()
        vItem:Button({
            Title = "Hapus pilihan item",
            Desc = "Kembali ke semua item",
            Callback = function()
                table.clear(Vend.Items)
                Vend.ItemSig = nil
                UI.later("vendClear", function() UI.exec(function() UI.VendItems:Select(nil) end) end)
                Vend.refreshItems(true)
                notify("Vending", "Pilihan item dihapus: semua item", 3)
            end,
        })
    end)

    safe(function()
        UI.VendPointInput = vDrop:Input({
            Title = "Titik drop vending",
            Desc = "WORLD atau WORLD:ID (kosong = world ini). Isi stock: ambil drop di sini. Kosongkan: drop di sini",
            Value = Vend.Point,
            Placeholder = "STORAGE:ID",
            Callback = function(t) Vend.Point = tostring(t or "") end,
        })
    end)

    safe(function()
        vDrop:Button({
            Title = "Simpan posisi drop vending (posisi karakter)",
            Desc = "Berdiri di tempat drop (boleh di world titik drop), lalu tekan. Dipakai mode isi stock & kosongkan",
            Callback = function()
                local x, y = Auto.here()
                if not x then
                    notify("Vending", "Kamu belum masuk world", 3)
                    return
                end
                Vend.DropX, Vend.DropY = x, y
                -- world titik drop ikut diisi, kecuali sudah pakai pintu (WORLD:ID / WORLD|ID)
                local _, door = Vend.point()
                if not door then
                    Vend.Point = Guard.worldName()
                    if UI.VendPointInput then pcall(function() UI.VendPointInput:Set(Vend.Point) end) end
                end
                notify("Vending", ("Posisi drop vending (%d,%d) di %s"):format(x, y, Vend.Point), 4)
            end,
        })
    end)

    safe(function()
        vDrop:Button({
            Title = "Hapus posisi drop vending",
            Desc = "Drop / tunggu di titik kedatangan (pintu) saja",
            Callback = function()
                Vend.DropX, Vend.DropY = -1, -1
                notify("Vending", "Posisi drop vending dihapus", 3)
            end,
        })
    end)

    task.spawn(function()
        while alive() do
            local txt
            if Refs.World then
                local list = Vend.machines()
                local total, empty = 0, 0
                for _, m in ipairs(list) do
                    if m.id and m.stock > 0 then total += m.stock else empty += 1 end
                end
                local name, door = Vend.point()
                local names = {}
                for i, id in ipairs(Vend.Items) do
                    if i > 4 then
                        names[#names + 1] = "+" .. (#Vend.Items - 4)
                        break
                    end
                    names[#names + 1] = itemName(id)
                end
                if not Vend.Running then Vend.refreshItems(false, list) end
                txt = table.concat({
                    "Status  : " .. (Vend.Running and "JALAN" or "BERHENTI") .. " - " .. Vend.Mode,
                    "Item    : " .. ((#names > 0) and table.concat(names, ", ") or "semua item yang bisa dijual"),
                    ("Vending : %d milikmu di world ini | isi %d | kosong %d"):format(#list, total, empty),
                    "Titik   : " .. ((name ~= "" or door) and (name .. (door and (":" .. door) or "")) or "world ini")
                        .. (Vend.DropX >= 0 and (" (" .. Vend.DropX .. "," .. Vend.DropY .. ")") or " (titik kedatangan)"),
                    ("Hasil   : stock +%d | diambil %d | di-drop %d"):format(Vend.Stocked, Vend.Taken, Vend.Dropped),
                    "Aksi    : " .. Vend.Status,
                }, "\n")
            else
                txt = "Data world belum ketemu"
            end
            if UI.VendStatus and txt ~= Vend.Shown then
                Vend.Shown = txt
                pcall(function() UI.VendStatus:SetDesc(txt) end)
            end
            task.wait(1)
        end
    end)
end)() end

-- ===== TAB: PABRIK =====
do (function()
    local PTab = makeTab("Pabrik", "factory", "farm")

    safe(function()
        UI.PabrikStatus = PTab:Paragraph({ Title = "Status Pabrik", Desc = "-" })
    end)

    safe(function()
        PTab:Toggle({
            Title = "Detail status",
            Desc = "Mati = 1 baris ringkas. Nyala = rincian lengkap di bawahnya",
            Value = Pabrik.Detail,
            Callback = function(on)
                Pabrik.Detail = on
                Pabrik.Shown = nil
            end,
        })
    end)

    local pCtl = box(PTab, "Kontrol", true)
    local pRute = box(PTab, "Rute & panen", true)
    local pTile = box(PTab, "Lantai tanam & break (peta)", true)
    local pDrop = box(PTab, "Drop seed", true)

    safe(function()
        UI.PabrikToggle = pCtl:Toggle({
            Title = "Jalankan Pabrik",
            Desc = "Panen + tanam mengikuti rute lantai pilihanmu, lalu break. Seed lebihan di-drop",
            Value = false,
            Callback = function(on)
                if on then Pabrik.start() elseif Pabrik.Running then Pabrik.stop() end
            end,
        })
    end)

    safe(function()
        UI.PabrikSeedDropdown = pCtl:Dropdown({
            Title = "Seed pabrik",
            Desc = "Block-nya otomatis (contoh: Dirt Seed -> Dirt)",
            Values = { "(memuat...)" },
            Callback = function(opt)
                local id = tonumber(string.match(opt or "", "%[(%d+)%]$"))
                if id then Pabrik.SeedId = id end
            end,
        })
    end)

    safe(function()
        pCtl:Toggle({
            Title = "Break Cepat",
            Desc = "Break secepat batas server selama pabrik jalan",
            Value = Pabrik.Fast,
            Callback = function(on) Pabrik.Fast = on end,
        })
    end)

    safe(function()
        pRute:Dropdown({
            Title = "Urutan rute",
            Desc = "Atas ke bawah / Bawah ke atas / Terdekat dulu (mulai dari ujung yang dekat karakter)",
            Values = Pabrik.ORDERS,
            Value = Pabrik.Order,
            Callback = function(opt)
                if table.find(Pabrik.ORDERS, opt) then Pabrik.Order = opt end
            end,
        })
    end)

    safe(function()
        pRute:Toggle({
            Title = "Full world",
            Desc = "Semua lantai di world dipakai otomatis (tidak perlu pilih di peta). Pilihan manualmu tetap tersimpan",
            Value = Pabrik.Full,
            Callback = function(on)
                Pabrik.Full = on
                Pabrik._setAt = 0
                Pabrik.FullAt = 0 -- pindai sekarang
                Pabrik.Shown, Pabrik.SmartShown = nil, nil
                if UI.smartRepaint then pcall(UI.smartRepaint) end
            end,
        })
    end)

    addNumber(pRute, {
        Title = "Mulai panen saat pohon siap (%)",
        Desc = "100 = tunggu semua pohon siap baru jalan. Kecil = lebih sering bolak-balik",
        Min = 10, Max = 100, Step = 5, Default = Pabrik.ReadyPct,
        Callback = function(v) Pabrik.ReadyPct = math.clamp(math.floor(v), 10, 100) end,
    })

    safe(function()
        pRute:Button({
            Title = "Reset hitungan hasil",
            Desc = "Panen / tanam / di-drop kembali ke 0",
            Callback = function()
                Pabrik.Harvested, Pabrik.Planted, Pabrik.Dropped = 0, 0, 0
                Pabrik.Shown = nil
                notify("Pabrik", "Hitungan hasil direset", 3)
            end,
        })
    end)

    safe(function()
        UI.PabrikSmartInfo = pTile:Paragraph({ Title = "Pilihan world ini", Desc = "Belum ada. Buka peta untuk memilih" })
    end)

    safe(function()
        pTile:Button({
            Title = "Buka peta",
            Desc = "Mode Lantai: ketuk lantai tempat pohon ditanam. Mode Berdiri / Tile break: atur break. Tersimpan per world",
            Callback = function()
                if UI.openSmartMenu then UI.openSmartMenu() end
            end,
        })
    end)

    safe(function()
        pTile:Button({
            Title = "Titik break = posisi karakter",
            Desc = "Cara cepat: berdiri di tempat break lalu tekan (tile break bisa diubah di peta)",
            Callback = function()
                local x, y = Auto.here()
                if not x then
                    notify("Pabrik", "Kamu belum masuk world", 3)
                    return
                end
                pcall(Pabrik.syncPick)
                Pabrik.BreakX, Pabrik.BreakY = x, y
                if next(Pabrik.Tiles) == nil then
                    Pabrik.Tiles["1,0"] = true
                    Pabrik.Tiles["2,0"] = true
                end
                Pabrik.saveBreak()
                local ok, why = Pabrik.breakValid()
                notify("Pabrik", ("Titik break (%d,%d)"):format(x, y) .. (ok and "" or (" | perlu diperbaiki: " .. tostring(why))), 4)
            end,
        })
    end)

    safe(function()
        pTile:Button({
            Title = "Break otomatis",
            Desc = "Hapus titik & tile break. Saat pabrik mulai, tempat break dicari sendiri",
            Callback = function()
                pcall(Pabrik.syncPick)
                Pabrik.BreakX, Pabrik.BreakY = -1, -1
                table.clear(Pabrik.Tiles)
                Pabrik.saveBreak()
                notify("Pabrik", "Titik break: otomatis", 3)
            end,
        })
    end)

    safe(function()
        pTile:Button({
            Title = "Hapus pilihan lantai",
            Desc = "Hanya pilihan manual di world ini (Full world tidak terpengaruh)",
            Callback = function()
                table.clear(Pabrik.Pick)
                Pabrik._setAt = 0
                if UI.smartRepaint then UI.smartRepaint() end
            end,
        })
    end)

    safe(function()
        pDrop:Toggle({
            Title = "Auto drop seed",
            Desc = "Ke titik drop (tab Titik Drop). Dilakukan di antara fase, tidak di tengah rute",
            Value = Pabrik.Drop,
            Callback = function(on) Pabrik.Drop = on end,
        })
    end)

    addNumber(pDrop, {
        Title = "Sisakan seed",
        Desc = "Untuk ditanam lagi",
        Min = 0, Max = 199, Step = 1, Default = Pabrik.Keep,
        Callback = function(v) Pabrik.Keep = math.floor(v) end,
    })

    addNumber(pDrop, {
        Title = "Drop kalau seed sudah",
        Desc = "Maksimal 190 (batas aman tas). Contoh 190 & sisakan 50 = drop 140",
        Min = 2, Max = 200, Step = 1, Default = Pabrik.DropAt,
        Callback = function(v) Pabrik.DropAt = math.floor(v) end,
    })

    local function countKeys(t)
        local n = 0
        for _ in pairs(t) do n += 1 end
        return n
    end

    -- "3 menit lagi" (untuk status ringkas)
    local function soon(sec)
        sec = math.max(0, math.ceil(sec or 0))
        if sec < 60 then return sec .. " detik lagi" end
        if sec < 3600 then return math.ceil(sec / 60) .. " menit lagi" end
        return ("%d jam %d menit lagi"):format(sec // 3600, (sec % 3600) // 60)
    end

    local sumAt, sumReady, sumNext, sumPlant = -10, 0, nil, 0

    task.spawn(function()
        while alive() do
            -- pilihan per world: ganti otomatis saat masuk world lain
            local okS, changed = pcall(Pabrik.syncPick)
            if okS and changed then
                local n = countKeys(Pabrik.Pick)
                if n > 0 then
                    notify("Pabrik", ("Pilihan lantai world %s dimuat (%d lantai)"):format(Pabrik.PickWorld, n), 4)
                end
                if UI.smartRepaint then pcall(UI.smartRepaint) end
                sumAt = -10
            end
            -- Full world: daftar lantai dipindai di sini juga, supaya status benar walau pabrik belum jalan
            local okF, fresh = pcall(Pabrik.refreshFull)
            if okF and fresh then
                sumAt = -10
                if UI.smartRepaint then pcall(UI.smartRepaint) end
            end

            local seed, block = Pabrik.SeedId, Auto.blockOfSeed(Pabrik.SeedId)
            local name, door = Auto.parseDropTarget()
            local dropAt = (name ~= "" and name or "world ini") .. (door and (" pintu " .. door) or "")
                .. (Pabrik.DropX >= 0 and (" (" .. Pabrik.DropX .. "," .. Pabrik.DropY .. ")") or "")

            -- STATUS RINGKAS (1 baris): "Panen 3 menit lagi | seed 42 | tanam 120 tile"
            local now = os.clock()
            if now - sumAt >= 2 then -- pohon dihitung tiap 2 detik, sisanya dihitung mundur sendiri
                local okQ, a, b, c = pcall(Pabrik.summary)
                if okQ and a then
                    sumAt, sumReady, sumNext, sumPlant = now, a, b, c or 0
                else
                    sumAt, sumReady, sumNext, sumPlant = now, 0, nil, 0
                end
            end
            local head
            if not Refs.World then
                head = "Belum masuk world"
            elseif sumPlant == 0 then
                head = Pabrik.Full and "Full world: belum ada lantai yang bisa ditanami" or "Belum ada lantai dipilih (buka peta)"
            elseif sumReady > 0 then
                head = "Panen: " .. sumReady .. " pohon siap"
            elseif sumNext then
                head = "Panen " .. soon(sumNext - (now - sumAt))
            else
                head = "Belum ada pohon"
            end
            if Pabrik.Running then
                local ph = Pabrik.Phase
                if Pabrik.Progress then
                    head = Pabrik.Progress .. " | " .. head
                elseif ph and ph ~= "TUNGGU" then
                    head = ph .. " | " .. head
                else
                    head = "TUNGGU: " .. tostring(Pabrik.Status) -- alasan sebenarnya kenapa bot diam
                end
            else
                local why = Pabrik.Status
                head = ((why ~= "-" and why ~= "Dihentikan" and why ~= "Mulai...") and ("BERHENTI: " .. why) or "BERHENTI") .. " | " .. head
            end
            local line = head
                .. " | seed " .. (seed and invCount(seed) or 0)
                .. " | tanam " .. sumPlant .. " tile"
                .. (Pabrik.Warn and (" | ! " .. Pabrik.Warn) or "")

            local nBad = 0
            for _, t in pairs(Pabrik.Bad) do
                if t > now then nBad += 1 end
            end

            local txt = line
            if Pabrik.Detail then
                txt = table.concat({
                    line,
                    "",
                    "Status : " .. (Pabrik.Running and ("JALAN - fase " .. tostring(Pabrik.Phase or "-")) or "BERHENTI"),
                    ("Rute   : %d titik berdiri | %d lantai%s%s"):format(#Pabrik.Route, countKeys(Pabrik.activePick()),
                        nBad > 0 and (" | " .. nBad .. " titik tidak terjangkau") or "",
                        Pabrik.Progress and (" | " .. Pabrik.Progress) or ""),
                    ("Urutan : %s | %s | panen saat %d%% siap"):format(tostring(Pabrik.Order),
                        Pabrik.Full and "FULL WORLD" or "lantai pilihan", Pabrik.ReadyPct),
                    ("Seed   : %s x%d | block %s x%d"):format(seed and itemName(seed) or "-", seed and invCount(seed) or 0,
                        block and itemName(block) or "-", block and invCount(block) or 0),
                    ("Break  : %s | tile %d%s"):format(Pabrik.BreakX >= 0 and ("(" .. Pabrik.BreakX .. "," .. Pabrik.BreakY .. ")")
                        or "otomatis", countKeys(Pabrik.Tiles), Pabrik.Fast and " | Break Cepat" or ""),
                    ("Drop   : %s | sisakan %d, drop saat >= %d"):format(Pabrik.Drop and dropAt or "mati", Pabrik.Keep,
                        math.min(Pabrik.DropAt, 190)),
                    ("Hasil  : panen %d | tanam %d | di-drop %d"):format(Pabrik.Harvested, Pabrik.Planted, Pabrik.Dropped),
                    "Aksi   : " .. Pabrik.Status,
                }, "\n")
            end
            if UI.PabrikStatus and txt ~= Pabrik.Shown then
                Pabrik.Shown = txt
                pcall(function() UI.PabrikStatus:SetDesc(txt) end)
            end
            do
                local nSeg = countKeys(Pabrik.activePick())
                local nWorld = 0
                for _, p in pairs(Pabrik.Picks) do
                    if type(p) == "table" and next(p) ~= nil then nWorld += 1 end
                end
                local wn = Pabrik.PickWorld ~= "" and Pabrik.PickWorld or "-"
                local sTxt = (nSeg > 0 and ("World %s: %s%d lantai | %d tile tanam"):format(wn, Pabrik.Full and "FULL WORLD, " or "", nSeg, sumPlant)
                    or (Pabrik.Full and ("World %s: Full world, belum ada lantai yang bisa ditanami"):format(wn)
                        or ("World %s: belum ada lantai. Buka peta untuk memilih, atau nyalakan Full world"):format(wn)))
                    .. "\nUrutan rute: " .. tostring(Pabrik.Order)
                    .. "\nBreak: " .. (Pabrik.BreakX >= 0 and ("berdiri (%d,%d), %d tile"):format(Pabrik.BreakX, Pabrik.BreakY, countKeys(Pabrik.Tiles))
                        or "otomatis")
                    .. ("\nTersimpan: %d world"):format(nWorld)
                if UI.PabrikSmartInfo and sTxt ~= Pabrik.SmartShown then
                    Pabrik.SmartShown = sTxt
                    pcall(function() UI.PabrikSmartInfo:SetDesc(sTxt) end)
                end
            end
            task.wait(1)
        end
    end)
end)() end

---------------------------------------------------------------------
-- PETA PABRIK: pilih lantai tanam + atur titik & tile break
---------------------------------------------------------------------
-- Tampilan: PETA MINI world, 3 mode (tombol di kanan atas):
--   Mode Lantai    : ketuk lantai untuk pilih / batal (pohon ditanam tepat di atasnya)
--   Mode Berdiri   : ketuk 1 tile = titik berdiri saat break
--   Mode Tile break: ketuk tile di sekitar titik berdiri (maks 2 tile) = tile yang dipasang-pecah
--   biru = lantai dipilih (baris hijau di atasnya = tile tanam), kuning = bot, ungu = titik break,
--   oranye = tile break, hijau kecil = pohon, MERAH = titik rute yang tidak terjangkau.
do (function() -- fungsi sendiri: variabel di dalam tidak ikut batas 200 local
    local Gui = newScreenGui("SkyPSmartMenu")
    UI.SmartGui = Gui
    local C = {
        on = Color3.fromRGB(62, 150, 255),      -- lantai dipilih
        floor = Color3.fromRGB(96, 104, 128),   -- lantai yang bisa dipilih
        stale = Color3.fromRGB(150, 110, 60),   -- pilihan lama, lantainya sudah berubah
        block = Color3.fromRGB(40, 44, 58),     -- block lain
        other = Color3.fromRGB(26, 29, 38),     -- benda tidak padat
        tree = Color3.fromRGB(52, 150, 96),
        plant = Color3.fromRGB(70, 210, 130),   -- tile tanam di atas lantai terpilih
        bot = Color3.fromRGB(255, 210, 60),
        brk = Color3.fromRGB(170, 120, 255),    -- titik berdiri saat break
        brkTile = Color3.fromRGB(255, 150, 70),
        bad = Color3.fromRGB(232, 84, 104),     -- titik rute tidak terjangkau
    }

    -- ukuran panel menyesuaikan layar (HP / PC)
    local cam = workspace.CurrentCamera
    local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
    local PW = math.clamp(math.floor(vp.X - 24), 300, 560)
    local PH = math.clamp(math.floor(vp.Y - 24), 280, 470)
    local MAP_W, MAP_H = PW - 20, PH - 140

    local Panel = Instance.new("Frame")
    Panel.Size = UDim2.fromOffset(PW, PH)
    Panel.Position = UDim2.fromOffset(math.max(8, math.floor((vp.X - PW) / 2)), math.max(8, math.floor((vp.Y - PH) / 2)))
    Panel.BackgroundColor3 = Color3.fromRGB(13, 15, 20)
    Panel.BorderSizePixel = 0
    Panel.Parent = Gui
    Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, 14)
    local stroke = Instance.new("UIStroke", Panel)
    stroke.Color = Color3.fromRGB(62, 150, 255)
    stroke.Transparency = 0.45

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -160, 0, 28)
    Title.Position = UDim2.fromOffset(10, 4)
    Title.BackgroundTransparency = 1
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 13
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.TextTruncate = Enum.TextTruncate.AtEnd
    Title.TextColor3 = Color3.fromRGB(236, 240, 247)
    Title.Text = "Peta Pabrik"
    Title.Parent = Panel

    local Close = Instance.new("TextButton")
    Close.Size = UDim2.fromOffset(24, 24)
    Close.Position = UDim2.new(1, -30, 0, 6)
    Close.BackgroundColor3 = Color3.fromRGB(32, 36, 48)
    Close.Text = "X"
    Close.Font = Enum.Font.GothamBold
    Close.TextSize = 12
    Close.TextColor3 = Color3.new(1, 1, 1)
    Close.Parent = Panel
    Instance.new("UICorner", Close).CornerRadius = UDim.new(0, 6)
    Close.MouseButton1Click:Connect(function() Gui.Enabled = false end)

    local Info = Instance.new("TextLabel")
    Info.Size = UDim2.new(1, -20, 0, 34)
    Info.Position = UDim2.fromOffset(10, 34)
    Info.BackgroundTransparency = 1
    Info.Font = Enum.Font.Gotham
    Info.TextSize = 12
    Info.TextWrapped = true
    Info.TextXAlignment = Enum.TextXAlignment.Left
    Info.TextYAlignment = Enum.TextYAlignment.Top
    Info.TextColor3 = Color3.fromRGB(139, 148, 167)
    Info.Text = "Ketuk lantai di peta untuk dipilih. Pohon ditanam tepat di atasnya"
    Info.Parent = Panel

    -- peta: bisa digeser (scroll) & diperbesar
    local Map = Instance.new("ScrollingFrame")
    Map.Size = UDim2.fromOffset(MAP_W, MAP_H)
    Map.Position = UDim2.fromOffset(10, 72)
    Map.BackgroundColor3 = Color3.fromRGB(8, 9, 13)
    Map.BorderSizePixel = 0
    Map.ScrollBarThickness = 4
    Map.ScrollingDirection = Enum.ScrollingDirection.XY
    Map.CanvasSize = UDim2.new(0, 0, 0, 0)
    Map.Parent = Panel
    Instance.new("UICorner", Map).CornerRadius = UDim.new(0, 8)

    local Canvas = Instance.new("Frame")
    Canvas.BackgroundTransparency = 1
    Canvas.BorderSizePixel = 0
    Canvas.Parent = Map
    local Layer = Instance.new("Frame") -- block & lantai (dibuat ulang tiap pindai)
    Layer.Size = UDim2.fromScale(1, 1)
    Layer.BackgroundTransparency = 1
    Layer.BorderSizePixel = 0
    Layer.ZIndex = 1
    Layer.Parent = Canvas

    -- penanda (bot / break): tidak menangkap ketukan, lantai di bawahnya tetap bisa diketuk
    local function newMark(color, z, round)
        local f = Instance.new("Frame")
        f.BackgroundColor3 = color
        f.BorderSizePixel = 0
        f.ZIndex = z
        f.Visible = false
        f.Parent = Canvas
        if round then Instance.new("UICorner", f).CornerRadius = UDim.new(1, 0) end
        local st = Instance.new("UIStroke", f)
        st.Color = Color3.new(1, 1, 1)
        st.Thickness = 1
        st.Transparency = round and 0.1 or 0.45
        return f
    end
    local Brk = newMark(C.brk, 5, false)
    local Bot = newMark(C.bot, 6, true)
    local brkPool = {}
    local badPool = {}

    local Legend = Instance.new("TextLabel")
    Legend.Size = UDim2.new(1, -20, 0, 16)
    Legend.Position = UDim2.new(0, 10, 1, -62)
    Legend.BackgroundTransparency = 1
    Legend.Font = Enum.Font.Gotham
    Legend.TextSize = 11
    Legend.RichText = true
    Legend.TextXAlignment = Enum.TextXAlignment.Left
    Legend.TextTruncate = Enum.TextTruncate.AtEnd
    Legend.TextColor3 = Color3.fromRGB(139, 148, 167)
    Legend.Text = '<font color="#3E96FF">●</font> dipilih  <font color="#606880">●</font> lantai  '
        .. '<font color="#FFD23C">●</font> bot  <font color="#AA78FF">●</font> break  <font color="#349660">●</font> pohon  '
        .. '<font color="#E85468">●</font> tak terjangkau'
    Legend.Parent = Panel

    local cell = 6                 -- ukuran 1 tile di peta (pixel)
    local dw, dh = 0, 0            -- ukuran world yang sedang digambar
    local drawnW, drawnName, drawnPick = nil, nil, nil
    local items = {}               -- { instance, x, y, lebar, tinggi } dalam satuan tile
    local segEls = {}              -- { sg, floor, plant, btn }
    local segs, scanning = {}, false
    local lastTap = nil
    local mode = "lantai"          -- "lantai" | "berdiri" | "tile"

    local function markAt(inst, x, y, size)
        inst.Size = UDim2.fromOffset(size, size)
        inst.Position = UDim2.fromOffset(x * cell + (cell - size) // 2, y * cell + (cell - size) // 2)
    end

    local function moveMarks()
        local n = 0
        if dw > 0 then
            local px, py = getPlayerTile()
            if px then markAt(Bot, px, py, math.max(cell, 8)) end
            Bot.Visible = px ~= nil
            Brk.Visible = Pabrik.BreakX >= 0
            if Pabrik.BreakX >= 0 then
                markAt(Brk, Pabrik.BreakX, Pabrik.BreakY, math.max(cell, 8))
                for key in pairs(Pabrik.Tiles) do
                    local dx, dy = string.match(tostring(key), "^(-?%d+),(-?%d+)$")
                    if dx then
                        n += 1
                        local f = brkPool[n]
                        if not f then
                            f = newMark(C.brkTile, 4, false)
                            brkPool[n] = f
                        end
                        markAt(f, Pabrik.BreakX + tonumber(dx), Pabrik.BreakY + tonumber(dy), math.max(cell - 1, 6))
                        f.Visible = true
                    end
                end
            end
        else
            Bot.Visible = false
            Brk.Visible = false
        end
        for i = n + 1, #brkPool do brkPool[i].Visible = false end
        -- titik rute yang tidak terjangkau: garis merah di tile tanam yang dilayani titik itu
        local nb = 0
        if dw > 0 then
            local nowB = os.clock()
            for _, st in ipairs(Pabrik.Route) do
                if (Pabrik.Bad[st.key] or 0) > nowB then
                    nb += 1
                    local f = badPool[nb]
                    if not f then
                        f = Instance.new("Frame")
                        f.BackgroundColor3 = C.bad
                        f.BackgroundTransparency = 0.25
                        f.BorderSizePixel = 0
                        f.ZIndex = 3
                        f.Parent = Canvas
                        badPool[nb] = f
                    end
                    f.Position = UDim2.fromOffset(st.lo * cell, st.y * cell)
                    f.Size = UDim2.fromOffset((st.hi - st.lo + 1) * cell, cell)
                    f.Visible = true
                end
            end
        end
        for i = nb + 1, #badPool do badPool[i].Visible = false end
    end

    local function layout()
        local size = UDim2.fromOffset(dw * cell, dh * cell)
        Canvas.Size = size
        Map.CanvasSize = size
        for _, e in ipairs(items) do
            e[1].Position = UDim2.fromOffset(e[2] * cell, e[3] * cell)
            e[1].Size = UDim2.fromOffset(e[4] * cell, e[5] * cell)
        end
        moveMarks()
    end

    local function centerOn(tx, ty)
        Map.CanvasPosition = Vector2.new(
            math.max(0, math.floor((tx + 0.5) * cell - MAP_W / 2)),
            math.max(0, math.floor((ty + 0.5) * cell - MAP_H / 2)))
    end

    local function paint(e)
        local on = Pabrik.activePick()[e.sg.key] ~= nil
        e.floor.BackgroundColor3 = on and C.on or (e.sg.stale and C.stale or C.floor)
        e.plant.BackgroundTransparency = on and 0.5 or 1
        if e.sg.stale then e.btn.Visible = on end -- lantai lama yang dibatalkan: hilang dari peta
    end

    local function refreshInfo()
        Pabrik._setAt = 0
        local nSeg, nTile = 0, 0
        for _ in pairs(Pabrik.activePick()) do nSeg += 1 end
        if nSeg > 0 and Refs.World then
            for _ in pairs(Pabrik.smartSet()) do nTile += 1 end
        end
        local wn = Pabrik.PickWorld ~= "" and Pabrik.PickWorld or "-"
        if mode == "lantai" then
            if Pabrik.Full then
                Info.Text = ("World %s | FULL WORLD: %d lantai, %d tile tanam\n%s"):format(
                    wn, nSeg, nTile, lastTap or "Semua lantai dipakai (matikan Full world di tab Pabrik untuk memilih)")
            else
                Info.Text = ("World %s | terpilih %d lantai, %d tile tanam (tersimpan otomatis)\n%s"):format(
                    wn, nSeg, nTile, lastTap or "Ketuk lantai di peta untuk pilih / batal")
            end
        else
            local nBrk = 0
            for _ in pairs(Pabrik.Tiles) do nBrk += 1 end
            local hint = (mode == "berdiri") and "Ketuk tile tempat bot berdiri saat break (tile itu tidak ditanami)"
                or "Ketuk tile di sekitar titik berdiri (maks 2 tile) untuk pilih / batal"
            Info.Text = ("World %s | break: %s, %d tile\n%s"):format(wn,
                Pabrik.BreakX >= 0 and ("berdiri (" .. Pabrik.BreakX .. "," .. Pabrik.BreakY .. ")") or "otomatis",
                nBrk, lastTap or hint)
        end
    end

    local function repaint()
        for _, e in ipairs(segEls) do paint(e) end
        refreshInfo()
    end
    UI.smartRepaint = repaint

    -- Deretan block per baris (digabung supaya jumlah kotak sedikit): { x, y, panjang, jenis }
    -- jenis: 1 = block padat, 2 = pohon, 3 = benda tidak padat
    local function scanBlocks(w)
        local out = {}
        if not w then return out end
        local n = 0
        for y = 0, w.h - 1 do
            local row = w.fg[y]
            local x0, cat = 0, 0
            for x = 0, w.w do -- x = w.w hanya penutup deretan
                n += 1
                if n % 4000 == 0 then task.wait() end
                local c = 0
                if x < w.w then
                    local id = row and row[x] or 0
                    if id ~= 0 then
                        local it = ItemDB[id]
                        if it and it.kind == "seed" then
                            c = 2
                        elseif it and not it.solid then
                            c = 3
                        else
                            c = 1
                        end
                    end
                end
                if c ~= cat then
                    if cat ~= 0 then out[#out + 1] = { x0, y, x - x0, cat } end
                    x0, cat = x, c
                end
            end
        end
        return out
    end

    -- Pilihan tersimpan yang lantainya sudah berubah (dipanjangkan / dipotong / hilang):
    -- lantai baru yang menimpanya otomatis dipilih; yang hilang total tetap digambar supaya bisa dibatalkan.
    local function fixStale()
        local known, stale = {}, {}
        for _, sg in ipairs(segs) do known[sg.key] = true end
        for key in pairs(Pabrik.Pick) do
            if not known[key] then stale[#stale + 1] = key end
        end
        for _, key in ipairs(stale) do
            local y, x0, x1 = string.match(tostring(key), "^(%d+),(%d+),(%d+)$")
            y, x0, x1 = tonumber(y), tonumber(x0), tonumber(x1)
            local moved = false
            if y and x0 and x1 then
                for _, sg in ipairs(segs) do
                    if sg.y == y and sg.x0 <= x1 and sg.x1 >= x0 then
                        Pabrik.Pick[sg.key] = true
                        moved = true
                    end
                end
            end
            if moved or not (y and x0 and x1) or y < 1 or y >= dh or x0 >= dw or x1 < x0 then
                Pabrik.Pick[key] = nil
            else
                x1 = math.min(x1, dw - 1)
                segs[#segs + 1] = { y = y, x0 = x0, x1 = x1, n = x1 - x0 + 1, key = key, stale = true }
            end
        end
    end

    local function draw(center)
            pcall(Pabrik.syncPick)
            if Pabrik.Full then pcall(Pabrik.refreshFull, true) end
            local w = Refs.World
            local ok, res = pcall(Pabrik.scanSegments, Pabrik.Full)
            local okB, rects = pcall(scanBlocks, w)
            if not alive() then return end
            Layer:ClearAllChildren()
            table.clear(items)
            table.clear(segEls)
            segs = (ok and type(res) == "table") and res or {}
            rects = (okB and type(rects) == "table") and rects or {}
            dw, dh = w and tonumber(w.w) or 0, w and tonumber(w.h) or 0
            drawnW, drawnPick = w, Pabrik.PickWorld
            if dw <= 0 or dh <= 0 then
                dw, dh = 0, 0
                layout()
                Info.Text = "Belum masuk world. Masuk world dulu lalu tekan Pindai ulang"
                return
            end
            -- pabrik sedang jalan & karakter di world lain (misal pergi drop): pilihan world pabrik tidak disentuh
            local here = string.upper(Guard.worldName and Guard.worldName() or "")
            if here ~= Pabrik.PickWorld then
                segs = {}
                for i = 1, math.min(#rects, 3000) do
                    local r = rects[i]
                    local f = Instance.new("Frame")
                    f.BorderSizePixel = 0
                    f.BackgroundColor3 = (r[4] == 2 and C.tree) or (r[4] == 3 and C.other) or C.block
                    f.Parent = Layer
                    items[#items + 1] = { f, r[1], r[2], r[3], 1 }
                end
                layout()
                Info.Text = ("Pabrik memakai pilihan world %s.\nKembali ke world itu untuk mengubah pilihan"):format(Pabrik.PickWorld)
                return
            end
            -- world baru: perbesaran dipaskan ke lebar panel
            if drawnName ~= Pabrik.PickWorld then
                drawnName = Pabrik.PickWorld
                cell = math.clamp(MAP_W // dw, 4, 14)
                center = true
            end
            if not Pabrik.Full then fixStale() end -- Full world: pilihan manual tidak disentuh

            for i = 1, math.min(#rects, 3000) do
                local r = rects[i]
                local f = Instance.new("Frame")
                f.BorderSizePixel = 0
                f.BackgroundColor3 = (r[4] == 2 and C.tree) or (r[4] == 3 and C.other) or C.block
                f.ZIndex = 1
                f.Parent = Layer
                items[#items + 1] = { f, r[1], r[2], r[3], 1 }
                if i % 400 == 0 then task.wait() end
            end
            if not alive() then return end

            for _, sg in ipairs(segs) do
                -- area ketuk = lantai + tile tanam di atasnya (2 tile tinggi, lebih gampang diketuk)
                local b = Instance.new("TextButton")
                b.Text = ""
                b.AutoButtonColor = false
                b.BackgroundTransparency = 1
                b.BorderSizePixel = 0
                b.ZIndex = 2
                b.Parent = Layer
                local plant = Instance.new("Frame")
                plant.Size = UDim2.fromScale(1, 0.5)
                plant.BackgroundColor3 = C.plant
                plant.BackgroundTransparency = 1
                plant.BorderSizePixel = 0
                plant.ZIndex = 2
                plant.Parent = b
                local floor = Instance.new("Frame")
                floor.Size = UDim2.fromScale(1, 0.5)
                floor.Position = UDim2.fromScale(0, 0.5)
                floor.BorderSizePixel = 0
                floor.ZIndex = 2
                floor.Parent = b
                items[#items + 1] = { b, sg.x0, sg.y - 1, sg.n, 2 }
                local e = { sg = sg, floor = floor, plant = plant, btn = b }
                segEls[#segEls + 1] = e
                paint(e)
                b.MouseButton1Click:Connect(function()
                    if Pabrik.Full then
                        lastTap = "Full world nyala: semua lantai dipakai. Matikan di tab Pabrik untuk memilih sendiri"
                        refreshInfo()
                        return
                    end
                    local on = Pabrik.Pick[sg.key] == nil
                    Pabrik.Pick[sg.key] = on or nil
                    lastTap = ("Lantai y=%d, x %d-%d (%d tile): %s"):format(sg.y, sg.x0, sg.x1, sg.n, on and "DIPILIH" or "batal")
                    paint(e)
                    refreshInfo()
                end)
            end

            layout()
            if center then
                local px, py = getPlayerTile()
                if px then centerOn(px, py) else Map.CanvasPosition = Vector2.new(0, 0) end
            end
            if #segs == 0 then
                Info.Text = "Tidak ada lantai (min 3 tile) yang bisa ditanami di world ini"
            else
                refreshInfo()
            end
    end

    local function rebuild(center)
        if scanning then return end
        scanning = true
        Info.Text = "Memindai world..."
        task.spawn(function()
            local ok, e = pcall(draw, center)
            scanning = false
            if not ok and alive() then Info.Text = "Gagal menggambar peta: " .. tostring(e) end
        end)
    end

    local function zoom(d)
        if dw == 0 then return end
        local old = cell
        cell = math.clamp(cell + d, 3, 26)
        if cell == old then return end
        -- titik tengah layar peta tetap di tengah
        local cx = (Map.CanvasPosition.X + MAP_W / 2) / old
        local cy = (Map.CanvasPosition.Y + MAP_H / 2) / old
        layout()
        centerOn(cx - 0.5, cy - 0.5)
    end

    -- MODE PETA: Lantai (pilih lantai tanam) / Berdiri (titik break) / Tile break
    local MODE_NEXT = { lantai = "berdiri", berdiri = "tile", tile = "lantai" }
    local MODE_TEXT = { lantai = "Mode: Lantai", berdiri = "Mode: Berdiri", tile = "Mode: Tile break" }
    local MODE_COLOR = { lantai = Color3.fromRGB(44, 49, 64), berdiri = C.brk, tile = Color3.fromRGB(214, 120, 50) }
    local ModeBtn = Instance.new("TextButton")
    ModeBtn.Size = UDim2.fromOffset(112, 24)
    ModeBtn.Position = UDim2.new(1, -148, 0, 6)
    ModeBtn.Font = Enum.Font.GothamBold
    ModeBtn.TextSize = 11
    ModeBtn.TextColor3 = Color3.new(1, 1, 1)
    ModeBtn.Parent = Panel
    Instance.new("UICorner", ModeBtn).CornerRadius = UDim.new(0, 6)

    -- lapisan ketuk untuk mode break: menutupi peta, jadi lantai di bawahnya tidak ikut terpilih
    local Tap = Instance.new("TextButton")
    Tap.Text = ""
    Tap.AutoButtonColor = false
    Tap.BackgroundTransparency = 1
    Tap.BorderSizePixel = 0
    Tap.Size = UDim2.fromScale(1, 1)
    Tap.ZIndex = 9
    Tap.Visible = false
    Tap.Parent = Canvas

    local function setMode(m)
        mode = m
        ModeBtn.Text = MODE_TEXT[m]
        ModeBtn.BackgroundColor3 = MODE_COLOR[m]
        Tap.Visible = m ~= "lantai"
        lastTap = nil
        refreshInfo()
    end
    ModeBtn.MouseButton1Click:Connect(function() setMode(MODE_NEXT[mode] or "lantai") end)
    ModeBtn.Text = MODE_TEXT[mode]
    ModeBtn.BackgroundColor3 = MODE_COLOR[mode]

    local downPos = nil
    Tap.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            downPos = Vector2.new(input.Position.X, input.Position.Y)
        end
    end)
    Tap.MouseButton1Click:Connect(function()
        local p = downPos
        downPos = nil
        if not p or dw == 0 or cell <= 0 then return end
        if string.upper(Guard.worldName and Guard.worldName() or "") ~= Pabrik.PickWorld then
            lastTap = "Kembali ke world " .. Pabrik.PickWorld .. " untuk mengubah break"
            refreshInfo()
            return
        end
        local origin = Canvas.AbsolutePosition
        local tx = math.floor((p.X - origin.X) / cell)
        local ty = math.floor((p.Y - origin.Y) / cell)
        if tx < 0 or ty < 0 or tx >= dw or ty >= dh then return end
        if mode == "berdiri" then
            if ty > 0 and Pabrik.floorOk(tx, ty) then ty -= 1 end -- yang diketuk lantainya: berdiri di atasnya
            local ox, oy = Pabrik.BreakX, Pabrik.BreakY
            Pabrik.BreakX, Pabrik.BreakY = tx, ty
            if next(Pabrik.Tiles) == nil then
                Pabrik.Tiles["1,0"] = true
                Pabrik.Tiles["2,0"] = true
            end
            Pabrik._setAt = 0
            local ok, why, part = Pabrik.breakValid()
            if not ok and part == "stand" then
                Pabrik.BreakX, Pabrik.BreakY = ox, oy
                lastTap = ("Tidak bisa berdiri di (%d,%d): %s"):format(tx, ty, tostring(why))
            else
                Pabrik.saveBreak()
                lastTap = ("Titik break (%d,%d). "):format(tx, ty)
                    .. (ok and "Ganti ke Mode Tile break untuk mengubah tile" or ("Perbaiki di Mode Tile break: " .. tostring(why)))
            end
        elseif mode == "tile" then
            if Pabrik.BreakX < 0 then
                lastTap = "Atur titik berdiri dulu (Mode: Berdiri)"
            else
                local dx, dy = tx - Pabrik.BreakX, ty - Pabrik.BreakY
                local key = dx .. "," .. dy
                local w = Refs.World
                if dx == 0 and dy == 0 then
                    lastTap = "Itu titik berdiri. Pilih tile di sebelahnya"
                elseif math.abs(dx) > 2 or math.abs(dy) > 2 then
                    lastTap = "Terlalu jauh: tile break maksimal 2 tile dari titik berdiri"
                elseif Pabrik.Tiles[key] then
                    Pabrik.Tiles[key] = nil
                    Pabrik.saveBreak()
                    lastTap = ("Tile break (%d,%d) dibatalkan"):format(tx, ty)
                else
                    Pabrik.Tiles[key] = true
                    Pabrik.saveBreak()
                    lastTap = ("Tile break (%d,%d) dipilih (tile ini tidak ditanami)"):format(tx, ty)
                end
            end
        end
        refreshInfo()
        pcall(moveMarks)
    end)

    -- tombol bawah: 3 tombol aksi + perkecil / perbesar
    local GAPF, ZW = 6, 34
    local BW = (MAP_W - 2 * ZW - 4 * GAPF) // 3
    local footX = 10
    local function footBtn(text, w, fn)
        local b = Instance.new("TextButton")
        b.Size = UDim2.fromOffset(w, 30)
        b.Position = UDim2.new(0, footX, 1, -38)
        b.BackgroundColor3 = Color3.fromRGB(44, 49, 64)
        b.Font = Enum.Font.GothamBold
        b.TextSize = 12
        b.TextColor3 = Color3.new(1, 1, 1)
        b.Text = text
        b.Parent = Panel
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
        b.MouseButton1Click:Connect(fn)
        footX += w + GAPF
    end
    footBtn("Pindai ulang", BW, function()
        lastTap = nil
        rebuild(false)
    end)
    footBtn("Pilih semua", BW, function()
        if Pabrik.Full then
            lastTap = "Full world nyala: semua lantai sudah dipakai"
            refreshInfo()
            return
        end
        for _, sg in ipairs(segs) do
            if not sg.stale then Pabrik.Pick[sg.key] = true end
        end
        lastTap = nil
        repaint()
    end)
    footBtn("Kosongkan", BW, function()
        if Pabrik.Full then
            lastTap = "Full world nyala. Matikan Full world di tab Pabrik dulu"
            refreshInfo()
            return
        end
        table.clear(Pabrik.Pick)
        lastTap = nil
        repaint()
    end)
    footBtn("-", ZW, function() zoom(-2) end)
    footBtn("+", ZW, function() zoom(2) end)

    UI.openSmartMenu = function()
        Gui.Enabled = true
        lastTap = nil
        rebuild(true)
    end

    -- Selama peta terbuka: posisi bot & break diperbarui; pindah world = peta digambar ulang
    task.spawn(function()
        while alive() do
            task.wait(0.3)
            if Gui.Enabled and not scanning then
                local okS, changed = pcall(Pabrik.syncPick)
                if (okS and changed) or Refs.World ~= drawnW or Pabrik.PickWorld ~= drawnPick then
                    lastTap = nil
                    rebuild(true)
                else
                    pcall(moveMarks)
                end
            end
        end
    end)

    -- Panel bisa digeser lewat judul
    local dragging, dragStart, startPos
    Title.Active = true
    Title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Panel.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            Panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end))
end)() end

---------------------------------------------------------------------
-- AUTO RECONNECT
---------------------------------------------------------------------
-- Cara kerja:
--   Terlempar dari world (event WorldClosed dari server):
--     catat aktivitas -> tunggu -> masuk world yang sama lagi -> lanjut aktivitas.
--   Disconnect dari server Roblox (layar error muncul):
--     catat aktivitas ke file -> teleport ulang ke game dengan data world
--     (game otomatis masuk world itu) -> script jalan lagi -> lanjut aktivitas.
--     Supaya script jalan lagi setelah teleport: isi URL script (queue_on_teleport)
--     atau taruh script di folder autoexec executor.
local Rejoin = {
    On = false,
    World = true,       -- masuk lagi kalau terlempar dari world
    Server = true,      -- rejoin kalau disconnect dari server
    DelaySec = 5,
    ScriptUrl = "",
    LocalFile = "SkyP/SkyP.lua", -- cadangan kalau URL kosong: file script di folder workspace executor
    HookOn = false,     -- webhook khusus rejoin (terpisah dari tab Discord)
    HookUrl = "",
    HookPing = "",      -- v2.1: ID Discord yang di-tag kalau rejoin gagal / dihentikan
    Keep = false,       -- selalu kembali ke world tujuan kalau berada di luar world
    Target = "",        -- world tujuan (kosong = world terakhir)
    Backup = "",        -- v2.1: world cadangan (pisah koma) kalau world tujuan tidak bisa dimasuki
    Watch = true,       -- v2.1: watchdog koneksi macet tanpa layar error
    WatchSec = 90,      -- v2.1: berapa detik tanpa data dari server dianggap macet
    Smart = true,       -- v2.1: baca alasan disconnect (perangkat lain / ban = tidak rejoin)
    MaxPerHour = 10,    -- v2.1: rem, terlempar lebih dari ini dalam 1 jam = berhenti
    Paused = false,     -- v2.1: dihentikan oleh rem
    Hist = {},          -- v2.1: waktu (os.time) tiap rejoin dalam 1 jam terakhir
    LastWorld = "",     -- world terakhir yang dimasuki
    Last = nil,         -- catatan aktivitas terakhir
    LastAt = 0,
    Busy = false,
    Count = 0,
    Status = "-",
}

do (function()
    local HttpService = game:GetService("HttpService")
    local TeleportService = game:GetService("TeleportService")
    local GuiService = game:GetService("GuiService")
    local canFile = type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
    local PENDING = "Fian/rejoin_" .. tostring(LocalPlayer.UserId) .. ".json"

    -- ===== v2.1: catatan rejoin di file (dipakai checkpoint & disconnect) =====
    -- kind: "cp" = checkpoint berkala (untuk crash / app tertutup), "dc" = disconnect terdeteksi
    local function writePending(saved, world, kind)
        if not canFile or world == "" then return end
        local s2 = saved or {}
        local data = {
            world = world, farm = s2.farm, clear = s2.clear, farmer = s2.farmer,
            spam = s2.spam, splice = s2.splice, pabrik = s2.pabrik, build = s2.build,
            tx = s2.tx, ty = s2.ty, at = os.time(), kind = kind, hist = Rejoin.Hist,
        }
        pcall(function()
            if type(makefolder) == "function" and type(isfolder) == "function" and not isfolder("Fian") then makefolder("Fian") end
            writefile(PENDING, HttpService:JSONEncode(data))
        end)
    end
    local function clearPending()
        Rejoin.HasCp = false
        if not canFile or type(delfile) ~= "function" then return end
        pcall(function() if isfile(PENDING) then delfile(PENDING) end end)
    end
    Rejoin.clearPending = clearPending

    -- ===== v2.1: rem, terlalu sering terlempar dalam 1 jam = berhenti (kemungkinan sengaja di-kick) =====
    local function allowRejoin(why)
        if Rejoin.Paused then return false end
        local now = os.time()
        local keep = {}
        for _, t in ipairs(Rejoin.Hist) do
            if type(t) == "number" and now - t < 3600 then keep[#keep + 1] = t end
        end
        keep[#keep + 1] = now
        Rejoin.Hist = keep
        local max = math.max(1, math.floor(tonumber(Rejoin.MaxPerHour) or 10))
        if #keep > max then
            Rejoin.Paused = true
            clearPending()
            Rejoin.Status = ("Berhenti: terlempar %d kali dalam 1 jam"):format(#keep)
            notify("Auto Rejoin", Rejoin.Status .. ". Matikan lalu nyalakan lagi Auto Rejoin untuk lanjut", 8)
            Hook.send("rejoin", Rejoin.Status .. " (" .. tostring(why) .. "). Auto Rejoin dihentikan")
            return false
        end
        return true
    end

    -- ===== v2.1: alasan disconnect yang TIDAK boleh di-rejoin =====
    local STOP_WORDS = { "banned", "diban", "blacklist", "exploit", "cheat", "unexpected client behavior" }
    local function stopReason(msg)
        if not Rejoin.Smart then return nil end
        local code = ""
        pcall(function() code = tostring(GuiService:GetErrorCode()) end)
        local m = string.lower(tostring(msg or ""))
        if string.find(code, "DuplicatePlayer", 1, true) or string.find(m, "another device", 1, true)
            or string.find(m, "different device", 1, true) or string.find(m, "perangkat lain", 1, true) then
            return "akun dibuka di perangkat lain"
        end
        for _, w in ipairs(STOP_WORDS) do
            if string.find(m, w, 1, true) then return "di-kick / diban (" .. w .. ")" end
        end
        return nil
    end

    -- catat aktivitas selagi masih jalan
    task.spawn(function()
        while alive() do
            local now = os.clock()
            local wn = Guard.worldName and Guard.worldName() or ""
            -- v2.2: di layar pilih world nama world masih yang lama: jangan catat apa pun di sana
            local picker = Guard.pickerOpen and Guard.pickerOpen()
            if wn ~= "" and not Pabrik.Traveling and not picker then Rejoin.LastWorld = wn end
            if picker or Pabrik.Traveling then
                -- tetap pakai catatan terakhir dari dalam world (jangan ditimpa / dihapus)
            elseif Guard.anyRunning and Guard.anyRunning() and Guard.Mode == "idle" then
                Rejoin.Last = Guard.snapshot()
                Rejoin.LastAt = now
            elseif now - Rejoin.LastAt > 3 and Guard.Mode == "idle" and wn ~= "" then
                -- masih di world tapi aktivitas dihentikan sendiri: jangan dilanjutkan
                Rejoin.Last = nil
            end
            task.wait(1)
        end
    end)

    -- ===== v2.1: checkpoint tiap 20 detik =====
    -- Kalau Roblox crash / freeze / app ditutup HP (tanpa layar error), begitu script jalan lagi
    -- (autoexec / queue) langsung masuk world terakhir & lanjut aktivitas.
    task.spawn(function()
        while alive() do
            task.wait(20)
            if not alive() then break end
            if Rejoin.On and not Rejoin.Paused and not Rejoin.Leaving and not Rejoin.Busy and not Pabrik.Traveling then
                local wn = Guard.worldName() or ""
                local saved = (Rejoin.Last and Rejoin.Last.world == wn) and Rejoin.Last or nil
                if wn ~= "" and (saved or Rejoin.Keep) then
                    writePending(saved, wn, "cp")
                    Rejoin.HasCp = true
                elseif Rejoin.HasCp and wn ~= "" then
                    clearPending() -- aktivitas dihentikan sendiri: tidak ada yang perlu dilanjutkan
                end
            elseif Rejoin.HasCp and not Rejoin.On then
                clearPending()
            end
        end
        -- script ditutup sendiri (bukan teleport): checkpoint dibuang supaya tidak jalan sendiri nanti
        if not Rejoin.Leaving and Rejoin.HasCp then clearPending() end
    end)

    local function resume(saved, reason)
        Guard.afterEnter()
        Rejoin.Count += 1
        Rejoin.Status = "Masuk lagi berhasil, lanjut aktivitas"
        notify("Auto Rejoin", reason .. ": lanjut aktivitas", 4)
        Hook.send("rejoin", reason .. " ke " .. tostring(saved.world) .. ", aktivitas dilanjutkan")
        Guard.resumeSaved(saved)
    end

    local function finishEnter(world, saved, reason)
        if saved and saved.world == world then
            resume(saved, reason)
        else
            Guard.afterEnter()
            Rejoin.Count += 1
            Rejoin.Status = reason .. " ke " .. world .. " berhasil"
            Hook.send("rejoin", reason .. " ke " .. world)
        end
    end

    function Rejoin.targetWorld()
        local t = tostring(Rejoin.Target or ""):upper():gsub("[^A-Z0-9]", "")
        if t ~= "" then return t end
        return Rejoin.LastWorld or ""
    end

    -- ===== v2.1: masuk world dengan jeda bertingkat + world cadangan =====
    -- return: world yang berhasil dimasuki, atau nil. force = rejoin manual (tidak perlu Auto Rejoin aktif)
    local WAITS = { 8, 15, 30, 60 }
    local function enterWithRetry(world, force)
        local list = { world }
        for w in tostring(Rejoin.Backup or ""):upper():gmatch("[A-Z0-9]+") do
            if w ~= world then list[#list + 1] = w end
        end
        for i, w in ipairs(list) do
            local tries = (i == 1) and 4 or 2
            for try = 1, tries do
                if not alive() or (not force and (not Rejoin.On or Rejoin.Paused)) then return nil end
                local ok, err = Guard.enterWorld(w)
                if ok then return w end
                local wait = WAITS[math.min(try, #WAITS)]
                Rejoin.Status = ("Gagal masuk %s (%d/%d): %s. Coba lagi %d dtk"):format(w, try, tries, tostring(err), wait)
                task.wait(wait)
            end
            if list[i + 1] then
                Hook.send("rejoin", "World " .. w .. " tidak bisa dimasuki, pindah ke world cadangan " .. list[i + 1])
            end
        end
        return nil
    end

    local function enterAndResume(world, saved, reason, force)
        local got = enterWithRetry(world, force)
        if got then
            Rejoin.Stuck = nil
            task.wait(1.5)
            finishEnter(got, saved, reason)
            return true
        end
        -- v2.2: gagal masuk: dicoba lagi otomatis 60 dtk lagi (watchdog layar pilih world)
        Rejoin.Stuck = { world = world, saved = saved, at = os.clock() }
        Rejoin.Status = "Gagal masuk " .. world .. (Rejoin.Backup ~= "" and " & world cadangan" or "")
        notify("Auto Rejoin", Rejoin.Status, 5)
        Hook.send("rejoin", Rejoin.Status)
        return false
    end

    -- ===== terlempar dari world =====
    local function onWorldClosed(msg)
        if not (Rejoin.On and Rejoin.World) or Rejoin.Paused or Rejoin.Busy or Pabrik.Traveling then return end
        if Guard.Mode == "away" or Guard.Mode == "out" then return end -- Penjaga yang keluar
        -- aktivitas yang sedang jalan (kalau ada) dilanjutkan; kalau tidak ada, tetap masuk lagi
        local saved = Rejoin.Last
        if saved and (saved.world == "" or os.clock() - Rejoin.LastAt > 10) then saved = nil end
        local world = (saved and saved.world) or Rejoin.LastWorld or ""
        if world == "" then world = Rejoin.targetWorld() end
        if world == "" then return end
        if not allowRejoin("terlempar dari " .. world) then return end
        Rejoin.Busy = true
        task.spawn(function()
            Guard.stopAll()
            local text = tostring(msg or ""):gsub("`.", "")
            Rejoin.Status = "Terlempar dari " .. world .. ". Masuk lagi..."
            Hook.send("rejoin", "Terlempar dari world " .. world .. (text ~= "" and (" (" .. text .. ")") or ""))
            task.wait(Rejoin.DelaySec + 1.5) -- tunggu animasi pintu selesai
            enterAndResume(world, saved, "Masuk lagi")
            Rejoin.Busy = false
        end)
    end

    -- game v1159+: WorldClosed lewat paket Net (ByteNet), bukan RemoteEvent bernama lagi.
    -- Net.on hanya MENDENGAR (tidak kirim apa pun ke server). Listener tidak bisa dilepas,
    -- jadi dicek alive() supaya script lama yang sudah ditutup tidak ikut jalan.
    local closedHooked = false
    if NetOk and type(Net) == "table" and type(Net.on) == "function"
        and type(Net.EVENTS) == "table" and Net.EVENTS.WorldClosed then
        closedHooked = pcall(Net.on, "WorldClosed", function(msg)
            if alive() then onWorldClosed(msg) end
        end, function()
            local w = Refs.World
            return w and rawget(w, "name") or ""
        end)
    end
    if not closedHooked then
        local closed = WorldRemotes:FindFirstChild("WorldClosed")
        if closed and closed:IsA("RemoteEvent") then
            table.insert(Connections, closed.OnClientEvent:Connect(function(msg)
                if alive() then onWorldClosed(msg) end
            end))
        end
    end

    -- ===== rejoin manual & selalu kembali ke world =====
    Session.rejoinNow = function() return Rejoin.now() end -- v2.3: dipakai Pabrik saat karakter terjebak
    function Rejoin.now()
        if Rejoin.Busy then
            notify("Auto Rejoin", "Sedang proses masuk world, tunggu dulu", 3)
            return
        end
        local world = Rejoin.targetWorld()
        if world == "" then
            notify("Auto Rejoin", "World tujuan belum ada. Isi 'World tujuan' atau masuk world dulu", 4)
            return
        end
        Rejoin.Busy = true
        task.spawn(function()
            local saved = nil
            if Guard.inWorld() then
                if Guard.anyRunning() then saved = Guard.snapshot() end
                Guard.stopAll()
                Rejoin.Status = "Keluar world..."
                if not Guard.leaveWorld() then
                    Rejoin.Status = "Gagal keluar world"
                    notify("Auto Rejoin", Rejoin.Status, 4)
                    Rejoin.Busy = false
                    return
                end
                task.wait(math.max(2, Rejoin.DelaySec))
            elseif Guard.anyRunning() then
                -- v2.2: di layar pilih world tapi aktivitas masih jalan: hentikan dulu, lanjut setelah masuk
                saved = Rejoin.Last or Guard.snapshot()
                Guard.stopAll()
            end
            if saved and saved.world ~= world then saved = nil end -- world lain: aktivitas tidak dilanjutkan
            Rejoin.Status = "Masuk ke " .. world .. "..."
            enterAndResume(world, saved, "Rejoin", true)
            Rejoin.Busy = false
        end)
    end

    task.spawn(function()
        local outSince = nil
        while alive() do
            task.wait(2)
            local out = not Guard.inWorld() -- v2.2: layar pilih world juga dihitung di luar world
            local free = Rejoin.On and Rejoin.Keep and not Rejoin.Paused and not Rejoin.Busy and not Rejoin.Leaving
                and not Pabrik.Traveling and Guard.Mode == "idle"
            if not (out and free) then
                outSince = nil
            else
                outSince = outSince or os.clock()
                local world = Rejoin.targetWorld()
                if world ~= "" and os.clock() - outSince >= Rejoin.DelaySec then
                    outSince = nil
                    if allowRejoin("di luar world") then
                        Rejoin.Busy = true
                        local saved = Rejoin.Last
                        if saved and (saved.world ~= world or os.clock() - Rejoin.LastAt > 600) then saved = nil end
                        Rejoin.Status = "Di luar world, masuk ke " .. world .. "..."
                        enterAndResume(world, saved, "Kembali otomatis")
                        Rejoin.Busy = false
                    end
                end
            end
        end
    end)

    -- ===== v2.2: aktivitas jalan tapi karakter ada di layar pilih world =====
    -- Terjadi kalau terlempar tanpa event WorldClosed, atau masuk world gagal setelah rejoin.
    -- Data world lama masih ada, jadi Pabrik / Farm mengira masih di world dan diam di menu.
    -- Jalan walau "Selalu kembali ke world" mati, asal Auto Rejoin aktif dan ada aktivitas jalan.
    task.spawn(function()
        local since = nil
        while alive() do
            task.wait(2)
            local traveling = Pabrik.Traveling and os.clock() - (Pabrik.TravelAt or 0) < 300
            local free = Rejoin.On and (Rejoin.World or Rejoin.Keep) and not Rejoin.Paused and not Rejoin.Busy
                and not Rejoin.Leaving and not traveling and Guard.Mode == "idle"
            local out = Guard.pickerOpen() or Guard.worldName() == ""
            local st = Rejoin.Stuck
            if st and not out then Rejoin.Stuck, st = nil, nil end -- sudah di world lagi (manual / fitur lain)
            local running = Guard.anyRunning()
            local retry = st and os.clock() - st.at >= 60
            if not (free and out and (running or retry)) then
                since = nil
            else
                since = since or os.clock()
                local stuck = os.clock() - since
                if running then
                    Rejoin.Status = ("Di layar pilih world padahal aktivitas jalan (%d dtk)"):format(math.floor(stuck))
                end
                if retry or stuck >= math.max(10, Rejoin.DelaySec + 5) then
                    since = nil
                    local saved, world = nil, ""
                    if running then
                        saved = Rejoin.Last or Guard.snapshot()
                        if Pabrik.Running and Pabrik.Home ~= "" then world = Pabrik.Home end
                    elseif st then
                        saved, world = st.saved, st.world or ""
                    end
                    if world == "" and saved and saved.world ~= "" then world = saved.world end
                    if world == "" then world = Rejoin.LastWorld or "" end
                    if world == "" then world = Rejoin.targetWorld() end
                    if st then st.at = os.clock() end
                    if world ~= "" and allowRejoin("di layar pilih world") then
                        Rejoin.Busy = true
                        if saved then saved.world = world end
                        Guard.stopAll()
                        Rejoin.Status = "Di layar pilih world, masuk ke " .. world .. "..."
                        Hook.send("rejoin", (running and "Karakter ada di layar pilih world padahal aktivitas jalan"
                            or "Masuk world tadi gagal, dicoba lagi") .. ". Masuk ke " .. world)
                        task.wait(1)
                        enterAndResume(world, saved, "Masuk lagi")
                        Rejoin.Busy = false
                    end
                end
            end
        end
    end)

    -- ===== disconnect dari server =====
    -- PATCH: auto execute lagi setelah teleport (URL raw / file lokal), di-queue juga saat game teleport sendiri
    local function queueScript()
        local q = queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport)
            or (fluxus and fluxus.queue_on_teleport)
        if type(q) ~= "function" then return false, "executor tidak punya queue_on_teleport" end
        local url = tostring(Rejoin.ScriptUrl or "")
        local wait = "if not game:IsLoaded() then game.Loaded:Wait() end task.wait(3) "
        if string.sub(url, 1, 8) == "https://" then
            return pcall(q, wait .. ("loadstring(game:HttpGet(%q))()"):format(url)), "url"
        end
        local f = tostring(Rejoin.LocalFile or "")
        local okF, has = pcall(function() return f ~= "" and isfile and isfile(f) end)
        if okF and has then
            return pcall(q, wait .. ("loadstring(readfile(%q))()"):format(f)), "file"
        end
        return false, "isi URL script / simpan script di " .. f
    end
    Rejoin.queueScript = queueScript
    pcall(function()
        table.insert(Connections, LocalPlayer.OnTeleport:Connect(function(st)
            if alive() and Rejoin.On and st == Enum.TeleportState.Started then queueScript() end
        end))
    end)
    pcall(function()
        table.insert(Connections, TeleportService.TeleportInitFailed:Connect(function(plr, res, msg)
            if alive() and plr == LocalPlayer and Rejoin.Leaving then
                Rejoin.Status = "Teleport gagal (" .. tostring(msg or res) .. "), dicoba lagi"
                Rejoin.RetryNow = true
            end
        end))
    end)

    -- webhook khusus rejoin: embed langsung dikirim (tidak antri, supaya sempat sebelum teleport)
    local function rejoinHook(text)
        if not Rejoin.HookOn or not Hook.valid(Rejoin.HookUrl) then return end
        local req = (syn and syn.request) or (http and http.request) or http_request or request or (fluxus and fluxus.request)
        if not req then return end
        local t = tostring(text)
        local urgent = t:find("Gagal") or t:find("gagal") or t:find("Berhenti") or t:find("Tidak rejoin")
            or t:find("dihentikan") or t:find("belum berhasil")
        local color = urgent and 0xE85468
            or ((t:find("Terlempar") or t:find("Disconnect") or t:find("Macet")) and 0xFFB020 or 0x2F7DFF)
        local ping = (tostring(Rejoin.HookPing or ""):gsub("%D", ""))
        local body = HttpService:JSONEncode({
            username = "SkyP Rejoin",
            content = (urgent and ping ~= "") and ("<@" .. ping .. ">") or nil,
            embeds = { {
                title = "Auto Rejoin",
                description = t,
                color = color,
                fields = {
                    { name = "Akun", value = LocalPlayer.Name, inline = true },
                    { name = "World", value = (Guard.worldName() ~= "" and Guard.worldName()) or (Rejoin.LastWorld ~= "" and Rejoin.LastWorld) or "-", inline = true },
                    { name = "Rejoin berhasil", value = tostring(Rejoin.Count), inline = true },
                },
                footer = { text = os.date("%d/%m/%Y %H:%M:%S") },
            } },
        })
        task.spawn(function()
            pcall(req, { Url = Rejoin.HookUrl, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = body })
        end)
    end
    Hook.onRejoin = rejoinHook

    local function onDisconnect(msg)
        if not (Rejoin.On and Rejoin.Server) or Rejoin.Leaving or Rejoin.Paused then return end
        Rejoin.Leaving = true
        -- v2.1: alasan tertentu (perangkat lain / ban) tidak di-rejoin, supaya tidak saling tendang / makin parah
        local stop = stopReason(msg)
        if stop then
            clearPending()
            Rejoin.Status = "Tidak rejoin: " .. stop
            notify("Auto Rejoin", Rejoin.Status, 8)
            Hook.send("rejoin", "Disconnect (" .. tostring(msg) .. "). Tidak rejoin karena " .. stop)
            return
        end
        if not allowRejoin("disconnect") then return end
        local saved = Rejoin.Last or (Guard.anyRunning() and Guard.snapshot()) or nil
        -- setelah disconnect nama world sudah kosong: pakai world terakhir yang tercatat
        local world = (saved and saved.world) or Rejoin.LastWorld or ""
        if world == "" then world = Guard.worldName() or "" end
        if world == "" then world = Rejoin.targetWorld() end
        writePending(saved, world, "dc")
        local queued, how = queueScript()
        Rejoin.Status = "Disconnect: rejoin..." .. (queued and (" (script di-queue lewat " .. tostring(how) .. ")")
            or (" (script tidak di-queue: " .. tostring(how) .. ", atau pakai autoexec)"))
        Hook.send("rejoin", "Disconnect dari server (" .. tostring(msg) .. "). Rejoin ke " .. (world ~= "" and world or "game"))
        task.spawn(function()
            task.wait(Rejoin.DelaySec)
            local n = 0
            while alive() do
                n += 1
                Rejoin.RetryNow = false
                pcall(function()
                    TeleportService:Teleport(game.PlaceId, LocalPlayer, (world ~= "") and { world = world } or nil)
                end)
                -- v2.1: jeda bertingkat (12, 20, 28 ... maks 60 dtk) supaya tidak kena limit teleport Roblox
                local wait = math.min(60, 12 + (n - 1) * 8)
                local t = os.clock()
                repeat task.wait(0.5) until Rejoin.RetryNow or os.clock() - t > wait
                if Rejoin.RetryNow then task.wait(math.min(30, 3 * n)) end
                if n % 5 == 0 then
                    Hook.send("rejoin", ("Rejoin server belum berhasil (%d percobaan), terus dicoba"):format(n))
                end
            end
        end)
    end

    pcall(function()
        table.insert(Connections, GuiService.ErrorMessageChanged:Connect(function(msg)
            if alive() and type(msg) == "string" and msg ~= "" then onDisconnect(msg) end
        end))
    end)
    -- jalur kedua: layar error Roblox (lebih andal di HP / executor tertentu)
    task.spawn(function()
        local okP, overlay = pcall(function()
            return game:GetService("CoreGui"):WaitForChild("RobloxPromptGui", 15):WaitForChild("promptOverlay", 15)
        end)
        if okP and overlay then
            table.insert(Connections, overlay.ChildAdded:Connect(function(c)
                if alive() and c.Name == "ErrorPrompt" then
                    task.wait(0.5)
                    local m = ""
                    pcall(function() m = GuiService:GetErrorMessage() end)
                    onDisconnect(m ~= "" and m or "ErrorPrompt")
                end
            end))
        end
    end)

    -- ===== v2.1: watchdog koneksi macet (tanpa layar error) =====
    -- Tanda macet: penghubung ke server (ClientReplicator) hilang, atau tidak ada data masuk
    -- dari server selama Rejoin.WatchSec detik. Dianggap disconnect -> rejoin server.
    task.spawn(function()
        local Stats = game:GetService("Stats")
        local net = nil
        pcall(function() net = game:GetService("NetworkClient") end)
        local seenRep, quietSince = false, nil
        while alive() do
            task.wait(3)
            if Rejoin.On and Rejoin.Watch and Rejoin.Server and not Rejoin.Leaving and not Rejoin.Paused then
                local lost = false
                if net then
                    local okR, rep = pcall(function() return net:FindFirstChildOfClass("ClientReplicator") end)
                    if okR and rep then
                        seenRep = true
                    elseif okR and seenRep then
                        lost = true -- pernah ada lalu hilang = koneksi putus
                    end
                end
                local okK, kbps = pcall(function() return Stats.DataReceiveKbps end)
                -- sepi data hanya dihitung saat di dalam world (di layar pilih world memang sepi)
                local quiet = okK and type(kbps) == "number" and kbps < 0.05 and (Guard.worldName() or "") ~= ""
                if lost or quiet then
                    quietSince = quietSince or os.clock()
                    local lim = lost and 10 or math.max(30, tonumber(Rejoin.WatchSec) or 90)
                    if os.clock() - quietSince >= lim then
                        quietSince = nil
                        onDisconnect(lost and "Koneksi ke server hilang"
                            or ("Macet: tidak ada data dari server selama " .. math.floor(lim) .. " dtk"))
                    end
                else
                    quietSince = nil
                end
            else
                quietSince = nil
            end
        end
    end)

    -- ===== setelah execute: lanjutkan dari catatan rejoin / checkpoint =====
    function Rejoin.startup(reconnectFn)
        if not canFile then return end
        local okE, has = pcall(isfile, PENDING)
        if not okE or not has then return end
        local okR, raw = pcall(readfile, PENDING)
        if type(delfile) == "function" then pcall(delfile, PENDING) end
        if not okR or type(raw) ~= "string" then return end
        local okD, saved = pcall(HttpService.JSONDecode, HttpService, raw)
        if not okD or type(saved) ~= "table" or type(saved.world) ~= "string" or saved.world == "" then return end
        if type(saved.hist) == "table" then Rejoin.Hist = saved.hist end
        local isCp = saved.kind == "cp"
        -- checkpoint: hanya kalau Auto Rejoin masih aktif & belum lebih dari 10 menit
        if isCp then
            if not Rejoin.On then return end
            if os.time() - (tonumber(saved.at) or 0) > 10 * 60 then return end
            if not allowRejoin("script jalan lagi setelah crash") then return end
            notify("Auto Rejoin", "Melanjutkan dari checkpoint ke " .. saved.world .. " (matikan Auto Rejoin untuk batal)", 6)
            Hook.send("rejoin", "Script jalan lagi (crash / app tertutup?). Lanjut dari checkpoint ke " .. saved.world)
        elseif os.time() - (tonumber(saved.at) or 0) > 15 * 60 then
            return -- terlalu lama
        end
        Rejoin.Busy = true
        Rejoin.Status = "Rejoin: menunggu masuk " .. saved.world
        -- tunggu game masuk world (lewat data teleport); kalau tidak, masuk sendiri
        local t0 = os.clock()
        local nextTry = t0 + 12
        while alive() and os.clock() - t0 < 120 do
            if isCp and not Rejoin.On then break end -- dibatalkan
            if Refs.World and Guard.inWorld() and Guard.worldName() == saved.world and Auto.here() then break end
            if not Refs.World then pcall(reconnectFn) end
            if Refs.World and os.clock() >= nextTry then -- game tidak langsung masuk: masuk sendiri (diulang)
                nextTry = os.clock() + 20
                Rejoin.Status = "Rejoin: masuk sendiri ke " .. saved.world
                pcall(Guard.enterWorld, saved.world)
            end
            task.wait(2)
        end
        local reason = isCp and "Lanjut dari checkpoint" or "Rejoin server"
        if alive() and Guard.inWorld() and Guard.worldName() == saved.world then
            pcall(reconnectFn)
            task.wait(1)
            if saved.farm or saved.clear or saved.farmer or saved.spam or saved.splice or saved.pabrik or saved.build then
                resume(saved, reason)
            else
                Guard.afterEnter()
                Rejoin.Count += 1
                Rejoin.Status = reason .. " ke " .. saved.world .. " berhasil"
                Hook.send("rejoin", reason .. " ke " .. saved.world)
            end
        elseif not (isCp and not Rejoin.On) then
            Rejoin.Status = "Rejoin: gagal masuk " .. saved.world
            Hook.send("rejoin", Rejoin.Status)
        end
        Rejoin.Busy = false
    end
end)() end

Config.add("Reconnect", Rejoin, { "On", "World", "Server", "DelaySec", "ScriptUrl", "Keep", "Target", "LocalFile", "HookOn", "HookUrl",
    "HookPing", "Backup", "Watch", "WatchSec", "Smart", "MaxPerHour" })
Config.add("Discord", Hook, { "On", "Url", "Penjaga", "Stop", "Full", "Bonus", "Rejoin", "Pabrik", "ReportMin" })

-- ===== TAB: TITIK DROP (dipakai Pabrik, Farmer, Auto Farm) =====
do (function()
    local DTab = makeTab("Titik Drop", "map-pin", "farm")

    safe(function()
        UI.DropPointStatus = DTab:Paragraph({ Title = "Titik Drop", Desc = "-" })
    end)

    local dBox = box(DTab, "Atur titik drop", true)

    safe(function()
        UI.DropWorldInput = dBox:Input({
            Title = "World drop",
            Desc = "Kosong = world ini | WORLD | WORLD:ID (masuk lewat pintu ID)",
            Value = Pabrik.DropWorld,
            Placeholder = "STORAGE:1",
            Callback = function(t) Pabrik.DropWorld = tostring(t or "") end,
        })
    end)

    safe(function()
        dBox:Button({
            Title = "Pakai posisi sekarang untuk drop",
            Desc = "Berdiri di tempat drop (boleh di world lain), lalu tekan",
            Callback = function()
                local x, y = Auto.here()
                if not x then
                    notify("Titik Drop", "Kamu belum masuk world", 3)
                    return
                end
                Pabrik.DropX, Pabrik.DropY = x, y
                -- world ikut diisi, kecuali sudah pakai format WORLD:ID
                if not string.find(Pabrik.DropWorld or "", ":", 1, true) then
                    Pabrik.DropWorld = Guard.worldName()
                    if UI.DropWorldInput then pcall(function() UI.DropWorldInput:Set(Pabrik.DropWorld) end) end
                end
                notify("Titik Drop", ("Posisi drop (%d,%d) di %s"):format(x, y, Pabrik.DropWorld), 4)
            end,
        })
    end)

    safe(function()
        dBox:Button({
            Title = "Hapus posisi drop",
            Desc = "Drop di titik kedatangan (pintu) saja",
            Callback = function()
                Pabrik.DropX, Pabrik.DropY = -1, -1
                notify("Titik Drop", "Posisi drop dihapus", 3)
            end,
        })
    end)

    task.spawn(function()
        while alive() do
            local name, door = Auto.parseDropTarget()
            local here = Guard.worldName()
            local point
            if Pabrik.DropX < 0 and not door and (name == "" or name == here) then
                point = "belum diatur"
            else
                point = (name ~= "" and name or "world ini") .. (door and (" pintu " .. door) or "")
                    .. (Pabrik.DropX >= 0 and (" (" .. Pabrik.DropX .. "," .. Pabrik.DropY .. ")") or " (titik kedatangan)")
            end
            local txt = table.concat({
                "Titik  : " .. point,
                "Dipakai: Pabrik (seed), Farmer & Auto Farm (otomatis saat item ~190)",
                ("Di-drop: Pabrik %d | Farmer %d | Auto Farm %d"):format(Pabrik.Dropped, Farmer.Dropped, State.Dropped),
                "Catatan: drop di titik ini tidak di-collect lagi",
            }, "\n")
            if UI.DropPointStatus and txt ~= UI.DropPointShown then
                UI.DropPointShown = txt
                pcall(function() UI.DropPointStatus:SetDesc(txt) end)
            end
            task.wait(1)
        end
    end)
end)() end

-- ===== TAB: KONEKSI =====
-- ===== DIRT FARM - diadaptasi dari script "AutoDirtFarm" (Blazy) ke SkyP =====
do
    (function()
        local RT = {
            Running = false,
            RunId = 0,
            Phase = "-",
            Status = "-",
            Broken = 0,
            Placed = 0,
            Planted = 0,
            Harvested = 0,
            Dropped = 0,
            Trashed = 0,
        }
        Session.RT = RT

        -- v8: pengaturan yang bisa diubah dari menu (ikut tersimpan di config)
        RT.Batch = 5       -- tile dipukul sekali berdiri saat menggali (1-5)
        RT.DirtStop = 190  -- farming berhenti & kembali menyusun kalau dirt di tas >= angka ini (maks 190)
        RT.FarmRows = 2    -- jumlah koridor galian (dari bawah) yang dipakai untuk farm Dirt Seed
        RT.DoDig, RT.DoLava, RT.DoRows, RT.DoFarm = true, true, true, true
        pcall(Config.add, "DirtFarm", RT, {"Batch", "DirtStop", "FarmRows", "DoDig", "DoLava", "DoRows", "DoFarm"})

        -- pengaturan (sama seperti script asli)
        local MAX_PLAYERS = 1            -- jalan hanya kalau pemain di world <= angka ini
        local PLACE_DIRT_ROWS_DELAY = 0  -- ms, 150 membantu kalau jalan macet
        local DROP_AT = 200              -- drop item kalau jumlahnya >= ini

        local floor, abs = math.floor, math.abs
        RT.Log = {}
        local function logEv(msg)
            local t = RT.Log
            if t[#t] == msg then
                return
            end
            t[#t + 1] = msg
            while #t > 40 do
                table.remove(t, 1)
            end
        end
        local ids = {}
        local skip = {}
        local zoneSet = false

        local function itemIdByName(name)
            local found
            pcall(function()
                for id, item in pairs(ItemDB) do
                    if type(id) == "number" and type(item) == "table" and item.name == name then
                        found = id
                        break
                    end
                end
            end)
            if not found then
                for id = 1, 6000 do
                    local ok, item = pcall(function()
                        return ItemDB[id]
                    end)
                    if ok and type(item) == "table" and item.name == name then
                        found = id
                        break
                    end
                end
            end
            return found
        end

        local function resolveIds()
            ids.platform = itemIdByName("Wooden Platform")
            ids.dirt = itemIdByName("Dirt") or 2
            ids.dirtSeed = itemIdByName("Dirt Seed") or 3
            ids.cave = itemIdByName("Cave Background") or 14
            ids.caveSeed = itemIdByName("Cave Background Seed")
            ids.lava = itemIdByName("Lava") or 4
            ids.lavaSeed = itemIdByName("Lava Seed")
            ids.rock = itemIdByName("Rock") or 10
            ids.rockSeed = itemIdByName("Rock Seed") or 11
            ids.list = {}
            local all = {ids.dirt, ids.dirtSeed, ids.cave, ids.caveSeed, ids.lava, ids.lavaSeed, ids.rock, ids.rockSeed}
            for i = 1, 8 do
                if all[i] then
                    ids.list[#ids.list + 1] = all[i]
                end
            end
        end

        -- 'alive' di bawah menimpa nama fungsi global; simpan yang asli dulu.
        -- Tanpa ini alive(id) memanggil dirinya sendiri terus (stack overflow) dan Dirt Farm macet diam.
        local scriptAlive = alive
        local function alive(id)
            return RT.Running and scriptAlive() and RT.RunId == id
        end

        local function setStatus(t)
            RT.Status = t
        end

        -- ===== baca world =====
        local function dims()
            local W = Refs.World
            if not W then
                return 0, 0
            end
            return W.w, W.h
        end

        local function fgAt(x, y)
            return tileAt("fg", x, y) or 0
        end

        local function bgAt(x, y)
            return tileAt("bg", x, y) or 0
        end

        -- 0 = kosong, 1 = solid, 2 = platform
        local function flagAt(x, y)
            local id = tileAt("fg", x, y)
            if not id or id == 0 then
                return 0
            end
            local it = ItemDB[id]
            if not it then
                return 1
            end
            if it.platform then
                return 2
            end
            if it.kind == "seed" then
                return 0
            end
            if it.solid then
                return 1
            end
            return 0
        end

        local function here()
            local ok, x, y = pcall(Auto.here)
            if ok and x then
                return x, y
            end
            return nil
        end

        local function nearTile(x, y)
            local mx, my = here()
            if not mx then
                return false
            end
            return abs(x - mx) <= 2 and abs(y - my) <= 2
        end

        local function worldName()
            local W = Refs.World
            local n = W and rawget(W, "name")
            return type(n) == "string" and n or ""
        end

        local function playerCount()
            local ok, list = pcall(Guard.playersHere)
            return ((ok and type(list) == "table") and #list or 0) + 1
        end

        local function waitPlayers(id)
            while alive(id) and playerCount() > MAX_PLAYERS do
                setStatus("Menunggu pemain lain keluar dari world...")
                task.wait(1)
            end
            return alive(id)
        end

        local function isSkipped(key)
            local t = skip[key]
            if t and os.clock() < t then
                return true
            end
            skip[key] = nil
            return false
        end

        local function markSkip(key, sec)
            skip[key] = os.clock() + (sec or 60)
        end

        -- v7.6: A* tidak bisa naik tangga platform (lompat lurus di kolom yang sama). Kalau target
        -- ada jauh di atas dan tidak terjangkau, naik lewat tangga kolom 1 / 98 pakai jumpUp,
        -- sambil sesekali coba jalan langsung ke target dari ketinggian yang sudah dicapai.
        local function climbLadder(tx, ty)
            local w, h = dims()
            local mx, my = here()
            if not mx or not my or ty > my - 2 then
                return false
            end
            local cols = {1, w - 2}
            table.sort(cols, function(a, b)
                return math.abs(mx - a) < math.abs(mx - b)
            end)
            for _, xl in ipairs(cols) do
                -- v8.3: tile berdiri di kolom tangga = tile kosong pertama (setinggi karakter atau di
                -- bawahnya) yang punya pijakan: platform, atau lantai dasar world. Dulu hanya dikenali
                -- kalau karakter sudah di atas platform, jadi dari koridor / dasar world karakter
                -- tidak bisa naik lagi.
                local sy
                local tried = 0
                for cy0 = math.max(my - 1, 0), h - 2 do
                    if tried >= 3 then
                        break
                    end
                    local below = flagAt(xl, cy0 + 1)
                    if flagAt(xl, cy0) == 0 and (below == 1 or below == 2) and fgAt(xl, cy0 + 1) ~= ids.lava then
                        tried = tried + 1
                        local okw, rw = pcall(Auto.walkTo, xl, cy0, 20)
                        if okw and rw == true then
                            sy = cy0
                            break
                        end
                    end
                end
                if sy then
                    logEv("naik tangga x=" .. xl .. " dari y=" .. sy .. " menuju y=" .. ty)
                    local cy = sy
                    for _ = 1, 40 do
                        if cy <= ty + 1 then
                            break
                        end
                        -- platform tepat di atas kepala (lompat 2), atau satu tile lebih tinggi
                        -- (lompat 3: platform pertama dari dasar)
                        local ny
                        if flagAt(xl, cy - 1) == 2 and flagAt(xl, cy - 2) == 0 then
                            ny = cy - 2
                        elseif flagAt(xl, cy - 1) == 0 and flagAt(xl, cy - 2) == 2 and flagAt(xl, cy - 3) == 0 then
                            ny = cy - 3
                        else
                            break
                        end
                        local okj, rj = pcall(Auto.jumpUp, xl, ny)
                        if not (okj and rj == true) then
                            -- lompatan kadang meleset: coba sekali lagi dari tile berdiri yang sama
                            task.wait(0.2)
                            pcall(Auto.walkTo, xl, cy, 5)
                            okj, rj = pcall(Auto.jumpUp, xl, ny)
                        end
                        if not (okj and rj == true) then
                            logEv("naik tangga gagal di (" .. xl .. "," .. cy .. ") -> y=" .. ny)
                            break
                        end
                        cy = ny
                        if cy - ty <= 8 or cy <= ty + 1 then
                            if xl == tx and cy == ty then
                                return true
                            end
                            local okt, rt = pcall(Auto.walkTo, tx, ty, 20)
                            if okt and rt == true then
                                return true
                            end
                        end
                    end
                end
            end
            return false
        end

        -- v7.6: turun lewat tangga: dari platform tangga jalan keluar ke kolom 0 / 99 (kosong),
        -- jatuh sampai dasar, lalu jalan ke target dari sana.
        local function descendLadder(tx, ty)
            local w = dims()
            local mx, my = here()
            -- v8.3: saat menyusun / farm (RT.ShortDrop), tujuan 1-2 baris di bawah juga lewat sini:
            -- turun ke dasar, lalu goTo berikutnya naik tangga sampai setinggi tujuan. Dulu tujuan
            -- sedekat itu tidak punya jalan sama sekali (mis. dari atas tanah ke koridor pertama).
            -- Saat menggali aturan lama tetap dipakai (turun lewat lubang di ujung baris).
            if not mx or not my or ty <= my or (not RT.ShortDrop and ty < my + 3) then
                return false
            end
            local cols = {1, w - 2}
            table.sort(cols, function(a, b)
                return math.abs(mx - a) < math.abs(mx - b)
            end)
            for _, xl in ipairs(cols) do
                local side = (xl < w / 2) and -1 or 1
                local outer = xl + side
                if outer >= 0 and outer < w and fgAt(outer, my) == 0 then
                    local sy
                    if flagAt(xl, my + 1) == 2 then
                        sy = my
                    elseif flagAt(xl, my) == 2 then
                        sy = my - 1
                    end
                    if sy and fgAt(xl, sy) == 0 then
                        local okw = true
                        if not (mx == xl and my == sy) then
                            local o, r = pcall(Auto.walkTo, xl, sy, 20)
                            okw = o and r == true
                        end
                        if okw then
                            logEv("turun tangga: keluar dari tepi platform x=" .. xl .. " ke kolom " .. outer .. " (y=" .. sy .. ")")
                            local okd, rd = pcall(Auto.dropOff, xl, side)
                            if okd and rd == true then
                                local okt, rt = pcall(Auto.walkTo, tx, ty, 20)
                                if okt and rt == true then
                                    return true
                                end
                                -- sudah di dasar: coba lagi lewat jalur biasa nanti
                                logEv("turun tangga ok, tapi jalan ke (" .. tx .. "," .. ty .. ") masih gagal")
                                return false
                            else
                                logEv("turun tangga gagal di x=" .. xl)
                            end
                        end
                    end
                end
            end
            return false
        end

        local goFail = 0
        local function goTo(x, y)
            if goFail > 0 then
                pcall(table.clear, Auto.BadEdge)
            end
            local ok, res = pcall(Auto.walkTo, x, y, 20)
            if ok and res == true then
                goFail = 0
                return true
            end
            if climbLadder(x, y) or descendLadder(x, y) then
                goFail = 0
                return true
            end
            goFail = goFail + 1
            task.wait(0.6)
            setStatus("Gagal jalan ke (" .. x .. "," .. y .. ") - jalur buntu / tidak terjangkau")
            local mx, my = here()
            if goFail <= 3 or goFail % 10 == 0 then
                logEv("goTo gagal x" .. goFail .. " (" .. x .. "," .. y .. ") dari (" .. tostring(mx) .. "," .. tostring(my) .. ")")
            end
            return false
        end

        -- ===== aksi =====
        local function punch(x, y)
            local ok, r = pcall(tryBreak, x, y, true)
            if not ok then
                r = nil
            end
            if r == "broke" then
                RT.Broken = RT.Broken + 1
            end
            task.wait(0.18)
            return r
        end

        local function place(x, y, id)
            if not id or invCount(id) <= 0 then
                return false
            end
            local it = ItemDB[id]
            local layer = (it and it.background) and "bg" or "fg"
            if tileAt(layer, x, y) ~= 0 then
                return false
            end
            sendSetTile(layer, x, y, id)
            pcall(function()
                Refs.Inv:remove(id, 1)
            end)
            PlacedAt[x .. "," .. y] = os.clock()
            RT.Placed = RT.Placed + 1
            task.wait(0.11)
            return true
        end

        -- ===== inventori & drop di tanah =====
        local function count(id)
            if not id then
                return 0
            end
            return invCount(id)
        end

        local function objs()
            if not Drops.list then
                pcall(findDropRefs)
            end
            local out = {}
            local list = Drops.list
            if type(list) == "table" then
                for _, o in ipairs(list) do
                    if type(o) == "table" and type(o.x) == "number" and type(o.y) == "number" and (o.n or 0) > 0 and not o.display and o.id ~= 112 then
                        out[#out + 1] = o
                    end
                end
            end
            return out
        end

        local function floatingAmount(id)
            local n = 0
            for _, o in ipairs(objs()) do
                if o.id == id then
                    n = n + o.n
                end
            end
            return n
        end

        local function walkToObj(id)
            for _, o in ipairs(objs()) do
                if o.id == id then
                    local key = "o" .. tostring(o.uid)
                    if not isSkipped(key) then
                        -- v8.3: dua kali. Percobaan pertama bisa hanya sampai "turun ke dasar",
                        -- percobaan kedua naik tangga ke ketinggian drop.
                        local ox, oy = floor(o.x), floor(o.y)
                        if not goTo(ox, oy) and not goTo(ox, oy) then
                            markSkip(key, 30)
                        end
                        return true
                    end
                end
            end
            return false
        end

        local function unobstObjects()
            local out = {}
            for _, o in ipairs(objs()) do
                local f = flagAt(floor(o.x), floor(o.y))
                if f == 0 or f == 2 then
                    out[#out + 1] = o
                end
            end
            return out
        end

        local function countPlaced(id)
            if not id then
                return 0
            end
            local w, h = dims()
            local n = 0
            for y = 0, h - 1 do
                for x = 0, w - 1 do
                    if fgAt(x, y) == id then
                        n = n + 1
                    end
                end
            end
            return n
        end

        -- v8.1: cari item platform untuk tangga. Nama di game bisa beda dari "Wooden Platform",
        -- jadi kandidat = nama persis, nama yang mengandung "platform", atau item bersifat platform.
        -- Dipilih yang ada di tas, lalu yang sudah terpasang di world.
        -- return: id, nama, daftar nama mirip (untuk pesan kalau tidak ketemu)
        local function findPlatformId()
            pcall(function()
                if Session.scanItemDB then
                    Session.scanItemDB()
                end
            end)
            local exact = itemIdByName("Wooden Platform")
            local cands, similar = {}, {}
            pcall(function()
                for id, it in pairs(ItemDB) do
                    if type(id) == "number" and type(it) == "table" and type(it.name) == "string" then
                        local nm = string.lower(it.name)
                        local isSeed = it.kind == "seed" or string.find(nm, "seed", 1, true) ~= nil
                        local byName = string.find(nm, "platform", 1, true) ~= nil
                        if not isSeed and not it.background and (id == exact or it.platform or byName) then
                            local sc = (id == exact and 100 or 0) + (it.platform and 20 or 0) + (byName and 10 or 0)
                                + (string.find(nm, "wood", 1, true) and 1 or 0)
                            cands[#cands + 1] = {id = id, name = it.name, sc = sc}
                        elseif not isSeed and #similar < 6 and (string.find(nm, "plat", 1, true) or string.find(nm, "ladder", 1, true)
                            or string.find(nm, "tangga", 1, true) or string.find(nm, "scaffold", 1, true)) then
                            similar[#similar + 1] = it.name
                        end
                    end
                end
            end)
            if #cands == 0 then
                if exact then
                    return exact, "Wooden Platform", similar
                end
                return nil, nil, similar
            end
            local best
            for _, c in ipairs(cands) do
                if invCount(c.id) > 0 then
                    c.sc = c.sc + 1000
                end
            end
            table.sort(cands, function(a, b)
                return a.sc > b.sc
            end)
            best = cands[1]
            -- tidak ada di tas: mungkin tangga sudah terpasang dari run sebelumnya
            if best.sc < 1000 and #cands > 1 then
                for i = 1, math.min(#cands, 8) do
                    if countPlaced(cands[i].id) > 0 then
                        best = cands[i]
                        break
                    end
                end
            end
            return best.id, best.name, similar
        end

        local function isItemToDrop()
            for _, id in ipairs(ids.list) do
                if count(id) >= DROP_AT then
                    return true
                end
            end
            return false
        end

        local function dropItem(id, n)
            n = n or count(id)
            if n <= 0 then
                return
            end
            local hud = Refs.Hud
            local f = hud and rawget(hud, "onDrop")
            if type(f) ~= "function" then
                setStatus("Fungsi drop game tidak ketemu")
                return
            end
            local mx, my = here()
            if mx then
                -- supaya item yang baru di-drop tidak diambil lagi
                Pabrik.Zone = {world = worldName(), x = mx + 0.5, y = my + 0.5}
                zoneSet = true
            end
            local left, tries = n, 0
            while left > 0 and tries < 3 do
                tries = tries + 1
                local before = count(id)
                pcall(f, id, math.min(left, 200))
                task.wait(0.7)
                local gone = before - count(id)
                if gone > 0 then
                    left = left - gone
                    RT.Dropped = RT.Dropped + gone
                end
            end
        end

        local function dropFull()
            for _, id in ipairs(ids.list) do
                if count(id) >= DROP_AT then
                    dropItem(id, count(id))
                end
            end
        end

        local function trashFull(amount)
            for _, id in ipairs(ids.list) do
                local n = count(id)
                if n >= amount then
                    local ok = pcall(Bag.recycle, id, n)
                    if ok then
                        RT.Trashed = RT.Trashed + n
                    end
                    task.wait(1)
                end
            end
        end

        local function anyTrash(amount)
            for _, id in ipairs(ids.list) do
                if count(id) >= amount then
                    return true
                end
            end
            return false
        end

        -- ===== tahap 1-4: bersihkan tepi & pasang platform =====
        local function clearSide(x0, x1)
            for y = 0, 53 do
                for x = x0, x1 do
                    local key = "c" .. x .. "," .. y
                    if not isSkipped(key) then
                        local solid = flagAt(x, y) == 1
                        if solid or bgAt(x, y) ~= 0 then
                            local sy = solid and (y - 1) or y
                            if nearTile(x, sy) then
                                if punch(x, y) == nil then
                                    markSkip(key, 60)
                                end
                            elseif not goTo(x, sy) then
                                markSkip(key, 30)
                            end
                            return true
                        end
                    end
                end
            end
            return false
        end

        local platSel, platSame = nil, 0

        -- v7.6: baris permukaan tanah (tile solid pertama dari atas) di kolom sebelah dalam tangga.
        -- Platform tangga harus satu paritas dengan baris ini supaya platform teratas sejajar tanah.
        local function groundRow(x)
            local w, h = dims()
            local ix = (x < w / 2) and (x + 1) or (x - 1)
            for gy = 0, h - 1 do
                if flagAt(ix, gy) == 1 then
                    return gy
                end
            end
            return nil
        end

        -- v7.6: tangga dihitung dari DASAR ke atas (bukan dari tile tertinggi yang punya pijakan).
        -- Kalau ada sisa platform di bagian atas (dari run sebelumnya), pemilihan dari atas keliru
        -- mengira tangga sudah jadi dan menyuruh karakter ke (x,2) yang tidak terjangkau.
        -- Return y tile berdiri berikutnya (di atas platform teratas rantai dari dasar).
        local function ladderStand(x)
            local _, h = dims()
            local L
            for y = h - 2, 0, -1 do
                if fgAt(x, y) == 0 and flagAt(x, y + 1) == 1 then
                    L = y
                    break
                end
            end
            if not L then
                return nil
            end
            local y = L
            for _ = 1, 80 do
                if y - 1 >= 0 and fgAt(x, y - 1) == ids.platform then
                    y = y - 2
                elseif y - 2 >= 0 and fgAt(x, y - 1) == 0 and fgAt(x, y - 2) == ids.platform then
                    y = y - 3
                else
                    break
                end
            end
            return y
        end

        local function placePlatformsCol(x)
            local _, h = dims()
            local y0 = ladderStand(x)
            if y0 and y0 <= 2 then
                setStatus("Tangga platform x=" .. x .. " sudah sampai atas")
                logEv("tangga x=" .. x .. " sudah sampai atas (berdiri y=" .. y0 .. ")")
                return false
            end
            if y0 and (fgAt(x, y0) ~= 0 or y0 < 0) then
                y0 = nil
            end
            for y = (y0 or 0), (y0 or (h - 1)) do
                local below = flagAt(x, y + 1)
                if fgAt(x, y) == 0 and (below == 1 or below == 2) then
                    local mx, my = here()
                    -- sudah di puncak tangga: tidak bisa pasang lebih tinggi lagi
                    if mx == x and my == y and my <= 2 then
                        setStatus("Tangga platform sampai puncak di (" .. x .. "," .. y .. ")")
                        logEv("tangga x=" .. x .. " sampai puncak di y=" .. y)
                        return false
                    end
                    -- pengaman: tile yang sama terpilih berulang tanpa kemajuan
                    local sel = x .. "," .. y
                    if sel == platSel then
                        platSame = platSame + 1
                    else
                        platSel, platSame = sel, 0
                    end
                    if platSame >= 8 then
                        setStatus("Tahap platform berhenti: tidak ada kemajuan di (" .. sel .. ")")
                        logEv("tangga x=" .. x .. " BERHENTI: tidak ada kemajuan di (" .. sel .. "), posisi (" .. tostring(mx) .. "," .. tostring(my) .. "), platform terpasang " .. countPlaced(ids.platform))
                        platSel, platSame = nil, 0
                        return false
                    end
                    if mx == x and my == y and my > 2 then
                        local py = y - 1
                        if below == 1 then
                            -- platform pertama dari dasar: samakan paritas dengan tanah.
                            -- Kalau meleset 1 tile, naikkan satu tile (jarak 3 sekali saja).
                            local g = groundRow(x)
                            if g and (py - g) % 2 ~= 0 and y - 2 >= 0 then
                                py = y - 2
                            end
                            logEv("platform pertama (" .. x .. "," .. py .. "), tanah y=" .. tostring(g))
                        end
                        if not place(x, py, ids.platform) then
                            if count(ids.platform) <= 0 then
                                setStatus("Platform di tas habis, berhenti di (" .. x .. "," .. y .. ")")
                            else
                                setStatus("Gagal pasang platform di (" .. x .. "," .. (y - 1) .. ") - tile terisi?")
                            end
                            return false
                        end
                    else
                        if fgAt(x, 2) == ids.platform then
                            logEv("tangga x=" .. x .. " selesai: platform ada di y=2")
                            return false
                        end
                        -- v7.3: naik lurus di kolom yang sama = lompat manual (A* tidak bisa)
                        local climbed = false
                        if mx == x and my and y < my and my - y <= 3 and Auto.jumpUp then
                            local okc, resc = pcall(Auto.jumpUp, x, y)
                            climbed = okc and resc == true
                            logEv("naik tangga (" .. x .. "," .. my .. ") -> (" .. x .. "," .. y .. "): " .. (climbed and "ok" or "gagal"))
                        end
                        if not climbed and not goTo(x, y) then
                            task.wait(0.5)
                        end
                    end
                    return true
                end
            end
            return false
        end

        -- ===== gerakan baris (adaptasi "Auto DF 5 Tile") =====
        -- Dari ATAS ke BAWAH, per baris. Berdiri 2 tile di atas baris target,
        -- lalu break sampai 5 tile sekaligus dari satu posisi. Arah sapu zig-zag:
        -- mulai dari ujung baris yang paling dekat dengan karakter.
        local BATCH = 5
        local batchHits = {}

        -- isTarget(x,y)      : tile ini target?
        -- onBroken(x,y)      : dipanggil tiap tile selesai dipecah (boleh nil)
        -- altStand(ax,ty,cx) : posisi berdiri cadangan (boleh nil)
        local function batchBreakStep(prefix, isTarget, x0, x1, onBroken, altStand)
            local w, h = dims()
            x1 = math.min(x1, w - 1)
            local mx, my = here()

            -- baris paling atas yang masih punya target
            local ty, xs
            for y = 0, h - 1 do
                local row
                for x = x0, x1 do
                    if isTarget(x, y) and not isSkipped(prefix .. x .. "," .. y) then
                        row = row or {}
                        row[#row + 1] = x
                    end
                end
                if row then
                    ty, xs = y, row
                    break
                end
            end
            if not ty then
                return false
            end

            local minX, maxX = xs[1], xs[#xs]
            local leftToRight = true
            if mx and abs(mx - maxX) < abs(mx - minX) then
                leftToRight = false
            end
            local anchor = leftToRight and minX or maxX
            local half = floor(BATCH / 2)
            local center = leftToRight and (minX + half) or (maxX - half)
            center = math.max(x0, math.min(x1, center))

            local pending = {}
            for _, x in ipairs(xs) do
                if x >= center - half and x <= center + half then
                    pending[#pending + 1] = x
                end
            end

            -- v8.3: posisi berdiri harus tile kosong. Lava di baris lantai: 2 tile di atasnya adalah
            -- baris lantai lain (padat), jadi posisi itu dibuang dan dipakai posisi cadangan.
            local spots = {}
            local function addSpot(sx, sy)
                if sx and sy and sy >= 0 and flagAt(sx, sy) == 0 and fgAt(sx, sy) ~= ids.lava then
                    spots[#spots + 1] = {sx, sy}
                end
            end
            addSpot(center, math.max(ty - 2, 0))
            if altStand then
                local ax, ay, bx, by = altStand(anchor, ty, center)
                addSpot(ax, ay)
                addSpot(bx, by)
            end

            -- sudah di posisi berdiri: break semua target dalam jangkauan
            for _, sp in ipairs(spots) do
                if mx == sp[1] and my == sp[2] then
                    local did = false
                    for _, x in ipairs(pending) do
                        if nearTile(x, ty) then
                            did = true
                            local key = prefix .. x .. "," .. ty
                            local r = punch(x, ty)
                            if r == nil then
                                markSkip(key, 60)
                            else
                                batchHits[key] = (batchHits[key] or 0) + 1
                                if batchHits[key] > 60 then
                                    batchHits[key] = nil
                                    markSkip(key, 60)
                                elseif onBroken and not isTarget(x, ty) then
                                    onBroken(x, ty)
                                end
                            end
                        end
                    end
                    if did then
                        return true
                    end
                end
            end

            -- belum di posisi: jalan dulu
            for _, sp in ipairs(spots) do
                if not (mx == sp[1] and my == sp[2]) and goTo(sp[1], sp[2]) then
                    return true
                end
            end
            markSkip(prefix .. anchor .. "," .. ty, 30)
            return true
        end

        -- ===== tahap 4b: deteksi lava, break dulu sebelum gali =====
        -- Cari tile berdiri yang aman (kosong, bukan lava, ada pijakan non-lava di bawah)
        local function lavaStandSpot(x, y)
            local cands = {
                {x + 1, y - 1}, {x - 1, y - 1}, {x, y - 1},
                {x + 1, y}, {x - 1, y}, {x + 1, y - 2}, {x - 1, y - 2},
                {x + 2, y - 1}, {x - 2, y - 1},
            }
            local mx, my = here()
            -- v8.3: dua pilihan terdekat (kiri & kanan lava), supaya kalau satu sisi tidak
            -- terjangkau sisi lainnya masih dicoba
            local good = {}
            for _, c in ipairs(cands) do
                local sx, sy = c[1], c[2]
                if sx >= 0 and sy >= 0
                    and fgAt(sx, sy) ~= ids.lava
                    and flagAt(sx, sy) == 0
                    and fgAt(sx, sy + 1) ~= ids.lava
                    and flagAt(sx, sy + 1) ~= 0 then
                    good[#good + 1] = {sx, sy, mx and (abs(sx - mx) + abs(sy - my)) or #good}
                end
            end
            if #good > 0 then
                table.sort(good, function(a, b)
                    return a[3] < b[3]
                end)
                local a, b = good[1], good[2]
                if b then
                    return a[1], a[2], b[1], b[2]
                end
                return a[1], a[2]
            end
            return x + 1, y - 1 -- cadangan (sama seperti versi lama)
        end

        -- ===== tutup lubang bekas lava (tidak ada fitur terbang, jadi jangan sampai jatuh) =====
        local lavaPending = {}

        -- block penutup: dirt dulu, lalu rock (platform disimpan untuk tangga)
        local function fillBlockId()
            for _, bid in ipairs({ids.dirt, ids.rock}) do
                if bid and count(bid) > 0 then
                    return bid
                end
            end
            return nil
        end

        local function fillHole(x, y)
            local bid = fillBlockId()
            if not bid then
                return false
            end
            for _ = 1, 5 do
                local cur = fgAt(x, y)
                if cur ~= 0 then
                    return cur ~= ids.lava -- sudah terisi block lain = aman
                end
                if place(x, y, bid) then
                    return true
                end
                task.wait(0.15)
            end
            return false
        end

        -- true = masih ada lava / lubang yang diproses, false = aman
        local function lavaFirstStep()
            if not ids.lava then
                return false
            end
            local w, h = dims()
            local mx, my = here()

            -- 1) tutup dulu lubang bekas lava yang belum sempat ditutup
            for i = #lavaPending, 1, -1 do
                local p = lavaPending[i]
                if fgAt(p.x, p.y) ~= 0 then
                    table.remove(lavaPending, i)
                elseif fillBlockId() then
                    setStatus("Menutup lubang bekas lava di (" .. p.x .. "," .. p.y .. ")")
                    if nearTile(p.x, p.y) then
                        if fillHole(p.x, p.y) then
                            table.remove(lavaPending, i)
                        else
                            markSkip("h" .. p.x .. "," .. p.y, 20)
                            table.remove(lavaPending, i)
                        end
                    else
                        local hx, hy = lavaStandSpot(p.x, p.y)
                        if not goTo(hx, hy) then
                            table.remove(lavaPending, i)
                        end
                    end
                    return true
                end
            end

            -- 2) v8.3: tanpa block penutup, lava yang di bawahnya padat tetap dipecah (lubangnya
            -- cuma sedalam 1 tile, aman) dan ditutup nanti begitu ada dirt. Lava yang di bawahnya
            -- kosong / lava lagi ditunda sampai ada block penutup.
            local canFill = fillBlockId() ~= nil

            -- 3) break lava dari baris teratas, tiap pecah langsung ditutup
            setStatus(canFill and "Break lava dari atas, lalu tutup dengan dirt"
                or "Break lava (belum ada dirt di tas, lubang ditutup nanti)")
            return batchBreakStep("l", function(x, y)
                if fgAt(x, y) ~= ids.lava then
                    return false
                end
                return canFill or (flagAt(x, y + 1) == 1 and fgAt(x, y + 1) ~= ids.lava)
            end, 0, w - 1, function(x, y)
                if fgAt(x, y) == 0 and not fillHole(x, y) and fgAt(x, y) == 0 then
                    lavaPending[#lavaPending + 1] = {x = x, y = y}
                end
            end, function(ax, ty)
                return lavaStandSpot(ax, ty)
            end)
        end

        -- tutup lubang bekas lava (dipakai setelah mesin Clear World memecah lava)
        local function lavaFillStep()
            for i = #lavaPending, 1, -1 do
                local p = lavaPending[i]
                if fgAt(p.x, p.y) ~= 0 then
                    table.remove(lavaPending, i)
                elseif not fillBlockId() then
                    setStatus("Block penutup habis, sisa lubang bekas lava dilewati")
                    for j = #lavaPending, 1, -1 do
                        table.remove(lavaPending, j)
                    end
                    return false
                else
                    setStatus("Menutup lubang bekas lava di (" .. p.x .. "," .. p.y .. ")")
                    if nearTile(p.x, p.y) then
                        fillHole(p.x, p.y)
                        table.remove(lavaPending, i)
                    else
                        local hx, hy = lavaStandSpot(p.x, p.y)
                        if not goTo(hx, hy) then
                            table.remove(lavaPending, i)
                        end
                    end
                    return true
                end
            end
            return false
        end

        -- ===== tahap 5: gali cave =====
        local function dirtFarmStep()
            setStatus("Gali cave dari atas (5 tile per posisi)")
            return batchBreakStep("d", function(x, y)
                return y >= 1 and bgAt(x, y) == ids.cave and bgAt(x, y - 1) == ids.cave
            end, 2, 97)
        end

        local function afterDirtFarm()
            if isItemToDrop() then
                task.wait(0.5)
                local _, my = here()
                if my then
                    goTo(97, my)
                end
                task.wait(2)
                dropFull()
                task.wait(2)
            end
        end

        -- ===== tahap 6: ganti lava dengan dirt =====
        local function breakLavaStep()
            local w, h = dims()
            for y = 0, h - 1 do
                for x = 0, w - 1 do
                    if fgAt(x, y) == ids.lava then
                        local key = "l" .. x .. "," .. y
                        if not isSkipped(key) then
                            local mx, my = here()
                            if mx == x + 1 and my == y - 1 then
                                if punch(x, y) == nil then
                                    markSkip(key, 60)
                                end
                            elseif not goTo(x + 1, y - 1) then
                                markSkip(key, 30)
                            end
                            return true
                        end
                    elseif y > 44 and x >= 1 and x <= 97 then
                        local f = flagAt(x, y)
                        if (f == 1 or f == 2) and fgAt(x + 1, y) == 0 then
                            local key = "p" .. x .. "," .. y
                            if not isSkipped(key) then
                                local mx, my = here()
                                if mx == x + 2 and my == y - 1 then
                                    if not place(x + 1, y, ids.dirt) then
                                        markSkip(key, 30)
                                    end
                                elseif not goTo(x + 2, y - 1) then
                                    markSkip(key, 30)
                                end
                                return true
                            end
                        end
                    end
                end
            end
            return false
        end

        local function afterLava(id)
            if count(ids.lava) >= 200 then
                local _, my = here()
                if my then
                    goTo(98, my)
                end
                task.wait(2)
                dropItem(ids.lava)
                if ids.lavaSeed then
                    dropItem(ids.lavaSeed)
                end
            end
            local tries = 0
            while alive(id) and count(ids.dirt) == 0 and floatingAmount(ids.dirt) > 0 and playerCount() <= MAX_PLAYERS and tries < 10 do
                tries = tries + 1
                walkToObj(ids.dirt)
                task.wait(2)
            end
        end

        -- ===== tahap 7: kumpulkan dirt lewat tanam & panen dirt seed =====
        -- ===== v7: gerakan ala script referensi (Auto DF) =====
        -- false = pakai cara lama v6
        local USE_REF_DF = true    -- gali serpentin: berdiri 2 tile di atas target, kiri->kanan lalu kanan->kiri
        local USE_REF_ROWS = true  -- susun dirt: berdiri di (x, y+1), taruh di (x, y); y = 22, 20, ... 2
        local REF_ROW_START_Y, REF_ROW_TOP_Y, REF_ROW_STEP_Y = 22, 1, 2
        local REF_ROW_X0, REF_ROW_X1 = 2, 97
        local DF_MAX_HIT = 100
        -- v8: tile dipukul sekali berdiri, dari menu (jangkauan pukul 2 tile ke samping = maks 5)
        local function dfBatch()
            return math.max(1, math.min(5, floor(tonumber(RT.Batch) or 5)))
        end
        -- v7.1: tangga platform dipasang setelah menggali tepi dari atas ke dasar. Tanpa platform
        -- karakter terjebak di dasar world, jadi cek dulu SEBELUM memecah apa pun.
        local PLATFORM_NEED = 52 -- 26 kiri + 26 kanan
        local PR = {Y = nil, X = nil, Done = false, Starve = 0}
        local function prReset()
            PR.Y, PR.X, PR.Done, PR.Starve = nil, nil, false, 0
        end

        local function canEndDirtRows()
            if USE_REF_ROWS then
                return PR.Done == true
            end
            return fgAt(97, 22) ~= 0
        end

        local function treeReady(x, y, id)
            local ok, t = pcall(Auto.treeReadyAt, x, y, id)
            return ok and t ~= nil and workspace:GetServerTimeNow() >= t
        end

        local function hasHarvestable(seed)
            local w, h = dims()
            for y = 0, h - 1 do
                for x = 0, w - 1 do
                    if fgAt(x, y) == seed and treeReady(x, y, seed) then
                        return true
                    end
                end
            end
            return false
        end

        -- return: ada aksi?, jumlah seed yang ditanam
        local function plantStep(seed)
            local w, h = dims()
            for y = h - 1, 23, -1 do -- v8.3: dari koridor paling bawah (dekat dasar, hemat naik tangga)
                for x = 2, math.min(97, w - 1) do -- v8: kolom tangga (0-1, 98-99) tidak ditanami
                    local below = flagAt(x, y + 1)
                    if fgAt(x, y) == 0 and (below == 1 or below == 2) then
                        local key = "t" .. x .. "," .. y
                        if not isSkipped(key) and Auto.plantSpotOk(x, y, seed) then
                            local mx, my = here()
                            if mx == x and my == y then
                                local n = 0
                                -- v8.3: x + 1 tidak boleh masuk kolom tangga (pohon di kaki tangga
                                -- membuat tangga tidak bisa dipakai)
                                if x + 1 <= 97 and fgAt(x + 1, y) == 0 and Auto.plantSpotOk(x + 1, y, seed) then
                                    if place(x + 1, y, seed) then
                                        n = n + 1
                                    end
                                end
                                if place(x, y, seed) then
                                    n = n + 1
                                end
                                if n == 0 then
                                    markSkip(key, 30)
                                end
                                RT.Planted = RT.Planted + n
                                return true, n
                            elseif not goTo(x, y) then
                                markSkip(key, 30)
                            end
                            return true, 0
                        end
                    end
                end
            end
            return false, 0
        end

        local function harvestStep(seed)
            local w, h = dims()
            for y = h - 1, 23, -1 do -- v8.3: urutan sama dengan tanam
                for x = 0, w - 1 do
                    if fgAt(x, y) == seed and treeReady(x, y, seed) then
                        local key = "h" .. x .. "," .. y
                        if not isSkipped(key) then
                            local mx, my = here()
                            if mx == x and my == y then
                                if fgAt(x + 1, y) == seed and treeReady(x + 1, y, seed) then
                                    punch(x + 1, y)
                                    RT.Harvested = RT.Harvested + 1
                                end
                                if punch(x, y) == nil then
                                    markSkip(key, 60)
                                else
                                    RT.Harvested = RT.Harvested + 1
                                end
                            elseif not goTo(x, y) then
                                markSkip(key, 30)
                            end
                            return true
                        end
                    end
                end
            end
            return false
        end

        local function gatherStep(id)
            if canEndDirtRows() then
                return false
            end
            local seed = ids.dirtSeed
            local total = floatingAmount(ids.dirt) + count(ids.dirt)
            setStatus("Total dirt: " .. total)
            if total > 1056 then
                return false
            end
            walkToObj(seed)
            task.wait(2)
            if count(seed) == 0 and floatingAmount(seed) > 0 then
                local tries = 0
                while alive(id) and count(seed) < 200 and floatingAmount(seed) > 0 and playerCount() <= MAX_PLAYERS and tries < 30 do
                    tries = tries + 1
                    walkToObj(seed)
                    task.wait(1)
                end
            end
            if count(seed) > 0 then
                local placed = countPlaced(seed)
                while alive(id) and count(seed) > 0 and placed < 175 and playerCount() <= MAX_PLAYERS do
                    local acted, n = plantStep(seed)
                    if not acted then
                        break
                    end
                    placed = placed + n
                    task.wait()
                end
            end
            if hasHarvestable(seed) then
                while alive(id) and hasHarvestable(seed) and playerCount() <= MAX_PLAYERS do
                    if not harvestStep(seed) then
                        break
                    end
                    task.wait()
                end
            end
            return true
        end

        -- ===== tahap 8: susun baris dirt =====
        local function placeRowStep()
            local _, h = dims()
            for y = 0, h - 1 do
                for x = 1, 97 do
                    local f = flagAt(x, y)
                    if (f == 1 or f == 2) and fgAt(x + 1, y) == 0 then
                        local key = "r" .. x .. "," .. y
                        if not isSkipped(key) then
                            local mx, my = here()
                            if mx == x and my == y - 1 then
                                if count(ids.dirt) <= 0 then
                                    if floatingAmount(ids.dirt) <= 0 then
                                        return false
                                    end
                                    return true
                                end
                                place(x + 2, y, ids.dirt)
                                place(x + 1, y, ids.dirt)
                                task.wait(PLACE_DIRT_ROWS_DELAY / 1000)
                            elseif not goTo(x, y - 1) then
                                markSkip(key, 30)
                            end
                            return true
                        end
                    end
                end
            end
            return false
        end

        local function afterRows(id)
            if count(ids.dirt) == 0 and floatingAmount(ids.dirt) > 0 then
                local tries = 0
                while alive(id) and count(ids.dirt) < 200 and floatingAmount(ids.dirt) > 0 and playerCount() <= MAX_PLAYERS and tries < 30 do
                    tries = tries + 1
                    if not walkToObj(ids.dirt) then
                        break -- v8.3: semua drop sedang dilewati (tidak terjangkau), jangan menunggu sia-sia
                    end
                    task.wait(0.2)
                end
            end
        end

        -- ===== tahap 9: buang sampah =====
        local function trashStep()
            local list = unobstObjects()
            setStatus("Objek di tanah: " .. #list)
            if #list == 0 then
                return false
            end
            local o = list[1]
            local key = "o" .. tostring(o.uid)
            if isSkipped(key) then
                for i = 2, #list do
                    if not isSkipped("o" .. tostring(list[i].uid)) then
                        o = list[i]
                        key = "o" .. tostring(o.uid)
                        break
                    end
                end
                if isSkipped(key) then
                    return false
                end
            end
            if not goTo(floor(o.x), floor(o.y)) then
                markSkip(key, 30)
            end
            if anyTrash(200) then
                trashFull(200)
            end
            return true
        end

        -- ===== alur utama =====
        local function phase(id, name, step, after)
            RT.Phase = name
            logEv("mulai: " .. name)
            goFail = 0
            while alive(id) do
                RT.Beat = os.clock()
                if not waitPlayers(id) then
                    logEv("tahap '" .. name .. "' berhenti saat menunggu pemain (Running=" .. tostring(RT.Running) .. ", script aktif=" .. tostring(scriptAlive()) .. ")")
                    return
                end
                local res = step()
                if after then
                    after(id)
                end
                if res == false then
                    setStatus("Tahap selesai: " .. name)
                    logEv("selesai: " .. name .. " | " .. tostring(RT.Status))
                    return
                end
                task.wait()
            end
            logEv("tahap '" .. name .. "' diputus: Running=" .. tostring(RT.Running) .. ", script aktif=" .. tostring(scriptAlive()) .. ", RunId cocok=" .. tostring(RT.RunId == id))
        end

        -- ===== pakai mesin Auto Clear World (cari jalan A*, pijakan otomatis, sapu dari atas) =====
        local savedF

        local function restoreF()
            if savedF then
                for k, v in pairs(savedF) do
                    Clear[k] = v
                end
                savedF = nil
            end
            Clear.Filter = nil
            Clear.Quiet = false
        end

        -- return: sisa tile (angka) kalau mesin dipakai, nil kalau mesin tidak tersedia
        local function useEngine(id, label, filter)
            if not Auto.startClear or not stopClear then
                return nil
            end
            if Clear.Running then
                pcall(stopClear, "Dihentikan oleh Dirt Farm")
            end
            savedF = {
                Sweep = Clear.Sweep,
                UseBlock = Clear.UseBlock,
                ScaffoldId = Clear.ScaffoldId,
                Collect = Clear.Collect,
                IncludeBg = Clear.IncludeBg,
            }
            Clear.Sweep = "Zig-zag"
            Clear.IncludeBg = true
            Clear.Collect = true
            Clear.UseBlock = true
            local sid = fillBlockId()
            if sid then
                Clear.ScaffoldId = sid
            end
            pcall(Auto.resetReach)
            Clear.Filter = filter
            Clear.Quiet = true
            pcall(Auto.startClear)
            if not Clear.Running then
                restoreF()
                return nil
            end
            RT.Phase = label
            local base = RT.Broken
            while alive(id) and Clear.Running do
                RT.Broken = base + (Clear.Broken or 0)
                setStatus(tostring(Clear.Status))
                task.wait(0.5)
            end
            RT.Broken = base + (Clear.Broken or 0)
            local rem = Clear.Remaining
            if Clear.Running then
                pcall(stopClear, "Dihentikan oleh Dirt Farm")
            end
            restoreF()
            if type(rem) ~= "number" or rem < 0 then
                rem = 0
            end
            return rem
        end

        -- mesin Clear World dulu; kalau tidak tersedia, pakai cara lama (cadangan)
        local USE_ENGINE = false -- true = pakai mesin Clear World (terlalu liar, dimatikan)

        local function enginePhase(id, name, filter, step, after)
            if not alive(id) then
                return
            end
            if not USE_ENGINE then
                phase(id, name, step, after)
                return
            end
            if not waitPlayers(id) then
                return
            end
            local rem = useEngine(id, name, filter)
            if rem == nil then
                phase(id, name, step, after)
            else
                setStatus("Tahap selesai: " .. name .. (rem > 0 and (" (sisa " .. rem .. " tile tidak terjangkau)") or ""))
                if after and alive(id) then
                    after(id)
                end
            end
        end

        local function sideFilter(a, b)
            return function(x, y)
                return x >= a and x <= b and y <= 53 and fgAt(x, y) ~= ids.platform
            end
        end

        local function lavaFilter(x, y)
            return fgAt(x, y) == ids.lava
        end

        local function caveFilter(x, y)
            return x >= 2 and x <= 97 and y >= 1 and bgAt(x, y) == ids.cave and bgAt(x, y - 1) == ids.cave
        end

        local function lavaEnginePhase(id)
            local w, h = dims()
            local spots = {}
            for y = 0, h - 1 do
                for x = 0, w - 1 do
                    if lavaFilter(x, y) then
                        spots[#spots + 1] = {x = x, y = y}
                    end
                end
            end
            if #spots == 0 then
                return
            end
            if not fillBlockId() then
                setStatus("Lava ada, tapi tidak ada Dirt/Rock untuk menutup lubang. Ambil block dulu")
                task.wait(2)
                return
            end
            enginePhase(id, "Break lava dulu", lavaFilter, lavaFirstStep, function(pid)
                if count(ids.lava) >= 200 then
                    afterLava(pid)
                end
            end)
            for _, sp in ipairs(spots) do
                if fgAt(sp.x, sp.y) == 0 then
                    lavaPending[#lavaPending + 1] = sp
                end
            end
            if alive(id) then
                phase(id, "Tutup lubang bekas lava", lavaFillStep)
            end
        end

        -- ===== gali per baris: SATU baris satu baris, dari atas, tanpa pecah samping/bawah =====
        -- Pola (sama seperti Auto DF): koridor = baris tempat berdiri, lantai = 1 baris di bawahnya
        -- (tidak dipecah), baris target = 2 baris di bawah tempat berdiri. Satu baris selesai
        -- baru lanjut ke baris berikutnya (2 baris di bawahnya).
        local function diggable(x, y)
            local f = fgAt(x, y)
            if f == ids.dirt or f == ids.rock or f == ids.lava then
                return true
            end
            return f == 0 and bgAt(x, y) == ids.cave
        end

        local function solidFloor(x, y)
            local fl = flagAt(x, y)
            return (fl == 1 or fl == 2) and fgAt(x, y) ~= ids.lava
        end

        local function rowDensity(y)
            local w = dims()
            local n = 0
            for x = 2, math.min(97, w - 1) do
                if diggable(x, y) then
                    n = n + 1
                end
            end
            return n
        end

        local lineBase
        local floorHits = {}

        -- cari "gumpalan" tanah utama: dari dasar naik selama barisnya padat
        local function computeLineBase()
            local _, h = dims()
            local DENSE = 30
            local bottom
            for y = h - 1, 0, -1 do
                if rowDensity(y) >= DENSE then
                    bottom = y
                    break
                end
            end
            if not bottom then
                return nil
            end
            local top = bottom
            while top - 1 >= 0 and rowDensity(top - 1) >= DENSE do
                top = top - 1
            end
            return {top = top, bottom = bottom}
        end

        -- perbaiki lantai koridor (baris c+1): lava dipecah lalu ditutup, lubang ditutup.
        -- Dikerjakan dari kiri ke kanan, berdiri di koridor (tile sebelahnya yang lantainya padat).
        local function floorFixStep(c)
            local w, h = dims()
            local f = c + 1
            if c < 0 or f >= h then
                return false
            end
            local mx, my = here()
            for x = 2, math.min(97, w - 1) do
                local key = "f" .. x .. "," .. f
                if not solidFloor(x, f) and not isSkipped(key) then
                    if not fillBlockId() then
                        setStatus("Lantai baris " .. f .. " berlubang/lava, tapi tidak ada Dirt/Rock untuk menutup")
                        return false
                    end
                    local sx
                    for _, cx in ipairs({x - 1, x + 1}) do
                        if cx >= 0 and cx < w and solidFloor(cx, f) and flagAt(cx, c) == 0 and fgAt(cx, c) ~= ids.lava then
                            sx = cx
                            break
                        end
                    end
                    if not sx then
                        markSkip(key, 60)
                        return true
                    end
                    if mx == sx and my == c then
                        floorHits[key] = (floorHits[key] or 0) + 1
                        if floorHits[key] > 40 then
                            floorHits[key] = nil
                            markSkip(key, 60)
                        elseif fgAt(x, f) ~= 0 then
                            if punch(x, f) == nil then
                                markSkip(key, 60)
                            end
                        elseif not fillHole(x, f) then
                            markSkip(key, 30)
                        end
                    elseif not goTo(sx, c) then
                        markSkip(key, 60)
                    end
                    return true
                end
            end
            return false
        end

        local function lineStep()
            local w, h = dims()
            if not lineBase then
                lineBase = computeLineBase()
                if not lineBase then
                    setStatus("Tanah utama tidak ketemu, tahap gali dilewati")
                    logEv("tanah utama TIDAK ketemu (dunia " .. w .. "x" .. h .. ", dirt id " .. tostring(ids.dirt) .. ")")
                    return false
                end
                setStatus("Tanah utama baris " .. lineBase.top .. " - " .. lineBase.bottom)
                logEv("tanah utama baris " .. lineBase.top .. "-" .. lineBase.bottom .. " (dunia " .. w .. "x" .. h .. ")")
            end
            local last = math.min(53, lineBase.bottom, h - 2)
            for ty = lineBase.top + 1, last, 2 do
                local has = false
                for x = 2, math.min(97, w - 1) do
                    if diggable(x, ty) and not isSkipped("L" .. x .. "," .. ty) then
                        has = true
                        break
                    end
                end
                if has then
                    -- 1) lantai koridor di atasnya harus padat (tidak ada lava / lubang)
                    if floorFixStep(ty - 2) then
                        return true
                    end
                    -- 2) gali baris ini saja, 5 tile per posisi, berdiri 2 tile di atas
                    setStatus("Gali baris " .. ty .. " (satu baris, 5 tile per posisi)")
                    return batchBreakStep("L", function(x, y)
                        return y == ty and diggable(x, y)
                    end, 2, 97)
                end
            end
            return false
        end

        -- ===== v7: sapu serpentin ala Auto DF =====
        -- Per baris target (ty): berdiri di koridor (ty-2), pecah (x, ty) satu per satu.
        -- Baris ganjil sapuan kiri->kanan, berikutnya kanan->kiri. Maks DF_MAX_HIT pukulan per tile.
        local DF = {Row = nil, Dir = 1, X = nil, Pass = 0, Hits = {}, FloorOk = {}}

        local function dfReset()
            DF.Row, DF.Dir, DF.X, DF.Pass, DF.Cur, DF.Hole = nil, 1, nil, 0, nil, nil
            table.clear(DF.Hits)
            table.clear(DF.FloorOk)
        end

        local function dfRange()
            local w, h = dims()
            if not lineBase then
                lineBase = computeLineBase()
            end
            if lineBase then
                return lineBase.top + 1, math.min(53, lineBase.bottom, h - 2)
            end
            -- cadangan: rentang tetap seperti script referensi (target y = 25 .. 53)
            logEv("tanah utama tidak ketemu, pakai rentang tetap 25-53")
            return 25, math.min(53, h - 2)
        end

        local function dfHasLeft(top, last, x0, x1)
            for ty = top, last, 2 do
                for x = x0, x1 do
                    if diggable(x, ty) and not isSkipped("D" .. x .. "," .. ty) then
                        return true
                    end
                end
            end
            return false
        end

        -- tile lantai yang boleh dipecah untuk membuka jalan turun (bukan lava/lock/dll)
        local function diggableOrSolid(x, y)
            local f = fgAt(x, y)
            return f == ids.dirt or f == ids.rock
        end

        -- lubang lantai yang dibuka untuk turun antar koridor: setelah karakter sudah turun
        -- (lebih rendah dari lubang), langsung ditutup lagi dengan dirt
        local function closeHole()
            local h = DF.Hole
            if not h then
                return
            end
            local mx, my = here()
            if not my or my <= h.y then
                return -- belum turun, tunggu
            end
            DF.Hole = nil
            if fgAt(h.x, h.y) == 0 and count(ids.dirt) > 0 and nearTile(h.x, h.y) then
                if place(h.x, h.y, ids.dirt) then
                    logEv("lubang turun (" .. h.x .. "," .. h.y .. ") ditutup dirt")
                end
            end
            -- v8.3: belum tertutup (dirt belum ada / sudah terlalu jauh) -> masuk daftar lubang,
            -- ditutup di tahap lava. Lubang di lantai memutus koridor di atasnya.
            if fgAt(h.x, h.y) == 0 then
                lavaPending[#lavaPending + 1] = {x = h.x, y = h.y}
            end
        end

        local function dfStep()
            closeHole()
            local w = dims()
            local x0, x1 = 2, math.min(97, w - 1)
            local top, last = dfRange()
            if not DF.Row then
                DF.Row, DF.Dir, DF.X = top, 1, x0
                logEv("DF mulai: baris " .. top .. " s/d " .. last)
            end
            while DF.Row <= last do
                local ty = DF.Row
                local c = ty - 2
                -- 1) lantai koridor (baris ty-1) harus padat dulu, sekali per baris
                if not DF.FloorOk[ty] then
                    if floorFixStep(c) then
                        return true
                    end
                    DF.FloorOk[ty] = true
                end
                -- 2) kelompok yang sedang dikerjakan: dfBatch() tile sekali berdiri
                if DF.Cur then
                    local cur, left = DF.Cur, {}
                    for _, tx in ipairs(cur.tiles) do
                        if diggable(tx, ty) and not isSkipped("D" .. tx .. "," .. ty) then
                            left[#left + 1] = tx
                        end
                    end
                    if #left == 0 then
                        DF.HoleTry = 0
                        DF.X = cur.last + cur.dir
                        DF.Cur = nil
                    else
                        cur.tiles = left
                        setStatus(("Gali baris %d, sapuan %s, x=%d (%d tile)"):format(ty, cur.dir == 1 and "kiri->kanan" or "kanan->kiri", left[1], #left))
                        local mx, my = here()
                        if mx == cur.cx and my == c then
                            local reached = false
                            for _, tx in ipairs(left) do
                                if nearTile(tx, ty) then
                                    reached = true
                                    local key = "D" .. tx .. "," .. ty
                                    DF.Hits[key] = (DF.Hits[key] or 0) + 1
                                    if DF.Hits[key] > DF_MAX_HIT then
                                        DF.Hits[key] = nil
                                        markSkip(key, 60)
                                        logEv("DF belum hancur: " .. tx .. "," .. ty)
                                    elseif punch(tx, ty) == nil then
                                        markSkip(key, 60)
                                    end
                                end
                            end
                            -- v8: sisa tile di luar jangkauan dari posisi ini -> pindah tepat di atas
                            -- tile pertama (tanpa ini karakter diam selamanya di tempat)
                            if not reached then
                                if cur.cx ~= left[1] then
                                    cur.cx = left[1]
                                else
                                    markSkip("D" .. left[1] .. "," .. ty, 60)
                                end
                            end
                        elseif not goTo(cur.cx, c) then
                            -- v7.6: tidak ada jalan turun ke koridor berikutnya. Karakter masih di koridor
                            -- atas (c-2) -> buka 1 tile lantai (c-1) di ujung baris supaya bisa jatuh turun
                            -- ke koridor c (ujung ini = tempat sapuan berikutnya dimulai).
                            local hx, hy = here()
                            local opened = false
                            if hx and hy == c - 2 then
                                local ex = (hx >= (x0 + x1) / 2) and x1 or x0
                                local fy = c - 1
                                if fgAt(ex, fy) ~= 0 and diggableOrSolid(ex, fy) then
                                    DF.HoleTry = (DF.HoleTry or 0) + 1
                                    if DF.HoleTry <= 40 then
                                        opened = true
                                        if nearTile(ex, fy) then
                                            if DF.HoleTry == 1 then
                                                logEv("DF buka lantai ujung (" .. ex .. "," .. fy .. ") untuk turun ke koridor y=" .. c)
                                            end
                                            punch(ex, fy)
                                            DF.Hole = {x = ex, y = fy}
                                        else
                                            goTo(ex - ((ex == x1) and 1 or -1), c - 2)
                                        end
                                    end
                                end
                            end
                            if opened then
                                return true
                            end
                            if cur.cx ~= left[1] then
                                cur.cx = left[1] -- cadangan: berdiri tepat di atas tile pertama
                            else
                                markSkip("D" .. left[1] .. "," .. ty, 60)
                            end
                        end
                        return true
                    end
                end
                -- 3) cari target berikutnya searah sapuan
                local step = DF.Dir
                local endX = (step == 1) and x1 or x0
                local x, found = DF.X, nil
                while (step == 1 and x <= endX) or (step == -1 and x >= endX) do
                    if diggable(x, ty) and not isSkipped("D" .. x .. "," .. ty) then
                        found = x
                        break
                    end
                    x = x + step
                end
                if not found then
                    -- baris selesai: turun 2 baris, arah sapuan dibalik
                    logEv("DF baris " .. ty .. " selesai")
                    DF.Row = ty + 2
                    DF.Dir = -step
                    DF.X = (DF.Dir == 1) and x0 or x1
                else
                    if DF.LogRow ~= ty then
                        DF.LogRow = ty
                        local mx0, my0 = here()
                        logEv("DF baris " .. ty .. ": koridor y=" .. c .. ", tile pertama x=" .. found .. ", posisi sekarang (" .. tostring(mx0) .. "," .. tostring(my0) .. ")")
                    end
                    -- kelompokkan sampai dfBatch() tile searah sapuan
                    local nb = dfBatch()
                    local tiles = {}
                    for k = 0, nb - 1 do
                        local tx = found + k * step
                        if tx < x0 or tx > x1 then
                            break
                        end
                        if diggable(tx, ty) and not isSkipped("D" .. tx .. "," .. ty) then
                            tiles[#tiles + 1] = tx
                        end
                    end
                    -- v8: berdiri di tengah jendela, jadi kelima tile berjarak <= 2 dari karakter
                    local cx = found + step * floor((nb - 1) / 2)
                    cx = math.max(x0, math.min(x1, cx))
                    DF.Cur = {tiles = tiles, cx = cx, last = found + (nb - 1) * step, dir = step}
                end
            end
            -- semua baris sudah disapu: cek sisa (tile yang tadi dilewati), maks 3 putaran
            if DF.Pass < 3 and dfHasLeft(top, last, x0, x1) then
                DF.Pass = DF.Pass + 1
                DF.Row, DF.Dir, DF.X, DF.Cur = top, 1, x0, nil
                table.clear(DF.FloorOk)
                logEv("DF putaran ulang " .. DF.Pass)
                return true
            end
            logEv("DF selesai")
            return false
        end

        -- ===== v7: susun dirt ala Auto Place =====
        -- Baris y = 22, 20, ... 2 (x 2..97): berdiri di (x, y+1), taruh dirt di (x, y).
        -- Dirt habis -> return false (main lalu kumpulkan dirt & lanjut dari posisi yang sama).
        local function prStep()
            local w = dims()
            local x1 = math.min(REF_ROW_X1, w - 1)
            if not PR.Y then
                -- permukaan tanah = baris padat PALING ATAS (baris itu tidak ikut digali).
                -- lineBase tidak dipakai karena salah kalau world sudah tergali dari run sebelumnya.
                -- v8: dicari mulai dari bawah baris 22. Dulu dicari dari y=0, jadi baris dirt yang
                -- sudah tersusun dikira permukaan tanah dan baris awal bergeser naik (baris 22 terlewat).
                -- World standar (tanah mulai y=24) -> mulai y=22, sama seperti Auto DF 5 Tile.
                local startY = REF_ROW_START_Y
                local gtop
                local _, wh = dims()
                for yy = REF_ROW_START_Y + 1, wh - 1 do
                    if rowDensity(yy) >= 30 then
                        gtop = yy
                        break
                    end
                end
                if not gtop and lineBase then
                    gtop = lineBase.top
                end
                if gtop and gtop - 2 >= REF_ROW_TOP_Y then
                    startY = gtop - 2
                end
                PR.Y, PR.X = startY, REF_ROW_X0
                logEv("susun baris mulai di y=" .. PR.Y .. " (permukaan tanah y=" .. tostring(gtop) .. ")")
            end
            while PR.Y >= REF_ROW_TOP_Y do
                local y = PR.Y
                local x = PR.X
                -- lewati tile yang sudah terisi (dirt maupun block lain)
                while x <= x1 and fgAt(x, y) ~= 0 do
                    x = x + 1
                end
                if x > x1 then
                    PR.Y, PR.X = y - REF_ROW_STEP_Y, REF_ROW_X0
                else
                    PR.X = x
                    if count(ids.dirt) <= 0 then
                        if floatingAmount(ids.dirt) > 0 and PR.Starve < 20 then
                            PR.Starve = PR.Starve + 1
                            setStatus("Dirt di tas habis, memungut drop...")
                            return true -- afterRows memungut drop
                        end
                        setStatus("Dirt habis, lanjut dari (" .. x .. "," .. y .. ")")
                        return false
                    end
                    PR.Starve = 0
                    local mx, my = here()
                    if mx == x and my == y + 1 then
                        local n = 0
                        for dx = 0, 2 do
                            local tx = x + dx
                            if tx <= x1 and fgAt(tx, y) == 0 and count(ids.dirt) > 0 then
                                if place(tx, y, ids.dirt) then
                                    n = n + 1
                                end
                            end
                        end
                        if n == 0 then
                            markSkip("P" .. x .. "," .. y, 30)
                            PR.X = x + 1
                        end
                        PR.Miss = 0
                        setStatus(("Susun dirt baris %d, x=%d"):format(y, x))
                    else
                        setStatus(("Jalan ke (%d,%d) untuk susun baris %d"):format(x, y + 1, y))
                        if goTo(x, y + 1) then
                            PR.Miss = 0
                        else
                            -- tidak terjangkau: lewati tile ini. 6x berturut-turut = berhenti,
                            -- daripada diam lama mencoba tile demi tile
                            PR.Miss = (PR.Miss or 0) + 1
                            if PR.Miss >= 6 then
                                local hx, hy = here()
                                PR.Stuck = "tidak bisa jalan ke (" .. x .. "," .. (y + 1) .. ") untuk menyusun baris " .. y
                                    .. ", posisi karakter (" .. tostring(hx) .. "," .. tostring(hy) .. "). Cek tangga platform di kolom 1 / 98"
                                return false
                            end
                            PR.X = x + 1
                        end
                    end
                    return true
                end
            end
            PR.Done = true
            logEv("susun baris selesai sampai y=" .. REF_ROW_TOP_Y)
            return false
        end

        -- ===== v8.3: tahap lava =====
        -- Cara lama (breakLavaStep) wajib berdiri di kanan lava. Lantai lava dianggap berbahaya
        -- oleh pencari jalan, jadi posisi itu tidak terjangkau dari kiri dan tahap ini berputar
        -- selamanya. Sekarang: berdiri di sisi mana pun yang terjangkau, pecah, langsung tutup.
        -- Berhenti sendiri kalau 45 langkah berturut-turut tidak ada lava yang berkurang.
        local LV = {}

        local function lavaStep()
            if not ids.lava then
                return false
            end
            if not LV.Spots then
                LV.Spots, LV.Stale, LV.Mark = {}, 0, nil
                local w, h = dims()
                for y = 0, h - 1 do
                    for x = 0, w - 1 do
                        if fgAt(x, y) == ids.lava then
                            LV.Spots[#LV.Spots + 1] = {x = x, y = y}
                        end
                    end
                end
                logEv("lava: " .. #LV.Spots .. " tile")
            end
            local left = 0
            for i = #LV.Spots, 1, -1 do
                local sp = LV.Spots[i]
                local f = fgAt(sp.x, sp.y)
                if f == ids.lava then
                    left = left + 1
                else
                    table.remove(LV.Spots, i)
                    if f == 0 then
                        -- sudah pecah tapi belum tertutup: masuk daftar lubang
                        local known = false
                        for _, p in ipairs(lavaPending) do
                            if p.x == sp.x and p.y == sp.y then
                                known = true
                                break
                            end
                        end
                        if not known then
                            lavaPending[#lavaPending + 1] = sp
                        end
                    end
                end
            end
            if left == 0 and (#lavaPending == 0 or not fillBlockId()) then
                return false
            end
            local mark = left .. ":" .. #lavaPending
            if LV.Mark ~= mark then
                LV.Mark, LV.Stale, LV.Retry = mark, 0, 0
            end
            LV.Stale = LV.Stale + 1
            if LV.Stale > 45 then
                logEv("lava: sisa " .. left .. " tile tidak terjangkau / tidak bisa dipecah, dilewati")
                return false
            end
            if lavaFirstStep() then
                return true
            end
            -- semua lava sedang dilewati. Posisi karakter sudah berubah (mis. pindah ke tangga satunya),
            -- jadi coba lagi dari sini: sisi lava yang tadi tidak terjangkau bisa jadi terjangkau.
            LV.Retry = (LV.Retry or 0) + 1
            if left > 0 and LV.Retry <= 3 then
                for k in pairs(skip) do
                    if string.sub(k, 1, 1) == "l" then
                        skip[k] = nil
                    end
                end
                return true
            end
            if left > 0 then
                logEv("lava: sisa " .. left .. " tile tidak terjangkau, dilewati")
            end
            return false
        end

        -- ===== v9: farm Dirt Seed ala PABRIK =====
        -- Dulu: jalan ke tiap pohon satu per satu (tanam 2 tile, panen 2 tile per posisi) = lambat.
        -- Sekarang seperti Pabrik:
        --   RUTE TETAP  : koridor galian paling bawah (jumlahnya dari menu), titik berdiri tiap 5 tile.
        --   PANEN+TANAM : sekali jalan mengikuti rute. Di tiap titik: panen semua yang siap (5 tile)
        --                 -> ambil hasil panen -> langsung tanam lagi. Titik tanpa pekerjaan dilewati.
        --   TUNGGU      : menunggu sampai banyak pohon siap (tidak bolak-balik untuk 1 pohon).
        -- Selesai (return false) kalau dirt di tas sudah cukup, atau tidak ada lagi yang bisa
        -- dikerjakan (FM.Stuck = alasannya).
        local FARM_SPAN = 2 -- tile yang terjangkau ke kiri / kanan dari titik berdiri
        local FM = {PlantN = {}}

        -- tile tanam sah: kosong / pohon Dirt Seed, dengan lantai padat (bukan lava) di bawahnya
        local function farmTileOk(x, y)
            local f = fgAt(x, y)
            return (f == 0 or f == ids.dirtSeed) and flagAt(x, y + 1) == 1 and fgAt(x, y + 1) ~= ids.lava
        end

        -- return: daftar baris {y, stops = {{x, y, lo, hi, key}, ... kiri -> kanan}}, dari bawah ke atas
        local function buildFarmRoute()
            local w, h = dims()
            local x0, x1 = 2, math.min(97, w - 1)
            local want = math.max(1, math.min(8, floor(tonumber(RT.FarmRows) or 2)))
            local rows = {}
            for y = h - 2, 23, -1 do
                if #rows >= want then
                    break
                end
                local n = 0
                for x = x0, x1 do
                    if farmTileOk(x, y) then
                        n = n + 1
                    end
                end
                if n >= 30 then
                    -- deretan yang lantainya bolong dipotong; tiap potongan dibagi per 5 tile
                    local stops = {}
                    local from
                    for x = x0, x1 + 1 do
                        if x <= x1 and farmTileOk(x, y) then
                            from = from or x
                        elseif from then
                            local lo = from
                            while lo <= x - 1 do
                                local hi = math.min(x - 1, lo + FARM_SPAN * 2)
                                stops[#stops + 1] = {x = floor((lo + hi) / 2), y = y, lo = lo, hi = hi, key = "F" .. lo .. "," .. y}
                                lo = hi + 1
                            end
                            from = nil
                        end
                    end
                    if #stops > 0 then
                        rows[#rows + 1] = {y = y, stops = stops}
                    end
                end
            end
            return rows
        end

        -- return: pohon siap, tile kosong yang bisa ditanam, jumlah pohon, detik ke pohon siap berikutnya
        local function farmScan(rows, seed)
            local ready, plantable, trees, nxt = 0, 0, 0, nil
            local now = workspace:GetServerTimeNow()
            for _, row in ipairs(rows) do
                for _, stp in ipairs(row.stops) do
                    if not isSkipped(stp.key) then
                        for x = stp.lo, stp.hi do
                            local f = fgAt(x, row.y)
                            if f == 0 then
                                if not isSkipped("t" .. x .. "," .. row.y) and Auto.plantSpotOk(x, row.y, seed) then
                                    plantable = plantable + 1
                                end
                            elseif f == seed then
                                trees = trees + 1
                                local ok, t = pcall(Auto.treeReadyAt, x, row.y, seed)
                                if ok and t then
                                    if now >= t then
                                        if not isSkipped("h" .. x .. "," .. row.y) then
                                            ready = ready + 1
                                        end
                                    elseif not nxt or t - now < nxt then
                                        nxt = t - now
                                    end
                                end
                            end
                        end
                    end
                end
            end
            return ready, plantable, trees, nxt
        end

        -- kerjakan 1 titik berdiri: panen -> ambil hasil -> tanam. return jumlah aksi
        local function farmWorkStop(stp, seed, canHarvest)
            local did = 0
            local y = stp.y
            local got = {}
            if canHarvest then
                for x = stp.lo, stp.hi do
                    local key = "h" .. x .. "," .. y
                    if fgAt(x, y) == seed and treeReady(x, y, seed) and not isSkipped(key) and nearTile(x, y) then
                        local r = punch(x, y) -- pohon siap: 1 pukulan = panen
                        if r ~= nil and fgAt(x, y) == seed then
                            r = punch(x, y)
                        end
                        if r == "broke" or fgAt(x, y) ~= seed then
                            RT.Harvested = RT.Harvested + 1
                            FM.PlantN["t" .. x .. "," .. y] = nil
                            got[#got + 1] = {x = x, y = y}
                            did = did + 1
                        else
                            markSkip(key, 30)
                        end
                    end
                end
            end
            -- ambil hasil panen dengan sentuhan badan (cara Pabrik), lalu balik ke titik berdiri
            if #got > 0 then
                setStatus(("Ambil hasil panen di (%d,%d)"):format(stp.x, y))
                pcall(function()
                    Drops.waitSpawn(got)
                    Drops.touchAll(got, stp.x, y)
                end)
                task.wait(0.15)
                local hx, hy = here()
                if hx ~= stp.x or hy ~= y then
                    goTo(stp.x, y)
                end
            end
            for x = stp.lo, stp.hi do
                if count(seed) <= 0 then
                    break
                end
                local key = "t" .. x .. "," .. y
                if fgAt(x, y) == 0 and not isSkipped(key) and nearTile(x, y) and Auto.plantSpotOk(x, y, seed) then
                    local n = (FM.PlantN[key] or 0) + 1
                    FM.PlantN[key] = n
                    if n > 3 then
                        -- sudah 3x ditanam tapi kosong lagi (ditolak server): lewati dulu
                        FM.PlantN[key] = nil
                        markSkip(key, 300)
                    elseif place(x, y, seed) then
                        RT.Placed = RT.Placed - 1 -- place() menghitungnya sebagai "pasang"
                        RT.Planted = RT.Planted + 1
                        did = did + 1
                    end
                end
            end
            return did
        end

        -- 1x jalan mengikuti rute (koridor bawah dulu, arah sapu mulai dari sisi terdekat). return jumlah aksi
        local function farmPass(id, rows, seed, target)
            local did = 0
            for _, row in ipairs(rows) do
                local stops = row.stops
                local mx = here()
                local a, b, st = 1, #stops, 1
                if mx and mx > (stops[1].x + stops[#stops].x) / 2 then
                    a, b, st = #stops, 1, -1
                end
                for i = a, b, st do
                    if not alive(id) or playerCount() > MAX_PLAYERS then
                        return did
                    end
                    RT.Beat = os.clock()
                    local stp = stops[i]
                    if not isSkipped(stp.key) then
                        local canHarvest = count(ids.dirt) < target
                        local work = false
                        for x = stp.lo, stp.hi do
                            local f = fgAt(x, row.y)
                            if f == 0 then
                                if count(seed) > 0 and not isSkipped("t" .. x .. "," .. row.y) and Auto.plantSpotOk(x, row.y, seed) then
                                    work = true
                                    break
                                end
                            elseif f == seed and canHarvest and not isSkipped("h" .. x .. "," .. row.y) and treeReady(x, row.y, seed) then
                                work = true
                                break
                            end
                        end
                        if work then
                            local hx, hy = here()
                            local ok = hx == stp.x and hy == row.y
                            if not ok then
                                setStatus(("Farm: jalan ke titik (%d,%d)"):format(stp.x, row.y))
                                -- dua kali: percobaan pertama bisa hanya sampai "turun ke dasar"
                                ok = goTo(stp.x, row.y) or goTo(stp.x, row.y)
                            end
                            if not alive(id) then
                                return did
                            end
                            if ok then
                                setStatus(("Farm: panen + tanam di (%d,%d), dirt di tas %d"):format(stp.x, row.y, count(ids.dirt)))
                                did = did + farmWorkStop(stp, seed, canHarvest)
                            else
                                markSkip(stp.key, 180)
                                logEv("farm: titik (" .. stp.x .. "," .. row.y .. ") tidak terjangkau, dilewati 3 menit")
                            end
                        end
                    end
                end
            end
            return did
        end

        local function farmStep()
            local seed = ids.dirtSeed
            -- tas maksimal 200 per item; 190 = batas aman (sama seperti Pabrik)
            local target = math.max(1, math.min(190, floor(tonumber(RT.DirtStop) or 190)))
            local have = count(ids.dirt)
            if have >= target then
                setStatus("Dirt di tas " .. have .. ", kembali menyusun")
                return false
            end

            -- pengaman: langkah demi langkah tanpa hasil (tempat tanam / pohon tidak terjangkau)
            local mark = RT.Planted .. ":" .. RT.Harvested .. ":" .. have .. ":" .. count(seed)
            if FM.Mark ~= mark then
                FM.Mark, FM.Fail = mark, 0
            end
            FM.Fail = (FM.Fail or 0) + 1
            if FM.Fail > 60 then
                local hx, hy = here()
                FM.Stuck = "tempat tanam / pohon Dirt Seed tidak terjangkau dari (" .. tostring(hx) .. "," .. tostring(hy) .. "). Cek tangga platform di kolom 1 / 98"
                return false
            end

            -- 1) dirt di tanah dipungut dulu; seed dipungut kalau di tas kosong
            if not (FM.NoPick and os.clock() < FM.NoPick) then
                local want
                if floatingAmount(ids.dirt) > 0 then
                    want = ids.dirt
                elseif count(seed) == 0 and floatingAmount(seed) > 0 then
                    want = seed
                end
                if want then
                    local pm = want .. ":" .. count(want)
                    if FM.PickMark ~= pm then
                        FM.PickMark, FM.PickTry = pm, 0
                    end
                    if FM.PickTry >= 15 then
                        -- sudah didatangi berkali-kali tapi jumlah di tas tidak bertambah
                        FM.NoPick, FM.PickTry = os.clock() + 60, 0
                        logEv("farm: drop di tanah tidak terambil, dilewati 60 dtk")
                    elseif walkToObj(want) then
                        FM.PickTry = FM.PickTry + 1
                        setStatus("Memungut " .. (want == seed and "Dirt Seed" or "dirt") .. " di tanah")
                        FM.Idle = nil
                        task.wait(0.3)
                        return true
                    end
                end
            end

            -- 2) rute tetap (dibuat sekali per tahap farm)
            if not FM.Rows then
                FM.Rows = buildFarmRoute()
                local nStops, nTiles = 0, 0
                for _, row in ipairs(FM.Rows) do
                    nStops = nStops + #row.stops
                    for _, stp in ipairs(row.stops) do
                        nTiles = nTiles + (stp.hi - stp.lo + 1)
                    end
                end
                logEv("farm: rute " .. #FM.Rows .. " koridor, " .. nStops .. " titik berdiri, " .. nTiles .. " tile tanam")
            end
            local rows = FM.Rows
            if #rows == 0 then
                FM.Stuck = "tidak ada koridor galian yang bisa ditanami (jalankan tahap gali dulu)"
                return false
            end

            -- 3) PANEN + TANAM: sekali jalan mengikuti rute
            local ready, plantable, trees, nxt = farmScan(rows, seed)
            local seeds = count(seed)
            local now = os.clock()
            if ready > 0 then
                FM.ReadySince = FM.ReadySince or now
            else
                FM.ReadySince = nil
            end
            -- panen kalau pohon siap sudah 70%, atau tidak ada lagi yang hampir siap (sama seperti Pabrik)
            local harvestGo = ready > 0
                and (ready >= math.ceil(trees * 0.7) or nxt == nil or nxt > 20 or now - (FM.ReadySince or now) > 45)
            local plantGo = plantable > 0 and seeds > 0 and now - (FM.PlantAt or -99) > 10
            if harvestGo or plantGo then
                local did = farmPass(FM.Id, rows, seed, target)
                FM.PlantAt = os.clock()
                FM.ReadySince = nil
                if did > 0 then
                    FM.Idle, FM.Empty = nil, 0
                else
                    FM.Empty = (FM.Empty or 0) + 1
                    if FM.Empty >= 3 then
                        local hx, hy = here()
                        FM.Stuck = "titik tanam tidak terjangkau dari (" .. tostring(hx) .. "," .. tostring(hy) .. "). Cek tangga platform di kolom 1 / 98"
                        return false
                    end
                    task.wait(1)
                end
                return true
            end

            -- 4) TUNGGU
            if trees > 0 then
                FM.Idle = FM.Idle or now
                local idle = now - FM.Idle
                -- pohon masih lama: dirt yang sudah ada disusun dulu (kalau cukup banyak untuk sekali naik)
                if (have >= 20 and ((nxt and nxt > 45) or (not nxt and ready == 0 and idle > 20)))
                    or (have > 0 and nxt and nxt > 180) then
                    setStatus("Pohon belum siap, susun dulu " .. have .. " dirt yang ada")
                    return false
                end
                local it = ItemDB[seed]
                local grow = (type(it) == "table" and tonumber(it.grow)) or 0
                if idle > math.max(600, grow * 2 + 120) then
                    FM.Stuck = "pohon Dirt Seed tidak kunjung siap panen. Tekan 'Hubungkan ke game' lalu jalankan lagi"
                    return false
                end
                if nxt then
                    setStatus(("Farm: %d dari %d pohon siap, menunggu yang lain (±%d dtk)"):format(ready, trees, math.ceil(nxt)))
                else
                    setStatus(("Farm: menunggu %d pohon Dirt Seed tumbuh (%d dtk)"):format(trees, floor(idle)))
                end
                FM.Fail = 0
                task.wait(1)
                return true
            end
            if have > 0 then
                return false -- masih ada sedikit dirt: susun dulu
            end
            if floatingAmount(ids.dirt) > 0 or floatingAmount(seed) > 0 then
                FM.Stuck = "dirt habis, sisa dirt / Dirt Seed di tanah tidak terjangkau"
            else
                FM.Stuck = "dirt dan Dirt Seed habis. Tambah Dirt Seed atau dirt, lalu jalankan lagi (lanjut dari posisi terakhir)"
            end
            return false
        end

        local function main(id)
            goFail = 0
            RT.ShortDrop = false
            resolveIds()
            local platName, platSimilar
            ids.platform, platName, platSimilar = findPlatformId()
            platName = platName or "Wooden Platform"
            if not ids.platform then
                local msg = "Berhenti: item platform untuk tangga tidak ketemu di data item game"
                if platSimilar and #platSimilar > 0 then
                    msg = msg .. ". Nama yang mirip: " .. table.concat(platSimilar, ", ")
                end
                setStatus(msg)
                RT.endMsg = msg
                logEv("preflight: item platform tidak ketemu")
                return
            end
            logEv("preflight: platform tangga = " .. platName .. " (id " .. ids.platform .. ")")
            do
                local bag, placed = count(ids.platform), countPlaced(ids.platform)
                logEv("preflight: platform di tas " .. bag .. ", terpasang " .. placed .. " (butuh total " .. PLATFORM_NEED .. ")")
                if bag + placed < PLATFORM_NEED then
                    local msg = "Berhenti sebelum mulai: butuh " .. PLATFORM_NEED .. " " .. platName .. " (tas " .. bag .. " + terpasang " .. placed .. "). Tanpa tangga karakter terjebak di dasar world"
                    setStatus(msg)
                    RT.endMsg = msg
                    return
                end
            end

            enginePhase(id, "Bersihkan sisi kiri", sideFilter(0, 1), function()
                return clearSide(0, 1)
            end)

            if alive(id) and count(ids.platform) >= 26 then
                logEv("platform kiri mulai: tas " .. count(ids.platform) .. ", terpasang " .. countPlaced(ids.platform))
                phase(id, "Pasang platform kiri", function()
                    return placePlatformsCol(1)
                end)
                logEv("platform kiri selesai: tas " .. count(ids.platform) .. ", terpasang " .. countPlaced(ids.platform))
            elseif alive(id) then
                setStatus("Platform di tas " .. count(ids.platform) .. " (<26), tahap platform kiri dilewati")
                task.wait(2)
            end

            enginePhase(id, "Bersihkan sisi kanan", sideFilter(98, 99), function()
                return clearSide(98, 99)
            end)

            if alive(id) and count(ids.platform) >= 26 then
                logEv("platform kanan mulai: tas " .. count(ids.platform) .. ", terpasang " .. countPlaced(ids.platform))
                phase(id, "Pasang platform kanan", function()
                    return placePlatformsCol(98)
                end)
                logEv("platform kanan selesai: tas " .. count(ids.platform) .. ", terpasang " .. countPlaced(ids.platform))
            elseif alive(id) then
                setStatus("Platform di tas " .. count(ids.platform) .. " (<26), tahap platform kanan dilewati")
                task.wait(2)
            end

            -- gali SATU baris satu baris dari atas (lava ikut dipecah & lantainya ditutup)
            -- v8.3: gali -> lava. Lava di lantai menutup jalan, jadi sebagian tile bisa tertinggal
            -- saat menggali. Kalau tahap lava berhasil mengurangi lava, gali diulang sekali lagi
            -- untuk sisa tile itu (maks 3 putaran; putaran tanpa sisa selesai seketika).
            for round = 1, 3 do
                if not alive(id) then
                    break
                end
                lineBase = nil
                if round > 1 then
                    table.clear(skip)
                end
                if not RT.DoDig then
                    logEv("tahap gali dimatikan dari menu")
                elseif USE_REF_DF then
                    dfReset()
                    phase(id, "Gali serpentin (" .. dfBatch() .. " tile per posisi)", dfStep, function()
                        afterDirtFarm()
                    end)
                else
                    phase(id, "Gali per baris (dari atas)", lineStep, function()
                        afterDirtFarm()
                    end)
                end

                if not RT.DoLava then
                    logEv("tahap lava dimatikan dari menu")
                    break
                end
                if not alive(id) then
                    break
                end
                local lava0 = countPlaced(ids.lava)
                LV.Spots = nil
                phase(id, "Ganti lava dengan dirt", lavaStep)
                if not alive(id) then
                    break
                end
                local nl = countPlaced(ids.lava)
                logEv("tahap lava selesai: sisa lava " .. nl .. ", lubang belum tertutup " .. #lavaPending)
                if not RT.DoDig or nl >= lava0 then
                    break
                end
                logEv("lava berkurang " .. (lava0 - nl) .. ", cek ulang sisa galian (putaran " .. (round + 1) .. ")")
            end
            if not alive(id) then
                return
            end

            -- ===== v8: susun baris dirt <-> farm Dirt Seed, bergantian sampai baris teratas selesai =====
            -- Resume: prStep selalu melewati tile yang sudah terisi, jadi run berikutnya (setelah
            -- dihentikan / disconnect / dirt habis) langsung lanjut dari tile kosong pertama.
            if not RT.DoRows then
                logEv("tahap susun baris dimatikan dari menu")
                return
            end
            prReset()
            PR.Miss, PR.Stuck = 0, nil
            RT.ShortDrop = true
            local stale = 0
            while alive(id) and not PR.Done do
                local placed0, harv0 = RT.Placed, RT.Harvested
                -- lubang bekas lava yang tadi belum sempat ditutup (waktu itu belum ada dirt)
                if #lavaPending > 0 and fillBlockId() then
                    phase(id, "Tutup lubang bekas lava", lavaFillStep)
                    if not alive(id) then
                        break
                    end
                end
                phase(id, "Susun baris dirt", prStep, afterRows)
                if not alive(id) or PR.Done then
                    break
                end
                if PR.Stuck then
                    RT.endMsg = "Berhenti: " .. PR.Stuck
                    logEv("susun baris berhenti: " .. PR.Stuck)
                    break
                end
                -- sampai sini = dirt habis sebelum semua baris selesai
                local at = "(" .. tostring(PR.X) .. "," .. tostring(PR.Y) .. ")"
                if not RT.DoFarm then
                    RT.endMsg = "Dirt habis di " .. at .. ". Farm dimatikan: isi dirt lalu jalankan lagi"
                    break
                end
                logEv("dirt habis di " .. at .. ", mulai farm Dirt Seed")
                FM.Idle, FM.Stuck, FM.NoPick, FM.PickMark, FM.Mark, FM.Fail = nil, nil, nil, nil, nil, 0
                FM.Id, FM.Rows, FM.Empty, FM.ReadySince, FM.PlantAt = id, nil, 0, nil, nil
                phase(id, "Farm Dirt Seed", farmStep)
                if not alive(id) then
                    break
                end
                if FM.Stuck then
                    RT.endMsg = "Berhenti di " .. at .. ": " .. FM.Stuck
                    logEv("farm berhenti: " .. FM.Stuck)
                    break
                end
                -- pengaman: 3 putaran tanpa ada yang terpasang / terpanen
                if RT.Placed == placed0 and RT.Harvested == harv0 then
                    stale = stale + 1
                    if stale >= 3 then
                        RT.endMsg = "Berhenti di " .. at .. ": tidak ada kemajuan (dirt tidak bertambah)"
                        break
                    end
                else
                    stale = 0
                end
            end
            if PR.Done and alive(id) then
                RT.endMsg = "Dirt Farm selesai: semua baris dirt tersusun"
            end
        end

        local function runner(id)
            local errors = 0
            while alive(id) do
                local ok, err = pcall(main, id)
                if ok then
                    break
                end
                errors = errors + 1
                warn("[SkyP] Dirt Farm error: " .. tostring(err))
                logEv("ERROR #" .. errors .. ": " .. tostring(err))
                setStatus("Error (coba lagi): " .. tostring(err))
                task.wait(2)
            end
            if alive(id) then
                RT.stop(RT.endMsg or "Dirt Farm selesai")
                RT.endMsg = nil
            end
        end

        function RT.stop(msg)
            if not RT.Running then
                return
            end
            logEv("STOP: " .. tostring(msg))
            RT.Running = false
            if Clear.Running and Clear.Filter and stopClear then
                pcall(stopClear, "Dihentikan oleh Dirt Farm")
            end
            restoreF()
            pcall(Auto.stopWalk)
            pcall(Auto.releaseInput)
            if RT.prevCollect ~= nil then
                State.CollectAround = RT.prevCollect
                RT.prevCollect = nil
            end
            if RT.prevMode ~= nil then
                State.CollectMode = RT.prevMode
                RT.prevMode = nil
            end
            if zoneSet then
                Pabrik.Zone = nil
                zoneSet = false
            end
            pcall(function()
                UI.RTToggle:Set(false)
            end)
            RT.Phase = "-"
            if msg then
                RT.Status = msg
                notify("Dirt Farm", msg, 4)
            end
        end

        function RT.start()
            if RT.Running then
                return
            end
            local function fail(m)
                notify("Dirt Farm", m, 4)
                RT.Status = m
                pcall(function()
                    UI.RTToggle:Set(false)
                end)
            end
            if not Refs.World then
                fail("Data world belum ketemu. Tekan 'Hubungkan ke game'")
                return
            end
            if not here() then
                fail("Kamu belum masuk world")
                return
            end
            if State.Running then
                stopFarm("Dihentikan karena Dirt Farm dimulai")
            end
            if Clear.Running and stopClear then
                stopClear("Dihentikan karena Dirt Farm dimulai")
            end
            if Farmer.Running and stopFarmer then
                stopFarmer("Dihentikan karena Dirt Farm dimulai")
            end
            if Splice.Running and Splice.stop then
                Splice.stop("Dihentikan karena Dirt Farm dimulai")
            end
            if Pabrik.Running and Pabrik.stop then
                Pabrik.stop("Dihentikan karena Dirt Farm dimulai")
            end
            if Vend.Running and Vend.stop then
                Vend.stop("Dihentikan karena Dirt Farm dimulai")
            end
            if not Refs.Trees then
                pcall(Auto.findTreeRefs)
            end
            if not Drops.list then
                pcall(findDropRefs)
            end
            table.clear(skip)
            RT.Log = {}
            RT.endMsg = nil
            RT.Broken, RT.Placed, RT.Planted, RT.Harvested, RT.Dropped, RT.Trashed = 0, 0, 0, 0, 0, 0
            RT.prevCollect = State.CollectAround
            RT.prevMode = State.CollectMode
            State.CollectAround = true
            State.CollectMode = "Remote"
            RT.Status = "Mulai..."
            RT.Running = true
            RT.RunId = RT.RunId + 1
            task.spawn(runner, RT.RunId)
        end

        -- ===== menu =====
        local tab = makeTab("Dirt Farm", "pickaxe", "farm")
        safe(function()
            UI.RTStatus = tab:Paragraph({Title = "Status", Desc = "-"})
        end)
        local sec = box(tab, "Kontrol", true)
        safe(function()
            UI.RTToggle = sec:Toggle({
                Title = "Dirt Farm",
                Desc = "Bersihkan sisi kiri & kanan, pasang platform (tangga), gali, ganti lava dengan dirt, lalu susun baris dirt "
                    .. "(y 22, 20, ... 2) sambil farm Dirt Seed kalau dirt habis. Butuh 52 platform (Wooden Platform atau sejenisnya)",
                Value = false,
                Callback = function(v)
                    if v then
                        RT.start()
                    elseif RT.Running then
                        RT.stop("Dirt Farm dihentikan")
                    end
                end,
            })
        end)

        -- v8: pengaturan
        local opt = box(tab, "Pengaturan", false)
        addNumber(opt, {
            Title = "Tile per posisi",
            Desc = "Jumlah tile yang dipukul sekali berdiri saat menggali",
            Min = 1, Max = 5, Default = dfBatch(),
            Callback = function(v)
                RT.Batch = math.max(1, math.min(5, floor(v)))
            end,
        })
        addNumber(opt, {
            Title = "Batas dirt",
            Desc = "Farm Dirt Seed berhenti dan kembali menyusun kalau dirt di tas sudah sebanyak ini (tas maksimal 200)",
            Min = 20, Max = 190, Step = 10, Default = math.max(20, math.min(190, tonumber(RT.DirtStop) or 190)),
            Callback = function(v)
                RT.DirtStop = math.max(20, math.min(190, floor(v)))
            end,
        })
        addNumber(opt, {
            Title = "Koridor untuk farm",
            Desc = "Jumlah koridor galian (dihitung dari bawah) yang ditanami Dirt Seed. 1 koridor = 96 pohon",
            Min = 1, Max = 8, Default = math.max(1, math.min(8, tonumber(RT.FarmRows) or 2)),
            Callback = function(v)
                RT.FarmRows = math.max(1, math.min(8, floor(v)))
            end,
        })
        for _, o in ipairs({
            {"DoDig", "Tahap: gali", "Gali baris 25, 27, ... 53 (lantai di antaranya tidak dipecah)"},
            {"DoLava", "Tahap: lava", "Pecah lava lalu ganti dengan dirt"},
            {"DoRows", "Tahap: susun baris dirt", "Taruh dirt di baris 22, 20, ... 2 (x 2-97). Lanjut otomatis dari tile kosong pertama"},
            {"DoFarm", "Tahap: farm Dirt Seed", "Kalau dirt habis: farm Dirt Seed cara Pabrik (rute tetap, panen + tanam 5 tile per titik), lalu lanjut menyusun"},
        }) do
            safe(function()
                opt:Toggle({
                    Title = o[2],
                    Desc = o[3],
                    Value = RT[o[1]] ~= false,
                    Callback = function(v)
                        RT[o[1]] = v and true or false
                    end,
                })
            end)
        end

        task.spawn(function()
            local last = nil
            while scriptAlive() do
                if UI.RTStatus then
                    local txt = "[Dirt Farm] Status : " .. (RT.Running and "JALAN" or "BERHENTI")
                        .. "\nTahap  : " .. RT.Phase
                        .. "\nInfo   : " .. RT.Status
                        .. "\nDetak  : " .. string.format("%.0f", os.clock() - (RT.Beat or os.clock())) .. " dtk lalu"
                        .. "\nHitung : pecah " .. RT.Broken .. " | pasang " .. RT.Placed .. " | tanam " .. RT.Planted .. " | panen " .. RT.Harvested
                    if txt ~= last then
                        last = txt
                        pcall(function()
                            UI.RTStatus:SetDesc(txt)
                        end)
                    end
                end
                task.wait(1)
            end
        end)
    end)()
end
local ConnTab = makeTab("Koneksi", "plug", "setel")

safe(function()
    UI.RefInfo = ConnTab:Paragraph({ Title = "Referensi game", Desc = "-" })
end)

Box.ConnMain = box(ConnTab, "Koneksi", true)
Box.ConnCfg = box(ConnTab, "Config", true)
Box.ConnCalib = box(ConnTab, "Koreksi posisi", false)

local function reconnect(show)
    -- hentikan Clear / Farmer dulu
    if Clear.Running then stopClear("Dihentikan: hubungkan ulang ke game") end
    if Farmer.Running then stopFarmer("Dihentikan: hubungkan ulang ke game") end
    Auto.resetReach()
    -- 1) cari isi tas cepat lalu langsung isi dropdown (tidak menunggu scan getgc yang lama)
    if pcall(Anim.quickRefs) and Refs.Inv then
        pcall(doInvRefresh, true)
        task.wait() -- biar dropdown tampil dulu sebelum scan lengkap (scan menahan layar sebentar)
    end
    -- 2) scan lengkap
    findRefs()
    watchInventory()
    pcall(doInvRefresh, true) -- langsung di thread ini (thread INIT / antrian UI), bukan thread tombol
    findDropRefs(true)
    Auto.findTreeRefs()
    table.clear(DropFailUntil)
    Anim.fn, Anim.idx = nil, nil
    pcall(Anim.findFast)
    if State.LiteMode then setLite(true) end
    if Misc.InfJump then hookJammer() end
    pcall(function() UI.RefInfo:SetDesc(refsText()) end)
    updateStatus()
    if show then notify(show, refsText(), 5) end
end

safe(function()
    Box.ConnMain:Button({
        Title = "Hubungkan ke game",
        Desc = "Pakai setelah pindah world",
        Callback = function()
            UI.later("reconnect", function()
                reconnect("Koneksi")
                if Session.refreshRoles then pcall(Session.refreshRoles) end
            end)
        end,
    })
end)

safe(function()
    UI.ConfigStatus = Box.ConnCfg:Paragraph({ Title = "Status", Desc = Config.Status })
end)

safe(function()
    Box.ConnCfg:Toggle({
        Title = "Auto Save Config",
        Desc = "Simpan pengaturan otomatis, dimuat lagi saat execute",
        Value = Config.AutoSave,
        Callback = function(on)
            Config.AutoSave = on
            Config.save(true) -- simpan pilihan ini juga
        end,
    })
end)

safe(function()
    Box.ConnCfg:Button({
        Title = "Simpan config sekarang",
        Callback = function()
            local ok = Config.save(true)
            notify("Config", ok and "Tersimpan" or Config.Status, 3)
        end,
    })
end)

safe(function()
    Box.ConnCfg:Button({
        Title = "Reset config (default)",
        Desc = "Hapus file config, lalu execute ulang",
        Callback = function()
            Config.reset()
            notify("Config", Config.Status, 4)
        end,
    })
end)

safe(function()
    Box.ConnCalib:Input({
        Title = "Koreksi posisi X",
        Desc = "Isi 1 / -1 kalau tile meleset",
        Value = tostring(State.CalibX),
        Callback = function(text) State.CalibX = tonumber(text) or 0 end,
    })
end)

safe(function()
    Box.ConnCalib:Input({
        Title = "Koreksi posisi Y",
        Value = tostring(State.CalibY),
        Callback = function(text) State.CalibY = tonumber(text) or 0 end,
    })
end)

safe(function()
    ConnTab:Paragraph({ Title = "Auto Rejoin pindah", Desc = "Pengaturan Auto Rejoin sekarang ada di menu Keamanan > Auto Rejoin" })
end)

-- ===== TAB: AUTO REJOIN (v2.1: tab sendiri di menu Keamanan) =====
do (function()
    local RTab = makeTab("Auto Rejoin", "refresh-cw", "aman")

    safe(function()
        UI.RejoinStatus = RTab:Paragraph({ Title = "Status", Desc = Rejoin.Status })
    end)

    -- 1) utama: yang paling sering dipakai, langsung terbuka
    local mBox = box(RTab, "Auto Rejoin", true)
    safe(function()
        mBox:Toggle({
            Title = "Auto Rejoin",
            Desc = "Masuk lagi & lanjut aktivitas kalau terlempar, disconnect, macet, atau Roblox crash",
            Value = Rejoin.On,
            Callback = function(on)
                Rejoin.On = on
                if on then
                    Rejoin.Paused, Rejoin.Hist = false, {} -- nyalakan ulang = rem direset
                    if Rejoin.Status:find("Berhenti", 1, true) then Rejoin.Status = "-" end
                elseif Rejoin.clearPending then
                    Rejoin.clearPending()
                end
            end,
        })
    end)
    safe(function()
        mBox:Input({
            Title = "World tujuan",
            Desc = "Kosongkan = world terakhir yang kamu masuki",
            Value = Rejoin.Target,
            Placeholder = "NAMAWORLD",
            Callback = function(text) Rejoin.Target = tostring(text or "") end,
        })
    end)
    safe(function()
        mBox:Input({
            Title = "World cadangan",
            Desc = "Dipakai kalau world tujuan tidak bisa dimasuki. Pisah dengan koma",
            Value = Rejoin.Backup,
            Placeholder = "WORLD2, WORLD3",
            Callback = function(text) Rejoin.Backup = tostring(text or "") end,
        })
    end)
    addNumber(mBox, {
        Title = "Jeda sebelum masuk lagi (detik)",
        Min = 2, Max = 60, Step = 1, Default = Rejoin.DelaySec,
        Callback = function(v) Rejoin.DelaySec = math.floor(v) end,
    })
    safe(function()
        mBox:Button({
            Title = "Rejoin world sekarang",
            Desc = "Keluar lalu masuk lagi, aktivitas dilanjutkan",
            Callback = function() Rejoin.now() end,
        })
    end)

    -- 2) kapan rejoin
    local tBox = box(RTab, "Kapan rejoin", false)
    safe(function()
        tBox:Toggle({
            Title = "Terlempar dari world",
            Desc = "World ditutup / di-kick dari world: masuk lagi ke world yang sama",
            Value = Rejoin.World,
            Callback = function(on) Rejoin.World = on end,
        })
    end)
    safe(function()
        tBox:Toggle({
            Title = "Disconnect dari server",
            Desc = "Layar error Roblox: teleport ulang ke game lalu masuk world terakhir",
            Value = Rejoin.Server,
            Callback = function(on) Rejoin.Server = on end,
        })
    end)
    safe(function()
        tBox:Toggle({
            Title = "Koneksi macet (watchdog)",
            Desc = "Game diam tanpa layar error (tidak ada data dari server): dianggap disconnect",
            Value = Rejoin.Watch,
            Callback = function(on) Rejoin.Watch = on end,
        })
    end)
    addNumber(tBox, {
        Title = "Batas macet (detik)",
        Desc = "Berapa lama tanpa data dari server baru dianggap macet",
        Min = 30, Max = 300, Step = 10, Default = Rejoin.WatchSec,
        Callback = function(v) Rejoin.WatchSec = math.floor(v) end,
    })
    safe(function()
        tBox:Toggle({
            Title = "Selalu kembali ke world",
            Desc = "Kalau berada di luar world (layar pilih world), masuk lagi otomatis",
            Value = Rejoin.Keep,
            Callback = function(on) Rejoin.Keep = on end,
        })
    end)

    -- 3) pengaman: supaya rejoin tidak memperparah keadaan
    local sBox = box(RTab, "Pengaman", false)
    safe(function()
        sBox:Toggle({
            Title = "Baca alasan disconnect",
            Desc = "Tidak rejoin kalau akun dibuka di perangkat lain, atau di-kick karena ban / cheat",
            Value = Rejoin.Smart,
            Callback = function(on) Rejoin.Smart = on end,
        })
    end)
    addNumber(sBox, {
        Title = "Batas rejoin per jam",
        Desc = "Lebih dari ini dalam 1 jam = Auto Rejoin berhenti (kemungkinan sengaja di-kick)",
        Min = 3, Max = 30, Step = 1, Default = Rejoin.MaxPerHour,
        Callback = function(v) Rejoin.MaxPerHour = math.floor(v) end,
    })

    -- 4) auto execute setelah teleport
    local eBox = box(RTab, "Auto execute (rejoin server)", false)
    safe(function()
        eBox:Input({
            Title = "URL script",
            Desc = "Link raw script ini, supaya jalan lagi setelah teleport. Kosong = pakai autoexec",
            Value = Rejoin.ScriptUrl,
            Placeholder = "https://...",
            Callback = function(text)
                Rejoin.ScriptUrl = tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "")
            end,
        })
    end)
    safe(function()
        eBox:Input({
            Title = "File script lokal (cadangan)",
            Desc = "Dipakai kalau URL kosong. Simpan script ini di folder workspace executor",
            Value = Rejoin.LocalFile,
            Placeholder = "SkyP/SkyP.lua",
            Callback = function(text) Rejoin.LocalFile = (tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "")) end,
        })
    end)
    safe(function()
        eBox:Button({
            Title = "Tes auto execute",
            Desc = "Cek apakah script bisa di-queue untuk jalan lagi setelah teleport",
            Callback = function()
                local ok, how = Rejoin.queueScript()
                notify("Auto Rejoin", ok and ("OK, script di-queue lewat " .. tostring(how)) or ("Gagal: " .. tostring(how)), 5)
            end,
        })
    end)

    -- 5) webhook
    local rHook = box(RTab, "Webhook Rejoin", false)
    safe(function()
        rHook:Toggle({
            Title = "Webhook rejoin",
            Desc = "Kirim notifikasi terlempar / disconnect / masuk lagi ke Discord",
            Value = Rejoin.HookOn,
            Callback = function(on) Rejoin.HookOn = on end,
        })
    end)
    safe(function()
        rHook:Input({
            Title = "URL webhook rejoin",
            Desc = "Boleh beda dengan webhook di tab Discord",
            Value = Rejoin.HookUrl,
            Placeholder = "https://discord.com/api/webhooks/...",
            Callback = function(text) Rejoin.HookUrl = (tostring(text or ""):gsub("%s", "")) end,
        })
    end)
    safe(function()
        rHook:Input({
            Title = "Tag ID Discord",
            Desc = "Di-tag kalau rejoin gagal / dihentikan, supaya ada notifikasi di HP. Kosong = tanpa tag",
            Value = Rejoin.HookPing,
            Placeholder = "123456789012345678",
            Callback = function(text) Rejoin.HookPing = (tostring(text or ""):gsub("%D", "")) end,
        })
    end)
    safe(function()
        rHook:Button({
            Title = "Tes webhook rejoin",
            Callback = function()
                if not Hook.valid(Rejoin.HookUrl) then
                    notify("Webhook Rejoin", "URL webhook tidak valid", 4)
                    return
                end
                local was = Rejoin.HookOn
                Rejoin.HookOn = true
                Hook.onRejoin("Tes webhook rejoin dari SkyP. Kalau Tag ID diisi, kamu di-tag seperti saat rejoin gagal")
                Rejoin.HookOn = was
                notify("Webhook Rejoin", "Pesan tes dikirim", 3)
            end,
        })
    end)
end)() end

-- ===== TAB: DISCORD =====
do (function()
    local DcTab = makeTab("Discord", "bell", "setel")

    safe(function()
        UI.HookStatus = DcTab:Paragraph({ Title = "Status", Desc = Hook.Status })
    end)

    local dMain = box(DcTab, "Webhook", true)
    local dWhat = box(DcTab, "Yang dikirim", false)

    safe(function()
        dMain:Toggle({
            Title = "Notifikasi Discord",
            Desc = "Kirim kabar penting ke channel Discord kamu",
            Value = Hook.On,
            Callback = function(on) Hook.On = on end,
        })
    end)

    safe(function()
        dMain:Input({
            Title = "URL Webhook",
            Desc = "Channel Discord > Edit > Integrasi > Webhook > Salin URL",
            Value = Hook.Url,
            Placeholder = "https://discord.com/api/webhooks/...",
            Callback = function(text)
                text = tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "")
                Hook.Url = text
                if text ~= "" and not Hook.valid(text) then
                    notify("Discord", "URL webhook tidak valid", 4)
                end
            end,
        })
    end)

    safe(function()
        dMain:Button({
            Title = "Tes kirim",
            Callback = function()
                if not Hook.valid(Hook.Url) then
                    notify("Discord", "Isi URL webhook dulu", 3)
                    return
                end
                local was = Hook.On
                Hook.On = true
                Hook.send("test", "Tes notifikasi dari SkyP")
                Hook.On = was
                notify("Discord", "Pesan tes masuk antrian", 3)
            end,
        })
    end)

    addNumber(dMain, {
        Title = "Laporan statistik (menit)",
        Desc = "Kirim statistik sesi tiap X menit. 0 = mati",
        Min = 0, Max = 180, Step = 5, Default = Hook.ReportMin,
        Callback = function(v) Hook.ReportMin = math.floor(v) end,
    })

    for _, item in ipairs({
        { "Penjaga", "Mod / Dev / pemain masuk world" },
        { "Stop", "Aktivitas berhenti (block habis / error)" },
        { "Full", "Inventori penuh" },
        { "Bonus", "Quest diklaim / redeem berhasil" },
        { "Rejoin", "Terlempar / disconnect / masuk lagi" },
        { "Pabrik", "Pabrik drop seed / berhenti" },
    }) do
        safe(function()
            dWhat:Toggle({
                Title = item[2],
                Value = Hook[item[1]],
                Callback = function(on) Hook[item[1]] = on end,
            })
        end)
    end
end)() end


---------------------------------------------------------------------
-- INIT
---------------------------------------------------------------------
-- Thread pekerjaan UI: dibuat di sini (sama seperti thread status yang terbukti bisa mengubah UI).
-- Callback tombol / event game di sebagian executor tidak punya izin mengubah dropdown.
do
    task.spawn(function()
        while alive() do
            local ok, err = pcall(UI.runJobs)
            if not ok then warn("[SkyP] UI runner: " .. tostring(err)) end
            task.wait(0.1)
        end
    end)
end

---------------------------------------------------------------------
-- OBSERVASI: pantau semua menu di satu tab
--   - Ringkasan: tiap fitur JALAN / mati + angka kemajuannya
--   - Peringatan: fitur jalan tapi tidak ada kemajuan, karakter diam, pemain lain, referensi hilang
--   - Sistem: world, posisi, pemain, FPS, hook gerak
--   - Dirt Farm: tahap, info, detak, log
--   - Detail: isi panel status asli tiap menu (ditangkap, menu aslinya tidak diubah)
--   - Salin laporan: semua di atas jadi satu teks
---------------------------------------------------------------------
do (function()
    local Obs = { Text = {}, At = {}, Sig = {}, Shown = {}, On = true, T0 = os.clock() }
    Session.Obs = Obs
    local floor, clock = math.floor, os.clock

    -- panel status tiap menu: { kunci di UI, nama tampil }
    local WATCH = {
        { "Status", "Farm" },
        { "ClearStatus", "Clear World" },
        { "FarmerStatus", "Farmer" },
        { "SpamStatus", "Auto Chat" },
        { "GuardStatus", "Penjaga" },
        { "QuestStatus", "Bonus: Quest" },
        { "CodeStatus", "Bonus: Kode" },
        { "StatsText", "Statistik" },
        { "BagStatus", "Tas" },
        { "SpliceStatus", "Splice" },
        { "VendStatus", "Vending" },
        { "PabrikStatus", "Pabrik" },
        { "DropPointStatus", "Titik Drop" },
        { "RTStatus", "Dirt Farm" },
        { "RefInfo", "Koneksi" },
        { "ConfigStatus", "Config" },
        { "RejoinStatus", "Rejoin" },
        { "HookStatus", "Discord" },
    }

    -- tangkap isi panel tiap kali menu aslinya memperbarui teksnya
    for _, w in ipairs(WATCH) do
        local key, label = w[1], w[2]
        local el = UI[key]
        if type(el) == "table" and type(el.SetDesc) == "function" then
            local orig = el.SetDesc
            pcall(function()
                el.SetDesc = function(self, txt, ...)
                    if type(txt) == "string" then
                        Obs.Text[label] = txt
                        Obs.At[label] = clock()
                    end
                    return orig(self, txt, ...)
                end
            end)
        end
    end

    -- FPS
    local fps, acc, frames = 0, 0, 0
    table.insert(Connections, RunService.Heartbeat:Connect(function(dt)
        acc = acc + dt
        frames = frames + 1
        if acc >= 1 then
            fps = frames / acc
            acc, frames = 0, 0
        end
    end))

    local function s(v)
        if v == nil then return "-" end
        return tostring(v)
    end

    local function dur(sec)
        sec = floor(sec)
        if sec < 60 then return sec .. " dtk" end
        if sec < 3600 then return floor(sec / 60) .. " mnt " .. (sec % 60) .. " dtk" end
        return floor(sec / 3600) .. " jam " .. floor((sec % 3600) / 60) .. " mnt"
    end

    -- posisi karakter + sudah berapa lama tidak berpindah tile
    local pos = { x = nil, y = nil, t = clock() }
    local function samplePos()
        local ok, x, y = pcall(Auto.here)
        if not ok or not x then
            ok, x, y = pcall(getPlayerTile)
        end
        if not ok or not x then
            pos.x, pos.y, pos.t = nil, nil, clock()
            return
        end
        if x ~= pos.x or y ~= pos.y then
            pos.x, pos.y, pos.t = x, y, clock()
        end
    end

    local function lastLines(list, n)
        local out = {}
        if type(list) ~= "table" then return out end
        for i = math.max(1, #list - n + 1), #list do
            out[#out + 1] = tostring(list[i])
        end
        return out
    end

    -- daftar fitur: { nama, jalan?, info, apakah menggerakkan karakter }
    local function modules()
        local rt = Session.RT or {}
        return {
            { "Farm", State.Running == true,
                ("%s | place %s, break %s, ambil %s | %s"):format(s(State.Mode), s(State.Placed), s(State.Broken), s(State.Collected), s(State.LastAction)), true },
            { "Clear World", Clear.Running == true,
                ("pecah %s | sisa %s | %s"):format(s(Clear.Broken), s(Clear.Remaining), s(Clear.Status)), true },
            { "Farmer", Farmer.Running == true,
                ("tanam %s, panen %s | %s"):format(s(Farmer.Planted), s(Farmer.Harvested), s(Farmer.Status)), true },
            { "Splice", Splice.Running == true, s(Splice.Status), true },
            { "Pabrik", Pabrik.Running == true, s(Pabrik.Status), true },
            { "Vending", Vend.Running == true, s(Vend.Status), true },
            { "Dirt Farm", rt.Running == true,
                ("%s | %s | pecah %s, pasang %s"):format(s(rt.Phase), s(rt.Status), s(rt.Broken), s(rt.Placed)), true },
            { "Auto Chat", Spam.On == true, ("terkirim %s | %s"):format(s(Spam.Sent), s(Spam.Last)), false },
            { "Penjaga", Guard.On == true, s(Guard.Status or Guard.Mode), false },
            { "Bonus Quest/Kode", (Bonus.Quest == true) or (Bonus.Redeem == true),
                ("quest %s, kode %s"):format(Bonus.Quest and "on" or "off", Bonus.Redeem and "on" or "off"), false },
            { "Growscan Auto", Scan.Auto == true, "", false },
            { "Rejoin", Rejoin.On == true, s(Rejoin.Status), false },
        }
    end

    local function summaryText()
        local lines, now = {}, clock()
        for _, m in ipairs(modules()) do
            local name, on, info = m[1], m[2], m[3]
            if on then
                local line = "● " .. name .. "  JALAN"
                if info ~= "" then line = line .. "  " .. info end
                local sg = Obs.Sig[name]
                if not sg or sg.v ~= info then
                    Obs.Sig[name] = { v = info, t = now }
                elseif now - sg.t >= 20 then
                    line = line .. "  ⚠ tidak berubah " .. dur(now - sg.t)
                end
                lines[#lines + 1] = line
            else
                Obs.Sig[name] = nil
                lines[#lines + 1] = "○ " .. name
            end
        end
        return table.concat(lines, "\n")
    end

    local function warningText()
        local w, now = {}, clock()
        local movingOn = nil
        for _, m in ipairs(modules()) do
            if m[2] and m[4] then movingOn = movingOn or m[1] end
        end
        local onPicker = Guard.pickerOpen and Guard.pickerOpen()
        if movingOn and onPicker then
            w[#w + 1] = "Di layar pilih world padahal " .. movingOn .. " jalan" .. (Rejoin.On and " (Auto Rejoin akan masuk lagi)" or " (nyalakan Auto Rejoin supaya masuk lagi otomatis)")
        elseif movingOn and pos.x and now - pos.t >= 15 then
            w[#w + 1] = "Karakter diam " .. dur(now - pos.t) .. " di (" .. pos.x .. "," .. tostring(pos.y) .. ") padahal " .. movingOn .. " jalan"
        end
        local miss = {}
        for _, k in ipairs({ "World", "Inv", "SetTile", "State", "Punch" }) do
            if not Refs[k] then miss[#miss + 1] = k end
        end
        if #miss > 0 then
            w[#w + 1] = "Referensi game belum ketemu: " .. table.concat(miss, ", ") .. " (tekan 'Hubungkan ke game')"
        end
        if not OrigIsDown then
            w[#w + 1] = "Kontrol gerak game (WorldMenu.isDown) tidak ketemu: karakter tidak bisa digerakkan oleh script"
        end
        local rt = Session.RT
        if rt and rt.Running then
            local okp, list = pcall(Guard.playersHere)
            local others = (okp and type(list) == "table") and #list or 0
            if others >= 1 then
                w[#w + 1] = "Ada " .. others .. " pemain lain di world: Dirt Farm hanya jalan kalau kamu sendirian (menunggu)"
            end
            local beat = rt.Beat and (now - rt.Beat) or 0
            if beat >= 20 then
                w[#w + 1] = "Dirt Farm tidak memberi tanda hidup " .. dur(beat) .. " (kemungkinan macet di tahap '" .. s(rt.Phase) .. "')"
            end
        end
        if fps > 0 and fps < 20 then
            w[#w + 1] = ("FPS rendah (%.0f): aktifkan Mode Lite"):format(fps)
        end
        for _, m in ipairs(modules()) do
            local sg = Obs.Sig[m[1]]
            -- v2.2: hanya fitur yang menggerakkan karakter (Rejoin / Penjaga memang statusnya jarang berubah)
            if m[2] and m[4] and sg and now - sg.t >= 20 then
                w[#w + 1] = m[1] .. " jalan tapi tidak ada kemajuan " .. dur(now - sg.t) .. " (" .. m[3] .. ")"
            end
        end
        if #w == 0 then return "Tidak ada peringatan" end
        for i = 1, #w do w[i] = "⚠ " .. w[i] end
        return table.concat(w, "\n")
    end

    local function systemText()
        local W = Refs.World
        local lines = {}
        local wname = W and rawget(W, "name")
        lines[#lines + 1] = ("World   : %s (%s x %s)"):format(
            type(wname) == "string" and wname ~= "" and wname or "-", s(W and W.w), s(W and W.h))
        lines[#lines + 1] = "Posisi  : " .. (pos.x and ("(" .. pos.x .. "," .. tostring(pos.y) .. "), diam " .. dur(clock() - pos.t)) or "-")
        local okp, list = pcall(Guard.playersHere)
        if okp and type(list) == "table" then
            local names = {}
            for i, p in ipairs(list) do
                if i > 4 then names[#names + 1] = "+" .. (#list - 4) .. " lagi" break end
                names[#names + 1] = tostring(p.name)
            end
            lines[#lines + 1] = "Pemain  : " .. #list .. " lain" .. (#names > 0 and (" (" .. table.concat(names, ", ") .. ")") or "")
        end
        lines[#lines + 1] = ("FPS     : %.0f"):format(fps)
        lines[#lines + 1] = "Aktif   : " .. dur(clock() - Obs.T0)
        lines[#lines + 1] = "Gerak   : " .. (OrigIsDown and "hook isDown OK" or "hook isDown TIDAK ADA")
        lines[#lines + 1] = ("Refs    : World %s, Inv %s, SetTile %s, State %s, Punch %s, Others %s, Trees %s, Drop %s"):format(
            Refs.World and "ok" or "-", Refs.Inv and "ok" or "-", Refs.SetTile and "ok" or "-", Refs.State and "ok" or "-",
            Refs.Punch and "ok" or "-", Refs.Others and "ok" or "-", Refs.Trees and "ok" or "-", Drops.list and "ok" or "-")
        lines[#lines + 1] = ("Pengaturan: speed %s%%, infjump %s, ghost %s, lite %s"):format(
            s(Misc.Speed), Misc.InfJump and "on" or "off", Misc.Ghost and "on" or "off", State.LiteMode and "on" or "off")
        return table.concat(lines, "\n")
    end

    local function dirtText()
        local rt = Session.RT
        if not rt then return "Dirt Farm tidak ada" end
        local lines = {
            "Status : " .. (rt.Running and "JALAN" or "BERHENTI"),
            "Tahap  : " .. s(rt.Phase),
            "Info   : " .. s(rt.Status),
            "Detak  : " .. (rt.Beat and (floor(clock() - rt.Beat) .. " dtk lalu") or "-"),
            ("Hitung : pecah %s, pasang %s, tanam %s, panen %s, drop %s, buang %s"):format(
                s(rt.Broken), s(rt.Placed), s(rt.Planted), s(rt.Harvested), s(rt.Dropped), s(rt.Trashed)),
        }
        local log = lastLines(rt.Log, 12)
        if #log > 0 then
            lines[#lines + 1] = "Log (12 terakhir):"
            for _, l in ipairs(log) do lines[#lines + 1] = "- " .. l end
        else
            lines[#lines + 1] = "Log    : kosong"
        end
        return table.concat(lines, "\n")
    end

    local function detailText(label)
        local t = Obs.Text[label]
        if not t then return "(belum ada update dari menu ini)" end
        return t .. "\n[diperbarui " .. dur(clock() - (Obs.At[label] or clock())) .. " lalu]"
    end

    local function probeText()
        local P = Drops.Probe
        if not P or (P.nOk + P.nFail) == 0 then
            return "Belum ada data. Nyalakan mode Remote lalu jalankan Farm / collect sebentar"
        end
        local seen, list = {}, {}
        for k in pairs(P.ok) do if not seen[k] then seen[k] = true list[#list + 1] = k end end
        for k in pairs(P.fail) do if not seen[k] then seen[k] = true list[#list + 1] = k end end
        table.sort(list)
        local lines = {
            ("Diterima: %d | Ditolak: %d"):format(P.nOk, P.nFail),
            "Terjauh yang DITERIMA : " .. (P.okMax and ("%.2f tile"):format(P.okMax) or "-"),
            "Terdekat yang DITOLAK : " .. (P.failMin and ("%.2f tile"):format(P.failMin) or "-"),
            "Jarak (tile) : diterima / ditolak",
        }
        for i, b in ipairs(list) do
            if i > 14 then lines[#lines + 1] = "..." break end
            lines[#lines + 1] = ("%.1f-%.1f : %d / %d"):format(b, b + 0.5, P.ok[b] or 0, P.fail[b] or 0)
        end
        lines[#lines + 1] = "Catatan: ditolak bisa juga karena sebab lain (drop sudah diambil, dll), bukan hanya jarak"
        return table.concat(lines, "\n")
    end

    local function reportText()
        local parts = {
            "== SkyP Observasi ==",
            "-- Ringkasan --", summaryText(),
            "-- Peringatan --", warningText(),
            "-- Sistem --", systemText(),
            "-- Dirt Farm --", dirtText(),
            "-- Jarak ambil drop --", probeText(),
            "-- Diagnosa referensi --", Obs.Diag or "(belum dijalankan)",
            "-- Nametag --", (select(1, pcall(Misc.DumpNameTag)) and Misc.LastNameDump) or "(gagal membaca nametag)",
            "-- Detail menu --",
        }
        for _, w in ipairs(WATCH) do
            parts[#parts + 1] = "[" .. w[2] .. "]"
            parts[#parts + 1] = detailText(w[2])
        end
        return table.concat(parts, "\n")
    end
    Obs.report = reportText

    -----------------------------------------------------------------
    -- TAB
    -----------------------------------------------------------------
    local tab = makeTab("Observasi", "activity", "setel")
    safe(function()
        UI.ObsSummary = tab:Paragraph({ Title = "Ringkasan semua menu", Desc = "-" })
    end)
    safe(function()
        UI.ObsWarn = tab:Paragraph({ Title = "Peringatan", Desc = "-" })
    end)
    safe(function()
        UI.ObsSystem = tab:Paragraph({ Title = "Sistem", Desc = "-" })
    end)

    local ctl = box(tab, "Kontrol", true)
    safe(function()
        ctl:Toggle({
            Title = "Update otomatis",
            Desc = "Perbarui tab ini tiap 1 detik. Matikan kalau terasa berat",
            Value = true,
            Callback = function(on) Obs.On = on end,
        })
    end)
    local function refresh() end
    safe(function()
        ctl:Button({
            Title = "Segarkan sekarang",
            Desc = "Perbarui semua panel di tab ini satu kali",
            Callback = function() pcall(refresh) end,
        })
    end)
    safe(function()
        ctl:Button({
            Title = "Salin struktur nametag",
            Desc = "Kalau nama / bendera di atas karakter masih salah: tekan ini saat di dalam world, lalu kirim hasilnya ke developer",
            Callback = function()
                local ok, n = pcall(Misc.DumpNameTag)
                notify("Observasi", ok and ("Struktur nametag disalin (" .. tostring(n) .. " baris)") or ("Gagal: " .. tostring(n)), 4)
            end,
        })
    end)
    safe(function()
        ctl:Button({
            Title = "Salin laporan",
            Desc = "Salin semua isi observasi jadi satu teks (kirim ke developer kalau ada masalah)",
            Callback = function()
                local txt = reportText()
                local clip = setclipboard or toclipboard
                if clip then
                    pcall(clip, txt)
                    notify("Observasi", "Laporan disalin (" .. #txt .. " huruf)", 3)
                else
                    notify("Observasi", "Executor tidak punya setclipboard", 4)
                end
            end,
        })
    end)

    local dbox = box(tab, "Dirt Farm (tahap, info, log)", true)
    safe(function()
        UI.ObsDirt = dbox:Paragraph({ Title = "Dirt Farm", Desc = "-" })
    end)

    local pbox = box(tab, "Jarak ambil drop (ukur batas server)", true)
    safe(function()
        UI.ObsProbe = pbox:Paragraph({ Title = "Hasil ukur", Desc = "-" })
    end)
    safe(function()
        pbox:Button({
            Title = "Reset ukur",
            Desc = "Hapus data jarak, mulai hitung dari nol",
            Callback = function()
                Drops.Probe = { ok = {}, fail = {}, okMax = nil, failMin = nil, nOk = 0, nFail = 0 }
                Obs.Shown.probe = nil
            end,
        })
    end)

    local det = box(tab, "Detail tiap menu", false)
    local detEl = {}
    for _, w in ipairs(WATCH) do
        safe(function()
            detEl[w[2]] = det:Paragraph({ Title = w[2], Desc = "-" })
        end)
    end

    local function put(el, key, txt)
        if not el or Obs.Shown[key] == txt then return end
        Obs.Shown[key] = txt
        pcall(function() el:SetDesc(txt) end)
    end


    -----------------------------------------------------------------
    -- DIAGNOSA REFERENSI: catat bentuk data game sekarang (kalau pemindai World/Inventori gagal)
    -----------------------------------------------------------------
    local function keysOf(t, max)
        local out, n = {}, 0
        pcall(function()
            for k, v in next, t do
                n = n + 1
                if n <= max then
                    local tv = type(v)
                    local extra = (tv == "number" or tv == "boolean") and ("=" .. tostring(v)) or ""
                    out[#out + 1] = tostring(k) .. ":" .. tv .. extra
                end
            end
        end)
        return table.concat(out, ", ") .. (n > max and (" ...+" .. (n - max)) or "")
    end

    local function childNames(inst, max)
        local out = {}
        pcall(function()
            for i, c in ipairs(inst:GetChildren()) do
                if i > max then out[#out + 1] = "..." break end
                out[#out + 1] = c.Name
            end
        end)
        return table.concat(out, ", ")
    end

    local function runDiag()
        local L = {}
        local function add(x) L[#L + 1] = x end
        local exName = "?"
        if identifyexecutor then
            local okE, n, v = pcall(identifyexecutor)
            if okE then exName = tostring(n) .. (v and (" " .. tostring(v)) or "") end
        end
        add("Executor : " .. exName)
        add(("Fungsi   : getgc=%s getconsts=%s isexecutorclosure=%s debug.info=%s islclosure=%s"):format(
            tostring(getgc ~= nil), tostring(getconsts ~= nil), tostring(isexecutorclosure ~= nil),
            tostring(debug and debug.info ~= nil), tostring(islclosure ~= nil)))
        add("Modul    : Inventory=" .. tostring(type(InventoryModule)) .. " ItemDB=" .. tostring(type(ItemDB))
            .. " WorldMenu=" .. tostring(MenuModOk) .. " Particles=" .. tostring(ParticlesOk))
        add("Shared   : " .. childNames(Shared, 40))
        add("GameGui  : " .. childNames(GameGui, 40))
        add("WorldRemotes: " .. childNames(WorldRemotes, 30))
        add("Inventory(modul) kunci: " .. keysOf(InventoryModule, 30))
        if not getgc then
            add("getgc tidak ada: pemindaian tidak bisa jalan di executor ini")
            return table.concat(L, "\n")
        end
        local okG, gc = pcall(getgc, true)
        if not okG or type(gc) ~= "table" then
            add("getgc(true) GAGAL: " .. tostring(gc))
            return table.concat(L, "\n")
        end
        local nTab, nFn = 0, 0
        local worlds, invs, states, others = {}, {}, {}, {}
        local invMeta, exactWorld = 0, 0
        for i, v in ipairs(gc) do
            if i % 3000 == 0 then task.wait() end
            local tv = type(v)
            if tv == "table" then
                nTab = nTab + 1
                pcall(function()
                    local w, h = rawget(v, "w"), rawget(v, "h")
                    if type(w) == "number" and type(h) == "number" and w >= 20 and h >= 20 and w <= 3000 and h <= 3000 then
                        if #worlds < 5 then worlds[#worlds + 1] = v end
                        if type(rawget(v, "fg")) == "table" and type(rawget(v, "bg")) == "table" and rawget(v, "spawn") ~= nil then
                            exactWorld = exactWorld + 1
                        end
                    end
                    if type(rawget(v, "slots")) == "table" and #invs < 4 then invs[#invs + 1] = v end
                    if type(rawget(v, "state")) == "function" and #states < 3 then states[#states + 1] = v end
                    if type(rawget(v, "list")) == "function" and #others < 4 then others[#others + 1] = v end
                    if getmetatable(v) == InventoryModule then invMeta = invMeta + 1 end
                end)
            elseif tv == "function" then
                nFn = nFn + 1
            end
        end
        add(("getgc    : %d objek (%d tabel, %d fungsi)"):format(#gc, nTab, nFn))
        add(("World cocok pola lama (fg,bg,w,h,spawn): %d | kandidat (punya w & h): %d"):format(exactWorld, #worlds))
        for i, v in ipairs(worlds) do
            add(("  W%d: %s"):format(i, keysOf(v, 40)))
        end
        add(("Inventori: metatable cocok modul = %d | kandidat (punya slots) = %d"):format(invMeta, #invs))
        for i, v in ipairs(invs) do
            local mt = "-"
            pcall(function() mt = (getmetatable(v) == InventoryModule) and "=modul" or type(getmetatable(v)) end)
            add(("  I%d (metatable %s): %s"):format(i, mt, keysOf(v, 30)))
        end
        add("Posisi   : kandidat (fungsi state) = " .. #states)
        for i, v in ipairs(states) do
            local okS, res = pcall(rawget(v, "state"))
            add(("  S%d: %s"):format(i, okS and type(res) == "table" and keysOf(res, 25) or tostring(res)))
        end
        add("Pemain   : kandidat (fungsi list) = " .. #others)
        for i, v in ipairs(others) do
            add(("  O%d: %s"):format(i, keysOf(v, 25)))
        end
        return table.concat(L, "\n")
    end

    local dgbox = box(tab, "Diagnosa referensi (kalau 'Hubungkan ke game' gagal)", true)
    safe(function()
        UI.ObsDiag = dgbox:Paragraph({ Title = "Hasil diagnosa", Desc = "Belum dijalankan. Masuk ke world dulu, lalu tekan tombol di bawah" })
    end)
    safe(function()
        dgbox:Button({
            Title = "Jalankan diagnosa",
            Desc = "Scan memori game ±beberapa detik (layar bisa tersendat sebentar). Hasilnya ikut masuk ke 'Salin laporan'",
            Callback = function()
                task.spawn(function()
                    put(UI.ObsDiag, "diag", "Memindai...")
                    local ok, res = pcall(runDiag)
                    Obs.Diag = ok and res or ("Diagnosa error: " .. tostring(res))
                    put(UI.ObsDiag, "diag", Obs.Diag)
                    notify("Observasi", "Diagnosa selesai. Tekan 'Salin laporan' lalu kirim hasilnya", 5)
                end)
            end,
        })
    end)

    refresh = function()
        samplePos()
        put(UI.ObsSummary, "sum", summaryText())
        put(UI.ObsWarn, "warn", warningText())
        put(UI.ObsSystem, "sys", systemText())
        put(UI.ObsDirt, "dirt", dirtText())
        put(UI.ObsProbe, "probe", probeText())
        for _, w in ipairs(WATCH) do
            put(detEl[w[2]], "d:" .. w[2], detailText(w[2]))
        end
    end

    task.spawn(function()
        while alive() do
            if Obs.On then pcall(refresh) else samplePos() end
            task.wait(1)
        end
    end)
end)() end

-- [SkyP Cracked] License heartbeat loop removed

task.spawn(function()
    reconnect("SkyP v" .. Session.Lic.Ver)
    -- Penjaga dari config dinyalakan setelah data pemain ketemu
    -- (supaya pemain yang sudah ada dicatat dulu)
    if Config.saved("Penjaga", "On") == true and alive() then
        if UI.GuardToggle then pcall(function() UI.GuardToggle:Set(true) end) end
        if not Guard.On then Guard.set(true) end
    end
    Config.start()
    -- habis rejoin server: lanjutkan aktivitas sebelumnya
    Rejoin.startup(reconnect)
end)

task.spawn(function()
    while alive() do
        if not State.Running then updateStatus() end
        Auto.updateClearStatus()
        Auto.updateFarmerStatus()
        updateSpamStatus()
        if UI.ConfigStatus and Config.Status ~= Config.Shown then
            Config.Shown = Config.Status
            pcall(function() UI.ConfigStatus:SetDesc(Config.Status) end)
        end
        local nHour = 0
        for _, t in ipairs(Rejoin.Hist or {}) do
            if type(t) == "number" and os.time() - t < 3600 then nHour += 1 end
        end
        local rj = ("%s\nWorld tujuan: %s\nBerhasil masuk lagi: %d kali | Terlempar 1 jam terakhir: %d/%d%s"):format(
            Rejoin.Status, (Rejoin.targetWorld and Rejoin.targetWorld() ~= "") and Rejoin.targetWorld() or "-", Rejoin.Count,
            nHour, math.floor(tonumber(Rejoin.MaxPerHour) or 10), Rejoin.Paused and " (DIHENTIKAN)" or "")
        if UI.RejoinStatus and rj ~= Rejoin.Shown then
            Rejoin.Shown = rj
            pcall(function() UI.RejoinStatus:SetDesc(rj) end)
        end
        local hk = ("%s\nAntrian: %d pesan"):format(Hook.Status, #Hook.Queue)
        if UI.HookStatus and hk ~= Hook.Shown then
            Hook.Shown = hk
            pcall(function() UI.HookStatus:SetDesc(hk) end)
        end
        task.wait(1)
    end
end)

---------------------------------------------------------------------
-- CLEANUP (otomatis saat script dijalankan ulang)
---------------------------------------------------------------------
Session.Cleanup = function()
    State.Running = false
    Clear.Running = false
    Farmer.Running = false
    Spam.On = false
    if Config.AutoSave then pcall(Config.save, false) end -- simpan sebelum ditutup
    Guard.On = false
    Bonus.Quest, Bonus.Redeem = false, false
    Scan.Auto = false
    Splice.Running = false
    Rejoin.On = false
    if Session.RT then Session.RT.Running = false end
    Pabrik.Running = false
    State.Override = nil
    pcall(Auto.stopWalk)
    AutoInput.active = false
    pcall(Auto.releaseInput)
    for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
    -- kembalikan nama asli (watermark dilepas)
    Misc.CustomName = false
    pcall(nameRestore)
    -- kembalikan fungsi game ke asal
    pcall(setLite, false)
    pcall(unhookJammer)
    if OrigIsDown and MenuModOk and rawget(MenuModule, "isDown") == isDownWrapper then
        MenuModule.isDown = OrigIsDown
    end
    if Refs.World then
        if Misc.Ghost then pcall(function() Refs.World.ghost = false end) end
        if Misc.Speed ~= 100 then pcall(function() Refs.World.speedScale = 1 end) end
    end
    pcall(function() GridGui:Destroy() end)
    pcall(function() UI.SmartGui:Destroy() end)
    pcall(function() FlyPad:Destroy() end)
    pcall(function() Window:Destroy() end)
end
