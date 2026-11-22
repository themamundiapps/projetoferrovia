--!strict
-- Jornal da Companhia: eventos de época que mudam a economia por alguns minutos.
-- O servidor sorteia (só com o jogo aberto); o efeito vai salvo no próprio evento (ver Economia.EventoAtivo).
-- Os eventos ruins que dá para resolver têm um preço: pagar encerra o evento na hora.

local Economia = require(script.Parent:WaitForChild("Economia"))

type EstadoMapa = Economia.EstadoMapa

local Jornal = {}

Jornal.PRIMEIRO_EVENTO = 4 * 60 -- segundos de jogo até a primeira notícia
Jornal.INTERVALO_MIN = 5 * 60 -- entre uma notícia e a próxima
Jornal.INTERVALO_MAX = 8 * 60
Jornal.MAX_ATIVOS = 2
Jornal.MAX_EDICOES = 12 -- notícias guardadas em "edições anteriores"
Jornal.TRECHOS_MINIMOS = 4 -- antes disso a companhia é pequena demais para sair no jornal
Jornal.CUSTO_RESOLVER_SEGUNDOS = 45 -- resolver custa ~45 s do lucro atual (no mínimo R$ 1.000)

-- Nome do jornal em cada era.
-- Nome do jornal nos EUA, por era.
Jornal.NOMES_EUA = {
	vapor = { pt = "Gazeta da Ferrovia", en = "The Railroad Gazette" },
	diesel = { pt = "Notícias dos Trilhos", en = "The Rail News" },
	eletrico = { pt = "Diário da Linha", en = "The Line Daily" },
	alta = { pt = "Trilhos Online", en = "Rails Online" },
}

Jornal.NOMES_EUROPA = {
	vapor = { pt = "Gazeta Ferroviária Continental", en = "The Continental Railway Gazette" },
	diesel = { pt = "Correio dos Trilhos", en = "The Rail Courier" },
	eletrico = { pt = "Diário Europeu da Linha", en = "The European Line Daily" },
	alta = { pt = "Euro Trilhos", en = "Euro Rails" },
}

function Jornal.nome(eraId: string, mapaId: string?): { pt: string, en: string }
	local nomes = if mapaId == "eua" then Jornal.NOMES_EUA elseif mapaId == "europa" then Jornal.NOMES_EUROPA else Jornal.NOMES
	return (nomes :: any)[eraId] or nomes.vapor
end

Jornal.NOMES = {
	vapor = { pt = "Gazeta da Corte", en = "The Court Gazette" },
	diesel = { pt = "Correio Ferroviário", en = "The Railway Post" },
	eletrico = { pt = "Jornal dos Trilhos", en = "The Rail Journal" },
	alta = { pt = "Trilhos Online", en = "Rails Online" },
}

export type Definicao = {
	id: string,
	mapa: string?, -- mapa do evento ("brasil", "eua"); nil = Brasil, menos os que servem em todo país (GERAIS)
	eras: { string }?, -- nil = todas
	peso: number,
	duracao: number, -- segundos
	tipo: string, -- ver Economia.EventoAtivo
	mult: number,
	resolvivel: boolean?,
	titulo: { pt: string, en: string }, -- %s = nome do alvo (linha, cidade ou região)
	texto: { pt: string, en: string },
	-- escolhe o alvo; devolve nil se o evento não faz sentido agora (e ele não é sorteado)
	alvo: ((estado: EstadoMapa, dados: any, rng: Random) -> (string?, string?))?,
}

