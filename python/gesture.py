from enum import Enum
from random import choice

Gesture = Enum(
    value="Gesture",
    names= [
        ("F","finger"),
		("P","proffer"),
		("S","snap"),
		("W","wave"),
		("D","digit"),
		("K","stab"),
		("N","nothing"),
        ("c","clap")
		# ("d","2 handed digit"),
		# ("w","2 handed wave"),
		# ("s","2 handed snap"),
		# ("p","2 handed proffer"),
    ])


def randomGesture():
	return choice(['F','P','S','W','D','>','-','C'])
