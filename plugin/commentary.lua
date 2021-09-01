if vim.g.loaded_commentary then
  return
end

vim.g.loaded_commentary = true


commentary = require("commentary")
commentary.setup()
