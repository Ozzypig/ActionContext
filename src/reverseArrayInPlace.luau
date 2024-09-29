--!strict

local function reverseArrayInPlace<T>(array: { T })
	for i = 1, #array / 2 do
		local j = #array - i + 1
		local temp = array[i]
		array[i] = array[j]
		array[j] = temp
	end
end

return reverseArrayInPlace
