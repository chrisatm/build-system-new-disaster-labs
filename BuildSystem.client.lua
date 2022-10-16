local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
--local GuiService = game:GetService("GuiService")

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
local RAY_OFFSET = 1

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
	local RAY_ADD_DISTANCE = 25
	local RAY_DISTANCE_X = part.Size.X + (part.Size.X * RAY_OFFSET)
	local RAY_DISTANCE_Y = part.Size.Y + (part.Size.Y * RAY_OFFSET)
	local RAY_DISTANCE_Z = part.Size.Z + (part.Size.Z * RAY_OFFSET)
	local sides = {
		[1] = {
			part.Position + Vector3.new(RAY_DISTANCE_X, 0, 0),
			Vector3.new(-RAY_DISTANCE_X, 0, 0)
		},
		[2] = {
			part.Position - Vector3.new(RAY_DISTANCE_X, 0, 0),
			Vector3.new(RAY_DISTANCE_X, 0, 0)
		},
		[3] = {
			part.Position + Vector3.new(0, RAY_DISTANCE_Y, 0),
			Vector3.new(0, -RAY_DISTANCE_Y, 0)
		},
		[4] = {
			part.Position - Vector3.new(0, RAY_DISTANCE_Y, 0),
			Vector3.new(0, RAY_DISTANCE_Y, 0)
		},
		[5] = {
			part.Position + Vector3.new(0, 0, RAY_DISTANCE_Z),
			Vector3.new(0, 0, -RAY_DISTANCE_Z)
		},
		[6] = {
			part.Position - Vector3.new(0, 0, RAY_DISTANCE_Z),
			Vector3.new(0, 0, RAY_DISTANCE_Z)
		},
	}
	
	local results = {}
	
	for i, info in pairs(sides) do
		local origin = info[1]
		local direction = info[2]
		
		-- Build a "RaycastParams" object
		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
		raycastParams.FilterDescendantsInstances = {
			game.Workspace.Rays,
			game.Workspace.Outlines
		}
		raycastParams.IgnoreWater = true
		
		local function visiualizeRay()
			local distance = (origin - direction).Magnitude
			local originPart = Instance.new("Part")
			originPart.Shape = Enum.PartType.Ball
			originPart.Anchored = true
			originPart.Size = Vector3.new(0.25, 0.25, 0.25)
			originPart.Position = origin
			originPart.Color = Color3.new(0.666667, 0.333333, 1)
			originPart.Material = Enum.Material.Neon
			originPart.CanCollide = false
			originPart.CanTouch = false
			originPart.Transparency = 0.5
			originPart.Parent = game.Workspace.Rays
			local rayPart = Instance.new("Part")
			rayPart.Color = Color3.new(1, 1, 0)
			rayPart.Anchored = true
			rayPart.CanCollide = false
			rayPart.CanTouch = false
			rayPart.Material = Enum.Material.Neon
			rayPart.Size = Vector3.new(0.05, 0.05, distance)
			rayPart.CFrame = CFrame.lookAt(origin, origin + direction) * CFrame.new(0, 0, -distance/2)
			rayPart.Transparency = 0.5
			rayPart.Parent = game.Workspace.Rays
			task.delay(0.1, function()
				rayPart:Destroy()
				originPart:Destroy()
			end)
		end
		--visiualizeRay()

		-- parameters workspace:Raycast(origin, direction, raycastParams)
		local raycastResult = workspace:Raycast(origin, direction * RAY_ADD_DISTANCE, raycastParams)
		-- Interpret the result
		if raycastResult then
			--print("Index, Direction:", i, direction)
			--print("Object/terrain hit:", raycastResult.Instance:GetFullName())
			--print("Hit position:", raycastResult.Position)
			--print("Surface normal at the point of intersection:", raycastResult.Normal)
			--print("Material hit:", raycastResult.Material.Name)

			local distance = (origin - raycastResult.Position).Magnitude
			local normal = raycastResult.Normal

			local function visiualizeRayResult()
				local originPart = Instance.new("Part")
				originPart.Shape = Enum.PartType.Ball
				originPart.Anchored = true
				originPart.Size = Vector3.new(0.5, 0.5, 0.5)
				originPart.Position = origin
				originPart.Color = Color3.new(0, 0.333333, 1)
				originPart.Material = Enum.Material.Neon
				originPart.CanCollide = false
				originPart.CanTouch = false
				originPart.Parent = game.Workspace.Rays
				local rayPart = Instance.new("Part")
				rayPart.Color = Color3.new(1, 0.333333, 0)
				rayPart.Anchored = true
				rayPart.CanCollide = false
				rayPart.CanTouch = false
				rayPart.Material = Enum.Material.Neon
				rayPart.Size = Vector3.new(0.1, 0.1, distance)
				rayPart.CFrame = CFrame.lookAt(origin, raycastResult.Position) * CFrame.new(0, 0, -distance/2)
				rayPart.Parent = game.Workspace.Rays
				task.delay(0.1, function()
					rayPart:Destroy()
					originPart:Destroy()
				end)
			end
			
			visiualizeRayResult()
			
			local result = {
				raycastResult,
				direction,
				distance,
				normal
			}

			table.insert(results, result)		
		end
	end
		
	return results
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
		return nil
	end
