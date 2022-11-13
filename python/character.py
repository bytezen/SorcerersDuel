import logging

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

# logger.warning('WARNING IS WORKING')
# logger.debug('IS DEBUG????')
# logger.info('IS INFO????')
# log.basicConfig(level=log.DEBUG, filename="game.log", filemode='a',
#      format='%(name)s:%(levelname)s: %(message)s')

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
        self.HitByMissile = False
        # self.Invisible
        # self.InvisibleTurns
        self.LastGestureLH = None
        self.LastGestureRH = None
        self.LH = ""
        # self.LHDuration
        # self.LHSave #unsused in original
        # self.LeftSpell
        # self.LeftTarget
        # self.LightWoundsCured
        self.MagicDispelled = False
        # self.Paralyzed
        # self.Paralyser
        # self.ParalyzedLeft
        # self.ParalyzedRight
        # self.PermanencyPending
        # self.Poisoned
        # self.Quote
        self.RH = ""
        # self.RHDuration
        # self.RHSave #unsused in original
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
        logger.info(f"{self.name} clearing spells from this turn: {self._buffer}")
        self._buffer = []

    def gesture(self, gesture_pair):
        L,R = gesture_pair

        # test for double hand move
        if L.lower() == R.lower():
            L = L.lower()
            R = R.lower()
        else:
            L = L.upper()
            R = R.upper()

        self.LH += L
        self.RH += R

    def left_gesture(self, gesture):
        pass
        self.LastGestureLH = gesture

    def right_gesture(self,gesture):
        pass
        self.LastGestureRH = gesture

    def commit_gestures(self):
        pass
        # double handed gesture that is not None
        if self.LastGestureLH == self.LastGestureRH and self.LastGestureLH is not None:
            self.LH += self.LastGestureLH.lower()
            self.RH += self.LastGestureRH.lower()
        else:
            if self.LastGestureLH is None:
                self.LH += '-'
            else:
                self.LH += self.LastGestureLH.upper()
        
            if self.LastGestureRH is None:
                self.RH += '-'
            else:
                self.RH += self.LastGestureRH.upper()

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

    marty.clear_spell_buffer()

