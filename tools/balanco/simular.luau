-- Simulação de balanço (rodar com tools/balanco/simular.sh). Vector2 é trocado por tabela na cópia dos dados.
Vector2 = { new = function(x, y) return { X = x, Y = y } end }
local E = require("./Economia")
local D = require("./Brasil")
local e = E.estadoNovo()
local t = 0
E.relogio = function() return t end
local log = {}
local function lucro() return E.rendaTotal(e, D) end
local fimHist, diesel
for passo = 1, 4 * 3600 do
	for _ = 1, 5 do
		local melhor, mc, ml
		for i, l in D.linhas do for j, tr in l.trechos do
			if E.situacaoTrecho(e, D, i, j) == "disponivel" then
				local c = E.opcaoTrecho(tr, nil).custo
				if not mc or c < mc then melhor, mc, ml = tr, c, l end
			end
		end end
		if melhor and mc <= e.dinheiro then
			e.dinheiro -= mc
			e.trechos[melhor.id] = E.opcaoTrecho(melhor, nil).id or "padrao"
			if (e.trens[ml.id] or 0) == 0 then e.trens[ml.id] = 1 end
			table.insert(log, string.format("%6.1fmin %-18s lucro=%.1f/s", t / 60, melhor.id, lucro()))
		else break end
	end
	for _, l in D.linhas do
		if E.podeComprarTrem(e, D, l) and e.dinheiro >= E.custoTrem(e, l) then
			local antes = lucro()
			e.trens[l.id] += 1
			if lucro() > antes then e.dinheiro -= E.custoTrem(e, l) else e.trens[l.id] -= 1 end
		end
	end
	-- pesquisa: começa o próximo projeto disponível
	if not E.pesquisaAtual(e) then
		for _, p in D.projetos do
			if E.situacaoProjeto(e, D, p) == "disponivel" and e.dinheiro >= p.custo then
				e.dinheiro -= p.custo
				e.projetos[p.id] = E.relogio() + p.segundos
				table.insert(log, string.format("%6.1fmin estudo %s", t / 60, p.id))
				break
			end
		end
	end
	local ne, ok = E.proximaEra(e, D)
	if ne and ok and e.dinheiro >= ne.custo then e.dinheiro -= ne.custo; e.era = ne.id; table.insert(log, string.format("%6.1fmin DIESEL", t / 60)) end
	e.dinheiro = math.max(0, e.dinheiro + lucro())
	t += 1
end
local b = E.balanco(e, D)
table.insert(log, string.format("FIM %.0fmin caixa=%s lucro=%.0f/s", t / 60, E.formatar(e.dinheiro), b.lucro))
print(table.concat(log, "\n"))
