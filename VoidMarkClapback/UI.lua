local _, V = ...
-- Compact, entirely in-game, user-triggered preset replies. No Windows companion.
local panel, history, targetText, preview, status, styleMenu, replyMenu, destinationMenu
local destination = 'Whisper'
local destinations = {'Whisper', 'General', 'LocalDefense'}
local function destinationChannel()
    if destination == 'Whisper' then
        local c = V.conversations[V.selected]
        if not c or not c.name or c.name == '' then return nil, 'Select a whisper player first.' end
        return 'WHISPER', c.name
    end
    local name = destination == 'General' and 'General' or 'LocalDefense'
    local channelID = GetChannelName(name)
    if not channelID or channelID == 0 then return nil, name .. ' is not joined in this zone.' end
    return 'CHANNEL', channelID
end
local style = 'Rage Whispers'
local replyIndex = 1
local styleOrder = {"Rage Whispers", "1v1 Excuses", "Backup Threats", "Camping Stories", "Whisper Warriors", "Subscription", "Ganking", "Winning PvP", "Corpse Runs", "No Life", "Sarcastic", "Funny", "Friendly"}
local replies = {
    ["Rage Whispers"] = {
        "bro you're still typing?",
        "lmao you've said that four different ways now.",
        "Do you want a rematch or another paragraph?",
        "You're working harder on these whispers than I am on PvP.",
        "I killed your character, not your entire evening.",
        "You can stop updating me on how mad you are.",
        "You're talking like this is a court case.",
        "All this over a corpse run?",
        "We get it, you're upset.",
        "Your whisper key is getting more action than your abilities.",
        "It's been ten minutes. Are you coming or not?",
        "lol you're still on that?",
    },
    ["1v1 Excuses"] = {
        "It's world PvP, not a scheduled duel.",
        "You're asking for rules after the fight ended.",
        "Nobody promised you a 1v1.",
        "If you wanted a duel, you know where the duel button is.",
        "lol I don't owe you a fair fight.",
        "1v1, 2v1, 10v1. It's still a PvP server.",
        "You keep saying 1v1 like that'll undo the death.",
        "We can discuss the rules while you run back.",
        "This isn't a tournament, bro.",
        "Imagine arguing about team sizes in world PvP.",
        "You're more interested in the format than the fight.",
    },
    ["Backup Threats"] = {
        "Cool, tell your friend to hurry up.",
        "Your friend logging on has been the main event for ten minutes.",
        "Are we fighting him or waiting for his download to finish?",
        "Bro keeps announcing the reinforcements.",
        "Tell him to bring snacks. You're taking forever.",
        "Sweet, more world PvP.",
        "You're threatening me with a group on a PvP server. lmao.",
        "Your backup has an ETA or just a press release?",
        "That's a lot of hype for someone who isn't here.",
        "Make it a guild event, I don't care.",
        "Have him whisper me too so we can skip the introductions.",
    },
    ["Camping Stories"] = {
        "Congrats on yesterday. What about right now?",
        "You keep telling me about yesterday like it's a replay.",
        "Apparently that camp bothered you more than me.",
        "lol you promised to camp me 20 whispers ago.",
        "You can't corpse camp me from a whisper window.",
        "I'll believe it when I see it.",
        "You've camped the chat box longer than any corpse.",
        "Big plans. Still standing here.",
        "Yesterday's score doesn't help you tonight.",
        "Quit telling me about it and come find me.",
        "Your best PvP moment is a story about yesterday?",
    },
    ["Whisper Warriors"] = {
        "You have time to whisper but not time to win?",
        "At this point we're pen pals.",
        "You're doing more typing than fighting.",
        "Another whisper. Guess the reinforcements are still loading.",
        "lmao I can hear the keyboard from Redridge.",
        "I'm sure the next whisper will change the outcome.",
        "You seem to know more about my schedule than I do.",
        "Keep talking, I'll keep playing.",
        "Your keyboard has better uptime than your character.",
        "You made an alt just to keep this conversation going?",
        "You're not hunting me. You're writing my biography.",
        "The only thing you're camping is my inbox.",
    },
    ["Subscription"] = {
        "We pay the same $14.99. I'm having fun. You're filing complaints.",
        "Best $14.99 I've spent all month.",
        "My sub came with world PvP. Did yours not?",
        "I paid $14.99 to play, not ask permission.",
        "You're spending $14.99 to argue with someone enjoying theirs.",
        "I'm getting my money's worth. You don't sound like you are.",
        "It's my $14.99, bro.",
        "Neither of us paid for a fair fight.",
        "I've had cheaper entertainment, but not better.",
        "You keep typing; I'm getting my $14.99 worth.",
    },
    ["Ganking"] = {
        "It's a PvP server. I'm doing the PvP part.",
        "Red means dead. Pretty simple.",
        "Now you're mad I attacked you on a PvP server?",
        "lol you picked the wrong server for rules.",
        "You call it ganking, I call it Tuesday.",
        "Your quest objective just changed to survive.",
        "Don't blame me for taking the free kill.",
        "You're welcome to fight back instead of typing.",
        "Sorry, I forgot to ask your level first.",
        "You keep respawning in the same spot. What did you expect?",
        "I didn't roll here to hand out peace treaties.",
        "If this bothers you, wait until Stranglethorn.",
    },
    ["Winning PvP"] = {
        "Can't hear you over the combat log.",
        "Still got the kill though.",
        "You won the argument in your head. I won the fight.",
        "Your best cooldown was the whisper afterward.",
        "That's a lot of explaining for a lost fight.",
        "lmao see you in the world.",
        "I can always find you a rematch.",
        "Your whisper DPS is impressive.",
        "You should've typed that before you died.",
        "GG. Rematch anytime.",
    },
    ["Corpse Runs"] = {
        "Welcome back. Long walk?",
        "How's the runback?",
        "All that typing and you still have to run back.",
        "I've seen you in ghost form more than alive.",
        "Keep this up, the spirit healer will learn your name.",
        "That walk looks rough.",
        "Same graveyard, different attempt.",
        "You're doing laps out there.",
        "Your corpse run has more uptime than your buffs.",
        "I'm not going anywhere. Take your time.",
        "Another run? Respect the cardio.",
    },
    ["No Life"] = {
        "You're tracking my playtime now? lmao.",
        "Imagine taking attendance for a stranger in WoW.",
        "That's a lot of interest in what I do with my time.",
        "Keep tabs on me; makes me feel important.",
        "You're watching me more closely than your target.",
        "You've memorized my zones better than your keybinds.",
        "Thanks for the detailed itinerary of my day.",
        "Didn't know I had a fan club.",
        "You're bringing up yesterday again?",
        "Sounds like you've been thinking about me all day.",
    },
    ["Sarcastic"] = {
        "Please submit your complaint after the next respawn.",
        "Is this the part where I apologize for world PvP?",
        "Your feedback has been delivered to the spirit healer.",
        "I'm not sure the next whisper will change the outcome.",
        "Did you need a manager or a healer?",
        "You've made your point. Six times.",
        "Thank you for the play-by-play of my own character.",
        "Let me know when the lecture is over.",
        "Sorry, I was busy playing the game.",
        "Absolutely devastating argument. Still PvPing though.",
    },
    ["Funny"] = {
        "You've sent more whispers than my mailbox gets in a week.",
        "I should start charging rent for this whisper window.",
        "Your backup must be logging in on dial-up.",
        "Your friend got a loading screen or a permission slip?",
        "I came to PvP and somehow joined a book club.",
        "Your ghost is getting its steps in.",
        "You're treating Redridge like a customer service desk.",
        "Blizzard should add a cooldown to your whisper key.",
        "The spirit healer has already heard your side of the story.",
        "Do I get a quest reward for reading all this?",
    },
    ["Friendly"] = {
        "GG, see you around.",
        "It's just world PvP. No hard feelings.",
        "Good fight. Catch you next time.",
        "You got me last time. That's how PvP goes.",
        "Nothing personal, I just attack red names.",
        "Win some, lose some.",
        "GL out there.",
        "All good. See you next fight.",
        "Have a good one.",
        "lol fair enough. GG.",
    },
}
-- Kept available for Lua contract tests and future preset-only integrations.
V.ReplyStyles, V.Replies = styleOrder, replies

