-- lua/floating_terminal.lua
local M = {}

-- store buffer, window, cursor info
M.buf = nil
M.win = nil
M.cursor = { 1, 0 } -- default row 1, col 0

M.toggle = function(cmd)
  cmd = cmd or vim.o.shell or 'bash'

  -- Close existing floating terminal if it exists
  if M.win and type(M.win) == 'number' and vim.api.nvim_win_is_valid(M.win) then
    local ok, cursor = pcall(vim.api.nvim_win_get_cursor, M.win)
    if ok then
      M.cursor = cursor
    else
      M.cursor = { 1, 0 }
    end

    vim.api.nvim_win_close(M.win, true)
    M.win = nil
    return
  end

  -- Create new buffer if needed
  if not M.buf or not vim.api.nvim_buf_is_valid(M.buf) then
    M.buf = vim.api.nvim_create_buf(false, true) -- unlisted scratch buffer
    vim.fn.termopen(cmd)
  end

  -- Window dimensions (80% of screen)
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local opts = {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
  }

  -- Open floating window
  M.win = vim.api.nvim_open_win(M.buf, true, opts)

  -- Ensure cursor is valid
  if not M.cursor or type(M.cursor) ~= 'table' or M.cursor[1] < 1 then
    M.cursor = { 1, 0 }
  end

  -- Set cursor safely
  if M.win and type(M.win) == 'number' and vim.api.nvim_win_is_valid(M.win) then
    pcall(vim.api.nvim_win_set_cursor, M.win, M.cursor)
  end

  -- Map <Esc> to toggle terminal from inside
  vim.api.nvim_buf_set_keymap(M.buf, 'n', '<Esc>', "<cmd>lua require('floating_terminal').toggle()<CR>", { noremap = true, silent = true })

  -- Cleanup if buffer is wiped
  vim.api.nvim_create_autocmd('BufWipeout', {
    buffer = M.buf,
    callback = function()
      M.buf = nil
      M.win = nil
    end,
  })
end

return M
