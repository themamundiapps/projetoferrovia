--!strict
-- Menu: barra inferior (Linhas, Gabinete, Contratos, Companhia, Ajustes), o painel lateral de cada uma
-- e os botões de zoom.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Economia = require(Shared:WaitForChild("Economia"))
local Emojis = require(Shared:WaitForChild("Emojis"))
local Metas = require(Shared:WaitForChild("Metas"))
local Idioma = require(Shared:WaitForChild("Idioma"))
local Jornal = require(Shared:WaitForChild("Jornal"))
local Assets = require(Shared:WaitForChild("Assets"))
local Banco = require(Shared:WaitForChild("Banco"))
local Tarifas = require(Shared:WaitForChild("Tarifas"))
local Decisoes = require(Shared:WaitForChild("Decisoes"))
local Estilo = require(script.Parent:WaitForChild("Estilo"))

local novo = Estilo.novo

local Menu = {}
Menu.__index = Menu

export type Menu = typeof(setmetatable({} :: any, Menu))

local ABAS = {
	{ id = "linhas", nome = "Linhas", emoji = "linhas" },
	{ id = "projetos", nome = "Gabinete", emoji = "gabinete" },
	{ id = "metas", nome = "Contratos", emoji = "contratos" },
	{ id = "jornal", nome = "Jornal", emoji = "jornal" },
	{ id = "banco", nome = "Banco", emoji = "banco" },
	{ id = "tarifas", nome = "Tarifas", emoji = "tarifas" },
	{ id = "companhia", nome = "Companhia", emoji = "companhia" },
	{ id = "ajustes", nome = "Ajustes", emoji = "configuracoes" },
}

function Menu.new(tela: ScreenGui, era: any, dados: any): Menu
	local est = Estilo.new(era)
	local self = setmetatable({}, Menu)
	self.est = est
	self.dados = dados
	self.estado = nil :: any
	self.aba = nil :: string?
	self.ajustes = { nomesEstacoes = true, nomesMapa = true, trens = true }
	self.aoAgir = Instance.new("BindableEvent") -- (tipo, args)
	self.aoFocarLinha = Instance.new("BindableEvent") -- (linhaId)
	self.aoAjuste = Instance.new("BindableEvent") -- (chave, valor)
	self.aoZoom = Instance.new("BindableEvent") -- (fator)
	self.aoConcluirProjeto = Instance.new("BindableEvent") -- (projeto) quando um estudo termina
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
		local m = est:medalhao((Emojis :: any)[aba.emoji], if aba.id == "ajustes" then "Ajustes" else aba.nome, fileira :: Frame, i, aba.id)
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
		local rotulo = if aba.id == "ajustes" then (Emojis :: any)[aba.emoji] else `{(Emojis :: any)[aba.emoji]} {aba.nome}`
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
		Position = UDim2.new(1, -16, 1, -16),
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
		b.TextSize = 24
		b.Activated:Connect(function()
			self.aoZoom:Fire(fatores[i])
		end)
	end

	-- ---------------------------------------------------- gavetas (puxadores nas bordas da tela)
	-- esquerda: a companhia (ou a última aba aberta); direita: as linhas, com o painel do lado direito
	self.lado = "esq"
	self.ultimaAba = "companhia"
	local gavetaEsq = est:abaLateral("Companhia", "esq", tela)
	local gavetaDir = est:abaLateral("Linhas", "dir", tela)
	table.insert(self.instancias, gavetaEsq)
	table.insert(self.instancias, gavetaDir)
	self.gavetas = { esq = gavetaEsq, dir = gavetaDir }
	gavetaEsq.Activated:Connect(function()
		if self.aba and self.lado == "esq" then
			self:abrirAba(nil)
		else
			self:abrirAba(if self.ultimaAba == "linhas" or self.ultimaAba == "metas" then "companhia" else self.ultimaAba, "esq")
		end
	end)
	gavetaDir.Activated:Connect(function()
		if self.aba and self.lado == "dir" then
			self:abrirAba(nil)
		else
			self:abrirAba("linhas", "dir")
		end
	end)
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
	-- o painel encosta na gaveta do lado em que foi aberto
	local dir = self.lado == "dir"
	local margem = Estilo.MARGEM_LATERAL + b
	self.painel.AnchorPoint = Vector2.new(if dir then 1 else 0, 0)
	self.painel.Position = UDim2.new(if dir then 1 else 0, if dir then -margem else margem, 0, y + 10 + 2 * b)
	-- embaixo, para acima da barra do menu (que cresce com os medalhões)
	local barra = self.barra
	local alturaBarra = if barra then barra.AbsoluteSize.Y else 60
	-- o Jornal abre como uma página larga; as outras abas, na largura normal
	local largura = if self.aba == "jornal" then 560 else 330
	self.painel.Size = UDim2.new(0, largura, 1, -(y + 10 + 2 * b) - (alturaBarra + 14 + 3 * b) - 10)
