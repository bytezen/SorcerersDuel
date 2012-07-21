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
#      The Original Code is users.pl.
#
#      The Initial Developer of the Original Code is Terje Bråten.
#
#      Contributors: Martin Gregory.
#
#----------------------------------------------------------------------

$Revision .= " U9.5";

sub CreateUser
{
    my ($NewUser,$Password,$Address) = @_;

    if ('Referee' eq $NewUser)
    {
	print MAIL "$h You are NOT the referee, I am!\n\n";
	print MAIL "As you are thrown head first down the mountain,\n" .
	    "you hear the old $gmName grumble to himself\n" .
		"\"New users now days... pay no respect at all.\"\n\n";
	return 0;
    }

    if (&IsMonster($NewUser))
    {
	print MAIL "$h Everyone knows monsters can't control wizards!\n\n";
	print MAIL "A Monster posing as a user was turned away from Firetop Mountain!\n";
	return 0;
    }

    if ( grep ($NewUser eq $_, @WizardNames) )
    {
	print MAIL "$h Sorry, but a mage exists with that name.\n";
	return 0;
    }

    if ($NewUser =~ m/janitor/i)
    {
	print MAIL "$h The Firetop Mountain Janitor sidles over and looks you up and down...\n";
	print MAIL "\"There's only room for one Janitor on this Mountain, and it ain't you, punk!\",\n";
	print MAIL " he says, and suddenly you find yourself a long way away...\n";
	return 0;
    }

    if ( $arg[0] =~ /no((ne)|(_?one)|(_?body))/i or $NewUser eq "All")
    {
	print MAIL "$h $arg[0] is not a valid user name.\n\n";
	return 0;
    }

    push(@UserNames, $NewUser);

    $Users{$NewUser}{'Index'} = $#UserNames;

    $Users{$NewUser}{"Password"} = $Password;
    $Users{$NewUser}{"Address"} = $Address;
    $Users{$NewUser}{"Duels"} = 0;
    $Users{$NewUser}{"Melees"} = 0;
    $Users{$NewUser}{"Mages"} = 0;
    $Users{$NewUser}{"Vacation"} = 0;

    &SetStat('UserActive', $NewUser, time());
    
    return 1;
}


sub GetUsers
{
    open(USERS, "users.dat") || die "Error opening users.dat\n$!";

    my(@UserInfo) = <USERS>;

    close USERS;
    
    eval "@UserInfo";

    @UserNames = keys %Users;

    die $@ if $@;
}


sub WriteUsers
{
    # Get rid of 'fakes'.  These happen where code like 
    # if (!$Users{$Name}{'Password'}) is done to determine if the user
    # exists.  This is not good code because it makes perl create an
    # empty entry for $User{$Name}, if there was not one.  This type
    # of not-so-good code exists because it used to be 
    # if (!$User{"$User.Password"}) back in the Perl 4 days, and was
    # 'automatically' converted.  It's too hard to find all the bad
    # places...

    my $User;
    foreach $User (keys %Users)
    {
	if (!keys(%{$Users{$User}}))
        {
	    delete $Users{$User};
	}
        elsif ($Users{$User}{'Index'} < 0)
	{
	    delete $Users{$User};
	    DeleteStat('UserActive', $User);
	}
    }

    open(USERS, ">users.dat") or 
	die "Error writing users.dat:$!, stopped ";
    
    print USERS Data::Dumper->Dump([\%Users], 
				   ['*Users']);
    
    close USERS or 
	die "Couldn't write users.dat: $!, stopped ";
}


sub UserList
{
    local (@list) = @_;
    my ($UsrName,@Wizlist,$wiz,$DuelScore,$MeleeScore,$line,$OnVacation);

    print MAIL "\nUsername            Duelscore MeleeScore  Mages  Address\n";
    print MAIL   "--------            --------- ----------  -----  -------\n";

    foreach $UsrName (@list ? @list : sort(@UserNames))
    {
	$UsrName = &GetName($UsrName);
	if (!$Users{$UsrName})
	{
	    if ($Wizard{$UsrName})
	    {
		$UsrName = $Wizard{$UsrName}{'User'};
	    }
	    else
	    {
		$line = sprintf ("%-20s %s", $UsrName, "No such user.\n");
		print MAIL $line;
		next;
	    }
	}

	($DuelScore,$MeleeScore) = (0,0);
	@Wizlist = &WizardsOfUser($UsrName,@WizardNames);
	foreach $wiz (@Wizlist)
	{
	    $DuelScore += $Wizard{$wiz}{'DuelScore'};
	    $MeleeScore += $Wizard{$wiz}{'MeleeScore'};
	}

	if ($Users{$UsrName}{'Vacation'})
	{
	    $OnVacation = " (on vacation)";
	}
	else
	{
	    $OnVacation = "";
	}
	$line = sprintf ("%-20s %4d/%-4d %4d/%-4d %3d/%-3d %s",
			 $UsrName . $OnVacation,
			 $DuelScore, $Users{$UsrName}{'Duels'},
			 $MeleeScore, $Users{$UsrName}{'Melees'},
			 $#Wizlist+1, $Users{$UsrName}{'Mages'},
			 $Users{$UsrName}{'Address'});
	print MAIL "$line\n";
    }
    print MAIL "\n";
}


