Scriptname DTSC_PlayerAliasScript extends ReferenceAlias 

; Spells Clean 
; by DracoTorre
; version 2
;
; Shows all select spells (restores if needed) until DTSC_WaitSecondsSetting
; then removes spells unless DTSC_DisableSetting > 0 or DTSC_RestoreAllSpells > 0.
;
; DT_SpellsClean.esp
;
; http://www.dracotorre.com/mods/spellsclean/
; https://www.nexusmods.com/skyrimspecialedition/mods/14776


Actor property PlayerRef auto
Quest property MQ101Quest auto
Keyword property ArmorJewelryKY auto
Keyword property ClothingRingKY auto

Message property DTSC_CleanTotalMsg auto
Message property DTSC_CustomSpellAddedMsg auto
Message property DTSC_CustomExceptionMsg auto
Message property DTSC_CustomExistsMsg auto
Message property DTSC_CustomArmorAddedMsg auto
Message property DTSC_InitMessage auto
Message property DTSC_ConfirmRemoveMsg auto
Spell property DTSC_ConfigSpell auto
GlobalVariable property DTSC_HasItemsMod auto
GlobalVariable property DTSC_CaptureSpellAdd auto
GlobalVariable property DTSC_InitOptions auto
GlobalVariable property DTSC_ModMonCount auto
GlobalVariable property DTSC_HasItemsCustom auto
FormList property DTSC_SpellsExtraList auto
FormList property DTSC_ArmorsExtraList auto
FormList property DTSC_ExtraExceptionList auto 

; constants
GlobalVariable property DTSC_DisableAll auto
GlobalVariable property DTSC_RestoreAllSpells auto
GlobalVariable property DTSC_WaitSecondsToCheck auto  ; default
GlobalVariable property DTSC_Version auto
GlobalVariable property DTSC_VersionPrior auto
GlobalVariable property DTSC_Verbose auto
GlobalVariable property DTSC_WearableLantToggles auto ; now use WL setting
GlobalVariable property DTSC_IsXB1 auto  ; skip if Xbox
GlobalVariable property DTSC_CaptureLimit auto

; settings
GlobalVariable property DTSC_VerboseSetting auto
GlobalVariable property DTSC_RecheckModsSettings auto
GlobalVariable property DTSC_DisableSetting auto
GlobalVariable property DTSC_IncludeItemsSetting auto
GlobalVariable property DTSC_MCMSetting auto
GlobalVariable property DTSC_WLToggleSetting auto
GlobalVariable property DTSC_iNeedSetting auto
GlobalVariable property DTSC_CampFrostExtras auto
GlobalVariable property DTSC_WaitSecondsSetting auto

; mods -- 0 = skip, 1 = process -- saved
GlobalVariable property DTSC_CampFrostOps auto
GlobalVariable property DTSC_WearableLantConfig auto
GlobalVariable property DTSC_ImmersiveCitz auto
GlobalVariable property DTSC_FlowerGirls auto
GlobalVariable property DTSC_MoonlightTales auto
GlobalVariable property DTSC_FacelightReset auto
GlobalVariable property DTSC_HunterbornConfig auto
GlobalVariable property DTSC_BetterVampConfig auto
GlobalVariable property DTSC_WetAndColdConfig auto
GlobalVariable property DTSC_iNeedAction auto
GlobalVariable property DTSC_WildcatConfig auto
GlobalVariable property DTSC_UnreadBooksGlow auto
GlobalVariable property DTSC_VigorCI auto
GlobalVariable property DTSC_SmilodonConf auto
GlobalVariable property DTSC_DeadlyCombatConf auto
GlobalVariable property DTSC_NATSet auto

int property CleanTaskOption auto hidden
{2 = restore, 1 = remove}

bool recheckExclusions = false  ; v2.30 - in case more exclusions have been added in update
int captureCount = 0  ;v2.10
float lastCaptureTime = 0.0     ; game-time
float lastSpellAddedTime = 0.0  ;v2.25 real-tikme for equip too fast such as auto-equip other hand

; ************************** Events *******************

Event OnPlayerLoadGame()
	UnregisterForUpdate()
	ManageMod()
		
	; first update restores all spells
	CleanTaskOption = 2
	
	RegisterForSingleUpdate(2.4)
EndEvent

