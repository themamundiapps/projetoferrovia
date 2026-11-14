--!strict
-- Ponto de entrada do cliente. Por enquanto só confirma que o Rojo sincronizou.
-- A interface (mapa 2D, painéis, menu) entra aqui nas próximas etapas.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Emojis = require(Shared:WaitForChild("Emojis"))

print(`[Ferrovia] Cliente iniciado. {#Theme.Eras} eras no tema. Teste de emoji: {Emojis.trens} {Emojis.carga_cafe}`)
