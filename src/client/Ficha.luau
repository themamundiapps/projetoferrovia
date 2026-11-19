--!strict
-- Ficha da cidade: painel à direita com imagem, números, estação, linhas, porto/produção e história.
-- Abre ao tocar numa estação. A estrutura é montada uma vez por cidade; a cada segundo só os valores mudam.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Economia = require(Shared:WaitForChild("Economia"))
local Emojis = require(Shared:WaitForChild("Emojis"))
local Idioma = require(Shared:WaitForChild("Idioma"))
local Assets = require(Shared:WaitForChild("Assets"))
local Estilo = require(script.Parent:WaitForChild("Estilo"))

local novo = Estilo.novo
local T = Idioma.T

local Ficha = {}
Ficha.__index = Ficha

export type Ficha = typeof(setmetatable({} :: any, Ficha))

local LARGURA = 340
local MARGEM = 14
-- Emoji do espaço reservado, enquanto a cidade não tem imagem.
local EMOJI_PAISAGEM = {
	cafe = "carga_cafe",
	serra = "terreno_montanha",
	litoral = "terreno_ponte",
	canavial = "carga_acucar",
	sertao = "carga_gado",
	sul = "carga_madeira",
	cerrado = "carga_graos",
	amazonia = "terreno_floresta",
}

function Ficha.new(tela: ScreenGui, era: any, dados: any): Ficha
	local est = Estilo.new(era)
	local self = setmetatable({}, Ficha)
	self.est = est
	self.tela = tela
	self.dados = dados
	self.estado = nil :: any
	self.aberta = nil :: string?
	self.aoAgir = Instance.new("BindableEvent") -- (tipo, args)
	self.aoFechar = Instance.new("BindableEvent")
	self.aoFocarLinha = Instance.new("BindableEvent") -- (linhaId)
	self._chave = ""
	self._vivo = nil :: (() -> ())?

	local painel = est:caixa({
		Name = "Ficha",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -Estilo.MARGEM_LATERAL, 0, Estilo.TOPO_TELA + 12),
		Size = UDim2.fromOffset(LARGURA, 300),
		Visible = false,
		ClipsDescendants = true,
	}, tela)
	self.painel = painel

	local rolagem = novo("ScrollingFrame", {
		Name = "Rolagem",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 5,
		ScrollBarImageColor3 = est.c.inkMuted,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ZIndex = 31,
	}, painel)
	est:padding(rolagem, MARGEM)
	local lista = est:lista(rolagem, 10)
	self.rolagem = rolagem

	local fechar = novo("TextButton", {
		Name = "Fechar",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -6, 0, 6),
		Size = UDim2.fromOffset(36, 36),
		BackgroundTransparency = 1,
		Text = "X",
		FontFace = est.f.body,
		TextSize = 20,
		TextColor3 = est.c.inkMuted,
		ZIndex = 36,
	}, painel)
	fechar.Activated:Connect(function()
		self:fechar()
	end)

	-- o painel tem a altura do conteúdo, até o limite da tela (acima dos botões de zoom); daí em diante, rola
	local function ajustarAltura()
		local limite = math.max(200, Estilo.px(tela.AbsoluteSize.Y) - (Estilo.TOPO_TELA + 12) - 132)
		painel.Size = UDim2.fromOffset(LARGURA, math.min(lista.AbsoluteContentSize.Y + 2 * MARGEM, limite))
	end
	self.conexoes = {
		lista:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(ajustarAltura),
		tela:GetPropertyChangedSignal("AbsoluteSize"):Connect(ajustarAltura),
	}

	return self
end

function Ficha.destruir(self: Ficha)
	for _, c in self.conexoes do
		c:Disconnect()
	end
	self.painel:Destroy()
	self.aoAgir:Destroy()
	self.aoFechar:Destroy()
	self.aoFocarLinha:Destroy()
end

function Ficha.abrir(self: Ficha, id: string)
	if not self.dados.estacoes[id] then
		return
	end
	self.aberta = id
	self._chave = ""
	self.rolagem.CanvasPosition = Vector2.zero
	self.painel.Visible = true
	self:_atualizar()
end

