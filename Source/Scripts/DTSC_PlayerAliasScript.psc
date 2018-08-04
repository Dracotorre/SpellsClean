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

Quest property DTSC_SkyUIConfigQuest auto
Message property DTSC_CleanTotalMsg auto
Message property DTSC_CustomSpellAddedMsg auto
Message property DTSC_CustomExceptionMsg auto
Message property DTSC_CustomExistsMsg auto
Message property DTSC_CustomArmorAddedMsg auto
Message property DTSC_InitMessage auto
Message property DTSC_InitMCMMessage auto
Message property DTSC_ConfirmRemoveMsg auto
Message property DTSC_EquipFailMsg auto
Message property DTSC_VersionErrorDowngradeMsg auto
Spell property DTSC_ConfigSpell auto
GlobalVariable property DTSC_HasItemsMod auto
GlobalVariable property DTSC_CaptureSpellAdd auto
GlobalVariable property DTSC_InitOptions auto
GlobalVariable property DTSC_ModMonCount auto
GlobalVariable property DTSC_HasItemsCustom auto
GlobalVariable property DTSC_ConfigSpellRemDelay auto  ; added v2.42
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
GlobalVariable property DTSC_CaptureLimitSetting auto
GlobalVariable property DTSC_VerboseSetting auto
GlobalVariable property DTSC_RecheckModsSettings auto
GlobalVariable property DTSC_DisableSetting auto
GlobalVariable property DTSC_IncludeItemsSetting auto
GlobalVariable property DTSC_MCMSetting auto
GlobalVariable property DTSC_WLToggleSetting auto
GlobalVariable property DTSC_iNeedSetting auto
GlobalVariable property DTSC_CampFrostExtras auto
GlobalVariable property DTSC_WaitSecondsSetting auto
GlobalVariable property DTSC_CleanCustomSetting auto

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
GlobalVariable property DTSC_ASGM auto
GlobalVariable property DTSC_OBISmain auto
GlobalVariable property DTSC_OBISpatrol auto
GlobalVariable property DTSC_VividWeathers auto
GlobalVariable property DTSC_SOTGenU auto
GlobalVariable property DTSC_SOTGenSS auto

int property CleanTaskOption auto hidden
{2 = restore, 1 = remove}
bool property IsSkyUIPresent auto hidden

bool recheckExclusions = false  ; v2.30 - in case more exclusions have been added in update
int captureCount = 0  ;v2.10
float lastCaptureTime = 0.0     ; game-time
float lastSpellAddedTime = 0.0  ;v2.25 real-time for equip too fast such as auto-equip other hand
int updateType = 2   ; normal clean = 0, remove spell = 1, done = 2, clean custom = 3

; ************************** Events *******************

Event OnPlayerLoadGame()
	UnregisterForUpdate()
	updateType = -1
	CheckSkyUI()
	ManageMod()
	
	lastSpellAddedTime = 0.01  ; reset for launch - v2.32 fix for excluding first equip
		
	; first update restores all spells
	CleanTaskOption = 2
	
	RegisterForSingleUpdate(1.6)
EndEvent

