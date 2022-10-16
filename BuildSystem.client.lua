local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild('PlayerGui')
local char = player.Character or player.CharacterAdded:Wait()
repeat wait() until char:FindFirstChild("Humanoid")
local humanoid = char.Humanoid

local button = script.Parent

local heartbeatConnection = nil

local gridTexture = nil

local blockSize = Vector3.new(2,2,2)

local currentOutline = nil
local currentPartToOutline = nil
local currentPosition = nil

-- display a grid
local function displayGrid(shouldDisplay)
	if not gridTexture then
		gridTexture = Instance.new("Texture")
		gridTexture.Name = "GridTexture"
		gridTexture.Texture = "rbxassetid://2415319308"
		gridTexture.Face = Enum.NormalId.Top
		gridTexture.Transparency = 1
		gridTexture.Parent = game.Workspace.Plot
	end
	if shouldDisplay == true then
		gridTexture.Transparency = 0
	else
		gridTexture.Transparency = 0.8
	end
end


local function getRayResults(part)
	
	local RAY_DISTANCE_X = part.Size.X/2
	local RAY_DISTANCE_Y = part.Size.Y/2
	local RAY_DISTANCE_Z = part.Size.Z/2
	local origin = part.Position
	local directions = {
		Vector3.new(-RAY_DISTANCE_X, 0, 0),
		Vector3.new(RAY_DISTANCE_X, 0, 0),
		Vector3.new(0, -RAY_DISTANCE_Y, 0),
		Vector3.new(0, RAY_DISTANCE_Y, 0),
		Vector3.new(0, 0, -RAY_DISTANCE_Z),
		Vector3.new(0, 0, RAY_DISTANCE_Z)
	}
	
	for i, direction in pairs(directions) do
		local result = nil
		local function castRay()
			-- Build a "RaycastParams" object
			local raycastParams = RaycastParams.new()
			raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
			raycastParams.FilterDescendantsInstances = {
				game.Workspace.Rays,
				game.Workspace.Outlines
			}
			raycastParams.IgnoreWater = true

			-- parameters workspace:Raycast(origin, direction, raycastParams)
			local raycastResult = workspace:Raycast(origin, direction, raycastParams)

			-- Interpret the result
			if raycastResult then
				--print("Index, Direction:", i, direction)
				--print("Object/terrain hit:", raycastResult.Instance:GetFullName())
				--print("Hit position:", raycastResult.Position)
				--print("Surface normal at the point of intersection:", raycastResult.Normal)
				--print("Material hit:", raycastResult.Material.Name)
				
				--if direction.X ~= 0 then
				--	currentPosition = part.Position + Vector3.new(part.Size.X/2, 0, 0)
				--elseif direction.Y ~= 0 then
				--	currentPosition = part.Position + Vector3.new(0, part.Size.Y/2, 0) 
				--elseif direction.Z ~= 0 then
				--	currentPosition = part.Position + Vector3.new(0, 0, part.Size.Z/2)
				--end

				local function visiualizeRay()
					local rayPart = Instance.new("Part")
					local distance = (origin - raycastResult.Position).Magnitude
					rayPart.Color = Color3.new(0.333333, 1, 0)
					rayPart.Anchored = true
					rayPart.CanCollide = false
					rayPart.Size = Vector3.new(0.1, 0.1, distance)
					rayPart.CFrame = CFrame.lookAt(origin, raycastResult.Position) * CFrame.new(0, 0, -distance/2)
					rayPart.Parent = game.Workspace.Rays
					task.delay(0.1, function()
						rayPart:Destroy()
					end)
				end
				visiualizeRay()
				
				result = {
					raycastResult,
					direction
				}
				return result
			end
		end
		return castRay()
	end
end


