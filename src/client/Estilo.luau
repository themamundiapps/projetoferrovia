--!strict
-- Estilo: peças de interface com o visual da era (caixas, textos, botões, listas).
-- Todos os painéis usam isto, para o jogo inteiro trocar de cara junto com a era.

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

-- Caixa de painel: fundo da era, contorno, bloqueia o mapa embaixo.
function Estilo.caixa(self: Estilo, props: { [string]: any }, pai: Instance): Frame
	local fr = novo("Frame", props, pai)
	fr.BackgroundColor3 = self.c.panel
	fr.Active = true
	if fr.ZIndex < 30 then
		fr.ZIndex = 30
	end
	novo("UIStroke", { Color = self.c.ink, Thickness = self.era.forma.traco + 0.5 }, fr)
	self:cantos(fr)
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
	self:cantos(b)
	if tipo == "discreto" then
		novo("UIStroke", { Color = c.rule, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, b)
	end
	return b
end

-- Liga/desliga a aparência de um botão (sem dinheiro, travado...).
function Estilo.habilitar(_self: Estilo, b: TextButton, sim: boolean)
	b.Active = sim
	b.AutoButtonColor = sim
	b.BackgroundTransparency = if sim then 0 else 0.6
end

function Estilo.divisor(self: Estilo, pai: Instance, ordem: number?): Frame
	return novo("Frame", {
		LayoutOrder = ordem or 0,
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = self.c.rule,
		BorderSizePixel = 0,
		ZIndex = 31,
	}, pai)
end

return Estilo