Event OnUpdate()
	if (updateType == -1)
		float vers = DTSC_Version.GetValue()
		float oldV = DTSC_VersionPrior.GetValue()
		if (oldV > vers)
			DTSC_VersionErrorDowngradeMsg.Show(vers, oldV)
		endIf
		updateType = 0
		RegisterForSingleUpdate(2.0)
	elseIf (updateType == 3)
		updateType = 2
		if (DTSC_CleanCustomSetting.GetValueInt() > 0)
			CleanCapturedArmors(1, false)
			CleanCapturedSpells(1, false)
		else
			CleanCapturedArmors(2, false)
			CleanCapturedSpells(2, false)
		endIf

	elseIf (updateType == 1)
		updateType = 2
		
		DTSC_ConfigSpellRemDelay.SetValue(1.066)  ; reset
		
		; **** remove our config spell **
		if (PlayerRef.HasSpell(DTSC_ConfigSpell))
			PlayerRef.RemoveSpell(DTSC_ConfigSpell)
		endIf
	else
		
		if (Game.IsFightingControlsEnabled())
			; only process if enabled or restoring
			if (DTSC_DisableAll.GetValue() <= 0.0)
				int doRestore = DTSC_RestoreAllSpells.GetValueInt()
				
				; clean/restore - always restore first
				if (DTSC_DisableSetting.GetValue() < 1 || doRestore > 0 || CleanTaskOption == 2)
					CleanSpells()
				endIf
				
				; do we clean next time?
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
					
				elseIf (CleanTaskOption == 1 && updateType == 0)
					; need to remove our config spell
					updateType = 1
					
					float extraDelay = DTSC_ConfigSpellRemDelay.GetValue()
					if (DTSC_MCMSetting.GetValueInt() >= 1)
						extraDelay = 0.0
					elseIf (extraDelay > 100.0)
						extraDelay = 100.0
					elseIf (extraDelay < 1.0)
						extraDelay = 1.1
					endIf
					
					RegisterForSingleUpdate(2.5 + extraDelay)
					
				endIf
			endIf
		else
			; no fight controls - try later
			RegisterForSingleUpdate(12.0)
		endIf
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
		
		float curRealTime = Utility.GetCurrentRealTime()    ; time since game launch
		float secSinceLastAdd = curRealTime - lastSpellAddedTime
		lastSpellAddedTime = curRealTime
		
		if (secSinceLastAdd < 0.33)
			; v2.25
			;Debug.Trace("[DTSC] equip too fast")
			Utility.WaitMenuMode(0.4)
			DTSC_EquipFailMsg.Show()
			return
		endIf
		
		float curTime = Utility.GetCurrentGameTime()
		float minDiff = DTSC_CommonF.GetGameTimeHoursDifference(curTime, captureTime) * 60.0
		
		bool capOK = DTSC_CommonF.AddSpellCaptureTimeOK(captureTime, DTSC_MCMSetting.GetValueInt() == 1)
	
		int capLimit = DTSC_CaptureLimitSetting.GetValueInt()
		
		if (DTSC_MCMSetting.GetValueInt() < 1 || capLimit < 1 || capLimit > 100)
			capLimit = DTSC_CaptureLimit.GetValueInt()
		endIf
		
		if (capOK && captureCount < capLimit)
			
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
	if (!PlayerRef.HasSpell(DTSC_ConfigSpell))
		;Debug.Trace("[DTSC] add config spell: " + DTSC_ConfigSpell)
		if (DTSC_MCMSetting.GetValueInt() < 1)
			PlayerRef.AddSpell(DTSC_ConfigSpell, false)
		endIf
		if (DTSC_InitOptions.GetValueInt() <= 0)
			DTSC_InitOptions.SetValueInt(1)
			if (DTSC_MCMSetting.GetValueInt() < 1)
				DTSC_InitMessage.Show(DTSC_ModMonCount.GetValue())
			else
				DTSC_InitMCMMessage.Show(DTSC_ModMonCount.GetValue())
			endIf
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

bool Function CheckSkyUI()

	if (DTSC_IsXB1.GetValueInt() < 1)
		IsSkyUIPresent = IsPluginPresent(0x01000814, "SkyUI_SE.esp") as bool
		if (!IsSkyUIPresent)
			; check old
			IsSkyUIPresent = IsPluginPresent(0x01000814, "SkyUI.esp") as bool
		endIf
		
		if (IsSkyUIPresent)
			if (DTSC_SkyUIConfigQuest.IsRunning() == false)
				DTSC_SkyUIConfigQuest.Start()
				DTSC_MCMSetting.SetValueInt(1)
				DTSC_CaptureLimitSetting.SetValueInt(64)
			endIf
		else
			DTSC_CaptureLimitSetting.SetValueInt(12)
			DTSC_MCMSetting.SetValueInt(0)
		endIf
	endIf
	
	return IsSkyUIPresent
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
				cleanSpellsCount += CleanWLOptionals(pluginName, taskOption)
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
	
	if (DTSC_CleanCustomSetting.GetValueInt() > 0)
		cleanSpellsCount += CleanCapturedSpells(taskOption, restoreAll)
	endIf
	
	; *** items ***
	
	if (DTSC_IncludeItemsSetting.GetValueInt() > 0 || ignoreDisabled || DTSC_HasItemsMod.GetValue() < 0.0)
		bool skipReportCount = false
		
		if (DTSC_HasItemsMod.GetValueInt() < 0)
			; don't clean on establish
			cleanItemsCount = CleanItems(true, true)
			skipReportCount = true
		else
			cleanItemsCount = CleanItems(restoreAll, ignoreDisabled)
		endIf
		
		if (cleanItemsCount > 0)
			
			modCount += cleanItemsCount
			DTSC_HasItemsMod.SetValueInt(1) 
			
			if (skipReportCount)
				cleanItemsCount = 0
			endIf
		elseIf (DTSC_HasItemsMod.GetValueInt() < 0)
			DTSC_HasItemsMod.SetValueInt(0)
		endIf
		
		if (DTSC_CleanCustomSetting.GetValueInt() > 0)
			; do custom list of armors 
			cleanItemsCount += CleanCapturedArmors(taskOption, restoreAll)
		endIf
	endIf
	
	if (DTSC_ModMonCount.GetValueInt() == 0)
		; let's update if zero else only on remove phase
		DTSC_ModMonCount.SetValueInt(modCount)
	endIf

	if (!restoreAll)
		; update count on remove phase
		DTSC_ModMonCount.SetValueInt(modCount)
		
		if (DTSC_VerboseSetting.GetValue() > 0.0 || DTSC_Verbose.GetValue() > 0.0)
			if (cleanSpellsCount > 0 || cleanItemsCount > 0)
				DTSC_CleanTotalMsg.Show(cleanSpellsCount, cleanItemsCount)
			endIf
		endIf
		recheckExclusions = false
	endIf
	
	if (ignoreDisabled)
		DTSC_RecheckModsSettings.SetValueInt(0)
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

