# IronPaw Profit Calculator

A World of Warcraft addon that helps you maximize profit by analyzing auction house data and suggesting optimal raw material purchases from Nam Ironpaw using Ironpaw Tokens.

## Features

- **Auction House Integration**: Reads market prices from the Auctionator addon
- **Profit Calculation**: Calculates profit per token for all Nam Ironpaw items
- **Smart Recommendations**: Suggests optimal purchases based on your token count
- **Risk Assessment**: Evaluates investment risk based on market data quality
- **Price Trends**: Shows 7-day price trends for informed decision making
- **User-Friendly UI**: Clean interface with sorting and filtering options

## Requirements

- **Required**: World of Warcraft (Retail or Classic)
- **Recommended**: Auctionator addon for accurate market prices
- **Optional**: Any auction house scanning addon compatible with Auctionator

## Installation

1. Download the addon files
2. Extract to your `World of Warcraft/_retail_/Interface/AddOns/` folder
3. Make sure the folder is named `IronPawProfit`
4. Restart World of Warcraft or reload UI (`/reload`)

## Usage

### Basic Commands

- `/ironpaw` or `/ipp` - Open the main calculator window
- `/ironpaw scan` - Refresh auction house data
- `/ironpaw tokens` - Show current Ironpaw Token count
- `/ironpaw config` - Open configuration options
- `/ironpaw help` - Show command help

### Getting Started

1. **Install Auctionator** (recommended) and perform auction house scans
2. **Open the addon** with `/ironpaw`
3. **Click "Scan AH"** to refresh price data
4. **Review recommendations** sorted by profit per token
5. **Visit Nam Ironpaw** in Halfhill (Valley of the Four Winds, 53.5, 51.2)

### Understanding the Interface

#### Main Window
- **Token Display**: Shows your current Ironpaw Token count
- **Category Filter**: Filter items by type (Meat, Seafood, Vegetables, etc.)
- **Min Profit**: Set minimum profit threshold in gold
- **Summary Panel**: Overview of total profit potential

#### Results Table
- **Item Name**: Raw material name with profit color coding
- **Tokens**: Token cost per stack
- **Profit/Token**: Profit earned per token spent
- **Recommended**: Suggested number of stacks to buy
- **Total Profit**: Expected total profit from recommendation

#### Color Coding
- 🟢 **Green**: High profit (5+ gold per token)
- 🟡 **Yellow**: Medium profit (2-5 gold per token)
- 🟠 **Orange**: Low profit (0.5-2 gold per token)
- ⚪ **White**: Minimal profit (less than 0.5 gold per token)

### Profit Calculation

The addon calculates profit as follows:
```
Profit per Token = (Market Price × Stack Size) - 0
```

Since Ironpaw items only cost tokens (no gold), the profit margin is essentially 100% if the item can be sold for any amount on the auction house.

## Configuration Options

Access via `/ironpaw config` or the game's Interface Options:

- **Minimum Profit**: Only show items above this profit threshold
- **Maximum Investment**: Limit total gold value of recommendations
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
