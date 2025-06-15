Scriptname GrimoirePowerScript extends ActiveMagicEffect

Book Property RunebookBase Auto

; Menu timeout constants
Int Property MAX_MENU_ITERATIONS = 100 Auto
Int MENU_TIMEOUT_SECONDS = 300  ; Fixed 5 minutes

; Cache for location data to reduce StorageUtil calls
String[] cachedUIDs
String[] cachedNames
Int cachedCount = 0
Float lastCacheTime = 0.0
Float CACHE_TIMEOUT = 5.0

; Session management
Bool sessionActive = False
Float sessionStartTime = 0.0
Int sessionIterations = 0

Event OnEffectStart(Actor akTarget, Actor akCaster)
    If akTarget == Game.GetPlayer()
        If ValidateGrimoireRequirements()
            StartGrimoireSession()
        EndIf
    EndIf
EndEvent

; Validate Runebook access requirements
Bool Function ValidateGrimoireRequirements()
    If !ValidateProperties()
        Return False
    EndIf
    
    If !ValidatePlayerState()
        Return False
    EndIf
    
    Return True
EndFunction

; Validate required properties are set
Bool Function ValidateProperties()
    If !RunebookBase
        Debug.Notification("ERROR: RunebookBase Property not set!")
        Return False
    EndIf
    
    Return True
EndFunction

; Validate player has required items
Bool Function ValidatePlayerState()
    Actor player = Game.GetPlayer()
    If player.GetItemCount(RunebookBase) <= 0
        Debug.Notification("Thou dost need a Runebook!")
        Return False
    EndIf
    
    Return True
EndFunction

; Start session with proper initialization
Function StartGrimoireSession()
    sessionActive = True
    sessionStartTime = Utility.GetCurrentRealTime()
    sessionIterations = 0
    
    RefreshLocationCache()
    OpenGrimoireSession()
    EndGrimoireSession()
EndFunction

; Main Runebook session with safety limits
Function OpenGrimoireSession()
    While sessionActive && sessionIterations < MAX_MENU_ITERATIONS
        ; Safety timeout check
        If IsSessionTimedOut()
            Debug.Notification("Session timeout reached.")
            Return
        EndIf
        
        String menuResult = ShowMainGrimoireMenu()
        
        If menuResult == "close" || menuResult == "timeout" || menuResult == "error"
            Return
        ElseIf menuResult == "manage"
            ShowRuneManagementSession()
        ElseIf menuResult == "settings"
            ShowSettingsSession()
        ElseIf menuResult == "select"
            ; Selection made, continue loop
        EndIf
        
        sessionIterations += 1
        Utility.Wait(0.1)
    EndWhile
    
    If sessionIterations >= MAX_MENU_ITERATIONS
        Debug.Notification("Maximum menu operations reached.")
    EndIf
EndFunction

; Check if session has timed out
Bool Function IsSessionTimedOut()
    Return (Utility.GetCurrentRealTime() - sessionStartTime) > MENU_TIMEOUT_SECONDS
EndFunction

; Clean session shutdown
Function EndGrimoireSession()
    sessionActive = False
    sessionStartTime = 0.0
    sessionIterations = 0
    CleanupCache()
EndFunction

; Cache management to reduce StorageUtil calls
Function RefreshLocationCache()
    Float currentTime = Utility.GetCurrentRealTime()
    If (currentTime - lastCacheTime) < CACHE_TIMEOUT && cachedCount > 0
        Return
    EndIf
    
    Actor player = Game.GetPlayer()
    Int storedCount = StorageUtil.GetIntValue(player, "Runebook_Count", 0)
    
    ; Clear old arrays
    cachedUIDs = new String[20]
    cachedNames = new String[20]
    
    ; Populate cache with validation
    Int validCount = 0
    Int i = 0
    While i < storedCount && validCount < 20
        String uid = StorageUtil.GetStringValue(player, "Runebook_" + i)
        If uid != ""
            String locName = StorageUtil.GetStringValue(player, uid + "_Name")
            If locName != "" && ValidateMarkerExists(player, uid)
                cachedUIDs[validCount] = uid
                cachedNames[validCount] = locName
                validCount += 1
            Else
                ; Clean up invalid entry
                CleanupInvalidRune(player, i)
            EndIf
        EndIf
        i += 1
    EndWhile
    
    cachedCount = validCount
    lastCacheTime = currentTime
    
    ; Update stored count if it changed
    If validCount != storedCount
        StorageUtil.SetIntValue(player, "Runebook_Count", validCount)
        CompactRuneList()
    EndIf
