# Changelog

All notable changes to the IronPaw Profit Calculator addon will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2025-08-04

### Added - Smart Market Analysis & Competition Detection

#### Revolutionary Market Intelligence System
- **Market Depth Analysis**: Real-time analysis of auction house competition during scans
- **Competition Level Detection**: Automatically classifies markets as low/medium/high/very_high competition
- **Market-Adjusted Recommendations**: Prioritizes items that actually sell over theoretical profit
- **Average Time on Market**: Estimates how long items take to sell based on price history
- **Market Recommendation Score**: 0-100 score factoring competition, listings, and sale speed

#### Enhanced Token Allocation Strategy
- **Smart Priority System**: Uses market multipliers to adjust recommendations
  - Low competition items get 30% priority boost
  - High competition items get 20-40% priority penalty
  - Market-flooded items (20+ listings) heavily penalized
- **Prioritize Top Item Configuration**: Option to allocate all tokens to most profitable item
- **Maximum Stacks Per Item**: Configurable limit for market depth considerations
- **Intelligent Distribution**: Balances profit potential with actual market conditions

#### New Commands and Reports
- **`/ironpaw market`**: Comprehensive market analysis and competition report
- **`/ironpaw sales`**: Auction performance tracking and success rates
- **Market-Adjusted Priority Display**: Shows how market conditions affect recommendations
- **Competition Warnings**: Alerts about overcrowded markets to avoid

#### Advanced Auction House Integration
- **Sale Success Tracking**: Monitors which items actually sell vs expire
- **Market Volatility Analysis**: Detects price wars and unstable markets
- **Listing Count Analysis**: Tracks current auction house inventory levels
- **Price History Intelligence**: Analyzes 14-day price trends for market health

#### Configuration Enhancements
- **`maxStacksPerItem`**: Control maximum stacks per item (default: 999 = no limit)
- **`prioritizeTopItem`**: Give top profitable item priority for all tokens (default: true)
- **Enhanced Config Display**: Shows new market-related configuration options

#### Risk Assessment Improvements
- **Market-Based Risk Scoring**: Incorporates auction success rates into risk calculations
- **Competition Risk Factors**: Flags high-competition items as higher risk
- **Sale Performance Integration**: Uses historical auction performance in recommendations

### Technical Improvements
- **Async Market Analysis**: Non-blocking market depth analysis during scans
- **Enhanced Data Storage**: Items now store market competition and timing data
- **Improved Performance**: Optimized auction house data processing
- **Better Error Handling**: More robust handling of missing auction data

### Changed
- **Recommendation Algorithm**: Now uses market-adjusted priority instead of raw profit
- **Token Allocation Logic**: Considers market conditions when distributing tokens
- **Priority Calculation**: Factors in competition level, market depth, and sale speed
- **User Interface**: Enhanced to show market-adjusted vs theoretical profit

### Example Impact
**Before (Theoretical Only):**
```
1. White Turnips: 378g87s9c profit per token
2. Green Cabbages: 370g97s0c profit per token
3. Red Leeks: 316g94s5c profit per token
```

**After (Market-Adjusted):**
```
1. Red Leeks: 316g94s -> 411g02s (+30% - low competition)
2. Green Cabbages: 370g97s -> 407g07s (+10% - normal market)
3. White Turnips: 378g87s -> 264g21s (-30% - market flooded)
```

**Result**: Recommends Red Leeks despite lower base profit due to better market conditions!

---

## [1.0.0] - 2025-08-04

### Initial Release

#### Added
- **Core Functionality**
  - Complete Nam Ironpaw inventory database with 59 tradeable items
  - Ironpaw Token cost calculations for all vendor items
  - Real-time profit per token calculations
  - Integration with Auctionator addon for market price data
  - Comprehensive slash command system (`/ironpaw`, `/ipp`)

- **User Interface**
  - Main calculator window with sortable item list
  - Profit display with color-coded profit indicators
  - Category filtering (Meat, Seafood, Vegetables, etc.)
  - Minimum profit threshold filtering
  - Current token count display
  - Risk assessment indicators based on data quality

- **Auction House Integration** 
  - Automatic price data retrieval from Auctionator
  - Asynchronous data processing to prevent UI freezing
  - Market price validation and quality assessment
  - Support for individual items and item sacks/bundles
  - Manual price override functionality for missing data

- **Configuration System**
  - Configurable automatic scanning intervals
  - Price data staleness thresholds
  - UI refresh preferences
  - Saved variables for persistent settings

- **Commands and Features**
  - `/ironpaw` - Open main calculator window
  - `/ironpaw scan` - Refresh auction house data  
  - `/ironpaw tokens` - Display current token count
  - `/ironpaw config` - Show configuration settings
  - `/ironpaw help` - Display command help

- **Money Formatting**
  - Proper gold/silver/copper display formatting
  - Rounded copper values to 2 decimal places
  - Automatic trailing zero removal for clean display

- **Documentation**
  - Comprehensive code documentation with function headers
  - Inline comments for complex logic
  - Module documentation for all core components
  - Complete README with installation and usage instructions

#### Technical Details
- **Addon Structure**: Modular design with separate core and UI components
- **Database**: Complete Nam Ironpaw vendor inventory (59 items)
- **API Integration**: Auctionator v1 API compatibility
- **Performance**: Asynchronous processing for large data sets
- **Error Handling**: Graceful fallback for missing dependencies
- **Memory Management**: Efficient data structures and cleanup

#### Supported Items
- **Meat Products**: 100 Aged Yak Shoulder, 100 Thick Mushan Ribs, etc.
- **Seafood**: 100 Emperor Salmon, 100 Giant Mantis Shrimp, etc.  
- **Vegetables**: 100 Scallions, 100 Mogu Pumpkin, etc.
- **Specialty Items**: Various sacks and bundles with quantity multipliers

#### Known Limitations
- Requires Auctionator addon for automatic price data
- Price accuracy depends on auction house scan frequency
- Manual price entry required for items not on auction house

---

## Version Format

This addon uses semantic versioning:
- **MAJOR.MINOR.PATCH** (e.g., 1.0.0)
- **MAJOR**: Incompatible API changes
- **MINOR**: New functionality in backwards-compatible manner  
- **PATCH**: Backwards-compatible bug fixes

## Support

For issues, suggestions, or contributions, please visit the addon's repository or contact the author.
