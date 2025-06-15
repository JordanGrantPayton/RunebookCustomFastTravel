Scriptname RunebookMarkQuest extends Quest

Actor Property PlayerRef Auto
MiscObject Property RunestoneBlank Auto
Book Property RunebookBase Auto
Static Property MapMarkerStatic Auto

; Constants for safety
Int Property MAX_RUNE_LIMIT = 20 Auto
Int Property MAX_RETRY_ATTEMPTS = 3 Auto

; Track created markers for cleanup
ObjectReference[] recentMarkers

Function StartMarkProcess()
    If !PlayerRef
        PlayerRef = Game.GetPlayer()
    EndIf
    
    If ValidateMarkRequirements()
        String autoName = GetNextSequentialName()
        If CreateLocationSafely(autoName)
            Debug.Notification("The rune resonates with this location's essence.")
        Else
            Debug.Notification("Failed to create rune marker.")
        EndIf
    EndIf
EndFunction

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
    
    If !ValidateLocation()
        Return False
    EndIf
    
    Return True
EndFunction

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

Bool Function ValidatePlayerState()
    If PlayerRef.GetItemCount(RunebookBase) <= 0
        Debug.Notification("Thou dost need a Runebook to store thy markings!")
        Return False
    EndIf
    
    If GetSettingBool("RequireReagents")
        If PlayerRef.GetItemCount(RunestoneBlank) <= 0
            Debug.Notification("Thou dost not possess a Runestone!")
            Return False
        EndIf
    EndIf
    
    Return True
EndFunction

Bool Function ValidateRuneLimit()
    Int currentCount = GetValidRuneCount()
    If currentCount >= MAX_RUNE_LIMIT
        Debug.Notification("Thy Runebook cannot hold more than twenty runes.")
        Return False
    EndIf
    
    Return True
EndFunction

; New validation for location suitability
Bool Function ValidateLocation()
    ; Check if player is in a valid location for marking
    If PlayerRef.IsInInterior()
        Cell currentCell = PlayerRef.GetParentCell()
        If currentCell && currentCell.IsInterior()
            ; Allow interior marking but warn about potential issues
            ; Could add specific interior restrictions here if needed
        EndIf
    EndIf
    
    ; Check for nearby existing markers to prevent clustering
    If HasNearbyMarker(128.0)  ; 128 units radius
        Debug.Notification("Another rune resonates too closely to this location.")
        Return False
    EndIf
    
    Return True
EndFunction

; Check for nearby existing markers
Bool Function HasNearbyMarker(Float radius)
    Int currentCount = StorageUtil.GetIntValue(PlayerRef, "Runebook_Count", 0)
    Float playerX = PlayerRef.GetPositionX()
    Float playerY = PlayerRef.GetPositionY()
    Float playerZ = PlayerRef.GetPositionZ()
    
    Int i = 0
    While i < currentCount
        String uid = StorageUtil.GetStringValue(PlayerRef, "Runebook_" + i)
        If uid != ""
            ObjectReference marker = StorageUtil.GetFormValue(PlayerRef, uid + "_Marker") as ObjectReference
            If marker && !marker.IsDeleted()
                Float distance = Math.sqrt(Math.pow(playerX - marker.GetPositionX(), 2) + \
                                         Math.pow(playerY - marker.GetPositionY(), 2) + \
                                         Math.pow(playerZ - marker.GetPositionZ(), 2))
                If distance < radius
                    Return True
                EndIf
            EndIf
        EndIf
        i += 1
    EndWhile
    
    Return False
EndFunction

; Get actual count of valid runes (cleaning up invalid ones)
Int Function GetValidRuneCount()
    Int storedCount = StorageUtil.GetIntValue(PlayerRef, "Runebook_Count", 0)
    Int validCount = 0
    
    Int i = 0
    While i < storedCount
        String uid = StorageUtil.GetStringValue(PlayerRef, "Runebook_" + i)
        If uid != ""
            ; Check if marker still exists
            ObjectReference marker = StorageUtil.GetFormValue(PlayerRef, uid + "_Marker") as ObjectReference
            If marker && !marker.IsDeleted()
                validCount += 1
            Else
                ; Clean up invalid entry
                CleanupInvalidRune(i)
            EndIf
        EndIf
        i += 1
    EndWhile
    
    ; Update stored count if it changed
    If validCount != storedCount
        StorageUtil.SetIntValue(PlayerRef, "Runebook_Count", validCount)
    EndIf
    
    Return validCount
EndFunction

; Clean up invalid rune entry
Function CleanupInvalidRune(Int index)
    String uid = StorageUtil.GetStringValue(PlayerRef, "Runebook_" + index)
    If uid != ""
        StorageUtil.UnsetFormValue(PlayerRef, uid + "_Marker")
        StorageUtil.UnsetStringValue(PlayerRef, uid + "_Name")
        StorageUtil.UnsetStringValue(PlayerRef, "Runebook_" + index)
    EndIf
