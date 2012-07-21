require File.dirname(__FILE__) + '/spell'
require File.dirname(__FILE__) + '/gestures'


class SummonGoblin < Spell  
  Gestures = "#{Gesture.Snap}#{Gesture.Finger}#{Gesture.Wave}"
  @@gestures = HandGesture.new(Gestures)
  
  Name = 'SummonGoblin'
  @@effect = Proc.new {|subject,target| puts "#{subject}'s goblin attacks #{target}"}

  def initialize(name,gestures,effect)
    super(name,gestures,effect)
  end

  def SummonGoblin.conjure
    #@@me = new unless @@me
    #@@me
    SummonGoblin.new(Name,@@gestures,@@effect)
  end
 
end #SummonGoblin

class SummonOgre < Spell
  Gestures = "#{Gesture.Profer}#{Gesture.Snap}#{Gesture.Finger}#{Gesture.Wave}"
  @@gestures = HandGesture.new(Gestures)
  
  Name = 'SummonOgre'
  #@@gestures = [Gesture.Profer, Gesture.Digit, Gesture.Wave, Gesture.Profer]
  @@effect = Proc.new {|subject,target| puts  'Ogre attacks'}
  
  def initialize(name,gestures,effect)
    super(name,gestures,effect)
  end  
  def SummonOgre.conjure
    #@@me = new unless @@me
    #@@me
    SummonOgre.new(Name,@@gestures,@@effect)
  end
end #SummonOgre

class SummonTroll < Spell
  Gestures = "#{Gesture.Finger}#{Gesture.Profer}#{Gesture.Snap}#{Gesture.Finger}#{Gesture.Wave}"
  @@gestures = HandGesture.new(Gestures)    
  
  Name = 'SummonTroll'
  @@effect = Proc.new {|subject,target| puts  'Troll attacks'}
  
  def initialize(name,gestures,effect)
    super(name,gestures,effect)
  end
  
  def SummonTroll.conjure
    #@@me = new unless @@me
    #@@me
    SummonTroll.new(Name,@@gestures,@@effect)
  end
end #SummonTroll

class SummonGiant < Spell
  Gestures = "#{Gesture.Finger}#{Gesture.Profer}#{Gesture.Snap}#{Gesture.Finger}#{Gesture.Wave}"
  @@gestures = HandGesture.new(Gestures)       
  
  Name = 'SummonGiant'

  @@effect = Proc.new {|subject,target| subject.minions << Giant.new(subject,target); puts "Eff:: #{subject} summons Giant"}

  def initialize(name,gestures,effect)
    super(name,gestures,effect)
  end
  
  def SummonGiant.conjure
    #@@me = new unless @@me
    #@@me
    SummonGiant.new(Name,@@gestures,@@effect)
  end
end #SummonGiant

class SummonIceElemental < Spell
  Gestures = "#{Gesture.Snap}#{Gesture.Wave}#{Gesture.Wave}#{Gesture.Snap}"
  @@gestures = HandGesture.new(Gestures,/C.{4}$/)       
  
  Name = 'SummonIceElemental'
  @@effect = Proc.new {|subject,target| puts  'Ice elemental attacks'}
  
  def initialize(name,gestures,effect)
    super(name,gestures,effect)
  end  
  def SummonIceElemental.conjure
    #@@me = new unless @@me
    #@@me
    SummonIceElemental.new(Name,@@gestures,@@effect)
  end
end #SummonIceElemental


class StandardSummonFireElemental < Spell
  Gestures = "#{Gesture.Wave}#{Gesture.Snap}#{Gesture.Snap}#{Gesture.Wave}"
  @@gestures = HandGesture.new(Gestures,/C.{4}$/)       
  
  Name = 'StandardSummonFireElemental'
  @@effect = Proc.new {|subject,target| puts  'Fire elemental is summonded'}
  
  def initialize(name,gestures,effect)
    super(name,gestures,effect)
  end
  
  def StandardSummonFireElemental.conjure
    #@@me = new unless @@me
    #@@me
    StandardSummonFireElemental.new(Name,@@gestures,@@effect)
  end
end #StandardSummonFireElemental


class ClassicSummonFireElemental < Spell
  Gestures = "#{Gesture.Snap}#{Gesture.Wave}#{Gesture.Profer}#{Gesture.Profer}"
  @@gestures = HandGesture.new(Gestures,/C.{4}$/)       
  Name = 'ClassicSummonFireElemental'
  @@effect = Proc.new {|subject,target| puts  'fire elemental is invoked'}
  
  def initialize(name,gestures,effect)
    super(name,gestures,effect)
  end
  
  def ClassicSummonFireElemental.conjure
    #@@me = new unless @@me
    #@@me
    ClassicSummonFireElemental.new(Name,@@gestures,@@effect)
  end
end #ClassicSummonFireElemental



if __FILE__ == $0
  

end