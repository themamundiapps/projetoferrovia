--!strict
-- Menu: barra inferior (Linhas, Gabinete, Contratos, Companhia, Ajustes), o painel lateral de cada uma
-- e os botões de zoom.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Economia = require(Shared:WaitForChild("Economia"))
local Emojis = require(Shared:WaitForChild("Emojis"))
local Metas = require(Shared:WaitForChild("Metas"))
local Idioma = require(Shared:WaitForChild("Idioma"))
local L = Idioma.L
local Jornal = require(Shared:WaitForChild("Jornal"))
local Assets = require(Shared:WaitForChild("Assets"))
local Creditos = require(Shared:WaitForChild("Creditos"))
local Tarifas = require(Shared:WaitForChild("Tarifas"))
local Decisoes = require(Shared:WaitForChild("Decisoes"))
local Loja = require(Shared:WaitForChild("Loja"))
local Estilo = require(script.Parent:WaitForChild("Estilo"))

local novo = Estilo.novo

local Menu = {}
Menu.__index = Menu

export type Menu = typeof(setmetatable({} :: any, Menu))

local ABAS = {
	{ id = "linhas", nome = { pt = "Linhas", en = "Lines" }, emoji = "linhas" },
	{ id = "projetos", nome = { pt = "Gabinete", en = "Cabinet" }, emoji = "gabinete" },
	{ id = "metas", nome = { pt = "Contratos", en = "Contracts" }, emoji = "contratos" },
	{ id = "jornal", nome = { pt = "Jornal", en = "Newspaper" }, emoji = "jornal" },
	{ id = "tarifas", nome = { pt = "Tarifas", en = "Fares" }, emoji = "tarifas" },
	{ id = "companhia", nome = { pt = "Companhia", en = "Company" }, emoji = "companhia" },
	{ id = "loja", nome = { pt = "Loja", en = "Shop" }, emoji = "loja" },
	{ id = "ajustes", nome = { pt = "Ajustes", en = "Settings" }, emoji = "configuracoes" },
}

function Menu.new(tela: ScreenGui, era: any, dados: any): Menu
	local est = Estilo.new(era)
	local self = setmetatable({}, Menu)
	self.est = est
	self.dados = dados
	self.estado = nil :: any
	self.aba = nil :: string?
	self.verCreditos = false -- dentro de Ajustes: lista de créditos no lugar das opções
	self.verConquistas = false -- dentro de Companhia: a galeria de conquistas no lugar do resumo
	self.ajudaAberta = {} :: { [string]: boolean } -- explicação aberta pelo botão "?" de cada aba
	self.ajustes = { nomesEstacoes = true, nomesMapa = true, trens = true, musica = true, efeitos = true }
	self.aoAgir = Instance.new("BindableEvent") -- (tipo, args)
	self.aoFocarLinha = Instance.new("BindableEvent") -- (linhaId)
	self.aoAjuste = Instance.new("BindableEvent") -- (chave, valor)
	self.aoZoom = Instance.new("BindableEvent") -- (fator)
	self.aoConcluirProjeto = Instance.new("BindableEvent") -- (projeto) quando um estudo termina
	self.aoAbrirDireita = Instance.new("BindableEvent") -- painel aberto à direita: a ficha e a concessão saem da frente
	self.instancias = {} :: { Instance }
	self.vivos = {} :: { () -> () } -- atualizações a cada segundo que não recriam o painel (cronômetros, botões)
	self._concluidos = {} :: { [string]: boolean }
	self.avisoGabinete = false -- bolinha na aba quando um estudo termina com a aba fechada
	self.avisoJornal = false -- bolinha na aba quando sai notícia nova com a aba fechada

	-- ---------------------------------------------------- barra inferior
	-- com o kit clássico: base de mogno e medalhões; senão, a caixa com abas
	local barra, fileira = est:barraMedalhoes({
		Name = "BarraMenu",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -6),
	}, tela, #ABAS)
	if not barra then
		local caixa = est:caixa({
			Name = "BarraMenu",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -14 - est:bordaKit()),
			AutomaticSize = Enum.AutomaticSize.XY,
			Size = UDim2.fromOffset(0, 0),
		}, tela)
		est:padding(caixa, 6)
		est:lista(caixa, 6, true)
		barra, fileira = caixa, caixa
	end
	table.insert(self.instancias, barra :: Frame)
	self.barra = barra
	self.botoesAba = {} :: { [string]: TextButton }
	self.medalhoes = {} :: { [string]: any } -- com o kit clássico, a barra vira uma fileira de medalhões
	for i, aba in ABAS do
		local m = est:medalhao((Emojis :: any)[aba.emoji], Idioma.t(aba.nome), fileira :: Frame, i, aba.id)
		if m then
			m.botao.Name = "Aba_" .. aba.id
			m.botao.Activated:Connect(function()
				self:abrirAba(if self.aba == aba.id then nil else aba.id)
			end)
			self.botoesAba[aba.id] = m.botao
			self.medalhoes[aba.id] = m
			continue
		end
		-- Ajustes vira só o ícone, para a barra caber em telas menores
		local rotulo = if aba.id == "ajustes" then (Emojis :: any)[aba.emoji] else `{(Emojis :: any)[aba.emoji]} {Idioma.t(aba.nome)}`
		local b = est:aba(rotulo, fileira :: Frame, i)
		b.Name = "Aba_" .. aba.id
		b.Size = UDim2.fromOffset(0, 44)
		b.AutomaticSize = Enum.AutomaticSize.X
		est:padding(b, 14, 0)
		b.Activated:Connect(function()
			self:abrirAba(if self.aba == aba.id then nil else aba.id)
		end)
		self.botoesAba[aba.id] = b
	end

	-- ---------------------------------------------------- zoom (celular)
	local zoom = novo("Frame", {
		Name = "Zoom",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16 - Estilo.INSET_DIR, 1, -16),
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1,
		ZIndex = 30,
	}, tela)
	est:lista(zoom, 6)
	table.insert(self.instancias, zoom)
	local rotulos = { "+", "–" }
	local fatores = { 1.4, 1 / 1.4 }
	for i, rotulo in rotulos do
		local b = est:botaoRedondo(rotulo, zoom, i)
		b.Name = if i == 1 then "ZoomMais" else "ZoomMenos"
		b.Size = UDim2.fromOffset(52, 52)
		b.BackgroundColor3 = est.c.panel
		b.TextSize = 30
		b.Activated:Connect(function()
			self.aoZoom:Fire(fatores[i])
		end)
	end
	-- No computador o zoom é a roda do mouse: os botões só aparecem em tela de toque. Se não couberem
	-- ao lado da barra de baixo (tela estreita), sobem para cima dela, no canto direito.
	zoom.Visible = UserInputService.TouchEnabled
	local function posicionarZoom()
		local livre = (tela.AbsoluteSize.X - (barra :: Frame).AbsoluteSize.X) / 2
		local cabe = livre >= zoom.AbsoluteSize.X + (16 + 8 + Estilo.INSET_DIR) * Estilo.escala
		zoom.Position = UDim2.new(1, -16 - Estilo.INSET_DIR, 1, if cabe then -16 else -(Estilo.px((barra :: Frame).AbsoluteSize.Y) + 6 + 10))
	end
	self._vigiaZoom = tela:GetPropertyChangedSignal("AbsoluteSize"):Connect(posicionarZoom)
	zoom:GetPropertyChangedSignal("AbsoluteSize"):Connect(posicionarZoom)
	posicionarZoom()

	-- os painéis abrem pelos medalhões da barra de baixo (as gavetas das laterais saíram: repetiam
	-- Companhia e Linhas). O painel fica à esquerda; "dir" continua existindo para quem abrir por código.
	self.lado = "esq"
	self.ultimaAba = "companhia"
	-- a ficha da cidade e a concessão abrem à direita: o painel da direita sai da frente
	local function vigiar(filho: Instance)
		if (filho.Name == "Ficha" or filho.Name == "Concessao") and filho:IsA("GuiObject") then
			filho:GetPropertyChangedSignal("Visible"):Connect(function()
				if filho.Visible and self.aba and self.lado == "dir" then
					self:abrirAba(nil)
				end
			end)
		end
	end
	for _, filho in tela:GetChildren() do
		vigiar(filho)
	end
	self._vigiaTela = tela.ChildAdded:Connect(vigiar)

	-- ---------------------------------------------------- painel lateral (conteúdo da aba)
	local painel = est:caixa({
		Name = "PainelMenu",
		Position = UDim2.fromOffset(Estilo.MARGEM_LATERAL, 150),
		Size = UDim2.new(0, 330, 1, -240),
		Visible = false,
	}, tela)
	table.insert(self.instancias, painel)
	self.painel = painel
	local rolagem = novo("ScrollingFrame", {
		Name = "Rolagem",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = est.c.inkMuted,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ZIndex = 31,
	}, painel)
	est:padding(rolagem, 14)
	est:lista(rolagem, 8)
	self.rolagem = rolagem

	return self
end

function Menu.destruir(self: Menu)
	for _, inst in self.instancias do
		inst:Destroy()
	end
	self.aoAgir:Destroy()
	if self._vigiaTela then
		self._vigiaTela:Disconnect()
	end
	if self._vigiaZoom then
		self._vigiaZoom:Disconnect()
	end
	self.aoFocarLinha:Destroy()
	self.aoAjuste:Destroy()
	self.aoZoom:Destroy()
	self.aoConcluirProjeto:Destroy()
end

-- Coloca o painel lateral logo abaixo de uma posição Y da tela (abaixo do caixa da companhia).
function Menu.posicionarAbaixoDe(self: Menu, y: number)
	self._topoY = y
	-- com a moldura do kit, as caixas ganham uma borda por fora: o vão entre elas cresce junto
	local b = self.est:bordaKit()
	-- o painel fica no lado em que foi aberto (normalmente à esquerda)
	local dir = self.lado == "dir"
	local margem = Estilo.MARGEM_LATERAL + b
	self.painel.AnchorPoint = Vector2.new(if dir then 1 else 0, 0)
	self.painel.Position = UDim2.new(if dir then 1 else 0, if dir then -margem else margem, 0, y + 10 + 2 * b)
	-- embaixo, para acima da barra do menu (que cresce com os medalhões)
	local barra = self.barra
	local alturaBarra = if barra then Estilo.px(barra.AbsoluteSize.Y) else 60
	-- o Jornal abre como uma página larga; as outras abas, na largura normal
	local largura = if self.aba == "jornal" then 560 else 330
	self.painel.Size = UDim2.new(0, largura, 1, -(y + 10 + 2 * b) - (alturaBarra + 14 + 3 * b) - 10)
end

function Menu.abrirAba(self: Menu, aba: string?, lado: string?)
	if aba ~= self.aba then
		-- aba nova começa do topo (o redesenho guarda a rolagem só dentro da mesma aba)
		self.rolagem.CanvasPosition = Vector2.zero
		self.verCreditos = false
		self.verConquistas = false
	end
	self.aba = aba
	if aba then
		self.ultimaAba = aba
		self.lado = lado or "esq"
		if self.lado == "dir" then
			self.aoAbrirDireita:Fire()
		end
		if self._topoY then
			self:posicionarAbaixoDe(self._topoY)
		end
	end
	if aba == "projetos" then
		self.avisoGabinete = false
	elseif aba == "jornal" then
		self.avisoJornal = false
	end
	self:_rotularAbas()
	self.painel.Visible = aba ~= nil
	for id, b in self.botoesAba do
		local m = self.medalhoes[id]
		if m then
			self.est:marcarMedalhao(m, id == aba)
		else
			self.est:marcarAba(b, id == aba)
		end
	end
	self:_redesenhar()
end

