#!/usr/bin/env perl

use strict;

# Don't buffer output
$| = 1;

my @bagua=qw(☰ ☱ ☲ ☳ ☴ ☵ ☶ ☷);
my $bagua_n = 8;
my $bagua_i = 0;

my $config_file = $ENV{HOME} . '/.config/bagua-status';

sub read_status {
	open FILE, '<', $config_file;
	$bagua_i = <FILE>;
	close FILE;
}

sub save_status {
	open FILE, '>', $config_file;
	print FILE $bagua_i;
	close FILE;
}

sub print_status {
	my $trigram = $bagua[$bagua_i];
	print "[{\"name\":\"bagua\",\"full_text\":\"$trigram\"}],\n";
}

sub click {
	my $button = shift;
	if ($button == 1) {
		# left click
		$bagua_i++;
	} elsif ($button == 2) {
		# middle click
		$bagua_i = $bagua_n - 1- $bagua_i;
	} elsif ($button == 3) {
		# right click
		$bagua_i--;
	}
	$bagua_i %= $bagua_n;
	print_status;
	save_status;

};

print "{\"version\":1, \"click_events\":true}\n";
print "[\n";

read_status;
print_status;

while (<>) {
	if (/"name":"bagua"/ and /"button":([0-9])/) {
		my $button = $1;
		click $button;
	}
}
