-- [[ USER CONFIGURATION ]]
local MY_LICENSE_KEY = "MASUKKAN_KEY_DISINI" -- Pembeli isi ini

-- [[ CLOUD SYSTEM - JANGAN DIUBAH ]]
local API_URL = "http://147.139.250.143:8080/auth?key=" .. MY_LICENSE_KEY:gsub("%s+", "")

-- Helper untuk decode Base64 dari Server
local function decodeB64(data)
    local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    data = string.gsub(data, '[^'..b..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r, f = '', (b:find(x) - 1)
        for i = 6, 1, -1 do r = r .. (f % 2^i - f % 2^(i - 1) > 0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d%d%d%d%d%d', function(x)
        local n = 0
        for i = 1, 8 do n = n + (x:sub(i, i) == '1' and 2^(8 - i) or 0) end
        return string.char(n)
    end))
end

runThread(function()
    log("📡 BGL Script: Menghubungkan ke Cloud...")
    local response, err = fetch(API_URL)

    if err or not response or response == "" then
        error("❌ Server Offline atau Koneksi Bermasalah.")
    end

    if string.find(response, '"status":"success"') then
        log("✅ Auth Success! Loading core script...")
        
        -- Ambil data Base64 dari response server
        local encoded = response:match('"content":"(.-)"')
        local decoded = decodeB64(encoded)

        -- Jalankan kode inti di memori
        local run, loadErr = load(decoded)
        if run then
            run() -- Memulai BGL Harvester
        else
            error("❌ Gagal memuat data core: " .. tostring(loadErr))
        end
    else
        local msg = response:match('"msg":"(.-)"') or "Key Invalid/Expired"
        error("❌ Akses Ditolak: " .. msg)
    end
end)
