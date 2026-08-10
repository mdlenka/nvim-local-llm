local context = require("local_llm.context")
local eq = assert.are.same

describe("context.get_prefix_from_line", function()
  it("extracts ASCII prefix at end of line", function()
    local info = context.get_prefix_from_line("The muon scat", 13)
    eq("scat", info.prefix)
    eq(9,  info.start_col)
    eq(13, info.end_col)
  end)
  it("returns nil when cursor is on whitespace", function()
    assert.is_nil(context.get_prefix_from_line("hello world ", 12))
  end)
end)

describe("context.get_context_from_lines", function()
  it("collects up to max_chars across lines", function()
    local lines = { "aaa", "bbb", "ccc" }
    local ctx = context.get_context_from_lines(lines, 3, 3, 100)
    eq("aaa\nbbb\nccc", ctx)
  end)
end)
