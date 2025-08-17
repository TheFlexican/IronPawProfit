--[[
    Config.lua - Configuration and Settings Management
    
    This module manages all configuration settings for the IronPaw Profit Calculator.
    It provides default values, validation, and accessor functions for all addon settings.
    
    Features:
    - Default configuration values with sensible defaults
    - Configuration validation to ensure values are within acceptable ranges
    - Get/Set functions for accessing configuration values
    - Integration with WoW's saved variables system
    
    Configuration Options:
    - minProfit: Minimum profit threshold for recommendations
    - maxInvestment: Maximum gold willing to invest
    - showOnlyProfitable: Filter to show only profitable items
    - autoScan: Automatically scan auction house on login
    - maxRecommendationsPerItem: Maximum items to show in results
    - dataMaxAge: Maximum age of auction data before refresh needed
    - windowPosition: UI window position settings
]]--

-- Config.lua
-- Configuration and settings management

local addonName, addon = ...

-- Default configuration values
-- These are used when the addon is first installed or after a reset
local DefaultConfig = {
    minProfit = 100,                     -- Minimum profit in copper to show recommendations
    maxInvestment = 1000,                -- Maximum gold willing to invest (in gold)
    showOnlyProfitable = true,           -- Only show items with positive profit
    autoScan = false,                    -- Automatically scan auction house on login
    showMinimapButton = true,            -- Show minimap button (future feature)
    colorCodeProfit = true,              -- Color-code profit values in UI
    maxRecommendationsPerItem = 999,     -- Maximum items to display (999 = show all)
    maxStacksPerItem = 999,              -- Maximum stacks per item (999 = no limit)
    prioritizeTopItem = true,            -- Give top profitable item priority for all tokens
    dataMaxAge = 168,                    -- Maximum age of auction data in hours (7 days)
    merchantChengContainerCost = 13500,  -- Cost per container from Merchant Cheng (1.35g in copper)
    windowPosition = {                   -- UI window position
        point = "CENTER",
        x = 0,
        y = 0
    }
}

-- Create a frame to ensure IronPawProfit is loaded before we attach functions
-- This handles the timing issue where config functions need to be available
-- before the main addon is fully initialized
local configFrame = CreateFrame("Frame")
configFrame:RegisterEvent("ADDON_LOADED")
configFrame:SetScript("OnEvent", function(self, event, loadedAddonName)
    if loadedAddonName == addonName and IronPawProfit then
        -- Now we can safely attach functions to IronPawProfit
        IronPawProfit.DefaultConfig = DefaultConfig
        
        -- Configuration validation
        function IronPawProfit:ValidateConfig()
            if not self.db or not self.db.profile then
                return
            end
            
            local config = self.db.profile
            
            -- Ensure all values are within reasonable bounds
            config.minProfit = math.max(0, math.min(1000, config.minProfit or 1))
            config.maxInvestment = math.max(0, math.min(100000, config.maxInvestment or 1000))
            config.maxRecommendationsPerItem = math.max(1, math.min(999, config.maxRecommendationsPerItem or 999)) -- Allow up to 999 items
            config.maxStacksPerItem = math.max(1, math.min(999, config.maxStacksPerItem or 999)) -- Allow 1-999 stacks per item
            config.dataMaxAge = math.max(1, math.min(720, config.dataMaxAge or 168)) -- 1 hour to 30 days
            
            -- Ensure booleans
            config.showOnlyProfitable = (config.showOnlyProfitable ~= false)
            config.autoScan = (config.autoScan == true)
            config.showMinimapButton = (config.showMinimapButton ~= false)
            config.colorCodeProfit = (config.colorCodeProfit ~= false)
            config.prioritizeTopItem = (config.prioritizeTopItem ~= false)
        end

        -- Get configuration value with fallback
        function IronPawProfit:GetConfig(key)
            if self.db and self.db.profile then
                return self.db.profile[key]
            end
            return DefaultConfig[key]
        end

        -- Set configuration value
        function IronPawProfit:SetConfig(key, value)
            if self.db and self.db.profile then
                self.db.profile[key] = value
                self:ValidateConfig()
                return true
            end
            return false
        end

        -- Reset to defaults
        function IronPawProfit:ResetConfig()
            if self.db and self.db.profile then
                for key, value in pairs(DefaultConfig) do
                    if type(value) == "table" then
                        self.db.profile[key] = {}
                        for subkey, subvalue in pairs(value) do
                            self.db.profile[key][subkey] = subvalue
                        end
                    else
                        self.db.profile[key] = value
                    end
                end
                self:Print("Configuration reset to defaults.")
                return true
            end
            return false
        end

        -- Debug information
        function IronPawProfit:PrintDebugInfo()
            if not self then
                print("IronPawProfit not initialized")
                return
            end
            
            self:Print("=== Debug Information ===")
            self:Print("Addon Version: " .. (self.version or "Unknown"))
            local currentTokens = (self.GetIronpawTokenCount and self:GetIronpawTokenCount() or nil)
            local totalTokens = nil
            if self.GetTotalStoredTokens then
                local ok, res = pcall(function() return self:GetTotalStoredTokens() end)
                if ok and type(res) == "number" then totalTokens = res end
            end
            if totalTokens then
                self:Print(string.format("Tokens Available: %s (Total: %d)", tostring(currentTokens or "Unknown"), totalTokens))
            else
                self:Print("Tokens Available: " .. (currentTokens or "Unknown"))
            end
            self:Print("Database Items: " .. (self.GetDatabaseItemCount and self:GetDatabaseItemCount() or "Unknown"))
            
            if self.AuctionatorInterface then
                self:Print("Auctionator Available: " .. tostring(self.AuctionatorInterface:IsAuctionatorAvailable()))
            else
                self:Print("Auctionator Interface: Not initialized")
            end
            
            if self.db and self.db.profile then
                self:Print("Config - Min Profit: " .. (self.db.profile.minProfit or "Unknown") .. "g")
                self:Print("Config - Max Investment: " .. (self.db.profile.maxInvestment or "Unknown") .. "g")
                self:Print("Config - Show Only Profitable: " .. tostring(self.db.profile.showOnlyProfitable))
            else
                self:Print("Config: Not initialized")
            end
            
            local itemsWithData = 0
            if self.Database then
                for itemID, data in pairs(self.Database) do
                    if data.marketAvailable then
                        itemsWithData = itemsWithData + 1
                    end
                end
            end
            self:Print("Items with Market Data: " .. itemsWithData)
        end
        
        -- Unregister the event since we're done
        configFrame:UnregisterEvent("ADDON_LOADED")
    end
end)
