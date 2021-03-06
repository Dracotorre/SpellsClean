Scriptname DTSC_ConfigScript extends ActiveMagicEffect  

; Spells Clean 
; version 2
;
; configuration menus - 2 sub-menus, 1 for extras and 1 for timer

Actor property PlayerREF auto
ReferenceAlias property KeepCleanQuestAlias auto

; menu messages
Message property DTSC_ConfigMessage auto
Message property DTSC_ConfigExtrasMsg auto
Message property DTSC_ConfigTimerMessage auto
Message property DTSC_ConfigAddCustomSpellMsg auto

; to report on main menu
GlobalVariable property DTSC_Version auto
GlobalVariable property DTSC_ModMonCount auto
GlobalVariable property DTSC_CaptureLimit auto

; settings to set
GlobalVariable property DTSC_DisableSetting auto
GlobalVariable property DTSC_RecheckModsSetting auto
GlobalVariable property DTSC_VerboseSetting auto
GlobalVariable property DTSC_CampFrostExtras auto    ; not currently used
GlobalVariable property DTSC_WLToggleSettings auto
GlobalVariable property DTSC_iNeedSetting auto
GlobalVariable property DTSC_IncludeItemsSetting auto
GlobalVariable property DTSC_WaitSecondsSetting auto
GlobalVariable property DTSC_CaptureSpellAdd auto
{ signals if ready to capture spells }

GlobalVariable property DTSC_HasItemsCustom auto
GlobalVariable property DTSC_ConfigSpellRemDelay auto  ; added v2.42

Spell property DTSC_ConfigSpell auto
FormList property DTSC_SpellsExtraList auto
FormList property DTSC_ArmorsExtraList auto

bool property HideOnExit auto hidden

Event OnEffectStart(Actor akTarget, Actor akCaster)
	;Debug.Trace("[DTSC] OnEffectStart")
	if (akCaster == PlayerREF)
		DTSC_CaptureSpellAdd.SetValue(0.0)
		HideOnExit = true
		
		Menu()
	endIf
EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
	;Debug.Trace("[DTSC] OnEffectFinish")
	Utility.Wait(0.5)
	if (akCaster == PlayerREF && HideOnExit && DTSC_ConfigSpellRemDelay.GetValue() < 1.20)
		
		PlayerREF.RemoveSpell(DTSC_ConfigSpell)
	endIf
EndEvent
 
; see tutorial: https://www.creationkit.com/index.php?title=Options_Menu

Function Menu(int aiMessage = 0, int aiButton = 0, bool abMenu = true)
	while abMenu
		if (aiMessage == 0)
			aiButton = DTSC_ConfigMessage.Show(DTSC_Version.GetValue(), DTSC_ModMonCount.GetValue())
			if (aiButton == 0)
				DTSC_DisableSetting.SetValueInt(1)
				abMenu = false
			elseIf (aiButton == 1)
				DTSC_DisableSetting.SetValueInt(0)
			elseIf (aiButton == 2)
				DTSC_RecheckModsSetting.SetValueInt(1)
			elseIf (aiButton == 3)
				DTSC_VerboseSetting.SetValueInt(1)
			elseIf (aiButton == 4)
				DTSC_VerboseSetting.SetValueInt(0)
			elseIf (aiButton == 5)
				aiMessage = 1
			elseIf (aiButton == 6)
				aiMessage = 2
			elseIf (aiButton == 7)
				aiMessage = 3
			else
				abMenu = false
			endIf
		elseIf (aiMessage == 1)
			int biButton = DTSC_ConfigExtrasMsg.Show()
			
			if (biButton == 0)
				aiMessage = 0
			elseIf (biButton == 1)
				DTSC_WLToggleSettings.SetValueInt(1)
			elseIf (biButton == 2)
				DTSC_WLToggleSettings.SetValueInt(0)
			elseIf (biButton == 3)
				DTSC_iNeedSetting.SetValueInt(1)
			elseIf (biButton == 4)
				DTSC_iNeedSetting.SetValueInt(0)
			elseIf (biButton == 5)
				DTSC_IncludeItemsSetting.SetValueInt(1)
			elseIf (biButton == 6)
				DTSC_IncludeItemsSetting.SetValueInt(0)
			endIf
		elseIf (aiMessage == 2)
			int ciButton = DTSC_ConfigTimerMessage.Show(DTSC_WaitSecondsSetting.GetValue() + 6.0)
			aiMessage = 0
			
			if (ciButton == 1)
				DTSC_WaitSecondsSetting.SetValueInt(12)
			elseIf (ciButton == 2)
				DTSC_WaitSecondsSetting.SetValueInt(24)
			elseIf (ciButton == 3)
				DTSC_WaitSecondsSetting.SetValueInt(54)
			elseIf (ciButton == 4)
				DTSC_WaitSecondsSetting.SetValueInt(234)
			endIf
		elseIf (aiMessage == 3)
			ValidateCaptureLimit()
			
			int diButton = DTSC_ConfigAddCustomSpellMsg.Show(DTSC_CaptureLimit.GetValue(), DTSC_SpellsExtraList.GetSize(), DTSC_ArmorsExtraList.GetSize())
			aiMessage = 0
			
			if (diButton == 0)
				DTSC_CaptureSpellAdd.SetValue(0.0)
			elseIf (diButton == 1)
				float capTime = Utility.GetCurrentGameTime()  ; v2.08
				;Debug.Trace("[DTSC] menu AddSpell capTime: " + capTime)
				DTSC_CaptureSpellAdd.SetValue(capTime)
				
				; grant bonus time before removing spell - v2.42
				float extraTime = 12.0 + DTSC_ConfigSpellRemDelay.GetValue()
				DTSC_ConfigSpellRemDelay.SetValue(extraTime)
				
				HideOnExit = false
				abMenu = false
			elseIf (diButton == 2)
				DTSC_CaptureSpellAdd.SetValue(0.0)
				(KeepCleanQuestAlias as DTSC_PlayerAliasScript).RecoverCustomArmors()
				(KeepCleanQuestAlias as DTSC_PlayerAliasScript).RecoverCustomSpells()
			endIf
		endIf
	endWhile
EndFunction



Function ValidateCaptureLimit()
	int capLimit = DTSC_CaptureLimit.GetValueInt()
		
	if (capLimit > 100)
		DTSC_CaptureLimit.SetValueInt(100)
	elseIf (capLimit < 1)
		DTSC_CaptureLimit.SetValueInt(1)
	endIf
EndFunction