#----------------------------------------------------------------------
#
#  Copyright (c) Martin Gregory, 1996.  All rights reserved.
#  Copyright (c) John Williams, Terje Bråten, 1996.  All rights reserved.
#  Copyright (c) Martin Gregory, Terje Bråten, 1998.  All rights reserved.
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
#      The Original Code is lib.pl.
#
#      The Initial Developer of the Original Code is Martin Gregory.
#
#      Contributors: Terje Bråten, John Williams.
#
#----------------------------------------------------------------------

$Revision .= ' L9.24';

# The description of an opponent's state in a Game Status report...
# (any states not in this hash will appear unchanged in the report)

%StateDescription = ('orders' => 'thinking',
                     'choose-target' => 'thinking',
                     'choose-spell' => 'thinking'
                     );
sub Num
{
    if ($_[0] =~ m/(-?\d+)/)
    {
        return $1;
    }
    else
    {
        return 0;
    }
}
        

sub Rnd { # number

    return int(rand($_[0]));
}

sub Randomize {
    
    srand(time|$$);
}

&Randomize;

%Damage = ('Stab', '1',
           'Goblin', '1',
           'Ogre',   '2',
           'Troll',  '3',
           'Giant',  '4',
           'IceElemental',  '3',
           'FireElemental', '3');

sub IsNumber {
    return( $_[0] =~ /^\d+$/ );
}

sub JoinList
{
    local (@List) = @_;
    local ($list);
    $lastitem = pop(@List);
    if (@List)
    {
	$list = join(', ',@List) . " and " . $lastitem;
    }
    else
    {
	$list = $lastitem;
    }
    return $list;
}

@Colours = ('Red', 'Green', 'Pink', 'Blue', 'Orange',
            'Mauve', 'White', 'Yellow');