local function screenToWorldPosition(screenPos)
	-- Build a "RaycastParams" object
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	raycastParams.FilterDescendantsInstances = {}
	raycastParams.IgnoreWater = true

	-- Cast the ray
	--local inset = GuiService:GetGuiInset()
	local RAY_DISTANCE = 1000 -- default ray distance like mouse.Hit
	local camera = workspace.CurrentCamera
	--local targetScreenPos = position - Vector3.new(inset.X, inset.Y, 0)
	local targetScreenPos = screenPos
	local targetRay = camera:ScreenPointToRay(targetScreenPos.X, targetScreenPos.Y)
	local raycastResult = workspace:Raycast(targetRay.Origin, targetRay.Direction * RAY_DISTANCE, raycastParams)

	-- Interpret the result
	if raycastResult then
		--print("Object/terrain hit:", raycastResult.Instance:GetFullName())
		--print("Hit position:", raycastResult.Position)
		--print("Surface normal at the point of intersection:", raycastResult.Normal)
		--print("Material hit:", raycastResult.Material.Name)
		local xResult = math.floor(raycastResult.Position.X + 0.5)
		local yResult = math.floor(raycastResult.Position.Y + 0.5)
		local zResult = math.floor(raycastResult.Position.Z + 0.5)
		local roundedPosition = Vector3.new(xResult, yResult, zResult)
		return roundedPosition
	else
		--print("Nothing was hit!")
		return nil
	end
end


local function handleBuildOutline(part, screenPos)
	if heartbeatConnection then
		heartbeatConnection:Disconnect()
		heartbeatConnection = nil
	else
		heartbeatConnection = RunService.Heartbeat:Connect(function(dt)
			-- set part to mouse position
			local mouseLocation = UserInputService:GetMouseLocation()
			local worldPos = screenToWorldPosition(mouseLocation)
			if worldPos == nil then return end
			currentPosition = worldPos
			part.Position = worldPos
			
			-- correct part position
			local rayResults = getRayResults(part)
			print(rayResults)
			--part.Position = currentPosition
		end)
	end
end

local function handleSelect(inputState, inputObject)

	-- this is mousebutton 1 and button B
	if inputState == Enum.UserInputState.End then

		-- get inputobject values
		local delta = inputObject.Delta -- vector3 distance between mouse or joystick movements?
		local keyCode = inputObject.KeyCode -- unknown
		local position = inputObject.Position -- vector3 position of mouse?
		local userInputState = inputObject.UserInputState -- begin
		local userInputType = inputObject.UserInputType -- mousebutton1
		print("delta, keyCode, position, userInputState, userInputType")
		print(delta, keyCode, position, userInputState, userInputType)

		-- create a part, set position, and parent to workspace
		local newPart = Instance.new("Part")
		local worldPosition = screenToWorldPosition(position)
		if typeof(worldPosition) == "Vector3" then
			newPart.Size = blockSize
			newPart.Position = currentPosition
			newPart.Anchored = true
			newPart.Parent = game.Workspace.Builds
		end
		
		-- end build mode
		--ContextActionService:UnbindAction("Build")
		--handleBuildOutline()
		--displayGrid(false)
		--if currentOutline then
		--	currentOutline:Destroy()
		--	currentOutline = nil
		--end
		--if currentPartToOutline then
		--	currentPartToOutline:Destroy()
		--	currentPartToOutline = nil
		--end
	end
end


local function handleInput(actionName, inputState, inputObject)
	if actionName == "Build" then
		handleSelect(inputState, inputObject)
	end
end



button.Activated:Connect(function(inputObject, clickCount)
	
	-- get inputobject values
	local delta = inputObject.Delta -- vector3 distance between mouse or joystick movements?
	local keyCode = inputObject.KeyCode -- unknown
	local position = inputObject.Position -- vector3 position of mouse?
	local userInputState = inputObject.UserInputState -- begin
	local userInputType = inputObject.UserInputType -- mousebutton1
	
	--if userInputState == Enum.UserInputState.Begin then
		print("delta, keyCode, position, userInputState, userInputType")
		print(delta, keyCode, position, userInputState, userInputType)
		
		-- create partOutline
		local function partOutline()
			local newPart = Instance.new("Part")
			newPart.Size = blockSize
			newPart.CanCollide = false
			newPart.CanTouch = false
			newPart.Transparency = 0.5
			newPart.Parent = game.Workspace.Outlines
			local selectionBox = Instance.new("SelectionBox")
			selectionBox.Name = "Outline"
			selectionBox.LineThickness = 0.05
			selectionBox.Color3 = Color3.new(0, 255, 0)
			selectionBox.Transparency = 0.8
			selectionBox.Parent = playerGui
			selectionBox.Adornee = newPart
			currentOutline = selectionBox
			currentPartToOutline = newPart
			handleBuildOutline(newPart, position)
		end
		local outlineGraphic = partOutline()
		
		displayGrid(true)

		-- connect the Build ContextActionService
		ContextActionService:BindAction("Build", handleInput, true, Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonB)
		ContextActionService:SetTitle("Build", "Build")
	--end
end)
