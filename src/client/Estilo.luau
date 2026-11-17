--!strict
-- Estilo: peças de interface com o visual da era (caixas, textos, botões, listas).
-- Todos os painéis usam isto, para o jogo inteiro trocar de cara junto com a era.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Assets = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Assets"))

local Estilo = {}
Estilo.__index = Estilo

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
Estilo.novo = novo

export type Estilo = typeof(setmetatable({} :: { era: any, c: any, f: any }, Estilo))

function Estilo.new(era: any): Estilo
	return setmetatable({ era = era, c = era.cores, f = era.fontes }, Estilo)
end

function Estilo.padding(_self: Estilo, pai: Instance, px: number, py: number?)
	novo("UIPadding", {
		PaddingLeft = UDim.new(0, px),
		PaddingRight = UDim.new(0, px),
		PaddingTop = UDim.new(0, py or px),
		PaddingBottom = UDim.new(0, py or px),
	}, pai)
end

function Estilo.cantos(self: Estilo, pai: Instance)
	if self.era.forma.canto > 0 then
		novo("UICorner", { CornerRadius = UDim.new(0, self.era.forma.canto) }, pai)
	end
end

function Estilo.lista(_self: Estilo, pai: Instance, espaco: number, horizontal: boolean?)
	return novo("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, espaco),
		FillDirection = if horizontal then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical,
		VerticalAlignment = if horizontal then Enum.VerticalAlignment.Center else Enum.VerticalAlignment.Top,
	}, pai)
end

-- Moldura do kit de UI da era (imagem fatiada em 9) atrás de uma caixa: fica como irmã da caixa, um
-- pouco maior que ela, e acompanha posição, tamanho e visibilidade. Assim o conteúdo e as listas da
-- caixa não mudam. Devolve false se a era ainda não tem a peça enviada.
function Estilo.moldura(self: Estilo, fr: GuiObject): boolean
	local kit = Assets.KitUI[self.era.kit or ""]
	local p = kit and kit.painel
	local pai = fr.Parent
	if not p or p.id == "rbxassetid://0" or not pai or not pai:IsA("GuiBase2d") then
		return false
	end
	local b = p.borda
	local img = novo("ImageLabel", {
		Name = fr.Name .. "_Moldura",
		BackgroundTransparency = 1,
		Image = p.id,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = p.slice,
		SliceScale = p.escala,
		ZIndex = fr.ZIndex - 1,
		Active = false,
	}, pai) :: ImageLabel
	local function acompanhar()
		local origem = (pai :: GuiBase2d).AbsolutePosition
		img.Position = UDim2.fromOffset(fr.AbsolutePosition.X - origem.X - b, fr.AbsolutePosition.Y - origem.Y - b)
		local w, h = fr.AbsoluteSize.X + 2 * b, fr.AbsoluteSize.Y + 2 * b
		img.Size = UDim2.fromOffset(w, h)
		-- caixa pequena (caixa da companhia, barra do menu): os cantos encolhem para não cobrir o texto;
		-- nenhum canto passa de 1/4 do lado menor da caixa
		local cx, cy = p.slice.Min.X, p.slice.Min.Y
		local lado = math.min(w, h) * 0.25
		img.SliceScale = math.max(0.05, math.min(p.escala, lado / cy, lado / cx))
		img.Visible = fr.Visible
		img.ZIndex = fr.ZIndex - 1
	end
	fr:GetPropertyChangedSignal("AbsolutePosition"):Connect(acompanhar)
	fr:GetPropertyChangedSignal("AbsoluteSize"):Connect(acompanhar)
	fr:GetPropertyChangedSignal("Visible"):Connect(acompanhar)
	fr:GetPropertyChangedSignal("ZIndex"):Connect(acompanhar)
	fr.Destroying:Connect(function()
		img:Destroy()
	end)
	fr.BackgroundTransparency = 1
	acompanhar()
	return true
end

