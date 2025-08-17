--[[
    Database.lua - Nam Ironpaw Inventory Database
    
    This module contains all data about Nam Ironpaw's vendor inventory and provides
    database functions for the IronPaw Profit Calculator addon.
    
    Key Features:
    - Complete Nam Ironpaw vendor inventory with verified item IDs
    - Sack items with material ID mappings for auction house lookups
    - Category organization for filtering
    - Database initialization and utility functions
    
    Data Structure:
    Each item entry contains:
    - itemID: WoW item ID for the sack/item sold by Nam Ironpaw
    - name: Display name of the item
    - tokens: Token cost to purchase from vendor
    - category: Item category (Meat, Seafood, Vegetable, Fruit, Reagent)
    - stack: Stack size (always 1 for sacks)
    - contains: Number of individual materials in sack (25 for most sacks)
    - materialID: Item ID of the actual cooking material for auction lookups
    
    Item ID Verification:
    All sack item IDs have been verified against Wowhead Nam Ironpaw vendor page
    to ensure accuracy for auction house price lookups.
]]--

-- Database.lua
-- Contains all data about Nam Ironpaw's inventory and related information

local addonName, addon = ...

-- Create global database module
IronPawProfitDatabase = {}

--[[
    Nam Ironpaw's Complete Vendor Inventory
    
    All item IDs verified against Wowhead Nam Ironpaw vendor page:
    https://www.wowhead.com/classic/npc=58776/nam-ironpaw
    
    Sack Items (87701-87730): Each contains 25 cooking materials for 1 token
    Reagent Items (74661, 74662, 74853): Direct reagents sold by vendor
    
    Data Structure: [itemID] = { 
        name = "Display Name",
        tokens = cost_in_tokens,
        category = "Item Category", 
        stack = stack_size,
        contains = materials_per_sack,
        materialID = auction_lookup_item_id 
    }
]]--
local IronpawInventory = {
    -- Meat Sacks (Item IDs 87701-87705)
    [87701] = { name = "Sack of Raw Tiger Steaks", tokens = 1, category = "Meat", stack = 1, contains = 5, materialID = 74833 },
    [87702] = { name = "Sack of Mushan Ribs", tokens = 1, category = "Meat", stack = 1, contains = 5, materialID = 74834 },
    [87703] = { name = "Sack of Raw Turtle Meat", tokens = 1, category = "Meat", stack = 1, contains = 5, materialID = 74837 },
    [87704] = { name = "Sack of Raw Crab Meat", tokens = 1, category = "Meat", stack = 1, contains = 5, materialID = 74838 },
    [87705] = { name = "Sack of Wildfowl Breasts", tokens = 1, category = "Meat", stack = 1, contains = 5, materialID = 74839 },
    [87730] = { name = "Sack of Crocolisk Belly", tokens = 1, category = "Seafood", stack = 1, contains = 5, materialID = 75014 },

    -- Vegetable Sacks (Item IDs 87706-87716)
    [87706] = { name = "Sack of Green Cabbages", tokens = 1, category = "Vegetable", stack = 1, contains = 25, materialID = 74840 }, 
    [87707] = { name = "Sack of Juicycrunch Carrots", tokens = 1, category = "Vegetable", stack = 1, contains = 25, materialID = 74841 },
    [87708] = { name = "Sack of Mogu Pumpkins", tokens = 1, category = "Vegetable", stack = 1, contains = 25, materialID = 74842 },
    [87709] = { name = "Sack of Scallions", tokens = 1, category = "Vegetable", stack = 1, contains = 25, materialID = 74843 }, 
    [87710] = { name = "Sack of Red Blossom Leeks", tokens = 1, category = "Vegetable", stack = 1, contains = 25, materialID = 74844 },
    [87713] = { name = "Sack of Jade Squash", tokens = 1, category = "Vegetable", stack = 1, contains = 25, materialID = 74847 }, 
    [87715] = { name = "Sack of Pink Turnips", tokens = 1, category = "Vegetable", stack = 1, contains = 25, materialID = 74849 },
    [87716] = { name = "Sack of White Turnips", tokens = 1, category = "Vegetable", stack = 1, contains = 25, materialID = 74850 },
    
    -- Fruit Sacks (Item IDs 87712, 87714)
    [87712] = { name = "Sack of Witchberries", tokens = 1, category = "Fruit", stack = 1, contains = 25, materialID = 74846 },
    [87714] = { name = "Sack of Striped Melons", tokens = 1, category = "Fruit", stack = 1, contains = 25, materialID = 74848 },
    
    -- Seafood Sacks (Item IDs 87721-87730)
    [87721] = { name = "Sack of Jade Lungfish", tokens = 1, category = "Seafood", stack = 1, contains = 5, materialID = 74856 }, 
    [87722] = { name = "Sack of Giant Mantis Shrimp", tokens = 1, category = "Seafood", stack = 1, contains = 5, materialID = 74857 }, 
    [87723] = { name = "Sack of Emperor Salmon", tokens = 1, category = "Seafood", stack = 1, contains = 5, materialID = 74859 },
    [87724] = { name = "Sack of Redbelly Mandarin", tokens = 1, category = "Seafood", stack = 1, contains = 5, materialID = 74860 },
    [87725] = { name = "Sack of Tiger Gourami", tokens = 1, category = "Seafood", stack = 1, contains = 5, materialID = 74861 }, 
    [87726] = { name = "Sack of Jewel Danio", tokens = 1, category = "Seafood", stack = 1, contains = 5, materialID = 74863 },
    [87727] = { name = "Sack of Reef Octopus", tokens = 1, category = "Seafood", stack = 1, contains = 5, materialID = 74864 }, 
    [87728] = { name = "Sack of Krasarang Paddlefish", tokens = 1, category = "Seafood", stack = 1, contains = 5, materialID = 74865 },
    [87729] = { name = "Sack of Golden Carp", tokens = 1, category = "Seafood", stack = 1, contains = 5, materialID = 74866 },
    
    
    -- Reagents (Direct items, not sacks)
    [74853] = { name = "100 Year Soy Sauce", tokens = 1, category = "Reagent", stack = 1 },
    [74662] = { name = "Rice Flour", tokens = 1, category = "Reagent", stack = 1 },
    [74661] = { name = "Black Pepper", tokens = 1, category = "Reagent", stack = 1 },

}

