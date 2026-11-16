--!strict
-- Metas: contratos com prazo, missões do dia, medalhas e tutorial.
-- Regras puras, como a Economia: o servidor aplica, o cliente só mostra.
-- No jogo, 1 minuto de verdade = 1 dia da ferrovia (os números "por dia" são por minuto jogado).

local Economia = require(script.Parent:WaitForChild("Economia"))

type EstadoMapa = Economia.EstadoMapa

local Metas = {}

Metas.SEGUNDOS_POR_DIA = 60
Metas.VALIDADE_OFERTAS_SEGUNDOS = 10 * 60 -- as ofertas de contrato mudam sozinhas a cada 10 min
Metas.TROCA_OFERTAS_SEGUNDOS = 2 * 60 -- o jogador pode pedir ofertas novas 2 min depois das últimas
Metas.FUSO_SEGUNDOS = -3 * 3600 -- as missões viram à meia-noite de Brasília
Metas.PREMIO_TUTORIAL = 500

-- Experiência (XP) por ação.
Metas.XP = { trecho = 10, linha = 40, trem = 3, estacao = 5, projeto = 60, era = 150, missao = 30, tutorial = 50 }

-- Dificuldade de um contrato: quanto a companhia precisa melhorar, e o prêmio (em minutos do lucro atual).
Metas.DIFICULDADES = {
	{ id = "facil", nome = "Fácil", caixaAlta = "FÁCIL", fator = 1.1, premio = 1.5, xp = 30 },
	{ id = "medio", nome = "Médio", caixaAlta = "MÉDIO", fator = 1.25, premio = 3, xp = 50 },
	{ id = "dificil", nome = "Difícil", caixaAlta = "DIFÍCIL", fator = 1.45, premio = 5, xp = 80 },
}

function Metas.dificuldade(id: string): any
	for _, d in Metas.DIFICULDADES do
		if d.id == id then
			return d
		end
	end
	return Metas.DIFICULDADES[1]
end

-- ---------------------------------------------------------------- contexto (contas feitas uma vez por segundo)

export type Contexto = {
	balanco: Economia.Balanco,
	passageirosDia: number,
	cargaDia: { [string]: number },
}

function Metas.contexto(estado: EstadoMapa, dados: any): Contexto
	local balanco = Economia.balanco(estado, dados)
	return {
		balanco = balanco,
		passageirosDia = Economia.passageirosPorDia(balanco),
		cargaDia = Economia.cargaPorDia(estado, dados, balanco),
	}
end

-- Arredonda para cima, para um número "redondo" de 2 algarismos (1.234 -> 1.300).
local function redondo(n: number): number
	if n <= 0 then
		return 0
	end
	local p = 10 ^ math.max(0, math.floor(math.log10(n)) - 1)
	return math.ceil(n / p) * p
end

local function linhasAtivas(ctx: Contexto): number
	local n = 0
	for _ in ctx.balanco.linhas do
		n += 1
	end
	return n
end

-- Todos os passageiros de todas as linhas conseguem embarcar?
function Metas.todosEmbarcam(ctx: Contexto): boolean
	local alguma = false
	for _, bl in ctx.balanco.linhas do
		alguma = true
		if bl.servico < 1 then
			return false
		end
	end
	return alguma
end

local function acharLinha(dados: any, id: string): any?
	for _, l in dados.linhas do
		if l.id == id then
			return l
		end
	end
	return nil
end

-- ---------------------------------------------------------------- contratos

-- Cada gerador devolve { tipo, alvo?, meta, prazo } ou nil se o contrato não faz sentido agora.
local GERADORES: { [string]: (EstadoMapa, any, Contexto, any, Random) -> any? } = {}

function GERADORES.passageiros(_estado, _dados, ctx, dif, _rng)
	if ctx.passageirosDia <= 0 then
		return nil
	end
	local dias = 5
	return { tipo = "passageiros", meta = redondo(ctx.passageirosDia * dias * dif.fator), prazo = dias * Metas.SEGUNDOS_POR_DIA }
