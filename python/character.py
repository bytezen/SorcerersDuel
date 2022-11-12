
class World:
    def __init__(self):
        self._mages = []
        self._monsters = []

    @property
    def mages(self):
        return self._mages

    @property
    def monsters(self):
        return self._monsters
    def add_mage(self, m):
        self._mages.append(m)

    def add_monster(self,m):
        self._monsters.append(m)

class Being:
    def __init__(self,name):
        self.hp = 14
        self.name = name

        self._post_turn_actions = []
        self.reset_state()

        self.Controller = None

    def add_post_turn_action(self, fn):
        self._post_turn_actions.append(fn)

    def update_post_attack(self):
        for fn in self._post_turn_actions:
            fn(self)

    def die(self):
        self._hp = 0

    def reset_state(self):
        self.afraid = False
        # self.BHDuration # both hands duration
        # self.BHSave  # both hands save
        # self.FireDuration
        # self.FireSpell
        # self.FireTarget
        # self.Blind
        # self.BlindTurns
        # self.BothSpell
        # self.BothTarget
        # self.Charmed
        # self.CharmedRight
        # self.CharmedLeft
        # self.ColdResistant
        # self.Confused
        # self.Countering
        # self.Dead
        # self.DelayPending
        # self.Fast
        # self.Forgetful
        # self.HastenedTurn
        # self.HeatResistant
        # self.HeavyWoundsCured
        # self.HitByFireBall
        # self.HitByLightning
        # self.HitByMissile
        # self.Invisible
        # self.InvisibleTurns
        # self.LastGestureLH
        # self.LastGestureRH
        # self.LH
        # self.LHDuration
        # self.LHSave
        # self.LeftSpell
        # self.LeftTarget
        # self.LightWoundsCured
        # self.Paralyzed
        # self.Paralyser
        # self.ParalyzedLeft
        # self.ParalyzedRight
        # self.PermanencyPending
        # self.Poisoned
        # self.Quote
        # self.RH
        # self.RHDuration
        # self.RHSave
        # self.ReceivedHeavyWounds
        # self.ReceivedLightWounds
        # self.Reflecting
        # self.RightSpell
        # self.RightTarget
        # self.SavedSpell
        # self.SavedTarget
        self.shielded = False
        # self.ShortLightningUsed
        # self.Sick
        # self.State
        # self.Surrendered
        # self.Target
        # self.TimeStopped
        # self.TimeStoppedTurn
        self.reflecting = False 
        self.countering = False 
        self.shielding = False




    def __str__(self):
        return self.name

class Mage(Being):
    def __init__(self, name):
        super().__init__(name)
        self._buffer = []
        self._slaves = []

    @property
    def spell_buffer(self):
        return self._buffer

    def clear_spell_buffer(self):
        print(f"{self._name} clearing spells from this turn: {self._buffer}")
        self._buffer = []

class Monster(Being):
    def __init__(self, name, controller, target, type):
        # super().__init__(f"{controller.name}'s {type}")
        super().__init__(name)
        self.type = type
        self.controller = controller
        self.target = target
    
class Goblin(Monster):
    def __init__(self, controller,target):
        name = f"{controller.name}'s Goblin{controller._goblinCount}"
        super().__init__(name,controller, target,"Goblin")

    def __str__(self):
        return f"{self.name}"



if __name__ == '__main__':
    world = World()
    marty = Mage('marty')
    steve = Mage('steve')

    world.add_mage(marty)
    world.add_mage(steve)

    cast_summon_goblin(world, marty, steve)

    print("monsters...")
    for monster in marty.monsters:
        print(monster, monster.health)
    
    cast_dispel_magic(world, marty)
    print("monsters after dispel magic")

    for monster in marty.monsters:
        monster.update_post_attack()
        print(monster, monster.health)
