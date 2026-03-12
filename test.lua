-- ==========================================================
-- 🌟 PREMIUM AUTO SURGERY SCRIPT (SMART AI VERSION) 🌟
-- ==========================================================
local delay = 180 -- Delay aman (dalam milidetik)
local stats = { saved = 0, toolsUsed = 0 }

-- 1. Daftar ID Tool (Bersih, Rapi, & Mudah dibaca)
local tools = {
    Sponge = 1258, Scalpel = 1260, Anesthetic = 1262,
    Antibiotic = 1266, Splint = 1268, Stitches = 1270,
    FixIt = 1296, Pins = 4308, Transfusion = 4310,
    Defibrillator = 4312, Clamp = 4314, Ultrasound = 4316, LabKit = 4318
}

-- 2. Smart Rule Engine (Prioritas Dieksekusi dari Atas ke Bawah)
local rules = {
    -- 🚨 KONDISI KRITIS (DARURAT)
    { text = "Heart stopped!", tool = "Defibrillator" },
    { text = "screams and flails!", tool = "Anesthetic" },
    { text = "The patient wakes up!", tool = "Anesthetic" },
    { text = "Coming to", tool = "Anesthetic" },
    { text = "Awake", tool = "Anesthetic" },
    
    -- 🩸 PENDARAHAN & DETAK JANTUNG
    { text = "losing blood `4very quickly", tool = "Clamp" },
    { text = "losing blood `4very quickly", tool = "Stitches" }, -- Backup jika Clamp habis
    { text = "losing blood!", tool = "Stitches" },
    { text = "Pulse: `4", tool = "Transfusion" },
    { text = "Pulse: `6", tool = "Transfusion" },
    
    -- 🌡️ INFEKSI / SUHU BADAN TINGGI
    { text = "Temp: `4", tool = "Antibiotic" },
    { text = "Temp: `6", tool = "Antibiotic" },
    { text = "Temp: `3", tool = "Antibiotic" },
    
    -- 🦴 TULANG PATAH / HANCUR
    { text = "shattered", tool = "Pins" },
    { text = "shattered", tool = "Scalpel" }, -- Terkadang butuh disayat dulu
    { text = "broken", tool = "Splint" },
    
    -- 🩺 DIAGNOSA & LAINNYA
    { text = "has not been diagnosed", tool = "Ultrasound" },
    { text = "can't see what you are doing", tool = "Sponge" },
    { text = "Incisions: `20", tool = "FixIt" },
    { text = "Incisions: `30", tool = "FixIt" }
}

-- 3. Fungsi Utama Klik Tool (Local Function Anti-Bocor)
local function useTool(toolName)
    local id = tools[toolName]
    if not id then return end
    
    runThread(function()
        sleep(delay)
        sendPacket(2, "action|dialog_return\ndialog_name|surgery\nbuttonClicked|tool" .. id)
        
        -- Tracker Live
        stats.toolsUsed = stats.toolsUsed + 1
        log("`9[`4AUTO-SURG`9] `aGunakan: `e" .. toolName .. " `o(Total Pakai: " .. stats.toolsUsed .. "x)")
    end)
end

-- 4. Hook Pembaca Dialog (Pengganti if-else yang panjang)
local function onVariant(v)
    -- Pastikan packet valid untuk loader Anda
    if not v or not v.v1 or not v.v2 then return false end
    local event = v.v1
    local dialog = v.v2

    -- Jika mendapat notifikasi sukses menyelamatkan pasien
    if event:find("OnConsoleMessage") and dialog:find("`2YOU SAVED YOUR PATIENT!") then
        stats.saved = stats.saved + 1
        log("`9[`2SUCCESS`9] `aPasien Diselamatkan! `o(Total Sukses: `2" .. stats.saved .. "`o)")
        return true
    end

    -- Jika popup Dialog Surgery Muncul
    if event:find("OnDialogRequest") and dialog:find("surgery") then
        
        -- Looping ke dalam Rule Engine kita
        for _, rule in ipairs(rules) do
            -- Jika teks gejala cocok DAN tombol tool tersebut tersedia di layar
            if dialog:find(rule.text) and dialog:find("tool" .. tools[rule.tool]) then
                useTool(rule.tool)
                return true
            end
        end
        
        -- KONDISI FALLBACK (Jika tidak ada kondisi darurat, lakukan sayatan / bersihkan)
        if dialog:find("tool" .. tools.Scalpel) then
            useTool("Scalpel")
            return true
        elseif dialog:find("tool" .. tools.Sponge) then
            useTool("Sponge")
            return true
        end
    end

    return false
end

-- 5. Pemasangan Hook ke Loader
AddHook(onVariant, "OnVariant")
-- Jika loader Anda menggunakan standar huruf kecil, ganti baris di atas menjadi: addHook("OnVariant", "PremiumSurg", onVariant)

log("`9[`ePREMIUM SURG`9] `aScript Smart AI Aktif! `oMenunggu pasien...")