int Function CleanBook(Book item)
	if (item && PlayerRef.GetItemCount(item) > 0)
		
		PlayerRef.RemoveItem(item, 1, true)
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

; v2.50 - moved block to this function for re-use
int Function CleanCapturedArmors(int taskOption, bool restoreAll)
	int resultCount = 0
	int len = DTSC_ArmorsExtraList.GetSize()  ; getsize first
		
	; v2.30 - recheck exclusions on update during clean phase
	if (recheckExclusions && !restoreAll && len > 0)
		CheckExclusionsForList(DTSC_ArmorsExtraList)
		len = DTSC_ArmorsExtraList.GetSize()  ; update 
	endIf
	
	int idx = 0
	while (idx < len)
		Armor armItem = DTSC_ArmorsExtraList.GetAt(idx) as Armor
		if (armItem)
			resultCount += ProcessTaskForArmor(taskOption, armItem)
			Utility.Wait(0.1)
		endIf
		idx += 1
	endWhile
	
	DTSC_HasItemsCustom.SetValueInt(len)
	
	return resultCount
endFunction

; v2.50 - moved block to this function for re-use
int Function CleanCapturedSpells(int taskOption, bool restoreAll)
	int resultCount = 0
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
			resultCount += ProcessTaskForSpell(taskOption, aSpell)
			Utility.Wait(0.1)
		endIf
		idx += 1
	endWhile
	
	return resultCount
endFunction

; v2.50 - moved here for re-use
int Function CleanItems(bool restoreAll, bool ignoreDisabled)
	int resultCount = 0
	
	;  **** single Armor and Book mods *****
	resultCount = HandleArmorForMod(0x04005901, "Moonlight Tales Special Edition.esp", DTSC_MoonlightTales, restoreAll, ignoreDisabled)
	
	resultCount += HandleBookForMod(0x0921D9E1, "Vivid WeathersSE.esp", DTSC_VividWeathers, restoreAll, ignoreDisabled)
	
	; OBIS menu disabled if not in inventory due to forced reference
	if (restoreAll && DTSC_OBISmain.GetValue() > 0.0)
		resultCount += HandleBookForMod(0x0901074F, "OBIS SE.esp", DTSC_OBISmain, restoreAll, ignoreDisabled)
		resultCount += HandleBookForMod(0x09093562, "OBIS SE Patrols Addon.esp", DTSC_OBISpatrol, restoreAll, ignoreDisabled)
		DTSC_OBISmain.SetValue(0.0)
	endIf
	resultCount += HandleBookForMod(0x09004E0F, "AcquisitiveSoulGemMultithreaded.esp", DTSC_ASGM, restoreAll, ignoreDisabled)
	
	resultCount += HandleBookForMod(0x09006E75, "SOTGenesisMod.esp", DTSC_SOTGenU, restoreAll, ignoreDisabled)
	resultCount += HandleBookForMod(0x0905BFEC, "Genesis Surface Spawns.esp", DTSC_SOTGenSS, restoreAll, ignoreDisabled)
	
	return resultCount
endFunction 

; v2.50 - moved block here for re-use
int Function CleanWLOptionals(string pluginName, int taskOption)
	int resultCount = 0
	
	Spell sp = Game.GetFormFromFile(0x06020A40, pluginName) as Spell  ; toggle lantern
	resultCount += ProcessTaskForSpell(taskOption, sp)
	sp = Game.GetFormFromFile(0x06020A42, pluginName) as Spell  ; check fuel
	resultCount += ProcessTaskForSpell(taskOption, sp)
	
	return resultCount
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
	Debug.Trace("[DTSC] processing " + modName)
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
			
			if (taskOption == 2 || DTSC_IncludeItemsSetting.GetValueInt() > 0)
				result = ProcessTaskForArmor(taskOption, armorItem)
			endIf
			if (ignoreDisabled)
				; force for initialize
				result = 1
			endIf
			
			gVar.SetValue(1.0)
			Utility.Wait(0.06)
		else
			gVar.SetValue(0.0)
		endIf
	endIf
	return result
