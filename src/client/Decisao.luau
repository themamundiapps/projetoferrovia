--!strict
-- Janela de decisão (estilo Victoria): aparece no meio da tela quando chega uma decisão, com o texto e as
-- opções; cada botão mostra o que a escolha faz. L("Decidir depois", "Decide later") esconde a janela e deixa um botão
-- no canto para voltar a ela. O jogo continua rodando atrás.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Economia = require(Shared:WaitForChild("Economia"))
local Decisoes = require(Shared:WaitForChild("Decisoes"))
local Emojis = require(Shared:WaitForChild("Emojis"))
local Idioma = require(Shared:WaitForChild("Idioma"))
local L = Idioma.L
local Assets = require(Shared:WaitForChild("Assets"))
local Estilo = require(script.Parent:WaitForChild("Estilo"))

local novo = Estilo.novo

local Decisao = {}
Decisao.__index = Decisao

export type Decisao = typeof(setmetatable({} :: any, Decisao))

local Z = 50

local function subirZ(raiz: Instance, base: number)
	for _, d in raiz:GetDescendants() do
		if d:IsA("GuiObject") and not string.find(d.Name, "Kit$") then
			d.ZIndex = base + 1 + (if d:IsA("TextButton") then 1 else 0)
		end
	end
end

function Decisao.new(tela: ScreenGui, era: any, dados: any): Decisao
	local est = Estilo.new(era)
	local self = setmetatable({}, Decisao)
	self.est = est
	self.dados = dados
	self.tela = tela
	self.chave = nil :: string? -- decisão desenhada agora (id + quando chegou)
	self.minimizado = false
	self.estado = nil :: any
	self.botoes = {} :: { TextButton }
	self.liberado = {} :: { boolean }
	self.aoAgir = Instance.new("BindableEvent") -- (tipo, args) para o servidor

	local caixa = est:caixa({
		Name = "Decisao",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(500, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = false,
		ZIndex = Z,
	}, tela)
	self.caixa = caixa
	local contorno = caixa:FindFirstChildOfClass("UIStroke")
	if contorno then
		contorno.Color = est.c.accent
		contorno.Thickness = 3
	end
	est:padding(caixa, 18, 16)
	est:lista(caixa, 10)

	-- ilustração (16:9), só quando a decisão tem imagem
	self.imagem = novo("ImageLabel", {
		Name = "Ilustracao",
		LayoutOrder = -1,
		Size = UDim2.fromScale(1, 0),
		BackgroundColor3 = est.c.bg,
		ScaleType = Enum.ScaleType.Crop,
		Visible = false,
	}, caixa) :: ImageLabel
	novo("UIAspectRatioConstraint", { AspectRatio = 16 / 9 }, self.imagem)
	est:cantos(self.imagem)
	-- cabeçalho: emoji grande + título
	local topo = novo("Frame", { LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 }, caixa)
	est:lista(topo, 12, true)
	self.lblEmoji = novo("TextLabel", {
		LayoutOrder = 1,
		Size = UDim2.fromOffset(48, 48),
		BackgroundTransparency = 1,
		Text = "",
		TextSize = 40,
	}, topo) :: TextLabel
	self.lblTitulo = est:texto("titulo", "", topo, 2)
	self.lblTitulo.Size = UDim2.new(1, -60, 0, 0)
	self.lblRotulo = est:texto("rotulo", "", caixa, 0)
	self.lblTexto = est:texto("corpo", "", caixa, 2)
	est:divisor(caixa, 3)
	self.opcoes = novo("Frame", { Name = "Opcoes", LayoutOrder = 4, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 }, caixa)
	est:lista(self.opcoes, 8)
	self.btnDepois = est:botao("discreto", "Decidir depois", caixa, 5)
	self.btnDepois.Name = "BtnDepois"
	self.btnDepois.Size = UDim2.new(1, 0, 0, 34)
	self.btnDepois.TextSize = 14
	self.btnDepois.Activated:Connect(function()
		self.minimizado = true
		self:_mostrar()
	end)

	-- botão para voltar à decisão (canto direito, acima do zoom)
	self.btnPendente = est:botao("principal", L(`{Emojis.contratos} Decisão pendente`, `{Emojis.contratos} Pending decision`), tela)
	self.btnPendente.Name = "DecisaoPendente"
	self.btnPendente.AnchorPoint = Vector2.new(1, 1)
	self.btnPendente.Position = UDim2.new(1, -14, 1, -132)
	self.btnPendente.Size = UDim2.fromOffset(200, 40)
	self.btnPendente.Visible = false
	self.btnPendente.ZIndex = 40
	self.btnPendente.Activated:Connect(function()
		self.minimizado = false
		self:_mostrar()
	end)
	-- fica logo acima dos botões de zoom quando eles aparecem (tela de toque); eles mudam de lugar
	-- em tela estreita
	local achado = tela:FindFirstChild("Zoom") :: GuiObject?
	if achado then
		local zoom: GuiObject = achado
		local function acimaDoZoom()
			if zoom.Visible then
				local base = Estilo.px(tela.AbsolutePosition.Y + tela.AbsoluteSize.Y - zoom.AbsolutePosition.Y) + 6
				self.btnPendente.Position = UDim2.new(1, -14, 1, -math.max(132, base))
			else
				self.btnPendente.Position = UDim2.new(1, -14, 1, -132)
			end
		end
		zoom:GetPropertyChangedSignal("AbsolutePosition"):Connect(acimaDoZoom)
		zoom:GetPropertyChangedSignal("Visible"):Connect(acimaDoZoom)
		acimaDoZoom()
	end

	local function ajustarLargura()
		caixa.Size = UDim2.fromOffset(math.clamp(Estilo.px(tela.AbsoluteSize.X) - 40, 280, 520), 0)
	end
	self.conexao = tela:GetPropertyChangedSignal("AbsoluteSize"):Connect(ajustarLargura)
	ajustarLargura()
	subirZ(caixa, Z)
	return self
end

function Decisao._mostrar(self: Decisao)
	local temPendente = self.chave ~= nil
	self.caixa.Visible = temPendente and not self.minimizado
	self.btnPendente.Visible = temPendente and self.minimizado
end

function Decisao._contexto(self: Decisao, estado: any): Decisoes.Contexto
	local pend = estado.decisoes.pendente
	return {
		estado = estado,
		lucro = estado.renda or 0,
		simbolo = self.dados.simbolo,
		tipo = pend.tipo,
		alvo = pend.alvo,
		dados = self.dados,
		idioma = Idioma.atual,
	}
end

function Decisao._desenhar(self: Decisao, estado: any, def: Decisoes.Definicao)
	local pend = estado.decisoes.pendente
	local est = self.est
	local titulo, texto = Decisoes.textos(def, pend.tipo, pend.alvo, self.dados, Idioma.atual)
	local img = Assets.Decisoes[def.id]
	self.imagem.Image = img or ""
	self.imagem.Visible = img ~= nil
	self.imagem.Size = UDim2.new(1, 0, 0, 0)
	self.imagem.AutomaticSize = Enum.AutomaticSize.None
	self.lblEmoji.Visible = img == nil
	self.lblTitulo.Size = if img then UDim2.new(1, 0, 0, 0) else UDim2.new(1, -60, 0, 0)
	self.lblEmoji.Text = (Emojis :: any)[def.emoji] or Emojis.contratos
	self.lblTitulo.Text = titulo
	self.lblRotulo.Text = L(`{Emojis.contratos} DECISÃO DA COMPANHIA`, `{Emojis.contratos} COMPANY DECISION`)
	self.lblTexto.Text = texto
	for _, b in self.botoes do
		b:Destroy()
	end
	table.clear(self.botoes)
	table.clear(self.liberado)
	for i, _ in def.opcoes do
		local b = est:botao(if i == 1 then "principal" else "secundario", "", self.opcoes, i)
		b.Name = `Opcao_{i}`
		b.Size = UDim2.new(1, 0, 0, 0)
		b.AutomaticSize = Enum.AutomaticSize.Y
		b.RichText = true
		b.TextXAlignment = Enum.TextXAlignment.Left
		est:padding(b, 14, 9)
		b.Activated:Connect(function()
			if self.liberado[i] then
				self.aoAgir:Fire("escolherDecisao", { opcao = i })
			end
		end)
		self.botoes[i] = b
	end
	subirZ(self.caixa, Z)
	self:_atualizarOpcoes(estado, def)
end

-- Valores mudam com o lucro: reescreve os botões a cada atualização do estado.
function Decisao._atualizarOpcoes(self: Decisao, estado: any, def: Decisoes.Definicao)
	local ctx = self:_contexto(estado)
	local simbolo = self.dados.simbolo
	for i, op in def.opcoes do
		local b = self.botoes[i]
		if b then
			local nome = if Idioma.atual == "en" then op.en else op.pt
			local custo = Decisoes.custo(estado, ctx.lucro, op)
			local pode = estado.dinheiro >= custo
			local efeitos = Decisoes.descrever(op, ctx)
			local falta = if pode then "" else L(`  ({Emojis.alerta} faltam {Economia.formatar(custo - estado.dinheiro, simbolo)})`, `  ({Emojis.alerta} {Economia.formatar(custo - estado.dinheiro, simbolo)} short)`)
			b.Text = `<b>{nome}</b>\n<font size="13">{efeitos}{falta}</font>`
			self.liberado[i] = pode
			self.est:habilitar(b, pode)
		end
	end
end

function Decisao.atualizarEstado(self: Decisao, estado: any)
	self.estado = estado
	local pend = estado.decisoes and estado.decisoes.pendente
	local def = pend and Decisoes.acharDecisao(pend.id)
	if not pend or not def then
		self.chave = nil
		self:_mostrar()
		return
	end
	local chave = `{pend.id}:{pend.em}`
	if chave ~= self.chave then
		self.chave = chave
		self.minimizado = false -- decisão nova sempre abre a janela
		self:_desenhar(estado, def)
	else
		self:_atualizarOpcoes(estado, def)
	end
	self:_mostrar()
end

function Decisao.destruir(self: Decisao)
	self.conexao:Disconnect()
	self.caixa:Destroy()
	self.btnPendente:Destroy()
	self.aoAgir:Destroy()
end

return Decisao
