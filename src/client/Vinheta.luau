--!strict
-- Vinheta de troca de era: a tela escurece, mostra a era que ficou para trás e a nova, e clareia.
-- Curta (uns 3 s) e sem bloquear o jogo por muito tempo. Vinheta.mostrar(playerGui, eraDe, eraPara, aoEscurecer)
-- chama aoEscurecer quando a tela já está preta (é a hora de remontar o mapa e a interface na era nova).

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Idioma = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Idioma"))

local ESCURECER = 0.35
local SEGURAR = 1.9
local CLAREAR = 0.6

local Vinheta = {}

local function rotulo(props: { [string]: any }, pai: Instance): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.AnchorPoint = Vector2.new(0.5, 0.5)
	l.TextTransparency = 1
	for k, v in props do
		(l :: any)[k] = v
	end
	l.Parent = pai
	return l
end

function Vinheta.mostrar(playerGui: Instance, eraDe: any, eraPara: any, aoEscurecer: (() -> ())?)
	local gui = Instance.new("ScreenGui")
	gui.Name = "VinhetaEra"
	gui.DisplayOrder = 30
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.ScreenInsets = Enum.ScreenInsets.None
	gui.Parent = playerGui

	local fundo = Instance.new("Frame")
	fundo.Size = UDim2.fromScale(1, 1)
	fundo.BackgroundColor3 = Color3.new(0, 0, 0)
	fundo.BackgroundTransparency = 1
	fundo.Active = true
	fundo.Parent = gui
	-- os textos ficam num miolo centrado; a escala vai nele (no fundo, o UIScale encolhia ou esticava
	-- a partir do canto de cima à esquerda e tirava tudo do centro)
	local miolo = Instance.new("Frame")
	miolo.Name = "Miolo"
	miolo.AnchorPoint = Vector2.new(0.5, 0.5)
	miolo.Position = UDim2.fromScale(0.5, 0.5)
	miolo.Size = UDim2.fromScale(1, 1)
	miolo.BackgroundTransparency = 1
	miolo.Parent = fundo
	local escala = Instance.new("UIScale")
	escala.Parent = miolo
	local t = fundo.AbsoluteSize
	if t.X > 0 then
		escala.Scale = math.clamp(math.min(t.X / 1000, t.Y / 560), 0.6, 1.25)
	end

	local claro = Color3.fromRGB(236, 230, 214)
	local fonteDe = eraDe and eraDe.fontes and eraDe.fontes.display or Font.fromEnum(Enum.Font.GothamBold)
	local fontePara = eraPara and eraPara.fontes and eraPara.fontes.display or Font.fromEnum(Enum.Font.GothamBold)
	local corPara = eraPara and eraPara.cores and eraPara.cores.accent or claro

	local antes = rotulo({
		Position = UDim2.fromScale(0.5, 0.36),
		Size = UDim2.new(1, 0, 0, 34),
		Text = if eraDe then `{Idioma.t(eraDe.nome)}  ·  {eraDe.anos or ""}` else "",
		FontFace = fonteDe,
		TextSize = 24,
		TextColor3 = claro,
	}, miolo)
	local seta = rotulo({
		Position = UDim2.fromScale(0.5, 0.46),
		Size = UDim2.new(1, 0, 0, 30),
		Text = "▼",
		FontFace = Font.fromEnum(Enum.Font.GothamBold),
		TextSize = 22,
		TextColor3 = claro,
	}, miolo)
	local depois = rotulo({
		Position = UDim2.fromScale(0.5, 0.58),
		Size = UDim2.new(1, 0, 0, 64),
		Text = if eraPara then Idioma.t(eraPara.nome) else "",
		FontFace = fontePara,
		TextSize = 52,
		TextColor3 = claro,
	}, miolo)
	local anos = rotulo({
		Position = UDim2.fromScale(0.5, 0.68),
		Size = UDim2.new(1, 0, 0, 30),
		Text = if eraPara then eraPara.anos or "" else "",
		FontFace = fontePara,
		TextSize = 22,
		TextColor3 = corPara:Lerp(claro, 0.35),
	}, miolo)

	local function tw(obj: Instance, d: number, props: { [string]: any }): Tween
		local x = TweenService:Create(obj, TweenInfo.new(d, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
		x:Play()
		return x
	end

	task.spawn(function()
		tw(fundo, ESCURECER, { BackgroundTransparency = 0 }).Completed:Wait()
		if aoEscurecer then
			local ok, erro = pcall(aoEscurecer)
			if not ok then
				warn("[Ferrovia] Erro ao trocar de era:", erro)
			end
		end
		tw(antes, 0.35, { TextTransparency = 0.35 })
		task.wait(0.25)
		tw(seta, 0.3, { TextTransparency = 0.5 })
		task.wait(0.2)
		tw(depois, 0.45, { TextTransparency = 0 })
		tw(anos, 0.45, { TextTransparency = 0.1 })
		task.wait(SEGURAR)
		for _, l in { antes, seta, depois, anos } do
			tw(l, CLAREAR * 0.6, { TextTransparency = 1 })
		end
		tw(fundo, CLAREAR, { BackgroundTransparency = 1 }).Completed:Wait()
		gui:Destroy()
	end)
end

return Vinheta
