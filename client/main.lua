if not lib.checkDependency('ox_lib', '3.21.0', true) then return end

lib.locale()

local options = api.getTargetOptions()

local SendNuiMessage = SendNuiMessage
local GetEntityCoords = GetEntityCoords
local GetEntityType = GetEntityType
local HasEntityClearLosToEntity = HasEntityClearLosToEntity
local GetEntityBoneIndexByName = GetEntityBoneIndexByName
local GetEntityBonePosition_2 = GetEntityBonePosition_2
local GetEntityModel = GetEntityModel
local IsDisabledControlJustPressed = IsDisabledControlJustPressed
local DisableControlAction = DisableControlAction
local DisablePlayerFiring = DisablePlayerFiring
local GetModelDimensions = GetModelDimensions
local GetOffsetFromEntityInWorldCoords = GetOffsetFromEntityInWorldCoords
local currentTarget = {}
local currentMenu
local menuChanged
local menuHistory = {}
local nearbyZones

-- Toggle ox_target, instead of holding the hotkey
local toggleHotkey = GetConvarInt('ox_target:toggleHotkey', 0) == 1
local mouseButton = GetConvarInt('ox_target:leftClick', 1) == 1 and 24 or 25
local debug = false
local vec0 = vec3(0, 0, 0)

local currentArrData = {}


UIRoutes = { }

RegisterNUICallback('useUIRoute', function(data, cb)
    local route, data in data

    local handler = UIRoutes[route]

    assert(handler ~= nil, ('Rota (%s) inválida'):format(route) )

    local response = handler(data) or { }

    cb(response)
end)

