$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'test/unit'
require 'test/tc_damaging_spells'
require 'test/tc_enchantment_spells'
require 'test/tc_protection_spells'
require 'test/tc_summoning_spells'