# state checking for Chandra Snapshot
########################################################################
sub check_state {
########################################################################
    #use lib '//Snap';
    use Chex;

    %hash = @_;
    # Create the Chandra Expected state object
    #$chex_file = "/proj/sot/ska/dev/starcheck/TEST//pred_state.rdb";
    $chex_file = "/home/mta/Chex/pred_state.rdb";
    $chex = Chex->new($chex_file);

    # Get OBT from snapshot
    $date = $hash{OBT}[1];
    #print "Checking for date: $date\n"; #debug

    # Set up tolerances for ra, dec, roll
    $d2r = 3.14159265/180.;
    $ra_tol = 50/3600.;
    $dec_tol = 50/3600.;
    $roll_tol = 500/3600.;

    # If there is a unique value of dec, then adjust $ra_tol
    %pred = $chex->get($date);
    @dec_vals = @{$pred{dec}};
    $ra_tol *= 1.0 / (cos($dec_vals[0] * $d2r) + 1e-5) if (@dec_vals == 1) ;

    $BLU = "#00EECC";
    $GRN = "#33CC00";
    $YLW = "#FFFF00";
    $RED = "#FF0000";
    $WHT = "#FFFFFF";
    $UNDEF = "undef";
    
    # Define variables to check
    my @checks;
    #open KEY, '$work_dir/snaps.par';
    $parfile = "/home/mta/Snap/snaps2.par";
    open KEY, $parfile;
    while (<KEY>) {
      if ($_ =~ /^#/) {}
      else { 
        chomp;
        push @checks, $_;
      }
    }
    close KEY;

    # Now do the checking, and adjust color of text accordingly
    foreach $check (@checks) {
      #print "State Checking: $check\n"; # debug
      @chk = split(/\t+/, $check);

      # don't check stale data, color already set by set_status
      my $status = ${$hash{"$chk[0]"}}[2];
      if ($status eq "S" || $status eq "I") {
        next;
      }

      $val = ${$hash{"$chk[0]"}}[1];

      # unchecked
      if ($chk[1] == 0) {
        $color = $BLU;
      }

      # use chex
      if ($chk[1] == 1) {
	$color = $BLU; # Default to blue (not checked or undef)
        if ($val) {
	  $match = $chex->match(var => $chk[2], # State variable name
			        val => $val, # Observed state value
			        tol => $chk[3]);

	  $color = $RED if ($match == 0); # Bad match => red
	  $color = $GRN if ($match == 1); # Good match => green
        }
      }

      # use static limits
      if ($chk[1] == 2) {
        $color = $GRN;
        if ($val <= $chk[2] && $chk[2] ne '-') {$color = $YLW;}
        if ($val >= $chk[3] && $chk[3] ne '-') {$color = $YLW;}
        if ($val <= $chk[4] && $chk[4] ne '-') {$color = $RED;}
        if ($val >= $chk[5] && $chk[5] ne '-') {$color = $RED;}
      }

      # use a constant
      if ($chk[1] == 3) {
        my $cmp = $chk[2];
        $cmp =~ s/^\s+//;
        $cmp =~ s/\s+$//;
        $color = $RED;
        if ($val eq $cmp) { $color = $GRN;}
      }

      # use a function
      if ($chk[1] == 4) {
        $funcall = $chk[2];
        $funcall =~ s/^\s+//;
        $funcall =~ s/\s+$//;
        #print "$funcall $val\n";  # DEBUG
        $color = &$funcall("$val");
      }

      if ($chk[1] == 5) {
        $funcall = $chk[2];
        $funcall =~ s/^\s+//;
        $funcall =~ s/\s+$//;
        #print "$funcall $val\n";  # DEBUG
        $stat=${$hash{"5EHSE106"}}[1];
        $prev=${$hash{"5HSE202a"}}[1];
        $pstat=${$hash{"5EHSE106a"}}[1];
        @args=($val,$stat,$prev,$pstat,$chk[3],$chk[4]);
        $color = &$funcall(@args);
      }

      $hash{$chk[0]}[3] = $color;
      if ($color eq $BLU) { $hash{$chk[0]}[2] = "B"; }
      if ($color eq $GRN) { $hash{$chk[0]}[2] = "G"; }
      if ($color eq $YLW) { $hash{$chk[0]}[2] = "Y"; }
      if ($color eq $RED) { $hash{$chk[0]}[2] = "R"; }
      if ($color eq $UNDEF) { $hash{$chk[0]}[2] = "U"; }
    }

    return %hash;
}

########################################################################
#   User defined functions for mode 4
########################################################################
sub radmon {
    # don't know alt in backup, so just use sim and obsid !
    # below $radalt km , radmon should be disabled for belt and perigee
    #   passage, above $radalt km radmon is always enabled, unless
    #   something is wrong (e.g. SCS 107 ran)
    my $radalt = 90000;
    my $alt = ${$hash{EPHEM_ALT}}[1];
    my $val = $_[0];
    my $sim = ${$hash{"3TSCPOS"}}[1];
    my $obs = ${$hash{COBSRQID}}[1];
    my $color = $BLU; # Default to blue (not checked or undef)
    if ($obs > 55000 && $sim < -99000 && $val eq "ENAB") {
      $color = $RED;
    }
    if ($obs > 55000 && $sim < -99000 && $val eq "DISA") {
      $color = $GRN;
    }
    if (($obs < 55000 || $sim > -99000) && $val eq "DISA") {
      $color = $RED;
    }
    if (($obs < 55000 || $sim > -99000) && $val eq "ENAB") {
      $color = $GRN;
    }
    if ($alt > $radalt && $val eq "ENAB") {
      $color = $GRN;
    }
    return $color;
}

sub pcadmode {
    # PCADMODE should be NPNT, unless slewing (then NMAN)
    #  if chex says ra dec or roll is undef, then assume slewing
    my $val = $_[0];
    my $date = $hash{OBT}[1];
    #print "pcadmode date: $date\n"; #debug
    #my %pred = $chex->get($hash{OBT}[1]);
    my @ra = @{$pred{ra}};
    my @dec = @{$pred{dec}};
    my @roll = @{$pred{roll}};
    my @grat = @{$pred{gratings}};
    #if ($#ra > 0)   {$ra[0] = $UNDEF;}
    #if ($#dec > 0)  {$dec[0] = $UNDEF;}
    #if ($#roll > 0) {$roll[0] = $UNDEF;}
    my $color = $BLU;
    #if ($ra[0] eq $UNDEF || $dec[0] eq $UNDEF || $roll[0] eq $UNDEF) {
    if ($ra[0] eq $UNDEF && $dec[0] eq $UNDEF && $roll[0] eq $UNDEF) {
      if ($val eq 'NPNT') {$color = $YLW;}
      if ($val eq 'NMAN') {$color = $GRN;}
    } else {
      if ($val eq 'NPNT') {$color = $GRN;}
      if ($val eq 'NMAN') {$color = $YLW;}
    }
    if ($grat[0] eq $UNDEF) {
      if ($val eq 'NMAN') {$color = $GRN;}
    }
    my $afile = "/home/mta/Snap/.nsunalert";
    my $tfile = "/home/mta/Snap/.nsunwait";
    if ($val eq 'NPNT' || $val eq 'NMAN') {
      if (-s $afile) {
        my $tnum = 3;  # but, wait a little while before deleting lock
        if (-s $tfile) {
          open (TF, "<$tfile");
          $tnum = <TF>;
          close TF;
        }
        $tnum--;
        if ($tnum == 0) {
          unlink $afile;
        }
        if ($tnum > 0) {
          open (TF, ">$tfile");
          print TF $tnum;
          close TF;
        }
      } # if (-s $afile) {
    } # if ($val eq 'NPNT' || $val eq 'NMAN') {
    if ($val eq 'NSUN') {
      $color = $RED;
      my $tnum = 0;  # but, wait a little while before waking people up
      if (-s $tfile) {
        open (TF, "<$tfile");
        $tnum = <TF>;
        close TF;
      }
      $tnum++;
      if ($tnum == 2) {
        send_nsun_alert($val);
      }
      if ($tnum <= 1) {
        open (TF, ">$tfile");
        print TF $tnum;
        close TF;
      }
    } # if ($val eq 'NSUN') {
  return $color;
} #pcadmode

sub hetg {
    my $val = $_[0];
    my %pred = $chex->get(${$hash{OBT}}[1]);
    my @grat = @{$pred{gratings}};
    $color = $RED;
    if ($val < 15 && $grat[0] eq 'HETG') {$color = $GRN;}
    if ($val > 70 && $grat[0] ne 'HETG') {$color = $GRN;}
    if ($grat[0] eq $UNDEF) {$color = $BLU;}
    return $color;
}

sub letg {
    my $val = $_[0];
    my %pred = $chex->get(${$hash{OBT}}[1]);
    my @grat = @{$pred{gratings}};
    $color = $RED;
    if ($val < 15 && $grat[0] eq 'LETG') {$color = $GRN;}
    if ($val > 70 && $grat[0] ne 'LETG') {$color = $GRN;}
    if ($grat[0] eq $UNDEF) {$color = $BLU;}
    return $color;
}

sub e1300 {
    my $val = $_[0];
    my $radmon = ${$hash{CORADMEN}}[1];
    if ($radmon eq 'ENAB') {
      if ($val < 3.3) {$color = $GRN;}
      if ($val >= 3.3) {$color = $YLW;}
      if ($val >= 10.0) {$color = $RED;}
    } else {$color = $BLU;}
    return $color;
}

sub p4gm {
    my $val = $_[0];
    my $radmon = ${$hash{CORADMEN}}[1];
    if ($radmon eq 'ENAB') {
      if ($val < 100) {$color = $GRN;}
      if ($val >= 100) {$color = $YLW;}
      if ($val >= 300) {$color = $RED;}
    } else {$color = $BLU;}
    return $color;
}

sub p41gm {
    my $val = $_[0];
    my $radmon = ${$hash{CORADMEN}}[1];
    if ($radmon eq 'ENAB') {
      if ($val < 2.82) {$color = $GRN;}
      if ($val >= 2.82) {$color = $YLW;}
      if ($val >= 8.47) {$color = $RED;}
    } else {$color = $BLU;}
    return $color;
}

sub imfunc {
    my $val = $_[0];
    $color = $BLU;
    if (${$hash{AOPCADMD}}[1] eq 'NPNT') {
      $color = $GRN;
      if ($val =~ 'N') {
        my $obs = ${$hash{COBSRQID}}[1];
        if ($obs lt 55000) { $color = $RED; }
        if ($obs ge 55000) { $color = $YLW; }
      }
    }
    return $color;
}

sub scs128 {
    my $val = $_[0];
    my $color = $BLU;
    if (${$hash{COTLRDSF}}[1] eq 'EPS') {
      if ($val ne 'ACT') {
        $color = $YLW;
        my $scs129 = ${$hash{COSCS129S}}[1];
        my $scs130 = ${$hash{COSCS130S}}[1];
        if ($scs129 ne 'ACT' && $scs130 ne 'ACT') {
          $color = $RED;
        }
      } else {
        $color = $GRN;
      }
    }
    return $color;
}
      
sub scs129 {
    my $val = $_[0];
    my $color = $BLU;
    if (${$hash{COTLRDSF}}[1] eq 'EPS') {
      if ($val ne 'ACT') {
        $color = $YLW;
        my $scs128 = ${$hash{COSCS128S}}[1];
        my $scs130 = ${$hash{COSCS130S}}[1];
        if ($scs128 ne 'ACT' && $scs130 ne 'ACT') {
          $color = $RED;
        }
      } else {
        $color = $GRN;
      }
    }
    return $color;
}
      
sub scs130 {
    my $val = $_[0];
    my $color = $BLU;
    if (${$hash{COTLRDSF}}[1] eq 'EPS') {
      if ($val ne 'ACT') {
        $color = $YLW;
        my $scs128 = ${$hash{COSCS128S}}[1];
        my $scs129 = ${$hash{COSCS129S}}[1];
        if ($scs128 ne 'ACT' && $scs129 ne 'ACT') {
          $color = $RED;
        }
      } else {
        $color = $GRN;
      }
    }
    return $color;
}

sub scs107 {
    my $val = $_[0];
    my $afile = "/home/mta/Snap/.scs107alert";
    my $tfile = "/home/mta/Snap/.scs107wait";
    $color = $BLU;
    #if (${$hash{COTLRDSF}}[1] eq 'EPS') {
      $color = $YLW;
      if ($val eq 'INAC') {
        $color = $GRN;
        if (-s $afile) {
          my $tnum = 3;  # but, wait a little while before deleting lock
          if (-s $tfile) {
            open (TF, "<$tfile");
            $tnum = <TF>;
            close TF;
          }
          $tnum--;
          if ($tnum == 0) {
            unlink $afile;
          }
          if ($tnum > 0) {
            open (TF, ">$tfile");
            print TF $tnum;
            close TF;
          }
        }
      }
      if ($val eq 'DISA' && ${$hash{COSCS128S}}[1] eq 'INAC' && ${$hash{COSCS129S}}[1] eq 'INAC' && ${$hash{COSCS130S}}[1] eq 'INAC') {
      # add extra checks, rhodes is being shifty 08/12/03 bds
      #if ($val eq 'DISA') {
        $color = $RED;
        my $tnum = 0;  # but, wait a little while before waking people up
        if (-s $tfile) {
          open (TF, "<$tfile");
          $tnum = <TF>;
          close TF;
        }
        $tnum++;
        if ($tnum == 2) {
          send_107_alert($val);
          if (${$hash{"3TSCPOS"}}[1] > -99000) {
            send_sim_unsafe_alert(${$hash{"3TSCPOS"}}[1]);
          } # if (${$hash{"3TSCPOS"}}[1] > -99000) {
        }
        if ($tnum <= 1) {
          open (TF, ">$tfile");
          print TF $tnum;
          close TF;
        }
      }
    #} #if (${$hash{COTLRDSF}}[1] eq 'EPS') {
    return $color;
}

sub aofstar {
  my $val = $_[0];
  my $afile = "/home/mta/Snap/.britalert";
  my $tfile = "/home/mta/Snap/.britwait";
  $color = $YLW;
  if ($val eq 'GUID') {
    $color = $GRN;
    if (-s $afile) {
      my $tnum = 3;  # but, wait a little while before deleting lock
      if (-s $tfile) {
        open (TF, "<$tfile");
        $tnum = <TF>;
        close TF;
      }
      $tnum--;
      if ($tnum == 0) {
        unlink $afile;
      }
      if ($tnum > 0) {
        open (TF, ">$tfile");
        print TF $tnum;
        close TF;
      }
    }
  }
  if ($val eq 'BRIT') {
    $color = $RED;
    my $tnum = 0;  # but, wait a little while before waking people up
    if (-s $tfile) {
      open (TF, "<$tfile");
      $tnum = <TF>;
      close TF;
    }
    $tnum++;
    if ($tnum == 3) {
      send_brit_alert($val);
    }
    if ($tnum <= 3) {
      open (TF, ">$tfile");
      print TF $tnum;
      close TF;
    }
  }
  return $color;
}
      
sub fmt {
    my $val = $_[0];
    my $test = chop($_[0]);
    $color = $RED;
    #print "$val $test[0]\n"; # DEBUG
    if ($test == 1 || $test == 2) {$color = $GRN;}
    if ($test == 3 || $test == 4 || $test == 6) {$color = $YLW;}
    if ($test == 5) {
      $color = $RED;
      send_fmt_alert(split("_", $val));
    }
    return $color;
}

sub airu1g1i {
    my $val = $_[0];
    my $tfile = "/home/mta/Snap/.gyrowait";
    $color = $BLU;
    if ($val < 150) { $color =$GRN;}
    if ($val >= 150 && $val < 200) { $color =$YLW;}
    if ($val >= 200) {
      $color = $RED;
      my $tnum = 0;  # but, wait a little while before waking people up
      if (-s $tfile) {
        open (TF, "<$tfile");
        $tnum = <TF>;
        close TF;
      }
      $tnum++;
      # reset tfile only each pass
      #  gyro current gets noisy, so count total violations
      #  instead of total in a row like the others
      if ($tnum == 5) {
        send_gyro_alert($val);
      }
      if ($tnum <= 5) {
        open (TF, ">$tfile");
        print TF $tnum;
        close TF;
      }
    }
    return $color;
}

sub ctxapwr {
  my $val = $_[0];
  my $afile = "/home/mta/Snap/.ctxpwralert";
  my $tfile = "/home/mta/Snap/.ctxpwrwait";
  my $dfile = "/home/mta/Snap/.ctxpwrdel";
  my $ctxa_pwr_lim=36.75;
  # pwr is noisy, so we need two lock files send alert after
  #  10 violations rearm after 50 non-violations.
  # ctx pwr has high sample rate, so may want higher count thresholds
  $color = $GRN;
  if ($val < $ctxa_pwr_lim) {
    $color = $GRN;
    my $tnum = 50;  # but, wait a little while before deleting lock
    if (-s $dfile) {
      open (TF, "<$dfile");
      $dnum = <TF>;
      close TF;
    }
    $dnum--;
    if ($dnum == 0) {
      if (-s $afile) {
        unlink $afile;
      }
      unlink $tfile;
    }
    if ($dnum > 0) {
      open (TF, ">$dfile");
      print TF $dnum;
      close TF;
    }
  }
  if ($val >= $ctxa_pwr_lim) {
    $color = $YLW;
    my $tnum = 0;  # but, wait a little while before waking people up
    if (-s $tfile) {
      open (TF, "<$tfile");
      $tnum = <TF>;
      close TF;
    }
    $tnum++;
    if ($tnum == 10) {
      unlink $dfile;
      send_ctxpwr_alert($val,'A');
    }
    if ($tnum <= 10) {
      open (TF, ">$tfile");
      print TF $tnum;
      close TF;
    }
  }
  if ($val >= 37.00) { $color=$RED; }
  return $color;
}

sub ctxbpwr {
  my $val = $_[0];
  my $afile = "/home/mta/Snap/.ctxpwralert";
  my $tfile = "/home/mta/Snap/.ctxpwrwait";
  my $dfile = "/home/mta/Snap/.ctxpwrdel";
  my $ctxb_pwr_lim=36.75;
  # pwr is noisy, so we need two lock files send alert after
  #  10 violations rearm after 50 non-violations.
  # ctx pwr has high sample rate, so may want higher count thresholds
  $color = $GRN;
  if ($val < $ctxb_pwr_lim) {
    $color = $GRN;
    my $dnum = 50;  # but, wait a little while before deleting lock
    if (-s $dfile) {
      open (TF, "<$dfile");
      $dnum = <TF>;
      close TF;
    }
    $dnum--;
    if ($dnum == 0) {
      if (-s $afile) {
        unlink $afile;
      }
      unlink $tfile;
    }
    if ($dnum > 0) {
      open (TF, ">$dfile");
      print TF $dnum;
      close TF;
    }
  }
  if ($val >= $ctxb_pwr_lim) {
    $color = $YLW;
    my $tnum = 0;  # but, wait a little while before waking people up
    if (-s $tfile) {
      open (TF, "<$tfile");
      $tnum = <TF>;
      close TF;
    }
    $tnum++;
    if ($tnum == 10) {
      unlink $dfile;
      send_ctxpwr_alert($val,'B');
    }
    if ($tnum <= 10) {
      open (TF, ">$tfile");
      print TF $tnum;
      close TF;
    }
  }
  if ($val >= 37.00) { $color=$RED; }
  return $color;
}

sub ctxav {
  my $val = $_[0];
  my $afile = "/home/mta/Snap/.ctxvalert";
  my $tfile = "/home/mta/Snap/.ctxvwait";
  $color = $GRN;
  if ($val < 3.60) {
    $color = $GRN;
    my $tnum = 3;  # but, wait a little while before deleting lock
    if (-s $tfile) {
      open (TF, "<$tfile");
      $tnum = <TF>;
      close TF;
    }
    $tnum--;
    if ($tnum == 0) {
      if (-s $afile) {
      unlink $afile;
      }
    }
    if ($tnum > 0) {
      open (TF, ">$tfile");
      print TF $tnum;
      close TF;
    }
  }
  if ($val >= 3.60) {
    $color = $YLW;
    my $tnum = 0;  # but, wait a little while before waking people up
    if (-s $tfile) {
      open (TF, "<$tfile");
      $tnum = <TF>;
      close TF;
    }
    $tnum++;
    if ($tnum == 3) {
      send_ctxv_alert($val,'A');
    }
    if ($tnum <= 3) {
      open (TF, ">$tfile");
      print TF $tnum;
      close TF;
    }
  }
  if ($val >= 3.70) { $color=$RED; }
  return $color;
}

sub ctxbv {
  my $val = $_[0];
  my $afile = "/home/mta/Snap/.ctxvalert";
  my $tfile = "/home/mta/Snap/.ctxvwait";
  $color = $GRN;
  if ($val < 3.60) {
    $color = $GRN;
    my $tnum = 3;  # but, wait a little while before deleting lock
    if (-s $tfile) {
      open (TF, "<$tfile");
      $tnum = <TF>;
      close TF;
    }
    $tnum--;
    if ($tnum == 0) {
      if (-s $afile) {
      unlink $afile;
      }
    }
    if ($tnum > 0) {
      open (TF, ">$tfile");
      print TF $tnum;
      close TF;
    }
  }
  if ($val >= 3.60) {
    $color = $YLW;
    my $tnum = 0;  # but, wait a little while before waking people up
    if (-s $tfile) {
      open (TF, "<$tfile");
      $tnum = <TF>;
      close TF;
    }
    $tnum++;
    if ($tnum == 3) {
      send_ctxv_alert($val,'B');
    }
    if ($tnum <= 3) {
      open (TF, ">$tfile");
      print TF $tnum;
      close TF;
    }
  }
  if ($val >= 3.70) { $color=$RED; }
  return $color;
}

sub hkp27v {
  my ($val,$stat,$prev,$pstat,$lim,$abs_diff)=@_;
  my $afile = "/home/mta/Snap/.hkp27valert";
  my $tfile = "/home/mta/Snap/.hkp27vwait";
  #print "HKP27V  $val $stat $lim\n";
  $color = $WHT;
  if ($stat % 2 == 1) {
    if ($val >= $lim) {
      $color = $GRN;
      my $tnum = 3;  # but, wait a little while before deleting lock
      if (-s $tfile) {
        open (TF, "<$tfile");
        $tnum = <TF>;
        close TF;
      }
      $tnum--;
      if ($tnum == 0) {
        if (-s $afile) {
          unlink $afile;
        }
      }
      if ($tnum > 0) {
        open (TF, ">$tfile");
        print TF $tnum;
        close TF;
      }
    }
    if ($val < $lim && abs($val-$prev) lt $abs_diff && abs($val-$prev) gt 1) {
      $color = $YLW;
      my $tnum = 0;  # but, wait a little while before waking people up
      if (-s $tfile) {
        open (TF, "<$tfile");
        $tnum = <TF>;
        close TF;
      }
      $tnum++;
      if ($tnum == 5) {
        send_hkp27v_alert($val);
      }
      if ($tnum <= 5) {
        open (TF, ">$tfile");
        print TF $tnum;
        close TF;
      }
    }
  } # if ((${$h{"5EHSE106"}}[1]+1) % 2 == 0) {
  return $color;
}

sub shldart {
  my $val = $_[0];
  my $afile = "/home/mta/Snap/.hrc_shld_alert";
  my $tfile = "/home/mta/Snap/.hrcshldwait";
  $color = $YLW;
  if ($val > 255) {
    $color = $BLU;
  }
  if ($val < 245) {
    $color = $GRN;
    if (-s $afile) {
      my $tnum = 3;  # but, wait a little while before deleting lock
      if (-s $tfile) {
        open (TF, "<$tfile");
        $tnum = <TF>;
        close TF;
      }
      $tnum--;
      if ($tnum == 0) {
        unlink $afile;
      }
      if ($tnum > 0) {
        open (TF, ">$tfile");
        print TF $tnum;
        close TF;
      }
    }
  }
  if ($val > 245 && ${$hash{CORADMEN}}[1] eq 'ENAB') {
    $color = $YLW;
    my $tnum = 0;  # but, wait a little while before waking people up
    if (-s $tfile) {
      open (TF, "<$tfile");
      $tnum = <TF>;
      close TF;
    }
    $tnum++;
    if ($tnum == 3) {
      send_hrc_shld_alert($val);
    }
    if ($tnum <= 3) {
      open (TF, ">$tfile");
      print TF $tnum;
      close TF;
    }
  }
  return $color;
}

sub pline03t {
  my $val = $_[0];
  my $afile = "/home/mta/Snap/.pline03talert";
  my $tfile = "/home/mta/Snap/.pline03twait";
  $color = $BLU;
  if ($val > 42.5) {
    $color = $GRN;
    if (-s $afile) {
      my $tnum = 3;  # but, wait a little while before deleting lock
      if (-s $tfile) {
        open (TF, "<$tfile");
        $tnum = <TF>;
        close TF;
      }
      $tnum--;
      if ($tnum == 0) {
        unlink $afile;
      }
      if ($tnum > 0) {
        open (TF, ">$tfile");
        print TF $tnum;
        close TF;
      }
    }
  } # if ($val > 42.5) {
  if ($val < 42.5) {
    $color = $YLW;
    my $tnum = 0;  # but, wait a little while before waking people up
    if (-s $tfile) {
      open (TF, "<$tfile");
      $tnum = <TF>;
      close TF;
    }
    $tnum++;
    if ($tnum == 3) {
      send_pline03t_alert($val);
    }
    if ($tnum <= 1) {
      open (TF, ">$tfile");
      print TF $tnum;
      close TF;
    }
    if ($val < 40.0) {$color=$RED;}
  } #if ($val < 42.5) {
  return $color;
}

sub pline04t {
  my $val = $_[0];
  my $afile = "/home/mta/Snap/.pline04talert";
  my $tfile = "/home/mta/Snap/.pline04twait";
  $color = $BLU;
  if ($val > 42.5) {
    $color = $GRN;
    if (-s $afile) {
      my $tnum = 3;  # but, wait a little while before deleting lock
      if (-s $tfile) {
        open (TF, "<$tfile");
        $tnum = <TF>;
        close TF;
      }
      $tnum--;
      if ($tnum == 0) {
        unlink $afile;
      }
      if ($tnum > 0) {
        open (TF, ">$tfile");
        print TF $tnum;
        close TF;
      }
    }
  } # if ($val > 42.5) {
  if ($val < 42.5) {
    $color = $YLW;
    my $tnum = 0;  # but, wait a little while before waking people up
    if (-s $tfile) {
      open (TF, "<$tfile");
      $tnum = <TF>;
      close TF;
    }
    $tnum++;
    if ($tnum == 3) {
      send_pline04t_alert($val);
    }
    if ($tnum <= 1) {
      open (TF, ">$tfile");
      print TF $tnum;
      close TF;
    }
    if ($val < 40.0) {$color=$RED;}
  } #if ($val < 42.5) {
  return $color;
}

sub send_107_alert {
  # send e-mail alert if SCS107 DISA
  my $obstime = ${$hash{COSCS107S}}[0];
  if (! time_curr($obstime)) {
    return;
  }
  #my $afile = "$work_dir/.scs107alert";
  my $afile = "/home/mta/Snap/.scs107alert";
  my $comfile = "/pool14/chandra/DSN.schedule";
  if (-s $afile) {
  } else {
    open FILE, ">$afile";
    #print FILE "  THIS IS ONLY A TEST !!!! \n\n"; #debug
    #print FILE "(Testing ... I wasn't working before, but now I am)\n"; #debug
    print FILE "Chandra realtime telemetry shows SCS107 $_[0] at $obt UT\n\n";
    # try to figure out next comm passes
    open COMS, $comfile;
    my @time = split(":", $obt);
    # use decimal day to allow comms spanning two days
    my $day = $time[1] + ($time[2]/24) + ($time[3]/1440);
    while (<COMS>) {
      my @line = split(" ", $_);
      #print FILE "$time[0] $time[1] $time[2] $time[3]\n"; # debug
      #print FILE "$line[0] $line[4] $line[6] $line[7]\n"; # debug
      if ($line[0] < $time[0]) {next;}
      if ($line[4] < $time[1]) {next;}
      #if ($line[7] < ("$time[2]"."$time[3]")) {next;}
      if ($line[3] < $day) {next;}
      my @next = split(/\./, $line[1]);
      print FILE "Current pass:  $line[0]:$next[0]:$line[6] to $line[7]\n";
      print FILE "Next passes:   ";
      @line = split(" ", <COMS>);
      @next = split(/\./, $line[1]);
      print FILE "$line[0]:$next[0]:$line[6] to $line[7]\n";
      @line = split(" ", <COMS>);
      @next = split(/\./, $line[1]);
      print FILE "               $line[0]:$next[0]:$line[6] to $line[7]\n";
      @line = split(" ", <COMS>);
      @next = split(/\./, $line[1]);
      print FILE "               $line[0]:$next[0]:$line[6] to $line[7]\n";
      last;
    }
      
    print FILE "\nSnapshot:\n";
    print FILE "http://cxc.harvard.edu/cgi-gen/mta/Snap/snap.cgi\n"; #debug
    #print FILE "http://cxc.harvard.edu/mta_days/MIRROR/Snap/snap.cgi\n"; #debug
    #print FILE "This message sent to sot_yellow_alert\n"; #debug
    print FILE "This message sent to sot_red_alert\n"; #debug
    #print FILE "This message sent to brad rac swolk\n"; #debug
    #print FILE "This message sent to brad\n"; #debug
    #print FILE "\n TEST   TEST   TEST   TEST   TEST   TEST   TEST\n"; #debug
    close FILE;

    #open MAIL, "|mail brad\@head.cfa.harvard.edu swolk\@head.cfa.harvard.edu rac\@head.cfa.harvard.edu";
    #open MAIL, "|mail brad\@head.cfa.harvard.edu swolk\@head.cfa.harvard.edu";
    #open MAIL, "|mail sot_yellow_alert\@head.cfa.harvard.edu";
    #open MAIL, "|mailx -s SCS107 sot_red_alert\@head.cfa.harvard.edu";
    open MAIL, "|mailx -s SCS107 sot_red_alert\@head.cfa.harvard.edu operators";
    #open MAIL, "|mailx -s SCS107 brad\@head.cfa.harvard.edu";
    #open MAIL, "|more"; #debug
    open FILE, $afile;
    while (<FILE>) {
      print MAIL $_;
    }
    close FILE;
    close MAIL;
  }
}

sub send_nsun_alert {
  my $obstime = ${$hash{AOPCADMD}}[0];
  if (! time_curr($obstime)) {
    return;
  }
  my $afile = "/home/mta/Snap/.nsunalert";
  my $comfile = "/pool14/chandra/DSN.schedule";
  if (-s $afile) {
  } else {
    open FILE, ">$afile";
    print FILE "Chandra realtime telemetry shows PCADMODE $_[0] at $obt UT\n\n";
    # try to figure out next comm passes
    open COMS, $comfile;
    my @time = split(":", $obt);
    # use decimal day to allow comms spanning two days
    my $day = $time[1] + ($time[2]/24) + ($time[3]/1440);
    while (<COMS>) {
      my @line = split(" ", $_);
      #print FILE "$time[0] $time[1] $time[2] $time[3]\n"; # debug
      #print FILE "$line[0] $line[4] $line[6] $line[7]\n"; # debug
      if ($line[0] < $time[0]) {next;}
      if ($line[4] < $time[1]) {next;}
      #if ($line[7] < ("$time[2]"."$time[3]")) {next;}
      if ($line[3] < $day) {next;}
      my @next = split(/\./, $line[1]);
      print FILE "Current pass:  $line[0]:$next[0]:$line[6] to $line[7]\n";
      print FILE "Next passes:   ";
      @line = split(" ", <COMS>);
      @next = split(/\./, $line[1]);
      print FILE "$line[0]:$next[0]:$line[6] to $line[7]\n";
      @line = split(" ", <COMS>);
      @next = split(/\./, $line[1]);
      print FILE "               $line[0]:$next[0]:$line[6] to $line[7]\n";
      @line = split(" ", <COMS>);
      @next = split(/\./, $line[1]);
      print FILE "               $line[0]:$next[0]:$line[6] to $line[7]\n";
      last;
    }
      
    print FILE "\nSnapshot:\n";
    print FILE "http://cxc.harvard.edu/cgi-gen/mta/Snap/snap.cgi\n"; #debug
    print FILE "This message sent to sot_yellow_alert\n"; #debug
    #print FILE "This message sent to sot_red_alert\n"; #debug
    #print FILE "This message sent to brad swolk\n"; #debug
    #print FILE "\n TEST   TEST   TEST   TEST   TEST   TEST   TEST\n"; #debug
    close FILE;

    #open MAIL, "|mailx -s NSUN brad\@head.cfa.harvard.edu swolk\@head.cfa.harvard.edu";
    open MAIL, "|mailx -s NSUN sot_yellow_alert\@head.cfa.harvard.edu";
    #open MAIL, "|mailx -s NSUN sot_red_alert\@head.cfa.harvard.edu";
    #open MAIL, "|mailx -s NSUN sot_red_alert\@head.cfa.harvard.edu operators";
    #open MAIL, "|more"; #debug
    open FILE, $afile;
    while (<FILE>) {
      print MAIL $_;
    }
    close FILE;
    close MAIL;
  }
} #send_nsun_alert

sub send_sim_unsafe_alert {
  # send e-mail alert if SCS107 DISA and sim position gt -99000
  my $obstime = ${$hash{COSCS107S}}[0];
  if (! time_curr($obstime)) {
    return;
  }
  my $afile = "/home/mta/Snap/.sim_unsafe_alert";
  if (-s $afile) {
  } else {
    open FILE, ">$afile";
    print FILE "Chandra realtime telemetry shows SCS107 DISABLED and SIM at $_[0] at $obt UT\n\n";
      
    print FILE "\nSnapshot:\n";
    print FILE "http://cxc.harvard.edu/cgi-gen/mta/Snap/snap.cgi\n"; #debug
    print FILE "This message sent to brad swolk\n"; #debug
    close FILE;

    open MAIL, "|mailx -s SIM_UNSAFE! brad\@head.cfa.harvard.edu swolk\@head.cfa.harvard.edu";
    #open MAIL, "|mailx -s SIM_UNSAFE! sot_red_alert\@head.cfa.harvard.edu operators";
    open FILE, $afile;
    while (<FILE>) {
      print MAIL $_;
    }
    close FILE;
    close MAIL;
  }
}

sub send_hrc_shld_alert {
  my $obstime = ${$hash{"2SHLDART"}}[0];
  if (! time_curr($obstime)) {
    return;
  }
  my $afile = "/home/mta/Snap/.hrc_shld_alert";
  if (-s $afile) {
  } else {
    open FILE, ">$afile";
    printf FILE "Chandra realtime telemetry shows HRC SHIELD RATE of %3d at $obt UT\n",$_[0];
      
    print FILE "\nSnapshot:\n";
    print FILE "http://cxc.harvard.edu/cgi-gen/mta/Snap/snap.cgi\n"; #debug
    print FILE "This message sent to brad swolk\n"; #debug
    close FILE;

    open MAIL, "|mailx -s 'HRC SHIELD' brad\@head.cfa.harvard.edu";
    #open MAIL, "|mailx -s 'HRC SHIELD' brad\@head.cfa.harvard.edu swolk\@head.cfa.harvard.edu";
    #open MAIL, "|mailx -s 'HRC SHIELD' sot_red_alert\@head.cfa.harvard.edu operators";
    open FILE, $afile;
    while (<FILE>) {
      print MAIL $_;
    }
    close FILE;
    close MAIL;
  }
}

sub send_brit_alert {
  # send e-mail alert if AOFSTAR BRIT
  my $obstime = ${$hash{AOFSTAR}}[0];
  print "$obstime\n"; #debugbrit
  if (! time_curr($obstime)) {
    return;
  }
  my $afile = "/home/mta/Snap/.britalert";
  my $comfile = "/pool14/chandra/DSN.schedule";
  if (-s $afile) {
  } else {
    open FILE, ">$afile";
    #print FILE "  THIS IS ONLY A TEST !!!! \n\n"; #debug
    #print FILE "(Testing ... I wasn't working before, but now I am)\n"; #debug
    print FILE "Chandra realtime telemetry shows AOFSTAR $_[0] at $obt UT\n\n";
    # try to figure out next comm passes
    open COMS, $comfile;
    my @time = split(":", $obt);
    # use decimal day to allow comms spanning two days
    my $day = $time[1] + ($time[2]/24) + ($time[3]/1440);
    while (<COMS>) {
      my @line = split(" ", $_);
      #print FILE "$time[0] $time[1] $time[2] $time[3]\n"; # debug
      #print FILE "$line[0] $line[4] $line[6] $line[7]\n"; # debug
      if ($line[0] < $time[0]) {next;}
      if ($line[4] < $time[1]) {next;}
      #if ($line[7] < ("$time[2]"."$time[3]")) {next;}
      if ($line[3] < $day) {next;}
      my @next = split(/\./, $line[1]);
      print FILE "Current pass:  $line[0]:$next[0]:$line[6] to $line[7]\n";
      print FILE "Next passes:   ";
      @line = split(" ", <COMS>);
      @next = split(/\./, $line[1]);
      print FILE "$line[0]:$next[0]:$line[6] to $line[7]\n";
      @line = split(" ", <COMS>);
      @next = split(/\./, $line[1]);
      print FILE "               $line[0]:$next[0]:$line[6] to $line[7]\n";
      @line = split(" ", <COMS>);
      @next = split(/\./, $line[1]);
      print FILE "               $line[0]:$next[0]:$line[6] to $line[7]\n";
      last;
    }
      
    print FILE "\nSnapshot:\n";
    print FILE "http://cxc.harvard.edu/cgi-gen/mta/Snap/snap.cgi\n"; #debug
    #print FILE "http://cxc.harvard.edu/mta_days/MIRROR/Snap/snap.cgi\n"; #debug
    print FILE "This message sent to sot_yellow_alert\n"; #debug
    #print FILE "This message sent to sot_red_alert\n"; #debug
    #print FILE "This message sent to brad rac swolk\n"; #debug
    #print FILE "This message sent to brad\n"; #debug
    #print FILE "\n TEST   TEST   TEST   TEST   TEST   TEST   TEST\n"; #debug
    close FILE;

    #open MAIL, "|mail brad\@head.cfa.harvard.edu swolk\@head.cfa.harvard.edu rac\@head.cfa.harvard.edu";
    #open MAIL, "|mail brad\@head.cfa.harvard.edu swolk\@head.cfa.harvard.edu";
    open MAIL, "|mailx -s BRIT sot_yellow_alert\@head.cfa.harvard.edu";
    #open MAIL, "|mailx -s BRIT sot_red_alert\@head.cfa.harvard.edu";
    #open MAIL, "|mailx -s BRIT brad\@head.cfa.harvard.edu";
    #open MAIL, "|mail brad\@head.cfa.harvard.edu";
    #open MAIL, "|more"; #debug
    open FILE, $afile;
    while (<FILE>) {
      print MAIL $_;
    }
    close FILE;
    close MAIL;
  }
}

sub send_fmt_alert {
  # send e-mail alert if FMT5
  my $obstime = ${$hash{CCSDSTMF}}[0];
  if (! time_curr($obstime)) {
    return;
  }
  my $afile = "$work_dir/.fmt5alert";
  my $comfile = "/pool14/chandra/DSN.schedule";
  if (-s $afile) {
  } else {
    open FILE, ">$afile";
    #print FILE "  THIS IS ONLY A TEST !!!! \n\n"; #debug
    print FILE "Chandra realtime telemetry shows FMT$_[0] at $obt UT\n\n";
    # try to figure out next comm passes
    open COMS, $comfile;
    my @time = split(":", $obt);
    # use decimal day to allow comms spanning two days
    my $day = $time[1] + ($time[2]/24) + ($time[3]/1440);
    while (<COMS>) {
      my @line = split(" ", $_);
      #print FILE "$time[0] $time[1] $time[2] $time[3]\n"; # debug
      #print FILE "$line[0] $line[4] $line[6] $line[7]\n"; # debug
      if ($line[0] < $time[0]) {next;}
      if ($line[4] < $time[1]) {next;}
      #if ($line[7] < ("$time[2]"."$time[3]")) {next;}
      if ($line[3] < $day) {next;}
      my @next = split(/\./, $line[1]);
      print FILE "Current pass:  $line[0]:$next[0]:$line[6] to $line[7]\n";
      print FILE "Next passes:   ";
      @line = split(" ", <COMS>);
      @next = split(/\./, $line[1]);
      print FILE "$line[0]:$next[0]:$line[6] to $line[7]\n";
      @line = split(" ", <COMS>);
      @next = split(/\./, $line[1]);
      print FILE "               $line[0]:$next[0]:$line[6] to $line[7]\n";
      @line = split(" ", <COMS>);
      @next = split(/\./, $line[1]);
      print FILE "               $line[0]:$next[0]:$line[6] to $line[7]\n";
      last;
    }
      
    print FILE "\nSnapshot:\n";
    print FILE "http://cxc.harvard.edu/cgi-gen/mta/Snap/snap.cgi\n"; #debug
    print FILE "This message sent to sot_red_alert\n"; #debug
    #print FILE "\n TEST   TEST   TEST   TEST   TEST   TEST   TEST\n"; #debug
    close FILE;

    #open MAIL, "|mail brad\@head.cfa.harvard.edu swolk\@head.cfa.harvard.edu rac\@head.cfa.harvard.edu";
    open MAIL, "|mailx -s FMT5 sot_red_alert\@head.cfa.harvard.edu";
    #open MAIL, "|mail brad\@head.cfa.harvard.edu";
    #open MAIL, "|more"; #debug
    open FILE, $afile;
    while (<FILE>) {
      print MAIL $_;
    }
    close FILE;
    close MAIL;
  }
}

sub send_gyro_alert {
  # send e-mail alert if AIRU1Q1I gt 200 mAmp
  my $obstime = ${$hash{CCSDSTMF}}[0];
  if (! time_curr($obstime)) {
    return;
  }
  my $afile = "$work_dir/.airuialert";
  my $comfile = "/pool14/chandra/DSN.schedule";
  if (-s $afile) {
  } else {
    open FILE, ">$afile";
    #print FILE "\n TEST   TEST   TEST   TEST   TEST   TEST   TEST\n"; #debug
    print FILE "Chandra realtime telemetry shows AIRU1G1I %f6.2 mAmp at %s UT\n\n", $_[0], $obt;
    # try to figure out next comm passes
    open COMS, $comfile;
    my @time = split(":", $obt);
    # use decimal day to allow comms spanning two days
    my $day = $time[1] + ($time[2]/24) + ($time[3]/1440);
    while (<COMS>) {
      my @line = split(" ", $_);
      #print FILE "$time[0] $time[1] $time[2] $time[3]\n"; # debug
      #print FILE "$line[0] $line[4] $line[6] $line[7]\n"; # debug
      if ($line[0] < $time[0]) {next;}
      if ($line[4] < $time[1]) {next;}
      #if ($line[7] < ("$time[2]"."$time[3]")) {next;}
      if ($line[3] < $day) {next;}
      my @next = split(/\./, $line[1]);
      print FILE "Current pass:  $line[0]:$next[0]:$line[6] to $line[7]\n";
      print FILE "Next passes:   ";
      @line = split(" ", <COMS>);
      @next = split(/\./, $line[1]);
      print FILE "$line[0]:$next[0]:$line[6] to $line[7]\n";
      @line = split(" ", <COMS>);
      @next = split(/\./, $line[1]);
      print FILE "               $line[0]:$next[0]:$line[6] to $line[7]\n";
      @line = split(" ", <COMS>);
      @next = split(/\./, $line[1]);
      print FILE "               $line[0]:$next[0]:$line[6] to $line[7]\n";
      last;
    }
      
    print FILE "\nSnapshot:\n";
    print FILE "http://cxc.harvard.edu/cgi-gen/mta/Snap/snap.cgi\n"; #debug
    #print FILE "This message sent to sot_red_alert\n"; #debug
    #print FILE "This message sent to swolk brad brad1\n"; #debug
    print FILE "This message sent to brad brad1\n"; #debug
    #print FILE "\n TEST   TEST   TEST   TEST   TEST   TEST   TEST\n"; #debug
    close FILE;

    #open MAIL, "|mailx -s AIRU1G1I brad\@head.cfa.harvard.edu swolk\@head.cfa.harvard.edu 6172573986\@mobile.mycingular.com";
    open MAIL, "|mailx -s AIRU1G1I brad\@head.cfa.harvard.edu 6172573986\@mobile.mycingular.com";
    #open MAIL, "|mailx -s AIRU1G1I sot_red_alert\@head.cfa.harvard.edu";
    open FILE, $afile;
    while (<FILE>) {
      print MAIL $_;
    }
    close FILE;
    close MAIL;
  }
}

sub send_ctxpwr_alert {
  my $obstime = ${$hash{CTXAPWR}}[0];
  if (! time_curr($obstime)) {
    return;
  }
  my $afile = "/home/mta/Snap/.ctxpwralert";
  if (-s $afile) {
  } else {
    open FILE, ">$afile";
    print FILE "Chandra realtime telemetry shows Transmitter $_[1] Power = $_[0] DBM at $obt UT\n";
    print FILE "Limit = 36.75 DBM\n\n";
    print FILE "This message sent to brad\n"; #debug
    close FILE;

    open MAIL, "|mailx -s CTXPWR brad\@head.cfa.harvard.edu swolk\@head.cfa.harvard.edu";
    #open MAIL, "|mailx -s CTXPWR brad\@head.cfa.harvard.edu";
    #open MAIL, "|mailx -s CTXPWR sot_yellow_alert\@head.cfa.harvard.edu";
    open FILE, $afile;
    while (<FILE>) {
      print MAIL $_;
    }
    close FILE;
    close MAIL;
  }
}

sub send_ctxv_alert {
  my $obstime = ${$hash{CTXAV}}[0];
  if (! time_curr($obstime)) {
    return;
  }
  my $afile = "/home/mta/Snap/.ctxvalert";
  if (-s $afile) {
  } else {
    open FILE, ">$afile";
    print FILE "Chandra realtime telemetry shows Transmitter $_[1] Voltage = $_[0] V at $obt UT\n";
    print FILE "Limit = 3.60 V\n\n";
    print FILE "This message sent to brad\n"; #debug
    close FILE;

    open MAIL, "|mailx -s CTXV brad\@head.cfa.harvard.edu swolk\@head.cfa.harvard.edu";
    #open MAIL, "|mailx -s CTXV brad\@head.cfa.harvard.edu";
    open FILE, $afile;
    while (<FILE>) {
      print MAIL $_;
    }
    close FILE;
    close MAIL;
  }
}

sub send_hkp27v_alert {
  my $obstime = ${$hash{"5HSE202"}}[0];
  #print "send_hkp27v $obstime\n";
  if (! time_curr($obstime)) {
    return;
  }
  my $afile = "/home/mta/Snap/.hkp27valert";
  if (-s $afile) {
  } else {
    open FILE, ">$afile";
    print FILE "Chandra realtime telemetry shows EPHIN HKP27V Voltage = $_[0] V at $obt UT\n";
    print FILE "Limit > 26.0 V\n\n";
    print FILE "This message sent to sot_yellow_alert\n"; #debug
    close FILE;

    open MAIL, "|mailx -s HKP27V sot_yellow_alert\@head.cfa.harvard.edu";
    open FILE, $afile;
    while (<FILE>) {
      print MAIL $_;
    }
    close FILE;
    close MAIL;
  }
}

sub send_pline03t_alert {
  my $obstime = ${$hash{"PLINE03T"}}[0];
  if (! time_curr($obstime)) {
    return;
  }
  my $afile = "/home/mta/Snap/.pline03talert";
  if (-s $afile) {
  } else {
    open FILE, ">$afile";
    print FILE "Chandra realtime telemetry shows  PLINE03T = $_[0] F at $obt UT\n";
    print FILE "Limit > 42.5 V\n\n";
    print FILE "This message sent to sot_yellow_alert\n"; #debug
    close FILE;

    open MAIL, "|mailx -s PLINE03T brad\@head.cfa.harvard.edu";
    #open MAIL, "|mailx -s PLINE03T sot_yellow_alert\@head.cfa.harvard.edu";
    open FILE, $afile;
    while (<FILE>) {
      print MAIL $_;
    }
    close FILE;
    close MAIL;
  }
}

sub send_pline04t_alert {
  my $obstime = ${$hash{"PLINE04T"}}[0];
  if (! time_curr($obstime)) {
    return;
  }
  my $afile = "/home/mta/Snap/.pline04talert";
  if (-s $afile) {
  } else {
    open FILE, ">$afile";
    print FILE "Chandra realtime telemetry shows  PLINE04T = $_[0] F at $obt UT\n";
    print FILE "Limit > 42.5 V\n\n";
    print FILE "This message sent to sot_yellow_alert\n"; #debug
    close FILE;

    open MAIL, "|mailx -s PLINE04T brad\@head.cfa.harvard.edu";
    #open MAIL, "|mailx -s PLINE04T sot_yellow_alert\@head.cfa.harvard.edu";
    open FILE, $afile;
    while (<FILE>) {
      print MAIL $_;
    }
    close FILE;
    close MAIL;
  }
}

sub time_curr {
  use Time::TST_Local;
  # return 1 if $time is within $tlim seconds of current time
  #  else return 0
  $tlim = 120;
  $time = $_[0];
  my $t1998 = 883612800.0;
  @now = gmtime();
  $curr_time = timegm(@now) - $t1998;
  #print "time: $time\n";
  #print "curr: $curr_time\n";
  $diff = abs($curr_time - $time);
  if ($diff <= $tlim) {
    return 1;
  } else {
    return 0;
  }
}
  
1;
