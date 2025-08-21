-- if not lib.checkDependency('qbx_core', '1.18.0', true) then return end



API = Tunnel.getInterface("API")

Business = Proxy.getInterface("business")
Inventory = Tunnel.getInterface("inventory")

---@diagnostic disable-next-line: duplicate-set-field
function utils.hasPlayerGotGroup(filter)
    local playerId = GetPlayerServerId(PlayerId())
    return API.IsPlayerAceAllowedGroup( playerId, filter ) or Business.hasClassePermission(filter)
end

---@diagnostic disable-next-line: duplicate-set-field
function utils.hasItem( playerId, item )
    return Inventory.GetItem(playerId, item, nil, true)
end