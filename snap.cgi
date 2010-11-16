#!/usr/bin/perl -w
#/proj/axaf/bin/perl -w

# browse the Chandra snapshot archive

# October 2000: State checking added by TLA
# Robert Cameron
# October 1999

use CGI ':standard';
#use lib '/proj/rad1/ska/lib/perl5/local';
#use lib '/proj/ascwww/AXAF/extra/science/cgi-gen/mta/Snap';
use lib '/data/mta4/www/Snapshot';
use Chex;

# read the snapshot archive

#$snarcdir = '/pool7/brad/snarc';
#mirror $snarcdir = '/data/mta/www/MIRROR/Snap';
#$snarcdir = '/proj/ascwww/AXAF/extra/science/cgi-gen/mta/Snap';
$snarcdir = '/data/mta4/www/Snapshot';
@snarcfiles = <$snarcdir/snarc.2*>;
foreach $f (@snarcfiles) {
    if (open SF, $f) {
	while (<SF>) {
	    if (/UTC/) { push @r,$r; $r = '' };
	    $r .= $_;
	}
	close SF;
    }
}
push @r,$r;
shift @r;

# read the top line of the latest snapshot

#$top = (open SF, '/pool14/chandra/chandra_psi.snapshot')? <SF> : '';
$top = (open SF, './chandra.snapshot')? <SF> : '';
#$top = (open SF, '/data/mta/www/MIRROR/Snap/chandra.snapshot')? <SF> : '';

#### this stuff is to generate $top if chandra.snapshot is not kept current
#  but, for now it is, so skip this
#read the ephemeris file
#
#@ephem = split ' ',<EF> if open (EF, '/proj/rac/ops/ephem/gephem.dat');
#
## read the ACE flux
#
#$fluf = "/proj/rac/ops/ACE/fluace.dat";
#if (open FF, $fluf) {
#    @ff = <FF>;
#    @fl = split ' ',$ff[-3];
#    $fluxace = $fl[11];
#    close FF;
#} else { print STDERR "$fluf not found!\n" };
#
## read the ACIS fluence
#
##$fluf = "/data/acis25/svirani/ACIS/FLU-MON/ACIS-FLUENCE.dat";
##if (open FF, $fluf) {
#    #@ff = <FF>;
#    #@fl = split ' ',$ff[-1];
#    #$fluace = $fl[9];
#    #close FF;
##} else { print STDERR "$fluf not found!\n" };
#
## read the CRM fluence - replaces F_ACE in snapshot May 2001
#$fluf = "/proj/rac/ops/CRM/CRMsummary.dat";
#if (open FF, $fluf) {
#    @ff = <FF>;
#    @fl = split ' ',$ff[-1];
#    $flucrm = $fl[-1];
#    close FF;
#} else { print STDERR "$fluf not found!\n" };
#
## read the ACE Kp file
#
#$kpf = "/proj/rac/ops/ACE/kp.dat";
#if (open KPF, $kpf) {
#    while (<KPF>) { $kp = $_ };
#} else { print STDERR "Cannot read $kpf\n" };
#@kp = split /\s+/, $kp;
#
#$utc = `date -u +"%Y:%j:%T (%b%e)"`;
#chomp $utc;
#
##$top = sprintf "UTC %s f_ACE %.2e F_ACE %.2e Kp %.1f R km%7s%s\n",$utc,$fluxace,$fluace,$kp[9],$ephem[0],$ephem[1];
#$top = sprintf "UTC %s f_ACE %.2e F_CRM %.2e Kp %.1f R km%7s%s\n",$utc,$fluxace,$flucrm,$kp[9],$ephem[0],$ephem[1];
####### end generate $top #############################################

# read the current proton flux info

 #$pfile = '/proj/rac/ops/CRM2/CRMsummary.dat';
 $pfile = './CRMsummary.dat';  # it is now copied over for DMZ transistion 11/16/10 bds
 open FF, $pfile;
 while (<FF>) {$fluxinfo .= $_};

# write a snapshot plus CGI controls

print header, start_html(-title => "Chandra Snapshot Browser",
			 -BGCOLOR => 'black',
			 -TEXT    => 'white',
                         -LINK    => 'white',
                         -VLINK    => 'white',
                         -ALINK    => 'white');

