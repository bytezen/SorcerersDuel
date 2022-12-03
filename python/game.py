import character
import spell
import gesture


class Game:
    def __init__(self):
        self.mages = []
        self.monsters = []
        # who needs to move in current round
        self.need_to_gesture = []
        self.round = 0
        self.mage_count = None
        self.state = InitState(self)
        self.state.enter()

    def add_mage(self, mage):
        self.mages.append(mage)

    def add_monster(self, monster):
        self.monsters.append(monster)

    def kill_monster(self, monster):
        self.monsters.remove(monster)

    def everyone(self):
        return self.mages.union(self.monsters)

    def is_melee(self): 
        return len(self.mages) > 2

    def run(self):
        self.state.execute()

    def change_state(self, state):
        self.state.exit()
        print(f"changing state to {state.__class__.__name__}")
        self.state = state
        self.state.enter()

class State:
    def __init__(self, game):
        self.game = game

    def enter(self):
        pass

    def execute(self):
        pass

    def exit(self):
        pass

class InitState(State):
    def __init__(self, game):
        super().__init__(game)

    def execute(self):
        g = self.game
        if g.mage_count is not None:
            if len(g.mages) == g.mage_count:
                next = GestureState(g)
                g.change_state(next)
                
            else:
                mage = input(f"Mage {1 + len(g.mages)} shall be known as: ")
                
                g.mages.append(character.Mage(mage.capitalize()))
        
        else:
            count = int(input("How many mages in this duel? "))
            g.mage_count = count

class GestureState(State):
    def __init__(self, game):
        super().__init__(game)

    def enter(self):
        # filter mages and monsters for anyone who can't go this turn
        g = self.game
        world = g.mages + g.monsters
        g.need_to_gesture = [ being for being in world if being.__class__.__name__ == 'Mage' and not being.is_enchanted()]

    def execute(self):
        g = self.game

        if len(g.need_to_gesture) ==0:
            next = EvalGestureState(g)
            g.change_state(next)
            return

        print(f"awaiting gestures {[m.name for m in g.need_to_gesture]} characters")
        user_input = input("Enter mage, left hand gesture, right hand gesture:: ")

        mage_name,lh,rh = [ s.strip() for s in user_input.split(",")]
        mage_name = mage_name.capitalize()
        lh = lh.upper()
        rh = rh.upper()

        #look up mage
        result = [ m for m in g.need_to_gesture if m.name == mage_name]

        if len(result) == 0:
            print(f"{mage_name} does not need to gesture")
            return
        else:
            mage = result[0] #character.Mage(mage_name)

        #validate gestures
        if lh not in gesture.Valid:
            print(f"invalid left hand gesture {lh}")
            return
        elif rh not in gesture.Valid:
            print(f"invalid right hand gesture {rh}")
            return
        else:
            mage.gesture((lh,rh))
            print(f"{mage.name} gestures ..." )
            g.need_to_gesture.remove(mage)
            
        # if all good then add the gesture and remove them from the 
        # need_to_gesture list

    def exit(self):
        for m in self.game.mages:
            l_description = gesture.Description[m.LH[-1]]
            r_description = gesture.Description[m.RH[-1]]

            print(f"{m} {l_description} the left hand and {r_description} and the right hand.")

        self.game.need_to_gesture = []

class EvalGestureState(State):
    def __init__(self, game):
        super().__init__(game)


def process_round(mages=None, creatures=None):
    # check the spells in the order from the server

    # dispel magic 
    dispelMagic = any(map(lambda m : m.MagicDispelled))
    
    if dispelMagic:
        # all enchantments are false
        # monsters die AFTER they attack
        for m in mages:
            m.enchantments_off()

def process_gestures(mage):
    """
    this method assumes that the mages gesturs have already
    been committed (i.e. double handed gestures are already 
    accounted for)
    """
    # get list of spell gestures and filter by conjured
    pass

if __name__ == '__main__':
    # import logging
    process_round(mages=2,bar=4)