-- Cartão (quadro dentro dos painéis): com a peça do kit, o próprio cartão é a imagem fatiada (ele tem
-- lista e padding dentro, então a imagem não pode ser uma filha comum). Sem a peça, Frame com contorno.
function Estilo.cartao(self: Estilo, props: { [string]: any }, pai: Instance, destaque: boolean?): any
	local kit = Assets.KitUI[self.era.kit or ""]
	local p = kit and kit.cartao
	local c = self.c
	if p and p.id ~= "rbxassetid://0" then
		local img = novo("ImageLabel", props, pai)
		img.BackgroundTransparency = 1
		img.Image = p.id
		img.ScaleType = Enum.ScaleType.Slice
		img.SliceCenter = p.slice
		local function ajustar()
			local lado = math.min(img.AbsoluteSize.X, img.AbsoluteSize.Y) * 0.25
			img.SliceScale = math.max(0.05, math.min(p.escala, lado / p.slice.Min.X, lado / p.slice.Min.Y))
		end
		img:GetPropertyChangedSignal("AbsoluteSize"):Connect(ajustar)
		ajustar()
		if destaque then
			novo("UIStroke", { Color = c.accent, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, img)
		end
		self:padding(img, 16, 13)
		return img
	end
	local fr = novo("Frame", props, pai)
	fr.BackgroundColor3 = c.bg
	self:cantos(fr)
	novo("UIStroke", {
		Color = if destaque then c.accent else c.rule,
		Thickness = if destaque then 2 else 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, fr)
	self:padding(fr, 10, 8)
	return fr
end

-- Barra de progresso: com o kit, o trilho é a imagem fatiada e o preenchimento corre no canal dela.
-- Devolve o preenchimento (o código muda o Size dele em escala, de 0 a 1, e a cor).
function Estilo.barra(self: Estilo, pai: Instance, ordem: number?): Frame
	local c = self.c
	local kit = Assets.KitUI[self.era.kit or ""]
	local p = kit and kit.barra_fundo
	if p and p.id ~= "rbxassetid://0" then
		local altura = 18
		local trilho = novo("ImageLabel", {
			Name = "BarraKit",
			LayoutOrder = ordem or 0,
			Size = UDim2.new(1, 0, 0, altura),
			BackgroundTransparency = 1,
			Image = p.id,
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = p.slice,
			SliceScale = altura / (2 * p.slice.Min.Y),
			ZIndex = 33,
		}, pai) :: ImageLabel
		local escala = altura / (2 * p.slice.Min.Y)
		-- o canal fica entre as pontas de latão (largura da peça em pixels, vezes a escala na tela)
		local inset = math.floor(p.canal.x * p.largura * escala + 0.5)
		local canal = novo("Frame", {
			Name = "Canal",
			BackgroundTransparency = 1,
			Position = UDim2.new(0, inset, p.canal.topo, 0),
			Size = UDim2.new(1, -2 * inset, p.canal.base - p.canal.topo, 0),
			ClipsDescendants = true,
			ZIndex = 34,
		}, trilho)
		local q = kit.barra_cheia
		if q and q.id ~= "rbxassetid://0" then
			-- cápsula esmaltada tingida pela cor que o código der ao preenchimento (BackgroundColor3)
			local cheio = novo("ImageLabel", {
				Name = "Cheio",
				Size = UDim2.fromScale(0, 1),
				BackgroundTransparency = 1,
				BackgroundColor3 = c.accent,
				Image = q.id,
				ImageColor3 = c.accent,
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = q.slice,
				ZIndex = 35,
			}, canal) :: ImageLabel
			local function ajustar()
				local h = cheio.AbsoluteSize.Y
				cheio.SliceScale = math.max(0.05, h / (2 * q.slice.Min.Y))
				cheio.Visible = cheio.AbsoluteSize.X >= 2
			end
			cheio:GetPropertyChangedSignal("BackgroundColor3"):Connect(function()
				cheio.ImageColor3 = cheio.BackgroundColor3
			end)
			cheio:GetPropertyChangedSignal("AbsoluteSize"):Connect(ajustar)
			ajustar()
			return cheio :: any
		end
		return novo("Frame", {
			Size = UDim2.fromScale(0, 1),
			BackgroundColor3 = c.accent,
			BorderSizePixel = 0,
			ZIndex = 35,
		}, canal)
	end
	local fundo = novo("Frame", {
		LayoutOrder = ordem or 0,
		Size = UDim2.new(1, 0, 0, 10),
		BackgroundColor3 = c.panel,
		BorderSizePixel = 0,
		ZIndex = 33,
	}, pai)
	novo("UIStroke", { Color = c.ink, Thickness = 1 }, fundo)
	return novo("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = c.accent,
		BorderSizePixel = 0,
		ZIndex = 34,
	}, fundo)
end

-- Título de painel: com o kit, o texto vai centralizado numa placa (cabeçalho); sem ele, texto simples.
function Estilo.titulo(self: Estilo, txt: string, pai: Instance, ordem: number?): TextLabel
	local kit = Assets.KitUI[self.era.kit or ""]
	local p = kit and kit.cabecalho
	if p and p.id ~= "rbxassetid://0" then
		local altura = 52
		local escala = (altura / 2) / p.slice.Min.Y
		local placa = novo("ImageLabel", {
			Name = "Cabecalho",
			LayoutOrder = ordem or 0,
			Size = UDim2.new(1, 0, 0, altura),
			BackgroundTransparency = 1,
			Image = p.id,
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = p.slice,
			SliceScale = escala,
			ZIndex = 31,
		}, pai)
		local ponta = math.ceil(p.slice.Min.X * escala) + 4
		local l = self:texto("titulo", txt, placa, 0)
		l.AutomaticSize = Enum.AutomaticSize.None
		l.Position = UDim2.fromOffset(ponta, 0)
		l.Size = UDim2.new(1, -2 * ponta, 1, 0)
		l.TextXAlignment = Enum.TextXAlignment.Center
		l.TextYAlignment = Enum.TextYAlignment.Center
		-- nomes longos (o banco e o jornal mudam com a era) encolhem em vez de quebrar a linha
		l.TextWrapped = false
		l.TextScaled = true
		novo("UITextSizeConstraint", { MaxTextSize = 21, MinTextSize = 12 }, l)
		novo("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12) }, l)
		l.ZIndex = 32
		return l
	end
	return self:texto("titulo", txt, pai, ordem)
end

-- Quanto a moldura do kit sai para fora das caixas (0 se a era ainda não tem moldura).
function Estilo.bordaKit(self: Estilo): number
	local kit = Assets.KitUI[self.era.kit or ""]
	local p = kit and kit.painel
	return if p and p.id ~= "rbxassetid://0" then p.borda else 0
end

-- Caixa de painel: fundo da era, contorno (ou a moldura do kit), bloqueia o mapa embaixo.
function Estilo.caixa(self: Estilo, props: { [string]: any }, pai: Instance): Frame
	local fr = novo("Frame", props, pai)
	fr.BackgroundColor3 = self.c.panel
	fr.Active = true
	if fr.ZIndex < 30 then
		fr.ZIndex = 30
	end
	if not self:moldura(fr) then
		novo("UIStroke", { Color = self.c.ink, Thickness = self.era.forma.traco + 0.5 }, fr)
		self:cantos(fr)
	end
	return fr
end

export type TipoTexto = "titulo" | "subtitulo" | "rotulo" | "corpo" | "numero" | "fraco"

function Estilo.texto(self: Estilo, tipo: TipoTexto, txt: string, pai: Instance, ordem: number?): TextLabel
	local c, f = self.c, self.f
	local fonte, tam, cor = f.body, 16, c.ink
	if tipo == "titulo" then
		fonte, tam = f.display, 24
	elseif tipo == "subtitulo" then
		fonte, tam = f.display, 18
	elseif tipo == "rotulo" then
		fonte, tam, cor = f.label, 13, c.inkMuted
	elseif tipo == "numero" then
		fonte, tam = f.number, 16
	elseif tipo == "fraco" then
		fonte, tam, cor = f.body, 14, c.inkMuted
	end
	return novo("TextLabel", {
		LayoutOrder = ordem or 0,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Text = txt,
		TextWrapped = true,
		RichText = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		FontFace = fonte,
		TextSize = tam,
		TextColor3 = cor,
		ZIndex = 31,
	}, pai)
end

export type TipoBotao = "principal" | "secundario" | "discreto"

-- Veste um botão com a peça do kit: a imagem fatiada fica atrás e o texto passa para um rótulo por
-- cima dela (no modo Sibling, uma filha cobriria o texto do próprio botão). O botão continua um
-- TextButton: o resto do código segue mudando b.Text, b.TextSize etc., e o rótulo copia.
local PROPS_TEXTO = { Text = true, RichText = true, FontFace = true, TextSize = true, TextColor3 = true, TextWrapped = true, TextXAlignment = true, TextYAlignment = true, TextScaled = true }
local trocarPeca = setmetatable({} :: { [TextButton]: (any) -> () }, { __mode = "k" })
local function vestirBotao(b: TextButton, p: any)
	b.BackgroundTransparency = 1
	b.AutoButtonColor = false
	b.TextTransparency = 1
	local fundo = novo("ImageLabel", {
		Name = "FundoKit",
		BackgroundTransparency = 1,
		Image = p.id,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = p.slice,
		ZIndex = 1,
		Active = false,
	}, b) :: ImageLabel
	local rotulo = novo("TextLabel", {
		Name = "RotuloKit",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 2,
		Active = false,
	}, b) :: TextLabel
	-- cor de fundo do botão vira o tom da peça: fundo escuro (aba selecionada) escurece a imagem
	local base = Color3.new(1, 1, 1)
	local function tingir()
		local cor = b.BackgroundColor3
		local lum = 0.299 * cor.R + 0.587 * cor.G + 0.114 * cor.B
		base = if lum < 0.35 then cor:Lerp(Color3.new(1, 1, 1), 0.3) else Color3.new(1, 1, 1)
		fundo.ImageColor3 = base
	end
	local function copiar()
		rotulo.Text = b.Text
		rotulo.RichText = b.RichText
		rotulo.FontFace = b.FontFace
		rotulo.TextSize = b.TextSize
		rotulo.TextColor3 = b.TextColor3
		rotulo.TextWrapped = b.TextWrapped
		rotulo.TextScaled = b.TextScaled
		rotulo.TextXAlignment = b.TextXAlignment
		rotulo.TextYAlignment = b.TextYAlignment
	end
	-- a imagem cobre o botão inteiro, mesmo quando ele tem padding (o rótulo fica dentro do padding)
	local function ajustar()
		local pad = b:FindFirstChildOfClass("UIPadding")
		local l, r, t, d = 0, 0, 0, 0
		if pad then
			l, r, t, d = pad.PaddingLeft.Offset, pad.PaddingRight.Offset, pad.PaddingTop.Offset, pad.PaddingBottom.Offset
		end
		fundo.Position = UDim2.fromOffset(-l, -t)
		fundo.Size = UDim2.new(1, l + r, 1, t + d)
		local w, h = b.AbsoluteSize.X, b.AbsoluteSize.Y
		local cx, cy = p.slice.Min.X, p.slice.Min.Y
		-- as pontas ocupam a altura toda do botão
		local escala = math.max(0.05, math.min((h / 2) / cy, (w / 2) / cx))
		fundo.SliceScale = escala
		-- o texto não entra nas pontas (rebites e arabescos)
		-- (botão que cresce com o texto, como as abas, não encolhe o rótulo: senão o texto quebra a linha)
		local cresce = b.AutomaticSize == Enum.AutomaticSize.X or b.AutomaticSize == Enum.AutomaticSize.XY
		local folga = if cresce then 0 else math.max(0, cx * escala * 0.8 - l)
		rotulo.Position = UDim2.fromOffset(folga, 0)
		rotulo.Size = UDim2.new(1, -2 * folga, 1, 0)
	end
	b.Changed:Connect(function(prop: string)
		if PROPS_TEXTO[prop] then
			copiar()
		elseif prop == "BackgroundColor3" then
			tingir()
		end
	end)
	b:GetPropertyChangedSignal("AbsoluteSize"):Connect(ajustar)
	b.ChildAdded:Connect(function(filho)
		if filho:IsA("UIPadding") then
			task.defer(ajustar)
		end
	end)
	-- apertado: a peça escurece um pouco
	b.InputBegan:Connect(function(input)
		if b.Active and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			fundo.ImageColor3 = base:Lerp(Color3.new(0, 0, 0), 0.2)
		end
	end)
	b.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			fundo.ImageColor3 = base
		end
	end)
	b.MouseLeave:Connect(function()
		fundo.ImageColor3 = base
	end)
	tingir()
	copiar()
	ajustar()
	trocarPeca[b] = function(nova: any)
		p = nova
		fundo.Image = nova.id
		fundo.ScaleType = if nova.redondo then Enum.ScaleType.Fit else Enum.ScaleType.Slice
		fundo.SliceCenter = nova.slice
		ajustar()
	end
end

-- Aba da barra do menu em forma de medalhão (como nos jogos de estratégia): botão redondo com o ícone,
-- plaquinha com o nome embaixo e uma etiqueta em cima (cronômetro, ●). Só com o kit (botão redondo e
-- aba); devolve nil sem ele. O botão devolvido é transparente: o visual fica nas filhas.
export type Medalhao = { botao: TextButton, nome: TextLabel, etiqueta: TextLabel, placa: ImageLabel, disco: ImageLabel }

local function peca(kit: any, nome: string): any
	local p = kit and kit[nome]
	if p and p.id and p.id ~= "rbxassetid://0" then
		return p
	end
	return nil
end

-- Medidas do medalhão (com a peça própria) e da barra onde ele se apoia.
local MED_LARG, MED_ALT, MED_DISCO, MED_GAP = 86, 96, 66, 2
local BASE_ALT, BASE_PAD = 62, 46
local NOME_CLARO, NOME_ATIVO = Color3.fromRGB(236, 222, 190), Color3.fromRGB(255, 206, 96)

-- Barra de medalhões: base de mogno esticada (9-slice) e a fileira por cima.
-- Devolve (barra, fileira); sem as peças do kit devolve nil.
function Estilo.barraMedalhoes(self: Estilo, props: { [string]: any }, pai: Instance, n: number): (Frame?, Frame?)
	local kit = Assets.KitUI[self.era.kit or ""]
	local base = peca(kit, "base_medalhoes")
	if not (base and peca(kit, "medalhao")) then
		return nil, nil
	end
	local largFileira = n * MED_LARG + (n - 1) * MED_GAP
	local barra = novo("Frame", {
		Size = UDim2.fromOffset(largFileira + 2 * BASE_PAD, MED_ALT + 12),
		BackgroundTransparency = 1,
		ZIndex = 30,
	}, pai) :: Frame
	for k, v in props do
		(barra :: any)[k] = v
	end
	local escala = BASE_ALT / base.altura
	novo("ImageLabel", {
		Name = "Base",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 1),
		Size = UDim2.new(1, 0, 0, BASE_ALT),
		BackgroundTransparency = 1,
		Image = base.id,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = base.slice,
		SliceScale = escala,
		ZIndex = 30,
	}, barra)
	local fileira = novo("Frame", {
		Name = "Fileira",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.fromOffset(largFileira, MED_ALT),
		BackgroundTransparency = 1,
		ZIndex = 31,
	}, barra) :: Frame
	novo("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, MED_GAP),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
	}, fileira)
	return barra, fileira
