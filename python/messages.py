welcome = """
Welcome to Cragmoor Mountain. """

start_duel ="""
%s and %s step into The Cauldron and warily bow to one another
"""
start_melee="""
The mages, %s, scamper to their positions around The Cauldron
"""

make_gesture ="""
%s gestures %s with their left hand and
%s with their right hand
"""

gesture_history="""
%s Gestures
LH: %s
RH: %s
"""

class Messages:

    def __init__(self,game):
        self.game = game
        self.mages = list(self.game.mages)

    def welcome(self):
        if len(self.mages) == 2:
            return (welcome % (self.game.mages[0], self.game.mages[1]))
        else:
            return " and ".join( [ ", ".join(self.mages[:-1]), self.mages[-1]] )

    def start(self):
        if self.game.is_melee():
            msg = ", ".join(self.mages[:-1])
            msg = " and ".join([msg, self.mages[-1]])
            return (start_melee % msg)
        else:
            return (start_duel % tuple(self.mages))

    def gesture(self, mage, gesture):
        return make_gesture % (mage, gesture[0], gesture[1])

    def gesture_history(self, mage):
        return (mage.LH, mage.RH)

if __name__ =='__main__':
    import game
    import character


    steve = character.Mage('steve')
    doera = character.Mage('doera')

    g = game.Game()
    g.add_mage( steve )
    g.add_mage( doera )

    Msg = Messages(g)
    print(Msg.start())

    steve.gesture(('P','S'))
    print(Msg.gesture(steve, ('P','S')))
