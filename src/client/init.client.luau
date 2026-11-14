--!strict
-- Ponto de entrada do cliente: abre o mapa do Brasil em tela cheia (protótipo do mapa 2D).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Mapas = require(Shared:WaitForChild("Mapas"))
local Emojis = require(Shared:WaitForChild("Emojis"))
local Assets = require(Shared:WaitForChild("Assets"))
local DadosBrasil = require(Shared:WaitForChild("Dados"):WaitForChild("Brasil"))
local MapaView = require(script:WaitForChild("MapaView"))

local jogador = Players.LocalPlayer
local playerGui = jogador:WaitForChild("PlayerGui")

-- O jogo é só interface: câmera parada e controles do personagem desligados.
local camera = workspace.CurrentCamera
if camera then
	camera.CameraType = Enum.CameraType.Scriptable
end
task.spawn(function()
	local ok, erro = pcall(function()
		local modulo = jogador:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule", 10)
		if modulo then
			local playerModule = require(modulo :: ModuleScript) :: any
			playerModule:GetControls():Disable()
		end
	end)
	if not ok then
		warn("[Ferrovia] Não consegui desligar os controles:", erro)
	end
end)
pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
end)

local era = Theme.PorId.vapor
-- textura do mar da era, se já tiver sido enviada ao Roblox
local idMar = era.marPadrao and (Assets.Ids :: any)[era.marPadrao]
if idMar and idMar ~= "rbxassetid://0" then
	era.marTextura = idMar
end

local tela = Instance.new("ScreenGui")
tela.Name = "Ferrovia"
tela.IgnoreGuiInset = true
tela.ResetOnSpawn = false
tela.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
tela.Parent = playerGui

local mapa = MapaView.new(tela, Mapas.brasil, DadosBrasil, era)

-- Enquadra as estações das linhas do MVP.
local minimo = Vector2.new(math.huge, math.huge)
local maximo = Vector2.new(-math.huge, -math.huge)
for _, e: any in DadosBrasil.estacoes do
	minimo = minimo:Min(e.pos)
	maximo = maximo:Max(e.pos)
end
task.spawn(function()
	-- espera a interface ter tamanho real antes de enquadrar
	while mapa.raiz.AbsoluteSize.X <= 0 do
		task.wait()
	end
	mapa:_atualizarZoomMin()
	mapa:focar(minimo, maximo, 80)
end)

-- Faixa de depuração (temporária): mostra o zoom e como usar.
local info = Instance.new("TextLabel")
info.Name = "Info"
info.AnchorPoint = Vector2.new(0, 1)
info.Position = UDim2.new(0, 16, 1, -16)
info.AutomaticSize = Enum.AutomaticSize.XY
info.BackgroundColor3 = era.cores.panel
info.TextColor3 = era.cores.ink
info.FontFace = era.fontes.body
info.TextSize = 16
info.TextXAlignment = Enum.TextXAlignment.Left
info.ZIndex = 20
info.Parent = tela
local margem = Instance.new("UIPadding")
margem.PaddingLeft = UDim.new(0, 10)
margem.PaddingRight = UDim.new(0, 10)
margem.PaddingTop = UDim.new(0, 6)
margem.PaddingBottom = UDim.new(0, 6)
margem.Parent = info
local borda = Instance.new("UIStroke")
borda.Color = era.cores.ink
borda.Thickness = 1.5
borda.Parent = info

local function atualizarInfo(zoom: number)
	info.Text = `{Emojis.linhas} Brasil · {era.nome} · zoom {string.format("%.1f", zoom)}x   |   arraste para mover · roda do mouse ou pinça para zoom`
end
mapa.aoMudarCamera.Event:Connect(atualizarInfo)
atualizarInfo(mapa.zoom)

print(`[Ferrovia] Cliente iniciado: mapa do Brasil com {#DadosBrasil.linhas} linhas.`)
