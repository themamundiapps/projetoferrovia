--!strict
-- Jogo (servidor): sessões dos jogadores, ações de compra, renda por segundo, ganho offline, metas e save.
-- O servidor é a única autoridade sobre dinheiro; o cliente só pede ações e mostra o estado.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local TextService = game:GetService("TextService")
local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Economia = require(Shared:WaitForChild("Economia"))
local Idioma = require(Shared:WaitForChild("Idioma"))
local L = Idioma.L
local Metas = require(Shared:WaitForChild("Metas"))
local Jornal = require(Shared:WaitForChild("Jornal"))
local Tarifas = require(Shared:WaitForChild("Tarifas"))
local Decisoes = require(Shared:WaitForChild("Decisoes"))
local Loja = require(Shared:WaitForChild("Loja"))
local DadosBrasil = require(Shared:WaitForChild("Dados"):WaitForChild("Brasil"))
local DadosEUA = require(Shared:WaitForChild("Dados"):WaitForChild("EUA"))
local DadosEuropa = require(Shared:WaitForChild("Dados"):WaitForChild("Europa"))
local Persistencia = require(script.Parent:WaitForChild("Persistencia"))

type EstadoMapa = Economia.EstadoMapa

-- Cada mapa é uma companhia separada no mesmo save (dinheiro, trechos, era, XP...). Só o mapa aberto
-- rende; ao trocar, o mapa que fica não acumula o tempo em que o jogador estava no outro.
local MAPAS: { [string]: any } = { brasil = DadosBrasil, eua = DadosEUA, europa = DadosEuropa }
local MAPA_PADRAO = "brasil"
-- v2 (25/11/2026): reset geral antes do lançamento (o save antigo é da v1).
local VERSAO_SAVE = 2
local AUTOSAVE_SEGUNDOS = 60

type Sessao = {
	jogador: Player,
	mapas: { [string]: EstadoMapa },
	mapaAtual: string,
	carregado: boolean,
	podeSalvar: boolean,
	ultimaAcao: number,
	ultimoNome: number, -- os.clock() da última troca de nome da companhia
	proximaNoticia: number, -- os.time() da próxima notícia do Jornal (0 = ainda não marcado)
	proximaDecisao: number, -- os.time() da próxima decisão (0 = ainda não marcado)
	ganhoOffline: number,
	eventos: { any }, -- novidades para o cliente avisar (contrato cumprido, medalha, nível...), enviadas uma vez
	rng: Random,
	idioma: string, -- "pt" ou "en": as mensagens para este jogador saem neste idioma
	loja: SaveLoja, -- compras (vale para todos os mapas)
	proximoGerente: number, -- os.clock() da próxima rodada do Gerente Automático
	pontosRanking: number, -- última pontuação enviada ao ranking global
}

