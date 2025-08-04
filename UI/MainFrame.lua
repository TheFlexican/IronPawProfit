-- MainFrame.lua
-- Main user interface for the IronPaw Profit Calculator

local addonName, addon = ...

-- Create global MainFrame module
IronPawProfitMainFrame = {}

-- Initialize the module
function IronPawProfitMainFrame:Initialize(mainAddon)
    self.addon = mainAddon
    
    -- Attach functions to the main addon
    self:AttachFunctions()
    
    -- Create main frame
    function self.addon:CreateMainFrame()
    if self.mainFrame then
        return self.mainFrame
    end
    
    -- Store addon reference for closures
    local addon = self
    
    -- Main frame
    local frame = CreateFrame("Frame", "IronPawProfitMainFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(700, 600)
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
    
    -- Create tab system
    frame.tabs = {}
    frame.activeTab = 1
    
    -- Tab button creation function
    local function CreateTab(parent, text, index)
        local tab = CreateFrame("Button", nil, parent, "GameMenuButtonTemplate")
        tab:SetSize(120, 25)
        tab:SetText(text)
        tab:SetPoint("TOPLEFT", parent, "TOPLEFT", 20 + (index - 1) * 125, -25)
        
        tab:SetScript("OnClick", function()
            addon:ShowTab(index)
        end)
        
        return tab
    end
    
    -- Create tabs
    frame.tabs[1] = CreateTab(frame, "Nam Ironpaw", 1)
    frame.tabs[2] = CreateTab(frame, "Token Arbitrage", 2)
    frame.tabs[3] = CreateTab(frame, "Raw Materials", 3)
    
    -- Tab content panels
    frame.tabPanels = {}
    
    -- Create content area for tabs
    local contentY = -55
    
    -- Create content area for tabs
    local contentY = -55
    
    -- TAB 1: Nam Ironpaw (Original functionality)
    frame.tabPanels[1] = CreateFrame("Frame", nil, frame)
    frame.tabPanels[1]:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, contentY)
    frame.tabPanels[1]:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    
    -- Token display (Tab 1)
    frame.tokenDisplay = CreateFrame("Frame", nil, frame.tabPanels[1])
    frame.tokenDisplay:SetSize(200, 30)
    frame.tokenDisplay:SetPoint("TOPLEFT", frame.tabPanels[1], "TOPLEFT", 20, -10)
    
    frame.tokenDisplay.icon = frame.tokenDisplay:CreateTexture(nil, "ARTWORK")
    frame.tokenDisplay.icon:SetSize(20, 20)
    frame.tokenDisplay.icon:SetPoint("LEFT")
    frame.tokenDisplay.icon:SetTexture("Interface\\Icons\\inv_misc_token_argentdawn3") -- Ironpaw token icon
    
    frame.tokenDisplay.text = frame.tokenDisplay:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.tokenDisplay.text:SetPoint("LEFT", frame.tokenDisplay.icon, "RIGHT", 5, 0)
    frame.tokenDisplay.text:SetText("Tokens: 0")
    
    -- Scan button (Tab 1)
    frame.scanButton = CreateFrame("Button", nil, frame.tabPanels[1], "GameMenuButtonTemplate")
    frame.scanButton:SetSize(100, 25)
    frame.scanButton:SetPoint("TOPRIGHT", frame.tabPanels[1], "TOPRIGHT", -20, -10)
    frame.scanButton:SetText("Scan AH")
    frame.scanButton:SetScript("OnClick", function()
        addon:RefreshAuctionData()
    end)
    
    -- Category dropdown (Tab 1)
    frame.categoryDropdown = CreateFrame("Frame", "IronPawCategoryDropdown", frame.tabPanels[1], "UIDropDownMenuTemplate")
    frame.categoryDropdown:SetPoint("TOPLEFT", frame.tokenDisplay, "BOTTOMLEFT", -15, -10)
    UIDropDownMenu_SetWidth(frame.categoryDropdown, 120)
    UIDropDownMenu_SetText(frame.categoryDropdown, "All Categories")
    
    -- Initialize dropdown (Tab 1)
    UIDropDownMenu_Initialize(frame.categoryDropdown, function(self, level)
        local categories = addon.Categories or {"All", "Meat", "Seafood", "Vegetable", "Fruit", "Reagent", "Bundle"}
        for _, category in ipairs(categories) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = category
            info.value = category
            info.func = function()
                UIDropDownMenu_SetSelectedValue(frame.categoryDropdown, category)
                addon:FilterByCategory(category)
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    
    -- Profit threshold controls (Tab 1)
    frame.thresholdLabel = frame.tabPanels[1]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.thresholdLabel:SetPoint("TOPLEFT", frame.categoryDropdown, "BOTTOMLEFT", 15, -10)
    frame.thresholdLabel:SetText("Min Profit:")
    
    frame.thresholdEditBox = CreateFrame("EditBox", nil, frame.tabPanels[1], "InputBoxTemplate")
    frame.thresholdEditBox:SetSize(60, 20)
    frame.thresholdEditBox:SetPoint("LEFT", frame.thresholdLabel, "RIGHT", 5, 0)
    frame.thresholdEditBox:SetText(tostring(addon.db.profile.minProfit or 1))
    frame.thresholdEditBox:SetScript("OnEnterPressed", function(editbox)
        local value = tonumber(editbox:GetText()) or 1
        addon.db.profile.minProfit = value
        addon:UpdateProfitCalculations()
        editbox:ClearFocus()
    end)
    
    frame.goldLabel = frame.tabPanels[1]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.goldLabel:SetPoint("LEFT", frame.thresholdEditBox, "RIGHT", 5, 0)
    frame.goldLabel:SetText("gold")
    
    -- Update button (Tab 1)
    frame.updateButton = CreateFrame("Button", nil, frame.tabPanels[1], "GameMenuButtonTemplate")
    frame.updateButton:SetSize(80, 25)
    frame.updateButton:SetPoint("LEFT", frame.goldLabel, "RIGHT", 20, 0)
    frame.updateButton:SetText("Update")
    frame.updateButton:SetScript("OnClick", function()
        addon:UpdateProfitCalculations()
    end)
    
    -- Summary panel (Tab 1)
    frame.summaryPanel = CreateFrame("Frame", nil, frame.tabPanels[1], "BackdropTemplate")
    frame.summaryPanel:SetSize(660, 60)
    frame.summaryPanel:SetPoint("TOPLEFT", frame.thresholdLabel, "BOTTOMLEFT", 0, -20)
    frame.summaryPanel:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 3, right = 3, top = 5, bottom = 3 }
    })
    frame.summaryPanel:SetBackdropColor(0, 0, 0, 0.25)
    frame.summaryPanel:SetBackdropBorderColor(0.4, 0.4, 0.4)
    
    -- Summary text (Tab 1)
    frame.summaryText = frame.summaryPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.summaryText:SetPoint("TOPLEFT", frame.summaryPanel, "TOPLEFT", 10, -5)
    frame.summaryText:SetPoint("BOTTOMRIGHT", frame.summaryPanel, "BOTTOMRIGHT", -10, 5)
    frame.summaryText:SetJustifyH("LEFT")
    frame.summaryText:SetJustifyV("TOP")
    frame.summaryText:SetText("Click 'Update' to calculate profit recommendations...")
    
    -- Scroll frame for results (Tab 1)
    frame.scrollFrame = CreateFrame("ScrollFrame", nil, frame.tabPanels[1], "UIPanelScrollFrameTemplate")
    frame.scrollFrame:SetPoint("TOPLEFT", frame.summaryPanel, "BOTTOMLEFT", 0, -10)
    frame.scrollFrame:SetPoint("BOTTOMRIGHT", frame.tabPanels[1], "BOTTOMRIGHT", -30, 20)
    
    -- Content frame for scroll (Tab 1)
    frame.contentFrame = CreateFrame("Frame", nil, frame.scrollFrame)
    frame.contentFrame:SetSize(1, 1) -- Will be resized as needed
    frame.scrollFrame:SetScrollChild(frame.contentFrame)
    
    -- Results display (Tab 1)
    frame.resultRows = {}
    
    -- TAB 2: Token Arbitrage (Merchant Cheng)
    frame.tabPanels[2] = CreateFrame("Frame", nil, frame)
    frame.tabPanels[2]:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, contentY)
    frame.tabPanels[2]:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    frame.tabPanels[2]:Hide()
    
    -- Container cost setting (Tab 2)
    -- Container cost is now fixed at 1.35g per container (set in logic, not configurable)
    
    -- Arbitrage scan button (Tab 2)
    frame.arbitrageScanButton = CreateFrame("Button", nil, frame.tabPanels[2], "GameMenuButtonTemplate")
    frame.arbitrageScanButton:SetSize(120, 25)
    frame.arbitrageScanButton:SetPoint("TOPRIGHT", frame.tabPanels[2], "TOPRIGHT", -20, -10)
    frame.arbitrageScanButton:SetText("Find Arbitrage")
    frame.arbitrageScanButton:SetScript("OnClick", function()
        if IronPawProfit and IronPawProfit.ShowMerchantChengArbitrage then
            IronPawProfit:ShowMerchantChengArbitrage()
        end
    end)
    
    -- Instructions (Tab 2)
