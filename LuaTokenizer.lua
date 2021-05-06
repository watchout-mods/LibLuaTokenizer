local NAME, MAJOR, MINOR = "LuaTokenizer", "LuaTokenizer-1.0", 4
local Lib = {};
if LibStub then
	Lib = LibStub:NewLibrary(MAJOR, MINOR);
	if not Lib then return end;
else
	_G[NAME] = Lib;
end

local tconcat, pairs, sub, char, byte
    = table.concat, pairs, string.sub, string.char, string.byte;
local keywords = { ["and"] = "and", ["break"] = "break", ["do"] = "do", ["else"] = "else",
	["elseif"] = "elseif", ["end"] = "end", ["false"] = "false", ["for"] = "for",
	["function"] = "function", ["if"] = "if", ["in"] = "in", ["local"] = "local", ["nil"] = "nil",
	["not"] = "not", ["or"] = "or", ["repeat"] = "repeat", ["return"] = "return", ["then"] = "then",
	["true"] = "true", ["until"] = "until", ["while"] = "while" };

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
local START, ERROR, ANY, F, G = "START", "ERROR", {}, {}, {}; -- special keys
local FNC = {[F] = F, [G] = G};
Lib.Special = { ERROR = ERROR, START = START, ANY = ANY };
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
		local open = stackpos == 0 and "" or tconcat(stack, "", stackpos, #stack - 1);
		local find = "^(.-%]" .. open .. "%])";
		local pos1, pos2, blk = str:find(find, pos);
		-- print(("CONSUME find %q; pos %q; pos1 %s; pos2 %s; blk %q"):format(find, pos, tostring(pos1), tostring(pos2), blk or ""));
		if pos1 then
			stack[#stack] = blk; -- stack[#stack] => was first ch of block from statemachine
			local s = tconcat(stack);
			ret[#ret + 1] = cb(token or s, s, ln, ln, pos1, pos2);
			return states[newstate], {}, pos2 + 1, ln;
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
			[F] = add_line(push_char("NEWLINE"))},
		["'"] = "STRINGA",
		['"'] = "STRINGB",
		["["] = "BRACKET",
		["."] = {[range("0","9")] = "NUM_DEC", [F] = push_char()},
		["0"] = { 
			["x"] = "NUM_HEX",
			["."] = "NUM_DEC",
			[range("1","9")] = "NUMBER",
			[list("e","E")] = "NUM_EXP",
			[F] = push_char("NUMBER")},
		[range("1","9")] = "NUMBER",
		[class_idstart()] = "ID", --{[F] = consume_while("^([a-zA-Z0-9_]*)", "ID")},
		[list("<",">","=")] = {
			[F] = push_char(),
			["="] = {[F] = push_token()}},
		["~"] = {
			[F] = push_token("ERROR"), -- if left out, next char would be in error token too
			["="] = {[F] = push_token()},},
		[list("^","/","*","+","%","#",",","]","(",")","{","}",":",";")] = {[F] = push_char()},
		[list(" ", "\t")] = {
			[list(" ", "\t")] = "BLANK",
			[F] = push_char("WHITESPACE")},
		["-"] = {
			["-"] = "COMMENT",
			[F] = push_char()}},
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
		[ANY] = "STRINGA"},
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
		[range("0", "9")] = "NUMBER",
		["."] = "NUM_DEC",
		[list("e", "E")] = "NUM_EXP",
		[F] = push_token("NUMBER")},
	NUM_DEC = {
		[range("0", "9")] = "NUM_DEC",
		[list("e", "E")] = {
			["-"] = {[range("0", "9")] = "NUM_EXP"},
			[range("0", "9")] = "NUM_EXP"},
		[F] = push_token("NUMBER")},
	NUM_EXP = {[range("0", "9")] = "NUM_EXP", [F] = push_token("NUMBER")},
	NUM_HEX = {
		[range("0", "9")] = "NUM_HEX",
		[range("a", "f")] = "NUM_HEX",
		[range("A", "F")] = "NUM_HEX",
		[F] = push_token("HEXNUM")},
	ID = {[class_id()] = "ID", [F] = push_id()},
	BRACKET = {
		[F] = push_token() --[[Normal brackets - for table index]],
		[G] = consume_block("STRING", nil, 0),
		["["] = G,
		["="] = "BRACKET2"},
	BRACKET2 = {
		[G] = consume_block("STRING", nil, 2),
		["["] = G,
		["="] = "BRACKET2"},
	COMMENT = {
		[F] = push_token("COMMENT"),
		["["] = {
			[F] = push_token("COMMENT"),
			[G] = consume_block("COMMENT", nil, 0),
			["="] = "CRACKET",
			["["] = G,
			[list("\r", "\n", "")] = F,
			[ANY] = "COMMENT"},
		[list("\r", "\n", "")] = F,
		[ANY] = "COMMENT2"},
	COMMENT2 = {
		[except("\r", "\n")] = "COMMENT2",
		[F] = push_token("COMMENT")},
	CRACKET  = {
		[G] = consume_block("COMMENT", nil, 0),
		["["] = G,
		["="] = "CRACKET",
		[ANY] = "COMMENT2"},
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
		-- print(("A ch %q; pos %s; st[ch] %q; len+1 %q"):format(ch, pos, tostring(st[ch] and true), len + 1));
		if newst == nil and st[F] then
			newst, stack, pos, ln = st[F](states, stack, str, ret, cb, pos, ln);
		elseif newst and FNC[newst] then
			-- new state, stack, new pos, new line number
			newst, stack, pos, ln = st[newst](states, stack, str, ret, cb, pos, ln);
		else
			pos = pos + 1;
		end
		-- print(("B ch %q; pos %s; st[ch] %q; len+1 %q"):format(ch, pos, tostring(st[ch] and true), len + 1));
		st = newst or states[ERROR];
	end
	if #stack > 1 then
		states[ERROR][F](states, stack, str, ret, cb, pos, ln);
	end
	return ret;
end

---
-- Prepares a parse tree.
-- 
-- If the value is a string, it will be replaced by the top-level value where the index is that
-- string. If the key is a function, this will run the function with the sub-table and key as
-- arguments.
local function prepare_tree(states, state)
	local queue, queuelen = {}, 0;
	for k, v in pairs(state) do
		local t = type(v);
		if FNC[v] then
			-- nop
		elseif t == "table" then
			setmetatable(v, {__tostring = function() return tostring(k) end})
			prepare_tree(states, v);
		elseif t == "string" then
			state[k] = states[v];
		end
		if type(k) == "function" then
			queuelen = queuelen + 1;
			queue[queuelen] = k;
		end
	end
	for i=1, queuelen do
		local k = queue[i]
		state[k] = nil, k(state, state[k]); -- state[k] is only nil'd after assignment
	end
end
prepare_tree(states, states)

return Lib;