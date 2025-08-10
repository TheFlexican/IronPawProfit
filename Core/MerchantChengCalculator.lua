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
            -- Removed debug print
            return recommendations
        end
        
        -- Get container cost from Merchant Cheng
        local containerCost = self:GetContainerCost()
        -- Removed debug print
        
        -- Step 1: Calculate all possible token generation costs
        local tokenGenerationCosts = {}
        local itemsProcessed = 0
        local itemsWithMaterialID = 0
        local itemsWithMarketData = 0
        local itemsWithPrice = 0
        local maxAHQty = 10000
        if IronPawProfit.db and IronPawProfit.db.profile and IronPawProfit.db.profile.maxAHQty then
            maxAHQty = IronPawProfit.db.profile.maxAHQty
        end
        -- Extract all raw materials from the Nam Ironpaw database for token generation
        for itemID, itemData in pairs(IronPawProfit.Database) do
            itemsProcessed = itemsProcessed + 1
            if itemData.materialID then
                itemsWithMaterialID = itemsWithMaterialID + 1
                if itemData.marketAvailable then
                    itemsWithMarketData = itemsWithMarketData + 1
                    local materialID = itemData.materialID
                    local materialName = self:GetRawMaterialName(materialID, itemData.name)
                    local marketPrice = self:GetRawMaterialPrice(materialID)
                    local ahQuantity = self:GetMaterialMarketDepth(materialID)
                    if marketPrice and marketPrice > 0 then
                        itemsWithPrice = itemsWithPrice + 1
                        local materialsPerContainer = MaterialQuantities[materialID] or 25
                        local totalMaterialCost = marketPrice * materialsPerContainer
                        local totalCostPerToken = totalMaterialCost + containerCost
                        -- Only include if AH quantity is below threshold
                        if ahQuantity <= maxAHQty then
                            table.insert(tokenGenerationCosts, {
                                materialID = materialID,
                                materialName = materialName,
                                originalSackName = itemData.name,
                                category = itemData.category,
                                materialPrice = marketPrice,
                                materialsNeeded = materialsPerContainer,
                                containerCost = containerCost,
                                totalCostPerToken = totalCostPerToken,
                                marketDepth = ahQuantity,
                                ahQuantity = ahQuantity,
                                competitionLevel = self:GetMaterialCompetitionLevel(materialID)
                            })
                        end
                    end
                end
            end
        end
        
        -- Step 2: Find the most profitable sacks from Nam Ironpaw to buy with tokens
        local profitableSacks = {}
        for itemID, itemData in pairs(IronPawProfit.Database) do
            if itemData.marketAvailable and itemData.marketPrice > 0 then
                local sackValue = itemData.marketPrice
                local tokenCost = itemData.tokenCost or 1
                local profitPerToken = sackValue / tokenCost
                table.insert(profitableSacks, {
                    itemID = itemID,
                    sackName = itemData.name,
                    category = itemData.category,
                    sackValue = sackValue,
                    tokenCost = tokenCost,
                    profitPerToken = profitPerToken
                })
            end
        end
        
        -- Sort sacks by profit per token (highest first) - these are the best to buy
        table.sort(profitableSacks, function(a, b) return a.profitPerToken > b.profitPerToken end)
        
        -- Sort token generation methods by cost (lowest first) - these are the cheapest to make
        table.sort(tokenGenerationCosts, function(a, b) return a.totalCostPerToken < b.totalCostPerToken end)
        
        -- Removed debug print summary
        
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
            -- Ensure materialName is always set for display
            if not opportunity.materialName or opportunity.materialName == "Unknown" then
                local itemName = GetItemInfo(opportunity.materialID)
                opportunity.materialName = itemName or ("Material " .. opportunity.materialID)
            end
            table.insert(recommendations, opportunity)
        end
        
        -- Debug summary
        -- Removed debug print summary
        
        -- Sort by net profit (highest profit first)
        table.sort(recommendations, function(a, b)
            return a.netProfit > b.netProfit
        end)
        
        -- Removed debug print summary
        
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
        -- ...existing code...
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
            return nil
        end
        local marketPrice, serverMedian, available = IronPawProfit.AuctionatorInterface:GetMarketPrice(materialID)
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

        local recommendations = self:GenerateRawMaterialCostComparison()
        table.sort(recommendations, function(a, b) return a.totalCostPerToken < b.totalCostPerToken end)
        report.recommendations = recommendations
        report.summary = {
            totalMaterials = #recommendations,
            cheapestMaterial = (#recommendations > 0) and recommendations[1].materialName or "None",
            cheapestCost = (#recommendations > 0) and recommendations[1].totalCostPerToken or 0,
            mostExpensiveMaterial = (#recommendations > 0) and recommendations[#recommendations].materialName or "None",
            mostExpensiveCost = (#recommendations > 0) and recommendations[#recommendations].totalCostPerToken or 0,
            averageCost = self:CalculateAverageCost(recommendations)
        }
        return report
    end

    -- Generate cost comparison for all raw materials (not arbitrage)
    function MerchantChengCalculator:GenerateRawMaterialCostComparison()
        local recommendations = {}
        
        -- Get all Nam Ironpaw sacks to find their corresponding raw materials
        local database = IronPawProfit.Database or {}
        if not database or next(database) == nil then
            return {}
        end
        local maxAHQty = 10000
        if IronPawProfit.db and IronPawProfit.db.profile and IronPawProfit.db.profile.maxAHQty then
            maxAHQty = IronPawProfit.db.profile.maxAHQty
        end
        for itemID, itemData in pairs(database) do
            if itemData.materialID then
                local materialID = itemData.materialID
                local materialPrice = self:GetRawMaterialPrice(materialID)
                local ahQuantity = self:GetMaterialMarketDepth(materialID)
                if materialPrice and materialPrice > 0 and ahQuantity <= maxAHQty then
                    local quantity = MaterialQuantities[materialID] or 25
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
                        marketDepth = ahQuantity,
                        ahQuantity = ahQuantity,
                        competitionLevel = self:GetMaterialCompetitionLevel(materialID) or 0
                    })
                end
            end
        end
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
        -- ...existing code...
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
