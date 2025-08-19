
-- by Hussein Ali 
Hussein = "n"

local pushSpeed = 0.04
local turnSpeed = 0.5
local playerAttachOffset = {0, -3.2, 0.3}

function handlePushKey(key, keyState)
    local player = client
    if key ~= Hussein then return end

    if keyState == "down" then
        if getElementData(player, "isPushingVehicle") then
            stopPushingVehicle(player)
        else
            local vehicle = getNearestVehicle(player, 4)
            if vehicle and getElementType(vehicle) == "vehicle" and not getVehicleEngineState(vehicle) and not getPedOccupiedVehicle(player) then
                attachElements(player, vehicle, playerAttachOffset[1], playerAttachOffset[2], playerAttachOffset[3])
                setElementData(player, "isPushingVehicle", vehicle)
                
                local pushTimer = setTimer(function(p, v)
                    if not isElement(p) or not isElement(v) then
                        if isTimer(getElementData(p, "pushingVehicleTimer")) then
                            stopPushingVehicle(p)
                        end
                        return
                    end

                    local rx, ry, rz = getElementRotation(v)
                    local velX = -math.sin(math.rad(rz)) * pushSpeed
                    local velY = math.cos(math.rad(rz)) * pushSpeed
                    setElementVelocity(v, velX, velY, 0)
                    
                end, 50, 0, player, vehicle)
                setElementData(player, "pushingVehicleTimer", pushTimer)
                triggerClientEvent(getRootElement(), "VehiclePush:updateAnim", getRootElement(), getPlayerName(player), true)
            end
        end
    end
end
addEvent("VehiclePush:onKey", true)
addEventHandler("VehiclePush:onKey", getRootElement(), handlePushKey)

function handleVehicleTurn(direction)
    local player = client
    if not getElementData(player, "isPushingVehicle") then return end

    local vehicle = getElementData(player, "isPushingVehicle")
    if vehicle and isElement(vehicle) then
        local rx, ry, rz = getElementRotation(vehicle)
        local newRz = rz

        if direction == "left" then
            newRz = rz + turnSpeed
        elseif direction == "right" then
            newRz = rz - turnSpeed
        end
        
        setElementRotation(vehicle, rx, ry, newRz)
        setElementRotation(player, 0, 0, newRz) 
    end
end
addEvent("VehiclePush:onTurn", true)
addEventHandler("VehiclePush:onTurn", getRootElement(), handleVehicleTurn)


function stopPushingVehicle(player)
    local timer = getElementData(player, "pushingVehicleTimer")
    if timer then
        killTimer(timer)
    end
    local vehicle = getElementData(player, "isPushingVehicle")
    if vehicle and isElement(vehicle) then
        setElementVelocity(vehicle, 0, 0, 0)
        if isElementAttached(player) then
            detachElements(player)
        end
    end
    
    removeElementData(player, "isPushingVehicle")
    removeElementData(player, "pushingVehicleTimer")
    triggerClientEvent(getRootElement(), "VehiclePush:updateAnim", getRootElement(), getPlayerName(player), false)
end

addEventHandler("onPlayerQuit", getRootElement(), function()
    stopPushingVehicle(source)
end)

function getNearestVehicle(player, maxDistance)
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