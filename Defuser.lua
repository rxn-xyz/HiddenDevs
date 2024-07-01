local defuser = {}

defuser.operations = {
	["+"]  = function(x, y) return x + y end,
	["-"]  = function(x, y) return x - y end,
	["*"]  = function(x, y) return x * y end,
	["/"]  = function(x, y) return x / y end,
	[">"]  = function(x, y) return x > y end,
	["<"]  = function(x, y) return x < y end,
	[">="] = function(x, y) return x >= y end,
	["<="] = function(x, y) return x <= y end,
	["=="] = function(x, y) return x == y end
}

function defuser.interval(interval, number)
	if interval:find("[><=]=?") then
		interval    = {interval:match("([><=]=?)%D*(%d+[.]?%d*)")}
		number      = tonumber(number)
		interval[2] = tonumber(interval[2])
		return defuser.operations[interval[1]](number, interval[2])
	end
	interval = {interval:match("([%[%(])(%d+[.]?%d*)%D*(%d+[.]?%d*)([%]%)])")}
	local min_operator = (interval[1] == "[" and ">=" or ">")
	local max_operator = (interval[4] == "]" and "<=" or "<")
	number      = tonumber(number)
	interval[2] = tonumber(interval[2])
	interval[3] = tonumber(interval[3])
	return defuser.operations[min_operator](number, interval[2]) and defuser.operations[max_operator](number, interval[3])
end

function defuser.list(dictionary)
	local array = {}
	for index ,_ in dictionary do
		table.insert(array, index)
	end
	return array
end

function defuser.strip(input, exclusions, length)
	local output = input:gsub(".", function(character)
		for _, exclusion in exclusions do
			if character:match(exclusion) then
				return character
			end
		end
		return ""
	end)
	return #output == length and output or nil
end

function defuser.wires(input)
	local wires = {
		["1"] = {{"r", true}, {"g", true}, {"b", true}, {"y", true}, {"none"}},
		["3"] = {{"r", false}, {"w", true}, {"b", true}},
		["4"] = {{"g", false}, {"b", false}, {"w", false}, {"none"}}
	}
	input = input:gsub("%A", "")
	local result
	for index, wire in wires[tostring(#input)] do
		if not result and (input:find(wire[1]) ~= nil) == wire[2] then
			result = index
		end
	end
	return result or #wires[tostring(#input)]
end

function defuser.hexadecimal(input)
	return (input:gsub("%S%S", function(hex)
		return string.char(tonumber(hex, 16)::number)
	end):gsub(" ", ""))
end

function defuser.keypad(input)
	local matches = {}
	for match in input:gmatch("(%d%d?)") do
		table.insert(matches, match)
	end
	local intervals = {
		["none"]     = {{"+", 10}, {"-", 10}, {"+", 0}, {"*", 3}},
		["< 10"]     = {{"+", 15}, {"+", 10}, {"*", 2}, {"*", 2}},
		["(10, 20)"] = {{"+", 20}, {"*", 2}, {"*", 3}, {"+", 20}},
		["(20, 80)"] = {{"+", 30}, {"*", 3}, {"-", 5}, {"+", 50}}
	}
	local x, y, z = 0, 0, 0
	for index, match in matches do
		local action
		for interval, actions in intervals do
			if not action and interval ~= "none" and defuser.interval(interval, match) then
				action = actions[index]
			end
		end
		action = (not action and intervals.none[index] or action)
		x  = defuser.operations[action[1]](x, action[2])
		y += (match / 2)
		z  = (x - y)
	end
	local orders = {
		["<= 0"]        = "TL TR BL BR",
		["[0.5, 19.5]"] = "TL TR BR BL",
		["[20, 49.5]"]  = "BR BL TR TL",
		["[50, 89.5]"]  = "BL TL BR TR",
		[">= 90"]       = "TR BL TL BR"
	}
	for interval, order in orders do
		if defuser.interval(interval, z) then
			return order
		end
	end
end

function defuser.binary(input)
	local matches = {
		"^0+$",
		"^.1....0$",
		"^11.....$",
		"^0.....0$",
		"nil",
		"nil",
		".*(0).*(0).*(0).*(0).*",
		".*(1).*(1).*(1).*(1).*(1).*(1).*",
	}
	input = defuser.strip(input, {"[01]"}, 7)
	for index, match in matches do
		if input:gsub(" ", ""):match(match) then
			return index
		end
	end
	return 10
end

function defuser.mathematics(input)
	local letters = {
		["a"] = 1, ["b"] = 3, ["c"] = 7, ["d"] = 2, ["e"] = 4, 
		["f"] = 5, ["g"] = 6, ["h"] = 0, ["i"] = 8, ["j"] = 9
	}
	input = defuser.strip(input, defuser.list(letters), 4):split("")
	return ((letters[input[1]] * 10) + letters[input[2]]) * ((letters[input[3]] * 10) + letters[input[4]])
end

function defuser.colorcode(input)
	
	for index, value in input do
		input[index] = value:gsub("[%A%s]", ""):split("")
	end
	local totals = {0, 0}
	local values = {
		["r"] = {0, 1},
		["g"] = {0, 3},
		["b"] = {1, 2},
		["y"] = {2, 3},
		["w"] = {3, 4}
	}
	for index, colors in input do
		for _, color in colors do
			totals[index] += values[color][index]
		end
	end
	local total = totals[2] - totals[1]
	return total >= 0 and total or 0
end

function defuser.timing(input)
	local letters = {
		["a"] = 4, ["b"] = 3, ["c"] = 7, ["d"] = 9
	}
	input = {input:lower():gsub("[^%d%a]",""):match("(%d%d)(%a%a)")}
	input[1] = input[1]:split("")
	input[1] = input[1][1] + input[1][2]
	input[2] = input[2]:split("")
	input[2] = letters[input[2][1]] + letters[input[2][2]]
	local intervals = {
		["[0, 59]"]    = "white",
		["[60, 99]"]   = "red",
		["[100, 199]"] = "yellow",
		["[200, 299]"] = "green",
		["[300, 399]"] = "blue",
		["[400, 499]"] = "yellow",
		["[500, 599]"] = "red",
		[">= 600"] = "white"
	}
	for interval, color in intervals do
		if defuser.interval(interval, input[1] * input[2]) then
			return color
		end
	end
end

function defuser.tiles(input)
	local colors = {
		["r"] = 1,
		["g"] = 9,
		["b"] = 7,
		["y"] = 2,
		["p"] = 6,
		["w"] = 5
	}
	input = input:lower():gsub("%A",""):match("(%a%a)"):split("")
	return colors[input[1]] + colors[input[2]]
end

function defuser.serial(input)
	return input
end

function defuser.find(input)
	input = {pcall(function()
		local skips = {"operations", "interval", "call"}
		for module in defuser do
			if input:gsub("%A", "") ~= "" and not table.find(skips, module) and module:match(input:lower()) then
				return module
			end
		end
	end)}
	return (input[1] or defuser[input[2]]) and input[2] or "invalid module"
end

function defuser.call(input, ...)
	input = defuser.find(input)
	if not defuser[input] then return input end
	local arguemnts = ...
	local results = {pcall(function() return defuser[input](arguemnts) end)}
	return (results[1] and results[2] or "invalid input")
end

return defuser
