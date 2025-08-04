--[[
    IronPaw Profit Calculator - Main Addon File
    
    Author: TheFlexican
    Version: 1.0.0
    
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
IronPawProfit.version = "1.0.0"

-- Initialization state tracking
-- Ensures modules are loaded in the correct order
IronPawProfit.initState = {
    config = false,              -- Configuration system loaded
    database = false,            -- Item database loaded
    auctionatorInterface = false, -- Auctionator API integration loaded
    profitCalculator = false,    -- Profit calculation engine loaded
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
    
    -- Step 3: Initialize Auctionator interface
    self:InitializeAuctionatorInterface()
    self.initState.auctionatorInterface = true
    
    -- Step 4: Initialize profit calculator
    self:InitializeProfitCalculator()
    self.initState.profitCalculator = true
    
    -- Step 5: Initialize UI components
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
    
    -- Initialize token count
    self:UpdateIronpawTokens()
end

--[[
    Handle bag update events
    Updates token count when bags change (tokens are currency items)
]]--
function IronPawProfit:OnBagUpdate()
    -- Update token count when bags change
    self:UpdateIronpawTokens()
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
        self:Print(string.format("Current Ironpaw Tokens: %d", tokens))
    elseif args[1] == "config" then
        -- Show current configuration
        self:ShowConfig()
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
    local dataMaxAge = self:GetConfig("dataMaxAge") or 168
    
    -- Display current values
    self:Print(string.format("Minimum Profit: %s", self:FormatMoney(minProfit)))
    self:Print(string.format("Maximum Investment: %dg", maxInvestment))
    self:Print(string.format("Show Only Profitable: %s", showOnlyProfitable and "Yes" or "No"))
    self:Print(string.format("Auto Scan on Login: %s", autoScan and "Yes" or "No"))
    self:Print(string.format("Max Recommendations: %d", maxRecommendations))
    self:Print(string.format("Data Max Age: %d hours", dataMaxAge))
    
    self:Print(" ")
    self:Print("To modify settings, edit them in the main UI or use:")
    self:Print("/ironpaw reset - Reset all settings to defaults")
    self:Print(" ")
    self:Print("Note: Most settings can be changed in the main addon window.")
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
    -- This will be implemented by the profit calculator module
    if self.ProfitCalculator and self.ProfitCalculator.UpdateProfitCalculations then
        self.ProfitCalculator:UpdateProfitCalculations()
    end
end

function IronPawProfit:UpdateTokenDisplay(tokens)
    if self.mainFrame and self.mainFrame.tokenDisplay then
        self.mainFrame.tokenDisplay.text:SetText(string.format("Ironpaw Tokens: %d", tokens))
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
