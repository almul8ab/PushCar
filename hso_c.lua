
-- by Hussein Ali 
hso = {}

hso.key = "n"
hso.isPushing = false
hso.isAnimLoaded = false
hso.textFormat = "Press %s to push"
hso.turnState = { left = false, right = false }

hso.translations = {
    ar = "للدفع أضغط حرف %s",
    en = "Press %s to push",
    es = "Presiona %s para empujar",
    de = "Drücke %s zum Schieben",
    ru = "Нажмите %s, чтобы толкать",
    tr = "İtmek için %s tuşuna basın"
}

function hso.updateAnim(playerName, start)
    local player = getPlayerFromName(playerName)
    if not isElement(player) or not hso.isAnimLoaded then return end

    if start then
        setPedAnimation(player, "push", "WALK_civi", -1, true, false, false, false)
        if player == localPlayer then
            hso.isPushing = true
        end
    else
        setPedAnimation(player)
        if player == localPlayer then
            hso.isPushing = false
            hso.turnState = { left = false, right = false }
        end
    end
end
addEvent("VehiclePush:updateAnim", true)
addEventHandler("VehiclePush:updateAnim", getRootElement(), hso.updateAnim)

function hso.onStart()
    if engineLoadIFP("push.ifp", "push") then
        hso.isAnimLoaded = true
    end
    local langCode = string.sub(getLocalization()["code"], 1, 2)
    hso.textFormat = hso.translations[langCode] or hso.translations["en"]
end
addEventHandler("onClientResourceStart", getResourceRootElement(getThisResource()), hso.onStart)

bindKey(hso.key, "down", function()
    triggerServerEvent("VehiclePush:onKey", localPlayer)
end)

function hso.handleTurn(key, state)
    if not hso.isPushing then return end
    
    local direction
    if key == "a" then
        direction = "left"
    elseif key == "d" then
        direction = "right"
    else
        return
    end
    
    local isPressed = (state == "down")
    
    if hso.turnState[direction] ~= isPressed then
        hso.turnState[direction] = isPressed
        triggerServerEvent("VehiclePush:onTurn", localPlayer, direction, state)
    end
end
bindKey("a", "both", hso.handleTurn)
bindKey("d", "both", hso.handleTurn)

addEventHandler("onClientRender", root, function()
    if getPedOccupiedVehicle(localPlayer) or hso.isPushing then return end
        
    local nearestVeh = hso.getNearestVeh(localPlayer, 4)
    if isElement(nearestVeh) and getVehicleType(nearestVeh) == "Automobile" and not getVehicleEngineState(nearestVeh) then
        local matrix = getElementMatrix(nearestVeh)
        local offX, offY, offZ = 0, -2.1, 0.7 
        local worldX = matrix[4][1] + matrix[1][1]*offX + matrix[2][1]*offY + matrix[3][1]*offZ
        local worldY = matrix[4][2] + matrix[1][2]*offX + matrix[2][2]*offY + matrix[3][2]*offZ
        local worldZ = matrix[4][3] + matrix[1][3]*offX + matrix[2][3]*offY + matrix[3][3]*offZ
        local screenX, screenY = getScreenFromWorldPosition(worldX, worldY, worldZ)
        
        if screenX then
            local text = string.format(hso.textFormat, string.upper(hso.key))
            dxDrawText(text, screenX - 100, screenY - 20, screenX + 100, screenY + 20, tocolor(0, 0, 0, 220), 1.2, "default-bold", "center", "center", false, false, true, true)
            dxDrawText(text, screenX - 102, screenY - 22, screenX + 98, screenY + 18, tocolor(255, 255, 255, 220), 1.2, "default-bold", "center", "center", false, false, true, true)
        end
    end
end)

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
