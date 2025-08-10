-- MainFrame.lua
-- Main user interface for the IronPaw Profit Calculator

local addonName, addon = ...

-- Create global MainFrame module
IronPawProfitMainFrame = {}

--------------------------------------------------------------------------------
-- Initialization and Core Frame Management
--------------------------------------------------------------------------------

-- Initialize the module and create the UI
function IronPawProfitMainFrame:Initialize(mainAddon)
    self.addon = mainAddon
    self:AttachFunctionsToMainAddon()
    self:CreateMainFrame()
end

-- Attach key functions to the main addon object to be called from elsewhere
function IronPawProfitMainFrame:AttachFunctionsToMainAddon()
    local addon = self.addon
    addon.mainFrameModule = self

    local functionsToAttach = {
        "ShowMainFrame",
        "UpdateTokenDisplay",
        "FilterByCategory",
        "UpdateProfitCalculations",
        "ShowItemTooltip",
        "ShowMerchantChengArbitrage",
        "ShowRawMaterialAnalysis",
        "FilterMaterialsByType",
        "ShowSeedAnalysis"
    }

    for _, funcName in ipairs(functionsToAttach) do
        addon[funcName] = function(...)
            return self[funcName](self, ...)
        end
    end
end

-- Show the main frame
function IronPawProfitMainFrame:ShowMainFrame()
    if not self.addon.mainFrame or not self.addon.mainFrame:IsShown() then
        self:CreateMainFrame()
    end
    
    self.addon.mainFrame:Show()
    self:ShowTab(1)
    self:UpdateTokenDisplay()
    self:UpdateProfitCalculations()
end

