--!strict
-- Economia: regras puras (sem efeitos colaterais), usadas pelo servidor para decidir
-- e pelo cliente para mostrar previsões. Valores provisórios, ajustados nos playtests.

local Economia = {}

Economia.DINHEIRO_INICIAL = 2500
-- Receita bruta de um trecho entre cidades médias: o custo dele a cada PAYBACK segundos.
-- O prazo cresce a cada "degrau" de linha (as linhas mais novas demoram mais para se pagar),
-- e a era seguinte volta a acelerar tudo.
Economia.PAYBACK_SEGUNDOS = 30
Economia.CRESCIMENTO_PAYBACK = 2.5
Economia.FATOR_CUSTO_TREM = 0.4 -- trem custa 40% do custo médio dos trechos da linha
Economia.OFFLINE_MAX_SEGUNDOS = 2 * 60 * 60

-- Demanda: cada cidade "pesa" pelo porte; um trecho gera passageiros pela soma dos pesos das pontas.
Economia.PESO_PORTE = { 1, 2, 3, 5, 8 }
Economia.PESO_REFERENCIA = 6 -- duas cidades de porte 3: receita "normal" do trecho
Economia.PASSAGEIROS_POR_PESO = 60 -- passageiros por hora, por ponto de peso

-- Efeito rede: cada cidade grande (porte 3+) alcançável pelos trilhos, fora da própria linha, dá +3%.
Economia.PORTE_CIDADE_GRANDE = 3
Economia.BONUS_REDE_POR_CIDADE = 0.03
Economia.MAX_CIDADES_REDE = 15

-- Manutenção, por segundo, em fração da receita bruta "normal" do degrau da linha:
-- um trecho custa 10% do que rende; um trem custa 45% do preço dele dividido pelo prazo.
Economia.MANUTENCAO_TRECHO = 0.10
Economia.MANUTENCAO_TREM = 0.45
Economia.REEMBOLSO_TREM = 0.5 -- vender um trem devolve metade do preço
Economia.MAX_TRENS_LINHA = 30

-- Nível da companhia: sobe com experiência (XP) e dá +1% de receita por nível acima do 1.
Economia.NIVEL_MAXIMO = 30
Economia.BONUS_POR_NIVEL_COMPANHIA = 0.01
Economia.TITULOS = {
	{ nivel = 1, nome = "Companhia Local" },
	{ nivel = 3, nome = "Companhia Regional" },
	{ nivel = 6, nome = "Companhia Estadual" },
	{ nivel = 10, nome = "Companhia Nacional" },
	{ nivel = 15, nome = "Grande Companhia" },
	{ nivel = 20, nome = "Império Ferroviário" },
}

-- Produção das cidades produtoras, por dia de jogo, por ponto de porte.
Economia.PRODUCAO_POR_PORTE = { cafe = 400, minerio = 900, graos = 1200, acucar = 500, madeira = 600, gado = 150, borracha = 80 }
Economia.HORAS_DE_OPERACAO = 18 -- os trens rodam 18 h por dia

-- Cargas: cada cidade produtora ligada por trilho até um porto dá um bônus na renda da linha dela.
Economia.CARGAS = {
	cafe = { nome = "Café", emoji = "carga_cafe", bonus = 0.25, unidade = "sacas" },
	minerio = { nome = "Minério", emoji = "carga_minerio", bonus = 0.6, unidade = "t" },
	graos = { nome = "Grãos", emoji = "carga_graos", bonus = 0.4, unidade = "t" },
	acucar = { nome = "Açúcar", emoji = "carga_acucar", bonus = 0.3, unidade = "sacas" },
	madeira = { nome = "Madeira", emoji = "carga_madeira", bonus = 0.3, unidade = "t" },
	gado = { nome = "Gado", emoji = "carga_gado", bonus = 0.3, unidade = "cabeças" },
	borracha = { nome = "Borracha", emoji = "carga_borracha", bonus = 0.6, unidade = "t" },
}
-- Ordem em que as cargas aparecem nas listas.
Economia.ORDEM_CARGAS = { "cafe", "acucar", "minerio", "madeira", "gado", "borracha", "graos" }

