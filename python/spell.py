import logging 
from gesture import Gesture

logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)
# Create handler
c_handler = logging.StreamHandler()
f_handler = logging.FileHandler(f"{__name__}.log")
c_handler.setLevel(logging.DEBUG)
f_handler.setLevel(logging.DEBUG)
# Create formatters and add it to handlers
c_format = logging.Formatter('%(name)s - %(levelname)s - %(message)s')
f_format = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
c_handler.setFormatter(c_format)
f_handler.setFormatter(f_format)
# Add handlers to the logger
logger.addHandler(c_handler)
logger.addHandler(f_handler)
# logging.basicConfig(level=logging.DEBUG, filename="game.log", filemode='a',
    # format='%(name)s:%(levelname)s: %(message)s')

class Spell:
    Protection = "Protection"
    Damage = "Damage"
    Enchantment = "Enchantment"
    Summoning = "Summoning"

    @classmethod
    def get_cast_spell(cls, gestures):
        """
        return the Spell names that match the tail of gestures or None
        """
        # for spell in SpellBook:
            # print(f"{spell.name} with gestures: {spell.gestures} {spell.is_conjured(gestures)}")
        
        return [ spell for spell in SpellBook if spell.is_conjured(gestures)]


    def __init__(self, conjurer, target=None):
        print(f"the target is now:  {target}")
        self._duration = 1
        self.conjurer = conjurer
        self.target = target

    def cast(self):
        raise NotImplemented("subclasses should implement")

    # @property
    # def active(self): return self._active    


    # @property
    # def gestures(self): return self._gestures

    # @classmethod
    # # def is_conjuring(self, gs ):
    #     """ return true if the gestures match the spell up to the length of the spell -1.
    #     If the gestures match the spell then the spell is conjured and this will return False"""
    #     count = self.gestures_to_conjure(gs)
    #     return count > 0 and count < len(self.gestures)

    @classmethod
    def is_conjured(cls,gs):
        return cls.gestures_to_conjure(gs) == 0

    @classmethod
    def gestures_to_conjure(cls,gs):
        """ return the number of gestures needed to conjure
        the spell. Returns a value between 0 and len(spell).
        0 indicates that the spell is cast; len(spell) indicates
        that the spell has not started to be conjured"""

        #test the prefixes in descending order of length
        #to see if there are any matches...
        for p in prefixes(cls.gestures):
            if gs.endswith(p):
                return len(cls.gestures) - len(p)
        
        # ... no matches? then we have to do all of the gestures
        # to cast the spell
        return len(cls.gestures)

def prefixes(s) :
    """ return all prefixes for a string"""
    ret = [ s[ slice(0,i)] for i in range(1,len(s)+1)]
    ret.sort(key = len,reverse = True)
    return ret


class Shield(Spell):
    name = "Shield"
    gestures = 'P'
    type = Spell.Protection

    def __init__(self, conjurer, target=None):
        target = conjurer if target is None else target
        super().__init__(conjurer, target)

    def cast(self):
        logger.info(f"{self.conjurer} casting {self.name} @ {self.target}")
        self.target.shielded = True

class DispelMagic(Spell):
    name = "Dispel Magic"
    gestures ="cDPW"
    type = Spell.Protection

    def __init__(self, conjurer):
        super().__init__(conjurer)

    def cast(self):
        # remove all enchantments from everyone in the world
        # monsters should be removed after they attack.
        self.conjurer.MagicDispelled = True

class MagicMissile(Spell):
    name = "Magic Missile"
    gestures = "SD"
    type = Spell.Damage

    def __init__(self, conjurer, target):
        super().__init__(conjurer,target)

    def cast(self):
        self.target.HitByMissile = True

class MagicMirror(Spell):
    name = "Magic Mirror"
    gestures = "cw"
    type = Spell.Protection

    def __init__(self, conjurer, target):
        super().__init__(conjurer,target)

    def cast(self):
        self.target.Reflecting = True

class CounterSpell(Spell):
    name = "Counter Spell"
    gestures,classic = ["WPP","WWS"]
    type = Spell.Protection

    def __init__(self, conjurer, target):
        super().__init__(conjurer,target)

    def cast(self):
        self.target.Countering = True

class Amnesia(Spell):
    name = "Amnesia"
    gestures = "DPP"
    type = Spell.Enchantment

class Confusion(Spell):
    name = "Confusion"
    gestures = "DSF"
    type = Spell.Enchantment

SpellBook = [Shield,DispelMagic,MagicMissile,MagicMirror,CounterSpell,Amnesia,Confusion]

# Develop spell logic below
# TODO: move to another module

def cast_dispel_magic(world, conjurer, target=None):
    """
    This spell acts as a combination of Counter Spell and Remove Enchantment, but its effects are universal rather than limited to the subject of the spell.
    It will stop any spell cast in the same turn from working (apart from another Dispel Magic spell which combines with it for the same result), and will remove all enchantments from all beings before they have effect.
    In addition, all monsters are destroyed although they can attack that turn.
    Counter Spells and Magic Mirrors have no effect. The spell will not work on stabs or surrenders.
    As with a Counter Spell it also acts as a Shield for its subject.
    """

    logging.info("casting ... dispel_magic")

    # remove all spells cast in this turn
    # remove enchantments from everyone
    for mage in world.mages:
        mage.clear_spell_buffer()
        mage.reset_state()

    # schedule monsters to be destroyed
    for monster in world.monsters:
        monster.add_post_turn_action( lambda self,**args:
            self.die())
    
def cast_counter_spell(world, conjurer, target=None):
    if target is None:
        target = conjurer

    logging.info(f"{conjurer} casts counter spell @ {target}")
    target.countering = True
    target.shielding = True

def cast_summon_goblin(world, conjurer, target):
    """
    This spell creates a goblin under the control of the target of the spell 
    (or the target's controller, if the target is a monster). The goblin can 
    attack immediately and its victim will be opponent of its controller. 
    It does one point of damage to its victim per turn and is destroyed 
    after one point of damage is inflicted upon it. 
    The summoning spell cannot be cast at an elemental, and if cast at something which doesn't 
    exist, the spell has no effect.
    """
    logging.info(conjurer,"casting ... summon goblin")
    goblin = Goblin(conjurer,target)
    conjurer.add_monster(goblin)
    world.add_monster(goblin)

def cast_magic_mirror(world, conjurer, target=None):
    """
    """
    if target is None:
        target = conjurer

    logging.info(conjurer + 'casting magic mirror at' + target)
    target.reflecting = True

def cast_raise_dead(world, conjurer, target=None):
    pass

def process_spells(characters):
    pass

if __name__ == '__main__':
    print(f"Gesturing 'DPP' --> {Spell.get_cast_spell('DPP')}")