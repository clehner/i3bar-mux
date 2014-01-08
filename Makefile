PREFIX := /usr/local
BINDIR := ${PREFIX}/bin
LIBDIR := ${PREFIX}/lib/i3bar-mux

bin = i3bar-mux
commands = bagua.pl calendar.pl counter.sh pomodoro.pl socket.pl weather.pl

all:

install:
	mkdir -p ${BINDIR} ${LIBDIR}
	install -m 0755 ${bin} ${BINDIR}
	install -m 0755 -t ${LIBDIR} ${commands}

uninstall:
	rm -f ${BINDIR}/${bin}
	for prog in ${commands}; do \
		rm -f ${LIBDIR}/$$prog; \
	done
	@rmdir ${BINDIR} ${LIBDIR}

.PHONY: install uninstall
