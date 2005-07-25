#!/usr/bin/perl

#########################################################################################
#											#
#	update_cus_mail.perl: move an old cus email to archive and clean up a current	#
#			      directory							#
#											#
#	author: t. isobe (tisobe@cfa.harvard.edu)					#
#											#
#	last update: Jul 13, 2005							#
#											#
#########################################################################################

#
#--- get today's date
#

($usec, $umin, $uhour, $umday, $umon, $uyear, $uwday, $uyday, $uisdst)= localtime(time);

$year   = 1900   + $uyear;
$month  = $umon  + 1;

#
#--- change month from number to letters
#

mo_no_to_lett($month);

$cmo_up = $month_up;
$cmo_lo = $month_lo;
$cmo_fl = $month_fl;

#
#--- find out the last month
#

if($umon == 0){
	$lmonth = 12;
	$lyear = $year -1;
}else{
	$lmonth = $umon;
	$lyear  = $year;
}

mo_no_to_lett($lmonth);

$lmo_up = $month_up;
$lmo_lo = $month_lo;
$lmo_fl = $month_fl;
	
#
#--- check 2 months ago
#

$pmonth = $lmonth -1;
if($pmonth == 0){
	$pmonth = 12;
	$pyear  = $lyear -1;
}else{
	$pyear  = $lyear;
}

mo_no_to_lett($pmonth);
$pmo_up = $month_up;
$pmo_lo = $month_lo;
$pmo_fl = $month_fl;

#
#--- create a new directory for the last month's archive
#


$a_dir = '/data/mta4/www/CUS/MAIL/ARCHIVE/'."$lyear"."$lmo_up";
system("mkdir $a_dir");

$b_dir = '/arc/cus/mail_archive.'."$lmo_lo";

system("/usr/local/bin/hypermail -m $b_dir -d $a_dir -c /home/cus/HYPERMAIL/hypermail.config");

#
#--- clean up the last month's mail
#

system("rm /data/mta4/www/CUS/MAIL/*.html");
system("rm -r /data/mta4/www/CUS/MAIL/a*");

system("/usr/local/bin/hypermail -m /arc/cus/mail_archive -d /data/mta4/www/CUS/MAIL -c /home/cus/HYERMAIL/hypermail.config");

system("rm /data/mta4/www/CUS/MAIL/ARCHIVE/CURRENT/*.html");
system("rm -r /data/mta4/www/CUS/MAIL/ARCHIVE/CURRENT/a*");

system("/usr/local/bin/hypermail -m /arc/cus/mail_archive -d /data/mta4/www/CUS/MAIL/ARCHIVE/CURRENT -c /home/cus/HYPERMAIL/hypermail_fordtdig.config");

#
#--- add new entry to htdig.conf
#

system("mv /home/mta/DIG/htdig-3.1.4/conf/htdig.conf /home/mta/DIG/htdig-3.1.4/conf/htdig.conf~");
open(FH, "/home/mta/DIG/htdig-3.1.4/conf/htdig.conf~");

open(OUT, ">/home/mta/DIG/htdig-3.1.4/conf/htdig.conf");

$new_line = 'http://hea-www.harvard.edu/~mta/cus/ARCHIVE/'."$year$lmo_up";
while(<FH>){
        chomp $_;
        if($_ =~ /start_url/ && $_ !~ /\#/){
                @atemp = split(/start_url:       /, $_);
                $line = 'start_url:       '." $new_line"."$atemp[1]";
                print OUT "$line\n";
        }else{
                print OUT "$_\n";
        }
}
close(OUT);
close(FH);

#
#--- add new lines to the html page
#

system("mv /data/mta4/www/CUS/MAIL/ARCHIVE/index.html /data/mta4/www/CUS/MAIL/ARCHIVE/index.html~");
open(FH, "/data/mta4/www/CUS/MAIL/ARCHIVE/index.html~");

@save = ();

$current = '<LI><A HREF="../."><STRONG> Current Month: '."$cmo_fl $year".'</STRONG></A>';
$test    = '<LI><A HREF="./'."$pyear$pmo_up".'"><STRONG> '."$pmo_fl $pyear".'</STRONG></A>';
$line    = '<LI><A HREF="./'."$lyear$lmo_up".'"><STRONG> '."$lmo_fl $lyear".'</STRONG></A>';

while(<FH>){
	chomp $_;
	if($_ =~ /$test/){
		push(@save, $_);
		if($lmonth != 1){
			push(@save, $line);
		}
	}elsif($_ =~ /Current Month:/){
		push(@save, $current);
		if($lmonth == 1){
			$tline = '<hr>';
			$new1 = '<h3> '."$year".'<h3>';
			push(@save, $tline);
			push(@save, $new1);
			push(@save, $line);
		}
	}else{
		push(@save, $_);
	}
}
close(FH);

open(OUT, "> /data/mta4/www/CUS/MAIL/ARCHIVE/index.html");
foreach $ent (@save){
	print OUT "$ent\n";
}
close(OUT);
	

##################################################################
### convert month in number to month name in letters        ######
##################################################################

sub mo_no_to_lett {
	($no_month) = @_;
	if($no_month == 1){
		$month_up = 'JAN';
		$month_lo = 'Jan';
		$month_fl = 'January';
	}elsif($no_month == 2){
		$month_up = 'FEB';
		$month_lo = 'Feb';
		$month_fl = 'February';
	}elsif($no_month == 3){
		$month_up = 'MAR';
		$month_lo = 'Mar';
		$month_fl = 'March';
	}elsif($no_month == 4){
		$month_up = 'APR';
		$month_lo = 'Apr';
		$month_fl = 'April';
	}elsif($no_month == 5){
		$month_up = 'MAY';
		$month_lo = 'May';
		$month_fl = 'May';
	}elsif($no_month == 6){
		$month_up = 'JUN';
		$month_lo = 'Jun';
		$month_fl = 'June';
	}elsif($no_month == 7){
		$month_up = 'JUL';
		$month_lo = 'Jul';
		$month_fl = 'July';
	}elsif($no_month == 8){
		$month_up = 'AUG';
		$month_lo = 'Aug';
		$month_fl = 'August';
	}elsif($no_month == 9){
		$month_up = 'SEP';
		$month_lo = 'Sep';
		$month_fl = 'September';
	}elsif($no_month == 10){
		$month_up = 'OCT';
		$month_lo = 'Oct';
		$month_fl = 'October';
	}elsif($no_month == 11){
		$month_up = 'NOV';
		$month_lo = 'Nov';
		$month_fl = 'November';
	}elsif($no_month == 12){
		$month_up = 'DEC';
		$month_lo = 'Dec';
		$month_fl = 'December';
	}
}
