---
sidebar_position: 4
---
# Chords

An **input chord** is when two or more inputs are performed simultaneously. An example is <kbd>Ctrl+C</kbd>,
which typically is a shortcut for **Copy**. The term _chord_ is borrowed from music theory, and
is when two notes performed at the same time.

An ActionContext has the `CreateBindAction` method, which returns a new action suitable for
providing to an outer context. When the outer bind action's inputs are began (pressing control),
the inner context is entered, allowing the inner actions (copy, paste) to be performed. Once
released, the inner context is left, which unbinds the inner actions (and cancels them, if still
being held).

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

The above example can be shorthanded to just a few lines:

```lua
ActionContext.new({
	ActionContext.new({
		ActionContext.actionBegin("Copy", { Enum.KeyCode.C }, function () print("Copied") end),
		ActionContext.actionBegin("Paste", { Enum.KeyCode.V }, function () print("Pasted") end),
	}):CreateBindAction("ControlChord", { Enum.KeyCode.LeftControl, Enum.KeyCode.RightControl }),
}):Enter()
```

#### Input Triads

This also makes triads like <kbd>Ctrl+Shift+T</kbd>, a combination often assigned in browsers to re-open
closed tabs, very easy. Just add one more delicious layer to your `ActionContext` cake:

```lua
ActionContext.new({ -- Browser opened...
	ActionContext.new({ -- Holding control...
		ActionContext.new({ -- Holding shift...
			-- Reopen your tabs!
			ActionContext.actionBegin("ReopenTabs", { Enum.KeyCode.C }, function () print("Re-opening tabs") end),
		}):CreateBindAction("ShiftChord", { Enum.KeyCode.LeftShift, Enum.KeyCode.RightShift }),
	}):CreateBindAction("ControlChord", { Enum.KeyCode.LeftControl, Enum.KeyCode.RightControl }),
}):Enter()
```

#### Ordering

Keen readers might notice this creates a strict ordering requirement which is not typically present for modifier
keys (shift, ctrl, alt, super). In other words, the above example would not capture <kbd>Shift+Ctrl+T</kbd>.
It is entirely possible to implement this by using additonal "middleware" contexts - just make sure you're
re-using contexts where appropriate:

```lua
local ctrlShiftContext = ActionContext.new({
	ActionContext.actionBegin("ReopenTabs", { Enum.KeyCode.T }, function () print("Re-opening tabs") end)
})
local controlInputs = { Enum.KeyCode.LeftControl, Enum.KeyCode.RightControl }
local shiftInputs = { Enum.KeyCode.LeftShift, Enum.KeyCode.RightShift }
ActionContext.new({
	ActionContext.new({
		ctrlShiftContext:CreateBindAction("ControlShiftChord", shiftInputs),
	}):CreateBindAction("ControlChord", controlInputs),
	ActionContext.new({
		ctrlShiftContext:CreateBindAction("ShiftControlChord", controlInputs),
	}):CreateBindAction("ShiftChord", shiftInputs),
}):Enter()
```

The implementation of tetrads (<kbd>Ctrl+Alt+Shift+T</kbd>) is left up to the reader. Good luck.