end

function Menu.abrirAba(self: Menu, aba: string?, lado: string?)
	if aba ~= self.aba then
		-- aba nova começa do topo (o redesenho guarda a rolagem só dentro da mesma aba)
		self.rolagem.CanvasPosition = Vector2.zero
	end
	self.aba = aba
	if aba then
		self.ultimaAba = aba
		self.lado = lado or "esq"
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
	-- banco: redesenha quando pega/quita empréstimo ou quando muda a classe de crédito
	table.insert(metas, if estado.emprestimo then estado.emprestimo.em else 0)
	table.insert(metas, Banco.classe(Banco.nota(estado, Economia.satisfacao(estado, self.dados))).id)
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
		self:_etiquetar("projetos", "Gabinete", extraGabinete())
		self:_etiquetar("jornal", "Jornal", extraJornal())
		self:_etiquetar("metas", "Contratos", extraMetas())
		return
	end
	local b = self.botoesAba.projetos
	if b then
		local txt = `{Emojis.gabinete} Gabinete`
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
		local txt = `{Emojis.jornal} Jornal`
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
		local txt = `{Emojis.contratos} Contratos`
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
	elseif self.aba == "banco" then
		self:_abaBanco()
	elseif self.aba == "tarifas" then
		self:_abaTarifas()
	elseif self.aba == "companhia" then
		self:_abaCompanhia()
	else
		self:_abaAjustes()
	end
	self.rolagem.CanvasPosition = Vector2.new(0, rolagemY)
end

-- ---------------------------------------------------------------- aba Linhas

function Menu._abaLinhas(self: Menu)
	local est, dados, estado, r = self.est, self.dados, self.estado, self.rolagem
	est:titulo(`{Emojis.linhas} Linhas`, r, 1)
	if not estado then
		return
	end
	local simbolo = dados.simbolo

	local bTudo = est:botao("principal", `{Emojis.construir} Construir tudo que der`, r, 2)
	bTudo.Name = "BtnConstruirTudo"
	bTudo.Activated:Connect(function()
		self.aoAgir:Fire("construirTudo", {})
	end)
	local bFrota = est:botao("secundario", `{Emojis.trens} Completar frotas`, r, 3)
	bFrota.Name = "BtnCompletarFrotas"
	bFrota.Activated:Connect(function()
		self.aoAgir:Fire("completarFrotas", {})
	end)
	est:texto("fraco", "Construir tudo compra os trechos liberados do mais barato para o mais caro. Completar frotas compra trens até todos os passageiros embarcarem.", r, 4)

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

		local titulo = est:texto("subtitulo", `{linha.nome} <font size="13">· {linha.ano}</font>`, textos, 1)
		titulo.ZIndex = 33
		local info
		if not liberada and linha.projeto then
			info = `{Emojis.gabinete} Projeto: estude no Gabinete para liberar`
		elseif not liberada then
			info = `{Emojis.cadeado} Complete antes: {table.concat(Economia.faltaParaLiberar(estado, dados, i), ", ")}`
		else
			local lucro = if bl then bl.lucro else 0
			local txtLucro = if lucro >= 0 then `lucro {Economia.formatar(lucro, simbolo, true)}/s`
				else `prejuízo {Economia.formatar(-lucro, simbolo, true)}/s`
			local txtRede = if bl and bl.rede > 0 then ` · rede +{math.round((bl.fatorRede - 1) * 100)}%` else ""
			info = `{construidos}/{#linha.trechos} trechos · {estado.trens[linha.id] or 0} trens · {txtLucro}{txtRede}`
		end
		local l2 = est:texto("fraco", info, textos, 2)
		l2.ZIndex = 33
		local situacao = if not liberada then ""
			elseif faltando > 0 then `{Emojis.alerta} Lotada: só {math.round((bl and bl.servico or 0) * 100)}% embarcam · faltam {faltando} trem(ns)`
			elseif sobrando > 0 then `{Emojis.alerta} {sobrando} trem(ns) rodando vazio(s)`
			elseif completa then `{Emojis.confirmar} Linha completa`
			elseif construidos == 0 then `{Emojis.construir} Pronta para começar`
			else `{Emojis.construir} Em construção`
		if situacao ~= "" then
			local l3 = est:texto("fraco", situacao, textos, 3)
			l3.ZIndex = 33
			if faltando > 0 or sobrando > 0 then
				l3.TextColor3 = est.c.negative
			elseif completa then
				l3.TextColor3 = est.c.positive
			end
		end
		linhaBtn.Activated:Connect(function()
			self.aoFocarLinha:Fire(linha.id)
		end)
	end
