# xanChat Notes

## Changelog (2026-02-04)
- Removed AceEvent, AceGUI, CallbackHandler, and LibStub from load order.
- Added `wrapper.lua` providing a lightweight event system, callbacks, and optional tickers with Classic/Retail fallbacks.
- Replaced AceGUI-based Copy Chat UI with Blizzard widgets.
- Added `/xanchat debug` to toggle wrapper debug prints (wrapper load + event registration).
- Fixed versioned settings update to use the addon metadata version (previously always treated as changed).

## Compatibility Notes
- Wrapper uses feature detection for metadata and CVars (`C_AddOns`/`C_CVar` fallbacks).
- Event dispatch and UI code remain compatible across Classic and Retail where APIs exist.
