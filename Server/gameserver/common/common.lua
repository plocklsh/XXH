function tostringex(v, len)
	if len == nil then len = 0 end
	local pre = string.rep('\t', len)
	local ret = ""
	if type(v) == "table" then
		if len > 5 then return "\t{ ... }" end
		local t = ""
		local keys = {}
		for k, v1 in pairs(v) do
			table.insert(keys, k)
		end
		--table.sort(keys)
		for k, v1 in pairs(keys) do
			k = v1
			v1 = v[k]
			t = t .. "\n\t" .. pre .. tostring(k) .. ":"
			t = t .. tostringex(v1, len + 1)
		end
		if t == "" then
			ret = ret .. pre .. "{ }\t(" .. tostring(v) .. ")"
		else
			if len > 0 then
				ret = ret .. "\t(" .. tostring(v) .. ")\n"
			end
			ret = ret .. pre .. "{" .. t .. "\n" .. pre .. "}"
		end
	else
		ret = ret .. pre .. tostring(v) .. "\t(" .. type(v) .. ")"
	end
	return ret
end

TraceError = function(e)
	if type(e) == "table" then
		print(tostringex(e))
	else
		print(tostring(e))
	end
end

function __G__TRACKBACK__(errorMessage)
    print("ERROR: " .. tostring(errorMessage) .. "\n")
    print(debug.traceback())
end

NULL_FUNC = NULL_FUNC or function() end

function pcall_ex(f, arg1, ...)
	local ret, einfo = pcall(f, arg1, ...);
	if not ret then print(einfo .. " " .. debug.traceback()); end
end

local EventProtocol = require("common.EventProtocol");
eventlib = {};
EventProtocol.extend(eventlib);

function throw()
	print(debug.traceback())
end

function isHitByRate(rate, nMax)
	nMax = nMax or 1000000
	local num = math.random(1,nMax)
	local count = rate*nMax
	if num < count then return true end 
	return false
end

--获取直接与圆的交点
--y=k*x+c	直线方程
--r*r = a*a + b*b;	圆方程
--precision=精确度
function getLineXCirclePoint(k, c, a, b, r, precision)
	local ret = {};
	for i=0, 1 do
		local s = i == 0 and -r or r;
		local x = a + s;
		local x1 = a + s;
		local delta = 0;
		local first = true;
		for j=1, 1000 do	--循环1000次
			x = x1;
			local fx = (1 + k * k) * x * x + 2 * (k * c - a - b) * x + (c - b) * (c - b) + a * a - r * r;
			local dfx = 2 * (1 + k * k) * x + 2 * (k * c - a - b);
			x1 = x - fx / dfx;
			if not first and delta < ((x1 - x) >= 0 and (x1 - x) or -(x1 - x)) then
				break; --没有根
			end
			first = false;
			delta = (x1 - x) >= 0 and (x1 - x) or -(x1 - x);
			if (delta <= precision) then break; end
		end

		if (delta < precision) then
			local xx = x;
			local yy = k * x + c;

			table.insert(ret, {x=xx, y=yy});
		end
	end
	return ret;
end

--point1 = {x=1, y=2} 第一个点 point2=第二个点 point3=圆心坐标 r=半径
function get2pointXCircle(point1, point2, point3, r)
	local k = (point1.y - point2.y) / (point1.x - point2.x);
	local c = point1.y - k * point1.x;
	return getLineXCirclePoint(k, c, point3.x, point3.y, r, 0.000001);
end

--TraceError(get2pointXCircle({x=1, y=1}, {x=2, y=0}, {x=3, y=3}, 3));

--禁止使用不声明的全局变量
function disable_global()
	setmetatable(_G, {
		__newindex = function (_, n, v)
			rawset(_G, n, v);
			print(_U"赋值失败，未定义全局变量：" .. tostring(n) .. "\r\n" .. debug.traceback());
		end,
		__index = function (_, n)
			print(_U"读取变量失败，未定义全局变量：" .. tostring(n) .. "\r\n" .. debug.traceback());
		end,
	});
end

--声明全局变量
function declare_global(name, initval)
	if rawget(_G, name) then
		print(_U"变量重复定义：" .. tostring(name) .. "\r\n" .. debug.traceback());
	end
	rawset(_G, name, initval);
end

function enable_global()
	setmetatable(_G, {});
end

enable_global();
