utils = {}

local GetWorldCoordFromScreenCoord = GetWorldCoordFromScreenCoord
local StartShapeTestLosProbe = StartShapeTestLosProbe
local GetShapeTestResultIncludingMaterial = GetShapeTestResultIncludingMaterial

---@param flag number
---@return boolean hit
---@return number entityHit
---@return vector3 endCoords
---@return vector3 surfaceNormal
---@return number materialHash
function utils.raycastFromCamera(flag)
    local coords, normal = GetWorldCoordFromScreenCoord(0.5, 0.5)
    local destination = coords + normal * 10
    local handle = StartShapeTestLosProbe(coords.x, coords.y, coords.z, destination.x, destination.y, destination.z,
        flag, cache.ped, 4)

    while true do
        Wait(0)
        local retval, hit, endCoords, surfaceNormal, materialHash, entityHit = GetShapeTestResultIncludingMaterial(
        handle)

        if retval ~= 1 then
            ---@diagnostic disable-next-line: return-type-mismatch
            return hit, entityHit, endCoords, surfaceNormal, materialHash
        end
    end
end

function utils.getTexture()
    return lib.requestStreamedTextureDict('ammo_types'), 'tomahawk_normal'
end

function utils.getItemTexture()
    return lib.requestStreamedTextureDict('generic_textures'), 'selection_box_bg_1a'
end

-- SetDrawOrigin is limited to 32 calls per frame. Set as 0 to disable.
local drawZoneSprites = GetConvarInt('ox_target:DrawTexture', 24)
local SetDrawOrigin = SetDrawOrigin
local DrawTexture = DrawTexture
local ClearDrawOrigin = ClearDrawOrigin
local colour = vector(155, 155, 155, 175)
local hover = vector(98, 135, 236, 255)
local currentZones = {}
local previousZones = {}
local drawZones = {}
local drawN = 0
local _aspectRatio = 16 / 9
local width = 0.02
local height = width * _aspectRatio --GetAspectRatio(false)

if drawZoneSprites == 0 then drawZoneSprites = -1 end

---@param coords vector3
---@return CZone[], boolean
function utils.getNearbyZones(coords)
    if not Zones then return currentZones, false end

    local n = 0
    drawN = 0
    previousZones, currentZones = currentZones, table.wipe(previousZones)

    for _, zone in pairs(Zones) do
        local contains = zone:contains(coords)

        if contains then
            n += 1
            currentZones[n] = zone
        end

        if drawN <= drawZoneSprites and zone.DrawTexture ~= false and (contains or (zone.distance or 7) < 7) then
            drawN += 1
            drawZones[drawN] = zone
            zone.colour = contains and hover or nil
        end
    end

    local previousN = #previousZones

    if n ~= previousN then
        return currentZones, true
    end

    if n > 0 then
        for i = 1, n do
            local zoneA = currentZones[i]
            local found = false

            for j = 1, previousN do
                local zoneB = previousZones[j]

                if zoneA == zoneB then
                    found = true
                    break
                end
            end

            if not found then
                return currentZones, true
            end
        end
    end

    return currentZones, false
end

function utils.drawZoneSprites(dict, texture, options)

    for k, v in pairs(options) do
        local optionCount = #v
        for i = 1, optionCount do
            local option = v[i]
        end
    end 

    if drawN == 0 then return end

    for i = 1, drawN do
        local zone = drawZones[i]
        local spriteColour = zone.colour or colour

        local isHovered = false

        local currentItem = state.currentItemHover()

        if currentItem and currentItem.coords then
            isHovered = #(currentItem.coords - zone.coords) < 1
        end

        if zone.DrawTexture ~= false and not isHovered then
            SetDrawOrigin(zone.coords.x, zone.coords.y, zone.coords.z)

            -- Citizen.InvokeNative(0x2A32FAA57B937173, 0x50638AB9, zone.coords.x, zone.coords.y, zone.coords.z, 0,0,0,0,0,0, 0.025, 0.025, 0.025, spriteColour.r, spriteColour.g, spriteColour.b, spriteColour.a, 0, 0, 2, 0, 0, 0, 0)
            Citizen.InvokeNative(0x2A32FAA57B937173, 0x94FDAE17, zone.coords.x, zone.coords.y, zone.coords.z - 0.98, 0,0,0,0,0,0, 0.01, 0.01, 1.0, spriteColour.r, spriteColour.g, spriteColour.b, spriteColour.a, 0, 0, 2, 0, 0, 0, 0)
            -- DrawTexture(dict, texture, 0, 0, width - 0.01, height - 0.018, 0, spriteColour.r, spriteColour.g, spriteColour.b, spriteColour.a)
        end
    end

    ClearDrawOrigin()
