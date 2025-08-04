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
    function MerchantChengCalculator:CalculateRawMaterialCosts()
        local recommendations = {}
        
        -- Safety check: ensure Database exists
        if not IronPawProfit.Database then
            return recommendations
        end
        
        -- Get container cost from Merchant Cheng
        local containerCost = self:GetContainerCost()
        
        -- Extract all raw materials from the Nam Ironpaw database
        for itemID, itemData in pairs(IronPawProfit.Database) do
            -- Only process items that have materialID (sacks with raw materials)
            if itemData.materialID and itemData.marketAvailable then
                local materialID = itemData.materialID
                local materialName = self:GetRawMaterialName(materialID, itemData.name)
                
                -- Get market price for the raw material
                local marketPrice = self:GetRawMaterialPrice(materialID)
                
                if marketPrice and marketPrice > 0 then
                    -- Calculate cost per token
                    -- We need enough raw materials to fill one container = 1 token
                    -- Assuming containers need same quantity as sacks (25 materials per container)
                    local materialsPerContainer = itemData.contains or 25
                    local totalMaterialCost = marketPrice * materialsPerContainer
                    local totalCostPerToken = totalMaterialCost + containerCost
                    
                    -- Calculate potential profit if we use the token to buy from Nam Ironpaw
                    local namIronpawProfit = itemData.profitPerToken or 0
                    local netProfit = namIronpawProfit - totalCostPerToken
                    
                    table.insert(recommendations, {
                        materialID = materialID,
                        materialName = materialName,
                        originalSackName = itemData.name,
                        category = itemData.category,
                        materialPrice = marketPrice,
                        materialsNeeded = materialsPerContainer,
                        containerCost = containerCost,
                        totalCostPerToken = totalCostPerToken,
                        namIronpawProfit = namIronpawProfit,
                        netProfit = netProfit,
                        profitMargin = (totalCostPerToken > 0) and (netProfit / totalCostPerToken) * 100 or 0,
                        -- Market analysis data
                        marketDepth = self:GetMaterialMarketDepth(materialID),
                        competitionLevel = self:GetMaterialCompetitionLevel(materialID),
                        recommendationScore = self:CalculateMaterialScore(materialID, netProfit, totalCostPerToken)
                    })
                end
            end
        end
        
        -- Sort by net profit (highest profit first)
        table.sort(recommendations, function(a, b)
            return a.netProfit > b.netProfit
        end)
        
        return recommendations
    end

    --[[
        Get readable name for raw material based on sack name
        
        Args:
            materialID (number): Item ID of the raw material
            sackName (string): Name of the sack containing this material
            
        Returns:
            string: Human-readable name for the raw material
    ]]--
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
    ]]--
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
    ]]--
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
    ]]--
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
    ]]--
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
    ]]--
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
    ]]--
    function MerchantChengCalculator:GenerateRawMaterialReport()
        local report = {
            timestamp = time(),
            recommendations = {},
            summary = {},
            warnings = {},
            profitable = {},
            unprofitable = {}
        }
        
        local recommendations = self:CalculateRawMaterialCosts()
        
        -- Separate profitable from unprofitable
        for _, rec in ipairs(recommendations) do
            if rec.netProfit > 0 then
                table.insert(report.profitable, rec)
            else
                table.insert(report.unprofitable, rec)
            end
        end
        
        report.recommendations = recommendations
        
        -- Generate summary
        report.summary = {
            totalMaterials = #recommendations,
            profitableMaterials = #report.profitable,
            unprofitableMaterials = #report.unprofitable,
            bestProfitPerToken = (#report.profitable > 0) and report.profitable[1].netProfit or 0,
            bestMaterial = (#report.profitable > 0) and report.profitable[1].materialName or "None",
            averageProfit = self:CalculateAverageProfit(report.profitable)
        }
        
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
    ]]--
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
    ]]--
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
