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
#      The Original Code is stats.pl.
#
#      The Initial Developer of the Original Code is Martin Gregory.
#
#      Contributors: Terje Bråten, John Williams.
#
#----------------------------------------------------------------------

$Revision .= " ST9.0";

# Routines to track FM usage statistics

%Stats = ();    # $Stats{<stats-group>}{<stat-name>} = value.

# <stat-name>s cannot not contain spaces.  Keys of each <stats-group> array
# that contain spaces are considered special record-keeping keys.

sub GetStats
{
    unless (open(STATS, "stats.dat"))
    {                           
        print STDERR "
Couldn't open stats.dat file ($!) - continuing without stats,
";
        return;
    }

    my @Stats = <STATS>;

    eval "@Stats";

    warn $@ if $@;

    close STATS;
}

sub StatsGroups
{
    return keys(%Stats);
}

sub StatsElements
{
    my($GroupName) = @_;
    return grep($_ ne 'Group Description' && $_ ne 'Display Func Name',
                keys %{$Stats{$GroupName}});
}

sub SetStat
{
    my($Group, $stat, $value) = @_;

    if (!$Stats{$Group})
    {
        print STDERR "Attempt to write to non-existent stats group $Group: ignoring\n";
        return;
    }

# I don't understand why this line was here (MG) ...
#    return if $stat =~ m/\b\d/; #No stats with a digit in it

    if ($stat =~ m/\s+/) 
    {
	print STDERR "Attempt to write to stat with space in the name: $stat - ignoring\n";
	return;
    }
    
    $Stats{$Group}{$stat} = $value;
}

sub GetStat
{
    my($Group, $stat) = @_;

    if (!$Stats{$Group})
    {
        print STDERR "Attempt to read to non-existent stats group $Group: ignoring\n";
        return;
    }
    
    return ($Stats{$Group}{$stat});
}

sub IncrementStat
{
    my($Group, $stat, $inc_by) = @_;

    if (!$Stats{$Group})
    {
        print STDERR "Attempt to increment in non-existent stats group $Group: ignoring\n";
        return;
    }

# I don't understand why this line was here (MG) ...
#    return if $stat =~ m/\b\d/; #No stats with a digit in it
    $stat =~ s/\s+//g;
    $inc_by = 1 if (!$inc_by);

    $Stats{$Group}{$stat} = $Stats{$Group}{$stat} ?
        $Stats{$Group}{$stat} + $inc_by : $inc_by;
}

sub DeleteStat
{
    my($Group, $stat) = @_;

    $stat =~ s/\s+//g;
    return delete $Stats{$Group}{$stat};
}

sub StatsListing
{
    my(@RequiredStats) = @_;

    my($Listing) = "Firetop Mountain Statistics\n";
    $Listing .=    "---------------------------\n";
    
    foreach $group (sort @RequiredStats)
    {
        if (!grep(m/^$group$/, keys(%Stats)))
        {
            $Listing .= "(no such stats group: $group)\n";
            next;
        }

        $Listing .= "\n$group: $Stats{$group}{'Group Description'}\n";
        $Listing .= '-' x (length($group) + 2 +
                           length($Stats{$group}{'Group Description'})) ."\n";

        foreach $stat (sort {SortStatValues($Stats{$group})}
		       grep {$_ !~ / /}           # don't include control fields
		       keys(%{$Stats{$group}}))
        {
            $Listing .= 
		sprintf("%-20s %s\n",
			$stat . ":",
			&{$Stats{$group}{'Display Func Name'}}($Stats{$group}{$stat}));
        }
    }
    $Listing .= "\n";
    return($Listing);
}

sub WriteStats
{
    unless(open(STATS, ">stats.dat"))
    {
        print STDERR "Couldn't write stats file (bad luck!)\n";
        return;
    }

    print STATS Data::Dumper->Dump([\%Stats], ['*Stats']);
    
    close(STATS) or
	print STDERR "error writing STATS file (bad luck!)\n";
}

sub SortStatValues
{
    my ($StatValues)= @_;

    return($StatValues->{$a} <=> $StatValues->{$b});
}

sub DisplayStatAsIs
{
    return $_[0];
}

sub DisplayLapsedTime
{
    my($LastActive) = @_;
    my($lapse) = time() - $LastActive;
    # days since last active.
    return(int($lapse/(60*60*24)));
}

my(@InfoItems) = (
              "
 Martin Gregory    (original author and current maintainer)
 Steve Andrewartha (original playtester)
 Mel Nicholson     (added the advanced targeting options)
 John Williams     (did the original 'Multi Player' code)
 Terje Bråten   (took John's code and made a working 'Multi Player' server,
                    adding all the new 'challenge' system code)
",
              "
 'Firetop Mountain' is 11,000 lines of Perl code.
",
              "
 The 'Firetop Mountain Server' is generously hosted by Richard Rognlie on his
 Linux box 'play.gamerz.net'.  He provides this service for free for players 
 the world over.  Many thanks to him for it.
"
              );

sub DisplayInfoItem
{
    return ($InfoItems[$_[0]]);
}

1;
