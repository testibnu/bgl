
_G.LICENSE_KEY = "MASUKKAN_KEY_DI_SINI" --CODE LICENSE DARI DISCORD

local _G_LICENSE_KEY = "KEY-F5D54E61"
local DEBUG_URL = "https://api.tokodukun.com:8443/auth"

local function debugAuth()
    print("`9[DEBUG] `wMemulai Tes Koneksi ke: " .. DEBUG_URL)
    
    local bodyData = '{"key":"' .. _G_LICENSE_KEY .. '","hwid":"DEBUG-TEST-01"}'
    local headers = {
        ["Content-Type"] = "application/json",
        ["User-Agent"] = "Mozilla/5.0",
        ["Content-Length"] = tostring(#bodyData)
    }

    -- Eksekusi Fetch dengan pcall untuk menangkap crash
    local success, res = pcall(fetch, DEBUG_URL, {
        method = "POST",
        headers = headers,
        body = bodyData,
        timeout = 15000
    })

    if not success then
        -- Kasus 1: Fungsi fetch-nya sendiri yang error (misal: DNS atau SSL fail)
        print("`4[CRITICAL ERROR] `wPcall Failed: " .. tostring(res))
    else
        -- Kasus 2: Fetch jalan, tapi apa isinya?
        print("`2[SUCCESS] `wFetch berhasil dipanggil.")
        
        if type(res) == "table" then
            print("`9[INFO] `wResponse adalah Table.")
            for k, v in pairs(res) do
                -- Kita bongkar semua isi table response (status, body, error, dll)
                print("`b   -> " .. tostring(k) .. ": `w" .. tostring(v))
            end
            
            if res.error then
                print("`4[FETCH ERROR] `wPesan Error: " .. tostring(res.error))
            end
        elseif type(res) == "string" then
            print("`9[INFO] `wResponse adalah String.")
            print("`b   -> Body: `w" .. res)
        else
            print("`4[UNKNOWN] `wTipe data response aneh: " .. type(res))
        end
    end
end

debugAuth()
