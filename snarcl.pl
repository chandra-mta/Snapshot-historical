#!/opt/local/bin/perl -w

# delete obsolete snapshot archive (snarc) files


#$snarcdir = '/proj/ascwww/AXAF/extra/science/cgi-gen/mta/Snap';
$snarcdir = '/data/mta4/www/Snapshot';
$snarcroot = "$snarcdir/snarc.";

while (<$snarcroot*>) {
    if (-M $_ > 3.0) { unlink $_; }
}

# also clean out wirless pages
$snarcdir = '/data/mta4/www/WL/Snap_dat';
$snarcroot = "$snarcdir/";

while (<$snarcroot*>) {
    if (-M $_ > 3.0) { unlink $_; }
}