-- Gabinete de Projetos: uma pesquisa por vez; acelerar custa até 60% do preço do projeto,
-- proporcional ao tempo que ainda falta.
Economia.FATOR_ACELERAR = 0.6

-- Relógio usado nas pesquisas (os.time no servidor). O cliente troca pelo horário do servidor.
Economia.relogio = function(): number
	return os.time()
end

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
	{ id = "vapor", multiplicador = 1, custo = 0, linhasCompletas = 0, capacidade = 350 },
	{ id = "diesel", multiplicador = 2, custo = 400000, linhasCompletas = 10, capacidade = 700 },
}

-- Estado salvo de um jogador em um mapa.
export type EstadoMapa = {
	dinheiro: number,
	trechos: { [string]: string }, -- id do trecho -> id da alternativa escolhida ("padrao" se não houver)
	trens: { [string]: number }, -- id da linha -> quantidade de trens
	era: string, -- id da era atual
	estacoes: { [string]: number }, -- id da estação -> nível (0 a 5)
	projetos: { [string]: number }, -- id do projeto -> horário (os.time) em que a pesquisa termina
	ultimoTick: number, -- os.time() do último cálculo de renda
	-- metas (ver Metas.luau)
	xp: number, -- experiência da companhia
	medalhas: { [string]: number }, -- id da medalha -> horário em que foi ganha
	contadores: { [string]: number }, -- totais da vida da companhia (trechos, trens, estacoes, contratos, missoes)
	contrato: any?, -- contrato em andamento
	ofertas: { any }, -- contratos oferecidos
	ofertasEm: number, -- horário em que as ofertas foram geradas
	missoes: { dia: number, lista: { any } }, -- missões do dia
	tutorial: boolean, -- tutorial concluído ou pulado
}

function Economia.estadoNovo(): EstadoMapa
	return {
		dinheiro = Economia.DINHEIRO_INICIAL,
		trechos = {},
		trens = {},
		era = "vapor",
		estacoes = {},
		projetos = {},
		ultimoTick = os.time(),
		xp = 0,
		medalhas = {},
		contadores = {},
		contrato = nil,
		ofertas = {},
		ofertasEm = 0,
		missoes = { dia = 0, lista = {} },
		tutorial = false,
	}
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

-- Soma dos pesos das duas cidades de um trecho.
function Economia.pesoTrecho(dados: any, trecho: any): number
	local a, b = dados.estacoes[trecho.de], dados.estacoes[trecho.para]
	return Economia.PESO_PORTE[a.porte] + Economia.PESO_PORTE[b.porte]
end

-- Receita bruta de um trecho por segundo (sem estações, rede, trens, cargas, era ou satisfação).
-- Ligar cidades grandes rende mais que ligar vilas, para o mesmo custo.
-- Prazo (segundos) em que um trecho médio deste degrau paga o próprio custo.
function Economia.prazo(degrau: number?): number
	return Economia.PAYBACK_SEGUNDOS * Economia.CRESCIMENTO_PAYBACK ^ (degrau or 0)
end

function Economia.rendaTrecho(dados: any, trecho: any, alternativaId: string?): number
	local opcao = Economia.opcaoTrecho(trecho, alternativaId)
	local demanda = opcao.fatorDemanda or 1
	local tamanho = math.sqrt(Economia.pesoTrecho(dados, trecho) / Economia.PESO_REFERENCIA)
	return opcao.custo / Economia.prazo(trecho.degrau) * demanda * tamanho
end

-- Manutenção de um trecho construído, por segundo.
function Economia.manutencaoTrecho(trecho: any, alternativaId: string?): number
	return Economia.opcaoTrecho(trecho, alternativaId).custo / Economia.prazo(trecho.degrau) * Economia.MANUTENCAO_TRECHO
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

