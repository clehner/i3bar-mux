#!/usr/bin/env perl

# Yahoo Weather i3status
# based on weather_yahoo.py by ultrabug

use strict;
use HTTP::Request;
use LWP::UserAgent;

my $city_code = $ARGV[0] // 'USNY1232';
my $days = +$ARGV[1] // 4;
my $interval = ($ARGV[2] // 30) * 60;

my $query = 'select item from weather.forecast where location="' . $city_code . '"';
my $request = HTTP::Request->new(GET =>
	'http://query.yahooapis.com/v1/public/yql?q=' . $query . '&format=json');

#my @icons = qw(☀ ☁ ☂ ☃ ☔ ⛈ ⛇ ?⛄ );
my @icons;
$icons[$_] = '☀' for qw(28 32 33 34 36); # sun
$icons[$_] = '☁' for qw(19 20 21 22 23 24 25 26 27 28); # cloud
$icons[$_] = '⛅' for qw(29 30 30 44 29); # cloud cover
$icons[$_] = '☂' for qw(5 6 9 11 12); # rain
$icons[$_] = '☔' for qw(37 38 39 40 45 47); # more rain
$icons[$_] = '⛈' for qw(0 1 2 3 4 ); # storm
$icons[$_] = '❄' for qw(7 8 10 13 14 15 16 17 18 35 41 42 43 46); # snow ☃⛇

# Don't buffer output
$| = 1;

sub get_icon {
	# Return an unicode icon based on the forecast code and text
	# See: http://developer.yahoo.com/weather/#codes
	my $code = shift;
	my $text = lc shift;

	# icon identify by code
	return $icons[$code] // '?';
}

sub forecast {
	my $ua = LWP::UserAgent->new;
	my $response = $ua->request($request);
	if (!$response->is_success) {
		return 'fail';
	}

	# http://query.yahooapis.com/v1/public/yql?q=select%20item%20from%20weather.forecast%20where%20location=%22USNY1232%22&format=json

	my $json = $response->decoded_content;
	my ($temp, $forecast) = $json =~ /"temp":"(.*?)".*"forecast":(.*)/g;

	my $line = "$temp°";
	my @codes = $forecast =~ /"code":"(.*?)"/g;
	my @texts = $forecast =~ /"text":"(.*?)"/g;

	# reset today
	($texts[0]) = $json =~ /"text":"(.*?)"/;
	($codes[0]) = $json =~ /"code":"(.*?)"/;

	# return current temp + current today + 3 days forecast
	for my $i (0 .. $days-1) {
		my $code = $codes[$i];
		my $text = $texts[$i];
		#print 'code: ' . $code . ' text: ' . $text . "\n";
		$line .= ' ' . get_icon($code, $text);
	}
	#print "[{\"name\":\"weather\",\"full_text\":\"$line\"}],\n";
	print $line . "\n";
	alarm $interval;
}

$SIG{ALRM} = \&forecast;

forecast;
while (<STDIN>) {}
