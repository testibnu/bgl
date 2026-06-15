local IS_GL=(growtopia~=nil)or(growlauncher~=nil)or(type(addHook)=="function"and type(RemoveHook)=="nil")
local IS_GENTA=(type(AddHook)=="function")
local API_URL="https://vendlocator.sender.my.id/api/public/"
local function xLog(msg)
local txt="`9[VL]`w "..msg
if IS_GL and log then log(txt)
elseif IS_GENTA and doLog then doLog(txt)
else print(txt)end
end
local function xToast(msg)
if IS_GENTA and doToast then doToast(4,2500,msg)end
xLog(msg)
end
local function formatPrice(priceStr)
if not priceStr or priceStr==""then return"?"end
if priceStr:find("/")then return priceStr end
local bglMatch=priceStr:match("(%d+%.?%d*)%s*BGL")
if bglMatch then return tonumber(bglMatch).." BGL"end
local dlMatch=priceStr:match("(%d+%.?%d*)%s*DL")
if dlMatch then return tonumber(dlMatch).." DL"end
local wlMatch=priceStr:match("(%d+%.?%d*)%s*WL")
if wlMatch then return tonumber(wlMatch).." WL"end
local match=priceStr:match("(%d+%.?%d*)")
return match and(tonumber(match).." WL")or priceStr
end
local function shortTime(timeStr)
if not timeStr then return"?"end
local lower=timeStr:lower()
if lower:find("baru")or lower:find("just")then return"baru"
elseif lower:find("menit")then return(lower:match("%d+")or"?").."m"
elseif lower:find("jam")then return(lower:match("%d+")or"?").."j"
elseif lower:find("hari")then return(lower:match("%d+")or"?").."h"
else return"lama"end
end
local function xFetch(url)
if IS_GL then
local ok,res=pcall(fetch,url)
if ok and type(res)=="string"then return res end
elseif IS_GENTA then
local ok,res=pcall(makeRequest,url,"GET",{},"",5000)
if ok and res and res.content then return res.content end
end
return nil
end
local function xWarp(world)
if IS_GL and growtopia and growtopia.warpTo then growtopia.warpTo(world)
elseif IS_GENTA then sendPacket(3,"action|join_request\nname|"..world.."\ninvitedWorld|0")end
end
local function xRunThread(func)
if IS_GL then runThread(func)elseif IS_GENTA then runThread(func,"VL_Thread")end
end
local function parseJSON(str)
if not str then return nil end
local items={}
for name,price,world,time,xtype in str:gmatch('"name":"([^"]-)","price":"([^"]-)","world":"([^"]-)","time":"([^"]-)","type":"([^"]-)"')do
table.insert(items,{name=name,price=price,world=world,time=time,type=xtype})
end
if#items>0 then return{success=true,data=items}end
return nil
end
local function xDialog(dialogStr,fallbackData)
if IS_GL and growtopia and growtopia.sendDialog then growtopia.sendDialog(dialogStr)
elseif IS_GENTA then
xToast("Menampilkan hasil...")
local lp=getLocal()local net=lp and lp.netId or-1
local formats={{"OnDialogRequest",dialogStr},{[0]="OnDialogRequest",[1]=dialogStr},{v0="OnDialogRequest",v1=dialogStr},{v1="OnDialogRequest",v2=dialogStr}}
for _,varList in ipairs(formats)do pcall(sendVariant,varList,-1,0)pcall(sendVariant,varList,net,0)end
if fallbackData and#fallbackData>0 then
xLog("`2==== HASIL ====``")
for i=1,math.min(10,#fallbackData)do
local r=fallbackData[i]
xLog("`w"..i..". `2"..(r.world or"???").." `w- `6"..formatPrice(r.price or"?").." `w(`8"..shortTime(r.time or"baru").."`w)")
end
xLog("`2===============``")
end
end
end
local function getRecentItems()
local url=API_URL.."recent"
local res=xFetch(url)
if not res then return{}end
local data=parseJSON(res)
if data and data.success and data.data then return data.data end
return{}
end
local function searchItem(itemName)
if not itemName or itemName==""then return end
itemName=itemName:gsub("%s+"," "):gsub("^%s+",""):gsub("%s+$","")
xToast("Mencari: "..itemName)
local url=API_URL.."search/"..itemName:gsub(" ","%%20")
local res=xFetch(url)
if not res then return xToast("Koneksi gagal!")end
local data=parseJSON(res)
if not data or not data.success or not data.data or#data.data==0 then return xToast("Tidak ditemukan: "..itemName)end
local results=data.data
local dialog="set_default_color|`o\nadd_label_with_icon|big|`2VendLocator``|left|18|\nadd_spacer|small|\n"
dialog=dialog.."add_textbox|`7Search: `2"..itemName:upper().." `7(`2"..#results.." results`7)|left|\n"
dialog=dialog.."add_spacer|small|\nadd_textbox|`7━━━━━━━━━━━━━━━━━━━━|center|\nadd_spacer|small|\n"
for i,r in ipairs(results)do
if i>15 then break end
local world=r.world or"???"local price=formatPrice(r.price or"?")local time=shortTime(r.time or"baru")local name=r.name or"?"
dialog=dialog.."add_button|warp_"..world.."|`2"..i..". `2"..name.." `7(`6"..price.."`7) `7(`8"..time.."`7) `7-> `2"..world.."`|\n"
end
dialog=dialog.."add_spacer|small|\nadd_textbox|`7━━━━━━━━━━━━━━━━━━━━|center|\n"
dialog=dialog.."add_textbox|`7🌐 vendlocator.sender.my.id|center|\nadd_spacer|small|\n"
dialog=dialog.."add_button|close_vl|`4Tutup`|\nend_dialog|close_vl|\n"
xDialog(dialog,results)
end
local function showHomeDialog()
xToast("Loading...")
local items=getRecentItems()
local dialog="set_default_color|`o\nadd_label_with_icon|big|`2VendLocator``|left|18|\nadd_spacer|small|\n"
dialog=dialog.."add_textbox|`7🌐 vendlocator.sender.my.id|center|\nadd_spacer|small|\n"
dialog=dialog.."add_textbox|`7Commands:|bold|left|\n"
dialog=dialog.."add_textbox|`7  `2/vf`7 - Menu|left|\n"
dialog=dialog.."add_textbox|`7  `2/vf <item>`7 - Cari|left|\n"
dialog=dialog.."add_spacer|small|\nadd_textbox|`7━━━━━━━━━━━━━━━━━━━━|center|\n"
dialog=dialog.."add_textbox|`2Recent Items:|bold|left|\nadd_spacer|small|\n"
if#items==0 then dialog=dialog.."add_textbox|`7(tidak ada data)|center|\n"
else for i,item in ipairs(items)do if i>10 then break end
local world=item.world or"???"local price=formatPrice(item.price or"?")local time=shortTime(item.time or"baru")local name=item.name or"?"
dialog=dialog.."add_button|warp_"..world.."|`2"..i..". `2"..name.." `7(`6"..price.."`7) `7(`8"..time.."`7) `7-> `2"..world.."`|\n"
end end
dialog=dialog.."add_spacer|small|\nadd_textbox|`7━━━━━━━━━━━━━━━━━━━━|center|\n"
dialog=dialog.."add_textbox|`7🔒 Full version di website!|center|\nadd_spacer|small|\n"
dialog=dialog.."add_button|close_vl|`4Tutup`|\nend_dialog|close_vl|\n"
xDialog(dialog,items)
end
local function handleTextPacket(pkt)
if pkt:find("action|input")then
local text=pkt:match("text|(.+)")
if text then
local item=text:match("^/vf%s+(.+)$")
if item and item~=""then xRunThread(function()searchItem(item)end)return true end
if text=="/vf"then xRunThread(function()showHomeDialog()end)return true end
end
end
if pkt:find("buttonClicked|warp_")then
local world=pkt:match("buttonClicked|warp_([%w%d_]+)")
if world then xToast("Warp ke: "..world)xRunThread(function()sleep(100)xWarp(world)end)end
return true
end
if pkt:find("buttonClicked|close_vl")then return true end
return false
end
if IS_GL then
if removeHook then removeHook("onSendPacket")end
addHook(function(type,pkt)if type==2 then return handleTextPacket(pkt)end end,"onSendPacket")
if applyHook then applyHook()end
elseif IS_GENTA then
if RemoveHook then pcall(RemoveHook,"VL_Public")end
AddHook("OnTextPacket","VL_Public",function(flag,pkt)return handleTextPacket(pkt)end)
end
xToast("✅ VendLocator Public!")
xToast("💡 /vf menu | /vf <item> cari")
xToast("🌐 vendlocator.sender.my.id")
