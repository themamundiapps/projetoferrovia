--!strict
-- Menu inicial: boas-vindas, escolha do mapa (Brasil e EUA; Europa em breve), novidades e ranking global.
-- Fica por cima de tudo; o mapa da companhia passa devagar no fundo (o init.client cuida do passeio).
-- Uso: Inicio.new(playerGui) mostra "Carregando…"; :montar(estado, era, dados) monta o menu;
-- aoJogar dispara com o id do mapa escolhido; :fechar() some com fade; :destruir().

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Economia = require(Shared:WaitForChild("Economia"))
local Idioma = require(Shared:WaitForChild("Idioma"))
local Novidades = require(Shared:WaitForChild("Novidades"))
local DadosBrasil = require(Shared:WaitForChild("Dados"):WaitForChild("Brasil"))
local DadosEUA = require(Shared:WaitForChild("Dados"):WaitForChild("EUA"))
local Emojis = require(Shared:WaitForChild("Emojis"))
local Estilo = require(script.Parent:WaitForChild("Estilo"))

local novo = Estilo.novo
local LARGURA_COLUNA = 470

local Inicio = {}
Inicio.__index = Inicio

export type Inicio = typeof(setmetatable(
	{} :: {
		gui: ScreenGui,
		raiz: Frame,
		escalado: Frame,
		escala: UIScale,
		conteudo: Frame,
		aoJogar: BindableEvent,
		aberto: boolean,
		conexoes: { RBXScriptConnection },
		_medir: () -> (),
	},
	Inicio
))

local function L(pt: string, en: string): string
	return Idioma.t({ pt = pt, en = en })
end

