ScriptName DTSC_CommonF hidden

float Function GetGameTimeHoursDifference(float time1, float time2) global
	float result = 0.0
	if (time2 == time1)
		return 0.0
	elseIf (time2 > time1)
		result = time2 - time1
	else
		result = time1 - time2
	endIf
	result *= 24.0
	return result
endFunction

int Function RestoreArmor(Armor armItm, Actor actorRef) global
	if (armItm && actorRef.GetItemCount(armItm) == 0)
		actorRef.AddItem(armItm, 1, true)
		return 1
	endIf
	return 0
endFunction

int Function RestoreSpell(Spell sp, Actor actorRef) global
	if (sp && !actorRef.HasSpell(sp))
		actorRef.AddSpell(sp, false)
		return 1
	endIf
	return 0
endFunction