require File.dirname(__FILE__) + '/spell'
require File.dirname(__FILE__) + '/gestures'

class MagicMissile < Spell  
  Gestures = "#{Gesture.Snap}#{Gesture.Digit}"
  @@gestures = HandGesture.new(Gestures)
  #@@me = nil
  Name = 'MagicMissile'
  @@name = 'MagicMissile'
  @@effect = Proc.new { |subject,target| puts 'MagicMissile effect goes here' }
  
  #private_class_method :new

  def initialize(name,gestures,effect)
    super(name,gestures,effect)
  end

#  def initialize
#    @name = @@name
#    @invocation_gestures = @@gestures
#    @effect = @@effect
#  end
  
  def MagicMissile.conjure
    #@@me = new unless @@me
    #@@me
    MagicMissile.new(Name,@@gestures,@@effect)
  end
 
end #MagicMissile

class FingerOfDeath < Spell
  Gestures = "#{Gesture.Profer}#{Gesture.Wave}#{Gesture.Profer}#{Gesture.Finger}#{Gesture.Snap}#{Gesture.Snap}#{Gesture.Snap}#{Gesture.Digit}"
  @@gestures = HandGesture.new(Gestures)
  
  #@@me = nil
  @@name = 'FingerOfDeath'
  #@@gestures = [Gesture.Profer, Gesture.Digit, Gesture.Wave, Gesture.Profer]
  @@effect = '{source} removes enchantment from himself.  (If he is a monster) {source} attacks and dies with {hand} hand'
  #private_class_method :new
  
  def initialize
    @name = @@name
    @invocation_gestures = @@gestures
    @effect = @@effect  
  end
  
  def FingerOfDeath.conjure
    #@@me = new unless @@me
    #@@me
    FingerOfDeath.new
  end
end #FingerOfDeath

class ClassicLightningBolt < Spell
  Gestures = "#{Gesture.Wave}#{Gesture.Digit}#{Gesture.Digit}#{Gesture.Clap}"
  @@gestures = HandGesture.new(Gestures,/C$/)    
  #@@me = nil
  @@name = 'ClassicLightningBolt'
  @@effect = '{source} reflects all spells'
  #private_class_method :new
  
  def initialize
    @name = @@name
    @invocation_gestures = @@gestures
    @effect = @@effect  
  end
  
  def ClassicLightningBolt.conjure
    #@@me = new unless @@me
    ##@@me
    ClassicLightningBolt.new
  end
end #ClassicLightningBolt

class StandardLightningBolt < Spell
  Gestures = "#{Gesture.Digit}#{Gesture.Finger}#{Gesture.Finger}#{Gesture.Digit}#{Gesture.Digit}"
  @@gestures = HandGesture.new(Gestures)       
  #@@me = nil
  @@name = 'StandardLightningBolt'

  @@effect = '{source} removes enchantment from himself.  (If he is a monster) {source} attacks and dies with {hand} hand'
  #private_class_method :new
  
  def initialize
    @name = @@name
    @invocation_gestures = @@gestures
    @effect = @@effect  
  end
  
  def StandardLightningBolt.conjure
    #@@me = new unless #@@me
    #@@me
    StandardLightningBolt.new
  end
end #StandardcounterSpell

class CauseLightWounds < Spell
  Gestures = "#{Gesture.Wave}#{Gesture.Finger}#{Gesture.Profer}"
  @@gestures = HandGesture.new(Gestures)       
  #@@me = nil
  @@name = 'CauseLightWounds'
  #@@gestures = "#{Gesture.Wave}#{Gesture.Wave}#{Gesture.Snap}"
  @@effect = '{source} removes enchantment from himself.  (If he is a monster) {source} attacks and dies with {hand} hand'
  #private_class_method :new
  
  def initialize
    @name = @@name
    @invocation_gestures = @@gestures
    @effect = @@effect  
  end
  
  def CauseLightWounds.conjure
    #@@me = new unless #@@me
    #@@me
    CauseLightWounds.new
  end
end #CauseLightWounds


class CauseHeavyWounds < Spell
  Gestures = "#{Gesture.Wave}#{Gesture.Profer}#{Gesture.Finger}#{Gesture.Digit}"
  @@gestures = HandGesture.new(Gestures)   
  #@@me = nil
  @@name = 'CauseHeavyWounds'
  @@effect = 'All magic is cleared. Monsters may attack before dying'
  #private_class_method :new
  
  def initialize
    @name = @@name
    @invocation_gestures = @@gestures
    @effect = @@effect  
  end
  
  def CauseHeavyWounds.conjure
    #@@me = new unless #@@me
    #@@me
    CauseHeavyWounds.new
  end
end #dispelMagic


class Fireball < Spell
  Gestures = "#{Gesture.Finger}#{Gesture.Snap}#{Gesture.Snap}#{Gesture.Digit}#{Gesture.Digit}"
  @@gestures = HandGesture.new(Gestures)   
  #@@me = nil
  @@name = 'Fireball'
  @@effect = 'The dead are raised'
  #private_class_method :new
  
  def initialize
    @name = @@name
    @invocation_gestures = @@gestures
    @effect = @@effect  
  end
  
  def Fireball.conjure
    #@@me = new unless #@@me
    #@@me
    Fireball.new
  end
end #Fireball


class FireStorm < Spell
  Gestures = "#{Gesture.Snap}#{Gesture.Wave}#{Gesture.Wave}#{Gesture.Clap}"
  @@gestures = HandGesture.new(Gestures,/C$/)   
  #@@me = nil
  @@name = 'FireStorm'
  @@effect = 'Light wounds are cured'
  #private_class_method :new
  
  def initialize
    @name = @@name
    @invocation_gestures = @@gestures
    @effect = @@effect  
  end
  
  def FireStorm.conjure
    #@@me = new unless #@@me
    #@@me
    FireStorm.new
  end
end #FireStorm


class IceStorm < Spell
  Gestures = "#{Gesture.Wave}#{Gesture.Snap}#{Gesture.Snap}#{Gesture.Clap}"
  @@gestures = HandGesture.new(Gestures,/C$/)   
  #@@me = nil
  @@name = 'IceStorm'
  @@effect = 'Heavy wounds are cured'
  #private_class_method :new
  
  def initialize
    @name = @@name
    @invocation_gestures = @@gestures
    @effect = @@effect  
  end
  
  def IceStorm.conjure
    #@@me = new unless #@@me
    #@@me
    IceStorm.new
  end
end #IceStorm





if __FILE__ == $0
  
  #ProtectionSpells.write_book
  #ProtectionSpells.spell_book.each {|spell| puts spell}    
  gestures = ["PEWWS","PECD"] 
  testSpell = CauseLightWounds.new #ProtectionSpells::CauseHeavyWounds.conjure
  puts testSpell.invoked?(gestures)
  #puts "invoked" if testSpell.invocation_gestures.invoked_by_right_hand?(gestures)
end