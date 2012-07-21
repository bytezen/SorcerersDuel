  class Gesture
    @@profer = 'P'
    @@snap   = 'S'
    @@wave   = 'W'
    @@digit  = 'D'
    @@finger = 'F'
    @@clap   = 'C'
    @@stab   = 'B'
     
    def self.Profer
      @@profer  
    end

    def self.Snap
      @@snap  
    end

    def self.Wave
      @@wave  
    end

    def self.Digit
      @@digit  
    end

    def self.Finger
      @@finger  
    end

    def self.Clap
      @@clap
    end

    def self.Stab
      @@stab  
    end

    def self.None
      nil  
    end
end

class HandGesture
  attr_reader :right_hand, :left_hand, :both_hands
  LeftHand=0 
  RightHand = 1
  
  def initialize(right_left_gestures, both_hands_gestures = nil)
    @right_hand = Regexp.new("#{right_left_gestures}$")    
    @left_hand = @right_hand
    #@both_hands = both_hands_gestures == nil ? nil : Regexp.new("#{both_hands_gestures}$")
    @both_hands ||= both_hands_gestures
  end 

  def to_s
    "right_hand = #@right_hand; left_hand = #@left_hand; both_hands = #@both_hands"  
  end

  def both_hands_gesture?(gestures)
    return true unless @both_hands != nil
    return false if gestures.length < 2
    gestures[0] =~ @both_hands && gestures[1] =~ @both_hands
  end

  def invoked_by_right_hand?(gestures)
    gestures[RightHand] =~ @right_hand &&
    both_hands_gesture?(gestures)
    #right_hand_gesture?(gestures) && left_hand_gesture?(gestures) && both_hands_gesture?(gestures)
  end
 
  def invoked_by_left_hand?(gestures)
    gestures[LeftHand] =~ @left_hand &&
    both_hands_gesture?(gestures)
  end
end

if __FILE__ == $0
  hg = HandGesture.new("C")
  gestures = "#{Gesture.Clap}#{Gesture.Digit}#{Gesture.Profer}#{Gesture.Digit}#{Gesture.Clap}"
  puts hg.invoked?(gestures)
  puts gestures
  #puts "rtHand? = #{hg.right_hand_gesture?(gestures)}"
  #puts "ltHand? = #{hg.left_hand_gesture?(gestures)}"
  #puts "bothHands? = #{hg.both_hands_gesture?(gestures)}"
end

