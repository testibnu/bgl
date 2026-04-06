-- ==========================================================
-- 🛠️ FULL DEBUG LOADER (CONNECTION + DECRYPTION) 🛠️
-- ==========================================================
_G.LICENSE_KEY = "KEY-F5D54E61"
local DEBUG_URL    = "https://api.tokodukun.com:8443/auth"
local SECRET_PASS  = "BAGEL_SuperS3cr3t_2026!@#" -- Secret sudah ada di sini

local function printDebug(msg)
    print("`9[DEBUG] `w" .. msg)
end

local function runFullDebug()
    printDebug("Memulai tes ke: " .. DEBUG_URL)
    
    local bodyData = '{"key":"' .. _G.LICENSE_KEY .. '","hwid":"DEBUG-TEST-01"}'
    local headers = {
        ["Content-Type"] = "application/json",
        ["Accept"] = "application/json",
        ["User-Agent"] = "Mozilla/5.0",
        ["Content-Length"] = tostring(#bodyData)
    }

    printDebug("Mengirim POST Body: " .. bodyData)

    -- 1. TES KONEKSI (FETCH)
    local success, res = pcall(fetch, DEBUG_URL, {
        method = "POST",
        headers = headers,
        body = bodyData,
        timeout = 15000
    })

    if not success then
        print("`4[FAIL] `wPcall Error (Fungsi fetch crash): " .. tostring(res))
        return
    end

    -- 2. ANALISIS RESPONSE
    local rawBody = ""
    if type(res) == "table" then
        printDebug("Response adalah TABLE. Memeriksa isinya...")
        if res.error then print("`4[FAIL] `wFetch Error: " .. tostring(res.error)) end
        rawBody = res.body or res.content or ""
        printDebug("HTTP Status: " .. tostring(res.status or "Unknown"))
    else
        rawBody = tostring(res)
        printDebug("Response adalah STRING.")
    end

    if rawBody == "" then
        print("`4[FAIL] `wServer mengirim body kosong (Offline/Blocked).")
        return
    end

    printDebug("Raw Data dari Server: " .. rawBody)

    -- 3. PARSING DATA
    local status  = rawBody:match('"status"%s*:%s*"?(%w+)"?')
    local content = rawBody:match('"content"%s*:%s*"([^"]+)"')

    if status == "success" and content then
        print("`2[OK] `wAutentikasi Berhasil. Mencoba dekripsi...")
        
        -- Fungsi Dekripsi Internal (Cepat)
        local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
        local function dec64(data)
            data = string.gsub(data, '[^'..b64chars..'=]', '')
            return (data:gsub('.', function(x)
                if (x == '=') then return '' end
                local r,f='',(b64chars:find(x)-1)
                for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
                return r;
            end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
                if (#x ~= 8) then return '' end
                local c=0
                for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
                return string.char(c)
            end))
        end

        local function xor(data, key)
            local bit = bit or _G.bit or (require and pcall(require, "bit") and require("bit"))
            local bxor = bit and bit.bxor or function(a,b) return a + b end -- Simple fallback
            local res = ""
            for i=1,#data do
                res = res .. string.char(bxor(data:byte(i), key:byte((i-1)%#key+1)))
            end
            return res
        end

        local success_dec, final_script = pcall(function()
            return xor(dec64(content), SECRET_PASS)
        end)

        if success_dec then
            print("`2[SUCCESS] `wScript berhasil didekripsi!")
            printDebug("Panjang Script: " .. #final_script .. " karakter.")
            -- load(final_script)() -- Jangan di-load dulu, kita cuma debug
        else
            print("`4[FAIL] `wDekripsi Gagal: " .. tostring(final_script))
        end
    else
        local msg = rawBody:match('"msg"%s*:%s*"([^"]+)"')
        print("`4[FAIL] `wServer Menolak: " .. (msg or "Unknown Error"))
    end
end

runFullDebug()
