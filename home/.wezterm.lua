local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

------------------------------------------------------------
-- PLATFORM
------------------------------------------------------------
local triple = wezterm.target_triple
local platform = {
	is_windows = triple:find("windows") ~= nil,
	is_linux = triple:find("linux") ~= nil,
	is_mac = triple:find("darwin") ~= nil,
}
-- Distinguish Wayland from X11 on Linux
platform.is_wayland = platform.is_linux and os.getenv("WAYLAND_DISPLAY") ~= nil

------------------------------------------------------------
-- PERFORMANCE
------------------------------------------------------------
config.max_fps = 144
config.animation_fps = 144

-- WebGpu is the best renderer on Windows / macOS / Wayland.
-- Fall back to OpenGL on X11 where WebGpu support is uneven.
config.front_end = (platform.is_linux and not platform.is_wayland) and "OpenGL" or "WebGpu"

------------------------------------------------------------
-- FONT
------------------------------------------------------------
config.font = wezterm.font_with_fallback({
	"Maple Mono NF",
	"JetBrains Mono NL",
	"Symbols Nerd Font",
})
config.font_size = 12

------------------------------------------------------------
-- COLORS
------------------------------------------------------------
config.color_scheme = "Catppuccin Macchiato"

------------------------------------------------------------
-- WINDOW
------------------------------------------------------------
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_at_bottom = true
config.tab_and_split_indices_are_zero_based = true

-- Linux tiling WMs typically manage decorations themselves; drop the title bar.
-- Windows and macOS keep the native title bar for proper window management.
config.window_decorations = platform.is_linux and "RESIZE" or "TITLE | RESIZE"

-- Let WezTerm use the native Wayland compositor when available
if platform.is_wayland then
	config.enable_wayland = true
end

------------------------------------------------------------
-- SHELL DETECTION
------------------------------------------------------------
local UNIX_SHELLS = { "fish", "zsh", "bash", "sh" }
local WINDOWS_SHELLS = { "pwsh", "powershell", "cmd" } -- bare names, .exe appended below

-- `where.exe` matches bare names ("pwsh") and suffixed ones ("pwsh.exe") equally,
-- so always pass the bare name and only append .exe when building the actual args.
local function find_executable(name)
	return wezterm.run_child_process(platform.is_windows and { "where.exe", name } or { "which", name })
end

local function detect_shell()
	local shells = platform.is_windows and WINDOWS_SHELLS or UNIX_SHELLS
	local suffix = platform.is_windows and ".exe" or ""
	local default = platform.is_windows and "cmd.exe" or "sh"
	for _, sh in ipairs(shells) do
		if find_executable(sh) then
			return { sh .. suffix }
		end
	end
	return { default }
end

-- Run a single WSL process that walks the candidate list internally and
-- prints the first shell found — one spawn instead of N.
-- Returns (shell_name, prog_args), or (nil, nil) if nothing matched.
local function detect_wsl_shell(distro)
	-- Build: `for s in fish zsh bash sh; do command -v "$s" >/dev/null && printf '%s' "$s" && exit 0; done; exit 1`
	local script = string.format(
		'for s in %s; do command -v "$s" >/dev/null 2>&1 && printf \'%%s\' "$s" && exit 0; done; exit 1',
		table.concat(UNIX_SHELLS, " ")
	)

	local base = distro and { "wsl.exe", "-d", distro, "--exec" } or { "wsl.exe", "--exec" }
	local probe = { table.unpack(base) }
	table.insert(probe, "sh")
	table.insert(probe, "-c")
	table.insert(probe, script)

	local ok, stdout = wezterm.run_child_process(probe)
	if not ok then
		return nil, nil
	end

	-- stdout is the matched shell name, e.g. "fish"
	local sh = stdout:match("^(%S+)")
	if not sh or sh == "" then
		return nil, nil
	end

	-- Launch as a login shell so rc/profile files are sourced
	local prog = { table.unpack(base) }
	table.insert(prog, sh)
	table.insert(prog, "-l")
	return sh, prog
end

-- WSL is a Windows-only concept
config.wsl_domains = platform.is_windows and wezterm.default_wsl_domains() or {}

