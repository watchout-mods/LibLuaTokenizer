dofile("../LuaTokenizer-1.0.lua");
local io = require("io");

---
-- TESTING
---

local str = {};
for line in io.lines() do
	str[#str+1] = line;
end
str = table.concat(str, "\r\n");

local function tflip(tbl)
	r = {};
	for k,v in pairs(tbl) do r[v] = k end
	return r;
end
--[=[
local tokens = Lib:Tokenize(str);
for i=1, #tokens do
	local t = tokens[i];
	print("Token", t.T, "Value", t.V, "LastChar", t.CE, "LastLine", t.LE);
end]=]

local tokens = { NUMBER="2aa198", KEYWORD="268bd2", ID="93a1a1",
	GLOBALID="d33682", COMMENT="586e75", ERROR="dc322f", HEXNUM="268bd2",
	STRING="859900",MLSTRING="b58900",}
local state, kwstates;
local upvalues = {};
local keywords = tflip({"and","break","do","else","elseif","end","false","for",
	"function","if","in","local","nil","not","or","repeat","return","then",
	"true","until","while"})
local stmts = tflip({"do","else","elseif","end","for","function","if","in",
	"local","repeat","return","then","until","while"})

function tf_blockstart()
	upvalues = setmetatable({}, {__index = upvalues});
end
function tf_blockend()
	local mt = getmetatable(upvalues);
	if mt then
		upvalues = mt.__index;
	end
end
function tf_default(token, LS, LE, CS, CE, V, ...)
	if token == "ID" and not upvalues[V] then
		token = "GLOBALID";
	end
	
	if token == "\t" then
		return '    ';
	elseif token == "NEWLINE" then
		return "<span class=\"newline\">$</span>\n";
	elseif tokens[token] then
		return ('<span class="%s">%s</span>'):format(token, V);
	end
	return V or token;
end

function tf_start(token, LS, LE, CS, CE, V, ...)
	if token == "KEYWORD" then
		if kwstates[V] then
			state = kwstates[V];
		end
	elseif token == "." or token == ":" then
		state = tf_index(tf_start);
	end
	return tf_default(token, LS, LE, CS, CE, V, ...)
end


function tf_index(ret)
	return function(token, LS, LE, CS, CE, V, ...)
		if token == "ID" then
			token = "INDEX";
			state = ret;
		end
		return tf_default(token, LS, LE, CS, CE, V, ...)
	end
end

function tf_local(token, LS, LE, CS, CE, V, ...)
	if token == "KEYWORD" then
		if kwstates[V] then
			state = kwstates[V]
		else
			state = tf_start
		end
	elseif token == "ID" then
		upvalues[V] = true;
	elseif token == "NEWLINE" or token == ";" or token == "=" then
		state = tf_start;
	end
	return tf_default(token, LS, LE, CS, CE, V, ...)
end

function tf_do(token, LS, LE, CS, CE, V, ...)
	state = tf_for2;
	tf_blockstart();
	return tf_default(token, LS, LE, CS, CE, V, ...)
end

function tf_for(token, LS, LE, CS, CE, V, ...)
	state = tf_for2;
	tf_blockstart();
	return tf_for2(token, LS, LE, CS, CE, V, ...)
end

function tf_for2(token, LS, LE, CS, CE, V, ...)
	if token == "KEYWORD" then
		if V == "do" then
			state = tf_start
		elseif kwstates[V] then
			state = kwstates[V]
		else
			state = tf_start
		end
	elseif token == "ID" then
		upvalues[V] = true;
		state = tf_for3;
	end
	
	return tf_default(token, LS, LE, CS, CE, V, ...)
end

function tf_for3(token, LS, LE, CS, CE, V, ...)
	if token == "KEYWORD" then
		if V == "do" then
			state = tf_start
		elseif kwstates[V] then
			state = kwstates[V]
		else
			state = tf_start
		end
	elseif token == "." or token == ":" then
		state = tf_index(tf_for3);
	elseif token == "ID" then
		upvalues[V] = true;
	end
	
	return tf_default(token, LS, LE, CS, CE, V, ...)
end


function tf_func(token, LS, LE, CS, CE, V, ...)
	tf_blockstart();
	state = tf_func2;
	return tf_func2(token, LS, LE, CS, CE, V, ...)
end

function tf_func2(token, LS, LE, CS, CE, V, ...)
	if token == "(" then
		state = tf_local;
	elseif token == ":" then
		upvalues.self = true;
		state = tf_func3;
	end
	return tf_default(token, LS, LE, CS, CE, V, ...)
end

function tf_func3(token, LS, LE, CS, CE, V, ...)
	if token == "(" then
		state = tf_local;
	elseif token == "ID" then
		return tf_default("INDEX", LS, LE, CS, CE, V, ...)
	end
	return tf_default(token, LS, LE, CS, CE, V, ...)
end

function tf_tabledef(token, LS, LE, CS, CE, V, ...)
	if token == "}" then
		state = tf_start;
	elseif token == "ID" then
		return tf_default("INDEX", LS, LE, CS, CE, V, ...)
	end
	return tf_default(token, LS, LE, CS, CE, V, ...)
end


function tf_end(token, LS, LE, CS, CE, V, ...)
	tf_blockend();
	state = tf_start;
	return tf_default(token, LS, LE, CS, CE, V, ...)
end

kwstates = {["local"] = tf_local, ["for"] = tf_for, ["end"] = tf_end,
	["do"] = tf_do, ["then"] = tf_do, ["function"] = tf_func}
state = tf_start
local function transform(...)
	return state(...);
end

io.write(unpack(LuaTokenizer:Tokenize(str, transform)));