frame.arbitrageInstructions = frame.tabPanels[2]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
frame.arbitrageInstructions:SetPoint("TOPLEFT", frame.tabPanels[2], "TOPLEFT", 20, -40)
frame.arbitrageInstructions:SetPoint("TOPRIGHT", frame.tabPanels[2], "TOPRIGHT", -20, -50)
    frame.arbitrageInstructions:SetJustifyH("LEFT")
    frame.arbitrageInstructions:SetJustifyV("TOP")
    frame.arbitrageInstructions:SetText("|cffffd100Token Arbitrage Strategy:|r\n1. Find cheapest raw materials to generate tokens via Merchant Cheng\n2. Use those tokens to buy most valuable sacks from Nam Ironpaw\n3. Sell sacks on auction house for profit\n\nExample: Buy Golden Carp (60x) + Container → 1 Token → Buy White Turnip Sack → Sell for profit")
    
    -- Arbitrage results (Tab 2)
    frame.arbitrageScrollFrame = CreateFrame("ScrollFrame", nil, frame.tabPanels[2], "UIPanelScrollFrameTemplate")
    frame.arbitrageScrollFrame:SetPoint("TOPLEFT", frame.arbitrageInstructions, "BOTTOMLEFT", 0, -20)
    frame.arbitrageScrollFrame:SetPoint("BOTTOMRIGHT", frame.tabPanels[2], "BOTTOMRIGHT", -30, 20)
    
    frame.arbitrageContentFrame = CreateFrame("Frame", nil, frame.arbitrageScrollFrame)
    frame.arbitrageContentFrame:SetSize(1, 1)
    frame.arbitrageScrollFrame:SetScrollChild(frame.arbitrageContentFrame)
    
    frame.arbitrageRows = {}
    
    -- TAB 3: Raw Materials (Merchant Cheng)
    frame.tabPanels[3] = CreateFrame("Frame", nil, frame)
    frame.tabPanels[3]:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, contentY)
    frame.tabPanels[3]:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    frame.tabPanels[3]:Hide()
    
    -- Material cost analysis button (Tab 3)
    frame.materialScanButton = CreateFrame("Button", nil, frame.tabPanels[3], "GameMenuButtonTemplate")
    frame.materialScanButton:SetSize(140, 25)
    frame.materialScanButton:SetPoint("TOPRIGHT", frame.tabPanels[3], "TOPRIGHT", -20, -10)
    frame.materialScanButton:SetText("Analyze Materials")
    frame.materialScanButton:SetScript("OnClick", function()
        if addon and addon.ShowRawMaterialAnalysis then
            addon:ShowRawMaterialAnalysis()
        end
    end)
    
    -- Filter by material type (Tab 3)
    frame.materialTypeDropdown = CreateFrame("Frame", "IronPawMaterialTypeDropdown", frame.tabPanels[3], "UIDropDownMenuTemplate")
    frame.materialTypeDropdown:SetPoint("TOPLEFT", frame.tabPanels[3], "TOPLEFT", 5, -10)
    UIDropDownMenu_SetWidth(frame.materialTypeDropdown, 120)
    UIDropDownMenu_SetText(frame.materialTypeDropdown, "All Materials")
    
    -- Initialize material type dropdown (Tab 3)
    UIDropDownMenu_Initialize(frame.materialTypeDropdown, function(self, level)
        local materialTypes = {"All Materials", "Fish (20 qty)", "Fish (60 qty)", "Meat (20 qty)", "Vegetables (100 qty)"}
        for _, materialType in ipairs(materialTypes) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = materialType
            info.value = materialType
            info.func = function()
                UIDropDownMenu_SetSelectedValue(frame.materialTypeDropdown, materialType)
                if addon and addon.FilterMaterialsByType then
                    addon:FilterMaterialsByType(materialType)
                end
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    
    -- Instructions (Tab 3)
    frame.materialInstructions = frame.tabPanels[3]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.materialInstructions:SetPoint("TOPLEFT", frame.materialTypeDropdown, "BOTTOMLEFT", 15, -20)
    frame.materialInstructions:SetPoint("TOPRIGHT", frame.tabPanels[3], "TOPRIGHT", -20, -60)
    frame.materialInstructions:SetJustifyH("LEFT")
    frame.materialInstructions:SetJustifyV("TOP")
    frame.materialInstructions:SetText("|cffffd100Raw Material Analysis:|r\nCompare costs to generate tokens using different raw materials:\n• Fish: Most need 20, Golden Carp needs 60\n• Meat: All need 20\n• Vegetables: All need 100 (most expensive per token)")
    
    -- Material results (Tab 3)
    frame.materialScrollFrame = CreateFrame("ScrollFrame", nil, frame.tabPanels[3], "UIPanelScrollFrameTemplate")
    frame.materialScrollFrame:SetPoint("TOPLEFT", frame.materialInstructions, "BOTTOMLEFT", 0, -20)
    frame.materialScrollFrame:SetPoint("BOTTOMRIGHT", frame.tabPanels[3], "BOTTOMRIGHT", -30, 20)
    
    frame.materialContentFrame = CreateFrame("Frame", nil, frame.materialScrollFrame)
    frame.materialContentFrame:SetSize(1, 1)
    frame.materialScrollFrame:SetScrollChild(frame.materialContentFrame)
    
    frame.materialRows = {}
    
    -- Tab switching function
    function addon:ShowTab(tabIndex)
        local frame = self.mainFrame
        if not frame or not frame.tabPanels then return end
        
        -- Hide all tabs
        for i, panel in ipairs(frame.tabPanels) do
            panel:Hide()
        end
        
        -- Update tab button appearances
        for i, tab in ipairs(frame.tabs) do
            if i == tabIndex then
                tab:SetNormalFontObject("GameFontHighlightLarge")
                tab:LockHighlight()
            else
                tab:SetNormalFontObject("GameFontNormal")
                tab:UnlockHighlight()
            end
        end
        
        -- Show selected tab
        if frame.tabPanels[tabIndex] then
            frame.tabPanels[tabIndex]:Show()
            frame.activeTab = tabIndex
        end
    end
    
    self.mainFrame = frame
    return frame
end

        -- Show the main frame
        function self.addon:ShowMainFrame()
            -- Ensure Categories are available before creating UI
            if not self.Categories then
                self.Categories = {"All", "Meat", "Seafood", "Vegetable", "Fruit", "Reagent", "Bundle"}
            end
            
            if not self.mainFrame then
                self:CreateMainFrame()
            end
            
            self.mainFrame:Show()
            
            -- Initialize with the first tab
            self:ShowTab(1)
            
            self:UpdateTokenDisplay()
            self:UpdateProfitCalculations()
        end-- Update token display
        function self.addon:UpdateTokenDisplay(tokens)
    if not self.mainFrame then return end
    
    tokens = tokens or self:GetIronpawTokenCount()
    self.mainFrame.tokenDisplay.text:SetText(string.format("Tokens: %d", tokens))
end

-- Filter results by category
        function self.addon:FilterByCategory(category)
    self.selectedCategory = category
    self:UpdateProfitCalculations()
end

-- Update profit calculations and display
        function self.addon:UpdateProfitCalculations()
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
        function self.addon:UpdateSummaryDisplay(report)
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
        function self.addon:UpdateResultsDisplay(recommendations, category)
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
        function self.addon:GetOrCreateResultRow(index)
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
        if IronPawProfitMainFrame.addon and IronPawProfitMainFrame.addon.ShowItemTooltip then
            IronPawProfitMainFrame.addon:ShowItemTooltip(self.itemData)
        end
    end)
    
    row:SetScript("OnLeave", function(self)
        self.bg:SetAlpha(0)
        GameTooltip:Hide()
    end)
    
    self.mainFrame.resultRows[index] = row
    return row