function nuiDrawRender(data)
    currentArrData = {}
    sendReactMessage( 'setTarget', currentArrData)

    if data.event == "leftTarget" then
        -- print(" LEFTTTTTTTTTTTTTTTTTTTTTTT ")
        sendReactMessage( 'leftTarget' )
    end

    if data.event == "setTarget" then
        local screen = { x = 0.5, y = 0.5 }

        if data.options then
            for optionType, items in pairs( data.options ) do 
                if items then
                    for i, item in pairs( items ) do 
                        item.type = optionType
                        item.id = i

                        if item.screen then
                           screen = { x = item.screen.x, y = item.screen.y }
                        end

                        if not item.hide then
                            table.insert( currentArrData, item )
                        end
                    end
                end
            end
        end

        if data.zones and data.zones.options then
            for zoneId, options in pairs( data.zones.options ) do 
                for i, item in pairs( options ) do 
                    item.id = i
                    item.type = "zones"
                    item.zoneId = zoneId
                    if not item.hide then
                        table.insert( currentArrData, item )
                    end
                end
            end

            if data.zones.screen then
                screen = {x = data.zones.screen.x, y = data.zones.screen.y }
            end
        end

        if #currentArrData >= 1 then
            state.setSelectedIndex(1)
        end

        -- sendReactMessage( 'setScreenPosition', screen)

        -- print(" currentArrData :: ", #currentArrData)
        sendReactMessage( 'setTarget', currentArrData)
    end
end

local canPress = true
-- canPressAgain

function UIRoutes.canPressAgain()
    canPress = true
end

CreateThread(function()
    while true do 
        local tickTime = 1000

        if state.isActive() then
            if currentArrData and #currentArrData >= 1 then

                if not IsPedRagdoll(PlayerPedId()) then

                    DisableControlAction(0, `INPUT_MELEE_GRAPPLE_CHOKE`, true)
                    DisableControlAction(0, `INPUT_GAME_MENU_TAB_RIGHT`, true)
                    DisableControlAction(0, `INPUT_LOOT_VEHICLE`, true)
                    DisableControlAction(0, `INPUT_FRONTEND_RB`, true)
                    DisableControlAction(0, `INPUT_INTERACT_LEAD_ANIMAL`, true)
                    DisableControlAction(0, `INPUT_MELEE_GRAPPLE`, true)
                    DisableControlAction(0, `INPUT_DYNAMIC_SCENARIO`, true)
                    DisableControlAction(0, `INPUT_LOOT2`, true)
                    DisableControlAction(0, `INPUT_LOOT`, true)
                    DisableControlAction(0, `INPUT_REVIVE`, true)
                    DisableControlAction(0, `INPUT_SHOP_INSPECT`, true)
                    DisableControlAction(0, `INPUT_MELEE_GRAPPLE_REVERSAL`, true)
                    DisableControlAction(0, `INPUT_BREAK_VEHICLE_LOCK`, true)
                    DisableControlAction(0, `INPUT_MAP_POI`, true)
                    DisableControlAction(0, `INPUT_INTERACT_LOCKON_ROB`, true)
                    DisableControlAction(0, `INPUT_ARREST`, true)
                    DisableControlAction(0, `INPUT_HITCH_ANIMAL`, true)
                    DisableControlAction(0, `INPUT_IGNITE`, true)
                    DisableControlAction(0, `INPUT_ENTER`, true)
                    DisableControlAction(0, `INPUT_CONTEXT_Y`, true)
                    DisableControlAction(0, `INPUT_SURRENDER`, true)
                    DisableControlAction(0, `INPUT_SHOP_BUY`, true)
                    DisableControlAction(0, `INPUT_INTERACT_LOCKON_TRACK_ANIMAL`, true)
                    DisableControlAction(0, `INPUT_INTERACT_LOCKON_DETACH_HORSE`, true)
                    DisableControlAction(0, `INPUT_CRAFTING_EAT`, true)
                    DisableControlAction(0, `INPUT_HORSE_EXIT`, true)
                    DisableControlAction(0, `INPUT_VEH_EXIT`, true)
                    DisableControlAction(0, `INPUT_RADIAL_MENU_SLOT_NAV_NEXT`, true)

                    local selectedIndex = state.selectedIndex()

                    -- Controle para navegar na lista
                    if IsControlJustPressed(0, `INPUT_PREV_WEAPON`) then     -- Cima
                        state.setSelectedIndex(selectedIndex > 1 and selectedIndex - 1 or 1)
                        Wait(200)
                    elseif IsControlJustPressed(0, `INPUT_NEXT_WEAPON`) then -- Baixo
                        state.setSelectedIndex(selectedIndex < #currentArrData and selectedIndex + 1 or #currentArrData)
                        Wait(200)
                    end

                    tickTime = 0

                    if IsDisabledControlJustPressed(0, `INPUT_ENTER`) and currentArrData[selectedIndex] and canPress then
                        local item = currentArrData[selectedIndex]

                        pcall(function()
                            selectInteractivePoint( {item.type, item.id, item.zoneId}  )
                            sendReactMessage( 'pressed' )
                        end)

                        canPress = false

                        tickTime = 200
                    end
                end
            end
        end

        Wait(tickTime)
    end
end)

---@param option OxTargetOption
---@param distance number
---@param endCoords vector3
---@param entityHit? number
---@param entityType? number
---@param entityModel? number | false
local function shouldHide(option, distance, endCoords, entityHit, entityType, entityModel)
    if option.menuName ~= currentMenu then
        return true
    end

    if distance > (option.distance or 7) then
        return true
    end

    if option.groups and not utils.hasPlayerGotGroup(option.groups) then
        return true
    end

    if option.items and not utils.hasPlayerGotItems(option.items, option.anyItem) then
        return true
    end

    local bone = entityModel and option.bones or nil

    if bone then
        ---@cast entityHit number
        ---@cast entityType number
        ---@cast entityModel number

        local _type = type(bone)

        if _type == 'string' then
            local boneId = GetEntityBoneIndexByName(entityHit, bone)

            if boneId ~= -1 and #(endCoords - GetEntityBonePosition_2(entityHit, boneId)) <= 2 then
                bone = boneId
            else
                return true
            end
        elseif _type == 'table' then
            local closestBone, boneDistance

            for j = 1, #bone do
                local boneId = GetEntityBoneIndexByName(entityHit, bone[j])

                if boneId ~= -1 then
                    local dist = #(endCoords - GetEntityBonePosition_2(entityHit, boneId))

                    if dist <= (boneDistance or 1) then
                        closestBone = boneId
                        boneDistance = dist
                    end
                end
            end

            if closestBone then
                bone = closestBone
            else
                return true
            end
        end
    end

    local offset = entityModel and option.offset or nil

    if offset then
        ---@cast entityHit number
        ---@cast entityType number
        ---@cast entityModel number

        if not option.absoluteOffset then
            local min, max = GetModelDimensions(entityModel)
            offset = (max - min) * offset + min
        end

        offset = GetOffsetFromEntityInWorldCoords(entityHit, offset.x, offset.y, offset.z)

        if #(endCoords - offset) > (option.offsetSize or 1) then
            return true
        end
    end

    if option.canInteract then
        local success, resp = pcall(option.canInteract, entityHit, distance, endCoords, option.name, bone)
        return not success or not resp
    end
end


local RotationToDirection = function(rotation)
	local adjustedRotation = {x = (math.pi / 180) * rotation.x,y = (math.pi / 180) * rotation.y,z = (math.pi / 180) * rotation.z}
	local direction = {
		x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), 
		y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), 
		z = math.sin(adjustedRotation.x)
	}
	return direction