Event OnUpdate()

	if (Game.IsFightingControlsEnabled())
		; only process if enabled or restoring
		if (DTSC_DisableAll.GetValue() <= 0.0)
			int doRestore = DTSC_RestoreAllSpells.GetValueInt()
			
			; always restore
			if (DTSC_DisableSetting.GetValue() < 1 || doRestore > 0 || CleanTaskOption == 2)
				CleanSpells()
			endIf
			
			if (CleanTaskOption == 2 && doRestore < 1)
			
				; remove spells on next update
				CleanTaskOption = 1
				float waitSecs = DTSC_WaitSecondsSetting.GetValue()
				if (waitSecs > 300.0 || waitSecs <= 0.0)
					waitSecs = DTSC_WaitSecondsToCheck.GetValue()
				endIf
				if (waitSecs < 8.0)
					waitSecs = 8.0
				endIf
				
				ActivateConfig()
				RegisterForSingleUpdate(waitSecs)
			endIf
		endIf
	else
		; no fight controls - try later
		RegisterForSingleUpdate(12.0)
	endIf
EndEvent

; use to capture custom spells and armors 
Event OnObjectEquipped(Form akBaseObject, ObjectReference akReference)
	if (akBaseObject && akBaseObject as Spell && akBaseObject == DTSC_ConfigSpell)
		return
	endIf
	float captureTime = DTSC_CaptureSpellAdd.GetValue()
	; wait a fraction to ensure timing -v2.06
	Utility.WaitMenuMode(0.4)  ;v2.10 changed from Wait to menu-mode so don't need to close menu
	
	if (akBaseObject && captureTime > 0.0)
		if (captureTime > lastCaptureTime)
			captureCount = 0
			lastCaptureTime = captureTime
		endIf
		
		float curRealTime = Utility.GetCurrentRealTime()
		float secSinceLastAdd = curRealTime - lastSpellAddedTime
		lastSpellAddedTime = curRealTime
		if (secSinceLastAdd < 0.33)
			; v2.25
			;Debug.Trace("[DTSC] equip too fast")
			return
		endIf
		
		float curTime = Utility.GetCurrentGameTime()
		float minDiff = DTSC_CommonF.GetGameTimeHoursDifference(curTime, captureTime) * 60.0
		
		;Debug.Trace("[DTSC] minDiff " + minDiff)
		; v2.08 added more time allowance (pauses in menu) - 1.67 minutes game-time is 5 seconds real-time
		if (minDiff < 1.667 && captureCount < DTSC_CaptureLimit.GetValueInt())
			if (DTSC_ExtraExceptionList.HasForm(akBaseObject))
				if (DTSC_VerboseSetting.GetValueInt() > 0)
					Utility.WaitMenuMode(0.25)    ; v2.10
					DTSC_CustomExceptionMsg.Show()
				endIf
				return
			endIf
			
			if (akBaseObject as Spell)
				AddCustomSpell(akBaseObject)
				
			elseIf (akBaseObject as Armor)
				if (AddCustomArmor(akBaseObject) > 0)
					if (DTSC_HasItemsMod.GetValueInt() < 1)
						DTSC_IncludeItemsSetting.SetValueInt(1)
					endIf
				endIf
			endIf
		else
			DTSC_CaptureSpellAdd.SetValue(0.0)
			captureCount = 0
		endIf	
	else
		captureCount = 0
	endIf
endEvent

; ***************************  Functions ******************

Function ActivateConfig()
	if (DTSC_MCMSetting.GetValueInt() < 1 && !PlayerRef.HasSpell(DTSC_ConfigSpell))
		;Debug.Trace("[DTSC] add config spell: " + DTSC_ConfigSpell)
		PlayerRef.AddSpell(DTSC_ConfigSpell, false)
		if (DTSC_InitOptions.GetValueInt() <= 0)
			DTSC_InitOptions.SetValueInt(1)
			DTSC_InitMessage.Show(DTSC_ModMonCount.GetValue())
		endIf
	endIf
endFunction

