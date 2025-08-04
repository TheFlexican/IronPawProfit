-- MerchantChengCalculator.lua
-- Calculates optimal raw material purchases to generate Iron Paw tokens via Merchant Cheng containers

local addonName, addon = ...

-- Create global MerchantChengCalculator module
IronPawProfitMerchantChengCalculator = {}

-- Initialize the module
function IronPawProfitMerchantChengCalculator:Initialize(mainAddon)
    self.addon = mainAddon
    
    -- Add MerchantChengCalculator functions to main addon
    self.addon.MerchantChengCalculator = {}
    local MerchantChengCalculator = self.addon.MerchantChengCalculator

    --[[
        Calculate cost per token for raw materials that can be used with Merchant Cheng containers
        
        The system works as:
        1. Buy raw materials from auction house
        2. Purchase containers from Merchant Cheng  
        3. Fill containers with raw materials
        4. Turn in filled containers to get 1 Ironpaw token each
        
        Args:
            None
            
        Returns:
            table: Array of raw material recommendations sorted by cost per token
    ]]--
    
    -- Lookup table for exact material quantities needed per container
    -- Based on official Bundle of Groceries requirements from Wowhead
    local MaterialQuantities = {
        -- Fish (mostly 20, Golden Carp is 60)
        [74856] = 20, -- Jade Lungfish
        [74857] = 20, -- Giant Mantis Shrimp  
        [74859] = 20, -- Emperor Salmon
        [74860] = 20, -- Redbelly Mandarin
        [74861] = 20, -- Tiger Gourami
        [74863] = 20, -- Jewel Danio
        [74864] = 20, -- Reef Octopus
        [74865] = 20, -- Krasarang Paddlefish
        [74866] = 60, -- Golden Carp (special case)
        [75014] = 20, -- Crocolisk Belly (actually meat but listed with fish)
        
        -- Meat (all 20)
        [74833] = 20, -- Raw Tiger Steak
        [74834] = 20, -- Mushan Ribs
        [74837] = 20, -- Raw Turtle Meat
        [74838] = 20, -- Raw Crab Meat
        [74839] = 20, -- Wildfowl Breast
        
        -- Vegetables (all 100)
        [74840] = 100, -- Green Cabbage
        [74841] = 100, -- Juicycrunch Carrot
        [74842] = 100, -- Mogu Pumpkin
        [74843] = 100, -- Scallions
        [74844] = 100, -- Red Blossom Leek
        [74846] = 100, -- Witchberries
        [74847] = 100, -- Jade Squash
        [74848] = 100, -- Striped Melon
        [74849] = 100, -- Pink Turnip
        [74850] = 100, -- White Turnip
    }
    
    function MerchantChengCalculator:CalculateRawMaterialCosts()
        local recommendations = {}
        
        -- Safety check: ensure Database exists
        if not IronPawProfit.Database then
            IronPawProfit:Print("DEBUG CHENG: Database not available")
            return recommendations
        end
        
        -- Get container cost from Merchant Cheng
        local containerCost = self:GetContainerCost()
        IronPawProfit:Print("DEBUG CHENG: Container cost = " .. IronPawProfit:FormatMoney(containerCost))
        
        -- Step 1: Calculate all possible token generation costs
        local tokenGenerationCosts = {}
        local itemsProcessed = 0
        local itemsWithMaterialID = 0
        local itemsWithMarketData = 0
        local itemsWithPrice = 0
        
        -- Extract all raw materials from the Nam Ironpaw database for token generation
        for itemID, itemData in pairs(IronPawProfit.Database) do
            itemsProcessed = itemsProcessed + 1
            -- Only process items that have materialID (sacks with raw materials)
            if itemData.materialID then
                itemsWithMaterialID = itemsWithMaterialID + 1
                IronPawProfit:Print("DEBUG CHENG: Processing " .. (itemData.name or "Unknown") .. " -> material ID " .. itemData.materialID)
                
                if itemData.marketAvailable then
                    itemsWithMarketData = itemsWithMarketData + 1
                    local materialID = itemData.materialID
                    local materialName = self:GetRawMaterialName(materialID, itemData.name)
                    
                    -- Get market price for the raw material
                    local marketPrice = self:GetRawMaterialPrice(materialID)
                    IronPawProfit:Print("DEBUG CHENG: Material " .. materialName .. " price = " .. (marketPrice and IronPawProfit:FormatMoney(marketPrice) or "nil"))
                    
                    if marketPrice and marketPrice > 0 then
                        itemsWithPrice = itemsWithPrice + 1
                        -- Calculate cost per token using correct material quantities
                        local materialsPerContainer = MaterialQuantities[materialID] or 25 -- Fallback to 25 if not found
                        local totalMaterialCost = marketPrice * materialsPerContainer
                        local totalCostPerToken = totalMaterialCost + containerCost
                        
                        table.insert(tokenGenerationCosts, {
                            materialID = materialID,
                            materialName = materialName,
                            originalSackName = itemData.name,
                            category = itemData.category,
                            materialPrice = marketPrice,
                            materialsNeeded = materialsPerContainer,
                            containerCost = containerCost,
                            totalCostPerToken = totalCostPerToken,
                            -- Market analysis data
                            marketDepth = self:GetMaterialMarketDepth(materialID),
                            competitionLevel = self:GetMaterialCompetitionLevel(materialID)
                        })
                        
                        IronPawProfit:Print("DEBUG CHENG: Token generation cost for " .. materialName .. ":")
                        IronPawProfit:Print("  - Materials needed: " .. materialsPerContainer .. " x " .. IronPawProfit:FormatMoney(marketPrice))
                        IronPawProfit:Print("  - Total cost per token: " .. IronPawProfit:FormatMoney(totalCostPerToken))
                    else
                        IronPawProfit:Print("DEBUG CHENG: " .. materialName .. " has no market price")
                    end
                else
                    IronPawProfit:Print("DEBUG CHENG: " .. (itemData.name or "Unknown") .. " not market available")
                end
            end
        end
        
        -- Step 2: Find the most profitable sacks from Nam Ironpaw to buy with tokens
        local profitableSacks = {}
        for itemID, itemData in pairs(IronPawProfit.Database) do
            if itemData.marketAvailable and itemData.marketPrice > 0 then
                local sackValue = itemData.marketPrice -- Value if we sell the sack
                local tokenCost = itemData.tokenCost or 1 -- Cost in tokens to buy this sack
                local profitPerToken = sackValue / tokenCost
                
                table.insert(profitableSacks, {
                    itemID = itemID,
                    sackName = itemData.name,
                    category = itemData.category,
                    sackValue = sackValue,
                    tokenCost = tokenCost,
                    profitPerToken = profitPerToken
                })
                
                IronPawProfit:Print("DEBUG CHENG: Nam Ironpaw sack value - " .. itemData.name .. ": " .. IronPawProfit:FormatMoney(sackValue) .. " per " .. tokenCost .. " token(s)")
            end
        end
        
        -- Sort sacks by profit per token (highest first) - these are the best to buy
        table.sort(profitableSacks, function(a, b) return a.profitPerToken > b.profitPerToken end)
        
        -- Sort token generation methods by cost (lowest first) - these are the cheapest to make
        table.sort(tokenGenerationCosts, function(a, b) return a.totalCostPerToken < b.totalCostPerToken end)
        
        IronPawProfit:Print("DEBUG CHENG: Best Nam Ironpaw purchases:")
        for i = 1, math.min(3, #profitableSacks) do
            local sack = profitableSacks[i]
            IronPawProfit:Print("  " .. i .. ". " .. sack.sackName .. " = " .. IronPawProfit:FormatMoney(sack.profitPerToken) .. " per token")
        end
        
        IronPawProfit:Print("DEBUG CHENG: Cheapest token generation methods:")
        for i = 1, math.min(3, #tokenGenerationCosts) do
            local method = tokenGenerationCosts[i]
            IronPawProfit:Print("  " .. i .. ". " .. method.materialName .. " = " .. IronPawProfit:FormatMoney(method.totalCostPerToken) .. " per token")
        end
        
        -- Step 3: Calculate arbitrage opportunities
        -- Show the best arbitrage opportunity for each material (diversified recommendations)
        local materialOpportunities = {}
        
        for _, tokenMethod in ipairs(tokenGenerationCosts) do
            -- Find the best arbitrage opportunity for this material
            local bestOpportunity = nil
            local bestProfit = 0
            
            for _, targetSack in ipairs(profitableSacks) do
                local arbitrageProfit = targetSack.profitPerToken - tokenMethod.totalCostPerToken
                if arbitrageProfit > bestProfit then
                    bestProfit = arbitrageProfit
                    bestOpportunity = {
                        -- Token generation data
                        materialID = tokenMethod.materialID,
                        materialName = tokenMethod.materialName,
                        originalSackName = tokenMethod.originalSackName,
                        category = tokenMethod.category,
                        materialPrice = tokenMethod.materialPrice,
                        materialsNeeded = tokenMethod.materialsNeeded,
                        containerCost = tokenMethod.containerCost,
                        totalCostPerToken = tokenMethod.totalCostPerToken,
                        
                        -- Target purchase data
                        targetSackID = targetSack.itemID,
                        targetSackName = targetSack.sackName,
                        targetSackValue = targetSack.profitPerToken,
                        targetTokenCost = targetSack.tokenCost,
                        
                        -- Arbitrage calculation
                        netProfit = arbitrageProfit,
                        profitMargin = (tokenMethod.totalCostPerToken > 0) and (arbitrageProfit / tokenMethod.totalCostPerToken) * 100 or 0,
                        
                        -- Market analysis data
                        marketDepth = tokenMethod.marketDepth,
                        competitionLevel = tokenMethod.competitionLevel,
                        recommendationScore = self:CalculateMaterialScore(tokenMethod.materialID, arbitrageProfit, tokenMethod.totalCostPerToken)
                    }
                end
            end
            
            -- Store the best opportunity for this material
            if bestOpportunity and bestProfit > 0 then
                materialOpportunities[tokenMethod.materialID] = bestOpportunity
            end
        end
        
        -- Convert to array and add to recommendations
        for materialID, opportunity in pairs(materialOpportunities) do
            table.insert(recommendations, opportunity)
            
            IronPawProfit:Print("DEBUG CHENG: ARBITRAGE OPPORTUNITY:")
            IronPawProfit:Print("  - Generate token: " .. opportunity.materialName .. " (" .. IronPawProfit:FormatMoney(opportunity.totalCostPerToken) .. ")")
            IronPawProfit:Print("  - Buy sack: " .. opportunity.targetSackName .. " (" .. IronPawProfit:FormatMoney(opportunity.targetSackValue) .. ")")
            IronPawProfit:Print("  - Arbitrage profit: " .. IronPawProfit:FormatMoney(opportunity.netProfit) .. " per token")
        end
        
        -- Debug summary
        IronPawProfit:Print("DEBUG CHENG: Summary - Processed: " .. itemsProcessed .. " items")
        IronPawProfit:Print("DEBUG CHENG: Items with materialID: " .. itemsWithMaterialID)
        IronPawProfit:Print("DEBUG CHENG: Items with market data: " .. itemsWithMarketData)
        IronPawProfit:Print("DEBUG CHENG: Items with price: " .. itemsWithPrice)
        IronPawProfit:Print("DEBUG CHENG: Total recommendations: " .. #recommendations)
        
        -- Sort by net profit (highest profit first)
        table.sort(recommendations, function(a, b)
            return a.netProfit > b.netProfit
        end)
        
        local profitableCount = 0
        for _, rec in ipairs(recommendations) do
            if rec.netProfit > 0 then
                profitableCount = profitableCount + 1
            end
        end
        IronPawProfit:Print("DEBUG CHENG: Profitable recommendations: " .. profitableCount)
        
        return recommendations
    end

    --[[
        Get readable name for raw material based on sack name
        
        Args:
            materialID (number): Item ID of the raw material
            sackName (string): Name of the sack containing this material
            
        Returns:
            string: Human-readable name for the raw material
    ]] --
    function MerchantChengCalculator:GetRawMaterialName(materialID, sackName)
        -- Try to get actual item name from game
        local itemName = GetItemInfo(materialID)
        if itemName then
            return itemName
        end

        -- Fallback: derive from sack name
        local materialName = sackName:gsub("Sack of ", ""):gsub("s$", "") -- Remove "Sack of" and trailing "s"
        return materialName .. " (ID: " .. materialID .. ")"
    end

    --[[
        Get market price for a raw material using Auctionator
        
        Args:
            materialID (number): Item ID of the raw material
            
        Returns:
            number: Market price per item in copper, or nil if not available
    ]] --
    function MerchantChengCalculator:GetRawMaterialPrice(materialID)
        if not IronPawProfit.AuctionatorInterface:IsAuctionatorAvailable() then
            IronPawProfit:Print("DEBUG CHENG: Auctionator not available for material " .. materialID)
            return nil
        end

        local marketPrice, serverMedian, available = IronPawProfit.AuctionatorInterface:GetMarketPrice(materialID)

        IronPawProfit:Print("DEBUG CHENG: Material " .. materialID .. " - marketPrice=" .. (marketPrice or "nil") ..
                                ", serverMedian=" .. (serverMedian or "nil") .. ", available=" .. tostring(available))

        if available and (marketPrice or serverMedian) then
            return marketPrice or serverMedian
        end

        return nil
    end

    --[[
        Get market depth information for a raw material
        
        Args:
            materialID (number): Item ID of the raw material
            
        Returns:
            number: Number of current auction listings
    ]] --
    function MerchantChengCalculator:GetMaterialMarketDepth(materialID)
        if not IronPawProfit.AuctionatorInterface:IsAuctionatorAvailable() then
            return 0
        end

        local marketData = IronPawProfit.AuctionatorInterface:GetDetailedData(materialID)
        return marketData.marketDepth or 0
    end

    --[[
        Get competition level for a raw material
        
        Args:
            materialID (number): Item ID of the raw material
            
        Returns:
            string: Competition level ("low", "medium", "high", "very_high")
    ]] --
    function MerchantChengCalculator:GetMaterialCompetitionLevel(materialID)
        if not IronPawProfit.AuctionatorInterface:IsAuctionatorAvailable() then
            return "unknown"
        end

        local marketData = IronPawProfit.AuctionatorInterface:GetDetailedData(materialID)
        return marketData.competitionLevel or "unknown"
    end

    --[[
        Calculate recommendation score for a raw material
        
        Args:
            materialID (number): Item ID of the raw material
            netProfit (number): Net profit after all costs
            totalCost (number): Total cost to generate one token
            
        Returns:
            number: Recommendation score (0-100)
    ]] --
    function MerchantChengCalculator:CalculateMaterialScore(materialID, netProfit, totalCost)
        if not IronPawProfit.AuctionatorInterface:IsAuctionatorAvailable() then
            return 50 -- Neutral score without market data
        end

        local score = 50 -- Base score

        -- Profit factor (up to +30 points for very profitable, -30 for unprofitable)
        if netProfit > 0 then
            local profitRatio = netProfit / totalCost
            score = score + math.min(30, profitRatio * 100)
        else
            score = score - 30 -- Penalty for unprofitable materials
        end

        -- Market depth factor
        local marketDepth = self:GetMaterialMarketDepth(materialID)
        if marketDepth == 0 then
            score = score + 10 -- Bonus for no competition
        elseif marketDepth <= 5 then
            score = score + 5 -- Small bonus for low competition
        elseif marketDepth > 20 then
            score = score - 15 -- Penalty for high competition
        end

        -- Competition level factor
        local competitionLevel = self:GetMaterialCompetitionLevel(materialID)
        if competitionLevel == "low" then
            score = score + 15
        elseif competitionLevel == "medium" then
            score = score + 5
        elseif competitionLevel == "high" then
            score = score - 10
        elseif competitionLevel == "very_high" then
            score = score - 20
        end

        return math.max(0, math.min(100, score))
    end

    --[[
        Calculate optimal raw material purchases for token generation
        
        Args:
            availableGold (number): Available gold to spend (in copper)
            targetTokens (number): Number of tokens wanted to generate
            
        Returns:
            table: Recommendations with quantities
            number: Total gold needed
            number: Total tokens that can be generated
    ]] --
    function MerchantChengCalculator:CalculateOptimalRawMaterialPurchases(availableGold, targetTokens)
        local recommendations = self:CalculateRawMaterialCosts()
        local purchases = {}
        local totalGoldNeeded = 0
        local tokensGenerated = 0

        targetTokens = targetTokens or math.huge -- Default to unlimited if not specified

        -- Sort by profitability (best net profit first)
        for _, rec in ipairs(recommendations) do
            if rec.netProfit > 0 and tokensGenerated < targetTokens then
                -- Calculate how many tokens we can afford to make with this material
                local tokensAffordable = math.floor(availableGold / rec.totalCostPerToken)
                local tokensToMake = math.min(tokensAffordable, targetTokens - tokensGenerated)

                if tokensToMake > 0 then
                    local totalCost = tokensToMake * rec.totalCostPerToken
                    local materialsNeeded = tokensToMake * rec.materialsNeeded
                    local containersNeeded = tokensToMake

                    table.insert(purchases, {
                        materialID = rec.materialID,
                        materialName = rec.materialName,
                        category = rec.category,
                        tokensToGenerate = tokensToMake,
                        materialsNeeded = materialsNeeded,
                        containersNeeded = containersNeeded,
                        materialCost = materialsNeeded * rec.materialPrice,
                        containerCost = containersNeeded * rec.containerCost,
                        totalCost = totalCost,
                        expectedProfit = tokensToMake * rec.namIronpawProfit,
                        netProfit = tokensToMake * rec.netProfit,
                        costPerToken = rec.totalCostPerToken,
                        profitPerToken = rec.netProfit
                    })

                    availableGold = availableGold - totalCost
                    totalGoldNeeded = totalGoldNeeded + totalCost
                    tokensGenerated = tokensGenerated + tokensToMake
                end
            end
        end

        return purchases, totalGoldNeeded, tokensGenerated
    end

    --[[
        Generate a detailed report about raw material opportunities
        
        Returns:
            table: Comprehensive report with recommendations and analysis
    ]] --
    function MerchantChengCalculator:GenerateRawMaterialReport()
        local report = {
            timestamp = time(),
            recommendations = {},
            summary = {},
            warnings = {},
            profitable = {},
            unprofitable = {}
        }

        IronPawProfit:Print("DEBUG CHENG: Starting raw material cost comparison")
        local recommendations = self:GenerateRawMaterialCostComparison()

        -- Sort by cost per token (lowest first)
        table.sort(recommendations, function(a, b) return a.totalCostPerToken < b.totalCostPerToken end)

        report.recommendations = recommendations

        -- Generate summary
        report.summary = {
            totalMaterials = #recommendations,
            cheapestMaterial = (#recommendations > 0) and recommendations[1].materialName or "None",
            cheapestCost = (#recommendations > 0) and recommendations[1].totalCostPerToken or 0,
            mostExpensiveMaterial = (#recommendations > 0) and recommendations[#recommendations].materialName or "None",
            mostExpensiveCost = (#recommendations > 0) and recommendations[#recommendations].totalCostPerToken or 0,
            averageCost = self:CalculateAverageCost(recommendations)
        }

        IronPawProfit:Print("DEBUG CHENG: Raw material comparison complete - " .. #recommendations .. " materials analyzed")
        
        return report
    end

    -- Generate cost comparison for all raw materials (not arbitrage)
    function MerchantChengCalculator:GenerateRawMaterialCostComparison()
        local recommendations = {}
        
        IronPawProfit:Print("DEBUG CHENG: Generating raw material cost comparison")
        
        -- Get all Nam Ironpaw sacks to find their corresponding raw materials
        local database = IronPawProfit.Database or {}
        if not database or next(database) == nil then
            IronPawProfit:Print("DEBUG CHENG: ERROR - Database not available or empty")
            return {}
        end
        
        IronPawProfit:Print("DEBUG CHENG: Found database with items available")
        
        for itemID, itemData in pairs(database) do
            if itemData.materialID then
                local materialID = itemData.materialID
                local materialPrice = self:GetRawMaterialPrice(materialID)
                
                if materialPrice and materialPrice > 0 then
                    local quantity = MaterialQuantities[materialID] or 25 -- Fallback to 25 if not found
                    local materialCost = materialPrice * quantity
                    local containerCost = self:GetContainerCost()
                    local totalCostPerToken = materialCost + containerCost
                    
                    table.insert(recommendations, {
                        materialID = materialID,
                        materialName = GetItemInfo(materialID) or ("Material " .. materialID),
                        category = itemData.category or "Unknown",
                        materialPrice = materialPrice,
                        materialsNeeded = quantity,
                        containerCost = containerCost,
                        totalCostPerToken = totalCostPerToken,
                        originalSackName = itemData.name,
                        marketDepth = self:GetMaterialMarketDepth(materialID) or 0,
                        competitionLevel = self:GetMaterialCompetitionLevel(materialID) or 0
                    })
                    
                    IronPawProfit:Print("DEBUG CHENG: " .. (GetItemInfo(materialID) or ("Material " .. materialID)) .. " - " .. 
                        quantity .. " needed @ " .. IronPawProfit:FormatMoney(materialPrice) .. 
                        " = " .. IronPawProfit:FormatMoney(totalCostPerToken) .. " per token")
                end
            end
        end
        
        IronPawProfit:Print("DEBUG CHENG: Raw material cost analysis complete - " .. #recommendations .. " materials")
        return recommendations
    end

    -- Calculate average cost for materials
    function MerchantChengCalculator:CalculateAverageCost(materials)
        if #materials == 0 then return 0 end
        
        local totalCost = 0
        for _, material in ipairs(materials) do
            totalCost = totalCost + (material.totalCostPerToken or 0)
        end
        
        return totalCost / #materials
    end

    --[[
        Calculate average profit for profitable materials
        
        Args:
            profitableItems (table): Array of profitable material recommendations
            
        Returns:
            number: Average profit per token in copper
    ]] --
    function MerchantChengCalculator:CalculateAverageProfit(profitableItems)
        report.summary = {
            totalMaterials = #recommendations,
            profitableMaterials = #report.profitable,
            unprofitableMaterials = #report.unprofitable,
            bestProfitPerToken = (#report.profitable > 0) and report.profitable[1].netProfit or 0,
            bestMaterial = (#report.profitable > 0) and report.profitable[1].materialName or "None",
            averageProfit = self:CalculateAverageProfit(report.profitable)
        }

        IronPawProfit:Print(
            "DEBUG CHENG: Report summary - Total: " .. report.summary.totalMaterials .. ", Profitable: " ..
                report.summary.profitableMaterials .. ", Unprofitable: " .. report.summary.unprofitableMaterials)

        -- Generate warnings
        if not IronPawProfit.AuctionatorInterface:IsAuctionatorAvailable() then
            table.insert(report.warnings, "Auctionator not available - raw material prices unavailable")
        end

        if #report.profitable == 0 then
            table.insert(report.warnings, "No profitable raw materials found - container costs may be too high")
        end

        if report.summary.averageProfit < 10000 then -- Less than 1 gold average profit
            table.insert(report.warnings, "Low profit margins - consider manual token acquisition instead")
        end

        return report
    end

    --[[
        Calculate average profit for profitable materials
        
        Args:
            profitableItems (table): Array of profitable material recommendations
            
        Returns:
            number: Average profit per token in copper
    ]] --
    function MerchantChengCalculator:CalculateAverageProfit(profitableItems)
        if #profitableItems == 0 then
            return 0
        end

        local totalProfit = 0
        for _, item in ipairs(profitableItems) do
            totalProfit = totalProfit + item.netProfit
        end

        return totalProfit / #profitableItems
    end

    --[[
        Update container cost from Merchant Cheng
        This should be called when the actual container cost is determined
        
        Args:
            newCost (number): Cost per container in copper
    ]] --
    function MerchantChengCalculator:UpdateContainerCost(newCost)
        -- Store in addon configuration
        if IronPawProfit.db and IronPawProfit.db.profile then
            IronPawProfit.db.profile.merchantChengContainerCost = newCost
        end
    end

    --[[
        Get current container cost (with fallback to default)
        
        Returns:
            number: Container cost in copper
    ]]--
    function MerchantChengCalculator:GetContainerCost()
        if IronPawProfit.db and IronPawProfit.db.profile and IronPawProfit.db.profile.merchantChengContainerCost then
            return IronPawProfit.db.profile.merchantChengContainerCost
        end

        return 13500 -- Default: 1.35 gold per container
    end

    return true
end
