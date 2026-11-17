--!strict
-- Interface (cliente): caixa da companhia, painel da concessão e avisos.
-- Só mostra o estado que o servidor manda e pede ações; nunca decide nada sobre dinheiro.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Economia = require(Shared:WaitForChild("Economia"))
local Metas = require(Shared:WaitForChild("Metas"))
local Idioma = require(Shared:WaitForChild("Idioma"))
local Emojis = require(Shared:WaitForChild("Emojis"))
local Estilo = require(script.Parent:WaitForChild("Estilo"))

local Interface = {}
Interface.__index = Interface

local function novo(classe: string, props: { [string]: any }, pai: Instance?): any
	local inst = Instance.new(classe)
	for k, v in props do
		(inst :: any)[k] = v
	end
	if pai then
		inst.Parent = pai
	end
	return inst
end

-- string.upper não converte letras acentuadas; esta versão converte.
local ACENTOS: { [string]: string } = {
	["á"] = "Á", ["à"] = "À", ["â"] = "Â", ["ã"] = "Ã", ["é"] = "É", ["ê"] = "Ê",
	["í"] = "Í", ["ó"] = "Ó", ["ô"] = "Ô", ["õ"] = "Õ", ["ú"] = "Ú", ["ç"] = "Ç",
}
local function maiusculas(texto: string): string
	local r = string.upper(texto)
	for min, mai in ACENTOS do
		r = string.gsub(r, min, mai)
	end
	return r
end

local function padding(pai: Instance, px: number)
	novo("UIPadding", {
		PaddingLeft = UDim.new(0, px),
		PaddingRight = UDim.new(0, px),
		PaddingTop = UDim.new(0, px),
		PaddingBottom = UDim.new(0, px),
	}, pai)
end

export type Interface = typeof(setmetatable({} :: any, Interface))

local MESES = { "janeiro", "fevereiro", "março", "abril", "maio", "junho", "julho", "agosto", "setembro", "outubro", "novembro", "dezembro" }

local function numero(n: number): string
	return (Economia.formatar(n, "", false):gsub("^%s+", ""))
end