end

-- Medalhão de aba: disco com ícone, plaquinha com o nome e etiqueta (cronômetro, aviso).
-- Usa as peças próprias (medalhao, placa_nome, icones) e, sem elas, o botão redondo e a aba.
function Estilo.medalhao(self: Estilo, emoji: string, nome: string, pai: Instance, ordem: number?, id: string?): Medalhao?
	local kit = Assets.KitUI[self.era.kit or ""]
	local med, placaNome = peca(kit, "medalhao"), peca(kit, "placa_nome")
	local disco0, placa0 = med or peca(kit, "botao_redondo"), placaNome or peca(kit, "aba")
	if not (disco0 and placa0 and peca(kit, "aba_ativa")) then
		return nil
	end
	local proprio = med ~= nil and placaNome ~= nil
	local c, f = self.c, self.era.fontes
	local b = novo("TextButton", {
		LayoutOrder = ordem or 0,
		Size = if proprio then UDim2.fromOffset(MED_LARG, MED_ALT) else UDim2.fromOffset(84, 96),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 32,
	}, pai) :: TextButton
	local tamDisco = if proprio then MED_DISCO else 62
	local disco = novo("ImageLabel", {
		Name = "Disco",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, if proprio then 0 else 8),
		Size = UDim2.fromOffset(tamDisco, tamDisco),
		BackgroundTransparency = 1,
		Image = disco0.id,
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 33,
	}, b) :: ImageLabel
	local icones = kit and kit.icones
	local icone = icones and id and icones[id]
	if proprio and icone and icone ~= "rbxassetid://0" then
		novo("ImageLabel", {
			Name = "Icone",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.64, 0.64),
			BackgroundTransparency = 1,
			Image = icone,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 34,
		}, disco)
	else
		novo("TextLabel", {
			Name = "Icone",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = emoji,
			TextSize = 27,
			ZIndex = 34,
		}, disco)
	end
	local altPlaca = if proprio then 22 else 24
	local pl = novo("ImageLabel", {
		Name = "Placa",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, 0),
		Size = if proprio then UDim2.new(1, -4, 0, altPlaca) else UDim2.new(1, 0, 0, altPlaca),
		BackgroundTransparency = 1,
		Image = placa0.id,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = placa0.slice,
		SliceScale = if proprio then altPlaca / placa0.altura else 12 / placa0.slice.Min.Y,
		ZIndex = 35,
	}, b) :: ImageLabel
	local lNome = novo("TextLabel", {
		Name = "Nome",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = nome,
		FontFace = if proprio then f.number else f.label,
		TextSize = 13,
		TextColor3 = if proprio then NOME_CLARO else c.ink,
		ZIndex = 36,
	}, pl) :: TextLabel
	local etiqueta = novo("TextLabel", {
		Name = "Etiqueta",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, -8),
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 18),
		BackgroundColor3 = if proprio then c.accent else c.ink,
		Text = "",
		FontFace = f.number,
		TextSize = 12,
		TextColor3 = c.panel,
		Visible = false,
		ZIndex = 37,
	}, b) :: TextLabel
	novo("UICorner", { CornerRadius = UDim.new(0, 9) }, etiqueta)
	novo("UIPadding", { PaddingLeft = UDim.new(0, 7), PaddingRight = UDim.new(0, 7) }, etiqueta)
	if proprio then
		novo("UIStroke", { Color = Color3.fromRGB(214, 172, 92), Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, etiqueta)
	end
	-- passar o mouse e apertar mexem no disco
	b.MouseEnter:Connect(function()
		disco.ImageColor3 = Color3.fromRGB(255, 245, 225)
	end)
	b.MouseLeave:Connect(function()
		disco.ImageColor3 = Color3.new(1, 1, 1)
	end)
	b.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			disco.ImageColor3 = Color3.fromRGB(205, 200, 190)
		end
	end)
	b.InputEnded:Connect(function()
		disco.ImageColor3 = Color3.new(1, 1, 1)
	end)
	return { botao = b, nome = lNome, etiqueta = etiqueta, placa = pl, disco = disco }
