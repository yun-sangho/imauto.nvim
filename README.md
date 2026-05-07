# imauto.nvim

Automatically switch the macOS input method when entering and leaving Neovim's
insert mode. Leaving insert switches to a default IM (e.g. ABC / English);
re-entering insert restores whatever you were typing in before.

No external CLI dependency — a tiny Carbon-based Swift helper is bundled with
the plugin and built on first use.

## Requirements

- macOS
- Neovim 0.9+ (0.10+ recommended)
- **Xcode Command Line Tools** — required to compile the bundled Swift helper.
  Install with:

  ```sh
  xcode-select --install
  ```

  Most macOS development machines already have this. If `swiftc --version`
  prints a version, you're set. The build itself takes under a second.

## Installation

### lazy.nvim

```lua
{
  "yun-sangho/imauto.nvim",
  build = "make build",
  event = "VeryLazy",
  opts = {},
}
```

The `build` hook compiles `bin/imauto` once at install/update time. The
plugin also auto-builds on first use if the binary is missing, so the hook is
optional but recommended.

### packer.nvim

```lua
use({
  "yun-sangho/imauto.nvim",
  run = "make build",
  config = function()
    require("imauto").setup({})
  end,
})
```

## Configuration

Defaults:

```lua
require("imauto").setup({
  default_im = "com.apple.keylayout.ABC",
  -- Leave nil to use the bundled bin/imauto. Set to "macism" or any
  -- other CLI path to override.
  cmd = nil,
  set_default_events = { "InsertLeave", "CmdlineLeave" },
  set_previous_events = { "InsertEnter" },
  restore_focus_state = true,
  async = true,
})
```

| Option | Description |
| --- | --- |
| `default_im` | IM identifier used when leaving insert mode. |
| `cmd` | Override the IM-switching binary. `nil` uses the bundled helper. |
| `set_default_events` | Events that trigger switching to `default_im`. `{}` disables. |
| `set_previous_events` | Events that restore the previous IM. `{}` disables. |
| `restore_focus_state` | Remember IM on `FocusLost`, restore on `FocusGained`. |
| `async` | Run IM-switch commands without blocking the UI. |

## Commands

- `:ImautoToggle` — toggle between default and previous IM.
- `:ImautoGet` — print current IM.
- `:ImautoSet <id>` — set IM directly.

## API

```lua
local im = require("imauto")
im.setup(opts)
im.toggle()
im.set("com.apple.inputmethod.Korean.2SetKorean")
im.get()
```

## Finding your IM identifier

```sh
./bin/imauto           # prints the currently selected source id
```

Common identifiers:

| Layout | ID |
| --- | --- |
| US / ABC | `com.apple.keylayout.ABC` |
| Korean (2-Set) | `com.apple.inputmethod.Korean.2SetKorean` |
| Japanese (Romaji) | `com.apple.inputmethod.Kotoeri.RomajiTyping.Roman` |
| Chinese (Pinyin Simplified) | `com.apple.inputmethod.SCIM.ITABC` |

## How it works

The bundled `swift/imauto.swift` calls Carbon's `TISCopyCurrentKeyboardInputSource`
and `TISSelectInputSource` to read/set the active input source. After every
selection it verifies the current source and retries once with a short delay to
work around a long-standing macOS quirk where switching to CJK IMEs occasionally
updates the menu bar without activating the actual input mode.

The plugin registers autocmds in the `Imauto` group:

- On `InsertLeave` / `CmdlineLeave`, it records the current IM and switches to
  `default_im`.
- On `InsertEnter`, it restores the previously recorded IM.
- On `FocusLost` / `FocusGained`, it remembers and restores your IM so other
  apps don't leave you stranded in the wrong layout.

## Building manually

```sh
make build
make clean
```

## License

MIT
