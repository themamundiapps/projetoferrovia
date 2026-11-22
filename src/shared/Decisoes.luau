--!strict
-- Decisões: eventos com escolha, no estilo de Victoria. 15 por era. A cada ~10 minutos chega uma;
-- fica esperando (sem prazo) até o jogador escolher, e não chega outra enquanto isso.
-- Cada opção tem efeitos genéricos (dinheiro, modificador temporário, XP, trem, estudo, sorte), e o texto
-- do efeito que aparece no botão é gerado a partir deles: o que o jogador lê é o que acontece.

local Economia = require(script.Parent:WaitForChild("Economia"))

type EstadoMapa = Economia.EstadoMapa
type Texto = { pt: string, en: string }

local Decisoes = {}

Decisoes.PRIMEIRA = 6 * 60 -- segundos de jogo até a primeira decisão
Decisoes.INTERVALO_MIN = 8 * 60
Decisoes.INTERVALO_MAX = 12 * 60
Decisoes.TRECHOS_MINIMOS = 3
Decisoes.MAX_HISTORICO = 12
Decisoes.PISO_MINUTO = 1500 -- 1 "minuto de lucro" vale pelo menos isso (vezes o multiplicador da era)

-- ---------------------------------------------------------------- efeitos

-- dinheiro: minutos de lucro (negativo = custo, pago na hora; a opção fica bloqueada sem caixa)
-- mod: modificador temporário de receita ou manutenção (tipo como em Economia.EventoAtivo; min = duração)
-- xp, trem (na linha do evento), pesquisa (minutos a menos no estudo em andamento)
-- sorte: chance de dar certo, com os efeitos de cada lado
export type Efeito = {
	dinheiro: number?,
	mod: { tipo: string, mult: number, min: number }?,
	xp: number?,
	trem: number?,
	pesquisa: number?,
	sorte: { chance: number, sucesso: { Efeito }, falha: { Efeito } }?,
}

local function D(min: number): Efeito
	return { dinheiro = min }
end
local function M(tipo: string, mult: number, min: number): Efeito
	return { mod = { tipo = tipo, mult = mult, min = min } }
end
local function XP(n: number): Efeito
	return { xp = n }
end
local function TREM(n: number): Efeito
	return { trem = n }
end
local function ESTUDO(min: number): Efeito
	return { pesquisa = min }
end
local function SORTE(chance: number, sucesso: { Efeito }, falha: { Efeito }): Efeito
	return { sorte = { chance = chance, sucesso = sucesso, falha = falha } }
end

export type Opcao = { pt: string, en: string, ef: { Efeito } }

-- alvo: "linha" (uma linha construída qualquer), "cidade" (uma cidade grande da rede) ou uma tabela com
-- cidade/carga/regiao fixas (a decisão só aparece se aquilo estiver na rede). %s no texto = nome do alvo.
export type Definicao = {
	id: string,
	mapa: string?, -- "eua", "europa"...; sem mapa = Brasil (as decisões contam a história do país)
	era: string,
	emoji: string,
	alvo: any,
	titulo: Texto,
	texto: Texto,
	opcoes: { Opcao },
}

