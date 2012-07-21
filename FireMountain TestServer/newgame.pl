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
#      The Original Code is newgame.pl.
#
#      The Initial Developer of the Original Code is Terje Bråten.
#
#      Contributors: Martin Gregory.
#
#----------------------------------------------------------------------

$Revision .= " N9.11";

@OptionsList = (
           'add',
           'challenge',
           'exclude',
           'start',
           'all',
           'open',
           'closed',
           'limit',
           'nolimit',
           'spellbook',
           'addspell',
           'removespell',
           'authoritarian',
           'democratic'
           );

sub ReadNewGame
{
    my($NewGame) = @_;

    open(NEWGAME,"$NewGame.ngm") || die "Could not open file $NewGame.ngm\n$!";

    print LOG "Reading setup $NewGame\n";

    my(@GameInfo) = <NEWGAME>;
    close(NEWGAME);

    eval "@GameInfo";

    die $@ if $@;

    # Make sure that none of the challenged have been terminated by nag...
    # Note that it would be a lot nicer if we told the rest of the challenged
    # and accepted that this had happened, since they may end up wondering why
    # their game hasn't started, and where did the nag-terminated mage go.
    # However, a tidy solution to that seems like a lot of work at this point.
    # This 'hack' just makes sure we don't barf on an undefined mage during
    # challenge processing.  The situation should never arise in the first
    # place if cleanup.pl is doing its job properly!

    @Challenged = grep(defined($Wizard{$_}), @Challenged);

    return 1;
}


sub WriteNewGame
{
    local($NewGame) = @_;

    # Compute the game type.
    if ($Limit == 2)
    {
       $GameType = "Duel";
    }
    else
    {
       if (!$Open)
       {
           $GameType = (scalar(keys(%Accepted)) + @Challenged > 2) ? 
               "Melee" : "Duel";
       }
       else
       {
           $GameType = "Melee";
       }
    }

    if ($Open)
    {
       # Do not save who is challenged in open games
       @Challenged = ();
    }
    else
    {
       # No Excluded list in closed games
       @Excluded = ();
    }

    open(NEWGAME,">$NewGame.ngm") or 
	die "Can't write $NewGame.ngm: $!, stopped ";

    print LOG "Writing setup $NewGame\n";

    print NEWGAME Data::Dumper->Dump([$Comment,
				      $Open,
				      $Limit,
				      $Auth,
				      $DemTime,
				      $GameType,
				      $SpellBook,
						\%AddSpells,
						\%RemoveSpells,
				      $Challenger,
				      \%Accepted,
				      \@Challenged,
				      \@Excluded,
				      \@Subscribers],
				     ['Comment',
				      'Open',
				      'Limit',
				      'Auth',
				      'DemTime',
				      'GameType',
				      'SpellBook',
						'*AddSpells',
						'*RemoveSpells',
				      'Challenger',
				      '*Accepted',
				      '*Challenged',
				      '*Excluded',
				      '*Subscribers']);
    close(NEWGAME) or 
	die "Couldn't write $NewGame.ngm: $!, stopped ";
}

sub ReadChange
{
    local($NewGame,$Change) = @_;

    local ($Field,$Value);

# make the default value 'DEPRICATED' to indicate an unused field
# Depricated fields will _not_ be written to the .ngm file, so they
# can be deleted after a sufficient amount of time has passed.
	 %NewAddSpells = ();
	 %NewRemoveSpells = ();
    local (%GameInfoFields) = ( "Proposer" => "",
			        "NewSpellBook" => "",
			        "NewComment" => "",
			        "NewOpen" => "",
			        "NewLimit" => "",
			        "StartNow" => "",
			        "NewDemTime" => "" );
    local (%GameInfo);

# This array indicates which fields are new and are allowed to default
    local (@DefaultGameInfoFields) = ();

    if (!open(CHANGE,"$NewGame-C-$Change.ngm"))
    {
	print STDERR "Could not open $NewGame-C-$Change.ngm\n$!\n";
	return -1;
    }
    print LOG "Reading change $Change\n";

    while (($_ = <CHANGE>) ne "---BEGIN CHALLENGED---\n")
    {
	chomp;
	next if (!m/\S+/);
	($Field, $Value) = m/^(\w+)\:(.*)$/ or die "Error in file $NewGame-C-$Change.ngm\n";
	if ($Field eq "NewAddSpells")
	{
		my ($gestures, $spellname) = split(/,\s*/, $Value);
		$NewAddSpells{$gestures} = $spellname;
	}
	elsif ($Field eq "NewRemoveSpells")
	{
		my ($gestures, $spellname) = split(/,\s*/, $Value);
		$NewRemoveSpells{$gestures} = $spellname;
	}
	else
	{
	die "unknown field: $Field ($_)\n"
	    if !defined $GameInfoFields{$Field};
	$GameInfo{$Field}=$Value;
#	print LOG "$Field: $Value\n";
    }
    }

    foreach $Field (keys %GameInfoFields)
    {
	next if $GameInfoFields{$Field} eq 'DEPRICATED';
	if (!defined $GameInfo{$Field})
	{
	    if (grep(/^$Field$/,@DefaultGameInfoFields))
	    {
		$GameInfo{$Field} = $GameInfoFields{$Field};
#                print LOG "Missing field $Field -- default assigned\n";
            }
            else
            {
                die "Missing required New Game field: $Field\n";
            }
	}
    }

    $Proposer = $GameInfo{'Proposer'};
    $NewSpellBook = $GameInfo{'NewSpellBook'};
    $NewComment = $GameInfo{'NewComment'};
    $NewOpen = $GameInfo{'NewOpen'};
    $NewLimit = $GameInfo{'NewLimit'};
    $StartNow = $GameInfo{'StartNow'};
    $NewAuth = 0;
    $NewDemTime = $GameInfo{'NewDemTime'};
    if ($NewDemTime eq "Authoritarian")
    {
	$NewAuth = 'Yes';
    }

#    $TimeLimits = $GameInfo{'TimeLimits'};
#    ($NewMoveTime, $NewFirstWarnTime, $NewWarnFreq) = split(',',$TimeLimits);

    local ($num,$Name) = (0,"");

    @NewChallenged = ();
    while (1)
    {
	$Name = <CHANGE>;
	chomp ($Name);
	last if $Name eq "---BEGIN EXCLUDED---";
	push (@NewChallenged,$Name);
	$num++;
    }
#    print LOG "$num more players are challenged\n";
    ($num = @NewExcluded = <CHANGE>) || ($num=0);
    chomp @NewExcluded;
#    print LOG "$num players are excluded\n";

    close CHANGE;
    return 1;
}


