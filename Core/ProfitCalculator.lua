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

-- Calculate market multiplier based on competition and market conditions
    function ProfitCalculator:GetMarketMultiplier(itemData)
        local multiplier = 1.0 -- Base multiplier
        
        -- Factor in competition level
        if itemData.competitionLevel == "low" then
            multiplier = multiplier * 1.3 -- 30% bonus for low competition
        elseif itemData.competitionLevel == "medium" then
            multiplier = multiplier * 1.1 -- 10% bonus for medium competition
        elseif itemData.competitionLevel == "high" then
            multiplier = multiplier * 0.8 -- 20% penalty for high competition
        elseif itemData.competitionLevel == "very_high" then
            multiplier = multiplier * 0.6 -- 40% penalty for very high competition
        end
        
        -- Factor in market depth (number of current listings)
        local marketDepth = itemData.marketDepth or 0
        if marketDepth == 0 then
            multiplier = multiplier * 1.2 -- 20% bonus for no competition
        elseif marketDepth <= 3 then
            multiplier = multiplier * 1.1 -- 10% bonus for low listings
        elseif marketDepth <= 10 then
            multiplier = multiplier * 1.0 -- Normal market
        elseif marketDepth <= 20 then
            multiplier = multiplier * 0.85 -- 15% penalty for many listings
        else
            multiplier = multiplier * 0.7 -- 30% penalty for overcrowded market
        end
        
        -- Factor in average time on market
        local timeOnMarket = itemData.averageTimeOnMarket or 3
        if timeOnMarket <= 1 then
            multiplier = multiplier * 1.15 -- 15% bonus for fast sales
        elseif timeOnMarket <= 3 then
            multiplier = multiplier * 1.05 -- 5% bonus for reasonable sales speed
        elseif timeOnMarket > 7 then
            multiplier = multiplier * 0.9 -- 10% penalty for slow sales
        end
        
        -- Factor in recommendation score from market analysis
        local recScore = itemData.recommendationScore or 50
        if recScore >= 80 then
            multiplier = multiplier * 1.1 -- 10% bonus for high recommendation score
        elseif recScore <= 30 then
            multiplier = multiplier * 0.9 -- 10% penalty for low recommendation score
        end
        
        return multiplier
    end

-- Get human-readable explanation of market conditions
    function ProfitCalculator:GetMarketReason(itemData)
        local reasons = {}
        
        -- Competition analysis
        if itemData.competitionLevel == "low" then
            table.insert(reasons, "low competition")
        elseif itemData.competitionLevel == "high" then
            table.insert(reasons, "high competition")
        elseif itemData.competitionLevel == "very_high" then
            table.insert(reasons, "very high competition")
        end
        
        -- Market depth analysis
        local marketDepth = itemData.marketDepth or 0
        if marketDepth == 0 then
            table.insert(reasons, "no current listings")
        elseif marketDepth > 20 then
            table.insert(reasons, "market flooded (" .. marketDepth .. " listings)")
        elseif marketDepth > 10 then
            table.insert(reasons, "many listings (" .. marketDepth .. ")")
        end
        
        -- Time on market analysis
        local timeOnMarket = itemData.averageTimeOnMarket or 3
        if timeOnMarket <= 1 then
            table.insert(reasons, "sells quickly")
        elseif timeOnMarket > 7 then
            table.insert(reasons, "sells slowly")
        end
        
        if #reasons == 0 then
            return "normal market conditions"
        else
            return table.concat(reasons, ", ")
        end
    end    -- Calculate optimal purchase recommendations
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
                        -- Calculate market-adjusted priority
                        local marketMultiplier = ProfitCalculator:GetMarketMultiplier(itemData)
                        local adjustedPriority = (profitPerToken / itemData.tokenCost) * marketMultiplier
                        
                        table.insert(recommendations, {
                            itemData = itemData,
                            profitPerToken = profitPerToken,
                            profitPerStack = profitPerStack,
                            profitMargin = profitMargin,
                            priority = adjustedPriority, -- Market-adjusted priority
                            rawPriority = profitPerToken / itemData.tokenCost, -- Original priority
                            marketMultiplier = marketMultiplier,
                            marketReason = ProfitCalculator:GetMarketReason(itemData)
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
            
            -- Apply market depth considerations 
            -- Check configuration for prioritizing top item and max stacks
            local prioritizeTopItem = IronPawProfit:GetConfig("prioritizeTopItem")
            local maxStacksPerItem = IronPawProfit:GetConfig("maxStacksPerItem") or 999
            
            if prioritizeTopItem and i == 1 then
                -- First (most profitable) item gets priority - use all available tokens if profitable
                recommendedStacks = maxAffordableStacks
            else
                -- Apply configured maximum stacks per item for other items
                if maxStacksPerItem >= 999 then
                    recommendedStacks = maxAffordableStacks
                else
                    recommendedStacks = math.min(recommendedStacks, maxStacksPerItem)
                end
            end
            
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
            
            -- Check auction sale success rate
            local successRate, successMessage = IronPawProfit.AuctionatorInterface:GetSaleSuccessRate(itemData.itemID)
            if successRate < 0.5 then
                risk.score = risk.score + 25
                table.insert(risk.factors, "Low auction success rate (" .. string.format("%.1f%%", successRate * 100) .. ")")
            elseif successRate > 0.8 then
                risk.score = risk.score - 15
                table.insert(risk.factors, "High auction success rate (" .. string.format("%.1f%%", successRate * 100) .. ")")
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
