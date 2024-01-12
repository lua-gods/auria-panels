-- fake not host
-- getmetatable(host).__index.isHost = function() return false end

-- load files
for _, v in pairs(listFiles('', true)) do
   if v ~= 'init' then
      require(v)
   end
end