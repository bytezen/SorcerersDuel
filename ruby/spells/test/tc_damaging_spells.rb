$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'test/unit'
require 'damaging_spells'
require 'gestures'

class TestDamagingSpells < Test::Unit::TestCase
  
  def test_MagicMissile
    gestures_left_test  = ["SD","PECD"]
    gestures_right_test = ["PECD","SD"] 
    gestures_both_test  = ["PECSD","SD"] 
    gestures_both_fail  = ["PECD","WS"] 
    gestures_invoke = [gestures_left_test,
                       gestures_right_test,
                       gestures_both_test]
    
    spell = MagicMissile.conjure
    
    gestures_invoke.each { |g| assert(spell.invoked?(g), "#{g[0]} -- #{g[1]} did not invoke MagicMissile") }
    assert(!spell.invoked?(gestures_both_fail) ," #{gestures_both_fail[0]} -- #{gestures_both_fail[1]}  invoked MagicMissile")
  end
  
  def test_FingerOfDeath
    gestures_left_test  = ["ERPWPFSSSD","PECD"]
    gestures_right_test = ["PECD","ERPWPFSSSD"] 
    gestures_both_fail  = ["PECD","WSEPDW"] 
    gestures_invoke = [gestures_left_test,
                       gestures_right_test]
    
    spell = FingerOfDeath.conjure
    
    gestures_invoke.each { |g| assert(spell.invoked?(g), "#{g[0]} -- #{g[1]} did not invoke FingerOfDeath") }
    assert(!spell.invoked?(gestures_both_fail) ," #{gestures_both_fail[0]} -- #{gestures_both_fail[1]}  invoked FingerOfDeath")      
  end
  
  def test_ClassicLightningBolt
    gestures_left_test  = ["CWDFFWDDC","CWC"]
    gestures_right_test = ["PECDC","CWDFFWDDC"]
    gestures_both_fail  = ["PECW","WSC"] 
    gestures_invoke = [gestures_left_test,
                       gestures_right_test]
    
    spell = ClassicLightningBolt.conjure
    
    gestures_invoke.each { |g| assert(spell.invoked?(g), "#{g[0]} -- #{g[1]} did not invoke ClassicLightningBolt") }
    assert(!spell.invoked?(gestures_both_fail) ," #{gestures_both_fail[0]} -- #{gestures_both_fail[1]}  invoked ClassicLightningBolt")
      
  end

  def test_StandardLightningBolt
    gestures_left_test  = ["CWDFFDD","CWC"]
    gestures_right_test = ["PECDC","CWDDFFDD"]
    gestures_both_fail  = ["PECW","WSC"] 
    gestures_invoke = [gestures_left_test,
                       gestures_right_test]
    
    spell = StandardLightningBolt.conjure
    
    gestures_invoke.each { |g| assert(spell.invoked?(g), "#{g[0]} -- #{g[1]} did not invoke StandardLightningBolt") }
    assert(!spell.invoked?(gestures_both_fail) ," #{gestures_both_fail[0]} -- #{gestures_both_fail[1]}  invoked StandardLightningBolt")
      
  end

  def test_CauseLightWounds
    gestures_left_test  = ["CWFPSWFP","CW"]
    gestures_right_test = ["PECDCW","WPCWFPSWFP"]
    gestures_both_test  = ["PECDPDWFP","EPDWFP"]     
    gestures_both_fail  = ["PECW","WSC"] 
    gestures_invoke = [gestures_left_test,
                       gestures_right_test,
                       gestures_both_test]
    
    spell = CauseLightWounds.conjure
    
    gestures_invoke.each { |g| assert(spell.invoked?(g), "#{g[0]} -- #{g[1]} did not invoke CauseLightWounds") }
    assert(!spell.invoked?(gestures_both_fail) ," #{gestures_both_fail[0]} -- #{gestures_both_fail[1]}  invoked CauseLightWounds")      
  end
  
  def test_CauseHeavyWounds
    gestures_left_test  = ["DWCSWPFD","PECDCDEFE"]
    gestures_right_test = ["PECDCDE","PEWWSDCSWWPFD"] 
    gestures_both_fail  = ["PECD","WS"] 
    gestures_invoke = [gestures_left_test,
                       gestures_right_test]
    
    spell = CauseHeavyWounds.conjure
    
    gestures_invoke.each { |g| assert(spell.invoked?(g), "#{g[0]} -- #{g[1]} did not invoke CauseHeavyWounds") }
    assert(!spell.invoked?(gestures_both_fail) ," #{gestures_both_fail[0]} -- #{gestures_both_fail[1]}  invoked CauseHeavyWounds")
  end
  
  def test_Fireball
    gestures_left_test  = ["DFCSWPPFSSDD","PECDERF"]
    gestures_right_test = ["PECDERF","DFCSWPPFSSDD"] 
    gestures_both_fail  = ["PECD","WS"] 
    gestures_invoke = [gestures_left_test,
                       gestures_right_test]
    
    spell = Fireball.conjure
    
    gestures_invoke.each { |g| assert(spell.invoked?(g), "#{g[0]} -- #{g[1]} did not invoke Fireball") }
    assert(!spell.invoked?(gestures_both_fail) ," #{gestures_both_fail[0]} -- #{gestures_both_fail[1]}  invoked Fireball")      
  end

  def test_FireStorm
    gestures_left_test  = ["ERERCWSWWC","CECDPWDC"]
    gestures_right_test = ["PEC","ERERCWSWWC"] 
    gestures_both_fail  = ["PECD","WS"] 
    gestures_invoke = [gestures_left_test,
                       gestures_right_test]
    
    spell = FireStorm.conjure
    
    gestures_invoke.each { |g| assert(spell.invoked?(g), "#{g[0]} -- #{g[1]} did not invoke FireStorm") }
    assert(!spell.invoked?(gestures_both_fail) ," #{gestures_both_fail[0]} -- #{gestures_both_fail[1]}  invoked FireStorm")      
  end

  def test_IceStorm
    gestures_left_test  = ["ERERCWSSC","CECDPWDC"]
    gestures_right_test = ["PECDWEDC","ERERCWSSC"] 
    gestures_both_fail  = ["PECD","WS"] 
    gestures_invoke = [gestures_left_test,
                       gestures_right_test]
    
    spell = IceStorm.conjure
    
    gestures_invoke.each { |g| assert(spell.invoked?(g), "#{g[0]} -- #{g[1]} did not invoke IceStorm") }
    assert(!spell.invoked?(gestures_both_fail) ," #{gestures_both_fail[0]} -- #{gestures_both_fail[1]}  invoked IceStorm")      
  end

end