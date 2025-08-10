-- ProfitDisplay.lua
-- Additional UI components for displaying detailed profit information

local addonName, addon = ...

-- Create global ProfitDisplay module
IronPawProfitProfitDisplay = {}

-- Initialize the module
function IronPawProfitProfitDisplay:Initialize(mainAddon)
    self.addon = mainAddon
    
    -- Create detailed profit window
    function self.addon:CreateProfitDetailWindow()
    if self.profitDetailFrame then
        return self.profitDetailFrame
    end
    
    local frame = CreateFrame("Frame", "IronPawProfitDetailFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(400, 300)
    frame:SetPoint("CENTER", 200, 0)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()
    
    -- Title
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    frame.title:SetPoint("TOP", frame, "TOP", 0, -5)
    frame.title:SetText("Profit Details")
    
    -- Item display area
    frame.itemIcon = frame:CreateTexture(nil, "ARTWORK")
    frame.itemIcon:SetSize(32, 32)
    frame.itemIcon:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -40)
    
    frame.itemName = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.itemName:SetPoint("LEFT", frame.itemIcon, "RIGHT", 10, 0)
    frame.itemName:SetText("Item Name")
    
    -- Profit breakdown
    frame.profitBreakdown = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.profitBreakdown:SetPoint("TOPLEFT", frame.itemIcon, "BOTTOMLEFT", 0, -20)
    frame.profitBreakdown:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -20, -72)
    frame.profitBreakdown:SetJustifyH("LEFT")
    frame.profitBreakdown:SetJustifyV("TOP")
    
    -- Market trend chart area
    frame.trendFrame = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.trendFrame:SetSize(360, 120)
    frame.trendFrame:SetPoint("TOPLEFT", frame.profitBreakdown, "BOTTOMLEFT", 0, -20)
    frame.trendFrame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 3, right = 3, top = 5, bottom = 3 }
    })
    frame.trendFrame:SetBackdropColor(0, 0, 0, 0.5)
    frame.trendFrame:SetBackdropBorderColor(0.4, 0.4, 0.4)
    
    frame.trendTitle = frame.trendFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.trendTitle:SetPoint("TOP", frame.trendFrame, "TOP", 0, -5)
    frame.trendTitle:SetText("7-Day Price Trend")
    
    -- Action buttons
    frame.buyButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    frame.buyButton:SetSize(100, 25)
    frame.buyButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 20, 20)
    frame.buyButton:SetText("Go to NPC")
    frame.buyButton:SetScript("OnClick", function()
        IronPawProfit:ShowNamIronpawLocation()
    end)
    
    frame.closeButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    frame.closeButton:SetSize(80, 25)
    frame.closeButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 20)
    frame.closeButton:SetText("Close")
    frame.closeButton:SetScript("OnClick", function()
        frame:Hide()
    end)
    
    self.profitDetailFrame = frame
    return frame
end

-- Show detailed profit information for an item
        function IronPawProfit:ShowProfitDetails(itemData, recommendation)
    if not itemData then return end
    
    local frame = self:CreateProfitDetailWindow()
    
    -- Update item display
    local texture = GetItemIcon(itemData.itemID)
    if texture then
        frame.itemIcon:SetTexture(texture)
    end
    
    frame.itemName:SetText(itemData.name or "Unknown Item")
    
    -- Calculate detailed breakdown
    local breakdown = self:GenerateProfitBreakdown(itemData, recommendation)
    frame.profitBreakdown:SetText(breakdown)
    
    -- Update trend display
    self:UpdateTrendDisplay(frame.trendFrame, itemData.itemID)
    
    frame:Show()
end

-- Generate detailed profit breakdown text
        function IronPawProfit:GenerateProfitBreakdown(itemData, recommendation)
    local text = ""
    
    -- Basic info
    text = text .. string.format("|cffffd700Basic Information:|r\n")
    text = text .. string.format("Token Cost: %d tokens\n", itemData.tokenCost)
    text = text .. string.format("Stack Size: %d items\n", itemData.stackSize)
    text = text .. string.format("Market Price: %s per item\n", self:FormatMoney(itemData.marketPrice))
    text = text .. string.format("Server Median: %s per item\n", self:FormatMoney(itemData.serverMedian))
    text = text .. "\n"
    
    -- Profit calculation
    text = text .. string.format("|cff00ff00Profit Analysis:|r\n")
    text = text .. string.format("Revenue per stack: %s\n", self:FormatMoney(itemData.marketPrice * itemData.stackSize))
    text = text .. string.format("Cost per stack: %d tokens (no gold)\n", itemData.tokenCost)
    text = text .. string.format("Profit per token: %s\n", self:FormatMoney(itemData.profitPerToken))
    text = text .. string.format("Profit per stack: %s\n", self:FormatMoney(itemData.profitPerStack))
    text = text .. "\n"
    
    -- Recommendation details
    if recommendation then
        text = text .. string.format("|cff88ccffRecommendation:|r\n")
        text = text .. string.format("Suggested purchase: %d stacks\n", recommendation.recommendedStacks or 0)
        text = text .. string.format("Tokens needed: %d\n", recommendation.tokensNeeded or 0)
        text = text .. string.format("Total investment value: %s\n", self:FormatMoney(recommendation.totalValue or 0))
        text = text .. string.format("Expected profit: %s\n", self:FormatMoney(recommendation.totalProfit or 0))
        text = text .. "\n"
    end
    
    -- Risk assessment
    if self.ProfitCalculator then
        local risk = self.ProfitCalculator:CalculateRiskAssessment(itemData)
        local riskColor = "|cff00ff00" -- Green
        if risk.level == "medium" then
            riskColor = "|cffffff00" -- Yellow
        elseif risk.level == "high" then
            riskColor = "|cffff0000" -- Red
        end
        
        text = text .. string.format("|cffff8800Risk Assessment:|r\n")
        text = text .. string.format("Risk Level: %s%s|r\n", riskColor, risk.level:upper())
        text = text .. string.format("Recommendation: %s\n", risk.recommendation)
        
        if #risk.factors > 0 then
            text = text .. "Risk Factors:\n"
            for _, factor in ipairs(risk.factors) do
                text = text .. string.format("  • %s\n", factor)
            end
        end
    end
    
    return text