int Function AddCustomArmor(Form baseArmor)
	if (baseArmor.HasKeyword(ClothingRingKY) || baseArmor.HasKeyword(ArmorJewelryKY))
		
		if (!DTSC_ArmorsExtraList.HasForm(baseArmor))
			captureCount += 1
			DTSC_ArmorsExtraList.AddForm(baseArmor)
			DTSC_HasItemsCustom.SetValueInt(DTSC_ArmorsExtraList.GetSize())
			if (DTSC_VerboseSetting.GetValueInt() > 0)
				Utility.WaitMenuMode(0.2)   ;v2.10 replaced Wait
				DTSC_CustomArmorAddedMsg.Show(captureCount)
			endIf
		elseIf (DTSC_VerboseSetting.GetValueInt() > 0)
			Utility.WaitMenuMode(0.2)
			;DTSC_CustomExistsMsg.Show()
			ConfirmRemoveMenu(DTSC_ArmorsExtraList, baseArmor)
		endIf
		return 1
	endIf
	return 0
endFunction

int Function AddCustomSpell(Form baseSpell)
	if (!DTSC_SpellsExtraList.HasForm(baseSpell))
		captureCount += 1
		DTSC_SpellsExtraList.AddForm(baseSpell)
		;Debug.Trace("[DTSC] added  " + baseSpell + ", count: " + captureCount)
		if (DTSC_VerboseSetting.GetValueInt() > 0)
			Utility.WaitMenuMode(0.2) ;v2.10 replaced Wait
			DTSC_CustomSpellAddedMsg.Show(captureCount)
		endIf
	elseIf (DTSC_VerboseSetting.GetValueInt() > 0)
		Utility.WaitMenuMode(0.1)
		;DTSC_CustomExistsMsg.Show()
		ConfirmRemoveMenu(DTSC_SpellsExtraList, baseSpell)
	endIf
	return 1
endFunction

; v2.30 - checks and removes exclusions from aList - items should be restored first
Function CheckExclusionsForList(FormList aList)
	if (aList)
		int len = aList.GetSize()
		int idx = len - 1
		; go backward so we can remove keeping index
		while (idx >= 0)
			Form aForm = aList.GetAt(idx)
			if (aForm && DTSC_ExtraExceptionList.HasForm(aForm))
				aList.RemoveAddedForm(aForm)
			endIf
			idx -= 1
		endWhile
	endIf
endFunction

