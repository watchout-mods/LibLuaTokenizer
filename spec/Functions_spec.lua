describe("Tokenizer", function()
	local tok = require("LuaTokenizer")
	local cb = require("spec/Callbacks");

	local function assertTokenChar(expect, source)
		assert.are.same(expect, tok:Tokenize(source, cb.tokenchar))
	end

	it("parses an empty anonymous function", function()
		local str = [[function()end]];
		local expect = {"KEYWORD", "(", ")", "KEYWORD"};
		local actual = tok:Tokenize(str, cb.onlytoken);
		assert.are.same(expect, actual);

		local expect = {"function", "(", ")", "end"};
		local actual =  tok:Tokenize(str, cb.onlychar);
		assert.are.same(expect, actual);
	end)

	it("parses an empty function", function()
		local str = [[function foo()end]];
		local expect = {"function", " ", "foo", "(", ")", "end"};
		local actual = tok:Tokenize(str, cb.onlychar);
		assert.are.same(expect, actual);
	end)

	it("parses a function with arguments", function()
		local str = [[function foo(a,b,cde)end]];
		local expect = {"function", " ", "foo", "(", "a", ",", "b", ",", "cde", ")", "end"};
		local actual = tok:Tokenize(str, cb.onlychar);
		assert.are.same(expect, actual);
	end)

	it("parses a function with arguments and vararg #ignore", function()
		local str = [[function foo(a,b,cde,...)end]];
		local expect = {"function", " ", "foo", "(", "a", ",", "b", ",", "cde", ",", "...", ")", "end"};
		local actual = tok:Tokenize(str, cb.onlychar);
		assert.are.same(expect, actual);
	end)

	it("parses a return statement", function()
		assertTokenChar({{"KEYWORD", "return"}}, [[return]]);
		assertTokenChar({{"KEYWORD", "return"}, {";", ";"}}, [[return;]]);
		assertTokenChar({{"KEYWORD", "return"}, {"NUMBER", ".1"}}, [[return.1]]);
		assertTokenChar({{"KEYWORD", "return"}, {"STRING", '"x"'}}, [[return"x"]]);
		assertTokenChar({{"KEYWORD", "return"}, {"STRING", '[[x]]'}}, "return[[x]]");

		assertTokenChar({{"KEYWORD", "return"},
				{"STRING", '"a"'},
				{",", ","},
				{"NUMBER", "1.2"},
				{",", ","},
				{"KEYWORD", "false"}},
			[[return"a",1.2,false]]);
	end)
end)
