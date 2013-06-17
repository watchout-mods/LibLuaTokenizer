local NAME, MAJOR, MINOR = "LibHighlight", "LibHighlight-1.0", 1
local Lib = {};
if LibStub then
	Lib = LibStub:NewLibrary(MAJOR, MINOR);
	if not Lib then return end;
else
	_G[NAME] = Lib;
end

---
-- TODO: Implement start character and line positions (high)
-- TODO: Implement some escape sequences in strings like \123 ... or not (very
--       low)
-- TODO: Unicode newlines are: (http://en.wikipedia.org/wiki/Newline#Unicode)
--       * LF:    Line Feed, U+000A
--       * VT:    Vertical Tab, U+000B
--       * FF:    Form Feed, U+000C
--       * CR:    Carriage Return, U+000D
--       * CR+LF: CR (U+000D) followed by LF (U+000A)
--       * NEL:   Next Line, U+0085
--       * LS:    Line Separator, U+2028
--       * PS:    Paragraph Separator, U+2029
local tconcat, pairs, sub = table.concat, pairs, string.sub;

local function tflip(tbl)
	r = {};
	for k,v in pairs(tbl) do r[v] = v end
	return r;
end

local tl_line     = tflip({ "\n","\11","\12","\r","\r\n" }) -- TODO unicode?
local tl_singlec  = tflip({ "^","/","*","+","-","%","=","#","-",",","[","]","(",
                    ")","{","}",":","."," ","\t",";" })
local tl_idstart  = tflip({ "_","A","B","C","D","E","F","G","H","I","J","K","L",
                    "M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","a",
				    "b","c","d","e","f","g","h","i","j","k","l","m","n","o","p",
				    "q","r","s","t","u","v","w","x","y","z" })
local tl_numstrt  = tflip({ "-",".","0","1","2","3","4","5","6","7","8","9" })
local tl_eqstart  = tflip({ "<",">","=","~" })
local tl_anystart = tflip({ "<",">","=","~",".","-","<",">","=","^","/","*","+",
                    "-","%","#","-",",","[","]","(",")","{","}",":","."," ",";",
					"\t","\r","\n" })
local tl_anyfull  = tflip({ "<=",">=","==","~=","..","--","...","<",">","=","^",
                    "/","*","+","-","%","#","-",",","[","]","(",")","{","}",":",
					"."," ","\t",";","\n","\11","\12","\r","\r\n","\133" })
local tl_any      = tflip({ "_","A","B","C","D","E","F","G","H","I","J","K","L",
                    "M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","a",
				    "b","c","d","e","f","g","h","i","j","k","l","m","n","o","p",
				    "q","r","s","t","u","v","w","x","y","z","0","1","2","3","4",
				    "5","6","7","8","9","<",">","=","~","\r","\n",".","-","^",
					"/","*","+","-","%","=","#","-",",","[","]","(",")","{","}",
					":","."," ","\t",";","'",'"' })
local keywords = tflip({"and","break","do","else","elseif","end","false","for",
	"function","if","in","local","nil","not","or","repeat","return","then",
	"true","until","while"})

local function default_transform(token, LS, LE, CS, CE, V, ...)
	return {token, LS, LE, CS, CE, V, ...};
end


function Lib:Tokenize(str, transform)
	local node, stack, ln, pos, len = {}, {}, 1, 1, #str;
	local state1, state2, state3;
	if not transform then transform = default_transform; end
	
	local function finish() -- finish a previous token
		if #stack > 0 then
			node[#node+1] = transform("ERROR",nil,ln,nil,pos,tconcat(stack));
			stack = {};
		end
	end
	function state1() -- start state
		while pos <= len do
			local w = str:sub(pos,pos);
			if tl_anystart[w] then
				finish();
				local ww, www = str:sub(pos,pos+1), str:sub(pos,pos+2);
				if      tl_anyfull[www] then  w = www;
				elseif  tl_anyfull[ww]  then  w = ww;   end
				pos = pos + (#w-1);
				
				if tl_line[w] then
					node[#node+1] = transform("NEWLINE",nil,ln,nil,pos,w);
					ln = ln + 1;
				elseif w == "[" then -- Multi-line string
					local a, b, t = str:find("^%[(=*)%[", pos);
					if a then
						pos = b + 1;
						stack[#stack+1] = ("[%s["):format(t);
						state3(t);
						node[#node+1] = transform("MLSTRING",nil,ln,nil,pos,tconcat(stack),t)
						stack = {}
					else
						node[#node+1] = transform(w, nil, ln, nil, pos);
					end
				elseif w == "--" then
					stack[#stack+1] = "--";
					state4();
					node[#node+1] = transform("COMMENT",nil,ln,nil,pos,tconcat(stack))
					stack = {};
				elseif tl_anyfull[w] then
					node[#node+1] = transform(tl_anyfull[w],nil,ln,nil,pos,w);
				end
			elseif w == '"' or w == "'" then
				finish();
				stack[#stack+1] = w;
				pos = pos + 1;
				state2(w);
			elseif tl_idstart[w] then
				finish();
				local a, b, t = str:find("^([a-zA-Z_][a-zA-Z0-9_]*)", pos); -- ID
				pos = b;
				if keywords[t] then -- Keyword
					node[#node+1] = transform("KEYWORD", nil, ln, nil, pos, t);
				else -- Identifier
					node[#node+1] = transform("ID", nil, ln, nil, pos, t);
				end
			elseif tl_numstrt[w] then
				finish();
				while true do -- pseudo-switch
					local a,b,t = str:find("^(0x[0-9a-fA-F]+)", pos); -- hex number
					if a then
						pos = b;
						node[#node+1] = transform("HEXNUM", nil, ln, nil, pos, t);
						break;
					end
					local a,b,t = str:find("^(%.%d+[eE]?-?[%d]*)", pos); -- number
					if a then
						pos = b;
						node[#node+1] = transform("NUMBER", nil, ln, nil, pos, t);
						break;
					end
					local a,b,t = str:find("^(%d+%.?%d*[eE]?-?[%d]*)", pos); -- number
					if a then
						pos = b;
						node[#node+1] = transform("NUMBER", nil, ln, nil, pos, t);
						break;
					end
					node[#node+1] = transform(w, nil, ln, nil, pos);
					break;
				end
			else
				stack[#stack+1] = w;
			end
			
			pos = pos + 1;
		end
		finish();
	end
	function state2(limiter) -- default string state
		while pos <= len do
			local w = str:sub(pos,pos);
			if w == "\\" then
				-- TODO: Special escape sequences like \123
				stack[#stack+1] = "\\";
				local x, xx = str:sub(pos+1, pos+1), str:sub(pos+1, pos+2);
				if tl_line[xx] or tl_line[x] then
					ln = ln + 1
				end
				local c = tl_line[xx] or tl_line[x] or x;
				stack[#stack+1] = c
				pos = pos + #c;
			elseif tl_line[w] then
				pos = pos - 1;
				break;
			elseif w == limiter then
				stack[#stack+1] = w;
				break
			else
				stack[#stack+1] = w;
			end
			
			pos = pos + 1;
		end
		node[#node+1] = transform("STRING", nil, ln, nil, pos,tconcat(stack),limiter)
		stack = {};
	end
	function state3(limiter) -- block string/comment state
		while pos <= len do
			local w = str:sub(pos,pos);
			if w == "\\" then
				-- TODO: Special escape sequences like \123
				stack[#stack+1] = str:sub(pos, pos+1);
				pos = pos + 1;
			elseif tl_line[w] then
				local ww = str:sub(pos,pos+1);
				if tl_line[ww] then
					pos, w = pos + 1, ww;
				end
				stack[#stack+1] = w;
				ln = ln + 1;
			elseif w == "]" then
				local pos1, pos2, token = str:find("^%]("..limiter..")%]", pos);
				if pos1 then
					pos = pos2;
					stack[#stack+1] = ("]%s]"):format(limiter);
					break
				else
					stack[#stack+1] = w;
				end
			else
				stack[#stack+1] = w;
			end
			
			pos = pos + 1;
		end
	end
	function state4() -- comments
		pos = pos + 1;
		while pos <= len do
			local w = str:sub(pos,pos);
			if w == "\\" then
				-- TODO: Special escape sequences like \123
				local x = str:sub(pos+1, pos+1);
				if x == "\n" then ln = ln + 1 end
				stack[#stack+1] = "\\";
				stack[#stack+1] = x;
				pos = pos + 1;
			elseif tl_line[w] then
				pos = pos - 1;
				break;
			elseif w == "[" then -- Multi-line
				local pos1, pos2, token = str:find("^%[(=*)%[", pos);
				if pos1 then
					pos = pos2 + 1;
					stack[#stack+1] = ("[%s["):format(token);
					state3(token);
				else
					stack[#stack+1] = w;
				end
			else
				stack[#stack+1] = w;
			end
			
			pos = pos + 1;
		end
	end
	
	state1();
	return node;
end

local tl_bnop = tflip({"^","/","*","+","-","%","=","..","<",">","<=",">=",
                 "==","~=","and","or"})
local tl_unop = tflip({"#","-","not"})
local tl_fsep = tflip({",",";"})
local token   = { NUMBER="|cff2aa198", KEYWORD="|cff268bd2", ID      ="|cff93a1a1",
                  STRING="|cff859900", COMMENT="|cff586e75", GLOBALID="|cffd33682",
                  HEXNUM="|cff268bd2", ERROR  ="|cffdc322f", MLSTRING="|cffb58900",}

local function cb(t, LS, LE, CS, CE, V, ...)
	if t == "\t" then -- normalizes tabs
		return '    ';
	elseif t == "NEWLINE" then -- normalizes newlines
		return "\r\n";
	elseif token[t] then
		return ('%s%s|r'):format(token[t], V);
	end
	return V or t;
end
function Lib:Highlight(str)
	return table.concat(self:Tokenize(str, cb));
end

function Lib:StripColors(str)
	return str:gsub("||","|!"):gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r",""):gsub("|!","||");
end