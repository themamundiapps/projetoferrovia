--!strict
-- Economia: regras puras (sem efeitos colaterais), usadas pelo servidor para decidir
-- e pelo cliente para mostrar previsões. Valores provisórios, ajustados nos playtests.

local Economia = {}

Economia.DINHEIRO_INICIAL = 1000
Economia.PAYBACK_SEGUNDOS = 30 -- um trecho paga o próprio custo em ~30 s com serviço em 100%
Economia.TRECHOS_POR_TREM = 2 -- cada linha precisa de 1 trem a cada 2 trechos construídos
Economia.FATOR_CUSTO_TREM = 0.4 -- trem custa 40% do custo médio dos trechos da linha
Economia.OFFLINE_MAX_SEGUNDOS = 2 * 60 * 60

-- Estado salvo de um jogador em um mapa.
export type EstadoMapa = {
	dinheiro: number,
	trechos: { [string]: string }, -- id do trecho -> id da alternativa escolhida ("padrao" se não houver)
	trens: { [string]: number }, -- id da linha -> quantidade de trens
	ultimoTick: number, -- os.time() do último cálculo de renda
}

function Economia.estadoNovo(): EstadoMapa
	return { dinheiro = Economia.DINHEIRO_INICIAL, trechos = {}, trens = {}, ultimoTick = os.time() }
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

function Economia.custoTrem(estado: EstadoMapa, linha: any): number
	local soma = 0
	for _, t in linha.trechos do
		soma += t.custo
	end
	local base = soma / #linha.trechos * Economia.FATOR_CUSTO_TREM
	-- cada trem a mais na mesma linha fica 15% mais caro
	local ja = estado.trens[linha.id] or 0
	return math.round(base * (1.15 ^ math.max(0, ja - 1)))
end

function Economia.rendaLinha(estado: EstadoMapa, linha: any): number
	local bruta = 0
	for _, t in linha.trechos do
		local alt = estado.trechos[t.id]
		if alt then
			bruta += Economia.rendaTrecho(t, alt)
		end
	end
	return bruta * Economia.servico(estado, linha)
end

function Economia.rendaTotal(estado: EstadoMapa, dados: any): number
	local total = 0
	for _, linha in dados.linhas do
		total += Economia.rendaLinha(estado, linha)
	end
	return total
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
