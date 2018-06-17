Scriptname DTSC_SkyUIConfigPanelScript extends SKI_ConfigBase

ReferenceAlias property KeepCleanQuestAlias auto

GlobalVariable property DTSC_Version auto
GlobalVariable property DTSC_ModMonCount auto
GlobalVariable property DTSC_CaptureLimitSetting auto
GlobalVariable property DTSC_CaptureSpellAdd auto

FormList property DTSC_ArmorExtraList auto
FormList property DTSC_SpellsExtraList auto

GlobalVariable property DTSC_WearableLantConfig auto
GlobalVariable property DTSC_iNeedAction auto
GlobalVariable property DTSC_HasItemsCustom auto
GlobalVariable property DTSC_HasItemMods auto 

; settings to set
GlobalVariable property DTSC_MCMSetting auto
GlobalVariable property DTSC_DisableSetting auto
GlobalVariable property DTSC_RecheckModsSetting auto
GlobalVariable property DTSC_VerboseSetting auto
GlobalVariable property DTSC_WLToggleSettings auto
GlobalVariable property DTSC_iNeedSetting auto
GlobalVariable property DTSC_IncludeItemsSetting auto
GlobalVariable property DTSC_WaitSecondsSetting auto

; ===============================================
; local

int SettingCleanEnabled_OID
int SettingVerboseEnabled_OID
int SettingRecheckMods_OID
int SettingPreferMCM_OID
int SettingTimerA_OID
int SettingTimerB_OID
int SettingTimerC_OID
int SettingTimerD_OID
int SettingCleanWL_OID
int SettingClean_iNeed_OID
int SettingCleanItems_OID
int SettingAddSpellEnable_OID
int SettingAddSpellReset_OID
int SettingAddSpellMaxOptionA_OID
int SettingAddSpellMaxOptionB_OID
int SettingAddSpellMaxOptionC_OID
int TextCustomSpellList_OID
int TextCustomArmorList_OID

; ====================================
;  events

Event OnConfigInit()
	Pages = new string[2]
	Pages[0] = "$SpellsCleanOptionsPage"
	Pages[1] = "$SpellsCleanAddSpellPage"
endEvent

Event OnPageReset(string page)

	if (Pages == None)
		OnConfigInit()
	endif
	
	if (page == "" || page == "$SpellsCleanOptionsPage")
		ResetPageMain()
	elseIf (page == "$SpellsCleanAddSpellPage")
		ResetPageAddSpell()
	else
		ResetPageMain()
	endIf
	
endEvent

Event OnOptionHighlight(int option)
	if (option == SettingCleanEnabled_OID)
		SetInfoText("$CleanEnabledInfo")
	elseIf (option == SettingAddSpellEnable_OID)
		SetInfoText("$AddSpellGuide")
	elseIf (option == SettingPreferMCM_OID)
		SetInfoText("$PreferMCMInfo")
	elseIf (option == SettingVerboseEnabled_OID)
		SetInfoText("$VerboseInfo")
	elseIf (option== SettingCleanItems_OID)
		SetInfoText("$CleanItemsInfo")
	elseIf (option == SettingRecheckMods_OID)
		SetInfoText("$RecheckModsInfo")
	elseIf (option == SettingAddSpellReset_OID)
		SetInfoText("$AddSpellResetInfo")
	elseIf (option == SettingCleanWL_OID)
		SetInfoText("$WLTogglInfo")
	elseIf (option == SettingTimerA_OID || option == SettingTimerB_OID || option == SettingTimerC_OID)
		SetInfoText("$TimerSettingInfo")
	elseIf (option == SettingAddSpellMaxOptionA_OID || SettingAddSpellMaxOptionB_OID || SettingAddSpellMaxOptionC_OID)
		SetInfoText("$AddSpellMaxInfo")
	elseIf (option == TextCustomSpellList_OID)
		SetInfoText("$CustomSpellListInfo")
	elseIf (option == TextCustomArmorList_OID)
		SetInfoText("$CustomArmorListInfo")
	endIf
endEvent

