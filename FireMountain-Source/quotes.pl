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
#      The Original Code is quotes.pl.
#
#      The Initial Developer of the Original Code is Martin Gregory.
#
#      Contributors: Terje Bråten, John Williams.
#
#----------------------------------------------------------------------

$Revision .= " Q9.1";

sub SummonsNotification
{
    local($Challenger, $Opponent, $NewGame, $AllChallenged) = @_;

    my($WhoHas) = $AllChallenged ? "Everyone has" : "You have";

    my($Subject) = $AllChallenged ? 
	"An Open $GameType on Firetop Mountain!" : 
	    "A Summons to Battle on Firetop Mountain!";

    return "Subject: $Subject

$Opponent,

$WhoHas been challenged to a $GameType atop Firetop Mountain by

  $Challenger  (". $Wizard{$Challenger}{'User'}. ")

Please indicate your acceptance to the Referee at your soonest convenience.

(This is challenge $NewGame. Referee is $gmAddr, Subject: $RequiredSubject)

";
}


sub ChangeProposalNotification
{
    local ($Proposer, $Wizard, $NewGame, $Change) = @_;
    return "Subject: A proposed change to challenge $NewGame

$Wizard,

A new change (change no $Change) has now been proposed to the setup of
the new game $NewGame by $Proposer. Please tell the referee if you
accept or oppose this change.

";
}


sub ChangeNotification
{
    local ($Proposer, $Wizard, $NewGame) = @_;
    local ($proposal);
    if ($Proposer eq $Wizard)
    {
	$proposal = "your proposal.";
    }
    else
    {
	$proposal = "$Proposer\'s proposal.";
    }

    return "Subject: Challenge $NewGame has been changed

$Wizard,

The $gmName has changed challenge $NewGame, implementing
 $proposal

";
}


sub NoChangeNotification
{
    local ($Proposer, $Wizard, $NewGame,$Change) = @_;
    local ($proposal);
    if ($Proposer eq $Wizard)
    {
	$Proposer = "you";
    }

    return "Subject: Proposed change $Change to challenge $NewGame declined

$Wizard,

The majority of the wizards that have accpted challenge $NewGame,
do not want change no $Change proposed by $Proposer to take effect.
The $gmName drops the proposal into his magic paper basket.

";
}


sub ExcludeNotification
{
    local($Wizard, $NewGame) = @_;
    return "Subject: You have been excluded from challenge $NewGame

$Wizard,

You have had a chance to accept challenge $NewGame, but not any more.
But as this game proceeds without you, may be there is another challenge
that you may accept, or may be you should initiate one your self?

";
}

sub WithdrawalNotification
{
    local($Wizard, $Challenger, $NewGame) = @_;
    return "Subject: Challenge $NewGame withdrawn

$Wizard,

$Challenger has withdrawn challenge $NewGame to a battle
on Firetop Mountain. All mages that have shown up have
been dismissed. (You may go and sit under a menhir and relax...
... or make new a challenge yourself!)

";
}


sub AcceptNotification
{
    local ($Acceptee, $AcceptUser, $NewGame) = @_;
    return "Subject: Challenge $NewGame accepted by $Acceptee

$AcceptUser has accepted challenge $NewGame with mage $Acceptee.

";
}

sub DeclineNotification
{
    local($Whimp, $Wizard, $NewGame) = @_;
    return "Subject: The challenge has been declined!

$Wizard,

$Whimp has declined challenge $NewGame.

";
}

sub DeclineAcknowledge
{
    local($Wizard) = @_;
    return "Your opponent(s) graciously acknowlenge your decision not to face a $GameType.

You try to ignore the snickering from the sidelines as you walk away after
delivering your notice of declination...

";
}

