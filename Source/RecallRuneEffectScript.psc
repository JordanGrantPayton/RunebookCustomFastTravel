Scriptname RecallRuneEffectScript extends ActiveMagicEffect

Book Property RunebookBase Auto

Event OnEffectStart(Actor akTarget, Actor akCaster)
    If akTarget == Game.GetPlayer()
        ; Cast animation is complete, execute immediately
        If ValidateRecallRequirements(akTarget)
            ExecuteRecall(akTarget)
        EndIf
    EndIf
EndEvent

; Validation
Bool Function ValidateRecallRequirements(Actor player)
    If !ValidateProperties()
        Return False
    EndIf
    
    If !ValidatePlayerState(player)
        Return False
    EndIf
    
    If !ValidateDestination(player)
        Return False
    EndIf
    
    ; NEW: Check fast travel restrictions (if setting enabled)
    If !CanUseRunebookTravel(player)
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

; Validate player state
Bool Function ValidatePlayerState(Actor player)
    ; Check combat status (if enabled)
    If GetSettingBool("BlockInCombat")
        If player.IsInCombat()
            Debug.Notification("Wouldst thou flee during the heat of battle?")
            Return False
        EndIf
    EndIf
    
    ; Check for Runebook
    If player.GetItemCount(RunebookBase) <= 0
        Debug.Notification("Thou dost need a Runebook!")
        Return False
    EndIf
    
    ; Check for any marked locations
    Int numLocations = StorageUtil.GetIntValue(player, "Runebook_Count", 0)
    If numLocations == 0
        Debug.Notification("Thy Runebook contains no runes.")
        Return False
    EndIf
    
    Return True
EndFunction

; Validate selected destination exists and is accessible
Bool Function ValidateDestination(Actor player)
    String selectedUID = StorageUtil.GetStringValue(player, "Runebook_SelectedDestination", "")
    If selectedUID == ""
        Debug.Notification("Choose thy destination from the Runebook's pages")
        Return False
    EndIf
    
    ObjectReference marker = GetValidMarker(player, selectedUID)
    If !marker
        Return False
    EndIf
    
    Return True
EndFunction

; Check fast travel restrictions
Bool Function CanUseRunebookTravel(Actor player)
    ; Check user settings
    If GetSettingBool("RespectFastTravelRestrictions")
        ; User wants restrictions, check game state
        If !Game.IsFastTravelEnabled()
            Debug.Notification("The threads of fate bind thee to this moment.")
            Return False
        EndIf
    EndIf
    
    ; Either restrictions are disabled, or fast travel is allowed
    Return True
EndFunction

; Get marker reference and validate it exists
ObjectReference Function GetValidMarker(Actor player, String selectedUID)
    Form markerForm = StorageUtil.GetFormValue(player, selectedUID + "_Marker")
    If !markerForm
        Debug.Notification("The marked location hath faded from memory")
        ClearInvalidSelection(player)
        Return None
    EndIf

    ObjectReference mapMarker = markerForm as ObjectReference
    If !mapMarker
        Debug.Notification("The marked location hath faded from memory")
        ClearInvalidSelection(player)
        Return None
    EndIf

    If mapMarker.IsDeleted()
        Debug.Notification("The marked location hath faded from memory")
        ClearInvalidSelection(player)
        Return None
    EndIf
    
    Return mapMarker
EndFunction

; Clear invalid destination selection
Function ClearInvalidSelection(Actor player)
    StorageUtil.UnsetStringValue(player, "Runebook_SelectedDestination")
    StorageUtil.UnsetStringValue(player, "Runebook_SelectedName")
EndFunction

; Execute the recall teleportation
Function ExecuteRecall(Actor player)
    String selectedUID = StorageUtil.GetStringValue(player, "Runebook_SelectedDestination", "")
    ObjectReference marker = GetValidMarker(player, selectedUID)
    
    If marker
        player.MoveTo(marker)
    EndIf
EndFunction

; Setting management function
Bool Function GetSettingBool(String settingName)
    ; Default values for each setting
    Int defaultValue = 1
    
    Return StorageUtil.GetIntValue(None, "Runebook_Setting_" + settingName, defaultValue) as Bool
EndFunction
