local completion = require "cc.shell.completion"



shell.setCompletionFunction("viviedit/viviedit.lua", completion.build(completion.file))

shell.setAlias("viviedit", "viviedit/viviedit.lua")
shell.setAlias("vividownload", "viviedit/vividownload.lua")

settings.load(".settings")
