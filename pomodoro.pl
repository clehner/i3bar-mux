#!/usr/bin/env perl
#
# Pomodoro i3status
#
# based on:
# https://github.com/ultrabug/py3status/blob/master/examples/pomodoro.py

use strict;
use POSIX qw(strftime);

my $name = 'pomodoro';
my $title = 'Pomodoro';

my $max_breaks = 4;
my $timer_pomodoro = 25 * 60;
my $timer_break = 5 * 60;
my $timer_long_break = 15 * 60;

my $color_good = '#00FF00';
my $color_degraded = '#0000FF';
my $color_bad = '#FF0000';

my $interval = 1;
my $timer;
my $prefix;
my $status;
my $breaks;
my $alert = 0;
my $run = 0;

# Don't buffer output
$| = 1;

sub print_status {
	my $time = strftime("%Y-%m-%d %H:%M:%S", localtime(time()));
	my $text = "$prefix ($timer)";
	my $urgent = '';
	if ($alert) {
		$urgent = '"urgent":true,';
		$alert = 0;
	}
	my $color = ($status eq 'start') ? $color_good :
		($status eq 'pause') ? $color_degraded : $color_bad;
		
	printf '[{"name":"%s",%s"color":"%s","full_text":"%s"}]'."\n",
		$name, $urgent, $color, $text;
}

sub stop {
	$prefix = $title;
	$status = 'stop';
	$timer = $timer_pomodoro;
	$breaks = 1;
}

sub start {
	$status = 'start';
	$prefix = $title;
	$timer = $timer_pomodoro;
}

sub pause {
	$status = 'pause';
	$prefix = 'Break #' . $breaks;
	if ($breaks > $max_breaks) {
		$timer = $timer_long_break;
		$breaks = 1;
	} else {
		$breaks++;
		$timer = $timer_break;
	}
}

sub on_click {
	my $button = shift;
	if ($button == 1) {
		if ($status eq 'stop') {
			$status = 'start';
		}
		$run = 1;

	} elsif ($button == 2) {
		stop;
		$run = 0;

	} elsif ($button == 3) {
		pause;
		$run = 0;
	}
}

sub nagbar {
	my $level = shift // 'warning';
	my $msg = "$prefix time is up!";
	#my @args = ('i3-nagbar', '-m', $msg, '-t', $level);
	system("i3-nagbar -m \"$msg\" -t \"$level\" >/dev/null 2>/dev/null")
}

sub decrement {
	if (--$timer < 0) {
		$alert = 1;
		$run = 0;
		nagbar;
		if ($status eq 'start') {
			pause;
		} elsif ($status eq 'pause') {
			start;
		}
	}
}

$SIG{ALRM} = sub {
	decrement if $run;
	print_status;
	alarm $interval;
};
alarm $interval;

print "{\"version\":1, \"click_events\":true}\n";
print "[\n";

stop;

print_status;

while (<>) {
	if (/"name":"$name"/ and /"button":([0-9])/) {
		on_click $1;
		print_status;
	}
}
