# Changelog

All notable changes to the IronPaw Profit Calculator addon are documented here.

This project follows Keep a Changelog and Semantic Versioning.

For full compare links, see the releases on GitHub:

- v1.0.3: https://github.com/TheFlexican/IronPawProfit/compare/v1.0.2...v1.0.3
- v1.0.2: https://github.com/TheFlexican/IronPawProfit/compare/v1.0.1...v1.0.2
- v1.0.1: https://github.com/TheFlexican/IronPawProfit/compare/v1.0.0...v1.0.1
- v1.0.0: https://github.com/TheFlexican/IronPawProfit/releases/tag/v1.0.0

## [1.0.3] - 2025-08-17

### Added
- Initial release of persistent token storage and reconciliation.

### Changed
- UI token display updated to show current + total stored tokens.

### Fixed
- Error handling improvements around token storage.

## [1.0.1] - 2025-08-15

### Fixed
- Main window now closes with Esc consistently:
  - Registered the frame in `UISpecialFrames`.
  - Resolved a global name collision between the module table and the frame that caused an Esc handler error in UIParent.
  - Added `OnEscapePressed` handlers for input boxes so Esc clears focus and closes the window even when an EditBox is focused.

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