$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'test/unit'
require 'enchantment_spells'
require 'gestures'

class TestEnchantmentSpells < Test::Unit::TestCase
  
  def test_Amnesia
    gestures_left_test  = ["DPP","PECD"]
    gestures_right_test = ["PECD","SDPP"] 
    gestures_both_fail  = ["PECD","WS"] 
    gestures_invoke = [gestures_left_test,
                       gestures_right_test]
    
    spell = Amnesia.conjure
    
    gestures_invoke.each { |g| assert(spell.invoked?(g), "#{g[0]} -- #{g[1]} did not invoke Amnesia") }
    assert(!spell.invoked?(gestures_both_fail) ," #{gestures_both_fail[0]} -- #{gestures_both_fail[1]}  invoked Amnesia")
  end
  
  def test_Confusion
    gestures_left_test  = ["ERPWDSF","PECD"]
    gestures_right_test = ["PECD","ERPWPFSSSDSF"] 
    gestures_both_fail  = ["PECD","WSEPDW"] 
    gestures_invoke = [gestures_left_test,
                       gestures_right_test]
    
    spell = Confusion.conjure
    
    gestures_invoke.each { |g| assert(spell.invoked?(g), "#{g[0]} -- #{g[1]} did not invoke Confusion") }
    assert(!spell.invoked?(gestures_both_fail) ," #{gestures_both_fail[0]} -- #{gestures_both_fail[1]}  invoked Confusion")      
  end
  
  def test_CharmPerson
    gestures_left_test  = ["CWDFPSDF","CW"]
    gestures_right_test = ["PECDCW","CWDFFPSDF"]
    gestures_both_fail  = ["PECW","WSC"] 
    gestures_invoke = [gestures_left_test,
                       gestures_right_test]
    
    spell = CharmPerson.conjure
    
    gestures_invoke.each { |g| assert(spell.invoked?(g), "#{g[0]} -- #{g[1]} did not invoke CharmPerson") }
    assert(!spell.invoked?(gestures_both_fail) ," #{gestures_both_fail[0]} -- #{gestures_both_fail[1]}  invoked CharmPerson")
      
  end

  def test_CharmMonster
    gestures_left_test  = ["CWDFWPSDD","CWC"]
    gestures_right_test = ["PECDC","CWDDCPSDD"]
    gestures_both_fail  = ["PECW","WSC"] 
    gestures_invoke = [gestures_left_test,
                       gestures_right_test]
    
    spell = CharmMonster.conjure
    
    gestures_invoke.each { |g| assert(spell.invoked?(g), "#{g[0]} -- #{g[1]} did not invoke CharmMonster") }
    assert(!spell.invoked?(gestures_both_fail) ," #{gestures_both_fail[0]} -- #{gestures_both_fail[1]}  invoked CharmMonster")
      
  end

  def test_Paralysis
    gestures_left_test  = ["CWFPSWFFF","CW"]
    gestures_right_test = ["PECDCW","WPCWFPSWFFF"]
    gestures_both_fail  = ["PECW","WSC"] 
    gestures_invoke = [gestures_left_test,
                       gestures_right_test]
    
    spell = Paralysis.conjure
    
    gestures_invoke.each { |g| assert(spell.invoked?(g), "#{g[0]} -- #{g[1]} did not invoke Paralysis") }
    assert(!spell.invoked?(gestures_both_fail) ," #{gestures_both_fail[0]} -- #{gestures_both_fail[1]}  invoked Paralysis")      
  end
  
  def test_Fear
    gestures_left_test  = ["DWCSWD","PECDCDEFE"]
    gestures_right_test = ["PECDCDE","PEWWSDCSWD"] 
    gestures_both_fail  = ["PECD","WS"] 
    gestures_invoke = [gestures_left_test,
                       gestures_right_test]
    
    spell = Fear.conjure
    
    gestures_invoke.each { |g| assert(spell.invoked?(g), "#{g[0]} -- #{g[1]} did not invoke Fear") }
    assert(!spell.invoked?(gestures_both_fail) ," #{gestures_both_fail[0]} -- #{gestures_both_fail[1]}  invoked Fear")
  end
  
  def test_AntiSpell
    gestures_left_test  = ["DFCSWPPFSPFP","PECDERF"]
    gestures_right_test = ["PECDERF","DFCSWPPFSSPFP"] 
    gestures_both_fail  = ["PECD","WS"] 
    gestures_invoke = [gestures_left_test,
                       gestures_right_test]
    
    spell = AntiSpell.conjure
    
    gestures_invoke.each { |g| assert(spell.invoked?(g), "#{g[0]} -- #{g[1]} did not invoke AntiSpell") }
    assert(!spell.invoked?(gestures_both_fail) ," #{gestures_both_fail[0]} -- #{gestures_both_fail[1]}  invoked AntiSpell")      
  end

  def test_Protection
    gestures_left_test  = ["ERERCWSWWP","CECDPWDC"]
    gestures_right_test = ["PEC","ERERCWSWWP"] 
    gestures_both_fail  = ["PECD","WS"] 
    gestures_invoke = [gestures_left_test,
                       gestures_right_test]
    
    spell = Protection.conjure
    
    gestures_invoke.each { |g| assert(spell.invoked?(g), "#{g[0]} -- #{g[1]} did not invoke Protection") }
    assert(!spell.invoked?(gestures_both_fail) ," #{gestures_both_fail[0]} -- #{gestures_both_fail[1]}  invoked Protection")      
  end

  def test_ResistHeat
    gestures_left_test  = ["ERERCWWFP","CECDPWDC"]
    gestures_right_test = ["PECDWEDC","ERERCWWFP"] 
    gestures_both_fail  = ["PECD","WS"] 
    gestures_invoke = [gestures_left_test,
                       gestures_right_test]
    
    spell = ResistHeat.conjure
    
    gestures_invoke.each { |g| assert(spell.invoked?(g), "#{g[0]} -- #{g[1]} did not invoke ResistHeat") }
    assert(!spell.invoked?(gestures_both_fail) ," #{gestures_both_fail[0]} -- #{gestures_both_fail[1]}  invoked ResistHeat")      
  end

  def test_ResistCold
    gestures_left_test  = ["SFSSFP","PECD"]
    gestures_right_test = ["PECD","SFWSSFP"] 
    gestures_both_fail  = ["PECD","WS"] 
    gestures_invoke = [gestures_left_test,
                       gestures_right_test]
    
    spell = ResistCold.conjure
    
    gestures_invoke.each { |g| assert(spell.invoked?(g), "#{g[0]} -- #{g[1]} did not invoke ResistCold") }
    assert(!spell.invoked?(gestures_both_fail) ," #{gestures_both_fail[0]} -- #{gestures_both_fail[1]}  invoked ResistCold")
  end
  
  def test_Disease
    gestures_left_test  = ["ERPDSFFFC","PECDC"]
    gestures_right_test = ["PEC","WPDWPDSFFFC"] 
    gestures_both_fail  = ["PECD","WSEPDSFFC"] 
    gestures_invoke = [gestures_left_test,
                       gestures_right_test]
    
    spell = Disease.conjure
    
    gestures_invoke.each { |g| assert(spell.invoked?(g), "#{g[0]} -- #{g[1]} did not invoke Disease") }
    assert(!spell.invoked?(gestures_both_fail) ," #{gestures_both_fail[0]} -- #{gestures_both_fail[1]}  invoked Disease")      
  end
  
  def test_Poison
    gestures_left_test  = ["CWFPSFDWWFWD","CW"]
    gestures_right_test = ["PECDCW","WPCWFPSDWWFWD"]
    gestures_both_fail  = ["PECW","WSC"] 
    gestures_invoke = [gestures_left_test,
                       gestures_right_test]
    
    spell = Poison.conjure
    
    gestures_invoke.each { |g| assert(spell.invoked?(g), "#{g[0]} -- #{g[1]} did not invoke Poison") }
    assert(!spell.invoked?(gestures_both_fail) ," #{gestures_both_fail[0]} -- #{gestures_both_fail[1]}  invoked Poison")
      
  end
  
  def test_Blindness
    gestures_left_test  = ["CWFPSDWFFD","CWD"]
    gestures_right_test = ["PECDWFFD","WPCWFPSFD"]
    gestures_both_fail  = ["PECWDWFFD","WSC"] 
    gestures_invoke = [gestures_left_test,
                       gestures_right_test]
    
    spell = Blindness.conjure
    
    gestures_invoke.each { |g| assert(spell.invoked?(g), "#{g[0]} -- #{g[1]} did not invoke Blindness") }
    assert(!spell.invoked?(gestures_both_fail) ," #{gestures_both_fail[0]} -- #{gestures_both_fail[1]}  invoked Blindness")      
  end
  
  def test_Invisibility
    gestures_left_test  = ["DWCSPPWS","PECDCDEWS"]
    gestures_right_test = ["PECDCWS","PEWWSDCSWPPWS"] 
    gestures_both_fail  = ["PECDPPWS","ES"] 
    gestures_invoke = [gestures_left_test,
                       gestures_right_test]
    
    spell = Invisibility.conjure
    
    gestures_invoke.each { |g| assert(spell.invoked?(g), "#{g[0]} -- #{g[1]} did not invoke Invisibility") }
    assert(!spell.invoked?(gestures_both_fail) ," #{gestures_both_fail[0]} -- #{gestures_both_fail[1]}  invoked Invisibility")
  end
  
  def test_Haste
    gestures_left_test  = ["DFCPWPWWC","PECDERFC"]
    gestures_right_test = ["PECDERFC","DFCSPWPWWC"] 
    gestures_both_fail  = ["PWPWWC","WS"] 
    gestures_invoke = [gestures_left_test,
                       gestures_right_test]
    
    spell = Haste.conjure
    
    gestures_invoke.each { |g| assert(spell.invoked?(g), "#{g[0]} -- #{g[1]} did not invoke Haste") }
    assert(!spell.invoked?(gestures_both_fail) ," #{gestures_both_fail[0]} -- #{gestures_both_fail[1]}  invoked Haste")      
  end

  def test_TimeStop
    gestures_left_test  = ["ERERCWSPPC","CECDPWC"]
    gestures_right_test = ["PEC","ERERCWSPPC"] 
    gestures_both_fail  = ["PECSPPC","WS"] 
    gestures_invoke = [gestures_left_test,
                       gestures_right_test]
    
    spell = TimeStop.conjure
    
    gestures_invoke.each { |g| assert(spell.invoked?(g), "#{g[0]} -- #{g[1]} did not invoke TimeStop") }
    assert(!spell.invoked?(gestures_both_fail) ," #{gestures_both_fail[0]} -- #{gestures_both_fail[1]}  invoked TimeStop")      
  end

  def test_StandardTimeStop
    gestures_left_test  = ["ERERCWSPPFD","CECDPWD"]
    gestures_right_test = ["PECDWED","ERERCWSPPFD"] 
    gestures_both_fail  = ["PECD","WS"] 
    gestures_invoke = [gestures_left_test,
                       gestures_right_test]
    
    spell = StandardTimeStop.conjure
    
    gestures_invoke.each { |g| assert(spell.invoked?(g), "#{g[0]} -- #{g[1]} did not invoke StandardTimeStop") }
    assert(!spell.invoked?(gestures_both_fail) ," #{gestures_both_fail[0]} -- #{gestures_both_fail[1]}  invoked StandardTimeStop")      
  end

  def test_DelayEffect
    gestures_left_test  = ["SDWSSSP","PECD"]
    gestures_right_test = ["PECD","SDWSSSP"] 
    gestures_both_fail  = ["PECD","WS"] 
    gestures_invoke = [gestures_left_test,
                       gestures_right_test]
    
    spell = DelayEffect.conjure
    
    gestures_invoke.each { |g| assert(spell.invoked?(g), "#{g[0]} -- #{g[1]} did not invoke DelayEffect") }
    assert(!spell.invoked?(gestures_both_fail) ," #{gestures_both_fail[0]} -- #{gestures_both_fail[1]}  invoked DelayEffect")
  end
  
  def test_Permanency
    gestures_left_test  = ["ERPWSPFPSDW","PECD"]
    gestures_right_test = ["PECD","ERPWSPFPSDW"] 
    gestures_both_fail  = ["PECD","WSEPDW"] 
    gestures_invoke = [gestures_left_test,
                       gestures_right_test]
    
    spell = Permanency.conjure
    
    gestures_invoke.each { |g| assert(spell.invoked?(g), "#{g[0]} -- #{g[1]} did not invoke Permanency") }
    assert(!spell.invoked?(gestures_both_fail) ," #{gestures_both_fail[0]} -- #{gestures_both_fail[1]}  invoked Permanency")      
  end
  
end