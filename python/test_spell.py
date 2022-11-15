import pytest
import spell as SpellBook
import character
from game import Game

# @pytest.fixture
# def shield():
#   return spell.Shield()

# @pytest.fixture
# def magic_missile():
#   return spell.MagicMissile()

@pytest.fixture
def mage1():
    return character.Mage("mage1")

@pytest.fixture
def mage2():
    return character.Mage("mage2")

# def test_gesture_distance():
    # pass

@pytest.fixture
def game():
    return Game()

def test_gesture_shield(mage1):
    assert SpellBook.Shield.name == "Shield"
    # mage1.left_gesture('P')
    mage1.gesture(('P','-'))
    shield = SpellBook.Shield(mage1)

    # mage1.commit_gestures()
    assert mage1.LH == "P"
    assert mage1.RH == "-"

    mage1 = character.Mage('mage1')

    mage1.gesture(('-','P'))
    assert mage1.RH == "P"
    assert mage1.LH == "-"

   # mage1.commit

def test_cast_shield(mage1,mage2):
    # spell = spell.Shield()
    shield = SpellBook.Shield(mage1)
    shield.cast()
    assert shield.target == mage1 
    assert mage1.shielded == True

    shield2 = SpellBook.Shield(mage1, mage2)
    shield2.cast()
    assert mage2.shielded == True

    # TODO: test shield interaction with other spell

# def test_shield_interactions(shield, mage1, mage2):
#     pass

def test_gesture_magic_missile(mage1, mage2):
    assert SpellBook.MagicMissile.name == "Magic Missile"

    for gesture in SpellBook.MagicMissile.gestures:
        mage1.gesture((gesture,'-'))

    assert mage1.LH == "SD"

    for gesture in SpellBook.MagicMissile.gestures:
        mage2.gesture(('-',gesture))

    assert mage2.RH == "SD"

def test_cast_magic_missile(mage1, mage2):
    spell = SpellBook.MagicMissile(mage1,mage2)
    spell.cast()

    assert mage2.HitByMissile == True

def test_gesture_dispel_magic(mage1,mage2):
    assert SpellBook.DispelMagic.name == "Dispel Magic"

    for idx,gesture in enumerate(SpellBook.DispelMagic.gestures):
        # starts with clap
        if idx == 0:
            mage1.gesture((gesture,'C'))
        else:
            mage1.gesture((gesture,'-'))

    assert mage1.LH == "cDPW" and mage1.RH.startswith("c")

    for idx,gesture in enumerate(SpellBook.DispelMagic.gestures):
        # starts with clap
        if idx == 0:
            mage2.gesture(('C',gesture))
        else:
            mage2.gesture(('-',gesture))

    assert mage2.RH == "cDPW" and mage2.LH.startswith("c")

def test_cast_dispel_magic(mage1):
    spell = SpellBook.DispelMagic(mage1)

    spell.cast()
    assert mage1.MagicDispelled

def test_conjure_magic_mirror(mage1):
    assert SpellBook.MagicMirror.name == "Magic Mirror"

    mage1.gesture(('C','C'))
    mage1.gesture(('W','W'))

    assert mage1.LH == SpellBook.MagicMirror.gestures
    assert mage1.LH == SpellBook.MagicMirror.gestures

def test_cast_magic_mirror(mage1, mage2):
    spell = SpellBook.MagicMirror(mage1,mage2)
    spell.cast()
    assert mage2.Reflecting

def test_conjure_counter_spell(mage1,mage2):
    assert SpellBook.CounterSpell.name == "Counter Spell"

    mage1.gesture(('W','-'))
    mage1.gesture(('P','-'))
    mage1.gesture(('P','-'))
    assert mage1.LH == SpellBook.CounterSpell.gestures

    mage2.gesture(('-','W'))
    mage2.gesture(('-','P'))
    mage2.gesture(('-','P'))
    assert mage2.RH == SpellBook.CounterSpell.gestures

def test_cast_counter_spell(mage1,mage2):
    spell = SpellBook.CounterSpell(mage1,mage1)
    spell.cast()
    assert mage1.Countering == True