-- Create the main UI frame and all its components
function IronPawProfitMainFrame:CreateMainFrame()
    if self.addon.mainFrame then
        return self.addon.mainFrame
    end
    
    local addon = self.addon -- Local reference for closures
    
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
    
    local function CreateTab(parent, text, index)
        local tab = CreateFrame("Button", nil, parent, "GameMenuButtonTemplate")
        tab:SetSize(120, 25)
        tab:SetText(text)
        tab:SetPoint("TOPLEFT", parent, "TOPLEFT", 20 + (index - 1) * 125, -25)
        tab:SetScript("OnClick", function() self:ShowTab(index) end)
        return tab
    end
    
    frame.tabs[1] = CreateTab(frame, "Nam Ironpaw", 1)
    frame.tabs[2] = CreateTab(frame, "Token Arbitrage", 2)
    frame.tabs[3] = CreateTab(frame, "Raw Materials", 3)
    frame.tabs[4] = CreateTab(frame, "Seed Planting", 4)
    
    -- Tab content panels
    frame.tabPanels = {}
    local contentY = -55
    
    -------------------------------------------------
    -- TAB 1: Nam Ironpaw (Original functionality)
    -------------------------------------------------
    frame.tabPanels[1] = CreateFrame("Frame", nil, frame)
    frame.tabPanels[1]:SetAllPoints(frame)

    frame.tokenDisplay = CreateFrame("Frame", nil, frame.tabPanels[1])
    frame.tokenDisplay:SetSize(200, 30)
    frame.tokenDisplay:SetPoint("TOPLEFT", 20, contentY - 10)
    frame.tokenDisplay.icon = frame.tokenDisplay:CreateTexture(nil, "ARTWORK")
    frame.tokenDisplay.icon:SetSize(20, 20)
    frame.tokenDisplay.icon:SetPoint("LEFT")
    frame.tokenDisplay.icon:SetTexture("Interface\\Icons\\inv_misc_token_argentdawn3")
    frame.tokenDisplay.text = frame.tokenDisplay:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.tokenDisplay.text:SetPoint("LEFT", frame.tokenDisplay.icon, "RIGHT", 5, 0)
    frame.tokenDisplay.text:SetText("Tokens: 0")
    
    frame.scanButton = CreateFrame("Button", nil, frame.tabPanels[1], "GameMenuButtonTemplate")
    frame.scanButton:SetSize(100, 25)
    frame.scanButton:SetPoint("TOPRIGHT", -20, contentY - 10)
    frame.scanButton:SetText("Scan AH")
    frame.scanButton:SetScript("OnClick", function() addon:RefreshAuctionData() end)
    
    frame.categoryDropdown = CreateFrame("Frame", "IronPawCategoryDropdown", frame.tabPanels[1], "UIDropDownMenuTemplate")
    frame.categoryDropdown:SetPoint("TOPLEFT", frame.tokenDisplay, "BOTTOMLEFT", -15, -10)
    UIDropDownMenu_SetWidth(frame.categoryDropdown, 120)
    UIDropDownMenu_SetText(frame.categoryDropdown, "All Categories")
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
    
    frame.updateButton = CreateFrame("Button", nil, frame.tabPanels[1], "GameMenuButtonTemplate")
    frame.updateButton:SetSize(80, 25)
    frame.updateButton:SetPoint("LEFT", frame.goldLabel, "RIGHT", 20, 0)
    frame.updateButton:SetText("Update")
    frame.updateButton:SetScript("OnClick", function()
        local editbox = self.addon.mainFrame.thresholdEditBox
        local value = tonumber(editbox:GetText()) or 1
        self.addon.db.profile.minProfit = value
        self.addon:UpdateProfitCalculations()
    end)
    
    frame.summaryPanel = CreateFrame("Frame", nil, frame.tabPanels[1], "BackdropTemplate")
    frame.summaryPanel:SetSize(660, 60)
    frame.summaryPanel:SetPoint("TOPLEFT", frame.thresholdLabel, "BOTTOMLEFT", 0, -20)
    frame.summaryPanel:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 3, right = 3, top = 5, bottom = 3 } })
    frame.summaryPanel:SetBackdropColor(0, 0, 0, 0.25)
    frame.summaryPanel:SetBackdropBorderColor(0.4, 0.4, 0.4)
    
    frame.summaryText = frame.summaryPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.summaryText:SetPoint("TOPLEFT", 10, -5)
    frame.summaryText:SetPoint("BOTTOMRIGHT", -10, 5)
    frame.summaryText:SetJustifyH("LEFT")
    frame.summaryText:SetJustifyV("TOP")
    frame.summaryText:SetText("Click 'Update' to calculate profit recommendations...")
    
    frame.scrollFrame = CreateFrame("ScrollFrame", nil, frame.tabPanels[1], "UIPanelScrollFrameTemplate")
    frame.scrollFrame:SetPoint("TOPLEFT", frame.summaryPanel, "BOTTOMLEFT", 0, -10)
    frame.scrollFrame:SetPoint("BOTTOMRIGHT", frame.tabPanels[1], "BOTTOMRIGHT", -30, 20)
    
    frame.contentFrame = CreateFrame("Frame", nil, frame.scrollFrame)
    frame.contentFrame:SetSize(1, 1)
    frame.scrollFrame:SetScrollChild(frame.contentFrame)
    frame.resultRows = {}
    
    -------------------------------------------------
    -- TAB 2: Token Arbitrage (Merchant Cheng)
    -------------------------------------------------
    frame.tabPanels[2] = CreateFrame("Frame", nil, frame)
    frame.tabPanels[2]:SetAllPoints(frame)
    frame.tabPanels[2]:Hide()
    
    frame.arbitrageScanButton = CreateFrame("Button", nil, frame.tabPanels[2], "GameMenuButtonTemplate")
    frame.arbitrageScanButton:SetSize(120, 25)
    frame.arbitrageScanButton:SetPoint("TOPRIGHT", -20, contentY - 10)
    frame.arbitrageScanButton:SetText("Find Arbitrage")
    frame.arbitrageScanButton:SetScript("OnClick", function() addon:ShowMerchantChengArbitrage() end)
    
    frame.arbitrageInstructions = frame.tabPanels[2]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.arbitrageInstructions:SetPoint("TOPLEFT", 20, contentY - 40)
    frame.arbitrageInstructions:SetPoint("RIGHT", -20, 0)
    frame.arbitrageInstructions:SetJustifyH("LEFT")
    frame.arbitrageInstructions:SetText("|cffffd100Token Arbitrage Strategy:|r\n1. Find cheapest raw materials to generate tokens via Merchant Cheng\n2. Use those tokens to buy most valuable sacks from Nam Ironpaw\n3. Sell sacks on auction house for profit\n\nExample: Buy Golden Carp (60x) + Container → 1 Token → Buy White Turnip Sack → Sell for profit")
    
    frame.arbitrageScrollFrame = CreateFrame("ScrollFrame", nil, frame.tabPanels[2], "UIPanelScrollFrameTemplate")
    frame.arbitrageScrollFrame:SetPoint("TOPLEFT", frame.arbitrageInstructions, "BOTTOMLEFT", 0, -20)
    frame.arbitrageScrollFrame:SetPoint("BOTTOMRIGHT", frame.tabPanels[2], "BOTTOMRIGHT", -30, 20)
    
    frame.arbitrageContentFrame = CreateFrame("Frame", nil, frame.arbitrageScrollFrame)
    frame.arbitrageContentFrame:SetSize(1, 1)
    frame.arbitrageScrollFrame:SetScrollChild(frame.arbitrageContentFrame)
    frame.arbitrageRows = {}
    
    -------------------------------------------------
    -- TAB 3: Raw Materials (Merchant Cheng)
    -------------------------------------------------
    frame.tabPanels[3] = CreateFrame("Frame", nil, frame)
    frame.tabPanels[3]:SetAllPoints(frame)
    frame.tabPanels[3]:Hide()
    
    frame.materialScanButton = CreateFrame("Button", nil, frame.tabPanels[3], "GameMenuButtonTemplate")
    frame.materialScanButton:SetSize(140, 25)
    frame.materialScanButton:SetPoint("TOPRIGHT", -20, contentY - 10)
    frame.materialScanButton:SetText("Analyze Materials")
    frame.materialScanButton:SetScript("OnClick", function() addon:ShowRawMaterialAnalysis() end)
    
    frame.materialTypeDropdown = CreateFrame("Frame", "IronPawMaterialTypeDropdown", frame.tabPanels[3], "UIDropDownMenuTemplate")
    frame.materialTypeDropdown:SetPoint("TOPLEFT", 5, contentY - 10)
    UIDropDownMenu_SetWidth(frame.materialTypeDropdown, 120)
    UIDropDownMenu_SetText(frame.materialTypeDropdown, "All Materials")
    UIDropDownMenu_Initialize(frame.materialTypeDropdown, function(self, level)
        local materialTypes = {"All Materials", "Fish (20 qty)", "Fish (60 qty)", "Meat (20 qty)", "Vegetables (100 qty)"}
        for _, materialType in ipairs(materialTypes) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = materialType
            info.value = materialType
            info.func = function()
                UIDropDownMenu_SetSelectedValue(frame.materialTypeDropdown, materialType)
                addon:FilterMaterialsByType(materialType)
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    
    frame.materialInstructions = frame.tabPanels[3]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.materialInstructions:SetPoint("TOPLEFT", frame.materialTypeDropdown, "BOTTOMLEFT", 15, -20)
    frame.materialInstructions:SetPoint("RIGHT", -20, 0)
    frame.materialInstructions:SetJustifyH("LEFT")
    frame.materialInstructions:SetText("|cffffd100Raw Material Analysis:|r\nCompare costs to generate tokens using different raw materials:\n• Fish: Most need 20, Golden Carp needs 60\n• Meat: All need 20\n• Vegetables: All need 100 (most expensive per token)")
    
    frame.materialScrollFrame = CreateFrame("ScrollFrame", nil, frame.tabPanels[3], "UIPanelScrollFrameTemplate")
    frame.materialScrollFrame:SetPoint("TOPLEFT", frame.materialInstructions, "BOTTOMLEFT", 0, -20)
    frame.materialScrollFrame:SetPoint("BOTTOMRIGHT", frame.tabPanels[3], "BOTTOMRIGHT", -30, 20)
    
    frame.materialContentFrame = CreateFrame("Frame", nil, frame.materialScrollFrame)
    frame.materialContentFrame:SetSize(1, 1)
    frame.materialScrollFrame:SetScrollChild(frame.materialContentFrame)
    frame.materialRows = {}
    
    -------------------------------------------------
    -- TAB 4: Seed Planting (Merchant Greenfield)
    -------------------------------------------------
    frame.tabPanels[4] = CreateFrame("Frame", nil, frame)
    frame.tabPanels[4]:SetAllPoints(frame)
    frame.tabPanels[4]:Hide()

    -- Seed Quantity Input
    local seedQtyLabel = frame.tabPanels[4]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    seedQtyLabel:SetPoint("TOPLEFT", 20, contentY - 15)
    seedQtyLabel:SetText("Seeds to Plant:")

    frame.seedQuantityEditBox = CreateFrame("EditBox", nil, frame.tabPanels[4], "InputBoxTemplate")
    frame.seedQuantityEditBox:SetSize(40, 20)
    frame.seedQuantityEditBox:SetPoint("LEFT", seedQtyLabel, "RIGHT", 5, 0)
    frame.seedQuantityEditBox:SetText("16")
    frame.seedQuantityEditBox:SetAutoFocus(false)
    frame.seedQuantityEditBox:SetScript("OnEnterPressed", function(editbox)
        addon:ShowSeedAnalysis()
        editbox:ClearFocus()
    end)

    frame.seedScanButton = CreateFrame("Button", nil, frame.tabPanels[4], "GameMenuButtonTemplate")
    frame.seedScanButton:SetSize(140, 25)
    frame.seedScanButton:SetPoint("TOPRIGHT", -20, contentY - 10)
    frame.seedScanButton:SetText("Analyze Seeds")
    frame.seedScanButton:SetScript("OnClick", function() addon:ShowSeedAnalysis() end)

    frame.seedInstructions = frame.tabPanels[4]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.seedInstructions:SetPoint("TOPLEFT", 20, contentY - 40)
    frame.seedInstructions:SetPoint("RIGHT", -20, 0)
    frame.seedInstructions:SetJustifyH("LEFT")
    frame.seedInstructions:SetText("|cffffd100Find the most profitable seeds to plant from Merchant Greenfield.|r\nSeed Planting Analysis:")

    frame.seedSummaryPanel = CreateFrame("Frame", nil, frame.tabPanels[4], "BackdropTemplate")
    frame.seedSummaryPanel:SetSize(660, 40)
    frame.seedSummaryPanel:SetPoint("TOPLEFT", frame.seedInstructions, "BOTTOMLEFT", 0, -10)
    frame.seedSummaryPanel:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 3, right = 3, top = 5, bottom = 3 } })
    frame.seedSummaryPanel:SetBackdropColor(0, 0, 0, 0.25)
    frame.seedSummaryPanel:SetBackdropBorderColor(0.4, 0.4, 0.4)

    frame.seedSummaryText = frame.seedSummaryPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.seedSummaryText:SetPoint("TOPLEFT", 10, -5)
    frame.seedSummaryText:SetPoint("BOTTOMRIGHT", -10, 5)
    frame.seedSummaryText:SetJustifyH("LEFT")
    frame.seedSummaryText:SetJustifyV("TOP")
    frame.seedSummaryText:SetText("Click 'Analyze Seeds' to find the most profitable crop.")

    frame.seedScrollFrame = CreateFrame("ScrollFrame", nil, frame.tabPanels[4], "UIPanelScrollFrameTemplate")
    frame.seedScrollFrame:SetPoint("TOPLEFT", frame.seedSummaryPanel, "BOTTOMLEFT", 0, -10)
    frame.seedScrollFrame:SetPoint("BOTTOMRIGHT", frame.tabPanels[4], "BOTTOMRIGHT", -30, 20)

    frame.seedContentFrame = CreateFrame("Frame", nil, frame.seedScrollFrame)
    frame.seedContentFrame:SetSize(1, 1)
    frame.seedScrollFrame:SetScrollChild(frame.seedContentFrame)
    frame.seedRows = {}
    
    self.addon.mainFrame = frame
