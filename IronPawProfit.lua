--[[
    IronPaw Profit Calculator - Main Addon File
    
    Description:
    This addon calculates profit potential for Nam Ironpaw vendor purchases in WoW MoP Classic.
    It analyzes auction house prices for cooking materials and recommends which sacks to buy
    for maximum profit when reselling the contents.
    
    Features:
    - Real-time auction house price monitoring via Auctionator integration
    - Profit calculations per token spent
    - Recommendation system for optimal purchases
    - Category filtering (Meat, Seafood, Vegetable, Fruit, Reagent)
    - Detailed tooltips with price breakdowns
    - Debug commands for troubleshooting
    
    Dependencies:
    - Auctionator addon (for accurate market prices)
    
    Slash Commands:
    /ironpaw or /ipp - Main commands
    - show: Open the main UI
    - scan: Refresh auction data
    - debug: Various debug options
    - help: Show command list
]]--

-- IronPaw Profit Calculator
-- Main addon initialization and event handling

local addonName, addon = ...

-- Create main addon object
IronPawProfit = {}
IronPawProfit.version = "1.0.3"

-- Initialization state tracking
-- Ensures modules are loaded in the correct order
IronPawProfit.initState = {
    config = false,              -- Configuration system loaded
    database = false,            -- Item database loaded
    auctionatorInterface = false, -- Auctionator API integration loaded
    profitCalculator = false,    -- Profit calculation engine loaded
    merchantChengCalculator = false, -- Merchant Cheng calculator loaded
    greenfieldCalculator = false, -- Greenfield calculator loaded
    ui = false                   -- User interface components loaded
}

-- Create frame for event handling
-- Registers for key WoW events to respond to game state changes
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")  -- When addons finish loading
eventFrame:RegisterEvent("PLAYER_LOGIN")  -- When player finishes logging in
eventFrame:RegisterEvent("BAG_UPDATE")    -- When bag contents change (for token counting)

-- Local references for performance
local IronPawProfit = IronPawProfit

-- Default saved variables structure
-- These values are used when the addon is first installed or after a reset
local defaults = {
    profile = {
        minProfit = 1,           -- Minimum profit in gold to show suggestions
        maxInvestment = 1000,    -- Maximum gold willing to invest
        showOnlyProfitable = true, -- Filter out unprofitable items
        autoScan = false,        -- Automatically scan on login
        windowPosition = {       -- UI window position
            point = "CENTER",
            x = 0,
            y = 0
        }
    }
}

-- Event handler function
-- Processes WoW events and routes them to appropriate handler functions
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddonName = ...
        if loadedAddonName == addonName then
            -- Our addon finished loading
            IronPawProfit:OnInitialize()
        elseif loadedAddonName == "Auctionator" then
            -- Auctionator finished loading - we can now use its API
            IronPawProfit:OnAddonLoaded(event, loadedAddonName)
        end
    elseif event == "PLAYER_LOGIN" then
        -- Player finished logging in - safe to access all game APIs
        IronPawProfit:OnPlayerLogin()
    elseif event == "BAG_UPDATE" then
        -- Bag contents changed - update token count
        IronPawProfit:OnBagUpdate()
    end
end)

