--!strict
-- Idioma: textos em português e inglês.
-- No cliente o idioma é o que o jogador escolheu no menu do Roblox (Configurações › Idioma):
-- português para "pt-*", inglês para o resto. Quando ele troca lá, o cliente remonta a interface
-- (Idioma.aoMudarNoRoblox). No servidor fica "pt"; as mensagens que o servidor manda para um jogador
-- usam o idioma da sessão dele (Jogo.luau).
-- Três jeitos de traduzir:
--   Idioma.L("texto", "text")    -- par no próprio lugar (o jeito mais usado na interface)
--   Idioma.t({ pt = …, en = … })  -- par que vem dos dados
--   Idioma.T("chave", …)          -- textos fixos da tabela TEXTOS abaixo, com %s/%d

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Idioma = {}

local LocalizationService = game:GetService("LocalizationService")

-- "pt" ou "en", pelo idioma do Roblox do jogador
local function detectar(): string
	if RunService:IsClient() then
		local jogador = Players.LocalPlayer
		local local_ = if jogador then string.lower(jogador.LocaleId or "") else ""
		if local_ == "" then
			local_ = string.lower(LocalizationService.RobloxLocaleId or "")
		end
		if local_ ~= "" and string.sub(local_, 1, 2) ~= "pt" then
			return "en"
		end
	end
	return "pt"
end
Idioma.atual = detectar()

-- Muda o idioma; quem desenha a interface remonta depois.
function Idioma.definir(idioma: string)
	Idioma.atual = if idioma == "en" then "en" else "pt"
end

-- Chama `funcao(idioma)` quando o jogador troca o idioma no menu do Roblox (só no cliente).
function Idioma.aoMudarNoRoblox(funcao: (string) -> ())
	local function conferir()
		local novo = detectar()
		if novo ~= Idioma.atual then
			funcao(novo)
		end
	end
	local jogador = Players.LocalPlayer
	if jogador then
		jogador:GetPropertyChangedSignal("LocaleId"):Connect(conferir)
	end
	LocalizationService:GetPropertyChangedSignal("RobloxLocaleId"):Connect(conferir)
end

-- Par de textos no próprio lugar: Idioma.L("Fechar", "Close").
function Idioma.L(pt: string, en: string): string
	return if Idioma.atual == "en" then en else pt
end

-- Texto que vem dos dados nos dois idiomas: { pt = "...", en = "..." }.
function Idioma.t(texto: any): string
	if type(texto) == "table" then
		return texto[Idioma.atual] or texto.pt or ""
	end
	return if texto == nil then "" else tostring(texto)
end