end

-- Switch between tabs
function IronPawProfitMainFrame:ShowTab(tabIndex)
    local frame = self.addon.mainFrame
    if not frame or not frame.tabPanels then return end
    
    for i, panel in ipairs(frame.tabPanels) do
        panel:Hide()
    end
    
    for i, tab in ipairs(frame.tabs) do
        if i == tabIndex then
            tab:SetNormalFontObject("GameFontHighlightLarge")
            tab:LockHighlight()
        else
            tab:SetNormalFontObject("GameFontNormal")
            tab:UnlockHighlight()
        end
    end
    
    if frame.tabPanels[tabIndex] then
        frame.tabPanels[tabIndex]:Show()
        frame.activeTab = tabIndex
    end
end

--------------------------------------------------------------------------------
-- Tab 1: Nam Ironpaw Functions
--------------------------------------------------------------------------------

function IronPawProfitMainFrame:UpdateTokenDisplay(tokens)
    if not self.addon.mainFrame then return end
    tokens = tokens or self.addon:GetIronpawTokenCount()
    self.addon.mainFrame.tokenDisplay.text:SetText(string.format("Tokens: %d", tokens))
end

function IronPawProfitMainFrame:FilterByCategory(category)
    self.addon.selectedCategory = category
    self:UpdateProfitCalculations()
