--!strict
-- Ponto de entrada do cliente: mapa do Brasil + interface da economia.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Mapas = require(Shared:WaitForChild("Mapas"))
local Assets = require(Shared:WaitForChild("Assets"))
local Economia = require(Shared:WaitForChild("Economia"))
local Emojis = require(Shared:WaitForChild("Emojis"))
local DadosBrasil = require(Shared:WaitForChild("Dados"):WaitForChild("Brasil"))
local MapaView = require(script:WaitForChild("MapaView"))
local Interface = require(script:WaitForChild("Interface"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local remoteEstado = Remotes:WaitForChild("Estado") :: RemoteEvent
local remoteAcao = Remotes:WaitForChild("Acao") :: RemoteFunction
local remotePedirEstado = Remotes:WaitForChild("PedirEstado") :: RemoteFunction

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
local ui = Interface.new(tela, era, DadosBrasil)

-- Enquadra as estações das linhas do MVP.
local minimo = Vector2.new(math.huge, math.huge)
local maximo = Vector2.new(-math.huge, -math.huge)
for _, e: any in DadosBrasil.estacoes do
	minimo = minimo:Min(e.pos)
	maximo = maximo:Max(e.pos)
end
task.spawn(function()
	while mapa.raiz.AbsoluteSize.X <= 0 do
		task.wait()
	end
	mapa:_atualizarZoomMin()
	mapa:focar(minimo, maximo, 80)
end)

-- ---------------------------------------------------------------- estado vindo do servidor

local function situacoes(estado: any): { [string]: string }
	local s = {}
	for i, linha in DadosBrasil.linhas do
		for j, t in linha.trechos do
			s[t.id] = Economia.situacaoTrecho(estado, DadosBrasil, i, j)
		end
	end
	return s
end

local function aplicarEstado(estado: any)
	if not estado then
		return
	end
	mapa:definirSituacao(situacoes(estado))
	ui:atualizarEstado(estado)
end

remoteEstado.OnClientEvent:Connect(aplicarEstado)
task.spawn(function()
	aplicarEstado(remotePedirEstado:InvokeServer())
end)

-- ---------------------------------------------------------------- seleção e ações

mapa.aoTocar.Event:Connect(function(pontoMapa: Vector2)
	local id = mapa:trechoProximo(pontoMapa, 22)
	mapa:selecionar(id)
	if id then
		ui:abrir(id)
	else
		ui:fechar()
	end
end)

ui.aoFechar.Event:Connect(function()
	mapa:selecionar(nil)
end)

ui.aoAgir.Event:Connect(function(tipo: string, args: any)
	local resposta = remoteAcao:InvokeServer(tipo, args)
	if resposta and not resposta.ok then
		ui:avisar(`{Emojis.alerta} {resposta.erro or "Não deu certo."}`)
	elseif resposta and resposta.ok then
		ui:avisar(if tipo == "trem" then `{Emojis.trens} Trem comprado!` else `{Emojis.construir} Trecho construído!`, 2)
		if tipo == "construir" then
			-- se o trecho novo fez a linha precisar de mais trens, avisa
			task.delay(0.4, function()
				local linha = Economia.acharTrecho(DadosBrasil, args.trecho)
				local estado = ui.estado
				if linha and estado and Economia.trensFaltando(estado, linha) > 0 then
					ui:avisar(`{Emojis.trens} A linha {linha.nome} cresceu e precisa de mais 1 trem para render 100%.`, 5)
				end
			end)
		end
	end
end)

task.delay(1.5, function()
	ui:avisar(`{Emojis.linhas} Toque num trilho para ver a concessão. Comece pela E.F. Mauá, perto do Rio.`, 6)
end)

print(`[Ferrovia] Cliente iniciado: mapa do Brasil com {#DadosBrasil.linhas} linhas.`)
