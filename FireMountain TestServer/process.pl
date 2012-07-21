#!/usr/bin/perl -w
# -*- perl -*-
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
#      The Original Code is process.pl.
#
#      The Initial Developer of the Original Code is Martin Gregory.
#
#      Contributors: Terje Bråten, John Williams.
#
#----------------------------------------------------------------------

$Revision = "P9.38";

$Home = shift or
    die "Need to supply \$Home as first argument to process.pl\n";

require "$Home/init.pl";

use vars ('$SpellDuration',
	  '$IceElementalPresent',
          '$FireAndIceExplosion',
          '$FireAndIceStormExplosion',
	  '@UserNames',
	  '@DeadMonsters',
	  '@DeadPlayers',  # NOTE - this contains surrendered players too!
	  '$SaveDir',
	  '$sendmail',
	  '$lockfile',
	  '$InputFile',
	  '@MaintainerAddresses',
	  '$RefPassword');

$KeepState = 20;   # How many previous lots of data files to keep.

$SubjectLine = "Subject: Results of Firetop Mountain Orders\n\n";

$SensibleLinesPerEmail = 100; # smallest size email for rules.

#----------------------------------------------------------------------

$| = 1;

require "$Home/lib.pl";
require "$Home/users.pl";
require "$Home/quotes.pl";
require "$Home/spells.pl";
require "$Home/newgame.pl";
require "$Home/stats.pl";
require "$Home/Dumper.pm";

chdir $SaveDir;

$Gestures = 'FPSWDC>-';

%GestureDesc = ('F', 'wriggles the fingers of',
                'P', 'proffers the palm of',
                'S', 'snaps the fingers of',
                'W', 'waves',
                'D', 'points the digit of',
                'C', 'claps with',
                '>', 'stabs with',
                '-', 'does nothing with');

%Paralyzed = ('F', 'F',
              'P', 'P',
              'S', 'D',
              'W', 'P',
              'D', 'D',
              'C', 'F',
              '>', '>',
              '-', '-');

%HandMap = ('Right', 'RH',
            'Left', 'LH',
            'Both', 'BH',
            'Fire', 'Fire');

#----------------------------------------------------------------------

open(LOCK,"<$lockfile") || die "Couldn't open $lockfile: $!\n";
flock(LOCK,2);

open(LOG, ">>$LogDir/process.log") || die "Couldn't open log file\n";
system("date >> $LogDir/process.log");
select((select(LOG), $| = 1)[0]);

open(ORDERS, "<$InputFile") || die "Couldn't open $InputFile: $!\n";

$FromLine = <ORDERS>;

@fld = split(/[ \n\t]+/,$FromLine);

if ($ENV{'SENDER'})
{
    $plrAddr = "\L$ENV{'SENDER'}";
    print LOG "Orders from $plrAddr (using SENDER as provided)\n";
}
elsif ($fld[0] eq "From")
{
    $plrAddr = "\L$fld[1]";
    print LOG "Orders from $plrAddr\n";
}
else
{
    die "Can't work out who to reply to!\n";
}

if (-f "disable_server")
{
    if ($gmAddr ne $plrAddr)
    {
        &OpenMail(MAIL,$plrAddr);

        print MAIL "Subject: Firetop Mountain Server is OFF!

Hi - you recently sent some orders to the Main Firetop Mountain server.
However, the server is temporarily down for maintenance.

There is ususally an email broadcast when the server returns - please hold
off till then, then resubmit your orders (your orders were _not_ queued).

Thanks!

Firetop Mountain Referee.
";
        close MAIL;
    }
    close LOG;
    flock(LOCK,8);
    close(LOCK);
    exit 0;
}

$ShowScores = "";   # A string containing one or more
                    # of 'duel', 'melee', 'all'.

@ShowStats = ();   # An array containing statistics group names
%Messages = ();    # A hash of messages by receipient name list.

@UsersArg = ();
@InfoArg = ();

$CommandCount = 0;
$parse = "";

&GetUsers;
&GetWizards;
&GetStats;

$LeftIn = 0;
$RightIn = 0;

$SkipToSubject = 1;
$SkipToBody = 0;
$NeedsEnd = 0;
$NoUserOK = 0;

$ShowGames = 0;
@GamesToShow = ();
$Replay = 0;

$LastOrder = 0;  # Don't process any more orders after orders affecting
                 # challenges (it's too easy to get in a mess).

$isincomment = 0;       # CUT..END CUT flag

