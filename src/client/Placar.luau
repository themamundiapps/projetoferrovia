--!strict
-- Ranking dos jogadores deste servidor, no canto de cima à direita: foto, nome, companhia, nível e
-- linhas completas. Ranking justo: ordena pelo nível (e linhas completas no desempate), que vêm de
-- jogar; o dinheiro não entra porque dá para comprar na loja. Clicar no título recolhe e abre. Some
-- quando o painel do trecho (que abre no mesmo canto) está aberto.
-- Os números vêm dos atributos que o servidor põe em cada jogador (Jogo.atualizarPlacar):
-- Nivel, Linhas, Companhia (nome já filtrado pelo Roblox) e Pinturas (selo ✦ do passe).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Idioma = require(Shared:WaitForChild("Idioma"))
local Emojis = require(Shared:WaitForChild("Emojis"))
local Estilo = require(script.Parent:WaitForChild("Estilo"))

local L = Idioma.L

local MAX_LINHAS = 8
local LARGURA = 250
local ALTURA_LINHA = 38
local INTERVALO = 2 -- segundos entre atualizações
-- cor da medalha do 1º, 2º e 3º lugar
local CORES_PODIO = { Color3.fromRGB(222, 178, 58), Color3.fromRGB(178, 184, 192), Color3.fromRGB(186, 122, 72) }

local Placar = {}
Placar.__index = Placar

export type Placar = typeof(setmetatable(
	{} :: {
		raiz: Frame,
		lista: Frame,
		titulo: TextButton,
		linhas: { any },
		aberto: boolean,
		escondido: boolean,
		vivo: boolean,
		simbolo: string?,
		fotos: { [number]: string },
	},
	Placar
))

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

function Placar.new(tela: ScreenGui, era: any, simbolo: string?): Placar
	local est = Estilo.new(era)
	local c, f = est.c, era.fontes
	local self = setmetatable({}, Placar) :: Placar
	self.linhas = {}
	self.aberto = true
	self.escondido = false
	self.vivo = true
	self.simbolo = simbolo
	self.fotos = {}

	local raiz = est:caixa({
		Name = "Placar",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -Estilo.MARGEM_LATERAL, 0, Estilo.TOPO_TELA + 12),
		Size = UDim2.fromOffset(LARGURA, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ZIndex = 30,
	}, tela)
	-- abaixo dos painéis do menu (que abrem por cima dele)
	raiz.ZIndex = 26
	self.raiz = raiz
	local corpo = novo("Frame", {
		Name = "Corpo",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ZIndex = 27,
	}, raiz)
	novo("UIPadding", {
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
	}, corpo)
	novo("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }, corpo)

	self.titulo = novo("TextButton", {
		Name = "Titulo",
		LayoutOrder = 0,
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundTransparency = 1,
		Text = "",
		FontFace = f.display,
		TextSize = 15,
		TextColor3 = c.ink,
		TextXAlignment = Enum.TextXAlignment.Left,
		AutoButtonColor = false,
		ZIndex = 28,
	}, corpo)
	self.titulo.Activated:Connect(function()
		self.aberto = not self.aberto
		self.lista.Visible = self.aberto
		self:_titulo()
	end)

	self.lista = novo("Frame", {
		Name = "Lista",
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ZIndex = 27,
	}, corpo)
	novo("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) }, self.lista)

	for i = 1, MAX_LINHAS do
		local linha = novo("Frame", {
			Name = "Linha" .. i,
			LayoutOrder = i,
			Size = UDim2.new(1, 0, 0, ALTURA_LINHA),
			BackgroundColor3 = c.accent,
			BackgroundTransparency = 1,
			Visible = false,
			ZIndex = 27,
		}, self.lista)
		novo("UICorner", { CornerRadius = UDim.new(0, 6) }, linha)
		-- posição: medalha colorida no pódio, número simples dali para baixo
		local pos = novo("TextLabel", {
			Name = "Posicao",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 2, 0.5, 0),
			Size = UDim2.fromOffset(20, 20),
			BackgroundColor3 = CORES_PODIO[i] or c.panel,
			BackgroundTransparency = if CORES_PODIO[i] then 0 else 1,
			Text = tostring(i),
			FontFace = f.display,
			TextSize = 13,
			TextColor3 = if CORES_PODIO[i] then Color3.fromRGB(40, 28, 18) else c.inkMuted,
			ZIndex = 28,
		}, linha)
		novo("UICorner", { CornerRadius = UDim.new(1, 0) }, pos)
		local foto = novo("ImageLabel", {
			Name = "Foto",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 28, 0.5, 0),
			Size = UDim2.fromOffset(30, 30),
			BackgroundColor3 = c.rule,
			Image = "",
			ZIndex = 28,
		}, linha)
		novo("UICorner", { CornerRadius = UDim.new(1, 0) }, foto)
		novo("UIStroke", { Color = c.ink, Thickness = 1.5, Transparency = 0.3 }, foto)
		local nome = novo("TextLabel", {
			Name = "Nome",
			Position = UDim2.fromOffset(66, 3),
			Size = UDim2.new(1, -66 - 78, 0, 17),
			BackgroundTransparency = 1,
			Text = "",
			FontFace = Font.new(f.body.Family, Enum.FontWeight.Bold),
			TextSize = 14,
			TextColor3 = c.ink,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 28,
		}, linha)
		local companhia = novo("TextLabel", {
			Name = "Companhia",
			Position = UDim2.fromOffset(66, 20),
			Size = UDim2.new(1, -66 - 78, 0, 14),
			BackgroundTransparency = 1,
			Text = "",
			FontFace = f.body,
			TextSize = 12,
			TextColor3 = c.inkMuted,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 28,
		}, linha)
		-- à direita: o nível em destaque e, embaixo, as linhas completas
		local nivel = novo("TextLabel", {
			Name = "Nivel",
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -4, 0, 3),
			Size = UDim2.fromOffset(76, 17),
			BackgroundTransparency = 1,
			Text = "",
			FontFace = Font.new(f.body.Family, Enum.FontWeight.Bold),
			TextSize = 14,
			TextColor3 = c.accent,
			TextXAlignment = Enum.TextXAlignment.Right,
			ZIndex = 28,
		}, linha)
		local linhasTxt = novo("TextLabel", {
			Name = "Linhas",
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -4, 0, 20),
			Size = UDim2.fromOffset(76, 14),
			BackgroundTransparency = 1,
			Text = "",
			FontFace = f.body,
			TextSize = 12,
			TextColor3 = c.inkMuted,
			TextXAlignment = Enum.TextXAlignment.Right,
			ZIndex = 28,
		}, linha)
		self.linhas[i] = { frame = linha, foto = foto, nome = nome, companhia = companhia, nivel = nivel, linhas = linhasTxt }
	end

	self:atualizar()
	task.spawn(function()
		while self.vivo do
			task.wait(INTERVALO)
			if self.vivo then
				self:atualizar()
			end
		end
	end)
	return self
