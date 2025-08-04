-- MainFrame.lua
-- Main user interface for the IronPaw Profit Calculator

local addonName, addon = ...

-- Create global MainFrame module
IronPawProfitMainFrame = {}

-- Initialize the module
function IronPawProfitMainFrame:Initialize(mainAddon)
    self.addon = mainAddon
    
    -- Create main frame
    function self.addon:CreateMainFrame()
    if self.mainFrame then
        return self.mainFrame
    end
    
    -- Main frame
    local frame = CreateFrame("Frame", "IronPawProfitMainFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(600, 500)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()
    
    -- Title
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    frame.title:SetPoint("TOP", frame, "TOP", 0, -5)
    frame.title:SetText("IronPaw Profit Calculator")
    
    -- Close button (already provided by BasicFrameTemplate)
    
    -- Token display
    frame.tokenDisplay = CreateFrame("Frame", nil, frame)
    frame.tokenDisplay:SetSize(200, 30)
    frame.tokenDisplay:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -30)
    
    frame.tokenDisplay.icon = frame.tokenDisplay:CreateTexture(nil, "ARTWORK")
    frame.tokenDisplay.icon:SetSize(20, 20)
    frame.tokenDisplay.icon:SetPoint("LEFT")
    frame.tokenDisplay.icon:SetTexture("Interface\\Icons\\inv_misc_token_argentdawn3") -- Ironpaw token icon
    
    frame.tokenDisplay.text = frame.tokenDisplay:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.tokenDisplay.text:SetPoint("LEFT", frame.tokenDisplay.icon, "RIGHT", 5, 0)
    frame.tokenDisplay.text:SetText("Tokens: 0")
    
    -- Scan button
    frame.scanButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    frame.scanButton:SetSize(100, 25)
    frame.scanButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -20, -30)
    frame.scanButton:SetText("Scan AH")
    frame.scanButton:SetScript("OnClick", function()
        IronPawProfit:RefreshAuctionData()
    end)
    
    -- Category dropdown
    frame.categoryDropdown = CreateFrame("Frame", "IronPawCategoryDropdown", frame, "UIDropDownMenuTemplate")
    frame.categoryDropdown:SetPoint("TOPLEFT", frame.tokenDisplay, "BOTTOMLEFT", -15, -10)
    UIDropDownMenu_SetWidth(frame.categoryDropdown, 120)
    UIDropDownMenu_SetText(frame.categoryDropdown, "All Categories")
    
    -- Initialize dropdown
    UIDropDownMenu_Initialize(frame.categoryDropdown, function(self, level)
        local categories = IronPawProfit.Categories or {"All", "Meat", "Seafood", "Vegetable", "Fruit", "Reagent", "Bundle"}
        for _, category in ipairs(categories) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = category
            info.value = category
            info.func = function()
                UIDropDownMenu_SetSelectedValue(frame.categoryDropdown, category)
                IronPawProfit:FilterByCategory(category)
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    
    -- Profit threshold controls
    frame.thresholdLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.thresholdLabel:SetPoint("TOPLEFT", frame.categoryDropdown, "BOTTOMLEFT", 15, -10)
    frame.thresholdLabel:SetText("Min Profit:")
    
    frame.thresholdEditBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    frame.thresholdEditBox:SetSize(60, 20)
    frame.thresholdEditBox:SetPoint("LEFT", frame.thresholdLabel, "RIGHT", 5, 0)
    frame.thresholdEditBox:SetText(tostring(IronPawProfit.db.profile.minProfit or 1))
    frame.thresholdEditBox:SetScript("OnEnterPressed", function(self)
        local value = tonumber(self:GetText()) or 1
        IronPawProfit.db.profile.minProfit = value
        IronPawProfit:UpdateProfitCalculations()
        self:ClearFocus()
    end)
    
    frame.goldLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.goldLabel:SetPoint("LEFT", frame.thresholdEditBox, "RIGHT", 5, 0)
    frame.goldLabel:SetText("gold")
    
    -- Update button
    frame.updateButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    frame.updateButton:SetSize(80, 25)
    frame.updateButton:SetPoint("LEFT", frame.goldLabel, "RIGHT", 20, 0)
    frame.updateButton:SetText("Update")
    frame.updateButton:SetScript("OnClick", function()
        IronPawProfit:UpdateProfitCalculations()
    end)
    
    -- Summary panel
    frame.summaryPanel = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.summaryPanel:SetSize(560, 60)
    frame.summaryPanel:SetPoint("TOPLEFT", frame.thresholdLabel, "BOTTOMLEFT", 0, -20)
    frame.summaryPanel:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 3, right = 3, top = 5, bottom = 3 }
    })
    frame.summaryPanel:SetBackdropColor(0, 0, 0, 0.25)
    frame.summaryPanel:SetBackdropBorderColor(0.4, 0.4, 0.4)
    
    -- Summary text
    frame.summaryText = frame.summaryPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.summaryText:SetPoint("TOPLEFT", frame.summaryPanel, "TOPLEFT", 10, -5)
    frame.summaryText:SetPoint("BOTTOMRIGHT", frame.summaryPanel, "BOTTOMRIGHT", -10, 5)
    frame.summaryText:SetJustifyH("LEFT")
    frame.summaryText:SetJustifyV("TOP")
    frame.summaryText:SetText("Click 'Update' to calculate profit recommendations...")
    
    -- Scroll frame for results
    frame.scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    frame.scrollFrame:SetPoint("TOPLEFT", frame.summaryPanel, "BOTTOMLEFT", 0, -10)
    frame.scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 20)
    
    -- Content frame for scroll
    frame.contentFrame = CreateFrame("Frame", nil, frame.scrollFrame)
    frame.contentFrame:SetSize(1, 1) -- Will be resized as needed
    frame.scrollFrame:SetScrollChild(frame.contentFrame)
    
    -- Results display
    frame.resultRows = {}
    
    self.mainFrame = frame
    return frame
