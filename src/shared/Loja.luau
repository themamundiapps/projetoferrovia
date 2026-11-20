--!strict
-- Loja: passes (compra única) e produtos (compra repetida), em Robux.
-- Os ids vêm do Creator Dashboard (Monetização > Passes / Produtos de desenvolvedor). Item com id 0
-- ainda não foi criado: aparece na loja como "Em breve" e não pode ser comprado.
-- O preço que o jogador vê vem do Roblox (GetProductInfo); `preco` aqui é só a referência do que
-- foi combinado (documento "Renda com Robux").
-- Regras: linguagem calma, sem promoção falsa, sem caixa surpresa, e o ranking não conta dinheiro
-- (dinheiro dá para comprar; nível e linhas completas vêm de jogar).

local Loja = {}

export type Texto = { pt: string, en: string }
export type Passe = { id: string, passId: number, emoji: string, preco: number, nome: Texto, descricao: Texto }
export type Produto = {
	id: string,
	produtoId: number,
	emoji: string,
	preco: number,
	nome: Texto,
	descricao: Texto,
	tipo: string, -- "dinheiro" | "impulso" | "estudo"
	horas: number?, -- dinheiro: horas da renda atual
	ateSegundos: number?, -- estudo: faixa de tempo restante que esta versão cobre
}

Loja.PASSES = {
	{
		id = "dobro", passId = 0, emoji = "dinheiro", preco = 399,
		nome = { pt = "Lucro em Dobro", en = "Double Profit" },
		descricao = { pt = "Toda a renda das linhas vale o dobro, para sempre.", en = "All line income is doubled, forever." },
	},
	{
		id = "gerente", passId = 0, emoji = "companhia", preco = 249,
		nome = { pt = "Gerente Automático", en = "Auto Manager" },
		descricao = { pt = "Compra os trens que faltam e constrói os trechos liberados sozinho, do mais barato ao mais caro. Dá para desligar aqui na loja.", en = "Buys missing trains and builds unlocked sections on its own, cheapest first. You can turn it off here in the shop." },
	},
	{
		id = "estudos", passId = 0, emoji = "gabinete", preco = 199,
		nome = { pt = "Estudos Rápidos", en = "Fast Studies" },
		descricao = { pt = "Os estudos do Gabinete de Projetos levam metade do tempo.", en = "Projects Cabinet studies take half the time." },
	},
	{
		id = "offline", passId = 0, emoji = "relogio", preco = 149,
		nome = { pt = "Renda Offline Longa", en = "Long Offline Income" },
		descricao = { pt = "Com o jogo fechado, a renda acumula por até 24 h (sem o passe, até 2 h).", en = "With the game closed, income builds up for up to 24 h (without the pass, up to 2 h)." },
	},
	{
		id = "pinturas", passId = 0, emoji = "trens", preco = 99,
		nome = { pt = "Pinturas Especiais", en = "Special Liveries" },
		descricao = { pt = "Locomotivas douradas no mapa e um selo ✦ ao lado do seu nome nos rankings. Só visual.", en = "Golden locomotives on the map and a ✦ badge next to your name on the leaderboards. Cosmetic only." },
	},
} :: { Passe }

