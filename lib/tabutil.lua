tabutil = require'tabutil'

tabutil.remove = function (t,v) 
  table.remove(t,tab.key(t,v))
end

tabutil.add_or_remove = function (t,v)
  if tab.contains(t,v) then
    tab.remove(t,v)
  else
    table.insert(t,v)
  end
end

tabutil.get = function (t,v)
  local key = tab.key(t,v)
  if key then
    return t[key]
  end
  return nil
end

tabutil.insert_table = function (t,v)
  for _,b in pairs(v) do table.insert(t,b) end
end

return tabutil