end

local createdItems = {}

function utils.drawInteractValues(data, cb)
    -- Tamanho do texto

    local selectedIndex = state.selectedIndex()
    DisableControlAction(0, `INPUT_ENTER`, true)
    DisableControlAction(0, `INPUT_ARREST`, true)
    DisableControlAction(0, `INPUT_MELEE_GRAPPLE`, true)
    DisableControlAction(0, `INPUT_MELEE_GRAPPLE_REVERSAL`, true)
    DisableControlAction(0, `INPUT_SURRENDER`, true)

    createdItems = {}

    if data.options then
        for targetType, options in pairs(data.options) do
            for i, option in ipairs(options) do
                if not option.hide then
                    utils.createInteractItem(#createdItems + 1, option, targetType, nil, cb)
                end
            end
        end
    end

    if data.zones.options then
        for _, options in pairs(data.zones.options) do
            for i, option in ipairs(options) do
                if not option.hide then
                    option.coords = data.zones.coords
                    utils.createInteractItem(#createdItems + 1, option, "zones", _, cb)
                end
            end
        end
    end

    -- Controle para navegar na lista
    if IsControlJustPressed(0, `INPUT_PREV_WEAPON`) then     -- Cima
        state.setSelectedIndex(selectedIndex > 1 and selectedIndex - 1 or #createdItems)
    elseif IsControlJustPressed(0, `INPUT_NEXT_WEAPON`) then -- Baixo
        state.setSelectedIndex(selectedIndex < #createdItems and selectedIndex + 1 or 1)
    end
end

function utils.createInteractItem(i, option, targetType, zoneId, cb)
    local onScreen, _x, _y = GetScreenCoordFromWorldCoord(option.coords.x, option.coords.y, option.coords.z)

    local baseX, baseY = _x, _y
    local itemHeight = 0.025                     -- Altura entre itens
    local spriteWidth, spriteHeight = 0.1, 0.031 -- Tamanho do sprite de fundo
    local textScale = 0.30

    local itemY = baseY + (i - 1) * itemHeight

    local isHovered = i == state.selectedIndex()

    local hoverColor = { 255, 255, 255 }
    local normalColor = { 200, 200, 200 }

    -- Define as cores para o item selecionado ou não selecionado
    local color = isHovered and hoverColor or normalColor

    if IsDisabledControlJustPressed(0, `INPUT_ENTER`) and isHovered then
        cb({targetType, i, zoneId})
    end

    -- Desenha o fundo
    -- DrawTexture("generic_textures", "selection_box_bg_1a", baseX, itemY, spriteWidth + 0.003, spriteHeight - 0.007, 0.0, 0, 0, 0, 220)

    local itemColorBg = isHovered and { r = 80, g = 80, b = 80 } or { r = 52, g = 52, b = 52 }

    DrawTexture("generic_textures", "selection_box_bg_1d", baseX, itemY, spriteWidth + 0.003, spriteHeight - 0.007, 0.0, 0, 0, 0, 220)

    -- Desenha o texto alinhado à esquerda
    SetTextFontForCurrentCommand(9)
    SetTextScale(textScale, textScale)
    SetTextColor(color[1], color[2], color[3], 255)
    SetTextJustification(1)
    SetTextWrap(baseX - spriteWidth / 2, baseX + spriteWidth / 2)

    -- local str = CreateVarString(10, "LITERAL_STRING", option.label)
    -- DisplayText(str, baseX - spriteWidth / 2 + 0.01, itemY - spriteHeight / 2 + 0.005)

    -- Desenha o botão de interação no item selecionado
    if isHovered then
        local str2 = CreateVarString(10, "LITERAL_STRING", "E")
        SetTextFontForCurrentCommand(1)
        SetTextCentre(true)
        SetTextScale(0.4, 0.4)
        SetTextColor(20, 20, 20, 255)
        DisplayText(str2, baseX - spriteWidth / 2 - 0.02, itemY - 0.015)
        DrawTexture("generic_textures", "hud_menu_grid", baseX - spriteWidth / 2 - 0.02, itemY, 0.015, 0.025, 0.0, 255,
            255, 255, 255)
    end

    table.insert(createdItems, i)
end

function utils.drawText3D(text, x, y, z, h, w)
    local dict, texture = utils.getItemTexture()

    local str = CreateVarString(10, "LITERAL_STRING", text)

    SetDrawOrigin(x, y, z)

    SetTextScale(h, w)
    SetTextFontForCurrentCommand(1)

    SetTextColor(255, 255, 255, 215)
    local factor = (string.len(text)) / 225
    local _x, _y = 0, 0

    DisplayText(str, _x, _y)
    DrawTexture(dict, texture, _x + (factor - 0.015), _y + 0.010, 0.015 + factor, 0.03, 0, 20, 20, 20, 220)
end

function utils.hasExport(export)
    local resource, exportName = string.strsplit('.', export)

    return pcall(function()
        return exports[resource][exportName]
    end)
end

local playerItems = {}

function utils.getItems()
    return playerItems
end

---@param filter string | string[] | table<string, number>
---@param hasAny boolean?
---@return boolean
function utils.hasPlayerGotItems(filter, hasAny)
    if not playerItems then return true end

    local _type = type(filter)

    if _type == 'string' then
        return (playerItems[filter] or 0) > 0
    elseif _type == 'table' then
        local tabletype = table.type(filter)

        if tabletype == 'hash' then
            for name, amount in pairs(filter) do
                local hasItem = (playerItems[name] or 0) >= amount

                if hasAny then
                    if hasItem then return true end
                elseif not hasItem then
                    return false
                end
            end
        elseif tabletype == 'array' then
            for i = 1, #filter do
                local hasItem = (playerItems[filter[i]] or 0) > 0

                if hasAny then
                    if hasItem then return true end
                elseif not hasItem then
                    return false
                end
            end
        end
    end

    return not hasAny
end

---stub
---@param filter string | string[] | table<string, number>
---@return boolean
function utils.hasPlayerGotGroup(filter)
    return true
end

SetTimeout(0, function()
    if utils.hasExport('ox_inventory.Items') then
        setmetatable(playerItems, {
            __index = function(self, index)
                self[index] = exports.ox_inventory:Search('count', index) or 0
                return self[index]
            end
        })

        AddEventHandler('ox_inventory:itemCount', function(name, count)
            playerItems[name] = count
        end)
    end

end)

function utils.warn(msg)
    local trace = Citizen.InvokeNative(`FORMAT_STACK_TRACE` & 0xFFFFFFFF, nil, 0, Citizen.ResultAsString())
    local _, _, src = string.strsplit('\n', trace, 4)

    warn(('%s ^0%s\n'):format(msg, src:gsub(".-%(", '(')))
end


function DrawTexture(textureStreamed,textureName,x, y, width, height,rotation,r, g, b, a, p11)


    while not HasStreamedTextureDictLoaded(textureStreamed) do 
        Wait(0)
        RequestStreamedTextureDict(textureStreamed, false)
    end
    
    DrawSprite(textureStreamed, textureName, x, y, width, height, rotation, r, g, b, a, p11);
end


function sendReactMessage(action, data)
    SendNuiMessage(
        json.encode({
            action = action,
            data = data,
        })
    )
end