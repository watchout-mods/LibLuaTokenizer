LUA=lua

all: test

test:
	${LUA} test/Helper.lua test/Test*.lua

.PHONY: all test
