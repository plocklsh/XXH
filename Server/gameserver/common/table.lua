table.loadstring = function(strData)
	if strData == nil or strData == "" then
		TraceError(_U"loadstring参数为nil 或者空的字串:<"..tostring(strData)..">"..debug.traceback())
		return {}
	end
	local f = loadstring("do local ret=" .. strData ..  " return ret end")
	if f then
		return f() or {}
    else
        return {}
	end
end

table.tostring = function(t)
	local mark={}
	local assign={}
	local ser_table 
	if type(t) ~= "table" then
		--TraceError("tostring参数为nil 或者空的字串:<"..tostring(t)..">"..debug.traceback())
		return "{}"
	end
    ser_table = function (tbl,parent)
		mark[tbl]=parent
		local tmp={}
		for k,v in pairs(tbl) do
			local key= type(k)=="number" and "["..k.."]" or "[".. string.format("%q", k) .."]"
			if type(v)=="table" then
				local dotkey= parent.. key
				if mark[v] then
					table.insert(assign,dotkey.."="..mark[v])
				else
					table.insert(tmp, key.."="..ser_table(v,dotkey))
				end
			elseif type(v) == "string" then
				table.insert(tmp, key.."=".. string.format('%q', v))
			elseif type(v) == "number" or type(v) == "boolean" then
				table.insert(tmp, key.."=".. tostring(v))
			end
		end
		return "{"..table.concat(tmp,",").."}"
	end
	if #assign > 0 then
		print(_U("table存在循环引用，这很危险!!!") .. debug.traceback())
	end
    return ser_table(t,"ret")..table.concat(assign," ")
end

MAX_COPY_LAY = 7;
deepcopy = function(tbSrc, nMaxLay)
	nMaxLay = nMaxLay or MAX_COPY_LAY;
	if (nMaxLay <= 0) then
		error("Error: DeepCopy拷贝的层数操作最大层，检查是否有循环引用");
		return;
	end
	
	local tbRet = {};
	for k, v in pairs(tbSrc) do
		if (type(v) == "table") then
			tbRet[k] = deepcopy(v, nMaxLay-1);
		else
			tbRet[k] = v;
		end
	end
	
	return tbRet;
end

table.clone = deepcopy

-- 随机打乱一个连续的，从1开始Table, 注意,没有返回值,直接对目标数组进行操作
table.disarrange = function(tb)
	local nLen	= #tb;
	for n, value in pairs(tb) do
		local nRand = math.random(1, nLen);
		tb[n]		= tb[nRand];
		tb[nRand]	= value;
	end
end;


--交换table中的两个key
table.swap = function(ref_table, key1, key2)
	local tmp = ref_table[key1]
	ref_table[key1] = ref_table[key2]
	ref_table[key2] = tmp
end

--判断是否包含某个值,包含则返回key
table.finditemkey = function(tbl, value)
	for k, v in pairs(tbl) do
		if v == value then
			return k
		end
	end
	return
end

--找出一个table中的最值
table.findtop = function(ref_tbl, rulefunc)
	local topitem
	if not rulefunc then
		rulefunc = function(a, b) return a < b end
	end
	for k, v in pairs(ref_tbl) do
		if not topitem then
			topitem = v
		else
			if rulefunc(v, topitem) then
				topitem = v
			end
		end
	end
	return topitem
end


--合并数组
table.mergearray = function(...)
	local ret = {}
	for k, v in pairs({...}) do
		for k1, v1 in pairs(v) do
			table.insert(ret, v1)
		end
	end
	return ret
end

table.getItemCount = function(list)
	local count = 0
	for k,v in pairs(list) do
		count = count + 1
	end
	return count
end
table.removeFromTable = function(ref_table,item)
	for k,v in pairs(ref_table) do
		if v == item then table.remove(ref_table,k) end
	end
end