-- Parte do save com as compras. Os passes ficam guardados só como reserva (se a consulta ao Roblox
-- falhar ao entrar); quem manda é UserOwnsGamePassAsync.
type SaveLoja = {
	passes: { [string]: boolean },
	impulsoAte: number,
	estudosGuardados: number,
	gerenteLigado: boolean,
	recibos: { [string]: number }, -- PurchaseId -> os.time(): compras já entregues (nunca entregar duas vezes)
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
-- conquista de outro jogador do servidor (nome, id da medalha): aparece embaixo da barra de cima
local remoteConquista = Instance.new("RemoteEvent")
remoteConquista.Name = "Conquista"
remoteConquista.Parent = pastaRemotes
pastaRemotes.Parent = ReplicatedStorage

-- ---------------------------------------------------------------- estado

local function numero(v: any): boolean
	return type(v) == "number" and v == v -- descarta NaN
end

-- Contrato salvo: só aceita se todos os campos estiverem no lugar.
local function sanearContrato(c: any): any?
	if type(c) ~= "table" or type(c.tipo) ~= "string" then
		return nil
	end
	for _, campo in { "id", "meta", "prazo", "premio", "xp", "progresso", "decorrido" } do
		if not numero(c[campo]) then
			return nil
		end
	end
	return {
		id = c.id,
		tipo = c.tipo,
		alvo = if type(c.alvo) == "string" then c.alvo else nil,
		dificuldade = if type(c.dificuldade) == "string" then c.dificuldade else "facil",
		meta = c.meta,
		prazo = c.prazo,
		premio = c.premio,
		xp = c.xp,
		progresso = c.progresso,
		decorrido = c.decorrido,
	}
end

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
	if type(salvo.estacoes) == "table" then
		for k, v in salvo.estacoes do
			if type(k) == "string" and type(v) == "number" then
				e.estacoes[k] = math.clamp(math.floor(v), 0, #Economia.NIVEIS_ESTACAO)
			end
		end
	end
	if type(salvo.projetos) == "table" then
		for k, v in salvo.projetos do
			-- só projetos que existem em algum mapa; o valor é o horário em que a pesquisa termina
			if type(k) == "string" and type(v) == "number" and v == v then
				e.projetos[k] = v
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
	-- metas
	if numero(salvo.xp) then
		e.xp = math.max(0, salvo.xp)
	end
	for _, campo in { "medalhas", "contadores" } do
		if type(salvo[campo]) == "table" then
			for k, v in salvo[campo] do
				if type(k) == "string" and numero(v) then
					(e :: any)[campo][k] = v
				end
			end
		end
	end
	e.contrato = sanearContrato(salvo.contrato)
	if type(salvo.ofertas) == "table" then
		for i = 1, 3 do
			local c = sanearContrato(salvo.ofertas[i])
			if c then
				table.insert(e.ofertas, c)
			end
		end
	end
	if numero(salvo.ofertasEm) then
		e.ofertasEm = salvo.ofertasEm
	end
	if type(salvo.missoes) == "table" and numero(salvo.missoes.dia) and type(salvo.missoes.lista) == "table" then
		e.missoes.dia = salvo.missoes.dia
		for i = 1, 3 do
			local m = salvo.missoes.lista[i]
			if type(m) == "table" and type(m.tipo) == "string" and numero(m.meta) and numero(m.progresso) and numero(m.premio) and numero(m.xp) then
				table.insert(e.missoes.lista, {
					tipo = m.tipo,
					meta = m.meta,
					progresso = m.progresso,
					premio = m.premio,
					xp = m.xp,
					resgatada = m.resgatada == true,
				})
			end
		end
	end
	e.tutorial = salvo.tutorial == true
	e.tarifas = Tarifas.sanear(salvo.tarifas)
	if type(salvo.nomeCompanhia) == "string" and #salvo.nomeCompanhia <= 64 then
		e.nomeCompanhia = salvo.nomeCompanhia
	end
	-- (o banco saiu em 22/11: empréstimos de saves antigos são perdoados, por isso salvo.emprestimo é ignorado)
	-- decisões: pendente só se existir no catálogo; efeitos com números dentro dos limites
	local dc = salvo.decisoes
	if type(dc) == "table" then
		local p = dc.pendente
		if type(p) == "table" and type(p.id) == "string" and Decisoes.acharDecisao(p.id) then
			e.decisoes.pendente = {
				id = p.id,
				tipo = if type(p.tipo) == "string" then p.tipo else "",
				alvo = if type(p.alvo) == "string" then p.alvo else nil,
				em = if numero(p.em) then p.em else os.time(),
			}
		end
		if type(dc.efeitos) == "table" then
			for i = 1, 8 do
				local ev = dc.efeitos[i]
				if type(ev) == "table" and type(ev.id) == "string" and type(ev.tipo) == "string" and numero(ev.mult)
					and ev.mult >= 0.3 and ev.mult <= 2 and numero(ev.fim) and numero(ev.inicio) and ev.fim > os.time()
					and ev.fim - ev.inicio <= 30 * 60 then
					table.insert(e.decisoes.efeitos, {
						id = ev.id,
						tipo = ev.tipo,
						alvo = if type(ev.alvo) == "string" then ev.alvo else nil,
						mult = ev.mult,
						inicio = ev.inicio,
						fim = ev.fim,
					})
				end
			end
		end
		if type(dc.vistas) == "table" then
			for id, v in dc.vistas do
				if type(id) == "string" and v == true and Decisoes.acharDecisao(id) then
					e.decisoes.vistas[id] = true
				end
			end
		end
		if type(dc.historico) == "table" then
			for i = 1, Decisoes.MAX_HISTORICO do
				local h = dc.historico[i]
				if type(h) == "table" and type(h.id) == "string" and Decisoes.acharDecisao(h.id) and numero(h.opcao) and numero(h.em) then
					table.insert(e.decisoes.historico, { id = h.id, opcao = h.opcao, em = h.em, sorte = if type(h.sorte) == "boolean" then h.sorte else nil })
				end
			end
		end
	end
	-- jornal: o efeito de cada evento vem do catálogo, não do save
	local j = salvo.jornal
	if type(j) == "table" then
		if type(j.ativos) == "table" then
			for i = 1, Jornal.MAX_ATIVOS do
				local ev = j.ativos[i]
				local def = if type(ev) == "table" and type(ev.id) == "string" then Jornal.acharEvento(ev.id) else nil
				if def and numero(ev.fim) and numero(ev.inicio) and ev.fim > os.time() then
					table.insert(e.jornal.ativos, {
						id = def.id,
						tipo = def.tipo,
						alvo = if type(ev.alvo) == "string" then ev.alvo else nil,
						mult = def.mult,
						inicio = ev.inicio,
						fim = math.min(ev.fim, ev.inicio + def.duracao),
					})
				end
			end
		end
		if type(j.edicoes) == "table" then
			for i = 1, Jornal.MAX_EDICOES do
				local ed = j.edicoes[i]
				if type(ed) == "table" and type(ed.id) == "string" and Jornal.acharEvento(ed.id) and numero(ed.em) then
					table.insert(e.jornal.edicoes, { id = ed.id, alvo = if type(ed.alvo) == "string" then ed.alvo else nil, em = ed.em })
				end
			end
		end
	end
	return e
end

local function pacoteEstado(s: Sessao, renda: number?): any
	local dados = MAPAS[s.mapaAtual]
	local e = s.mapas[s.mapaAtual]
	-- linhas completas em cada mapa já jogado (o menu inicial marca os mapas completos)
	local progressoMapas = {}
	for id, em in s.mapas do
		if MAPAS[id] then
			progressoMapas[id] = { linhas = Economia.linhasCompletas(em, MAPAS[id]), total = #MAPAS[id].linhas }
		end
	end
	return {
		mapa = s.mapaAtual,
		progressoMapas = progressoMapas,
		dinheiro = e.dinheiro,
		renda = renda or Economia.rendaTotal(e, dados),
		xp = e.xp,
		medalhas = e.medalhas,
		contadores = e.contadores,
		contrato = e.contrato,
		ofertas = e.ofertas,
		ofertasEm = e.ofertasEm,
		missoes = e.missoes,
		loja = e.loja,
		tutorial = e.tutorial,
		nomeCompanhia = e.nomeCompanhia,
		decisoes = e.decisoes,
		tarifas = e.tarifas,
		jornal = e.jornal,
		eventos = s.eventos,
		trechos = e.trechos,
		trens = e.trens,
		era = e.era,
		estacoes = e.estacoes,
		projetos = e.projetos,
		agora = os.time(),
		ganhoOffline = s.ganhoOffline,
		salvando = s.podeSalvar,
	}
end

-- Placar do servidor (lista de jogadores do Roblox, no canto de cima): nível e renda por segundo.
-- A lista ordena pelo primeiro valor (o nível); a renda vai como texto formatado.
local function atualizarPlacar(s: Sessao, renda: number?)
	local jogador = s.jogador
	local pasta = jogador:FindFirstChild("leaderstats")
	if not pasta then
		pasta = Instance.new("Folder")
		pasta.Name = "leaderstats"
		local nivel = Instance.new("IntValue")
		nivel.Name = "Nível"
		nivel.Parent = pasta
		local rendaTxt = Instance.new("StringValue")
		rendaTxt.Name = "Renda/s"
		rendaTxt.Parent = pasta
		pasta.Parent = jogador
	end
	local e = s.mapas[s.mapaAtual]
	if not e then
		return
	end
	local nivel = pasta:FindFirstChild("Nível") :: IntValue?
	if nivel then
		nivel.Value = (Economia.nivel(e))
	end
	-- para o ranking visual do cliente (Placar). Ranking justo: nível e linhas completas, que vêm de
	-- jogar; dinheiro não entra (dá para comprar na loja).
	jogador:SetAttribute("Nivel", (Economia.nivel(e)))
	jogador:SetAttribute("Linhas", Economia.linhasCompletas(e, MAPAS[s.mapaAtual]))
	jogador:SetAttribute("Companhia", e.nomeCompanhia or "")
	local rendaTxt = pasta:FindFirstChild("Renda/s") :: StringValue?
	if rendaTxt and renda then
		local dados = MAPAS[s.mapaAtual]
		rendaTxt.Value = Economia.formatar(math.max(0, renda), dados and dados.simbolo)
	end
end

local function enviarEstado(s: Sessao, renda: number?)
	if s.carregado then
		remoteEstado:FireClient(s.jogador, pacoteEstado(s, renda))
		s.ganhoOffline = 0 -- só avisa uma vez
		s.eventos = {}
	end
end

-- ---------------------------------------------------------------- metas (XP, contratos, missões, medalhas)

local function ganharXp(s: Sessao, e: EstadoMapa, xp: number)
	local antes = Economia.nivel(e)
	e.xp += xp
	local depois = Economia.nivel(e)
	if depois > antes then
		table.insert(s.eventos, { tipo = "nivel", nivel = depois, titulo = Economia.tituloNivel(depois, e.era, s.idioma) })
	end
end

-- Põe um evento em vigor, guarda a manchete nas edições e avisa o cliente.
local function publicar(s: Sessao, e: EstadoMapa, ev: any)
	table.insert(e.jornal.ativos, ev)
	table.insert(e.jornal.edicoes, 1, { id = ev.id, alvo = ev.alvo, em = ev.inicio })
	while #e.jornal.edicoes > Jornal.MAX_EDICOES do
		table.remove(e.jornal.edicoes)
	end
	table.insert(s.eventos, { tipo = "jornal", id = ev.id, alvo = ev.alvo, tipoEfeito = ev.tipo })
end

local function encerrarContrato(s: Sessao, e: EstadoMapa, cumprido: boolean)
	local c = e.contrato
	if not c then
		return
	end
	e.contrato = nil
	if cumprido then
		e.dinheiro += c.premio
		Metas.contar(e, "contratos", 1)
		ganharXp(s, e, c.xp)
	end
	table.insert(s.eventos, { tipo = "contrato", cumprido = cumprido, premio = c.premio })
end

-- Missões do dia, ofertas de contrato e medalhas: mantém tudo em dia.
local function atualizarMetas(s: Sessao, e: EstadoMapa, dados: any, ctx: Metas.Contexto)
	local dia = Metas.diaAtual()
	if e.missoes.dia ~= dia then
		e.missoes = { dia = dia, lista = Metas.gerarMissoes(e, dados, ctx, s.rng) }
	end
	if not e.contrato and (#e.ofertas == 0 or os.time() - e.ofertasEm >= Metas.VALIDADE_OFERTAS_SEGUNDOS) then
		e.ofertas = Metas.gerarOfertas(e, dados, ctx, s.rng)
		if #e.ofertas > 0 then
			e.ofertasEm = os.time()
		end
	end
	-- jornal: tira os eventos vencidos e, de tempos em tempos, publica uma notícia nova
	local agora = os.time()
	local vigentes = {}
	for _, ev in e.jornal.ativos do
		if ev.fim > agora then
			table.insert(vigentes, ev)
		end
	end
	e.jornal.ativos = vigentes
	local trechos = 0
	for _ in e.trechos do
		trechos += 1
	end
	if trechos >= Jornal.TRECHOS_MINIMOS then
		if s.proximaNoticia == 0 then
			s.proximaNoticia = agora + Jornal.PRIMEIRO_EVENTO
		elseif agora >= s.proximaNoticia then
			s.proximaNoticia = agora + s.rng:NextInteger(Jornal.INTERVALO_MIN, Jornal.INTERVALO_MAX)
			if #e.jornal.ativos < Jornal.MAX_ATIVOS then
				local ev = Jornal.sortear(e, dados, s.rng)
				if ev then
					publicar(s, e, ev)
				end
			end
		end
	end
	-- decisões: tira os efeitos vencidos; sem decisão pendente, de tempos em tempos chega uma nova
	local efeitos = {}
	for _, ev in e.decisoes.efeitos do
		if ev.fim > agora then
			table.insert(efeitos, ev)
		end
	end
	e.decisoes.efeitos = efeitos
	if not e.decisoes.pendente and trechos >= Decisoes.TRECHOS_MINIMOS then
		if s.proximaDecisao == 0 then
			s.proximaDecisao = agora + Decisoes.PRIMEIRA
		elseif agora >= s.proximaDecisao then
			s.proximaDecisao = agora + s.rng:NextInteger(Decisoes.INTERVALO_MIN, Decisoes.INTERVALO_MAX)
			local def, tipo, alvo = Decisoes.sortear(e, dados, e.decisoes.vistas, s.rng)
			if def then
				e.decisoes.pendente = { id = def.id, tipo = tipo, alvo = alvo, em = agora }
				table.insert(s.eventos, { tipo = "decisao", id = def.id })
			end
		end
	end
	for _, m in Metas.novasMedalhas(e, dados, ctx) do
		e.medalhas[m.id] = os.time()
		table.insert(s.eventos, { tipo = "medalha", id = m.id })
		ganharXp(s, e, m.xp)
		-- avisa os outros jogadores do servidor
		for _, outro in Players:GetPlayers() do
			if outro ~= s.jogador then
				remoteConquista:FireClient(outro, s.jogador.DisplayName, m.id)
			end
		end
	end
end

local function salvar(s: Sessao): boolean
	-- no Studio sem acesso às APIs não há DataStore: as compras de teste valem só na sessão
	local soMemoria = RunService:IsStudio() and not Persistencia.disponivel()
	if not s.carregado then
		return false
	elseif not s.podeSalvar then
		return soMemoria
	end
	-- o estado da loja dentro de cada mapa é só cópia (Economia.EstadoLoja): sai do save do mapa
	local mapas = {}
	for id, e in s.mapas do
		e.ultimoTick = os.time()
		local copia = table.clone(e) :: any
		copia.loja = nil
		mapas[id] = copia
	end
	-- recibos antigos saem (o Roblox não repete uma compra entregue há mais de alguns dias)
	local limite = os.time() - 30 * 24 * 3600
	for id, quando in s.loja.recibos do
		if quando < limite then
			s.loja.recibos[id] = nil
		end
	end
	return Persistencia.salvar(s.jogador.UserId, { versao = VERSAO_SAVE, mapas = mapas, loja = s.loja, mapaAtual = s.mapaAtual })
end

-- ---------------------------------------------------------------- loja (ver Loja.luau)

local function sanearLoja(salvo: any): SaveLoja
	local loja: SaveLoja = { passes = {}, impulsoAte = 0, estudosGuardados = 0, gerenteLigado = true, recibos = {} }
	if type(salvo) ~= "table" then
		return loja
	end
	if type(salvo.passes) == "table" then
		for _, p in Loja.PASSES do
			loja.passes[p.id] = salvo.passes[p.id] == true
		end
	end
	if numero(salvo.impulsoAte) then
		loja.impulsoAte = salvo.impulsoAte
	end
	if numero(salvo.estudosGuardados) then
		loja.estudosGuardados = math.clamp(math.floor(salvo.estudosGuardados), 0, 100)
	end
	loja.gerenteLigado = salvo.gerenteLigado ~= false
	if type(salvo.recibos) == "table" then
		for id, quando in salvo.recibos do
			if type(id) == "string" and numero(quando) then
				loja.recibos[id] = quando
			end
		end
	end
	return loja
end

-- Copia o que importa para a renda e para a interface para dentro do estado de cada mapa.
local function aplicarLoja(s: Sessao)
	local l = s.loja
	for _, e in s.mapas do
		e.loja = {
			dobro = l.passes.dobro == true,
			impulsoAte = l.impulsoAte,
			estudos = l.passes.estudos == true,
			offline = l.passes.offline == true,
			gerente = l.passes.gerente == true,
			gerenteLigado = l.gerenteLigado,
			pinturas = l.passes.pinturas == true,
			estudosGuardados = l.estudosGuardados,
		}
	end
	s.jogador:SetAttribute("Pinturas", l.passes.pinturas == true)
end

-- Ao entrar: quais passes o jogador tem (se a consulta falhar, fica o que estava no save).
local function consultarPasses(s: Sessao)
	for _, p in Loja.PASSES do
		if p.passId ~= 0 then
			local ok, tem = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(s.jogador.UserId, p.passId)
			end)
			if ok then
				s.loja.passes[p.id] = tem == true
			end
		end
	end
end

-- Entrega um produto. Devolve a mensagem para o jogador.
local function entregarProduto(s: Sessao, prod: Loja.Produto): string
	local dados = MAPAS[s.mapaAtual]
	local e = s.mapas[s.mapaAtual]
	if prod.tipo == "dinheiro" then
		local base = Economia.balanco(e, dados, true).lucro
		local valor = Loja.valorPacote(prod, base)
		e.dinheiro += valor
		return L(`{Idioma.t(prod.nome)}: + {Economia.formatar(valor, dados.simbolo)}`, `{Idioma.t(prod.nome)}: + {Economia.formatar(valor, dados.simbolo)}`)
	elseif prod.tipo == "impulso" then
		s.loja.impulsoAte = math.max(s.loja.impulsoAte, os.time()) + Loja.IMPULSO_SEGUNDOS
		local minutos = math.ceil((s.loja.impulsoAte - os.time()) / 60)
		return L(`Impulso 2x ativo por {minutos} min.`, `2x Boost active for {minutos} min.`)
	elseif prod.tipo == "estudo" then
		local atual = Economia.pesquisaAtual(e)
		if atual then
			e.projetos[atual] = os.time()
			return L("Estudo concluído!", "Study finished!")
		end
		-- comprou sem estudo em andamento (terminou no meio da compra): vale no próximo
		s.loja.estudosGuardados += 1
		return L("O estudo já tinha terminado: o próximo estudo que você começar termina na hora.", "The study had already finished: the next study you start will finish right away.")
	end
	return ""
end

-- Compras de produtos. Regra do Roblox: só responder "concedido" depois de entregar e salvar, e nunca
-- entregar duas vezes a mesma compra (o recibo fica no save).
MarketplaceService.ProcessReceipt = function(info: any): Enum.ProductPurchaseDecision
	local jogador = Players:GetPlayerByUserId(info.PlayerId)
	local s = jogador and sessoes[jogador]
	if not s or not s.carregado then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local idCompra = tostring(info.PurchaseId)
	if not s.loja.recibos[idCompra] then
		local prod = Loja.produtoPorId(info.ProductId)
		if not prod then
			warn(`[Ferrovia] Produto desconhecido: {info.ProductId}`)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local antes = Idioma.atual
		Idioma.atual = s.idioma
		local msg = entregarProduto(s, prod)
		Idioma.atual = antes
		s.loja.recibos[idCompra] = os.time()
		aplicarLoja(s)
		table.insert(s.eventos, { tipo = "compra", texto = msg })
		enviarEstado(s)
	end
	if salvar(s) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	-- não deu para salvar: o Roblox tenta de novo depois; o recibo em memória evita entregar duas vezes
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

-- Passe comprado durante o jogo.
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(jogador: Player, passId: number, comprou: boolean)
	local s = sessoes[jogador]
	local p = Loja.passePorId(passId)
	if not comprou or not s or not p then
		return
	end
	s.loja.passes[p.id] = true
	aplicarLoja(s)
	table.insert(s.eventos, { tipo = "compra", texto = Idioma.t(p.nome) })
	enviarEstado(s)
	task.spawn(salvar, s)
end)

-- Gerente Automático: completa as frotas e constrói o que o caixa pagar.
local function rodarGerente(s: Sessao, acoes: any)
	local antes = Idioma.atual
	Idioma.atual = s.idioma
	pcall(acoes.completarFrotas, s, nil)
	pcall(acoes.construirTudo, s, nil)
	Idioma.atual = antes
end

-- ---------------------------------------------------------------- ações

local Acoes: { [string]: (Sessao, any) -> (boolean, string?) } = {}

function Acoes.construir(s: Sessao, args: any): (boolean, string?)
	if type(args) ~= "table" or type(args.trecho) ~= "string" then
		return false, L("Pedido inválido.", "Invalid request.")
	end
	local dados = MAPAS[s.mapaAtual]
	local e = s.mapas[s.mapaAtual]
	local linha, iLinha, trecho, iTrecho = Economia.acharTrecho(dados, args.trecho)
	if not trecho then
		return false, L("Trecho desconhecido.", "Unknown section.")
	end
	local situacao = Economia.situacaoTrecho(e, dados, iLinha, iTrecho)
	if situacao == "construido" then
		return false, L("Esse trecho já foi construído.", "That section is already built.")
	elseif situacao == "projeto" then
		return false, L("Essa ferrovia ainda é só um projeto: pesquise no Gabinete de Projetos.", "That railway is still just a project: study it in the Projects Cabinet.")
	elseif situacao == "bloqueado" then
		return false, L("Esse trecho ainda não está liberado.", "That section is not unlocked yet.")
	end
	local alternativa = "padrao"
	if trecho.alternativas then
		alternativa = if type(args.alternativa) == "string" then args.alternativa else trecho.alternativas[1].id
	end
	local custo = Economia.opcaoTrecho(trecho, alternativa).custo
	if e.dinheiro < custo then
		return false, L("Dinheiro insuficiente.", "Not enough money.")
	end
	e.dinheiro -= custo
	e.trechos[trecho.id] = alternativa
	if (e.trens[linha.id] or 0) == 0 then
		e.trens[linha.id] = 1 -- primeiro trem da linha é grátis
	end
	Metas.contar(e, "trechos", 1)
	ganharXp(s, e, Metas.XP.trecho)
	if Economia.linhaCompleta(e, linha) then
		ganharXp(s, e, Metas.XP.linha)
		table.insert(s.eventos, { tipo = "linha", nome = linha.nome })
	end
	return true, nil
end

function Acoes.trem(s: Sessao, args: any): (boolean, string?)
	if type(args) ~= "table" or type(args.linha) ~= "string" then
		return false, L("Pedido inválido.", "Invalid request.")
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
		return false, L("Linha desconhecida.", "Unknown line.")
	end
	if Economia.trechosConstruidos(e, linha) == 0 then
		return false, L("Construa um trecho dessa linha primeiro.", "Build a section of that line first.")
	end
	if not Economia.podeComprarTrem(e, dados, linha) then
		return false, L("Frota completa: os trens já levam todos os passageiros desta linha.", "Fleet full: the trains already carry every passenger on this line.")
	end
	local custo = Economia.custoTrem(e, linha)
	if e.dinheiro < custo then
		return false, L("Dinheiro insuficiente.", "Not enough money.")
	end
	e.dinheiro -= custo
	e.trens[linha.id] = (e.trens[linha.id] or 0) + 1
	Metas.contar(e, "trens", 1)
	ganharXp(s, e, Metas.XP.trem)
	return true, nil
end

-- Vende um trem (devolve metade do preço). A linha fica sempre com ao menos 1.
function Acoes.venderTrem(s: Sessao, args: any): (boolean, string?)
	if type(args) ~= "table" or type(args.linha) ~= "string" then
		return false, L("Pedido inválido.", "Invalid request.")
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
		return false, L("Linha desconhecida.", "Unknown line.")
	end
	if not Economia.podeVenderTrem(e, linha) then
		return false, L("Toda linha precisa de pelo menos 1 trem.", "Every line needs at least 1 train.")
	end
	e.trens[linha.id] -= 1
	e.dinheiro += Economia.valorVendaTrem(e, linha)
	return true, nil
end

function Acoes.melhorarEstacao(s: Sessao, args: any): (boolean, string?)
	if type(args) ~= "table" or type(args.estacao) ~= "string" then
		return false, L("Pedido inválido.", "Invalid request.")
	end
	local dados = MAPAS[s.mapaAtual]
	local e = s.mapas[s.mapaAtual]
	if not dados.estacoes[args.estacao] then
		return false, L("Estação desconhecida.", "Unknown station.")
	end
	if not Economia.estacaoNaRede(e, dados, args.estacao) then
		return false, L("Construa um trecho até esta estação primeiro.", "Build a section to this station first.")
	end
	local custo = Economia.custoMelhoria(e, dados, args.estacao)
	if not custo then
		return false, L("Esta estação já está no nível máximo.", "This station is already at the top level.")
	end
	if e.dinheiro < custo then
		return false, L("Dinheiro insuficiente.", "Not enough money.")
	end
	e.dinheiro -= custo
	e.estacoes[args.estacao] = Economia.nivelEstacao(e, args.estacao) + 1
	Metas.contar(e, "estacoes", 1)
	ganharXp(s, e, Metas.XP.estacao)
	return true, nil
end

-- Constrói, do mais barato para o mais caro, todos os trechos disponíveis que o dinheiro pagar.
function Acoes.construirTudo(s: Sessao, _args: any): (boolean, string?)
	local dados = MAPAS[s.mapaAtual]
	local e = s.mapas[s.mapaAtual]
	local construidos = 0
	for _ = 1, 100 do
		local melhor, melhorCusto = nil, math.huge
		for i, linha in dados.linhas do
			for j, t in linha.trechos do
				if Economia.situacaoTrecho(e, dados, i, j) == "disponivel" then
					local custo = Economia.opcaoTrecho(t, nil).custo
					if custo < melhorCusto then
						melhor, melhorCusto = t, custo
					end
				end
			end
		end
		if not melhor or melhorCusto > e.dinheiro then
			break
		end
		local ok = Acoes.construir(s, { trecho = melhor.id })
		if not ok then
			break
		end
		construidos += 1
	end
	if construidos == 0 then
		return false, L("Nenhum trecho disponível cabe no seu caixa agora.", "No available section fits your budget right now.")
	end
	return true, L(`{construidos} trecho(s) construído(s).`, `{construidos} section(s) built.`)
end

-- Compra os trens que faltam em todas as linhas, enquanto houver dinheiro.
-- Vende os trens que sobram (sem passageiro para levar), pelo valor de venda. Devolve quantos saíram.
-- Acontece sobretudo na troca de era: os trens novos levam o dobro, e metade da frota antiga fica vazia.
local function venderSobras(e: any, dados: any): (number, number)
	local vendidos, valor = 0, 0
	for _, linha in dados.linhas do
		local sobra = Economia.trensSobrando(e, dados, linha)
		local podeTirar = math.max(0, (e.trens[linha.id] or 0) - 1) -- toda linha fica com ao menos 1
		local n = math.min(sobra, podeTirar)
		if n > 0 then
			e.trens[linha.id] -= n
			local v = Economia.valorVendaTrem(e, linha) * n
			e.dinheiro += v
			vendidos += n
			valor += v
		end
	end
	return vendidos, valor
end

function Acoes.completarFrotas(s: Sessao, _args: any): (boolean, string?)
	local dados = MAPAS[s.mapaAtual]
	local e = s.mapas[s.mapaAtual]
	local vendidos, valor = venderSobras(e, dados)
	local comprados = 0
	for _, linha in dados.linhas do
		while Economia.podeComprarTrem(e, dados, linha) and e.dinheiro >= Economia.custoTrem(e, linha) do
			e.dinheiro -= Economia.custoTrem(e, linha)
			e.trens[linha.id] = (e.trens[linha.id] or 0) + 1
			Metas.contar(e, "trens", 1)
			ganharXp(s, e, Metas.XP.trem)
			comprados += 1
		end
	end
	local simbolo = dados.simbolo
	if comprados == 0 and vendidos == 0 then
		return false, L("Nenhuma linha precisa de trem, ou falta dinheiro.", "No line needs a train, or there is not enough money.")
	elseif vendidos > 0 and comprados > 0 then
		return true, L(`{comprados} trem(ns) comprado(s) e {vendidos} vazio(s) vendido(s) (+ {Economia.formatar(valor, simbolo)}).`, `{comprados} train(s) bought and {vendidos} empty one(s) sold (+ {Economia.formatar(valor, simbolo)}).`)
	elseif vendidos > 0 then
		return true, L(`{vendidos} trem(ns) vazio(s) vendido(s) (+ {Economia.formatar(valor, simbolo)}).`, `{vendidos} empty train(s) sold (+ {Economia.formatar(valor, simbolo)}).`)
	end
	return true, L(`{comprados} trem(ns) comprado(s).`, `{comprados} train(s) bought.`)
end

-- Gabinete de Projetos: começa a pesquisa (paga na hora, termina com o tempo, mesmo offline).
function Acoes.pesquisar(s: Sessao, args: any): (boolean, string?)
	if type(args) ~= "table" or type(args.projeto) ~= "string" then
		return false, L("Pedido inválido.", "Invalid request.")
	end
	local dados = MAPAS[s.mapaAtual]
	local e = s.mapas[s.mapaAtual]
	local p = Economia.acharProjeto(dados, args.projeto)
	if not p then
		return false, L("Projeto desconhecido.", "Unknown project.")
	end
	local situacao = Economia.situacaoProjeto(e, dados, p)
	if situacao == "concluido" then
		return false, L("Esse projeto já foi concluído.", "That project is already finished.")
	elseif situacao == "pesquisando" then
		return false, L("Esse projeto já está em estudo.", "That project is already being studied.")
	elseif situacao == "ocupado" then
		return false, L("O Gabinete já está estudando outro projeto. Espere terminar ou acelere.", "The Cabinet is already studying another project. Wait for it to finish or speed it up.")
	elseif situacao == "bloqueado" then
		local _, motivo = Economia.requisitosProjeto(e, dados, p)
		return false, motivo or L("Projeto ainda fechado.", "Project still locked.")
	end
	if e.dinheiro < p.custo then
		return false, L("Dinheiro insuficiente.", "Not enough money.")
	end
	e.dinheiro -= p.custo
	e.projetos[p.id] = os.time() + Economia.duracaoProjeto(e, p)
	Metas.contar(e, "estudo", 1)
	ganharXp(s, e, Metas.XP.projeto)
	-- "Concluir estudo" comprado antes (sem estudo em andamento): usa agora
	if s.loja.estudosGuardados > 0 then
		s.loja.estudosGuardados -= 1
		e.projetos[p.id] = os.time()
		aplicarLoja(s)
		task.spawn(salvar, s)
		return true, L(`Estudo concluído: {p.nome}.`, `Study finished: {p.nome}.`)
	end
	return true, L(`Estudo iniciado: {p.nome}.`, `Study started: {p.nome}.`)
end

-- Paga para terminar agora a pesquisa em andamento.
function Acoes.acelerar(s: Sessao, args: any): (boolean, string?)
	if type(args) ~= "table" or type(args.projeto) ~= "string" then
		return false, L("Pedido inválido.", "Invalid request.")
	end
	local dados = MAPAS[s.mapaAtual]
	local e = s.mapas[s.mapaAtual]
	local p = Economia.acharProjeto(dados, args.projeto)
	if not p then
		return false, L("Projeto desconhecido.", "Unknown project.")
	end
	local atual, restante = Economia.pesquisaAtual(e)
	if atual ~= p.id then
		return false, L("Esse projeto não está em estudo.", "That project is not being studied.")
	end
	local custo = Economia.custoAcelerar(p, restante)
	if e.dinheiro < custo then
		return false, L("Dinheiro insuficiente.", "Not enough money.")
	end
	e.dinheiro -= custo
	e.projetos[p.id] = os.time()
	return true, nil
end

function Acoes.modernizar(s: Sessao, _args: any): (boolean, string?)
	local dados = MAPAS[s.mapaAtual]
	local e = s.mapas[s.mapaAtual]
	local proxima, liberada = Economia.proximaEra(e, dados)
	if not proxima then
		return false, L("Você já está na era mais moderna.", "You are already in the most modern era.")
	end
	if not liberada then
		return false, L(`Complete {Economia.metaEra(proxima, dados)} linhas para liberar a próxima era.`, `Complete {Economia.metaEra(proxima, dados)} lines to unlock the next era.`)
	end
	if e.dinheiro < proxima.custo then
		return false, L("Dinheiro insuficiente.", "Not enough money.")
	end
	e.dinheiro -= proxima.custo
	e.era = proxima.id
	ganharXp(s, e, Metas.XP.era)
	-- os trens da era nova levam mais gente: os que ficariam vazios são vendidos na hora
	local vendidos, valor = venderSobras(e, dados)
	if vendidos > 0 then
		return true, L(`Os trens novos levam mais passageiros: {vendidos} trem(ns) antigo(s) vendido(s) (+ {Economia.formatar(valor, dados.simbolo)}).`, `The new trains carry more passengers: {vendidos} old train(s) sold (+ {Economia.formatar(valor, dados.simbolo)}).`)
	end
	return true, nil
end

-- Contratos: aceitar uma das ofertas (uma por vez).
function Acoes.aceitarContrato(s: Sessao, args: any): (boolean, string?)
	if type(args) ~= "table" or type(args.id) ~= "number" then
		return false, L("Pedido inválido.", "Invalid request.")
	end
	local e = s.mapas[s.mapaAtual]
	if e.contrato then
		return false, L("Você já tem um contrato em andamento.", "You already have a contract in progress.")
	end
	for i, oferta in e.ofertas do
		if oferta.id == args.id then
			table.remove(e.ofertas, i)
			oferta.progresso, oferta.decorrido = 0, 0
			e.contrato = oferta
			return true, L("Contrato assinado. O prazo já está correndo!", "Contract signed. The clock is running!")
		end
	end
	return false, L("Essa oferta não está mais disponível.", "That offer is no longer available.")
end

-- Desistir não tem multa, mas a oferta se perde.
function Acoes.desistirContrato(s: Sessao, _args: any): (boolean, string?)
	local e = s.mapas[s.mapaAtual]
	if not e.contrato then
		return false, L("Não há contrato em andamento.", "There is no contract in progress.")
	end
	e.contrato = nil
	return true, L("Contrato cancelado.", "Contract cancelled.")
end

function Acoes.trocarOfertas(s: Sessao, _args: any): (boolean, string?)
	local dados = MAPAS[s.mapaAtual]
	local e = s.mapas[s.mapaAtual]
	if e.contrato then
		return false, L("Termine o contrato em andamento primeiro.", "Finish the current contract first.")
	end
	local espera = Metas.TROCA_OFERTAS_SEGUNDOS - (os.time() - e.ofertasEm)
	if #e.ofertas > 0 and espera > 0 then
		return false, L(`Ofertas novas em {Metas.relogio(espera)}.`, `New offers in {Metas.relogio(espera)}.`)
	end
	local novas = Metas.gerarOfertas(e, dados, Metas.contexto(e, dados), s.rng)
	if #novas == 0 then
		return false, L("Construa mais trechos para receber contratos.", "Build more sections to get contracts.")
	end
	e.ofertas = novas
	e.ofertasEm = os.time()
	return true, nil
end

-- Missão do dia: quando completa, o jogador resgata o prêmio.
function Acoes.resgatarMissao(s: Sessao, args: any): (boolean, string?)
	if type(args) ~= "table" or type(args.indice) ~= "number" then
		return false, L("Pedido inválido.", "Invalid request.")
	end
	local dados = MAPAS[s.mapaAtual]
	local e = s.mapas[s.mapaAtual]
	local m = e.missoes.lista[args.indice]
	if not m then
		return false, L("Missão desconhecida.", "Unknown mission.")
	end
	if m.resgatada then
		return false, L("Essa missão já foi resgatada.", "That mission was already claimed.")
	end
	if m.progresso < m.meta then
		return false, L("Essa missão ainda não foi cumprida.", "That mission is not complete yet.")
	end
	m.resgatada = true
	e.dinheiro += m.premio
	Metas.contar(e, "missoes", 1)
	ganharXp(s, e, m.xp)
	return true, L(`Missão cumprida: + {Economia.formatar(m.premio, Economia.moedaDe(dados, e))}`, `Mission complete: + {Economia.formatar(m.premio, Economia.moedaDe(dados, e))}`)
end

-- Tutorial: concluir (com prêmio, no último passo) ou pular.
-- Jornal: pagar para encerrar um evento ruim (enchente, greve, apagão).
function Acoes.resolverEvento(s: Sessao, args: any): (boolean, string?)
	if type(args) ~= "table" or type(args.id) ~= "string" then
		return false, L("Pedido inválido.", "Invalid request.")
	end
	local dados = MAPAS[s.mapaAtual]
	local e = s.mapas[s.mapaAtual]
	for i, ev in e.jornal.ativos do
		if ev.id == args.id and ev.fim > os.time() then
			local def = Jornal.acharEvento(ev.id)
			if not def or not def.resolvivel then
				return false, L("Esse acontecimento não tem como ser resolvido.", "That event cannot be resolved.")
			end
			local custo = Jornal.custoResolver(Economia.rendaTotal(e, dados))
			if e.dinheiro < custo then
				return false, L("Dinheiro insuficiente.", "Not enough money.")
			end
			e.dinheiro -= custo
			table.remove(e.jornal.ativos, i)
			return true, L("Problema resolvido.", "Problem solved.")
		end
	end
	return false, L("Esse acontecimento já passou.", "That event is already over.")
end

-- Decisões: escolhe uma das opções da decisão pendente (args.opcao = índice).
local TIPOS_COM_ALVO = { linha = true, cidade = true, regiao = true, carga = true }
function Acoes.escolherDecisao(s: Sessao, args: any): (boolean, string?)
	if type(args) ~= "table" or type(args.opcao) ~= "number" then
		return false, L("Pedido inválido.", "Invalid request.")
	end
	local dados = MAPAS[s.mapaAtual]
	local e = s.mapas[s.mapaAtual]
	local pend = e.decisoes.pendente
	local def = pend and Decisoes.acharDecisao(pend.id)
	if not pend or not def then
		return false, L("Não há decisão esperando.", "There is no decision waiting.")
	end
	local op = def.opcoes[math.floor(args.opcao)]
	if not op then
		return false, L("Pedido inválido.", "Invalid request.")
	end
	local lucro = Economia.rendaTotal(e, dados)
	local custo = Decisoes.custo(e, lucro, op)
	if e.dinheiro < custo then
		return false, L("Dinheiro insuficiente para essa escolha.", "Not enough money for that choice.")
	end
	local r = Decisoes.resolver(op, e, lucro, s.rng)
	e.dinheiro = math.max(0, e.dinheiro + r.dinheiro)
	local agora = os.time()
	for _, m in r.mods do
		table.insert(e.decisoes.efeitos, {
			id = def.id,
			tipo = m.tipo,
			alvo = if TIPOS_COM_ALVO[m.tipo] then pend.alvo else nil,
			mult = m.mult,
			inicio = agora,
			fim = agora + m.min * 60,
		})
	end
	if r.xp > 0 then
		ganharXp(s, e, r.xp)
	end
	if r.trens > 0 and pend.tipo == "linha" and pend.alvo then
		e.trens[pend.alvo] = math.min(Economia.MAX_TRENS_LINHA, (e.trens[pend.alvo] or 0) + r.trens)
	end
	if r.pesquisa > 0 then
		local id = Economia.pesquisaAtual(e)
		if id then
			e.projetos[id] -= r.pesquisa * 60
		end
	end
	e.decisoes.vistas[def.id] = true
	table.insert(e.decisoes.historico, 1, { id = def.id, opcao = math.floor(args.opcao), em = agora, sorte = r.sorteOk })
	while #e.decisoes.historico > Decisoes.MAX_HISTORICO do
		table.remove(e.decisoes.historico)
	end
	e.decisoes.pendente = nil
	s.proximaDecisao = agora + s.rng:NextInteger(Decisoes.INTERVALO_MIN, Decisoes.INTERVALO_MAX)
	if r.sorteOk == true then
		return true, L("Deu certo!", "It worked!")
	elseif r.sorteOk == false then
		return true, L("Não deu certo desta vez.", "It didn't work this time.")
	end
	return true, L("Decisão tomada.", "Decision made.")
end

-- Tarifas: muda o preço de uma classe (args.classe = 1 a 3, args.preco = 0,5 a 2).
function Acoes.definirTarifa(s: Sessao, args: any): (boolean, string?)
	if type(args) ~= "table" or type(args.classe) ~= "number" or type(args.preco) ~= "number" or args.preco ~= args.preco then
		return false, L("Pedido inválido.", "Invalid request.")
	end
	local c = math.floor(args.classe)
	if c < 1 or c > Tarifas.CLASSES then
		return false, L("Pedido inválido.", "Invalid request.")
	end
	local e = s.mapas[s.mapaAtual]
	e.tarifas = e.tarifas or Tarifas.padrao()
	local t = e.tarifas :: Tarifas.EstadoTarifas
	t.precos[c] = Tarifas.arredondar(args.preco)
	return true, nil
end

-- Tarifas: contrata ou dispensa um serviço de bordo (args.id).
function Acoes.alternarServico(s: Sessao, args: any): (boolean, string?)
	if type(args) ~= "table" or type(args.id) ~= "string" then
		return false, L("Pedido inválido.", "Invalid request.")
	end
	local serv = Tarifas.PorId[args.id]
	if not serv then
		return false, L("Pedido inválido.", "Invalid request.")
	end
	local e = s.mapas[s.mapaAtual]
	if serv.era > Economia.indiceEra(e) then
		return false, L("Esse serviço ainda não existe nesta era.", "That service does not exist yet in this era.")
	end
	e.tarifas = e.tarifas or Tarifas.padrao()
	local t = e.tarifas :: Tarifas.EstadoTarifas
	if t.servicos[serv.id] then
		t.servicos[serv.id] = nil
		return true, L(`{serv.nome.pt}: serviço dispensado.`, `{serv.nome.en}: service dismissed.`)
	end
	t.servicos[serv.id] = true
	return true, L(`{serv.nome.pt}: serviço contratado.`, `{serv.nome.en}: service hired.`)
end

-- Nome da companhia: passa pelo filtro de texto do Roblox antes de ser guardado (obrigatório para texto
-- digitado que outros jogadores podem ver, como no ranking).
local NOME_MIN, NOME_MAX = 3, 32
function Acoes.renomear(s: Sessao, args: any): (boolean, string?)
	if type(args) ~= "table" or type(args.nome) ~= "string" then
		return false, L("Pedido inválido.", "Invalid request.")
	end
	local nome = args.nome:gsub("%s+", " "):gsub("^ ", ""):gsub(" $", "")
	if utf8.len(nome) == nil or utf8.len(nome) < NOME_MIN or utf8.len(nome) > NOME_MAX then
		return false, L(`O nome precisa ter de {NOME_MIN} a {NOME_MAX} letras.`, `The name must have {NOME_MIN} to {NOME_MAX} letters.`)
	end
	if os.clock() - s.ultimoNome < 10 then
		return false, L("Espere alguns segundos para trocar o nome de novo.", "Wait a few seconds before changing the name again.")
	end
	s.ultimoNome = os.clock()
	local ok, filtrado = pcall(function()
		local resultado = TextService:FilterStringAsync(nome, s.jogador.UserId, Enum.TextFilterContext.PublicChat)
		return resultado:GetNonChatStringForBroadcastAsync()
	end)
	if not ok then
		return false, L("Não deu para conferir o nome agora. Tente de novo daqui a pouco.", "Could not check the name right now. Try again in a moment.")
	end
	s.mapas[s.mapaAtual].nomeCompanhia = filtrado
	if filtrado ~= nome then
		return true, L("Parte do nome foi bloqueada pelo filtro do Roblox.", "Part of the name was blocked by the Roblox filter.")
	end
	return true, L("Nome da companhia registrado.", "Company name registered.")
end

-- O jogador trocou o idioma em Ajustes: as próximas mensagens saem no idioma novo.
-- Troca o mapa aberto (cada mapa é uma companhia própria, com o seu progresso).
function Acoes.mapa(s: Sessao, args: any): (boolean, string?)
	local id = type(args) == "table" and args.mapa
	if type(id) ~= "string" or not MAPAS[id] then
		return false, L("Mapa desconhecido.", "Unknown map.")
	end
	if id == s.mapaAtual then
		return true, nil
	end
	-- o mapa que fica para trás para de render agora; o novo começa a contar daqui
	local antigo = s.mapas[s.mapaAtual]
	if antigo then
		antigo.ultimoTick = os.time()
	end
	s.mapaAtual = id
	-- avisos do mapa antigo que ainda não foram mostrados (nível, linha, contrato, jornal) não valem no novo:
	-- chegavam logo depois da troca, com o título de nível do outro mapa
	for i = #s.eventos, 1, -1 do
		local tipo = s.eventos[i].tipo
		if tipo == "nivel" or tipo == "linha" or tipo == "contrato" or tipo == "jornal" then
			table.remove(s.eventos, i)
		end
	end
	local e = s.mapas[id]
	e.ultimoTick = os.time()
	s.proximaNoticia = 0
	s.proximaDecisao = 0
	atualizarPlacar(s, nil)
	task.spawn(salvar, s)
	return true, nil
end

-- Liga ou desliga o Gerente Automático (só para quem tem o passe).
function Acoes.gerente(s: Sessao, args: any): (boolean, string?)
	if not s.loja.passes.gerente then
		return false, L("Você ainda não tem o Gerente Automático.", "You don't have the Auto Manager yet.")
	end
	s.loja.gerenteLigado = type(args) == "table" and args.ligado == true
	aplicarLoja(s)
	return true, if s.loja.gerenteLigado then L("Gerente Automático ligado.", "Auto Manager on.") else L("Gerente Automático desligado.", "Auto Manager off.")
end

function Acoes.idioma(s: Sessao, args: any): (boolean, string?)
	if type(args) ~= "table" or (args.idioma ~= "pt" and args.idioma ~= "en") then
		return false, L("Pedido inválido.", "Invalid request.")
	end
	s.idioma = args.idioma
	return true, nil
end

function Acoes.tutorial(s: Sessao, args: any): (boolean, string?)
	local dados = MAPAS[s.mapaAtual]
	local e = s.mapas[s.mapaAtual]
	if e.tutorial then
		return false, L("O tutorial já acabou.", "The tutorial is already over.")
	end
	if type(args) == "table" and args.pular == true then
		e.tutorial = true
		return true, nil
	end
	local passo = Metas.passoTutorial(e, dados)
	if not passo or passo.id ~= "fim" then
		return false, L("Ainda falta um passo do tutorial.", "There is still a tutorial step left.")
	end
	e.tutorial = true
	e.dinheiro += Metas.PREMIO_TUTORIAL
	ganharXp(s, e, Metas.XP.tutorial)
	return true, L(`Tutorial concluído: + {Economia.formatar(Metas.PREMIO_TUTORIAL, Economia.moedaDe(dados, e))}`, `Tutorial complete: + {Economia.formatar(Metas.PREMIO_TUTORIAL, Economia.moedaDe(dados, e))}`)
end

remoteAcao.OnServerInvoke = function(jogador: Player, tipo: any, args: any)
	local s = sessoes[jogador]
	if not s or not s.carregado then
		return { ok = false, erro = L("Carregando seus dados…", "Loading your data…") }
	end
	local agora = os.clock()
	if agora - s.ultimaAcao < 0.1 then
		return { ok = false, erro = L("Devagar!", "Slow down!") }
	end
	s.ultimaAcao = agora
	local acao = if type(tipo) == "string" then Acoes[tipo] else nil
	if not acao then
		return { ok = false, erro = L("Ação desconhecida.", "Unknown action.") }
	end
	-- as mensagens da ação saem no idioma do jogador (Idioma.L lê Idioma.atual)
	local antes = Idioma.atual
	Idioma.atual = s.idioma
	local ok, texto = acao(s, args)
	Idioma.atual = antes
	if ok then
		enviarEstado(s)
	end
	-- em caso de sucesso, o segundo valor (se houver) é uma mensagem para o jogador
	return { ok = ok, erro = if ok then nil else texto, mensagem = if ok then texto else nil }
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
	s.eventos = {}
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
		ultimoNome = -math.huge,
		proximaNoticia = 0,
		proximaDecisao = 0,
		ganhoOffline = 0,
		eventos = {},
		rng = Random.new(),
		idioma = if string.sub(string.lower(jogador.LocaleId or ""), 1, 2) == "pt" or (jogador.LocaleId or "") == "" then "pt" else "en",
		loja = sanearLoja(nil),
		proximoGerente = 0,
		pontosRanking = -1,
	}
	sessoes[jogador] = s

	local salvo, ok = Persistencia.carregar(jogador.UserId)
	if not ok then
		-- falhou de verdade (não é "jogador novo"): não salvar por cima do progresso real
		warn(`[Ferrovia] Não consegui carregar {jogador.Name}; esta sessão não vai salvar.`)
	end
	s.podeSalvar = ok and Persistencia.disponivel()
	s.loja = sanearLoja(if type(salvo) == "table" then salvo.loja else nil)
	if type(salvo) == "table" and type(salvo.mapaAtual) == "string" and MAPAS[salvo.mapaAtual] then
		s.mapaAtual = salvo.mapaAtual
	end
	consultarPasses(s)

	for id, dados in MAPAS do
		local estadoSalvo = if type(salvo) == "table" and type(salvo.mapas) == "table" then salvo.mapas[id] else nil
		local e = sanear(estadoSalvo)
		s.mapas[id] = e
		aplicarLoja(s) -- antes da renda offline: Lucro em Dobro e Renda Offline Longa contam
		Economia.ajustarFrota(e, dados)
		if estadoSalvo then
			local decorrido = math.clamp(os.time() - e.ultimoTick, 0, Economia.offlineMaximo(e))
			-- o Impulso 2x não conta no tempo fora (pode ter acabado no meio); o Lucro em Dobro conta
			local loja = e.loja :: any
			local impulso = loja.impulsoAte
			loja.impulsoAte = 0
			local ganho = math.max(-e.dinheiro, Economia.rendaTotal(e, dados) * decorrido)
			loja.impulsoAte = impulso
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
		atualizarPlacar(s, nil)
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
	--   game.ServerStorage.FerroviaDebug:Invoke("era", "eletrico")
	-- Também há o painel de debug do cliente (src/client/Debug.luau), que fala pelo RemoteFunction
	-- Remotes.Debug: ele só é criado aqui dentro, então no jogo publicado nem existe.
	local function executar(s: Sessao, comando: string, valor: any): any
		do
			local e = s.mapas[s.mapaAtual]
			if comando == "dinheiro" then
				e.dinheiro += tonumber(valor) or 0
			elseif comando == "zerar" then
				s.mapas[s.mapaAtual] = Economia.estadoNovo()
			elseif comando == "pesquisas" then
				-- termina na hora todas as pesquisas em andamento
				for id, fim in e.projetos do
					e.projetos[id] = math.min(fim, os.time())
				end
			elseif comando == "xp" then
				ganharXp(s, e, tonumber(valor) or 0)
			elseif comando == "contrato" then
				-- cumpre o contrato em andamento; com "falhar", estoura o prazo (vale no próximo segundo)
				if e.contrato and valor == "falhar" then
					e.contrato.decorrido = e.contrato.prazo
				elseif e.contrato then
					encerrarContrato(s, e, true)
				end
			elseif comando == "missoes" then
				-- completa as missões de hoje; com "novas", sorteia de novo
				if valor == "novas" then
					e.missoes.dia = 0
				else
					for _, m in e.missoes.lista do
						m.progresso = m.meta
					end
				end
			elseif comando == "evento" then
				-- publica uma notícia agora (valor = id do evento, ou nada para sortear)
				local ev: any = nil
				if type(valor) == "string" then
					local def = Jornal.acharEvento(valor)
					local alvo = def and def.alvo and def.alvo(e, MAPAS[s.mapaAtual], s.rng)
					if def and alvo then
						ev = { id = def.id, tipo = def.tipo, alvo = if alvo == "" then nil else alvo, mult = def.mult, inicio = os.time(), fim = os.time() + def.duracao }
					end
				else
					ev = Jornal.sortear(e, MAPAS[s.mapaAtual], s.rng)
				end
				if ev then
					publicar(s, e, ev)
				end
				return ev and ev.id
			elseif comando == "decisao" then
				-- traz uma decisão agora (valor = id, ou nada para sortear da era)
				local def, tipo, alvo
				if type(valor) == "string" then
					def = Decisoes.acharDecisao(valor)
					if def then
						tipo, alvo = Decisoes.resolverAlvo(def, e, MAPAS[s.mapaAtual], s.rng)
						if not tipo then
							return "alvo indisponível"
						end
					end
				else
					def, tipo, alvo = Decisoes.sortear(e, MAPAS[s.mapaAtual], e.decisoes.vistas, s.rng)
				end
				if def then
					e.decisoes.pendente = { id = def.id, tipo = tipo, alvo = alvo, em = os.time() }
					table.insert(s.eventos, { tipo = "decisao", id = def.id })
				end
				enviarEstado(s)
				return def and def.id
			elseif comando == "era" then
				-- pula para uma era ("vapor", "diesel", "eletrico", "alta") para ver o visual dela
				for _, era in Economia.ERAS do
					if era.id == valor then
						e.era = era.id
					end
				end
			elseif comando == "tempo" then
				-- adianta o relógio em `valor` minutos: lucro, pesquisas, contrato e efeitos do Jornal/decisões
				local seg = (tonumber(valor) or 0) * 60
				local b = Economia.balanco(e, MAPAS[s.mapaAtual])
				e.dinheiro += math.max(0, b.lucro) * seg
				for id, fim in e.projetos do
					e.projetos[id] = fim - seg
				end
				if e.contrato then
					e.contrato.decorrido = math.min(e.contrato.prazo, e.contrato.decorrido + seg)
				end
				for _, ev in ((e.jornal or {}) :: any).ativos or {} do
					ev.fim -= seg
				end
				for _, ev in e.decisoes.efeitos do
					ev.fim -= seg
				end
			elseif comando == "estado" then
				return e
			end
			enviarEstado(s)
		end
		return "ok"
	end
	local debug = Instance.new("BindableFunction")
	debug.Name = "FerroviaDebug"
	debug.OnInvoke = function(comando: string, valor: any)
		local r: any = "ok"
		for _, s in sessoes do
			r = executar(s, comando, valor)
		end
		return r
	end
	debug.Parent = ServerStorage
	local remoteDebug = Instance.new("RemoteFunction")
	remoteDebug.Name = "Debug"
	remoteDebug.OnServerInvoke = function(jogador: Player, comando: any, valor: any)
		local s = sessoes[jogador]
		if not RunService:IsStudio() or not s or not s.carregado or type(comando) ~= "string" or comando == "estado" then
			return "indisponível"
		end
		local ok, r = pcall(executar, s, comando, valor)
		return if ok then (if type(r) == "table" then "ok" else tostring(r or "ok")) else "erro: " .. tostring(r)
	end
	remoteDebug.Parent = pastaRemotes
end

-- ---------------------------------------------------------------- ranking global

-- Pontuação: nível × 1000 + linhas completas (o nível manda; as linhas desempatam). Nada de dinheiro.
-- Cada servidor manda a pontuação dos seus jogadores a cada poucos minutos e guarda o top 10, que o
-- menu inicial pede pelo RemoteFunction Remotes.Ranking.
local INTERVALO_RANKING = 120
local TOP_RANKING = 10
local rankingStore: OrderedDataStore? = nil
do
	local ok, store = pcall(function()
		return DataStoreService:GetOrderedDataStore("RankingGlobal_v2")
	end)
	if ok then
		rankingStore = store
	end
end
local topRanking: { any } = {}
local rankingEm = 0

-- A pontuação do jogador é a da sua melhor companhia (o mapa onde ele foi mais longe).
local function pontosRanking(s: Sessao): number
	local melhor = 0
	for id, e in s.mapas do
		melhor = math.max(melhor, (Economia.nivel(e)) * 1000 + Economia.linhasCompletas(e, MAPAS[id]))
	end
	return melhor
end

local function atualizarRanking()
	local store = rankingStore
	if not store or not Persistencia.disponivel() then
		return
	end
	for _, s in sessoes do
		local pts = pontosRanking(s)
		if s.carregado and s.podeSalvar and pts ~= s.pontosRanking then
			local ok = pcall(function()
				store:SetAsync(tostring(s.jogador.UserId), pts)
			end)
			if ok then
				s.pontosRanking = pts
			end
		end
	end
	local ok, pagina = pcall(function()
		return store:GetSortedAsync(false, TOP_RANKING):GetCurrentPage()
	end)
	if not ok or type(pagina) ~= "table" then
		return
	end
	local ids = {}
	for _, item in pagina do
		local id = tonumber(item.key)
		if id then
			table.insert(ids, id)
		end
	end
	-- nomes de exibição (a maioria não está neste servidor)
	local nomes: { [number]: string } = {}
	local okNomes, infos = pcall(function()
		return game:GetService("UserService"):GetUserInfosByUserIdsAsync(ids)
	end)
	if okNomes and type(infos) == "table" then
		for _, info in infos do
			nomes[info.Id] = info.DisplayName
		end
	end
	local lista = {}
	for _, item in pagina do
		local id = tonumber(item.key)
		if id and type(item.value) == "number" then
			table.insert(lista, {
				userId = id,
				nome = nomes[id] or "?",
				nivel = item.value // 1000,
				linhas = item.value % 1000,
			})
		end
	end
	topRanking = lista
	rankingEm = os.time()
end

local remoteRanking = Instance.new("RemoteFunction")
remoteRanking.Name = "Ranking"
remoteRanking.OnServerInvoke = function(_jogador: Player)
	return { lista = topRanking, em = rankingEm, disponivel = rankingStore ~= nil and Persistencia.disponivel() }
end
remoteRanking.Parent = pastaRemotes

task.spawn(function()
	task.wait(10) -- deixa os jogadores carregarem
	while true do
		atualizarRanking()
		task.wait(INTERVALO_RANKING)
	end
end)

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
				local dados = MAPAS[s.mapaAtual]
				local ctx = Metas.contexto(e, dados)
				local lucro = ctx.balanco.lucro
				-- com prejuízo (manutenção maior que a receita) o caixa desce, mas nunca abaixo de zero
				e.dinheiro = math.max(0, e.dinheiro + lucro * dt)
				-- 1 minuto de verdade = 1 dia da ferrovia
				Metas.contar(e, "lucro", math.max(0, lucro) * dt)
				Metas.contar(e, "passageiros", ctx.passageirosDia / Metas.SEGUNDOS_POR_DIA * dt)
				local resultado = Metas.avancarContrato(e, dados, ctx, dt)
				if resultado then
					encerrarContrato(s, e, resultado == "cumprido")
				end
				atualizarMetas(s, e, dados, ctx)
				if s.loja.passes.gerente and s.loja.gerenteLigado and agora >= s.proximoGerente then
					s.proximoGerente = agora + Loja.GERENTE_INTERVALO
					rodarGerente(s, Acoes)
				end
				atualizarPlacar(s, lucro)
				enviarEstado(s, lucro)
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
