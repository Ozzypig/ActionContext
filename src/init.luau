--!strict
--[=[
	@class ActionContext
	An ActionContext object, also known as just a context, represents a situation in which
	the player may take actions by performing input. An action is represented by a table
	with `ActionName`, `Inputs` and a `Handle` callback:

	```lua
	local honkAction = {
		ActionName = "Honk",
		Inputs = { Enum.KeyCode.H },
		Handle = function (userInputState: Enum.UserInputState, inputObject: InputObject)
			if userInputState == Enum.UserInputState.Begin then
				sound:Play() -- BEEP!
			end
			-- (Returning nothing here or nil implies
			-- returning Enum.ContextActionResult.Sink, see
			-- docs for ContextActionService:BindAction)
		end,
	}
	```

	Actions like as these are passed in a table to Context.new:

	```lua
	local carContext = ActionContext.new({ honkAction })
	```

	Finally, the context is entered then left at the appropriate time:

	```lua
	-- Player gets in the car:
	carContext:Enter()

	-- Player exits the car:
	carContext:Leave()
	```

	Now the player can honk the horn when they are sitting in the car!

	The Context library also provides some convenience functions for the creation of simple actions,
	like those of one-off key commands:

	```lua
	ActionContext.new({
		ActionContext.actionBegin("Honk", { Enum.KeyCode.H }, function () sound:Play() end)
	}):Enter()
	```

	Got a lot of actions? Organize them into ModuleScripts inside a container:


	```lua
	ActionContext.fromChildren(container):Enter()
	```

	Using Context:CreateBindAction, it becomes easy to to create input chords. Using this method,
	doing one action causes another context to be entered. For example, holding Ctrl enters a
	context in which C and V can be pressed, which is ultimately a Ctrl+C and Ctrl+V sequence:

	```lua
	local innerContext = ActionContext.new({
		-- in this context, we're holding Ctrl
		ActionContext.actionBegin("Copy", { Enum.KeyCode.C }, function () print("Copied") end),
		ActionContext.actionBegin("Paste", { Enum.KeyCode.V }, function () print("Pasted") end),
	})
	local outerContext = ActionContext.new({
		-- While holding either Control key, the innerContext is entered/left.
		innerContext:CreateBindAction("ControlChord", { Enum.KeyCode.LeftControl, Enum.KeyCode.RightControl }),
	})
	outerContext:Enter()
	```

	It may be helpful to name `Context` objeccts after the game state in which they are relevant.
	In the above example, `outerContext` might be renamed to `textEditorContext`, and the `innerContext` might be
	renamed to `ctrlContext`.
]=]

local ContextActionService: ContextActionService = game:GetService("ContextActionService")

local RequireChildren = require(script.RequireChildren)

--[[
	Helper function. Reverses an array in place.
]]
local function reverseArrayInPlace<T>(array: { T })
	for i = 1, #array / 2 do
		local j = #array - i + 1
		local temp = array[i]
		array[i] = array[j]
		array[j] = temp
	end
end

--[=[
	@type UserInput Enum.UserInputType | Enum.KeyCode
	@within ActionContext
	An enum suitable for use with [ContextActionService:BindAction].
]=]
export type UserInput = Enum.UserInputType | Enum.KeyCode

--[=[
	@type HandleCallback (userInputState: Enum.UserInputState, inputObject: InputObject) -> Enum.ContextActionResult?
	@within ActionContext
	An action handler callback which processes arguments that come from [ContextActionService:BindAction].
]=]
export type HandleCallback = (
	userInputState: Enum.UserInputState,
	inputObject: InputObject
) -> Enum.ContextActionResult?
--| ((userInputState: Enum.UserInputState, inputObject: InputObject) -> ())

--[=[
	@type HandleInputObjectCallback (inputObject: InputObject) -> Enum.ContextActionResult?
	@within ActionContext
	A simpler action handler callback which processes arguments that come from [ContextActionService:BindAction],
	with the assumption that a particular UserInputState is desired.
	Used with [ActionContext.action], [ActionContext.actionBegin], and [ActionContext.actionEnd].
]=]
export type HandleInputObjectCallback = (inputObject: InputObject) -> Enum.ContextActionResult?
--| ((inputObject: InputObject)->())

--[=[
	@type ActionHandler { ActionName: string, Inputs: { UserInput }, Handle: HandleCallback, }
	@within ActionContext
	A table describing a single action to be bound/unbound with [ContextActionService:BindAction]/
	[ContextActionService:UnbindAction].
]=]
export type ActionHandler = {
	ActionName: string,
	Inputs: { UserInput },
	Handle: HandleCallback,
}

