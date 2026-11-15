--!strict
-- Interface (cliente): caixa da companhia, painel da concessão e avisos.
-- Só mostra o estado que o servidor manda e pede ações; nunca decide nada sobre dinheiro.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Economia = require(Shared:WaitForChild("Economia"))
local Metas = require(Shared:WaitForChild("Metas"))
local Emojis = require(Shared:WaitForChild("Emojis"))

local Interface = {}
Interface.__index = Interface

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

-- string.upper não converte letras acentuadas; esta versão converte.
local ACENTOS: { [string]: string } = {
	["á"] = "Á", ["à"] = "À", ["â"] = "Â", ["ã"] = "Ã", ["é"] = "É", ["ê"] = "Ê",
	["í"] = "Í", ["ó"] = "Ó", ["ô"] = "Ô", ["õ"] = "Õ", ["ú"] = "Ú", ["ç"] = "Ç",
}
local function maiusculas(texto: string): string
	local r = string.upper(texto)
	for min, mai in ACENTOS do
		r = string.gsub(r, min, mai)
	end
	return r
end

local function padding(pai: Instance, px: number)
	novo("UIPadding", {
		PaddingLeft = UDim.new(0, px),
		PaddingRight = UDim.new(0, px),
		PaddingTop = UDim.new(0, px),
		PaddingBottom = UDim.new(0, px),
	}, pai)
end

export type Interface = typeof(setmetatable({} :: any, Interface))

