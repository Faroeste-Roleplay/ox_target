state = {}

local itemsVisible = false

local isActive = false
local selectedIndex = 1
---@return boolean
function state.isActive()
    return isActive
end

---@param value boolean
function state.setActive(value)
    isActive = value

    sendReactMessage( 'visible', value)
end

local nuiFocus = false

---@return boolean
function state.isNuiFocused()
    return nuiFocus
end

---@param value boolean
function state.setNuiFocus(value, cursor)
    if value then SetCursorLocation(0.5, 0.5) end

    nuiFocus = value
    -- SetNuiFocus(value, cursor or false)
    -- SetNuiFocusKeepInput(value)
end

local isDisabled = false

local itemHovered = {}

---@return boolean
function state.isDisabled()
    return isDisabled
end

---@param value boolean
function state.setDisabled(value)
    isDisabled = value
end

function state.setItemsActive( state )
    itemsVisible = state
end

function state.itemStatus( state )
    return itemsVisible
end

function state.selectedIndex()
    return selectedIndex
end

function state.setSelectedIndex( value )
    selectedIndex = value

    sendReactMessage( 'setCurrentSelected', selectedIndex - 1)
end

function state.setCurrentItemHover( item )
    itemHovered = item
end

function state.currentItemHover( )
    return itemHovered
end