end

-- Update trend display (simplified chart)
        function IronPawProfit:UpdateTrendDisplay(trendFrame, itemID)
    -- Clear existing trend lines
    if trendFrame.trendLines then
        for _, line in pairs(trendFrame.trendLines) do
            line:Hide()
        end
    else
        trendFrame.trendLines = {}
    end
    
    -- Get price history
    if not self.AuctionatorInterface:IsAuctionatorAvailable() then
        local noDataText = trendFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        noDataText:SetPoint("CENTER", trendFrame, "CENTER")
        noDataText:SetText("No trend data available\n(Auctionator required)")
        noDataText:SetTextColor(0.7, 0.7, 0.7)
        return
    end
    
    local history = self.AuctionatorInterface:GetPriceHistory(itemID, 7)
    
    if #history < 2 then
        local noDataText = trendFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        noDataText:SetPoint("CENTER", trendFrame, "CENTER")
        noDataText:SetText("Insufficient data for trend\n(Need 2+ days of data)")
        noDataText:SetTextColor(0.7, 0.7, 0.7)
        return
    end
    
    -- Simple text-based trend display
    local trendText = ""
    local minPrice, maxPrice = math.huge, 0
    
    for _, point in ipairs(history) do
        minPrice = math.min(minPrice, point.price)
        maxPrice = math.max(maxPrice, point.price)
    end
    
    trendText = trendText .. string.format("Price Range: %s - %s\n", 
        self:FormatMoney(minPrice), self:FormatMoney(maxPrice))
    
    -- Calculate trend direction
    local recent = history[1].price
    local old = history[#history].price
    local change = (recent - old) / old * 100
    
    local trendDirection = ""
    local trendColor = "|cffffffff"
    
    if change > 5 then
        trendDirection = "Rising"
        trendColor = "|cff00ff00"
    elseif change < -5 then
        trendDirection = "Falling" 
        trendColor = "|cffff0000"
    else
        trendDirection = "Stable"
        trendColor = "|cffffff00"
    end
    
    trendText = trendText .. string.format("Trend: %s%s|r (%.1f%%)\n", 
        trendColor, trendDirection, change)
    
    trendText = trendText .. string.format("Current: %s\n", self:FormatMoney(recent))
    trendText = trendText .. string.format("7-day avg: %s", 
        self:FormatMoney(self:CalculateAverage(history)))
    
    local displayText = trendFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    displayText:SetPoint("TOPLEFT", trendFrame, "TOPLEFT", 10, -20)
    displayText:SetPoint("BOTTOMRIGHT", trendFrame, "BOTTOMRIGHT", -10, 10)
    displayText:SetJustifyH("LEFT")
    displayText:SetJustifyV("TOP")
    displayText:SetText(trendText)
    
    table.insert(trendFrame.trendLines, displayText)
end

-- Calculate average price from history
        function IronPawProfit:CalculateAverage(history)
    if #history == 0 then return 0 end
    
    local total = 0
    for _, point in ipairs(history) do
        total = total + point.price
    end
    
    return total / #history
end

-- Show Nam Ironpaw location information
        function IronPawProfit:ShowNamIronpawLocation()
    local message = "Nam Ironpaw can be found in Halfhill, Valley of the Four Winds.\n" ..
                   "Coordinates: 53.5, 51.2 (near the cooking trainer)\n" ..
                   "He sells raw cooking materials for Ironpaw Tokens."
    
    StaticPopup_Show("IRONPAW_NPC_LOCATION", message)
end

-- Create static popup for NPC location
StaticPopupDialogs["IRONPAW_NPC_LOCATION"] = {
    text = "Nam Ironpaw Location:\n\n%s",
    button1 = "OK",
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- Create minimap button for quick access
        function IronPawProfit:CreateMinimapButton()
    if self.minimapButton then return end
    
    local button = CreateFrame("Button", "IronPawProfitMinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    
    -- Button texture
    button:SetNormalTexture("Interface\\Icons\\inv_misc_token_argentdawn3")
    button:SetPushedTexture("Interface\\Icons\\inv_misc_token_argentdawn3")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    
    -- Position on minimap
    button:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -15, 15)
    
    -- Click handler
    button:SetScript("OnClick", function(self, button)
        if button == "LeftButton" then
            IronPawProfit:ShowMainFrame()
        elseif button == "RightButton" then
            IronPawProfit:RefreshAuctionData()
        end
    end)
    
    -- Tooltip
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("IronPaw Profit Calculator")
        GameTooltip:AddLine("Left-click: Open main window", 1, 1, 1)
        GameTooltip:AddLine("Right-click: Refresh auction data", 1, 1, 1)
        GameTooltip:Show()
    end)
    
    button:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    self.minimapButton = button
end

    return true
end
