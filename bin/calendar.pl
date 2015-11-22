#!/usr/bin/env perl
#
# calendar.pl
# Simple clickable i3status calendar
#
# Usage: ./calendar.pl [interval]

use strict;
use POSIX qw(strftime);

my $interval = +$ARGV[0] || 1;

# Don't buffer output
$| = 1;

sub print_date {
	my $time = strftime("%a %m-%d %H:%M:%S", localtime(time()));
	print "[{\"name\":\"calendar\",\"full_text\":\"$time\"}],\n";
	alarm $interval;
}

my $cal_pid;

sub toggle_cal {
	if ($cal_pid) {
		kill 'TERM', $cal_pid;
		$cal_pid = 0;
	} else {
		$cal_pid = open(CAL, "gsimplecal|");
	}
}

sub next_month {
	if ($cal_pid) {
		open(NEXT, "gsimplecal next_month|");
	}
}

sub prev_month {
	if ($cal_pid) {
		open(PREV, "gsimplecal prev_month|");
	}
}

$SIG{ALRM} = \&print_date;

$SIG{CLD} = sub {
	if ($cal_pid == waitpid(-1, 0)) {
		$cal_pid = 0;
	}
};

print "{\"version\":1, \"click_events\":true}\n";
print "[\n";

print_date;

# get back on schedule
alarm($interval - (time % $interval));

while (<STDIN>) {
	if (/"name":"calendar"/ and /"button":([0-9])/) {
		my $button = $1;
		if ($button == 1) {
			toggle_cal;
		} elsif ($button == 2 || $button == 4) {
			prev_month;
		} elsif ($button == 3 || $button == 5) {
			next_month;
		}
	}
}
