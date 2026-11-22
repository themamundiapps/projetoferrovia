--!strict
-- MapaView: desenha um mapa (tiles + trilhos + estações) dentro de um Frame e cuida de
-- arrastar (mouse/toque) e zoom (roda do mouse/pinça).
--
-- Tudo é guardado em coordenadas do mapa completo (pixels do mapa, ex.: 2048x2048).
-- Ao mudar o zoom, reposicionamos os elementos (são poucos); ao arrastar, só movemos o conteúdo.

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Emojis = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Emojis"))
local Assets = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Assets"))
local Idioma = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Idioma"))

-- placa (cartucho) atrás do nome das capitais e metrópoles
local PLACA_ALTURA, PLACA_FOLGA = 26, 15

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
	emenda: boolean, -- pedaço de um trecho com desvio (via): estica um pouco para não abrir fresta na curva
	linhaId: string,
	ordem: number, -- ordem da linha nos dados (define qual faixa cada linha ocupa num corredor)
	-- Corredor compartilhado: linhas que passam pelo mesmo caminho são desenhadas lado a lado.
	-- faixa = deslocamento em "larguras de linha" (0 = no centro); normal = direção do deslocamento.
	faixa: number,
	normal: Vector2, -- sempre à esquerda do sentido de..para (igual em todos os pedaços do trecho)
	-- direção do deslocamento em cada ponta: na emenda entre dois pedaços é a "mitra" (média das
	-- normais), para os pedaços deslocados continuarem se encontrando na curva
	mA: Vector2,
	mB: Vector2,
	junta: { linha: Frame, casing: Frame }?, -- bolinha na dobra para o próximo pedaço (curva redonda)
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
	seloConectado: boolean?, -- a produtora tem caminho até um porto (selo forte)
	seloAte: number?, -- selo escondido até este instante (a carga acabou de embarcar num trem)
	placa: ImageLabel?, -- cartucho atrás do nome (capitais e metrópoles, com o kit da era)
	folgaPlaca: number, -- distância do começo da placa até o nome
	apagada: boolean, -- cidade que só aparece em projetos ainda não estudados
	terminal: boolean, -- ponta de alguma linha: aparece mesmo no zoom mais longe
}

-- Trens animados: cada linha tem uma trilha (os pontos dos trechos construídos) e alguns trens indo e voltando.
-- ids: estação de cada ponto (para saber por onde o trem passou)
export type LinhaTrens = { id: string, pontos: { Vector2 }, ids: { string }?, n: number, situacao: string } -- "normal" | "lotado" | "vazio"
-- antes/depois: índice da estação mais perto antes/depois de cada ponto (os desvios do traçado não são estações)
type Trilha = { pontos: { Vector2 }, ids: { string }, acumulado: { number }, total: number, duracao: number, segs: { [number]: any }, antes: { number }, depois: { number } }
-- Frete para o mapa animar: cada trem, voltando para a cidade onde a linha começa, pega a carga das
-- produtoras por onde passa e entrega lá. coletas: carga de cada produtora e quanto rende num aviso;
-- emojis: emoji de cada carga; formatar: dinheiro no formato do jogo.
export type Frete = {
	emojis: { [string]: string },
	coletas: { [string]: { carga: string, valor: number } },
	formatar: (number) -> string,
}
-- Um trem desenhado (carros: a locomotiva e os vagões, se houver, que seguem a curva da trilha).
-- aresta: trecho (entre estações) em que a locomotiva está, no sentido em que anda; carga: o que o trem leva nele,
-- mostrado como emoji em cima do trem.
type Trem = { carros: { Frame }, emoji: TextLabel, trilha: Trilha, fase: number, aresta: string?, carga: { string }?, valor: number? }

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
		segPorPontos: { [string]: Segmento },
		bloqueado: boolean, -- menu inicial aberto: o mapa ignora mouse e toque
		segsDoTrecho: { [string]: { Segmento } },
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
		frete: Frete,
		pinturas: boolean?, -- passe Pinturas Especiais: locomotivas douradas
		ultimoAviso: { [string]: number },
	},
	MapaView
))

