-- Swayimg config (API of swayimg 5.7), Gruvbox Dark theme.
-- Reference: share/swayimg/example.lua and share/swayimg/swayimg.lua in the
-- swayimg package (the latter has LuaLS annotations for every field).
--
-- Key names are xkb keysym names, modifiers are joined with "+":
-- "Shift+w", "Ctrl+Alt+p". Swayimg matches the keysym of the *active*
-- layout, so in the RU layout the "q" key arrives as "Cyrillic_shorti".
--
-- All key bindings go through bind(), which
--   * also binds the same physical key in the RU layout,
--   * lists the binding in the "/" help overlay when given a description,
--   * closes the help overlay instead of running the action while it is open.
-- Swayimg's built-in bindings are reset per mode and re-declared here, so
-- this file is the complete list of keys.

local viewer    = swayimg.viewer
local slideshow = swayimg.slideshow
local gallery   = swayimg.gallery

local modes      = { viewer = viewer, slideshow = slideshow, gallery = gallery }
local mode_names = { [viewer] = "viewer", [slideshow] = "slideshow", [gallery] = "gallery" }

--------------------------------------------------------------------------------
-- Theme: Gruvbox Dark (same palette as foot/ghostty/btop)
-- Colors are 0xAARRGGBB (AA = alpha, ff = fully opaque)
--------------------------------------------------------------------------------
local gruvbox = {
  bg0_h  = 0xff1d2021, -- hard background
  bg0    = 0xff282828, -- background
  bg1    = 0xff3c3836,
  bg2    = 0xff504945,
  fg     = 0xffebdbb2, -- foreground
  yellow = 0xfffabd2f, -- accent: selection
  aqua   = 0xff8ec07c, -- marks
}

-- Overlay text sits on opaque bg0 panels (no shadow needed then). Even at
-- ~90 % opacity, gallery thumbnail edges show through as distracting lines.
local TEXT_TIMEOUT = 5          -- seconds until text hides
local TEXT_SIZE = 18            -- font size in pixels
local HELP_SIZE = 16            -- smaller while the help is open, to fit 1080p at 2x
local PANEL_BG = gruvbox.bg0    -- panel background

-- Text block helpers. A "\t" splits key and value, swayimg aligns values.
-- Blank " " lines and the spaces around each line pad the panel background.
local function kv(key, value)
  return "  " .. key .. "   \t" .. value .. "  "
end

local function line(text)
  return "  " .. text .. "  "
end

