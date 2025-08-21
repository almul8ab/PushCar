-- By Hussein Ali
hso = {}

hso.settings = {
    key = "n",
    speed = 0.04,
    turnSpeed = 0.5,
    turnInterval = 50,
    attachOffsetCenter = {0, -3.2, 0.3},
    attachOffsetLeft = {-0.4, -3.2, 0.3},
    attachOffsetRight = {0.4, -3.2, 0.3},
    attachOffsetCenter_Front = {0, 3.2, 0.3},
    attachOffsetLeft_Front = {-0.4, 3.2, 0.3},
    attachOffsetRight_Front = {0.4, 3.2, 0.3},
    cooldown = 2000
}

hso.pushingData = {}
hso.vehiclePushers = {}
hso.pushCooldowns = {}

function hso.repositionPushers(vehicle)
    local vehicleData = hso.vehiclePushers[vehicle]
    if not vehicleData then return end

    local pushers = {}
    for i = 1, 2 do
        if isElement(vehicleData.players[i]) then
            table.insert(pushers, vehicleData.players[i])
        end
    end

    for _, p in ipairs(pushers) do
        if isElementAttached(p) then detachElements(p) end
    end
    
    local pushingFrom = vehicleData.pushingFrom
    local suffix = (pushingFrom == "front") and "_Front" or ""

    if #pushers == 1 then
        local p = pushers[1]
        local offset = hso.settings["attachOffsetCenter" .. suffix]
        attachElements(p, vehicle, offset[1], offset[2], offset[3])
        vehicleData.players = { [1] = p, [2] = nil }
        hso.pushingData[p].slot = 1
    elseif #pushers == 2 then
        local p1, p2 = pushers[1], pushers[2]
        local offset1 = hso.settings["attachOffsetLeft" .. suffix]
        attachElements(p1, vehicle, offset1[1], offset1[2], offset1[3])
        local offset2 = hso.settings["attachOffsetRight" .. suffix]
        attachElements(p2, vehicle, offset2[1], offset2[2], offset2[3])
        vehicleData.players = { [1] = p1, [2] = p2 }
        hso.pushingData[p1].slot = 1
        hso.pushingData[p2].slot = 2
    end
end

function hso.updateVehicleState(vehicle)
    if not isElement(vehicle) then return end
    local data = hso.vehiclePushers[vehicle]
    if not data then return end

    local pusherCount = 0
    for i = 1, 2 do
        if isElement(data.players[i]) then pusherCount = pusherCount + 1 else data.players[i] = nil end
    end

    if pusherCount == 0 then
        if isTimer(data.timer) then killTimer(data.timer) end
        setElementVelocity(vehicle, 0, 0, 0)
        hso.vehiclePushers[vehicle] = nil
        return
    end

    local rx, ry, rz = getElementRotation(vehicle)
    local newRz = rz
    if data.turnState.left > 0 and data.turnState.right == 0 then
        newRz = rz + hso.settings.turnSpeed
    elseif data.turnState.right > 0 and data.turnState.left == 0 then
        newRz = rz - hso.settings.turnSpeed
    end
    
    if newRz ~= rz then
        setElementRotation(vehicle, rx, ry, newRz)
    end
    
    local playerRotationOffset = (data.pushingFrom == "front") and 180 or 0
    for _, p in pairs(data.players) do
        if isElement(p) then
            setElementRotation(p, 0, 0, newRz + playerRotationOffset)
        end
    end
    
    local currentSpeed = hso.settings.speed
    if pusherCount == 2 then currentSpeed = currentSpeed * 1.15 end
    
    local directionModifier = (data.pushingFrom == "front") and -1 or 1
    local finalSpeed = currentSpeed * directionModifier
    
    local velX = -math.sin(math.rad(newRz)) * finalSpeed
    local velY = math.cos(math.rad(newRz)) * finalSpeed
    setElementVelocity(vehicle, velX, velY, 0)
end

function hso.startPushing(player, vehicle, pushingFrom)
    if not isElement(player) or not isElement(vehicle) then return end
    
    local vehicleData = hso.vehiclePushers[vehicle]
    
    if not vehicleData then
        vehicleData = {
            players = {[1] = nil, [2] = nil},
            turnState = {left = 0, right = 0},
            pushingFrom = pushingFrom,
            timer = setTimer(hso.updateVehicleState, hso.settings.turnInterval, 0, vehicle)
        }
        hso.vehiclePushers[vehicle] = vehicleData
    end
    
    local slot
    if not vehicleData.players[1] then slot = 1
    elseif not vehicleData.players[2] then slot = 2
    else return end

    hso.pushingData[player] = { vehicle = vehicle, slot = slot, pushingFrom = pushingFrom }
    vehicleData.players[slot] = player
    
    hso.repositionPushers(vehicle)
    
    triggerClientEvent(getRootElement(), "VehiclePush:updateAnim", getRootElement(), getPlayerName(player), true)