sub ChallengeAcceptance
{
    local($Opponent, $GameName) = @_;
    if ($#Players > 1)
    {
        local @Wizlist = @Players;
        local($lastwiz) = pop(@Wizlist);
        local($wizlist) = join(', ',@Wizlist) . " and " . $lastwiz;
        return "All participants have accepted the challenge to a melee.

The melee name is '$GameName'.

$wizlist now stand around the perimeter of the large Graven Circle.

On the Referee's command, you bow, and then you may commence casting at
will...

";
    }

    return "$Opponent is ready to do battle with you, in duel name '$GameName'.

$Opponent stands before you in the Graven Circle.

On the Referees command, you bow, and then you may commence casting
at will...

";
}


sub StartNotification
{
    local($GameName) = @_;
    if ($#Players > 1)
    {
	return "Subject: A Melee has Commenced!

All participants have accepted the challenge to a melee.

The melee name is '$GameName'.

" . &JoinList(@Players) . " now stand
around the perimeter of the large Graven Circle.

On the Referee's command, you bow, and then you may commence casting at
will...

";
    }

# StartNotification is called to tell an opponent that the action of
# $Player caused a game to start.

    return "Subject: A Duel has Commenced!

$Player is ready to do battle with you, in duel name '$GameName'.

$Player stands before you in the Graven Circle.

On the Referees command, you bow, and then you may commence casting
at will...

";
}


sub DisplayNewGameState
{
    local($NewGame) = @_;
    &ReadNewGame($NewGame);

    $disp = "\nCurrent status for challenge $NewGame:\n\n".
	" This challenge is initiated by $Challenger,\n".
        " and will be using the \u$SpellBook Spell Book.\n\n";

    local (@Wizlist) = (keys %Accepted);
    if (@Wizlist==1)
    {
	$disp .= " $Challenger is patiently sitting alone in the Graven Circle,\n".
	    " and wonders if anyone else dares to show up.\n";
    }
    else
    {
	$disp .= " " . &JoinList(@Wizlist) . " are sitting\n" .
	    " in the Graven Circle, waiting for the $GameType to begin";
	if ($Auth)
	{
	    $disp .= ".\n";
	}
	else
	{
	    $disp .= "\n and occasionally negotiating the terms of the battle.\n";
	}
    }

    if ($Open)
    {
	$disp .= "\n This is an open challenge that any mage can accept";
	if (@Excluded)
	{
	    $disp .= ",\n except ". &JoinList(@Excluded) . ".\n";
	}
	else
	{
	    $disp .= ".\n";
	}
	if ($Open =~ /^\d+$/)
	{
	    my ($s) = ($Open>1)?"s":"";
	    $disp .= " (But each player may only accept this challenge with $Open mage$s.)\n";
	}
    }
    else
    {
	if (!$Challenged[0])
	{
	    $disp .= "\n The Referee is waiting to hear what is to be done with this Challenge.\n";
	}
	elsif (1==@Challenged)
	{
	    $disp .= "\n $Challenged[0] is challenged to participate in this $GameType,\n".
		" but has not showed up yet.\n";
	}
	else
	{
	    $disp .= "\n " . &JoinList(@Challenged) . " are challenged\n".
		" to participate in this $GameType, but have not showed up yet.\n"
	}
    }

    $disp .= "\n The $GameType will start " . &WhenItStarts ."\n" if $Challenged[0];

    $disp .= "\n This battle is limited to a total of ".
	"$Limit participants.\n" if $Limit;

#    $disp .= "\n There is a time limit of ".&DisplyTime($MoveTime).
#	" for each move\n" if $MoveTime;
#    $disp .= " A warning about possible timeouts are sendt after ".
#	&DisplyTime($FirstWarnTime)."\n" if $FirstWarnTime;
#    $disp .= " and then new warnings are sendt every ".
#	&DisplyTime($WarnFreq)."\n" if $WarnFreq;

    $disp .= "\n Comment: $Comment\n" if $Comment;

    if ($Auth)
    {
	$disp .= "\n Any changes to this challenge($NewGame)\n".
	    " are authoritatively made by $Challenger\n\n";
    }
    else
    {
	$disp .= "\n Any proposed changes to this challenge($NewGame)\n".
	    " are subject to a democratic process.\n";
#	    " Proposed changes that are not opposed within ".
#	    &DisplyTime($DemTime)." is considered accepted.\n\n";

	local (@Changes) = &GetChanges;
	if (@Changes)
	{
	    $disp .= "\n These changes has been proposed:\n\n";

	    local ($Change,@For,@Against,@Answers);
	    foreach $Change (@Changes)
	    {
		$disp .= &DisplayChange($NewGame,$Change) . "\n";
		@For = ();
		@Against = ();
		foreach $Mage (keys %Accepted)
		{
		    @Answers = @{$Accepted{$Mage}};
		    if ($Answers[0] eq 'all' or $Answers[$Change] eq 'yes')
		    {
			push (@For,$Mage);
		    }
		    elsif ($Answers[$Change] eq 'no')
		    {
			push (@Against,$Mage);
		    }
		}
		$disp .= "  These mages are for change $Change: " .
		          &JoinList(@For) . "\n" if @For;
		$disp .= "  These mages are against change $Change: " .
		    &JoinList(@Against) . "\n" if @Against;
		$disp .= "\n\n";
	    }
	}
    }

    return $disp;
}


sub WhenItStarts
{
    if ($Limit and ($Open or ($Limit < @Challenged + (keys %Accepted))))
    {
        local ($needed) = $Limit - (keys %Accepted);
	if ($needed==1)
	{
	    return "when an opponent has arrived." if $Limit == 2;
	    return "when one more mage has arrived.";
	}
	return "when " . $needed . " more mages have arrived.";
    }

    if (!$Open)
    {
	if (1 == @Challenged)
	{
	    return "when $Challenged[0] arrives.";
	}
	return "when they arrive.";
    }
    return "sometime in the future.";
}


#sub DisplyTime
#{
#    local ($Time) = @_;
#    local ($String);
#
#    $Time =~ m/^(\d+)([hd])/ or die "Wrong time format $Time\n";
#    $Time = $1;
#    if ($2 eq "h")
#    {
#	$String = "$Time hour";
#    }
#    else
#    {
#	$String = "$Time day";
#    }
#
#    $String .= "s" if $Time > 1;
#
#    return $String;
#}

sub DisplayChange
{
    local($NewGame,$Change) = @_;
    &ReadChange($NewGame,$Change);

    local ($disp) = "  Proposed change no $Change to challenge $NewGame:\n";

    if ($NewSpellBook)
    {
	$disp .= "   Use the $NewSpellBook Spell Book.\n";
    }

    if ($NewOpen)
    {
	if ($NewOpen eq "No")
	{
	    $disp .= "   Close the challenge, so that only those that are challenged can join.\n";
	}
	else
	{
	    $disp .= "   Make the challenge open for anyone to join";
	    if ($NewOpen =~ /^\d+$/)
	    {
		my($s) = ($NewOpen>1)?"s":"";
		$disp .= ",\n   but each player may control maximum $NewOpen mage$s.\n";
	    }
	    else
	    {
		$disp .= ".\n";
	    }
	}
    }

    if (@NewChallenged)
    {
	$disp .= "   Challenge " . &JoinList(@NewChallenged) .
	    "\n     to also participate in this $GameType.\n";
    }

    if (@NewExcluded)
    {
	$disp .= "   Exclude " . &JoinList(@NewExcluded) .
	    ".\n";
    }

    if ($StartNow)
    {
	$disp .= "   Start the game now, and exclude those that have not accepted to join yet.\n";
    }

    if ($NewLimit)
    {
	if ($NewLimit eq "No_Limit")
	{
	    $disp .= "   Do not set any limit for the total number ".
		"of participants in this battle.\n"
	}
	else
	{
	    $disp .= "   Limit this battle to a total of ".
		"$NewLimit participants.\n";
	}
    }

#    $disp .= "   Set a time limit of ".&DispTime($NewMoveTime).
#	" for each move\n" if $NewMoveTime;
#    $disp .= "     and send a warning about possible timeouts are after ".
#	&DispTime($NewFirstWarnTime)."\n" if $NewFirstWarnTime;
#    $disp .= "     and then send new warnings every ".
#	&DispTime($NewWarnFreq)."\n" if $NewWarnFreq;

    $disp .= "   New comment: $NewComment\n" if $NewComment;

    if ($NewAuth eq 'Yes')
    {
	$disp .= "   Any changes to this challenge($NewGame)".
	    " are authoritatively made by $Challenger\n";
    }
    else
    {
	if ($NewDemTime)
	{
	    $disp .= "   Any proposed changes to this challenge($NewGame)\n".
		"   are subject to a democratic prosess.\n"
#	    $disp .= "   Proposed changes that are not opposed within ".
#		    &DispTime($NewDemTime)."\n   is considered accepted.\n";
	}
    }

    $disp .= "  This change is proposed by $Proposer.\n";

    return $disp;
}

sub LastOpponentDeclined
{
    my($Player, $NewGame) = @_;

    my($qual, $changer);

    if (scalar(keys %Accepted) == 1)
    {
        my($disp) = "Subject: Challenge $NewGame declined

   Notice from the Referee regarding Challenge $NewGame:

     Your opponent has declined the challenge.  
  
     In order for the game to proceed, you need to challenge someone else!
  
     You can do this by issuing a CHANGEGAME order (or you may use the
     command WITHDRAW to withdraw this challenge and make a compeltely
     new challenge using NEWGAME).
  
     Nothing further will happen with this game until you do so.
";
    }
    else
    {
        my($disp) = "Subject: Challenge $NewGame declined

   Notice from the Referee regarding Challenge $NewGame:

     The only outstanding mage has declined the challenge.  
  
     In order for the game to proceed, a CHANGEGAME command must be
     issued telling the server what you all want to happen.
  
     One option is CHANGEGAME $NewGame (name etc) START,
     which will start the game with the existing mages.
     Another is to use CHANGEGAME to challenge someone else.
  
     Nothing further will happen with this game until the CHANGEGAME order
     is issued and approved.
";
    }
}

1;
