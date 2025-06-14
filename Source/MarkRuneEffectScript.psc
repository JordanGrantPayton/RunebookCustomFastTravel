Scriptname MarkRuneEffectScript extends ActiveMagicEffect

Quest Property MarkQuest Auto

Event OnEffectStart(Actor akTarget, Actor akCaster)
    If akTarget == Game.GetPlayer()
        ; Cast animation is complete, execute immediately
        If ValidateSpellRequirements()
            ExecuteMarkSpell()
        EndIf
    EndIf
EndEvent

; Validate spell requirements and dependencies
Bool Function ValidateSpellRequirements()
    If !ValidateProperties()
        Return False
    EndIf
    
    If !ValidateQuestScript()
        Return False
    EndIf
    
    Return True
EndFunction

; Validate required properties are set
Bool Function ValidateProperties()
    If !MarkQuest
        Debug.Notification("ERROR: MarkQuest Property not set!")
        Return False
    EndIf
    
    Return True
EndFunction

; Validate quest script is correct type and accessible
Bool Function ValidateQuestScript()
    RunebookMarkQuest questScript = MarkQuest as RunebookMarkQuest
    If !questScript
        Debug.Notification("ERROR: Mark quest script not found or wrong type!")
        Return False
    EndIf
    
    Return True
EndFunction

; Execute the mark spell
Function ExecuteMarkSpell()
    RunebookMarkQuest questScript = MarkQuest as RunebookMarkQuest
    questScript.StartMarkProcess()
EndFunction