end

function IronPawProfitMainFrame:UpdateProfitCalculations()
    if not self.addon.mainFrame or not self.addon.mainFrame:IsShown() then return end
    if not self.addon.ProfitCalculator or not self.addon.Database then
        self.addon.mainFrame.summaryText:SetText("Waiting for data to load...")
        return
    end
    
    local tokens = self.addon:GetIronpawTokenCount()
    local category = self.addon.selectedCategory or "All"
    local report = self.addon.ProfitCalculator:GenerateInvestmentReport(tokens)
    
    self:UpdateSummaryDisplay(report)
    self:UpdateResultsDisplay(report.recommendations, category)
end

function IronPawProfitMainFrame:UpdateSummaryDisplay(report)
    if not self.addon.mainFrame then return end
    if not report or not report.summary then
        self.addon.mainFrame.summaryText:SetText("No data available. Click 'Scan AH' to refresh auction data.")
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
        self.addon:FormatMoney(summary.totalProfitPotential or 0),
        self.addon:FormatMoney(summary.averageProfitPerToken or 0),
        summary.topProfitItem or "None"
    )
    
    if #warnings > 0 then
        text = text .. "\n|cffff8800Warnings:|r " .. table.concat(warnings, ", ")
    end
    
    self.addon.mainFrame.summaryText:SetText(text)