-- Zoom mínimo para mostrar a bolinha da estação, por porte: no Brasil inteiro só as cidades grandes e as
-- pontas de linha aparecem (as outras poluíam o mapa). A linha continua inteira.
local ZOOM_PONTO = { [5] = 0, [4] = 0, [3] = 0.5, [2] = 0.8, [1] = 1.1 }
-- Avisos de frete (porto e produtora): só com o mapa perto o bastante, e no máximo um a cada tantos segundos por cidade.
local ZOOM_AVISO = 0.9
-- Emoji da carga em cima dos trens: só com o mapa perto o bastante (no país inteiro vira poluição).
local ZOOM_EMOJI = 0.7
local INTERVALO_AVISO = 4 -- segundos (o valor do aviso é o frete desse intervalo)
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
-- Vagões atrás de cada locomotiva (0: só a locomotiva; a carga aparece como emoji em cima do trem).
local VAGOES = 0
-- Locomotiva com o passe Pinturas Especiais.
local COR_DOURADA = Color3.fromRGB(214, 168, 52)
-- Por quanto tempo o selo da produtora some quando a carga embarca num trem.
local SELO_SUMIDO = 3

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
		segPorPontos = {},
		bloqueado = false,
		segsDoTrecho = {},
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
		frete = { emojis = {}, coletas = {}, formatar = tostring },
		ultimoAviso = {},
	}, MapaView)

	self:_criarTiles(mapa)
	self:_criarRotulosMapa(dados)
	self:_criarLinhas(dados)
	self:_calcularCorredores()
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
			Text = Idioma.L(r.texto, r.textoEn or r.texto),
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

-- Textura leve da linha, para diferenciar linhas da mesma cor: a primeira linha de cada cor é lisa, as
-- seguintes ganham um desenho ao longo dela (o gradiente só escurece, então é tudo em tons mais escuros).
-- Cada desenho é uma lista de faixas {começo, fim, escurecer} na largura da linha (0 = uma borda, 1 = a outra).
local TEXTURAS_LINHA: { { { number } } } = {
	{}, -- lisa
	{ { 0.38, 0.62, 0.62 } }, -- friso escuro no meio
	{ { 0.18, 0.33, 0.6 }, { 0.67, 0.82, 0.6 } }, -- dois frisos, como trilhos
	{ { 0.5, 1, 0.72 } }, -- duas cores: metade de baixo mais escura
}