end

-- Update a result row with data
        function self.addon:UpdateResultRow(row, recommendation, index)
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
    if recommendation.profitPerToken > 10 then -- > 100 gold per token
        color = "|cff00ff00" -- Green
    elseif recommendation.profitPerToken > 50 then -- > 50 gold per token
        color = "|cffffff00" -- Yellow
    elseif recommendation.profitPerToken < 25 then -- < 25 gold per token
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
        function self.addon:ShowItemTooltip(itemData)
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

-- Show Merchant Cheng token arbitrage analysis
function IronPawProfitMainFrame:ShowMerchantChengArbitrage()
    local addon = self.addon
    if not addon.MerchantChengCalculator then
        addon:Print("Merchant Cheng calculator not available")
        return
    end
    
    local recommendations = addon.MerchantChengCalculator:CalculateRawMaterialCosts()
    self:UpdateArbitrageDisplay(recommendations)
end

-- Show raw material analysis
function IronPawProfitMainFrame:ShowRawMaterialAnalysis()
    local addon = self.addon
    if not addon.MerchantChengCalculator then
        addon:Print("Merchant Cheng calculator not available")
        return
    end
    
    local report = addon.MerchantChengCalculator:GenerateRawMaterialReport()
    self:UpdateMaterialDisplay(report.recommendations)