end

-- ---------------------------------------------------------------- aba Gabinete de Projetos

function Menu._abaProjetos(self: Menu)
	local est, dados, estado, r = self.est, self.dados, self.estado, self.rolagem
	est:titulo(`{Emojis.gabinete} Gabinete de Projetos`, r, 1)
	est:texto(
		"fraco",
		"Ferrovias que o Brasil planejou e nunca terminou e, no fim, planos ousados que ninguém chegou a fazer (os \"E se?\"). Estude um projeto por vez: o estudo leva tempo de verdade (continua com o jogo fechado) e, quando termina, a linha abre no mapa.",
		r,
		2
	)
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
		txt("rotulo", `{if p.ficticio then "E SE? · " else ""}{if linha then #linha.trechos else 0} TRECHOS · {numero(km)} KM`, 2)
		txt("fraco", Idioma.t(p.descricao), 3)

		if situacao == "concluido" then
			local l = txt("corpo", `{Emojis.confirmar} Projeto aprovado: a linha está aberta no mapa.`, 4)
			l.TextColor3 = c.positive
			local b = est:botao("discreto", `{Emojis.linhas} Ver no mapa`, cartao, 5)
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
			local function atualizar()
				local e = self.estado
				local _, restante = Economia.pesquisaAtual(e)
				barra.Size = UDim2.fromScale(math.clamp(1 - restante / p.segundos, 0, 1), 1)
				lTempo.Text = `{Emojis.relogio} Em estudo · faltam <b>{relogio(restante)}</b>`
				local custo = Economia.custoAcelerar(p, restante)
				bAcel.Text = `{Emojis.velocidade} Acelerar agora · {Economia.formatar(custo, simbolo)}`
				est:habilitar(bAcel, e.dinheiro >= custo)
			end
			atualizar()
			table.insert(self.vivos, atualizar)
		elseif situacao == "bloqueado" then
			local _, motivo = Economia.requisitosProjeto(estado, dados, p)
			txt("corpo", `{Emojis.cadeado} {motivo or "Ainda fechado."}`, 4)
			txt("fraco", `Estudo: {Economia.formatar(p.custo, simbolo)} · {relogio(p.segundos)}`, 5)
		else
			local b = est:botao("principal", `{Emojis.gabinete} Estudar · {Economia.formatar(p.custo, simbolo)} · {relogio(p.segundos)}`, cartao, 4)
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
				lMotivo.Text = if not livre then "O Gabinete já está ocupado com outro estudo."
					elseif e.dinheiro < p.custo then `Faltam {Economia.formatar(p.custo - e.dinheiro, simbolo)}.`
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
	est:titulo(`{Emojis.contratos} Contratos`, r, 1)
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
		txt("rotulo", `{dif.caixaAlta} · PRÊMIO {Economia.formatar(contrato.premio, simbolo)} · +{contrato.xp} XP`, 2)
		txt("fraco", dica, 3)
		local cheio = novaBarra(est, cartao, 4)
		local lProg = txt("corpo", "", 5)
		local bDes = est:botao("discreto", "Desistir do contrato", cartao, 6)
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
			lProg.Text = `<b>{Metas.progressoContrato(atual)}</b> · {Emojis.relogio} faltam {relogio(atual.prazo - atual.decorrido)}`
		end
		atualizar()
		table.insert(self.vivos, atualizar)
	elseif #ofertas > 0 then
		est:texto("fraco", "Escolha um contrato por vez. O prazo só corre com o jogo aberto, e não há multa se ele acabar.", r, 2)
		for i, o in ofertas do
			local emoji, titulo, dica = Metas.descreverContrato(o, dados)
			local dif = Metas.dificuldade(o.dificuldade)
			local cartao, txt = novoCartao(est, r, `Oferta_{i}`, 10 + i)
			txt("subtitulo", `{(Emojis :: any)[emoji] or ""} {titulo}`, 1)
			txt("rotulo", `{dif.caixaAlta} · PRAZO {relogio(o.prazo)}`, 2)
			txt("fraco", dica, 3)
			txt("corpo", `{Emojis.presente} Prêmio: <b>{Economia.formatar(o.premio, simbolo)}</b> · +{o.xp} XP`, 4)
			local b = est:botao("principal", `{Emojis.assinar} Aceitar contrato`, cartao, 5)
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
				bTroca.Text = `{Emojis.auto} Trocar ofertas em {relogio(espera)}`
				est:habilitar(bTroca, false)
			else
				bTroca.Text = `{Emojis.auto} Trocar ofertas`
				est:habilitar(bTroca, true)
			end
		end
		atualizar()
		table.insert(self.vivos, atualizar)
	else
		est:texto("fraco", "Construa os primeiros trechos para começar a receber ofertas de contrato.", r, 2)
	end

	-- missões do dia
	est:divisor(r, 40)
	est:texto("subtitulo", `{Emojis.alvo} Missões de hoje`, r, 41)
	local missoes = (estado.missoes or {}).lista or {}
	for i, m in missoes do
		local emoji, titulo = Metas.descreverMissao(m, simbolo)
		local pronta = m.progresso >= m.meta
		local cartao, txt = novoCartao(est, r, `Missao_{i}`, 41 + i, pronta and not m.resgatada)
		local lTitulo = txt("corpo", `{(Emojis :: any)[emoji] or ""} <b>{titulo}</b>`, 1)
		if m.resgatada then
			lTitulo.TextColor3 = c.inkMuted
			local l = txt("fraco", `{Emojis.confirmar} Resgatada`, 2)
			l.TextColor3 = c.positive
		elseif pronta then
			local b = est:botao("principal", `{Emojis.presente} Resgatar · {Economia.formatar(m.premio, simbolo)} · +{m.xp} XP`, cartao, 2)
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
				lProg.Text = `{numero(math.floor(atual.progresso))} de {numero(atual.meta)} · prêmio {Economia.formatar(atual.premio, simbolo)} · +{atual.xp} XP`
			end
			atualizar()
			table.insert(self.vivos, atualizar)
		end
	end
	local lVira = est:texto("fraco", "", r, 50)
	local function atualizarVira()
		lVira.Text = `Missões novas em {relogio(Metas.segundosAteVirar(Economia.relogio()))}.`
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
		return `{valor} em toda a receita`
	elseif ev.tipo == "manutencao" then
		return `manutenção {valor}`
	elseif ev.tipo == "linha" then
		return `{valor} na linha {nome}`
	elseif ev.tipo == "carga" then
		return `{valor} nas linhas que levam {string.lower(nome)}`
	elseif ev.tipo == "cidade" then
		return `{valor} nas linhas de {nome}`
	elseif ev.tipo == "regiao" then
		return `{valor} nas linhas do {nome}`
	end
	return valor