end

        -- Show the main frame
        function IronPawProfit:ShowMainFrame()
            -- Ensure Categories are available before creating UI
            if not self.Categories then
                self.Categories = {"All", "Meat", "Seafood", "Vegetable", "Fruit", "Reagent", "Bundle"}
            end
            
            if not self.mainFrame then
                self:CreateMainFrame()
            end
            
            self.mainFrame:Show()
            self:UpdateTokenDisplay()
            self:UpdateProfitCalculations()
        end-- Update token display
        function IronPawProfit:UpdateTokenDisplay(tokens)
    if not self.mainFrame then return end
    
    tokens = tokens or self:GetIronpawTokenCount()
    self.mainFrame.tokenDisplay.text:SetText(string.format("Tokens: %d", tokens))
end

-- Filter results by category
        function IronPawProfit:FilterByCategory(category)
    self.selectedCategory = category
    self:UpdateProfitCalculations()
end

-- Update profit calculations and display
        function IronPawProfit:UpdateProfitCalculations()
    if not self.mainFrame or not self.mainFrame:IsShown() then
        return
    end
    
    -- Safety check: ensure ProfitCalculator and Database exist
    if not self.ProfitCalculator or not self.Database then
        self.mainFrame.summaryText:SetText("Waiting for data to load...")
        return
    end
    
    local tokens = self:GetIronpawTokenCount()
    local category = self.selectedCategory or "All"
    
    -- Generate investment report
    local report = self.ProfitCalculator:GenerateInvestmentReport(tokens)
    
    -- Update summary
    self:UpdateSummaryDisplay(report)
    
    -- Update results list
    self:UpdateResultsDisplay(report.recommendations, category)
end

-- Update summary display
        function IronPawProfit:UpdateSummaryDisplay(report)
    if not self.mainFrame then return end
    
    -- Safety check for report structure
    if not report or not report.summary then
        self.mainFrame.summaryText:SetText("No data available. Click 'Scan AH' to refresh auction data.")
        return
    end
    
    local summary = report.summary
    local warnings = report.warnings or {}
    
    local text = string.format(
        "Recommendations: %d items | Tokens to spend: %d/%d | Total profit potential: %s\n" ..
        "Average profit per token: %s | Top item: %s",
        summary.totalRecommendations or 0,
        summary.totalTokensToSpend or 0,
        report.availableTokens or 0,
        self:FormatMoney(summary.totalProfitPotential or 0),
        self:FormatMoney(summary.averageProfitPerToken or 0),
        summary.topProfitItem or "None"
    )
    
    if #warnings > 0 then
        text = text .. "\n|cffff8800Warnings:|r " .. table.concat(warnings, ", ")
    end
    
    self.mainFrame.summaryText:SetText(text)
end

-- Update results display
        function IronPawProfit:UpdateResultsDisplay(recommendations, category)
    if not self.mainFrame then return end
    
    -- Clear existing rows
    for _, row in pairs(self.mainFrame.resultRows) do
        row:Hide()
    end
    
    -- Safety check for recommendations
    if not recommendations then
        return
    end
    
    -- Filter recommendations by category
    local filteredRecs = {}
    for _, rec in ipairs(recommendations) do
        if rec and rec.itemData and (category == "All" or rec.itemData.category == category) then
            table.insert(filteredRecs, rec)
        end
    end
    
    -- Create/update rows
    local yOffset = -10
    for i, rec in ipairs(filteredRecs) do
        local row = self:GetOrCreateResultRow(i)
        self:UpdateResultRow(row, rec, i)
        
        row:SetPoint("TOPLEFT", self.mainFrame.contentFrame, "TOPLEFT", 10, yOffset)
        row:Show()
        
        yOffset = yOffset - 35
    end
    
    -- Update content frame size
    self.mainFrame.contentFrame:SetHeight(math.abs(yOffset) + 20)
end

