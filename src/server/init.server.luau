--!strict
-- Ponto de entrada do servidor.

local Players = game:GetService("Players")

-- O jogo é só interface: não criar avatar no mundo 3D.
Players.CharacterAutoLoads = false

require(script:WaitForChild("Jogo"))

print("[Ferrovia] Servidor iniciado.")