local function panel(lines)
  local out = { " " }
  for _, l in ipairs(lines) do out[#out + 1] = l end
  out[#out + 1] = " "
  return out
end

local function status(msg)
  swayimg.text.status = " \n" .. line(msg) .. "\n "
end

--------------------------------------------------------------------------------
-- Keyboard layouts
--------------------------------------------------------------------------------

-- Latin keysym -> keysym produced by the same physical key in the RU layout.
local ru = {
  q = "Cyrillic_shorti", w = "Cyrillic_tse",   e = "Cyrillic_u",
  r = "Cyrillic_ka",     t = "Cyrillic_ie",    y = "Cyrillic_en",
  u = "Cyrillic_ghe",    i = "Cyrillic_sha",   o = "Cyrillic_shcha",
  p = "Cyrillic_ze",     a = "Cyrillic_ef",    s = "Cyrillic_yeru",
  d = "Cyrillic_ve",     f = "Cyrillic_a",     g = "Cyrillic_pe",
  h = "Cyrillic_er",     j = "Cyrillic_o",     k = "Cyrillic_el",
  l = "Cyrillic_de",     z = "Cyrillic_ya",    x = "Cyrillic_che",
  c = "Cyrillic_es",     v = "Cyrillic_em",    b = "Cyrillic_i",
  n = "Cyrillic_te",     m = "Cyrillic_softsign",
  bracketleft = "Cyrillic_ha", bracketright = "Cyrillic_hardsign",
  semicolon   = "Cyrillic_zhe", apostrophe  = "Cyrillic_e",
  comma       = "Cyrillic_be",  period      = "Cyrillic_yu",
  grave       = "Cyrillic_io",
  -- The US "/" key types "." in RU. Side effect: US "." also triggers
  -- whatever is bound to "/".
  slash       = "period",
}

local function split_key(key)
  return key:match("^(.-)([^+-]+)$") -- "Shift+w" -> "Shift+", "w"
end

--------------------------------------------------------------------------------
-- Help overlay
--------------------------------------------------------------------------------

local help_lines = { viewer = {}, slideshow = {}, gallery = {} }
local text_schemes = {}       -- mode name -> normal text scheme
local help_open = nil         -- name of the mode showing help, nil if closed
local text_was_visible = false

local BLOCKS = { "topleft", "topright", "bottomleft", "bottomright" }

-- Fill in all four blocks so that setting a scheme also clears the others.
local function full_scheme(scheme)
  local out = {}
  for _, pos in ipairs(BLOCKS) do out[pos] = scheme[pos] or {} end
  return out
end

-- Set a mode's normal text scheme (remembered for restoring after help).
local function set_text(mode, scheme)
  local name = mode_names[mode]
  text_schemes[name] = scheme
  if help_open ~= name then mode.text = full_scheme(scheme) end
end

local KEY_LABELS = {
  space = "Space", Prior = "PgUp", Next = "PgDn", Escape = "Esc",
  Return = "Enter", BackSpace = "BkSp", Delete = "Del", Insert = "Ins",
  bracketleft = "[", bracketright = "]", equal = "=", minus = "-",
  slash = "/",
}

local function key_label(key)
  local mods, base = split_key(key)
  if base:match("^KP_") then return nil end  -- keypad duplicates: not listed
  if base == "plus" then return "+" end       -- Shift is implied
  if mods == "Shift+" and base:match("^%l$") then return base:upper() end
  return mods .. (KEY_LABELS[base] or base)
end

local function add_help(mode, keys, desc)
  local labels = {}
  for _, key in ipairs(keys) do
    labels[#labels + 1] = key_label(key)
  end
  local list = help_lines[mode_names[mode]]
  list[#list + 1] = kv(table.concat(labels, " "), desc)
end

local function show_help()
  local name = swayimg.mode
  local lines = help_lines[name]
  local half = math.ceil(#lines / 2)
  local left = { line(name:sub(1, 1):upper() .. name:sub(2) .. " keys"), " " }
  local right = { line("Any key closes"), " " }
  for i, l in ipairs(lines) do
    local col = i <= half and left or right
    col[#col + 1] = l
  end

  help_open = name
  text_was_visible = swayimg.text.visible
  swayimg.text.timeout = 0  -- 0 = never auto-hide
  swayimg.text.size = HELP_SIZE
  modes[name].text = full_scheme({ topleft = panel(left), topright = panel(right) })
  swayimg.text.visible = true
end

local function hide_help()
  local name = help_open
  help_open = nil
  modes[name].text = full_scheme(text_schemes[name] or {})
  swayimg.text.size = TEXT_SIZE
  swayimg.text.timeout = TEXT_TIMEOUT
  swayimg.text.visible = text_was_visible
end

--------------------------------------------------------------------------------
-- bind()
--------------------------------------------------------------------------------

-- Bind keys in a mode. `desc` (optional) lists the binding in the help.
local function bind(mode, keys, fn, desc)
  if type(keys) == "string" then keys = { keys } end
  local all = {}
  for _, key in ipairs(keys) do
    all[#all + 1] = key
    local mods, base = split_key(key)
    local twin = ru[base:lower()]
    if twin then all[#all + 1] = mods .. twin end
  end
  mode.on_key(all, function()
    if help_open then hide_help() else fn() end
  end)
  if desc then add_help(mode, keys, desc) end
end

-- Swayimg's built-in handler shows "Unhandled key: ..." for every unbound key
-- except Shift/Ctrl/Alt/Super. Also stay quiet for AltGr (ISO_Level3_Shift)
-- and layout switching keys (ISO_Next_Group etc.), so switching the layout
-- doesn't close the help either.
local function is_silent_key(name)
  local _, base = split_key(name)
  return base:match("^ISO_Level%d_") or base:match("^ISO_.*Group")
      or base == "Mode_switch"
end

for _, mode in pairs(modes) do
  mode.bind_reset() -- drop built-in key/mouse bindings, all declared below
  mode.on_unassigned_key(function(key)
    if is_silent_key(key) then return end
    if help_open then
      hide_help()
    else
      status("Unhandled key: " .. key)
    end
  end)
end

--------------------------------------------------------------------------------
-- Action helpers
--------------------------------------------------------------------------------

-- Quote a string for /bin/sh. Lua's %q uses double quotes, inside which the
-- shell still expands $(...) and backticks, so a crafted file name would run
-- commands when passed to os.execute.
local function shell_quote(s)
  return "'" .. (s:gsub("'", [['\'']])) .. "'"
end

-- LuaJIT's os.execute returns the exit status, Lua 5.2+ returns true/nil.
local function run(cmd)
  local res = os.execute(cmd)
  return res == true or res == 0
end

local function quit() swayimg.exit() end

local function set_mode(name)
  return function() swayimg.mode = name end
end

local function toggle_text()
  swayimg.text.visible = not swayimg.text.visible
end

local function toggle_fullscreen()
  swayimg.fullscreen = not swayimg.fullscreen
end

local function toggle_antialiasing()
  swayimg.antialiasing = not swayimg.antialiasing
end

local function print_marked()
  local count = 0
  for _, entry in ipairs(swayimg.imagelist.get()) do
    if entry.mark then
      print(entry.path)
      count = count + 1
    end
  end
  if count > 0 then
    status("Print paths of selected images: " .. count)
  else
    status("Print paths failed: no images selected")
  end
end

local function print_current(mode)
  return function()
    local image = mode.get_image()
    if image then
      print(image.path)
      status("Print path: " .. image.path)
    end
  end
end

--------------------------------------------------------------------------------
-- File actions (viewer and gallery). Each takes the mode and returns the
-- key handler, so the same code works with viewer.get_image() and
-- gallery.get_image().
--------------------------------------------------------------------------------

local function current_path(mode)
  local img = mode.get_image()
  return img and img.path
end

-- Marked images, or the current one if nothing is marked.
local function marked_or_current(mode)
  local paths = {}
  for _, entry in ipairs(swayimg.imagelist.get()) do
    if entry.mark then paths[#paths + 1] = entry.path end
  end
  if #paths == 0 then paths[1] = current_path(mode) end
  return paths
end

local function copy_path(mode)
  return function()
    local path = current_path(mode)
    if not path then return end
    if run("wl-copy " .. shell_quote(path)) then
      status("Copied path: " .. path)
    else
      status("wl-copy failed")
    end
  end
end

-- PNG is the format every app accepts when pasting, so convert (first
-- frame, EXIF-rotated) in the background: big photos would otherwise freeze
-- the window while encoding.
local function copy_image(mode)
  return function()
    local path = current_path(mode)
    if not path then return end
    if not run("command -v magick >/dev/null && command -v wl-copy >/dev/null") then
      status("Copy image needs magick and wl-copy")
      return
    end
    run("(magick " .. shell_quote(path .. "[0]") .. " -auto-orient png:- | " ..
        "wl-copy --type image/png) >/dev/null 2>&1 &")
    status("Copying image to clipboard")
  end
end

local function show_in_files(mode)
  return function()
    local path = current_path(mode)
    if not path then return end
    run("nautilus --select " .. shell_quote(path) .. " >/dev/null 2>&1 &")
  end
end

-- Removing the current entry from the list makes swayimg show the next one.
local function trash_image(mode)
  return function()
    local path = current_path(mode)
    if not path then return end
    if run("trash-put " .. shell_quote(path)) then
      swayimg.imagelist.remove(path)
      status("Trashed: " .. path)
    else
      status("trash-put failed: " .. path)
    end
  end
end

local function delete_image(mode)
  return function()
    local path = current_path(mode)
    if not path then return end
    local ok, err = os.remove(path)
    if ok then
      swayimg.imagelist.remove(path)
      status("Deleted: " .. path)
    else
      status("Delete failed: " .. tostring(err))
    end
  end
end

-- Send to phone via GSConnect (KDE Connect for GNOME) over D-Bus.
local GSCONNECT = "org.gnome.Shell.Extensions.GSConnect"

-- First paired and connected device: D-Bus object path and name.
local function connected_phone()
  local pipe = io.popen("gdbus call --session --dest " .. GSCONNECT ..
    " --object-path /org/gnome/Shell/Extensions/GSConnect" ..
    " --method org.freedesktop.DBus.ObjectManager.GetManagedObjects 2>/dev/null")
  if not pipe then return nil end
  local out = pipe:read("*a")
  pipe:close()
  for dev, props in out:gmatch("'(/org/gnome/Shell/Extensions/GSConnect/Device/[^'/]+)': (%b{})") do
    if props:find("'Connected': <true>", 1, true) and props:find("'Paired': <true>", 1, true) then
      return dev, props:match("'Name': <'([^']*)'>") or "phone"
    end
  end
end

-- GVariant text-format string literal.
local function gvariant_string(s)
  return "'" .. s:gsub("\\", "\\\\"):gsub("'", "\\'") .. "'"
end

local function send_to_phone(mode)
  return function()
    local paths = marked_or_current(mode)
    if #paths == 0 then return end
    local dev, name = connected_phone()
    if not dev then
      status("No phone connected (GSConnect)")
      return
    end
    local sent = 0
    for _, path in ipairs(paths) do
      -- shareFile(path, open_on_phone)
      local arg = "[<(" .. gvariant_string(path) .. ", false)>]"
      if run("gdbus call --session --dest " .. GSCONNECT ..
             " --object-path " .. shell_quote(dev) ..
             " --method org.gtk.Actions.Activate shareFile " ..
             shell_quote(arg) .. " '{}' >/dev/null 2>&1") then
        sent = sent + 1
      end
    end
    status(("Sent %d of %d to %s"):format(sent, #paths, name))
  end
end

-- Toggle list order: by name <-> newest first. Swayimg re-sorts but doesn't
-- redraw, so re-select the current image to refresh the view and counters.
local function toggle_order(mode)
  return function()
    local newest = swayimg.imagelist.order ~= "mtime"
    swayimg.imagelist.order = newest and "mtime" or "numeric"
    swayimg.imagelist.reverse = newest
    local path = current_path(mode)
    if path then
      if mode == gallery then gallery.select_path(path) else mode.reload() end
    end
    status(newest and "Order: newest first" or "Order: by name")
  end
end

--------------------------------------------------------------------------------
-- General
--------------------------------------------------------------------------------
swayimg.mode = "viewer"            -- mode at startup
swayimg.antialiasing = true        -- anti-aliasing
swayimg.decoration = false         -- window title/buttons/borders
swayimg.overlay = false            -- window overlay mode
swayimg.exif_orientation = true    -- image orientation by EXIF
swayimg.dnd_button = "MouseRight"  -- drag-and-drop mouse button

--------------------------------------------------------------------------------
-- Image list
--------------------------------------------------------------------------------
swayimg.imagelist.order = "numeric"  -- list order
swayimg.imagelist.reverse = false    -- reverse order
swayimg.imagelist.recursive = false  -- recursive directory reading
swayimg.imagelist.adjacent = true    -- add adjacent files from same dir
swayimg.imagelist.fsmon = true       -- file system monitoring

--------------------------------------------------------------------------------
-- Text overlay
--------------------------------------------------------------------------------
swayimg.text.visible = false                -- hidden at startup, toggle with "i"
swayimg.text.font = "monospace:style=Medium" -- Iosevka Curly here; Medium reads better on images
swayimg.text.size = TEXT_SIZE               -- font size in pixels
swayimg.text.spacing = 2                    -- line spacing
swayimg.text.padding = 16                   -- gap between panels and window edge
swayimg.text.color = gruvbox.fg             -- text color
swayimg.text.background = PANEL_BG          -- panel background
swayimg.text.shadow = 0x00000000            -- alpha 0 = no shadow
swayimg.text.timeout = TEXT_TIMEOUT         -- layer hide timeout
swayimg.text.status_timeout = 3             -- status message hide timeout

--------------------------------------------------------------------------------
-- Viewer mode
--------------------------------------------------------------------------------
viewer.default_scale = "optimal"   -- default image scale
viewer.default_position = "center" -- default image position
viewer.drag_button = "MouseLeft"   -- mouse button to drag image
viewer.autopos = "center"          -- center images smaller than the window
viewer.loop = true                 -- image list loop mode
viewer.preload = 1                 -- number of images to preload
viewer.history = 1                 -- number of images in history cache
viewer.mark_color = gruvbox.aqua   -- mark icon color
viewer.pinch_factor = 1.0          -- pinch gesture factor
-- Info panels, rebuilt per image. Swayimg drops a line whose field is
-- missing only if nothing else is left on it, and the panel padding would
-- keep it, so optional lines are added only when the image has the data.
local EXIF_LINES = {
  { "EXIF date", "Exif.Photo.DateTimeOriginal" },
  { "EXIF camera", "Exif.Image.Model" },
}

local function viewer_text(img)
  local file = {
    kv("File", "{name}"),
    kv("Format", "{format}"),
    kv("File size", "{sizehr}"),
    kv("File time", "{time}"),
  }
  for _, exif in ipairs(EXIF_LINES) do
    if img and img.meta[exif[2]] then
      file[#file + 1] = kv(exif[1], "{meta." .. exif[2] .. "}")
    end
  end
  local list = { kv("Image", "{list.index} of {list.total}") }
  if img and img.frames > 1 then
    list[#list + 1] = kv("Frame", "{frame.index} of {frame.total}")
  end
  list[#list + 1] = kv("Size", "{frame.width}x{frame.height}")
  return {
    topleft = panel(file),
    topright = panel(list),
    bottomleft = panel({ kv("Scale", "{scale}") }),
  }
end

set_text(viewer, viewer_text(nil))
viewer.on_image_change(function()
  set_text(viewer, viewer_text(viewer.get_image()))
end)
viewer.set_window_background(gruvbox.bg0_h)                    -- window background
viewer.set_image_chessboard(16, gruvbox.bg0, gruvbox.bg1)      -- transparency grid

-- Scroll: Ctrl/Alt + wheel zooms at the pointer, plain wheel pans the image.
-- One wheel notch = 1.0 (negative = up), hi-res wheels send fractions.
viewer.on_scroll(function(mods, horizontal, vertical)
  if mods == "Ctrl" or mods == "Alt" then
    if vertical ~= 0 then
      local mouse = swayimg.get_mouse_pos()
      viewer.set_abs_scale(viewer.scale * 1.1 ^ -vertical, mouse.x, mouse.y)
    end
  else
    local pos = viewer.get_position()
    viewer.set_abs_position(pos.x + math.floor(horizontal * 50),
                            pos.y + math.floor(vertical * 50))
  end
end)

-- Zoom toward the window centre (window centre is the default anchor).
local function zoom(factor)
  return function() viewer.set_abs_scale(viewer.scale * factor) end
end

-- Move the image by a fraction of the window size.
local function pan(dx, dy)
  return function()
    local wnd = swayimg.get_window_size()
    local pos = viewer.get_position()
    viewer.set_abs_position(pos.x + math.floor(wnd.width * dx),
                            pos.y + math.floor(wnd.height * dy))
  end
end

-- Step through frames of an animation (stops playback).
local function step_frame(delta)
  return function()
    local img = viewer.get_image()
    if img and img.frames > 1 then
      viewer.frame = (viewer.frame + delta) % img.frames
    end
  end
end

local function open_image(mode, dir)
  return function() mode.open(dir) end
end

local function fix_scale(scale)
  return function() viewer.set_fix_scale(scale) end
end

-- Related keys share one help line (add_help) to keep the help short enough
-- for a 1080p screen at 2x scaling; their bind() calls have no description.

-- Navigation
bind(viewer, { "j", "l", "space", "Right", "Next" }, open_image(viewer, "next"), "next image")
bind(viewer, { "h", "k", "Left", "Prior" }, open_image(viewer, "prev"), "previous image")
bind(viewer, "Home", open_image(viewer, "first"))
bind(viewer, "End", open_image(viewer, "last"))
add_help(viewer, { "Home", "End" }, "first / last image")
bind(viewer, "Shift+Prior", step_frame(-1))
bind(viewer, "Shift+Next", step_frame(1))
add_help(viewer, { "Shift+Prior", "Shift+Next" }, "previous / next frame")

-- Scale and position ("+" is Shift+equal on the main keyboard)
bind(viewer, { "equal", "Shift+plus", "KP_Add" }, zoom(1.1))
bind(viewer, { "minus", "KP_Subtract" }, zoom(1 / 1.1))
add_help(viewer, { "equal", "Shift+plus", "minus" }, "zoom in / out")
bind(viewer, { "0", "BackSpace" }, function() viewer.reset() end, "reset zoom")
bind(viewer, "w", fix_scale("width"))
bind(viewer, "Shift+w", fix_scale("height"))
bind(viewer, "z", fix_scale("fit"))
bind(viewer, "Shift+z", fix_scale("fill"))
add_help(viewer, { "w", "Shift+w", "z", "Shift+z" }, "fit width / height / window / fill")
bind(viewer, "Up", pan(0, 0.1))
bind(viewer, "Down", pan(0, -0.1))
add_help(viewer, { "Up", "Down" }, "scroll up / down")

-- Transform
bind(viewer, "bracketleft", function() viewer.rotate(270) end)
bind(viewer, "bracketright", function() viewer.rotate(90) end)
add_help(viewer, { "bracketleft", "bracketright" }, "rotate left / right")
bind(viewer, "m", function() viewer.flip_horizontal() end)
bind(viewer, "Shift+m", function() viewer.flip_vertical() end)
add_help(viewer, { "m", "Shift+m" }, "mirror horizontally / vertically")

-- Window and modes
bind(viewer, { "f", "F11" }, toggle_fullscreen, "fullscreen")
bind(viewer, { "i", "t" }, toggle_text, "image info")
bind(viewer, "a", toggle_antialiasing, "anti-aliasing")
bind(viewer, { "Return", "KP_Enter" }, set_mode("gallery"))
bind(viewer, "s", function()
  swayimg.mode = "slideshow"
  status("Slide show started")
end)
add_help(viewer, { "Return", "s" }, "gallery / slideshow")

-- Files
bind(viewer, { "x", "Insert" }, function() viewer.mark_image() end, "mark image")
bind(viewer, "p", print_current(viewer))
bind(viewer, "Shift+p", print_marked)
add_help(viewer, { "p", "Shift+p" }, "print path / marked paths")
bind(viewer, "y", copy_path(viewer))
bind(viewer, "Shift+y", copy_image(viewer))
add_help(viewer, { "y", "Shift+y" }, "copy path / image")
bind(viewer, "e", show_in_files(viewer), "show in Nautilus")
bind(viewer, "Shift+s", send_to_phone(viewer), "send to phone (marked or current)")
bind(viewer, "r", toggle_order(viewer), "newest first / by name")
bind(viewer, { "d", "Delete" }, trash_image(viewer))
bind(viewer, { "Shift+d", "Shift+Delete" }, delete_image(viewer))
add_help(viewer, { "d", "Shift+d", "Delete" }, "trash / delete permanently")

bind(viewer, { "q", "Escape" }, quit, "quit")
bind(viewer, "slash", show_help, "this help")

-- Force scale mode on window resize (useful for tiling compositors)
swayimg.on_window_resize(function()
  if swayimg.mode == "viewer" then
    viewer.set_fix_scale("optimal")
  end
end)

--------------------------------------------------------------------------------
-- Slide show mode
--------------------------------------------------------------------------------
slideshow.timeout = 5                     -- timeout to switch image
slideshow.default_scale = "fit"           -- default image scale
slideshow.history = 0                     -- number of images in history cache
slideshow.drag_button = "MouseLeft"       -- mouse button to drag image
slideshow.mark_color = gruvbox.aqua       -- mark icon color
set_text(slideshow, { topleft = panel({ line("{name}") }) })
slideshow.set_window_background("extend") -- blurred copy of the image fills the window
slideshow.set_image_chessboard(16, gruvbox.bg0, gruvbox.bg1) -- transparency grid

bind(slideshow, { "j", "l", "space", "Right", "Next" }, open_image(slideshow, "next"), "next image")
bind(slideshow, { "h", "k", "Left", "Prior" }, open_image(slideshow, "prev"), "previous image")
bind(slideshow, { "f", "F11" }, toggle_fullscreen, "fullscreen")
bind(slideshow, { "i", "t" }, toggle_text, "image info")
bind(slideshow, "s", function()
  swayimg.mode = "viewer"
  status("Slide show stopped")
end, "stop slideshow")
bind(slideshow, { "Return", "KP_Enter" }, set_mode("gallery"), "gallery")
bind(slideshow, { "q", "Escape" }, quit, "quit")
bind(slideshow, "slash", show_help, "this help")

--------------------------------------------------------------------------------
-- Gallery mode
--------------------------------------------------------------------------------
gallery.aspect = "fill"                   -- thumbnail aspect ratio
gallery.thumb_size = 200                  -- thumbnail size in pixels
gallery.padding_size = 8                  -- padding between thumbnails
gallery.border_size = 3                   -- border size for selected thumbnail
gallery.border_color = gruvbox.yellow     -- border color for selected thumbnail
gallery.selected_scale = 1.15             -- scale for selected thumbnail
gallery.selected_color = gruvbox.bg2      -- background for selected thumbnail
gallery.unselected_color = gruvbox.bg0    -- background for other thumbnails
gallery.window_color = gruvbox.bg0_h      -- window background color
gallery.mark_color = gruvbox.aqua         -- mark icon color
gallery.pinch_factor = 100.0              -- pinch gesture factor
gallery.cache = 100                       -- thumbnails stored in memory
gallery.preload = false                   -- preload invisible thumbnails
gallery.pstore = false                    -- persistent storage for thumbnails
set_text(gallery, {
  topleft = panel({ kv("File", "{name}") }),
  topright = panel({ line("{list.index} of {list.total}") }),
})

-- Window title follows the selected thumbnail
gallery.on_image_change(function()
  local image = gallery.get_image()
  if image then
    swayimg.title = "Gallery: " .. image.path
  end
end)

-- Click a thumbnail to open it (built-in behaviour, removed by bind_reset)
gallery.on_mouse("MouseLeft", function()
  local pos = swayimg.get_mouse_pos()
  gallery.select_at(pos.x, pos.y)
  swayimg.mode = "viewer"
end)

local function gsel(dir)
  return function() gallery.select(dir) end
end

local function thumb_zoom(factor)
  return function()
    local size = gallery.thumb_size
    gallery.thumb_size = math.max(size + math.floor(size * factor), 0)
  end
end

-- Navigation. Swayimg has no API to scroll the gallery without moving the
-- selection, so Ctrl+e / Ctrl+y move one row like j / k.
bind(gallery, { "h", "Left" }, gsel("left"))
bind(gallery, { "j", "Down", "Ctrl+e" }, gsel("down"))
bind(gallery, { "k", "Up", "Ctrl+y" }, gsel("up"))
bind(gallery, { "l", "Right" }, gsel("right"))
add_help(gallery, { "h", "j", "k", "l", "arrows" }, "move selection")
add_help(gallery, { "Ctrl+e", "Ctrl+y" }, "row down / up")
bind(gallery, { "Shift+h", "Home" }, gsel("first"))
bind(gallery, { "Shift+l", "End" }, gsel("last"))
add_help(gallery, { "Shift+h", "Shift+l", "Home", "End" }, "first / last image")
bind(gallery, { "Shift+j", "Next" }, gsel("pgdown"))
bind(gallery, { "Shift+k", "Prior" }, gsel("pgup"))
add_help(gallery, { "Shift+j", "Shift+k", "Next", "Prior" }, "page down / up")

-- Thumbnails, window and modes
bind(gallery, { "equal", "Shift+plus", "KP_Add" }, thumb_zoom(0.1))
bind(gallery, { "minus", "KP_Subtract" }, thumb_zoom(-0.1))
add_help(gallery, { "equal", "Shift+plus", "minus" }, "bigger / smaller thumbnails")
bind(gallery, { "f", "F11" }, toggle_fullscreen, "fullscreen")
bind(gallery, { "i", "t" }, toggle_text, "image info")
bind(gallery, "a", toggle_antialiasing, "anti-aliasing")
bind(gallery, { "Return", "KP_Enter" }, set_mode("viewer"))
bind(gallery, "s", set_mode("slideshow"))
add_help(gallery, { "Return", "s" }, "open in viewer / slideshow")

-- Files (same keys as in the viewer)
bind(gallery, { "x", "Insert" }, function() gallery.mark_image() end, "mark image")
bind(gallery, "p", print_current(gallery))
bind(gallery, "Shift+p", print_marked)
add_help(gallery, { "p", "Shift+p" }, "print path / marked paths")
bind(gallery, "y", copy_path(gallery))
bind(gallery, "Shift+y", copy_image(gallery))
add_help(gallery, { "y", "Shift+y" }, "copy path / image")
bind(gallery, "e", show_in_files(gallery), "show in Nautilus")
bind(gallery, "Shift+s", send_to_phone(gallery), "send to phone (marked or current)")
bind(gallery, "r", toggle_order(gallery), "newest first / by name")
bind(gallery, { "d", "Delete" }, trash_image(gallery))
bind(gallery, { "Shift+d", "Shift+Delete" }, delete_image(gallery))
add_help(gallery, { "d", "Shift+d", "Delete" }, "trash / delete permanently")

bind(gallery, { "q", "Escape" }, quit, "quit")
bind(gallery, "slash", show_help, "this help")
