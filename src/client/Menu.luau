--!strict
-- Menu: barra inferior (Linhas, Companhia, Ajustes), o painel lateral de cada uma e os botões de zoom.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Economia = require(Shared:WaitForChild("Economia"))
local Emojis = require(Shared:WaitForChild("Emojis"))
local Estilo = require(script.Parent:WaitForChild("Estilo"))

local novo = Estilo.novo

local Menu = {}
Menu.__index = Menu

export type Menu = typeof(setmetatable({} :: any, Menu))

local ABAS = {
	{ id = "linhas", nome = "Linhas", emoji = "linhas" },
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
	self.ajustes = { nomesEstacoes = true, nomesMapa = true }
	self.aoAgir = Instance.new("BindableEvent") -- (tipo, args)
	self.aoFocarLinha = Instance.new("BindableEvent") -- (linhaId)
	self.aoAjuste = Instance.new("BindableEvent") -- (chave, valor)
	self.aoZoom = Instance.new("BindableEvent") -- (fator)
	self.instancias = {} :: { Instance }

	-- ---------------------------------------------------- barra inferior
	local barra = est:caixa({
		Name = "BarraMenu",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -14),
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.fromOffset(0, 0),
	}, tela)
	est:padding(barra, 6)
	est:lista(barra, 6, true)
	table.insert(self.instancias, barra)
	self.botoesAba = {} :: { [string]: TextButton }
	for i, aba in ABAS do
		local b = est:botao("discreto", `{(Emojis :: any)[aba.emoji]} {aba.nome}`, barra, i)
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
		local b = est:botao("discreto", rotulo, zoom, i)
		b.Name = if i == 1 then "ZoomMais" else "ZoomMenos"
		b.Size = UDim2.fromOffset(46, 46)
		b.BackgroundColor3 = est.c.panel
		b.TextSize = 24
		b.Activated:Connect(function()
			self.aoZoom:Fire(fatores[i])
		end)
	end

	-- ---------------------------------------------------- painel lateral (conteúdo da aba)
	local painel = est:caixa({
		Name = "PainelMenu",
		Position = UDim2.fromOffset(16, 150),
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
	self.aoFocarLinha:Destroy()
	self.aoAjuste:Destroy()
	self.aoZoom:Destroy()
end

-- Coloca o painel lateral logo abaixo de uma posição Y da tela (abaixo do caixa da companhia).
function Menu.posicionarAbaixoDe(self: Menu, y: number)
	self.painel.Position = UDim2.fromOffset(16, y + 10)
	self.painel.Size = UDim2.new(0, 330, 1, -(y + 10) - 90)
end

function Menu.abrirAba(self: Menu, aba: string?)
	self.aba = aba
	self.painel.Visible = aba ~= nil
	local c = self.est.c
	for id, b in self.botoesAba do
		local ativo = id == aba
		b.BackgroundColor3 = if ativo then c.ink else c.bg
		b.TextColor3 = if ativo then c.panel else c.ink
	end
	self:_redesenhar()
end

-- O painel só é redesenhado quando muda algo que ele mostra (trechos, trens, estações, era).
-- Redesenhar a cada segundo destruiria os botões no meio de um clique.
local function assinatura(estado: any): string
	local ok, txt = pcall(function()
		return HttpService:JSONEncode({ estado.trechos, estado.trens, estado.estacoes or {}, estado.era })
	end)
	return if ok then txt else tostring(os.clock())
end

function Menu.atualizarEstado(self: Menu, estado: any)
	self.estado = estado
	local nova = assinatura(estado)
	if nova ~= self._assinatura then
		self._assinatura = nova
		if self.aba then
			self:_redesenhar()
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
	if self.aba == "linhas" then
		self:_abaLinhas()
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
	est:texto("titulo", `{Emojis.linhas} Linhas`, r, 1)
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
	est:texto("fraco", "Construir tudo compra os trechos liberados do mais barato para o mais caro, até o dinheiro acabar.", r, 4)

	for i, linha in dados.linhas do
		local construidos = Economia.trechosConstruidos(estado, linha)
		local liberada = Economia.linhaLiberada(estado, dados, i)
		local completa = construidos == #linha.trechos
		local faltando = Economia.trensFaltando(estado, linha)
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
		if not liberada then
			info = `{Emojis.cadeado} Libera ao completar {dados.linhas[i - 1].nome}`
		else
			local renda = Economia.formatar(Economia.rendaLinhaFinal(estado, dados, linha), simbolo, true)
			info = `{construidos}/{#linha.trechos} trechos · {estado.trens[linha.id] or 0} trens · {renda}/s`
		end
		local l2 = est:texto("fraco", info, textos, 2)
		l2.ZIndex = 33
		local situacao = if not liberada then ""
			elseif faltando > 0 then `{Emojis.alerta} Faltam {faltando} trem(ns): rende só {math.round(Economia.servico(estado, linha) * 100)}%`
			elseif completa then `{Emojis.confirmar} Linha completa`
			elseif construidos == 0 then `{Emojis.construir} Pronta para começar`
			else `{Emojis.construir} Em construção`
		if situacao ~= "" then
			local l3 = est:texto("fraco", situacao, textos, 3)
			l3.ZIndex = 33
			if faltando > 0 then
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

-- ---------------------------------------------------------------- aba Companhia

function Menu._abaCompanhia(self: Menu)
	local est, dados, estado, r = self.est, self.dados, self.estado, self.rolagem
	est:texto("titulo", `{Emojis.companhia} Companhia`, r, 1)
	if not estado then
		return
	end
	local st = Economia.estatisticas(estado, dados)
	local simbolo = dados.simbolo
	local function numero(n: number): string
		return (Economia.formatar(n, "", false):gsub("^%s+", ""))
	end
	local era = self.est.era
	est:texto("rotulo", string.upper(era.nome) .. " · " .. era.anos, r, 2)

	local sat = math.round(st.satisfacao * 100)
	est:texto("subtitulo", `{Emojis.satisfacao} Satisfação: {sat}%`, r, 3)
	local barra = novo("Frame", {
		LayoutOrder = 4,
		Size = UDim2.new(1, 0, 0, 10),
		BackgroundColor3 = est.c.bg,
		BorderSizePixel = 0,
		ZIndex = 32,
	}, r)
	novo("UIStroke", { Color = est.c.ink, Thickness = 1 }, barra)
	novo("Frame", {
		Size = UDim2.new(st.satisfacao, 0, 1, 0),
		BackgroundColor3 = if sat >= 70 then est.c.positive elseif sat >= 40 then est.c.accent else est.c.negative,
		BorderSizePixel = 0,
		ZIndex = 33,
	}, barra)
	est:texto("fraco", `Vem do serviço das linhas (trens suficientes) e do nível das estações. Hoje mexe {if sat >= 50 then "+" else ""}{math.round((Economia.fatorSatisfacao(estado, dados) - 1) * 100)}% na renda.`, r, 5)
	est:divisor(r, 6)

	local linhas = {
		`{Emojis.renda} Renda: <b>{Economia.formatar(st.renda, simbolo, true)}/s</b>`,
		`{Emojis.passageiros} Passageiros: <b>{numero(st.passageirosDia)}</b> por dia`,
		`{Emojis.carga_cafe} Café: <b>{numero(st.cafeDia)}</b> sacas por dia`,
		`{Emojis.carga_minerio} Minério: <b>{numero(st.minerioDia)}</b> t por dia`,
		`{Emojis.linhas} Trechos: <b>{st.trechos}</b> de {st.trechosTotal}`,
		`{Emojis.confirmar} Linhas completas: <b>{st.linhasCompletas}</b> de {st.linhasTotal}`,
		`{Emojis.estacoes} Estações na rede: <b>{st.estacoes}</b>`,
	}
	for i, txt in linhas do
		est:texto("corpo", txt, r, 10 + i)
	end
end

-- ---------------------------------------------------------------- aba Ajustes

function Menu._abaAjustes(self: Menu)
	local est, r = self.est, self.rolagem
	est:texto("titulo", `{Emojis.configuracoes} Ajustes`, r, 1)
	local opcoes = {
		{ chave = "nomesEstacoes", nome = "Nomes das cidades" },
		{ chave = "nomesMapa", nome = "Nomes de estados, rios e regiões" },
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
