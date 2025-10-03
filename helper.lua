function console(b, a)
    SendVarlist({[0] = "OnConsoleMessage", [1] = a and "[`4ERROR``] " or "[`4Nov4``] " .. b,netid = -1})
end

if GetLocal().world == "" or GetLocal().world == 'EXIT' then
    console('`4Run at world!!!',1)
    return
end
if GetLocal().name == '' then
    console('Please dont hide your name')
    return
end

usernames = GetLocal().name
userentered = GetLocal().userid

function makeRequest(url, method)
    local command =
        string.format(
        'powershell -WindowStyle Hidden -Command "(Invoke-WebRequest -Uri \'%s\' -Method %s).Content"',
        url,
        method
    )
    local handle = io.popen(command)
    local result = handle:read("*a")
    handle:close()
    return {content = result}
end

local json = load(makeRequest("https://raw.githubusercontent.com/LuaDist/dkjson/refs/heads/master/dkjson.lua", "GET").content)()
local base64 = load(makeRequest("https://raw.githubusercontent.com/iskolbin/lbase64/refs/heads/master/base64.lua","GET").content)()

function convert(a)
    SendPacketRaw({type = 10,int_data = a})
end

local logspin = {}

function rainbow(a)
    math.randomseed(os.time())
    local aa = ""
    for i = 1, #a do
        local char = a:sub(i, i)
        if char ~= " " then
            local color = tostring(math.random(1, 9))
            aa = aa .. "`" .. color .. char .. "``"
        else
            aa = aa .. " "
        end
    end
    return aa
end

