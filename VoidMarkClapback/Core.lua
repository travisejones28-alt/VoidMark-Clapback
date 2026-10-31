local addon, V = ...
V.conversations, V.seen, V.seenOrder = {}, {}, {}
V.selected = nil
local function encode(s)
    return (tostring(s):gsub('([^%w%-%._~])', function(c) return string.format('%%%02X', string.byte(c)) end))
end
local function decode(s) return (s:gsub('%%(%x%x)', function(h) return string.char(tonumber(h, 16)) end)) end
V.encode = encode
function V.Prune()
    local cutoff = time() - 3600
    for key, c in pairs(V.conversations) do
        if c.updated < cutoff then V.conversations[key] = nil end
    end
end
function V.Record(event, message, sender, ...)
    if not sender or sender == '' or not message then return end
    -- Remaining event args start at language (arg3); lineID and GUID are args11/12.
    local lineID, guid = select(9, ...), select(10, ...)
    if lineID and lineID ~= 0 then
        local id = event .. ':' .. tostring(lineID)
        if V.seen[id] then return end
        V.seen[id] = true; table.insert(V.seenOrder, id)
        if #V.seenOrder > 500 then V.seen[table.remove(V.seenOrder, 1)] = nil end
    end
    V.Prune()
    local key = sender:lower()
    local c = V.conversations[key] or {name=sender, messages={}}
    c.guid, c.updated = guid, time()
    if guid and GetPlayerInfoByGUID then
        local ok, class, classID, race = pcall(GetPlayerInfoByGUID, guid)
        if ok then c.class, c.classID, c.race = class, classID, race end
    end
    table.insert(c.messages, {direction=event == 'CHAT_MSG_WHISPER' and 'in' or 'out', text=message, time=time()})
    while #c.messages > 20 do table.remove(c.messages, 1) end
    V.conversations[key] = c
    local count, oldest, oldestTime = 0, nil, math.huge
    for k, item in pairs(V.conversations) do count=count+1; if item.updated<oldestTime then oldest,oldestTime=k,item.updated end end
    if count>100 then V.conversations[oldest]=nil end
    if not V.selected then V.selected = key end
    if V.Refresh then V.Refresh() end
end
function V.Export()
    local c = V.conversations[V.selected]
    if not c then return '' end
    local character = UnitName('player') .. '-' .. GetRealmName():gsub('%s+', '')
    local rows = {'VMC1\t' .. encode(character) .. '\t' .. encode(c.name)}
    for _,m in ipairs(c.messages) do table.insert(rows, m.direction .. '\t' .. m.time .. '\t' .. encode(m.text)) end
    return table.concat(rows, '\n')
end
local function incomingFilter(self, event, message, sender, ...)
    if not sender then return false, message, sender, ... end
    return false, message .. ' |cffaa77ff|Hvmclap:' .. encode(sender) .. '|h[Clapback]|h|r', sender, ...
end
local frame=CreateFrame('Frame')
frame:RegisterEvent('ADDON_LOADED')
frame:RegisterEvent('CHAT_MSG_WHISPER')
frame:RegisterEvent('CHAT_MSG_WHISPER_INFORM')
frame:RegisterEvent('PLAYER_LOGOUT')
frame:SetScript('OnEvent',function(self,event,...)
    if event=='ADDON_LOADED' then
        if ... ~= addon then return end
        VoidMarkClapbackDB = VoidMarkClapbackDB or {}
        V.db=VoidMarkClapbackDB
        if V.CreateMinimapIcon then V.CreateMinimapIcon() end
        if V.db.remember then V.conversations=V.db.conversations or {} end
        V.db.conversations=nil
        V.Prune()
        ChatFrame_AddMessageEventFilter('CHAT_MSG_WHISPER', incomingFilter)
        -- Handle only our own action; normal player/item links retain Blizzard/ElvUI behavior.
        local original=SetItemRef
        SetItemRef=function(link,text,button,chatFrame,...)
            local name=link and link:match('^vmclap:(.+)$')
            if name then V.selected=decode(name):lower();V.Open();return end
            return original(link,text,button,chatFrame,...)
        end
        SLASH_VOIDMARKCLAPBACK1='/clapback'
        SlashCmdList.VOIDMARKCLAPBACK=function(msg)
            msg=(msg or ''):lower()
            if msg=='clear' then V.conversations={};V.selected=nil;V.db.conversations=nil
            elseif msg=='remember' then V.db.remember=not V.db.remember;print('Clapback saved history: '..tostring(V.db.remember))
            elseif msg~='' then V.selected=msg end
            V.Open()
        end
    elseif event=='PLAYER_LOGOUT' then
        if V.db then V.db.conversations=V.db.remember and V.conversations or nil end
    else V.Record(event,...) end
end)
