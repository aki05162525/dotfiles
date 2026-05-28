local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

local function local_workspace_path()
  local config_dir = WEZTERM_DOTFILES_CONFIG_DIR or wezterm.config_dir

  return config_dir .. "/workspace.local.lua"
end

local function load_local_workspaces()
  local ok, workspaces = pcall(dofile, local_workspace_path())

  if not ok then
    return {}
  end

  if type(workspaces) ~= "table" then
    wezterm.log_warn("workspace.local.lua must return a table")
    return {}
  end

  return workspaces
end

local function workspace_choices()
  local choices = {}

  for _, workspace in ipairs(load_local_workspaces()) do
    if type(workspace) == "table" and workspace.name and workspace.cwd then
      table.insert(choices, {
        id = workspace.cwd,
        label = workspace.name,
      })
    end
  end

  return choices
end

function M.apply(config)
  config.keys = config.keys or {}

  table.insert(config.keys, {
    key = "o",
    mods = "CTRL",
    action = wezterm.action_callback(function(window, pane)
      local choices = workspace_choices()

      if #choices == 0 then
        window:perform_action(act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }), pane)
        return
      end

      window:perform_action(
        act.InputSelector({
          title = "Choose Workspace",
          choices = choices,
          fuzzy = true,
          action = wezterm.action_callback(function(inner_window, inner_pane, cwd, name)
            if not cwd or not name then
              return
            end

            inner_window:perform_action(
              act.SwitchToWorkspace({
                name = name,
                spawn = {
                  cwd = cwd,
                },
              }),
              inner_pane
            )
          end),
        }),
        pane
      )
    end),
  })
end

return M
