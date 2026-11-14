--!strict
-- MapaView: desenha um mapa (tiles + trilhos + estações) dentro de um Frame e cuida de
-- arrastar (mouse/toque) e zoom (roda do mouse/pinça).
--
-- Tudo é guardado em coordenadas do mapa completo (pixels do mapa, ex.: 2048x2048).
-- Ao mudar o zoom, reposicionamos os elementos (são poucos); ao arrastar, só movemos o conteúdo.

local UserInputService = game:GetService("UserInputService")

local MapaView = {}
MapaView.__index = MapaView

export type EstadoTrecho = "construido" | "disponivel" | "bloqueado"

type Segmento = {
	a: Vector2,
	b: Vector2,
	casing: Frame,
	linha: Frame,
	estado: EstadoTrecho,
}

type Estacao = {
	id: string,
	pos: Vector2,
	porte: number,
	ponto: Frame,
	rotulo: TextLabel,
}

type RotuloMapa = {
	pos: Vector2,
	zoomMin: number,
	zoomMax: number,
	label: TextLabel,
}

type Tile = {
	x: number,
	y: number,
	w: number,
	h: number,
	imagem: ImageLabel,
	detalhe: boolean,
}

export type MapaView = typeof(setmetatable(
	{} :: {
		raiz: Frame,
		conteudo: Frame,
		largura: number,
		altura: number,
		zoom: number,
		zoomMin: number,
		zoomMax: number,
		pan: Vector2,
		era: any,
		tiles: { Tile },
		segmentos: { Segmento },
		estacoes: { Estacao },
		rotulosMapa: { RotuloMapa },
		conexoes: { RBXScriptConnection },
		aoMudarCamera: BindableEvent,
		foco: { min: Vector2, max: Vector2, margem: number }?,
		interagiu: boolean,
	},
	MapaView
))

-- Zoom mínimo para mostrar o nome da estação, por porte (5 = metrópole, 1 = vila).
local ZOOM_ROTULO = { [5] = 0, [4] = 0.8, [3] = 1.6, [2] = 2.6, [1] = 4 }
local ZOOM_MAX = 8
-- A partir deste zoom, as regiões de detalhe (alta resolução) aparecem por cima do mapa base.
local ZOOM_DETALHE = 1.8

-- Ordem das camadas (ZIndex).
local Z = {
	terra = 1,
	rios = 2,
	costa = 3,
	detalheFundo = 4,
	detalheTerra = 5,
	detalheRios = 6,
	detalheCosta = 7,
	rotuloMapa = 8, -- estados, regiões, rios, oceano (abaixo dos trilhos)
	contorno = 9,
	linha = 10,
	estacao = 11,
	rotulo = 12,
}

-- Cor e camada de cada tipo de tile.
local function estiloTile(camada: string, cores: any, detalhe: boolean): (Color3, number)
	if camada == "terra" then
		return cores.land, if detalhe then Z.detalheTerra else Z.terra
	elseif camada == "rios" then
		return cores.rio, if detalhe then Z.detalheRios else Z.rios
	end
	return cores.coast, if detalhe then Z.detalheCosta else Z.costa
end

local function novo(classe: string, props: { [string]: any }, pai: Instance?): Instance
	local inst = Instance.new(classe)
	for k, v in props do
		(inst :: any)[k] = v
	end
	if pai then
		inst.Parent = pai
	end
	return inst
end

function MapaView.new(pai: Instance, mapa: any, dados: any, era: any): MapaView
	local cores = era.cores

	local raiz = novo("Frame", {
		Name = "Mapa",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = cores.sea,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Active = false, -- deixa os gestos passarem; botões da interface (Active = true) bloqueiam o mapa
	}, pai) :: Frame

	if era.marPadrao and era.marTextura then
		novo("ImageLabel", {
			Name = "TexturaMar",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Image = era.marTextura,
			ImageColor3 = cores.seaPattern,
			ScaleType = Enum.ScaleType.Tile,
			TileSize = UDim2.fromOffset(128, 128),
			ZIndex = 0,
		}, raiz)
	end

	local conteudo = novo("Frame", {
		Name = "Conteudo",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(0, 0),
	}, raiz) :: Frame

	local self = setmetatable({
		raiz = raiz,
		conteudo = conteudo,
		largura = mapa.largura,
		altura = mapa.altura,
		zoom = 1,
		zoomMin = 0.1,
		zoomMax = ZOOM_MAX,
		pan = Vector2.zero,
		era = era,
		tiles = {},
		segmentos = {},
		estacoes = {},
		rotulosMapa = {},
		conexoes = {},
		aoMudarCamera = Instance.new("BindableEvent"),
		foco = nil,
		interagiu = false,
	}, MapaView)

	self:_criarTiles(mapa)
	self:_criarRotulosMapa(dados)
	self:_criarLinhas(dados)
	self:_criarEstacoes(dados)
	self:_conectarEntrada()

	table.insert(
		self.conexoes,
		raiz:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			self:_atualizarZoomMin()
			-- enquanto o jogador não mexeu no mapa, mantém o enquadramento inicial
			local foco = self.foco
			if foco and not self.interagiu then
				self:focar(foco.min, foco.max, foco.margem)
			else
				self:definirCamera(self.zoom, self.pan)
			end
		end)
	)

	self:_atualizarZoomMin()
	return self
