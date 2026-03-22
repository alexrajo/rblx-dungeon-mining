local formatter = {
	suffixes = {"k", "M", "B", "T", "qD", "qT", "sT"},
	decimals = 2
}

function formatter:GetFormattedLargeNumber(num)
	local scale = 1
	for i = #self.suffixes, 1, -1 do
		scale = 1000^i
		if num < scale then continue end

		return tostring(math.floor(num/scale*10^self.decimals)/10^self.decimals)..self.suffixes[i]
	end
	return tostring(math.floor(num*100)/100)
end

function formatter.SplitTime(seconds)
	local h = math.floor(seconds/3600)
	local m = math.floor((seconds-h*3600)/60)
	local s = seconds-h*3600-m*60

	return h, m, s
end

function formatter:GetFormattedTime(seconds): string
	local h, m, s = self.SplitTime(seconds)
	h = h > 9 and h or "0"..h
	m = m > 9 and m or "0"..m
	s = s > 9 and s or "0"..s
	return h..":"..m..":"..s
end

function formatter:GetFormattedMinutesAndSeconds(seconds): string
	local h, m, s = self.SplitTime(seconds)
	m += h*60
	
	m = m > 9 and m or "0"..m
	s = s > 9 and s or "0"..s
	return m.."m "..s.."s"
end

function formatter.ZeroPrefixNumber(num: number, numLength: number): string
	local currentNumLength = #tostring(num)
	if currentNumLength == numLength then return tostring(num) end
	if currentNumLength > numLength then return nil end
	
	local finalString = tostring(num)
	for i = 1, numLength-currentNumLength do
		finalString = "0"..finalString
	end
	
	return finalString
end

return formatter
