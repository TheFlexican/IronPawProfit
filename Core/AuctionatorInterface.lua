-- AuctionatorInterface.lua
-- Interfaces with Auctionator addon to get market price data

local addonName, addon = ...

-- Create global AuctionatorInterface module
IronPawProfitAuctionatorInterface = {}

-- Initialize the module
function IronPawProfitAuctionatorInterface:Initialize(mainAddon)
    self.addon = mainAddon
    
    -- Add AuctionatorInterface functions to main addon
    self.addon.AuctionatorInterface = {}
    local AuctionatorInterface = self.addon.AuctionatorInterface

    -- Check if Auctionator is available
    function AuctionatorInterface:IsAuctionatorAvailable()
        return IsAddOnLoaded("Auctionator") and Auctionator and Auctionator.API and Auctionator.API.v1
    end

    -- Get the correct item ID for auction house lookup
    function AuctionatorInterface:GetAuctionItemID(itemData)
        -- For sacks, use the individual material ID for auction lookup
        return itemData.materialID or itemData.itemID
    end

    -- Calculate total value for sacks containing multiple items
    function AuctionatorInterface:CalculateTotalValue(itemData, individualPrice)
        if not individualPrice then return nil end
        
        -- For sacks, multiply individual price by quantity
        if itemData.materialID and itemData.contains then
            return individualPrice * itemData.contains
        end
        
        -- For individual items, return as-is
        return individualPrice
    end

    -- Get market price from Auctionator
    function AuctionatorInterface:GetMarketPrice(itemID, realm, faction)
        if not self:IsAuctionatorAvailable() then
            return nil, nil, false
        end
        
        realm = realm or GetRealmName()
        faction = faction or UnitFactionGroup("player")
        
        local callerID = "IronPawProfit"
        local marketPrice = nil
        local serverMedian = nil
        local available = false
    
        
        -- Try to get market price using Auctionator API
        pcall(function()
            marketPrice = Auctionator.API.v1.GetAuctionPriceByItemID(callerID, itemID)
        end)
        
        -- Get mean price over 7 days as server median
        if Auctionator.Database then
            pcall(function()
                serverMedian = Auctionator.Database:GetMeanPrice(tostring(itemID), 7)
            end)
        end
        
        -- Check if item is available on auction house
            if marketPrice and marketPrice > 0 then
                available = true
            elseif serverMedian and serverMedian > 0 then
                available = true
                marketPrice = serverMedian -- Use mean as fallback
            end
            
            return marketPrice, serverMedian, available
        end

-- Get detailed auction data for an item
        function AuctionatorInterface:GetDetailedData(itemID, realm, faction)
    if not self:IsAuctionatorAvailable() then
        return {}
    end
    
    realm = realm or GetRealmName()
    faction = faction or UnitFactionGroup("player")
    
    local data = {
        itemID = itemID,
        realm = realm,
        faction = faction,
        marketPrice = 0,
        serverMedian = 0,
        confidence = 0,
        seen = 0,
        lastSeen = 0,
        available = false
    }
    
    local callerID = "IronPawProfit"
    
    -- Get current market price
    pcall(function()
        data.marketPrice = Auctionator.API.v1.GetAuctionPriceByItemID(callerID, itemID) or 0
    end)
    
    -- Get mean price as server median
    if Auctionator.Database then
        pcall(function()
            data.serverMedian = Auctionator.Database:GetMeanPrice(tostring(itemID), 7) or 0
        end)
        
        -- Get price age (days since last seen)
        pcall(function()
            local age = Auctionator.API.v1.GetAuctionAgeByItemID(callerID, itemID)
            if age then
                data.lastSeen = time() - (age * 24 * 60 * 60) -- Convert days to timestamp
                data.seen = 1 -- We have data
                data.confidence = math.max(0, 100 - (age * 10)) -- Confidence decreases with age
            end
        end)
    end
    
    -- Determine availability
    data.available = (data.marketPrice > 0 or data.serverMedian > 0)
    
    return data
end

