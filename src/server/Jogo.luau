--!strict
-- Jogo (servidor): sessões dos jogadores, ações de compra, renda por segundo, ganho offline e save.
-- O servidor é a única autoridade sobre dinheiro; o cliente só pede ações e mostra o estado.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Economia = require(Shared:WaitForChild("Economia"))
local DadosBrasil = require(Shared:WaitForChild("Dados"):WaitForChild("Brasil"))
local Persistencia = require(script.Parent:WaitForChild("Persistencia"))

type EstadoMapa = Economia.EstadoMapa

local MAPAS: { [string]: any } = { brasil = DadosBrasil }
local MAPA_PADRAO = "brasil"
local VERSAO_SAVE = 1
local AUTOSAVE_SEGUNDOS = 60

type Sessao = {
	jogador: Player,
	mapas: { [string]: EstadoMapa },
	mapaAtual: string,
	carregado: boolean,
	podeSalvar: boolean,
	ultimaAcao: number,
	ganhoOffline: number,
}

local sessoes: { [Player]: Sessao } = {}

-- ---------------------------------------------------------------- remotes

local pastaRemotes = Instance.new("Folder")
pastaRemotes.Name = "Remotes"
local remoteEstado = Instance.new("RemoteEvent")
remoteEstado.Name = "Estado"
remoteEstado.Parent = pastaRemotes
local remoteAcao = Instance.new("RemoteFunction")
remoteAcao.Name = "Acao"
remoteAcao.Parent = pastaRemotes
local remotePedirEstado = Instance.new("RemoteFunction")
remotePedirEstado.Name = "PedirEstado"
remotePedirEstado.Parent = pastaRemotes
pastaRemotes.Parent = ReplicatedStorage

-- ---------------------------------------------------------------- estado

local function sanear(salvo: any): EstadoMapa
	local e = Economia.estadoNovo()
	if type(salvo) ~= "table" then
		return e
	end
	if type(salvo.dinheiro) == "number" and salvo.dinheiro == salvo.dinheiro then -- descarta NaN
		e.dinheiro = math.max(0, salvo.dinheiro)
	end
	if type(salvo.trechos) == "table" then
		for k, v in salvo.trechos do
			if type(k) == "string" and type(v) == "string" then
				e.trechos[k] = v
			end
		end
	end
	if type(salvo.trens) == "table" then
		for k, v in salvo.trens do
			if type(k) == "string" and type(v) == "number" then
				e.trens[k] = math.max(0, math.floor(v))
			end
		end
	end
	if type(salvo.era) == "string" then
		for _, era in Economia.ERAS do
			if era.id == salvo.era then
				e.era = salvo.era
			end
		end
	end
	if type(salvo.ultimoTick) == "number" then
		e.ultimoTick = salvo.ultimoTick
	end
	return e
end

local function pacoteEstado(s: Sessao): any
	local dados = MAPAS[s.mapaAtual]
	local e = s.mapas[s.mapaAtual]
	return {
		mapa = s.mapaAtual,
		dinheiro = e.dinheiro,
		renda = Economia.rendaTotal(e, dados),
		trechos = e.trechos,
		trens = e.trens,
		era = e.era,
		ganhoOffline = s.ganhoOffline,
		salvando = s.podeSalvar,
	}
end

local function enviarEstado(s: Sessao)
	if s.carregado then
		remoteEstado:FireClient(s.jogador, pacoteEstado(s))
		s.ganhoOffline = 0 -- só avisa uma vez
	end
end

local function salvar(s: Sessao)
	if not s.carregado or not s.podeSalvar then
		return
	end
	for _, e in s.mapas do
		e.ultimoTick = os.time()
	end
	Persistencia.salvar(s.jogador.UserId, { versao = VERSAO_SAVE, mapas = s.mapas })
end

-- ---------------------------------------------------------------- ações

local Acoes: { [string]: (Sessao, any) -> (boolean, string?) } = {}

