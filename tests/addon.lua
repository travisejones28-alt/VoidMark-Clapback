-- Lua 5.1 contract harness: no WoW client behavior is claimed by these mocks.
local handlers, filters = {}, {}
local now = 10000
function time() return now end
function UnitName() return 'Me' end
function GetRealmName() return 'Test Realm' end
function CreateFrame() return {RegisterEvent=function()end,SetScript=function(_,_,f)handlers.event=f end} end
function ChatFrame_AddMessageEventFilter(event,f)filters[event]=f end
local forwarded=0
function SetItemRef() forwarded=forwarded+1 end
SlashCmdList={}
local V={Open=function()end}
assert(loadfile('VoidMarkClapback/Core.lua'))('VoidMarkClapback',V)
local mockedOpen = V.Open
assert(loadfile('VoidMarkClapback/UI.lua'))('VoidMarkClapback', V) -- load presets without opening the UI
assert(#V.ReplyStyles == 13, 'all reply categories available')
local seenReplies = {}
for _,category in ipairs(V.ReplyStyles) do
  local items=V.Replies[category]
  assert(items and #items>=10, 'category with at least ten replies: '..category)
  for _,reply in ipairs(items) do
    assert(type(reply)=='string' and #reply>0 and #reply<=200, 'safe chat-length preset: '..category)
    assert(not seenReplies[reply:lower()], 'duplicate preset: '..reply)
    seenReplies[reply:lower()]=true
  end
end
assert(V.Replies['1v1 Excuses'] and V.Replies['Backup Threats'] and V.Replies['Camping Stories'] and V.Replies['Rage Whispers'] and V.Replies['Whisper Warriors'], 'common rage patterns covered')
V.Open = mockedOpen -- keep subsequent hyperlink tests independent of WoW UI frames
assert(loadfile('VoidMarkClapback/Minimap.lua')) -- syntax check only
handlers.event(nil,'ADDON_LOADED','VoidMarkClapback')
local function incoming(player,id)
  handlers.event(nil,'CHAT_MSG_WHISPER','why me?',player,'Common','','','',0,0,'',0,id,'Player-GUID')
end
incoming('Other-Realm',12);incoming('Other-Realm',12)
assert(#V.conversations['other-realm'].messages==1,'duplicate line ID')
incoming('Other-Realm',13)
assert(#V.conversations['other-realm'].messages==2,'distinct repeated text retained')
assert(V.conversations['other-realm'].guid=='Player-GUID','event GUID position')
incoming('Second-Realm',14)
SetItemRef('vmclap:Second-Realm')
assert(V.selected=='second-realm','action chooses correct player')
SetItemRef('item:6948');assert(forwarded==1,'ordinary hyperlinks forwarded')
local hidden,msg=filters.CHAT_MSG_WHISPER(nil,'CHAT_MSG_WHISPER','original','Other-Realm')
assert(not hidden and msg:find('original') and msg:find('vmclap:'),'filter preserves whisper')
assert(V.Export():find('VMC1\tMe%-TestRealm\tSecond%-Realm'),'manual context character')
handlers.event(nil,'PLAYER_LOGOUT');assert(VoidMarkClapbackDB.conversations==nil,'history private by default')
now=now+3601;V.Prune();assert(next(V.conversations)==nil,'retention')
print('Addon contract checks passed')