EndFunction

; Validate marker still exists
Bool Function ValidateMarkerExists(Actor player, String uid)
    Form markerForm = StorageUtil.GetFormValue(player, uid + "_Marker")
    If !markerForm
        Return False
    EndIf
    
    ObjectReference marker = markerForm as ObjectReference
    If !marker || marker.IsDeleted()
        Return False
    EndIf
    
    Return True
EndFunction

; Clean up invalid rune data
Function CleanupInvalidRune(Actor player, Int index)
    String uid = StorageUtil.GetStringValue(player, "Runebook_" + index)
    If uid != ""
        ; Clean up marker if it exists
        Form markerForm = StorageUtil.GetFormValue(player, uid + "_Marker")
        If markerForm
            ObjectReference marker = markerForm as ObjectReference
            If marker && !marker.IsDeleted()
                marker.Delete()
            EndIf
        EndIf
        
        ; Clean up storage
        StorageUtil.UnsetFormValue(player, uid + "_Marker")
        StorageUtil.UnsetStringValue(player, uid + "_Name")
        StorageUtil.UnsetStringValue(player, "Runebook_" + index)
    EndIf
EndFunction

; Cleanup cache memory
Function CleanupCache()
    cachedUIDs = new String[1]
    cachedNames = new String[1]
    cachedCount = 0
EndFunction

; Show main menu with improved error handling
String Function ShowMainGrimoireMenu()
    If !sessionActive || IsSessionTimedOut()
        Return "close"
    EndIf
    
    Actor player = Game.GetPlayer()
    RefreshLocationCache()
    
    If cachedCount == 0
        Debug.Notification("Thy Runebook contains no runes.")
        Return "close"
    EndIf
    
    UIListMenu menu = CreateMainMenu(player)
    If !menu
        Debug.Notification("ERROR: Could not create Runebook menu!")
        Return "error"
    EndIf
    
    menu.OpenMenu()
    String result = menu.GetResultString()
    
    ; Handle menu results
    If result == "[[ Close ]]" || result == "" || result == "---"
        Return "close"
    ElseIf result == "[[ Manage Runes ]]"
        Return "manage"
    ElseIf result == "[[ Settings ]]"
        Return "settings"
    Else
        ; Location selected
        String cleanResult = CleanSelectionMarkers(result)
        If SetSelectedDestination(cleanResult)
            Return "select"
        Else
            Return "error"
        EndIf
    EndIf
EndFunction

; Create main menu using cached data
UIListMenu Function CreateMainMenu(Actor player)
    UIListMenu menu = UIExtensions.GetMenu("UIListMenu", TRUE) as UIListMenu
    If !menu
        Return None
    EndIf
    
    ; Navigation options
    menu.AddEntryItem("[[ Close ]]")
    menu.AddEntryItem("[[ Manage Runes ]]")
    menu.AddEntryItem("[[ Settings ]]")
    menu.AddEntryItem("---")
    
    ; Get current selection for highlighting
    String currentSelection = StorageUtil.GetStringValue(player, "Runebook_SelectedName", "")
    
    ; Use cached data instead of repeated StorageUtil calls
    Int i = 0
    While i < cachedCount && i < 20
        String locName = cachedNames[i]
        If locName != ""
            If locName == currentSelection
                menu.AddEntryItem(">>> " + locName + " <<<")
            Else
                menu.AddEntryItem(locName)
            EndIf
        EndIf
        i += 1
    EndWhile
    
    Return menu
EndFunction

; Remove selection markers from result string
String Function CleanSelectionMarkers(String result)
    If StringUtil.Find(result, ">>> ") == 0
        Return StringUtil.Substring(result, 4, StringUtil.GetLength(result) - 8)
    EndIf
    Return result
EndFunction

