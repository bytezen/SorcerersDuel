$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'test/unit'
require 'protection_spells'
require 'gestures'

class TestSpells < Test::Unit::TestCase
  def setup
    
  end
  
  def test_shield
    gestures_left_test  = ["WP","PECD"]
    gestures_right_test = ["PECD","WP"] 
    gestures_both_test  = ["PECDP","WP"] 
    gestures_both_fail  = ["PECD","WS"] 
    gestures_invoke = [gestures_left_test,
                       gestures_right_test,
                       gestures_both_test]
    
    spell = Shield.conjure
    
    gestures_invoke.each { |g| assert(spell.invoked?(g), "#{g[0]} -- #{g[1]} did not invoke Shield") }
    assert(!spell.invoked?(gestures_both_fail) ," #{gestures_both_fail[0]} -- #{gestures_both_fail[1]}  invoked Shield")
  end
  
  def test_remove_enchantment
    gestures_left_test  = ["ERPDWP","PECD"]
    gestures_right_test = ["PECD","WPDWP"] 
    gestures_both_test  = ["PECDPDWP","EPDWP"] 
    gestures_both_fail  = ["PECD","WSEPDW"] 
    gestures_invoke = [gestures_left_test,
                       gestures_right_test,
                       gestures_both_test]
    
    spell = RemoveEnchantment.conjure
    
    gestures_invoke.each { |g| assert(spell.invoked?(g), "#{g[0]} -- #{g[1]} did not invoke RemoveEnchantment") }
    assert(!spell.invoked?(gestures_both_fail) ," #{gestures_both_fail[0]} -- #{gestures_both_fail[1]}  invoked RemoveEnchantment")      
  end
  
  def test_magic_mirror
    gestures_left_test  = ["CW","CW"]
    gestures_right_test = ["PECDCW","WPCW"] 
    gestures_both_fail  = ["PECW","WSC"] 
    gestures_invoke = [gestures_left_test,
                       gestures_right_test]
    
    spell = MagicMirror.conjure
    
    gestures_invoke.each { |g| assert(spell.invoked?(g), "#{g[0]} -- #{g[1]} did not invoke MagicMirror") }
    assert(!spell.invoked?(gestures_both_fail) ," #{gestures_both_fail[0]} -- #{gestures_both_fail[1]}  invoked MagicMirror")
      
  end
  
  def test_standard_counter_spell
    gestures_left_test  = ["WPP","PECD"]
    gestures_right_test = ["PECD","WPP"] 
    gestures_both_test  = ["PECDWPP","EWWPP"] 
    gestures_both_fail  = ["PECD","WS"] 
    gestures_invoke = [gestures_left_test,
                       gestures_right_test,
                       gestures_both_test]
    
    spell = StandardCounterSpell.conjure
    
    gestures_invoke.each { |g| assert(spell.invoked?(g), "#{g[0]} -- #{g[1]} did not invoke StandardCounterSpell") }
    assert(!spell.invoked?(gestures_both_fail) ," #{gestures_both_fail[0]} -- #{gestures_both_fail[1]}  invoked StandardCounterSpell")      
  end
  
  def test_classic_counter_spell
    gestures_left_test  = ["PEWWS","PECD"]
    gestures_right_test = ["PECD","PEWWS"] 
    gestures_both_test  = ["PECDWWS","WPWWS"] 
    gestures_both_fail  = ["PECD","WS"] 
    gestures_invoke = [gestures_left_test,
                       gestures_right_test,
                       gestures_both_test]
    
    spell = ClassicCounterSpell.conjure
    
    gestures_invoke.each { |g| assert(spell.invoked?(g), "#{g[0]} -- #{g[1]} did not invoke ClassicCounterSpell") }
    assert(!spell.invoked?(gestures_both_fail) ," #{gestures_both_fail[0]} -- #{gestures_both_fail[1]}  invoked ClassicCounterSpell")      
  end 
  
  
  def test_dispel_magic
    gestures_left_test  = ["cDPW","CECD"]
    gestures_right_test = ["CECD","CDPW"] 
    gestures_both_fail  = ["PECD","CDPW"] 
    gestures_invoke = [gestures_left_test,
                       gestures_right_test]
    
    spell = DispelMagic.conjure
    
    gestures_invoke.each { |g| assert(spell.invoked?(g), "#{g[0]} -- #{g[1]} did not invoke DispelMagic") }
    assert(!spell.invoked?(gestures_both_fail) ," #{gestures_both_fail[0]} -- #{gestures_both_fail[1]}  invoked DispelMagic")      
  end
  
  def test_raise_dead
    gestures_left_test  = ["DWWFWC","PECDC"]
    gestures_right_test = ["PECDC","PEWWSDWWFWC"] 
    gestures_both_fail  = ["PECD","WS"] 
    gestures_invoke = [gestures_left_test,
                       gestures_right_test]
    
    spell = RaiseDead.conjure
    
    gestures_invoke.each { |g| assert(spell.invoked?(g), "#{g[0]} -- #{g[1]} did not invoke RaiseDead") }
    assert(!spell.invoked?(gestures_both_fail) ," #{gestures_both_fail[0]} -- #{gestures_both_fail[1]}  invoked RaiseDead")
  end
  
  def test_cure_light_wounds
    gestures_left_test  = ["DFW","PECD"]
    gestures_right_test = ["PECD","DFW"] 
    gestures_both_test  = ["PECDDFW","DFW"] 
    gestures_both_fail  = ["PECD","WS"] 
    gestures_invoke = [gestures_left_test,
                       gestures_right_test,
                       gestures_both_test]
    
    spell = CureLightWounds.conjure
    
    gestures_invoke.each { |g| assert(spell.invoked?(g), "#{g[0]} -- #{g[1]} did not invoke CureLightWounds") }
    assert(!spell.invoked?(gestures_both_fail) ," #{gestures_both_fail[0]} -- #{gestures_both_fail[1]}  invoked CureLightWounds")      
  end
  
  def test_cure_heavy_wounds
    gestures_left_test  = ["DFPW","PECD"]
    gestures_right_test = ["PECD","DFPW"] 
    gestures_both_test  = ["PECDDFPW","DFPW"] 
    gestures_both_fail  = ["PECD","WS"] 
    gestures_invoke = [gestures_left_test,
                       gestures_right_test,
                       gestures_both_test]
    
    spell = CureHeavyWounds.conjure
    
    gestures_invoke.each { |g| assert(spell.invoked?(g), "#{g[0]} -- #{g[1]} did not invoke CureHeavyWounds") }
    assert(!spell.invoked?(gestures_both_fail) ," #{gestures_both_fail[0]} -- #{gestures_both_fail[1]}  invoked CureHeavyWounds")            
  end
end