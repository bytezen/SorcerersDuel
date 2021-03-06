require "gestures"
require "protection_spells"
require "damaging_spells"
require "summoning_spells"
require "enchantment_spells"


class SpellBook
  @@me = nil
  
  private_class_method :new
  
  def initialize
    @spell_book = []
    initialize_protection_spells
    initialize_damaging_spells
    initialize_summoning_spells
    initialize_enchantment_spells    
  end

  def SpellBook.get_spell_book
    @@me = new unless @@me
    @@me
  end

  #Gestures is an array of handGestures
  def invokeSpell(gestures)
    invokeList = []  
    @spell_book.each {|spell| puts "#{spell} invoked" if spell.invoked?(gestures) }      
    invokeList
  end


  private 
  def initialize_protection_spells
    @spell_book << Shield.new
    @spell_book << RemoveEnchantment.new
    @spell_book << MagicMirror.new
    @spell_book << StandardCounterSpell.new
    @spell_book << ClassicCounterSpell.new
    @spell_book << DispelMagic.new
    @spell_book << RaiseDead.new
    @spell_book << CureLightWounds.new
    @spell_book << CureHeavyWounds.new
  end
  def initialize_summoning_spells
    @spell_book << SummonGoblin.new
    @spell_book << SummonOgre.new
    @spell_book << SummonTroll.new
    @spell_book << SummonGiant.new
    @spell_book << SummonIceElemental.new
    @spell_book << StandardSummonFireElemental.new
    @spell_book << ClassicSummonFireElemental.new
  end
  def initialize_damaging_spells
    @spell_book << MagicMissile.new
    @spell_book << FingerOfDeath.new
    @spell_book << ClassicLightningBolt.new
    @spell_book << StandardLightningBolt.new
    @spell_book << CauseLightWounds.new
    @spell_book << CauseHeavyWounds.new
    @spell_book << Fireball.new
    @spell_book << FireStorm.new
    @spell_book << IceStorm.new     
  end
  def initialize_enchantment_spells    
    @spell_book << Amnesia.new
    @spell_book << Confusion.new
    @spell_book << CharmPerson.new
    @spell_book << CharmMonster.new
    @spell_book << Paralysis.new
    @spell_book << Fear.new
    @spell_book << AntiSpell.new
    @spell_book << Protection.new
    @spell_book << ResistHeat.new
    @spell_book << ResistCold.new
    @spell_book << Disease.new
    @spell_book << Poison.new
    @spell_book << Blindness.new
    @spell_book << Invisibility.new
    @spell_book << Haste.new
    @spell_book << StandardTimeStop.new
    @spell_book << TimeStop.new
    @spell_book << DelayEffect.new
    @spell_book << Permanency.new
  end
  
  
end #SpellBook

###Library Testing Code
if(__FILE__ == $0)


end

__END__
