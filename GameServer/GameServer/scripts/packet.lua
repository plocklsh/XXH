require("pack");

local qxpacket = class("qxpacket");

--=:native endian <:little endian >:big endian default:=
function qxpacket:ctor(endian)
	self._endian = "=";
	if endian then self._endian = endian; end
	self._packetT = {};
	self._pos = 1;
end

function qxpacket:setPos(value)
	self._pos = value;
end

function qxpacket:getLen()
	return #self._packetT;
end

function qxpacket:_insertInToPacketT(value)
	for i=1, #value do
		self._packetT[self._pos] = value:sub(i, i);
		self._pos = self._pos + 1;
	end
end

function qxpacket:_getBytesFromPacketT(len)	
	local value =  table.concat(self._packetT, "", self._pos, self._pos + len - 1)
	self._pos = self._pos + len;
	return value;
end

function qxpacket:writeByte(value)
	self:_insertInToPacketT(string.pack(self._endian .. "b", value));
end

function qxpacket:readByte()
	local _, value = string.unpack(self:_getBytesFromPacketT(1), self._endian .. "b");
	return value;
end

function qxpacket:writeShort(value)
	self:_insertInToPacketT(string.pack(self._endian .. "h", value));	
end

function qxpacket:readShort()
	local _, value = string.unpack(self:_getBytesFromPacketT(2), self._endian .. "h");
	return value;
end

function qxpacket:writeInt(value)
	self:_insertInToPacketT(string.pack(self._endian .. "i", value));
end

function qxpacket:readInt()
	local _, value = string.unpack(self:_getBytesFromPacketT(4), self._endian .. "i");
	return value;
end

--[[	TODO 感觉这个有BUG，由于使用的次数少之又少，所以暂时忽略掉
function qxpacket:writeLong(value)
	self:_insertInToPacketT(string.pack(self._endian .. "l", value));
end

function qxpacket:readLong()
	local _, value = string.unpack(self:_getBytesFromPacketT(8), self._endian .. "l");
	return value;
end
]]

function qxpacket:writeNumber(value)
	self:_insertInToPacketT(string.pack(self._endian .. "f", value));
end

function qxpacket:readNumber()
	local _, value = string.unpack(self:_getBytesFromPacketT(4), self._endian .. "f");
	return value;
end

function qxpacket:writeString(value)
	self:_insertInToPacketT(string.pack(self._endian .. "a", value));
end

function qxpacket:readString()
	local _, strLen = string.unpack(self:_getBytesFromPacketT(4), self._endian .. "I");

	local _, value = string.unpack(self:_getBytesFromPacketT(strLen), self._endian .. "A" .. strLen);
	return value;
end

function qxpacket:setPackSize(value)
	local str = string.pack(self._endian .. "i", value);
	for i=1, #str do
		self._packetT[i] = str:sub(i, i);
	end
end

function qxpacket:getPack()
	return table.concat(self._packetT);
end

function qxpacket:setPack(value)
	assert(type(value) == "string");
	assert(#self._packetT == 0);
	for i=1, value:len() do
		table.insert(self._packetT, value:sub(i, i));
	end
end

return qxpacket;

