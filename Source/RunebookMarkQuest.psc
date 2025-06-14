Scriptname RunebookMarkQuest extends Quest

Actor Property PlayerRef Auto
MiscObject Property RunestoneBlank Auto
Book Property RunebookBase Auto
Static Property MapMarkerStatic Auto

; Main entry point for marking locations
Function StartMarkProcess()
    ; Ensure PlayerRef is set
    If !PlayerRef
        PlayerRef = Game.GetPlayer()
    EndIf
    
    If ValidateMarkRequirements()
        String autoName = GetNextSequentialName()
        CreateLocation(autoName)
    EndIf
EndFunction

; Consolidated validation
Bool Function ValidateMarkRequirements()
    If !ValidateProperties()
        Return False
    EndIf
    
    If !ValidatePlayerState()
        Return False
    EndIf
    
    If !ValidateRuneLimit()
        Return False
    EndIf
    
    Return True
EndFunction

; Validate all required properties
Bool Function ValidateProperties()
    If !RunebookBase
        Debug.Notification("ERROR: RunebookBase Property not set!")
        Return False
    EndIf
    
    If !RunestoneBlank
        Debug.Notification("ERROR: RunestoneBlank Property not set!")
        Return False
    EndIf
    
    If !MapMarkerStatic
        Debug.Notification("ERROR: MapMarkerStatic Property not set!")
        Return False
    EndIf
    
    Return True
EndFunction

; Validate player has required items
Bool Function ValidatePlayerState()
    ; Check for Runebook
    If PlayerRef.GetItemCount(RunebookBase) <= 0
        Debug.Notification("Thou dost need a Runebook to store thy markings!")
        Return False
    EndIf
    
    ; Check for blank runestone (if required by settings)
    If GetSettingBool("RequireReagents")
        If PlayerRef.GetItemCount(RunestoneBlank) <= 0
            Debug.Notification("Thou dost not possess a Runestone!")
            Return False
        EndIf
    EndIf
    
    Return True
EndFunction

; Validate rune limit
Bool Function ValidateRuneLimit()
    Int currentCount = StorageUtil.GetIntValue(PlayerRef, "Runebook_Count", 0)
    If currentCount >= 20
        Debug.Notification("Thy Runebook cannot hold more than twenty runes.")
        Return False
    EndIf
    
    Return True
EndFunction

; Alternative entry point for validated creation
Function CreateMarkLocation()
    If ValidateMarkRequirements()
        String autoName = GetNextSequentialName()
        CreateLocation(autoName)
    EndIf
EndFunction

; Generate sequential location name
String Function GetNextSequentialName()
    Int currentCount = StorageUtil.GetIntValue(PlayerRef, "Runebook_Count", 0)
    Int nextNumber = currentCount + 1
    Return "Marked Location " + nextNumber
EndFunction

; Create the marked location
Function CreateLocation(String locName)
    ; Generate unique ID for this location
    String runeUID = "Rune_" + Utility.RandomInt(100000, 999999)
    
    ; Create map marker at player location
    ObjectReference mapMarker = PlayerRef.PlaceAtMe(MapMarkerStatic, 1, false, true)
    mapMarker.SetPosition(PlayerRef.GetPositionX(), PlayerRef.GetPositionY(), PlayerRef.GetPositionZ())
    mapMarker.SetAngle(0.0, 0.0, PlayerRef.GetAngleZ())
    
    ; Make it invisible but persistent
    mapMarker.Disable(False)
    mapMarker.SetMotionType(4, False)
    
    ; Store in Runebook system
    StorageUtil.SetFormValue(PlayerRef, runeUID + "_Marker", mapMarker)
    StorageUtil.SetStringValue(PlayerRef, runeUID + "_Name", locName)
    
    ; Add to master list of marked locations
    Int numLocations = StorageUtil.GetIntValue(PlayerRef, "Runebook_Count", 0)
    StorageUtil.SetStringValue(PlayerRef, "Runebook_" + numLocations, runeUID)
    StorageUtil.SetIntValue(PlayerRef, "Runebook_Count", numLocations + 1)
    
    ; Consume the blank runestone (if required by settings)
    If GetSettingBool("RequireReagents")
        PlayerRef.RemoveItem(RunestoneBlank, 1, true)
    EndIf
    
    Debug.Notification("The rune resonates with this location's essence.")
EndFunction

; Setting management function
Bool Function GetSettingBool(String settingName)
    ; Default values for each setting (both default to True)
    Int defaultValue = 1
    
    Return StorageUtil.GetIntValue(None, "Runebook_Setting_" + settingName, defaultValue) as Bool
EndFunction