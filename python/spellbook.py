Protection = "Protection"
Summon = "Summoning"
Enchatment = "Enchantment"
Damaging = "Damaging"

DispelMagic = ("Dispel Magic", "cDPW", Protection)
SummonIceElemental = ("Summon Ice Elemental", "cSWWS",Summon)
SummonFireElemental = ("Summon Fire Elemental", "cWSSW",Summon)
MagicMirror = ("Magic Mirror", "cw", Protection)
LightningBolt = ("Lightning Bolt", "DFFDD")
CureHeavyWounds = ("Cure Heavy Wounds", "DFPW", Protection)
CureLightWounds = ("Cure Light Wounds", "DFW", Protection)
Amnesia = ("Amnesia", "DPP")
Confusion = ("Confusion", "DSF")
Disease = ( "Disease", "DSFFFc")
Blindness = ("Blindness", "DWFFd")
DelayEffect = ( "Delay Effect", "DWSSSP")
RaiseDead = ( "Raise Dead", "DWWFWc", Protection)
Poison = ( "Poison", "DWWFWD")
Paralysis = ("Paralysis", "FFF")
SummonTroll = ("Summon Troll", "FPSFW",Summon)
Fireball = ("Fireball", "FSSDD")
Shield = ("Shield", "P", Protection)
RemoveEnchantment = ("Remove Enchantment", "PDWP", Protection)
Invisibility = ("Invisibility", "PPws")
CharmMonster = ("Charm Monster", "PSDD")
CharmPerson = ("Charm Person", "PSDF")
SummonOgre = ("Summon Ogre", "PSFW",Summon)
FingerOfDeath = ("Finger of Death", "PWPFSSSD")
Haste = ("Haste", "PWPWWc" )
MagicMissile = ("Magic Missile", "SD")
SummonGoblin = ("Summon Goblin", "SFW",Summon)
AntiSpell = ("Anti Spell", "SPFP")
SPFPSDW = ("Permanency", "SPFPSDW")
TimeStop1 = ("Time Stop", "SPPc")
TimeStop2 = ("Time Stop", "SPPFD")
ResistCold = ("Resist Cold", "SSFP")
Fear = ("Fear", "SWD")
FireStorm = ("Fire Storm", "SWWc")
LightningBolt = ("Lightning Bolt", "WDDc")
CauseLightWounds = ("Cause Light Wounds", "WFP")
SummonGiant = ( "Summon Giant", "WFPSFW",Summon)
CauseHeavyWounds = ("Cause Heavy Wounds", "WPFD")
CounterSpell = ("Counter Spell", "WPP", Protection)
IceStorm = ("Ice Storm", "WSSc")
ResistHeat = ("Resist Heat", "WWFP")
Protection = ("Protection", "WWP")
CounterSpell2 = ("Counter Spell", "WWS", Protection)

StandardBook = [
DispelMagic, SummonIceElemental, SummonFireElemental, MagicMirror, LightningBolt, CureHeavyWounds,
CureLightWounds, Amnesia, Confusion, Disease, Blindness, DelayEffect, RaiseDead, Poison, Paralysis,
SummonTroll, Fireball, Shield, RemoveEnchantment, Invisibility, CharmMonster, CharmPerson, SummonOgre,
FingerOfDeath, Haste, MagicMissile, SummonGoblin, AntiSpell, TimeStop1, TimeStop2, ResistCold,
Fear, FireStorm, LightningBolt, CauseLightWounds, SummonGiant, CauseHeavyWounds, CounterSpell, IceStorm,
ResistHeat, Protection, CounterSpell]

def prefixes(s) :
    """ return all prefixes for a string"""
    ret = [ s[ slice(0,i)] for i in range(1,len(s))]
    ret.sort(key = len,reverse = True)
    return ret

def conjuring(gestures, spell):
    """ return true if the gestures match the spell up to the length of the spell -1.
    If the gestures match the spell then the spell is conjured and this will return False"""

    gestureCount = len(gestures)
    spellLength = len(spell)

    if gestureCount <= spellLength:
        return gestureCount if spell.startswith(gestures) else -1
    
    if gestures.endswith(spell):
        print("spell should be conjured")
        return spellLength

    spell_prefixes = prefixes(spell)
    for p in spell_prefixes:
        if gestures.endswith(p):
            return len(p)

    return -1

if __name__ == '__main__':
    SpellBook = [DispelMagic,SummonIceElemental,SummonFireElemental,MagicMirror,LightningBolt]
    leftHand = ""
    rightHand = ""


            
    # print(SpellBook)
    # print(prefixes(LightningBolt[1]) )
    # print(prefixes(SummonFireElemental[1]) )
    # exit(0)

    while(True):
        lh = (input("input left gesture: ")).upper()
        rh = (input("input right gesture: ")).upper()


        if lh == rh: 
            if rh == 'P':
                print('surrendered')
                break
            elif rh == 'C':
                leftHand += lh.lower()
                rightHand += rh.lower()
        else:
            rightHand += '-' if rh == 'C' else rh
            leftHand += '-' if lh == 'C' else lh

        print(f"left hand: {leftHand}") 
        print(f"right hand: {rightHand}") 
        
        for name,spell in SpellBook:
            # print(name, spell)
            conjureLeftHand = conjuring(leftHand,spell)
            if conjureLeftHand > 0:
                if conjureLeftHand == len(spell):
                    print(f"{name} conjured!!!")
                else: 
                    print(f"conjuring {name} with left hand")

            conjureRightHand = conjuring(rightHand,spell)
            if conjureRightHand > 0:
                if conjureRightHand == len(spell):
                    print(f"{name} conjured!!!")
                else: 
                    print(f"conjuring {name} with right hand")