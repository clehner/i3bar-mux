i3bar-mux
=========

**i3bar-mux** is a tool for multiplexing status commands into i3bar. It allows
you to combine multiple i3status commands into one output to i3bar.

## Features

- No package installation required. Depends only on Perl.
- UNIXy philosophy of individual commands for different status items.
- Agnostic to language the commands are implemented in.
- Supports click events.

## Usage

    i3bar-mux [commands]

or 

    i3bar-mux -c [config]

where commands is a list of commands, or config is a file with a list of
commands (and comments).

When run, i3bar-mux will execute each command it is given, which should be
long-running. It will combine the output streams of each command into an
[i3bar-format](http://i3wm.org/docs/i3bar-protocol.html) stream, and pass
through click events from i3bar to the commands as well, if they support it. The
output format of the commands is expected to be either i3bar format or a
plain-text line-by-line stream.

## Credits

Inspired by [py3status](https://github.com/ultrabug/py3status) and
[i3pystatus](https://github.com/enkore/i3pystatus).

Much thanks to the creators of the [i3](http://i3wm.org/) window manager and
[i3status](http://i3wm.org/i3status/).

## License

Copyright (c) 2013-2014 Charles Lehner

[MIT License](http://cel.mit-license.org/)
