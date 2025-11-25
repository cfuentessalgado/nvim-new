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

**Basic Commands:**
- `:Tinker` - Toggle Laravel Tinker (show/hide, preserves session)
- `:TinkerClose` - Kill Tinker session completely
- `:TinkerToggle` - Toggle Tinker (alias for `:Tinker`)
- `:TinkerClear` - Clear output buffer
- `:TinkerStatus` - Show Tinker status

**Snippet Management:**
- `:TinkerSave [name]` - Save current code buffer as snippet
- `:TinkerLoad [name]` - Load a snippet (shows picker if no name)
- `:TinkerDelete [name]` - Delete a snippet (shows picker if no name)
- `:TinkerList` - List all saved snippets
- `:TinkerNew` - Create new snippet (clear buffer)
- `:w` - In code buffer, saves snippet (smart save based on current state)

### Keybindings

**Global:**
- `<leader>lt` - Open Laravel Tinker

**Inside Tinker code buffer:**
- `<CR>` or `<leader>te` - Execute current line (normal mode)
- `<CR>` or `<leader>te` - Execute selection (visual mode)
- `<leader>tc` - Clear output
- `<leader>tq` - Hide tinker (toggle off, keeps session)
- `<leader>tk` - Kill tinker session completely
- `<leader>ts` - Save current buffer as snippet
- `<leader>tl` - Load a snippet
- `<leader>td` - Delete a snippet
- `<leader>tn` - New snippet (clear buffer)
- `:w` - Save snippet (if loaded, updates it; if new, prompts for name)

**Inside output buffer:**
- `q` - Hide tinker

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

### Snippet Workflow

Save your commonly used Tinker commands as snippets for quick reuse:

1. **Write some useful code** in the Tinker buffer:
   ```php
   // Database queries
   User::count()
   Post::where('published', true)->count()
   
   // Check cache
   Cache::get('key')
   ```

2. **Save it**: 
   - Press `:w` and enter a name when prompted
   - Or press `<leader>ts` or run `:TinkerSave database-check`

3. **Later, load it**: 
   - Press `<leader>tl` and select from the picker
   - Or run `:TinkerLoad database-check`
   - The buffer name will show "Tinker: database-check"

4. **Edit and re-save**: 
   - Just press `:w` to update the loaded snippet
   - No need to enter the name again!

5. **Manage snippets**:
   - New snippet: `<leader>tn` or `:TinkerNew`
   - List all: `:TinkerList`
   - Delete: `<leader>td` or `:TinkerDelete snippet-name`

6. **Toggle workflow**:
   - Press `<leader>lt` or `:Tinker` to hide Tinker and resume editing
   - Press `<leader>lt` again to show it - your code and session are still there!
   - Use `<leader>tk` or `:TinkerClose` to kill the session completely

**Snippet ideas:**
- Database health checks
- User testing scenarios
- Cache debugging
- Queue inspection
- Model relationship tests
- Common development tasks

Snippets are stored in: `~/.local/share/nvim/tinker-snippets/`

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
