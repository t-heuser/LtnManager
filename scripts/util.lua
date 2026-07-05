local gui = require("lib.gui")
local format = require("__flib__.format")
local stdutil = require("__core__.lualib.util")

local util = {}

--- Create a flying text at the player's cursor with an error sound.
--- @param player LuaPlayer
--- @param message LocalisedString
function util.error_flying_text(player, message)
  player.create_local_flying_text({ create_at_cursor = true, text = message })
  player.play_sound({ path = "utility/cannot_build" })
end

function util.split_string(inputstr, sep)
  sep = sep or "%s" -- Defaults to whitespace if no separator is given
  local t = {}
  for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
    table.insert(t, str)
  end
  return t
end

function util.gui_list(parent, iterator, test, build, update, ...)
  local children = parent.children
  local i = 0

  for k, v in table.unpack(iterator) do
    local passed = test(v, k, i, ...)
    if passed then
      i = i + 1
      local child = children[i]
      if not child then
        gui.build(parent, { build(...) })
        child = parent.children[i]
      end
      gui.update(child, update(v, k, i, ...))
    end
  end

  for j = i + 1, #children do
    children[j].destroy()
  end
end

--- A dataset to put into a slot table.
---
--- If `type` is provided, it will be used for the sprite definition. If not provided, the type will be derived from the
--- name of each material.
--- @class SlotTableDef
--- @field color string
--- @field entries table<string, number>
--- @field translations table
--- @field type string|nil

--- Updates a slot table based on the passed criteria.
--- @param table LuaGuiElement
--- @param sources SlotTableDef[]
function util.slot_table_update(table, sources)
  local children = table.children

  local i = 0
  for _, source_data in pairs(sources) do
    if source_data.entries then
      for name, count in pairs(source_data.entries) do
        local sprite, quality
        if source_data.type then
          sprite = source_data.type .. "/" .. name
        else
          local item_data = stdutil.split(name, ",")
          name = item_data[1] .. "," .. item_data[2]
          sprite = string.gsub(name, ",", "/") -- remove quality info
          quality = item_data[3]
        end
        if helpers.is_valid_sprite_path(sprite) then
          i = i + 1
          local button = children[i]
          if not button then
            button = gui.add(table, { type = "sprite-button", enabled = true })
          end
          button.style = "ltnm_small_slot_button_" .. source_data.color
          button.sprite = sprite
          button.quality = quality
          local translations = source_data.translations or {}
          button.tooltip = "[img="
            .. sprite
            .. "]  [font=default-semibold]"
            .. (translations[name] or name)
            .. "[/font]\n"
            .. format.number(count)
          button.number = count
        end
      end
    end
  end

  for i = i + 1, #children do
    children[i].destroy()
  end
end

function util.sorted_iterator(arr, src_tbl, sort_state)
  local step = sort_state and 1 or -1
  local i = sort_state and 1 or #arr

  return function()
    local j = i + step
    if arr[j] then
      i = j
      local arr_value = arr[j]
      return arr_value, src_tbl[arr_value]
    end
  end,
    arr
end

local MAX_INT = 2147483648 -- math.pow(2, 31)
function util.signed_int32(val)
  return (val >= MAX_INT and val - (2 * MAX_INT)) or val
end

return util
