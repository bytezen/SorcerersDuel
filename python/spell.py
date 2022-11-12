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

    print("casting ... dispel_magic")

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

    print(f"{conjurer} casts counter spell @ {target}")
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
    print(conjurer,"casting ... summon goblin")
    goblin = Goblin(conjurer,target)
    conjurer.add_monster(goblin)
    world.add_monster(goblin)

def cast_magic_mirror(world, conjurer, target=None):
    """
    """
    if target is None:
        target = conjurer

    print(conjurer + 'casting magic mirror at' + target)
    target.reflecting = True

def cast_raise_dead(world, conjurer, target=None):
    pass
