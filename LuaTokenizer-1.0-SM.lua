local NAME, MAJOR, MINOR = "LuaTokenizer", "LuaTokenizer-1.0", 1
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
local function list(...)
	local list = {...};
	return function(tbl, set)
		for i=1, #list do tbl[list[i]] = set; end
	end
end

--------------------------------------------------------------------------------
---                          token operator helpers                          ---
--------------------------------------------------------------------------------
local function push_char(token, newstate, more)
	newstate = newstate or "START";
	return function(states, stack, str, ret, cb, pos, ln)
		local s = stack[1];
		stack[2], stack[1] = nil, stack[2];
--print(("PUSH CHAR\t%q\t%q LEN	%d	POS	%d"):format(token or s, s, #stack, pos))
		ret[#ret+1] = cb(token or s, s, ln, ln, pos-#s, pos-1, more)
		return states[newstate], stack, pos, ln;
	end
end
local function push_token(token, newstate, more)
	newstate = newstate or "START";
	return function(states, stack, str, ret, cb, pos, ln)
		local s = tconcat(stack, "", 1, #stack-1);
		stack = {stack[#stack]};
--print(("PUSH TOKEN\t%q\t%q"):format(token or s, s))
		ret[#ret+1] = cb(token or s, s, ln, ln, pos-#s, pos-1, more)
		return states[newstate], stack, pos, ln;
	end
end
local function push_id(newstate)
	newstate = newstate or "START";
	return function(states, stack, str, ret, cb, pos, ln)
		local s, token = tconcat(stack, "", 1, #stack-1), "ID";
		stack = {stack[#stack]};
		if keywords[s] then token = "KEYWORD" end
--print(("PUSH ID\t%q\t%q"):format(token or s, s))
		ret[#ret+1] = cb(token or s, s, ln, ln, pos-#s, pos-1)
		return states[newstate], stack, pos, ln;
	end
end
local function add_line(x)
	if type(x) == "function" then
		return function(a,b,c,d,e,f,l) return x(a,b,c,d,e,f,l+1) end
	else
		x = x or "START";
		return function(a,b,c,d,e,p,l) return states[x], b, p-1, l+1 end
	end
end
local function consume_block(token, newstate, stackpos)
	newstate = newstate or "START";
	return function(states, stack, str, ret, cb, pos, ln)
		local open = tconcat(stack, "", stackpos or 2, #stack-2);
		local find = ("^(.-%%]%s%%])(.)"):format(open);
--print("CONSUME", find, pos, pos1, pos2, blk)
		local pos1, pos2, blk, nxt = str:find(find, pos);
		if pos1 then
			stack[#stack] = blk; -- stack[#stack] => was first ch of block from statemachine
			local s = tconcat(stack);
			ret[#ret+1] = cb(token or s, s, ln, ln, pos-#open-2, pos2, more)
			stack = {nxt};
			return states[newstate], stack, pos2, ln;
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
			[range("0","9")] = "NUMBER",
			[list("e","E")] = "NUMBER3",
			[F] = push_char("NUMBER")},
		[range("1","9")] = "NUMBER",
		[class_idstart()] = "ID", --{[F] = consume_while("^([a-zA-Z0-9_]*)", "ID")},
		[list("<",">","=")] = {
			[F] = push_char(nil),
			["="] = {[F] = push_token(nil)}},
		["~"] = {
			["="] = {[F] = push_token(nil)},},
		[list("^","/","*","+","%","#",",","]","(",")","{","}",":"," ","\t",";")]
			= {[F] = push_char(nil)},
		["-"] = {
			["-"] = "COMMENT", --{
				--[F] = push_token("COMMENT", "COMMENT")},
			[F] = push_char(nil)}},
	STRINGA = {
		["'"] = {[F] = push_token("STRING")},
		["\\"] = {
			[ANY] = "STRINGA",
			["\n"] = {
				["\r"] = {[F] = add_line("STRINGA")},
				[F] = add_line("STRINGA")}},
		["\n"] = {
			["\r"] = {[F] = push_token("ERROR")},
			[F] = push_token("ERROR")},
		[ANY] = "STRINGA",
	},
	STRINGB = {
		['"'] = {[F] = push_token("STRING")},
		["\\"] = {
			[ANY] = "STRINGB",
			["\n"] = {
				["\r"] = {[F] = add_line("STRINGB")},
				[F] = add_line("STRINGB")}},
		["\n"] = {
			["\r"] = {[F] = push_token("ERROR")},
			[F] = push_token("ERROR")},
		[ANY] = "STRINGB"},
	NUMBER = {
		[range("1","9")] = "NUMBER",
		["."] = "NUMBER2",
		[list("e","E")] = "NUMBER3",
		["0"] = { 
			["x"] = "HEXNUM",
			[range("0","9")] = "NUMBER",
			["."] = "NUMBER2"},
		[F] = push_token("NUMBER")},
	NUMBER2 = {[range("0","9")] = "NUMBER2", [list("e","E")] = "NUMBER3", [F] = push_token("NUMBER")},
	NUMBER3 = {[range("0","9")] = "NUMBER5", ["-"] = "NUMBER4"},
	NUMBER4 = {[range("0","9")] = "NUMBER5" },
	NUMBER5 = {[range("0","9")] = "NUMBER5", [F] = push_token("NUMBER")},
	HEXNUM = {
		[range("0","9")] = "HEXNUM",
		[range("a","f")] = "HEXNUM",
		[range("A","F")] = "HEXNUM",
		[F] = push_token("HEXNUM")},
	ID = {
		[class_id()] = "ID",
		[F] = push_id()},
	BRACKET  = {["["] = {[F]=consume_block("STRING"),},["="]="BRACKET2",[F] = push_token(nil),},
	BRACKET2 = {["["] = {[F]=consume_block("STRING"),},["="]="BRACKET2",},
	COMMENT  = {
		["["] = {
			["="]="CRACKET",
			["["]={[F]=consume_block("COMMENT","START",4)},
			[ANY] = "COMMENT2"},
		[ANY] = "COMMENT2",},
	COMMENT2 = {
		["\n"] = {
			["\r"] = {[F] = push_token("COMMENT")},
			[F] = push_token("COMMENT"),
		},
		[ANY] = "COMMENT2",
	},
	CRACKET  = {["["] = {[F]=consume_block("COMMENT","START",4),},["="]="CRACKET",[ANY] = "COMMENT2",},
}

function Lib:Tokenize(str, cb)
	local st, ret, len, cb = states[START], {}, #str, cb or default_transform;
	local stack, pos, ln = {}, 1, 1;
	while pos <= len+1 do
		local ch = str:sub(pos,pos);
		local newst = st[ch] or st[ANY]; 
		stack[#stack+1] = ch;
		if not newst and st[F] then
			newst, stack, pos, ln = st[F](states,stack,str,ret,cb,pos,ln);
			newst = newst[ch] or newst[ANY] or states[ERROR]; 
		end
		st = newst or states[ERROR];
		pos = pos + 1;
	end
	if #stack > 1 then
		states[ERROR][F](states,stack,str,ret,cb,pos,ln);
	end
	return ret;
end

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
		state[k] = nil, k(state, state[k]);
	end
end
prepare_tree(states, states)

-- print tree:
--[===[
local ST = {};
function printTree(t, indent, known, rec, ...)
	if type(t) ~= "table" then error("Argument #1 must be a table") end
	if rec ~= nil and type(rec) ~= "number" then error("Argument #2 must be nil or a number") end
	if known ~= nil and type(known) ~= "table" then error("Argument #3 must be nil or a table") end
	
	known = known or {t, [t] = 1};
	rec = rec or 0;
	indent = indent or "  ";
	local indentc = indent:rep(rec);
	local indentn = indent:rep(rec+1);
	local msg = tostring(t);
	if ... then msg = ("[%s]"):format(tostring(...):gsub("[\n]","\\n"):gsub("[\r]","\\r")); end
	
	local sorter = {};
	for k,v in pairs(t) do sorter[#sorter+1] = k; end
	table.sort(sorter, function(a, b)
		local ta, tb = type(a), type(b);
		-- returns true when the first is less than the second
		if ta == tb then
			return tostring(a) < tostring(b);
		elseif ta == "boolean" then
			return true;
		elseif ta == "number" and tb == "string" then
			return true;
		elseif ta == "string" and tb == "number" then
			return false;
		elseif ta == "table" then
			return true;
		elseif tb == "table" then
			return false;
		end
		return tostring(a) < tostring(b);
	end);
	
	print(indentc..msg.." = {");
	for a,k in ipairs(sorter) do
		local _k = k
		if type(_k) == "table" then
			if not known[k] then known[#known+1] = k; known[k] = #known; end
			_k = known[k]
		elseif type(_k) == "function" then
			if not known[k] then known[#known+1] = k; known[k] = #known; end
			_k = "FNC#"..known[k]
		elseif type(_k) == "string" then
			_k = k:gsub("[\n\r]", "\\n");
		else
			_k = tostring(k);
		end
		if type(t[k]) == "table" and not known[t[k]] then
			known[#known+1] = t[k];
			known[t[k]] = (known[t] or "T")..".".._k or #known;
			printTree(t[k], indent, known, rec+1, k);
		elseif type(t[k]) == "table" then
			print(("%s[%s] = recurse to #%s,"):format(indentn,_k,tostring(known[t[k]])));
		else
			print(("%s[%s] = %s,"):format(indentn,_k,tostring(t[k])));
			--print(("  "):rep(rec+2).."["..tostring(k).."] = "..tostring(t[k])..",");
		end
	end
	print(indentc.."},");
end
printTree(states, "  ", {F, ANY, states, [F]=":F:", [ANY]=":ANY:", [states]="states"})
--]===]
