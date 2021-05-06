describe("Tokenizer", function()
	local tok = require("LuaTokenizer")
	local cb = require("spec/Callbacks");

	it("parses an empty comment", function()
		local str = [[--]];
		local expect = {{"COMMENT", "--"}};
		local actual =  tok:Tokenize(str, cb.tokenchar);
		assert.are.same(expect, actual);
	end)

	it("parses an empty comment (2)", function()
		local str = [[-- ]];
		local expect = {{"COMMENT", "-- "}};
		local actual =  tok:Tokenize(str, cb.tokenchar);
		assert.are.same(expect, actual);
	end)

	it("parses a single line comment", function()
		local str = [[-- asdf]];
		local expect = {"COMMENT"};
		local actual =  tok:Tokenize(str, cb.onlytoken);
		assert.are.same(expect, actual);
	end)

	it("parses a single line comment exactly", function()
		local str = [[-- asdf]];
		local expect = {{"COMMENT", "-- asdf"}};
		local actual =  tok:Tokenize(str, cb.tokenchar);
		assert.are.same(expect, actual);
	end)

	it("parses a comment with escaped escape at the end", function()
		local str = [[-- asdf\\]];
		local expect = {{"COMMENT", "-- asdf\\\\"}};
		local actual =  tok:Tokenize(str, cb.tokenchar);
		assert.are.same(expect, actual);
	end)

	it("parses a block comment", function()
		local str = [=[--[[asdf]]]=];
		local expect ={{"COMMENT", "--[[asdf]]"}};
		local actual =  tok:Tokenize(str, cb.tokenchar);
		assert.are.same(expect, actual);
	end)

	it("parses a block comment followed by a semicolon", function()
		local str = [=[--[[asdf]];]=];
		local expect ={{"COMMENT", "--[[asdf]]"}, {";", ";"}};
		local actual =  tok:Tokenize(str, cb.tokenchar);
		assert.are.same(expect, actual);
	end)

	it("parses a multi-line block comment", function()
		local str = [=[
		--[[asdf
		ghij]]
		]=];
		local expect ={
			{"WHITESPACE", "		"},
			{"COMMENT", "--[[asdf\n		ghij]]"},
			{"NEWLINE", "\n"},
			{"WHITESPACE", "		"}
		};
		local actual =  tok:Tokenize(str, cb.tokenchar);
		assert.are.same(expect, actual);
	end)
end)
