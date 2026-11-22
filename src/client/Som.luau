--!strict
-- Som: música de fundo por era (playlist embaralhada, com fade entre faixas) e efeitos sonoros.
-- Os ids ficam em Assets.Musicas e Assets.Sons. Liga/desliga em Ajustes (chaves "musica" e "efeitos").

local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Assets"))

local VOLUME_MUSICA = 0.15
local VOLUME_EFEITOS = 0.35
local FADE = 1.5

local Som = {}

local grupoMusica = Instance.new("SoundGroup")
grupoMusica.Name = "Musica"
grupoMusica.Volume = VOLUME_MUSICA
grupoMusica.Parent = SoundService

local grupoEfeitos = Instance.new("SoundGroup")
grupoEfeitos.Name = "Efeitos"
grupoEfeitos.Volume = VOLUME_EFEITOS
grupoEfeitos.Parent = SoundService

local musicaLigada = true
local efeitosLigados = true
local eraAtual: string? = nil
local fila: { string } = {}
local tocando: Sound? = nil
local conexaoFim: RBXScriptConnection? = nil
local geracao = 0 -- muda a cada troca de era: faixas antigas não puxam a próxima

-- volume próprio de cada efeito (1 = o do grupo): as vinhetas da APM são gravadas bem mais altas
local VOLUME_EFEITO: { [string]: number } = {
	conquista = 0.35,
}
-- efeitos que cortam (com fade) depois de alguns segundos: quem deixa o jogo de fundo não leva susto
local DURACAO_MAX: { [string]: number } = {
	conquista = 2.5,
}

-- efeitos ficam pré-carregados (um Sound por nome, reaproveitado)
local efeitos: { [string]: Sound } = {}
for nome, id in Assets.Sons do
	local s = Instance.new("Sound")
	s.Name = nome
	s.SoundId = id
	s.Volume = VOLUME_EFEITO[nome] or 1
	s.SoundGroup = grupoEfeitos
	s.Parent = grupoEfeitos
	efeitos[nome] = s
end

local function embaralhar(lista: { string }): { string }
	local t = table.clone(lista)
	for i = #t, 2, -1 do
		local j = math.random(i)
		t[i], t[j] = t[j], t[i]
	end
	return t
end

local function sumir(s: Sound)
	local tw = TweenService:Create(s, TweenInfo.new(FADE), { Volume = 0 })
	tw.Completed:Once(function()
		s:Destroy()
	end)
	tw:Play()
end

-- Playlist que toca agora: a do mapa (a mesma em todas as eras) ou, sem ela, a da era.
local mapaAtual = "brasil"
local function listaAtual(): { string }?
	return (Assets :: any).MusicasMapa[mapaAtual] or (eraAtual and Assets.Musicas[eraAtual])
end

local function proxima()
	if conexaoFim then
		conexaoFim:Disconnect()
		conexaoFim = nil
	end
	local lista = listaAtual()
	if not musicaLigada or not lista or #lista == 0 then
		return
	end
	if #fila == 0 then
		fila = embaralhar(lista)
	end
	local id = table.remove(fila, 1) :: string
	local s = Instance.new("Sound")
	s.Name = "Faixa"
	s.SoundId = id
	s.SoundGroup = grupoMusica
	s.Volume = 0
	s.Parent = grupoMusica
	s:Play()
	TweenService:Create(s, TweenInfo.new(FADE), { Volume = 1 }):Play()
	tocando = s
	local minha = geracao
	-- faixa que não carrega (tirada do ar, sem permissão) não pode travar a playlist: pula
	task.delay(12, function()
		if minha == geracao and tocando == s and not s.IsLoaded then
			s:Destroy()
			proxima()
		end
	end)
	conexaoFim = s.Ended:Connect(function()
		s:Destroy()
		if minha == geracao then
			task.wait(2) -- um respiro entre as faixas
			if minha == geracao then
				proxima()
			end
		end
	end)
end

local function pararMusica()
	geracao += 1
	if conexaoFim then
		conexaoFim:Disconnect()
		conexaoFim = nil
	end
	if tocando then
		sumir(tocando)
		tocando = nil
	end
end

-- Troca a playlist para a era (não faz nada se já é a mesma).
-- Troca o mapa da trilha (o Brasil toca bossa nova em todas as eras; sem trilha própria, a da era).
-- A música atual para e a próxima chamada a Som.musica começa a playlist nova.
function Som.definirMapa(id: string)
	if id == mapaAtual then
		return
	end
	mapaAtual = id
	fila = {} -- a fila embaralhada era do mapa anterior
	if tocando then
		local s = tocando
		tocando = nil
		geracao += 1
		s:Stop()
		s:Destroy()
	end
end

function Som.musica(eraId: string)
	if eraId == eraAtual and tocando then
		return
	end
	-- com trilha do mapa, trocar de era não reinicia a música
	local antes = listaAtual()
	eraAtual = eraId
	if tocando and antes and antes == listaAtual() then
		return
	end
	fila = {}
	pararMusica()
	proxima()
end

-- Pula para outra faixa da mesma era (debug).
function Som.pular()
	pararMusica()
	proxima()
end

function Som.efeito(nome: string)
	if not efeitosLigados then
		return
	end
	local s = efeitos[nome]
	if s then
		-- toca um clone: o mesmo efeito pode se sobrepor (cliques seguidos)
		local c = s:Clone()
		c.Parent = grupoEfeitos
		c:Play()
		c.Ended:Once(function()
			c:Destroy()
		end)
		local max = DURACAO_MAX[nome]
		if max then
			task.delay(max, function()
				if c.Parent and c.IsPlaying then
					local tw = TweenService:Create(c, TweenInfo.new(0.8), { Volume = 0 })
					tw.Completed:Once(function()
						c:Destroy()
					end)
					tw:Play()
				end
			end)
		end
	end
end

function Som.definir(chave: string, valor: boolean)
	if chave == "musica" then
		musicaLigada = valor
		if valor then
			if not tocando then
				proxima()
			end
		else
			pararMusica()
		end
	elseif chave == "efeitos" then
		efeitosLigados = valor
	end
end

-- Clique em qualquer botão da interface (não do mapa): liga uma vez por botão.
function Som.observarCliques(raiz: Instance)
	local function ligar(obj: Instance)
		if obj:IsA("GuiButton") and not obj:GetAttribute("SemClique") then
			(obj :: GuiButton).Activated:Connect(function()
				Som.efeito("clique")
			end)
		end
	end
	for _, d in raiz:GetDescendants() do
		ligar(d)
	end
	raiz.DescendantAdded:Connect(ligar)
end

return Som