end

function IronPawProfitMainFrame:UpdateResultsDisplay(recommendations, category)
    if not self.addon.mainFrame then return end
    
    for _, row in pairs(self.addon.mainFrame.resultRows) do
        row:Hide()
    end
    
    if not recommendations then return end
    
    local filteredRecs = {}
    for _, rec in ipairs(recommendations) do
        if rec and rec.itemData and (category == "All" or rec.itemData.category == category) then
            table.insert(filteredRecs, rec)
        end
    end
    
    local yOffset = -10
    for i, rec in ipairs(filteredRecs) do
        local row = self:GetOrCreateResultRow(i)
        self:UpdateResultRow(row, rec, i)
        row:SetPoint("TOPLEFT", self.addon.mainFrame.contentFrame, "TOPLEFT", 10, yOffset)
        row:Show()
        yOffset = yOffset - 35
    end
    
    self.addon.mainFrame.contentFrame:SetHeight(math.abs(yOffset) + 20)
end

function IronPawProfitMainFrame:GetOrCreateResultRow(index)
    if self.addon.mainFrame.resultRows[index] then
        return self.addon.mainFrame.resultRows[index]
    end
    
    local row = CreateFrame("Frame", nil, self.addon.mainFrame.contentFrame)
    row:SetSize(520, 30)
    
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(24, 24)
    row.icon:SetPoint("LEFT", 5, 0)
    
    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.name:SetPoint("LEFT", row.icon, "RIGHT", 5, 0)
    row.name:SetSize(150, 20)
    row.name:SetJustifyH("LEFT")
    
    row.tokens = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.tokens:SetPoint("LEFT", row.name, "RIGHT", 5, 0)
    row.tokens:SetSize(50, 20)
    row.tokens:SetJustifyH("CENTER")
    
    row.profit = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.profit:SetPoint("LEFT", row.tokens, "RIGHT", 5, 0)
    row.profit:SetSize(80, 20)
    row.profit:SetJustifyH("RIGHT")
    
    row.quantity = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.quantity:SetPoint("LEFT", row.profit, "RIGHT", 5, 0)
    row.quantity:SetSize(50, 20)
    row.quantity:SetJustifyH("CENTER")
    
    row.totalProfit = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.totalProfit:SetPoint("LEFT", row.quantity, "RIGHT", 5, 0)
    row.totalProfit:SetSize(80, 20)
    row.totalProfit:SetJustifyH("RIGHT")
    
    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints()
    row.bg:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    row.bg:SetAlpha(0)
    
    row:SetScript("OnEnter", function(self)
        self.bg:SetAlpha(0.3)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if IronPawProfit and IronPawProfit.ShowItemTooltip then
            IronPawProfit.ShowItemTooltip(self.itemData)
        end
    end)
    
    row:SetScript("OnLeave", function(self)
        self.bg:SetAlpha(0)
        GameTooltip:Hide()
    end)
    
    self.addon.mainFrame.resultRows[index] = row
    return row
end

function IronPawProfitMainFrame:UpdateResultRow(row, recommendation, index)
    row.itemData = recommendation.itemData
    row.recommendation = recommendation
    
    local texture = GetItemIcon(recommendation.itemData.itemID)
    if texture then
        row.icon:SetTexture(texture)
    end
    
    local color = "|cffffffff" -- White
    if recommendation.profitPerToken > 100000 then color = "|cff00ff00" -- Green
    elseif recommendation.profitPerToken > 50000 then color = "|cffffff00" -- Yellow
    elseif recommendation.profitPerToken < 25000 then color = "|cffff8000" -- Orange
    end
    
    row.name:SetText(color .. (recommendation.itemData.name or "Unknown"))
    row.tokens:SetText(string.format("%d", recommendation.itemData.tokenCost))
    row.profit:SetText(color .. self.addon:FormatMoneyPrecise(recommendation.profitPerToken))
    row.quantity:SetText(string.format("%d", recommendation.recommendedStacks or 0))
    row.totalProfit:SetText(color .. self.addon:FormatMoney(recommendation.totalProfit or 0))
end