end

-- ---------------------------------------------------------------- criação

function MapaView._criarTiles(self: MapaView, mapa: any)
	local cores = self.era.cores
	for _, t in mapa.tiles do
		if t.id == "rbxassetid://0" then
			continue -- ainda não enviado ao Roblox
		end
		local cor, z = estiloTile(t.camada, cores, false)
		local imagem = novo("ImageLabel", {
			Name = t.arquivo,
			BackgroundTransparency = 1,
			Image = t.id,
			ImageColor3 = cor,
			ScaleType = Enum.ScaleType.Stretch,
			ZIndex = z,
		}, self.conteudo) :: ImageLabel
		table.insert(self.tiles, { x = t.x, y = t.y, w = t.w, h = t.h, imagem = imagem, detalhe = false })
	end

	-- Regiões de detalhe: um fundo da cor do mar esconde o contorno grosso do mapa base,
	-- e por cima vêm os blocos de alta resolução (convertidos para coordenadas do mapa base).
	for _, d in mapa.detalhes or {} do
		local fundo = novo("ImageLabel", {
			Name = "detalhe_" .. d.id,
			BackgroundColor3 = cores.sea,
			BorderSizePixel = 0,
			Image = self.era.marTextura or "",
			ImageColor3 = cores.seaPattern,
			ScaleType = Enum.ScaleType.Tile,
			TileSize = UDim2.fromOffset(128, 128),
			ZIndex = Z.detalheFundo,
		}, self.conteudo) :: ImageLabel
		table.insert(self.tiles, { x = d.x0, y = d.y0, w = d.largura, h = d.altura, imagem = fundo, detalhe = true })
		for _, t in d.tiles do
			if t.id == "rbxassetid://0" then
				continue -- ainda não enviado ao Roblox
			end
			local cor, z = estiloTile(t.camada, cores, true)
			local imagem = novo("ImageLabel", {
				Name = t.arquivo,
				BackgroundTransparency = 1,
				Image = t.id,
				ImageColor3 = cor,
				ScaleType = Enum.ScaleType.Stretch,
				ZIndex = z,
			}, self.conteudo) :: ImageLabel
			table.insert(self.tiles, {
				x = d.x0 + t.x / d.escala,
				y = d.y0 + t.y / d.escala,
				w = t.w / d.escala,
				h = t.h / d.escala,
				imagem = imagem,
				detalhe = true,
			})
		end
	end
end

-- Estilo de cada tipo de rótulo do mapa: fonte, tamanho, cor e transparência.
local function estiloRotulo(tipo: string, era: any): (Font, number, Color3, number)
	local c, f = era.cores, era.fontes
	if tipo == "estado" then
		return f.display, 20, c.ink, 0.78
	elseif tipo == "oceano" then
		return f.display, 24, c.ink, 0.5
	elseif tipo == "rio" then
		return f.label, 14, c.rio, 0
	end
	return f.label, 15, c.inkMuted, 0.1 -- regiao
end

function MapaView._criarRotulosMapa(self: MapaView, dados: any)
	for i, r in dados.rotulos or {} do
		local fonte, tamanho, cor, transp = estiloRotulo(r.tipo, self.era)
		local label = novo("TextLabel", {
			Name = "rotulo_" .. i,
			AnchorPoint = Vector2.new(0.5, 0.5),
			AutomaticSize = Enum.AutomaticSize.XY,
			Size = UDim2.fromOffset(0, 0),
			BackgroundTransparency = 1,
			Text = r.texto,
			FontFace = fonte,
			TextSize = tamanho,
			TextColor3 = cor,
			TextTransparency = transp,
			LineHeight = 1.1,
			Rotation = r.angulo or 0,
			ZIndex = Z.rotuloMapa,
		}, self.conteudo) :: TextLabel
		table.insert(self.rotulosMapa, { pos = r.pos, zoomMin = r.zoomMin or 0, zoomMax = r.zoomMax or 99, label = label })
	end
end

