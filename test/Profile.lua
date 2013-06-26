local d = os.clock;
local io = require("io");
local N = 100;

local str = {};
for line in io.lines() do
	str[#str+1] = line;
end
str = table.concat(str, "\n");

local cb = function() end;

local t;

t = d();
dofile("../LuaTokenizer-1.0.lua");
print(("Load time: %.3f ms"):format((d()-t)*1000))
t = d();
for i=1, N do
	local x = LuaTokenizer:Tokenize(str, cb)
end
t = d()-t;
print(("    Exec time: %.3f s"):format(t))
print(("    Avg /it:   %.3f ms"):format(t*1000/N, "ms"))
print( "-----------------------")

t = d();
dofile("../LuaTokenizer-1.0-old.lua");
print("Old version")
print(("Load time: %.3f ms"):format((d()-t)*1000))
t = d();
for i=1, N do
	local x = LuaTokenizer:Tokenize(str, cb)
end
t = d()-t;
print(("    Exec time: %.3f s"):format(t))
print(("    Avg /it:   %.3f ms"):format(t*1000/N, "ms"))
print( "-----------------------")
