#!/opt/local/bin/perl

my $fileroot="/home/mta/Snap";
my @files=qw(.scs107alert);

my $grep="/usr/xpg4/bin/grep";

foreach $file (@files) {
  $alert=$fileroot."/".$file;
  if (-s $alert) {
    if (-M $alert < 0.01 && -M $alert < 1.0) {
      if (! `$grep -f $alert /var/mail/mta`) {
        `date`;
        s/\s+/_/g;
        `mv $alert $alert.$_`;
      }
    }
  }
}