sub NewColour
{
    @ColoursAvail = @Colours;
    $ColourIndex = $MonstersCreated;
    $Colour = "";

    while($ColourIndex > $#ColoursAvail)
    {
        $Colour .= $ColoursAvail[$ColourIndex % $#ColoursAvail];

        splice(@ColoursAvail, $ColourIndex % $#ColoursAvail, 1);

        $Colour .= "ish";

        $ColourIndex = int($ColourIndex/$#ColoursAvail) - 1;
    }

    $Colour .= $ColoursAvail[$ColourIndex];

    return($Colour);
}

sub IsMonsterInGame
{
    local($name) = @_;

    if (&IsMonster($name))
    {
	return 1 if $name =~ m/^(R|L|B)H:/i;
	return &IsBeing($name);
    }

    return 0;
}

sub IsMonster
{
    local($name) = @_;

    if ($name !~ m/\:/)
    {
	if (($name =~ m/Goblin$/i) ||
	    ($name =~ m/Ogre$/i) ||
	    ($name =~ m/Troll$/i) ||
	    ($name =~ m/Giant$/i) ||
	    ($name =~ m/Ice *Elemental/i) ||
	    ($name =~ m/Fire *Elemental/i))
	{
	    return 1;
	}
	return 0;
    }

    if (defined(@Players))
    {
	foreach $wiz (@Players)
	{
	    next if grep(/^$wiz$/,@DeadPlayers);
	    if ( $name =~ m/^(RH|LH|BH)\:($wiz)$/i )
	    {
		return 1;
	    }
	}
    }

    return 0;
}


sub MaxHP
{
    local ($name) = @_;

    return 1 if $name =~ m/Goblin$/i;
    return 2 if $name =~ m/Ogre$/i;
    return 3 if $name =~ m/Troll$/i;
    return 4 if $name =~ m/Giant$/i;
    return 3 if $name =~ m/((Ice)|(Fire)) *Elemental/i;

    return 15;
}


sub IsLiveBeing
{
    local($name) = @_;

    if (&IsBeing($name))
    {
	return 1 unless grep (/^$name$/i, @DeadPlayers);
    }
    return 0;
}

sub IsBeing
{
    local($name) = @_;

    return 1 if grep (/^$name$/i, @Beings);
    return 0;
}


sub IsGesture
{
    return (length($_[0]) == 1) && (index($Gestures, $_[0]) >= 0);
}


sub GetName
{
    # This routine is used to return the accepted (case-wise) form of
    # any valid name from user input.
    
    my ($rawname) = @_;

    my ($lowname) = "\L$rawname";
    my ($b);

    # is it a being from the current game?
    foreach $i (0 .. $#Beings)
    {
        $b = "\L$Beings[$i]";
        return $Beings[$i] if ($b eq $lowname);
    }

    # is it a user?
    foreach $i (0 .. $#UserNames)
    {
	$b = "\L$UserNames[$i]";
	return $UserNames[$i] if ($b eq $lowname);
    }

    # maybe its one of the other wizards...
    foreach $i (0 .. $#WizardNames)
    {
        $b = "\L$WizardNames[$i]";
        return $WizardNames[$i] if ($b eq $lowname);
    }

    # is it a dead monster?
    foreach $i (0 .. $#DeadMonsters)
    {
	$b = "\L$DeadMonsters[$i]";
	return $DeadMonsters[$i] if ($b eq $lowname);
    }

    # maybe its an unborn...
    if (&IsUnborn($rawname))
    {
        local($hand, $wiz) = ($lowname, $lowname);
        $hand =~ s/(.*):(.*)/$1/;
        $hand = "\U$hand";
        $wiz =~ s/(.*):(.*)/$2/;
        $wiz = &GetName($wiz);
        return "$hand:$wiz";
    }

    # Can't recognise it, so it must be either a new name or garbage.
    # If it's a new name, it must be capitalised for use later...
    
    return "\u$rawname";
}


%RevHandMap = ('RH', 'the right hand',
	       'LH', 'the left hand',
	       'BH', 'both hands',
	       'FIRE', 'a banked spell');


sub BeingDescription
{
    local($Being) = @_;
    local($wiz, $hand);

    if ($Being =~ /(.+):(.+)/)
    {
	$hand = $RevHandMap{&Upcase($1)};
	$wiz = &GetName($2);
	if(not $hand)
	{
	    $hand=$1;  # Messy message results from bogus input.
	}
	$Being = "the monster $wiz is summoning with $hand";
    }

    if ($Being eq "no_one")
    {
	$Being = "no one";
    }

    return $Being;
}


sub GetSpellName
{
    local($rawname) = @_;
    my ($i,$n);

    $rawname = "\L$rawname";
    $rawname =~ tr/ -//d; #Make spaces and hypens redundant

    foreach $i (values(%SpellBook))
    {
        # spellsbook now contains lists of spells so:
        foreach $spell (@{$i}) {
            $n = "\L$spell";
            $n =~ tr/ -//d;
            return $spell if ($n eq $rawname);
        }
    }
                
    return 'none';
}


sub GetWizards
{
    open(WIZARDS, "wizards.dat") or die "Can't read wizards.dat: $!";

    @WizardInfo = <WIZARDS>;

    close WIZARDS;

    eval "@WizardInfo";

    @WizardNames = keys %Wizard;

    die $@ if $@;
}


sub WriteWizards
{
    # first get rid of Dead wizards
    my (@Wizs) = @WizardNames;

    my $Wiz;
    foreach $Wiz (@Wizs)
    {
	if ($Wizard{$Wiz}{'Dead'})
	{
	    delete $Wizard{$Wiz};
	    &DeleteStat('WizActive', $Wiz);
	    @WizardNames = grep($Wiz ne $_, @WizardNames);
	}
    }

    # Get rid of 'fakes'.  These happen where code like 
    # if (!$Wizards{$Name}{$User}) is done to determine if the wizard
    # exists.  This is not good code because it makes perl create an
    # empty entry for $Wizard{$Name}, if there was not one.  This type
    # of not-so-good code exists because it used to be 
    # if (!$Wizards{"$Name.$User"}) back in the Perl 4 days, and was
    # 'automatically' converted.  It's too hard to find all the bad
    # places...

    foreach $Wiz (keys %Wizard)
    {
	delete $Wizard{$Wiz} if (!keys(%{$Wizard{$Wiz}}));
    }

    # Now write the data...

    open(WIZARDS, ">wizards.dat") or 
	die "Couldn't write wizards.dat: $!, stopped";
    
    print WIZARDS Data::Dumper->Dump([\%Wizard],
				     ['*Wizard']);
    
    close WIZARDS or 
	die "Couldn't write wizards.dat: $!, stopped";
}


sub TakeWizOutOfGame
{
    # This is either a death, a surrender or a nag termination.

    my($Victim) = @_;

    push(@DeadPlayers, $Victim);

    if ($Info{$Victim}{'HP'} > 0)
    {
	# A surrender.  Can't free them from the game, since that would
	# make them vulnerable to the nagger... then we'd loose their
	# %Wizard entry (and maybe even their %Users entry) which
	# is not safe.

	$Info{$Victim}{'State'} = 'OUT';
    }
    else
    {
	$Info{$Victim}{'State'} = 'Dead';
    }

# remove all enchantments
    &RemoveAllEnchantments($Victim, 1);
}

sub Penalty
{
    return if ($#_ == -1);
    local(@Losers) = @_;

    local @sameaddr = ();
    foreach $wiz (@Players)
    {
        if ( &SamePlayer($wiz,$Players[0]) )
	{
	    push(@sameaddr,$wiz);
	}
    }
    if ($#sameaddr != $#Players)
    {
	# There was more than one real player, so it wasn't a practice game!
	foreach $Loser (@Losers)
	{
            $Wizard{$Loser}{$GameType.'Score'} -= 1;
            if ($Wizard{$Loser}{$GameType.'Score'} < 0)
            {
                $Wizard{$Loser}{$GameType.'Score'} = 0;
            }
	}
    }
}

%BeingInfoFields = ( # field name, and default value
                    'Afraid', '0',
                    'BHDuration', '1',
                    'BHSave', '0',
                    'FireDuration', '1',
                    'FireSpell', 'none',
                    'FireTarget', 'none',
                    'Blind', '0',
                    'BlindTurns', '0',
                    'BothSpell', 'none',
                    'BothTarget', 'none',
                    'Charmed', '0',
                    'CharmedRight', '0',
                    'CharmedLeft', '0',
                    'ColdResistant', '0',
                    'Confused', '0',
                    'Controller', 'no_one',
                    'Countering', '0',
                    'Dead', '0',
                    'DelayPending', '0',
                    'Fast', '0',
                    'Forgetful', '0',
                    'HastenedTurn', '0',
                    'HP', '15',
                    'HeatResistant', '0',
                    'HeavyWoundsCured', '0',
                    'HitByFireBall', '0',
                    'HitByLightning', '0',
                    'HitByMissile', '0',
                    'Invisible', '0',
                    'InvisibleTurns', '0',
		    'LastGestureLH', 'B',
		    'LastGestureRH', 'B',
                    'LH', 'B',
                    'LHDuration', '1',
                    'LHSave', '0',
                    'LeftSpell', 'none',
                    'LeftTarget', 'none',
                    'LightWoundsCured', '0',
                    'Name', 'nobody',
                    'Paralyzed', '0',
                    'Paralyser', 'no_one',
                    'ParalyzedLeft', '0',
                    'ParalyzedRight', '0',
                    'PermanencyPending', '0',
                    'Poisoned', '0',
                    'Quote', 'none',
                    'RH', 'B',
                    'RHDuration', '1',
                    'RHSave', '0',
                    'ReceivedHeavyWounds', '0',
                    'ReceivedLightWounds', '0',
                    'Reflecting', '0',
                    'RightSpell', 'B',
                    'RightTarget', 'none',
                    'SavedSpell', 'none',
                    'SavedTarget', 'none',
                    'Shielded', '0',
                    'ShortLightningUsed', '0',
                    'Sick', '0',
                    'State', 'orders',
                    'Surrendered', '0',
                    'Target', 'no_one',
                    'TimeStopped', '0',
                    'TimeStoppedTurn', '0');

sub CreateGame
{
    # This routine sets up a pile of global variables including
    # %Info, @Players, @DeadPlayers, @DeadMonsters and $Turn.

    local @Wizzes = @_;
    local($GameName) = shift(@Wizzes);
    @Players = @Wizzes;

    %Info = ();  # New game!
    @Beings = ();
    @DeadPlayers = ();
    @DeadMonsters = ();

    $Turn = 1;
    $SequenceNumber = 1;
    $MonstersCreated = 0;
    $GesturesDone = 0;
    $ColourSeed = &Rnd($#Colours);

    for (1..$ColourSeed)
    {
        push(@Colours, shift(@Colours));
    }
    
    print LOG "New Game: $GameName\n";
    
    foreach $wiz (@Wizzes)
    {
        push(@Beings, $wiz);
        
        foreach $field (keys %BeingInfoFields)
        {
            if ($field ne 'Name')
            {
                $Info{$wiz}{$field} = $BeingInfoFields{$field};
            }
            else
            {
                $Info{$wiz}{$field} = $wiz;
            }
        }
    }

    &StartHistory(@Wizzes);

    &StartDescription(@Wizzes);
}

sub GetGameInfo
{
    # This routine sets up a pile of global variables including
    # %Info, @Players, @DeadPlayers, @DeadMonsters and $Turn.

    my($Game, $Player, $File) = @_;

    if (!$File)
    {
	$File = "$Game.gm";
    }
    if (!open(GAME, $File))
    {
#	print STDERR "Could not open game file $File\n$!\n";
	return 0;
    }

    print LOG "Reading $Game\n";

    my(@Game) = <GAME>;

    eval "@Game";

    die $@ if $@;

    # %SpellBook is now stored directly in the game file to support custom
	 # spellbooks
    # %SpellBook = %{$SpellBooks{"\u$SpellBook"}};

    $GameType = (@Players == 2) ? "Duel" : "Melee";
    
    for (1..$ColourSeed)
    {
        push(@Colours, shift(@Colours));
    }

    return 1 if ($Player eq 'no_one');
    return grep($Player eq $_, @Players);
}


sub WriteGameInfo
{
    my($Game) = @_;
    
    open(GAME, ">$Game.gm") or die "Can't write $Game.gm: $! ";

    print LOG "Saving $Game $SequenceNumber\n";

    print GAME Data::Dumper->Dump([$Turn, 
				   $SequenceNumber, 
				   $MonstersCreated,
				   $ColourSeed,
				   $GesturesDone,
				   $IceElementalPresent,
				   $FireElementalPresent,
					$SpellBookName,
				   \%SpellBook,
				   \@Players,
				   \@Subscribers,
				   \@DeadPlayers,
				   \@DeadMonsters,
				   \@Beings,
				   \%Info],
				  ['Turn', 
				   'SequenceNumber', 
				   'MonstersCreated',
				   'ColourSeed',
				   'GesturesDone',
				   'IceElementalPresent',
				   'FireElementalPresent',
					'SpellBookName',
				   '*SpellBook',
				   '*Players',
				   '*Subscribers',
				   '*DeadPlayers',
				   '*DeadMonsters',
				   '*Beings',
				   '*Info']);

    close GAME or die "Can't write $Game.gm: $! ";
    
    return 1;
}

sub NewName
{
    local ($NameFile) = @_;

    open(NAMES, "<$NameFile") || die "Could not open $NameFile\n$!";

    local($NewNumber) = <NAMES>;

    close NAMES;

    chomp ($NewNumber);

    $NewNumber++;

    if ($NameFile !~ m/\bChange/)
    {
	opendir (DIR,$SaveDir) || die $! ;
	local (@Files) = readdir (DIR);
	closedir DIR;

	while (grep /^$NewNumber/,@Files)
	{
	    $NewNumber++;
	}
    }

    open(NAMES, ">$NameFile") || die $!;
    print NAMES "$NewNumber\n";
    close NAMES;
        
    return $NewNumber;
}

%SpellBooks = ("Empty" => {},
          "Standard" =>
	       {"cDPW",   ["Dispel Magic"],
		"cSWWS",  ["Summon Ice Elemental"],
		"cWSSW",  ["Summon Fire Elemental"],
		"cw",     ["Magic Mirror"],
		"DFFDD",  ["Lightning Bolt"],
		"DFPW",   ["Cure Heavy Wounds"],
		"DFW",    ["Cure Light Wounds"],
		"DPP",    ["Amnesia"],
		"DSF",    ["Confusion"],
		"DSFFFc", ["Disease"],
		"DWFFd",  ["Blindness"],
		"DWSSSP", ["Delay Effect"],
		"DWWFWc", ["Raise Dead"],
		"DWWFWD", ["Poison"],
		"FFF",    ["Paralysis"],
		"FPSFW",  ["Summon Troll"],
		"FSSDD",  ["Fireball"],
		"P",      ["Shield"],
		"PDWP",   ["Remove Enchantment"],
		"PPws",   ["Invisibility"],
		"PSDD",   ["Charm Monster"],
		"PSDF",   ["Charm Person"],
		"PSFW",   ["Summon Ogre"],
		"PWPFSSSD", ["Finger of Death"],
		"PWPWWc", ["Haste"],
		"SD",     ["Magic Missile"],
		"SFW",    ["Summon Goblin"],
		"SPFP",   ["Anti Spell"],
		"SPFPSDW",["Permanency"],
		"SPPc",   ["Time Stop"],
		"SPPFD",  ["Time Stop"],
		"SSFP",   ["Resist Cold"],
		"SWD",    ["Fear"],
		"SWWc",   ["Fire Storm"],
		"WDDc",   ["Short Lightning Bolt"],
		"WFP",    ["Cause Light Wounds"],
		"WFPSFW", ["Summon Giant"],
		"WPFD",   ["Cause Heavy Wounds"],
		"WPP",    ["Counter Spell"],
		"WSSc",   ["Ice Storm"],
		"WWFP",   ["Resist Heat"],
		"WWP",    ["Protection"],
		"WWS",    ["Counter Spell"]},
	       "Classic" =>
	       {"cDPW",   ["Dispel Magic"],
		"cSWWS",  ["Summon Ice Elemental"],
		"cSWPP",  ["Summon Fire Elemental"],
		"cw",     ["Magic Mirror"],
		"DFFDD",  ["Lightning Bolt"],
		"DFPW",   ["Cure Heavy Wounds"],
		"DFW",    ["Cure Light Wounds"],
		"DPP",    ["Amnesia"],
		"DSF",    ["Confusion"],
		"DSFFFc", ["Disease"],
		"DWFFd",  ["Blindness"],
		"DWSSSP", ["Delay Effect"],
		"DWWFWc", ["Raise Dead"],
		"DWWFWD", ["Poison"],
		"FFF",    ["Paralysis"],
		"FPSFW",  ["Summon Troll"],
		"FSSDD",  ["Fireball"],
		"P",      ["Shield"],
		"PDWP",   ["Remove Enchantment"],
		"PPws",   ["Invisibility"],
		"PSDD",   ["Charm Monster"],
		"PSDF",   ["Charm Person"],
		"PSFW",   ["Summon Ogre"],
		"PWPFSSSD", ["Finger of Death"],
		"PWPWWc", ["Haste"],
		"SD",     ["Magic Missile"],
		"SFW",    ["Summon Goblin"],
		"SPFP",    ["Anti Spell"],
		"SPFPSDW",["Permanency"],
		"SPPc",   ["Time Stop"],
		"SSFP",   ["Resist Cold"],
		"SWD",    ["Fear"],
		"SWWc",   ["Fire Storm"],
		"WDDc",   ["Short Lightning Bolt"],
		"WFP",    ["Cause Light Wounds"],
		"WFPSFW", ["Summon Giant"],
		"WPFD",   ["Cause Heavy Wounds"],
		"WPP",    ["Counter Spell"],
		"WSSc",   ["Ice Storm"],
		"WWFP",   ["Resist Heat"],
		"WWP",    ["Protection"],
		"WWS",    ["Counter Spell"]},
               "NoMonster" =>
	       {"cDPW",   ["Dispel Magic"],
		"cSWWS",  ["Summon Ice Elemental"],
		"cWSSW",  ["Summon Fire Elemental"],
		"cw",     ["Magic Mirror"],
		"DFFDD",  ["Lightning Bolt"],
		"DFPW",   ["Cure Heavy Wounds"],
		"DFW",    ["Cure Light Wounds"],
		"DPP",    ["Amnesia"],
		"DSF",    ["Confusion"],
		"DSFFFc", ["Disease"],
		"DWFFd",  ["Blindness"],
		"DWSSSP", ["Delay Effect"],
		"DWWFWc", ["Raise Dead"],
		"DWWFWD", ["Poison"],
		"FFF",    ["Paralysis"],
		"FSSDD",  ["Fireball"],
		"P",      ["Shield"],
		"PDWP",   ["Remove Enchantment"],
		"PPws",   ["Invisibility"],
		"PSDF",   ["Charm Person"],
		"PWPFSSSD", ["Finger of Death"],
		"PWPWWc", ["Haste"],
		"SD",     ["Magic Missile"],
		"SPFP",   ["Anti Spell"],
		"SPFPSDW",["Permanency"],
		"SPPc",   ["Time Stop"],
		"SPPFD",  ["Time Stop"],
		"SSFP",   ["Resist Cold"],
		"SWD",    ["Fear"],
		"SWWc",   ["Fire Storm"],
		"WDDc",   ["Short Lightning Bolt"],
		"WFP",    ["Cause Light Wounds"],
		"WPFD",   ["Cause Heavy Wounds"],
		"WPP",    ["Counter Spell"],
		"WSSc",   ["Ice Storm"],
		"WWFP",   ["Resist Heat"],
		"WWP",    ["Protection"],
		"WWS",    ["Counter Spell"]}
	       );


%TargetSelf = ("Dispel Magic", '1',
               "Magic Mirror", '1',
               "Lightning Bolt", '0',
               "Short Lightning Bolt", '0',
               "Cure Heavy Wounds", '1',
               "Cure Light Wounds", '1',
               "Delay Effect", '1',
               "Raise Dead", '1',
               "Shield", '1',
               "Invisibility", '1',
               "Haste", '1',
               "Permanency", '1',
               "Time Stop", '1',
               "Resist Cold", '1',
               "Counter Spell", '1',
               "Resist Heat", '1',
               "Protection", '1',
               "Summon Goblin", '1',
               "Summon Ogre", '1',
               "Summon Troll", '1',
               "Summon Giant", '1',
               "Summon Fire Elemental", '0',
               "Summon Ice Elemental", '0',
               "Paralysis", '0',
               "Amnesia", '0',
               "Fear", '0',
               "Confusion", '0',
               "Charm Monster", '1',
               "Charm Person", '0',
               "Disease", '0',
               "Poison", '0',
               "Blindness", '0',
               "Remove Enchantment", '0',
               "LightningBolt", '0',
               "ShortLightningBolt", '0',
               "Fireball", '0',
               "Finger of Death", '0',
               "Magic Missile", '0',
               "Cause Light Wounds", '0',
               "Cause Heavy Wounds", '0',
               "Anti Spell", '0',
               "Fire Storm", '0',
               "Ice Storm", '0'
               );

sub SelfTarget
{
    local($spellname) = @_;

    return($TargetSelf{$spellname});
}

%UntargettedSpell = ( "Summon Ice Elemental", '1',
                      "Summon Fire Elemental", '1',
                      "Fire Storm", '1',
                      "Ice Storm", '1'
                     );

sub UntargettedSpell
{
    return $UntargettedSpell{$_[0]};
}

sub CheckForCastRight
{
    local($Right, $Left, $Caster) = @_;

    my @Spells = ();

#debug    print "CFC: $Right $Left\n";
    foreach $sequence (keys %SpellBook)
    {
#debug        print "Seq: $sequence $SpellBook{$sequence}\n";
#debug        print "rh...\n";

        $o = 0;
        for $i (1 .. length($sequence))
        {
            $SpellMatch = 0;
            $NextPart = substr($sequence, -$i, 1);
#debug            print "np: $NextPart\n";
            $o += 1 while (substr($Right, -($i + $o), 1) eq '.');
            last if ((&Upcase($NextPart) ne substr($Right, -($i+$o), 1)) ||
                     (&IsLower($NextPart) &&
                      (($i == 1) || 
                       (&Upcase($NextPart) ne substr($Left, -($i+$o), 1)))));
#debug            print "match\n";
            $SpellMatch = 1;    
        }

        if ($SpellMatch) {
            $SpellDesc  = $SpellBook{$sequence};
            if ($Info{$Caster}{'ShortLightningUsed'}) {
                @SpellDesc = grep (!/^Short Lightning Bolt$/, @{$SpellDesc});
	    } else {
                @SpellDesc = @{$SpellDesc};
	    }
#debug            print "whole match\n";

            push(@Spells, @SpellDesc);
        }
    }
    
    return @Spells;
}

sub CheckForCastBoth
{
    local($Right, $Left, $Caster) = @_;

    my @Spells = ();

#debug    print "CFC(B):\n";
    foreach $sequence (keys %SpellBook)
    {
#debug        print "Seq: $sequence $SpellBook{$sequence}\n";
#debug        print "bh..\n";
        
        $o = 0;
        for $i (1 .. length($sequence))
        {
            $SpellMatch = 0;
            $NextPart = substr($sequence, -$i, 1);
#debug            print "np: $NextPart\n";
            $o += 1 while (substr($Right, -($i + $o), 1) eq '.');
            last if ((($i == 1) && !&IsLower($NextPart)) ||
                     (&Upcase($NextPart) ne substr($Right, -($i+$o), 1)) ||
                     (&IsLower($NextPart) &&
                      (&Upcase($NextPart) ne substr($Left, -($i+$o), 1))));
#debug            print "match\n";
            $SpellMatch = 1;    
        }

        if (!$SpellMatch)
        {
#debug            print "(other hand perhaps?)\n";
            $o = 0;
            for $i (1 .. length($sequence))
            {
                $SpellMatch = 0;
                $NextPart = substr($sequence, -$i, 1);
#debug                print "np: $NextPart\n"; 
                $o += 1 while (substr($Left, -($i + $o), 1) eq '.');
                last if ((($i == 1) && !&IsLower($NextPart)) ||
                         (&Upcase($NextPart) ne substr($Left, -($i+$o), 1)) ||
                         (&IsLower($NextPart) &&
                          (&Upcase($NextPart) ne substr($Right, -($i+$o),1))));
#debug                print "match\n";
                    $SpellMatch = 1;    
            }
        }

        if ($SpellMatch) {
            $SpellDesc  = $SpellBook{$sequence};
            if ($Info{$Caster}{'ShortLightningUsed'}) {
                @SpellDesc = grep (!/^Short Lightning Bolt$/, @{$SpellDesc});
	    } else {
                @SpellDesc = @{$SpellDesc};
	    }
#debug            print "whole match\n";

            push(@Spells, @SpellDesc);
        }
    }
    
    return @Spells;
}

sub CheckForCastLeft
{
    local($Right, $Left, $Caster) = @_;

    my @Spells = ();

#debug    print "CFC(L): R>$Right<  L>$Left<\n";

    foreach $sequence (keys %SpellBook)
    {
#debug        print "Seq: $sequence $SpellBook{$sequence}\n";
#debug        print "lh...\n";
            
        $o = 0;
        for $i (1 .. length($sequence))
        {
            $SpellMatch = 0;
            $NextPart = substr($sequence, -$i, 1);
#debug            print "np: $NextPart\n";
            $o += 1 while (substr($Right, -($i + $o), 1) eq '.');
            last if ((&Upcase($NextPart) ne substr($Left, -($i+$o), 1)) ||
                     (&IsLower($NextPart) &&
                      (($i == 1) ||
                       (&Upcase($NextPart) ne substr($Right, -($i+$o), 1)))));
#debug            print "match\n";
            $SpellMatch = 1;    
        }

        if ($SpellMatch) {
            $SpellDesc  = $SpellBook{$sequence};
            if ($Info{$Caster}{'ShortLightningUsed'}) {
                @SpellDesc = grep (!/^Short Lightning Bolt$/, @{$SpellDesc});
	    } else {
                @SpellDesc = @{$SpellDesc};
	    }
#debug            print "whole match\n";

            push(@Spells, @SpellDesc);
        }
    }
    
    return @Spells;
}


sub Upcase
{
    return "\U$_[0]";
}

sub IsLower
{
    return ($_[0] =~ m/^[a-z]+$/);
}

sub GameStatus
{
    my (@Receivers) = @_;
    my ($UserReceiver,$Receiver,$BlindMage,$Blind, %BlindTurns)
	= ('no_one',"","",0);

    if (!$FinishGame)
    {
	if (@Receivers)
	{
	    $Status = "\u$SpellBookName $GameType Status for ".
		&JoinList(@Receivers)." (game $GameName, turn $Turn):\n";
	    $UserReceiver = $Wizard{$Receivers[0]}{'User'};

	    # If any of the Receivers is not blind this turn, then this User
	    # gets to see the report for that turn
	    # (IE is effectively not Blind)
	    for ($i=0;$i<length($Info{$Receivers[0]}{'BlindTurns'});$i++)
	    {
		$Blind=1;
		foreach $Receiver (@Receivers)
		{
		    if (!substr($Info{$Receiver}{'BlindTurns'}, $i, 1))
		    {
			$Blind = 0;
		    }
		}
		$BlindTurns{$i} = 'no_one' if $Blind;
	    }

	    $Blind=1;
	    foreach $Receiver (@Receivers)
	    {
		if (!$Info{$Receiver}{'Blind'})
		{
		    $Blind = 0;
		}
	    }
	}
	else
	{
	    # No recivers, generating a report for spectators.
	    $Status = "\u$SpellBookName $GameType Status (game $GameName, turn $Turn):\n";
	    for ($i=0;$i<length($Info{$Players[0]}{'BlindTurns'});$i++)
	    {
		$Blind=0;
		foreach $Receiver (@Players)
		{
		    if (substr($Info{$Receiver}{'BlindTurns'}, $i, 1))
		    {
			if (!$Blind)
			{
			    $Blind = 1;
			    $BlindTurns{$i} = $Receiver;
			}
			else
			{
			    $BlindTurns{$i} = "no_one";
			}
		    }
		}
	    }

	    $Blind=0;
	    foreach $Receiver (@Players)
	    {
		if ($Info{$Receiver}{'Blind'})
		{
		    if (!$Blind)
		    {
			$Blind = 1;
			# Only one blind mage
			$BlindMage = $Receiver;
		    }
		    else
		    {
			$BlindMage = "";
		    }
		}
	    }
	}
    }
    else
    {
	$Status="";
	$Blind = 0;
    }

    my %orderof = ( 'OUT' => 1, 'Dead' => 2 );
    my ($NoSee, $Left, $Right);
    foreach $being (map { $_->[0] }
        sort { $a->[1] <=> $b->[1]
            || $a->[2] cmp $b->[2]
            || $a->[3] cmp $b->[3] }
        map { [ $_,
            $orderof{$Info{$_}{'State'}} || 0,
            &IsMonster($_) ? chr(0xff) : $Wizard{$_}{'User'},
            $Info{$_}{'Name'} ] } @Beings)
    {
	next if $Blind && &IsMonster($being);

        $Status .= "\n $Info{$being}{'Name'} ";
	$Status .= "($Wizard{$being}{User}) " if (!&IsMonster($being));
	$Status .= "HP: ";

	$NoSee = 0;
	if ($Blind)
	{
	    if (!@Receivers)
	    {
		if ($being ne $BlindMage)
		{
		    $NoSee = 1;
		}
	    }
	    elsif (!grep($being eq $_, @Receivers))
	    {
		$NoSee = 1;
	    }
	}

	if ($NoSee)
	{
	    $Status .= "??";
	}
	else
	{
	    $Status .= "$Info{$being}{'HP'}";
	}

        if (&IsMonster($being))
        {
            $Status .= "\n";
            $extra = "";
            foreach $atr ('ColdResistant',
                          'Confused',
                          'Countering',
                          'Fast',
                          'HeatResistant',
                          'Invisible',
                          'Paralyzed',
                          'Poisoned',
                          'Reflecting',
                          'Shielded',
                          'Sick')
            {
                if ($Info{$being}{$atr})
                {
                    $Status .= "  $atr($Info{$being}{$atr}) ";
                    $extra = "\n";
                }
            }

            $Status .= $extra;

            next if $being =~ m/(Ice|Fire) ?Elemental/;
            $Status .= "  Controller: $Info{$being}{'Controller'}\n";
            $Status .= "  Target: $Info{$being}{'Target'}\n";
        }
        else
        {
            if ($StateDescription{$Info{$being}{'State'}})
            {
                $State = $StateDescription{$Info{$being}{'State'}};
                if ($Wizard{$being}{'User'} eq $UserReceiver or $FinishGame)
                {
                    $State .= " (". $Info{$being}{'State'} . ")";
                }
            }
            else
            {
                $State = $Info{$being}{'State'};
            }

            $State =~ s/_/ /;

            $Status .= " State: $State\n";

            $Status .= "  ";
	    if ($NoSee) {
		$Status .= "(You wish you could see what shape $being is in.)\n";
	    }
	    else
	    {
		$extra = "";

		foreach $atr ('Afraid',
			      'Blind',
			      'Charmed',
			      'ColdResistant',
			      'Confused',
			      'Countering',
			      'DelayPending',
			      'Fast',
			      'Forgetful',
			      'HeatResistant',
			      'Invisible',
			      'Paralyzed',
			      'PermanencyPending',
			      'Poisoned',
			      'Reflecting',
			      'Shielded',
			      'Sick',
			      'TimeStoppedTurn')
		{
		    if ($Info{$being}{$atr})
		    {
			$Status .= "$atr($Info{$being}{$atr}) ";
			$extra = "\n";
		    }
		}

		$Status .= $extra."\n";

		if ($Info{$being}{'SavedSpell'} ne 'none')
		{
		    $Status .= "  SavedSpell: ". $Info{$being}{'SavedSpell'};
		    $Status .= " at ". $Info{$being}{'SavedTarget'};
		    $Status .= "\n\n";
		}
	    }

            if ($Info{$being}{'State'} eq 'orders' or
		$Info{$being}{'State'} eq 'Dead' or
		$Info{$being}{'State'} eq 'OUT' or $FinishGame)
            {
                $Amount = length($Info{$being}{'RH'});
            }
            else 
            {   # They must have submitted gestures for this turn
		#  ... don't show those yet....
                $Amount = length($Info{$being}{'RH'}) - 1;
            }

	    $Left = "";
	    $Right = "";
            if (!$FinishGame && $Amount > 60) {
                $Left = $Right = "...";
            }
            for $i (0 .. $Amount-1)
            {
                next if !$FinishGame && $Amount - $i > 60;
                if ( $FinishGame ||
                    ($Wizard{$being}{'User'} eq $UserReceiver) ||
                    (substr($Info{$being}{'LH'}, $i, 1) eq '.') ||
                    (
		      (!$BlindTurns{$i} || $BlindTurns{$i} eq $being) &&
		      !substr($Info{$being}{'InvisibleTurns'}, $i, 1)
		    )
		   )
                {
                    $Left .= substr($Info{$being}{'LH'}, $i, 1);
                    $Right .= substr($Info{$being}{'RH'}, $i, 1);
                }
                else
                {
                    $Left .= "?";
                    $Right .= "?";
                }
            }
	    $Status .= "  Left:  $Left\n  Right: $Right\n";
        }
    }

    return $Status if $Blind;

    $Status .= "\n A magical tombstone shaped like a monster is standing in a corner.\n";
    if (!@DeadMonsters)
    {
	$Status .= " It has no inscriptions on it.\n";
    }
    else
    {
	if (@DeadMonsters==1)
	{
	    $Status .= " There is one name engraved into it:\n\n";
	}
	else
	{
	    $Status .= " The following names are engraved into it:\n\n";
	}
	my ($dead);
	foreach $dead (@DeadMonsters)
	{
	    $Status .= "     $dead\n";
	}
    }

    return $Status;
}


sub SamePlayer
{
    local ($wiz1,$wiz2) = @_;
    if (!$Wizard{$wiz1}{'User'} or !$Wizard{$wiz2}{'User'})
    {
	return 0;
    }
    if ($Wizard{$wiz1}{'User'} eq $Wizard{$wiz2}{'User'})
    {
	return 'Yes';
    }
    return 0;
}


sub Min
{
    return(($_[0] > $_[1]) ? $_[1] : $_[0]);
}

sub LastGesture
{
    #This sub. finds the last char in any string that is not a '.' or '#'

    local ($String) = @_;
    my ($o,$c);
    $o=1;
    $o += 1 while
	($c=substr($String, -$o, 1)) eq '.' or $c eq '#';
    return $c;
}

@NoEVerbs = ('wish', 'do', 'flinch');   # eg flinches -> flinch .. no 2nd person "e".

sub SecondPerson
{
    # Note: this routine deals with deciding whether the second person pronoun 
    # should be capitalised by whether it is at the beginning of a line or not
    # (sentences that know that they are continuing onto a new line with a name
    #  leave a space at the beginning of the line).

    local($String, $Person) = @_;

    while ($String =~ s/^(\w+) says ([^\n]*(\n [^\n]*)*)$/$1-Quote-place-holder/m)
    {
	$Quote{$1} = $2;
    }

    $String =~ s/ at RH:(.+)\b/, anticipating a monster from $1\'s right spell/g;
    $String =~ s/ at LH:(.+)\b/, anticipating a monster from $1\'s left spell/g;

    local($Own) = $Person."'s";

    $String =~ s/^$Own\b/Your/gm;
    $String =~ s/\b$Own\b/your/g;

    # First substitute some places where the person is not
    # the subject in the sentence
    $String =~ s/around $Person\b/around you/g;
    $String =~ s/surrounding $Person\b/surrounding you/g;
    $String =~ s/of (the )$Person\b/of ${1}you/g;
    $String =~ s/towards $Person\b/towards you/g;

    # The next substitution deals with the funny construction that
    # happens when "you prepare to $GestureDesc" in process.pl,
    # because the statement is in the future tense but the
    # GestureDescs are in the present tense!
    
    $String =~ s/^$Person prepares to (\w+)s/You prepare to $1/gm;
    $String =~ s/\b$Person prepares to (\w+)s/you prepare to $1/g;

    # Now the more striaghtforward stuff... 

    $String =~ s/^$Person is\b/You are/gm;
    $String =~ s/\b$Person is\b/you are/g;

    $String =~ s/^$Person has\b/You have/gm;
    $String =~ s/\b$Person has\b/you have/g;

    $String =~ s/\b$Person casts (.*?) at $Person\b/You cast $1 at yourself/g;
    $String =~ s/\b$Person stabs $Person\b/You stab yourself/g;

    foreach $verb (@NoEVerbs)
    {
        $String =~ s/^$Person ($verb)es\b/You $1/gm;
        $String =~ s/\b$Person ($verb)es\b/you $1/g;
	# special fix for "You prepare to $GestureDesc", which gets messed up
        # if the first verb in $GestureDesc is a No E verb.
        $String =~ s/($verb)e\b/$verb/g; 
    }

    $String =~ s/^$Person (\w+)s\b/You $1/gm;
    $String =~ s/\b$Person (\w+)s\b/you $1/g;

    $String =~ s/^$Person\b/You/gm;
    $String =~ s/\b$Person\b/you/g;

    if ($Quote{$Person})
    {
	$String =~ s/^You-Quote-place-holder$/You say $Quote{$Person}/m;
    }
    while ($String =~ s/^(\w+)-Quote-place-holder$/$1 says $Quote{$1}/m)
    {}

    return $String;
}

sub Opponent
{
    local($TheThing) = @_;

    if (&IsMonster($TheThing))
    {
        return $Info{$TheThing}{'Target'};
    }

    if ($#Players == 1)
    {
        return(($TheThing eq $Players[0]) ? $Players[1] : $Players[0]);
    }

# There are a few legitimate uses of &Opponent with more than two players.
# when a goblin is created, its target will be no_one, until targetted.
# luckily it is now possible to "target lh:me you"
    if ($#Players - $#DeadPlayers > 2)
    { 
#debug        print "called Opponent routine with more than 2 players.\n";
        return 'no_one';
    }
# 2 or less surviving players
    foreach $opp (@Players)
    {
        if ($opp ne $TheThing && !grep(/^$opp$/,@DeadPlayers))
        {
            return $opp;
        }
    }
# less than two survivors
    return 'no_one';
}

sub Announce
{
    local($Announcement) = @_;

    push(@Events, $Announcement);
#debug    print "Announcing:\n$Announcement";
    foreach $wiz (@Players)
    {
	$Info{$wiz}{'SeeEvent'} .= '1';
#debug    print "$wiz: $Info{$wiz}{'SeeEvent'}\n"; 
    }
}

sub NoteThat
{
    local($TheEvent, $TheBeing) = @_;

#debug    print "\nNoting $TheEvent for $TheBeing\n"; 
    
    push(@Events, $TheEvent);

    if (&IsBeing($TheBeing))
    {
        if (&IsMonster($TheBeing))
        {
            foreach $looker (@Players)
            {
                $Info{$looker}{'SeeEvent'} .=
                    ((!$Info{$looker}{'Blind'} && 
                      !$Info{$TheBeing}{'Invisible'}) ?
                     '1' : '0');
            }
        }
        else
        {
#debug        print "$TheBeing is seeing:\n$TheEvent"; 
        
	    foreach $looker (@Players)
	    {
	        if ($looker eq $TheBeing)
	        {
		    $Info{$TheBeing}{'SeeEvent'} .= '1';
#debug          print "$TheBeing: $Info{$TheBeing}{'SeeEvent'}\n"; 
	        }
	        else
	        {
		    $Info{$looker}{'SeeEvent'} .=
		        ((!$Info{$looker}{'Blind'} &&
		          !$Info{$TheBeing}{'Invisible'} &&
		          !$Info{$TheBeing}{'TimeStoppedTurn'}) ? '1' : '0');
#debug          print "$looker: $Info{$looker}{'SeeEvent'}\n";
	        }
	    }
        }
    }
    else
    {
        foreach $looker (@Players)
        {
            $Info{$looker}{'SeeEvent'} .= !$Info{$looker}{'Blind'} || '0';
#debug      print "$looker: $Info{$looker}{'SeeEvent'}\n";  
        }
    }
}


sub CreateBeing
{
    local($ItsName, $ItsHP) = @_;

    push(@Beings, $ItsName);

    foreach $f (keys %BeingInfoFields)
    {
        $Info{$ItsName}{$f} = $BeingInfoFields{$f};
    }

    $Info{$ItsName}{'Name'} = $ItsName;
    $Info{$ItsName}{'HP'} = $ItsHP;

    $MonstersCreated++;
}

sub RemoveAllEnchantments
{
    my ($Name, $more) = @_;
    # It is nice to just have one subroutine where
    # all enchantmets are removed. It is so easy to forget one.
    # The flag more indicates that things like
    # Countering, HitByLightning, Dead, Risen, etc, should also be removed.

   ($Info{$Name}{'StruckBlind'},
    $Info{$Name}{'Disappearing'},
    $Info{$Name}{'Forgetful'},
    $Info{$Name}{'Confused'}, 
    $Info{$Name}{'Charmed'},
    $Info{$Name}{'CharmedLeft'},
    $Info{$Name}{'CharmedRight'},
    $Info{$Name}{'Paralyzed'},
    $Info{$Name}{'ParalyzedLeft'},
    $Info{$Name}{'ParalyzedRight'},
    $Info{$Name}{'Afraid'},
    $Info{$Name}{'ColdResistant'},
    $Info{$Name}{'HeatResistant'},
    $Info{$Name}{'Sick'},
    $Info{$Name}{'Poisoned'},
    $Info{$Name}{'Blind'},
    $Info{$Name}{'Invisible'},
    $Info{$Name}{'Fast'},
    $Info{$Name}{'Lost'},
    $Info{$Name}{'Shielded'},
    $Info{$Name}{'PermanencyPending'},
    $Info{$Name}{'DelayPending'},
    $Info{$Name}{'TimeStopped'},
    $Info{$Name}{'SavedSpell'},
    $Info{$Name}{'SavedTarget'})
       = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,"none","none");

    if ($more)
    {
	($Info{$Name}{'HitByLightning'},
	 $Info{$Name}{'HitByMissile'},
	 $Info{$Name}{'ReceivedLightWounds'},
	 $Info{$Name}{'ReceivedHeavyWounds'},
	 $Info{$Name}{'LightWoundsCured'},
	 $Info{$Name}{'HeavyWoundsCured'},
	 $Info{$Name}{'Countering'},
	 $Info{$Name}{'Reflecting'},
	 $Info{$Name}{'DispelShield'},
	 $Info{$Name}{'Risen'},
	 $Info{$Name}{'Dead'},
	 $Info{$Name}{'HastenedTurn'},
	 $Info{$Name}{'TimeStoppedTurn'},
	 $Info{$Name}{'Controller'})
	    = (0,0,0,0,0,0,0,0,0,0,0,0,0,"no_one");
    }
}

sub KillBeing
{
    local ($Name) = @_;
    for ($i=0;$i<@Beings;$i++)
    {
	next unless $Name eq $Beings[$i];
	splice(@Beings,$i,1);
	last;
    }

    # This is necessary because WriteGameInfo now just dumps
    # the Info stucture unconditionally, and the being might
    # be resurected by raise dead.
    &RemoveAllEnchantments($Name, 1);

    return unless IsMonster($Name);

    push (@DeadMonsters,$Name);
    if ($Name eq 'FireElemental') 
    {
	$FireElementalPresent = 0;
    }
    if ($Name eq 'IceElemental')
    {
	$IceElementalPresent = 0;
    }
}


sub ProtectEffect
{
    local($effectee) = @_;

    if ($Info{$effectee}{'Countering'})
    {
        return("hazy glow");
    }
    else
    {
        return("glimmering shield");
    }
}


sub GameList
{
    local(@Gamelist) = @_;
    my($Wiz,$state,$Games,$NextGame,$GameTurn,$desc,$line,@GameFiles,@DscFiles) = ("","","",0,0);

    opendir(GAMEDIR, ".") || die $!;
    
    if (!@Gamelist)
    {
        @GameFiles = sort {&Num($a) <=> &Num($b)} grep(/\.gm$/, readdir(GAMEDIR));
	@ShowGames = grep(s/\.gm//, @GameFiles);
    }
    else
    {
	@ShowGames = @Gamelist;
    }

    if (@ShowGames)
    {
	$Games .= "Battles in Progress on Firetop Mountain\n";
	$Games .= "---------------------------------------\n\n";

	$Games .= " Game turn              Wizard  State                  Wizard  State\n";
	$Games .= " -------------------------------------------------------------------\n\n";
    }

    while($NextGame = pop(@ShowGames))
    {
	GetGameInfo($NextGame, 'no_one') or next;

        $Games .= sprintf(" %4d  %2s  ", $NextGame, $Turn);

	my($WizCount) = 0;
	while($Wizard = shift(@Beings))
	{
	    next if (IsMonster($Wizard));
	    if (++$WizCount == 3)
	    {
		# Only two wiz's per (80 char) line
		# (yuck - what a hack...)
		$WizCount = 1;
		$Games =~ s/ ? vs $/vs\n           /;
	    }

	    if (defined($Wizard{$Wizard}{'User'})
	     && defined($Users{$Wizard{$Wizard}{'User'}}{'Vacation'})
	     && ($Users{$Wizard{$Wizard}{'User'}}{'Vacation'}))
	    {
		$State = "(on vacation)";
	    }
	    else
	    {
		$State = $Info{$Wizard}{'State'};
		if ($StateDescription{$State} and
		    $StateDescription{$State} eq 'thinking')
		{
		    $State = "";
		}
		else
		{
		    $State = "($State)";
		}
		$State =~ s/_/ /;
	    }
	    $Wizard .= "($Wizard{$Wizard}{'User'})";
	    $Games .= sprintf("%19s %-11s vs ", $Wizard, $State);
	}
	$Games =~ s/vs $/\n/;
    }

    # restore game info, if there was any

    if ($GameName and $GameName ne "NONE" and $GameName ne "NEW")
    {
	GetGameInfo($GameName, 'no_one');
    }

    if (!@Gamelist)
    {
	rewinddir(GAMEDIR);
	@DscFiles = sort {&Num($a) <=> &Num($b)} grep(/.dsc$/, readdir(GAMEDIR));
    }
    else
    {
	foreach $NextGame (@Gamelist)
	{
	    unshift (@DscFiles,"$NextGame.dsc") if !(-f "$NextGame.gm");
	}
    }
    
    if (@DscFiles)
    {
	$Games .="\n" if @GameFiles;
	$Games .= "Past History\n";
	$Games .= "------------\n\n";
    }
    
    while($NextGame = pop(@DscFiles))
    {
        $NextGame =~ m/(.*)\./;
        $Name = $1;
        if (!-f "$Name.gm")
        {
            open(DESC, "$Name.dsc") || die $!;
            chomp($desc = <DESC>);
	    $line = <DESC>; #skip ---- line
	    chomp ($line = <DESC>);
	    if ($line =~ m/Last turn/)
	    {
		$desc .= " ($line";
		chomp ($line = <DESC>);
		$desc .= "  $line)";
	    }
            $Games .= " $desc.\n";
            close DESC;
        }
    }
    
    $Games .= "\n\n";
    
    return $Games;
}

sub BusyCode 
{
    local ($wiz) = @_;
    if ($Wizard{$wiz}{'Busy'})
    {
	if ($Wizard{$wiz}{'Busy'} =~ m/^N/)
	{
	    return 1;
	}
	return 2;
    }

    return 0;
}

sub wizard_by_score
{
    if ($Wizard{$a}{$ScoreType.'Score'} != $Wizard{$b}{$ScoreType.'Score'})
    {
	return $Wizard{$b}{$ScoreType.'Score'} <=> $Wizard{$a}{$ScoreType.'Score'};
    }

    if(&BusyCode($a) != &BusyCode($b))
    {
	return &BusyCode($a) <=> &BusyCode($b);
    }

    if($Wizard{$a}{'User'} ne $Wizard{$b}{'User'})
    {
	return "\U$Wizard{$a}{'User'}" cmp "\U$Wizard{$b}{'User'}";
    }

    return "\U$a" cmp "\U$b";
}

sub dead_by_score
{
    if ($DeadScores[$a] != $DeadScores[$b])
    {
	return $DeadScores[$b] <=> $DeadScores[$a];
    }

    if ($DeadUsers[$a] ne $DeadUsers[$b])
    {
	return "\U$DeadUsers[$a]" cmp "\U$DeadUsers[$b]";
    }

    return "\U$DeadNames[$a]" cmp "\U$DeadNames[$b]";
}


sub WriteGameHistory
{
    &StartHistory(@Players) if (! -f "$GameName.hst");
        
    open(HISTORY, ">>$GameName.hst") || return;  # Cant do?  Bad luck.

    my @Wizzes = (sort(@Players));

    my @MageBlind = ();
    my $ExtraLine = 0;

    foreach $wiz (@Wizzes)
    {
	if (substr($Info{$wiz}{'BlindTurns'},-1,1)==1)
	{
	    push(@MageBlind,$wiz);
	}
    }

    my $TurnNum = $Turn;
    $TurnNum =~ s/(\D*)$//;
    printf(HISTORY "% 3u%1s:", $TurnNum, $1);

    foreach $wiz (@Wizzes)
    {
        $Hist{$wiz}{'LH'} = substr($Info{$wiz}{'LH'}, -1, 1);
        $Hist{$wiz}{'LH'} .= '*' if ($Info{$wiz}{'LeftSpell'} ne 'none' ||
                                    $Info{$wiz}{'BothSpell'} ne 'none');
        
        $Hist{$wiz}{'RH'} = substr($Info{$wiz}{'RH'}, -1, 1);
        $Hist{$wiz}{'RH'} .= '*' if ($Info{$wiz}{'RightSpell'} ne 'none' ||
                                    $Info{$wiz}{'BothSpell'} ne 'none');

        $Hist{$wiz}{'Spells'} = $Info{$wiz}{'LeftSpell'};
        $Hist{$wiz}{'Spells'} .= "+$Info{$wiz}{'RightSpell'}";
        $Hist{$wiz}{'Spells'} .= $Info{$wiz}{'BothSpell'};
        $Hist{$wiz}{'Spells'} .= "+$Info{$wiz}{'FireSpell'}";
        
        $Hist{$wiz}{'Spells'} =~ tr/+a-z / /d;
        $Hist{$wiz}{'Spells'} =~ s/^ +//;
        $Hist{$wiz}{'Spells'} =~ s/ +$//;

	$Hist{$wiz}{'ExSpell'} = "";
	if (length($Hist{$wiz}{'Spells'}) > 7)
	{
	    $ExtraLine = 1;
	    $Hist{$wiz}{'Spells'} =~ s/ (\w+)$//;
	    $Hist{$wiz}{'ExSpell'} = $1;
	}

# If two mages are blind at the same time, they should not see each other.
	$Hist{$wiz}{'Hide'} =
	    ( substr($Info{$wiz}{'InvisibleTurns'},-1,1)==1 ||
	      (($#MageBlind == 0) && $wiz ne $MageBlind[0]) ||
	      ($#MageBlind > 0) ) ?
		  '!' : '+';

        $Hist{$wiz}{'Monsters'} = "";

        foreach $mons (@Beings)
        {
            next if (!&IsMonster($mons) ||
                     $Info{$mons}{'Controller'} ne $wiz);
            $Hist{$wiz}{'Monsters'} .= "${mons}($Info{$mons}{'HP'}) ";
        }
        $Hist{$wiz}{'Monsters'} =~ tr/a-z//d;
        $Hist{$wiz}{'Monsters'} =~ s/ $//;

	$Hist{$wiz}{'ExMonsters'} = "";
	if (length($Hist{$wiz}{'Monsters'}) > 13)
	{
	    $ExtraLine = 1;
	    my ($ch, $i) = ("+", 14);
	    while ($ch ne " ")
	    {
		$i -= 1;
		$ch = substr($Hist{$wiz}{'Monsters'},$i,1);
	    }
	    $Hist{$wiz}{'ExMonsters'} = substr($Hist{$wiz}{'Monsters'},$i+1);
	    $Hist{$wiz}{'Monsters'} = substr($Hist{$wiz}{'Monsters'},0,$i);
	}

        printf(HISTORY "%s %-2s %-2s %2d %-7s %-13s :",
           $Hist{$wiz}{'Hide'},
           $Hist{$wiz}{'LH'}, $Hist{$wiz}{'RH'}, $Info{$wiz}{'HP'},
           $Hist{$wiz}{'Spells'}, 
           $Hist{$wiz}{'Monsters'});
    }

    $WildBeasts = ($#MageBlind >= 0) ? '!' : '+' ;

    foreach $mons (@Beings)
    {
        next if (!&IsMonster($mons) ||
                 $Info{$mons}{'Controller'} ne 'none');

        $WildBeasts .= "${mons}($Info{$mons}{'HP'})+";
    }
    $WildBeasts =~ tr/+a-z/ /d;

    printf(HISTORY " %s\n", $WildBeasts);

    if ($ExtraLine)
    {
	print HISTORY "    :";
    	foreach $wiz (@Wizzes)
	{
            printf(HISTORY "%s          %-7s %-13s :",
	       $Hist{$wiz}{'Hide'},
	       $Hist{$wiz}{'ExSpell'},
	       $Hist{$wiz}{'ExMonsters'});
	}
	print HISTORY "\n";
    }
    close HISTORY;
}


sub GameReport
{
    local ($HistoryFile, $GameInProgress) = @_;

    $Report = "";

    while(<$HistoryFile>)
    {
        if ($GameInProgress)
        {
            s/![^:]*:/ ?? ?? ## ??????? ?????????????:/g;
	    s/![^:\n]*$/??/;
        }

        tr/+!//d;

        $Report .= $_;
    }

    return $Report;
}

sub StartHistory
{
    local @Wizzes = @_;
    
    local @wizlist = map $_ . "($Wizard{$_}{'User'})", @Wizzes;
    local($lastwiz) = pop(@wizlist);
    local($wizlist) = join(', ',@wizlist) . " and " . $lastwiz;

    if (open(HISTORY, ">$GameName.hst"))
    {
        $Title = "Battle $GameName between $wizlist";
        print HISTORY "+$Title\n";
        print HISTORY "+" . "-" x length($Title) . "\n";
        print HISTORY "+\n";

	$Header1 = "     ";
	$Header2 = "Turn:";
	$Header3 = "-----";
        foreach $wiz (sort(@Wizzes))
        {
	    $Header1 .= sprintf("+    %-20s          :", $wiz);
	    $Header2 .= "+ LH RH HP Spells  Owned Beasts  :";
	    $Header3 .= "+---------------------------------";
        }
        $Header1 .= " Wild\n";
        $Header2 .= " Beasts\n";
        $Header3 .= "-------\n";
	print HISTORY $Header1;
	print HISTORY $Header2;
	print HISTORY $Header3;

        close HISTORY;
    }
}

sub StartDescription
{
    local @Wizzes = @_;

    local @wizlist = map $_ . "($Wizard{$_}{'User'})", @Wizzes;
    local($lastwiz) = pop(@wizlist);
    local($wizlist) = join(', ',@wizlist) . " and " . $lastwiz;

    if (open(DESC, ">$GameName.dsc"))
    {
        $Title = "Battle $GameName between $wizlist\n";
        print DESC $Title;
        print DESC "-" x (length($Title)-1);
        print DESC "\n\n";

		  print DESC "SpellBook: $SpellBookName\n";
		  if ($SpellBookName eq 'Custom')
		  {
            my $maxlength = 0;
		      foreach my $g (sort keys %SpellBook)
		      {
		          $maxlength = length($g) if (length($g) > $maxlength);
		      }
		      foreach my $g (sort keys %SpellBook)
		      {
		          print DESC "  $g", " " x ($maxlength + 2 - length ($g)), join(", ", @{$SpellBook{$g}}), "\n";
		      }
		      print DESC "\n";
		  }
        close DESC;
    }
}

sub EndDescription
{
    #Called from the ScoreGame routine
    my($Winnerlist,$s,$line);

    if (@Winners==0)
    {
	$Winnerlist = 'none';
    }
    else
    {
	$Winnerlist = &JoinList(@Winners);
    }
    if (@Winners>1)
    {
	$s="s";
    }
    else
    {
	$s="";
    }

    open (OLD, "<$GameName.dsc") || die "Cannot open $GameName.dsc\n$!";
    open (DESC, ">$GameName.dsc.new") || die "Cannot write to $GameName.dsc.new\n$!";
    $line = <OLD>; # Skip title
    print DESC $line;
    $line = <OLD>; # Skip ----- line
    print DESC $line;

    print DESC "Last turn: $Turn\n";
    print DESC "Winner$s: $Winnerlist\n";

    while (defined($line = <OLD>))
    {
	print DESC $line;
    }
    close DESC;
    close OLD;
    rename ("$GameName.dsc","$GameName.dsc.old") || die "Error renaming $GameName.dsc\n$!";
    rename ("$GameName.dsc.new","$GameName.dsc") || die "Error renaming $GameName.dsc.new\n$!";
    unlink ("$GameName.dsc.old") || die "Error unlinking $GameName.dsc.old\n$!";
}


# this is called when the game is over to compute scores
# and mark remaining dead wizards.
sub ScoreGame
{
    local @Winners = @_;
#    print "Scoring game $GameName with winners @Winners\n"; # debug!
    &EndDescription;
    $GameValue = 0;
    local @sameplr = ();
    local($num) = 0;
    local($plural) = "";
    foreach $wiz (@Players)
    {
        if (&SamePlayer($Players[0],$wiz))
	{
	    push(@sameplr,$wiz);
	}
	if ($Info{$wiz}{'HP'} <= 0)
	{
            $Wizard{$wiz}{'Dead'} = 1; 
	    open(HISTORY, ">>$GameType.history.dat") || die $! ;
	    print HISTORY "$wiz $Wizard{$wiz}{$GameType.'Score'} $Wizard{$wiz}{'User'}\n";
	    close HISTORY;

            &DeleteStat('WizActive', $wiz);
	}
	if (grep(/^$wiz$/,@Winners))
	{
	    $Info{$wiz}{'State'} = "Victorious!";
	}
	else
	{
	    $GameValue += 1;
	}
    }

    if ($#sameplr == $#Players)
    {
        &Announce("This was a practice game; no points awarded.\n");
    }
    else
    {
	foreach $wiz (@Players)
	{
	    $Users{$Wizard{$wiz}{'User'}}{"${GameType}s"}++;
	    $Wizard{$wiz}{'Battles'}++;
	}
	if ($#Players > 1 && $#Winners > -1)
	{
	    $plural = ($GameValue == 1) ? "" : "s";
            &Announce("The reward for winning the $GameType is $GameValue point$plural.\n");
	}
	if ($#Winners > 0)
	{
	    $num = $#Winners + 1;
	    $GameValue = int( $GameValue / $num );
	    $plural = ($GameValue == 1) ? "" : "s";
            &Announce("The reward is divided amongst the $num winners (rounding down).\n".
                      "Each will be awarded $GameValue point$plural.\n");
	}
	foreach $wiz (@Winners)
	{
	    $Wizard{$wiz}{$GameType.'Score'} += $GameValue;
	}
	
	# Do DuelELOs for players (duels only)
	if ($GameType eq 'Duel')
	{
	    DuelELO (@Winners);
	}
    }
}

# Update DuelELO ratings for users if a duel has just completed.
sub DuelELO
{
    local @Winners = @_;
    local $winner;
    if ($#Winners == 0)
    {
	$winner = $Winners[0];
    }
    else
    {
	$winner = "";
    }

    local $user1 = $Wizard{$Players[0]}{'User'};
    local $user2 = $Wizard{$Players[1]}{'User'};

    local $WinningUser;
    if ($winner ne "")
    {
	$WinningUser = $Wizard{$winner}{'User'};
    }
    else
    {
	$WinningUser = "";
    } 

    # If user previously had no DuelELO, initialize it to 1000
    if (!exists $Users{$user1}{'DuelELO'})
    {
	$Users{$user1}{'DuelELO'} = 1000;
    }
    if (!exists $Users{$user2}{'DuelELO'})
    {
	$Users{$user2}{'DuelELO'} = 1000;
    }

    # Update DuelELOs based on outgame of this game
    my $ELODiff = $Users{$user1}{'DuelELO'} - $Users{$user2}{'DuelELO'}; 

    my $v1;
    my $v2;

    if ($WinningUser eq "")
    {
	$v1 = 0.5;
        $v2 = 0.5;
    }
    else
    {
	$v1 = 0;
	$v2 = 0;
 	$v1 = 1 if ($WinningUser eq $user1);
 	$v2 = 1 if ($WinningUser eq $user2);
    }

    my $ELOChange1 = 40 * ($v1 - (1 / (1 + (2 ** ((-$ELODiff) / 100)))));
    my $ELOChange2 = 40 * ($v2 - (1 / (1 + (2 ** (($ELODiff) / 100)))));

    $ELOChange1 = int ($ELOChange1 * 100) / 100;
    $ELOChange2 = int ($ELOChange2 * 100) / 100;

    $Users{$user1}{'DuelELO'} += $ELOChange1; 
    $Users{$user2}{'DuelELO'} += $ELOChange2; 
}

sub FinishGame
{
    print LOG "Finishing game $GameName...\n";
    foreach my $wiz (@Players)
    {
	$Wizard{$wiz}{'Busy'} = 0;
    }
    unlink(<${GameName}.gm*>);
}


sub AllOrdersIn
{
    foreach $wiz (@Players)
    {
	next if grep(/^$wiz$/,@DeadPlayers);
	if ($Info{$wiz}{'State'} ne 'orders_in')
	{
	    return 0;
	}
    }
    return 1;
}


sub OpenMail
{
    local ($FileHandle,$Addr) = @_;
    if (!$Addr)
    {  # looks like the mage disappeared! No drama - it can happen.
	print LOG "OpenMail opening /dev/null 'cause it wasn't passed an address...\n";
	open($FileHandle, ">/dev/null") || 
	    die "Oh oh!  Couldn't write to /dev/null!! $!\n";
	return;
    }
    my ($LogName) = LogFileName($Addr);

    (system ("date >> $LogName"))/256 &&
        print STDERR  "Could not add date to $LogName\n$!\n";
    open($FileHandle, "|tee -a $LogName|$sendmail -f$gmAddr $Addr") || die "Could not open sendmail to $Addr\n$!\n";
    select((select($FileHandle), $| = 1)[0]);
    print $FileHandle "From: $gmName <$gmAddr>\n";
    print $FileHandle "To: $Addr\n";
}

sub SendEsquireMail
{
    return unless $UpdateFMUsers;
    my ($cmd, $addr) = @_;
    my ($list) = 'FM-Users';
    my ($code) = &EsquireCode($list, $addr, "\L$cmd");

    open (ESQUIRE, "|$sendmail esquire\@gamerz.net") || die "Could not open sendmail to esquire\@gamerz.net\n$!\n";
    select((select(ESQUIRE), $| = 1)[0]);
    print ESQUIRE "To: esquire\@gamerz.net\nSender: fm-users-owner\@gamerz.net\nReply-To: nobody\@gamerz.net\nSubject: Commands to esquire\n\n";

    print ESQUIRE "approve $code $cmd $list $addr\n";

    close ESQUIRE;
}

sub EsquireCode
{
    # EsquireCode($list, $address,$cmd);
    $secret="some key phrase goes here";
    my $phrase = join(":",$secret,@_);

    open MD5,"|/usr/bin/md5sum >/tmp/md5.tmp.$$";
    print MD5 $phrase;
    close MD5;

    open MD5, "/tmp/md5.tmp.$$";
    my $code = <MD5>;
    close MD5;

    unlink("/tmp/md5.tmp.$$");

    return substr($code,1,6);
}

sub LogFileName
{
    my($Address) = @_;

    my ($LogName) = "\L$Address";
    $LogName =~ s/\@.*$//;
    $LogName =~ s:/::g;
    $LogName = "$LogDir/to.$LogName.log";
    return $LogName;
}

sub OpenOpponentMail
{
    my ($wiz,$OppUser,$FileHandle);

    foreach $wiz (@Players)
    {
	if (!$Wizard{$wiz})
	{
	    die "Corrupt game file! Wizard $wiz do not exist!\n"
	}
	if ($Wizard{$wiz}{'User'} ne $User)
	{
	    if (!grep(/^$Wizard{$wiz}{'User'}$/, @OpponentUsers))
	    {
		push (@OpponentUsers, $Wizard{$wiz}{'User'})
	    }
	}
    }

    foreach $OppUser (@OpponentUsers)
    {
	$FileHandle = 'MAIL'.$OppUser;
	&OpenMail($FileHandle, $Users{$OppUser}{'Address'});
    }
}

sub CloseOpponentMail
{
    my ($OppUser,$FileHandle);
    foreach $OppUser (@OpponentUsers)
    {
	$FileHandle = 'MAIL'.$OppUser;
	close($FileHandle);
    }
}

sub PrintOpponentMail
{
    local($msg) = @_;
    my ($OppUser,$FileHandle);
    foreach $OppUser (@OpponentUsers)
    {
	$FileHandle = 'MAIL'.$OppUser;
	print $FileHandle $msg;
    }
}

sub ChooseMailHandle
{
    local($MailUser) = @_;
    if ($MailUser eq $User)
    {
	return 'MAIL';
    }
    else
    {
	return 'MAIL'.$MailUser;
    }
}


sub OnVacation
{
    my ($Duration) = @_;
    
    if (!open(VACATIONERS, "$VacationFile"))
    {
	# Couldn't open vacation file - everyone must be working!
	@Vacationers = ();
    }
    else
    {
	@Vacationers = <VACATIONERS>;
	close VACATIONERS;
    }
    
    if (!$Referee and $Duration > 7 * $AllowedVacation)
    {
	print MAIL " Sorry - we're all too jealous to allow vacations longer than $AllowedVacation weeks!\n";
	return;
    }

    if (IsNumber($Duration))
    {
	my $VacationStart = time();
	
	push (@Vacationers, "$User $Duration $VacationStart\n");
	$Users{$User}{'Vacation'} = $VacationStart + (24 * 3600 * $Duration);

	print MAIL " $User is added to the vacation file.\n";
    }
    elsif (-f $Duration)  # Referee can put game files here
    {
	push (@Vacationers, "$Duration\n");
	print MAIL "$Duration is added to the vacation file\n";
    }
    else
    {
	print MAIL " Yuk - bad argument in OnVacation! Janitor notified!\n";
	print "Bad argument in OnVaction: $Duration\n";
    }
    
    open (VACATIONERS, ">$VacationFile");
    print VACATIONERS @Vacationers;
    close VACATIONERS;
    
    print MAIL "\n";
}

sub UpdateVacationFile
{

    # Take user's name out of the vacation file, and remind
    # about active mages...

    my ($Active) = @_; # The user name.

    if (!open(VACATIONERS, "$VacationFile"))
    {
	# Couldn't open vacation file - everyone must be working!
        warn  "Hmmm - why isn't there a vacation file ($VacationFile)?\n";
	return;
    }
    else
    {
	@Vacationers = <VACATIONERS>;
	close VACATIONERS;
    }


    my ($n, $VacUser, $Duration, $Start, $Wiz) = ();

    for($n=0; $n <= $#Vacationers; $n++)
    {
	($VacUser, $Duration, $Start) = split /\s+/, $Vacationers[$n];
	next unless $Duration;

	$Users{$VacUser}{'Vacation'} = $Start + (24 * 3600 * $Duration);

	if ($VacUser eq $Active)
	{
	    print MAIL "Velcome back from vacation $Active.\n";

	    splice(@Vacationers,$n,1);
	    $Users{$Active}{'Vacation'} = 0;
	    
	    open (VACATIONERS, ">$VacationFile") ||
		warn "Gleep: couldn't write vacation file!\n";
	    print VACATIONERS @Vacationers;
	    close VACATIONERS;
	    
	    print MAIL "You have been removed from the vacation list.\n";

	    my($game,$state);
	    foreach $Wiz (&WizardsOfUser($Active,@WizardNames))
	    {
		$game = $Wizard{$Wiz}{'Busy'};
		if ($game and $game !~ s/^N//)
		{
		    &GetGameInfo($game,$Wiz); #Get %Info and $Turn
		    $state = $Info{$Wiz}{'State'};
		    if ($StateDescription{$state})
		    {
			print MAIL " Your wizard $Wiz is awaiting your orders in game $Wizard{$Wiz}{'Busy'}.\n" .
			    "     (State: $state     Turn: $Turn)\n";
		    }
		}
	    }
	    print MAIL "\n";
	    
	    # restore the correct game info, if we messed it up above.
	    if ($game ne $GameName && $GameName ne 'NONE') 
	    {
		&GetGameInfo($GameName, $Active);
	    }
	}
    }
}

sub NoteActivity
{
    # Record the fact that the wizard has succesfully done something
    # in this game...

    my($wiz) = @_;

    &SetStat('WizActive', $wiz, time());
    &SetStat('UserActive', $Wizard{$wiz}{'User'}, time());
}

1;
