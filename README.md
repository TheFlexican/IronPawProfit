# IronPaw Profit Calculator

A World of Warcraft addon that helps you maximize profit by analyzing auction house data and suggesting optimal raw material purchases from Nam Ironpaw using Ironpaw Tokens.

## 🚀 NEW in v1.1.0: Smart Market Analysis

**Revolutionary market intelligence that recommends items that actually sell, not just theoretical profit!**

- **Market Competition Detection** - Analyzes auction house competition levels
- **Market-Adjusted Recommendations** - Prioritizes items with better sale potential  
- **Auction Success Tracking** - Monitors which items sell vs expire
- **Smart Token Allocation** - Distributes tokens based on real market conditions

## Features

### Core Functionality
- **Auction House Integration**: Reads market prices from the Auctionator addon
- **Profit Calculation**: Calculates profit per token for all Nam Ironpaw items
- **Smart Recommendations**: Market-adjusted suggestions based on competition and sale potential
- **Risk Assessment**: Evaluates investment risk including auction success rates
- **Price Trends**: Shows 7-day price trends for informed decision making
- **User-Friendly UI**: Clean interface with sorting and filtering options

### Market Intelligence (NEW!)
- **Competition Analysis**: Detects low/medium/high/very_high competition levels
- **Market Depth Tracking**: Monitors current auction house listing counts
- **Sale Success Rates**: Tracks which items actually sell vs expire
- **Market-Adjusted Priority**: Recommends based on sale potential, not just profit
- **Time on Market Analysis**: Estimates how quickly items sell

## Requirements

- **Required**: World of Warcraft (Retail or Classic)
- **Recommended**: Auctionator addon for accurate market prices and competition analysis
- **Optional**: Any auction house scanning addon compatible with Auctionator

## Installation

1. Download the addon files
2. Extract to your `World of Warcraft/_retail_/Interface/AddOns/` folder
3. Make sure the folder is named `IronPawProfit`
4. Restart World of Warcraft or reload UI (`/reload`)

## Usage

### Basic Commands

- `/ironpaw` or `/ipp` - Open the main calculator window
- `/ironpaw scan` - Refresh auction house data with market analysis
- `/ironpaw tokens` - Show current Ironpaw Token count
- `/ironpaw config` - Open configuration options
- `/ironpaw market` - **NEW!** Show market analysis and competition levels
- `/ironpaw sales` - **NEW!** Show auction performance and success rates
- `/ironpaw help` - Show command help

### Getting Started

1. **Install Auctionator** (recommended) and perform auction house scans
2. **Open the addon** with `/ironpaw`
3. **Click "Scan AH"** to refresh price data and analyze market conditions
4. **Review market-adjusted recommendations** - items with better sale potential rank higher
5. **Check market analysis** with `/ironpaw market` to understand competition
6. **Visit Nam Ironpaw** in Halfhill (Valley of the Four Winds, 53.5, 51.2)

### Understanding Market-Adjusted Recommendations

#### Before vs After Market Analysis

**Example - Old System (Theoretical Profit Only):**
```
1. White Turnips: 378g87s profit per token
2. Green Cabbages: 370g97s profit per token  
3. Red Leeks: 316g94s profit per token
```

**New System (Market-Adjusted Priority):**
```
1. Red Leeks: 316g94s → 411g02s (+30% - low competition, sells quickly)
2. Green Cabbages: 370g97s → 407g07s (+10% - normal market conditions)
3. White Turnips: 378g87s → 264g21s (-30% - market flooded, high competition)
```

**Result**: Now recommends Red Leeks despite lower base profit because they're more likely to actually sell!

### Understanding the Interface

#### Main Window
- **Token Display**: Shows your current Ironpaw Token count
- **Category Filter**: Filter items by type (Meat, Seafood, Vegetables, etc.)
- **Min Profit**: Set minimum profit threshold in gold
- **Summary Panel**: Overview of total profit potential

#### Results Table
- **Item Name**: Raw material name with profit color coding
- **Tokens**: Token cost per stack
- **Profit/Token**: Market-adjusted profit per token (NEW!)
- **Recommended**: Suggested number of stacks based on market conditions
- **Total Profit**: Expected total profit from recommendation
- **Market Info**: Competition level and market conditions (hover for details)

