-- by Hussein Ali 

hso = {}

hso.settings = {
    key = "n",
    speed = 0.04,
    turnSpeed = 0.5,
    turnInterval = 50,
    attachOffset = {0, -3.2, 0.3},
    cooldown = 2000
}

hso.pushingData = {}
hso.pushCooldowns = {}

function hso.startPushing(player, vehicle)
    if not isElement(player) or not isElement(vehicle) then return end
    attachElements(player, vehicle, hso.settings.attachOffset[1], hso.settings.attachOffset[2], hso.settings.attachOffset[3])

    local pushTimer = setTimer(function(p, v)
        if not isElement(p) or not isElement(v) or not hso.pushingData[p] then
            hso.stopPushing(p)
            return
        end
        local rx, ry, rz = getElementRotation(v)
        local velX = -math.sin(math.rad(rz)) * hso.settings.speed
        local velY = math.cos(math.rad(rz)) * hso.settings.speed
        setElementVelocity(v, velX, velY, 0)
    end, 50, 0, player, vehicle)
    
    hso.pushingData[player] = {
        vehicle = vehicle,
        pushTimer = pushTimer,
        turnTimer = nil,
        turnDirection = nil
    }
    triggerClientEvent(getRootElement(), "VehiclePush:updateAnim", getRootElement(), getPlayerName(player), true)
end

function hso.stopPushing(player)
    if not hso.pushingData[player] then return end
    
    local data = hso.pushingData[player]
    if isTimer(data.pushTimer) then killTimer(data.pushTimer) end
    if isTimer(data.turnTimer) then killTimer(data.turnTimer) end
    
    if isElement(player) and isElementAttached(player) then detachElements(player) end
    if isElement(data.vehicle) then setElementVelocity(data.vehicle, 0, 0, 0) end
    
    hso.pushingData[player] = nil
    triggerClientEvent(getRootElement(), "VehiclePush:updateAnim", getRootElement(), getPlayerName(player), false)
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
        if vehicle and not getVehicleEngineState(vehicle) and not getPedOccupiedVehicle(client) then
            hso.startPushing(client, vehicle)
        end
    end
end
addEvent("VehiclePush:onKey", true)
addEventHandler("VehiclePush:onKey", getRootElement(), hso.handleKey)

function hso.handleTurn(direction, state)
    local player = client
    local data = hso.pushingData[player]
    if not data or not isElement(data.vehicle) then return end

    if state == "down" then
        if isTimer(data.turnTimer) then killTimer(data.turnTimer) end
        data.turnTimer = setTimer(function(p, v)
            if not isElement(p) or not isElement(v) then return end
            local rx, ry, rz = getElementRotation(v)
            local newRz = rz
            if data.turnDirection == "left" then newRz = rz + hso.settings.turnSpeed
            elseif data.turnDirection == "right" then newRz = rz - hso.settings.turnSpeed end
            setElementRotation(v, rx, ry, newRz)
            setElementRotation(p, 0, 0, newRz)
        end, hso.settings.turnInterval, 0, player, data.vehicle)
        data.turnDirection = direction
    elseif state == "up" then
        if data.turnDirection == direction and isTimer(data.turnTimer) then
            killTimer(data.turnTimer)
            data.turnTimer = nil
            data.turnDirection = nil
        end
    end
end
addEvent("VehiclePush:onTurn", true)
addEventHandler("VehiclePush:onTurn", getRootElement(), hso.handleTurn)

function hso.getNearestVeh(player, maxDistance)
    local closestVehicle = false
    local shortestDistance = maxDistance + 1
    local pX, pY, pZ = getElementPosition(player)
    for _, vehicle in ipairs(getElementsByType("vehicle")) do
        local vX, vY, vZ = getElementPosition(vehicle)
        local currentDistance = getDistanceBetweenPoints3D(pX, pY, pZ, vX, vY, vZ)
        if currentDistance <= maxDistance and currentDistance < shortestDistance then
            closestVehicle = vehicle
            shortestDistance = currentDistance
        end
    end
    return closestVehicle
end

addEventHandler("onPlayerQuit", getRootElement(), function()
    if hso.pushingData[source] then
        hso.stopPushing(source)
    end
end)