; Improved destination setting with validation
Bool Function SetSelectedDestination(String selectedName)
    Actor player = Game.GetPlayer()
    String uid = FindRuneUIDByNameCached(selectedName)
    
    If uid != "" && ValidateMarkerExists(player, uid)
        StorageUtil.SetStringValue(player, "Runebook_SelectedDestination", uid)
        StorageUtil.SetStringValue(player, "Runebook_SelectedName", selectedName)
        Debug.Notification("Destination chosen.")
        Return True
    Else
        Debug.Notification("Selected location is no longer valid.")
        Return False
    EndIf
EndFunction

; Fast lookup using cached data
String Function FindRuneUIDByNameCached(String runeName)
    Int i = 0
    While i < cachedCount
        If cachedNames[i] == runeName
            Return cachedUIDs[i]
        EndIf
        i += 1
    EndWhile
    
    ; Fallback to traditional lookup
    Return FindRuneUIDByName(runeName)
EndFunction

; Management session with safety limits
Function ShowRuneManagementSession()
    Int managementIterations = 0
    
    While sessionActive && managementIterations < 50 && sessionIterations < MAX_MENU_ITERATIONS
        If IsSessionTimedOut()
            Return
        EndIf
        
        String menuResult = ShowRuneManagementMenu()
        
        If menuResult == "back" || menuResult == "error"
            Return
        ElseIf menuResult == "action"
            RefreshLocationCache()
        EndIf
        
        managementIterations += 1
        sessionIterations += 1
        Utility.Wait(0.1)
    EndWhile
EndFunction

; Show rune management menu and return action
String Function ShowRuneManagementMenu()
    If !sessionActive || IsSessionTimedOut()
        Return "back"
    EndIf
    
    Actor player = Game.GetPlayer()
    RefreshLocationCache()
    
    If cachedCount == 0
        Debug.Notification("No runes to manage.")
        Return "back"
    EndIf
    
    UIListMenu menu = CreateManagementMenu(player)
    If !menu
        Return "back"
    EndIf
    
    menu.OpenMenu()
    String selectedRune = menu.GetResultString()
    
    If selectedRune == "[[ Back ]]" || selectedRune == "" || selectedRune == "---"
        Return "back"
    Else
        ShowRuneActionsLoop(selectedRune)
        Return "action"
    EndIf
EndFunction

; Create rune management menu
UIListMenu Function CreateManagementMenu(Actor player)
    UIListMenu menu = UIExtensions.GetMenu("UIListMenu", TRUE) as UIListMenu
    If !menu
        Return None
    EndIf
    
    menu.AddEntryItem("[[ Back ]]")
    menu.AddEntryItem("---")
    
    Int i = 0
    While i < cachedCount && i < 20
        String locName = cachedNames[i]
        If locName != ""
            menu.AddEntryItem(locName)
        EndIf
        i += 1
    EndWhile
    
    Return menu
EndFunction

; Rune actions loop for specific rune
Function ShowRuneActionsLoop(String runeName)
    Int actionIterations = 0
    
    While sessionActive && actionIterations < 20
        If IsSessionTimedOut()
            Return
        EndIf
        
        String menuResult = ShowRuneActionMenu(runeName)
        
        If menuResult == "back"
            Return
        ElseIf menuResult == "rename"
            ExecuteRename(runeName)
            Return
        ElseIf menuResult == "delete"
            ExecuteDelete(runeName)
            Return
        EndIf
        
        actionIterations += 1
        sessionIterations += 1
        Utility.Wait(0.1)
    EndWhile
EndFunction

; Show action menu for specific rune
String Function ShowRuneActionMenu(String runeName)
    UIListMenu menu = CreateActionMenu(runeName)
    If !menu
        Return "back"
    EndIf
    
    menu.OpenMenu()
    String choice = menu.GetResultString()
    
    If choice == "[[ Back ]]" || choice == ""
        Return "back"
    ElseIf StringUtil.Find(choice, "Rename:") == 0
        Return "rename"
    ElseIf StringUtil.Find(choice, "Delete:") == 0
        Return "delete"
    EndIf
    
    Return "back"
EndFunction

