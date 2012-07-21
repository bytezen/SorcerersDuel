class SpellStateManager
  attr_reader :touched, :blocked, :expired
  attr_writer :touched, :blocked, :expired

  def initialize(effect)
    @effect = effect
  end

  def invoke(conjurer,target=nil)
    @effect.call(conjurer,target)
  end

  def reset
    touched(false)
    blocked(false)
    expired(false)    
  end
end