sub InfoCommand
{
    local (@list) = @_;
    my ($Name,%WizUsers);

    foreach $Name (@list ? @list : sort(@UserNames))
    {
	$Name = &GetName($Name);

	if ($Users{$Name})
	{
	    print MAIL &UserInfoString($Name) . "\n";
	}
	elsif ($Wizard{$Name})
	{
	    print MAIL &WizInfoString($Name);
	    print MAIL "$Name belongs to $Wizard{$Name}{User}.\n\n";

	    $WizUsers{$Wizard{$Name}{'User'}} = 1;
	}
    }

    foreach $Name (keys %WizUsers)
    {
	print MAIL &UserInfoString($Name) . "\n";
    }
}

sub UserInfoString
{
    my($Name) = @_;

    my ($DuelScore,$MeleeScore,$MageList,$Game, $State) = (0,0,"");
    my (@Wizlist) = &WizardsOfUser($Name,@WizardNames);
    foreach my $wiz (@Wizlist)
    {
	$DuelScore += $Wizard{$wiz}{'DuelScore'};
	$MeleeScore += $Wizard{$wiz}{'MeleeScore'};
	
	$MageList .= " $wiz ($Wizard{$wiz}{'DuelScore'} $Wizard{$wiz}{'MeleeScore'}";
	$Game = $Wizard{$wiz}{'Busy'};
	if ($Game)
	{
	    $MageList .= " G:$Game";
	    if ($Game !~ /^\D/ && &GetGameInfo($Game,$wiz))
	    {
		$State = $Info{$wiz}{'State'};
		if ($StateDescription{$State})
		{
		    $State = $StateDescription{$State}
		}
		$State =~ s/_/ /;
		$MageList .= " $State";
	    }
	}
	$MageList .= ") ";
    }

    my $OnVacation = "";
    if ($Users{$Name}{'Vacation'})
    {
	$OnVacation = " (on vacation)";
    }

    return(
	   "User:               ". $Name.$OnVacation."\n".
	   "Address:            ". $Users{$Name}{'Address'}."\n".
	   "Total Duel Score:   ". $DuelScore ."\n".
	   "Duels fought:       ". $Users{$Name}{'Duels'}."\n".
	   "Total Melee Score:  ". $MeleeScore ."\n".
	   "Melees fought:      ". $Users{$Name}{'Melees'}."\n".
	   "Current mages:      ". ($#Wizlist+1) . "\n" .
	   "Mages ever created: ". $Users{$Name}{'Mages'}."\n".
	   "$MageList\n");
}

sub WizInfoString
{
    my ($Name) = @_;

    my ($String) = (
		    "Mage name:        ". $Name . "\n".
		    "Duel score:       ". $Wizard{$Name}{'DuelScore'} . "\n".
		    "Melee score:      ". $Wizard{$Name}{'MeleeScore'} . "\n".
		    "Battles survived: ". $Wizard{$Name}{'Battles'} . "\n".
		    "Status:           "
		    );

    if ($Wizard{$Name}{'Retired'} eq 1)
    {
	$String .= "Retired\n";
    }
    elsif ($Wizard{$Name}{'Busy'})
    {
	my($game) = $Wizard{$Name}{'Busy'};
	if ($game =~ s/^N(.*)$/$1/)
	{
	    $String .= "Just accepted challenge $game\n";
	}
	else
	{
	    if (!&GetGameInfo($game,$Name)) #Get %Info and $Turn
	    {
		$String .= "Oh no!  Database inconsistency for $Name!\n";
		$String .= "(Janitor has been notified: please don't use this mage!)\n";
		print STDERR "Database inconsistency detected during INFO command processing: \n $Name in game $game\n";
	    }
	    else
	    {
		my($state) = $Info{$Name}{'State'};
		if ($StateDescription{$state})
		{
		    $state = $StateDescription{$state};
		}
		$state =~ s/_/ /;
		$String .= "Busy in battle $game turn $Turn ($state)\n";
	    }
	}
    }
    else
    {
	$String .= "Free\n";
    }

    return $String;
}

sub Scores
{
    local($ScoreType) = @_;   # note - this is used in wizard_by_score,
                              #  so don't make it a my() variable!
    local($OtherScoreType) = (($ScoreType eq 'Duel')?'Melee':'Duel');
    local($Scores) = "\n";
    local($Resters) = "\n";
    my ($OnVacation) = "";

    $Scores .= "Honour Roll of the Mages of Firetop Mountain\n";
    $Scores .= "--------------------------------------------\n\n";
    $Scores .= "Active List (Sorted by $ScoreType Scores):\n\n";
    $Scores .= 
	sprintf("  Game   %-5s   %-5s   Battles     Mage                 User\n", 
		$ScoreType, $OtherScoreType);

    $Scores .= "         Score   Score   Survived\n";

    $Scores .= " ---------------------------------------------------------\n";

    $Resters = "Successfully Retired ($ScoreType Scores):\n\n";
    $Resters .= 
	sprintf("  Game   %-5s   %-5s   Battles     Mage                 User\n", 
		$ScoreType, $OtherScoreType);

    $Resters .= "         Score   Score   Survived\n";

    $Resters .= " ---------------------------------------------------------\n";

    foreach $wiz (sort wizard_by_score @WizardNames)
    {
        if (!$Wizard{$wiz}{'Dead'})
        {
            if ($Wizard{$wiz}{'Busy'})
            {
		if ($Users{$Wizard{$wiz}{'User'}}{'Vacation'})
		{
		    $OnVacation = "V";
		}
		else
		{
		    $OnVacation = "";
		}
                $Entry = sprintf(" %5s ",$Wizard{$wiz}{'Busy'}.$OnVacation);
            }
            else
            {
                $Entry = "       ";
            }
            
            $Entry .= sprintf("  %-5s   %-5s   %-8s    %-20s %s\n",
                              $Wizard{$wiz}{$ScoreType.'Score'},
                              $Wizard{$wiz}{$OtherScoreType.'Score'},
			      $Wizard{$wiz}{'Battles'},
                              $wiz,
                              $Wizard{$wiz}{'User'},
			      );

            if ($Wizard{$wiz}{'Retired'})
            {
                $Resters .= $Entry;
            }
            else
            {
                $Scores .= $Entry;
            }
        }
    }

    $Scores .= "

N before the game number indicates that it is a new game
that has not started yet.
V after the game number indiactes that the user controlling
the mage is on vacation.

";

    $Scores .= $Resters;
    
    open(HISTORY, "$ScoreType.history.dat") || return $Scores;

    @DeadNames = ();
    @DeadScores = ();
    @DeadUsers = ();
    %BestScore = ();
    
    while(<HISTORY>)
    {
        chomp;
        
        ($Name, $Score, $DeadUser) = split(/[ ]+/, $_, 3);
        print LOG "read dead wiz $Name\n";
        if ($Name && (!$BestScore{$Name} || ($BestScore{$Name} < $Score)))
        {
            push(@DeadNames, $Name);
            push(@DeadScores, $Score);
            push(@DeadUsers, $DeadUser);
            $BestScore{$Name} = $Score;
        }
    }

    close HISTORY;

    open(HISTORY, ">$ScoreType.history.dat") || die $!;
    
    $Scores .= "\n\nIn Remembrance of those who died Valiantly in ${ScoreType}s\n\n";

    $Scores .= " Score  Mage               User\n";
    $Scores .= " ---------------------------------\n";

    foreach $wiz_index (sort dead_by_score (0 .. $#DeadNames))
    {
        $Scores .= sprintf("%5s   %-18s %s\n",
                           $DeadScores[$wiz_index],
                           $DeadNames[$wiz_index],
                           $DeadUsers[$wiz_index]);
        print HISTORY "$DeadNames[$wiz_index] $DeadScores[$wiz_index] $DeadUsers[$wiz_index]\n";
    }
    close HISTORY;

    $Scores .= "\n\n";
    return $Scores;
    
}


sub WizardsOfUser
{
    local ($Usr,@WizNames) = @_;
    return grep($Wizard{$_}{'User'} eq $Usr, @WizNames);
}

1;