function splitp(p)
    local result = {}
    for param in (p or ""):gmatch("%S+") do
        result[#result + 1] = param
    end
    return result
end

function getBgl(x ,y)
    SendPacket(2,'action|dialog_return\ndialog_name|phonecall\ntilex|'.. x .. '|\ntiley|' .. y .. '|\nnum|-34|\nbuttonClicked|turnin\n')
end

function getinv(id)
    for _, i in pairs(GetInventory()) do
        if i.id == id then
            return i.count
        end
    end
    return 0
end

function lockbalance()
    return (getinv(242) or 0) + ((getinv(7188) or 0) * 10000) + ((getinv(1796) or 0) * 100)
end

function banks(m, amount)
    local a = "action|dialog_return\ndialog_name|my_bank_account\nbuttonClicked|"
    if m == "depo" then
        return SendPacket(2, a .. "depo_true\n\nbgl_|" .. amount)
    elseif m == "wd" then
        return SendPacket(2, a .. "wd_true\n\nwd_amount|" .. amount)
    end
   return nil
end

local NOTIFIER_ITEM_NAMES = {
    [242] = "World Lock",
    [1796] = "Diamond Lock",
    [7188] = "Blue Gem Lock",
    [17240] = "Absolute Lock"
}

function state(z, x, y)
    SendPacketRaw({type = 0, pos_x = x, pos_y = y, flags = z})
end

function drop(id, count, facing, x, y)
    state(facing, x, y)
    SendPacket(2, string.format([[action|dialog_return
dialog_name|drop_item
itemID|%d|
count|%d]], id, count))
    local item_name = NOTIFIER_ITEM_NAMES[id]
    if item_name then
        local CHAT_PREFIX = "`9[`4@Nov4`9] Dropped "
        local chat_message = CHAT_PREFIX .. "`2" .. count .. " `5" .. item_name
        local packet_to_send = "action|input\n|text|" .. chat_message
        SendPacket(2, packet_to_send)
    end
end

function cdrop(amount, facing, x, y)
    if amount > lockbalance() then
        return console("Balance tidak mencukupi", 1)
    end
    bgl = (amount >= 10000) and (math.floor(amount / 10000)) or 0
    dl = (amount >= 100) and (math.floor(amount % 10000 / 100)) or 0
    wl = (amount >= 1) and (math.floor(((amount % 10000) % 100))) or 0
    if wl and wl > 0 then
        drop(242, wl, facing, x, y)
    end
    if dl and dl > 0 then
        drop(1796, dl, facing, x, y)
    end
    if bgl and bgl > 0 then
        drop(7188, bgl, facing, x, y)
    end
end

local SPAM = {ENABLE = false, DELAY = 0, TEXT = ""}

local dialogspam = function()
    local abcd = string.format(
        [[
set_default_color|`0
add_label_with_icon|big|Auto Spam Configuration|left|32|
add_smalltext|Nov4|left|
add_spacer|small|
add_smalltext|Auto Spam %s|left|
add_spacer|small|
add_label_with_icon|small|`0Set Message :|left|1752|
add_text_input|nov4spam_message||%s|250|
add_spacer|small|
add_label_with_icon|small|`0Set Delay in second :|left|1482|
add_text_input|nov4spam_delay||%d|4|
add_spacer|small|
add_button|nov4spam_setconfig|Set Config|noflags|0|0| 
add_button|nov4spam_setup|%s|noflags|0|0|
add_quick_exit|
]],SPAM.ENABLE and "`2Running``" or "`4Stopped``",
    SPAM.TEXT,
    SPAM.DELAY,
    SPAM.ENABLE and "`4Stop" or "`2Start")
    SendVarlist({[0] = "OnDialogRequest", [1] = abcd, netid = -1})
end

local rainbowchat = false
local pullwrench = false
local fasttake = false
function pull(netid)
    SendPacket(2,string.format([[action|dialog_return
dialog_name|popup
netID|%s|
buttonClicked|pull]],netid))
end

function getplayers(x)
    for _, p in pairs(GetPlayers()) do
        if p.netid == x then
            return p.name
        end
    end
    return ""
end

function takelock(x,y)
    local pos1 = {x = x * 32 - 6, y = y * 32 - 2}
    local pos2 = {x = (x + 1) * 32 - 6, y = (y + 1) * 32 - 2}
    for _, object in pairs(GetObjects()) do
        if object.pos_x >= pos1.x and object.pos_x <= pos2.x then
            if object.pos_y >= pos1.y and object.pos_y <= pos2.y then
                if object.id == 242 or object.id == 7188 or object.id == 1796 or object.id == 16990 then
                    SendPacketRaw({type = 11,int_data = object.oid,pos_x = GetLocal().pos_x,pos_y = GetLocal().pos_y})
                    Sleep(60)
                end
            end
        end
    end
end

local is_collect_notifier_enabled = true
local TARGET_LOCK_NAMES = {
    ["World Lock"] = true,
    ["Diamond Lock"] = true,
    ["Blue Gem Lock"] = true,
}

function OnCollectedNotifier(v, p)
    if not is_collect_notifier_enabled then return false end
    if v[0] == "OnConsoleMessage" then
        local message = v[1]
        local count, item_name_raw = string.match(message, 'Collected `w(%d+) (.-)``')
        if count and item_name_raw then
            local item_name = item_name_raw:gsub("%. Rarity: `w%d+", "")
            item_name = item_name:match("(.+)%s*$") or item_name
            if TARGET_LOCK_NAMES[item_name] then
                local CHAT_PREFIX = "`9[`4@Nov4`9] Collected " 
                local chat_message = CHAT_PREFIX .. "`2" .. count .. " `5" .. item_name
                local packet_to_send = "action|input\n|text|" .. chat_message
                SendPacket(2, packet_to_send)
                return false 
            end
        end
    end
    return false
end

local cmd = {
    ["wp"] = {
        func = function(world)
            if world ~= "" then
                console("Going to " .. world)
                SendPacket(3, "action|join_request\nname|" .. world .. "\ninvitedWorld|0")
                return
            end
            console("Usage : /wp `9<worldname>", 1)
        end,
        desc = "Warping to another world!",
        usage = "/wp <`2worldname``>",
        label = 3802
    },
    ["drop"] = {
        func = function(par)
            local args = splitp(par)
            local itemid, amount = tonumber(args[1]), tonumber(args[2])
            if not itemid or not amount then
                console("Usage: /drop `9<itemid> <amount>", 1)
                return
            end
            local facing, x, y = GetLocal().facing_left and 48 or 32, GetLocal().pos_x, GetLocal().pos_y
            drop(itemid, amount, facing, x, y)
        end,
        desc = "Drop Item From your backpack using ItemID",
        usage = "/drop <`2itemid``> <`2amount``>",
        label = 448
    },
    ["wd"] = {
        func = function(amount)
            if tonumber(amount) then
                banks("wd",amount)
                console('Withdraw '..amount..' From Banks')
                return
            end
            console('Usage : /wd `9<amount>``',1)
        end,
        desc = 'Withdraw BGL From Bank',
        usage = '/wd <`2amount``>',
        label = 7188
    },
    ['ft'] = {
        func = function()
            fasttake = not fasttake
            console(string.format('Succes %s Fast Take!', fasttake and "`2Enable``" or "`4Disable``"))
        end,
        desc = 'Fast Take Lock from Display Box! (Punch Display for take all lock in display!)',
        usage = '/ft',
        label = 1422
    },
    ["depo"] = {
        func = function(amount)
            if tonumber(amount) then
                banks("depo",amount)
                console('Deposit '..amount..' BGL to the bank')
                return
            end
            console('Usage : /wd `9<amount>``',1)
        end,
        desc = 'Deposit BGL to the Bank',
        usage = '/depo <`2amount``>',
        label = 7188
    },
    ["wl"] = {
        func = function(num)
            local count = tonumber(num)
            if count then
                local facing, x, y = GetLocal().facing_left and 48 or 32, GetLocal().pos_x, GetLocal().pos_y
                drop(242, count, facing, x, y)
                return
            end
            console("Usage : /wl `9<amount>", 1)
        end,
        desc = "Shortcut Dropping World Lock",
        usage = "/wl <`2amount``>",
        label = 242
    },
    ["dl"] = {
        func = function(num)
            local count = tonumber(num)
            if count then
                local facing, x, y = GetLocal().facing_left and 48 or 32, GetLocal().pos_x, GetLocal().pos_y
                drop(1796, count, facing, x, y)
                return
            end
            console("Usage : /dl `9<amount>", 1)
        end,
        desc = "Shortcut Dropping Diamond Lock",
        usage = "/dl <`2amount``>",
        label = 1796
    },
    ["bgl"] = {
        func = function(num)
            local count = tonumber(num)
            if count then
                local facing, x, y = GetLocal().facing_left and 48 or 32, GetLocal().pos_x, GetLocal().pos_y
                drop(7188, count, facing, x, y)
                return
            end
            console("Usage : /bgl `9<amount>", 1)
        end,
        desc = "Shortcut Dropping Blue Gem Lock",
        usage = "/bgl <`2amount``>",
        label = 7188
    },
    ["wx"] = {
        func = function(params)
            local total_bgl, multiplier = params:match("^(%d+)x(%d+)$")
            if not total_bgl or not multiplier then
                console("Usage : /wx `9<total_bgl>x<multiplier>", 1)
                return
            end
            total_bgl = tonumber(total_bgl)
            multiplier = tonumber(multiplier)
            local result = total_bgl * multiplier
            if getinv(7188) < result then
                console("`4BGL not enough " .. result .. " BGL!", 1)
                return
            end
            local facing, x, y = GetLocal().facing_left and 48 or 32, GetLocal().pos_x, GetLocal().pos_y
            state(facing, x, y)
            SendPacket(2, string.format([[action|dialog_return
dialog_name|drop_item
itemID|%d|
count|%d]], 7188, result))
            local win_message = "`9[`4@Nov4`9] Dropped " .. result .. " Blue Gem Lock."
            SendPacket(2, "action|input\n|text|" .. win_message)
        end,
        desc = "Auto drop BGL with multiplier and custom message.",
        usage = "/wx <`2total_bgl``>x<`2multiplier``>",
        label = 7188
    },
    ['pf'] = {
        func = function()
            pullwrench = not pullwrench
            console(string.format('Succes %s Fast Pull',pullwrench and "`2Enable``" or "`4Disable``"))
        end,
        desc = "Fast Pull using Wrench",
        usage = "/pf",
        label = 32
    },
    ["da"] = {
        func = function(num)
            local count = tonumber(num)
            if count then
                local facing, x, y = GetLocal().facing_left and 48 or 32, GetLocal().pos_x, GetLocal().pos_y
                drop(17240, count, facing, x, y)
                return
            end
            console("Usage : /da `9<amount>", 1)
        end,
        desc = "Shortcut Dropping Absolute Lock",
        usage = "/da <`2amount``>",
        label = 17240
    },
    ['dall'] = {
        func = function()
            local facing, x, y = GetLocal().facing_left and 48 or 32, GetLocal().pos_x, GetLocal().pos_y
            RunThread(function()
                if getinv(242) ~= 0 then
                    drop(242,getinv(242),facing,x,y)
                    Sleep(50)
                end
                if getinv(1796) ~= 0 then
                    drop(1796,getinv(1796),facing,x,y)
                    Sleep(50)
                end
                if getinv(7188) ~= 0 then
                    drop(7188,getinv(7188),facing,x,y)
                    Sleep(50)
                end
            end)
        end,
        desc = "Dropping All BGL / DL / WL in Inventory",
        usage = "/dall",
        label = 1422
    },
    ["cd"] = {
        func = function(num)
            local count = tonumber(num)
            if count then
                local facing, x, y = GetLocal().facing_left and 48 or 32, GetLocal().pos_x, GetLocal().pos_y
                RunThread(
                    function()
                        cdrop(count, facing, x, y)
                    end
                )
                return
            end
            console("Usage : /cd `9<amount>", 1)
        end,
        desc = "Dropping Multiple Lock",
        usage = "/cd <`2amount``>",
        label = 242
    },
    ["rainbows"] = {
        func = function()
            rainbowchat = not rainbowchat
            console(string.format("Success %s Rainbow Chat", rainbowchat and "`2Enable``" or "`4Disable``"))
        end,
        desc = "Make your normal chat to `1R```2a```3i```4n```5b```6o```7w``",
        usage = "/rainbows",
        label = 408
    },
    ["sc"] = {
        func = function()
            local dialog =
                [[
set_default_color|`0
add_label_with_icon|big|Nov4 Proxy - List Command |left|32| 
add_smalltext|Discord Owner : @novascatia|left|
add_smalltext|This Helper has ]] ..cmdcount() .. [[ Command!|left|
add_spacer|small|
]] .. makecmdinfo() .. [[
end_dialog|gazette|Close||
add_quick_exit|
]]
            SendVarlist({[0] = "OnDialogRequest", [1] = dialog, netid = -1})
        end,
        desc = "Show All List Command",
        usage = "/sc",
        label = 32
    },
    ["spammer"] = {
        func = function()
            dialogspam()
        end,
        desc = "Auto Spam Panel",
        usage = "/spammer",
        label = 1752
    },
    ["logspin"] = {
        func = function()
            dataspin = ""
            for i = #logspin,1,-1 do
                if logspin[i].world == GetLocal().world then
                    dataspin = dataspin..logspin[i].spin
                end
            end
            local dialog = string.format([[
set_default_color|`0
add_label_with_icon|big|Log Spin At World : %s |left|758|
add_smalltext|Nov4 Store|left| 
add_spacer|small|
%s
add_spacer|small|
add_smalltext|`2Creator`` : `1@novascatia|left|
add_spacer|small|
end_dialog|gazette|Close||
add_quick_exit|
]],GetLocal().world,(dataspin == "") and "add_label_with_icon|small|No one player spun the wheel|left|6124|" or dataspin)
            SendVarlist({
                [0] = "OnDialogRequest",
                [1] = dialog,
                netid = -1
            })
        end,
        desc = 'Show LogSpin Like CCTV',
        usage = '/logspin',
        label = 758
    }
}

local cmd_order = {"sc", "wp", "drop", "wl", "dl", "bgl", "wx", "da", "depo", "wd", "cd", "dall", "rainbows", "logspin", "spammer", "pf", "ft"}

cmdcount = function()
    local a = 0
    for i, v in pairs(cmd) do
        a = a + 1
    end
    return a
end

makecmdinfo = function()
    local str = ""
    for _, cmdname in ipairs(cmd_order) do
        local v = cmd[cmdname]
        if v then
            str =
                str ..
                string.format(
                    "add_label_with_icon|small|[`1/%s``] - %s|left|%d|\nadd_smalltext|Usage : %s|left|\nadd_spacer|small|\n",
                    cmdname,
                    v.desc,
                    v.label,
                    v.usage
                )
        end
    end
    return str
end

AddCallback("timer","OnUpdate",function(delta)
    timer.Update(delta)
end)

function commandhandler(a, b)
    local p = b:match("action|input\n|text|/(.+)")
    if p then
        local command, params = p:match("^(%S+)%s*(.*)")
        if command and cmd[command] then
            cmd[command].func(params)
            return true
        end
    end
end
AddCallback('COMMANDHANDLER','OnPacket',commandhandler)

function messagehandler(a, b)
    text = b:match("action|input\n|text|(.+)")
    if text and not text:match("^/") then
        if rainbowchat then
            text = rainbow(text)
        end
        SendPacket(2, "action|input\n|text|" .. text)
        return true
    end
end
AddCallback('MESSAGEHANDLER','OnPacket',messagehandler)

function buttonhandler(a, b)
    local button = b:match("buttonClicked|(.+)")
    if button then 
    if button:match("^nov4spam_setconfig") then
        if SPAM.ENABLE then
            return console('Please Stop The Spam First')
        end
        SPAM.TEXT = b:match("nov4spam_message|(.-)\n")
        SPAM.DELAY = b:match("nov4spam_delay|(%d+)")
        dialogspam()
    end
    if button:match("^nov4spam_setup") then
        if SPAM.TEXT == "" or SPAM.DELAY == 0 then
            console("Please Set The Message & Delay Before Start", 1)
            return true
        end
        SPAM.ENABLE = not SPAM.ENABLE
        dialogspam()
        if SPAM.ENABLE then
            timer.Create('AUTOSPAM',tonumber(SPAM.DELAY),0,function()
                SendPacket(2,"action|input\n|text|"..SPAM.TEXT)
            end)
            else
                timer.Destroy('AUTOSPAM')
        end
    end
    end
    if b:find("action|wrench") then
        netids = tonumber(b:match("netid|(%d+)"))
        if netids ~= GetLocal().netid and pullwrench then
            pull(netids)
            console(string.format("Pulling %s",getplayers(netids)))
            return true
        end
    end
end
AddCallback('BUTTONHANDLER','OnPacket',buttonhandler)

function calculateReme(n)
    local sum = 0
    local s = tostring(n)
    for i = 1, #s do
        sum = sum + tonumber(s:sub(i, i))
    end
    return sum % 10
end

function onvariant(v)
    if v[0] == "OnConsoleMessage" then
        v[1] = v[1]:gsub("ihkaz", "nov4")
        console(v[1])
        OnCollectedNotifier(v)
        return true
    end

    if v[0] == "OnTalkBubble" then
        if v[2]:find("spun the wheel and got") then
            local num = tonumber(string.match(v[2]:gsub("`.", ""), "(%d+)%!"))
            local reme_result = calculateReme(num)
            pname = getplayers(v[1]):gsub("%[.-%]", "")
            SendVarlist({[0] = "OnNameChanged", [1] = pname .. "[`1 REME : " .. tostring(reme_result) .. "``]", netid = v[1]})
            SendVarlist({
                [0] = "OnTalkBubble",
                [1] = v[1],
                [2] = v[2] .. " `9[`4REME : `9" .. tostring(reme_result) .. "```9]",
                [3] = v[3],
                netid = -1
            })
            table.insert(
                logspin,
                {
                    spin = string.format(
                        "add_label_with_icon|small|[%s] %s : %s (`w%s``)|left|758|\n",
                        os.date("%H:%M:%S", os.time()),
                        pname:gsub(" ", ""),
                        num,
                        reme_result
                    ),
                    world = GetLocal().world
                }
            )
            return true
        end
    end
    
    if v[0] == "OnDialogRequest" then
        if v[1]:find("add_textbox|Excellent%! I'm happy to sell you a Blue Gem Lock in exchange for 100 Diamond Lock") then
            return true
        end
        if v[1]:find("phonecall") and getinv(1796) >= 100 then
            tilex = v[1]:match("tilex|(%d+)")
            tiley = v[1]:match("tiley|(%d+)")
            getBgl(tilex,tiley)
            return true
        end
    end
end
AddCallback('ONVARIANT','OnVarlist',onvariant)

webhookpayloads = string.format([[
{
  "embeds": [
    {
      "author": {
        "name": "Nov4 Eye",
        "icon_url": "https://cdn.discordapp.com/attachments/1373013808468983858/1374798479565787156/Proyek_Baru_41_5140F36.png?ex=682f5c5c&is=682e0adc&hm=c03e43069dfbb39393e1d0348e341cbf6913c6f5aac4cddfa9fa2d9b5fd48d92&"
      },
      "title": "GTFY Helper Succesfully Runned!",
      "fields": [
        {
          "name": "Name Player :",
          "value": "<a:ir:1102981035332993164> %s",
          "inline": true
        },
        {
          "name": "Player ID :",
          "value": "<a:ir:1102981035332993164> %s",
          "inline": true
        },
        {
          "name": "Join Time :",
          "value": "<a:ir:1102981035332993164> %s",
          "inline": true
        }
      ],
      "image": {
        "url": "https://cdn.discordapp.com/attachments/1373013808468983858/1374798479800406179/Proyek_Baru_79_4712913.png?ex=682f5c5c&is=682e0adc&hm=b795f528c95c13d49a9e89b1bbeb2f9467abf858319f1ac81fb1e99311d3883c&"
      },
      "color": 16777215
    }
  ]
}
]],GetLocal().name:gsub('`.',''),math.floor(GetLocal().userid),"<t:"..os.time()..":R>")
RunThread(function()
    SendWebhook("gantiwebhukdisini",webhookpayloads)
end)

local dialoggazzete = [[
set_default_color|`0
add_label_with_icon|big|Nov4 Store Helper!|left|7188| 
add_smalltext|https://dsc.gg/nov4community|left| 
add_spacer|small|
add_label_with_icon|small| What's New? PATCH : [`403/10/2025]``]|left|6124|
add_spacer|small|
add_smalltext|[+] Check /sc to see commands|left|
add_smalltext|[+] Lock Collect Notifier is now always ON|left|
add_smalltext|[+] Auto calculate x for leme or reme use /wx (bet) (x)|left| 
add_spacer|small|
add_smalltext|`2Creator`` : `1@novascatia|left|
add_smalltext|`2Donate World`` : `1DEXT|left|
add_spacer|small|
end_dialog|gazette|Close||
add_quick_exit|
]]
SendVarlist({[0] = "OnDialogRequest",[1] = dialoggazzete,netid = -1})