function Ficha.fechar(self: Ficha)
	if not self.aberta then
		return
	end
	self.aberta = nil
	self.painel.Visible = false
	self.aoFechar:Fire()
end

function Ficha.atualizarEstado(self: Ficha, estado: any)
	self.estado = estado
	if self.aberta then
		self:_atualizar()
	end
end

-- Situação de cada linha que passa pela cidade: "desde 1858", "projeto", "a construir" ou "fechada".
local function linhasDaCidade(estado: any, dados: any, id: string): { any }
	local lista = {}
	for i, linha in dados.linhas do
		local passa, desde = false, nil
		for _, t in linha.trechos do
			if t.de == id or t.para == id then
				passa = true
				if estado.trechos[t.id] and (not desde or t.ano < desde) then
					desde = t.ano
				end
			end
		end
		if passa then
			local situacao = if desde then T("ficha_desde", desde)
				elseif linha.projeto and not Economia.projetoConcluido(estado, linha.projeto) then T("ficha_projeto")
				elseif Economia.linhaLiberada(estado, dados, i) then T("ficha_a_construir")
				else T("ficha_fechada")
			table.insert(lista, { linha = linha, situacao = situacao, construida = desde ~= nil, projeto = linha.projeto ~= nil and desde == nil })
		end
	end
	return lista
end

function Ficha._atualizar(self: Ficha)
	local estado, dados, id = self.estado, self.dados, self.aberta
	if not estado or not id then
		return
	end
	-- a estrutura só é refeita quando muda a cidade ou a situação das linhas dela
	local linhas = linhasDaCidade(estado, dados, id)
	local partes = { id }
	for _, l in linhas do
		table.insert(partes, l.linha.id .. l.situacao)
	end
	local chave = table.concat(partes, "|")
	if chave ~= self._chave then
		self._chave = chave
		self:_montar(id, linhas)
	end
	if self._vivo then
		self._vivo()
	end
end