function IronPawProfitMainFrame:ShowItemTooltip(itemData)
    if not itemData then return end
    
    GameTooltip:SetHyperlink("item:" .. itemData.itemID)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("IronPaw Profit Info:", 1, 1, 0)
    GameTooltip:AddLine(string.format("Token Cost: %d", itemData.tokenCost), 1, 1, 1)
    GameTooltip:AddLine(string.format("Market Price: %s", self.addon:FormatMoney(itemData.marketPrice)), 1, 1, 1)
    
    if itemData.contains and itemData.contains > 1 then
        local pricePerItem = math.floor(itemData.marketPrice / itemData.contains)
        GameTooltip:AddLine(string.format("Price per Item: %s", self.addon:FormatMoney(pricePerItem)), 0.8, 0.8, 1)
        GameTooltip:AddLine(string.format("Contains: %d items", itemData.contains), 0.7, 0.7, 0.7)
    end
    
    GameTooltip:AddLine(string.format("Profit per Token: %s", self.addon:FormatMoney(itemData.profitPerToken)), 0, 1, 0)
    GameTooltip:AddLine(string.format("Stack Size: %d", itemData.stackSize), 1, 1, 1)
    
    if itemData.lastScanned and itemData.lastScanned > 0 then
        local timeAgo = time() - itemData.lastScanned
        local hours = math.floor(timeAgo / 3600)
        GameTooltip:AddLine(string.format("Data Age: %d hours", hours), 0.7, 0.7, 0.7)
    end
    
    GameTooltip:Show()
end

--------------------------------------------------------------------------------
-- Tab 2 & 3: Merchant Cheng Functions
--------------------------------------------------------------------------------

function IronPawProfitMainFrame:ShowMerchantChengArbitrage()
    local addon = self.addon
    if not addon.MerchantChengCalculator then
        addon:Print("Merchant Cheng calculator not available")
        return
    end
    
    local recommendations = addon.MerchantChengCalculator:CalculateRawMaterialCosts()
    self:UpdateArbitrageDisplay(recommendations)
end

function IronPawProfitMainFrame:ShowRawMaterialAnalysis()
    local addon = self.addon
    if not addon.MerchantChengCalculator then
        addon:Print("Merchant Cheng calculator not available")
        return
    end
    
    local report = addon.MerchantChengCalculator:GenerateRawMaterialReport()
    self:UpdateMaterialDisplay(report.recommendations)
end

function IronPawProfitMainFrame:FilterMaterialsByType(materialType)
    self:ShowRawMaterialAnalysis()
end

