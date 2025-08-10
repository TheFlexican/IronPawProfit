-- GreenfieldCalculator.lua
-- Calculates optimal seeds to plant for profit from Merchant Greenfield.

local addonName, addon = ...

-- Create global GreenfieldCalculator module
IronPawProfitGreenfieldCalculator = {}
local GreenfieldCalculator = IronPawProfitGreenfieldCalculator -- Local alias for convenience

--[[
    This table holds the data for the seeds sold by Merchant Greenfield.
    It includes profession-related seeds as well as vegetable seeds.
    
    Data Structure: [seedItemID] = {
        name = "Seed Name",
        cost = cost_in_copper,
        yields = {
            { itemID = itemID, name = "Item Name", quantity = average_yield, chance = drop_chance (1 for 100%) },
            ...
        }
    }
]]--
local GreenfieldSeeds = {
    -- Profession Seeds
    [85216] = {
        name = "Enigma Seed",
        cost = 10000,
        yields = {
            { itemID = 72234, name = "Green Tea Leaf", quantity = 0.875, chance = 1 },
            { itemID = 72237, name = "Rain Poppy", quantity = 0.875, chance = 1 },
            { itemID = 72235, name = "Silkweed", quantity = 0.875, chance = 1 },
            { itemID = 79011, name = "Fool's Cap", quantity = 0.875, chance = 1 },
            { itemID = 79010, name = "Snow Lily", quantity = 0.875, chance = 1 },
            { itemID = 72238, name = "Golden Lotus", quantity = 1, chance = 0.05 },
        }
    },
    [85217] = {
        name = "Magebulb Seed",
        cost = 10000,
        yields = {
            { itemID = 74249, name = "Spirit Dust", quantity = 3.5, chance = 1 },
            { itemID = 74250, name = "Mysterious Essence", quantity = 1, chance = 0.05 },
        }
    },
    [89202] = {
        name = "Raptorleaf Seed",
        cost = 10000,
        yields = {
            { itemID = 72120, name = "Mist-Touched Leather", quantity = 1.5, chance = 1 },
            { itemID = 72163, name = "Magnificent Hide", quantity = 1, chance = 0.05 },
        }
    },
    [85215] = {
        name = "Snakeroot Seed",
        cost = 10000,
        yields = {
            { itemID = 72092, name = "Ghost Iron Ore", quantity = 3, chance = 1 },
            { itemID = 72103, name = "White Trillium Ore", quantity = 1, chance = 0.05 },
            { itemID = 72094, name = "Black Trillium Ore", quantity = 1, chance = 0.05 },
            { itemID = 72093, name = "Kyparite", quantity = 1, chance = 0.05 },
        }
    },
    [89197] = {
        name = "Windshear Cactus Seed",
        cost = 10000,
        yields = {
            { itemID = 72988, name = "Windwool Cloth", quantity = 3.5, chance = 1 },
            { itemID = 82441, name = "Bolt of Windwool Cloth", quantity = 2, chance = 0.05 },
        }
    },
    [89233] = { -- corrected from 87747
        name = "Songbell Seed",
        cost = 10000,
        yields = {
            { itemID = 89112, name = "Mote of Harmony", quantity = 1, chance = 1 },
        }
    },

    -- Vegetable Seeds
    [79102] = {
        name = "Green Cabbage Seeds",
        cost = 10000,
        yields = {
            { itemID = 74840, name = "Green Cabbage", quantity = 5, chance = 1 },
        }
    },
    [80590] = {
        name = "Juicycrunch Carrot Seeds",
        cost = 10000,
        yields = {
            { itemID = 74841, name = "Juicycrunch Carrot", quantity = 5, chance = 1 },
        }
    },
    [80591] = {
        name = "Scallion Seeds",
        cost = 10000,
        yields = {
            { itemID = 74843, name = "Scallions", quantity = 5, chance = 1 },
        }
    },
    [80592] = {
        name = "Mogu Pumpkin Seeds",
        cost = 10000,
        yields = {
            { itemID = 74842, name = "Mogu Pumpkin", quantity = 5, chance = 1 },
        }
    },
    [80593] = {
        name = "Red Blossom Leek Seeds",
        cost = 10000,
        yields = {
            { itemID = 74844, name = "Red Blossom Leek", quantity = 5, chance = 1 },
        }
    },
    [80594] = {
        name = "Pink Turnip Seeds",
        cost = 10000,
        yields = {
            { itemID = 74849, name = "Pink Turnip", quantity = 5, chance = 1 },
        }
    },
    [80595] = {
        name = "White Turnip Seeds",
        cost = 10000,
        yields = {
            { itemID = 74850, name = "White Turnip", quantity = 5, chance = 1 },
        }
    },
    [89328] = {
        name = "Jade Squash Seeds",
        cost = 10000,
        yields = {
            { itemID = 74847, name = "Jade Squash", quantity = 5, chance = 1 },
        }
    },
    [89326] = {
        name = "Witchberry Seeds",
        cost = 10000,
        yields = {
            { itemID = 74846, name = "Witchberries", quantity = 5, chance = 1 },
        }
    },
    [89329] = {
        name = "Striped Melon Seeds",
        cost = 10000,
        yields = {
            { itemID = 74848, name = "Striped Melon", quantity = 5, chance = 1 },
        }
    }
}

-- Initialize the module
function GreenfieldCalculator:Initialize(mainAddon)
    self.addon = mainAddon
    self.GreenfieldSeeds = GreenfieldSeeds
    
    -- Assign the module itself to the main addon, so its methods are preserved
    mainAddon.GreenfieldCalculator = self
end

--[[
    Calculate profit for planting seeds from Merchant Greenfield.
    
    Returns:
        table: Array of seed recommendations sorted by profit.
]]--
function GreenfieldCalculator:CalculateSeedProfits()
    local recommendations = {}
    
    for seedID, seedData in pairs(self.GreenfieldSeeds) do
        local totalMarketValue = 0
        local tooltipData = {}
        
        for _, yieldInfo in ipairs(seedData.yields) do
            -- Use self.addon to correctly reference the main addon object
            local marketPrice = self.addon.AuctionatorInterface:GetMarketPrice(yieldInfo.itemID)
            if marketPrice and marketPrice > 0 then
                -- Expected value = price * quantity * chance
                local calculatedValue = marketPrice * yieldInfo.quantity * yieldInfo.chance
                totalMarketValue = totalMarketValue + calculatedValue
                
                table.insert(tooltipData, {
                    name = yieldInfo.name,
                    quantity = yieldInfo.quantity,
                    chance = yieldInfo.chance,
                    marketPrice = marketPrice,
                    calculatedValue = calculatedValue
                })
            end
        end
        
        if totalMarketValue > 0 then
            local profit = totalMarketValue - seedData.cost
            
            table.insert(recommendations, {
                seedID = seedID,
                seedName = seedData.name,
                profit = profit,
                marketValue = totalMarketValue,
                cost = seedData.cost,
                tooltipData = tooltipData
            })
        end
    end
    
    -- Sort recommendations by profit (highest first)
    table.sort(recommendations, function(a, b)
        return a.profit > b.profit
    end)
    
    return recommendations
end
