-- ProfitCalculator.lua
-- Calculates optimal purchases based on market prices and available tokens

local addonName, addon = ...

-- Create global ProfitCalculator module
IronPawProfitCalculator = {}

-- Initialize the module
function IronPawProfitCalculator:Initialize(mainAddon)
    self.addon = mainAddon
    
    -- Add ProfitCalculator functions to main addon
    self.addon.ProfitCalculator = {}
    local ProfitCalculator = self.addon.ProfitCalculator

    -- Calculate profit for a single item
    function ProfitCalculator:CalculateItemProfit(itemData)
        if not itemData or not itemData.marketPrice or itemData.marketPrice <= 0 then
            return 0, 0, 0 -- No profit if no market data
        end
        
        local tokenCost = itemData.tokenCost
        local stackSize = itemData.stackSize
        local marketPrice = itemData.marketPrice
        
        -- Calculate profit per token
        local profitPerToken = (marketPrice * stackSize) - 0 -- No gold cost, just tokens
        
        -- Calculate profit per stack
        local profitPerStack = marketPrice * stackSize
        
        -- Calculate profit margin as percentage
        local profitMargin = 100 -- Since we only pay tokens, margin is essentially 100% if profitable
        
        return profitPerToken, profitPerStack, profitMargin
    end

    -- Calculate optimal purchase recommendations
    function ProfitCalculator:CalculateOptimalPurchases(availableTokens, maxInvestment, minProfitThreshold)
        local recommendations = {}
        local totalProfitPotential = 0
        
        -- Safety check: ensure Database exists
        if not IronPawProfit.Database then
            return recommendations, totalProfitPotential, 0
        end
        
            -- First, calculate profits for all items
            for itemID, itemData in pairs(IronPawProfit.Database) do
                if itemData.marketAvailable and itemData.marketPrice > 0 then
                    local profitPerToken, profitPerStack, profitMargin = ProfitCalculator:CalculateItemProfit(itemData)
                    
                    -- Update item data
                    itemData.profitPerToken = profitPerToken
                    itemData.profitPerStack = profitPerStack
                    itemData.profitMargin = profitMargin
                    
                    -- Only consider profitable items above threshold
                    if profitPerToken >= (minProfitThreshold * 10000) then -- Convert gold to copper
                        table.insert(recommendations, {
                            itemData = itemData,
                            profitPerToken = profitPerToken,
                            profitPerStack = profitPerStack,
                            profitMargin = profitMargin,
                            priority = profitPerToken / itemData.tokenCost -- Efficiency ratio
                        })
                    end
                end
            end
    
            -- Sort by priority (profit per token efficiency)
            table.sort(recommendations, function(a, b) 
                return a.priority > b.priority 
            end)
            
            -- Apply maxRecommendationsPerItem limit from config
            local maxRecommendations = IronPawProfit:GetConfig("maxRecommendationsPerItem") or 999
            if #recommendations > maxRecommendations then
                local limitedRecs = {}
                for i = 1, math.min(maxRecommendations, #recommendations) do
                    table.insert(limitedRecs, recommendations[i])
                end
                recommendations = limitedRecs
            end
    
    -- Calculate recommended quantities using knapsack-like approach
    local tokensRemaining = availableTokens
    local goldInvested = 0
    
    for i, rec in ipairs(recommendations) do
        local item = rec.itemData
        local maxAffordableStacks = math.floor(tokensRemaining / item.tokenCost)
        
        if maxAffordableStacks > 0 then
            -- Calculate how many we should actually buy
            local recommendedStacks = maxAffordableStacks
            
            -- Apply investment limit if specified
            if maxInvestment and maxInvestment > 0 then
                local goldNeededForMax = 0 -- We don't spend gold, just tokens
                recommendedStacks = maxAffordableStacks -- Buy as many as we can afford with tokens
            end
            
            -- Apply market depth considerations (don't flood the market)
            recommendedStacks = math.min(recommendedStacks, 10) -- Cap at 10 stacks per item
            
            rec.recommendedStacks = recommendedStacks
            rec.tokensNeeded = recommendedStacks * item.tokenCost
            rec.totalProfit = recommendedStacks * rec.profitPerStack
            rec.totalValue = recommendedStacks * item.marketPrice * item.stackSize
            
            tokensRemaining = tokensRemaining - rec.tokensNeeded
            totalProfitPotential = totalProfitPotential + rec.totalProfit
            
            item.recommendedQuantity = recommendedStacks
        else
            rec.recommendedStacks = 0
            rec.tokensNeeded = 0
            rec.totalProfit = 0
            rec.totalValue = 0
        end
    end
    
    return recommendations, totalProfitPotential, tokensRemaining
end

-- Get market trend analysis
        function ProfitCalculator:AnalyzeMarketTrends(itemID)
            local trends = {
                direction = "stable", -- "rising", "falling", "stable"
                confidence = 0,
                recommendation = "hold",
                analysis = "Insufficient data for trend analysis"
            }
            
            if not IronPawProfit.AuctionatorInterface:IsAuctionatorAvailable() then
                return trends
            end
            
            -- Get price history
            local history = IronPawProfit.AuctionatorInterface:GetPriceHistory(itemID, 7)
            
            if #history >= 3 then
                -- Simple trend analysis
                local recent = history[1].price
                local old = history[#history].price
                local change = (recent - old) / old * 100
                
                if change > 10 then
                    trends.direction = "rising"
                    trends.recommendation = "buy"
                    trends.analysis = string.format("Price rising by %.1f%% over 7 days", change)
                elseif change < -10 then
                    trends.direction = "falling"
                    trends.recommendation = "wait"
                    trends.analysis = string.format("Price falling by %.1f%% over 7 days", math.abs(change))
                else
                    trends.direction = "stable"
                    trends.recommendation = "hold"
                    trends.analysis = string.format("Price stable (%.1f%% change over 7 days)", change)
        end
        
        trends.confidence = math.min(#history * 10, 100) -- Confidence based on data points
    end
    
    return trends
end

-- Calculate risk assessment for an investment
        function ProfitCalculator:CalculateRiskAssessment(itemData)
            local risk = {
                level = "medium", -- "low", "medium", "high"
                factors = {},
                score = 50, -- 0-100, lower is safer
                recommendation = "proceed with caution"
            }
            
            -- Check data quality
            local dataGood, reason, aucData = IronPawProfit.AuctionatorInterface:ValidateDataQuality(itemData.itemID)
            if not dataGood then
                risk.level = "high"
                risk.score = risk.score + 30
                table.insert(risk.factors, reason)
            end
            
            -- Check market volatility
            local trends = ProfitCalculator:AnalyzeMarketTrends(itemData.itemID)
            if trends.direction == "falling" then
                risk.score = risk.score + 20
                table.insert(risk.factors, "Price trend is falling")
            elseif trends.direction == "rising" then
                risk.score = risk.score - 10
                table.insert(risk.factors, "Price trend is rising")
            end
            
            -- Check profit margin
            if itemData.profitPerToken < 5000 then -- Less than 50 silver profit per token
                risk.score = risk.score + 15
                table.insert(risk.factors, "Low profit margin")
            end
            
            -- Determine final risk level
            if risk.score <= 30 then
                risk.level = "low"
                risk.recommendation = "safe investment"
            elseif risk.score <= 70 then
                risk.level = "medium" 
                risk.recommendation = "proceed with caution"
            else
                risk.level = "high"
                risk.recommendation = "high risk - consider avoiding"
            end
            
            return risk
end

-- Generate detailed investment report
        function ProfitCalculator:GenerateInvestmentReport(availableTokens)
            local report = {
                timestamp = time(),
                availableTokens = availableTokens,
                recommendations = {},
                summary = {},
                warnings = {}
            }
            
            -- Get configuration
            local minProfit = IronPawProfit.db.profile.minProfit or 1
            local maxInvestment = IronPawProfit.db.profile.maxInvestment or 1000
            
            -- Calculate optimal purchases
            local recommendations, totalProfit, tokensRemaining = ProfitCalculator:CalculateOptimalPurchases(
                availableTokens, maxInvestment, minProfit)
            
            report.recommendations = recommendations
            report.tokensRemaining = tokensRemaining
            
            -- Generate summary
            report.summary = {
                totalRecommendations = #recommendations,
                totalTokensToSpend = availableTokens - tokensRemaining,
                totalProfitPotential = totalProfit,
                averageProfitPerToken = (#recommendations > 0) and (totalProfit / (availableTokens - tokensRemaining)) or 0,
                topProfitItem = (#recommendations > 0) and recommendations[1].itemData.name or "None"
            }
            
            -- Generate warnings
            if not IronPawProfit.AuctionatorInterface:IsAuctionatorAvailable() then
                table.insert(report.warnings, "Auctionator not available - using manual prices only")
            end
            
            if #recommendations == 0 then
                table.insert(report.warnings, "No profitable items found with current settings")
            end
            
            if totalProfit < 10000 then -- Less than 1 gold total profit
                table.insert(report.warnings, "Very low profit potential - consider adjusting thresholds")
            end
            
            return report
end

                -- Initialize the profit calculator directly
                IronPawProfit.ProfitCalculator = ProfitCalculator

                -- Quick profit check for a single item
        function ProfitCalculator:QuickProfitCheck(itemID)
                    local itemData = IronPawProfit:GetItemData(itemID)
                    if not itemData then
                        return nil, "Item not found in database"
                    end
                    
                    if not itemData.marketAvailable then
                        return nil, "No market data available"
                    end
                    
                    local profitPerToken, profitPerStack, profitMargin = ProfitCalculator:CalculateItemProfit(itemData)
                    local risk = ProfitCalculator:CalculateRiskAssessment(itemData)
                    
                    return {
                        itemData = itemData,
                        profitPerToken = profitPerToken,
                        profitPerStack = profitPerStack,
                        profitMargin = profitMargin,
                        risk = risk,
                        formattedProfit = IronPawProfit:FormatMoney(profitPerToken)
                    }, nil
        end

    return true
end
