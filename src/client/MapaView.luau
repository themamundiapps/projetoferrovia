--!strict
-- MapaView: desenha um mapa (tiles + trilhos + estações) dentro de um Frame e cuida de
-- arrastar (mouse/toque) e zoom (roda do mouse/pinça).
--
-- Tudo é guardado em coordenadas do mapa completo (pixels do mapa, ex.: 2048x2048).
-- Ao mudar o zoom, reposicionamos os elementos (são poucos); ao arrastar, só movemos o conteúdo.

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Emojis = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Emojis"))

local MapaView = {}
MapaView.__index = MapaView

export type EstadoTrecho = "construido" | "disponivel" | "bloqueado" | "projeto"

type Segmento = {
	id: string,
	cor: Color3,
	a: Vector2,
	b: Vector2,
	casing: Frame,
	linha: Frame,
	estado: EstadoTrecho,
	de: string,
	para: string,
	tracos: { Frame }, -- tracejado das linhas que ainda são só projeto (vazio nas outras)
}

type Estacao = {
	id: string,
	pos: Vector2,
	porte: number,
	ponto: Frame,
	traco: UIStroke,
	tamanho: number,
	nivel: number,
	rotulo: TextLabel,
	selo: TextLabel?, -- ☕/⛏️ das cidades produtoras
	apagada: boolean, -- cidade que só aparece em projetos ainda não estudados
}

