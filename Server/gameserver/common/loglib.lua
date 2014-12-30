if not loglib then
    loglib = {};
end

loglib.logstack = {};
loglib.occurredCount = 5;   --记录发生commit的时机，这里指缓存了1条记录就执行commit
loglib.shutDownServerCallBack = nil;	--记录当前是否需要执行关掉服务器的回调函数

-- 例子:loglib.addLog("gold", {field = value}, 回调函数，参数为上一条sql回的id);
loglib.addLog = function(data_name, values, result ,dbname)
    if not dbname then dbname = "dglog" end    
	table.insert(loglib.logstack, {key = data_name, data = values, cbs = result ,logdbname = dbname});
    
    if #loglib.logstack >= loglib.occurredCount then
        loglib.commit();    --执行日志提交
    end
end

loglib.trans_data = function(value)
    if value == nil then value = " "; end
	if type(value) == "table" then
		return toSqlStr(table.tostring(value));
	elseif type(value) == "string" then
        local new_value = ""
        if value == "" or value == nil then
            value = " ";
        end
        if value == "now()" then
            new_value = value;
        else
            new_value = toSqlStr(value);
        end        
		return new_value;
    else
		return tostring(value);
	end
end

--提交日志
loglib.commit = function()
    local log_sqlstack = {};
	for _, log_entry in pairs(loglib.logstack) do
		local fields = "";
		local values = "";
        
        local count = 0;
        local totalCount = 0;
        for k, v in pairs(log_entry.data) do
            totalCount = totalCount + 1;
        end

		for c_field, c_value in pairs(log_entry.data) do
            fields = fields .. "`" .. c_field .. "`";
			values = values .. loglib.trans_data(c_value);
            count = count + 1;
            if count < totalCount then
                fields = fields .. ",";
                values = values .. ",";
            end
		end

		local log_sql = string.format([[insert into %s(%s) values(%s);]], log_entry.key, fields, values);
        local log_item = {log_sql = log_sql, cbs = log_entry.cbs ,dbname = log_entry.logdbname};
        table.insert(log_sqlstack, log_item);
	end
	loglib.logstack = {};

    --TODO选择以哪种方式进行日志保存，暂时直接在gs里，以后可能需要换成发协议，可把log_sqlstack当参数发过去
    loglib.pushSqlInDetail(log_sqlstack);
end

--写入细节日志
loglib.pushSqlInDetail = function(sql_stack)
	--不带回调的合并成一个大的sql	
	local bigSqlStr = "";
	local bigdbname = "";
	for _, sql_item in pairs(sql_stack) do
        if sql_item.cbs == nil then
			bigSqlStr = bigSqlStr .. sql_item.log_sql;			
			bigdbname = sql_item.dbname;			
		else
			loglib.executeOneSql(sql_item.log_sql, sql_item.dbname, sql_item.cbs);
		end
    end
	if bigSqlStr ~= "" then
		loglib.executeOneSql(bigSqlStr, bigdbname);
	end
end

loglib.executeOneSql = function(sqlstr, dbname, cbs)
	dblib.execsql(sqlstr, function(dt)
		if dt.ret == 1 and dt.eff_row > 0 then
			TraceError(_U"日志sql插入成功1");
			if cbs ~= nil then
				cbs(dt.eff_row);
				cbs = nil;				
			end						
		else
			if dt.ret ~= 1 then
				TraceError(_U"日志sql插入失败:" .. sqlstr);
			else
				TraceError(_U"日志sql插入成功2");
			end
		end			
	end, dbname);
end

loglib.forceCommit = function()
	if #loglib.logstack > 0 then
		loglib.commit();
	end
end
