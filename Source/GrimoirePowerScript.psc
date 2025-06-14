Scriptname GrimoirePowerScript extends ActiveMagicEffect

Book Property RunebookBase Auto

Event OnEffectStart(Actor akTarget, Actor akCaster)
    If akTarget == Game.GetPlayer()
        If ValidateGrimoireRequirements()
            OpenGrimoireSession()  ; Start the continuous session
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

; Main Runebook continuous menu loop
Function OpenGrimoireSession()
    While True
        String menuResult = ShowMainGrimoireMenu()
        
        If menuResult == "close"
            Return  ; Exit the session
        ElseIf menuResult == "manage"
            ShowRuneManagementSession()
        ElseIf menuResult == "settings"
            ShowSettingsSession()
        ElseIf menuResult == "select"
            ; Selection made, continue loop to main menu
            ; (loop will continue automatically)
        EndIf
    EndWhile
EndFunction

; Show main Runebook menu and return action
String Function ShowMainGrimoireMenu()
    Actor player = Game.GetPlayer()
    Int numLocations = StorageUtil.GetIntValue(player, "Runebook_Count", 0)
    
    If numLocations == 0
        Debug.Notification("Thy Runebook contains no runes.")
        Return "close"
    EndIf
    
    UIListMenu menu = CreateMainMenu(player, numLocations)
    If !menu
        Debug.Notification("ERROR: Could not create Runebook menu!")
        Return "close"
    EndIf
    
    menu.OpenMenu()
    String result = menu.GetResultString()
    
    If result == "[[ Close ]]" || result == ""
        Return "close"
    ElseIf result == "[[ Manage Runes ]]"
        Return "manage"
    ElseIf result == "[[ Settings ]]"
        Return "settings"
    Else
        ; Location selected
        String cleanResult = CleanSelectionMarkers(result)
        SetSelectedDestination(cleanResult)
        Return "select"
    EndIf
EndFunction

; Create the main Runebook menu
UIListMenu Function CreateMainMenu(Actor player, Int numLocations)
    UIListMenu menu = UIExtensions.GetMenu("UIListMenu", TRUE) as UIListMenu
    If !menu
        Return None
    EndIf
    
    ; Navigation options
    menu.AddEntryItem("[[ Close ]]")
    menu.AddEntryItem("[[ Manage Runes ]]")
    menu.AddEntryItem("[[ Settings ]]")
    menu.AddEntryItem("---")
    
    ; Location entries
    String currentSelection = StorageUtil.GetStringValue(player, "Runebook_SelectedName", "")
    PopulateLocationEntries(menu, player, numLocations, currentSelection)
    
    Return menu
EndFunction

; Populate menu with location entries
Function PopulateLocationEntries(UIListMenu menu, Actor player, Int numLocations, String currentSelection)
    Int i = 0
    While i < numLocations && i < 20
        String uid = StorageUtil.GetStringValue(player, "Runebook_" + i)
        String locName = StorageUtil.GetStringValue(player, uid + "_Name")
        
        If locName == currentSelection
            menu.AddEntryItem(">>> " + locName + " <<<")
        Else
            menu.AddEntryItem(locName)
        EndIf
        i += 1
    EndWhile
EndFunction

; Remove selection markers from result string
String Function CleanSelectionMarkers(String result)
    If StringUtil.Find(result, ">>> ") == 0
        Return StringUtil.Substring(result, 4, StringUtil.GetLength(result) - 8)
    EndIf
    Return result
EndFunction

; Set the selected destination for recall
Function SetSelectedDestination(String selectedName)
    Actor player = Game.GetPlayer()
    String uid = FindRuneUIDByName(selectedName)
    
    If uid != ""
        StorageUtil.SetStringValue(player, "Runebook_SelectedDestination", uid)
        StorageUtil.SetStringValue(player, "Runebook_SelectedName", selectedName)
        Debug.Notification("Destination chosen.")
    EndIf
EndFunction

; Rune management session
Function ShowRuneManagementSession()
    While True
        String menuResult = ShowRuneManagementMenu()
        
        If menuResult == "back"
            Return  ; Return to main menu
        ElseIf menuResult == "action"
            ; Action completed, continue management loop
            ; (loop will continue automatically)
        EndIf
    EndWhile
EndFunction

; Show rune management menu and return action
String Function ShowRuneManagementMenu()
    Actor player = Game.GetPlayer()
    Int numLocations = StorageUtil.GetIntValue(player, "Runebook_Count", 0)
    
    If numLocations == 0
        Debug.Notification("No runes to manage.")
        Return "back"
    EndIf
    
    UIListMenu menu = CreateManagementMenu(player, numLocations)
    If !menu
        Return "back"
    EndIf
    
    menu.OpenMenu()
    String selectedRune = menu.GetResultString()
    
    If selectedRune == "[[ Back ]]" || selectedRune == ""
        Return "back"
    Else
        ShowRuneActionsLoop(selectedRune)
        Return "action"  ; Continue management after action
    EndIf
EndFunction

; Create rune management menu
UIListMenu Function CreateManagementMenu(Actor player, Int numLocations)
    UIListMenu menu = UIExtensions.GetMenu("UIListMenu", TRUE) as UIListMenu
    If !menu
        Return None
    EndIf
    
    menu.AddEntryItem("[[ Back ]]")
    menu.AddEntryItem("---")
    
    Int i = 0
    While i < numLocations && i < 20
        String uid = StorageUtil.GetStringValue(player, "Runebook_" + i)
        String locName = StorageUtil.GetStringValue(player, uid + "_Name")
        menu.AddEntryItem(locName)
        i += 1
    EndWhile
    
    Return menu
EndFunction

; Rune actions loop for specific rune
Function ShowRuneActionsLoop(String runeName)
    While True
        String menuResult = ShowRuneActionMenu(runeName)
        
        If menuResult == "back"
            Return  ; Back to management menu
        ElseIf menuResult == "rename"
            ExecuteRename(runeName)
            Return  ; Back to management after rename
        ElseIf menuResult == "delete"
            ExecuteDelete(runeName)
            Return  ; Back to management after delete
        EndIf
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
    While True
        String menuResult = ShowSettingsMenu()
        
        If menuResult == "back"
            Return  ; Return to main menu
        ElseIf menuResult == "toggle"
            ; Setting toggled, continue settings loop
            ; (loop will continue automatically)
        EndIf
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
    
    If choice == "[[ Back ]]" || choice == ""
        Return "back"
    Else
        HandleSettingChoice(choice)
        Return "toggle"  ; Continue settings loop
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
    Debug.Notification("All settings reset to defaults.")
EndFunction

; Setting management functions
Bool Function GetSettingBool(String settingName)
    ; Default values for each setting
    Int defaultValue = 1  ; True by default for both settings
    
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