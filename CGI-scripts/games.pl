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
#      The Original Code is games.pl.
#
#      The Initial Developer of the Original Code is Craig Ferguson.
#
#      Portions of the Original Code are based on lib.pl, by Martin
#      Gregory
#
#----------------------------------------------------------------------
#
#      This code presents the output of a GAMES command as an HTML
#      page.
#
#----------------------------------------------------------------------

$Revision .= ' L1.00';

# The description of an opponent's state in a Game Status report...
# (any states not in this hash will appear unchanged in the report)

sub Num
{
        my $str = shift;
	return $1 if ($str =~ /(-?\d+)/);
	return 0;
}

sub ReportErrorAndExit
{
	my $Error = shift;
	print "Content-type: text/html\n\n";
        print "<HTML><HEAD><TITLE>Error in Games.pl</TITLE></HEAD>\n";
        print "<BODY>\n";
	print "$Error\n";
        print "</BODY></HTML>\n";
	exit;
}

sub BadGame
{
	my $game = shift;
	$game =~ s/\.gm$//;
	print "<TR><TD Colspan=\"4\">Error $! opening game $game</TD></TR>\n";
}

sub BadDsc
{
	my $dsc = shift;
	$dsc =~ s/\.dsc$//;
	print "Error $! opening decsription $dsc<BR>\n";
}

%StateDescription = ('orders' => 'thinking',
                     'choose-target' => 'thinking',
                     'choose-spell' => 'thinking'
                     );

$version = "";
$version = "Test" if ($ENV{SCRIPT_FILENAME} =~ m#/Test/#); 
$version = "Main" if ($ENV{SCRIPT_FILENAME} =~ m#/Main/#); 

$gamedir = "/home/FM/fm/\L$version\E/saves";

my($Wiz,$state,$Games,$NextGame,$GameTurn,$desc,$line,@ActiveGameFiles,@DscFiles) = ("","","",0,0);

opendir(GAMEDIR, "$gamedir") || ReportErrorAndExit("Error opening games directory ($gamedir): " . $!);
@ActiveGameFiles = sort {&Num($a) <=> &Num($b)} grep(/\.gm$/, readdir(GAMEDIR));
    
open (WIZARDS, "<$gamedir/wizards.dat") || ReportErrorAndExit("Error wizards file ($gamedir/wizards.dat): " . $!);
@WizardInfo = <WIZARDS>;
close WIZARDS;
eval "@WizardInfo";

print "Content-type: text/html\n\n";
print "<HTML><HEAD><TITLE>Firetop Mountain Games ($version Server)</TITLE></HEAD>\n";
print "<BODY>\n";

if (@ActiveGameFiles)
{
	print "<H1>Battles in Progress on Firetop Mountain</H1>\n";

	print "<TABLE BORDER=\"1\">\n";
	print "<TR><TH>Game</TH>\n";
	print "<TH>Turn</TH>\n";
	print "<TH>Wizard State</TH>\n";
	print "<TH>Wizard State</TH>\n";
	print "</TR>\n";

	while($NextGame = pop(@ActiveGameFiles))
	{

		if (!open (GAME, "$gamedir/$NextGame"))
		{
 			BadGame($NextGame);
			next;
		}
		my(@Game) = <GAME>;
		close GAME;

		eval "@Game";

		$NextGame =~ s/\.gm$//;

		my $RowsOfWizards = int($#Players / 2) + 1;
		print "<TR><TD";
		print " ROWSPAN=\"$RowsOfWizards\" VALIGN=\"Top\"" if ($RowsOfWizards > 1);
		print "><A name=\"$NextGame\">$NextGame</A></TD><TD";
		print " ROWSPAN=\"$RowsOfWizards\" VALIGN=\"Top\"" if ($RowsOfWizards > 1);
		print ">$Turn</TD>\n";

		my($WizCount) = 0;
		while($Wizard = shift(@Players))
		{

			# Go to a new row when required
			if (++$WizCount == 3)
			{
				$WizCount = 1;
				print "</TR><TR>\n";
	    		}

			my $State = "";

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
			print "<TD>$Wizard $State</TD>\n";
		}
                print "</TR>\n";
	}
	print "</TABLE>\n";
}

rewinddir GAMEDIR;
@DscFiles = sort {&Num($a) <=> &Num($b)} grep(/.dsc$/, readdir(GAMEDIR));
if (@DscFiles)
{
	print "<H1>Past History</H1>\n";
    
	while($NextGame = pop(@DscFiles))
	{
		$NextGame =~ m/(.*)\./;
		$Name = $1;
		if (!-f "$gamedir/$Name.gm")
		{
			if (!open(DESC, "$gamedir/$Name.dsc"))
			{
				BadDsc($NextGame);
			}
			else
			{
				chomp($desc = <DESC>);
				$line = <DESC>; #skip ---- line
				chomp ($line = <DESC>);
				if ($line =~ m/Last turn/)
				{
					$desc .= " ($line";
					chomp ($line = <DESC>);
					$desc .= "  $line)";
				}
				print "$desc<BR>\n";
				close DESC;
			}
		}
	}
}
print "</BODY></HTML>\n";
