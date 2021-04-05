local tok = require("LuaTokenizer")

function cb_onlytoken(token, ...)
	return token;
end

function cb_onlychar(token, char, ...)
	return char;
end

function cb_tokenchar(str)
	return function(token, char, ln1, ln2, pos1, pos2, ...)
		if token ~= char and token ~= "NEWLINE" then
			return ("%s [%s] {%s}"):format(token, char, str:sub(pos1, pos2));
		else
			return token;
		end
	end
end

test("", function(...)
	local str = [[local foo;]];
	local expect = {"KEYWORD", "WHITESPACE", "ID", ";"};
	local actual =  tok:Tokenize(str, cb_onlytoken);
	assertArrayEquals(expect, actual);
end)

test("", function(...)
	local str = [[local function(a, b, c)
		return a * b + c;
	end]];
	local expect = {
		"KEYWORD", "WHITESPACE", "KEYWORD", "(", "ID", ",", "WHITESPACE", "ID", ",", "WHITESPACE",
		"ID", ")", "NEWLINE", "WHITESPACE", "KEYWORD", "WHITESPACE", "ID", "WHITESPACE", "*",
		"WHITESPACE", "ID", "WHITESPACE", "+", "WHITESPACE", "ID", ";", "NEWLINE", "WHITESPACE",
		"KEYWORD"
	};
	local actual = tok:Tokenize(str, cb_onlytoken);
	-- inspect(tok:Tokenize(str, cb_tokenchar(str)));
	assertArrayEquals(expect, actual);
end)

test("", function(...)
	local expect = {"KEYWORD", "WHITESPACE", "ID", "=", "STRING", ";"};
	assertArrayEquals(expect, tok:Tokenize([=[local foo="bar";]=], cb_onlytoken));
end)

test("", function(...)
	local str = [=[local foo=[[bar]];]=];
	local expect = {"KEYWORD", "WHITESPACE", "ID", "=", "STRING", ";"};
	assertArrayEquals(expect, tok:Tokenize(str, cb_onlytoken));
	assertArrayEquals(expect, tok:Tokenize([=[local foo=[[bar]];]=], cb_onlytoken));
	assertArrayEquals(expect, tok:Tokenize([[local foo=[=[bar]=];]], cb_onlytoken));
	assertArrayEquals(expect, tok:Tokenize([[local foo=[==[bar]==];]], cb_onlytoken));
	assertArrayEquals(expect, tok:Tokenize([[local foo=[===[bar]===];]], cb_onlytoken));
end)

test("", function(...)
	local str = [[local foo=([=[
]=]);]];
	local expect = {"KEYWORD", "WHITESPACE", "ID", "=", "(", "STRING", ")", ";"};
	assertArrayEquals(expect, tok:Tokenize(str, cb_onlytoken));
end)