end

local RayCastGamePlayCamera = function(distance)
    local cameraRotation = GetGameplayCamRot()
	local cameraCoord = GetGameplayCamCoord()
	local direction = RotationToDirection(cameraRotation)
	local destination = {x = cameraCoord.x + direction.x * distance,y = cameraCoord.y + direction.y * distance,z = cameraCoord.z + direction.z * distance}
	local a, b, c, d, e = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, -1, PlayerPedId(), 0))
	return b, c, e
end


local function startTargeting()
    if state.isDisabled() or state.isActive() or IsNuiFocused() or IsPauseMenuActive() then return end

    state.setActive(true)

    local flag = 3167 
    local hit, entityHit, endCoords, distance, lastEntity, entityType, entityModel, hasTarget, zonesChanged
    local zones = {}

    CreateThread(function()
        local dict, texture = utils.getTexture()
        local lastCoords

        while state.isActive() do
            lastCoords = endCoords == vec0 and lastCoords or endCoords or vec0

            if debug then
                DrawMarker(0x50638AB9, lastCoords.x, lastCoords.y, lastCoords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.1, 0.1,
                    0.1,
                    ---@diagnostic disable-next-line: param-type-mismatch
                    255, 42, 24, 100, false, false, 0, true, false, false, false)
            end

            utils.drawZoneSprites(dict, texture, options)
            -- DisablePlayerFiring(cache.playerId, true)
            -- DisableControlAction(0, 25, true)
            -- DisableControlAction(0, 140, true)
            -- DisableControlAction(0, 141, true)
            -- DisableControlAction(0, 142, true)

            -- if state.isNuiFocused() then
            --     -- DisableControlAction(0, 1, true)
            --     -- DisableControlAction(0, 2, true)

            --     if not hasTarget or options and IsDisabledControlJustPressed(0, 25) then
            --         -- state.setNuiFocus(false, false)
            --     end
            -- elseif hasTarget and IsDisabledControlJustPressed(0, mouseButton) then
            --     -- state.setNuiFocus(true, true)
            -- end

            Wait(0)
        end

        SetStreamedTextureDictAsNoLongerNeeded(dict)
    end)

    while state.isActive() do
        if not state.isNuiFocused() and lib.progressActive() then
            state.setActive(false)
            break
        end

        local playerCoords = GetEntityCoords(cache.ped)
        hit, entityHit, endCoords = lib.raycast.fromCamera(flag, 4, 20)

        -- hit, endCoords, entityHit = RayCastGamePlayCamera(50.0)

        -- DrawLine(playerCoords.x, playerCoords.y, playerCoords.z, endCoords.x, endCoords.y, endCoords.z, 255, 200, 200, 255)

        distance = #(playerCoords - endCoords)

        if entityHit ~= 0 and entityHit ~= lastEntity then
            local success, result = pcall(GetEntityType, entityHit)
            entityType = success and result or 0
        end

        if entityType == 0 then
            local _flag = flag == 511 and 26 or 511
            -- _hit, _endCoords, _entityHit = RayCastGamePlayCamera(50.0)
            _hit, _entityHit, _endCoords = lib.raycast.fromCamera(_flag, 4, 20)
            local _distance = #(playerCoords - _endCoords)

            if _distance < distance then
                flag, hit, entityHit, endCoords, distance = _flag, _hit, _entityHit, _endCoords, _distance

                if entityHit ~= 0 then
                    local success, result = pcall(GetEntityType, entityHit)
                    entityType = success and result or 0
                end
            end
        end

        nearbyZones, zonesChanged = utils.getNearbyZones(endCoords)
        -- print(" entityHit :: ", hit, entityHit, lastEntity)

        local entityChanged = entityHit ~= lastEntity
        local newOptions = (zonesChanged or entityChanged or menuChanged) and true

        if entityHit > 0 and entityChanged then
            currentMenu = nil

            if flag ~= 511 then
                entityHit = HasEntityClearLosToEntity(entityHit, cache.ped, 7) and entityHit or 0
            end

            if lastEntity ~= entityHit and debug then
                if lastEntity then
                    -- SetEntityDrawOutline(lastEntity, false)
                end

                if entityType ~= 1 then
                    -- SetEntityDrawOutline(entityHit, true)
                end
            end

            if entityHit > 0 then
                local success, result = pcall(GetEntityModel, entityHit)
                entityModel = success and result
            end
        end

        if hasTarget and (zonesChanged or (entityChanged and hasTarget >= 1)) then

            -- print(" LEFT 2 :: ")
            nuiDrawRender( {event= "leftTarget"} )

            if entityChanged then options:wipe() end
            -- if debug and lastEntity > 0 then SetEntityDrawOutline(lastEntity, false) end
            hasTarget = false
        end

        if newOptions and entityModel and entityHit > 0 then
            options:set(entityHit, entityType, entityModel)
        end

        lastEntity = entityHit
        currentTarget.entity = entityHit
        currentTarget.coords = endCoords
        currentTarget.distance = distance
        local hidden = 0
        local totalOptions = 0

        for k, v in pairs(options) do
            local optionCount = #v
            local dist = k == '__global' and 0 or distance
            totalOptions += optionCount

            for i = 1, optionCount do
                local option = v[i]
                local hide = shouldHide(option, dist, endCoords, entityHit, entityType, entityModel)
                local entityCoords = GetEntityCoords(entityHit)
                option.coords = entityCoords

                if option.hide ~= hide then
                    option.hide = hide
                    newOptions = true
                end

                if hide then hidden += 1 end
            end
        end

        if zonesChanged then table.wipe(zones) end

        for i = 1, #nearbyZones do
            local zone = nearbyZones[i]
            local zoneOptions = zone?.options
            if zone and zoneOptions then 
                local optionCount = #zoneOptions
                totalOptions += optionCount
                zones.coords = nearbyZones[i].coords
                zones.options = {}
                
                zones.options[i] = zoneOptions

                for j = 1, optionCount do
                    local option = zoneOptions[j]
                    local hide  =  shouldHide(option, distance, endCoords, entityHit)

                    if option.hide ~= hide then
                        option.hide = hide
                        newOptions = true
                    end

                    if hide then hidden += 1 end
                end
            end
        end

        if newOptions then
            if hasTarget == 1 and options.size > 1 then
                hasTarget = true
            end

            if hasTarget and hidden == totalOptions then
                if hasTarget and hasTarget ~= 1 then
                    hasTarget = false
                    -- print(" LEFT 1 :: ")

                    nuiDrawRender({event= "leftTarget"})
                end
            elseif menuChanged or hasTarget ~= 1 and hidden ~= totalOptions then
                hasTarget = options.size

                if currentMenu and options.__global[1]?.name ~= 'builtin:goback' then
                    table.insert(options.__global, 1,
                        {
                            icon = 'fa-solid fa-circle-chevron-left',
                            label = locale('go_back'),
                            name = 'builtin:goback',
                            menuName = currentMenu,
                            openMenu = 'home'
                        })
                end

                nuiDrawRender({
                    event = 'setTarget',
                    options = options,
                    zones = zones,
                })

                -- SendNuiMessage(json.encode({
                --     event = 'setTarget',
                --     options = options,
                --     zones = zones,
                -- }, { sort_keys = true }))
            end

            menuChanged = false
        end

        if toggleHotkey and IsPauseMenuActive() then
            state.setActive(false)
        end

        if not hasTarget or hasTarget == 1 then
            flag = flag == 511 and 26 or 511
        end

        Wait(hit and 50 or 100)
        -- if debug then
            -- print("HasTarget:", hasTarget, "Hidden:", hidden, "Total:", totalOptions)
        -- end
        
    end

    if lastEntity and debug then
        -- SetEntityDrawOutline(lastEntity, false)
    end


    
    -- state.setNuiFocus(false)
    nuiDrawRender({event= "visible", state= false})
    table.wipe(currentTarget)
    options:wipe()

    if nearbyZones then table.wipe(nearbyZones) end

    
