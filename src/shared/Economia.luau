--!strict
-- Economia: regras puras (sem efeitos colaterais), usadas pelo servidor para decidir
-- e pelo cliente para mostrar previsões. Valores provisórios, ajustados nos playtests.

local Economia = {}

Economia.DINHEIRO_INICIAL = 1000
Economia.PAYBACK_SEGUNDOS = 30 -- um trecho paga o próprio custo em ~30 s com serviço em 100%
Economia.TRECHOS_POR_TREM = 2 -- cada linha precisa de 1 trem a cada 2 trechos construídos
Economia.FATOR_CUSTO_TREM = 0.4 -- trem custa 40% do custo médio dos trechos da linha
Economia.OFFLINE_MAX_SEGUNDOS = 2 * 60 * 60

-- Cargas: cada cidade produtora ligada por trilho até um porto dá um bônus na renda da linha dela.
Economia.CARGAS = {
	cafe = { nome = "Café", emoji = "carga_cafe", bonus = 0.25 },
	minerio = { nome = "Minério", emoji = "carga_minerio", bonus = 0.6 },
}

-- Estações: cada nível aumenta a renda dos trechos que chegam nela.
Economia.NIVEIS_ESTACAO = {
	{ nome = "Plataforma coberta", emoji = "estacoes" },
	{ nome = "Armazém", emoji = "cargas" },
	{ nome = "Restaurante", emoji = "satisfacao" },
	{ nome = "Hotel", emoji = "companhia" },
	{ nome = "Grande estação", emoji = "prestigio" },
}
Economia.BONUS_POR_NIVEL = 0.08
Economia.CUSTO_BASE_ESTACAO = 60 -- por porte da cidade, no nível 1 da primeira linha

-- Eras: a próxima libera com N linhas completas e multiplica a renda de tudo.
Economia.ERAS = {
	{ id = "vapor", multiplicador = 1, custo = 0, linhasCompletas = 0 },
	{ id = "diesel", multiplicador = 2, custo = 60000, linhasCompletas = 4 },
}

-- Estado salvo de um jogador em um mapa.
export type EstadoMapa = {
	dinheiro: number,
	trechos: { [string]: string }, -- id do trecho -> id da alternativa escolhida ("padrao" se não houver)
	trens: { [string]: number }, -- id da linha -> quantidade de trens
	era: string, -- id da era atual
	estacoes: { [string]: number }, -- id da estação -> nível (0 a 5)
	ultimoTick: number, -- os.time() do último cálculo de renda
}

function Economia.estadoNovo(): EstadoMapa
	return { dinheiro = Economia.DINHEIRO_INICIAL, trechos = {}, trens = {}, era = "vapor", estacoes = {}, ultimoTick = os.time() }
end

-- Custo e alternativa efetivos de um trecho (com a escolha de traçado, se houver).
function Economia.opcaoTrecho(trecho: any, alternativaId: string?): any
	if trecho.alternativas then
		for _, alt in trecho.alternativas do
			if alt.id == alternativaId then
				return alt
			end
		end
		return trecho.alternativas[1]
	end
	return trecho
end

function Economia.rendaTrecho(trecho: any, alternativaId: string?): number
	local opcao = Economia.opcaoTrecho(trecho, alternativaId)
	local demanda = opcao.fatorDemanda or 1
	return opcao.custo / Economia.PAYBACK_SEGUNDOS * demanda
end

function Economia.trechosConstruidos(estado: EstadoMapa, linha: any): number
	local n = 0
	for _, t in linha.trechos do
		if estado.trechos[t.id] then
			n += 1
		end
	end
	return n
end

function Economia.linhaCompleta(estado: EstadoMapa, linha: any): boolean
	return Economia.trechosConstruidos(estado, linha) == #linha.trechos
end

-- Linhas abrem em ordem histórica: a próxima só libera quando a anterior estiver completa.
function Economia.linhaLiberada(estado: EstadoMapa, dados: any, indiceLinha: number): boolean
	if indiceLinha <= 1 then
		return true
	end
	return Economia.linhaCompleta(estado, dados.linhas[indiceLinha - 1])
end

export type SituacaoTrecho = "construido" | "disponivel" | "bloqueado"

