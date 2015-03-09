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
my $status;
my $color;

sub read_status {
	if ($_[1] =~ /^ERROR/) {
		$status = 'unknown';
		$track = '';
		$color = $status_colors{'unknown'};
		return;
	}

	if ($_[1] =~ /^\[([^\]]*)\]/) {
		$status = $1;
	} else {
		$status = 'unknown';
	}
	$track = $_[0];
	$track =~ s|/|//|g;
	$track =~ s|"|\"|g;
	$track =~ s|\s*$||;
	$color = $status_colors{$status} // $status_colors{'unknown'};
}

sub print_status {
	if (!$status) {
		read_status(`mpc status`);
	}
	print "[{\"name\":\"$status_name\",\"color\":\"$color\",\"full_text\":\"$track\"}],\n";
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
	foreach my $rh ($read_set->can_read) {
		$_ = <$rh>;
		if ($rh == \*STDIN) {
			if ($_) {
				if (/"name":"$status_name"/ and /"button":([0-9])/) {
					my $button = $1;
					if ($button == 1) {
						read_status(`mpc toggle --wait`);
					} elsif ($button == 2) {
						read_status(`mpc next`);
					} elsif ($button == 3) {
						read_status(`mpc prev`);
					} elsif ($button == 4) {
						read_status(`mpc seek -1`);
					} elsif ($button == 5) {
						read_status(`mpc seek +1`);
					}
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