local CATALOGO: { Definicao } = {
	-- ================================================================ VAPOR (1852–1930)
	{
		id = "barao_cafe", era = "vapor", emoji = "carga_cafe", alvo = { carga = "cafe" },
		titulo = { pt = "O barão do café faz uma proposta", en = "The coffee baron makes an offer" },
		texto = { pt = "Um barão oferece pagar parte das suas obras. Em troca, quer frete barato para o café dele por um bom tempo.", en = "A baron offers to pay for part of your works. In return, he wants cheap freight for his coffee for a good while." },
		opcoes = {
			{ pt = "Aceitar o dinheiro do barão", en = "Take the baron's money", ef = { D(4), M("carga", 0.8, 15) } },
			{ pt = "Recusar: a companhia não tem dono", en = "Refuse: the company answers to no one", ef = { XP(40) } },
		},
	},
	{
		id = "viagem_imperial", era = "vapor", emoji = "estacoes", alvo = nil,
		titulo = { pt = "O Imperador quer viajar de trem", en = "The Emperor wants to ride the train" },
		texto = { pt = "Dom Pedro II pede uma viagem especial pela sua ferrovia. A corte inteira vai estar olhando.", en = "Emperor Pedro II asks for a special journey on your railway. The whole court will be watching." },
		opcoes = {
			{ pt = "Preparar um vagão imperial", en = "Prepare an imperial carriage", ef = { D(-2), M("geral", 1.25, 10), XP(50) } },
			{ pt = "Uma viagem simples, sem luxo", en = "A plain trip, no luxury", ef = { XP(15) } },
			{ pt = "Cobrar a passagem da comitiva", en = "Charge the entourage their fares", ef = { D(1), M("geral", 0.9, 10) } },
		},
	},
	{
		id = "febre_santos", era = "vapor", emoji = "alerta", alvo = { cidade = "santos" },
		titulo = { pt = "Febre amarela no porto de %s", en = "Yellow fever at the port of %s" },
		texto = { pt = "A doença assusta os viajantes e os navios evitam o porto. Os médicos pedem dinheiro para o saneamento.", en = "The disease frightens travellers and ships avoid the port. Doctors are asking for money for sanitation." },
		opcoes = {
			{ pt = "Financiar o saneamento", en = "Fund the sanitation works", ef = { D(-3), M("cidade", 1.2, 15), XP(30) } },
			{ pt = "Esperar passar", en = "Wait it out", ef = { SORTE(0.5, {}, { M("cidade", 0.6, 8) }) } },
		},
	},
	{
		id = "engenheiros_ingleses", era = "vapor", emoji = "construir", alvo = nil,
		titulo = { pt = "Engenheiros ingleses oferecem serviço", en = "English engineers offer their services" },
		texto = { pt = "Uma firma de Londres promete cuidar dos seus trilhos melhor do que ninguém. Mas cobra em libras.", en = "A London firm promises to look after your tracks better than anyone. But it charges in pounds." },
		opcoes = {
			{ pt = "Contratar os ingleses", en = "Hire the English", ef = { D(-2), M("manutencao", 0.75, 15) } },
			{ pt = "Formar engenheiros brasileiros", en = "Train Brazilian engineers", ef = { D(-1), XP(60) } },
			{ pt = "Dispensar", en = "Turn them away", ef = {} },
		},
	},
	{
		id = "greve_maquinistas", era = "vapor", emoji = "alerta", alvo = nil,
		titulo = { pt = "Os maquinistas cruzam os braços", en = "The engine drivers down tools" },
		texto = { pt = "Os maquinistas pedem salários melhores e ameaçam parar os trens a partir de amanhã.", en = "The drivers want better pay and threaten to stop the trains from tomorrow." },
		opcoes = {
			{ pt = "Dar o aumento", en = "Give them the raise", ef = { D(-2), XP(20) } },
			{ pt = "Negociar com calma", en = "Negotiate calmly", ef = { SORTE(0.6, { XP(30) }, { M("geral", 0.7, 8) }) } },
			{ pt = "Contratar substitutos", en = "Hire replacements", ef = { M("geral", 0.8, 10) } },
		},
	},
	{
		id = "locomotiva_experimental", era = "vapor", emoji = "trens", alvo = "linha",
		titulo = { pt = "Uma locomotiva experimental", en = "An experimental locomotive" },
		texto = { pt = "Uma fábrica quer testar uma locomotiva nova na linha %s. Pode ser um sucesso ou um vexame.", en = "A factory wants to test a new locomotive on the %s line. It could be a triumph or a fiasco." },
		opcoes = {
			{ pt = "Comprar a locomotiva", en = "Buy the locomotive", ef = { D(-2), TREM(1) } },
			{ pt = "Deixar testarem de graça", en = "Let them test it for free", ef = { SORTE(0.5, { M("linha", 1.3, 10) }, { M("linha", 0.8, 10) }) } },
			{ pt = "Recusar", en = "Decline", ef = {} },
		},
	},
	{
		id = "deslizamento_serra", era = "vapor", emoji = "terreno_montanha", alvo = "linha",
		titulo = { pt = "Deslizamento na linha %s", en = "Landslide on the %s line" },
		texto = { pt = "A chuva derrubou a encosta em cima dos trilhos. Dá para reconstruir agora ou improvisar um desvio.", en = "Rain brought the hillside down onto the tracks. You can rebuild now or improvise a detour." },
		opcoes = {
			{ pt = "Reconstruir já", en = "Rebuild right away", ef = { D(-2) } },
			{ pt = "Fazer um desvio provisório", en = "Build a temporary detour", ef = { M("linha", 0.7, 10) } },
		},
	},
	{
		id = "jornalista", era = "vapor", emoji = "jornal", alvo = nil,
		titulo = { pt = "Um jornalista ataca a companhia", en = "A journalist attacks the company" },
		texto = { pt = "Um artigo famoso diz que seus trens vivem atrasados e sujos. A cidade inteira está comentando.", en = "A well-known article says your trains are always late and dirty. The whole city is talking." },
		opcoes = {
			{ pt = "Convidá-lo para uma viagem", en = "Invite him on a trip", ef = { D(-0.5), M("geral", 1.15, 8) } },
			{ pt = "Processar o jornal", en = "Sue the newspaper", ef = { SORTE(0.5, { XP(40) }, { M("geral", 0.85, 10) }) } },
			{ pt = "Ignorar", en = "Ignore it", ef = { M("geral", 0.9, 8) } },
		},
	},
	{
		id = "trem_imigrantes", era = "vapor", emoji = "passageiros", alvo = { regiao = "se" },
		titulo = { pt = "Fazendeiros pedem trens para imigrantes", en = "Farmers ask for immigrant trains" },
		texto = { pt = "Navios cheios de famílias italianas chegam toda semana. Os fazendeiros querem levá-las logo para o interior.", en = "Ships full of Italian families arrive every week. The farmers want them taken inland quickly." },
		opcoes = {
			{ pt = "Criar um trem de imigrantes", en = "Run an immigrant train", ef = { D(-1), M("regiao", 1.3, 15) } },
			{ pt = "Cobrar o transporte dos fazendeiros", en = "Bill the farmers for the transport", ef = { D(2) } },
		},
	},
	{
		id = "telegrafo", era = "vapor", emoji = "info", alvo = nil,
		titulo = { pt = "Telégrafo ao longo dos trilhos", en = "Telegraph along the tracks" },
		texto = { pt = "Com fios ao lado da linha, as estações avisariam umas às outras sobre cada trem. O governo também quer usar os postes.", en = "With wires beside the line, stations could warn each other about every train. The government wants the poles too." },
		opcoes = {
			{ pt = "Instalar o telégrafo", en = "Install the telegraph", ef = { D(-3), M("manutencao", 0.8, 20), XP(40) } },
			{ pt = "Alugar os postes ao governo", en = "Rent the poles to the government", ef = { D(2) } },
		},
	},
	{
		id = "bitola", era = "vapor", emoji = "linhas", alvo = nil,
		titulo = { pt = "Bitola larga ou estreita?", en = "Broad gauge or narrow?" },
		texto = { pt = "Os engenheiros discutem a distância entre os trilhos das próximas obras. Larga é mais rápida; estreita é mais barata.", en = "The engineers argue over the gauge for the next works. Broad is faster; narrow is cheaper." },
		opcoes = {
			{ pt = "Bitola larga", en = "Broad gauge", ef = { D(-3), M("geral", 1.2, 20) } },
			{ pt = "Bitola métrica", en = "Metre gauge", ef = { D(2) } },
		},
	},
	{
		id = "seringalistas", era = "vapor", emoji = "carga_borracha", alvo = nil,
		titulo = { pt = "Os barões da borracha querem sócios", en = "The rubber barons want partners" },
		texto = { pt = "Manaus e Belém estão ricas com a borracha. Os seringalistas convidam a companhia para investir na Amazônia.", en = "Manaus and Belém are rich from rubber. The rubber barons invite the company to invest in the Amazon." },
		opcoes = {
			{ pt = "Investir na borracha", en = "Invest in rubber", ef = { D(-2), SORTE(0.6, { D(5) }, {}) } },
			{ pt = "Ficar de fora", en = "Stay out", ef = {} },
		},
	},
	{
		id = "exposicao_universal", era = "vapor", emoji = "medalha", alvo = nil,
		titulo = { pt = "Convite para a Exposição Universal", en = "Invitation to the World's Fair" },
		texto = { pt = "Paris convida o Brasil a mostrar suas ferrovias. Levar uma locomotiva de navio custa caro, mas daria fama.", en = "Paris invites Brazil to show off its railways. Shipping a locomotive is expensive, but it would bring fame." },
		opcoes = {
			{ pt = "Levar uma locomotiva", en = "Ship a locomotive over", ef = { D(-2), M("geral", 1.1, 15), XP(80) } },
			{ pt = "Mandar só fotografias", en = "Send photographs only", ef = { D(-0.3), XP(20) } },
			{ pt = "Recusar o convite", en = "Decline the invitation", ef = {} },
		},
	},
	{
		id = "gripe_espanhola", era = "vapor", emoji = "alerta", alvo = nil,
		titulo = { pt = "A gripe espanhola chega", en = "The Spanish flu arrives" },
		texto = { pt = "A epidemia se espalha pelas cidades. Os passageiros têm medo de viajar em vagões cheios.", en = "The epidemic spreads through the cities. Passengers are afraid of travelling in crowded carriages." },
		opcoes = {
			{ pt = "Desinfetar todos os trens", en = "Disinfect every train", ef = { D(-2), XP(30) } },
			{ pt = "Reduzir os horários", en = "Cut the timetable", ef = { M("geral", 0.8, 10), M("manutencao", 0.7, 10) } },
			{ pt = "Seguir normalmente", en = "Carry on as usual", ef = { M("geral", 0.75, 10) } },
		},
	},
	{
		id = "cangaco", era = "vapor", emoji = "alerta", alvo = { regiao = "ne" },
		titulo = { pt = "Cangaceiros atacam um trem no sertão", en = "Bandits attack a train in the backlands" },
		texto = { pt = "Um bando de cangaceiros parou um trem no %s. Os passageiros estão com medo de voltar a viajar.", en = "A band of cangaceiros held up a train in the %s. Passengers are afraid to travel again." },
		opcoes = {
			{ pt = "Pagar escolta para os trens", en = "Pay for train escorts", ef = { D(-2), M("regiao", 1.1, 15) } },
			{ pt = "Desviar dos trechos perigosos", en = "Avoid the dangerous stretches", ef = { M("regiao", 0.7, 10) } },
		},
	},

	-- ================================================================ DIESEL (1930–1965)
	{
		id = "tropas_1930", era = "diesel", emoji = "alerta", alvo = nil,
		titulo = { pt = "Tropas pedem os seus trens", en = "Troops demand your trains" },
		texto = { pt = "Uma revolução sacode o país. Soldados chegam às estações exigindo trens para levar as tropas.", en = "A revolution shakes the country. Soldiers arrive at the stations demanding trains to move the troops." },
		opcoes = {
			{ pt = "Ceder os trens, com indenização", en = "Hand over the trains, for compensation", ef = { D(3), M("geral", 0.7, 8) } },
			{ pt = "Recusar e manter o serviço", en = "Refuse and keep the service running", ef = { SORTE(0.5, { XP(40) }, { M("geral", 0.8, 10) }) } },
		},
	},
	{
		id = "siderurgica", era = "diesel", emoji = "carga_minerio", alvo = { cidade = "rio" },
		titulo = { pt = "Uma usina de aço no Vale do Paraíba", en = "A steelworks in the Paraíba Valley" },
		texto = { pt = "O governo vai construir a maior siderúrgica da América do Sul, perto de %s. Ela vai precisar de trilhos.", en = "The government will build the largest steelworks in South America, near %s. It will need rails." },
		opcoes = {
			{ pt = "Construir um ramal até a usina", en = "Build a branch to the works", ef = { D(-3), M("cidade", 1.3, 20) } },
			{ pt = "Comprar trilhos de aço baratos", en = "Buy cheap steel rails", ef = { D(-1), M("manutencao", 0.8, 20) } },
			{ pt = "Deixar a usina com as estradas", en = "Leave the works to the roads", ef = {} },
		},
	},
	{
		id = "segunda_guerra", era = "diesel", emoji = "alerta", alvo = nil,
		titulo = { pt = "O Brasil entra na guerra", en = "Brazil enters the war" },
		texto = { pt = "Com o país em guerra, o governo quer prioridade para o transporte de material militar.", en = "With the country at war, the government wants priority for military transport." },
		opcoes = {
			{ pt = "Levar material de guerra", en = "Carry war materiel", ef = { D(4), M("manutencao", 1.3, 10) } },
			{ pt = "Manter os passageiros em primeiro lugar", en = "Keep passengers first", ef = { XP(40) } },
		},
	},
	{
		id = "caminhoes", era = "diesel", emoji = "alerta", alvo = nil,
		titulo = { pt = "Os caminhões chegam", en = "The lorries arrive" },
		texto = { pt = "Estradas novas e caminhões baratos começam a disputar as cargas com a ferrovia.", en = "New roads and cheap lorries start competing with the railway for freight." },
		opcoes = {
			{ pt = "Baixar o preço do frete", en = "Cut freight prices", ef = { M("geral", 0.9, 15), XP(40) } },
			{ pt = "Comprar uma frota de caminhões", en = "Buy a lorry fleet", ef = { D(-3), SORTE(0.5, { D(6) }, {}) } },
			{ pt = "Não fazer nada", en = "Do nothing", ef = { M("geral", 0.8, 10) } },
		},
	},
	{
		id = "diesel_americano", era = "diesel", emoji = "era_diesel", alvo = nil,
		titulo = { pt = "Locomotivas diesel americanas", en = "American diesel locomotives" },
		texto = { pt = "Uma fábrica dos Estados Unidos oferece locomotivas diesel prontas. Uma fábrica nacional promete as suas para depois.", en = "A US factory offers ready-made diesel locomotives. A Brazilian factory promises its own, later." },
		opcoes = {
			{ pt = "Importar agora", en = "Import them now", ef = { D(-3), M("manutencao", 0.7, 20) } },
			{ pt = "Esperar a fábrica nacional", en = "Wait for the Brazilian factory", ef = { XP(50), ESTUDO(5) } },
		},
	},
	{
		id = "copa_1950", era = "diesel", emoji = "medalha", alvo = { cidade = "rio" },
		titulo = { pt = "A Copa do Mundo no Maracanã", en = "The World Cup at the Maracanã" },
		texto = { pt = "O maior estádio do mundo abre em %s e torcedores chegam de todo canto. Os trens podem ajudar ou lucrar.", en = "The world's largest stadium opens in %s and fans pour in from everywhere. Trains can help, or profit." },
		opcoes = {
			{ pt = "Trens extras para o estádio", en = "Extra trains to the stadium", ef = { D(-1), M("cidade", 1.4, 10) } },
			{ pt = "Passagem com preço dobrado", en = "Double the fares", ef = { D(3), M("geral", 0.85, 10) } },
		},
	},
	{
		id = "suburbio_lotado", era = "diesel", emoji = "passageiros", alvo = "linha",
		titulo = { pt = "Trens lotados na linha %s", en = "Packed trains on the %s line" },
		texto = { pt = "Os trabalhadores viajam pendurados nas portas. A imprensa cobra uma solução.", en = "Workers ride hanging out of the doors. The press demands a solution." },
		opcoes = {
			{ pt = "Comprar trens novos", en = "Buy new trains", ef = { D(-2), TREM(1), M("linha", 1.2, 15) } },
			{ pt = "Aumentar a passagem", en = "Raise the fares", ef = { D(2), M("linha", 0.8, 10) } },
		},
	},
	{
		id = "jornada_8h", era = "diesel", emoji = "alerta", alvo = nil,
		titulo = { pt = "Ferroviários pedem jornada de 8 horas", en = "Rail workers demand an 8-hour day" },
		texto = { pt = "O sindicato quer turnos de 8 horas e férias pagas. Se não for atendido, promete greve.", en = "The union wants 8-hour shifts and paid holidays. If ignored, it promises a strike." },
		opcoes = {
			{ pt = "Aceitar as condições", en = "Accept the terms", ef = { D(-2), XP(60) } },
			{ pt = "Recusar", en = "Refuse", ef = { SORTE(0.5, {}, { M("geral", 0.65, 8) }) } },
		},
	},
	{
		id = "petroleo_nosso", era = "diesel", emoji = "era_diesel", alvo = nil,
		titulo = { pt = "\"O petróleo é nosso!\"", en = "\"The oil is ours!\"" },
		texto = { pt = "O Brasil cria sua empresa de petróleo. Dá para fechar um contrato de diesel nacional ou seguir comprando de fora.", en = "Brazil creates its own oil company. You can sign a domestic diesel contract or keep buying abroad." },
		opcoes = {
			{ pt = "Contrato de diesel nacional", en = "Domestic diesel contract", ef = { D(-1), M("manutencao", 0.8, 20) } },
			{ pt = "Diesel importado mais barato", en = "Cheaper imported diesel", ef = { D(2), SORTE(0.6, {}, { M("manutencao", 1.4, 10) }) } },
		},
	},
	{
		id = "obras_brasilia", era = "diesel", emoji = "construir", alvo = nil,
		titulo = { pt = "Uma capital nova no cerrado", en = "A new capital in the cerrado" },
		texto = { pt = "Começam as obras de Brasília. Milhares de operários e toneladas de material precisam chegar ao Planalto.", en = "Work begins on Brasília. Thousands of workers and tonnes of material must reach the Plateau." },
		opcoes = {
			{ pt = "Levar material de construção", en = "Haul construction material", ef = { D(4) } },
			{ pt = "Trens para os operários", en = "Trains for the workers", ef = { M("geral", 1.2, 10), XP(40) } },
		},
	},
	{
		id = "ar_condicionado", era = "diesel", emoji = "melhorar", alvo = "linha",
		titulo = { pt = "Vagões com ar-condicionado", en = "Air-conditioned carriages" },
		texto = { pt = "Uma novidade americana promete viagens fresquinhas no calor. Poderia estrear na linha %s.", en = "An American novelty promises cool journeys in the heat. It could debut on the %s line." },
		opcoes = {
			{ pt = "Em todos os vagões da linha", en = "In every carriage on the line", ef = { D(-2), M("linha", 1.3, 20) } },
			{ pt = "Só na primeira classe", en = "First class only", ef = { D(-0.5), M("linha", 1.1, 15) } },
			{ pt = "Ainda não", en = "Not yet", ef = {} },
		},
	},
	{
		id = "enchente_vale", era = "diesel", emoji = "alerta", alvo = "linha",
		titulo = { pt = "O rio ameaça a linha %s", en = "The river threatens the %s line" },
		texto = { pt = "As chuvas não param e o rio está subindo perto dos trilhos. Os engenheiros sugerem um dique.", en = "The rain won't stop and the river is rising near the tracks. The engineers suggest a dyke." },
		opcoes = {
			{ pt = "Construir o dique", en = "Build the dyke", ef = { D(-3), XP(20) } },
			{ pt = "Torcer para parar de chover", en = "Hope the rain stops", ef = { SORTE(0.4, {}, { M("linha", 0.6, 8) }) } },
		},
	},
	{
		id = "radio_novela", era = "diesel", emoji = "info", alvo = nil,
		titulo = { pt = "Propaganda no rádio", en = "Radio advertising" },
		texto = { pt = "É a era de ouro do rádio. Uma emissora oferece patrocinar a novela mais ouvida do país.", en = "It's the golden age of radio. A station offers you sponsorship of the country's most popular soap opera." },
		opcoes = {
			{ pt = "Patrocinar a novela", en = "Sponsor the soap opera", ef = { D(-1.5), M("geral", 1.2, 12) } },
			{ pt = "Só um jingle barato", en = "Just a cheap jingle", ef = { D(-0.3), SORTE(0.5, { M("geral", 1.15, 10) }, {}) } },
			{ pt = "Propaganda é dinheiro jogado fora", en = "Advertising is money down the drain", ef = {} },
		},
	},
	{
		id = "rodoviarismo", era = "diesel", emoji = "alerta", alvo = nil,
		titulo = { pt = "O governo prefere as estradas", en = "The government favours roads" },
		texto = { pt = "O dinheiro público vai para rodovias e fábricas de carros. As ferrovias perdem prestígio.", en = "Public money goes to highways and car factories. The railways lose prestige." },
		opcoes = {
			{ pt = "Fazer pressão no Congresso", en = "Lobby Congress", ef = { D(-2), SORTE(0.6, { D(5) }, {}) } },
			{ pt = "Enxugar a companhia", en = "Slim down the company", ef = { M("manutencao", 0.75, 15), M("geral", 0.9, 15) } },
		},
	},
	{
		id = "trem_de_luxo", era = "diesel", emoji = "estacoes", alvo = { cidade = "sao_paulo" },
		titulo = { pt = "Um trem de luxo para %s", en = "A luxury train to %s" },
		texto = { pt = "Empresários querem um trem noturno elegante, com restaurante e cabines, ligando as grandes cidades.", en = "Businessmen want an elegant night train, with a restaurant and cabins, linking the big cities." },
		opcoes = {
			{ pt = "Lançar o trem de luxo", en = "Launch the luxury train", ef = { D(-3), M("cidade", 1.35, 20) } },
			{ pt = "Não vale a pena", en = "Not worth it", ef = {} },
		},
	},

	-- ================================================================ ELÉTRICA (1965–2000)
	{
		id = "eletrificar", era = "eletrico", emoji = "era_eletrico", alvo = nil,
		titulo = { pt = "Subsídio para eletrificar", en = "A subsidy to electrify" },
		texto = { pt = "O governo oferece ajuda para trocar o diesel por energia elétrica, desde que a companhia ponha a sua parte.", en = "The government offers help to swap diesel for electric power, as long as the company pays its share." },
		opcoes = {
			{ pt = "Aceitar e eletrificar", en = "Accept and electrify", ef = { D(-3), M("manutencao", 0.7, 20) } },
			{ pt = "Recusar e ficar com o dinheiro", en = "Decline and keep the cash", ef = { D(1) } },
		},
	},
	{
		id = "choque_petroleo", era = "eletrico", emoji = "alerta", alvo = nil,
		titulo = { pt = "Choque do petróleo", en = "Oil shock" },
		texto = { pt = "O preço do petróleo dispara no mundo inteiro. O diesel dos seus trens fica caríssimo.", en = "Oil prices soar worldwide. The diesel for your trains becomes very expensive." },
		opcoes = {
			{ pt = "Acelerar a troca por trens elétricos", en = "Speed up the switch to electric", ef = { D(-3), M("manutencao", 0.6, 15) } },
			{ pt = "Repassar o custo ao passageiro", en = "Pass the cost on to passengers", ef = { D(2), M("geral", 0.8, 10) } },
		},
	},
	{
		id = "carajas", era = "eletrico", emoji = "carga_minerio", alvo = nil,
		titulo = { pt = "Descoberta a serra de Carajás", en = "The Carajás range discovered" },
		texto = { pt = "Geólogos acham uma das maiores reservas de ferro do planeta no Pará. Quem vai levar esse minério até o mar?", en = "Geologists find one of the planet's largest iron reserves in Pará. Who will carry that ore to the sea?" },
		opcoes = {
			{ pt = "Estudar uma ferrovia até lá", en = "Study a railway out there", ef = { D(-2), ESTUDO(8), XP(40) } },
			{ pt = "Vender os direitos", en = "Sell the rights", ef = { D(4) } },
		},
	},
	{
		id = "metro_sp", era = "eletrico", emoji = "linhas", alvo = { cidade = "sao_paulo" },
		titulo = { pt = "%s inaugura o metrô", en = "%s opens its metro" },
		texto = { pt = "A primeira linha de metrô do Brasil começa a funcionar. Dá para integrar as estações ou disputar passageiros.", en = "Brazil's first metro line opens. You can integrate the stations or compete for passengers." },
		opcoes = {
			{ pt = "Integrar as estações", en = "Integrate the stations", ef = { D(-2), M("cidade", 1.3, 20) } },
			{ pt = "Competir com o metrô", en = "Compete with the metro", ef = { D(1), M("cidade", 0.85, 10) } },
		},
	},
	{
		id = "inflacao", era = "eletrico", emoji = "dinheiro", alvo = nil,
		titulo = { pt = "A inflação dispara", en = "Inflation runs wild" },
		texto = { pt = "Os preços sobem toda semana. As passagens não acompanham e o dinheiro em caixa perde valor.", en = "Prices rise every week. Fares lag behind and the cash in the till loses value." },
		opcoes = {
			{ pt = "Reajustar as passagens toda semana", en = "Raise fares every week", ef = { D(3), M("geral", 0.85, 10) } },
			{ pt = "Congelar as tarifas", en = "Freeze the fares", ef = { M("geral", 0.95, 10), XP(60) } },
			{ pt = "Aplicar o caixa no mercado", en = "Put the cash on the market", ef = { SORTE(0.5, { D(6) }, { D(-3) }) } },
		},
	},
	{
		id = "concessao", era = "eletrico", emoji = "contratos", alvo = nil,
		titulo = { pt = "Leilão de concessões ferroviárias", en = "Railway concessions auction" },
		texto = { pt = "O governo vai leiloar as ferrovias estatais. Comprar uma concessão custa caro, mas amplia o negócio.", en = "The government will auction the state railways. A concession is expensive, but it grows the business." },
		opcoes = {
			{ pt = "Arrematar uma concessão", en = "Win a concession", ef = { D(-5), M("geral", 1.25, 25) } },
			{ pt = "Ficar de fora do leilão", en = "Sit out the auction", ef = {} },
		},
	},
	{
		id = "maria_fumaca", era = "eletrico", emoji = "era_vapor", alvo = "linha",
		titulo = { pt = "Uma maria-fumaça esquecida", en = "A forgotten steam engine" },
		texto = { pt = "No fundo de um galpão da linha %s, acharam uma locomotiva a vapor antiga, ainda inteira.", en = "At the back of a shed on the %s line, they found an old steam locomotive, still in one piece." },
		opcoes = {
			{ pt = "Restaurar para um trem turístico", en = "Restore it for a tourist train", ef = { D(-1.5), M("linha", 1.2, 20), XP(50) } },
			{ pt = "Vender para um museu", en = "Sell it to a museum", ef = { D(2) } },
		},
	},
	{
		id = "greve_geral", era = "eletrico", emoji = "alerta", alvo = nil,
		titulo = { pt = "Greve geral", en = "General strike" },
		texto = { pt = "Os trabalhadores de várias categorias param ao mesmo tempo. Os ferroviários querem aderir.", en = "Workers from many trades stop at once. The rail workers want to join in." },
		opcoes = {
			{ pt = "Fechar um acordo antes", en = "Strike a deal first", ef = { D(-2) } },
			{ pt = "Esperar a greve acabar", en = "Wait for the strike to end", ef = { M("geral", 0.7, 10) } },
		},
	},
	{
		id = "computadores", era = "eletrico", emoji = "info", alvo = nil,
		titulo = { pt = "Reservas por computador", en = "Computer reservations" },
		texto = { pt = "Uma empresa oferece um computador enorme que controla passagens e horários de todos os trens.", en = "A company offers a huge computer that manages tickets and timetables for every train." },
		opcoes = {
			{ pt = "Comprar o computador", en = "Buy the computer", ef = { D(-2), M("geral", 1.15, 20) } },
			{ pt = "Continuar no papel", en = "Stay on paper", ef = {} },
		},
	},
	{
		id = "tri_mexico", era = "eletrico", emoji = "medalha", alvo = nil,
		titulo = { pt = "Tricampeões no México!", en = "Three-time world champions!" },
		texto = { pt = "A seleção ganha a Copa e o país inteiro sai às ruas para festejar.", en = "The national team wins the World Cup and the whole country takes to the streets." },
		opcoes = {
			{ pt = "Trem da vitória de graça", en = "Free victory train", ef = { D(-1), M("geral", 1.3, 8), XP(30) } },
			{ pt = "Dia normal de trabalho", en = "Business as usual", ef = {} },
		},
	},
	{
		id = "ferrovia_do_aco", era = "eletrico", emoji = "construir", alvo = nil,
		titulo = { pt = "A Ferrovia do Aço", en = "The Steel Railway" },
		texto = { pt = "Um projeto gigante quer ligar as minas às usinas por túneis e pontes. Pode dar muito certo ou virar obra parada.", en = "A giant project wants to link mines to mills through tunnels and bridges. It could succeed or stall forever." },
		opcoes = {
			{ pt = "Entrar no consórcio", en = "Join the consortium", ef = { D(-4), SORTE(0.5, { D(10) }, {}) } },
			{ pt = "Não arriscar", en = "Don't risk it", ef = {} },
		},
	},
	{
		id = "conteineres", era = "eletrico", emoji = "cargas", alvo = nil,
		titulo = { pt = "Os contêineres chegam aos portos", en = "Containers reach the ports" },
		texto = { pt = "As caixas de aço padronizadas mudam o comércio do mundo. Os portos querem terminais novos.", en = "Standardised steel boxes are changing world trade. The ports want new terminals." },
		opcoes = {
			{ pt = "Construir um terminal de contêineres", en = "Build a container terminal", ef = { D(-3), M("geral", 1.2, 20) } },
			{ pt = "Seguir com carga solta", en = "Stick with loose cargo", ef = {} },
		},
	},
	{
		id = "barulho", era = "eletrico", emoji = "alerta", alvo = "cidade",
		titulo = { pt = "Moradores de %s reclamam do barulho", en = "%s residents complain about the noise" },
		texto = { pt = "Os vizinhos da linha fazem abaixo-assinado contra o barulho dos trens de madrugada.", en = "People living by the line sign a petition against the noise of trains at night." },
		opcoes = {
			{ pt = "Construir barreiras acústicas", en = "Build noise barriers", ef = { D(-1.5), M("cidade", 1.15, 15) } },
			{ pt = "Ignorar a reclamação", en = "Ignore the complaint", ef = { M("cidade", 0.8, 10) } },
		},
	},
	{
		id = "plano_real", era = "eletrico", emoji = "dinheiro", alvo = nil,
		titulo = { pt = "Moeda nova, o Real", en = "A new currency, the Real" },
		texto = { pt = "O país troca de moeda e as passagens precisam ser convertidas. Arredondar para cima ou para baixo?", en = "The country changes currency and fares must be converted. Round up or round down?" },
		opcoes = {
			{ pt = "Arredondar para cima", en = "Round up", ef = { D(3), M("geral", 0.9, 10) } },
			{ pt = "Arredondar para baixo", en = "Round down", ef = { D(-1), M("geral", 1.2, 10), XP(40) } },
		},
	},
	{
		id = "trem_hotel", era = "eletrico", emoji = "estacoes", alvo = { cidade = "rio" },
		titulo = { pt = "Um trem-hotel noturno", en = "A night hotel-train" },
		texto = { pt = "Que tal dormir em %s e acordar na outra cidade? Uma rede de hotéis propõe uma parceria.", en = "How about falling asleep in %s and waking up in another city? A hotel chain proposes a partnership." },
		opcoes = {
			{ pt = "Lançar o trem-hotel", en = "Launch the hotel-train", ef = { D(-2), M("cidade", 1.25, 20) } },
			{ pt = "Deixar para outra hora", en = "Maybe another time", ef = {} },
		},
	},

	-- ================================================================ ALTA VELOCIDADE (2000–2030)
	{
		id = "racionamento", era = "alta", emoji = "era_eletrico", alvo = nil,
		titulo = { pt = "Racionamento de energia", en = "Power rationing" },
		texto = { pt = "Os reservatórios secaram e o governo manda cortar o consumo de eletricidade.", en = "The reservoirs have dried up and the government orders electricity use to be cut." },
		opcoes = {
			{ pt = "Comprar geradores próprios", en = "Buy your own generators", ef = { D(-3) } },
			{ pt = "Reduzir os horários", en = "Cut the timetable", ef = { M("geral", 0.75, 10), M("manutencao", 0.7, 10) } },
		},
	},
	{
		id = "pre_sal", era = "alta", emoji = "cargas", alvo = { cidade = "santos" },
		titulo = { pt = "Petróleo no pré-sal", en = "Pre-salt oil" },
		texto = { pt = "Acharam petróleo no fundo do mar, perto de %s. O porto vai crescer muito.", en = "Oil has been found deep under the sea, near %s. The port is going to grow a lot." },
		opcoes = {
			{ pt = "Ampliar a linha até o porto", en = "Expand the line to the port", ef = { D(-3), M("cidade", 1.3, 20) } },
			{ pt = "Vender terrenos perto do porto", en = "Sell land near the port", ef = { D(4) } },
		},
	},
	{
		id = "copa_2014", era = "alta", emoji = "medalha", alvo = nil,
		titulo = { pt = "A Copa volta ao Brasil", en = "The World Cup returns to Brazil" },
		texto = { pt = "Torcedores do mundo inteiro vêm assistir aos jogos. Os estádios ficam longe do centro.", en = "Fans from all over the world come to watch. The stadiums are far from the city centres." },
		opcoes = {
			{ pt = "Trens especiais para os estádios", en = "Special trains to the stadiums", ef = { D(-2), M("geral", 1.3, 10) } },
			{ pt = "Cobrar mais caro dos turistas", en = "Charge tourists more", ef = { D(3), M("geral", 0.85, 8) } },
		},
	},
	{
		id = "olimpiada_rio", era = "alta", emoji = "medalha", alvo = { cidade = "rio" },
		titulo = { pt = "Olimpíada em %s", en = "Olympic Games in %s" },
		texto = { pt = "A cidade recebe os Jogos e precisa de transporte para atletas e público.", en = "The city hosts the Games and needs transport for athletes and spectators." },
		opcoes = {
			{ pt = "Criar o trem olímpico", en = "Create the Olympic train", ef = { D(-2), M("cidade", 1.45, 10) } },
			{ pt = "Deixar com os ônibus", en = "Leave it to the buses", ef = {} },
		},
	},
	{
		id = "aplicativo", era = "alta", emoji = "info", alvo = nil,
		titulo = { pt = "Um aplicativo de passagens", en = "A ticketing app" },
		texto = { pt = "Os passageiros querem comprar a passagem pelo celular. Fazer em casa ou contratar uma empresa barata?", en = "Passengers want to buy tickets on their phones. Build it in-house or hire a cheap firm?" },
		opcoes = {
			{ pt = "Desenvolver um aplicativo próprio", en = "Build your own app", ef = { D(-2), M("geral", 1.2, 25) } },
			{ pt = "Contratar uma empresa barata", en = "Hire a cheap firm", ef = { D(-0.5), SORTE(0.6, { M("geral", 1.15, 15) }, { M("geral", 0.9, 10) }) } },
			{ pt = "Bilhete de papel ainda funciona", en = "Paper tickets still work", ef = { M("geral", 0.95, 10) } },
		},
	},
	{
		id = "paineis_solares", era = "alta", emoji = "era_alta", alvo = nil,
		titulo = { pt = "Painéis solares nas estações", en = "Solar panels on the stations" },
		texto = { pt = "Os telhados das estações poderiam gerar parte da energia dos trens.", en = "Station roofs could generate part of the trains' power." },
		opcoes = {
			{ pt = "Instalar os painéis", en = "Install the panels", ef = { D(-3), M("manutencao", 0.65, 25), XP(50) } },
			{ pt = "Ainda é cedo", en = "It's still early days", ef = {} },
		},
	},
	{
		id = "pandemia", era = "alta", emoji = "alerta", alvo = nil,
		titulo = { pt = "Uma pandemia esvazia os trens", en = "A pandemic empties the trains" },
		texto = { pt = "As pessoas ficam em casa e os vagões rodam quase vazios.", en = "People stay at home and the carriages run almost empty." },
		opcoes = {
			{ pt = "Manter o serviço com protocolos", en = "Keep running, with safety rules", ef = { D(-2), XP(50) } },
			{ pt = "Reduzir a frota por um tempo", en = "Cut the fleet for a while", ef = { M("geral", 0.65, 10), M("manutencao", 0.6, 10) } },
		},
	},
	{
		id = "hackers", era = "alta", emoji = "alerta", alvo = nil,
		titulo = { pt = "Ataque ao sistema de bilhetes", en = "Attack on the ticketing system" },
		texto = { pt = "Invasores derrubam o sistema de passagens. As filas tomam conta das estações.", en = "Intruders bring down the ticketing system. Queues take over the stations." },
		opcoes = {
			{ pt = "Chamar especialistas em segurança", en = "Call in security experts", ef = { D(-2) } },
			{ pt = "Restaurar o backup e torcer", en = "Restore the backup and hope", ef = { SORTE(0.5, {}, { M("geral", 0.7, 10) }) } },
		},
	},
	{
		id = "trem_autonomo", era = "alta", emoji = "trens", alvo = "linha",
		titulo = { pt = "Trens sem maquinista", en = "Driverless trains" },
		texto = { pt = "Um fabricante quer testar trens autônomos na linha %s. Se funcionar, a operação fica bem mais barata.", en = "A manufacturer wants to test self-driving trains on the %s line. If it works, operations get much cheaper." },
		opcoes = {
			{ pt = "Testar na linha", en = "Test them on the line", ef = { D(-3), SORTE(0.7, { M("manutencao", 0.6, 20) }, { M("linha", 0.7, 10) }) } },
			{ pt = "Esperar a tecnologia amadurecer", en = "Wait for the technology to mature", ef = {} },
		},
	},
	{
		id = "influenciador", era = "alta", emoji = "prestigio", alvo = "linha",
		titulo = { pt = "Um vídeo viraliza na linha %s", en = "A video goes viral on the %s line" },
		texto = { pt = "Um influenciador filmou a viagem e milhões de pessoas assistiram.", en = "An influencer filmed the journey and millions watched it." },
		opcoes = {
			{ pt = "Patrocinar mais vídeos", en = "Sponsor more videos", ef = { D(-1), M("linha", 1.25, 15) } },
			{ pt = "Aproveitar a onda de graça", en = "Ride the wave for free", ef = { M("linha", 1.1, 8) } },
		},
	},
	{
		id = "hidrogenio", era = "alta", emoji = "pesquisa", alvo = nil,
		titulo = { pt = "Locomotiva a hidrogênio", en = "Hydrogen locomotive" },
		texto = { pt = "Uma universidade propõe uma parceria para pesquisar trens movidos a hidrogênio.", en = "A university proposes a partnership to research hydrogen-powered trains." },
		opcoes = {
			{ pt = "Financiar a pesquisa", en = "Fund the research", ef = { D(-2), ESTUDO(10), XP(50) } },
			{ pt = "Não agora", en = "Not now", ef = {} },
		},
	},
	{
		id = "greve_caminhoneiros", era = "alta", emoji = "cargas", alvo = nil,
		titulo = { pt = "Greve dos caminhoneiros", en = "Truckers' strike" },
		texto = { pt = "As estradas param e falta de tudo nas cidades. Só os trens continuam rodando.", en = "The roads grind to a halt and cities run short of everything. Only the trains keep moving." },
		opcoes = {
			{ pt = "Trens de carga extras, preço justo", en = "Extra freight trains, fair price", ef = { D(-1), M("geral", 1.3, 10), XP(40) } },
			{ pt = "Aproveitar e cobrar mais", en = "Cash in and charge more", ef = { D(4), M("geral", 0.9, 10) } },
		},
	},
	{
		id = "chuvas_extremas", era = "alta", emoji = "alerta", alvo = "linha",
		titulo = { pt = "Chuvas extremas na linha %s", en = "Extreme rain on the %s line" },
		texto = { pt = "Os temporais estão cada vez mais fortes. Os engenheiros pedem uma drenagem moderna.", en = "The storms keep getting stronger. The engineers ask for modern drainage." },
		opcoes = {
			{ pt = "Investir em drenagem", en = "Invest in drainage", ef = { D(-3), XP(30) } },
			{ pt = "Arriscar", en = "Take the risk", ef = { SORTE(0.5, {}, { M("linha", 0.6, 10) }) } },
		},
	},
	{
		id = "carros_autonomos", era = "alta", emoji = "alerta", alvo = nil,
		titulo = { pt = "Carros autônomos ameaçam o trem", en = "Self-driving cars threaten the train" },
		texto = { pt = "Os carros que dirigem sozinhos chegam às ruas. Muita gente acha que o trem vai sobrar.", en = "Self-driving cars hit the streets. Many people think the train will be left behind." },
		opcoes = {
			{ pt = "Integrar os carros às estações", en = "Integrate the cars with the stations", ef = { D(-2), M("geral", 1.2, 20) } },
			{ pt = "Ignorar a moda", en = "Ignore the fad", ef = { M("geral", 0.9, 15) } },
		},
	},
	{
		id = "turistas", era = "alta", emoji = "passageiros", alvo = nil,
		titulo = { pt = "Turistas descobrem os trens", en = "Tourists discover the trains" },
		texto = { pt = "Guias de viagem estrangeiros recomendam conhecer o Brasil de trem.", en = "Foreign travel guides recommend seeing Brazil by train." },
		opcoes = {
			{ pt = "Criar um trem panorâmico", en = "Create a panoramic train", ef = { D(-2), M("geral", 1.2, 20) } },
			{ pt = "Vender pacotes para agências", en = "Sell packages to agencies", ef = { D(3) } },
		},
	},
	-- ================================================================ EUA (mapa = "eua"), 8 por era
	-- ---------------------------------------------------------------- Vapor (1830–1935)
	{
		id = "eua_terras", mapa = "eua", era = "vapor", emoji = "linhas", alvo = nil,
		titulo = { pt = "O Congresso oferece terras", en = "Congress offers land" },
		texto = { pt = "Para cada quilômetro de trilho, o governo dá terras dos dois lados da linha. Em troca, a companhia leva o correio e as tropas por um preço baixo.", en = "For every mile of track, the government grants land on both sides of the line. In return, the company carries the mail and the troops at a low price." },
		opcoes = {
			{ pt = "Aceitar as terras", en = "Accept the land", ef = { D(5), M("geral", 0.9, 15) } },
			{ pt = "Construir sem ajuda", en = "Build without help", ef = { XP(50) } },
		},
	},
	{
		id = "eua_prego_ouro", mapa = "eua", era = "vapor", emoji = "medalha", alvo = "linha",
		titulo = { pt = "O último prego da linha %s", en = "The last spike on the %s line" },
		texto = { pt = "As duas frentes de obra se encontraram. Os jornais querem uma cerimônia com prego de ouro e telégrafo para o país inteiro.", en = "The two work gangs have met. The papers want a ceremony with a golden spike, telegraphed to the whole country." },
		opcoes = {
			{ pt = "Fazer a festa do prego de ouro", en = "Hold the golden spike ceremony", ef = { D(-1), M("linha", 1.3, 10), XP(50) } },
			{ pt = "Abrir a linha sem festa", en = "Open the line without fuss", ef = { XP(10) } },
		},
	},
	{
		id = "eua_assaltantes", mapa = "eua", era = "vapor", emoji = "alerta", alvo = "linha",
		titulo = { pt = "Assaltantes de trem na linha %s", en = "Train robbers on the %s line" },
		texto = { pt = "Uma quadrilha parou um trem e levou o cofre do vagão expresso. Os passageiros estão com medo de viajar.", en = "A gang stopped a train and took the express car's safe. Passengers are afraid to travel." },
		opcoes = {
			{ pt = "Contratar detetives particulares", en = "Hire private detectives", ef = { D(-2), XP(30) } },
			{ pt = "Blindar o vagão expresso", en = "Armor the express car", ef = { D(-1), M("linha", 1.1, 10) } },
			{ pt = "Torcer para não se repetir", en = "Hope it won't happen again", ef = { SORTE(0.5, {}, { M("linha", 0.7, 10) }) } },
		},
	},
	{
		id = "eua_hora_padrao", mapa = "eua", era = "vapor", emoji = "relogio", alvo = nil,
		titulo = { pt = "Que horas são, afinal?", en = "What time is it, anyway?" },
		texto = { pt = "Cada cidade acerta o relógio pelo sol e os horários viram uma confusão. As ferrovias propõem dividir o país em fusos horários.", en = "Every town sets its clock by the sun and timetables are a mess. The railroads propose dividing the country into time zones." },
		opcoes = {
			{ pt = "Adotar a hora padrão", en = "Adopt standard time", ef = { D(-1), M("manutencao", 0.8, 20), XP(40) } },
			{ pt = "Manter a hora de cada cidade", en = "Keep each town's own time", ef = { M("geral", 0.95, 10) } },
		},
	},
	{
		id = "eua_freio_ar", mapa = "eua", era = "vapor", emoji = "construir", alvo = nil,
		titulo = { pt = "O freio a ar de Westinghouse", en = "Westinghouse's air brake" },
		texto = { pt = "Um jovem inventor mostra um freio que o maquinista aciona em todos os vagões de uma vez. Os guarda-freios não precisariam mais correr pelo teto.", en = "A young inventor shows a brake the engineer applies on every car at once. Brakemen would no longer have to run along the roofs." },
		opcoes = {
			{ pt = "Instalar em toda a frota", en = "Fit the whole fleet", ef = { D(-3), M("manutencao", 0.75, 20), XP(40) } },
			{ pt = "Continuar com o freio manual", en = "Stay with hand brakes", ef = {} },
		},
	},
	{
		id = "eua_pullman", mapa = "eua", era = "vapor", emoji = "passageiros", alvo = nil,
		titulo = { pt = "Vagões-dormitório de luxo", en = "Luxury sleeping cars" },
		texto = { pt = "George Pullman oferece seus vagões-dormitório, com camas, tapetes e serviço de bordo. Ele fica com uma parte da passagem.", en = "George Pullman offers his sleeping cars, with beds, carpets and onboard service. He keeps a share of the fare." },
		opcoes = {
			{ pt = "Alugar os vagões Pullman", en = "Lease the Pullman cars", ef = { D(-2), M("geral", 1.2, 15) } },
			{ pt = "Ficar com os vagões simples", en = "Keep the plain cars", ef = {} },
		},
	},
	{
		id = "eua_neve_serra", mapa = "eua", era = "vapor", emoji = "terreno_montanha", alvo = { regiao = "o" },
		titulo = { pt = "Neve nas montanhas do %s", en = "Snow in the mountains of the %s" },
		texto = { pt = "No inverno, a neve enterra os trilhos nos passos de montanha. Os engenheiros sugerem cobrir a linha com galpões de madeira.", en = "In winter, snow buries the tracks in the mountain passes. The engineers suggest covering the line with timber snow sheds." },
		opcoes = {
			{ pt = "Construir os galpões de neve", en = "Build the snow sheds", ef = { D(-2), M("manutencao", 0.8, 15) } },
			{ pt = "Esperar o degelo", en = "Wait for the thaw", ef = { M("regiao", 0.75, 8) } },
		},
	},
	{
		id = "eua_carvao", mapa = "eua", era = "vapor", emoji = "carga_carvao", alvo = { carga = "carvao" },
		titulo = { pt = "A mineradora quer um contrato longo", en = "The coal company wants a long contract" },
		texto = { pt = "Uma mineradora promete mandar todo o carvão pela sua ferrovia por anos. Mas quer pagar menos pelo frete.", en = "A mining company promises to ship all its coal on your railroad for years. But it wants to pay less freight." },
		opcoes = {
			{ pt = "Assinar o contrato", en = "Sign the contract", ef = { D(3), M("carga", 0.85, 15) } },
			{ pt = "Manter o preço do frete", en = "Keep the freight rate", ef = { XP(30) } },
		},
	},
	-- ---------------------------------------------------------------- Diesel (1935–1970)
	{
		id = "eua_zephyr", mapa = "eua", era = "diesel", emoji = "velocidade", alvo = "linha",
		titulo = { pt = "Um trem aerodinâmico de aço inoxidável", en = "A stainless steel streamliner" },
		texto = { pt = "Uma fábrica oferece um trem a diesel, prateado e aerodinâmico, para a linha %s. Os jornais adoram.", en = "A builder offers a silver, streamlined diesel train for the %s line. The newspapers love it." },
		opcoes = {
			{ pt = "Comprar o trem aerodinâmico", en = "Buy the streamliner", ef = { D(-3), TREM(1), M("linha", 1.25, 15) } },
			{ pt = "Esperar o preço cair", en = "Wait for the price to drop", ef = {} },
		},
	},
	{
		id = "eua_tropas", mapa = "eua", era = "diesel", emoji = "trens", alvo = nil,
		titulo = { pt = "O exército precisa de trens", en = "The army needs trains" },
		texto = { pt = "O país entrou na guerra e milhões de soldados precisam cruzar o continente. O governo pede prioridade nos trilhos.", en = "The country is at war and millions of soldiers must cross the continent. The government asks for priority on the rails." },
		opcoes = {
			{ pt = "Dar prioridade às tropas", en = "Give the troops priority", ef = { M("geral", 0.85, 10), XP(80) } },
			{ pt = "Cobrar o preço normal", en = "Charge the normal rate", ef = { D(2) } },
		},
	},
	{
		id = "eua_dieselizar", mapa = "eua", era = "diesel", emoji = "era_diesel", alvo = nil,
		titulo = { pt = "Aposentar as locomotivas a vapor?", en = "Retire the steam locomotives?" },
		texto = { pt = "As locomotivas a diesel quase não param para manutenção. Mas trocar a frota inteira custa caro.", en = "Diesel locomotives hardly ever stop for maintenance. But replacing the whole fleet is expensive." },
		opcoes = {
			{ pt = "Trocar tudo pelo diesel", en = "Go all diesel", ef = { D(-3), M("manutencao", 0.7, 20) } },
			{ pt = "Trocar aos poucos", en = "Switch gradually", ef = { D(-1), M("manutencao", 0.9, 15) } },
		},
	},
	{
		id = "eua_rodovias", mapa = "eua", era = "diesel", emoji = "alerta", alvo = nil,
		titulo = { pt = "As rodovias interestaduais chegam", en = "The interstate highways arrive" },
		texto = { pt = "O governo começa uma rede de rodovias pelo país inteiro. Os caminhões vão disputar a carga dos trens.", en = "The government starts a highway network across the whole country. Trucks will compete for the trains' freight." },
		opcoes = {
			{ pt = "Levar os caminhões em vagões-plataforma", en = "Carry the trailers on flatcars", ef = { D(-2), M("geral", 1.15, 15) } },
			{ pt = "Cortar os trens menos usados", en = "Cut the least-used trains", ef = { M("manutencao", 0.8, 15), M("geral", 0.9, 15) } },
		},
	},
	{
		id = "eua_avioes", mapa = "eua", era = "diesel", emoji = "passageiros", alvo = nil,
		titulo = { pt = "Os aviões levam os passageiros", en = "Airliners take the passengers" },
		texto = { pt = "Voar de costa a costa ficou rápido e barato. Os trens de longa distância andam meio vazios.", en = "Flying coast to coast has become fast and cheap. Long-distance trains run half empty." },
		opcoes = {
			{ pt = "Vagões panorâmicos com cúpula de vidro", en = "Glass-domed observation cars", ef = { D(-2), M("geral", 1.15, 12) } },
			{ pt = "Baixar o preço das passagens", en = "Lower the fares", ef = { M("geral", 1.05, 12) } },
		},
	},
	{
		id = "eua_poeira", mapa = "eua", era = "diesel", emoji = "carga_graos", alvo = { regiao = "mw" },
		titulo = { pt = "Seca e poeira no %s", en = "Drought and dust in the %s" },
		texto = { pt = "As tempestades de poeira arruinaram as fazendas. Famílias inteiras precisam de comida e de transporte.", en = "Dust storms have ruined the farms. Whole families need food and transport." },
		opcoes = {
			{ pt = "Levar ajuda de graça", en = "Carry relief for free", ef = { D(-1), XP(60) } },
			{ pt = "Cobrar o frete normal", en = "Charge the normal freight", ef = { D(1), M("regiao", 0.9, 10) } },
		},
	},
	{
		id = "eua_tapete_vermelho", mapa = "eua", era = "diesel", emoji = "prestigio", alvo = { cidade = "new_york" },
		titulo = { pt = "Tapete vermelho em %s", en = "Red carpet in %s" },
		texto = { pt = "O trem expresso de luxo entre Nova York e Chicago vira moda. Celebridades querem embarcar sobre um tapete vermelho.", en = "The luxury express between New York and Chicago is all the rage. Celebrities want to board on a red carpet." },
		opcoes = {
			{ pt = "Estender o tapete vermelho", en = "Roll out the red carpet", ef = { D(-2), M("cidade", 1.3, 12) } },
			{ pt = "Serviço normal", en = "Regular service", ef = {} },
		},
	},
	{
		id = "eua_oleodutos", mapa = "eua", era = "diesel", emoji = "carga_petroleo", alvo = { carga = "petroleo" },
		titulo = { pt = "As petroleiras constroem oleodutos", en = "The oil companies build pipelines" },
		texto = { pt = "Os oleodutos podem levar o petróleo sem trem nenhum. As petroleiras ficam se você baixar o frete.", en = "Pipelines can move oil with no trains at all. The oil companies will stay if you lower the freight rate." },
		opcoes = {
			{ pt = "Baixar o frete", en = "Lower the freight rate", ef = { M("carga", 0.85, 15) } },
			{ pt = "Manter o preço e arriscar", en = "Keep the price and take the risk", ef = { SORTE(0.5, {}, { M("carga", 0.6, 15) }) } },
		},
	},
	-- ---------------------------------------------------------------- Elétrica (1970–2000)
	{
		id = "eua_amtrak", mapa = "eua", era = "eletrico", emoji = "passageiros", alvo = nil,
		titulo = { pt = "O governo cria a Amtrak", en = "The government creates Amtrak" },
		texto = { pt = "Uma empresa federal se oferece para assumir os trens de passageiros, que dão prejuízo. A companhia ficaria só com a carga.", en = "A federal company offers to take over the money-losing passenger trains. The company would keep only the freight." },
		opcoes = {
			{ pt = "Passar os passageiros à Amtrak", en = "Hand the passengers to Amtrak", ef = { D(3), M("geral", 0.85, 20) } },
			{ pt = "Continuar com os passageiros", en = "Keep the passengers", ef = { XP(40) } },
		},
	},
	{
		id = "eua_falencia_vizinha", mapa = "eua", era = "eletrico", emoji = "banco", alvo = { regiao = "ne" },
		titulo = { pt = "Ferrovias falidas no %s", en = "Bankrupt railroads in the %s" },
		texto = { pt = "As velhas ferrovias do %s quebraram. O governo procura alguém para assumir as linhas, com ajuda federal.", en = "The old railroads of the %s have gone bust. The government is looking for someone to take over the lines, with federal aid." },
		opcoes = {
			{ pt = "Assumir as linhas com ajuda", en = "Take over the lines with aid", ef = { D(4), M("manutencao", 1.15, 15) } },
			{ pt = "Ficar de fora", en = "Stay out", ef = {} },
		},
	},
	{
		id = "eua_desregulamentar", mapa = "eua", era = "eletrico", emoji = "dinheiro", alvo = nil,
		titulo = { pt = "Liberdade para definir o frete", en = "Freedom to set freight rates" },
		texto = { pt = "Uma lei nova deixa as ferrovias cobrarem o que quiserem pelo frete. Os clientes reclamam, mas as contas melhoram.", en = "A new law lets railroads charge whatever they want for freight. Customers complain, but the books improve." },
		opcoes = {
			{ pt = "Subir o frete das linhas cheias", en = "Raise rates on the busy lines", ef = { M("geral", 1.2, 20) } },
			{ pt = "Manter os preços de antes", en = "Keep the old prices", ef = { XP(30) } },
		},
	},
	{
		id = "eua_conteineres", mapa = "eua", era = "eletrico", emoji = "cargas", alvo = { cidade = "los_angeles" },
		titulo = { pt = "Contêineres empilhados em %s", en = "Stacked containers in %s" },
		texto = { pt = "Os navios da Ásia trazem contêineres que podem ir em dois andares nos vagões. O porto quer trens para levá-los ao interior.", en = "Ships from Asia bring containers that can ride two high on railcars. The port wants trains to take them inland." },
		opcoes = {
			{ pt = "Investir em vagões de dois andares", en = "Invest in double-stack cars", ef = { D(-3), M("cidade", 1.3, 15) } },
			{ pt = "Deixar para os caminhões", en = "Leave it to the trucks", ef = {} },
		},
	},
	{
		id = "eua_eletrificar", mapa = "eua", era = "eletrico", emoji = "era_eletrico", alvo = { cidade = "washington" },
		titulo = { pt = "Trens elétricos até %s", en = "Electric trains to %s" },
		texto = { pt = "Com cabos aéreos, trens elétricos rápidos poderiam ligar as grandes cidades do litoral leste.", en = "With overhead wires, fast electric trains could link the big cities of the East Coast." },
		opcoes = {
			{ pt = "Eletrificar o corredor", en = "Electrify the corridor", ef = { D(-3), M("cidade", 1.25, 15), XP(40) } },
			{ pt = "Continuar no diesel", en = "Stay with diesel", ef = {} },
		},
	},
	{
		id = "eua_carvao_oeste", mapa = "eua", era = "eletrico", emoji = "carga_carvao", alvo = { carga = "carvao" },
		titulo = { pt = "Trens de carvão de um quilômetro", en = "Mile-long coal trains" },
		texto = { pt = "As usinas elétricas pedem carvão sem parar. Trens enormes, com mais de cem vagões, podem levar tudo de uma vez.", en = "Power plants want coal nonstop. Huge trains, over a hundred cars long, can haul it all at once." },
		opcoes = {
			{ pt = "Montar os trens gigantes", en = "Run the giant trains", ef = { D(-2), M("carga", 1.3, 15) } },
			{ pt = "Seguir com trens normais", en = "Stick with regular trains", ef = {} },
		},
	},
	{
		id = "eua_fusao", mapa = "eua", era = "eletrico", emoji = "companhia", alvo = nil,
		titulo = { pt = "Uma proposta de fusão", en = "A merger offer" },
		texto = { pt = "Uma ferrovia rival quer comprar uma parte da companhia. Dinheiro na mão, mas você teria de dividir as decisões.", en = "A rival railroad wants to buy a stake in the company. Cash in hand, but you would have to share the decisions." },
		opcoes = {
			{ pt = "Vender uma parte", en = "Sell a stake", ef = { D(5), M("geral", 0.9, 15) } },
			{ pt = "Continuar independente", en = "Stay independent", ef = { XP(40) } },
		},
	},
	{
		id = "eua_choque_petroleo", mapa = "eua", era = "eletrico", emoji = "carga_petroleo", alvo = nil,
		titulo = { pt = "Filas nos postos de gasolina", en = "Lines at the gas stations" },
		texto = { pt = "A gasolina sumiu dos postos e as pessoas deixam o carro em casa. É a hora de mostrar que o trem gasta menos.", en = "Gasoline has vanished from the pumps and people leave their cars at home. Time to show that trains use less fuel." },
		opcoes = {
			{ pt = "Fazer propaganda do trem", en = "Advertise the train", ef = { D(-1), M("geral", 1.2, 12) } },
			{ pt = "Aproveitar sem gastar", en = "Ride the wave for free", ef = { M("geral", 1.08, 12) } },
		},
	},
	-- ---------------------------------------------------------------- Alta Velocidade (2000–)
	{
		id = "eua_acela", mapa = "eua", era = "alta", emoji = "velocidade", alvo = "linha",
		titulo = { pt = "Trens inclináveis para a linha %s", en = "Tilting trains for the %s line" },
		texto = { pt = "Trens que se inclinam nas curvas podem correr mais na linha %s sem refazer os trilhos.", en = "Trains that lean into the curves can run faster on the %s line without rebuilding the track." },
		opcoes = {
			{ pt = "Comprar os trens inclináveis", en = "Buy the tilting trains", ef = { D(-3), TREM(1), M("linha", 1.25, 15) } },
			{ pt = "Esperar uma linha nova", en = "Wait for a new line", ef = {} },
		},
	},
	{
		id = "eua_ptc", mapa = "eua", era = "alta", emoji = "alerta", alvo = nil,
		titulo = { pt = "Controle automático dos trens", en = "Automatic train control" },
		texto = { pt = "Uma lei exige um sistema que freia o trem sozinho se o maquinista errar. É caro, mas evita acidentes.", en = "A law requires a system that brakes the train on its own if the engineer makes a mistake. It's expensive, but it prevents accidents." },
		opcoes = {
			{ pt = "Instalar já", en = "Install it now", ef = { D(-3), M("manutencao", 0.8, 20), XP(40) } },
			{ pt = "Pedir mais prazo", en = "Ask for more time", ef = { SORTE(0.5, {}, { M("geral", 0.8, 10) }) } },
		},
	},
	{
		id = "eua_verba_federal", mapa = "eua", era = "alta", emoji = "gabinete", alvo = nil,
		titulo = { pt = "Verba federal para ferrovias", en = "Federal rail funding" },
		texto = { pt = "Washington abriu um programa bilionário para trens. Dá para pedir dinheiro para os estudos ou para as obras.", en = "Washington has opened a multibillion-dollar rail program. You can apply for money for studies or for construction." },
		opcoes = {
			{ pt = "Pedir verba para os estudos", en = "Apply for study funding", ef = { ESTUDO(10), XP(40) } },
			{ pt = "Pedir verba para as obras", en = "Apply for construction funding", ef = { D(3) } },
		},
	},
	{
		id = "eua_baterias", mapa = "eua", era = "alta", emoji = "era_eletrico", alvo = nil,
		titulo = { pt = "Locomotivas a bateria", en = "Battery locomotives" },
		texto = { pt = "Uma fábrica testa locomotivas que andam com baterias nas linhas sem eletrificação. Menos combustível e menos fumaça.", en = "A builder is testing locomotives that run on batteries on non-electrified lines. Less fuel and less smoke." },
		opcoes = {
			{ pt = "Testar na frota", en = "Trial them in the fleet", ef = { D(-2), M("manutencao", 0.85, 20), XP(50) } },
			{ pt = "Esperar a tecnologia amadurecer", en = "Wait for the technology to mature", ef = {} },
		},
	},
	{
		id = "eua_parques", mapa = "eua", era = "alta", emoji = "passageiros", alvo = { regiao = "o" },
		titulo = { pt = "Trens para os parques do %s", en = "Trains to the parks of the %s" },
		texto = { pt = "Os parques nacionais estão lotados de carros. Os guardas-parque pedem trens panorâmicos até as entradas.", en = "The national parks are jammed with cars. The rangers ask for scenic trains to the park gates." },
		opcoes = {
			{ pt = "Criar os trens panorâmicos", en = "Run the scenic trains", ef = { D(-1), M("regiao", 1.25, 12) } },
			{ pt = "Não é com a companhia", en = "Not the company's business", ef = {} },
		},
	},
	{
		id = "eua_furacao", mapa = "eua", era = "alta", emoji = "alerta", alvo = { regiao = "s" },
		titulo = { pt = "Furacão se aproxima do %s", en = "Hurricane approaching the %s" },
		texto = { pt = "A tempestade vai chegar em dois dias. Dá para reforçar as pontes agora ou consertar o que quebrar depois.", en = "The storm will hit in two days. You can reinforce the bridges now or fix whatever breaks afterward." },
		opcoes = {
			{ pt = "Reforçar as pontes", en = "Reinforce the bridges", ef = { D(-2), XP(20) } },
			{ pt = "Consertar depois", en = "Repair afterward", ef = { SORTE(0.4, {}, { M("regiao", 0.6, 10) }) } },
		},
	},
	{
		id = "eua_tecnologia", mapa = "eua", era = "alta", emoji = "companhia", alvo = { cidade = "san_francisco" },
		titulo = { pt = "Empresas de tecnologia em %s", en = "Tech companies in %s" },
		texto = { pt = "As empresas de tecnologia querem trens para os funcionários e oferecem pagar uma parte, se tiverem o nome nos vagões.", en = "The tech companies want trains for their staff and offer to pay part of it, if their name goes on the cars." },
		opcoes = {
			{ pt = "Aceitar o patrocínio", en = "Accept the sponsorship", ef = { D(3), M("cidade", 1.1, 15) } },
			{ pt = "Manter a marca da companhia", en = "Keep the company's own brand", ef = { XP(30) } },
		},
	},
	{
		id = "eua_comercio_online", mapa = "eua", era = "alta", emoji = "cargas", alvo = nil,
		titulo = { pt = "As compras pela internet explodem", en = "Online shopping explodes" },
		texto = { pt = "Os centros de distribuição querem contêineres chegando todo dia, no horário certo.", en = "Distribution centers want containers arriving every day, right on time." },
		opcoes = {
			{ pt = "Criar trens expressos de carga", en = "Run express freight trains", ef = { D(-2), M("geral", 1.2, 15) } },
			{ pt = "Seguir os horários de sempre", en = "Keep the usual timetable", ef = {} },
		},
	},
	-- ================================================================ Europa (mapa = "europa")
	-- Vapor
	{
		id = "eur_bitola", mapa = "europa", era = "vapor", emoji = "construir", alvo = nil,
		titulo = { pt = "A guerra das bitolas", en = "The gauge war" },
		texto = { pt = "Brunel usa trilhos de 7 pés; Stephenson, de 4 pés e 8½ polegadas. O Parlamento quer saber qual deve valer para todos.", en = "Brunel uses 7-foot track; Stephenson, 4 feet 8½ inches. Parliament wants to know which should be the standard." },
		opcoes = {
			{ pt = "Defender a bitola padrão", en = "Back the standard gauge", ef = { D(-1), M("manutencao", 0.85, 20), XP(40) } },
			{ pt = "Defender a bitola larga", en = "Back the broad gauge", ef = { M("geral", 1.1, 10), M("manutencao", 1.1, 20) } },
		},
	},
	{
		id = "eur_febre_ferroviaria", mapa = "europa", era = "vapor", emoji = "dinheiro", alvo = nil,
		titulo = { pt = "Febre das ações ferroviárias", en = "Railway mania" },
		texto = { pt = "Todo mundo quer comprar ações de ferrovias, até de linhas que nunca serão construídas. Os bancos oferecem dinheiro fácil.", en = "Everyone wants railway shares, even in lines that will never be built. The banks are offering easy money." },
		opcoes = {
			{ pt = "Vender ações agora", en = "Sell shares now", ef = { D(6), SORTE(0.5, {}, { M("geral", 0.8, 15) }) } },
			{ pt = "Ficar longe da bolha", en = "Stay away from the bubble", ef = { XP(40) } },
		},
	},
	{
		id = "eur_terceira_classe", mapa = "europa", era = "vapor", emoji = "passageiros", alvo = nil,
		titulo = { pt = "Os vagões abertos da 3ª classe", en = "The open third-class wagons" },
		texto = { pt = "Uma lei obriga pelo menos um trem por dia com vagões cobertos e passagem barata para os trabalhadores.", en = "A law requires at least one train a day with covered carriages and a cheap fare for workers." },
		opcoes = {
			{ pt = "Cobrir todos os vagões", en = "Roof every carriage", ef = { D(-2), M("geral", 1.15, 15) } },
			{ pt = "Cumprir só o mínimo", en = "Do only the minimum", ef = { XP(10) } },
		},
	},
	{
		id = "eur_hora_ferroviaria", mapa = "europa", era = "vapor", emoji = "relogio", alvo = nil,
		titulo = { pt = "A hora de Greenwich", en = "Greenwich time" },
		texto = { pt = "Cada cidade acerta o relógio pelo sol e os horários viram uma confusão. As ferrovias propõem usar a hora de Greenwich em todas as estações.", en = "Every town sets its clock by the sun and timetables are a mess. The railways propose using Greenwich time at every station." },
		opcoes = {
			{ pt = "Adotar a hora padrão", en = "Adopt standard time", ef = { D(-1), M("manutencao", 0.8, 20), XP(40) } },
			{ pt = "Manter a hora de cada cidade", en = "Keep each town's own time", ef = { M("geral", 0.95, 10) } },
		},
	},
	{
		id = "eur_tunel_alpes", mapa = "europa", era = "vapor", emoji = "construir", alvo = "linha",
		titulo = { pt = "Perfuratrizes de ar comprimido na linha %s", en = "Compressed-air drills on the %s line" },
		texto = { pt = "Um engenheiro mostra máquinas que cavam a rocha três vezes mais rápido que a picareta. Custam caro e ainda quebram muito.", en = "An engineer shows machines that bore through rock three times faster than picks. They are expensive and still break down a lot." },
		opcoes = {
			{ pt = "Comprar as perfuratrizes", en = "Buy the drills", ef = { D(-2), ESTUDO(15), XP(30) } },
			{ pt = "Seguir na picareta", en = "Stick with picks", ef = {} },
		},
	},
	{
		id = "eur_wagons_lits", mapa = "europa", era = "vapor", emoji = "estacoes", alvo = nil,
		titulo = { pt = "Vagões-leito de luxo", en = "Luxury sleeping cars" },
		texto = { pt = "Um empresário belga propõe vagões-leito com restaurante para viagens longas entre as capitais.", en = "A Belgian businessman proposes sleeping cars with a restaurant for long journeys between capitals." },
		opcoes = {
			{ pt = "Fazer parceria", en = "Go into partnership", ef = { D(-2), M("geral", 1.2, 15), XP(30) } },
			{ pt = "Recusar", en = "Decline", ef = {} },
		},
	},
	-- Diesel
	{
		id = "eur_nacionalizar", mapa = "europa", era = "diesel", emoji = "companhia", alvo = nil,
		titulo = { pt = "O governo quer nacionalizar as ferrovias", en = "The government wants to nationalise the railways" },
		texto = { pt = "Depois da guerra, os governos estão juntando as companhias numa empresa estatal. Oferecem uma indenização.", en = "After the war, governments are merging the companies into a state railway. They are offering compensation." },
		opcoes = {
			{ pt = "Aceitar a indenização e cooperar", en = "Take the compensation and cooperate", ef = { D(5), M("geral", 0.9, 15) } },
			{ pt = "Brigar na Justiça", en = "Fight it in court", ef = { SORTE(0.5, { XP(60) }, { D(-3) }) } },
		},
	},
	{
		id = "eur_ponte_bombardeada", mapa = "europa", era = "diesel", emoji = "alerta", alvo = "linha",
		titulo = { pt = "Ponte destruída na linha %s", en = "Bridge destroyed on the %s line" },
		texto = { pt = "A guerra levou uma ponte da linha. Dá para fazer uma ponte provisória de madeira ou esperar o aço da reconstrução.", en = "The war took out a bridge on the line. You can build a temporary wooden bridge or wait for steel from the reconstruction." },
		opcoes = {
			{ pt = "Ponte provisória já", en = "Temporary bridge now", ef = { D(-1), M("linha", 0.9, 10) } },
			{ pt = "Esperar a ponte de aço", en = "Wait for the steel bridge", ef = { M("linha", 0.5, 10), XP(20) } },
		},
	},
	{
		id = "eur_refugiados", mapa = "europa", era = "diesel", emoji = "passageiros", alvo = nil,
		titulo = { pt = "Trens de refugiados", en = "Refugee trains" },
		texto = { pt = "Milhares de famílias precisam atravessar a Europa para recomeçar a vida. As organizações de ajuda pedem trens especiais.", en = "Thousands of families need to cross Europe to start their lives again. Aid organisations ask for special trains." },
		opcoes = {
			{ pt = "Ceder trens de graça", en = "Lend trains for free", ef = { D(-2), XP(80) } },
			{ pt = "Cobrar a passagem normal", en = "Charge the normal fare", ef = { D(1) } },
		},
	},
	{
		id = "eur_diesel_ou_eletrico", mapa = "europa", era = "diesel", emoji = "construir", alvo = nil,
		titulo = { pt = "Diesel ou eletrificação?", en = "Diesel or electrification?" },
		texto = { pt = "Os engenheiros discutem: locomotivas a diesel saem logo, mas eletrificar as linhas sai mais barato a longo prazo.", en = "The engineers argue: diesel locomotives are available now, but electrifying the lines is cheaper in the long run." },
		opcoes = {
			{ pt = "Diesel agora", en = "Diesel now", ef = { M("geral", 1.15, 15) } },
			{ pt = "Começar a eletrificar", en = "Start electrifying", ef = { D(-3), M("manutencao", 0.75, 25), XP(30) } },
		},
	},
	{
		id = "eur_carvao_ruhr", mapa = "europa", era = "diesel", emoji = "carga_carvao", alvo = { regiao = "c" },
		titulo = { pt = "Comunidade do Carvão e do Aço", en = "The Coal and Steel Community" },
		texto = { pt = "Seis países vão juntar o carvão e o aço para nunca mais fazerem guerra. As ferrovias da %s podem levar o carvão sem tarifas de fronteira.", en = "Six countries will pool coal and steel so they never go to war again. Railways in %s can carry coal without border tariffs." },
		opcoes = {
			{ pt = "Entrar no acordo", en = "Join the agreement", ef = { M("regiao", 1.3, 15), XP(40) } },
			{ pt = "Ficar com as tarifas", en = "Keep the tariffs", ef = { D(2) } },
		},
	},
	{
		id = "eur_ramais", mapa = "europa", era = "diesel", emoji = "linhas", alvo = nil,
		titulo = { pt = "Fechar os ramais que dão prejuízo?", en = "Close the loss-making branch lines?" },
		texto = { pt = "Um relatório do governo recomenda fechar milhares de quilômetros de ramais rurais e trocar por ônibus.", en = "A government report recommends closing thousands of kilometres of rural branch lines and replacing them with buses." },
		opcoes = {
			{ pt = "Fechar os ramais", en = "Close the branches", ef = { M("manutencao", 0.8, 20), M("geral", 0.95, 15) } },
			{ pt = "Manter os ramais", en = "Keep the branches", ef = { D(-1), XP(40) } },
		},
	},
	-- Elétrica
	{
		id = "eur_tgv", mapa = "europa", era = "eletrico", emoji = "trens", alvo = "linha",
		titulo = { pt = "Um trem de alta velocidade na linha %s?", en = "A high-speed train on the %s line?" },
		texto = { pt = "Os franceses mostram um trem que passa dos 260 km/h numa linha nova, sem curvas apertadas. Querem testar na sua linha.", en = "The French show a train that tops 260 km/h on a new line with no tight curves. They want to test it on your line." },
		opcoes = {
			{ pt = "Liberar o teste", en = "Allow the test", ef = { D(-2), M("linha", 1.4, 15), XP(40) } },
			{ pt = "Recusar", en = "Decline", ef = {} },
		},
	},
	{
		id = "eur_eurocity", mapa = "europa", era = "eletrico", emoji = "passageiros", alvo = nil,
		titulo = { pt = "Trens EuroCity entre as capitais", en = "EuroCity trains between capitals" },
		texto = { pt = "As ferrovias de vários países propõem trens rápidos com horário cadenciado e sem trocar de trem na fronteira.", en = "Railways from several countries propose fast trains on a regular timetable, with no change at the border." },
		opcoes = {
			{ pt = "Entrar na rede", en = "Join the network", ef = { D(-2), M("geral", 1.2, 20) } },
			{ pt = "Seguir sozinho", en = "Go it alone", ef = { XP(10) } },
		},
	},
	{
		id = "eur_greve_geral", mapa = "europa", era = "eletrico", emoji = "alerta", alvo = nil,
		titulo = { pt = "Os ferroviários ameaçam greve", en = "Railway workers threaten to strike" },
		texto = { pt = "O sindicato pede aumento e menos horas. Sem acordo, os trens param no fim de semana.", en = "The union wants a raise and shorter hours. Without a deal, the trains stop this weekend." },
		opcoes = {
			{ pt = "Dar o aumento", en = "Give the raise", ef = { D(-2), XP(30) } },
			{ pt = "Negociar devagar", en = "Negotiate slowly", ef = { SORTE(0.5, {}, { M("geral", 0.7, 10) }) } },
		},
	},
	{
		id = "eur_carga_conteineres", mapa = "europa", era = "eletrico", emoji = "cargas", alvo = nil,
		titulo = { pt = "Contêineres dos portos", en = "Containers from the ports" },
		texto = { pt = "Roterdã e Hamburgo recebem navios cheios de contêineres. Os caminhões não dão conta; as ferrovias podem levar a carga para o interior.", en = "Rotterdam and Hamburg receive ships full of containers. The trucks can't cope; the railways can carry the cargo inland." },
		opcoes = {
			{ pt = "Montar terminais de contêiner", en = "Build container terminals", ef = { D(-3), M("geral", 1.25, 20), XP(30) } },
			{ pt = "Deixar para os caminhões", en = "Leave it to the trucks", ef = {} },
		},
	},
	{
		id = "eur_queda_muro", mapa = "europa", era = "eletrico", emoji = "linhas", alvo = nil,
		titulo = { pt = "O Muro de Berlim caiu", en = "The Berlin Wall has fallen" },
		texto = { pt = "As fronteiras do Leste se abrem e milhões querem viajar. Os trilhos entre Leste e Oeste precisam ser religados.", en = "The borders to the East are opening and millions want to travel. The tracks between East and West need reconnecting." },
		opcoes = {
			{ pt = "Religar as linhas já", en = "Reconnect the lines now", ef = { D(-3), M("geral", 1.3, 20), XP(60) } },
			{ pt = "Esperar os governos", en = "Wait for the governments", ef = { M("geral", 1.1, 10) } },
		},
	},
	{
		id = "eur_tunel_canal", mapa = "europa", era = "eletrico", emoji = "construir", alvo = nil,
		titulo = { pt = "Um túnel sob o Canal da Mancha", en = "A tunnel under the English Channel" },
		texto = { pt = "Ingleses e franceses decidem, enfim, cavar o túnel. Procuram companhias para investir nos trens que vão passar por ele.", en = "The British and French finally decide to dig the tunnel. They are looking for companies to invest in the trains that will run through it." },
		opcoes = {
			{ pt = "Investir", en = "Invest", ef = { D(-4), SORTE(0.6, { M("geral", 1.3, 20) }, { M("geral", 0.95, 10) }) } },
			{ pt = "Ficar de fora", en = "Stay out", ef = {} },
		},
	},
	-- Alta velocidade
	{
		id = "eur_liberalizacao", mapa = "europa", era = "alta", emoji = "companhia", alvo = nil,
		titulo = { pt = "Os trilhos se abrem à concorrência", en = "The tracks open to competition" },
		texto = { pt = "Uma nova regra europeia deixa qualquer companhia rodar trens em qualquer país. Concorrentes chegam com passagens baratas.", en = "A new European rule lets any company run trains in any country. Rivals arrive with cheap fares." },
		opcoes = {
			{ pt = "Baixar as passagens também", en = "Cut fares too", ef = { M("geral", 1.15, 15), M("manutencao", 1.1, 15) } },
			{ pt = "Apostar no conforto", en = "Bet on comfort", ef = { D(-2), XP(40) } },
		},
	},
	{
		id = "eur_trens_noturnos", mapa = "europa", era = "alta", emoji = "relogio", alvo = nil,
		titulo = { pt = "A volta dos trens noturnos", en = "The return of night trains" },
		texto = { pt = "Viajantes querem fugir dos aviões. Um consórcio propõe trens-leito entre as capitais, como nos tempos do Expresso do Oriente.", en = "Travellers want to avoid planes. A consortium proposes sleeper trains between capitals, as in the days of the Orient Express." },
		opcoes = {
			{ pt = "Relançar os trens noturnos", en = "Relaunch night trains", ef = { D(-2), M("geral", 1.2, 20), XP(40) } },
			{ pt = "Só trens de dia", en = "Day trains only", ef = {} },
		},
	},
	{
		id = "eur_voo_curto", mapa = "europa", era = "alta", emoji = "linhas", alvo = nil,
		titulo = { pt = "Fim dos voos curtos", en = "An end to short flights" },
		texto = { pt = "O governo pensa em proibir voos onde o trem leva menos de duas horas e meia. As companhias aéreas protestam.", en = "The government is considering banning flights where the train takes under two and a half hours. The airlines protest." },
		opcoes = {
			{ pt = "Apoiar a proibição", en = "Support the ban", ef = { M("geral", 1.25, 15), XP(30) } },
			{ pt = "Ficar neutro", en = "Stay neutral", ef = { D(1) } },
		},
	},
	{
		id = "eur_onda_calor", mapa = "europa", era = "alta", emoji = "alerta", alvo = "linha",
		titulo = { pt = "Onda de calor na linha %s", en = "Heatwave on the %s line" },
		texto = { pt = "Os trilhos dilatam com o calor e os trens precisam andar devagar. Dá para pintar os trilhos de branco ou trocar o lastro.", en = "The rails expand in the heat and trains must slow down. You can paint the rails white or replace the ballast." },
		opcoes = {
			{ pt = "Pintar os trilhos de branco", en = "Paint the rails white", ef = { D(-1), M("linha", 1.05, 10) } },
			{ pt = "Trocar o lastro", en = "Replace the ballast", ef = { D(-3), XP(40) } },
			{ pt = "Andar devagar por enquanto", en = "Go slow for now", ef = { M("linha", 0.7, 10) } },
		},
	},
	{
		id = "eur_hidrogenio", mapa = "europa", era = "alta", emoji = "construir", alvo = nil,
		titulo = { pt = "Trens a hidrogênio", en = "Hydrogen trains" },
		texto = { pt = "Uma fábrica alemã oferece trens a hidrogênio para as linhas que nunca foram eletrificadas.", en = "A German factory offers hydrogen trains for lines that were never electrified." },
		opcoes = {
			{ pt = "Comprar uma frota", en = "Buy a fleet", ef = { D(-3), M("manutencao", 0.8, 25), XP(40) } },
			{ pt = "Esperar a tecnologia baratear", en = "Wait for it to get cheaper", ef = {} },
		},
	},
	{
		id = "eur_patrimonio", mapa = "europa", era = "alta", emoji = "medalha", alvo = "linha",
		titulo = { pt = "Patrimônio da Humanidade na linha %s", en = "World Heritage on the %s line" },
		texto = { pt = "A UNESCO quer declarar os viadutos e túneis antigos da linha Patrimônio da Humanidade. Turistas viriam, mas as reformas ficariam mais caras.", en = "UNESCO wants to declare the line's old viaducts and tunnels a World Heritage Site. Tourists would come, but repairs would cost more." },
		opcoes = {
			{ pt = "Aceitar o título", en = "Accept the title", ef = { M("linha", 1.3, 20), M("manutencao", 1.1, 20), XP(50) } },
			{ pt = "Recusar", en = "Decline", ef = {} },
		},
	},
}
Decisoes.CATALOGO = CATALOGO

