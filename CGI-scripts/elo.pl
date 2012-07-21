#!/usr/bin/perl
#----------------------------------------------------------------------
#
#  Copyright (c) Craig Ferguson, 2001.  All rights reserved.
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
#      The Original Code is elo.pl.
#
#      The Initial Developer of the Original Code is Craig Ferguson.
#
#      Portions of the Original Code are based on users.pl, by Martin
#      Gregory
#
#----------------------------------------------------------------------
#
#      This code presents a list of FM users and their ELO scores
#       as a web page
#
#----------------------------------------------------------------------

$Revision .= ' L1.00';

# The description of an opponent's state in a Game Status report...
# (any states not in this hash will appear unchanged in the report)

sub sortbyelo
{
        $Users{$a}{'DuelELO'} = 1000 if (!defined($Users{$a}{'DuelELO'}));
        $Users{$b}{'DuelELO'} = 1000 if (!defined($Users{$b}{'DuelELO'}));
	return $Users{$b}{'DuelELO'} <=> $Users{$a}{'DuelELO'};
}

sub ReportErrorAndExit
{
	my $Error = shift;
	print "Content-type: text/html\n\n";
        print "<HTML><HEAD><TITLE>Error in elo.pl</TITLE></HEAD>\n";
        print "<BODY>\n";
	print "$Error\n";
        print "</BODY></HTML>\n";
	exit;
}

$version = "";
$version = "Test" if ($ENV{SCRIPT_FILENAME} =~ m#/Test/#); 
$version = "Main" if ($ENV{SCRIPT_FILENAME} =~ m#/Main/#); 


$gamedir = "/home/FM/fm/\L$version\E/saves";

# Get user info into %Users
open (USERS, "<$gamedir/users.dat") || ReportErrorAndExit("Error opening users file ($gamedir/users.dat): " . $!);
@UserInfo = <USERS>;
close USERS;
eval "@UserInfo";

# Get stats info (%Stats)
open (STATS, "<$gamedir/stats.dat") || ReportErrorAndExit("Error opening stats file ($gamedir/stats.dat): " . $!);
@Stats = <STATS>;
close STATS;
eval "@Stats";

$now = time();

print "Content-type: text/html\n\n";
print "<HTML><HEAD><TITLE>Firetop Mountain ELO Ratings ($version Server)</TITLE></HEAD>\n";

print "<BODY>\n";

	print "<H1>Active List (active in last 30 days):</H1>\n";
	print "<TABLE BORDER=\"1\"><TR><TH>User</TH>\n";
	print "<TH>ELO</TH>\n";
	print "</TR>\n";

	foreach $user (sort sortbyelo grep {($now - $Stats{'UserActive'}{$_}) < (30*24*60*60)} keys(%Users))
	{
		print "<TR><TD>$user</TD><TD>$Users{$user}{'DuelELO'}</TD></TR>\n";
	}
	print "</TABLE>\n";

	print "<H1>Inactive List (no activity for more than 30 days):</H1>\n";
	print "<TABLE BORDER=\"1\"><TR><TH>User</TH>\n";
	print "<TH>ELO</TH>\n";
	print "</TR>\n";

	foreach $user (sort sortbyelo grep {($now - $Stats{'UserActive'}{$_}) >= (30*24*60*60)} keys(%Users))
	{
		print "<TR><TD>$user</TD><TD>$Users{$user}{'DuelELO'}</TD></TR>\n";
	}
	print "</TABLE>\n";

print "</BODY></HTML>\n";