-- Refresh all auction data for items in database
        function AuctionatorInterface:RefreshData()
    if not self:IsAuctionatorAvailable() then
        IronPawProfit:Print("Auctionator not available for price data.")
        return false
    end
    
    local realm = GetRealmName()
    local faction = UnitFactionGroup("player")
    local updated = 0
    local errors = 0
    local totalItems = 0
    
    -- Safety check: ensure Database exists
    if not IronPawProfit.Database then
        IronPawProfit:Print("Database not ready yet. Please wait for addon to fully initialize.")
        return
    end
    
    -- DEBUG: Count total items in database first
    for itemID, itemData in pairs(IronPawProfit.Database) do
        totalItems = totalItems + 1
    end
    
    -- Convert to array for async processing
    local itemsToProcess = {}
    for itemID, itemData in pairs(IronPawProfit.Database) do
        table.insert(itemsToProcess, {itemID = itemID, itemData = itemData})
    end
    
    -- Start async processing
    self:ProcessItemsAsync(itemsToProcess, 1, updated, errors, totalItems)
    
    return true
end

-- Process items asynchronously to prevent UI freezing
function AuctionatorInterface:ProcessItemsAsync(itemsToProcess, currentIndex, updated, errors, totalItems)
    if currentIndex > #itemsToProcess then
        if errors > 0 then
            message = message .. string.format(" (%d errors)", errors)
        end
        
        -- Refresh UI after completion
        if IronPawProfit.RefreshUI then
            IronPawProfit:RefreshUI()
        end
        return
    end
    
    local realm = GetRealmName()
    local faction = UnitFactionGroup("player")
    local item = itemsToProcess[currentIndex]
    local itemID = item.itemID
    local itemData = item.itemData
    
    -- Use materialID for auction house lookup if available (for sacks)
    local lookupItemID = self:GetAuctionItemID(itemData)

    
    local success, individualMarketPrice, individualServerMedian, available = pcall(function()
        return self:GetMarketPrice(lookupItemID, realm, faction)
    end)
    
    if success then
        -- Calculate total value (multiply by quantity for sacks)
        local totalMarketPrice = self:CalculateTotalValue(itemData, individualMarketPrice)
        local totalServerMedian = self:CalculateTotalValue(itemData, individualServerMedian)
        
        if IronPawProfit:UpdateItemMarketData(itemID, totalMarketPrice, totalServerMedian, available) then
            updated = updated + 1
        end
    else
        IronPawProfit:Print(string.format("DEBUG: ERROR querying %s (ID:%d)", itemData.name, itemID))
        errors = errors + 1
    end
    
    -- Schedule next item processing on next frame (10ms delay)
    C_Timer.After(0.01, function()
        self:ProcessItemsAsync(itemsToProcess, currentIndex + 1, updated, errors, totalItems)
    end)
end

