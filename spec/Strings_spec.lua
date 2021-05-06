describe("Tokenizer", function()
	local tok = require("LuaTokenizer")
	local cb = require("spec/Callbacks");

	it("parses a simple single-quoted string", function()
		local str = [['asdf']];
		local expect = {{"STRING", "'asdf'"}};
		local actual =  tok:Tokenize(str, cb.tokenchar);
		assert.are.same(expect, actual);
	end)

	it("parses a simple string", function()
		local str = [[x="asdf"]];
		local expect = {"ID", "=", "STRING"};
		local actual =  tok:Tokenize(str, cb.onlytoken);
		assert.are.same(expect, actual);
	end)

	it("parses a simple string exactly", function()
		local str = [[x="asdf"]];
		local expect = {{"ID", "x"}, {"=", "="}, {"STRING", '"asdf"'}};
		local actual =  tok:Tokenize(str, cb.tokenchar);
		assert.are.same(expect, actual);
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
