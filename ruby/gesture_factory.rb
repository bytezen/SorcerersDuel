module GestureFactory

  def get_gestures
    gestures = []
    gestures << next_left_gesture
    gestures << next_right_gesture
  end
end


class CommandLineGestureFactory
  include GestureFactory

  def next_gesture
    puts "Enter your gesture and press return\n\t:"
    gets.chomp.upcase
  end
  
  def next_left_gesture
    print "For left hand --"
    next_gesture
  end

  def next_right_gesture
    print "For right hand --"
    next_gesture
  end

end

class FileGestureFactory
  
  def next_gesture
  end      
end