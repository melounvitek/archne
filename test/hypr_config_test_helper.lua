local helper = {}

function helper.load_config(path)
  local state = {
    bindings = {},
    configs = {},
    starts = {},
    unbound = {},
  }

  hl = {
    config = function(config)
      table.insert(state.configs, config)
    end,
    unbind = function(keys)
      state.unbound[keys] = true
    end,
    dsp = {
      focus = function(options)
        return { action = "focus", options = options }
      end,
      window = {
        close = function()
          return { action = "close" }
        end,
        move = function(options)
          return { action = "move", options = options }
        end,
      },
    },
  }

  o = {
    bind = function(keys, description, dispatcher, options)
      state.bindings[keys] = {
        description = description,
        dispatcher = dispatcher,
        options = options,
      }
    end,
    launch_on_start = function(command)
      table.insert(state.starts, command)
    end,
  }

  local_override_loaded = false
  package.preload["hypr.local_overrides"] = function()
    local_override_loaded = true
  end
  package.loaded["hypr.local_overrides"] = nil

  dofile(path)

  state.local_override_loaded = local_override_loaded

  return state
end

function helper.assert_equal(actual, expected, message)
  if actual ~= expected then
    error(string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)))
  end
end

return helper