function Interface.new(tela: ScreenGui, era: any, dados: any)
	local c, f = era.cores, era.fontes
	local self = setmetatable({}, Interface)
	self.era = era
	self.dados = dados
	self.estado = nil :: any
	self.trechoAberto = nil :: string?
	self.estacaoAberta = nil :: string?
	self.alternativa = nil :: string?
	self.aoAgir = Instance.new("BindableEvent") -- (tipo, args)
	self.aoFechar = Instance.new("BindableEvent")
	self._fila = {} :: { { msg: string, segundos: number } }
	self._rodandoFila = false

	local function caixa(props: { [string]: any }): Frame
		local fr = novo("Frame", props, tela)
		fr.BackgroundColor3 = c.panel
		fr.Active = true -- bloqueia o mapa embaixo
		fr.ZIndex = 30
		if not Estilo.new(era):moldura(fr) then
			novo("UIStroke", { Color = c.ink, Thickness = era.forma.traco + 0.5 }, fr)
			if era.forma.canto > 0 then
				novo("UICorner", { CornerRadius = UDim.new(0, era.forma.canto) }, fr)
			end
		end
		return fr
	end

	-- ---------------------------------------------------- barra de cima (de ponta a ponta)
	-- esquerda: companhia, caixa e data; direita: recursos e nível. Embaixo dela, o botão da era.
	local est = Estilo.new(era)
	local ALT = Estilo.ALTURA_TOPO
	local CREME, FRACO = Estilo.CREME, Estilo.CREME_FRACO
	local hud = novo("Frame", {
		Name = "Topo",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ZIndex = 28,
	}, tela)
	novo("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) }, hud)
	self.hud = hud
	local barra = est:barraTopo(hud)
	barra.LayoutOrder = 1
	local ponta = math.round(76 * ALT / 117) + 6
	local conteudo = novo("Frame", {
		Name = "Conteudo",
		Position = UDim2.fromOffset(ponta, 6),
		Size = UDim2.new(1, -2 * ponta, 0, ALT - 18),
		BackgroundTransparency = 1,
		ZIndex = 31,
	}, barra)
	local function grupo(nome: string, direita: boolean): Frame
		local g = novo("Frame", {
			Name = nome,
			AnchorPoint = Vector2.new(if direita then 1 else 0, 0),
			Position = UDim2.fromScale(if direita then 1 else 0, 0),
			Size = UDim2.fromScale(0, 1),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			ZIndex = 31,
		}, conteudo)
		novo("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 14),
		}, g)
		return g
	end
	local esquerda, direita = grupo("Esquerda", false), grupo("Direita", true)
	local function bloco(pai: Instance, nome: string, ordem: number, largura: number?): Frame
		local b = novo("Frame", {
			Name = nome,
			LayoutOrder = ordem,
			Size = UDim2.new(0, largura or 0, 1, 0),
			AutomaticSize = if largura then Enum.AutomaticSize.None else Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			ZIndex = 31,
		}, pai)
		novo("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			HorizontalAlignment = if largura then Enum.HorizontalAlignment.Center else Enum.HorizontalAlignment.Left,
			Padding = UDim.new(0, 1),
		}, b)
		return b
	end
	local function textoTopo(pai: Instance, ordem: number, fonte: Font, tam: number, cor: Color3): TextLabel
		return novo("TextLabel", {
			LayoutOrder = ordem,
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 1,
			Text = "",
			FontFace = fonte,
			TextSize = tam,
			TextColor3 = cor,
			ZIndex = 32,
		}, pai)
	end
	local function separador(pai: Instance, ordem: number)
		novo("Frame", {
			Name = "Separador",
			LayoutOrder = ordem,
			Size = UDim2.fromOffset(2, 34),
			BackgroundColor3 = Color3.fromRGB(196, 156, 84),
			BackgroundTransparency = 0.35,
			BorderSizePixel = 0,
			ZIndex = 31,
		}, pai)
	end
	-- item com ícone, valor e legenda (faixa de recursos e caixa)
	local function item(pai: Instance, nome: string, ordem: number, icone: string, emoji: string, tamValor: number, tamIcone: number?): (Frame, TextLabel, TextLabel)
		local fr = novo("Frame", {
			Name = nome,
			LayoutOrder = ordem,
			Size = UDim2.fromScale(0, 1),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			ZIndex = 31,
		}, pai)
		novo("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 6),
		}, fr)
		est:icone(icone, emoji, fr, tamIcone or 26, 1)
		local col = bloco(fr, "Valores", 2)
		local valor = textoTopo(col, 1, f.number, tamValor, CREME)
		local legenda = textoTopo(col, 2, f.label, 11, FRACO)
		return fr, valor, legenda
	end

	-- companhia: nome inteiro e título do presidente
	local blocoNome = bloco(esquerda, "Companhia", 1)
	self.lblNome = textoTopo(blocoNome, 1, f.display, 18, CREME)
	self.lblNome.Name = "NomeCompanhia"
	self.lblNome.TextTruncate = Enum.TextTruncate.AtEnd
	novo("UISizeConstraint", { MaxSize = Vector2.new(250, math.huge) }, self.lblNome)
	self.lblCargo = textoTopo(blocoNome, 2, f.label, 12, FRACO)
	self.lblCargo.Name = "Titulo"
	separador(esquerda, 2)
	-- caixa e renda
	local _, lblDinheiro, lblRenda = item(esquerda, "Caixa", 3, "dinheiro", Emojis.dinheiro, 22, 30)
	self.lblDinheiro, self.lblRenda = lblDinheiro, lblRenda
	self.lblDinheiro.Text = "…"
	separador(esquerda, 4)
	-- data do jogo (1 minuto = 1 dia) e era
	local blocoData = bloco(esquerda, "Data", 5)
	self.lblData = textoTopo(blocoData, 1, f.display, 17, CREME)
	self.lblEra = textoTopo(blocoData, 2, f.label, 12, FRACO)
	self.lblEra.Text = era.nome

	-- recursos
	self.recursos = {} :: { [string]: { quadro: Frame, valor: TextLabel, legenda: TextLabel } }
	local listaRecursos = {
		{ "trens", "trens", Emojis.trens, "trens" },
		{ "passageiros", "passageiros", Emojis.passageiros or "🧳", "passageiros/dia" },
		{ "satisfacao", "satisfacao", Emojis.satisfacao, "satisfação" },
		{ "carga", "carga", Emojis.cargas or "📦", "carga/dia" },
		{ "contrato", "decisao", Emojis.contratos, "contrato" },
	}
	for i, r in listaRecursos do
		local q, v, l = item(direita, "Recurso_" .. r[1], i, r[2], r[3], 16)
		l.Text = r[4]
		self.recursos[r[1]] = { quadro = q, valor = v, legenda = l }
	end
	separador(direita, 10)
	-- nível: título fica junto do nome; aqui o número, a barra e o XP
	local blocoNivel = bloco(direita, "Nivel", 11, 150)
	self.lblNivel = textoTopo(blocoNivel, 1, f.label, 13, CREME)
	self.lblNivel.Name = "Nivel"
	local trilho = novo("Frame", { Name = "Trilho", LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, ZIndex = 31 }, blocoNivel)
	self.cheioXp = est:barra(trilho, 1)
	self.lblXp = textoTopo(blocoNivel, 3, f.label, 11, FRACO)

	-- se a tela for estreita, a faixa de recursos perde itens (o menos importante primeiro)
	local ORDEM_ESCONDER = { "carga", "passageiros", "trens", "satisfacao" }
	local function caber()
		for _, r in self.recursos do
			r.quadro.Visible = r ~= self.recursos.contrato or self.estado ~= nil and self.estado.contrato ~= nil
		end
		blocoData.Visible = true
		for _, id in ORDEM_ESCONDER do
			if esquerda.AbsoluteSize.X + direita.AbsoluteSize.X + 24 <= conteudo.AbsoluteSize.X then
				return
			end
			self.recursos[id].quadro.Visible = false
		end
		if esquerda.AbsoluteSize.X + direita.AbsoluteSize.X + 24 > conteudo.AbsoluteSize.X then
			blocoData.Visible = false
		end
	end
	self._caber = function()
		task.defer(caber)
	end
	conteudo:GetPropertyChangedSignal("AbsoluteSize"):Connect(self._caber)

	-- botão da era (aparece embaixo da barra quando a próxima era é liberada)
	local linhaEra = novo("Frame", {
		Name = "LinhaEra",
		LayoutOrder = 2,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 30,
	}, hud)
	novo("UIPadding", { PaddingLeft = UDim.new(0, Estilo.MARGEM_LATERAL) }, linhaEra)
	self.linhaEra = linhaEra
	self.btnEra = est:botao("principal", "", linhaEra, 1)
	self.btnEra.Name = "BtnEra"
	self.btnEra.Size = UDim2.fromOffset(300, 0)
	self.btnEra.AutomaticSize = Enum.AutomaticSize.Y
	self.btnEra.TextSize = 15
	self.btnEra.TextWrapped = true
	self.btnEra.RichText = true
	self.btnEra.ZIndex = 32
	est:padding(self.btnEra, 22, 8)
	self.btnEra.Activated:Connect(function()
		self.aoAgir:Fire("modernizar", {})
	end)

	-- ---------------------------------------------------- aviso (topo, centro)
	self.aviso = caixa({
		Name = "Aviso",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, Estilo.ALTURA_TOPO + 12),
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.fromOffset(0, 0),
		Visible = false,
	})
	padding(self.aviso, 10)
	self.lblAviso = novo("TextLabel", {
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		Text = "",
		FontFace = f.body,
		TextSize = 16,
		TextColor3 = c.ink,
		ZIndex = 31,
	}, self.aviso)

	-- ---------------------------------------------------- painel da concessão (direita)
	local painel = caixa({
		Name = "Concessao",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -Estilo.MARGEM_LATERAL, 0, Estilo.ALTURA_TOPO + 12),
		Size = UDim2.fromOffset(300, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = false,
	})
	self.painel = painel

	-- o conteúdo fica num frame interno com a lista; o botão de fechar fica solto no painel
	local corpo = novo("Frame", {
		Name = "Corpo",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ZIndex = 31,
	}, painel)
	padding(corpo, 16)
	novo("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) }, corpo)

	local function texto(ordem: number, fonte: Font, tam: number, cor: Color3): TextLabel
		return novo("TextLabel", {
			LayoutOrder = ordem,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Text = "",
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			FontFace = fonte,
			TextSize = tam,
			TextColor3 = cor,
			ZIndex = 31,
		}, corpo)
	end
	self.lblCabecalho = texto(1, f.label, 13, c.inkMuted)
	self.lblTitulo = texto(2, f.display, 24, c.ink)
	self.lblDetalhes = texto(3, f.body, 16, c.ink)
	self.lblDetalhes.LineHeight = 1.25

	-- opções de traçado
	self.opcoes = novo("Frame", {
		LayoutOrder = 4,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ZIndex = 31,
	}, corpo)
	novo("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) }, self.opcoes)

	local function botao(ordem: number, pai: Instance): TextButton
		local b = novo("TextButton", {
			LayoutOrder = ordem,
			Size = UDim2.new(1, 0, 0, 46),
			BackgroundColor3 = c.accent,
			Text = "",
			FontFace = f.display,
			TextSize = 17,
			TextColor3 = c.onAccent,
			TextWrapped = true,
			AutoButtonColor = true,
			ZIndex = 32,
		}, pai)
		if era.forma.canto > 0 then
			novo("UICorner", { CornerRadius = UDim.new(0, era.forma.canto) }, b)
		end
		return b
	end
	self.btnConstruir = botao(5, corpo)
	self.btnConstruir.Name = "BtnConstruir"
	self.lblMotivo = texto(6, f.body, 14, c.inkMuted)

	self.divTrens = novo("Frame", { LayoutOrder = 7, Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = c.rule, BorderSizePixel = 0, ZIndex = 31 }, corpo)
	self.lblTrens = texto(8, f.body, 16, c.ink)
	self.btnTrem = botao(9, corpo)
	self.btnTrem.Name = "BtnTrem"
	self.btnTrem.BackgroundColor3 = c.ink
	self.btnTrem.TextColor3 = c.panel
	self.btnTrem.Size = UDim2.new(1, 0, 0, 40)
	self.btnVender = botao(10, corpo)
	self.btnVender.Name = "BtnVenderTrem"
	self.btnVender.BackgroundColor3 = c.bg
	self.btnVender.TextColor3 = c.ink
	self.btnVender.TextSize = 15
	self.btnVender.Size = UDim2.new(1, 0, 0, 34)
	novo("UIStroke", { Color = c.rule, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, self.btnVender)
	self.divCarga = novo("Frame", { LayoutOrder = 12, Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = c.rule, BorderSizePixel = 0, ZIndex = 31 }, corpo)
	self.lblCarga = texto(13, f.body, 15, c.ink)
	-- nota histórica da linha, em itálico, no pé do painel
	self.lblNota = texto(14, Font.new(f.body.Family, Enum.FontWeight.Regular, Enum.FontStyle.Italic), 14, c.inkMuted)
	self.lblNota.Visible = false
	self.lblCarga.LineHeight = 1.2

	self.btnFechar = novo("TextButton", {
		Name = "Fechar",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -6, 0, 6),
		Size = UDim2.fromOffset(32, 32),
		BackgroundTransparency = 1,
		Text = "X",
		FontFace = f.body,
		TextSize = 20,
		TextColor3 = c.inkMuted,
		ZIndex = 33,
	}, painel)

	self.btnConstruir.Activated:Connect(function()
		if self.estacaoAberta then
			self.aoAgir:Fire("melhorarEstacao", { estacao = self.estacaoAberta })
		elseif self.trechoAberto then
			self.aoAgir:Fire("construir", { trecho = self.trechoAberto, alternativa = self.alternativa })
		end
	end)
	self.btnTrem.Activated:Connect(function()
		local linha = self.trechoAberto and Economia.acharTrecho(self.dados, self.trechoAberto)
		if linha then
			self.aoAgir:Fire("trem", { linha = linha.id })
		end
	end)
	self.btnVender.Activated:Connect(function()
		local linha = self.trechoAberto and Economia.acharTrecho(self.dados, self.trechoAberto)
		if linha then
			self.aoAgir:Fire("venderTrem", { linha = linha.id })
		end
	end)
	self.btnFechar.Activated:Connect(function()
		self:fechar()
	end)

	return self
end

function Interface.destruir(self: Interface)
	self.hud:Destroy()
	self.aviso:Destroy()
	self.painel:Destroy()
	self.aoAgir:Destroy()
	self.aoFechar:Destroy()
end

function Interface.avisar(self: Interface, msg: string, segundos: number?)
	self.lblAviso.Text = msg
	self.aviso.Visible = true
	local marca = os.clock()
	self._marcaAviso = marca
	task.delay(segundos or 3, function()
		if self._marcaAviso == marca then
			self.aviso.Visible = false
		end
	end)
end

-- Avisos em fila (contrato cumprido, medalha, nível...): um de cada vez, sem um apagar o outro.
function Interface.enfileirar(self: Interface, msg: string, segundos: number?)
	table.insert(self._fila, { msg = msg, segundos = segundos or 4 })
	if self._rodandoFila then
		return
	end
	self._rodandoFila = true
	task.spawn(function()
		while #self._fila > 0 and self.aviso.Parent do
			local item = table.remove(self._fila, 1)
			self:avisar(item.msg, item.segundos)
			task.wait(item.segundos)
		end
		self._rodandoFila = false
	end)
end

function Interface.atualizarEstado(self: Interface, estado: any)
	self.estado = estado
	local simbolo = self.dados.simbolo
	local nivel, xpNoNivel, xpDoNivel = Economia.nivel(estado)
	self.lblCargo.Text = Economia.tituloNivel(nivel, estado.era, Idioma.atual)
	self.lblNivel.Text = `{Emojis.nivel} NÍVEL {nivel}`
	self.lblXp.Text = if xpDoNivel > 0 then `{numero(xpNoNivel)} / {numero(xpDoNivel)} XP` else "nível máximo"
	self.cheioXp.Size = UDim2.fromScale(if xpDoNivel > 0 then math.clamp(xpNoNivel / xpDoNivel, 0, 1) else 1, 1)
	self.lblNome.Text = estado.nomeCompanhia or Idioma.T("companhia_padrao")
	-- data: 1 minuto de verdade = 1 dia do jogo; o ano acompanha o progresso da era
	local dia = math.floor(workspace:GetServerTimeNow() / Metas.SEGUNDOS_POR_DIA)
	self.lblData.Text = `{dia % 30 + 1} de {MESES[(dia // 30) % 12 + 1]} de {Economia.anoAtual(estado, self.dados)}`
	self.lblEra.Text = self.era.nome
	self.lblDinheiro.Text = Economia.formatar(estado.dinheiro, simbolo)
	if estado.renda >= 0 then
		self.lblRenda.Text = `+ {Economia.formatar(estado.renda, simbolo, true)} por segundo`
		self.lblRenda.TextColor3 = Estilo.VERDE_CLARO
	else
		-- manutenção maior que a receita
		self.lblRenda.Text = `− {Economia.formatar(-estado.renda, simbolo, true)} por segundo`
		self.lblRenda.TextColor3 = Color3.fromRGB(240, 130, 110)
	end
	-- faixa de recursos
	local b = Economia.balanco(estado, self.dados)
	local trens = 0
	for _, n in estado.trens do
		trens += n
	end
	local carga = 0
	for _, v in Economia.cargaPorDia(estado, self.dados, b) do
		carga += v
	end
	local r = self.recursos
	r.trens.valor.Text = numero(trens)
	r.passageiros.valor.Text = numero(Economia.passageirosPorDia(b))
	r.satisfacao.valor.Text = `{math.round(b.satisfacao * 100)}%`
	r.carga.valor.Text = numero(carga)
	local contrato = estado.contrato
	if contrato then
		r.contrato.valor.Text = `{Metas.progressoContrato(contrato)} · {Metas.relogio(contrato.prazo - contrato.decorrido)}`
	end
	self._caber()
	local proxima, liberada = Economia.proximaEra(estado, self.dados)
	local eraProx = proxima and self.eras and self.eras[proxima.id]
	if proxima and liberada and eraProx then
		local podePagar = estado.dinheiro >= proxima.custo
		self.linhaEra.Visible = true
		local fator = math.round(proxima.multiplicador / Economia.multiplicadorEra(estado))
		local emoji = (Emojis :: any)["era_" .. proxima.id] or Emojis.era_diesel
		self.btnEra.Text = `{emoji} <b>Modernizar: {eraProx.nome}</b>\nRenda ×{fator} nas linhas · {Economia.formatar(proxima.custo, simbolo)}`
		Estilo.new(self.era):habilitar(self.btnEra, podePagar)
	else
		self.linhaEra.Visible = false
	end
	if estado.ganhoOffline and estado.ganhoOffline > 0.5 then
		self:avisar(`{Emojis.relogio} Enquanto você esteve fora, seus trens renderam {Economia.formatar(estado.ganhoOffline, simbolo)}`, 6)
	end
	if self.trechoAberto then
		self:_preencher()
	elseif self.estacaoAberta then
		self:_preencherEstacao()
	end
end

function Interface._modoTrecho(self: Interface, sim: boolean)
	self.divTrens.Visible = sim
	self.lblTrens.Visible = sim
	if not sim then
		self.lblNota.Visible = false
		self.btnTrem.Visible = false
		self.btnVender.Visible = false
		self.opcoes.Visible = false
		self.divCarga.Visible = false
		self.lblCarga.Visible = false
	end
end

local PORTES = { "Vila", "Cidade", "Cidade grande", "Capital regional", "Metrópole" }

function Interface.abrirEstacao(self: Interface, estacaoId: string)
	self.trechoAberto = nil
	self.estacaoAberta = estacaoId
	self.painel.Visible = true
	self:_modoTrecho(false)
	self:_preencherEstacao()
end

function Interface._preencherEstacao(self: Interface)
	local estado, dados = self.estado, self.dados
	local id = self.estacaoAberta
	if not estado or not id then
		return
	end
	local simbolo = dados.simbolo
	local e = dados.estacoes[id]
	local nivel = Economia.nivelEstacao(estado, id)
	local naRede = Economia.estacaoNaRede(estado, dados, id)

	self.lblCabecalho.Text = `ESTAÇÃO · {maiusculas(PORTES[e.porte] or "")}{if e.porto then " · PORTO" else ""}`
	self.lblTitulo.Text = e.nome
	local linhas = {}
	for i, def in Economia.NIVEIS_ESTACAO do
		local marca = if i <= nivel then Emojis.confirmar elseif i == nivel + 1 then Emojis.mais else Emojis.cadeado
		table.insert(linhas, `{marca} {def.nome}`)
	end
	table.insert(linhas, "")
	table.insert(linhas, `{Emojis.renda} Bônus atual: +{math.round(nivel * Economia.BONUS_POR_NIVEL * 100)}% na renda dos trechos que chegam aqui`)
	if e.produz and Economia.CARGAS[e.produz] then
		local def = Economia.CARGAS[e.produz]
		local conectada = Economia.conectadasAoPorto(estado, dados)[id]
		table.insert(linhas, `{(Emojis :: any)[def.emoji]} Produz {string.lower(def.nome)}{if conectada then " (chegando a um porto)" else " (sem trilho até um porto)"}`)
	end
	self.lblDetalhes.Text = table.concat(linhas, "\n")

	local custo = Economia.custoMelhoria(estado, dados, id)
	if not naRede then
		self.btnConstruir.Text = `{Emojis.cadeado} Fora da rede`
		self.lblMotivo.Text = "Construa um trecho até esta estação para poder melhorá-la."
		self.btnConstruir.Active, self.btnConstruir.AutoButtonColor, self.btnConstruir.BackgroundTransparency = false, false, 0.6
	elseif not custo then
		self.btnConstruir.Text = `{Emojis.prestigio} Nível máximo`
		self.lblMotivo.Text = ""
		self.btnConstruir.Active, self.btnConstruir.AutoButtonColor, self.btnConstruir.BackgroundTransparency = false, false, 0.6
	else
		local proximo = Economia.NIVEIS_ESTACAO[nivel + 1].nome
		local podePagar = estado.dinheiro >= custo
		self.btnConstruir.Text = `{Emojis.melhorar} {proximo} · {Economia.formatar(custo, simbolo)}`
		self.lblMotivo.Text = if podePagar then `+{math.round(Economia.BONUS_POR_NIVEL * 100)}% na renda dos trechos desta estação.` else `Faltam {Economia.formatar(custo - estado.dinheiro, simbolo)}.`
		self.btnConstruir.Active, self.btnConstruir.AutoButtonColor = podePagar, podePagar
		self.btnConstruir.BackgroundTransparency = if podePagar then 0 else 0.6
	end
	self.lblMotivo.Visible = self.lblMotivo.Text ~= ""
end

function Interface.abrir(self: Interface, trechoId: string)
	if self.trechoAberto ~= trechoId then
		self.alternativa = nil
	end
	self.estacaoAberta = nil
	self:_modoTrecho(true)
	self.trechoAberto = trechoId
	self.painel.Visible = true
	self:_preencher()
end

function Interface.fechar(self: Interface)
	self.trechoAberto = nil
	self.estacaoAberta = nil
	self.painel.Visible = false
	self.aoFechar:Fire()
end

function Interface._preencher(self: Interface)
	local estado, dados, c = self.estado, self.dados, self.era.cores
	if not estado or not self.trechoAberto then
		return
	end
	local simbolo = dados.simbolo
	local linha, iLinha, trecho, iTrecho = Economia.acharTrecho(dados, self.trechoAberto)
	if not trecho then
		return
	end
	local situacao = Economia.situacaoTrecho(estado, dados, iLinha, iTrecho)
	local escolhida = estado.trechos[trecho.id] or self.alternativa
	local opcao = Economia.opcaoTrecho(trecho, escolhida)
	local terreno = dados.terrenos[opcao.terreno or trecho.terreno]
	local de, para = dados.estacoes[trecho.de].nome, dados.estacoes[trecho.para].nome

	self.lblCabecalho.Text = `{maiusculas(linha.nome)} · {trecho.ano}`
	local nota = linha.nota or (linha.projeto and (Economia.acharProjeto(dados, linha.projeto) or {}).descricao)
	self.lblNota.Text = Idioma.t(nota)
	self.lblNota.Visible = self.lblNota.Text ~= ""
	self.lblTitulo.Text = `{de} – {para}`
	local fatorRede = Economia.bonusRede(estado, dados, linha)
	local passageiros = Economia.passageirosTrecho(estado, dados, trecho, fatorRede)
	if not estado.trechos[trecho.id] then
		-- antes de construir: previsão com a escolha de traçado atual
		local opcaoPrev = Economia.opcaoTrecho(trecho, escolhida)
		passageiros = Economia.PASSAGEIROS_POR_PESO * Economia.pesoTrecho(dados, trecho) * (opcaoPrev.fatorDemanda or 1)
	end
	local era = Economia.multiplicadorEra(estado)
	local estA, estB = dados.estacoes[trecho.de], dados.estacoes[trecho.para]
	self.lblDetalhes.Text = table.concat({
		`{Emojis.distancia} Extensão: {opcao.km} km`,
		`{Emojis.terreno_montanha} Terreno: {terreno.nome} (custo ×{string.format("%.1f", terreno.custo):gsub("%.", ",")})`,
		`{Emojis.passageiros} Demanda: {Economia.numero(passageiros)} passageiros/h (cidades de porte {estA.porte} e {estB.porte})`,
		`{Emojis.renda} Receita: + {Economia.formatar(Economia.rendaTrecho(dados, trecho, escolhida) * era, simbolo, true)}/s{if era > 1 then ` (×{era} da era)` else ""}`,
		`{Emojis.manutencao} Manutenção: − {Economia.formatar(Economia.manutencaoTrecho(trecho, escolhida), simbolo, true)}/s`,
	}, "\n")

	-- opções de traçado (só antes de construir). Só recria os botões quando algo muda,
	-- senão um clique poderia cair num botão que acabou de ser destruído.
	local temOpcoes = trecho.alternativas ~= nil and situacao ~= "construido"
	self.opcoes.Visible = temOpcoes
	local chaveOpcoes = `{trecho.id}|{self.alternativa or ""}|{situacao}|{temOpcoes}`
	if chaveOpcoes ~= self._chaveOpcoes then
		self._chaveOpcoes = chaveOpcoes
		for _, filho in self.opcoes:GetChildren() do
			if filho:IsA("TextButton") then
				filho:Destroy()
			end
		end
	else
		temOpcoes = false -- já estão desenhadas
	end
	if temOpcoes then
		local atual = self.alternativa or trecho.alternativas[1].id
		for i, alt in trecho.alternativas do
			local sel = alt.id == atual
			local b = Instance.new("TextButton")
			b.LayoutOrder = i
			b.Size = UDim2.new(1, 0, 0, 0)
			b.AutomaticSize = Enum.AutomaticSize.Y
			b.BackgroundColor3 = if sel then c.accent else c.bg
			b.BackgroundTransparency = if sel then 0.82 else 0
			b.TextXAlignment = Enum.TextXAlignment.Left
			b.TextWrapped = true
			b.RichText = true
			b.FontFace = self.era.fontes.body
			b.TextSize = 15
			b.TextColor3 = c.ink
			b.ZIndex = 32
			b.Text = `<b>{if sel then "● " else "○ "}{alt.nome}</b>\n{alt.descricao}\n{alt.km} km · {Economia.formatar(alt.custo, simbolo)}`
			local pad = Instance.new("UIPadding")
			pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 8), UDim.new(0, 8)
			pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 6), UDim.new(0, 6)
			pad.Parent = b
			local borda = Instance.new("UIStroke")
			borda.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			borda.Color = if sel then c.accent else c.rule
			borda.Thickness = if sel then 2 else 1
			borda.Parent = b
			b.Parent = self.opcoes
			b.Activated:Connect(function()
				self.alternativa = alt.id
				self:_preencher()
			end)
		end
	end

	-- botão principal
	local custo = opcao.custo
	if situacao == "construido" then
		self.btnConstruir.Text = `{Emojis.confirmar} Trecho construído`
		self.btnConstruir.Active = false
		self.btnConstruir.AutoButtonColor = false
		self.btnConstruir.BackgroundTransparency = 0.6
		self.lblMotivo.Text = ""
	elseif situacao == "projeto" then
		self.btnConstruir.Text = `{Emojis.gabinete} Ainda é só um projeto`
		self.btnConstruir.Active = false
		self.btnConstruir.AutoButtonColor = false
		self.btnConstruir.BackgroundTransparency = 0.6
		self.lblMotivo.Text = "Estude este projeto no Gabinete (menu de baixo) para liberar a construção."
	elseif situacao == "bloqueado" then
		self.btnConstruir.Text = `{Emojis.cadeado} Ainda fechado`
		self.btnConstruir.Active = false
		self.btnConstruir.AutoButtonColor = false
		self.btnConstruir.BackgroundTransparency = 0.6
		if not Economia.linhaLiberada(estado, dados, iLinha) then
			self.lblMotivo.Text = `Para liberar, complete antes: {table.concat(Economia.faltaParaLiberar(estado, dados, iLinha), ", ")}.`
		else
			self.lblMotivo.Text = "Construa antes o trecho anterior desta linha."
		end
	else
		local podePagar = estado.dinheiro >= custo
		self.btnConstruir.Text = `{Emojis.assinar} Assinar concessão · {Economia.formatar(custo, simbolo)}`
		self.btnConstruir.Active = podePagar
		self.btnConstruir.AutoButtonColor = podePagar
		self.btnConstruir.BackgroundTransparency = if podePagar then 0 else 0.6
		self.lblMotivo.Text = if podePagar then "" else `Faltam {Economia.formatar(custo - estado.dinheiro, simbolo)}.`
	end
	self.lblMotivo.Visible = self.lblMotivo.Text ~= ""

	-- trens da linha: a frota tem que levar os passageiros; trem a mais só custa manutenção
	local construidos = Economia.trechosConstruidos(estado, linha)
	local trens = estado.trens[linha.id] or 0
	local faltando = Economia.trensFaltando(estado, dados, linha)
	local sobrando = Economia.trensSobrando(estado, dados, linha)
	local demanda = Economia.passageirosLinha(estado, dados, linha)
	local capacidade = trens * Economia.capacidadeTrem(estado)
	local servico = math.round(Economia.servico(estado, dados, linha) * 100)
	local custoTrem = Economia.custoTrem(estado, linha)
	local manutTrem = Economia.formatar(Economia.manutencaoTrem(estado, linha), simbolo, true)
	local fmt = Economia.numero
	self.btnVender.Visible = false
	if construidos == 0 then
		self.lblTrens.Text = `{Emojis.trens} O primeiro trem vem junto com o primeiro trecho. Cada trem leva {fmt(Economia.capacidadeTrem(estado))} passageiros/h.`
		self.lblTrens.TextColor3 = c.inkMuted
		self.btnTrem.Visible = false
	else
		local linhaFrota = `{Emojis.trens} Frota: {trens} {if trens == 1 then "trem" else "trens"} · leva {fmt(capacidade)} de {fmt(demanda)} passageiros/h`
		if faltando > 0 then
			self.lblTrens.Text = `{linhaFrota}\n{Emojis.alerta} Lotado: só {servico}% dos passageiros embarcam. Faltam {faltando} {if faltando == 1 then "trem" else "trens"} (cada um custa {manutTrem}/s de manutenção).`
			self.lblTrens.TextColor3 = c.negative
		elseif sobrando > 0 then
			self.lblTrens.Text = `{linhaFrota}\n{Emojis.alerta} {sobrando} {if sobrando == 1 then "trem rodando vazio" else "trens rodando vazios"}: cada um custa {manutTrem}/s de manutenção.`
			self.lblTrens.TextColor3 = c.negative
		else
			self.lblTrens.Text = `{linhaFrota}\n{Emojis.confirmar} Todos os passageiros embarcam.`
			self.lblTrens.TextColor3 = c.positive
		end
		self.btnTrem.Visible = faltando > 0
		if faltando > 0 then
			local podePagar = estado.dinheiro >= custoTrem
			self.btnTrem.Text = `{Emojis.trens} Comprar trem · {Economia.formatar(custoTrem, simbolo)}`
			self.btnTrem.Active = podePagar
			self.btnTrem.AutoButtonColor = podePagar
			self.btnTrem.BackgroundTransparency = if podePagar then 0 else 0.6
		end
		if Economia.podeVenderTrem(estado, linha) then
			self.btnVender.Visible = true
			self.btnVender.Text = `Vender 1 trem · + {Economia.formatar(Economia.valorVendaTrem(estado, linha), simbolo)}`
		end
	end

	-- cargas desta linha
	local cargas = Economia.cargasPorLinha(estado, dados)[linha.id]
	local valores = Economia.valorCargas(estado, dados)
	local linhasTexto = {}
	for _, info in cargas do
		local def = Economia.CARGAS[info.carga]
		local emoji = (Emojis :: any)[def.emoji] or ""
		local nome = dados.estacoes[info.estacao].nome
		local v = valores[info.estacao]
		local unidade = def.unidade:gsub("s$", "")
		if info.conectada then
			local frete = if v and v.unidadesDia > 0
				then ` · {Economia.formatar(v.preco, simbolo, true)} por {unidade}, {Economia.formatar(v.reaisDia, simbolo)}/dia`
				else ""
			table.insert(linhasTexto, `{emoji} {def.nome} de {nome} chega a um porto: +{math.round(def.bonus * 100)}% na renda{frete}`)
		else
			local renderia = if v and v.reaisDia > 0 then ` (renderia {Economia.formatar(v.reaisDia, simbolo)}/dia)` else ""
			table.insert(linhasTexto, `{emoji} {def.nome} de {nome} ainda sem trilho até um porto{renderia}`)
		end
	end
	local temCarga = #linhasTexto > 0
	self.divCarga.Visible = temCarga
	self.lblCarga.Visible = temCarga
	self.lblCarga.Text = table.concat(linhasTexto, "\n")
end

return Interface
