# Changelog

All notable changes to the IronPaw Profit Calculator addon are documented here.

This project adheres to "Keep a Changelog" and uses Semantic Versioning.

You can view full diffs for each release on GitHub using the links in the References section below.


## [1.0.4] - 2025-08-17

### Changed
- Removed the category dropdown from the Nam Ironpaw UI and simplified the layout so Min Profit and Tokens-to-spend appear on a single row.
- UI layout and anchor fixes for the Nam Ironpaw tab.

### Fixed
- Minor UI anchor issues after layout adjustments.
- Scan AH button is now persistant between tabs.

## [1.0.3] - 2025-08-17

### Added
- Persistent per-character Ironpaw token storage and aggregated total display.

### Changed
- UI token display updated to show current character tokens plus aggregated total when available.

### Fixed
- Error handling improvements around token storage and reconciliation.

## [1.0.1] - 2025-08-15

### Fixed
- Main window now closes with Esc consistently.
  - Registered the frame in `UISpecialFrames` and resolved a frame name collision.
  - Added `OnEscapePressed` handlers for input boxes so Esc clears focus and closes the window when an EditBox is focused.

## [1.0.0] - 2025-08-15

### Added
- Core Nam Ironpaw profit calculator using Auctionator price data.
- Multi-tab UI: Nam Ironpaw, Token Arbitrage, Raw Materials, Seed Planting.
- Merchant Cheng support:
  - Raw material cost analysis to generate Ironpaw Tokens.
  - Token arbitrage view (generate cheaply, spend profitably).
  - Configurable container cost (`/ironpaw containers [gold]`).
- Merchant Greenfield seed analysis (profit per seed and totals for a chosen quantity).
- Basic configuration and saved variables (min profit threshold, etc.).
- Slash commands:
  - `/ironpaw` or `/ipp` – open the main window
  - `/ironpaw scan` – refresh auction data
  - `/ironpaw tokens` – show current token count

## References

[1.0.4]: https://github.com/TheFlexican/IronPawProfit/compare/v1.0.3...v1.0.4
[1.0.3]: https://github.com/TheFlexican/IronPawProfit/compare/v1.0.2...v1.0.3
[1.0.2]: https://github.com/TheFlexican/IronPawProfit/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/TheFlexican/IronPawProfit/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/TheFlexican/IronPawProfit/releases/tag/v1.0.0