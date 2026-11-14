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
	self.hud = hud
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

	self.btnEra = novo("TextButton", {
		Name = "BtnEra",
		LayoutOrder = 4,
		Size = UDim2.fromOffset(250, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = c.accent,
		TextColor3 = c.onAccent,
		FontFace = f.display,
		TextSize = 15,
		TextWrapped = true,
		RichText = true,
		Text = "",
		Visible = false,
		ZIndex = 32,
	}, hud)
	padding(self.btnEra, 8)
	if era.forma.canto > 0 then
		novo("UICorner", { CornerRadius = UDim.new(0, era.forma.canto) }, self.btnEra)
	end
	self.lblEra = novo("TextLabel", {
		LayoutOrder = 5,
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		Text = `{era.nome} · {era.anos}`,
		FontFace = f.label,
		TextSize = 13,
		TextColor3 = c.inkMuted,
		ZIndex = 31,
	}, hud)
	self.btnEra.Activated:Connect(function()
		self.aoAgir:Fire("modernizar", {})
	end)

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
	self.divCarga = novo("Frame", { LayoutOrder = 10, Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = c.rule, BorderSizePixel = 0, ZIndex = 31 }, corpo)
	self.lblCarga = texto(11, f.body, 15, c.ink)
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

function Interface.atualizarEstado(self: Interface, estado: any)
	self.estado = estado
	local simbolo = self.dados.simbolo
	self.lblDinheiro.Text = Economia.formatar(estado.dinheiro, simbolo)
	self.lblRenda.Text = `+ {Economia.formatar(estado.renda, simbolo, true)} por segundo`
	local proxima, liberada = Economia.proximaEra(estado, self.dados)
	local eraProx = proxima and self.eras and self.eras[proxima.id]
	if proxima and liberada and eraProx then
		local podePagar = estado.dinheiro >= proxima.custo
		self.btnEra.Visible = true
		self.btnEra.Text = `{Emojis.era_diesel} <b>Modernizar: {eraProx.nome}</b>\nRenda ×{proxima.multiplicador} em todas as linhas · {Economia.formatar(proxima.custo, simbolo)}`
		self.btnEra.Active = podePagar
		self.btnEra.AutoButtonColor = podePagar
		self.btnEra.BackgroundTransparency = if podePagar then 0 else 0.55
	else
		self.btnEra.Visible = false
	end
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
		`{Emojis.renda} Renda: + {Economia.formatar(Economia.rendaTrecho(trecho, escolhida) * Economia.multiplicadorEra(estado), simbolo, true)}/s{if Economia.multiplicadorEra(estado) > 1 then ` (×{Economia.multiplicadorEra(estado)} da era)` else ""}`,
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

	-- trens da linha (a frota vai só até o necessário)
	local construidos = Economia.trechosConstruidos(estado, linha)
	local trens = estado.trens[linha.id] or 0
	local necessarios = Economia.trensNecessarios(estado, linha)
	local faltando = Economia.trensFaltando(estado, linha)
	local servico = math.round(Economia.servico(estado, linha) * 100)
	if construidos == 0 then
		self.lblTrens.Text = `{Emojis.trens} O primeiro trem vem junto com o primeiro trecho. Cada 2 trechos pedem mais 1 trem.`
		self.lblTrens.TextColor3 = c.inkMuted
		self.btnTrem.Visible = false
	elseif faltando > 0 then
		local plural = if faltando == 1 then "trem" else "trens"
		self.lblTrens.Text = `{Emojis.alerta} Frota: {trens} de {necessarios} trens. Faltam {faltando} {plural}: esta linha rende só {servico}%.`
		self.lblTrens.TextColor3 = c.negative
		local custoTrem = Economia.custoTrem(estado, linha)
		local podePagar = estado.dinheiro >= custoTrem
		self.btnTrem.Visible = true
		self.btnTrem.Text = `{Emojis.trens} Comprar trem · {Economia.formatar(custoTrem, simbolo)}`
		self.btnTrem.Active = podePagar
		self.btnTrem.AutoButtonColor = podePagar
		self.btnTrem.BackgroundTransparency = if podePagar then 0 else 0.6
	else
		self.lblTrens.Text = `{Emojis.confirmar} Frota completa: {trens} de {necessarios} trens · rendendo 100%.`
		self.lblTrens.TextColor3 = c.positive
		self.btnTrem.Visible = false
	end

	-- cargas desta linha
	local cargas = Economia.cargasPorLinha(estado, dados)[linha.id]
	local linhasTexto = {}
	for _, info in cargas do
		local def = Economia.CARGAS[info.carga]
		local emoji = (Emojis :: any)[def.emoji] or ""
		local nome = dados.estacoes[info.estacao].nome
		if info.conectada then
			table.insert(linhasTexto, `{emoji} {def.nome} de {nome} chega a um porto: +{math.round(def.bonus * 100)}% na renda`)
		else
			table.insert(linhasTexto, `{emoji} {def.nome} de {nome} ainda sem trilho até um porto`)
		end
	end
	local temCarga = #linhasTexto > 0
	self.divCarga.Visible = temCarga
	self.lblCarga.Visible = temCarga
	self.lblCarga.Text = table.concat(linhasTexto, "\n")
end

return Interface
