describe("Tokenizer", function( ... )
	local tok = require("LuaTokenizer")

	function cb_onlytoken(token, ...)
		return token;
	end

	it("parses integer numbers", function( ... )
		local expect = {"NUMBER"};
		assert.are.same(expect, tok:Tokenize([[0]], cb_onlytoken));
		assert.are.same(expect, tok:Tokenize([[1]], cb_onlytoken));
		assert.are.same(expect, tok:Tokenize([[99]], cb_onlytoken));

		local expect = {"-", "NUMBER"};
		assert.are.same(expect, tok:Tokenize([[-0]], cb_onlytoken));
		assert.are.same(expect, tok:Tokenize([[-1]], cb_onlytoken));
		assert.are.same(expect, tok:Tokenize([[-99]], cb_onlytoken));
	end)

	it("parses exponential-notation numbers", function( ... )
		local expect = {"NUMBER"};
		assert.are.same(expect, tok:Tokenize([[1.234E567890]], cb_onlytoken));
		assert.are.same(expect, tok:Tokenize([[1.234e567890]], cb_onlytoken));

		local expect = {"-", "NUMBER"};
		assert.are.same(expect, tok:Tokenize([[-1.234E567890]], cb_onlytoken));
		assert.are.same(expect, tok:Tokenize([[-1.234e567890]], cb_onlytoken));
	end)

	it("parses decimal numbers", function( ... )
		local expect = {"NUMBER"};
		assert.are.same(expect, tok:Tokenize([[1.2345678901234567890]], cb_onlytoken));
		assert.are.same(expect, tok:Tokenize([[1.234E567890]], cb_onlytoken));
		assert.are.same(expect, tok:Tokenize([[1.234e567890]], cb_onlytoken));
		assert.are.same(expect, tok:Tokenize([[0.1]], cb_onlytoken));
		assert.are.same(expect, tok:Tokenize([[.1]], cb_onlytoken));

		local expect = {"-", "NUMBER"};
		assert.are.same(expect, tok:Tokenize([[-1.2345678901234567890]], cb_onlytoken));
		assert.are.same(expect, tok:Tokenize([[-1.234E567890]], cb_onlytoken));
		assert.are.same(expect, tok:Tokenize([[-1.234e567890]], cb_onlytoken));
		assert.are.same(expect, tok:Tokenize([[-0.1]], cb_onlytoken));
		assert.are.same(expect, tok:Tokenize([[-.1]], cb_onlytoken));
	end)

	it("parses hexa-decimal numbers", function( ... )
		local expect = {"HEXNUM"};
		assert.are.same(expect, tok:Tokenize([[0x123AF]], cb_onlytoken));
	end)
end)