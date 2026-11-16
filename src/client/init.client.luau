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
local Metas = require(Shared:WaitForChild("Metas"))
local Emojis = require(Shared:WaitForChild("Emojis"))
local DadosBrasil = require(Shared:WaitForChild("Dados"):WaitForChild("Brasil"))
local MapaView = require(script:WaitForChild("MapaView"))
local Interface = require(script:WaitForChild("Interface"))
local Menu = require(script:WaitForChild("Menu"))
local Tutorial = require(script:WaitForChild("Tutorial"))
local Ficha = require(script:WaitForChild("Ficha"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local remoteEstado = Remotes:WaitForChild("Estado") :: RemoteEvent
local remoteAcao = Remotes:WaitForChild("Acao") :: RemoteFunction
local remotePedirEstado = Remotes:WaitForChild("PedirEstado") :: RemoteFunction

-- Pesquisas usam o horário do servidor (o relógio do aparelho pode estar errado).
Economia.relogio = function(): number
	return workspace:GetServerTimeNow()
end

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

local tela = Instance.new("ScreenGui")
tela.Name = "Ferrovia"
tela.IgnoreGuiInset = true
tela.ResetOnSpawn = false
tela.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
tela.Parent = playerGui

-- Painéis, caixa e menu ficam numa segunda tela que respeita a barra do Roblox (botão do menu, chat):
-- o mapa ocupa a tela inteira, mas nada clicável fica embaixo dos botões do Roblox.
local telaUI = Instance.new("ScreenGui")
telaUI.Name = "FerroviaUI"
telaUI.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
telaUI.DisplayOrder = 1
telaUI.ResetOnSpawn = false
telaUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
telaUI.Parent = playerGui

-- Onde a câmera começa (e volta, em "Reenquadrar"): a região das primeiras linhas, definida nos dados.
local minimo: Vector2 = DadosBrasil.foco.min
local maximo: Vector2 = DadosBrasil.foco.max

local mapa: any = nil
local ui: any = nil
local menu: any = nil
local tutorial: any = nil
local ficha: any = nil
local ajustesSalvos: { [string]: boolean } = { nomesEstacoes = true, nomesMapa = true, trens = true }
local eraAtual: string? = nil
local ultimoEstado: any = nil
local conexoesTela: { RBXScriptConnection } = {}

local function situacoes(estado: any): { [string]: string }
	local s = {}
	for i, linha in DadosBrasil.linhas do
		for j, t in linha.trechos do
			s[t.id] = Economia.situacaoTrecho(estado, DadosBrasil, i, j)
		end
	end
	return s
end

-- Trens de cada linha para o mapa animar: a trilha são os trechos construídos, em ordem.
local function trensDoMapa(estado: any): { any }
	local lista = {}
	local rede = Economia.rede(estado, DadosBrasil)
	for _, linha in DadosBrasil.linhas do
		local pontos: { Vector2 } = {}
		for _, t in linha.trechos do
			if estado.trechos[t.id] then
				if #pontos == 0 then
					table.insert(pontos, DadosBrasil.estacoes[t.de].pos)
				end
				table.insert(pontos, DadosBrasil.estacoes[t.para].pos)
			end
		end
		if #pontos >= 2 then
			local situacao = if Economia.trensFaltando(estado, DadosBrasil, linha, rede) > 0 then "lotado"
				elseif Economia.trensSobrando(estado, DadosBrasil, linha, rede) > 0 then "vazio"
				else "normal"
			table.insert(lista, { id = linha.id, pontos = pontos, n = estado.trens[linha.id] or 0, situacao = situacao })
		end
	end
	return lista
end

local function aplicarNaTela(estado: any)
	mapa:definirSituacao(situacoes(estado))
	mapa:definirCargas(Economia.conectadasAoPorto(estado, DadosBrasil))
	mapa:definirNiveis(estado.estacoes or {})
	mapa:definirTrens(trensDoMapa(estado))
	ui:atualizarEstado(estado)
	menu:atualizarEstado(estado)
	tutorial:atualizarEstado(estado)
	ficha:atualizarEstado(estado)
end

-- Novidades que o servidor manda uma vez só (contrato, medalha, nível, linha completa): viram avisos em fila.
local function avisarEventos(estado: any)
	local simbolo = DadosBrasil.simbolo
	for _, ev in estado.eventos or {} do
		if ev.tipo == "contrato" and ev.cumprido then
			ui:enfileirar(`{Emojis.contratos} Contrato cumprido! Prêmio: {Economia.formatar(ev.premio, simbolo)}`, 5)
		elseif ev.tipo == "contrato" then
			ui:enfileirar(`{Emojis.relogio} O prazo do contrato acabou. Há ofertas novas na aba Contratos.`, 5)
		elseif ev.tipo == "medalha" then
			local m = Metas.acharMedalha(ev.id)
			if m then
				ui:enfileirar(`{Emojis.medalha} Medalha: {m.nome}! +{m.xp} XP`, 4)
			end
		elseif ev.tipo == "nivel" then
			ui:enfileirar(`{Emojis.nivel} Nível {ev.nivel}: {ev.titulo}! Bônus de receita: +{ev.nivel - 1}%`, 5)
		elseif ev.tipo == "linha" then
			ui:enfileirar(`{Emojis.confirmar} Linha completa: {ev.nome}!`, 4)
		end
	end
end

local function agir(tipo: string, args: any)
	local resposta = remoteAcao:InvokeServer(tipo, args)
	if resposta and not resposta.ok then
		ui:avisar(`{Emojis.alerta} {resposta.erro or "Não deu certo."}`)
	elseif resposta and resposta.ok then
		if resposta.mensagem then
			ui:avisar(`{Emojis.confirmar} {resposta.mensagem}`, 3)
		elseif tipo == "acelerar" then
			ui:avisar(`{Emojis.velocidade} Estudo concluído na hora!`, 2)
		elseif tipo == "melhorarEstacao" then
			ui:avisar(`{Emojis.melhorar} Estação melhorada!`, 2)
		elseif tipo == "trem" then
			ui:avisar(`{Emojis.trens} Trem comprado!`, 2)
		elseif tipo == "aceitarContrato" or tipo == "trocarOfertas" or tipo == "tutorial" then
			-- sem aviso próprio: a tela já mostra o que mudou
		elseif tipo == "venderTrem" then
			ui:avisar(`{Emojis.dinheiro} Trem vendido.`, 2)
		elseif tipo == "construir" then
			ui:avisar(`{Emojis.construir} Trecho construído!`, 2)
			-- se o trecho novo fez a linha precisar de mais trens, avisa
			task.delay(0.4, function()
				local linha = Economia.acharTrecho(DadosBrasil, args.trecho)
				local estado = ui.estado
				local faltando = if linha and estado then Economia.trensFaltando(estado, DadosBrasil, linha) else 0
				if linha and faltando > 0 then
					ui:avisar(`{Emojis.trens} A linha {linha.nome} cresceu: faltam {faltando} trem(ns) para levar todos os passageiros.`, 5)
				end
			end)
		end
	end
end

-- Monta (ou remonta, ao trocar de era) o mapa e a interface com o visual da era.
local function montar(eraId: string)
	local era = Theme.PorId[eraId] or Theme.PorId.vapor
	local idMar = era.marPadrao and (Assets.Ids :: any)[era.marPadrao]
	era.marTextura = if idMar and idMar ~= "rbxassetid://0" then idMar else nil

	local camera: { zoom: number, pan: Vector2 }? = nil
	local selecionado: string? = nil
	local cidadeAberta: string? = nil
	if mapa then
		camera = { zoom = mapa.zoom, pan = mapa.pan }
		selecionado = ui.trechoAberto
		cidadeAberta = ficha.aberta
		ficha:destruir()
		for _, c in conexoesTela do
			c:Disconnect()
		end
		table.clear(conexoesTela)
		ui:destruir()
		menu:destruir()
		tutorial:destruir()
		mapa:destruir()
	end

	mapa = MapaView.new(tela, Mapas.brasil, DadosBrasil, era)
	ui = Interface.new(telaUI, era, DadosBrasil)
	ui.eras = Theme.PorId
	menu = Menu.new(telaUI, era, DadosBrasil)
	tutorial = Tutorial.new(telaUI, era, DadosBrasil)
	ficha = Ficha.new(telaUI, era, DadosBrasil)
	menu.ajustes = ajustesSalvos
	for chave, valor in ajustesSalvos do
		mapa:definirAjuste(chave, valor)
	end
	eraAtual = eraId

	table.insert(conexoesTela, menu.aoAgir.Event:Connect(agir))
	table.insert(conexoesTela, menu.aoConcluirProjeto.Event:Connect(function(p: any)
		ui:avisar(`{Emojis.gabinete} Projeto aprovado: {p.nome}! A linha já pode ser construída.`, 6)
	end))
	-- o painel do menu acompanha a altura do caixa (que cresce quando aparece o botão da era)
	local function reposicionar()
		-- posição relativa à tela do jogo (as posições absolutas vêm deslocadas pela barra do Roblox)
		local origem = (ui.hud.Parent :: any).AbsolutePosition.Y
		menu:posicionarAbaixoDe(ui.hud.AbsolutePosition.Y - origem + ui.hud.AbsoluteSize.Y)
	end
	table.insert(conexoesTela, ui.hud:GetPropertyChangedSignal("AbsoluteSize"):Connect(reposicionar))
	task.defer(reposicionar)
	table.insert(conexoesTela, menu.aoZoom.Event:Connect(function(fator: number)
		local centro = mapa.raiz.AbsolutePosition + mapa.raiz.AbsoluteSize / 2
		mapa.interagiu = true
		mapa:zoomEm(mapa.zoom * fator, centro)
	end))
	table.insert(conexoesTela, menu.aoAjuste.Event:Connect(function(chave: string, valor: boolean)
		if chave == "reenquadrar" then
			mapa:focar(minimo, maximo, 80)
		else
			ajustesSalvos[chave] = valor
			mapa:definirAjuste(chave, valor)
		end
	end))
	-- enquadra a linha e abre o próximo trecho a construir (ou o primeiro)
	local function focarLinha(linhaId: string)
		local mn = Vector2.new(math.huge, math.huge)
		local mx = Vector2.new(-math.huge, -math.huge)
		local alvo: string? = nil
		for i, linha in DadosBrasil.linhas do
			if linha.id == linhaId then
				for j, t in linha.trechos do
					for _, id in { t.de, t.para } do
						local p = DadosBrasil.estacoes[id].pos
						mn, mx = mn:Min(p), mx:Max(p)
					end
					if not alvo and ultimoEstado and Economia.situacaoTrecho(ultimoEstado, DadosBrasil, i, j) ~= "construido" then
						alvo = t.id
					end
				end
				alvo = alvo or linha.trechos[1].id
			end
		end
		if alvo then
			ficha:fechar()
			mapa.interagiu = true
			mapa:focar(mn, mx, 140)
			mapa:selecionar(alvo)
			ui:abrir(alvo)
		end
	end
	-- a ficha da cidade e o painel do trecho ocupam o mesmo canto: só um aberto por vez
	local function abrirCidade(id: string)
		ui:fechar()
		mapa:selecionar(nil)
		ficha:abrir(id)
	end
	table.insert(conexoesTela, ficha.aoAgir.Event:Connect(agir))
	table.insert(conexoesTela, ficha.aoFocarLinha.Event:Connect(focarLinha))
	table.insert(conexoesTela, menu.aoFocarLinha.Event:Connect(focarLinha))
	table.insert(conexoesTela, tutorial.aoAgir.Event:Connect(agir))
	table.insert(conexoesTela, tutorial.aoAcao.Event:Connect(function(acao: string, alvo: string?)
		if acao == "linha" and alvo then
			focarLinha(alvo)
		elseif acao == "estacao" and alvo then
			local p = DadosBrasil.estacoes[alvo].pos
			local folga = Vector2.new(60, 60)
			mapa.interagiu = true
			mapa:focar(p - folga, p + folga, 140)
			abrirCidade(alvo)
		elseif acao == "aba" and alvo then
			menu:abrirAba(alvo)
		end
	end))

	table.insert(conexoesTela, mapa.aoTocar.Event:Connect(function(pontoMapa: Vector2)
		-- estação tem prioridade sobre trecho quando o toque cai em cima dela
		local estacao = mapa:estacaoProxima(pontoMapa, 14)
		if estacao then
			abrirCidade(estacao)
			return
		end
		ficha:fechar()
		local id = mapa:trechoProximo(pontoMapa, 22)
		mapa:selecionar(id)
		if id then
			ui:abrir(id)
		else
			ui:fechar()
		end
	end))
	table.insert(conexoesTela, ui.aoFechar.Event:Connect(function()
		mapa:selecionar(nil)
	end))
	table.insert(conexoesTela, ui.aoAgir.Event:Connect(agir))

	task.spawn(function()
		while mapa.raiz.AbsoluteSize.X <= 0 do
			task.wait()
		end
		mapa:_atualizarZoomMin()
		if camera then
			mapa.interagiu = true
			mapa.zoom = -1
			mapa:definirCamera(camera.zoom, camera.pan)
		else
			mapa:focar(minimo, maximo, 80)
		end
	end)

	if ultimoEstado then
		aplicarNaTela(ultimoEstado)
		if selecionado then
			mapa:selecionar(selecionado)
			ui:abrir(selecionado)
		elseif cidadeAberta then
			ficha:abrir(cidadeAberta)
		end
	end
end

-- ---------------------------------------------------------------- estado vindo do servidor

local function aplicarEstado(estado: any)
	if not estado then
		return
	end
	ultimoEstado = estado
	if estado.era ~= eraAtual then
		local trocou = eraAtual ~= nil
		montar(estado.era)
		if trocou then
			local era = Theme.PorId[estado.era]
			local emoji = (Emojis :: any)["era_" .. estado.era] or Emojis.era_diesel
			ui:enfileirar(`{emoji} Bem-vindo à {era and era.nome or "nova era"}! A receita dobrou e cada trem leva o dobro de passageiros.`, 6)
		end
		avisarEventos(estado)
		return
	end
	aplicarNaTela(estado)
	avisarEventos(estado)
end

montar("vapor")
remoteEstado.OnClientEvent:Connect(aplicarEstado)
task.spawn(function()
	aplicarEstado(remotePedirEstado:InvokeServer())
end)

print(`[Ferrovia] Cliente iniciado: mapa do Brasil com {#DadosBrasil.linhas} linhas.`)
