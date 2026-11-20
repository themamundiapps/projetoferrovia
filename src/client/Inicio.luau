--!strict
-- Menu inicial: boas-vindas, escolha do mapa (Brasil; EUA e Europa em breve) e novidades.
-- Fica por cima de tudo; o mapa da companhia passa devagar no fundo (o init.client cuida do passeio).
-- Uso: Inicio.new(playerGui) mostra "Carregando…"; :montar(estado, era, dados) monta o menu;
-- aoJogar dispara no botão do Brasil; :fechar() some com fade; :destruir().

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Economia = require(Shared:WaitForChild("Economia"))
local Idioma = require(Shared:WaitForChild("Idioma"))
local Novidades = require(Shared:WaitForChild("Novidades"))
local Emojis = require(Shared:WaitForChild("Emojis"))
local Estilo = require(script.Parent:WaitForChild("Estilo"))

local novo = Estilo.novo
local LARGURA_COLUNA = 470

local Inicio = {}
Inicio.__index = Inicio

export type Inicio = typeof(setmetatable(
	{} :: {
		gui: ScreenGui,
		raiz: CanvasGroup,
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
	local raiz = novo("CanvasGroup", {
		Name = "Raiz",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0, -- tela preta até o estado chegar
		Active = true, -- segura cliques e roda do mouse: o mapa de fundo não mexe
	}, gui) :: CanvasGroup
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
	local escala = novo("UIScale", { Name = "Escala" }, raiz) :: UIScale
	local self = setmetatable({
		gui = gui,
		raiz = raiz,
		escala = escala,
		conteudo = nil :: any,
		aoJogar = Instance.new("BindableEvent"),
		aberto = true,
		conexoes = {},
		_medir = function() end,
	}, Inicio)
	local function medir()
		local t = raiz.AbsoluteSize
		if t.X > 0 and t.Y > 0 then
			-- cabe na tela: pela largura e pela altura da coluna (em pontos virtuais)
			local coluna = self.conteudo and self.conteudo:FindFirstChild("Coluna") :: Frame?
			local alturaColuna = if coluna then coluna.AbsoluteSize.Y / math.max(escala.Scale, 0.01) else 560
			escala.Scale = math.clamp(math.min(t.X / 1000, t.Y * 0.92 / math.max(alturaColuna, 400)), 0.55, 1.1)
		end
	end
	self._medir = medir
	table.insert(self.conexoes, raiz:GetPropertyChangedSignal("AbsoluteSize"):Connect(medir))
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
	local s = 1 / math.max(self.escala.Scale, 0.01)

	-- tudo dentro de um quadro em "pontos virtuais" (a escala vale para o quadro inteiro)
	local conteudo = novo("Frame", {
		Name = "Conteudo",
		Size = UDim2.fromScale(s, s),
		BackgroundTransparency = 1,
	}, self.raiz) :: Frame
	self.conteudo = conteudo
	table.insert(self.conexoes, self.escala:GetPropertyChangedSignal("Scale"):Connect(function()
		local k = 1 / math.max(self.escala.Scale, 0.01)
		conteudo.Size = UDim2.fromScale(k, k)
	end))

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
		Size = UDim2.new(1, 0, 0, 128),
		BackgroundTransparency = 1,
	}, coluna)
	est:lista(fileira, 10, true)
	local mapas = {
		{
			id = "brasil",
			nome = L("Brasil", "Brazil"),
			info = L(`{#dados.linhas} linhas · 1854 até hoje`, `{#dados.linhas} lines · 1854 to today`),
			pronto = true,
		},
		{ id = "eua", nome = L("Estados Unidos", "United States"), info = L("Em breve", "Coming soon"), pronto = false },
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
		if m.pronto then
			local b = est:botao("principal", if temCompanhia then L("Continuar", "Continue") else L("Jogar", "Play"), cartao, 4)
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
	-- ajusta a escala para a coluna inteira caber na altura da tela
	task.defer(self._medir)
	coluna:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		self._medir()
	end)
end

-- Some com fade (o mapa continua embaixo) e para de segurar os cliques.
function Inicio.fechar(self: Inicio, duracao: number?)
	if not self.aberto then
		return
	end
	self.aberto = false
	local d = duracao or 0.5
	local tw = TweenService:Create(self.raiz, TweenInfo.new(d, Enum.EasingStyle.Quad), { GroupTransparency = 1 })
	tw.Completed:Once(function()
		self.gui.Enabled = false
	end)
	tw:Play()
end

-- Volta a mostrar (botão "Menu inicial" em Ajustes).
function Inicio.abrir(self: Inicio)
	self.aberto = true
	self.gui.Enabled = true
	self.raiz.GroupTransparency = 1
	TweenService:Create(self.raiz, TweenInfo.new(0.4, Enum.EasingStyle.Quad), { GroupTransparency = 0 }):Play()
end

function Inicio.destruir(self: Inicio)
	for _, c in self.conexoes do
		c:Disconnect()
	end
	self.gui:Destroy()
	self.aoJogar:Destroy()
end

return Inicio
