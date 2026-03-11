-- ==========================================
-- Auto-Harvest Science Station V11 (ULTIMATE HARVESTER)
-- (3-Row Snake Original, Fix Stand Pos 4, & Sync Drop)
-- ==========================================

local isAutoDropping = false

function blockDropDialog(var, pkt)
    if isAutoDropping then
        if var.v1 == "OnDialogRequest" and type(var.v2) == "string" then
            if string.find(var.v2, "drop_item") then
                return true 
            end
        end
    end
    return false
end

addHook(blockDropDialog, "onVariant")
applyHook()

runThread(function()
    math.randomseed(os.time())

    -- DAFTAR WORLD DIBALIK (Mundur dari 38 ke 30)
    local worlds = {
        "ykequ", "ooxac"
    }
    
    local whitelist = { "koryeon" }
    local scienceStationID = 928
    local barnDoorID = 886 
    local chemicals = { 914, 916, 918, 920, 924 }
    local totalHarvested = 0
    local harvestSinceLastLongBreak = 0 

    -- SETTING WORLD DROP --
    local dropWorldName = "bhare"
    local dropDoorName = "chemstok"
    ------------------------

    log("🚀 Memulai Bot V11 (ROTASI ORIGINAL + FIX POSISI TENGAH)...")

    -- ==========================================
    -- FUNGSI: Jalan Bertahap
    -- ==========================================
    local function SafeFindPath(destX, destY, distLimit)
        distLimit = distLimit or 1 
        local p = getLocal()
        if not p then return false end
        
        for i = 1, 20 do 
            p = getLocal()
            if not p then return false end
            local curX = math.floor(p.posX / 32)
            local curY = math.floor(p.posY / 32)
            
            if math.abs(curX - destX) <= distLimit and math.abs(curY - destY) <= distLimit then
                return true 
            end
            
            local stepX = curX
            local stepY = curY
            local maxStep = math.random(5, 8) 
            
            if destX > curX then stepX = math.min(curX + maxStep, destX)
            elseif destX < curX then stepX = math.max(curX - maxStep, destX) end
            
            if destY > curY then stepY = math.min(curY + maxStep, destY)
            elseif destY < curY then stepY = math.max(curY - maxStep, destY) end
            
            FindPath(stepX, stepY)
            local reached = await(function()
                local cp = getLocal()
                if not cp then return false end
                local cx = math.floor(cp.posX / 32)
                local cy = math.floor(cp.posY / 32)
                local currentLimit = (stepX == destX and stepY == destY) and distLimit or 1
                return math.abs(cx - stepX) <= currentLimit and math.abs(cy - stepY) <= currentLimit
            end, 2000)
            
            randomSleep(80, 150) 
            
            if not reached then
                log("Mencari celah jalan alternatif...")
                local escapeX = curX + math.random(-1, 1)
                local escapeY = curY + math.random(-1, 1)
                FindPath(escapeX, escapeY)
                randomSleep(200, 300)
                if i > 3 and not reached then return false end
            end
        end
        
        return await(function()
            local cp = getLocal()
            if not cp then return false end
            return math.abs(math.floor(cp.posX/32) - destX) <= distLimit and math.abs(math.floor(cp.posY/32) - destY) <= distLimit
        end, 2000)
    end

    -- ==========================================
    -- FUNGSI: Deteksi Pemain
    -- ==========================================
    local function isWorldSafe()
        local players = getPlayerList()
        local p = getLocal()
        if not p then return false end

        if players and #players > 1 then
            for _, player in pairs(players) do
                if player.netID ~= p.netID then
                    local playerName = string.lower(player.name)
                    local isFriend = false
                    
                    for _, wlName in ipairs(whitelist) do
                        if string.find(playerName, wlName) then
                            isFriend = true; break
                        end
                    end
                    
                    if not isFriend then
                        log("⚠️ TERDETEKSI ORANG ASING: " .. player.name)
                        return false 
                    end
                end
            end
        end
        return true
    end

    -- ==========================================
    -- FUNGSI BANTUAN: Lempar ke Satu Arah (Verifikasi Tas)
    -- ==========================================
    local function dropEverythingHere(targetX, targetY)
        local p = getLocal()
        sendPacketRaw(false, { type = 0, value = 0, x = p.posX, y = p.posY, px = targetX, py = targetY })
        randomSleep(300, 500)
        
        isAutoDropping = true
        local isSpotFull = false
        
        for _, cID in ipairs(chemicals) do
            local amtBefore = growtopia.checkInventoryCount(cID)
            
            if amtBefore > 0 then
                sendPacket(2, "action|drop\nitemID|" .. cID)
                randomSleep(200, 300)
                sendPacket(2, "action|dialog_return\ndialog_name|drop_item\nitemID|" .. cID .. "|\ncount|" .. amtBefore)
                
                randomSleep(800, 1000) 
                
                local amtAfter = growtopia.checkInventoryCount(cID)
                
                if amtAfter >= amtBefore then
                    isSpotFull = true
                    break 
                end
            end
        end
        
        growtopia.sendDialog("")
        isAutoDropping = false
        
        return not isSpotFull
    end

    -- ==========================================
    -- FUNGSI: Cek Stack 200, Drop Cerdas di World Lain
    -- ==========================================
    local function checkAndDrop()
        local needDrop = false
        for _, chemID in ipairs(chemicals) do
            if growtopia.checkInventoryCount(chemID) >= 200 then
                needDrop = true; break
            end
        end

        if needDrop then
            local farmWorld = GetWorldName() 
            
            log("🎒 Tas penuh! Otw drop ke " .. dropWorldName .. "|" .. dropDoorName)
            growtopia.warpTo(dropWorldName .. "|" .. dropDoorName)
            
            local isDropWorldLoaded = await(function()
                local cw = GetWorldName()
                local p = getLocal()
                return cw == string.upper(dropWorldName) and p ~= nil
            end, 15000)

            if not isDropWorldLoaded then
                log("⚠️ Gagal masuk world drop! Menunggu sebentar lalu kembali farm...")
                sleep(3000)
                return false
            end
            
            randomSleep(1500, 2000)

            local allBarnDoors = {}
            for _, t in pairs(getTiles()) do
                if t.fg == barnDoorID or t.bg == barnDoorID then
                    table.insert(allBarnDoors, {x = t.x, y = t.y})
                end
            end
            
            if #allBarnDoors == 0 then
                log("⚠️ TIDAK ADA BARN DOOR DI WORLD INI!")
                sleep(3000)
            else
                for i, door in ipairs(allBarnDoors) do
                    local hasItems = false
                    for _, cID in ipairs(chemicals) do
                        if growtopia.checkInventoryCount(cID) > 0 then hasItems = true; break end
                    end
                    if not hasItems then break end 

                    local isReachedDoor = SafeFindPath(door.x, door.y, 0)
                    
                    if isReachedDoor then
                        log("Mencoba melempar ke KIRI Barn Door #" .. i .. "...")
                        local successLeft = dropEverythingHere(door.x - 1, door.y)
                        
                        hasItems = false
                        for _, cID in ipairs(chemicals) do
                            if growtopia.checkInventoryCount(cID) > 0 then hasItems = true; break end
                        end
                        if not hasItems then break end 
                        
                        log("Sisi KIRI penuh! Putar badan, melempar ke KANAN...")
                        local successRight = dropEverythingHere(door.x + 1, door.y)
                        
                        hasItems = false
                        for _, cID in ipairs(chemicals) do
                            if growtopia.checkInventoryCount(cID) > 0 then hasItems = true; break end
                        end
                        if not hasItems then break end 
                        
                        log("Sisi KANAN juga penuh! Lanjut mencari pintu berikutnya...")
                    else
                        log("Gagal mencapai Barn Door #" .. i)
                    end
                end
            end
            
            log("🔙 Tas sudah kosong. Kembali ke world: " .. farmWorld)
            growtopia.warpTo(farmWorld)
            
            local isFarmWorldLoaded = await(function()
                local cw = GetWorldName()
                local p = getLocal()
                return cw == string.upper(farmWorld) and p ~= nil
            end, 15000)

            if isFarmWorldLoaded then
                randomSleep(1500, 2500)
            end
        end
    end

    -- ==========================================
    -- LOOPING ROTASI WORLD
    -- ==========================================
    for _, worldName in ipairs(worlds) do
        log("-----------------------------------------")
        log("Berpindah ke world: " .. worldName)
        
        growtopia.warpTo(worldName)
        
        local isWorldLoaded = await(function()
            local currentWorld = GetWorldName()
            local p = getLocal()
            return currentWorld == string.upper(worldName) and p ~= nil
        end, 15000)

        if isWorldLoaded then
            randomSleep(2000, 3000) 
            
            local currentStreak = 0
            local targetRest = math.random(30, 60)
            
            for scanPass = 1, 2 do
                local targets = {}
                for _, tile in pairs(getTiles()) do
                    if tile.fg == scienceStationID and tile.readyharvest then
                        table.insert(targets, tile)
                    end
                end

                if #targets > 0 then
                    if scanPass == 1 then
                        log("Ditemukan " .. #targets .. " stasiun di " .. worldName)
                    else
                        log("🔎 SCAN ULANG: Menemukan " .. #targets .. " stasiun yang tertinggal! Membersihkan...")
                    end
                    
                    -- POLA ULAR 3 BARIS (3-Row Snake) ORIGINAL --
                    table.sort(targets, function(a, b)
                        local trackA = math.floor(a.y / 3)
                        local trackB = math.floor(b.y / 3)

                        if trackA == trackB then
                            if a.x == b.x then return a.y < b.y end
                            if trackA % 2 == 0 then return a.x < b.x else return a.x > b.x end
                        end
                        return trackA < trackB
                    end)

                    for _, target in ipairs(targets) do
                        
                        if not isWorldSafe() then
                            log("⚠️ KABUR! ADA ORANG ASING MASUK!")
                            break 
                        end

                        local p = getLocal()
                        if not p then break end 

                        local currentTile = getTile(target.x, target.y)
                        if currentTile.fg == scienceStationID and currentTile.readyharvest then
                            
                            -- ========================================================
                            -- PERBAIKAN: MENGUNCI PATHFINDER DI TITIK TENGAH (POSISI 4)
                            -- ========================================================
                            local track = math.floor(target.y / 3)
                            local standY = (track * 3) + 1  -- Ini adalah koordinat Y tengah (blok ke-2 dari 3)

                            local distanceX = math.abs((math.floor(p.posX / 32)) - target.x)
                            -- Bandingkan jarak bot dengan standY, BUKAN dengan target.y
                            local distanceY = math.abs((math.floor(p.posY / 32)) - standY)
                            
                            -- Bot dianggap sampai jika X sejajar dan Y ada di posisi tengah
                            local isReached = (distanceX <= 1 and distanceY <= 1)

                            if not isReached then
                                -- Perintahkan jalan HANYA ke titik tengah (standY)
                                isReached = SafeFindPath(target.x, standY, 1)
                            end

                            if isReached then
                                local checkAgain = getTile(target.x, target.y)
                                if checkAgain.fg == scienceStationID and checkAgain.readyharvest then
                                    p = getLocal() 
                                    if p then 
                                        
                                        if math.random(1, 100) <= 2 then
                                            sendPacketRaw(false, {
                                                type = 3, value = 18,
                                                x = p.posX, y = p.posY, 
                                                px = target.x + math.random(-1, 1), 
                                                py = target.y + math.random(-1, 1)
                                            })
                                            randomSleep(150, 250)
                                        end

                                        -- Memukul station target (bisa atas, tengah, atau bawah) dari posisi berdiri
                                        sendPacketRaw(false, {
                                            type = 3, value = 18,
                                            x = p.posX, y = p.posY, 
                                            px = target.x, py = target.y
                                        })
                                        
                                        totalHarvested = totalHarvested + 1
                                        currentStreak = currentStreak + 1
                                        harvestSinceLastLongBreak = harvestSinceLastLongBreak + 1
                                        
                                        randomSleep(160, 220) 

                                        if currentStreak >= targetRest then
                                            randomSleep(1000, 2000)
                                            currentStreak = 0 
                                            targetRest = math.random(30, 60) 
                                        end

                                        if harvestSinceLastLongBreak >= math.random(400, 500) then
                                            local afkTimeMin = math.random(1, 2) 
                                            log("🕒 AFK Super Singkat " .. afkTimeMin .. " menit...")
                                            growtopia.sendChat("/sleep")
                                            sleep(afkTimeMin * 60 * 1000) 
                                            harvestSinceLastLongBreak = 0
                                        end

                                        checkAndDrop()
                                    end
                                end
                            end
                        end
                    end
                    
                    if scanPass == 1 then randomSleep(1000, 1500) end
                else
                    if scanPass == 2 then
                        log("✨ World sudah disapu bersih!")
                    end
                    break 
                end
            end
        end
        
        log("Menunggu 10 detik sebelum pindah world...")
        sleep(10000) 
    end
    
    log("=========================================")
    log("MISI SELESAI! Total Panen: " .. totalHarvested)
end)

-- AKHIR DARI SCRIPT --
