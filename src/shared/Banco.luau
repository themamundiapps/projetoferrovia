--!strict
-- Banco: empréstimos para acelerar a construção. O limite e os juros dependem do crédito da
-- companhia (satisfação dos passageiros e nível). A dívida é paga sozinha com uma parte do lucro;
-- dá para quitar de uma vez a qualquer momento. Um empréstimo por vez.

local Economia = require(script.Parent:WaitForChild("Economia"))
local Idioma = require(script.Parent:WaitForChild("Idioma"))

type EstadoMapa = Economia.EstadoMapa

local Banco = {}

Banco.PARCELA = 0.25 -- parte do lucro que vai para a dívida, automaticamente
Banco.MINUTOS_LIMITE = 5 -- com crédito A, empresta até 5 minutos de lucro
Banco.PISO = 5000 -- limite mínimo (vezes o multiplicador da era), para quem ainda lucra pouco
Banco.OPCOES = { 0.25, 0.5, 1 } -- frações do limite oferecidas

-- O banco muda com a época.
Banco.NOMES = {
	vapor = { pt = "Casa Bancária da Corte", en = "Court Banking House" },
	diesel = { pt = "Banco de Crédito Ferroviário", en = "Railway Credit Bank" },
	eletrico = { pt = "Banco Nacional de Fomento", en = "National Development Bank" },
	alta = { pt = "Banco Digital dos Trilhos", en = "Rail Digital Bank" },
}

export type Classe = { id: string, minimo: number, juros: number, limite: number, nome: { pt: string, en: string } }

-- Do melhor para o pior. juros = acréscimo total sobre o valor; limite = fração do limite máximo.
local CLASSES: { Classe } = {
	{ id = "A", minimo = 0.75, juros = 0.10, limite = 1.0, nome = { pt = "Excelente", en = "Excellent" } },
	{ id = "B", minimo = 0.55, juros = 0.20, limite = 0.7, nome = { pt = "Bom", en = "Good" } },
	{ id = "C", minimo = 0.35, juros = 0.35, limite = 0.45, nome = { pt = "Regular", en = "Fair" } },
	{ id = "D", minimo = 0, juros = 0.50, limite = 0.25, nome = { pt = "Arriscado", en = "Risky" } },
}
Banco.CLASSES = CLASSES

export type Emprestimo = {
	valor: number, -- quanto entrou no caixa
	total: number, -- quanto se deve no total (valor + juros)
	divida: number, -- quanto falta pagar
	classe: string,
	em: number, -- os.time() de quando foi tomado
}

-- Nota de crédito de 0 a 1: 75% satisfação dos passageiros, 25% nível da companhia (cheio no nível 20).
function Banco.nota(estado: EstadoMapa, satisfacao: number): number
	local nivel = Economia.nivel(estado)
	return math.clamp(0.75 * satisfacao + 0.25 * math.min(nivel / 20, 1), 0, 1)
end

function Banco.classe(nota: number): Classe
	for _, c in Banco.CLASSES do
		if nota >= c.minimo then
			return c
		end
	end
	return Banco.CLASSES[#Banco.CLASSES]
end

-- Limite de crédito agora: alguns minutos de lucro (ou o piso da era), conforme a classe.
function Banco.limite(estado: EstadoMapa, lucro: number, satisfacao: number): (number, Classe, number)
	local nota = Banco.nota(estado, satisfacao)
	local classe = Banco.classe(nota)
	local base = math.max(math.max(lucro, 0) * 60 * Banco.MINUTOS_LIMITE, Banco.PISO * Economia.multiplicadorEra(estado))
	return math.floor(base * classe.limite / 100) * 100, classe, nota
end

-- As ofertas do momento: { valor, total } para cada fração do limite.
function Banco.ofertas(estado: EstadoMapa, lucro: number, satisfacao: number): ({ { valor: number, total: number } }, Classe, number)
	local limite, classe, nota = Banco.limite(estado, lucro, satisfacao)
	local lista = {}
	for _, f in Banco.OPCOES do
		local valor = math.max(100, math.floor(limite * f / 100) * 100)
		table.insert(lista, { valor = valor, total = math.ceil(valor * (1 + classe.juros)) })
	end
	return lista, classe, nota
end

-- Por que não dá para pegar um empréstimo agora (nil = pode).
function Banco.impedimento(estado: EstadoMapa): string?
	if estado.emprestimo then
		return Idioma.L("Quite o empréstimo atual antes de pedir outro.", "Pay off your current loan before taking another.")
	end
	if next(estado.trechos) == nil then
		return Idioma.L("O banco só empresta para quem já tem trilho: construa o primeiro trecho.", "The bank only lends to companies with track: build your first section.")
	end
	return nil
end

-- Quanto sai do caixa para a dívida neste intervalo (dt segundos com este lucro por segundo).
function Banco.parcela(estado: EstadoMapa, lucro: number, dt: number): number
	local e = estado.emprestimo
	if not e or lucro <= 0 then
		return 0
	end
	return math.min(e.divida, lucro * Banco.PARCELA * dt)
end

-- Tempo estimado para terminar de pagar com o lucro atual (math.huge se não há lucro).
function Banco.tempoRestante(estado: EstadoMapa, lucro: number): number
	local e = estado.emprestimo
	if not e then
		return 0
	end
	if lucro <= 0 then
		return math.huge
	end
	return e.divida / (lucro * Banco.PARCELA)
end

return Banco