export type ActionContextImpl = {
	__index: ActionContextImpl,

	-- Exposed dependencies
	RequireChildren: typeof(RequireChildren),
	reverseArrayInPlace: typeof(reverseArrayInPlace),

	-- Class static functions

	new: (actionHandlers: { ActionHandler }) -> ActionContext,
	fromChildren: (instance: Instance) -> ActionContext,
	action: (
		actionName: string,
		userInputState: Enum.UserInputState,
		inputs: { UserInput },
		callback: HandleInputObjectCallback
	) -> ActionHandler,
	actionBegin: (actionName: string, inputs: { UserInput }, callback: HandleInputObjectCallback) -> ActionHandler,
	actionEnd: (actionName: string, inputs: { UserInput }, callback: HandleInputObjectCallback) -> ActionHandler,

	-- Object methods

	Enter: (self: ActionContext) -> (),
	Bind: (self: ActionContext) -> (), -- alias for Enter

	Leave: (self: ActionContext) -> (),
	Unbind: (self: ActionContext) -> (), -- alias for Leave

	CreateBindAction: (self: ActionContext, actionName: string, inputs: { UserInput }) -> ActionHandler,

	HandleAction: (
		self: ActionContext,
		actionName: string,
		userInputState: Enum.UserInputState,
		inputObject: InputObject
	) -> Enum.ContextActionResult?,
}

export type ActionContext = typeof(setmetatable(
	{} :: {
		-- Object fields
		_bound: boolean,
		ActionHandlers: { ActionHandler },
		_actionHandlersByName: { [string]: ActionHandler },
	},
	{} :: ActionContextImpl
))

local ActionContext: ActionContextImpl = {} :: ActionContextImpl
ActionContext.__index = ActionContext
ActionContext._VERSION = "1.0.0"
ActionContext.reverseArrayInPlace = reverseArrayInPlace
ActionContext.RequireChildren = RequireChildren

--[=[
	Create a new `ActionContext` with actions from ModuleScripts within
	a given container instance. These ModuleScripts are expected
	to return tables which are ActionHandlers.

	Modules are required in ascending order of the RequirePriority
	attribute, if defined, then followed by unset priority modules
	in an undefined order.

	After requiring, the array of actions is reversed, causing the
	higher priority modules' actions to be bound after the
	lower priority modules' actions. This means that their action
	handlers take priority if they share inputs.
]=]
function ActionContext.fromChildren(instance: Instance): ActionContext
	local actionHandlers: { ActionHandler } = RequireChildren.AsArray(instance)
	reverseArrayInPlace(actionHandlers)
	local actionContext: ActionContext = ActionContext.new(actionHandlers)
	return actionContext
end

--[=[
	Create an action handler of a given name which runs a callback
	on a particular input and desired user input state. The handler sinks
	all other inputs. Useful for one-shot key commands.

	```lua
	ActionContext.new({
		ActionContext.action("Honk", Enum.UserInputState.Begin, { Enum.KeyCode.H }, function () sound:Play() end)
	}):Enter()
	```
]=]
function ActionContext.action(
	actionName: string,
	desiredUserInputState: Enum.UserInputState,
	inputs: { UserInput },
	callback: HandleInputObjectCallback
): ActionHandler
	return {
		ActionName = actionName,
		Inputs = inputs,
		Handle = function(userInputState: Enum.UserInputState, inputObject: InputObject): Enum.ContextActionResult?
			if userInputState == desiredUserInputState then
				callback(inputObject)
			end
			return Enum.ContextActionResult.Sink
		end,
	}
end

--[=[
	A shortcut for [ActionContext.action] with Enum.UserInputState.Begin

	```lua
	ActionContext.new({
		ActionContext.actionBegin("Honk", { Enum.KeyCode.H }, function () sound:Play() end)
	}):Enter()
	```

	Warning: Don't combine with ActionContext.actionEnd, as the underlying
	ActionContext.action sinks all other input states. Even if both actions
	used different names for the same input (also not recommended),
	the latter action will take priority and sink inputs before they
	reach the formerly bound action. If you need to handle multiple
	user input states, use ActionContext.action once i.e. bind only one action.
]=]
function ActionContext.actionBegin(
	actionName: string,
	inputs: { UserInput },
	callback: HandleInputObjectCallback
): ActionHandler
	return ActionContext.action(actionName, Enum.UserInputState.Begin, inputs, callback)
end

--[=[
	Same as [ActionContext.actionBegin], except for Enum.UserInputState.End
]=]
function ActionContext.actionEnd(
	actionName: string,
	inputs: { UserInput },
	callback: HandleInputObjectCallback
): ActionHandler
	return ActionContext.action(actionName, Enum.UserInputState.Begin, inputs, callback)
end

--[=[
	Creates a new [ActionContext] object with the given action handlers.
]=]
function ActionContext.new(actionHandlers: { ActionHandler }): ActionContext
	local self = {}
	self._bound = false
	self.ActionHandlers = actionHandlers

	-- Create name mapping
	local actionHandlersByName: { [string]: ActionHandler } = {}
	for _, handler in self.ActionHandlers do
		actionHandlersByName[handler.ActionName] = handler
	end
	self._actionHandlersByName = actionHandlersByName

	return setmetatable(self, ActionContext)
end

