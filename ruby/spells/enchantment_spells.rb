require File.dirname(__FILE__) + '/spell'
require File.dirname(__FILE__) + '/gestures'

class Amnesia < Spell  
  Gestures = "#{Gesture.Digit}#{Gesture.Profer}#{Gesture.Profer}"
  @@gestures = HandGesture.new(Gestures)
  #@@me = nil
  @@name = 'Amnesia'
  @@effect = '{source} shields {target} with {hand} hand'
  
  #private_class_method :new
  
  def initialize
    @name = @@name
    @invocation_gestures = @@gestures
    @effect = @@effect
  end
  
  def Amnesia.conjure
    #@@me = new unless @@me
    #@@me
    Amnesia.new
  end
 
end #Amnesia

class Confusion < Spell
  Gestures = "#{Gesture.Digit}#{Gesture.Snap}#{Gesture.Finger}"
  @@gestures = HandGesture.new(Gestures)
  
  #@@me = nil
  @@name = 'Confusion'
  #@@gestures = [Gesture.Profer, Gesture.Digit, Gesture.Wave, Gesture.Profer]
  @@effect = '{source} removes enchantment from himself.  (If he is a monster) {source} attacks and dies with {hand} hand'
  #private_class_method :new
  
  def initialize
    @name = @@name
    @invocation_gestures = @@gestures
    @effect = @@effect  
  end
  
  def Confusion.conjure
    #@@me = new unless @@me
    #@@me
    Confusion.new
  end
end #Confusion

class CharmPerson < Spell
  Gestures = "#{Gesture.Profer}#{Gesture.Snap}#{Gesture.Digit}#{Gesture.Finger}"
  @@gestures = HandGesture.new(Gestures)    
  #@@me = nil
  @@name = 'CharmPerson'
  @@effect = '{source} reflects all spells'
  #private_class_method :new
  
  def initialize
    @name = @@name
    @invocation_gestures = @@gestures
    @effect = @@effect  
  end
  
  def CharmPerson.conjure
    #@@me = new unless @@me
    ##@@me
    CharmPerson.new
  end
end #CharmPerson

class CharmMonster < Spell
  Gestures = "#{Gesture.Profer}#{Gesture.Snap}#{Gesture.Digit}#{Gesture.Digit}"
  @@gestures = HandGesture.new(Gestures)       
  #@@me = nil
  @@name = 'CharmMonster'
  @@effect = '{source} removes enchantment from himself.  (If he is a monster) {source} attacks and dies with {hand} hand'
  #private_class_method :new
  
  def initialize
    @name = @@name
    @invocation_gestures = @@gestures
    @effect = @@effect  
  end
  
  def CharmMonster.conjure
    #@@me = new unless #@@me
    #@@me
    CharmMonster.new
  end
end #StandardcounterSpell

class Paralysis < Spell
  Gestures = "#{Gesture.Finger}#{Gesture.Finger}#{Gesture.Finger}"
  @@gestures = HandGesture.new(Gestures)       
  #@@me = nil
  @@name = 'Paralysis'
  #@@gestures = "#{Gesture.Wave}#{Gesture.Wave}#{Gesture.Snap}"
  @@effect = '{source} removes enchantment from himself.  (If he is a monster) {source} attacks and dies with {hand} hand'
  #private_class_method :new
  
  def initialize
    @name = @@name
    @invocation_gestures = @@gestures
    @effect = @@effect  
  end
  
  def Paralysis.conjure
    #@@me = new unless #@@me
    #@@me
    Paralysis.new
  end
end #Paralysis


class Fear < Spell
  Gestures = "#{Gesture.Snap}#{Gesture.Wave}#{Gesture.Digit}"
  @@gestures = HandGesture.new(Gestures)   
  #@@me = nil
  @@name = 'Fear'
  @@effect = 'All magic is cleared. Monsters may attack before dying'
  #private_class_method :new
  
  def initialize
    @name = @@name
    @invocation_gestures = @@gestures
    @effect = @@effect  
  end
  
  def Fear.conjure
    #@@me = new unless #@@me
    #@@me
    Fear.new
  end
end #Fear