function Decisoes.acharDecisao(id: string): Definicao?
	for _, d in CATALOGO do
		if d.id == id then
			return d
		end
	end
	return nil
end

-- ---------------------------------------------------------------- alvo

-- Resolve o alvo de uma decisão agora: devolve (tipo, id) ou nil se ela não faz sentido.
function Decisoes.resolverAlvo(def: Definicao, estado: EstadoMapa, dados: any, rng: Random): (string?, string?)
	local a = def.alvo
	if a == nil then
		return "", nil
	elseif a == "linha" then
		local opcoes = {}
		for _, linha in dados.linhas do
			if Economia.trechosConstruidos(estado, linha) > 0 then
				table.insert(opcoes, linha.id)
			end
		end
		if #opcoes == 0 then
			return nil, nil
		end
		return "linha", opcoes[rng:NextInteger(1, #opcoes)]
	elseif a == "cidade" then
		local opcoes = {}
		for id, e in dados.estacoes do
			if e.porte >= 3 and Economia.estacaoNaRede(estado, dados, id) then
				table.insert(opcoes, id)
			end
		end
		if #opcoes == 0 then
			return nil, nil
		end
		table.sort(opcoes)
		return "cidade", opcoes[rng:NextInteger(1, #opcoes)]
	elseif type(a) == "table" then
		if a.cidade then
			if dados.estacoes[a.cidade] and Economia.estacaoNaRede(estado, dados, a.cidade) then
				return "cidade", a.cidade
			end
		elseif a.carga then
			for _, lista in Economia.cargasPorLinha(estado, dados) do
				for _, info in lista do
					if info.carga == a.carga and info.conectada then
						return "carga", a.carga
					end
				end
			end
		elseif a.regiao then
			for id, e in dados.estacoes do
				if e.regiao == a.regiao and Economia.estacaoNaRede(estado, dados, id) then
					return "regiao", a.regiao
				end
			end
		end
	end
	return nil, nil
end

function Decisoes.nomeAlvo(tipo: string?, alvo: string?, dados: any, idioma: string?): string
	if not alvo then
		return ""
	end
	if tipo == "linha" then
		for _, l in dados.linhas do
			if l.id == alvo then
				return l.nome
			end
		end
	elseif tipo == "cidade" then
		return if dados.estacoes[alvo] then dados.estacoes[alvo].nome else alvo
	elseif tipo == "regiao" then
		local r = dados.regioes[alvo]
		return if r then (r :: any)[idioma or "pt"] or r.pt else alvo
	elseif tipo == "carga" then
		local c = (Economia.CARGAS :: any)[alvo]
		return if c then c.nome else alvo
	end
	return alvo
end

-- Título e texto já com o nome do alvo.
function Decisoes.textos(def: Definicao, tipo: string?, alvo: string?, dados: any, idioma: string?): (string, string)
	local lingua = idioma or "pt"
	local nome = Decisoes.nomeAlvo(tipo, alvo, dados, lingua)
	local function trocar(t: Texto): string
		return (((t :: any)[lingua] or t.pt):gsub("%%s", function()
			return nome
		end))
	end
	return trocar(def.titulo), trocar(def.texto)
end

-- ---------------------------------------------------------------- dinheiro

-- Quanto vale "1 minuto de lucro" agora (com um piso que cresce com a era).
function Decisoes.valorMinuto(estado: EstadoMapa, lucro: number): number
	return math.max(math.max(lucro, 0) * 60, Decisoes.PISO_MINUTO * Economia.multiplicadorEra(estado))
end

local function arredondar(v: number): number
	if v < 1000 then
		return math.floor(v / 10 + 0.5) * 10
	end
	local p = 10 ^ (math.floor(math.log10(v)) - 1)
	return math.floor(v / p + 0.5) * p
end

function Decisoes.valorDinheiro(estado: EstadoMapa, lucro: number, minutos: number): number
	local v = arredondar(Decisoes.valorMinuto(estado, lucro) * math.abs(minutos))
	return if minutos < 0 then -v else v
end

-- Custo à vista de uma opção (só os dinheiros diretos negativos; a sorte não é cobrada antes).
function Decisoes.custo(estado: EstadoMapa, lucro: number, opcao: Opcao): number
	local total = 0
	for _, ef in opcao.ef do
		if ef.dinheiro and ef.dinheiro < 0 then
			total += -Decisoes.valorDinheiro(estado, lucro, ef.dinheiro)
		end
	end
	return total
end

-- ---------------------------------------------------------------- descrição dos efeitos

local NOMES_MOD = {
	geral = { pt = "em toda a receita", en = "on all income" },
	linha = { pt = "na linha %s", en = "on the %s line" },
	cidade = { pt = "nas linhas de %s", en = "on lines serving %s" },
	regiao = { pt = "nas linhas do %s", en = "on lines in the %s" },
	carga = { pt = "nas linhas que levam %s", en = "on lines carrying %s" },
}

export type Contexto = { estado: EstadoMapa, lucro: number, simbolo: string, tipo: string?, alvo: string?, dados: any, idioma: string? }

local function descreverUm(ef: Efeito, ctx: Contexto): string
	local pt = (ctx.idioma or "pt") == "pt"
	if ef.dinheiro then
		local v = Decisoes.valorDinheiro(ctx.estado, ctx.lucro, ef.dinheiro)
		return if v >= 0 then `+{Economia.formatar(v, ctx.simbolo)}` else `−{Economia.formatar(-v, ctx.simbolo)}`
	elseif ef.mod then
		local m = ef.mod
		local pct = math.round((m.mult - 1) * 100)
		local sinal = if pct >= 0 then "+" else "−"
		local tempo = if pt then `por {m.min} min` else `for {m.min} min`
		if m.tipo == "manutencao" then
			return if pt then `manutenção {sinal}{math.abs(pct)}% {tempo}` else `upkeep {sinal}{math.abs(pct)}% {tempo}`
		end
		local onde = (NOMES_MOD :: any)[m.tipo]
		local nome = Decisoes.nomeAlvo(ctx.tipo, ctx.alvo, ctx.dados, ctx.idioma)
		if m.tipo == "carga" then
			nome = string.lower(nome) -- "nas linhas que levam café"
		end
		local txt = if onde then ((if pt then onde.pt else onde.en):gsub("%%s", function()
			return nome
		end)) else ""
		return `{sinal}{math.abs(pct)}% {txt} {tempo}`
	elseif ef.xp then
		return `+{ef.xp} XP`
	elseif ef.trem then
		local nome = Decisoes.nomeAlvo(ctx.tipo, ctx.alvo, ctx.dados, ctx.idioma)
		return if pt then `+{ef.trem} trem na linha {nome}` else `+{ef.trem} train on the {nome} line`
	elseif ef.pesquisa then
		return if pt then `estudo em andamento {ef.pesquisa} min mais curto` else `current study {ef.pesquisa} min shorter`
	elseif ef.sorte then
		local s = ef.sorte
		local function lista(efs: { Efeito }): string
			if #efs == 0 then
				return if pt then "nada acontece" else "nothing happens"
			end
			local partes = {}
			for _, e in efs do
				table.insert(partes, descreverUm(e, ctx))
			end
			return table.concat(partes, ", ")
		end
		local pct = math.round(s.chance * 100)
		return if pt then `{pct}% de chance: {lista(s.sucesso)}; senão: {lista(s.falha)}`
			else `{pct}% chance: {lista(s.sucesso)}; otherwise: {lista(s.falha)}`
	end
	return ""
end

-- Texto curto dos efeitos de uma opção, ex.: "−R$ 2.400 · +25% em toda a receita por 10 min · +50 XP".
function Decisoes.descrever(opcao: Opcao, ctx: Contexto): string
	if #opcao.ef == 0 then
		return if (ctx.idioma or "pt") == "pt" then "Nada muda." else "Nothing changes."
	end
	local partes = {}
	for _, ef in opcao.ef do
		table.insert(partes, descreverUm(ef, ctx))
	end
	return table.concat(partes, " · ")
end

-- ---------------------------------------------------------------- aplicar

-- Resultado de uma escolha para o servidor aplicar: dinheiro, modificadores, xp, trens e estudo.
export type Resultado = {
	dinheiro: number,
	mods: { { tipo: string, mult: number, min: number } },
	xp: number,
	trens: number,
	pesquisa: number,
	sorteOk: boolean?, -- nil = a opção não tinha sorte
}

function Decisoes.resolver(opcao: Opcao, estado: EstadoMapa, lucro: number, rng: Random): Resultado
	local r: Resultado = { dinheiro = 0, mods = {}, xp = 0, trens = 0, pesquisa = 0, sorteOk = nil }
	local function aplicar(efs: { Efeito })
		for _, ef in efs do
			if ef.dinheiro then
				r.dinheiro += Decisoes.valorDinheiro(estado, lucro, ef.dinheiro)
			elseif ef.mod then
				table.insert(r.mods, ef.mod)
			elseif ef.xp then
				r.xp += ef.xp
			elseif ef.trem then
				r.trens += ef.trem
			elseif ef.pesquisa then
				r.pesquisa += ef.pesquisa
			elseif ef.sorte then
				local ok = rng:NextNumber() < ef.sorte.chance
				r.sorteOk = ok
				aplicar(if ok then ef.sorte.sucesso else ef.sorte.falha)
			end
		end
	end
	aplicar(opcao.ef)
	return r
end

-- Sorteia a próxima decisão da era atual, sem repetir as já vistas na era (quando acabam, recomeça).
function Decisoes.sortear(estado: EstadoMapa, dados: any, vistas: { [string]: boolean }, rng: Random): (Definicao?, string?, string?)
	local function candidatas(ignorarVistas: boolean): { { def: Definicao, tipo: string, alvo: string? } }
		local lista = {}
		for _, def in CATALOGO do
			-- as decisões sem `mapa` são do Brasil (a história é a do país)
			if def.era == estado.era and (def.mapa or "brasil") == (dados.id or "brasil") and (ignorarVistas or not vistas[def.id]) then
				local tipo, alvo = Decisoes.resolverAlvo(def, estado, dados, rng)
				if tipo then
					table.insert(lista, { def = def, tipo = tipo, alvo = alvo })
				end
			end
		end
		return lista
	end
	local lista = candidatas(false)
	if #lista == 0 then
		lista = candidatas(true)
	end
	if #lista == 0 then
		return nil, nil, nil
	end
	local c = lista[rng:NextInteger(1, #lista)]
	return c.def, c.tipo, c.alvo
end

return Decisoes
