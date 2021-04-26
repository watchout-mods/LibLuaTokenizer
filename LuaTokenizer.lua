local NAME, MAJOR, MINOR = "LuaTokenizer", "LuaTokenizer-1.0", 3
local Lib = {};
if LibStub then
	Lib = LibStub:NewLibrary(MAJOR, MINOR);
	if not Lib then return end;
else
	_G[NAME] = Lib;
end

local tconcat, pairs, sub, char, byte
    = table.concat, pairs, string.sub, string.char, string.byte;
local keywords = {["and"]="and",["break"]="break",["do"]="do",["local"]="local",
	["elseif"]="elseif",["end"]="end",["false"]="false",["in"]="in",["if"]="if",
	["function"]="function",["return"]="return",["repeat"]="repeat",["or"]="or",
	["then"]="then",["else"]="else",["for"]="for",["nil"]="nil",["true"]="true",
	["not"]="not",["until"]="until",["while"]="while"};

---
-- @param token the current token (or char)
-- @param V     the current item (value/char/token)
-- @param LS    the start line of the current item
-- @param LE    the end line of the current item
-- @param CS    the start of the current item
-- @param CE    the end of the current item
local function default_transform(...) -- token, V, LS, LE, CS, CE, ... = ...
	return {...};
end

local states = nil;
local START, ERROR, ANY, F = "START", "ERROR", {}, {} -- special keys
Lib.START, Lib.ERROR, Lib.ANY, Lib.FNC = START, ERROR, ANY, F;

--------------------------------------------------------------------------------
---                    character- class and range helpers                    ---
--------------------------------------------------------------------------------
local function range(start, stop)
	return function(tbl, set)
		for i=byte(start), byte(stop) do tbl[char(i)] = set; end
	end
end
local function list(...)
	local list = {...};
	return function(tbl, set)
		for i=1, #list do tbl[list[i]] = set; end
	end
end
local function except(...)
	local list = {...};
	for i=1, #list do list[list[i]], list[i] = true, nil; end
	return function(tbl, set)
		local ch;
		for i=1, 255 do 
			ch = char(i);
			if not list[ch] then tbl[ch] = set; end
		end
	end
end
local function class_idstart()
	return function(tbl, set)
		for i=byte("a"), byte("z") do tbl[char(i)] = set; end
		for i=byte("A"), byte("Z") do tbl[char(i)] = set; end
		tbl["_"] = set;
	end
end
local function class_id()
	return function(tbl, set)
		for i=byte("a"), byte("z") do tbl[char(i)] = set; end
		for i=byte("A"), byte("Z") do tbl[char(i)] = set; end
		for i=byte("0"), byte("9") do tbl[char(i)] = set; end
		tbl["_"] = set;
	end
end

--------------------------------------------------------------------------------
---                          token operator helpers                          ---
--------------------------------------------------------------------------------
local function push_char(token, newstate, more)
	newstate = newstate or "START";
	return function(states, stack, str, ret, cb, pos, ln)
		local s = stack[1];
		-- stack[2], stack[1] = nil, stack[2];