-- Get or create a result row
        function IronPawProfit:GetOrCreateResultRow(index)
    if self.mainFrame.resultRows[index] then
        return self.mainFrame.resultRows[index]
    end
    
    local row = CreateFrame("Frame", nil, self.mainFrame.contentFrame)
    row:SetSize(520, 30)
    
    -- Item icon
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(24, 24)
    row.icon:SetPoint("LEFT", row, "LEFT", 5, 0)
    
    -- Item name
    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.name:SetPoint("LEFT", row.icon, "RIGHT", 5, 0)
    row.name:SetSize(150, 20)
    row.name:SetJustifyH("LEFT")
    
    -- Token cost
    row.tokens = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.tokens:SetPoint("LEFT", row.name, "RIGHT", 5, 0)
    row.tokens:SetSize(50, 20)
    row.tokens:SetJustifyH("CENTER")
    
    -- Profit per token
    row.profit = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.profit:SetPoint("LEFT", row.tokens, "RIGHT", 5, 0)
    row.profit:SetSize(80, 20)
    row.profit:SetJustifyH("RIGHT")
    
    -- Recommended quantity
    row.quantity = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.quantity:SetPoint("LEFT", row.profit, "RIGHT", 5, 0)
    row.quantity:SetSize(50, 20)
    row.quantity:SetJustifyH("CENTER")
    
    -- Total profit
    row.totalProfit = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.totalProfit:SetPoint("LEFT", row.quantity, "RIGHT", 5, 0)
    row.totalProfit:SetSize(80, 20)
    row.totalProfit:SetJustifyH("RIGHT")
    
    -- Background
    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints()
    row.bg:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    row.bg:SetAlpha(0)
    
    -- Hover effect
    row:SetScript("OnEnter", function(self)
        self.bg:SetAlpha(0.3)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        IronPawProfit:ShowItemTooltip(self.itemData)
    end)
    
    row:SetScript("OnLeave", function(self)
        self.bg:SetAlpha(0)
        GameTooltip:Hide()
    end)
    
    self.mainFrame.resultRows[index] = row
    return row
end

-- Update a result row with data
        function IronPawProfit:UpdateResultRow(row, recommendation, index)
    local item = recommendation.itemData
    
    -- Store data for tooltip
    row.itemData = item
    row.recommendation = recommendation
    
    -- Set item icon
    local texture = GetItemIcon(item.itemID)
    if texture then
        row.icon:SetTexture(texture)
    end
    
    -- Color code by profitability
    local color = "|cffffffff" -- White
    if recommendation.profitPerToken > 50000 then -- > 5 gold per token
        color = "|cff00ff00" -- Green
    elseif recommendation.profitPerToken > 20000 then -- > 2 gold per token
        color = "|cffffff00" -- Yellow
    elseif recommendation.profitPerToken < 5000 then -- < 50 silver per token
        color = "|cffff8000" -- Orange
    end
    
    -- Update text
    row.name:SetText(color .. (item.name or "Unknown"))
    row.tokens:SetText(string.format("%d", item.tokenCost))
    row.profit:SetText(color .. self:FormatMoneyPrecise(recommendation.profitPerToken))
    row.quantity:SetText(string.format("%d", recommendation.recommendedStacks or 0))
    row.totalProfit:SetText(color .. self:FormatMoney(recommendation.totalProfit or 0))
    
    -- Alternate row colors
    if index % 2 == 0 then
        row.bg:SetColorTexture(0.1, 0.1, 0.1, 0.5)
    else
        row.bg:SetColorTexture(0, 0, 0, 0)
    end
end

-- Show item tooltip
        function IronPawProfit:ShowItemTooltip(itemData)
    if not itemData then return end
    
    GameTooltip:SetHyperlink("item:" .. itemData.itemID)
    
    -- Add custom profit information
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("IronPaw Profit Info:", 1, 1, 0)
    GameTooltip:AddLine(string.format("Token Cost: %d", itemData.tokenCost), 1, 1, 1)
    GameTooltip:AddLine(string.format("Market Price: %s", self:FormatMoney(itemData.marketPrice)), 1, 1, 1)
    
    -- For sacks, show the price per individual item
    if itemData.contains and itemData.contains > 1 then
        local pricePerItem = math.floor(itemData.marketPrice / itemData.contains)
        GameTooltip:AddLine(string.format("Price per Item: %s", self:FormatMoney(pricePerItem)), 0.8, 0.8, 1)
        GameTooltip:AddLine(string.format("Contains: %d items", itemData.contains), 0.7, 0.7, 0.7)
    end
    
    GameTooltip:AddLine(string.format("Profit per Token: %s", self:FormatMoney(itemData.profitPerToken)), 0, 1, 0)
    GameTooltip:AddLine(string.format("Stack Size: %d", itemData.stackSize), 1, 1, 1)
    
    if itemData.lastScanned > 0 then
        local timeAgo = time() - itemData.lastScanned
        local hours = math.floor(timeAgo / 3600)
        GameTooltip:AddLine(string.format("Data Age: %d hours", hours), 0.7, 0.7, 0.7)
    end
    
    GameTooltip:Show()
end

    return true
end