end

function GERADORES.carga(_estado, _dados, ctx, dif, rng)
	local opcoes = {}
	for carga, porDia in ctx.cargaDia do
		if porDia > 0 then
			table.insert(opcoes, carga)
		end
	end
	if #opcoes == 0 then
		return nil
	end
	table.sort(opcoes)
	local carga = opcoes[rng:NextInteger(1, #opcoes)]
	local dias = 5
	return { tipo = "carga", alvo = carga, meta = redondo(ctx.cargaDia[carga] * dias * dif.fator), prazo = dias * Metas.SEGUNDOS_POR_DIA }
end

function GERADORES.lotacao(_estado, _dados, ctx, dif, _rng)
	if linhasAtivas(ctx) < 2 then
		return nil
	end
	local minutos = if dif.id == "facil" then 2 elseif dif.id == "medio" then 3 else 5
	return { tipo = "lotacao", meta = minutos * 60, prazo = math.round(minutos * 60 * 1.5) + 60 }
end

function GERADORES.linha(estado, dados, ctx, dif, _rng)
	-- primeira linha liberada que ainda não está completa
	for i, linha in dados.linhas do
		if Economia.linhaLiberada(estado, dados, i) and not Economia.linhaCompleta(estado, linha) then
			local falta = 0
			for _, t in linha.trechos do
				if not estado.trechos[t.id] then
					falta += Economia.opcaoTrecho(t, nil).custo
				end
			end
			local lucro = ctx.balanco.lucro
			if lucro <= 0 then
				return nil
			end
			local espera = math.max(0, falta - estado.dinheiro) / lucro -- segundos juntando dinheiro, sem gastar em mais nada
			if espera > 12 * 60 then
				return nil
			end
			local folga = if dif.id == "facil" then 2 elseif dif.id == "medio" then 1.4 else 1.1
			local prazo = math.clamp(math.ceil((espera * folga + 60) / 30) * 30, 120, 15 * 60)
			return { tipo = "linha", alvo = linha.id, meta = #linha.trechos, prazo = prazo }
		end
	end
	return nil
end

function GERADORES.satisfacao(_estado, _dados, ctx, dif, _rng)
	local atual = math.floor(ctx.balanco.satisfacao * 100)
	if linhasAtivas(ctx) == 0 or atual >= 88 then
		return nil
	end
	local pontos = if dif.id == "facil" then 4 elseif dif.id == "medio" then 8 else 14
	return { tipo = "satisfacao", meta = math.min(95, atual + pontos), prazo = 5 * Metas.SEGUNDOS_POR_DIA }
end

local TIPOS_CONTRATO = { "passageiros", "carga", "lotacao", "linha", "satisfacao" }

local function embaralhar(lista: { any }, rng: Random)
	for i = #lista, 2, -1 do
		local j = rng:NextInteger(1, i)
		lista[i], lista[j] = lista[j], lista[i]
	end
end

-- Até 3 ofertas, de tipos diferentes: uma fácil, uma média e uma difícil.
function Metas.gerarOfertas(estado: EstadoMapa, dados: any, ctx: Contexto, rng: Random): { any }
	local tipos = table.clone(TIPOS_CONTRATO)
	embaralhar(tipos, rng)
	local ofertas = {}
	local base = os.time() * 10
	for _, tipo in tipos do
		local dif = Metas.DIFICULDADES[#ofertas + 1]
		if not dif then
			break
		end
		local c = GERADORES[tipo](estado, dados, ctx, dif, rng)
		if c and c.meta > 0 then
			c.id = base + #ofertas
			c.dificuldade = dif.id
			c.premio = redondo(math.max(600, ctx.balanco.lucro * 60 * dif.premio))
			c.xp = dif.xp
			c.progresso = 0
			c.decorrido = 0
			table.insert(ofertas, c)
		end
	end
	return ofertas
end

-- Avança o contrato em andamento. Devolve "cumprido", "falhou" ou nil (segue em andamento).
function Metas.avancarContrato(estado: EstadoMapa, dados: any, ctx: Contexto, dt: number): string?
	local c = estado.contrato
	if not c then
		return nil
	end
	c.decorrido += dt
	if c.tipo == "passageiros" then
		c.progresso += ctx.passageirosDia / Metas.SEGUNDOS_POR_DIA * dt
	elseif c.tipo == "carga" then
		c.progresso += (ctx.cargaDia[c.alvo] or 0) / Metas.SEGUNDOS_POR_DIA * dt
	elseif c.tipo == "lotacao" then
		if Metas.todosEmbarcam(ctx) then
			c.progresso += dt
		end
	elseif c.tipo == "linha" then
		local linha = acharLinha(dados, c.alvo)
		c.progresso = if linha then Economia.trechosConstruidos(estado, linha) else c.meta
	elseif c.tipo == "satisfacao" then
		c.progresso = math.floor(ctx.balanco.satisfacao * 100)
	end
	if c.progresso >= c.meta then
		return "cumprido"
	end
	if c.decorrido >= c.prazo then
		return "falhou"
	end
	return nil
end

function Metas.relogio(segundos: number): string
	segundos = math.max(0, math.ceil(segundos))
	local h, m, s = segundos // 3600, (segundos % 3600) // 60, segundos % 60
	if h > 0 then
		return string.format("%d:%02d:%02d", h, m, s)
	end
	return string.format("%d:%02d", m, s)
end

-- Texto do contrato: emoji (nome em Emojis), título e explicação de como cumprir.
function Metas.descreverContrato(c: any, dados: any): (string, string, string)
	local n = Economia.numero
	if c.tipo == "passageiros" then
		return "passageiros", `Transporte {n(c.meta)} passageiros`, "Mais trens nas linhas lotadas, estações melhores e trechos novos aumentam os passageiros."
	elseif c.tipo == "carga" then
		local carga = (Economia.CARGAS :: any)[c.alvo]
		return carga.emoji, `Entregue {n(c.meta)} {carga.unidade} de {string.lower(carga.nome)} no porto`, "Melhore as estações produtoras e não deixe faltar trem nas linhas delas."
	elseif c.tipo == "lotacao" then
		return "trens", `Ninguém na plataforma por {Metas.relogio(c.meta)}`, "O relógio só anda enquanto todas as linhas levam 100% dos passageiros."
	elseif c.tipo == "linha" then
		local linha = acharLinha(dados, c.alvo)
		return "construir", `Complete a linha {if linha then linha.nome else "?"}`, "Junte dinheiro e construa todos os trechos dela antes do prazo."
	elseif c.tipo == "satisfacao" then
		return "satisfacao", `Chegue a {c.meta}% de satisfação`, "Sobe com trens suficientes em todas as linhas e com estações melhores."
	end
	return "menu", "Contrato", ""
end

-- Progresso em texto ("3.200 de 5.000").
function Metas.progressoContrato(c: any): string
	local n = Economia.numero
	if c.tipo == "lotacao" then
		return `{Metas.relogio(c.progresso)} de {Metas.relogio(c.meta)}`
	elseif c.tipo == "satisfacao" then
		return `{math.floor(c.progresso)}% de {c.meta}%`
	elseif c.tipo == "linha" then
		return `{math.floor(c.progresso)} de {c.meta} trechos`
	end
	return `{n(math.floor(c.progresso))} de {n(c.meta)}`
end

-- ---------------------------------------------------------------- missões do dia

function Metas.diaAtual(): number
	return (os.time() + Metas.FUSO_SEGUNDOS) // 86400
end

-- Segundos até as missões virarem.
function Metas.segundosAteVirar(agora: number): number
	return 86400 - (agora + Metas.FUSO_SEGUNDOS) % 86400
end

local MISSOES: { [string]: (EstadoMapa, any, Contexto, Random) -> number? } = {}

function MISSOES.trechos(estado, dados, _ctx, rng)
	local livres = 0
	for i, linha in dados.linhas do
		if Economia.linhaLiberada(estado, dados, i) then
			livres += #linha.trechos - Economia.trechosConstruidos(estado, linha)
		end
	end
	return if livres >= 2 then math.min(livres, rng:NextInteger(2, 3)) else nil
end

function MISSOES.estacoes(estado, dados, _ctx, rng)
	local niveis = 0
	for id in dados.estacoes do
		if Economia.estacaoNaRede(estado, dados, id) then
			niveis += #Economia.NIVEIS_ESTACAO - Economia.nivelEstacao(estado, id)
		end
	end
	return if niveis >= 2 then math.min(niveis, rng:NextInteger(2, 3)) else nil
end

function MISSOES.contratos(_estado, _dados, ctx, rng)
	return if linhasAtivas(ctx) > 0 then rng:NextInteger(1, 2) else nil
end

function MISSOES.lucro(_estado, _dados, ctx, _rng)
	return if ctx.balanco.lucro > 0 then redondo(math.max(1000, ctx.balanco.lucro * 300)) else nil
end

function MISSOES.passageiros(_estado, _dados, ctx, _rng)
	return if ctx.passageirosDia > 0 then redondo(ctx.passageirosDia * 8) else nil
end

function MISSOES.trens(estado, dados, _ctx, _rng)
	local faltando = 0
	for _, linha in dados.linhas do
		faltando += Economia.trensFaltando(estado, dados, linha)
	end
	return if faltando >= 1 then math.min(faltando, 2) else nil
end

function MISSOES.estudo(estado, dados, _ctx, _rng)
	for _, p in dados.projetos or {} do
		if Economia.situacaoProjeto(estado, dados, p) == "disponivel" then
			return 1
		end
	end
	return nil
end

local TIPOS_MISSAO = { "trechos", "estacoes", "contratos", "lucro", "passageiros", "trens", "estudo" }
-- Missões que valem para quem ainda não construiu nada.
local MISSOES_INICIAIS = { { tipo = "trechos", meta = 3 }, { tipo = "trens", meta = 1 }, { tipo = "contratos", meta = 1 } }

-- 3 missões para o dia, escolhidas pelo que a companhia consegue fazer hoje.
function Metas.gerarMissoes(estado: EstadoMapa, dados: any, ctx: Contexto, rng: Random): { any }
	local tipos = table.clone(TIPOS_MISSAO)
	embaralhar(tipos, rng)
	local premio = redondo(math.max(400, ctx.balanco.lucro * 90))
	local lista = {}
	for _, tipo in tipos do
		if #lista >= 3 then
			break
		end
		local meta = MISSOES[tipo](estado, dados, ctx, rng)
		if meta and meta > 0 then
			table.insert(lista, { tipo = tipo, meta = meta, progresso = 0, premio = premio, xp = Metas.XP.missao, resgatada = false })
		end
	end
	for _, inicial in MISSOES_INICIAIS do
		if #lista >= 3 then
			break
		end
		local repetida = false
		for _, m in lista do
			repetida = repetida or m.tipo == inicial.tipo
		end
		if not repetida then
			table.insert(lista, { tipo = inicial.tipo, meta = inicial.meta, progresso = 0, premio = premio, xp = Metas.XP.missao, resgatada = false })
		end
	end
	return lista
end

-- Soma n nos totais da companhia e nas missões do dia desse tipo.
function Metas.contar(estado: EstadoMapa, tipo: string, n: number)
	estado.contadores[tipo] = (estado.contadores[tipo] or 0) + n
	for _, m in estado.missoes.lista do
		if m.tipo == tipo and m.progresso < m.meta then
			m.progresso = math.min(m.meta, m.progresso + n)
		end
	end
end

function Metas.descreverMissao(m: any, simbolo: string?): (string, string)
	local n = Economia.numero
	if m.tipo == "trechos" then
		return "construir", `Construa {m.meta} {if m.meta == 1 then "trecho" else "trechos"}`
	elseif m.tipo == "estacoes" then
		return "estacoes", `Melhore estações {m.meta} {if m.meta == 1 then "vez" else "vezes"}`
	elseif m.tipo == "contratos" then
		return "menu", `Cumpra {m.meta} {if m.meta == 1 then "contrato" else "contratos"}`
	elseif m.tipo == "lucro" then
		return "dinheiro", `Lucre {Economia.formatar(m.meta, simbolo)}`
	elseif m.tipo == "passageiros" then
		return "passageiros", `Transporte {n(m.meta)} passageiros`
	elseif m.tipo == "trens" then
		return "trens", `Compre {m.meta} {if m.meta == 1 then "trem" else "trens"}`
	elseif m.tipo == "estudo" then
		return "gabinete", "Comece um estudo no Gabinete"
	end
	return "missoes", "Missão"
end

-- Alguma missão pronta esperando o jogador resgatar?
function Metas.missaoParaResgatar(estado: any): boolean
	for _, m in (estado.missoes or {}).lista or {} do
		if m.progresso >= m.meta and not m.resgatada then
			return true
		end
	end
	return false
end

-- ---------------------------------------------------------------- medalhas

local function totalTrechos(estado: EstadoMapa): number
	local n = 0
	for _ in estado.trechos do
		n += 1
	end
	return n
end

Metas.MEDALHAS = {
	{
		id = "primeiro_apito", nome = "Primeiro apito", emoji = "trens", xp = 20,
		descricao = "Construa o seu primeiro trecho.",
		teste = function(estado: EstadoMapa, _dados: any, _ctx: Contexto): boolean
			return totalTrechos(estado) >= 1
		end,
	},
	{
		id = "linha_inaugurada", nome = "Linha inaugurada", emoji = "linhas", xp = 30,
		descricao = "Complete uma linha com mais de um trecho.",
		teste = function(estado: EstadoMapa, dados: any, _ctx: Contexto): boolean
			for _, linha in dados.linhas do
				if #linha.trechos >= 2 and Economia.linhaCompleta(estado, linha) then
					return true
				end
			end
			return false
		end,
	},
	{
		id = "cafe_no_porto", nome = "Café no porto", emoji = "carga_cafe", xp = 30,
		descricao = "Ligue uma cidade do café a um porto.",
		teste = function(_estado: EstadoMapa, _dados: any, ctx: Contexto): boolean
			return (ctx.cargaDia.cafe or 0) > 0
		end,
	},
	{
		id = "minerio_no_porto", nome = "Ferro para o mundo", emoji = "carga_minerio", xp = 40,
		descricao = "Ligue uma mina a um porto.",
		teste = function(_estado: EstadoMapa, _dados: any, ctx: Contexto): boolean
			return (ctx.cargaDia.minerio or 0) > 0
		end,
	},
	{
		id = "graos_no_porto", nome = "Celeiro do país", emoji = "carga_graos", xp = 50,
		descricao = "Ligue uma região de grãos a um porto.",
		teste = function(_estado: EstadoMapa, _dados: any, ctx: Contexto): boolean
			return (ctx.cargaDia.graos or 0) > 0
		end,
	},
	{
		id = "frota_10", nome = "Dez locomotivas", emoji = "era_vapor", xp = 30,
		descricao = "Tenha 10 trens rodando.",
		teste = function(estado: EstadoMapa, _dados: any, _ctx: Contexto): boolean
			local n = 0
			for _, t in estado.trens do
				n += t
			end
			return n >= 10
		end,
	},
	{
		id = "grande_estacao", nome = "Grande estação", emoji = "estacoes", xp = 50,
		descricao = "Leve uma estação ao nível máximo.",
		teste = function(estado: EstadoMapa, _dados: any, _ctx: Contexto): boolean
			for _, nivel in estado.estacoes do
				if nivel >= #Economia.NIVEIS_ESTACAO then
					return true
				end
			end
			return false
		end,
	},
	{
		id = "ninguem_na_plataforma", nome = "Ninguém na plataforma", emoji = "passageiros", xp = 40,
		descricao = "Tenha 4 linhas rodando, todas levando 100% dos passageiros.",
		teste = function(_estado: EstadoMapa, _dados: any, ctx: Contexto): boolean
			return linhasAtivas(ctx) >= 4 and Metas.todosEmbarcam(ctx)
		end,
	},
	{
		id = "passageiros_felizes", nome = "Passageiros felizes", emoji = "satisfacao", xp = 60,
		descricao = "Chegue a 90% de satisfação.",
		teste = function(_estado: EstadoMapa, _dados: any, ctx: Contexto): boolean
			return linhasAtivas(ctx) >= 2 and ctx.balanco.satisfacao >= 0.9
		end,
	},
	{
		id = "adeus_vapor", nome = "Adeus, vapor", emoji = "era_diesel", xp = 60,
		descricao = "Modernize a companhia para a próxima era.",
		teste = function(estado: EstadoMapa, _dados: any, _ctx: Contexto): boolean
			return Economia.indiceEra(estado) >= 2
		end,
	},
	{
		id = "do_papel_ao_trilho", nome = "Do papel ao trilho", emoji = "gabinete", xp = 40,
		descricao = "Conclua um estudo no Gabinete de Projetos.",
		teste = function(estado: EstadoMapa, dados: any, _ctx: Contexto): boolean
			for _, p in dados.projetos or {} do
				if Economia.projetoConcluido(estado, p.id) then
					return true
				end
			end
			return false
		end,
	},
	{
		id = "obra_entregue", nome = "Obra entregue", emoji = "construir", xp = 80,
		descricao = "Complete uma ferrovia que só existia no papel.",
		teste = function(estado: EstadoMapa, dados: any, _ctx: Contexto): boolean
			for _, linha in dados.linhas do
				if linha.projeto and Economia.linhaCompleta(estado, linha) then
					return true
				end
			end
			return false
		end,
	},
	{
		id = "malha_integrada", nome = "Malha integrada", emoji = "conectar", xp = 60,
		descricao = "Tenha uma linha ligada a 5 cidades grandes de outras linhas.",
		teste = function(_estado: EstadoMapa, _dados: any, ctx: Contexto): boolean
			for _, bl in ctx.balanco.linhas do
				if bl.rede >= 5 then
					return true
				end
			end
			return false
		end,
	},
	{
		id = "palavra_cumprida", nome = "Palavra cumprida", emoji = "menu", xp = 60,
		descricao = "Cumpra 10 contratos.",
		teste = function(estado: EstadoMapa, _dados: any, _ctx: Contexto): boolean
			return (estado.contadores.contratos or 0) >= 10
		end,
	},
	{
		id = "primeiro_milhao", nome = "Primeiro milhão", emoji = "dinheiro", xp = 80,
		descricao = "Junte 1 milhão no caixa.",
		teste = function(estado: EstadoMapa, _dados: any, _ctx: Contexto): boolean
			return estado.dinheiro >= 1e6
		end,
	},
	{
		id = "pais_nos_trilhos", nome = "O país nos trilhos", emoji = "mapa_mundo", xp = 150,
		descricao = "Complete todas as linhas do mapa.",
		teste = function(estado: EstadoMapa, dados: any, _ctx: Contexto): boolean
			return Economia.linhasCompletas(estado, dados) == #dados.linhas
		end,
	},
}

-- Medalhas que a companhia acabou de merecer (ainda não registradas no estado).
function Metas.novasMedalhas(estado: EstadoMapa, dados: any, ctx: Contexto): { any }
	local novas = {}
	for _, m in Metas.MEDALHAS do
		if not estado.medalhas[m.id] and m.teste(estado, dados, ctx) then
			table.insert(novas, m)
		end
	end
	return novas
end

function Metas.acharMedalha(id: string): any?
	for _, m in Metas.MEDALHAS do
		if m.id == id then
			return m
		end
	end
	return nil
end

-- ---------------------------------------------------------------- tutorial

export type PassoTutorial = {
	id: string,
	indice: number,
	total: number,
	texto: string,
	acao: string?, -- "linha" (mostrar no mapa), "aba" (abrir uma aba do menu) ou "concluir"
	alvo: string?,
	botao: string?,
}

-- Passo atual do tutorial, decidido pelo que o jogador já fez. nil = tutorial encerrado.
function Metas.passoTutorial(estado: any, dados: any): PassoTutorial?
	if estado.tutorial then
		return nil
	end
	local total = 5
	local primeira, segunda = dados.linhas[1], dados.linhas[2]
	if Economia.trechosConstruidos(estado, primeira) == 0 then
		return {
			id = "primeiro", indice = 1, total = total, acao = "linha", alvo = primeira.id, botao = "Mostrar no mapa",
			texto = `Bem-vindo à sua companhia! Toque no trilho da {primeira.nome} e assine a concessão: é o seu primeiro trecho.`,
		}
	end
	if segunda and Economia.trechosConstruidos(estado, segunda) == 0 then
		return {
			id = "segunda", indice = 2, total = total, acao = "linha", alvo = segunda.id, botao = "Mostrar no mapa",
			texto = `A primeira linha já rende. Agora comece a {segunda.nome}: cidades grandes dão muito mais passageiros.`,
		}
	end
	if (estado.contadores or {}).trens == nil then
		for _, linha in dados.linhas do
			if Economia.trensFaltando(estado, dados, linha) > 0 then
				return {
					id = "trem", indice = 3, total = total, acao = "linha", alvo = linha.id, botao = "Mostrar no mapa",
					texto = `A {linha.nome} está lotada: tem passageiro ficando na plataforma. Toque num trecho dela e compre um trem.`,
				}
			end
		end
	end
	local melhorou = false
	for _, nivel in estado.estacoes or {} do
		melhorou = melhorou or nivel > 0
	end
	if not melhorou then
		-- aponta a maior cidade que já tem trilho
		local maior: string? = nil
		for _, linha in dados.linhas do
			for _, t in linha.trechos do
				if estado.trechos[t.id] then
					for _, id in { t.de, t.para } do
						if not maior or dados.estacoes[id].porte > dados.estacoes[maior].porte then
							maior = id
						end
					end
				end
			end
		end
		return {
			id = "estacao", indice = 4, total = total, acao = "estacao", alvo = maior, botao = "Mostrar no mapa",
			texto = "Toque numa cidade (a bolinha no mapa) para abrir a ficha dela e melhore a estação: mais passageiros e mais renda.",
		}
	end
	if not estado.contrato and ((estado.contadores or {}).contratos or 0) == 0 then
		return {
			id = "contrato", indice = 5, total = total, acao = "aba", alvo = "metas", botao = "Abrir Contratos",
			texto = "Agora aceite um contrato: cumprir contratos e missões dá prêmios e faz a companhia subir de nível.",
		}
	end
	return {
		id = "fim", indice = total, total = total, acao = "concluir", botao = `Concluir · + {Economia.formatar(Metas.PREMIO_TUTORIAL, dados.simbolo)}`,
		texto = "Pronto! Complete linhas para liberar as próximas, estude projetos no Gabinete e fique de olho no lucro de cada linha. Boa viagem!",
	}
end

return Metas