EndFunction

String Function GetNextSequentialName()
    Int validCount = GetValidRuneCount()
    Int nextNumber = validCount + 1
    Return "Marked Location " + nextNumber
EndFunction

; Safe creation with retry logic and validation
Bool Function CreateLocationSafely(String locName)
    Int attempts = 0
    
    While attempts < MAX_RETRY_ATTEMPTS
        String runeUID = GenerateUniqueUID()
        
        ; Create marker with error checking
        ObjectReference mapMarker = CreateMarkerSafely()
        If !mapMarker
            attempts += 1
            Utility.Wait(0.1)
        Else
            ; Configure marker
            If !ConfigureMarker(mapMarker)
                mapMarker.Delete()
                attempts += 1
                Utility.Wait(0.1)
            Else
                ; Store data atomically
                If !StoreLocationData(runeUID, locName, mapMarker)
                    mapMarker.Delete()
                    attempts += 1
                    Utility.Wait(0.1)
                Else
                    ; Success - consume reagent if required
                    If GetSettingBool("RequireReagents")
                        PlayerRef.RemoveItem(RunestoneBlank, 1, true)
                    EndIf
                    
                    ; Track for cleanup
                    TrackCreatedMarker(mapMarker)
                    
                    Return True
                EndIf
            EndIf
        EndIf
        
        attempts += 1
    EndWhile
    
    Return False
EndFunction

; Generate unique UID with collision detection
String Function GenerateUniqueUID()
    String uid = ""
    Int attempts = 0
    
    While attempts < 100  ; Prevent infinite loop
        uid = "Rune_" + Utility.RandomInt(100000, 999999)
        
        ; Check if UID already exists
        Form existingMarker = StorageUtil.GetFormValue(PlayerRef, uid + "_Marker")
        If !existingMarker
            Return uid
        EndIf
        
        attempts += 1
    EndWhile
    
    ; Fallback to timestamp-based UID
    Return "Rune_" + (Utility.GetCurrentGameTime() * 1000000) as Int
EndFunction

; Safe marker creation
ObjectReference Function CreateMarkerSafely()
    ObjectReference marker = PlayerRef.PlaceAtMe(MapMarkerStatic, 1, false, true)
    If marker
        Return marker
    Else
        Return None
    EndIf
EndFunction

; Configure marker properties
Bool Function ConfigureMarker(ObjectReference marker)
    If !marker
        Return False
    EndIf
    
    marker.SetPosition(PlayerRef.GetPositionX(), PlayerRef.GetPositionY(), PlayerRef.GetPositionZ())
    marker.SetAngle(0.0, 0.0, PlayerRef.GetAngleZ())
    marker.Disable(False)  ; Make invisible but keep in memory
    marker.SetMotionType(4, False)  ; Make static
    Return True
EndFunction

; Atomic data storage
Bool Function StoreLocationData(String runeUID, String locName, ObjectReference mapMarker)
    If !mapMarker
        Return False
    EndIf
    
    ; Store marker and name
    StorageUtil.SetFormValue(PlayerRef, runeUID + "_Marker", mapMarker)
    StorageUtil.SetStringValue(PlayerRef, runeUID + "_Name", locName)
    
    ; Add to master list
    Int numLocations = StorageUtil.GetIntValue(PlayerRef, "Runebook_Count", 0)
    StorageUtil.SetStringValue(PlayerRef, "Runebook_" + numLocations, runeUID)
    StorageUtil.SetIntValue(PlayerRef, "Runebook_Count", numLocations + 1)
    
    Return True
EndFunction

; Track created markers for potential cleanup
Function TrackCreatedMarker(ObjectReference marker)
    If !recentMarkers
        recentMarkers = new ObjectReference[10]
    EndIf
    
    ; Add to tracking array (simple circular buffer)
    Int i = 0
    While i < recentMarkers.Length
        If !recentMarkers[i]
            recentMarkers[i] = marker
            Return
        EndIf
        i += 1
    EndWhile
    
    ; Array full, replace oldest
    recentMarkers[0] = marker
EndFunction

; Emergency cleanup function
Function EmergencyCleanup()
    If recentMarkers
        Int i = 0
        While i < recentMarkers.Length
            If recentMarkers[i] && !recentMarkers[i].IsDeleted()
                recentMarkers[i].Delete()
            EndIf
            recentMarkers[i] = None
            i += 1
        EndWhile
    EndIf
EndFunction

Bool Function GetSettingBool(String settingName)
    Int defaultValue = 1
    Return StorageUtil.GetIntValue(None, "Runebook_Setting_" + settingName, defaultValue) as Bool
EndFunction
