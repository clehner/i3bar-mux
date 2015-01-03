#!/bin/bash

config_file=~/.config/counter-status

read_status() {
	num=$(cat $config_file)
	(( num += 0 ));
}

save_status() {
	echo $num > $config_file
}

print_status() {
	echo '[{"name":"counter","full_text":"'$num'"}],'
}

echo '{"version":1, "click_events":true}'
echo '['

read_status
print_status

while read event; do
	if ! [[ "$event" =~ '"name":"counter"' ]]; then
		continue;
	fi
	if [[ "$event" =~ '"button":1' ]]; then
		(( num++ ))
	elif [[ "$event" =~ '"button":3' ]]; then
		(( num-- ))
	elif [[ "$event" =~ '"button":2' ]]; then
		(( num *= -1 ))
	fi
	save_status
	print_status
done

echo ']'