local function label(parent, text, x, y, width)
    local f = parent:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
    f:SetPoint('TOPLEFT', x, y)
    f:SetWidth(width)
    f:SetJustifyH('LEFT')
    f:SetText(text)
    return f
end
local function button(parent, text, x, y, w, callback)
    local b=CreateFrame('Button', nil, parent, 'UIPanelButtonTemplate')
    b:SetPoint('TOPLEFT', x, y)
    b:SetSize(w, 24)
    b:SetText(text)
    b:SetScript('OnClick', callback)
    return b
end
local function selectedReply()
    return replies[style] and replies[style][replyIndex] or nil
end
local function updatePreview()
    if preview then preview:SetText(selectedReply() or 'Choose a reply.') end
    if styleMenu then UIDropDownMenu_SetText(styleMenu, style) end
    if replyMenu then UIDropDownMenu_SetText(replyMenu, 'Reply '..replyIndex..' of '..#replies[style]) end
    if destinationMenu then UIDropDownMenu_SetText(destinationMenu, destination) end
end
function V.Refresh()
    if not panel then return end
    V.Prune()
    local c=V.conversations[V.selected]
    targetText:SetText(c and ('Player: '..c.name) or 'No player selected')
    history:Clear()
    if c then
        for i=math.max(1,#c.messages-5),#c.messages do
            local m=c.messages[i]
            history:AddMessage((m.direction=='in' and c.name or 'Me')..': '..m.text, .9,.84,1)
        end
    end
    if not c then status:SetText('Receive a whisper or select a player to begin.') end
end
function V.Open()
    if panel then panel:Show();V.Refresh();return end
    panel=CreateFrame('Frame','VoidMarkClapbackFrame',UIParent,'BackdropTemplate')
    panel:SetSize(455,380)
    panel:SetClampedToScreen(true)
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag('LeftButton')
    panel:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Buttons\\WHITE8X8',edgeSize=2})
    panel:SetBackdropColor(.055,.035,.085,.96)
    panel:SetBackdropBorderColor(.55,.25,.85)
    local p=V.db.position
    if p then panel:SetPoint('CENTER',UIParent,'CENTER',p.x,p.y) else panel:SetPoint('CENTER') end
    panel:SetScript('OnDragStart',panel.StartMoving)
    panel:SetScript('OnDragStop',function(self)
        self:StopMovingOrSizing()
        local x,y=self:GetCenter()
        local px,py=UIParent:GetCenter()
        V.db.position={x=x-px,y=y-py}
    end)
    table.insert(UISpecialFrames,'VoidMarkClapbackFrame')
    label(panel,'VoidMark Clapback',13,-12,325)
    local close=CreateFrame('Button',nil,panel,'UIPanelCloseButton')
    close:SetPoint('TOPRIGHT',0,0)
    targetText=label(panel,'No player selected',13,-38,290)
    button(panel,'Next Player',329,-33,110,function()
        local keys={}
        for k in pairs(V.conversations) do table.insert(keys,k) end
        table.sort(keys)
        if #keys==0 then status:SetText('No whispers recorded yet.');return end
        local i=0
        for n,k in ipairs(keys) do if k==V.selected then i=n;break end end
        V.selected=keys[(i % #keys)+1]
        V.Refresh()
    end)
    history=CreateFrame('ScrollingMessageFrame',nil,panel)
    history:SetPoint('TOPLEFT',13,-68)
    history:SetSize(424,107)
    history:SetFontObject(ChatFontNormal)
    history:SetJustifyH('LEFT')
    history:SetFading(false)
    history:SetMaxLines(35)
    history:EnableMouseWheel(true)
    history:SetScript('OnMouseWheel',function(self,d)if d>0 then self:ScrollUp()else self:ScrollDown()end end)
    label(panel,'Style:',13,-194,65)
    styleMenu=CreateFrame('Frame','VoidMarkClapbackStyleMenu',panel,'UIDropDownMenuTemplate')
    styleMenu:SetPoint('TOPLEFT',58,-178)
    UIDropDownMenu_SetWidth(styleMenu,155)
    UIDropDownMenu_Initialize(styleMenu,function(self,level)
        for _,name in ipairs(styleOrder) do
            local option=UIDropDownMenu_CreateInfo()
            option.text=name;option.checked=(style==name)
            option.func=function()style=name;replyIndex=1;updatePreview();CloseDropDownMenus()end
            UIDropDownMenu_AddButton(option,level)
        end
    end)
    label(panel,'Reply:',253,-194,65)
    replyMenu=CreateFrame('Frame','VoidMarkClapbackReplyMenu',panel,'UIDropDownMenuTemplate')
    replyMenu:SetPoint('TOPLEFT',297,-178)
    UIDropDownMenu_SetWidth(replyMenu,112)
    UIDropDownMenu_Initialize(replyMenu,function(self,level)
        for i,message in ipairs(replies[style]) do
            local option=UIDropDownMenu_CreateInfo()
            option.text=i..'. '..message
            option.checked=(replyIndex==i)
            option.func=function()replyIndex=i;updatePreview();CloseDropDownMenus()end
            UIDropDownMenu_AddButton(option,level)
        end
    end)
    label(panel,'Post to:',13,-232,80)
    destinationMenu=CreateFrame('Frame','VoidMarkClapbackDestinationMenu',panel,'UIDropDownMenuTemplate')
    destinationMenu:SetPoint('TOPLEFT',83,-216)
    UIDropDownMenu_SetWidth(destinationMenu,163)
    UIDropDownMenu_Initialize(destinationMenu,function(self,level)
        for _,name in ipairs(destinations) do
            local option=UIDropDownMenu_CreateInfo()
            option.text=name;option.checked=(destination==name)
            option.func=function()
                destination=name;updatePreview()
                status:SetText(name=='Whisper' and 'Will whisper the selected player.' or 'Will post to '..name..' in your current zone.')
                CloseDropDownMenus()
            end
            UIDropDownMenu_AddButton(option,level)
        end
    end)
    preview=label(panel,'',15,-260,423)
    preview:SetTextColor(.95,.9,1)
    preview:SetHeight(43)
    button(panel,'Send',13,-310,102,function()
        local message=selectedReply()
        if not message or message=='' then status:SetText('Choose a reply first.');return end
        local channel,target=destinationChannel()
        if not channel then status:SetText(target);return end
        if channel=='WHISPER' then
            SendChatMessage(message,'WHISPER',nil,target)
            status:SetText('Whisper sent to '..target)
        else
            SendChatMessage(message,'CHANNEL',nil,target)
            status:SetText('Posted to '..destination)
        end
    end)
    button(panel,'Edit in chat',126,-310,143,function()
        local channel,target=destinationChannel()
        if not channel then status:SetText(target);return end
        local message=selectedReply()
        if channel=='WHISPER' then
            ChatFrame_OpenChat('/w '..target..' '..message)
        else
            ChatFrame_OpenChat('/'..target..' '..message)
        end
        status:SetText('Review the message, then press Enter.')
    end)
    button(panel,'Next Reply',281,-310,158,function()
        replyIndex=replyIndex % #replies[style]+1
        updatePreview()
    end)
    status=label(panel,'Pick a reply and click Send.',13,-347,426)
    updatePreview()
    V.Refresh()
end
