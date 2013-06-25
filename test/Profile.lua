local d = os.clock;
local io = require("io");

local str = {};
for line in io.lines() do
	str[#str+1] = line;
end
str = table.concat(str, "\n");

local cb = function() end;

local t;

t = d();
dofile("../LuaTokenizer-1.0.lua");
print("Loading time:", d()-t)
t = d();
for i=1, 100 do
	local x = LuaTokenizer:Tokenize(str, cb)
end
print("    Exec time:", d()-t)
print("--------------------")

t = d();
dofile("../LuaTokenizer-1.0-old.lua");
print("Loading time of old version:", d()-t)
t = d();
for i=1, 100 do
	local x = LuaTokenizer:Tokenize(str, cb)
end
print("    Exec time:", d()-t)
print("--------------------")
