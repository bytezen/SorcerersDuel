class Spell
  attr_reader :name,     #spell name in lowerCase format
              :invocation_gestures, #List of gestures to invoke spell
              :subject,  #The author of the spell
              :target,   #The target of the spell
              :effect,
              :type,
              :damage,    #Returns the Magical State
              :power,     #The rank order of the spell, lower is more powerful
              :countered    #flag to determine if spell is blocked
  attr_writer :subject,:target, :countered
  @@blocked_spells = []

  def initialize(name, gestures, effect)
    @name = name
    @invocation_gestures = gestures
    @effect = effect
    @state_manager = SpellStateManager.new(@effect)
    countered = false

  end
#  def initialize(state_manager)
#    @state_manager = state_manager
#  end
  
  def cast(subject,target=nil)
    if(countered) 
      puts "--#{self} is countered"
      return
    end  
    self.effect
  end

  def type
    "Spell"
  end

  def to_s
    #gest = @gestures.to_s.split(//).collect {|g| g == Gesture.Clap ? g.downcase : g}
    @name #+ " -- invocation: #{gest}"
  end

  # THIS IS A TEMPORARY IMPLEMENTATION...WE DO NOT NEED THE MSGs JUST THE BOOL
  def invoked?(gestures)
    gestures.each { |g| g.upcase!}      
    s=""  
    s += "#@name invoked by right hand; " if @invocation_gestures.invoked_by_right_hand?(gestures)  
    s += "#@name invoked by left hand "  if @invocation_gestures.invoked_by_left_hand?(gestures)
    s != ""
    #invoke_gestures.invoked?(gestures)
    #gestures.each do |gest| 
    #  next false if gest.length < @gestures.to_s.length
    #  return true if @gestures.to_s =~ /#{gest.slice(-@gestures.length..-1)}/
    #end      
    #false
  end

  def invoked_by_right_hand?(gestures)
    @invocation_gestures.invoked_by_right_hand?(gestures)
  end

  def invoked_by_left_hand?(gestures)
    @invocation_gestures.invoked_by_left_hand?(gestures)
  end
  
  def invoke(conjurer=nil,target=nil)
    sub = conjurer || self.subject
    tar = target || self.target
    @state_manager.invoke(sub,tar)  
  end

  def ==(spell)
    self.name == spell.name && spell.kind_of?(Spell)
  end

  def test_effect_processing
    puts @@blocked_spells
  end
end
