--!strict
-- Ponto de entrada do servidor. Por enquanto só confirma que o Rojo sincronizou.
-- Os sistemas de economia, save e compras entram aqui nas próximas etapas.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Mapas = require(Shared:WaitForChild("Mapas"))

local nomes = {}
for nome in Mapas do
	table.insert(nomes, nome)
end
table.sort(nomes)

print(`[Ferrovia] Servidor iniciado. Mapas carregados: {table.concat(nomes, ", ")}`)
