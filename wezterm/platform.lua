local wezterm = require("wezterm")

local M = {}

local function choose_wsl_domain()
  local preferred = "WSL:Ubuntu"
  local domains = wezterm.default_wsl_domains()

  for _, domain in ipairs(domains) do
    if domain.name == preferred then
      return domains, domain.name
    end
  end

  if domains[1] then
    return domains, domains[1].name
  end

  return domains, nil
end

function M.apply(config)
  if wezterm.target_triple:find("windows") then
    local wsl_domains, default_domain = choose_wsl_domain()
    config.wsl_domains = wsl_domains

    if default_domain then
      config.default_domain = default_domain
    end
  end
end

return M