class AntiSpell < Spell
  Gestures = "#{Gesture.Snap}#{Gesture.Profer}#{Gesture.Finger}#{Gesture.Profer}"
  @@gestures = HandGesture.new(Gestures)   
  #@@me = nil
  @@name = 'AntiSpell'
  @@effect = 'The dead are raised'
  #private_class_method :new
  
  def initialize
    @name = @@name
    @invocation_gestures = @@gestures
    @effect = @@effect  
  end
  
  def AntiSpell.conjure
    #@@me = new unless #@@me
    #@@me
    AntiSpell.new
  end
end #AntiSpell


class Protection < Spell
  Gestures = "#{Gesture.Wave}#{Gesture.Wave}#{Gesture.Profer}"
  @@gestures = HandGesture.new(Gestures)   
  #@@me = nil
  @@name = 'Protection'
  @@effect = 'Light wounds are cured'
  #private_class_method :new
  
  def initialize
    @name = @@name
    @invocation_gestures = @@gestures
    @effect = @@effect  
  end
  
  def Protection.conjure
    #@@me = new unless #@@me
    #@@me
    Protection.new
  end
end #Protection


class ResistHeat < Spell
  Gestures = "#{Gesture.Wave}#{Gesture.Wave}#{Gesture.Finger}#{Gesture.Profer}"
  @@gestures = HandGesture.new(Gestures)   
  #@@me = nil
  @@name = 'ResistHeat'
  @@effect = 'Heavy wounds are cured'
  #private_class_method :new
  
  def initialize
    @name = @@name
    @invocation_gestures = @@gestures
    @effect = @@effect  
  end
  
  def ResistHeat.conjure
    #@@me = new unless #@@me
    #@@me
    ResistHeat.new
  end
end #ResistHeat

class ResistCold < Spell  
  Gestures = "#{Gesture.Snap}#{Gesture.Snap}#{Gesture.Finger}#{Gesture.Profer}"
  @@gestures = HandGesture.new(Gestures)
  #@@me = nil
  @@name = 'ResistCold'
  @@effect = '{source} shields {target} with {hand} hand'
  
  #private_class_method :new
  
  def initialize
    @name = @@name
    @invocation_gestures = @@gestures
    @effect = @@effect
  end
  
  def ResistCold.conjure
    #@@me = new unless @@me
    #@@me
    ResistCold.new
  end
 
end #ResistCold

class Disease < Spell
  Gestures = "#{Gesture.Digit}#{Gesture.Snap}#{Gesture.Finger}#{Gesture.Finger}#{Gesture.Finger}#{Gesture.Clap}"
  @@gestures = HandGesture.new(Gestures,/C$/)
  
  #@@me = nil
  @@name = 'Disease'
  #@@gestures = [Gesture.Profer, Gesture.Digit, Gesture.Wave, Gesture.Profer]
  @@effect = '{source} removes enchantment from himself.  (If he is a monster) {source} attacks and dies with {hand} hand'
  #private_class_method :new
  
  def initialize
    @name = @@name
    @invocation_gestures = @@gestures
    @effect = @@effect  
  end
  
  def Disease.conjure
    #@@me = new unless @@me
    #@@me
    Disease.new
  end
end #Disease

class Poison < Spell
  Gestures = "#{Gesture.Digit}#{Gesture.Wave}#{Gesture.Wave}#{Gesture.Finger}#{Gesture.Wave}#{Gesture.Digit}"
  @@gestures = HandGesture.new(Gestures)    
  #@@me = nil
  @@name = 'Poison'
  @@effect = '{source} reflects all spells'
  #private_class_method :new
  
  def initialize
    @name = @@name
    @invocation_gestures = @@gestures
    @effect = @@effect  
  end
  
  def Poison.conjure
    #@@me = new unless @@me
    ##@@me
    Poison.new
  end
end #Poison

