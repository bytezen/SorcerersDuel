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
#      The Original Code is scores.pl.
#
#      The Initial Developer of the Original Code is Craig Ferguson.
#
#      Portions of the Original Code are based on users.pl, by Martin
#      Gregory
#
#----------------------------------------------------------------------
#
#      This code presents the output of a SCORES command as an HTML
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
        print "<HTML><HEAD><TITLE>Error in scores.pl</TITLE></HEAD>\n";
        print "<BODY>\n";
	print "$Error\n";
        print "</BODY></HTML>\n";
	exit;
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

$version = "";
$version = "Test" if ($ENV{SCRIPT_FILENAME} =~ m#/Test/#); 
$version = "Main" if ($ENV{SCRIPT_FILENAME} =~ m#/Main/#); 

# Get type of score output requested based on filename
@types = ('Duel', 'Melee');
@types = ('Melee') if ($ENV{SCRIPT_FILENAME} =~ m/meleescores\.pl$/);
@types = ('Duel')  if ($ENV{SCRIPT_FILENAME} =~ m/duelscores\.pl$/);

$gamedir = "/home/FM/fm/\L$version\E/saves";

open (WIZARDS, "<$gamedir/wizards.dat") || ReportErrorAndExit("Error opening wizards file ($gamedir/wizards.dat): " . $!);
@WizardInfo = <WIZARDS>;
close WIZARDS;
eval "@WizardInfo";

@WizardNames = keys %Wizard;

print "Content-type: text/html\n\n";
print "<HTML><HEAD><TITLE>Firetop Mountain Scores ($version Server)</TITLE></HEAD>\n";

print "<BODY>\n";

foreach $type (@types)
{
	print "<H1>Honour Roll of the Mages of Firetop Mountain</H1>\n";

	print "<H2>Active List (Sorted by $type Scores):</H2>\n";
	print "<TABLE BORDER=\"1\"><TR><TH>Game</TH>\n";
	print "<TH>$type Score</TH>\n";
	my $othertype = "Melee" if ($type eq 'Duel');
	$othertype = "Duel"  if ($type eq 'Melee');
	print "<TH>$othertype Score</TH>\n";
	print "<TH>Battles</TH>\n";
	print "<TH>Mage</TH>\n";
	print "<TH>User</TH>\n";
	print "</TR>\n";

	$ScoreType = $type;
	foreach $wiz (sort wizard_by_score grep {!$Wizard{$_}{'Dead'} && !$Wizard{$_}{'Retired'}} @WizardNames)
	{
		print "<TR><TD>";
		if ($Wizard{$wiz}{'Busy'})
		{
			print "$Wizard{$wiz}{'Busy'}";
			print "V" if ($Users{$Wizard{$wiz}{'User'}}{'Vacation'});
		}
		print "</TD>\n";
           
		print "<TD>$Wizard{$wiz}{$type.'Score'}</TD>\n";
		print "<TD>$Wizard{$wiz}{$othertype.'Score'}</TD>\n";
		print "<TD>$Wizard{$wiz}{'Battles'}</TD>\n";
		print "<TD>$wiz</TD>\n";
		print "<TD>$Wizard{$wiz}{'User'}</TD>\n";
		print "</TR>\n";
	}
	print "</TABLE>\n";

	print "<H2>Successfully Retired ($type Scores):</H2>\n";
	print "<TABLE BORDER=\"1\"><TR><TH>Game</TH>\n";
	print "<TH>$type Score</TH>\n";
	my $othertype = "Melee" if ($type eq "Duel");
	my $othertype = "Duel"  if ($type eq "Melee");
	print "<TH>$othertype Score</TH>\n";
	print "<TH>Battles</TH>\n";
	print "<TH>Mage</TH>\n";
	print "<TH>User</TH>\n";
	print "</TR>\n";

	$ScoreType = $type;
	foreach $wiz (sort wizard_by_score grep {!$Wizard{$_}{'Dead'} && $Wizard{$_}{'Retired'}} @WizardNames)
	{
		print "<TR><TD>";
		if ($Wizard{$wiz}{'Busy'})
		{
			print "$Wizard{$wiz}{'Busy'}";
			print "V" if ($Users{$Wizard{$wiz}{'User'}}{'Vacation'});
		}
		print "</TD>\n";
           
		print "<TD>$Wizard{$wiz}{$type.'Score'}</TD>\n";
		print "<TD>$Wizard{$wiz}{$othertype.'Score'}</TD>\n";
		print "<TD>$Wizard{$wiz}{'Battles'}</TD>\n";
		print "<TD>$wiz</TD>\n";
		print "<TD>$Wizard{$wiz}{'User'}</TD>\n";
		print "</TR>\n";
	}
	print "</TABLE>\n";

    
	if (!open(HISTORY, "<$gamedir/$type.history.dat"))
	{
		print "</BODY></HTML>\n";
		exit;
	}

	@DeadNames = ();
	@DeadScores = ();
	@DeadUsers = ();
	%BestScore = ();
    
	while(<HISTORY>)
	{
		chomp;
        
		($Name, $Score, $DeadUser) = split(/[ ]+/, $_, 3);
		if ($Name && (!$BestScore{$Name} || ($BestScore{$Name} < $Score)))
		{
			push(@DeadNames, $Name);
			push(@DeadScores, $Score);
			push(@DeadUsers, $DeadUser);
			$BestScore{$Name} = $Score;
		}
	}
	close HISTORY;

	#if (!open(HISTORY, ">$gamedir/$type.history.dat"))
	#{
	#	print "</BODY></HTML>\n";
	#	exit;
	#}

    
	print "<H2>In Remembrance of those who died Valiantly in ${type}s</H2>\n";

	print "<TABLE BORDER=\"1\">\n";
	print "<TR><TH>Score</TH><TH>Mage</TH><TH>User</TH></TR>\n";

	foreach $wiz_index (sort dead_by_score (0 .. $#DeadNames))
	{
		print "<TR><TD>$DeadScores[$wiz_index]</TD>\n";
		print "<TD>$DeadNames[$wiz_index]</TD>\n";
		print "<TD>$DeadUsers[$wiz_index]</TD>\n";
		print "</TR>\n";
	#	print HISTORY "$DeadNames[$wiz_index] $DeadScores[$wiz_index] $DeadUsers[$wiz_index]\n";
	}
        print "</TABLE>\n";
	#close HISTORY;
}

print "</BODY></HTML>\n";
