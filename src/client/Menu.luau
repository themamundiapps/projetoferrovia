--!strict
-- Menu: barra inferior (Linhas, Companhia, Ajustes), o painel lateral de cada uma e os botões de zoom.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Economia = require(Shared:WaitForChild("Economia"))
local Emojis = require(Shared:WaitForChild("Emojis"))
local Estilo = require(script.Parent:WaitForChild("Estilo"))

local novo = Estilo.novo

local Menu = {}
Menu.__index = Menu

export type Menu = typeof(setmetatable({} :: any, Menu))

local ABAS = {
	{ id = "linhas", nome = "Linhas", emoji = "linhas" },
	{ id = "projetos", nome = "Gabinete", emoji = "gabinete" },
	{ id = "companhia", nome = "Companhia", emoji = "companhia" },
	{ id = "ajustes", nome = "Ajustes", emoji = "configuracoes" },
}

function Menu.new(tela: ScreenGui, era: any, dados: any): Menu
	local est = Estilo.new(era)
	local self = setmetatable({}, Menu)
	self.est = est
	self.dados = dados
	self.estado = nil :: any
	self.aba = nil :: string?
	self.ajustes = { nomesEstacoes = true, nomesMapa = true }
	self.aoAgir = Instance.new("BindableEvent") -- (tipo, args)
	self.aoFocarLinha = Instance.new("BindableEvent") -- (linhaId)
	self.aoAjuste = Instance.new("BindableEvent") -- (chave, valor)
	self.aoZoom = Instance.new("BindableEvent") -- (fator)
	self.aoConcluirProjeto = Instance.new("BindableEvent") -- (projeto) quando um estudo termina
	self.instancias = {} :: { Instance }
	self.vivos = {} :: { () -> () } -- atualizações a cada segundo que não recriam o painel (cronômetros, botões)
	self._concluidos = {} :: { [string]: boolean }
	self.avisoGabinete = false -- bolinha na aba quando um estudo termina com a aba fechada

	-- ---------------------------------------------------- barra inferior
	local barra = est:caixa({
		Name = "BarraMenu",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -14),
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.fromOffset(0, 0),
	}, tela)
	est:padding(barra, 6)
	est:lista(barra, 6, true)
	table.insert(self.instancias, barra)
	self.botoesAba = {} :: { [string]: TextButton }
	for i, aba in ABAS do
		local b = est:botao("discreto", `{(Emojis :: any)[aba.emoji]} {aba.nome}`, barra, i)
		b.Name = "Aba_" .. aba.id
		b.Size = UDim2.fromOffset(0, 44)
		b.AutomaticSize = Enum.AutomaticSize.X
		est:padding(b, 14, 0)
		b.Activated:Connect(function()
			self:abrirAba(if self.aba == aba.id then nil else aba.id)
		end)
		self.botoesAba[aba.id] = b
	end

	-- ---------------------------------------------------- zoom (celular)
	local zoom = novo("Frame", {
		Name = "Zoom",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -16),
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1,
		ZIndex = 30,
	}, tela)
	est:lista(zoom, 6)
	table.insert(self.instancias, zoom)
	local rotulos = { "+", "–" }
	local fatores = { 1.4, 1 / 1.4 }
	for i, rotulo in rotulos do
		local b = est:botao("discreto", rotulo, zoom, i)
		b.Name = if i == 1 then "ZoomMais" else "ZoomMenos"
		b.Size = UDim2.fromOffset(46, 46)
		b.BackgroundColor3 = est.c.panel
		b.TextSize = 24
		b.Activated:Connect(function()
			self.aoZoom:Fire(fatores[i])
		end)
	end

	-- ---------------------------------------------------- painel lateral (conteúdo da aba)
	local painel = est:caixa({
		Name = "PainelMenu",
		Position = UDim2.fromOffset(16, 150),
		Size = UDim2.new(0, 330, 1, -240),
		Visible = false,
	}, tela)
	table.insert(self.instancias, painel)
	self.painel = painel
	local rolagem = novo("ScrollingFrame", {
		Name = "Rolagem",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = est.c.inkMuted,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ZIndex = 31,
	}, painel)
	est:padding(rolagem, 14)
	est:lista(rolagem, 8)
	self.rolagem = rolagem

	return self