--[[
    Addon initialization function
    Called when our addon finishes loading
    Responsible for:
    - Setting up saved variables
    - Registering slash commands
    - Initializing all modules in correct order
]]--
function IronPawProfit:OnInitialize()
    -- Initialize saved variables
    if not IronPawProfitDB then
        IronPawProfitDB = {}
    end
    
    -- Set defaults
    for key, value in pairs(defaults.profile) do
        if IronPawProfitDB[key] == nil then
            IronPawProfitDB[key] = value
        end
    end
    
    self.db = { profile = IronPawProfitDB }
    
    -- Register slash commands
    SLASH_IRONPAW1 = "/ironpaw"
    SLASH_IRONPAW2 = "/ipp"
    SlashCmdList["IRONPAW"] = function(msg) IronPawProfit:SlashCommand(msg) end
    
    -- Initialize modules in proper order
    self:Print("IronPaw Profit Calculator loading...")
    
    -- Step 1: Initialize configuration
    self:InitializeConfig()
    self.initState.config = true
    
    -- Step 2: Initialize database
    self:InitializeDatabase()
    self.initState.database = true

    -- Initialize token storage if database provided helpers (functions are attached to addon)
    if self.InitTokenStorage then
        self:InitTokenStorage()
    end
    
    -- Step 3: Initialize Auctionator interface
    self:InitializeAuctionatorInterface()
    self.initState.auctionatorInterface = true
    
    -- Step 4: Initialize profit calculator
    self:InitializeProfitCalculator()
    self.initState.profitCalculator = true
    
    -- Step 5: Initialize merchant cheng calculator
    self:InitializeMerchantChengCalculator()
    self.initState.merchantChengCalculator = true

    -- Step 6: Initialize Greenfield calculator
    self:InitializeGreenfieldCalculator()
    self.initState.greenfieldCalculator = true
    
    -- Step 7: Initialize UI components
    self:InitializeUI()
    self.initState.ui = true
    
    self:Print("IronPaw Profit Calculator loaded! Use /ironpaw or /show to open.")
end

--[[
    Handle when other addons finish loading
    Specifically watches for Auctionator to become available
]]--
function IronPawProfit:OnAddonLoaded(event, loadedAddonName)
    if loadedAddonName == "Auctionator" then
        self:Print("Auctionator detected! Profit calculations will be more accurate.")
        self:RefreshAuctionData()
    end
end

--[[
    Handle player login event
    Performs checks and initialization that require the player to be fully logged in
]]--
function IronPawProfit:OnPlayerLogin()
    -- Check for required addons
    if not IsAddOnLoaded("Auctionator") then
        self:Print("|cffff0000Warning:|r Auctionator not detected. Install Auctionator for accurate market prices.")
    end
    
    -- Initialize token storage for this session and update token count
    if self.InitTokenStorage then
        self:InitTokenStorage()
    end
    self:UpdateIronpawTokens()
end

--[[
    Handle bag update events
    Updates token count when bags change (tokens are currency items)
]]--
function IronPawProfit:OnBagUpdate()
    -- Update token count when bags change
    -- Reconcile token changes and persist per-character balances
    local current = self:GetIronpawTokenCount()
    if self.ReconcileTokenChange then
        -- Protect against errors in reconciliation
        local ok, a, b, c = pcall(function() return self:ReconcileTokenChange(current) end)
        if not ok then
            self:Print("[TokenStorage] Error reconciling token change: " .. tostring(a))
        else
            -- a,b,c correspond to oldTokens,newTokens,delta (may be nil for oldTokens)
            -- Update UI after reconciliation
            self:UpdateIronpawTokens()
        end
    else
        self:UpdateIronpawTokens()
    end
end