Event OnOptionSelect(int option) 
	if (option == SettingCleanEnabled_OID)
		SetToggleGlobalVar(DTSC_DisableSetting, option, 0.0)
	elseIf (option == SettingVerboseEnabled_OID)
		SetToggleGlobalVar(DTSC_VerboseSetting, option, 1.0)
	elseIf (option == SettingPreferMCM_OID)
		SetToggleGlobalVar(DTSC_MCMSetting, option, 0.0)
	elseIf (option == SettingCleanItems_OID)
		SetToggleGlobalVar(DTSC_IncludeItemsSetting, option, 1.0)
	elseIf (option == SettingCleanWL_OID)
		SetToggleGlobalVar(DTSC_WLToggleSettings, option, 1.0)
	elseIf (option == SettingClean_iNeed_OID)
		SetToggleGlobalVar(DTSC_iNeedSetting, option, 1.0)
	elseIf (option == SettingRecheckMods_OID)
		SetToggleGlobalVar(DTSC_RecheckModsSetting, option, 1.0)
	elseIf (option == SettingTimerA_OID)
		SetWaitTimerOption(option, 12.0)
	elseIf (option == SettingTimerB_OID)
		SetWaitTimerOption(option, 24.0)
	elseIf (option == SettingTimerC_OID)
		SetWaitTimerOption(option, 54.0)
	elseIf (option == SettingTimerD_OID)
		SetWaitTimerOption(option, 234.0)
	elseIf (option == SettingAddSpellMaxOptionA_OID)
		SetMaxCountOption(option, 4)
	elseIf (option == SettingAddSpellMaxOptionB_OID)
		SetMaxCountOption(option, 12)
	elseIf (option == SettingAddSpellMaxOptionC_OID)
		SetMaxCountOption(option, 64)
	elseIf (option == SettingAddSpellEnable_OID)
		float capTime = DTSC_CaptureSpellAdd.GetValue()
		bool capOn = DTSC_CommonF.AddSpellCaptureTimeOK(capTime)
		if (capOn)
			; disable add-a-spell 
			DTSC_CaptureSpellAdd.SetValue(0.0)
			SetToggleOptionValue(option, false)
		else
			; enable add-a-spell
			float gameTime = Utility.GetCurrentGameTime()
			DTSC_CaptureSpellAdd.SetValue(gameTime)
			SetToggleOptionValue(option, true)
		endIf
	elseIf (option == SettingAddSpellReset_OID)
		DTSC_CaptureSpellAdd.SetValue(0.0)
		(KeepCleanQuestAlias as DTSC_PlayerAliasScript).RecoverCustomArmors()
		(KeepCleanQuestAlias as DTSC_PlayerAliasScript).RecoverCustomSpells()
		SetTextOptionValue(TextCustomSpellList_OID, "0")
		SetTextOptionValue(TextCustomArmorList_OID, "0")
	endIf 
endEvent

; ===============================
; functions

Function ResetPageAddSpell()
	SetCursorFillMode(TOP_TO_BOTTOM)
	
	AddHeaderOption("$AddSpellOverview")
	
	string spellCountStr = "" + DTSC_SpellsExtraList.GetSize()
	string itemCountStr = "" + DTSC_ArmorExtraList.GetSize()
	
	TextCustomSpellList_OID = AddTextOption("$CurrentSpellList", spellCountStr)
	TextCustomArmorList_OID = AddTextOption("$CurrentArmorList", itemCountStr)
	
	AddEmptyOption()
	AddEmptyOption()
	
	AddHeaderOption("$AddSpellControlHeader")
	
	float capTime = DTSC_CaptureSpellAdd.GetValue()
	bool capOn = DTSC_CommonF.AddSpellCaptureTimeOK(capTime)
	
	SettingAddSpellEnable_OID = AddToggleOption("$AddSpellEnabled", capOn)
	
	AddEmptyOption()
	
	SettingAddSpellReset_OID = AddTextOption("$AddSpellReset", "")
	
	SetCursorPosition(1)
	
	AddHeaderOption("$AddSpellMaxText")
	
	int capCountLim = DTSC_CaptureLimitSetting.GetValueInt()
	
	SettingAddSpellMaxOptionA_OID = AddToggleOption("4", capCountLim <= 4)
	SettingAddSpellMaxOptionB_OID = AddToggleOption("12", capCountLim == 12)
	SettingAddSpellMaxOptionC_OID = AddToggleOption("64", capCountLim == 64)
	
endFunction

