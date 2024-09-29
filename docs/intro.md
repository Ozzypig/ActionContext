---
sidebar_position: 1
---
# Intro

`ActionContext` is a simpler, briefer, more memorable way to use ContextActionService
through the use of object-oriented programming. It gives the concept of the **context**
a first-class implementation in your code, groups actions together, and makes obvious
when a context shared by multiple actions is entered/left.

## Example

```lua
local honkAction = {
	ActionName = "Honk",
	Inputs = { Enum.KeyCode.H, Enum.KeyCode.ButtonY },
	Handle = function (userInputState, inputObject)
		if userInputState == Enum.UserInputState.Begin then
			sound:Play()
		end
	end,
}
local actionContext = ActionContext.new({ honkAction })

-- Entering the car...
actionContext:Enter() 
-- ...and leaving it
actionContext:Leave() 
```

## Example (shorthand)

```lua
ActionContext.new({ 
	ActionContext.actionBegin("Honk", { Enum.KeyCode.H }, function (inputObject)
		sound:Play()
	end)
 }):Enter()
```
