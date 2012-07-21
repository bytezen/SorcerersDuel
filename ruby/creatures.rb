require 'monster'

class Goblin < Character
  Life = 1
  Damage = 1
  attr_reader :target, :master
  attr_writer :target, :master
  include Monster

  def initialize(master,target)
    @master = master
    @target = target
  end
end


class Ogre < Character
  LIFE = 2
  DAMAGE = 2
  include Monster 
  attr_reader :target, :master
  attr_writer :target, :master

  def initialize(master,target)
    @master = master
    @target = target
  end
end

class Troll < Character
  include Monster  
  LIFE = 3
  DAMAGE = 3
  attr_reader :target, :master
  attr_writer :target, :master

  def initialize(master,target)
    @master = master
    @target = target
  end  
end


class Giant < Character
  include Monster  
  LIFE = 4
  DAMAGE = 4    
  attr_reader :target, :master
  attr_writer :target, :master

  def initialize(master,target)
    @master = master
    @target = target
  end
end