end

local function ha(segundos: number): string
	local m = math.floor(segundos / 60)
	if m < 1 then
		return "agora há pouco"
	elseif m < 60 then
		return `há {m} min`
	end
	local h = math.floor(m / 60)
	if h < 24 then
		return `há {h} h`
	end
	return `há {math.floor(h / 24)} dia(s)`
end

-- Foto da notícia: a cidade do alvo (ou uma da rede ligada a ele); sem cidade, a maior da rede.
local function fotoEvento(ev: any, estado: any, dados: any): (string?, string?)
	local function imagem(id: string): string?
		local e = dados.estacoes[id]
		return (Assets.Cidades :: any)[id] or (e and (Assets.Paisagens :: any)[e.paisagem or ""])
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
		local ia, ib = (Assets.Cidades :: any)[a] ~= nil, (Assets.Cidades :: any)[b] ~= nil
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
	return (Assets.Cidades :: any).rio, dados.estacoes.rio and dados.estacoes.rio.nome
end

local PRECO_JORNAL = { vapor = "100 réis", diesel = "1 cruzeiro", eletrico = "Cr$ 2", alta = "grátis" }
local MESES_JORNAL = { "janeiro", "fevereiro", "março", "abril", "maio", "junho", "julho", "agosto", "setembro", "outubro", "novembro", "dezembro" }
local PAPEL = Color3.fromRGB(238, 228, 204) -- papel de jornal
local TINTA = Color3.fromRGB(38, 30, 22)
local TINTA_FRACA = Color3.fromRGB(96, 82, 64)