end

function Placar._titulo(self: Placar)
	local n = #Players:GetPlayers()
	local seta = if self.aberto then "-" else "+" -- ▾ e ▸ não existem na fonte da Alta Velocidade
	self.titulo.Text = `{Emojis.nivel or "🏆"} {Idioma.maiusculas(L("Neste servidor", "On this server"))} ({n})  {seta}`
end

-- Foto do jogador (rosto), pedida uma vez por jogador.
function Placar._foto(self: Placar, img: ImageLabel, userId: number)
	local cache = self.fotos[userId]
	if cache then
		img.Image = cache
		return
	end
	img.Image = ""
	task.spawn(function()
		local ok, conteudo = pcall(function()
			return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
		end)
		if ok and conteudo then
			self.fotos[userId] = conteudo
			if img.Parent and img:GetAttribute("UserId") == userId then
				img.Image = conteudo
			end
		end
	end)
end

function Placar.atualizar(self: Placar)
	self:_titulo()
	local lista = {}
	for _, j in Players:GetPlayers() do
		table.insert(lista, {
			jogador = j,
			linhas = tonumber(j:GetAttribute("Linhas")) or 0,
			companhia = tostring(j:GetAttribute("Companhia") or ""),
			nivel = tonumber(j:GetAttribute("Nivel")) or 0,
			pinturas = j:GetAttribute("Pinturas") == true,
		})
	end
	table.sort(lista, function(a, b)
		if a.nivel ~= b.nivel then
			return a.nivel > b.nivel
		elseif a.linhas ~= b.linhas then
			return a.linhas > b.linhas
		end
		return a.jogador.UserId < b.jogador.UserId
	end)
	for i, l in self.linhas do
		local item = lista[i]
		l.frame.Visible = item ~= nil
		if not item then
			continue
		end
		local eu = item.jogador == Players.LocalPlayer
		-- a linha do próprio jogador ganha um fundo leve
		l.frame.BackgroundTransparency = if eu then 0.8 else 1
		l.nome.Text = item.jogador.DisplayName .. (if item.pinturas then " ✦" else "")
		l.companhia.Text = if item.companhia ~= "" then item.companhia else Idioma.T("companhia_padrao")
		l.nivel.Text = `{L("Nível", "Level")} {item.nivel}`
		l.linhas.Text = L(`{item.linhas} linha{if item.linhas == 1 then "" else "s"}`, `{item.linhas} line{if item.linhas == 1 then "" else "s"}`)
		if l.foto:GetAttribute("UserId") ~= item.jogador.UserId then
			l.foto:SetAttribute("UserId", item.jogador.UserId)
			self:_foto(l.foto, item.jogador.UserId)
		end
	end
end

-- Esconde enquanto outro painel ocupa o canto (o painel do trecho, por exemplo).
function Placar.esconder(self: Placar, sim: boolean)
	self.escondido = sim
	self.raiz.Visible = not sim
end

-- Topo do painel, em pixels da interface (logo abaixo da barra de cima e do botão da era).
function Placar.posicionar(self: Placar, y: number)
	self.raiz.Position = UDim2.new(1, -Estilo.MARGEM_LATERAL, 0, y + 10)
end

function Placar.destruir(self: Placar)
	self.vivo = false
	self.raiz:Destroy()
end

return Placar
