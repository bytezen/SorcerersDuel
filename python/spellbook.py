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
_Shield = ("Shield", "P", Protection)
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
SummonTroll, Fireball, _Shield, RemoveEnchantment, Invisibility, CharmMonster, CharmPerson, SummonOgre,
FingerOfDeath, Haste, MagicMissile, SummonGoblin, AntiSpell, TimeStop1, TimeStop2, ResistCold,
Fear, FireStorm, LightningBolt, CauseLightWounds, SummonGiant, CauseHeavyWounds, CounterSpell, IceStorm,
ResistHeat, Protection, CounterSpell]

# gestures and moves
from enum import Enum

class Gestures(Enum):
    Proffer,Digit,Finger,Snap,Wave,Clap,Stab,Empty = range(8)

    @classmethod
    def from_string(cls,s):
        s = s.lower()
        if s in ['p',"proffer"]:
            return Gestures.Proffer
        elif s in ['d',"digit"]:
            return Gestures.Digit 
        elif s in ['f',"finger"]: 
            return Gestures.Finger
        elif s in ['s',"snap"]: 
            return Gestures.Snap
        elif s in ['w',"wave"]:
            return  Gestures.Wave
        elif s in ['c',"clap"]:
            return Gestures.Clap
        elif s in ['>',"stab"]: 
            return Gestures.Stab
        elif s in [' ','','empty']:
            return Gestures.Empty
        else: 
            raise ValueError(f"unknown gesture: " + s)

    @classmethod
    def symbol(cls, g):
        if g == Gestures.Proffer:
            return "P"
        elif g == Gestures.Digit:
            return "D"
        elif g == Gestures.Finger:
            return "F"
        elif g == Gestures.Snap:
            return "S"
        elif g == Gestures.Wave:
            return "W"
        elif g == Gestures.Clap:
            return "c"
        elif g == Gestures.Stab:
            return ">"
        elif g == Gestures.Empty:
            return "-"
        else: 
            raise ValueError(f"unknown gesture {g}")

    def __str__(self):
        if self == Gestures.Proffer:
            return "Proffer"
        elif self == Gestures.Digit:
            return "Digit"
        elif self == Gestures.Finger:
            return "Finger"
        elif self == Gestures.Snap:
            return "Snap"
        elif self == Gestures.Wave:
            return "Wave"
        elif self == Gestures.Clap:
            return "Clap"
        elif self == Gestures.Stab:
            return "Stab"
        elif self == Gestures.Empty:
            return "Empty"
        else: 
            raise ValueError(f"unknown gesture {self}")

class Mage:
    pass

class Spell:
    name="Generic Spell"
    gestures=""
    type="Generic"

    @classmethod
    def cast(cls, mage,target=None):
        print(f"casting {cls.name}")

    def __init__(self, owner, target=None):
        self._duration = 1
        self._owner = owner
        self._target = target
        self._active = True
    @property
    def active(self): return self._active    

    @active.setter 
    def active(self,v):
        self._active = v

class Shield(Spell):
    name = _Shield[0]
    gestures = _Shield[1]
    type = _Shield[2]

    @classmethod
    def cast(cls,mage,target=None):
        super().cast(mage,target)

    def __init__(self, owner, target):
        super().__init__(owner, target)

def prefixes(s) :
    """ return all prefixes for a string"""
    ret = [ s[ slice(0,i)] for i in range(1,len(s))]
    ret.sort(key = len,reverse = True)
    return ret

def is_conjuring(gestures, spell):
    """ return true if the gestures match the spell up to the length of the spell -1.
    If the gestures match the spell then the spell is conjured and this will return False"""
    count = gestures_to_conjure(gestures,spell)
    return count > 0 and count < len(spell)
    # gestureCount = len(gestures)
    # spellLength = len(spell)

    # if gestureCount <= spellLength:
    #     return gestureCount if spell.startswith(gestures) else -1
    
    # if gestures.endswith(spell):
    #     print("spell should be conjured")
    #     return spellLength

    # spell_prefixes = prefixes(spell)
    # for p in spell_prefixes:
    #     if gestures.endswith(p):
    #         return len(p)

    # return -1

def is_conjured(gestures,spell):
    return gestures_to_conjure(gestures,spell) == 0

def gestures_to_conjure(gestures, spell):
    """ return the number of gestures needed to conjure
    the spell. Returns a value between 0 and len(spell).
    0 indicates that the spell is cast; len(spell) indicates
    that the spell has not started to be conjured"""

    #test the prefixes in descending order of length
    #to see if there are any matches...
    for p in prefixes(spell):
        if gestures.endswith(p):
            return len(spell) - len(p)
    
    # ... no matches? then we have all of the gestures
    # to cast the spell
    return len(spell)

def cast(mage, spell, target=None):
    pass



if __name__ == '__main__':
    # developing the spell resolution logic

    spells_cast = [_Shield, DispelMagic,Invisibility,DispelMagic]
    spells_in_effect = []

    # dispel magic
    # 2 dispel magic cancel out
    if DispelMagic in spells_cast:
        if len([ x for x in spells_cast if x == DispelMagic]) % 2 == 0:
            print('dispel magic cancels out')
        else:
            print('dispel magic is cast and takes effect')
            #DispelMagic.cast()

    shield = Shield(None, None)
    print(shield.active)
    shield.active = False
    print(shield.active)

    def testGestureInput():
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
                conjureLeftHand = is_conjuring(leftHand,spell)
                if conjureLeftHand > 0:
                    if conjureLeftHand == len(spell):
                        print(f"{name} conjured!!!")
                    else: 
                        print(f"conjuring {name} with left hand")

                conjureRightHand = is_conjuring(rightHand,spell)
                if conjureRightHand > 0:
                    if conjureRightHand == len(spell):
                        print(f"{name} conjured!!!")
                    else: 
                        print(f"conjuring {name} with right hand")