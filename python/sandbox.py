from enum import Enum

Gesture = Enum(
    value="Gesture",
    names= [
        ("F","finger"),
		("P","proffer"),
		("S","snap"),
		("W","wave"),
		("D","digit"),
		(">","stab"),
		("-","nothing")
	    # ("LF","left_finger"),
		# ("LP","left_proffer"),
		# ("LS","left_snap"),
		# ("LW","left_wave"),
		# ("LD","left_digit"),
		# ("LK","left_stab"),
		# ("L","left_nothing"),
		# ("RF","right_finger"),
		# ("RP","right_proffer"),
		# ("RS","right_snap"),
		# ("RW","right_wave"),
		# ("RD","right_digit"),
		# ("RK","right_stab"),
		# ("R","right_nothing")
    ])

def get_mage_move(gesture_tuple):
    left, right = gesture_tuple
    if left is not None:
        if len(left) == 1:
            left_gesture = '-'
        else:
            left_gesture = left[0][1]
    else:
        left_gesture = '-'

    if right is not None:
        if len(right) == 1:
            right_gesture = '-'
        else:
            right_gesture = right[0][1]
    else:
        right_gesture = '-'

    if right_gesture == left_gesture:
        return right_gesture.lower()
    else:
        return (left_gesture, right_gesture)


# mages
# standard spell book
standard_book = [("cDPW",   "Dispel Magic"),
("cSWWS",  "Summon Ice Elemental"),
("cWSSW",  "Summon Fire Elemental"),
("cw",     "Magic Mirror"),
("DFFDD",  "Lightning Bolt"),
("DFPW",   "Cure Heavy Wounds"),
("DFW",    "Cure Light Wounds"),
("DPP",    "Amnesia"),
("DSF",    "Confusion"),
("DSFFFc", "Disease"),
("DWFFd",  "Blindness"),
("DWSSSP", "Delay Effect"),
("DWWFWc", "Raise Dead"),
("DWWFWD", "Poison"),
("FFF",    "Paralysis"),
("FPSFW",  "Summon Troll"),
("FSSDD",  "Fireball"),
("P",      "Shield"),
("PDWP",   "Remove Enchantment"),
("PPws",   "Invisibility"),
("PSDD",   "Charm Monster"),
("PSDF",   "Charm Person"),
("PSFW",   "Summon Ogre"),
("PWPFSSSD", "Finger of Death"),
("PWPWWc", "Haste"),
("SD",     "Magic Missile"),
("SFW",    "Summon Goblin"),
("SPFP",   "Anti Spell"),
("SPFPSDW","Permanency"),
("SPPc",   "Time Stop"),
("SPPFD",  "Time Stop"),
("SSFP",   "Resist Cold"),
("SWD",    "Fear"),
("SWWc",   "Fire Storm"),
("WDDc",   "Lightning Bolt"),
("WFP",    "Cause Light Wounds"),
("WFPSFW", "Summon Giant"),
("WPFD",   "Cause Heavy Wounds"),
("WPP",    "Counter Spell"),
("WSSc",   "Ice Storm"),
("WWFP",   "Resist Heat"),
("WWP",    "Protection"),
("WWS",    "Counter Spell")]

def prefixes(s) :
    """ return all prefixes for a string"""
    return [ s[ slice(0,len(s)-i)] for i in range(len(s))]


def suffixes(s,num):
    """ return the suffixes of length num from string"""
    return [ s[slice(-num + i, len(s))] for i in range(num) ]


def valid_spell(spell, gestures):
    spell_len = len(spell[0])
    return False

print(suffixes("DFSP>-WDF",5))

#Play State
leftHand = []
rightHand = []

mentalState = None
health = 14

class Mage:
    def __init__(self,name):
        self.name = name
        


class Spell:
    def DispelMagic(cls):
        if not Spell.DispelMagic:
            cls.DispelMagic = Spell("DispleMagic","cDPW")

    def __init__(self, name, standard, classic=None):
        self.name = name
        self.gestures = standard
        self.classic = classic
        if self.classic is None:
            self.classic = self.gestures

    def __str__(self):
        return self.name
    
    def __repr__(self):
        return f"{self.name},{self.gestures}"

DispelMagic = Spell("DispelMagic","cDPW")
print(f"{DispelMagic!r}")

if __name__ == '__main__':
    wally = Mage("Wally")

    print(wally)
    shield = Spell("shield", "S")
    print(shield.gestures, len(shield.gestures))
    print(Spell.DispelMagic)