require 'spells/spell_book'

class Character
  include SpellBook
  attr_writer :name, :life, :opponent, :minions
  attr_reader :name, :life, :opponent, :invoked_spells, :minions
  
  
  def invoke_spell(spell, target=nil)
    #puts "Character #@name invokes #{spell} on #{t}"
    #spell.target = t 
    @invoked_spells.each {|spell| spell.invoke(self,t) }
    #@invoked_spells << spell
  end
  
  def conjure_spell(spell,target=nil,subject=self)
    s = SpellBook.valid_spell?(spell)  
    if(!s) 
        puts "Do not know spell: #{spell}"
        return
    end

    s.subject = subject || self
    s.target  = target || opponent
    @invoked_spells << s
  end

  def invoke_spells
    @invoked_spells.each {|spell| spell.invoke }
  end

  def spells_conjured?
    spells = nil  
    spells    
  end
  
  def damage(damage)
      puts 'Inflicting damage'
    @life-=damage
  end
end