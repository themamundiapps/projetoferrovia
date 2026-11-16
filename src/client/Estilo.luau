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
		fundo.SliceCenter = nova.slice
		ajustar()
	end
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
			Size = UDim2.new(1, 0, 0, 0),
			BackgroundTransparency = 1,
			Image = p.id,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 31,
		}, pai)
		novo("UIAspectRatioConstraint", { AspectRatio = p.largura / p.altura }, img)
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

return Estilo
