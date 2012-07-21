#!/usr/bin/perl
#----------------------------------------------------------------------
#
#  Copyright (c) Craig Ferguson, 2000.  All rights reserved.
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
#      The Original Code is challenges.pl.
#
#      The Initial Developer of the Original Code is Craig Ferguson.
#
#      Portions of the Original Code are based on users.pl, by Martin
#      Gregory
#
#----------------------------------------------------------------------
#
#      This code presents the output of a CHALLENGES command as an HTML
#      page.
#
#----------------------------------------------------------------------

$Revision .= ' L1.00';

# The description of an opponent's state in a Game Status report...
# (any states not in this hash will appear unchanged in the report)

sub ReportErrorAndExit
{
	my $Error = shift;
	print "Content-type: text/html\n\n";
        print "<HTML><HEAD><TITLE>Error in challenges.pl</TITLE></HEAD>\n";
        print "<BODY>\n";
	print "$Error\n";
        print "</BODY></HTML>\n";
	exit;
}

sub OpenChallenges
{
	print "<H2>Challenges open for anyone to accept:</H2>\n";
	print "<TABLE BORDER=\"1\"><TR><TH>Game</TH>\n";
	print "<TH>Challenger</TH><TH>No. acc.</TH>\n";
	print "<TH>Limit</TH><TH>Spell Book</TH>\n";
	print "<TH>Comments</TH>\n";
	print "</TR>\n";
	foreach $row (0..$#OpenChallenges)
	{
		print "<TR><TD>$OpenChallenges[$row]{'Game'}</TD>\n";
		print "<TD>$OpenChallenges[$row]{'Challenger'}</TD>\n";
		print "<TD>$OpenChallenges[$row]{'NoAcc'}</TD>\n";
		print "<TD>$OpenChallenges[$row]{'Limit'}</TD>\n";
		print "<TD>$OpenChallenges[$row]{'Spell Book'}</TD>\n";
		print "<TD>$OpenChallenges[$row]{'Comment'}</TD>\n";
		print "</TR>\n";
	}
	print "</TABLE>\n";
}

sub ClosedChallenges
{
	print "<H2>Closed Challenges:</H2>\n";
	print "<TABLE BORDER=\"1\"><TR><TH>Game</TH>\n";
	print "<TH>Challenger</TH><TH>No. acc.</TH>\n";
	print "<TH>Limit</TH><TH>Spell Book</TH>\n";
	print "<TH>Comments</TH>\n";
	print "</TR>\n";
	foreach $row (0..$#ClosedChallenges)
	{
		print "<TR><TD>$ClosedChallenges[$row]{'Game'}</TD>\n";
		print "<TD>$ClosedChallenges[$row]{'Challenger'}</TD>\n";
		print "<TD>$ClosedChallenges[$row]{'NoAcc'}</TD>\n";
		print "<TD>$ClosedChallenges[$row]{'Limit'}</TD>\n";
		print "<TD>$ClosedChallenges[$row]{'Spell Book'}</TD>\n";
		print "<TD>$ClosedChallenges[$row]{'Comment'}</TD>\n";
		print "</TR>\n";
	}
	print "</TABLE>\n";
}

$version = "";
$version = "Test" if ($ENV{SCRIPT_FILENAME} =~ m#/Test/#); 
$version = "Main" if ($ENV{SCRIPT_FILENAME} =~ m#/Main/#); 

$gamedir = "/home/FM/fm/\L$version\E/saves";

open (WIZARDS, "<$gamedir/wizards.dat") || ReportErrorAndExit("Error opening wizards file ($gamedir/wizards.dat): " . $!);
@WizardInfo = <WIZARDS>;
close WIZARDS;
eval "@WizardInfo";

opendir (SAVEDIR,$gamedir) || ReportErrorAndExit("Error opening save directory ($gamedir): " . $!);

@NewGames = grep(/\.ngm$/, readdir(SAVEDIR));

closedir (SAVEDIR);

print "Content-type: text/html\n\n";
print "<HTML><HEAD><TITLE>Firetop Mountain Challenges ($version Server)</TITLE></HEAD>\n";

print "<BODY>\n";
print "<H1>Challenges to battle on Firetop Mountain</H1>\n";

@OpenChallenges = ();
@ClosedChallenges = ();

#  Indices into OpenChallenges and CloseChallenges arrays
$orow = 0;
$crow = 0;

foreach $NewGame (@NewGames)
{
	$ng = $NewGame;
	$ng =~ s/\.ngm$//;

	if (!open (NEWGAME, "<$gamedir/$NewGame"))
	{
		print "Error opening newgame file $NewGame: $!\n";
	}
	else
	{
		@GameInfo = <NEWGAME>;
		close NEWGAME;
		eval "@GameInfo";

		@Challenged = grep(defined($Wizard{$_}), @Challenged);

		if ($Open)
		{
			$OpenChallenges[$orow]{'Game'} = $ng;
			$OpenChallenges[$orow]{'Challenger'} = "$Challenger ($Wizard{$Challenger}{'User'})";
			$OpenChallenges[$orow]{'NoAcc'} = (keys %Accepted)-1;
			$OpenChallenges[$orow]{'Limit'} = $Limit?$Limit:'none';
			$OpenChallenges[$orow]{'Spell Book'} = "\u$SpellBook";
			$OpenChallenges[$orow]{'Comment'} = $Comment;
			$orow++;
		}
		else
		{
			$NumAcc = (keys %Accepted)-1;
			$NumChl = @Challenged;
			$ClosedChallenges[$crow]{'Game'} = $ng;
			$ClosedChallenges[$crow]{'Challenger'} = "$Challenger ($Wizard{$Challenger}{'User'})";
			$ClosedChallenges[$crow]{'NoAcc'} = "$NumAcc / $NumChl"; 
			$ClosedChallenges[$crow]{'Limit'} = $Limit?$Limit:'none';
			$ClosedChallenges[$crow]{'Spell Book'} = "\u$SpellBook";
			$ClosedChallenges[$crow]{'Comment'} = $Comment;
			$crow++;
		}
	}
}

OpenChallenges;
ClosedChallenges;