local function linhaConstruida(estado: EstadoMapa, dados: any, rng: Random): (string?, string?)
	local opcoes = {}
	for _, linha in dados.linhas do
		if Economia.trechosConstruidos(estado, linha) > 0 then
			table.insert(opcoes, linha)
		end
	end
	if #opcoes == 0 then
		return nil, nil
	end
	local l = opcoes[rng:NextInteger(1, #opcoes)]
	return l.id, l.nome
end

local function cargaNoPorto(carga: string): (EstadoMapa, any, Random) -> (string?, string?)
	return function(estado, dados, _rng)
		for _, lista in Economia.cargasPorLinha(estado, dados) do
			for _, info in lista do
				if info.carga == carga and info.conectada then
					return carga, (Economia.CARGAS :: any)[carga].nome
				end
			end
		end
		return nil, nil
	end
end

local function cidadeNaRede(id: string): (EstadoMapa, any, Random) -> (string?, string?)
	return function(estado, dados, _rng)
		if Economia.estacaoNaRede(estado, dados, id) then
			return id, dados.estacoes[id].nome
		end
		return nil, nil
	end
end

local function regiaoNaRede(regiao: string): (EstadoMapa, any, Random) -> (string?, string?)
	return function(estado, dados, _rng)
		for id, e in dados.estacoes do
			if e.regiao == regiao and Economia.estacaoNaRede(estado, dados, id) then
				return regiao, dados.regioes[regiao].pt
			end
		end
		return nil, nil
	end
end

local function semAlvo(_estado: EstadoMapa, _dados: any, _rng: Random): (string?, string?)
	return "", ""
end

Jornal.EVENTOS = {
	-- ---------------------------------------------------------------- bons
	{
		id = "safra_cafe", eras = { "vapor", "diesel" }, peso = 3, duracao = 180, tipo = "carga", mult = 1.6,
		alvo = cargaNoPorto("cafe"),
		titulo = { pt = "Safra recorde de café!", en = "Record coffee harvest!" },
		texto = { pt = "Os cafezais nunca deram tanto. As linhas que levam café ao porto rendem 60% a mais.", en = "The coffee plantations have never yielded so much. Lines carrying coffee to port earn 60% more." },
	},
	{
		id = "imperador", eras = { "vapor" }, peso = 2, duracao = 120, tipo = "geral", mult = 1.25,
		alvo = semAlvo,
		titulo = { pt = "Sua Majestade viaja de trem", en = "His Majesty travels by train" },
		texto = { pt = "Dom Pedro II elogia a companhia e todo mundo quer andar de trem: +25% em toda a receita.", en = "Emperor Pedro II praises the company and everyone wants to ride the train: +25% on all income." },
	},
	{
		id = "imigrantes", eras = { "vapor", "diesel" }, peso = 2, duracao = 180, tipo = "regiao", mult = 1.35,
		alvo = regiaoNaRede("se"),
		titulo = { pt = "Navios de imigrantes chegam a Santos", en = "Immigrant ships arrive in Santos" },
		texto = { pt = "Milhares de famílias seguem para o interior. As linhas do %s rendem 35% a mais.", en = "Thousands of families head inland. Lines in the %s earn 35% more." },
	},
	{
		id = "exposicao", eras = { "vapor", "diesel" }, peso = 2, duracao = 150, tipo = "cidade", mult = 1.5,
		alvo = cidadeNaRede("rio"),
		titulo = { pt = "Exposição Nacional no Rio de Janeiro", en = "National Exhibition in Rio de Janeiro" },
		texto = { pt = "Visitantes de todo o país lotam os trens: as linhas que chegam ao %s rendem 50% a mais.", en = "Visitors from all over the country pack the trains: lines reaching %s earn 50% more." },
	},
	{
		id = "borracha", eras = { "vapor" }, peso = 2, duracao = 180, tipo = "carga", mult = 1.8,
		alvo = cargaNoPorto("borracha"),
		titulo = { pt = "A borracha vale ouro", en = "Rubber is worth its weight in gold" },
		texto = { pt = "As fábricas do mundo querem borracha. A linha que a leva ao porto rende 80% a mais.", en = "The world's factories want rubber. The line carrying it to port earns 80% more." },
	},
	{
		id = "carnaval", peso = 2, duracao = 120, tipo = "cidade", mult = 1.5,
		alvo = cidadeNaRede("rio"),
		titulo = { pt = "É Carnaval!", en = "It's Carnival!" },
		texto = { pt = "Todo mundo quer ir para o %s. As linhas que chegam lá rendem 50% a mais.", en = "Everyone wants to go to %s. Lines reaching it earn 50% more." },
	},
	{
		id = "esforco_guerra", eras = { "diesel" }, peso = 2, duracao = 180, tipo = "carga", mult = 1.8,
		alvo = cargaNoPorto("minerio"),
		titulo = { pt = "Esforço de guerra: minério em alta", en = "War effort: iron ore in demand" },
		texto = { pt = "Os Aliados compram todo o ferro que o Brasil puder mandar. As linhas do minério rendem 80% a mais.", en = "The Allies buy all the iron Brazil can ship. Ore lines earn 80% more." },
	},
	{
		id = "copa", eras = { "diesel", "alta" }, peso = 2, duracao = 150, tipo = "geral", mult = 1.3,
		alvo = semAlvo,
		titulo = { pt = "A Copa do Mundo é no Brasil!", en = "The World Cup is in Brazil!" },
		texto = { pt = "Torcedores viajam de cidade em cidade: +30% em toda a receita.", en = "Fans travel from city to city: +30% on all income." },
	},
	{
		id = "soja", eras = { "eletrico", "alta" }, peso = 3, duracao = 180, tipo = "carga", mult = 1.7,
		alvo = cargaNoPorto("graos"),
		titulo = { pt = "Supersafra de grãos no cerrado", en = "Bumper grain harvest in the cerrado" },
		texto = { pt = "Silos cheios de soja e milho. As linhas que levam grãos ao porto rendem 70% a mais.", en = "Silos full of soy and corn. Lines carrying grain to port earn 70% more." },
	},
	{
		id = "olimpiada", eras = { "alta" }, peso = 2, duracao = 150, tipo = "cidade", mult = 1.6,
		alvo = cidadeNaRede("rio"),
		titulo = { pt = "Jogos Olímpicos no Rio", en = "Olympic Games in Rio" },
		texto = { pt = "O mundo inteiro vem ao %s. As linhas que chegam lá rendem 60% a mais.", en = "The whole world comes to %s. Lines reaching it earn 60% more." },
	},
	-- ---------------------------------------------------------------- ruins
	{
		id = "enchente", peso = 3, duracao = 180, tipo = "linha", mult = 0.4, resolvivel = true,
		alvo = linhaConstruida,
		titulo = { pt = "Enchente danifica a linha %s", en = "Flood damages the %s line" },
		texto = { pt = "O rio subiu e levou parte do aterro: a linha roda a 40% até o conserto.", en = "The river rose and washed out part of the embankment: the line runs at 40% until repaired." },
	},
	{
		id = "greve", peso = 2, duracao = 180, tipo = "manutencao", mult = 1.6, resolvivel = true,
		alvo = semAlvo,
		titulo = { pt = "Greve dos ferroviários", en = "Railway workers on strike" },
		texto = { pt = "Os maquinistas pedem aumento. Enquanto não houver acordo, a manutenção custa 60% a mais.", en = "The drivers want a raise. Until there's a deal, upkeep costs 60% more." },
	},
	{
		id = "geada", eras = { "vapor", "diesel" }, peso = 2, duracao = 180, tipo = "carga", mult = 0.6,
		alvo = cargaNoPorto("cafe"),
		titulo = { pt = "Geada queima os cafezais", en = "Frost burns the coffee plantations" },
		texto = { pt = "Pouco café para levar ao porto: as linhas do café rendem 40% a menos.", en = "Little coffee to take to port: coffee lines earn 40% less." },
	},
	{
		id = "febre_amarela", eras = { "vapor" }, peso = 2, duracao = 150, tipo = "cidade", mult = 0.6,
		alvo = cidadeNaRede("santos"),
		titulo = { pt = "Febre amarela em %s", en = "Yellow fever in %s" },
		texto = { pt = "Os navios evitam o porto e os passageiros somem: as linhas que chegam lá rendem 40% a menos.", en = "Ships avoid the port and passengers vanish: lines reaching it earn 40% less." },
	},
	{
		id = "crise_petroleo", eras = { "eletrico" }, peso = 2, duracao = 180, tipo = "manutencao", mult = 1.5,
		titulo = { pt = "Crise do petróleo", en = "Oil crisis" },
		texto = { pt = "O preço do petróleo dispara e tudo fica mais caro: a manutenção sobe 50%.", en = "Oil prices soar and everything gets dearer: upkeep rises 50%." },
		alvo = semAlvo,
	},
	{
		id = "apagao", eras = { "eletrico", "alta" }, peso = 2, duracao = 150, tipo = "geral", mult = 0.7, resolvivel = true,
		alvo = semAlvo,
		titulo = { pt = "Apagão!", en = "Blackout!" },
		texto = { pt = "Falta luz em boa parte do país e os trens elétricos param: −30% em toda a receita até religar.", en = "Power is out across much of the country and electric trains stop: −30% on all income until it's back." },
	},
	-- ================================================================ EUA (mapa = "eua")
	{
		id = "eua_ouro", mapa = "eua", eras = { "vapor" }, peso = 2, duracao = 150, tipo = "cidade", mult = 1.5,
		alvo = cidadeNaRede("san_francisco"),
		titulo = { pt = "Corrida do ouro!", en = "Gold rush!" },
		texto = { pt = "Garimpeiros do mundo inteiro querem chegar a %s. As linhas que chegam lá rendem 50% a mais.", en = "Prospectors from all over the world want to reach %s. Lines reaching it earn 50% more." },
	},
	{
		id = "eua_boiadas", mapa = "eua", eras = { "vapor", "diesel" }, peso = 3, duracao = 180, tipo = "carga", mult = 1.6,
		alvo = cargaNoPorto("gado"),
		titulo = { pt = "As boiadas do Texas chegam aos trilhos", en = "The Texas cattle drives reach the rails" },
		texto = { pt = "Caubóis tocam milhares de cabeças até as estações. As linhas do gado rendem 60% a mais.", en = "Cowboys drive thousands of head to the stations. Cattle lines earn 60% more." },
	},
	{
		id = "eua_trigo", mapa = "eua", peso = 3, duracao = 180, tipo = "carga", mult = 1.7,
		alvo = cargaNoPorto("graos"),
		titulo = { pt = "Supersafra de trigo nas Grandes Planícies", en = "Bumper wheat crop on the Great Plains" },
		texto = { pt = "Os silos transbordam. As linhas que levam grãos rendem 70% a mais.", en = "The elevators are overflowing. Grain lines earn 70% more." },
	},
	{
		id = "eua_exposicao", mapa = "eua", eras = { "vapor" }, peso = 2, duracao = 150, tipo = "cidade", mult = 1.5,
		alvo = cidadeNaRede("chicago"),
		titulo = { pt = "Exposição Mundial em Chicago", en = "World's Fair in Chicago" },
		texto = { pt = "Milhões de visitantes vêm ver a roda-gigante e a luz elétrica: as linhas que chegam a %s rendem 50% a mais.", en = "Millions come to see the Ferris wheel and electric light: lines reaching %s earn 50% more." },
	},
	{
		id = "eua_petroleo", mapa = "eua", eras = { "vapor", "diesel" }, peso = 2, duracao = 180, tipo = "carga", mult = 1.8,
		alvo = cargaNoPorto("petroleo"),
		titulo = { pt = "Jorra petróleo no Texas!", en = "Oil gushes in Texas!" },
		texto = { pt = "Um poço novo jorra dia e noite e os vagões-tanque não dão conta: as linhas do petróleo rendem 80% a mais.", en = "A new well gushes day and night and the tank cars can't keep up: oil lines earn 80% more." },
	},
	{
		id = "eua_guerra", mapa = "eua", eras = { "diesel" }, peso = 2, duracao = 180, tipo = "carga", mult = 1.8,
		alvo = cargaNoPorto("aco"),
		titulo = { pt = "Esforço de guerra: o país precisa de aço", en = "War effort: the nation needs steel" },
		texto = { pt = "As usinas trabalham sem parar e os trens também: as linhas do aço rendem 80% a mais.", en = "The mills run around the clock and so do the trains: steel lines earn 80% more." },
	},
	{
		id = "eua_inverno", mapa = "eua", eras = { "vapor", "diesel" }, peso = 2, duracao = 180, tipo = "carga", mult = 1.6,
		alvo = cargaNoPorto("carvao"),
		titulo = { pt = "Inverno rigoroso: todo mundo quer carvão", en = "Harsh winter: everyone wants coal" },
		texto = { pt = "As cidades do Norte precisam de carvão para se aquecer. As linhas do carvão rendem 60% a mais.", en = "Northern cities need coal for heat. Coal lines earn 60% more." },
	},
	{
		id = "eua_imigrantes", mapa = "eua", eras = { "vapor", "diesel" }, peso = 2, duracao = 180, tipo = "regiao", mult = 1.35,
		alvo = regiaoNaRede("ne"),
		titulo = { pt = "Navios de imigrantes chegam a Nova York", en = "Immigrant ships arrive in New York" },
		texto = { pt = "Milhares de famílias passam por Ellis Island e seguem de trem. As linhas do %s rendem 35% a mais.", en = "Thousands of families pass through Ellis Island and go on by train. Lines in the %s earn 35% more." },
	},
	{
		id = "eua_feira_ny", mapa = "eua", eras = { "diesel" }, peso = 2, duracao = 150, tipo = "cidade", mult = 1.5,
		alvo = cidadeNaRede("new_york"),
		titulo = { pt = "Feira Mundial de Nova York", en = "New York World's Fair" },
		texto = { pt = "\"O mundo de amanhã\" atrai visitantes de todo o país: as linhas que chegam a %s rendem 50% a mais.", en = "\"The World of Tomorrow\" draws visitors from across the country: lines reaching %s earn 50% more." },
	},
	{
		id = "eua_olimpiada", mapa = "eua", eras = { "eletrico", "alta" }, peso = 2, duracao = 150, tipo = "cidade", mult = 1.6,
		alvo = cidadeNaRede("los_angeles"),
		titulo = { pt = "Jogos Olímpicos em Los Angeles", en = "Olympic Games in Los Angeles" },
		texto = { pt = "O mundo inteiro vem a %s. As linhas que chegam lá rendem 60% a mais.", en = "The whole world comes to %s. Lines reaching it earn 60% more." },
	},
	{
		id = "eua_copa", mapa = "eua", eras = { "alta" }, peso = 2, duracao = 150, tipo = "geral", mult = 1.3,
		alvo = semAlvo,
		titulo = { pt = "A Copa do Mundo é nos Estados Unidos!", en = "The World Cup is in the United States!" },
		texto = { pt = "Torcedores viajam de cidade em cidade para ver os jogos: +30% em toda a receita.", en = "Fans travel from city to city to see the matches: +30% on all income." },
	},
	{
		id = "eua_poeira", mapa = "eua", eras = { "diesel" }, peso = 2, duracao = 180, tipo = "carga", mult = 0.6,
		alvo = cargaNoPorto("graos"),
		titulo = { pt = "Tempestades de poeira nas planícies", en = "Dust storms on the plains" },
		texto = { pt = "A seca levanta nuvens de poeira e as colheitas somem: as linhas dos grãos rendem 40% a menos.", en = "Drought raises clouds of dust and the crops vanish: grain lines earn 40% less." },
	},
	{
		id = "eua_febre", mapa = "eua", eras = { "vapor" }, peso = 2, duracao = 150, tipo = "cidade", mult = 0.6,
		alvo = cidadeNaRede("new_orleans"),
		titulo = { pt = "Febre amarela em %s", en = "Yellow fever in %s" },
		texto = { pt = "A cidade entra em quarentena e os passageiros somem: as linhas que chegam lá rendem 40% a menos.", en = "The city goes into quarantine and passengers vanish: lines reaching it earn 40% less." },
	},
	{
		id = "eua_nevasca", mapa = "eua", peso = 2, duracao = 180, tipo = "linha", mult = 0.4, resolvivel = true,
		alvo = linhaConstruida,
		titulo = { pt = "Nevasca bloqueia a linha %s", en = "Blizzard blocks the %s line" },
		texto = { pt = "A neve cobriu os trilhos: a linha roda a 40% até os limpa-neves passarem.", en = "Snow buried the tracks: the line runs at 40% until the snowplows get through." },
	},
} :: { Definicao }

function Jornal.acharEvento(id: string): Definicao?
	for _, def in Jornal.EVENTOS do
		if def.id == id then
			return def
		end
	end
	return nil
end

-- Notícias que servem em qualquer país (as outras sem `mapa` são do Brasil).
local GERAIS = { enchente = true, greve = true, crise_petroleo = true, apagao = true }

local function doMapa(def: Definicao, mapaId: string?): boolean
	if GERAIS[def.id] then
		return true
	end
	return (def.mapa or "brasil") == (mapaId or "brasil")
end

local function vale(def: Definicao, eraId: string): boolean
	if not def.eras then
		return true
	end
	for _, e in def.eras do
		if e == eraId then
			return true
		end
	end
	return false
end

-- Sorteia um evento que faça sentido agora (sem repetir um que já está em vigor). nil = nenhum serve.
function Jornal.sortear(estado: EstadoMapa, dados: any, rng: Random): (Economia.EventoAtivo?, Definicao?)
	local ativos: { [string]: boolean } = {}
	for _, ev in Economia.eventosAtivos(estado) do
		ativos[ev.id] = true
	end
	local opcoes: { { def: Definicao, alvo: string? } } = {}
	local total = 0
	for _, def in Jornal.EVENTOS do
		if vale(def, estado.era) and doMapa(def, dados.id) and not ativos[def.id] and def.alvo then
			local alvo = def.alvo(estado, dados, rng)
			if alvo then
				table.insert(opcoes, { def = def, alvo = if alvo == "" then nil else alvo })
				total += def.peso
			end
		end
	end
	if total <= 0 then
		return nil, nil
	end
	local sorteio = rng:NextNumber() * total
	for _, op in opcoes do
		sorteio -= op.def.peso
		if sorteio <= 0 then
			local agora = os.time()
			return {
				id = op.def.id,
				tipo = op.def.tipo,
				alvo = op.alvo,
				mult = op.def.mult,
				inicio = agora,
				fim = agora + op.def.duracao,
			}, op.def
		end
	end
	return nil, nil
end

-- Nome do alvo para o texto: linha, cidade, região ou carga.
function Jornal.nomeAlvo(ev: { tipo: string, alvo: string? }, dados: any, idioma: string?): string
	local alvo = ev.alvo
	if not alvo then
		return ""
	end
	if ev.tipo == "linha" then
		for _, l in dados.linhas do
			if l.id == alvo then
				return l.nome
			end
		end
	elseif ev.tipo == "cidade" then
		return dados.estacoes[alvo] and dados.estacoes[alvo].nome or alvo
	elseif ev.tipo == "regiao" then
		local r = dados.regioes[alvo]
		return if r then (r :: any)[idioma or "pt"] or r.pt else alvo
	elseif ev.tipo == "carga" then
		local c = (Economia.CARGAS :: any)[alvo]
		return if c then c.nome else alvo
	end
	return alvo
end

-- Manchete e texto já com o nome do alvo no lugar do %s.
function Jornal.textos(ev: { id: string, tipo: string, alvo: string? }, dados: any, idioma: string?): (string, string)
	local def = Jornal.acharEvento(ev.id)
	if not def then
		return ev.id, ""
	end
	local lingua = idioma or "pt"
	local nome = Jornal.nomeAlvo(ev, dados, lingua)
	local titulo = ((def.titulo :: any)[lingua] or def.titulo.pt):gsub("%%s", function()
		return nome
	end)
	local texto = ((def.texto :: any)[lingua] or def.texto.pt):gsub("%%s", function()
		return nome
	end)
	return titulo, texto
end

function Jornal.custoResolver(lucro: number): number
	local bruto = math.max(1000, lucro * Jornal.CUSTO_RESOLVER_SEGUNDOS)
	local p = 10 ^ math.max(0, math.floor(math.log10(bruto)) - 1)
	return math.ceil(bruto / p) * p
end

return Jornal