local function texturaLinha(frame: GuiObject, padrao: number)
	local faixas = TEXTURAS_LINHA[(padrao - 1) % #TEXTURAS_LINHA + 1]
	if #faixas == 0 then
		return
	end
	local pontos = { ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)) }
	for _, f in faixas do
		local escuro = Color3.new(f[3], f[3], f[3])
		table.insert(pontos, ColorSequenceKeypoint.new(math.max(f[1] - 0.001, 0.001), Color3.new(1, 1, 1)))
		table.insert(pontos, ColorSequenceKeypoint.new(f[1], escuro))
		if f[2] < 1 then
			table.insert(pontos, ColorSequenceKeypoint.new(f[2], escuro))
			table.insert(pontos, ColorSequenceKeypoint.new(f[2] + 0.001, Color3.new(1, 1, 1)))
		end
	end
	local ultima = faixas[#faixas]
	table.insert(pontos, ColorSequenceKeypoint.new(1, if ultima[2] >= 1 then Color3.new(ultima[3], ultima[3], ultima[3]) else Color3.new(1, 1, 1)))
	novo("UIGradient", { Color = ColorSequence.new(pontos), Rotation = 90 }, frame)
end

function MapaView._criarLinhas(self: MapaView, dados: any)
	local cores = self.era.cores
	local usosCor: { [any]: number } = {}
	for _, linha in dados.linhas do
		local cor: Color3 = self.era.linhas[linha.cor] or cores.ink
		usosCor[linha.cor] = (usosCor[linha.cor] or 0) + 1
		local padrao = usosCor[linha.cor]
		for _, trecho in linha.trechos do
			-- o trecho vai de estação a estação passando pelos pontos de "via" (desvios para não cortar o
			-- mar); cada pedaço é um segmento com o mesmo id
			local pontos: { Vector2 } = { dados.estacoes[trecho.de].pos }
			for _, v in trecho.via or {} do
				table.insert(pontos, v)
			end
			table.insert(pontos, dados.estacoes[trecho.para].pos)
			local emenda = #pontos > 2
			for p = 1, #pontos - 1 do
				local a: Vector2 = pontos[p]
				local b: Vector2 = pontos[p + 1]
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
				texturaLinha(frame, padrao)
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
				-- dobra para o próximo pedaço do mesmo trecho: uma bolinha da cor da linha (e do contorno)
				-- arredonda a curva, sem o "dente" que dois retângulos em ângulo deixam
				local junta: { linha: Frame, casing: Frame }? = nil
				if p < #pontos - 1 then
					local jc = novo("Frame", {
						Name = trecho.id .. "_junta_contorno",
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundColor3 = cores.ink,
						BorderSizePixel = 0,
						ZIndex = Z.contorno,
					}, self.conteudo) :: Frame
					novo("UICorner", { CornerRadius = UDim.new(1, 0) }, jc)
					local jl = novo("Frame", {
						Name = trecho.id .. "_junta",
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundColor3 = cor,
						BorderSizePixel = 0,
						ZIndex = Z.linha,
					}, self.conteudo) :: Frame
					novo("UICorner", { CornerRadius = UDim.new(1, 0) }, jl)
					junta = { linha = jl, casing = jc }
				end
				table.insert(self.segmentos, {
					junta = junta,
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
					emenda = emenda,
					linhaId = linha.id,
					ordem = linha.ordem or 0,
					faixa = 0,
					normal = if (b - a).Magnitude > 1e-3 then Vector2.new(-(b - a).Unit.Y, (b - a).Unit.X) else Vector2.zero,
					mA = Vector2.zero,
					mB = Vector2.zero,
				})
				self.segsDoTrecho[trecho.id] = self.segsDoTrecho[trecho.id] or {}
				table.insert(self.segsDoTrecho[trecho.id], self.segmentos[#self.segmentos])
			end
		end
	end
end

-- Corredores: segmentos de linhas diferentes quase paralelos e colados (um passando por cima do
-- outro) formam um grupo; cada linha do grupo ganha uma faixa, e o _layout as desenha lado a lado,
-- como num mapa de metrô. Os trens andam na faixa da sua linha.
local TOLERANCIA_CORREDOR = 2.5 -- px do mapa
local COS_CORREDOR = math.cos(math.rad(15))

local function distanciaAoSegmento(p: Vector2, a: Vector2, b: Vector2): number
	local ab = b - a
	local t = math.clamp((p - a):Dot(ab) / math.max(ab:Dot(ab), 1e-6), 0, 1)
	return (a + ab * t - p).Magnitude
end

local function fracaoColada(x: Segmento, y: Segmento): number
	local perto = 0
	for k = 0, 10 do
		if distanciaAoSegmento(x.a:Lerp(x.b, k / 10), y.a, y.b) < TOLERANCIA_CORREDOR then
			perto += 1
		end
	end
	return perto / 11
end

local function chaveSegmento(linhaId: string, a: Vector2, b: Vector2): string
	return `{linhaId}|{math.round(a.X * 10)},{math.round(a.Y * 10)}|{math.round(b.X * 10)},{math.round(b.Y * 10)}`
end

-- Vetor da emenda entre dois pedaços deslocados: projeção 1 nas duas normais (as bordas se encontram).
local function mitra(n1: Vector2, n2: Vector2): Vector2
	local d = 1 + n1:Dot(n2)
	if d < 0.3 then -- curva muito fechada: a mitra iria longe demais
		return n2
	end
	return (n1 + n2) / d
end

function MapaView._calcularCorredores(self: MapaView)
	local segs = self.segmentos
	local pai: { number } = {}
	for i = 1, #segs do
		pai[i] = i
	end
	local function raiz(i: number): number
		while pai[i] ~= i do
			pai[i] = pai[pai[i]]
			i = pai[i]
		end
		return i
	end
	for i = 1, #segs do
		local s1 = segs[i]
		for j = i + 1, #segs do
			local s2 = segs[j]
			if s1.linhaId ~= s2.linhaId and s1.normal ~= Vector2.zero and s2.normal ~= Vector2.zero
				and math.abs(s1.normal:Dot(s2.normal)) >= COS_CORREDOR
				and math.max(fracaoColada(s1, s2), fracaoColada(s2, s1)) >= 0.3
			then
				pai[raiz(i)] = raiz(j)
			end
		end
	end
	local grupos: { [number]: { Segmento } } = {}
	for i, s in segs do
		local r = raiz(i)
		grupos[r] = grupos[r] or {}
		table.insert(grupos[r], s)
	end
	for _, grupo in grupos do
		local ordemDe: { [string]: number } = {}
		local linhas: { string } = {}
		for _, s in grupo do
			if not ordemDe[s.linhaId] then
				ordemDe[s.linhaId] = s.ordem
				table.insert(linhas, s.linhaId)
			end
		end
		if #linhas < 2 then
			continue
		end
		table.sort(linhas, function(x, y)
			return ordemDe[x] < ordemDe[y]
		end)
		local faixaDe: { [string]: number } = {}
		for k, id in linhas do
			faixaDe[id] = k - (#linhas + 1) / 2
		end
		-- a faixa é medida numa direção comum do grupo; cada segmento a converte para a sua normal
		-- (linhas em sentidos opostos têm a "esquerda" trocada)
		local referencia = grupo[1].normal
		for _, s in grupo do
			s.faixa = faixaDe[s.linhaId] * (if s.normal:Dot(referencia) < 0 then -1 else 1)
		end
	end
	-- um trecho com desvio fica inteiro na mesma faixa (senão dá degrau nas curvas), e as emendas
	-- entre os pedaços usam a mitra das duas normais
	for _, pedacos in self.segsDoTrecho do
		local f = 0
		for _, s in pedacos do
			if s.faixa ~= 0 then
				f = s.faixa
				break
			end
		end
		for k, s in pedacos do
			s.faixa = f
			local antes, depois = pedacos[k - 1], pedacos[k + 1]
			s.mA = if antes then mitra(antes.normal, s.normal) else s.normal
			s.mB = if depois then mitra(s.normal, depois.normal) else s.normal
		end
	end
	-- para os trens acharem o segmento (e a faixa) de cada pedaço da trilha
	self.segPorPontos = {}
	for _, s in segs do
		self.segPorPontos[chaveSegmento(s.linhaId, s.a, s.b)] = s
		self.segPorPontos[chaveSegmento(s.linhaId, s.b, s.a)] = s
	end
end

-- Distância entre as faixas de um corredor, em pixels de tela.
local function larguraFaixa(zoom: number): number
	-- menos que a largura da linha: as cores ficam coladas, uma levemente por cima da outra
	return math.clamp(2 + zoom * 0.9, 3, 10) * 0.6
end

function MapaView._criarEstacoes(self: MapaView, dados: any)
	local cores = self.era.cores
	local fontes = self.era.fontes
	local terminais: { [string]: boolean } = {}
	for _, linha in dados.linhas do
		local n = #linha.trechos
		if n > 0 then
			terminais[linha.trechos[1].de] = true
			terminais[linha.trechos[n].para] = true
		end
	end
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
		local contorno = novo("UIStroke", {
			Color = cores.panel,
			Thickness = 2,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
		}, rotulo) :: UIStroke

		-- capitais e metrópoles: o nome vai numa placa de pergaminho (só com a peça do kit)
		local placa: ImageLabel? = nil
		local folgaPlaca = PLACA_FOLGA
		local kit = (Assets.KitUI :: any)[self.era.kit or ""]
		local pc = kit and kit.placa_cidade
		if e.porte >= 4 and pc and pc.id ~= "rbxassetid://0" then
			placa = novo("ImageLabel", {
				Name = id .. "_placa",
				AnchorPoint = Vector2.new(0, 0.5),
				Size = UDim2.fromOffset(0, PLACA_ALTURA),
				BackgroundTransparency = 1,
				Image = pc.id,
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = pc.slice,
				SliceScale = PLACA_ALTURA / pc.altura,
				ZIndex = Z.rotulo,
			}, self.conteudo) :: ImageLabel
			rotulo.ZIndex = Z.rotulo + 1
			contorno.Enabled = false
			-- placa com faixa decorada à esquerda (a de estação da Era Elétrica): o nome começa depois dela
			folgaPlaca = math.max(PLACA_FOLGA, math.ceil((pc.margem or 0) * PLACA_ALTURA / pc.altura) + 6)
		end

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
			placa = placa,
			folgaPlaca = folgaPlaca,
			apagada = false,
			terminal = terminais[id] == true,
		})
	end
end

-- ---------------------------------------------------------------- trechos

-- Aparência de cada situação: construído (cor cheia), disponível (cor clara, pode comprar), bloqueado (apagado).
function MapaView._estilizar(self: MapaView, s: Segmento)
	local cores = self.era.cores
	local sel = self.selecionado == s.id or (self :: any).linhaDestacada == s.linhaId
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
	local j = s.junta
	if j then
		j.linha.BackgroundColor3 = s.linha.BackgroundColor3
		j.linha.BackgroundTransparency = s.linha.BackgroundTransparency
		j.casing.BackgroundColor3 = s.casing.BackgroundColor3
		j.casing.BackgroundTransparency = s.casing.BackgroundTransparency
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
			if e.placa then
				e.placa.ImageTransparency = if apagada then 0.45 else 0
			end
		end
	end
end

-- Selo de carga: forte quando a produtora tem caminho até um porto, apagado quando não.
function MapaView.definirCargas(self: MapaView, conectadas: { [string]: boolean })
	for _, e in self.estacoes do
		local selo = e.selo
		if selo then
			e.seloConectado = conectadas[e.id] == true
			if not (e.seloAte and os.clock() < e.seloAte) then
				selo.TextTransparency = if e.seloConectado then 0 else 0.65
			end
		end
	end
end

-- Seleciona um trecho; com `linhaId`, contorna também a linha inteira (ao escolher a linha na lista).
function MapaView.selecionar(self: MapaView, trechoId: string?, linhaId: string?)
	self.selecionado = trechoId;
	(self :: any).linhaDestacada = linhaId
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
	local tam = (e.tamanho + e.nivel * 1.2) * escala
	e.ponto.Size = UDim2.fromOffset(tam, tam)
	e.traco.Thickness = math.max(1.2, (2.5 + e.nivel * 0.4) * escala)
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
			for _, c in t.carros do
				c.Visible = valor
			end
			t.emoji.Visible = false -- volta no próximo quadro, se o trem estiver levando carga
		end
	end
	self:_layout()
end

-- ---------------------------------------------------------------- trens

local function espessuraLinha(zoom: number): number
	return math.clamp(2 + zoom * 0.9, 3, 10)
end

-- Tamanho do trem em pixels de tela: a altura acompanha a espessura da linha.
local function medidasTrem(zoom: number): (number, number, number, number)
	local altura = espessuraLinha(zoom) + (if zoom < 1 then 2 else 3)
	return altura, altura * 1.9, altura * 1.45, math.max(1.5, altura * 0.3) -- altura, locomotiva, vagão, folga
end

function MapaView._tamanhoTrens(self: MapaView)
	local altura, loco, vagao = medidasTrem(self.zoom)
	for _, t in self.trens do
		for k, c in t.carros do
			c.Size = UDim2.fromOffset(if k == 1 then loco else vagao, if k == 1 then altura else altura * 0.85)
		end
	end
end

-- Define os trens de cada linha. Só recria os desenhos quando a frota, a trilha ou a lotação mudam.
function MapaView.definirTrens(self: MapaView, lista: { LinhaTrens })
	local partes = {}
	for _, l in lista do
		table.insert(partes, `{l.id}:{#l.pontos}:{l.n}:{l.situacao}`)
	end
	local assinatura = table.concat(partes, "|") .. tostring(self.pinturas)
	if assinatura == self.assinaturaTrens then
		return
	end
	self.assinaturaTrens = assinatura
	for _, t in self.trens do
		for _, c in t.carros do
			c:Destroy()
		end
		t.emoji:Destroy()
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
		-- segmento desenhado de cada pedaço da trilha (para o trem andar na faixa da linha)
		local segsTrilha: { [number]: any } = {}
		for i = 1, #l.pontos - 1 do
			segsTrilha[i] = self.segPorPontos[chaveSegmento(l.id, l.pontos[i], l.pontos[i + 1])]
		end
		local ids = l.ids or {}
		local function ehEstacao(i: number): boolean
			return l.ids == nil or (ids[i] or "") ~= ""
		end
		-- estação mais perto antes e depois de cada ponto
		local antes, depois = {}, {}
		local ultima = 1
		for i = 1, #l.pontos do
			if ehEstacao(i) then
				ultima = i
			end
			antes[i] = ultima
		end
		local proxima = #l.pontos
		for i = #l.pontos, 1, -1 do
			if ehEstacao(i) then
				proxima = i
			end
			depois[i] = proxima
		end
		-- a duração conta só as estações
		local paradas = 0
		for i = 1, #l.pontos do
			if ehEstacao(i) then
				paradas += 1
			end
		end
		local trilha: Trilha = {
			pontos = l.pontos,
			ids = ids,
			acumulado = acumulado,
			total = acumulado[#acumulado],
			segs = segsTrilha,
			antes = antes,
			depois = depois,
			duracao = math.clamp(5 * (paradas - 1), 7, 30), -- segundos de uma ponta à outra
		}
		-- trem lotado: locomotiva vermelha; trem rodando vazio (frota demais): o trem todo apagado
		local transp = if l.situacao == "vazio" then 0.55 else 0
		local visiveis = math.min(l.n, MAX_TRENS_VISIVEIS)
		for k = 1, visiveis do
			local carros: { Frame } = {}
			for c = 1, 1 + VAGOES do
				local carro = novo("Frame", {
					Name = `trem_{l.id}_{k}_{c}`,
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = if c == 1 then (if l.situacao == "lotado" then cores.negative elseif self.pinturas then COR_DOURADA else cores.ink) else cores.panel,
					BackgroundTransparency = transp,
					BorderSizePixel = 0,
					Visible = self.mostrarTrens,
					ZIndex = if c == 1 then Z.trem + 1 else Z.trem,
				}, self.conteudo) :: Frame
				novo("UICorner", { CornerRadius = UDim.new(0, if c == 1 then 3 else 2) }, carro)
				novo("UIStroke", { Color = cores.ink, Thickness = if c == 1 then 1.5 else 1.2, Transparency = transp }, carro)
				table.insert(carros, carro)
			end
			local emoji = novo("TextLabel", {
				Name = `carga_{l.id}_{k}`,
				AnchorPoint = Vector2.new(0.5, 1),
				Size = UDim2.fromOffset(0, 0),
				AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundTransparency = 1,
				Text = "",
				TextSize = 16,
				Visible = false,
				ZIndex = Z.rotulo,
			}, self.conteudo) :: TextLabel
			table.insert(self.trens, { carros = carros, emoji = emoji, trilha = trilha, fase = (k - 1) / visiveis * 2 })
		end
	end
	self:_tamanhoTrens()
	self:_moverTrens()
end

-- Ponto da trilha a uma distância d do começo, em pixels do conteúdo, já na faixa da linha.
-- Devolve também o índice do pedaço e a direção dele (do começo para o fim da trilha).
local function pontoNaTrilha(tr: Trilha, d: number, z: number, faixa: number): (Vector2, number, Vector2)
	d = math.clamp(d, 0, tr.total)
	local i = 1
	while i < #tr.pontos - 1 and tr.acumulado[i + 1] < d do
		i += 1
	end
	local a, b = tr.pontos[i], tr.pontos[i + 1]
	local comprimento = tr.acumulado[i + 1] - tr.acumulado[i]
	local u = if comprimento > 0 then (d - tr.acumulado[i]) / comprimento else 0
	local p = a:Lerp(b, u) * z
	local seg = tr.segs[i]
	if seg and seg.faixa ~= 0 then
		local us = if (seg.a - a).Magnitude > 0.01 then 1 - u else u -- pedaço desenhado no sentido contrário
		p += seg.mA:Lerp(seg.mB, us) * (seg.faixa * faixa)
	end
	local dir = b - a
	return p, i, if dir.Magnitude > 0 then dir.Unit else Vector2.new(1, 0)
end

-- Chamado a cada quadro: cada trem vai e volta pela trilha da linha, mais devagar perto das pontas.
-- Mão dupla: quem vai anda de um lado da linha e quem volta, do outro, para os trens se cruzarem
-- sem um sumir embaixo do outro. Os vagões seguem a locomotiva pela curva.
function MapaView._moverTrens(self: MapaView)
	if not self.mostrarTrens or #self.trens == 0 then
		return
	end
	local z = self.zoom
	local faixa = larguraFaixa(z)
	local altura, loco, vagao, folga = medidasTrem(z)
	local lado = altura * 0.45
	local tamanhoEmoji = math.clamp(altura * 1.7, 10, 17)
	local agora = os.clock()
	for _, t in self.trens do
		local tr = t.trilha
		local u = (agora / tr.duracao + t.fase) % 2
		local voltando = u > 1
		if voltando then
			u = 2 - u
		end
		u = u * u * (3 - 2 * u)
		-- o trem ocupa [inicio, inicio + comprimento] da trilha; a locomotiva vai na ponta da frente
		local comprimento = (loco + VAGOES * (vagao + folga)) / z
		local escala = if comprimento > tr.total * 0.8 then tr.total * 0.8 / comprimento else 1
		comprimento *= escala
		local inicio = u * (tr.total - comprimento)
		local sentido = if voltando then -1 else 1
		local frente = if voltando then inicio else inicio + comprimento
		local d = frente
		local iFrente = 1
		for k, carro in t.carros do
			local tam = (if k == 1 then loco else vagao) / z * escala
			if k > 1 then
				d -= sentido * (folga / z * escala)
			end
			local centro = d - sentido * tam / 2
			local p, i, dir = pontoNaTrilha(tr, centro, z, faixa)
			p += Vector2.new(-dir.Y, dir.X) * (sentido * lado)
			if k == 1 then
				iFrente = i
				-- a carga vai em cima da locomotiva
				local mostrar = t.emoji.Text ~= "" and z >= ZOOM_EMOJI
				t.emoji.Visible = mostrar
				if mostrar then
					t.emoji.Position = UDim2.fromOffset(p.X, p.Y - altura * 0.6 - 1)
					t.emoji.TextSize = tamanhoEmoji
				end
			end
			carro.Position = UDim2.fromOffset(p.X, p.Y)
			carro.Rotation = math.deg(math.atan2(dir.Y, dir.X))
			d -= sentido * tam
		end
		-- trecho (entre estações) em que a locomotiva está, no sentido em que anda
		local de = tr.ids[if voltando then tr.depois[iFrente + 1] else tr.antes[iFrente]] or ""
		local para = tr.ids[if voltando then tr.antes[iFrente] else tr.depois[iFrente + 1]] or ""
		local aresta = `{de}>{para}`
		if aresta ~= t.aresta then
			self:_trocarAresta(t, aresta, de, voltando, agora)
		end
	end
end

-- Mostra a carga do trem como emoji em cima dele (vazio: sem emoji). Cada produtora que já embarcou
-- carga soma um emoji: duas cidades de café = ☕☕; de 4 para cima vira ☕×4.
function MapaView._mostrarCarga(self: MapaView, t: Trem)
	local ordem: { string } = {}
	local quantos: { [string]: number } = {}
	for _, c in t.carga or {} do
		if not quantos[c] then
			table.insert(ordem, c)
		end
		quantos[c] = (quantos[c] or 0) + 1
	end
	local partes = {}
	for _, c in ordem do
		local emoji = (self.frete.emojis :: any)[c] or ""
		local n = quantos[c]
		table.insert(partes, if n <= 3 then string.rep(emoji, n) else `{emoji}×{n}`)
	end
	t.emoji.Text = table.concat(partes, " ")
end

-- A carga embarcou num trem: o selo da produtora some por uns segundos e volta.
function MapaView._esconderSelo(self: MapaView, id: string, agora: number)
	for _, e in self.estacoes do
		if e.id == id and e.selo then
			e.seloAte = agora + SELO_SUMIDO
			e.selo.TextTransparency = 1
			local selo = e.selo
			task.delay(SELO_SUMIDO, function()
				if selo.Parent and e.seloAte and os.clock() >= e.seloAte - 0.05 then
					e.seloAte = nil
					TweenService:Create(selo, TweenInfo.new(0.4), { TextTransparency = if e.seloConectado then 0 else 0.65 }):Play()
				end
			end)
			return
		end
	end
end

-- A locomotiva entrou num trecho novo, saindo da estação "de". Voltando para o começo da linha, o trem
-- pega a carga de cada produtora por onde passa (o selo dela some e o emoji vai para cima do trem, somando
-- com o que já leva); ao dar meia-volta na cidade onde a linha começa, entrega tudo e sobe o frete.
function MapaView._trocarAresta(self: MapaView, t: Trem, aresta: string, de: string, voltando: boolean, agora: number)
	local anterior = t.aresta
	t.aresta = aresta
	if not anterior then
		return -- primeiro quadro do trem: começa vazio
	end
	if voltando then
		local coleta = self.frete.coletas[de]
		if coleta then
			t.carga = t.carga or {}
			table.insert(t.carga :: { string }, coleta.carga)
			t.valor = (t.valor or 0) + coleta.valor
			self:_esconderSelo(de, agora)
			self:_mostrarCarga(t)
			if t.emoji.Visible then
				-- o emoji "pula" para cima do trem
				t.emoji.TextTransparency = 1
				TweenService:Create(t.emoji, TweenInfo.new(0.35), { TextTransparency = 0 }):Play()
			end
		end
	elseif t.carga and #t.carga > 0 then
		if de == t.trilha.ids[1] then
			self:_avisoMapa(de, `{t.emoji.Text} +{self.frete.formatar(t.valor or 0)}`, self.era.cores.positive, 19, agora)
		end
		t.carga, t.valor = nil, nil
		self:_mostrarCarga(t)
	end
end

-- Frete atual (ver o tipo Frete). A carga que já está nos trens segue até o destino.
function MapaView.definirFrete(self: MapaView, frete: Frete)
	self.frete = frete
end

-- Aviso que sobe de uma estação e some (frete pago no porto, carga embarcada na produtora).
-- Só com o mapa perto o bastante, com a estação na tela, e no máximo um a cada tantos segundos por estação.
function MapaView._avisoMapa(self: MapaView, id: string, texto: string, cor: Color3, tamanho: number, agora: number)
	if not self.mostrarTrens or self.zoom < ZOOM_AVISO then
		return
	end
	if agora - (self.ultimoAviso[id] or -math.huge) < INTERVALO_AVISO then
		return
	end
	local pos: Vector2? = nil
	for _, e in self.estacoes do
		if e.id == id then
			pos = e.pos
			break
		end
	end
	if not pos then
		return
	end
	local p = pos * self.zoom
	local naTela = p + self.pan
	local tela = self.raiz.AbsoluteSize
	if naTela.X < -40 or naTela.Y < -40 or naTela.X > tela.X + 40 or naTela.Y > tela.Y + 40 then
		return
	end
	self.ultimoAviso[id] = agora
	local cores = self.era.cores
	local lbl = novo("TextLabel", {
		Name = "aviso_" .. id,
		AnchorPoint = Vector2.new(0.5, 1),
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.fromOffset(0, 0),
		Position = UDim2.fromOffset(p.X, p.Y - 14),
		BackgroundTransparency = 1,
		Text = texto,
		FontFace = self.era.fontes.display,
		TextSize = tamanho,
		TextColor3 = cor,
		ZIndex = Z.rotulo + 1,
	}, self.conteudo) :: TextLabel
	local contorno = novo("UIStroke", { Color = cores.panel, Thickness = 2.5 }, lbl) :: UIStroke
	-- sobe o tempo todo; fica nítido na primeira metade e some na segunda
	TweenService:Create(lbl, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.fromOffset(p.X, p.Y - 56) }):Play()
	local sumir = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 1)
	TweenService:Create(lbl, sumir, { TextTransparency = 1 }):Play()
	TweenService:Create(contorno, sumir, { Transparency = 1 }):Play()
	task.delay(2.1, function()
		lbl:Destroy()
	end)
end

-- Estação mais perto de um ponto do mapa, dentro de um raio em pixels de TELA.
function MapaView.estacaoProxima(self: MapaView, ponto: Vector2, raioTela: number): string?
	local melhor, melhorDist = nil, raioTela / self.zoom
	for _, e in self.estacoes do
		if not e.ponto.Visible then
			continue -- escondida no zoom longe
		end
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
		-- os trens se reposicionam junto com as linhas; esperar o próximo quadro deixava os trens
		-- um quadro na escala antiga, fora dos trilhos, a cada passo de zoom
		self:_moverTrens()
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
	local faixa = larguraFaixa(z)
	for _, s in self.segmentos do
		local a = s.a * z + s.mA * (s.faixa * faixa)
		local b = s.b * z + s.mB * (s.faixa * faixa)
		local d = b - a
		local meio = (a + b) / 2
		local angulo = math.deg(math.atan2(d.Y, d.X))
		local comprimento = d.Magnitude
		s.linha.Position = UDim2.fromOffset(meio.X, meio.Y)
		s.linha.Size = UDim2.fromOffset(comprimento, espessura)
		s.linha.Rotation = angulo
		local extra = if self.selecionado == s.id or (self :: any).linhaDestacada == s.linhaId then 8 else 4
		s.casing.Position = s.linha.Position
		s.casing.Size = UDim2.fromOffset(comprimento + 2, espessura + extra)
		s.casing.Rotation = angulo
		local j = s.junta
		if j then
			j.linha.Position = UDim2.fromOffset(b.X, b.Y)
			j.linha.Size = UDim2.fromOffset(espessura, espessura)
			j.casing.Position = j.linha.Position
			j.casing.Size = UDim2.fromOffset(espessura + extra, espessura + extra)
		end
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
		local mostrarPonto = e.terminal or z >= (ZOOM_PONTO[e.porte] or 0)
		e.ponto.Visible = mostrarPonto
		e.ponto.Position = UDim2.fromOffset(p.X, p.Y)
		e.rotulo.Visible = mostrarPonto and self.mostrarNomes and z >= (ZOOM_ROTULO[e.porte] or 0)
		local placa = e.placa
		if placa then
			-- a placa começa logo depois da bolinha e o nome vai por dentro dela
			placa.Visible = e.rotulo.Visible
			placa.Position = UDim2.fromOffset(p.X + tam / 2 + 3, p.Y)
			placa.Size = UDim2.fromOffset(e.rotulo.TextBounds.X + e.folgaPlaca + PLACA_FOLGA, PLACA_ALTURA)
			e.rotulo.Position = UDim2.fromOffset(p.X + tam / 2 + 3 + e.folgaPlaca, p.Y)
		else
			e.rotulo.Position = UDim2.fromOffset(p.X + tam / 2 + 5, p.Y)
		end
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
			if processado or self.bloqueado then
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
			elseif input.UserInputType == Enum.UserInputType.MouseWheel and not processado and not self.bloqueado then
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
			if not processado and not self.bloqueado and toques[1] and dentro(toques[1]) then
				self.aoTocar:Fire(self:telaParaMapa(toques[1]))
			end
		end)
	)
	local panInicial = Vector2.zero
	table.insert(
		self.conexoes,
		UserInputService.TouchPan:Connect(function(_toques, translacao: Vector2, _vel, estado: Enum.UserInputState, processado: boolean)
			if processado or self.bloqueado then
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
			if processado or self.bloqueado then
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