--[[
    Slash command parser and router
    Handles all /ironpaw and /ipp commands
    
    Available commands:
    - show: Open main UI window
    - scan: Refresh auction house data
    - tokens: Display current token count
    - config: Show configuration information
    - debug [queries|refresh]: Debug commands for troubleshooting
    - reset: Reset configuration to defaults
    - help: Show command help
]]--
function IronPawProfit:SlashCommand(input)
    local args = {}
    for word in input:gmatch("%S+") do
        table.insert(args, word:lower())
    end
    
    if #args == 0 or args[1] == "show" then
        self:ShowMainFrame()
    elseif args[1] == "scan" then
        self:RefreshAuctionData()
        self:Print("Scanning auction data...")
    elseif args[1] == "tokens" then
        local tokens = self:GetIronpawTokenCount()
        self:Print(string.format("Current Ironpaw Tokens (this character): %d", tokens))
        -- Show stored totals if available
        if IronPawProfitDB and IronPawProfitDB.tokenBalances then
            local total = 0
            for key, entry in pairs(IronPawProfitDB.tokenBalances) do
                if entry and type(entry.tokens) == "number" then
                    total = total + entry.tokens
                end
            end
            self:Print(string.format("Stored tokens across characters: %d", total))
            -- Optional: show per-character breakdown
            for key, entry in pairs(IronPawProfitDB.tokenBalances) do
                if entry and type(entry.tokens) == "number" then
                    local age = entry.lastUpdated and (time() - entry.lastUpdated) or nil
                    local ageText = age and string.format(" (last update: %dh ago)", math.floor(age / 3600)) or ""
                    self:Print(string.format("  %s: %d%s", key, entry.tokens, ageText))
                end
            end
        else
            self:Print("No stored token balances found. They will be recorded as you change token counts.")
        end
    elseif args[1] == "config" then
        -- Show current configuration
        self:ShowConfig()
    elseif args[1] == "sales" then
        -- Show auction sale report
        self:ShowSalesReport()
    elseif args[1] == "market" then
        -- Show market analysis
        self:ShowMarketAnalysis()
    elseif args[1] == "cheng" then
        -- Show Merchant Cheng raw material analysis
        self:ShowMerchantChengAnalysis()
    elseif args[1] == "materials" then
        -- Show raw material token generation opportunities
        self:ShowRawMaterialReport()
    elseif args[1] == "containers" then
        -- Set or show container cost from Merchant Cheng
        if #args >= 2 and tonumber(args[2]) then
            local costInGold = tonumber(args[2])
            local costInCopper = costInGold * 10000
            if self.MerchantChengCalculator then
                self.MerchantChengCalculator:UpdateContainerCost(costInCopper)
                self:Print(string.format("Container cost set to %s", self:FormatMoney(costInCopper)))
            else
                self:Print("Merchant Cheng calculator not initialized.")
            end
        else
            if self.MerchantChengCalculator then
                local cost = self.MerchantChengCalculator:GetContainerCost()
                self:Print(string.format("Current container cost: %s", self:FormatMoney(cost)))
            else
                self:Print("Merchant Cheng calculator not initialized.")
            end
        end
    elseif args[1] == "debug" then
        if #args >= 2 and args[2] == "queries" then
            if self.AuctionatorInterface then
                self.AuctionatorInterface:DebugDatabaseContents()
            else
                self:Print("AuctionatorInterface not initialized yet.")
            end
        elseif #args >= 2 and args[2] == "refresh" then
            if self.AuctionatorInterface then
                self:Print("Starting debug refresh of auction data...")
                self.AuctionatorInterface:RefreshData()
            else
                self:Print("AuctionatorInterface not initialized yet.")
            end
        else
            self:PrintDebugInfo()
        end
    elseif args[1] == "reset" then
        self:ResetConfig()
    elseif args[1] == "help" then
        self:ShowHelp()
    else
        self:ShowHelp()
    end
end

--[[
    Display help information for slash commands
    Shows all available commands and their descriptions
]]--
function IronPawProfit:ShowHelp()
    self:Print("IronPaw Profit Calculator Commands:")
    self:Print("/ironpaw show - Open the main window")
    self:Print("/ironpaw scan - Refresh auction house data")
    self:Print("/ironpaw tokens - Show current token count")
    self:Print("/ironpaw config - Show current configuration settings")
    self:Print("/ironpaw sales - Show auction sales report and success rates")
    self:Print("/ironpaw market - Show market analysis and competition levels")
    self:Print(" ")
    self:Print("Merchant Cheng Token Generation:")
    self:Print("/ironpaw cheng - Analyze raw materials for token generation")
    self:Print("/ironpaw materials - Show raw material purchase recommendations") 
    self:Print("/ironpaw containers [cost] - Set/show Merchant Cheng container cost")
    self:Print(" ")
    self:Print("Debug Commands:")
    self:Print("/ironpaw debug - Show debug information")
    self:Print("/ironpaw debug queries - Debug database vs query comparison")
    self:Print("/ironpaw debug refresh - Debug refresh with detailed logging")
    self:Print("/ironpaw reset - Reset configuration to defaults")
    self:Print("/ironpaw help - Show this help")
end

