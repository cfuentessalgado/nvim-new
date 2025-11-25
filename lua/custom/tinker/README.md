# Tinker.nvim

A free Tinkerwell alternative for Neovim! Execute Laravel code interactively without paying for expensive software.

## Features

- ✅ Detects Laravel projects automatically (checks `composer.json` for `laravel/framework`)
- ✅ Split view: PHP code buffer (LEFT) + Output buffer (RIGHT)
- ✅ Full LSP support in the code buffer
- ✅ Execute current line or visual selection
- ✅ Auto-scrolling output
- ✅ Real-time output display
- ✅ Clean output (ANSI codes stripped automatically)
- ✅ Syntax highlighting in both buffers

## Usage

### Commands

- `:Tinker` - Open Laravel Tinker
- `:TinkerClose` - Close Tinker
- `:TinkerToggle` - Toggle Tinker
- `:TinkerClear` - Clear output buffer

### Keybindings

**Global:**
- `<leader>lt` - Open Laravel Tinker

**Inside Tinker code buffer:**
- `<CR>` or `<leader>te` - Execute current line (normal mode)
- `<CR>` or `<leader>te` - Execute selection (visual mode)
- `<leader>tc` - Clear output
- `<leader>tq` - Quit tinker

**Inside output buffer:**
- `q` - Quit tinker

### Quick Start

1. Open a Laravel project
2. Press `<leader>lt` or run `:Tinker`
3. Write PHP code in the left buffer (no need for `<?php` tag)
4. Press `<CR>` to execute the current line
5. See results in the right buffer

### Examples

```php
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

## Configuration

Default configuration in `/lua/plugins/tinker.lua`:

```lua
{
    auto_scroll = true,           -- Auto scroll output buffer
    save_history = true,          -- Save tinker history (future feature)
    split_direction = "vertical", -- 'vertical' or 'horizontal'
    split_ratio = 0.5,           -- Ratio of code buffer to output buffer
}
```

## Why?

Because Tinkerwell charges too much and we can build this ourselves! 🚀

## License

Free as in freedom. Use it, modify it, share it.
