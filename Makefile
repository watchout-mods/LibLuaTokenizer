LUA=lua5.1

all: test

install-dependencies:
	sudo luarocks install busted

test:
	busted

.PHONY: all test install-dependencies
