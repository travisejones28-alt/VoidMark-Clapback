local _, V = ...
-- Compact, entirely in-game, user-triggered preset replies. No Windows companion.
local panel, history, targetText, preview, status, styleMenu, replyMenu
local style = 'Sarcastic'
local replyIndex = 1
local styleOrder = {'Sarcastic', 'Funny', 'Dry Humor', 'Friendly', 'Ridiculous'}
local replies = {
    ['Sarcastic'] = {
        'That was almost intimidating. Keep practicing.',
        'I appreciate the free feedback.',
        'You seem very invested in my character development.',
        'Noted. I will alert the management.',
        'Your concern has been filed under PvP.'
    },
    ['Funny'] = {
        'My keyboard slipped and here we are.',
        'I was just checking if your respawn timer works.',
        'The quest said defeat enemies. I follow instructions.',
        'Sorry, my map said this was a sightseeing tour.',
        'I blame the goblins. Always the goblins.'
    },
    ['Dry Humor'] = {
        'Interesting observation.',
        'That is one way to look at it.',
        'Understood. Anyway.',
        'The situation seems to be proceeding normally.',
        'A compelling argument, certainly.'
    },
    ['Friendly'] = {
        'All good, just having some PvP fun.',
        'No hard feelings. Good luck out there.',
        'Haha, fair enough. See you around.',
        'GG, that was a fun fight.',
        'Nothing personal. Have a good one.'
    },
    ['Ridiculous'] = {
        'My pet rock made the tactical decision.',
        'The council of murlocs demanded this duel.',
        'Please forward complaints to the nearest mailbox.',
        'A very small gnome is steering my character.',
        'The prophecy mentioned this exact moment.'
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