--[=[
	Call this when the player enters the gameplay situation in which 
	this context's actions should become available.

	Emits a warning when called repeatedly without Leaving ([ActionContext:Leave]) first.
]=]
function ActionContext:Enter()
	if self._bound then
		warn("Already bound")
	end
	for _, handler: ActionHandler in self.ActionHandlers do
		ContextActionService:BindAction(handler.ActionName, function(...)
			return self:HandleAction(...)
		end, false, table.unpack(handler.Inputs))
	end
	self._bound = true
end

--[=[
	Alias for [ActionContext:Enter].
	@method Bind
	@within ActionContext
]=]
ActionContext.Bind = ActionContext.Enter

--[=[
	Call this when the player leaves the gameplay situation in which
	this context's actions were available.

	Emits a warning when called without having called Enter ([ActionContext:Enter]) first.
]=]
function ActionContext:Leave()
	if not self._bound then
		warn(`Context: Not bound`)
	end
	for _, handler: ActionHandler in self.ActionHandlers do
		ContextActionService:UnbindAction(handler.ActionName)
	end
	self._bound = false
end

--[=[
	Alias for [ActionContext:Leave].
	@method Unbind
	@within ActionContext
]=]
ActionContext.Unbind = ActionContext.Leave

--[=[
	Returns an action handler suitable for use with another [ActionContext].

	When the action's input is began, this context will be Entered.
	When the action's input is ended or canceled, this context will be Left.

	Useful for creating input chords, like Ctrl+C and Ctrl+V:

	```lua
	local innerContext = ActionContext.new({
		-- in this context, we're holding Ctrl
		ActionContext.actionBegin("Copy", { Enum.KeyCode.C }, function () print("Copied") end),
		ActionContext.actionBegin("Paste", { Enum.KeyCode.V }, function () print("Pasted") end),
	})
	local outerContext = ActionContext.new({
		-- While holding either Control key, the innerContext is entered/left.
		innerContext:CreateBindAction("ControlChord", { Enum.KeyCode.LeftControl, Enum.KeyCode.RightControl }),
	})
	outerContext:Enter()
	```

	Or even triads, like Ctrl+Shift+T:

	```lua
	ActionContext.new({
		ActionContext.new({
			-- in this context, we're holding Ctrl
			ActionContext.new({
				-- in this context, we're holding Ctrl then Shift
				ActionContext.actionBegin("Tell the time", { Enum.KeyCode.T }, function (inputObject)
					local dt = DateTime.now()
					print(dt:FormatUniversalTime("llll", "en-us"))
					return Enum.ContextActionResult.Sink
				end)
			}):CreateBindAction("ShiftChord", { Enum.KeyCode.LeftShift, Enum.KeyCode.RightShift }),
		}):CreateBindAction("ControlChord", { Enum.KeyCode.LeftControl, Enum.KeyCode.RightControl }),
	}):Enter()
	```
]=]
function ActionContext:CreateBindAction(actionName: string, inputs: { UserInput }): ActionHandler
	local bound = false
	local actionHandler: ActionHandler = {
		ActionName = actionName,
		Inputs = inputs,
		Handle = function(userInputState: Enum.UserInputState, _inputObject: InputObject): Enum.ContextActionResult
			if not bound and userInputState == Enum.UserInputState.Begin then
				bound = true
				self:Enter()
				return Enum.ContextActionResult.Sink
			elseif
				bound and (userInputState == Enum.UserInputState.End or userInputState == Enum.UserInputState.Cancel)
			then
				bound = false
				self:Leave()
				return Enum.ContextActionResult.Sink
			end
			return Enum.ContextActionResult.Pass
		end,
	}
	return actionHandler
end

--[=[
	Process input related to an action to the appropriate handler within this context. This
	is automatically called by ContextActionService after this context has been entered and
	the actions bound.

	Call this manually if you want to handle input as if it were performed by the player
	through some other means. For example, if a touchscreen player touches an on-screen button
	to honk a car horn, you might want the button press input handled by a context that which
	is entered when the player sits in the car.

	```lua
	textButton.InputBegan:Connect(function (inputObject)
		context:HandleAction("Honk", Enum.UserInputState.Begin, inputObject)
	end)
	-- (also InputChanged, InputEnded as relevant)
	```

	Note that this method ignores whether the context is currently entered or left, so for this
	example you would need ensure the on-screen button is shown/hidden when the player enters/leaves
	the car.
]=]
function ActionContext:HandleAction(
	actionName: string,
	userInputState: Enum.UserInputState,
	inputObject: InputObject
): Enum.ContextActionResult?
	local handler: ActionHandler? = self._actionHandlersByName[actionName]
	local contextActionResult: Enum.ContextActionResult? = nil
	if handler then
		contextActionResult = handler.Handle(userInputState, inputObject)
	else
		warn(`Context: No action handler found for {actionName}`)
		contextActionResult = Enum.ContextActionResult.Pass
	end
	return contextActionResult
end

return ActionContext
