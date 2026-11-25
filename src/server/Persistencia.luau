--!strict
-- Persistência com DataStore. Um registro por jogador, com uma seção por mapa.
-- No Studio sem "Enable Studio Access to API Services", roda só em memória (não salva) e avisa.

local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local Persistencia = {}

-- v2 (25/11/2026): reset geral antes do lançamento. Os saves da v1 ficam no Roblox, mas o jogo
-- não lê mais nada deles; todo jogador começa uma companhia nova.
local NOME_STORE = "Ferrovia_v2"
local TENTATIVAS = 3

local store: DataStore? = nil
local disponivel = false

-- Modo gravação (só no Studio): com o atributo ModoGravacao = true no ServerStorage, a sessão começa do
-- zero e nada é carregado nem salvo (nem o ranking). Serve para gravar vídeo e tirar prints sem
-- mexer no progresso de ninguém. Fora do Studio o atributo é ignorado.
local modoGravacao = RunService:IsStudio() and game:GetService("ServerStorage"):GetAttribute("ModoGravacao") == true

if modoGravacao then
	warn("[Ferrovia] MODO GRAVAÇÃO: sessão do zero, nada é carregado nem salvo.")
else
	local ok, resultado = pcall(function()
		return DataStoreService:GetDataStore(NOME_STORE)
	end)
	if ok then
		store = resultado
		-- teste rápido: no Studio sem acesso às APIs, GetAsync falha
		local okTeste, erro = pcall(function()
			(resultado :: DataStore):GetAsync("__teste")
		end)
		disponivel = okTeste
		if not okTeste then
			warn(`[Ferrovia] DataStore indisponível ({erro}). O progresso NÃO será salvo nesta sessão.`)
			if RunService:IsStudio() then
				warn("[Ferrovia] No Studio: Home > Game Settings > Security > Enable Studio Access to API Services.")
			end
		end
	end
end

function Persistencia.disponivel(): boolean
	return disponivel
end

local function chave(userId: number): string
	return `jogador_{userId}`
end

-- Retorna a tabela salva do jogador (ou nil se nunca jogou). Em caso de erro, retorna nil, false.
function Persistencia.carregar(userId: number): (any?, boolean)
	if not disponivel or not store then
		return nil, true
	end
	for tentativa = 1, TENTATIVAS do
		local ok, valor = pcall(function()
			return (store :: DataStore):GetAsync(chave(userId))
		end)
		if ok then
			return valor, true
		end
		warn(`[Ferrovia] Falha ao carregar {userId} (tentativa {tentativa}): {valor}`)
		task.wait(1)
	end
	return nil, false
end

function Persistencia.salvar(userId: number, dados: any): boolean
	if not disponivel or not store then
		return false
	end
	for tentativa = 1, TENTATIVAS do
		local ok, erro = pcall(function()
			(store :: DataStore):SetAsync(chave(userId), dados, { userId })
		end)
		if ok then
			return true
		end
		warn(`[Ferrovia] Falha ao salvar {userId} (tentativa {tentativa}): {erro}`)
		task.wait(1)
	end
	return false
end

return Persistencia