function Acoes.construir(s: Sessao, args: any): (boolean, string?)
	if type(args) ~= "table" or type(args.trecho) ~= "string" then
		return false, "Pedido inválido."
	end
	local dados = MAPAS[s.mapaAtual]
	local e = s.mapas[s.mapaAtual]
	local linha, iLinha, trecho, iTrecho = Economia.acharTrecho(dados, args.trecho)
	if not trecho then
		return false, "Trecho desconhecido."
	end
	local situacao = Economia.situacaoTrecho(e, dados, iLinha, iTrecho)
	if situacao == "construido" then
		return false, "Esse trecho já foi construído."
	elseif situacao == "bloqueado" then
		return false, "Esse trecho ainda não está liberado."
	end
	local alternativa = "padrao"
	if trecho.alternativas then
		alternativa = if type(args.alternativa) == "string" then args.alternativa else trecho.alternativas[1].id
	end
	local custo = Economia.opcaoTrecho(trecho, alternativa).custo
	if e.dinheiro < custo then
		return false, "Dinheiro insuficiente."
	end
	e.dinheiro -= custo
	e.trechos[trecho.id] = alternativa
	if (e.trens[linha.id] or 0) == 0 then
		e.trens[linha.id] = 1 -- primeiro trem da linha é grátis
	end
	return true, nil
end

function Acoes.trem(s: Sessao, args: any): (boolean, string?)
	if type(args) ~= "table" or type(args.linha) ~= "string" then
		return false, "Pedido inválido."
	end
	local dados = MAPAS[s.mapaAtual]
	local e = s.mapas[s.mapaAtual]
	local linha = nil
	for _, l in dados.linhas do
		if l.id == args.linha then
			linha = l
		end
	end
	if not linha then
		return false, "Linha desconhecida."
	end
	if Economia.trechosConstruidos(e, linha) == 0 then
		return false, "Construa um trecho dessa linha primeiro."
	end
	if not Economia.podeComprarTrem(e, linha) then
		return false, "Frota completa: esta linha já tem todos os trens de que precisa."
	end
	local custo = Economia.custoTrem(e, linha)
	if e.dinheiro < custo then
		return false, "Dinheiro insuficiente."
	end
	e.dinheiro -= custo
	e.trens[linha.id] = (e.trens[linha.id] or 0) + 1
	return true, nil
end

function Acoes.modernizar(s: Sessao, _args: any): (boolean, string?)
	local dados = MAPAS[s.mapaAtual]
	local e = s.mapas[s.mapaAtual]
	local proxima, liberada = Economia.proximaEra(e, dados)
	if not proxima then
		return false, "Você já está na era mais moderna."
	end
	if not liberada then
		return false, `Complete {proxima.linhasCompletas} linhas para liberar a próxima era.`
	end
	if e.dinheiro < proxima.custo then
		return false, "Dinheiro insuficiente."
	end
	e.dinheiro -= proxima.custo
	e.era = proxima.id
	return true, nil
end

remoteAcao.OnServerInvoke = function(jogador: Player, tipo: any, args: any)
	local s = sessoes[jogador]
	if not s or not s.carregado then
		return { ok = false, erro = "Carregando seus dados…" }
	end
	local agora = os.clock()
	if agora - s.ultimaAcao < 0.1 then
		return { ok = false, erro = "Devagar!" }
	end
	s.ultimaAcao = agora
	local acao = if type(tipo) == "string" then Acoes[tipo] else nil
	if not acao then
		return { ok = false, erro = "Ação desconhecida." }
	end
	local ok, erro = acao(s, args)
	if ok then
		enviarEstado(s)
	end
	return { ok = ok, erro = erro }
end

remotePedirEstado.OnServerInvoke = function(jogador: Player)
	local s = sessoes[jogador]
	while s and not s.carregado do
		task.wait(0.1)
	end
	if not s then
		return nil
	end
	local pacote = pacoteEstado(s)
	s.ganhoOffline = 0
	return pacote
