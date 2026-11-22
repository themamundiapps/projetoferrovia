-- Jogador "guloso" para rodar DENTRO do Studio (execute_luau no Edit, sem precisar do luau no PC).
-- Uso: colocar este código num ModuleScript "_Simulador" em ServerStorage e, num task.spawn,
--   local r = require(ServerStorage._Simulador:Clone())("EUA", { horas = 30 }, valorDeSaida)
-- Parâmetros opcionais para testar ajustes sem mudar o código: payback, crescimento, fatorEra,
-- fatorEstudo, fatorCustoEstudo, dt (passo em segundos, padrão 5). Roda sobre cópias dos módulos.
-- Resultado de 22/11/2026: Brasil diesel 1,3 h · elétrica 4,6 h · alta 15,6 h · fim 20,4 h;
--                          EUA    diesel 2,4 h · elétrica 4,1 h · alta 12,1 h · fim 18,1 h.
-- Apagar o _Simulador do ServerStorage depois (não deve ir para o jogo publicado).
local Shared=game.ReplicatedStorage.Shared
return function(nomeMapa, P, saida)
	local pasta=Instance.new("Folder"); pasta.Name="_simTmp"
	for _,n in {"Economia","Tarifas","Loja","Idioma"} do Shared[n]:Clone().Parent=pasta end
	Shared.Dados[nomeMapa]:Clone().Parent=pasta
	pasta.Parent=game:GetService("ServerStorage")
	local E=require(pasta.Economia); local D=require(pasta[nomeMapa])
	if P.payback then E.PAYBACK_SEGUNDOS=P.payback end
	if P.crescimento then E.CRESCIMENTO_PAYBACK=P.crescimento end
	for _,era in E.ERAS do era.custo=era.custo*(P.fatorEra or 1) end
	for _,p in D.projetos do p.segundos=p.segundos*(P.fatorEstudo or 1); p.custo=p.custo*(P.fatorCustoEstudo or 1) end
	local dt=P.dt or 5
	local e=E.estadoNovo(); local t=0
	E.relogio=function() return t end
	local marcos={}
	local function lucro() return E.rendaTotal(e,D) end
	local horas=P.horas or 30
	local passos=math.floor(horas*3600/dt)
	local fim=nil
	for passo=1,passos do
		for _=1,8 do
			local melhor,mc,ml
			for i,l in D.linhas do for j,tr in l.trechos do
				if E.situacaoTrecho(e,D,i,j)=="disponivel" then
					local c=E.opcaoTrecho(tr,nil).custo
					if not mc or c<mc then melhor,mc,ml=tr,c,l end
				end end end
			if melhor and mc<=e.dinheiro then
				e.dinheiro-=mc
				e.trechos[melhor.id]=E.opcaoTrecho(melhor,nil).id or "padrao"
				if (e.trens[ml.id] or 0)==0 then e.trens[ml.id]=1 end
			else break end
		end
		for _,l in D.linhas do
			for _=1,3 do
				if E.podeComprarTrem(e,D,l) and e.dinheiro>=E.custoTrem(e,l) then
					local antes=lucro(); e.trens[l.id]+=1
					if lucro()>antes then e.dinheiro-=E.custoTrem(e,l) else e.trens[l.id]-=1; break end
				else break end
			end
		end
		if not E.pesquisaAtual(e) then
			for _,p in D.projetos do
				if E.situacaoProjeto(e,D,p)=="disponivel" and e.dinheiro>=p.custo then
					e.dinheiro-=p.custo; e.projetos[p.id]=E.relogio()+p.segundos; break
				end
			end
		end
		local ne,ok=E.proximaEra(e,D)
		if ne and ok and e.dinheiro>=ne.custo then e.dinheiro-=ne.custo; e.era=ne.id; table.insert(marcos,string.format("%s %.1fh",ne.id,t/3600)) end
		local n=E.linhasCompletas(e,D)
		if n==#D.linhas and not fim then fim=t; table.insert(marcos,string.format("FIM %.1fh",t/3600)); break end
		if n==math.floor(#D.linhas/2) and not marcos.meio then marcos.meio=true; table.insert(marcos,string.format("metade %.1fh",t/3600)) end
		e.dinheiro=math.max(0,e.dinheiro+lucro()*dt)
		t+=dt
		if passo%40==0 then if saida then saida.Value=string.format("%s %.1fh",nomeMapa,t/3600) end task.wait() end
	end
	if not fim then table.insert(marcos,string.format("parou %.1fh linhas=%d era=%s",t/3600,E.linhasCompletas(e,D),e.era)) end
	pasta:Destroy()
	return nomeMapa..": "..table.concat(marcos," | ")
end
