--!strict

local attributeGetter = require(script.Parent.attributeGetter)

type cmp<T> = (tLHS: T, tRHS: T) -> boolean

local function subsort<T, U>(sort: cmp<U>, transform: (T) -> U): cmp<T>
	return function(lhs: T, rhs: T)
		return sort(transform(lhs), transform(rhs))
	end
end

local function lt(lhs: number, rhs: number): boolean
	return lhs < rhs
end

local RequireChildren = {}

local getRequirePriority = attributeGetter("RequirePriority", "number", math.huge)
--[[
	Require all of the ModuleScript children of a given container Instance, and
	return the results in an array (numerically-indexed table).
	
	The "RequirePriority" attribute influences the order in which the ModuleScripts
	are required: lowest first, followed by unset (undefined order)
]]
function RequireChildren.AsArray<T>(container: Instance): { T }
	local results: { T } = {}
	local children: { Instance } = container:GetChildren()
	table.sort(children, subsort(lt, getRequirePriority))
	for _, child: Instance in children do
		if child:IsA("ModuleScript") then
			local result = require(child) :: T
			table.insert(results, result)
		end
	end
	return results
end

--[[
	Require all of the ModuleScript children of a given container Instance in an
	arbitrary order, and return the results in a dictionary that maps the name
	of each ModuleScript to its return value.
	
	Raises an error if a subsequent ModuleScript shares a name with an
	already-required module.
]]
function RequireChildren.AsDictionary<T>(container: Instance): { [string]: T }
	local results: { [string]: T } = {}
	for _, child: Instance in container:GetChildren() do
		if child:IsA("ModuleScript") then
			local result = require(child) :: T
			assert(results[child.Name] == nil, "Duplicate ModuleScript with name")
			results[child.Name] = result
		end
	end
	return results
end

return RequireChildren
