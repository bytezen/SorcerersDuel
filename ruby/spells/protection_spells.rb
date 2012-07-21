require File.dirname(__FILE__) + '/spell'
require File.dirname(__FILE__) + '/damaging_spells'
require File.dirname(__FILE__) + '/summoning_spells'
require File.dirname(__FILE__) + '/gestures'
require File.dirname(__FILE__) + '/spell_state_manager'

  
class Shield < Spell  
  Gestures = "#{Gesture.Profer}"
  @@gestures = HandGesture.new(Gestures)
  Name = 'Shield'
  @@blocked_spells = [MagicMissile::Name, SummonOgre::Name, SummonGoblin::Name, SummonTroll::Name, SummonGiant::Name]
  @@effect = Proc.new do |subject,target|

      puts "#{target.invoked_spells}"
      #puts target.invoked_spells      
      #target.invoked_spells.each {|spell| puts "target invoked #{spell}" }
      #puts " #{subject} conjures #{self} on #{target}!"
  end
  
  #private_class_method :new
  
  def initialize(name,gestures,effect)
    super(name,gestures,effect)
  end
 # def initialize
 #   @name = Name
 #   @invocation_gestures = @@gestures
 #   @effect = @@effect
 #   @state_manager = SpellStateManager.new(@@effect)
 #   test_effect_processing
 # end
  
  def Shield.conjure
    #@@me = new unless @@me
    #@@me
    Shield.new(Name,@@gestures,@@effect)
  end
 
end #Shield

class RemoveEnchantment < Spell
  Gestures = "#{Gesture.Profer}#{Gesture.Digit}#{Gesture.Wave}#{Gesture.Profer}"
  @@gestures = HandGesture.new(Gestures)
  
  #@@me = nil
  Name = 'RemoveEnchantment'
  #@@gestures = [Gesture.Profer, Gesture.Digit, Gesture.Wave, Gesture.Profer]
  @@effect = '{source} removes enchantment from himself.  (If he is a monster) {source} attacks and dies with {hand} hand'
  #private_class_method :new
  
  def initialize
    @name = Name
    @invocation_gestures = @@gestures
    @effect = @@effect  
  end
  
  def RemoveEnchantment.conjure
    #@@me = new unless @@me
    #@@me
    RemoveEnchantment.new
  end
end #RemoveEnchantment

class MagicMirror < Spell
  Gestures = "#{Gesture.Clap}#{Gesture.Wave}"
  @@gestures = HandGesture.new(Gestures,/CW$/)    
  #@@me = nil
  Name = 'MagicMirror'
  @@effect = '{source} reflects all spells'
  #private_class_method :new
  
  def initialize
    @name = Name
    @invocation_gestures = @@gestures
    @effect = @@effect  
  end
  
  def MagicMirror.conjure
    #@@me = new unless @@me
    ##@@me
    MagicMirror.new
  end
end #magicMirror

class StandardCounterSpell < Spell
  Gestures = "#{Gesture.Wave}#{Gesture.Profer}#{Gesture.Profer}"
  @@gestures = HandGesture.new(Gestures)       
  #@@me = nil
  Name = 'StandardCounterSpell'

  @@effect = '{source} removes enchantment from himself.  (If he is a monster) {source} attacks and dies with {hand} hand'
  #private_class_method :new
  
  def initialize
    @name = Name
    @invocation_gestures = @@gestures
    @effect = @@effect  
  end
  
  def StandardCounterSpell.conjure
    #@@me = new unless #@@me
    #@@me
    StandardCounterSpell.new
  end
end #StandardcounterSpell

class ClassicCounterSpell < Spell
  Gestures = "#{Gesture.Wave}#{Gesture.Wave}#{Gesture.Snap}"
  @@gestures = HandGesture.new(Gestures)       
  #@@me = nil
  Name = 'ClassicCounterSpell'
  #@@gestures = "#{Gesture.Wave}#{Gesture.Wave}#{Gesture.Snap}"
  @@effect = '{source} removes enchantment from himself.  (If he is a monster) {source} attacks and dies with {hand} hand'
  #private_class_method :new
  
  def initialize
    @name = Name
    @invocation_gestures = @@gestures
    @effect = @@effect  
  end
  
  def ClassicCounterSpell.conjure
    #@@me = new unless #@@me
    #@@me
    ClassicCounterSpell.new
  end
end #ClassicCounterSpell


class DispelMagic < Spell
  Gestures = "#{Gesture.Digit}#{Gesture.Profer}#{Gesture.Wave}"
  @@gestures = HandGesture.new(Gestures,/C.{3}$/)   
  #@@me = nil
  Name = 'DispelMagic'
  Power = 1
  @@effect = 
  #private_class_method :new
  
  @@effect = Proc.new do |subject,target|
      target.invoked_spells.each do |spell| 
        spell.countered = true
        puts "Eff:: #{target}'s #{spell} was countered by #{subject}'s #{self}"
      end
      subject.invoked_spells.each do |spell|
        next if spell = self
        spell.countered = true
        puts "Eff:: #{subject}'s #{spell} was countered by their own #{self}"
      end
  end

  def initialize(name,gestures,effect)
    super(name,gestures,effect)
  end
  
  def DispelMagic.conjure
    #@@me = new unless #@@me
    #@@me
    DispelMagic.new(Name,@@gestures,@@effect)
  end
end #dispelMagic


class RaiseDead < Spell
  Gestures = "#{Gesture.Digit}#{Gesture.Wave}#{Gesture.Wave}#{Gesture.Finger}#{Gesture.Wave}#{Gesture.Clap}"
  @@gestures = HandGesture.new(Gestures,/C$/)   
  #@@me = nil
  Name = 'RaiseDead'
  @@effect = 'The dead are raised'
  #private_class_method :new
  
  def initialize
    @name = Name
    @invocation_gestures = @@gestures
    @effect = @@effect  
  end
  
  def RaiseDead.conjure
    #@@me = new unless #@@me
    #@@me
    RaiseDead.new
  end
end #RaiseDead


class CureLightWounds < Spell
  Gestures = "#{Gesture.Digit}#{Gesture.Finger}#{Gesture.Wave}"
  @@gestures = HandGesture.new(Gestures)   
  #@@me = nil
  Name = 'CureLightWounds'
  @@effect = 'Light wounds are cured'
  #private_class_method :new
  
  def initialize
    @name = Name
    @invocation_gestures = @@gestures
    @effect = @@effect  
  end
  
  def CureLightWounds.conjure
    #@@me = new unless #@@me
    #@@me
    CureLightWounds.new
  end
end #CureLightWounds


class CureHeavyWounds < Spell
  Gestures = "#{Gesture.Digit}#{Gesture.Finger}#{Gesture.Profer}#{Gesture.Wave}"
  @@gestures = HandGesture.new(Gestures)   
  #@@me = nil
  Name = 'CureHeavyWounds'
  @@effect = 'Heavy wounds are cured'
  #private_class_method :new
  
  def initialize
    @name = Name
    @invocation_gestures = @@gestures
    @effect = @@effect  
  end
  
  def CureHeavyWounds.conjure
    #@@me = new unless #@@me
    #@@me
    CureHeavyWounds.new
  end
end #CureHeavyWounds





if __FILE__ == $0
  
  #ProtectionSpells.write_book
  #ProtectionSpells.spell_book.each {|spell| puts spell}    
  gestures = ["PEWWS","PECD"] 
  testSpell = ClassicCounterSpell.new #ProtectionSpells::DispelMagic.conjure
  puts testSpell.invoked?(gestures)
  #puts "invoked" if testSpell.invocation_gestures.invoked_by_right_hand?(gestures)
end