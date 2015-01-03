#!/usr/bin/env perl
# vim:ts=4:sw=4:expandtab
#
# socket.pl
# Socket reader for i3bar, with auto reconnect
#
# Usage: ./socket.pl host port [timeout]

use strict;
use warnings;
use IO::Select;
use IO::Socket::INET;

if ($#ARGV < 1) {
    print STDERR "Usage: $0 hostname port [timeout]\n";
    exit 1;
}

my $host = $ARGV[0];
my $port = +$ARGV[1];
my $idle_timeout = +$ARGV[2] || 60;
my $connect_timeout = 10;

# Don't buffer output
$| = 1;

my $read_set = new IO::Select();
$read_set->add(\*STDIN);

my $socket;

my $timeout = $idle_timeout;

sub connect_sock {
    $socket = new IO::Socket::INET(
        PeerAddr => $host,
        PeerPort => $port,
        Proto    => 'tcp',
        Timeout  => $connect_timeout,
        Blocking => 0
    );
    if ($socket) {
        $read_set->add($socket);
        $timeout = $idle_timeout;
    } else {
        $timeout = $connect_timeout;
    }
}

sub got_line {
    my $line = shift;
    print $line . "\n";
}

connect_sock;

while (1) {
    my @readers = $read_set->can_read($timeout);
    if (scalar @readers == 0) {
        # timed out. reconnect
        if ($socket) {
            $socket->close();
            $read_set->remove($socket);
        }
        connect_sock;
    }

	foreach my $rh (@readers) {
        my $buf;
        if (sysread($rh, $buf, 128)) {
            got_line($_) for split("\n", $buf);

        } else {
            if ($rh == \*STDIN) {
                # stdin closed
                exit 0;

            } else {
                # socket closed. reconnect
                $read_set->remove($socket);
                connect_sock;
            }
        }
    }
}

