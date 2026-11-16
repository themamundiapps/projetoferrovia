--!strict
-- Jogo (servidor): sessões dos jogadores, ações de compra, renda por segundo, ganho offline, metas e save.
-- O servidor é a única autoridade sobre dinheiro; o cliente só pede ações e mostra o estado.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local TextService = game:GetService("TextService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Economia = require(Shared:WaitForChild("Economia"))
local Metas = require(Shared:WaitForChild("Metas"))
local Jornal = require(Shared:WaitForChild("Jornal"))
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
	ultimoNome: number, -- os.clock() da última troca de nome da companhia
	proximaNoticia: number, -- os.time() da próxima notícia do Jornal (0 = ainda não marcado)
	ganhoOffline: number,
	eventos: { any }, -- novidades para o cliente avisar (contrato cumprido, medalha, nível...), enviadas uma vez
	rng: Random,
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
	if type(salvo.nomeCompanhia) == "string" and #salvo.nomeCompanhia <= 64 then
		e.nomeCompanhia = salvo.nomeCompanhia
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
	return {
		mapa = s.mapaAtual,
		dinheiro = e.dinheiro,
		renda = renda or Economia.rendaTotal(e, dados),
		xp = e.xp,
		medalhas = e.medalhas,
		contadores = e.contadores,
		contrato = e.contrato,
		ofertas = e.ofertas,
		ofertasEm = e.ofertasEm,
		missoes = e.missoes,
		tutorial = e.tutorial,
		nomeCompanhia = e.nomeCompanhia,
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
		table.insert(s.eventos, { tipo = "nivel", nivel = depois, titulo = Economia.tituloNivel(depois, e.era) })
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
	for _, m in Metas.novasMedalhas(e, dados, ctx) do
		e.medalhas[m.id] = os.time()
		table.insert(s.eventos, { tipo = "medalha", id = m.id })
		ganharXp(s, e, m.xp)
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
	elseif situacao == "projeto" then
		return false, "Essa ferrovia ainda é só um projeto: pesquise no Gabinete de Projetos."
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
	if not Economia.podeComprarTrem(e, dados, linha) then
		return false, "Frota completa: os trens já levam todos os passageiros desta linha."
	end
	local custo = Economia.custoTrem(e, linha)
	if e.dinheiro < custo then
		return false, "Dinheiro insuficiente."
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
	if not Economia.podeVenderTrem(e, linha) then
		return false, "Toda linha precisa de pelo menos 1 trem."
	end
	e.trens[linha.id] -= 1
	e.dinheiro += Economia.valorVendaTrem(e, linha)
	return true, nil
end

function Acoes.melhorarEstacao(s: Sessao, args: any): (boolean, string?)
	if type(args) ~= "table" or type(args.estacao) ~= "string" then
		return false, "Pedido inválido."
	end
	local dados = MAPAS[s.mapaAtual]
	local e = s.mapas[s.mapaAtual]
	if not dados.estacoes[args.estacao] then
		return false, "Estação desconhecida."
	end
	if not Economia.estacaoNaRede(e, dados, args.estacao) then
		return false, "Construa um trecho até esta estação primeiro."
	end
	local custo = Economia.custoMelhoria(e, dados, args.estacao)
	if not custo then
		return false, "Esta estação já está no nível máximo."
	end
	if e.dinheiro < custo then
		return false, "Dinheiro insuficiente."
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
		return false, "Nenhum trecho disponível cabe no seu caixa agora."
	end
	return true, `{construidos} trecho(s) construído(s).`
end

-- Compra os trens que faltam em todas as linhas, enquanto houver dinheiro.
function Acoes.completarFrotas(s: Sessao, _args: any): (boolean, string?)
	local dados = MAPAS[s.mapaAtual]
	local e = s.mapas[s.mapaAtual]
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
	if comprados == 0 then
		return false, "Nenhuma linha precisa de trem, ou falta dinheiro."
	end
	return true, `{comprados} trem(ns) comprado(s).`
end

-- Gabinete de Projetos: começa a pesquisa (paga na hora, termina com o tempo, mesmo offline).
function Acoes.pesquisar(s: Sessao, args: any): (boolean, string?)
	if type(args) ~= "table" or type(args.projeto) ~= "string" then
		return false, "Pedido inválido."
	end
	local dados = MAPAS[s.mapaAtual]
	local e = s.mapas[s.mapaAtual]
	local p = Economia.acharProjeto(dados, args.projeto)
	if not p then
		return false, "Projeto desconhecido."
	end
	local situacao = Economia.situacaoProjeto(e, dados, p)
	if situacao == "concluido" then
		return false, "Esse projeto já foi concluído."
	elseif situacao == "pesquisando" then
		return false, "Esse projeto já está em estudo."
	elseif situacao == "ocupado" then
		return false, "O Gabinete já está estudando outro projeto. Espere terminar ou acelere."
	elseif situacao == "bloqueado" then
		local _, motivo = Economia.requisitosProjeto(e, dados, p)
		return false, motivo or "Projeto ainda fechado."
	end
	if e.dinheiro < p.custo then
		return false, "Dinheiro insuficiente."
	end
	e.dinheiro -= p.custo
	e.projetos[p.id] = os.time() + p.segundos
	Metas.contar(e, "estudo", 1)
	ganharXp(s, e, Metas.XP.projeto)
	return true, `Estudos da {p.nome} começaram.`
end

-- Paga para terminar agora a pesquisa em andamento.
function Acoes.acelerar(s: Sessao, args: any): (boolean, string?)
	if type(args) ~= "table" or type(args.projeto) ~= "string" then
		return false, "Pedido inválido."
	end
	local dados = MAPAS[s.mapaAtual]
	local e = s.mapas[s.mapaAtual]
	local p = Economia.acharProjeto(dados, args.projeto)
	if not p then
		return false, "Projeto desconhecido."
	end
	local atual, restante = Economia.pesquisaAtual(e)
	if atual ~= p.id then
		return false, "Esse projeto não está em estudo."
	end
	local custo = Economia.custoAcelerar(p, restante)
	if e.dinheiro < custo then
		return false, "Dinheiro insuficiente."
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
	ganharXp(s, e, Metas.XP.era)
	return true, nil
end

-- Contratos: aceitar uma das ofertas (uma por vez).
function Acoes.aceitarContrato(s: Sessao, args: any): (boolean, string?)
	if type(args) ~= "table" or type(args.id) ~= "number" then
		return false, "Pedido inválido."
	end
	local e = s.mapas[s.mapaAtual]
	if e.contrato then
		return false, "Você já tem um contrato em andamento."
	end
	for i, oferta in e.ofertas do
		if oferta.id == args.id then
			table.remove(e.ofertas, i)
			oferta.progresso, oferta.decorrido = 0, 0
			e.contrato = oferta
			return true, "Contrato assinado. O prazo já está correndo!"
		end
	end
	return false, "Essa oferta não está mais disponível."
end

-- Desistir não tem multa, mas a oferta se perde.
function Acoes.desistirContrato(s: Sessao, _args: any): (boolean, string?)
	local e = s.mapas[s.mapaAtual]
	if not e.contrato then
		return false, "Não há contrato em andamento."
	end
	e.contrato = nil
	return true, "Contrato cancelado."
end

function Acoes.trocarOfertas(s: Sessao, _args: any): (boolean, string?)
	local dados = MAPAS[s.mapaAtual]
	local e = s.mapas[s.mapaAtual]
	if e.contrato then
		return false, "Termine o contrato em andamento primeiro."
	end
	local espera = Metas.TROCA_OFERTAS_SEGUNDOS - (os.time() - e.ofertasEm)
	if #e.ofertas > 0 and espera > 0 then
		return false, `Ofertas novas em {Metas.relogio(espera)}.`
	end
	local novas = Metas.gerarOfertas(e, dados, Metas.contexto(e, dados), s.rng)
	if #novas == 0 then
		return false, "Construa mais trechos para receber contratos."
	end
	e.ofertas = novas
	e.ofertasEm = os.time()
	return true, nil
end

-- Missão do dia: quando completa, o jogador resgata o prêmio.
function Acoes.resgatarMissao(s: Sessao, args: any): (boolean, string?)
	if type(args) ~= "table" or type(args.indice) ~= "number" then
		return false, "Pedido inválido."
	end
	local dados = MAPAS[s.mapaAtual]
	local e = s.mapas[s.mapaAtual]
	local m = e.missoes.lista[args.indice]
	if not m then
		return false, "Missão desconhecida."
	end
	if m.resgatada then
		return false, "Essa missão já foi resgatada."
	end
	if m.progresso < m.meta then
		return false, "Essa missão ainda não foi cumprida."
	end
	m.resgatada = true
	e.dinheiro += m.premio
	Metas.contar(e, "missoes", 1)
	ganharXp(s, e, m.xp)
	return true, `Missão cumprida: + {Economia.formatar(m.premio, Economia.moedaDe(dados, e))}`
end

-- Tutorial: concluir (com prêmio, no último passo) ou pular.
-- Jornal: pagar para encerrar um evento ruim (enchente, greve, apagão).
function Acoes.resolverEvento(s: Sessao, args: any): (boolean, string?)
	if type(args) ~= "table" or type(args.id) ~= "string" then
		return false, "Pedido inválido."
	end
	local dados = MAPAS[s.mapaAtual]
	local e = s.mapas[s.mapaAtual]
	for i, ev in e.jornal.ativos do
		if ev.id == args.id and ev.fim > os.time() then
			local def = Jornal.acharEvento(ev.id)
			if not def or not def.resolvivel then
				return false, "Esse acontecimento não tem como ser resolvido."
			end
			local custo = Jornal.custoResolver(Economia.rendaTotal(e, dados))
			if e.dinheiro < custo then
				return false, "Dinheiro insuficiente."
			end
			e.dinheiro -= custo
			table.remove(e.jornal.ativos, i)
			return true, "Problema resolvido."
		end
	end
	return false, "Esse acontecimento já passou."
end

-- Nome da companhia: passa pelo filtro de texto do Roblox antes de ser guardado (obrigatório para texto
-- digitado que outros jogadores podem ver, como no ranking).
local NOME_MIN, NOME_MAX = 3, 32
function Acoes.renomear(s: Sessao, args: any): (boolean, string?)
	if type(args) ~= "table" or type(args.nome) ~= "string" then
		return false, "Pedido inválido."
	end
	local nome = args.nome:gsub("%s+", " "):gsub("^ ", ""):gsub(" $", "")
	if utf8.len(nome) == nil or utf8.len(nome) < NOME_MIN or utf8.len(nome) > NOME_MAX then
		return false, `O nome precisa ter de {NOME_MIN} a {NOME_MAX} letras.`
	end
	if os.clock() - s.ultimoNome < 10 then
		return false, "Espere alguns segundos para trocar o nome de novo."
	end
	s.ultimoNome = os.clock()
	local ok, filtrado = pcall(function()
		local resultado = TextService:FilterStringAsync(nome, s.jogador.UserId, Enum.TextFilterContext.PublicChat)
		return resultado:GetNonChatStringForBroadcastAsync()
	end)
	if not ok then
		return false, "Não deu para conferir o nome agora. Tente de novo daqui a pouco."
	end
	s.mapas[s.mapaAtual].nomeCompanhia = filtrado
	if filtrado ~= nome then
		return true, "Parte do nome foi bloqueada pelo filtro do Roblox."
	end
	return true, "Nome da companhia registrado."
end

function Acoes.tutorial(s: Sessao, args: any): (boolean, string?)
	local dados = MAPAS[s.mapaAtual]
	local e = s.mapas[s.mapaAtual]
	if e.tutorial then
		return false, "O tutorial já acabou."
	end
	if type(args) == "table" and args.pular == true then
		e.tutorial = true
		return true, nil
	end
	local passo = Metas.passoTutorial(e, dados)
	if not passo or passo.id ~= "fim" then
		return false, "Ainda falta um passo do tutorial."
	end
	e.tutorial = true
	e.dinheiro += Metas.PREMIO_TUTORIAL
	ganharXp(s, e, Metas.XP.tutorial)
	return true, `Tutorial concluído: + {Economia.formatar(Metas.PREMIO_TUTORIAL, Economia.moedaDe(dados, e))}`
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
	local ok, texto = acao(s, args)
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
		ganhoOffline = 0,
		eventos = {},
		rng = Random.new(),
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
			local ganho = math.max(-e.dinheiro, Economia.rendaTotal(e, dados) * decorrido)
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
			elseif comando == "estado" then
				return e
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