end


-- CreateThread( function()

--     while true do

--             if not state.isNuiFocused() and lib.progressActive() then
--                 state.setActive(false)
--                 break
--             end
    
--             local playerCoords = GetEntityCoords(cache.ped)
--             hit, entityHit, endCoords = lib.raycast.fromCamera(flag, 4, 20)
--             distance = #(playerCoords - endCoords)
    
--             if entityHit ~= 0 and entityHit ~= lastEntity then
--                 local success, result = pcall(GetEntityType, entityHit)
--                 entityType = success and result or 0
--             end
    
--             if entityType == 0 then
--                 local _flag = flag == 511 and 26 or 511
--                 local _hit, _entityHit, _endCoords = lib.raycast.fromCamera(_flag, 4, 20)
--                 local _distance = #(playerCoords - _endCoords)
    
--                 if _distance < distance then
--                     flag, hit, entityHit, endCoords, distance = _flag, _hit, _entityHit, _endCoords, _distance
    
--                     if entityHit ~= 0 then
--                         local success, result = pcall(GetEntityType, entityHit)
--                         entityType = success and result or 0
--                     end
--                 end
--             end
    
--             nearbyZones, zonesChanged = utils.getNearbyZones(endCoords)
    
--             local entityChanged = entityHit ~= lastEntity
--             local newOptions = (zonesChanged or entityChanged or menuChanged) and true
    
--             if entityHit > 0 and entityChanged then
--                 currentMenu = nil
    
--                 if flag ~= 511 then
--                     entityHit = HasEntityClearLosToEntity(entityHit, cache.ped, 7) and entityHit or 0
--                 end
    
--                 if lastEntity ~= entityHit and debug then
--                     if lastEntity then
--                         -- SetEntityDrawOutline(lastEntity, false)
--                     end
    
--                     if entityType ~= 1 then
--                         -- SetEntityDrawOutline(entityHit, true)
--                     end
--                 end
    
--                 if entityHit > 0 then
--                     local success, result = pcall(GetEntityModel, entityHit)
--                     entityModel = success and result
--                 end
--             end
    
--             if hasTarget and (zonesChanged or entityChanged and hasTarget > 1) then
--                 nuiDrawRender({event= "leftTarget"})
                
--                 -- sendReactMessage( 'leftTarget', {})

--                 -- SendNuiMessage('{"event": "leftTarget"}')
    
--                 if entityChanged then options:wipe() end
    
--                 -- if debug and lastEntity > 0 then SetEntityDrawOutline(lastEntity, false) end
    
--                 hasTarget = false
--             end
    
--             if newOptions and entityModel and entityHit > 0 then
--                 options:set(entityHit, entityType, entityModel)
--             end
    
--             lastEntity = entityHit
--             currentTarget.entity = entityHit
--             currentTarget.coords = endCoords
--             currentTarget.distance = distance
--             local hidden = 0
--             local totalOptions = 0
    
--             for k, v in pairs(options) do
--                 local optionCount = #v
--                 local dist = k == '__global' and 0 or distance
--                 totalOptions += optionCount
    
--                 for i = 1, optionCount do
--                     local option = v[i]
--                     local hide = shouldHide(option, dist, endCoords, entityHit, entityType, entityModel)
--                     local entityCoords = GetEntityCoords(entityHit)
--                     option.coords = entityCoords
                    
--                     local onScreen, _x, _y = GetScreenCoordFromWorldCoord(entityCoords.x, entityCoords.y, entityCoords.z)
--                     option.screen = { x = _x, y = _y}

                    
    
--                     if option.hide ~= hide then
--                         option.hide = hide
--                         newOptions = true
--                     end
    
--                     if hide then hidden += 1 end
--                 end
--             end
    
--             if zonesChanged then table.wipe(zones) end
    
--             for i = 1, #nearbyZones do
--                 local zoneOptions = nearbyZones[i].options
--                 local optionCount = #zoneOptions
--                 totalOptions += optionCount
--                 zones.coords = nearbyZones[i].coords
--                 zones.options = {}
                
--                 zones.options[i] = zoneOptions
        
                    
--                 -- local onScreen, _x, _y = GetScreenCoordFromWorldCoord(entityCoords.x, entityCoords.y, entityCoords.z)
--                 -- option.screen = { x = _x, y = _y}
    
--                 for j = 1, optionCount do
--                     local option = zoneOptions[j]
--                     local hide = shouldHide(option, distance, endCoords, entityHit)
    
--                     if option.hide ~= hide then
--                         option.hide = hide
--                         newOptions = true
--                     end
    
--                     if hide then hidden += 1 end
--                 end
--             end
    
--             if newOptions then
--                 if hasTarget == 1 and options.size > 1 then
--                     hasTarget = true
--                 end
    
--                 if hasTarget and hidden == totalOptions then
--                     if hasTarget and hasTarget ~= 1 then
--                         hasTarget = false
    
--                         -- sendReactMessage( 'leftTarget', {})
--                         -- SendNuiMessage('{"event": "leftTarget"}')
--                         nuiDrawRender({event= "leftTarget"})
--                     end
--                 elseif menuChanged or hasTarget ~= 1 and hidden ~= totalOptions then
--                     hasTarget = options.size
    
--                     if currentMenu and options.__global[1]?.name ~= 'builtin:goback' then
--                         table.insert(options.__global, 1,
--                             {
--                                 icon = 'fa-solid fa-circle-chevron-left',
--                                 label = locale('go_back'),
--                                 name = 'builtin:goback',
--                                 menuName = currentMenu,
--                                 openMenu = 'home'
--                             })
--                     end
    
--                     nuiDrawRender({
--                         event = 'setTarget',
--                         options = options,
--                         zones = zones,
--                     })
    

--                 end
    
--                 menuChanged = false
--             end
    
--             if toggleHotkey and IsPauseMenuActive() then
--                 state.setActive(false)
--             end
    
--             if not hasTarget or hasTarget == 1 then
--                 flag = flag == 511 and 26 or 511
--             end

            
    
--             Wait(hit and 50 or 100)
    

--         -- if not state.isActive() then
--         --     state.setActive(true)
--         -- end

--         -- Wait(0)
--     end
-- end)

