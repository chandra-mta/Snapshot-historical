package TomUtil;
use POSIX;
use Text::ParseWords;
use Time::JulianDay;
use Time::DayOfYear;
use Time::Local;

@ISA = qw(Exporter);

@EXPORT = qw(hms2dec
	     dec2hms
	     fits_read_keys
	     read_param_file
	     time2date
	     date2time);

sub dec2hms {
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
    @arg = split;

    if (@arg == 2) {
	my $ra = shift;
	my $dec = shift;
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
	print "hms2dec: Error -- enter either 6 or 2 arguments\n";
    }
}


###################################################################################
sub fits_read_keys {
###################################################################################
    my @keys;
    my $file = shift;
    @keys = `fdump $file STDOUT - - prdata- prhead+ page-`;

    my $noquote = "[^']";
    my %keys = ();
    foreach (@keys) {
	if (/(\S+)\s*= '(${noquote}+)'/ or /(\S+)\s*= ([^\/]+)/) {   
	    my $key = $1;
	    my $keyval = $2;
	    $key =~ s/\s+$//;
	    $keyval =~ s/\s+$//;
	    $key =~ s/^\s+//;
	    $keyval =~ s/^\s+//;
	    $keys{$key} = $keyval;
	}
    }
    
    return %keys;
}

###################################################################################
sub read_param_file {
###################################################################################
    my $file = shift;
    my %param = ();
    open (PAR, $file) || die "Couldn't open parameter file $file\n";
    while (<PAR>) {
	@fields = quotewords(",", 0, $_);
	$param{$fields[0]} = $fields[3];
    }
    close PAR;

    return %param;
}



###################################################################################
sub time2date {
###################################################################################
# Date format:  1999:260:03:30:01.542
    my $time = shift;
    my $floor_time = floor($time);
    my $t1998 = @_ ? 0.0 : 883612800; # 2nd argument implies Unix time not CXC time
    ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime($floor_time+$t1998);

    return sprintf ("%04d:%03d:%02d:%02d:%06.3f",
		    $year+1900, $yday+1, $hour, $min, $sec + ($time-$floor_time));
}

##***************************************************************************
sub date2time {
##***************************************************************************
# Date format:  1999:260:03:30:01.542
    
    my $date = shift;
    my $t1998 = @_ ? 0.0 : 883612800; # 2nd argument implies Unix time not CXC time
    my ($sec, $min, $hr, $doy, $yr) = reverse split ":", $date;

    return ($doy*86400 + $hr*3600 + $min*60 + $sec) unless ($yr);

    my ($mon, $day) = ydoy2md($yr, $doy);

    return timegm($sec,$min,$hr,$day,$mon-1,$yr) - $t1998;
}