end

function hso.stopPushing(player)
    local playerData = hso.pushingData[player]
    if not playerData then return end
    
    local vehicle = playerData.vehicle
    local slot = playerData.slot
    local vehicleData = hso.vehiclePushers[vehicle]

    if isElement(player) and isElementAttached(player) then detachElements(player) end
    triggerClientEvent(getRootElement(), "VehiclePush:updateAnim", getRootElement(), getPlayerName(player), false)

    hso.pushingData[player] = nil
    
    if vehicleData then
        vehicleData.players[slot] = nil
        
        local pushersLeft = 0
        for i = 1, 2 do
            if isElement(vehicleData.players[i]) then pushersLeft = pushersLeft + 1 end
        end
        
        if pushersLeft > 0 then
            hso.repositionPushers(vehicle)
        else
            if isTimer(vehicleData.timer) then killTimer(vehicleData.timer) end
            if isElement(vehicle) then setElementVelocity(vehicle, 0, 0, 0) end
            hso.vehiclePushers[vehicle] = nil
        end
    end
end

function hso.handleKey() 
    if hso.pushCooldowns[client] and getTickCount() - hso.pushCooldowns[client] < hso.settings.cooldown then
        return
    end
    hso.pushCooldowns[client] = getTickCount()

    if hso.pushingData[client] then
        hso.stopPushing(client)
    else
        local vehicle = hso.getNearestVeh(client, 4)
        if not (vehicle and not getVehicleEngineState(vehicle) and not getPedOccupiedVehicle(client)) then return end

        local matrix = getElementMatrix(vehicle)
        local vx, vy, vz = getElementPosition(vehicle)
        local px, py, pz = getElementPosition(client)
        local frontX, frontY = vx + matrix[2][1] * 3, vy + matrix[2][2] * 3
        local backX, backY = vx - matrix[2][1] * 3, vy - matrix[2][2] * 3
        local distToFront = getDistanceBetweenPoints2D(px, py, frontX, frontY)
        local distToBack = getDistanceBetweenPoints2D(px, py, backX, backY)
        local pushingFrom = (distToFront < distToBack) and "front" or "back"

        local vehicleData = hso.vehiclePushers[vehicle]
        if vehicleData and vehicleData.pushingFrom ~= pushingFrom then
            return
        end
        
        local pusherCount = vehicleData and (#(table.filter(vehicleData.players, isElement))) or 0
        if pusherCount < 2 then
            hso.startPushing(client, vehicle, pushingFrom)
        end
    end
end
addEvent("VehiclePush:onKey", true)
addEventHandler("VehiclePush:onKey", getRootElement(), hso.handleKey)

function hso.handleTurn(direction, state)
    local player = client
    local playerData = hso.pushingData[player]
    if not playerData or not playerData.vehicle then return end
    
    local vehicle = playerData.vehicle
    local vehicleData = hso.vehiclePushers[vehicle]
    if not vehicleData then return end

    local increment = (state == "down") and 1 or -1
    vehicleData.turnState[direction] = math.max(0, vehicleData.turnState[direction] + increment)
end
addEvent("VehiclePush:onTurn", true)
addEventHandler("VehiclePush:onTurn", getRootElement(), hso.handleTurn)

function hso.getNearestVeh(player, maxDistance)
    local closestVehicle, shortestDistance = false, maxDistance + 1
    local pX, pY, pZ = getElementPosition(player)
    for _, vehicle in ipairs(getElementsByType("vehicle")) do
        local vX, vY, vZ = getElementPosition(vehicle)
        local currentDistance = getDistanceBetweenPoints3D(pX, pY, pZ, vX, vY, vZ)
        if currentDistance < shortestDistance then
            closestVehicle, shortestDistance = vehicle, currentDistance
        end
    end
    return closestVehicle
end

addEventHandler("onPlayerQuit", getRootElement(), function()
    if hso.pushingData[source] then hso.stopPushing(source) end
end)

function table.filter(tbl, func)
    local result = {}
    for k, v in pairs(tbl) do
        if func(v) then table.insert(result, v) end
    end
    return result
end