end

function Menu.destruir(self: Menu)
	for _, inst in self.instancias do
		inst:Destroy()
	end
	self.aoAgir:Destroy()
	self.aoFocarLinha:Destroy()
	self.aoAjuste:Destroy()
	self.aoZoom:Destroy()
	self.aoConcluirProjeto:Destroy()
end

-- Coloca o painel lateral logo abaixo de uma posição Y da tela (abaixo do caixa da companhia).
function Menu.posicionarAbaixoDe(self: Menu, y: number)
	self.painel.Position = UDim2.fromOffset(16, y + 10)
	self.painel.Size = UDim2.new(0, 330, 1, -(y + 10) - 90)
end

function Menu.abrirAba(self: Menu, aba: string?)
	self.aba = aba
	if aba == "projetos" then
		self.avisoGabinete = false
	end
	self:_rotularAbas()
	self.painel.Visible = aba ~= nil
	local c = self.est.c
	for id, b in self.botoesAba do
		local ativo = id == aba
		b.BackgroundColor3 = if ativo then c.ink else c.bg
		b.TextColor3 = if ativo then c.panel else c.ink
	end
	self:_redesenhar()
end

-- O painel só é redesenhado quando muda algo que ele mostra (trechos, trens, estações, era, projetos).
-- Redesenhar a cada segundo destruiria os botões no meio de um clique.
function Menu._assinatura(self: Menu, estado: any): string
	local situacoes = {}
	for _, p in self.dados.projetos or {} do
		table.insert(situacoes, Economia.situacaoProjeto(estado, self.dados, p))
	end
	local ok, txt = pcall(function()
		return HttpService:JSONEncode({ estado.trechos, estado.trens, estado.estacoes or {}, estado.era, situacoes })
	end)
	return if ok then txt else tostring(os.clock())
end

local function numero(n: number): string
	return (Economia.formatar(n, "", false):gsub("^%s+", ""))
end

local function relogio(segundos: number): string
	segundos = math.max(0, math.ceil(segundos))
	local h, m, s = segundos // 3600, (segundos % 3600) // 60, segundos % 60
	if h > 0 then
		return string.format("%d:%02d:%02d", h, m, s)
	end
	return string.format("%d:%02d", m, s)
end

-- Texto das abas: o Gabinete mostra o cronômetro do estudo e uma bolinha quando um estudo termina.
function Menu._rotularAbas(self: Menu)
	local b = self.botoesAba.projetos
	if not b then
		return
	end
	local txt = `{Emojis.gabinete} Gabinete`
	local atual, restante = nil, 0
	if self.estado then
		atual, restante = Economia.pesquisaAtual(self.estado)
	end
	if atual then
		txt ..= ` · {relogio(restante)}`
	elseif self.avisoGabinete then
		txt ..= " ●"
	end
	b.Text = txt
end

function Menu.atualizarEstado(self: Menu, estado: any)
	-- estudo que terminou desde a última atualização: avisa na aba
	local antes = self.estado
	if antes then
		for _, p in self.dados.projetos or {} do
			if Economia.projetoConcluido(estado, p.id) and (antes.projetos or {})[p.id] and not self._concluidos[p.id] then
				if self.aba ~= "projetos" then
					self.avisoGabinete = true
				end
				self.aoConcluirProjeto:Fire(p)
			end
		end
	end
	self._concluidos = {}
	for _, p in self.dados.projetos or {} do
		if Economia.projetoConcluido(estado, p.id) then
			self._concluidos[p.id] = true
		end
	end
	self.estado = estado
	self:_rotularAbas()
	local nova = self:_assinatura(estado)
	if nova ~= self._assinaturaAtual then
		self._assinaturaAtual = nova
		if self.aba then
			self:_redesenhar()
		end
	else
		for _, f in self.vivos do
			f()
		end
	end
