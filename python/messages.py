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

    def __init__(self):
        pass

    def welcome(self):
        if len(self.mages) == 2:
            return (welcome % (self.game.mages[0], self.game.mages[1]))
        else:
            return " and ".join( [ ", ".join(self.mages[:-1]), self.mages[-1]] )

    def start(self, mages):
        msg =""
        if len(mages) == 2:
            msg = """
            The Council of Elders welcomes you to a battle of skill and wit
            between %s and %s
            """ % tuple(mages)

        print(msg)

    def gesture(self, mage):
        msg = """
        %s gestures 
        %s with his left hand 
        %s with his right hand
        """
        print(msg % (mage, mage.LH[-1], mage.RH[-1]))

    def gesture_history(self, mage):
        msg = """
        %s's gestures have been:
        LH: %s
        RH: %s
        """ 
        print(msg % (mage, " ".join(mage.LH), " ".join(mage.RH))) 

if __name__ =='__main__':
    import game
    import character


    steve = character.Mage('steve')
    doera = character.Mage('doera')

    g = game.Game()
    g.add_mage( steve )
    g.add_mage( doera )

    Msg = Messages()

    Msg.start(g.mages)
    steve.gesture(('P','S'))
    steve.gesture(('P','S'))
    steve.gesture(('P','S'))
    Msg.gesture(steve)
    Msg.gesture_history(steve)


    # print(Msg.gesture(steve, ('P','S')))
