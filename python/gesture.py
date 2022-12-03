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

Valid = ['F','P','S','W','D','>','-','C']

Description =  {'F': 'wriggles the fingers of',
                'P': 'proffers the palm of',
                'S': 'snaps the fingers of',
                'W': 'waves',
                'D': 'points the digit of',
                'C': 'claps with',
                '>': 'stabs with',
                '-': 'does nothing with'}
def randomGesture():
	return choice(['F','P','S','W','D','>','-','C'])
