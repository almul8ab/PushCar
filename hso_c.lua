-- by Hussein Ali 

Hussein = "n"

local tranHso = {
    ar = "للدفع أضغط حرف %s",
    en = "Press %s to push",
    es = "Presiona %s para empujar",
    de = "Drücke %s zum Schieben",
    ru = "Нажмите %s, чтобы толкать",
    tr = "İtmek için %s tuşuna basın"
}

local isAnimationLoaded = false
local isPushing = false

bindKey(Hussein, "down", function(key, state)
    triggerServerEvent("VehiclePush:onKey", localPlayer, key, state)
end)

function updateAnimation(playerName, start)
    local player = getPlayerFromName(playerName)
    if isElement(player) then
        if not isAnimationLoaded then
            return
        end
        if start then
            setPedAnimation(player, "push", "WALK_civi", -1, true, false, false, false)
            if player == localPlayer then
                isPushing = true
            end
        else
            setPedAnimation(player)
            if player == localPlayer then
                isPushing = false
            end
        end
    end
end
addEvent("VehiclePush:updateAnim", true)
addEventHandler("VehiclePush:updateAnim", getRootElement(), updateAnimation)

function loadAnim()
    local success = engineLoadIFP("push.ifp", "push")
    if success then
        isAnimationLoaded = true
    end
end
addEventHandler("onClientResourceStart", getResourceRootElement(getThisResource()), loadAnim)

function getNearestVehicleClient(player, maxDistance)
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

addEventHandler("onClientRender", root,
    function()
        if isPushing then
            if getKeyState("a") then
                triggerServerEvent("VehiclePush:onTurn", localPlayer, "left")
            elseif getKeyState("d") then
                triggerServerEvent("VehiclePush:onTurn", localPlayer, "right")
            end
        end

        if not getPedOccupiedVehicle(localPlayer) and not isPushing then
            local nearestVeh = getNearestVehicleClient(localPlayer, 4)
            if isElement(nearestVeh) and getVehicleType(nearestVeh) == "Automobile" and not getElementData(nearestVeh, "engineState") then
                local matrix = getElementMatrix(nearestVeh)
                local offX, offY, offZ = 0, -2.1, 0.7 
                local worldX = matrix[4][1] + matrix[1][1]*offX + matrix[2][1]*offY + matrix[3][1]*offZ
                local worldY = matrix[4][2] + matrix[1][2]*offX + matrix[2][2]*offY + matrix[3][2]*offZ
                local worldZ = matrix[4][3] + matrix[1][3]*offX + matrix[2][3]*offY + matrix[3][3]*offZ
                local screenX, screenY = getScreenFromWorldPosition(worldX, worldY, worldZ)
                if screenX then
                    local langCode = string.sub(getLocalization()["code"], 1, 2)
                    local textFormat = tranHso[langCode] or tranHso["en"]
                    local text = string.format(textFormat, string.upper(Hussein))

                    dxDrawText(text, (screenX + 2) - 100, (screenY + 2) - 20, (screenX + 2) + 100, (screenY + 2) + 20, tocolor(0, 0, 0, 220), 1.2, "default-bold", "center", "center", false, false, true)
                    dxDrawText(text, screenX - 100, screenY - 20, screenX + 100, screenY + 20, tocolor(255, 255, 255, 220), 1.2, "default-bold", "center", "center", false, false, true)
                end
            end
        end
    end
)

setTimer(function()
    for _, vehicle in ipairs(getElementsByType("vehicle", localPlayer, true)) do
        if getElementData(vehicle, "engineState") == nil then
            triggerServerEvent("VehiclePush:syncEngineState", vehicle)
        end
    end
end, 2000, 0)