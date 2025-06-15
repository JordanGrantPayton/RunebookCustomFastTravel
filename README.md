# RUNEBOOK CUSTOM FAST TRAVEL

**VERSION:** 1.0.2  
**RELEASE DATE:** 2025/06/14  
**AUTHOR:** Jordan Payton  
**DEVELOPED FOR:** SKYRIM VERSION: 1.6.1170.0.8  
**INSPIRED BY:** The golden age of online RPGs, a certain mystical realm where virtue once reigned.

## DESCRIPTION

A customizable fast-travel system for Skyrim that puts the player in control. Mark up to 20 personal waypoints anywhere in the world, then teleport instantly to any saved location with intuitive spell-based travel.

## WHAT THIS GIVES YOU

- Personal teleportation network - Save 20 of your favorite locations.
- Immersive magic system - Uses spells and reagents instead of map clicking.
- Instant travel - Less loading screens, no carriage rides, no opening the map.
- Full control - Choose exactly where your fast-travel points go.
- Smart management - Rename locations, delete unwanted marks, organize your Runebook.
- Works everywhere - Mark locations in any worldspace, teleport to Blackreach.

## PERFECT FOR

- Roleplaying mages who want a more immersive experience.
- Bypassing unoptimized fast-travel points and long walks.
- Teleporting directly into your home.
- Quick access to favorite shops, merchants, workbenches, etc.

## FEATURES

- **Mark Spell** - Save any position in any worldspace as a permanent teleportation waypoint.
- **Recall Spell** - Instantly travel to any saved destination.
- **Dynamic Management Interface** - Full menu system for selecting, organizing, and configuring waypoints.
- **Crafting Integration** - Create Runestones(required reagent for Mark) using existing materials and Blacksmith forge.
- **Waypoint Organization** - Rename destinations and remove unwanted locations with persistent data storage.
- **Customizable Requirements** - Toggle reagent consumption and combat restrictions via Runebook settings.
- **Persistent Data System** - All marked locations survive save/load cycles and game restarts.
- **No Fast-Travel Conflicts** - Operates independently of vanilla fast-travel system.

## REQUIREMENTS

### ESSENTIAL

- [SKSE64 (Skyrim Script Extender)](https://skse.silverlock.org/)
- [UIExtensions (User Interface Extensions)](https://www.nexusmods.com/skyrimspecialedition/mods/17561)

### RECOMMENDED

- [Wizard's Hats - Simple](https://www.nexusmods.com/skyrimspecialedition/mods/2385)

## INSTALLATION

1. Install SKSE64 first (follow SKSE installation guide)
2. Install UIExtensions
3. Install Wizard's Hats - Simple
4. Extract this mod to your Skyrim Data folder
5. Activate RunebookMarkandRecall.esp in your mod manager
6. Launch Skyrim via SKSE64 loader
7. Start/continue your game

## GETTING STARTED

1. Find the displaced mage, last seen around the College of Winterhold.
2. Acquire the Mark and Recall spells, the Open Runebook lesser power, the Runebook, and Runestones.
3. Cast Mark while holding a runebook and runestone to mark locations
4. Use Open Runebook lesser power to select destinations
5. Cast Recall to teleport to your chosen location
6. Craft additional runestones at a blacksmith forge: 1 Soul Gem (any size but black) + 1 Void Salts = 1 Runestone

## HOW TO USE

### MARKING LOCATIONS

- Equip Mark spell
- Have a Runebook and Runestone in inventory
- Cast the spell at desired location
- The Runestone is consumed in the marking ritual, its essence becoming a permanent rune within your Runebook

### MANAGING DESTINATIONS

- Cast the Open Runebook lesser power
- Browse your marked locations
- Select a destination for recall
- Rename or delete unwanted locations with the Manage menu.

### RECALLING

- Cast Recall Rune spell
- Must have selected a destination via Runebook first
- Requires Runebook in inventory
- Cannot be used in combat (if enabled in settings)

## SETTINGS

Access via Open Runebook → Settings:

- **Require Runestones:** Toggle reagent consumption for marking
- **Block Recall in Combat:** Prevent teleportation during combat, recommended for stability.
- **Reset All Settings:** Restore default configuration

## CRAFTING

Runestones can be crafted at any blacksmith forge:

- **Recipe:** 1 Soul Gem + 1 Void Salts = 1 Runestone
- Works with any size soul gem, minus black to avoid accidental consumption. The larger the soul gem, the more runestones the recipe yields.

## COMPATIBILITY

- **Mid-playthrough safe:** Yes, I tested with my existing saves and it was fine.
- **Uninstall safe:** Delete all runes via Open Runebook before uninstalling to prevent orphaned save data.
- **Load order:** Load after SKSE64, UIExtensions, and Wizard's Hats - Simple

## KNOWN ISSUES

- None currently identified
- Report bugs on mod page

## UNINSTALLATION

1. Use Open Runebook to delete all marked locations
2. Remove all mod items from inventory
3. Create a clean save
4. Disable the mod
5. Load the clean save

> **WARNING:** Uninstalling without cleaning save data may cause issues.

## PERMISSIONS

- You may modify this mod for personal use
- You must credit Wizard's Hats - Simple
- Contact author before redistributing modifications

## CREDITS

- SKSE64 Team - Skyrim Script Extender
- expired6978 - UIExtensions
- Calyps - Wizard's Hats
- Created with Skyrim Creation Kit

## CHANGELOG

**v1.0.0 - Initial Release**

- Complete Mark/Recall spell system

## FUTURE DEVELOPMENT

- Fine tune spell sounds.

## SUPPORT

For support, bug reports, or suggestions:

- Visit the mod page on Nexus Mods
- Check the Posts section for known issues
- Provide detailed bug reports with load order

**Thank you for using Runebook Custom Fast Travel!!!**
