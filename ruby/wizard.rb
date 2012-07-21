require 'character'
require 'spells/gestures'

class Wizard < Character
  attr_reader :enchantment_state,#Any enchantments that the wizard currently has
              :gesture_history,         #Two dimensional array, rtHand, ltHand of gestures
              :left_target,         #Target for a spell generated on the left hand
              :right_target

  attr_writer :enchantment_state, :invoked_spells
  LIFE = 15

  def initialize(name)
    @name = name
    @gesture_history = []
    @gesture_history[$RightHand] = "" 
    @gesture_history[$LeftHand] = ""
                        #$RightHand => "",
                        #$LeftHand => ""
                        #}
    @life = LIFE           
    @invoked_spells = []
    @minions = []
  end
 
  def to_s
    @name
  end

  def invoked_spells=(invokedList)
    @invoked_spells = invokedList
    puts @invoked_spells.length
    @invoked_spells.each do |spellList|
      puts "spell list length = #{spellList.length}"
      puts "...invoking more than one spell" if spellList.length > 1
    end
  end

  def gesture_left(gesture, target=nil)
    @gesture_history[$LeftHand] << (gesture.upcase)
    @left_target = target
  end
  
  def gesture_right(gesture, target=nil)
    @gesture_history[$RightHand] << (gesture.upcase)
    @right_target = target
  end

  def right_hand_gestures
    @gesture_history[$RightHand]
  end

  def left_hand_gestures
    @gesture_history[$LeftHand]
  end

  def invoked_left_hand_spells
    @invoked_spells[$LeftHand]
  end

  def invoked_right_hand_spells
    @invoked_spells[$RightHand]
  end

end


if __FILE__ == $0
  
  rhazes = Wizard.new("Rhazes")
  phazes = Wizard.new("Phazes")
  rhazes.opponent = phazes
  rhazes.conjure_spell(Shield::Name)
  rhazes.conjure_spell(DispelMagic::Name)
  phazes.conjure_spell(SummonGiant::Name)
  rhazes.invoke_spells
  #puts "#{rhazes.invoked_spells.length} invoked spells"
  #puts "#{phazes.invoked_spells.length} invoked spells"
  
  
end