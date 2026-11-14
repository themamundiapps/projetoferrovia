--!strict
-- Ponto de entrada do servidor.
-- Os sistemas de economia, save e compras entram aqui nas próximas etapas.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- O jogo é só interface: não criar avatar no mundo 3D.
Players.CharacterAutoLoads = false

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Mapas = require(Shared:WaitForChild("Mapas"))

local nomes = {}
for nome in Mapas do
	table.insert(nomes, nome)
end
table.sort(nomes)

print(`[Ferrovia] Servidor iniciado. Mapas carregados: {table.concat(nomes, ", ")}`)