--[[
    Display current configuration settings
    Shows all config values and how to modify them
]]--
function IronPawProfit:ShowConfig()
    self:Print("=== IronPaw Profit Calculator Configuration ===")
    
    -- Get current config values
    local minProfit = self:GetConfig("minProfit") or 100
    local maxInvestment = self:GetConfig("maxInvestment") or 1000
    local showOnlyProfitable = self:GetConfig("showOnlyProfitable")
    local autoScan = self:GetConfig("autoScan")
    local maxRecommendations = self:GetConfig("maxRecommendationsPerItem") or 999
    local maxStacksPerItem = self:GetConfig("maxStacksPerItem") or 999
    local prioritizeTopItem = self:GetConfig("prioritizeTopItem")
    local dataMaxAge = self:GetConfig("dataMaxAge") or 168
    
    -- Display current values
    self:Print(string.format("Minimum Profit: %s", self:FormatMoney(minProfit)))
    self:Print(string.format("Maximum Investment: %dg", maxInvestment))
    self:Print(string.format("Show Only Profitable: %s", showOnlyProfitable and "Yes" or "No"))
    self:Print(string.format("Auto Scan on Login: %s", autoScan and "Yes" or "No"))
    self:Print(string.format("Max Recommendations: %d", maxRecommendations))
    self:Print(string.format("Max Stacks Per Item: %s", maxStacksPerItem == 999 and "No Limit" or tostring(maxStacksPerItem)))
    self:Print(string.format("Prioritize Top Item: %s", prioritizeTopItem and "Yes" or "No"))
    self:Print(string.format("Data Max Age: %d hours", dataMaxAge))
    
    self:Print(" ")
    self:Print("To modify settings, edit them in the main UI or use:")
    self:Print("/ironpaw reset - Reset all settings to defaults")
    self:Print(" ")
    self:Print("Note: Most settings can be changed in the main addon window.")
end