-- Categories for UI filtering and organization
-- Used by dropdown menus and category-based filtering
local Categories = {
    "All",       -- Show all items regardless of category
    "Meat",      -- Meat sacks (87701-87705)
    "Seafood",   -- Fish/seafood sacks (87721-87730)
    "Vegetable", -- Vegetable sacks (87706-87716, excluding fruits)
    "Fruit",     -- Fruit sacks (87712, 87714)
    "Reagent",   -- Direct reagent items (74661, 74662, 74853)
}

--[[
    Initialize the database module
    
    This function:
    1. Sets up references between the database and main addon
    2. Validates and processes all inventory data
    3. Creates the working Database table with market data fields
    4. Attaches utility functions to the main addon
    
    Args:
        mainAddon: Reference to the main IronPawProfit addon object
        
    Returns:
        boolean: true if initialization successful
]]--
function IronPawProfitDatabase:Initialize(mainAddon)
    self.addon = mainAddon
    
    -- Store data references for access by other modules
    self.addon.IronpawInventory = IronpawInventory
    self.addon.Categories = Categories
    
    -- Initialize working database table
    self.addon.Database = {}
    
    -- Validate and prepare inventory data into working format
    -- Each item gets expanded with market data and calculation fields
    for itemID, data in pairs(IronpawInventory) do
        if data.name and data.tokens and data.category then
            self.addon.Database[itemID] = {
                -- Core item data from inventory
                itemID = itemID,
                name = data.name,
                tokenCost = data.tokens,
                category = data.category,
                stackSize = data.stack or 1,
                contains = data.contains,           -- For sacks: how many individual items
                materialID = data.materialID,       -- For auction house price lookup
                contents = data.contents,           -- For bundles: description
                
                -- Market data fields (populated by AuctionatorInterface)
                marketPrice = 0,                    -- Current market price
                serverMedian = 0,                   -- Server median price
                marketAvailable = false,            -- Whether item is available on AH
                lastScanned = 0,                    -- Timestamp of last price update
                
                -- Profit calculation fields (populated by ProfitCalculator)
                profitPerToken = 0,                 -- Gold profit per token spent
                profitPerStack = 0,                 -- Gold profit per stack purchased
                profitMargin = 0,                   -- Percentage profit margin
                recommendedQuantity = 0             -- Recommended purchase quantity
            }
        end
    end
    
    -- Add database functions to main addon
    self:AttachFunctions()
    
    return true