function MapaView._criarLinhas(self: MapaView, dados: any)
	local cores = self.era.cores
	for _, linha in dados.linhas do
		local cor: Color3 = self.era.linhas[linha.cor] or cores.ink
		for _, trecho in linha.trechos do
			local a: Vector2 = dados.estacoes[trecho.de].pos
			local b: Vector2 = dados.estacoes[trecho.para].pos
			local casing = novo("Frame", {
				Name = trecho.id .. "_contorno",
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = cores.ink,
				BorderSizePixel = 0,
				ZIndex = Z.contorno,
			}, self.conteudo) :: Frame
			local frame = novo("Frame", {
				Name = trecho.id,
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = cor,
				BorderSizePixel = 0,
				ZIndex = Z.linha,
			}, self.conteudo) :: Frame
			table.insert(self.segmentos, { a = a, b = b, casing = casing, linha = frame, estado = "construido" })
		end
	end
end

function MapaView._criarEstacoes(self: MapaView, dados: any)
	local cores = self.era.cores
	local fontes = self.era.fontes
	for id, e in dados.estacoes do
		local tamanho = 10 + e.porte * 2
		local ponto = novo("Frame", {
			Name = id,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(tamanho, tamanho),
			BackgroundColor3 = cores.panel,
			ZIndex = Z.estacao,
		}, self.conteudo) :: Frame
		novo("UICorner", { CornerRadius = UDim.new(0.5, 0) }, ponto)
		novo("UIStroke", { Color = cores.ink, Thickness = 3 }, ponto)

		local rotulo = novo("TextLabel", {
			Name = id .. "_nome",
			AnchorPoint = Vector2.new(0, 0.5),
			AutomaticSize = Enum.AutomaticSize.XY,
			Size = UDim2.fromOffset(0, 0),
			BackgroundTransparency = 1,
			Text = e.nome,
			FontFace = fontes.display,
			TextSize = if e.porte >= 4 then 16 else 14,
			TextColor3 = cores.ink,
			ZIndex = Z.rotulo,
		}, self.conteudo) :: TextLabel
		novo("UIStroke", {
			Color = cores.panel,
			Thickness = 2,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
		}, rotulo)

		table.insert(self.estacoes, { id = id, pos = e.pos, porte = e.porte, ponto = ponto, rotulo = rotulo })
	end
end

-- ---------------------------------------------------------------- câmera

function MapaView._atualizarZoomMin(self: MapaView)
	local tela = self.raiz.AbsoluteSize
	if tela.X <= 0 or tela.Y <= 0 then
		return
	end
	self.zoomMin = math.min(tela.X / self.largura, tela.Y / self.altura)
end

local function limitarEixo(pan: number, tamanhoMapa: number, tela: number): number
	if tamanhoMapa <= tela then
		return (tela - tamanhoMapa) / 2
	end
	return math.clamp(pan, tela - tamanhoMapa, 0)
end

function MapaView.definirCamera(self: MapaView, zoom: number, pan: Vector2)
	local tela = self.raiz.AbsoluteSize
	zoom = math.clamp(zoom, self.zoomMin, self.zoomMax)
	local mudouZoom = zoom ~= self.zoom
	self.zoom = zoom
	self.pan = Vector2.new(
		limitarEixo(pan.X, self.largura * zoom, tela.X),
		limitarEixo(pan.Y, self.altura * zoom, tela.Y)
	)
	self.conteudo.Position = UDim2.fromOffset(math.round(self.pan.X), math.round(self.pan.Y))
	if mudouZoom then
		self:_layout()
	end
	self.aoMudarCamera:Fire(self.zoom)
end

-- Aplica um fator de zoom mantendo fixo o ponto da tela informado (cursor ou centro da pinça).
function MapaView.zoomEm(self: MapaView, novoZoom: number, pontoTela: Vector2)
	novoZoom = math.clamp(novoZoom, self.zoomMin, self.zoomMax)
	local local_ = pontoTela - self.raiz.AbsolutePosition
	local noMapa = (local_ - self.pan) / self.zoom
	self:definirCamera(novoZoom, local_ - noMapa * novoZoom)
end

-- Enquadra uma caixa do mapa (em pixels do mapa) com uma margem.
function MapaView.focar(self: MapaView, min: Vector2, max: Vector2, margem: number?)
	local m = margem or 60
	self.foco = { min = min, max = max, margem = m }
	local tela = self.raiz.AbsoluteSize
	local tam = max - min
	local zoom = math.min((tela.X - m * 2) / math.max(tam.X, 1), (tela.Y - m * 2) / math.max(tam.Y, 1))
	zoom = math.clamp(zoom, self.zoomMin, self.zoomMax)
	local centro = (min + max) / 2
	self.zoom = -1 -- força relayout
	self:definirCamera(zoom, tela / 2 - centro * zoom)
end

