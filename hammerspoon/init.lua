local jeo = { }


-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

-- The first value returned from jeo.handleKeyEvent determines whether the key
-- event should be propagated or deleted.
local PROPAGATE = false
local DELETE = true

-- Keys used to address event properties.
local AUTOREPEAT = hs.eventtap.event.properties.keyboardEventAutorepeat
local USER_DATA = hs.eventtap.event.properties.eventSourceUserData

-- The value of USER_DATA that represents a synthetic event. This is used to
-- prevent generated events from undergoing further remapping.
local SYNTHETIC = 5462350

-- Human-friendly labels for the pass-through and non pass-through layouts.
local JEO_DESC = 'Jeo'
local QWERTY_DESC = 'QWERTY'

-- The event handler should be triggered for only these event types.
jeo.KEY_EVENTS = {
  hs.eventtap.event.types.keyDown,
  hs.eventtap.event.types.keyUp
}

-- Locations of the right-hand backspace and delete keys.
local DEL_ESC_MAP = { ['['] = 'delete', [']'] = 'escape' }

-- Miscellaneous hotkeys.
local HOTKEYS = {
  spotlight = 'delete',
  save = '\\',
  eject = 'f13',
  lock = 'f16',
  sleep = 'f17'
}

-- Keys used for application launchers.
local LAUNCH_KEYS = {
  activityMonitor = '`',
  calendar = 'f6',
  editor = '=',
  mail = 'f5',
  systemPreferences = 'help',
  terminal = '-'
}

-------------------------------------------------------------------------------
-- Alphanumeric layers (in order of decreasing precedence)
--
-- Each layer is a table of tables. The index into the first table is the lower
-- QWERTY key that triggered the event. The nested table has three keys: 'key',
-- 'alt', and 'shift'. The former refers to the lower QWERTY key that should be
-- sent in the resulting synthetic event, and the latter two reference Boolean
-- values for whether the corresponding modifiers should be applied.
--
-- When the 'key' of a nested table indexes 'none', no synthetic event should
-- be generated.
-------------------------------------------------------------------------------

local SYMBOL_LAYER = require 'jeospoon.symbol'
local NUMPAD_LAYER = require 'jeospoon.numpad'
local SHIFT_LAYER = require 'jeospoon.shift'
local DEFAULT_LAYER = require 'jeospoon.default'


-------------------------------------------------------------------------------
-- Configuration / state
-------------------------------------------------------------------------------

-- Disable pass-through mode by default.
local passThrough = false

-- Disable symbol layer by default.
local symbol = false

function jeo.enablePassThrough()
  passThrough = true
  hs.alert.closeAll()
  hs.alert.show(' ' .. QWERTY_DESC)
end

function jeo.disablePassThrough()
  passThrough = false
  hs.alert.closeAll()
  hs.alert.show(' ' .. JEO_DESC)
end

-- Focusing launcher app names. By default, these are only apps that come pre-
-- installed with macOS.
local focusingLauncherApps = {
  [LAUNCH_KEYS.calendar] = 'Calendar',
  [LAUNCH_KEYS.editor] = 'TextEdit',
  [LAUNCH_KEYS.mail] = 'Mail',
  [LAUNCH_KEYS.terminal] = 'Terminal'
}

-- Toggling launcher app names. Also only pre-installed apps by default.
local togglingLauncherApps = {
  [LAUNCH_KEYS.activityMonitor] = 'Activity Monitor',
  [LAUNCH_KEYS.systemPreferences] = 'System Preferences'
}

function jeo.setEditor(appName)
  focusingLauncherApps[LAUNCH_KEYS.editor] = appName
end

function jeo.setTerminal(appName)
  focusingLauncherApps[LAUNCH_KEYS.terminal] = appName
end


-------------------------------------------------------------------------------
-- Utilities
-------------------------------------------------------------------------------

-- Extract a list of keys from a table (order not guaranteed).
local function getKeys(tbl)
  local keys = { }

  for key, _ in pairs(tbl) do
    table.insert(keys, key)
  end

  return keys
end


-------------------------------------------------------------------------------
-- Main event handler
-------------------------------------------------------------------------------

