# computations for chandra snapshot
# BDS May 2001

sub time_now {
  use Time::TST_Local;
  my $t1998 = 883612800.0;
  my @now = gmtime();
  return (timegm(@now) - $t1998);
}

sub do_comps {
  my %h = @_;
  %eph_large = (E150,0.25, E300,1.78, E1300,2.01, P4GM,0.18, P41GM,0.18);
  %eph_small = (E150,0.01, E300,0.14, E1300,0.12, P4GM,0.18, P41GM,0.18);

  # do some computations
  
  $t1998 = 883612800.0;
  my @times;
  foreach $key (keys(%h)) {
    push @times, ${$h{$key}}[0];
  }
  @stimes = sort numerically @times;
  $ltime = pop @stimes;
  $time0 = shift @stimes;
  #die "Exit because of stale data! Data timespan: $time0 to $ltime\n" if ($ltime - $time0) > 100000;

  ($sec,$min,$hr,$dummy,$dummy,$y,$dummy,$yday,$dummy) = gmtime($ltime+$t1998);
  $obt = sprintf "%4d:%3.3d:%2.2d:%2.2d:%2.2d",$y+1900,$yday+1,$hr,$min,$sec;
  $h{OBT} = [$ltime, $obt, 0, "white"]; 
  
  $q1 = ${$h{AOATTQT1}}[1];
  $q2 = ${$h{AOATTQT2}}[1];
  $q3 = ${$h{AOATTQT3}}[1];
  $q1sq = $q1**2;
  $q2sq = $q2**2;
  $q3sq = $q3**2;
  $q4sq = 1 - $q1sq - $q2sq - $q3sq;
  $q4 = sqrt($q4sq);
  $xa = $q1sq - $q2sq - $q3sq + $q4sq;
  $xb = 2*($q1*$q2 + $q3*$q4);
  $xn = 2*($q1*$q3 - $q2*$q4);
  $yn = 2*($q2*$q3 + $q1*$q4);
  $zn = $q3sq + $q4sq - $q1sq - $q2sq;
  $r2d = 180 / 3.141593;
  $r2as = $r2d * 3600;
  $dec = atan2($xn, sqrt(1 - $xn**2)) * $r2d;
  $ra = atan2($xb,$xa) * $r2d;
  $roll = atan2($yn,$zn) * $r2d;
  $ra += 360 if $ra < 0;
  $roll += 360 if $roll < 0;
  
  $h{RA} = [${$h{AOATTQT1}}[0], $ra, ${$h{AOATTQT1}}[2], ${$h{AOATTQT1}}[3]];
  $h{ROLL} = [${$h{AOATTQT1}}[0], $roll, ${$h{AOATTQT1}}[2], ${$h{AOATTQT1}}[3]];
  $h{DEC} = [${$h{AOATTQT1}}[0], $dec, ${$h{AOATTQT1}}[2], ${$h{AOATTQT1}}[3]];
  
  $acaobj = substr(${$h{AOACFID0}}[1],0,1).substr(${$h{AOACFID1}}[1],0,1).
            substr(${$h{AOACFID2}}[1],0,1).substr(${$h{AOACFID3}}[1],0,1).
            substr(${$h{AOACFID4}}[1],0,1).substr(${$h{AOACFID5}}[1],0,1).
            substr(${$h{AOACFID6}}[1],0,1).substr(${$h{AOACFID7}}[1],0,1);

  $h{ACAOBJ} = [${$h{AOACFID0}}[0], $acaobj, ${$h{AOACFID0}}[2], ${$h{AOACFID0}}[3]];

  $acafct = substr(${$h{AOACFCT0}}[1],0,1).substr(${$h{AOACFCT1}}[1],0,1).
            substr(${$h{AOACFCT2}}[1],0,1).substr(${$h{AOACFCT3}}[1],0,1).
            substr(${$h{AOACFCT4}}[1],0,1).substr(${$h{AOACFCT5}}[1],0,1).
            substr(${$h{AOACFCT6}}[1],0,1).substr(${$h{AOACFCT7}}[1],0,1);

  $h{ACAFCT} = [${$h{AOACFCT0}}[0], $acafct, ${$h{AOACFCT0}}[2], ${$h{AOACFCT0}}[3]];
  
  $acistat = ${$h{"1STAT7ST"}}[1].${$h{"1STAT6ST"}}[1].${$h{"1STAT5ST"}}[1].${$h{"1STAT4ST"}}[1].
             ${$h{"1STAT3ST"}}[1].${$h{"1STAT2ST"}}[1].${$h{"1STAT1ST"}}[1].${$h{"1STAT0ST"}}[1];
  $acistat = unpack "H*", pack("B*",$acistat);

  $h{ACISTAT} = [${$h{"1STAT7ST"}}[0], $acistat, ${$h{"1STAT7ST"}}[2], ${$h{"1STAT7ST"}}[3]];
  
  #$eph{INT} = (${$h{"5EP00716"}}[1] == 0) ? ${$h{"5EP00704"}}[1] : 
  #    (${$h{"5EP00704"}}[1]+256) * (2**(${$h{"5EP00716"}}[1] - 1));
  $eph{P4GM}  = (${$h{"5EP00500"}}[1] == 0) ? ${$h{"5EP00488"}}[1] : 
      (${$h{"5EP00488"}}[1]+256) * (2**(${$h{"5EP00500"}}[1] - 1));
  $eph{P41GM} = (${$h{"5EP00764"}}[1] == 0) ? ${$h{"5EP00752"}}[1] : 
      (${$h{"5EP00752"}}[1]+256) * (2**(${$h{"5EP00764"}}[1] - 1));
  $eph{E150} = (${$h{"5EP00668"}}[1] == 0) ? ${$h{"5EP00656"}}[1] : 
      (${$h{"5EP00656"}}[1]+256) * (2**(${$h{"5EP00668"}}[1] - 1));
  $eph{E300} = (${$h{"5EP00688"}}[1] == 0) ? ${$h{"5EP00672"}}[1] : 
      (${$h{"5EP00672"}}[1]+256) * (2**(${$h{"5EP00688"}}[1] - 1));
  $eph{E1300} = (${$h{"5EP00692"}}[1] == 0) ? ${$h{"5EP00680"}}[1] : 
      (${$h{"5EP00680"}}[1]+256) * (2**(${$h{"5EP00692"}}[1] - 1));
  
  $eph{GEOM} = "BAD";
  if (${$h{"5EHSE2"}}[1] == 255) {
      $eph{GEOM} = "LARG";
      foreach (keys %eph_large) { $eph{$_} /= $eph_large{$_}*65.6 };
  }
  if (${$h{"5EHSE2"}}[1] == 193) {
      $eph{GEOM} = "SMAL";
      foreach (keys %eph_small) { $eph{$_} /= $eph_small{$_}*65.6 };
  }

  # after turning off det A
  #foreach (keys %eph_small) { $eph{$_} /= 1.17*65.6 };
  #foreach (keys %eph_small) { $eph{$_} /= 1.17 };

  $h{GEOM} = [${$h{"5EHSE2"}}[0], $eph{GEOM}, ${$h{"5EHSE2"}}[2], ${$h{"5EHSE2"}}[3]];
  $h{P4GM}  = [${$h{"5EP00500"}}[0], $eph{P4GM}, ${$h{"5EP00500"}}[2], ${$h{"5EP00500"}}[3]];
  $h{P41GM} = [${$h{"5EP00764"}}[0], $eph{P41GM}, ${$h{"5EP00764"}}[2], ${$h{"5EP00764"}}[3]];
  $h{E150} = [${$h{"5EP00668"}}[0], $eph{E150}, ${$h{"5EP00668"}}[2], ${$h{"5EP00668"}}[3]];
  $h{E300} = [${$h{"5EP00688"}}[0], $eph{E300}, ${$h{"5EP00688"}}[2], ${$h{"5EP00688"}}[3]];
  $h{E1300} = [${$h{"5EP00692"}}[0], $eph{E1300}, ${$h{"5EP00692"}}[2], ${$h{"5EP00692"}}[3]];
  
  $socb1 = (${$h{EOCHRGB1}}[1] > 120)? ${$h{EOCHRGB1}}[1]/100 : ${$h{EOCHRGB1}}[1]*100;
  $socb2 = (${$h{EOCHRGB2}}[1] > 120)? ${$h{EOCHRGB2}}[1]/100 : ${$h{EOCHRGB2}}[1]*100;
  $socb3 = (${$h{EOCHRGB3}}[1] > 120)? ${$h{EOCHRGB3}}[1]/100 : ${$h{EOCHRGB3}}[1]*100;
  
  $h{SOCB1} = [${$h{EOCHRGB1}}[0], $socb1, ${$h{EOCHRGB1}}[2], ${$h{EOCHRGB1}}[3]];
  $h{SOCB2} = [${$h{EOCHRGB2}}[0], $socb2, ${$h{EOCHRGB2}}[2], ${$h{EOCHRGB2}}[3]];
  $h{SOCB3} = [${$h{EOCHRGB3}}[0], $socb3, ${$h{EOCHRGB3}}[2], ${$h{EOCHRGB3}}[3]];

  $aleak = (${$h{"5EHSE400"}}[1] < 1.02)? ${$h{"5EHSE400"}}[1] : 1.02;
  $h{ALEAK} = [${$h{"5EHSE400"}}[0], $aleak, ${$h{"5EHSE400"}}[2], ${$h{"5EHSE400"}}[3]];
  
  $h{AODITHR3}[1] = ${$h{AODITHR3}}[1]*$r2as;
  $h{AORATE3}[1] = ${$h{AORATE3}}[1]*$r2as;
  $h{AODITHR2}[1] = ${$h{AODITHR2}}[1]*$r2as;
  $h{AORATE2}[1] = ${$h{AORATE2}}[1]*$r2as;
  $h{AORATE1}[1] = ${$h{AORATE1}}[1]*$r2as;
  $h{AACCCDPT}[1] = (${$h{AACCCDPT}}[1] - 32)*5/9;
  $h{AOACINTT}[1] = ${$h{AOACINTT}}[1]/1000;

  # if shld hv is off, make rate 0, acorn comes out NaN
  if (${$h{"2S2HVST"}}[1] == 0) { ${$h{"2SHLDART"}}[1]=0; }

  $utc = `date -u +"%Y:%j:%T (%b%e)"`;
  chomp $utc;
  $h{UTC} = [time_now(), $utc, "", "white"];
   
  return %h;
}

sub numerically { $a <=> $b };

1;
