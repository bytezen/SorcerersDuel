#! /usr/bin/perl -w
# -*- perl -*-

# Cleanup log files left round by FM's process.pl, and inspect game files to
# see if any players are lagging... hassle them if they are.

#----------------------------------------------------------------------

$CleanupVersion = '$Id: cleanup.pl,v 1.3.2.1 2002/11/11 05:27:02 fm Exp $ ';
$Revision = 'CL9.0';

$Home = shift or
    die "Need to supply \$Home as first argument to cleanup.pl\n";

$LogFile = $Home . "/cleanup.log";  # dont put this in logs dir!
$down = $Home . "/disable_server";

if (-f $LogFile and -M $LogFile < 0.5)
{
    die "Hey!  $LogFile has changed in under a day.  This doesn't seem right - wanna check your cron?\n";
}

rename($LogFile, "$LogFile.old");

open(CLEANUP_LOG, "| tee $LogFile") && select CLEANUP_LOG;
$| = 1;

print "Nagger version $Revision $CleanupVersion\n";

require "$Home/init.pl";
require "$Home/Dumper.pm";

#Stop perl compiler from complaining about variables only used once.
# (imported from other modules)
use vars qw{$Turn %Accepted @UserNames %Users};

#----------------------------------------------------------------------

$LeaveLogLines = 1000;   # keep this many most recent lines from log files
$MaxLogAge = 70; # Delete logs that not has been written to in so many days

$KeepHistories = 30;  # days

# most nagger control variables are set in init.pl:
use vars qw{$gmAddr $VacationFile $RefPassword $CallProcess_pl 
	    $sendmail $lockfile $RequiredSubject

	    $NagTime
	    $AutoResignTime
	    
	    $AllowedRest
	    $AllowedRetirement
	    
	    $ChallengeWarn
	    $ChallengeTimeout
	    
	    $NagUser
	    $TerminateUser};	    

# for testing: if 1, won't overwrite game files (still truncates logs)
$NoWrite = 0;
# for testing: if 1, will act as if all game files are old enough to nag
$KillemAll = 0;

#----------------------------------------------------------------------

chdir $SaveDir;

require "$Home/lib.pl";
require "$Home/users.pl";
require "$Home/stats.pl";
require "$Home/newgame.pl";
require "$Home/quotes.pl";

open(LOCK,"<$lockfile") || die "Couldn't open lock file\n";
flock(LOCK,2);

# messages from lib.pl go into normal log file...
open(LOG, ">>$LogDir/process.log") || die "Couldn't open log file\n";

print LOG "Cleanup.pl starting: ", scalar(localtime), "\n";

opendir(HERE, ".");
@Here = readdir(HERE);
closedir(HERE);

# first, lets do a backup!

print "Backing up (to ../saves.backup.tar.gz)...\n";

# give our selves every chance possible not to loose this stuff!
rename('../backup.saves.tar.gz', '../backup.saves.tar.gz.previous');

!system("tar czf ../saves.backup.tar.gz *") or
    warn "tar job returned non-zero exit status!\n";

# cleanup logs...

print "Cleaning up logs...\n";

chdir $LogDir;
opendir(LOGDIR, $LogDir);
@LogFiles = readdir(LOGDIR);
closedir(LOGDIR);

foreach $Logfile (grep(/log$/, @LogFiles ))
{
    if (-M $Logfile > $MaxLogAge)
    {
	unlink $Logfile unless $NoWrite;
	next;
    }
    system("tail -$LeaveLogLines $Logfile > tmp.$$");
    if (-s $Logfile == -s "tmp.$$")
    {
	unlink "tmp.$$";
    }
    else
    {
	rename("tmp.$$", $Logfile);
    }
}

print "Cleaning up old game histories...\n";