; Create action menu for rune
UIListMenu Function CreateActionMenu(String runeName)
    UIListMenu menu = UIExtensions.GetMenu("UIListMenu", TRUE) as UIListMenu
    If !menu
        Return None
    EndIf
    
    menu.AddEntryItem("[[ Back ]]")
    menu.AddEntryItem("---")
    menu.AddEntryItem("Rename: " + runeName)
    menu.AddEntryItem("Delete: " + runeName)
    
    Return menu
EndFunction

; Settings session
Function ShowSettingsSession()
    Int settingsIterations = 0
    
    While sessionActive && settingsIterations < 30 && sessionIterations < MAX_MENU_ITERATIONS
        If IsSessionTimedOut()
            Return
        EndIf
        
        String menuResult = ShowSettingsMenu()
        
        If menuResult == "back"
            Return
        ElseIf menuResult == "toggle"
            ; Setting toggled, continue settings loop
        EndIf
        
        settingsIterations += 1
        sessionIterations += 1
        Utility.Wait(0.1)
    EndWhile
EndFunction

; Show settings menu and return action
String Function ShowSettingsMenu()
    UIListMenu menu = CreateSettingsMenu()
    If !menu
        Return "back"
    EndIf
    
    menu.OpenMenu()
    String choice = menu.GetResultString()
    
    If choice == "[[ Back ]]" || choice == "" || choice == "---"
        Return "back"
    Else
        HandleSettingChoice(choice)
        Return "toggle"
    EndIf
EndFunction

; Create settings menu
UIListMenu Function CreateSettingsMenu()
    UIListMenu menu = UIExtensions.GetMenu("UIListMenu", TRUE) as UIListMenu
    If !menu
        Return None
    EndIf
    
    menu.AddEntryItem("[[ Back ]]")
    menu.AddEntryItem("---")
    
    ; Add setting toggles with current state
    If GetSettingBool("RequireReagents")
        menu.AddEntryItem("[x] Require Runestones")
    Else
        menu.AddEntryItem("[ ] Require Runestones")
    EndIf
    
    If GetSettingBool("BlockInCombat")
        menu.AddEntryItem("[x] Block Recall in Combat")
    Else
        menu.AddEntryItem("[ ] Block Recall in Combat")
    EndIf
    
    If GetSettingBool("RespectFastTravelRestrictions")
        menu.AddEntryItem("[x] Respect Fast Travel Restrictions")
    Else
        menu.AddEntryItem("[ ] Respect Fast Travel Restrictions")
    EndIf
    
    menu.AddEntryItem("---")
    menu.AddEntryItem("Reset All Settings")
    
    Return menu
EndFunction

; Handle setting choice
Function HandleSettingChoice(String choice)
    If StringUtil.Find(choice, "Require Runestones") >= 0
        ToggleSetting("RequireReagents", "Runestones are now ", "required for marking.", "no longer required.")
    ElseIf StringUtil.Find(choice, "Block Recall in Combat") >= 0
        ToggleSetting("BlockInCombat", "Combat blocking is now ", "enabled.", "disabled.")
    ElseIf StringUtil.Find(choice, "Respect Fast Travel Restrictions") >= 0
        ToggleSetting("RespectFastTravelRestrictions", "Fast travel restrictions are now ", "respected.", "ignored.")
    ElseIf choice == "Reset All Settings"
        ResetAllSettings()
    EndIf
EndFunction

; Toggle a setting and show feedback
Function ToggleSetting(String settingName, String prefix, String enabledMsg, String disabledMsg)
    Bool currentValue = GetSettingBool(settingName)
    SetSettingBool(settingName, !currentValue)
    
    If !currentValue
        Debug.Notification(prefix + enabledMsg)
    Else
        Debug.Notification(prefix + disabledMsg)
    EndIf
EndFunction

; Reset all settings to defaults
Function ResetAllSettings()
    SetSettingBool("RequireReagents", True)
    SetSettingBool("BlockInCombat", True)
    SetSettingBool("RespectFastTravelRestrictions", True)
    Debug.Notification("All settings reset to defaults.")
EndFunction

; Setting management functions
Bool Function GetSettingBool(String settingName)
    Int defaultValue = 1
    Return StorageUtil.GetIntValue(None, "Runebook_Setting_" + settingName, defaultValue) as Bool
EndFunction