-- Aba Jornal: uma página de jornal da época (manchete com foto, outras notícias em colunas,
-- notas da diretoria, movimento da companhia e edições anteriores).
function Menu._abaJornal(self: Menu)
	local est, dados, estado, r = self.est, self.dados, self.estado, self.rolagem
	local eraId = if estado then estado.era else "vapor"
	local nomeJornal = Idioma.t(Jornal.NOMES[eraId] or Jornal.NOMES.vapor)
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
		then `{dia % 30 + 1} de {MESES_JORNAL[(dia // 30) % 12 + 1]} de {Economia.anoAtual(estado, dados)}`
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
	linha("Rio de Janeiro", Enum.TextXAlignment.Left)
	linha(data, Enum.TextXAlignment.Center)
	linha(`Nº {#edicoes + 1} · {PRECO_JORNAL[eraId] or ""}`, Enum.TextXAlignment.Right)
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
			lTempo.Text = `{Emojis.relogio} vale por mais {relogio(resta)}`
			if bResolver then
				local custo = Jornal.custoResolver(self.estado.renda or 0)
				bResolver.Text = `Resolver agora · {Economia.formatar(custo, simbolo)}`
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
				t(folha, 13, `Vista de {cidade}. Gravura da redação.`, italico, 11, TINTA_FRACA, true)
			end
		end
		t(folha, 14, texto, f.body, 14, TINTA)
		prazo(folha, 15, principal)
	else
		t(folha, 10, "CALMARIA NOS TRILHOS", f.display, 24, TINTA, true)
		t(folha, 11, "Nada de extraordinário nas notícias de hoje. Os trens correm no horário e o comércio segue seu curso.", italico, 14, TINTA_FRACA, true)
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
	t(mov, 1, "Movimento da Companhia", f.display, 15, TINTA)
	local lMov = t(mov, 2, "", f.body, 12, TINTA)
	local function atualizarMovimento()
		local b = Economia.balanco(self.estado, dados)
		local carga = 0
		for _, v in Economia.cargaPorDia(self.estado, dados, b) do
			carga += v
		end
		local nome = self.estado.nomeCompanhia or Idioma.T("companhia_padrao")
		lMov.Text = `A {nome} levou ontem <b>{numero(Economia.passageirosPorDia(b))}</b> passageiros`
			.. (if carga > 0 then ` e <b>{numero(carga)}</b> unidades de carga` else "")
			.. `. Em caixa, {Economia.formatar(self.estado.dinheiro, simbolo)}; a satisfação dos viajantes está em {math.round(b.satisfacao * 100)}%.`
	end
	atualizarMovimento()
	table.insert(self.vivos, atualizarMovimento)
	local notas = materia(fixas, 2)
	t(notas, 1, "Notas da Diretoria", f.display, 15, TINTA)
	local efeitos = Economia.efeitosDecisoes(estado)
	if #efeitos == 0 then
		t(notas, 2, "A diretoria não tem comunicados em vigor.", italico, 12, TINTA_FRACA)
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
		t(folha, 41, "Edições anteriores", f.display, 14, TINTA, true)
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

-- ---------------------------------------------------------------- aba Banco