function jeo.handleKeyEvent(event)
  -- Disregard events generated by us.
  if event:getProperty(USER_DATA) == SYNTHETIC then
    return PROPAGATE
  end

  -- Extract information about the event.
  local isRepeat = event:getProperty(AUTOREPEAT) ~= 0
  local keyDown = event:getType() == hs.eventtap.event.types.keyDown
  local srcKey = hs.keycodes.map[event:getKeyCode()]
  local srcMods = event:getFlags()

  -- Local variables for generating synthetic events.
  local dstKey, dstMap, launchApp
  local dstModList = { }
  local layer = DEFAULT_LAYER

  -- If event is pass-through toggle, handle it appropriately.
  if keyDown and srcKey == 'escape' and srcMods.cmd and not srcMods.alt then
    -- Discard repeats.
    if isRepeat then
      return DELETE
    end

    -- Toggle pass-through mode.
    passThrough = not passThrough
    hs.alert.closeAll()
    hs.alert.show(' ' .. (passThrough and QWERTY_DESC or JEO_DESC))

    -- Prevent propagation.
    return DELETE
  elseif passThrough then
    -- Otherwise, if we're in pass-through mode, disregard all events.
    return PROPAGATE
  end

  -- Consume quote key as symbol modifier.
  if srcKey == '\'' then
    symbol = keyDown
    return DELETE
  end

  -- Determine the alphanumeric layer. By default the state of the alt and
  -- shift keys are discarded once the layer has been chosen, because each
  -- layer sets is own alt/shift combination on a per-key basis.
  --
  --   * If symbol is down, use the symbol layer.
  --
  --   * Otherwise, if alt is down but cmd is not, use the numpad layer.
  --
  --   * Otherwise, use the default or the shift layer according to whether
  --     shift is down, but don't allow the layer to release alt or shift when
  --     cmd is down. (This makes cmd-shift-1, cmd-alt-a etc shortcuts function
  --     as expected.)
  if symbol then
    layer = SYMBOL_LAYER
  elseif srcMods.alt and not srcMods.cmd then
    layer = NUMPAD_LAYER
  else
    if srcMods.shift then
      layer = SHIFT_LAYER
    end
    if srcMods.cmd then
      if srcMods.shift then table.insert(dstModList, 'shift') end
      if srcMods.alt then table.insert(dstModList, 'alt') end
    end
  end

  -- Try to remap the key as an alphanumeric.
  dstMap = layer[srcKey]
  if dstMap then
    dstKey = dstMap.key

    -- Delete the event if the map specifies no action.
    if dstKey == 'none' then
      return DELETE
    end

    -- Set alt/shift, if not already specified.
    if #dstModList == 0 then
      if dstMap.alt then table.insert(dstModList, 'alt') end
      if dstMap.shift then table.insert(dstModList, 'shift') end
    end

    -- Copy over the remaining modifiers.
    if srcMods.cmd then table.insert(dstModList, 'cmd') end
    if srcMods.ctrl then table.insert(dstModList, 'ctrl') end
    if srcMods.fn then table.insert(dstModList, 'fn') end

    -- Create a new event for the remapped key.
    local newEvent = hs.eventtap.event.newKeyEvent(dstModList, dstKey, keyDown)
    newEvent:setProperty(USER_DATA, SYNTHETIC)

    -- Post the new event and consume the old one.
    return DELETE, { newEvent }
  end

  -- Check for right-hand delete and escape.
  dstKey = DEL_ESC_MAP[srcKey]
  if dstKey then
    local srcModList = getKeys(srcMods)
    local newEvent = hs.eventtap.event.newKeyEvent(srcModList, dstKey, keyDown)
    newEvent:setProperty(USER_DATA, SYNTHETIC)
    return DELETE, { newEvent }
  end

  -- Handle the miscellaneous hotkeys.
  if srcKey == HOTKEYS.spotlight then
    if isRepeat then return DELETE end

    -- Spotlight
    local spotMods = { 'cmd' }
    if srcMods.alt then table.insert(spotMods, 'alt') end
    local newEvent = hs.eventtap.event.newKeyEvent(spotMods, 'space', keyDown)
    newEvent:setProperty(USER_DATA, SYNTHETIC)

    return DELETE, { newEvent }
  elseif srcKey == HOTKEYS.save then
    if isRepeat then return DELETE end

    -- Save
    local saveMods = { 'cmd' }
    if srcMods.alt then table.insert(saveMods, 'alt') end
    if srcMods.ctrl then table.insert(saveMods, 'ctrl') end
    if srcMods.shift then table.insert(saveMods, 'shift') end
    local newEvent = hs.eventtap.event.newKeyEvent(saveMods, 's', keyDown)
    newEvent:setProperty(USER_DATA, SYNTHETIC)

    return DELETE, { newEvent }
  elseif srcKey == HOTKEYS.eject then
    if isRepeat then return DELETE end

    -- Media eject
    local newEvent = hs.eventtap.event.newSystemKeyEvent('EJECT', keyDown)
    newEvent:setProperty(USER_DATA, SYNTHETIC)

    return DELETE, { newEvent }
  elseif srcKey == HOTKEYS.lock then
    if keyDown and not isRepeat then
      -- Lock
      hs.caffeinate.lockScreen()
    end
    return DELETE
  elseif srcKey == HOTKEYS.sleep then
    if keyDown and not isRepeat then
      -- Sleep
      hs.caffeinate.systemSleep()
    end
    return DELETE
  end

  -- Interpret Cmd-<Activity Monitor> as 'take a screenshot'.
  if srcMods.cmd and srcKey == LAUNCH_KEYS.activityMonitor then
    local newMods = { 'cmd', 'shift' }
    local newEvent = hs.eventtap.event.newKeyEvent(newMods, '4', keyDown)
    newEvent:setProperty(USER_DATA, SYNTHETIC)
    return DELETE, { newEvent }
  end

  -- Handle the focusing launchers. These bring an app into focus, launching it
  -- if necessary. If the app is already in focus, no action is taken.
  launchApp = focusingLauncherApps[srcKey]
  if launchApp then
    if keyDown and not isRepeat then
      hs.application.launchOrFocus(launchApp)
    end
    return DELETE
  end

  -- Handle the toggling launchers. These bring an app into focus, launching it
  -- if necessary. If the app is already in focus, the app is closed.
  launchApp = togglingLauncherApps[srcKey]
  if launchApp then
    if keyDown and not isRepeat then
      local app = hs.application.find(launchApp)
      if app and app:isFrontmost() then
        app:kill()
      else
        hs.application.launchOrFocus(launchApp)
      end
    end
    return DELETE
  end

  -- Default to doing nothing.
  return PROPAGATE
end


-------------------------------------------------------------------------------

return jeo