local function fakeAddKeybind(keybind)

    local lastPressedState = false

    CreateThread(function()
        while true do 

            if keybind then
                if IsControlJustReleased(0, keybind.defaultKey) and lastPressedState then
                    lastPressedState = false
                    keybind:onReleased()
                end

                if IsControlJustPressed(0, keybind.defaultKey) and not lastPressedState then
                    lastPressedState = true

                    CreateThread(function()
                        keybind:onPressed()
                    end)
                end
            end

            Wait(0)
        end
    end)
end

-- - Theres no need because targeting is fully
do
    ---@type KeybindProps
    local keybind = {
        name = 'ox_target',
        defaultKey = `INPUT_PC_FREE_LOOK`,-- `INPUT_INTERACT_LOCKON`, --GetConvar('ox_target:defaultHotkey', 'LMENU'),
        -- defaultMapper = 'keyboard',
        description = locale('toggle_targeting'),
    }

    if toggleHotkey then
        function keybind:onPressed()
            if state.isActive() then
                return state.setActive(false)
            end

            return startTargeting()
        end
    else
        keybind.onPressed = startTargeting

        function keybind:onReleased()
            state.setActive(false)
        end
    end

    fakeAddKeybind(keybind)
end

---@generic T
---@param option T
---@param server? boolean
---@return T
local function getResponse(option, server)
    local response = table.clone(option)
    response.entity = currentTarget.entity
    response.zone = currentTarget.zone
    response.coords = currentTarget.coords
    response.distance = currentTarget.distance

    if server then
        response.entity = response.entity ~= 0 and NetworkGetEntityIsNetworked(response.entity) and
            NetworkGetNetworkIdFromEntity(response.entity) or 0
    end

    response.icon = nil
    response.groups = nil
    response.items = nil
    response.canInteract = nil
    response.onSelect = nil
    response.export = nil
    response.event = nil
    response.serverEvent = nil
    response.command = nil

    return response