--print(("PUSH CHAR\t%q\t%q LEN	%d	POS	%d"):format(token or s, s, #stack, pos))
		ret[#ret + 1] = cb(token or s, s, ln, ln, pos - #s, pos - 1, more);
		return states[newstate], {}, pos, ln;
	end
end

local function push_token(token, newstate, more)
	newstate = newstate or "START";
	return function(states, stack, str, ret, cb, pos, ln)
		local s = tconcat(stack, "", 1, #stack - 1);
--print(("PUSH TOKEN\t%q\t%q"):format(token or s, s))
		ret[#ret + 1] = cb(token or s, s, ln, ln, pos - #s, pos - 1, more);
		return states[newstate], {}, pos, ln;
	end
end

local function push_id(newstate)
	newstate = newstate or "START";
	return function(states, stack, str, ret, cb, pos, ln)
		local s = tconcat(stack, "", 1, #stack - 1);
		local token = keywords[s] and "KEYWORD" or "ID";
--print(("PUSH ID\t%q\t%q"):format(token or s, s))
		ret[#ret + 1] = cb(token or s, s, ln, ln, pos - #s, pos - 1);
		return states[newstate], {}, pos, ln;
	end
end

local function add_line(x)
	if type(x) == "function" then
		return function(a, b, c, d, e, f, l) return x(a, b, c, d, e, f, l + 1) end
	else
		x = x or "START";
		return function(a, b, c, d, e, p, l) return states[x], b, p, l + 1 end
	end
end

local function consume_block(token, newstate, stackpos)
	newstate = newstate or "START";
	stackpos = stackpos or 2;
	return function(states, stack, str, ret, cb, pos, ln)
		local open = stackpos == 0 and "" or tconcat(stack, "", stackpos, #stack - 2);
		local find = "^(.-%]" .. open .. "%])(.?)";
		local pos1, pos2, blk, nxt = str:find(find, pos);
--print("CONSUME", find, pos, pos1, pos2, blk)
		if pos1 then
			stack[#stack] = blk; -- stack[#stack] => was first ch of block from statemachine
			local s = tconcat(stack);
			ret[#ret + 1] = cb(token or s, s, ln, ln, pos - #open - 2, pos2 - 1, more);
			return states[newstate], {}, pos2, ln;
		else
			return states[ERROR], stack, pos, ln;
		end
	end
end

states = {
	[ERROR] = {[F] = push_token("ERROR")}, -- Error trap
	[ANY] = {[F] = push_token("ERROR")},
	[F] = push_token("ERROR"),
	[START] = {
		[list("\11","\12","\n")] = {[F] = add_line(push_char("NEWLINE"))},
		["\r"] = {
			["\n"] = {[F] = add_line(push_token("NEWLINE"))},
			[F] = add_line(push_char("NEWLINE")),},
		["'"] = "STRINGA",
		['"'] = "STRINGB",
		["["] = "BRACKET",
		["."] = {
			[range("0","9")] = "NUMBER2",
			[F] = push_char(nil),},
		["0"] = { 
			["x"] = "HEXNUM",
			["."] = "NUMBER2",
			[range("1","9")] = "NUMBER",
			[list("e","E")] = "NUMBER3",
			[F] = push_char("NUMBER")},
		[range("1","9")] = "NUMBER",
		[class_idstart()] = "ID", --{[F] = consume_while("^([a-zA-Z0-9_]*)", "ID")},
		[list("<",">","=")] = {
			[F] = push_char(nil),
			["="] = {[F] = push_token(nil)}},
		["~"] = {
			[F] = push_token("ERROR"), -- if left out, next char would be in error token too
			["="] = {[F] = push_token(nil)},},
		[list("^","/","*","+","%","#",",","]","(",")","{","}",":",";")] = {
			[F] = push_char(nil)},
		[list(" ", "\t")] = {
			[list(" ", "\t")] = "BLANK",
			[F] = push_char("WHITESPACE")},
		["-"] = {
			["-"] = "COMMENT",
			[F] = push_char(nil)}},
	BLANK = {
		[list(" ", "\t")] = "BLANK",
		[F] = push_token("WHITESPACE")},
	STRINGA = {
		["'"] = {[F] = push_token("STRING")},
		["\\"] = {
			[ANY] = "STRINGA",
			["\n"] = {[F] = add_line("STRINGA")},
			["\r"] = {
				["\n"] = {[F] = add_line("STRINGA")},
				[F] = add_line("STRINGA")}},
		["\r"] = {
			["\n"] = {[F] = push_token("ERROR")},
			[F] = push_token("ERROR")},
		["\n"] = {[F] = push_token("ERROR")},
		[ANY] = "STRINGA",
	},
	STRINGB = {
		['"'] = {[F] = push_token("STRING")},
		["\\"] = {
			[ANY] = "STRINGB",
			["\n"] = {[F] = add_line("STRINGB")},
			["\r"] = {
				["\n"] = {[F] = add_line("STRINGB")},
				[F] = add_line("STRINGB")}},
		["\r"] = {
			["\n"] = {[F] = push_token("ERROR")},
			[F] = push_token("ERROR")},
		["\n"] = {[F] = push_token("ERROR")},
		[ANY] = "STRINGB"},
	NUMBER = {
		[range("1", "9")] = "NUMBER2",
		["."] = "NUMBER2",
		["x"] = "HEXNUM",
		[list("e", "E")] = "NUMBER3",
		[F] = push_token("NUMBER")},
	NUMBER2 = {[range("0", "9")] = "NUMBER2", [list("e", "E")] = "NUMBER3", [F] = push_token("NUMBER")},
	NUMBER3 = {[range("0", "9")] = "NUMBER5", ["-"] = "NUMBER4"},
	NUMBER4 = {[range("0", "9")] = "NUMBER5"},
	NUMBER5 = {[range("0", "9")] = "NUMBER5", [F] = push_token("NUMBER")},
	HEXNUM = {
		[range("0", "9")] = "HEXNUM",
		[range("a", "f")] = "HEXNUM",
		[range("A", "F")] = "HEXNUM",
		[F] = push_token("HEXNUM")},
	ID = {
		[class_id()] = "ID",
		[F] = push_id()},
	BRACKET = {
		["["] = {[F] = consume_block("STRING", "START", 0)},
		["="] = "BRACKET2",
		[F] = push_token(nil) --[[Normal brackets - for table index]]},
	BRACKET2 = {["["] = {[F] = consume_block("STRING")}, ["="] = "BRACKET2"},
	COMMENT = {
		["["] = {
			["="] = "CRACKET",
			["["] = {[F] = consume_block("COMMENT", "START", 4)},
			[except("\r", "\n", "=", "[")] = "COMMENT2",
			[F] = push_token("COMMENT")},
		[except("\r", "\n", "[")] = "COMMENT2",
		[F] = push_token("COMMENT")},
	COMMENT2 = {
		[except("\r", "\n")] = "COMMENT2",
		[F] = push_token("COMMENT")},
	CRACKET  = {["["] = {[F] = consume_block("COMMENT", "START", 4)}, ["="] = "CRACKET", [ANY] = "COMMENT2"},
}

---
-- @param str the string to tokenize
-- @param cb  a callback that is called when an error is encountered
function Lib:Tokenize(str, cb)
	local st, ret, len, cb = states[START], {}, #str, cb or default_transform;
	local stack, pos, ln = {}, 1, 1;
	while pos <= (len + 1) do
		local ch = str:sub(pos, pos);     -- get next character. No way around this.
		local newst = st[ch] or st[ANY];  -- try transition to new state using ch
		stack[#stack + 1] = ch;
		if not newst and st[F] then
			newst, stack, pos, ln = st[F](states, stack, str, ret, cb, pos, ln);
			-- next state, new pos, new line number
			--newst = newst[ch] or newst[ANY] or states[ERROR];
		else
			pos = pos + 1;
		end
		st = newst or states[ERROR];
	end
	if #stack > 1 then
		states[ERROR][F](states, stack, str, ret, cb, pos, ln);
	end
	return ret;
end

---
-- Prepares a parse tree.
local function prepare_tree(states, state)
	local queue = {};
	for k,v in pairs(state) do
		local t = type(v);
		if t == "table" then
			setmetatable(v, {__tostring = function() return tostring(k) end})
			prepare_tree(states, v);
		elseif t == "string" then
			state[k] = states[v];
		end
		if type(k) == "function" then
			queue[#queue+1] = k;
		end
	end
	for i=1, #queue do
		local k = queue[i]
		state[k] = nil, k(state, state[k]); -- state[k] is only nil'd after assignment
	end
end
prepare_tree(states, states)

return Lib;