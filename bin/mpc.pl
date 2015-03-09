#!/usr/bin/env perl
# mpc.pl
# i3bar status item for MPD status using mpc(1)

use strict;
use warnings;
use IO::Select;

my $read_set = new IO::Select();
$read_set->add(\*STDIN);

my $status_name = "mpc";
my %status_colors = (
	playing => '#00FF00',
	paused => '#00FFFF',
	unknown => '#FFFF00'
);

my $track;
my $text;
my $status;
my $color;
my $show_time = 0;
my $timeout;

sub read_status {
	if (scalar @_ < 3 or $_[1] =~ /^ERROR/) {
		$status = 'unknown';
		$track = '♫';
		$color = $status_colors{'unknown'};
		return;
	}

	my $time = '';
	if ($_[1] =~ /^\[([^\]]*)\]\s*\S*\s*(\S*)/) {
		$status = $1;
		$time = $2;
	} else {
		$status = 'unknown';
	}
	$track = $_[0];
	$track =~ s|/|//|g;
	$track =~ s|"|\"|g;
	$track =~ s|\s*$||;
	$color = $status_colors{$status} // $status_colors{'unknown'};

	$text = $track;
	if ($show_time) {
		use utf8;
		$show_time = 0;
		$timeout = 2;
		my $time_str = "…[$time]";
		$text = substr($text, 0, -length($time_str)) . $time_str;
	} else {
		$timeout = undef;
	}
}

sub print_status {
	if (!$status) {
		read_status(`mpc status`);
	}
	print "[{\"name\":\"$status_name\",\"color\":\"$color\",\"full_text\":\"$text\"}],\n";
}

sub clicked_button {
	$show_time = 1;
	if ($1 == 1) { # left click
		read_status(`mpc toggle`);
	} elsif ($1 == 2) { # right click
		read_status(`mpc next`);
	} elsif ($1 == 3) { # middle click
		read_status(`mpc prev`);
	} elsif ($1 == 4) { # scroll up
		read_status(`mpc seek -1`);
	} elsif ($1 == 5) { # scroll down
		read_status(`mpc seek +1`);
	}
	$show_time = 1;
}

# Don't buffer output
$| = 1;

my $idle_pid = open IDLE, 'mpc idleloop|'
	or die "open mpc idleloop: $!";
$read_set->add(\*IDLE);

print "{\"version\":1, \"click_events\":true}\n";
print "[\n";

print_status;

while ($read_set->count gt 0) {
	$status = "";
	foreach my $rh ($read_set->can_read($timeout)) {
		$_ = <$rh>;
		if ($rh == \*STDIN) {
			if ($_) {
				if (/"name":"$status_name"/ and /"button":([0-9])/) {
					clicked_button($1);
				}
			} else {
				# stdin closed
				kill TERM => $idle_pid;
				exit 0;
			}
		} elsif ($rh == \*IDLE) {
			if (!$_) {
				# mpc exited
				exit 1;
			}
		}
	}
	print_status;
}
