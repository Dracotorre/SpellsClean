Scriptname DTSC_KeepCleanScript extends Quest

Quest property MQ101Quest auto
ReferenceAlias property DTSC_PlayerAliasScriptP auto
Message property DTSC_StartDelayMessage auto

int property UpdateStep auto hidden

Event OnLoad()
	self.OnInit()
endEvent

Event OnInit()
	if (UpdateStep < 1)
		UpdateStep = 1
		RegisterForSingleUpdate(4.0)
	endIf
endEvent

Event OnUpdate()
	if (MQ101Quest.IsCompleted())
		if (Game.IsFightingControlsEnabled())
			if (UpdateStep == 1)
				(DTSC_PlayerAliasScriptP as DTSC_PlayerAliasScript).ManageMod()

				UpdateStep = 2
				
				RegisterForSingleUpdate(3.0)
			elseIf (UpdateStep == 2)
				(DTSC_PlayerAliasScriptP as DTSC_PlayerAliasScript).CleanSpells()
				Utility.Wait(0.5)
				(DTSC_PlayerAliasScriptP as DTSC_PlayerAliasScript).ActivateConfig()
				UpdateStep = 3
			endIf
		elseIf (UpdateStep > 1)
			RegisterForSingleUpdate(3.0)
		else
			DTSC_StartDelayMessage.Show()
		endIf
	else
		DTSC_StartDelayMessage.Show()
	endIf
	; else let the next OnPlayerLoadGame handle
endEvent 
