# Tinker.nvim

A free Tinkerwell alternative for Neovim! Execute Laravel code interactively without paying for expensive software.

## Features

- ✅ Detects Laravel projects automatically (checks `composer.json` for `laravel/framework`)
- ✅ Split view: PHP code buffer (LEFT) + Output buffer (RIGHT)
- ✅ Full LSP support in the code buffer
- ✅ Execute current line or visual selection with `<CR>`
- ✅ Auto-saves to project-specific file
- ✅ Real-time output display with syntax highlighting
- ✅ Clean, minimal UX

## Usage

### Commands

- `:Tinker` - Toggle Laravel Tinker (open/close)

### Keybindings

**Global:**
- `<leader>lt` - Toggle Laravel Tinker

**Inside Tinker code buffer:**
- `<CR>` - Execute current line (normal mode) or selection (visual mode)
- `<leader>tc` - Clear output
- `:w` - Save your tinker session

**Inside output buffer:**
- `q` - Close tinker

### Quick Start

1. Open a Laravel project
2. Press `<leader>lt` or run `:Tinker`
3. Write PHP code in the left buffer (start with `<?php` if you want)
4. Press `<CR>` to execute the current line
5. See results in the right buffer
6. Press `:w` to save your session
7. Press `<leader>lt` or `:Tinker` again to close - your work is auto-saved!

### Examples

```php
<?php

// Get user count
User::count()

// Create a user
User::create(['name' => 'John', 'email' => 'john@example.com'])

// Run queries
DB::table('users')->where('active', 1)->count()

// Test relationships
$user = User::first()
$user->posts

// Multi-line execution (select in visual mode and press Enter)
$users = User::all();
foreach($users as $user) {
    echo $user->name;
}
```

### How Auto-Save Works

Each Laravel project gets its own tinker file:
- Your code is automatically saved to `~/.config/mytinker/[project-path].php`
- For example: `~/.config/mytinker/repos/assetplan/Backoffice.php`
- When you toggle `:Tinker`, it always loads your last session for that project
- Just press `:w` to manually save anytime
- Auto-saves when you close tinker

## Configuration

Default configuration in `/lua/plugins/tinker.lua`:

```lua
{
    auto_scroll = true,           -- Auto scroll output buffer
    split_direction = "vertical", -- 'vertical' or 'horizontal'
    split_ratio = 0.5,           -- Ratio of code buffer to output buffer
    tinker_dir = "~/.config/mytinker", -- Where to store project sessions
}
```

## Why?

Because Tinkerwell charges too much and we can build this ourselves! 🚀

## License

Free as in freedom. Use it, modify it, share it.