Function CleanSpells()
	int modCount = 0
	Spell sp = None
	int cleanSpellsCount = 0
	int cleanItemsCount = 0
	bool ignoreDisabled = DTSC_RecheckModsSettings.GetValueInt() as bool
	bool restoreAll = DTSC_RestoreAllSpells.GetValue() as bool
	
	if (CleanTaskOption == 2)
		restoreAll = true
	endIf
	int taskOption = DTSC_CampFrostOps.GetValueInt()
	
	if (taskOption > 0 || ignoreDisabled)
		if (restoreAll)
			taskOption = 2
		elseIf (ignoreDisabled)
			taskOption = 1
		endIf
		sp = IsPluginPresent(0x050359AA, "Campfire.esm") as Spell  ; options
		if (sp)
			modCount += 1
			cleanSpellsCount += ProcessTaskForSpell(taskOption, sp)
			DTSC_CampFrostOps.SetValue(1.0)
			
			sp = IsPluginPresent(0x0608C8BF, "Frostfall.esp") as Spell ; options
			if (sp)
				modCount += 1
				cleanSpellsCount += ProcessTaskForSpell(taskOption, sp)
			endIf
			
			Utility.Wait(0.1)
		else
			DTSC_CampFrostOps.SetValue(0.0)
		endIf
	endIf
	
	taskOption = DTSC_WearableLantConfig.GetValueInt()
	if (taskOption > 0 || ignoreDisabled)
		if (restoreAll)
			taskOption = 2
		elseIf (ignoreDisabled)
			taskOption = 1
		endIf
		string pluginName = "Chesko_WearableLantern.esp"
		sp = IsPluginPresent(0x0601F49C, pluginName) as Spell  ; Config
		if (sp)
			modCount += 1
			cleanSpellsCount += ProcessTaskForSpell(taskOption, sp)
			DTSC_WearableLantConfig.SetValue(1.0)
			
			if (DTSC_WLToggleSetting.GetValueInt() > 0 || restoreAll)
				sp = Game.GetFormFromFile(0x06020A40, pluginName) as Spell  ; toggle lantern
				cleanSpellsCount += ProcessTaskForSpell(taskOption, sp)
				sp = Game.GetFormFromFile(0x06020A42, pluginName) as Spell  ; check fuel
				cleanSpellsCount += ProcessTaskForSpell(taskOption, sp)
			endIf
			Utility.Wait(0.1)
		else
			DTSC_WearableLantConfig.SetValue(0.0)
		endIf
	endIf
	
	taskOption = DTSC_iNeedAction.GetValueInt()
	if (taskOption > 0 || ignoreDisabled)
		if (restoreAll)
			taskOption = 2
		elseIf (ignoreDisabled)
			taskOption = 1
		endIf
		int iNeedSetting = DTSC_iNeedSetting.GetValueInt()
		if (iNeedSetting != 0 || restoreAll)
			Spell actionSpell = IsPluginPresent(0x09056CC4, "iNeed.esp") as Spell
			if (actionSpell)
				modCount += 1
				cleanSpellsCount += ProcessTaskForSpell(taskOption, actionSpell)
				DTSC_iNeedAction.SetValue(1.0)
			else
				DTSC_iNeedAction.SetValue(0.0)
			endIf
			if (iNeedSetting < 0)
				DTSC_iNeedSetting.SetValueInt(0)
			endIf
		elseIf (DTSC_iNeedAction.GetValueInt() >= 1)
			modCount += 1
		endIf
	endIf
	Utility.Wait(0.2)
	
	; ***** single Spell mods ****

	; cleanSpellsCount will not increase on restore if player has spell
	; so modCount invalid on remove and will come up short on removal if removed first
	; if only Skyrim Papyrus support Struct like FO4! 
	; we could spend a save-game variable, but not needed as long as we only report after removal phase
	;
	int difModCount = cleanSpellsCount - modCount
	
	cleanSpellsCount += HandleSpellForMod(0x06F10B4F, "Immersive Citizens - AI Overhaul.esp", DTSC_ImmersiveCitz, restoreAll, ignoreDisabled)
	
	cleanSpellsCount += HandleSpellForMod(0x0908B171, "Facelight.esp", DTSC_FacelightReset, restoreAll, ignoreDisabled)
	
	cleanSpellsCount += HandleSpellForMod(0x091B2F4B, "Hunterborn.esp", DTSC_HunterbornConfig, restoreAll, ignoreDisabled)
	
	cleanSpellsCount += HandleSpellForMod(0x0905FD94, "Better Vampires.esp", DTSC_BetterVampConfig, restoreAll, ignoreDisabled)

	cleanSpellsCount += HandleSpellForMod(0x090DBDAA, "WetandCold.esp", DTSC_WetAndColdConfig, restoreAll, ignoreDisabled)
	
	cleanSpellsCount += HandleSpellForMod(0x0906CE7E, "Wildcat - Combat of Skyrim.esp", DTSC_WildcatConfig, restoreAll, ignoreDisabled)
	
	Utility.Wait(0.2)
	
	cleanSpellsCount += HandleSpellForMod(0x0900433F, "UnreadBooksGlow.esp", DTSC_UnreadBooksGlow, restoreAll, ignoreDisabled)
	
	cleanSpellsCount += HandleSpellForMod(0x0900FBA1, "Smilodon - Combat of Skyrim.esp", DTSC_SmilodonConf, restoreAll, ignoreDisabled)
	
	if (DTSC_IsXB1.GetValueInt() < 1)
		cleanSpellsCount += HandleSpellForMod(0x070105F6, "FlowerGirls SE.esp", DTSC_FlowerGirls, restoreAll, ignoreDisabled)
		cleanSpellsCount += HandleSpellForMod(0x090B8649, "DeadlyCombat.esp", DTSC_DeadlyCombatConf, restoreAll, ignoreDisabled)
		
		cleanSpellsCount += HandleSpellForMod(0x09521F18, "Vigor - Combat and Injuries (SE).esp", DTSC_VigorCI, restoreAll, ignoreDisabled)
	endIf
	
	cleanSpellsCount += HandleSpellForMod(0x09023668, "NAT.esp", DTSC_NATSet, restoreAll, ignoreDisabled)
	
	modCount = cleanSpellsCount - difModCount
	
	; *** do captured spells ***
	if (restoreAll)
		taskOption = 2
	else
		taskOption = 1
	endIf
	
	int len = DTSC_SpellsExtraList.GetSize()
	; v2.30 - added recheck exclusions to modify list on clean phase
	if (recheckExclusions && !restoreAll && len > 0)
		CheckExclusionsForList(DTSC_SpellsExtraList)
		len = DTSC_SpellsExtraList.GetSize() ; update
	endIf
	
	int idx = 0
	while (idx < len)
		Spell aSpell = DTSC_SpellsExtraList.GetAt(idx) as Spell
		if (aSpell)
			cleanSpellsCount += ProcessTaskForSpell(taskOption, aSpell)
			Utility.Wait(0.1)
		endIf
		idx += 1
	endWhile
	
	if (DTSC_IncludeItemsSetting.GetValueInt() > 0)
		;  **** single Armor mods *****
		cleanItemsCount += HandleArmorForMod(0x04005901, "Moonlight Tales Special Edition.esp", DTSC_MoonlightTales, restoreAll, ignoreDisabled)
		if (cleanItemsCount > 0)
			modCount += 1
			DTSC_HasItemsMod.SetValueInt(1)
		endIf
		
		len = DTSC_ArmorsExtraList.GetSize()
		; v2.30 - recheck exclusions on update during clean phase
		if (recheckExclusions && !restoreAll && len > 0)
			CheckExclusionsForList(DTSC_ArmorsExtraList)
			len = DTSC_ArmorsExtraList.GetSize()  ; update 
		endIf
		
		idx = 0
		while (idx < len)
			Armor armItem = DTSC_ArmorsExtraList.GetAt(idx) as Armor
			if (armItem)
				cleanItemsCount += ProcessTaskForArmor(taskOption, armItem)
				Utility.Wait(0.1)
			endIf
			idx += 1
		endWhile
	endIf
	
	; **** remove our config spell **
	if (PlayerRef.HasSpell(DTSC_ConfigSpell))
		PlayerRef.RemoveSpell(DTSC_ConfigSpell)
	endIf
	
	if (DTSC_ModMonCount.GetValueInt() == 0)
		; let's update if zero else only on remove phase
		DTSC_ModMonCount.SetValueInt(modCount)
	endIf

	if (!restoreAll)
		; update count on remove phase
		DTSC_ModMonCount.SetValueInt(modCount)
		
		DTSC_RecheckModsSettings.SetValueInt(0)
		if (DTSC_VerboseSetting.GetValue() > 0.0 || DTSC_Verbose.GetValue() > 0.0)
			if (cleanSpellsCount > 0 || cleanItemsCount > 0)
				DTSC_CleanTotalMsg.Show(cleanSpellsCount, cleanItemsCount)
			endIf
		endIf
		recheckExclusions = false
	endIf
	