function IronPawProfitMainFrame:UpdateArbitrageDisplay(recommendations)
    local addon = self.addon
    if not addon.mainFrame or not addon.mainFrame.arbitrageContentFrame then return end
    
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
    
    local profitableRecs = {}
    for _, rec in ipairs(recommendations or {}) do
        if rec.netProfit and rec.netProfit > 5000 then -- Only show 50+ silver profit
            table.insert(profitableRecs, rec)
        end
    end

    local header = self:CreateArbitrageRow(addon.mainFrame.arbitrageContentFrame, 0, 
        "|cffffd100Generate Token|r", "|cffffd100Buy Sack|r", "|cffffd100Profit|r", "|cffffd100Margin|r")
    header:SetPoint("TOPLEFT", addon.mainFrame.arbitrageContentFrame, "TOPLEFT", 0, -5)
    table.insert(addon.mainFrame.arbitrageRows, header)

    for i, rec in ipairs(profitableRecs) do
        if i <= 15 then -- Limit display
            local tokenMethod = string.format("%s (%s)", rec.materialName or "Unknown", addon:FormatMoney(rec.totalCostPerToken or 0))
            local targetSack = string.format("%s (%s)", rec.targetSackName or "Unknown", addon:FormatMoney(rec.targetSackValue or 0))
            local profit = addon:FormatMoney(rec.netProfit or 0)
            local margin = string.format("%.1f%%", rec.profitMargin or 0)

            local row = self:CreateArbitrageRow(addon.mainFrame.arbitrageContentFrame, i, tokenMethod, targetSack, profit, margin)
            row:SetPoint("TOPLEFT", addon.mainFrame.arbitrageRows[#addon.mainFrame.arbitrageRows], "BOTTOMLEFT", 0, -2)
            table.insert(addon.mainFrame.arbitrageRows, row)
        end
    end
    
    local contentHeight = math.max(100, #addon.mainFrame.arbitrageRows * 25 + 20)
    addon.mainFrame.arbitrageContentFrame:SetHeight(contentHeight)
end

function IronPawProfitMainFrame:CreateArbitrageRow(parent, index, tokenMethod, targetSack, profit, margin)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(640, 20)
    
    row.tokenText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.tokenText:SetPoint("LEFT", row, "LEFT", 5, 0)
    row.tokenText:SetSize(180, 20)
    row.tokenText:SetJustifyH("LEFT")
    row.tokenText:SetText(tokenMethod)
    
    row.sackText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.sackText:SetPoint("LEFT", row.tokenText, "RIGHT", 10, 0)
    row.sackText:SetSize(180, 20)
    row.sackText:SetJustifyH("LEFT")
    row.sackText:SetText(targetSack)
    
    row.profitText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.profitText:SetPoint("LEFT", row.sackText, "RIGHT", 10, 0)
    row.profitText:SetSize(100, 20)
    row.profitText:SetJustifyH("RIGHT")
    row.profitText:SetText(profit)
    
    row.marginText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.marginText:SetPoint("LEFT", row.profitText, "RIGHT", 10, 0)
    row.marginText:SetSize(60, 20)
    row.marginText:SetJustifyH("RIGHT")
    row.marginText:SetText(margin)
    
    if index > 0 then
        local profitValue = tonumber(profit:match("(%d+)")) or 0
        if profitValue > 10000 then -- 1+ gold
            row.profitText:SetTextColor(0, 1, 0) -- Green
        elseif profitValue > 5000 then -- 50+ silver
            row.profitText:SetTextColor(1, 1, 0) -- Yellow
        else
            row.profitText:SetTextColor(1, 1, 1) -- White
        end
    end
    
    return row
end

function IronPawProfitMainFrame:UpdateMaterialDisplay(recommendations)
    local addon = self.addon
    if not addon.mainFrame or not addon.mainFrame.materialContentFrame then return end
    
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
    
    local header = self:CreateMaterialRow(addon.mainFrame.materialContentFrame, 0,
        "|cffffd100Material|r", "|cffffd100Quantity|r", "|cffffd100Cost per Token|r", "|cffffd100Category|r")
    header:SetPoint("TOPLEFT", addon.mainFrame.materialContentFrame, "TOPLEFT", 0, -5)
    table.insert(addon.mainFrame.materialRows, header)
    
    for i, rec in ipairs(recommendations) do
        if i <= 20 then -- Limit display
            local materialName = rec.materialName or "Unknown"
            local quantity = tostring(rec.materialsNeeded or 0)
            local costPerToken = addon:FormatMoney(rec.totalCostPerToken or 0)
            local category = rec.category or "Unknown"
            
            local row = self:CreateMaterialRow(addon.mainFrame.materialContentFrame, i, materialName, quantity, costPerToken, category)
            row:SetPoint("TOPLEFT", addon.mainFrame.materialRows[#addon.mainFrame.materialRows], "BOTTOMLEFT", 0, -2)
            table.insert(addon.mainFrame.materialRows, row)
        end
    end
    
    local contentHeight = math.max(100, #addon.mainFrame.materialRows * 25 + 20)
    addon.mainFrame.materialContentFrame:SetHeight(contentHeight)
end

function IronPawProfitMainFrame:CreateMaterialRow(parent, index, materialName, quantity, costPerToken, category)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(640, 20)
    
    row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.nameText:SetPoint("LEFT", row, "LEFT", 5, 0)
    row.nameText:SetSize(200, 20)
    row.nameText:SetJustifyH("LEFT")
    row.nameText:SetText(materialName)
    
    row.quantityText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.quantityText:SetPoint("LEFT", row.nameText, "RIGHT", 10, 0)
    row.quantityText:SetSize(80, 20)
    row.quantityText:SetJustifyH("CENTER")
    row.quantityText:SetText(quantity)
    
    row.costText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.costText:SetPoint("LEFT", row.quantityText, "RIGHT", 10, 0)
    row.costText:SetSize(120, 20)
    row.costText:SetJustifyH("RIGHT")
    row.costText:SetText(costPerToken)
    
    row.categoryText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.categoryText:SetPoint("LEFT", row.costText, "RIGHT", 10, 0)
    row.categoryText:SetSize(100, 20)
    row.categoryText:SetJustifyH("CENTER")
    row.categoryText:SetText(category)
    
    if index > 0 then
        if category == "Fish (20 qty)" or category == "Fish (60 qty)" then
            row.categoryText:SetTextColor(0.5, 0.8, 1) -- Light blue
        elseif category == "Meat (20 qty)" then
            row.categoryText:SetTextColor(1, 0.6, 0.6) -- Light red
        elseif category and (category == "Vegetables (100 qty)") then
            row.categoryText:SetTextColor(0.6, 1, 0.6) -- Light green
        end
    end
    
    return row
end

--------------------------------------------------------------------------------
-- Tab 4: Seed Planting Functions
--------------------------------------------------------------------------------

function IronPawProfitMainFrame:ShowSeedAnalysis()
    if not self.addon.mainFrame or not self.addon.mainFrame:IsShown() then return end
    if not self.addon.GreenfieldCalculator then
        self.addon.mainFrame.seedSummaryText:SetText("Seed calculator not available.")
        return
    end

    local recommendations = self.addon.GreenfieldCalculator:CalculateSeedProfits()
    self:UpdateSeedSummaryDisplay(recommendations)
    self:UpdateSeedResultsDisplay(recommendations)
end

function IronPawProfitMainFrame:UpdateSeedSummaryDisplay(recommendations)
    if not self.addon.mainFrame then return end
    local summaryText = self.addon.mainFrame.seedSummaryText
    
    if not recommendations or #recommendations == 0 then
        summaryText:SetText("No profitable seeds found. Scan the AH for current prices.")
        return
    end

    local bestSeed = recommendations[1]
    if not bestSeed or not bestSeed.profit then
        summaryText:SetText("Could not determine the best seed. Data might be missing.")
        return
    end
    
    local totalProfit = bestSeed.profit * (tonumber(self.addon.mainFrame.seedQuantityEditBox:GetText()) or 16)
    local _, bestSeedLink = GetItemInfo(bestSeed.seedID)

    local text = string.format(
        "Planting %d of the most profitable seed (%s) could yield a total profit of: %s",
        (tonumber(self.addon.mainFrame.seedQuantityEditBox:GetText()) or 16),
        bestSeedLink or bestSeed.seedName,
        self.addon:FormatMoney(totalProfit)
    )
    summaryText:SetText(text)
end

function IronPawProfitMainFrame:UpdateSeedResultsDisplay(recommendations)
    if not self.addon.mainFrame then return end
    
    for _, row in pairs(self.addon.mainFrame.seedRows) do
        row:Hide()
    end
    
    if not recommendations then return end
    
    local yOffset = -10
    for i, rec in ipairs(recommendations) do
        local row = self:GetOrCreateSeedRow(i)
        self:UpdateSeedRow(row, rec, i)
        row:SetPoint("TOPLEFT", self.addon.mainFrame.seedContentFrame, "TOPLEFT", 10, yOffset)
        row:Show()
        yOffset = yOffset - 35
    end
    
    self.addon.mainFrame.seedContentFrame:SetHeight(math.abs(yOffset) + 20)
end

function IronPawProfitMainFrame:GetOrCreateSeedRow(index)
    if self.addon.mainFrame.seedRows[index] then
        return self.addon.mainFrame.seedRows[index]
    end
    
    local row = CreateFrame("Frame", nil, self.addon.mainFrame.seedContentFrame)
    row:SetSize(620, 30)

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(24, 24)
    row.icon:SetPoint("LEFT", 5, 0)

    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.name:SetPoint("LEFT", row.icon, "RIGHT", 5, 0)
    row.name:SetSize(200, 20)
    row.name:SetJustifyH("LEFT")

    row.profit = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.profit:SetPoint("LEFT", row.name, "RIGHT", 10, 0)
    row.profit:SetSize(150, 20)
    row.profit:SetJustifyH("LEFT")
    
    row.totalProfit = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.totalProfit:SetPoint("LEFT", row.profit, "RIGHT", 10, 0)
    row.totalProfit:SetSize(150, 20)
    row.totalProfit:SetJustifyH("LEFT")

    self.addon.mainFrame.seedRows[index] = row
    return row
end

function IronPawProfitMainFrame:UpdateSeedRow(row, rec, index)
    local addon = self.addon -- For use in closures
    local itemID = rec.seedID
    local _, itemLink, _, _, _, _, _, _, _, itemTexture = GetItemInfo(itemID)
    
    row.icon:SetTexture(itemTexture)
    row.name:SetText(itemLink or rec.seedName)
    row.profit:SetText("Profit: " .. addon:FormatMoney(rec.profit))
    local numSeeds = tonumber(self.addon.mainFrame.seedQuantityEditBox:GetText()) or 16
    row.totalProfit:SetText("Total Profit (x" .. numSeeds .. "): " .. addon:FormatMoney(rec.profit * numSeeds))

    row:SetScript("OnEnter", function(frame)
        GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
        GameTooltip:SetText(rec.seedName, 1, 1, 1)
        GameTooltip:AddLine("Cost: " .. addon:FormatMoney(rec.cost), 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Expected Market Value: " .. addon:FormatMoney(rec.marketValue), 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Expected Profit: " .. addon:FormatMoney(rec.profit), 1, 1, 0)
        GameTooltip:AddLine(" ")

        GameTooltip:AddLine("|cffffd100Expected Yield Breakdown:|r")
        if rec.tooltipData then
            for _, data in ipairs(rec.tooltipData) do
                local valueText = addon:FormatMoney(data.calculatedValue)
                local priceText = addon:FormatMoney(data.marketPrice)
                local line = string.format(
                    "%s (%d x %.0f%%) - Price: %s | Value: %s",
                    data.name,
                    data.quantity,
                    data.chance * 100,
                    priceText,
                    valueText
                )
                GameTooltip:AddLine(line)
            end
        end
        
        GameTooltip:Show()
    end)
    
    row:SetScript("OnLeave", function(frame)
        GameTooltip:Hide()
    end)
end