end

-- Marca o medalhão da aba aberta: disco maior e nome em destaque.
function Estilo.marcarMedalhao(self: Estilo, m: Medalhao, ativo: boolean)
	local kit = Assets.KitUI[self.era.kit or ""]
	if peca(kit, "medalhao") and peca(kit, "placa_nome") then
		local t = if ativo then MED_DISCO + 10 else MED_DISCO
		m.disco.Size = UDim2.fromOffset(t, t)
		m.disco.Position = UDim2.new(0.5, 0, 0, if ativo then -8 else 0)
		m.nome.TextColor3 = if ativo then NOME_ATIVO else NOME_CLARO
		m.placa.ImageColor3 = if ativo then Color3.fromRGB(255, 236, 200) else Color3.new(1, 1, 1)
		return
	end
	local p = if ativo then kit.aba_ativa else kit.aba
	m.placa.Image = p.id
	m.placa.SliceCenter = p.slice
	m.placa.SliceScale = 12 / p.slice.Min.Y
	m.disco.Size = if ativo then UDim2.fromOffset(70, 70) else UDim2.fromOffset(62, 62)
	m.disco.Position = if ativo then UDim2.new(0.5, 0, 0, 2) else UDim2.new(0.5, 0, 0, 8)
	m.nome.TextColor3 = if ativo then self.c.accent else self.c.ink