Function ResetPageMain()
	
	SetCursorFillMode(TOP_TO_BOTTOM)
	
	float vers = DTSC_Version.GetValue()
	int versMaj = vers as int
	int versMin = ((vers - (versMaj as float)) * 100.0) as int
	
	AddHeaderOption("$AboutHeader")
	
	AddTextOption("$version", "" + versMaj + "." + versMin)
	AddTextOption("$monitoring", "" + DTSC_ModMonCount.GetValueInt())
	
	AddHeaderOption("$MainOptionHeader")
	
	SettingCleanEnabled_OID = AddToggleOption("$CleaningEnabled", DTSC_DisableSetting.GetValueInt() <= 0)
	SettingVerboseEnabled_OID = AddToggleOption("$VerboseEnabled", DTSC_VerboseSetting.GetValueInt() >= 1)
	SettingPreferMCM_OID = AddToggleOption("$InGameSpellEnabled", DTSC_MCMSetting.GetValueInt() <= 0)
	SettingRecheckMods_OID = AddToggleOption("$Recheckmods", DTSC_RecheckModsSetting.GetValueInt() >= 1)

	SetCursorPosition(1) ; Move cursor to top right position
	
	int waitSec = DTSC_WaitSecondsSetting.GetValueInt()
	AddHeaderOption("$Timerseconds")
	
	SettingTimerA_OID = AddToggleOption("16", waitSec <= 16)
	SettingTimerB_OID = AddToggleOption("30", waitSec == 24)
	SettingTimerC_OID = AddToggleOption("60", waitSec == 54)
	SettingTimerD_OID = AddToggleOption("240", waitSec >= 234)
	
	AddEmptyOption()
	
	AddHeaderOption("$Extras")
	
	
	if (DTSC_WearableLantConfig.GetValueInt() == 1)
		SettingCleanWL_OID = AddToggleOption("$CleanWLToggles", DTSC_WLToggleSettings.GetValueInt() == 1)
	endIf
	
	if (DTSC_iNeedAction.GetValueInt() >= 1)
		SettingClean_iNeed_OID = AddToggleOption("$CleaniNeedActions", DTSC_iNeedSetting.GetValueInt() == 1)
	endIf
	
	if (DTSC_HasItemMods.GetValueInt() > 0 || DTSC_HasItemsCustom.GetValueInt() > 0)
		SettingCleanItems_OID = AddToggleOption("$CleanItems", DTSC_IncludeItemsSetting.GetValueInt() == 1)
	endIf
	
endFunction

Function SetToggleGlobalVar(GlobalVariable aGlobalVar, int forOID, float valTrue)
	float val = aGlobalVar.GetValue()
	if (val <= 0.0)
		val = 1.0
	else
		val = 0.0
	endIf
	aGlobalVar.SetValue(val)
	SetToggleOptionValue(forOID, val == valTrue)
endFunction

Function SetMaxCountOption(int forOID, int toMaxCount)
	int maxCount = DTSC_CaptureLimitSetting.GetValueInt()
	int defMax = 64
	
	if (maxCount == toMaxCount)
		; toggle off - set default
		if (maxCount != defMax)
			toMaxCount = defMax
			SetToggleOptionValue(forOID, false)
			SetToggleOptionValue(SettingAddSpellMaxOptionC_OID, true)
		endIf
	else
		if (maxCount <= 4)
			SetToggleOptionValue(SettingAddSpellMaxOptionA_OID, false)
		elseIf (maxCount == 12)
			SetToggleOptionValue(SettingAddSpellMaxOptionB_OID, false)
		elseIf (maxCount >= 64)
			SetToggleOptionValue(SettingAddSpellMaxOptionC_OID, false)
		endIf
		
		SetToggleOptionValue(forOID, true)
	endIf
	
	DTSC_CaptureLimitSetting.SetValueInt(toMaxCount)
endFunction

Function SetWaitTimerOption(int forOID, float toWaitSec)
	float waitSec = DTSC_WaitSecondsSetting.GetValue()
	float defWaitSec = 24.0
	
	if (waitSec == toWaitSec)
		; toggle off - set default
		if (waitSec != defWaitSec)
			toWaitSec = defWaitSec
			SetToggleOptionValue(forOID, false)
			SetToggleOptionValue(SettingTimerB_OID, true)
		endIf
	else
		if (waitSec <= 12.0)
			SetToggleOptionValue(SettingTimerA_OID, false)
		elseIf (waitSec == 24.0)
			SetToggleOptionValue(SettingTimerB_OID, false)
		elseIf (waitSec == 54.0)
			SetToggleOptionValue(SettingTimerC_OID, false)
		else
			SetToggleOptionValue(SettingTimerD_OID, false)
		endIf
		
		SetToggleOptionValue(forOID, true)
	endIf
	
	DTSC_WaitSecondsSetting.SetValue(toWaitSec)
endFunction


