-- Emojis.lua · ícones do jogo em emoji (texto). Não precisam de upload.
-- Uso: label.Text = Emojis.carga_cafe  (TextLabel/TextButton; a cor do texto não afeta emojis coloridos)
-- Mantém os mesmos nomes dos ícones da v1, para trocar de volta sem mexer no resto do código.

local Emojis = {
	-- geral
	linhas = "🛤️",
	trens = "🚂",
	estacoes = "🚉",
	cargas = "📦",
	companhia = "💼",
	loja = "🛒",
	mapa_mundo = "🌎",
	missoes = "📋",
	ranking = "🏆",
	configuracoes = "⚙️",
	visitar = "👀",
	menu = "📜",
	dinheiro = "💰",
	renda = "📈",
	manutencao = "🔧",
	passageiros = "👥",
	satisfacao = "😊",
	relogio = "⏰",
	cadeado = "🔒",
	melhorar = "⬆️",
	confirmar = "✅",
	fechar = "❌",
	mais = "➕",
	menos = "➖",
	info = "ℹ️",
	alerta = "⚠️",
	velocidade = "💨", -- não há velocímetro em emoji
	distancia = "📏",
	presente = "🎁",
	prestigio = "⭐",
	conectar = "🔗",
	construir = "🔨",
	assinar = "✍️",
	sede = "🚩",
	auto = "🔄",
	gabinete = "📐", -- Gabinete de Projetos (esquadro de desenhista)
	pesquisa = "🔎",
	-- carga
	carga_cafe = "☕",
	carga_minerio = "⛏️", -- picareta no lugar de minério
	carga_soja = "🌱", -- o emoji de feijão (🫘) é novo demais
	carga_graos = "🌾",
	carga_carvao = "🔥", -- não há emoji de carvão
	carga_petroleo = "🛢️",
	carga_madeira = "🌲", -- o emoji de tora (🪵) é novo demais
	carga_gado = "🐄",
	carga_aco = "🔩",
	carga_mercadorias = "🏭",
	carga_passageiros = "🎫",
	-- terreno
	terreno_montanha = "⛰️",
	terreno_ponte = "🌉",
	terreno_pantano = "🐊", -- jacaré representa o Pantanal
	terreno_floresta = "🌳",
	terreno_tunel = "🚇",
	terreno_cremalheira = "🧗", -- não há emoji de cremalheira; escalada = trecho íngreme
	-- era
	era_vapor = "🚂",
	era_diesel = "🚆",
	era_eletrico = "🚈",
	era_alta = "🚅",
}

return Emojis
