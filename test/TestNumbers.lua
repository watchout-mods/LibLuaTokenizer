local tok = require("LuaTokenizer")

function cb_onlytoken(token, ...)
	return token;
end

test("Numbers", function( ... )
	local expect = {"NUMBER"};
	assertArrayEquals(expect, tok:Tokenize([[0]], cb_onlytoken));
	assertArrayEquals(expect, tok:Tokenize([[1]], cb_onlytoken));
	assertArrayEquals(expect, tok:Tokenize([[99]], cb_onlytoken));
	assertArrayEquals(expect, tok:Tokenize([[1.2345678901234567890]], cb_onlytoken));
	assertArrayEquals(expect, tok:Tokenize([[1.234E567890]], cb_onlytoken));
	assertArrayEquals(expect, tok:Tokenize([[1.234e567890]], cb_onlytoken));
	assertArrayEquals(expect, tok:Tokenize([[0.1]], cb_onlytoken));
	assertArrayEquals(expect, tok:Tokenize([[.1]], cb_onlytoken));
end)

test("Hex numbers", function( ... )
	local expect = {"HEXNUM"};
	assertArrayEquals(expect, tok:Tokenize([[0x123AF]], cb_onlytoken));
end)

test("Negative numbers", function( ... )
	local expect = {"-", "NUMBER"};
	assertArrayEquals(expect, tok:Tokenize([[-123411231231231]], cb_onlytoken));
end)
