#!/opt/local/bin/perl
#/usr/bin/perl
#/proj/axaf/bin/perl

# Will not run if RT data is not flowing,
#  to force update, even on old data, use -f option.

use snap;

# produce a Chandra status snapshot

# define the working directory for the snapshots

#$work_dir = "/proj/ascwww/AXAF/extra/science/cgi-gen/mta/Snap";
$work_dir = "/data/mta4/www/Snapshot";
$web_dir = "/data/mta4/www/Snapshot";
#$web_dir = "/proj/ascwww/AXAF/extra/science/cgi-gen/mta/Snap";
$wap_dir = "/data/mta4/www/WL/Snap_dat";
$text_ver = "./chandra.snapshot";
$pool_ver = "/pool14/chandra/chandra_psi.snapshot";
$check_comm_file = "/home/mta/Snap/check_comm_fail"; # file to write if 
                                        # check comm fails and alert is sent
$check_comm_file_bu="/home/mta/Snap/check_comm_fail_bu";
$check_comm_sent="/home/mta/Snap/check_comm_sent";

my @ftype = qw(ACA CCDM EPHIN EPS PCAD IRU SIM-OTG SI TEL EPS-SFMT NORM-SFMT);

# see if a tlogr is already running, but if too many 
#  iterations have been skipped something is wrong, so start a new one.
#my $lock = '/proj/ascwww/AXAF/extra/science/cgi-gen/mta/Snap/.on';
my $lock = '/data/mta4/www/Snapshot/.on';
if (-s $lock) {
  open(LOCK, $lock);
  my $errs = 0;
  while (<LOCK>) {
    ++$errs;
  }
  close (LOCK);
  if ($errs > 3) {
    unlink $lock;
  } else {
    `date >> $lock`;
    exit();
  }
}

my $aos = 0;
@tlfiles = <$work_dir/chandra*.tl>;
foreach $f (@tlfiles) {
  if (&time_test($f,3) > 0) {
  #if (-M $f < 4/1440) {
    $aos = 1;
    last;
  }
}

#if (exists($ARGV[0]) && $ARGV[0] == "-f") { $aos=1; }
if ($ARGV[0] =~ m/-f/) { $aos=1; }
if (! $aos) {
  unlink "/home/mta/Snap/.gyrowait";
  use snap_format;
  update_txt("$text_ver"); #save a local copy and then copy
  `cp $text_ver $pool_ver`;#do in two steps to avoid dependancy on pool space

  # update wireless current page
  %h = get_curr;
  %h = get_curr(%h);
  $utc = `date -u +"%Y:%j:%T (%b%e)"`;
  chomp $utc;
  $h{UTC} = [time_now(), $utc, "", "white"];
  $snapf = "$wap_dir/../snap_curr.wml";
  open(SF,">$snapf") or die "Cannot open $snapf\n";
  print SF write_curr_wap(%h);
  close SF;
  $snapf = "$wap_dir/snap_curr.txt";
  open(SF,">$snapf") or die "Cannot open $snapf\n";
  print SF write_curr_wap_arc(%h);
  close SF;
  # see if we should be aos
  check_comm($check_comm_file);
  # if no data on primary or backup, send alert
  if (-s $check_comm_file && -s $check_comm_file_bu && ! -s $check_comm_sent) {
    `cp $check_comm_file $check_comm_sent`;
    #`cat $check_comm_file | mailx -s 'check_comm' brad swolk`;
    `cat $check_comm_file | mailx -s 'check_comm' sot_lead brad jnichols pmendygral`;
  } # if (-s $check_comm_file && -s $check_comm_file_bu && 
  # give backup control of alerts, in case it sees data
  if (! -e "/home/mta/Snap/.alerts_bu") {
    `cp check_state_alerts.pm /home/mta/Snap/check_state.pm`;
    `cp snaps2_alerts.par /home/mta/Snap/snaps2.par`;
    `date > /home/mta/Snap/.alerts_bu`;
  } # if (! -e "/home/mta/Snap/.alerts_bu") {
  exit();
}

