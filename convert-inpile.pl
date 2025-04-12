#!/usr/bin/perl

# Note: Since the original syslog timestamp has no year, we must manually add a year and a blank in front of each line
# to the inpile with whatever editor we have.

use strict;
use warnings;

# Read input from STDIN.
while (my $line = <>) {
    chomp $line;

    if ($line =~ /^(\d{4})\s([A-Za-z]{3})\s{1,2}(\d{1,2})\s+(\d{2}):(\d{2}):(\d{2})\s([ -])\s+([0-9\.]+)\s+([0-9\.]+)\s+(\d+)$/) {
        my ($year, $month, $day, $hour, $minute, $second, $score_sign, $score, $scantime, $size) = ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10);

        # Convert month abbreviation to month number (1 = January, 12 = December)
        my %month_map = (
            'Jan' => 1, 'Feb' => 2, 'Mar' => 3, 'Apr' => 4,
            'May' => 5, 'Jun' => 6, 'Jul' => 7, 'Aug' => 8,
            'Sep' => 9, 'Oct' => 10, 'Nov' => 11, 'Dec' => 12
        );

        # Convert month abbreviation to number (1-12)
        my $month_num = $month_map{$month};

	# Calculate correct score value
	if ( $score_sign eq '-' ) {
		$score = $score * -1;
	}

        # Create a DateTime object from the extracted values
        my $timestamp = sprintf("\"%04d-%02d-%02d-%02d.%02d.%02d.000000\";%d;%0.1f;%0.1f",
            $year, $month_num, $day, $hour, $minute, $second, $size, $score, $scantime);

        print "$timestamp\n";
    }
    else {
        printf("Invalid input: %s\n", $line);
    }
}
