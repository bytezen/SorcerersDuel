require 'rools'
require 'spell'
require 'wizard'


SpellResolutionRules = Rools::RuleSet.new do
  rule 'shieldSpell' do
    condition {spell.name == 'shield'}
    consequence { puts "Yes, it's a Shield Spell" }
  end

end

white = Wizard.new
shield = Spell.new('shield',['p'])
shield.test = 'Rhazes'
puts shield.test
result = protectionRules.assert(shield)
puts "Status is = #{result}"