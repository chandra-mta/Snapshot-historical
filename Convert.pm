package Convert;

use POSIX;
use Text::ParseWords;
use Time::JulianDay;
use Time::DayOfYear;
use Time::Local;
use Carp;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

require Exporter;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT_OK = qw(hms2dec
		dec2hms
		time2date
		date2time
		radec_dist
	       );

%EXPORT_TAGS = (all => \@EXPORT_OK);

$VERSION = '0.01';

1;

# Preloaded methods go here.

##***************************************************************************
sub dec2hms {
##***************************************************************************
    # Converts from decimal to sexigesimal (HMS).  This is just a notational
    # convenience, since hms2dec actually goes both ways
    return (hms2dec (@_));
}

##***************************************************************************
sub hms2dec {
##***************************************************************************
    # Converts between sexigesimal (HMS) and decimal RA and Dec.  The
    # direction of conversion is given by the number and form of inputs
    # Returns two-element array of (RA, Dec) in either case.

    $_ = join ' ', @_;
    s/[,:dhms]/ /g;
    my @arg = split;
    my ($ra, $dec);

    if (@arg == 2) {
	($ra, $dec) = @arg;
	my ($rah, $ram, $ras);
	my ($dec_sign, $decd, $decm, $decs);
	my ($ra_hms, $dec_hms);

	$ra += 360.0 if ($ra < 0);
	$ra /= 15.;
	$rah = floor($ra);
	$ram = floor(($ra - $rah) * 60.);
	$ras = ($ra - $rah - $ram / 60.) * 60. * 60.;
	
	$dec_sign = ($dec < 0);
	$dec = abs($dec);
	$decd = floor($dec);
	$decm = floor(($dec - $decd ) * 60.);
	$decs = ($dec - $decd - $decm / 60) * 60. * 60.;
	
	$ra_hms = sprintf "%d:%02d:%06.3f", $rah, $ram, $ras;
	$dec_hms = sprintf "%s%d:%02d:%05.2f", $dec_sign ? '-' : '+', $decd, $decm, $decs;

	return ($ra_hms,$dec_hms);
    } elsif (@arg == 6) {
	my ($rah, $ram, $ras, $decd, $decm, $decs) = @arg;
	$ra = 15.0*($rah + $ram/60. + $ras/3600.);
	$dec = abs($decd) + $decm/60. + $decs/3600.;
	$dec = -$dec if ($decd < 0.0);
	return (sprintf("%12.7f",$ra), sprintf("%12.6f", $dec));
    } else {
	carp "hms2dec: ERROR -- enter either 6 or 2 arguments\n";
    }
}

###################################################################################
sub time2date {
###################################################################################
# Date format:  1999:260:03:30:01.542
    my $time = shift;
    my $t1998 = @_ ? 0.0 : 883612736.816; # 2nd argument implies Unix time not CXC time
    my $floor_time = floor($time+$t1998);
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime($floor_time);

    return sprintf ("%04d:%03d:%02d:%02d:%06.3f",
		    $year+1900, $yday+1, $hour, $min, $sec + ($time+$t1998-$floor_time));
}

##***************************************************************************
sub date2time {
##***************************************************************************
# Date format:  1999:260:03:30:01.542
# 956245305.5 = eng_decom (unix) time at VCDU = 4324480 around 2000:111:15:41:46 (2000-04-20T15:42:50)
# CXC Time from CCDM file is 72632569.96

    my $date = shift;
    my $t1998 = @_ ? 0.0 : 956245305.5- 72632569.96 + 1.276; # 2nd argument implies Unix time not CXC time
    my ($sec, $min, $hr, $doy, $yr) = reverse split ":", $date;

    return ($doy*86400 + $hr*3600 + $min*60 + $sec) unless ($yr);

    my ($mon, $day) = ydoy2md($yr, $doy);

    $sec = 59 if ($sec > 59);
    return timegm($sec,$min,$hr,$day,$mon-1,$yr) - $t1998;
}

##**********************************************************************
sub radec_dist {
##**********************************************************************
    my ($a1, $d1, $a2, $d2) = @_;
    my $d2r = 3.14159265358979/180.;

    return(0.0) if ($a1==$a2 && $d1==$d2);

    return acos( cos($d1*$d2r)*cos($d2*$d2r) * cos(($a1-$a2)*$d2r) +
              sin($d1*$d2r)*sin($d2*$d2r)) / $d2r;
}

# Autoload methods go after =cut, and are processed by the autosplit program.

__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Ska::Convert - Various conversions

=head1 SYNOPSIS

  use Ska::Convert;
  blah blah blah

=head1 DESCRIPTION

=head1 AUTHOR

Tom Aldcroft

=head1 SEE ALSO

perl(1).

=cut

