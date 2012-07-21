#----------------------------------------------------------------------
#
#  Copyright (c) Martin Gregory, 1996.  All rights reserved.
#  Copyright (c) John Williams, Terje Bråten, 1996.  All rights reserverd.
#
#  Note that this code implements Richard Bartle's "Waving Hands" game,
#  which is itself copyright.
#
#----------------------------------------------------------------------
#
#      The contents of this file are subject to the FM Public License
#      Version 1.0 (the "License"); you may not use this file except in
#      compliance with the License. You may obtain a copy of the License at
#      ftp://ftp.gamerz.net/pub/fm/LICENSE
#
#      Software distributed under the License is distributed on an "AS IS"
#      basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
#      License for the specific language governing rights and limitations
#      under the License.
#
#      The Original Code is spells.pl.
#
#      The Initial Developer of the Original Code is Martin Gregory.
#
#      Contributors: Terje Bråten, John Williams.
#
#----------------------------------------------------------------------

$Revision .= " SP9.3";

# A list of valid spell names
@Spells = (
               "Dispel Magic",
               "Counter Spell",
               "Magic Mirror",
               "Summon Goblin",
               "Summon Ogre",
               "Summon Troll",
               "Summon Giant",
               "Summon Fire Elemental",
               "Summon Ice Elemental",
               "Raise Dead",
               "Haste",
               "Time Stop",
               "Protection",
               "Resist Heat",
               "Resist Cold",
               "Paralysis",
               "Amnesia",
               "Fear",
               "Confusion",
               "Charm Monster",
               "Charm Person",
               "Disease",
               "Poison",
               "Cure Light Wounds",
               "Cure Heavy Wounds",
               "Anti Spell",
               "Blindness",
               "Invisibility",
               "Permanency",
               "Delay Effect",
               "Remove Enchantment",
               "Shield",
               "Magic Missile",
               "Cause Light Wounds",
               "Cause Heavy Wounds",
               "Short Lightning Bolt",
               "Lightning Bolt",
               "Fireball",
               "Finger of Death",
               "Fire Storm",
               "Ice Storm"
               );

# I have been changing the order of the spells in spells.pl
# and I thought I should write somthing about why things are in
# the order that they are. Also if further changes should be
# made, it is good to have a reference of which conditions must
# be met. So here are the things that must be considered if you
# want to change the spell order.  -Terje
# 
#   - Dispel Magic must be first since it cancels all the other spells.
# 
#   - All the other spells may be countered by Counter Spell, that is
#     why it is second. A disadvantage is that creatures created this
#     round may also be the target of a counter spell. That is why it is
#     repeated after the summon spells as "Counter Spell 2".
# 
#   - Magic Mirror may reflect any other spells, so thats why it should be
#     third. The same catch (and the same fix) considering targeting
#     creatures summoned the same round.
# 
#   - Creatures sommoned may be the target of all the other spells,
#     so the summoning spells should be as near the top of the list
#     as possible.
#
#   - Raise Dead should be near the top for the same reason. The risen
#     creature or mage may be the target of other spells.
# 
#   - Protection must be before Magic Missile.
# 
#   - Shield must be before Magic Missile
# 
#   - Shield must be after Remove Enchantment, since it is not
#     suppoesed to be removed by Remove Enchantment. (It is not
#     an enchantment spell)
# 
#   - All enchantment spells must be before Remove Enchantment.
#
#   - Charm Person must be after the other enchantment spells
#     that cancel each other, so that permanent CP is not so
#     easely destroyed by a later CP.
# 
#   - Remove Enchantment kills monsters by setting their HP to zero,
#     and nullify any effects from Cure Light Wounds or Cure Heavy Wounds,
#     so it must be after Cure Light Wounds and Cure Heavy Wounds.
# 
#   - Resist Heat and Resist Cold must be before Ice Storm and Fire Storm.
# 
#   - Resist Heat must be before Fireball.
# 
#   - If you are hastened, you get to do another gesture before f.eks.
#     a paraysis takes effect, so I put it among the first enchantment
#     spells just for the visual effect. (Not a neccesary condition)

# The order in which the spell routines must be called in one round.
# ** Note - the spell subroutine code is not necessarily in this order
#    in this file!

@SpellOrder = (
               "Dispel Magic",
               "Counter Spell",
               "Magic Mirror",
               "Summon Goblin",
               "Summon Ogre",
               "Summon Troll",
               "Summon Giant",
               "Summon Fire Elemental",
               "Summon Ice Elemental",
               "Raise Dead",
               "Counter Spell 2",
               "Magic Mirror 2",
               "Haste",
               "Time Stop",
               "Protection",
               "Resist Heat",
               "Resist Cold",
               "Paralysis",
               "Amnesia",
               "Fear",
               "Confusion",
               "Charm Monster",
               "Charm Person",
               "Disease",
               "Poison",
               "Cure Light Wounds",
               "Cure Heavy Wounds",
               "Anti Spell",
               "Blindness",
               "Invisibility",
               "Permanency",
               "Delay Effect",
               "Remove Enchantment",
               "Shield",
               "Magic Missile",
               "Cause Light Wounds",
               "Cause Heavy Wounds",
               "Short Lightning Bolt",
               "Lightning Bolt",
               "Fireball",
               "Finger of Death",
               "Fire Storm",
               "Ice Storm"
               );


# Utility functions