sub WriteChange
{
    local($NewGame,$Change) = @_;

    open(CHANGE,">$NewGame-C-$Change.ngm") || die $!;

    print LOG "Writing change $Change in game $NewGame\n";

    print CHANGE "Proposer:$Proposer\n";
#    print LOG "Proposer = $Proposer\n";

    print CHANGE "NewSpellBook:$NewSpellBook\n";

	 foreach my $gestures (keys %NewAddSpells)
	 {
        print CHANGE "NewAddSpells:$gestures, $NewAddSpells{$gestures}\n";
	 }

	 foreach my $gestures (keys %NewRemoveSpells)
	 {
        print CHANGE "NewRemoveSpells:$gestures, $NewRemoveSpells{$gestures}\n";
	 }

    print CHANGE "NewComment:$NewComment\n";
#    print LOG "New comment: $NewComment\n" if $NewComment;

    print CHANGE "NewOpen:$NewOpen\nNewLimit:$NewLimit\nStartNow:$StartNow\n";
#    print LOG "New Open = $NewOpen, New limit = $NewLimit\n"
#	if $NewOpen or $NewLimit;
#    print LOG "StartNow = $StartNow\n" if $StartNow;

    if ($NewAuth and $NewAuth eq "Yes")
    {
	print CHANGE "NewDemTime:Authoritarian\n";
#	print LOG "New mode: Authoritarian\n";
    }
    else
    {
	print CHANGE "NewDemTime:$NewDemTime\n";
#	print LOG "New DemTime=$NewDemTime\n" if $NewDemTime;
    }

#    print CHANGE "NewTimeLimits:$NewMoveTime,$NewFirstWarnTime,$NewWarnFreq\n";
#    print LOG "New time limits: $NewMoveTime,$NewFirstWarnTime,$NewWarnFreq\n"
#	if $NewMoveTime;

    print CHANGE "---BEGIN CHALLENGED---\n";

    print CHANGE join("\n",@NewChallenged);
    local ($num);
    ($num = @NewChallenged) || ($num=0);
    if ($num)
    {
	print CHANGE "\n";
#	print LOG "$num more players are challenged\n";
    }

    print CHANGE "---BEGIN EXCLUDED---\n";

    print CHANGE join("\n",@NewExcluded);
    ($num = @NewExcluded) || ($num=0);
    if ($num)
    {
	print CHANGE "\n";
#	print LOG "$num more players are excluded\n";
    }

    close CHANGE;
}