Loja.PRODUTOS = {
	{
		id = "mala", produtoId = 3733996753, emoji = "dinheiro", preco = 49, tipo = "dinheiro", horas = 0.5,
		nome = { pt = "Mala de dinheiro", en = "Bag of money" },
		descricao = { pt = "30 minutos da sua renda atual.", en = "30 minutes of your current income." },
	},
	{
		id = "cofre", produtoId = 3733996885, emoji = "banco", preco = 199, tipo = "dinheiro", horas = 3,
		nome = { pt = "Cofre", en = "Safe" },
		descricao = { pt = "3 horas da sua renda atual.", en = "3 hours of your current income." },
	},
	{
		id = "banco", produtoId = 3733996814, emoji = "prestigio", preco = 599, tipo = "dinheiro", horas = 12,
		nome = { pt = "Banco inteiro", en = "Whole bank" },
		descricao = { pt = "12 horas da sua renda atual.", en = "12 hours of your current income." },
	},
	{
		id = "impulso", produtoId = 3733996820, emoji = "velocidade", preco = 79, tipo = "impulso",
		nome = { pt = "Impulso 2x", en = "2x Boost" },
		descricao = { pt = "Renda em dobro por 30 minutos. Soma com o Lucro em Dobro; comprar de novo acrescenta mais 30 minutos.", en = "Double income for 30 minutes. Stacks with Double Profit; buying again adds 30 more minutes." },
	},
	-- terminar o estudo na hora: três preços, conforme o tempo que falta
	{
		id = "estudo_curto", produtoId = 3733996826, emoji = "gabinete", preco = 25, tipo = "estudo", ateSegundos = 10 * 60,
		nome = { pt = "Concluir estudo", en = "Finish study" },
		descricao = { pt = "Termina agora o estudo do Gabinete (faltando até 10 min).", en = "Finishes the Cabinet study now (up to 10 min left)." },
	},
	{
		id = "estudo_medio", produtoId = 3733996840, emoji = "gabinete", preco = 49, tipo = "estudo", ateSegundos = 25 * 60,
		nome = { pt = "Concluir estudo", en = "Finish study" },
		descricao = { pt = "Termina agora o estudo do Gabinete (faltando até 25 min).", en = "Finishes the Cabinet study now (up to 25 min left)." },
	},
	{
		id = "estudo_longo", produtoId = 3733996850, emoji = "gabinete", preco = 99, tipo = "estudo", ateSegundos = math.huge,
		nome = { pt = "Concluir estudo", en = "Finish study" },
		descricao = { pt = "Termina agora o estudo do Gabinete.", en = "Finishes the Cabinet study now." },
	},
} :: { Produto }

Loja.IMPULSO_SEGUNDOS = 30 * 60
Loja.OFFLINE_LONGO_SEGUNDOS = 24 * 60 * 60
Loja.FATOR_ESTUDOS = 0.5
Loja.GERENTE_INTERVALO = 15 -- segundos entre as rodadas do Gerente Automático
-- Renda mínima usada nos pacotes de dinheiro (companhia nova, ainda sem lucro): por segundo
Loja.RENDA_MINIMA_PACOTE = 2

function Loja.passe(id: string): Passe?
	for _, p in Loja.PASSES do
		if p.id == id then
			return p
		end
	end
	return nil
end

function Loja.passePorId(passId: number): Passe?
	if passId == 0 then
		return nil
	end
	for _, p in Loja.PASSES do
		if p.passId == passId then
			return p
		end
	end
	return nil
end

function Loja.produto(id: string): Produto?
	for _, p in Loja.PRODUTOS do
		if p.id == id then
			return p
		end
	end
	return nil
end

function Loja.produtoPorId(produtoId: number): Produto?
	if produtoId == 0 then
		return nil
	end
	for _, p in Loja.PRODUTOS do
		if p.produtoId == produtoId then
			return p
		end
	end
	return nil
end

-- Versão do "Concluir estudo" que cobre o tempo que falta.
function Loja.produtoEstudo(restante: number): Produto?
	for _, p in Loja.PRODUTOS do
		if p.tipo == "estudo" and restante <= (p.ateSegundos or 0) then
			return p
		end
	end
	return nil
end

-- Quanto um pacote de dinheiro dá: horas da renda das linhas, sem contar Lucro em Dobro nem impulso
-- (assim o valor é previsível e honesto). `rendaBase` é o lucro por segundo sem a loja.
function Loja.valorPacote(p: Produto, rendaBase: number): number
	return math.floor(math.max(rendaBase, Loja.RENDA_MINIMA_PACOTE) * (p.horas or 0) * 3600)
end

return Loja