end

-- Update arbitrage display (Tab 2)
function IronPawProfitMainFrame:UpdateArbitrageDisplay(recommendations)
    local addon = self.addon
    if not addon.mainFrame or not addon.mainFrame.arbitrageContentFrame then return end
    
    -- Clear existing rows
    for _, row in ipairs(addon.mainFrame.arbitrageRows) do
        row:Hide()
    end
    addon.mainFrame.arbitrageRows = {}
    
    if not recommendations or #recommendations == 0 then
        local noResults = addon.mainFrame.arbitrageContentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        noResults:SetPoint("TOPLEFT", addon.mainFrame.arbitrageContentFrame, "TOPLEFT", 10, -10)
        noResults:SetText("No arbitrage opportunities found. Ensure Auctionator is available and auction house has been scanned.")
        noResults:SetTextColor(1, 0.5, 0.5)
        table.insert(addon.mainFrame.arbitrageRows, noResults)
        return
    end
    
    -- Filter for profitable opportunities only (restore original logic)
    local profitableRecs = {}
    for _, rec in ipairs(recommendations or {}) do
        if rec.netProfit and rec.netProfit > 5000 then -- Only show 50+ silver profit
            table.insert(profitableRecs, rec)
        end
    end

    -- Create header
    local header = self:CreateArbitrageRow(addon.mainFrame.arbitrageContentFrame, 0, 
        "|cffffd100Generate Token|r", "|cffffd100Buy Sack|r", "|cffffd100Profit|r", "|cffffd100Margin|r")
    header:SetPoint("TOPLEFT", addon.mainFrame.arbitrageContentFrame, "TOPLEFT", 0, -5)
    table.insert(addon.mainFrame.arbitrageRows, header)

    -- Create rows for each profitable recommendation
    for i, rec in ipairs(profitableRecs) do
        if i <= 15 then -- Limit display
            local tokenMethod = string.format("%s (%s)", rec.materialName or "Unknown", addon:FormatMoney(rec.totalCostPerToken or 0))
            local targetSack = string.format("%s (%s)", rec.targetSackName or "Unknown", addon:FormatMoney(rec.targetSackValue or 0))
            local profit = addon:FormatMoney(rec.netProfit or 0)
            local margin = string.format("%.1f%%", rec.profitMargin or 0)

            local row = self:CreateArbitrageRow(addon.mainFrame.arbitrageContentFrame, i, tokenMethod, targetSack, profit, margin)
            row:SetPoint("TOPLEFT", addon.mainFrame.arbitrageRows[i], "BOTTOMLEFT", 0, -2)
            table.insert(addon.mainFrame.arbitrageRows, row)
        end
    end
    
    -- Update content size
    local contentHeight = math.max(100, #addon.mainFrame.arbitrageRows * 25 + 20)
    addon.mainFrame.arbitrageContentFrame:SetHeight(contentHeight)
end

-- Update material display (Tab 3)
function IronPawProfitMainFrame:UpdateMaterialDisplay(recommendations)
    local addon = self.addon
    if not addon.mainFrame or not addon.mainFrame.materialContentFrame then return end
    
    -- Clear existing rows
    for _, row in ipairs(addon.mainFrame.materialRows) do
        row:Hide()
    end
    addon.mainFrame.materialRows = {}
    
    if not recommendations or #recommendations == 0 then
        local noResults = addon.mainFrame.materialContentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        noResults:SetPoint("TOPLEFT", addon.mainFrame.materialContentFrame, "TOPLEFT", 10, -10)
        noResults:SetText("No raw materials found. Ensure Auctionator is available and auction house has been scanned.")
        noResults:SetTextColor(1, 0.5, 0.5)
        table.insert(addon.mainFrame.materialRows, noResults)
        return
    end
    
    -- Create header
    local header = self:CreateMaterialRow(addon.mainFrame.materialContentFrame, 0,
        "|cffffd100Material|r", "|cffffd100Quantity|r", "|cffffd100Cost per Token|r", "|cffffd100Category|r")
    header:SetPoint("TOPLEFT", addon.mainFrame.materialContentFrame, "TOPLEFT", 0, -5)
    table.insert(addon.mainFrame.materialRows, header)
    
    -- Create rows for each material
    for i, rec in ipairs(recommendations) do
        if i <= 20 then -- Limit display
            local materialName = rec.materialName or "Unknown"
            local quantity = tostring(rec.materialsNeeded or 0)
            local costPerToken = addon:FormatMoney(rec.totalCostPerToken or 0)
            local category = rec.category or "Unknown"
            
            local row = self:CreateMaterialRow(addon.mainFrame.materialContentFrame, i, materialName, quantity, costPerToken, category)
            row:SetPoint("TOPLEFT", addon.mainFrame.materialRows[i], "BOTTOMLEFT", 0, -2)
            table.insert(addon.mainFrame.materialRows, row)
        end
    end
    
    -- Update content size
    local contentHeight = math.max(100, #addon.mainFrame.materialRows * 25 + 20)
    addon.mainFrame.materialContentFrame:SetHeight(contentHeight)
end

-- Create arbitrage row
function IronPawProfitMainFrame:CreateArbitrageRow(parent, index, tokenMethod, targetSack, profit, margin)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(640, 20)
    
    -- Token method
    row.tokenText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.tokenText:SetPoint("LEFT", row, "LEFT", 5, 0)
    row.tokenText:SetSize(180, 20)
    row.tokenText:SetJustifyH("LEFT")
    row.tokenText:SetText(tokenMethod)
    
    -- Target sack
    row.sackText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.sackText:SetPoint("LEFT", row.tokenText, "RIGHT", 10, 0)
    row.sackText:SetSize(180, 20)
    row.sackText:SetJustifyH("LEFT")
    row.sackText:SetText(targetSack)
    
    -- Profit
    row.profitText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.profitText:SetPoint("LEFT", row.sackText, "RIGHT", 10, 0)
    row.profitText:SetSize(100, 20)
    row.profitText:SetJustifyH("RIGHT")
    row.profitText:SetText(profit)
    
    -- Margin
    row.marginText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.marginText:SetPoint("LEFT", row.profitText, "RIGHT", 10, 0)
    row.marginText:SetSize(60, 20)
    row.marginText:SetJustifyH("RIGHT")
    row.marginText:SetText(margin)
    
    -- Color coding
    if index > 0 then
        local profitValue = tonumber(profit:match("(%d+)")) or 0
        if profitValue > 100 then -- 1+ gold
            row.profitText:SetTextColor(0, 1, 0) -- Green
        elseif profitValue > 50 then -- 50+ silver
            row.profitText:SetTextColor(1, 1, 0) -- Yellow
        else
            row.profitText:SetTextColor(1, 1, 1) -- White
        end
    end
    
    return row
end

-- Create material row
function IronPawProfitMainFrame:CreateMaterialRow(parent, index, materialName, quantity, costPerToken, category)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(640, 20)
    
    -- Material name
    row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.nameText:SetPoint("LEFT", row, "LEFT", 5, 0)
    row.nameText:SetSize(200, 20)
    row.nameText:SetJustifyH("LEFT")
    row.nameText:SetText(materialName)
    
    -- Quantity
    row.quantityText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.quantityText:SetPoint("LEFT", row.nameText, "RIGHT", 10, 0)
    row.quantityText:SetSize(80, 20)
    row.quantityText:SetJustifyH("CENTER")
    row.quantityText:SetText(quantity)
    
    -- Cost per token
    row.costText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.costText:SetPoint("LEFT", row.quantityText, "RIGHT", 10, 0)
    row.costText:SetSize(120, 20)
    row.costText:SetJustifyH("RIGHT")
    row.costText:SetText(costPerToken)
    
    -- Category
    row.categoryText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.categoryText:SetPoint("LEFT", row.costText, "RIGHT", 10, 0)
    row.categoryText:SetSize(100, 20)
    row.categoryText:SetJustifyH("CENTER")
    row.categoryText:SetText(category)
    
    -- Color coding by category
    if index > 0 then
        if category == "Seafood" then
            row.categoryText:SetTextColor(0.5, 0.8, 1) -- Light blue
        elseif category == "Meat" then
            row.categoryText:SetTextColor(1, 0.6, 0.6) -- Light red
        elseif category == "Vegetable" or category == "Fruit" then
            row.categoryText:SetTextColor(0.6, 1, 0.6) -- Light green
        end
    end
    
    return row
end

-- Filter materials by type
function IronPawProfitMainFrame:FilterMaterialsByType(materialType)
    -- This would filter the displayed materials - for now just refresh
    self:ShowRawMaterialAnalysis()
end

-- Attach functions to addon
function IronPawProfitMainFrame:AttachFunctions()
    local addon = self.addon
    
    -- Store reference to the module in addon
    addon.mainFrameModule = self
    
    -- Add Merchant Cheng GUI functions to the main addon
    function addon:ShowMerchantChengArbitrage()
        if not self.mainFrameModule then return end
        self.mainFrameModule:ShowMerchantChengArbitrage()
    end
    
    function addon:ShowRawMaterialAnalysis()
        if not self.mainFrameModule then return end
        self.mainFrameModule:ShowRawMaterialAnalysis()
    end
    
    function addon:FilterMaterialsByType(materialType)
        if not self.mainFrameModule then return end
        self.mainFrameModule:FilterMaterialsByType(materialType)
    end
end
