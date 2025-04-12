#!/usr/bin/perl -w

# This is to be manually incremented on each "publish".
my $versionstring = '2025-04-12.00';

# ----------------------------------------------------------------------------------------------------------------------------------

use strict;
no strict "subs"; # For allowing symbolic names for syslog priorities.
use warnings;
use DBI;
use Sys::Syslog;

# ----------------------------------------------------------------------------------------------------------------------------------

# How to access the databases
my $odbc_dsn  = "DBI:ODBC:Driver={iSeries Access ODBC Driver};System=myas400;DBQ=SPAMASSASS;CMT=1";
my $odbc_user = "myassauser";
my $odbc_pass = "vryscrtpss";

# General vars.
my ( $adjusted_year, $current_day, $current_month, $current_year, $day, $dbh, $hour, $line, $minute, $month, $month_num, $sdate,
    $second, $sscore, $ssize, $stime, $syslog_ts, $time_dtf, $timestamp
);

# ----------------------------------------------------------------------------------------------------------------------------------

openlog("sa-parse-syslog", "pid", "user");

$dbh = DBI->connect($odbc_dsn, $odbc_user, $odbc_pass, {PrintError => 0, LongTruncOk => 1});
if ( ! defined($dbh) ) {
    syslog(LOG_ERR, "Init: connection to database failed: %s", $dbh->errstr);
    die;
}


# Prepare reusable SQL statements.
my $sth_insert_record = $dbh->prepare("INSERT INTO statspf (stamp, score, scantime, size) VALUES (?, ?, ?, ?)");
if (defined($dbh->errstr)) {
    syslog(LOG_ERR, "SQL preparation error: %s", $dbh->errstr);
    die;
}


#-----------------------------------------------------------------------------------------------------------------------------------

# Read from stdin, format one line and spit it out again.
foreach $line ( <STDIN> ) {
	chomp($line);
	if ( $line =~ /^([[:alpha:]]{3} ([ ][[:digit:]]|[[:digit:]]{2}) [[:digit:]:]+) leela spamd\[[[:digit:]]+\]: spamd: (identified spam|clean message) \(([-]?[[:digit:].]+)\/[[:digit:].]+\) for spamassassin:[[:digit:]]+ in ([[:digit:].]+) seconds, ([[:digit:]]+) bytes\.$/ ) {
		if (defined($1) && defined($4) && defined($5) && defined($6) ) {
            $syslog_ts = $1;
            $sscore = $4;
			$stime = $5;
			$ssize = $6;


            # The next part is required to estimate year's turn and add the proper year to complement the timestamp to be complete.
            # Suggestion by ChatGPT.
            $syslog_ts =~ /^([A-Za-z]{3})\s+(\d{1,2})\s+(\d{2}):(\d{2}):(\d{2})/;
            ($month, $day, $hour, $minute, $second) = ($1, $2, $3, $4, $5);

            # Convert month abbreviation to month number.
            my %month_map = (
                'Jan' => 1, 'Feb' => 2, 'Mar' => 3, 'Apr' => 4,
                'May' => 5, 'Jun' => 6, 'Jul' => 7, 'Aug' => 8,
                'Sep' => 9, 'Oct' => 10, 'Nov' => 11, 'Dec' => 12
            );
            $month_num = $month_map{$month};

            # Get the current date to help calculate year change (if any).
            $current_year = (localtime)[5] + 1900;
            ($current_month, $current_day) = (localtime)[4, 3];
            $current_month += 1;  # Adjust because localtime returns months 0-11.
            $adjusted_year = $current_year;
            # If the given date is earlier in the year than the current date, consider it last year.
            if ($month_num < $current_month || ($month_num == $current_month && $day < $current_day)) {
                $adjusted_year--;
            }
            # Create a DB2 timestamp from the extracted values.
            $timestamp = sprintf("%04d-%02d-%02d-%02d.%02d.%02d.000000",
                $adjusted_year, $month_num, $day, $hour, $minute, $second);
                

            # Debug: SQL
            #printf("INSERT INTO statspf (stamp, score, scantime, size) VALUES (%s, %0.1f, %0.1f, %d)\n",
            #    $timestamp, $sscore, $stime, $ssize);

			$sth_insert_record->execute($timestamp, $sscore, $stime, $ssize);
			if (defined($dbh->errstr)) {
                syslog(LOG_ERR, "Host loop: SQL execution error: %s", $dbh->errstr);
                $dbh->do("rollback");
                die;
			}
		} else {
            syslog(LOG_ERR, "Not all variables found for '%s'", $line);
		}
	}
}
$dbh->do("commit");

#-----------------------------------------------------------------------------------------------------------------------------------

# Cleanup is handled by the END block implicitly.
END {
    if ( $sth_insert_record ) {
        $sth_insert_record->finish;
    }
    if ( $dbh ) {
        $dbh->disconnect;
    }

    closelog;
}

#-----------------------------------------------------------------------------------------------------------------------------------
# vim: tabstop=4 shiftwidth=4 autoindent colorcolumn=133 expandtab textwidth=132
# -EOF-
