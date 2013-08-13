#!/proj/cm/Release/install.linux64.DS10/ots/bin/perl
##!/opt/local/bin/perl -w

# check that my acorn process is running
# if not, restart and log the process id

# Robert Cameron
# April 2000

$uid = "mta";
#$work_dir = "/proj/ascwww/AXAF/extra/science/cgi-gen/mta/Snap";
$work_dir = "/data/mta4/www/Snapshot";
$pid_file = "$work_dir/racorn.pid";
#@acorn = qw(/home/ascds/DS.release/bin/acorn /proj/cm/Release/install.DS7.6.9/bin/acorn /data/mta2/pallen/acorn-1.33/acorn /home/swolk/acorn/src1-3/acorn);
@acorn = qw(/home/ascds/DS.release/bin/acorn);
#@acorn = qw(/export/acis-flight/primary/acorn-1.33/acorn);
#@acorn = qw(/home/acisdude/real-time/back-up/acorn-1.33/acorn);
#@acorn = qw(/home/mta/ACORN/acorn1.52);
$acorn_exe = (-e $acorn[0])? $acorn[0] : $acorn[1];
#$UDP_port = "11111"; # eno's acorn feed
$UDP_port = "11112"; # multimon port (eno)
#$UDP_port = "11113"; # temp feed from forbin bds 09/11/03
$msids = "$work_dir/chandra-msids.list";
#$msids = "$work_dir/msids.list";
$filesize = 500;

# set environment variables for acorn

@mta_data = qw(/home/ascds/DS.release/config/mta/data /data/mta2/pallen/acorn-1.3/groups /home/swolk/acorn/groups);
$ENV{ASCDS_CONFIG_MTA_DATA} = (-e $mta_data[0])? $mta_data[0] : $mta_data[1]; 
# use custom IPCL dir to get uncalibrated SHLDART, DETART, but
#  everything else calibrated
@ipcl = qw(/data/mta4/www/Snapshot/P009 /home/ascds/DS.release/config/tp_template/P009/ /home/ascds/swolk/IPCL/P008 /home/swolk/acorn/ODB);
#@ipcl = qw(/home/ascds/DS.release/config/tp_template/P009/ /home/ascds/swolk/IPCL/P008 /home/swolk/acorn/ODB);
$ENV{IPCL_DIR} = (-e $ipcl[0])? $ipcl[0] : $ipcl[1];
$ENV{LD_LIBRARY_PATH} = '/home/ascds/DS.release/lib:/home/ascds/DS.release/ots/lib:/soft/SYBASE_OSRV15.5/OCS-15_0/lib:/home/ascds/DS.release/otslib:/opt/X11R6/lib:/usr/lib64/alliance/lib:$LD_LIBRARY_PATH';
chdir $work_dir or die "Cannot cd to $work_dir\n";

# get the PID for the last known acorn process

open (PIDF, "$pid_file") or die "Cannot read PID file $pid_file\n";
while (<PIDF>) { @pinfo = split };

# get the PID for the currently running acorn process (if any)
#
#@p = `/usr/ucb/ps -auxwww | grep $uid`;
@p = `/bin/ps -auxwww | grep $uid`;
#@a = grep /$acorn_exe.+$work_dir/, @p;
@a = grep /$acorn_exe.+$msids/, @p;
if (!@a) {
    $host=`hostname`;
    chomp $host;
    system("$acorn_exe -u $UDP_port -C $msids -e $filesize -nv > /dev/null &");
    #TMP open MAIL, "|mailx -s acorn 6172573986\@mobile.mycingular.com brad\@head-cfa.harvard.edu";
    open MAIL, "|mailx -s acorn brad\@head-cfa.harvard.edu";
    print MAIL "$host rhodes acorn dead. restarting. \n\n"; # current version
    close MAIL;
    print "Acorn process not found: restarting\n";
    sleep 3;
    #`../SOH/run-acorn.pl`;
    #`../SOH/PCAD/run-acorn.pl`;
}

@p = `/usr/ucb/ps -auxwww | grep $uid`;
@a = grep /$acorn_exe.+$work_dir/, @p;
die "Cannot find or restart acorn process\n" if (!@a);

foreach (@a) {
    @f = split;
    $pid = $f[1];
}

# compare the actual and expected PIDs. Log any change.

if ($pinfo[0] ne $pid) {
    $date = `date`;
    print "Acorn PID mismatch. Putting pid $pid in $pid_file at $date";
    open (PIDF, ">$pid_file") or die "Cannot write PID file $pid_file\n";
    print PIDF "$pid started at $date";
}
