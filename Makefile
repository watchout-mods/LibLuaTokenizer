LUA=lua5.1

all: test

install-dependencies:
	sudo luarocks install busted

test:
	busted --exclude-tags=ignore

test-only:
	busted -t only

.PHONY: all test test-only install-dependencies
