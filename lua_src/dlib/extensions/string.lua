
-- Copyright (C) 2017-2018 DBot

-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at

--     http://www.apache.org/licenses/LICENSE-2.0

-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

local gstring = _G.string
local string = DLib.module('string', 'string')
local unpack = unpack
local os = os
local select = select
local math = math
local table = table

function gstring.formatname(self)
	return self:sub(1, 1):upper() .. self:sub(2)
end

function gstring.formatname2(self)
	return self:sub(1, 1):upper() .. self:sub(2):replace('_', ' ')
end

function string.tformat(time)
	if time > 0xFFFFFFFFF then
		return 'Way too long'
	end

	local str = ''

	local ages = (time - time % 0xBBF81E00) / 0xBBF81E00
	time = time - ages * 0xBBF81E00

	local years = (time - time % 0x01E13380) / 0x01E13380
	time = time - years * 0x01E13380

	local weeks = (time - time % 604800) / 604800
	time = time - weeks * 604800

	local days = (time - time % 86400) / 86400
	time = time - days * 86400

	local hours = (time - time % 3600) / 3600
	time = time - hours * 3600

	local minutes = (time - time % 60) / 60
	time = time - minutes * 60

	local seconds = math.floor(time)

	if seconds ~= 0 then
		str = seconds .. ' seconds'
	end

	if minutes ~= 0 then
		str = minutes .. ' minutes ' .. str
	end

	if hours ~= 0 then
		str = hours .. ' hours ' .. str
	end

	if days ~= 0 then
		str = days .. ' days ' .. str
	end

	if weeks ~= 0 then
		str = weeks .. ' weeks ' .. str
	end

	if years ~= 0 then
		str = years .. ' years ' .. str
	end

	if ages ~= 0 then
		str = ages .. ' ages ' .. str
	end

	return str
end

function string.qdate(time)
	return os.date('%H:%M:%S - %d/%m/%Y', time)
end

string.HU_IN_M = 40
string.HU_IN_CM = string.HU_IN_M / 100

function string.ddistance(z, newline, from)
	if newline == nil then
		newline = true
	end

	local delta

	if from then
		delta = from - z
	else
		delta = LocalPlayer():GetPos().z - z
	end

	if delta > 200 and not newline then
		return string.fdistance(delta) .. ' lower'
	end

	if delta > 200 and newline then
		return '\n' .. string.fdistance(delta) .. ' lower'
	end

	if -delta > 200 and not newline then
		return string.fdistance(delta) .. 'upper'
	end

	if -delta > 200 and newline then
		return '\n' .. string.fdistance(delta) .. 'upper'
	end

	return ''
end

function string.fdistance(m)
	return string.format('%.1fm', m / string.HU_IN_M)
end

function string.niceName(ent)
	if not IsValid(ent) then return '' end
	if ent.Nick then return ent:Nick() end
	if ent.PrintName and ent.PrintName ~= '' then return ent.PrintName end
	if ent.GetPrintName then return ent:GetPrintName() end
	return ent:GetClass()
end

function string.split(stringIn, explodeIn, ...)
	return string.Explode(explodeIn, stringIn, ...)
end

-- fuck https://github.com/Facepunch/garrysmod/pull/1176
string.StartsWith = string.StartWith
gstring.StartsWith = gstring.StartWith

for k, v in pairs(gstring) do
	gstring[k:sub(1, 1):lower() .. k:sub(2)] = v
end

function string.bchar(...)
	local bytes = select('#', ...)

	if bytes < 800 then
		return string.char(...)
	end

	local input = {...}
	local output = ''
	local i = -799

	::loop::
	i = i + 800

	output = output .. string.char(unpack(input, i, math.min(i + 799, bytes)))

	if i + 799 < bytes then
		goto loop
	end

	return output
end

function string.bcharTable(input)
	local bytes = #input
	if bytes == 0 then return '' end

	if bytes < 800 then
		return string.char(unpack(input))
	end

	local output = ''
	local i = -799

	::loop::
	i = i + 800

	local status, output2 = pcall(string.char, unpack(input, i, math.min(i + 799, bytes)))

	if not status then
		for i2 = i, math.min(i + 799, bytes) do
			if input[i2] < 0 or input[i2] > 255 then
				error(output2 .. ' (' .. input[i2] .. ')')
			end
		end
	end

	output = output .. output2

	if i + 799 < bytes then
		goto loop
	end

	return output
end

function string.bbyte(strIn, sliceStart, sliceEnd)
	local strLen = #strIn
	local delta = sliceEnd - sliceStart

	if delta < 800 then
		local i = sliceStart - 1
		local output = {}

		::loop1::
		i = i + 1

		table.insert(output, strIn:byte(i, i))

		if i < sliceEnd then
			goto loop1
		end

		return output
	end

	local output = {}

	local i = sliceStart - 1

	::loop::
	i = i + 1

	table.insert(output, strIn:byte(i, i))

	if i < sliceEnd then
		goto loop
	end

	return output
end

return string