-- O painel só é redesenhado quando muda algo que ele mostra (trechos, trens, estações, era, projetos).
-- Redesenhar a cada segundo destruiria os botões no meio de um clique.
function Menu._assinatura(self: Menu, estado: any): string
	local situacoes = {}
	for _, p in self.dados.projetos or {} do
		table.insert(situacoes, Economia.situacaoProjeto(estado, self.dados, p))
	end
	-- metas: contrato, ofertas, missões (só o que muda o desenho, não o progresso), medalhas e nível
	local metas: { any } = { if estado.contrato then estado.contrato.id else 0, (Economia.nivel(estado)) }
	for _, o in estado.ofertas or {} do
		table.insert(metas, o.id)
	end
	for _, m in (estado.missoes or {}).lista or {} do
		table.insert(metas, `{m.tipo}{m.meta}{m.progresso >= m.meta}{m.resgatada}`)
	end
	local medalhas = 0
	for _ in estado.medalhas or {} do
		medalhas += 1
	end
	table.insert(metas, medalhas)
	table.insert(metas, estado.nomeCompanhia or "")
	for _, ev in Economia.eventosAtivos(estado) do
		table.insert(metas, ev.id .. ev.inicio)
	end
	for _, ev in Economia.efeitosDecisoes(estado) do
		table.insert(metas, ev.id .. ev.tipo .. ev.inicio)
	end
	table.insert(metas, #((estado.jornal or {}).edicoes or {}))
	-- loja: redesenha quando compra um passe, liga/desliga o gerente ou guarda um estudo
	local lj = estado.loja or {}
	table.insert(metas, `{lj.dobro}{lj.estudos}{lj.offline}{lj.gerente}{lj.gerenteLigado}{lj.pinturas}{lj.estudosGuardados}`)
	-- tarifas: redesenha quando muda um preço ou um serviço
	local tf = estado.tarifas or Tarifas.padrao()
	table.insert(metas, table.concat(tf.precos, ","))
	for _, sv in Tarifas.SERVICOS do
		table.insert(metas, if tf.servicos[sv.id] then sv.id else "")
	end
	local ok, txt = pcall(function()
		return HttpService:JSONEncode({ estado.trechos, estado.trens, estado.estacoes or {}, estado.era, situacoes, metas })
	end)
	return if ok then txt else tostring(os.clock())
end

local function numero(n: number): string
	return (Economia.formatar(n, "", false):gsub("^%s+", ""))
end

local function relogio(segundos: number): string
	segundos = math.max(0, math.ceil(segundos))
	local h, m, s = segundos // 3600, (segundos % 3600) // 60, segundos % 60
	if h > 0 then
		return string.format("%d:%02d:%02d", h, m, s)
	end
	return string.format("%d:%02d", m, s)
end

-- Texto das abas: o Gabinete mostra o cronômetro do estudo e uma bolinha quando um estudo termina;
-- Contratos mostra o prazo do contrato e uma bolinha quando há missão para resgatar.
-- Com medalhões, o nome fica na placa e o extra (cronômetro, ●, contagem) vai numa etiqueta em cima.
function Menu._etiquetar(self: Menu, id: string, nome: string, extra: string): boolean
	local m = self.medalhoes[id]
	if not m then
		return false
	end
	m.nome.Text = nome
	m.etiqueta.Text = extra
	m.etiqueta.Visible = extra ~= ""
	return true
end

function Menu._rotularAbas(self: Menu)
	if next(self.medalhoes) then
		local function extraGabinete(): string
			local atual, restante = nil, 0
			if self.estado then
				atual, restante = Economia.pesquisaAtual(self.estado)
			end
			return if atual then relogio(restante) elseif self.avisoGabinete then "●" else ""
		end
		local function extraJornal(): string
			local ativos = if self.estado then #Economia.eventosAtivos(self.estado) else 0
			return if self.avisoJornal then "●" elseif ativos > 0 then tostring(ativos) else ""
		end
		local function extraMetas(): string
			local contrato = self.estado and self.estado.contrato
			return if contrato then relogio(contrato.prazo - contrato.decorrido)
				elseif self.estado and Metas.missaoParaResgatar(self.estado) then "●"
				else ""
		end
		self:_etiquetar("projetos", L("Gabinete", "Cabinet"), extraGabinete())
		self:_etiquetar("jornal", L("Jornal", "Newspaper"), extraJornal())
		self:_etiquetar("metas", L("Contratos", "Contracts"), extraMetas())
		return
	end
	local b = self.botoesAba.projetos
	if b then
		local txt = L(`{Emojis.gabinete} Gabinete`, `{Emojis.gabinete} Cabinet`)
		local atual, restante = nil, 0
		if self.estado then
			atual, restante = Economia.pesquisaAtual(self.estado)
		end
		if atual then
			txt ..= ` · {relogio(restante)}`
		elseif self.avisoGabinete then
			txt ..= " ●"
		end
		b.Text = txt
	end
	local bj = self.botoesAba.jornal
	if bj then
		local txt = L(`{Emojis.jornal} Jornal`, `{Emojis.jornal} Newspaper`)
		local ativos = if self.estado then #Economia.eventosAtivos(self.estado) else 0
		if self.avisoJornal then
			txt ..= " ●"
		elseif ativos > 0 then
			txt ..= ` · {ativos}`
		end
		bj.Text = txt
	end
	local bm = self.botoesAba.metas
	if bm then
		local txt = L(`{Emojis.contratos} Contratos`, `{Emojis.contratos} Contracts`)
		local contrato = self.estado and self.estado.contrato
		if contrato then
			txt ..= ` · {relogio(contrato.prazo - contrato.decorrido)}`
		elseif self.estado and Metas.missaoParaResgatar(self.estado) then
			txt ..= " ●"
		end
		bm.Text = txt
	end
end

function Menu.atualizarEstado(self: Menu, estado: any)
	-- estudo que terminou desde a última atualização: avisa na aba
	local antes = self.estado
	if antes then
		for _, p in self.dados.projetos or {} do
			if Economia.projetoConcluido(estado, p.id) and (antes.projetos or {})[p.id] and not self._concluidos[p.id] then
				if self.aba ~= "projetos" then
					self.avisoGabinete = true
				end
				self.aoConcluirProjeto:Fire(p)
			end
		end
	end
	self._concluidos = {}
	for _, p in self.dados.projetos or {} do
		if Economia.projetoConcluido(estado, p.id) then
			self._concluidos[p.id] = true
		end
	end
	self.estado = estado
	self:_rotularAbas()
	local nova = self:_assinatura(estado)
	if nova ~= self._assinaturaAtual then
		self._assinaturaAtual = nova
		if self.aba then
			self:_redesenhar()
		end
	else
		for _, f in self.vivos do
			f()
		end
	end
end

function Menu._limpar(self: Menu)
	for _, filho in self.rolagem:GetChildren() do
		if filho:IsA("GuiObject") then
			filho:Destroy()
		end
	end
end

-- Título da aba com um botão "?" que mostra (ou esconde) a explicação logo abaixo.
-- A explicação começa escondida: quem já sabe como funciona vê o conteúdo direto.
function Menu._titulo(self: Menu, texto: string, ajuda: string?, pai: Instance?)
	local est, r = self.est, pai or self.rolagem
	local l = est:titulo(texto, r, 1)
	if not ajuda then
		return
	end
	local chave = self.aba or ""
	local aberta = self.ajudaAberta[chave] == true
	local alvo: Instance = if l.Parent and l.Parent.Name == "Cabecalho" then l.Parent else l
	local c = est:paleta(alvo)
	local b = novo("TextButton", {
		Name = "Ajuda",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(26, 26),
		BackgroundColor3 = if aberta then c.accent else c.panel,
		BackgroundTransparency = if aberta then 0 else 0.2,
		Text = "?",
		TextColor3 = if aberta then c.onAccent else c.ink,
		FontFace = est.f.number,
		TextSize = 16,
		AutoButtonColor = true,
		ZIndex = 40,
	}, alvo)
	novo("UICorner", { CornerRadius = UDim.new(1, 0) }, b)
	novo("UIStroke", { Color = c.rule, Thickness = 1 }, b)
	b.Activated:Connect(function()
		self.ajudaAberta[chave] = not aberta
		self:_redesenhar()
	end)
	if aberta then
		est:texto("fraco", ajuda, r, 2)
	end
end

function Menu._redesenhar(self: Menu)
	if not self.aba then
		return
	end
	-- guarda a rolagem para a lista não "pular" a cada atualização
	local rolagemY = self.rolagem.CanvasPosition.Y
	self:_limpar()
	table.clear(self.vivos)
	if self.aba == "linhas" then
		self:_abaLinhas()
	elseif self.aba == "projetos" then
		self:_abaProjetos()
	elseif self.aba == "metas" then
		self:_abaMetas()
	elseif self.aba == "jornal" then
		self:_abaJornal()
	elseif self.aba == "tarifas" then
		self:_abaTarifas()
	elseif self.aba == "companhia" then
		self:_abaCompanhia()
	elseif self.aba == "loja" then
		self:_abaLoja()
	else
		self:_abaAjustes()
	end
	self.rolagem.CanvasPosition = Vector2.new(0, rolagemY)
end

-- ---------------------------------------------------------------- aba Linhas

function Menu._abaLinhas(self: Menu)
	local est, dados, estado, r = self.est, self.dados, self.estado, self.rolagem
	self:_titulo(L(`{Emojis.linhas} Linhas`, `{Emojis.linhas} Lines`), L("Construir tudo compra os trechos liberados do mais barato para o mais caro. Completar frotas compra trens até todos os passageiros embarcarem e vende os que estão rodando vazios. Toque numa linha para vê-la no mapa.", "Build everything buys the unlocked sections from cheapest to most expensive. Fill up fleets buys trains until every passenger can board and sells the ones running empty. Tap a line to see it on the map."))
	if not estado then
		return
	end
	local simbolo = dados.simbolo

	-- os dois botões lado a lado, para sobrar espaço para as linhas
	local botoes = novo("Frame", {
		Name = "Botoes",
		LayoutOrder = 3,
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
		ZIndex = 31,
	}, r)
	est:lista(botoes, 8, true)
	local bTudo = est:botao("principal", L(`{Emojis.construir} Construir tudo`, `{Emojis.construir} Build all`), botoes, 1)
	bTudo.Name = "BtnConstruirTudo"
	bTudo.Size = UDim2.new(0.5, -4, 1, 0)
	bTudo.Activated:Connect(function()
		self.aoAgir:Fire("construirTudo", {})
	end)
	local bFrota = est:botao("secundario", L(`{Emojis.trens} Completar frotas`, `{Emojis.trens} Fill fleets`), botoes, 2)
	bFrota.Size = UDim2.new(0.5, -4, 1, 0)
	bFrota.Name = "BtnCompletarFrotas"
	bFrota.Activated:Connect(function()
		self.aoAgir:Fire("completarFrotas", {})
	end)

	local balanco = Economia.balanco(estado, dados)
	local rede = Economia.rede(estado, dados)
	for i, linha in dados.linhas do
		local construidos = Economia.trechosConstruidos(estado, linha)
		local liberada = Economia.linhaLiberada(estado, dados, i)
		local completa = construidos == #linha.trechos
		local faltando = Economia.trensFaltando(estado, dados, linha, rede)
		local sobrando = Economia.trensSobrando(estado, dados, linha, rede)
		local bl = balanco.linhas[linha.id]
		local cor = self.est.era.linhas[linha.cor] or est.c.ink

		local linhaBtn = novo("TextButton", {
			Name = "Linha_" .. linha.id,
			LayoutOrder = 10 + i,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = est.c.bg,
			Text = "",
			AutoButtonColor = true,
			ZIndex = 32,
		}, r)
		est:cantos(linhaBtn)
		novo("UIStroke", { Color = est.c.rule, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, linhaBtn)
		est:padding(linhaBtn, 10, 8)
		novo("Frame", {
			Size = UDim2.new(0, 6, 1, 0),
			BackgroundColor3 = cor,
			BackgroundTransparency = if liberada then 0 else 0.6,
			BorderSizePixel = 0,
			ZIndex = 33,
		}, linhaBtn)
		local textos = novo("Frame", {
			Position = UDim2.fromOffset(16, 0),
			Size = UDim2.new(1, -16, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			ZIndex = 33,
		}, linhaBtn)
		est:lista(textos, 2)

		-- 1ª fila: nome e ano à esquerda, lucro em destaque à direita
		local fila = novo("Frame", {
			Name = "Fila",
			LayoutOrder = 1,
			Size = UDim2.new(1, 0, 0, 22),
			BackgroundTransparency = 1,
			ZIndex = 33,
		}, textos)
		local titulo = est:texto("subtitulo", `{linha.nome} <font size="12">· {linha.ano}</font>`, fila, 1)
		titulo.AutomaticSize = Enum.AutomaticSize.None
		titulo.TextWrapped = false
		titulo.TextTruncate = Enum.TextTruncate.AtEnd
		titulo.TextSize = 16
		titulo.ZIndex = 33
		local lucro = if bl then bl.lucro else 0
		local temValor = liberada and construidos > 0
		titulo.Size = UDim2.new(1, if temValor then -96 else 0, 1, 0)
		if temValor then
			local lLucro = est:texto("numero", (if lucro >= 0 then "+" else "−") .. Economia.formatar(math.abs(lucro), simbolo, true) .. "/s", fila, 2)
			lLucro.AutomaticSize = Enum.AutomaticSize.None
			lLucro.AnchorPoint = Vector2.new(1, 0)
			lLucro.Position = UDim2.fromScale(1, 0)
			lLucro.Size = UDim2.new(0, 94, 1, 0)
			lLucro.TextXAlignment = Enum.TextXAlignment.Right
			lLucro.TextWrapped = false
			lLucro.TextSize = 15
			lLucro.TextColor3 = if lucro >= 0 then est.c.positive else est.c.negative
			lLucro.ZIndex = 33
		end
		-- 2ª fila: números curtos com ícones (ou o motivo de estar fechada)
		local info
		if not liberada and linha.projeto then
			info = L(`{Emojis.gabinete} Estude no Gabinete para liberar`, `{Emojis.gabinete} Study it in the Cabinet to unlock`)
		elseif not liberada then
			info = L(`{Emojis.cadeado} Complete antes: {table.concat(Economia.faltaParaLiberar(estado, dados, i), ", ")}`, `{Emojis.cadeado} Finish first: {table.concat(Economia.faltaParaLiberar(estado, dados, i), ", ")}`)
		else
			local partes = { `{Emojis.construir} {construidos}/{#linha.trechos}{if completa then " " .. Emojis.confirmar else ""}` }
			if construidos > 0 then
				table.insert(partes, `{Emojis.trens} {estado.trens[linha.id] or 0}`)
			end
			if bl and bl.rede > 0 then
				table.insert(partes, `{Emojis.conectar} +{math.round((bl.fatorRede - 1) * 100)}%`)
			end
			info = table.concat(partes, "   ")
		end
		local l2 = est:texto("fraco", info, textos, 2)
		l2.TextSize = 13
		l2.ZIndex = 33
		if not liberada then
			l2.TextWrapped = false
			l2.TextTruncate = Enum.TextTruncate.AtEnd
			titulo.TextTransparency = 0.35
		end
		-- 3ª fila: só quando há algo a fazer
		local alerta = if not liberada then nil
			elseif faltando > 0 then L(`{Emojis.alerta} Lotada: faltam {faltando} trem(ns)`, `{Emojis.alerta} Crowded: {faltando} more train(s) needed`)
			elseif sobrando > 0 then L(`{Emojis.alerta} {sobrando} trem(ns) vazio(s)`, `{Emojis.alerta} {sobrando} empty train(s)`)
			else nil
		if alerta then
			local l3 = est:texto("fraco", alerta, textos, 3)
			l3.TextSize = 13
			l3.TextColor3 = est.c.negative
			l3.ZIndex = 33
		end
		linhaBtn.Activated:Connect(function()
			self.aoFocarLinha:Fire(linha.id)
		end)
	end
end

-- ---------------------------------------------------------------- aba Gabinete de Projetos

-- Preço em Robux de cada passe/produto, pedido ao Roblox uma vez por sessão (passe/produto -> preço).
local precosLoja: { [string]: number } = {}
local function precoRoblox(chave: string, id: number, tipo: Enum.InfoType, aoChegar: () -> ())
	if id == 0 or precosLoja[chave] then
		return
	end
	precosLoja[chave] = -1 -- pedindo
	task.spawn(function()
		local ok, info = pcall(function()
			return MarketplaceService:GetProductInfo(id, tipo)
		end)
		if ok and info and type(info.PriceInRobux) == "number" then
			precosLoja[chave] = info.PriceInRobux
			aoChegar()
		else
			precosLoja[chave] = nil
		end
	end)
end

local function textoPreco(chave: string, referencia: number): string
	local p = precosLoja[chave]
	return `{if p and p > 0 then p else referencia} Robux`
end

function Menu._abaProjetos(self: Menu)
	local est, dados, estado, r = self.est, self.dados, self.estado, self.rolagem
	self:_titulo(L(`{Emojis.gabinete} Gabinete de Projetos`, `{Emojis.gabinete} Projects Cabinet`), L("Ferrovias que foram planejadas e nunca terminou e, no fim, planos ousados que ninguém chegou a fazer (os \"E se?\"). Estude um projeto por vez: o estudo leva tempo de verdade (continua com o jogo fechado) e, quando termina, a linha abre no mapa.", "Railways that were planned and never finished and, at the end, bold plans nobody ever tried (the \"What if?\" ones). Study one project at a time: studies take real time (they continue with the game closed) and, when done, the line opens on the map."))
	if not estado then
		return
	end
	local simbolo = dados.simbolo
	local c = est.c

	for i, p in dados.projetos or {} do
		local situacao = Economia.situacaoProjeto(estado, dados, p)
		local linha = nil
		for _, l in dados.linhas do
			if l.id == p.linha then
				linha = l
			end
		end
		local km = 0
		for _, t in (if linha then linha.trechos else {}) do
			km += t.km
		end

		local cartao = novo("Frame", {
			Name = "Projeto_" .. p.id,
			LayoutOrder = 10 + i,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = c.bg,
			ZIndex = 32,
		}, r)
		est:cantos(cartao)
		novo("UIStroke", {
			Color = if situacao == "pesquisando" then c.accent else c.rule,
			Thickness = if situacao == "pesquisando" then 2 else 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}, cartao)
		est:padding(cartao, 10, 8)
		est:lista(cartao, 4)

		local function txt(tipo: any, conteudo: string, ordem: number): TextLabel
			local l = est:texto(tipo, conteudo, cartao, ordem)
			l.ZIndex = 33
			return l
		end
		local emoji = (Emojis :: any)[p.emoji] or Emojis.linhas
		local titulo = txt("subtitulo", `{emoji} {p.nome}`, 1)
		if situacao == "bloqueado" then
			titulo.TextColor3 = c.inkMuted
		end
		txt("rotulo", L(`{if p.ficticio then "E SE? · " else ""}{if linha then #linha.trechos else 0} TRECHOS · {numero(km)} KM`, `{if p.ficticio then "WHAT IF? · " else ""}{if linha then #linha.trechos else 0} SECTIONS · {numero(km)} KM`), 2)
		txt("fraco", Idioma.t(p.descricao), 3)

		if situacao == "concluido" then
			local l = txt("corpo", L(`{Emojis.confirmar} Projeto aprovado: a linha está aberta no mapa.`, `{Emojis.confirmar} Project approved: the line is open on the map.`), 4)
			l.TextColor3 = c.positive
			local b = est:botao("discreto", L(`{Emojis.linhas} Ver no mapa`, `{Emojis.linhas} Show on map`), cartao, 5)
			b.ZIndex = 33
			b.Activated:Connect(function()
				self.aoFocarLinha:Fire(p.linha)
			end)
		elseif situacao == "pesquisando" then
			local barra = est:barra(cartao, 4)
			local lTempo = txt("corpo", "", 5)
			local bAcel = est:botao("secundario", "", cartao, 6)
			bAcel.Name = "BtnAcelerar"
			bAcel.ZIndex = 33
			bAcel.Activated:Connect(function()
				self.aoAgir:Fire("acelerar", { projeto = p.id })
			end)
			local bRobux = est:botao("discreto", "", cartao, 7)
			bRobux.Name = "BtnConcluirRobux"
			bRobux.ZIndex = 33
			bRobux.Visible = false
			bRobux.Activated:Connect(function()
				local id = bRobux:GetAttribute("Produto")
				if type(id) == "number" and id ~= 0 then
					MarketplaceService:PromptProductPurchase(Players.LocalPlayer, id)
				end
			end)
			local function atualizar()
				local e = self.estado
				local _, restante = Economia.pesquisaAtual(e)
				barra.Size = UDim2.fromScale(math.clamp(1 - restante / Economia.duracaoProjeto(e, p), 0, 1), 1)
				lTempo.Text = L(`{Emojis.relogio} Em estudo · faltam <b>{relogio(restante)}</b>`, `{Emojis.relogio} Being studied · <b>{relogio(restante)}</b> left`)
				local custo = Economia.custoAcelerar(p, restante)
				bAcel.Text = L(`{Emojis.velocidade} Acelerar agora · {Economia.formatar(custo, simbolo)}`, `{Emojis.velocidade} Finish now · {Economia.formatar(custo, simbolo)}`)
				est:habilitar(bAcel, e.dinheiro >= custo)
				-- versão em Robux (o preço depende do tempo que falta)
				local prod = Loja.produtoEstudo(restante)
				bRobux.Visible = prod ~= nil and prod.produtoId ~= 0
				if prod and prod.produtoId ~= 0 then
					precoRoblox("produto_" .. prod.id, prod.produtoId, Enum.InfoType.Product, function() end)
					local preco = textoPreco("produto_" .. prod.id, prod.preco)
					bRobux.Text = L(`{Emojis.gabinete} Concluir agora · {preco}`, `{Emojis.gabinete} Finish now · {preco}`)
					bRobux:SetAttribute("Produto", prod.produtoId)
				end
			end
			atualizar()
			table.insert(self.vivos, atualizar)
		elseif situacao == "bloqueado" then
			local _, motivo = Economia.requisitosProjeto(estado, dados, p)
			txt("corpo", `{Emojis.cadeado} {motivo or "Ainda fechado."}`, 4)
			txt("fraco", L(`Estudo: {Economia.formatar(p.custo, simbolo)} · {relogio(Economia.duracaoProjeto(estado, p))}`, `Study: {Economia.formatar(p.custo, simbolo)} · {relogio(Economia.duracaoProjeto(estado, p))}`), 5)
		else
			local b = est:botao("principal", L(`{Emojis.gabinete} Estudar · {Economia.formatar(p.custo, simbolo)} · {relogio(Economia.duracaoProjeto(estado, p))}`, `{Emojis.gabinete} Study · {Economia.formatar(p.custo, simbolo)} · {relogio(Economia.duracaoProjeto(estado, p))}`), cartao, 4)
			b.Name = "BtnEstudar_" .. p.id
			b.ZIndex = 33
			local lMotivo = txt("fraco", "", 5)
			b.Activated:Connect(function()
				self.aoAgir:Fire("pesquisar", { projeto = p.id })
			end)
			local function atualizar()
				local e = self.estado
				local livre = situacao == "disponivel"
				est:habilitar(b, livre and e.dinheiro >= p.custo)
				lMotivo.Text = if not livre then L("O Gabinete já está ocupado com outro estudo.", "The Cabinet is already busy with another study.")
					elseif e.dinheiro < p.custo then L(`Faltam {Economia.formatar(p.custo - e.dinheiro, simbolo)}.`, `{Economia.formatar(p.custo - e.dinheiro, simbolo)} short.`)
					else ""
				lMotivo.Visible = lMotivo.Text ~= ""
			end
			atualizar()
			table.insert(self.vivos, atualizar)
		end
	end
end

-- ---------------------------------------------------------------- aba Contratos (contratos e missões do dia)

local function novoCartao(est: any, pai: Instance, nome: string, ordem: number, destaque: boolean?): (Frame, (any, string, number) -> TextLabel)
	local cartao = est:cartao({
		Name = nome,
		LayoutOrder = ordem,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ZIndex = 32,
	}, pai, destaque)
	est:lista(cartao, 4)
	local function txt(tipo: any, conteudo: string, ordemTxt: number): TextLabel
		local l = est:texto(tipo, conteudo, cartao, ordemTxt)
		l.ZIndex = 33
		return l
	end
	return cartao, txt
end

-- Barra de progresso; devolve a parte cheia (ajuste o Size.X.Scale de 0 a 1).
local function novaBarra(est: any, pai: Instance, ordem: number): Frame
	return est:barra(pai, ordem)
end

function Menu._abaMetas(self: Menu)
	local est, dados, estado, r = self.est, self.dados, self.estado, self.rolagem
	self:_titulo(L(`{Emojis.contratos} Contratos`, `{Emojis.contratos} Contracts`), L("Escolha um contrato por vez. O prazo só corre com o jogo aberto, e não há multa se ele acabar.", "Pick one contract at a time. The deadline only runs while the game is open, and there is no penalty if it runs out."))
	if not estado then
		return
	end
	local simbolo = dados.simbolo
	local c = est.c
	local contrato = estado.contrato
	local ofertas = estado.ofertas or {}

	if contrato then
		local emoji, titulo, dica = Metas.descreverContrato(contrato, dados)
		local dif = Metas.dificuldade(contrato.dificuldade)
		local cartao, txt = novoCartao(est, r, "ContratoAtual", 10, true)
		txt("subtitulo", `{(Emojis :: any)[emoji] or ""} {titulo}`, 1)
		txt("rotulo", L(`{dif.caixaAlta} · PRÊMIO {Economia.formatar(contrato.premio, simbolo)} · +{contrato.xp} XP`, `{dif.caixaAlta} · REWARD {Economia.formatar(contrato.premio, simbolo)} · +{contrato.xp} XP`), 2)
		txt("fraco", dica, 3)
		local cheio = novaBarra(est, cartao, 4)
		local lProg = txt("corpo", "", 5)
		local bDes = est:botao("discreto", L("Desistir do contrato", "Give up the contract"), cartao, 6)
		bDes.Name = "BtnDesistir"
		bDes.ZIndex = 33
		bDes.Size = UDim2.new(1, 0, 0, 34)
		bDes.Activated:Connect(function()
			self.aoAgir:Fire("desistirContrato", {})
		end)
		local function atualizar()
			local atual = self.estado.contrato
			if not atual then
				return
			end
			cheio.Size = UDim2.fromScale(math.clamp(atual.progresso / atual.meta, 0, 1), 1)
			lProg.Text = L(`<b>{Metas.progressoContrato(atual)}</b> · {Emojis.relogio} faltam {relogio(atual.prazo - atual.decorrido)}`, `<b>{Metas.progressoContrato(atual)}</b> · {Emojis.relogio} {relogio(atual.prazo - atual.decorrido)} left`)
		end
		atualizar()
		table.insert(self.vivos, atualizar)
	elseif #ofertas > 0 then
		for i, o in ofertas do
			local emoji, titulo, dica = Metas.descreverContrato(o, dados)
			local dif = Metas.dificuldade(o.dificuldade)
			local cartao, txt = novoCartao(est, r, `Oferta_{i}`, 10 + i)
			txt("subtitulo", `{(Emojis :: any)[emoji] or ""} {titulo}`, 1)
			txt("rotulo", L(`{dif.caixaAlta} · PRAZO {relogio(o.prazo)}`, `{dif.caixaAlta} · DEADLINE {relogio(o.prazo)}`), 2)
			txt("fraco", dica, 3)
			txt("corpo", L(`{Emojis.presente} Prêmio: <b>{Economia.formatar(o.premio, simbolo)}</b> · +{o.xp} XP`, `{Emojis.presente} Reward: <b>{Economia.formatar(o.premio, simbolo)}</b> · +{o.xp} XP`), 4)
			local b = est:botao("principal", L(`{Emojis.assinar} Aceitar contrato`, `{Emojis.assinar} Accept contract`), cartao, 5)
			b.Name = "BtnAceitar"
			b.ZIndex = 33
			b.Size = UDim2.new(1, 0, 0, 38)
			b.Activated:Connect(function()
				self.aoAgir:Fire("aceitarContrato", { id = o.id })
			end)
		end
		local bTroca = est:botao("discreto", "", r, 30)
		bTroca.Name = "BtnTrocarOfertas"
		bTroca.Size = UDim2.new(1, 0, 0, 36)
		bTroca.Activated:Connect(function()
			self.aoAgir:Fire("trocarOfertas", {})
		end)
		local function atualizar()
			local espera = Metas.TROCA_OFERTAS_SEGUNDOS - (Economia.relogio() - (self.estado.ofertasEm or 0))
			if espera > 0 then
				bTroca.Text = L(`{Emojis.auto} Trocar ofertas em {relogio(espera)}`, `{Emojis.auto} New offers in {relogio(espera)}`)
				est:habilitar(bTroca, false)
			else
				bTroca.Text = L(`{Emojis.auto} Trocar ofertas`, `{Emojis.auto} New offers`)
				est:habilitar(bTroca, true)
			end
		end
		atualizar()
		table.insert(self.vivos, atualizar)
	else
		est:texto("fraco", L("Construa os primeiros trechos para começar a receber ofertas de contrato.", "Build your first sections to start getting contract offers."), r, 2)
	end

	-- missões do dia
	est:divisor(r, 40)
	est:texto("subtitulo", L(`{Emojis.alvo} Missões de hoje`, `{Emojis.alvo} Today's missions`), r, 41)
	local missoes = (estado.missoes or {}).lista or {}
	for i, m in missoes do
		local emoji, titulo = Metas.descreverMissao(m, simbolo)
		local pronta = m.progresso >= m.meta
		local cartao, txt = novoCartao(est, r, `Missao_{i}`, 41 + i, pronta and not m.resgatada)
		local lTitulo = txt("corpo", `{(Emojis :: any)[emoji] or ""} <b>{titulo}</b>`, 1)
		if m.resgatada then
			lTitulo.TextColor3 = est:paleta(cartao).inkMuted
			local l = txt("fraco", L(`{Emojis.confirmar} Resgatada`, `{Emojis.confirmar} Claimed`), 2)
			l.TextColor3 = c.positive
		elseif pronta then
			local b = est:botao("principal", L(`{Emojis.presente} Resgatar · {Economia.formatar(m.premio, simbolo)} · +{m.xp} XP`, `{Emojis.presente} Claim · {Economia.formatar(m.premio, simbolo)} · +{m.xp} XP`), cartao, 2)
			b.Name = "BtnResgatar"
			b.ZIndex = 33
			b.Size = UDim2.new(1, 0, 0, 38)
			b.Activated:Connect(function()
				self.aoAgir:Fire("resgatarMissao", { indice = i })
			end)
		else
			local cheio = novaBarra(est, cartao, 2)
			local lProg = txt("fraco", "", 3)
			local function atualizar()
				local atual = ((self.estado.missoes or {}).lista or {})[i]
				if not atual or atual.tipo ~= m.tipo then
					return
				end
				cheio.Size = UDim2.fromScale(math.clamp(atual.progresso / atual.meta, 0, 1), 1)
				lProg.Text = L(`{numero(math.floor(atual.progresso))} de {numero(atual.meta)} · prêmio {Economia.formatar(atual.premio, simbolo)} · +{atual.xp} XP`, `{numero(math.floor(atual.progresso))} of {numero(atual.meta)} · reward {Economia.formatar(atual.premio, simbolo)} · +{atual.xp} XP`)
			end
			atualizar()
			table.insert(self.vivos, atualizar)
		end
	end
	local lVira = est:texto("fraco", "", r, 50)
	local function atualizarVira()
		lVira.Text = L(`Missões novas em {relogio(Metas.segundosAteVirar(Economia.relogio()))}.`, `New missions in {relogio(Metas.segundosAteVirar(Economia.relogio()))}.`)
	end
	atualizarVira()
	table.insert(self.vivos, atualizarVira)
end

-- ---------------------------------------------------------------- aba Jornal

-- Notícia nova chegou (o init avisa): bolinha na aba se ela não estiver aberta.
function Menu.marcarJornal(self: Menu)
	if self.aba ~= "jornal" then
		self.avisoJornal = true
	end
	self:_rotularAbas()
end

-- Texto curto do efeito: "+60% · linhas do café", "manutenção +60%"...
local function efeitoEvento(ev: any, dados: any): string
	local pct = math.round((ev.mult - 1) * 100)
	local sinal = if pct > 0 then "+" else "−"
	local valor = `{sinal}{math.abs(pct)}%`
	local nome = Jornal.nomeAlvo(ev, dados, Idioma.atual)
	if ev.tipo == "geral" then
		return L(`{valor} em toda a receita`, `{valor} on all income`)
	elseif ev.tipo == "manutencao" then
		return L(`manutenção {valor}`, `upkeep {valor}`)
	elseif ev.tipo == "linha" then
		return L(`{valor} na linha {nome}`, `{valor} on the {nome} line`)
	elseif ev.tipo == "carga" then
		return L(`{valor} nas linhas que levam {string.lower(nome)}`, `{valor} on lines carrying {string.lower(nome)}`)
	elseif ev.tipo == "cidade" then
		return L(`{valor} nas linhas de {nome}`, `{valor} on lines in {nome}`)
	elseif ev.tipo == "regiao" then
		return L(`{valor} nas linhas do {nome}`, `{valor} on lines in the {nome}`)
	end
	return valor
end

local function ha(segundos: number): string
	local m = math.floor(segundos / 60)
	if m < 1 then
		return L("agora há pouco", "just now")
	elseif m < 60 then
		return L(`há {m} min`, `{m} min ago`)
	end
	local h = math.floor(m / 60)
	if h < 24 then
		return L(`há {h} h`, `{h} h ago`)
	end
	return L(`há {math.floor(h / 24)} dia(s)`, `{math.floor(h / 24)} day(s) ago`)
end

-- Foto da notícia: a cidade do alvo (ou uma da rede ligada a ele); sem cidade, a maior da rede.
local function fotoEvento(ev: any, estado: any, dados: any): (string?, string?)
	local function imagem(id: string): string?
		return Assets.imagemFicha(id, estado.era, dados.estacoes[id])
	end
	local candidatas: { string } = {}
	if ev.tipo == "cidade" and ev.alvo and dados.estacoes[ev.alvo] then
		table.insert(candidatas, ev.alvo)
	elseif ev.tipo == "linha" then
		for _, linha in dados.linhas do
			if linha.id == ev.alvo then
				for _, t in linha.trechos do
					table.insert(candidatas, t.para)
					table.insert(candidatas, t.de)
				end
			end
		end
	else
		for id, e in dados.estacoes do
			local combina = (ev.tipo == "carga" and e.produz == ev.alvo) or (ev.tipo == "regiao" and e.regiao == ev.alvo)
				or (ev.tipo ~= "carga" and ev.tipo ~= "regiao")
			if combina and Economia.estacaoNaRede(estado, dados, id) then
				table.insert(candidatas, id)
			end
		end
	end
	-- a maior cidade com imagem própria primeiro
	table.sort(candidatas, function(a, b)
		local pa, pb = dados.estacoes[a].porte, dados.estacoes[b].porte
		local ia, ib = imagem(a) ~= nil, imagem(b) ~= nil
		if ia ~= ib then
			return ia
		end
		return pa > pb
	end)
	for _, id in candidatas do
		local img = imagem(id)
		if img then
			return img, dados.estacoes[id].nome
		end
	end
	-- sem foto desta época para nenhuma cidade da notícia: a maior cidade do mapa que tenha uma
	local melhor: string? = nil
	for id, e in dados.estacoes do
		if imagem(id) and (not melhor or e.porte > dados.estacoes[melhor].porte) then
			melhor = id
		end
	end
	if melhor then
		return imagem(melhor), dados.estacoes[melhor].nome
	end
	return nil, nil -- nos EUA ainda não há imagens das cidades
end

local PRECO_JORNAL = { vapor = "100 réis", diesel = "1 cruzeiro", eletrico = "Cr$ 2", alta = L("grátis", "free") }
local PRECO_JORNAL_EUA = { vapor = "5 cents", diesel = "10 cents", eletrico = "25 cents", alta = L("grátis", "free") }
local PRECO_JORNAL_EUROPA = { vapor = "1 penny", diesel = "2 pence", eletrico = "50 centimes", alta = L("grátis", "free") }
local CIDADE_JORNAL = { brasil = "Rio de Janeiro", eua = "New York", europa = L("Londres", "London") }
local MESES_JORNAL_EN = { "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December" }
local MESES_JORNAL = { "janeiro", "fevereiro", "março", "abril", "maio", "junho", "julho", "agosto", "setembro", "outubro", "novembro", "dezembro" }
local PAPEL = Color3.fromRGB(238, 228, 204) -- papel de jornal
local TINTA = Color3.fromRGB(38, 30, 22)
local TINTA_FRACA = Color3.fromRGB(96, 82, 64)

-- Aba Jornal: uma página de jornal da época (manchete com foto, outras notícias em colunas,
-- notas da diretoria, movimento da companhia e edições anteriores).
function Menu._abaJornal(self: Menu)
	local est, dados, estado, r = self.est, self.dados, self.estado, self.rolagem
	local eraId = if estado then estado.era else "vapor"
	local nomeJornal = Idioma.t(Jornal.nome(eraId, self.dados.id))
	local f = est.f
	local gotica = Font.new("rbxasset://fonts/families/GrenzeGotisch.json", Enum.FontWeight.Bold)
	local italico = Font.new(f.body.Family, Enum.FontWeight.Regular, Enum.FontStyle.Italic)

	local folha = novo("Frame", {
		Name = "Folha",
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = PAPEL,
		BorderSizePixel = 0,
		ZIndex = 32,
	}, r)
	novo("UIStroke", { Color = TINTA_FRACA, Thickness = 1 }, folha)
	novo("UIPadding", {
		PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16),
		PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 16),
	}, folha)
	novo("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) }, folha)

	local function t(pai: Instance, ordem: number, txt: string, fonte: Font, tam: number, cor: Color3?, centro: boolean?): TextLabel
		return novo("TextLabel", {
			LayoutOrder = ordem,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Text = txt,
			RichText = true,
			TextWrapped = true,
			FontFace = fonte,
			TextSize = tam,
			TextColor3 = cor or TINTA,
			TextXAlignment = if centro then Enum.TextXAlignment.Center else Enum.TextXAlignment.Left,
			ZIndex = 33,
		}, pai)
	end
	local function fio(pai: Instance, ordem: number, grossura: number, duplo: boolean?)
		local fr = novo("Frame", {
			LayoutOrder = ordem,
			Size = UDim2.new(1, 0, 0, if duplo then grossura + 4 else grossura),
			BackgroundTransparency = 1,
			ZIndex = 33,
		}, pai)
		novo("Frame", { Size = UDim2.new(1, 0, 0, grossura), BackgroundColor3 = TINTA, BorderSizePixel = 0, ZIndex = 33 }, fr)
		if duplo then
			novo("Frame", { Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = TINTA, BorderSizePixel = 0, ZIndex = 33 }, fr)
		end
	end
	local function colunas(pai: Instance, ordem: number): Frame
		local fr = novo("Frame", {
			LayoutOrder = ordem,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			ZIndex = 33,
		}, pai)
		novo("UIGridLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			CellSize = UDim2.new(0.5, -8, 0, 0),
			CellPadding = UDim2.fromOffset(16, 10),
			FillDirectionMaxCells = 2,
		}, fr)
		return fr
	end
	-- célula de coluna: o grid não cresce com o conteúdo, então cada coluna mede o próprio texto
	local function materia(pai: Instance, ordem: number): Frame
		local fr = novo("Frame", {
			LayoutOrder = ordem,
			BackgroundTransparency = 1,
			ZIndex = 33,
		}, pai)
		local lista = novo("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 3) }, fr)
		local function medir()
			local grid = pai:FindFirstChildOfClass("UIGridLayout")
			if not grid then
				return
			end
			local maior = 0
			for _, irma in pai:GetChildren() do
				local l = irma:FindFirstChildOfClass("UIListLayout")
				if irma:IsA("Frame") and l then
					maior = math.max(maior, l.AbsoluteContentSize.Y)
				end
			end
			grid.CellSize = UDim2.new(0.5, -8, 0, maior)
		end
		lista:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(medir)
		task.defer(medir)
		return fr
	end

	-- cabeçalho
	t(folha, 1, nomeJornal, gotica, 40, TINTA, true)
	fio(folha, 2, 2, true)
	local linhaData = novo("Frame", { LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, ZIndex = 33 }, folha)
	local edicoes = if estado then (estado.jornal or {}).edicoes or {} else {}
	local dia = math.floor(workspace:GetServerTimeNow() / Metas.SEGUNDOS_POR_DIA)
	local data = if estado
		then L(`{dia % 30 + 1} de {MESES_JORNAL[(dia // 30) % 12 + 1]} de {Economia.anoAtual(estado, dados)}`, `{MESES_JORNAL_EN[(dia // 30) % 12 + 1]} {dia % 30 + 1}, {Economia.anoAtual(estado, dados)}`)
		else ""
	local function linha(txt: string, alinh: Enum.TextXAlignment)
		novo("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = txt,
			FontFace = f.label,
			TextSize = 11,
			TextColor3 = TINTA,
			TextXAlignment = alinh,
			ZIndex = 33,
		}, linhaData)
	end
	linha(CIDADE_JORNAL[self.dados.id or "brasil"] or "Rio de Janeiro", Enum.TextXAlignment.Left)
	linha(data, Enum.TextXAlignment.Center)
	linha(`Nº {#edicoes + 1} · {(if self.dados.id == "eua" then PRECO_JORNAL_EUA elseif self.dados.id == "europa" then PRECO_JORNAL_EUROPA else PRECO_JORNAL)[eraId] or ""}`, Enum.TextXAlignment.Right)
	fio(folha, 4, 1)
	if not estado then
		return
	end
	local simbolo = dados.simbolo
	local c = est.c
	local ativos = Economia.eventosAtivos(estado)

	-- relógio e botão de resolver de uma notícia
	local function prazo(pai: Instance, ordem: number, ev: any)
		local def = Jornal.acharEvento(ev.id)
		local lTempo = t(pai, ordem, "", italico, 11, TINTA_FRACA)
		local bResolver: TextButton? = nil
		if def and def.resolvivel then
			local b = est:botao("principal", "", pai, ordem + 1)
			b.Name = "BtnResolver"
			b.ZIndex = 34
			b.Size = UDim2.new(1, 0, 0, 34)
			b.TextSize = 14
			b.Activated:Connect(function()
				self.aoAgir:Fire("resolverEvento", { id = ev.id })
			end)
			bResolver = b
		end
		local function atualizar()
			local resta = math.max(0, ev.fim - Economia.relogio())
			lTempo.Text = L(`{Emojis.relogio} vale por mais {relogio(resta)}`, `{Emojis.relogio} lasts {relogio(resta)} more`)
			if bResolver then
				local custo = Jornal.custoResolver(self.estado.renda or 0)
				bResolver.Text = L(`Resolver agora · {Economia.formatar(custo, simbolo)}`, `Solve now · {Economia.formatar(custo, simbolo)}`)
				est:habilitar(bResolver, self.estado.dinheiro >= custo)
			end
		end
		atualizar()
		table.insert(self.vivos, atualizar)
	end

	-- manchete: a notícia mais nova, com foto
	local principal = ativos[#ativos]
	if principal then
		local titulo, texto = Jornal.textos(principal, dados, Idioma.atual)
		local bom = principal.mult > 1 and principal.tipo ~= "manutencao"
		t(folha, 10, Idioma.maiusculas(titulo), f.display, 24, TINTA, true)
		t(folha, 11, efeitoEvento(principal, dados), italico, 14, if bom then c.positive else c.negative, true)
		local img, cidade = fotoEvento(principal, estado, dados)
		if img then
			local foto = novo("Frame", {
				Name = "Foto",
				LayoutOrder = 12,
				-- altura fixa (a proporção automática não funciona dentro da lista)
				Size = UDim2.new(1, 0, 0, 240),
				BackgroundColor3 = TINTA,
				BorderSizePixel = 0,
				ZIndex = 33,
			}, folha)
			novo("ImageLabel", {
				Position = UDim2.fromOffset(2, 2),
				Size = UDim2.new(1, -4, 1, -4),
				BackgroundTransparency = 1,
				Image = img,
				ImageColor3 = Color3.fromRGB(226, 196, 150), -- tom sépia de foto antiga
				ScaleType = Enum.ScaleType.Crop,
				ZIndex = 34,
			}, foto)
			if cidade then
				t(folha, 13, L(`Vista de {cidade}. Gravura da redação.`, `View of {cidade}. Newsroom engraving.`), italico, 11, TINTA_FRACA, true)
			end
		end
		t(folha, 14, texto, f.body, 14, TINTA)
		prazo(folha, 15, principal)
	else
		t(folha, 10, L("CALMARIA NOS TRILHOS", "ALL QUIET ON THE TRACKS"), f.display, 24, TINTA, true)
		t(folha, 11, L("Nada de extraordinário nas notícias de hoje. Os trens correm no horário e o comércio segue seu curso.", "Nothing out of the ordinary in today's news. Trains run on time and trade goes on as usual."), italico, 14, TINTA_FRACA, true)
	end

	-- outras notícias, em duas colunas
	if #ativos > 1 then
		fio(folha, 20, 1)
		local grade = colunas(folha, 21)
		for i = #ativos - 1, 1, -1 do
			local ev = ativos[i]
			local titulo, texto = Jornal.textos(ev, dados, Idioma.atual)
			local bom = ev.mult > 1 and ev.tipo ~= "manutencao"
			local m = materia(grade, #ativos - i)
			t(m, 1, titulo, f.display, 15, TINTA)
			t(m, 2, efeitoEvento(ev, dados), italico, 12, if bom then c.positive else c.negative)
			t(m, 3, texto, f.body, 12, TINTA)
			prazo(m, 4, ev)
		end
	end

	-- colunas fixas: notas da diretoria (decisões) e movimento da companhia
	fio(folha, 30, 1)
	local fixas = colunas(folha, 31)
	local mov = materia(fixas, 1)
	t(mov, 1, L("Movimento da Companhia", "Company Report"), f.display, 15, TINTA)
	local lMov = t(mov, 2, "", f.body, 12, TINTA)
	local function atualizarMovimento()
		local b = Economia.balanco(self.estado, dados)
		local carga = 0
		for _, v in Economia.cargaPorDia(self.estado, dados, b) do
			carga += v
		end
		local nome = self.estado.nomeCompanhia or Idioma.T("companhia_padrao")
		lMov.Text = L(`A {nome} levou ontem <b>{numero(Economia.passageirosPorDia(b))}</b> passageiros`, `Yesterday {nome} carried <b>{numero(Economia.passageirosPorDia(b))}</b> passengers`)
			.. (if carga > 0 then L(` e <b>{numero(carga)}</b> unidades de carga`, ` and <b>{numero(carga)}</b> units of cargo`) else "")
			.. L(`. Em caixa, {Economia.formatar(self.estado.dinheiro, simbolo)}; a satisfação dos viajantes está em {math.round(b.satisfacao * 100)}%.`, `. Cash on hand: {Economia.formatar(self.estado.dinheiro, simbolo)}; passenger satisfaction stands at {math.round(b.satisfacao * 100)}%.`)
	end
	atualizarMovimento()
	table.insert(self.vivos, atualizarMovimento)
	local notas = materia(fixas, 2)
	t(notas, 1, L("Notas da Diretoria", "Board Notices"), f.display, 15, TINTA)
	local efeitos = Economia.efeitosDecisoes(estado)
	if #efeitos == 0 then
		t(notas, 2, L("A diretoria não tem comunicados em vigor.", "The board has no notices in force."), italico, 12, TINTA_FRACA)
	end
	for i, ev in efeitos do
		local def = Decisoes.acharDecisao(ev.id)
		local nome = if def then (Decisoes.textos(def, ev.tipo, ev.alvo, dados, Idioma.atual)) else ev.id
		local bom = (ev.mult > 1) ~= (ev.tipo == "manutencao")
		local l = t(notas, 1 + i, "", f.body, 12, if bom then c.positive else c.negative)
		local function atualizar()
			l.Text = `<b>{efeitoEvento(ev, dados)}</b> · {nome} · {relogio(math.max(0, ev.fim - Economia.relogio()))}`
		end
		atualizar()
		table.insert(self.vivos, atualizar)
	end

	-- edições anteriores
	if #edicoes > 0 then
		fio(folha, 40, 1)
		t(folha, 41, L("Edições anteriores", "Past editions"), f.display, 14, TINTA, true)
		local grade = colunas(folha, 42)
		local agora = Economia.relogio()
		for i, ed in edicoes do
			local ev = { id = ed.id, alvo = ed.alvo, tipo = ((Jornal.acharEvento(ed.id) :: any) or {}).tipo or "" }
			local titulo = Jornal.textos(ev, dados, Idioma.atual)
			local m = materia(grade, i)
			t(m, 1, `<b>{titulo}</b>`, f.body, 12, TINTA)
			t(m, 2, ha(agora - ed.em), italico, 11, TINTA_FRACA)
		end
	end
end

-- ---------------------------------------------------------------- aba Tarifas

local function pct(x: number): string
	return `{math.round(x * 100)}%`
end

local function sinal(x: number): string
	local n = math.round(x)
	return if n > 0 then `+{n}` elseif n < 0 then `−{-n}` else "0"
end

function Menu._abaTarifas(self: Menu)
	local est, dados, estado, r = self.est, self.dados, self.estado, self.rolagem
	self:_titulo(L(`{Emojis.tarifas} Tarifas`, `{Emojis.tarifas} Fares`), L("O preço da passagem de cada classe vale para todas as linhas. Mais caro rende mais por passageiro, mas afasta gente; caro demais irrita quem viaja. O serviço de bordo deixa cada classe aceitar pagar mais.", "Each class's ticket price applies to every line. Pricier tickets earn more per passenger but drive people away; too pricey annoys travellers. Onboard service makes each class willing to pay more."))
	if not estado then
		return
	end
	local simbolo = dados.simbolo
	local era = Economia.indiceEra(estado)
	local tf = estado.tarifas or Tarifas.padrao()
	local mistura = Economia.misturaRede(estado, dados)
	local tol = Tarifas.tolerancia(tf, era)

	-- resumo
	local resumo, txtR = novoCartao(est, r, "ResumoTarifas", 3, true)
	local _ = resumo
	local fp, fr = Tarifas.fatores(tf, mistura, era, tol)
	local ajuste = Tarifas.ajusteSatisfacao(tf, mistura, era) * 100
	txtR("subtitulo", L(`Receita das passagens: {pct(fr)} do normal`, `Ticket income: {pct(fr)} of normal`), 1)
	txtR("corpo", L(`Passageiros: {pct(fp)} · satisfação {sinal(ajuste)} pontos`, `Passengers: {pct(fp)} · satisfaction {sinal(ajuste)} points`), 2)
	local lCusto = txtR("fraco", "", 3)
	local function atualizarCusto()
		local custo = Tarifas.custoServicos(self.estado.tarifas, era) * Economia.manutencaoTrens(self.estado, dados)
		lCusto.Text = if custo > 0
			then L(`Serviço de bordo custa {Economia.formatar(custo, simbolo, true)} por segundo.`, `Onboard service costs {Economia.formatar(custo, simbolo, true)} per second.`)
			else L("Nenhum serviço de bordo contratado.", "No onboard service hired.")
	end
	atualizarCusto()
	table.insert(self.vivos, atualizarCusto)

	-- preço por classe
	est:texto("subtitulo", L("Preço das passagens", "Ticket prices"), r, 10)
	for c = 1, Tarifas.CLASSES do
		local p = tf.precos[c] or 1
		local cartao, txt = novoCartao(est, r, `Classe_{c}`, 10 + c)
		txt("subtitulo", L(`{Tarifas.nomeClasse(c, era, Idioma.atual)} · {pct(mistura[c])} dos passageiros`, `{Tarifas.nomeClasse(c, era, Idioma.atual)} · {pct(mistura[c])} of passengers`), 1)
		local fileira = novo("Frame", {
			Name = "Preco",
			LayoutOrder = 2,
			Size = UDim2.new(1, 0, 0, 38),
			BackgroundTransparency = 1,
			ZIndex = 33,
		}, cartao)
		local menos = est:botao("secundario", "−", fileira, 1)
		menos.Name = "Menos"
		menos.Size = UDim2.fromOffset(46, 38)
		menos.ZIndex = 34
		local mais = est:botao("secundario", "+", fileira, 3)
		mais.Name = "Mais"
		mais.AnchorPoint = Vector2.new(1, 0)
		mais.Position = UDim2.fromScale(1, 0)
		mais.Size = UDim2.fromOffset(46, 38)
		mais.ZIndex = 34
		local valor = est:texto("numero", pct(p), fileira, 2)
		valor.Size = UDim2.new(1, -104, 1, 0)
		valor.Position = UDim2.fromOffset(52, 0)
		valor.AutomaticSize = Enum.AutomaticSize.None
		valor.TextXAlignment = Enum.TextXAlignment.Center
		valor.TextYAlignment = Enum.TextYAlignment.Center
		valor.TextSize = 22
		valor.ZIndex = 34
		est:habilitar(menos, p > Tarifas.MIN + 1e-6)
		est:habilitar(mais, p < Tarifas.MAX - 1e-6)
		menos.Activated:Connect(function()
			self.aoAgir:Fire("definirTarifa", { classe = c, preco = p - Tarifas.PASSO })
		end)
		mais.Activated:Connect(function()
			self.aoAgir:Fire("definirTarifa", { classe = c, preco = p + Tarifas.PASSO })
		end)
		local d = Tarifas.demanda(c, p, tol[c])
		local otimo = Tarifas.precoOtimo(c, tol[c])
		txt("fraco", L(`Procura {pct(d)} · cada assento rende {pct(p * d)} · o melhor fica perto de {pct(otimo)}`, `Demand {pct(d)} · each seat earns {pct(p * d)} · best is around {pct(otimo)}`), 3)
		local justo = Tarifas.JUSTO[c] + 0.8 * tol[c]
		if p > justo + 1e-6 then
			local aviso = txt("fraco", L(`{Emojis.alerta} Acima de {pct(justo)} os passageiros reclamam: a satisfação cai.`, `{Emojis.alerta} Above {pct(justo)} passengers complain: satisfaction drops.`), 4)
			aviso.TextColor3 = est.c.negative
		elseif p < 1 - 1e-6 then
			txt("fraco", L(`{Emojis.satisfacao} Passagem popular: rende menos, mas a satisfação sobe.`, `{Emojis.satisfacao} Cheap ticket: earns less, but satisfaction rises.`), 4)
		end
	end

	-- serviço de bordo
	est:divisor(r, 20)
	est:texto("subtitulo", L("Serviço de bordo", "Onboard service"), r, 21)
	local manutTrens = Economia.manutencaoTrens(estado, dados)
	local futuros: { string } = {}
	local ordem = 22
	for _, sv in Tarifas.SERVICOS do
		if sv.era > era then
			table.insert(futuros, Idioma.t(sv.nome))
			continue
		end
		local ativo = tf.servicos[sv.id] == true
		local cartao, txt = novoCartao(est, r, `Servico_{sv.id}`, ordem, ativo)
		ordem += 1
		txt("subtitulo", `{(Emojis :: any)[sv.emoji] or ""} {Idioma.t(sv.nome)}`, 1)
		txt("fraco", Idioma.t(sv.desc), 2)
		local efeitos: { string } = {}
		for c = 1, Tarifas.CLASSES do
			if sv.tol[c] > 0 then
				table.insert(efeitos, L(`{Tarifas.nomeClasse(c, era, Idioma.atual)} aceita +{pct(sv.tol[c])}`, `{Tarifas.nomeClasse(c, era, Idioma.atual)} accepts +{pct(sv.tol[c])}`))
			end
		end
		table.insert(efeitos, L(`satisfação +{math.round(sv.sat * 100)}`, `satisfaction +{math.round(sv.sat * 100)}`))
		txt("corpo", table.concat(efeitos, " · "), 3)
		txt("fraco", L(`Custo: {Economia.formatar(sv.custo * manutTrens, simbolo, true)}/s ({pct(sv.custo)} da manutenção dos trens)`, `Cost: {Economia.formatar(sv.custo * manutTrens, simbolo, true)}/s ({pct(sv.custo)} of train upkeep)`), 4)
		local b = est:botao(if ativo then "secundario" else "principal", if ativo then L("Dispensar", "Dismiss") else L("Contratar", "Hire"), cartao, 5)
		b.Name = "BtnServico"
		b.Size = UDim2.new(1, 0, 0, 36)
		b.ZIndex = 33
		b.Activated:Connect(function()
			self.aoAgir:Fire("alternarServico", { id = sv.id })
		end)
	end
	if #futuros > 0 then
		est:texto("fraco", L(`Nas próximas eras: {table.concat(futuros, ", ")}.`, `In later eras: {table.concat(futuros, ", ")}.`), r, ordem)
	end
end

-- ---------------------------------------------------------------- aba Companhia

function Menu._abaCompanhia(self: Menu)
	local est, dados, estado, r = self.est, self.dados, self.estado, self.rolagem
	if self.verConquistas and estado then
		self:_conquistas()
		return
	end
	est:titulo(L(`{Emojis.companhia} Companhia`, `{Emojis.companhia} Company`), r, 1)
	if not estado then
		return
	end
	local st = Economia.estatisticas(estado, dados)
	local simbolo = dados.simbolo
	local function numero(n: number): string
		return (Economia.formatar(n, "", false):gsub("^%s+", ""))
	end
	local era = self.est.era
	est:texto("rotulo", Idioma.maiusculas(era.nome) .. " · " .. Economia.anoAtual(estado, self.dados), r, 2)

	-- nível da companhia
	local nivel, xpNoNivel, xpDoNivel = Economia.nivel(estado)
	est:texto("subtitulo", `{Emojis.nivel} {Idioma.T("nivel_titulo", nivel, Economia.tituloNivel(nivel, estado.era, Idioma.atual))}`, r, 3)
	local cheioXp = novaBarra(est, r, 4)
	cheioXp.Size = UDim2.fromScale(if xpDoNivel > 0 then math.clamp(xpNoNivel / xpDoNivel, 0, 1) else 1, 1)
	local bonus = math.round((Economia.fatorNivel(estado) - 1) * 100)
	est:texto(
		"fraco",
		(if xpDoNivel > 0 then L(`{numero(xpNoNivel)} de {numero(xpDoNivel)} XP para o próximo nível`, `{numero(xpNoNivel)} of {numero(xpDoNivel)} XP to the next level`) else L("Nível máximo", "Top level"))
			.. L(` · bônus de receita: +{bonus}%. Ganhe XP construindo, cumprindo contratos e missões e ganhando medalhas.`, ` · income bonus: +{bonus}%. Earn XP by building, completing contracts and missions, and winning medals.`),
		r,
		5
	)
	self:_resumoConquistas(6)

	local sat = math.round(st.satisfacao * 100)
	est:texto("subtitulo", L(`{Emojis.satisfacao} Satisfação: {sat}%`, `{Emojis.satisfacao} Satisfaction: {sat}%`), r, 7)
	local cheioSat = est:barra(r, 8)
	cheioSat.Size = UDim2.fromScale(st.satisfacao, 1)
	cheioSat.BackgroundColor3 = if sat >= 70 then est.c.positive elseif sat >= 40 then est.c.accent else est.c.negative
	est:texto("fraco", `Vem dos passageiros que conseguem embarcar (trens suficientes) e do nível das estações. Hoje mexe {(function()
		local pct = math.round((Economia.fatorSatisfacao(estado, dados) - 1) * 100)
		return if pct > 0 then `+{pct}` else tostring(math.abs(pct) == 0 and 0 or pct)
	end)()}% na renda.`, r, 9)
	est:divisor(r, 10)

	local linhas = {
		L(`{Emojis.renda} Receita: <b>{Economia.formatar(st.receita, simbolo, true)}/s</b>`, `{Emojis.renda} Income: <b>{Economia.formatar(st.receita, simbolo, true)}/s</b>`),
		L(`{Emojis.manutencao} Manutenção: <b>− {Economia.formatar(st.manutencao, simbolo, true)}/s</b>`, `{Emojis.manutencao} Upkeep: <b>− {Economia.formatar(st.manutencao, simbolo, true)}/s</b>`),
		if st.renda >= 0 then L(`{Emojis.dinheiro} Lucro: <b>{Economia.formatar(st.renda, simbolo, true)}/s</b>`, `{Emojis.dinheiro} Profit: <b>{Economia.formatar(st.renda, simbolo, true)}/s</b>`)
			else L(`{Emojis.alerta} Prejuízo: <b>{Economia.formatar(-st.renda, simbolo, true)}/s</b>`, `{Emojis.alerta} Loss: <b>{Economia.formatar(-st.renda, simbolo, true)}/s</b>`),
		L(`{Emojis.trens} Trens: <b>{st.trens}</b>`, `{Emojis.trens} Trains: <b>{st.trens}</b>`),
		L(`{Emojis.passageiros} Passageiros: <b>{numero(st.passageirosDia)}</b> por dia`, `{Emojis.passageiros} Passengers: <b>{numero(st.passageirosDia)}</b> per day`),
		L(`{Emojis.linhas} Trechos: <b>{st.trechos}</b> de {st.trechosTotal}`, `{Emojis.linhas} Sections: <b>{st.trechos}</b> of {st.trechosTotal}`),
		L(`{Emojis.confirmar} Linhas completas: <b>{st.linhasCompletas}</b> de {st.linhasTotal}`, `{Emojis.confirmar} Complete lines: <b>{st.linhasCompletas}</b> of {st.linhasTotal}`),
		L(`{Emojis.estacoes} Estações na rede: <b>{st.estacoes}</b>`, `{Emojis.estacoes} Stations on the network: <b>{st.estacoes}</b>`),
		L(`{Emojis.contratos} Contratos cumpridos: <b>{(estado.contadores or {}).contratos or 0}</b>`, `{Emojis.contratos} Contracts completed: <b>{(estado.contadores or {}).contratos or 0}</b>`),
		L(`{Emojis.carga_passageiros} Passageiros desde a fundação: <b>{numero(math.floor((estado.contadores or {}).passageiros or 0))}</b>`, `{Emojis.carga_passageiros} Passengers since founding: <b>{numero(math.floor((estado.contadores or {}).passageiros or 0))}</b>`),
	}
	for i, txt in linhas do
		est:texto("corpo", txt, r, 10 + i)
	end

	-- cargas: quanto chega ao porto, o frete pago por unidade e quanto rende por dia
	est:divisor(r, 24)
	est:texto("subtitulo", L(`{Emojis.cargas} Cargas e fretes`, `{Emojis.cargas} Cargo and freight`), r, 25)
	local temCarga = false
	-- as cargas ficam num contêiner próprio: são muitas (13 tipos) e não podem invadir a seção seguinte
	local listaCargas = novo("Frame", {
		Name = "Cargas",
		LayoutOrder = 26,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ZIndex = 31,
	}, r)
	est:lista(listaCargas, 6)
	for i, id in Economia.ORDEM_CARGAS do
		local v = st.cargaValor[id]
		if v and v.unidadesDia > 0 then
			temCarga = true
			local carga = (Economia.CARGAS :: any)[id]
			local unidade = carga.unidade:gsub("s$", "") -- "sacas" -> "saca"; "t" e "cabeças" -> "cabeça"
			est:texto("corpo", L(`{(Emojis :: any)[carga.emoji] or ""} {carga.nome}: <b>{numero(math.round(v.unidadesDia))}</b> {carga.unidade}/dia · `
				.. `<b>{Economia.formatar(v.preco, simbolo, true)}</b> por {unidade} · <b>{Economia.formatar(v.reaisDia, simbolo)}</b>/dia`,
				`{(Emojis :: any)[carga.emoji] or ""} {carga.nome}: <b>{numero(math.round(v.unidadesDia))}</b> {carga.unidade}/day · `
				.. `<b>{Economia.formatar(v.preco, simbolo, true)}</b> per {unidade} · <b>{Economia.formatar(v.reaisDia, simbolo)}</b>/day`), listaCargas, i)
		end
	end
	if not temCarga then
		est:texto("fraco", L("Nenhuma carga chega a um porto ainda. Ligue uma cidade produtora (café, minério…) a um porto pelos trilhos: o frete entra na renda da linha.", "No cargo reaches a port yet. Link a producing city (coffee, ore…) to a port by rail: the freight adds to the line's income."), listaCargas, 1)
	end

	-- nome da companhia
	est:divisor(r, 30)
	local lNome = est:texto("rotulo", Idioma.T("companhia_nome"), r, 31)
	lNome.TextSize = 12
	local caixaNome = novo("TextBox", {
		Name = "CampoNome",
		LayoutOrder = 32,
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundColor3 = est.c.bg,
		ClearTextOnFocus = false,
		Text = estado.nomeCompanhia or "",
		PlaceholderText = Idioma.T("companhia_padrao"),
		PlaceholderColor3 = est.c.inkMuted,
		FontFace = est.f.body,
		TextSize = 16,
		TextColor3 = est.c.ink,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 32,
	}, r)
	novo("UIStroke", { Color = est.c.rule, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, caixaNome)
	novo("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, caixaNome)
	est:cantos(caixaNome)
	local bNome = est:botao("secundario", Idioma.T("companhia_salvar"), r, 33)
	bNome.Name = "BtnRenomear"
	bNome.Size = UDim2.new(1, 0, 0, 36)
	bNome.Activated:Connect(function()
		self.aoAgir:Fire("renomear", { nome = caixaNome.Text })
	end)
	est:texto("fraco", Idioma.T("companhia_dica_nome"), r, 34)
end

-- ---------------------------------------------------------------- conquistas (medalhas)

-- Grupos da galeria, na ordem em que aparecem. Medalha que não está em nenhum grupo vai para "Outras".
local GRUPOS_CONQUISTAS = {
	{ nome = { pt = "Primeiros passos", en = "First steps" }, ids = { "primeiro_apito", "linha_inaugurada", "frota_10", "do_papel_ao_trilho" } },
	{ nome = { pt = "Cargas", en = "Cargo" }, ids = { "cafe_no_porto", "carvao_no_porto", "minerio_no_porto", "graos_no_porto" } },
	{ nome = { pt = "Operação", en = "Operations" }, ids = { "ninguem_na_plataforma", "passageiros_felizes", "grande_estacao", "malha_integrada" } },
	{ nome = { pt = "Negócios", en = "Business" }, ids = { "palavra_cumprida", "primeiro_milhao" } },
	{ nome = { pt = "Eras", en = "Eras" }, ids = { "adeus_vapor", "fio_no_trilho", "bala_de_prata" } },
	{ nome = { pt = "Grandes obras", en = "Great works" }, ids = { "obra_entregue", "sonhador" } },
	{ nome = { pt = "Mapa completo", en = "Map complete" }, ids = { "pais_nos_trilhos", "eua_completo", "europa_completo" } },
}


-- Medalhão redondo com o emoji: colorido quando ganho, apagado com cadeado quando não.
local function medalhaoConquista(est: any, pai: Instance, emoji: string, ganha: boolean, tamanho: number, ordem: number?): Frame
	local c = est:paleta(pai)
	local fr = novo("Frame", {
		Name = "Medalhao",
		LayoutOrder = ordem or 0,
		Size = UDim2.fromOffset(tamanho, tamanho),
		BackgroundColor3 = if ganha then Color3.new(1, 1, 1) else c.rule,
		BackgroundTransparency = if ganha then 0 else 0.55,
		ZIndex = 34,
	}, pai) :: Frame
	novo("UICorner", { CornerRadius = UDim.new(1, 0) }, fr)
	if ganha then
		-- medalha de ouro: dourado claro em cima, mais escuro embaixo, com aro de ouro velho
		novo("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new(Color3.fromRGB(250, 232, 170), Color3.fromRGB(205, 158, 64)),
		}, fr)
		novo("UIStroke", { Color = Color3.fromRGB(140, 100, 32), Thickness = 2 }, fr)
	else
		novo("UIStroke", { Color = c.rule, Thickness = 1.5 }, fr)
	end
	novo("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = emoji,
		TextSize = math.floor(tamanho * 0.52),
		TextTransparency = if ganha then 0 else 0.7,
		ZIndex = 35,
	}, fr)
	if not ganha then
		novo("TextLabel", {
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.fromScale(1.08, 1.08),
			Size = UDim2.fromOffset(math.floor(tamanho * 0.42), math.floor(tamanho * 0.42)),
			BackgroundTransparency = 1,
			Text = Emojis.cadeado,
			TextSize = math.floor(tamanho * 0.32),
			ZIndex = 36,
		}, fr)
	end
	return fr
end

-- Contagem das medalhas deste mapa: ganhas, total, XP ganho e XP total.
local function contarConquistas(estado: any, dados: any): (number, number, number, number)
	local ganhas, total, xp, xpTotal = 0, 0, 0, 0
	for _, m in Metas.medalhasDoMapa(dados) do
		total += 1
		xpTotal += m.xp or 0
		if (estado.medalhas or {})[m.id] then
			ganhas += 1
			xp += m.xp or 0
		end
	end
	return ganhas, total, xp, xpTotal
end

-- Cartão de resumo na aba Companhia: contagem, barra, as últimas ganhas e o botão da galeria.
function Menu._resumoConquistas(self: Menu, ordem: number)
	local est, dados, estado, r = self.est, self.dados, self.estado, self.rolagem
	local ganhas, total = contarConquistas(estado, dados)
	local cartao, txt = novoCartao(est, r, "ResumoConquistas", ordem, true)
	txt("subtitulo", L(`{Emojis.medalha} Conquistas · {ganhas} de {total}`, `{Emojis.medalha} Achievements · {ganhas} of {total}`), 1)
	local cheio = est:barra(cartao, 2)
	cheio.Size = UDim2.fromScale(if total > 0 then ganhas / total else 0, 1)
	-- fileira com as últimas medalhas ganhas (as mais recentes primeiro)
	local recentes = {}
	for _, m in Metas.medalhasDoMapa(dados) do
		local quando = (estado.medalhas or {})[m.id]
		if quando then
			table.insert(recentes, { m = m, quando = tonumber(quando) or 0 })
		end
	end
	table.sort(recentes, function(a, b)
		return a.quando > b.quando
	end)
	if #recentes > 0 then
		local fileira = novo("Frame", {
			Name = "Recentes",
			LayoutOrder = 3,
			Size = UDim2.new(1, 0, 0, 48),
			BackgroundTransparency = 1,
			ZIndex = 33,
		}, cartao)
		est:lista(fileira, 8, true)
		for i = 1, math.min(5, #recentes) do
			medalhaoConquista(est, fileira, (Emojis :: any)[recentes[i].m.emoji] or Emojis.medalha, true, 44, i)
		end
	else
		txt("fraco", L("Nenhuma ainda. A primeira vem com o primeiro trecho construído.", "None yet. The first one comes with your first section."), 3)
	end
	local b = est:botao("secundario", L(`{Emojis.medalha} Ver todas as conquistas`, `{Emojis.medalha} See all achievements`), cartao, 4)
	b.Name = "VerConquistas"
	b.ZIndex = 33
	b.Activated:Connect(function()
		self.verConquistas = true
		self.rolagem.CanvasPosition = Vector2.zero
		self:_redesenhar()
	end)
end

-- Galeria de conquistas: grade de medalhões por grupo, com progresso nas que contam algo.
function Menu._conquistas(self: Menu)
	local est, dados, estado, r = self.est, self.dados, self.estado, self.rolagem
	est:titulo(L(`{Emojis.medalha} Conquistas`, `{Emojis.medalha} Achievements`), r, 1)
	local bVolta = est:botao("secundario", L("Voltar à companhia", "Back to company"), r, 2)
	bVolta.Activated:Connect(function()
		self.verConquistas = false
		self.rolagem.CanvasPosition = Vector2.zero
		self:_redesenhar()
	end)

	-- cabeçalho: contagem grande, barra e XP
	local ganhas, total, xp, xpTotal = contarConquistas(estado, dados)
	local cab, txt = novoCartao(est, r, "Cabecalho", 3, true)
	local topo = novo("Frame", {
		Name = "Topo",
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, 64),
		BackgroundTransparency = 1,
		ZIndex = 33,
	}, cab)
	est:lista(topo, 12, true)
	medalhaoConquista(est, topo, Emojis.medalha, ganhas > 0, 60, 1)
	local col = novo("Frame", {
		LayoutOrder = 2,
		Size = UDim2.new(1, -72, 1, 0),
		BackgroundTransparency = 1,
		ZIndex = 33,
	}, topo)
	est:lista(col, 2)
	local lNum = est:texto("titulo", `{ganhas} / {total}`, col, 1)
	lNum.ZIndex = 34
	local lSub = est:texto("fraco", L(`{xp} de {xpTotal} XP ganhos com conquistas`, `{xp} of {xpTotal} XP earned from achievements`), col, 2)
	lSub.ZIndex = 34
	local cheio = est:barra(cab, 2)
	cheio.Size = UDim2.fromScale(if total > 0 then ganhas / total else 0, 1)
	txt("fraco", L("Cada mapa tem as suas conquistas. Elas dão XP, e o XP sobe o nível da companhia.", "Each map has its own achievements. They give XP, and XP raises your company level."), 3)

	-- grupos
	local doMapa = {}
	for _, m in Metas.medalhasDoMapa(dados) do
		doMapa[m.id] = m
	end
	local usadas = {}
	local grupos = {}
	for _, g in GRUPOS_CONQUISTAS do
		local lista = {}
		for _, id in g.ids do
			if doMapa[id] then
				table.insert(lista, doMapa[id])
				usadas[id] = true
			end
		end
		if #lista > 0 then
			table.insert(grupos, { nome = Idioma.t(g.nome), lista = lista })
		end
	end
	local outras = {}
	for _, m in Metas.medalhasDoMapa(dados) do
		if not usadas[m.id] then
			table.insert(outras, m)
		end
	end
	if #outras > 0 then
		table.insert(grupos, { nome = L("Outras", "Other"), lista = outras })
	end

	local ordem = 10
	for _, g in grupos do
		local nG = 0
		for _, m in g.lista do
			if (estado.medalhas or {})[m.id] then
				nG += 1
			end
		end
		ordem += 1
		est:texto("rotulo", Idioma.maiusculas(`{g.nome} · {nG}/{#g.lista}`), r, ordem)
		ordem += 1
		local grade = novo("Frame", {
			Name = "Grade",
			LayoutOrder = ordem,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			ZIndex = 32,
		}, r)
		novo("UIGridLayout", {
			CellSize = UDim2.new(0.5, -5, 0, 190),
			CellPadding = UDim2.fromOffset(10, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, grade)
		for i, m in g.lista do
			local quando = (estado.medalhas or {})[m.id]
			local ganha = quando ~= nil
			local tile = est:cartao({
				Name = "Medalha_" .. m.id,
				LayoutOrder = i,
				ZIndex = 32,
			}, grade, ganha)
			local lista = est:lista(tile, 4)
			if lista then
				(lista :: any).HorizontalAlignment = Enum.HorizontalAlignment.Center
			end
			medalhaoConquista(est, tile, (Emojis :: any)[m.emoji] or Emojis.medalha, ganha, 50, 1)
			local lNome = est:texto("corpo", `<b>{m.nome}</b>`, tile, 2)
			lNome.TextXAlignment = Enum.TextXAlignment.Center
			lNome.ZIndex = 33
			local lDesc = est:texto("fraco", m.descricao, tile, 3)
			lDesc.TextXAlignment = Enum.TextXAlignment.Center
			lDesc.TextSize = 12
			lDesc.ZIndex = 33
			local atual, alvo = Metas.progressoMedalha(m, estado, dados)
			if not ganha and atual and alvo and alvo > 0 then
				local barra = est:barra(tile, 4)
				barra.Size = UDim2.fromScale(math.clamp(atual / alvo, 0, 1), 1)
				local fmt = if alvo >= 1e4 then Economia.formatar(math.min(atual, alvo), dados.simbolo) .. " / " .. Economia.formatar(alvo, dados.simbolo)
					else `{math.min(math.floor(atual), alvo)} / {alvo}`
				local lProg = est:texto("rotulo", fmt, tile, 5)
				lProg.TextXAlignment = Enum.TextXAlignment.Center
				lProg.ZIndex = 33
			else
				local rodape = if ganha
					then L(`{Emojis.confirmar} Ganha em {os.date("%d/%m", tonumber(quando) or 0)} · +{m.xp} XP`, `{Emojis.confirmar} Earned {os.date("%m/%d", tonumber(quando) or 0)} · +{m.xp} XP`)
					else `+{m.xp} XP`
				local lRod = est:texto("rotulo", rodape, tile, 5)
				lRod.TextXAlignment = Enum.TextXAlignment.Center
				lRod.ZIndex = 33
				if ganha then
					lRod.TextColor3 = est:paleta(tile).positive
				end
			end
		end
	end
end

-- ---------------------------------------------------------------- aba Loja (Robux; ver Loja.luau)

function Menu._abaLoja(self: Menu)
	local est, dados, estado, r = self.est, self.dados, self.estado, self.rolagem
	est:titulo(L(`{Emojis.loja} Loja`, `{Emojis.loja} Shop`), r, 1)
	est:texto("fraco", L(
		"Compras com Robux para acelerar a companhia. Nada aqui muda os rankings: eles contam o nível e as linhas completas, que vêm de jogar.",
		"Robux purchases to speed up your company. Nothing here changes the leaderboards: they count level and complete lines, which come from playing."
	), r, 2)
	if not estado then
		return
	end
	local loja = estado.loja or {}
	local simbolo = dados.simbolo
	local jogador = Players.LocalPlayer
	local function redesenhar()
		if self.aba == "loja" then
			self:_redesenhar()
		end
	end

	-- passes (compra única)
	est:texto("subtitulo", L("Passes (compra única)", "Passes (one-time)"), r, 10)
	for i, p in Loja.PASSES do
		local cartao, txt = novoCartao(est, r, "Passe_" .. p.id, 10 + i, loja[p.id] == true)
		txt("subtitulo", `{(Emojis :: any)[p.emoji] or ""} {Idioma.t(p.nome)}`, 1)
		txt("fraco", Idioma.t(p.descricao), 2)
		if loja[p.id] then
			local l = txt("corpo", L(`{Emojis.confirmar} Você já tem este passe.`, `{Emojis.confirmar} You own this pass.`), 3)
			l.TextColor3 = est.c.positive
			if p.id == "gerente" then
				local ligado = loja.gerenteLigado ~= false
				local b = est:botao("discreto", if ligado then L(`{Emojis.confirmar} Gerente ligado (toque para desligar)`, `{Emojis.confirmar} Manager on (tap to turn off)`)
					else L(`{Emojis.fechar} Gerente desligado (toque para ligar)`, `{Emojis.fechar} Manager off (tap to turn on)`), cartao, 4)
				b.ZIndex = 33
				b.Activated:Connect(function()
					self.aoAgir:Fire("gerente", { ligado = not ligado })
				end)
			end
		elseif p.passId == 0 then
			txt("fraco", L(`{Emojis.relogio} Em breve`, `{Emojis.relogio} Coming soon`), 3)
		else
			precoRoblox("passe_" .. p.id, p.passId, Enum.InfoType.GamePass, redesenhar)
			local b = est:botao("principal", textoPreco("passe_" .. p.id, p.preco), cartao, 3)
			b.Name = "Comprar_" .. p.id
			b.ZIndex = 33
			b.Activated:Connect(function()
				MarketplaceService:PromptGamePassPurchase(jogador, p.passId)
			end)
		end
	end

	-- produtos (compra repetida)
	est:divisor(r, 30)
	est:texto("subtitulo", L("Pacotes e impulsos", "Packs and boosts"), r, 31)
	local ordem = 31
	for _, p in Loja.PRODUTOS do
		if p.tipo == "estudo" then
			continue -- "Concluir estudo" fica no Gabinete, ao lado do estudo em andamento
		end
		ordem += 1
		local cartao, txt = novoCartao(est, r, "Produto_" .. p.id, ordem)
		txt("subtitulo", `{(Emojis :: any)[p.emoji] or ""} {Idioma.t(p.nome)}`, 1)
		txt("fraco", Idioma.t(p.descricao), 2)
		if p.tipo == "dinheiro" then
			local lValor = txt("corpo", "", 3)
			local function atualizar()
				local b2 = Economia.balanco(self.estado, dados, true).lucro
				lValor.Text = L(`Hoje: <b>+ {Economia.formatar(Loja.valorPacote(p, b2), simbolo)}</b>`, `Right now: <b>+ {Economia.formatar(Loja.valorPacote(p, b2), simbolo)}</b>`)
			end
			atualizar()
			table.insert(self.vivos, atualizar)
		elseif p.tipo == "impulso" then
			local lTempo = txt("corpo", "", 3)
			local function atualizar()
				local ate = ((self.estado or {}).loja or {}).impulsoAte or 0
				local resta = ate - Economia.relogio()
				lTempo.Text = if resta > 0 then L(`{Emojis.velocidade} Ativo: faltam <b>{relogio(resta)}</b>`, `{Emojis.velocidade} Active: <b>{relogio(resta)}</b> left`) else ""
				lTempo.Visible = resta > 0
			end
			atualizar()
			table.insert(self.vivos, atualizar)
		end
		if p.produtoId == 0 then
			txt("fraco", L(`{Emojis.relogio} Em breve`, `{Emojis.relogio} Coming soon`), 4)
		else
			precoRoblox("produto_" .. p.id, p.produtoId, Enum.InfoType.Product, redesenhar)
			local b = est:botao("principal", textoPreco("produto_" .. p.id, p.preco), cartao, 4)
			b.Name = "Comprar_" .. p.id
			b.ZIndex = 33
			b.Activated:Connect(function()
				MarketplaceService:PromptProductPurchase(jogador, p.produtoId)
			end)
		end
	end
	est:texto("fraco", L(
		"Os pacotes usam a renda das suas linhas sem o Lucro em Dobro e sem impulso, então o valor é sempre o que aparece aqui.",
		"Packs use your lines' income without Double Profit or boosts, so the amount is always what you see here."
	), r, 60)
end

-- ---------------------------------------------------------------- aba Ajustes

function Menu._abaAjustes(self: Menu)
	local est, r = self.est, self.rolagem
	if self.verCreditos then
		self:_creditos()
		return
	end
	est:titulo(L(`{Emojis.configuracoes} Ajustes`, `{Emojis.configuracoes} Settings`), r, 1)
	local opcoes = {
		{ chave = "nomesEstacoes", nome = L("Nomes das cidades", "City names") },
		{ chave = "nomesMapa", nome = L("Nomes de estados, rios e regiões", "State, river and region names") },
		{ chave = "trens", nome = L("Trens andando no mapa", "Trains moving on the map") },
		{ chave = "musica", nome = L("Música", "Music") },
		{ chave = "efeitos", nome = L("Efeitos sonoros", "Sound effects") },
	}
	for i, op in opcoes do
		local ligado = self.ajustes[op.chave]
		local b = est:botao("discreto", `{if ligado then Emojis.confirmar else Emojis.fechar} {op.nome}`, r, 1 + i)
		b.TextXAlignment = Enum.TextXAlignment.Left
		est:padding(b, 12, 0)
		b.Activated:Connect(function()
			self.ajustes[op.chave] = not self.ajustes[op.chave]
			self.aoAjuste:Fire(op.chave, self.ajustes[op.chave])
			self:_redesenhar()
		end)
	end
	local bEnq = est:botao("secundario", L(`{Emojis.mapa_mundo} Reenquadrar o mapa`, `{Emojis.mapa_mundo} Recenter the map`), r, 10)
	bEnq.Activated:Connect(function()
		self.aoAjuste:Fire("reenquadrar", true)
	end)
	est:texto("fraco", L("🌐 O idioma do jogo segue o do Roblox: troque no menu do Roblox › Configurações › Idioma.", "🌐 The game follows your Roblox language: change it in the Roblox menu › Settings › Language."), r, 9)
	local bInicio = est:botao("secundario", L(`{Emojis.mapa_mundo} Menu inicial`, `{Emojis.mapa_mundo} Main menu`), r, 12)
	bInicio.Activated:Connect(function()
		self:abrirAba(nil)
		self.aoAjuste:Fire("menuInicial", true)
	end)
	local bCred = est:botao("discreto", L(`{Emojis.jornal} Créditos`, `{Emojis.jornal} Credits`), r, 11)
	bCred.Activated:Connect(function()
		self.verCreditos = true
		self.rolagem.CanvasPosition = Vector2.zero
		self:_redesenhar()
	end)
end

-- Texto vindo de fora (nomes de autores e arquivos) dentro de um rótulo RichText.
local function escapar(s: string): string
	return (s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

-- Créditos das fotos das cidades: as licenças CC BY e CC BY-SA pedem autor, título e licença.
-- Sem links: o jogo não pode mostrar endereços de fora do Roblox (os links ficam em CREDITOS.md
-- e na descrição do jogo).
function Menu._creditos(self: Menu)
	local est, r = self.est, self.rolagem
	est:titulo(L(`{Emojis.jornal} Créditos`, `{Emojis.jornal} Credits`), r, 1)
	local bVolta = est:botao("secundario", L("Voltar aos ajustes", "Back to settings"), r, 2)
	bVolta.Activated:Connect(function()
		self.verCreditos = false
		self.rolagem.CanvasPosition = Vector2.zero
		self:_redesenhar()
	end)
	est:texto(
		"corpo",
		L("As fotos das cidades nas eras Diesel, Elétrica e Alta Velocidade vêm do Wikimedia Commons e são usadas sob as licenças indicadas abaixo. Elas foram recortadas e reduzidas para o jogo; as fotos em CC BY-SA continuam sob a mesma licença. As ilustrações da Era do Vapor são do estúdio.", "The city photos in the Diesel, Electric and High Speed eras come from Wikimedia Commons and are used under the licenses listed below. They were cropped and resized for the game; CC BY-SA photos remain under the same license. The Steam Era illustrations are by the studio."),
		r,
		3
	)
	local ordem, cidadeAtual = 10, ""
	for _, c in Creditos do
		if c.cidade ~= cidadeAtual then
			cidadeAtual = c.cidade
			ordem += 1
			est:texto("subtitulo", escapar(c.cidade), r, ordem)
		end
		ordem += 1
		est:texto(
			"fraco",
			L(`<b>{escapar(c.era)}</b> · foto de {escapar(c.ano)}\n{escapar(c.autor)} · {escapar(c.licenca)}\n<i>{escapar(c.arquivo)}</i>`, `<b>{escapar(c.era)}</b> · photo from {escapar(c.ano)}\n{escapar(c.autor)} · {escapar(c.licenca)}\n<i>{escapar(c.arquivo)}</i>`),
			r,
			ordem
		)
	end
end

return Menu
