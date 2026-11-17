--!strict
-- Tutorial: caixa no topo da tela que guia os primeiros passos (um passo por vez, decidido em Metas).
-- O botão principal mostra no mapa (ou abre a aba) o que o passo pede; dá para pular a qualquer hora.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Metas = require(Shared:WaitForChild("Metas"))
local Emojis = require(Shared:WaitForChild("Emojis"))
local Estilo = require(script.Parent:WaitForChild("Estilo"))

local novo = Estilo.novo

local Tutorial = {}
Tutorial.__index = Tutorial

export type Tutorial = typeof(setmetatable({} :: any, Tutorial))

-- Espaço reservado dos dois lados para o caixa da companhia e os painéis.
local MARGEM_LATERAL = 360

function Tutorial.new(tela: ScreenGui, era: any, dados: any): Tutorial
	local est = Estilo.new(era)
	local self = setmetatable({}, Tutorial)
	self.dados = dados
	self.passo = nil :: Metas.PassoTutorial?
	self.aoAcao = Instance.new("BindableEvent") -- (acao, alvo): "linha", "estacao" ou "aba"
	self.aoAgir = Instance.new("BindableEvent") -- (tipo, args) para o servidor

	local caixa = est:caixa({
		Name = "Tutorial",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, Estilo.ALTURA_TOPO + 60),
		Size = UDim2.fromOffset(420, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = false,
	}, tela)
	self.caixa = caixa
	local contorno = caixa:FindFirstChildOfClass("UIStroke")
	if contorno then
		contorno.Color = est.c.accent -- destaque: é a caixa que diz o que fazer agora
		contorno.Thickness = 2.5
	end
	est:padding(caixa, 12, 10)
	est:lista(caixa, 6)

	self.lblPasso = est:texto("rotulo", "", caixa, 1)
	self.lblTexto = est:texto("corpo", "", caixa, 2)

	local botoes = novo("Frame", {
		LayoutOrder = 3,
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundTransparency = 1,
		ZIndex = 31,
	}, caixa)
	self.btnAcao = est:botao("principal", "", botoes)
	self.btnAcao.Name = "BtnAcao"
	self.btnAcao.Size = UDim2.new(0.62, -4, 1, 0)
	self.btnPular = est:botao("discreto", "Pular tutorial", botoes)
	self.btnPular.Name = "BtnPular"
	self.btnPular.AnchorPoint = Vector2.new(1, 0)
	self.btnPular.Position = UDim2.fromScale(1, 0)
	self.btnPular.Size = UDim2.new(0.38, -4, 1, 0)
	self.btnPular.TextSize = 14

	self.btnAcao.Activated:Connect(function()
		local passo = self.passo
		if not passo then
			return
		end
		if passo.acao == "concluir" then
			self.aoAgir:Fire("tutorial", {})
		elseif passo.acao then
			self.aoAcao:Fire(passo.acao, passo.alvo)
		end
	end)
	self.btnPular.Activated:Connect(function()
		self.aoAgir:Fire("tutorial", { pular = true })
	end)

	-- em telas estreitas a caixa encolhe para não cobrir os painéis dos lados
	local function ajustarLargura()
		caixa.Size = UDim2.fromOffset(math.clamp(tela.AbsoluteSize.X - 2 * MARGEM_LATERAL, 260, 440), 0)
	end
	self.conexao = tela:GetPropertyChangedSignal("AbsoluteSize"):Connect(ajustarLargura)
	ajustarLargura()

	return self
end

function Tutorial.atualizarEstado(self: Tutorial, estado: any)
	local passo = Metas.passoTutorial(estado, self.dados)
	local anterior = self.passo
	self.passo = passo
	self.caixa.Visible = passo ~= nil
	if not passo or (anterior and anterior.id == passo.id and anterior.alvo == passo.alvo) then
		return
	end
	self.lblPasso.Text = `{Emojis.dica} PRIMEIROS PASSOS · {passo.indice} DE {passo.total}`
	self.lblTexto.Text = passo.texto
	self.btnAcao.Text = passo.botao or "Mostrar no mapa"
	self.btnPular.Visible = passo.acao ~= "concluir"
	self.btnAcao.Size = if passo.acao == "concluir" then UDim2.fromScale(1, 1) else UDim2.new(0.62, -4, 1, 0)
end

function Tutorial.destruir(self: Tutorial)
	self.conexao:Disconnect()
	self.caixa:Destroy()
	self.aoAcao:Destroy()
	self.aoAgir:Destroy()
end

return Tutorial
