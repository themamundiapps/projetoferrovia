-- Tarifas.luau · preço das passagens por classe e serviço de bordo (uma tabela para a companhia toda).
--
-- Cada trem leva três classes. Cada cidade manda uma mistura de passageiros: metrópoles e cidades
-- ricas (café, açúcar, borracha) mandam mais gente de 1ª classe; vilas mandam mais 3ª.
--
-- Preço (p, de 0,5 a 2 vezes o normal) e procura (d) de cada classe:
--     d = 1 - k' × (p - 1),   k' = sensibilidade / (1 + tolerância dos serviços)
-- A receita da classe é p × d: tem um ponto ótimo em p* = (1 + k') / (2 k'). A 3ª classe é sensível
-- (ótimo perto do normal), a 1ª quase não liga (aguenta uns 160%). O serviço de bordo aumenta a
-- tolerância e a satisfação, mas custa uma parte da manutenção dos trens.
-- Preço acima do "justo" derruba a satisfação; passagem popular (abaixo do normal) sobe um pouco.
-- Com tudo no normal e nenhum serviço, os fatores dão exatamente 1 (a economia de antes).
--
-- Módulo puro (sem require): Economia usa estas funções; o menu usa os textos.

local Tarifas = {}

Tarifas.CLASSES = 3
Tarifas.MIN, Tarifas.MAX, Tarifas.PASSO = 0.5, 2, 0.1
Tarifas.SENSIBILIDADE = { 0.45, 0.7, 1.0 } -- 1ª, 2ª, 3ª
Tarifas.JUSTO = { 1.4, 1.2, 1.1 } -- acima disso (mais a tolerância) o passageiro reclama
Tarifas.PENALIDADE = 0.5 -- satisfação perdida por ponto acima do justo (pesado pela mistura)
Tarifas.BONUS_POPULAR = 0.3 -- satisfação ganha por ponto abaixo do normal
Tarifas.DEMANDA_MIN, Tarifas.DEMANDA_MAX = 0.05, 1.5

-- Nome das classes em cada era (índice da era: vapor, diesel, elétrica, alta velocidade).
Tarifas.NOMES = {
	{ pt = { "1ª classe", "2ª classe", "3ª classe" }, en = { "First class", "Second class", "Third class" } },
	{ pt = { "Pullman", "1ª classe", "2ª classe" }, en = { "Pullman", "First class", "Second class" } },
	{ pt = { "Executiva", "Turística", "Econômica" }, en = { "Business", "Tourist", "Economy" } },
	{ pt = { "Business", "Conforto", "Econômica" }, en = { "Business", "Comfort", "Economy" } },
}

export type Servico = {
	id: string,
	era: number, -- era em que passa a existir
	emoji: string,
	nome: { pt: string, en: string },
	desc: { pt: string, en: string },
	tol: { number }, -- tolerância a preço por classe (1ª, 2ª, 3ª)
	sat: number, -- satisfação somada
	custo: number, -- fração da manutenção dos trens
}

