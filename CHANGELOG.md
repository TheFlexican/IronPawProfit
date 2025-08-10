# Changelog

All notable changes to the IronPaw Profit Calculator addon will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2025-08-04

### Added - Merchant Cheng Token Generation System

#### Revolutionary Token Generation Features
- **Raw Material Analysis**: Scan auction house for cheapest raw materials to generate Ironpaw tokens
- **Merchant Cheng Integration**: Calculate cost per token using raw materials + containers
- **Complete Profit Cycle**: Raw materials → containers → tokens → Nam Ironpaw purchases
- **Cost Optimization**: Find most cost-effective ways to generate tokens before spending them

#### New Merchant Cheng Calculator Module
- **Raw Material Cost Analysis**: Calculate cost per token for all available cooking materials
- **Market Competition Tracking**: Analyze competition levels for raw material purchases
- **Container Cost Configuration**: Configurable container costs from Merchant Cheng
- **Net Profit Calculations**: Factor in both token generation cost and Nam Ironpaw profit potential
- **Optimal Purchase Planning**: Recommend best raw materials for token generation investment

#### Enhanced GUI Interface
- **Tabbed Interface**: New 3-tab system (Nam Ironpaw, Token Arbitrage, Raw Materials)
- **Token Arbitrage Tab**: Shows best opportunities combining token generation + sack purchases
- **Raw Materials Tab**: Comprehensive cost comparison for all available cooking materials
- **Shopping List Integration**: Displays exact quantities needed for 1, 5, and 10 tokens
- **Price Refresh Button**: Manual price update functionality for current market data
- **Interactive Tooltips**: Detailed breakdowns with shopping recommendations on hover
- **Smart Disclaimers**: Timestamps and market volatility warnings
- **Integrated Analysis**: Seamlessly switch between different analysis modes

#### Enhanced Command System
- **`/ironpaw cheng`**: Comprehensive raw material analysis for token generation
- **`/ironpaw materials`**: Detailed purchase recommendations with investment planning
- **`/ironpaw containers [cost]`**: Set or display Merchant Cheng container costs
- **Integrated Help System**: Updated help with clear explanation of new features

#### Smart Shopping List Features
- **Quantity Recommendations**: Shows exact materials needed for 1, 5, and 10 token batches  
- **Cost Breakdowns**: Displays total investment required for different batch sizes
- **Market Volatility Warnings**: Timestamps and disclaimers about price fluctuations
- **Interactive Planning**: Hover tooltips with detailed purchase recommendations
- **Batch Size Optimization**: Start small (1-5 tokens) to test market before large investments

### Technical Improvements
- **Correct Material Quantities**: Fish (20/60), Meat (20), Vegetables (100) per container
- **Database Architecture**: Enhanced database structure for raw material mappings
- **Function Scoping**: Proper module organization and variable scoping
- **Error Handling**: Robust error checking and debug logging
- **Market Integration**: Seamless Auctionator integration for raw material pricing

#### Intelligent Market Analysis
- **Cross-Market Optimization**: Compare token generation costs vs direct Nam Ironpaw purchases
- **Competition-Aware Recommendations**: Factor raw material market competition into suggestions
- **Profit Margin Analysis**: Calculate real profit after all token generation costs
- **Risk Assessment Integration**: Evaluate both raw material purchase risks and final sale potential

### Configuration Enhancements
- **Persistent Storage**: Container costs saved across sessions
- **Dynamic Cost Updates**: Easy container cost adjustment via commands

### Technical Improvements
- **Modular Architecture**: Clean separation between Nam Ironpaw and Merchant Cheng systems
- **Shared Market Data**: Raw materials use same market analysis as finished goods
- **Enhanced Database Utilization**: Leverage existing materialID mappings for raw material lookup
- **Performance Optimization**: Efficient sorting and filtering for raw material recommendations

---

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