function MapaView._layout(self: MapaView)
	local z = self.zoom
	self.conteudo.Size = UDim2.fromOffset(self.largura * z, self.altura * z)

	local mostrarDetalhe = z >= ZOOM_DETALHE
	for _, t in self.tiles do
		if t.detalhe then
			t.imagem.Visible = mostrarDetalhe
			if not mostrarDetalhe then
				continue
			end
		end
		-- +1 px evita frestas finas entre os blocos
		t.imagem.Position = UDim2.fromOffset(math.floor(t.x * z), math.floor(t.y * z))
		t.imagem.Size = UDim2.fromOffset(math.ceil(t.w * z) + 1, math.ceil(t.h * z) + 1)
	end

	local espessura = math.clamp(2 + z * 0.9, 4, 10)
	for _, s in self.segmentos do
		local a, b = s.a * z, s.b * z
		local d = b - a
		local meio = (a + b) / 2
		local angulo = math.deg(math.atan2(d.Y, d.X))
		local comprimento = d.Magnitude
		s.linha.Position = UDim2.fromOffset(meio.X, meio.Y)
		s.linha.Size = UDim2.fromOffset(comprimento, espessura)
		s.linha.Rotation = angulo
		s.casing.Position = s.linha.Position
		s.casing.Size = UDim2.fromOffset(comprimento + 2, espessura + 4)
		s.casing.Rotation = angulo
	end

	for _, r in self.rotulosMapa do
		local visivel = z >= r.zoomMin and z < r.zoomMax
		r.label.Visible = visivel
		if visivel then
			local p = r.pos * z
			r.label.Position = UDim2.fromOffset(p.X, p.Y)
		end
	end

	for _, e in self.estacoes do
		local p = e.pos * z
		e.ponto.Position = UDim2.fromOffset(p.X, p.Y)
		e.rotulo.Position = UDim2.fromOffset(p.X + 12, p.Y)
		e.rotulo.Visible = z >= (ZOOM_ROTULO[e.porte] or 0)
	end
end

-- ---------------------------------------------------------------- entrada

function MapaView._conectarEntrada(self: MapaView)
	local arrastando = false
	local ultimo = Vector2.zero

	local function dentro(pos: Vector2): boolean
		local p, t = self.raiz.AbsolutePosition, self.raiz.AbsoluteSize
		return pos.X >= p.X and pos.Y >= p.Y and pos.X <= p.X + t.X and pos.Y <= p.Y + t.Y
	end

	-- Mouse: arrastar com o botão esquerdo, zoom com a roda.
	table.insert(
		self.conexoes,
		UserInputService.InputBegan:Connect(function(input: InputObject, processado: boolean)
			if processado then
				return
			end
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				local pos = Vector2.new(input.Position.X, input.Position.Y)
				if dentro(pos) then
					arrastando = true
					ultimo = pos
					self.interagiu = true
				end
			end
		end)
	)
	table.insert(
		self.conexoes,
		UserInputService.InputEnded:Connect(function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				arrastando = false
			end
		end)
	)
	table.insert(
		self.conexoes,
		UserInputService.InputChanged:Connect(function(input: InputObject, processado: boolean)
			if input.UserInputType == Enum.UserInputType.MouseMovement and arrastando then
				local pos = Vector2.new(input.Position.X, input.Position.Y)
				self:definirCamera(self.zoom, self.pan + (pos - ultimo))
				ultimo = pos
			elseif input.UserInputType == Enum.UserInputType.MouseWheel and not processado then
				local pos = Vector2.new(input.Position.X, input.Position.Y)
				if dentro(pos) then
					self.interagiu = true
					local fator = if input.Position.Z > 0 then 1.15 else 1 / 1.15
					self:zoomEm(self.zoom * fator, pos)
				end
			end
		end)
	)

	-- Toque: arrastar com um dedo, pinça com dois.
	local panInicial = Vector2.zero
	table.insert(
		self.conexoes,
		UserInputService.TouchPan:Connect(function(_toques, translacao: Vector2, _vel, estado: Enum.UserInputState, processado: boolean)
			if processado then
				return
			end
			if estado == Enum.UserInputState.Begin then
				self.interagiu = true
				panInicial = self.pan
			elseif estado == Enum.UserInputState.Change then
				self:definirCamera(self.zoom, panInicial + translacao)
			end
		end)
	)

	local zoomInicial = 1
	table.insert(
		self.conexoes,
		UserInputService.TouchPinch:Connect(function(toques: { Vector2 }, escala: number, _vel, estado: Enum.UserInputState, processado: boolean)
			if processado then
				return
			end
			if estado == Enum.UserInputState.Begin then
				self.interagiu = true
				zoomInicial = self.zoom
			elseif estado == Enum.UserInputState.Change and #toques >= 2 then
				local centro = (toques[1] + toques[2]) / 2
				self:zoomEm(zoomInicial * escala, centro)
			end
		end)
	)
end

function MapaView.destruir(self: MapaView)
	for _, c in self.conexoes do
		c:Disconnect()
	end
	self.aoMudarCamera:Destroy()
	self.raiz:Destroy()
end

return MapaView
