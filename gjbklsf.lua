-- fenti | FREE SLOP
--
-- HOW TO NAVIGATE THIS FILE
--   Use your editor search (Ctrl+F) on the tag in the first column — each major block starts with the same tag in a section header.
--
--   TAG         HOW TO FIND STUFF 
--   [FENTI-00·loader] AC module — HttpGet + loadstring from default GitHub raw (override _G.FENTI_AC_MODULE_URL)
--   [FENTI-01]   Bootstrap + Potassium gate
--   [FENTI-02B]  Module picker UI (what features load)
--   [FENTI-02C]  Obsidian Library load + TextService patch
--   [FENTI-03]   Services (Strike watch lives in AC module)
--   [FENTI-04]   Player, character, remotes, QTE refs
--   [FENTI-04a]  Self aura (meshes / particles — Obsidian Aura tab)
--   [FENTI-05]   Constants (spots, executor checks, Support table)
--   [FENTI-06]   All shared state variables (+ Labels, caches)
--   [FENTI-07]   Small utils (session time, refresh char, anti-AFK, no-stun)
--   [FENTI-08]   Ban / fail logging (Adonis hooks in AC module)
--   [FENTI-09]   ESP (highlights, screen TextLabel, loops)
--   [FENTI-10]   (removed) aimbot / silent aim
--   [FENTI-11]   GetMousePos cleanup only
--   [FENTI-12]   Combat (triggerbot, screen shake)
--   [FENTI-13]   Horse + tween TP helpers
--   [FENTI-14]   Smart TP, root motion hold, reset TP
--   [FENTI-15]   NPCs, shop, proximity prompts, radius tick, chest helpers
--   [FENTI-16]   Auto dialogue / reroll (IIFE → _G.fentiDialogue)
--   [FENTI-17]   Fishing (rod, bait, cast/catch loop, bobber scan, bite → completeBiteMinigame)
--                  [FENTI-17·mash] _G.fentiGetMashingContainer IIFE
--                  [FENTI-17a]     bobber / instaprompt IIFE
--                  [FENTI-17b]     QTE auto-mash IIFE
--   [FENTI-18]   Chest / corpse / saints farm (_G.FentiFarm IIFE)
--   [FENTI-20]   Webhook
--   [FENTI-21]   Serverhop
--   [FENTI-22]   Obsidian UI: Information → Players → Fishing → Teleport → Saints → D4C farm → Aimbot → NPCs → Aura → Config
--   [FENTI-23]   Post-UI startup notify
--
-- NOTE: Luau limits ~200 locals per function prototype — plain `do` still counts toward the main chunk; use (function() … end)().
-- AC bypass (required): hub always fetches the module via prelude HttpGet + loadstring.
--   Override URL only: _G.FENTI_AC_MODULE_URL = "https://raw.githubusercontent.com/…/your_ac.lua" (non-empty string before run).
--   If HttpGet fails or the chunk is invalid, the hub stops (warn + return). No stub / no inject-only path.
-- AC module: _G.FENTI_AC_SILENT = true skips the success print in fenti_ac_bypass.lua (optional).
-- Tunables (read by AC module): FENTI_SAFE_AC, FENTI_ENABLE_MODULE8, FENTI_ENABLE_ADONIS_GC, FENTI_TREE_DESTROY_PASS, etc.
do
    (function()
        local g = _G
        pcall(function()
            local ls = loadstring
            if type(ls) == "function" and rawget(g, "loadstring") == nil then rawset(g, "loadstring", ls) end
        end)
        pcall(function()
            local ld = load
            if type(ld) == "function" and rawget(g, "load") == nil then rawset(g, "load", ld) end
        end)
        pcall(function()
            local gg = getgenv
            if type(gg) == "function" and rawget(g, "getgenv") == nil then rawset(g, "getgenv", gg) end
        end)
        pcall(function()
            local gr = getrenv
            if type(gr) == "function" and rawget(g, "getrenv") == nil then rawset(g, "getrenv", gr) end
        end)
        pcall(function()
            local s = syn
            if type(s) == "table" and type(rawget(g, "syn")) ~= "table" then rawset(g, "syn", s) end
        end)
        pcall(function()
            local h = http
            if type(h) == "table" and type(rawget(g, "http")) ~= "table" then rawset(g, "http", h) end
        end)
        pcall(function()
            local hr = http_request
            if type(hr) == "function" and rawget(g, "http_request") == nil then rawset(g, "http_request", hr) end
        end)
        pcall(function()
            local rq = request
            if type(rq) == "function" and rawget(g, "request") == nil then rawset(g, "request", rq) end
        end)
        if type(rawget(g, "identifyexecutor")) == "boolean" then
            g.identifyexecutor = function() return "Unknown" end
        end
        local function fentiEnvAccessor(name)
            return rawget(g, name)
        end
        -- Strict getgenv: never call getgenv() with no args; only getgenv(0..7) or getgenv(thread) inside pcall.
        local function fentiTryExecutorEnvTable(envFn)
            if type(envFn) ~= "function" then return nil end
            for level = 0, 7 do
                local ok, t = pcall(function()
                    return envFn(level)
                end)
                if ok and type(t) == "table" then return t end
            end
            local th = coroutine.running()
            if th then
                local ok2, t2 = pcall(function()
                    return envFn(th)
                end)
                if ok2 and type(t2) == "table" then return t2 end
            end
            return nil
        end
        local function fentiPickCompiler(env)
            if type(env) ~= "table" then return nil end
            local ls = rawget(env, "loadstring")
            if type(ls) == "function" then return ls end
            local ld = rawget(env, "load")
            if type(ld) == "function" then return ld end
            return nil
        end
        local function fentiResolveCompiler()
            local c = fentiPickCompiler(g)
            if c then return c end
            local sh = rawget(g, "shared")
            if type(sh) == "table" then
                c = fentiPickCompiler(sh)
                if c then return c end
            end
            do
                local gg = fentiEnvAccessor("getgenv")
                if type(gg) == "function" then
                    local ge = fentiTryExecutorEnvTable(gg)
                    if ge then
                        c = fentiPickCompiler(ge)
                        if c then return c end
                    end
                end
            end
            do
                local gr = fentiEnvAccessor("getrenv")
                if type(gr) == "function" then
                    local re = fentiTryExecutorEnvTable(gr)
                    if re then
                        c = fentiPickCompiler(re)
                        if c then return c end
                    end
                end
            end
            do
                local ok, ls = pcall(function() return loadstring end)
                if ok and type(ls) == "function" then return ls end
                local ok2, ld = pcall(function() return load end)
                if ok2 and type(ld) == "function" then return ld end
            end
            return nil
        end
        -- HttpGet first; fallbacks use rawget(_G, …) after bootstrap mirrors above.
        local function fentiPickRequest(env)
            if type(env) ~= "table" then return nil end
            local synr = rawget(env, "syn")
            if type(synr) == "table" and type(synr.request) == "function" then return synr.request end
            local httpt = rawget(env, "http")
            if type(httpt) == "table" and type(httpt.request) == "function" then return httpt.request end
            for _, k in ipairs({ "http_request", "request", "fluxus_request" }) do
                local f = rawget(env, k)
                if type(f) == "function" then return f end
            end
            return nil
        end
        local function fentiResolveRequest()
            local r = fentiPickRequest(g)
            if r then return r end
            local sh = rawget(g, "shared")
            if type(sh) == "table" then
                r = fentiPickRequest(sh)
                if r then return r end
            end
            do
                local gg = fentiEnvAccessor("getgenv")
                if type(gg) == "function" then
                    local ge = fentiTryExecutorEnvTable(gg)
                    if ge then
                        r = fentiPickRequest(ge)
                        if r then return r end
                    end
                end
            end
            do
                local gr = fentiEnvAccessor("getrenv")
                if type(gr) == "function" then
                    local re = fentiTryExecutorEnvTable(gr)
                    if re then
                        r = fentiPickRequest(re)
                        if r then return r end
                    end
                end
            end
            return nil
        end
        g.fentiHttpGet = function(url)
            if type(url) ~= "string" then return nil end
            local ok, body = pcall(function()
                return game:HttpGet(url)
            end)
            if ok and type(body) == "string" and #body > 80 then return body end
            local req = fentiResolveRequest()
            if type(req) == "function" then
                local ok2, res = pcall(function()
                    return req({
                        Url = url,
                        Method = "GET",
                        Headers = { ["User-Agent"] = "Mozilla/5.0 (compatible; Roblox)" },
                    })
                end)
                if ok2 and type(res) == "table" and type(res.Body) == "string" and #res.Body > 80 then
                    return res.Body
                end
            end
            warn("[fenti] fentiHttpGet: no usable body for " .. url:sub(1, 100))
            return nil
        end
        g.fentiLoadstringRun = function(source, tag)
            tag = tostring(tag or "?")
            if type(source) ~= "string" or #source < 50 then
                warn("[fenti] empty/short source for " .. tag .. " (len=" .. tostring(type(source) == "string" and #source or 0) .. ")")
                return nil
            end
            local ls = fentiResolveCompiler()
            if type(ls) ~= "function" then
                warn("[fenti] No loadstring/load — executor did not expose compiler APIs (cannot load " .. tag .. ").")
                return nil
            end
            local chunkName = "fenti_" .. tag:gsub("[^%w_]", "_")
            local chunk, compileErr
            do
                local ok1, a1, a2 = pcall(function()
                    return ls(source, chunkName)
                end)
                if ok1 and type(a1) == "function" then
                    chunk, compileErr = a1, a2
                else
                    local ok2, b1, b2 = pcall(function()
                        return ls(source)
                    end)
                    if ok2 and type(b1) == "function" then
                        chunk, compileErr = b1, b2
                    end
                end
            end
            if type(chunk) ~= "function" then
                warn("[fenti] compile failed " .. tag .. " got=" .. type(chunk) .. " err=" .. tostring(compileErr))
                return nil
            end
            local ok, res = pcall(chunk)
            if not ok then
                warn("[fenti] running chunk failed (" .. tag .. "): " .. tostring(res))
                return nil
            end
            return res
        end
    end)()
    end
    
    -- [FENTI-00·loader] AC module — always HttpGet + loadstring (default GitHub raw). Hub does not start without it.
    local FENTI_AC_REQUIRED_API = { "earlyPass", "registerModule8", "destroyStrike", "stripACLIInFolder", "setupStrikeWatch", "lateInit" }
    local FENTI_AC_MODULE_URL_DEFAULT = "https://raw.githubusercontent.com/dfgkl5kubnfik5gchlindfg45/DKLNBVJKKKWEJKHCVUUCIVBUNOIUADSRT/refs/heads/main/a.lua"
    local _fentiAcUrlOverride = rawget(_G, "FENTI_AC_MODULE_URL")
    local FENTI_AC_MODULE_URL = type(_fentiAcUrlOverride) == "string" and #_fentiAcUrlOverride > 0 and _fentiAcUrlOverride or FENTI_AC_MODULE_URL_DEFAULT
    local fentiAC = { loaded = false, api = nil, err = nil, source = "none" }
    if not _G.fentiHttpGet or not _G.fentiLoadstringRun then
        fentiAC.err = "Prelude missing fentiHttpGet / fentiLoadstringRun"
    else
        local okLoad, errLoad = pcall(function()
            local src = _G.fentiHttpGet(FENTI_AC_MODULE_URL)
            if type(src) ~= "string" or #src < 80 then error("short_or_empty_http") end
            local api = _G.fentiLoadstringRun(src, "fenti.AC")
            if type(api) ~= "table" then error("return_not_table") end
            for _, need in ipairs(FENTI_AC_REQUIRED_API) do
                if type(api[need]) ~= "function" then error("missing_api:" .. need) end
            end
            fentiAC.api = api
            fentiAC.loaded = true
            fentiAC.source = "http"
        end)
        if not okLoad then fentiAC.err = tostring(errLoad) end
    end
    _G.fentiAC = fentiAC
    if not fentiAC.loaded then
        warn("[fenti] AC module required — " .. tostring(fentiAC.err))
        return
    end
    pcall(function() fentiAC.api.earlyPass() end)
    
    -- [FENTI-00] Module 8 flag (implementation lives in AC module via registerModule8)
    local _fentiSafeAc = rawget(_G, "FENTI_SAFE_AC") == true
    local _fentiStrictPlace = rawget(_G, "FENTI_STRICT_MODE") == true
    local FENTI_MODULE8_ENABLED = not _fentiStrictPlace and not _fentiSafeAc and rawget(_G, "FENTI_DISABLE_MODULE8") ~= true
        and rawget(_G, "FENTI_ENABLE_MODULE8") == true
    pcall(function() fentiAC.api.registerModule8(FENTI_MODULE8_ENABLED) end)
    -- Before K-gate / RS watchers (string.char — weak obfuscators won't see plaintext folder name).
    local FENTI_RS_STRIKE_NAME = string.char(83, 116, 114, 105, 107, 101)
    local FENTI_RS_STRIKE_NAME_LOWER = string.char(115, 116, 114, 105, 107, 101)
    local FENTI_CLASS_REMOTE_FUNCTION = string.char(82, 101, 109, 111, 116, 101, 70, 117, 110, 99, 116, 105, 111, 110)
    local FENTI_CLASS_REMOTE_EVENT = string.char(82, 101, 109, 111, 116, 101, 69, 118, 101, 110, 116)
    local FENTI_CLASS_UNRELIABLE_REMOTE_EVENT = string.char(85, 110, 114, 101, 108, 105, 97, 98, 108, 101, 82, 101, 109, 111, 116, 101, 69, 118, 101, 110, 116)
    
    -- ----------------------------------------------------------------------------
    -- [FENTI-01] 1. BOOTSTRAP
    -- ----------------------------------------------------------------------------
    repeat task.wait() until game:IsLoaded()
    task.wait(2)
    if FENTI_MODULE8_ENABLED then
        pcall(function() _G.fentiModule8Run("after IsLoaded+2s") end)
    end
    
    -- Potassium: freeze → bypass → unfreeze → watch (before loader / hub). Ban still fires = log + exit chunk.
    _G.fentiPotassiumAbort = false
    _G.fentiExecutorWasPotassium = false
    do
    (function()
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local Workspace = game:GetService("Workspace")
        local ReplicatedFirst = game:GetService("ReplicatedFirst")
        local StarterGui = game:GetService("StarterGui")
        local RStorage = game:GetService("ReplicatedStorage")
        local GuiService = game:GetService("GuiService")
        local lp = Players.LocalPlayer
        if not lp then return end
    
        local ex = ""
        -- Must not use (identifyexecutor and identifyexecutor()): some loaders set identifyexecutor = true (boolean) → call crashes.
        pcall(function()
            if type(identifyexecutor) == "function" then
                local ok, r = pcall(identifyexecutor)
                if ok and type(r) == "string" then ex = string.lower(r) end
            end
        end)
        local isK = string.find(ex, "potassium", 1, true) ~= nil
        pcall(function()
            if _G.Potassium or _G.Pot or _G.KPot then isK = true end
        end)
        if not isK then return end
        _G.fentiExecutorWasPotassium = true
        -- Full K-gate (freeze, disable all RF/SG scripts, strip, spoof) crashes some places; SAFE_AC keeps monitoring flags only.
        if rawget(_G, "FENTI_SAFE_AC") == true then return end
    
        local function klog(msg)
            local line = os.date("%Y-%m-%d %H:%M:%S") .. " [K-GATE] " .. tostring(msg):sub(1, 480)
            warn("[fenti] " .. line)
            pcall(function()
                if makefolder then makefolder("fail logs") end
                if writefile then
                    local path = "fail logs/fenti_potassium_gate.txt"
                    local prev = ""
                    if isfile and readfile and isfile(path) then prev = readfile(path) end
                    writefile(path, prev .. line .. "\n")
                end
            end)
        end
    
        klog("FREEZE_START place=" .. tostring(game.PlaceId) .. " executor=" .. tostring(ex))
    
        local freezeCamConn = nil
        local frozenCF = nil
        pcall(function()
            local cam = Workspace.CurrentCamera
            if cam then
                frozenCF = cam.CFrame
                cam.CameraType = Enum.CameraType.Scriptable
                freezeCamConn = RunService.RenderStepped:Connect(function()
                    pcall(function()
                        if frozenCF and cam.Parent then cam.CFrame = frozenCF end
                    end)
                end)
            end
        end)
    
        pcall(function()
            local char = lp.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hrp then
                hrp.Anchored = true
                hrp.AssemblyLinearVelocity = Vector3.zero
            end
            if hum then
                hum.PlatformStand = true
                hum.WalkSpeed = 0
                hum.JumpPower = 0
            end
        end)
    
        pcall(function()
            for _, root in ipairs({ ReplicatedFirst, StarterGui }) do
                for _, obj in ipairs(root:GetDescendants()) do
                    if obj:IsA("LocalScript") then pcall(function() obj.Disabled = true end) end
                end
            end
        end)
    
        task.wait(0.25)
    
        klog("BYPASS_PHASE")
    
        pcall(function()
            local s = RStorage:FindFirstChild(FENTI_RS_STRIKE_NAME, true)
            if not s then return end
            if _G.fentiAC and _G.fentiAC.loaded and type(_G.fentiAC.api.destroyStrike) == "function" then
                pcall(_G.fentiAC.api.destroyStrike)
            end
            s = RStorage:FindFirstChild(FENTI_RS_STRIKE_NAME, true)
            if s then s:Destroy() end
            klog("k_RS_folder_cleared")
        end)
        for _, n in ipairs({ "Krypton", "Kripton" }) do
            pcall(function()
                local k = RStorage:FindFirstChild(n)
                if k then k:Destroy(); klog("removed_" .. n) end
            end)
        end
    
        local function stripACLI(folder)
            if _G.fentiAC and _G.fentiAC.loaded and type(_G.fentiAC.api.stripACLIInFolder) == "function" then
                pcall(_G.fentiAC.api.stripACLIInFolder, folder)
            end
        end
        stripACLI(ReplicatedFirst)
        stripACLI(StarterGui)
    
        if FENTI_MODULE8_ENABLED then
            pcall(function() _G.fentiModule8Run("potassium_gate", true) end)
        end
    
        pcall(function()
            if identifyexecutor then
                identifyexecutor = function()
                    return "Roblox"
                end
                klog("identifyexecutor_spoof_active")
            end
        end)
    
        klog("UNFREEZE_SCRIPTS")
    
        pcall(function()
            for _, root in ipairs({ ReplicatedFirst, StarterGui }) do
                for _, obj in ipairs(root:GetDescendants()) do
                    if obj:IsA("LocalScript") then
                        local ln = string.lower(obj.Name)
                        if not (string.find(ln, "acli", 1, true) or string.find(ln, "adonis", 1, true)) then
                            pcall(function() obj.Disabled = false end)
                        end
                    end
                end
            end
        end)
    
        pcall(function()
            if freezeCamConn then freezeCamConn:Disconnect() end
        end)
        pcall(function()
            local cam = Workspace.CurrentCamera
            if cam then cam.CameraType = Enum.CameraType.Custom end
        end)
        pcall(function()
            local char = lp.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hrp then pcall(function() hrp.Anchored = false end) end
            if hum then hum.PlatformStand = false end
        end)
    
        pcall(function()
            RStorage.ChildAdded:Connect(function(ch)
                task.defer(function()
                    local ln = string.lower(ch.Name)
                    if ln == FENTI_RS_STRIKE_NAME_LOWER then pcall(function() ch:Destroy() end); return end
                    if string.find(ln, "acli", 1, true) or string.find(ln, "adonis", 1, true) then
                        pcall(function() ch:Destroy() end)
                        return
                    end
                    if ln == "krypton" or ln == "kripton" then pcall(function() ch:Destroy() end) end
                end)
            end)
        end)
        pcall(function()
            ReplicatedFirst.ChildAdded:Connect(function(ch)
                if not ch:IsA("LocalScript") then return end
                task.defer(function()
                    local ln = string.lower(ch.Name)
                    if string.find(ln, "acli", 1, true) or string.find(ln, "adonis", 1, true) then
                        pcall(function()
                            ch.Disabled = true
                            ch:Destroy()
                        end)
                    end
                end)
            end)
        end)
    
        local kickSeen, kickMsg = false, ""
        local oldKickRef = nil
        pcall(function()
            oldKickRef = lp.Kick
            if typeof(oldKickRef) == "function" then
                lp.Kick = function(self, ...)
                    kickSeen = true
                    kickMsg = tostring(select(1, ...) or "")
                    klog("KICK_INTERCEPTED msg=" .. kickMsg:sub(1, 300))
                end
            end
        end)
    
        local lastGuiErr = ""
        local guiConn
        pcall(function()
            guiConn = GuiService.ErrorMessageChanged:Connect(function(msg)
                if type(msg) == "string" and msg ~= "" then
                    lastGuiErr = msg
                    local low = string.lower(msg)
                    if string.find(low, "kick", 1, true) or string.find(low, "ban", 1, true) or string.find(low, "moderat", 1, true) then
                        klog("GUI_KICKLIKE msg=" .. msg:sub(1, 280))
                    end
                end
            end)
        end)
    
        klog("WATCH_WINDOW_8s")
    
        task.wait(8)
    
        pcall(function()
            if guiConn then guiConn:Disconnect() end
        end)
        pcall(function()
            if oldKickRef and typeof(oldKickRef) == "function" then lp.Kick = oldKickRef end
        end)
    
        if kickSeen then
            klog("ABORT_REASON=Player.Kick_called_before_hub msg=" .. kickMsg:sub(1, 400))
            klog("NOTE=Potassium_or_game_kicked_during_gate_game_may_still_disconnect_if_Kick_not_hookable")
            _G.fentiPotassiumAbort = true
            return
        end
    
        local lowErr = string.lower(lastGuiErr)
        if lastGuiErr ~= "" and (string.find(lowErr, "kick", 1, true) or string.find(lowErr, "banned", 1, true) or string.find(lowErr, "moderat", 1, true)) then
            klog("ABORT_REASON=GuiService_kicklike_message msg=" .. lastGuiErr:sub(1, 400))
            _G.fentiPotassiumAbort = true
            return
        end
    
        klog("GATE_OK_loading_hub")
    end)()
    end
    
    if _G.fentiPotassiumAbort then
        warn("[fenti] Potassium gate stopped the hub — see fail logs/fenti_potassium_gate.txt for ABORT_REASON lines.")
        return
    end
    
    -- ----------------------------------------------------------------------------
    -- [FENTI-02B] 2B. OBSIDIAN LIBRARY LOAD (no module picker — Fishing + NPC TP only)
    -- ----------------------------------------------------------------------------
    local LoadModules = { Fishing = true, Combat = false, ESP = false, Chests = false, Teleport = false, Horse = true, Misc = false }
    local FENTI_OBSIDIAN_REPO = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
    local Library = nil
    
    do
        pcall(function()
            local src = _G.fentiHttpGet(FENTI_OBSIDIAN_REPO .. "Library.lua")
            if src then Library = _G.fentiLoadstringRun(src, "Obsidian.Library") end
        end)
        if not Library then
            warn("[fenti] Obsidian Library did not load. If HttpGet is blocked, allow request() in your key script.")
            return
        end
    end
    
    -- ----------------------------------------------------------------------------
    -- [FENTI-02C] 2C. OBSIDIAN UI LIBRARY (Library loaded inside picker above)
    -- ----------------------------------------------------------------------------
    
    do
        local TextService = game:GetService("TextService")
        local _origGetTextBounds = Library.GetTextBounds
        local needsPatch = not pcall(function()
            local p = Instance.new("GetTextBoundsParams")
            p.Text = "t"
            p.Size = 14
            p.Font = Font.fromEnum(Enum.Font.SourceSans)
            p.Width = 100
            local b = TextService:GetTextBoundsAsync(p)
            local _ = b.X
        end)
        if needsPatch then
            Library.GetTextBounds = function(self, Text, FontObj, Size, Width)
                local enumFont = Enum.Font.SourceSans
                pcall(function()
                    if typeof(FontObj) == "Font" then
                        local family = FontObj.Family or ""
                        for _, f in ipairs(Enum.Font:GetEnumItems()) do
                            if family:find(f.Name) then enumFont = f; break end
                        end
                    elseif typeof(FontObj) == "EnumItem" then
                        enumFont = FontObj
                    end
                end)
                local plain = tostring(Text or ""):gsub("<[^>]+>", "")
                local ok, result = pcall(function()
                    return TextService:GetTextSize(plain, Size or 14, enumFont, Vector2.new(Width or 1000, 10000))
                end)
                if ok and result then return result.X, result.Y end
                local estW = #plain * (Size or 14) * 0.55
                local estH = (Size or 14) * 1.3
                if Width and estW > Width then estH = estH * math.ceil(estW / Width); estW = Width end
                return estW, estH
            end
        end
    end
    
    local ThemeManager
    pcall(function()
        local src = _G.fentiHttpGet(FENTI_OBSIDIAN_REPO .. "addons/ThemeManager.lua")
        if src then ThemeManager = _G.fentiLoadstringRun(src, "Obsidian.ThemeManager") end
    end)
    local SaveManager
    pcall(function()
        local src = _G.fentiHttpGet(FENTI_OBSIDIAN_REPO .. "addons/SaveManager.lua")
        if src then SaveManager = _G.fentiLoadstringRun(src, "Obsidian.SaveManager") end
    end)
    local Options = Library.Options
    local Toggles = Library.Toggles
    Library.ForceCheckbox = true
    Library.ShowToggleFrameInKeybinds = true
    
    -- ----------------------------------------------------------------------------
    -- [FENTI-03] 3. SERVICES
    -- ----------------------------------------------------------------------------
    local Players = game:GetService("Players")
    local RS = game:GetService("ReplicatedStorage")
    local RunService = game:GetService("RunService")
    local UIS = game:GetService("UserInputService")
    local VirtualUser; pcall(function() VirtualUser = game:GetService("VirtualUser") end)
    local HttpService = game:GetService("HttpService")
    local Marketplace = game:GetService("MarketplaceService")
    local TeleportService = game:GetService("TeleportService")
    local GuiService = game:GetService("GuiService")
    local camera = workspace.CurrentCamera
    
    pcall(function()
        if fentiAC.loaded and type(fentiAC.api.setupStrikeWatch) == "function" then
            fentiAC.api.setupStrikeWatch(RS, UIS, FENTI_MODULE8_ENABLED)
        end
    end)
    
    -- ----------------------------------------------------------------------------
    -- [FENTI-04] 4. PLAYER / CHARACTER / REMOTES
    -- ----------------------------------------------------------------------------
    local player = Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    
    
    local Remotes = RS:FindFirstChild("Remotes")
    local remote = Remotes and Remotes:FindFirstChild("UseTool")
    local ToggleHorseRemote = Remotes and Remotes:FindFirstChild("ToggleHorse")
    local HorseControlEvent = RS:FindFirstChild("HorseControlEvent")
    local DialogueRemote = Remotes and Remotes:FindFirstChild("DialogueRemote")
    local GunActionRemote = Remotes and Remotes:FindFirstChild("GunAction")
    
    local playerGui = player:WaitForChild("PlayerGui")
    local QTE = {}
    QTE.system = playerGui:FindFirstChild("MashingSystem") or playerGui:WaitForChild("MashingSystem", 5)
    QTE.container = QTE.system and (QTE.system:FindFirstChild("Container") or QTE.system:WaitForChild("Container", 5))
    if not QTE.system or not QTE.container then warn("QTE System not found!") end
    -- ----------------------------------------------------------------------------
    -- [FENTI-04a] Self aura (your models; Obsidian tab: Aura)
    -- ----------------------------------------------------------------------------
    do
    (function()
    local LocalPlayer = player
    
    
    local SELF_AURA_TEXTURE            = "rbxassetid://6347925"
    local SUSSANO_MESH_ID              = "rbxassetid://8052040362"
    local SUSSANO_SIZE                 = Vector3.new(1, 1, 1)
    local SUSSANO_COLOR                = Color3.fromRGB(98, 37, 209)
    local FUSED_ZAMASU_MESH_ID         = "rbxassetid://749282412"
    local FUSED_ZAMASU_SIZE            = Vector3.new(7.5, 6.6, 0.05)
    local FUSED_ZAMASU_COLOR           = Color3.fromRGB(255, 255, 255)
    local SIX_PATHS_MESH_ID            = "rbxassetid://10549281129"
    local SIX_PATHS_TEXTURE_ID         = "rbxassetid://10549281279"
    local SIX_PATHS_SCALE              = Vector3.new(0.1, 0.1, 0.1)
    local SIX_PATHS_COLOR              = Color3.fromRGB(255, 255, 255)
    local ANGEL_WINGS_MESH_ID          = "rbxassetid://96334959293762"
    local ANGEL_WINGS_TEXTURE_ID       = "rbxassetid://96334959293762"
    local ANGEL_WINGS_SIZE             = Vector3.new(2, 1, 1.0)
    local ANGEL_WINGS_COLOR            = Color3.fromRGB(163, 162, 165)
    local ANGEL_HALO_MESH_ID           = "rbxassetid://14459675588"
    local ANGEL_HALO_TEXTURE_ID        = "rbxassetid://14459675588"
    local ANGEL_HALO_SIZE              = Vector3.new(1, 0.369, 1)
    local ANGEL_HALO_COLOR             = Color3.fromRGB(163, 162, 165)
    local ANGEL_HALO_OFFSET            = Vector3.new(0, 2.654, 0)
    local INFINITY_COLOR               = Color3.fromRGB(85, 0, 255)
    local INFINITY_TEXTURES            = { "rbxassetid://8214516794", "rbxassetid://3074825547", "rbxassetid://7451697448" }
    local INFINITY_TORSO_CAM_TEXTURES  = { "rbxassetid://1084999891", "rbxassetid://1075864321", "rbxassetid://13350929609" }
    local INFINITY_TORSO_EXTRA_TEXTURE = "rbxassetid://7387058218"
    
    local HALO_PARTICLES = {
        { color = Color3.fromRGB(244,105,255), texture = "rbxassetid://890403512", lightEmission = 0.25, lightInfluence = 1, lifetime = {min=0.5,max=0.65}, rate = 150, rotation = 0, rotSpeed = 0, speed = 3.5, spreadAngleX = 0, spreadAngleY = 0, size = 4 },
        { color = Color3.fromRGB(87,255,87),  texture = "rbxassetid://890402558", lightEmission = 1,    lightInfluence = 1, lifetime = {min=0.5,max=0.65}, rate = 150, rotation = 0, rotSpeed = 0, speed = 5,   spreadAngleX = 0, spreadAngleY = 0, size = 4 },
        { color = Color3.fromRGB(255,255,255),texture = "rbxassetid://572215241", lightEmission = 1,    lightInfluence = 1, lifetime = {min=0.25,max=0.5}, rate = 25,  rotation = 0, rotSpeed = 0, speed = 1,   spreadAngleX = 0, spreadAngleY = 0, size = 1.25 },
    }
    
    local MUI_PARTICLES = {
        { colorSequence=true, colorA=Color3.fromRGB(0,0,170),    colorB=Color3.fromRGB(0,140,255),   texture="rbxassetid://1084987899",  lightEmission=1, lightInfluence=1, lifetime={min=5,max=6},      rate=25, rotation=0,    rotationMax=0,   rotSpeed=-50,  rotSpeedMax=50,  speed=0,     spreadAngleX=0,   spreadAngleY=0,   size=0.8,   shapeInOut=Enum.ParticleEmitterShapeInOut.Outward,   shapeStyle=Enum.ParticleEmitterShapeStyle.Volume },
        { colorSequence=true, colorA=Color3.fromRGB(0,0,85),     colorB=Color3.fromRGB(0,125,190),   texture="rbxassetid://12026515010", lightEmission=1, lightInfluence=1, lifetime={min=0.75,max=0.75},rate=25, rotation=-360, rotationMax=360, rotSpeed=-100, rotSpeedMax=100, speed=0.25,  spreadAngleX=25,  spreadAngleY=25,  size=1.4,   shapeInOut=Enum.ParticleEmitterShapeInOut.InAndOut,  shapeStyle=Enum.ParticleEmitterShapeStyle.Volume },
        { colorSequence=true, colorA=Color3.fromRGB(0,180,255),  colorB=Color3.fromRGB(180,195,255), texture="rbxassetid://1075864321",  lightEmission=1, lightInfluence=1, lifetime={min=1,max=1},      rate=6,  rotation=0,    rotationMax=0,   rotSpeed=0,    rotSpeedMax=0,   speed=0.125, spreadAngleX=360, spreadAngleY=360, size=3.375, shapeInOut=Enum.ParticleEmitterShapeInOut.Outward,   shapeStyle=Enum.ParticleEmitterShapeStyle.Volume },
        { colorSequence=true, colorA=Color3.fromRGB(0,0,85),     colorB=Color3.fromRGB(0,125,190),   texture="http://www.roblox.com/asset/?id=7451746284", lightEmission=1, lightInfluence=1, lifetime={min=1,max=1}, rate=35, rotation=-360, rotationMax=360, rotSpeed=-100, rotSpeedMax=100, speed=0.125, spreadAngleX=360, spreadAngleY=360, size=0.35, shapeInOut=Enum.ParticleEmitterShapeInOut.InAndOut, shapeStyle=Enum.ParticleEmitterShapeStyle.Volume },
        { colorSequence=true, colorA=Color3.fromRGB(0,0,90),     colorB=Color3.fromRGB(10,250,210),  texture="rbxassetid://8012987204",  lightEmission=1, lightInfluence=1, lifetime={min=1,max=1},      rate=35, rotation=-360, rotationMax=360, rotSpeed=-100, rotSpeedMax=100, speed=0.1,   spreadAngleX=360, spreadAngleY=360, size=0.8,   shapeInOut=Enum.ParticleEmitterShapeInOut.Outward,   shapeStyle=Enum.ParticleEmitterShapeStyle.Volume },
    }
    
    local MUI_TORSO_GLOW_PARTICLE = {
        color=Color3.fromRGB(188,203,255), texture="rbxassetid://1075864321", lightEmission=1, lightInfluence=1,
        lifetime={min=1,max=1}, rate=6, rotation=0, rotationMax=0, rotSpeed=0, rotSpeedMax=0,
        speed=0.125, spreadAngleX=360, spreadAngleY=360, size=1,
    }
    
    local CRIMSON_MOON_PARTICLES = {
        { colorSequence=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(1,0,0)),ColorSequenceKeypoint.new(0.5,Color3.new(1,0.388235,0.388235)),ColorSequenceKeypoint.new(1,Color3.new(0,0,0))}), texture="rbxassetid://11989899750", lightEmission=1, lightInfluence=0, lifetime={min=0.4,max=0.5}, rate=100, rotSpeed={min=0,max=0}, rotation={min=-360,max=360}, shape=Enum.ParticleEmitterShape.Sphere, shapeInOut=Enum.ParticleEmitterShapeInOut.Outward, shapeStyle=Enum.ParticleEmitterShapeStyle.Surface, size=NumberSequence.new({NumberSequenceKeypoint.new(0,2.9375),NumberSequenceKeypoint.new(1,2)}), speed={min=0.01,max=0.01}, spreadAngleX=0, spreadAngleY=0, zOffset=0 },
        { colorSequence=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(1,0.290196,0.290196)),ColorSequenceKeypoint.new(1,Color3.new(1,0.290196,0.290196))}), texture="rbxassetid://12026515010", brightness=10, drag=10, lifetime={min=1,max=1.75}, rate=50, speed={min=35,max=40}, shape=Enum.ParticleEmitterShape.Box, shapeInOut=Enum.ParticleEmitterShapeInOut.Outward, shapeStyle=Enum.ParticleEmitterShapeStyle.Volume, size=NumberSequence.new({NumberSequenceKeypoint.new(0,6.8125),NumberSequenceKeypoint.new(1,0)}), zOffset=5.1 },
        { colorSequence=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(1,0.290196,0.290196)),ColorSequenceKeypoint.new(1,Color3.new(1,0.290196,0.290196))}), texture="rbxassetid://13712003050", brightness=20, drag=10, lifetime={min=1,max=1.75}, rate=50, speed={min=65,max=85}, shape=Enum.ParticleEmitterShape.Box, shapeInOut=Enum.ParticleEmitterShapeInOut.Outward, shapeStyle=Enum.ParticleEmitterShapeStyle.Volume, size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.4375),NumberSequenceKeypoint.new(1,0)}), zOffset=5.1 },
        { colorSequence=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(1,0.290196,0.290196)),ColorSequenceKeypoint.new(1,Color3.new(1,0.290196,0.290196))}), texture="rbxassetid://14476165199", lifetime={min=0.6,max=0.7}, rate=10, shape=Enum.ParticleEmitterShape.Box, shapeInOut=Enum.ParticleEmitterShapeInOut.Outward, shapeStyle=Enum.ParticleEmitterShapeStyle.Volume, size=NumberSequence.new({NumberSequenceKeypoint.new(0,16.7087),NumberSequenceKeypoint.new(1,16.9178)}), zOffset=5.1 },
        { colorSequence=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(1,0.192157,0.192157)),ColorSequenceKeypoint.new(1,Color3.new(1,0.192157,0.192157))}), texture="rbxassetid://10357918337", brightness=5, lifetime={min=0.2,max=0.3}, rate=50, shape=Enum.ParticleEmitterShape.Box, shapeInOut=Enum.ParticleEmitterShapeInOut.Outward, shapeStyle=Enum.ParticleEmitterShapeStyle.Volume, size=NumberSequence.new({NumberSequenceKeypoint.new(0,8.625),NumberSequenceKeypoint.new(1,0)}), zOffset=-1 },
        { colorSequence=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(1,0.290196,0.290196)),ColorSequenceKeypoint.new(1,Color3.new(1,0.290196,0.290196))}), texture="http://www.roblox.com/asset/?id=13348242294", lifetime={min=0.6,max=0.7}, rate=4, shape=Enum.ParticleEmitterShape.Box, shapeInOut=Enum.ParticleEmitterShapeInOut.Outward, shapeStyle=Enum.ParticleEmitterShapeStyle.Volume, size=NumberSequence.new({NumberSequenceKeypoint.new(0,6.3),NumberSequenceKeypoint.new(1,6.3)}), zOffset=5.1 },
    }
    
    -- ============================================================================
    -- SELF AURA — state
    -- ============================================================================
    local SelfAuraState = { Objects = {}, ChildConn = nil, Character = nil }
    local currentAura = "off"
    
    local function clear_self_aura()
        for _, obj in ipairs(SelfAuraState.Objects) do
            if obj and obj.Parent then obj:Destroy() end
        end
        table.clear(SelfAuraState.Objects)
        if SelfAuraState.ChildConn then
            SelfAuraState.ChildConn:Disconnect()
            SelfAuraState.ChildConn = nil
        end
        SelfAuraState.Character = nil
    end
    
    local function track_self_aura_object(obj)
        if obj then SelfAuraState.Objects[#SelfAuraState.Objects + 1] = obj end
    end
    
    -- ============================================================================
    -- SELF AURA — emitter factories (exact from source)
    -- ============================================================================
    local function create_glitch_emitter(color)
        local emitter = Instance.new("ParticleEmitter")
        emitter.Name = "SelfAura_Glitch"
        emitter.Texture = SELF_AURA_TEXTURE
        emitter.Color = ColorSequence.new(color)
        emitter.LightEmission = 0
        emitter.LightInfluence = 0
        emitter.Rate = 2000000
        emitter.Lifetime = NumberRange.new(0.1, 1.2)
        emitter.Speed = NumberRange.new(0, 0.15)
        emitter.Rotation = NumberRange.new(0, 360)
        emitter.RotSpeed = NumberRange.new(-90, 90)
        emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0) })
        emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
        emitter.SpreadAngle = Vector2.new(180, 180)
        emitter.LockedToPart = true
        return emitter
    end
    
    local function create_karma_emitter(color, texture)
        local emitter = Instance.new("ParticleEmitter")
        emitter.Name = "SelfAura_Karma"
        emitter.Texture = texture or "rbxassetid://1084987899"
        emitter.Color = ColorSequence.new(color)
        emitter.LightEmission = 0.75
        emitter.LightInfluence = 1
        emitter.Rate = 240
        emitter.Lifetime = NumberRange.new(0.5, 1.2)
        emitter.Speed = NumberRange.new(0.8, 1.6)
        emitter.Rotation = NumberRange.new(0, 360)
        emitter.RotSpeed = NumberRange.new(-90, 90)
        emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(0.4, 1.5), NumberSequenceKeypoint.new(1, 0) })
        emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.12), NumberSequenceKeypoint.new(1, 1) })
        emitter.SpreadAngle = Vector2.new(180, 180)
        emitter.EmissionDirection = Enum.NormalId.Top
        emitter.LockedToPart = true
        return emitter
    end
    
    local function create_infinity_emitter(textureId, rate, lifetime, faceCamera)
        local emitter = Instance.new("ParticleEmitter")
        emitter.Name = "SelfAura_Infinity"
        emitter.Texture = textureId
        emitter.Color = ColorSequence.new(INFINITY_COLOR)
        emitter.Rate = rate
        emitter.Lifetime = NumberRange.new(lifetime)
        emitter.Speed = NumberRange.new(0, 0.2)
        emitter.Rotation = NumberRange.new(0, 360)
        emitter.RotSpeed = NumberRange.new(-60, 60)
        emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) })
        emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
        emitter.SpreadAngle = Vector2.new(180, 180)
        emitter.LockedToPart = true
        if faceCamera then emitter.Orientation = Enum.ParticleOrientation.FacingCamera end
        return emitter
    end
    
    local function create_halo_emitter(particleConfig)
        local emitter = Instance.new("ParticleEmitter")
        emitter.Name = "SelfAura_HaloParticle"
        emitter.Texture = particleConfig.texture
        emitter.Color = ColorSequence.new(particleConfig.color)
        emitter.LightEmission = particleConfig.lightEmission
        emitter.LightInfluence = particleConfig.lightInfluence
        emitter.Rate = particleConfig.rate
        emitter.Lifetime = NumberRange.new(particleConfig.lifetime.min, particleConfig.lifetime.max)
        emitter.Speed = NumberRange.new(particleConfig.speed)
        emitter.Rotation = NumberRange.new(particleConfig.rotation)
        emitter.RotSpeed = NumberRange.new(particleConfig.rotSpeed)
        emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, particleConfig.size), NumberSequenceKeypoint.new(1, 0) })
        emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
        emitter.SpreadAngle = Vector2.new(particleConfig.spreadAngleX, particleConfig.spreadAngleY)
        emitter.Orientation = Enum.ParticleOrientation.FacingCamera
        emitter.EmissionDirection = Enum.NormalId.Top
        emitter.LockedToPart = true
        return emitter
    end
    
    local function create_mui_emitter(particleConfig)
        local emitter = Instance.new("ParticleEmitter")
        emitter.Name = "SelfAura_MuiParticle"
        emitter.Texture = particleConfig.texture
        if particleConfig.colorSequence then
            emitter.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, particleConfig.colorA), ColorSequenceKeypoint.new(1, particleConfig.colorB) })
        else
            emitter.Color = ColorSequence.new(particleConfig.color)
        end
        emitter.LightEmission = particleConfig.lightEmission
        emitter.LightInfluence = particleConfig.lightInfluence
        emitter.Rate = particleConfig.rate
        emitter.Lifetime = NumberRange.new(particleConfig.lifetime.min, particleConfig.lifetime.max)
        emitter.Speed = NumberRange.new(particleConfig.speed)
        emitter.Rotation = NumberRange.new(particleConfig.rotation, particleConfig.rotationMax)
        emitter.RotSpeed = NumberRange.new(particleConfig.rotSpeed, particleConfig.rotSpeedMax)
        emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, particleConfig.size), NumberSequenceKeypoint.new(1, 0) })
        emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
        emitter.SpreadAngle = Vector2.new(particleConfig.spreadAngleX, particleConfig.spreadAngleY)
        emitter.Orientation = Enum.ParticleOrientation.FacingCamera
        emitter.EmissionDirection = Enum.NormalId.Top
        emitter.LockedToPart = true
        return emitter
    end
    
    local function create_crimson_moon_emitter(particleConfig)
        local emitter = Instance.new("ParticleEmitter")
        emitter.Name = "SelfAura_CrimsonMoon"
        emitter.Texture = particleConfig.texture
        if particleConfig.colorSequence then
            if typeof(particleConfig.colorSequence) == "ColorSequence" then
                emitter.Color = particleConfig.colorSequence
            elseif type(particleConfig.colorSequence) == "table" then
                emitter.Color = ColorSequence.new(particleConfig.colorSequence)
            else
                emitter.Color = ColorSequence.new(Color3.new(1,1,1))
            end
        elseif particleConfig.color then
            emitter.Color = ColorSequence.new(particleConfig.color)
        else
            emitter.Color = ColorSequence.new(Color3.new(1,1,1))
        end
        emitter.Brightness = particleConfig.brightness or 1
        emitter.Drag = particleConfig.drag or 0
        emitter.EmissionDirection = particleConfig.emissionDirection or Enum.NormalId.Top
        emitter.Enabled = true
        emitter.FlipbookMode = particleConfig.flipbookMode or Enum.ParticleFlipbookMode.Loop
        emitter.FlipbookLayout = particleConfig.flipbookLayout or Enum.ParticleFlipbookLayout.None
        emitter.FlipbookFramerate = particleConfig.flipbookFramerate or NumberRange.new(1,1)
        emitter.FlipbookStartRandom = particleConfig.flipbookStartRandom or false
        emitter.Lifetime = NumberRange.new(particleConfig.lifetime.min, particleConfig.lifetime.max)
        emitter.LightEmission = particleConfig.lightEmission or 0
        emitter.LightInfluence = particleConfig.lightInfluence or 1
        emitter.LockedToPart = particleConfig.lockedToPart or false
        emitter.Orientation = particleConfig.orientation or Enum.ParticleOrientation.FacingCamera
        emitter.Rate = particleConfig.rate
        local rspeed = particleConfig.rotSpeed or {min=0,max=0}
        emitter.RotSpeed = NumberRange.new(rspeed.min or 0, rspeed.max or 0)
        local rot = particleConfig.rotation or {min=0,max=0}
        emitter.Rotation = NumberRange.new(rot.min or 0, rot.max or 0)
        if particleConfig.shape then emitter.Shape = particleConfig.shape end
        if particleConfig.shapeInOut then emitter.ShapeInOut = particleConfig.shapeInOut end
        if particleConfig.shapeStyle then emitter.ShapeStyle = particleConfig.shapeStyle end
        emitter.Size = particleConfig.size or NumberSequence.new(1)
        local spd = particleConfig.speed or {min=0,max=0}
        emitter.Speed = NumberRange.new(spd.min or 0, spd.max or 0)
        emitter.SpreadAngle = Vector2.new(particleConfig.spreadAngleX or 0, particleConfig.spreadAngleY or 0)
        if particleConfig.squash then pcall(function() emitter.Squash = particleConfig.squash end) end
        emitter.TimeScale = particleConfig.timeScale or 1
        emitter.Transparency = particleConfig.transparency or NumberSequence.new({ NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(1,1) })
        emitter.VelocityInheritance = particleConfig.velocityInheritance or 0
        emitter.ZOffset = particleConfig.zOffset or 0
        return emitter
    end
    
    -- ============================================================================
    -- SELF AURA — per-aura apply functions (exact from source)
    -- ============================================================================
    local function apply_infinity_torso_effects(part)
        if not part or not part:IsA("BasePart") then return end
        local name = part.Name
        if name ~= "UpperTorso" and name ~= "Torso" then return end
        for _, tex in ipairs(INFINITY_TORSO_CAM_TEXTURES) do
            local emitter = create_infinity_emitter(tex, 1, 0.5, true)
            emitter.Parent = part
            track_self_aura_object(emitter)
        end
        local extra = create_infinity_emitter(INFINITY_TORSO_EXTRA_TEXTURE, 5, 3, false)
        extra.Parent = part
        track_self_aura_object(extra)
    end
    
    local function apply_sussano(character)
        local root = character and (character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso"))
        if not root or not root:IsA("BasePart") then return end
        local meshPart = Instance.new("Part")
        meshPart.Name = "SelfAura_Sussano"
        meshPart.Size = SUSSANO_SIZE
        meshPart.Color = SUSSANO_COLOR
        meshPart.Material = Enum.Material.Neon
        meshPart.Transparency = 0.25
        meshPart.Reflectance = 0.1
        meshPart.CanCollide = false
        meshPart.Massless = true
        meshPart.CastShadow = false
        meshPart.Anchored = false
        meshPart.CFrame = root.CFrame * CFrame.Angles(0, math.rad(180), 0)
        local sm = Instance.new("SpecialMesh")
        sm.MeshType = Enum.MeshType.FileMesh
        sm.MeshId = SUSSANO_MESH_ID
        sm.Scale = Vector3.new(1, 1, 1)
        sm.Parent = meshPart
        track_self_aura_object(sm)
        meshPart.Parent = character
        track_self_aura_object(meshPart)
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = root; weld.Part1 = meshPart; weld.Parent = meshPart
        track_self_aura_object(weld)
    end
    
    local function apply_fused_zamasu(character)
        local head = character and character:FindFirstChild("Head")
        if not head or not head:IsA("BasePart") then return end
        local meshPart = Instance.new("Part")
        meshPart.Name = "SelfAura_FusedZamasu"
        meshPart.Size = FUSED_ZAMASU_SIZE
        meshPart.Color = FUSED_ZAMASU_COLOR
        meshPart.Material = Enum.Material.Neon
        meshPart.Transparency = 0
        meshPart.CanCollide = false
        meshPart.Massless = true
        meshPart.CastShadow = false
        meshPart.Anchored = false
        meshPart.CFrame = head.CFrame * CFrame.new(0, 2.5, 3) * CFrame.fromEulerAnglesXYZ(-3.608, -0.005 + math.pi, 0.002)
        local sm = Instance.new("SpecialMesh")
        sm.MeshType = Enum.MeshType.FileMesh
        sm.MeshId = FUSED_ZAMASU_MESH_ID
        sm.Scale = Vector3.new(1, 1, 1)
        sm.Parent = meshPart
        track_self_aura_object(sm)
        meshPart.Parent = character
        track_self_aura_object(meshPart)
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = head; weld.Part1 = meshPart; weld.Parent = meshPart
        track_self_aura_object(weld)
        for _, desc in ipairs(character:GetDescendants()) do
            if desc:IsA("BasePart") and not (desc.Parent and desc.Parent:IsA("Accessory")) and not desc.Name:find("SelfAura") then
                for _, particleConfig in ipairs(HALO_PARTICLES) do
                    local emitter = create_halo_emitter(particleConfig)
                    emitter.Parent = desc
                    track_self_aura_object(emitter)
                end
            end
        end
    end
    
    local function apply_six_paths(character)
        local torso = character and (character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso"))
        if not torso or not torso:IsA("BasePart") then return end
        local meshPart = Instance.new("Part")
        meshPart.Name = "SelfAura_SixPaths"
        meshPart.Shape = Enum.PartType.Ball
        meshPart.Size = Vector3.new(1,1,1)
        meshPart.Color = SIX_PATHS_COLOR
        meshPart.Material = Enum.Material.Neon
        meshPart.Transparency = 0
        meshPart.CanCollide = false
        meshPart.Massless = true
        meshPart.CastShadow = false
        meshPart.Anchored = false
        meshPart.CFrame = torso.CFrame * CFrame.new(0,0,2)
        meshPart.Parent = character
        track_self_aura_object(meshPart)
        local mesh = Instance.new("SpecialMesh")
        mesh.MeshType = Enum.MeshType.FileMesh
        mesh.MeshId = SIX_PATHS_MESH_ID
        mesh.TextureId = SIX_PATHS_TEXTURE_ID
        mesh.Scale = SIX_PATHS_SCALE
        mesh.Offset = Vector3.new(0,0,0)
        mesh.VertexColor = Vector3.new(1,1,1)
        mesh.Parent = meshPart
        track_self_aura_object(mesh)
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = torso; weld.Part1 = meshPart; weld.Parent = meshPart
        track_self_aura_object(weld)
    end
    
    local function apply_angel(character)
        local torso = character and (character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso"))
        if not torso or not torso:IsA("BasePart") then return end
        -- wings
        local wingsPart = Instance.new("Part")
        wingsPart.Name = "SelfAura_AngelWings"
        wingsPart.Shape = Enum.PartType.Ball
        wingsPart.Size = Vector3.new(0.5,0.5,0.5)
        wingsPart.Color = ANGEL_WINGS_COLOR
        wingsPart.Material = Enum.Material.Neon
        wingsPart.Transparency = 0.2
        wingsPart.Reflectance = 0.5
        wingsPart.CanCollide = false
        wingsPart.Massless = true
        wingsPart.CastShadow = false
        wingsPart.Anchored = false
        wingsPart.CFrame = torso.CFrame
        wingsPart.Parent = character
        track_self_aura_object(wingsPart)
        local wingsMesh = Instance.new("SpecialMesh")
        wingsMesh.MeshType = Enum.MeshType.FileMesh
        wingsMesh.MeshId = ANGEL_WINGS_MESH_ID
        wingsMesh.TextureId = ANGEL_WINGS_TEXTURE_ID
        wingsMesh.Scale = ANGEL_WINGS_SIZE
        wingsMesh.Offset = Vector3.new(0,0,0)
        wingsMesh.VertexColor = Vector3.new(1,1,1)
        wingsMesh.Parent = wingsPart
        track_self_aura_object(wingsMesh)
        local wingsWeld = Instance.new("WeldConstraint")
        wingsWeld.Part0 = torso; wingsWeld.Part1 = wingsPart; wingsWeld.Parent = wingsPart
        track_self_aura_object(wingsWeld)
        -- halo
        local haloPart = Instance.new("Part")
        haloPart.Name = "SelfAura_AngelHalo"
        haloPart.Shape = Enum.PartType.Ball
        haloPart.Size = Vector3.new(1,1,1)
        haloPart.Color = ANGEL_HALO_COLOR
        haloPart.Material = Enum.Material.Neon
        haloPart.Transparency = 0.1
        haloPart.Reflectance = 0.5
        haloPart.CanCollide = false
        haloPart.Massless = true
        haloPart.CastShadow = false
        haloPart.Anchored = false
        haloPart.CFrame = torso.CFrame * CFrame.new(ANGEL_HALO_OFFSET)
        haloPart.Parent = character
        track_self_aura_object(haloPart)
        local haloMesh = Instance.new("SpecialMesh")
        haloMesh.MeshType = Enum.MeshType.FileMesh
        haloMesh.MeshId = ANGEL_HALO_MESH_ID
        haloMesh.TextureId = ANGEL_HALO_TEXTURE_ID
        haloMesh.Scale = ANGEL_HALO_SIZE
        haloMesh.Offset = Vector3.new(0,0,0)
        haloMesh.VertexColor = Vector3.new(1,1,1)
        haloMesh.Parent = haloPart
        track_self_aura_object(haloMesh)
        local haloWeld = Instance.new("WeldConstraint")
        haloWeld.Part0 = torso; haloWeld.Part1 = haloPart; haloWeld.Parent = haloPart
        track_self_aura_object(haloWeld)
    
        -- falling feathers on all body parts
        for _, desc in ipairs(character:GetDescendants()) do
            if desc:IsA("BasePart") and not (desc.Parent and desc.Parent:IsA("Accessory")) then
                local feather = Instance.new("ParticleEmitter")
                feather.Name = "SelfAura_Feathers"
                feather.Texture = "rbxassetid://12170122357"  -- feather texture
                feather.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
                feather.LightEmission = 0.2
                feather.LightInfluence = 1
                feather.Rate = 3
                feather.Lifetime = NumberRange.new(2.5, 4)
                feather.Speed = NumberRange.new(1, 3)
                feather.Rotation = NumberRange.new(0, 360)
                feather.RotSpeed = NumberRange.new(-45, 45)
                feather.Size = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0.2),
                    NumberSequenceKeypoint.new(0.5, 0.35),
                    NumberSequenceKeypoint.new(1, 0),
                })
                feather.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(0.8, 0),
                    NumberSequenceKeypoint.new(1, 1),
                })
                feather.SpreadAngle = Vector2.new(30, 30)
                feather.Acceleration = Vector3.new(0, -3, 0)  -- fall downward
                feather.LockedToPart = false  -- drift away from body
                feather.Orientation = Enum.ParticleOrientation.FacingCamera
                feather.Parent = desc
                track_self_aura_object(feather)
            end
        end
    end
    
    local function apply_darkseed(character)
        local torso = character and (character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso"))
        if not torso or not torso:IsA("BasePart") then return end
        local darkseedModel = Instance.new("Model")
        darkseedModel.Name = "SelfAura_Darkseed"; darkseedModel.Parent = character
        track_self_aura_object(darkseedModel)
        local main = Instance.new("Attachment")
        main.Name = "Darkseed_Main1"; main.Position = Vector3.new(0,-1.5,0)
        main.Axis = Vector3.new(1,0,0); main.SecondaryAxis = Vector3.new(0,1,0)
        main.Visible = false; main.Parent = torso
        track_self_aura_object(main)
        local target = Instance.new("Attachment")
        target.Name = "Darkseed_Main2"; target.Position = Vector3.new(0,2,0)
        target.Axis = Vector3.new(1,0,0); target.SecondaryAxis = Vector3.new(0,1,0)
        target.Visible = false; target.Parent = torso
        track_self_aura_object(target)
        local beam1 = Instance.new("Beam")
        beam1.Name="Darkseed_Beam1"; beam1.Attachment0=main; beam1.Attachment1=target
        beam1.Brightness=1; beam1.FaceCamera=true; beam1.LightEmission=1; beam1.LightInfluence=1
        beam1.Segments=50; beam1.Texture="rbxassetid://1849531275"; beam1.TextureLength=0.1
        beam1.TextureMode=Enum.TextureMode.Stretch; beam1.TextureSpeed=1
        beam1.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.341121,0),NumberSequenceKeypoint.new(1,1)})
        beam1.Width0=12; beam1.Width1=12; beam1.ZOffset=-1; beam1.Parent=darkseedModel
        track_self_aura_object(beam1)
        local wind = Instance.new("Beam")
        wind.Name="Darkseed_Wind"; wind.Attachment0=main; wind.Attachment1=target
        wind.Brightness=0; wind.FaceCamera=true; wind.LightEmission=0; wind.LightInfluence=0
        wind.Segments=50; wind.Texture="rbxassetid://623219622"; wind.TextureLength=0.1
        wind.TextureMode=Enum.TextureMode.Stretch; wind.TextureSpeed=1
        wind.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.495327,0),NumberSequenceKeypoint.new(1,1)})
        wind.Width0=15; wind.Width1=15; wind.ZOffset=0; wind.Parent=darkseedModel
        track_self_aura_object(wind)
        local function makeDarkseedEmitter(name,color,texture,rate,sizeSeq,lifetime,speed,drag,lightEmission,lightInfluence,zOffset)
            local e = Instance.new("ParticleEmitter")
            e.Name=name; e.Color=ColorSequence.new(color); e.Drag=drag or 1
            e.EmissionDirection=Enum.NormalId.Top; e.Enabled=true
            e.Lifetime=NumberRange.new(unpack(lifetime)); e.LightEmission=lightEmission or 0
            e.LightInfluence=lightInfluence or 1; e.LockedToPart=true
            e.Orientation=Enum.ParticleOrientation.FacingCamera; e.Rate=rate
            e.RotSpeed=NumberRange.new(-360,360); e.Rotation=NumberRange.new(0,0)
            e.Shape=Enum.ParticleEmitterShape.Box; e.ShapeInOut=Enum.ParticleEmitterShapeInOut.Outward
            e.ShapeStyle=Enum.ParticleEmitterShapeStyle.Volume; e.Size=sizeSeq
            e.Speed=NumberRange.new(unpack(speed)); e.SpreadAngle=Vector2.new(30,30)
            e.Texture=texture; e.TimeScale=1
            e.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.50,0),NumberSequenceKeypoint.new(1,1)})
            e.VelocityInheritance=0; e.ZOffset=zOffset or -1
            return e
        end
        local p1 = makeDarkseedEmitter("Darkseed_PurpleFlames",{ColorSequenceKeypoint.new(0,Color3.fromRGB(136,136,186)),ColorSequenceKeypoint.new(1,Color3.fromRGB(0,255,139))},"rbxassetid://5407030718",300,NumberSequence.new({NumberSequenceKeypoint.new(0,3.03),NumberSequenceKeypoint.new(0.5,1.3),NumberSequenceKeypoint.new(1,0)}),{1,1},{10,10},1,0,1,-1)
        p1.Parent=main; track_self_aura_object(p1)
        local p2 = makeDarkseedEmitter("Darkseed_BlackFlames",{ColorSequenceKeypoint.new(0,Color3.fromRGB(136,136,186)),ColorSequenceKeypoint.new(1,Color3.fromRGB(0,255,139))},"rbxassetid://7216855238",150,NumberSequence.new({NumberSequenceKeypoint.new(0,2.66),NumberSequenceKeypoint.new(1,0)}),{1,1},{10,10},1,0,0,-0.9)
        p2.Parent=main; track_self_aura_object(p2)
        local p3 = makeDarkseedEmitter("Darkseed_OrangeFlames",{ColorSequenceKeypoint.new(0,Color3.fromRGB(189,189,1)),ColorSequenceKeypoint.new(1,Color3.fromRGB(0,255,139))},"rbxassetid://7216855238",150,NumberSequence.new({NumberSequenceKeypoint.new(0,1.68),NumberSequenceKeypoint.new(1,0)}),{1,1},{10,10},1,1,0,-0.8)
        p3.Parent=main; track_self_aura_object(p3)
        local p4 = makeDarkseedEmitter("Darkseed_GreenExpel",{ColorSequenceKeypoint.new(0,Color3.fromRGB(82,188,1)),ColorSequenceKeypoint.new(1,Color3.fromRGB(0,255,1))},"rbxassetid://243664672",25,NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.5,0.37),NumberSequenceKeypoint.new(1,0)}),{0.5,1},{-11,20},10,1,1,0)
        p4.Parent=main; track_self_aura_object(p4)
    end
    
    local function apply_aquatic_overseer(character)
        local torso = character and (character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso"))
        if not torso or not torso:IsA("BasePart") then return end
        local model = Instance.new("Model")
        model.Name = "SelfAura_AquaticOverseer"; model.Parent = character
        track_self_aura_object(model)
        local function newAttachment(name, cf, axis, secondaryAxis)
            local att = Instance.new("Attachment")
            att.Name=name; att.CFrame=cf; att.Axis=axis; att.SecondaryAxis=secondaryAxis
            att.Visible=false; att.Parent=torso
            track_self_aura_object(att)
            return att
        end
        local att1 = newAttachment("Aquatic_Attachment1",CFrame.new(0.0152049065,0.23413229,0),Vector3.new(0.6427876353,-0.7660444379,0),Vector3.new(0.7660444379,0.6427876353,0))
        local att2 = newAttachment("Aquatic_Attachment2",CFrame.new(0.0152053833,0.23413229,0),Vector3.new(0.7660444379,0.6427876353,0),Vector3.new(-0.6427876353,0.7660444379,0))
        local att3 = newAttachment("Aquatic_Attachment3",CFrame.new(0,0.177586555,-0.870529175,1,0,0,0,0,1,0,-1,0),Vector3.new(1,0,0),Vector3.new(0,0,-1))
        local function newSwirl(name, attachment, size)
            local e = Instance.new("ParticleEmitter")
            e.Name=name; e.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(0,0.333333,1)),ColorSequenceKeypoint.new(1,Color3.new(0,1,0.333333))})
            e.EmissionDirection=Enum.NormalId.Top; e.Enabled=true; e.Lifetime=NumberRange.new(1,1)
            e.LightEmission=0.5; e.LightInfluence=1; e.LockedToPart=false
            e.Orientation=Enum.ParticleOrientation.VelocityPerpendicular; e.Rate=25
            e.RotSpeed=NumberRange.new(250,250); e.Rotation=NumberRange.new(180,180)
            e.Shape=Enum.ParticleEmitterShape.Box; e.ShapeInOut=Enum.ParticleEmitterShapeInOut.Outward
            e.ShapeStyle=Enum.ParticleEmitterShapeStyle.Volume; e.Size=size
            e.Speed=NumberRange.new(0.001,0.001); e.SpreadAngle=Vector2.new(0,0)
            e.Texture="rbxassetid://7216847765"; e.TimeScale=1
            e.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)})
            e.VelocityInheritance=0; e.ZOffset=0; e.Parent=attachment
            track_self_aura_object(e)
        end
        newSwirl("Aquatic_Swirl1",att1,NumberSequence.new({NumberSequenceKeypoint.new(0,2),NumberSequenceKeypoint.new(1,0)}))
        newSwirl("Aquatic_Swirl2",att2,NumberSequence.new({NumberSequenceKeypoint.new(0,2),NumberSequenceKeypoint.new(1,0)}))
        local aura1 = Instance.new("Part")
        aura1.Name="SelfAura_Aura1"; aura1.Anchored=false; aura1.CanCollide=false
        aura1.Transparency=1; aura1.Size=Vector3.new(4,5,3)
        aura1.CFrame=torso.CFrame*CFrame.new(0,-0.5,0); aura1.Parent=character
        track_self_aura_object(aura1)
        local weld = Instance.new("WeldConstraint")
        weld.Part0=torso; weld.Part1=aura1; weld.Parent=aura1
        track_self_aura_object(weld)
        local fog = Instance.new("ParticleEmitter")
        fog.Name="SelfAura_SmoothFog1"; fog.Acceleration=Vector3.new(0,0.5,1)
        fog.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(0,0.333333,1)),ColorSequenceKeypoint.new(1,Color3.new(0,1,0.333333))})
        fog.EmissionDirection=Enum.NormalId.Top; fog.Enabled=true; fog.Lifetime=NumberRange.new(5,5)
        fog.LightEmission=1; fog.LightInfluence=0; fog.LockedToPart=true
        fog.Orientation=Enum.ParticleOrientation.FacingCamera; fog.Rate=200
        fog.RotSpeed=NumberRange.new(50,50); fog.Rotation=NumberRange.new(180,180)
        fog.Shape=Enum.ParticleEmitterShape.Box; fog.ShapeInOut=Enum.ParticleEmitterShapeInOut.Outward
        fog.ShapeStyle=Enum.ParticleEmitterShapeStyle.Volume
        fog.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.5),NumberSequenceKeypoint.new(1,0)})
        fog.Speed=NumberRange.new(0.001,0.001); fog.SpreadAngle=Vector2.new(0,0)
        fog.Texture="rbxassetid://258126401"; fog.TimeScale=1
        fog.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)})
        fog.VelocityInheritance=0; fog.ZOffset=0; fog.Parent=aura1
        track_self_aura_object(fog)
    end
    
    local function apply_crimson_moon(character)
        local torso = character and (character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso"))
        if not torso or not torso:IsA("BasePart") then return end
        local model = Instance.new("Model"); model.Name="SelfAura_CrimsonMoon"; model.Parent=character
        track_self_aura_object(model)
        local base = Instance.new("Part")
        base.Name="Torso1"; base.Anchored=false; base.CanCollide=false
        base.CanQuery=false; base.CanTouch=false; base.CastShadow=false
        base.Material=Enum.Material.Plastic; base.Size=Vector3.new(2,2,1)
        base.Transparency=1; base.CFrame=torso.CFrame; base.Parent=model
        track_self_aura_object(base)
        local weld = Instance.new("WeldConstraint"); weld.Part0=torso; weld.Part1=base; weld.Parent=base
        track_self_aura_object(weld)
        local aura = Instance.new("Part")
        aura.Name="Aura1"; aura.Anchored=false; aura.CanCollide=false
        aura.CanQuery=false; aura.CanTouch=false; aura.CastShadow=false
        aura.Material=Enum.Material.ForceField; aura.Size=Vector3.new(10,10,10)
        aura.Transparency=1; aura.CFrame=torso.CFrame; aura.Parent=model
        track_self_aura_object(aura)
        local auraWeld = Instance.new("WeldConstraint"); auraWeld.Part0=torso; auraWeld.Part1=aura; auraWeld.Parent=aura
        track_self_aura_object(auraWeld)
        local attachment = Instance.new("Attachment")
        attachment.Name="AuraAttachment1"; attachment.Parent=aura
        attachment.CFrame=CFrame.new(0,0,0); attachment.Visible=false
        track_self_aura_object(attachment)
        local function newEmitter(parent, props)
            local e = Instance.new("ParticleEmitter")
            for k,v in pairs(props) do pcall(function() e[k]=v end) end
            e.Parent=parent; track_self_aura_object(e); return e
        end
        newEmitter(aura,{Name="InnerSmoke1",Acceleration=Vector3.new(0,0,0),Brightness=1,Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(1,0,0)),ColorSequenceKeypoint.new(0.5,Color3.new(1,0.388235,0.388235)),ColorSequenceKeypoint.new(1,Color3.new(1,1,0))}),Drag=0,EmissionDirection=Enum.NormalId.Top,FlipbookFramerate=NumberRange.new(1,1),FlipbookLayout=Enum.ParticleFlipbookLayout.Grid4x4,FlipbookMode=Enum.ParticleFlipbookMode.OneShot,FlipbookStartRandom=false,Lifetime=NumberRange.new(0.4,0.5),LightEmission=1,LightInfluence=0,LockedToPart=true,Orientation=Enum.ParticleOrientation.VelocityPerpendicular,Rate=100,RotSpeed=NumberRange.new(0,0),Rotation=NumberRange.new(-360,360),Shape=Enum.ParticleEmitterShape.Sphere,ShapeInOut=Enum.ParticleEmitterShapeInOut.Outward,ShapeStyle=Enum.ParticleEmitterShapeStyle.Surface,Size=NumberSequence.new({NumberSequenceKeypoint.new(0,2.9375),NumberSequenceKeypoint.new(1,2)}),Speed=NumberRange.new(0.01,0.01),SpreadAngle=Vector2.new(0,0),Texture="rbxassetid://11989899750",TimeScale=1,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.400106,0.5),NumberSequenceKeypoint.new(0.600951,0.5),NumberSequenceKeypoint.new(1,0)}),VelocityInheritance=0,ZOffset=0})
        newEmitter(attachment,{Name="Smoke1",Acceleration=Vector3.new(0,50,0),Brightness=10,Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(1,0.290196,0.290196)),ColorSequenceKeypoint.new(1,Color3.new(1,0.290196,0.290196))}),Drag=10,EmissionDirection=Enum.NormalId.Top,FlipbookFramerate=NumberRange.new(1,1),FlipbookLayout=Enum.ParticleFlipbookLayout.Grid4x4,FlipbookMode=Enum.ParticleFlipbookMode.OneShot,FlipbookStartRandom=false,Lifetime=NumberRange.new(1,1.75),LightEmission=1,LightInfluence=0,LockedToPart=false,Orientation=Enum.ParticleOrientation.FacingCamera,Rate=50,RotSpeed=NumberRange.new(0,0),Rotation=NumberRange.new(-360,360),Shape=Enum.ParticleEmitterShape.Box,ShapeInOut=Enum.ParticleEmitterShapeInOut.Outward,ShapeStyle=Enum.ParticleEmitterShapeStyle.Volume,Size=NumberSequence.new({NumberSequenceKeypoint.new(0,6.8125),NumberSequenceKeypoint.new(1,0)}),Speed=NumberRange.new(35,40),SpreadAngle=Vector2.new(360,360),Texture="rbxassetid://12026515010",TimeScale=1,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.401163,0.95625),NumberSequenceKeypoint.new(0.599366,0.95),NumberSequenceKeypoint.new(1,0)}),VelocityInheritance=0,ZOffset=5.1})
        newEmitter(attachment,{Name="Power1",Acceleration=Vector3.new(0,0,0),Brightness=5,Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(1,0.192157,0.192157)),ColorSequenceKeypoint.new(1,Color3.new(1,0.192157,0.192157))}),Drag=0,EmissionDirection=Enum.NormalId.Top,FlipbookFramerate=NumberRange.new(1,1),FlipbookLayout=Enum.ParticleFlipbookLayout.None,FlipbookMode=Enum.ParticleFlipbookMode.OneShot,FlipbookStartRandom=false,Lifetime=NumberRange.new(0.2,0.3),LightEmission=1,LightInfluence=0,LockedToPart=true,Orientation=Enum.ParticleOrientation.FacingCamera,Rate=50,RotSpeed=NumberRange.new(0,0),Rotation=NumberRange.new(-360,360),Shape=Enum.ParticleEmitterShape.Box,ShapeInOut=Enum.ParticleEmitterShapeInOut.Outward,ShapeStyle=Enum.ParticleEmitterShapeStyle.Volume,Size=NumberSequence.new({NumberSequenceKeypoint.new(0,8.625),NumberSequenceKeypoint.new(1,0)}),Speed=NumberRange.new(0,0),SpreadAngle=Vector2.new(0,0),Texture="rbxassetid://10357918337",TimeScale=1,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.399577,0.75),NumberSequenceKeypoint.new(0.600423,0.75),NumberSequenceKeypoint.new(1,0)}),VelocityInheritance=0,ZOffset=-1})
    end
    
    local function apply_galactic_center(character)
        local torso = character and (character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso"))
        if not torso or not torso:IsA("BasePart") then return end
        local model = Instance.new("Model"); model.Name="SelfAura_GalacticCenter"; model.Parent=character
        track_self_aura_object(model)
        local spaceParts = Instance.new("Part")
        spaceParts.Name="SpaceParts1"; spaceParts.Anchored=false; spaceParts.CanCollide=false
        spaceParts.CanQuery=false; spaceParts.CanTouch=false; spaceParts.CastShadow=false
        spaceParts.Material=Enum.Material.Plastic; spaceParts.Size=Vector3.new(2,2,1)
        spaceParts.Transparency=1; spaceParts.CFrame=torso.CFrame; spaceParts.Parent=model
        track_self_aura_object(spaceParts)
        local spw = Instance.new("WeldConstraint"); spw.Part0=torso; spw.Part1=spaceParts; spw.Parent=spaceParts
        track_self_aura_object(spw)
        local spaceSmoke = Instance.new("Part")
        spaceSmoke.Name="SpaceSmoke1"; spaceSmoke.Anchored=false; spaceSmoke.CanCollide=false
        spaceSmoke.CanQuery=false; spaceSmoke.CanTouch=false; spaceSmoke.CastShadow=false
        spaceSmoke.Material=Enum.Material.Plastic; spaceSmoke.Size=Vector3.new(6,6,6)
        spaceSmoke.Transparency=1; spaceSmoke.CFrame=torso.CFrame; spaceSmoke.Parent=model
        track_self_aura_object(spaceSmoke)
        local ssw = Instance.new("WeldConstraint"); ssw.Part0=spaceParts; ssw.Part1=spaceSmoke; ssw.Parent=spaceSmoke
        track_self_aura_object(ssw)
        local function newE(props)
            local e = Instance.new("ParticleEmitter")
            for k,v in pairs(props) do if k~="Parent" then pcall(function() e[k]=v end) end end
            e.Parent=props.Parent; track_self_aura_object(e); return e
        end
        newE({Name="SpaceMiniStar1",Acceleration=Vector3.new(0,0,0),Brightness=0.15,Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(1,1,1)),ColorSequenceKeypoint.new(1,Color3.new(1,1,1))}),Drag=5,EmissionDirection=Enum.NormalId.Top,Enabled=true,FlipbookFramerate=NumberRange.new(24,32),FlipbookLayout=Enum.ParticleFlipbookLayout.Grid4x4,FlipbookMode=Enum.ParticleFlipbookMode.Loop,FlipbookStartRandom=true,Lifetime=NumberRange.new(4,6),LightEmission=1,LightInfluence=0,LockedToPart=true,Orientation=Enum.ParticleOrientation.VelocityParallel,Rate=250,RotSpeed=NumberRange.new(-15,15),Rotation=NumberRange.new(0,360),Shape=Enum.ParticleEmitterShape.Sphere,ShapeInOut=Enum.ParticleEmitterShapeInOut.Outward,ShapeStyle=Enum.ParticleEmitterShapeStyle.Volume,Size=NumberSequence.new({NumberSequenceKeypoint.new(0,1.5),NumberSequenceKeypoint.new(1,0.5)}),Speed=NumberRange.new(4,10),SpreadAngle=Vector2.new(360,360),Texture="rbxassetid://12270879938",TimeScale=1,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.1,0.5),NumberSequenceKeypoint.new(0.8,0.75),NumberSequenceKeypoint.new(1,1)}),VelocityInheritance=0,ZOffset=-0.5,Parent=spaceSmoke})
        newE({Name="SpaceSmoke_Cloud1",Acceleration=Vector3.new(0,0,0),Brightness=1,Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(0,0.0980392,0.0588235)),ColorSequenceKeypoint.new(1,Color3.new(0,0.0980392,0.0588235))}),Drag=1.5,EmissionDirection=Enum.NormalId.Top,Enabled=true,FlipbookFramerate=NumberRange.new(1,1),FlipbookLayout=Enum.ParticleFlipbookLayout.None,FlipbookMode=Enum.ParticleFlipbookMode.Loop,FlipbookStartRandom=false,Lifetime=NumberRange.new(4,8),LightEmission=-0.05,LightInfluence=0,LockedToPart=true,Orientation=Enum.ParticleOrientation.FacingCamera,Rate=100,RotSpeed=NumberRange.new(-40,40),Rotation=NumberRange.new(0,360),Shape=Enum.ParticleEmitterShape.Sphere,ShapeInOut=Enum.ParticleEmitterShapeInOut.Outward,ShapeStyle=Enum.ParticleEmitterShapeStyle.Volume,Size=NumberSequence.new({NumberSequenceKeypoint.new(0,3),NumberSequenceKeypoint.new(1,10)}),Speed=NumberRange.new(1,4),SpreadAngle=Vector2.new(360,360),Texture="rbxassetid://12270911652",TimeScale=1,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.300499,0.5),NumberSequenceKeypoint.new(0.7,0.9),NumberSequenceKeypoint.new(1,1)}),VelocityInheritance=0,ZOffset=-2,Parent=spaceSmoke})
        local nebulas = Instance.new("Attachment"); nebulas.Name="Nebulas1"; nebulas.CFrame=CFrame.new(0,0,0); nebulas.Visible=true; nebulas.Parent=spaceParts
        track_self_aura_object(nebulas)
        newE({Name="Nebula1_B",Acceleration=Vector3.new(0,0,0),Brightness=5,Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(1,1,1)),ColorSequenceKeypoint.new(1,Color3.new(1,1,1))}),Drag=0,EmissionDirection=Enum.NormalId.Top,Enabled=true,FlipbookFramerate=NumberRange.new(1,1),FlipbookLayout=Enum.ParticleFlipbookLayout.None,FlipbookMode=Enum.ParticleFlipbookMode.Loop,FlipbookStartRandom=false,Lifetime=NumberRange.new(2,6),LightEmission=0,LightInfluence=0,LockedToPart=true,Orientation=Enum.ParticleOrientation.FacingCamera,Rate=50,RotSpeed=NumberRange.new(60,60),Rotation=NumberRange.new(0,360),Shape=Enum.ParticleEmitterShape.Box,ShapeInOut=Enum.ParticleEmitterShapeInOut.Outward,ShapeStyle=Enum.ParticleEmitterShapeStyle.Volume,Size=NumberSequence.new({NumberSequenceKeypoint.new(0,6),NumberSequenceKeypoint.new(1,5.75)}),Speed=NumberRange.new(0,0),SpreadAngle=Vector2.new(0,0),Texture="rbxassetid://21313202",TimeScale=1,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.2,0.5),NumberSequenceKeypoint.new(1,1)}),VelocityInheritance=0,ZOffset=-0.95,Parent=nebulas})
    end
    
    local function apply_tatas(character)
        local torso = character and (character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso"))
        if not torso or not torso:IsA("BasePart") then return end
    
        -- [offset, nipple offset relative to ball center]
        local setup = {
            { ball = Vector3.new(-0.55, 0.3, -0.4), nip = Vector3.new(-0.55, 0.3, -0.97) },
            { ball = Vector3.new( 0.55, 0.3, -0.4), nip = Vector3.new( 0.55, 0.3, -0.97) },
        }
    
        for _, s in ipairs(setup) do
            -- main ball (peachy)
            local ball = Instance.new("Part")
            ball.Name = "SelfAura_Tata"
            ball.Shape = Enum.PartType.Ball
            ball.Size = Vector3.new(1.1, 1.1, 1.1)
            ball.Color = Color3.fromRGB(255, 200, 160)  -- peachy
            ball.Material = Enum.Material.SmoothPlastic
            ball.Transparency = 0
            ball.Reflectance = 0.05
            ball.CanCollide = false
            ball.Massless = true
            ball.CastShadow = false
            ball.Anchored = false
            ball.CFrame = torso.CFrame * CFrame.new(s.ball)
            ball.Parent = character
            track_self_aura_object(ball)
    
            local ballWeld = Instance.new("WeldConstraint")
            ballWeld.Part0 = torso; ballWeld.Part1 = ball; ballWeld.Parent = ball
            track_self_aura_object(ballWeld)
    
            -- nipple (small pink cylinder facing forward = along -Z of torso)
            local nip = Instance.new("Part")
            nip.Name = "SelfAura_Nip"
            nip.Size = Vector3.new(0.18, 0.18, 0.22)  -- small stub
            nip.Color = Color3.fromRGB(235, 100, 120)  -- pinky
            nip.Material = Enum.Material.SmoothPlastic
            nip.Transparency = 0
            nip.Reflectance = 0.02
            nip.CanCollide = false
            nip.Massless = true
            nip.CastShadow = false
            nip.Anchored = false
            -- positioned at front face of ball, rotated so the cylinder points forward
            nip.CFrame = torso.CFrame * CFrame.new(s.nip) * CFrame.Angles(math.pi/2, 0, 0)
            nip.Parent = character
            track_self_aura_object(nip)
    
            local nipMesh = Instance.new("SpecialMesh")
            nipMesh.MeshType = Enum.MeshType.Cylinder
            nipMesh.Parent = nip
            track_self_aura_object(nipMesh)
    
            local nipWeld = Instance.new("WeldConstraint")
            nipWeld.Part0 = torso; nipWeld.Part1 = nip; nipWeld.Parent = nip
            track_self_aura_object(nipWeld)
        end
    end
    
    -- ── Part-level dispatcher ─────────────────────────────────────────────────────
    local function apply_self_aura_to_part(part, auraType)
        if not part or not part:IsA("BasePart") then return end
        if part.Parent and part.Parent:IsA("Accessory") then return end
        if auraType == "glitch aura" then
            if part.Name == "Head" then return end
            local green = create_glitch_emitter(Color3.fromRGB(0,255,0)); green.Parent=part; track_self_aura_object(green)
            local black = create_glitch_emitter(Color3.fromRGB(0,0,0)); black.Parent=part; track_self_aura_object(black)
        elseif auraType == "karma aura" then
            if part.Name == "Head" then return end
            local auraA = create_karma_emitter(Color3.fromRGB(128,0,255),"rbxassetid://1084987899"); auraA.Rate=80; auraA.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.3),NumberSequenceKeypoint.new(1,0)}); auraA.Parent=part; track_self_aura_object(auraA)
            local auraB = create_karma_emitter(Color3.fromRGB(0,255,255),"rbxassetid://12026515010"); auraB.Rate=50; auraB.Speed=NumberRange.new(1,2); auraB.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.5),NumberSequenceKeypoint.new(1,0)}); auraB.Parent=part; track_self_aura_object(auraB)
        elseif auraType == "mui" then
            for _, particleConfig in ipairs(MUI_PARTICLES) do
                local emitter = create_mui_emitter(particleConfig); emitter.Parent=part; track_self_aura_object(emitter)
            end
            if part.Name == "UpperTorso" or part.Name == "Torso" then
                local glowEmitter = create_mui_emitter(MUI_TORSO_GLOW_PARTICLE); glowEmitter.Parent=part; track_self_aura_object(glowEmitter)
            end
        elseif auraType == "infinity aura" then
            for _, tex in ipairs(INFINITY_TEXTURES) do
                local emitter = create_infinity_emitter(tex,10,0.5,false); emitter.Parent=part; track_self_aura_object(emitter)
            end
            apply_infinity_torso_effects(part)
        end
    end
    
    -- ── Top-level apply ───────────────────────────────────────────────────────────
    local function apply_self_aura(character)
        clear_self_aura()
        if not character or currentAura == "off" then return end
        SelfAuraState.Character = character
        if     currentAura == "sussano"          then apply_sussano(character)
        elseif currentAura == "fused zamasu"     then apply_fused_zamasu(character)
        elseif currentAura == "six paths"        then apply_six_paths(character)
        elseif currentAura == "angel"            then apply_angel(character)
        elseif currentAura == "darkseed"         then apply_darkseed(character)
        elseif currentAura == "aquatic overseer" then apply_aquatic_overseer(character)
        elseif currentAura == "galactic center"  then apply_galactic_center(character)
        elseif currentAura == "crimsonMoon"      then apply_crimson_moon(character)
        elseif currentAura == "tatas"            then apply_tatas(character)
        else
            for _, desc in ipairs(character:GetDescendants()) do
                apply_self_aura_to_part(desc, currentAura)
            end
            SelfAuraState.ChildConn = character.DescendantAdded:Connect(function(desc)
                apply_self_aura_to_part(desc, currentAura)
            end)
        end
    end
    
    local function refresh_self_aura()
        local character = LocalPlayer and LocalPlayer.Character
        if not character then clear_self_aura(); return end
        apply_self_aura(character)
    end
    
    _G.fentiSelfAuraSetChoice = function(v) currentAura = v; refresh_self_aura() end
    _G.fentiSelfAuraUnload = clear_self_aura
    _G.fentiSelfAuraGetChoice = function() return currentAura end
    _G.fentiSelfAuraCharConn = LocalPlayer.CharacterAdded:Connect(function(character) task.wait(0.2); apply_self_aura(character) end)
    if LocalPlayer.Character then task.defer(function() apply_self_aura(LocalPlayer.Character) end) end
    end)()
    end
    
    -- ----------------------------------------------------------------------------
    -- [FENTI-05] 5. CONSTANTS
    -- ----------------------------------------------------------------------------
    local function fentiIdentifyExecutorLower()
        if type(identifyexecutor) ~= "function" then return "unknown" end
        local ok, r = pcall(identifyexecutor)
        if ok and type(r) == "string" and r ~= "" then return string.lower(r) end
        return "unknown"
    end
    
    local assetName = "Unknown Game"
    pcall(function() assetName = Marketplace:GetProductInfo(game.PlaceId).Name end)
    local execLower = fentiIdentifyExecutorLower()
    
    local executorDisplay = "Unknown"
    pcall(function()
        if type(identifyexecutor) ~= "function" then return end
        local ok, name = pcall(identifyexecutor)
        if ok and type(name) == "string" and name ~= "" then executorDisplay = name end
    end)
    local _isXeno = execLower:find("xeno") ~= nil
    -- Velocity (executor): early UUID/LogService/namecall hooks often trip spoofcheck before logs flush; treat like other risky clients.
    local _isVelocityExecutor = string.find(execLower, "velocity", 1, true) ~= nil
    -- (Silent-aim __namecall hook removed — no defer.)
    local _executorNamecallRisk = _isXeno or _isVelocityExecutor or execLower:find("median") or execLower:find("madium")
    -- Spoofcheck-sensitive: skip UUID heartbeat + LogService taps (AC module reads the same via lateInit ctx).
    local _fentiSkipACMonitoring = _executorNamecallRisk
        or (_G.fentiExecutorWasPotassium == true)
        or (string.find(execLower, "potassium", 1, true) ~= nil)
    pcall(function()
        if _G.Potassium or _G.Pot or _G.KPot then _fentiSkipACMonitoring = true end
    end)
    local Support = {
        Clipboard = (typeof(setclipboard) == "function"),
        Connections = (typeof(getconnections) == "function"),
        Proximity = (typeof(fireproximityprompt) == "function"),
    }
    -- Caps how far we stretch prompts; 9999-style values often trip anti-cheat.
    local FENTI_PROMPT_MAX_STRETCH = 48
    -- Bump when you publish; optional _G.FENTI_VERSION_CHECK_URL compares remote return value to this (or _G.FENTI_EXPECTED_VERSION).
    local FENTI_SCRIPT_VERSION = 5
    local BEST_FISHING_SPOT = CFrame.new(-4883, 44.999, -2118)
    local SAFE_ZONE_POS = CFrame.new(0, 50, 0)
    -- User-defined fishing TP presets (name + CFrame). "Default (hub)" = BEST_FISHING_SPOT.
    local fentiCustomFishSpotEntries = {}
    local fentiSelectedFishSpotName = "Default (hub)"
    local function fentiFishSpotDropdownValues()
        local v = { "Default (hub)" }
        for _, e in ipairs(fentiCustomFishSpotEntries) do
            table.insert(v, e.name)
        end
        return v
    end
    local function fentiGetFishSpotCFrame()
        if fentiSelectedFishSpotName == "Default (hub)" or fentiSelectedFishSpotName == "" then
            return BEST_FISHING_SPOT
        end
        for _, e in ipairs(fentiCustomFishSpotEntries) do
            if e.name == fentiSelectedFishSpotName then
                return e.cf
            end
        end
        return BEST_FISHING_SPOT
    end
    _G.fentiGetFishSpotCFrame = fentiGetFishSpotCFrame
    
    -- ----------------------------------------------------------------------------
    -- [FENTI-06] 6. ALL STATE VARIABLES
    -- ----------------------------------------------------------------------------
    -- Fishing / economy
    local Script_Start_Time = os.time()
    local isRunning, fishCaught, chestsOpened = false, 0, 0
    local useBait, autoBuyBait, autoSellFish, autoBuyRod = true, false, false, false
    local autoFishLootChests = false
    if rawget(_G, "FENTI_FISH_DEBUG") == nil then _G.FENTI_FISH_DEBUG = false end
    -- Chest / TP loop
    local chestFarmEnabled, originalPosition, rootMotionLockConn, tpLoopConnection = false, nil, nil, nil
    local openedChests, totalChestsAtStart = {}, 0
    -- Walk-up chests: background loop fires prompts when true (see proximity IIFE). Teleport tab can toggle off.
    if rawget(_G, "AutoCollect") == nil then _G.AutoCollect = true end
    _G.fentiFishingStanceMode = "spring"
    
    -- Fishing pose/rig helpers live in nested scope (saves main-chunk local register slots; Luau limit ~200).
    ;(function()
        local function destroyRig()
            local r = rawget(_G, "fentiFishingRig")
            if not r then return end
            pcall(function()
                if r.alignPos and r.alignPos.Parent then r.alignPos:Destroy() end
                if r.alignOr and r.alignOr.Parent then r.alignOr:Destroy() end
                if r.hrpAtt and r.hrpAtt.Name == "FentiHRPAtt" and r.hrpAtt.Parent then r.hrpAtt:Destroy() end
                if r.folder and r.folder.Parent then r.folder:Destroy() end
            end)
            _G.fentiFishingRig = nil
        end
        local function setSpringOn(on)
            local r = rawget(_G, "fentiFishingRig")
            if not r then return end
            pcall(function()
                if r.alignPos then r.alignPos.Enabled = on end
                if r.alignOr then r.alignOr.Enabled = on end
            end)
        end
        local function ensureSpringRig(holdCF)
            local r = rawget(_G, "fentiFishingRig")
            if r and r.anchorPart and r.anchorPart.Parent and r.worldAtt and r.worldAtt.Parent then
                pcall(function() r.anchorPart.CFrame = holdCF end)
                return r
            end
            destroyRig()
            local folder = Instance.new("Folder")
            folder.Name = "FentiFishingHold"
            folder.Parent = workspace
            local ap = Instance.new("Part")
            ap.Name = "FentiAnchorTarget"
            ap.Anchored = true
            ap.CanCollide = false
            ap.CanQuery = false
            ap.CanTouch = false
            ap.Transparency = 1
            ap.Size = Vector3.new(0.2, 0.2, 0.2)
            ap.CFrame = holdCF
            ap.Parent = folder
            local worldAtt = Instance.new("Attachment")
            worldAtt.Name = "FentiWorldAtt"
            worldAtt.Parent = ap
            r = { folder = folder, anchorPart = ap, worldAtt = worldAtt, alignPos = nil, alignOr = nil, hrpAtt = nil }
            _G.fentiFishingRig = r
            return r
        end
        local function attachSpring(root, rig)
            if rig.alignPos and rig.alignPos.Parent then return end
            local attH = root:FindFirstChild("RootAttachment")
            if not attH then attH = root:FindFirstChildOfClass("Attachment") end
            if not attH then
                attH = Instance.new("Attachment")
                attH.Name = "FentiHRPAtt"
                attH.Parent = root
            end
            rig.hrpAtt = attH
            pcall(function()
                local apc = Instance.new("AlignPosition")
                apc.Name = "FentiAlignPosition"
                apc.Attachment0 = attH
                apc.Attachment1 = rig.worldAtt
                apc.RigidityEnabled = false
                apc.Responsiveness = 22
                apc.Parent = root
                pcall(function() apc.ApplyAtCenterOfMass = false end)
                pcall(function() apc.MaxForce = 80000 end)
                rig.alignPos = apc
            end)
            pcall(function()
                local aoc = Instance.new("AlignOrientation")
                aoc.Name = "FentiAlignOrientation"
                aoc.Attachment0 = attH
                aoc.Attachment1 = rig.worldAtt
                aoc.RigidityEnabled = false
                aoc.Responsiveness = 18
                aoc.Parent = root
                pcall(function() aoc.MaxTorque = 200000 end)
                rig.alignOr = aoc
            end)
        end
        local function stopPoseHold()
            _G.fentiFishingHoldCF = nil
            _G.fentiCastingUnanchor = nil
            destroyRig()
            local c = rawget(_G, "fentiFishingPoseHoldConn")
            if c then
                pcall(function() c:Disconnect() end)
                _G.fentiFishingPoseHoldConn = nil
            end
            pcall(function()
                local ch = player.Character
                local rr = ch and ch:FindFirstChild("HumanoidRootPart")
                if rr then rr.Anchored = false end
            end)
        end
        _G.__fentiFishPose = {
            destroyRig = destroyRig,
            setSpringOn = setSpringOn,
            ensureSpringRig = ensureSpringRig,
            attachSpring = attachSpring,
            stopPoseHold = stopPoseHold,
        }
        _G.fentiStopFishingPoseHold = stopPoseHold
    end)()
    -- Visual / combat toggles
    local espEnabled, corpseFarmEnabled = false, false
    local noStunEnabled, triggerbotEnabled, noScreenShake = false, false, false
    local screenShakeHooked, screenShakeConnections = false, {}
    -- Saints filter (used by radius tick + sniper)
    local saintsEnabled, saintsPartFilter = false, {
        SaintsHeart = true,
        SaintsLeftArm = true,
        SaintsLeftLeg = true,
        SaintsRibcage = true,
        SaintsRightArm = true,
        SaintsRightLeg = false,
    }
    -- Slower saints pickup (fewer AC triggers); default on — disable in Corpse tab for max speed at higher risk.
    local saintsPickupStealth = true
    -- Optional safe hop before claim (movement TP); off by default.
    local saintsResetBeforeClaim = false
    -- Full auto: fast spam, instant-prompt on, skip pre-reset; success → safe hop; fail → fish→safe + retry wave.
    local saintsAllInOne = false
    local saintsEspEnabled = false
    -- After saints sniper / auto-claim: soft TP to safe zone; retry if hop fails.
    local saintsSafeAfterClaim = true
    local saintsSafeAfterClaimMaxAttempts = 5
    local saintsClaimPromptRounds = 3
    local saintsClaimLock = setmetatable({}, { __mode = "k" })
    local function fentiSaintsPartEligible(partName)
        if type(partName) ~= "string" or not string.find(string.lower(partName), "saints", 1, true) then return false end
        local anySelected = false
        for _, v in pairs(saintsPartFilter) do if v then anySelected = true; break end end
        if not anySelected then return true end
        return saintsPartFilter[partName] == true
    end
    local isOnHorse = false
    local webhookURL, webhookEnabled, lastCaughtFish = "", false, "Unknown"
    -- Webhook: post only for checked tiers (legendary / epic / rare / common in the same notification string).
    local webhookRarityNotify = { Legendary = true, Epic = true, Rare = true, Common = true }
    -- Real catch count: only bump on server/client catch notifications (not bite/reel heuristics).
    local lastFentiCatchNotifAt = 0
    local lastFentiChestPromptSpam = 0
    local autoDialogueEnabled, dialogueConnection, rerollCount = false, nil, 0
    local corpseListenerActive, corpseListenerConn = false, nil
    local activeConnections, qteInProgress = {}, false
    local killstreakTrackerEnabled, antiRagdollEnabled = false, false
    local fentiKillstreakConns, fentiAntiRagdollConns = {}, {}
    local QTE_TARGETS = {["Easy"] = 10, ["Mid"] = 20, ["Hard"] = 30}
    local VIM; pcall(function() VIM = game:GetService("VirtualInputManager") end)
    local Labels = {}
    local sendFishWebhook, serverHop, removeEntityESP, removePlayerESP
    local ESPState = { PlayerCache = {}, EntityCache = {}, renderConn = nil, updateConn = nil, espSession = 0, worldConns = {}, screenGui = nil }
    -- ----------------------------------------------------------------------------
    -- [FENTI-07] 7. CORE UTILITIES
    -- ----------------------------------------------------------------------------
    local function GetSessionTime()
        local seconds = os.time() - Script_Start_Time
        return string.format("%dh %02dm", math.floor(seconds / 3600), math.floor((seconds % 3600) / 60))
    end
    
    -- Never yield on CharacterAdded:Wait() here — that hard-freezes the client if anything goes wrong.
    local function refreshCharacter()
        local char = player.Character
        character = char
        if not char then
            humanoidRootPart = nil
            return
        end
        humanoidRootPart = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 3)
        if not humanoidRootPart then humanoidRootPart = char:FindFirstChild("HumanoidRootPart") end
    end
    
    player.CharacterAdded:Connect(function(char)
        character = char
        humanoidRootPart = char:WaitForChild("HumanoidRootPart", 12) or char:FindFirstChild("HumanoidRootPart")
    end)
    
    player.CharacterRemoving:Connect(function()
        pcall(function()
            if GunActionRemote then GunActionRemote:FireServer("StopAutoFire") end
        end)
    end)
    
    pcall(function()
        for _, sp in pairs(workspace:GetDescendants()) do
            if sp:IsA("SpawnLocation") then SAFE_ZONE_POS = sp.CFrame + Vector3.new(0, 5, 0); break end
        end
    end)
    
    local function antiAFKLoop()
        pcall(function()
            if Support.Connections then
                for _, conn in pairs(getconnections(player.Idled)) do
                    if conn.Disable then conn:Disable() elseif conn.Disconnect then conn:Disconnect() end
                end
            end
        end)
        while task.wait(60) do
            if Toggles.AntiAFK and Toggles.AntiAFK.Value then
                pcall(function()
                    VirtualUser:CaptureController()
                    VirtualUser:Button2Down(Vector2.new(0,0), camera.CFrame)
                    task.wait(0.2)
                    VirtualUser:Button2Up(Vector2.new(0,0), camera.CFrame)
                end)
            end
        end
    end
    
    local function fentiStopKillstreakTracker()
        for _, c in ipairs(fentiKillstreakConns) do pcall(function() c:Disconnect() end) end
        table.clear(fentiKillstreakConns)
    end
    local function fentiPickStreakStat(lstats)
        if not lstats then return nil end
        local okTypes = { IntValue = true, NumberValue = true, DoubleConstrainedValue = true, StringValue = true }
        for _, n in ipairs({
            "STREAK", "Streak", "KillStreak", "Killstreak", "killstreak",
            "PlayerKillStreak", "Kill_Streak", "Kills", "Streaks",
        }) do
            local ch = lstats:FindFirstChild(n)
            if ch and okTypes[ch.ClassName] then return ch end
        end
        return nil
    end
    local function fentiStartKillstreakTracker()
        fentiStopKillstreakTracker()
        if not killstreakTrackerEnabled then return end
        task.spawn(function()
            local lstats = player:WaitForChild("leaderstats", 40)
            if not lstats or not killstreakTrackerEnabled then return end
            local function refreshLabel()
                local st = fentiPickStreakStat(lstats)
                if Labels.KillStreak then
                    if st then Labels.KillStreak:SetText("<b>Kill streak:</b> " .. tostring(st.Value))
                    else Labels.KillStreak:SetText("<b>Kill streak:</b> — (no STREAK stat)") end
                end
            end
            refreshLabel()
            local st = fentiPickStreakStat(lstats)
            if st then table.insert(fentiKillstreakConns, st.Changed:Connect(refreshLabel)) end
            table.insert(fentiKillstreakConns, lstats.ChildAdded:Connect(function()
                task.defer(function()
                    if not killstreakTrackerEnabled then return end
                    fentiStopKillstreakTracker()
                    fentiStartKillstreakTracker()
                end)
            end))
        end)
    end
    local function fentiStopAntiRagdoll()
        for _, c in ipairs(fentiAntiRagdollConns) do pcall(function() c:Disconnect() end) end
        table.clear(fentiAntiRagdollConns)
    end
    local function fentiSetupAntiRagdollHumanoid(char, hum)
        if not antiRagdollEnabled or not char or not hum then return end
        pcall(function()
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
        end)
        local ac = char:GetAttributeChangedSignal("IsRagdolled"):Connect(function()
            if not antiRagdollEnabled then return end
            pcall(function()
                if char:GetAttribute("IsRagdolled") and hum.Health > 0 then
                    task.spawn(function()
                        while antiRagdollEnabled and char.Parent and hum.Parent and hum.Health > 0 and char:GetAttribute("IsRagdolled") do
                            hum.PlatformStand = true
                            pcall(function() hum:ChangeState(Enum.HumanoidStateType.Physics) end)
                            RunService.Stepped:Wait()
                        end
                        if hum.Parent and hum.Health > 0 then
                            hum.PlatformStand = false
                            pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
                        end
                    end)
                elseif hum.Health > 0 then
                    hum.PlatformStand = false
                    pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
                end
            end)
        end)
        table.insert(fentiAntiRagdollConns, ac)
    end
    local function fentiStartAntiRagdoll()
        fentiStopAntiRagdoll()
        if not antiRagdollEnabled then return end
        local function onChar(ch)
            task.defer(function()
                local hum = ch:WaitForChild("Humanoid", 10)
                if hum and antiRagdollEnabled then fentiSetupAntiRagdollHumanoid(ch, hum) end
            end)
        end
        if player.Character then onChar(player.Character) end
        table.insert(fentiAntiRagdollConns, player.CharacterAdded:Connect(onChar))
    end
    
    local function noStunLoop()
        while noStunEnabled do
            pcall(function()
                local char = player.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then
                        hum.PlatformStand = false
                        -- Do NOT keep FallingDown/Ragdoll disabled forever — many gun scripts tie reload/fire to humanoid state and get stuck after hits.
                        if hum:GetState() == Enum.HumanoidStateType.FallingDown or hum:GetState() == Enum.HumanoidStateType.Ragdoll or hum:GetState() == Enum.HumanoidStateType.PlatformStanding then
                            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                        end
                    end
                    local root = char:FindFirstChild("HumanoidRootPart")
                    if root then
                        for _, child in pairs(root:GetChildren()) do
                            if child:IsA("BodyVelocity") and child.MaxForce == Vector3.new(40000, 40000, 40000) then child:Destroy() end
                        end
                    end
                end
            end)
            task.wait(0.2)
        end
    end
    
    -- ----------------------------------------------------------------------------
    -- [FENTI-08] 8. ANTI-DETECTION + BAN LOGGING
    -- ----------------------------------------------------------------------------
    local _banLog = {}
    local _banLog_counts = {}
    local FAIL_LOG_DIR = "fail logs"
    local FAIL_LOG_PATH = FAIL_LOG_DIR .. "/fenti_" .. os.date("%Y%m%d_%H%M%S") .. "_" .. tostring(math.random(10000, 99999)) .. ".txt"
    local function failLogWrite(line)
        local s = tostring(line or "")
        if string.find(s, "[BYPASS]", 1, true) or string.find(s, "[AC-", 1, true) or string.find(s, "[DESTROY-", 1, true) then
            s = "[Bypass] success"
        end
        pcall(function()
            if makefolder then makefolder(FAIL_LOG_DIR) end
            if not writefile then return end
            local prev = ""
            if isfile and readfile and isfile(FAIL_LOG_PATH) then prev = readfile(FAIL_LOG_PATH) end
            writefile(FAIL_LOG_PATH, prev .. s:sub(1, 4000) .. "\n")
        end)
    end
    local function failLogSnapshot(tag, extra)
        local lines = {
            "======== " .. tostring(tag) .. " @ " .. os.date("%Y-%m-%d %H:%M:%S") .. " ========",
            "PlaceId=" .. tostring(game.PlaceId) .. " JobId=" .. tostring(game.JobId),
        }
        pcall(function()
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                table.insert(lines, "HRP=" .. tostring(player.Character.HumanoidRootPart.Position))
            end
        end)
        if extra then table.insert(lines, tostring(extra)) end
        failLogWrite(table.concat(lines, "\n"))
    end
    local function banLog(category, msg)
        local cat = tostring(category or "")
        local text = tostring(msg or "")
        if cat == "BYPASS" or cat:sub(1, 3) == "AC-" or string.find(cat, "DESTROY", 1, true) or cat == "STRIKE" then
            cat, text = "Bypass", "success"
        end
        local entry = "[" .. os.date("%H:%M:%S") .. "] [" .. cat .. "] " .. text:sub(1, 300)
        table.insert(_banLog, entry)
        _banLog_counts[cat] = (_banLog_counts[cat] or 0) + 1
        if #_banLog > 500 then table.remove(_banLog, 1) end
        print("[fenti-log] " .. entry)
        -- Disk read+write every log was freezing the client (especially FISH spam).
        task.defer(function()
            pcall(function() failLogWrite(entry) end)
        end)
    end
    _G.fentiACLog = function(_cat, _msg)
        banLog("Bypass", "success")
    end
    
    local function fentiHttpGetVersion(url)
        local sep = string.find(url, "?", 1, true) and "&" or "?"
        local full = url .. sep .. "t=" .. tostring(tick())
        local ok, body = pcall(function() return game:HttpGet(full, true) end)
        if ok and type(body) == "string" and body ~= "" then return body end
        local req = (syn and syn.request) or (http and http.request) or http_request or request or fluxus_request
        if not req then return nil end
        local ok2, res = pcall(function()
            return req({ Url = full, Method = "GET" })
        end)
        if ok2 and type(res) == "table" and type(res.Body) == "string" and res.Body ~= "" then return res.Body end
        return nil
    end
    
    local function fentiOptionalRemoteVersionCheck()
        local url = rawget(_G, "FENTI_VERSION_CHECK_URL")
        if type(url) ~= "string" or url == "" then return end
        local expected = rawget(_G, "FENTI_EXPECTED_VERSION")
        if type(expected) ~= "number" then expected = FENTI_SCRIPT_VERSION end
        local body = fentiHttpGetVersion(url)
        if not body then
            banLog("VERSION", "check failed (no HTTP body)")
            return
        end
        local compile = loadstring or load
        if type(compile) ~= "function" then
            warn("[fenti] version check skipped — no loadstring/load")
            return
        end
        local chunk, cerr = compile(body)
        if type(chunk) ~= "function" then
            banLog("VERSION", "check failed compile: " .. tostring(cerr))
            return
        end
        local okRun, remoteVer = pcall(chunk)
        if not okRun or type(remoteVer) ~= "number" then
            banLog("VERSION", "check failed run: " .. tostring(remoteVer))
            return
        end
        banLog("VERSION", "remote=" .. tostring(remoteVer) .. " expected=" .. tostring(expected))
        if remoteVer ~= expected then
            local msg = "Outdated (remote " .. tostring(remoteVer) .. ", local " .. tostring(expected) .. ")."
            if rawget(_G, "FENTI_VERSION_KICK") == true then
                player:Kick(msg)
            else
                warn("[fenti] " .. msg .. " Set _G.FENTI_VERSION_KICK=true before run to kick.")
            end
        end
    end
    
    task.defer(function()
        pcall(fentiOptionalRemoteVersionCheck)
    end)
    
    _banLog._bypassDone = false
    _banLog._bypassHookCount = 0
    _banLog._onBypassApplied = nil
    
    banLog("INIT", "Ready.")
    failLogSnapshot("SESSION_START", "session started")
    
    if fentiAC.loaded and type(fentiAC.api.lateInit) == "function" then
        local okLate = pcall(function()
            fentiAC.api.lateInit({
                banLog = banLog,
                failLogWrite = failLogWrite,
                _banLog = _banLog,
                activeConnections = activeConnections,
                RS = RS,
                Players = Players,
                player = player,
                _fentiSkipACMonitoring = _fentiSkipACMonitoring,
                acLogVerbose = false,
            })
        end)
        if not okLate then
            warn("[fenti] AC module lateInit failed — edit/host fenti_ac_bypass.lua")
        end
    end
    
    pcall(function()
        Players.LocalPlayer.OnTeleport:Connect(function(state, placeId, spawnName)
            failLogWrite("[TELEPORT] state=" .. tostring(state.Name) .. " placeId=" .. tostring(placeId) .. " spawn=" .. tostring(spawnName))
            if state == Enum.TeleportState.Started then
                banLog("TELEPORT", "Being teleported to " .. tostring(placeId) .. " spawn=" .. tostring(spawnName))
            end
        end)
    end)
    
    pcall(function()
        if rawget(_G, "FENTI_NO_GUI_ERROR_LOG") == true then return end
        local lastErrSig, lastErrT = "", 0
        game:GetService("GuiService").ErrorMessageChanged:Connect(function(msg)
            if type(msg) ~= "string" or msg == "" then return end
            local sig = msg:sub(1, 500)
            local now = tick()
            if sig == lastErrSig and (now - lastErrT) < 12 then return end
            lastErrSig, lastErrT = sig, now
            banLog("ERROR-GUI", msg)
            failLogWrite("[GUI_KICK_OR_ERROR] " .. msg:sub(1, 800))
        end)
    end)
    
    pcall(function()
        local char = player.Character or player.CharacterAdded:Wait()
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.Died:Connect(function()
                banLog("DEATH", "Player died at " .. os.date("%H:%M:%S") .. " (pos=" .. tostring(humanoidRootPart and humanoidRootPart.Position or "?") .. ")")
            end)
        end
        player.CharacterAdded:Connect(function(newChar)
            local newHum = newChar:WaitForChild("Humanoid", 5)
            if newHum then
                newHum.Died:Connect(function()
                    banLog("DEATH", "Player died (respawned char)")
                end)
            end
        end)
    end)
    
    -- ----------------------------------------------------------------------------
    -- [FENTI-09] 9. HIGHLIGHT + SCREEN-TEXT ESP (no BillboardGui)
    -- ----------------------------------------------------------------------------
    local VisualSettings = {
        Enabled = false,
        RenderDistance = 2000,
        ShowHP = true,
        ShowName = true,
        ShowDisplayName = true,
        ShowDistance = true,
        ShowWeapon = true,
        ShowHighlightFill = true,
        HighlightFill = 0.55,
        HighlightOutline = 0.2,
        PlayerColor = Color3.fromRGB(255, 50, 50),
        EntityEnabled = false,
        EntityColor = Color3.fromRGB(255, 255, 0),
        ESPAlwaysOnTop = true,
    }
    
    local entities = workspace:FindFirstChild("Entities")
    
    local function getESPScreenGui()
        if ESPState.screenGui and ESPState.screenGui.Parent then return ESPState.screenGui end
        local sg = Instance.new("ScreenGui")
        sg.Name = "fenti_ESP_Overlay"
        sg.ResetOnSpawn = false
        sg.IgnoreGuiInset = false
        sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        sg.DisplayOrder = 750
        sg.Enabled = true
        local ok = pcall(function() sg.Parent = game:GetService("CoreGui") end)
        if not ok or not sg.Parent then
            pcall(function() sg.Parent = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui", 8) end)
        end
        ESPState.screenGui = sg
        return sg
    end
    
    local function isVisible(position, whitelist)
        local cam = workspace.CurrentCamera
        if not cam then return false end
        local filter = whitelist or {}
        pcall(function() if player.Character then table.insert(filter, player.Character) end end)
        return #cam:GetPartsObscuringTarget({position}, filter) == 0
    end
    
    local function fentiESPIsLocalCharacterTarget(target)
        if not target then return false end
        local lp = Players.LocalPlayer
        if not lp then return false end
        local myChar = lp.Character
        if myChar then
            if target == myChar or target:IsDescendantOf(myChar) then return true end
        end
        local owner = Players:GetPlayerFromCharacter(target)
        return owner ~= nil and owner == lp
    end
    
    local function fentiESPGetCharacterHoldingName(char)
        if not char then return nil end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local toolName = nil
        if hum then
            pcall(function()
                local t = hum:GetEquippedTool()
                if t then toolName = t.Name end
            end)
        end
        if not toolName then
            local t2 = char:FindFirstChildWhichIsA("Tool")
            if t2 then toolName = t2.Name end
        end
        return toolName
    end
    
    local function createESPGui(target, color, labelText, _showHP, _isEntity)
        if not target then return nil end
        if fentiESPIsLocalCharacterTarget(target) then return nil end
        local rootPart = target:FindFirstChild("HumanoidRootPart")
        if not rootPart then return nil end
    
        local sg = getESPScreenGui()
        local textLbl = Instance.new("TextLabel")
        textLbl.Name = "fenti_ESP_text"
        textLbl.BackgroundTransparency = 1
        textLbl.TextColor3 = color
        textLbl.Text = labelText or target.Name
        textLbl.TextSize = 15
        textLbl.Font = Enum.Font.GothamBold
        textLbl.TextStrokeTransparency = 0.45
        textLbl.TextStrokeColor3 = Color3.new(0, 0, 0)
        textLbl.TextXAlignment = Enum.TextXAlignment.Center
        textLbl.TextYAlignment = Enum.TextYAlignment.Bottom
        textLbl.AnchorPoint = Vector2.new(0.5, 1)
        textLbl.Visible = false
        pcall(function() textLbl.AutomaticSize = Enum.AutomaticSize.XY end)
        textLbl.Size = UDim2.fromOffset(2, 2)
        textLbl.ZIndex = 5
        textLbl.Parent = sg
    
        local hl = Instance.new("Highlight")
        hl.Name = "fenti_ESP_HL"
        hl.FillColor = color
        hl.FillTransparency = VisualSettings.ShowHighlightFill and VisualSettings.HighlightFill or 1
        hl.OutlineColor = color
        hl.OutlineTransparency = VisualSettings.HighlightOutline
        hl.Enabled = VisualSettings.ShowHighlightFill or VisualSettings.HighlightOutline < 0.99
        hl.Parent = target
        pcall(function()
            if VisualSettings.ESPAlwaysOnTop then hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop end
        end)
    
        return { TextLabel = textLbl, Highlight = hl }
    end
    
    local function addPlayerESP(plr)
        if not plr or plr == player or (player and plr.UserId == player.UserId) then return end
        removePlayerESP(plr)
        local char = plr.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then return end
        local disp = VisualSettings.ShowDisplayName and plr.DisplayName ~= "" and plr.DisplayName or plr.Name
        local line = VisualSettings.ShowDisplayName and plr.DisplayName ~= plr.Name
            and (disp .. "  @" .. plr.Name) or disp
        local objs = createESPGui(char, VisualSettings.PlayerColor, line, VisualSettings.ShowHP, false)
        if objs then
            ESPState.PlayerCache[plr] = { Character = char, Objects = objs }
        end
    end
    
    removePlayerESP = function(plr)
        local data = ESPState.PlayerCache[plr]
        if data then
            pcall(function() if data.Objects.TextLabel then data.Objects.TextLabel:Destroy() end end)
            pcall(function() if data.Objects.Highlight then data.Objects.Highlight:Destroy() end end)
            ESPState.PlayerCache[plr] = nil
        end
    end
    
    local function addEntityESP(ent)
        if fentiESPIsLocalCharacterTarget(ent) then return end
        if Players:GetPlayerFromCharacter(ent) then return end
        if player and player.Character and ent == player.Character then return end
        if not ent:FindFirstChildOfClass("Humanoid") then return end
        removeEntityESP(ent)
        local hum = ent:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then return end
        local objs = createESPGui(ent, VisualSettings.EntityColor, ent.Name, true, true)
        if objs then
            ESPState.EntityCache[ent] = {Objects = objs}
        end
    end
    
    removeEntityESP = function(ent)
        local data = ESPState.EntityCache[ent]
        if data then
            pcall(function() if data.Objects.TextLabel then data.Objects.TextLabel:Destroy() end end)
            pcall(function() if data.Objects.Highlight then data.Objects.Highlight:Destroy() end end)
            ESPState.EntityCache[ent] = nil
        end
    end
    
    local function updateESPLoop()
        refreshCharacter()
        if not humanoidRootPart then return end
        local cam = workspace.CurrentCamera
        if not cam then
            for _, data in pairs(ESPState.PlayerCache) do
                pcall(function()
                    local o = data.Objects
                    if o and o.TextLabel then o.TextLabel.Visible = false end
                end)
            end
            for _, data in pairs(ESPState.EntityCache) do
                pcall(function()
                    local o = data.Objects
                    if o and o.TextLabel then o.TextLabel.Visible = false end
                end)
            end
            return
        end
        local myPos = humanoidRootPart.Position
        local maxD = VisualSettings.RenderDistance
        local maxDsq = maxD * maxD
    
        for plr, data in pairs(ESPState.PlayerCache) do
            if plr == player or (player and plr.UserId == player.UserId) then
                removePlayerESP(plr)
            else
            pcall(function()
                local char = data.Character
                local objs = data.Objects
                local lbl = objs and objs.TextLabel
                local hl = objs and objs.Highlight
                if not char or not char.Parent or not char:FindFirstChild("HumanoidRootPart") then
                    removePlayerESP(plr); return
                end
                local root = char.HumanoidRootPart
                local hum = char:FindFirstChildOfClass("Humanoid")
                if not hum or hum.Health <= 0 then removePlayerESP(plr); return end
    
                local dOff = myPos - root.Position
                local dSq = dOff:Dot(dOff)
                if dSq > maxDsq then
                    if lbl then lbl.Visible = false end
                    if hl then hl.Enabled = false end
                    return
                end
                local dist = math.floor(math.sqrt(dSq))
                if hl then
                    hl.Enabled = true
                    hl.FillTransparency = VisualSettings.ShowHighlightFill and VisualSettings.HighlightFill or 1
                end
    
                local worldPt = root.Position + Vector3.new(0, 3, 0)
                local sp, onScreen = cam:WorldToViewportPoint(worldPt)
                local okVis = onScreen and sp.Z > 0
    
                local lines = {}
                if VisualSettings.ShowName then
                    if VisualSettings.ShowDisplayName then
                        local disp = plr.DisplayName ~= "" and plr.DisplayName or plr.Name
                        table.insert(lines, (plr.DisplayName ~= plr.Name) and (disp .. "  @" .. plr.Name) or disp)
                    else
                        table.insert(lines, plr.Name)
                    end
                end
                if VisualSettings.ShowDistance then table.insert(lines, dist .. "m") end
                if VisualSettings.ShowHP then
                    table.insert(lines, string.format("%.0f / %.0f HP", hum.Health, hum.MaxHealth))
                end
                if VisualSettings.ShowWeapon then
                    local holdName = fentiESPGetCharacterHoldingName(char)
                    if holdName then table.insert(lines, "Holding: " .. holdName) end
                end
                if lbl and cam then
                    lbl.TextColor3 = VisualSettings.PlayerColor
                    lbl.Text = table.concat(lines, "\n")
                    lbl.Visible = okVis and #lines > 0
                    if lbl.Visible then lbl.Position = UDim2.fromOffset(sp.X, sp.Y - 6) end
                end
            end)
            end
        end
    
        for ent, data in pairs(ESPState.EntityCache) do
            if fentiESPIsLocalCharacterTarget(ent) then
                removeEntityESP(ent)
            else
            pcall(function()
                local objs = data.Objects
                local lbl = objs and objs.TextLabel
                local hl = objs and objs.Highlight
                if not ent or not ent.Parent or not ent:FindFirstChild("HumanoidRootPart") then
                    removeEntityESP(ent); return
                end
                local root = ent.HumanoidRootPart
                local hum = ent:FindFirstChildOfClass("Humanoid")
                if not hum or hum.Health <= 0 then removeEntityESP(ent); return end
    
                local dOff2 = myPos - root.Position
                local dSq = dOff2:Dot(dOff2)
                if dSq > maxDsq then
                    if lbl then lbl.Visible = false end
                    if hl then hl.Enabled = false end
                    return
                end
                local dist = math.floor(math.sqrt(dSq))
                if hl then
                    hl.Enabled = true
                    hl.FillTransparency = VisualSettings.ShowHighlightFill and VisualSettings.HighlightFill or 1
                end
    
                local worldPt = root.Position + Vector3.new(0, 3, 0)
                local sp, onScreen = cam:WorldToViewportPoint(worldPt)
                local okVis = onScreen and sp.Z > 0
    
                local lines = {}
                if VisualSettings.ShowName then table.insert(lines, ent.Name) end
                if VisualSettings.ShowWeapon then
                    local holdName = fentiESPGetCharacterHoldingName(ent)
                    if holdName then table.insert(lines, "Holding: " .. holdName) end
                end
                if VisualSettings.ShowDistance then table.insert(lines, dist .. "m") end
                if VisualSettings.ShowHP then
                    table.insert(lines, string.format("%.0f / %.0f HP", hum.Health, hum.MaxHealth))
                end
                if lbl and cam then
                    lbl.TextColor3 = VisualSettings.EntityColor
                    lbl.Text = table.concat(lines, "\n")
                    lbl.Visible = okVis and #lines > 0
                    if lbl.Visible then lbl.Position = UDim2.fromOffset(sp.X, sp.Y - 6) end
                end
            end)
            end
        end
    end
    
    local function disconnectESPWorldListeners()
        for _, c in ipairs(ESPState.worldConns) do pcall(function() c:Disconnect() end) end
        table.clear(ESPState.worldConns)
    end
    
    local function rebuildESP()
        for plr, _ in pairs(ESPState.PlayerCache) do removePlayerESP(plr) end
        for ent, _ in pairs(ESPState.EntityCache) do removeEntityESP(ent) end
        table.clear(ESPState.PlayerCache); table.clear(ESPState.EntityCache)
    
        if not VisualSettings.Enabled then return end
    
        for _, plr in pairs(Players:GetPlayers()) do
            if plr and player and plr ~= player and plr.UserId ~= player.UserId then addPlayerESP(plr) end
        end
        if VisualSettings.EntityEnabled and entities then
            for _, ent in pairs(entities:GetChildren()) do addEntityESP(ent) end
        end
    end
    
    local function startESP()
        ESPState.espSession = (ESPState.espSession or 0) + 1
        local session = ESPState.espSession
        disconnectESPWorldListeners()
        rebuildESP()
        table.insert(ESPState.worldConns, Players.PlayerAdded:Connect(function(plr)
            if not plr or plr == player or (player and plr.UserId == player.UserId) then return end
            if espEnabled and VisualSettings.Enabled then addPlayerESP(plr) end
        end))
        table.insert(ESPState.worldConns, Players.PlayerRemoving:Connect(function(plr) removePlayerESP(plr) end))
        if entities then
            table.insert(ESPState.worldConns, entities.ChildAdded:Connect(function(ent)
                if espEnabled and VisualSettings.Enabled and VisualSettings.EntityEnabled then addEntityESP(ent) end
            end))
            table.insert(ESPState.worldConns, entities.ChildRemoved:Connect(function(ent) removeEntityESP(ent) end))
        end
    
        if ESPState.updateConn then ESPState.updateConn:Disconnect() end
        ESPState.updateConn = RunService.RenderStepped:Connect(function()
            if not espEnabled or not VisualSettings.Enabled then return end
            pcall(updateESPLoop)
        end)
    
        task.spawn(function()
            while ESPState.espSession == session and espEnabled and VisualSettings.Enabled do
                task.wait(22)
                if ESPState.espSession ~= session or not espEnabled or not VisualSettings.Enabled then break end
                pcall(rebuildESP)
            end
        end)
    end
    
    local function stopESP()
        ESPState.espSession = (ESPState.espSession or 0) + 1
        disconnectESPWorldListeners()
        if ESPState.updateConn then ESPState.updateConn:Disconnect(); ESPState.updateConn = nil end
        for plr, _ in pairs(ESPState.PlayerCache) do
            local data = ESPState.PlayerCache[plr]
            if data then
                pcall(function() if data.Objects.TextLabel then data.Objects.TextLabel:Destroy() end end)
                pcall(function() if data.Objects.Highlight then data.Objects.Highlight:Destroy() end end)
            end
        end
        table.clear(ESPState.PlayerCache)
        for ent, _ in pairs(ESPState.EntityCache) do
            local data = ESPState.EntityCache[ent]
            if data then
                pcall(function() if data.Objects.TextLabel then data.Objects.TextLabel:Destroy() end end)
                pcall(function() if data.Objects.Highlight then data.Objects.Highlight:Destroy() end end)
            end
        end
        table.clear(ESPState.EntityCache)
        pcall(function()
            if ESPState.screenGui then ESPState.screenGui:Destroy(); ESPState.screenGui = nil end
        end)
    end
    
    local function fentiPlayerESPToggleRebuild()
        if espEnabled and VisualSettings.Enabled then pcall(rebuildESP) end
    end
    
    -- ----------------------------------------------------------------------------
    -- [FENTI-10] Aimbot / silent aim — removed (triggerbot unchanged).
    -- ----------------------------------------------------------------------------
    -- [FENTI-11] GetMousePos RF cleanup only (no __namecall hooks).
    -- ----------------------------------------------------------------------------
    local function uninstallGetMousePosHook()
        pcall(function()
            local getMousePos = Remotes and Remotes:FindFirstChild("GetMousePos")
            if getMousePos and getMousePos:IsA(FENTI_CLASS_REMOTE_FUNCTION) then
                getMousePos.OnClientInvoke = nil
            end
        end)
    end
    
    local function _applyBypassSideEffects() end
    _banLog._onBypassApplied = _applyBypassSideEffects
    if _banLog._bypassDone then task.defer(_applyBypassSideEffects) end
    
    -- ----------------------------------------------------------------------------
    -- [FENTI-12] 12. COMBAT (triggerbot, no screen shake)
    -- ----------------------------------------------------------------------------
    local function getGunRaycastTarget(range)
        local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
        local ray = camera:ViewportPointToRay(screenCenter.X, screenCenter.Y)
        local fireRange = range or 5000
        local filterList = {player.Character}
        pcall(function()
            for _, obj in ipairs(game:GetService("CollectionService"):GetTagged("BulletPassThrough")) do
                table.insert(filterList, obj)
            end
        end)
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        rayParams.FilterDescendantsInstances = filterList
        pcall(function() rayParams.CollisionGroup = "RaycastCollisionGroup" end)
    
        local glassMats = {
            [Enum.Material.Wood] = true, [Enum.Material.WoodPlanks] = true,
            [Enum.Material.Plastic] = true, [Enum.Material.SmoothPlastic] = true,
            [Enum.Material.Fabric] = true, [Enum.Material.Ice] = true, [Enum.Material.Glass] = true,
        }
        local origin, direction, remaining = ray.Origin, ray.Direction, fireRange
    
        for _ = 1, 5 do
            rayParams.FilterDescendantsInstances = filterList
            local result = workspace:Raycast(origin, direction * remaining, rayParams)
            if not result then return ray.Origin + ray.Direction * fireRange, nil end
            local hitModel = result.Instance:FindFirstAncestorOfClass("Model")
            if hitModel and hitModel:FindFirstChildOfClass("Humanoid") then return result.Position, hitModel end
            if glassMats[result.Instance.Material] then
                table.insert(filterList, result.Instance)
                remaining = remaining - (result.Position - origin).Magnitude
                origin = result.Position + direction * 0.1
                if remaining <= 0 then return result.Position, nil end
            else return result.Position, nil end
        end
        return ray.Origin + ray.Direction * fireRange, nil
    end
    
    local function fentiToolAmmoCount(tool)
        if not tool then return nil end
        local clip = tool:FindFirstChild("AmmoInClip")
        if clip and clip:IsA("IntValue") then return clip.Value end
        local ok, n = pcall(function()
            local sc = tool:FindFirstChild("ServerConfig")
            if not sc then return nil end
            local m = require(sc)
            if type(m) == "table" and type(m.AmmoInClip) == "number" then return m.AmmoInClip end
            return nil
        end)
        if ok and type(n) == "number" then return n end
        return nil
    end
    
    local function fentiPlayerWantsReload(char)
        if UIS:IsKeyDown(Enum.KeyCode.R) then return true end
        if UIS.GamepadEnabled and UIS:IsGamepadButtonPressed(Enum.UserInputType.Gamepad1, Enum.KeyCode.ButtonX) then return true end
        if not char then return false end
        if char:GetAttribute("IsReloading") == true or char:GetAttribute("Reloading") == true then return true end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and hum:GetAttribute("IsReloading") == true then return true end
        return false
    end
    
    local function triggerbotLoop()
        while triggerbotEnabled do
            pcall(function()
                local char = player.Character
                if not char then
                    pcall(function() if GunActionRemote then GunActionRemote:FireServer("StopAutoFire") end end)
                    return
                end
                local myHum = char:FindFirstChildOfClass("Humanoid")
                if not myHum or myHum.Health <= 0 then
                    pcall(function() if GunActionRemote then GunActionRemote:FireServer("StopAutoFire") end end)
                    return
                end
                local tool = char:FindFirstChildOfClass("Tool")
                if not tool then
                    pcall(function() if GunActionRemote then GunActionRemote:FireServer("StopAutoFire") end end)
                    return
                end
                local isGun = tool:FindFirstChild("ServerConfig") or tool:FindFirstChild("ClientConfig") or tool:FindFirstChild("AmmoInClip")
                if not isGun then return end
    
                if fentiPlayerWantsReload(char) then
                    pcall(function() if GunActionRemote then GunActionRemote:FireServer("StopAutoFire") end end)
                    return
                end
                local ammoLeft = fentiToolAmmoCount(tool)
                if ammoLeft ~= nil and ammoLeft <= 0 then
                    pcall(function() if GunActionRemote then GunActionRemote:FireServer("StopAutoFire") end end)
                    return
                end
    
                local triggerRange = Options.TriggerRange and Options.TriggerRange.Value or 5000
                local hitPos, hitModel = getGunRaycastTarget(triggerRange)
                if hitModel then
                    local hum = hitModel:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        local isPlayer = Players:GetPlayerFromCharacter(hitModel)
                        local shouldFire = (isPlayer and isPlayer ~= player) or (not isPlayer and Toggles.TriggerNPCs and Toggles.TriggerNPCs.Value)
                        if shouldFire and GunActionRemote then
                            local isAuto = false
                            pcall(function() isAuto = require(tool.ClientConfig).IsAutomatic == true end)
                            local isAiming = char:GetAttribute("IsAiming") or false
                            if isAuto then
                                local okBurst = pcall(function()
                                    GunActionRemote:FireServer("StartAutoFire", hitPos, isAiming)
                                    task.wait(Options.TriggerDelay and Options.TriggerDelay.Value or 0.05)
                                    pcall(function() GunActionRemote:FireServer("UpdateAutoFireTarget", hitPos, isAiming) end)
                                    task.wait(0.05)
                                end)
                                pcall(function() GunActionRemote:FireServer("StopAutoFire") end)
                                if not okBurst then
                                    task.wait(0.05)
                                    pcall(function() GunActionRemote:FireServer("StopAutoFire") end)
                                end
                            else
                                GunActionRemote:FireServer("Fire", hitPos, isAiming)
                            end
                            task.wait(Options.TriggerDelay and Options.TriggerDelay.Value or 0.1)
                        end
                    end
                end
            end)
            task.wait(0.08)
        end
        pcall(function() if GunActionRemote then GunActionRemote:FireServer("StopAutoFire") end end)
    end
    
    local function enableNoScreenShake()
        if screenShakeHooked then return end
        screenShakeHooked = true
        local shakeRemote = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("ScreenShakeRemote")
        if not shakeRemote then
            for _, desc in pairs(RS:GetDescendants()) do
                if desc.Name == "ScreenShakeRemote" then shakeRemote = desc; break end
            end
        end
        if shakeRemote then
            if Support.Connections then
                pcall(function()
                    for _, conn in pairs(getconnections(shakeRemote.OnClientEvent)) do
                        if conn.Disable then conn:Disable() elseif conn.Disconnect then conn:Disconnect() end
                    end
                end)
            end
            table.insert(screenShakeConnections, shakeRemote.OnClientEvent:Connect(function() return end))
        end
        local lastCamCF = camera.CFrame
        local shakeSkip = 0
        table.insert(screenShakeConnections, RunService.RenderStepped:Connect(function()
            if not noScreenShake then return end
            shakeSkip = shakeSkip + 1; if shakeSkip < 2 then return end; shakeSkip = 0
            local currentCF = camera.CFrame
            local delta = (currentCF.Position - lastCamCF.Position).Magnitude
            if delta > 0.01 and delta < 0.5 then
                local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
                if hum and hum.MoveDirection.Magnitude < 0.1 and not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
                    camera.CFrame = lastCamCF; return
                end
            end
            lastCamCF = currentCF
        end))
    end
    
    local function disableNoScreenShake()
        screenShakeHooked = false
        for _, conn in pairs(screenShakeConnections) do if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end end
        table.clear(screenShakeConnections)
    end
    
    -- ----------------------------------------------------------------------------
    -- [FENTI-13] 13. HORSE SYSTEM
    -- ----------------------------------------------------------------------------
    local function getPlayerHorse()
        local uid = tostring(player.UserId)
        for _, child in pairs(workspace:GetChildren()) do
            if child:IsA("Model") and child:FindFirstChildOfClass("Humanoid") then
                for _, attr in ipairs({ "OwnerPlayer", "OwnerUserId", "Owner", "PlayerUserId", "UserId" }) do
                    local o = child:GetAttribute(attr)
                    if o ~= nil and tostring(o) == uid then return child end
                end
            end
        end
        return nil
    end
    
    local function spawnHorse()
        if not ToggleHorseRemote then Library:Notify("ToggleHorse remote not found!", 3); return false end
        if getPlayerHorse() then return true end
        ToggleHorseRemote:FireServer()
        local okHorse = false
        for i = 1, 50 do task.wait(0.3); if getPlayerHorse() then okHorse = true; break end end
        if okHorse then return true end
        Library:Notify("Horse did not spawn in time!", 3); return false
    end
    
    local function fireHorsePrompt(horse)
        if not horse then return false end
        local fired = false
        for _, desc in pairs(horse:GetDescendants()) do
            if desc:IsA("ProximityPrompt") then
                pcall(function()
                    desc.HoldDuration = 0
                    local m = desc.MaxActivationDistance
                    desc.MaxActivationDistance = math.min(FENTI_PROMPT_MAX_STRETCH, math.max(m > 0.05 and m or 10, 18))
                    desc.Enabled = true
                end)
                task.wait(0.05)
                safeFireProximityPrompt(desc)
                fired = true
            end
        end
        if not fired then
            pcall(function()
                for _, desc in pairs(workspace:GetDescendants()) do
                    if desc:IsA("ProximityPrompt") and desc.Parent and desc.Parent.Parent == horse then
                        pcall(function()
                            desc.HoldDuration = 0
                            local m = desc.MaxActivationDistance
                            desc.MaxActivationDistance = math.min(FENTI_PROMPT_MAX_STRETCH, math.max(m > 0.05 and m or 10, 18))
                            desc.Enabled = true
                        end)
                        task.wait(0.05)
                        safeFireProximityPrompt(desc)
                        fired = true; break
                    end
                end
            end)
        end
        return fired
    end
    
    local function isMounted()
        if isOnHorse then return true end
        local char = player.Character
        if char and char:GetAttribute("IsRiding") then isOnHorse = true; return true end
        return false
    end
    
    local function spamMountPrompt(horse, timeout)
        timeout = timeout or 10
        local startTime = tick()
        while not isMounted() and (tick() - startTime) < timeout do
            refreshCharacter()
            if humanoidRootPart then
                local pp = horse and horse.PrimaryPart
                if pp then humanoidRootPart.CFrame = pp.CFrame + Vector3.new(0, 3, 0) end
            end
            fireHorsePrompt(horse)
            task.wait(0.15)
        end
        return isMounted()
    end
    
    local function mountHorse()
        if isMounted() then return true end
        if not ToggleHorseRemote then Library:Notify("ToggleHorse remote not found!", 3); return false end
        local horse = getPlayerHorse()
        if horse then
            if spamMountPrompt(horse, 20) then
                return true
            end
        end
        if not getPlayerHorse() then ToggleHorseRemote:FireServer() end
        local startTime = tick()
        while not isMounted() and (tick() - startTime) < 30 do
            horse = getPlayerHorse()
            if horse then
                refreshCharacter()
                local pp = horse.PrimaryPart
                if humanoidRootPart and pp then humanoidRootPart.CFrame = pp.CFrame + Vector3.new(0, 3, 0) end
                fireHorsePrompt(horse)
            end
            task.wait(0.15)
        end
        if isMounted() then return true end
        Library:Notify("Could not mount horse!", 3); return false
    end
    
    local function dismountHorse()
        if not isOnHorse then return end
        if HorseControlEvent then HorseControlEvent:FireServer("DismountRequest") end
    end
    
    local function buyHorse()
        if not DialogueRemote then Library:Notify("DialogueRemote not found!", 3); return end
        pcall(function() DialogueRemote:FireServer("Action", "Buy_Horse") end)
        task.wait(0.3)
        pcall(function() DialogueRemote:FireServer("Buy_Horse") end)
        Library:Notify("Buy horse request sent!", 3)
    end
    
    local function fentiBriefVelocityDamp(hrp, frames)
        frames = frames or 6
        if not hrp then return end
        local n = 0
        local conn
        conn = RunService.Heartbeat:Connect(function()
            n = n + 1
            pcall(function()
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                hrp.Velocity = Vector3.zero
                hrp.RotVelocity = Vector3.zero
            end)
            if n >= frames then pcall(function() conn:Disconnect() end) end
        end)
    end
    
    local function respawnTeleportHoldSeconds(studDist)
        studDist = math.max(0, studDist or 0)
        return math.clamp(2.2 + studDist * 0.008, 2.2, 12)
    end

    -- After CharacterAdded: wait until humanoid is alive and HRP exists so respawn snap does not run on a half-loaded rig.
    local function fentiWaitForRespawnReady(newChar, maxWait)
        maxWait = maxWait or 15
        if not newChar or not newChar.Parent then return nil end
        local t0 = tick()
        local hum = newChar:WaitForChild("Humanoid", math.min(8, maxWait))
        if not hum then return nil end
        while tick() - t0 < maxWait do
            local root = newChar:FindFirstChild("HumanoidRootPart")
            if root and root.Parent and hum.Parent and hum.Health > 0 then
                task.wait(0.2)
                return root
            end
            task.wait(0.05)
        end
        return newChar:FindFirstChild("HumanoidRootPart")
    end
    
    local function respawnTeleportTo(destination, logTag)
        refreshCharacter()
        if not humanoidRootPart then banLog("TP", "Teleport cancelled — wait for character."); return false end
        local destCF = typeof(destination) == "CFrame" and destination or CFrame.new(destination)
        local destPos = destCF.Position + Vector3.new(0, 3, 0)
        destCF = CFrame.new(destPos, destPos + destCF.LookVector)
        local tpDist = (humanoidRootPart.Position - destPos).Magnitude
        local holdSec = respawnTeleportHoldSeconds(tpDist)
        local hum = character and character:FindFirstChildOfClass("Humanoid")
        if hum then hum.Health = 0 end
    
        local newChar = player.CharacterAdded:Wait()
        local newRoot = fentiWaitForRespawnReady(newChar, 15)
        if not newRoot then newRoot = newChar:WaitForChild("HumanoidRootPart", 10) end
        if not newRoot then banLog("TP", "Teleport failed — no spawn position."); failLogWrite("[TP_FAIL] no HumanoidRootPart after respawn"); return false end
        character = newChar; humanoidRootPart = newRoot
    
        task.wait(0.12)
        pcall(function() newRoot.Anchored = true end)
        newRoot.CFrame = destCF
        newRoot.AssemblyLinearVelocity = Vector3.zero
        newRoot.AssemblyAngularVelocity = Vector3.zero
        task.wait(0.12)
        newRoot.CFrame = destCF
    
        local holdConn; holdConn = RunService.Heartbeat:Connect(function()
            pcall(function()
                newRoot.CFrame = destCF
                newRoot.AssemblyLinearVelocity = Vector3.zero
            end)
        end)
        task.wait(holdSec)
        holdConn:Disconnect()
        pcall(function() newRoot.Anchored = false end)
    
        return true
    end
    
    -- Respawn snap: no 0.12s waits, no multi-second pin (for instant chains).
    local function respawnTeleportInstant(destination, logTag)
        refreshCharacter()
        if not humanoidRootPart then
            banLog("TP", "Instant respawn TP cancelled — no HRP.")
            return false
        end
        local destCF = typeof(destination) == "CFrame" and destination or CFrame.new(destination)
        local destPos = destCF.Position + Vector3.new(0, 3, 0)
        destCF = CFrame.new(destPos, destPos + destCF.LookVector)
        local hum = character and character:FindFirstChildOfClass("Humanoid")
        if hum then
            pcall(function() hum.Health = 0 end)
            task.wait(0.04)
            pcall(function()
                if hum.Parent and hum.Health > 0.05 then
                    hum:TakeDamage((hum.MaxHealth or 100) + 1e5)
                end
            end)
        end
        local newChar = player.CharacterAdded:Wait()
        local newRoot = fentiWaitForRespawnReady(newChar, 15)
        if not newRoot then newRoot = newChar:WaitForChild("HumanoidRootPart", 10) end
        if not newRoot then
            banLog("TP", "Instant respawn TP failed — no HRP after respawn [" .. tostring(logTag) .. "]")
            return false
        end
        character, humanoidRootPart = newChar, newRoot
        pcall(function()
            newRoot.CFrame = destCF
            newRoot.AssemblyLinearVelocity = Vector3.zero
            newRoot.AssemblyAngularVelocity = Vector3.zero
            newRoot.Velocity = Vector3.zero
            newRoot.RotVelocity = Vector3.zero
        end)
        refreshCharacter()
        return true
    end
    
    pcall(function()
        if HorseControlEvent then
            HorseControlEvent.OnClientEvent:Connect(function(action)
                if action == "Mount" then isOnHorse = true
                elseif action == "DismountComplete" then isOnHorse = false end
            end)
        end
    end)
    
    -- ----------------------------------------------------------------------------
    -- [FENTI-14] 14. TELEPORT (smart + prompt moves; fishing anchor snap separate)
    -- ----------------------------------------------------------------------------
    -- Must NOT use fishing `isRunning` here — a stale connection stayed idle until fishing started, then fought casts.
    local function lockRootMotion()
        _G.fentiVelocityLockActive = true
        if rootMotionLockConn then rootMotionLockConn:Disconnect() end
        local acc = 0
        rootMotionLockConn = RunService.Heartbeat:Connect(function(dt)
            acc = acc + dt
            if acc < 0.22 then return end
            acc = 0
            if rawget(_G, "fentiVelocityLockActive") and humanoidRootPart then
                pcall(function()
                    humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
                    humanoidRootPart.AssemblyAngularVelocity = Vector3.zero
                    humanoidRootPart.Velocity = Vector3.zero
                    humanoidRootPart.RotVelocity = Vector3.zero
                end)
            end
        end)
    end
    local function unlockRootMotion()
        _G.fentiVelocityLockActive = nil
        if rootMotionLockConn then rootMotionLockConn:Disconnect(); rootMotionLockConn = nil end
    end
    local function startTPLoop()
        if tpLoopConnection then tpLoopConnection:Disconnect() end
        local acc = 0
        tpLoopConnection = RunService.Heartbeat:Connect(function(dt)
            acc = acc + dt
            if acc < 0.22 then return end
            acc = 0
            if isRunning and originalPosition and humanoidRootPart then
                local drift = (humanoidRootPart.Position - originalPosition).Magnitude
                if drift > 5 and not rawget(_G, "fentiFishingNoSnap") then
                    pcall(function()
                        humanoidRootPart.CFrame = CFrame.new(originalPosition)
                        humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
                        humanoidRootPart.AssemblyAngularVelocity = Vector3.zero
                        humanoidRootPart.Velocity = Vector3.zero
                        humanoidRootPart.RotVelocity = Vector3.zero
                    end)
                end
            end
        end)
    end
    local function stopTPLoop()
        if tpLoopConnection then tpLoopConnection:Disconnect(); tpLoopConnection = nil end
    end
    
    -- Prompt geometry (true IIFE — locals live in a separate prototype; `do` does not reset Luau ~200-local limit)
    local fentiPromptWorldPosition, fentiShouldAttemptPromptFire, patchNearbyPrompts
    (function()
        local function fpwp(prompt)
            if not prompt or not prompt:IsA("ProximityPrompt") then return nil end
            local parent = prompt.Parent
            if parent and parent:IsA("BasePart") then return parent.Position end
            if parent and parent:IsA("Attachment") then
                local ok, p = pcall(function() return parent.WorldPosition end)
                if ok and p then return p end
            end
            if parent and parent:IsA("Model") then
                local ok, p = pcall(function() return parent:GetPivot().Position end)
                if ok and p then return p end
            end
            if parent then
                local bp = parent:FindFirstAncestorWhichIsA("BasePart")
                if bp then return bp.Position end
                local att = parent:FindFirstAncestorWhichIsA("Attachment")
                if att then
                    local ok, p = pcall(function() return att.WorldPosition end)
                    if ok and p then return p end
                end
            end
            return nil
        end
        local function frip(root, prompt, outerRadius)
            if not root or not prompt then return false end
            local pos = fpwp(prompt)
            if not pos then return false end
            local gameMax = prompt.MaxActivationDistance
            local base = gameMax > 0.05 and gameMax or outerRadius
            local cap = math.min(outerRadius, math.max(base, 15))
            return (root.Position - pos).Magnitude <= cap + 4
        end
        local function fsap(root, prompt, outerRadius)
            if not prompt then return false end
            if not root then return true end
            local anchor = fpwp(prompt)
            if anchor == nil then return true end
            return frip(root, prompt, outerRadius)
        end
        local function pnp(center, radius)
            radius = radius or 60
            pcall(function()
                for _, desc in pairs(workspace:GetDescendants()) do
                    if desc:IsA("ProximityPrompt") then
                        local pos = fpwp(desc)
                        if pos and (pos - center).Magnitude < radius then
                            desc.HoldDuration = 0
                            local m = desc.MaxActivationDistance
                            desc.MaxActivationDistance = math.min(FENTI_PROMPT_MAX_STRETCH, math.max(m > 0.05 and m or 10, 18))
                            desc.Enabled = true
                            desc.RequiresLineOfSight = false
                        end
                    end
                end
            end)
        end
        fentiPromptWorldPosition = fpwp
        fentiShouldAttemptPromptFire = fsap
        patchNearbyPrompts = pnp
    end)()
    
    local function fentiSoftTeleportTo(destination, logTag)
        logTag = tostring(logTag or "softTP")
        refreshCharacter()
        if not humanoidRootPart then
            banLog("TP", "TP cancelled — no HRP [" .. logTag .. "]")
            return false
        end
        local destCF = typeof(destination) == "CFrame" and destination or CFrame.new(destination)
        local Rm = RS:FindFirstChild("Remotes")
        local mov = Rm and Rm:FindFirstChild("ActionRemote")
        pcall(function()
            if mov then mov:FireServer("Vault") end
        end)
        task.wait(0.08)
        refreshCharacter()
        if not humanoidRootPart then return false end
        pcall(function()
            humanoidRootPart.CFrame = destCF
        end)
        banLog("TP", "TP OK [" .. logTag .. "]")
        return true
    end
    _G.fentiSoftTeleportTo = fentiSoftTeleportTo

    local function fentiPromptMoveTeleport(destination, logTag)
        return fentiSoftTeleportTo(destination, logTag)
    end
    local function smartTeleport(destination)
        refreshCharacter()
        if not humanoidRootPart then return end
        fentiSoftTeleportTo(destination, "smartTP")
    end
    local function fentiPromptTeleport(destination)
        fentiPromptMoveTeleport(destination, "promptTP")
    end
    
    -- ----------------------------------------------------------------------------
    -- [FENTI-15] 15. SHOP / NPC / BANK + PROXIMITY
    -- ----------------------------------------------------------------------------
    -- --- NPC + Daniel shop + bank (remote dialogue) ---
    local function npcAction(action, npcModel)
        if not npcModel then Library:Notify("NPC not found!", 3); return end
        if not DialogueRemote then Library:Notify("DialogueRemote not found!", 3); return end
        pcall(function() DialogueRemote:FireServer("Action", action, npcModel) end)
    end
    local function danielAction(action) npcAction(action, workspace:FindFirstChild("NPC") and workspace.NPC:FindFirstChild("Daniel")) end
    local function sellAllFish()
        for _, fish in ipairs({"Bass", "Snapper", "Cod"}) do danielAction("SellAll_" .. fish); task.wait(0.5) end
    end
    local function autoSellLoop()
        while autoSellFish do
            sellAllFish(); Library:Notify("Auto-sold all fish!", 2)
            task.wait(Options.AutoSellDelay and Options.AutoSellDelay.Value or 60)
        end
    end
    local function buyAmmoPack()
        local npcFolder = workspace:FindFirstChild("NPC")
        if not npcFolder then return end
        danielAction("Buy_AmmoPack"); task.wait(0.3)
        for _, npcName in ipairs({"Flint", "Samuel1", "Drock2", "Silas", "Loded1"}) do
            local npc = npcFolder:FindFirstChild(npcName)
            if npc then npcAction("Buy_AmmoPack", npc); task.wait(0.2); npcAction("Buy_Ammo", npc); task.wait(0.2) end
        end
    end
    
    local function getNPCList()
        local list = {}
        local npcFolder = workspace:FindFirstChild("NPC")
        if npcFolder then for _, ch in pairs(npcFolder:GetChildren()) do if ch:IsA("Model") then table.insert(list, ch.Name) end end end
        table.sort(list); return list
    end
    local function getNPCModel(npcName)
        local npcFolder = workspace:FindFirstChild("NPC")
        return npcFolder and npcFolder:FindFirstChild(npcName)
    end
    local function teleportToNPC(npcName)
        local npc = getNPCModel(npcName)
        if not npc then Library:Notify("NPC not found: " .. npcName, 3); return end
        refreshCharacter()
        if humanoidRootPart then
            local pos; pcall(function() pos = npc:IsA("Model") and npc:GetPivot().Position or npc.Position end)
            if pos then smartTeleport(CFrame.new(pos + Vector3.new(0, 3, 0))); Library:Notify("Teleported to " .. npcName, 3) end
        end
    end
    
    -- --- ProximityPrompt: fire helpers + radius scanner (true IIFE — separate prototype; avoids PARSER_LOCAL_LIMIT) ---
    local safeFireProximityPrompt, firePromptsUnderInstanceOnly, patchAndFirePromptsOnInstance
    local spamPrompt, waitForPrompt, fireAllPrompts
    local _isChestProximityPrompt
    local fentiRadiusPromptStop = false
    (function()
    -- rawget(_G, …) so a rename/minify pass cannot break the native prompt API name.
    local function fentiTryGlobalFireProximityPrompt(p)
        local fpp = rawget(_G, "fireproximityprompt")
        if type(fpp) ~= "function" then return end
        pcall(fpp, p)
        pcall(fpp, p, 0)
    end
    local function sfp(prompt)
        if not prompt or not prompt:IsA("ProximityPrompt") then return false end
    
        local oldHold = prompt.HoldDuration
        local oldMax = prompt.MaxActivationDistance
        local oldEnabled = prompt.Enabled
        local oldLos = prompt.RequiresLineOfSight
        pcall(function()
            prompt.HoldDuration = 0
            prompt.MaxActivationDistance = math.min(FENTI_PROMPT_MAX_STRETCH, math.max(oldMax > 0.05 and oldMax or 10, 18))
            prompt.Enabled = true
            prompt.RequiresLineOfSight = false
        end)
        task.wait(0.02)
    
        local ok = false
        local function tryTriggeredConns()
            if typeof(getconnections) ~= "function" then return false end
            local any = false
            pcall(function()
                for _, conn in pairs(getconnections(prompt.Triggered)) do
                    if conn.Fire then pcall(function() conn:Fire(player) end); any = true end
                end
            end)
            return any
        end
        local function tryFireSignal()
            if typeof(firesignal) ~= "function" then return false end
            pcall(function() firesignal(prompt.Triggered, player) end)
            return true
        end
        local function tryNativeHold(short)
            pcall(function()
                prompt:InputHoldBegin()
                task.wait(short and 0.02 or 0.28)
                prompt:InputHoldEnd()
            end)
            return true
        end
    
        fentiTryGlobalFireProximityPrompt(prompt)
        if tryTriggeredConns() then ok = true end
        if not ok and tryFireSignal() then ok = true end
        if not ok then tryNativeHold(_isXeno or not Support.Proximity) end
    
        task.delay(0.5, function()
            pcall(function()
                prompt.HoldDuration = oldHold
                prompt.MaxActivationDistance = oldMax
                prompt.Enabled = oldEnabled
                prompt.RequiresLineOfSight = oldLos
            end)
        end)
        return true
    end
    
    -- Radius-only proximity assist (replaces workspace-wide instant prompts — avoids lag)
    local FENTI_RADIUS_CHEST_CORPSE_SAINTS_HORSE = 25
    -- Insta-prompt: parts under workspace.saints.Entities are often >25 studs from you until TP; slightly looser.
    local FENTI_RADIUS_SAINTS_INSTA = 38
    local FENTI_RADIUS_HORSE = 42
    -- Insta / radius prompts: aggressive multi-path burst (native + Triggered hooks + hold shim); one delayed property restore.
    local FENTI_INSTA_PROMPT_STRETCH = 62
    local function fentiFireProximityMinimal(prompt)
        if not prompt or not prompt:IsA("ProximityPrompt") then return end
        local oldHold, oldMax, oldEnabled, oldLos
        pcall(function()
            oldHold = prompt.HoldDuration
            oldMax = prompt.MaxActivationDistance
            oldEnabled = prompt.Enabled
            oldLos = prompt.RequiresLineOfSight
            prompt.HoldDuration = 0
            prompt.RequiresLineOfSight = false
            prompt.Enabled = true
            local m = oldMax > 0.05 and oldMax or 10
            prompt.MaxActivationDistance = math.min(FENTI_INSTA_PROMPT_STRETCH, math.max(m, 24))
        end)
        local function burstNative()
            fentiTryGlobalFireProximityPrompt(prompt)
        end
        burstNative()
        if typeof(getconnections) == "function" then
            pcall(function()
                for _, conn in pairs(getconnections(prompt.Triggered)) do
                    if conn.Fire then pcall(function() conn:Fire(player) end) end
                end
            end)
        end
        if typeof(firesignal) == "function" then
            pcall(function() firesignal(prompt.Triggered, player) end)
        end
        pcall(function()
            prompt:InputHoldBegin()
        end)
        task.defer(function()
            pcall(function() prompt:InputHoldEnd() end)
            burstNative()
            if typeof(getconnections) == "function" then
                pcall(function()
                    for _, conn in pairs(getconnections(prompt.Triggered)) do
                        if conn.Fire then pcall(function() conn:Fire(player) end) end
                    end
                end)
            end
        end)
        task.delay(0.04, function()
            if not prompt.Parent then return end
            burstNative()
            pcall(function()
                prompt:InputHoldBegin()
            end)
            task.defer(function()
                pcall(function() prompt:InputHoldEnd() end)
            end)
        end)
        task.delay(0.42, function()
            pcall(function()
                if not prompt.Parent then return end
                prompt.HoldDuration = oldHold
                prompt.MaxActivationDistance = oldMax
                prompt.Enabled = oldEnabled
                prompt.RequiresLineOfSight = oldLos
            end)
        end)
    end
    _G.fentiFireProximityMinimal = fentiFireProximityMinimal
    local function fentiGetChestFolderRoots()
        local roots = {}
        local function add(folder)
            if folder and folder.Parent then roots[#roots + 1] = folder end
        end
        add(workspace:FindFirstChild("Chests"))
        add(workspace:FindFirstChild("chests"))
        local map = workspace:FindFirstChild("Map")
        if map then
            add(map:FindFirstChild("Chests"))
            add(map:FindFirstChild("chests"))
        end
        local entities = workspace:FindFirstChild("Entities")
        if entities then
            add(entities:FindFirstChild("Chests"))
            add(entities:FindFirstChild("chests"))
        end
        return roots
    end
    -- Chest reel (fishing): AutoCollect loop is off while isRunning — spam prompts when NotificationEvent says chest.
    _G.fentiSpamNearbyChestPrompts = function(radius, rounds, delayBetween)
        radius = radius or 58
        rounds = rounds or 22
        delayBetween = delayBetween or 0.065
        task.spawn(function()
            local plr = Players.LocalPlayer
            for _ = 1, rounds do
                if not plr then break end
                pcall(function()
                    local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                    if not root then return end
                    local rp = root.Position
                    local r2 = radius * radius
                    for _, chests in ipairs(fentiGetChestFolderRoots()) do
                        for _, box in ipairs(chests:GetChildren()) do
                            if box.Parent then
                                local part = box:IsA("BasePart") and box or (box.PrimaryPart or box:FindFirstChildWhichIsA("BasePart"))
                                if part then
                                    local d = part.Position - rp
                                    if d:Dot(d) <= r2 then
                                        local prompt = box:FindFirstChildWhichIsA("ProximityPrompt", true)
                                        if prompt then
                                            pcall(function() fentiFireProximityMinimal(prompt) end)
                                            pcall(function() fentiFireProximityMinimal(prompt) end)
                                            pcall(function() sfp(prompt) end)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end)
                task.wait(delayBetween)
            end
        end)
    end
    -- Deferred multi-burst — instant-prompt radius tick stays light; violence runs next frames.
    local function fentiDeferSafeProximityFire(prompt)
        if not prompt or not prompt:IsA("ProximityPrompt") then return end
        local p = prompt
        task.defer(function()
            pcall(function() fentiFireProximityMinimal(p) end)
        end)
        task.defer(function()
            pcall(function() sfp(p) end)
        end)
        task.delay(0.03, function()
            pcall(function() fentiFireProximityMinimal(p) end)
        end)
    end
    local function ichest(prompt)
        if not prompt or not prompt:IsA("ProximityPrompt") then return false end
        local p = prompt.Parent
        while p and p ~= game do
            if p.Name == "ChestBox" then return true end
            p = p.Parent
        end
        return false
    end
    local function fentiRadiusProximityTick()
        if fentiRadiusPromptStop then return end
        if not Toggles then return end
        local lp = Players.LocalPlayer
        local char = lp.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        -- Fishing cast: avoid workspace scans the same window the client is spawning the line/bobber (major stutter fix).
        if isRunning then
            local lc = rawget(_G, "fentiLastCastClock")
            if type(lc) == "number" and (os.clock() - lc) < 0.78 then
                return
            end
        end
    
        local rZone = FENTI_RADIUS_CHEST_CORPSE_SAINTS_HORSE
        -- Chest walk-up: handled by _G.AutoCollect loop (radius 25, interval 0.25) — not here (avoids double-firing with sfp-style ticks).
    
        if Toggles.InstantPromptCorpse and Toggles.InstantPromptCorpse.Value then
            local folder = workspace:FindFirstChild("CorpseSpawns")
            if folder then
                for _, spawn in ipairs(folder:GetChildren()) do
                    if spawn.Name == "CorpseSpawn" then
                        local part = spawn:IsA("BasePart") and spawn or spawn:FindFirstChildWhichIsA("BasePart")
                        if part and (part.Position - root.Position).Magnitude <= rZone then
                            local prompt = spawn:FindFirstChildWhichIsA("ProximityPrompt", true)
                            if prompt then fentiDeferSafeProximityFire(prompt) end
                        end
                    end
                end
            end
            local corpseParts = workspace:FindFirstChild("CorpseParts")
            if corpseParts then
                for _, p in ipairs(corpseParts:GetChildren()) do
                    if p:IsA("BasePart") and fentiSaintsPartEligible(p.Name) and (p.Position - root.Position).Magnitude <= rZone then
                        local prompt = p:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt then fentiDeferSafeProximityFire(prompt) end
                    end
                end
            end
        end
    
        if saintsEnabled and Toggles.InstantPromptSaints and Toggles.InstantPromptSaints.Value then
            local rSaints = FENTI_RADIUS_SAINTS_INSTA
            local nearParts = {}
            local function pushIfSaintPart(ch)
                if ch:IsA("BasePart") and fentiSaintsPartEligible(ch.Name) and (ch.Position - root.Position).Magnitude <= rSaints then
                    table.insert(nearParts, ch)
                end
            end
            for _, ch in ipairs(workspace:GetChildren()) do
                pushIfSaintPart(ch)
            end
            local saintsFolder = workspace:FindFirstChild("saints")
            if saintsFolder then
                local ents = saintsFolder:FindFirstChild("Entities")
                if ents then
                    for _, folder in ipairs(ents:GetChildren()) do
                        if folder.Name ~= lp.Name and folder.Name ~= lp.DisplayName and folder.Name ~= tostring(lp.UserId) then
                            for _, ch in ipairs(folder:GetChildren()) do
                                if ch:IsA("BasePart") then
                                    pushIfSaintPart(ch)
                                elseif ch:IsA("Model") then
                                    local bp = ch.PrimaryPart or ch:FindFirstChildWhichIsA("BasePart")
                                    if bp then pushIfSaintPart(bp) end
                                end
                            end
                        end
                    end
                end
            end
            if #nearParts > 0 then
                local now = tick()
                local nextPatch = rawget(_G, "fentiSaintsInstaPatchNext") or 0
                if now >= nextPatch then
                    _G.fentiSaintsInstaPatchNext = now + 0.7
                    pcall(function() patchNearbyPrompts(root.Position, rSaints + 28) end)
                end
                for _, ch in ipairs(nearParts) do
                    local prompt = ch:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt then fentiDeferSafeProximityFire(prompt) end
                end
            end
        end
    
        if Toggles.InstantPromptHorse and Toggles.InstantPromptHorse.Value then
            local hR = FENTI_RADIUS_HORSE
            local owned = getPlayerHorse()
            if owned then
                local hp = owned.PrimaryPart or owned:FindFirstChildWhichIsA("BasePart")
                if hp and (hp.Position - root.Position).Magnitude <= hR then
                    for _, d in ipairs(owned:GetDescendants()) do
                        if d:IsA("ProximityPrompt") then fentiDeferSafeProximityFire(d) end
                    end
                end
            end
            for _, m in ipairs(workspace:GetChildren()) do
                if m:IsA("Model") and m ~= owned and string.find(string.lower(m.Name), "horse", 1, true) then
                    local part = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
                    if part and (part.Position - root.Position).Magnitude <= hR then
                        local prompt = m:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt then fentiDeferSafeProximityFire(prompt) end
                    end
                end
            end
        end
    end
    task.defer(function()
        while not fentiRadiusPromptStop do
            task.wait(isRunning and 0.42 or 0.32)
            pcall(fentiRadiusProximityTick)
        end
    end)
    
    -- AutoCollect: chest walk-up — also runs while fishing (slower interval) so reeled-in chests can open without stopping the bot.
    task.defer(function()
        local radius = 48
        while true do
            local interval = (isRunning and 0.38) or 0.24
            task.wait(interval)
            if _G.AutoCollect then
                pcall(function()
                    if isRunning then
                        local lc = rawget(_G, "fentiLastCastClock")
                        if type(lc) == "number" and (os.clock() - lc) < 0.78 then return end
                    end
                    local plr = Players.LocalPlayer
                    pcall(function() if cloneref then plr = cloneref(plr) end end)
                    local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                    if not root then return end
                    local rootsChest = fentiGetChestFolderRoots()
                    if #rootsChest == 0 then return end
                    for _, chests in ipairs(rootsChest) do
                        for _, box in ipairs(chests:GetChildren()) do
                            if not _G.AutoCollect then break end
                            if box.Parent then
                                local part = box:IsA("BasePart") and box or (box.PrimaryPart or box:FindFirstChildWhichIsA("BasePart"))
                                if part and (part.Position - root.Position).Magnitude <= radius then
                                    local prompt = box:FindFirstChildWhichIsA("ProximityPrompt", true)
                                    if prompt then
                                        pcall(function() fentiFireProximityMinimal(prompt) end)
                                        if isRunning then
                                            pcall(function() fentiFireProximityMinimal(prompt) end)
                                        else
                                            pcall(function() sfp(prompt) end)
                                        end
                                        task.wait(isRunning and 0.06 or 0.1)
                                    end
                                end
                            end
                        end
                    end
                end)
            end
        end
    end)
    
    local function fpui(inst, _logPrefix, delayBetween)
        delayBetween = delayBetween or 0.15
        if not inst or not inst.Parent then return 0 end
        refreshCharacter()
        local fired = 0
        pcall(function()
            for _, d in pairs(inst:GetDescendants()) do
                if d:IsA("ProximityPrompt") and fentiShouldAttemptPromptFire(humanoidRootPart, d, 120) then
                    sfp(d)
                    fired = fired + 1
                    task.wait(delayBetween)
                end
            end
        end)
        return fired
    end
    
    local function paf(inst, _logPrefix, delayBetween)
        delayBetween = delayBetween or 0.22
        if not inst or not inst.Parent then return 0 end
        refreshCharacter()
        local pos
        pcall(function()
            if inst:IsA("BasePart") then pos = inst.Position
            elseif inst:IsA("Model") then pos = inst:GetPivot().Position end
        end)
        if pos then patchNearbyPrompts(pos, 70) end
        local fired = 0
        pcall(function()
            for _, d in pairs(inst:GetDescendants()) do
                if d:IsA("ProximityPrompt") and fentiShouldAttemptPromptFire(humanoidRootPart, d, 120) then
                    sfp(d)
                    fired = fired + 1
                    task.wait(delayBetween)
                end
            end
        end)
        return fired
    end
    
    local function spm(prompt, times, delay)
        times = times or 5; delay = delay or 0.15
        for _ = 1, times do
            sfp(prompt)
            task.wait(delay)
        end
    end
    
    local function wfp(instance, timeout)
        timeout = timeout or 5
        local prompt = instance:FindFirstChildOfClass("ProximityPrompt")
        if prompt then pcall(function()
            prompt.HoldDuration = 0
            local m = prompt.MaxActivationDistance
            prompt.MaxActivationDistance = math.min(FENTI_PROMPT_MAX_STRETCH, math.max(m > 0.05 and m or 10, 18))
            prompt.Enabled = true
        end); return prompt end
        for _, desc in pairs(instance:GetDescendants()) do
            if desc:IsA("ProximityPrompt") then pcall(function()
                desc.HoldDuration = 0
                local m = desc.MaxActivationDistance
                desc.MaxActivationDistance = math.min(FENTI_PROMPT_MAX_STRETCH, math.max(m > 0.05 and m or 10, 18))
                desc.Enabled = true
            end); return desc end
        end
        local t0 = os.clock()
        local found = nil
        local conn
        conn = instance.DescendantAdded:Connect(function(desc)
            if desc:IsA("ProximityPrompt") then found = desc; if conn then conn:Disconnect() end end
        end)
        while not found and (os.clock() - t0) < timeout do task.wait(0.1) end
        if conn then conn:Disconnect() end
        return found
    end
    
    local function fap(instance, retries)
        retries = retries or 3
        local fired = false
        for _ = 1, retries do
            for _, desc in pairs(instance:GetDescendants()) do
                if desc:IsA("ProximityPrompt") then
                    spm(desc, 3, 0.1)
                    fired = true
                end
            end
            if fired then break end
            task.wait(0.5)
        end
        return fired
    end
    
    safeFireProximityPrompt = sfp
    firePromptsUnderInstanceOnly = fpui
    patchAndFirePromptsOnInstance = paf
    spamPrompt = spm
    waitForPrompt = wfp
    fireAllPrompts = fap
    _isChestProximityPrompt = ichest
    end)()
    
    do
    (function()
        local function openBank()
            local banker = getNPCModel("Banker")
            if not banker then Library:Notify("Banker NPC not found!", 3); return end
            teleportToNPC("Banker"); task.wait(0.5)
            local promptFired = fireAllPrompts(banker)
            if not promptFired and DialogueRemote then
                pcall(function() DialogueRemote:FireServer("Open", {["Start"] = {["Choices"] = {[1] = {["ServerAction"] = "OpenBank", ["Text"] = "Open Storage"}, [2] = {["Quit"] = true, ["Text"] = "Nevermind."}}, ["Text"] = "Need to stash something safely?"}}, banker, 15, "Start") end)
                task.wait(0.3)
                pcall(function() DialogueRemote:FireServer("Action", "OpenBank", banker) end)
            end
            local openStorageRemote = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("OpenStorageUI")
            if openStorageRemote then pcall(function() openStorageRemote:FireServer() end) end
        end
        local function talkToNPC(npcName)
            local npc = getNPCModel(npcName)
            if not npc then Library:Notify("NPC not found: " .. npcName, 3); return end
            teleportToNPC(npcName); task.wait(0.5)
            if fireAllPrompts(npc) then Library:Notify("Interacted with " .. npcName, 3); return end
            if DialogueRemote then
                pcall(function() DialogueRemote:FireServer("Talk", npcName, npc) end); task.wait(0.2)
                pcall(function() DialogueRemote:FireServer("Open", nil, npc, 15, "Start") end); task.wait(0.2)
                pcall(function() DialogueRemote:FireServer("Action", "Talk", npc) end)
                Library:Notify("Sent dialogue to " .. npcName, 3)
            end
        end
        _G.fentiOpenBank = openBank
        _G.fentiTalkToNPC = talkToNPC
    end)()
    end
    
    -- ----------------------------------------------------------------------------
    -- [FENTI-16] 16. AUTO DIALOGUE (IIFE — own local register pool; avoids chunk limit ~200)
    -- ----------------------------------------------------------------------------
    do
    (function()
    local function getDialogueGui()
        return player:FindFirstChild("PlayerGui") and player.PlayerGui:FindFirstChild("DialogueGui")
    end
    local function clickDialogueChoice(choiceNumber)
        local gui = getDialogueGui()
        if not gui then return end
        pcall(function()
            local choice = gui.MainFrame.ChoiceList:FindFirstChild("Choice_" .. choiceNumber)
            if choice then
                local button = choice:IsA("TextButton") and choice or choice:FindFirstChildOfClass("TextButton")
                if button then
                    if Support.Connections then
                        for _, conn in pairs(getconnections(button.MouseButton1Click)) do
                            if conn.Fire then conn:Fire() elseif conn.Function then task.spawn(conn.Function) end
                        end
                    else pcall(function() firesignal(button.MouseButton1Click) end) end
                end
            end
        end)
    end
    local function instaDialogNPC(npcName)
        local npc = getNPCModel(npcName)
        if not npc then Library:Notify("NPC not found: " .. tostring(npcName), 3); return end
        if not DialogueRemote then Library:Notify("DialogueRemote missing!", 3); return end
        refreshCharacter()
        pcall(function()
            DialogueRemote:FireServer("Talk", npcName, npc)
            DialogueRemote:FireServer("Open", nil, npc, 15, "Start")
            DialogueRemote:FireServer("Action", "Talk", npc)
        end)
        task.spawn(function()
            for _ = 1, 10 do
                clickDialogueChoice(1)
                task.wait(0.05)
            end
        end)
        Library:Notify("Insta dialog → " .. npcName, 2)
    end
    local function dialogueHasBracket()
        local gui = getDialogueGui()
        if not gui then return false end
        local npcText = gui.MainFrame:FindFirstChild("NPCText")
        return npcText and (npcText.Text:find("【") or npcText.Text:find("「")) or false
    end
    local function getDialogueText()
        local gui = getDialogueGui()
        if not gui then return "" end
        local npcText = gui.MainFrame:FindFirstChild("NPCText")
        return npcText and npcText.Text or ""
    end
    local function startAutoDialogue()
        if dialogueConnection then dialogueConnection:Disconnect() end
        rerollCount = 0
        local dlgSkip = 0
        dialogueConnection = RunService.Heartbeat:Connect(function()
            if not autoDialogueEnabled then return end
            dlgSkip = dlgSkip + 1; if dlgSkip < 5 then return end; dlgSkip = 0
            if dialogueHasBracket() then
                clickDialogueChoice(1); autoDialogueEnabled = false
                if dialogueConnection then dialogueConnection:Disconnect(); dialogueConnection = nil end
                Library:Notify("Got rare result after " .. rerollCount .. " rerolls!\n" .. getDialogueText():sub(1, 80), 8)
                if Toggles.AutoDialogue then Toggles.AutoDialogue:SetValue(false) end
                if Labels.Reroll then Labels.Reroll:SetText("Rerolls: " .. rerollCount .. " (FOUND!)") end
            else
                clickDialogueChoice(2); rerollCount = rerollCount + 1
                if Labels.Reroll then Labels.Reroll:SetText("Rerolls: " .. rerollCount) end
            end
            task.wait(0.5)
        end)
    end
    local function stopAutoDialogue()
        autoDialogueEnabled = false
        if dialogueConnection then dialogueConnection:Disconnect(); dialogueConnection = nil end
    end
    _G.fentiDialogue = {
        instaDialogNPC = instaDialogNPC,
        startAutoDialogue = startAutoDialogue,
        stopAutoDialogue = stopAutoDialogue,
    }
    end)()
    end
    
    -- ----------------------------------------------------------------------------
    -- [FENTI-17] 17. FISHING SYSTEM (IIFE — own local register pool; avoids chunk limit ~200)
    -- ----------------------------------------------------------------------------
    _G.fentiFish = (function()
    local function getUseToolRemote()
        if remote and remote.Parent then return remote end
        local Rm = RS:FindFirstChild("Remotes")
        return Rm and Rm:FindFirstChild("UseTool")
    end
    local function getQTERemote()
        local ev = RS:FindFirstChild("QTEEvent")
        if ev and ev.Parent then return ev end
        local Rm = RS:FindFirstChild("Remotes")
        if Rm then
            ev = Rm:FindFirstChild("QTEEvent")
            if ev and ev.Parent then return ev end
        end
        return RS:FindFirstChild("QTEEvent", true)
    end
    local function fishDbg(msg)
        msg = tostring(msg)
        banLog("FISH", msg)
        if rawget(_G, "FENTI_FISH_DEBUG") == true then warn("[fenti-fish] " .. msg) end
    end
    local function hasBait()
        local bp = player:FindFirstChild("Backpack")
        return (bp and bp:FindFirstChild("Bait")) or (player.Character and player.Character:FindFirstChild("Bait")) or false
    end
    local function hasFishingRod()
        local bp = player:FindFirstChild("Backpack")
        return (bp and bp:FindFirstChild("FishingRod")) or (player.Character and player.Character:FindFirstChild("FishingRod")) or false
    end
    -- softOnly: if FishingRod is already the equipped tool, do nothing (avoids EquipTool flicker every “catch” cycle).
    local function ensureFishingRodEquipped(softOnly)
        softOnly = softOnly == true
        if not character or not character.Parent or not humanoidRootPart or not humanoidRootPart.Parent then
            refreshCharacter()
        end
        if not character then return end
        local hum = character:FindFirstChildOfClass("Humanoid")
        local equipped = nil
        pcall(function()
            equipped = hum and hum:GetEquippedTool()
        end)
        if softOnly and equipped and equipped.Name == "FishingRod" then return end
        local backpack = player:FindFirstChild("Backpack")
        local rod = character:FindFirstChild("FishingRod")
        if not rod and backpack then rod = backpack:FindFirstChild("FishingRod") end
        if not rod then return end
        if equipped == rod then return end
        if rod.Parent ~= character then
            rod.Parent = character
            if isRunning then
                task.wait()
            else
                task.wait(0.04)
            end
        end
        -- Always EquipTool — rod can be under Character but not actually equipped after a catch/reel (broke 2nd+ casts).
        if hum then pcall(function() hum:EquipTool(rod) end) end
        if isRunning then
            task.wait()
        else
            task.wait(0.03)
        end
    end
    local function useBaitIfEnabled()
        if not useBait then return end
        if not character or not character.Parent or not humanoidRootPart then
            refreshCharacter()
        end
        local backpack = player:FindFirstChild("Backpack")
        if not backpack or not character then return end
        if not hasBait() and autoBuyBait then
            danielAction("Buy_Bait_15")
            task.wait(0.45)
        end
        local baitTool = backpack:FindFirstChild("Bait")
        if not baitTool then return end
        local hum = character:FindFirstChildOfClass("Humanoid")
        local prevTool = character:FindFirstChildWhichIsA("Tool")
        local usedClick = false
        baitTool.Parent = character
        task.wait(0.03)
        if baitTool:FindFirstChild("Handle") then
            local cd = baitTool.Handle:FindFirstChildOfClass("ClickDetector")
            if cd and fireclickdetector then pcall(fireclickdetector, cd); usedClick = true; task.wait(0.06) end
        end
        if not usedClick and hum and baitTool.Parent == character then
            pcall(function()
                hum:EquipTool(baitTool)
                task.wait(0.03)
                baitTool:Activate()
                task.wait(0.04)
            end)
        end
        baitTool.Parent = backpack
        task.wait(0.03)
        local rod = backpack:FindFirstChild("FishingRod")
        if rod and hum then
            pcall(function() hum:EquipTool(rod) end)
        elseif prevTool and prevTool.Parent == backpack and hum then
            pcall(function() hum:EquipTool(prevTool) end)
        end
        task.wait(0.03)
    end

    -- Long cast (camera cone + 60–100 studs) — optional alt; short cast is default (less stall after FireServer).
    local function getRandomVector()
        local holdCF = rawget(_G, "fentiFishingHoldCF")
        if not character or not character.Parent or not humanoidRootPart then
            refreshCharacter()
        end
        if not humanoidRootPart and typeof(holdCF) ~= "CFrame" then return Vector3.zero end
        local playerPos = (typeof(holdCF) == "CFrame" and holdCF.Position) or humanoidRootPart.Position
        local camera = workspace.CurrentCamera
        local cameraDirection = (camera and camera.CFrame.LookVector)
            or (typeof(holdCF) == "CFrame" and holdCF.LookVector)
            or (humanoidRootPart and humanoidRootPart.CFrame.LookVector)
            or Vector3.new(0, 0, -1)
        local spreadAngle = math.rad(30)
        local randomAngle1 = (math.random() - 0.5) * spreadAngle
        local randomAngle2 = (math.random() - 0.5) * spreadAngle
        local rotatedDirection = (CFrame.new(Vector3.zero, cameraDirection) * CFrame.Angles(randomAngle1, randomAngle2, 0)).LookVector
        local throwDistance = math.random(60, 100)
        return playerPos + rotatedDirection * throwDistance
    end
    -- Working-game pattern: HRP forward ~20 studs (optional alt cast).
    local function getShortCastAim()
        if humanoidRootPart then
            return (humanoidRootPart.CFrame * CFrame.new(0, 0, -20)).Position
        end
        local holdCF = rawget(_G, "fentiFishingHoldCF")
        if typeof(holdCF) == "CFrame" then
            return (holdCF * CFrame.new(0, 0, -20)).Position
        end
        return Vector3.zero
    end
    -- Fishing Bot v4 / bridgewestern style: HRP facing, 15° spread, 60–100 studs, slight Y jitter (matches working cast).
    local function legacyGetRandomVector()
        if not character or not character.Parent or not humanoidRootPart then
            refreshCharacter()
        end
        local holdCF = rawget(_G, "fentiFishingHoldCF")
        local pos = (humanoidRootPart and humanoidRootPart.Position)
            or (typeof(holdCF) == "CFrame" and holdCF.Position)
        if not pos then return Vector3.zero end
        local facing = (humanoidRootPart and humanoidRootPart.CFrame.LookVector)
            or (typeof(holdCF) == "CFrame" and holdCF.LookVector)
            or Vector3.new(0, 0, -1)
        local spread = math.rad(15)
        local dir = (CFrame.new(Vector3.zero, facing) * CFrame.Angles(math.random() * spread * 0.5, (math.random() - 0.5) * spread * 2, 0)).LookVector
        local dist = math.random(60, 100)
        local target = pos + dir * dist
        return Vector3.new(target.X, pos.Y - math.random(1, 5), target.Z)
    end
    -- Keep spring constraints off briefly after Primary so AlignPosition does not fight the new line/bobber (fixes 2nd+ cast “no bobber” loops).
    local function fentiArmCastPhysicsFreeWindow(duration)
        duration = duration or 0.55
        _G.fentiLastCastClock = os.clock()
        _G.fentiCastPhysicsSeq = (rawget(_G, "fentiCastPhysicsSeq") or 0) + 1
        local seq = _G.fentiCastPhysicsSeq
        _G.fentiCastingUnanchor = true
        pcall(function() if humanoidRootPart then humanoidRootPart.Anchored = false end end)
        task.delay(duration, function()
            if rawget(_G, "fentiCastPhysicsSeq") ~= seq then return end
            _G.fentiCastingUnanchor = nil
        end)
    end
    -- Cast: bait + 0.3s pause, then camera cone 60–100 studs (low hitch vs short HRP-only cast).
    local function castRod()
        if Labels.Status then Labels.Status:SetText("Status: Casting...") end
        if not character or not character.Parent or not humanoidRootPart then
            refreshCharacter()
        end
        if not humanoidRootPart then return nil end
        ensureFishingRodEquipped()
        if not humanoidRootPart then return nil end
        useBaitIfEnabled()
        task.wait(0.3)
        local r = getUseToolRemote()
        if not r then warn("[fenti] Remotes.UseTool missing"); return nil end
        local aim = getRandomVector()
        if aim == Vector3.zero then return nil end
        local throwLen = (aim - humanoidRootPart.Position).Magnitude
        if throwLen < 8 or throwLen > 500 then return nil end
        r:FireServer("FishingRod", "Primary", aim)
        fentiArmCastPhysicsFreeWindow(0.55)
        return aim
    end
    -- Alt: long cast if bobber keeps missing (unchanged aim style).
    local function castRodLong()
        if not character or not character.Parent or not humanoidRootPart then
            refreshCharacter()
        end
        if not humanoidRootPart and typeof(rawget(_G, "fentiFishingHoldCF")) ~= "CFrame" then return nil end
        ensureFishingRodEquipped()
        if not humanoidRootPart and typeof(rawget(_G, "fentiFishingHoldCF")) ~= "CFrame" then return nil end
        local r = getUseToolRemote()
        if not r then return nil end
        local aim = getRandomVector()
        local rootPos = humanoidRootPart and humanoidRootPart.Position
            or (typeof(rawget(_G, "fentiFishingHoldCF")) == "CFrame" and rawget(_G, "fentiFishingHoldCF").Position)
        if not rootPos then return nil end
        local throwLen = (aim - rootPos).Magnitude
        if throwLen < 8 or throwLen > 500 then return nil end
        r:FireServer("FishingRod", "Primary", aim)
        fentiArmCastPhysicsFreeWindow(0.6)
        return aim
    end
    -- Same short aim as default cast (retry / parity with AutoFish3).
    local function castRodForwardShort()
        if not character or not character.Parent or not humanoidRootPart then
            refreshCharacter()
        end
        if not humanoidRootPart then return nil end
        ensureFishingRodEquipped()
        if not humanoidRootPart then return nil end
        local r = getUseToolRemote()
        if not r then return nil end
        local aim = (humanoidRootPart.CFrame * CFrame.new(0, 0, -20)).Position
        r:FireServer("FishingRod", "Primary", aim)
        fentiArmCastPhysicsFreeWindow(0.55)
        return aim
    end
    local function pickupRod()
        if Labels.Status then Labels.Status:SetText("Status: Picking up...") end
        local r = getUseToolRemote()
        if r then r:FireServer("FishingRod", "Primary") end
        fentiArmCastPhysicsFreeWindow(0.42)
        task.wait(0.25)
        ensureFishingRodEquipped()
    end

    -- Game client (decompiled): QTEEvent:FireServer("MashingSuccess"|"MashingFail") for mashing; "Success"|"Fail" for reaction circle.
    local function fentiMashingContainerVisible()
        local c = _G.fentiGetMashingContainer and _G.fentiGetMashingContainer()
        return c and c.Visible
    end
    local function fentiReactionCircleVisible()
        local ms = playerGui:FindFirstChild("MashingSystem") or (QTE.system and QTE.system.Parent and QTE.system)
        if not ms then return false end
        local rc = ms:FindFirstChild("ReactionCircle")
        return rc ~= nil and rc.Visible == true
    end

    -- Mashing UI visible (game started mashing QTE).
    local function handleQTE()
        if Labels.Status then Labels.Status:SetText("Status: QTE! …") end
        banLog("FISH", "QTE — FireServer(MashingSuccess)")
        refreshCharacter()
        local q = getQTERemote()
        if not humanoidRootPart or not q then return end
        _G.fentiSuppressFishHold = true
        pcall(function()
            pcall(function() q:FireServer("MashingSuccess") end)
            if Labels.Status then Labels.Status:SetText("Status: QTE passed (mashing)") end
            task.wait(3.5)
        end)
        _G.fentiSuppressFishHold = false
    end

    -- After bite: reel, wait for minigame UI; fallback MashingSuccess matches prior working hub (many catches need the remote even when UI is slow/missing).
    -- Do not set HumanoidRootPart.Anchored here — it causes a visible hitch and can desync/cancel the fishing line client-side.
    local function completeBiteMinigame()
        if Labels.Status then Labels.Status:SetText("Status: Bite — reel, wait minigame…") end
        fishDbg("completeBite: start (Primary reel → wait UI / QTE)")
        refreshCharacter()
        local r = getUseToolRemote()
        local q = getQTERemote()
        if not humanoidRootPart or not r then return end
        _G.fentiSuppressFishHold = true
        pcall(function() r:FireServer("FishingRod", "Primary") end)
        task.wait(0.15)
        local sent = false
        if q then
            local t0 = tick()
            while isRunning and (tick() - t0) < 5.5 do
                if fentiMashingContainerVisible() then
                    task.wait(0.08)
                    -- FENTI-17b auto-mash sends keys / MashingSuccess; duplicating here breaks the line for many games.
                    sent = true
                    if Labels.Status then Labels.Status:SetText("Status: Mashing — auto QTE") end
                    break
                end
                if fentiReactionCircleVisible() then
                    task.wait(0.12)
                    pcall(function() q:FireServer("Success") end)
                    sent = true
                    if Labels.Status then Labels.Status:SetText("Status: Reaction Success sent") end
                    break
                end
                task.wait(0.08)
            end
            -- Mashing UI without StartMashing (desync): auto never runs — single remote nudge.
            if sent and q and fentiMashingContainerVisible() then
                local w0 = tick()
                while not qteInProgress and (tick() - w0) < 0.85 do
                    task.wait(0.05)
                end
                if not qteInProgress and fentiMashingContainerVisible() then
                    pcall(function() q:FireServer("MashingSuccess") end)
                end
            end
            -- Game often needs this after reel even when mashing UI never shows; without it catches fail.
            if not sent then
                task.wait(0.15)
                pcall(function() q:FireServer("MashingSuccess") end)
                if Labels.Status then Labels.Status:SetText("Status: QTE fallback") end
            end
        end
        task.wait(1.35)
        -- Keep suppress until QTE auto finishes so spring/pose does not fight the line mid-mash.
        local qt0 = tick()
        while qteInProgress and isRunning and (tick() - qt0) < 22 do
            task.wait(0.05)
        end
        if isRunning then unlockRootMotion() end
        _G.fentiSuppressFishHold = false
        fentiArmCastPhysicsFreeWindow(0.4)
        fishDbg("completeBite: end")
    end

    local function legacyCastRod()
        if Labels.Status then Labels.Status:SetText("Status: Casting...") end
        if not character or not character.Parent or not humanoidRootPart then
            refreshCharacter()
        end
        if not humanoidRootPart then return end
        useBaitIfEnabled()
        ensureFishingRodEquipped()
        task.wait(0.3)
        local r = getUseToolRemote()
        if not r then
            warn("[fenti] Remotes.UseTool missing")
            return
        end
        r:FireServer("FishingRod", "Primary", legacyGetRandomVector())
        fentiArmCastPhysicsFreeWindow(0.55)
    end

    _G.fentiGetQTERemote = getQTERemote

    return {
        hasBait = hasBait,
        hasFishingRod = hasFishingRod,
        ensureFishingRodEquipped = ensureFishingRodEquipped,
        useBaitIfEnabled = useBaitIfEnabled,
        getRandomVector = getRandomVector,
        castRod = castRod,
        castRodLong = castRodLong,
        castRodForwardShort = castRodForwardShort,
        pickupRod = pickupRod,
        handleQTE = handleQTE,
        completeBiteMinigame = completeBiteMinigame,
        legacyCastRod = legacyCastRod,
        getQTERemote = getQTERemote,
        armCastPhysicsFreeWindow = fentiArmCastPhysicsFreeWindow,
        fishDbg = fishDbg,
    }
    end)()

    -- [FENTI-17·mash] MashingSystem container resolver (IIFE — register cap)
    do
    (function()
        _G.fentiGetMashingContainer = function()
            if QTE.container and QTE.container.Parent then return QTE.container end
            pcall(function()
                local ms = playerGui:FindFirstChild("MashingSystem")
                if ms then QTE.system = ms; QTE.container = ms:FindFirstChild("Container") end
            end)
            return QTE.container
        end
    end)()
    end

    do
    (function()
        -- Fishing bobber pick: no ownership / network checks — only looks-like-bobber heuristics (color, name, beam, prompt).

        -- Capped subtree walk — never GetDescendants() on workspace-sized trees (one call allocates the whole list).
        local function fentiScanPartForBobberHooks(part, maxNodes)
            maxNodes = maxNodes or 56
            local hasPrompt, hasBeam = false, false
            local n = 0
            local stack = { part }
            local si = 1
            while si <= #stack do
                local cur = stack[si]
                si = si + 1
                for _, ch in ipairs(cur:GetChildren()) do
                    n = n + 1
                    if n > maxNodes then return hasPrompt, hasBeam end
                    local cn = ch.ClassName
                    if cn == "ProximityPrompt" then hasPrompt = true end
                    if cn == "Beam" then hasBeam = true end
                    if hasPrompt and hasBeam then return true, true end
                    table.insert(stack, ch)
                end
            end
            return hasPrompt, hasBeam
        end

        local function fentiFindProximityPromptCapped(part, maxNodes)
            maxNodes = maxNodes or 72
            local n = 0
            local stack = { part }
            local si = 1
            while si <= #stack do
                local cur = stack[si]
                si = si + 1
                for _, ch in ipairs(cur:GetChildren()) do
                    n = n + 1
                    if n > maxNodes then return nil end
                    if ch:IsA("ProximityPrompt") and not _isChestProximityPrompt(ch) then return ch end
                    table.insert(stack, ch)
                end
            end
            return nil
        end

        _G.fentiScanPartForBobberHooks = fentiScanPartForBobberHooks
        _G.fentiFindProximityPromptCapped = fentiFindProximityPromptCapped
    end)()
    end

    -- [FENTI-17a] Fishing bobber / instaprompt (IIFE — register cap; skips chest prompts)
    do
    (function()
        local FENTI_FISH_BOBBER_RADIUS = 120
        -- Bite: armed Sound (ignore splash ~1.55s) + filter; ChildAdded + DescendantAdded; then completeBiteMinigame.
        local function waitForFishBite(fishingPart)
            if not fishingPart or not fishingPart.Parent then return false end
            local fishDbgLocal = type(_G.fentiFish.fishDbg) == "function" and _G.fentiFish.fishDbg or function() end
            local BITE_ARM_SEC = 1.55
            local timeout, startTime = 50, tick()
            local fishDone, biteStarted = false, false
            local soundConn, descConn
            local function disconnectSound()
                if soundConn and soundConn.Connected then soundConn:Disconnect() end
                if descConn and descConn.Connected then descConn:Disconnect() end
                soundConn, descConn = nil, nil
            end
            local function soundOkForBite(s)
                if not s or not s:IsA("Sound") then return false end
                if s.Volume <= 0 then return false end
                if s.Looped then
                    local tl = s.TimeLength
                    if type(tl) == "number" and tl > 90 then return false end
                end
                return true
            end
            local function beginBiteSequence()
                if biteStarted or not isRunning then return end
                biteStarted = true
                disconnectSound()
                task.spawn(function()
                    if Labels.Status then Labels.Status:SetText("Status: Bite — reel & QTE…") end
                    fishDbgLocal("waitBite: bite confirmed → completeBiteMinigame")
                    pcall(function() _G.fentiFish.completeBiteMinigame() end)
                    fishDone = true
                end)
            end
            local function scheduleBiteFromSound(snd)
                if not soundOkForBite(snd) then return end
                task.spawn(function()
                    while isRunning and fishingPart.Parent and not biteStarted and (tick() - startTime) < BITE_ARM_SEC do
                        task.wait(0.05)
                    end
                    if biteStarted or not isRunning or not fishingPart.Parent then return end
                    if not soundOkForBite(snd) then return end
                    if snd.Parent and snd:IsA("Sound") and snd.IsPlaying and soundOkForBite(snd) then
                        fishDbgLocal("waitBite: sound playing (post-arm)")
                        beginBiteSequence()
                        return
                    end
                    for _ = 1, 56 do
                        if biteStarted or not isRunning then return end
                        if not fishingPart.Parent then return end
                        if snd.Parent and snd:IsA("Sound") and snd.IsPlaying and soundOkForBite(snd) then
                            fishDbgLocal("waitBite: sound started (polled)")
                            beginBiteSequence()
                            return
                        end
                        task.wait(0.05)
                    end
                end)
            end
            fishDbgLocal("waitBite: listen ChildAdded+DescendantAdded on bobber")
            soundConn = fishingPart.ChildAdded:Connect(function(child)
                if child:IsA("Sound") then scheduleBiteFromSound(child) end
            end)
            descConn = fishingPart.DescendantAdded:Connect(function(child)
                if child:IsA("Sound") then scheduleBiteFromSound(child) end
            end)
            while isRunning and (tick() - startTime) < timeout do
                if fishDone then
                    disconnectSound()
                    return true
                end
                if not fishingPart.Parent then disconnectSound(); return false end
                task.wait(0.1)
            end
            disconnectSound()
            if Labels.Status and not fishDone then Labels.Status:SetText("Status: No bite (timeout)") end
            fishDbgLocal("waitBite: timeout fishDone=" .. tostring(fishDone))
            return fishDone
        end
        local function fireFishingBobberPrompt(fishingPart)
            if not fishingPart or not fishingPart.Parent then return false end
            local prompt = nil
            for _, child in pairs(fishingPart:GetDescendants()) do
                if child:IsA("ProximityPrompt") and not _isChestProximityPrompt(child) then
                    prompt = child
                    break
                end
            end
            if not prompt then return false end
            if type(safeFireProximityPrompt) == "function" then
                pcall(function() safeFireProximityPrompt(prompt) end)
                task.wait(0.45)
                return true
            end
            if _G.fentiFireProximityMinimal then _G.fentiFireProximityMinimal(prompt); task.wait(0.45); return true end
            return false
        end
        local function fentiFishingPromptAssistTick(anchorPosition)
            pcall(function()
                local lc = rawget(_G, "fentiLastCastClock")
                -- Stay off bobber/fish prompts until line lands (short gate caused stacked Primary / “triple cast” feel).
                if type(lc) == "number" and (os.clock() - lc) < 2.65 then return end
                local lp = Players.LocalPlayer
                pcall(function() if cloneref then lp = cloneref(lp) end end)
                local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                local center = anchorPosition or (hrp and hrp.Position)
                if not center then return end
                local castHint = rawget(_G, "fentiLastFishCastAim")
                local hintGateSq = nil
                if typeof(castHint) == "Vector3" and castHint.Magnitude > 1 then
                    hintGateSq = 70 * 70
                end
                local radius = FENTI_FISH_BOBBER_RADIUS
                local rSq = radius * radius
                local parts = {}
                local function pushBobber(p)
                    if p.Name ~= "Part" or not p:IsA("BasePart") then return end
                    local d = p.Position - center
                    local dsq = d:Dot(d)
                    if dsq <= rSq then table.insert(parts, { p = p, dsq = dsq }) end
                end
                for _, p in ipairs(workspace:GetChildren()) do
                    pushBobber(p)
                    if p:IsA("Folder") or p:IsA("Model") then
                        for _, c in ipairs(p:GetChildren()) do pushBobber(c) end
                    end
                end
                -- Closest Part that already looks "bobbed" (beam or fish prompt) — no ownership scan.
                local bestPr, bestDsq = nil, math.huge
                for _, e in ipairs(parts) do
                    local hasPr, hasBm = _G.fentiScanPartForBobberHooks(e.p, 48)
                    if hasPr or hasBm then
                        if hintGateSq then
                            local dh = e.p.Position - castHint
                            if dh:Dot(dh) > hintGateSq then
                                hasPr, hasBm = false, false
                            end
                        end
                        if hasPr or hasBm then
                            local pr = _G.fentiFindProximityPromptCapped(e.p, 96)
                            if pr and e.dsq < bestDsq then
                                bestPr, bestDsq = pr, e.dsq
                            end
                        end
                    end
                end
                if bestPr then
                    local g = rawget(_G, "fentiFishAssistCastGen") or 0
                    if rawget(_G, "fentiFishAssistFiredGen") == g then
                        return
                    end
                    _G.fentiFishAssistFiredGen = g
                    local pr = bestPr
                    task.defer(function()
                        pcall(function()
                            if type(safeFireProximityPrompt) == "function" then safeFireProximityPrompt(pr)
                            elseif _G.fentiFireProximityMinimal then _G.fentiFireProximityMinimal(pr) end
                        end)
                    end)
                end
            end)
        end
        _G.FENTI_FISH_BOBBER_RADIUS = FENTI_FISH_BOBBER_RADIUS
        _G.fentiFireFishingBobberPrompt = fireFishingBobberPrompt
        _G.fentiFishingPromptAssistTick = fentiFishingPromptAssistTick
        _G.fentiWaitForFishBite = waitForFishBite
    end)()
    end

    -- Prefer red bobber (~RGB 255,60,60), prompts, beam — avoid random workspace "Part" debris.
    -- castAimHint: world position where *this* cast targeted; avoids locking onto last cast's leftover bobber.
    -- deepScan: bounded BFS from workspace roots — never workspace:GetDescendants() (huge alloc + hitch).
    local function findBestFishingBobberPart(playerPos, maxDist, castAimHint, deepScan)
        if not playerPos then return nil end
        maxDist = maxDist or 100
        local maxSq = maxDist * maxDist
        local bestPart, bestScore = nil, -math.huge
        local hintSqGate = nil
        if typeof(castAimHint) == "Vector3" and castAimHint.Magnitude > 1 then
            hintSqGate = 70 * 70
        end
        local function consider(part)
            if not part:IsA("BasePart") then return end
            local c = part.Color
            local redBob = c.R > 0.78 and c.G < 0.5 and c.B < 0.5
            local namedPart = (part.Name == "Part" or part.Name == "Bobber" or string.lower(part.Name):find("bobber", 1, true))
            -- Generic "Part" with a huge subtree: skip before any descendant walk (was freezing on map geometry).
            if part.Name == "Part" and not redBob and #part:GetChildren() > 36 then return end
            local hookBudget = (redBob or namedPart) and 80 or 24
            local hasPrompt, hasBeam = _G.fentiScanPartForBobberHooks(part, hookBudget)
            local hasHook = hasPrompt or hasBeam
            if not namedPart and not (redBob and hasHook) then return end
            local d = part.Position - playerPos
            local dsq = d:Dot(d)
            if dsq > maxSq then return end
            local score = -dsq / 5000
            if redBob then score = score + 200 end
            if namedPart then score = score + 35 end
            if hasPrompt then score = score + 90 end
            if hasBeam then score = score + 55 end
            if typeof(castAimHint) == "Vector3" and castAimHint.Magnitude > 1 then
                local da = part.Position - castAimHint
                local adsq = da:Dot(da)
                score = score - adsq / 100
                if adsq < 55 * 55 then score = score + 320
                elseif adsq < hintSqGate then score = score + 140 end
            end
            if score > bestScore then bestScore, bestPart = score, part end
        end
        for _, ch in ipairs(workspace:GetChildren()) do
            if ch:IsA("BasePart") then consider(ch) end
            for _, c in ipairs(ch:GetChildren()) do
                if c:IsA("BasePart") then consider(c) end
            end
        end
        if deepScan and bestScore < 100 then
            local maxVisit = 1800
            local visited = 0
            local stack = {}
            for _, ch in ipairs(workspace:GetChildren()) do
                table.insert(stack, ch)
            end
            local si = 1
            while si <= #stack and visited < maxVisit do
                local inst = stack[si]
                si = si + 1
                visited = visited + 1
                if visited % 140 == 0 then task.wait() end
                if inst:IsA("BasePart") then consider(inst) end
                for _, c in ipairs(inst:GetChildren()) do
                    table.insert(stack, c)
                end
            end
        end
        return bestPart
    end

    -- Red bobber (~255,60,60) within range — same idea as AutoFish3.
    local function findRedBobberPartNear(playerPos, maxDist)
        if not playerPos then return nil end
        maxDist = maxDist or 100
        local maxSq = maxDist * maxDist
        local best, bestSq = nil, maxSq
        for _, p in ipairs(workspace:GetChildren()) do
            if p.Name == "Part" and p:IsA("BasePart") then
                local c = p.Color
                if c.R > 0.92 and c.G < 0.35 and c.B < 0.35 then
                    local d = p.Position - playerPos
                    local dsq = d:Dot(d)
                    if dsq <= maxSq and dsq < bestSq then
                        best, bestSq = p, dsq
                    end
                end
            end
        end
        return best
    end

    _G.fentiFishingLoop = function()
        refreshCharacter()
        if not humanoidRootPart then return end
        -- Drop stale velocity lock (e.g. after saints) — it used to arm when `isRunning` flipped true and froze fishing.
        unlockRootMotion()
        stopTPLoop()
        if _G.fentiStopFishingPoseHold then pcall(_G.fentiStopFishingPoseHold) end
        if autoBuyRod and not _G.fentiFish.hasFishingRod() then
            pcall(function() danielAction("Buy_FishingRod_150") end)
            task.wait(1.25)
        end
        refreshCharacter()
        if not humanoidRootPart then return end
        local anchorCF = humanoidRootPart.CFrame
        originalPosition = anchorCF.Position
        -- Stance is spring constraints only (see Heartbeat below).
        -- Pose lock while fishing (chest knockback). Released during cast / reel Primary via fentiCastingUnanchor + fentiSuppressFishHold.
        _G.fentiFishingHoldCF = anchorCF
        -- Hold spot snap off for whole auto-fish — resetting HRP during cast/wait cancels the line / UseTool.
        _G.fentiFishingNoSnap = true
        task.defer(function() banLog("FISH", "Fishing started") end)
        if _G.fentiFishingPoseHoldConn then pcall(function() _G.fentiFishingPoseHoldConn:Disconnect() end); _G.fentiFishingPoseHoldConn = nil end
        _G.fentiFishingPoseHoldConn = RunService.Heartbeat:Connect(function()
            local Pose = rawget(_G, "__fentiFishPose")
            if not Pose then return end
            if not isRunning then
                Pose.destroyRig()
                pcall(function()
                    local ch = player.Character
                    local r = ch and ch:FindFirstChild("HumanoidRootPart")
                    if r then r.Anchored = false end
                end)
                pcall(function()
                    local c = rawget(_G, "fentiFishingPoseHoldConn")
                    if c then c:Disconnect() end
                end)
                _G.fentiFishingPoseHoldConn = nil
                return
            end
            if rawget(_G, "fentiCastingUnanchor") or rawget(_G, "fentiSuppressFishHold") then
                Pose.setSpringOn(false)
                pcall(function()
                    local ch = player.Character
                    local r = ch and ch:FindFirstChild("HumanoidRootPart")
                    if r then r.Anchored = false end
                end)
                return
            end
            local hold = rawget(_G, "fentiFishingHoldCF")
            if typeof(hold) ~= "CFrame" then return end
            local ch = player.Character
            local root = ch and ch:FindFirstChild("HumanoidRootPart")
            if not root then return end
            pcall(function() root.Anchored = false end)
            local rig = Pose.ensureSpringRig(hold)
            Pose.attachSpring(root, rig)
            Pose.setSpringOn(true)
        end)
        if useBait then
            pcall(function() _G.fentiFish.useBaitIfEnabled() end)
        end
        local fishAssistStop = false
        task.spawn(function()
            local interval = 1.12
            while isRunning and not fishAssistStop do
                pcall(function() _G.fentiFishingPromptAssistTick(anchorCF.Position) end)
                task.wait(interval)
            end
        end)
        _G.fentiSuppressFishHold = false
        local castAttempts, castSuccesses = 0, 0
        local lastCastAim = nil
        local noBobberStreak = 0
        -- One FireServer("FishingRod","Primary", aim) per loop; then wait for bobber — no back-to-back casts.
        local FENTI_POST_CAST_SETTLE = 2.85
        while isRunning do
            castAttempts = castAttempts + 1
            _G.fentiFishAssistCastGen = (rawget(_G, "fentiFishAssistCastGen") or 0) + 1
            if not character or not character.Parent or not humanoidRootPart or not humanoidRootPart.Parent then
                refreshCharacter()
            end
            if noBobberStreak >= 4 then
                noBobberStreak = 0
                if Labels.Status then Labels.Status:SetText("Status: Long cast…") end
                pcall(function() _G.fentiFish.fishDbg("loop: long cast") end)
                lastCastAim = _G.fentiFish.castRodLong()
            else
                pcall(function() _G.fentiFish.fishDbg("loop: cast attempt #" .. castAttempts) end)
                lastCastAim = _G.fentiFish.castRod()
            end
            _G.fentiLastFishCastAim = lastCastAim
            task.wait(FENTI_POST_CAST_SETTLE)
            local playerPos = (humanoidRootPart and humanoidRootPart.Position) or anchorCF.Position
            local fishingPart = findRedBobberPartNear(playerPos, 100)
            if not fishingPart then
                fishingPart = findBestFishingBobberPart(playerPos, 130, lastCastAim, false)
            end
            if not fishingPart then
                task.wait(1.15)
                refreshCharacter()
                playerPos = (humanoidRootPart and humanoidRootPart.Position) or playerPos
                fishingPart = findBestFishingBobberPart(playerPos, 130, lastCastAim, true)
            end
            if fishingPart then
                noBobberStreak = 0
                castSuccesses = castSuccesses + 1
                if Labels.Status then Labels.Status:SetText("Status: Bobber found, waiting…") end
                pcall(function() _G.fentiFish.fishDbg("loop: bobber locked, waiting bite") end)
                if _G.fentiWaitForFishBite(fishingPart) then
                    if Labels.Status then Labels.Status:SetText("Status: Bite/QTE handled") end
                    pcall(function() _G.fentiFish.fishDbg("loop: bite+QTE path done — soft rod check only") end)
                    task.wait(0.4)
                    if not chestFarmEnabled and fireproximityprompt and humanoidRootPart then
                        local chestFolder = workspace:FindFirstChild("Chests")
                        if chestFolder then
                            for _, chest in ipairs(chestFolder:GetChildren()) do
                                if chest.Name == "ChestBox" then
                                    local chestPos
                                    pcall(function()
                                        if chest:IsA("Model") then chestPos = chest:GetPivot().Position
                                        elseif chest:IsA("BasePart") then chestPos = chest.Position end
                                    end)
                                    if chestPos and (chestPos - humanoidRootPart.Position).Magnitude <= 50 then
                                        for _, d in ipairs(chest:GetDescendants()) do
                                            if d:IsA("ProximityPrompt") then
                                                pcall(function() fireproximityprompt(d) end)
                                                task.wait(2)
                                                break
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                    task.wait(1.5)
                    pcall(function() _G.fentiFish.ensureFishingRodEquipped(true) end)
                else
                    if Labels.Status then Labels.Status:SetText("Status: No bite — reset line") end
                    _G.fentiFish.pickupRod()
                    task.wait(1)
                end
            else
                noBobberStreak = noBobberStreak + 1
                if Labels.Status then Labels.Status:SetText("Status: No bobber — pause before next cast") end
                task.wait(2.4)
            end
            if useBait then
                pcall(function() _G.fentiFish.useBaitIfEnabled() end)
            end
        end
        fishAssistStop = true
        if _G.fentiStopFishingPoseHold then pcall(_G.fentiStopFishingPoseHold) end
        banLog("FISH", "Fishing stopped — casts " .. castAttempts .. ", caught " .. fishCaught)
        if Labels.Status then Labels.Status:SetText("Status: Idle") end
        _G.fentiFishingNoSnap = nil
        _G.fentiFishAssistFiredGen = nil
        _G.fentiLastFishCastAim = nil
        stopTPLoop()
        unlockRootMotion()
    end

    -- [FENTI-17b] QTE auto-mash (IIFE — register cap)
    do
    (function()
        local function qteEv()
            local q = type(_G.fentiGetQTERemote) == "function" and _G.fentiGetQTERemote() or nil
            if q and q.Parent then return q end
            q = RS:FindFirstChild("QTEEvent")
            if q and q.Parent and (q:IsA("RemoteEvent") or q:IsA("UnreliableRemoteEvent")) then return q end
            local Rm = RS:FindFirstChild("Remotes")
            if Rm then
                q = Rm:FindFirstChild("QTEEvent")
                if q and q.Parent then return q end
            end
            return nil
        end
        local wiredQTE = setmetatable({}, { __mode = "k" })
        -- Game QTEHandler: InputBegan only counts mash when gameProcessedEvent is FALSE. 4th arg to SendKeyEvent is that flag — never pass `game` (truthy).
        local function simulateKey(keyCode)
            if not VIM then return false end
            local function send(isDown)
                local ok = pcall(function() VIM:SendKeyEvent(isDown, keyCode, false, false) end)
                if ok then return true end
                return pcall(function() VIM:SendKeyEvent(isDown, keyCode, false) end)
            end
            local a = send(true)
            task.wait(0.015)
            local b = send(false)
            return a or b
        end
        -- Mash QTE: map KeyLabel text → KeyCode (Xeno/Volt differ on names like Space).
        local function mashKeyFromFishLabel(txt)
            txt = tostring(txt or ""):gsub("%s+", ""):upper()
            if txt == "" or #txt > 14 then return nil end
            if txt == "SPACE" or txt == "SPACEBAR" then return Enum.KeyCode.Space end
            if txt == "ENTER" or txt == "RETURN" then return Enum.KeyCode.Return end
            local ok, kc = pcall(function() return Enum.KeyCode[txt] end)
            return ok and kc or nil
        end
        local function getCurrentMashKey()
            local container = _G.fentiGetMashingContainer()
            if not container or not container.Visible then return nil end
            local circle = container:FindFirstChild("Circle")
            if not circle then return nil end
            local kl = circle:FindFirstChild("KeyLabel")
            local txt = kl and kl.Text and kl.Text:gsub("%s+", ""):upper() or ""
            return mashKeyFromFishLabel(txt)
        end
        local function fireMashingSuccess()
            local q = qteEv()
            if not q then
                return
            end
            local function once(ev)
                pcall(function() ev:FireServer("MashingSuccess") end)
            end
            once(q)
            task.delay(0.08, function()
                local q2 = qteEv()
                if q2 then once(q2) end
            end)
        end
        local function fireReactionSuccess()
            local q = qteEv()
            if q then
                pcall(function() q:FireServer("Success") end)
            end
        end
        local function fentiMashContainerOpen()
            local gc = _G.fentiGetMashingContainer
            local c = type(gc) == "function" and gc() or nil
            return c ~= nil and c.Visible == true
        end
        local function runFishingMashSequence(sourceTag, difficulty)
            sourceTag = sourceTag or "?"
            local tgt = QTE_TARGETS["Mid"]
            if type(difficulty) == "string" then
                tgt = QTE_TARGETS[difficulty] or tgt
            elseif type(difficulty) == "number" and difficulty >= 1 then
                tgt = math.floor(difficulty)
            end
            local pressBudget = tgt + 22
            refreshCharacter()
            unlockRootMotion()
            if not VIM then
                local tw = tick()
                while isRunning and (tick() - tw) < 5 do
                    if fentiMashContainerOpen() then break end
                    task.wait(0.08)
                end
                if fentiMashContainerOpen() then
                    task.wait(0.35 + tgt * 0.028)
                    fireMashingSuccess()
                end
                task.wait(0.35)
                -- Never leave velocity lock on during auto-fish — it zeros HRP every ~0.22s and fights spring rig + casts ("spaced out").
                if isRunning then unlockRootMotion() else lockRootMotion() end
                pcall(function()
                    if _G.fentiSpamNearbyChestPrompts then _G.fentiSpamNearbyChestPrompts(64, 18, 0.08) end
                end)
                if Labels.Status then Labels.Status:SetText("Status: Mash QTE (remote fallback, UI was open)") end
                return
            end
            task.wait(0.12)
            local t0 = tick()
            local maxDur = 14
            local count = 0
            while isRunning and (tick() - t0) < maxDur do
                local c = _G.fentiGetMashingContainer and _G.fentiGetMashingContainer()
                if not c or not c.Visible then break end
                local circle = c:FindFirstChild("Circle")
                local kl = circle and circle:FindFirstChild("KeyLabel")
                local txt = kl and kl.Text and kl.Text:gsub("%s+", ""):upper() or ""
                local kc = mashKeyFromFishLabel(txt)
                if kc then
                    simulateKey(kc)
                    count = count + 1
                    if count >= pressBudget then break end
                end
                task.wait(0.04)
            end
            task.wait(0.2)
            if fentiMashContainerOpen() then
                fireMashingSuccess()
            end
            task.wait(0.45)
            if isRunning then unlockRootMotion() else lockRootMotion() end
            pcall(function()
                if _G.fentiSpamNearbyChestPrompts then _G.fentiSpamNearbyChestPrompts(64, 18, 0.08) end
            end)
            if Labels.Status then Labels.Status:SetText("Status: Mash QTE done") end
        end
        _G.fentiRunFishingMashSequence = runFishingMashSequence
        local function autoMashing(difficulty, ...)
            qteInProgress = true
            task.wait(0.2)
            if isRunning then
                pcall(function() runFishingMashSequence("StartMashing", difficulty) end)
                task.wait(0.3)
                qteInProgress = false
                return
            end
            local target = QTE_TARGETS[difficulty]
            if type(difficulty) == "number" and difficulty >= 1 then target = math.floor(difficulty) end
            if type(target) ~= "number" then target = QTE_TARGETS["Mid"] end
            if not VIM then
                task.wait(math.max(0.55, (target / 10) * 0.48))
                fireMashingSuccess()
            else
                for _ = 1, target + 18 do
                    local container = _G.fentiGetMashingContainer()
                    if not container or not container.Visible then break end
                    local key = getCurrentMashKey()
                    if key then simulateKey(key) end
                    task.wait(0.04)
                end
                fireMashingSuccess()
            end
            task.wait(0.3); qteInProgress = false
        end
        local function autoReaction()
            qteInProgress = true; task.wait(0.2)
            local ms = QTE.system or playerGui:FindFirstChild("MashingSystem")
            if not ms then qteInProgress = false; return end
            local rc = ms:FindFirstChild("ReactionCircle")
            if not rc then task.wait(0.5); rc = ms:FindFirstChild("ReactionCircle") end
            if rc and rc.Visible then
                local kl = rc:FindFirstChild("KeyLabel")
                local us = rc:FindFirstChild("UIStroke")
                local pressed, ws = false, tick()
                while (tick() - ws) < 5 do
                    if us and us.Color.R > 0.95 and us.Color.G > 0.95 and us.Color.B > 0.95 then
                        task.wait(0.02)
                        if kl and kl.Text ~= "" then
                            local sym = kl.Text:gsub("%s+", ""):upper()
                            local ok, kc = pcall(function() return Enum.KeyCode[sym] end)
                            if ok and kc then
                                if isRunning then
                                    fireReactionSuccess()
                                elseif not simulateKey(kc) then
                                    fireReactionSuccess()
                                end
                                pressed = true; break
                            end
                        end
                    end
                    task.wait(0.015)
                end
                if not pressed then fireReactionSuccess() end
            else
                task.wait(0.5); fireReactionSuccess()
            end
            task.wait(0.3); qteInProgress = false
        end
        local function attachQTEListener(q)
            if not q or wiredQTE[q] then return end
            wiredQTE[q] = true
            q.OnClientEvent:Connect(function(eventType, ...)
                if eventType == "StartMashing" then
                    task.spawn(autoMashing, ...)
                elseif eventType == "CancelMashing" then
                    qteInProgress = false
                elseif eventType == "StartReaction" then task.spawn(autoReaction) end
            end)
        end
        local function tryWireQTE()
            attachQTEListener(qteEv())
        end
        task.defer(tryWireQTE)
        task.delay(1.5, tryWireQTE)
        pcall(function()
            RS.DescendantAdded:Connect(function(inst)
                if inst.Name == "QTEEvent" and (inst:IsA("RemoteEvent") or inst:IsA("UnreliableRemoteEvent")) then
                    tryWireQTE()
                end
            end)
        end)
    end)()
    end
    
    -- ----------------------------------------------------------------------------
    -- [FENTI-18] 18–19. CHEST / CORPSE / SAINTS → _G.FentiFarm (IIFE: no main-chunk local for table)
    -- ----------------------------------------------------------------------------
    do
    (function()
    local FentiFarm = {}
    local saintsPollQuietUntil = setmetatable({}, { __mode = "k" })
    local saintsPollThread = nil
    local saintsEspHlCache = {}
    local saintsEspConn = nil
    local saintsEspNextTick = 0
    FentiFarm.getChestPosition = function(chest)
        if chest:IsA("Model") then
            local s, p = pcall(function() return chest:GetPivot().Position end)
            if s and p then return p end
            if chest.PrimaryPart then return chest.PrimaryPart.Position end
            for _, c in pairs(chest:GetChildren()) do if c:IsA("BasePart") then return c.Position end end
        elseif chest:IsA("BasePart") then return chest.Position end
        return nil
    end
    FentiFarm.countChests = function()
        local f = workspace:FindFirstChild("Chests"); if not f then return 0 end
        local c = 0; for _, ch in pairs(f:GetChildren()) do if ch.Name == "ChestBox" then c = c + 1 end end; return c
    end
    FentiFarm.chestFarmLoop = function()
        totalChestsAtStart = FentiFarm.countChests(); chestsOpened = 0; openedChests = {}
        local function updateChestUI()
            local remaining = FentiFarm.countChests()
            local unopened = 0
            local cf = workspace:FindFirstChild("Chests")
            if cf then for _, ch in pairs(cf:GetChildren()) do if ch.Name == "ChestBox" and not openedChests[ch] then unopened = unopened + 1 end end end
            if Labels.ChestCount then Labels.ChestCount:SetText(string.format("Opened: %d / %d  |  Left: %d", chestsOpened, totalChestsAtStart, unopened)) end
            if Labels.ChestServer then Labels.ChestServer:SetText("Chests In Server: " .. remaining) end
        end
        updateChestUI()
        while chestFarmEnabled do
            if FentiFarm.countChests() == 0 and Toggles.ChestServerhop.Value then Library:Notify("No chests! Serverhopping...", 5); task.wait(2); serverHop(); return end
            local toOpen = {}
            local cf = workspace:FindFirstChild("Chests")
            if cf then for _, ch in pairs(cf:GetChildren()) do if ch.Name == "ChestBox" and not openedChests[ch] then table.insert(toOpen, ch) end end end
            if #toOpen == 0 then
                if Toggles.ChestServerhop.Value then Library:Notify("All chests opened! Serverhopping...", 5); task.wait(2); serverHop(); return end
                updateChestUI(); task.wait(5)
            else
                for _, chest in pairs(toOpen) do
                    if not chestFarmEnabled or not chest.Parent then break end
                    local pos = nil
                    local prOpen = chest:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prOpen then pos = fentiPromptWorldPosition(prOpen) end
                    if not pos then pos = FentiFarm.getChestPosition(chest) end
                    if pos then
                        refreshCharacter()
                        if humanoidRootPart then
                            fentiPromptTeleport(CFrame.new(pos + Vector3.new(0, 3, 0)))
                            task.wait(0.5)
                            task.wait(0.2)
                            local prOpen2 = chest:FindFirstChildWhichIsA("ProximityPrompt", true)
                            local n = 0
                            if prOpen2 and _G.fentiFireProximityMinimal then
                                _G.fentiFireProximityMinimal(prOpen2)
                                n = 1
                                task.wait(0.15)
                            end
                            banLog("CHEST-FARM", "ChestBox prompts fired (minimal): " .. n)
                            openedChests[chest] = true; chestsOpened = chestsOpened + 1
                            Library:Notify(string.format("Chest %d/%d", chestsOpened, totalChestsAtStart), 2); updateChestUI()
                            task.wait(Options.ChestTPDelay.Value or 5)
                            if isRunning and originalPosition then smartTeleport(CFrame.new(originalPosition)); task.wait(0.5) end
                        end
                    end
                end
                updateChestUI(); task.wait(3)
            end
        end
    end
    
    FentiFarm.getCorpsePosition = function(spawn)
        if spawn:IsA("BasePart") then return spawn.Position
        elseif spawn:IsA("Model") then local s, p = pcall(function() return spawn:GetPivot().Position end); if s then return p end end
        return nil
    end
    FentiFarm.countCorpseSpawns = function()
        local f = workspace:FindFirstChild("CorpseSpawns"); if not f then return 0 end
        local c = 0; for _, ch in pairs(f:GetChildren()) do if ch.Name == "CorpseSpawn" then c = c + 1 end end; return c
    end
    FentiFarm.getCorpseSpawnList = function()
        local list = {}; local f = workspace:FindFirstChild("CorpseSpawns"); if not f then return list end
        for i, ch in pairs(f:GetChildren()) do if ch.Name == "CorpseSpawn" then table.insert(list, "Corpse #" .. i) end end; return list
    end
    FentiFarm.getCorpseByIndex = function(index)
        local f = workspace:FindFirstChild("CorpseSpawns"); if not f then return nil end
        local count = 0
        for _, ch in pairs(f:GetChildren()) do if ch.Name == "CorpseSpawn" then count = count + 1; if count == index then return ch end end end
        return nil
    end
    FentiFarm.pickupCorpseAt = function(spawn)
        local pos = FentiFarm.getCorpsePosition(spawn); if not pos then return false end
        refreshCharacter(); if not humanoidRootPart then return false end
        fentiPromptTeleport(CFrame.new(pos + Vector3.new(0, 3, 0))); task.wait(0.8)
        refreshCharacter()
        pcall(function()
            if humanoidRootPart then humanoidRootPart.Anchored = false end
        end)
    
        local picked = false
        local prompt = waitForPrompt(spawn, 3)
        if prompt then spamPrompt(prompt, 8, 0.15); picked = true end
        if not picked then picked = fireAllPrompts(spawn, 3) end
    
        for _, obj in pairs(workspace:GetChildren()) do
            if obj:IsA("Model") or obj:IsA("BasePart") then
                local objPos; pcall(function() objPos = obj:IsA("Model") and obj:GetPivot().Position or obj.Position end)
                if objPos and humanoidRootPart and (objPos - humanoidRootPart.Position).Magnitude < 25 then
                    local p = waitForPrompt(obj, 1)
                    if p then spamPrompt(p, 5, 0.15); picked = true
                    elseif fireAllPrompts(obj, 2) then picked = true end
                end
            end
        end
        local cpFolder = RS:FindFirstChild("CorpseParts")
        if cpFolder then
            for _, part in pairs(cpFolder:GetChildren()) do
                if fentiSaintsPartEligible(part.Name) then
                    local p = waitForPrompt(part, 1)
                    if p then spamPrompt(p, 5, 0.15); picked = true
                    elseif fireAllPrompts(part, 2) then picked = true end
                end
            end
        end
        local wcp = workspace:FindFirstChild("CorpseParts")
        if wcp then
            for _, part in pairs(wcp:GetChildren()) do
                if part:IsA("BasePart") and fentiSaintsPartEligible(part.Name) and humanoidRootPart and (part.Position - humanoidRootPart.Position).Magnitude < 40 then
                    local p = waitForPrompt(part, 1)
                    if p then spamPrompt(p, 5, 0.15); picked = true
                    elseif fireAllPrompts(part, 2) then picked = true end
                end
            end
        end
        return picked
    end
    FentiFarm.corpseFarmLoop = function()
        while corpseFarmEnabled do
            local folder = workspace:FindFirstChild("CorpseSpawns")
            if not folder or #folder:GetChildren() == 0 then
                if Labels.Corpse then Labels.Corpse:SetText("No corpse spawns. Waiting...") end
                task.wait(3)
            else
                for _, spawn in pairs(folder:GetChildren()) do
                    if not corpseFarmEnabled then break end
                    if spawn.Name == "CorpseSpawn" then
                        FentiFarm.pickupCorpseAt(spawn)
                        if Labels.Corpse then Labels.Corpse:SetText("Spots: " .. FentiFarm.countCorpseSpawns()) end
                        if Toggles.CorpseSafeTP and Toggles.CorpseSafeTP.Value then fentiPromptTeleport(SAFE_ZONE_POS); task.wait(1) end
                        task.wait(Options.CorpseTPDelay and Options.CorpseTPDelay.Value or 3)
                    end
                end
                task.wait(2)
            end
        end
    end
    FentiFarm.startCorpseListener = function()
        if corpseListenerConn then corpseListenerConn:Disconnect() end
        corpseListenerActive = true
        corpseListenerConn = RS.DescendantAdded:Connect(function(desc)
            if not corpseListenerActive then return end
            if desc.Name == "CorpseSpawnSFX" or (desc:IsA("Sound") and desc.Name:find("Corpse")) then
                Library:Notify("Corpse spawned! (SFX detected)", 4)
                if Labels.Corpse then Labels.Corpse:SetText("Spots: " .. FentiFarm.countCorpseSpawns()) end
                if Options.SelectedCorpse then Options.SelectedCorpse:SetValues(FentiFarm.getCorpseSpawnList()) end
            end
        end)
        local wsConn = workspace.DescendantAdded:Connect(function(desc)
            if not corpseListenerActive then return end
            if desc.Name == "CorpseSpawnSFX" or (desc:IsA("Sound") and desc.Name:find("Corpse")) then
                Library:Notify("Corpse spawned!", 4)
                if Labels.Corpse then Labels.Corpse:SetText("Spots: " .. FentiFarm.countCorpseSpawns()) end
                if Options.SelectedCorpse then Options.SelectedCorpse:SetValues(FentiFarm.getCorpseSpawnList()) end
            end
            if desc.Name == "CorpseSpawn" then
                task.wait(0.5)
                if Labels.Corpse then Labels.Corpse:SetText("Spots: " .. FentiFarm.countCorpseSpawns()) end
                if Options.SelectedCorpse then Options.SelectedCorpse:SetValues(FentiFarm.getCorpseSpawnList()) end
            end
        end)
        table.insert(activeConnections, corpseListenerConn)
        table.insert(activeConnections, wsConn)
    end
    FentiFarm.stopCorpseListener = function()
        corpseListenerActive = false
        if corpseListenerConn then corpseListenerConn:Disconnect(); corpseListenerConn = nil end
    end
    
    local function matchesSaintsFilter(name)
        if not name:find("Saints") then return false end
        local anySelected = false
        for _, v in pairs(saintsPartFilter) do if v then anySelected = true; break end end
        if not anySelected then return true end
        return saintsPartFilter[name] == true
    end
    
    local function getMyEntityFolder()
        local saints = workspace:FindFirstChild("saints")
        if not saints then return nil end
        local ents = saints:FindFirstChild("Entities")
        if not ents then return nil end
        return ents:FindFirstChild(player.Name)
            or ents:FindFirstChild(player.DisplayName)
            or ents:FindFirstChild(tostring(player.UserId))
    end

    local function fentiIsOtherEntityFolder(folderName)
        if folderName == player.Name or folderName == player.DisplayName then return false end
        if folderName == tostring(player.UserId) then return false end
        return true
    end
    
    local function hasSaintPart(partName)
        local folder = getMyEntityFolder()
        if not folder then return false end
        return folder:FindFirstChild(partName) ~= nil
    end
    
    local function claimSaintsPart(part)
        if not part or not part:IsDescendantOf(workspace) then return end
        if saintsClaimLock[part] then return end
        local partName = part.Name
        if hasSaintPart(partName) then
            Library:Notify("Already have " .. partName .. "!", 3)
            return
        end
        saintsClaimLock[part] = true
        Library:Notify("Saints: claiming " .. partName, 3)

        if saintsResetBeforeClaim then
            fentiPromptTeleport(SAFE_ZONE_POS)
            task.wait(0.45)
            refreshCharacter()
        end

        if not part:IsDescendantOf(workspace) then
            saintsClaimLock[part] = nil
            Library:Notify(partName .. " despawned.", 3)
            return
        end

        refreshCharacter()
        if not humanoidRootPart then
            saintsClaimLock[part] = nil
            Library:Notify("Saints: no HRP", 4)
            return
        end

        local atCF = part.CFrame
        pcall(function()
            if part:IsA("Model") then atCF = part:GetPivot() end
        end)
        local targetCF = atCF * CFrame.new(0, 2, 0)
        local tpOk = _G.fentiSoftTeleportTo and _G.fentiSoftTeleportTo(targetCF, "saintsClaim")
        if not tpOk then
            pcall(function()
                refreshCharacter()
                if humanoidRootPart then
                    humanoidRootPart.CFrame = targetCF
                    humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
                end
            end)
        end

        refreshCharacter()
        task.wait(0.12)
        pcall(function()
            if humanoidRootPart and part.Parent then
                patchNearbyPrompts(humanoidRootPart.Position, 72)
                patchAndFirePromptsOnInstance(part, "saintsClaim", 0.12)
            end
        end)
        task.wait(0.2)
        local claimedOk = false
        for _round = 1, math.max(1, saintsClaimPromptRounds) do
            if not part:IsDescendantOf(workspace) then break end
            refreshCharacter()
            local pr = waitForPrompt(part, 2.2)
            if pr then
                spamPrompt(pr, 10, 0.1)
            else
                pcall(function()
                    if humanoidRootPart then patchNearbyPrompts(humanoidRootPart.Position, 72) end
                end)
                for _ = 1, 10 do
                    pcall(function()
                        local p2 = part:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if p2 and _G.fentiFireProximityMinimal then _G.fentiFireProximityMinimal(p2) end
                    end)
                    task.wait(0.07)
                end
                fireAllPrompts(part, 4)
            end
            task.wait(0.32)
            if hasSaintPart(partName) then
                claimedOk = true
                break
            end
        end

        if claimedOk then
            Library:Notify("Saints: claimed " .. partName, 2)
        else
            Library:Notify("Saints: " .. partName .. " — check inventory (retried)", 3)
        end

        if saintsSafeAfterClaim then
            task.wait(0.06)
            local okSafe = false
            for att = 1, saintsSafeAfterClaimMaxAttempts do
                refreshCharacter()
                if _G.fentiSoftTeleportTo and _G.fentiSoftTeleportTo(SAFE_ZONE_POS, "saintsPostClaim_" .. att) then
                    okSafe = true
                    break
                end
                task.wait(0.35 + att * 0.12)
                refreshCharacter()
            end
            if not okSafe then
                Library:Notify("Saints: safe TP failed — open Teleport → Safe zone", 4)
            end
        end

        saintsClaimLock[part] = nil
    end
    FentiFarm.claimSaintsPart = claimSaintsPart
    
    local saintsConns = {}
    FentiFarm.startSaintsMonitor = function()
        for _, c in ipairs(saintsConns) do pcall(function() c:Disconnect() end) end
        saintsConns = {}
        if saintsPollThread then
            pcall(function() task.cancel(saintsPollThread) end)
            saintsPollThread = nil
        end
    
        local function isMine(obj)
            local myFolder = getMyEntityFolder()
            return myFolder and obj:IsDescendantOf(myFolder)
        end
    
        -- fromPoll: Entity-folder rescan — dedupe so we don’t notify + spawn every interval for the same part.
        local function onWorldPart(child, fromPoll)
            if not saintsEnabled then return end
            if not child:IsA("BasePart") then return end
            if not matchesSaintsFilter(child.Name) then return end
            if hasSaintPart(child.Name) then return end
            if isMine(child) then return end
            if saintsClaimLock[child] then return end
            if fromPoll then
                local quiet = saintsPollQuietUntil[child]
                if quiet and tick() < quiet then return end
                saintsPollQuietUntil[child] = tick() + 28
            end
            Library:Notify("Saints part spawned: " .. child.Name, 4)
            task.spawn(function()
                local fn = FentiFarm.claimSaintsPart
                if fn then fn(child) end
            end)
        end
    
        local function onWorkspaceChildAdded(child)
            onWorldPart(child, false)
        end

        local function scanEntityFolderForSaints(folder, fromPoll)
            for _, ch in ipairs(folder:GetChildren()) do
                if ch:IsA("BasePart") and matchesSaintsFilter(ch.Name) and not hasSaintPart(ch.Name) then
                    onWorldPart(ch, fromPoll)
                elseif ch:IsA("Model") then
                    for _, d in ipairs(ch:GetDescendants()) do
                        if d:IsA("BasePart") and matchesSaintsFilter(d.Name) and not hasSaintPart(d.Name) then
                            onWorldPart(d, fromPoll)
                        end
                    end
                end
            end
        end

        local function scanAllSaintsParts(fromPoll)
            for _, ch in ipairs(workspace:GetChildren()) do
                if ch:IsA("BasePart") and matchesSaintsFilter(ch.Name) and not hasSaintPart(ch.Name) then
                    onWorldPart(ch, fromPoll)
                end
            end
            local wcp = workspace:FindFirstChild("CorpseParts")
            if wcp then
                for _, ch in ipairs(wcp:GetChildren()) do
                    if ch:IsA("BasePart") and matchesSaintsFilter(ch.Name) and not hasSaintPart(ch.Name) then
                        onWorldPart(ch, fromPoll)
                    end
                end
            end
            local saintsF = workspace:FindFirstChild("saints")
            if not saintsF then return end
            local ents = saintsF:FindFirstChild("Entities")
            if not ents then return end
            for _, folder in ipairs(ents:GetChildren()) do
                if fentiIsOtherEntityFolder(folder.Name) then
                    scanEntityFolderForSaints(folder, fromPoll)
                end
            end
        end

        local hookedSaintsRoots = {}
        local function hookSaintsWatchTree(sf)
            if not sf or hookedSaintsRoots[sf] then return end
            hookedSaintsRoots[sf] = true
            table.insert(saintsConns, sf.DescendantAdded:Connect(function(inst)
                if not saintsEnabled then return end
                if inst:IsA("BasePart") and matchesSaintsFilter(inst.Name) then
                    task.defer(function()
                        if inst.Parent then onWorldPart(inst, false) end
                    end)
                end
            end))
        end

        scanAllSaintsParts(false)
        local existingSaints = workspace:FindFirstChild("saints")
        if existingSaints then hookSaintsWatchTree(existingSaints) end

        table.insert(saintsConns, workspace.ChildAdded:Connect(function(ch)
            if ch.Name == "saints" then hookSaintsWatchTree(ch) end
            onWorkspaceChildAdded(ch)
        end))
        table.insert(saintsConns, workspace.DescendantAdded:Connect(function(inst)
            if not inst:IsA("BasePart") then return end
            local par = inst.Parent
            if par and par.Name == "CorpseParts" and par:IsDescendantOf(workspace) then
                onWorldPart(inst, false)
            end
        end))
    
        saintsPollThread = task.spawn(function()
            while saintsEnabled do
                local stealthPoll = rawget(_G, "FENTI_SAINTS_STEALTH") == true or saintsPickupStealth == true
                local waitSec = stealthPoll and (math.random(32, 62) / 10)
                    or (saintsAllInOne and (2 + math.random(0, 20) / 10) or (10 + math.random(0, 60) / 10))
                task.wait(waitSec)
                if not saintsEnabled then break end
                pcall(function() scanAllSaintsParts(true) end)
            end
            saintsPollThread = nil
        end)
    
        for _, c in ipairs(saintsConns) do table.insert(activeConnections, c) end
    end
    FentiFarm.stopSaintsMonitor = function()
        for _, c in ipairs(saintsConns) do pcall(function() c:Disconnect() end) end
        saintsConns = {}
        if saintsPollThread then
            pcall(function() task.cancel(saintsPollThread) end)
            saintsPollThread = nil
        end
    end
    FentiFarm.stopSaintsEsp = function()
        if saintsEspConn then
            pcall(function() saintsEspConn:Disconnect() end)
            saintsEspConn = nil
        end
        for part, hl in pairs(saintsEspHlCache) do
            pcall(function()
                if hl and hl.Parent then hl:Destroy() end
            end)
        end
        saintsEspHlCache = {}
    end
    FentiFarm.startSaintsEsp = function()
        if not saintsEspEnabled then return end
        if saintsEspConn then return end
        local function tickEsp()
            if not saintsEspEnabled then
                FentiFarm.stopSaintsEsp()
                return
            end
            local meFolder = getMyEntityFolder()
            local seen = {}
            local function consider(p)
                if p:IsA("BasePart") and matchesSaintsFilter(p.Name) then
                    if hasSaintPart(p.Name) then return end
                    if meFolder and p:IsDescendantOf(meFolder) then return end
                    seen[p] = true
                    if not saintsEspHlCache[p] or not saintsEspHlCache[p].Parent then
                        pcall(function()
                            local old = saintsEspHlCache[p]
                            if old and old.Parent then old:Destroy() end
                            local hl = Instance.new("Highlight")
                            hl.Name = "FentiSaintsESP"
                            hl.Adornee = p
                            hl.FillColor = Color3.fromRGB(255, 220, 80)
                            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                            hl.FillTransparency = 0.55
                            hl.OutlineTransparency = 0
                            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                            hl.Parent = p
                            saintsEspHlCache[p] = hl
                        end)
                    end
                end
            end
            for _, ch in ipairs(workspace:GetChildren()) do
                consider(ch)
            end
            local corpsePartsFolder = workspace:FindFirstChild("CorpseParts")
            if corpsePartsFolder then
                for _, p in ipairs(corpsePartsFolder:GetChildren()) do
                    consider(p)
                end
            end
            local saints = workspace:FindFirstChild("saints")
            if saints then
                local ents = saints:FindFirstChild("Entities")
                if ents then
                    for _, folder in ipairs(ents:GetChildren()) do
                        if fentiIsOtherEntityFolder(folder.Name) then
                            for _, p in ipairs(folder:GetChildren()) do
                                consider(p)
                                if p:IsA("Model") then
                                    for _, d in ipairs(p:GetDescendants()) do
                                        consider(d)
                                    end
                                end
                            end
                        end
                    end
                end
            end
            for part, hl in pairs(saintsEspHlCache) do
                if not seen[part] or not part.Parent then
                    pcall(function()
                        if hl and hl.Parent then hl:Destroy() end
                    end)
                    saintsEspHlCache[part] = nil
                end
            end
        end
        saintsEspNextTick = 0
        saintsEspConn = RunService.Heartbeat:Connect(function()
            local now = tick()
            if now < saintsEspNextTick then return end
            saintsEspNextTick = now + 0.35
            pcall(tickEsp)
        end)
    end
    FentiFarm.hasSaintPart = hasSaintPart
    _G.FentiFarm = FentiFarm
    end)()
    end
    
    -- ----------------------------------------------------------------------------
    -- [FENTI-20] 20. WEBHOOK (IIFE — chunk register cap)
    -- ----------------------------------------------------------------------------
    ;(function()
        local FENTI_FISH_RARITY_TIERS = {
            { keys = { "legendary" }, label = "Legendary", color = 16766720 },
            { keys = { "epic" }, label = "Epic", color = 9379868 },
            { keys = { "rare" }, label = "Rare", color = 3447003 },
            { keys = { "common" }, label = "Common", color = 9807270 },
        }
        function _G.fentiClassifyFishRarity(text)
            local s = string.lower(tostring(text or ""))
            for _, tier in ipairs(FENTI_FISH_RARITY_TIERS) do
                for _, k in ipairs(tier.keys) do
                    if string.find(s, k, 1, true) then
                        return tier.label, tier.color
                    end
                end
            end
            return "Common", 9807270
        end
    end)()
    
    -- `catchLine` = full NotificationEvent string (same rarity words the game shows).
    sendFishWebhook = function(catchLine)
        local url = webhookURL
        if url == "" and Options and Options.WebhookURL then url = Options.WebhookURL.Value or "" end
        if not webhookEnabled or url == "" then return end
        local rarityLabel, rarityColor = _G.fentiClassifyFishRarity(catchLine)
        if webhookRarityNotify[rarityLabel] == false then return end
        task.spawn(function()
            pcall(function()
                local req = (syn and syn.request) or (http and http.request) or http_request or request or fluxus_request
                if not req then return end
                local elapsed = os.time() - Script_Start_Time
                local sessionStr = string.format("%dh %02dm", math.floor(elapsed / 3600), math.floor((elapsed % 3600) / 60))
                req({
                    Url = url, Method = "POST", Headers = {["Content-Type"] = "application/json"},
                    Body = HttpService:JSONEncode({
                        username = "fenti",
                        avatar_url = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=150&height=150&format=png",
                        embeds = {{
                            title = "Fish caught — " .. rarityLabel,
                            description = catchLine,
                            color = rarityColor,
                            fields = {
                                { name = "Rarity", value = rarityLabel, inline = true },
                                { name = "Player", value = player.Name, inline = true },
                                { name = "Session total", value = tostring(fishCaught), inline = true },
                                { name = "Session time", value = sessionStr, inline = true },
                                { name = "Server", value = game.JobId ~= "" and game.JobId:sub(1, 12) .. "..." or "Studio", inline = false },
                            },
                            footer = { text = "fenti" }, timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                        }},
                    }),
                })
            end)
        end)
    end
    
    pcall(function()
        local notifRemote = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("NotificationEvent")
        if notifRemote then
            notifRemote.OnClientEvent:Connect(function(...)
                local args = {...}; local fullMsg = ""
                for _, val in ipairs(args) do if type(val) == "string" then fullMsg = fullMsg .. " " .. val end end
                local lower = fullMsg:lower()
                -- Only "caught" / "reeled" count as catches (not every message containing "fish").
                if lower:find("caught") or lower:find("reeled") then
                    local line = fullMsg:gsub("^%s+", ""):gsub("%s+$", "")
                    -- Chest from fishing: spam proximity opens; do not count as fish / webhook.
                    if lower:find("chest", 1, true) then
                        local nowChest = tick()
                        if nowChest - lastFentiChestPromptSpam >= 0.8 then
                            lastFentiChestPromptSpam = nowChest
                            pcall(function()
                                if _G.fentiSpamNearbyChestPrompts then _G.fentiSpamNearbyChestPrompts(64, 26, 0.06) end
                            end)
                        end
                        banLog("FISH", "Chest reel (notification) — " .. line:sub(1, 120))
                        return
                    end
                    lastCaughtFish = line:match("[Cc]aught%s+(.+)") or line:match("[Rr]eeled%s+in%s+(.+)") or line
                    lastCaughtFish = lastCaughtFish:gsub("^%s+", ""):gsub("%s+$", "")
                    if lastCaughtFish == "" then lastCaughtFish = line end
                    local now = tick()
                    if now - lastFentiCatchNotifAt >= 0.85 then
                        lastFentiCatchNotifAt = now
                        fishCaught = fishCaught + 1
                        if Labels.FishCount then Labels.FishCount:SetText("Fish Caught: " .. fishCaught) end
                        banLog("FISH", "Catch confirmed (game notification) #" .. fishCaught .. " — " .. line:sub(1, 120))
                        sendFishWebhook(line)
                    end
                end
            end)
        end
    end)
    
    -- ----------------------------------------------------------------------------
    -- [FENTI-21] 21. SERVERHOP
    -- ----------------------------------------------------------------------------
    serverHop = function()
        Library:Notify("Serverhopping...", 5)
        local success, result = pcall(function()
            local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
            if servers and servers.data then
                for _, server in ipairs(servers.data) do
                    if server.id ~= game.JobId and server.playing < server.maxPlayers then
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, player); return true
                    end
                end
            end; return false
        end)
        if not success or not result then Library:Notify("Serverhop failed, retrying...", 3); task.wait(5); TeleportService:Teleport(game.PlaceId, player) end
    end
    
    -- ----------------------------------------------------------------------------
    -- [FENTI-22] 22. OBSIDIAN UI (_G.fentiWindow — avoids main-chunk “local Window” register overflow)
    -- ----------------------------------------------------------------------------
    -- Inside the IIFE below: [FENTI-22a] Information, [FENTI-22·players] Players (you + ESP), [FENTI-22b] Fishing, [FENTI-22c] Teleport, [FENTI-22d] NPCs, [FENTI-22·aura] Aura, [FENTI-22e] Config.
    _G.fentiWindow = nil
    if type(Library) ~= "table" or type(Library.CreateWindow) ~= "function" then
        warn("[fenti] Library.CreateWindow missing — UI library did not load correctly.")
        return
    end
    -- pcall temps on _G (not bare globals): many obfuscators break implicit globals; _G is usually whitelisted.
    _G.fentiCWOk, _G.fentiCWErr = pcall(function()
        _G.fentiWindow = Library:CreateWindow({
            Title = "fenti",
            Footer = "by vbu3 | " .. tostring(assetName),
            NotifySide = "Right",
            Icon = 119322103775095,
            ShowCustomCursor = false,
            AutoShow = true,
            Center = true,
            EnableSidebarResize = true,
            Font = Enum.Font.RobotoMono,
        })
    end)
    if not _G.fentiCWOk then
        warn("[fenti] CreateWindow error: " .. tostring(_G.fentiCWErr))
        _G.fentiCWOk, _G.fentiCWErr = pcall(function()
            _G.fentiWindow = Library:CreateWindow({
                Title = "fenti",
                Footer = "by vbu3 | " .. tostring(assetName),
                NotifySide = "Right",
                ShowCustomCursor = false,
                AutoShow = true,
                Center = true,
                EnableSidebarResize = true,
                Font = Enum.Font.RobotoMono,
            })
        end)
        if not _G.fentiCWOk then warn("[fenti] CreateWindow retry (no Icon) failed: " .. tostring(_G.fentiCWErr)) end
    end
    if not _G.fentiWindow then warn("[fenti] Could not open the menu (Library/CreateWindow returned nil)."); return end
    do
    (function()
    -- [FENTI-22·core] Sidebar order: Information → Players → Fishing → Teleport → Saints → D4C farm → Aimbot → NPCs → Aura → Config (last)
    local Tabs = {}
    local Window = _G.fentiWindow
    pcall(function() Tabs.Information = Window:AddTab("Information", "info") end)
    pcall(function() Tabs.Players = Window:AddTab("Players", "users") end)
    pcall(function() Tabs.Fishing = Window:AddTab("Fishing", "anchor") end)
    pcall(function() Tabs.Teleport = Window:AddTab("Teleport", "map-pin") end)
    pcall(function() Tabs.Saints = Window:AddTab("Saints", "crosshair") end)
    pcall(function() Tabs.D4CFarm = Window:AddTab("D4C farm", "swords") end)
    pcall(function() Tabs.Aimbot = Window:AddTab("Aimbot", "zap") end)
    pcall(function() Tabs.NPCs = Window:AddTab("NPCs", "user") end)
    pcall(function() Tabs.Aura = Window:AddTab("Aura", "palette") end)
    pcall(function() Tabs.Config = Window:AddTab("Config", "cog") end)
    
    -- [FENTI-22a] Information
    if Tabs.Information then do
    local InfoLeft = {
        User = Tabs.Information:AddLeftGroupbox("User", "user"),
        Game = Tabs.Information:AddLeftGroupbox("Game", "gamepad"),
    }
    local InfoRightOverview = Tabs.Information:AddRightGroupbox("Tabs", "sparkles")
    local InfoRightLogs = Tabs.Information:AddRightGroupbox("Logs", "list")
    
    InfoLeft.User:AddLabel("<b>Type:</b> <font color='#FFCC00'>Free</font>")
    InfoLeft.User:AddLabel("<b>Status:</b> <font color='#00FF00'>Working</font>")
    InfoLeft.User:AddLabel("<b>Executor:</b> " .. executorDisplay)
    InfoLeft.User:AddLabel("<b>Xeno:</b> <font color='#00FF00'>Works</font> — idk anymore")
    InfoLeft.User:AddDivider()
    Labels.Session = InfoLeft.User:AddLabel("<b>Session:</b> " .. GetSessionTime())
    task.spawn(function()
        while task.wait(30) do
            if Labels.Session then Labels.Session:SetText("<b>Session:</b> " .. GetSessionTime()) end
        end
    end)
    
    InfoLeft.Game:AddLabel("<b>Game:</b> " .. assetName)
    InfoLeft.Game:AddDivider()
    InfoLeft.Game:AddLabel("<b>PlaceId:</b> " .. tostring(game.PlaceId))
    InfoLeft.Game:AddDivider()
    InfoLeft.Game:AddLabel("<b>JobId:</b> " .. (game.JobId ~= "" and game.JobId or "Studio"), true)
    InfoLeft.Game:AddDivider()
    InfoLeft.Game:AddButton({ Text = "Copy JobId", Func = function()
        if setclipboard then setclipboard(game.JobId); Library:Notify("JobId copied.", 3) else Library:Notify("Clipboard not supported.", 3) end
    end })
    local InfoContributors = Tabs.Information:AddLeftGroupbox("Contributors", "users")
    InfoContributors:AddLabel("<b>capy</b>", true)
    InfoContributors:AddLabel("<b>ivan</b>", true)
    InfoContributors:AddLabel("<b>920m</b>", true)
    
    InfoRightOverview:AddLabel("<b>Players</b> — you (anti-ragdoll, kill streak) + ESP others", true)
    InfoRightOverview:AddLabel("<b>Fishing</b> — auto fish, shop, webhook", true)
    InfoRightOverview:AddLabel("<b>Teleport</b> — tp ", true)
    InfoRightOverview:AddLabel("<b>Saints</b> — auto claim + optional safe hop", true)
    InfoRightOverview:AddLabel("<b>Aimbot</b> — for u fat fucking loosers", true)
    InfoRightOverview:AddLabel("<b>NPCs</b> — teleport, talk, reroll", true)
    InfoRightOverview:AddLabel("<b>Aura</b> — character effects PLEASE USE THEM", true)
    InfoRightOverview:AddLabel("<b>Config</b> — save, unload", true)
    
    InfoRightLogs:AddLabel("Error log file (if your executor supports files):", true)
    InfoRightLogs:AddDivider()
    InfoRightLogs:AddButton({ Text = "Copy fail log path", Func = function()
        if setclipboard then setclipboard(FAIL_LOG_PATH); Library:Notify("Copied path.", 3) else Library:Notify("Clipboard not supported.", 3) end
    end })
    InfoRightLogs:AddButton({ Text = "Append snapshot to fail log", Func = function()
        failLogSnapshot("MANUAL", "Recent log tail:\n" .. table.concat(_banLog, "\n"):sub(-6000))
        Library:Notify("Appended to " .. FAIL_LOG_PATH, 5)
    end })
    InfoRightLogs:AddDivider()
    InfoRightLogs:AddButton({ Text = "Copy full log", Func = function()
        local header = "=== fenti log ===\nGame: " .. assetName .. "\nLog file: " .. FAIL_LOG_PATH .. "\nSession: " .. GetSessionTime() .. "\nEntries: " .. #_banLog .. "\n"
        local counts = "--- Counts ---\n"
        for cat, cnt in pairs(_banLog_counts) do counts = counts .. cat .. ": " .. cnt .. "\n" end
        local log = header .. counts .. "--- Log ---\n" .. table.concat(_banLog, "\n")
        if setclipboard then setclipboard(log); Library:Notify("Copied " .. #_banLog .. " entries.", 3) else Library:Notify("Clipboard not supported.", 3) end
    end })
    InfoRightLogs:AddButton({ Text = "Log summary", Func = function()
        local parts = {"Entries: " .. #_banLog}
        for cat, cnt in pairs(_banLog_counts) do table.insert(parts, cat .. "=" .. cnt) end
        Library:Notify(table.concat(parts, " | "), 6)
    end })
    end end -- Information
    
    -- [FENTI-22·players] Local player (anti-ragdoll, leaderstats streak) + ESP others
    if Tabs.Players then do
    local PlayersYou = Tabs.Players:AddLeftGroupbox("You", "user-circle")
    Labels.KillStreak = PlayersYou:AddLabel("<b>Kill streak:</b> —")
    PlayersYou:AddToggle("KillstreakTracker", {
        Text = "Track leaderstats streak",
        Default = false,
        Callback = function(v)
            killstreakTrackerEnabled = v
            if v then fentiStartKillstreakTracker() else fentiStopKillstreakTracker() end
            Library:Notify(v and "Kill streak tracker on" or "Kill streak tracker off", 2)
        end,
    })
    PlayersYou:AddToggle("AntiRagdollFenti", {
        Text = "Anti-ragdoll",
        Default = false,
        Callback = function(v)
            antiRagdollEnabled = v
            if v then fentiStartAntiRagdoll() else fentiStopAntiRagdoll() end
            Library:Notify(v and "Anti-ragdoll on" or "Anti-ragdoll off", 2)
        end,
    })
    PlayersYou:AddLabel("killstreak tracker", true)
    local PlayersESP = Tabs.Players:AddLeftGroupbox("Player ESP", "eye")
    local PlayersESPRight = Tabs.Players:AddRightGroupbox("ESP style", "palette")
    
    PlayersESP:AddToggle("PlayerESPMaster", {
        Text = "Enable player ESP",
        Default = false,
        Callback = function(on)
            VisualSettings.Enabled = on
            espEnabled = on
            if on then pcall(startESP) else pcall(stopESP) end
            Library:Notify(on and "Player ESP on" or "Player ESP off", 2)
        end,
    })
    PlayersESP:AddDivider()
    PlayersESP:AddToggle("PlayerESPHP", { Text = "HP", Default = true, Callback = function(v) VisualSettings.ShowHP = v end })
    PlayersESP:AddToggle("PlayerESPHolding", { Text = "Currently holding", Default = true, Callback = function(v) VisualSettings.ShowWeapon = v end })
    PlayersESP:AddToggle("PlayerESPDistance", { Text = "Distance", Default = true, Callback = function(v) VisualSettings.ShowDistance = v end })
    PlayersESP:AddDivider()
    PlayersESP:AddToggle("PlayerESPName", { Text = "Name", Default = true, Callback = function(v) VisualSettings.ShowName = v end })
    PlayersESP:AddToggle("PlayerESPDisplayName", { Text = "Use display name", Default = true, Callback = function(v) VisualSettings.ShowDisplayName = v end })
    
    PlayersESPRight:AddSlider("PlayerESPRenderDist", {
        Text = "Max distance (studs)",
        Default = 2000,
        Min = 150,
        Max = 4000,
        Rounding = 0,
        Callback = function(v) VisualSettings.RenderDistance = v end,
    })
    PlayersESPRight:AddToggle("PlayerESPHighlightFill", { Text = "Highlight fill", Default = true, Callback = function(v) VisualSettings.ShowHighlightFill = v; fentiPlayerESPToggleRebuild() end })
    PlayersESPRight:AddSlider("PlayerESPHighlightAlpha", {
        Text = "Fill transparency",
        Default = 55,
        Min = 0,
        Max = 100,
        Rounding = 0,
        Callback = function(v) VisualSettings.HighlightFill = v / 100; fentiPlayerESPToggleRebuild() end,
    })
    PlayersESPRight:AddDivider()
    PlayersESPRight:AddToggle("PlayerESPEntity", {
        Text = "idk i needa fix ts",
        Default = false,
        Callback = function(v)
            VisualSettings.EntityEnabled = v
            fentiPlayerESPToggleRebuild()
        end,
    })
    end end -- Players
    
    -- [FENTI-22b] Fishing
    if Tabs.Fishing then do
    local FishingLeft = Tabs.Fishing:AddLeftGroupbox("Bot", "play")
    local FishingRight = Tabs.Fishing:AddRightGroupbox("Status", "activity")
    local FishingShop = Tabs.Fishing:AddRightGroupbox("Daniel's Shop", "shopping-cart")
    
    Labels.Status = FishingRight:AddLabel("Status: Idle")
    Labels.FishCount = FishingRight:AddLabel("Fish Caught: 0")
    FishingRight:AddDivider()
    FishingRight:AddLabel("Discord webhook (optional)", true)
    FishingRight:AddInput("WebhookURL", { Text = "Discord Webhook URL", Default = "", Placeholder = "https://discord.com/api/webhooks/...", Finished = true, Callback = function(val) webhookURL = val end })
    FishingRight:AddToggle("WebhookEnabled", { Text = "Send catches to Discord", Default = false, Callback = function(val)
        webhookEnabled = val
        if val and webhookURL ~= "" then Library:Notify("Webhook ON", 3) elseif val then Library:Notify("Webhook ON — set URL", 3) else Library:Notify("Webhook OFF", 3) end
    end })
    FishingRight:AddDivider()
    FishingRight:AddLabel("Which rarities to post (uncheck to skip):", true)
    FishingRight:AddToggle("WebhookNotifyLegendary", { Text = "Post Legendary", Default = true, Callback = function(v) webhookRarityNotify.Legendary = v end })
    FishingRight:AddToggle("WebhookNotifyEpic", { Text = "Post Epic", Default = true, Callback = function(v) webhookRarityNotify.Epic = v end })
    FishingRight:AddToggle("WebhookNotifyRare", { Text = "Post Rare", Default = true, Callback = function(v) webhookRarityNotify.Rare = v end })
    FishingRight:AddToggle("WebhookNotifyCommon", { Text = "Post Common", Default = true, Callback = function(v) webhookRarityNotify.Common = v end })
    
    FishingLeft:AddToggle("UseBait", { Text = "Use bait", Default = true, Callback = function(val) useBait = val end })
    FishingLeft:AddToggle("AutoBuyBait", { Text = "Auto buy bait when out", Default = false, Callback = function(val) autoBuyBait = val end })
    FishingLeft:AddToggle("AutoFishLoot", { Text = "Auto loot (chests ≤40 studs)", Default = false, Callback = function(val) autoFishLootChests = val end })
    FishingLeft:AddDivider()
    FishingLeft:AddLabel("<b>Fishing TP presets</b>", true)
    FishingLeft:AddDropdown("FishSpotPick", {
        Text = "Teleport preset",
        Values = fentiFishSpotDropdownValues(),
        Default = "Default",
        Callback = function(val) fentiSelectedFishSpotName = val end,
    })
    FishingLeft:AddInput("FishSpotNewName", { Text = "New preset name", Default = "My spot", Finished = true })
    FishingLeft:AddButton({ Text = "Add preset (save stand here)", Func = function()
        refreshCharacter()
        if not humanoidRootPart then Library:Notify("No character.", 3); return end
        local name = Options.FishSpotNewName and Options.FishSpotNewName.Value or ""
        if type(name) ~= "string" or name == "" then name = "Spot " .. (#fentiCustomFishSpotEntries + 1) end
        for _, e in ipairs(fentiCustomFishSpotEntries) do
            if e.name == name then Library:Notify("That name already exists.", 3); return end
        end
        table.insert(fentiCustomFishSpotEntries, { name = name, cf = humanoidRootPart.CFrame })
        pcall(function()
            if Options.FishSpotPick then Options.FishSpotPick:SetValues(fentiFishSpotDropdownValues()) end
        end)
        Library:Notify("Added \"" .. name .. "\"", 3)
    end })
    FishingLeft:AddButton({ Text = "Remove selected preset", Func = function()
        local sel = fentiSelectedFishSpotName
        if sel == "Default (hub)" then Library:Notify("Cannot remove default hub spot.", 3); return end
        for i, e in ipairs(fentiCustomFishSpotEntries) do
            if e.name == sel then table.remove(fentiCustomFishSpotEntries, i); break end
        end
        fentiSelectedFishSpotName = "Default (hub)"
        pcall(function()
            if Options.FishSpotPick then
                Options.FishSpotPick:SetValues(fentiFishSpotDropdownValues())
                Options.FishSpotPick:SetValue("Default (hub)")
            end
        end)
        Library:Notify("Removed.", 2)
    end })
    FishingLeft:AddButton({ Text = "Teleport to selected preset", Func = function()
        smartTeleport(fentiGetFishSpotCFrame()); Library:Notify("Teleported.", 2)
    end })
    FishingLeft:AddDivider()
    FishingLeft:AddButton({ Text = "START fishing", Func = function()
        if not isRunning then isRunning = true; Library:Notify("Started.", 3); task.spawn(_G.fentiFishingLoop) else Library:Notify("Already running.", 2) end
    end })
    FishingLeft:AddButton({ Text = "STOP fishing", Func = function()
        isRunning = false
        _G.fentiFishingNoSnap = nil
        if _G.fentiStopFishingPoseHold then pcall(_G.fentiStopFishingPoseHold) end
        _G.fentiFishAssistFiredGen = nil
        _G.fentiLastFishCastAim = nil
        stopTPLoop()
        unlockRootMotion()
        Library:Notify("Stopped.", 3)
    end })
    
    FishingShop:AddButton({ Text = "Buy bait (15 Moola)", Func = function() danielAction("Buy_Bait_15"); Library:Notify("Buying bait…", 3) end })
    FishingShop:AddButton({ Text = "Buy fishing rod (150 Moola)", Func = function() danielAction("Buy_FishingRod_150"); Library:Notify("Buying rod…", 3) end })
    FishingShop:AddToggle("AutoBuyRod", { Text = "Buy rod if missing when starting", Default = false, Callback = function(val) autoBuyRod = val end })
    FishingShop:AddDivider()
    FishingShop:AddButton({ Text = "Sell all Bass", Func = function() danielAction("SellAll_Bass") end })
    FishingShop:AddButton({ Text = "Sell all Snapper", Func = function() danielAction("SellAll_Snapper") end })
    FishingShop:AddButton({ Text = "Sell all Cod", Func = function() danielAction("SellAll_Cod") end })
    FishingShop:AddDivider()
    FishingShop:AddButton({ Text = "Sell ALL fish", Func = function() sellAllFish(); Library:Notify("Sold all.", 3) end })
    FishingShop:AddDivider()
    FishingShop:AddSlider("AutoSellDelay", { Text = "Auto-sell every (seconds)", Default = 60, Min = 15, Max = 300, Rounding = 0 })
    FishingShop:AddToggle("AutoSellFish", { Text = "Auto sell all fish", Default = false, Callback = function(s)
        autoSellFish = s
        if s then Library:Notify("Auto-sell ON", 3); task.spawn(autoSellLoop) else Library:Notify("Auto-sell OFF", 3) end
    end })
    FishingShop:AddDivider()
    FishingShop:AddButton({ Text = "Buy ammo pack", Func = function() buyAmmoPack(); Library:Notify("Buying ammo…", 3) end })
    end end -- Fishing
    
    -- [FENTI-22·saints] Saints sniper farm (monitor + soft TP)
    if Tabs.Saints then do
    local SaintsFarm = Tabs.Saints:AddLeftGroupbox("Saints", "crosshair")
    local SaintsStyle = Tabs.Saints:AddRightGroupbox("Pickup style", "shield")
    SaintsFarm:AddLabel("Safe hop after claim uses the same move as the Teleport tab.", true)
    SaintsFarm:AddDivider()
    SaintsFarm:AddToggle("SaintsAutoFarm", {
        Text = "Auto pickup saints",
        Default = false,
        Callback = function(v)
            saintsEnabled = v
            if v then
                pcall(function() _G.FentiFarm.startSaintsMonitor() end)
                Library:Notify("Saints farm on", 2)
            else
                pcall(function() _G.FentiFarm.stopSaintsMonitor() end)
                Library:Notify("Saints farm off", 2)
            end
        end,
    })
    SaintsFarm:AddToggle("InstantPromptSaints", {
        Text = "Instant prompt (saint parts)",
        Default = false,
    })
    SaintsFarm:AddToggle("SaintsFullAuto", {
        Text = "Full auto (everything on)",
        Default = false,
        Callback = function(v)
            saintsAllInOne = v
            if v then
                saintsEspEnabled = true
                pcall(function() _G.FentiFarm.startSaintsEsp() end)
                pcall(function()
                    if Toggles.SaintsPartEsp then Toggles.SaintsPartEsp:SetValue(true) end
                end)
                pcall(function()
                    if Toggles.InstantPromptSaints then Toggles.InstantPromptSaints:SetValue(true) end
                end)
                pcall(function()
                    if Toggles.SaintsAutoFarm and not Toggles.SaintsAutoFarm.Value then
                        Toggles.SaintsAutoFarm:SetValue(true)
                    elseif not saintsEnabled then
                        saintsEnabled = true
                        _G.FentiFarm.startSaintsMonitor()
                    end
                end)
                Library:Notify("Saints full auto on", 3)
            else
                Library:Notify("Full auto off", 2)
            end
        end,
    })
    SaintsFarm:AddToggle("SaintsResetBeforeClaim", {
        Text = "Safe hop before claim",
        Default = false,
        Callback = function(v)
            saintsResetBeforeClaim = v
            Library:Notify(v and "Pre-claim: safe hop first" or "Pre-claim safe hop off", 2)
        end,
    })
    SaintsStyle:AddLabel("<b>Parts to target</b> — saints parts", true)
    local _saintUiParts = {
        { "SaintsHeart", "SaintsHeart" },
        { "SaintsLeftArm", "SaintsLeftArm" },
        { "SaintsRightArm", "SaintsRightArm" },
        { "SaintsLeftLeg", "SaintsLeftLeg" },
        { "SaintsRightLeg", "SaintsRightLeg" },
        { "SaintsRibcage", "SaintsRibcage" },
    }
    for _, sp in ipairs(_saintUiParts) do
        local key, lab = sp[1], sp[2]
        SaintsStyle:AddToggle("SaintsTarget_" .. key, {
            Text = lab,
            Default = saintsPartFilter[key] == true,
            Callback = function(v) saintsPartFilter[key] = v end,
        })
    end
    SaintsStyle:AddDivider()
    SaintsStyle:AddToggle("SaintsPartEsp", {
        Text = "ESP saint parts",
        Default = false,
        Callback = function(v)
            saintsEspEnabled = v
            if v then pcall(function() _G.FentiFarm.startSaintsEsp() end)
            else pcall(function() _G.FentiFarm.stopSaintsEsp() end) end
        end,
    })
    SaintsStyle:AddToggle("SaintsSafeAfterClaim", {
        Text = "Instant safe TP after pickup (retry)",
        Default = true,
        Callback = function(v)
            saintsSafeAfterClaim = v
            Library:Notify(v and "After claim: safe hop (retries)" or "Post-claim safe TP off", 2)
        end,
    })
    SaintsStyle:AddToggle("SaintsStealthPickup", { Text = "Slower pickup (safer)", Default = true, Callback = function(v) saintsPickupStealth = v end })
    SaintsStyle:AddToggle("SaintsGlobalStealth", {
        Text = "Soft prompts (advanced)",
        Default = false,
        Callback = function(v)
            if v then _G.FENTI_SAINTS_STEALTH = true else _G.FENTI_SAINTS_STEALTH = nil end
        end,
    })
    end end -- Saints
    
    -- [FENTI-22·d4c] D4C farm — auto knock / knives / aimbot (ty ivan for the base logic)
    if Tabs.D4CFarm then do
    local D4CLeft = Tabs.D4CFarm:AddLeftGroupbox("D4C farm", "swords")
    D4CLeft:AddLabel("<i>Auto knock — ty for the script ivan.</i>", true)
    D4CLeft:AddDivider()

    local d4cSelectedPlayer = nil
    local d4cLastThrowTime = 0
    local d4cThrowDebounce = 1.2
    local d4cStandUpDelay = 0.2
    local d4cPreviousRagdollState = false
    local d4cAimKey = nil
    local d4cKnifeKey = nil
    local d4cListeningAim = false
    local d4cListeningKnife = false
    local d4cSelectedLabel = nil
    local d4cHealthLabel = nil
    local d4cKnivesLabel = nil
    local d4cAimKeyLabel = nil
    local d4cKnifeKeyLabel = nil
    local d4cAimbotConn = nil

    local function d4cUpdateSelectedLabel()
        if not d4cSelectedLabel then return end
        if d4cSelectedPlayer and d4cSelectedPlayer.Parent then
            local name = d4cSelectedPlayer.DisplayName or d4cSelectedPlayer.Name
            d4cSelectedLabel:SetText("Selected: " .. name)
        else
            d4cSelectedLabel:SetText("Selected: None")
            d4cSelectedPlayer = nil
        end
    end

    local function d4cGetKnivesCount()
        local backpack = player:FindFirstChild("Backpack")
        if backpack then
            for _, child in ipairs(backpack:GetChildren()) do
                if child:IsA("Tool") and child.Name:match("^Knives %(%d+%)$") then
                    local countStr = child.Name:match("%((%d+)%)")
                    if countStr then return tonumber(countStr) end
                end
            end
        end
        local char = player.Character
        if char then
            local tool = char:FindFirstChildWhichIsA("Tool")
            if tool and tool.Name:match("^Knives %(%d+%)$") then
                local countStr = tool.Name:match("%((%d+)%)")
                if countStr then return tonumber(countStr) end
            end
        end
        return 0
    end

    local function d4cIsKnifeEquipped(char)
        if not char then return false end
        local tool = char:FindFirstChildWhichIsA("Tool")
        return tool ~= nil and tool.Name:match("^Knives %(") ~= nil
    end

    local function d4cThrowKnives()
        if not Toggles.D4CKnifeThrow or not Toggles.D4CKnifeThrow.Value then return end
        local now = tick()
        if now - d4cLastThrowTime < d4cThrowDebounce then return end
        d4cLastThrowTime = now

        local char = player.Character
        if not char or not char:FindFirstChild("Humanoid") then return end

        if not d4cIsKnifeEquipped(char) then
            if VIM then
                pcall(function()
                    VIM:SendKeyEvent(true, Enum.KeyCode.Five, false, false)
                    task.wait(0.1)
                    VIM:SendKeyEvent(false, Enum.KeyCode.Five, false, false)
                end)
            end
            task.wait(0.35)
        else
            task.wait(0.1)
        end

        local currentTool = char and char:FindFirstChildWhichIsA("Tool")
        if currentTool then
            local viewport = camera.ViewportSize
            local centerX = viewport.X / 2
            local centerY = viewport.Y / 2
            for _ = 1, 3 do
                pcall(function()
                    currentTool:Activate()
                    if VIM then
                        VIM:SendMouseButtonEvent(centerX, centerY, 0, true, false, 1)
                        task.wait(0.05)
                        VIM:SendMouseButtonEvent(centerX, centerY, 0, false, false, 1)
                    end
                end)
                task.wait(0.25)
            end
        end
    end

    local function d4cSelectPlayer()
        local input = (Options.D4CTargetPlayer and Options.D4CTargetPlayer.Value or ""):lower():gsub("%s+", "")
        if input == "" then
            d4cSelectedPlayer = nil
            d4cUpdateSelectedLabel()
            return
        end
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Name:lower() == input or (plr.DisplayName and plr.DisplayName:lower() == input) then
                d4cSelectedPlayer = plr
                d4cPreviousRagdollState = false
                d4cUpdateSelectedLabel()
                if Toggles.D4CKnifeThrow and Toggles.D4CKnifeThrow.Value then
                    task.wait(0.4)
                    d4cThrowKnives()
                end
                return
            end
        end
        d4cSelectedPlayer = nil
        d4cUpdateSelectedLabel()
    end

    D4CLeft:AddInput("D4CTargetPlayer", {
        Text = "Target player",
        Default = "",
        Placeholder = "Name or display name…",
    })
    D4CLeft:AddButton({ Text = "Select target", Func = d4cSelectPlayer })

    d4cSelectedLabel = D4CLeft:AddLabel("Selected: None")
    d4cHealthLabel = D4CLeft:AddLabel("Health: N/A")
    d4cKnivesLabel = D4CLeft:AddLabel("Knives left: 0")
    D4CLeft:AddLabel("Equip Knives in hotbar slot 5.", true)
    D4CLeft:AddDivider()

    D4CLeft:AddToggle("D4CAimbot", { Text = "Aimbot (camera to head)", Default = false })
    d4cAimKeyLabel = D4CLeft:AddLabel("Aimbot key: none")
    D4CLeft:AddButton({
        Text = "Set aimbot key",
        Func = function()
            d4cListeningAim = true
            d4cAimKeyLabel:SetText("Aimbot key: press any key…")
        end,
    })

    D4CLeft:AddToggle("D4CKnifeThrow", { Text = "Knife throwing", Default = true })
    d4cKnifeKeyLabel = D4CLeft:AddLabel("Knife key: none")
    D4CLeft:AddButton({
        Text = "Set knife key",
        Func = function()
            d4cListeningKnife = true
            d4cKnifeKeyLabel:SetText("Knife key: press any key…")
        end,
    })

    local function d4cEnableAimbot()
        if d4cAimbotConn then return end
        d4cAimbotConn = RunService.RenderStepped:Connect(function()
            if not Toggles.D4CAimbot or not Toggles.D4CAimbot.Value or not d4cSelectedPlayer then return end
            local char = d4cSelectedPlayer.Character
            if not char or not char:FindFirstChild("Head") then return end
            local headPos = char.Head.Position
            local camPos = camera.CFrame.Position
            camera.CFrame = CFrame.new(camPos, headPos)
            local viewport = camera.ViewportSize
            if VIM then
                VIM:SendMouseMoveEvent(viewport.X / 2, viewport.Y / 2)
            end
            UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
            UIS.MouseIconEnabled = false
        end)
    end

    local function d4cDisableAimbot()
        if d4cAimbotConn then
            d4cAimbotConn:Disconnect()
            d4cAimbotConn = nil
        end
        UIS.MouseBehavior = Enum.MouseBehavior.Default
        UIS.MouseIconEnabled = true
    end

    Toggles.D4CAimbot:OnChanged(function(value)
        if value then d4cEnableAimbot() else d4cDisableAimbot() end
    end)

    UIS.WindowFocused:Connect(function()
        if Toggles.D4CAimbot and Toggles.D4CAimbot.Value and d4cSelectedPlayer then
            task.wait(0.05)
            d4cEnableAimbot()
        end
    end)

    UIS.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        if d4cListeningAim then
            d4cAimKey = input.KeyCode
            d4cListeningAim = false
            d4cAimKeyLabel:SetText("Aimbot key: " .. d4cAimKey.Name)
            return
        end
        if d4cListeningKnife then
            d4cKnifeKey = input.KeyCode
            d4cListeningKnife = false
            d4cKnifeKeyLabel:SetText("Knife key: " .. d4cKnifeKey.Name)
            return
        end
        if d4cAimKey and input.KeyCode == d4cAimKey and Toggles.D4CAimbot then
            Toggles.D4CAimbot:SetValue(not Toggles.D4CAimbot.Value)
        end
        if d4cKnifeKey and input.KeyCode == d4cKnifeKey and Toggles.D4CKnifeThrow then
            Toggles.D4CKnifeThrow:SetValue(not Toggles.D4CKnifeThrow.Value)
        end
    end)

    task.spawn(function()
        while task.wait(0.1) do
            if d4cKnivesLabel then
                d4cKnivesLabel:SetText(string.format("Knives left: %d", d4cGetKnivesCount()))
            end
            d4cUpdateSelectedLabel()

            if not Toggles.D4CKnifeThrow or not Toggles.D4CKnifeThrow.Value or not d4cSelectedPlayer or not d4cSelectedPlayer.Character then
            else
                local hum = d4cSelectedPlayer.Character:FindFirstChild("Humanoid")
                if hum then
                    local percent = (hum.Health / hum.MaxHealth) * 100
                    if d4cHealthLabel then d4cHealthLabel:SetText(string.format("Health: %.0f%%", percent)) end
                    local isRagdolled = hum.PlatformStand
                        or hum:GetState() == Enum.HumanoidStateType.Physics
                        or hum:GetState() == Enum.HumanoidStateType.Ragdoll
                    -- Only auto-throw when they recover from ragdoll (avoids spamming while standing).
                    if d4cPreviousRagdollState and not isRagdolled then
                        task.spawn(function()
                            task.wait(d4cStandUpDelay)
                            if d4cSelectedPlayer and Toggles.D4CKnifeThrow and Toggles.D4CKnifeThrow.Value then
                                d4cThrowKnives()
                            end
                        end)
                    end
                    d4cPreviousRagdollState = isRagdolled
                end
            end
        end
    end)
    end end -- D4C farm
    
    -- [FENTI-22·aimbot] External ESP / silent aim (loads remote Lua; executor-dependent)
    if Tabs.Aimbot then do
    local FENTI_EXTERNAL_AIMBOT_URL = "https://raw.githubusercontent.com/vbbi33jkllljcvvbjkqw89fjjkjhkjzsdaih/dddvbk34vb/refs/heads/main/Aimboitsilentdih.lua"
    local AimbotBox = Tabs.Aimbot:AddLeftGroupbox("External loader", "shield")
    AimbotBox:AddLabel("<font color='#FFAA00'><b>Warning</b></font> — This is only for jews although it doesnt ban through what i tested loads silentaim/esp", true)
    AimbotBox:AddLabel("<font color='#FF6666'><b>Solara/xeno will not run this.</b></font> Use a stronger executor (e.g. <b>Volt</b> or similar)", true)
    AimbotBox:AddLabel("use with ur own descretion and u fat fucking looser aimbotting in this fucking game", true)
    AimbotBox:AddDivider()
    AimbotBox:AddButton({
        Text = "Load external aimbot / ESP",
        Func = function()
            if rawget(_G, "fentiExternalAimbotLoaded") == true then
                Library:Notify(" aimbot already loaded", 4)
                return
            end
            task.spawn(function()
                Library:Notify("Downloading external script…", 3)
                local get, compile = rawget(_G, "fentiHttpGet"), rawget(_G, "loadstring") or loadstring
                if type(get) ~= "function" then
                    Library:Notify("HTTP helper missing — cannot fetch script.", 5)
                    return
                end
                if type(compile) ~= "function" then
                    Library:Notify("loadstring not available on this executor.", 5)
                    return
                end
                local src = get(FENTI_EXTERNAL_AIMBOT_URL)
                if type(src) ~= "string" or #src < 80 then
                    Library:Notify("failed", 5)
                    return
                end
                local chunk, cerr
                do
                    local okc, a, b = pcall(function() return compile(src, "fenti_external_aimbot") end)
                    if okc and type(a) == "function" then chunk, cerr = a, b
                    else
                        local ok2, c, d = pcall(function() return compile(src) end)
                        if ok2 and type(c) == "function" then chunk, cerr = c, d end
                    end
                end
                if type(chunk) ~= "function" then
                    Library:Notify("Compile failed — check F9 Output.", 5)
                    warn("[fenti] external aimbot compile: " .. tostring(cerr))
                    return
                end
                local okRun, runErr = pcall(chunk)
                if not okRun then
                    Library:Notify("Runtime error: " .. tostring(runErr):sub(1, 120), 6)
                    warn("[fenti] external aimbot run: " .. tostring(runErr))
                    return
                end
                rawset(_G, "fentiExternalAimbotLoaded", true)
                Library:Notify("jewjewjewjejwejwej — check in-game (ESP / aim)", 6)
            end)
        end,
    })
    end end -- Aimbot
    
    -- [FENTI-22c] Teleport (locations + move engine only)
    if Tabs.Teleport then do
    local TPLocations = Tabs.Teleport:AddLeftGroupbox("Places", "map-pin")
    TPLocations:AddLabel("Place and prompt teleports use the hub move (no respawn).", true)
    TPLocations:AddDivider()
    TPLocations:AddButton({ Text = "Fishing spot (selected preset)", Func = function()
        smartTeleport(fentiGetFishSpotCFrame()); Library:Notify("Done.", 2)
    end })
    TPLocations:AddButton({ Text = "Safe zone", Func = function() smartTeleport(SAFE_ZONE_POS); Library:Notify("Done.", 2) end })
    
    local TPMoves = Tabs.Teleport:AddRightGroupbox("Move style", "move")
    TPMoves:AddLabel("No kill-respawn. Presets are chosen under <b>Fishing</b> → fishing TP dropdown.", true)
    
    local TPWorld = Tabs.Teleport:AddRightGroupbox("Prompts", "hand")
    TPWorld:AddToggle("AutoCollectChests", { Text = "Auto open chests nearby", Default = true, Callback = function(v)
        _G.AutoCollect = v
        Library:Notify(v and "Chests on" or "Chests off", 2)
    end })
    TPWorld:AddLabel("Chests: fires nearby chest prompts while you move or fish (this toggle).", true)
    pcall(function()
        if Toggles.AutoCollectChests then _G.AutoCollect = Toggles.AutoCollectChests.Value end
    end)
    end end -- Teleport
    
    -- [FENTI-22d] NPCs
    if Tabs.NPCs then do
    local NPCActions = Tabs.NPCs:AddLeftGroupbox("NPC actions", "user")
    local NPCAuto = Tabs.NPCs:AddRightGroupbox("Auto dialogue", "zap")
    
    local npcList = getNPCList()
    NPCActions:AddDropdown("SelectedNPC", { Text = "NPC", Values = npcList, Default = nil, AllowNull = true, Searchable = true })
    NPCActions:AddButton({ Text = "Teleport to NPC", Func = function()
        local sel = Options.SelectedNPC.Value
        if sel and sel ~= "" then teleportToNPC(sel) else Library:Notify("Select an NPC.", 3) end
    end })
    NPCActions:AddButton({ Text = "Talk to NPC", Func = function()
        local sel = Options.SelectedNPC.Value
        if sel and sel ~= "" then _G.fentiTalkToNPC(sel) else Library:Notify("Select an NPC.", 3) end
    end })
    NPCActions:AddButton({ Text = "Fast dialogue", Func = function()
        local sel = Options.SelectedNPC.Value
        if sel and sel ~= "" then _G.fentiDialogue.instaDialogNPC(sel) else Library:Notify("Select an NPC.", 3) end
    end })
    NPCActions:AddButton({ Text = "Refresh NPC list", Func = function()
        local nl = getNPCList(); Options.SelectedNPC:SetValues(nl); Library:Notify(#nl .. " NPCs.", 3)
    end })
    NPCActions:AddDivider()
    NPCActions:AddButton({ Text = "Open bank (Banker)", Func = _G.fentiOpenBank })
    
    NPCAuto:AddLabel("<b>Horse reroll</b>\nSkips dialogue until a rare line.", true)
    NPCAuto:AddDivider()
    Labels.Reroll = NPCAuto:AddLabel("Rerolls: 0")
    NPCAuto:AddToggle("AutoDialogue", { Text = "Auto reroll", Default = false, Callback = function(s)
        autoDialogueEnabled = s
        if s then
            rerollCount = 0
            if Labels.Reroll then Labels.Reroll:SetText("Rerolls: 0") end
            _G.fentiDialogue.startAutoDialogue()
            Library:Notify("Auto-reroll ON", 3)
        else
            _G.fentiDialogue.stopAutoDialogue()
            Library:Notify("Auto-reroll OFF", 3)
        end
    end }):AddKeyPicker("AutoDialogueKeybind", { Default = "T", SyncToggleState = true, Mode = "Toggle", Text = "Auto reroll" })
    end end -- NPCs
    
    -- [FENTI-22·aura] Self aura (Obsidian — same options as your NeverPaste build, no Linoria)
    if Tabs.Aura then do
    local AuraBox = Tabs.Aura:AddLeftGroupbox("Self aura", "sparkles")
    AuraBox:AddDropdown("SelfAura", {
        Text = "Aura",
        Values = {
            "off",
            "glitch aura",
            "sussano",
            "fused zamasu",
            "mui",
            "karma aura",
            "darkseed",
            "aquatic overseer",
            "galactic center",
            "crimsonMoon",
            "six paths",
            "angel",
            "tatas",
        },
        Default = "off",
        Callback = function(v)
            if _G.fentiSelfAuraSetChoice then _G.fentiSelfAuraSetChoice(v) end
        end,
    })
    AuraBox:AddLabel("Client-side visuals only. Choice is saved with Config autoload.", true)
    end end -- Aura
    
    -- [FENTI-22e] Config (menu, theme, save, unload — keep last in sidebar)
    if Tabs.Config then do
    local MenuGroup = Tabs.Config:AddLeftGroupbox("Menu", "wrench")
    MenuGroup:AddToggle("KeybindMenuOpen", { Default = Library.KeybindFrame.Visible, Text = "Open keybind menu", Callback = function(val) Library.KeybindFrame.Visible = val end })
    MenuGroup:AddToggle("ShowCustomCursor", { Text = "Custom cursor", Default = false, Callback = function(val) Library.ShowCustomCursor = val end })
    MenuGroup:AddDropdown("NotificationSide", { Values = {"Left", "Right"}, Default = "Right", Text = "Notification side", Callback = function(val) Library:SetNotifySide(val) end })
    MenuGroup:AddDropdown("DPIDropdown", { Values = {"50%","75%","100%","125%","150%","175%","200%"}, Default = "100%", Text = "DPI scale", Callback = function(val) Library:SetDPIScale(tonumber(val:gsub("%%",""))) end })
    MenuGroup:AddDivider()
    MenuGroup:AddLabel("Menu toggle"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })
    
    MenuGroup:AddDivider()
    MenuGroup:AddButton("Unload script", function()
        failLogWrite("=== UNLOAD " .. os.date() .. " ===")
        isRunning = false
        _G.fentiFishingNoSnap = nil
        chestFarmEnabled = false; espEnabled = false
        corpseFarmEnabled = false; noStunEnabled = false; autoSellFish = false
        killstreakTrackerEnabled = false; antiRagdollEnabled = false
        fentiStopKillstreakTracker(); fentiStopAntiRagdoll()
        triggerbotEnabled = false; noScreenShake = false; autoDialogueEnabled = false; saintsEnabled = false
        saintsAllInOne = false; saintsEspEnabled = false
        VisualSettings.Enabled = false; VisualSettings.EntityEnabled = false
        disableNoScreenShake(); pcall(function() _G.fentiDialogue.stopAutoDialogue() end)
        pcall(function() _G.FentiFarm.stopCorpseListener() end); pcall(function() _G.FentiFarm.stopSaintsMonitor() end)
        pcall(function() _G.FentiFarm.stopSaintsEsp() end)
        stopESP(); pcall(uninstallGetMousePosHook)
        stopTPLoop(); unlockRootMotion()
        if _G.fentiStopFishingPoseHold then pcall(_G.fentiStopFishingPoseHold) end
        fentiRadiusPromptStop = true
        pcall(function()
            if _G.fentiSelfAuraCharConn then
                _G.fentiSelfAuraCharConn:Disconnect()
                _G.fentiSelfAuraCharConn = nil
            end
        end)
        pcall(function() if _G.fentiSelfAuraUnload then _G.fentiSelfAuraUnload() end end)
        for _, c in pairs(activeConnections) do if typeof(c) == "RBXScriptConnection" then c:Disconnect() end end
        Library:Unload()
    end)
    end end -- Config
    
    pcall(function() Library.ToggleKeybind = Options.MenuKeybind end)
    if ThemeManager and SaveManager and Tabs.Config then
        pcall(function()
            ThemeManager:SetLibrary(Library); SaveManager:SetLibrary(Library)
            SaveManager:IgnoreThemeSettings()
            SaveManager:SetIgnoreIndexes({
                "MenuKeybind",
                "ForceSilentNamecall",
                "HookGetMousePosRF",
                "SilentAim",
                "SilentAimAllV3",
                "AimChance",
                "InstantPromptWorld",
            })
            ThemeManager:SetFolder("fenti"); SaveManager:SetFolder("fenti/config")
            -- Obsidian ThemeManager: when no themes/default.txt, LoadDefault uses this (must be before ApplyToTab).
            ThemeManager.DefaultTheme = "Jester"
            SaveManager:BuildConfigSection(Tabs.Config); ThemeManager:ApplyToTab(Tabs.Config)
            ThemeManager:LoadDefault(); SaveManager:LoadAutoloadConfig()
            pcall(function()
                local opt = Options.SelfAura
                local v = opt and opt.Value
                if v and v ~= "" and _G.fentiSelfAuraSetChoice then _G.fentiSelfAuraSetChoice(v) end
            end)
            -- Always apply Jester last so saved default.txt / autoload cannot stick another palette.
            ThemeManager:ApplyTheme("Jester")
            local themeList = ThemeManager.Library.Options and ThemeManager.Library.Options.ThemeManager_ThemeList
            if themeList then pcall(function() themeList:SetValue("Jester") end) end
        end)
    end
    
    end)()
    end
    
    -- ----------------------------------------------------------------------------
    -- [FENTI-23] 23. STARTUP (after UI — keeps main chunk locals down)
    -- ----------------------------------------------------------------------------
    task.spawn(antiAFKLoop)
    -- Do not auto-start corpse RS/workspace listeners: "Everything" preset enables Teleport; games that
    -- use remote/logservice spoofchecks often fingerprint extra DescendantAdded on ReplicatedStorage.
    -- Turn on "Detect Corpse Spawns" in Teleport → Corpse when you want it.
    if LoadModules.Teleport and rawget(_G, "FENTI_AUTO_CORPSE_LISTENER") == true then
        _G.FentiFarm.startCorpseListener()
    end
    
    do
    (function()
        if UIS.TouchEnabled and not UIS.KeyboardEnabled then Library:SetDPIScale(75); Library:Notify("Mobile detected.", 3)
        else
            local kbText = (Options.MenuKeybind and Options.MenuKeybind.Value) or "RightShift"
            Library:Notify("Press " .. kbText .. " to toggle UI.", 5)
        end
        Library:Notify("Tabs: Info · Players · Fishing · Teleport · Saints · NPCs · Aura · Config", 4)
        warn("[fenti] Ready - toggle the menu with your keybind.")
    end)()
    end
    
