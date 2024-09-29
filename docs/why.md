---
sidebar_label: 'Why?'
sidebar_position: 2
---
# Why use `ActionContext`?

Some Roblox developers might bemoan the learning of yet even more input API, especially
since Roblox's has changed many times over many years. The main idea behind this API is
simplicty and brevity of the current-best best-practice for this specific case.

This page is inspired by the [_Why use Promises?_](https://eryn.io/roblox-lua-promise/docs/WhyUsePromises)
page on the [roblox-lua-promise](https://eryn.io/roblox-lua-promise/) docs, which serves
a similar purpose.

## An Input Problem

Most seasoned Roblox developers will have coded up input systems in their games, and in
doing so, likely have spent time writing a good amount of ContextActionService boilerplate
code that looks like this:

```lua
local ContextActionService = game:GetService("ContextActionService")
local ACTION_HONK = "Honk"
local INPUTS_HONK = { Enum.KeyCode.H, Enum.KeyCode.ButtonY }

local honkSound = script.HonkSound
local function handleHonkAction(actionName, userInputState, inputObject)
	-- (actionName is always going to be "Honk" because this handler
	-- was only used once for this action)
	if userInputState == Enum.UserInputState.Begin then
		honkSound:Play()
	end
end

-- When the player enters the car...
ContextActionService:BindAction(ACTION_HONK, handleHonkAction, true, unpack(INPUTS_HONK))

-- When the player leaves the car...
ContextActionService:UnbindAction(ACTION_HONK)
```

This is quite long-winded and doesn't provide a whole lot of flexibility with adding
new things the player can do. While using ContextActionService (CAS) is generally a
good idea, the API leaves a lot of work up to the developer and is often ignored over
the simplicty of UserInputService (UIS).

## An Input Solution

Enter **ActionContext**, an object-oriented way to ease the pain of all that boilerplate:
it represents a single context in which one or more player actions are relevant. Once
relevant (or not), just call a single single Enter/Leave method (or Bind/Unbind if you
prefer).

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

-- When the player enters the car...
actionContext:Enter() -- (alias: Bind)

-- When the player leaves the car...
actionContext:Leave() -- (alias: Unbind)
```

Not only is this easier to remember, this API also has useful shortcuts for common
scenarios. The above table can be simplified through the use of `ActionContext.actionBegin`:

```lua
-- Automatically checks for UserInputState.Begin:
local honkAction = ActionContext.actionBegin("Honk", { Enum.KeyCode.H }, function (inputObject)
	sound:Play()
end)
-- A shorthand, if the action is always relevant:
ActionContext.new({ honkAction }):Enter()
```