# take control of alerts
if (-e "/home/mta/Snap/.alerts_bu") {
  `cp check_state_noalerts.pm /home/mta/Snap/check_state.pm`;
  `cp snaps2_noalerts.par /home/mta/Snap/snaps2.par`;
  `/usr/bin/rm /home/mta/Snap/.alerts_bu`;
} # if (-e "/home/mta/Snap/.alerts_bu") {
# start check_comm all clear e-mails
if (-s $check_comm_file) {
  open MAIL, "| mailx -s 'check_comm' brad";
  print MAIL "Rhodes data flow resumed.\n";
  close MAIL;
  unlink $check_comm_file;
} # if (-s $check_comm_file) {

#if (! -s $check_comm_file && ! -s $check_comm_file_bu && -s $check_comm_sent) {
if (! -s $check_comm_file && -s $check_comm_sent) {
  #open MAIL, "| mailx -s 'check_comm' brad swolk";
  open MAIL, "| mailx -s 'check_comm' sot_lead brad jnichols pmendygral";
  print MAIL "Real-time data flow has resumed.\n";
  close MAIL;
  unlink $check_comm_sent;
} #if (! -s $check_comm_file && ! -s $check_comm_file_bu && 
# end check_comm all clear e-mails

`date > $lock`;

my %h = get_data($work_dir, @ftype);
 
use comps;
%h = do_comps(%h);

%h = set_status(%h, get_curr(%h));

# check state
use check_state;
%h = check_state(%h);

#foreach $msid ( keys %h ) {
    #print "$msid: @{ $h{$msid} }\n";
#}

use snap_format;
my $snap_text = write_txt(%h);
my $snap_html = write_htm(%h);
#my $snap_wap = write_wap(%h);
my $snap_curr_wap = write_curr_wap(%h);
my $curr_wap_txt = write_curr_wap_arc(%h);

# write out the current snapshot

#<mirror>#$snapf = "/pool14/chandra/chandra2.snapshot";
#<mirror>$snapf = "/data/mta/www/MIRROR/Snap/chandra2.snapshot";
#<mirror>open(SF,">$snapf") or die "Cannot create $snapf\n";
#<mirror>print SF $st,$s;
#<mirror>close SF;

## write the snapshot to a daily archive file if it has changed
#
#if ($sp ne $s) {
    #$date = sprintf "%4d%3.3d",$y+1900,$yday+1;
    #$snapf = "/pool7/snarc/snarc.$date";
    #open(SF,">>$snapf") or die "Cannot append to $snapf\n";
    #print SF $st,$s;
    #close SF;
#}

# December 2000 BDS: add state checking
#  print new annotated snapshot

# October 2000: State checking added by TLA
# Robert Cameron
# October 1999

# write out the current snapshot

#$snapf = "/pool14/chandra/chandra2.snapshot";
$snapf = $text_ver;
open(SF,">$snapf") or die "Cannot create $snapf\n";
print SF $snap_text;
close SF;
`cp $text_ver $pool_ver`;

#$snapf = "$work_dir/chandra.snapshot";
#open(SF,">$snapf") or die "Cannot create $snapf\n";
#print SF $snap_text;
#close SF;

# write the snapshot to a daily archive file if it has changed

#($old, $junk1, $junk2) = get_value($sp, 'OBT', 'CTUVCDU');
#($new, $junk1, $junk2) = get_value($snap_text, 'OBT', 'CTUVCDU');
#$old = substr($sp, index($sp, 'OBT'));
#$new = substr($snap_text, index($snap_text, 'OBT'));
#if ($old ne $new) {
$date = sprintf "%4d%3.3d",$y+1900,$yday+1;
$snapf = "$web_dir/snarc.$date";
open(SF,">>$snapf") or die "Cannot append to $snapf\n";
print SF $snap_html;
close SF;
#}
 
# make wireless page
#$snapf = "/data/mta4/www/WL/snap.wml";
#open(SF,">$snapf") or die "Cannot open $snapf\n";
#print SF $snap_wap;
#close SF;
write_wap(%h);
write_wap_arc(%h);
$snapf = "/data/mta4/www/WL/snap_curr.wml";
open(SF,">$snapf") or die "Cannot open $snapf\n";
print SF $snap_curr_wap;
close SF;
$snapf = "$wap_dir/snap_curr.$date";
open(SF,">>$snapf") or die "Cannot append to $snapf\n";
print SF $curr_wap_txt;
close SF;
$snapf = "$wap_dir/snap_curr.txt";
open(SF,">$snapf") or die "Cannot append to $snapf\n";
print SF $curr_wap_txt;
close SF;

unlink $lock;

`/opt/local/bin/idl plot > /dev/null`;  # make plots
#end