-- ---------------------------------------------------------------- nível da companhia

-- XP total para chegar a um nível (nível 1 = 0).
function Economia.xpDoNivel(nivel: number): number
	return math.round(50 * (nivel - 1) ^ 1.7)
end

-- Nível atual, XP já ganho dentro do nível e XP que o nível pede (0 no nível máximo).
function Economia.nivel(estado: EstadoMapa): (number, number, number)
	local xp = estado.xp or 0
	local n = 1
	while n < Economia.NIVEL_MAXIMO and xp >= Economia.xpDoNivel(n + 1) do
		n += 1
	end
	if n >= Economia.NIVEL_MAXIMO then
		return n, 0, 0
	end
	local base = Economia.xpDoNivel(n)
	return n, xp - base, Economia.xpDoNivel(n + 1) - base
end

function Economia.tituloNivel(nivel: number): string
	local nome = Economia.TITULOS[1].nome
	for _, t in Economia.TITULOS do
		if nivel >= t.nivel then
			nome = t.nome
		end
	end
	return nome
end

function Economia.fatorNivel(estado: EstadoMapa): number
	local n = Economia.nivel(estado)
	return 1 + Economia.BONUS_POR_NIVEL_COMPANHIA * (n - 1)
end

-- ---------------------------------------------------------------- Gabinete de Projetos

function Economia.acharProjeto(dados: any, id: string): any?
	for _, p in dados.projetos or {} do
		if p.id == id then
			return p
		end
	end
	return nil
end

function Economia.projetoConcluido(estado: EstadoMapa, id: string): boolean
	local fim = (estado.projetos or {})[id]
	return fim ~= nil and Economia.relogio() >= fim
end

-- Pesquisa em andamento (só uma por vez): id e segundos que faltam.
function Economia.pesquisaAtual(estado: EstadoMapa): (string?, number)
	local agora = Economia.relogio()
	local projetos: { [string]: number } = estado.projetos or {}
	for id, fim in projetos do
		if fim > agora then
			return id, fim - agora
		end
	end
	return nil, 0
end

-- Requisitos de um projeto: se estão cumpridos e, se não, o que falta (texto para o jogador).
function Economia.requisitosProjeto(estado: EstadoMapa, dados: any, p: any): (boolean, string?)
	local r = p.requer or {}
	if r.projeto and not Economia.projetoConcluido(estado, r.projeto) then
		local outro = Economia.acharProjeto(dados, r.projeto)
		return false, `Conclua antes o projeto {if outro then outro.nome else r.projeto}.`
	end
	if r.era then
		local precisa, atual = 0, Economia.indiceEra(estado)
		for i, era in Economia.ERAS do
			if era.id == r.era then
				precisa = i
			end
		end
		if atual < precisa then
			return false, `Chegue à era {r.era == "diesel" and "do Diesel" or r.era}.`
		end
	end
	if r.linhasCompletas and Economia.linhasCompletas(estado, dados) < r.linhasCompletas then
		return false, `Complete {r.linhasCompletas} linhas (hoje: {Economia.linhasCompletas(estado, dados)}).`
	end
	return true, nil
end

export type SituacaoProjeto = "concluido" | "pesquisando" | "disponivel" | "ocupado" | "bloqueado"

function Economia.situacaoProjeto(estado: EstadoMapa, dados: any, p: any): SituacaoProjeto
	if Economia.projetoConcluido(estado, p.id) then
		return "concluido"
	end
	local atual = Economia.pesquisaAtual(estado)
	if atual == p.id then
		return "pesquisando"
	end
	if not Economia.requisitosProjeto(estado, dados, p) then
		return "bloqueado"
	end
	if atual then
		return "ocupado"
	end
	return "disponivel"
end

function Economia.custoAcelerar(p: any, restante: number): number
	if restante <= 0 then
		return 0
	end
	return math.max(1, math.ceil(p.custo * Economia.FATOR_ACELERAR * math.min(1, restante / p.segundos)))
end

