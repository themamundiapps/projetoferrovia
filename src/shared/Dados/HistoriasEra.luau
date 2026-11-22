--!strict
-- História das cidades importantes em cada era (aparece na ficha da cidade).
-- Brasil: Diesel = 1930–1965, Elétrica = 1965–2000, Alta Velocidade = 2000 em diante (EUA no fim do arquivo).
-- A ficha usa o texto da era atual; se a cidade não tiver, volta para a era anterior e, no fim,
-- para a `historia` dos dados do mapa (a da Era do Vapor). Escrito à mão (os dados são gerados).
-- Os ids das cidades não se repetem entre os mapas, então todas ficam na mesma tabela.

type Texto = { pt: string, en: string }

return {
	rio = {
		diesel = {
			pt = "Capital federal e maior vitrine do país. Os trens de subúrbio da Central viraram elétricos a partir de 1937, e a nova estação, com sua torre do relógio, abriu em 1943.",
			en = "Federal capital and the country's showcase. The Central's suburban trains went electric from 1937, and the new station, with its clock tower, opened in 1943.",
		},
		eletrico = {
			pt = "Deixou de ser capital em 1960, mas seguiu sendo o cartão-postal do Brasil. A ponte Rio–Niterói abriu em 1974, e o metrô começou a rodar em 1979.",
			en = "It stopped being the capital in 1960 but remained Brazil's postcard. The Rio–Niterói bridge opened in 1974, and the metro started running in 1979.",
		},
		alta = {
			pt = "Sede da Copa de 2014 e dos Jogos Olímpicos de 2016. O Centro ganhou o VLT, e o trem-bala até São Paulo ficou só no papel.",
			en = "Host of the 2014 World Cup and the 2016 Olympic Games. Downtown got a light rail, while the bullet train to São Paulo never left the drawing board.",
		},
	},
	sao_paulo = {
		diesel = {
			pt = "Virou a maior cidade industrial do país. Em 1946, a inglesa São Paulo Railway passou para o governo e virou Santos–Jundiaí, mas a Estação da Luz continuou sendo a porta de entrada da cidade.",
			en = "It became the country's biggest industrial city. In 1946 the British São Paulo Railway was taken over by the government and renamed Santos–Jundiaí, but Luz Station remained the city's front door.",
		},
		eletrico = {
			pt = "O metrô começou a rodar em 1974, entre Jabaquara e Vila Mariana. A Grande São Paulo passou dos 15 milhões de habitantes.",
			en = "The metro started running in 1974, between Jabaquara and Vila Mariana. Greater São Paulo passed 15 million people.",
		},
		alta = {
			pt = "A maior metrópole do hemisfério sul, com mais de 20 milhões de pessoas na região. A Linha 4-Amarela do metrô, aberta em 2010, roda sem condutor.",
			en = "The largest metropolis in the southern hemisphere, with over 20 million people in the region. Metro Line 4-Yellow, opened in 2010, runs without drivers.",
		},
	},
	bh = {
		diesel = {
			pt = "A capital mineira cresceu depressa. Nos anos 1940, o prefeito JK mandou erguer a Pampulha, com a igreja e o cassino desenhados por Niemeyer.",
			en = "Minas Gerais' capital grew fast. In the 1940s, mayor JK had Pampulha built, with the church and casino designed by Niemeyer.",
		},
		eletrico = {
			pt = "Virou polo industrial, com a Cidade Industrial de Contagem e a fábrica da Fiat em Betim, de 1976. O trem metropolitano começou a rodar em 1986.",
			en = "It became an industrial hub, with Contagem's industrial district and the Fiat plant in Betim, from 1976. The metro rail started running in 1986.",
		},
		alta = {
			pt = "Uma das maiores regiões metropolitanas do país, famosa pelos bares e pelo pão de queijo, e uma das sedes da Copa de 2014.",
			en = "One of the country's largest metropolitan areas, famous for its bars and cheese bread, and one of the 2014 World Cup host cities.",
		},
	},
	recife = {
		diesel = {
			pt = "Nos anos 1950 era a maior cidade do Nordeste. Os trens da Great Western ligavam o porto aos engenhos e ao interior até a ferrovia ser estatizada, em 1950.",
			en = "In the 1950s it was the largest city in the Northeast. Great Western trains linked the port to the sugar mills and the interior until the railway was nationalised in 1950.",
		},
		eletrico = {
			pt = "O metrô do Recife começou a rodar em 1985, aproveitando o traçado de antigas linhas de trem.",
			en = "Recife's metro started running in 1985, reusing the route of old railway lines.",
		},
		alta = {
			pt = "Os casarões restaurados do Bairro do Recife abrigam o Porto Digital, criado em 2000 e hoje um dos maiores polos de tecnologia do país.",
			en = "The restored mansions of the old Recife quarter house Porto Digital, founded in 2000 and now one of the country's largest tech hubs.",
		},
	},
	salvador = {
		diesel = {
			pt = "A Viação Férrea Leste Brasileiro reunia os trilhos da Bahia; da Calçada saíam os trens para Alagoinhas e o sertão.",
			en = "The Leste Brasileiro railway brought together the lines of Bahia; trains left Calçada for Alagoinhas and the backlands.",
		},
		eletrico = {
			pt = "O petróleo do Recôncavo e o Polo Petroquímico de Camaçari, de 1978, fizeram dela uma grande metrópole. O Pelourinho virou Patrimônio da Humanidade em 1985.",
			en = "Oil from the Recôncavo and the Camaçari petrochemical complex, from 1978, made it a major metropolis. The Pelourinho became a World Heritage Site in 1985.",
		},
		alta = {
			pt = "Depois de mais de uma década de obras, o metrô abriu em 2014. A cidade do axé recebe milhões de turistas no Carnaval.",
			en = "After more than a decade of works, the metro opened in 2014. The home of axé music draws millions of visitors at Carnival.",
		},
	},
	curitiba = {
		diesel = {
			pt = "Capital do mate e da madeira. Daqui a Rede de Viação Paraná–Santa Catarina, criada em 1942, comandava os trilhos do sul.",
			en = "Capital of yerba mate and timber. From here the Paraná–Santa Catarina railway network, created in 1942, ran the southern lines.",
		},
		eletrico = {
			pt = "Em 1974 inventou o ônibus expresso em canaleta exclusiva, copiado no mundo todo, e virou exemplo de planejamento urbano.",
			en = "In 1974 it invented the express bus on dedicated lanes, copied all over the world, and became a model of urban planning.",
		},
		alta = {
			pt = "A cidade dos parques e das estações-tubo. O velho trem de Paranaguá virou passeio turístico pela Serra do Mar até Morretes.",
			en = "The city of parks and tube stations. The old Paranaguá train became a scenic ride through the Serra do Mar to Morretes.",
		},
	},
	porto_alegre = {
		diesel = {
			pt = "Sede da Viação Férrea do Rio Grande do Sul, de onde partiam os trens para a fronteira. A cidade se modernizou com avenidas largas.",
			en = "Headquarters of the Rio Grande do Sul state railway, from where trains left for the border. The city modernised with broad avenues.",
		},
		eletrico = {
			pt = "O Trensurb, trem metropolitano, abriu em 1985 ligando o centro a Sapucaia do Sul.",
			en = "Trensurb, the metro rail, opened in 1985 linking downtown to Sapucaia do Sul.",
		},
		alta = {
			pt = "Sediou o primeiro Fórum Social Mundial, em 2001. Em 2013 ganhou o Aeromóvel, um trem movido a ar, até o aeroporto.",
			en = "It hosted the first World Social Forum in 2001. In 2013 it got the Aeromóvel, an air-propelled train, to the airport.",
		},
	},
	belem = {
		diesel = {
			pt = "Depois da borracha, viveu da castanha e do porto. A Estrada de Ferro de Bragança ainda levava passageiros pelo nordeste do Pará.",
			en = "After the rubber boom it lived off Brazil nuts and the port. The Bragança railway still carried passengers through northeastern Pará.",
		},
		eletrico = {
			pt = "A rodovia Belém–Brasília mudou tudo: a ferrovia de Bragança fechou em meados dos anos 1960, e a cidade passou a crescer pela estrada.",
			en = "The Belém–Brasília highway changed everything: the Bragança railway closed in the mid-1960s, and the city began to grow along the road.",
		},
		alta = {
			pt = "O Ver-o-Peso e a Estação das Docas, antigos armazéns do porto reabertos em 2000, atraem turistas do mundo todo.",
			en = "Ver-o-Peso market and Estação das Docas, old port warehouses reopened in 2000, attract visitors from all over the world.",
		},
	},
	manaus = {
		diesel = {
			pt = "Com o fim do ciclo da borracha, a cidade encolheu e viveu anos de silêncio à beira do rio Negro.",
			en = "With the end of the rubber boom, the city shrank and lived quiet years on the banks of the Rio Negro.",
		},
		eletrico = {
			pt = "A Zona Franca, criada em 1967, trouxe fábricas de eletrônicos e de motos, e a cidade voltou a crescer.",
			en = "The Free Trade Zone, created in 1967, brought electronics and motorcycle factories, and the city grew again.",
		},
		alta = {
			pt = "Em 2011 ganhou a ponte sobre o rio Negro e, em 2014, foi sede da Copa com a Arena da Amazônia.",
			en = "In 2011 it got the bridge over the Rio Negro and, in 2014, hosted World Cup games at the Arena da Amazônia.",
		},
	},
	brasilia = {
		diesel = {
			pt = "Em 1956 começou a obra no meio do cerrado. Candangos de todo o país ergueram a nova capital em menos de quatro anos.",
			en = "In 1956 work began in the middle of the cerrado. Workers from all over the country built the new capital in less than four years.",
		},
		eletrico = {
			pt = "Os ministérios se mudaram do Rio, e a capital cresceu nas cidades-satélites em volta do Plano Piloto, tombado pela UNESCO em 1987.",
			en = "The ministries moved from Rio, and the capital grew in the satellite towns around the Pilot Plan, listed by UNESCO in 1987.",
		},
		alta = {
			pt = "O metrô, em operação desde 2001, liga o Plano Piloto às cidades-satélites de um Distrito Federal que já passa de 3 milhões de pessoas.",
			en = "The metro, running since 2001, links the Pilot Plan to the satellite towns of a Federal District that now has over 3 million people.",
		},
	},
	fortaleza = {
		diesel = {
			pt = "A Rede de Viação Cearense levava os trens até o sertão. Nas grandes secas, os retirantes chegavam à capital pelos trilhos.",
			en = "The Ceará railway network took trains into the backlands. In the great droughts, refugees reached the capital by rail.",
		},
		eletrico = {
			pt = "Cresceu com a chegada de gente do interior e com o turismo de praia. A avenida Beira-Mar virou cartão-postal.",
			en = "It grew with people arriving from the interior and with beach tourism. Beira-Mar avenue became its postcard.",
		},
		alta = {
			pt = "Uma das cinco maiores cidades do país e sede da Copa de 2014. O metrô começou a rodar em 2012.",
			en = "One of the five largest cities in the country and a 2014 World Cup host. The metro started running in 2012.",
		},
	},
	juiz_de_fora = {
		diesel = {
			pt = "A 'Manchester Mineira' vivia das tecelagens, e os trens da Central do Brasil a ligavam ao Rio e a Belo Horizonte.",
			en = "The 'Manchester of Minas' lived off its textile mills, and Central do Brasil trains linked it to Rio and Belo Horizonte.",
		},
		eletrico = {
			pt = "Com as tecelagens em declínio, passou a viver da universidade federal, criada em 1960, e do comércio da Zona da Mata.",
			en = "As the mills declined, it came to live off the federal university, founded in 1960, and trade across the Zona da Mata.",
		},
		alta = {
			pt = "Cidade universitária e centro de serviços da Zona da Mata, com fábrica de automóveis aberta em 1999.",
			en = "A university town and service centre of the Zona da Mata, with a car factory opened in 1999.",
		},
	},
	santos = {
		diesel = {
			pt = "O porto continuava embarcando café, e os jardins da orla viraram o passeio de domingo dos paulistas.",
			en = "The port kept shipping coffee, and the seafront gardens became the Sunday stroll for people from São Paulo.",
		},
		eletrico = {
			pt = "Virou o maior porto da América Latina, cheio de contêineres. Em 1974 uma nova cremalheira passou a subir a serra com os trens de carga.",
			en = "It became Latin America's largest port, full of containers. In 1974 a new rack railway began hauling freight trains up the mountains.",
		},
		alta = {
			pt = "O porto bate recordes de contêineres, os trens de carga sobem a serra, e o bonde histórico passeia pelo centro restaurado.",
			en = "The port breaks container records, freight trains climb the mountains, and the heritage tram runs through the restored old town.",
		},
	},
	campinas = {
		diesel = {
			pt = "Aqui se encontravam a Companhia Paulista e a Mogiana, e a cidade trocava o café pela indústria.",
			en = "The Paulista and Mogiana railways met here, and the city was swapping coffee for industry.",
		},
		eletrico = {
			pt = "Ganhou a Unicamp em 1966, e o aeroporto de Viracopos cresceu. Em 1971 as ferrovias paulistas viraram a Fepasa.",
			en = "It got Unicamp university in 1966, and Viracopos airport grew. In 1971 São Paulo's railways were merged into Fepasa.",
		},
		alta = {
			pt = "Polo de tecnologia e pesquisa, com Viracopos entre os maiores aeroportos de carga do país. A maria-fumaça ainda leva turistas até Jaguariúna.",
			en = "A technology and research hub, with Viracopos among the country's largest cargo airports. A steam train still takes visitors to Jaguariúna.",
		},
	},
	vitoria = {
		diesel = {
			pt = "A Estrada de Ferro Vitória a Minas passou a trazer o minério de Itabira, e em 1942 nasceu a Companhia Vale do Rio Doce.",
			en = "The Vitória–Minas railway began bringing iron ore from Itabira, and in 1942 the Vale do Rio Doce company was founded.",
		},
		eletrico = {
			pt = "O porto de Tubarão, de 1966, virou um dos maiores exportadores de minério do mundo. A Terceira Ponte, de 1989, ligou a ilha a Vila Velha.",
			en = "Tubarão port, from 1966, became one of the world's largest iron ore exporters. The Third Bridge, from 1989, linked the island to Vila Velha.",
		},
		alta = {
			pt = "A Vitória a Minas é uma das poucas ferrovias do país com trem de passageiros todos os dias, ligando a capital a Belo Horizonte.",
			en = "The Vitória–Minas is one of the few railways in the country with a daily passenger train, linking the capital to Belo Horizonte.",
		},
	},
	sao_jose_campos = {
		diesel = {
			pt = "Era a cidade dos sanatórios: doentes de tuberculose chegavam pelo trem da Central em busca do clima de montanha.",
			en = "It was the city of sanatoriums: tuberculosis patients arrived on the Central's trains in search of the mountain air.",
		},
		eletrico = {
			pt = "Com o ITA e o centro técnico da Aeronáutica, nasceu ali a Embraer, em 1969, e a cidade virou a capital da aviação brasileira.",
			en = "Thanks to the ITA institute and the Air Force technical centre, Embraer was born here in 1969, and the city became Brazil's aviation capital.",
		},
		alta = {
			pt = "Polo aeroespacial à beira da Via Dutra. Por aqui passaria o trem-bala Rio–São Paulo, planejado e nunca construído.",
			en = "An aerospace hub along the Dutra highway. The Rio–São Paulo bullet train, planned but never built, would have passed through here.",
		},
	},
	sorocaba = {
		diesel = {
			pt = "Sede das oficinas da Estrada de Ferro Sorocabana e das tecelagens que lhe deram o apelido de 'Manchester Paulista'.",
			en = "Home of the Sorocabana railway workshops and of the textile mills that earned it the nickname 'Manchester of São Paulo'.",
		},
		eletrico = {
			pt = "Em 1971 a Sorocabana virou parte da Fepasa, e a cidade trocou os teares pelas metalúrgicas.",
			en = "In 1971 the Sorocabana became part of Fepasa, and the city swapped its looms for metalworks.",
		},
		alta = {
			pt = "Uma das cidades que mais crescem no interior paulista, com parque tecnológico e fábricas de autopeças.",
			en = "One of the fastest-growing cities in inland São Paulo, with a technology park and car-parts factories.",
		},
	},
	ponta_grossa = {
		diesel = {
			pt = "O maior entroncamento ferroviário do Paraná: as estações e as oficinas da Rede empregavam milhares de ferroviários.",
			en = "Paraná's largest railway junction: the stations and workshops of the state network employed thousands of railwaymen.",
		},
		eletrico = {
			pt = "Virou capital da soja e da agroindústria dos Campos Gerais, e os trens de carga levavam os grãos até o porto de Paranaguá.",
			en = "It became the capital of soy and agribusiness in the Campos Gerais, and freight trains carried the grain to the port of Paranaguá.",
		},
		alta = {
			pt = "Polo industrial e universitário. As antigas estações ferroviárias do centro viraram espaços culturais.",
			en = "An industrial and university hub. The old railway stations downtown became cultural venues.",
		},
	},
	santa_maria = {
		diesel = {
			pt = "A cidade ferroviária do Sul: a Viação Férrea tinha aqui oficinas, escolas e a cooperativa dos ferroviários.",
			en = "The railway city of the South: the state railway had workshops, schools and the railwaymen's cooperative here.",
		},
		eletrico = {
			pt = "Em 1960 ganhou a primeira universidade federal do interior do país, enquanto os trens de passageiros iam rareando.",
			en = "In 1960 it got the first federal university in the Brazilian interior, while passenger trains grew scarce.",
		},
		alta = {
			pt = "Cidade universitária e militar, com uma das maiores guarnições do Exército. A velha gare da estação virou espaço cultural.",
			en = "A university and military town, with one of the Army's largest garrisons. The old station hall became a cultural venue.",
		},
	},
	campo_grande = {
		diesel = {
			pt = "A Noroeste do Brasil trazia gado e gente, e a cidade virou a maior do sul de Mato Grosso.",
			en = "The Noroeste do Brasil railway brought cattle and people, and the city became the largest in southern Mato Grosso.",
		},
		eletrico = {
			pt = "Virou capital do novo estado de Mato Grosso do Sul, criado em 1977 e instalado em 1979.",
			en = "It became the capital of the new state of Mato Grosso do Sul, created in 1977 and set up in 1979.",
		},
		alta = {
			pt = "Capital do agronegócio e porta de entrada do Pantanal. O velho trem do Pantanal chegou a voltar como passeio turístico.",
			en = "Capital of agribusiness and gateway to the Pantanal. The old Pantanal train even came back as a tourist ride.",
		},
	},
	florianopolis = {
		diesel = {
			pt = "Uma capital pequena, de pescadores e funcionários públicos. A ponte Hercílio Luz era a única ligação com o continente.",
			en = "A small capital of fishermen and civil servants. The Hercílio Luz bridge was its only link to the mainland.",
		},
		eletrico = {
			pt = "A ponte Colombo Salles, de 1975, aliviou a velha Hercílio Luz, interditada em 1982. A ilha descobriu o turismo de praia.",
			en = "The Colombo Salles bridge, from 1975, relieved the old Hercílio Luz, closed in 1982. The island discovered beach tourism.",
		},
		alta = {
			pt = "Polo de tecnologia e turismo. Restaurada, a ponte Hercílio Luz voltou a abrir no fim de 2019.",
			en = "A technology and tourism hub. Restored, the Hercílio Luz bridge reopened at the end of 2019.",
		},
	},
	maceio = {
		diesel = {
			pt = "Porto do açúcar das usinas alagoanas; os trilhos da Great Western a ligavam ao Recife.",
			en = "The sugar port for Alagoas' mills; Great Western tracks linked it to Recife.",
		},
		eletrico = {
			pt = "A indústria química do sal-gema chegou nos anos 1970, e as praias de águas verdes atraíram os primeiros turistas.",
			en = "The rock-salt chemical industry arrived in the 1970s, and the green-water beaches drew the first tourists.",
		},
		alta = {
			pt = "Destino de praias e piscinas naturais. O VLT ainda corre pelos trilhos centenários até Rio Largo.",
			en = "A destination of beaches and natural pools. The light rail still runs on century-old tracks to Rio Largo.",
		},
	},
	natal = {
		diesel = {
			pt = "Na Segunda Guerra, a base de Parnamirim recebeu aviões dos Estados Unidos rumo à África: era o 'Trampolim da Vitória'.",
			en = "In World War II, the Parnamirim base hosted American planes heading to Africa: it was the 'Springboard to Victory'.",
		},
		eletrico = {
			pt = "Em 1965 a Barreira do Inferno lançou os primeiros foguetes do país, e as dunas começaram a atrair turistas.",
			en = "In 1965 the Barreira do Inferno range launched the country's first rockets, and the dunes began to attract tourists.",
		},
		alta = {
			pt = "A capital do sol e das dunas de Genipabu, com trens urbanos ligando a cidade à região metropolitana.",
			en = "The capital of sunshine and the Genipabu dunes, with commuter trains linking the city to its metropolitan area.",
		},
	},
	-- ================================================================ EUA
	-- Diesel = 1935–1970, Elétrica = 1970–2000, Alta Velocidade = 2000 em diante (anos do mapa dos EUA).
	boston = {
		diesel = {
			pt = "A South Station chegou a ser a estação mais movimentada do mundo. Os trens de subúrbio levavam os trabalhadores das cidades em volta até o porto e as fábricas.",
			en = "South Station was once the busiest railway station in the world. Commuter trains carried workers from the surrounding towns to the port and the factories.",
		},
		eletrico = {
			pt = "Universidades e hospitais tomaram o lugar das fábricas. O governo estadual assumiu os trens de subúrbio para salvá-los da falência.",
			en = "Universities and hospitals took the place of the factories. The state took over the commuter trains to save them from bankruptcy.",
		},
		alta = {
			pt = "Ponta norte do corredor do Acela, o trem mais rápido do país, que liga Boston a Nova York e Washington.",
			en = "Northern end of the Acela corridor, the country's fastest train, linking Boston to New York and Washington.",
		},
	},
	new_york = {
		diesel = {
			pt = "A Grand Central e a Penn Station recebiam trens de luxo como o 20th Century Limited, que embarcava os passageiros num tapete vermelho rumo a Chicago.",
			en = "Grand Central and Penn Station received luxury trains like the 20th Century Limited, which boarded passengers on a red carpet bound for Chicago.",
		},
		eletrico = {
			pt = "A velha Penn Station foi demolida em 1963, e o protesto que veio depois salvou a Grand Central. O metrô e os trens de subúrbio carregavam milhões por dia.",
			en = "The old Penn Station was torn down in 1963, and the outcry that followed saved Grand Central. The subway and commuter trains carried millions a day.",
		},
		alta = {
			pt = "A estação Moynihan abriu em 2021 no antigo correio, em frente à Penn Station. Os túneis sob o rio Hudson são o grande gargalo do corredor do Nordeste.",
			en = "Moynihan Train Hall opened in 2021 in the old post office, across from Penn Station. The tunnels under the Hudson River are the Northeast Corridor's great bottleneck.",
		},
	},
	philadelphia = {
		diesel = {
			pt = "A Pennsylvania Railroad eletrificou a linha até Nova York e Washington, e a 30th Street Station, de 1933, virou o coração da maior ferrovia do país.",
			en = "The Pennsylvania Railroad electrified its line to New York and Washington, and 30th Street Station, opened in 1933, became the heart of the country's largest railroad.",
		},
		eletrico = {
			pt = "Em 1970 a Penn Central, criada pela fusão da Pennsylvania com a New York Central, faliu: a maior falência da história do país até então.",
			en = "In 1970 Penn Central, born of the merger of the Pennsylvania and the New York Central, went bankrupt: the largest bankruptcy in the country's history up to then.",
		},
		alta = {
			pt = "A 30th Street Station é uma das estações mais movimentadas da Amtrak, no meio do caminho entre Nova York e Washington.",
			en = "30th Street Station is one of Amtrak's busiest, halfway between New York and Washington.",
		},
	},
	pittsburgh = {
		diesel = {
			pt = "As usinas de aço trabalhavam dia e noite durante a guerra. O céu ficava tão escuro de fumaça que os postes acendiam ao meio-dia.",
			en = "The steel mills ran day and night during the war. The sky grew so dark with smoke that streetlights came on at noon.",
		},
		eletrico = {
			pt = "As usinas fecharam nos anos 1980 e a cidade perdeu metade dos empregos. Os trilhos que levavam aço passaram a levar outras cargas.",
			en = "The mills closed in the 1980s and the city lost half its jobs. The tracks that carried steel began carrying other freight.",
		},
		alta = {
			pt = "Reinventada com universidades, hospitais e robótica, mas ainda cortada por trens de carga ao longo dos rios.",
			en = "Reinvented with universities, hospitals and robotics, but still crossed by freight trains along its rivers.",
		},
	},
	baltimore = {
		diesel = {
			pt = "A B&O, a ferrovia mais antiga do país, ainda tinha sede aqui. Seu trem Capitol Limited ia até Chicago.",
			en = "The B&O, the country's oldest railroad, was still headquartered here. Its Capitol Limited train ran to Chicago.",
		},
		eletrico = {
			pt = "A B&O sumiu nas fusões e virou parte da Chessie System. A velha oficina de Mount Clare virou o Museu Ferroviário da B&O.",
			en = "The B&O disappeared into mergers and became part of the Chessie System. The old Mount Clare shops became the B&O Railroad Museum.",
		},
		alta = {
			pt = "O porto recebe navios de contêineres e de carros, e há um projeto de trem de levitação magnética até Washington.",
			en = "The port handles container and car ships, and there is a plan for a magnetic levitation train to Washington.",
		},
	},
	washington = {
		diesel = {
			pt = "A Union Station recebia trens cheios de soldados e funcionários do governo durante a guerra.",
			en = "Union Station received trains full of soldiers and government workers during the war.",
		},
		eletrico = {
			pt = "Em 1971 a Amtrak nasceu aqui para cuidar dos trens de passageiros do país inteiro. O metrô abriu em 1976.",
			en = "In 1971 Amtrak was born here to run passenger trains for the whole country. The Metro opened in 1976.",
		},
		alta = {
			pt = "Ponta sul do corredor do Acela. A Union Station, restaurada, é ao mesmo tempo estação e shopping.",
			en = "Southern end of the Acela corridor. The restored Union Station is both a station and a shopping mall.",
		},
	},
	atlanta = {
		diesel = {
			pt = "Seguia sendo o grande entroncamento ferroviário do Sul, com trens como o Crescent ligando Nova York a Nova Orleans.",
			en = "It remained the great rail junction of the South, with trains like the Crescent linking New York to New Orleans.",
		},
		eletrico = {
			pt = "Cidade-sede do movimento pelos direitos civis. O metrô MARTA abriu em 1979 e o aeroporto virou o mais movimentado do mundo.",
			en = "Home city of the civil rights movement. The MARTA subway opened in 1979 and the airport became the busiest in the world.",
		},
		alta = {
			pt = "Os pátios de carga da Norfolk Southern e da CSX fazem dela um dos maiores centros logísticos do país.",
			en = "Norfolk Southern and CSX freight yards make it one of the country's biggest logistics hubs.",
		},
	},
	miami = {
		diesel = {
			pt = "Os trens de luxo do norte traziam turistas fugindo do inverno. O furacão de 1935 destruiu a ferrovia até Key West, que virou estrada.",
			en = "Luxury trains from the North brought tourists escaping the winter. The 1935 hurricane destroyed the railroad to Key West, which became a highway.",
		},
		eletrico = {
			pt = "A chegada de refugiados cubanos transformou a cidade. O metrô elevado, o Metrorail, abriu em 1984.",
			en = "The arrival of Cuban refugees transformed the city. The elevated Metrorail opened in 1984.",
		},
		alta = {
			pt = "Em 2018 a Brightline voltou a ligar Miami ao norte da Flórida com trens rápidos e privados, e em 2023 chegou a Orlando.",
			en = "In 2018 Brightline again linked Miami to northern Florida with fast private trains, reaching Orlando in 2023.",
		},
	},
	new_orleans = {
		diesel = {
			pt = "Trens como o City of New Orleans e o Panama Limited ligavam a cidade do jazz a Chicago pelo vale do Mississippi.",
			en = "Trains like the City of New Orleans and the Panama Limited linked the jazz city to Chicago through the Mississippi valley.",
		},
		eletrico = {
			pt = "O porto ficou entre os maiores do mundo em grãos e petróleo, que chegavam de trem e de barcaça.",
			en = "The port became one of the world's largest for grain and oil, which arrived by train and by barge.",
		},
		alta = {
			pt = "Reconstruída depois do furacão Katrina, em 2005. Seis grandes ferrovias de carga ainda se encontram aqui.",
			en = "Rebuilt after Hurricane Katrina in 2005. Six major freight railroads still meet here.",
		},
	},
	cincinnati = {
		diesel = {
			pt = "A Union Terminal, de 1933, em estilo art déco, recebia mais de cem trens por dia durante a guerra.",
			en = "The 1933 Art Deco Union Terminal handled more than a hundred trains a day during the war.",
		},
		eletrico = {
			pt = "Os trens de passageiros minguaram e a Union Terminal quase foi demolida; virou um centro de museus em 1990.",
			en = "Passenger trains dwindled and Union Terminal was nearly demolished; it became a museum center in 1990.",
		},
		alta = {
			pt = "A Union Terminal restaurada voltou a receber o trem Cardinal, entre Chicago e Nova York.",
			en = "The restored Union Terminal again welcomes the Cardinal train, between Chicago and New York.",
		},
	},
	detroit = {
		diesel = {
			pt = "A capital do automóvel virou o \"arsenal da democracia\": as fábricas de carro fizeram tanques e aviões na guerra.",
			en = "The Motor City became the \"arsenal of democracy\": car plants built tanks and planes during the war.",
		},
		eletrico = {
			pt = "A Michigan Central Station, gigante, perdeu os trens e fechou em 1988. A cidade encolheu com a crise da indústria.",
			en = "The giant Michigan Central Station lost its trains and closed in 1988. The city shrank with the industrial crisis.",
		},
		alta = {
			pt = "A Ford comprou e restaurou a Michigan Central Station, reaberta em 2024 como centro de tecnologia.",
			en = "Ford bought and restored Michigan Central Station, reopened in 2024 as a technology hub.",
		},
	},
	chicago = {
		diesel = {
			pt = "A capital ferroviária do país: os passageiros que cruzavam o continente trocavam de trem e de estação aqui.",
			en = "The nation's railroad capital: passengers crossing the continent changed trains, and stations, here.",
		},
		eletrico = {
			pt = "Os currais da Union Stock Yards fecharam em 1971. A Union Station virou a base da Amtrak no Meio-Oeste.",
			en = "The Union Stock Yards closed in 1971. Union Station became Amtrak's Midwest base.",
		},
		alta = {
			pt = "Um quarto dos trens de carga do país ainda passa por Chicago, e a Amtrak sai daqui para todas as direções.",
			en = "A quarter of the country's freight trains still pass through Chicago, and Amtrak heads out from here in every direction.",
		},
	},
	minneapolis = {
		diesel = {
			pt = "Os moinhos de farinha e os trens Empire Builder e North Coast Limited, rumo ao Pacífico, partiam daqui.",
			en = "The flour mills, and the Empire Builder and North Coast Limited trains bound for the Pacific, set out from here.",
		},
		eletrico = {
			pt = "Em 1970 a Great Northern e a Northern Pacific se uniram na Burlington Northern, com sede em St. Paul.",
			en = "In 1970 the Great Northern and the Northern Pacific merged into the Burlington Northern, headquartered in St. Paul.",
		},
		alta = {
			pt = "Os bondes modernos voltaram em 2004, e os trens de grãos ainda saem das planícies rumo aos portos.",
			en = "Modern light rail returned in 2004, and grain trains still leave the plains for the ports.",
		},
	},
	st_louis = {
		diesel = {
			pt = "A Union Station chegou a ser a maior estação do mundo em número de trilhos, com trens para o Oeste e o Sul.",
			en = "Union Station was once the world's largest station by number of tracks, with trains to the West and the South.",
		},
		eletrico = {
			pt = "O Gateway Arch, de 1965, virou o símbolo da \"porta do Oeste\". A Union Station perdeu os trens em 1978 e virou hotel.",
			en = "The 1965 Gateway Arch became the symbol of the \"Gateway to the West\". Union Station lost its trains in 1978 and became a hotel.",
		},
		alta = {
			pt = "Trens mais rápidos ligam St. Louis a Chicago a até 180 km/h, e os pátios de carga seguem cheios.",
			en = "Faster trains link St. Louis to Chicago at up to 110 mph, and the freight yards are still busy.",
		},
	},
	kansas_city = {
		diesel = {
			pt = "A Union Station, uma das maiores do país, recebia trens das ferrovias que cruzavam as planícies.",
			en = "Union Station, one of the country's largest, received trains from the railroads crossing the plains.",
		},
		eletrico = {
			pt = "Os currais fecharam e a Union Station quase virou ruína, até a cidade decidir salvá-la.",
			en = "The stockyards closed and Union Station nearly fell into ruin, until the city decided to save it.",
		},
		alta = {
			pt = "Segundo maior centro ferroviário de carga do país, com uma Union Station restaurada e um bonde novo.",
			en = "The country's second-largest freight rail hub, with a restored Union Station and a new streetcar.",
		},
	},
	houston = {
		diesel = {
			pt = "O petróleo transformou a cidade. O canal de navios fez do porto um dos mais movimentados do país.",
			en = "Oil transformed the city. The ship channel made the port one of the busiest in the country.",
		},
		eletrico = {
			pt = "Centro da indústria petroquímica e da NASA. A cidade cresceu com o carro e quase sem trens de passageiros.",
			en = "Center of the petrochemical industry and of NASA. The city grew around the car, with almost no passenger trains.",
		},
		alta = {
			pt = "O trem-bala Texas Central, até Dallas, foi planejado com tecnologia japonesa, mas parou na Justiça e na falta de verba.",
			en = "The Texas Central bullet train to Dallas was planned with Japanese technology, but stalled in the courts and for lack of funds.",
		},
	},
	dallas = {
		diesel = {
			pt = "Cresceu com o algodão, o petróleo e o cruzamento de ferrovias que a criou.",
			en = "It grew with cotton, oil and the railroad crossing that created it.",
		},
		eletrico = {
			pt = "O aeroporto de Dallas–Fort Worth, de 1974, virou um dos maiores do mundo. Os trens de passageiros quase sumiram.",
			en = "Dallas–Fort Worth airport, opened in 1974, became one of the world's largest. Passenger trains nearly disappeared.",
		},
		alta = {
			pt = "Tem a maior rede de bondes modernos do país e espera o trem-bala até Houston.",
			en = "It has the country's largest light rail network and awaits the bullet train to Houston.",
		},
	},
	denver = {
		diesel = {
			pt = "O California Zephyr, de 1949, saía daqui e cruzava as Rochosas com vagões de teto de vidro.",
			en = "The California Zephyr, launched in 1949, left from here and crossed the Rockies with glass-domed cars.",
		},
		eletrico = {
			pt = "O boom do petróleo e do esqui fez a cidade crescer; a Union Station seguiu recebendo o Zephyr da Amtrak.",
			en = "The oil and ski booms made the city grow; Union Station kept receiving Amtrak's Zephyr.",
		},
		alta = {
			pt = "A Union Station reformada, de 2014, virou o centro de uma rede nova de trens até o aeroporto e os subúrbios.",
			en = "The renovated Union Station, reopened in 2014, became the hub of a new rail network to the airport and suburbs.",
		},
	},
	portland = {
		diesel = {
			pt = "Porto da madeira e dos grãos do Noroeste, com estaleiros que fizeram centenas de navios na guerra.",
			en = "Port for the Northwest's timber and grain, with shipyards that built hundreds of ships during the war.",
		},
		eletrico = {
			pt = "Trocou uma rodovia à beira do rio por um parque e, em 1986, abriu uma das primeiras redes de bonde moderno do país.",
			en = "It swapped a riverside highway for a park and, in 1986, opened one of the country's first modern light rail networks.",
		},
		alta = {
			pt = "Referência em transporte público; o trem Cascades a liga a Seattle e Vancouver.",
			en = "A model for public transit; the Cascades train links it to Seattle and Vancouver.",
		},
	},
	seattle = {
		diesel = {
			pt = "A Boeing fez dela a cidade dos aviões. As ferrovias levavam a madeira e os grãos até o porto.",
			en = "Boeing made it the city of airplanes. The railroads carried timber and grain to the port.",
		},
		eletrico = {
			pt = "O porto virou um dos maiores de contêineres do país, com trens que seguem direto para o Meio-Oeste.",
			en = "The port became one of the country's largest for containers, with trains heading straight to the Midwest.",
		},
		alta = {
			pt = "Cidade da tecnologia, ligada a Portland pelo trem Cascades e cortada por uma rede de bondes modernos que só cresce.",
			en = "A tech city, linked to Portland by the Cascades train and crossed by an ever-growing light rail network.",
		},
	},
	san_francisco = {
		diesel = {
			pt = "A ponte Bay Bridge, de 1936, levou trens até Oakland. Os passageiros do leste ainda chegavam de balsa.",
			en = "The 1936 Bay Bridge carried trains to Oakland. Passengers from the East still arrived by ferry.",
		},
		eletrico = {
			pt = "O metrô BART, de 1972, passou por um túnel sob a baía. Os bondinhos de cabo viraram símbolo da cidade.",
			en = "The BART subway, opened in 1972, ran through a tunnel under the bay. The cable cars became the city's symbol.",
		},
		alta = {
			pt = "Ponta norte do trem de alta velocidade da Califórnia, ainda em obras no Vale Central. Os trens Caltrain viraram elétricos em 2024.",
			en = "Northern end of California's high-speed rail, still under construction in the Central Valley. Caltrain went electric in 2024.",
		},
	},
	los_angeles = {
		diesel = {
			pt = "A Union Station, de 1939, foi a última grande estação construída no país. Hollywood chegava e partia de trem.",
			en = "Union Station, opened in 1939, was the last great station built in the country. Hollywood arrived and left by train.",
		},
		eletrico = {
			pt = "A cidade das rodovias. O porto de Los Angeles e Long Beach virou o maior do país, e o corredor Alameda levou os contêineres aos trens.",
			en = "The city of freeways. The Los Angeles–Long Beach port became the country's largest, and the Alameda Corridor took containers to the trains.",
		},
		alta = {
			pt = "O metrô cresce a cada ano, os Jogos Olímpicos de 2028 estão chegando e o trem de alta velocidade deve um dia ligá-la a São Francisco.",
			en = "The subway grows every year, the 2028 Olympics are coming and high-speed rail should one day link it to San Francisco.",
		},
	},
	-- ================================================================ Europa
	-- Diesel = 1935–1960, Elétrica = 1960–1990, Alta Velocidade = 1990 em diante (anos do mapa da Europa).
	london = {
		diesel = {
			pt = "Os trens a vapor ainda dominavam, mas o metrô elétrico serviu de abrigo durante os bombardeios da guerra.",
			en = "Steam still ruled, but the electric Underground served as a shelter during the wartime bombing.",
		},
		eletrico = {
			pt = "O vapor acabou em 1968. A velha Euston foi demolida, e o protesto salvou a estação de St Pancras.",
			en = "Steam ended in 1968. Old Euston was demolished, and the outcry saved St Pancras station.",
		},
		alta = {
			pt = "Desde 2007 o Eurostar sai de St Pancras e chega a Paris em pouco mais de duas horas.",
			en = "Since 2007 the Eurostar has left from St Pancras and reached Paris in just over two hours.",
		},
	},
	paris = {
		diesel = {
			pt = "As ferrovias francesas foram unidas na SNCF em 1938. A Gare de l'Est viu partir e voltar os soldados da guerra.",
			en = "The French railways were merged into the SNCF in 1938. The Gare de l'Est saw soldiers leave and return from the war.",
		},
		eletrico = {
			pt = "Em 1981 o TGV ligou Paris a Lyon em duas horas, a 260 km/h: o começo da alta velocidade na Europa.",
			en = "In 1981 the TGV linked Paris to Lyon in two hours, at 260 km/h: the start of high-speed rail in Europe.",
		},
		alta = {
			pt = "Centro da maior rede de alta velocidade da Europa, com trens para Londres, Bruxelas, Amsterdã e Barcelona.",
			en = "Hub of Europe's largest high-speed network, with trains to London, Brussels, Amsterdam and Barcelona.",
		},
	},
	berlin = {
		diesel = {
			pt = "A guerra destruiu as estações. Depois, a cidade foi dividida, e as linhas entre o Leste e o Oeste foram cortadas.",
			en = "The war destroyed the stations. Afterwards the city was divided, and the lines between East and West were cut.",
		},
		eletrico = {
			pt = "O Muro, de 1961, separou os trilhos. Os trens do Oeste cruzavam a Alemanha Oriental com as portas trancadas.",
			en = "The Wall, from 1961, split the tracks. Western trains crossed East Germany with their doors locked.",
		},
		alta = {
			pt = "A Hauptbahnhof, de 2006, reuniu a cidade num só lugar, com trens cruzando em dois níveis.",
			en = "The Hauptbahnhof, opened in 2006, brought the city together in one place, with trains crossing on two levels.",
		},
	},
	istanbul = {
		diesel = {
			pt = "A estação de Sirkeci, ponta final do Expresso do Oriente, recebia viajantes de toda a Europa.",
			en = "Sirkeci station, the Orient Express terminus, welcomed travellers from all over Europe.",
		},
		eletrico = {
			pt = "Os carros e os aviões tiraram passageiros do trem. O Expresso do Oriente parou de chegar aqui em 1977.",
			en = "Cars and planes took passengers from the train. The Orient Express stopped coming here in 1977.",
		},
		alta = {
			pt = "Desde 2013 o túnel Marmaray passa sob o Bósforo e liga, de trem, a Europa à Ásia.",
			en = "Since 2013 the Marmaray tunnel has run under the Bosphorus, linking Europe to Asia by rail.",
		},
	},
	wien = {
		diesel = {
			pt = "Depois da guerra, a cidade foi dividida entre os Aliados até 1955, e as estações tiveram que ser reconstruídas.",
			en = "After the war the city was divided among the Allies until 1955, and the stations had to be rebuilt.",
		},
		eletrico = {
			pt = "Os trens elétricos passaram a subir o Semmering, e Viena virou ponte entre o Leste e o Oeste.",
			en = "Electric trains began climbing the Semmering, and Vienna became a bridge between East and West.",
		},
		alta = {
			pt = "A nova Hauptbahnhof, de 2014, juntou as linhas do sul e do leste numa estação só.",
			en = "The new Hauptbahnhof, opened in 2014, joined the southern and eastern lines in a single station.",
		},
	},
	roma = {
		diesel = {
			pt = "A nova estação Termini, com seu saguão modernista, ficou pronta em 1950.",
			en = "The new Termini station, with its modernist hall, was finished in 1950.",
		},
		eletrico = {
			pt = "A Direttissima Roma–Florença, de 1977, foi a primeira linha de alta velocidade da Europa.",
			en = "The Rome–Florence Direttissima, from 1977, was Europe's first high-speed line.",
		},
		alta = {
			pt = "Os trens Frecciarossa ligam Roma a Milão em três horas.",
			en = "Frecciarossa trains link Rome to Milan in three hours.",
		},
	},
	madrid = {
		diesel = {
			pt = "Depois da Guerra Civil, as ferrovias espanholas foram unidas na RENFE, em 1941.",
			en = "After the Civil War, the Spanish railways were merged into RENFE in 1941.",
		},
		eletrico = {
			pt = "O trem Talgo, leve e articulado, começou a mudar de bitola sem parar na fronteira francesa.",
			en = "The light, articulated Talgo train began changing gauge without stopping at the French border.",
		},
		alta = {
			pt = "Em 1992 o AVE ligou Madri a Sevilha. Hoje a Espanha tem a maior rede de alta velocidade da Europa.",
			en = "In 1992 the AVE linked Madrid to Seville. Today Spain has Europe's largest high-speed network.",
		},
	},
	lisboa = {
		diesel = {
			pt = "A estação do Rossio, com fachada neomanuelina, recebia os trens que saíam de um túnel sob a cidade.",
			en = "Rossio station, with its neo-Manueline façade, received trains coming out of a tunnel under the city.",
		},
		eletrico = {
			pt = "Os trens elétricos chegaram à Linha do Norte, e a ponte 25 de Abril ganhou trilhos em 1999.",
			en = "Electric trains reached the Northern Line, and the 25 de Abril bridge got rails in 1999.",
		},
		alta = {
			pt = "A Gare do Oriente, de 1998, foi feita para a Expo e virou a porta de entrada da cidade.",
			en = "Gare do Oriente, from 1998, was built for the Expo and became the city's gateway.",
		},
	},
	amsterdam = {
		diesel = {
			pt = "A Centraal Station, sobre ilhas artificiais, seguia sendo o coração da rede holandesa.",
			en = "Centraal Station, built on artificial islands, remained the heart of the Dutch network.",
		},
		eletrico = {
			pt = "Os holandeses criaram trens com horário cadenciado: um trem a cada meia hora em quase todas as linhas.",
			en = "The Dutch introduced clock-face timetables: a train every half hour on almost every line.",
		},
		alta = {
			pt = "Trens de alta velocidade ligam Amsterdã a Paris, Bruxelas e Londres.",
			en = "High-speed trains link Amsterdam to Paris, Brussels and London.",
		},
	},
	bruxelles = {
		diesel = {
			pt = "A Junção Norte–Sul, um túnel sob o centro, começou a ser cavada para ligar as estações da cidade.",
			en = "The North–South Junction, a tunnel under the centre, was begun to link the city's stations.",
		},
		eletrico = {
			pt = "A Junção Norte–Sul ficou pronta em 1952 e virou uma das linhas mais movimentadas da Europa.",
			en = "The North–South Junction opened in 1952 and became one of Europe's busiest lines.",
		},
		alta = {
			pt = "Encruzilhada da alta velocidade entre Paris, Londres, Amsterdã e Colônia.",
			en = "A high-speed crossroads between Paris, London, Amsterdam and Cologne.",
		},
	},
	hamburg = {
		diesel = {
			pt = "O porto e a estação foram bombardeados; a reconstrução trouxe de volta os navios e os trens.",
			en = "The port and the station were bombed; reconstruction brought back the ships and the trains.",
		},
		eletrico = {
			pt = "O porto de contêineres cresceu e os trens de carga passaram a levar as caixas para toda a Europa Central.",
			en = "The container port grew, and freight trains began carrying the boxes all over Central Europe.",
		},
		alta = {
			pt = "Os trens ICE ligam Hamburgo a Berlim em menos de duas horas.",
			en = "ICE trains link Hamburg to Berlin in under two hours.",
		},
	},
	milano = {
		diesel = {
			pt = "A estação Centrale, monumental, ficou pronta em 1931; os trens do Gotardo e do Simplon chegavam aqui.",
			en = "The monumental Centrale station was finished in 1931; Gotthard and Simplon trains arrived here.",
		},
		eletrico = {
			pt = "Capital do milagre econômico italiano, com trens lotados de trabalhadores que vinham do sul.",
			en = "Capital of Italy's economic miracle, with trains packed with workers coming from the south.",
		},
		alta = {
			pt = "O túnel de base do Gotardo, de 2016, o mais longo do mundo, aproximou Milão de Zurique.",
			en = "The Gotthard Base Tunnel, from 2016, the world's longest, brought Milan closer to Zurich.",
		},
	},
	munchen = {
		diesel = {
			pt = "A estação central foi muito danificada na guerra e reconstruída nos anos 1950.",
			en = "The central station was badly damaged in the war and rebuilt in the 1950s.",
		},
		eletrico = {
			pt = "Para os Jogos Olímpicos de 1972, a cidade ganhou o S-Bahn, com trens elétricos sob o centro.",
			en = "For the 1972 Olympics the city got the S-Bahn, with electric trains under the centre.",
		},
		alta = {
			pt = "A nova linha de alta velocidade, de 2017, levou Munique a Berlim em menos de quatro horas.",
			en = "The new high-speed line, from 2017, brought Munich to within four hours of Berlin.",
		},
	},
	budapest = {
		diesel = {
			pt = "A estação Keleti, de 1884, seguia como a grande porta de entrada da Hungria.",
			en = "Keleti station, from 1884, remained Hungary's great gateway.",
		},
		eletrico = {
			pt = "Atrás da Cortina de Ferro, os trens ligavam Budapeste a Moscou e a Viena, com longas paradas na fronteira.",
			en = "Behind the Iron Curtain, trains linked Budapest to Moscow and Vienna, with long stops at the border.",
		},
		alta = {
			pt = "Os trens Railjet ligam Budapeste a Viena e Munique sem trocar de trem.",
			en = "Railjet trains link Budapest to Vienna and Munich without changing trains.",
		},
	},
} :: { [string]: { [string]: Texto } }