function Interface.new(tela: ScreenGui, era: any, dados: any)
	local c, f = era.cores, era.fontes
	local self = setmetatable({}, Interface)
	self.era = era
	self.dados = dados
	self.estado = nil :: any
	self.trechoAberto = nil :: string?
	self.estacaoAberta = nil :: string?
	self.alternativa = nil :: string?
	self.aoAgir = Instance.new("BindableEvent") -- (tipo, args)
	self.aoFechar = Instance.new("BindableEvent")
	self._fila = {} :: { { msg: string, segundos: number } }
	self._rodandoFila = false

	local function caixa(props: { [string]: any }): Frame
		local fr = novo("Frame", props, tela)
		fr.BackgroundColor3 = c.panel
		fr.Active = true -- bloqueia o mapa embaixo
		fr.ZIndex = 30
		novo("UIStroke", { Color = c.ink, Thickness = era.forma.traco + 0.5 }, fr)
		if era.forma.canto > 0 then
			novo("UICorner", { CornerRadius = UDim.new(0, era.forma.canto) }, fr)
		end
		return fr
	end

	-- ---------------------------------------------------- caixa da companhia (canto superior esquerdo)
	local hud = caixa({
		Name = "Caixa",
		Position = UDim2.fromOffset(16, 16),
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.fromOffset(0, 0),
	})
	self.hud = hud
	padding(hud, 12)
	novo("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) }, hud)
	novo("TextLabel", {
		LayoutOrder = 1,
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		Text = "CAIXA DA COMPANHIA",
		FontFace = f.label,
		TextSize = 13,
		TextColor3 = c.inkMuted,
		ZIndex = 31,
	}, hud)
	self.lblDinheiro = novo("TextLabel", {
		LayoutOrder = 2,
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		Text = "…",
		FontFace = f.display,
		TextSize = 32,
		TextColor3 = c.ink,
		ZIndex = 31,
	}, hud)
	self.lblRenda = novo("TextLabel", {
		LayoutOrder = 3,
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		Text = "",
		FontFace = f.number,
		TextSize = 15,
		TextColor3 = c.positive,
		ZIndex = 31,
	}, hud)

	-- nível da companhia e contrato em andamento
	self.lblNivel = novo("TextLabel", {
		Name = "Nivel",
		LayoutOrder = 4,
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		Text = "",
		FontFace = f.body,
		TextSize = 14,
		TextColor3 = c.ink,
		ZIndex = 31,
	}, hud)
	self.lblContrato = novo("TextLabel", {
		Name = "Contrato",
		LayoutOrder = 5,
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		Text = "",
		FontFace = f.body,
		TextSize = 14,
		TextColor3 = c.accent,
		Visible = false,
		ZIndex = 31,
	}, hud)

	self.btnEra = novo("TextButton", {
		Name = "BtnEra",
		LayoutOrder = 6,
		Size = UDim2.fromOffset(250, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = c.accent,
		TextColor3 = c.onAccent,
		FontFace = f.display,
		TextSize = 15,
		TextWrapped = true,
		RichText = true,
		Text = "",
		Visible = false,
		ZIndex = 32,
	}, hud)
	padding(self.btnEra, 8)
	if era.forma.canto > 0 then
		novo("UICorner", { CornerRadius = UDim.new(0, era.forma.canto) }, self.btnEra)
	end
	self.lblEra = novo("TextLabel", {
		LayoutOrder = 7,
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		Text = `{era.nome} · {era.anos}`,
		FontFace = f.label,
		TextSize = 13,
		TextColor3 = c.inkMuted,
		ZIndex = 31,
	}, hud)
	self.btnEra.Activated:Connect(function()
		self.aoAgir:Fire("modernizar", {})
	end)

	-- ---------------------------------------------------- aviso (topo, centro)
	self.aviso = caixa({
		Name = "Aviso",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 16),
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.fromOffset(0, 0),
		Visible = false,
	})
	padding(self.aviso, 10)
	self.lblAviso = novo("TextLabel", {
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		Text = "",
		FontFace = f.body,
		TextSize = 16,
		TextColor3 = c.ink,
		ZIndex = 31,
	}, self.aviso)

	-- ---------------------------------------------------- painel da concessão (direita)
	local painel = caixa({
		Name = "Concessao",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, 16),
		Size = UDim2.fromOffset(300, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = false,
	})
	self.painel = painel
	-- o conteúdo fica num frame interno com a lista; o botão de fechar fica solto no painel
	local corpo = novo("Frame", {
		Name = "Corpo",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ZIndex = 31,
	}, painel)
	padding(corpo, 16)
	novo("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) }, corpo)

	local function texto(ordem: number, fonte: Font, tam: number, cor: Color3): TextLabel
		return novo("TextLabel", {
			LayoutOrder = ordem,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Text = "",
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			FontFace = fonte,
			TextSize = tam,
			TextColor3 = cor,
			ZIndex = 31,
		}, corpo)
	end
	self.lblCabecalho = texto(1, f.label, 13, c.inkMuted)
	self.lblTitulo = texto(2, f.display, 24, c.ink)
	self.lblDetalhes = texto(3, f.body, 16, c.ink)
	self.lblDetalhes.LineHeight = 1.25

	-- opções de traçado
	self.opcoes = novo("Frame", {
		LayoutOrder = 4,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ZIndex = 31,
	}, corpo)
	novo("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) }, self.opcoes)

	local function botao(ordem: number, pai: Instance): TextButton
		local b = novo("TextButton", {
			LayoutOrder = ordem,
			Size = UDim2.new(1, 0, 0, 46),
			BackgroundColor3 = c.accent,
			Text = "",
			FontFace = f.display,
			TextSize = 17,
			TextColor3 = c.onAccent,
			TextWrapped = true,
			AutoButtonColor = true,
			ZIndex = 32,
		}, pai)
		if era.forma.canto > 0 then
			novo("UICorner", { CornerRadius = UDim.new(0, era.forma.canto) }, b)
		end
		return b
	end
	self.btnConstruir = botao(5, corpo)
	self.btnConstruir.Name = "BtnConstruir"
	self.lblMotivo = texto(6, f.body, 14, c.inkMuted)

	self.divTrens = novo("Frame", { LayoutOrder = 7, Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = c.rule, BorderSizePixel = 0, ZIndex = 31 }, corpo)
	self.lblTrens = texto(8, f.body, 16, c.ink)
	self.btnTrem = botao(9, corpo)
	self.btnTrem.Name = "BtnTrem"
	self.btnTrem.BackgroundColor3 = c.ink
	self.btnTrem.TextColor3 = c.panel
	self.btnTrem.Size = UDim2.new(1, 0, 0, 40)
	self.btnVender = botao(10, corpo)
	self.btnVender.Name = "BtnVenderTrem"
	self.btnVender.BackgroundColor3 = c.bg
	self.btnVender.TextColor3 = c.ink
	self.btnVender.TextSize = 15
	self.btnVender.Size = UDim2.new(1, 0, 0, 34)
	novo("UIStroke", { Color = c.rule, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, self.btnVender)
	self.divCarga = novo("Frame", { LayoutOrder = 12, Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = c.rule, BorderSizePixel = 0, ZIndex = 31 }, corpo)
	self.lblCarga = texto(13, f.body, 15, c.ink)
	self.lblCarga.LineHeight = 1.2

	self.btnFechar = novo("TextButton", {
		Name = "Fechar",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -6, 0, 6),
		Size = UDim2.fromOffset(32, 32),
		BackgroundTransparency = 1,
		Text = "X",
		FontFace = f.body,
		TextSize = 20,
		TextColor3 = c.inkMuted,
		ZIndex = 33,
	}, painel)

	self.btnConstruir.Activated:Connect(function()
		if self.estacaoAberta then
			self.aoAgir:Fire("melhorarEstacao", { estacao = self.estacaoAberta })
		elseif self.trechoAberto then
			self.aoAgir:Fire("construir", { trecho = self.trechoAberto, alternativa = self.alternativa })
		end
	end)
	self.btnTrem.Activated:Connect(function()
		local linha = self.trechoAberto and Economia.acharTrecho(self.dados, self.trechoAberto)
		if linha then
			self.aoAgir:Fire("trem", { linha = linha.id })
		end
	end)
	self.btnVender.Activated:Connect(function()
		local linha = self.trechoAberto and Economia.acharTrecho(self.dados, self.trechoAberto)
		if linha then
			self.aoAgir:Fire("venderTrem", { linha = linha.id })
		end
	end)
	self.btnFechar.Activated:Connect(function()
		self:fechar()
	end)

	return self
end

function Interface.destruir(self: Interface)
	self.hud:Destroy()
	self.aviso:Destroy()
	self.painel:Destroy()
	self.aoAgir:Destroy()
	self.aoFechar:Destroy()
end

function Interface.avisar(self: Interface, msg: string, segundos: number?)
	self.lblAviso.Text = msg
	self.aviso.Visible = true
	local marca = os.clock()
	self._marcaAviso = marca
	task.delay(segundos or 3, function()
		if self._marcaAviso == marca then
			self.aviso.Visible = false
		end
	end)
end

-- Avisos em fila (contrato cumprido, medalha, nível...): um de cada vez, sem um apagar o outro.
function Interface.enfileirar(self: Interface, msg: string, segundos: number?)
	table.insert(self._fila, { msg = msg, segundos = segundos or 4 })
	if self._rodandoFila then
		return
	end
	self._rodandoFila = true
	task.spawn(function()
		while #self._fila > 0 and self.aviso.Parent do
			local item = table.remove(self._fila, 1)
			self:avisar(item.msg, item.segundos)
			task.wait(item.segundos)
		end
		self._rodandoFila = false
	end)
end

function Interface.atualizarEstado(self: Interface, estado: any)
	self.estado = estado
	local simbolo = self.dados.simbolo
	local nivel = Economia.nivel(estado)
	self.lblNivel.Text = `{Emojis.nivel} Nível {nivel} · {Economia.tituloNivel(nivel)}`
	local contrato = estado.contrato
	self.lblContrato.Visible = contrato ~= nil
	if contrato then
		self.lblContrato.Text = `{Emojis.contratos} {Metas.progressoContrato(contrato)} · {Metas.relogio(contrato.prazo - contrato.decorrido)}`
	end
	self.lblDinheiro.Text = Economia.formatar(estado.dinheiro, simbolo)
	if estado.renda >= 0 then
		self.lblRenda.Text = `+ {Economia.formatar(estado.renda, simbolo, true)} por segundo`
		self.lblRenda.TextColor3 = self.era.cores.positive
	else
		-- manutenção maior que a receita
		self.lblRenda.Text = `− {Economia.formatar(-estado.renda, simbolo, true)} por segundo (prejuízo)`
		self.lblRenda.TextColor3 = self.era.cores.negative
	end
	local proxima, liberada = Economia.proximaEra(estado, self.dados)
	local eraProx = proxima and self.eras and self.eras[proxima.id]
	if proxima and liberada and eraProx then
		local podePagar = estado.dinheiro >= proxima.custo
		self.btnEra.Visible = true
		self.btnEra.Text = `{Emojis.era_diesel} <b>Modernizar: {eraProx.nome}</b>\nRenda ×{proxima.multiplicador} nas linhas · {Economia.formatar(proxima.custo, simbolo)}`
		self.btnEra.Active = podePagar
		self.btnEra.AutoButtonColor = podePagar
		self.btnEra.BackgroundTransparency = if podePagar then 0 else 0.55
	else
		self.btnEra.Visible = false
	end
	if estado.ganhoOffline and estado.ganhoOffline > 0.5 then
		self:avisar(`{Emojis.relogio} Enquanto você esteve fora, seus trens renderam {Economia.formatar(estado.ganhoOffline, simbolo)}`, 6)
	end
	if self.trechoAberto then
		self:_preencher()
	elseif self.estacaoAberta then
		self:_preencherEstacao()
	end
end

function Interface._modoTrecho(self: Interface, sim: boolean)
	self.divTrens.Visible = sim
	self.lblTrens.Visible = sim
	if not sim then
		self.btnTrem.Visible = false
		self.btnVender.Visible = false
		self.opcoes.Visible = false
		self.divCarga.Visible = false
		self.lblCarga.Visible = false
	end
end

local PORTES = { "Vila", "Cidade", "Cidade grande", "Capital regional", "Metrópole" }

function Interface.abrirEstacao(self: Interface, estacaoId: string)
	self.trechoAberto = nil
	self.estacaoAberta = estacaoId
	self.painel.Visible = true
	self:_modoTrecho(false)
	self:_preencherEstacao()
end

function Interface._preencherEstacao(self: Interface)
	local estado, dados = self.estado, self.dados
	local id = self.estacaoAberta
	if not estado or not id then
		return
	end
	local simbolo = dados.simbolo
	local e = dados.estacoes[id]
	local nivel = Economia.nivelEstacao(estado, id)
	local naRede = Economia.estacaoNaRede(estado, dados, id)

	self.lblCabecalho.Text = `ESTAÇÃO · {maiusculas(PORTES[e.porte] or "")}{if e.porto then " · PORTO" else ""}`
	self.lblTitulo.Text = e.nome
	local linhas = {}
	for i, def in Economia.NIVEIS_ESTACAO do
		local marca = if i <= nivel then Emojis.confirmar elseif i == nivel + 1 then Emojis.mais else Emojis.cadeado
		table.insert(linhas, `{marca} {def.nome}`)
	end
	table.insert(linhas, "")
	table.insert(linhas, `{Emojis.renda} Bônus atual: +{math.round(nivel * Economia.BONUS_POR_NIVEL * 100)}% na renda dos trechos que chegam aqui`)
	if e.produz and Economia.CARGAS[e.produz] then
		local def = Economia.CARGAS[e.produz]
		local conectada = Economia.conectadasAoPorto(estado, dados)[id]
		table.insert(linhas, `{(Emojis :: any)[def.emoji]} Produz {string.lower(def.nome)}{if conectada then " (chegando a um porto)" else " (sem trilho até um porto)"}`)
	end
	self.lblDetalhes.Text = table.concat(linhas, "\n")

	local custo = Economia.custoMelhoria(estado, dados, id)
	if not naRede then
		self.btnConstruir.Text = `{Emojis.cadeado} Fora da rede`
		self.lblMotivo.Text = "Construa um trecho até esta estação para poder melhorá-la."
		self.btnConstruir.Active, self.btnConstruir.AutoButtonColor, self.btnConstruir.BackgroundTransparency = false, false, 0.6
	elseif not custo then
		self.btnConstruir.Text = `{Emojis.prestigio} Nível máximo`
		self.lblMotivo.Text = ""
		self.btnConstruir.Active, self.btnConstruir.AutoButtonColor, self.btnConstruir.BackgroundTransparency = false, false, 0.6
	else
		local proximo = Economia.NIVEIS_ESTACAO[nivel + 1].nome
		local podePagar = estado.dinheiro >= custo
		self.btnConstruir.Text = `{Emojis.melhorar} {proximo} · {Economia.formatar(custo, simbolo)}`
		self.lblMotivo.Text = if podePagar then `+{math.round(Economia.BONUS_POR_NIVEL * 100)}% na renda dos trechos desta estação.` else `Faltam {Economia.formatar(custo - estado.dinheiro, simbolo)}.`
		self.btnConstruir.Active, self.btnConstruir.AutoButtonColor = podePagar, podePagar
		self.btnConstruir.BackgroundTransparency = if podePagar then 0 else 0.6
	end
	self.lblMotivo.Visible = self.lblMotivo.Text ~= ""
end

function Interface.abrir(self: Interface, trechoId: string)
	if self.trechoAberto ~= trechoId then
		self.alternativa = nil
	end
	self.estacaoAberta = nil
	self:_modoTrecho(true)
	self.trechoAberto = trechoId
	self.painel.Visible = true
	self:_preencher()
end

function Interface.fechar(self: Interface)
	self.trechoAberto = nil
	self.estacaoAberta = nil
	self.painel.Visible = false
	self.aoFechar:Fire()
end

function Interface._preencher(self: Interface)
	local estado, dados, c = self.estado, self.dados, self.era.cores
	if not estado or not self.trechoAberto then
		return
	end
	local simbolo = dados.simbolo
	local linha, iLinha, trecho, iTrecho = Economia.acharTrecho(dados, self.trechoAberto)
	if not trecho then
		return
	end
	local situacao = Economia.situacaoTrecho(estado, dados, iLinha, iTrecho)
	local escolhida = estado.trechos[trecho.id] or self.alternativa
	local opcao = Economia.opcaoTrecho(trecho, escolhida)
	local terreno = dados.terrenos[opcao.terreno or trecho.terreno]
	local de, para = dados.estacoes[trecho.de].nome, dados.estacoes[trecho.para].nome

	self.lblCabecalho.Text = `{maiusculas(linha.nome)} · {trecho.ano}`
	self.lblTitulo.Text = `{de} – {para}`
	local fatorRede = Economia.bonusRede(estado, dados, linha)
	local passageiros = Economia.passageirosTrecho(estado, dados, trecho, fatorRede)
	if not estado.trechos[trecho.id] then
		-- antes de construir: previsão com a escolha de traçado atual
		local opcaoPrev = Economia.opcaoTrecho(trecho, escolhida)
		passageiros = Economia.PASSAGEIROS_POR_PESO * Economia.pesoTrecho(dados, trecho) * (opcaoPrev.fatorDemanda or 1)
	end
	local era = Economia.multiplicadorEra(estado)
	local estA, estB = dados.estacoes[trecho.de], dados.estacoes[trecho.para]
	self.lblDetalhes.Text = table.concat({
		`{Emojis.distancia} Extensão: {opcao.km} km`,
		`{Emojis.terreno_montanha} Terreno: {terreno.nome} (custo ×{string.format("%.1f", terreno.custo):gsub("%.", ",")})`,
		`{Emojis.passageiros} Demanda: {Economia.numero(passageiros)} passageiros/h (cidades de porte {estA.porte} e {estB.porte})`,
		`{Emojis.renda} Receita: + {Economia.formatar(Economia.rendaTrecho(dados, trecho, escolhida) * era, simbolo, true)}/s{if era > 1 then ` (×{era} da era)` else ""}`,
		`{Emojis.manutencao} Manutenção: − {Economia.formatar(Economia.manutencaoTrecho(trecho, escolhida), simbolo, true)}/s`,
	}, "\n")

	-- opções de traçado (só antes de construir). Só recria os botões quando algo muda,
	-- senão um clique poderia cair num botão que acabou de ser destruído.
	local temOpcoes = trecho.alternativas ~= nil and situacao ~= "construido"
	self.opcoes.Visible = temOpcoes
	local chaveOpcoes = `{trecho.id}|{self.alternativa or ""}|{situacao}|{temOpcoes}`
	if chaveOpcoes ~= self._chaveOpcoes then
		self._chaveOpcoes = chaveOpcoes
		for _, filho in self.opcoes:GetChildren() do
			if filho:IsA("TextButton") then
				filho:Destroy()
			end
		end
	else
		temOpcoes = false -- já estão desenhadas
	end
	if temOpcoes then
		local atual = self.alternativa or trecho.alternativas[1].id
		for i, alt in trecho.alternativas do
			local sel = alt.id == atual
			local b = Instance.new("TextButton")
			b.LayoutOrder = i
			b.Size = UDim2.new(1, 0, 0, 0)
			b.AutomaticSize = Enum.AutomaticSize.Y
			b.BackgroundColor3 = if sel then c.accent else c.bg
			b.BackgroundTransparency = if sel then 0.82 else 0
			b.TextXAlignment = Enum.TextXAlignment.Left
			b.TextWrapped = true
			b.RichText = true
			b.FontFace = self.era.fontes.body
			b.TextSize = 15
			b.TextColor3 = c.ink
			b.ZIndex = 32
			b.Text = `<b>{if sel then "● " else "○ "}{alt.nome}</b>\n{alt.descricao}\n{alt.km} km · {Economia.formatar(alt.custo, simbolo)}`
			local pad = Instance.new("UIPadding")
			pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 8), UDim.new(0, 8)
			pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 6), UDim.new(0, 6)
			pad.Parent = b
			local borda = Instance.new("UIStroke")
			borda.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			borda.Color = if sel then c.accent else c.rule
			borda.Thickness = if sel then 2 else 1
			borda.Parent = b
			b.Parent = self.opcoes
			b.Activated:Connect(function()
				self.alternativa = alt.id
				self:_preencher()
			end)
		end
	end

	-- botão principal
	local custo = opcao.custo
	if situacao == "construido" then
		self.btnConstruir.Text = `{Emojis.confirmar} Trecho construído`
		self.btnConstruir.Active = false
		self.btnConstruir.AutoButtonColor = false
		self.btnConstruir.BackgroundTransparency = 0.6
		self.lblMotivo.Text = ""
	elseif situacao == "projeto" then
		self.btnConstruir.Text = `{Emojis.gabinete} Ainda é só um projeto`
		self.btnConstruir.Active = false
		self.btnConstruir.AutoButtonColor = false
		self.btnConstruir.BackgroundTransparency = 0.6
		self.lblMotivo.Text = "Estude este projeto no Gabinete (menu de baixo) para liberar a construção."
	elseif situacao == "bloqueado" then
		self.btnConstruir.Text = `{Emojis.cadeado} Ainda fechado`
		self.btnConstruir.Active = false
		self.btnConstruir.AutoButtonColor = false
		self.btnConstruir.BackgroundTransparency = 0.6
		if not Economia.linhaLiberada(estado, dados, iLinha) then
			self.lblMotivo.Text = `Para liberar, complete antes: {table.concat(Economia.faltaParaLiberar(estado, dados, iLinha), ", ")}.`
		else
			self.lblMotivo.Text = "Construa antes o trecho anterior desta linha."
		end
	else
		local podePagar = estado.dinheiro >= custo
		self.btnConstruir.Text = `{Emojis.assinar} Assinar concessão · {Economia.formatar(custo, simbolo)}`
		self.btnConstruir.Active = podePagar
		self.btnConstruir.AutoButtonColor = podePagar
		self.btnConstruir.BackgroundTransparency = if podePagar then 0 else 0.6
		self.lblMotivo.Text = if podePagar then "" else `Faltam {Economia.formatar(custo - estado.dinheiro, simbolo)}.`
	end
	self.lblMotivo.Visible = self.lblMotivo.Text ~= ""

	-- trens da linha: a frota tem que levar os passageiros; trem a mais só custa manutenção
	local construidos = Economia.trechosConstruidos(estado, linha)
	local trens = estado.trens[linha.id] or 0
	local faltando = Economia.trensFaltando(estado, dados, linha)
	local sobrando = Economia.trensSobrando(estado, dados, linha)
	local demanda = Economia.passageirosLinha(estado, dados, linha)
	local capacidade = trens * Economia.capacidadeTrem(estado)
	local servico = math.round(Economia.servico(estado, dados, linha) * 100)
	local custoTrem = Economia.custoTrem(estado, linha)
	local manutTrem = Economia.formatar(Economia.manutencaoTrem(estado, linha), simbolo, true)
	local fmt = Economia.numero
	self.btnVender.Visible = false
	if construidos == 0 then
		self.lblTrens.Text = `{Emojis.trens} O primeiro trem vem junto com o primeiro trecho. Cada trem leva {fmt(Economia.capacidadeTrem(estado))} passageiros/h.`
		self.lblTrens.TextColor3 = c.inkMuted
		self.btnTrem.Visible = false
	else
		local linhaFrota = `{Emojis.trens} Frota: {trens} {if trens == 1 then "trem" else "trens"} · leva {fmt(capacidade)} de {fmt(demanda)} passageiros/h`
		if faltando > 0 then
			self.lblTrens.Text = `{linhaFrota}\n{Emojis.alerta} Lotado: só {servico}% dos passageiros embarcam. Faltam {faltando} {if faltando == 1 then "trem" else "trens"} (cada um custa {manutTrem}/s de manutenção).`
			self.lblTrens.TextColor3 = c.negative
		elseif sobrando > 0 then
			self.lblTrens.Text = `{linhaFrota}\n{Emojis.alerta} {sobrando} {if sobrando == 1 then "trem rodando vazio" else "trens rodando vazios"}: cada um custa {manutTrem}/s de manutenção.`
			self.lblTrens.TextColor3 = c.negative
		else
			self.lblTrens.Text = `{linhaFrota}\n{Emojis.confirmar} Todos os passageiros embarcam.`
			self.lblTrens.TextColor3 = c.positive
		end
		self.btnTrem.Visible = faltando > 0
		if faltando > 0 then
			local podePagar = estado.dinheiro >= custoTrem
			self.btnTrem.Text = `{Emojis.trens} Comprar trem · {Economia.formatar(custoTrem, simbolo)}`
			self.btnTrem.Active = podePagar
			self.btnTrem.AutoButtonColor = podePagar
			self.btnTrem.BackgroundTransparency = if podePagar then 0 else 0.6
		end
		if Economia.podeVenderTrem(estado, linha) then
			self.btnVender.Visible = true
			self.btnVender.Text = `Vender 1 trem · + {Economia.formatar(Economia.valorVendaTrem(estado, linha), simbolo)}`
		end
	end

	-- cargas desta linha
	local cargas = Economia.cargasPorLinha(estado, dados)[linha.id]
	local linhasTexto = {}
	for _, info in cargas do
		local def = Economia.CARGAS[info.carga]
		local emoji = (Emojis :: any)[def.emoji] or ""
		local nome = dados.estacoes[info.estacao].nome
		if info.conectada then
			table.insert(linhasTexto, `{emoji} {def.nome} de {nome} chega a um porto: +{math.round(def.bonus * 100)}% na renda`)
		else
			table.insert(linhasTexto, `{emoji} {def.nome} de {nome} ainda sem trilho até um porto`)
		end
	end
	local temCarga = #linhasTexto > 0
	self.divCarga.Visible = temCarga
	self.lblCarga.Visible = temCarga
	self.lblCarga.Text = table.concat(linhasTexto, "\n")
end

return Interface
