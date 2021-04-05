function log(tpl, ...)
	print(tpl:format(...));
end

local TestCase = nil;
local TestCasePrototype = {
	__index = {
		addError = function(tbl, message, ...)
			if tbl.Errors then
				tbl.Errors = tbl.Errors + 1;
			else
				tbl.Errors = 1;
			end
		end,
		addExecution = function(tbl, message, ...)
			if tbl.Executions then
				tbl.Executions = tbl.Executions + 1;
			else
				tbl.Executions = 1;
			end
		end,
		addFailure = function(tbl, message, ...)
			if tbl.Failures then
				tbl.Failures = tbl.Failures + 1;
			else
				tbl.Failures = 1;
			end
		end,
		isDebug = function( ... )
			return false;
		end
	}
}

local function assert_(expect, message, ...)
	if not expect then
		if type(message) == "string" then
			TestCase:addFailure(message:format(...));
			if TestCase:isDebug() then
				log(message, ...);
			end
		else
			TestCase:addFailure("Assertion failed");
			if TestCase:isDebug() then
				log("Assertion failed", ...);
			end
		end
	end
end

function assertEquals(expect, arg, message, ...)
	assert_(expect == arg, "Expected %s, but got %s", expect, arg);
end

function assertArrayEquals(expect, arg, message, ...)
	if message then
		assert_(type(expect) == "table", message, ...);
		assert_(type(arg) == "table", message, ...);
		assert_(#expect == #arg, message, ...);
		for k, v in pairs(expect) do
			assert_(v == arg[k], message, ...);
		end
	else
		assert_(type(expect) == "table", "Need to expect a table, but got", type(expect));
		assert_(type(arg) == "table", "Expected a table, but got", type(arg));
		assert_(#expect == #arg, "Arrays are of unequal length (expected %s ~= %s)", #expect, #arg);
		for k, v in pairs(expect) do
			assert_(v == arg[k], "Array value different (expected %s ~= %s)", v, arg[k]);
		end
	end
end

function assertNotEqual(expect, arg)
	assert(expect ~= arg, ("Expected not %s, but got %s"):format(expect, arg));
end

local function prepareTestEnvironment(test, ... )
	log("--------------------------------------------------------------------------------")
	log("Running test '%s'", test);
	TestCase = setmetatable({}, TestCasePrototype);
end

function test(description, fn, ...)
	TestCase:addExecution();
	local res, err = pcall(fn, ...);
	if not res then
		TestCase:addError(err);
		print(("Error: %s"):format(err));
	end
end

local function finishTests()
	local t, f, e = TestCase.Executions, TestCase.Failures, TestCase.Errors;
	log("--------------------------------------------------------------------------------")
	log("Tests finished:");
	log("%s tests run, %s failed, %s errors", t or 0, f or 0, e or 0);
	log("\n\n");
end

do
	local types = {
		["string"]   = "STR",
		["table"]    = "TBL",
		["function"] = "FNC",
		["number"]   = "NUM",
		["userdata"] = "USR",
		["boolean"]  = "BOL",
	}
	function printTable(t, ...)
		local i=0;
		if ... then print(...); end
		print(tostring(t).." {");
		for k,v in pairs(t) do
			print("","("..types[type(k)]..") "..tostring(k),"", "("..types[type(v)]..") "..tostring(v));
			i = i+1;
		end
		print("}");
		return i;
	end
end

function inspect(t, rec, ...)
	if type(t) ~= "table" then error("Argument #1 must be a table") end
	if rec ~= nil and type(rec) ~= "number" then error("Argument #2 must be nil or a number") end
	
	rec = rec or 0;
	local indent = ("  "):rep(rec);
	local msg = tostring(t);
	if ... then msg = "["..tostring(...).."]"; end
	
	local sorter = {};
	for k,v in pairs(t) do sorter[#sorter+1] = k; end
	table.sort(sorter, function(a, b)
		local ta, tb = type(a), type(b);
		-- returns true when the first is less than the second
		if ta == tb then
			return a < b;
		elseif ta == "boolean" then
			return true;
		elseif ta == "number" and tb == "string" then
			return true;
		elseif ta == "string" and tb == "number" then
			return false;
		end
		return tostring(a) < tostring(b);
	end);
	
	print(indent..msg.." = {");
	for a,k in ipairs(sorter) do
		if type(t[k]) == "table" then
			inspect(t[k], rec+2, k);
		else
			print(("  "):rep(rec+2).."["..tostring(k).."] = "..tostring(t[k])..",");
		end
	end
	print(indent.."},");
end

-- Run tests given as argument
for _, f in pairs({...}) do
	local t = f:gsub("%.lua$", "");
	prepareTestEnvironment(t);
	require(t);
	finishTests(t);
end