-- Textos fixos da interface. %s e %d são preenchidos por Idioma.T (use %% para um sinal de porcentagem).
Idioma.TEXTOS = {
	-- ficha da cidade: cabeçalho
	porte_1 = { pt = "Vila", en = "Village" },
	porte_2 = { pt = "Cidade", en = "Town" },
	porte_3 = { pt = "Cidade grande", en = "City" },
	porte_4 = { pt = "Capital regional", en = "Regional capital" },
	porte_5 = { pt = "Metrópole", en = "Metropolis" },
	ficha_porto = { pt = "Porto", en = "Port" },
	ficha_produtora = { pt = "Produtora", en = "Producer" },
	-- números
	ficha_populacao = { pt = "POPULAÇÃO", en = "POPULATION" },
	ficha_habitantes = { pt = "habitantes", en = "inhabitants" },
	ficha_passageiros = { pt = "PASSAGEIROS", en = "PASSENGERS" },
	ficha_por_hora = { pt = "%s/h", en = "%s/h" },
	ficha_todos_embarcam = { pt = "todos embarcam", en = "all board" },
	ficha_so_embarcam = { pt = "só %d%% embarcam", en = "only %d%% board" },
	ficha_fora_da_rede = { pt = "fora da rede", en = "off the network" },
	ficha_rede = { pt = "REDE", en = "NETWORK" },
	ficha_cidades_ligadas = { pt = "cidades grandes ligadas", en = "big cities linked" },
	-- estação
	ficha_estacao = { pt = "ESTAÇÃO", en = "STATION" },
	ficha_parada_simples = { pt = "Parada simples", en = "Simple stop" },
	ficha_nivel = { pt = "nível %d de %d", en = "level %d of %d" },
	ficha_sem_melhorias = { pt = "A estação ainda não tem melhorias.", en = "The station has no upgrades yet." },
	ficha_bonus_atual = {
		pt = "Hoje a estação dá +%d%% de passageiros e renda nos trechos que chegam aqui.",
		en = "The station now gives +%d%% passengers and income on the sections that reach it.",
	},
	ficha_proxima = { pt = "%s leva a +%d%%.", en = "%s takes it to +%d%%." },
	ficha_nivel_maximo = { pt = "Nível máximo", en = "Top level" },
	ficha_botao_fora = { pt = "Fora da rede", en = "Off the network" },
	ficha_motivo_fora = {
		pt = "Construa um trecho até esta cidade para poder melhorar a estação.",
		en = "Build a section to this city to upgrade its station.",
	},
	ficha_faltam = { pt = "Faltam %s.", en = "%s short." },
	ficha_lotada = { pt = "Plataforma cheia: faltam %d trem(ns) na linha %s.", en = "Crowded platform: %d more train(s) needed on the %s line." },
	-- linhas
	ficha_linhas = { pt = "LINHAS", en = "LINES" },
	ficha_desde = { pt = "desde %d", en = "since %d" },
	ficha_projeto = { pt = "projeto", en = "project" },
	ficha_a_construir = { pt = "a construir", en = "to build" },
	ficha_fechada = { pt = "fechada", en = "locked" },
	-- porto e produção
	ficha_secao_porto = { pt = "PORTO", en = "PORT" },
	ficha_cargas_chegam = { pt = "Cargas que chegam a este porto:", en = "Cargo reaching this port:" },
	ficha_sem_cargas = {
		pt = "Nenhuma carga chega aqui ainda. Ligue uma cidade produtora por trilho.",
		en = "No cargo reaches here yet. Link a producing city by rail.",
	},
	ficha_producao = { pt = "PRODUÇÃO", en = "PRODUCTION" },
	ficha_produz = { pt = "%s: %s %s por dia", en = "%s: %s %s per day" },
	ficha_chega_ao_porto = { pt = "Chega a um porto: +%d%% na linha %s.", en = "Reaches a port: +%d%% on the %s line." },
	ficha_sem_porto = { pt = "Ainda sem trilho até um porto.", en = "No rail link to a port yet." },
	ficha_frete = { pt = "Frete: %s por %s · %s por dia.", en = "Freight: %s per %s · %s per day." },
	ficha_renderia = { pt = "Ligada a um porto, renderia %s por dia.", en = "Linked to a port, it would earn %s per day." },
	-- história
	ficha_historia = { pt = "HISTÓRIA", en = "HISTORY" },
	ficha_fechar = { pt = "Fechar", en = "Close" },
	-- companhia
	companhia_padrao = { pt = "Companhia Ferroviária", en = "Railway Company" },
	companhia_nome = { pt = "NOME DA COMPANHIA", en = "COMPANY NAME" },
	companhia_dica_nome = { pt = "De 3 a 32 letras. Aparece no caixa e, no futuro, no ranking.", en = "3 to 32 letters. Shown on your treasury and, later, on the leaderboard." },
	companhia_salvar = { pt = "Registrar nome", en = "Register name" },
	nivel_titulo = { pt = "Nível %d · %s", en = "Level %d · %s" },
} :: { [string]: { pt: string, en: string } }

-- Texto fixo pela chave, com os valores no lugar de %s e %d.
function Idioma.T(chave: string, ...: any): string
	local par = Idioma.TEXTOS[chave]
	local texto = if par then (par :: any)[Idioma.atual] or par.pt else chave
	if select("#", ...) > 0 then
		return string.format(texto, ...)
	end
	return (string.gsub(texto, "%%%%", "%%"))
end

-- string.upper não mexe em letras acentuadas: esta troca as mais comuns.
local ACENTOS: { [string]: string } = { ["á"] = "Á", ["à"] = "À", ["â"] = "Â", ["ã"] = "Ã", ["é"] = "É", ["ê"] = "Ê", ["í"] = "Í", ["ó"] = "Ó", ["ô"] = "Ô", ["õ"] = "Õ", ["ú"] = "Ú", ["ç"] = "Ç" }
function Idioma.maiusculas(texto: string): string
	local r = string.upper(texto)
	for min, mai in ACENTOS do
		r = string.gsub(r, min, mai)
	end
	return r
end

return Idioma