function Inicio.new(playerGui: Instance): Inicio
	local gui = novo("ScreenGui", {
		Name = "Inicio",
		DisplayOrder = 20,
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ScreenInsets = Enum.ScreenInsets.None,
	}, playerGui) :: ScreenGui
	local raiz = novo("Frame", {
		Name = "Raiz",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0, -- tela preta até o estado chegar
		Active = true, -- segura cliques e roda do mouse: o mapa de fundo não mexe
	}, gui) :: Frame
	local carregando = novo("TextLabel", {
		Name = "Carregando",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(400, 40),
		BackgroundTransparency = 1,
		Text = L("Carregando a companhia…", "Loading your company…"),
		TextColor3 = Color3.fromRGB(230, 225, 210),
		FontFace = Font.fromEnum(Enum.Font.GothamMedium),
		TextSize = 20,
	}, raiz)
	carregando.Name = "Carregando"
	-- O conteúdo do menu fica num quadro "Escalado" com UIScale (a raiz cobre a tela, sem escala).
	-- A raiz é um Frame comum: com CanvasGroup (que dava o fade) o menu saía pixelizado, porque ele
	-- desenha tudo numa textura de resolução limitada. A saída agora é deslizando para a esquerda.
	local escalado = novo("Frame", {
		Name = "Escalado",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, raiz) :: Frame
	local escala = novo("UIScale", { Name = "Escala" }, escalado) :: UIScale
	local self = setmetatable({
		gui = gui,
		raiz = raiz,
		escalado = escalado,
		escala = escala,
		conteudo = nil :: any,
		aoJogar = Instance.new("BindableEvent"),
		aberto = true,
		conexoes = {},
		_medir = function() end,
	}, Inicio)
	-- O quadro escalado encolhe/estica a partir do canto de cima à esquerda; por isso ele tem tamanho
	-- 1/escala: depois de escalado, cobre a tela exata e o centro fica no centro.
	local function medir()
		local t = gui.AbsoluteSize
		if t.X > 0 and t.Y > 0 then
			-- cabe na tela: pela largura e pela altura da coluna (em pontos virtuais)
			local coluna = self.conteudo and self.conteudo:FindFirstChild("Coluna") :: Frame?
			local alturaColuna = if coluna then coluna.AbsoluteSize.Y / math.max(escala.Scale, 0.01) else 560
			escala.Scale = math.clamp(math.min(t.X / 1000, t.Y * 0.92 / math.max(alturaColuna, 400)), 0.55, 1.1)
			local k = 1 / math.max(escala.Scale, 0.01)
			escalado.Size = UDim2.fromScale(k, k)
		end
	end
	self._medir = medir
	table.insert(self.conexoes, gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(medir))
	medir()
	return self
end

-- Monta o menu com o visual da era do save. `estado` pode ser de um jogador novo (sem trechos).
function Inicio.montar(self: Inicio, estado: any, era: any, dados: any)
	if self.conteudo then
		self.conteudo:Destroy()
	end
	local carregando = self.raiz:FindFirstChild("Carregando")
	if carregando then
		carregando:Destroy()
	end
	self.raiz.BackgroundTransparency = 1
	local est = Estilo.new(era)
	local c = est.c
	-- tudo dentro de um quadro em "pontos virtuais" (a raiz já compensa a escala: o quadro ocupa a raiz toda)
	local conteudo = novo("Frame", {
		Name = "Conteudo",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, (self :: any).escalado) :: Frame
	self.conteudo = conteudo

	-- faixa à esquerda na cor do painel da era, sumindo para a direita: o mapa aparece à direita
	local faixa = novo("Frame", {
		Name = "Faixa",
		Size = UDim2.new(0, LARGURA_COLUNA + 260, 1, 0),
		BackgroundColor3 = c.panel,
		BorderSizePixel = 0,
	}, conteudo)
	novo("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.02),
			NumberSequenceKeypoint.new(0.62, 0.08),
			NumberSequenceKeypoint.new(1, 1),
		}),
	}, faixa)

	local coluna = novo("Frame", {
		Name = "Coluna",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 56 + Estilo.INSET_ESQ, 0.5, 0),
		Size = UDim2.fromOffset(LARGURA_COLUNA, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, conteudo) :: Frame
	est:lista(coluna, 12)

	-- título
	local titulo = est:texto("titulo", "Ferrovia Tycoon", coluna, 1)
	titulo.TextSize = 40
	titulo.TextColor3 = c.ink
	local sub = est:texto("corpo", L(
		"Construa as ferrovias de um país inteiro, do trem a vapor ao trem-bala.",
		"Build a whole country's railways, from steam engines to bullet trains."
	), coluna, 2)
	sub.TextSize = 17

	-- boas-vindas
	local jogador = Players.LocalPlayer
	local nome = jogador and jogador.DisplayName or ""
	local temCompanhia = estado and estado.trechos and next(estado.trechos) ~= nil
	local nivel = if estado then (Economia.nivel(estado)) else 1
	local ola = if temCompanhia
		then L(`Que bom te ver de novo, {nome}!`, `Good to see you again, {nome}!`)
		else L(`Bem-vindo, {nome}!`, `Welcome, {nome}!`)
	local linhaOla = est:texto("subtitulo", ola, coluna, 3)
	linhaOla.TextSize = 22
	local situacao = if temCompanhia
		then L(
			`{estado.nomeCompanhia or "Sua companhia"} está na {era.nome}, nível {nivel}.`,
			`{estado.nomeCompanhia or "Your company"} is in the {Idioma.t(era.nomeEn or era.nome)}, level {nivel}.`
		)
		else L(
			"Escolha um mapa e construa o primeiro trecho de ferrovia do país.",
			"Pick a map and build the country's first stretch of railway."
		)
	est:texto("fraco", situacao, coluna, 4)

	-- escolha do mapa
	local rotuloMapa = est:texto("rotulo", Idioma.maiusculas(L("Escolha o mapa", "Choose a map")), coluna, 5)
	rotuloMapa.TextSize = 14
	local fileira = novo("Frame", {
		Name = "Mapas",
		LayoutOrder = 6,
		Size = UDim2.new(1, 0, 0, 146),
		BackgroundTransparency = 1,
	}, coluna)
	est:lista(fileira, 10, true)
	local nLinhasBrasil, nLinhasEUA = #DadosBrasil.linhas, #DadosEUA.linhas
	local mapas = {
		{
			id = "brasil",
			nome = L("Brasil", "Brazil"),
			info = L(`{nLinhasBrasil} linhas · 1854 até hoje`, `{nLinhasBrasil} lines · 1854 to today`),
			pronto = true,
		},
		{
			id = "eua",
			nome = L("Estados Unidos", "United States"),
			info = L(`{nLinhasEUA} linhas · 1830 até hoje`, `{nLinhasEUA} lines · 1830 to today`),
			pronto = true,
		},
		{ id = "europa", nome = L("Europa", "Europe"), info = L("Em breve", "Coming soon"), pronto = false },
	}
	for i, m in mapas do
		local cartao = est:cartao({
			Name = "Mapa_" .. m.id,
			LayoutOrder = i,
			Size = UDim2.new(1 / 3, -7, 1, 0),
		}, fileira, m.pronto)
		est:lista(cartao, 6)
		local n = est:texto("subtitulo", m.nome, cartao, 1)
		n.TextSize = 19
		local inf = est:texto("fraco", m.info, cartao, 2)
		inf.TextSize = 13
		local prog = ((estado or {}).progressoMapas or {})[m.id]
		if m.pronto and prog and prog.linhas > 0 then
			local completo = prog.linhas >= prog.total
			local lProg = est:texto("rotulo", if completo then L(`{Emojis.medalha} Mapa completo`, `{Emojis.medalha} Map complete`)
				else L(`{prog.linhas} de {prog.total} linhas completas`, `{prog.linhas} of {prog.total} lines complete`), cartao, 3)
			lProg.TextSize = 12
			if completo then
				lProg.TextColor3 = est:paleta(cartao).positive
			end
		end
		if m.pronto then
			-- cada mapa é uma companhia separada: "Continuar" só no mapa aberto agora
			local continuar = temCompanhia and m.id == (dados.id or "brasil")
			local b = est:botao(if continuar or m.id == (dados.id or "brasil") then "principal" else "discreto", if continuar then L("Continuar", "Continue") else L("Jogar", "Play"), cartao, 4)
			b.Size = UDim2.new(1, 0, 0, 40)
			b.Name = "Jogar"
			b.Activated:Connect(function()
				if self.aberto then
					self.aoJogar:Fire(m.id)
				end
			end)
		else
			if cartao:IsA("ImageLabel") then
				(cartao :: ImageLabel).ImageTransparency = 0.45
			end
			n.TextTransparency = 0.4
			inf.TextTransparency = 0.3
			local cadeado = est:texto("fraco", `{Emojis.cadeado} {L("Em construção", "Under construction")}`, cartao, 4)
			cadeado.TextSize = 13
			cadeado.TextTransparency = 0.3
		end
	end

	-- novidades
	local rotuloNov = est:texto("rotulo", Idioma.maiusculas(L("Novidades", "What's new")), coluna, 7)
	rotuloNov.TextSize = 14
	local caixa = est:cartao({
		Name = "Novidades",
		LayoutOrder = 8,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	}, coluna)
	est:lista(caixa, 8)
	for i = 1, math.min(3, #Novidades) do
		local nov = Novidades[i]
		local ano, mes, dia = string.match(nov.data, "(%d+)-(%d+)-(%d+)")
		local data = if ano then `{dia}/{mes}` else nov.data
		local l = est:texto("corpo", `<b>{data} · {Idioma.t(nov.titulo)}</b>  {Idioma.t(nov.texto)}`, caixa, i)
		l.TextSize = 14
	end
	-- ranking global (todos os servidores): nível e linhas completas, com a foto de cada jogador.
	-- O servidor guarda o top 10 num OrderedDataStore e manda pelo Remotes.Ranking.
	local CORES_PODIO = { Color3.fromRGB(222, 178, 58), Color3.fromRGB(178, 184, 192), Color3.fromRGB(186, 122, 72) }
	local ranking = est:cartao({
		Name = "Ranking",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -24 - Estilo.INSET_DIR, 0, 24),
		Size = UDim2.fromOffset(290, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	}, conteudo)
	est:lista(ranking, 4)
	local tituloRanking = est:texto("rotulo", `{Emojis.nivel} {Idioma.maiusculas(L("Ranking global", "Global leaderboard"))}`, ranking, 0)
	tituloRanking.TextSize = 14
	local avisoRanking = est:texto("fraco", L("Carregando…", "Loading…"), ranking, 1)
	avisoRanking.TextSize = 13
	local linhasRanking: { any } = {}
	local fotos: { [number]: string } = {}
	for i = 1, 10 do
		local linha = novo("Frame", {
			Name = "Linha" .. i,
			LayoutOrder = 10 + i,
			Size = UDim2.new(1, 0, 0, 36),
			BackgroundColor3 = c.accent,
			BackgroundTransparency = 1,
			Visible = false,
		}, ranking)
		novo("UICorner", { CornerRadius = UDim.new(0, 6) }, linha)
		local pos = novo("TextLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 2, 0.5, 0),
			Size = UDim2.fromOffset(20, 20),
			BackgroundColor3 = CORES_PODIO[i] or c.panel,
			BackgroundTransparency = if CORES_PODIO[i] then 0 else 1,
			Text = tostring(i),
			FontFace = era.fontes.display,
			TextSize = 13,
			TextColor3 = if CORES_PODIO[i] then Color3.fromRGB(40, 28, 18) else c.inkMuted,
		}, linha)
		novo("UICorner", { CornerRadius = UDim.new(1, 0) }, pos)
		local foto = novo("ImageLabel", {
			Name = "Foto",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 28, 0.5, 0),
			Size = UDim2.fromOffset(30, 30),
			BackgroundColor3 = c.rule,
			Image = "",
		}, linha)
		novo("UICorner", { CornerRadius = UDim.new(1, 0) }, foto)
		novo("UIStroke", { Color = c.ink, Thickness = 1.5, Transparency = 0.3 }, foto)
		local nomeL = novo("TextLabel", {
			Position = UDim2.fromOffset(66, 0),
			Size = UDim2.new(1, -66 - 70, 1, 0),
			BackgroundTransparency = 1,
			Text = "",
			FontFace = Font.new(era.fontes.body.Family, Enum.FontWeight.Bold),
			TextSize = 14,
			TextColor3 = c.ink,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}, linha)
		local nivelL = novo("TextLabel", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -4, 0, 2),
			Size = UDim2.fromOffset(68, 17),
			BackgroundTransparency = 1,
			Text = "",
			FontFace = Font.new(era.fontes.body.Family, Enum.FontWeight.Bold),
			TextSize = 14,
			TextColor3 = c.accent,
			TextXAlignment = Enum.TextXAlignment.Right,
		}, linha)
		local linhasL = novo("TextLabel", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -4, 0, 19),
			Size = UDim2.fromOffset(68, 14),
			BackgroundTransparency = 1,
			Text = "",
			FontFace = era.fontes.body,
			TextSize = 12,
			TextColor3 = c.inkMuted,
			TextXAlignment = Enum.TextXAlignment.Right,
		}, linha)
		linhasRanking[i] = { frame = linha, foto = foto, nome = nomeL, nivel = nivelL, linhas = linhasL }
	end
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local function atualizarRanking()
		local remote = remotes:FindFirstChild("Ranking") :: RemoteFunction?
		if not remote then
			return
		end
		local ok, r = pcall(function()
			return remote:InvokeServer()
		end)
		if not ok or type(r) ~= "table" or not conteudo.Parent then
			return
		end
		local lista = r.lista or {}
		avisoRanking.Visible = #lista == 0
		avisoRanking.Text = if r.disponivel == false
			then L("O ranking global aparece no jogo publicado.", "The global leaderboard shows up in the published game.")
			else L("Ainda ninguém no ranking. Ele atualiza a cada poucos minutos.", "No one on the leaderboard yet. It updates every few minutes.")
		for i, l in linhasRanking do
			local item = lista[i]
			l.frame.Visible = item ~= nil
			if item then
				local eu = item.userId == (jogador and jogador.UserId)
				l.frame.BackgroundTransparency = if eu then 0.8 else 1
				l.nome.Text = tostring(item.nome)
				l.nivel.Text = `{L("Nível", "Level")} {item.nivel}`
				l.linhas.Text = L(`{item.linhas} linha{if item.linhas == 1 then "" else "s"}`, `{item.linhas} line{if item.linhas == 1 then "" else "s"}`)
				local id = item.userId
				if fotos[id] then
					l.foto.Image = fotos[id]
				else
					l.foto.Image = ""
					task.spawn(function()
						local okFoto, img = pcall(function()
							return Players:GetUserThumbnailAsync(id, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
						end)
						if okFoto and img then
							fotos[id] = img
							if l.frame.Parent and lista[i] == item then
								l.foto.Image = img
							end
						end
					end)
				end
			end
		end
	end
	task.spawn(function()
		while conteudo.Parent do
			if self.aberto then
				atualizarRanking()
			end
			task.wait(30)
		end
	end)

	-- ajusta a escala para a coluna inteira caber na altura da tela
	task.defer(self._medir)
	coluna:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		self._medir()
	end)
end

-- Desliza para a esquerda (o mapa continua embaixo) e para de segurar os cliques.
function Inicio.fechar(self: Inicio, duracao: number?)
	if not self.aberto then
		return
	end
	self.aberto = false
	local d = duracao or 0.45
	local tw = TweenService:Create(self.raiz, TweenInfo.new(d, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.fromScale(-1, 0) })
	tw.Completed:Once(function()
		if not self.aberto then
			self.gui.Enabled = false
		end
	end)
	tw:Play()
end

-- Volta a mostrar (botão "Menu inicial" em Ajustes).
function Inicio.abrir(self: Inicio)
	self.aberto = true
	self.gui.Enabled = true
	self.raiz.Position = UDim2.fromScale(-1, 0)
	TweenService:Create(self.raiz, TweenInfo.new(0.4, Enum.EasingStyle.Quad), { Position = UDim2.fromScale(0, 0) }):Play()
end

function Inicio.destruir(self: Inicio)
	for _, c in self.conexoes do
		c:Disconnect()
	end
	self.gui:Destroy()
	self.aoJogar:Destroy()
end

return Inicio
