local callbacks = {};

function callbacks.onlytoken(token, ...)
	return token;
end

function callbacks.onlychar(token, char, ...)
	return char;
end

function callbacks.tokenchar(token, char, ...)
	return {token, char};
end

function callbacks.pretty(str)
	return function(token, char, ln1, ln2, pos1, pos2, ...)
		if token ~= char and token ~= "NEWLINE" then
			return ("%s [%s] {%s}"):format(token, char, str:sub(pos1, pos2));
		else
			return token;
		end
	end
end

return callbacks;
