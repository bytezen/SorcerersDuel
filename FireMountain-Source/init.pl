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
#      The Original Code is init.pl.
#
#      The Initial Developer of the Original Code is Martin Gregory.
#
#      Contributors: Terje Bråten, John Williams.
#
#----------------------------------------------------------------------

$Revision .= ' I9.8';

#----------------------------------------------------------------------
# Site configuration

if ($ENV{'FM_SITE'} and ("pvv" eq $ENV{FM_SITE}))
{
    $SaveDir = $Home . "/saves";
    $LogDir = $Home . "/logs";
    $VacationFile = $SaveDir . "/vacation";

    $sendmail = "$Home/fakemail";
    $lockfile = "/local/fm/lock";
    # The lockfile has to be local and not NFS mounted

    $gmAddr = "fm\@pvv.ntnu.no";
    $gmName = "FM Apprentice Referee";
    $RequiredSubject = "FM Orders";

    $MaintainerAddress = "terjebr\@pvv.ntnu.no";
    @MaintainerAddresses = ($MaintainerAddress,"mgregory\@ieee.org");
    $InputFile = shift or
        die "Need to supply input file name as second argument to process.pl\n";
    $CallProcess_pl = "|$Home/process.pl $Home -";
    # ^ Used by cleanup.pl to pipe a 'mail' to the process.pl script.
}
else
{
    $SaveDir = $Home . "/saves";
    $LogDir = $Home . "/logs";
    $VacationFile = $SaveDir . "/vacation";
    $sendmail = $ENV{'SENDMAIL'} ? $ENV{'SENDMAIL'} : "/usr/lib/sendmail -it";
    $lockfile = "lock";
    # The lockfile must not be NFS mounted

    $gmAddr = "fm\@gamerz.net";
    $gmName = "Firetop Mountain Referee";
    $RequiredSubject = "FM Orders";
    $UpdateFMUsers = 1; # If addresses should be sendt to the FM-Users mailing list

    $MaintainerAddress = "FM-Janitors\@gamerz.net";
    #@MaintainerAddresses = (
    #    "janitor\@gregories.net",
    #    "craigferguson\@shaw.ca",
    #    "akur\@gamerz.net",
    #    "yuvalsapir\@gmail.com");
    @MaintainerAddresses = (
        "craigferguson\@shaw.ca",
        "yes\@barak.net.il",
        "andy\@toucanet.com",
        "mgregory\@ieee.org",
        "neonelf\@yahoo.com",
        "akur\@gamerz.net",
        "janitor\@gregories.net",
        "wsimmons\@unicircuit.com",
        "martin\@gregories.net",
        "yuvalsapir\@gmail.com");
    $InputFile = $ARGV[0];
    $CallProcess_pl = "|$Home/process.pl $Home -";
    # ^ Used by cleanup.pl to pipe a 'mail' to the process.pl script.
}

#----------------------------------------------------------------------
# Nagger Settings...

$NagTime = 4;         # days
$AutoResignTime = 14;

$AllowedRest = 1;  # weeks per point of score.
$AllowedRetirement = 1; # months per point of score.

$ChallengeWarn = 5;  # days after which a challenge will be nagged
$ChallengeTimeout = 14; # days after which a challenge will be terminated.

$NagUser = 21;  # days after which a mageless user will be nagged
$TerminateUser = 40; # days after which a mageless user will be terminated.

$AllowedVacation = 5; # weeks
#----------------------------------------------------------------------

chomp($RefPassword = `cat $SaveDir/refpass.txt`); # The Referee's password.
# The referee may issue a GAME command in any game to update
# it and get it going. This is handy if f.ex. the game file
# has been edited to recover from a bug, and you want the
# game to continue.

# There is also a VACTION command for the referee. Syntax:
#   VACATION Referee <Ref's passwd> <List of mages>
# This put the wizzes in the list (and all other wizzes
# owned by the same player) in the vacation file.

1;
