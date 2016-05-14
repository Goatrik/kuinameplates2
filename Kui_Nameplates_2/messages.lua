--------------------------------------------------------------------------------
-- Kui Nameplates
-- By Kesava at curse.com
-- All rights reserved
--------------------------------------------------------------------------------
-- Handle frame event listeners, dispatch messages, init plugins/elements/layout
--------------------------------------------------------------------------------
local addon = KuiNameplates

local k,listener,plugin,_
local listeners = {}

function addon:DispatchMessage(message, ...)
    if listeners[message] then
        -- call plugin listeners...
        for k,listener in ipairs(listeners[message]) do
            listener[message](...)
        end
    end

    if addon.layout and addon.layout[message] then
        -- ... and the layout's listener
        addon.layout[message](...)
    end

    if addon.debug then
        addon:print('dispatched message: '..message)
    end
end
----------------------------------------------------------------- event frame --
local event_frame = CreateFrame('Frame')
local event_listeners = {}

local function event_frame_OnEvent(self,event,...)
    if not event_listeners[event] then
        self:UnregisterEvent(event)
        return
    end

    for _,t in ipairs(event_listeners[event]) do
        local f
        if t[2] and t[1][t[2]] then
            f = t[1][t[2]]
        else
            f = t[1][event]
        end

        if f then
            if event:sub(1,4) == 'UNIT' then
                local unit = ...
                if not addon:UnitHasNameplate(unit) then return end
                f(t[1], addon:GetNameplateByUnit(unit), unit, ...)
            else
                f(t[1], ...)
            end
        end
    end
end

event_frame:SetScript('OnEvent',event_frame_OnEvent)
----------------------------------------------------------- message registrar --
local message = {}
message.__index = message
function message.RegisterMessage(table, message)
    if not table or not message then return end
    if not table.plugin then return end
    if not listeners[message] then
        listeners[message] = {}
    end

    -- higher priority plugins are called later
    if #listeners[message] > 0 then
        local inserted
        for k,plugin in ipairs(listeners[message]) do
            if plugin.priority > table.priority then
                -- insert before a higher priority plugin
                tinsert(listeners[message], k, table)
                inserted = true
            end
        end

        if not inserted then
            -- no higher priority plugin was found; insert at the end
            tinsert(listeners[message], table)
        end
    else
        tinsert(listeners[message], table)
    end
end
function message.RegisterEvent(table,event,func)
    if not event_listeners[event] then
        event_listeners[event] = {}
    end

    tinsert(event_listeners[event], {table,func})

    event_frame:RegisterEvent(event)
end
------------------------------------------------------------ plugin registrar --
-- priority = any number. Defines the load order. Default of 5.
-- plugins with a higher priority are executed later (i.e. they override the
-- settings of any previous plugin)
function addon:NewPlugin(priority)
    local pluginTable = {
        plugin = true,
        priority = priority or 5
    }
    setmetatable(pluginTable, message)
    tinsert(addon.plugins, pluginTable)
    return pluginTable
end
-------------------------------------------------- external element registrar --
function addon:NewElement(name)
    local ele = {
        name = name,
        plugin = true,
        priority = 0
    }

    setmetatable(ele, message)
    addon.elements[name] = ele

    return ele
end
------------------------------------------------------------ layout registrar --
-- the layout is always executed last
function addon:Layout()
    if addon.layout then return end
    addon.layout = {}
    setmetatable(addon.layout, message)
    return addon.layout
end