endFunction

int Function CleanArmor(Armor armItm)
	if (armItm && PlayerRef.GetItemCount(armItm) > 0)
		;Debug.Trace(self + " remove item " + armItm)
		PlayerRef.RemoveItem(armItm, 1, true)
		return 1
	endIf
	return 0
endFunction

int Function CleanSpell(Spell sp)
	if (sp && PlayerRef.HasSpell(sp))
		;Debug.Trace(self + " hide spell " + sp)
		PlayerRef.RemoveSpell(sp)
		return 1
	endIf
	return 0
endFunction

Function ConfirmRemoveMenu(FormList list, Form formToRemove, int aiButton = 0)
	aiButton = DTSC_ConfirmRemoveMsg.Show() 
	if aiButton == 0  
		; no, do nothing
	elseIf aiButton == 1
		; yes, remove spell from clean list
		list.RemoveAddedForm(formToRemove)
	endIf
endFunction

; set to 2 on startup
int Function GetFrostfallRunningValue()
	GlobalVariable frGV = Game.GetFormFromFile(0x0306DCFB, "Frostfall.esp") as GlobalVariable
	if (frGV)
		return frGV.GetValueInt()
	endIf
	return -1
endFunction

int Function HandleArmorForMod(int formId, string modName,  GlobalVariable gVar, bool restore, bool ignoreDisabled)
	int taskOption = -1
	int processMod = gVar.GetValueInt()
	if (!ignoreDisabled)
		
		if (processMod <= 0)
			return 0
		endIf
	endIf
	int result = 0
	if (restore)
		taskOption = 2
	elseIf (ignoreDisabled)
		taskOption = 1
	else
		taskOption = processMod
	endIf
	
	if (taskOption > 0)
		Armor armorItem = IsPluginPresent(formId, modName) as Armor
		if (armorItem)
			result = ProcessTaskForArmor(taskOption, armorItem)
			
			gVar.SetValue(1.0)
			Utility.Wait(0.1)
		else
			gVar.SetValue(0.0)
		endIf
	endIf
	return result
