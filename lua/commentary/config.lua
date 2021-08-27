local M = {}

--helper function to use default value if the user vaule is nil
local if_nil = function(value, default_value)
	return value ~= nil and value or default_value
end

-- default_langugages_config table contains key & value
-- key: the language name
-- value: a table with the following elements
-- index1 single_line_comment
-- index2 multiline comment
-- index3 prefer_multicomment
local default_langugages_config = {
	go = { "//", { "/*", "*/" }, false },
	lua = { "--", { "--[[", "--]]" }, false},
	tyescript = { "//", { "/*", "*/" }, false },
	vim = { "\"", {}, false},
}

--the config structure contains the following:
--key: the language name
--value: is a table that has the following keys/values
--single_line_comment: string
--multiline_comment: table that has opening/closing comment strings (optional)
--perfer_multiline: boolean
--example:
--{ "go"= { single_line_comment= "//", multiline_comment= { "/*", "*/"} , perfer_multiline= false } }
M.set_opts = function(config)
	local user_config = {}
	config = config == nil and {} or config

	for k, v in pairs(config) do
		local key = k
		local value = {}

		if v.single_line_comment == nil then
			error("single_line_comment parameter cannot be nil for language " .. key)
		end

		local default_sign_line_comment = default_langugages_config[key] and default_langugages_config[key][1] or nil
		table.insert(value, if_nil(v.single_line_comment, default_sign_line_comment))

		local default_multiline_comment = default_langugages_config[key] and default_langugages_config[key][2] or nil
		table.insert(value, if_nil(v.multiline_comment, default_multiline_comment))

		local default_perfer_multiline = default_langugages_config[key] and default_langugages_config[key][3] or false
		table.insert(value, if_nil(v.perfer_multiline, default_perfer_multiline))

		user_config[key]  = value
	end

	M.languages = vim.tbl_deep_extend("keep", user_config, default_langugages_config)
  return M
end

return M
