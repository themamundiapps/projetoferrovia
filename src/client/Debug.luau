-- Debug.luau · painel de testes (TEMPORÁRIO, só no Studio).
--
-- Só aparece quando o servidor cria Remotes.Debug, o que ele faz apenas dentro do Studio.
-- Abre e fecha pelo botão 🛠 no canto de baixo à esquerda ou pela tecla F2.
-- Os comandos são os do FerroviaDebug do servidor (ver Jogo.luau, "atalhos de teste").

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Debug = {}

local FUNDO = Color3.fromRGB(24, 26, 30)
local BOTAO = Color3.fromRGB(52, 58, 66)
local PERIGO = Color3.fromRGB(150, 40, 40)
local TEXTO = Color3.fromRGB(235, 235, 235)
local FRACO = Color3.fromRGB(150, 156, 165)
local FONTE = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.SemiBold)

-- { título da seção, { { rótulo, comando, valor }, ... } }
local SECOES = {
	{ "Dinheiro", { { "+10 mil", "dinheiro", 1e4 }, { "+1 mi", "dinheiro", 1e6 }, { "+100 mi", "dinheiro", 1e8 }, { "+10 bi", "dinheiro", 1e10 } } },
	{ "XP", { { "+100", "xp", 100 }, { "+1.000", "xp", 1000 }, { "+10.000", "xp", 10000 } } },
	{ "Adiantar o tempo", { { "+10 min", "tempo", 10 }, { "+1 h", "tempo", 60 }, { "+8 h", "tempo", 480 } } },
	{ "Era (só o visual e o multiplicador)", { { "Vapor", "era", "vapor" }, { "Diesel", "era", "diesel" }, { "Elétrica", "era", "eletrico" }, { "Alta vel.", "era", "alta" } } },
	{ "Jornal e decisões", { { "Notícia", "evento" }, { "Decisão", "decisao" } } },
	{ "Contrato", { { "Cumprir", "contrato" }, { "Falhar", "contrato", "falhar" } } },
	{ "Missões e pesquisas", { { "Completar missões", "missoes" }, { "Missões novas", "missoes", "novas" }, { "Terminar pesquisas", "pesquisas" } } },
}

local function novo(classe: string, props: { [string]: any }, pai: Instance?): any
	local i = Instance.new(classe)
	for k, v in props do
		(i :: any)[k] = v
	end
	if pai then
		i.Parent = pai
	end
	return i
end

function Debug.iniciar(remote: RemoteFunction, pai: Instance)
	if not RunService:IsStudio() then
		return
	end
	local tela = novo("ScreenGui", {
		Name = "FerroviaDebugUI",
		DisplayOrder = 50,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, pai)

	local abrir = novo("TextButton", {
		Name = "AbrirDebug",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 10, 1, -10),
		Size = UDim2.fromOffset(40, 40),
		BackgroundColor3 = FUNDO,
		BackgroundTransparency = 0.15,
		Text = "🛠",
		TextSize = 22,
		TextColor3 = TEXTO,
		AutoButtonColor = true,
	}, tela)
	novo("UICorner", { CornerRadius = UDim.new(0, 8) }, abrir)

	local painel = novo("Frame", {
		Name = "PainelDebug",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 10, 1, -58),
		Size = UDim2.fromOffset(300, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = FUNDO,
		BackgroundTransparency = 0.08,
		Visible = false,
	}, tela)
	novo("UICorner", { CornerRadius = UDim.new(0, 10) }, painel)
	novo("UIPadding", {
		PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
		PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 10),
	}, painel)
	novo("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }, painel)

	local function rotulo(txt: string, ordem: number, tam: number, cor: Color3): TextLabel
		return novo("TextLabel", {
			LayoutOrder = ordem,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Text = txt,
			TextWrapped = true,
			FontFace = FONTE,
			TextSize = tam,
			TextColor3 = cor,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, painel)
	end
	rotulo("🛠 Debug (só no Studio) · F2", 0, 16, TEXTO)
	local status = rotulo("Pronto.", 1000, 13, FRACO)

	local ocupado = false
	local function rodar(comando: string, valor: any, nome: string)
		if ocupado then
			return
		end
		ocupado = true
		status.Text = `{nome}…`
		local ok, r = pcall(function()
			return remote:InvokeServer(comando, valor)
		end)
		status.Text = if ok then `{nome}: {r}` else `{nome}: falhou ({r})`
		ocupado = false
	end

	local function botao(pai2: Instance, txt: string, cor: Color3, acao: () -> ()): TextButton
		local b = novo("TextButton", {
			Size = UDim2.fromOffset(0, 26),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = cor,
			Text = txt,
			FontFace = FONTE,
			TextSize = 14,
			TextColor3 = TEXTO,
			AutoButtonColor = true,
		}, pai2)
		novo("UICorner", { CornerRadius = UDim.new(0, 6) }, b)
		novo("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, b)
		b.Activated:Connect(acao)
		return b
	end

	for i, secao in SECOES do
		rotulo(secao[1], i * 2, 13, FRACO)
		local fileira = novo("Frame", {
			LayoutOrder = i * 2 + 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
		}, painel)
		novo("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Wraps = true,
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, fileira)
		for _, item in secao[2] do
			botao(fileira, item[1], BOTAO, function()
				rodar(item[2], item[3], `{secao[1]} · {item[1]}`)
			end)
		end
	end

	-- zerar pede dois cliques em 3 segundos
	rotulo("Perigo", 900, 13, FRACO)
	local fileiraPerigo = novo("Frame", {
		LayoutOrder = 901,
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundTransparency = 1,
	}, painel)
	local armado = 0
	local bZerar: TextButton
	bZerar = botao(fileiraPerigo, "Zerar progresso", PERIGO, function()
		if os.clock() - armado < 3 then
			armado = 0
			bZerar.Text = "Zerar progresso"
			rodar("zerar", nil, "Zerar")
		else
			armado = os.clock()
			bZerar.Text = "Clique de novo para zerar"
			task.delay(3, function()
				if os.clock() - armado >= 3 then
					bZerar.Text = "Zerar progresso"
				end
			end)
		end
	end)

	local function alternar()
		painel.Visible = not painel.Visible
	end
	abrir.Activated:Connect(alternar)
	UserInputService.InputBegan:Connect(function(input, processado)
		if not processado and input.KeyCode == Enum.KeyCode.F2 then
			alternar()
		end
	end)
end

return Debug
