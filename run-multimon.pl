#!/opt/local/bin/perl -w

# check that my multimon process is running
# if not, restart and log the process id


$uid = "brad";
$port = "15000";
$pid_file = "/home/$uid/rmulti.pid";
@multi = qw(/data/mta1/pallen/multimon/multimon);
#$multi_exe = (-e $multi[0])? $multi[0] : $multi[1];
$multi_exe = $multi[0];

# get the PID for the last known multi process

open (PIDF, "$pid_file") or die "Cannot read PID file $pid_file\n";
while (<PIDF>) { @pinfo = split };

# get the PID for the currently running acorn process (if any)

@p = `/usr/ucb/ps -auxwww | grep $uid`;
@a = grep /$multi_exe/, @p;
if (!@a) {
    system("$multi_exe $port &");
    print "Multimon process not found: restarting\n";
    sleep 3;
}

@p = `/usr/ucb/ps -auxwww | grep $uid`;
@a = grep /$multi_exe/, @p;
die "Cannot find or restart multimon process\n" if (!@a);

foreach (@a) {
    @f = split;
    $pid = $f[1];
}

# compare the actual and expected PIDs. Log any change.

if ($pinfo[0] ne $pid) {
    $date = `date`;
    print "Multimon PID mismatch. Putting pid $pid in $pid_file at $date";
    open (PIDF, ">$pid_file") or die "Cannot write PID file $pid_file\n";
    print PIDF "$pid started at $date";
}
