vim.cmd([[set rtp+=.]])
local ok_plenary = pcall(function()
  local p = os.getenv("PLENARY_DIR")
  if p then vim.cmd("set rtp+=" .. p) end
end)
require("plenary.busted")