local default_prog = detect_shell()
config.default_prog = default_prog

-- Detect WSL shell once at startup; name is reused for the tab-title fallback.
local wsl_shell_name, wsl_prog = nil, nil
if platform.is_windows and #config.wsl_domains > 0 then
	wsl_shell_name, wsl_prog = detect_wsl_shell(config.wsl_domains[1].name)
end

------------------------------------------------------------
-- LEADER
------------------------------------------------------------
config.leader = { key = "q", mods = "ALT", timeout_milliseconds = 2000 }

------------------------------------------------------------
-- KEYBINDINGS
------------------------------------------------------------
local function ldr(key, action)
	return { key = key, mods = "LEADER", action = action }
end

config.keys = {
	-- Tabs
	ldr("c", act.SpawnTab("CurrentPaneDomain")),
	ldr("x", act.CloseCurrentPane({ confirm = true })),
	ldr("b", act.ActivateTabRelative(-1)),
	ldr("n", act.ActivateTabRelative(1)),

	-- Splits
	ldr("\\", act.SplitHorizontal({ domain = "CurrentPaneDomain" })),
	ldr("-", act.SplitVertical({ domain = "CurrentPaneDomain" })),

	-- Pane focus (vim-style)
	ldr("h", act.ActivatePaneDirection("Left")),
	ldr("j", act.ActivatePaneDirection("Down")),
	ldr("k", act.ActivatePaneDirection("Up")),
	ldr("l", act.ActivatePaneDirection("Right")),

	-- Pane resize
	ldr("LeftArrow", act.AdjustPaneSize({ "Left", 5 })),
	ldr("RightArrow", act.AdjustPaneSize({ "Right", 5 })),
	ldr("UpArrow", act.AdjustPaneSize({ "Up", 5 })),
	ldr("DownArrow", act.AdjustPaneSize({ "Down", 5 })),

	-- Explicit native-shell tab
	ldr("1", act.SpawnCommandInNewTab({ args = default_prog })),
}

-- WSL tab shortcut (Windows only, when at least one WSL distro exists).
-- Uses the detected shell inside WSL; falls back to plain SpawnTab if detection failed.
if platform.is_windows and #config.wsl_domains > 0 then
	local wsl_action = wsl_prog and act.SpawnCommandInNewTab({ args = wsl_prog })
		or act.SpawnTab({ DomainName = config.wsl_domains[1].name })
	table.insert(config.keys, ldr("2", wsl_action))
end

------------------------------------------------------------
-- TAB TITLE
------------------------------------------------------------
local PROCESS_LABELS = {
	pwsh = "PowerShell",
	powershell = "PowerShell",
	cmd = "CMD",
	fish = "fish",
	zsh = "zsh",
	bash = "bash",
	ssh = "SSH",
}

local WSL_LABELS = {
	fish = "WSL:fsh",
	zsh = "WSL:zsh",
	bash = "WSL:sh",
}

wezterm.on("format-tab-title", function(tab)
	local pane = tab.active_pane
	-- Strip .exe suffix so "pwsh.exe" → "pwsh" hits PROCESS_LABELS correctly
	local proc = (pane.foreground_process_name:match("([^/\\]+)$") or ""):lower():gsub("%.exe$", "")
	local is_wsl = pane.domain_name and pane.domain_name:find("WSL") ~= nil

	local label
	if is_wsl then
		-- foreground_process_name is often empty in WSL; fall back to the shell
		-- we detected at startup, then to a plain "WSL" label.
		local effective = (proc ~= "" and proc) or wsl_shell_name or ""
		label = WSL_LABELS[effective] or (wsl_shell_name and ("WSL:" .. wsl_shell_name) or "WSL")
	else
		label = PROCESS_LABELS[proc] or proc
	end

	return { { Text = " " .. label .. " " } }
end)

------------------------------------------------------------
-- LEADER INDICATOR
------------------------------------------------------------
wezterm.on("update-status", function(window)
	window:set_left_status(window:leader_is_active() and " 🌊 LEADER " or "")
end)

return config