function Ficha._montar(self: Ficha, id: string, linhas: { any })
	local est, dados, r = self.est, self.dados, self.rolagem
	local c, f = est.c, est.f
	for _, filho in r:GetChildren() do
		if filho:IsA("GuiObject") then
			filho:Destroy()
		end
	end
	local e = dados.estacoes[id]
	local simbolo = dados.simbolo
	local larguraUtil = LARGURA - 2 * MARGEM

	local function secao(nome: string, ordem: number): Frame
		local bloco = novo("Frame", {
			Name = "Secao_" .. nome,
			LayoutOrder = ordem,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			ZIndex = 31,
		}, r)
		est:lista(bloco, 6)
		local titulo = est:texto("rotulo", nome, bloco, 1)
		titulo.TextSize = 12
		est:divisor(bloco, 2)
		return bloco
	end

	-- cabeçalho
	local cabecalho = novo("Frame", {
		Name = "Cabecalho",
		LayoutOrder = 1,
		Size = UDim2.new(1, -30, 0, 0), -- espaço para o X
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ZIndex = 31,
	}, r)
	est:lista(cabecalho, 2)
	local tipo = { T("porte_" .. e.porte) }
	if e.porto then
		table.insert(tipo, T("ficha_porto"))
	end
	if e.produz then
		table.insert(tipo, T("ficha_produtora"))
	end
	local lTipo = est:texto("rotulo", Idioma.maiusculas(table.concat(tipo, " · ")), cabecalho, 1)
	lTipo.TextSize = 12
	local lNome = est:texto("titulo", e.nome, cabecalho, 2)
	lNome.Name = "Nome"
	est:texto("fraco", `{e.estado} · {Idioma.t(dados.regioes[e.regiao])}`, cabecalho, 3)

	-- imagem (16:9)
	local moldura = novo("Frame", {
		Name = "Imagem",
		LayoutOrder = 2,
		Size = UDim2.new(1, 0, 0, math.round(larguraUtil * 9 / 16)),
		BackgroundColor3 = c.land,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 31,
	}, r)
	novo("UIStroke", { Color = c.ink, Thickness = 1.5 }, moldura)
	est:cantos(moldura)
	local imagem = (Assets.Cidades :: any)[id] or (Assets.Paisagens :: any)[e.paisagem or ""]
	if imagem then
		local img = novo("ImageLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Image = imagem,
			ScaleType = Enum.ScaleType.Crop,
			ZIndex = 32,
		}, moldura)
		est:cantos(img)
	else
		novo("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = (Emojis :: any)[EMOJI_PAISAGEM[e.paisagem or ""] or "estacoes"] or "",
			TextSize = 48,
			TextTransparency = 0.45,
			ZIndex = 32,
		}, moldura)
	end

	-- três números
	local numeros = novo("Frame", {
		Name = "Numeros",
		LayoutOrder = 3,
		Size = UDim2.new(1, 0, 0, 72),
		BackgroundTransparency = 1,
		ZIndex = 31,
	}, r)
	est:lista(numeros, 8, true)
	local function numero(nome: string, ordem: number): (TextLabel, TextLabel)
		local celula = novo("Frame", {
			Name = nome,
			LayoutOrder = ordem,
			Size = UDim2.new(1 / 3, -6, 1, 0),
			BackgroundTransparency = 1,
			ZIndex = 31,
		}, numeros)
		novo("UIStroke", { Color = c.rule, Thickness = 1 }, celula)
		est:cantos(celula)
		est:padding(celula, 7, 6)
		est:lista(celula, 1)
		local l = est:texto("rotulo", nome, celula, 1)
		l.TextSize = 11
		local valor = est:texto("subtitulo", "", celula, 2)
		valor.TextSize = 17
		valor.TextWrapped = false
		local pe = est:texto("fraco", "", celula, 3)
		pe.TextSize = 12
		return valor, pe
	end
	local vPop, pPop = numero(T("ficha_populacao"), 1)
	local vPas, pPas = numero(T("ficha_passageiros"), 2)
	local vRede, pRede = numero(T("ficha_rede"), 3)
	pPop.Text = T("ficha_habitantes")
	pRede.Text = T("ficha_cidades_ligadas")

	-- estação
	local sEstacao = secao(T("ficha_estacao"), 4)
	local linhaNivel = novo("Frame", {
		LayoutOrder = 3,
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		ZIndex = 31,
	}, sEstacao)
	est:lista(linhaNivel, 4, true)
	local quadrados: { Frame } = {}
	local contornos: { UIStroke } = {}
	for i = 1, #Economia.NIVEIS_ESTACAO do
		local q = novo("Frame", {
			LayoutOrder = i,
			Size = UDim2.fromOffset(14, 14),
			BackgroundColor3 = c.ink,
			BorderSizePixel = 0,
			ZIndex = 32,
		}, linhaNivel)
		est:cantos(q)
		quadrados[i] = q
		contornos[i] = novo("UIStroke", { Color = c.rule, Thickness = 1 }, q)
	end
	local lNivel = novo("TextLabel", {
		LayoutOrder = 10,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundTransparency = 1,
		RichText = true,
		Text = "",
		FontFace = f.body,
		TextSize = 15,
		TextColor3 = c.ink,
		ZIndex = 32,
	}, linhaNivel)
	novo("UIPadding", { PaddingLeft = UDim.new(0, 6) }, lNivel)
	local lBonus = est:texto("fraco", "", sEstacao, 4)
	local lLotada = est:texto("fraco", "", sEstacao, 5)
	lLotada.TextColor3 = c.negative
	local botao = est:botao("principal", "", sEstacao, 6)
	botao.Name = "BtnMelhorar"
	botao.Size = UDim2.new(1, 0, 0, 46)
	botao.Activated:Connect(function()
		self.aoAgir:Fire("melhorarEstacao", { estacao = id })
	end)
	local lMotivo = est:texto("fraco", "", sEstacao, 7)

	-- linhas que passam pela cidade (tocar numa linha mostra ela no mapa)
	if #linhas > 0 then
		local sLinhas = secao(T("ficha_linhas"), 5)
		for i, l in linhas do
			local cor: Color3 = est.era.linhas[l.linha.cor] or c.ink
			local b = novo("TextButton", {
				Name = "Linha_" .. l.linha.id,
				LayoutOrder = 2 + i,
				Size = UDim2.new(1, 0, 0, 28),
				BackgroundColor3 = c.bg,
				BackgroundTransparency = 1,
				AutoButtonColor = false,
				Text = "",
				ZIndex = 32,
			}, sLinhas)
			if l.projeto then
				-- tracejado, como no mapa
				for k = 0, 2 do
					novo("Frame", {
						AnchorPoint = Vector2.new(0, 0.5),
						Position = UDim2.new(0, k * 7, 0.5, 0),
						Size = UDim2.fromOffset(5, 3),
						BackgroundColor3 = cor,
						BorderSizePixel = 0,
						ZIndex = 33,
					}, b)
				end
			else
				local amostra = novo("Frame", {
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 0, 0.5, 0),
					Size = UDim2.fromOffset(19, 6),
					BackgroundColor3 = cor,
					BackgroundTransparency = if l.construida then 0 else 0.6,
					BorderSizePixel = 0,
					ZIndex = 33,
				}, b)
				novo("UIStroke", { Color = c.ink, Thickness = 1, Transparency = if l.construida then 0 else 0.6 }, amostra)
			end
			novo("TextLabel", {
				Position = UDim2.fromOffset(28, 0),
				Size = UDim2.new(1, -118, 1, 0),
				BackgroundTransparency = 1,
				Text = l.linha.nome,
				FontFace = if l.construida then Font.new(f.body.Family, Enum.FontWeight.SemiBold) else f.body,
				TextSize = 15,
				TextColor3 = if l.construida then c.ink else c.inkMuted,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				ZIndex = 33,
			}, b)
			novo("TextLabel", {
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.fromScale(1, 0),
				Size = UDim2.new(0, 88, 1, 0),
				BackgroundTransparency = 1,
				Text = l.situacao,
				FontFace = f.label,
				TextSize = 12,
				TextColor3 = c.inkMuted,
				TextXAlignment = Enum.TextXAlignment.Right,
				ZIndex = 33,
			}, b)
			b.Activated:Connect(function()
				self.aoFocarLinha:Fire(l.linha.id)
			end)
		end
	end

	-- porto e produção
	local lPorto: TextLabel? = nil
	if e.porto then
		lPorto = est:texto("corpo", "", secao(T("ficha_secao_porto"), 6), 3)
	end
	local lProducao: TextLabel? = nil
	if e.produz and (Economia.CARGAS :: any)[e.produz] then
		lProducao = est:texto("corpo", "", secao(T("ficha_producao"), 7), 3)
	end

	-- história
	local lHistoria = est:texto("corpo", Idioma.t(e.historia), secao(T("ficha_historia"), 8), 3)
	lHistoria.FontFace = Font.new(f.body.Family, Enum.FontWeight.Regular, Enum.FontStyle.Italic)
	lHistoria.LineHeight = 1.15

	-- valores que mudam com o jogo
	self._vivo = function()
		local estado = self.estado
		local rede = Economia.rede(estado, dados)
		local naRede = Economia.estacaoNaRede(estado, dados, id)
		local mov = Economia.movimentoEstacao(estado, dados, id, rede)
		local nivel = Economia.nivelEstacao(estado, id)
		local maximo = #Economia.NIVEIS_ESTACAO
		local porNivel = math.round(Economia.BONUS_POR_NIVEL * 100)

		vPop.Text = Economia.numero(Economia.populacao(estado, dados, id))
		if naRede then
			vPas.Text = T("ficha_por_hora", Economia.numero(math.round(mov.passageiros)))
			if mov.servico >= 1 then
				pPas.Text = T("ficha_todos_embarcam")
				pPas.TextColor3 = c.positive
			else
				pPas.Text = T("ficha_so_embarcam", math.floor(mov.servico * 100))
				pPas.TextColor3 = c.negative
			end
		else
			vPas.Text = "–"
			pPas.Text = T("ficha_fora_da_rede")
			pPas.TextColor3 = c.inkMuted
		end
		vRede.Text = tostring(mov.cidadesLigadas)

		-- quadradinhos: cheios até o nível atual, o próximo em destaque
		for i, q in quadrados do
			q.BackgroundTransparency = if i <= nivel then 0 else 1
			contornos[i].Color = if i <= nivel then c.ink elseif i == nivel + 1 then c.accent else c.rule
			contornos[i].Thickness = if i == nivel + 1 then 2 else 1
		end
		local nomeNivel = if nivel > 0 then Economia.NIVEIS_ESTACAO[nivel].nome else T("ficha_parada_simples")
		lNivel.Text = `<b>{nomeNivel}</b> · {T("ficha_nivel", nivel, maximo)}`
		local bonus = if nivel > 0 then T("ficha_bonus_atual", nivel * porNivel) else T("ficha_sem_melhorias")
		if nivel < maximo then
			bonus ..= " " .. T("ficha_proxima", Economia.NIVEIS_ESTACAO[nivel + 1].nome, (nivel + 1) * porNivel)
		end
		lBonus.Text = bonus
		local lotada = mov.linhaLotada ~= nil and mov.trensFaltando > 0
		lLotada.Visible = lotada
		if lotada then
			lLotada.Text = `{Emojis.alerta} {T("ficha_lotada", mov.trensFaltando, mov.linhaLotada.nome)}`
		end

		local custo = Economia.custoMelhoria(estado, dados, id)
		if not naRede then
			botao.Text = `{Emojis.cadeado} {T("ficha_botao_fora")}`
			est:habilitar(botao, false)
			lMotivo.Text = T("ficha_motivo_fora")
		elseif not custo then
			botao.Text = `{Emojis.prestigio} {T("ficha_nivel_maximo")}`
			est:habilitar(botao, false)
			lMotivo.Text = ""
		else
			local podePagar = estado.dinheiro >= custo
			botao.Text = `{Emojis.melhorar} {Economia.NIVEIS_ESTACAO[nivel + 1].nome} · {Economia.formatar(custo, simbolo)}`
			est:habilitar(botao, podePagar)
			lMotivo.Text = if podePagar then "" else T("ficha_faltam", Economia.formatar(custo - estado.dinheiro, simbolo))
		end
		lMotivo.Visible = lMotivo.Text ~= ""

		if lPorto then
			-- cidades produtoras ligadas por trilho a este porto
			local comp = rede.componente[id]
			local chegam = {}
			if comp then
				for outraId, outra in dados.estacoes do
					local carga = outra.produz and (Economia.CARGAS :: any)[outra.produz]
					if carga and rede.componente[outraId] == comp then
						table.insert(chegam, `{(Emojis :: any)[carga.emoji] or ""} {outra.nome}`)
					end
				end
				table.sort(chegam)
			end
			lPorto.Text = if #chegam > 0 then `{T("ficha_cargas_chegam")}\n{table.concat(chegam, " · ")}` else T("ficha_sem_cargas")
			lPorto.TextColor3 = if #chegam > 0 then c.ink else c.inkMuted
		end
		if lProducao then
			local carga = (Economia.CARGAS :: any)[e.produz]
			local porDia = e.porte * ((Economia.PRODUCAO_POR_PORTE :: any)[e.produz] or 0) * (1 + Economia.BONUS_POR_NIVEL * nivel)
			local texto = `{(Emojis :: any)[carga.emoji] or ""} {T("ficha_produz", carga.nome, Economia.numero(math.round(porDia)), carga.unidade)}`
			-- em qual linha a carga conta (a primeira linha construída que passa aqui) e se chega a um porto
			local situacao = T("ficha_sem_porto")
			local cor = c.inkMuted
			local v = (Economia.valorCargas(estado, dados))[id]
			if v and v.conectada then
				for _, linha in dados.linhas do
					if linha.id == v.linha then
						situacao = T("ficha_chega_ao_porto", math.round(carga.bonus * 100), linha.nome)
						cor = c.positive
					end
				end
				if v.unidadesDia > 0 then
					situacao ..= "\n" .. T("ficha_frete", Economia.formatar(v.preco, simbolo, true), (carga.unidade:gsub("s$", "")), Economia.formatar(v.reaisDia, simbolo))
				end
			elseif v and v.reaisDia > 0 then
				situacao ..= " " .. T("ficha_renderia", Economia.formatar(v.reaisDia, simbolo))
			end
			lProducao.Text = `{texto}\n<font color="#{cor:ToHex()}">{situacao}</font>`
		end
	end
end

return Ficha