-- Linhas históricas abrem em ondas (degraus): uma onda libera quando todas as linhas históricas
-- da onda anterior estão completas. Linhas de projeto abrem quando a pesquisa do projeto termina.
-- Devolve os nomes das linhas que ainda faltam completar (vazio = liberada).
function Economia.faltaParaLiberar(estado: EstadoMapa, dados: any, indiceLinha: number): { string }
	local linha = dados.linhas[indiceLinha]
	local falta = {}
	if not linha or linha.projeto or (linha.degrau or 0) <= 0 then
		return falta
	end
	for _, outra in dados.linhas do
		if not outra.projeto and outra.degrau == linha.degrau - 1 and not Economia.linhaCompleta(estado, outra) then
			table.insert(falta, outra.nome)
		end
	end
	return falta
end

function Economia.linhaLiberada(estado: EstadoMapa, dados: any, indiceLinha: number): boolean
	local linha = dados.linhas[indiceLinha]
	if linha and linha.projeto then
		return Economia.projetoConcluido(estado, linha.projeto)
	end
	return #Economia.faltaParaLiberar(estado, dados, indiceLinha) == 0
end

export type SituacaoTrecho = "construido" | "disponivel" | "bloqueado" | "projeto"

-- Dentro da linha, os trechos são construídos em sequência.
function Economia.situacaoTrecho(estado: EstadoMapa, dados: any, indiceLinha: number, indiceTrecho: number): SituacaoTrecho
	local linha = dados.linhas[indiceLinha]
	local trecho = linha.trechos[indiceTrecho]
	if estado.trechos[trecho.id] then
		return "construido"
	end
	if not Economia.linhaLiberada(estado, dados, indiceLinha) then
		return if linha.projeto then "projeto" else "bloqueado"
	end
	if indiceTrecho > 1 and not estado.trechos[linha.trechos[indiceTrecho - 1].id] then
		return "bloqueado"
	end
	return "disponivel"
end

-- ---------------------------------------------------------------- rede

export type Rede = {
	componente: { [string]: number }, -- estação -> pedaço da rede (ilha de trilhos ligados)
	grandes: { [number]: { string } }, -- pedaço -> cidades grandes nele
}

-- Separa a rede em pedaços ligados e lista as cidades grandes de cada um.
function Economia.rede(estado: EstadoMapa, dados: any): Rede
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
	local componente: { [string]: number } = {}
	local grandes: { [number]: { string } } = {}
	local n = 0
	for inicio in vizinhos do
		if not componente[inicio] then
			n += 1
			grandes[n] = {}
			local fila = { inicio }
			componente[inicio] = n
			local i = 1
			while i <= #fila do
				local id = fila[i]
				if dados.estacoes[id].porte >= Economia.PORTE_CIDADE_GRANDE then
					table.insert(grandes[n], id)
				end
				for _, v in vizinhos[id] do
					if not componente[v] then
						componente[v] = n
						table.insert(fila, v)
					end
				end
				i += 1
			end
		end
	end
	return { componente = componente, grandes = grandes }
end

-- Bônus de rede de uma linha: cidades grandes ligadas a ela por trilho que não estão na própria linha.
function Economia.bonusRede(estado: EstadoMapa, dados: any, linha: any, rede: Rede?): (number, number)
	local r = rede or Economia.rede(estado, dados)
	local proprias: { [string]: boolean } = {}
	local comp: number? = nil
	for _, t in linha.trechos do
		if estado.trechos[t.id] then
			proprias[t.de], proprias[t.para] = true, true
			comp = r.componente[t.de]
		end
	end
	if not comp then
		return 1, 0
	end
	local n = 0
	for _, id in r.grandes[comp] do
		if not proprias[id] then
			n += 1
		end
	end
	n = math.min(n, Economia.MAX_CIDADES_REDE)
	return 1 + n * Economia.BONUS_REDE_POR_CIDADE, n
end

-- ---------------------------------------------------------------- passageiros e trens