-- Get price history for an item
        function AuctionatorInterface:GetPriceHistory(itemID, days)
    if not self:IsAuctionatorAvailable() or not Auctionator.Database then
        return {}
    end
    
    days = days or 7
    local history = {}
    
    pcall(function()
        local entries = Auctionator.Database:GetPriceHistory(tostring(itemID))
        
        if entries then
            -- Sort by most recent first
            table.sort(entries, function(a, b) 
                return (a.rawDay or 0) > (b.rawDay or 0) 
            end)
            
            -- Take only the requested number of days
            for i = 1, math.min(days, #entries) do
                local entry = entries[i]
                if entry.minSeen and entry.minSeen > 0 then
                    table.insert(history, {
                        timestamp = entry.rawDay and (entry.rawDay * 24 * 60 * 60) or 0,
                        price = entry.minSeen,
                        date = entry.date or "Unknown",
                        available = entry.available or 0
                    })
                end
            end
        end
    end)
    
    return history
end

-- Get current auction listings for an item (limited functionality with Auctionator)
        function AuctionatorInterface:GetCurrentListings(itemID)
    if not self:IsAuctionatorAvailable() then
        return {}
    end
    
    local listings = {}
    local callerID = "IronPawProfit"
    
    -- Auctionator doesn't expose individual listings, so we simulate with available data
    pcall(function()
        local price = Auctionator.API.v1.GetAuctionPriceByItemID(callerID, itemID)
        if price and price > 0 then
            table.insert(listings, {
                buyout = price,
                count = 1,
                timeLeft = 4, -- Unknown, assume long time
                unitPrice = price
            })
        end
    end)
    
    return listings
end

-- Validate Auctionator data quality
        function AuctionatorInterface:ValidateDataQuality(itemID)
    if not self:IsAuctionatorAvailable() then
        return false, "Auctionator not available"
    end
    
    local data = self:GetDetailedData(itemID)
    local callerID = "IronPawProfit"
    
    -- Check if we have recent data
    local daysSinceLastScan = 0
    local age = nil
    
    pcall(function()
        age = Auctionator.API.v1.GetAuctionAgeByItemID(callerID, itemID)
    end)
    
    if age then
        daysSinceLastScan = age
    end
    
    -- Validate data quality
    local isGood = false
    local reason = ""
    
    if not data.available then
        reason = "No auction data available"
    elseif age == nil then
        reason = "No scan history"
    elseif daysSinceLastScan > 7 then
        reason = string.format("Data older than 7 days (%d days)", math.floor(daysSinceLastScan))
    elseif data.marketPrice <= 0 and data.serverMedian <= 0 then
        reason = "No market price"
    else
        isGood = true
        reason = string.format("Good data quality (%.1f days old)", daysSinceLastScan)
    end
    
    return isGood, reason, data
end

        -- Initialize the Auctionator interface directly
        IronPawProfit.AuctionatorInterface = AuctionatorInterface
        
        if AuctionatorInterface:IsAuctionatorAvailable() then
            IronPawProfit:Print("Auctionator interface initialized successfully.")
        else
            IronPawProfit:Print("Auctionator not found. Manual price entry will be required.")
        end

-- Manual price override for items without Auctionator data
        function AuctionatorInterface:SetManualPrice(itemID, price)
    if IronPawProfit:UpdateItemMarketData(itemID, price, price, true) then
        IronPawProfit:Print(string.format("Manual price set for %s: %s", 
            IronPawProfit:GetItemLink(itemID), 
            IronPawProfit:FormatMoney(price)))
        return true
    end
    return false
end

-- Export functions for external use
        function AuctionatorInterface:GetAvailableItems()
    local available = {}
    
    -- Safety check: ensure Database exists
    if not IronPawProfit.Database then
        return available
    end
    
    for itemID, data in pairs(IronPawProfit.Database) do
        if data.marketAvailable and data.marketPrice > 0 then
            table.insert(available, data)
        end
    end
    return available
end

-- Get vendor price if available
        function AuctionatorInterface:GetVendorPrice(itemID)
    if not self:IsAuctionatorAvailable() then
        return nil
    end
    
    local callerID = "IronPawProfit"
    local vendorPrice = nil
    
    pcall(function()
        vendorPrice = Auctionator.API.v1.GetVendorPriceByItemID(callerID, itemID)
    end)
    
    return vendorPrice
end

-- DEBUG: Print database contents comparison
        function AuctionatorInterface:DebugDatabaseContents()
    IronPawProfit:Print("=== DEBUG: Database Contents Analysis ===")
    
    -- Check IronpawInventory vs Database
    local inventoryCount = 0
    local databaseCount = 0
    
    if IronPawProfit.IronpawInventory then
        for itemID, data in pairs(IronPawProfit.IronpawInventory) do
            inventoryCount = inventoryCount + 1
            IronPawProfit:Print(string.format("Inventory: %d = %s", itemID, data.name))
        end
    else
        IronPawProfit:Print("ERROR: IronpawInventory not found!")
    end
    
    if IronPawProfit.Database then
        for itemID, data in pairs(IronPawProfit.Database) do
            databaseCount = databaseCount + 1
            IronPawProfit:Print(string.format("Database: %d = %s (materialID: %s)", 
                itemID, data.name, tostring(data.materialID)))
        end
    else
        IronPawProfit:Print("ERROR: Database not found!")
    end
    
    IronPawProfit:Print(string.format("Total in IronpawInventory: %d", inventoryCount))
    IronPawProfit:Print(string.format("Total in Database: %d", databaseCount))
    IronPawProfit:Print("=== END DEBUG ===")
end

-- Check if price data is exact (not estimated)
        function AuctionatorInterface:IsDataExact(itemID)
    if not self:IsAuctionatorAvailable() then
        return false
    end
    
    local callerID = "IronPawProfit"
    local isExact = false
    
    pcall(function()
        isExact = Auctionator.API.v1.IsAuctionDataExactByItemID(callerID, itemID)
    end)
    
    return isExact or false
end

    return true
end
