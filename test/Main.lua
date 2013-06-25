dofile("../LuaTokenizer-1.0-SM.lua");
local io = require("io");

local str = {};
for line in io.lines() do
	str[#str+1] = line;
end
str = table.concat(str, "\n");

local Highlighter = {}
do
	local op = "OPERATOR"
	local token = {
		NUMBER="NUMBER", KEYWORD="KEYWORD", ID       ="ID",
		STRING="STRING", COMMENT="COMMENT", GLOBALID ="GLOBALID",
		HEXNUM="HEXNUM", ERROR  ="ERROR",   MLSTRING ="MLSTRING",
		["<="]=op,[">="]=op,["=="]=op,["~="]=op,[".."]=op,["..."]=op,
		["<"]=op,[">"]=op,["="]=op,["^"]=op,["/"]=op,["*"]=op,["+"]=op,["-"]=op,
		["%"]=op,["#"]=op,["-"]=op,[","]=op,["["]=op,["]"]=op,["("]=op,[")"]=op,
		["{"]=op,["}"]=op,[":"]=op,["."]=op,[";"]=op, }

	local function cb(t, V, LS, LE, CS, CE, ...)
		if t == "\t" then -- normalizes tabs
			return '    ';
		elseif t == "NEWLINE" then -- normalizes newlines
			return V;
		elseif token[t] then
			return ('<span class="%s" data-cs="%s" data-ce="%s" data-tt="%s">%s</span>')
				:format(token[t], CS or "", CE or "", t or "", V or t or "");
		end
		return V or t;
	end
	
	function Highlighter:Highlight(str)
		return table.concat(LuaTokenizer:Tokenize(str, cb));
	end

	function Highlighter:StripColors(str)
		return str:gsub("||","|!"):gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r",""):gsub("|!","||");
	end
end

io.write(Highlighter:Highlight(str));

local r, e = loadstring(str, "input")
if e then 
	local line, err = e:match("^%[string \"input\"%]:(%d+):(.*)$");
	print("\n\n");
	print("Error:", line, err);
end

