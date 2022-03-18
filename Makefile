prefix ?= /usr/local
bindir = $(prefix)/bin

build:
	swift build -c release --disable-sandbox

install: build
	install -d "$(bindir)"
	install ".build/release/findsimulator" "$(bindir)"

uninstall:
	rm -rf "$(bindir)/findsimulator"

clean:
	rm -rf .build

.PHONY: build install uninstall clean