end

--[[
    Attach utility functions to the main addon
    These functions become available as self:FunctionName() on the main addon
]]--
function IronPawProfitDatabase:AttachFunctions()
    local addon = self.addon
    
    --[[
        Get total number of items in database
        
        Returns:
            number: Count of items in the database
    ]]--
    function addon:GetDatabaseItemCount()
        local count = 0
        for _ in pairs(self.Database) do
            count = count + 1
        end
        return count
    end

    --[[
        Get all items matching a specific category
        
        Args:
            category (string): Category to filter by ("All", "Meat", "Seafood", etc.)
            
        Returns:
            table: Array of item data objects matching the category
    ]]--
    function addon:GetItemsByCategory(category)
        local items = {}
        
        for itemID, data in pairs(self.Database) do
            if category == "All" or data.category == category then
                table.insert(items, data)
            end
        end
        
        return items
    end

    --[[
        Get data for a specific item by ID
        
        Args:
            itemID (number): WoW item ID to look up
            
        Returns:
            table|nil: Item data object or nil if not found
    ]]--
    function addon:GetItemData(itemID)
        return self.Database[itemID]
    end

    --[[
        Update market data for a specific item
        Called by AuctionatorInterface when new price data is available
        
        Args:
            itemID (number): Item ID to update
            marketPrice (number): Current market price in copper
            serverMedian (number): Server median price in copper
            available (boolean): Whether item is available on auction house
            
        Returns:
            boolean: true if update successful, false if item not found
    ]]--
    function addon:UpdateItemMarketData(itemID, marketPrice, serverMedian, available)
        local item = self.Database[itemID]
        if item then
            item.marketPrice = marketPrice or 0
            item.serverMedian = serverMedian or 0
            item.marketAvailable = available or false
            item.lastScanned = time()
            return true
        end
        return false
    end

    --[[
        Format money values for display
        Converts copper values to gold/silver/copper format
        
        Args:
            copper (number): Amount in copper pieces
            
        Returns:
            string: Formatted money string (e.g., "12g 34s 56c")
    ]]--
    function addon:FormatMoney(copper)
        if not copper or copper == 0 then
            return "0g"
        end
        
        local gold = math.floor(copper / 10000)
        local silver = math.floor((copper % 10000) / 100)
        local copperCoins = copper % 100
        
        -- Round copper to 2 decimal places to avoid long decimal strings
        copperCoins = math.floor(copperCoins * 100 + 0.5) / 100
        
        local result = ""
        if gold > 0 then
            result = result .. gold .. "g"
        end
        if silver > 0 then
            result = result .. silver .. "s"
        end
        if copperCoins > 0 or result == "" then
            -- Format copper with up to 2 decimal places, removing trailing zeros
            if copperCoins == math.floor(copperCoins) then
                result = result .. math.floor(copperCoins) .. "c"
            else
                result = result .. string.format("%.2f", copperCoins):gsub("%.?0+$", "") .. "c"
            end
        end
        
        return result
    end

    --[[
        Format money values for profit display with decimal precision
        Shows two decimal places for copper amounts for more precise profit calculations
        
        Args:
            copper (number): Amount in copper pieces
            
        Returns:
            string: Formatted money string with decimals (e.g., "12g 34s 56.78c")
    ]]--
    function addon:FormatMoneyPrecise(copper)
        if not copper or copper == 0 then
            return "0.00c"
        end
        
        local gold = math.floor(copper / 10000)
        local silver = math.floor((copper % 10000) / 100)
        local copperCoins = copper % 100
        
        local result = ""
        if gold > 0 then
            result = result .. gold .. "g "
        end
        if silver > 0 then
            result = result .. silver .. "s "
        end
        
        -- Always show copper with 2 decimal places for precision
        result = result .. string.format("%.2fc", copperCoins)
        
        return result
    end

    --[[
        Get item link for tooltip display
        Creates a clickable item link for WoW's tooltip system
        
        Args:
            itemID (number): WoW item ID
            
        Returns:
            string: Item link or fallback string if item not found
    ]]--
    function addon:GetItemLink(itemID)
        local name, link = GetItemInfo(itemID)
        return link or ("Item:" .. itemID)
    end

    ------------------------------------------------------------------
    -- Ironpaw Token Storage / Ledger
    -- Persist per-character token balances and provide helpers to
    -- reconcile changes (e.g. when a character spends tokens at a vendor)
    ------------------------------------------------------------------
    function addon:InitTokenStorage()
        -- Ensure saved variable table exists
        if not IronPawProfitDB then IronPawProfitDB = {} end
        if not IronPawProfitDB.tokenBalances then
            IronPawProfitDB.tokenBalances = {}
        end
    end

    function addon:GetCharacterKey()
        local name = UnitName("player") or "Unknown"
        local realm = GetRealmName() or "UnknownRealm"
        return realm .. "-" .. name
    end

    function addon:SaveCurrentCharacterTokenBalance(tokens)
        if type(tokens) ~= "number" then
            self:Print("[TokenStorage] Invalid token value provided to SaveCurrentCharacterTokenBalance")
            return false
        end

        self:InitTokenStorage()
        local key = self:GetCharacterKey()
        IronPawProfitDB.tokenBalances[key] = { tokens = tokens, lastUpdated = time() }
        return true
    end

    function addon:GetStoredTokenBalance(charKey)
        if not IronPawProfitDB or not IronPawProfitDB.tokenBalances then return nil end
        local entry = IronPawProfitDB.tokenBalances[charKey]
        if entry and type(entry.tokens) == "number" then
            return entry.tokens
        end
        return nil
    end

    function addon:GetTotalStoredTokens()
        if not IronPawProfitDB or not IronPawProfitDB.tokenBalances then return 0 end
        local sum = 0
        for k, v in pairs(IronPawProfitDB.tokenBalances) do
            if v and type(v.tokens) == "number" then
                sum = sum + v.tokens
            end
        end
        return sum
    end

    -- Reconcile token change for current character.
    -- If tokens decreased, we assume tokens were spent and update stored balance.
    -- Returns: oldBalance, newBalance, delta (positive if decreased)
    function addon:ReconcileTokenChange(newTokens)
        if type(newTokens) ~= "number" then
            self:Print("[TokenStorage] ReconcileTokenChange received invalid token count")
            return nil
        end

        self:InitTokenStorage()
        local key = self:GetCharacterKey()
        local oldEntry = IronPawProfitDB.tokenBalances[key]
        local oldTokens = (oldEntry and type(oldEntry.tokens) == "number") and oldEntry.tokens or nil

        -- If we have no previous record, just save and return
        if oldTokens == nil then
            IronPawProfitDB.tokenBalances[key] = { tokens = newTokens, lastUpdated = time() }
            return nil, newTokens, 0
        end

        if newTokens == oldTokens then
            -- No change
            IronPawProfitDB.tokenBalances[key].lastUpdated = time()
            return oldTokens, newTokens, 0
        end

        local delta = oldTokens - newTokens
        -- Update saved balance to the new observed value
        IronPawProfitDB.tokenBalances[key].tokens = newTokens
        IronPawProfitDB.tokenBalances[key].lastUpdated = time()

        if delta > 0 then
            -- Tokens decreased (spent)
            self:Print(string.format("[TokenStorage] %s spent %d Ironpaw token(s). Recorded change.", key, delta))
        elseif delta < 0 then
            -- Tokens increased (gained)
            self:Print(string.format("[TokenStorage] %s gained %d Ironpaw token(s). Recorded change.", key, -delta))
        end

        return oldTokens, newTokens, delta
    end
end
