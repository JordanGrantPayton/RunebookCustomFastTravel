# CHANGELOG

## v1.0.2 - 2025/06/15

### GrimoirePowerScript.psc
- Added "Respect Fast Travel Restrictions" setting to settings menu

### RecallRuneEffectScript.psc
- Added fast travel restriction checking to validation chain
- Integrated user setting to allow configurable fast travel behavior

### Game Behavior

**Default (Respect Fast Travel Restrictions = ON): Recommended**
- Runebook recall follows same restrictions as map fast travel
- Blocked during combat, dragon attacks, story quests, quest restrictions
- Message: "The threads of fate bind thee to this moment."
- Caveat: Also blocks you from fast-traveling from many indoor areas

**Optional (Respect Fast Travel Restrictions = OFF):**
- Runebook recall works during most situations
- Only blocked by combat (if combat setting enabled)
- Allows player to recall from indoors, use with caution while on important quests

## v1.0.1 - 2025/06/14

**Notes:** User reported an issue with the Open Runebook GUI that was fixed in a previous update. Realized the original upload was an old version.

### Critical Fixes
- Fixed infinite loop vulnerability in menu system (`While True` → bounded loops)
- Added session timeout (5min) for stuck menu events
- Fixed memory leaks from UI menu object accumulation
- Added automatic cleanup of corrupted teleport markers

### Performance Improvements
- Implemented caching system to reduce StorageUtil calls
- Menu opening speed improved

### Bug Fixes
- Fixed separator lines (`---`) being selectable in menus
- Fixed ESC/Tab key handling inconsistencies
- Fixed cache not refreshing after data modifications

### Safety Features
- Maximum 100 operations (clicks) per session
- 5 minute menu timeout
- Multiple exit conditions (ESC/Tab/Close/timeout/error)
- Emergency cleanup functions for corrupted states

## v1.0.0 - 2025/06/14

- Initial Release
- Complete Mark/Recall spell system for Skyrim
