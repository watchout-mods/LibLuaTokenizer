describe("Tokenizer", function()
	local tok = require("LuaTokenizer")
	local cb = require("spec/Callbacks");

	it("parses a simple single-quoted string", function()
		local actual = [['asdf']];
		local expect = {{"STRING", "'asdf'"}};
		assert.are.same(expect, tok:Tokenize(actual, cb.tokenchar));
	end)

	it("does not change whitespace in a string", function()
		assert.are.same({[[' ']]}, tok:Tokenize([[' ']], cb.onlychar));
		assert.are.same({[[" "]]}, tok:Tokenize([[" "]], cb.onlychar));

		assert.are.same({[['  ']]}, tok:Tokenize([['  ']], cb.onlychar));
		assert.are.same({[["  "]]}, tok:Tokenize([["  "]], cb.onlychar));

		assert.are.same({"' \t'"}, tok:Tokenize("' \t'", cb.onlychar));
		assert.are.same({'" \t"'}, tok:Tokenize('" \t"', cb.onlychar));

		assert.are.same({"' \t \t '"}, tok:Tokenize("' \t \t '", cb.onlychar));
		assert.are.same({'" \t \t "'}, tok:Tokenize('" \t \t "', cb.onlychar));
		assert.are.same({'[[ \t \t ]]'}, tok:Tokenize('[[ \t \t ]]', cb.onlychar));
		assert.are.same({'[=[ \t \t ]=]'}, tok:Tokenize('[=[ \t \t ]=]', cb.onlychar));
	end)

	it("parses a simple string", function()
		local actual = [[x="asdf"]];
		local expect = {"ID", "=", "STRING"};
		assert.are.same(expect, tok:Tokenize(actual, cb.onlytoken));
	end)

	it("parses a simple string exactly", function()
		local str = [[x="asdf"]];
		local expect = {{"ID", "x"}, {"=", "="}, {"STRING", '"asdf"'}};
		local actual =  tok:Tokenize(str, cb.tokenchar);
		assert.are.same(expect, actual);
	end)

	it("parses all escape sequences", function()
		local actual = [["\1\2\3\4\5\6\7\8\9\0\n\r\\\a\90\'\""]];
		local expect = {{"STRING", [["\1\2\3\4\5\6\7\8\9\0\n\r\\\a\90\'\""]]}};
		assert.are.same(expect, tok:Tokenize(actual, cb.tokenchar));
	end)

	it("parses a string with escape at the end", function()
		local str = [[x="asdf\\"]];
		local expect = {"ID", "=", "STRING"};
		local actual =  tok:Tokenize(str, cb.onlytoken);
		assert.are.same(expect, actual);
	end)

	it("parses a string with escape at the end exactly", function()
		local str = [[x="asdf\\"]];
		local expect = {{"ID", "x"}, {"=", "="}, {"STRING", [["asdf\\"]]}};
		local actual =  tok:Tokenize(str, cb.tokenchar);
		assert.are.same(expect, actual);
	end)

	it("outputs an error when parsing a string with escape at the end", function()
		local str = [[x="asdf\"]];
		local expect = {"ID", "=", "ERROR"};
		local actual =  tok:Tokenize(str, cb.onlytoken);
		assert.are.same(expect, actual);
	end)

	it("outputs an error and exact fragments when parsing string with escape at the end", function()
		local str = [[x="asdf\"]];
		local s = [["asdf\"]]; -- separate line because SLT highlighting fails otherwise
		local expect ={{"ID", "x"}, {"=", "="}, {"ERROR", s}};
		local actual =  tok:Tokenize(str, cb.tokenchar);
		assert.are.same(expect, actual);
	end)
end)