end

-- Botão redondo (zoom): peça inteira do kit; sem ela, botão discreto.
function Estilo.botaoRedondo(self: Estilo, txt: string, pai: Instance, ordem: number?): TextButton
	local b = self:botao("discreto", txt, pai, ordem)
	local kit = Assets.KitUI[self.era.kit or ""]
	local troca = trocarPeca[b]
	local med = peca(kit, "medalhao")
	if troca and med then
		-- mesmo medalhão da barra de baixo: aro de latão, miolo esmaltado e símbolo dourado
		troca({ id = med.id, slice = Rect.new(1, 1, 683, 683), redondo = true })
		b.TextColor3 = NOME_ATIVO
		b.FontFace = Font.new(self.era.fontes.display.Family, Enum.FontWeight.Bold)
	elseif troca and kit and kit.botao_redondo and kit.botao_redondo.id ~= "rbxassetid://0" then
		troca(kit.botao_redondo)
	end
	return b
end

-- Aba da barra do menu: peça própria do kit (normal e ativa); sem ela, botão discreto.
function Estilo.aba(self: Estilo, txt: string, pai: Instance, ordem: number?): TextButton
	local b = self:botao("discreto", txt, pai, ordem)
	local kit = Assets.KitUI[self.era.kit or ""]
	local troca = trocarPeca[b]
	if troca and kit and kit.aba and kit.aba.id ~= "rbxassetid://0" then
		troca(kit.aba)
	end
	return b
