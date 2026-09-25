# BrickKit Monetization V1 - Server Core

This directory contains the M2.1 server core. It is intentionally source-only: no package manager, build tool, dependency, or polished UI is included.

## Studio layout

Create a `BrickKitMonetization` Model in `ServerScriptService` and reproduce the hierarchy in this directory with matching Script and ModuleScript names. `MonetizationServer.server.luau` is the entry-point Script. Edit only `Config` for the standard built-in rewards.

The implementation uses the current Roblox API signature:

`MarketplaceService:BindReceiptHandler(Enum.ReceiptType.DeveloperProduct, handler, { productId })`

It deliberately does not fall back to or replace `ProcessReceipt`. A binding conflict disables only the affected Developer Product.

Run the files under `tests/` as ModuleScripts with `TestRunner` as a server Script. Complete `tests/STUDIO_CHECKLIST.md` for behavior that requires published Marketplace items, DataStore access, multiple servers, or respawns.