ORDER:while (1)
{
    $_ = <ORDERS>;
    if (!defined)
    {
	if ($NeedsEnd && !$isincomment)
	{
	    $_ = "END\n";   # automatically add END if needed
	}
	else
	{
	    last;
	}
    }

    chomp;

    if ($SkipToBody)
    {
        next if (m/.+/);    # jump over remaing headers

        $SkipToBody = 0;    # blank line => we are past the headers
	next;
    }

    if ($SkipToSubject)
    {
	if (m/^\s*$/)
	{
	    # blank line => we are past the headers
	    $SkipToSubject = 0;
	    $SkipToBody = 0;
	    next;
	}
	next unless s/^Subject:\s+//i;

	$SkipToSubject = 0;
        $SkipToBody = 1;

        # accept orders on the subject line
	if (!(s/^\w*FM\s+//i))
	{
	    next unless s/^.*(help|rules)/$1/i;
	}

	next if /^orders\b/i;
    }

    s/^\s*(--(\b|\s)|__).*$/END/;        # Auto end if sig.
    next if /^\s*[^\w\s]/;         # Skip forwarded email lines
    s/;.*$// unless m/^\s*say\b/i; # Strip comments

    if (/^\s*cut\s*$/i) {       # CUT..END CUT
        $isincomment = 1;
        next;
    } elsif (/^\s*end\s*cut\s*$/i) {
        $isincomment = 0;
        next;
    }
    next if $isincomment;       # skip if being commented

    $Command = $_;

    if ($Command =~ m/^Turn Server Off, (.*)$/ &&
        ($passwd = $1, crypt($passwd, "aa") eq "aae.ep8N3noK2"))
    {
        system('touch disable_server');
        &OpenMail(MAIL,$MaintainerAddress);
        print MAIL "Subject: Firetop Mountain Server has been turned OFF\n\nOK\n";
        close MAIL;
        close LOG;
        flock(LOCK,8);
        close(LOCK);
        exit 0;
    }

    @arg = split(/[\t ]+/, $Command);
    shift(@arg) while @arg > 0 && $arg[0] eq "";
    next if @arg == 0;

    $keyword = shift(@arg);
    $keyword = "\U$keyword";

	 # Put ADDSPELL and REMOVESPELL processing here, because they
	 # may be on lines immediately following NEWGAME and CHANGEGAME
	 # which set $LastOrder,\.
	 if ($keyword eq 'ADDSPELL' || $keyword eq 'REMOVESPELL')
	 {
        print LOG "parsing $keyword...\n";
        $parse .= sprintf("%-40s", $_);
		  # Previous command must have been either a NEWGAME or CHANGEGAME
		  if ($CommandCount < 1)
		  {
            $parse .= "\n > $keyword must follow a NEWGAME or CHANGEGAME command";
            $errs++;
            last;
		  }
		  my @prevcmd = split (/[\t ]/, $CmdLine[$CommandCount-1]);
		  if ($prevcmd[0] ne "NEWGAME" && $prevcmd[0] ne "CHANGEGAME")
		  {
            $parse .= "\n > $keyword must follow a NEWGAME or CHANGEGAME command";
            $errs++;
            last;
		  }
          if ($CmdLine[$CommandCount-1] =~ /^(.*)([Cc][Oo][Mm][Mm][Ee][Nn][Tt].*$)/) {
            $CmdLine[$CommandCount-1] = "$1$keyword " . join (" ", @arg) . ", $2";
          } else {
		    $CmdLine[$CommandCount-1] .= ", $keyword " . join (" ", @arg);
          }
        $parse .= " OK\n";
		  next;
    }

   if ($LastOrder and $keyword ne 'END')
    {
	$parse .= sprintf("%-40s ignored", $_);
        $parse .= "\n(ignoring any commands following previous administrative command)\n";
        last;
    }

    if ($keyword eq "TEST_COMMAND")
    {
        print LOG "parsing $keyword...\n";
	$parse .= sprintf("%-40s", $_);
	$CmdLine[$CommandCount++] = join(" ",$keyword,@arg);
        $GameName = "NONE" if (!$GameName);
	$NoUserOK = 1;
        $parse .= " OK\n";
	next;
    }

    if ($keyword eq 'RULES' || $keyword eq 'HELP' || $keyword eq 'FAQ')
    {
	print LOG "parsing $keyword...\n";
	$parse .= sprintf("%-40s", $_);
	$CmdLine[$CommandCount++] = join(" ",$keyword,@arg);
	$NoUserOK = 1;

        if (!$GameName)
        {
            $GameName = "NONE";
        }
        $parse .= " OK\n";
	next;
    }

    if ($keyword eq "NEWUSER")
    {
	print LOG "parsing $keyword...\n";
	$parse .= sprintf("%-40s", $_);
	$CmdLine[$CommandCount++] = join(" ",$keyword,@arg);
	$NoUserOK = 1;

	if ($User)
	{
	    $parse .= "\n > But you are already registered as user $User!"
       ."\n   (Use the command CHANGEUSER if you want to change user name.)\n";
	    $errs++;
	    last;
	}

        if (@arg != 2)
        {
            $parse .= "\n > $keyword expects a user name and a password!\n";
            $errs++;
            last;
        }

        print LOG "..$arg[0]\n";

	my ($NewUser,$Password) = (&GetName("\L$arg[0]"),$arg[1]);

	my ($u);
	foreach $u (@UserNames)
	{
	    if ($plrAddr eq $Users{$u}{'Address'})
	    {
		$parse .= "\n > You are already registered as user $u.\n".
		    "   (It is not allowed to have multiple users at this server)\n";
		$errs++;
		last ORDER;
	    }
	}

        if ($Users{$NewUser})
	{
            $parse .= "\n > That user name is already taken, sorry.\n";
	    $errs++;
	    last;
	}

        if (defined($Wizard{$NewUser}))
        {
            $parse .= "\n > That user name is already in use as a wizard name, sorry.\n";
	    $errs++;
	    last;
        }

        if (($NewUser !~ m/^\w+$/) || ($Password !~ m/^\w+$/))
        {
            $parse .= "\n > Please use alpha-numeric characters only \n  - other characters are too hard to pronounce!\n";
            $errs++;
            last;
        }

        if (!$GameName)
        {
            $GameName = "NONE";
        }

        $parse .= " OK\n";
	next;
    }

    if ($keyword eq "USER")
    {
	$arg[0] = $arg[0] ? $arg[0] : "";  # protect against no $arg[0] warnings

	print LOG "parsing $keyword $arg[0] ...\n";
	$parse .= sprintf("%-40s", $_);
	$CmdLine[$CommandCount++] = join(" ",$keyword,@arg);

	if ($User)
	{
	    $parse .= "\n > But you are already logged in as user $User!"
          ."\n   (This command is only to be used as the first command.)\n";
	    $errs++;
	    last;
	}

	if ( @arg < 2 )
        {
	    $parse .= " \n > $keyword command needs user name and password!\n";
	    $errs++; last;
	}

	if ( @arg > 2 )
        {
	    $parse .= " \n > Too many arguments for $keyword command!\n";
	    $errs++; last;
	}

	($User,$Password) = (&GetName($arg[0]),$arg[1]);
	my ($usrAddr) = ("");

        if (!$Users{$User})
        {
	    if ($User eq "Referee")
	    {
		$Referee = 1; #It is the Referee that is submitting orders
		print LOG "The Referee logs in ...\n";
 	    }
	    else
	    {
		$parse .= " \n > There doesn't seem to be a user called $User!\n";
		$errs++;
		last;
	    }
        }
	else
	{
	    $usrAddr = $Users{$User}{'Address'};
	}

	if ($Referee)
	{
	    if ($Password ne $RefPassword)
	    {
		$parse .= " \n > $Password is not the right password for $gmName\n";
		$errs++;
		last;
	    }

	    if ($plrAddr ne $gmAddr && !grep($plrAddr eq $_,@MaintainerAddresses))
	    {
		$parse .= "\n > Only the Maintainer ($MaintainerAddress) may act as the Referee.\n";
		print LOG "A false Referee!\n";
		#and generate an error message on STOUT also ...
		print "A false Referee!\n";
		$errs++; last;
	    }

	}
	elsif ($Users{$User}{"Password"} ne $Password )
        {
            $parse .= " \n > $Password is not the right password for $User\n";
            $errs++;
            last;
        }
	print LOG "User $User logged in OK.\n";
        $parse .= " OK\n";

	if ($usrAddr)
	{
	    if ($usrAddr eq "nobody\@gamerz.net")
	    {
		$parse .= "  $User has no valid mail address.\n";
		$Users{$User}{'Address'} = $plrAddr;
		$parse .= "  Changed address for $User to $plrAddr\n";
		&SendEsquireMail("subscribe", $plrAddr);
	    }
	    else
	    {
		$plrAddr = $usrAddr;
	    }
	}

	next;
    }

    if ($keyword eq "RESEND") 
    {
	print LOG "parsing $keyword...\n";
	$parse .= sprintf("%-40s", $_);
	$CmdLine[$CommandCount++] = join(" ",$keyword,@arg);

        $GameName = "NONE" if (!$GameName);

	if ( @arg > 1)
        {
	    $parse .= " \n > $keyword command expects only the number of reports to send\n";
	    $errs++; next;
	}

        $parse .= " OK\n"; next;
    }

    if ($keyword eq "GAMES" ||
	$keyword eq "LIST")
    {
        print LOG "parsing $keyword...\n";
        $parse .= sprintf("%-40s", $_);
        $CmdLine[$CommandCount++] = join(" ",$keyword,@arg);
	$NoUserOK = 1;

        $GameName = "NONE" if (!$GameName);

        if (!@arg)
	{
            $parse .= " OK\n";
            next;
        }

        my($NewErrs,$game) = (0,0);
        foreach $game (@arg)
	{
            if (!(-f "$game.dsc"))
	    {
                $parse .= "\n Game $game not found!\n";
                $errs++;
                $NewErrs = 1;
            }
	}
        next if $NewErrs;
        $parse .= " OK\n";
        next;
    }

    if ($keyword eq "CHALLENGES" ||
        $keyword eq "SCORES" ||
        $keyword eq "SPELLS" ||
        $keyword eq "STANDINGS" ||
        $keyword eq "STATS")
    {
	print LOG "parsing $keyword...\n";
	$parse .= sprintf("%-40s", $_);
	$CmdLine[$CommandCount++] = join(" ",$keyword,@arg);
	$NoUserOK = 1;

        if (!$GameName)
        {
            $GameName = "NONE";
        }
        $parse .= " OK\n"; next;
    }

    if ($keyword eq "INFO"||$keyword eq "USERS")
    {
	print LOG "parsing $keyword...\n";
	$parse .= sprintf("%-40s", $_);
	$CmdLine[$CommandCount++] = join(" ",$keyword,@arg);
	$NoUserOK = 1;
	$GameName = "NONE" if (!$GameName);

	my($NewErrs,$Name) = 0;
	foreach $Name (@arg)
	{
	    $Name = &GetName($Name);
	    if (!$Users{$Name} && !$Wizard{$Name})
	    {
		$parse .= "\n Hmmm - $Name does not seem to be a User or a Wizard!\n";
		$errs++;
		$NewErrs = 1;
	    }
	}
	next if ($NewErrs);
	$parse .= " OK\n";
	next;
    }


    if ($keyword eq "SHOW" ||
        $keyword eq "DESCRIBE")
    {
	print LOG "parsing $keyword...\n";
	$parse .= sprintf("%-40s", $_);
	$CmdLine[$CommandCount++] = join(" ",$keyword,@arg);
	$NoUserOK = 1;

        if (!$GameName)
        {
            $GameName = "NONE";
        }

        if (@arg != 1)
        {
            $parse .= "\n $keyword expects one argument.\n";
            $errs++; next;
        }

	if ( (!-f "$arg[0].hst") && (!-f "$arg[0].ngm") )
	{
	    $parse .= "\n > No game $arg[0] found!\n";
	    $errs++; next;
	}

        $parse .= " OK\n"; next;
    }

    if ($keyword eq "END")
    {
        print LOG "parsing $keyword...\n";
	$parse .= $_;
        $NeedsEnd = 0;
	if ($GameName and $GameName ne "NONE" and $GameName ne "NEW")
	{
	    $CmdLine[$CommandCount++] = "END";
	    last if $Replay;
	    if (($LeftIn && !$RightIn) || ($RightIn && !$LeftIn))
	    {
		$parse .= "\n You only successfully specified the gesture of one hand!\n";
		$parse .= " Please try again! (You will need to resubmit both hands)\n";
		$errs++;
	    }
	}
        last;
    }

    next if !$User;

    if ($keyword eq "CHANGEUSER")
    {
	print LOG "parsing $keyword...\n";
	$parse .= sprintf("%-40s", $_);
	$CmdLine[$CommandCount++] = join(" ",$keyword,@arg);
        $GameName = "NONE" if (!$GameName);

	if ( @arg != 1 )
        {
	    $parse .= " \n > $keyword command needs new user name as argument!\n";
	    $errs++;
	    next;
	}

	my($Username) = &GetName($arg[0]);

        if ($Users{$Username}{"Password"})
	{
            $parse .= "\n > That user name is already taken, sorry.\n";
	    $errs++;
	    last;
	}

        if (defined($Wizard{$Username}))
	{
            $parse .= "\n > That user name is already in use as a mage name, sorry.\n";
	    $errs++;
	    last;
	}

        if ($Username !~ m/^\w+$/)
        {
            $parse .= "\n > Please use alpha-numeric characters only \n  - other characters are too hard to pronounce!\n";
            $errs++;
            last;
        }

        $parse .= " OK\n"; next;
    }

    if ($keyword eq "VACATION")
    {
	print LOG "parsing $keyword...\n";
	$parse .= sprintf("%-40s", $_);
	$CmdLine[$CommandCount++] = join(" ",$keyword,@arg);

        if (!$GameName)
        {
            $GameName = "NONE";
        }

	
	if (@arg != 1 or (!IsNumber($arg[0]) and !$Referee))
        {
	    $parse .= " \n > $keyword command needs the duration\n";
 	    # (Referee is allowed a game name, but
            #  no need to tell the players that!)
	    $errs++; last;
	}

	$parse .= " OK\n"; next;
    }

    if ($keyword eq "MAGE")
    {
	print LOG "parsing $keyword...\n";
	$parse .= sprintf("%-40s", $_);
	$CmdLine[$CommandCount++] = join(" ",$keyword,@arg);

	if ( $GameName )
        {
	    $parse .= "\n > $keyword command must be second command only\n";
	    $errs++; next;
	}

	if ( @arg != 1 )
        {
	    $parse .= " \n > $keyword command needs Mage Name only!\n";
	    $errs++; last;
	}

	$Player = &GetName($arg[0]);

        $DidSomething = 0;   # If the player doesnt do anything we dont save
                             # save the gamefile (so we can track the time
                             # that orders were last submitted).

        if (!$Wizard{$Player})
        {
	    $parse .= " \n > There doesn't seem to be a wizard called $Player!\n";
	    $errs++;
	    last;
	}
        
	if (!$Referee and $Wizard{$Player}{"User"} ne $User)
        {
            $parse .= " \n > The wizard called $Player is not one of your mages!\n";
            $errs++;
            last;
        }

	$GameName = $Wizard{$Player}{"Busy"};

	if (!$GameName or $GameName =~ m/^N/)
	{
	    $parse .= "\n > $Player doesn't seem to be involved in battle at the moment!\n";
	    $errs++;
	    last;
	}

	if (!&GetGameInfo($GameName, $Player))
	{
	    $parse .= "\n > *** DATABASE ERROR: Janitor has been notified.  Please don't submit more orders for this game or wizard. ***\n";
	    print  "*** DATABASE ERROR: $GameName, $Player\n";
	    $errs++;
	    last;
	}

	$SubjectLine = "Subject: Battle $GameName, turn $Turn (Results of Orders)\n\n";

        if ($Info{$Player}{'State'} eq 'orders_in')
        {
            $parse .= "\n You've already submitted orders for this round:\n it's too late to change your mind now!\n\n";
            last;   #; don't flag an error, so we give them the game status.
        }

 	if ($Info{$Player}{'State'} eq 'OUT')
 	{
 	    $parse .= "\n Sorry, but you are out of game $GameName!\n".
 	     " No orders for $Player are accepted in this game anymore.\n\n";
 	    last;   #; don't flag an error, so we give them the game status.
 	}

        $NeedsEnd = 1;

        $parse .= " OK\n"; next;
    }

    if ($keyword eq "GAME" || $keyword eq "MOVE")
    {
	# This command is partly for backward compatibility, but
        # also so that the Referee can submit orders for a nominated game...

	print LOG "parsing $keyword...\n";
	$parse .= sprintf("%-40s", $_);
	$CmdLine[$CommandCount++] = join(" ",$keyword,@arg);

	if ( $GameName )
        {
	    $parse .= "\n > $keyword command must be second command only\n";
	    $errs++; next;
	}

	if ( @arg != 2 )
        {
	    $parse .= " \n > $keyword command needs game-ID and player name!\n";
	    $errs++; last;
	}

	($GameName, $Player) = ($arg[0], &GetName($arg[1]));

        $DidSomething = 0;   # If the player doesnt do anything we dont save
                             # save the gamefile (so we can track the time
                             # that orders were last submitted).

        if (!$Wizard{$Player})
        {
	    if ($Referee and $Player eq "Referee")
	    {
		$Player = 'no_one';
		$DidSomething = 1; # Allways update the gamefile.
		print LOG "Move in game $GameName made by the Referee\n";
 	    }
	    else
	    {
		$parse .= " \n > There doesn't seem to be a wizard called $Player!\n";
		$errs++;
		last;
	    }
        }

	if (!$Referee and $Wizard{$Player}{"User"} ne $User)
        {
            $parse .= " \n > The wizard called $Player is not one of your mages!\n";
            $errs++;
            last;
        }

        if (!&GetGameInfo($GameName, $Player))
        {
            $parse .= "\n > '$GameName' is not a valid game for $Player\n";
            $errs++;
            last;
        }

	$SubjectLine = "Subject: Battle $GameName, turn $Turn (Results of Orders)\n\n";

	if ($Referee and $Player eq 'no_one')
	{
	    $Player = "";
	    $NeedsEnd = 1;
	    $parse .= " OK\n"; next;
	}

        if ($Info{$Player}{'State'} eq 'orders_in')
        {
            $parse .= "\n You've already submitted orders for this round:\n it's too late to change your mind now!\n\n";
            last;   #; don't flag an error, so we give them the game status.
        }

 	if ($Info{$Player}{'State'} eq 'OUT')
 	{
 	    $parse .= "\n Sorry, but you are out of game $GameName!\n".
 	     " No orders for $Player are accepted in this game anymore.\n\n";
 	    last;   #; don't flag an error, so we give them the game status.
 	}

        $NeedsEnd = 1;

        $parse .= " OK\n"; next;
    }

    if ($keyword eq "REPLAY")
    {
	print LOG "parsing $keyword...\n";
	$parse .= sprintf("%-40s", $_);

	if ( $GameName )
        {
	    $parse .= "\n > $keyword command cannot be combined with the above comands.\n";
	    $errs++; last;
	}

	if ( @arg < 1 || $arg[0] !~ m/^\d+$/ )
        {
	    $parse .= " \n > $keyword command needs at least a game number.\n";
	    $errs++; last;
	}

	$GameName = $arg[0];

	if ( @arg == 2 && $arg[1] =~ m/^\d+\w?$/)
	{
	    $Turn = $arg[1];
	}
	elsif (@arg == 1)
	{
	    opendir (DIR,$SaveDir) || die $!;
	    my (@Turns) = grep /^$GameName\.gm\.turn\./, readdir(DIR);
	    closedir DIR;
	    if (!@Turns)
	    {
		$parse .= "\n > No played turns found for game $GameName.\n";
		$errs++; last;
	    }
	    @Turns = sort {-M $a <=> -M $b} @Turns;
	    $Turn = pop @Turns;
	    $Turn =~ s/^$GameName\.gm\.turn\.//;
	}
	else
	{
	    if ( @arg > 2 )
	    {
		$parse .= "\n > Too many arguments for command $keyword.\n";
	    }
	    else
	    {
		$parse .= "\n > Invalid turn number.\n";
	    }
	    $errs++; last;
	}

	$CmdLine[$CommandCount++] = "$keyword $GameName $Turn";
	$Player = "no_one";

	if (!&GetGameInfo($GameName, $Player, "$GameName.gm.turn.$Turn"))
	{
	    if (! -f "$GameName.gm")
	    {
		$parse .= "\n > '$GameName' is not a current game.\n";
	    }
	    else
	    {
		$parse .= "\n > Found no turn $Turn in game $GameName.\n";
	    }
            $errs++; last;
	}

	$SubjectLine = "Subject: Battle $GameName, turn $Turn (Replay)\n\n";
	$Replay = 1;
        $NeedsEnd = 1;
        $DidSomething = 0;   # Do not save
	$LastOrder = 1;
        $parse .= " OK\n"; next;
    }

    if ($keyword eq "MESSAGE")
    {
        print LOG "parsing $keyword...\n";
	$parse .= sprintf("%-40s", $_);
	$CmdLine[$CommandCount++] = join(" ",$keyword,@arg);

        $GameName = "NONE" if (!$GameName);
        $MessageTerminator = '^\s*END\s*MESSAGE\s*$';    #'

        if (@arg < 2)
        {
            $parse .= "\n $keyword needs FROM and TO LIST\n";
            $errs++;
	    goto SkipMessage;
        }

	my ($From, $Message, $MessageIn);

        $From = &GetName(shift @arg);

	if (!$Referee || $From ne "Referee")
	{
	    if (!$Wizard{$From})
	    {
		$parse .= "\n $From is not a registered combatant.\n";
		$errs++;
		goto SkipMessage;
	    }
	}

	if (!$Referee)
	{
	    if ($Wizard{$From}{'User'} ne $User)
	    {
		$parse .= "\n > $From is not one of user $User\'s wizards.\n";
		$errs++;
		goto SkipMessage;
	    }
	}

	my ($error) = (0);
        foreach $mage (@arg)
        {
            $MageName = &GetName($mage);
            if (!$Wizard{$MageName} && !$Users{$MageName})
            {
                $parse .= "\n Hmmm - Who is $mage? Can't find any mage or user by that name.\n";
                $errs++;
		$error = 1;
            }
        }
	goto SkipMessage if $error;

        $Message = "";
        $MessageIn = 0;
        while (<ORDERS>)
        {
            if (m/$MessageTerminator/i)
            {
                $parse .= " Message Recorded\n";
                $MessageIn = 1;
                last;
            }
            $Message .= $_;
        }

	push (@Messages, $Message);

        if (!$MessageIn)
        {
            $parse .= "\n Hmmm didn't see 'END MESSAGE' - sending the whole lot!\n";
        }

        next;

      SkipMessage:
        $MessageIn = 0;
	while (<ORDERS>)
	{
	    if (m/$MessageTerminator/i)
	    {
		$MessageIn = 1;
		last;
	    }
	}
        if (!$MessageIn)
        {
            $parse .= "\n Didn't see 'END MESSAGE' - ignoring the rest of the mail.\n";
	    last;
        }
	next;
    }

    if ($keyword eq "ANNOUNCE")
    {
        print LOG "parsing $keyword...\n";
	$parse .= sprintf("%-40s", $_);
	$CmdLine[$CommandCount++] = join(" ",$keyword,@arg);

        $GameName = "NONE" if (!$GameName);
        $MessageTerminator = '^\s*END\s*ANNOUNCE\s*$';    #'

        if (@arg < 1)
        {
            $parse .= "\n $keyword needs a list of games\n";
            $errs++;
	    while (<ORDERS>)
	    {
		#Skip Message
		last if (m/$MessageTerminator/i)
	    }
	    next;
        }

        my (%msgto, $ToUser, $UserInGame) = ();
        foreach my $gamenum (@arg)
        {
            if (!&GetGameInfo($gamenum, 'no_one')) {
                $parse .= "\n Game $gamenum seems to be missing!\n";
                $errs++;
            } else {
		$UserInGame=0;
		foreach $Wiz (@Players)
		{
		    $ToUser = $Wizard{$Wiz}{'User'};
                    $msgto{$ToUser}++;
		    $UserInGame=1 if $ToUser eq $User;
                }
		if (!($UserInGame || $Referee))
		{
		    $parse .= "\n You can not make announcements in games you are not participating in.\n";
		    print LOG "False annoucement from $plrAddr to game $gamenum\n";
		    $errs++;
		    last;
		}
            }
        }

	if ($GameName and $GameName =~ /^\d/)
	{
	    #Restore Game Info for use for subsequent commands in this mail
	    &GetGameInfo($GameName, $Player);
	}

        if ($errs)
	{
	    while (<ORDERS>)
	    {
		#Skip Message
		last if (m/$MessageTerminator/i)
	    }
	    next;
	}

        push (@Recipients, [sort keys %msgto]);

	my ($Message, $MessageIn) = ("", 0);
        while (<ORDERS>)
        {
            if (m/$MessageTerminator/i)
            {
                $parse .= " Announcement Recorded\n";
                $MessageIn = 1;
                last;
            }
            $Message .= $_;
        }

        push (@Messages, $Message);

        if (!$MessageIn)
        {
            $parse .= "\n Hmmm didn't see 'END ANNOUNCE' - sending the whole lot!\n";
        }

        next;
    }

    if ($keyword eq "ADDRESS" ||
        $keyword eq "PASSWORD")
    {
	print LOG "parsing $keyword...\n";
	$parse .= sprintf("%-40s", $_);
	$CmdLine[$CommandCount++] = join(" ",$keyword,@arg);

        if (!$GameName)
        {
            $GameName = "NONE";
        }

        if (@arg != 1)
        {
            $parse .= "\n $keyword expects exactly one argument.\n";
            $errs++; next;
        }

        $parse .= " OK\n"; next;
    }


    if (($keyword eq "NEWGAME") ||
        ($keyword eq "CHANGEGAME") ||
        ($keyword eq "ACCEPT") ||
        ($keyword eq "OPPOSE") ||
        ($keyword eq "WITHDRAW") ||
        ($keyword eq "DECLINE") ||
        ($keyword eq "RETIRE") ||
        ($keyword eq "QUIT") ||
        ($keyword eq "REGISTER") ||
        ($keyword eq "SUBSCRIBE"))
    {
	if ($GameName and $GameName ne "NONE" and $GameName ne "NEW")
	{
	    $parse .= sprintf("%-40s", $_);
	    $parse .= "\n > Can't process this type of command with ordinary game orders.\n";
	    $errs++;
	    last;
	}
        $GameName = "NEW";
    }

    last if (!$GameName || ($GameName eq "NONE"));

    $parse .= sprintf("%-40s", $_);

    if ($keyword eq "SUBSCRIBE")
    {
	print LOG "parsing $keyword...\n";
	if ( @arg < 1 )
        {
	    $parse .= "\n > $keyword needs a list of game numbers.\n";
	    $errs++; next;
	}

	my @newarg = ();

	while ($GN = shift @arg)
	{
	    if (-f "$GN.ngm")
	    {
		push (@newarg, "N$GN");
		next;
	    }

	    if (!&GetGameInfo($GN, 'no_one'))
	    {
		$parse .= "\n > '$GN' is not a current game.\n";
		$errs++;
		last ORDER;
	    }
	    push (@newarg, $GN);
	}

	$CmdLine[$CommandCount++] = join(" ",$keyword,@newarg);
	$parse .= " OK\n";
	next;
    }

    if (($keyword eq "NEWGAME") || ($keyword eq "CHANGEGAME") ||
        ($keyword eq "ACCEPT") || ($keyword eq "OPPOSE") ||
        ($keyword eq "WITHDRAW") || ($keyword eq "DECLINE"))
    {
        $LastOrder = 1;
	print LOG "parsing $keyword...\n";

	my @newarg = ();

        # command game_number name [option]

	if ( @arg < 2 )
        {
	    $parse .= "\n > not enough arguments for $keyword\n";
	    $errs++; next;
	}

	if ($keyword eq "NEWGAME")
	{
	    $NewGame = 0;
	}
	else
	{
	    $NewGame = shift @arg;
	    push (@newarg, $NewGame);
	}

	if ($NewGame)
	{
	    if (-f "$NewGame.ngm")
	    {
		$SubjectLine = "Subject: Challenge $NewGame on Firetop Mountain (Results of Orders)\n\n";
	    }
	    else
	    {
		$parse .="\n > Found no challenge $NewGame.\n";
		$errs++;
		next;
	    }
	}

	$Player = shift @arg;
	$Player =~ s/,+$//;
	$Player = &GetName($Player);

	push (@newarg, $Player);

	$CmdLine[$CommandCount++] = join(" ",$keyword,@newarg,@arg);

	if (!$Wizard{$Player})
	{
	    $parse .= "\n > $Player is not a recognised wizard.\n";
	    $errs++;
	    next;
	}

        if ($Wizard{$Player}{"User"} ne $User)
        {
            $parse .= "\n > $Player is not a mage controlled by user $User.\n";
            $errs++;
            last;
        }

	if ($Wizard{$Player}{"Busy"} and $keyword ne "DECLINE")
	{
	    $game=$Wizard{$Player}{"Busy"};
	    if ("$game" ne "N$NewGame")
	    {
		if ( $game =~ s/^N// )
		{
		    $parse .= "\n > You are already into game $game\n";
		}
		else
		{
		    $parse .= "\n > You are busy fighting in game $game\n";
		}
		$errs++;
		next;
	    }
	}

	if ($keyword eq "ACCEPT" or
	    $keyword eq "OPPOSE")
	{
	    my ($key) = shift @arg;
	    if (!$key)
	    {
		if ($keyword eq "OPPOSE")
		{
		    $parse .= "\n > You must specify which change you want to oppose.\n";
		    $errs++; next;
		}
		$parse .= " OK\n";
		next;
	    }

	    $key = "\L$key";
	    if ("change" eq $key)
	    {
		my ($Change);
		$Change = shift @arg;

		if (!(grep ( /^$Change$/ , &GetChanges($NewGame) ) ))
		{
		    $parse .= "\n > Found no proposed change no $Change for the new game $NewGame.\n";
		    $errs++;
		    next;
		}
		$parse .= " OK\n";
		next;
	    }

	    if ($key eq "everything")
	    {
		if ($keyword eq "ACCEPT")
		{
		    $parse .= " OK\n";
		    next;
		}
		if ($keyword eq "OPPOSE")
		{
		    $parse .= "\n > Sorry, you cannot automatically oppose everything.
   (Don`t be so negative. Be happy. Praise God. Sing Hallelujah.)\n\n";
		    $errs++;
		    next;
		}
	    }

	    $parse .= "\n > Unknown word: $key\n";
	    $errs++;
	    next;
	}
        $parse .= " OK\n";
        next;
    }

    if ($keyword eq "REGISTER")
    {
	print LOG "parsing $keyword...\n";
	$CmdLine[$CommandCount++] = join(" ",$keyword,@arg);

        if (@arg != 1)
        {
            $parse .= "\n > $keyword expects a name as argument!\n";
            $errs++;
            next;
        }

        if ($arg[0] !~ m/^\w+$/)
        {
            $parse .= "\n > Please use alpha-numeric characters only \n  - other characters are too hard to pronounce!\n";
            $errs++;
            next;
        }

	if ($arg[0] !~ m/^\D/)
	{
            $parse .= "\n > Sorry, but a mage name can not begin with a number.\n";
            $errs++;
            next;
	}

	if (uc $arg[0] eq "YOU")
        {
            $parse .= "\n > Very funny.  Try again....\n";
            $errs++;
            next;
        }

        $parse .= " OK\n"; next;
    }

    if ($keyword eq "RETIRE" or $keyword eq "QUIT")
    {
	print LOG "parsing $keyword...\n";
	$CmdLine[$CommandCount++] = join(" ",$keyword,@arg);

        if (@arg > 1)
        {
            $parse .= "\n > $keyword expects only one mage name as argument.\n";
            $errs++;
            next;
        }

        if ($keyword eq "RETIRE" and @arg != 1)
	{
            $parse .= "\n > $keyword expects a mage name as argument.\n";
            $errs++;
            next;
	}

        $parse .= " OK\n"; next;
    }

    if (($GameName eq "NEW" || $Replay) && ($keyword ne "END"))
    {
        $parse .= "\n > $keyword Can't process ordinary orders with previous command(s)\n > Ignoring the rest of the mail.\n";
        last;
    }

    $CmdLine[$CommandCount++] = join(" ",$keyword,@arg);

    if ($keyword eq "LH" || $keyword eq "RH")
    {
        $DidSomething = 1;

	if ( @arg != 1 )
        {
	    $parse .= "\n > $keyword <gesture char> expected.\n";
	    $errs++; next;
	}

        $arg[0] = &Upcase($arg[0]);

        if (!&IsGesture($arg[0]))
        {
	    $parse .= "\n > '$arg[0]' is not a valid gesture\n";
	    $errs++; next;
	}

        if ((($keyword eq 'RH') && $RightIn) ||
            (($keyword eq 'LH') && $LeftIn))
        {
            $parse .= "\n You've already specified a gesture for $keyword!\n";
	    $errs++; next;
        }

        if ($Info{$Player}{'Afraid'} && ($arg[0] =~ m/[cdfs]/i))
        {
	    if ( !($Info{$Player}{'HastenedTurn'} ||
		   $Info{$Player}{'TimeStoppedTurn'}) )
	    {
		$parse .= "\n You are too afraid to do that!\n";
		$errs++; next;
	    }
	}

        $RightIn = $RightIn || ($keyword eq 'RH');
        $LeftIn = $LeftIn || ($keyword eq 'LH');

        $parse .= " OK\n"; next;
    }

    if ($keyword eq "TURN")
    {
        if (@arg != 1)
        {
            $parse .= "\n $keyword expects a turn number!\n";
            $errs++; next;
        }

        if (uc $arg[0] ne $Turn)
        {
            $parse .= "\n Game $GameName is currently on Turn $Turn!\n";
            $errs++; next;
        }

        $parse .= " OK\n"; next;
    }

    if ($keyword =~ m/^CHO/)
    {
        $DidSomething = 1;

        $Choice = join(" ", @arg);

	if ( @arg < 2 )  # (need at least "<hand sel> name")
        {
	    $parse .= "\n > $Choice doesn't look like <hand> <spell>!\n";
	    $errs++; next;
	}

        $arg[0] = &Upcase($arg[0]);

        if (!($arg[0] =~ m/^((RH)|(LH)|(BH))$/))
        {
            $parse .= "\n $arg[0] is not a valid hand selector\n";
            $errs++; next;
        }

        $parse .= " OK\n"; next;
    }

    if ($keyword eq "TARGET")
    {
        $DidSomething = 1;

	if ( @arg < 2 )
        {
	    $parse .= "\n > TARGET needs hand or monster and Target Name\n";
	    $errs++; next;
	}

        if (!(&Upcase($arg[0]) =~ m/^((RH)|(LH)|(BH))$/) && !&IsMonsterInGame($arg[0]))
        {
            $parse .= "\n $arg[0] is not a valid hand or monster\n";
            $errs++; next;
        }

	$name1 = &GetName(join('',@arg[1..$#arg]));

        if ( !&IsBeing($name1) &&
	     !&IsMonsterInGame($name1) &&
	     ($name1 !~ /No((ne)|(_?one)|(body))/i) )
	{
	    if (grep ($name1 eq $_,@DeadMonsters))
	    {
		$parse .= " OK\n"; next;
	    }
	    $name1 = &BeingDescription($name1);
	    $parse .= "\n $name1 is not a valid target.\n";
	    $errs++; next;
	}

        if ( &IsMonster($arg[0]) &&
            (&GetName($arg[0]) eq $name1) )
        {
            $parse .= "\n Monsters aren't completely stupid, you know!\n";
            $errs++; next;
        }

        $parse .= " OK\n"; next;
    }

    if ($keyword eq "PARALYZE")
    {
        $DidSomething = 1;

	if ( @arg != 2 )
        {
	    $parse .= "\n > PARALYZE needs hand selector and Target Name\n";
	    $errs++; next;
	}

        $arg[0] = &Upcase($arg[0]);

        if (!($arg[0] =~ m/^((RH)|(LH))$/))
        {
            $parse .= "\n $arg[0] is not a valid hand selector\n";
            $errs++; next;
        }

	$name1 = &GetName($arg[1]);
        if (!&IsBeing($name1))
        {
            $parse .= "\n $arg[1] is not a valid target name.\n";
            $errs++; next;
        }
	if (grep(/^$name1$/,@DeadPlayers))
	{
	    $parse .= "\n $name1 has already left the Graven Circle.\n";
            $errs++; next;
	}

        $parse .= " OK\n"; next;
    }

    if ($keyword eq "DIRECT")
    {
        $DidSomething = 1;

	if ( @arg != 3 )
        {
	    $parse .= "\n > DIRECT needs hand selector, Gesture and Target Name\n";
	    $errs++; next;
	}

        $arg[0] = &Upcase($arg[0]);

        if (!($arg[0] =~ m/^((RH)|(LH))$/))
        {
            $parse .= "\n $arg[0] is not a valid hand selector\n";
            $errs++; next;
        }

        $arg[1] = &Upcase($arg[1]);

        if (!&IsGesture($arg[1]))
        {
            $parse .= "\n $arg[1] is not a valid gesture.\n";
            $errs++; next;
        }

	$name2 = &GetName($arg[2]);
        if (!&IsBeing($name2))
        {
            $parse .= "\n $arg[2] is not a valid target.\n";
            $errs++; next;
        }
	if (grep(/^$name2$/,@DeadPlayers))
	{
	    $parse .= "\n $name2 has already left the Graven Circle.\n";
            $errs++; next;
	}

        $parse .= " OK\n"; next;
    }

    if ($keyword eq "PERMANENT")
    {
        $DidSomething = 1;

	if ( @arg != 1 )
        {
	    $parse .= "\n > PERMANENT needs hand selector\n";
	    $errs++; next;
	}

        $arg[0] = &Upcase($arg[0]);

        if (!($arg[0] =~ m/^((RH)|(LH)|(BH))$/))
        {
            $parse .= "\n $arg[0] is not a valid hand\n";
            $errs++; next;
        }

        $parse .= " OK\n"; next;
    }

    if ($keyword eq "DELAY")
    {
        $DidSomething = 1;

	if ( @arg != 1 )
        {
	    $parse .= "\n > DELAY needs hand selector\n";
	    $errs++; next;
	}

        $arg[0] = &Upcase($arg[0]);

        if (!($arg[0] =~ m/^((RH)|(LH)|(BH))$/))
        {
            $parse .= "\n $arg[0] is not a valid hand\n";
            $errs++; next;
        }

        $parse .= " OK\n"; next;
    }

    if ($keyword eq "FIRE")
    {
        $DidSomething = 1;

	if ( @arg != 0 )
        {
	    $parse .= "\n > FIRE has no parameters\n";
	    $errs++; next;
	}

        $parse .= " OK\n"; next;
    }

    if ($keyword eq "SAY")
    {
        $DidSomething = 1;

	if ( @arg == 0 )
        {
	    $parse .= "\n > SAY what?\n";
	    $errs++; next;
	}

        $parse .= " OK\n"; next;
    }

	 if ($keyword eq "SPELLBOOK")
	 {
	     $parse .= " OK\n"; next;
	 }

    $parse .= " Not understood\n";
    $errs++;
}

if ($isincomment)
{
    $parse .= "No END CUT command found!\n\n";
    $errs++;
}

if ($NeedsEnd)
{
    $parse .= "No END command found!\n\n";
    $errs++;
}

$MessageOfToDay = "";
if (open(MOTD, "$Home/motd.txt"))
{
    undef $/;
    $MessageOfToDay = <MOTD>;
    $/="\n";

    close MOTD;
}

if (defined($SequenceNumber))
{
    $MessageOfToDay .= "(Turn: $Turn  Seq: $SequenceNumber Ver: $Revision)\n\n";
}
else
{
    $MessageOfToDay .= "(Ver: $Revision)\n\n";
}

if ($gmAddr eq $plrAddr)
{
# don't send mail to ourselves (e.g. when cleanup.pl sends GAME command)
    open(MAIL,">>$LogDir/to.$gmAddr.log") || die "Could not open $LogDir/to.$gmAddr.log\n$!\n";
}
else
{
    &OpenMail(MAIL,$plrAddr);
}

print MAIL $SubjectLine;
print MAIL $MessageOfToDay;

if ( $errs )
{
    print MAIL $parse;
    my $s = "";
    $s = "s" if $errs>1;
    print MAIL "\n$errs error$s detected - no orders processed\n\n";
    close MAIL;
    close LOG;
    flock(LOCK,8);
    close(LOCK);
    exit 0;
}

if ( !($User || $NoUserOK) )
{
    print MAIL $parse;
    print MAIL "
No USER or NEWUSER command found as first command!

";
    close MAIL;
    close LOG;
    flock(LOCK,8);
    close(LOCK);
    exit 0;
}


if ( !$GameName )
{
    print MAIL $parse;
    print MAIL "\n Couldn't work out what game you meant!\n";
    print MAIL " Were your orders missing a GAME or MAGE command?\n\n";
    print MAIL "No orders processed.\n\n";

    close MAIL;
    close LOG;
    flock(LOCK,8);
    close(LOCK);
    exit 0;
}

print MAIL "$parse\n\nNo errors detected.\n\n";

print LOG "Processing...\n";

print MAIL "Processing...\n\n";

$Status_info_OK = 0;

COMMAND:
for($line=0; $line<@CmdLine; $line++)
{
    $Command = $CmdLine[$line];
    @arg = split(/[\n\t ]+/, $Command);
    $keyword = shift(@arg);
    $keyword = "\U$keyword";
    $h = "$Command\n >";

    if ($keyword eq "TEST_COMMAND")
    {
        print "Noticed a test command!\n";
        print STDERR "Noticed a test command on STDERR!\n";
        print MAIL "Printed something on STDOUT and STERR for you!\n";
        next;
    }

    if ($keyword eq "RULES" || $keyword eq 'HELP')
    {
	if ($arg[0])
	{
	    $arg[0] = &Num($arg[0]); #Just in case the argument is not numeric
        }

	if ($arg[0] and $arg[0] < $SensibleLinesPerEmail) 
	{
	    print MAIL "$arg[0] lines per email?

 ... very funny.  

Well... the rules are about 1800 lines long...
    
    ... so how about trying a number bigger than $SensibleLinesPerEmail!
    
";
	    next;
	}

	open(RULES, "$Home/rules.txt") || die $! ;
	
        print MAIL "A copy of the rules is on its way to you!\n";
        
        my($part_number) = 1;
        my($line_number) = 1;

        open(RULE_MAIL,"|$sendmail -f$gmAddr -F\"$gmName\" $plrAddr");
        print RULE_MAIL "To: $plrAddr\n";
        print RULE_MAIL "Subject: Rules of Combat on Firetop Mountain";
        print RULE_MAIL " (Part $part_number)" if $arg[0];
        print RULE_MAIL "\n\n";

        while(<RULES>)
        {
            if ($arg[0] and ($line_number % $arg[0] == 0))
            {
                close(RULE_MAIL);
                $part_number++;

                open(RULE_MAIL,"|$sendmail -f$gmAddr -F\"$gmName\" $plrAddr");
                print RULE_MAIL "Subject: Rules of Combat on Firetop Mountain (Part $part_number)\n\n";
            }

            print RULE_MAIL;
            $line_number++;
        }

        close RULES;
        close RULE_MAIL;

        print MAIL "(The rules have been mailed in $part_number parts)\n\n"
            if ($part_number > 1);

        next;
    }

    if ($keyword eq "FAQ")
    {
        open(FAQ, "$Home/faq.txt") || die $! ;

        print MAIL "A copy of the FAQ is on its way to you!\n";

        open(FAQ_MAIL,"|$sendmail -f$gmAddr -F\"$gmName\" $plrAddr");

        print FAQ_MAIL "Subject: Firetop Mountain Frequently Asked Questions\n\n";

        while(<FAQ>)
        {
            print FAQ_MAIL;
        }

        close FAQ;
        close FAQ_MAIL;

        next;
    }

    if ($keyword eq "NEWUSER")
    {
	my ($NewUser) = &GetName("\L$arg[0]");

	next unless &CreateUser ($NewUser,$arg[1],$plrAddr);

	print MAIL "$NewUser has been registered as a user at Firetop Mountain.\n";
        # May be let the GM know that a new person has registered...
#        print "$NewUser has been registered as a user at Firetop Mountain.\n";

	# Add the new user to the FM-Users mailing list.
	&SendEsquireMail("subscribe",$Users{$NewUser}{'Address'});

        $ShowScores = "all";
        next;
    }

    if ($keyword eq "STATS")
    {
        if (!$arg[0])
        {
            @ShowStats = &StatsGroups;
        }
        else
        {
            @ShowStats = @arg;
        }
	next;
    }

    if ($keyword eq "CHALLENGES")
    {
        $ShowChallenges = 1;
        next;
    }

    if ($keyword eq "SPELLS")
	 {
	     $ShowSpells = 1;
		  next;
	 }

    if ($keyword eq "SCORES" ||
        $keyword eq "STANDINGS")
    {
        if (!$arg[0])
        {
            $ShowScores = "all";
        }
        elsif ($arg[0] =~ m/^duel$/i || $arg[0] =~ m/^melee$/i)
        {
            $ShowScores .= $arg[0];
        }
        elsif ($GameType)
        {
            $ShowScores .= $GameType;
        }
        else  # well, we could have done better checking on the arg,
        {     # but who really cares?
            $ShowScores = "all";
        }
        next;
    }

    if ($keyword eq "GAMES" ||
        $keyword eq "LIST")
    {
        $ShowGames = 1;
	push (@GamesToShow,@arg);
        next;
    }

    if ($keyword eq "RESEND") 
    {
	my $ReportCommand;

	my $LogFileName = &LogFileName($Users{$User}{'Address'});

	if(!open(REPORTS, "$LogFileName"))
	{
	    print MAIL "There seems to be no record of reports to send to you!\n";
	    next;
	}

	# slurp it in - its probably big, but who cares...
	my (@ReportText) = <REPORTS>;

	# split it into emails

	my ($Report) = 0;
	my @Reports;

	for (my $line = 0; $line < @ReportText; $line++)
	{
	    if ($line<$#ReportText && $ReportText[$line+1] =~ m/^From: /)
	    {
		$Report++;
	    }

	    $Reports[$Report] .= $ReportText[$line];
	}
	
	# Send it off...

        print MAIL "A resend of your reports is on its way to you.\n";

	defined($arg[0]) and &Num($arg[0]) or $arg[0] = 1;

	$arg[0] = Min($arg[0], $#Reports-1);
	my $Num = 0;

	for (my $Report = $#Reports-$arg[0]; $Report < $#Reports; $Report++)
	{
	    $Num++;
	    open(RESEND_MAIL,"|$sendmail -f$gmAddr -F\"$gmName\" $plrAddr");
	    print RESEND_MAIL 
		"Subject: Resend of Firetop Mountain results ($Num of $arg[0])\n\n";

	    print RESEND_MAIL $Reports[$Report];
	    close RESEND_MAIL;
        }

        next;
    }

    if ($keyword eq "USERS")
    {
	push @UsersArg, [@arg];
	next;
    }

    if ($keyword eq "INFO")
    {
	push @InfoArg, [@arg];
	next;
    }

    if ($keyword eq "SHOW")
    {
	if (-f "$arg[0].ngm")
	{
	    print MAIL &DisplayNewGameState($arg[0]);
	    next;
	}

        $fh = HISTORY;
        if (!open($fh, "$arg[0].hst"))
        {
            print MAIL "$h Sorry - there is no record for Battle $arg[0].\n";
            next;
        }

        $InProgress = -f "$arg[0].gm";

        print MAIL &GameReport($fh, $InProgress);
        print MAIL "\n";
        next;
    }

    if ($keyword eq "DESCRIBE")
    {
	if (-f "$arg[0].ngm")
	{
	    print MAIL &DisplayNewGameState($arg[0]);
	    next;
	}

        if (!open(DESC, "$arg[0].dsc"))
        {
            print MAIL "$h Sorry - there is no record for Battle $arg[0].\n";
            next;
        }

        if (-f "$arg[0].gm")
        {
            while(<DESC>)
            {
                print MAIL unless m/^!/;
            }
        }
        else
        {
            while(<DESC>)
            {
                s/^!//;
                print MAIL;
            }
        }
        next;
    }

    last unless $User;

    if ($keyword eq "USER")
    {
	next;
    }

    if ($keyword eq "CHANGEUSER")
    {
	my ($ToUser) = &GetName("\L$arg[0]");

	next unless &CreateUser($ToUser,
				$Users{$User}{'Password'},
				$Users{$User}{'Address'});

	print MAIL "The user $User magically transforms into user $ToUser.\n";
	print "The user $User magically transforms into user $ToUser.\n";

	foreach $wiz (@WizardNames)
	{
	    next unless $Wizard{$wiz}{'User'} eq $User;
	    $Wizard{$wiz}{'User'} = $ToUser;
	}
	$Users{$ToUser}{'Duels'} = $Users{$User}{'Duels'};
	$Users{$ToUser}{'Melees'} = $Users{$User}{'Melees'};
	$Users{$ToUser}{'Mages'} = $Users{$User}{'Mages'};

	$Users{$User}{'Index'} = -1;
	$User = $ToUser;
	next;
    }

    if ($keyword eq "VACATION")
    {
	&OnVacation(@arg);
	next;
    }

    if ($keyword eq "REGISTER")
    {
        $Name = &GetName($arg[0]);

        if ($Wizard{$Name}{'User'})
        {
	    print MAIL "$h $Name is already registered, sorry.\n\n";
	    print MAIL "An imposter posing as $Name was turned away from Firetop Mountain!\n";
	    next COMMAND;
        }
	
	# Cannot use the name of another user as a wizard name
	if (($Name ne $User) && defined($Users{$Name}))
	{
	    print MAIL "$h $Name is the user name of another user, sorry.\n\n";
	    print MAIL "An imposter posing as $Name was turned away from Firetop Mountain!\n";
	    next COMMAND;
	}

	if ('Referee' eq $Name)
	{
	    print MAIL "$h You are NOT the referee, I am!\n\n";
	    print MAIL "As you are thrown head first down the mountain,\n" .
		       "you hear the old $gmName grumble to himself\n" .
		       "\"Young wizards now days, pays no respect at all.\"\n\n";
	    next;
	}

        if (&IsMonster($Name))
        {
            print MAIL "$h Everyone knows monsters can't cast spells!\n\n";
            print MAIL "A Monster posing as a Wizard was turned away from Firetop Mountain!\n";
            next;
        }

        if ($Name =~ m/janitor/i)
        {
            print MAIL "$h The Firetop Mountain Janitor sidles over and looks you up and down...\n";
            print MAIL "\"There's only room for one Janitor on this Mountain, and it ain't you, punk!\",\n";
            print MAIL " he says, and suddenly you find yourself a long way away...\n";
            next;
        }

	if ( $arg[0] =~ /no((ne)|(_?one)|(_?body))/i or $Name eq "All" )
	{
	    print MAIL "$h $arg[0] is not a valid name.\n\n";
	    next;
	}

        push(@WizardNames, $Name);

        $Wizard{$Name}{'Dead'} = 0;

        $Wizard{$Name}{"User"} = $User;

        $Wizard{$Name}{"DuelScore"} = 0;
        $Wizard{$Name}{"MeleeScore"} = 0;
        $Wizard{$Name}{"Battles"} = 0;
        $Wizard{$Name}{"Busy"} = 0;
        $Wizard{$Name}{"Retired"} = 0;

        $Users{$User}{'Mages'} += 1;

        print MAIL "$Name has been admitted to Firetop Mountain.\n";

        # Let the GM know that a new person has registered...
#        print STDERR "$Name has been admitted to Firetop Mountain.\n";

        &NoteActivity($Name);

        next;
    }

    if ($keyword eq "RETIRE" or $keyword eq "QUIT")
    {
        if ($keyword eq "QUIT" and !$arg[0])
        {
            if (&WizardsOfUser($User,@WizardNames))
            {
                print MAIL "\nYou can not quit while you still have mages.\n(Use \"QUIT <Mage Name>\" if you want to kill one of your own mages.\n)";
                next;
            }

            $Users{$User}{'Index'} = -1;
            &SendEsquireMail("unsubscribe", $Users{$User}{'Address'});
	    
            print MAIL "\nYour user $User at FiretopMountain has now been deleted.\n
We hope you enjoyed playing Firetop Mountain. Should you ever want
to play again you are always welcome to register again as a new user.\n";
            next;
        }

        $Name = &GetName($arg[0]);

        if (!$Wizard{$Name})
        {
            print MAIL "$h $Name is not a registered combatant\n";
            next;
        }

        if ($Wizard{$Name}{"User"} ne $User)
        {
            print MAIL "Mage $Name do not belong to user $User!\n";
            last;
        }

        if ($Wizard{$Name}{'Busy'})
        {
	    my($game) = $Wizard{$Name}{'Busy'};
	    if ($game =~ s/^N(.*)$/$1/)
	    {
		print MAIL "You cannot "."\L$keyword"." now, when you have accpted challenge $game!\n";
	    }
	    else
	    {
		print MAIL "You'll need to finish your battle $game before you can "."\L$keyword"."\n";
	    }
            next;
        }

        &DeclineAll($Name,0); #Decline all pending challenges

	if ($keyword eq "RETIRE" &&
            ($Wizard{$Name}{'DuelScore'}+$Wizard{$Name}{'MeleeScore'} > 0))
	{
 	    $Wizard{$Name}{"Retired"} = 1;
            print MAIL "$Name retires greacefully and goes to sit with the other mages resting\nin the shade of the great Menhirs surrounding the Circle.\n";
            &NoteActivity($Name);
        }
        else
        {
            print MAIL "$Name leaves Firetop Mountain, having survived the experience, but\nnot ready to battle further at this stage.\n";
            $Wizard{$Name}{'Dead'} = 1; 
        }
        $ShowScores = "all";

        next;
    }

    if ($keyword eq "SUBSCRIBE")
    {
	while ($GN = shift @arg)
	{
	    if ($GN =~ s/^N//)
	    {
		&ReadNewGame($GN);
		if (grep($_ eq $User,@Subscribers))
		{
		    print MAIL "You are already among those that will receive updates on game $GN.\n";
		}
		else
		{
		    push (@Subscribers, $User);
		    &WriteNewGame($GN);
		    print MAIL "You are now subscribing to game $GN.\n";
		}
	    }
	    else
	    {
		&GetGameInfo($GN, 'no_one');
		if (grep($_ eq $User,(@Subscribers, @Players)))
		{
		    print MAIL "You are already reciving updates on game $GN.\n";
		}
		else
		{
		    push (@Subscribers, $User);
		    &WriteGameInfo($GN);
		    print MAIL "You are now subscribing to game $GN.\n";
		}
	    }
	}
    }

    if ($keyword eq "NEWGAME")
    {
        $Wizard{$arg[0]}{"Retired"} = 0;
        &NoteActivity($arg[0]);
	&NewGame(@arg);
	next;
    }

    if ($keyword eq "CHANGEGAME")
    {
        &NoteActivity($arg[1]);
	&ChangeNewGame(@arg);
	next;
    }

    if ($keyword eq "ACCEPT")
    {
        $Wizard{&GetName($arg[1])}{"Retired"} = 0;
        &NoteActivity(&GetName($arg[1]));
	&Accept(@arg);
        next;
    }

    if ($keyword eq "OPPOSE")
    {
        &NoteActivity(&GetName($arg[1]));
	&Oppose(@arg);
        next;
    }

    if ($keyword eq "DECLINE")
    {
	&Decline(@arg);
        next;
    }

    if ($keyword eq "WITHDRAW")
    {
	&Withdraw(@arg);
        next;
    }


    if ($keyword eq "MESSAGE")
    {
        my ($From) = &GetName(shift @arg);
	my (%ToHash, $ToUser, $mage, $Name, $Message, $FromAddr) = ();

	$Message = shift @Messages;
	if ($Referee)
	{
	    $FromAddr = $MaintainerAddress;
	}
	else
	{
	    $FromAddr = $Users{$User}{'Address'};
	}

        foreach $mage (@arg)
        {
            $Name = &GetName($mage);
            if ($Users{$Name})
            {
                $ToUser = $Name;
            }
            else
            {
	        $ToUser = $Wizard{$Name}{'User'};
            }
	    next if $ToHash{$ToUser};
	    $ToHash{$ToUser}++;

            &OpenMail(MSGMAIL, $Users{$ToUser}{'Address'});
            print MSGMAIL "Subject: A Firetop Mountain Message from $From
Reply-to: ". $FromAddr . "

A message from: $From
Addressed to: @arg
Reads:

";

            print MSGMAIL $Message . "\n";

            close MSGMAIL;
        }
        print MAIL "Message to @arg from $From sent.\n";
        next;
    }

    if ($keyword eq "ANNOUNCE")
    {
	my ($From, $ReplyTo, $ToUser, @ToList, $Message);

	if ($Referee)
	{
	    $From = "the Referee";
	    $ReplyTo = $MaintainerAddress;
	}
	else
	{
	    $From = $User;
	    $ReplyTo = $plrAddr;
	}

	@ToList = @{shift @Recipients};
	$Message = shift @Messages;

        foreach $ToUser (@ToList)
        {
            &OpenMail(MSGMAIL, $Users{$ToUser}{'Address'});
            print MSGMAIL "Subject: A Firetop Mountain Announcement from $From
Reply-to: $ReplyTo

A message from: $From
Addressed to players of: @arg
Reads:

";
            print MSGMAIL $Message . "\n";
            close MSGMAIL;
        }
        print MAIL "Announcement to @arg sent.\n";
        next;
    }

    if ($keyword eq "ADDRESS")
    {
	&SendEsquireMail ("unsubscribe", $Users{$User}{'Address'});
        $Users{$User}{'Address'} = $arg[0];
	&SendEsquireMail ("subscribe", $Users{$User}{'Address'});
	print MAIL "Address for $User changed to $arg[0]\n";
    }

    if ($keyword eq "PASSWORD")
    {
	next if $Referee; #The referee's passwd is in the code
        $Users{$User}{'Password'} = $arg[0];
        print MAIL "Password for $User changed to $arg[0]\n";
    }

    next if (!$GameName || ($GameName eq "NEW"));

    if ($keyword eq "REPLAY")
    {
	next;
    }

    if ($keyword eq "LH" || $keyword eq "RH")
    {
        if ($Info{$Player}{'State'} ne "orders")
        {
            print MAIL "$h Already got gestures from $Info{$Player}{'Name'}\n";
            print MAIL "   (ignoring)\n";
            next;
        }

        $OtherHand = ($keyword eq 'RH') ? 'LH' : 'RH';
        $arg[0] = &Upcase($arg[0]);

        $Info{$Player}{$keyword} .= $arg[0];
	$Info{$Player}{"LastGesture$keyword"} = $arg[0];

        if (length($Info{$Player}{$keyword}) >length($Info{$Player}{$OtherHand}))
        {
            # wait for the other hand to be sumitted
            next;
        }

        $RHMove = $GestureDesc{$Info{$Player}{'LastGestureRH'}};
        $LHMove = $GestureDesc{$Info{$Player}{'LastGestureLH'}};

        $Event = "$Player prepares to $LHMove your left hand,\n";
        $Event .= "$Player prepares to $RHMove your right...\n\n";

        print MAIL &SecondPerson($Event, $Player);

        @RightSpells = &CheckForCastRight($Info{$Player}{'RH'},
                                          $Info{$Player}{'LH'}, $Player);
        @LeftSpells = &CheckForCastLeft($Info{$Player}{'RH'},
                                        $Info{$Player}{'LH'}, $Player);
        @BothSpells = &CheckForCastBoth($Info{$Player}{'RH'},
                                        $Info{$Player}{'LH'}, $Player);

        $spells = &SetSpells($Player);

# added 13/6/2001 -ak
        $Event = "";
        if ($Info{$Player}{'LeftSpell'} !~ /^choose$|^none$/) {
            $Event .= "You prepare to cast $Info{$Player}{'LeftSpell'} with your left hand.\n\n"
        }
        if ($Info{$Player}{'RightSpell'} !~ /^choose$|^none$/) {
            $Event .= "You prepare to cast $Info{$Player}{'RightSpell'} with your right hand.\n\n"
        }
        if ($Info{$Player}{'BothSpell'} !~ /^choose$|^none$/) {
            $Event .= "You prepare to cast $Info{$Player}{'BothSpell'} with both of your hands.\n\n"
        }
        print MAIL $Event if $Event;
# end added 13/6/2001 -ak

	$spells =~ s/^/ /gm;
	if ($Info{$Player}{'State'} eq 'choose-spell')
        {
            print MAIL "\nYou have the choice of the following spells this round:\n";
	    print MAIL $spells;
            print MAIL "\nNow expecting a spell choice...\n\n";
        }
    }

    if ($keyword =~ m/^CHO/)
    {
        $Hand = &Upcase(shift(@arg));

        if ($Info{$Player}{'State'} ne "choose-spell")
        {
            if ($Hand eq "RH")
            {
                print MAIL "Your Right Hand spell is '$Info{$Player}{'RightSpell'}' - you have no choice.\n";
            }
            if ($Hand eq "LH")
            {
                print MAIL "Your Left Hand spell is '$Info{$Player}{'LeftSpell'}' - you have no choice.\n";
            }
            if ($Hand eq "BH")
            {
                print MAIL "Your Both-Hands spell is '$Info{$Player}{'BothSpell'}' - you have no choice.\n";
            }
            next;
        }

        $TheirChoice = join(" ", @arg);

        $Choice = &GetSpellName($TheirChoice);

        if ($Choice eq 'none')
        {
            print MAIL " $TheirChoice isn't a valid spell!\n";
            next;
        }

        @RightSpells = &CheckForCastRight($Info{$Player}{'RH'},
                                          $Info{$Player}{'LH'}, $Player);
        @LeftSpells = &CheckForCastLeft($Info{$Player}{'RH'},
                                        $Info{$Player}{'LH'}, $Player);
        @BothSpells = &CheckForCastBoth($Info{$Player}{'RH'},
                                        $Info{$Player}{'LH'}, $Player);

        $GotChoice = 0;
        if ($Hand eq "RH")
        {
            if ($Info{$Player}{'RightSpell'} ne 'choose')
            {
                print MAIL "You have no choice about your Right Hand spell: '$Info{$Player}{'RightSpell'}'.\n";
                next;
            }

            foreach $spell (@RightSpells)
            {
                if (&Upcase($spell) eq &Upcase($Choice))
                {
                    $Info{$Player}{'RightSpell'} = $spell;
                    $Info{$Player}{'BothSpell'} = 'none';
                    $GotChoice = 1;
                    print MAIL "You chose $Choice for your Right Hand.\n";
                }
            }
        }
        elsif ($Hand eq "LH")
        {
            if ($Info{$Player}{'LeftSpell'} ne 'choose')
            {
                print MAIL "You have no choice about your Left Hand spell: '$Info{$Player}{'LeftSpell'}'.\n";
                next;
            }

            foreach $spell (@LeftSpells)
            {
                if (&Upcase($spell) eq &Upcase($Choice))
                {
                    $Info{$Player}{'LeftSpell'} = $spell;
                    $Info{$Player}{'BothSpell'} = 'none';
                    $GotChoice = 1;
                    print MAIL "You chose $Choice for your Left Hand.\n";
                }
            }
        }
        elsif ($Hand eq "BH")
        {
            if ($Info{$Player}{'BothSpell'} ne 'choose')
            {
                print MAIL "You have no choice about your Both Hands spell: '$Info{$Player}{'BothSpell'}'.\n";
            }

            foreach $spell (@BothSpells)
            {
                if (&Upcase($spell) eq &Upcase($Choice))
                {
                    $Info{$Player}{'BothSpell'} = $spell;
                    $Info{$Player}{'RightSpell'} = 'none';
                    $Info{$Player}{'LeftSpell'} = 'none';
                    $GotChoice = 1;
                    print MAIL "You chose $Choice for your both-hands spells.\n";
                }
            }
        }

        if (!$GotChoice)
        {
            print MAIL "$h This is not one of your choices!\n";
        }

        if (($Info{$Player}{'BothSpell'} ne 'choose') &&
            ($Info{$Player}{'RightSpell'} ne 'choose') &&
            ($Info{$Player}{'LeftSpell'} ne 'choose'))
        {
            $Info{$Player}{'State'} = 'orders_in';
        }
    }

    if ($keyword eq "TARGET")
    {
        $Select = shift(@arg);

        $Monster = &GetName($Select);
        $Hand = &Upcase($Select);

	foreach $hand ('Both','Right','Left')
	{
	    if ($Hand eq $HandMap{$hand})
	    {
		$RaiseDead = $Info{$Player}{$hand.'Spell'} eq 'Raise Dead';
		last;
	    }
	}

        $t = &GetName(join('',@arg));

	if ($t =~ /No((ne)|(_?one)|(body))/i)
	{
	    $t = "no_one";
	}

        $targ = (($t eq $Player) ?
                 "yourself" : &BeingDescription($t));
	$targ =~ s/$Player is\b/you are/g;


	if ( grep ($targ eq $_,@DeadMonsters) && !$RaiseDead &&
             !($targ =~ /(Fire|Ice)Elemental/ && ${$1."ElementalPresent"}) )
	{
	    print MAIL "$h $targ is a dead monster.\n";
	    if ($Info{$Player}{'State'} eq "orders_in")
	    {
		$Info{$Player}{'State'} = "choose-target";
	    }
            last;
	}

	if (grep(/^$targ$/,@DeadPlayers) && !$RaiseDead)
	{
	    print MAIL "$h $targ has already left the Graven Circle.\n";
            last;
	}

        if ($Hand eq "RH")
        {
            print MAIL "You aim with your Right Hand at $targ.\n\n";
            $Info{$Player}{'RightTarget'} = $t;
        }
        elsif ($Hand eq "LH")
        {
            print MAIL "You aim with your Left Hand at $targ.\n\n";
            $Info{$Player}{'LeftTarget'} = $t;
        }
        elsif ($Hand eq "BH")
        {
            print MAIL "You aim a two hand combination at $targ.\n\n";
            $Info{$Player}{'BothTarget'} = $t;
        }
        else
	{
	    if ($Info{$Player}{'Target'} eq 'no_one')
	    {
		$Info{$Player}{'Target'} = "$Monster=>$t";
	    }
	    else
	    {
		$Info{$Player}{'Target'} =~
		    s/(^|<)$Monster=>[^<]*/$1$Monster=>$t/ or
			$Info{$Player}{'Target'} .= "<$Monster=>$t";
	    }
	    $Monster = &BeingDescription($Monster);
	    $Event = "$Player prepares to direct $Monster\n";
            $Event .= " to attack $targ.\n\n";
            $Event = &SecondPerson($Event, $Player);
	    print MAIL $Event;
	}

        if ($Info{$Player}{'State'} eq 'choose-target')
        {   $Info{$Player}{'State'} = 'orders_in'; }
    }

    if ($keyword eq "PARALYZE")
    {
        $Hand = &Upcase(shift(@arg));

        $t = &GetName($arg[0]);

        if (!$Info{$t}{'Paralyzed'} ||
            ($Info{$t}{'Paralyser'} ne $Player))
        {
            print MAIL "$h You don't seem to have control over $t.\n";
            next;
        }

        if ($Info{$t}{'ParalyzedRight'} || 
	    $Info{$t}{'ParalyzedLeft'})
        {
            print MAIL "$h One of $t"."'s hands is already stuck (and will be again this turn)!\n";
            next;
        }

        $targ = (($t eq $Player) ? "yourself" : $t);

        if ($Hand eq "RH")
        {
            print MAIL "You paralyze the Right Hand of $targ.\n\n";
            $Info{$t}{'ParalyzedRight'} = 1;
        }
        else
        {
            print MAIL "You paralyze the Left Hand of $targ.\n\n";
            $Info{$t}{'ParalyzedLeft'} = 1;
        }
    }

    if ($keyword eq "DIRECT")
    {
        ($Hand, $Gesture, $Victim)  = @arg;

        $Hand = &Upcase($Hand);
        $Gesture = &Upcase($Gesture);
        $Victim = &GetName($Victim);

        if (!$Info{$Victim}{'Charmed'} ||
            ($Info{$Victim}{'Controller'} ne $Player))
        {
            print MAIL "You don't seem to have control over $Victim.\n";
            next;
        }

        if ($Info{$Victim}{'CharmedRight'} || $Info{$Victim}{'CharmedLeft'})
	{
            print MAIL "You have already directed one of $Victim"."'s hands.\n";
            next;
        }

        $targ = (($Victim eq $Player) ? "yourself" : $Victim);

        if ($Hand eq "RH")
        {
            print MAIL "You attempt to direct the Right Hand of $targ.\n\n";
            $Info{$Victim}{'CharmedRight'} = $Gesture;
        }
        else
        {
            print MAIL "You attempt to direct the Left Hand of $targ.\n\n";
            $Info{$Victim}{'CharmedLeft'} = $Gesture;
        }
    }

    if ($keyword eq "PERMANENT")
    {
        $Hand = &Upcase(shift(@arg));

        if (!$Info{$Player}{'PermanencyPending'})
        {
            print MAIL "$h You don't have the capability for that at the moment.\n";
	    next;
        }

        print MAIL "You apply your reserve of power to make a spell permanent.\n";
        $Info{$Player}{$Hand.'Duration'} = 999;
        $Info{$Player}{'PermanencyPending'} = 0;
    }

    if ($keyword eq "DELAY")
    {
        $Hand = &Upcase(shift(@arg));

        if (!$Info{$Player}{'DelayPending'})
        {
            print MAIL "$h You don't have the capability for that at the moment.\n";
	    next;
        }

        print MAIL "You apply your reserve of power to bank up a spell.\n";

        $Info{$Player}{$Hand.'Save'} = 1;
        $Info{$Player}{'DelayPending'} = 0;
    }

    if ($keyword eq "FIRE")
    {
        if ($Info{$Player}{'SavedSpell'} eq 'none')
        {
            print MAIL "$h You don't have a spell saved up to fire.\n";
	    next;
        }

        print MAIL "You prepare to fire your saved up spell...\n";

        $Info{$Player}{'FireSpell'} = $Info{$Player}{'SavedSpell'};
        $Info{$Player}{'FireTarget'} = $Info{$Player}{'SavedTarget'};
        $Info{$Player}{'SavedSpell'} = 'none';
        $Info{$Player}{'SavedTarget'} = 'none';
    }

    if ($keyword eq "SAY")
    {
        $Info{$Player}{'Quote'} = join(" ", @arg);
    }

	 if ($keyword eq "SPELLBOOK")
	 {
		if ($GameName)
		  {
	     print MAIL "SpellBook for Game $GameName:\n";
		  my $maxlength = 0;
		  foreach my $g (sort keys %SpellBook)
		  {
		      $maxlength = length($g) if (length($g) > $maxlength);
		  }
		  foreach my $g (sort keys %SpellBook)
		  {
		      print MAIL "  $g", " " x ($maxlength + 2 - length ($g)), join(", ",@{$SpellBook{$g}}), "\n";
		  }
		  print MAIL "\n";
		  }
		else
		{
		    print MAIL "SpellBook should be after a GAME or MAGE command\n";
		}
	 }

# allows a player can get out of 'choose-target' without doing anything
    if ( ($keyword eq "END") && !$Referee && !$Replay &&
	($Info{$Player}{'State'} eq 'choose-target') )
    {
	$DidSomething = 1;
	$Info{$Player}{'State'} = 'orders_in';
    }

    if (($keyword eq "END") && (($#Players + 1) - ($#DeadPlayers + 1) > 2))
    {
        if (!$Referee && $Info{$Player}{'State'} eq 'orders_in')
	{
	    foreach $hand ('Right','Left','Both')
	    {
	        if ($Info{$Player}{$hand.'Spell'} ne 'none' &&
		    $Info{$Player}{$hand.'Target'} eq 'none')
	        {
	            $spell = $Info{$Player}{$hand.'Spell'};
	            if (!&SelfTarget($spell) && !&UntargettedSpell($spell))
	            {
	                print MAIL "There is no default target for your $hand hand spell ($spell).\n\n";
	                print MAIL "You may target the spell before the round continues.\n\n";
	                $Info{$Player}{'State'} = 'choose-target';
			$Info{$Player}{$hand.'Target'} = 'no_one';
	            }
		}

		next if $hand eq 'Both';

		if (($Info{$Player}{"LastGesture$HandMap{$hand}"} eq '>') &&
		    ($Info{$Player}{"${hand}Target"} eq 'none'))
		{
		    print MAIL "There is no default target for a stab.\n\n";
		    print MAIL "You may target your \L$hand hand before the round continues.\n\n";
		    $Info{$Player}{'State'} = 'choose-target';
		    $Info{$Player}{$hand.'Target'} = 'no_one';
		}
	    }
	}
    }

    if ($keyword eq "GAME" || $keyword eq "MOVE" || $keyword eq "MAGE")
    {
	if ($Referee && !&AllOrdersIn)
	{
	    $Nag = 1; # The Referee wants to nag the players
	    next;
	}

        if (!$Referee)
        {
            &NoteActivity($Player);
            &UpdateVacationFile($Wizard{$Player}{'User'});
        }

        if ($KeepState)
        {
            system("cp $GameName.gm $GameName".".gm.seq$SequenceNumber");

            $DeleteRev = $SequenceNumber - $KeepState;
            if ($DeleteRev > 0)
            {
                unlink("$GameName".".gm.seq$DeleteRev");
            }
        }
        $SequenceNumber++;
	$Nag = 0;
    }

    if (($keyword eq "END") && (&AllOrdersIn || $Nag))
    {
        # Get ready to tell opponent the game is moving on...
	if (!$Replay)
	{
	    @OpponentUsers = @Subscribers;
	    &OpenOpponentMail; #Sets @OpponentUsers
	    &PrintOpponentMail("Subject: Battle $GameName, turn $Turn\n\n");
	    &PrintOpponentMail($MessageOfToDay);
	}
	else
	{
	    @OpponentUsers = ();
	}

        @Events = ();
	$Round = $Turn;
        $TimeStoppedTurn = 0;
        foreach $wiz (@Players)
        {
            $Info{$wiz}{'SeeEvent'} = "";
        }

        # Then do one or more rounds...

	while (&AllOrdersIn && $#Players != $#DeadPlayers)
        {
	    &WriteGameInfo($GameName) unless $Replay;
	    # Save the latest game status before we run the turn
	    # (Necessary for the REPLAY command to work)
	    $NewSpellChoises=0;
	    $NewTargets=0;
	    $Status_info_OK = 0;
            &PrepareForTurn;

            if (!&AllOrdersIn)
            {
		if ($NewSpellChoises)
		{
		    if ($NewSpellChoises>1)
		    {
			&Announce("Enchantments have resulted in wizards having a new choice of spells\n".
				  "The round will resume when these choices have been made...\n\n");
		    }
		    else
		    {
			&Announce("An enchantment has resulted in a wizard having a new choice of spells\n".
				  "The round will resume when this choice has been made...\n\n");
		    }
		}
		else
		{
		    if ($NewTargets>1)
		    {
			&Announce("Enchantments have resulted in wizards having a new chance to target spells.\n".
				  "The round will resume when these targets have been set...\n\n");
		    }
		    else
		    {
			&Announce("An enchantment has resulted in a wizard having a new chance to target spells.\n".
				  "The round will resume when this has been done...\n\n");
		    }
		}
            }
            else
            {
		if (!$Replay)
		{
		    # Save turnstatus that can be used by REPLAY
		    system "cp $GameName.gm $GameName.gm.turn.$Turn";
		}

		&DoRoundActivity;

                $GesturesDone = 0;

                # note that we _can_ exit DoRoundActivity() with both
                # players back to orders_in.  This requires another round
                # to be run... it happens if a player gets hit by Amesia and
                # Haste in the same round.
            }
        }

        # And let them know what happened...
	my ($SeeEvent);
        foreach $ToUser ($User,@OpponentUsers)
        {
	    @Lookers = &WizardsOfUser($ToUser,@Players);

	    $Report = "";
            for $i (0 .. $#Events)
            {
		$SeeEvent = 0;
                if (@Lookers)
                {
		    if ( grep(substr($Info{$_}{'SeeEvent'},$i,1),@Lookers) )
		    {
			$SeeEvent = 1;
		    }
		}
		else
		{
		    $SeeEvent = 1;
		    if (grep(0==substr($Info{$_}{'SeeEvent'},$i,1), @Players ))
		    {
			$SeeEvent = 0;
		    }
		}

		if ($SeeEvent)
                {
		    $Event = $Events[$i];
		    $Event =~ s/^NOT A REAL EVENT\://;
                    $Report .= "$Event\n";
                }
            }

	    $Mail = &ChooseMailHandle($ToUser);

	    if ($#Lookers == 0)
	    {
		#Only one wizard for this user
		print $Mail &SecondPerson($Report, $Lookers[0]);
	    }
	    else
	    {
		print $Mail $Report;
	    }
        }

	last if $Replay;

        &PrintOpponentMail("\n\n");
        foreach $ToUser (@OpponentUsers)
	{
	    @Lookers = &WizardsOfUser($ToUser,@Players);
	    $Mail = &ChooseMailHandle($ToUser);
	    print $Mail &GameStatus(@Lookers);
	}

	&PrintOpponentMail(&Scores($GameType)) if $ShowScores;
	&CloseOpponentMail;

#	popTask($GameName);
#	pushTask($Movetime,$GameName,"TimeOut");

	&StartDescription(@Players) if (! -f"$GameName.dsc");

	if (!$Nag && ($#Events>0) && open(DESC, ">>$GameName.dsc"))
	{
	    print DESC "In Round $Round:\n";

	    for $i (1 .. $#Events)
	    {
		$Report = "$Events[$i]";
		next if $Report =~ m/^NOT A REAL EVENT\:/;
		$Report =~ s/\n\n/\n/g; #No double newlines in the report
		$all_see = 1;
		if (grep(0==substr($Info{$_}{'SeeEvent'},$i,1), @Players ))
		{ $all_see = 0; }
		if (!$all_see)
		{
		    $Report =~ s/^(.)/!$1/gm;
		}
		print DESC $Report;
	    }
	    print DESC "\n";
	    close DESC;
	}
    }
}


print LOG "Done.\n";
print MAIL "\nDone.\n\n";

if (($GameName ne 'NEW') && ($GameName ne 'NONE'))
{
    @Lookers = &WizardsOfUser($User,@Players);
    print MAIL &GameStatus(@Lookers) ;
}

if (!$Replay)
{
    &WriteGameInfo($GameName) if (($GameName ne 'NEW') &&
				  ($GameName ne 'NONE') &&
				  $DidSomething);

    &FinishGame if $FinishGame;

    &WriteWizards;
    &WriteUsers;
    &WriteStats;
}

print MAIL &Scores("Duel") if ($ShowScores =~ m/duel/i ||
                               $ShowScores =~ m/all/i);
print MAIL &Scores("Melee") if ($ShowScores =~ m/melee/i ||
                               $ShowScores =~ m/all/i);
print MAIL &StatsListing(@ShowStats) if (@ShowStats);

my $Arg;
foreach $Arg (@UsersArg)
{
    &UserList(@{$Arg});
}

foreach $Arg (@InfoArg)
{
    &InfoCommand(@{$Arg});
}

print MAIL &GameList(@GamesToShow) if $ShowGames;

print MAIL &NewGameList if $ShowChallenges;

print MAIL &SpellList if $ShowSpells;

close(MAIL);
close(LOG);

flock(LOCK,8);
close(LOCK);

exit 0;
#----------------------------------------------------------------------

sub PrepareForTurn
{
    # Is this a special turn?
    foreach $wiz (@Players)
    {
	next if grep(/^$wiz$/,@DeadPlayers);
	if ($Info{$wiz}{'HastenedTurn'})
	{
	    $HastenedTurn = 1;
	}

	if (!$HastenedTurn && $Info{$wiz}{'TimeStoppedTurn'})
	{
	    $TimeStoppedTurn = 1;
	}
    }

    foreach $wiz (@Players)
    {
	next if grep(/^$wiz$/,@DeadPlayers);
	next if $TimeStoppedTurn || $HastenedTurn;
	if (!$GesturesDone)
	{
	    $Info{$wiz}{'CheckNewSpells'} = "";

	    if ($Info{$wiz}{'Confused'})
	    {
		$badhand = (&Rnd(2) ?  'RH' : 'LH');
		$newgesture = substr($Gestures, &Rnd(6), 1);
		if ($newgesture eq $Info{$wiz}{"LastGesture$badhand"})
		{
		    $Info{$wiz}{'Confused'} .= 'Lucky';
		}
		else
		{
		    substr($Info{$wiz}{$badhand}, -1, 1) = $newgesture;
		    $Info{$wiz}{"LastGesture$badhand"} = $newgesture;
		    $Info{$wiz}{'CheckNewSpells'} .= $badhand;
		}
	    }

	    if ($Info{$wiz}{'Paralyzed'} > 0 &&
		!$Info{$wiz}{'ParalyzedLeft'} &&
		!$Info{$wiz}{'ParalyzedRight'})
	    {
		# paralyzer didnt select a hand to paralyze

		$Hand = (&Rnd(2) ?  'RH' : 'LH');

		if ($Hand eq "RH")
		{
		    &NoteThat("$wiz"."'s Right Hand is stuck!\n",
			      $wiz);

		    $Info{$wiz}{'ParalyzedRight'} = 1;
		}
		else
		{
		    &NoteThat("$wiz"."'s Left Hand is stuck!\n",
			      $wiz);
		    $Info{$wiz}{'ParalyzedLeft'} = 1;
		}
	    }

	    foreach $hand ('Right','Left')
	    {
		$h = $HandMap{$hand};

                if ($Info{$wiz}{"Paralyzed$hand"})
                {
		    $gestures = $Info{$wiz}{$h};
		    chop $gestures;
                    $paralyz = $Paralyzed{&LastGesture($gestures)};

                    if ($Info{$wiz}{"LastGesture$h"} eq $paralyz)
                    {
			$Info{$wiz}{"Paralyzed$hand"} .= 'Lucky';
                    }
                    else
                    {
			$Info{$wiz}{"LastGesture$h"} = $paralyz;
                        substr($Info{$wiz}{$h}, -1, 1) = $paralyz;
                        $Info{$wiz}{'CheckNewSpells'} .= $h;
                    }
		}

                if ($Info{$wiz}{"Charmed$hand"})
                {
                    if ($Info{$wiz}{"Charmed$hand"} eq
			$Info{$wiz}{"LastGesture$h"})
                    {
			$Info{$wiz}{"Charmed$hand"} .= 'Lucky';
		    }
                    else
                    {
			$Info{$wiz}{"LastGesture$h"} =
                            $Info{$wiz}{"Charmed$hand"};
                        substr($Info{$wiz}{$h}, -1, 1) =
                            $Info{$wiz}{"LastGesture$h"};
                        $Info{$wiz}{'CheckNewSpells'} .= $h;
                    }
		}
	    }
	}
    }

    $GesturesDone = 1;
    # Now see if any spells have changed due to enchantments...

    foreach $wiz (@Players)
    {
	next if grep(/^$wiz$/,@DeadPlayers);
	if ($Info{$wiz}{'CheckNewSpells'})
	{
	    $ChooserMail = &ChooseMailHandle($Wizard{$wiz}{'User'});

	    $newstab = "";

            # Revise checking for spells when a hand gesture
            # has been changed by enchantment

            # Get spells available with new gestures
            my @newLHSpells = CheckForCastLeft($Info{$wiz}{'RH'},
                                            $Info{$wiz}{'LH'}, $wiz);
            my @newRHSpells = CheckForCastRight($Info{$wiz}{'RH'},
                                            $Info{$wiz}{'LH'}, $wiz);
            my @newBHSpells = CheckForCastBoth($Info{$wiz}{'RH'},
                                            $Info{$wiz}{'LH'}, $wiz);

            # Wiz was attempting a BH spell
            if ($Info{$wiz}{'BothSpell'} !~ /^none$/)
            {
                # Can still cast spell?  Leave things alone
                if (grep ($_ eq $Info{$wiz}{'BothSpell'}, @newBHSpells))
                {
                    @BothSpells = ($Info{$wiz}{'BothSpell'});
                    @RightSpells = ('none');
                    @LeftSpells = ('none');
                }
                else
                {
                    @BothSpells = @newBHSpells;
                    @RightSpells = @newRHSpells;
                    @LeftSpells = @newLHSpells;
                }
            }
            else
            {
		@BothSpells = @newBHSpells;

                # If user can still cast same single hand spells,
                # leave them alone.  Otherwise allow new spells.
                if (grep ($_ eq $Info{$wiz}{'RightSpell'}, @newRHSpells))
                {
                    @RightSpells = ($Info{$wiz}{'RightSpell'});
                }
                else
                {
                    @RightSpells = @newRHSpells;
                }
                if (grep ($_ eq $Info{$wiz}{'LeftSpell'}, @newLHSpells))
                {
                    @LeftSpells = ($Info{$wiz}{'LeftSpell'});
                }
                else
                {
                    @LeftSpells = @newLHSpells;
                }
            }

	    foreach $hand ('Right','Left')
	    {
                $newstab = "\L$hand hand" 
                    if ($Info{$wiz}{"LastGesture$h"} eq '>');
	    }

	    ($oldRightSpell,$oldLeftSpell,$oldBothSpell) =
		($Info{$wiz}{'RightSpell'},
		 $Info{$wiz}{'LeftSpell'},
		 $Info{$wiz}{'BothSpell'});

	    $spells = &SetSpells($wiz);
	    $spells =~ s/^/   /gm;

	    if ($Info{$wiz}{'State'} eq 'choose-spell')
	    {
		$NewSpellChoises++;
		print $ChooserMail "\nAn enchantment have given you a new choice of spells.\nYou now have the choice of the following spells this round:\n";
		print $ChooserMail $spells;
		print $ChooserMail "\nNow expecting a spell choice...\n\n";
	    }
	    else
	    {
		if (($Info{$wiz}{'RightSpell'} ne 'none' ||
		     $Info{$wiz}{'LeftSpell'} ne 'none' ||
		     $Info{$wiz}{'BothSpell'} ne 'none') &&
		    ($Info{$wiz}{'RightSpell'} ne $oldRightSpell ||
		     $Info{$wiz}{'LeftSpell'} ne $oldLeftSpell ||
		     $Info{$wiz}{'BothSpell'} ne $oldBothSpell))
		{
		    $NewTargets++;
		    $Info{$wiz}{'State'} = 'choose-target';
		    print $ChooserMail "\nDue to an enchantment, your spells have changed this round:\n";
		    print $ChooserMail $spells;
		    print $ChooserMail "You will also stab with your $newstab.\n" if $newstab;
		    print $ChooserMail "If you wish to change the target of the spell(s), you may do so now.\n".
			"Otherwise, submit orders with nothing between the GAME and END commands,\n".
			"and the round will continue.\n\n";
		}
		elsif ($newstab)
		{
		    $Info{$wiz}{'State'} = 'choose-target';
		    print $ChooserMail "\nDue to an enchantment, ".
			"you will stab with your $newstab this round.\n".
			"If you wish to change the target of the stab, you may do so now.\n".
			"Otherwise, submit orders with nothing between the GAME and END commands,\n".
			"and the round will continue.\n\n";
		}
	    }

	    $Info{$wiz}{'CheckNewSpells'} = "";
        }
    }

    return unless &AllOrdersIn;

    &Announce("\nThe Battle Continues...\n");

    foreach $wiz (@Players)
    {
	# I thoought this was more natural to have here ...
	$Info{$wiz}{'BlindTurns'} .=
	    ($Info{$wiz}{'Blind'} ? '1' : '0');

	$Info{$wiz}{'InvisibleTurns'} .=
	    (($Info{$wiz}{'Invisible'} || $Info{$wiz}{'TimeStoppedTurn'})
	     ? '1' : '0');
	# If a wiz can't see at the beginning of a turn, he should
	# not be able to see what happened afterwards, even if he
	# got rid of the blindness.

	next if grep(/^$wiz$/,@DeadPlayers);
    }

    # Speak now...

    foreach $wiz (@Players)
    {
	next if grep(/^$wiz$/,@DeadPlayers);
        next if (($TimeStoppedTurn && !$Info{$wiz}{'TimeStoppedTurn'}) ||
                 ($HastenedTurn && !$Info{$wiz}{'HastenedTurn'}));

        if ($Info{$wiz}{'Quote'} ne "none")
        {
            $q = $Info{$wiz}{'Quote'};

            if ($q !~ m/^\"/)
            {
                # force a quote around speech
                $q = "$wiz says \"$q\"\n";
            }
            else
            {
                $q = "$wiz says $q\n";
            }

	    $split = 70;
	  SPLIT:while (length($q) > $split)
	    {
		for($s = $split; ($s > ($split-69)) && (substr($q, $s, 1) ne " "); $s--)
		{}
		if ($s > ($split-69))
		{
		    substr($q, $s, 1) = "\n ";
		    $split = $s+70;
		}
		else
		{
		    last SPLIT;
		}
	    }

            &Announce($q);
        }
        $Info{$wiz}{'Quote'} = 'none';
    }

    # Describe the gestures done...
    foreach $wiz (@Players)
    {
	next if grep(/^$wiz$/,@DeadPlayers);
	next if (($TimeStoppedTurn && !$Info{$wiz}{'TimeStoppedTurn'}) ||
		 ($HastenedTurn && !$Info{$wiz}{'HastenedTurn'}));

	# describe effects of enchantments

	if ($Info{$wiz}{'Forgetful'})
	{
	    if ($HastenedTurn)
	    {
		&NoteThat ("$wiz is slowly getting dopey, but $wiz does still manage to remember what to do.\n",$wiz);
	    }
	    elsif ($TimeStoppedTurn)
	    {
		&NoteThat ("Escaping briefly from amnesia, $wiz manages to remember what to do.\n",$wiz);
	    }
	    else
	    {
		&NoteThat("Looking dopey, $wiz repeats last round's gestures!\n",
			  $wiz);
	    }
	}
	elsif ($Info{$wiz}{'Afraid'})
	{
	    if ($HastenedTurn)
	    {
		&NoteThat ("Speedily $wiz makes some new gestures before getting too afraid.\n",$wiz);
	    }
	    elsif ($TimeStoppedTurn)
	    {
		&NoteThat ("From another time line, things seem not so frightening to $wiz.\n",$wiz);
	    }
	}
	elsif ($Info{$wiz}{'Confused'})
	{
	    if ($HastenedTurn)
	    {
		&NoteThat ("Speedily $wiz makes some new gestures before getting too confused.\n",$wiz);
	    }
	    elsif ($TimeStoppedTurn)
	    {
		&NoteThat ("From another time line, things seem clearer to $wiz.\n",$wiz);
	    }
	    else
	    {
		$Event = "$wiz is very confused...\n";
		if ($Info{$wiz}{'Confused'} =~ s/Lucky//)
		{
		    $Event .= "By sheer luck, $wiz makes the intended gesture anyway!\n";
		}
		else
		{
		    $Event .= "$wiz gets a gesture all mixed up!\n";
		}
		&NoteThat ($Event,$wiz);
	    }

	    $Info{$wiz}{'Confused'} =~ s/Lucky//g;
	}
	elsif ($Info{$wiz}{"Paralyzed"})
	{
	    if ($HastenedTurn)
	    {
		&NoteThat ("Speedily $wiz makes some new gestures\nbefore the paralysis takes effect.\n",$wiz);
	    }
	    elsif ($TimeStoppedTurn)
	    {
		&NoteThat ("In another timeline, $wiz finds that paralysis has not quite set in.\n",$wiz);
	    }
	    else
	    {
		foreach $hand ('Right','Left')
		{
		    if ($Info{$wiz}{"Paralyzed$hand"})
		    {
			$h = $HandMap{$hand};
			&NoteThat("$wiz"."'s $hand Hand is paralyzed!\n",
				  $wiz);
			if ($Info{$wiz}{"Paralyzed$hand"} =~ s/Lucky//)
			{
			    &NoteThat("Luckily, $wiz intended to repeat the gesture anyhow!\n",
				      $wiz);
			}
		    }

		    $Info{$wiz}{"Paralyzed$hand"} =~ s/Lucky//g;
		}
	    }
	}
	elsif ($Info{$wiz}{"Charmed"})
	{
	    if ($HastenedTurn)
	    {
		&NoteThat ("Speedily $wiz makes some new gestures\nbefore losing control of one hand.\n",$wiz);
	    }
	    elsif ($TimeStoppedTurn)
	    {
		&NoteThat ("From another timeline, $wiz finds " .
                           $Info{$wiz}{'Controller'} .
                           " a lot less charming.\n",$wiz);
	    }
	    else
	    {
		foreach $hand ('Right','Left')
		{
		    $h = $HandMap{$hand};

		    if ($Info{$wiz}{"Charmed$hand"})
		    {

			&NoteThat("$wiz"."'s $hand Hand is under the control of someone else!\n",
				  $wiz);
			if ($Info{$wiz}{"Charmed$hand"} =~ s/Lucky//)
			{
			    &NoteThat("Luckily, $wiz gets to do the desired gesture anyhow!\n",
				      $wiz);
			}
		    }

		    $Info{$wiz}{"Charmed$hand"} =~ s/Lucky//g;
		}
	    }
	}
	else
	{
	    if ($Info{$wiz}{'HastenedTurn'})
	    {
		&Announce("Speedily, $wiz sneaks in another gesture!\n");
	    }

	    if (!$HastenedTurn && $Info{$wiz}{'TimeStoppedTurn'})
	    {
		&Announce("$wiz sneaks in another gesture from a parallel time line...\n");
	    }
	}

	$Event = "$Info{$wiz}{'Name'} ";
	$Event .= $GestureDesc{$Info{$wiz}{'LastGestureLH'}};
	$Event .= " the left hand.\n";
	$Event .= "$Info{$wiz}{'Name'} ";
	$Event .= $GestureDesc{$Info{$wiz}{'LastGestureRH'}};
	$Event .= " the right...\n";

	&NoteThat($Event, $wiz);
    }

    foreach $wiz (@Players)
    {
	next if grep(/^$wiz$/,@DeadPlayers);
	next if $TimeStoppedTurn || $HastenedTurn;

	# Some things wear off at this stage

	if ($Info{$wiz}{'Afraid'} == 999)
	{
	    $Info{$wiz}{'Afraid'} = -1;
	}
	elsif ($Info{$wiz}{'Afraid'} > 0)
	{
	    $Info{$wiz}{'Afraid'} -= 1;
	}

	if ($Info{$wiz}{'Charmed'} == 999)
	{
	    $Info{$wiz}{'Charmed'} = -1;
	}
	elsif ($Info{$wiz}{'Charmed'} > 0)
	{
	    $Info{$wiz}{'Charmed'} -= 1;
	    if ($Info{$wiz}{'Charmed'} == 0)
	    {
		$Info{$wiz}{'Controller'} = $wiz;
	    }
	}

	if ($Info{$wiz}{'Paralyzed'} == 999)
	{
	    $Info{$wiz}{'Paralyzed'} = -1;
	}
	elsif ($Info{$wiz}{'Paralyzed'} > 0)
	{
	    $Info{$wiz}{'Paralyzed'} -= 1;
	}

	if ($Info{$wiz}{'Forgetful'} == 999)
	{
	    $Info{$wiz}{'Forgetful'} = -1;
	}
	elsif ($Info{$wiz}{'Forgetful'} > 0)
	{
	    $Info{$wiz}{'Forgetful'} -= 1;
	}

	if ($Info{$wiz}{'Confused'} == 999)
	{
	    $Info{$wiz}{'Confused'} = -1;
	}
	elsif ($Info{$wiz}{'Confused'} > 0)
	{
	    $Info{$wiz}{'Confused'} -= 1;
	}
    }
}

sub DoRoundActivity
{
    # Describe the resulting spells that will be cast...

    @SpellsCast = ();
    foreach $wiz (@Players)
    {
	next if grep(/^$wiz$/,@DeadPlayers);
        next if (($TimeStoppedTurn && !$Info{$wiz}{'TimeStoppedTurn'}) ||
                 ($HastenedTurn && !$Info{$wiz}{'HastenedTurn'}));

        foreach $hand ('Right', 'Left', 'Both', 'Fire')
        {
            if ($Info{$wiz}{$hand.'Spell'} ne "none")
            {
                if ($Info{$wiz}{$hand.'Target'} eq 'none')
                {
                    $Info{$wiz}{$hand.'Target'} =
                        (&SelfTarget($Info{$wiz}{$hand.'Spell'}) ?
                         $wiz : &Opponent($wiz));
                }

		$SelectedSpell = $Info{$wiz}{$hand.'Spell'};
		if (($SelectedSpell eq 'Lightning Bolt') &&
		    ($Info{$wiz}{'LastGestureRH'} eq 'C') &&
		    ($Info{$wiz}{'LastGestureLH'} eq 'C') )
		{
		    $Info{$wiz}{'ShortLightningUsed'} = 1;
		}

                if ($Info{$wiz}{$HandMap{$hand}.'Save'})
                {
                    $Info{$wiz}{'SavedSpell'} = $SelectedSpell;
                    $Info{$wiz}{'SavedTarget'} = $Info{$wiz}{$hand.'Target'};
                    $Event = "$wiz saves $Info{$wiz}{$hand.'Spell'} ";
                    $Event .= "to cast at $Info{$wiz}{$hand.'Target'} later.\n";
                    $Info{$wiz}{$HandMap{$hand}.'Save'} = 0;
                    $Info{$wiz}{$hand.'Spell'} = 'none';
                }
                else
                {
		    $Event = "";

		    if ($hand eq 'Fire')
		    {
			$Event = "$wiz releases the delayed $SelectedSpell.\n";
		    }
		    $Event .= "$wiz casts $SelectedSpell";

		    if (&UntargettedSpell($SelectedSpell))
		    {
			$SpellTarget = 'no_one';
		    }
		    else
		    {
			$SpellTarget = $Info{$wiz}{$hand.'Target'};
			$Event .=  " at ".&BeingDescription($SpellTarget);
		    }
                    $Event .= ".\n";

		    $SpellDuration = $Info{$wiz}{$HandMap{$hand}.'Duration'};
		    $Info{$wiz}{$HandMap{$hand}.'Duration'} = 1;
		    if ($SpellDuration == 999)
		    {
			$Event .= "${wiz}'s blue halo flares brightly as $wiz casts $SelectedSpell!\n";
		    }

		    push (@SpellsCast,"$SelectedSpell#$wiz#$SpellTarget#$hand#$SpellDuration");
                }
                &NoteThat($Event, $wiz);
            }
        }
	if ($Info{$wiz}{'RHDuration'}+$Info{$wiz}{'LHDuration'} > 990)
	{
	    &NoteThat("The blue halo above $wiz flares brightly, then disappears.\n", $wiz);
	}
    }

    # Initialise all per-round flags.

    # (Note that this *does* have to be done somewhere each turn for all flags.
    #  It is not sufficient to rely on the data being uninititalised at the
    #  beginning since DoRoundActivity can be called more than once per
    #  invocation of process.pl... and most data now gets saved anyway!)

    $DispelMagicInForce = 0;
    $FireStormActive = 0;
    $IceStormActive = 0;
    $FireAndIceExplosion = 0;
    $FireAndIceStormExplosion = 0;

    foreach $Entity (keys %Info)
    {
	$Info{$Entity}{'EnchantCancelled'} = 0;
    }

    foreach $wiz (@Players)
    {
	$Info{$wiz}{'BHnewborn'} = "null-monster";
	$Info{$wiz}{'LHnewborn'} = "null-monster";
	$Info{$wiz}{'RHnewborn'} = "null-monster";
    }

    # Execute any pending spells...

    foreach $spellnumber (0 .. $#SpellOrder)
    {
        $spell = $SpellOrder[$spellnumber];

	foreach $SpellLine (@SpellsCast)
        {
	    ($SelectedSpell,$wiz, $SpellTarget, $hand, $SpellDuration) =
		split (/\#/, $SpellLine);

	    if ($SelectedSpell eq $spell)
	    {
		$Event = ""; #Clear this variable, in case $SpellTarget eq "no_one"
		if (($SpellTarget ne "no_one") ||
		    &UntargettedSpell($SelectedSpell))
		{
		    $Event = &CastSpell($SelectedSpell, $wiz, $SpellTarget, 
					$hand, $SpellDuration);
		}

		if ($Event)
		{
#debug              print "SpellEvent:\n$Event";
		    foreach $seer (@Players)
		    {
			# we see each spell event unless we are blind
			# or the opponent is getting in a time stop,
			# or it was DispelMagic (which affects everyone).
			# Even if we are blind, we see it if it has been
			# flagged as target-feels-it and it hits us...

			if ($Info{$seer}{'TimeStoppedTurn'} ||
			    $DispelMagicInForce ||
			    (!$TimeStoppedTurn &&
			     (!$Info{$seer}{'Blind'} ||
			      (($Event =~ m/^-T /m) &&
			       ($seer eq $SpellTarget) ))))
			{
			    $Info{$seer}{'SeeEvent'} .= '1';
			}
			else
			{
			    $Info{$seer}{'SeeEvent'} .= '0';
			}
		    }

		    $Event =~ s/^-T //gm;
		    push(@Events, $Event);

		}
	    }
	}
        last if $DispelMagicInForce;
    }


    # Now cause any resultant effects to happen...

    if ($DispelMagicInForce)
    {
	$Event = "";
	foreach $being (@Beings)
	{
	    next if grep(/^$being$/,@DeadPlayers);
	    # remove enchantments from wizards / kill monsters

	    if (&IsMonster($being))
	    {
		$Event .= "$being shrivels under the impact of the shock wave!\n";
		$Info{$being}{'HP'} = 0;
	    }
	    else
	    {
		&RemoveAllEnchantments($being,0);
		$Event .= "Suddenly $being seems completely ordinary again!\n";
	    }
	}
	&NoteThat($Event,"no-one");

	foreach $being (@Beings)
	{
	    if ($Info{$being}{'DispelShield'})
	    {
		$Info{$being}{'Shielded'} = 1;
		$Info{$being}{'DispelShield'} = 0;
		&NoteThat("\nA glimmering shield appears in front of $being.\n","no-one");
	    }
	}
    }

    if ($FireStormActive)
    {
        &NoteThat("A Fire Storm rages through the Graven Circle.\n",
                  "no_one");
    }

    if ($IceStormActive)
    {
        &NoteThat("An Ice Storm howls through the Graven Circle.\n",
                  "no_one");
    }

    if ($IceElementalPresent && $Info{'IceElemental'}{'HitByFireBall'})
    {
        # Get rid of IceElemental before physical damage is done...
        &NoteThat("The Ice Elemental evaporates!\n",
                  'IceElemental');
        
        &KillBeing('IceElemental');
        $IceElementalPresent = 0;
        $Info{'IceElemental'}{'HitByFireBall'} = 0;
    }

    foreach $being (@Beings)
    {
        next if grep(/^$being$/,@DeadPlayers);
        if (&IsMonster($being) && $Info{$being}{'Charmed'})
        {
            $Info{$being}{'Controller'} = $Info{$being}{'Charmed'};
            $Info{$being}{'Controller'} =~ s/^\d* *//;
            $Info{$being}{'Charmed'} = 0;
            $Info{$being}{'Target'} = 'no_one';

            &NoteThat("$being looks to $Info{$being}{'Controller'} for guidance.\n",
                      $being);
        }

        if ($FireStormActive)
        {
            if ( ($TimeStoppedTurn ||
		 !($Info{$being}{'Countering'}) &&
                 !($Info{$being}{'HeatResistant'})) &&
                !($being =~ m/FireElemental/))
            {
                &NoteThat("$being roasts in the raging Fire Storm.\n",
                          $being);
                $Info{$being}{'HP'} -= 5;
            }
        }

        if ($IceStormActive)
        {
            if ( ($TimeStoppedTurn ||
		 !($Info{$being}{'Countering'}) &&
                 !($Info{$being}{'ColdResistant'}) &&
                 !($Info{$being}{'HitByFireBall'})) &&
                !($being =~ m/IceElemental/))
            {
                &NoteThat("$being freezes in the howling Ice Storm.\n",
                          $being);
                $Info{$being}{'HP'} -= 5;
            }
        }

        if ($Info{$being}{'HitByFireBall'})
        {
            if ($IceStormActive && !$TimeStoppedTurn)
            {
                &NoteThat("The Fireball warms $being nicely as the Ice Storm rages all around.\n",
                          $being);
            }
	    elsif ($Info{$being}{'HeatResistant'} && !$TimeStoppedTurn)
	    {
		&NoteThat("The Fireball warms $being nicely.\n", $being);
	    }
            else
            {
                while($Info{$being}{'HitByFireBall'})
                {
		    if ($being =~ m/FireElemental/)
		    {
			&NoteThat("The FireElemental is strengthent a moment as it absorbs a Fireball\n", $being);
		    }
		    else
		    {
			$Info{$being}{'HitByFireBall'}--;
			&NoteThat("$being gets scorched!\n", $being);
			$Info{$being}{'HP'} -= 5;
		    }
                }
            }

	    $Info{$being}{'HitByFireBall'} = 0;
            # No scorching next turn if not hit this turn
        }

        while($Info{$being}{'HitByLightning'})
        {
            $Info{$being}{'HitByLightning'}--;
            &NoteThat("$being gets zapped!\n",
                      $being);
            $Info{$being}{'HP'} -= 5;
        }

        while($Info{$being}{'HitByMissile'})
        {
            $Info{$being}{'HitByMissile'}--;
	    if (!$TimeStoppedTurn &&
		$Info{$being}{'Shielded'})
	    {
		if ($Info{$being}{'Countering'})
		{
		    &NoteThat("The hazy glow around $being effortlessly absorbs a Magic Missile.\n", $being);
		}
		else
		{
		    &NoteThat("A Magic Missile thunks into the glimmering shield protecting $being.\n", $being);
		}
	    }
	    else
	    {
		&NoteThat("There is a thunk as a Magic Missile hits $being.\n",
			  $being);
		$Info{$being}{'HP'} -= 1;
	    }
        }

        while($Info{$being}{'ReceivedHeavyWounds'})
        {
            $Info{$being}{'ReceivedHeavyWounds'}--;
            &NoteThat("$being grunts from the impact of the Heavy Wounds.\n",
                      $being);
            $Info{$being}{'HP'} -= 3;
        }

        while($Info{$being}{'ReceivedLightWounds'})
        {
            $Info{$being}{'ReceivedLightWounds'}--;
            &NoteThat("$being flinches from the impact of the Light Wounds.\n",
                      $being);
            $Info{$being}{'HP'} -= 2;
        }

        if ($Info{$being}{'HeavyWoundsCured'})
        {
            while($Info{$being}{'HeavyWoundsCured'})
            {
                $Info{$being}{'HeavyWoundsCured'}--;
                &NoteThat("$being looks very relieved.\n",
                          $being);
                $Info{$being}{'HP'} += 2;
            }
            $Info{$being}{'Sick'} = 0;
        }

        while($Info{$being}{'LightWoundsCured'})
        {
            $Info{$being}{'LightWoundsCured'}--;
            &NoteThat("$being looks quite relieved.\n",$being);
            $Info{$being}{'HP'}++;
        }

	while ($Info{$being}{'Risen'})
	{
	    if ($Info{$being}{'Dead'})
	    {
		&NoteThat("$being\'s new life energy saves $being from the Finger of Death\n",$being);
		$Info{$being}{'Dead'} = 0;
		$Info{$being}{'Risen'} = 0;
	    }
	    else
	    {
		&NoteThat("$being feels like a new being.\n",$being);
		$Info{$being}{'HP'} += 5;
		$Info{$being}{'Risen'}--;
	    }
	}

        if ($Info{$being}{'Dead'})
        {
            &NoteThat("$being falls under the force of the Finger of Death.\n",
                      $being);
            $Info{$being}{'HP'} = 0;
            $Info{$being}{'Dead'} = 0;
        }

        next if ($TimeStoppedTurn || $HastenedTurn);

        if ($Info{$being}{'Poisoned'})
        {
            if ($Info{$being}{'Poisoned'}-- == 1)
            {
                &NoteThat("$being succumbs to the poison!\n",
                          $being);
                $Info{$being}{'HP'} = 0;
            }
            else
            {
                &NoteThat("The poison makes $being weaker...\n",
                          $being);
            }
        }

        if ($Info{$being}{'Sick'})
        {
            if ($Info{$being}{'Sick'}-- == 1)
            {
                &NoteThat("A nasty magical disease finishes off $being!\n",
                          $being);
                $Info{$being}{'HP'} = 0;
            }
            else
            {
                &NoteThat("$being looks sicker...\n",
                          $being);
            }
        }
    }


    # Now process the players TARGET commands that affect monsters

    foreach $wiz (@Players)
    {
	next if grep(/^$wiz$/,@DeadPlayers);
	next if $Info{$wiz}{'Target'} eq 'no_one';

	@TargetCommands = split ('<', $Info{$wiz}{'Target'});

	foreach $Command (@TargetCommands)
	{
	    ($Monster,$Target) = split ('=>',$Command);

	    if (&IsUnborn($Monster))
	    {
		$Monster = &FindNewborn($Monster);
	    }

	    if (&IsUnborn($Target))
	    {
		$Target = &FindNewborn($Target);
	    }

	    if (($Monster eq 'null-monster') || !&IsBeing($Monster) || grep(/^$Monster$/,@DeadPlayers))
	    {
		if ($Target eq 'null-monster')
		{
		    $Event = "$wiz wishes in vain for help from a monster.\n";
		}
		else
		{
		    $Event = "$wiz wishes that someone would attack $Target.\n";
		}
	    }
	    else
	    {
		if ($Info{$Monster}{'Controller'} and
		    $Info{$Monster}{'Controller'} eq $wiz)
		{
		    if (&IsBeing($Target))
		    {
			$Event = "$wiz sets $Monster onto $Target.\n";
			$Info{$Monster}{'Target'} = $Target;
		    }
		    else
		    {
			$Event = "$Monster can't understand who to attack.\n";
			$Info{$Monster}{'Target'} = 'no_one';
		    }
		}
		else
		{
		    $Event = "$Monster looks in scorn at $wiz trying to take charge.\n";
		}
	    }
	    NoteThat($Event,$wiz);
	}
	$Info{$wiz}{'Target'} = 'no_one';
    }


    # Now do physical attacks...
    # (has to be separate loop to spell effect in case an Elemental
    #  was destroyed by a spell before it gets a chance to attack)

    foreach $being (@Beings)
    {
        next if ( grep(/^$being$/,@DeadPlayers) ||
		  ($Info{$being}{'Dead'} && $Info{$being}{'NewRisen'}) ||
		  ($TimeStoppedTurn &&
		   (!$Info{$being}{'TimeStoppedTurn'} ||
                    &IsMonster($being))
                  ) ||
                  ($HastenedTurn &&
		   (!$Info{$being}{'HastenedTurn'} || &IsMonster($being))
		  )
		);

        if ($being =~ m/IceElemental/)
        {
            if ($Info{$being}{'Confused'})
            {
                &NoteThat("It takes more than a bit of confusion to distract an angry Ice Elemental!\n", $being);
                $Info{$being}{'Confused'} = 0;
            }
            if ($Info{$being}{'Afraid'})
            {
                &NoteThat("A taste of fear only makes the Ice Elemental more angry!\n", $being);
                $Info{$being}{'Afraid'} = 0;
            }
            if ($Info{$being}{'Paralyzed'} ||
                $Info{$being}{'Forgetful'})
            {
                &NoteThat("$being seems stunned.\n", $being);
                $Info{$being}{'Forgetful'} = Min($Info{$being}{'Forgetful'}, 0);
                $Info{$being}{'Paralyzed'} = Min($Info{$being}{'Paralyzed'}, 0);

                next;
            }
            if ($Info{$being}{'Controller'} ne "none")
            {
                &NoteThat("$being sees that " . $Info{$being}{'Controller'} .
                          " is an inadequate master, and continues rampaging...\n",
                          $being);
                $Info{$being}{'Charmed'} = Min($Info{$being}{'Charmed'}, 0);
                $Info{$being}{'Controller'} = "none";
            }

            foreach $target (@Beings)
            {
                next if grep(/^$target$/,@DeadPlayers);
                next if ($being eq $target);

                if ($Info{$target}{'Invisible'})
                {
                    &NoteThat("The Ice Elemental overlooks $target.\n",
                              'IceElemental');
                }
                elsif ($Info{$target}{'ColdResistant'})
                {
                    &NoteThat("$target shrugs off the Ice Elemental's assault.\n",
                              $target);
                }
                elsif ($Info{$target}{'Shielded'})
                {
                    $ProtectString = &ProtectEffect($target);
                    &NoteThat("The Ice Elemental is deflected by $target\'s $ProtectString.\n",
                              $target);
                }
                else
                {
                    &NoteThat("$target freezes under the Ice Elemental's assault!\n",
                              $target);
                    $Info{$target}{'HP'} -= $Damage{'IceElemental'};
                }
            }
        }
        elsif ($being =~ m/FireElemental/)
        {
            if ($Info{$being}{'Confused'})
            {
                &NoteThat("It takes more than a bit of confusion to distract an angry Fire Elemental!\n", $being);
                $Info{$being}{'Confused'} = 0;
            }
            if ($Info{$being}{'Afraid'})
            {
                &NoteThat("A taste of fear only makes the Fire Elemental more angry!\n", $being);
                $Info{$being}{'Afraid'} = 0;
            }
            if ($Info{$being}{'Paralyzed'} ||
                $Info{$being}{'Forgetful'})
            {
                &NoteThat("$being seems stunned.\n", $being);
                $Info{$being}{'Forgetful'} = Min($Info{$being}{'Forgetful'}, 0);
                $Info{$being}{'Paralyzed'} = Min($Info{$being}{'Paralyzed'}, 0);

                next;
            }
            if ($Info{$being}{'Controller'} ne "none")
            {
                &NoteThat("$being sees that " . $Info{$being}{Controller} .
                          " is an inadequate master, and continues rampaging...\n",
                          $being);
                $Info{$being}{'Charmed'} = Min($Info{$being}{'Charmed'}, 0);
                $Info{$being}{'Controller'} = "none";
            }

            foreach $target (@Beings)
            {
                next if grep(/^$target$/,@DeadPlayers);
                next if ($being eq $target);

                if ($Info{$target}{'Invisible'})
                {
                    &NoteThat("The Fire Elemental overlooks $target.\n",
                              'FireElemental');
                }
                elsif ($Info{$target}{'HeatResistant'})
                {
                    &NoteThat("$target shrugs off the Fire Elemental's assault.\n",
                              $target);
                }
                elsif ($Info{$target}{'Shielded'})
                {
                    $ProtectString = &ProtectEffect($target);
                    &NoteThat("The Fire Elemental is deflected by $target\'s $ProtectString.\n",
                              $target);
                }
                else
                {
                    &NoteThat("$target roasts under the Fire Elemental's assault!\n",
                              $target);
                    $Info{$target}{'HP'} -= $Damage{'FireElemental'};
                }
            }
        }
        elsif (&IsMonster($being))
        {
	    $target = $Info{$being}{'Target'};
            if ($Info{$being}{'Paralyzed'})
            {
                &NoteThat("$being stands still!\n", $being);
                if ($Info{$being}{'Paralyzed'} == 999)
                {
                    $Info{$being}{'Paralyzed'} = -1;
                }
                elsif ($Info{$being}{'Paralyzed'} > 0)
                {
                    $Info{$being}{'Paralyzed'} -= 1;
                }
                next;
            }
            if ($Info{$being}{'Confused'})
            {
		do {
                    $target = $Beings[&Rnd($#Beings + 1)];
		} while ($target eq $being || grep(/^$target$/,@DeadPlayers));

                &NoteThat("$being looks rather confused!\n", $being);
                if ($Info{$being}{'Confused'} == 999)
                {
                    $Info{$being}{'Confused'} = -1;
                }
                elsif ($Info{$being}{'Confused'} > 0)
                {
                    $Info{$being}{'Confused'} -= 1;
                }
            }
            if ($Info{$being}{'Forgetful'})
            {
                &NoteThat("$being wanders around looking vague.", $being);
                if ($Info{$being}{'Forgetful'} == 999)
                {
                    $Info{$being}{'Forgetful'} = -1;
                }
                elsif ($Info{$being}{'Forgetful'} > 0)
                {
                    $Info{$being}{'Forgetful'} -= 1;
                }
                next;
            }
            if ($Info{$being}{'Afraid'})
            {
                &NoteThat("$being cowers helplessly in a corner!\n", $being);
                if ($Info{$being}{'Afraid'} == 999)
                {
                    $Info{$being}{'Afraid'} = -1;
                }
                elsif ($Info{$being}{'Afraid'} > 0)
                {
                    $Info{$being}{'Afraid'} -= 1;
                }
                next;
            }

            $being =~ m/.*([A-Z][a-z]+)/;
            $damage = $Damage{$1};

            if ($target eq 'no_one')
            {
                &NoteThat("$being wanders aimlessly around the Circle.\n",
                          $being);
            }
            elsif (!&IsBeing($target) || grep(/^$target$/,@DeadPlayers))
            {
                &NoteThat("$being wanders around looking for someone called $target.\n",
                          $being);
            }
            elsif ($Info{$target}{'Invisible'})
            {
                &NoteThat("$being rushes around angrily trying to find $target.\n",
                          $being);
            }
            elsif ($Info{$target}{'Shielded'})
            {
                $ProtectString = &ProtectEffect($target);
                &NoteThat("$being is deflected by $target"."'s $ProtectString.\n",
                          $being);
            }
            else
            {
                &NoteThat("$being strikes $target!\n",
                          $target);

                $Info{$target}{'HP'} -= $damage;
            }
        }
        else
	{
          STAB_CHECK:
	    foreach $hand ('Right','Left')
	    {
		my ($h) = $HandMap{$hand};

		if ($Info{$being}{"LastGesture$h"} eq '>')
		{
		    $target = $Info{$being}{"${hand}Target"};
		    if (&IsUnborn($target))
		    {
			$target = &FindNewborn($target);
			if ($target eq "null-monster") {$target = 'no_one'}
		    }

		    if ($target eq 'none')
		    {
			$target = &Opponent($being);
		    }

		    if ($target eq 'no_one')
		    {
			&NoteThat("With dagger clenched in \L$hand\E hand, $being stabs aimlessly.\n",
                          $being);
		    }
		    elsif (!&IsBeing($target) || grep(/^$target$/,@DeadPlayers))
		    {
			&NoteThat("With dagger clenched in \L$hand\E hand, $being attempts to stab someone called $target.\n",
                          $being);
		    }
		    elsif (($Info{$target}{'Invisible'} &&
			    !$Info{$being}{'TimeStoppedTurn'}) ||
			   $Info{$being}{'Blind'})
		    {
			&NoteThat("$being stabs wildly, hoping to hit $target.\n",
				  $being);
		    }
		    elsif ($Info{$target}{'Shielded'} &&
			   !$Info{$being}{'TimeStoppedTurn'})
		    {
			$ProtectString = &ProtectEffect($target);
			&NoteThat("$being"."'s \L$hand\E stab is deflected by $target"."'s $ProtectString.\n",
                          $being);
		    }
		    else
		    {
			&NoteThat("$being stabs $target!\n",
				  $target);
			$Info{$target}{'HP'} -= $Damage{'Stab'};
		    }
                    last STAB_CHECK; # you can only stab once per turn
		}
	    }
	}
    }

    # Now deal with fast/time stopped attacks by monsters: they get an
    # extra attack as long as they weren't already killed...
    # But not also an extra attack in a TimeStoppedTurn or a HastenedTurn

    foreach $being (@Beings)
    {
	# ($Info{$wiz}{'TimeStoppedTurn'} and $Info{$wiz}{'HastenedTurn'}
        #  are only set for mages, so can't use them in this test)

        next if ($TimeStoppedTurn ||
		 $HastenedTurn ||
		 !&IsMonster($being) ||
                 $Info{$being}{'HP'} <= 0 ||
                 !($Info{$being}{'TimeStopped'} || $Info{$being}{'Fast'})
                );

        if ($being =~ m/(Ice|Fire)Elemental/)
        {
	    $Element = $1;
	    if ($Element eq 'Fire')
	    {
		$Temp='Heat';
	    }
	    else
	    {
		$Temp='Cold';
	    }

            foreach $target (@Beings)
            {
                next if grep(/^$target$/,@DeadPlayers);
                next if ($being eq $target);

                if ($Info{$being}{'TimeStopped'})
                {
                    if ($Info{$target}{'Invisible'} ||
                        $Info{$target}{$Temp.'Resistant'} ||
                        $Info{$target}{'Shielded'})
                    {
                        &NoteThat("Then, from another timeline, $being manages to hit $target after all!\n",
                                  $target);
                    }
                    else
                    {
			if ($Element eq 'Ice')
			{
			    &NoteThat("Then, from another timeline, $being freezes $target again!\n",
				      $target);
			}
			else
			{
			    &NoteThat("Then, from another timeline, $being roasts $target again!\n",
				      $target);
			}
                    }
                    $Info{$target}{'HP'} -= $Damage{$being};
		}

                if ($Info{$being}{'Fast'} &&
                    !($Info{$target}{'Invisible'} ||
                      $Info{$target}{$Temp.'Resistant'} ||
                      $Info{$target}{'Shielded'}))
                {
                    &NoteThat("Being hastened, the $being hits $target again!\n",
                              $target);
                    $Info{$target}{'HP'} -= $Damage{$being};
                }
            }
        }
        else # must be monster...
        {
	    $target = $Info{$being}{'Target'};
            $being =~ m/.*([A-Z][a-z]+)/;  # strip colour off monster type
            $damage = $Damage{$1};

            next if (($target eq 'no_one') ||
                     !&IsBeing($target) ||
                     grep(/^$target$/,@DeadPlayers) );
            
            if ($Info{$being}{'TimeStopped'} )
            {
                if ($Info{$target}{'Invisible'} ||
                    $Info{$target}{'Shielded'} ||
                    $Info{$being}{'Confused'} ||
                    $Info{$being}{'Afraid'} ||
                    $Info{$being}{'Paralyzed'})
                {
                    &NoteThat("Then, from another timeline, $being manages to hit $target afterall!\n",
                              $target);
                }
                else
                {
                    &NoteThat("Then, from another timeline, $being manages to hit $target again!\n",
                              $target);
                }
                $Info{$target}{'HP'} -= $damage;
            }

            if ($Info{$being}{'Fast'} &&
                !($Info{$target}{'Invisible'} ||
                  $Info{$target}{'Shielded'} ||
                  $Info{$being}{'Confused'} ||
                  $Info{$being}{'Afraid'} ||
                  $Info{$being}{'Paralyzed'}))
            {
                &NoteThat("Being hastened, $being strikes again!\n",
                          $target);
                $Info{$target}{'HP'} -= $damage;
            }
        }
    }

    # Now correct HP and check out surviving monsters
    my @CurrentBeings = @Beings;  # make a copy, so we can kill beings
    foreach $being (@CurrentBeings)
    {
	$Info{$being}{'HP'} = &Min($Info{$being}{'HP'}, &MaxHP($being));
	next if !IsMonster($being);
        if ($Info{$being}{'Dead'})
        {
	    if ($Info{$being}{'NewRisen'})
	    {
                &NoteThat("$being returns to the grave again, never being fully alive.\n",
                          $being);
	    }
            if ($Info{$being}{'TimeStoped'})
            {
                &NoteThat("$being\'s body flickers out for a moment, before falling stone dead.\n",
                          $being);
            }
            if ($Info{$being}{'Fast'})
            {
                &NoteThat("$being was not fast enough to escape the Finger of Death!\n",
                          $being);
            }
        }
        $Info{$being}{'NewRisen'} = 0;
        if ($Info{$being}{'HP'} <= 0)
        {
            &NoteThat("$being dies.\n", $being);
	    &KillBeing($being);
        }
    }

    foreach $wiz (@Players)
    {
	next if grep(/^$wiz$/,@DeadPlayers);
        if ( ($Info{$wiz}{'LastGestureRH'} eq 'P') &&
             ($Info{$wiz}{'LastGestureLH'} eq 'P') )
        {
            &NoteThat("$wiz holds up both hands in surrender!\n",
                      $wiz);
            $Info{$wiz}{'Surrendered'} = 1;
        }
    }

    &WriteGameHistory;

    # What next?

    $FinishGame = 0;
    @alive = ();
    @kicking = ();
    @surrendered = ();
    foreach $wiz (@Players)
    {
	next if grep(/^$wiz$/,@DeadPlayers);
    	$Info{$wiz}{'State'} = 'orders';
	if ($Info{$wiz}{'HP'} > 0)
	{
	    push(@alive,$wiz);
	    if (!$Info{$wiz}{'Surrendered'})
	    {
		push(@kicking,$wiz);
	    }
	    else
	    {
		# take wizard out of game, and allow him to play elsewhere
		&TakeWizOutOfGame($wiz);
		push(@surrendered,$wiz);
		if ($#Players > 1)
		{
		    &Announce("$wiz supplicates to the remaining mages,\n".
		              "and bids a hasty retreat from the circle.\n");
		}
	    }
	}
	else
	{
	    &TakeWizOutOfGame($wiz);

	    if ($#Players > 1)
	    {
                if ($Info{$wiz}{'TimeStoped'})
                {
                    &NoteThat("$wiz\'s body flickers out for a moment, before falling stone dead.\n",
                              $wiz);
                }
                if ($Info{$wiz}{'Fast'})
                {
                    &NoteThat("$wiz was not fast enough to escape death!\n",
                              $wiz);
                }
		&Announce("$wiz has been killed!\n");
	    }
	}
    }

    if ($#alive == -1)
    {
        # everyone dead: no winner
        &Announce("What a battle!  The contestants have wiped each other out!\n");
	&ScoreGame();
        $ShowScores = $GameType;
        $FinishGame = 1;
    }
    elsif ($#alive == 0 && $#kicking == -1)
    {
        # surrendered as enemy died: no winner (no penalty for surrender)
	if ($#Players == 1)
	{
	    $deadguy = &Opponent($alive[0]);
            &Announce("$alive[0] surrendered to $deadguy even as $deadguy died!\n");
	}
	else
	{
	    &Announce("$alive[0] surrendered just as the last enemy falls!\n");
	}
        &Announce("What a wasted opportunity to score a point!\n");
	&ScoreGame();
        $ShowScores = $GameType;
        $FinishGame = 1;
    }
    elsif ($#alive == 0 && $#kicking == 0)
    {
        # victory by kill (no surrenders this round)
	if ($#Players == 1)
	{
            &Announce("$alive[0] defeated " . &Opponent($alive[0]) . " outright!\n");
            &Announce(&Opponent($alive[0]) . " dies.\n");
	}
	else
	{
	    &Announce("$alive[0] stands alone in the Graven Circle, Victorious!\n");
	}
	&ScoreGame(@alive);
        $ShowScores = $GameType;
        $FinishGame = 1;
    }
    elsif ($#kicking == -1)
    {
        # everyone surrendered: share victory (no penalty for surrender)
        if ($#Players == 1)
        {
            &Announce("Both Mages decide to call it a draw!\n");
	    &ScoreGame();
        }
        else
        {
            if ($#DeadPlayers == -1)
            {
                &Announce("All Mages agree to call the melee a draw!\n");
	        &ScoreGame();
            }
            else
            {
                &Announce("The remaining Mages agree to share the victory!\n");
	        &ScoreGame(@alive);
            }
	}
        $ShowScores = $GameType;
        $FinishGame = 1;
    }
    elsif ($#kicking == 0)
    {
        # one mage left: victory (penalize surrenders)
        foreach $wiz (@Players)
        {
            next if grep(/^$wiz$/,@DeadPlayers);
            if ($Info{$wiz}{'Surrendered'})
            {
                &Announce("$wiz supplicates before a superior mage!\n");
            }
        }
        &Announce("$kicking[0] is the victor...\n");
        foreach $wiz (@Players)
        {
            if ($Info{$wiz}{'Surrendered'})
            {
                &Announce("$wiz gets to live to fight another day.\n");
            }
        }
	&Penalty(@surrendered);
	&ScoreGame(@kicking);
        $ShowScores = $GameType;
        $FinishGame = 1;
    }
    else
    {
        # continue (but penalize any surrenders)
	if (@surrendered)
	{
	    &Penalty(@surrendered);
	}

	# On to the next round!
	@MageTimeStopped = ();
	@MageHastened = ();
	$Antispelled = 0;
	foreach $wiz (@Players)
	{
            next if grep(/^$wiz$/,@DeadPlayers);
	    if ($Info{$wiz}{'TimeStopped'}) { push(@MageTimeStopped,$wiz); }
	    if ($Info{$wiz}{'Fast'}) { push(@MageHastened,$wiz); }
	    if ($Info{$wiz}{'Lost'}) { $Antispelled++; }
	}

	$HastenedNextTurn = 0;
	$TimeStoppedNextTurn = 0;

	foreach $wiz (@Players)
	{
	    $Info{$wiz}{'RightSpell'} = 'none';
	    $Info{$wiz}{'LeftSpell'} = 'none';
	    $Info{$wiz}{'BothSpell'} = 'none';
	    $Info{$wiz}{'FireSpell'} = 'none';
	    $Info{$wiz}{'RightTarget'} = 'none';
	    $Info{$wiz}{'LeftTarget'} = 'none';
	    $Info{$wiz}{'BothTarget'} = 'none';

	    $Info{$wiz}{'RHDuration'} = 1;
	    $Info{$wiz}{'LHDuration'} = 1;
	    $Info{$wiz}{'BHDuration'} = 1;

	    if ($Antispelled>0)
	    {
		$Info{$wiz}{'BlindTurns'} .= '0';
		$Info{$wiz}{'InvisibleTurns'} .= '0';
		if ($Info{$wiz}{'Lost'}) 
		{
		    $Info{$wiz}{'RH'} .= '#';
		    $Info{$wiz}{'LH'} .= '#';
		}
		else
		{
		    $Info{$wiz}{'RH'} .= '.';
		    $Info{$wiz}{'LH'} .= '.';
		}
	    }

	    $Info{$wiz}{'Lost'} = 0;
	    $Info{$wiz}{'HastenedTurn'} = 0;
	    $Info{$wiz}{'TimeStoppedTurn'} = 0;

	    if ($Info{$wiz}{'State'} eq 'OUT' or $Info{$wiz}{'State'} eq 'Dead')
	    {
		$Info{$wiz}{'RH'} .= '-';
		$Info{$wiz}{'LH'} .= '-';
		$Info{$wiz}{'LastGestureRH'} = '-';
		$Info{$wiz}{'LastGestureLH'} = '-';
		next;
	    }
	}

	if ($Antispelled>0)
	{
	    &WriteGameHistory;
	}

	foreach $wiz (@Players)
	{
	    if ($Info{$wiz}{'State'} eq 'OUT' or $Info{$wiz}{'State'} eq 'Dead')
	    {
		next;
	    }

	    if ($#MageHastened >= 0 && !($HastenedTurn || $TimeStoppedTurn))
	    {
		if ($Info{$wiz}{'Fast'})
		{
		    $Info{$wiz}{'State'} = 'orders';
		    $Info{$wiz}{'HastenedTurn'} = 1;
		    $HastenedNextTurn = 1;
		}
		else
		{
		    foreach $opp (@MageHastened)
		    {
			&NoteThat("$wiz blinks in amazement while $opp moves in a blur...\n", $wiz);
		    }
		    $Info{$wiz}{'State'} = 'orders_in';
		    $Info{$wiz}{'RH'} .= '.';
		    $Info{$wiz}{'LH'} .= '.';
		}
	    }
	    elsif ($#MageTimeStopped >= 0)
	    {
		if ($Info{$wiz}{'TimeStopped'})
		{
		    &NoteThat("$wiz sneaks in another gesture from a parallel time line...\n", $wiz);
		    $Info{$wiz}{'TimeStoppedTurn'} = 1;
		    $Info{$wiz}{'State'} = 'orders';
		    $TimeStoppedNextTurn = 1;
		}
		else
		{
		    foreach $opp (@MageTimeStopped)
		    {
			&NoteThat("$wiz blinks as $opp winks out of existence for a moment!\n", $wiz);
		    }
		    $Info{$wiz}{'State'} = 'orders_in';
		    $Info{$wiz}{'RH'} .= '.';
		    $Info{$wiz}{'LH'} .= '.';
		}
	    }
	    else
	    {
		$Info{$wiz}{'State'} = 'orders';
	    }
	}

	$Turn =~ s/[^\d]*$//;
	if ($HastenedNextTurn)
	{
	    $Turn .= 'H';
	}
	else
	{
	    $Turn++ unless $TimeStoppedTurn;

	    if ($TimeStoppedNextTurn)
	    {
		$Turn .= 'T';
	    }
	}


        foreach $wiz (@Players)
        {

            if (($Info{$wiz}{'State'} eq 'orders') &&
                $Info{$wiz}{'Forgetful'} &&
		!($Info{$wiz}{'HastenedTurn'} || $Info{$wiz}{'TimeStoppedTurn'}))
            {
                &NoteThat("$wiz"."'s mind is a complete blank!\n\n".
                          "$wiz can do nothing but repeat last round's gestures,\n while trying to remember what is going on!\n",
                          $wiz);

                $Info{$wiz}{'RH'} .= $Info{$wiz}{'LastGestureRH'};
                $Info{$wiz}{'LH'} .= $Info{$wiz}{'LastGestureLH'};

		@RightSpells = &CheckForCastRight($Info{$wiz}{'RH'},$Info{$wiz}{'LH'},$wiz);
		@LeftSpells = &CheckForCastLeft($Info{$wiz}{'RH'},$Info{$wiz}{'LH'},$wiz);
		@BothSpells = &CheckForCastBoth($Info{$wiz}{'RH'},$Info{$wiz}{'LH'},$wiz);
		if ($Info{$wiz}{'LastGestureRH'} eq '>')
		{
		    $newstab = "right hand";
		}
		elsif ($Info{$wiz}{'LastGestureLH'} eq '>')
		{
		    $newstab = "left hand";
		}
		else
		{
		    $newstab = "";
		}
		$spells = &SetSpells($wiz);
		$spells =~ s/^/   /gm;
# if the player has spell choices, describe them here
# This is only for this player to see, and not a real event
		$Event = "NOT A REAL EVENT:";
		if ($Info{$wiz}{'State'} eq 'choose-spell')
		{
		    $Event .= "\n  You will have the choice of the following spells next round:\n";
		    $Event .= $spells;
		    $Event .= "  You will also stab with your $newstab.\n" if $newstab;
		    $Event .= "\nNow expecting a spell choice...\n\n";
		}
		else
		{
		    if (@RightSpells || @LeftSpells || @BothSpells)
		    {
			$Event .= "\n  You will cast the following spell(s) next round:\n";
			$Event .= $spells;
			$Event .= "  You will also stab with your $newstab.\n" if $newstab;
			$Event .= "  If you wish to change the target of the spell(s), you may do so now.\n";
		    }
		    elsif ($newstab)
		    {
			$Event .= "\n  You will stab with your $newstab next round.\n";
			$Event .= "  If you wish to change the target of the stab, you may do so now.\n";
		    }
		    else
		    {
			$Event .= "\n  If you wish to change the target of monsters, you may do so now.\n";
		    }
		    $Event .= "  Otherwise, submit orders with nothing between the GAME and END commands,\n";
		    $Event .= "  and the round will continue.\n";

		    $Info{$wiz}{'State'} = 'choose-target';
		}
		# Note the choices, but make sure only the player sees it.
		&NoteThat($Event,$wiz);
		foreach $looker (@Players)
		{
		    substr($Info{$looker}{'SeeEvent'}, -1, 1) = '0'
                            unless $looker eq $wiz;
		}
            }
        }

        foreach $being (@Beings)
        {
            next if grep(/^$being$/,@DeadPlayers);
            $Info{$being}{'TimeStopped'} = 0 if !$HastenedNextTurn;

            if ($Info{$being}{'StruckBlind'})
            {
                &NoteThat("$being is struck blind!\n", $being);
                $Info{$being}{'Blind'} = $Info{$being}{'StruckBlind'};
                $Info{$being}{'StruckBlind'} = 0;
            }
            if ($Info{$being}{'Disappearing'})
            {
                &NoteThat("$being disappears!\n", $being);
                $Info{$being}{'Invisible'} = $Info{$being}{'Disappearing'};
		$Info{$being}{'Disappearing'} = 0;
            }

            if (!$HastenedNextTurn && !$TimeStoppedTurn)
            {
                foreach $atr ('Blind',
                              'Countering',
                              'Fast',
                              'Invisible',
                              'PermanencyPending',
                              'DelayPending',
                              'Reflecting',
                              'Shielded'
                              )
                {
                    if ($Info{$being}{$atr} == 999)
                    {
                        $Info{$being}{$atr} = -1;
                    }
                    elsif ($Info{$being}{$atr} > 0)
                    {
                        $Info{$being}{$atr} -= 1;
                    }
                }

                if (!$Info{$being}{'Charmed'})
                {
		    $Info{$being}{'CharmedRight'} = 0;
		    $Info{$being}{'CharmedLeft'} = 0;
                }

                if (!$Info{$being}{'Paralyzed'})
                {
		    $Info{$being}{'ParalyzedRight'} = 0;
		    $Info{$being}{'ParalyzedLeft'} = 0;
                }
            }
        }
    }
}


sub SetSpells
{
# expects @RightSpells, @LeftSpells, and @BothSpells to be setup upon entry
    local($wiz) = @_;

    local($PrintSpells) = "";

    if (((@RightSpells || @LeftSpells) && @BothSpells) ||
        (@RightSpells > 1) || (@LeftSpells > 1) || (@BothSpells > 1))
    {
        if ((@LeftSpells > 1) || (@BothSpells && (@LeftSpells == 1)))
        {
            foreach $spell (@LeftSpells)
            {
                $PrintSpells .= "$spell (left hand)\n";
            }
            $Info{$wiz}{'LeftSpell'} = 'choose';
        }
        elsif (@LeftSpells == 1)
        {
            $Info{$wiz}{'LeftSpell'} = $LeftSpells[0];
        }
        else
        {
            $Info{$wiz}{'LeftSpell'} = 'none';
        }

        if ((@RightSpells > 1) || (@BothSpells && (@RightSpells == 1)))
        {
            foreach $spell (@RightSpells)
            {
                $PrintSpells .= "$spell (right hand)\n";
            }
            $Info{$wiz}{'RightSpell'} = 'choose';
        }
        elsif (@RightSpells == 1)
        {
            $Info{$wiz}{'RightSpell'} = $RightSpells[0];
        }
        else
        {
            $Info{$wiz}{'RightSpell'} = 'none';
        }

        if (((@RightSpells || @LeftSpells) && @BothSpells) ||
            (@BothSpells > 1))
        {
            foreach $spell (@BothSpells)
            {
                $PrintSpells .= "$spell (both hands)\n";
            }
            $Info{$wiz}{'BothSpell'} = 'choose';
        }

        $Info{$wiz}{'State'} = "choose-spell";
    }
    else
    {
        if (@BothSpells)
        {
            $Info{$wiz}{'RightSpell'} = $Info{$wiz}{'LeftSpell'} = 'none';
            $Info{$wiz}{'BothSpell'} = $BothSpells[0];
            $PrintSpells .= "$Info{$wiz}{'BothSpell'} (both hands)\n";
        }
        else
        {
            $Info{$wiz}{'BothSpell'} = 'none';
            $Info{$wiz}{'LeftSpell'} =
                ((@LeftSpells == 1) ? $LeftSpells[0] : 'none');
            $PrintSpells .= "$Info{$wiz}{'LeftSpell'} (left hand)\n"
		if $Info{$wiz}{'LeftSpell'} ne 'none';
            $Info{$wiz}{'RightSpell'} =
                ((@RightSpells == 1) ? $RightSpells[0] : 'none');
            $PrintSpells .= "$Info{$wiz}{'RightSpell'} (right hand)\n"
		if $Info{$wiz}{'RightSpell'} ne 'none';
        }

        $Info{$wiz}{'State'} = "orders_in";
    }

    return $PrintSpells;
}