endFunction

int Function HandleSpellForMod(int formId, string modName,  GlobalVariable gVar, bool restore, bool ignoreDisabled)
	int processMod = gVar.GetValueInt()
	if (!ignoreDisabled)
		if (processMod <= 0)
			return 0
		endIf
	endIf
	int taskOption = -1
	int result = 0
	if (restore)
		taskOption = 2
	elseIf (ignoreDisabled)
		taskOption = 1
	else
		taskOption = processMod
	endIf
	;Debug.Trace("[DTSC_] HandleSpellForMod " + modName + ", ignore: " + ignoreDisabled)
	if (taskOption > 0)
		Spell sp = IsPluginPresent(formId, modName) as Spell 
		if (sp)
			result = ProcessTaskForSpell(taskOption, sp)

			gVar.SetValue(1.0)
			Utility.Wait(0.1)
		else
			gVar.SetValue(0.0)
		endIf
	endIf
	return result
endFunction

Form Function IsPluginPresent(int formID, string pluginName)
	; from CreationKit.com: "Note the top most byte in the given ID is unused so 0000ABCD works as well as 0400ABCD"
	Form formFound = Game.GetFormFromFile(formID, pluginName)
	if (formFound)
		Debug.Trace(self + " found plugin: " + pluginName)
		return formFound 
	endIf
	return None
endFunction

Function ManageMod()
	float vers = DTSC_Version.GetValue()
	float oldV = DTSC_VersionPrior.GetValue()
	
	if (oldV < vers)
		recheckExclusions = true 
		
		if (oldV > 0.5 && oldV < 2.00)
			DTSC_BetterVampConfig.SetValueInt(1)
			DTSC_CampFrostOps.SetValueInt(1)
			DTSC_ImmersiveCitz.SetValueInt(1)
			DTSC_iNeedAction.SetValueInt(1)
			DTSC_FacelightReset.SetValueInt(1)
			DTSC_FlowerGirls.SetValueInt(1)
			DTSC_HunterbornConfig.SetValueInt(1)
			DTSC_WearableLantConfig.SetValueInt(1)
			DTSC_WetAndColdConfig.SetValueInt(1)
			DTSC_WildcatConfig.SetValueInt(1)
		endIf
		if (oldV > 1.0 && oldV < 2.02)
			if (DTSC_MoonlightTales.GetValueInt() > 0)
				DTSC_HasItemsMod.SetValueInt(1)
				DTSC_IncludeItemsSetting.SetValueInt(1)
			elseIf (IsPluginPresent(0x04005901, "Moonlight Tales Special Edition.esp"))
				DTSC_HasItemsMod.SetValueInt(1)
			endIf
			if (DTSC_WearableLantToggles.GetValueInt() > 0)
				DTSC_WLToggleSetting.SetValueInt(1)
			endIf
		endIf
		if (oldV > 1.0 && oldV < 2.03)
			DTSC_InitOptions.SetValueInt(1)
		endIf
		if (oldV > 1.0 && oldV < 2.20 && DTSC_iNeedAction.GetValueInt() > 0 && DTSC_iNeedSetting.GetValueInt() < 0)
			DTSC_iNeedSetting.SetValueInt(0)
		endIf

		lastCaptureTime = Utility.GetCurrentRealTime()

		DTSC_VersionPrior.SetValue(vers)
	endIf
endFunction

int Function ProcessTaskForArmor(int taskOption, Armor armItm)
	if (taskOption == 1)
		return CleanArmor(armItm)
	elseIf (taskOption > 1)
		return DTSC_CommonF.RestoreArmor(armItm, PlayerRef)
	endIf
	return 0
endFunction

int Function ProcessTaskForSpell(int taskOption, Spell sp)
	if (taskOption == 1)
		return CleanSpell(sp)
	elseIf (taskOption > 1)
		return DTSC_CommonF.RestoreSpell(sp, PlayerRef)
	endIf
	return 0
endFunction

; **************** no longer used *******************

GlobalVariable property DTSC_IgnoreDisabledPluginChecks auto
{This setting is deprecated as of version 2.0.}