-- Dentro da linha, os trechos são construídos em sequência.
function Economia.situacaoTrecho(estado: EstadoMapa, dados: any, indiceLinha: number, indiceTrecho: number): SituacaoTrecho
	local linha = dados.linhas[indiceLinha]
	local trecho = linha.trechos[indiceTrecho]
	if estado.trechos[trecho.id] then
		return "construido"
	end
	if not Economia.linhaLiberada(estado, dados, indiceLinha) then
		return "bloqueado"
	end
	if indiceTrecho > 1 and not estado.trechos[linha.trechos[indiceTrecho - 1].id] then
		return "bloqueado"
	end
	return "disponivel"
end

function Economia.trensNecessarios(estado: EstadoMapa, linha: any): number
	return math.ceil(Economia.trechosConstruidos(estado, linha) / Economia.TRECHOS_POR_TREM)
end

function Economia.servico(estado: EstadoMapa, linha: any): number
	local necessarios = Economia.trensNecessarios(estado, linha)
	if necessarios == 0 then
		return 0
	end
	return math.min(1, (estado.trens[linha.id] or 0) / necessarios)
end

-- Preço fixo por linha: 40% do custo médio dos trechos dela.
function Economia.custoTrem(_estado: EstadoMapa, linha: any): number
	local soma = 0
	for _, t in linha.trechos do
		soma += t.custo
	end
	return math.round(soma / #linha.trechos * Economia.FATOR_CUSTO_TREM)
end

-- Quantos trens faltam para a linha rodar a 100%. A frota nunca passa disso.
function Economia.trensFaltando(estado: EstadoMapa, linha: any): number
	return math.max(0, Economia.trensNecessarios(estado, linha) - (estado.trens[linha.id] or 0))
end

function Economia.podeComprarTrem(estado: EstadoMapa, linha: any): boolean
	return Economia.trechosConstruidos(estado, linha) > 0 and Economia.trensFaltando(estado, linha) > 0
end

-- Corrige a frota salva: nunca acima do necessário, e ao menos 1 trem se a linha tem trechos.
function Economia.ajustarFrota(estado: EstadoMapa, dados: any)
	for _, linha in dados.linhas do
		local necessarios = Economia.trensNecessarios(estado, linha)
		local atual = estado.trens[linha.id] or 0
		if necessarios == 0 then
			estado.trens[linha.id] = nil
		else
			estado.trens[linha.id] = math.clamp(atual, 1, necessarios)
		end
	end
end

-- ---------------------------------------------------------------- eras

function Economia.indiceEra(estado: EstadoMapa): number
	for i, era in Economia.ERAS do
		if era.id == estado.era then
			return i
		end
	end
	return 1
end

function Economia.multiplicadorEra(estado: EstadoMapa): number
	return Economia.ERAS[Economia.indiceEra(estado)].multiplicador
end

function Economia.linhasCompletas(estado: EstadoMapa, dados: any): number
	local n = 0
	for _, linha in dados.linhas do
		if Economia.linhaCompleta(estado, linha) then
			n += 1
		end
	end
	return n
end

-- Próxima era e se já está liberada (pelas linhas completas). O dinheiro é checado à parte.
function Economia.proximaEra(estado: EstadoMapa, dados: any): (any?, boolean)
	local proxima = Economia.ERAS[Economia.indiceEra(estado) + 1]
	if not proxima then
		return nil, false
	end
	return proxima, Economia.linhasCompletas(estado, dados) >= proxima.linhasCompletas
end

-- ---------------------------------------------------------------- estações

function Economia.nivelEstacao(estado: EstadoMapa, id: string): number
	return estado.estacoes[id] or 0
end

-- Estação faz parte da rede se algum trecho construído chega nela.
function Economia.estacaoNaRede(estado: EstadoMapa, dados: any, id: string): boolean
	for _, linha in dados.linhas do
		for _, t in linha.trechos do
			if estado.trechos[t.id] and (t.de == id or t.para == id) then
				return true
			end
		end
	end
	return false
end

-- Ordem (1, 2, 3...) da primeira linha histórica que passa pela estação: cidades de linhas tardias custam mais.
local function ordemEstacao(dados: any, id: string): number
	for i, linha in dados.linhas do
		for _, t in linha.trechos do
			if t.de == id or t.para == id then
				return i
			end
		end
	end
	return 1
end

function Economia.custoMelhoria(estado: EstadoMapa, dados: any, id: string): number?
	local nivel = Economia.nivelEstacao(estado, id)
	if nivel >= #Economia.NIVEIS_ESTACAO then
		return nil
	end
	local e = dados.estacoes[id]
	local base = Economia.CUSTO_BASE_ESTACAO * e.porte * (1.7 ^ (ordemEstacao(dados, id) - 1))
	return math.round(base * (2 ^ nivel))
end

local function fatorEstacoes(estado: EstadoMapa, t: any): number
	return 1 + Economia.BONUS_POR_NIVEL * (Economia.nivelEstacao(estado, t.de) + Economia.nivelEstacao(estado, t.para))
end

-- ---------------------------------------------------------------- satisfação

-- 70% vem do serviço das linhas (trens), 30% do nível médio das estações da rede. Vai de 0 a 1.
function Economia.satisfacao(estado: EstadoMapa, dados: any): number
	local servicoPeso, peso = 0, 0
	local niveis, nEst = 0, 0
	local contada: { [string]: boolean } = {}
	for _, linha in dados.linhas do
		local n = Economia.trechosConstruidos(estado, linha)
		if n > 0 then
			servicoPeso += Economia.servico(estado, linha) * n
			peso += n
			for _, t in linha.trechos do
				if estado.trechos[t.id] then
					for _, id in { t.de, t.para } do
						if not contada[id] then
							contada[id] = true
							niveis += Economia.nivelEstacao(estado, id)
							nEst += 1
						end
					end
				end
			end
		end
	end
	if peso == 0 then
		return 0.5
	end
	local servico = servicoPeso / peso
	local nivelMedio = if nEst > 0 then niveis / nEst / #Economia.NIVEIS_ESTACAO else 0
	return math.clamp(0.7 * servico + 0.3 * nivelMedio, 0, 1)
end

-- Satisfação mexe na renda de tudo: de -15% (0%) a +15% (100%).
function Economia.fatorSatisfacao(estado: EstadoMapa, dados: any): number
	return 0.85 + 0.3 * Economia.satisfacao(estado, dados)
end

-- ---------------------------------------------------------------- cargas

-- Estações ligadas a algum porto por trilho construído (busca em largura a partir dos portos).
function Economia.conectadasAoPorto(estado: EstadoMapa, dados: any): { [string]: boolean }
	local vizinhos: { [string]: { string } } = {}
	for _, linha in dados.linhas do
		for _, t in linha.trechos do
			if estado.trechos[t.id] then
				vizinhos[t.de] = vizinhos[t.de] or {}
				vizinhos[t.para] = vizinhos[t.para] or {}
				table.insert(vizinhos[t.de], t.para)
				table.insert(vizinhos[t.para], t.de)
			end
		end
	end
	local visitado: { [string]: boolean } = {}
	local fila: { string } = {}
	for id, e in dados.estacoes do
		if e.porto and vizinhos[id] then
			visitado[id] = true
			table.insert(fila, id)
		end
	end
	local i = 1
	while i <= #fila do
		for _, v in vizinhos[fila[i]] do
			if not visitado[v] then
				visitado[v] = true
				table.insert(fila, v)
			end
		end
		i += 1
	end
	return visitado
end

export type InfoCarga = { estacao: string, carga: string, conectada: boolean }

-- Produtoras de cada linha (cada estação conta só na primeira linha, em ordem histórica, que a alcança).
function Economia.cargasPorLinha(estado: EstadoMapa, dados: any): { [string]: { InfoCarga } }
	local conectadas = Economia.conectadasAoPorto(estado, dados)
	local jaContada: { [string]: boolean } = {}
	local r: { [string]: { InfoCarga } } = {}
	for _, linha in dados.linhas do
		local lista: { InfoCarga } = {}
		for _, t in linha.trechos do
			if estado.trechos[t.id] then
				for _, id in { t.de, t.para } do
					local e = dados.estacoes[id]
					if e.produz and Economia.CARGAS[e.produz] and not jaContada[id] then
						jaContada[id] = true
						table.insert(lista, { estacao = id, carga = e.produz, conectada = conectadas[id] == true })
					end
				end
			end
		end
		r[linha.id] = lista
	end
	return r
end

function Economia.bonusCarga(lista: { InfoCarga }): number
	local b = 0
	for _, info in lista do
		if info.conectada then
			b += Economia.CARGAS[info.carga].bonus
		end
	end
	return b
end

-- ---------------------------------------------------------------- renda

function Economia.rendaLinha(estado: EstadoMapa, linha: any, cargas: { InfoCarga }?): number
	local bruta = 0
	for _, t in linha.trechos do
		local alt = estado.trechos[t.id]
		if alt then
			bruta += Economia.rendaTrecho(t, alt) * fatorEstacoes(estado, t)
		end
	end
	local bonus = if cargas then Economia.bonusCarga(cargas) else 0
	return bruta * Economia.servico(estado, linha) * (1 + bonus) * Economia.multiplicadorEra(estado)
end

function Economia.rendaTotal(estado: EstadoMapa, dados: any): number
	local cargas = Economia.cargasPorLinha(estado, dados)
	local total = 0
	for _, linha in dados.linhas do
		total += Economia.rendaLinha(estado, linha, cargas[linha.id])
	end
	return total * Economia.fatorSatisfacao(estado, dados)
end

-- Renda de uma linha já com a satisfação aplicada (para mostrar no painel).
function Economia.rendaLinhaFinal(estado: EstadoMapa, dados: any, linha: any): number
	local cargas = Economia.cargasPorLinha(estado, dados)
	return Economia.rendaLinha(estado, linha, cargas[linha.id]) * Economia.fatorSatisfacao(estado, dados)
end

-- ---------------------------------------------------------------- estatísticas (para o painel da companhia)

function Economia.estatisticas(estado: EstadoMapa, dados: any): any
	local trechos, total = 0, 0
	local passageiros = 0
	for _, linha in dados.linhas do
		local servico = Economia.servico(estado, linha)
		for _, t in linha.trechos do
			total += 1
			if estado.trechos[t.id] then
				trechos += 1
				local a, b = dados.estacoes[t.de], dados.estacoes[t.para]
				local opcao = Economia.opcaoTrecho(t, estado.trechos[t.id])
				passageiros += (a.porte + b.porte) * opcao.km * 15 * (opcao.fatorDemanda or 1) * fatorEstacoes(estado, t) * servico
			end
		end
	end
	local cafe, minerio = 0, 0
	for _, lista in Economia.cargasPorLinha(estado, dados) do
		for _, info in lista do
			if info.conectada then
				local porte = dados.estacoes[info.estacao].porte
				if info.carga == "cafe" then
					cafe += porte * 400
				elseif info.carga == "minerio" then
					minerio += porte * 900
				end
			end
		end
	end
	local estacoes = 0
	for id in dados.estacoes do
		if Economia.estacaoNaRede(estado, dados, id) then
			estacoes += 1
		end
	end
	return {
		renda = Economia.rendaTotal(estado, dados),
		trechos = trechos,
		trechosTotal = total,
		linhasCompletas = Economia.linhasCompletas(estado, dados),
		linhasTotal = #dados.linhas,
		estacoes = estacoes,
		passageirosDia = math.round(passageiros),
		cafeDia = cafe,
		minerioDia = minerio,
		satisfacao = Economia.satisfacao(estado, dados),
	}
end

-- Localiza um trecho pelo id: retorna linha, índice da linha, trecho, índice do trecho.
function Economia.acharTrecho(dados: any, trechoId: string): (any, number, any, number)
	for i, linha in dados.linhas do
		for j, t in linha.trechos do
			if t.id == trechoId then
				return linha, i, t, j
			end
		end
	end
	return nil, 0, nil, 0
end

-- Formata dinheiro no padrão brasileiro: R$ 7.195 / R$ 9,22 / R$ 1,2 mi
function Economia.formatar(valor: number, simbolo: string?, decimais: boolean?): string
	local s = simbolo or "R$"
	local abs = math.abs(valor)
	local sinal = if valor < 0 then "-" else ""
	local limites = { 1e12, 1e9, 1e6 }
	local nomes = { "tri", "bi", "mi" }
	for i, limite in limites do
		if abs >= limite then
			local txt = string.format("%.1f", abs / limite):gsub("%.", ",")
			return `{sinal}{s} {txt} {nomes[i]}`
		end
	end
	if decimais and abs < 1000 then
		local txt = string.format("%.2f", abs):gsub("%.", ",")
		return `{sinal}{s} {txt}`
	end
	local inteiro = tostring(math.floor(abs + 0.5))
	local comPontos = inteiro:reverse():gsub("(%d%d%d)", "%1."):reverse():gsub("^%.", "")
	return `{sinal}{s} {comPontos}`
end

return Economia
