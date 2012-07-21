require 'character'

module Monster

  def attack
    character.damage(self.target)
  end
end