end

-- ---------------------------------------------------------------- sessões

local function aoEntrar(jogador: Player)
	local s: Sessao = {
		jogador = jogador,
		mapas = {},
		mapaAtual = MAPA_PADRAO,
		carregado = false,
		podeSalvar = false,
		ultimaAcao = 0,
		ganhoOffline = 0,
	}
	sessoes[jogador] = s

	local salvo, ok = Persistencia.carregar(jogador.UserId)
	if not ok then
		-- falhou de verdade (não é "jogador novo"): não salvar por cima do progresso real
		warn(`[Ferrovia] Não consegui carregar {jogador.Name}; esta sessão não vai salvar.`)
	end
	s.podeSalvar = ok and Persistencia.disponivel()

	for id, dados in MAPAS do
		local estadoSalvo = if type(salvo) == "table" and type(salvo.mapas) == "table" then salvo.mapas[id] else nil
		local e = sanear(estadoSalvo)
		Economia.ajustarFrota(e, dados)
		if estadoSalvo then
			local decorrido = math.clamp(os.time() - e.ultimoTick, 0, Economia.OFFLINE_MAX_SEGUNDOS)
			local ganho = Economia.rendaTotal(e, dados) * decorrido
			e.dinheiro += ganho
			if id == s.mapaAtual then
				s.ganhoOffline = ganho
			end
		end
		e.ultimoTick = os.time()
		s.mapas[id] = e
	end

	if sessoes[jogador] == s then
		s.carregado = true
		enviarEstado(s)
	end
end

local function aoSair(jogador: Player)
	local s = sessoes[jogador]
	if s then
		salvar(s)
		sessoes[jogador] = nil
	end
end

Players.PlayerAdded:Connect(aoEntrar)
Players.PlayerRemoving:Connect(aoSair)
for _, j in Players:GetPlayers() do
	task.spawn(aoEntrar, j)
end

game:BindToClose(function()
	local pendentes = 0
	for _, s in sessoes do
		pendentes += 1
		task.spawn(function()
			salvar(s)
			pendentes -= 1
		end)
	end
	local limite = os.clock() + 25
	while pendentes > 0 and os.clock() < limite do
		task.wait(0.1)
	end
end)

-- ---------------------------------------------------------------- atalhos de teste (só no Studio)

if RunService:IsStudio() then
	-- Uso (barra de comandos, contexto Server):
	--   game.ServerStorage.FerroviaDebug:Invoke("dinheiro", 100000)
	--   game.ServerStorage.FerroviaDebug:Invoke("zerar")
	local debug = Instance.new("BindableFunction")
	debug.Name = "FerroviaDebug"
	debug.OnInvoke = function(comando: string, valor: any)
		for _, s in sessoes do
			local e = s.mapas[s.mapaAtual]
			if comando == "dinheiro" then
				e.dinheiro += tonumber(valor) or 0
			elseif comando == "zerar" then
				s.mapas[s.mapaAtual] = Economia.estadoNovo()
			end
			enviarEstado(s)
		end
		return "ok"
	end
	debug.Parent = ServerStorage
end

-- ---------------------------------------------------------------- renda e autosave

task.spawn(function()
	local ultimo = os.clock()
	local proximoSave = os.clock() + AUTOSAVE_SEGUNDOS
	while true do
		task.wait(1)
		local agora = os.clock()
		local dt = agora - ultimo
		ultimo = agora
		for _, s in sessoes do
			if s.carregado then
				local e = s.mapas[s.mapaAtual]
				e.dinheiro += Economia.rendaTotal(e, MAPAS[s.mapaAtual]) * dt
				enviarEstado(s)
			end
		end
		if agora >= proximoSave then
			proximoSave = agora + AUTOSAVE_SEGUNDOS
			for _, s in sessoes do
				task.spawn(salvar, s)
			end
		end
	end
end)

return {}