end

function selectInteractivePoint(data)
    local zone = data[3] and nearbyZones[data[3]]

    ---@type OxTargetOption?
    local option = zone and zone.options[data[2]] or options[data[1]][data[2]]

    if option then
        if option.openMenu then
            local menuDepth = #menuHistory

            if option.name == 'builtin:goback' then
                option.menuName = option.openMenu
                option.openMenu = menuHistory[menuDepth]

                if menuDepth > 0 then
                    menuHistory[menuDepth] = nil
                end
            else
                menuHistory[menuDepth + 1] = currentMenu
            end

            menuChanged = true
            currentMenu = option.openMenu ~= 'home' and option.openMenu or nil

            options:wipe()
        else
            state.setNuiFocus(false)
        end

        currentTarget.zone = zone?.id

        if option.onSelect then
            option.onSelect(option.qtarget and currentTarget.entity or getResponse(option))
        elseif option.export then
            exports[option.resource or zone.resource][option.export](nil, getResponse(option))
        elseif option.event then
            TriggerEvent(option.event, getResponse(option))
        elseif option.serverEvent then
            TriggerServerEvent(option.serverEvent, getResponse(option, true))
        elseif option.command then
            ExecuteCommand(option.command)
        end

        if option.menuName == 'home' then return end
    end

    if not option?.openMenu and IsNuiFocused() then
        state.setActive(false)
    end
end