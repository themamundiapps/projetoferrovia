-- Europa.luau · GERADO por tools/dados/gerar.mjs a partir de tools/dados/europa.json. Não editar à mão.
-- Posições em pixels do mapa completo (2048x1536), na mesma projeção dos tiles.
-- Custos provisórios (economia ainda não balanceada).

return {
	id = "europa",
	moeda = "EUR",
	simbolo = "€",
	anos = {
		vapor = { 1825, 1935 },
		diesel = { 1935, 1960 },
		eletrico = { 1960, 1990 },
		alta = { 1990, 2040 },
	},
	metasEra = {
		diesel = 25,
		eletrico = 51,
		alta = 53,
	},
	terrenos = {
		planicie = { nome = "Planície", nomes = { pt = "Planície", en = "Plains" }, custo = 1 },
		costa = { nome = "Planície costeira", nomes = { pt = "Planície costeira", en = "Coastal plain" }, custo = 1.1 },
		vale = { nome = "Vale", nomes = { pt = "Vale", en = "Valley" }, custo = 1.2 },
		colinas = { nome = "Colinas", nomes = { pt = "Colinas", en = "Hills" }, custo = 1.4 },
		montanhas = { nome = "Montanhas", nomes = { pt = "Montanhas", en = "Mountains" }, custo = 2 },
		alpes = { nome = "Alpes (túneis e viadutos)", nomes = { pt = "Alpes (túneis e viadutos)", en = "Alps (tunnels and viaducts)" }, custo = 2.6 },
		tunel_base = { nome = "Túnel de base sob os Alpes", nomes = { pt = "Túnel de base sob os Alpes", en = "Base tunnel under the Alps" }, custo = 3.2 },
		mar = { nome = "Travessia do mar (túnel ou ponte)", nomes = { pt = "Travessia do mar (túnel ou ponte)", en = "Sea crossing (tunnel or bridge)" }, custo = 3.5 },
	},
	estacoes = {
		london = { nome = "Londres", nomeEn = "London", pos = Vector2.new(692.2, 610.1), lon = -0.13, lat = 51.51, porte = 5, produz = nil, porto = true, paisagem = nil, estado = "Reino Unido", regiao = "o", historia = { pt = "A maior cidade do mundo no século XIX. Cada companhia ferroviária construiu a sua própria estação terminal.", en = "The largest city in the world in the 19th century. Every railway company built its own terminus." } },
		reading = { nome = "Reading", nomeEn = nil, pos = Vector2.new(664.4, 609.3), lon = -0.97, lat = 51.45, porte = 2, produz = nil, porto = false, paisagem = "eur_campo", estado = "Reino Unido", regiao = "o", historia = { pt = "Cidade do vale do Tâmisa, primeira grande parada da Great Western a caminho de Bristol.", en = "A Thames valley town, the first big stop on the Great Western on the way to Bristol." } },
		bristol = { nome = "Bristol", nomeEn = nil, pos = Vector2.new(611.9, 600.7), lon = -2.59, lat = 51.45, porte = 3, produz = nil, porto = true, paisagem = nil, estado = "Reino Unido", regiao = "o", historia = { pt = "Porto do oeste da Inglaterra, ligado a Londres pela Great Western de Brunel em 1841.", en = "A port in the west of England, linked to London by Brunel's Great Western in 1841." } },
		birmingham = { nome = "Birmingham", nomeEn = nil, pos = Vector2.new(643.1, 550.7), lon = -1.9, lat = 52.48, porte = 4, produz = "aco", porto = false, paisagem = nil, estado = "Reino Unido", regiao = "o", historia = { pt = "A \"oficina do mundo\": fundições e fábricas de ferro ao redor de uma rede de canais.", en = "The \"workshop of the world\": foundries and ironworks around a web of canals." } },
		crewe = { nome = "Crewe", nomeEn = nil, pos = Vector2.new(631.7, 515.4), lon = -2.44, lat = 53.1, porte = 1, produz = nil, porto = false, paisagem = "eur_industria", estado = "Reino Unido", regiao = "o", historia = { pt = "Uma vila que a ferrovia criou: oficinas de locomotivas e o grande entroncamento do noroeste.", en = "A town the railway created: locomotive works and the great junction of the north-west." } },
		manchester = { nome = "Manchester", nomeEn = nil, pos = Vector2.new(641.3, 496.7), lon = -2.24, lat = 53.48, porte = 4, produz = nil, porto = false, paisagem = nil, estado = "Reino Unido", regiao = "o", historia = { pt = "A capital do algodão, cheia de chaminés. A primeira estação de passageiros do mundo abriu aqui em 1830.", en = "Cottonopolis, full of chimneys. The world's first passenger station opened here in 1830." } },
		liverpool = { nome = "Liverpool", nomeEn = nil, pos = Vector2.new(617.8, 496.3), lon = -2.98, lat = 53.41, porte = 4, produz = nil, porto = true, paisagem = nil, estado = "Reino Unido", regiao = "o", historia = { pt = "O porto do algodão que vinha da América, que precisava chegar rápido às fábricas de Manchester.", en = "The port for American cotton, which had to reach the mills of Manchester quickly." } },
		darlington = { nome = "Darlington", nomeEn = nil, pos = Vector2.new(671.5, 445.9), lon = -1.55, lat = 54.52, porte = 1, produz = "carvao", porto = false, paisagem = "eur_industria", estado = "Reino Unido", regiao = "o", historia = { pt = "Cidade das minas de carvão de Durham, de onde saiu o primeiro trem a vapor público, em 1825.", en = "A town of the Durham coal mines, where the first public steam train set out in 1825." } },
		stockton = { nome = "Stockton-on-Tees", nomeEn = nil, pos = Vector2.new(678.9, 444.4), lon = -1.32, lat = 54.57, porte = 1, produz = nil, porto = true, paisagem = "eur_costa", estado = "Reino Unido", regiao = "o", historia = { pt = "Porto do rio Tees, ponta final da Stockton and Darlington: o carvão seguia daqui em barcos.", en = "A port on the River Tees, the end of the Stockton and Darlington: coal went on from here by boat." } },
		york = { nome = "York", nomeEn = nil, pos = Vector2.new(681.1, 477.5), lon = -1.08, lat = 53.96, porte = 3, produz = nil, porto = false, paisagem = nil, estado = "Reino Unido", regiao = "o", historia = { pt = "Cidade medieval que virou o grande entroncamento do norte, terra do \"rei das ferrovias\" George Hudson.", en = "A medieval city that became the great junction of the north, home of \"Railway King\" George Hudson." } },
		newcastle = { nome = "Newcastle", nomeEn = nil, pos = Vector2.new(673.6, 422.1), lon = -1.61, lat = 54.97, porte = 3, produz = "carvao", porto = true, paisagem = nil, estado = "Reino Unido", regiao = "o", historia = { pt = "Terra de George Stephenson e do carvão do Tyne, que abastecia Londres por mar.", en = "Home of George Stephenson and Tyne coal, which supplied London by sea." } },
		edinburgh = { nome = "Edimburgo", nomeEn = "Edinburgh", pos = Vector2.new(636.2, 362.9), lon = -3.19, lat = 55.95, porte = 4, produz = nil, porto = true, paisagem = nil, estado = "Reino Unido", regiao = "o", historia = { pt = "Capital da Escócia; o Flying Scotsman a liga a Londres desde 1862.", en = "Scotland's capital; the Flying Scotsman has linked it to London since 1862." } },
		paris = { nome = "Paris", nomeEn = nil, pos = Vector2.new(758.6, 759.4), lon = 2.35, lat = 48.86, porte = 5, produz = nil, porto = false, paisagem = nil, estado = "França", regiao = "o", historia = { pt = "Centro de uma rede em estrela: seis grandes estações, cada uma voltada para uma região da França.", en = "Hub of a star-shaped network: six great stations, each facing a region of France." } },
		rouen = { nome = "Ruão", nomeEn = "Rouen", pos = Vector2.new(719.1, 724.1), lon = 1.1, lat = 49.44, porte = 2, produz = "graos", porto = false, paisagem = "eur_campo", estado = "França", regiao = "o", historia = { pt = "Cidade do rio Sena, no caminho entre Paris e o mar; a linha foi construída por operários ingleses.", en = "A city on the Seine, between Paris and the sea; the line was built by English navvies." } },
		le_havre = { nome = "Le Havre", nomeEn = nil, pos = Vector2.new(685.7, 717.1), lon = 0.11, lat = 49.49, porte = 2, produz = nil, porto = true, paisagem = "eur_costa", estado = "França", regiao = "o", historia = { pt = "O porto atlântico de Paris, de onde saíam os navios para Nova York.", en = "Paris's Atlantic port, where ships left for New York." } },
		lille = { nome = "Lille", nomeEn = nil, pos = Vector2.new(791.8, 668.7), lon = 3.06, lat = 50.63, porte = 3, produz = "acucar", porto = false, paisagem = nil, estado = "França", regiao = "o", historia = { pt = "Cidade têxtil do norte, cercada de campos de beterraba e de minas de carvão.", en = "A textile city in the north, surrounded by sugar-beet fields and coal mines." } },
		dijon = { nome = "Dijon", nomeEn = nil, pos = Vector2.new(846.4, 848.6), lon = 5.04, lat = 47.32, porte = 2, produz = nil, porto = false, paisagem = "eur_campo", estado = "França", regiao = "o", historia = { pt = "Capital da Borgonha, dos vinhedos e da mostarda, no meio do caminho entre Paris e Lyon.", en = "Capital of Burgundy, of vineyards and mustard, halfway between Paris and Lyon." } },
		lyon = { nome = "Lyon", nomeEn = nil, pos = Vector2.new(833.7, 930.2), lon = 4.84, lat = 45.76, porte = 4, produz = nil, porto = false, paisagem = nil, estado = "França", regiao = "o", historia = { pt = "Cidade da seda, onde o Saône encontra o Ródano.", en = "The silk city, where the Saône meets the Rhône." } },
		marseille = { nome = "Marselha", nomeEn = "Marseille", pos = Vector2.new(845.6, 1061.0), lon = 5.37, lat = 43.3, porte = 4, produz = nil, porto = true, paisagem = nil, estado = "França", regiao = "o", historia = { pt = "O grande porto francês do Mediterrâneo, porta para a Argélia e o Oriente.", en = "France's great Mediterranean port, gateway to Algeria and the East." } },
		chambery = { nome = "Chambéry", nomeEn = nil, pos = Vector2.new(873.0, 942.7), lon = 5.92, lat = 45.57, porte = 1, produz = nil, porto = false, paisagem = "eur_alpes", estado = "França", regiao = "o", historia = { pt = "Antiga capital da Saboia, ao pé dos Alpes, no caminho do túnel do Fréjus.", en = "The old capital of Savoy, at the foot of the Alps, on the way to the Fréjus tunnel." } },
		bruxelles = { nome = "Bruxelas", nomeEn = "Brussels", pos = Vector2.new(835.8, 660.8), lon = 4.35, lat = 50.85, porte = 4, produz = nil, porto = false, paisagem = nil, estado = "Bélgica", regiao = "o", historia = { pt = "A Bélgica abriu a primeira ferrovia pública do continente em 1835, saindo de Bruxelas.", en = "Belgium opened the continent's first public railway in 1835, out of Brussels." } },
		antwerpen = { nome = "Antuérpia", nomeEn = "Antwerp", pos = Vector2.new(838.9, 641.5), lon = 4.4, lat = 51.22, porte = 3, produz = nil, porto = true, paisagem = nil, estado = "Bélgica", regiao = "o", historia = { pt = "O grande porto da Bélgica, no rio Escalda.", en = "Belgium's great port, on the Scheldt." } },
		amsterdam = { nome = "Amsterdã", nomeEn = "Amsterdam", pos = Vector2.new(859.7, 582.1), lon = 4.9, lat = 52.37, porte = 4, produz = nil, porto = true, paisagem = nil, estado = "Países Baixos", regiao = "o", historia = { pt = "A primeira ferrovia holandesa, de 1839, ligou Amsterdã a Haarlem.", en = "The first Dutch railway, in 1839, linked Amsterdam to Haarlem." } },
		rotterdam = { nome = "Roterdã", nomeEn = "Rotterdam", pos = Vector2.new(844.4, 604.8), lon = 4.48, lat = 51.92, porte = 3, produz = nil, porto = true, paisagem = nil, estado = "Países Baixos", regiao = "o", historia = { pt = "Porto na foz do Reno, que viria a ser o maior da Europa.", en = "A port at the mouth of the Rhine that would become Europe's largest." } },
		koln = { nome = "Colônia", nomeEn = "Cologne", pos = Vector2.new(922.8, 661.3), lon = 6.96, lat = 50.94, porte = 4, produz = nil, porto = false, paisagem = nil, estado = "Alemanha", regiao = "c", historia = { pt = "Cidade da catedral, à beira do Reno; a Köln-Mindener a ligou ao norte da Alemanha.", en = "The cathedral city on the Rhine; the Köln-Mindener linked it to northern Germany." } },
		essen = { nome = "Essen", nomeEn = nil, pos = Vector2.new(925.6, 633.9), lon = 7.01, lat = 51.46, porte = 3, produz = "carvao", porto = false, paisagem = nil, estado = "Alemanha", regiao = "c", historia = { pt = "Coração do Vale do Ruhr: carvão e as siderúrgicas da Krupp.", en = "Heart of the Ruhr Valley: coal and the Krupp steelworks." } },
		hannover = { nome = "Hanôver", nomeEn = "Hanover", pos = Vector2.new(1015.3, 587.8), lon = 9.73, lat = 52.37, porte = 3, produz = nil, porto = false, paisagem = nil, estado = "Alemanha", regiao = "c", historia = { pt = "Capital de um reino e grande cruzamento das ferrovias do norte alemão.", en = "Capital of a kingdom and a great crossroads of northern German railways." } },
		berlin = { nome = "Berlim", nomeEn = "Berlin", pos = Vector2.new(1133.2, 577.4), lon = 13.4, lat = 52.52, porte = 5, produz = nil, porto = false, paisagem = nil, estado = "Alemanha", regiao = "c", historia = { pt = "Capital da Prússia e, depois, do Império Alemão, com estações para cada direção.", en = "Capital of Prussia and later of the German Empire, with stations for every direction." } },
		hamburg = { nome = "Hamburgo", nomeEn = "Hamburg", pos = Vector2.new(1023.7, 525.5), lon = 9.99, lat = 53.55, porte = 4, produz = nil, porto = true, paisagem = nil, estado = "Alemanha", regiao = "c", historia = { pt = "O porto alemão para o mundo, no rio Elba.", en = "Germany's port to the world, on the Elbe." } },
		leipzig = { nome = "Leipzig", nomeEn = nil, pos = Vector2.new(1102.2, 641.0), lon = 12.37, lat = 51.34, porte = 3, produz = nil, porto = false, paisagem = nil, estado = "Alemanha", regiao = "c", historia = { pt = "Cidade das feiras e dos livros; a Leipzig–Dresden foi a primeira ferrovia de longa distância da Alemanha.", en = "A city of trade fairs and books; the Leipzig–Dresden was Germany's first long-distance railway." } },
		dresden = { nome = "Dresden", nomeEn = nil, pos = Vector2.new(1148.1, 654.4), lon = 13.74, lat = 51.05, porte = 3, produz = nil, porto = false, paisagem = nil, estado = "Alemanha", regiao = "c", historia = { pt = "A \"Florença do Elba\", capital da Saxônia.", en = "The \"Florence on the Elbe\", capital of Saxony." } },
		munchen = { nome = "Munique", nomeEn = "Munich", pos = Vector2.new(1079.7, 810.7), lon = 11.58, lat = 48.14, porte = 4, produz = nil, porto = false, paisagem = nil, estado = "Alemanha", regiao = "c", historia = { pt = "Capital da Baviera, porta da ferrovia que cruza os Alpes pelo Brenner.", en = "Capital of Bavaria, gateway to the railway across the Alps through the Brenner." } },
		kobenhavn = { nome = "Copenhague", nomeEn = "Copenhagen", pos = Vector2.new(1100.6, 411.6), lon = 12.57, lat = 55.68, porte = 4, produz = nil, porto = true, paisagem = nil, estado = "Dinamarca", regiao = "c", historia = { pt = "Capital da Dinamarca, entre o Mar do Norte e o Báltico.", en = "Denmark's capital, between the North Sea and the Baltic." } },
		zurich = { nome = "Zurique", nomeEn = "Zurich", pos = Vector2.new(971.7, 851.4), lon = 8.54, lat = 47.37, porte = 3, produz = nil, porto = false, paisagem = nil, estado = "Suíça", regiao = "c", historia = { pt = "Cidade dos bancos e do lago, ponto de partida para o túnel do Gotardo.", en = "A city of banks and the lake, starting point for the Gotthard tunnel." } },
		luzern = { nome = "Lucerna", nomeEn = "Lucerne", pos = Vector2.new(963.1, 868.1), lon = 8.31, lat = 47.05, porte = 2, produz = "gado", porto = false, paisagem = "eur_alpes", estado = "Suíça", regiao = "c", historia = { pt = "Cidade do lago e dos prados alpinos, ao pé da subida do Gotardo.", en = "A lakeside town of alpine meadows, at the foot of the Gotthard climb." } },
		lausanne = { nome = "Lausanne", nomeEn = nil, pos = Vector2.new(901.4, 894.0), lon = 6.63, lat = 46.52, porte = 2, produz = nil, porto = false, paisagem = "eur_alpes", estado = "Suíça", regiao = "c", historia = { pt = "No lago Léman, onde começa a linha para o túnel do Simplon.", en = "On Lake Geneva, where the line to the Simplon tunnel begins." } },
		innsbruck = { nome = "Innsbruck", nomeEn = nil, pos = Vector2.new(1074.2, 856.7), lon = 11.4, lat = 47.27, porte = 2, produz = nil, porto = false, paisagem = "eur_alpes", estado = "Áustria", regiao = "c", historia = { pt = "Capital do Tirol, cercada de montanhas, no caminho do Passo do Brenner.", en = "Capital of the Tyrol, surrounded by mountains, on the way to the Brenner Pass." } },
		wien = { nome = "Viena", nomeEn = "Vienna", pos = Vector2.new(1248.0, 797.9), lon = 16.37, lat = 48.21, porte = 4, produz = nil, porto = false, paisagem = nil, estado = "Áustria", regiao = "c", historia = { pt = "Capital do Império Austro-Húngaro; daqui saíam as linhas para o Adriático e para o Oriente.", en = "Capital of the Austro-Hungarian Empire; lines to the Adriatic and the East started here." } },
		graz = { nome = "Graz", nomeEn = nil, pos = Vector2.new(1219.7, 860.5), lon = 15.44, lat = 47.07, porte = 2, produz = nil, porto = false, paisagem = "eur_alpes", estado = "Áustria", regiao = "c", historia = { pt = "Cidade da Estíria, logo depois da subida do Semmering.", en = "A Styrian city, just past the Semmering climb." } },
		ljubljana = { nome = "Liubliana", nomeEn = "Ljubljana", pos = Vector2.new(1189.4, 916.0), lon = 14.51, lat = 46.06, porte = 2, produz = nil, porto = false, paisagem = "eur_alpes", estado = "Eslovênia", regiao = "c", historia = { pt = "Cidade pequena na Südbahn, entre Viena e o mar.", en = "A small city on the Südbahn, between Vienna and the sea." } },
		trieste = { nome = "Trieste", nomeEn = nil, pos = Vector2.new(1163.7, 939.1), lon = 13.78, lat = 45.65, porte = 3, produz = nil, porto = true, paisagem = nil, estado = "Itália", regiao = "s", historia = { pt = "O porto do Império Austríaco no Adriático, ponta final da Südbahn em 1857.", en = "The Austrian Empire's Adriatic port, end of the Südbahn in 1857." } },
		brno = { nome = "Brno", nomeEn = nil, pos = Vector2.new(1251.9, 745.0), lon = 16.61, lat = 49.2, porte = 2, produz = nil, porto = false, paisagem = "eur_industria", estado = "Tchéquia", regiao = "c", historia = { pt = "Cidade têxtil da Morávia, primeira grande parada da Kaiser Ferdinands-Nordbahn.", en = "A Moravian textile city, the first big stop on the Kaiser Ferdinands-Nordbahn." } },
		krakow = { nome = "Cracóvia", nomeEn = "Kraków", pos = Vector2.new(1360.0, 687.0), lon = 19.94, lat = 50.06, porte = 3, produz = "carvao", porto = false, paisagem = nil, estado = "Polônia", regiao = "c", historia = { pt = "Antiga capital polonesa, perto das minas de carvão da Silésia.", en = "The old Polish capital, near the coal mines of Silesia." } },
		poznan = { nome = "Poznań", nomeEn = nil, pos = Vector2.new(1246.9, 575.1), lon = 16.93, lat = 52.41, porte = 2, produz = "graos", porto = false, paisagem = "eur_campo", estado = "Polônia", regiao = "c", historia = { pt = "Cidade das planícies de trigo, no caminho de Berlim a Varsóvia.", en = "A city of wheat plains, on the way from Berlin to Warsaw." } },
		warszawa = { nome = "Varsóvia", nomeEn = "Warsaw", pos = Vector2.new(1378.7, 568.3), lon = 21.01, lat = 52.23, porte = 4, produz = nil, porto = false, paisagem = nil, estado = "Polônia", regiao = "c", historia = { pt = "Capital polonesa, à beira do rio Vístula.", en = "The Polish capital, on the Vistula." } },
		budapest = { nome = "Budapeste", nomeEn = "Budapest", pos = Vector2.new(1346.0, 825.3), lon = 19.04, lat = 47.5, porte = 4, produz = "graos", porto = false, paisagem = nil, estado = "Hungria", regiao = "l", historia = { pt = "As cidades de Buda e Peste, unidas em 1873; o trigo da planície húngara passava por aqui.", en = "The towns of Buda and Pest, united in 1873; wheat from the Hungarian plain passed through here." } },
		beograd = { nome = "Belgrado", nomeEn = "Belgrade", pos = Vector2.new(1415.5, 960.5), lon = 20.46, lat = 44.79, porte = 3, produz = nil, porto = false, paisagem = nil, estado = "Sérvia", regiao = "l", historia = { pt = "Capital da Sérvia, onde o Sava encontra o Danúbio; o Expresso do Oriente passava aqui.", en = "Serbia's capital, where the Sava meets the Danube; the Orient Express came through here." } },
		sofia = { nome = "Sófia", nomeEn = "Sofia", pos = Vector2.new(1539.7, 1052.2), lon = 23.32, lat = 42.7, porte = 3, produz = nil, porto = false, paisagem = nil, estado = "Bulgária", regiao = "l", historia = { pt = "Capital da Bulgária desde 1879, no caminho de Viena a Constantinopla.", en = "Bulgaria's capital since 1879, on the way from Vienna to Constantinople." } },
		istanbul = { nome = "Istambul", nomeEn = "Istanbul", pos = Vector2.new(1775.1, 1091.8), lon = 28.98, lat = 41.01, porte = 5, produz = nil, porto = true, paisagem = nil, estado = "Turquia", regiao = "l", historia = { pt = "Constantinopla, a ponte entre a Europa e a Ásia, ponta final do Expresso do Oriente.", en = "Constantinople, the bridge between Europe and Asia, end of the Orient Express." } },
		torino = { nome = "Turim", nomeEn = "Turin", pos = Vector2.new(937.7, 971.9), lon = 7.69, lat = 45.07, porte = 4, produz = nil, porto = false, paisagem = nil, estado = "Itália", regiao = "s", historia = { pt = "Capital do Piemonte e primeira capital da Itália unificada.", en = "Capital of Piedmont and first capital of unified Italy." } },
		milano = { nome = "Milão", nomeEn = "Milan", pos = Vector2.new(993.9, 952.5), lon = 9.19, lat = 45.46, porte = 4, produz = nil, porto = false, paisagem = nil, estado = "Itália", regiao = "s", historia = { pt = "A capital industrial italiana, onde chegam os túneis do Gotardo e do Simplon.", en = "Italy's industrial capital, where the Gotthard and Simplon tunnels arrive." } },
		verona = { nome = "Verona", nomeEn = nil, pos = Vector2.new(1060.8, 953.5), lon = 10.99, lat = 45.44, porte = 2, produz = nil, porto = false, paisagem = "eur_mediterraneo", estado = "Itália", regiao = "s", historia = { pt = "Cidade de Romeu e Julieta, onde a linha do Brenner desce na planície do Pó.", en = "The city of Romeo and Juliet, where the Brenner line comes down into the Po plain." } },
		venezia = { nome = "Veneza", nomeEn = "Venice", pos = Vector2.new(1110.1, 952.4), lon = 12.32, lat = 45.44, porte = 3, produz = nil, porto = true, paisagem = nil, estado = "Itália", regiao = "s", historia = { pt = "A cidade sobre a água, ligada ao continente por uma ponte ferroviária em 1846.", en = "The city on the water, linked to the mainland by a railway bridge in 1846." } },
		roma = { nome = "Roma", nomeEn = "Rome", pos = Vector2.new(1122.7, 1138.6), lon = 12.5, lat = 41.9, porte = 4, produz = nil, porto = false, paisagem = nil, estado = "Itália", regiao = "s", historia = { pt = "A capital da Itália desde 1871; a estação Termini fica ao lado das termas antigas.", en = "Italy's capital since 1871; Termini station stands next to the ancient baths." } },
		napoli = { nome = "Nápoles", nomeEn = "Naples", pos = Vector2.new(1195.3, 1190.6), lon = 14.27, lat = 40.85, porte = 4, produz = nil, porto = true, paisagem = nil, estado = "Itália", regiao = "s", historia = { pt = "A primeira ferrovia da Itália, de 1839, saiu de Nápoles para Portici, ao pé do Vesúvio.", en = "Italy's first railway, in 1839, ran from Naples to Portici, at the foot of Vesuvius." } },
		reggio = { nome = "Reggio Calabria", nomeEn = nil, pos = Vector2.new(1260.3, 1330.6), lon = 15.65, lat = 38.11, porte = 2, produz = nil, porto = true, paisagem = "eur_mediterraneo", estado = "Itália", regiao = "s", historia = { pt = "A ponta da bota italiana, de frente para a Sicília.", en = "The toe of the Italian boot, facing Sicily." } },
		messina = { nome = "Messina", nomeEn = "Strait of Messina Bridge", pos = Vector2.new(1255.9, 1326.7), lon = 15.55, lat = 38.19, porte = 2, produz = nil, porto = true, paisagem = "eur_mediterraneo", estado = "Itália", regiao = "s", historia = { pt = "Do outro lado do estreito: os trens atravessam até hoje em balsas.", en = "Across the strait: trains still cross on ferries today." } },
		palermo = { nome = "Palermo", nomeEn = nil, pos = Vector2.new(1164.6, 1335.7), lon = 13.36, lat = 38.12, porte = 3, produz = nil, porto = true, paisagem = nil, estado = "Itália", regiao = "s", historia = { pt = "Capital da Sicília, entre o mar e as montanhas.", en = "Sicily's capital, between the sea and the mountains." } },
		madrid = { nome = "Madri", nomeEn = "Madrid", pos = Vector2.new(473.6, 1168.0), lon = -3.7, lat = 40.42, porte = 4, produz = nil, porto = false, paisagem = nil, estado = "Espanha", regiao = "s", historia = { pt = "A capital no centro da meseta: todas as ferrovias espanholas partem daqui, em bitola larga.", en = "The capital in the middle of the plateau: every Spanish railway starts here, on broad gauge." } },
		zaragoza = { nome = "Saragoça", nomeEn = "Zaragoza", pos = Vector2.new(594.5, 1122.3), lon = -0.88, lat = 41.65, porte = 3, produz = nil, porto = false, paisagem = nil, estado = "Espanha", regiao = "s", historia = { pt = "Cidade do rio Ebro, no meio do caminho entre Madri e Barcelona.", en = "A city on the Ebro, halfway between Madrid and Barcelona." } },
		barcelona = { nome = "Barcelona", nomeEn = nil, pos = Vector2.new(713.0, 1150.9), lon = 2.17, lat = 41.39, porte = 4, produz = nil, porto = true, paisagem = nil, estado = "Espanha", regiao = "s", historia = { pt = "A primeira ferrovia da Espanha continental, de 1848, ligou Barcelona a Mataró.", en = "Mainland Spain's first railway, in 1848, linked Barcelona to Mataró." } },
		valladolid = { nome = "Valladolid", nomeEn = nil, pos = Vector2.new(444.8, 1096.5), lon = -4.72, lat = 41.65, porte = 2, produz = "graos", porto = false, paisagem = "eur_campo", estado = "Espanha", regiao = "s", historia = { pt = "No coração dos trigais de Castela.", en = "In the heart of the wheat fields of Castile." } },
		burgos = { nome = "Burgos", nomeEn = nil, pos = Vector2.new(490.5, 1068.2), lon = -3.7, lat = 42.34, porte = 1, produz = nil, porto = false, paisagem = "eur_campo", estado = "Espanha", regiao = "s", historia = { pt = "Cidade da catedral gótica, no caminho de Madri para o norte.", en = "A city of a Gothic cathedral, on the way from Madrid to the north." } },
		bilbao = { nome = "Bilbau", nomeEn = "Bilbao", pos = Vector2.new(527.9, 1025.7), lon = -2.93, lat = 43.26, porte = 3, produz = "minerio", porto = true, paisagem = nil, estado = "Espanha", regiao = "s", historia = { pt = "O minério de ferro basco saía daqui de navio para as siderúrgicas inglesas.", en = "Basque iron ore left from here by ship for English steelworks." } },
		lisboa = { nome = "Lisboa", nomeEn = "Lisbon", pos = Vector2.new(239.2, 1207.8), lon = -9.14, lat = 38.72, porte = 4, produz = nil, porto = true, paisagem = nil, estado = "Portugal", regiao = "s", historia = { pt = "Capital de Portugal, no estuário do Tejo; a primeira linha abriu em 1856.", en = "Portugal's capital, on the Tagus estuary; the first line opened in 1856." } },
		coimbra = { nome = "Coimbra", nomeEn = nil, pos = Vector2.new(284.8, 1138.4), lon = -8.43, lat = 40.21, porte = 2, produz = nil, porto = false, paisagem = "eur_campo", estado = "Portugal", regiao = "s", historia = { pt = "Cidade universitária no caminho entre Lisboa e o Porto.", en = "A university city on the way between Lisbon and Porto." } },
		porto = { nome = "Porto", nomeEn = nil, pos = Vector2.new(288.9, 1088.3), lon = -8.61, lat = 41.15, porte = 3, produz = nil, porto = true, paisagem = nil, estado = "Portugal", regiao = "s", historia = { pt = "Cidade do vinho do Porto; a ponte de Eiffel sobre o Douro trouxe o trem até aqui.", en = "The city of port wine; Eiffel's bridge over the Douro brought the train here." } },
		stockholm = { nome = "Estocolmo", nomeEn = "Stockholm", pos = Vector2.new(1241.4, 208.0), lon = 18.07, lat = 59.33, porte = 4, produz = "madeira", porto = true, paisagem = nil, estado = "Suécia", regiao = "n", historia = { pt = "Capital da Suécia, construída sobre ilhas; a madeira das florestas do norte chegava por aqui.", en = "Sweden's capital, built on islands; timber from the northern forests came through here." } },
		goteborg = { nome = "Gotemburgo", nomeEn = "Gothenburg", pos = Vector2.new(1079.7, 305.1), lon = 11.97, lat = 57.71, porte = 3, produz = nil, porto = true, paisagem = nil, estado = "Suécia", regiao = "n", historia = { pt = "O porto sueco voltado para o Mar do Norte.", en = "Sweden's port facing the North Sea." } },
		kaunas = { nome = "Kaunas", nomeEn = nil, pos = Vector2.new(1443.3, 413.5), lon = 23.9, lat = 54.9, porte = 2, produz = nil, porto = false, paisagem = "eur_norte", estado = "Lituânia", regiao = "n", historia = { pt = "Antiga capital da Lituânia, no caminho da Rail Baltica.", en = "Lithuania's old capital, on the Rail Baltica route." } },
		riga = { nome = "Riga", nomeEn = nil, pos = Vector2.new(1427.8, 305.9), lon = 24.11, lat = 56.95, porte = 3, produz = nil, porto = true, paisagem = nil, estado = "Letônia", regiao = "n", historia = { pt = "Capital da Letônia e porto do Báltico.", en = "Latvia's capital and a Baltic port." } },
		tallinn = { nome = "Tallinn", nomeEn = nil, pos = Vector2.new(1417.7, 173.5), lon = 24.75, lat = 59.44, porte = 2, produz = nil, porto = true, paisagem = "eur_norte", estado = "Estônia", regiao = "n", historia = { pt = "Capital da Estônia, com a cidade velha murada de frente para o mar.", en = "Estonia's capital, with its walled old town facing the sea." } },
		glasgow = { nome = "Glasgow", nomeEn = nil, pos = Vector2.new(604.5, 361.6), lon = -4.25, lat = 55.86, porte = 4, produz = "aco", porto = true, paisagem = nil, estado = "Reino Unido", regiao = "o", historia = { pt = "A segunda cidade do Império Britânico, dos estaleiros do rio Clyde e das locomotivas exportadas para o mundo todo.", en = "The Second City of the Empire, of the Clyde shipyards and locomotives exported all over the world." } },
		carlisle = { nome = "Carlisle", nomeEn = nil, pos = Vector2.new(633.5, 419.5), lon = -2.93, lat = 54.89, porte = 1, produz = nil, porto = false, paisagem = "eur_campo", estado = "Reino Unido", regiao = "o", historia = { pt = "Cidade da fronteira com a Escócia, onde sete companhias ferroviárias dividiam a mesma estação.", en = "A border city with Scotland, where seven railway companies shared one station." } },
		aberdeen = { nome = "Aberdeen", nomeEn = nil, pos = Vector2.new(679.1, 306.1), lon = -2.09, lat = 57.15, porte = 2, produz = nil, porto = true, paisagem = "eur_costa", estado = "Reino Unido", regiao = "o", historia = { pt = "A \"cidade de granito\" do nordeste da Escócia, porto de pesca no Mar do Norte.", en = "The \"Granite City\" of north-east Scotland, a fishing port on the North Sea." } },
		orleans = { nome = "Orléans", nomeEn = nil, pos = Vector2.new(738.0, 808.2), lon = 1.91, lat = 47.9, porte = 2, produz = "graos", porto = false, paisagem = "eur_campo", estado = "França", regiao = "o", historia = { pt = "Cidade de Joana d'Arc, no Loire, primeira parada das linhas que saíam de Paris para o sudoeste.", en = "Joan of Arc's city on the Loire, the first stop on the lines from Paris to the south-west." } },
		bordeaux = { nome = "Bordéus", nomeEn = "Bordeaux", pos = Vector2.new(628.4, 957.2), lon = -0.58, lat = 44.84, porte = 4, produz = nil, porto = true, paisagem = nil, estado = "França", regiao = "o", historia = { pt = "O porto do vinho, no rio Garona, ligado a Paris pela companhia Paris–Orléans em 1853.", en = "The wine port on the Garonne, linked to Paris by the Paris–Orléans company in 1853." } },
		toulouse = { nome = "Toulouse", nomeEn = nil, pos = Vector2.new(696.5, 1032.0), lon = 1.44, lat = 43.6, porte = 3, produz = nil, porto = false, paisagem = nil, estado = "França", regiao = "o", historia = { pt = "A \"cidade rosa\", ao lado do Canal du Midi, que a ferrovia dos irmãos Pereire passou a acompanhar.", en = "The \"Pink City\", beside the Canal du Midi, which the Pereire brothers' railway came to follow." } },
		montpellier = { nome = "Montpellier", nomeEn = nil, pos = Vector2.new(789.6, 1040.6), lon = 3.88, lat = 43.61, porte = 2, produz = nil, porto = false, paisagem = "eur_mediterraneo", estado = "França", regiao = "o", historia = { pt = "Cidade universitária do Languedoc, entre os vinhedos e o Mediterrâneo.", en = "A university city in Languedoc, between the vineyards and the Mediterranean." } },
		nancy = { nome = "Nancy", nomeEn = nil, pos = Vector2.new(890.8, 778.7), lon = 6.18, lat = 48.69, porte = 2, produz = "aco", porto = false, paisagem = "eur_industria", estado = "França", regiao = "o", historia = { pt = "Capital da Lorena, das minas de ferro e das siderúrgicas do leste da França.", en = "Capital of Lorraine, of iron mines and the steelworks of eastern France." } },
		strasbourg = { nome = "Estrasburgo", nomeEn = "Strasbourg", pos = Vector2.new(945.3, 786.8), lon = 7.75, lat = 48.58, porte = 3, produz = nil, porto = false, paisagem = nil, estado = "França", regiao = "o", historia = { pt = "Cidade da catedral, à beira do Reno, que trocou de país várias vezes entre a França e a Alemanha.", en = "The cathedral city on the Rhine, which changed hands between France and Germany several times." } },
		liege = { nome = "Liège", nomeEn = nil, pos = Vector2.new(875.6, 675.2), lon = 5.57, lat = 50.63, porte = 2, produz = "carvao", porto = false, paisagem = "eur_industria", estado = "Bélgica", regiao = "o", historia = { pt = "Cidade do carvão e do aço no vale do Mosa; aqui nasceu a primeira ferrovia internacional da Europa.", en = "A city of coal and steel in the Meuse valley; Europe's first international railway began here." } },
		koblenz = { nome = "Koblenz", nomeEn = nil, pos = Vector2.new(942.8, 692.7), lon = 7.59, lat = 50.36, porte = 2, produz = nil, porto = false, paisagem = "eur_campo", estado = "Alemanha", regiao = "c", historia = { pt = "Onde o Mosela encontra o Reno, entre castelos e vinhedos.", en = "Where the Moselle meets the Rhine, among castles and vineyards." } },
		frankfurt = { nome = "Frankfurt", nomeEn = nil, pos = Vector2.new(979.3, 706.8), lon = 8.68, lat = 50.11, porte = 4, produz = nil, porto = false, paisagem = nil, estado = "Alemanha", regiao = "c", historia = { pt = "Cidade dos bancos e das feiras, no rio Meno; sua estação central, de 1888, era a maior da Europa.", en = "A city of banks and trade fairs on the Main; its central station, from 1888, was Europe's largest." } },
		stuttgart = { nome = "Stuttgart", nomeEn = nil, pos = Vector2.new(995.4, 777.3), lon = 9.18, lat = 48.78, porte = 3, produz = nil, porto = false, paisagem = nil, estado = "Alemanha", regiao = "c", historia = { pt = "Capital de Württemberg, num vale cercado de colinas e vinhedos.", en = "Capital of Württemberg, in a valley ringed by hills and vineyards." } },
		wroclaw = { nome = "Breslávia", nomeEn = "Wrocław", pos = Vector2.new(1257.1, 643.1), lon = 17.04, lat = 51.11, porte = 3, produz = "carvao", porto = false, paisagem = nil, estado = "Polônia", regiao = "c", historia = { pt = "Grande cidade da Silésia, no rio Óder, ligada a Berlim em 1846.", en = "A great Silesian city on the Oder, linked to Berlin in 1846." } },
		praha = { nome = "Praga", nomeEn = "Prague", pos = Vector2.new(1173.8, 704.3), lon = 14.42, lat = 50.08, porte = 4, produz = nil, porto = false, paisagem = nil, estado = "Tchéquia", regiao = "c", historia = { pt = "A cidade das cem torres, capital da Boêmia, à beira do rio Moldava.", en = "The city of a hundred spires, capital of Bohemia, on the Vltava." } },
		linz = { nome = "Linz", nomeEn = nil, pos = Vector2.new(1174.7, 797.9), lon = 14.29, lat = 48.31, porte = 2, produz = "aco", porto = false, paisagem = "eur_industria", estado = "Áustria", regiao = "c", historia = { pt = "Cidade do Danúbio onde passou, em 1832, uma das primeiras ferrovias do continente, puxada a cavalo.", en = "A Danube city where one of the continent's first railways, horse-drawn, passed in 1832." } },
		salzburg = { nome = "Salzburgo", nomeEn = "Salzburg", pos = Vector2.new(1131.9, 827.0), lon = 13.04, lat = 47.8, porte = 2, produz = nil, porto = false, paisagem = "eur_alpes", estado = "Áustria", regiao = "c", historia = { pt = "A cidade de Mozart, ao pé dos Alpes, na fronteira com a Baviera.", en = "Mozart's city, at the foot of the Alps, on the border with Bavaria." } },
		malmo = { nome = "Malmö", nomeEn = nil, pos = Vector2.new(1113.5, 414.8), lon = 13, lat = 55.61, porte = 3, produz = "graos", porto = true, paisagem = nil, estado = "Suécia", regiao = "n", historia = { pt = "Porto do sul da Suécia, de frente para Copenhague, do outro lado do estreito.", en = "A port in southern Sweden, facing Copenhagen across the strait." } },
		oslo = { nome = "Oslo", nomeEn = nil, pos = Vector2.new(1043.9, 189.8), lon = 10.75, lat = 59.91, porte = 4, produz = "madeira", porto = true, paisagem = nil, estado = "Noruega", regiao = "n", historia = { pt = "Capital da Noruega, no fundo de um fiorde; a primeira ferrovia norueguesa saiu daqui em 1854.", en = "Norway's capital, at the head of a fjord; the first Norwegian railway left from here in 1854." } },
		bergen = { nome = "Bergen", nomeEn = nil, pos = Vector2.new(901.6, 160.5), lon = 5.32, lat = 60.39, porte = 3, produz = nil, porto = true, paisagem = nil, estado = "Noruega", regiao = "n", historia = { pt = "O porto dos fiordes do oeste, ligado a Oslo por uma ferrovia que cruza o planalto gelado.", en = "The port of the western fjords, linked to Oslo by a railway across the frozen plateau." } },
		genova = { nome = "Gênova", nomeEn = "Genoa", pos = Vector2.new(983.5, 1007.7), lon = 8.93, lat = 44.41, porte = 3, produz = nil, porto = true, paisagem = nil, estado = "Itália", regiao = "s", historia = { pt = "O grande porto da Itália, apertado entre o mar e os Apeninos.", en = "Italy's great port, squeezed between the sea and the Apennines." } },
		bologna = { nome = "Bolonha", nomeEn = "Bologna", pos = Vector2.new(1074.6, 1003.4), lon = 11.34, lat = 44.49, porte = 3, produz = nil, porto = false, paisagem = nil, estado = "Itália", regiao = "s", historia = { pt = "Cidade da universidade mais antiga do mundo e grande entroncamento das ferrovias italianas.", en = "City of the world's oldest university and a great junction of Italian railways." } },
		firenze = { nome = "Florença", nomeEn = "Florence", pos = Vector2.new(1071.8, 1041.4), lon = 11.25, lat = 43.77, porte = 4, produz = nil, porto = false, paisagem = nil, estado = "Itália", regiao = "s", historia = { pt = "O berço do Renascimento, no rio Arno; foi capital da Itália de 1865 a 1871.", en = "The cradle of the Renaissance, on the Arno; Italy's capital from 1865 to 1871." } },
		valencia = { nome = "Valência", nomeEn = "Valencia", pos = Vector2.new(599.7, 1238.9), lon = -0.38, lat = 39.47, porte = 4, produz = nil, porto = true, paisagem = nil, estado = "Espanha", regiao = "s", historia = { pt = "Cidade das laranjas e do arroz, no Mediterrâneo; seu primeiro trem, de 1852, ia até o porto do Grau.", en = "City of oranges and rice on the Mediterranean; its first train, in 1852, ran to the port of Grau." } },
		cordoba = { nome = "Córdoba", nomeEn = nil, pos = Vector2.new(407.5, 1290.9), lon = -4.78, lat = 37.89, porte = 2, produz = nil, porto = false, paisagem = "eur_mediterraneo", estado = "Espanha", regiao = "s", historia = { pt = "Cidade da grande mesquita, no vale do Guadalquivir.", en = "City of the great mosque, in the Guadalquivir valley." } },
		sevilla = { nome = "Sevilha", nomeEn = "Seville", pos = Vector2.new(352.9, 1306.5), lon = -5.99, lat = 37.39, porte = 4, produz = nil, porto = true, paisagem = nil, estado = "Espanha", regiao = "s", historia = { pt = "Capital da Andaluzia e antigo porto das Américas, no rio Guadalquivir.", en = "Capital of Andalusia and the old port for the Americas, on the Guadalquivir." } },
		badajoz = { nome = "Badajoz", nomeEn = nil, pos = Vector2.new(328.1, 1220.8), lon = -6.97, lat = 38.88, porte = 1, produz = nil, porto = false, paisagem = "eur_campo", estado = "Espanha", regiao = "s", historia = { pt = "Cidade da fronteira, onde a linha de Lisboa entrava na Espanha.", en = "A border town where the line from Lisbon entered Spain." } },
		skopje = { nome = "Skopje", nomeEn = nil, pos = Vector2.new(1472.5, 1100.8), lon = 21.43, lat = 42, porte = 2, produz = nil, porto = false, paisagem = "eur_mediterraneo", estado = "Macedônia do Norte", regiao = "l", historia = { pt = "Cidade do vale do Vardar, no caminho dos trens de Belgrado para o mar Egeu.", en = "A city in the Vardar valley, on the way of trains from Belgrade to the Aegean." } },
		thessaloniki = { nome = "Salônica", nomeEn = "Thessaloniki", pos = Vector2.new(1542.4, 1162.0), lon = 22.94, lat = 40.64, porte = 3, produz = nil, porto = true, paisagem = nil, estado = "Grécia", regiao = "l", historia = { pt = "O porto do norte da Grécia, que recebia os trens do Expresso do Oriente vindos de Belgrado.", en = "Northern Greece's port, which received Orient Express trains from Belgrade." } },
		athina = { nome = "Atenas", nomeEn = "Athens", pos = Vector2.new(1596.5, 1294.5), lon = 23.73, lat = 37.98, porte = 4, produz = nil, porto = true, paisagem = nil, estado = "Grécia", regiao = "l", historia = { pt = "A capital grega; a primeira ferrovia do país, de 1869, ligava Atenas ao porto do Pireu.", en = "The Greek capital; the country's first railway, in 1869, linked Athens to the port of Piraeus." } },
		bucuresti = { nome = "Bucareste", nomeEn = "Bucharest", pos = Vector2.new(1627.3, 941.5), lon = 26.1, lat = 44.43, porte = 4, produz = "graos", porto = false, paisagem = nil, estado = "Romênia", regiao = "l", historia = { pt = "A \"pequena Paris\" do Leste, capital da Romênia, no meio das planícies de trigo.", en = "The \"Little Paris\" of the East, Romania's capital, amid the wheat plains." } },
		constanta = { nome = "Constança", nomeEn = "Constanța", pos = Vector2.new(1723.1, 932.2), lon = 28.63, lat = 44.18, porte = 2, produz = nil, porto = true, paisagem = "eur_costa", estado = "Romênia", regiao = "l", historia = { pt = "O porto romeno no Mar Negro; a ponte de Cernavodă levou o trem até aqui em 1895.", en = "Romania's Black Sea port; the Cernavodă bridge brought the train here in 1895." } },
	},
	foco = { min = Vector2.new(617.8, 444.4), max = Vector2.new(692.2, 610.1) },
	regioes = {
		o = { pt = "Europa Ocidental", en = "Western Europe" },
		c = { pt = "Europa Central", en = "Central Europe" },
		s = { pt = "Sul da Europa", en = "Southern Europe" },
		l = { pt = "Bálcãs", en = "Balkans" },
		n = { pt = "Norte e Báltico", en = "North and Baltic" },
	},
	linhas = {
		{
			id = "stockton_darlington", nome = "Stockton and Darlington", nomeEn = nil, ano = 1825, cor = 2, ordem = 1, degrau = 0, projeto = nil, nota = { pt = "Em 27 de setembro de 1825, a Locomotion nº 1 de George Stephenson puxou o primeiro trem a vapor público do mundo.", en = "On 27 September 1825, George Stephenson's Locomotion No. 1 pulled the world's first public steam train." },
			trechos = {
				{ id = "stockton_darlington_1", de = "darlington", para = "stockton", ano = 1825, km = 20, terreno = "planicie", custo = 120, degrau = 0 },
			},
		},
		{
			id = "liverpool_manchester", nome = "Liverpool and Manchester", nomeEn = nil, ano = 1830, cor = 6, ordem = 2, degrau = 0, projeto = nil, nota = { pt = "A primeira ferrovia interurbana do mundo, só com trens a vapor e horário fixo. A Rocket venceu o concurso de locomotivas de Rainhill.", en = "The world's first intercity railway, with only steam trains and a timetable. The Rocket won the Rainhill locomotive trials." },
			trechos = {
				{ id = "liverpool_manchester_1", de = "liverpool", para = "manchester", ano = 1830, km = 62, terreno = "planicie", custo = 372, degrau = 0 },
			},
		},
		{
			id = "belgica", nome = "Ferrovias do Estado Belga", nomeEn = "Belgian State Railways", ano = 1836, cor = 3, ordem = 3, degrau = 1, projeto = nil, nota = { pt = "A Bélgica, recém-independente, foi o primeiro país a planejar uma rede nacional, com Mechelen no centro.", en = "Newly independent Belgium was the first country to plan a national network, with Mechelen at its centre." },
			trechos = {
				{ id = "belgica_1", de = "bruxelles", para = "antwerpen", ano = 1836, km = 52, terreno = "planicie", custo = 749, degrau = 1 },
			},
		},
		{
			id = "grand_junction", nome = "Grand Junction", nomeEn = nil, ano = 1837, cor = 5, ordem = 4, degrau = 1, projeto = nil, nota = { pt = "Ligou Birmingham ao noroeste e fez de Crewe, um vilarejo, um dos maiores entroncamentos ferroviários do mundo.", en = "It linked Birmingham to the north-west and turned the village of Crewe into one of the world's great railway junctions." },
			trechos = {
				{ id = "grand_junction_1", de = "birmingham", para = "crewe", ano = 1837, km = 97, terreno = "planicie", custo = 1397, degrau = 1 },
				{ id = "grand_junction_2", de = "crewe", para = "manchester", ano = 1842, km = 55, terreno = "planicie", custo = 792, degrau = 1 },
			},
		},
		{
			id = "london_birmingham", nome = "London and Birmingham", nomeEn = nil, ano = 1838, cor = 1, ordem = 5, degrau = 1, projeto = nil, nota = { pt = "A primeira grande linha saindo de Londres, construída por Robert Stephenson, com o arco de Euston na entrada.", en = "The first great main line out of London, built by Robert Stephenson, with the Euston Arch at its gate." },
			trechos = {
				{ id = "london_birmingham_1", de = "london", para = "birmingham", ano = 1838, km = 203, terreno = "colinas", custo = 4092, degrau = 1 },
			},
		},
		{
			id = "leipzig_dresden", nome = "Leipzig–Dresden", nomeEn = nil, ano = 1839, cor = 4, ordem = 6, degrau = 1, projeto = nil, nota = { pt = "A primeira ferrovia de longa distância da Alemanha, com o primeiro túnel ferroviário do país.", en = "Germany's first long-distance railway, with the country's first railway tunnel." },
			trechos = {
				{ id = "leipzig_dresden_1", de = "leipzig", para = "dresden", ano = 1839, km = 126, terreno = "colinas", custo = 2540, degrau = 1 },
			},
		},
		{
			id = "nordbahn", nome = "Kaiser Ferdinands-Nordbahn", nomeEn = nil, ano = 1839, cor = 2, ordem = 7, degrau = 2, projeto = nil, nota = { pt = "A primeira ferrovia a vapor da Áustria, financiada pelos Rothschild, levava o carvão e o sal da Galícia para Viena.", en = "Austria's first steam railway, funded by the Rothschilds, carried coal and salt from Galicia to Vienna." },
			trechos = {
				{ id = "nordbahn_1", de = "wien", para = "brno", ano = 1839, km = 139, terreno = "planicie", custo = 4804, degrau = 2 },
				{ id = "nordbahn_2", de = "brno", para = "krakow", ano = 1856, km = 323, terreno = "colinas", custo = 15628, degrau = 2 },
			},
		},
		{
			id = "hijs", nome = "Hollandsche IJzeren Spoorweg", nomeEn = nil, ano = 1839, cor = 6, ordem = 8, degrau = 2, projeto = nil, nota = { pt = "A primeira ferrovia holandesa começou com a locomotiva De Arend, entre Amsterdã e Haarlem, em 1839.", en = "The first Dutch railway began with the De Arend locomotive, between Amsterdam and Haarlem, in 1839." },
			trechos = {
				{ id = "hijs_1", de = "amsterdam", para = "rotterdam", ano = 1847, km = 72, terreno = "planicie", custo = 2488, degrau = 2 },
			},
		},
		{
			id = "great_western", nome = "Great Western", nomeEn = nil, ano = 1841, cor = 7, ordem = 9, degrau = 2, projeto = nil, nota = { pt = "Isambard Kingdom Brunel a construiu em bitola larga, com o túnel de Box e trens que chegavam a 100 km/h.", en = "Isambard Kingdom Brunel built it on broad gauge, with the Box Tunnel and trains that reached 100 km/h." },
			trechos = {
				{ id = "great_western_1", de = "london", para = "reading", ano = 1840, km = 73, terreno = "vale", custo = 3027, degrau = 2 },
				{ id = "great_western_2", de = "reading", para = "bristol", ano = 1841, km = 140, terreno = "colinas", custo = 6774, degrau = 2 },
			},
		},
		{
			id = "edinburgh_glasgow", nome = "Edinburgh and Glasgow", nomeEn = nil, ano = 1842, cor = 3, ordem = 10, degrau = 1, projeto = nil, nota = { pt = "Ligou as duas maiores cidades da Escócia em 1842, quase em linha reta, com o viaduto do Almond.", en = "It linked Scotland's two largest cities in 1842, almost in a straight line, with the Almond viaduct." },
			trechos = {
				{ id = "edinburgh_glasgow_1", de = "edinburgh", para = "glasgow", ano = 1842, km = 84, terreno = "planicie", custo = 1210, degrau = 1 },
			},
		},
		{
			id = "paris_rouen", nome = "Paris–Rouen–Le Havre", nomeEn = nil, ano = 1843, cor = 8, ordem = 11, degrau = 2, projeto = nil, nota = { pt = "Construída com dinheiro e operários ingleses, levou Paris até o mar pelo vale do Sena.", en = "Built with English money and navvies, it took Paris to the sea along the Seine valley." },
			trechos = {
				{ id = "paris_rouen_1", de = "paris", para = "rouen", ano = 1843, km = 139, terreno = "vale", custo = 5765, degrau = 2 },
				{ id = "paris_rouen_2", de = "rouen", para = "le_havre", ano = 1847, km = 90, terreno = "costa", custo = 3421, degrau = 2 },
			},
		},
		{
			id = "liege_koln", nome = "Bruxelas–Liège–Colônia", nomeEn = "Brussels–Liège–Cologne", ano = 1843, cor = 8, ordem = 12, degrau = 2, projeto = nil, nota = { pt = "A primeira ferrovia internacional da Europa: subia o planalto de Liège com cabos e cruzava a fronteira em Aachen.", en = "Europe's first international railway: it climbed the Liège plateau by cable and crossed the border at Aachen." },
			trechos = {
				{ id = "liege_koln_1", de = "bruxelles", para = "liege", ano = 1842, km = 112, terreno = "planicie", custo = 3871, degrau = 2 },
				{ id = "liege_koln_2", de = "liege", para = "koln", ano = 1843, km = 130, terreno = "colinas", custo = 6290, degrau = 2, via = { Vector2.new(893.1, 668.3) } },
			},
		},
		{
			id = "nord", nome = "Chemin de fer du Nord", nomeEn = nil, ano = 1846, cor = 1, ordem = 13, degrau = 3, projeto = nil, nota = { pt = "A companhia dos Rothschild ligou Paris ao norte industrial e à Bélgica.", en = "The Rothschilds' company linked Paris to the industrial north and to Belgium." },
			trechos = {
				{ id = "nord_1", de = "paris", para = "lille", ano = 1846, km = 254, terreno = "planicie", custo = 21068, degrau = 3 },
				{ id = "nord_2", de = "lille", para = "bruxelles", ano = 1846, km = 118, terreno = "planicie", custo = 9787, degrau = 3 },
			},
		},
		{
			id = "berlin_hamburg", nome = "Berlim–Hamburgo", nomeEn = "Berlin–Hamburg", ano = 1846, cor = 5, ordem = 14, degrau = 3, projeto = nil, nota = { pt = "Ligou a capital prussiana ao maior porto alemão pela planície do norte.", en = "It linked the Prussian capital to Germany's largest port across the northern plain." },
			trechos = {
				{ id = "berlin_hamburg_1", de = "berlin", para = "hamburg", ano = 1846, km = 319, terreno = "planicie", custo = 26459, degrau = 3 },
			},
		},
		{
			id = "berlin_breslau", nome = "Niederschlesisch-Märkische", nomeEn = nil, ano = 1846, cor = 6, ordem = 15, degrau = 2, projeto = nil, nota = { pt = "Ligou Berlim à Silésia e ao seu carvão; foi estatizada pela Prússia em 1852.", en = "It linked Berlin to Silesia and its coal; Prussia took it over in 1852." },
			trechos = {
				{ id = "berlin_breslau_1", de = "berlin", para = "wroclaw", ano = 1846, km = 378, terreno = "planicie", custo = 13064, degrau = 2, via = { Vector2.new(1170.7, 584.8), Vector2.new(1203.9, 616.4) } },
			},
		},
		{
			id = "koln_minden", nome = "Köln-Mindener", nomeEn = nil, ano = 1847, cor = 4, ordem = 16, degrau = 3, projeto = nil, nota = { pt = "Atravessou o Vale do Ruhr e transformou as minas de carvão no coração industrial da Alemanha.", en = "It crossed the Ruhr Valley and turned the coal mines into Germany's industrial heart." },
			trechos = {
				{ id = "koln_minden_1", de = "koln", para = "essen", ano = 1847, km = 72, terreno = "planicie", custo = 5972, degrau = 3 },
				{ id = "koln_minden_2", de = "essen", para = "hannover", ano = 1847, km = 265, terreno = "planicie", custo = 21980, degrau = 3 },
			},
		},
		{
			id = "west_coast", nome = "West Coast Main Line", nomeEn = nil, ano = 1848, cor = 1, ordem = 17, degrau = 4, projeto = nil, nota = { pt = "Subia a rampa de Shap e cruzava a fronteira escocesa: na \"corrida para o norte\" de 1895, trens disputavam quem chegava primeiro.", en = "It climbed Shap and crossed the Scottish border: in the 1895 \"Race to the North\", trains competed to arrive first." },
			trechos = {
				{ id = "west_coast_1", de = "crewe", para = "carlisle", ano = 1846, km = 257, terreno = "colinas", custo = 71624, degrau = 4, via = { Vector2.new(629.7, 479.6), Vector2.new(629.4, 464.0), Vector2.new(637.5, 439.6) } },
				{ id = "west_coast_2", de = "carlisle", para = "glasgow", ano = 1848, km = 170, terreno = "colinas", custo = 47378, degrau = 4 },
			},
		},
		{
			id = "east_coast", nome = "East Coast Main Line", nomeEn = nil, ano = 1850, cor = 7, ordem = 18, degrau = 4, projeto = nil, nota = { pt = "A linha do Flying Scotsman, entre Londres e Edimburgo; a Mallard bateu aqui o recorde mundial do vapor, 203 km/h.", en = "The Flying Scotsman's line between London and Edinburgh; Mallard set the world steam record here, 203 km/h." },
			trechos = {
				{ id = "east_coast_1", de = "london", para = "york", ano = 1850, km = 350, terreno = "planicie", custo = 69673, degrau = 4 },
				{ id = "east_coast_2", de = "york", para = "newcastle", ano = 1850, km = 147, terreno = "planicie", custo = 29263, degrau = 4 },
				{ id = "east_coast_3", de = "newcastle", para = "edinburgh", ano = 1850, km = 185, terreno = "costa", custo = 40510, degrau = 4 },
			},
		},
		{
			id = "praga", nome = "Dresden–Praga–Brno", nomeEn = "Dresden–Prague–Brno", ano = 1851, cor = 7, ordem = 19, degrau = 3, projeto = nil, nota = { pt = "A Ferrovia Estatal do Norte ligou Viena a Praga e desceu o vale do Elba até a Saxônia.", en = "The Northern State Railway linked Vienna to Prague and went down the Elbe valley to Saxony." },
			trechos = {
				{ id = "praga_1", de = "dresden", para = "praha", ano = 1851, km = 155, terreno = "vale", custo = 15428, degrau = 3, via = { Vector2.new(1164.5, 667.8) } },
				{ id = "praga_2", de = "praha", para = "brno", ano = 1849, km = 282, terreno = "colinas", custo = 32746, degrau = 3, via = { Vector2.new(1219.9, 703.2), Vector2.new(1242.8, 708.7) } },
			},
		},
		{
			id = "est", nome = "Chemin de fer de l'Est", nomeEn = nil, ano = 1852, cor = 2, ordem = 20, degrau = 3, projeto = nil, nota = { pt = "A linha de Paris a Estrasburgo, pelo vale do Marne e pela Lorena, saindo da Gare de l'Est.", en = "The line from Paris to Strasbourg, through the Marne valley and Lorraine, from the Gare de l'Est." },
			trechos = {
				{ id = "est_1", de = "paris", para = "nancy", ano = 1852, km = 356, terreno = "planicie", custo = 29528, degrau = 3, via = { Vector2.new(828.5, 760.4), Vector2.new(855.6, 772.4) } },
				{ id = "est_2", de = "nancy", para = "strasbourg", ano = 1852, km = 145, terreno = "colinas", custo = 16838, degrau = 3 },
			},
		},
		{
			id = "paris_orleans", nome = "Paris–Orléans–Bordéus", nomeEn = "Paris–Orléans–Bordeaux", ano = 1853, cor = 4, ordem = 21, degrau = 2, projeto = nil, nota = { pt = "A companhia Paris–Orléans levou os trens de Paris ao vale do Loire e, depois, ao porto do vinho em Bordéus.", en = "The Paris–Orléans company took trains from Paris to the Loire valley and then to the wine port of Bordeaux." },
			trechos = {
				{ id = "paris_orleans_1", de = "paris", para = "orleans", ano = 1843, km = 139, terreno = "planicie", custo = 4804, degrau = 2 },
				{ id = "paris_orleans_2", de = "orleans", para = "bordeaux", ano = 1853, km = 516, terreno = "planicie", custo = 17833, degrau = 2, via = { Vector2.new(691.8, 829.9), Vector2.new(674.0, 870.7), Vector2.new(661.3, 918.6) } },
			},
		},
		{
			id = "giovi", nome = "Turim–Gênova (Giovi)", nomeEn = "Turin–Genoa (Giovi)", ano = 1853, cor = 6, ordem = 22, degrau = 4, projeto = nil, nota = { pt = "O reino do Piemonte cruzou os Apeninos pela rampa dos Giovi para levar o porto de Gênova até Turim.", en = "The Kingdom of Piedmont crossed the Apennines by the Giovi incline to bring the port of Genoa to Turin." },
			trechos = {
				{ id = "giovi_1", de = "torino", para = "genova", ano = 1853, km = 169, terreno = "montanhas", custo = 67284, degrau = 4, via = { Vector2.new(971.9, 981.2) } },
			},
		},
		{
			id = "wurttemberg", nome = "Frankfurt–Stuttgart–Munique", nomeEn = "Frankfurt–Stuttgart–Munich", ano = 1854, cor = 1, ordem = 23, degrau = 5, projeto = nil, nota = { pt = "A rampa de Geislingen, de 1850, subia o Jura da Suábia com locomotivas empurrando atrás.", en = "The Geislingen incline, from 1850, climbed the Swabian Jura with banking locomotives pushing behind." },
			trechos = {
				{ id = "wurttemberg_1", de = "frankfurt", para = "stuttgart", ano = 1846, km = 196, terreno = "colinas", custo = 131097, degrau = 5, via = { Vector2.new(979.0, 744.3) } },
				{ id = "wurttemberg_2", de = "stuttgart", para = "munchen", ano = 1854, km = 246, terreno = "montanhas", custo = 235057, degrau = 5, via = { Vector2.new(1023.6, 797.5), Vector2.new(1055.6, 798.9) } },
			},
		},
		{
			id = "plm", nome = "Paris–Lyon–Méditerranée", nomeEn = nil, ano = 1857, cor = 3, ordem = 24, degrau = 3, projeto = nil, nota = { pt = "A \"linha imperial\", que levava Paris ao Mediterrâneo pelo vale do Ródano.", en = "The \"imperial line\", which took Paris to the Mediterranean down the Rhône valley." },
			trechos = {
				{ id = "plm_1", de = "paris", para = "dijon", ano = 1851, km = 329, terreno = "colinas", custo = 38204, degrau = 3 },
				{ id = "plm_2", de = "dijon", para = "lyon", ano = 1854, km = 218, terreno = "vale", custo = 21698, degrau = 3 },
				{ id = "plm_3", de = "lyon", para = "marseille", ano = 1856, km = 346, terreno = "vale", custo = 34438, degrau = 3 },
			},
		},
		{
			id = "sudbahn", nome = "Südbahn (Semmering)", nomeEn = nil, ano = 1857, cor = 8, ordem = 25, degrau = 4, projeto = nil, nota = { pt = "A ferrovia do Semmering, de 1854, foi a primeira a cruzar uma cordilheira dos Alpes. Hoje é Patrimônio da Humanidade.", en = "The Semmering railway, from 1854, was the first to cross an Alpine range. It is now a World Heritage Site." },
			trechos = {
				{ id = "sudbahn_1", de = "wien", para = "graz", ano = 1854, km = 181, terreno = "alpes", custo = 93680, degrau = 4 },
				{ id = "sudbahn_2", de = "graz", para = "ljubljana", ano = 1849, km = 166, terreno = "colinas", custo = 46263, degrau = 4 },
				{ id = "sudbahn_3", de = "ljubljana", para = "trieste", ano = 1857, km = 91, terreno = "montanhas", custo = 36230, degrau = 4 },
			},
		},
		{
			id = "lombardo_veneta", nome = "Turim–Milão–Veneza", nomeEn = "Turin–Milan–Venice", ano = 1857, cor = 1, ordem = 26, degrau = 5, projeto = nil, nota = { pt = "A ferrovia da planície do Pó; a ponte da laguna, de 1846, levou o trem até Veneza.", en = "The Po plain railway; the lagoon bridge of 1846 brought the train into Venice." },
			trechos = {
				{ id = "lombardo_veneta_1", de = "torino", para = "milano", ano = 1859, km = 156, terreno = "planicie", custo = 74530, degrau = 5 },
				{ id = "lombardo_veneta_2", de = "milano", para = "venezia", ano = 1857, km = 305, terreno = "planicie", custo = 145716, degrau = 5 },
			},
		},
		{
			id = "midi", nome = "Chemin de fer du Midi", nomeEn = nil, ano = 1858, cor = 7, ordem = 27, degrau = 5, projeto = nil, nota = { pt = "Os irmãos Pereire ligaram o Atlântico ao Mediterrâneo ao lado do Canal du Midi.", en = "The Pereire brothers linked the Atlantic to the Mediterranean alongside the Canal du Midi." },
			trechos = {
				{ id = "midi_1", de = "bordeaux", para = "toulouse", ano = 1856, km = 266, terreno = "vale", custo = 152500, degrau = 5, via = { Vector2.new(669.0, 996.8) } },
				{ id = "midi_2", de = "toulouse", para = "montpellier", ano = 1857, km = 276, terreno = "planicie", custo = 131861, degrau = 5, via = { Vector2.new(754.0, 1060.2), Vector2.new(763.2, 1052.6) } },
				{ id = "midi_3", de = "montpellier", para = "marseille", ano = 1858, km = 184, terreno = "costa", custo = 96698, degrau = 5, via = { Vector2.new(808.8, 1030.0), Vector2.new(818.5, 1039.1) } },
			},
		},
		{
			id = "reno", nome = "Ferrovia do Vale do Reno", nomeEn = "Rhine Valley Railway", ano = 1859, cor = 5, ordem = 28, degrau = 3, projeto = nil, nota = { pt = "Segue as curvas do Reno entre castelos, vinhedos e o rochedo de Lorelei.", en = "It follows the bends of the Rhine past castles, vineyards and the Lorelei rock." },
			trechos = {
				{ id = "reno_1", de = "koln", para = "koblenz", ano = 1858, km = 98, terreno = "vale", custo = 9754, degrau = 3 },
				{ id = "reno_2", de = "koblenz", para = "frankfurt", ano = 1859, km = 127, terreno = "vale", custo = 12641, degrau = 3, via = { Vector2.new(947.8, 706.6), Vector2.new(965.3, 712.3) } },
			},
		},
		{
			id = "westbahn", nome = "Westbahn", nomeEn = nil, ano = 1860, cor = 3, ordem = 29, degrau = 4, projeto = nil, nota = { pt = "A Ferrovia da Imperatriz Elisabeth levou os trens de Viena, pelo vale do Danúbio, até a fronteira da Baviera.", en = "The Empress Elisabeth Railway took trains from Vienna, along the Danube valley, to the Bavarian border." },
			trechos = {
				{ id = "westbahn_1", de = "wien", para = "linz", ano = 1858, km = 193, terreno = "colinas", custo = 53788, degrau = 4 },
				{ id = "westbahn_2", de = "linz", para = "salzburg", ano = 1860, km = 136, terreno = "colinas", custo = 37902, degrau = 4 },
			},
		},
		{
			id = "suecia", nome = "Västra stambanan", nomeEn = nil, ano = 1862, cor = 6, ordem = 30, degrau = 6, projeto = nil, nota = { pt = "A linha principal do oeste da Suécia, construída pelo Estado para ligar a capital ao Mar do Norte.", en = "Sweden's western main line, built by the state to link the capital to the North Sea." },
			trechos = {
				{ id = "suecia_1", de = "stockholm", para = "goteborg", ano = 1862, km = 496, terreno = "colinas", custo = 796211, degrau = 6 },
			},
		},
		{
			id = "madrid_barcelona", nome = "Madri–Saragoça–Barcelona", nomeEn = "Madrid–Zaragoza–Barcelona", ano = 1863, cor = 2, ordem = 31, degrau = 4, projeto = nil, nota = { pt = "Ligou a capital ao porto e à indústria da Catalunha, em bitola larga ibérica.", en = "It linked the capital to the port and industry of Catalonia, on broad Iberian gauge." },
			trechos = {
				{ id = "madrid_barcelona_1", de = "barcelona", para = "zaragoza", ano = 1861, km = 319, terreno = "colinas", custo = 88903, degrau = 4 },
				{ id = "madrid_barcelona_2", de = "zaragoza", para = "madrid", ano = 1863, km = 342, terreno = "colinas", custo = 95313, degrau = 4 },
			},
		},
		{
			id = "roma_napoli", nome = "Roma–Nápoles", nomeEn = "Rome–Naples", ano = 1863, cor = 3, ordem = 32, degrau = 5, projeto = nil, nota = { pt = "Ligou a cidade dos papas ao maior porto do sul da Itália, logo depois da unificação.", en = "It linked the city of the popes to southern Italy's largest port, right after unification." },
			trechos = {
				{ id = "roma_napoli_1", de = "roma", para = "napoli", ano = 1863, km = 235, terreno = "colinas", custo = 157182, degrau = 5 },
			},
		},
		{
			id = "lisboa_porto", nome = "Linha do Norte", nomeEn = "Northern Line (Portugal)", ano = 1864, cor = 6, ordem = 33, degrau = 4, projeto = nil, nota = { pt = "A espinha dorsal de Portugal; a ponte Maria Pia, de Eiffel, levou os trens até o Porto em 1877.", en = "Portugal's backbone; Eiffel's Maria Pia bridge carried the trains into Porto in 1877." },
			trechos = {
				{ id = "lisboa_porto_1", de = "lisboa", para = "coimbra", ano = 1864, km = 221, terreno = "costa", custo = 48393, degrau = 4 },
				{ id = "lisboa_porto_2", de = "coimbra", para = "porto", ano = 1864, km = 132, terreno = "colinas", custo = 36787, degrau = 4 },
			},
		},
		{
			id = "norte_espana", nome = "Caminhos de Ferro do Norte", nomeEn = "Northern Railway of Spain", ano = 1864, cor = 5, ordem = 34, degrau = 5, projeto = nil, nota = { pt = "Subia a meseta castelhana e descia até o País Basco, de onde saía o minério de ferro.", en = "It climbed the Castilian plateau and came down to the Basque Country, where iron ore was shipped." },
			trechos = {
				{ id = "norte_espana_1", de = "madrid", para = "valladolid", ano = 1860, km = 202, terreno = "colinas", custo = 135110, degrau = 5 },
				{ id = "norte_espana_2", de = "valladolid", para = "burgos", ano = 1860, km = 142, terreno = "planicie", custo = 67842, degrau = 5 },
				{ id = "norte_espana_3", de = "burgos", para = "bilbao", ano = 1863, km = 150, terreno = "montanhas", custo = 143327, degrau = 5 },
			},
		},
		{
			id = "sodra", nome = "Södra stambanan", nomeEn = nil, ano = 1864, cor = 3, ordem = 35, degrau = 6, projeto = nil, nota = { pt = "A linha principal do sul da Suécia, construída pelo Estado entre florestas e lagos até o estreito de Öresund.", en = "Sweden's southern main line, built by the state through forests and lakes to the Øresund strait." },
			trechos = {
				{ id = "sodra_1", de = "stockholm", para = "malmo", ano = 1864, km = 656, terreno = "colinas", custo = 1053054, degrau = 6, via = { Vector2.new(1194.2, 252.0), Vector2.new(1156.6, 304.7), Vector2.new(1134.9, 384.8) } },
			},
		},
		{
			id = "mza", nome = "Madri–Córdoba–Sevilha", nomeEn = "Madrid–Córdoba–Seville", ano = 1866, cor = 8, ordem = 36, degrau = 5, projeto = nil, nota = { pt = "A companhia MZA desceu da meseta para a Andaluzia pelo desfiladeiro de Despeñaperros.", en = "The MZA company came down from the plateau into Andalusia through the Despeñaperros gorge." },
			trechos = {
				{ id = "mza_1", de = "madrid", para = "cordoba", ano = 1866, km = 370, terreno = "montanhas", custo = 353541, degrau = 5 },
				{ id = "mza_2", de = "cordoba", para = "sevilla", ano = 1859, km = 150, terreno = "vale", custo = 85996, degrau = 5 },
			},
		},
		{
			id = "leste", nome = "Lisboa–Badajoz–Madri", nomeEn = "Lisbon–Badajoz–Madrid", ano = 1866, cor = 2, ordem = 37, degrau = 6, projeto = nil, nota = { pt = "A Linha do Leste saiu de Lisboa pelo vale do Tejo e encontrou a ferrovia espanhola em Badajoz.", en = "The Eastern Line left Lisbon up the Tagus valley and met the Spanish railway at Badajoz." },
			trechos = {
				{ id = "leste_1", de = "lisboa", para = "badajoz", ano = 1863, km = 266, terreno = "planicie", custo = 305000, degrau = 6, via = { Vector2.new(240.9, 1203.9), Vector2.new(247.8, 1196.4), Vector2.new(277.8, 1194.2) } },
				{ id = "leste_2", de = "badajoz", para = "madrid", ano = 1866, km = 410, terreno = "colinas", custo = 658159, degrau = 6 },
			},
		},
		{
			id = "brenner", nome = "Ferrovia do Brenner", nomeEn = "Brenner Railway", ano = 1867, cor = 7, ordem = 38, degrau = 6, projeto = nil, nota = { pt = "A primeira ferrovia a cruzar os Alpes por cima, pelo Passo do Brenner, sem túnel de cume.", en = "The first railway over the Alps, through the Brenner Pass, without a summit tunnel." },
			trechos = {
				{ id = "brenner_1", de = "munchen", para = "innsbruck", ano = 1858, km = 122, terreno = "vale", custo = 167865, degrau = 6 },
				{ id = "brenner_2", de = "innsbruck", para = "verona", ano = 1867, km = 257, terreno = "alpes", custo = 766170, degrau = 6 },
			},
		},
		{
			id = "barcelona_valencia", nome = "Barcelona–Valência", nomeEn = "Barcelona–Valencia", ano = 1868, cor = 5, ordem = 39, degrau = 6, projeto = nil, nota = { pt = "A linha do Mediterrâneo espanhol, entre laranjais, vinhedos e o delta do Ebro.", en = "The Spanish Mediterranean line, among orange groves, vineyards and the Ebro delta." },
			trechos = {
				{ id = "barcelona_valencia_1", de = "barcelona", para = "valencia", ano = 1868, km = 403, terreno = "costa", custo = 508296, degrau = 6, via = { Vector2.new(675.1, 1161.0), Vector2.new(662.8, 1163.3), Vector2.new(647.9, 1170.4), Vector2.new(634.2, 1183.6), Vector2.new(616.8, 1213.6) } },
			},
		},
		{
			id = "varsovia", nome = "Berlim–Varsóvia", nomeEn = "Berlin–Warsaw", ano = 1870, cor = 1, ordem = 40, degrau = 7, projeto = nil, nota = { pt = "A ligação entre Berlim e Varsóvia pela planície do norte, depois parte do Expresso Nord.", en = "The link between Berlin and Warsaw across the northern plain, later part of the Nord Express." },
			trechos = {
				{ id = "varsovia_1", de = "berlin", para = "poznan", ano = 1870, km = 299, terreno = "planicie", custo = 822813, degrau = 7 },
				{ id = "varsovia_2", de = "poznan", para = "warszawa", ano = 1870, km = 347, terreno = "planicie", custo = 954903, degrau = 7 },
			},
		},
		{
			id = "frejus", nome = "Túnel do Fréjus (Mont Cenis)", nomeEn = "Fréjus Tunnel (Mont Cenis)", ano = 1871, cor = 4, ordem = 41, degrau = 5, projeto = nil, nota = { pt = "O primeiro grande túnel sob os Alpes, com 13 km, cavado com perfuratrizes de ar comprimido.", en = "The first great tunnel under the Alps, 13 km long, dug with compressed-air drills." },
			trechos = {
				{ id = "frejus_1", de = "lyon", para = "chambery", ano = 1857, km = 108, terreno = "vale", custo = 61917, degrau = 5 },
				{ id = "frejus_2", de = "chambery", para = "torino", ano = 1871, km = 186, terreno = "alpes", custo = 231043, degrau = 5 },
			},
		},
		{
			id = "porrettana", nome = "Milão–Bolonha–Florença–Roma", nomeEn = "Milan–Bologna–Florence–Rome", ano = 1874, cor = 4, ordem = 42, degrau = 5, projeto = nil, nota = { pt = "A Porrettana cruzou os Apeninos com dezenas de túneis e juntou o norte e o centro da Itália recém-unificada.", en = "The Porrettana crossed the Apennines through dozens of tunnels and joined the north and centre of newly united Italy." },
			trechos = {
				{ id = "porrettana_1", de = "milano", para = "bologna", ano = 1859, km = 251, terreno = "planicie", custo = 119917, degrau = 5 },
				{ id = "porrettana_2", de = "bologna", para = "firenze", ano = 1864, km = 100, terreno = "montanhas", custo = 95551, degrau = 5 },
				{ id = "porrettana_3", de = "firenze", para = "roma", ano = 1874, km = 303, terreno = "colinas", custo = 202665, degrau = 5, via = { Vector2.new(1096.3, 1057.2), Vector2.new(1105.8, 1095.9) } },
			},
		},
		{
			id = "gotthard", nome = "Ferrovia do Gotardo", nomeEn = "Gotthard Railway", ano = 1882, cor = 2, ordem = 43, degrau = 6, projeto = nil, nota = { pt = "O túnel do Gotardo, de 15 km, custou a vida de quase 200 operários; as voltas em espiral de Wassen viraram cartão-postal.", en = "The 15 km Gotthard tunnel cost nearly 200 workers their lives; the spiral loops at Wassen became a postcard." },
			trechos = {
				{ id = "gotthard_1", de = "zurich", para = "luzern", ano = 1864, km = 49, terreno = "colinas", custo = 78658, degrau = 6 },
				{ id = "gotthard_2", de = "luzern", para = "milano", ano = 1882, km = 237, terreno = "alpes", custo = 706546, degrau = 6 },
			},
		},
		{
			id = "arlberg", nome = "Ferrovia do Arlberg", nomeEn = "Arlberg Railway", ano = 1884, cor = 6, ordem = 44, degrau = 6, projeto = nil, nota = { pt = "O túnel do Arlberg, de 10 km, ligou o Tirol à Suíça sem passar pela Alemanha.", en = "The 10 km Arlberg tunnel linked the Tyrol to Switzerland without passing through Germany." },
			trechos = {
				{ id = "arlberg_1", de = "innsbruck", para = "zurich", ano = 1884, km = 276, terreno = "alpes", custo = 822813, degrau = 6, via = { Vector2.new(1031.2, 864.6), Vector2.new(1007.8, 862.4) } },
			},
		},
		{
			id = "orient", nome = "Rota do Expresso do Oriente", nomeEn = "Orient Express Route", ano = 1888, cor = 8, ordem = 45, degrau = 6, projeto = nil, nota = { pt = "Em 1889 o Expresso do Oriente passou a ir de Paris a Constantinopla só de trem, com vagões-leito de luxo.", en = "In 1889 the Orient Express began running from Paris to Constantinople entirely by train, with luxury sleeping cars." },
			trechos = {
				{ id = "orient_1", de = "wien", para = "budapest", ano = 1846, km = 268, terreno = "planicie", custo = 307294, degrau = 6 },
				{ id = "orient_2", de = "budapest", para = "beograd", ano = 1884, km = 401, terreno = "planicie", custo = 459794, degrau = 6 },
				{ id = "orient_3", de = "beograd", para = "sofia", ano = 1888, km = 408, terreno = "montanhas", custo = 935640, degrau = 6 },
				{ id = "orient_4", de = "sofia", para = "istanbul", ano = 1888, km = 631, terreno = "colinas", custo = 1012922, degrau = 6 },
			},
		},
		{
			id = "forth", nome = "Ponte do Forth", nomeEn = "Forth Bridge", ano = 1890, cor = 4, ordem = 46, degrau = 7, projeto = nil, nota = { pt = "A ponte do Forth, de 1890, com seus grandes balanços de aço vermelho, levou o trem de Edimburgo para o norte da Escócia.", en = "The 1890 Forth Bridge, with its great red steel cantilevers, carried the train from Edinburgh to the north of Scotland." },
			trechos = {
				{ id = "forth_1", de = "edinburgh", para = "aberdeen", ano = 1890, km = 204, terreno = "costa", custo = 617523, degrau = 7, via = { Vector2.new(633.9, 357.7), Vector2.new(638.6, 354.8), Vector2.new(647.6, 337.6), Vector2.new(659.7, 334.4), Vector2.new(664.3, 327.2), Vector2.new(674.0, 315.4) } },
			},
		},
		{
			id = "carpatos", nome = "Budapeste–Bucareste–Constança", nomeEn = "Budapest–Bucharest–Constanța", ano = 1895, cor = 8, ordem = 47, degrau = 7, projeto = nil, nota = { pt = "Cruzava os Cárpatos pela Transilvânia; a ponte de Cernavodă sobre o Danúbio, de 1895, era a mais longa da Europa.", en = "It crossed the Carpathians through Transylvania; the 1895 Cernavodă bridge over the Danube was Europe's longest." },
			trechos = {
				{ id = "carpatos_1", de = "budapest", para = "bucuresti", ano = 1879, km = 869, terreno = "montanhas", custo = 4782772, degrau = 7, via = { Vector2.new(1513.4, 838.4), Vector2.new(1596.1, 882.2), Vector2.new(1618.9, 915.7) } },
				{ id = "carpatos_2", de = "bucuresti", para = "constanta", ano = 1895, km = 256, terreno = "planicie", custo = 704482, degrau = 7, via = { Vector2.new(1699.2, 929.5) } },
			},
		},
		{
			id = "simplon", nome = "Túnel do Simplon", nomeEn = "Simplon Tunnel", ano = 1906, cor = 5, ordem = 48, degrau = 7, projeto = nil, nota = { pt = "Em 1906, com 19,8 km, o Simplon virou o túnel ferroviário mais longo do mundo e encurtou o Paris–Milão.", en = "In 1906, at 19.8 km, the Simplon became the world's longest railway tunnel and shortened Paris–Milan." },
			trechos = {
				{ id = "simplon_1", de = "lausanne", para = "milano", ano = 1906, km = 288, terreno = "alpes", custo = 2060610, degrau = 7 },
			},
		},
		{
			id = "bergensbanen", nome = "Bergensbanen", nomeEn = nil, ano = 1909, cor = 7, ordem = 49, degrau = 7, projeto = nil, nota = { pt = "Atravessa o planalto de Hardangervidda a 1.222 m de altitude, com galerias para proteger os trilhos da neve.", en = "It crosses the Hardangervidda plateau at 1,222 m, with snow sheds to protect the tracks." },
			trechos = {
				{ id = "bergensbanen_1", de = "oslo", para = "bergen", ano = 1909, km = 408, terreno = "montanhas", custo = 2245536, degrau = 7, via = { Vector2.new(1030.8, 176.1), Vector2.new(979.8, 153.0), Vector2.new(959.0, 152.4), Vector2.new(931.0, 149.6) } },
			},
		},
		{
			id = "vardar", nome = "Belgrado–Salônica–Atenas", nomeEn = "Belgrade–Thessaloniki–Athens", ano = 1916, cor = 1, ordem = 50, degrau = 7, projeto = nil, nota = { pt = "Desce o vale do Vardar até o mar Egeu; o trecho até Atenas só ficou pronto durante a Primeira Guerra.", en = "It runs down the Vardar valley to the Aegean; the stretch to Athens was finished only during the First World War." },
			trechos = {
				{ id = "vardar_1", de = "beograd", para = "skopje", ano = 1888, km = 440, terreno = "vale", custo = 1452994, degrau = 7, via = { Vector2.new(1480.5, 1029.1) } },
				{ id = "vardar_2", de = "skopje", para = "thessaloniki", ano = 1888, km = 246, terreno = "vale", custo = 812356, degrau = 7 },
				{ id = "vardar_3", de = "thessaloniki", para = "athina", ano = 1916, km = 459, terreno = "montanhas", custo = 2526228, degrau = 7, via = { Vector2.new(1535.2, 1165.4), Vector2.new(1528.1, 1179.9), Vector2.new(1527.9, 1184.2), Vector2.new(1532.8, 1203.1), Vector2.new(1529.6, 1217.5), Vector2.new(1535.8, 1255.9), Vector2.new(1576.8, 1279.8) } },
			},
		},
		{
			id = "hs2", nome = "HS2", nomeEn = nil, ano = 2033, cor = 3, ordem = 51, degrau = 5, projeto = "hs2", nota = { pt = "A nova linha de alta velocidade britânica: Londres–Birmingham em obras, e o trecho até Manchester cortado em 2023.", en = "Britain's new high-speed line: London–Birmingham under construction, with the stretch to Manchester cancelled in 2023." },
			trechos = {
				{ id = "hs2_1", de = "london", para = "birmingham", ano = 2033, km = 203, terreno = "colinas", custo = 135779, degrau = 5 },
				{ id = "hs2_2", de = "birmingham", para = "manchester", ano = 2040, km = 142, terreno = "colinas", custo = 94978, degrau = 5 },
			},
		},
		{
			id = "rail_baltica", nome = "Rail Baltica", nomeEn = nil, ano = 2030, cor = 4, ordem = 52, degrau = 6, projeto = "rail_baltica", nota = { pt = "Uma ferrovia em bitola europeia para ligar os países bálticos a Varsóvia e ao resto do continente.", en = "A European-gauge railway linking the Baltic states to Warsaw and the rest of the continent." },
			trechos = {
				{ id = "rail_baltica_1", de = "warszawa", para = "kaunas", ano = 2030, km = 441, terreno = "planicie", custo = 505658, degrau = 6 },
				{ id = "rail_baltica_2", de = "kaunas", para = "riga", ano = 2030, km = 285, terreno = "planicie", custo = 326786, degrau = 6 },
				{ id = "rail_baltica_3", de = "riga", para = "tallinn", ano = 2030, km = 356, terreno = "costa", custo = 449016, degrau = 6, via = { Vector2.new(1437.2, 268.9), Vector2.new(1428.9, 224.6) } },
			},
		},
		{
			id = "fehmarn", nome = "Túnel do Fehmarnbelt", nomeEn = "Fehmarnbelt Tunnel", ano = 2031, cor = 7, ordem = 53, degrau = 7, projeto = "fehmarn", nota = { pt = "Um túnel submerso de 18 km sob o Báltico, entre a Alemanha e a Dinamarca, em obras desde 2020.", en = "An 18 km immersed tunnel under the Baltic, between Germany and Denmark, under construction since 2020." },
			trechos = {
				{ id = "fehmarn_1", de = "hamburg", para = "kobenhavn", ano = 2031, km = 362, terreno = "mar", custo = 3486636, degrau = 7 },
			},
		},
		{
			id = "lyon_turin", nome = "Túnel Lyon–Turim", nomeEn = "Lyon–Turin Tunnel", ano = 2033, cor = 1, ordem = 54, degrau = 8, projeto = "lyon_turin", nota = { pt = "Um túnel de base de 57 km sob os Alpes, para trens de carga e de alta velocidade entre a França e a Itália.", en = "A 57 km base tunnel under the Alps for freight and high-speed trains between France and Italy." },
			trechos = {
				{ id = "lyon_turin_1", de = "lyon", para = "torino", ano = 2033, km = 294, terreno = "tunel_base", custo = 6213531, degrau = 8 },
			},
		},
		{
			id = "messina", nome = "Ponte do Estreito de Messina", nomeEn = "Strait of Messina Bridge", ano = 2040, cor = 2, ordem = 55, degrau = 8, projeto = "messina", nota = { pt = "E se a Sicília tivesse, enfim, a ponte suspensa mais longa do mundo? O projeto vai e volta há mais de 50 anos.", en = "What if Sicily finally got the world's longest suspension bridge? The plan has come and gone for over 50 years." },
			trechos = {
				{ id = "messina_1", de = "napoli", para = "reggio", ano = 2040, km = 528, terreno = "colinas", custo = 4882060, degrau = 8, via = { Vector2.new(1225.1, 1196.7), Vector2.new(1250.4, 1213.4), Vector2.new(1273.1, 1245.9), Vector2.new(1281.1, 1271.6), Vector2.new(1290.8, 1289.2), Vector2.new(1278.2, 1316.6) } },
				{ id = "messina_2", de = "reggio", para = "messina", ano = 2040, km = 16, terreno = "mar", custo = 369853, degrau = 8 },
				{ id = "messina_3", de = "messina", para = "palermo", ano = 2040, km = 255, terreno = "costa", custo = 1852568, degrau = 8, via = { Vector2.new(1245.8, 1332.2), Vector2.new(1223.0, 1336.8), Vector2.new(1191.8, 1344.4), Vector2.new(1175.1, 1345.2) } },
			},
		},
	},
	projetos = {
		{ id = "hs2", nome = "HS2", nomeEn = nil, emoji = "pesquisa", linha = "hs2", custo = 2500000, segundos = 4800, ficticio = false, descricao = nil, requer = { linhasCompletas = nil, era = "diesel", projeto = nil } },
		{ id = "rail_baltica", nome = "Rail Baltica", nomeEn = nil, emoji = "pesquisa", linha = "rail_baltica", custo = 8000000, segundos = 14400, ficticio = false, descricao = nil, requer = { linhasCompletas = nil, era = "eletrico", projeto = nil } },
		{ id = "fehmarn", nome = "Túnel do Fehmarnbelt", nomeEn = "Fehmarnbelt Tunnel", emoji = "pesquisa", linha = "fehmarn", custo = 12000000, segundos = 14400, ficticio = false, descricao = nil, requer = { linhasCompletas = nil, era = "eletrico", projeto = "rail_baltica" } },
		{ id = "lyon_turin", nome = "Túnel Lyon–Turim", nomeEn = "Lyon–Turin Tunnel", emoji = "pesquisa", linha = "lyon_turin", custo = 30000000, segundos = 7200, ficticio = false, descricao = nil, requer = { linhasCompletas = nil, era = "alta", projeto = nil } },
		{ id = "messina", nome = "Ponte do Estreito de Messina", nomeEn = "Strait of Messina Bridge", emoji = "pesquisa", linha = "messina", custo = 40000000, segundos = 7200, ficticio = true, descricao = nil, requer = { linhasCompletas = nil, era = "alta", projeto = "lyon_turin" } },
	},
	rotulos = {
		{ tipo = "estado", texto = "R E I N O    U N I D O", textoEn = "U N I T E D    K I N G D O M", pos = Vector2.new(649.9, 529.3), angulo = 0, zoomMin = 0, zoomMax = 4 },
		{ tipo = "estado", texto = "I R L A N D A", textoEn = "I R E L A N D", pos = Vector2.new(461.2, 473.5), angulo = 0, zoomMin = 0, zoomMax = 4 },
		{ tipo = "estado", texto = "F R A N Ç A", textoEn = "F R A N C E", pos = Vector2.new(749.4, 867.9), angulo = 0, zoomMin = 0, zoomMax = 4 },
		{ tipo = "estado", texto = "E S P A N H A", textoEn = "S P A I N", pos = Vector2.new(470.5, 1211.3), angulo = 0, zoomMin = 0, zoomMax = 4 },
		{ tipo = "estado", texto = "P O R T U G A L", textoEn = "P O R T U G A L", pos = Vector2.new(294.8, 1174.0), angulo = -80, zoomMin = 0, zoomMax = 4 },
		{ tipo = "estado", texto = "A L E M A N H A", textoEn = "G E R M A N Y", pos = Vector2.new(1030.6, 660.2), angulo = 0, zoomMin = 0, zoomMax = 4 },
		{ tipo = "estado", texto = "I T Á L I A", textoEn = "I T A L Y", pos = Vector2.new(1148.4, 1090.2), angulo = 50, zoomMin = 0, zoomMax = 4 },
		{ tipo = "estado", texto = "S U Í Ç A", textoEn = "S W I T Z E R L A N D", pos = Vector2.new(955.2, 883.7), angulo = 0, zoomMin = 1.2, zoomMax = 4 },
		{ tipo = "estado", texto = "Á U S T R I A", textoEn = "A U S T R I A", pos = Vector2.new(1187.9, 834.6), angulo = 0, zoomMin = 0, zoomMax = 4 },
		{ tipo = "estado", texto = "B É L G I C A", textoEn = "B E L G I U M", pos = Vector2.new(842.9, 677.3), angulo = 0, zoomMin = 1.2, zoomMax = 4 },
		{ tipo = "estado", texto = "P A Í S E S    B A I X O S", textoEn = "N E T H E R L A N D S", pos = Vector2.new(882.0, 587.2), angulo = 0, zoomMin = 1.2, zoomMax = 4 },
		{ tipo = "estado", texto = "D I N A M A R C A", textoEn = "D E N M A R K", pos = Vector2.new(1000.4, 390.7), angulo = 0, zoomMin = 0, zoomMax = 4 },
		{ tipo = "estado", texto = "P O L Ô N I A", textoEn = "P O L A N D", pos = Vector2.new(1325.5, 588.1), angulo = 0, zoomMin = 0, zoomMax = 4 },
		{ tipo = "estado", texto = "T C H É Q U I A", textoEn = "C Z E C H I A", pos = Vector2.new(1204.6, 717.1), angulo = 0, zoomMin = 0, zoomMax = 4 },
		{ tipo = "estado", texto = "H U N G R I A", textoEn = "H U N G A R Y", pos = Vector2.new(1361.3, 844.7), angulo = 0, zoomMin = 0, zoomMax = 4 },
		{ tipo = "estado", texto = "S É R V I A", textoEn = "S E R B I A", pos = Vector2.new(1434.5, 1005.2), angulo = 0, zoomMin = 0, zoomMax = 4 },
		{ tipo = "estado", texto = "B U L G Á R I A", textoEn = "B U L G A R I A", pos = Vector2.new(1611.5, 1038.3), angulo = 0, zoomMin = 0, zoomMax = 4 },
		{ tipo = "estado", texto = "R O M Ê N I A", textoEn = "R O M A N I A", pos = Vector2.new(1568.3, 874.5), angulo = 0, zoomMin = 0, zoomMax = 4 },
		{ tipo = "estado", texto = "G R É C I A", textoEn = "G R E E C E", pos = Vector2.new(1513.8, 1227.6), angulo = 0, zoomMin = 0, zoomMax = 4 },
		{ tipo = "estado", texto = "T U R Q U I A", textoEn = "T U R K E Y", pos = Vector2.new(1734.5, 1183.9), angulo = 0, zoomMin = 0, zoomMax = 4 },
		{ tipo = "estado", texto = "S U É C I A", textoEn = "S W E D E N", pos = Vector2.new(1161.7, 254.1), angulo = 0, zoomMin = 0, zoomMax = 4 },
		{ tipo = "estado", texto = "N O R U E G A", textoEn = "N O R W A Y", pos = Vector2.new(997.8, 163.9), angulo = 0, zoomMin = 0, zoomMax = 4 },
		{ tipo = "estado", texto = "F I N L Â N D I A", textoEn = "F I N L A N D", pos = Vector2.new(1405.9, 91.6), angulo = 0, zoomMin = 0, zoomMax = 4 },
		{ tipo = "estado", texto = "E S T Ô N I A", textoEn = "E S T O N I A", pos = Vector2.new(1454.2, 205.5), angulo = 0, zoomMin = 1.2, zoomMax = 4 },
		{ tipo = "estado", texto = "L E T Ô N I A", textoEn = "L A T V I A", pos = Vector2.new(1470.9, 302.2), angulo = 0, zoomMin = 1.2, zoomMax = 4 },
		{ tipo = "estado", texto = "L I T U Â N I A", textoEn = "L I T H U A N I A", pos = Vector2.new(1438.1, 387.6), angulo = 0, zoomMin = 1.2, zoomMax = 4 },
		{ tipo = "estado", texto = "U C R Â N I A", textoEn = "U K R A I N E", pos = Vector2.new(1653.7, 669.9), angulo = 0, zoomMin = 0, zoomMax = 4 },
		{ tipo = "estado", texto = "B I E L O R R Ú S S I A", textoEn = "B E L A R U S", pos = Vector2.new(1576.8, 459.6), angulo = 0, zoomMin = 0, zoomMax = 4 },
		{ tipo = "estado", texto = "E S L O V Á Q U I A", textoEn = "S L O V A K I A", pos = Vector2.new(1357.4, 757.2), angulo = 0, zoomMin = 1.2, zoomMax = 4 },
		{ tipo = "estado", texto = "C R O Á C I A", textoEn = "C R O A T I A", pos = Vector2.new(1260.6, 935.1), angulo = 0, zoomMin = 1.2, zoomMax = 4 },
		{ tipo = "oceano", texto = "O C E A N O    A T L Â N T I C O", textoEn = "A T L A N T I C    O C E A N", pos = Vector2.new(352.2, 839.7), angulo = -70, zoomMin = 0, zoomMax = 99 },
		{ tipo = "oceano", texto = "M A R    D O    N O R T E", textoEn = "N O R T H    S E A", pos = Vector2.new(831.2, 397.9), angulo = 0, zoomMin = 0, zoomMax = 99 },
		{ tipo = "oceano", texto = "M A R    B Á L T I C O", textoEn = "B A L T I C    S E A", pos = Vector2.new(1283.8, 337.5), angulo = -60, zoomMin = 0, zoomMax = 99 },
		{ tipo = "oceano", texto = "M A R    M E D I T E R R Â N E O", textoEn = "M E D I T E R R A N E A N    S E A", pos = Vector2.new(838.2, 1287.1), angulo = 0, zoomMin = 0, zoomMax = 99 },
		{ tipo = "oceano", texto = "M A R    A D R I Á T I C O", textoEn = "A D R I A T I C    S E A", pos = Vector2.new(1240.8, 1074.2), angulo = 40, zoomMin = 0.9, zoomMax = 99 },
		{ tipo = "oceano", texto = "M A R    N E G R O", textoEn = "B L A C K    S E A", pos = Vector2.new(1821.7, 953.5), angulo = 0, zoomMin = 0, zoomMax = 99 },
		{ tipo = "oceano", texto = "M A R    T I R R E N O", textoEn = "T Y R R H E N I A N    S E A", pos = Vector2.new(1105.9, 1260.1), angulo = 0, zoomMin = 0.9, zoomMax = 99 },
		{ tipo = "regiao", texto = "Alpes", textoEn = "Alps", pos = Vector2.new(1031.3, 895.2), angulo = -10, zoomMin = 0, zoomMax = 99 },
		{ tipo = "regiao", texto = "Pireneus", textoEn = "Pyrenees", pos = Vector2.new(654.8, 1077.4), angulo = -10, zoomMin = 0, zoomMax = 99 },
		{ tipo = "regiao", texto = "Cárpatos", textoEn = "Carpathians", pos = Vector2.new(1499.4, 780.2), angulo = -35, zoomMin = 0, zoomMax = 99 },
		{ tipo = "regiao", texto = "Vale do Ruhr", textoEn = "Ruhr Valley", pos = Vector2.new(935.5, 624.2), angulo = 0, zoomMin = 0, zoomMax = 99 },
		{ tipo = "regiao", texto = "Meseta", textoEn = "Meseta", pos = Vector2.new(493.6, 1146.0), angulo = 0, zoomMin = 0, zoomMax = 99 },
		{ tipo = "regiao", texto = "Planície Húngara", textoEn = "Hungarian Plain", pos = Vector2.new(1407.7, 865.0), angulo = 0, zoomMin = 0, zoomMax = 99 },
		{ tipo = "rio", texto = "Rio Reno", textoEn = "Rhine", pos = Vector2.new(942.3, 717.0), angulo = -70, zoomMin = 0, zoomMax = 99 },
		{ tipo = "rio", texto = "Rio Danúbio", textoEn = "Danube", pos = Vector2.new(1292.5, 807.4), angulo = -15, zoomMin = 0, zoomMax = 99 },
		{ tipo = "rio", texto = "Rio Sena", textoEn = "Seine", pos = Vector2.new(785.8, 786.5), angulo = -20, zoomMin = 0, zoomMax = 99 },
		{ tipo = "rio", texto = "Rio Ródano", textoEn = "Rhône", pos = Vector2.new(820.7, 990.7), angulo = -80, zoomMin = 0, zoomMax = 99 },
		{ tipo = "rio", texto = "Rio Elba", textoEn = "Elbe", pos = Vector2.new(1075.1, 564.6), angulo = -40, zoomMin = 0, zoomMax = 99 },
		{ tipo = "rio", texto = "Rio Pó", textoEn = "Po", pos = Vector2.new(1042.7, 971.6), angulo = 0, zoomMin = 0, zoomMax = 99 },
		{ tipo = "rio", texto = "Rio Tejo", textoEn = "Tagus", pos = Vector2.new(375.9, 1184.5), angulo = -10, zoomMin = 0, zoomMax = 99 },
		{ tipo = "rio", texto = "Rio Vístula", textoEn = "Vistula", pos = Vector2.new(1337.4, 629.2), angulo = -70, zoomMin = 0, zoomMax = 99 },
	},
}
