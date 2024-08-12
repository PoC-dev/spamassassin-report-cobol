#!/usr/bin/perl -w

use strict;
use warnings;

my ($line, $sdate, $ssign, $sscore, $stime, $ssize, $ts1, $ts2, $nscore);

#--------------------------------------------------------------------------------------------------------------

format =
@<<<<<<<<<<<<<<<@<@####.##@####.#@###########
$sdate, $ssign, $sscore, $stime, $ssize
.

format STDOUT_TOP =
//IMPLOG  JOB  USER=HERC04,PASSWORD=PASS4U,MSGCLASS=A,MSGLEVEL=(0,0)
//IMPORT EXEC  PGM=IEBGENER
//SYSPRINT DD  SYSOUT=*
//SYSIN    DD  DUMMY
//SYSUT2   DD  DSN=HERC04.SSTATS.INPILE,DISP=MOD
//SYSUT1   DD  *
.

# Lines per Page for the Report Writer.
$==500000000;

# Read from stdin, format one line and spit it out again.
foreach $line ( <STDIN> ) {
	chomp($line);
	if ( $line =~ /^([[:alpha:]]{3} ([ ][[:digit:]]|[[:digit:]]{2}) [[:digit:]:]+) leela spamd\[[[:digit:]]+\]: spamd: (identified spam|clean message) \(([-]?[[:digit:].]+)\/[[:digit:].]+\) for spamassassin:[[:digit:]]+ in ([[:digit:].]+) seconds, ([[:digit:]]+) bytes\.$/ ) {
		if (defined($1) && defined($4) && defined($5) && defined($6) ) {
			$sdate = $1;
			if ( $4 ge 0 ) {
				$sscore = $4;
				$ssign = ' ';
			} elsif ( $4 lt 0 ) {
				$sscore = abs($4);
				$ssign = '-';
			}
			$nscore = $4;
			$stime = $5;
			$ssize = $6;

			if ( $sscore == '-0.00' ) {
				$sscore = 0.00;
			}

			write();
		} else {
			printf(<STDERR>, "Not all variables found for '%s'\n", $line);
		}

		undef($sdate);
		undef($sscore);
		undef($nscore);
		undef($stime);
		undef($ssize);
	}
}

printf("/*\n//\n");

#--------------------------------------------------------------------------------------------------------------
# vim:tabstop=4:shiftwidth=4:autoindent
# -EOF-
