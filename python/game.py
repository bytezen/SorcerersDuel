import character
import spell

class Game:
    def __init__(self):
        self.mages = {}
        self.monsters = {}
        self.round = 0

    def add_mage(self, mage):
        self.mages.add(mage)

    def add_monster(self, monster):
        self.monsters.add(monster)

    def kill_monster(self, monster):
        self.monsters.remove(monster)

    def everyone(self):
        return self.mages.union(self.monsters)

def process_round(mages=None, creatures=None):
    pass

def process_gestures(mage):
    # get list of spell gestures and filter by conjured
    pass

if __name__ == '__main__':
    # import logging
    process_round(mages=2,bar=4)