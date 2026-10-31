local _, V = ...
-- Compact, entirely in-game, user-triggered preset replies. No Windows companion.
local panel, history, targetText, preview, status, styleMenu, replyMenu
local style = 'Sarcastic'
local replyIndex = 1
local styleOrder = {'Subscription', 'Ganking', 'Winning PvP', 'Corpse Runs', 'No Life', 'Sarcastic', 'Funny', 'Friendly'}
local replies = {
    ['Subscription'] = {
        'My $14.99 buys world PvP. Yours apparently buys graveyard tours.',
        'We pay the same $14.99. I'm winning fights and you're writing complaints.',
        'Best $14.99 ever. Your corpse runs are included.',
        'I'm getting my money's worth out of PvP. How's your sub going?',
        'My sub pays for fights. Yours pays for the spirit healer.',
        'Same subscription, different scoreboard.',
        'I pay $14.99 to PvP, not to let you quest in peace.',
        'Every respawn is more value for my $14.99.',
        'I'm enjoying my $14.99. You sound like you're requesting a refund.',
        'At least one of us is enjoying the PvP we pay for.',
    },
    ['Ganking'] = {
        'It's a PvP server. I'm doing the PvP part.',
        'You call it ganking. I call it world PvP.',
        'I wasn't camping. You just kept coming back.',
        'The graveyard is part of the zone too.',
        'I was passing through. Then you respawned.',
        'You keep taking the same route. I keep getting the same result.',
        'Your quest objective changed to survive.',
        'A red nameplate is an invitation.',
        'You're welcome to fight back instead of typing.',
        'I don't set your hearthstone. I just encourage you to use it.',
    },
    ['Winning PvP'] = {
        'GG. That was a short fight.',
        'You had a plan. I had the killing blow.',
        'Your best cooldown was the whisper afterward.',
        'You were stronger in chat than in combat.',
        'That duel had a very clear winner.',
        'I came for honorable combat. The outcome was optional.',
        'Your keyboard works great in whispers.',
        'I think the combat log already settled this.',
        'The scoreboard makes a better argument than your whisper.',
        'Next time try fighting as hard as you're typing.',
    },
    ['Corpse Runs'] = {
        'Welcome back. Long walk?',
        'I admire your commitment to that graveyard.',
        'Same corpse, different attempt.',
        'I can wait. The spirit healer has office hours.',
        'You keep running back, I keep getting PvP.',
        'We've fought so often I recognize your ghost.',
        'At this point the graveyard is your home base.',
        'I see the runback timer was accurate.',
        'Another respawn, another opportunity.',
        'The road back is longer than the fight.',
    },
    ['No Life'] = {
        'You lost the fight and started investigating my schedule.',
        'My playtime didn't land the killing blow. I did.',
        'Calling me no-life won't change the combat log.',
        'You have time to whisper but not time to win?',
        'I'm online for PvP. You're online to monitor me.',
        'You found my location again. Still couldn't win.',
        'My free time wasn't on your action bar.',
        'You spend more time tracking me than countering me.',
        'I'm enjoying world PvP. You're keeping attendance.',
        'The fight ended. The excuses are still going.',
    },
    ['Sarcastic'] = {
        'I'll let the PvP server know you're upset about PvP.',
        'A complaint after every death? Impressive consistency.',
        'Please attach the combat log to your complaint.',
        'I would apologize, but the scoreboard disagrees.',
        'Your feedback has been delivered to the spirit healer.',
        'Have you tried not losing that fight?',
        'I'm sure the next whisper will change the outcome.',
        'Thank you for reviewing your latest corpse run.',
        'You can explain it again after your next respawn.',
        'I've forwarded your concerns to the Horde.',
    },
    ['Funny'] = {
        'Your corpse has more frequent flyer miles than my mount.',
        'The spirit healer asked me to tell you to slow down.',
        'Your respawn timer and I have become good friends.',
        'I came for world PvP and accidentally started a walking club.',
        'The graveyard should give you a punch card.',
        'I thought you were farming quests. Turns out you were farming corpse runs.',
        'Your ghost is getting more exercise than your character.',
        'That fight was shorter than your complaint.',
        'I think your hearthstone is trying to tell you something.',
        'Redridge tourism is booming thanks to your runbacks.',
    },
    ['Friendly'] = {
        'GG, see you out in the world.',
        'Good fight. Catch you on the next run.',
        'Nothing personal, just world PvP.',
        'Well played. Good luck on the rematch.',
        'All in good fun. That's PvP.',
        'GG. You nearly had me that time.',
        'No hard feelings. See you around.',
        'Good attempt. Hope the next fight is closer.',
        'Respect for coming back to fight.',
        'GG. Enjoy the rest of your night.',
    }
}
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
end
function V.Refresh()
    if not panel then return end
    V.Prune()
    local c=V.conversations[V.selected]
    targetText:SetText(c and ('To: '..c.name) or 'No player selected')
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
    panel:SetSize(425,310)
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
    button(panel,'Next Player',300,-33,108,function()
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
    history:SetSize(396,85)
    history:SetFontObject(ChatFontNormal)
    history:SetJustifyH('LEFT')
    history:SetFading(false)
    history:SetMaxLines(35)
    history:EnableMouseWheel(true)
    history:SetScript('OnMouseWheel',function(self,d)if d>0 then self:ScrollUp()else self:ScrollDown()end end)
    label(panel,'Style:',13,-166,60)
    styleMenu=CreateFrame('Frame','VoidMarkClapbackStyleMenu',panel,'UIDropDownMenuTemplate')
    styleMenu:SetPoint('TOPLEFT',55,-151)
    UIDropDownMenu_SetWidth(styleMenu,142)
    UIDropDownMenu_Initialize(styleMenu,function(self,level)
        for _,name in ipairs(styleOrder) do
            local option=UIDropDownMenu_CreateInfo()
            option.text=name
            option.checked=(style==name)
            option.func=function()style=name;replyIndex=1;updatePreview();CloseDropDownMenus()end
            UIDropDownMenu_AddButton(option,level)
        end
    end)
    label(panel,'Reply:',227,-166,55)
    replyMenu=CreateFrame('Frame','VoidMarkClapbackReplyMenu',panel,'UIDropDownMenuTemplate')
    replyMenu:SetPoint('TOPLEFT',268,-151)
    UIDropDownMenu_SetWidth(replyMenu,105)
    UIDropDownMenu_Initialize(replyMenu,function(self,level)
        for i,message in ipairs(replies[style]) do
            local option=UIDropDownMenu_CreateInfo()
            option.text=i..'. '..message
            option.checked=(replyIndex==i)
            option.func=function()replyIndex=i;updatePreview();CloseDropDownMenus()end
            UIDropDownMenu_AddButton(option,level)
        end
    end)
    preview=label(panel,'',15,-208,393)
    preview:SetTextColor(.95,.9,1)
    preview:SetHeight(38)
    button(panel,'Send',13,-253,96,function()
        local c=V.conversations[V.selected]
        local message=selectedReply()
        if not c or not c.name or c.name=='' then status:SetText('Select a player first.');return end
        if not message or message=='' then status:SetText('Choose a reply first.');return end
        -- A deliberate click sends one whisper; no automated responses or game inputs.
        SendChatMessage(message,'WHISPER',nil,c.name)
        status:SetText('Sent to '..c.name)
    end)
    button(panel,'Edit in chat',119,-253,116,function()
        local c=V.conversations[V.selected]
        if not c or not selectedReply() then status:SetText('Select a player first.');return end
        ChatFrame_OpenChat('/w '..c.name..' '..selectedReply())
        status:SetText('Edit the whisper and press Enter to send.')
    end)
    button(panel,'Next Reply',244,-253,164,function()
        replyIndex=replyIndex % #replies[style]+1
        updatePreview()
    end)
    status=label(panel,'Pick a reply and click Send.',13,-285,397)
    updatePreview()
    V.Refresh()
end