Tarifas.SERVICOS = {
	{
		id = "restaurante", era = 1, emoji = "satisfacao",
		nome = { pt = "Vagão-restaurante", en = "Dining car" },
		desc = { pt = "Refeições quentes na 1ª e na 2ª classe.", en = "Hot meals in first and second class." },
		tol = { 0.15, 0.15, 0 }, sat = 0.04, custo = 0.12,
	},
	{
		id = "leito", era = 1, emoji = "companhia",
		nome = { pt = "Carro-leito", en = "Sleeping car" },
		desc = { pt = "Cabines com cama: a 1ª classe aceita pagar bem mais.", en = "Cabins with beds: first class will pay much more." },
		tol = { 0.5, 0, 0 }, sat = 0.02, custo = 0.10,
	},
	{
		id = "bagagem", era = 1, emoji = "cargas",
		nome = { pt = "Carregadores de bagagem", en = "Porters" },
		desc = { pt = "Ajudam com as malas na 1ª e na 2ª.", en = "Help with luggage in first and second class." },
		tol = { 0.1, 0.25, 0 }, sat = 0.02, custo = 0.05,
	},
	{
		id = "bancos", era = 1, emoji = "estacoes",
		nome = { pt = "Bancos estofados na 3ª", en = "Padded seats in third" },
		desc = { pt = "Fim do banco de madeira: a 3ª classe agradece.", en = "No more wooden benches: third class is grateful." },
		tol = { 0, 0, 0.25 }, sat = 0.04, custo = 0.08,
	},
	{
		id = "radio", era = 2, emoji = "jornal",
		nome = { pt = "Rádio a bordo", en = "Onboard radio" },
		desc = { pt = "Música e notícias em todos os vagões.", en = "Music and news in every car." },
		tol = { 0.05, 0.1, 0.1 }, sat = 0.03, custo = 0.05,
	},
	{
		id = "ar", era = 2, emoji = "configuracoes",
		nome = { pt = "Ar-condicionado", en = "Air conditioning" },
		desc = { pt = "Viagem fresca no calor brasileiro.", en = "A cool ride in the Brazilian heat." },
		tol = { 0.2, 0.2, 0.1 }, sat = 0.05, custo = 0.15,
	},
	{
		id = "poltronas", era = 3, emoji = "estacoes",
		nome = { pt = "Poltronas reclináveis", en = "Reclining seats" },
		desc = { pt = "Conforto para as viagens longas.", en = "Comfort for long journeys." },
		tol = { 0.1, 0.2, 0.15 }, sat = 0.04, custo = 0.08,
	},
	{
		id = "wifi", era = 4, emoji = "configuracoes",
		nome = { pt = "Wi-fi a bordo", en = "Onboard wi-fi" },
		desc = { pt = "Internet do começo ao fim da linha.", en = "Internet from end to end of the line." },
		tol = { 0.15, 0.15, 0.15 }, sat = 0.05, custo = 0.06,
	},
} :: { Servico }

Tarifas.PorId = {} :: { [string]: Servico }
for _, s in Tarifas.SERVICOS do
	Tarifas.PorId[s.id] = s
end

-- Cargas cujas cidades têm mais gente endinheirada (barões do café, do açúcar e da borracha).
Tarifas.CARGAS_RICAS = { cafe = true, acucar = true, borracha = true }

export type EstadoTarifas = { precos: { number }, servicos: { [string]: boolean } }

function Tarifas.padrao(): EstadoTarifas
	return { precos = { 1, 1, 1 }, servicos = {} }
end

function Tarifas.arredondar(p: number): number
	p = math.floor(p / Tarifas.PASSO + 0.5) * Tarifas.PASSO
	return math.clamp(math.floor(p * 100 + 0.5) / 100, Tarifas.MIN, Tarifas.MAX)
end

-- Do save para o estado: só preços válidos e serviços que existem.
function Tarifas.sanear(salvo: any): EstadoTarifas
	local t = Tarifas.padrao()
	if type(salvo) ~= "table" then
		return t
	end
	if type(salvo.precos) == "table" then
		for c = 1, Tarifas.CLASSES do
			local p = salvo.precos[c]
			if type(p) == "number" and p == p then
				t.precos[c] = Tarifas.arredondar(p)
			end
		end
	end
	if type(salvo.servicos) == "table" then
		for id, v in salvo.servicos do
			if type(id) == "string" and v == true and Tarifas.PorId[id] then
				t.servicos[id] = true
			end
		end
	end
	return t
end

local function estado(t: EstadoTarifas?): EstadoTarifas
	return t or Tarifas.padrao()
end

-- Serviço vale só a partir da era dele (contratar antes não tem efeito nem custo).
function Tarifas.ativo(t: EstadoTarifas?, id: string, era: number): boolean
	local s = Tarifas.PorId[id]
	return s ~= nil and s.era <= era and estado(t).servicos[id] == true
end

