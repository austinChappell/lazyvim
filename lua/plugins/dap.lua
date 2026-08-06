-- Node/TypeScript debugging via vscode-js-debug (the same adapter VS Code uses).
-- The dap.core extra in config/lazy.lua brings nvim-dap, dap-ui and virtual text;
-- everything here is the JS/TS-specific wiring.

local js_filetypes = { "typescript", "javascript", "typescriptreact", "javascriptreact" }

-- Node can't execute .ts directly (no --experimental-strip-types before 22.6),
-- so launching a TS file needs tsx/ts-node. Prefer the project's local copy over
-- anything global so the debugger uses the same version the project runs with.
local function ts_runner()
  local cwd = vim.fn.getcwd()
  for _, bin in ipairs({ "tsx", "ts-node" }) do
    local local_bin = cwd .. "/node_modules/.bin/" .. bin
    if vim.fn.executable(local_bin) == 1 then
      return local_bin
    end
  end
  for _, bin in ipairs({ "tsx", "ts-node" }) do
    if vim.fn.executable(bin) == 1 then
      return bin
    end
  end
  vim.notify("No tsx/ts-node found - install one to launch TypeScript files directly", vim.log.levels.WARN)
  return nil
end

-- Match the package manager to the lockfile so "Launch npm script" runs the
-- script the way the project expects (pnpm workspaces, yarn PnP, etc).
local function package_manager()
  local cwd = vim.fn.getcwd()
  local lockfiles = {
    ["pnpm-lock.yaml"] = "pnpm",
    ["yarn.lock"] = "yarn",
    ["bun.lockb"] = "bun",
  }
  for lockfile, pm in pairs(lockfiles) do
    if vim.fn.filereadable(cwd .. "/" .. lockfile) == 1 and vim.fn.executable(pm) == 1 then
      return pm
    end
  end
  return "npm"
end

-- Shared bits: don't step into node internals or dependencies, and map compiled
-- JS in dist/ back to the original TS without wandering into node_modules.
local common = {
  cwd = "${workspaceFolder}",
  sourceMaps = true,
  skipFiles = { "<node_internals>/**", "${workspaceFolder}/node_modules/**" },
  outFiles = { "${workspaceFolder}/**/*.js", "!**/node_modules/**" },
  resolveSourceMapLocations = { "${workspaceFolder}/**", "!**/node_modules/**" },
}

local function config(name, overrides)
  return vim.tbl_extend("error", { name = name, type = "pwa-node" }, common, overrides)
end

return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      {
        "mason-org/mason.nvim",
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          table.insert(opts.ensure_installed, "js-debug-adapter")
        end,
      },
    },
    opts = function()
      local dap = require("dap")

      -- js-debug runs as a DAP server; ${port} is filled in by nvim-dap.
      dap.adapters["pwa-node"] = {
        type = "server",
        host = "localhost",
        port = "${port}",
        executable = { command = "js-debug-adapter", args = { "${port}" } },
      }

      -- launch.json files written for VS Code use type "node"; alias it.
      dap.adapters["node"] = function(cb, cfg)
        cfg.type = "pwa-node"
        cb(dap.adapters["pwa-node"])
      end

      local function configurations_for(ft)
        return {
          config("Launch current file", {
            request = "launch",
            program = "${file}",
            -- Plain .js runs on node as-is; only TS needs a loader in front.
            runtimeExecutable = ft:find("typescript") and ts_runner or nil,
            console = "integratedTerminal",
          }),
          config("Launch npm script", {
            request = "launch",
            runtimeExecutable = package_manager,
            runtimeArgs = function()
              return { "run", vim.fn.input("Script: ", "dev") }
            end,
            -- The package manager spawns node as a child; follow it or the
            -- breakpoints never bind.
            autoAttachChildProcesses = true,
            console = "integratedTerminal",
          }),
          -- For a process already started with `node --inspect` / `--inspect-brk`.
          config("Attach to process", {
            request = "attach",
            processId = function()
              return require("dap.utils").pick_process({ filter = "node" })
            end,
          }),
          config("Attach to port 9229", {
            request = "attach",
            address = "localhost",
            port = 9229,
            -- Reconnect on its own when nodemon/tsx watch restarts the process.
            restart = true,
          }),
        }
      end

      -- Anything in the project's .vscode/launch.json is picked up on top of
      -- these automatically - nvim-dap reads it on demand when you hit <leader>dc.
      for _, ft in ipairs(js_filetypes) do
        dap.configurations[ft] = configurations_for(ft)
      end
    end,
  },
}
