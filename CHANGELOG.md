# Changelog

All notable changes to the IronPaw Profit Calculator addon will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