#### Color Coding
- 🟢 **Green**: High profit (5+ gold per token)
- 🟡 **Yellow**: Medium profit (2-5 gold per token)
- 🟠 **Orange**: Low profit (0.5-2 gold per token)
- ⚪ **White**: Minimal profit (less than 0.5 gold per token)
- 🔴 **Red**: High competition warning

### Market-Adjusted Profit Calculation

The addon now uses sophisticated market analysis:

```
Base Profit per Token = (Market Price × Stack Size) - 0
Market Multiplier = f(competition, listings, sale_speed, success_rate)
Final Recommendation Score = Base Profit × Market Multiplier
```

**Market Multipliers:**
- **Low Competition**: 1.3x boost (30% increase)
- **No Current Listings**: 1.2x boost (20% increase)  
- **Fast Sales (≤1 day)**: 1.15x boost (15% increase)
- **High Competition**: 0.8x penalty (20% decrease)
- **Market Flooded (20+ listings)**: 0.7x penalty (30% decrease)
- **Slow Sales (>7 days)**: 0.9x penalty (10% decrease)

Since Ironpaw items only cost tokens (no gold), the profit margin is essentially 100% if the item can be sold - but market conditions determine if it will actually sell!

## Configuration Options

Access via `/ironpaw config` or the game's Interface Options:

### Basic Settings
- **Minimum Profit**: Only show items above this profit threshold
- **Maximum Investment**: Limit total gold value of recommendations
- **Show Only Profitable**: Hide items with negative or zero profit
- **Auto Scan**: Automatically refresh data when logging in
- **Color Code Profit**: Enable color coding for profit levels

### Market Analysis Settings (NEW!)
- **Max Stacks Per Item**: Maximum stacks recommended per item (default: 999 = no limit)
- **Prioritize Top Item**: Give the most profitable item priority for all tokens (default: true)
- **Data Max Age**: Maximum age of auction data before considered stale (default: 168 hours)

### Advanced Configuration

**Smart Token Allocation:**
- When `prioritizeTopItem = true`: Most profitable item gets all available tokens
- When `prioritizeTopItem = false`: Tokens distributed based on `maxStacksPerItem` setting
- Market conditions always factor into final recommendations
- **Show Only Profitable**: Hide items with no profit potential
- **Auto Scan**: Automatically scan when opening the addon

## Tips for Maximum Profit

1. **Scan Regularly**: Auction prices change frequently
2. **Check Multiple Servers**: Prices vary by server population
3. **Consider Market Timing**: Some items sell better on raid nights
4. **Monitor Trends**: Use the 7-day trend data for timing
5. **Diversify**: Don't put all tokens into one item type
6. **Check Competition**: High-profit items may have more sellers

## Troubleshooting

### "No auction data available"
- Install and run Auctionator addon
- Perform auction house scans with Auctionator
- Wait for scan data to accumulate

### "Auctionator not detected"
- Ensure Auctionator is installed and enabled
- Check addon loading order in character select
- Try `/reload` to refresh addon detection

### Token count shows 0
- Try `/ironpaw tokens` to manually refresh count

### Prices seem wrong
- Verify Auctionator scan data is recent
- Check if you're on the correct server/faction
- Manual price override available if needed

## Advanced Features

### Price Trend Analysis
- View 7-day price history for items
- Identify rising/falling market trends
- Make timing decisions based on historical data

### Risk Assessment
- Data quality indicators
- Market volatility warnings
- Investment safety recommendations

### Bulk Operations
- Calculate optimal token allocation
- Maximize profit across all available tokens
- Consider market depth and competition

## Support

For issues, suggestions, or contributions:
- Check the addon's github page
- Report bugs with specific error messages
- Include your WoW version and other addon list

## Version History

### v1.0.0
- Initial release
- Basic profit calculation
- Auctioneer integration
- Main UI with recommendations
- Risk assessment system
- Price trend analysis

## License

This addon is provided as-is for World of Warcraft players. Feel free to modify and redistribute according to standard addon distribution practices.

---

*Happy profit hunting! May your tokens turn to gold.*
