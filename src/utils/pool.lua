local Pool = {}
Pool.__index = Pool

function Pool.nuevo(cantidad, constructor)
  local p = setmetatable({}, Pool)
  p.objetos = {}
  for i = 1, cantidad do
    p.objetos[i] = { activo = false, instancia = constructor() }
  end
  return p
end

function Pool:obtener()
  for i = 1, #self.objetos do
    if not self.objetos[i].activo then
      self.objetos[i].activo = true
      return self.objetos[i].instancia
    end
  end
  return nil
end

function Pool:devolver(instancia)
  for i = 1, #self.objetos do
    if self.objetos[i].instancia == instancia then
      self.objetos[i].activo = false
      return
    end
  end
end

function Pool:iterarActivos()
  local i = 0
  return function()
    i = i + 1
    while i <= #self.objetos do
      if self.objetos[i].activo then return self.objetos[i].instancia end
      i = i + 1
    end
  end
end

return Pool