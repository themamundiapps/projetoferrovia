--!strict
-- Menu inicial: boas-vindas, escolha do mapa (Brasil, EUA e Europa), novidades e ranking global.
-- Fica por cima de tudo; o mapa da companhia passa devagar no fundo (o init.client cuida do passeio).
-- Uso: Inicio.new(playerGui) mostra "Carregando…"; :montar(estado, era, dados) monta o menu;
-- aoJogar dispara com o id do mapa escolhido; :fechar() some com fade; :destruir().

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Economia = require(Shared:WaitForChild("Economia"))
local Equipe = require(Shared:WaitForChild("Equipe"))
local Idioma = require(Shared:WaitForChild("Idioma"))
local Novidades = require(Shared:WaitForChild("Novidades"))
local DadosBrasil = require(Shared:WaitForChild("Dados"):WaitForChild("Brasil"))
local DadosEUA = require(Shared:WaitForChild("Dados"):WaitForChild("EUA"))
local DadosEuropa = require(Shared:WaitForChild("Dados"):WaitForChild("Europa"))
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
		_medir: (boolean?) -> (),
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
	-- `soEncolher` vale para mudanças no conteúdo: mudar a escala faz o texto quebrar de outro jeito,
	-- o que muda a altura da coluna e dispara outra medição. Só encolher quebra esse laço (flicker).
	local function medir(soEncolher: boolean?)
		local t = gui.AbsoluteSize
		if t.X > 0 and t.Y > 0 then
			-- cabe na tela: pela largura e pela altura da coluna (em pontos virtuais)
			local coluna = self.conteudo and self.conteudo:FindFirstChild("Coluna") :: Frame?
			local alturaColuna = if coluna then coluna.AbsoluteSize.Y / math.max(escala.Scale, 0.01) else 560
			local novoEsc = math.clamp(math.min(t.X / 1000, t.Y * 0.92 / math.max(alturaColuna, 400)), 0.55, 1.1)
			if soEncolher then
				novoEsc = math.min(novoEsc, escala.Scale)
			end
			if math.abs(novoEsc - escala.Scale) > 0.005 then
				escala.Scale = novoEsc
				escalado.Size = UDim2.fromScale(1 / math.max(novoEsc, 0.01), 1 / math.max(novoEsc, 0.01))
			end
		end
	end
	self._medir = medir
	table.insert(self.conexoes, gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		medir()
	end))
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
	local titulo = est:texto("titulo", L("Ferrovia Tycoon", "Railway Tycoon"), coluna, 1)
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
			"Escolha um mapa e construa o primeiro trecho de ferrovia.",
			"Pick a map and build the first stretch of railway."
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
	local nLinhasBrasil, nLinhasEUA, nLinhasEuropa = #DadosBrasil.linhas, #DadosEUA.linhas, #DadosEuropa.linhas
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
		{
			id = "europa",
			nome = L("Europa", "Europe"),
			info = L(`{nLinhasEuropa} linhas · 1825 até hoje`, `{nLinhasEuropa} lines · 1825 to today`),
			pronto = true,
		},
	}
	local nomePorId = {}
	for _, m in mapas do
		nomePorId[m.id] = m.nome
	end
	for i, m in mapas do
		local prog = ((estado or {}).progressoMapas or {})[m.id]
		-- trancado até completar o primeiro mapa (o servidor decide; aqui só mostra)
		local trancado = m.pronto and prog ~= nil and prog.liberado == false
		local cartao = est:cartao({
			Name = "Mapa_" .. m.id,
			LayoutOrder = i,
			Size = UDim2.new(1 / 3, -7, 1, 0),
		}, fileira, m.pronto and not trancado)
		est:lista(cartao, 6)
		local n = est:texto("subtitulo", m.nome, cartao, 1)
		n.TextSize = 19
		local inf = est:texto("fraco", m.info, cartao, 2)
		inf.TextSize = 13
		if m.pronto and prog and prog.linhas > 0 then
			local completo = prog.linhas >= prog.total
			local lProg = est:texto("rotulo", if completo then L(`{Emojis.medalha} Mapa completo`, `{Emojis.medalha} Map complete`)
				else L(`{prog.linhas} de {prog.total} linhas completas`, `{prog.linhas} of {prog.total} lines complete`), cartao, 3)
			lProg.TextSize = 12
			if completo then
				lProg.TextColor3 = est:paleta(cartao).positive
			end
		end
		if trancado then
			if cartao:IsA("ImageLabel") then
				(cartao :: ImageLabel).ImageTransparency = 0.45
			end
			n.TextTransparency = 0.4
			inf.TextTransparency = 0.3
			local falta = nomePorId[prog.falta] or ""
			local aviso = L(`Complete {falta} para liberar`, `Complete {falta} to unlock`)
			local cadeado = est:texto("fraco", `{Emojis.cadeado} {aviso}`, cartao, 4)
			cadeado.TextSize = 13
			cadeado.TextTransparency = 0.2
		elseif m.pronto then
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
	-- versão do jogo: canto inferior direito do menu, sobre o mapa de fundo
	local versao = novo("TextLabel", {
		Name = "Versao",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -18 - Estilo.INSET_DIR, 1, -14),
		Size = UDim2.fromOffset(90, 20),
		BackgroundTransparency = 1,
		Text = "v0.1.1",
		FontFace = era.fontes.label,
		TextSize = 12,
		TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextYAlignment = Enum.TextYAlignment.Bottom,
		ZIndex = 31,
	}, conteudo) :: TextLabel

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
	-- cores do cartão (papel claro em qualquer era): na Alta, est.c tem tinta clara e o nome sumia
	local cr = est:paleta(ranking)
	local fotos: { [number]: string } = {}
	for i = 1, 10 do
		local linha = novo("Frame", {
			Name = "Linha" .. i,
			LayoutOrder = 10 + i,
			Size = UDim2.new(1, 0, 0, 36),
			BackgroundColor3 = cr.accent,
			BackgroundTransparency = 1,
			Visible = false,
		}, ranking)
		novo("UICorner", { CornerRadius = UDim.new(0, 6) }, linha)
		local pos = novo("TextLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 2, 0.5, 0),
			Size = UDim2.fromOffset(20, 20),
			BackgroundColor3 = CORES_PODIO[i] or cr.panel,
			BackgroundTransparency = if CORES_PODIO[i] then 0 else 1,
			Text = tostring(i),
			FontFace = era.fontes.display,
			TextSize = 13,
			TextColor3 = if CORES_PODIO[i] then Color3.fromRGB(40, 28, 18) else cr.inkMuted,
		}, linha)
		novo("UICorner", { CornerRadius = UDim.new(1, 0) }, pos)
		local foto = novo("ImageLabel", {
			Name = "Foto",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 28, 0.5, 0),
			Size = UDim2.fromOffset(30, 30),
			BackgroundColor3 = cr.rule,
			Image = "",
		}, linha)
		novo("UICorner", { CornerRadius = UDim.new(1, 0) }, foto)
		novo("UIStroke", { Color = cr.ink, Thickness = 1.5, Transparency = 0.3 }, foto)
		local nomeL = novo("TextLabel", {
			Position = UDim2.fromOffset(66, 2),
			Size = UDim2.new(1, -66 - 70, 0, 17),
			BackgroundTransparency = 1,
			Text = "",
			FontFace = Font.new(era.fontes.body.Family, Enum.FontWeight.Bold),
			TextSize = 14,
			TextColor3 = cr.ink,
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
			TextColor3 = cr.accent,
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
			TextColor3 = cr.inkMuted,
			TextXAlignment = Enum.TextXAlignment.Right,
		}, linha)
		-- embaixo do nome: o título (pelo nível e pela era da melhor companhia) e o prego dourado de Pioneer
		local tituloL = novo("TextLabel", {
			Position = UDim2.fromOffset(66, 19),
			Size = UDim2.new(1, -66 - 70, 0, 14),
			BackgroundTransparency = 1,
			Text = "",
			FontFace = Font.new(era.fontes.body.Family, Enum.FontWeight.Regular, Enum.FontStyle.Italic),
			TextSize = 12,
			TextColor3 = cr.inkMuted,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			RichText = true,
		}, linha)
		linhasRanking[i] = { frame = linha, foto = foto, nome = nomeL, titulo = tituloL, nivel = nivelL, linhas = linhasL }
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
				local titulo = Economia.tituloNivel(tonumber(item.nivel) or 1, item.era, Idioma.atual)
				if item.pioneiro then
					titulo ..= ` · <font color="#3F8F4F"><b>{L("Pioneiro", "Pioneer")}</b></font>`
				end
				if Equipe[item.userId] then
					titulo = `<font color="#B8382B"><b>{L("Dono", "Owner")}</b></font> · ` .. titulo
				end
				l.titulo.Text = titulo
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
	task.defer(function()
		self._medir()
	end)
	coluna:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		self._medir(true)
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