-- Mistura de passageiros de uma cidade: fração de 1ª, 2ª e 3ª classe.
-- Eras mais modernas têm mais classe média (2ª cresce, 3ª encolhe).
function Tarifas.mistura(estacao: any, era: number): { number }
	local porte = estacao and estacao.porte or 1
	local rica = estacao and estacao.produz and Tarifas.CARGAS_RICAS[estacao.produz] and 1 or 0
	local s1 = 0.05 + 0.02 * (porte - 1) + 0.03 * rica + 0.01 * (era - 1)
	local s2 = 0.22 + 0.02 * (porte - 1) + 0.02 * rica + 0.05 * (era - 1)
	return { s1, s2, 1 - s1 - s2 }
end

-- Mistura de um trecho: média das duas pontas.
function Tarifas.misturaTrecho(dados: any, trecho: any, era: number): { number }
	local a = Tarifas.mistura(dados.estacoes[trecho.de], era)
	local b = Tarifas.mistura(dados.estacoes[trecho.para], era)
	return { (a[1] + b[1]) / 2, (a[2] + b[2]) / 2, (a[3] + b[3]) / 2 }
end

-- Tolerância a preço de cada classe, somando os serviços ativos.
function Tarifas.tolerancia(t: EstadoTarifas?, era: number): { number }
	local tol = { 0, 0, 0 }
	for _, s in Tarifas.SERVICOS do
		if Tarifas.ativo(t, s.id, era) then
			for c = 1, Tarifas.CLASSES do
				tol[c] += s.tol[c]
			end
		end
	end
	return tol
end

-- Procura de uma classe ao preço p (1 = como era antes).
function Tarifas.demanda(c: number, p: number, tol: number): number
	local k = Tarifas.SENSIBILIDADE[c] / (1 + tol)
	return math.clamp(1 - k * (p - 1), Tarifas.DEMANDA_MIN, Tarifas.DEMANDA_MAX)
end

-- Preço que dá mais receita numa classe (com os serviços atuais).
function Tarifas.precoOtimo(c: number, tol: number): number
	local k = Tarifas.SENSIBILIDADE[c] / (1 + tol)
	return Tarifas.arredondar((1 + k) / (2 * k))
end

-- Fatores sobre passageiros e sobre a receita de passageiros, para uma mistura.
function Tarifas.fatores(t: EstadoTarifas?, mistura: { number }, era: number, tol: { number }?): (number, number)
	local e = estado(t)
	local tl = tol or Tarifas.tolerancia(e, era)
	local fp, fr = 0, 0
	for c = 1, Tarifas.CLASSES do
		local p = e.precos[c] or 1
		local d = Tarifas.demanda(c, p, tl[c])
		fp += mistura[c] * d
		fr += mistura[c] * d * p
	end
	return fp, fr
end

-- Quanto as tarifas mexem na satisfação (de -1 a +1, somado à satisfação de 0 a 1).
-- Serviços somam; preço acima do justo tira; passagem popular dá um pouco.
function Tarifas.ajusteSatisfacao(t: EstadoTarifas?, mistura: { number }, era: number): number
	local e = estado(t)
	local tol = Tarifas.tolerancia(e, era)
	local ajuste = 0
	for _, s in Tarifas.SERVICOS do
		if Tarifas.ativo(e, s.id, era) then
			ajuste += s.sat
		end
	end
	for c = 1, Tarifas.CLASSES do
		local p = e.precos[c] or 1
		local justo = Tarifas.JUSTO[c] + 0.8 * tol[c]
		ajuste -= mistura[c] * math.max(0, p - justo) * Tarifas.PENALIDADE
		ajuste += mistura[c] * math.max(0, 1 - p) * Tarifas.BONUS_POPULAR
	end
	return ajuste
end

-- Custo dos serviços: fração somada sobre a manutenção dos trens.
function Tarifas.custoServicos(t: EstadoTarifas?, era: number): number
	local total = 0
	for _, s in Tarifas.SERVICOS do
		if Tarifas.ativo(t, s.id, era) then
			total += s.custo
		end
	end
	return total
end

function Tarifas.nomeClasse(c: number, era: number, idioma: string?): string
	local n = Tarifas.NOMES[math.clamp(era, 1, #Tarifas.NOMES)]
	local lista = if idioma == "en" then n.en else n.pt
	return lista[c]
end

return Tarifas
