$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'test/unit'
require 'summoning_spells'
require 'gestures'

class TestSpells < Test::Unit::TestCase
  
  def test_SummonGoblin
    gestures_left_test  = ["SFW","PECD"]
    gestures_right_test = ["PECD","SFW"] 
    gestures_both_test  = ["PECSFW","SFW"] 
    gestures_both_fail  = ["PECD","WS"] 
    gestures_invoke = [gestures_left_test,
                       gestures_right_test,
                       gestures_both_test]
    
    spell = SummonGoblin.conjure
    
    gestures_invoke.each { |g| assert(spell.invoked?(g), "#{g[0]} -- #{g[1]} did not invoke SummonGoblin") }
    assert(!spell.invoked?(gestures_both_fail) ," #{gestures_both_fail[0]} -- #{gestures_both_fail[1]}  invoked SummonGoblin")
  end
  
  def test_SummonOgre
    gestures_left_test  = ["ERPDWPSFW","PECD"]
    gestures_right_test = ["PECD","WPDWPSFW"] 
    gestures_both_test  = ["PECDPDWPSFW","EPDWPSFW"] 
    gestures_both_fail  = ["PECD","WSEPDW"] 
    gestures_invoke = [gestures_left_test,
                       gestures_right_test,
                       gestures_both_test]
    
    spell = SummonOgre.conjure
    
    gestures_invoke.each { |g| assert(spell.invoked?(g), "#{g[0]} -- #{g[1]} did not invoke SummonOgre") }
    assert(!spell.invoked?(gestures_both_fail) ," #{gestures_both_fail[0]} -- #{gestures_both_fail[1]}  invoked SummonOgre")      
  end
  
  def test_SummonTroll
    gestures_left_test  = ["CWFPSFW","CW"]
    gestures_right_test = ["PECDCW","WPCWFPSFW"]
    gestures_both_test  = ["PECDPDWFPSFW","EPDWFPSFW"]     
    gestures_both_fail  = ["PECW","WSC"] 
    gestures_invoke = [gestures_left_test,
                       gestures_right_test,
                       gestures_both_test]
    
    spell = SummonTroll.conjure
    
    gestures_invoke.each { |g| assert(spell.invoked?(g), "#{g[0]} -- #{g[1]} did not invoke SummonTroll") }
    assert(!spell.invoked?(gestures_both_fail) ," #{gestures_both_fail[0]} -- #{gestures_both_fail[1]}  invoked SummonTroll")
      
  end
  
  def test_SummonGiant
    gestures_left_test  = ["CWFPSFW","CW"]
    gestures_right_test = ["PECDCW","WPCWFPSFW"]
    gestures_both_test  = ["PECDPDWFPSFW","EPDWFPSFW"]     
    gestures_both_fail  = ["PECW","WSC"] 
    gestures_invoke = [gestures_left_test,
                       gestures_right_test,
                       gestures_both_test]
    
    spell = SummonGiant.conjure
    
    gestures_invoke.each { |g| assert(spell.invoked?(g), "#{g[0]} -- #{g[1]} did not invoke SummonGiant") }
    assert(!spell.invoked?(gestures_both_fail) ," #{gestures_both_fail[0]} -- #{gestures_both_fail[1]}  invoked SummonGiant")      
  end
  
  def test_SummonIceElemental
    gestures_left_test  = ["DWCSWWS","PECDCDEFE"]
    gestures_right_test = ["PECDCDE","PEWWSDCSWWS"] 
    gestures_both_fail  = ["PECD","WS"] 
    gestures_invoke = [gestures_left_test,
                       gestures_right_test]
    
    spell = SummonIceElemental.conjure
    
    gestures_invoke.each { |g| assert(spell.invoked?(g), "#{g[0]} -- #{g[1]} did not invoke SummonIceElemental") }
    assert(!spell.invoked?(gestures_both_fail) ," #{gestures_both_fail[0]} -- #{gestures_both_fail[1]}  invoked SummonIceElemental")
  end
  
  def test_ClassicSummonFireElemental
    gestures_left_test  = ["DFCSWPP","PECDERF"]
    gestures_right_test = ["PECDERF","DFCSWPP"] 
    gestures_both_fail  = ["PECD","WS"] 
    gestures_invoke = [gestures_left_test,
                       gestures_right_test]
    
    spell = ClassicSummonFireElemental.conjure
    
    gestures_invoke.each { |g| assert(spell.invoked?(g), "#{g[0]} -- #{g[1]} did not invoke ClassicSummonFireElemental") }
    assert(!spell.invoked?(gestures_both_fail) ," #{gestures_both_fail[0]} -- #{gestures_both_fail[1]}  invoked ClassicSummonFireElemental")      
  end

  def test_StandardSummonFireElemental
    gestures_left_test  = ["ERERCWSSW","CECDPWD"]
    gestures_right_test = ["PECDWED","ERERCWSSW"] 
    gestures_both_fail  = ["PECD","WS"] 
    gestures_invoke = [gestures_left_test,
                       gestures_right_test]
    
    spell = StandardSummonFireElemental.conjure
    
    gestures_invoke.each { |g| assert(spell.invoked?(g), "#{g[0]} -- #{g[1]} did not invoke StandardSummonFireElemental") }
    assert(!spell.invoked?(gestures_both_fail) ," #{gestures_both_fail[0]} -- #{gestures_both_fail[1]}  invoked StandardSummonFireElemental")      
  end

end