chdir $SaveDir;
foreach (sort(grep(/dsc$/, @Here)))
{
    if (m/(.*)\.dsc$/)
    {
        $Game = $1;

        if (! -f "$Game.gm")
        {
            if (-M $_ > $KeepHistories)
            {
                print " removing game: $Game\n";
                unlink("$Game.dsc", "$Game.hst") unless $NoWrite;
            }
        }
    }
}

foreach $GameType ('Duel','Melee')
{
    system("mv $GameType.history.dat $GameType.history.dat.old;
        head -10 $GameType.history.dat.old > $GameType.history.dat");
}


# Set these variables in all cases.
@VacationersFile = ();
@Vacationers = ();

# Now go on to nagging...

# (don't nag if there is any doubt that the server might not be up...)

if (-f 'disable_server' or -f $down)
{
    print "Not nagging - server is disabled\n";
}
else
{
    print "Checking for slow games...\n";
    &GetWizards;
    &GetUsers;

    if (!open(VACATIONERS, "$VacationFile"))
    {
        print "Couldn't open vacation file - everyone must be working!\n";
    }
    else
    {
        @VacationersFile = <VACATIONERS>;
        close VACATIONERS;
        # only the user name (first entry) is interesting.
        @Vacationers = map {(split())[0]} @VacationersFile;
    }

    $Turn = 0;  # shut up -w!
    @Players = @DeadPlayers = ();

  GAME_CHECK:
    foreach $GameFile (grep(/\.gm$/, @Here))
    {
        print "Checking game $GameFile... ";

	if (grep(m/^$GameFile$/, @Vacationers))
	{
	    print "($GameFile not checked: it's in the Vacation file)\n";
	    next GAME_CHECK;
	}

        if (-M $GameFile > $NagTime || $KillemAll)
        {
            print "Nag indicated...\n";
	    $GoodMessage = "";
            
            unless ($GameFile =~ m/(.+)\.gm$/)
            {
                print "Couldn't grok GameName from GameFile: $GameFile!?\n";
                next GAME_CHECK;
            }
            $GameName = $1;

            # 'no_one' makes &GetGameInfo skip the wiz check for us.
            # thus we can check the return value to determine if file is OK.

	    if ( ! &GetGameInfo($GameName,'no_one') )
	    {
		print "   ARGH!  Bogus GameFile\n";
		next GAME_CHECK;
	    }

	    @GoodGuys = @BadGuys = @DeadBadGuys = ();
          WIZ_CHECK:
	    foreach $wiz (@Players)
	    {
		next if grep(/^$wiz$/,@DeadPlayers);

		my $User = $Wizard{$wiz}{'User'};

		if ($User and grep(/^$User$/,@Vacationers))
		{
                    print " ($wiz is on vacation)\n";
                    $GoodMessage .= "($wiz is on vacation)\n";
                    
		    push(@GoodGuys,$wiz);
		}
		elsif ($Info{$wiz}{'State'} eq 'orders_in')
		{
		    push(@GoodGuys,$wiz);
		}
		else
		{
		    push(@BadGuys,$wiz);
		}
	    }

	    print "   Good = (@GoodGuys), Bad = (@BadGuys)\n";
	    next GAME_CHECK if ($#BadGuys == -1);

            if (-M $GameFile < $AutoResignTime && !$KillemAll)
            {
		foreach $Culprit (@BadGuys)
		{
                    print "Nagging $Culprit.\n";
		    &OpenMail( CULPRIT, $Users{$Wizard{$Culprit}{'User'}}{'Address'} );
                    print CULPRIT "Subject: Reminder: Firetop Mountain Game $GameName\n\n";
                    print CULPRIT &NagCulprit($Culprit);
		    close CULPRIT;
                
                    $GoodMessage .= &NagGoodGuy($Culprit);
		}
            } 
            else
            {
		foreach $Culprit (@BadGuys)
		{
		    print "Terminating $Culprit.\n"; 
		    &OpenMail( CULPRIT, $Users{$Wizard{$Culprit}{'User'}}{'Address'} );
		    print CULPRIT "Subject: Final Notice: Firetop Mountain Game $GameName\n\n";
		    print CULPRIT &TerminateCulprit($Culprit);
		    close CULPRIT;

		    $Info{$Culprit}{'HP'} = 0;
		    &TakeWizOutOfGame($Culprit);
		    push(@DeadBadGuys,$Culprit);

		    if (open(DESC, ">>$GameName.dsc"))
		    {
			print DESC "\n$Culprit forfeits the match for being too slow.\n";
			close DESC;
		    }
		    $GoodMessage .= &NotifyGoodGuyOfTermination($Culprit);
		}

		&WriteGameInfo($GameName)
                    if ((@DeadBadGuys > 0) && !$NoWrite);

		# all BadGuys terminated and only one GoodGuy: game over
                # (or no good-guys at all!)
		if ($#BadGuys == $#DeadBadGuys && @GoodGuys <= 1)
		{
                    $GoodMessage .= "Congratulations $GoodGuys[0]!  You win due to your opponent's forfeit!\n\n" if (@GoodGuys);
		    &ScoreGame(@GoodGuys) unless $NoWrite;
		    $GoodMessage .= &Scores($GameType);

                    &FinishGame unless $NoWrite;
		    &WriteWizards unless $NoWrite;
		}
		elsif ($#DeadBadGuys > -1)
		{
		    if ($#DeadBadGuys == $#BadGuys)
		    {
			$GoodMessage .= "The melee will now continue...\n\n";
		    }

# I dont think you can do the following: releasing the lock allows
# more than one process.pl to be running at once (remember that we are in a
# foreach $Game loop here).  Each could try to update wizards.dat at the same
# time...
#		    if (!fork)
#		    {
#			flock(LOCK,8); #Release lock so that process.pl can run
#			close(LOCK);
#
#			open(GAME, $CallProcess_pl);
#			print GAME "From $gmAddr\n";
#			print GAME "Subject: FM nagger\n\n";
#			print GAME "USER Referee $RefPassword\n";
#			print GAME "GAME $GameName Referee\n";
#			print GAME "END\n";
#			close(GAME);
#			exit 0;
#		    }

		    open(GAME , "|$sendmail $gmAddr");
		    print GAME "Subject: $RequiredSubject\n\n";
		    print GAME "User Referee $RefPassword\n\n";
		    print GAME "GAME $GameName Referee\n";
		    print GAME "END\n";
		    close(GAME);
		}
            }

	    foreach $GoodGuy (@GoodGuys)
	    {
		&OpenMail( GOOD_GUY, $Users{$Wizard{$GoodGuy}{'User'}}{'Address'} );
                print GOOD_GUY "Subject: Firetop Mountain Game $GameName\n\n";
		print GOOD_GUY "\nHi $GoodGuy,\n";                
		print GOOD_GUY $GoodMessage;
                close GOOD_GUY;
            }
        }
        else
        {
            print "proceeding fine.\n";
        }
    }

    print "Checking for lazy users...\n";
    
    &GetStats;
    
    # Work out a reasonable score above which to leave retirees on the list...
    
    my $RetireThreshold = 0;
    
    foreach $Wiz (@WizardNames)
    {
	if ($Wizard{$Wiz}{'Retired'} and
	    $Wizard{$Wiz}{'DuelScore'} + $Wizard{$Wiz}{'MeleeScore'} > $RetireThreshold)
	{
	    $RetireThreshold = 
		$Wizard{$Wiz}{'DuelScore'} + $Wizard{$Wiz}{'MeleeScore'};
	}
    }
    
    $RetireThreshold -= 4;
    
    print " Retirement Threshold Score is $RetireThreshold\n\n";
    
  USER_CHECK:
    foreach my $User (@UserNames)
    {
	if (grep(/^$User$/, @Vacationers))
	{
	    print "$User is on vacation - not checking\n";
	    next USER_CHECK;
	}

	my $UserActive = GetStat('UserActive', $User);

        if (!defined($UserActive))
        {
            print "Hmmm, $User isn't even in the stats list: adding $User now...\n";
            &SetStat('UserActive', $User, time());
            next USER_CHECK;
        }

	my $UserLapsedDays = int((time() - $UserActive) / (60*60*24));

	if (@UsersWizzes = WizardsOfUser($User, @WizardNames))
	{
	    # OK - user has wizards.  Let's see if they're being used...
	    
	    @UnusedWizzes = grep {!$Wizard{$_}{'Busy'}} @UsersWizzes;

	    if (@UnusedWizzes != @UsersWizzes)
	    {
		print "$User has wizards, and is using them - fine.\n";
		next USER_CHECK;
	    }

	    print "$User\'s mages are all idle... checking laziness...\n";
	    
	    # This check gives the user a chance to get a mage going again
	    # after their last active one finishes
	    
	    if ($UserLapsedDays < $NagUser) 
	    {
		print "... giving $User a chance to get things moving...";
		print " ($UserLapsedDays, $NagUser)\n";
	    }
	    else
	    {
	      WIZ_CHECK:
		foreach my $Wiz (@UsersWizzes)
		{
		    die "Logic error - $Wiz should not be busy!\n" 
			if $Wizard{$Wiz}{'Busy'};
		    
		    my $WizActive = &GetStat('WizActive', $Wiz);
		    
		    if (!defined($WizActive))
		    {
			print "Hmmm, $Wiz isn't even in the stats list: adding $Wiz now...\n";
			&SetStat('WizActive', $Wiz, time());
			next WIZ_CHECK;
		    }
		    
		    $TotScore = 
			$Wizard{$Wiz}{'DuelScore'} + $Wizard{$Wiz}{'MeleeScore'} +1;

		    $LapsedDays = int((time() - $WizActive) / (60*60*24));
		    
		    if ($Wizard{$Wiz}{'Retired'})
		    {
			if ($LapsedDays > $TotScore * $AllowedRetirement * 7 * 4)
			{
			    if ($TotScore > $RetireThreshold)
			    {
				print "$Wiz is enjoying his status in the sun\n";
			    }
			    else
			    {
				# print "*** $Wiz has had his time in the sun ($LapsedDays, " . ($TotScore-1) . ") - resisiting the temptation... ***\n";
				
				print "$Wiz has had his time in the sun ($LapsedDays, $TotScore) - terminating...\n";
				&OpenMail(LAZY_GUY, $Users{$Wizard{$Wiz}{'User'}}{'Address'});
				print LAZY_GUY "Subject: Remember $Wiz on Firetop Mountain?\n\n";
				print LAZY_GUY &TerminateLazy($Wiz);
				close LAZY_GUY;
				
				$Wizard{$Wiz}{'Dead'} = 1;
			    }
			}
			else
			{
			    print "$Wiz is enjoying retirement\n";
			}
		    }
		    elsif ($LapsedDays > $TotScore * $AllowedRest * 7)
		    {
			print "$Wiz is getting pretty lazy ($LapsedDays, " . ($TotScore-1) . ") - retiring...\n";
			
			&OpenMail(LAZY_GUY, $Users{$Wizard{$Wiz}{'User'}}{'Address'} );
			print LAZY_GUY "Subject: Remember $Wiz on Firetop Mountain?\n\n";
			print LAZY_GUY &RetireLazy($Wiz);
			close LAZY_GUY;
			
			$Wizard{$Wiz}{'Retired'} = 1;
			&DeclineAll($Wiz, 0);
		    }
		    else
		    {
			print "$Wiz has been hanging around for $LapsedDays days (OK, score is " . ($TotScore-1) . ")\n";
		    }
		}
		
	    }
	}
	else
	{
	    print "$User doesn't have wizzes ... checking laziness... \n";
	    
	    if (!defined($UserActive)) 
	    {
		print "Hmmmm ... $User is not even in the stats.  Adding now...\n";
		&SetStat('UserActive', $User, time());
	    }
	    else
	    {
		if  ($UserLapsedDays> $TerminateUser)
		{
		    print "$User is stale ($UserLapsedDays days) - terminating...\n";
		    &OpenMail(LAZY_GUY, $Users{$User}{'Address'});
		    print LAZY_GUY "Subject: Your User $User on Firetop Mountain\n\n";
		    print LAZY_GUY &UserTermination($User);
		    close LAZY_GUY;	
		    
		    $Users{$User}{'Index'} = -1;

		    &SendEsquireMail("unsubscribe", $Users{$User}{'Address'}) unless $NoWrite;
		}
		elsif ($UserLapsedDays > $NagUser)
		{
		    print "$User is hanging around ($UserLapsedDays days): nagging...\n";
		    &OpenMail(LAZY_GUY, $Users{$User}{'Address'});
		    print LAZY_GUY "Subject: Your User $User on Firetop Mountain\n\n";
		    print LAZY_GUY &UserWarning($User);
		    close LAZY_GUY;	
		}
		else 
		{
		    print "$User better get mages soon ($UserLapsedDays days)...\n";
		}
	    }
	}
    }

    print "Checking for expired vacations...\n";

    for(my $n=0; $n <= $#VacationersFile; $n++)
    {
	my ($VacUser, $Duration, $VacationStart) = 
	    split(' ', $VacationersFile[$n]);

	print " $VacUser... ";

	if ($Users{$VacUser})
	{
	    my ($Elapsed) =  (time() - $VacationStart) / (24 * 60 * 60);

	    print " on vacation for $Duration, elapsed $Elapsed...\n";
	    if ($Elapsed > $Duration)
	    {
		# Their vacation is over!
		
		print " back to work!\n";
		
		splice(@VacationersFile,$n,1);
		$n--;
		
		# Give them a reprieve from the nagger
		# (othewise their wizards might get terminated immediatly!)
		
		foreach my $Wiz (WizardsOfUser($VacUser))
		{
		    print " ... (allowing $Wiz some grace)\n";
		    NoteActivity($Wiz);
		}
	    }
	    else
	    {
		print " ... still having fun ...\n";
	    }
	}
	else
	{
	    print " ... not a user!\n";
	}
    }    
    
    open (VACATIONERS, ">$VacationFile") or
	die "Gleep: couldn't write vacation file!\n";
    print VACATIONERS @VacationersFile;
    close VACATIONERS;
    
    # Now lets cleanup old challenges.
    
    print "\nChecking for old challenges...\n\n";
    
    foreach $ChallengeFile (grep(m/^\d+.ngm$/, @Here))
    {
	$ChallengeNum = $ChallengeFile;
	$ChallengeNum =~ s/.ngm$//;
	
	print " Challenge $ChallengeNum...";
	if (-M $ChallengeFile > $ChallengeTimeout)
	{
	    print " too old!\n";
	    
	    &ReadNewGame($ChallengeNum);
	    
	    foreach $Acceptor (keys(%Accepted))
	    {
		
		&OpenMail(LAZY_GUY, $Users{$Wizard{$Acceptor}{'User'}}{'Address'});
		print LAZY_GUY "Subject: Remember Challenge $ChallengeNum on Firetop Mountain?\n\n";
		print LAZY_GUY &ChallengeTermination($Acceptor, $ChallengeNum);
		close LAZY_GUY;
		$Wizard{$Acceptor}{Busy} = 0;
		print " Freed $Acceptor.\n";
	    }

	    # Should really check if there are any -C-.ngm  files
            # and remove them too, but I'm too lazy right now!

	    unlink($ChallengeFile) or 
		warn "Gah! Could not remove $ChallengeFile!\n";
	}
	elsif (-M $ChallengeFile > $ChallengeWarn)
	{
	    print " needs a prod!\n";
	    
	    &ReadNewGame($ChallengeNum);
	    
	    &OpenMail(LAZY_GUY, $Users{$Wizard{$Challenger}{'User'}}{'Address'});
	    print LAZY_GUY "Subject: Remember Challenge $ChallengeNum on Firetop Mountain?\n\n";
	    print LAZY_GUY &ChallengeWarning($Challenger, $ChallengeNum);
	    close LAZY_GUY;	
	    print " told $Challenger\n";
	}
	else 
	{
	    printf " $ChallengeFile is OK (%d days old)\n", -M $ChallengeFile;
	}
    }
}

# get rid of stats for wizards who no longer exist
# (These only exist if some code somewhere forgets to DeleteStat them
#    when they die.)

my($deleted);
foreach $Name (&StatsElements('WizActive'))
{
    if (!$Wizard{$Name}) 
    {
        print "Noticed an old WizActive stat for $Name: deleting...\n";
        $deleted = &DeleteStat('WizActive', $Name);
    }
}
    
# get rid of retired wizards who didn't score...
# (These would not normally exist in any case).
    
foreach $wiz (@WizardNames)
{
    if ($Wizard{$wiz}{'Retired'} && 
	($Wizard{$wiz}{'DuelScore'}+$Wizard{$wiz}{'MeleeScore'} < 1))
    {
	$Wizard{$wiz}{'Dead'} = 1;
    }
}

&WriteWizards unless $NoWrite;
&WriteStats unless $NoWrite;
&WriteUsers unless $NoWrite;
    
print LOG "Cleanup finished.\n";
close LOG;

print "done.\n";
close CLEANUP_LOG;

flock(LOCK,8);
close(LOCK);

while (wait >= 0) {};  # can't print 'done' to CLEANUP_LOG after this, 'cause
                       # it's being tee'd, so tee is a child....

exit;


#-------------------------------------------------------------
sub NagGoodGuy
{
	my($Culprit) = shift;

	return "
Its been a while since $Culprit submitted orders, so I'm sending a reminder
to him/her.  Hopefully we'll see some action soon!

Good Luck...

The Firetop Mountain Referee Auto-nagging Service.
";
}


sub NagCulprit
{
	my($Culprit) = shift;

	$User = $Wizard{$Culprit}{'User'};
	return "
Hi '$Culprit',

Its been a while since you submitted orders for your Firetop Mountain battle!

Has this battle perhaps slipped your mind?  Here's the status:
".
&GameStatus($Culprit).
"
Hopefully you can submit some orders soon - if you don't, the referee
will declare your opponent to be the victor.

Firetop Mountain Referee Auto-nagging Service.
";
}


sub LastChanceGoodGuy
{
	my($Culprit) = shift;

	return "
$Culprit is taking forever with his move, but the GM has decided to try one
more nag.  Standby - hopefully there will be action soon!

The Firetop Mountain Auto-nagging Service.
";
}


sub LastChanceCulprit
{
	my($Culprit) = shift;

	$User = $Wizard{$Culprit}{'User'};
	return "
Hi '$Culprit',

You sure are taking a long time with your orders.  Normally, the GM would
terminate the game at this stage, declaring that you have forfeited.  But
the GM is giving you another chance!

Here is the status, in case you have lost the previous messages:
".
&GameStatus($Culprit) .
"
Looking forward to receiving your orders soon...

The Firetop Mountain Auto-nagging Service.
";
}


sub NotifyGoodGuyOfTermination
{
	my($Culprit) = shift;

	return "
$Culprit seems to be at a loss as to how to proceed in your duel.

Therefore the Firetop Mountain Referee has decided to remove
$Culprit from the mountain.

The Firetop Mountain Referee.


   From the sidelines emerges the Arch-Ref.  Silence descends over the
   Graven Circle.  The Arch-Ref gives a small, slow, shake of his head,
   almost looking sad, then blinks once at the comatose $Culprit.

   $Culprit vanishes!

   The Arch-Ref withdraws, and the other mages return their attention to
   more exciting affairs.
 

";
}


sub TerminateCulprit
{
	local($Culprit) = @_;

	return "
Hi '$Culprit',

It appears that you are at a loss as to how to proceed in your Firetop
Mountain duel.  Unfortunately, duels cannot be left in limbo forever,
so the Referee is declaring that you have forfeited.

Thanks for playing Firetop Mountain - hope you enjoyed it!

The Firetop Mountain Referee.



   Epilogue...
 
   From the sidelines emerges the Arch-Ref.  Silence descends over the
   Graven Circle.  The Arch-Ref gives a small, slow, shake of his head,
   almost looking sad, then blinks once at the comatose $Culprit.

   $Culprit vanishes!

   The Arch-Ref withdraws, and the other mages return their attention to
   more exciting affairs.

";
}

sub RetireLazy
{
    my($Lazy) = @_;

    if ($Wizard{$Lazy}{'DuelScore'} || $Wizard{$Lazy}{'MeleeScore'})
    {
        return "
The Graven Circle is a place where the elite come to battle.  It's been
a while since $Lazy was in a battle - people are starting to wonder if
all the tales about your prowess are made up.  Anyhow, the Janitor points
you in the direction of the other retired mages.

Any time you want to prove you're as good as you say you are, just issue a
challenge.  Until then, the rest of the active mages will leave you alone.

(This message brought to you by the Firetop Mountain Autonagger)
    ";
   }
   else
   {
      return "
The Graven Circle is a place where the elite come to battle.  It's been
a while since $Lazy was in a battle, and no-one can remember
$Lazy ever winning a fight.  So the Arch-mage has asked that $Lazy 
be removed.

Any time you want to prove you're as good as you say you are, you will
be welcome to re-register.  Hope you enjoyed 'Firetop Mountain'!

(This message brought to you by the Firetop Mountain Autonagger)
";
    } 
}

sub TerminateLazy
{
    my($Dead) = @_;
    
    return "

$Dead has had a wonderful time, lazying around the menhirs that surround the
Graven Circle, talking to the other retirees about deeds done long ago.

But Firetop Mountain is not a Retirement Home, it's a battle ground.
Eventually those who are no longer willing or able to participate must
move on.  And so it is with $Dead...

(If $Dead suddenly discovers the fountain of youth, and wants to return to
 battle, you will always be welcome to re-register)

Hope you enjoyed \"Firetop Mountain\"!

(This message brought to you by the Firetop Mountain Autonagger)
    ";

}

sub ChallengeWarning
{
    my ($Challenger, $Challenge) = @_;

    return "

Hello $Challenger!

It looks like your Firetop Mountain Challenge $Challenge is not getting
underway in its current form.  

Please use the CHANGEGAME order to make some adjustment that will let
this challenge proceed, or WITHDRAW the challenge.

If you do not do so, the challenge will be terminated.

(This message brought to you by the Firetop Mountain Autonagger)
";
}

sub ChallengeTermination
{
    my ($Participant, $Challenge) = @_;

    return "

Hello $Participant!

Unfortunately, Challenge $Challenge on Firetop Mountain looks like it is 
not going to result in a game, so it has been terminated.

You are now free to initiate a challenge of your own!


(This message brought to you by the Firetop Mountain Autonagger)
";
}

sub UserWarning
{
    my ($User) = @_;

    return "

Hello $User,

You seem to be sitting around Firetop Mountain not doing much.  We'd
love to have you play here, but if you sit around much longer the
Janitor will probably mistake you for debris and sweep you away....

(This message brought to you by the Firetop Mountain Autonagger)
";
}

sub UserTermination
{
    my ($User) = @_;

    return "

Hello $User,

It appears you are not up to much at Firetop Mountain these days.

We hope you enjoyed your time here - if you feel like playing again,
please feel free to sign up again!

In the mean time, your User name is being removed from the list...

(This message brought to you by the Firetop Mountain Autonagger)
";
}