sub NewGame
{
    $Challenger = shift;

    my($AllChallenged) = 0;

    # Global variables describing the new game...
    $Open = 0;
    $Limit = 0;
    $Auth = 0;
    $DemTime = 0;
#    $DemTime = "1d";
#    $MoveTime = "14d";
#    $FirstWarnTime = "5d";
#    $WarnFreq = "4d";
    $SpellBook = "Standard";
    %Accepted = ();
    @Challenged = ();
    @Excluded = ();
    @Subscribers = ();

	 %AddSpells = ();
	 %RemoveSpells = ();

    $options = join(' ',@_);

    $Comment = "";
    if ($options =~ s/,?\s*comment\s(.*)$//i)
    {
	$Comment = $1;
    }

	 # Can't lowercase addspell and removespell gesture list
    #$options = "\L$options";
    @options = split(/\s*,\s*/,$options);

    $msg = "Initiating a new challenge...\n\n";
    $errs = 0;

  foreach $option (@options)
  {
      @arg = split(/\s/,$option);
      while ($#arg >= 0)
      {
        my $curroption = shift(@arg);
		  $curroption = "\L$curroption";

        if ($curroption eq "spellbook")
        {
	    my (@choises) = keys %SpellBooks;
	    if (defined($arg[0]) and grep {$arg[0] =~ /^$_/i} @choises)
	    {
		my ($s) = shift(@arg);
		$SpellBook = (grep {$s =~ /^$_/i} @choises)[0];
	    }
	    else
	    {
	        $msg .= "> The option 'spellbook' must have one of the following arguments:\n";
	        my ($book);
	        foreach $book (sort @choises)
	        {
		    $msg .= ">      $book\n";
	        }
	        $errs++;
	    }
        }
  
        elsif ($curroption eq "addspell")
        {
				my $badaddspell = 0;
				my $gestures;
				my $spellname;
            if ($#arg < 1)
            {
                $msg .= "> Must provide gestures and spell name for $curroption\n";
                $errs++;
						  $badaddspell++;
            }
				else
				{
				    $gestures = shift (@arg);
					 if ($gestures !~ /^[DFPWScdfws]+$/)
					 {
					     $msg .= "> Gestures must only include the characters D, F, P, W, S, c, d, f, w, or s\n";
						  $errs++;
						  $badaddspell++;
					 }

					 $spellname = join (" ", @arg);
					 @arg = ();
					 my $goodname;
					 if (($goodname = &GetValidSpellName ($spellname)) eq "")
					 {
					     $msg .= "> $spellname is not a valid spell name\n";
						  $errs++;
						  $badaddspell++;
					 }
					if (!$badaddspell)
					{
					   if (!defined $AddSpells{$gestures}) {
					       $AddSpells{$gestures} = [];
					   }
						push (@{$AddSpells{$gestures}}, $goodname);
					}
				}
        }

		  elsif ($curroption eq "removespell")
		  {
				my $badremovespell = 0;
				my $gestures;
				my $spellname;
            if ($#arg < 1)
            {
                $msg .= "> Must provide gestures and spell name for $curroption\n";
                $errs++;
						  $badremovespell++;
            }
				else
				{
				    $gestures = shift (@arg);
					 if ($gestures !~ /^[DFPWScdfws]+$/)
					 {
					     $msg .= "> Gestures must only include the characters D, F, P, W, S, c, d, f, w, or s\n";
						  $errs++;
						  $badremovespell++;
					 }

					 $spellname = join (" ", @arg);
					 @arg = ();
					 my $goodname;
					 if (($goodname = &GetValidSpellName ($spellname)) eq "")
					 {
					     $msg .= "> $spellname is not a valid spell name\n";
						  $errs++;
						  $badremovespell++;
					 }
					if (!$badremovespell)
					{
					   if (!defined $RemoveSpells{$gestures}) {
					       $RemoveSpells{$gestures} = [];
					   }
						push (@{$RemoveSpells{$gestures}}, $goodname);
					}
				}
		  }
  
        elsif ($curroption eq "open")
        {
	    $Open = 1;  # default to one mage per player.
	    if (defined($arg[0]))
	    {
	        # if ($arg[0] !~ /^[\d]+$/)
	        # {
		#    $msg .= "> The option 'open' only takes a numeric argument\n";
		#    $errs++;
		#    next OPTION;
	        #}
  
	        if ($arg[0] =~ /^[\d]+$/)
	        {
		    $Open = shift(@arg);
		    if ($Open == 0)
		    {
			$Open = 'Yes';
		    }
	        }
	    }
        }
  
  
        elsif ($curroption eq "closed")
        {
	    $Open=0;
        }
  
  
        elsif ($curroption eq "limit")
        {
	    if ($#arg < 0 || $arg[0] !~ /^[\d]+$/)
	    {
	        $msg .= "> Need to specify a numeric limit\n";
	        $errs++;
	    }
  
	    elsif ($arg[0] < 2)
	    {
	        $msg .= "> You cannot limit the challenge to less than 2 players\n";
	        $errs++;
	    }
	    $Limit = shift(@arg);
        }
  
  
        elsif ($curroption eq "nolimit")
        {
	    $Limit = 0;
        }
  
  
        elsif ($curroption =~ /^auth/)
        {
	    $Auth=1;
        }
  
        
        elsif ($curroption =~ /^dem/)
        {
	    $Auth=0;
	    $DemTime="1d";
  #	  if (@arg)
  #	  {
  #	      $DemTime = &ParseTime(@arg);
  #	  }
	    next;
        }
  
  
  #      if ($key eq "timelimit")
  #      {
  #	  if ("none" eq $arg[0])
  #	  {
  #	      $MoveTime = 0;
  #	      next OPTION;
  #	  }
  #
  #	  $MoveTime = &ParseTime(@arg);
  #	  next if $errs;
  #
  #	  shift(@arg);
  #	  $key = shift(@arg);
  #	  $key = shift(@arg) if $key and $key =~ m/^[hd]/;
  #	  next if not $key;
  #	  if ($key ne "warn")
  #	  {
  #	      $msg .= "> Wrong syntax in \"timelimit\" option\n";
  #	      $msg .= ">  Can't figure what you ment by $key\n";
  #	  }
  #
  #	  $FirstWarnTime =&ParseTime(@arg);
  #	  next if $errs;
  #
  #	  shift(@arg);
  #	  $key = shift(@arg);
  #	  $key = shift(@arg) if $key and $key =~ m/^[hd]/;
  #	  next if not $key;
  #	  if ($key ne "each")
  #	  {
  #	      $msg .= "> Wrong syntax in \"timelimit\" option\n";
  #	      $msg .= ">  Can't figure what you meant by $key\n";
  #	  }
  #
  #	  $WarnFreq = &ParseTime(@arg);
  #	  next;
  #      }
  
  
        elsif ($curroption eq "challenge" or $curroption eq "add")
        {
          # Mages list will be @arg up to next option or end
          my @Mages = ();
          while (defined($arg[0]) && !grep {$arg[0] eq $_} @OptionsList)
          {
            push @Mages, shift(@arg);
          }

          if ($#Mages < 0)
          {
	    $msg .= "> $curroption does not make much sense without at least one wizard!\n";
            $errs++;
          } 

	  foreach $Mage (@Mages)
	  {
	      $Mage = &GetName($Mage);
  
	      if (!$Wizard{$Mage})
	      {
		  $msg .= "> $Mage is not a recognised wizard!\n";
		  $errs++;
	      }
  
	      if ($Mage eq $Challenger)
	      {
		  $msg .= "You want to challenge your self? Are you shizofren?\n";
		  $errs++;
	      }
  
	      if ($Wizard{$Mage}{'Busy'})
	      {
	          my ($Game) = $Wizard{$Mage}{'Busy'};
		  if ($Game !~ s/^N//)
		  {
		      $msg .= "> $Mage is already engaged in battle $Game at this time!\n";
		  }
		  else
		  {
	             $msg .= "> $Mage has already accepted challenge $Game\n";
		  }
	          $errs++;
	      }
  
              if ($Wizard{$Mage}{'Retired'})
              {
		  $msg .= "> $Mage has retired!\n";
		  $errs++;
              }
	      
  
	      if (@Excluded)
	      {
	        EXCL: foreach $n (0 .. $#Excluded)
	        {
		    if ($Excluded[$n] eq $Mage)
		    {
		        splice(@Excluded,$n,1);
		        last EXCL;
		    }
	        }
	      }
  
	      if (grep (/^$Mage$/,@Challenged))
	      {
		  $msg .= "> $Mage cannot be challenged twice.\n";
		  $errs++;
	      }
  
	      push (@Challenged, $Mage);
	  }
        }
  
  
        elsif ($curroption eq "exclude")
        {
          # Mages list will be @arg up to next option or end
          my @Mages = ();
          while (defined($arg[0]) && !grep {$arg[0] eq $_} @OptionsList)
          {
            push @Mages, shift(@arg);
          }

          if ($#Mages < 0)
          {
	    $msg .= "> $curroption does not make much sense without at least one wizard!\n";
            $errs++;
          } 

	  foreach $Mage (@Mages)
	  {
	      $Mage = &GetName($Mage);
  
	      if (!$Wizard{$Mage})
	      {
		  $msg .= "> $Mage is not a recognised wizard!\n";
		  $errs++;
	      }
  
	      if ($Mage eq $Challenger)
	      {
		  $msg .= "> You cannot exclude your self!\n";
		  $errs++;
	      }
  
	      if (grep (/^$Mage$/, @Excluded))
	      {
		  $msg .= "> $Mage is already excluded.\n";
		  $errs++;
	      }
  
	      local ($found,$n) = (0,0);
	      if (@Challenged)
	      {
	        CHALL:foreach $n (0 .. $#Challenged)
	        {
		    if ($Challenged[$n] eq $Mage)
		    {
		        $found = 1;
		        splice(@Challenged,$n,1);
		        last CHALL;
		    }
	        }
	      }
  
	      if (!$found and !$Open)
	      {
		  $msg .= "> $Mage has not been challenged in the first place.\n";
		  $errs++;
	      }
	      
	      push (@Excluded, $Mage) if $Open;
          }
        }
  

        elsif ($curroption eq "all")
        {
	    $AllChallenged = 1;
	    $Open = 1 unless $Open; #Challenges to all should be open
	    @Challenged = ();
	  MAGE:foreach $Mage (@WizardNames)
	  {
	      next MAGE if $Mage eq $Challenger or 
		  $Wizard{$Mage}{'Busy'} or $Wizard{$Mage}{'Retired'} or
		  grep (/^$Mage$/, @Excluded);
  
	      push (@Challenged, $Mage);
	  }
        }
   
        else
        {
          $msg .= "> $curroption is an unknown option.\n";
          $errs++;
        }
      }
  }


    if (!$Open and !@Challenged)
    {
	$msg .= "> No mages are challenged!\n";
	$errs++;
    }

    if ($errs)
    {
	 # Split line on ,ADDSPELL and ,REMOVESPELL in case it is really long
	 $h =~ s/,\s*(ADDSPELL)/,\n $1/gi;
	 $h =~ s/,\s*(REMOVESPELL)/,\n $1/gi;
	$msg .= "$h $errs errors.\nInitiation of challenge is aborted.\n\n";
	print MAIL $msg;
	return;
    }

    if ($Wizard{$Challenger}{'Retired'})
    {
	$Wizard{$Challenger}{'Retired'} = '0';
    }

    $NewGame = &NewName("GameNumber");

    local (@Wizlist) = @Challenged;
    # It is possible to challenge people to join an open game
    # but it won't have a @Challenged list, since it is open.

    open (CHANGENO, ">ChangeNumber.$NewGame") || die $!;
    print CHANGENO "0\n";
    close CHANGENO;

    &DoAccept($Challenger);

    $msg .= "You have initiated a new challenge!\n\n";
    print MAIL $msg;

    local ($GameState) = &DisplayNewGameState($NewGame); # (do once only)

    foreach $Name (@Wizlist)
    {
	&OpenMail(CHALLENGE,$Users{$Wizard{$Name}{'User'}}{'Address'});
	print CHALLENGE &SummonsNotification($Challenger,$Name,$NewGame,
					     $AllChallenged);
	print CHALLENGE $GameState;
	close CHALLENGE;
	print MAIL" $Name has been summoned to Firetop Mountain.\n\n";
    }

    print MAIL $GameState;
}


#sub ParseTime
#{    
#    $_[0] .= $_[1] if $_[1];
#    local ($time,$unit) = $_[0] =~ m/^(\d+)([hd])/;
#    if (!$time or !$unit)
#    {
#	$msg .= "> Wrong time format: $arg[0]\n";
#	$msg .= "   A time must be given in units hours(h) or days(d)\n";
#	$errs++;
#	return 0;
#    }
#    return $time.$unit;
#}


sub ChangeNewGame
{
    $NewGame = shift;
    $Proposer = shift;

	 # $Proposer might have a trailing , due to adding ADDSPELL or REMOVESPELL
	 # parameters on a following line...
	 $Proposer =~ s/,+$//;
    $Player = $Proposer;

    &ReadNewGame($NewGame) || die "CHANGE could not find new game $NewGame!";
    if (!defined ($Accepted{$Proposer}))
    {
	print MAIL "$h You are not among those that have accepted challenge $NewGame.\n";
	print MAIL " (At least not yet.)\n\n";
	print MAIL &DisplayNewGameState($NewGame);
	return;
    }

    $options = join(' ',@_);

    $NewSpellBook = "";
	 %NewAddSpells = ();
	 %NewRemoveSpells = ();
    $NewComment = "";
    $NewOpen = 0;
    $NewLimit = 0;
    $StartNow = 0;
    $NewAuth = 0;
    $NewDemTime = 0;
#    $NewMoveTime = 0;
#    $NewFirstWarnTime = 0;
#    $NewWarnFreq = 0;
    @NewChallenged = ();
    @NewExcluded = ();
    
    if ($Auth) 
    {
	if ($Proposer eq $Challenger)
	{
	    $msg = "Changing challenge $NewGame ...\n\n";
	}
	else
	{
	    $msg = "$h Only $Challenger can do changes to challenge $NewGame.\n\n";
	    print MAIL $msg;
	    return;
	}
    }
    else
    {
	$msg = "You propose a change to challenge $NewGame ...\n\n";
    }

    $numAccepted = keys %Accepted;
    $errs = 0;

    # Save comment from end of options list and remove it from options list
    # before options are converted to lower case
    if ($options =~ s/,?\s*comment\s(.*)$//i)
    {
	$NewComment = $1;
    }

    #$options = "\L$options";
    @options = split(/\s*,\s*/,$options);

# $option will loop through all comma separated options
  foreach $option (@options)
  {
      # @arg will contain the whitespace seperated options/parameters
      # if there are entries left after the option and parameters are
      # processed, they should be treated as possible new options
      # and parameters.
      @arg = split(/\s+/,$option);
      while ($#arg >= 0)
      {
        my $curroption = shift(@arg);
        $curroption = "\L$curroption";

        if ($curroption eq "spellbook")
        {
	    my (@choises) = keys %SpellBooks;
	    if (defined($arg[0]) and grep {$arg[0] =~ /^$_/i} @choises)
	    {
		my ($s) = shift(@arg);
		$NewSpellBook = (grep {$s =~ /^$_/i} @choises)[0];
	    }
	    else
	    {
	      $msg .= "> The option 'spellbook' MUST have one of the following arguments:\n";
	      my ($book);
	      foreach $book (sort @choises)
	      {
	        $msg .= ">      $book\n";
	      }
	      $errs++;
	    }
        }


        elsif ($curroption eq "addspell")
        {
				my $badaddspell = 0;
				my $gestures;
				my $spellname;
            if ($#arg < 1)
            {
                $msg .= "> Must provide gestures and spell name for $curroption\n";
                $errs++;
						  $badaddspell++;
            }
				else
				{
				    $gestures = shift (@arg);
					 if ($gestures !~ /^[DFPWScdfws]+$/)
					 {
					     $msg .= "> Gestures must only include the characters D, F, P, W, S, c, d, f, w, or s\n";
						  $errs++;
						  $badaddspell++;
					 }

					 $spellname = join (" ", @arg);
					 @arg = ();
					 my $goodname;
					 if (($goodname = &GetValidSpellName ($spellname)) eq "")
					 {
					     $msg .= "> $spellname is not a valid spell name\n";
						  $errs++;
						  $badaddspell++;
					 }
					if (!$badaddspell)
					{
					   if (!defined $NewAddSpells{$gestures}) {
					       $NewAddSpells{$gestures} = [];
					   }
						push (@{$NewAddSpells{$gestures}}, $goodname);
					}
				}
        }

		  elsif ($curroption eq "removespell")
		  {
				my $badremovespell = 0;
				my $gestures;
				my $spellname;
            if ($#arg < 1)
            {
                $msg .= "> Must provide gestures and spell name for $curroption\n";
                $errs++;
						  $badremovespell++;
            }
				else
				{
				    $gestures = shift (@arg);
					 if ($gestures !~ /^[DFPWScdfws]+$/)
					 {
					     $msg .= "> Gestures must only include the characters D, F, P, W, S, c, d, f, w, or s\n";
						  $errs++;
						  $badremovespell++;
					 }

					 $spellname = join (" ", @arg);
					 @arg = ();
					 my $goodname;
					 if (($goodname = &GetValidSpellName ($spellname)) eq "")
					 {
					     $msg .= "> $spellname is not a valid spell name\n";
						  $errs++;
						  $badremovespell++;
					 }
					if (!$badremovespell)
					{
					   if (!defined $NewRemoveSpells{$gestures}) {
					       $NewRemoveSpells{$gestures} = [];
					   }
						push (@{$NewRemoveSpells{$gestures}}, $goodname);
					}
				}
		  }
  
        elsif ($curroption eq "open")
        {
	    $NewOpen = 1;
	    if (defined($arg[0]))
	    {
	        #if ($arg[0] !~ /^[\d]+$/)
	        #{
		#    $msg .= "> The option 'open' only takes a numeric argument\n";
		#    $errs++;
		#    next OPTION;
	        #}
  
	        if ($arg[0] =~ /^[\d]+$/)
	        {
		    $NewOpen = shift(@arg);
		    if ($NewOpen == 0)
		    {
			$NewOpen = 'Yes';
		    }
	        }
	    }
        }

  
        elsif ($curroption eq "closed")
        {
	    $NewOpen="No";
	    next;
        }
      
  
        elsif ($curroption eq "limit")
        {
	  if ( defined($arg[0]) && ($arg[0] =~ /^[\d]+$/))
          {
            my $limitparm = shift(@arg);
	    if ($limitparm < 2)
	    {
	      $msg .= "> You cannot limit the game to less than 2 players\n";
	      $errs++;
	    }
	    elsif ($limitparm < $numAccepted)
	    {
	      $msg .= "> $numAccepted mages have already joined this new game,\n".
	   "   you cannot limit the game to less than that now.\n";
	      $errs++;
	    }
	    $NewLimit = $limitparm;
          }
          else
          {
	    $msg .= "> The option 'limit' MUST have one numeric argument.\n";
	    $errs++;
          }
        }

  
        elsif ($curroption eq "nolimit")
        {
	    $NewLimit = "No_Limit";
        }

  
        elsif ($curroption eq "start")
        {
	    if ( ($numAccepted) > 1)
	    {
	        $StartNow = 'Start';
	    }
	    else
	    {
	        $msg .= "> You cannot start the battle ".
		    "when no one else have accepted to join.";
	        $errs++;
	    }
        }
  
  
        elsif ($curroption =~ /^auth/)
        {
	    $NewAuth = "Yes";
        }
  
        
        elsif ($curroption =~ /^dem/)
        {
	    $NewAuth = "No";
	    $NewDemTime = "1d";
  #	  if (@arg)
  #	  {
  #	      $NewDemTime = &ParseTime(@arg);
  #	  }
        }
  
  
  #      if ($key eq "timelimit")
  #      {
  #	  if ("none" eq $arg[0])
  #	  {
  #	      $NewMoveTime = "No";
  #	      next OPTION;
  #	  }
  #
  #	  $NewMoveTime = &ParseTime(@arg);
  #	  next if $errs;
  #
  #	  shift(@arg);
  #	  $key = shift(@arg);
  #	  $key = shift(@arg) if $key and $key =~ m/^[hd]/;
  #	  next if not $key;
  #	  if ($key ne "warn")
  #	  {
  #	      $msg .= "> Wrong syntax in \"timelimit\" option\n";
  #	      $msg .= "   Can't figure what you ment by $key\n";
  #	  }
  #
  #	  $NewFirstWarnTime =&ParseTime(@arg);
  #	  next if $errs;
  #
  #	  shift(@arg);
  #	  $key = shift(@arg);
  #	  $key = shift(@arg) if $key and $key =~ m/^[hd]/;
  #	  next if not $key;
  #	  if ($key ne "each")
  #	  {
  #	      $msg .= "> Wrong syntax in \"timelimit\" option\n";
  #	      $msg .= "   Can't figure what you ment by $key\n";
  #	  }
  #
  #	  $NewWarnFreq = &ParseTime(@arg);
  #	  next;
  #      }
  
  
        elsif ($curroption eq "add" or $curroption eq "challenge")
        {
          # Mages list will be @arg up to next option or end
          my @Mages = ();
          while (defined($arg[0]) && !grep {$arg[0] eq $_} @OptionsList)
          {
            push @Mages, shift(@arg);
          }

          if ($#Mages < 0)
          {
	    $msg .= "> $curroption does not make much sense without at least one wizard!\n";
            $errs++;
          } 

	  foreach $Mage (@Mages)
	  {
	      $Mage = &GetName($Mage);
  
	      if (!$Wizard{$Mage})
	      {
		$msg .= "> $Mage is not a recognised wizard!\n";
		$errs++;
	      }
  
	      if ($Mage eq $Proposer)
	      {
		  $msg .= "> You want to challenge your self? Are you shizofren?\n";
		  $errs++;
	      }
  
	      if ($Accepted{$Mage})
	      {
		  $msg .= "> $Mage has allready accpted to take part in this battle.\n";
		  $errs++;
	      }
  
	      if ($Wizard{$Mage}{'Busy'})
	      {
		  my ($Game) = $Wizard{$Mage}{'Busy'};
		  if ($Game !~ s/^n//)
		  {
		      $msg .= "> $Mage is already engaged in battle $Game at this time!\n";
		  }
		  else
		  {
		      $msg .= "> $Mage has already accepted challenge $Game.\n";
		  }
		  $errs++;
	      }

              if ($Wizard{$Mage}{'Retired'})
              {
		  $msg .= "> $Mage has retired!\n";
		  $errs++;
              }

	      if (grep (/^$Mage$/, @Challenged))
	      {
		  $msg .= "> $Mage cannot be challenged twice.\n";
		  $errs++;
	      }

	      push(@NewChallenged,$Mage);
	  }
        }

        elsif ($curroption eq "exclude")
        {
          # Mages list will be @arg up to next option or end
          my @Mages = ();
          while (defined($arg[0]) && !grep {$arg[0] eq $_} @OptionsList)
          {
            push @Mages, shift(@arg);
          }

          if ($#Mages < 0)
          {
	    $msg .= "> $curroption does not make much sense without at least one wizard!\n";
            $errs++;
          } 

	  foreach $Mage (@Mages)
	  {
	      $Mage = &GetName($Mage);

	      if (!$Wizard{$Mage})
	      {
		  $msg .= "> $Mage is not a recognised wizard!\n";
		  $errs++;
	      }
  
	      if ($Mage eq $Proposer)
	      {
		  $msg .= "> You cannot exclude your self!\n";
		  $errs++;
	      }

	      if ($Accepted{$Mage})
	      {
		  $msg .= "> Too late to exlude $Mage now. :)\n";
		  $errs++;
	      }

	      if (grep (/^Mage$/, @Excluded))
	      {
		  $msg .= "> $Mage cannot be more excluded.\n";
		  $errs++;
	      }

  
	      if (!grep (/^$Mage$/, @Challenged) and !$Open)
	      {
		  $msg .= "> $Mage has not been challenged in the first place.\n";
		  $errs++;
	      }
  
	      push (@NewExcluded, $Mage);
	  }
        }

        
        elsif ($curroption eq "all")
        {
	  $NewOpen = 1 unless $Open or $NewOpen;
	  foreach $Mage (@WizardNames)
	  {
	    if (!($Accepted{$Mage} or 
		  grep (/^$Mage$/, (@Challenged, @Excluded)) or
		  $Wizard{$Mage}{'Busy'} or $Wizard{$Mage}{'Retired'}))
              {
  
	        push (@NewChallenged, $Mage);
              }
	  }
        }

        else
        {
          $msg .= "> $curroption is an unknown option.\n";
          $errs++;
        }
      }
  }


    if ($errs)
    {
	 # Split line on ,ADDSPELL and ,REMOVESPELL in case it is really long
	 $h =~ s/,\s*(ADDSPELL)/,\n $1/gi;
	 $h =~ s/,\s*(REMOVESPELL)/,\n $1/gi;
	$msg .= "$h $errs errors.\n";
	$msg .= "The referee shakes his head and refutes ".
	    "your confusing proposal for a change.\n\n";
	print MAIL $msg;
	return;
    }


    $msg .= "The referee takes note of your proposal for a change\n".
	"in the game setup $NewGame.\n\n";
    print MAIL $msg;
    $msg="";

    if ($Auth or $numAccepted==1)
    {
	&DoChange;
	return;
    }

    if ($numAccepted==2)
    {
	$msg = "50% of those that have accepted to join this game are for your proposed change.\n";
	if ($Proposer eq $Challenger)
	{
	    $msg .= "You initiated this challenge and therfore have a double vote,\n".
		" so the change takes effect right away.\n\n";
	    print MAIL $msg;
	    &DoChange;
	    return;
	}
    }

    $msg .= "If the majority of those who have accepted this challenge\n".
	"accept the change, it will take effect.\n\n";
    print MAIL $msg;

    $Change = &NewName("ChangeNumber.$NewGame");
    &WriteChange($NewGame,$Change);
    foreach $Name (keys %Accepted)
    {
	$Accepted{$Name}->[$Change] = 0;
    }
    $Accepted{$Proposer}->[$Change] = 'yes';
    &WriteNewGame($NewGame);

    &CheckChange($Change);
    return if $ChangeDone;

    local ($DisplayNewState) = &DisplayNewGameState($NewGame);
    #Taking this call out of the loop to save time
    foreach $Name (keys %Accepted)
    {
	next if $Name eq $Proposer;
	&OpenMail(CHANGE,$Users{$Wizard{$Name}{'User'}}{'Address'});
	print CHANGE &ChangeProposalNotification($Proposer,$Name,$NewGame,$Change);
	print CHANGE $DisplayNewState;
	close CHANGE;
	print MAIL" $Name has been notified.\n\n";
    }
    print MAIL $DisplayNewState;

#    &pushTask($DemTime,"$NewGame-C-$Change","DemTimeOut") if $DemTime;
}


sub DoChange
{
# Assumes that a $NewGame is set and read in,
# and that the new changes are set or read in.

    if ($NewComment)
    {
	$Comment = $NewComment;
    }

    if ($NewSpellBook)
    {
	$SpellBook = $NewSpellBook;
    }

	 my @gestures = keys %NewAddSpells;
	 if ($#gestures >= 0)
	 {
	     foreach my $g (@gestures)
		  {
		      $AddSpells{$g} = $NewAddSpells{$g};
		  }
	 }

	 @gestures = keys %NewRemoveSpells;
	 if ($#gestures >= 0)
	 {
	     foreach my $g (@gestures)
		  {
		      $RemoveSpells{$g} = $NewRemoveSpells{$g};
		  }
	 }

    if ($NewOpen)
    {
	if ($NewOpen ne "No")
	{
	    $Open = $NewOpen;
	}
	else
	{
	    $Open = 0;
	}
    }


    if ($NewLimit)
    {
	if ($NewLimit ne "No_Limit")
	{
	    $Limit = $NewLimit;
	}
	else
	{
	    $Limit = 0;
	}
    }


    if ($NewAuth)
    {
	if ($NewAuth ne "No")
	{
	    $Auth = $NewAuth;
	}
	else
	{
	    $Auth = 0;
	}
    }


    if ($NewDemTime)
    {
	$DemTime = $NewDemTime;
    }

#    if ($NewMoveTime)
#    {
#	if ($NewMoveTime ne "No")
#	{
#	    $MoveTime = $NewMoveTime;
#	    $FirstWarnTime = $NewFirstWarnTime;
#	    $WarnFreq = $NewWarnFreq;
#	}
#	else
#	{
#	    $MoveTime = 0;
#	}
#    }

    my ($n,$m);
    if (!$StartNow and @NewChallenged)
    {
	for ($m=0; $m <= $#NewChallenged; $m++)
	{
	  EXCL:foreach $n (0 .. $#Excluded)
	  {
	      if ($Excluded[$n] eq $NewChallenged[$m])
	      {
		  splice(@Excluded,$n,1);
		  last EXCL;
	      }
	  }

	    if ($Wizard{$NewChallenged[$m]}{'Busy'} or
		$Wizard{$NewChallenged[$m]}{'Retired'})
	    {
		splice (@NewChallenged,$m--,1);
	    }
	}

	@Challenged = (@Challenged, @NewChallenged);
    }

    if (@NewExcluded)
    {
	if (!$Open and @Challenged)
	{
	    foreach $Mage (@NewExcluded)
	    {
	      CHALL:for ($n=0;$n<=$#Challenged;$n++)
	      {
		  if ($Challenged[$n] eq $Mage)
		  {
		      splice(@Challenged,$n,1);
		      &OpenMail(EXCLUDED,$Users{$Wizard{$Mage}{'User'}}{'Address'});
		      print EXCLUDED &ExcludeNotification($Mage,$NewGame);
		      close EXCLUDED;
		      last CHALL;
		  }
	      }
	    }
	}

	@Excluded = (@Excluded, @NewExcluded);
    }

    $numAccepted = keys %Accepted;


    if ( ($StartNow and $numAccepted>1) or
	 (!$Open and !@Challenged and $numAccepted>1) or
	 ($numAccepted == $Limit) )
    {
	&StartGame;
	return;
    }

    local ($CurrentProposer,@Notify) = ($Proposer,());
    # All variables pertaining to a particular change
    # is destroyed by &DisplayNewGameState
    if (@NewChallenged)
    {
	@Notify = @NewChallenged;
    }

    WriteNewGame($NewGame);
    local ($GameState) = &DisplayNewGameState($NewGame);
    $Proposer = $CurrentProposer; # Restore the right Proposer to this change

    if (@Notify)
    {
	foreach $Name (@Notify)
	{
	    &OpenMail(CHALLENGE,$Users{$Wizard{$Name}{'User'}}{'Address'});
	    print CHALLENGE &SummonsNotification($Challenger,$Name,$NewGame,
						 0); #dont handle 'all' here
	    print CHALLENGE $GameState;
	    close CHALLENGE;
	    print MAIL" $Name has been summoned to Firetop Mountain.\n\n";
	}
    }

  MAGE:foreach $Mage (keys %Accepted, @Challenged)
  {
      next if $Mage eq $Player or grep (/^$Mage$/,@NewChallenged);

      &OpenMail(CHANGE,$Users{$Wizard{$Mage}{'User'}}{'Address'});
      print CHANGE &ChangeNotification($Proposer,$Mage,$NewGame);
      print CHANGE $GameState;
      close CHANGE;
  }

    $msg = "The $gmName does some changes to game setup $NewGame,\n";
    if ($Proposer eq $Player)
    {
        $msg .= "implementing your proposal.\n\n";
    }
    else
    {
        $msg .= "implementing $Proposer\'s proposal.\n\n";
    }
    print MAIL $msg;
    print MAIL $GameState;
}


sub StartGame
{
    if (!$Open and @Challenged)
    {
	foreach $Mage (@Challenged)
	{
	    &OpenMail(EXCLUDED,$Users{$Wizard{$Mage}{'User'}}{'Address'});
	    print EXCLUDED &ExcludeNotification($Mage,$NewGame);
	    close EXCLUDED;
	}
    }

    $DidSomething = 1;
    $GameStarted = 1;

	 $SpellBookName = $SpellBook;
    %SpellBook = %{$SpellBooks{"\u$SpellBookName"}};
	 foreach my $g (keys %RemoveSpells)
	 {
             @GestureSpells = grep {!grep (/$_/, @{$RemoveSpells{$g}})}  @{$SpellBook{$g}};
             if ($#GestureSpells < 0) {
                 delete $SpellBook{$g};
             } else {
                 $spellBook{$g} = \@GestureSpells;
             }
		  $SpellBookName = "Custom";
	 }
	 foreach my $g (keys %AddSpells)
	 {
	     push(@{$SpellBook{$g}}, @{$AddSpells{$g}});
		  $SpellBookName = "Custom";
	 }

    @Players = keys %Accepted;
    $GameName = $NewGame;
    &CreateGame($GameName, @Players);
    &PurgeNewGame($NewGame);

    $GameType = (@Players == 2) ? "Duel" : "Melee";

    foreach $Name (@Players)
    {
	$Wizard{$Name}{'Busy'} = $GameName;

	SUBSCR: foreach $n (0 .. $#Subscribers)
	{
	    if ($Subscribers[$n] eq $Wizard{$Name}{'User'})
	    {
		splice(@Subscribers,$n,1);
		last SUBSCR;
	    }
	}
    }

    foreach $Name (@Players)
    {
	if ($Name ne $Player)
	{
	    &OpenMail(OPPONENT,$Users{$Wizard{$Name}{'User'}}{'Address'});
	    print OPPONENT &StartNotification($GameName);
	    print OPPONENT &GameStatus($Name);
	    close OPPONENT;
	}
    }

    print MAIL &ChallengeAcceptance(&Opponent($Player), $GameName);
}


sub GetChanges
{
    local ($NewGame) = @_;
    local (@Changes) = ();

    opendir (DIR,$SaveDir) || die $! ;
    foreach (readdir(DIR))
    {
	if (/^$NewGame-C-(.+)\.ngm$/)
	{
	    push (@Changes,$1);
	}
    }
    closedir DIR;

    @Changes = sort {&Num($a) <=> &Num($b)} @Changes;

    return @Changes;
}


sub Accept
{
    $NewGame = shift;
    $Player = &GetName(shift);

    local ($Change,$key);
    $key = shift;
    if ($key)
    {
        $key = "\L$key";
	$Change = shift;
    }

    # Read in the new game and save it's state
    local ($GameState) = &DisplayNewGameState($NewGame);

    if (!$key and $Accepted{$Player})
    {
	if ($Player eq $Challenger)
	{
	    print MAIL "$h You do not need to accept your own challenge.\n";
	    print MAIL $GameState;
	    return;
	}

	print MAIL "$h You have already accepted this challenge.\n";
	print MAIL $GameState;
	return;
    }

    if (!$Accepted{$Player})
    {
	if ($Open)
	{
	    if (grep (/^$Player$/,@Excluded))
	    {
		print MAIL "$h Sorry, but you are excluded from joining this battle.\n\n";
		print MAIL $GameState;
		return;
	    }

            if ($Open =~ m/^\d+$/)
            {
                my ($num,$wiz,$s,@Same) = (0,"","");

                foreach $wiz (keys %Accepted)
                {
                    if (&SamePlayer($Player,$wiz))
                    {
                        $num++;
			push (@Same,$wiz);
                    }
                }

                if ($num >= $Open)
                {
                    $s = 's' if $Open > 1;
                    print MAIL "$h Only $Open mage$s pr. player is allowed in this game.\n";
		    print MAIL " > You have already joined this game with the mage$s "
			. &JoinList(@Same) . ".\n\n";
                    print MAIL $GameState;
                    return;
                }
            }

	    &DoAccept($Player);
	}
	else
	{
	    my($n);
	    for $n (0..$#Challenged)
	    {
		if ($Player eq $Challenged[$n])
		{
		    splice (@Challenged,$n,1);
		    &DoAccept($Player);
		    last;
		}
	    }

	    if (!$Accepted{$Player})
	    {
		print MAIL "$h Sorry, but you are not challenged to join this game.\n\n";
		print MAIL $GameState;
		return;
	    }
	}

	$numAccepted = keys %Accepted;

	if ( (!$Open and !@Challenged) or ($numAccepted == $Limit) )
	{
	    &StartGame;
	    return;
	}

	local ($AccNote);
	$AccNote = &AcceptNotification($Player, $Wizard{$Player}{'User'}, $NewGame);
	$GameState = &DisplayNewGameState($NewGame);
	foreach $Name (keys %Accepted, @Challenged)
	{
	    next if $Name eq $Player;
	    &OpenMail(OPPONENT,$Users{$Wizard{$Name}{'User'}}{'Address'});
	    print OPPONENT $AccNote;
	    print OPPONENT $GameState;
	    close OPPONENT;
	}

	print MAIL "You arrive at the Graven Circle on Firetop Mountain.\n\n";
	print MAIL "Since the participants have not all arrived, you sit down to wait.\n\n";
    }

    if (!$key)
    {
	print MAIL $GameState;
	return;
    }

    $ChangeDone = 0;

    if ($key eq "everything")
    {
	print MAIL "You tell the referee that you accept any changes anyone may propose.\n\n";
	$Accepted{$Player}->[0] = 'all';
	local (@Changes) = &GetChanges($NewGame);
	foreach $Change (@Changes)
	{
	    &CheckChange($Change);
	    return if $GameStarted;
	}
    }
    else
    {
        print MAIL "You tell the referee that you accept the proposed change no $Change.\n\n";
        $Accepted{$Player}->[$Change] = 'yes';
        &CheckChange($Change);
    }

    return if $ChangeDone;

    &WriteNewGame($NewGame);
    print MAIL &DisplayNewGameState($NewGame);
}


sub DoAccept
{
# Accept a player into a new game, and remove him/her from all
# @Challenged lists the player might have been in.
# This routine supposes that a new game is already loaded.

    local ($Player) =@_;
    local ($MaxChange,$n);

    open (CHANGENO,"ChangeNumber.$NewGame") || die $!;
    $MaxChange = <CHANGENO>;
    close CHANGENO;
    chomp $MaxChange;

    $Accepted{$Player} = ["OK"];
    for ($n=1;$n<=$MaxChange;$n++)
    {
	$Accepted{$Player}->[$n] = 0;
    }
    $Wizard{$Player}{'Busy'} = "N$NewGame";
    &WriteNewGame($NewGame);

    &DeclineAll($Player,$NewGame);

    &ReadNewGame($NewGame); # Restore the current new game before exit.
}


sub DeclineAll
{
    local ($Player,$ThisGame) = @_;
    #Decline all challenges for $Player, except $ThisGame

    opendir (DIR,$SaveDir) || die $! ;
    local ($NG,$n,$found,$GameState);
    foreach (readdir(DIR))
    {
	if (/^(\d+)\.ngm$/)
	{
	    $NG = $1;
	    next if $NG eq $ThisGame;
	    &ReadNewGame($NG);
	    next if $Open;
	    $found = 0;
	    foreach $n (0 .. $#Challenged)
	    {
		if ($Player eq $Challenged[$n])
		{
		    splice (@Challenged,$n,1);
		    $found = 1;
		    last;
		}
	    }
	    next if !$found;

	    &WriteNewGame($NG);

	    $GameState = &DisplayNewGameState($NG);

	    if (@Challenged || $Open)
            {
                foreach $Name (keys %Accepted, @Challenged)
                {
                    &OpenMail(OPPONENT,$Users{$Wizard{$Name}{'User'}}{'Address'});
                    print OPPONENT &DeclineNotification($Player,$Name,$NG);
                    print OPPONENT $GameState;
                    close OPPONENT;
                }
            }
            else
            {
                foreach $Name (keys %Accepted)
                {
                    &OpenMail(OPPONENT, $Users{$Wizard{$Name}{'User'}}{'Address'});
                    print OPPONENT &LastOpponentDeclined($Player, $NG);
                    print OPPONENT $GameState;
                    close OPPONENT;
                }
            }
        }
    }
    closedir DIR;
}


sub CheckChange
{
# Assumes a NewGame is loaded
    local ($Change) = @_;
    local ($For,$Against, $wight, @Answers) = (0,0);
    foreach $Mage (keys %Accepted)
    {
	@Answers = @{$Accepted{$Mage}};
	if ($Mage eq $Challenger)
	{
	    $wight = 3;
	}
	else
	{
	    $wight = 2;
	}

	if ($Answers[0] eq 'all' or $Answers[$Change] eq 'yes')
	{
	    $For += $wight;
	}
	elsif ($Answers[$Change] eq 'no')
	{
	    $Against += $wight;
	}
    }

    $numAccepted = keys %Accepted;
    if ($For > $numAccepted)
    {
	return if ReadChange($NewGame,$Change)<0;
	unlink ("$NewGame-C-$Change.ngm");
#	&popTask("$NewGame-C-$Change");
	&DoChange;
	$ChangeDone=1;
    }
    elsif ($Against > $numAccepted)
    {
	return if ReadChange($NewGame,$Change)<0;
	unlink ("$NewGame-C-$Change.ngm");
#	&popTask("$NewGame-C-$Change");
	$GameState = &DisplayNewGameState($NewGame);
	foreach $Name (keys %Accepted)
	{
	    next if $Name eq $Player;
	    &OpenMail(OPPONENT,$Users{$Wizard{$Name}{'User'}}{'Address'});
	    print OPPONENT &NoChangeNotification($Proposer,$Name,$NewGame,$Change);
	    print OPPONENT $GameState;
	    close OPPONENT;
	}
	print MAIL "The majority of the wizards that have agreed to join the new game $NewGame,
do not want change no $Change proposed by $Proposer to take effect.
The $gmName drops the proposal into his magic paper basket.\n\n";
    }
}


sub Oppose
{
    $NewGame = shift;
    $Player = &GetName(shift);
    shift; #change
    local ($Change) = shift;

    &ReadNewGame($NewGame) || die "OPPOSE could not read new game $NewGame\n$!";
    if (!$Accepted{$Player})
    {
	print MAIL "$h You have no part in new game $NewGame.\n";
	print MAIL " (At least not yet.)\n\n";
	print MAIL &DisplayNewGameState($NewGame);
	return;
    }

    print MAIL "You tell the referee that you oppose the proposed change no $Change.\n\n";
    $Accepted{$Player}->[$Change] = 'no';
    $Accepted{$Player}->[0] = 'OK';
    &CheckChange($Change);
    &WriteNewGame($NewGame);
    print MAIL &DisplayNewGameState($NewGame);
}


sub Decline
{
    $NewGame = shift;
    $Player = &GetName(shift);

    # Read in the new game and save it's state
    local ($GameState) = &DisplayNewGameState($NewGame);

    if ($Accepted{$Player})
    {
	if ($Player eq $Challenger)
	{
	    print MAIL "$h You cannot decline your own challenge!\n\n";
	    print MAIL "   Perhaps you want to WITHDRAW the challenge?\n";
	    print MAIL $GameState;
		 return;
	}

	delete $Accepted{$Player};
	$Wizard{$Player}{'Busy'} = 0;
    }
    else
    {
	if ($Open)
	{
	    print MAIL "$h New game $NewGame is an open challenge.\n";
	    print MAIL "   There is no need to decline it.\n\n";
	    print MAIL $GameState;
	    return;
	}

	my ($found)=0;
	my ($n);
	foreach $n (0 .. $#Challenged)
	{
	    if ($Challenged[$n] eq $Player)
	    {
		$found=1;
		splice(@Challenged,$n,1);
		last;
	    }
	}
	if (!$found)
	{
	    print MAIL "$h It doesn't seem like you are challenged to join this new game\n";
            print MAIL "   So luckily no-one knows you would have wimped out!\n\n";
	    print MAIL $GameState;
	    return;
	}
    }

    &WriteNewGame($NewGame);
    $GameState = &DisplayNewGameState($NewGame);

    if (@Challenged || $Open)
    {
        foreach $Name (keys %Accepted, @Challenged)
        {
            &OpenMail(OPPONENT,$Users{$Wizard{$Name}{'User'}}{'Address'});
            print OPPONENT &DeclineNotification($Player,$Name,$NewGame);
            print OPPONENT $GameState;
            close OPPONENT;
        }
    }
    else
    {
        foreach $Name (keys %Accepted, @Challenged)
        {
            &OpenMail(OPPONENT, $Users{$Wizard{$Name}{'User'}}{'Address'});
            print OPPONENT &LastOpponentDeclined($Player, $NewGame);
            print OPPONENT $GameState;
            close OPPONENT;
        }
    }

    print MAIL &DeclineAcknowledge($Player);
    print MAIL $GameState;
}


sub Withdraw
{
    $NewGame = shift;
    $Player = &GetName(shift);

    # Read in the new game and save it's state
    local ($GameState) = &DisplayNewGameState($NewGame);

    if ($Player ne $Challenger)
    {
	print MAIL "$h You have not intiated this challenge!\n";
	print MAIL "   Perhaps you want to DECLINE the challenge?\n\n";
	print MAIL $GameState;
	return;
    }

    foreach $Name (keys %Accepted, @Challenged)
    {
	$Wizard{$Name}{'Busy'} = 0;
	next if $Name eq $Player;
	&OpenMail(OPPONENT,$Users{$Wizard{$Name}{'User'}}{'Address'});
	print OPPONENT &WithdrawalNotification($Name, $Player, $NewGame);
	close OPPONENT;
	print MAIL " $Name has been notified of your decision not to proceed with new game $NewGame.\n\n";
    }

    &PurgeNewGame($NewGame);
    print MAIL "Challenge $NewGame is deleted.\n\n";
}

sub PurgeNewGame
{
    local ($NewGame) = @_;
    local ($Change, @Changes);
    @Changes = &GetChanges($NewGame);
    foreach $Change (@Changes)
    {
	unlink ("$NewGame-C-$Change.ngm");
    }
    unlink ("$NewGame.ngm");
    unlink ("ChangeNumber.$NewGame")
}


sub NewGameList
{
    my($NewGame,$Line,$List,$NumAcc,$NumChl,@OpenChallenges,@ClosedCallenges);

    opendir (SAVEDIR,$SaveDir) || die $! ;

    foreach (readdir(SAVEDIR))
    {
	if (/^([^-]+)\.ngm$/)
	{
	    $NewGame=$1;
	    &ReadNewGame($NewGame) || die "NewGameList could not open game $NewGame\n$!\n";
	    if ($Open)
	    {
		$NumAcc = (keys %Accepted)-1;

		$Line = sprintf("   %4d   %-15s %-14s %5d     %5s  %s",
				$NewGame,$Challenger,
				"($Wizard{$Challenger}{'User'})",
				$NumAcc,
				($Limit?$Limit:'none'),
				"\u$SpellBook");
		$Line .= "    Comment: $Comment" if $Comment;

		# Also list any spells being removed/added
		my $maxlength = 0;
		foreach my $g (keys %RemoveSpells)
		{
		    $maxlength = length $g if (length $g > $maxlength);
		}

		foreach my $g (keys %RemoveSpells)
		{
			$Line .= sprintf("\n   %-4s   %-15s %s",
			   "", "", "-$g");
			$Line .= " " x ($maxlength + 2 - length($g)) . join(", ", @{$RemoveSpells{$g}});
		}

		$maxlength = 0;
		foreach my $g (keys %AddSpells)
		{
		    $maxlength = length $g if (length $g > $maxlength);
		}

		foreach my $g (keys %AddSpells)
		{
			$Line .= sprintf("\n   %-4s   %-15s %s",
			   "", "", "+$g");
			$Line .= " " x ($maxlength + 2 - length($g)) . join (", ", @{$AddSpells{$g}});
		}

		$Line .= "\n";

		push (@OpenChallenges,$Line);
	    }
	    else
	    {
		$NumAcc = (keys %Accepted)-1;
		$NumChl = @Challenged;
		$Line = sprintf("   %4d   %-15s %-14s %5d     %2d (%4s)",
				$NewGame,$Challenger,
				"($Wizard{$Challenger}{'User'})",
				$NumAcc,$NumChl,
				($Limit?$Limit:'none'));
		$Line .= "    Comment: $Comment" if $Comment;
		$Line .= "\n";

		push (@ClosedChallenges,$Line);
	    }
	}
    }
    closedir SAVEDIR;

    $List = "Challenges to battle on Firetop Mountain\n"
	  . "----------------------------------------\n";

    if (@OpenChallenges)
    {
	$List .= "\n Challenges open for anyone to accept:\n";
	$List .= "   Game   Challenger                    No. acc.   Limit  Spell Book\n";
	$List .= "   ". '-'x64  ."\n";

	foreach $Line (sort {&Num($a) <=> &Num($b)} @OpenChallenges)
	{
	    $List .= $Line;
	}
    }

    if (@ClosedChallenges)
    {
	$List .= "\n Closed challenges:\n";
	$List .= "   Game   Challenger                    No. acc.   No. chl.\n";
	$List .= "                                                   (Limit)\n";
	$List .= "   ". '-'x64  ."\n";

	foreach $Line (sort {&Num($a) <=> &Num($b)} @ClosedChallenges)
	{
	    $List .= $Line;
	}
    }
    elsif (!@OpenChallenges)
    {
	$List .= "\n None\n";
    }

    $List .= "\n\n";
    return $List;
}

1;
