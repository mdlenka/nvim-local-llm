local parse = require("local_llm.parse")
local eq = assert.are.same

describe("parse.parse_words", function()
  it("parses well-formed OpenAI response", function()
    local r = { choices = { { message = { content = '{"words":["scattering","scattered","scatter"]}' } } } }
    eq({ "scattering", "scattered", "scatter" }, parse.parse_words(r))
  end)
  it("parses markdown-fenced JSON", function()
    local r = { choices = { { message = { content = '```json\n{"words":["calibrated","calculated"]}\n```' } } } }
    eq({ "calibrated", "calculated" }, parse.parse_words(r))
  end)
end)