# Given a potential spell name, return the name with proper capitalization,
# or "" if the name was not a valid spell
sub GetValidSpellName
{
    my $name = shift;
	 my @matches = grep (/^\Q$name\E$/i, @Spells);
	 if ($#matches >= 0)
	 {
	     return $matches[0];
	 }
	 else
	 {
	     return "";
	 }
}

# A list of valid spell names
sub SpellList
{
	 my $List  = "Valid Spell Names\n";
	 $List .= "-----------------\n";
	 foreach $spell (sort @Spells)
	 {
	     $List .= " $spell\n";
	 }
	 $List .= "\n";
    return $List;
}


# Routines for handling newborns...

sub IsUnborn
{
  local($name) = @_;
  $name =~ /^(R|L|B)H\:/i;
}


sub FindNewborn
{
  local($name) = @_;
  local($wiz,$hand) = ($name, $name);
 
  $wiz =~ s/(.*):(.*)/$2/;
  $hand =~ s/(.*):(.*)/$1/;

  return $Info{$wiz}{$hand.'newborn'};
}


sub CastSpell
{
    local($Spell, $Caster, $Target, $hand, $duration) = @_;

    &IncrementStat('SpellUse', $Spell) unless $Spell =~ m/2$/;

    $SpellCall = $Spell;
    $SpellCall =~ tr/ -2//d;
    $SpellCall = '&'.$SpellCall;
    $InitSpell = 0;

    print LOG "$Spell: $Caster -> $Target\n";

    if ($Target eq 'no_one')
    {
	return eval ($SpellCall.'("NoTarget")');
    }

    $Effect = "";

    if (&IsUnborn($Target))
    {
	if ($Spell =~ m/^Summon / or $Spell eq "Raise Dead")
	{
	    $Effect = eval ($SpellCall.'("NoMonster")');
	    return $Effect;
	}
	elsif ($Spell eq "Counter Spell" or $Spell eq "Magic Mirror")
	{
	    push (@SpellsCast, "$Spell 2#$Caster#$Target#$hand#$duration");
	    return ""; #Postphone spell if an Unborn is the target.
	}
	else
	{
	    $Target = &FindNewborn($Target);
	    if ($Target eq "null-monster")
	    {
		$Target="no_one";
		$Effect = eval ($SpellCall.'("NoTarget")');
		return $Effect;
	    }
	}
    }

    if ($Info{$Caster}{'Blind'} && ($Target ne $Caster))
    {
	$Effect .= eval ($SpellCall.'("Blind")');
    }
    elsif (!&IsLiveBeing($Target))
    {
	$Effect .= eval ($SpellCall.'("DeadTarget")');
    }
    elsif (!$Info{$Caster}{'TimeStoppedTurn'} &&
           ($Info{$Target}{'Invisible'} && ($Target ne $Caster)))
    {
	$Effect .= eval ($SpellCall.'("Invisible")');
	$Target = "no_one";
    }
    else
    {
	if (!$Info{$Caster}{'TimeStoppedTurn'} &&
            ($Info{$Target}{'Reflecting'} && ($Target ne $Caster)))
        {
	    $Effect .= eval ($SpellCall.'("Reflecting")');

            my ($tmp) = $Target;
	    $Target = $Caster;
	    $Caster = $tmp;
	}

	if (!$Info{$Caster}{'TimeStoppedTurn'} &&
           ($Info{$Target}{'Countering'}))
	{
            $Effect .= eval ($SpellCall.'("Countering")');
	}
	else
	{
	    $Effect .= eval ($SpellCall.'("DoSpell")');
	}
    }

    $SpellTarget = $Target; #Update the varible in the main program.

    return $Effect;
}
# The spell routines

sub DispelMagic
{
    local($Action) = @_;
    my ($Eff);

    if (!$InitSpell)
    {
	if ($DispelMagicInForce)
	{
	    $Eff = "An other shock wave emenates from $Caster,\n";
	    $Eff .= " joining the first one.\n\n";
	}
	else
	{
	    $Eff = "An ethereal shock wave emanates from $Caster,\n";
	    $Eff .= " leaving all enchantments crumbling in its wake!\n\n";
	}

	$InitSpell = 1;
    }

    if ($Action eq 'Reflecting')
    {
	$Eff = "As the shock wave hits the shimmering glow surrounding $Target,\n";
	$Eff .= "part of it is reflected back at $Caster!\n\n";
	return $Eff;
    }

    if (($Action eq 'NoTarget') || ($Action eq 'DeadTarget'))
    {
	$Eff .= "The shock wave concentrates into a shield like formation\n";
        $Eff .= "at a random place in the air.\n";
    }
    elsif (($Action eq 'Blind') || ($Action eq 'Invisible'))
    {
	$Eff .= "$Caster could not see $Target when casting the spell.\n";
	$Eff .= "The shock wave forms some kind of shield near $Target\n";
	$Eff .= "but it misses $Target and whirls away.\n";
    }
    elsif ($Action eq 'Countering')
    {
	$Eff .= "The hazy glow around $Target disturbs the shock wave\n";
	$Eff .= "enough that it does not form any shield around $Target\n";
    }
    else
    {
	$Eff .= "The shock wave concentrates into a shield like formation\n";
	$Eff .= "around $Target.\n";
	$Info{$Target}{'DispelShield'} = 1;
    }

    $DispelMagicInForce = 1;

    return $Eff;
}


sub CounterSpell
{
    local($Action) = @_;

    if ($Action eq 'DoSpell')
    {
        my ($String) = '-T ';
        
        if (!$Info{$Target}{'Invisible'})
        {
            $String .= "$Target is surrounded by a hazy glow...\n";
        }
        else
        {
            $String .= "$Target feels secure.\n";
        }

        $Info{$Target}{'Countering'} = 1;

        if (!$Info{$Target}{'Shielded'})
        {
            $Info{$Target}{'Shielded'} = 1;
        }

	return $String;
    }

    local (%Strings) = (
     NoTarget  => "$Caster\'s Counterspell zaps across the circle at a non-existent target!\n",
     Blind      => "$Caster fires a Counterspell, trying to guess where $Target is...\n".
		   "$Caster\'s Counterspell misses $Target.\n",
     DeadTarget => "$Caster\'s Counterspell is wasted.\n",
     Invisible  => "$Caster\'s Counterspell completely misses its invisible target ($Target)!\n",
     Countering =>  "$Caster\'s Counterspell joins the other, forming a hazy glow around $Target.\n",
     Reflecting => "$Caster\'s Counterspell bounces back off $Target!\n"
			);

    if ($Strings{$Action})
    {
	return $Strings{$Action}
    }

    return "Error in FM code. Please report this bug to the FM janitor.\n";
}


sub MagicMirror
{
    local($Action) = @_;

    if ($Action eq 'DoSpell')
    {
        my ($String) = '-T ';
        
        if (!$Info{$Target}{'Invisible'})
        {
            $String .= "$Target is covered by a shimmering glow.\n";
        }
        else
        {
            $String .= "$Target feels reflective.\n";
        }

        $Info{$Target}{'Reflecting'} = 1;

	return $String;
    }

    local (%Strings) = (
     NoTarget  => "$Caster\'s Magic Mirror zaps across the circle at a non-existent target!\n",
     Blind      => "$Caster fires a Magic Mirror, trying to guess where $Target is...\n".
		   "$Caster\'s Magic Mirror misses $Target.\n",
     DeadTarget => "$Caster\'s Magic Mirror is wasted.\n",
     Invisible  =>  "$Caster\'s Magic Mirror completely misses its invisible target ($Target)!\n",
     Countering => "The hazy glow surrounding $Target shimmers for a moment.\n",
     Reflecting => "$Caster\'s Magic Mirror bounces back off $Target!\n"
			);

    if ($Strings{$Action})
    {
	return $Strings{$Action}
    }

    return "Error in FM code. Please report this bug to the FM janitor.\n";
}


sub Shield
{
    local($Action) = @_;

    if ($Action eq 'DoSpell')
    {
        my ($String) = '-T ';
        
        if (!$Info{$Target}{'Invisible'})
        {
            $String .= "A glimmering shield appears in front of $Target.\n";
        }
        else
        {
            $String .= "$Target feels protected.\n";
        }

        if ($Info{$Target}{'Shielded'} >= 0)
        {
	    #Do not destroy "Protection" shield effect
	    if (!$Info{$Target}{'Shielded'})
	    {
		# Shield can't be permanent, so its duration must be 1
		$Info{$Target}{'Shielded'} = 1;
	    }
        }

	return $String;
    }

    local (%Strings) = (
     NoTarget  => "$Caster\'s Shield zaps across the circle at a non-existent target!\n",
     Blind      => "$Caster casts a Shield, trying to guess where $Target is...\n".
		   "$Caster\'s Shield misses $Target.\n",
     DeadTarget => "$Caster\'s Shield is wasted.\n",
     Invisible  => "$Caster\'s Shield completely misses its invisible target ($Target)!\n",
     Countering => "A glimmering shield dissolves in $Target\'s hazy glow.\n",
     Reflecting => "A glimmering shield streaks across to $Target,\n".
		   "but is reflected by $Target\'s shimmering glow!\n"
			);

    if ($Strings{$Action})
    {
	return $Strings{$Action}
    }

    return "Error in FM code. Please report this bug to the FM janitor.\n";
}


sub Protection
{
    local($Action) = @_;

    if ($Action eq 'DoSpell')
    {
        my ($String) = '-T ';
        
        if (!$Info{$Target}{'Invisible'})
        {
            $String .= "A solid, glimmering shield appears in front of $Target.\n";
        }
        else
        {
            $String .= "$Target feels well protected.\n";
        }

        if ($Info{$Target}{'Shielded'}>= 0)
        {
            $Info{$Target}{'Shielded'} = 
		($duration == 999 ? 999 : 4);
        }

	return $String;
    }

    local (%Strings) = (
     NoTarget  => "$Caster\'s Protection zaps across the circle at a non-existent target!\n",
     Blind      => "$Caster casts Protection, trying to guess where $Target is...\n".
		   "$Caster\'s Protection misses $Target.\n",
     DeadTarget => "$Caster\'s Protection is wasted.\n",
     Invisible  => "$Caster\'s Protection completely misses its invisible target ($Target)!\n",
     Countering => "A solid glimmering shield is engulfed in $Target\'s hazy glow.\n",
     Reflecting => "A solid glimmering shield streaks across to $Target,\n".
		   "but is reflected by $Target\'s shimmering glow!\n"
			);

    if ($Strings{$Action})
    {
	return $Strings{$Action}
    }

    return "Error in FM code. Please report this bug to the FM janitor.\n";
}


sub ResistHeat
{
    local($Action) = @_;

    if ($Action eq 'DoSpell')
    {
        my ($String) = '-T ';
        
        if ($Target eq 'FireElemental')
        {
            $String .= "As totaly contrary magic tries to take hold of it,\n";
            $String .= "the Fire Elemental withers, then, with a 'pop', disappears!\n";
        }
        elsif (!$Info{$Target}{'Invisible'})
        {
            $String .= "$Target is covered with sparking hoarfrost.\n";
        }
        else
        {
            $String .= "$Target feels cool\n";
        }

        $Info{$Target}{'HeatResistant'} = -1;

	return $String;
    }

    local (%Strings) = (
     NoTarget  => "$Caster\'s Resist Heat zaps across the circle at a non-existent target!\n",
     Blind      => "$Caster casts Resist Heat, trying to guess where $Target is...\n".
		   "$Caster\'s Resist Heat misses $Target.\n",
     DeadTarget => "$Caster\'s Resist Heat is wasted.\n",
     Invisible  => "$Caster\'s Resist Heat completely misses its invisible target ($Target)!\n",
     Countering => "Powdery frost sprinkes off $Target\'s hazy glow.\n",
     Reflecting => "$Caster\'s Resist Heat spell reflects off the shimmering glow surrounding $Target!\n"
			);

    if ($Strings{$Action})
    {
	return $Strings{$Action}
    }

    return "Error in FM code. Please report this bug to the FM janitor.\n";
}


sub ResistCold
{
    local($Action) = @_;

    if ($Action eq 'DoSpell')
    {
        my ($String) = '-T ';
        
        if ($Target eq 'IceElemental')
        {
            $String .= "As totaly contrary magic tries to take hold of it,\n";
            $String .= "the Ice Elemental withers, then, with a sharp 'crack', disappears!\n";
        }
        elsif (!$Info{$Target}{'Invisible'})
        {
            $String .= "$Target\'s cheeks take on a ruddy glow.\n";
        }
        else
        {
            $String .= "$Target feels warm.\n";
        }

        $Info{$Target}{'ColdResistant'} = -1;

	return $String;
    }

    local (%Strings) = (
     NoTarget  => "$Caster\'s Resist Cold zaps across the circle at a non-existent target!\n",
     Blind      => "$Caster casts Resist Cold, trying to guess where $Target is...\n".
		   "$Caster\'s Resist Cold misses $Target.\n",
     DeadTarget => "$Caster\'s Resist Cold is wasted.\n",
     Invisible  => "$Caster\'s Resist Cold completely misses its invisible target ($Target)!\n",
     Countering => "$Target\'s hazy glow turns deep red for a moment.\n",
     Reflecting => "$Caster\'s Resist Cold spell reflects off the shimmering glow surrounding $Target!\n"
			);

    if ($Strings{$Action})
    {
	return $Strings{$Action}
    }

    return "Error in FM code. Please report this bug to the FM janitor.\n";
}


sub SummonMonster
{
    local($Monster, $Strength) = @_;

    if ($Action eq 'DoSpell')
    {
	$NewName = &NewColour . $Monster;

	&CreateBeing($NewName, $Strength);

	$hand = $HandMap{$hand};
	$Info{$Caster}{"${hand}newborn"} = $NewName;

	if (&IsMonster($Target))
	{
	    $Info{$NewName}{'Controller'} = $Info{$Target}{'Controller'};
	}
	else
	{
	    $Info{$NewName}{'Controller'} = $Target;
	}

	$Attack = &Opponent($Info{$NewName}{'Controller'});
	$Info{$NewName}{'Target'} = $Attack;

	if ($Attack eq 'no_one')
	{
	    return "-T $NewName springs into being and looks at $Info{$NewName}{'Controller'} for instructions.\n";
	}
	else
	{
	    return "-T $NewName springs into being and rushes at $Attack.\n";
	}
    }

    local (%Strings) = (
     NoMonster  => "$Caster\'s attempt to cast a Summon spell at a being that\n".
		   "did not exist from the beginning of the turn fails miserably.\n",
     NoTarget   => "$Caster\'s $Spell zaps across the circle at a non-existent target!\n",
     Blind      => "$Caster casts $Spell, trying to guess where $Target is...\n".
		   "$Caster\'s $Spell misses $Target.\n",
     DeadTarget => "$Caster\'s $Spell is wasted.\n",
     Invisible  => "$Caster\'s $Spell completely misses its invisible target ($Target)!\n",
     Countering => "-T As a $Monster springs into being, it is absorbed by $Target\'s hazy glow.\n",
     Reflecting => "-T $Caster\'s $Spell spell reflects off the shimmering glow surrounding $Target!\n"
			);

    if ($Strings{$Action})
    {
	return $Strings{$Action}
    }

    return "Error in FM code. Please report this bug to the FM janitor.\n";
}

sub SummonGoblin
{
    local($Action) = @_;
    &SummonMonster('Goblin',1);
}

sub SummonOgre
{
    local($Action) = @_;
    &SummonMonster('Ogre',2);
}

sub SummonTroll
{
    local($Action) = @_;
    &SummonMonster('Troll',3);
}

sub SummonGiant
{
    local($Action) = @_;
    &SummonMonster('Giant',4);
}


sub SummonFireElemental
{
    local($Action) = @_;
    &SummonElemental('Fire','Ice');
}

sub SummonIceElemental
{
    local($Action) = @_;
    &SummonElemental('Ice','Fire');
}


sub SummonElemental
{
    local ($ThisElement,$OtherElement) = @_;
    local ($Screams) = ($ThisElement eq 'Fire') ? "roars" : "shrieks";

    if ($Action ne 'NoTarget')
    {
	return "Error in code. Contact the janitor about this bug.\n";
    }

    my ($Effect) = "A $ThisElement Elemental springs into being, and $Screams with indignation!\n";

    if ($FireAndIceExplosion) {
        $Effect .= "The $ThisElement Elemental dies in the shower of ice and flame.\n";
	push (@DeadMonsters,"${ThisElement}Elemental");
    }
    elsif (${"${ThisElement}ElementalPresent"})
    {
        $Effect .= "The two $ThisElement Elementals blaze as they merge!\n";
        $Info{"${ThisElement}Elemental"}{'HP'} = 3;
    }
    elsif (${"${OtherElement}ElementalPresent"})
    {
        $Effect .= "The $OtherElement Elements howls as it sees a worthy foe!\n";
        $Effect .= "The two Elementals lock in combat...\n";
        $Effect .= "... and disappear in a shower of ice and flame.\n";

	&KillBeing("${OtherElement}Elemental");
	push (@DeadMonsters,"${ThisElement}Elemental");
        ${"${OtherElement}ElementalPresent"} = 0;
        $FireAndIceExplosion = 1;
    }
    else
    {
        ${"${ThisElement}ElementalPresent"} = @Beings;

        $NewName = "${ThisElement}Elemental";

        &CreateBeing($NewName, 3);

	$hand = $HandMap{$hand};
	$Info{$Caster}{"${hand}newborn"} = $NewName;

        $Info{$NewName}{'Controller'} = 'none';
        $Info{$NewName}{'Target'} = 'none';
    }

    return $Effect;
}

sub EnchantCancel
#Generic routine to check if an enchantment cancels against an other.
{
    my($SpellType) = @_;
    
    if ($Info{$Target}{'EnchantCancelled'} &&  # might not be initialised
	$Info{$Target}{'EnchantCancelled'} > 1)
    {
	return "Another enchantment whirls around $Target, and crackles away to nothing.\n";
    }
    elsif ($SpellType eq 'Paralysis')
    {
	if ($Info{$Target}{'EnchantCancelled'})
	{
	    return "Another paralysis whirls around $Target, and crackles away to nothing.\n";
	}
        if (&Num($Info{$Target}{'Paralyzed'}) > 0)
        {
            # Paralysis cancel with itself
            $Info{$Target}{'Paralyzed'} =
		Min(&Num($Info{$Target}{'Paralyzed'}), 0);
            $Info{$Target}{'EnchantCancelled'} = 1;
            return "Suddenly $Target seems back to normal again!\n";
        }
        elsif (($Info{$Target}{'Forgetful'} > 0) ||
               (&Num($Info{$Target}{'Confused'}) > 0) ||
               (&Num($Info{$Target}{'Charmed'}) > 0) ||
               ($Info{$Target}{'Afraid'} > 0))
        {
            # Paralysis does not cancel other effects
            return "$Target feels a slight stiffening of the joints.\n";
        }
    }
    else
    {
        # Some other spell than paralysis: definitely cancels anything,
        # but is not cancelled by paralysis
        if ((&Num($Info{$Target}{'Paralyzed'}) > 0) || 
	    $Info{$Target}{'EnchantCancelled'})
        {
            $Info{$Target}{'Paralyzed'} =
		Min(&Num($Info{$Target}{'Paralyzed'}), 0);
            return "The Paralysis taking hold of $Target gives way to a more potent effect...\n";
	    $Info{$Target}{'EnchantCancelled'} = 0;
        }
        elsif (($Info{$Target}{'Forgetful'} > 0) || 
               (&Num($Info{$Target}{'Confused'}) > 0) ||
               (&Num($Info{$Target}{'Charmed'}) > 0) ||
               ($Info{$Target}{'Afraid'} > 0))
        {
            $Info{$Target}{'Forgetful'} = Min($Info{$Target}{'Forgetful'}, 0);
            $Info{$Target}{'Confused'} = Min(&Num($Info{$Target}{'Confused'}), 0);
            $Info{$Target}{'Charmed'} = Min(&Num($Info{$Target}{'Charmed'}), 0);
            $Info{$Target}{'Afraid'} = Min($Info{$Target}{'Afraid'}, 0);

            $Info{$Target}{'EnchantCancelled'} = 2;
            return "Suddenly $Target seems back to normal again!\n";
        }
    }

    return "";
}

sub Paralysis
{
    local($Action) = @_;

    if ($Action eq 'DoSpell')
    {
        my ($String) = '-T ';
        
	$String .= &EnchantCancel('Paralysis');
	if (!$Info{$Target}{'EnchantCancelled'})
        {
            if ($Info{$Target}{'Paralyzed'} >= 0)
            {
                $Info{$Target}{'Paralyzed'} = $duration;
            }
            if ($Info{$Target}{'ParalyzedRight'})
            {
                $String .= "It looks like $Target\'s right hand is going to be stuck again...\n";
                $Info{$Target}{'ParalyzedRight'} = $Info{$Target}{'Paralyzed'};
            }
            elsif ($Info{$Target}{'ParalyzedLeft'})
            {
                $String .= "It looks like $Target\'s left hand is going to be stuck again...\n";
                $Info{$Target}{'ParalyzedLeft'} = $Info{$Target}{'Paralyzed'};
            }
            else
            {
                $Info{$Target}{'Paralyser'} = $Caster;
                $String .= "$Caster\'s Paralysis spell takes hold of $Target.\n";
            }
        }

	return $String;
    }

    local (%Strings) = (
     NoTarget   => "$Caster\'s $Spell zaps across the circle at a non-existent target!\n",
     Blind      => "$Caster casts a $Spell, trying to guess where $Target is...\n".
		   "$Caster\'s $Spell misses $Target.\n",
     DeadTarget => "$Caster\'s $Spell is wasted.\n",
     Invisible  => "$Caster\'s $Spell completely misses its invisible target ($Target)!\n",
     Countering => "$Caster\'s $Spell spell fizzles against $Target\'s hazy glow.\n",
     Reflecting => "$Caster\'s $Spell spell reflects off the shimmering glow surrounding $Target!\n"
			);

    if ($Strings{$Action})
    {
	return $Strings{$Action}
    }

    return "Error in FM code. Please report this bug to the FM janitor.\n";
}


sub Amnesia
{
    local($Action) = @_;

    if ($Action eq 'DoSpell')
    {
        my ($String) = '-T ';

	$String .= &EnchantCancel('Amnesia');
        if (!$Info{$Target}{'EnchantCancelled'})
	{
	    if ($Info{$Target}{'Forgetful'} >= 0)
	    {
		$String .= "$Target"." starts to look a little dopey.\n";

		$Info{$Target}{'Forgetful'} = $duration;
	    }
	    else
	    {
		$String .= "$Target is already pretty dopey.\n";
	    }
	}
	return $String;
    }

    local (%Strings) = (
     NoTarget   => "$Caster\'s $Spell zaps across the circle at a non-existent target!\n",
     Blind      => "$Caster casts a $Spell, trying to guess where $Target is...\n".
		   "$Caster\'s $Spell misses $Target.\n",
     DeadTarget => "$Caster\'s $Spell is wasted.\n",
     Invisible  => "$Caster\'s $Spell completely misses its invisible target ($Target)!\n",
     Countering => "$Caster\'s $Spell spell fizzles against $Target\'s hazy glow.\n",
     Reflecting => "$Caster\'s $Spell spell reflects off the shimmering glow surrounding $Target!\n"
			);

    if ($Strings{$Action})
    {
	return $Strings{$Action}
    }

    return "Error in FM code. Please report this bug to the FM janitor.\n";
}


sub Fear
{
    local($Action) = @_;

    if ($Action eq 'DoSpell')
    {
        my ($String) = '-T ';
        
	$String .= &EnchantCancel('Fear');
        if (!$Info{$Target}{'EnchantCancelled'})
	{
	    if ($Info{$Target}{'Afraid'} >= 0)
	    {
		$String .= "Suddenly, $Target starts to look very frightened!\n";
		$Info{$Target}{'Afraid'} = $duration;
	    }
	    else
	    {
		$String .= "$Target is already pretty frightened.\n";
	    }
	}

	return $String;
    }

    local (%Strings) = (
     NoTarget   => "$Caster\'s $Spell zaps across the circle at a non-existent target!\n",
     Blind      => "$Caster casts a $Spell, trying to guess where $Target is...\n".
		   "$Caster\'s $Spell misses $Target.\n",
     DeadTarget => "$Caster\'s $Spell is wasted.\n",
     Invisible  => "$Caster\'s $Spell completely misses its invisible target ($Target)!\n",
     Countering => "$Caster\'s $Spell spell fizzles against $Target\'s hazy glow.\n",
     Reflecting => "$Caster\'s $Spell spell reflects off the shimmering glow surrounding $Target!\n"
			);

    if ($Strings{$Action})
    {
	return $Strings{$Action}
    }

    return "Error in FM code. Please report this bug to the FM janitor.\n";
}


sub Confusion
{
    local($Action) = @_;

    if ($Action eq 'DoSpell')
    {
        my ($String) = '-T ';
        
	$String .= &EnchantCancel('Confusion');
        if (!$Info{$Target}{'EnchantCancelled'})
	{
	    if ($Info{$Target}{'Confused'} >= 0)
	    {
		$String .= "All of a sudden, $Target starts to find things rather confusing...\n";
		$Info{$Target}{'Confused'} = $duration;
	    }
	    else
	    {
		$String .= "$Target is already pretty confused.\n";
	    }
	}

	return $String;
    }

    local (%Strings) = (
     NoTarget   => "$Caster\'s $Spell zaps across the circle at a non-existent target!\n",
     Blind      => "$Caster casts a $Spell, trying to guess where $Target is...\n".
		   "$Caster\'s $Spell misses $Target.\n",
     DeadTarget => "$Caster\'s $Spell is wasted.\n",
     Invisible  => "$Caster\'s $Spell completely misses its invisible target ($Target)!\n",
     Countering => "$Caster\'s $Spell spell fizzles against $Target\'s hazy glow.\n",
     Reflecting => "$Caster\'s $Spell spell reflects off the shimmering glow surrounding $Target!\n"
			);

    if ($Strings{$Action})
    {
	return $Strings{$Action}
    }

    return "Error in FM code. Please report this bug to the FM janitor.\n";
}


sub CharmMonster
{
    local($Action) = @_;

    if ($Action eq 'DoSpell')
    {
        my ($String) = '-T ';
        
	$String .= &EnchantCancel('CharmMonster');
        if (!$Info{$Target}{'EnchantCancelled'})
	{
            if (&IsMonster($Target))
            {
                $String .= "$Target seems quite enchanted by $Caster.\n";
                $Info{$Target}{'Charmed'} = "1 $Caster";
            }
            else
            {
                $String .= "$Target ignores $Caster\'s appeal to $Target\'s baser instincts.\n";
                $Info{$Target}{'EnchantCancelled'} = 2;
            }
	}

	return $String;
    }

    local (%Strings) = (
     NoTarget   => "$Caster\'s $Spell zaps across the circle at a non-existent target!\n",
     Blind      => "$Caster casts $Spell, trying to guess where $Target is...\n".
		   "$Caster\'s $Spell misses $Target.\n",
     DeadTarget => "$Caster\'s $Spell is wasted.\n",
     Invisible  => "$Caster\'s $Spell completely misses its invisible target ($Target)!\n",
     Countering => "$Target looks scornfully from behind a hazy glow at\n".
		    " $Caster\'s attempts to be charming.\n",
     Reflecting => "The shimmering glow surrounding $Target somehow \nmakes $Target look very charming to $Caster.\n"
			);

    if ($Strings{$Action})
    {
	return $Strings{$Action}
    }

    return "Error in FM code. Please report this bug to the FM janitor.\n";
}


sub CharmPerson
{
    local($Action) = @_;

    if ($Action eq 'DoSpell')
    {
        my ($String) = '-T ';
        
	$String .= &EnchantCancel('CharmPerson');
        if (!$Info{$Target}{'EnchantCancelled'})
	{
            if (&IsMonster($Target))
            {
                $String .= "$Target doesn't find $Caster\'s human antics particularly charming.\n";
                $Info{$Target}{'EnchantCancelled'} = 2;
            }
            else
            {
                $String .= "$Target starts to look persuaded by $Caster.\n";
                $Info{$Target}{'Controller'} = $Caster;
                $Info{$Target}{'Charmed'} = $duration;
		$Info{$Target}{'CharmedRight'} = 0; #Destroys any permanent CP
		$Info{$Target}{'CharmedLeft'} = 0;  #Destroys any permanent CP
            }
	}

	return $String;
    }

    local (%Strings) = (
     NoTarget   => "$Caster\'s $Spell zaps across the circle at a non-existent target!\n",
     Blind      => "$Caster casts $Spell, trying to guess where $Target is...\n".
		   "$Caster\'s $Spell misses $Target.\n",
     DeadTarget => "$Caster\'s $Spell is wasted.\n",
     Invisible  => "$Caster\'s $Spell completely misses its invisible target ($Target)!\n",
     Countering => "$Target looks scornfully from behind a hazy glow at\n".
		    " $Caster\'s attempts to be charming.\n",
     Reflecting => "The shimmering glow surrounding $Target somehow \nmakes $Target look very charming to $Caster.\n"
			);

    if ($Strings{$Action})
    {
	return $Strings{$Action}
    }

    return "Error in FM code. Please report this bug to the FM janitor.\n";
}


sub Haste
{
    local($Action) = @_;

    if ($Action eq 'DoSpell')
    {
        my ($String);

        if ($Info{$Target}{'Fast'} >= 0)
        {

            $Info{$Target}{'Fast'} =
                ($duration == 999 ? 999 : 3);

            $String = "-T ";

            $String .= "$Target speeds up!\n";
        }
        else
        {
            $String = "$Target is already pretty fast.\n";
        }

	return $String;
    }

    local (%Strings) = (
     NoTarget   => "$Caster\'s $Spell spell zaps across the circle at a non-existent target!\n",
     Blind      => "$Caster casts $Spell, trying to guess where $Target is...\n".
		   "$Caster\'s $Spell spell misses $Target.\n",
     DeadTarget => "$Caster\'s $Spell is wasted.\n",
     Invisible  => "$Caster\'s $Spell completely misses its invisible target ($Target)!\n",
     Countering => "$Target speeds up for a moment.\n",
     Reflecting => "$Caster\'s $Spell spell reflects off the shimmering glow surrounding $Target!\n"
			);

    if ($Strings{$Action})
    {
	return $Strings{$Action}
    }

    return "Error in FM code. Please report this bug to the FM janitor.\n";
}


sub RaiseDead
{
    local($Action) = @_;

    if ($Action eq 'DoSpell')  # must be casting at a live target.
    {
	my($String)="-T ";

	if (!($Info{$Target}{'Risen'} || $Info{$Target}{'NewRisen'}))
	{
	    $String="Mighty life magic is flowing through the air...\n";
	}

	$Info{$Target}{'Risen'}++;

	$String .= "$Target feels streams of life flowing through $Target\'s body.\n";

	if ($Info{$Target}{'NewRisen'})
	{
	    if ($Info{$Target}{'Controller'} ne $Caster)
	    {
		$Info{$Target}{'Controller'} = 'no_one';
		$Info{$Target}{'Target'} = 'no_one';
		$String .= "... $Target does not know to who to be thankful to or whom to obey!\n";
	    }
	}

	return $String;
    }

    if ($Action eq 'DeadTarget')
    {
        my($String) = "Mighty magic of life is flowing through the air...\n";

	if (grep($Target eq $_,@DeadMonsters))
	{
	    $String .= "... the decaying remains of the body of the $Target rises up and are healed.\n\n";

	    if ($Target =~ m/((Ice)|(Fire)) *Elemental/i)
	    {
		my ($ThisElement) = $1;
		my ($OtherElement) = ($ThisElement eq 'Fire') ? "Ice" : "Fire";
		my ($Screams) = ($ThisElement eq 'Fire') ? "roars" : "shrieks";

		$String .= "$Target is alive, and $Screams with indignation!\n";
		if ($FireAndIceExplosion)
		{
		    $String .= "The $Target dies again in the shower of ice and flame.\n";
		    return $String;
		}

		if ($ {"${OtherElement}ElementalPresent"})
	        {
		    $String .= "The $OtherElement Elements howls as it sees a worthy foe!\n";
		    $String .= "The two Elementals lock in combat...\n";
		    $String .= "... and disappear in a shower of ice and flame.\n";
		    &KillBeing("${OtherElement}Elemental");
		    ${"${OtherElement}ElementalPresent"} = 0;
	            $FireAndIceExplosion = 1;
		    return $String;
		}

	        ${"${Target}Present"} = @Beings;
		&CreateBeing ($Target,3);

		$Info{$Target}{'Controller'} = 'none';
		$Info{$Target}{'Target'} = 'none';
            }
            else
            {
		&CreateBeing ($Target,&MaxHP($Target));

                $Info{$Target}{'Controller'} = $Caster;
		$Info{$Target}{'NewRisen'}=1;

                my($Attack) = &Opponent($Caster);
                $Info{$Target}{'Target'} = $Attack;

                if ($Attack eq 'no_one')
                {
		    $String .= "$Target is alive, and looks at $Info{$Target}{'Controller'} for instructions.\n";
		}
                else
                {
		    $String .= "$Target is alive, and rushes at $Attack.\n";
		}
            }

            for ($i=0;$i<@DeadMonsters;$i++)
	    {
		next unless $Target eq $DeadMonsters[$i];
		splice(@DeadMonsters,$i,1);
		last;
	    }


            $hand = $HandMap{$hand};
	    $Info{$Caster}{"${hand}newborn"} = $Target;

	    return $String;
	}

	if (grep($Target eq $_,@DeadPlayers))
	{
	    if ($Info{$Target}{'State'} eq 'OUT')
	    {
		$String .= "$Target, sitting watching the battle from the side, feels wonderfully alive!\n";
		return $String;
	    }

	    $String .= "
The bones of $Target come up from the ground and flesh is formed on them.

Thunder and lightening strikes ravage the Circle, as Hell opens up and
delivers the soul of the lost mage $Target.

The body of $Target rises to its feet.

$Target is alive!
";

	    for ($i=0;$i<@DeadPlayers;$i++)
	    {
		next unless $Target eq $DeadPlayers[$i];
		splice(@DeadPlayers,$i,1);
		last;
	    }

	    $Info{$Target}{'HP'} = 15;
	    $Info{$Target}{'State'} = 'orders';

	    return $String;
	}

	return "Error in code. Please report this bug to the Janitor.\n";
    }

    local (%Strings) = (
     NoMonster  => "$Caster\'s attempt to cast Raise Dead at a being that\n".
		   "did not exist from the beginning of the turn fails miserably.\n",
     NoTarget   => "$Caster\'s $Spell zaps across the circle at a non-existent target!\n",
     Blind      => "$Caster is trying to guess where $Target is...\n".
		   "$Caster\'s $Spell misses $Target.\n",
     Invisible  => "$Caster\'s $Spell completely misses its invisible target ($Target)!\n",
     Countering => "The hazy glow around $Target effortlessly absorbs\n".
		   " $Caster\'s $Spell spell.\n",
     Reflecting => "$Caster\'s $Spell spell reflects off the shimmering glow surrounding $Target!\n"
			);

    if ($Strings{$Action})
    {
	return $Strings{$Action}
    }

    return "Error in FM code. Please report this bug to the FM janitor.\n";
}


sub TimeStop
{
    local($Action) = @_;

    if ($Action eq 'DoSpell')
    {
        my ($String) = '-T ';
        $String .= "$Target slips into another timeline!\n";

        $Info{$Target}{'TimeStopped'} = 1;

	return $String;
    }

    local (%Strings) = (
     NoTarget   => "$Caster\'s $Spell zaps across the circle at a non-existent target!\n",
     Blind      => "$Caster casts $Spell, trying to guess where $Target is...\n".
		   "$Caster\'s $Spell misses $Target.\n",
     DeadTarget => "$Caster\'s $Spell is wasted.\n",
     Invisible  => "$Caster\'s $Spell completely misses its invisible target ($Target)!\n",
     Countering => "The hazy glow surrounding $Target swirls anti-clockwise.\n",
     Reflecting => "$Caster\'s $Spell spell reflects off the shimmering glow surrounding $Target!\n"
			);

    if ($Strings{$Action})
    {
	return $Strings{$Action}
    }

    return "Error in FM code. Please report this bug to the FM janitor.\n";
}


sub Disease
{
    local($Action) = @_;

    if ($Action eq 'DoSpell')
    {
        my ($String) = '-T ';
        
        if ($Info{$Target}{'Invisible'})
        {
            $String .= "$Target starts to ache all over\n";
        }
        else
        {
            $String .= "$Target breaks out in spots.\n";
        }

        if (!$Info{$Target}{'Sick'})
        {
            $Info{$Target}{'Sick'} = 6;
        }

	return $String;
    }

    local (%Strings) = (
     NoTarget   => "$Caster\'s $Spell zaps across the circle at a non-existent target!\n",
     Blind      => "$Caster casts $Spell, trying to guess where $Target is...\n".
		   "$Caster\'s $Spell misses $Target.\n",
     DeadTarget => "$Caster\'s $Spell is wasted.\n",
     Invisible  => "$Caster\'s $Spell completely misses its invisible target ($Target)!\n",
     Countering => "$Target looks nauseous for a moment.\n",
     Reflecting => "A stream of deadly virus reflects off the shimmering glow surrounding $Target!\n"
			);

    if ($Strings{$Action})
    {
	return $Strings{$Action}
    }

    return "Error in FM code. Please report this bug to the FM janitor.\n";
}


sub Poison
{
    local($Action) = @_;

    if ($Action eq 'DoSpell')
    {
        my ($String) = '-T ';

        if ($Info{$Target}{'Invisible'})
        {
            $String .= "Magic venom infiltrates $Target's veins.\n";
        }
        else
        {
            $String .= "$Target wilts.\n";
        }

        if (!$Info{$Target}{'Poisoned'})
        {
            $Info{$Target}{'Poisoned'} = 6;
        }

	return $String;
    }

    local (%Strings) = (
     NoTarget   => "$Caster\'s $Spell zaps across the circle at a non-existent target!\n",
     Blind      => "$Caster casts $Spell, trying to guess where $Target is...\n".
		   "$Caster\'s $Spell misses $Target.\n",
     DeadTarget => "$Caster\'s $Spell is wasted.\n",
     Invisible  => "$Caster\'s $Spell completely misses its invisible target ($Target)!\n",
     Countering => "$Target looks sickly for a moment.\n",
     Reflecting => "A stream of deadly venom bounces off the shimmering glow surrounding $Target!\n"
			);

    if ($Strings{$Action})
    {
	return $Strings{$Action}
    }

    return "Error in FM code. Please report this bug to the FM janitor.\n";
}


sub Blindness
{
    local($Action) = @_;

    if ($Action eq 'DoSpell')
    {
        my ($String);
        if (&IsMonster($Target))
        {
            $String = "$Target is blinded!\n";
            $String .= "$Target wanders off aimlessly, then just disintegrates.\n";
	    &KillBeing($Target);
        }
        elsif ($Info{$Target}{'Blind'} >=0 )
        {
            $String = "-T ";
            $String .= "$Target finds the world starting to look dim.\n"; 
            $Info{$Target}{'StruckBlind'} =
                ($duration == 999 ? 999 : 4);
        }
        else
        {
            $String = "$Target is already completely blind.\n";
	}

	return $String;
    }

    local (%Strings) = (
     NoTarget   => "$Caster\'s $Spell zaps across the circle at a non-existent target!\n",
     Blind      => "$Caster casts $Spell, trying to guess where $Target is...\n".
		   "$Caster\'s $Spell misses $Target.\n",
     DeadTarget => "$Caster\'s $Spell is wasted.\n",
     Invisible  => "$Caster\'s $Spell completely misses its invisible target ($Target)!\n",
     Countering => "$Target blinks for a moment.\n",
     Reflecting => "A bright flash reflects off the shimmering glow surrounding $Target!\n"
			);

    if ($Strings{$Action})
    {
	return $Strings{$Action}
    }

    return "Error in FM code. Please report this bug to the FM janitor.\n";
}


sub Invisibility
{
    local($Action) = @_;

    if ($Action eq 'DoSpell')
    {
        my ($String) = '-T ';

        if (&IsMonster($Target))
        {
            $String .= "$Target disappears in a puff of smoke!\n";
	    &KillBeing($Target);
        }
        elsif (!$Info{$Target}{'Invisible'}) 
        {
            $String .= "$Target starts to look blurry around the edges!\n";
            $Info{$Target}{'Disappearing'} =
                ($duration == 999 ? 999 : 4);
        }

	return $String;
    }

    local (%Strings) = (
     NoTarget   => "$Caster\'s $Spell zaps across the circle at a non-existent target!\n",
     Blind      => "$Caster casts $Spell, trying to guess where $Target is...\n".
		   "$Caster\'s $Spell misses $Target.\n",
     DeadTarget => "$Caster\'s $Spell is wasted.\n",
     Invisible  => "$Caster\'s $Spell completely misses its invisible target ($Target)!\n",
     Countering => "$Target appears blurry around the edges for a moment.\n",
     Reflecting => "$Caster\'s $Spell spell reflects off the shimmering glow surrounding $Target!\n"
			);

    if ($Strings{$Action})
    {
	return $Strings{$Action}
    }

    return "Error in FM code. Please report this bug to the FM janitor.\n";
}


sub RemoveEnchantment
{
    local($Action) = @_;

    if ($Action eq 'DoSpell')
    {
	&RemoveAllEnchantments($Target, 0);
        
        my ($String) = "Tendrils reach out and pick at $Target, absorbing magical energy.\n";

        if (&IsMonster($Target))
        {
            $String .= "$Target goes all wobbly.\n";
            $Info{$Target}{'HP'} = 0;
	    $Info{$Target}{'HeavyWoundsCured'} = 0;
	    $Info{$Target}{'LightWoundsCured'} = 0;
        }
        else
        {
            $String .= "Suddenly $Target seems completely ordinary again!\n";
        }

	return $String;
    }

    local (%Strings) = (
     NoTarget   => "$Caster\'s $Spell zaps across the circle at a non-existent target!\n",
     Blind      => "$Caster casts $Spell, trying to guess where $Target is...\n".
		   "$Caster\'s $Spell misses $Target.\n",
     DeadTarget => "$Caster\'s $Spell is wasted.\n",
     Invisible  => "$Caster\'s $Spell completely misses its invisible target ($Target)!\n",
     Countering => "Tendrils reaching towards $Target are cut short as they hit a hazy glow.\n",
     Reflecting => "Tendrils reaching towards $Target bounce off a shimmering glow!\n"
			);

    if ($Strings{$Action})
    {
	return $Strings{$Action}
    }

    return "Error in FM code. Please report this bug to the FM janitor.\n";
}


sub ShortLightningBolt
{
    local($Action) = @_;

    if ($Action eq 'DoSpell')
    {
        $Info{$Target}{'HitByLightning'} += 1;

	    $Info{$Caster}{'ShortLightningUsed'} = 1;
	return "A Lightning Bolt arcs across the circle towards $Target!\n";
    }

    local (%Strings) = (
     NoTarget   => "$Caster\'s $Spell zaps across the circle at a non-existent target!\n",
     Blind      => "$Caster casts $Spell, trying to guess where $Target is...\n".
		   "$Caster\'s $Spell misses $Target.\n",
     DeadTarget => "$Caster\'s $Spell is wasted.\n",
     Invisible  => "$Caster\'s $Spell completely misses its invisible target ($Target)!\n",
     Countering => "The hazy glow around $Target crackles as it absorbs\n".
		   " $Caster\'s Lightning Bolt\n",
     Reflecting => "$Caster\'s $Spell reflects off the shimmering glow surrounding $Target!\n"
			);

    if ($Strings{$Action})
    {
	return $Strings{$Action}
    }

    return "Error in FM code. Please report this bug to the FM janitor.\n";
}

sub LightningBolt
{
    local($Action) = @_;

    if ($Action eq 'DoSpell')
    {
        $Info{$Target}{'HitByLightning'} += 1;

	return "A Lightning Bolt arcs across the circle towards $Target!\n";
    }

    local (%Strings) = (
     NoTarget   => "$Caster\'s $Spell zaps across the circle at a non-existent target!\n",
     Blind      => "$Caster casts $Spell, trying to guess where $Target is...\n".
		   "$Caster\'s $Spell misses $Target.\n",
     DeadTarget => "$Caster\'s $Spell is wasted.\n",
     Invisible  => "$Caster\'s $Spell completely misses its invisible target ($Target)!\n",
     Countering => "The hazy glow around $Target crackles as it absorbs\n".
		   " $Caster\'s Lightning Bolt\n",
     Reflecting => "$Caster\'s $Spell reflects off the shimmering glow surrounding $Target!\n"
			);

    if ($Strings{$Action})
    {
	return $Strings{$Action}
    }

    return "Error in FM code. Please report this bug to the FM janitor.\n";
}


sub Fireball
{
    local($Action) = @_;

    if ($Action eq 'DoSpell')
    {
        $Info{$Target}{'HitByFireBall'} += 1;

	return "A Fireball leaps across the circle towards $Target!\n";
    }

    local (%Strings) = (
     NoTarget   => "$Caster\'s $Spell zaps across the circle at a non-existent target!\n",
     Blind      => "$Caster casts $Spell, trying to guess where $Target is...\n".
		   "$Caster\'s $Spell misses $Target.\n",
     DeadTarget => "$Caster\'s $Spell is wasted.\n",
     Invisible  => "$Caster\'s $Spell completely misses its invisible target ($Target)!\n",
     Countering => "The hazy glow around $Target flares as it absorbs\n".
		    " $Caster\'s Fireball.\n",
     Reflecting => "$Caster\'s $Spell reflects off the shimmering glow surrounding $Target!\n"
			);

    if ($Strings{$Action})
    {
	return $Strings{$Action}
    }

    return "Error in FM code. Please report this bug to the FM janitor.\n";
}


sub FingerofDeath
{
    local($Action) = @_;

    if ($Action eq 'Countering')
    {
        $Info{$Target}{'Dead'} += 1;

	return "$Caster\'s Death Magic penetrates the hazy glow surrounding $Target!\n$Target feels the touch of the Finger of Death...\n";
    }

    if ($Action eq 'DoSpell')
    {
        $Info{$Target}{'Dead'} += 1;

	return "$Target feels the touch of the Finger of Death...\n";
    }

    local (%Strings) = (
     NoTarget   => "$Caster\'s $Spell zaps across the circle at a non-existent target!\n",
     Blind      => "$Caster casts $Spell, trying to guess where $Target is...\n".
		   "$Caster\'s $Spell misses $Target.\n",
     DeadTarget => "$Caster\'s $Spell is wasted.\n",
     Invisible  => "$Caster\'s $Spell completely misses its invisible target ($Target)!\n",
     Reflecting => "$Caster\'s Death Magic reflects off the shimmering glow surrounding $Target!\n"
			);

    if ($Strings{$Action})
    {
	return $Strings{$Action}
    }

    return "Error in FM code. Please report this bug to the FM janitor.\n";
}


sub MagicMissile
{
    local($Action) = @_;

    my ($String) = "";

    if ($Action eq 'Reflecting')
    {
	$String = "A Magic Missile zaps across the circle towards $Target!\n";
	$String .= "The Magic Missile reflects off the shimmering glow surrounding $Target!\n";
	$InitSpell = 1;
	return $String;
    }

    if (($Action eq 'DoSpell') or ($Action eq 'Countering'))
    {
	if ($InitSpell)
	{
	    $String = "A Magic Missile zaps across the circle back to $Target!\n";
	}
	else
	{
	    $String = "A Magic Missile zaps across the circle towards $Target!\n";
	}

	$Info{$Target}{'HitByMissile'} += 1;
	return $String;
    }

    local (%Strings) = (
     NoTarget   => "$Caster\'s $Spell zaps across the circle at a non-existent target!\n",
     Blind      => "$Caster casts $Spell, trying to guess where $Target is...\n".
		   "$Caster\'s $Spell misses $Target.\n",
     DeadTarget => "$Caster\'s $Spell is wasted.\n",
     Invisible  => "$Caster\'s $Spell completely misses its invisible target ($Target)!\n"
			);

    if ($Strings{$Action})
    {
	return $Strings{$Action}
    }

    return "Error in FM code. Please report this bug to the FM janitor.\n";
}


sub CauseLightWounds
{
    local($Action) = @_;

    if ($Action eq 'DoSpell')
    {
        $Info{$Target}{'ReceivedLightWounds'} += 1;

	return "-T $Target is hit!\n";
    }

    local (%Strings) = (
     NoTarget   => "$Caster\'s $Spell zaps across the circle at a non-existent target!\n",
     Blind      => "$Caster casts $Spell, trying to guess where $Target is...\n".
		   "$Caster\'s $Spell misses $Target.\n",
     DeadTarget => "$Caster\'s $Spell is wasted.\n",
     Invisible  => "$Caster\'s $Spell completely misses its invisible target ($Target)!\n",
     Countering => "The hazy glow around $Target effortlessly absorbs\n".
		   " $Caster\'s $Spell spell.\n",
     Reflecting => "$Caster\'s $Spell reflects off the shimmering glow surrounding $Target!\n"
			);

    if ($Strings{$Action})
    {
	return $Strings{$Action}
    }

    return "Error in FM code. Please report this bug to the FM janitor.\n";
}


sub CauseHeavyWounds
{
    local($Action) = @_;

    if ($Action eq 'DoSpell')
    {
        $Info{$Target}{'ReceivedHeavyWounds'} += 1;

	return "-T $Target is hit, hard!\n";
    }

    local (%Strings) = (
     NoTarget   => "$Caster\'s $Spell zaps across the circle at a non-existent target!\n",
     Blind      => "$Caster casts $Spell, trying to guess where $Target is...\n".
		   "$Caster\'s $Spell misses $Target.\n",
     DeadTarget => "$Caster\'s $Spell is wasted.\n",
     Invisible  => "$Caster\'s $Spell completely misses its invisible target ($Target)!\n",
     Countering => "A jagged hole appears momentarily in the hazy glow surrounding $Target.\n",
     Reflecting => "$Caster\'s $Spell reflects off the shimmering glow surrounding $Target!\n"
			);

    if ($Strings{$Action})
    {
	return $Strings{$Action}
    }

    return "Error in FM code. Please report this bug to the FM janitor.\n";
}


sub CureLightWounds
{
    local($Action) = @_;

    if ($Action eq 'DoSpell')
    {
        my ($String) = '-T ';
        
        if ($Info{$Target}{'Invisible'})
        {
            $String .= "$Target starts to feel a bit better!\n";
        }
        else
        {
            $String .= "$Target starts to look a bit better!\n";
        }

        $Info{$Target}{'LightWoundsCured'} += 1;

	return $String;
    }

    local (%Strings) = (
     NoTarget   => "$Caster\'s $Spell zaps across the circle at a non-existent target!\n",
     Blind      => "$Caster casts $Spell, trying to guess where $Target is...\n".
		   "$Caster\'s $Spell misses $Target.\n",
     DeadTarget => "$Caster\'s $Spell is wasted.\n",
     Invisible  => "$Caster\'s $Spell completely misses its invisible target ($Target)!\n",
     Countering => "The hazy glow surrounding $Target thickens slightly.\n",
     Reflecting => "$Caster\'s $Spell reflects off the shimmering glow surrounding $Target!\n"
			);

    if ($Strings{$Action})
    {
	return $Strings{$Action}
    }

    return "Error in FM code. Please report this bug to the FM janitor.\n";
}


sub CureHeavyWounds
{
    local($Action) = @_;

    if ($Action eq 'DoSpell')
    {
        my ($String) = '-T ';

        if ($Info{$Target}{'Invisible'})
        {
            $String .= "$Target starts to feel much better!\n";
        }
        else
        {
            $String .= "$Target starts to look much better!\n";
        }

        $Info{$Target}{'HeavyWoundsCured'} += 1;

	return $String;
    }

    local (%Strings) = (
     NoTarget   => "$Caster\'s $Spell zaps across the circle at a non-existent target!\n",
     Blind      => "$Caster casts $Spell, trying to guess where $Target is...\n".
		   "$Caster\'s $Spell misses $Target.\n",
     DeadTarget => "$Caster\'s $Spell is wasted.\n",
     Invisible  => "$Caster\'s $Spell completely misses its invisible target ($Target)!\n",
     Countering => "The hazy glow surrounding $Target thickens and swirls.\n",
     Reflecting => "$Caster\'s $Spell reflects off the shimmering glow surrounding $Target!\n"
			);

    if ($Strings{$Action})
    {
	return $Strings{$Action}
    }

    return "Error in FM code. Please report this bug to the FM janitor.\n";
}


sub AntiSpell
{
    local($Action) = @_;

    if ($Action eq 'DoSpell')
    {
	$Info{$Target}{'Lost'} = 1;
        return "-T $Target loses the plot completely!\n";
    }

    local (%Strings) = (
     NoTarget   => "$Caster\'s $Spell zaps across the circle at a non-existent target!\n",
     Blind      => "$Caster casts $Spell, trying to guess where $Target is...\n".
		   "$Caster\'s $Spell misses $Target.\n",
     DeadTarget => "$Caster\'s $Spell is wasted.\n",
     Invisible  => "$Caster\'s $Spell completely misses its invisible target ($Target)!\n",
     Countering => "The hazy glow around $Target dims for a moment.\n",
     Reflecting => "$Caster\'s $Spell reflects off the shimmering glow surrounding $Target!\n"
			);

    if ($Strings{$Action})
    {
	return $Strings{$Action}
    }

    return "Error in FM code. Please report this bug to the FM janitor.\n";
}


sub Permanency
{
    local($Action) = @_;

    if ($Action eq 'DoSpell')
    {
        $Info{$Target}{'PermanencyPending'} = 4;

	return "-T $Target prepares to make a spell permanent!\nA blue halo appears above $Target\'s head.\n";
    }

    local (%Strings) = (
     NoTarget   => "$Caster\'s $Spell zaps across the circle at a non-existent target!\n",
     Blind      => "$Caster casts $Spell, trying to guess where $Target is...\n".
		   "$Caster\'s $Spell misses $Target.\n",
     DeadTarget => "$Caster\'s $Spell is wasted.\n",
     Invisible  => "$Caster\'s $Spell completely misses its invisible target ($Target)!\n",
     Countering => "The hazy glow surrounding $Target turns solid for a moment.\n",
     Reflecting => "$Caster\'s $Spell reflects off the shimmering glow surrounding $Target!\n"
			);

    if ($Strings{$Action})
    {
	return $Strings{$Action}
    }

    return "Error in FM code. Please report this bug to the FM janitor.\n";
}


sub DelayEffect
{
    local($Action) = @_;

    if ($Action eq 'DoSpell')
    {
	if ($Info{$Target}{'DelayPending'}>=0 && $Info{$Target}{'DelayPending'}<$duration)
	{
	    $Info{$Target}{'DelayPending'} = ($duration<4?4:$duration);
	}
	return "-T $Target prepares to bank up a spell!\n";
    }

    local (%Strings) = (
     NoTarget   => "$Caster\'s $Spell zaps across the circle at a non-existent target!\n",
     Blind      => "$Caster casts $Spell, trying to guess where $Target is...\n".
		   "$Caster\'s $Spell misses $Target.\n",
     DeadTarget => "$Caster\'s $Spell is wasted.\n",
     Invisible  => "$Caster\'s $Spell completely misses its invisible target ($Target)!\n",
     Countering => "The hazy glow surrounding $Target swallows the Delay Effect spell.\n",
     Reflecting => "$Caster\'s $Spell reflects off the shimmering glow surrounding $Target!\n"
			);

    if ($Strings{$Action})
    {
	return $Strings{$Action}
    }

    return "Error in FM code. Please report this bug to the FM janitor.\n";
}


sub FireStorm
{
    local($Action) = @_;

    if ($Action ne 'NoTarget')
    {
	return "Error in code. Contact the janitor about this bug.\n";
    }

    my ($Effect) = "$Caster calls forth a Fire Storm!\n";

    if ($FireAndIceStormExplosion) {
	$Effect .= "The storm fades in the steam.\n";
    }
    elsif ($IceStormActive)
    {
        $Effect .= "With a tremendous hissing of steam and cracking of ice, \n";
        $Effect .= "the Ice Storm and Fire Storm rage away to nothing.\n";

        $IceStormActive = 0;
        $FireAndIceStormExplosion = 1;
    }
    elsif ($FireAndIceExplosion) {
	$Effect .= "The Fire Storm is consumed in the shower of fire and ice.\n";
    }
    elsif ($IceElementalPresent)
    {
        $Effect .= "The Ice Elemental wails as it is consumed in the flames!\n";
        $Effect .= "With a tremendous hissing of steam and cracking of ice, the Fire Storm abates.\n";

	&KillBeing('IceElemental');
        $IceElementalPresent = 0;
        $FireAndIceStormExplosion = 1;
    }
    else
    {
        $FireStormActive = 1;
    }

    if ($FireElementalPresent)
    {
        $Effect .= "The FireElemental roars with delight as it surrenders itself to the storm!\n";

	&KillBeing('FireElemental');
        $FireElementalPresent = 0;
    }
    
    return $Effect;
}



sub IceStorm
{
    local($Action) = @_;

    if ($Action ne 'NoTarget')
    {
	return "Error in code. Contact the janitor about this bug.\n";
    }

    my ($Effect) = "$Caster calls forth an Ice Storm!\n";

    if ($FireAndIceStormExplosion) {
        $Effect .= "The storm fades in the steam with the others.";
    }
    elsif ($FireStormActive)
    {
        $Effect .= "With a tremendous hissing of steam and cracking of ice,\n";
        $Effect .= "the Ice Storm and Fire Storm rage away to nothing.\n";

        $FireStormActive = 0;
        $FireAndIceStormExplosion = 1;
    }
    elsif ($FireAndIceExplosion) {
	$Effect .= "The Ice Storm is consumed by the shower of fire and ice.\n";
    }
    elsif ($FireElementalPresent)
    {
        $Effect .= "The Fire Elemental howls as it is consumed by the icy wind!\n";
        $Effect .= "With a tremendous hissing of steam and cracking of ice, the Ice Storm abates.\n";

	&KillBeing('FireElemental');
        $FireElementalPresent = 0;
        $FireAndIceStormExplosion = 1;
    }
    else
    {
        $IceStormActive = 1;
    }

    if ($IceElementalPresent && $IceStormActive)
    {
        $Effect .= "The IceElemental wails with delight as it surrenders itself to the storm!\n";

	&KillBeing('IceElemental');
        $IceElementalPresent = 0;
    }

    return $Effect;
}

1;
