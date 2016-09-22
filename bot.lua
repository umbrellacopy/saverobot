local function kmake(rows)
local kb = {}
kb.keyboard = rows
kb.resize_keyboard = true
kb.selective = true
return kb
end
local function kmakerow(texts)
local row = {}
for i=1 , #texts do
row[i] = {text=URL.escape(texts[i])}
end
return row
end
local function start_menu()
local rw1_texts = {'لیست پیام های ذخیره شده','حذف تمامی پیام های ذخیره شده'}
local rw2_texts = {'امار'}
local rw3_texts = {'درباره ما','راهنمای استفاده'}
local rows ={kmakerow(rw1_texts),kmakerow(rw2_texts),kmakerow(rw3_texts)}
return kmake(rows)
end
local function action(msg)
if msg.text == '/start' then
db:hset('bot:waiting',msg.chat.id,'main')
local start = [[
سلام دوست من به ربات ذخیره کننده خوش اومدید این ربات هرچیزی رو به اون ارسال کنید ذخیره میکنه و بعدا میتونید از همه اونا اک اپ گرفته یا به ایمیلتون ارسال کنید یا ....
]]
api.sendMessage(msg.chat.id, start, true,msg.message_id, true,start_menu())
return
elseif msg.text == '/init' and msg.chat.id == bot_sudo then
bot_init(true)
api.sendReply(msg, '*Reloaded!*', true)
return
elseif msg.text == '/stats' and msg.chat.id == bot_sudo then
api.sendReply(msg, '*Bot users : '..db:hlen('bot:waiting')..'*', true)
return
elseif msg.text and msg.text:match('^/s2au .*$') and msg.from.id == bot_sudo then
local pm = msg.text:match('^/s2au (.*)$')
local suc = 0
local ids = db:hkeys('bot:waiting')
if #ids ~= 0 then
for i=1,#ids do
local ok,desc = api.sendMessage(ids[i], pm,false, false, false, false,false,true)
print('Sent', ids[i])
if ok then
suc = suc +1
end
end
api.sendReply(msg, 'Msg sended to '..#ids..'user, '..suc..' success and '..(#ids - suc)..' fail!')
return
else
api.sendReply(msg, 'No User Found!')
return
end
elseif msg.text == '/f2au' and msg.from.id == bot_sudo and msg.reply then
local suc = 0
local ids = db:hkeys('bot:waiting')
if #ids ~= 0 then
for i=1,#ids do
local ok,desc = api.forwardMessage(ids[i], msg.reply.chat.id,msg.reply.message_id, true)
print('Sent', ids[i])
if ok then
suc = suc +1
end
end
api.sendReply(msg, 'Msg forwarded to '..#ids..'user, '..suc..' success and '..(#ids - suc)..' fail!')
return
else
api.sendReply(msg, 'No User Found!')
return
end
elseif msg.text == 'راهنمای استفاده' then
local help = [[
روش استفاده از ربات:
`پیامی فرستاده یا فوروارد کنید ربات این پیام را ذخیره کرده و بعدا میتوانید ان را بارگیری کنید
قابلیت ها : 
1 - گرفتن پیام ذخیره شده
2 - حذف پیام ذخیره شده
3 - لیست پیام ذخیره شده
4 - ارسال به ایمیل (درحال تکمیل)
`

روش استفاده از قابلیت اینلاین:
`درحال تکمیل.`
]]
api.sendMessage(msg.chat.id, help, true,msg.message_id, true,start_menu())
return
elseif msg.text == 'درباره ما' then
local pms = [[
*Save Robot* _v 1_

`ربات ذخیره ساز محصولی از` [تیم آمبرلا کپی](https://telegram.me/umbrellacopy)
]]
local keyboard = {}
    keyboard.inline_keyboard = {
{
{text = "Channel" , url = 'https://telegram.me/UmbrellaCopy'},
{text = "Source" , url = 'https://github.com/UmbrellaCopy/saverobot'},
{text = "RoBoT" , url = 'https://telegram.me/saverobot'}
}
}
api.sendMessage(msg.chat.id, pms, true,msg.message_id, true,keyboard)
return
end
local setup = db:hget('bot:waiting',msg.chat.id)
if setup == 'main' then
if msg.text and msg.text:match('^/get (%d+)$') then
local pnum = tonumber(msg.text:match('^/get (%d+)$'))
local m = db:hget('pms'..msg.chat.id,pnum)
if not m then
api.sendReply(msg,'پیام یافت نشد.')
return
end
m = json:decode(m)
local mmsg = api.forwardMessage(msg.chat.id, m.chat.id,m.message_id)
if m.forward_from_chat then
local musername = 'ندارد'
if m.forward_from_chat.username then
musername = '@'..m.forward_from_chat.username
end
api.sendReply(mmsg.result,'پیام فرستاده شده توسط کانال : '..(m.forward_from_chat.title or 'کانالی پاک شده')..' ['..m.forward_from_chat.id..'] ('..musername..')')
elseif m.forward_from then
local musername = 'ندارد'
if m.forward_from.username then
musername = '@'..m.forward_from.username
end
api.sendReply(mmsg.result,'پیام فرستاده شده توسط کاربر : '..(m.forward_from.first_name or 'کاربری پاک شده')..' ['..m.forward_from.id..'] ('..musername..')')
end

elseif msg.text and msg.text:match('^/del (%d+)$') then
local pnum = tonumber(msg.text:match('^/del (%d+)$'))
local m = db:hget('pms'..msg.chat.id,pnum)
if not m then
api.sendReply(msg,'پیام یافت نشد.')
return
end
db:hdel('pms'..msg.chat.id,pnum)
api.sendReply(msg,'پیام با موفقیت حذف شد')
elseif msg.text == 'لیست پیام های ذخیره شده' then
local pms = db:hkeys('pms'..msg.chat.id)
if #pms == 0 then
api.sendReply(msg,'هیچ پیامی وجود ندارد.')
return
end
local text = 'لیست پیام های ذخیره شده شما :\n'
for i,v in pairs(pms) do
text = text..'پیام '..i..'\nگرفتن با \n/get '..v..'\nحذف با \n/del '..v..'\n====\n'
end
api.sendReply(msg,text)
elseif msg.text == 'حذف تمامی پیام های ذخیره شده' then
db:del('pms'..msg.chat.id)
api.sendReply(msg,'همه پیام های شما با موفقیت حذف شد.')
elseif msg.text == 'امار' then
local numt = 0
local numf = 0
local numa = 0
local numd = 0
local nump = 0
local nums = 0
local numvi = 0
local numvo = 0
local numc = 0
local numl = 0
local numve = 0
local pms = db:hvals('pms'..msg.chat.id)
for i,m in pairs(pms) do
m = json:decode(m)
if m.text then
numt = numt + 1
end
if m.audio then
numa = numa + 1
end
if m.document then
numd = numd + 1
end
if m.photo then
nump = nump + 1
end
if m.sticker then
nums = nums + 1
end
if m.video then
numvi = numvi + 1
end
if m.voice then
numvo = numvo + 1
end
if m.contact then
numc = numc + 1
end
if m.location then
numl = numl + 1
end
if m.venue then
numve = numve + 1
end
if m.forward_from or m.forward_from_chat then
numf = numf + 1
end
end
local edit_asl = '`کل پیام های ذخیره شده ها : `*'..db:hlen('pms'..msg.chat.id)..'*\n`پیام های متنی : `*'..numt..'*\n`پیام های فروارد شده : `*'..numf..'*\n`پیام های صوتی : `*'..numa..'*\n`پیام های فایلی : `*'..numd..'*\n`پیام های استیکری : `*'..nums..'*\n`پیام های ویدیویی : `*'..numvi..'*\n`پیام های وویسی : `*'..numvo..'*\n`پیام های شماره اشتراک گذاری شده : `*'..numc..'*\n`پیام های مکان اشتراک گذاری شده : `*'..numl..'*\n`پیام های ونیو : `*'..numve..'*'
api.sendMessage(msg.chat.id, edit_asl, true,msg.message_id)
else
mkeys = db:hkeys('pms'..msg.chat.id)
mlen = 0
if #mkeys ~= 0 then
for i,v in pairs(mkeys) do
if tonumber(v) > mlen then
mlen = tonumber(v)
end
end
end
db:hset('pms'..msg.chat.id,tostring(mlen + 1),json:encode(msg))
api.sendReply(msg,'پیام شما ذخیره شد برای گرفتن محتوای پیام از \n/get '..(mlen + 1)..'\n و برای حذف پیام از \n/del '..(mlen + 1)..'\nاستفاده کنید')
end
end
end

local function iaction(inline)
local qresult = {}
local name = db:hget('bot:name',inline.from.id)
if name then
local number = db:hget('bot:number',inline.from.id)
if number then
local result = {}
result.id = tostring(#qresult + 1)
 result.type = 'contact'
 result.thumb_url = URL.escape('http://apktools.ir/wp-content/uploads/2016/07/telegram-icon.png')
 result.first_name = URL.escape(name)
 result.phone_number = URL.escape(number)
  qresult[#qresult + 1] = result
end
local result = {}
result.id = tostring(#qresult + 1)
 result.type = 'article'
 result.thumb_url = URL.escape('http://opload.ir/im/6m95/bf945d3115d93.jpg')
 result.description = URL.escape('اینجا کلیک کنید تا مشخصات شما ارسال شود')
 result.title = URL.escape('ارسال مشخصات')
local age = db:hget('bot:age',inline.from.id)
local loc = db:hget('bot:loc',inline.from.id)
local savad = db:hget('bot:savad',inline.from.id)
local rabete = db:hget('bot:rabete',inline.from.id)
local site = db:hget('bot:site',inline.from.id)
local channel = db:hget('bot:channel',inline.from.id)
local insta = db:hget('bot:instagram',inline.from.id)
local text = name
if age then
text = text .. '\n'..age.. ' ساله'
end
if loc then
text = text .. '\nاز '..loc
end
if savad then
text = text .. '\n'..savad
end
if rabete then
text = text .. '\n'..rabete
end
local keyboard = {}
local inkb = {}
if site then
inkb[(#inkb + 1)] = {text=URL.escape('سایت'),url=URL.escape('http://'..site)}
end
if insta then
inkb[(#inkb + 1)] = {text=URL.escape('اینستا'),url=URL.escape('http://instagram.com/'..insta)}
end
if channel then
inkb[(#inkb + 1)] = {text=URL.escape('کانال'),url=URL.escape('https://telegram.me/'..channel)}
end
keyboard.inline_keyboard={inkb}
if channel or insta or site then
result.reply_markup = keyboard
end
 result.message_text = URL.escape(text..'\n⛱ @uc_ASLrobot')
 qresult[#qresult + 1] = result
api.sendInline(inline.id, qresult,0)
else
local result = {}
result.id = tostring(#qresult + 1)
 result.type = 'article'
 result.thumb_url = URL.escape('http://seemorgh.com/images/content/news/1394/02/0000000000000000000000000011errrrerW.jpg')
 result.description = URL.escape('شما اطلاعات خود را ثبت نکردید، به ربات مراجعه کنید و اقدام به ثبت اطلاعات خود نمایید')
 result.title = URL.escape('اطلاعات موجود نیست')
result.message_text = URL.escape('شما هنوز اطلاعات خود را ثبت نکردید، به ربات مراجعه کنید و اقدام به ثبت اطلاعات خود نمایید')
keyboard = {}
keyboard.inline_keyboard = {{{text=URL.escape('ثبت مشخصات در ربات'),url=URL.escape('https://telegram.me/uc_aslrobot')}}}
result.reply_markup = keyboard
 qresult[#qresult + 1] = result
api.sendInline(inline.id, qresult,0)
end
end


return {
action = action,
iaction = iaction
}