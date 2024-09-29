---
sidebar_position: 3
---
# Organization

If your game features a good number of actions the player can perform, you may find
it convenient to separate those actions into their own modules. To this end,
`ActionContext.fromChildren(container)` exists to make that process convenient.

## Root

Let's say some other part of the game detects when the player enters/leaves a car.
It might require a module which returns an action context representing that situation:

```lua
local ActionContext = require(...)
return ActionContext.fromChildren(script)
```

Contained within this script might be two child modules which contain the logic of
the actions as described by this context.

### Child Module

```lua
local ActionContext = require(...)
return ActionContext.actionBegin("Honk", { Enum.KeyCode.H }, function (inputObject)
	sound:Play()
end)
```

### Another Child Module

```lua
local BrakeLights = require(...) -- SetEnabled
local toggleHeadlightsAction = {
	ActionName = "Brake",
	Inputs = { Enum.KeyCode.B },
	Handle = function (userInputState, inputObject)
		local isBraking = userInputState == Enum.UserInputState.Begin
		BrakeLights:SetEnabled(isBraking)
		-- ...and also actually slow down the car...
	end,
}
return toggleHeadlightsAction
```
