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

my $idle_pid;
my $track_num;
my $text = "";
my $status;
my $color;
my $show_time = 0;

sub read_status {
	if (scalar @_ < 3 or $_[1] =~ /^ERROR/) {
		$status = 'unknown';
		$track_num = '♫';
		$color = $status_colors{'unknown'};
		return;
	}

	my $time = '';
	my $duration = '';
	if ($_[1] =~ /^\[([^\]]*)\]\s*(\S*)\s*(\S*)\/(\S*)/) {
		$status = $1;
		$track_num = $2;
		$time = $3;
		$duration = $4;
	} else {
		$status = 'unknown';
	}
	$color = $status_colors{$status} // $status_colors{'unknown'};

	$text = ''.$track_num;
	if ($show_time) {
		$text .= ' <span foreground=\"#33ff99\">'.$time.'</span>';
	}
}

sub print_status {
	if (!$status) {
		read_status(`mpc status`);
	}
	print "[{\"name\":\"$status_name\",\"color\":\"$color\",\"full_text\":\"$text\"}],\n";
}

sub restart {
	kill TERM => $idle_pid;
	exec $0, '--continue';
}

sub quit_all {
	kill TERM => $idle_pid;
	exit 0;
}

sub clicked_button {
	if ($1 == 1) { # left click
		read_status(`mpc toggle`);
	} elsif ($1 == 2) { # middle click
		restart;
		#read_status(`mpc prev`);
	} elsif ($1 == 3) { # right click
		read_status(`mpc next`);
	} elsif ($1 == 4) { # scroll up
		read_status(`mpc seek -1`);
	} elsif ($1 == 5) { # scroll down
		read_status(`mpc seek +1`);
	}
}

# Don't buffer output
$| = 1;

$idle_pid = open IDLE, 'mpc idleloop|'
	or die "open mpc idleloop: $!";
$read_set->add(\*IDLE);

binmode(STDOUT, ":utf8");

$SIG{TERM} = \&quit_all;
$SIG{HUP} = \&restart;

if (scalar @ARGV < 1 || $ARGV[0] ne '--continue') {
	print "{\"version\":1, \"click_events\":true}\n";
	print "[\n";
}

print_status;

outer: while ($read_set->count gt 0) {
	my $timeout = ($status eq "playing" and $show_time) ? 1 : 3600;
	$status = "";
	foreach my $rh ($read_set->can_read($timeout)) {
		defined($_ = <$rh>) or quit_all;
		if ($rh == \*STDIN) {
			if (/"name":"$status_name"/ and /"button":([0-9])/) {
				clicked_button($1);
				next outer;
			}
		}
	}
	print_status;
}