end


function GetNormalFromFace(part, normalId)
	return part.CFrame:VectorToWorldSpace(Vector3.FromNormalId(normalId))
end

function NormalToFace(normalVector, part)
	local TOLERANCE_VALUE = 1 - 0.001
	local allFaceNormalIds = {
		Enum.NormalId.Front,
		Enum.NormalId.Back,
		Enum.NormalId.Bottom,
		Enum.NormalId.Top,
		Enum.NormalId.Left,
		Enum.NormalId.Right
	}    
	for _, normalId in pairs( allFaceNormalIds ) do
		-- If the two vectors are almost parallel,
		if GetNormalFromFace(part, normalId):Dot(normalVector) > TOLERANCE_VALUE then
			return normalId -- We found it!
		end
	end
	return nil -- None found within tolerance.
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
			part.Position = currentPosition
			
			-- correct part position
			local rayResults = getRayResults(part)
			if #rayResults > 0 then
				local positions = {}
				local isUp = false
				for i, result in pairs(rayResults) do
					local partDetected = result[1].Instance
					local direction = result[2]
					local distance = result[3]
					local normal = result[4]
					local addToPosition
					local directionName
					if direction.X ~= 0 and direction.X < 0 then
						addToPosition = Vector3.new(part.Size.X/2, 0, 0)
						directionName = "Back"
					elseif direction.X ~= 0 and direction.X > 0 then
						addToPosition = -(Vector3.new(part.Size.X/2, 0, 0))
						directionName = "Front"
					elseif direction.Y ~= 0 and direction.Y > 0 then
						addToPosition = Vector3.new(0, -part.Size.Y/2, 0)
						directionName = "Down"
					elseif direction.Y ~= 0 and direction.Y < 0 then
						addToPosition = Vector3.new(0, part.Size.Y/2, 0)
						directionName = "Up"
					elseif direction.Z ~= 0 and direction.Z > 0 then
						addToPosition = Vector3.new(0, 0, -part.Size.Z/2)
						directionName = "Left"
					elseif direction.Z ~= 0 and direction.Z < 0 then
						addToPosition = Vector3.new(0, 0, part.Size.Z/2)
						directionName = "Right"
					end
					if addToPosition then
						local res = {
							directionName,
							addToPosition,
							partDetected,
							distance
						}
						table.insert(positions, res)
					end
					print(NormalToFace(normal, part))
				end
				
				if #positions > 0 then
					local posTables = {}
					local newPosition = part.Position
					if #positions == 1 then
						local positionInfo = positions[1]
						local dirName = positionInfo[1]
						local newPos = positionInfo[2]
						local partDetected = positionInfo[3]
						local distance = positionInfo[4]
						newPosition += newPos
					elseif #positions > 1 then
						local isUp = nil
						local isDown = nil
						local isFront = nil
						local isBack = nil
						local isLeft= nil
						local isRight = nil
						for i, positionInfo in pairs(positions) do
							local dirName = positionInfo[1]
							local newPos = positionInfo[2]
							local partDetected = positionInfo[3]
							local distance = positionInfo[4]
							local newTable = {
								dirName,
								newPos,
								partDetected,
								distance
							}
							if dirName == "Front" then
								isFront = newTable
							elseif dirName == "Back" then
								isBack = newTable
							elseif dirName == "Up" then
								isUp = newTable
							elseif dirName == "Down" then
								isDown = newTable
							elseif dirName == "Left" then
								isLeft = newTable
							elseif dirName == "Right" then
								isRight = newTable
							end
						end
						
						if isFront then
							print(isFront[1], "distance:", isFront[4])
						end
						if isBack then
							print(isBack[1], "distance:", isBack[4])
						end
						if isUp then
							print(isUp[1], "distance:", isUp[4])
						end
						if isDown then
							print(isDown[1], "distance:", isDown[4])
						end
						if isLeft then
							print(isLeft[1], "distance:", isLeft[4])
						end
						if isRight then
							print(isRight[1], "distance:", isRight[4])
						end
										
						if isUp and isDown then
							local upDistance = isUp[4]
							if upDistance < part.Size.Y + (part.Size.Y * RAY_OFFSET) then
								table.insert(posTables, isUp)
							end	
						elseif isUp then
							local upDistance = isUp[4]
							if upDistance < part.Size.Y + (part.Size.Y * RAY_OFFSET) then
								table.insert(posTables, isUp)
							end	
						end
						
						
						if isBack and isFront and isLeft and isRight or isBack and isFront and isLeft or isBack and isFront and isRight then
							local backDistance = isBack[4]
							local frontDistance = isFront[4]
							local leftDistance = math.huge
							local rightDistance = math.huge
							if isLeft then
								leftDistance = isLeft[4]
							end
							if isRight then
								rightDistance = isRight[4]
							end	
							
							if backDistance > frontDistance then
								if backDistance > leftDistance then
									if backDistance <= part.Size.X + (part.Size.X * RAY_OFFSET) then
										table.insert(posTables, isBack)
									else
										table.insert(posTables, isLeft)
									end
								elseif backDistance > rightDistance then
									if backDistance <= part.Size.X + (part.Size.X * RAY_OFFSET) then
										table.insert(posTables, isBack)
									else
										table.insert(posTables, isRight)
									end
								end
							elseif backDistance < frontDistance then
								if frontDistance > leftDistance then
									if frontDistance <= part.Size.X + (part.Size.X * RAY_OFFSET) then
										table.insert(posTables, isFront)
									else
										table.insert(posTables, isLeft)
									end
								elseif frontDistance > rightDistance then
									if frontDistance <= part.Size.X + (part.Size.X * RAY_OFFSET) then
										table.insert(posTables, isFront)
									else
										table.insert(posTables, isRight)
									end
								end
							end				
						elseif isBack and isLeft and isRight or isFront and isLeft and isRight then
							local backDistance = math.huge
							local frontDistance = math.huge
							local leftDistance = isLeft[4]
							local rightDistance = isRight[4]
							if isBack then
								backDistance = isLeft[4]
							end
							if isFront then
								frontDistance = isRight[4]
							end	
							if leftDistance > rightDistance then
								if leftDistance > frontDistance then
									if leftDistance <= part.Size.X + (part.Size.X * RAY_OFFSET) then
										table.insert(posTables, isLeft)
									else
										table.insert(posTables, isFront)
									end
								elseif leftDistance > backDistance then
									if leftDistance <= part.Size.X + (part.Size.X * RAY_OFFSET) then
										table.insert(posTables, isLeft)
									else
										table.insert(posTables, isBack)
									end
								end
							else
								if rightDistance > frontDistance then
									if rightDistance <= part.Size.X + (part.Size.X * RAY_OFFSET) then
										table.insert(posTables, isRight)
									else
										table.insert(posTables, isFront)
									end
								elseif rightDistance > backDistance then
									if rightDistance <= part.Size.X + (part.Size.X * RAY_OFFSET) then
										table.insert(posTables, isRight)
									else
										table.insert(posTables, isBack)
									end
								end
							end	
						elseif isBack and isLeft or isBack and isRight then
							local backDistance = isBack[4]
							local frontDistance = isFront[4]
							local leftDistance = math.huge
							local rightDistance = math.huge
							if isLeft then
								leftDistance = isLeft[4]
							end
							if isRight then
								rightDistance = isRight[4]
							end	
							if backDistance > frontDistance then
								if backDistance > leftDistance then
									if backDistance <= part.Size.X + (part.Size.X * RAY_OFFSET) then
										table.insert(posTables, isBack)
									else
										table.insert(posTables, isLeft)
									end
								elseif backDistance > rightDistance then
									if backDistance <= part.Size.X + (part.Size.X * RAY_OFFSET) then
										table.insert(posTables, isBack)
									else
										table.insert(posTables, isRight)
									end
								end
							else
								if frontDistance > leftDistance then
									if frontDistance <= part.Size.X + (part.Size.X * RAY_OFFSET) then
										table.insert(posTables, isFront)
									else
										table.insert(posTables, isLeft)
									end
								elseif frontDistance > rightDistance then
									if frontDistance <= part.Size.X + (part.Size.X * RAY_OFFSET) then
										table.insert(posTables, isFront)
									else
										table.insert(posTables, isRight)
									end
								end
							end			
						elseif isFront and isLeft or isFront and isRight then
							
						end
					end
					
					if #posTables > 0 then
						for i, positionInfo in pairs(posTables) do
							if positionInfo == nil then return end
							print("Added:", positionInfo[1], "Distance:", positionInfo[4])
							local pos = positionInfo[2]
							newPosition += pos
						end
					end
					currentPosition = newPosition
					part.Position = currentPosition
				end
			else
				print("No rayResults")
			end
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
		--print("delta, keyCode, position, userInputState, userInputType")
		--print(delta, keyCode, position, userInputState, userInputType)

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
		--print("delta, keyCode, position, userInputState, userInputType")
		--print(delta, keyCode, position, userInputState, userInputType)
		
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
