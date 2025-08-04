-- Simple test script to verify addon structure
-- This would be run in WoW's Lua environment

print("=== IronPaw Profit Addon Test ===")

-- Check if all modules are defined
local modules = {
    "IronPawProfitDatabase",
    "IronPawProfitAuctionatorInterface", 
    "IronPawProfitCalculator",
    "IronPawProfitMainFrame",
    "IronPawProfitProfitDisplay"
}

for _, module in ipairs(modules) do
    if _G[module] then
        print("✓ " .. module .. " is defined")
        if _G[module].Initialize then
            print("  ✓ Has Initialize function")
        else
            print("  ✗ Missing Initialize function")
        end
    else
        print("✗ " .. module .. " is not defined")
    end
end

-- Check if main addon object exists
if IronPawProfit then
    print("✓ IronPawProfit main object exists")
    print("  Version: " .. (IronPawProfit.version or "unknown"))
    
    -- Check initialization state
    if IronPawProfit.initState then
        print("  Initialization state tracking: ✓")
        for key, value in pairs(IronPawProfit.initState) do
            print("    " .. key .. ": " .. tostring(value))
        end
    else
        print("  Initialization state tracking: ✗")
    end
else
    print("✗ IronPawProfit main object not found")
end

print("=== Test Complete ===")