function Menu._abaBanco(self: Menu)
	local est, dados, estado, r = self.est, self.dados, self.estado, self.rolagem
	local nomeBanco = Idioma.t(Banco.NOMES[if estado then estado.era else "vapor"] or Banco.NOMES.vapor)
	est:titulo(`{Emojis.banco} {nomeBanco}`, r, 1)
	est:texto("fraco", `Empréstimos para construir mais cedo. O limite e os juros dependem do seu crédito: satisfação dos passageiros e nível da companhia. A dívida é paga sozinha com {math.round(Banco.PARCELA * 100)}% do lucro, e dá para quitar quando quiser.`, r, 2)
	if not estado then
		return
	end
	local simbolo = dados.simbolo
	local function fmt(v: number): string
		return Economia.formatar(v, simbolo)
	end

	-- crédito da companhia
	local cartao, txt = novoCartao(est, r, "Credito", 3)
	local lClasse = txt("subtitulo", "", 1)
	local cheioNota = novaBarra(est, cartao, 2)
	local lDetalhe = txt("fraco", "", 3)
	local function atualizarCredito()
		local b = Economia.balanco(self.estado, dados)
		local limite, classe, nota = Banco.limite(self.estado, b.lucro, b.satisfacao)
		lClasse.Text = `Crédito {classe.id} · {Idioma.t(classe.nome)}`
		cheioNota.Size = UDim2.fromScale(nota, 1)
		lDetalhe.Text = `Satisfação {math.round(b.satisfacao * 100)}% · nível {(Economia.nivel(self.estado))} · juros de {math.round(classe.juros * 100)}% · limite {fmt(limite)}`
	end
	atualizarCredito()
	table.insert(self.vivos, atualizarCredito)
	local dica = est:texto("fraco", `{Emojis.dica} Mais trens nas linhas lotadas e estações melhores aumentam a satisfação e baixam os juros.`, r, 4)
	dica.TextSize = 13

	local emp = estado.emprestimo
	if emp then
		local cartao2, txt2 = novoCartao(est, r, "Emprestimo", 10, true)
		txt2("subtitulo", "Empréstimo em andamento", 1)
		local lDivida = txt2("corpo", "", 2)
		local cheio = novaBarra(est, cartao2, 3)
		local lTempo = txt2("fraco", "", 4)
		local bQuitar = est:botao("principal", "", cartao2, 5)
		bQuitar.Name = "BtnQuitar"
		bQuitar.ZIndex = 33
		bQuitar.Size = UDim2.new(1, 0, 0, 38)
		bQuitar.Activated:Connect(function()
			self.aoAgir:Fire("quitarEmprestimo", {})
		end)
		local function atualizar()
			local e = self.estado.emprestimo
			if not e then
				return
			end
			lDivida.Text = `Falta pagar <b>{fmt(e.divida)}</b> de {fmt(e.total)} (você pegou {fmt(e.valor)})`
			cheio.Size = UDim2.fromScale(math.clamp(1 - e.divida / e.total, 0, 1), 1)
			local resta = Banco.tempoRestante(self.estado, self.estado.renda or 0)
			lTempo.Text = if resta == math.huge
				then `{Emojis.alerta} Sem lucro, a dívida não diminui.`
				else `{Emojis.relogio} Pagando {math.round(Banco.PARCELA * 100)}% do lucro, termina em ~{relogio(resta)}`
			bQuitar.Text = `{Emojis.dinheiro} Quitar agora · {fmt(e.divida)}`
			est:habilitar(bQuitar, self.estado.dinheiro >= e.divida)
		end
		atualizar()
		table.insert(self.vivos, atualizar)
		return
	end

	est:texto("subtitulo", "Ofertas do banco", r, 10)
	local motivo = Banco.impedimento(estado)
	local botoes: { TextButton } = {}
	for i = 1, #Banco.OPCOES do
		local b = est:botao(if i == #Banco.OPCOES then "principal" else "secundario", "", r, 10 + i)
		b.Name = `BtnEmprestimo_{i}`
		b.Size = UDim2.new(1, 0, 0, 40)
		b.Activated:Connect(function()
			self.aoAgir:Fire("tomarEmprestimo", { opcao = i })
		end)
		botoes[i] = b
	end
	local lMotivo = est:texto("fraco", motivo or "", r, 20)
	lMotivo.Visible = motivo ~= nil
	local function atualizarOfertas()
		local b = Economia.balanco(self.estado, dados)
		local ofertas = Banco.ofertas(self.estado, b.lucro, b.satisfacao)
		local bloqueado = Banco.impedimento(self.estado) ~= nil
		for i, o in ofertas do
			local bt = botoes[i]
			if bt then
				bt.Text = `Pegar {fmt(o.valor)} · devolve {fmt(o.total)}`
				est:habilitar(bt, not bloqueado)
			end
		end
	end
	atualizarOfertas()
	table.insert(self.vivos, atualizarOfertas)
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
	est:titulo(`{Emojis.tarifas} Tarifas`, r, 1)
	est:texto("fraco", "O preço da passagem de cada classe vale para todas as linhas. Mais caro rende mais por passageiro, mas afasta gente; caro demais irrita quem viaja. O serviço de bordo deixa cada classe aceitar pagar mais.", r, 2)
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
	txtR("subtitulo", `Receita das passagens: {pct(fr)} do normal`, 1)
	txtR("corpo", `Passageiros: {pct(fp)} · satisfação {sinal(ajuste)} pontos`, 2)
	local lCusto = txtR("fraco", "", 3)
	local function atualizarCusto()
		local custo = Tarifas.custoServicos(self.estado.tarifas, era) * Economia.manutencaoTrens(self.estado, dados)
		lCusto.Text = if custo > 0
			then `Serviço de bordo custa {Economia.formatar(custo, simbolo, true)} por segundo.`
			else "Nenhum serviço de bordo contratado."
	end
	atualizarCusto()
	table.insert(self.vivos, atualizarCusto)

	-- preço por classe
	est:texto("subtitulo", "Preço das passagens", r, 10)
	for c = 1, Tarifas.CLASSES do
		local p = tf.precos[c] or 1
		local cartao, txt = novoCartao(est, r, `Classe_{c}`, 10 + c)
		txt("subtitulo", `{Tarifas.nomeClasse(c, era, Idioma.atual)} · {pct(mistura[c])} dos passageiros`, 1)
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
		txt("fraco", `Procura {pct(d)} · cada assento rende {pct(p * d)} · o melhor fica perto de {pct(otimo)}`, 3)
		local justo = Tarifas.JUSTO[c] + 0.8 * tol[c]
		if p > justo + 1e-6 then
			local aviso = txt("fraco", `{Emojis.alerta} Acima de {pct(justo)} os passageiros reclamam: a satisfação cai.`, 4)
			aviso.TextColor3 = est.c.negative
		elseif p < 1 - 1e-6 then
			txt("fraco", `{Emojis.satisfacao} Passagem popular: rende menos, mas a satisfação sobe.`, 4)
		end
	end

	-- serviço de bordo
	est:divisor(r, 20)
	est:texto("subtitulo", "Serviço de bordo", r, 21)
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
				table.insert(efeitos, `{Tarifas.nomeClasse(c, era, Idioma.atual)} aceita +{pct(sv.tol[c])}`)
			end
		end
		table.insert(efeitos, `satisfação +{math.round(sv.sat * 100)}`)
		txt("corpo", table.concat(efeitos, " · "), 3)
		txt("fraco", `Custo: {Economia.formatar(sv.custo * manutTrens, simbolo, true)}/s ({pct(sv.custo)} da manutenção dos trens)`, 4)
		local b = est:botao(if ativo then "secundario" else "principal", if ativo then "Dispensar" else "Contratar", cartao, 5)
		b.Name = "BtnServico"
		b.Size = UDim2.new(1, 0, 0, 36)
		b.ZIndex = 33
		b.Activated:Connect(function()
			self.aoAgir:Fire("alternarServico", { id = sv.id })
		end)
	end
	if #futuros > 0 then
		est:texto("fraco", `Nas próximas eras: {table.concat(futuros, ", ")}.`, r, ordem)
	end
end

-- ---------------------------------------------------------------- aba Companhia

function Menu._abaCompanhia(self: Menu)
	local est, dados, estado, r = self.est, self.dados, self.estado, self.rolagem
	est:titulo(`{Emojis.companhia} Companhia`, r, 1)
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
		(if xpDoNivel > 0 then `{numero(xpNoNivel)} de {numero(xpDoNivel)} XP para o próximo nível` else "Nível máximo")
			.. ` · bônus de receita: +{bonus}%. Ganhe XP construindo, cumprindo contratos e missões e ganhando medalhas.`,
		r,
		5
	)
	est:divisor(r, 6)

	local sat = math.round(st.satisfacao * 100)
	est:texto("subtitulo", `{Emojis.satisfacao} Satisfação: {sat}%`, r, 7)
	local cheioSat = est:barra(r, 8)
	cheioSat.Size = UDim2.fromScale(st.satisfacao, 1)
	cheioSat.BackgroundColor3 = if sat >= 70 then est.c.positive elseif sat >= 40 then est.c.accent else est.c.negative
	est:texto("fraco", `Vem dos passageiros que conseguem embarcar (trens suficientes) e do nível das estações. Hoje mexe {(function()
		local pct = math.round((Economia.fatorSatisfacao(estado, dados) - 1) * 100)
		return if pct > 0 then `+{pct}` else tostring(math.abs(pct) == 0 and 0 or pct)
	end)()}% na renda.`, r, 9)
	est:divisor(r, 10)

	local linhas = {
		`{Emojis.renda} Receita: <b>{Economia.formatar(st.receita, simbolo, true)}/s</b>`,
		`{Emojis.manutencao} Manutenção: <b>− {Economia.formatar(st.manutencao, simbolo, true)}/s</b>`,
		if st.renda >= 0 then `{Emojis.dinheiro} Lucro: <b>{Economia.formatar(st.renda, simbolo, true)}/s</b>`
			else `{Emojis.alerta} Prejuízo: <b>{Economia.formatar(-st.renda, simbolo, true)}/s</b>`,
		`{Emojis.trens} Trens: <b>{st.trens}</b>`,
		`{Emojis.passageiros} Passageiros: <b>{numero(st.passageirosDia)}</b> por dia`,
		`{Emojis.linhas} Trechos: <b>{st.trechos}</b> de {st.trechosTotal}`,
		`{Emojis.confirmar} Linhas completas: <b>{st.linhasCompletas}</b> de {st.linhasTotal}`,
		`{Emojis.estacoes} Estações na rede: <b>{st.estacoes}</b>`,
		`{Emojis.contratos} Contratos cumpridos: <b>{(estado.contadores or {}).contratos or 0}</b>`,
		`{Emojis.carga_passageiros} Passageiros desde a fundação: <b>{numero(math.floor((estado.contadores or {}).passageiros or 0))}</b>`,
	}
	for i, txt in linhas do
		est:texto("corpo", txt, r, 10 + i)
	end

	-- cargas: quanto chega ao porto, o frete pago por unidade e quanto rende por dia
	est:divisor(r, 24)
	est:texto("subtitulo", `{Emojis.cargas} Cargas e fretes`, r, 25)
	local temCarga = false
	for i, id in Economia.ORDEM_CARGAS do
		local v = st.cargaValor[id]
		if v and v.unidadesDia > 0 then
			temCarga = true
			local carga = (Economia.CARGAS :: any)[id]
			local unidade = carga.unidade:gsub("s$", "") -- "sacas" -> "saca"; "t" e "cabeças" -> "cabeça"
			est:texto("corpo", `{(Emojis :: any)[carga.emoji] or ""} {carga.nome}: <b>{numero(math.round(v.unidadesDia))}</b> {carga.unidade}/dia · `
				.. `<b>{Economia.formatar(v.preco, simbolo, true)}</b> por {unidade} · <b>{Economia.formatar(v.reaisDia, simbolo)}</b>/dia`, r, 25 + i)
		end
	end
	if not temCarga then
		est:texto("fraco", "Nenhuma carga chega a um porto ainda. Ligue uma cidade produtora (café, minério…) a um porto pelos trilhos: o frete entra na renda da linha.", r, 26)
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

	-- medalhas
	local ganhas = estado.medalhas or {}
	local nGanhas = 0
	for _ in ganhas do
		nGanhas += 1
	end
	est:divisor(r, 40)
	est:texto("subtitulo", `{Emojis.medalha} Medalhas: {nGanhas} de {#Metas.MEDALHAS}`, r, 41)
	for i, m in Metas.MEDALHAS do
		local tem = ganhas[m.id] ~= nil
		local emoji = if tem then (Emojis :: any)[m.emoji] or Emojis.medalha else Emojis.cadeado
		local l = est:texto(if tem then "corpo" else "fraco", `{emoji} <b>{m.nome}</b> · {m.descricao}`, r, 41 + i)
		l.Name = "Medalha_" .. m.id
	end
end

-- ---------------------------------------------------------------- aba Ajustes

function Menu._abaAjustes(self: Menu)
	local est, r = self.est, self.rolagem
	est:titulo(`{Emojis.configuracoes} Ajustes`, r, 1)
	local opcoes = {
		{ chave = "nomesEstacoes", nome = "Nomes das cidades" },
		{ chave = "nomesMapa", nome = "Nomes de estados, rios e regiões" },
		{ chave = "trens", nome = "Trens andando no mapa" },
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
	local bEnq = est:botao("secundario", `{Emojis.mapa_mundo} Reenquadrar o mapa`, r, 10)
	bEnq.Activated:Connect(function()
		self.aoAjuste:Fire("reenquadrar", true)
	end)
end

return Menu
