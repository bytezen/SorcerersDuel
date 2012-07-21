require File.dirname(__FILE__) + '/gestures'

class Stab 
  Gestures = "#{Gesture.Stab}"
  @@gestures = HandGesture.new(Gestures)
  #@@me = nil
  Name = 'Stab'
  @@blocked_spells
  @@effect = Proc.new do |subject,target| 
      puts " #{subject}  #{target}!"
  end
  
  #private_class_method :new
  
  def initialize
    @name = Name
    @invocation_gestures = @@gestures
    @effect = @@effect
    @state_manager = SpellStateManager.new(@@effect)
  end
  
  def Shield.conjure
    #@@me = new unless @@me
    #@@me
    Shield.new
  end
 
end #Shield