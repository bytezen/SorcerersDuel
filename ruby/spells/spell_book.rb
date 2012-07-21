require File.dirname(__FILE__) + '/gestures'
require File.dirname(__FILE__) + '/protection_spells'
require File.dirname(__FILE__) + '/damaging_spells'
require File.dirname(__FILE__) + '/summoning_spells'
require File.dirname(__FILE__) + '/enchantment_spells'


module SpellBook
  SpellBook = []

  def SpellBook.valid_spell?(spellname)
    SpellBook.each {|spell| return spell if(spell.name == spellname) }  
  end
  
  #Gestures is an array of handGestures
  def invoke_spell(gestures)
    puts "got here : #{gestures[$LeftHand]}"
    right_invokeList = []  
    left_invokeList = []

    SpellBook.each do |spell| 
      puts "testing spell -- #{spell}"
      puts "\t#{spell.invoked_by_left_hand?(gestures[$LeftHand])}"
      right_invokeList << spell if spell.invoked_by_right_hand?(gestures[$RightHand])
      left_invokeList << spell if spell.invoked_by_left_hand?(gestures[$LeftHand])          
    end
    #puts "right invoke list = #{right_invokeList}"
    #puts "left invoke list = #{left_invokeList}"
    [right_invokeList, left_invokeList]
  end

    SpellBook << Shield.conjure
    SpellBook << RemoveEnchantment.conjure
    SpellBook << MagicMirror.conjure
    SpellBook << StandardCounterSpell.conjure
    SpellBook << ClassicCounterSpell.conjure
    SpellBook << DispelMagic.conjure
    SpellBook << RaiseDead.conjure
    SpellBook << CureLightWounds.conjure
    SpellBook << CureHeavyWounds.conjure
    #SummoningSpells
    SpellBook << SummonGoblin.conjure
    SpellBook << SummonOgre.conjure
    SpellBook << SummonTroll.conjure
    SpellBook << SummonGiant.conjure
    SpellBook << SummonIceElemental.conjure
    SpellBook << StandardSummonFireElemental.conjure
    SpellBook << ClassicSummonFireElemental.conjure
    #DamagingSpells
    SpellBook << MagicMissile.conjure
    SpellBook << FingerOfDeath.conjure
    SpellBook << ClassicLightningBolt.conjure
    SpellBook << StandardLightningBolt.conjure
    SpellBook << CauseLightWounds.conjure
    SpellBook << CauseHeavyWounds.conjure
    SpellBook << Fireball.conjure
    SpellBook << FireStorm.conjure
    SpellBook << IceStorm.conjure     
    #EnchantmentSpells
    SpellBook << Amnesia.conjure
    SpellBook << Confusion.conjure
    SpellBook << CharmPerson.conjure
    SpellBook << CharmMonster.conjure
    SpellBook << Paralysis.conjure
    SpellBook << Fear.conjure
    SpellBook << AntiSpell.conjure
    SpellBook << Protection.conjure
    SpellBook << ResistHeat.conjure
    SpellBook << ResistCold.conjure
    SpellBook << Disease.conjure
    SpellBook << Poison.conjure
    SpellBook << Blindness.conjure
    SpellBook << Invisibility.conjure
    SpellBook << Haste.conjure
    SpellBook << StandardTimeStop.conjure
    SpellBook << TimeStop.conjure
    SpellBook << DelayEffect.conjure
    SpellBook << Permanency.conjure
end #SpellBook

class Test
  include SpellBook
  attr_reader :me
  @me
  def initialize(gestures)
    @me = invoke_spell(gestures)
  end      
end

###Library Testing Code
if(__FILE__ == $0)
  me = Test.new(["P","SD"])
  puts me.me
end