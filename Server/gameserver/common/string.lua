--看是否存在除了数字和英文字母外的其他字符
function string.checkOtherChar(str)
    local len = str:len()
	for i = 0, len do
		local a = string.byte(str, i, i);
		if a ~= nil then
			if (a > 47 and a < 58) or (a > 96 and a < 123) or (a > 64 and a < 91) then    --0~9  小写字母 大写字母
            else
                return 1
			end
		end
	end
    return 0
end 


function hex(s)
    local hexStr = string.gsub(s, "(.)", function(x) 
		return string.format("%02X",string.byte(x));
	end);
    return hexStr or "";
end

function toSqlStr(s)
	if type(s) ~= "string" then return s; end
	return "0x" .. hex(s);
end

function split(s, delim)
	assert (type (delim) == "string" and string.len (delim) > 0,"bad delimiter")
	local start = 1  local t = {}
	while true do
		local pos = string.find (s, delim, start, true) -- plain find
		if not pos then
			break
		end
		table.insert (t, string.sub (s, start, pos - 1))
		start = pos + string.len (delim)
	end
	table.insert (t, string.sub (s, start))
	return t
end