end

function Menu._limpar(self: Menu)
	for _, filho in self.rolagem:GetChildren() do
		if filho:IsA("GuiObject") then
			filho:Destroy()
		end
	end
end

function Menu._redesenhar(self: Menu)
	if not self.aba then
		return
	end
	-- guarda a rolagem para a lista não "pular" a cada atualização
	local rolagemY = self.rolagem.CanvasPosition.Y
	self:_limpar()
	table.clear(self.vivos)
	if self.aba == "linhas" then
		self:_abaLinhas()
	elseif self.aba == "projetos" then
		self:_abaProjetos()
	elseif self.aba == "companhia" then
		self:_abaCompanhia()
	else
		self:_abaAjustes()
	end
	self.rolagem.CanvasPosition = Vector2.new(0, rolagemY)
end

-- ---------------------------------------------------------------- aba Linhas

function Menu._abaLinhas(self: Menu)
	local est, dados, estado, r = self.est, self.dados, self.estado, self.rolagem
	est:texto("titulo", `{Emojis.linhas} Linhas`, r, 1)
	if not estado then
		return
	end
	local simbolo = dados.simbolo

	local bTudo = est:botao("principal", `{Emojis.construir} Construir tudo que der`, r, 2)
	bTudo.Name = "BtnConstruirTudo"
	bTudo.Activated:Connect(function()
		self.aoAgir:Fire("construirTudo", {})
	end)
	local bFrota = est:botao("secundario", `{Emojis.trens} Completar frotas`, r, 3)
	bFrota.Name = "BtnCompletarFrotas"
	bFrota.Activated:Connect(function()
		self.aoAgir:Fire("completarFrotas", {})
	end)
	est:texto("fraco", "Construir tudo compra os trechos liberados do mais barato para o mais caro. Completar frotas compra trens até todos os passageiros embarcarem.", r, 4)

	local balanco = Economia.balanco(estado, dados)
	local rede = Economia.rede(estado, dados)
	for i, linha in dados.linhas do
		local construidos = Economia.trechosConstruidos(estado, linha)
		local liberada = Economia.linhaLiberada(estado, dados, i)
		local completa = construidos == #linha.trechos
		local faltando = Economia.trensFaltando(estado, dados, linha, rede)
		local sobrando = Economia.trensSobrando(estado, dados, linha, rede)
		local bl = balanco.linhas[linha.id]
		local cor = self.est.era.linhas[linha.cor] or est.c.ink

		local linhaBtn = novo("TextButton", {
			Name = "Linha_" .. linha.id,
			LayoutOrder = 10 + i,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = est.c.bg,
			Text = "",
			AutoButtonColor = true,
			ZIndex = 32,
		}, r)
		est:cantos(linhaBtn)
		novo("UIStroke", { Color = est.c.rule, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, linhaBtn)
		est:padding(linhaBtn, 10, 8)
		novo("Frame", {
			Size = UDim2.new(0, 6, 1, 0),
			BackgroundColor3 = cor,
			BackgroundTransparency = if liberada then 0 else 0.6,
			BorderSizePixel = 0,
			ZIndex = 33,
		}, linhaBtn)
		local textos = novo("Frame", {
			Position = UDim2.fromOffset(16, 0),
			Size = UDim2.new(1, -16, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			ZIndex = 33,
		}, linhaBtn)
		est:lista(textos, 2)

		local titulo = est:texto("subtitulo", `{linha.nome} <font size="13">· {linha.ano}</font>`, textos, 1)
		titulo.ZIndex = 33
		local info
		if not liberada and linha.projeto then
			info = `{Emojis.gabinete} Projeto: estude no Gabinete para liberar`
		elseif not liberada then
			info = `{Emojis.cadeado} Libera ao completar {dados.linhas[i - 1].nome}`
		else
			local lucro = if bl then bl.lucro else 0
			local txtLucro = if lucro >= 0 then `lucro {Economia.formatar(lucro, simbolo, true)}/s`
				else `prejuízo {Economia.formatar(-lucro, simbolo, true)}/s`
			local txtRede = if bl and bl.rede > 0 then ` · rede +{math.round((bl.fatorRede - 1) * 100)}%` else ""
			info = `{construidos}/{#linha.trechos} trechos · {estado.trens[linha.id] or 0} trens · {txtLucro}{txtRede}`
		end
		local l2 = est:texto("fraco", info, textos, 2)
		l2.ZIndex = 33
		local situacao = if not liberada then ""
			elseif faltando > 0 then `{Emojis.alerta} Lotada: só {math.round((bl and bl.servico or 0) * 100)}% embarcam · faltam {faltando} trem(ns)`
			elseif sobrando > 0 then `{Emojis.alerta} {sobrando} trem(ns) rodando vazio(s)`
			elseif completa then `{Emojis.confirmar} Linha completa`
			elseif construidos == 0 then `{Emojis.construir} Pronta para começar`
			else `{Emojis.construir} Em construção`
		if situacao ~= "" then
			local l3 = est:texto("fraco", situacao, textos, 3)
			l3.ZIndex = 33
			if faltando > 0 or sobrando > 0 then
				l3.TextColor3 = est.c.negative
			elseif completa then
				l3.TextColor3 = est.c.positive
			end
		end
		linhaBtn.Activated:Connect(function()
			self.aoFocarLinha:Fire(linha.id)
		end)
	end
end

-- ---------------------------------------------------------------- aba Gabinete de Projetos

function Menu._abaProjetos(self: Menu)
	local est, dados, estado, r = self.est, self.dados, self.estado, self.rolagem
	est:texto("titulo", `{Emojis.gabinete} Gabinete de Projetos`, r, 1)
	est:texto(
		"fraco",
		"Ferrovias que o Brasil planejou e nunca terminou. Estude um projeto por vez: o estudo leva tempo de verdade (continua com o jogo fechado) e, quando termina, a linha abre no mapa.",
		r,
		2
	)
	if not estado then
		return
	end
	local simbolo = dados.simbolo
	local c = est.c

	for i, p in dados.projetos or {} do
		local situacao = Economia.situacaoProjeto(estado, dados, p)
		local linha = nil
		for _, l in dados.linhas do
			if l.id == p.linha then
				linha = l
			end
		end
		local km = 0
		for _, t in (if linha then linha.trechos else {}) do
			km += t.km
		end

		local cartao = novo("Frame", {
			Name = "Projeto_" .. p.id,
			LayoutOrder = 10 + i,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = c.bg,
			ZIndex = 32,
		}, r)
		est:cantos(cartao)
		novo("UIStroke", {
			Color = if situacao == "pesquisando" then c.accent else c.rule,
			Thickness = if situacao == "pesquisando" then 2 else 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}, cartao)
		est:padding(cartao, 10, 8)
		est:lista(cartao, 4)

		local function txt(tipo: any, conteudo: string, ordem: number): TextLabel
			local l = est:texto(tipo, conteudo, cartao, ordem)
			l.ZIndex = 33
			return l
		end
		local emoji = (Emojis :: any)[p.emoji] or Emojis.linhas
		local titulo = txt("subtitulo", `{emoji} {p.nome}`, 1)
		if situacao == "bloqueado" then
			titulo.TextColor3 = c.inkMuted
		end
		txt("rotulo", `{if linha then #linha.trechos else 0} TRECHOS · {numero(km)} KM`, 2)
		txt("fraco", p.descricao, 3)

		if situacao == "concluido" then
			local l = txt("corpo", `{Emojis.confirmar} Projeto aprovado: a linha está aberta no mapa.`, 4)
			l.TextColor3 = c.positive
			local b = est:botao("discreto", `{Emojis.linhas} Ver no mapa`, cartao, 5)
			b.ZIndex = 33
			b.Activated:Connect(function()
				self.aoFocarLinha:Fire(p.linha)
			end)
		elseif situacao == "pesquisando" then
			local fundo = novo("Frame", {
				LayoutOrder = 4,
				Size = UDim2.new(1, 0, 0, 10),
				BackgroundColor3 = c.panel,
				BorderSizePixel = 0,
				ZIndex = 33,
			}, cartao)
			novo("UIStroke", { Color = c.ink, Thickness = 1 }, fundo)
			local barra = novo("Frame", {
				Size = UDim2.fromScale(0, 1),
				BackgroundColor3 = c.accent,
				BorderSizePixel = 0,
				ZIndex = 34,
			}, fundo)
			local lTempo = txt("corpo", "", 5)
			local bAcel = est:botao("secundario", "", cartao, 6)
			bAcel.Name = "BtnAcelerar"
			bAcel.ZIndex = 33
			bAcel.Activated:Connect(function()
				self.aoAgir:Fire("acelerar", { projeto = p.id })
			end)
			local function atualizar()
				local e = self.estado
				local _, restante = Economia.pesquisaAtual(e)
				barra.Size = UDim2.fromScale(math.clamp(1 - restante / p.segundos, 0, 1), 1)
				lTempo.Text = `{Emojis.relogio} Em estudo · faltam <b>{relogio(restante)}</b>`
				local custo = Economia.custoAcelerar(p, restante)
				bAcel.Text = `{Emojis.velocidade} Acelerar agora · {Economia.formatar(custo, simbolo)}`
				est:habilitar(bAcel, e.dinheiro >= custo)
			end
			atualizar()
			table.insert(self.vivos, atualizar)
		elseif situacao == "bloqueado" then
			local _, motivo = Economia.requisitosProjeto(estado, dados, p)
			txt("corpo", `{Emojis.cadeado} {motivo or "Ainda fechado."}`, 4)
			txt("fraco", `Estudo: {Economia.formatar(p.custo, simbolo)} · {relogio(p.segundos)}`, 5)
		else
			local b = est:botao("principal", `{Emojis.gabinete} Estudar · {Economia.formatar(p.custo, simbolo)} · {relogio(p.segundos)}`, cartao, 4)
			b.Name = "BtnEstudar_" .. p.id
			b.ZIndex = 33
			local lMotivo = txt("fraco", "", 5)
			b.Activated:Connect(function()
				self.aoAgir:Fire("pesquisar", { projeto = p.id })
			end)
			local function atualizar()
				local e = self.estado
				local livre = situacao == "disponivel"
				est:habilitar(b, livre and e.dinheiro >= p.custo)
				lMotivo.Text = if not livre then "O Gabinete já está ocupado com outro estudo."
					elseif e.dinheiro < p.custo then `Faltam {Economia.formatar(p.custo - e.dinheiro, simbolo)}.`
					else ""
				lMotivo.Visible = lMotivo.Text ~= ""
			end
			atualizar()
			table.insert(self.vivos, atualizar)
		end
	end
end

-- ---------------------------------------------------------------- aba Companhia

function Menu._abaCompanhia(self: Menu)
	local est, dados, estado, r = self.est, self.dados, self.estado, self.rolagem
	est:texto("titulo", `{Emojis.companhia} Companhia`, r, 1)
	if not estado then
		return
	end
	local st = Economia.estatisticas(estado, dados)
	local simbolo = dados.simbolo
	local function numero(n: number): string
		return (Economia.formatar(n, "", false):gsub("^%s+", ""))
	end
	local era = self.est.era
	est:texto("rotulo", string.upper(era.nome) .. " · " .. era.anos, r, 2)

	local sat = math.round(st.satisfacao * 100)
	est:texto("subtitulo", `{Emojis.satisfacao} Satisfação: {sat}%`, r, 3)
	local barra = novo("Frame", {
		LayoutOrder = 4,
		Size = UDim2.new(1, 0, 0, 10),
		BackgroundColor3 = est.c.bg,
		BorderSizePixel = 0,
		ZIndex = 32,
	}, r)
	novo("UIStroke", { Color = est.c.ink, Thickness = 1 }, barra)
	novo("Frame", {
		Size = UDim2.new(st.satisfacao, 0, 1, 0),
		BackgroundColor3 = if sat >= 70 then est.c.positive elseif sat >= 40 then est.c.accent else est.c.negative,
		BorderSizePixel = 0,
		ZIndex = 33,
	}, barra)
	est:texto("fraco", `Vem dos passageiros que conseguem embarcar (trens suficientes) e do nível das estações. Hoje mexe {if sat >= 50 then "+" else ""}{math.round((Economia.fatorSatisfacao(estado, dados) - 1) * 100)}% na renda.`, r, 5)
	est:divisor(r, 6)

	local linhas = {
		`{Emojis.renda} Receita: <b>{Economia.formatar(st.receita, simbolo, true)}/s</b>`,
		`{Emojis.manutencao} Manutenção: <b>− {Economia.formatar(st.manutencao, simbolo, true)}/s</b>`,
		if st.renda >= 0 then `{Emojis.dinheiro} Lucro: <b>{Economia.formatar(st.renda, simbolo, true)}/s</b>`
			else `{Emojis.alerta} Prejuízo: <b>{Economia.formatar(-st.renda, simbolo, true)}/s</b>`,
		`{Emojis.trens} Trens: <b>{st.trens}</b>`,
		`{Emojis.passageiros} Passageiros: <b>{numero(st.passageirosDia)}</b> por dia`,
		`{Emojis.carga_cafe} Café: <b>{numero(st.cafeDia)}</b> sacas por dia`,
		`{Emojis.carga_minerio} Minério: <b>{numero(st.minerioDia)}</b> t por dia`,
		`{Emojis.carga_graos} Grãos: <b>{numero(st.graosDia)}</b> t por dia`,
		`{Emojis.linhas} Trechos: <b>{st.trechos}</b> de {st.trechosTotal}`,
		`{Emojis.confirmar} Linhas completas: <b>{st.linhasCompletas}</b> de {st.linhasTotal}`,
		`{Emojis.estacoes} Estações na rede: <b>{st.estacoes}</b>`,
	}
	for i, txt in linhas do
		est:texto("corpo", txt, r, 10 + i)
	end
end

-- ---------------------------------------------------------------- aba Ajustes

function Menu._abaAjustes(self: Menu)
	local est, r = self.est, self.rolagem
	est:texto("titulo", `{Emojis.configuracoes} Ajustes`, r, 1)
	local opcoes = {
		{ chave = "nomesEstacoes", nome = "Nomes das cidades" },
		{ chave = "nomesMapa", nome = "Nomes de estados, rios e regiões" },
	}
	for i, op in opcoes do
		local ligado = self.ajustes[op.chave]
		local b = est:botao("discreto", `{if ligado then Emojis.confirmar else Emojis.fechar} {op.nome}`, r, 1 + i)
		b.TextXAlignment = Enum.TextXAlignment.Left
		est:padding(b, 12, 0)
		b.Activated:Connect(function()
			self.ajustes[op.chave] = not self.ajustes[op.chave]
			self.aoAjuste:Fire(op.chave, self.ajustes[op.chave])
			self:_redesenhar()
		end)
	end
	local bEnq = est:botao("secundario", `{Emojis.mapa_mundo} Reenquadrar o mapa`, r, 10)
	bEnq.Activated:Connect(function()
		self.aoAjuste:Fire("reenquadrar", true)
	end)
end

return Menu