Function SetSettingBool(String settingName, Bool value)
    StorageUtil.SetIntValue(None, "Runebook_Setting_" + settingName, value as Int)
EndFunction

; Execute rune rename operation
Function ExecuteRename(String oldName)
    String newName = GetNewNameFromUser(oldName)
    If newName != "" && newName != oldName
        ApplyRename(oldName, newName)
    EndIf
EndFunction

; Get new name from user input
String Function GetNewNameFromUser(String currentName)
    UITextEntryMenu textMenu = UIExtensions.GetMenu("UITextEntryMenu", TRUE) as UITextEntryMenu
    If !textMenu
        Return ""
    EndIf
    
    textMenu.SetPropertyString("text", currentName)
    textMenu.OpenMenu()
    Return textMenu.GetResultString()
EndFunction

; Apply rename to rune data
Function ApplyRename(String oldName, String newName)
    Actor player = Game.GetPlayer()
    String uid = FindRuneUIDByName(oldName)
    
    If uid != ""
        StorageUtil.SetStringValue(player, uid + "_Name", newName)
        UpdateSelectedDestinationIfNeeded(oldName, newName)
        Debug.Notification("Rune renamed to: " + newName)
    EndIf
EndFunction

; Update selected destination if it was renamed
Function UpdateSelectedDestinationIfNeeded(String oldName, String newName)
    Actor player = Game.GetPlayer()
    String selectedName = StorageUtil.GetStringValue(player, "Runebook_SelectedName", "")
    
    If selectedName == oldName
        StorageUtil.SetStringValue(player, "Runebook_SelectedName", newName)
    EndIf
EndFunction

; Execute rune deletion
Function ExecuteDelete(String runeName)
    Actor player = Game.GetPlayer()
    String uid = FindRuneUIDByName(runeName)
    
    If uid != ""
        DeleteMarkerAndData(player, uid)
        CompactRuneList()
        ClearSelectedDestinationIfNeeded(runeName)
        Debug.Notification("Rune destroyed: " + runeName)
    EndIf
EndFunction

; Delete marker object and associated data
Function DeleteMarkerAndData(Actor player, String uid)
    ObjectReference marker = StorageUtil.GetFormValue(player, uid + "_Marker") as ObjectReference
    If marker
        marker.Delete()
    EndIf
    
    StorageUtil.UnsetFormValue(player, uid + "_Marker")
    StorageUtil.UnsetStringValue(player, uid + "_Name")
EndFunction

; Clear selected destination if it was deleted
Function ClearSelectedDestinationIfNeeded(String deletedName)
    Actor player = Game.GetPlayer()
    String selectedName = StorageUtil.GetStringValue(player, "Runebook_SelectedName", "")
    
    If selectedName == deletedName
        StorageUtil.UnsetStringValue(player, "Runebook_SelectedDestination")
        StorageUtil.UnsetStringValue(player, "Runebook_SelectedName")
    EndIf
EndFunction

; Find rune UID by display name
String Function FindRuneUIDByName(String runeName)
    Actor player = Game.GetPlayer()
    Int numLocations = StorageUtil.GetIntValue(player, "Runebook_Count", 0)
    
    Int i = 0
    While i < numLocations
        String uid = StorageUtil.GetStringValue(player, "Runebook_" + i)
        String locName = StorageUtil.GetStringValue(player, uid + "_Name")
        If locName == runeName
            Return uid
        EndIf
        i += 1
    EndWhile
    
    Return ""
EndFunction

; Compact rune list after deletions
Function CompactRuneList()
    Actor player = Game.GetPlayer()
    Int numLocations = StorageUtil.GetIntValue(player, "Runebook_Count", 0)
    Int writeIndex = 0
    
    Int i = 0
    While i < numLocations
        String uid = StorageUtil.GetStringValue(player, "Runebook_" + i)
        If uid != ""
            If i != writeIndex
                StorageUtil.SetStringValue(player, "Runebook_" + writeIndex, uid)
                StorageUtil.UnsetStringValue(player, "Runebook_" + i)
            EndIf
            writeIndex += 1
        EndIf
        i += 1
    EndWhile
    
    StorageUtil.SetIntValue(player, "Runebook_Count", writeIndex)
EndFunction
