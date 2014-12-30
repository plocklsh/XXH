configlib = configlib or 
{
	rootPath = "settings/",
};

function configlib.loadTabFile(szFileName, index1, index2)
	if not szFileName:find(configlib.rootPath) then
		szFileName = configlib.rootPath .. szFileName;
	end	
    local file_f = io.open(szFileName, "r")
	if file_f == nil then 
		print("file_f nil:" .. szFileName)
		return {}
	end 
	local file =  file_f:read("*a"); 
    file_f:close()

	if not file then
		print("no file:" .. szFileName)
		return {}
    end
	
	local tab_data = {}
	local nLine = 1
	local keys = {}
	local szMatch = "([^\n]*)\n"

	for szLine in string.gmatch(file, szMatch) do
		if nLine == 1 then
			for key in string.gmatch(szLine .. "\t", "([^\t]*)\t") do
				table.insert(keys, key)
            end
		else
			local index = 1
			local line_data = {}
			for value in string.gmatch(szLine .. "\t", "([^\t]*)\t") do
				--判断类型优化
				local fstr = string.sub(keys[index],1,1)
				if fstr == "n" then--int
					if value and not tonumber(value) then TraceError(szFileName..":"..keys[index] .. "(" .. tostring(nLine) .. ")" .._U"不是number:" .. tostring(_U(value))) end 
					line_data[keys[index]] = value and tonumber(value) or 0
				elseif fstr == "s" then--string
					line_data[keys[index]] = value and tostring(value) or ""
				elseif fstr == "t" then--table					
					if value == nil or value == "" then value = "{}"; end
					line_data[keys[index]] = table.loadstring(value)
				elseif fstr == "_" then--策划字段，不用读
					line_data[keys[index]] = nil
				else	 
					TraceError(_U"读取配置表出错，" ..szFileName .. _U" 配置表字段类型未确认:" .. keys[index])
					return 
				end
				index = index + 1
			end
			if not index1 and not index2 then
				table.insert(tab_data, line_data)
			elseif index1 then
				local index1Name = line_data[index1];
				if not index1Name then assert(false,szFileName); end
				if not index2 then
					if tab_data[index1Name] then assert(false, _U"重复的索引！！！！index1Name=" .. tostring(index1Name) .. ", filename=" .. tostring(szFileName)); end
					tab_data[index1Name] = line_data;
				else
					if not tab_data[index1Name] then tab_data[index1Name] = {}; end
					local index2Name = line_data[index2];
					if not index2Name then assert(false); end
					if tab_data[index1Name][index2Name] then assert(false, _U"重复的索引！！！！index2Name=" .. tostring(index2Name) .. ", filename=" .. tostring(szFileName)); end
					tab_data[index1Name][index2Name] = line_data;
				end
			end
		end
		
		nLine = nLine + 1
    end

	return tab_data	
end