class Blindness < Spell
  Gestures = "#{Gesture.Digit}#{Gesture.Wave}#{Gesture.Finger}#{Gesture.Finger}#{Gesture.Digit}"
  @@gestures = HandGesture.new(Gestures,/#{Gesture.Digit}$/)       
  #@@me = nil
  @@name = 'Blindness'

  @@effect = '{source} removes enchantment from himself.  (If he is a monster) {source} attacks and dies with {hand} hand'
  #private_class_method :new
  
  def initialize
    @name = @@name
    @invocation_gestures = @@gestures
    @effect = @@effect  
  end
  
  def Blindness.conjure
    #@@me = new unless #@@me
    #@@me
    Blindness.new
  end
end #StandardcounterSpell

class Invisibility < Spell
  Gestures = "#{Gesture.Profer}#{Gesture.Profer}#{Gesture.Wave}#{Gesture.Snap}"
  @@gestures = HandGesture.new(Gestures,/#{Gesture.Wave}#{Gesture.Snap}$/)       
  #@@me = nil
  @@name = 'Invisibility'
  #@@gestures = "#{Gesture.Wave}#{Gesture.Wave}#{Gesture.Snap}"
  @@effect = '{source} removes enchantment from himself.  (If he is a monster) {source} attacks and dies with {hand} hand'
  #private_class_method :new
  
  def initialize
    @name = @@name
    @invocation_gestures = @@gestures
    @effect = @@effect  
  end
  
  def Invisibility.conjure
    #@@me = new unless #@@me
    #@@me
    Invisibility.new
  end
end #Invisibility


class Haste < Spell
  Gestures = "#{Gesture.Profer}#{Gesture.Wave}#{Gesture.Profer}#{Gesture.Wave}#{Gesture.Wave}#{Gesture.Clap}"
  @@gestures = HandGesture.new(Gestures,/#{Gesture.Clap}$/)   
  #@@me = nil
  @@name = 'Haste'
  @@effect = 'All magic is cleared. Monsters may attack before dying'
  #private_class_method :new
  
  def initialize
    @name = @@name
    @invocation_gestures = @@gestures
    @effect = @@effect  
  end
  
  def Haste.conjure
    #@@me = new unless #@@me
    #@@me
    Haste.new
  end
end #dispelMagic


class StandardTimeStop < Spell
  Gestures = "#{Gesture.Snap}#{Gesture.Profer}#{Gesture.Profer}#{Gesture.Finger}#{Gesture.Digit}"
  @@gestures = HandGesture.new(Gestures)   
  #@@me = nil
  @@name = 'TimeStop'
  @@effect = 'The dead are raised'
  #private_class_method :new
  
  def initialize
    @name = @@name
    @invocation_gestures = @@gestures
    @effect = @@effect  
  end
  
  def StandardTimeStop.conjure
    #@@me = new unless #@@me
    #@@me
    StandardTimeStop.new
  end
end #TimeStop


class TimeStop < Spell
  Gestures = "#{Gesture.Snap}#{Gesture.Profer}#{Gesture.Profer}#{Gesture.Clap}"
  @@gestures = HandGesture.new(Gestures,/#{Gesture.Clap}$/)   
  #@@me = nil
  @@name = 'TimeStop'
  @@effect = 'The dead are raised'
  #private_class_method :new
  
  def initialize
    @name = @@name
    @invocation_gestures = @@gestures
    @effect = @@effect  
  end
  
  def TimeStop.conjure
    #@@me = new unless #@@me
    #@@me
    TimeStop.new
  end
end #TimeStop


class DelayEffect < Spell
  Gestures = "#{Gesture.Digit}#{Gesture.Wave}#{Gesture.Snap}#{Gesture.Snap}#{Gesture.Snap}#{Gesture.Profer}"
  @@gestures = HandGesture.new(Gestures)   
  #@@me = nil
  @@name = 'DelayEffect'
  @@effect = 'Light wounds are cured'
  #private_class_method :new
  
  def initialize
    @name = @@name
    @invocation_gestures = @@gestures
    @effect = @@effect  
  end
  
  def DelayEffect.conjure
    #@@me = new unless #@@me
    #@@me
    DelayEffect.new
  end
end #DelayEffect


class Permanency < Spell
  Gestures = "#{Gesture.Snap}#{Gesture.Profer}#{Gesture.Finger}#{Gesture.Profer}#{Gesture.Snap}#{Gesture.Digit}#{Gesture.Wave}"
  @@gestures = HandGesture.new(Gestures)   
  #@@me = nil
  @@name = 'Permanency'
  @@effect = 'Heavy wounds are cured'
  #private_class_method :new
  
  def initialize
    @name = @@name
    @invocation_gestures = @@gestures
    @effect = @@effect  
  end
  
  def Permanency.conjure
    #@@me = new unless #@@me
    #@@me
    Permanency.new
  end
end #Permanency




if __FILE__ == $0

end