if (defined param("idx") && ! defined param("action")) {
  $action = "Indef";
  $i = param("idx");
} else {
  $action = (defined param("action"))? param("action") : "Latest";
  $i = (defined param("idx"))? param("idx") : $#r;
}
$i = 0 if ($action=~/Earliest/);
$i++ if ($action=~/Next/);
$i-- if ($action=~/Prev/);
$i = $#r if ($action=~/Latest/);
$i = 0 if ($i < 0);
$i = $#r if ($i > $#r || $i=~/[^0-9]/);

$cur = CGI->new();
$cur->param("idx",$i);

#print pre("<meta http-equiv=\"refresh\" content=\"60, \/snap.cgi\">");

#$snap_text = check_state($r[$i]);
#print pre($snap_text);
print pre($r[$i]);

print start_form;
print submit(-name=>'action',-value=>"Earliest");
print submit(-name=>'action',-value=>"Prev");
print $cur->textfield("idx",$i,4);
print submit(-name=>'action',-value=>"Next");
print submit(-name=>'action',-value=>"Latest");

print "\n &nbsp &nbsp <a href=\"./snapshot_hlp.html\">Explanation<\/a>\n";

print h4('Current Data:');
print pre($top);
print pre($fluxinfo);

print end_form,end_html;

########################################################################
sub check_state {
########################################################################
    my $snap = shift;

    # Create the Chandra Expected state object
    $chex = Chex->new;

    # Get OBT from snapshot
    ($date) = get_value($snap, 'OBT','CTUVCDU');

    # Set up tolerances for ra, dec, roll
    $d2r = 3.14159265/180.;
    $ra_tol = 50/3600.;
    $dec_tol = 50/3600.;
    $roll_tol = 500/3600.;

    # If there is a unique value of dec, then adjust $ra_tol
    %pred = $chex->get($date);
    @dec_vals = @{$pred{dec}};
    $ra_tol *= 1.0 / (cos($dec_vals[0] * $d2r) + 1e-5) if (@dec_vals == 1) ;

    # Define variables to check
    my @checks = ({ state_var => 'simtsc',
		    prec      => 'SIM TTpos',
		    post      => 'HETG Angle',
		    tol       =>  5},
		  { state_var => 'simfa',
		    prec      => 'SIM FApos',
		    post      => 'LETG Angle',
                    tol       =>  5},
		  { state_var => 'obsid',
		    prec      => 'OBSID',
		    post      => 'EPState',
		    tol       =>  0.001},
		  { state_var => 'ra',
		    prec      => 'RA',
		    post      => 'Bus V',
                    tol       => $ra_tol},
		  { state_var => 'dec',
		    prec      => ' Dec ',
		    post      => 'Bus I',
                    tol       => $dec_tol},
		  { state_var => 'roll',
		    prec      => 'Roll',
		    post      => 'ACA Object',
		    tol       => $roll_tol}
		  );

    # Now do the checking, and adjust color of text accordingly
    foreach $check (@checks) {
	($val, $index0, $index1)  = get_value($snap, $check->{prec}, $check->{post});

	$match = $chex->match(var => $check->{state_var}, # State variable name
			      val => $val, # Observed state value
			      tol => $check->{tol});

	$color = "#66FFFF"; # Default to blue (not checked or undef)
	$color = "#FF0000" if ($match == 0); # Bad match => red
	$color = "#33CC00" if ($match == 1); # Good match => green

	substr $snap, $index1-1, 0, "</font>";
	substr $snap, $index0, 0, "<font color=\"$color\">";
    }

    return $snap;
}

####################################################################################
sub get_value {
####################################################################################
# Get a value in $s which is surrounded by $prec and $post
    my ($s, $prec, $post) = @_;
    my $index0 = index($s, $prec);
    my $index1 = index($s, $post);
    my $start = $index0 + length $prec;
    my $len   = $index1 - $start;
    my $val = substr $s, $start, $len;
    $val =~ s/^\s+//;
    $val =~ s/\s+$//;
    
    return ($val, $index0, $index1);
}