local function fatorEstacoesTrecho(estado: EstadoMapa, t: any): number
	return 1 + Economia.BONUS_POR_NIVEL * ((estado.estacoes[t.de] or 0) + (estado.estacoes[t.para] or 0))
end

-- Passageiros por hora que um trecho construído gera (estações e rede aumentam; o traçado pode diminuir).
function Economia.passageirosTrecho(estado: EstadoMapa, dados: any, t: any, fatorRede: number): number
	local opcao = Economia.opcaoTrecho(t, estado.trechos[t.id])
	return Economia.PASSAGEIROS_POR_PESO
		* Economia.pesoTrecho(dados, t)
		* fatorEstacoesTrecho(estado, t)
		* (opcao.fatorDemanda or 1)
		* fatorRede
end

function Economia.passageirosLinha(estado: EstadoMapa, dados: any, linha: any, rede: Rede?): number
	local fatorRede = Economia.bonusRede(estado, dados, linha, rede)
	local total = 0
	for _, t in linha.trechos do
		if estado.trechos[t.id] then
			total += Economia.passageirosTrecho(estado, dados, t, fatorRede)
		end
	end
	return math.round(total)
end

-- Lugares por hora que cada trem oferece (trens maiores e mais rápidos a cada era).
function Economia.capacidadeTrem(estado: EstadoMapa): number
	return Economia.ERAS[Economia.indiceEra(estado)].capacidade
end

-- Trens para levar todos os passageiros da linha.
function Economia.trensNecessarios(estado: EstadoMapa, dados: any, linha: any, rede: Rede?): number
	if Economia.trechosConstruidos(estado, linha) == 0 then
		return 0
	end
	return math.max(1, math.ceil(Economia.passageirosLinha(estado, dados, linha, rede) / Economia.capacidadeTrem(estado)))
end

-- Fração dos passageiros que a frota consegue levar (0 a 1).
function Economia.servico(estado: EstadoMapa, dados: any, linha: any, rede: Rede?): number
	local passageiros = Economia.passageirosLinha(estado, dados, linha, rede)
	if passageiros <= 0 then
		return 0
	end
	return math.min(1, (estado.trens[linha.id] or 0) * Economia.capacidadeTrem(estado) / passageiros)
end