endFunction

int Function HandleBookForMod(int formId, string modName,  GlobalVariable gVar, bool restore, bool ignoreDisabled)
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
		Book item = IsPluginPresent(formId, modName) as Book
		if (item)
			result = ProcessTaskForBook(taskOption, item)
			
			gVar.SetValue(1.0)
			Utility.Wait(0.06)
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
		
		Debug.Trace("[DTSC] upgrade old -> current " + oldV + " -> " + vers)
		
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
		
		if (oldV <= 2.42 && DTSC_HasItemsMod.GetValueInt() < 1)
			; reset to check for new config book mods to monitor 
			DTSC_HasItemsMod.SetValueInt(-1)
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

int Function ProcessTaskForBook(int taskOption, Book item)
	if (taskOption == 1)
		return CleanBook(item)
	elseIf (taskOption > 1)
		return DTSC_CommonF.RestoreBook(item, PlayerRef)
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

; **************************************************
; placed here for external use
;
Function RecoverCustomArmors()
	int len = DTSC_ArmorsExtraList.GetSize()
	int idx = 0
	while (idx < len)
		Armor aArm = DTSC_ArmorsExtraList.GetAt(idx) as Armor
		DTSC_CommonF.RestoreArmor(aArm, PlayerREF)
		Utility.WaitMenuMode(0.05)
		idx += 1
	endWhile
	if (len > 0)
		DTSC_ArmorsExtraList.Revert()
	endIf
EndFunction

Function RecoverCustomSpells()
	int len = DTSC_SpellsExtraList.GetSize()
	int idx = 0
	while (idx < len)
		Spell aSpell = DTSC_SpellsExtraList.GetAt(idx) as Spell
		DTSC_CommonF.RestoreSpell(aSpell, PlayerREF)
		Utility.WaitMenuMode(0.05)
		idx += 1
	endWhile
	if (len > 0)
		DTSC_SpellsExtraList.Revert()
		DTSC_HasItemsCustom.SetValueInt(0)
	endIf
EndFunction

Function RequestCleanCustoms()
	if (DTSC_InitOptions.GetValueInt() <= 0)
		return
	endIf
	if (updateType == 2)
		updateType = 3
		RegisterForSingleUpdate(2.4)
	endIf
endFunction

Function RequestCleanItems()
	if (DTSC_InitOptions.GetValueInt() <= 0)
		return
	endIf
	if (updateType == 2)
		if (DTSC_IncludeItemsSetting.GetValueInt() >= 1)
			CleanItems(false, false)
		else
			CleanItems(true, false)
		endIf
	endIf
endFunction

Function RequestCleanINeed()
	if (DTSC_InitOptions.GetValueInt() <= 0)
		return
	endIf
	if (updateType == 2)
		Spell actionSpell = IsPluginPresent(0x09056CC4, "iNeed.esp") as Spell
		if (actionSpell)
			if (DTSC_iNeedSetting.GetValueInt() >= 1)
				ProcessTaskForSpell(1, actionSpell)
			else
				ProcessTaskForSpell(2, actionSpell)
			endIf
		endIf
	endIf
endFunction

Function RequestCleanWLOption()
	if (DTSC_InitOptions.GetValueInt() <= 0)
		return
	endIf
	if (updateType == 2)
		if (DTSC_WLToggleSetting.GetValue() >= 1)
			CleanWLOptionals("Chesko_WearableLantern.esp", 1)
		else
			CleanWLOptionals("Chesko_WearableLantern.esp", 2)
		endIf
	endIf
endFunction

Function RequestReset()
	if (DTSC_InitOptions.GetValueInt() <= 0)
		return
	endIf
	if (DTSC_DisableSetting.GetValueInt() > 0)
		; do we need to restore?
		if (CleanTaskOption != 2 && updateType >= 1)
			CleanTaskOption = 2
			updateType = 0
			RegisterForSingleUpdate(2.0)
		
		endIf
	else
		; enabled - do we need to clean?
		if (updateType == 2)
			CleanTaskOption = 1
			updateType == 0
			RegisterForSingleUpdate(3.0)
		endIf
	endIf
EndFunction




; **************** no longer used *******************

GlobalVariable property DTSC_IgnoreDisabledPluginChecks auto
{This setting is deprecated as of version 2.0.}
