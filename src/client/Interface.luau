--!strict
-- Interface (cliente): caixa da companhia, painel da concessão e avisos.
-- Só mostra o estado que o servidor manda e pede ações; nunca decide nada sobre dinheiro.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Economia = require(Shared:WaitForChild("Economia"))
local Metas = require(Shared:WaitForChild("Metas"))
local Idioma = require(Shared:WaitForChild("Idioma"))
local L = Idioma.L
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

local MESES_EN = { "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December" }
local MESES = { "janeiro", "fevereiro", "março", "abril", "maio", "junho", "julho", "agosto", "setembro", "outubro", "novembro", "dezembro" }

local function numero(n: number): string
	return (Economia.formatar(n, "", false):gsub("^%s+", ""))
end

function Interface.new(tela: ScreenGui, era: any, dados: any)
	-- cores do painel (no kit de painel escuro, texto claro)
	local c, f = Estilo.new(era).c, era.fontes
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
	local coresTopo = est:coresTopo() -- claro na madeira (clássico), escuro no alumínio (moderno)
	self.coresTopo = coresTopo
	local CREME, FRACO = coresTopo.forte, coresTopo.fraco
	local hud = novo("Frame", {
		Name = "Topo",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ZIndex = 28,
	}, tela)
	-- no celular a barra encolhe menos que o resto; continua de ponta a ponta (largura dividida pela compensação)
	Estilo.compensar(hud, 0.82, function(k: number)
		hud.Size = UDim2.new(1 / k, 0, 0, 0)
	end)
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
	-- os botões do Roblox (menu, chat) ficam por cima da ponta esquerda: o conteúdo começa depois deles
	local GuiService = game:GetService("GuiService")
	local function desviar()
		-- (TopbarInset vem em pixels da tela; a barra fica dentro da área segura e da escala da interface)
		local esq = math.max(ponta, Estilo.px(GuiService.TopbarInset.Min.X - tela.AbsolutePosition.X, barra) + 12)
		-- à direita, o conteúdo não entra no recorte do celular (INSET_DIR em pontos da tela virtual)
		local dir = ponta + Estilo.INSET_DIR * Estilo.escala / Estilo.escalaDe(barra)
		conteudo.Position = UDim2.fromOffset(esq, 6)
		conteudo.Size = UDim2.new(1, -(esq + dir), 0, ALT - 18)
	end
	desviar()
	GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(desviar)
	-- todos os itens numa fileira só, espalhados por igual pela barra (sem buraco no meio)
	local itens = novo("Frame", {
		Name = "Itens",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 31,
	}, conteudo)
	novo("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		HorizontalFlex = Enum.UIFlexAlignment.SpaceEvenly,
		Padding = UDim.new(0, 10),
	}, itens)
	local esquerda, direita = itens, itens
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
	local function separador(pai: Instance, ordem: number): Frame
		return novo("Frame", {
			Name = "Separador",
			LayoutOrder = ordem,
			Size = UDim2.fromOffset(2, 34),
			BackgroundColor3 = coresTopo.separador,
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
		local legenda = textoTopo(col, 2, f.label, 12, FRACO)
		return fr, valor, legenda
	end

	-- companhia: nome inteiro e título do presidente
	-- (escondido desde 22/11: o nome quase não muda e já aparece na aba Companhia e no placar;
	-- a barra fica mais curta e cabe melhor no celular)
	local blocoNome = bloco(esquerda, "Companhia", 1)
	blocoNome.Visible = false
	self.lblNome = textoTopo(blocoNome, 1, f.display, 20, CREME)
	self.lblNome.Name = "NomeCompanhia"
	-- caixa e renda
	local _, lblDinheiro, lblRenda = item(esquerda, "Caixa", 3, "dinheiro", Emojis.dinheiro, 24, 36)
	self.lblDinheiro, self.lblRenda = lblDinheiro, lblRenda
	self.lblDinheiro.Text = "…"
	local sepData = separador(esquerda, 4)
	-- data do jogo (1 minuto = 1 dia) e era
	local blocoData = bloco(esquerda, "Data", 5)
	self.lblData = textoTopo(blocoData, 1, f.display, 19, CREME)
	self.lblEra = textoTopo(blocoData, 2, f.label, 13, FRACO)
	self.lblEra.Text = era.nome

	-- recursos
	self.recursos = {} :: { [string]: { quadro: Frame, valor: TextLabel, legenda: TextLabel } }
	local listaRecursos = {
		{ "trens", "trens", Emojis.trens, L("trens", "trains") },
		{ "passageiros", "passageiros", Emojis.passageiros or "🧳", L("passageiros/dia", "passengers/day") },
		{ "satisfacao", "satisfacao", Emojis.satisfacao, L("satisfação", "satisfaction") },
		{ "carga", "carga", Emojis.cargas or "📦", L("carga/dia", "cargo/day") },
		{ "contrato", "decisao", Emojis.contratos, L("contrato", "contract") },
	}
	local sepRecursos = separador(direita, 10)
	for i, r in listaRecursos do
		local q, v, l = item(direita, "Recurso_" .. r[1], 20 + i, r[2], r[3], 19, 32)
		l.Text = r[4]
		self.recursos[r[1]] = { quadro = q, valor = v, legenda = l }
	end
	separador(direita, 30)
	-- nível: título fica junto do nome; aqui o número, a barra e o XP
	-- título do presidente (Negociante, Barão...) junto do nível e da barra de XP
	local blocoNivel = bloco(direita, "Nivel", 31, 180)
	self.lblCargo = textoTopo(blocoNivel, 1, f.display, 16, CREME)
	self.lblCargo.Name = "Titulo"
	local trilho = novo("Frame", { Name = "Trilho", LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, ZIndex = 31 }, blocoNivel)
	self.cheioXp = est:barra(trilho, 1)
	self.lblNivel = textoTopo(blocoNivel, 3, f.label, 11, FRACO)
	self.lblNivel.Name = "Nivel"

	-- se a tela for estreita, a faixa de recursos perde itens (o menos importante primeiro)
	local ORDEM_ESCONDER = { "carga", "passageiros", "trens", "satisfacao" }
	local function largura(): number
		local total, n = 0, 0
		for _, filho in itens:GetChildren() do
			if filho:IsA("GuiObject") and filho.Visible then
				total += filho.AbsoluteSize.X
				n += 1
			end
		end
		return total + 12 * n
	end
	local function caber()
		for _, r in self.recursos do
			r.quadro.Visible = r ~= self.recursos.contrato or self.estado ~= nil and self.estado.contrato ~= nil
		end
		blocoData.Visible = true
		-- um separador só aparece se o bloco depois dele aparece
		local function separadores()
			sepData.Visible = blocoData.Visible
			local algum = false
			for _, r in self.recursos do
				algum = algum or r.quadro.Visible
			end
			sepRecursos.Visible = algum
		end
		separadores()
		for _, id in ORDEM_ESCONDER do
			if largura() <= conteudo.AbsoluteSize.X then
				return
			end
			self.recursos[id].quadro.Visible = false
			separadores()
		end
		if largura() > conteudo.AbsoluteSize.X then
			blocoData.Visible = false
			separadores()
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
	-- sem caixa: só o texto, claro com contorno escuro (o mesmo jeito das conquistas dos outros jogadores)
	self.aviso = novo("Frame", {
		Name = "Aviso",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, Estilo.TOPO_TELA + 14),
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 30,
	}, tela)
	self.lblAviso = novo("TextLabel", {
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		Text = "",
		RichText = true,
		FontFace = f.body,
		TextSize = 18,
		TextColor3 = Color3.fromRGB(250, 245, 230),
		TextStrokeColor3 = Color3.fromRGB(25, 20, 15),
		TextStrokeTransparency = 0.2,
		ZIndex = 31,
	}, self.aviso)

	-- ---------------------------------------------------- conquistas de outros jogadores (logo abaixo da barra)
	self.feed = novo("TextLabel", {
		Name = "FeedConquistas",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, Estilo.TOPO_TELA + 46),
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1,
		Text = "",
		RichText = true,
		FontFace = f.body,
		TextSize = 16,
		TextColor3 = Color3.fromRGB(250, 245, 230),
		TextTransparency = 1,
		-- sem fundo: texto claro com contorno escuro, legível sobre o mapa claro ou escuro
		TextStrokeColor3 = Color3.fromRGB(25, 20, 15),
		TextStrokeTransparency = 1,
		ZIndex = 29,
	}, tela)
	self._filaFeed = {} :: { string }

	-- ---------------------------------------------------- painel da concessão (direita)
	local painel = caixa({
		Name = "Concessao",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -Estilo.MARGEM_LATERAL, 0, Estilo.TOPO_TELA + 12),
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
			RichText = true,
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
	self.lblDetalhes.LineHeight = 1.25
	self.lblTrens.LineHeight = 1.2

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
	self.feed:Destroy()
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

-- Faixa discreta embaixo da barra de cima: "Fulano ganhou a conquista X". Uma de cada vez, some sozinha.
function Interface.conquistaDeOutro(self: Interface, msg: string)
	table.insert(self._filaFeed, msg)
	if #self._filaFeed > 4 then
		table.remove(self._filaFeed, 1) -- muitas de uma vez: fica só com as mais recentes
	end
	if self._feedRodando then
		return
	end
	self._feedRodando = true
	task.spawn(function()
		local TweenService = game:GetService("TweenService")
		while #self._filaFeed > 0 and self.feed.Parent do
			local texto = table.remove(self._filaFeed, 1)
			self.feed.Text = texto
			local info = TweenInfo.new(0.35)
			TweenService:Create(self.feed, info, { TextTransparency = 0, TextStrokeTransparency = 0.3 }):Play()
			task.wait(4.5)
			TweenService:Create(self.feed, info, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
			task.wait(0.5)
		end
		self._feedRodando = false
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
	self.lblCargo.Text = `{Emojis.nivel} {Economia.tituloNivel(nivel, estado.era, Idioma.atual)}`
	self.lblNivel.Text = if xpDoNivel > 0
		then L(`NÍVEL {nivel} · {numero(xpNoNivel)} / {numero(xpDoNivel)} XP`, `LEVEL {nivel} · {numero(xpNoNivel)} / {numero(xpDoNivel)} XP`)
		else L(`NÍVEL {nivel} · MÁXIMO`, `LEVEL {nivel} · MAX`)
	self.cheioXp.Size = UDim2.fromScale(if xpDoNivel > 0 then math.clamp(xpNoNivel / xpDoNivel, 0, 1) else 1, 1)
	-- nome muito comprido é cortado à mão (o corte automático do Roblox mede antes de a fonte carregar)
	local nome = estado.nomeCompanhia or Idioma.T("companhia_padrao")
	if utf8.len(nome) and (utf8.len(nome) :: number) > 28 then
		nome = string.sub(nome, 1, (utf8.offset(nome, 28) :: number) - 1) .. "…"
	end
	self.lblNome.Text = nome
	-- data: 1 minuto de verdade = 1 dia do jogo; o ano acompanha o progresso da era
	local dia = math.floor(workspace:GetServerTimeNow() / Metas.SEGUNDOS_POR_DIA)
	self.lblData.Text = L(`{dia % 30 + 1} de {MESES[(dia // 30) % 12 + 1]} de {Economia.anoAtual(estado, self.dados)}`, `{MESES_EN[(dia // 30) % 12 + 1]} {dia % 30 + 1}, {Economia.anoAtual(estado, self.dados)}`)
	self.lblEra.Text = self.era.nome
	self.lblDinheiro.Text = Economia.formatar(estado.dinheiro, simbolo)
	if estado.renda >= 0 then
		-- Lucro em Dobro / Impulso 2x: o multiplicador aparece junto da renda
		local fator = Economia.fatorLoja(estado)
		local extra = if fator > 1 then `  {Emojis.velocidade}×{fator}` else ""
		self.lblRenda.Text = L(`+ {Economia.formatar(estado.renda, simbolo, true)} por segundo{extra}`, `+ {Economia.formatar(estado.renda, simbolo, true)} per second{extra}`)
		self.lblRenda.TextColor3 = self.coresTopo.verde
	else
		-- manutenção maior que a receita
		self.lblRenda.Text = L(`− {Economia.formatar(-estado.renda, simbolo, true)} por segundo`, `− {Economia.formatar(-estado.renda, simbolo, true)} per second`)
		self.lblRenda.TextColor3 = self.coresTopo.vermelho
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
		self.btnEra.Text = L(`{emoji} <b>Modernizar: {eraProx.nome}</b>\nRenda ×{fator} nas linhas · {Economia.formatar(proxima.custo, simbolo)}`, `{emoji} <b>Modernize: {eraProx.nome}</b>\nIncome ×{fator} on lines · {Economia.formatar(proxima.custo, simbolo)}`)
		Estilo.new(self.era):habilitar(self.btnEra, podePagar)
	else
		self.linhaEra.Visible = false
	end
	if estado.ganhoOffline and estado.ganhoOffline > 0.5 then
		self:avisar(L(`{Emojis.relogio} Enquanto você esteve fora, seus trens renderam {Economia.formatar(estado.ganhoOffline, simbolo)}`, `{Emojis.relogio} While you were away, your trains earned {Economia.formatar(estado.ganhoOffline, simbolo)}`), 6)
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
local PORTES_EN = { "Village", "Town", "City", "Regional capital", "Metropolis" }

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

	self.lblCabecalho.Text = L(`ESTAÇÃO · {maiusculas(PORTES[e.porte] or "")}{if e.porto then " · PORTO" else ""}`, `STATION · {string.upper(PORTES_EN[e.porte] or "")}{if e.porto then " · PORT" else ""}`)
	self.lblTitulo.Text = e.nome
	local linhas = {}
	for i, def in Economia.NIVEIS_ESTACAO do
		local marca = if i <= nivel then Emojis.confirmar elseif i == nivel + 1 then Emojis.mais else Emojis.cadeado
		table.insert(linhas, `{marca} {def.nome}`)
	end
	table.insert(linhas, "")
	table.insert(linhas, L(`{Emojis.renda} Bônus atual: +{math.round(nivel * Economia.BONUS_POR_NIVEL * 100)}% na renda dos trechos que chegam aqui`, `{Emojis.renda} Current bonus: +{math.round(nivel * Economia.BONUS_POR_NIVEL * 100)}% income on the sections arriving here`))
	if e.produz and Economia.CARGAS[e.produz] then
		local def = Economia.CARGAS[e.produz]
		local conectada = Economia.conectadasAoPorto(estado, dados)[id]
		table.insert(linhas, L(`{(Emojis :: any)[def.emoji]} Produz {string.lower(def.nome)}{if conectada then " (chegando a um porto)" else " (sem trilho até um porto)"}`, `{(Emojis :: any)[def.emoji]} Produces {string.lower(def.nome)}{if conectada then " (reaching a port)" else " (no rail to a port)"}`))
	end
	self.lblDetalhes.Text = table.concat(linhas, "\n")

	local custo = Economia.custoMelhoria(estado, dados, id)
	if not naRede then
		self.btnConstruir.Text = L(`{Emojis.cadeado} Fora da rede`, `{Emojis.cadeado} Off the network`)
		self.lblMotivo.Text = L("Construa um trecho até esta estação para poder melhorá-la.", "Build a section to this station to upgrade it.")
		self.btnConstruir.Active, self.btnConstruir.AutoButtonColor, self.btnConstruir.BackgroundTransparency = false, false, 0.6
	elseif not custo then
		self.btnConstruir.Text = L(`{Emojis.prestigio} Nível máximo`, `{Emojis.prestigio} Top level`)
		self.lblMotivo.Text = ""
		self.btnConstruir.Active, self.btnConstruir.AutoButtonColor, self.btnConstruir.BackgroundTransparency = false, false, 0.6
	else
		local proximo = Economia.NIVEIS_ESTACAO[nivel + 1].nome
		local podePagar = estado.dinheiro >= custo
		self.btnConstruir.Text = `{Emojis.melhorar} {proximo} · {Economia.formatar(custo, simbolo)}`
		self.lblMotivo.Text = if podePagar then L(`+{math.round(Economia.BONUS_POR_NIVEL * 100)}% na renda dos trechos desta estação.`, `+{math.round(Economia.BONUS_POR_NIVEL * 100)}% income on this station's sections.`) else L(`Faltam {Economia.formatar(custo - estado.dinheiro, simbolo)}.`, `{Economia.formatar(custo - estado.dinheiro, simbolo)} short.`)
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
	local estado, dados, c = self.estado, self.dados, Estilo.new(self.era).c
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
	local nomeTerreno = if terreno.nomes then Idioma.t(terreno.nomes) else terreno.nome
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
	-- duas linhas curtas: o trecho (km e terreno) e o que ele dá (receita, manutenção, passageiros)
	local receita = Economia.formatar(Economia.rendaTrecho(dados, trecho, escolhida) * era, simbolo, true)
	local manut = Economia.formatar(Economia.manutencaoTrecho(trecho, escolhida), simbolo, true)
	self.lblDetalhes.Text = table.concat({
		`{Emojis.distancia} {opcao.km} km   {Emojis.terreno_montanha} {nomeTerreno}{if terreno.custo ~= 1 then ` ×{string.format("%.1f", terreno.custo)}` else ""}`,
		L(`{Emojis.renda} <b>+{receita}/s</b>   {Emojis.manutencao} −{manut}/s   {Emojis.passageiros} {Economia.numero(passageiros)}/h`, `{Emojis.renda} <b>+{receita}/s</b>   {Emojis.manutencao} −{manut}/s   {Emojis.passageiros} {Economia.numero(passageiros)}/h`),
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
		self.btnConstruir.Text = L(`{Emojis.confirmar} Trecho construído`, `{Emojis.confirmar} Section built`)
		self.btnConstruir.Active = false
		self.btnConstruir.AutoButtonColor = false
		self.btnConstruir.BackgroundTransparency = 0.6
		self.lblMotivo.Text = ""
	elseif situacao == "projeto" then
		self.btnConstruir.Text = L(`{Emojis.gabinete} Ainda é só um projeto`, `{Emojis.gabinete} Still just a project`)
		self.btnConstruir.Active = false
		self.btnConstruir.AutoButtonColor = false
		self.btnConstruir.BackgroundTransparency = 0.6
		self.lblMotivo.Text = L("Estude este projeto no Gabinete (menu de baixo) para liberar a construção.", "Study this project in the Cabinet (bottom menu) to unlock construction.")
	elseif situacao == "bloqueado" then
		self.btnConstruir.Text = L(`{Emojis.cadeado} Ainda fechado`, `{Emojis.cadeado} Still locked`)
		self.btnConstruir.Active = false
		self.btnConstruir.AutoButtonColor = false
		self.btnConstruir.BackgroundTransparency = 0.6
		if not Economia.linhaLiberada(estado, dados, iLinha) then
			self.lblMotivo.Text = L(`Para liberar, complete antes: {table.concat(Economia.faltaParaLiberar(estado, dados, iLinha), ", ")}.`, `To unlock, first finish: {table.concat(Economia.faltaParaLiberar(estado, dados, iLinha), ", ")}.`)
		else
			self.lblMotivo.Text = L("Construa antes o trecho anterior desta linha.", "Build the previous section of this line first.")
		end
	else
		local podePagar = estado.dinheiro >= custo
		self.btnConstruir.Text = L(`{Emojis.assinar} Assinar concessão · {Economia.formatar(custo, simbolo)}`, `{Emojis.assinar} Sign concession · {Economia.formatar(custo, simbolo)}`)
		self.btnConstruir.Active = podePagar
		self.btnConstruir.AutoButtonColor = podePagar
		self.btnConstruir.BackgroundTransparency = if podePagar then 0 else 0.6
		self.lblMotivo.Text = if podePagar then "" else L(`Faltam {Economia.formatar(custo - estado.dinheiro, simbolo)}.`, `{Economia.formatar(custo - estado.dinheiro, simbolo)} short.`)
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
		self.lblTrens.Text = L(`{Emojis.trens} O primeiro trem vem junto com o primeiro trecho. Cada trem leva {fmt(Economia.capacidadeTrem(estado))} passageiros/h.`, `{Emojis.trens} The first train comes with the first section. Each train carries {fmt(Economia.capacidadeTrem(estado))} passengers/h.`)
		self.lblTrens.TextColor3 = c.inkMuted
		self.btnTrem.Visible = false
	else
		local linhaFrota = L(`{Emojis.trens} <b>{trens}</b> {if trens == 1 then "trem" else "trens"} · {fmt(capacidade)} lugares para {fmt(demanda)}/h`, `{Emojis.trens} <b>{trens}</b> {if trens == 1 then "train" else "trains"} · {fmt(capacidade)} seats for {fmt(demanda)}/h`)
		if faltando > 0 then
			self.lblTrens.Text = L(`{linhaFrota}\n{Emojis.alerta} Só {servico}% embarcam: faltam {faltando}`, `{linhaFrota}\n{Emojis.alerta} Only {servico}% board: {faltando} more needed`)
			self.lblTrens.TextColor3 = c.negative
		elseif sobrando > 0 then
			self.lblTrens.Text = L(`{linhaFrota}\n{Emojis.alerta} {sobrando} vazio(s), custando {manutTrem}/s cada`, `{linhaFrota}\n{Emojis.alerta} {sobrando} empty, costing {manutTrem}/s each`)
			self.lblTrens.TextColor3 = c.negative
		else
			self.lblTrens.Text = L(`{linhaFrota}\n{Emojis.confirmar} Todos embarcam`, `{linhaFrota}\n{Emojis.confirmar} Everyone boards`)
			self.lblTrens.TextColor3 = c.positive
		end
		self.btnTrem.Visible = faltando > 0
		if faltando > 0 then
			local podePagar = estado.dinheiro >= custoTrem
			self.btnTrem.Text = L(`{Emojis.trens} Comprar trem · {Economia.formatar(custoTrem, simbolo)}`, `{Emojis.trens} Buy train · {Economia.formatar(custoTrem, simbolo)}`)
			self.btnTrem.Active = podePagar
			self.btnTrem.AutoButtonColor = podePagar
			self.btnTrem.BackgroundTransparency = if podePagar then 0 else 0.6
		end
		if Economia.podeVenderTrem(estado, linha) then
			self.btnVender.Visible = true
			self.btnVender.Text = L(`Vender 1 trem · + {Economia.formatar(Economia.valorVendaTrem(estado, linha), simbolo)}`, `Sell 1 train · + {Economia.formatar(Economia.valorVendaTrem(estado, linha), simbolo)}`)
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
		-- uma linha curta por carga: de onde, se chega ao porto e quanto rende por dia
		local _ = unidade
		if info.conectada then
			local dia = if v and v.reaisDia > 0 then L(` · {Economia.formatar(v.reaisDia, simbolo)}/dia`, ` · {Economia.formatar(v.reaisDia, simbolo)}/day`) else ""
			table.insert(linhasTexto, `{emoji} {nome}  <b>+{math.round(def.bonus * 100)}%</b>{dia}`)
		else
			table.insert(linhasTexto, L(`{emoji} {nome}  <i>sem porto</i>`, `{emoji} {nome}  <i>no port</i>`))
		end
	end
	local temCarga = #linhasTexto > 0
	self.divCarga.Visible = temCarga
	self.lblCarga.Visible = temCarga
	self.lblCarga.Text = table.concat(linhasTexto, "\n")
end

return Interface
