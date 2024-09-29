--!strict

type ValuePredicate = string | (value: any) -> (boolean, string?)

local function isValuePredicateSatisfiedBy(valuePredicate: ValuePredicate, value: any): (boolean, string?)
	if typeof(valuePredicate) == "string" then
		local ty = typeof(value)
		if ty == valuePredicate then
			return true, nil
		else
			return false, valuePredicate .. " expected , got " .. ty
		end
	elseif typeof(valuePredicate) == "function" then
		return valuePredicate(value)
	else
		error("invalid satisfaction")
	end
end

--[[
	Helper function for (boolean, string?) return types which need to prefix
	additional information in failure cases or in cases where a failure reason
	was not provided.
]]
local function successPrefix(prefix: string, default: string, b: boolean, s: string?): (boolean, string)
	return b, prefix .. (s or default)
end

--[[
	Returns a function that retrieves attributes from Instances which satisfy some predicate and
	raises an error if the attribute value does not satisfy the predicate.
	
		-- Let's say we're building a model which is a circle	
		-- With a "Radius" attribute:
		local getRadius = attributeGetter("Radius")
		local circleModel: Model = ...
		local radius = getRadius(circleModel)
		
	Enforce a type by providing its name:
	
		local getRadius = attributeGetter("Radius", "number")
		local radius = getRadius(circleModel)
		-- If the attribute's value was a string, that would've raised "Radius invalid: number expected, got string"
	
	Provide a default value to ignore missing attributes:
	
		local getRadius = attributeGetter("Radius", "number", 10)
		local radius = getRadius(circleModel)
	
	Need a more complicated check? Provide a function with this kind of signature:
	(value: any)->(isOk: boolean, reasonWhyNot: string?):
	
		local getRadius = attributeGetter("Radius", function (value: any): (boolean, string?)
			return typeof(value) == "number" and value > 0, "must be positive number"
		end, 10)
	
	Tip: You can use a function from Osyris' t module to keep it simple!
	
		local getRadius = attributeGetter("Radius", t.numberPositive, 10)
	
	The value predicate can be may also be a function which returns (boolean, string?)
		
		local getRadius = attributeGetter("Radius", function (value: any)
			return typeof(value) == "number" and value > 0, "must be positive number"
		end, 10)
		-- If a predicate function doesn't return a string, it says "check failed" instead
	
	Remember, the default value must also satisfy the predicate, if both are given
		
		local getRadius = attributeGetter("Radius", "number", "OOPS!!")
		--> Default value invalid: number expected, got string
	
	You can be explicit with your type annotations:
	
		local getRadius: (Instance)->(number) = attributeGetter("Radius", "number", 10)

]]
local function attributeGetter<T>(
	attributeName: string,
	attributeValuePredicate: ValuePredicate?,
	default: T?
): (instance: Instance) -> T
	-- If a default is provided, it must satisfy the type predicate
	if typeof(attributeValuePredicate) ~= "nil" and typeof(default) ~= "nil" then
		assert(
			successPrefix(
				"Default value invalid: ",
				"check failed",
				isValuePredicateSatisfiedBy(attributeValuePredicate, default)
			)
		)
	end
	return function(instance: Instance): T
		local attributeValueMaybe: T? = instance:GetAttribute(attributeName) :: T?
		local attributeValue: T
		-- Default value
		if typeof(default) ~= "nil" then
			attributeValue = if typeof(attributeValueMaybe) == "nil" then default else attributeValueMaybe
		else
			assert(typeof(attributeValueMaybe) ~= "nil", `{attributeName} missing`)
			attributeValue = attributeValueMaybe
		end
		-- Whether the value is satisfied
		if typeof(attributeValuePredicate) ~= "nil" then
			local satisfied: boolean, reasonWhyNotMaybe: string? =
				isValuePredicateSatisfiedBy(attributeValuePredicate, attributeValue)
			assert(successPrefix(`{attributeName} invalid: `, "check failed", satisfied, reasonWhyNotMaybe))
		end
		return attributeValue
	end
end

do
	local getRadius: (Instance) -> number
	getRadius = attributeGetter("Radius")
	getRadius = attributeGetter("Radius", "number", nil)
	getRadius = attributeGetter("Radius", "number", 10)
	getRadius = attributeGetter("Radius", nil, 10 :: number?)
	local _radius: number = getRadius(script)
end

return attributeGetter
