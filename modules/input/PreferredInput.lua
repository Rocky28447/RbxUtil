--!strict

-- PreferredInput
-- Stephen Leitnick
-- April 05, 2021

--[=[
	@within PreferredInput
	@type InputType "MouseKeyboard" | "Touch" | "Gamepad"

	The InputType is just a string that is either `"MouseKeyboard"`,
	`"Touch"`, or `"Gamepad"`.
]=]
export type InputType = "MouseKeyboard" | "Touch" | "Gamepad" | "Unknown"

local UserInputService = game:GetService("UserInputService")

local touchUserInputType = Enum.UserInputType.Touch
local keyboardUserInputType = Enum.UserInputType.Keyboard

type PreferredInput = {
	Current: InputType,
	DeterminePreferred: (inputType: Enum.UserInputType) -> InputType,
	Observe: (handler: (inputType: InputType) -> ()) -> () -> (),
}

--[=[
	@class PreferredInput
	@client

	A helper library for observing the preferred user input of the
	player. This is useful for determining what input schemes
	to use during gameplay. A player might switch from using
	a mouse to a gamepad mid-game, and it is important for the
	game to respond to this change.

	The Preferred class is part of the Input package.

	```lua
	local PreferredInput = require(packages.Input).PreferredInput
	```
]=]
--[=[
	@within PreferredInput
	@prop Current InputType
	@readonly

	The current preferred InputType.

	```lua
	print(PreferredInput.Current)
	```
]=]
--[=[
	@within PreferredInput
	@function Observe
	@param handler (preferred: InputType) -> ()
	@return () -> ()

	Observes the preferred input. In other words, the handler function will
	be fired immediately, as well as any time the preferred input changes.

	The returned function can be called to disconnect the observer.

	```lua
	local disconnect = PreferredInput.Observe(function(preferred)
		-- Fires immediately & any time the preferred input changes
		print(preferred)
	end)

	-- If/when desired, observer can be stopped by calling the returned function:
	disconnect()
	```
]=]

local PreferredInput: PreferredInput

local subscribers = {}

PreferredInput = {

	Current = "MouseKeyboard",

	DeterminePreferred = function(inputType: Enum.UserInputType): InputType
		if inputType == touchUserInputType then
			return "Touch"
		elseif inputType == keyboardUserInputType or inputType.Name:sub(1, 5) == "Mouse" then
			return "MouseKeyboard"
		elseif inputType.Name:sub(1, 7) == "Gamepad" then
			return "Gamepad"
		end
		return "Unknown"
	end,

	Observe = function(handler: (inputType: InputType) -> ()): () -> ()
		if table.find(subscribers, handler) then
			error("function already subscribed", 2)
		end
		table.insert(subscribers, handler)

		task.spawn(handler, PreferredInput.Current)

		return function()
			local index = table.find(subscribers, handler)
			if index then
				local n = #subscribers
				subscribers[index], subscribers[n] = subscribers[n], nil
			end
		end
	end,
}

local function SetPreferred(preferred: InputType)
	if preferred == PreferredInput.Current then
		return
	end
	PreferredInput.Current = preferred

	for _, subscriber in subscribers do
		task.spawn(subscriber, preferred)
	end
end

local function SetPreferredFromInputType(inputType: Enum.UserInputType)
	local preferred: InputType = PreferredInput.DeterminePreferred(inputType)
	if preferred ~= "Unknown" then
		SetPreferred(preferred)
	end
end

PreferredInput.DeterminePreferred(UserInputService:GetLastInputType())
UserInputService.LastInputTypeChanged:Connect(SetPreferredFromInputType)

return PreferredInput
