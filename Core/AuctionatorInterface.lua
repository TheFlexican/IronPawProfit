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
        available = false,
        -- Market depth analysis
        marketDepth = 0,
        competitionLevel = "unknown",
        averageTimeOnMarket = 0,
        recommendationScore = 0
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
        
        -- Analyze market depth and competition
        data.marketDepth, data.competitionLevel, data.averageTimeOnMarket = self:AnalyzeMarketDepth(itemID)
        data.recommendationScore = self:CalculateRecommendationScore(data)
    end
    
    -- Determine availability
    data.available = (data.marketPrice > 0 or data.serverMedian > 0)
    
    return data
end

-- Analyze market depth and competition for an item
        function AuctionatorInterface:AnalyzeMarketDepth(itemID)
    if not self:IsAuctionatorAvailable() then
        return 0, "unknown", 0
    end
    
    local marketDepth = 0
    local competitionLevel = "low"
    local averageTimeOnMarket = 0
    
    pcall(function()
        -- Try to get current listings count
        local listings = self:GetCurrentListings(itemID)
        marketDepth = #listings
        
        -- Get price history to analyze competition
        local history = self:GetPriceHistory(itemID, 14) -- Look at 2 weeks
        
        if #history > 0 then
            -- Analyze price volatility and frequency
            local priceChanges = 0
            local totalDays = 0
            
            for i = 2, #history do
                local currentPrice = history[i-1].price
                local previousPrice = history[i].price
                if previousPrice > 0 then
                    local change = math.abs((currentPrice - previousPrice) / previousPrice)
                    if change > 0.1 then -- 10% price change
                        priceChanges = priceChanges + 1
                    end
                end
                totalDays = totalDays + 1
            end
            
            -- Determine competition level based on price volatility and market depth
            local volatilityRatio = totalDays > 0 and (priceChanges / totalDays) or 0
            
            if marketDepth > 20 and volatilityRatio > 0.3 then
                competitionLevel = "very_high"
            elseif marketDepth > 10 and volatilityRatio > 0.2 then
                competitionLevel = "high"  
            elseif marketDepth > 5 or volatilityRatio > 0.1 then
                competitionLevel = "medium"
            else
                competitionLevel = "low"
            end
            
            -- Estimate average time on market (simplified)
            averageTimeOnMarket = math.max(1, 14 - (#history * 0.5)) -- More frequent price updates = faster sales
        end
        
        -- Use Auctionator's database to get more detailed analysis if available
        if Auctionator.Database then
            pcall(function()
                -- Try to access internal auction tracking if available
                local recentSales = (Auctionator.Database.GetRecentSales and Auctionator.Database:GetRecentSales(tostring(itemID))) or {}
                if #recentSales > 0 then
                    -- Calculate actual average time on market from sales data
                    local totalTime = 0
                    for _, sale in ipairs(recentSales) do
                        totalTime = totalTime + (sale.timeOnMarket or 2) -- Default 2 days if unknown
                    end
                    averageTimeOnMarket = totalTime / #recentSales
                end
            end)
        end
    end)
    
    return marketDepth, competitionLevel, averageTimeOnMarket
end

-- Calculate recommendation score based on market conditions
        function AuctionatorInterface:CalculateRecommendationScore(data)
    local score = 50 -- Base score
    
    -- Factor in competition level
    if data.competitionLevel == "low" then
        score = score + 20
    elseif data.competitionLevel == "medium" then
        score = score + 5
    elseif data.competitionLevel == "high" then
        score = score - 10
    elseif data.competitionLevel == "very_high" then
        score = score - 25
    end
    
    -- Factor in market depth (too many listings = bad)
    if data.marketDepth == 0 then
        score = score + 15 -- No competition!
    elseif data.marketDepth <= 3 then
        score = score + 10 -- Low competition
    elseif data.marketDepth <= 10 then
        score = score + 0 -- Normal competition
    elseif data.marketDepth <= 20 then
        score = score - 15 -- High competition
    else
        score = score - 30 -- Very crowded market
    end
    
    -- Factor in average time on market
    if data.averageTimeOnMarket <= 1 then
        score = score + 15 -- Sells very fast
    elseif data.averageTimeOnMarket <= 3 then
        score = score + 5 -- Sells reasonably fast
    elseif data.averageTimeOnMarket <= 7 then
        score = score + 0 -- Normal selling time
    else
        score = score - 10 -- Takes too long to sell
    end
    
    -- Factor in data confidence
    score = score + (data.confidence * 0.2) -- Add up to 20 points for good data
    
    return math.max(0, math.min(100, score))
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
        
        -- Get detailed market analysis for the item
        local marketData = self:GetDetailedData(lookupItemID, realm, faction)
        
        -- Store market analysis data in the item
        itemData.marketDepth = marketData.marketDepth
        itemData.competitionLevel = marketData.competitionLevel
        itemData.averageTimeOnMarket = marketData.averageTimeOnMarket
        itemData.recommendationScore = marketData.recommendationScore
        itemData.dataConfidence = marketData.confidence
        
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

-- Check auction sale status and history
        function AuctionatorInterface:GetAuctionSaleData()
    if not self:IsAuctionatorAvailable() then
        return {
            sold = {},
            active = {},
            expired = {},
            totalSales = 0,
            totalActive = 0,
            error = "Auctionator not available"
        }
    end
    
    local saleData = {
        sold = {},
        active = {},
        expired = {},
        totalSales = 0,
        totalActive = 0,
        totalValue = 0,
        error = nil
    }
    
    -- Get owned auctions data
    pcall(function()
        -- For Modern AH (Retail)
        if C_AuctionHouse and C_AuctionHouse.GetNumOwnedAuctions then
            for index = 1, C_AuctionHouse.GetNumOwnedAuctions() do
                local info = C_AuctionHouse.GetOwnedAuctionInfo(index)
                if info then
                    local auctionData = {
                        itemID = info.itemKey.itemID,
                        itemLink = info.itemLink,
                        quantity = info.quantity,
                        buyoutAmount = info.buyoutAmount,
                        bidAmount = info.bidAmount,
                        timeLeft = info.timeLeftSeconds,
                        status = info.status -- 0 = active, 1 = sold
                    }
                    
                    if info.status == 1 then -- Sold
                        table.insert(saleData.sold, auctionData)
                        saleData.totalSales = saleData.totalSales + (info.buyoutAmount or info.bidAmount or 0)
                    elseif info.status == 0 then -- Active
                        if info.timeLeftSeconds <= 0 then
                            table.insert(saleData.expired, auctionData)
                        else
                            table.insert(saleData.active, auctionData)
                            saleData.totalActive = saleData.totalActive + (info.buyoutAmount or info.bidAmount or 0)
                        end
                    end
                end
            end
        -- For Legacy AH (Classic)
        elseif GetNumAuctionItems then
            for index = 1, GetNumAuctionItems("owner") do
                local info = { GetAuctionItemInfo("owner", index) }
                local itemLink = GetAuctionItemLink("owner", index)
                local timeLeft = GetAuctionItemTimeLeft("owner", index)
                
                if info and itemLink then
                    local saleStatus = info[Auctionator.Constants.AuctionItemInfo.SaleStatus] or 0
                    local buyout = info[Auctionator.Constants.AuctionItemInfo.Buyout] or 0
                    local bid = info[Auctionator.Constants.AuctionItemInfo.BidAmount] or 0
                    local quantity = info[Auctionator.Constants.AuctionItemInfo.Quantity] or 1
                    
                    local auctionData = {
                        itemID = info[Auctionator.Constants.AuctionItemInfo.ItemID],
                        itemLink = itemLink,
                        quantity = quantity,
                        buyoutAmount = buyout,
                        bidAmount = bid,
                        timeLeft = timeLeft,
                        status = saleStatus
                    }
                    
                    if saleStatus == 1 then -- Sold
                        table.insert(saleData.sold, auctionData)
                        saleData.totalSales = saleData.totalSales + (buyout > 0 and buyout or bid)
                    else -- Active or expired
                        if timeLeft <= 0 then
                            table.insert(saleData.expired, auctionData)
                        else
                            table.insert(saleData.active, auctionData)
                            saleData.totalActive = saleData.totalActive + (buyout > 0 and buyout or bid)
                        end
                    end
                end
            end
        end
    end)
    
    -- Calculate total value
    saleData.totalValue = saleData.totalSales + saleData.totalActive
    
    return saleData
end

-- Get sale statistics for specific items from our database
        function AuctionatorInterface:GetItemSaleStats(itemID)
    local stats = {
        itemID = itemID,
        sold = 0,
        active = 0,
        expired = 0,
        totalSalesValue = 0,
        totalActiveValue = 0,
        averageSalePrice = 0,
        lastSaleTime = 0,
        error = nil
    }
    
    if not self:IsAuctionatorAvailable() then
        stats.error = "Auctionator not available"
        return stats
    end
    
    local saleData = self:GetAuctionSaleData()
    if saleData.error then
        stats.error = saleData.error
        return stats
    end
    
    -- Count sales for this specific item
    local salesCount = 0
    local salesValue = 0
    
    for _, auction in ipairs(saleData.sold) do
        if auction.itemID == itemID then
            stats.sold = stats.sold + auction.quantity
            local salePrice = auction.buyoutAmount or auction.bidAmount or 0
            salesValue = salesValue + salePrice
            salesCount = salesCount + 1
        end
    end
    
    -- Count active auctions for this item
    for _, auction in ipairs(saleData.active) do
        if auction.itemID == itemID then
            stats.active = stats.active + auction.quantity
            stats.totalActiveValue = stats.totalActiveValue + (auction.buyoutAmount or auction.bidAmount or 0)
        end
    end
    
    -- Count expired auctions for this item
    for _, auction in ipairs(saleData.expired) do
        if auction.itemID == itemID then
            stats.expired = stats.expired + auction.quantity
        end
    end
    
    -- Calculate averages
    stats.totalSalesValue = salesValue
    if salesCount > 0 then
        stats.averageSalePrice = salesValue / salesCount
    end
    
    return stats
end

-- Check if we should recommend this item based on sale success
        function AuctionatorInterface:GetSaleSuccessRate(itemID)
    local stats = self:GetItemSaleStats(itemID)
    
    if stats.error then
        return 0, stats.error
    end
    
    local totalAttempts = stats.sold + stats.active + stats.expired
    if totalAttempts == 0 then
        return 1, "No auction history - assuming good" -- No data, assume it's fine
    end
    
    local successRate = stats.sold / totalAttempts
    local message = string.format("%.1f%% success rate (%d sold, %d active, %d expired)", 
        successRate * 100, stats.sold, stats.active, stats.expired)
    
    return successRate, message
end

-- Monitor auction performance for recommendations
        function AuctionatorInterface:GenerateAuctionReport()
    local report = {
        timestamp = time(),
        overview = {},
        byItem = {},
        recommendations = {},
        warnings = {}
    }
    
    local saleData = self:GetAuctionSaleData()
    if saleData.error then
        table.insert(report.warnings, saleData.error)
        return report
    end
    
    -- Overall statistics
    report.overview = {
        totalSold = #saleData.sold,
        totalActive = #saleData.active,
        totalExpired = #saleData.expired,
        totalSalesValue = saleData.totalSales,
        totalActiveValue = saleData.totalActive,
        averageSaleValue = #saleData.sold > 0 and (saleData.totalSales / #saleData.sold) or 0
    }
    
    -- Per-item analysis for items in our database
    if IronPawProfit.Database then
        for itemID, itemData in pairs(IronPawProfit.Database) do
            local stats = self:GetItemSaleStats(itemID)
            local successRate, message = self:GetSaleSuccessRate(itemID)
            
            report.byItem[itemID] = {
                name = itemData.name,
                stats = stats,
                successRate = successRate,
                message = message,
                profitPerToken = itemData.profitPerToken or 0
            }
            
            -- Generate recommendations based on success rate
            if successRate < 0.5 and stats.sold > 0 then
                table.insert(report.recommendations, {
                    type = "warning",
                    itemName = itemData.name,
                    message = string.format("%s has low success rate (%.1f%%) - consider avoiding", 
                        itemData.name, successRate * 100)
                })
            elseif successRate > 0.8 and stats.sold > 2 then
                table.insert(report.recommendations, {
                    type = "positive",
                    itemName = itemData.name,
                    message = string.format("%s has high success rate (%.1f%%) - good choice", 
                        itemData.name, successRate * 100)
                })
            end
        end
    end
    
    return report
end

    return true
end