--[[
    Show auction sales report and success rates
    Analyzes auction performance to help with investment decisions
]]--
function IronPawProfit:ShowSalesReport()
    if not self.AuctionatorInterface then
        self:Print("Auctionator interface not available.")
        return
    end
    
    self:Print("=== IronPaw Auction Sales Report ===")
    
    local report = self.AuctionatorInterface:GenerateAuctionReport()
    
    if #report.warnings > 0 then
        self:Print("Warnings:")
        for _, warning in ipairs(report.warnings) do
            self:Print("  " .. warning)
        end
        return
    end
    
    -- Overall statistics
    local overview = report.overview
    self:Print(string.format("Total Auctions: %d sold, %d active, %d expired", 
        overview.totalSold, overview.totalActive, overview.totalExpired))
    
    if overview.totalSold > 0 then
        self:Print(string.format("Sales Value: %s (avg: %s per auction)", 
            self:FormatMoney(overview.totalSalesValue),
            self:FormatMoney(overview.averageSaleValue)))
    end
    
    if overview.totalActive > 0 then
        self:Print(string.format("Active Value: %s", self:FormatMoney(overview.totalActiveValue)))
    end
    
    -- Item-specific recommendations
    if #report.recommendations > 0 then
        self:Print(" ")
        self:Print("Recommendations based on auction history:")
        for _, rec in ipairs(report.recommendations) do
            if rec.type == "warning" then
                self:Print("|cFFFF6B6B" .. rec.message .. "|r") -- Red text
            else
                self:Print("|cFF90EE90" .. rec.message .. "|r") -- Light green text
            end
        end
    end
    
    -- Show top performers if we have data
    local topItems = {}
    for itemID, data in pairs(report.byItem) do
        if data.stats.sold > 0 then
            table.insert(topItems, data)
        end
    end
    
    if #topItems > 0 then
        table.sort(topItems, function(a, b) return a.successRate > b.successRate end)
        
        self:Print(" ")
        self:Print("Top performing items:")
        for i = 1, math.min(5, #topItems) do
            local item = topItems[i]
            self:Print(string.format("  %s: %.1f%% success, %s profit/token", 
                item.name, item.successRate * 100, self:FormatMoney(item.profitPerToken)))
        end
    end
    
    self:Print(" ")
    self:Print("Use this data to make informed investment decisions!")
end

--[[
    Show market analysis and competition levels
    Analyzes current auction house conditions for all items
]]--
function IronPawProfit:ShowMarketAnalysis()
    if not self.Database then
        self:Print("Database not available yet.")
        return
    end
    
    self:Print("=== IronPaw Market Analysis ===")
    
    -- Collect items with market data
    local itemsWithData = {}
    local totalItems = 0
    
    for itemID, itemData in pairs(self.Database) do
        totalItems = totalItems + 1
        if itemData.marketAvailable and itemData.profitPerToken and itemData.profitPerToken > 0 then
            -- Calculate market-adjusted priority
            local marketMultiplier = self.ProfitCalculator:GetMarketMultiplier(itemData)
            local marketReason = self.ProfitCalculator:GetMarketReason(itemData)
            
            table.insert(itemsWithData, {
                name = itemData.name,
                profitPerToken = itemData.profitPerToken,
                marketMultiplier = marketMultiplier,
                marketReason = marketReason,
                competitionLevel = itemData.competitionLevel or "unknown",
                marketDepth = itemData.marketDepth or 0,
                averageTimeOnMarket = itemData.averageTimeOnMarket or 0,
                adjustedProfit = itemData.profitPerToken * marketMultiplier
            })
        end
    end
    
    if #itemsWithData == 0 then
        self:Print("No market data available. Run '/ironpaw scan' first.")
        return
    end
    
    -- Sort by market-adjusted profit
    table.sort(itemsWithData, function(a, b) return a.adjustedProfit > b.adjustedProfit end)
    
    self:Print(string.format("Analyzed %d items with market data:", #itemsWithData))
    self:Print(" ")
    
    -- Show top recommendations based on market conditions
    self:Print("Top recommendations (market-adjusted):")
    for i = 1, math.min(8, #itemsWithData) do
        local item = itemsWithData[i]
        local multiplierText = ""
        if item.marketMultiplier > 1.1 then
            multiplierText = "|cFF90EE90+" .. string.format("%.0f%%|r", (item.marketMultiplier - 1) * 100)
        elseif item.marketMultiplier < 0.9 then
            multiplierText = "|cFFFF6B6B" .. string.format("%.0f%%|r", (item.marketMultiplier - 1) * 100)
        else
            multiplierText = "±0%"
        end
        
        self:Print(string.format("  %d. %s: %s -> %s (%s)", 
            i, 
            item.name,
            self:FormatMoney(item.profitPerToken),
            self:FormatMoney(item.adjustedProfit),
            multiplierText))
        self:Print(string.format("     Market: %s", item.marketReason))
    end
    
    -- Show market competition summary
    self:Print(" ")
    self:Print("Competition analysis:")
    local competitionCounts = {low = 0, medium = 0, high = 0, very_high = 0, unknown = 0}
    local highCompetitionItems = {}
    
    for _, item in ipairs(itemsWithData) do
        competitionCounts[item.competitionLevel] = competitionCounts[item.competitionLevel] + 1
        if item.competitionLevel == "high" or item.competitionLevel == "very_high" then
            table.insert(highCompetitionItems, item.name)
        end
    end
    
    self:Print(string.format("  Low competition: %d items", competitionCounts.low))
    self:Print(string.format("  Medium competition: %d items", competitionCounts.medium))
    self:Print(string.format("  High competition: %d items", competitionCounts.high))
    self:Print(string.format("  Very high competition: %d items", competitionCounts.very_high))
    
    if #highCompetitionItems > 0 then
        self:Print(" ")
        self:Print("|cFFFF6B6BAvoid due to high competition:|r")
        for i = 1, math.min(5, #highCompetitionItems) do
            self:Print("  • " .. highCompetitionItems[i])
        end
    end
    
    self:Print(" ")
    self:Print("Market analysis considers competition, current listings, and sale speed.")
end

--[[
    Show Merchant Cheng raw material analysis
    Displays cost per token for raw materials that can be used with containers
]]--
function IronPawProfit:ShowMerchantChengAnalysis()
    if not self.MerchantChengCalculator then
        self:Print("Merchant Cheng calculator not initialized.")
        return
    end
    
    self:Print("=== Merchant Cheng Token Generation Analysis ===")
    
    local report = self.MerchantChengCalculator:GenerateRawMaterialReport()
    
    if #report.warnings > 0 then
        for _, warning in ipairs(report.warnings) do
            self:Print("|cFFFF6B6BWarning:|r " .. warning)
        end
        self:Print(" ")
    end
    
    if #report.profitable == 0 then
        self:Print("No profitable raw materials found for token generation.")
        self:Print("Container costs may be too high relative to potential profits.")
        return
    end
    
    self:Print(string.format("Found %d profitable raw materials for token generation:", #report.profitable))
    self:Print(string.format("Container cost: %s", self:FormatMoney(self.MerchantChengCalculator:GetContainerCost())))
    self:Print(" ")
    
    -- Show top profitable raw materials
    self:Print("Most profitable raw materials (cost per token):")
    for i = 1, math.min(10, #report.profitable) do
        local mat = report.profitable[i]
        local profitColor = mat.netProfit > 50000 and "|cFF90EE90" or "|cFFFFFFFF" -- Green for >5g profit, white otherwise
        
        self:Print(string.format("  %d. %s (%s)", i, mat.materialName, mat.category))
        self:Print(string.format("     Cost per token: %s | Net profit: %s%s|r", 
            self:FormatMoney(mat.totalCostPerToken),
            profitColor,
            self:FormatMoney(mat.netProfit)))
        self:Print(string.format("     Materials needed: %d x %s = %s", 
            mat.materialsNeeded,
            self:FormatMoney(mat.materialPrice),
            self:FormatMoney(mat.materialsNeeded * mat.materialPrice)))
        self:Print(string.format("     Competition: %s | Market depth: %d listings", 
            mat.competitionLevel, mat.marketDepth))
        self:Print(" ")
    end
    
    self:Print("Use '/ironpaw materials <gold>' to see purchase recommendations.")
    self:Print("Use '/ironpaw containers <cost>' to update container cost.")
end

--[[
    Show raw material purchase recommendations
    Displays optimal raw material purchases for token generation
]]--
function IronPawProfit:ShowRawMaterialReport()
    if not self.MerchantChengCalculator then
        self:Print("Merchant Cheng calculator not initialized.")
        return
    end
    
    -- Try to determine available gold (this is a placeholder - actual implementation would need bag scanning)
    local availableGold = 1000000 -- Default to 100g in copper for demonstration
    
    self:Print("=== Raw Material Token Generation Report ===")
    
    local purchases, totalGoldNeeded, tokensGenerated = self.MerchantChengCalculator:CalculateOptimalRawMaterialPurchases(availableGold, 50)
    
    if #purchases == 0 then
        self:Print("No profitable raw material purchases found.")
        return
    end
    
    self:Print(string.format("Optimal token generation plan (max 50 tokens):"))
    self:Print(string.format("Total investment: %s | Tokens generated: %d", 
        self:FormatMoney(totalGoldNeeded), tokensGenerated))
    self:Print(" ")
    
    local totalProfit = 0
    
    for i, purchase in ipairs(purchases) do
        totalProfit = totalProfit + purchase.netProfit
        
        self:Print(string.format("%d. %s (%s)", i, purchase.materialName, purchase.category))
        self:Print(string.format("   Generate %d tokens | Investment: %s", 
            purchase.tokensToGenerate, self:FormatMoney(purchase.totalCost)))
        self:Print(string.format("   Buy %d materials + %d containers", 
            purchase.materialsNeeded, purchase.containersNeeded))
        self:Print(string.format("   Expected profit: %s | Net profit: %s", 
            self:FormatMoney(purchase.expectedProfit), self:FormatMoney(purchase.netProfit)))
        self:Print(" ")
    end
    
    self:Print(string.format("Total net profit potential: %s", self:FormatMoney(totalProfit)))
    self:Print("Note: This assumes you can sell Nam Ironpaw items at calculated profit margins.")
end

--[[
    Update Ironpaw token display in UI
    Called when bags change or UI is refreshed
]]--
function IronPawProfit:UpdateIronpawTokens()
    local tokens = self:GetIronpawTokenCount()
    if self.mainFrame and self.mainFrame:IsShown() then
        self:UpdateTokenDisplay(tokens)
    end
end

--[[
    Get current Ironpaw Token count from currency system
    
    Returns:
        number: Current number of Ironpaw Tokens the player has
        
    Note: Ironpaw Tokens are currency ID 402 in MoP Classic
]]--
function IronPawProfit:GetIronpawTokenCount()
    local tokens = 0
    local ironpawTokenCurrencyID = 402 -- Ironpaw Token currency ID
    
    -- In MoP Classic, GetCurrencyInfo returns a table with currency data
    local currencyInfo = GetCurrencyInfo(ironpawTokenCurrencyID)
    if currencyInfo and type(currencyInfo) == "table" and currencyInfo.name then
        tokens = currencyInfo.quantity or 0
    end
    
    return tokens
end

--[[
    Refresh auction house data for all items
    Triggers a complete scan of auction house prices via Auctionator
    Includes safety checks to ensure all required modules are loaded
]]--
function IronPawProfit:RefreshAuctionData()
    -- Safety checks: ensure components are ready
    if not self.AuctionatorInterface then
        self:Print("Auctionator interface not ready yet. Please wait for addon to fully initialize.")
        return
    end
    
    if not self.Database then
        self:Print("Database not ready yet. Please wait for addon to fully initialize.")
        return
    end
    
    self.AuctionatorInterface:RefreshData()
    if self.mainFrame and self.mainFrame:IsShown() then
        self:UpdateProfitCalculations()
    end
end

function IronPawProfit:InitializeConfig()
    -- Set default config reference
    if not self.DefaultConfig then
        self.DefaultConfig = {
            minProfit = 1,
            maxInvestment = 1000,
            showOnlyProfitable = true,
            autoScan = false,
            showMinimapButton = true,
            colorCodeProfit = true,
            maxRecommendationsPerItem = 999, -- Show all items instead of limiting to 10
            dataMaxAge = 168,
            windowPosition = {
                point = "CENTER",
                x = 0,
                y = 0
            }
        }
    end
    
    -- Ensure config functions are available
    if not self.ValidateConfig then
        -- Config functions will be loaded from Config.lua
    end
    
end

function IronPawProfit:InitializeDatabase()
    -- Initialize the database module
    if IronPawProfitDatabase and IronPawProfitDatabase.Initialize then
        self.Database = IronPawProfitDatabase
        IronPawProfitDatabase:Initialize(self)
    else
        self:Print("Warning: Database module not loaded")
    end
end

function IronPawProfit:InitializeAuctionatorInterface()
    -- Initialize the Auctionator interface module
    if IronPawProfitAuctionatorInterface and IronPawProfitAuctionatorInterface.Initialize then
        self.AuctionatorInterface = IronPawProfitAuctionatorInterface
        IronPawProfitAuctionatorInterface:Initialize(self)
    else
        self:Print("Warning: Auctionator interface module not loaded")
    end
end

function IronPawProfit:InitializeProfitCalculator()
    -- Initialize the profit calculator module
    if IronPawProfitCalculator and IronPawProfitCalculator.Initialize then
        self.ProfitCalculator = IronPawProfitCalculator
        IronPawProfitCalculator:Initialize(self)
    else
        self:Print("Warning: Profit calculator module not loaded")
    end
end

function IronPawProfit:InitializeMerchantChengCalculator()
    -- Initialize the merchant cheng calculator module
    if IronPawProfitMerchantChengCalculator and IronPawProfitMerchantChengCalculator.Initialize then
        self.MerchantChengCalculator = IronPawProfitMerchantChengCalculator
        IronPawProfitMerchantChengCalculator:Initialize(self)
    else
        self:Print("Warning: Merchant Cheng calculator module not loaded")
    end
end

--[[
    Initialize Greenfield calculator module
]]--
function IronPawProfit:InitializeGreenfieldCalculator()
    if IronPawProfitGreenfieldCalculator and IronPawProfitGreenfieldCalculator.Initialize then
        IronPawProfitGreenfieldCalculator:Initialize(self)
    end
end

function IronPawProfit:InitializeUI()
    -- Initialize UI modules
    if IronPawProfitMainFrame and IronPawProfitMainFrame.Initialize then
        self.MainFrame = IronPawProfitMainFrame
        IronPawProfitMainFrame:Initialize(self)
    end
    
    if IronPawProfitProfitDisplay and IronPawProfitProfitDisplay.Initialize then
        self.ProfitDisplay = IronPawProfitProfitDisplay
        IronPawProfitProfitDisplay:Initialize(self)
    end
    
end

function IronPawProfit:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[IronPaw Profit]|r " .. msg)
end

function IronPawProfit:ShowMainFrame()
    if not self.mainFrame then
        self.mainFrame = self:CreateMainFrame()
    end
    self.mainFrame:Show()
    self:UpdateProfitCalculations()
end

function IronPawProfit:UpdateProfitCalculations()
    -- Prefer aggregated stored tokens across characters when available
    local tokens = nil
    if self.GetTotalStoredTokens then
        local ok, total = pcall(function() return self:GetTotalStoredTokens() end)
        if ok and type(total) == "number" and total >= 0 then
            tokens = total
        end
    end

    if tokens == nil then
        tokens = self:GetIronpawTokenCount()
    end

    -- Delegate to profit calculator with chosen token count
    if self.ProfitCalculator and self.ProfitCalculator.GenerateInvestmentReport then
        -- Some profit modules expect UpdateProfitCalculations; call accordingly
        if self.ProfitCalculator.UpdateProfitCalculations then
            pcall(function() self.ProfitCalculator:UpdateProfitCalculations(tokens) end)
        else
            pcall(function() self.ProfitCalculator:GenerateInvestmentReport(tokens) end)
        end
    end
end

function IronPawProfit:UpdateTokenDisplay(tokens)
    if not self.mainFrame or not self.mainFrame.tokenDisplay then return end
    local current = tokens or self:GetIronpawTokenCount()
    local total = nil
    if self.GetTotalStoredTokens then
        local ok, res = pcall(function() return self:GetTotalStoredTokens() end)
        if ok and type(res) == "number" then
            total = res
        end
    end

    -- Delegate rendering to main frame's UpdateTokenDisplay function
    if self.mainFrame and self.mainFrame.tokenDisplay and self.MainFrame and self.MainFrame.UpdateTokenDisplay then
        -- Call the UI module's method to format the display
        pcall(function() self.MainFrame:UpdateTokenDisplay(current) end)
    else
        if total then
            self.mainFrame.tokenDisplay.text:SetText(string.format("Ironpaw Tokens: %d (Total: %d)", current, total))
        else
            self.mainFrame.tokenDisplay.text:SetText(string.format("Ironpaw Tokens: %d", current))
        end
    end
end

function IronPawProfit:PrintDebugInfo()
    self:Print("=== Debug Information ===")
    self:Print(string.format("Version: %s", self.version))
    self:Print(string.format("Config loaded: %s", tostring(self.initState.config)))
    self:Print(string.format("Database loaded: %s", tostring(self.initState.database)))
    self:Print(string.format("Auctionator Interface loaded: %s", tostring(self.initState.auctionatorInterface)))
    self:Print(string.format("Profit Calculator loaded: %s", tostring(self.initState.profitCalculator)))
    self:Print(string.format("UI loaded: %s", tostring(self.initState.ui)))
    self:Print(string.format("Auctionator available: %s", tostring(IsAddOnLoaded("Auctionator"))))
    if self.Database then
        self:Print(string.format("Items in database: %d", self:GetDatabaseItemCount()))
    end
    local tokens = self:GetIronpawTokenCount()
    self:Print(string.format("Current tokens: %d", tokens))
end

function IronPawProfit:ResetConfig()
    -- Reset configuration to defaults
    if self.db and self.db.profile then
        for key, value in pairs(defaults.profile) do
            self.db.profile[key] = value
        end
        self:Print("Configuration reset to defaults.")
    end
end