end

-- Marca a aba aberta: com o kit, troca para a peça ativa (texto continua escuro sobre o papel).
function Estilo.marcarAba(self: Estilo, b: TextButton, ativo: boolean)
	local c = self.c
	local kit = Assets.KitUI[self.era.kit or ""]
	local troca = trocarPeca[b]
	if troca and kit and kit.aba and kit.aba_ativa and kit.aba.id ~= "rbxassetid://0" and kit.aba_ativa.id ~= "rbxassetid://0" then
		troca(if ativo then kit.aba_ativa else kit.aba)
		b.TextColor3 = c.ink
		return
	end
	b.BackgroundColor3 = if ativo then c.ink else c.bg
	b.TextColor3 = if ativo then c.panel else c.ink
end

function Estilo.botao(self: Estilo, tipo: TipoBotao, txt: string, pai: Instance, ordem: number?): TextButton
	local c, f = self.c, self.f
	local b = novo("TextButton", {
		LayoutOrder = ordem or 0,
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundColor3 = if tipo == "principal" then c.accent elseif tipo == "secundario" then c.ink else c.bg,
		TextColor3 = if tipo == "principal" then c.onAccent elseif tipo == "secundario" then c.panel else c.ink,
		Text = txt,
		FontFace = f.display,
		TextSize = 16,
		TextWrapped = true,
		AutoButtonColor = true,
		ZIndex = 32,
	}, pai)
	local kit = Assets.KitUI[self.era.kit or ""]
	local peca = kit and (if tipo == "principal" then kit.botao else kit.botao_discreto)
	if peca and peca.id ~= "rbxassetid://0" then
		if tipo == "secundario" then
			-- o secundário (escuro) usa a peça clara: texto escuro
			b.BackgroundColor3 = c.bg
			b.TextColor3 = c.ink
		end
		vestirBotao(b, peca)
		return b
	end
	self:cantos(b)
	if tipo == "discreto" then
		novo("UIStroke", { Color = c.rule, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, b)
	end
	return b
end

-- Liga/desliga a aparência de um botão (sem dinheiro, travado...).
function Estilo.habilitar(_self: Estilo, b: TextButton, sim: boolean)
	b.Active = sim
	local fundo = b:FindFirstChild("FundoKit") :: ImageLabel?
	local rotulo = b:FindFirstChild("RotuloKit") :: TextLabel?
	if fundo and rotulo then
		fundo.ImageTransparency = if sim then 0 else 0.45
		rotulo.TextTransparency = if sim then 0 else 0.35
		return
	end
	b.AutoButtonColor = sim
	b.BackgroundTransparency = if sim then 0 else 0.6
end

function Estilo.divisor(self: Estilo, pai: Instance, ordem: number?): Frame
	local kit = Assets.KitUI[self.era.kit or ""]
	local p = kit and kit.divisor
	if p and p.id ~= "rbxassetid://0" then
		local img = novo("ImageLabel", {
			Name = "DivisorKit",
			LayoutOrder = ordem or 0,
			-- altura fixa e imagem inteira (Fit): na largura dos painéis (~300 px) a peça ocupa tudo
			Size = UDim2.new(1, 0, 0, 20),
			BackgroundTransparency = 1,
			Image = p.id,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 31,
		}, pai)
		return img
	end
	return novo("Frame", {
		LayoutOrder = ordem or 0,
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = self.c.rule,
		BorderSizePixel = 0,
		ZIndex = 31,
	}, pai)
end

-- ---------------------------------------------------------------- moldura da tela (barra de cima, gavetas)

Estilo.ALTURA_TOPO = 70 -- barra de cima
Estilo.LARGURA_ABA_LATERAL = 34 -- puxador das gavetas, colado nas bordas
Estilo.MARGEM_LATERAL = 34 + 10 -- onde começam os painéis encostados nas gavetas
Estilo.CREME = Color3.fromRGB(240, 226, 196) -- texto sobre a madeira
Estilo.CREME_FRACO = Color3.fromRGB(205, 184, 150)
Estilo.VERDE_CLARO = Color3.fromRGB(150, 205, 130)

-- Barra de cima de ponta a ponta: pontas de latão e miolo de mogno que se repete (os rebites não
-- esticam). Sem as peças, uma faixa escura simples. Devolve o frame (o conteúdo vai dentro dele).
function Estilo.barraTopo(self: Estilo, pai: Instance): Frame
	local kit = Assets.KitUI[self.era.kit or ""]
	local p = kit and kit.barra_topo
	local h = Estilo.ALTURA_TOPO
	local barra = novo("Frame", {
		Name = "BarraTopo",
		Size = UDim2.new(1, 0, 0, h),
		BackgroundColor3 = self.c.ink,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		Active = true,
		ZIndex = 28,
	}, pai) :: Frame
	if p and p.meio ~= "rbxassetid://0" then
		barra.BackgroundTransparency = 1
		local escala = h / p.altura
		local ponta = math.round(p.ponta * escala)
		novo("ImageLabel", {
			Name = "Esq",
			Size = UDim2.fromOffset(ponta, h),
			BackgroundTransparency = 1,
			Image = p.esq,
			ZIndex = 29,
		}, barra)
		novo("ImageLabel", {
			Name = "Meio",
			Position = UDim2.fromOffset(ponta, 0),
			Size = UDim2.new(1, -2 * ponta, 0, h),
			BackgroundTransparency = 1,
			Image = p.meio,
			ScaleType = Enum.ScaleType.Tile,
			TileSize = UDim2.fromOffset(math.round(p.largMeio * escala), h),
			ZIndex = 28,
		}, barra)
		novo("ImageLabel", {
			Name = "Dir",
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.fromScale(1, 0),
			Size = UDim2.fromOffset(ponta, h),
			BackgroundTransparency = 1,
			Image = p.dir,
			ZIndex = 29,
		}, barra)
	else
		novo("UIStroke", { Color = self.c.rule, Thickness = 2 }, barra)
	end
	return barra
end

-- Ícone desenhado do kit (imagem) ou, sem ele, o emoji.
function Estilo.icone(self: Estilo, nome: string, emoji: string, pai: Instance, tamanho: number, ordem: number?): GuiObject
	local kit = Assets.KitUI[self.era.kit or ""]
	local id = kit and kit.icones and kit.icones[nome]
	if id and id ~= "rbxassetid://0" then
		return novo("ImageLabel", {
			Name = "Icone",
			LayoutOrder = ordem or 0,
			Size = UDim2.fromOffset(tamanho, tamanho),
			BackgroundTransparency = 1,
			Image = id,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 31,
		}, pai)
	end
	return novo("TextLabel", {
		Name = "Icone",
		LayoutOrder = ordem or 0,
		Size = UDim2.fromOffset(tamanho, tamanho),
		BackgroundTransparency = 1,
		Text = emoji,
		TextSize = math.round(tamanho * 0.8),
		ZIndex = 31,
	}, pai)
end

-- Puxador de gaveta, colado na borda da tela (lado "esq" ou "dir"), com o nome escrito de pé.
function Estilo.abaLateral(self: Estilo, texto: string, lado: string, pai: Instance): TextButton
	local kit = Assets.KitUI[self.era.kit or ""]
	local p = kit and kit.aba_lateral
	local w, h = Estilo.LARGURA_ABA_LATERAL, 230
	local dir = lado == "dir"
	local b = novo("TextButton", {
		Name = if dir then "GavetaDir" else "GavetaEsq",
		AnchorPoint = Vector2.new(if dir then 1 else 0, 0.5),
		Position = UDim2.new(if dir then 1 else 0, 0, 0.5, 0),
		Size = UDim2.fromOffset(w, h),
		BackgroundColor3 = self.c.ink,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		ZIndex = 29,
	}, pai) :: TextButton
	local fundo: GuiObject = b
	if p and p.id ~= "rbxassetid://0" then
		b.BackgroundTransparency = 1
		fundo = novo("ImageLabel", {
			Name = "Fundo",
			-- a peça é reta à esquerda e redonda à direita; a da direita gira meia volta
			Rotation = if dir then 180 else 0,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Image = p.id,
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = p.slice,
			SliceScale = w / p.largura,
			ZIndex = 29,
		}, b)
	else
		novo("UICorner", { CornerRadius = UDim.new(0, 8) }, b)
	end
	local _ = fundo
	-- texto de pé: um rótulo deitado (largura = altura do puxador) girado 90°
	novo("TextLabel", {
		Name = "Rotulo",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(h - 40, w - 8),
		Rotation = if dir then 90 else -90,
		BackgroundTransparency = 1,
		Text = texto,
		FontFace = self.f.label,
		TextSize = 15,
		TextColor3 = Estilo.CREME,
		ZIndex = 30,
	}, b)
	b.MouseEnter:Connect(function()
		if fundo:IsA("ImageLabel") then
			(fundo :: ImageLabel).ImageColor3 = Color3.fromRGB(255, 240, 220)
		end
	end)
	b.MouseLeave:Connect(function()
		if fundo:IsA("ImageLabel") then
			(fundo :: ImageLabel).ImageColor3 = Color3.new(1, 1, 1)
		end
	end)
	return b
end

return Estilo
