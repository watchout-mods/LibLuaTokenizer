describe("Tokenizer", function()
	local tok = require("LuaTokenizer");
	local cb = require("spec/Callbacks");

	it("parses a simple string block on one line", function()
		local str = "[[bar]]";
		local expect = {{"STRING", "[[bar]]"}};
		assert.are.same(expect, tok:Tokenize(str, cb.tokenchar));
	end)

	it("parses a simple string block on one line", function()
		local str = "[[bar]];";
		local expect = {{"STRING", "[[bar]]"}, {";", ";"}};
		assert.are.same(expect, tok:Tokenize(str, cb.tokenchar));
	end)

	it("parses a simple string assignment block on one line", function()
		local str = [=[local foo=[[bar]]]=];
		local expect = {"KEYWORD", "WHITESPACE", "ID", "=", "STRING"};
		assert.are.same(expect, tok:Tokenize(str, cb.onlytoken));
	end)

	it("parses a simple string block on one line, followed by semicolon", function()
		local str = [=[local foo=[[bar]];]=];
		local expect = {"KEYWORD", "WHITESPACE", "ID", "=", "STRING", ";"};
		assert.are.same(expect, tok:Tokenize(str, cb.onlytoken));
	end)

	it("parses a simple string block on one line, followed by newline", function()
		local str = "local foo=[[bar]]\n";
		local expect = {"KEYWORD", "WHITESPACE", "ID", "=", "STRING", "NEWLINE"};
		assert.are.same(expect, tok:Tokenize(str, cb.onlytoken));
	end)


	it("parses a simple string block on one line", function()
		local str = [=[local foo=[[bar]]]=];
		local expect = {"KEYWORD", "WHITESPACE", "ID", "=", "STRING"};
		assert.are.same(expect, tok:Tokenize(str, cb.onlytoken));
	end)

	it("parses a simple string block on multiple lines", function()
		local str = [[local function(a, b, c)
			return a * b + c;
		end]];
		local expect = {
			"KEYWORD", "WHITESPACE", "KEYWORD", "(", "ID", ",", "WHITESPACE", "ID", ",", "WHITESPACE",
			"ID", ")", "NEWLINE", "WHITESPACE", "KEYWORD", "WHITESPACE", "ID", "WHITESPACE", "*",
			"WHITESPACE", "ID", "WHITESPACE", "+", "WHITESPACE", "ID", ";", "NEWLINE", "WHITESPACE",
			"KEYWORD"
		};
		assert.are.same(expect, tok:Tokenize(str, cb.onlytoken));
	end)

	it("parses a string block on one line", function()
		local expect = {"KEYWORD", "WHITESPACE", "ID", "=", "STRING", ";"};
		assert.are.same(expect, tok:Tokenize([=[local foo="bar";]=], cb.onlytoken));
	end)

	it("parses a string block with equal signs in its delimiter on one line #only", function()
		local expect = {{"KEYWORD", "local"}, {"WHITESPACE", " "}, {"ID", "foo"}, {"=", "="},
				{"STRING", "[=[bar]=]"}, {";", ";"}};
		assert.are.same(expect, tok:Tokenize([[local foo=[=[bar]=];]], cb.tokenchar));

		local expect = {{"KEYWORD", "local"}, {"WHITESPACE", " "}, {"ID", "foo"}, {"=", "="},
				{"STRING", "[==[bar]==]"}, {";", ";"}};
		assert.are.same(expect, tok:Tokenize([[local foo=[==[bar]==];]], cb.tokenchar));

		local expect = {{"KEYWORD", "local"}, {"WHITESPACE", " "}, {"ID", "foo"}, {"=", "="},
				{"STRING", "[===[bar]===]"}, {";", ";"}};
		assert.are.same(expect, tok:Tokenize([[local foo=[===[bar]===];]], cb.tokenchar));
	end)

	it("parses a string block with equal signs in its delimiter on multiple lines", function()
		local str = [[local foo=([=[
	]=]);]];
		local expect = {"KEYWORD", "WHITESPACE", "ID", "=", "(", "STRING", ")", ";"};
		assert.are.same(expect, tok:Tokenize(str, cb.onlytoken));
	end)
end)
