local _, V = ...
local panel, history, status, title, context, reply, hint
local displayedPlayer
local function label(parent,text,x,y,width)
    local f=parent:CreateFontString(nil,'OVERLAY','GameFontNormal')
    f:SetPoint('TOPLEFT',x,y);f:SetWidth(width);f:SetJustifyH('LEFT');f:SetText(text);return f
end
local function button(parent,text,x,y,width,handler)
    local b=CreateFrame('Button',nil,parent,'UIPanelButtonTemplate');b:SetSize(width,25);b:SetPoint('TOPLEFT',x,y);b:SetText(text);b:SetScript('OnClick',handler);return b
end
local function edit(parent,x,y,w,h,multi)
    local e=CreateFrame('EditBox',nil,parent,'InputBoxTemplate');e:SetPoint('TOPLEFT',x,y);e:SetSize(w,h);e:SetAutoFocus(false);e:SetMultiLine(multi);e:SetFontObject(ChatFontNormal);e:SetScript('OnEscapePressed',function(self)self:ClearFocus()end);return e
end
function V.Refresh()
    if not panel then return end
    V.Prune()
    if displayedPlayer ~= V.selected then
        displayedPlayer=V.selected
        if context then context:SetText('') end
        if reply then reply:SetText('') end
    end
    local c=V.conversations[V.selected]
    title:SetText(c and ('VoidMark Clapback | '..c.name) or 'VoidMark Clapback')
    history:Clear()
    if c then for _,m in ipairs(c.messages) do history:AddMessage(date('%H:%M',m.time)..' '..(m.direction=='in' and c.name or 'Me')..': '..m.text,0.88,0.83,1) end end
    status:SetText('AI: Windows companion (no live in-game connection)\nChat logging: '..(LoggingChat() and 'ON' or 'OFF'))
end
function V.Open()
    if panel then panel:Show();V.Refresh();return end
    panel=CreateFrame('Frame','VoidMarkClapbackFrame',UIParent,'BackdropTemplate')
    panel:SetSize(475,490);panel:SetClampedToScreen(true);panel:SetMovable(true);panel:EnableMouse(true);panel:RegisterForDrag('LeftButton')
    panel:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Buttons\\WHITE8X8',edgeSize=2})
    panel:SetBackdropColor(0.055,0.035,0.085,0.96);panel:SetBackdropBorderColor(0.55,0.25,0.85)
    local p=V.db.position
    if p then panel:SetPoint('CENTER',UIParent,'CENTER',p.x,p.y) else panel:SetPoint('CENTER') end
    panel:SetScript('OnDragStart',panel.StartMoving)
    panel:SetScript('OnDragStop',function(self)self:StopMovingOrSizing();local x,y=self:GetCenter();local px,py=UIParent:GetCenter();V.db.position={x=x-px,y=y-py}end)
    table.insert(UISpecialFrames,'VoidMarkClapbackFrame')
    title=label(panel,'VoidMark Clapback',14,-14,410)
    local close=CreateFrame('Button',nil,panel,'UIPanelCloseButton');close:SetPoint('TOPRIGHT',0,0)
    button(panel,'Player >',14,-40,85,function()
        local keys={};for key in pairs(V.conversations)do table.insert(keys,key)end;table.sort(keys)
        local index=0;for i,k in ipairs(keys)do if k==V.selected then index=i end end
        V.selected=keys[index % math.max(#keys,1)+1];context:SetText('');reply:SetText('');V.Refresh()
    end)
    button(panel,'Settings',108,-40,90,function()
        hint:SetText('/clapback clear: erase addon history\n/clapback remember: toggle saved history (default OFF)\nAI settings and API key are in the Windows companion.')
    end)
    button(panel,'Toggle chat log',208,-40,135,function()LoggingChat(not LoggingChat());V.Refresh()end)
    history=CreateFrame('ScrollingMessageFrame',nil,panel);history:SetPoint('TOPLEFT',14,-77);history:SetSize(447,145);history:SetFontObject(ChatFontNormal);history:SetJustifyH('LEFT');history:SetFading(false);history:SetMaxLines(100);history:EnableMouseWheel(true)
    history:SetScript('OnMouseWheel',function(self,d)if d>0 then self:ScrollUp()else self:ScrollDown()end end)
    button(panel,'Select AI Context',14,-230,130,function()
        local export=V.Export()
        if export=='' then hint:SetText('No conversation selected. Receive a whisper first.');return end
        context:SetText(export);context:SetFocus();context:HighlightText()
        hint:SetText('Context SELECTED. Press Ctrl+C now.\nIn the separate Clapback Windows app, click Paste Context,\nthen Generate / Regenerate. Review and copy your reply.')
    end)
    button(panel,'AI Instructions',154,-230,130,function()
        hint:SetText('Custom AI runs in the SEPARATE Windows Clapback app.\nUse Select AI Context -> Ctrl+C -> Paste Context there.\nOpen Custom AI, type instructions, and click Generate.')
    end)
    hint=label(panel,'AI is in the separate Windows Clapback application.\nSelect AI Context -> Ctrl+C -> Windows Paste Context.\nGenerate there, then paste your reviewed reply below.',14,-265,447)
    button(panel,'Select Context',14,-323,130,function()
        local export=V.Export()
        if export=='' then hint:SetText('No whisper history to export yet.');return end
        context:SetText(export);context:SetFocus();context:HighlightText()
        hint:SetText('Selected. Press Ctrl+C, then Paste Context in the Windows app.\nGenerate there; WoW cannot call AI directly.')
    end)
    local contextScroll=CreateFrame('ScrollFrame',nil,panel)
    contextScroll:SetPoint('TOPLEFT',155,-324);contextScroll:SetSize(302,25)
    context=edit(contextScroll,0,0,292,25,true);contextScroll:SetScrollChild(context)
    -- Highlight all includes every export row, even when the field shows one row.
    label(panel,'Paste a reviewed AI reply:',14,-361,420)
    reply=edit(panel,20,-383,435,27,false);reply:SetMaxBytes(240)
    button(panel,'Prepare Whisper',14,-420,155,function()
        local c=V.conversations[V.selected]
        if c and reply:GetText()~='' then ChatFrame_OpenChat('/w '..c.name..' '..reply:GetText());reply:ClearFocus() end
    end)
    status=label(panel,'',180,-422,280)
    V.Refresh()
end
