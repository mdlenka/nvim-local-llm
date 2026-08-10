local M = {}

local function try_decode(s)
  local ok, decoded = pcall(vim.json.decode, s)
  if not ok or type(decoded) ~= "table" then return nil end
  if type(decoded.words) == "table"      then return decoded.words end
  if type(decoded.candidates) == "table" then return decoded.candidates end
  if type(decoded.completions) == "table"then return decoded.completions end
  if decoded[1] ~= nil then return decoded end
  return nil
end

function M.parse_words(resp)
  if type(resp) ~= "table" then return {} end

  local content
  if resp.choices and resp.choices[1] and resp.choices[1].message then
    content = resp.choices[1].message.content
    
    -- If the model is a reasoning model (like Gemma-4-E4B-it), it might put 
    -- the answer in reasoning_content if it runs out of tokens before the final output.
    if type(content) ~= "string" or content == "" then
      content = resp.choices[1].message.reasoning_content
    end
  elseif type(resp.content) == "string" then
    content = resp.content
  elseif type(resp.text) == "string" then
    content = resp.text
  end
  
  if type(content) ~= "string" or content == "" then return {} end

  local direct = try_decode(content)
  if direct then return direct end

  local fenced = content:match("```json%s*(.-)%s*```") or content:match("```%s*(.-)%s*```")
  if fenced then
    local f = try_decode(fenced)
    if f then return f end
  end

  local obj = content:match("{.*}")
  if obj then
    local o = try_decode(obj)
    if o then return o end
  end

  local arr = content:match("%[.*%]")
  if arr then
    local a = try_decode(arr)
    if a then return a end
  end

  local words = {}
  for w in content:gmatch("[%w][%w%-]+") do
    table.insert(words, w)
  end
  return words
end

return M
