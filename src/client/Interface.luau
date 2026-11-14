--!strict
-- Interface (cliente): caixa da companhia, painel da concessão e avisos.
-- Só mostra o estado que o servidor manda e pede ações; nunca decide nada sobre dinheiro.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Economia = require(Shared:WaitForChild("Economia"))
local Emojis = require(Shared:WaitForChild("Emojis"))

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
local ACENTOS = {
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

function Interface.new(tela: ScreenGui, era: any, dados: any)
	local c, f = era.cores, era.fontes
	local self = setmetatable({}, Interface)
	self.era = era
	self.dados = dados
	self.estado = nil :: any
	self.trechoAberto = nil :: string?
	self.alternativa = nil :: string?
	self.aoAgir = Instance.new("BindableEvent") -- (tipo, args)
	self.aoFechar = Instance.new("BindableEvent")

	local function caixa(props: { [string]: any }): Frame
		local fr = novo("Frame", props, tela)
		fr.BackgroundColor3 = c.panel
		fr.Active = true -- bloqueia o mapa embaixo
		fr.ZIndex = 30
		novo("UIStroke", { Color = c.ink, Thickness = era.forma.traco + 0.5 }, fr)
		if era.forma.canto > 0 then
			novo("UICorner", { CornerRadius = UDim.new(0, era.forma.canto) }, fr)
		end
		return fr
	end

	-- ---------------------------------------------------- caixa da companhia (canto superior esquerdo)
	local hud = caixa({
		Name = "Caixa",
		Position = UDim2.fromOffset(16, 16),
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.fromOffset(0, 0),
	})
	padding(hud, 12)
	novo("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) }, hud)
	novo("TextLabel", {
		LayoutOrder = 1,
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		Text = "CAIXA DA COMPANHIA",
		FontFace = f.label,
		TextSize = 13,
		TextColor3 = c.inkMuted,
		ZIndex = 31,
	}, hud)
	self.lblDinheiro = novo("TextLabel", {
		LayoutOrder = 2,
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		Text = "…",
		FontFace = f.display,
		TextSize = 32,
		TextColor3 = c.ink,
		ZIndex = 31,
	}, hud)
	self.lblRenda = novo("TextLabel", {
		LayoutOrder = 3,
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		Text = "",
		FontFace = f.number,
		TextSize = 15,
		TextColor3 = c.positive,
		ZIndex = 31,
	}, hud)

	-- ---------------------------------------------------- aviso (topo, centro)
	self.aviso = caixa({
		Name = "Aviso",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 16),
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
		Position = UDim2.new(1, -16, 0, 16),
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

	novo("Frame", { LayoutOrder = 7, Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = c.rule, BorderSizePixel = 0, ZIndex = 31 }, corpo)
	self.lblTrens = texto(8, f.body, 16, c.ink)
	self.btnTrem = botao(9, corpo)
	self.btnTrem.Name = "BtnTrem"
	self.btnTrem.BackgroundColor3 = c.ink
	self.btnTrem.TextColor3 = c.panel
	self.btnTrem.Size = UDim2.new(1, 0, 0, 40)

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
		if self.trechoAberto then
			self.aoAgir:Fire("construir", { trecho = self.trechoAberto, alternativa = self.alternativa })
		end
	end)
	self.btnTrem.Activated:Connect(function()
		local linha = self.trechoAberto and Economia.acharTrecho(self.dados, self.trechoAberto)
		if linha then
			self.aoAgir:Fire("trem", { linha = linha.id })
		end
	end)
	self.btnFechar.Activated:Connect(function()
		self:fechar()
	end)

	return self
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

function Interface.atualizarEstado(self: Interface, estado: any)
	self.estado = estado
	local simbolo = self.dados.simbolo
	self.lblDinheiro.Text = Economia.formatar(estado.dinheiro, simbolo)
	self.lblRenda.Text = `+ {Economia.formatar(estado.renda, simbolo, true)} por segundo`
	if estado.ganhoOffline and estado.ganhoOffline > 0.5 then
		self:avisar(`{Emojis.relogio} Enquanto você esteve fora, seus trens renderam {Economia.formatar(estado.ganhoOffline, simbolo)}`, 6)
	end
	if self.trechoAberto then
		self:_preencher()
	end
end

function Interface.abrir(self: Interface, trechoId: string)
	if self.trechoAberto ~= trechoId then
		self.alternativa = nil
	end
	self.trechoAberto = trechoId
	self.painel.Visible = true
	self:_preencher()
end

function Interface.fechar(self: Interface)
	self.trechoAberto = nil
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
	self.lblTitulo.Text = `{de} – {para}`
	self.lblDetalhes.Text = table.concat({
		`{Emojis.distancia} Extensão: {opcao.km} km`,
		`{Emojis.terreno_montanha} Terreno: {terreno.nome} (custo ×{string.format("%.1f", terreno.custo):gsub("%.", ",")})`,
		`{Emojis.renda} Renda: + {Economia.formatar(Economia.rendaTrecho(trecho, escolhida), simbolo, true)}/s`,
	}, "\n")

	-- opções de traçado (só antes de construir)
	for _, filho in self.opcoes:GetChildren() do
		if filho:IsA("TextButton") then
			filho:Destroy()
		end
	end
	local temOpcoes = trecho.alternativas ~= nil and situacao ~= "construido"
	self.opcoes.Visible = temOpcoes
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
	elseif situacao == "bloqueado" then
		self.btnConstruir.Text = `{Emojis.cadeado} Ainda fechado`
		self.btnConstruir.Active = false
		self.btnConstruir.AutoButtonColor = false
		self.btnConstruir.BackgroundTransparency = 0.6
		if not Economia.linhaLiberada(estado, dados, iLinha) then
			self.lblMotivo.Text = `Complete a linha {dados.linhas[iLinha - 1].nome} para liberar.`
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

	-- trens da linha
	local construidos = Economia.trechosConstruidos(estado, linha)
	local trens = estado.trens[linha.id] or 0
	local necessarios = Economia.trensNecessarios(estado, linha)
	local servico = math.round(Economia.servico(estado, linha) * 100)
	if construidos == 0 then
		self.lblTrens.Text = `{Emojis.trens} Trens: o primeiro vem junto com o primeiro trecho.`
		self.btnTrem.Visible = false
	else
		self.lblTrens.Text = `{Emojis.trens} Trens: {trens} de {necessarios} necessários · serviço {servico}%`
		local custoTrem = Economia.custoTrem(estado, linha)
		local podePagar = estado.dinheiro >= custoTrem
		self.btnTrem.Visible = true
		self.btnTrem.Text = `Comprar trem · {Economia.formatar(custoTrem, simbolo)}`
		self.btnTrem.Active = podePagar
		self.btnTrem.AutoButtonColor = podePagar
		self.btnTrem.BackgroundTransparency = if podePagar then 0 else 0.6
	end
end

return Interface
