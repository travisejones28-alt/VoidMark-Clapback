local _, V = ...

function V.CreateMinimapIcon()
    if V.minimapIcon or not Minimap then return end
    local b=CreateFrame('Button','VoidMarkClapbackMinimapButton',Minimap,'BackdropTemplate')
    V.minimapIcon=b
    b:SetSize(28,28)
    b:SetFrameStrata('MEDIUM')
    b:SetFrameLevel(Minimap:GetFrameLevel()+10)
    b:SetClampedToScreen(true)
    b:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Buttons\\WHITE8X8',edgeSize=2})
    b:SetBackdropColor(0.12,0.05,0.2,1)
    b:SetBackdropBorderColor(0.65,0.35,1,1)
    local icon=b:CreateTexture(nil,'ARTWORK')
    icon:SetPoint('TOPLEFT',3,-3);icon:SetPoint('BOTTOMRIGHT',-3,3)
    icon:SetTexture('Interface\\ChatFrame\\UI-ChatIcon-Chat-Up')
    icon:SetVertexColor(0.8,0.55,1)
    b:SetHighlightTexture('Interface\\Buttons\\ButtonHilight-Square','ADD')
    b:RegisterForClicks('LeftButtonUp')
    b:RegisterForDrag('LeftButton')

    local function position()
        local angle=math.rad(tonumber(V.db.minimapAngle) or 225)
        local x,y=math.cos(angle),math.sin(angle)
        local shape=GetMinimapShape and GetMinimapShape() or 'ROUND'
        -- Project onto the square perimeter when ElvUI reports a square map.
        if shape=='SQUARE' then
            local scale=math.max(math.abs(x),math.abs(y))
            x,y=x/scale,y/scale
        end
        b:ClearAllPoints()
        b:SetPoint('CENTER',Minimap,'CENTER',x*(Minimap:GetWidth()/2+8),y*(Minimap:GetHeight()/2+8))
    end
    b:SetScript('OnClick',function()
        if b.ignoreClickUntil and GetTime()<b.ignoreClickUntil then return end
        if VoidMarkClapbackFrame and VoidMarkClapbackFrame:IsShown() then
            VoidMarkClapbackFrame:Hide()
        else V.Open() end
    end)
    b:SetScript('OnDragStart',function()
        GameTooltip:Hide()
        b:SetScript('OnUpdate',function()
            local mx,my=Minimap:GetCenter()
            if not mx then return end
            local x,y=GetCursorPosition()
            local scale=Minimap:GetEffectiveScale()
            V.db.minimapAngle=math.deg(math.atan2(y/scale-my,x/scale-mx))
            position()
        end)
    end)
    local function stopDrag()
        b:SetScript('OnUpdate',nil)
        b.ignoreClickUntil=GetTime()+0.15
    end
    b:SetScript('OnDragStop',stopDrag)
    b:SetScript('OnHide',stopDrag)
    b:SetScript('OnEnter',function()
        GameTooltip:SetOwner(b,'ANCHOR_LEFT')
        GameTooltip:AddLine('VoidMark Clapback',0.7,0.4,1)
        GameTooltip:AddLine('Left-click: open / close',1,1,1)
        GameTooltip:AddLine('Drag: move around the minimap',0.8,0.8,0.8)
        GameTooltip:Show()
    end)
    b:SetScript('OnLeave',function()GameTooltip:Hide()end)
    Minimap:HookScript('OnSizeChanged',position)
    Minimap:HookScript('OnShow',position)
    b:RegisterEvent('PLAYER_ENTERING_WORLD')
    b:SetScript('OnEvent',function()position();if C_Timer then C_Timer.After(1,position) end end)
    position()
end