-- Trens animados: cada linha tem uma trilha (os pontos dos trechos construídos) e alguns trens indo e voltando.
export type LinhaTrens = { id: string, pontos: { Vector2 }, n: number, situacao: string } -- "normal" | "lotado" | "vazio"
type Trilha = { pontos: { Vector2 }, acumulado: { number }, total: number, duracao: number }
type Trem = { frame: Frame, trilha: Trilha, fase: number }

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
	id: string?, -- imagem do bloco de detalhe; só fica carregada enquanto o bloco está na tela
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
		mostrarNomes: boolean,
		mostrarRotulos: boolean,
		mostrarTrens: boolean,
		trens: { Trem },
		assinaturaTrens: string,
		conexoes: { RBXScriptConnection },
		aoMudarCamera: BindableEvent,
		aoTocar: BindableEvent,
		selecionado: string?,
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
	trem = 11,
	estacao = 12,
	rotulo = 13,
}
-- No máximo este tanto de trens desenhados por linha (a frota pode ser maior).
local MAX_TRENS_VISIVEIS = 8

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
		mostrarNomes = true,
		mostrarRotulos = true,
		mostrarTrens = true,
		trens = {},
		assinaturaTrens = "",
		conexoes = {},
		aoMudarCamera = Instance.new("BindableEvent"),
		aoTocar = Instance.new("BindableEvent"),
		selecionado = nil,
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
		RunService.RenderStepped:Connect(function()
			self:_moverTrens()
		end)
	)

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
		local enviado = false
		for _, t in d.tiles do
			enviado = enviado or t.id ~= "rbxassetid://0"
		end
		if not enviado then
			continue -- bloco ainda não enviado ao Roblox: fica o mapa base
		end
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
			imagem.Image = "" -- carrega quando entrar na tela (_recortar)
			table.insert(self.tiles, {
				x = d.x0 + t.x / d.escala,
				y = d.y0 + t.y / d.escala,
				w = t.w / d.escala,
				h = t.h / d.escala,
				imagem = imagem,
				detalhe = true,
				id = t.id,
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
			-- linhas do Gabinete de Projetos ganham um tracejado, mostrado enquanto forem só projeto
			local tracos: { Frame } = {}
			if linha.projeto then
				local n = math.clamp(math.round((b - a).Magnitude / 9), 3, 40)
				for k = 1, n do
					tracos[k] = novo("Frame", {
						Name = `{trecho.id}_traco{k}`,
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundColor3 = cor,
						BorderSizePixel = 0,
						Visible = false,
						ZIndex = Z.linha,
					}, self.conteudo) :: Frame
				end
			end
			table.insert(self.segmentos, {
				id = trecho.id,
				cor = cor,
				a = a,
				b = b,
				casing = casing,
				linha = frame,
				estado = "construido",
				de = trecho.de,
				para = trecho.para,
				tracos = tracos,
			})
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
		local traco = novo("UIStroke", { Color = cores.ink, Thickness = 3 }, ponto) :: UIStroke

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

		local selo: TextLabel? = nil
		if e.produz then
			local emoji = (Emojis :: any)["carga_" .. e.produz]
			if emoji then
				selo = novo("TextLabel", {
					Name = id .. "_carga",
					AnchorPoint = Vector2.new(0.5, 1),
					Size = UDim2.fromOffset(22, 22),
					BackgroundTransparency = 1,
					Text = emoji,
					TextSize = 18,
					TextTransparency = 0.7,
					ZIndex = Z.rotulo,
				}, self.conteudo) :: TextLabel
			end
		end

		table.insert(self.estacoes, {
			id = id,
			pos = e.pos,
			porte = e.porte,
			ponto = ponto,
			traco = traco,
			tamanho = tamanho,
			nivel = 0,
			rotulo = rotulo,
			selo = selo,
			apagada = false,
		})
	end
end

-- ---------------------------------------------------------------- trechos

-- Aparência de cada situação: construído (cor cheia), disponível (cor clara, pode comprar), bloqueado (apagado).
function MapaView._estilizar(self: MapaView, s: Segmento)
	local cores = self.era.cores
	local sel = self.selecionado == s.id
	for _, t in s.tracos do
		t.Visible = s.estado == "projeto"
	end
	if s.estado == "projeto" then
		s.linha.BackgroundTransparency = 1
		s.casing.BackgroundTransparency = 1
		for _, t in s.tracos do
			t.BackgroundTransparency = 0.25
		end
	elseif s.estado == "construido" then
		s.linha.BackgroundColor3 = s.cor
		s.linha.BackgroundTransparency = 0
		s.casing.BackgroundTransparency = 0
	elseif s.estado == "disponivel" then
		s.linha.BackgroundColor3 = s.cor
		s.linha.BackgroundTransparency = 0.55
		s.casing.BackgroundTransparency = 0.7
	else
		s.linha.BackgroundColor3 = cores.locked
		s.linha.BackgroundTransparency = 0.82
		s.casing.BackgroundTransparency = 1
	end
	s.casing.BackgroundColor3 = if sel then cores.accent else cores.ink
	if sel then
		s.casing.BackgroundTransparency = 0
	end
end

function MapaView.definirSituacao(self: MapaView, situacoes: { [string]: string })
	local real: { [string]: boolean } = {} -- estações com algum trilho que não é só projeto
	for _, s in self.segmentos do
		local nova = situacoes[s.id]
		if nova then
			s.estado = nova :: any
		end
		if s.estado ~= "projeto" then
			real[s.de], real[s.para] = true, true
		end
		self:_estilizar(s)
	end
	-- cidades que só existem em projetos ficam esmaecidas, como um rascunho
	for _, e in self.estacoes do
		local apagada = not real[e.id]
		if apagada ~= e.apagada then
			e.apagada = apagada
			e.ponto.BackgroundTransparency = if apagada then 0.4 else 0
			e.traco.Transparency = if apagada then 0.55 else 0
			e.rotulo.TextTransparency = if apagada then 0.4 else 0
			local contorno = e.rotulo:FindFirstChildOfClass("UIStroke")
			if contorno then
				contorno.Transparency = if apagada then 0.5 else 0
			end
		end
	end
end

-- Selo de carga: forte quando a produtora tem caminho até um porto, apagado quando não.
function MapaView.definirCargas(self: MapaView, conectadas: { [string]: boolean })
	for _, e in self.estacoes do
		local selo = e.selo
		if selo then
			selo.TextTransparency = if conectadas[e.id] then 0 else 0.65
		end
	end
end

function MapaView.selecionar(self: MapaView, trechoId: string?)
	self.selecionado = trechoId
	for _, s in self.segmentos do
		self:_estilizar(s)
	end
	self:_layout()
end

-- Nível das estações: bolinha maior e contorno mais grosso a cada nível.
function MapaView.definirNiveis(self: MapaView, niveis: { [string]: number })
	for _, e in self.estacoes do
		e.nivel = niveis[e.id] or 0
		self:_tamanhoEstacao(e)
	end
end

-- Tamanho da bolinha da estação: cresce com o nível e encolhe quando o mapa está afastado,
-- para as cidades não se amontoarem com o país inteiro na tela.
function MapaView._tamanhoEstacao(self: MapaView, e: Estacao): number
	local escala = math.clamp(0.35 + 0.45 * self.zoom, 0.45, 1)
	local tam = (e.tamanho + e.nivel * 2) * escala
	e.ponto.Size = UDim2.fromOffset(tam, tam)
	e.traco.Thickness = math.max(1.2, (3 + e.nivel * 0.7) * escala)
	e.traco.Color = if e.nivel >= 5 then self.era.cores.accent else self.era.cores.ink
	return tam
end

function MapaView.definirAjuste(self: MapaView, chave: string, valor: boolean)
	if chave == "nomesEstacoes" then
		self.mostrarNomes = valor
	elseif chave == "nomesMapa" then
		self.mostrarRotulos = valor
	elseif chave == "trens" then
		self.mostrarTrens = valor
		for _, t in self.trens do
			t.frame.Visible = valor
		end
	end
	self:_layout()
end

-- ---------------------------------------------------------------- trens

local function espessuraLinha(zoom: number): number
	return math.clamp(2 + zoom * 0.9, 3, 10)
end

function MapaView._tamanhoTrens(self: MapaView)
	local altura = espessuraLinha(self.zoom) + (if self.zoom < 1 then 2 else 3)
	for _, t in self.trens do
		t.frame.Size = UDim2.fromOffset(altura * 1.9, altura)
	end
end

-- Define os trens de cada linha. Só recria os desenhos quando a frota, a trilha ou a lotação mudam.
function MapaView.definirTrens(self: MapaView, lista: { LinhaTrens })
	local partes = {}
	for _, l in lista do
		table.insert(partes, `{l.id}:{#l.pontos}:{l.n}:{l.situacao}`)
	end
	local assinatura = table.concat(partes, "|")
	if assinatura == self.assinaturaTrens then
		return
	end
	self.assinaturaTrens = assinatura
	for _, t in self.trens do
		t.frame:Destroy()
	end
	table.clear(self.trens)
	local cores = self.era.cores
	for _, l in lista do
		if #l.pontos < 2 or l.n <= 0 then
			continue
		end
		local acumulado = { 0 }
		for i = 2, #l.pontos do
			acumulado[i] = acumulado[i - 1] + (l.pontos[i] - l.pontos[i - 1]).Magnitude
		end
		local trilha: Trilha = {
			pontos = l.pontos,
			acumulado = acumulado,
			total = acumulado[#acumulado],
			duracao = math.clamp(5 * (#l.pontos - 1), 7, 30), -- segundos de uma ponta à outra
		}
		local visiveis = math.min(l.n, MAX_TRENS_VISIVEIS)
		for k = 1, visiveis do
			local frame = novo("Frame", {
				Name = `trem_{l.id}_{k}`,
				AnchorPoint = Vector2.new(0.5, 0.5),
				-- trem lotado fica vermelho; trem rodando vazio fica apagado
				BackgroundColor3 = if l.situacao == "lotado" then cores.negative else cores.panel,
				BackgroundTransparency = if l.situacao == "vazio" then 0.55 else 0,
				BorderSizePixel = 0,
				Visible = self.mostrarTrens,
				ZIndex = Z.trem,
			}, self.conteudo) :: Frame
			novo("UICorner", { CornerRadius = UDim.new(0, 2) }, frame)
			novo("UIStroke", { Color = cores.ink, Thickness = 1.5 }, frame)
			table.insert(self.trens, { frame = frame, trilha = trilha, fase = (k - 1) / visiveis * 2 })
		end
	end
	self:_tamanhoTrens()
	self:_moverTrens()
end

-- Chamado a cada quadro: cada trem vai e volta pela trilha da linha, mais devagar perto das pontas.
function MapaView._moverTrens(self: MapaView)
	if not self.mostrarTrens or #self.trens == 0 then
		return
	end
	local z = self.zoom
	local agora = os.clock()
	for _, t in self.trens do
		local tr = t.trilha
		local u = (agora / tr.duracao + t.fase) % 2
		local voltando = u > 1
		if voltando then
			u = 2 - u
		end
		u = u * u * (3 - 2 * u)
		local d = u * tr.total
		local i = 1
		while i < #tr.pontos - 1 and tr.acumulado[i + 1] < d do
			i += 1
		end
		local a, b = tr.pontos[i], tr.pontos[i + 1]
		local comprimento = tr.acumulado[i + 1] - tr.acumulado[i]
		local p = a:Lerp(b, if comprimento > 0 then (d - tr.acumulado[i]) / comprimento else 0) * z
		t.frame.Position = UDim2.fromOffset(p.X, p.Y)
		t.frame.Rotation = math.deg(math.atan2(b.Y - a.Y, b.X - a.X))
	end
end

-- Estação mais perto de um ponto do mapa, dentro de um raio em pixels de TELA.
function MapaView.estacaoProxima(self: MapaView, ponto: Vector2, raioTela: number): string?
	local melhor, melhorDist = nil, raioTela / self.zoom
	for _, e in self.estacoes do
		local d = (e.pos - ponto).Magnitude
		if d < melhorDist then
			melhor, melhorDist = e.id, d
		end
	end
	return melhor
end

-- Trecho mais perto de um ponto do mapa, dentro de um raio em pixels de TELA.
function MapaView.trechoProximo(self: MapaView, ponto: Vector2, raioTela: number): string?
	local melhor, melhorDist = nil, raioTela / self.zoom
	for _, s in self.segmentos do
		local ab = s.b - s.a
		local t = math.clamp((ponto - s.a):Dot(ab) / math.max(ab:Dot(ab), 1e-6), 0, 1)
		local d = (s.a + ab * t - ponto).Magnitude
		if d < melhorDist then
			melhor, melhorDist = s.id, d
		end
	end
	return melhor
end

function MapaView.telaParaMapa(self: MapaView, pontoTela: Vector2): Vector2
	return (pontoTela - self.raiz.AbsolutePosition - self.pan) / self.zoom
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
	self:_recortar()
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

-- Blocos de detalhe só existem de verdade quando estão na tela (com uma folga): fora dela,
-- somem e soltam a imagem, para o celular não guardar o Brasil inteiro em alta resolução.
function MapaView._recortar(self: MapaView)
	local z = self.zoom
	local mostrar = z >= ZOOM_DETALHE
	local tela = self.raiz.AbsoluteSize
	local folga = 128 / z
	local x0, y0 = -self.pan.X / z - folga, -self.pan.Y / z - folga
	local x1, y1 = (tela.X - self.pan.X) / z + folga, (tela.Y - self.pan.Y) / z + folga
	for _, t in self.tiles do
		if not t.detalhe then
			continue
		end
		local ver = mostrar and t.x < x1 and t.x + t.w > x0 and t.y < y1 and t.y + t.h > y0
		t.imagem.Visible = ver
		if t.id then
			local img = if ver then t.id else ""
			if t.imagem.Image ~= img then
				t.imagem.Image = img
			end
		end
	end
end

function MapaView._layout(self: MapaView)
	local z = self.zoom
	self.conteudo.Size = UDim2.fromOffset(self.largura * z, self.altura * z)

	local mostrarDetalhe = z >= ZOOM_DETALHE
	for _, t in self.tiles do
		if t.detalhe and not mostrarDetalhe then
			continue -- a visibilidade dos blocos de detalhe fica com _recortar
		end
		-- +1 px evita frestas finas entre os blocos
		t.imagem.Position = UDim2.fromOffset(math.floor(t.x * z), math.floor(t.y * z))
		t.imagem.Size = UDim2.fromOffset(math.ceil(t.w * z) + 1, math.ceil(t.h * z) + 1)
	end

	local espessura = espessuraLinha(z)
	self:_tamanhoTrens()
	for _, s in self.segmentos do
		local a, b = s.a * z, s.b * z
		local d = b - a
		local meio = (a + b) / 2
		local angulo = math.deg(math.atan2(d.Y, d.X))
		local comprimento = d.Magnitude
		s.linha.Position = UDim2.fromOffset(meio.X, meio.Y)
		s.linha.Size = UDim2.fromOffset(comprimento, espessura)
		s.linha.Rotation = angulo
		local extra = if self.selecionado == s.id then 8 else 4
		s.casing.Position = s.linha.Position
		s.casing.Size = UDim2.fromOffset(comprimento + 2, espessura + extra)
		s.casing.Rotation = angulo
		local n = #s.tracos
		if n > 0 and s.estado == "projeto" then
			local tam = comprimento / n
			for k, t in s.tracos do
				local p = a + d * ((k - 0.5) / n)
				t.Position = UDim2.fromOffset(p.X, p.Y)
				t.Size = UDim2.fromOffset(tam * 0.55, math.max(3, espessura * 0.6))
				t.Rotation = angulo
			end
		end
	end

	for _, r in self.rotulosMapa do
		local visivel = self.mostrarRotulos and z >= r.zoomMin and z < r.zoomMax
		r.label.Visible = visivel
		if visivel then
			local p = r.pos * z
			r.label.Position = UDim2.fromOffset(p.X, p.Y)
		end
	end

	for _, e in self.estacoes do
		local p = e.pos * z
		local tam = self:_tamanhoEstacao(e)
		e.ponto.Position = UDim2.fromOffset(p.X, p.Y)
		e.rotulo.Position = UDim2.fromOffset(p.X + tam / 2 + 5, p.Y)
		e.rotulo.Visible = self.mostrarNomes and z >= (ZOOM_ROTULO[e.porte] or 0)
		if e.selo then
			e.selo.Position = UDim2.fromOffset(p.X, p.Y - 8)
			e.selo.Visible = z >= 1.2
		end
	end
end

-- ---------------------------------------------------------------- entrada

function MapaView._conectarEntrada(self: MapaView)
	local arrastando = false
	local ultimo = Vector2.zero
	local inicioClique: Vector2? = nil

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
					inicioClique = pos
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
				local inicio = inicioClique
				inicioClique = nil
				local pos = Vector2.new(input.Position.X, input.Position.Y)
				if inicio and (pos - inicio).Magnitude < 6 then
					self.aoTocar:Fire(self:telaParaMapa(pos))
				end
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

	-- Toque: tocar seleciona, arrastar com um dedo, pinça com dois.
	table.insert(
		self.conexoes,
		UserInputService.TouchTap:Connect(function(toques: { Vector2 }, processado: boolean)
			if not processado and toques[1] and dentro(toques[1]) then
				self.aoTocar:Fire(self:telaParaMapa(toques[1]))
			end
		end)
	)
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
	self.aoTocar:Destroy()
	self.raiz:Destroy()
end

return MapaView