-- Preço fixo por linha: 40% do custo médio dos trechos dela.
function Economia.custoTrem(_estado: EstadoMapa, linha: any): number
	local soma = 0
	for _, t in linha.trechos do
		soma += t.custo
	end
	return math.round(soma / #linha.trechos * Economia.FATOR_CUSTO_TREM)
end

function Economia.valorVendaTrem(estado: EstadoMapa, linha: any): number
	return math.round(Economia.custoTrem(estado, linha) * Economia.REEMBOLSO_TREM)
end

function Economia.manutencaoTrem(estado: EstadoMapa, linha: any): number
	return Economia.custoTrem(estado, linha) / Economia.prazo(linha.degrau) * Economia.MANUTENCAO_TREM
end

function Economia.trensFaltando(estado: EstadoMapa, dados: any, linha: any, rede: Rede?): number
	return math.max(0, Economia.trensNecessarios(estado, dados, linha, rede) - (estado.trens[linha.id] or 0))
end

-- Trens sem passageiro (depois de mudar de era, por exemplo): só custam manutenção.
function Economia.trensSobrando(estado: EstadoMapa, dados: any, linha: any, rede: Rede?): number
	return math.max(0, (estado.trens[linha.id] or 0) - Economia.trensNecessarios(estado, dados, linha, rede))
end

-- Compra só até levar todo mundo: trem a mais não dá passageiro.
function Economia.podeComprarTrem(estado: EstadoMapa, dados: any, linha: any, rede: Rede?): boolean
	local trens = estado.trens[linha.id] or 0
	return Economia.trechosConstruidos(estado, linha) > 0
		and trens < Economia.MAX_TRENS_LINHA
		and Economia.trensFaltando(estado, dados, linha, rede) > 0
end

-- Toda linha com trecho fica com ao menos 1 trem.
function Economia.podeVenderTrem(estado: EstadoMapa, linha: any): boolean
	return (estado.trens[linha.id] or 0) > 1
end

-- Corrige a frota salva: entre 1 e o máximo, e nenhum trem em linha sem trecho.
function Economia.ajustarFrota(estado: EstadoMapa, dados: any)
	for _, linha in dados.linhas do
		local atual = estado.trens[linha.id] or 0
		if Economia.trechosConstruidos(estado, linha) == 0 then
			estado.trens[linha.id] = nil
		else
			estado.trens[linha.id] = math.clamp(atual, 1, Economia.MAX_TRENS_LINHA)
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

local fatorEstacoes = fatorEstacoesTrecho

-- ---------------------------------------------------------------- satisfação

-- 70% vem do serviço das linhas (trens), 30% do nível médio das estações da rede. Vai de 0 a 1.
function Economia.satisfacao(estado: EstadoMapa, dados: any, rede: Rede?): number
	rede = rede or Economia.rede(estado, dados)
	local servicoPeso, peso = 0, 0
	local niveis, nEst = 0, 0
	local contada: { [string]: boolean } = {}
	for _, linha in dados.linhas do
		local n = if Economia.trechosConstruidos(estado, linha) > 0 then Economia.passageirosLinha(estado, dados, linha, rede) else 0
		if n > 0 then
			servicoPeso += Economia.servico(estado, dados, linha, rede) * n
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
function Economia.fatorSatisfacao(estado: EstadoMapa, dados: any, rede: Rede?): number
	return 0.85 + 0.3 * Economia.satisfacao(estado, dados, rede)
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

export type BalancoLinha = {
	receita: number, -- já com satisfação e nível da companhia
	manutencao: number,
	lucro: number,
	passageiros: number,
	capacidade: number,
	servico: number,
	rede: number, -- cidades grandes ligadas (efeito rede)
	fatorRede: number,
}

export type Balanco = {
	receita: number,
	manutencao: number,
	lucro: number,
	satisfacao: number,
	linhas: { [string]: BalancoLinha },
}

-- Receita bruta da linha (antes da satisfação e do nível da companhia): trechos × estações × rede × serviço × cargas × era.
function Economia.receitaLinha(estado: EstadoMapa, dados: any, linha: any, cargas: { InfoCarga }?, rede: Rede?): number
	local fatorRede = Economia.bonusRede(estado, dados, linha, rede)
	local bruta = 0
	for _, t in linha.trechos do
		local alt = estado.trechos[t.id]
		if alt then
			bruta += Economia.rendaTrecho(dados, t, alt) * fatorEstacoes(estado, t)
		end
	end
	local bonus = if cargas then Economia.bonusCarga(cargas) else 0
	return bruta * fatorRede * Economia.servico(estado, dados, linha, rede) * (1 + bonus) * Economia.multiplicadorEra(estado)
end

function Economia.manutencaoLinha(estado: EstadoMapa, linha: any): number
	local total = 0
	for _, t in linha.trechos do
		local alt = estado.trechos[t.id]
		if alt then
			total += Economia.manutencaoTrecho(t, alt)
		end
	end
	return total + (estado.trens[linha.id] or 0) * Economia.manutencaoTrem(estado, linha)
end

-- Contas da companhia: receita (com satisfação), manutenção e lucro, no total e por linha.
function Economia.balanco(estado: EstadoMapa, dados: any): Balanco
	local rede = Economia.rede(estado, dados)
	local cargas = Economia.cargasPorLinha(estado, dados)
	local satisfacao = Economia.satisfacao(estado, dados, rede)
	local fatorSat = (0.85 + 0.3 * satisfacao) * Economia.fatorNivel(estado)
	local b: Balanco = { receita = 0, manutencao = 0, lucro = 0, satisfacao = satisfacao, linhas = {} }
	for _, linha in dados.linhas do
		if Economia.trechosConstruidos(estado, linha) > 0 then
			local fatorRede, nRede = Economia.bonusRede(estado, dados, linha, rede)
			local receita = Economia.receitaLinha(estado, dados, linha, cargas[linha.id], rede) * fatorSat
			local manutencao = Economia.manutencaoLinha(estado, linha)
			b.linhas[linha.id] = {
				receita = receita,
				manutencao = manutencao,
				lucro = receita - manutencao,
				passageiros = Economia.passageirosLinha(estado, dados, linha, rede),
				capacidade = (estado.trens[linha.id] or 0) * Economia.capacidadeTrem(estado),
				servico = Economia.servico(estado, dados, linha, rede),
				rede = nRede,
				fatorRede = fatorRede,
			}
			b.receita += receita
			b.manutencao += manutencao
		end
	end
	b.lucro = b.receita - b.manutencao
	return b
end

-- Passageiros levados por dia de jogo (a demanda é por hora; quem não cabe no trem fica de fora).
function Economia.passageirosPorDia(balanco: Balanco): number
	local total = 0
	for _, bl in balanco.linhas do
		total += math.min(bl.passageiros, bl.capacidade) * Economia.HORAS_DE_OPERACAO
	end
	return total
end

-- Carga entregue no porto por dia de jogo, por tipo. Depende do porte e do nível da estação
-- produtora e de quantos trens a linha dela tem (serviço).
function Economia.cargaPorDia(estado: EstadoMapa, dados: any, balanco: Balanco?): { [string]: number }
	local b = balanco or Economia.balanco(estado, dados)
	local r: { [string]: number } = {}
	for carga in Economia.PRODUCAO_POR_PORTE :: { [string]: number } do
		r[carga] = 0
	end
	for linhaId, lista in Economia.cargasPorLinha(estado, dados) do
		local bl = b.linhas[linhaId]
		for _, info in lista do
			local base = (Economia.PRODUCAO_POR_PORTE :: any)[info.carga]
			if info.conectada and bl and base then
				local e = dados.estacoes[info.estacao]
				local nivel = 1 + Economia.BONUS_POR_NIVEL * Economia.nivelEstacao(estado, info.estacao)
				r[info.carga] += e.porte * base * nivel * bl.servico
			end
		end
	end
	return r
end

-- Quanto o caixa muda por segundo (pode ser negativo).
function Economia.rendaTotal(estado: EstadoMapa, dados: any): number
	return Economia.balanco(estado, dados).lucro
end

-- ---------------------------------------------------------------- estatísticas (para o painel da companhia)

function Economia.estatisticas(estado: EstadoMapa, dados: any): any
	local balanco = Economia.balanco(estado, dados)
	local trechos, total = 0, 0
	local passageiros, trens = Economia.passageirosPorDia(balanco), 0
	for _, linha in dados.linhas do
		for _, t in linha.trechos do
			total += 1
			if estado.trechos[t.id] then
				trechos += 1
			end
		end
		if balanco.linhas[linha.id] then
			trens += estado.trens[linha.id] or 0
		end
	end
	local carga = Economia.cargaPorDia(estado, dados, balanco)
	local estacoes = 0
	for id in dados.estacoes do
		if Economia.estacaoNaRede(estado, dados, id) then
			estacoes += 1
		end
	end
	return {
		renda = balanco.lucro,
		receita = balanco.receita,
		manutencao = balanco.manutencao,
		trens = trens,
		trechos = trechos,
		trechosTotal = total,
		linhasCompletas = Economia.linhasCompletas(estado, dados),
		linhasTotal = #dados.linhas,
		estacoes = estacoes,
		passageirosDia = math.round(passageiros),
		cargaDia = carga, -- por tipo de carga
		satisfacao = balanco.satisfacao,
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

-- Número sem símbolo de moeda (1.234 · 2,5 mi).
function Economia.numero(valor: number): string
	return (Economia.formatar(valor, "", false):gsub("^%s+", ""):gsub("^%-%s+", "-"))
end

return Economia
