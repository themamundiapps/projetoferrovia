# Monta tools/dados/europa.json a partir de europa_estacoes.py e das linhas abaixo.
# Uso: python tools/dados/montar_europa.py && node tools/dados/gerar.mjs
# Traçados simplificados (só as cidades principais); anos dos trechos aproximados.
import json, os, sys

AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
from europa_estacoes import E  # noqa: E402


def T(pt, en):
    return {"pt": pt, "en": en}


TERRENOS = {
    "planicie": {"nome": "Planície", "nomeEn": "Plains", "custo": 1.0},
    "costa": {"nome": "Planície costeira", "nomeEn": "Coastal plain", "custo": 1.1},
    "vale": {"nome": "Vale", "nomeEn": "Valley", "custo": 1.2},
    "colinas": {"nome": "Colinas", "nomeEn": "Hills", "custo": 1.4},
    "montanhas": {"nome": "Montanhas", "nomeEn": "Mountains", "custo": 2.0},
    "alpes": {"nome": "Alpes (túneis e viadutos)", "nomeEn": "Alps (tunnels and viaducts)", "custo": 2.6},
    "tunel_base": {"nome": "Túnel de base sob os Alpes", "nomeEn": "Base tunnel under the Alps", "custo": 3.2},
    "mar": {"nome": "Travessia do mar (túnel ou ponte)", "nomeEn": "Sea crossing (tunnel or bridge)", "custo": 3.5},
}

# países (no lugar dos estados) e regiões
ESTADOS = {
    "GB": ["Reino Unido", "o"], "FR": ["França", "o"], "BE": ["Bélgica", "o"], "NL": ["Países Baixos", "o"],
    "DE": ["Alemanha", "c"], "DK": ["Dinamarca", "c"], "CH": ["Suíça", "c"], "AT": ["Áustria", "c"],
    "CZ": ["Tchéquia", "c"], "PL": ["Polônia", "c"], "SI": ["Eslovênia", "c"],
    "IT": ["Itália", "s"], "ES": ["Espanha", "s"], "PT": ["Portugal", "s"],
    "HU": ["Hungria", "l"], "RS": ["Sérvia", "l"], "BG": ["Bulgária", "l"], "TR": ["Turquia", "l"],
    "SE": ["Suécia", "n"], "LT": ["Lituânia", "n"], "LV": ["Letônia", "n"], "EE": ["Estônia", "n"],
}
REGIOES = {
    "o": T("Europa Ocidental", "Western Europe"), "c": T("Europa Central", "Central Europe"),
    "s": T("Sul da Europa", "Southern Europe"), "l": T("Bálcãs", "Balkans"), "n": T("Norte e Báltico", "North and Baltic"),
}


def tr(de, para, ano, terreno, via=None):
    t = {"de": de, "para": para, "ano": ano, "terreno": terreno}
    if via:
        t["via"] = via
    return t


# (id, nome, ano, cor, degrau, trechos, nota, projeto)
LINHAS = [
    ("stockton_darlington", "Stockton and Darlington", 1825, 2, 0, [
        tr("darlington", "stockton", 1825, "planicie"),
    ], T("Em 27 de setembro de 1825, a Locomotion nº 1 de George Stephenson puxou o primeiro trem a vapor público do mundo.",
         "On 27 September 1825, George Stephenson's Locomotion No. 1 pulled the world's first public steam train.")),
    ("liverpool_manchester", "Liverpool and Manchester", 1830, 6, 0, [
        tr("liverpool", "manchester", 1830, "planicie"),
    ], T("A primeira ferrovia interurbana do mundo, só com trens a vapor e horário fixo. A Rocket venceu o concurso de locomotivas de Rainhill.",
         "The world's first intercity railway, with only steam trains and a timetable. The Rocket won the Rainhill locomotive trials.")),
    ("london_birmingham", "London and Birmingham", 1838, 1, 1, [
        tr("london", "birmingham", 1838, "colinas"),
    ], T("A primeira grande linha saindo de Londres, construída por Robert Stephenson, com o arco de Euston na entrada.",
         "The first great main line out of London, built by Robert Stephenson, with the Euston Arch at its gate.")),
    ("grand_junction", "Grand Junction", 1837, 5, 1, [
        tr("birmingham", "crewe", 1837, "planicie"),
        tr("crewe", "manchester", 1842, "planicie"),
    ], T("Ligou Birmingham ao noroeste e fez de Crewe, um vilarejo, um dos maiores entroncamentos ferroviários do mundo.",
         "It linked Birmingham to the north-west and turned the village of Crewe into one of the world's great railway junctions.")),
    ("belgica", "Ferrovias do Estado Belga", 1836, 3, 1, [
        tr("bruxelles", "antwerpen", 1836, "planicie"),
    ], T("A Bélgica, recém-independente, foi o primeiro país a planejar uma rede nacional, com Mechelen no centro.",
         "Newly independent Belgium was the first country to plan a national network, with Mechelen at its centre.")),
    ("leipzig_dresden", "Leipzig–Dresden", 1839, 4, 1, [
        tr("leipzig", "dresden", 1839, "colinas"),
    ], T("A primeira ferrovia de longa distância da Alemanha, com o primeiro túnel ferroviário do país.",
         "Germany's first long-distance railway, with the country's first railway tunnel.")),
    ("great_western", "Great Western", 1841, 7, 2, [
        tr("london", "reading", 1840, "vale"),
        tr("reading", "bristol", 1841, "colinas"),
    ], T("Isambard Kingdom Brunel a construiu em bitola larga, com o túnel de Box e trens que chegavam a 100 km/h.",
         "Isambard Kingdom Brunel built it on broad gauge, with the Box Tunnel and trains that reached 100 km/h.")),
    ("paris_rouen", "Paris–Rouen–Le Havre", 1843, 8, 2, [
        tr("paris", "rouen", 1843, "vale"),
        tr("rouen", "le_havre", 1847, "costa"),
    ], T("Construída com dinheiro e operários ingleses, levou Paris até o mar pelo vale do Sena.",
         "Built with English money and navvies, it took Paris to the sea along the Seine valley.")),
    ("nordbahn", "Kaiser Ferdinands-Nordbahn", 1839, 2, 2, [
        tr("wien", "brno", 1839, "planicie"),
        tr("brno", "krakow", 1856, "colinas"),
    ], T("A primeira ferrovia a vapor da Áustria, financiada pelos Rothschild, levava o carvão e o sal da Galícia para Viena.",
         "Austria's first steam railway, funded by the Rothschilds, carried coal and salt from Galicia to Vienna.")),
    ("hijs", "Hollandsche IJzeren Spoorweg", 1839, 6, 2, [
        tr("amsterdam", "rotterdam", 1847, "planicie"),
    ], T("A primeira ferrovia holandesa começou com a locomotiva De Arend, entre Amsterdã e Haarlem, em 1839.",
         "The first Dutch railway began with the De Arend locomotive, between Amsterdam and Haarlem, in 1839.")),
    ("nord", "Chemin de fer du Nord", 1846, 1, 3, [
        tr("paris", "lille", 1846, "planicie"),
        tr("lille", "bruxelles", 1846, "planicie"),
    ], T("A companhia dos Rothschild ligou Paris ao norte industrial e à Bélgica.",
         "The Rothschilds' company linked Paris to the industrial north and to Belgium.")),
    ("plm", "Paris–Lyon–Méditerranée", 1857, 3, 3, [
        tr("paris", "dijon", 1851, "colinas"),
        tr("dijon", "lyon", 1854, "vale"),
        tr("lyon", "marseille", 1856, "vale"),
    ], T("A \"linha imperial\", que levava Paris ao Mediterrâneo pelo vale do Ródano.",
         "The \"imperial line\", which took Paris to the Mediterranean down the Rhône valley.")),
    ("berlin_hamburg", "Berlim–Hamburgo", 1846, 5, 3, [
        tr("berlin", "hamburg", 1846, "planicie"),
    ], T("Ligou a capital prussiana ao maior porto alemão pela planície do norte.",
         "It linked the Prussian capital to Germany's largest port across the northern plain.")),
    ("koln_minden", "Köln-Mindener", 1847, 4, 3, [
        tr("koln", "essen", 1847, "planicie"),
        tr("essen", "hannover", 1847, "planicie"),
    ], T("Atravessou o Vale do Ruhr e transformou as minas de carvão no coração industrial da Alemanha.",
         "It crossed the Ruhr Valley and turned the coal mines into Germany's industrial heart.")),
    ("east_coast", "East Coast Main Line", 1850, 7, 4, [
        tr("london", "york", 1850, "planicie"),
        tr("york", "newcastle", 1850, "planicie"),
        tr("newcastle", "edinburgh", 1850, "costa"),
    ], T("A linha do Flying Scotsman, entre Londres e Edimburgo; a Mallard bateu aqui o recorde mundial do vapor, 203 km/h.",
         "The Flying Scotsman's line between London and Edinburgh; Mallard set the world steam record here, 203 km/h.")),
    ("sudbahn", "Südbahn (Semmering)", 1857, 8, 4, [
        tr("wien", "graz", 1854, "alpes"),
        tr("graz", "ljubljana", 1849, "colinas"),
        tr("ljubljana", "trieste", 1857, "montanhas"),
    ], T("A ferrovia do Semmering, de 1854, foi a primeira a cruzar uma cordilheira dos Alpes. Hoje é Patrimônio da Humanidade.",
         "The Semmering railway, from 1854, was the first to cross an Alpine range. It is now a World Heritage Site.")),
    ("madrid_barcelona", "Madri–Saragoça–Barcelona", 1863, 2, 4, [
        tr("barcelona", "zaragoza", 1861, "colinas"),
        tr("zaragoza", "madrid", 1863, "colinas"),
    ], T("Ligou a capital ao porto e à indústria da Catalunha, em bitola larga ibérica.",
         "It linked the capital to the port and industry of Catalonia, on broad Iberian gauge.")),
    ("lisboa_porto", "Linha do Norte", 1864, 6, 4, [
        tr("lisboa", "coimbra", 1864, "costa"),
        tr("coimbra", "porto", 1864, "colinas"),
    ], T("A espinha dorsal de Portugal; a ponte Maria Pia, de Eiffel, levou os trens até o Porto em 1877.",
         "Portugal's backbone; Eiffel's Maria Pia bridge carried the trains into Porto in 1877.")),
    ("norte_espana", "Caminhos de Ferro do Norte", 1864, 5, 5, [
        tr("madrid", "valladolid", 1860, "colinas"),
        tr("valladolid", "burgos", 1860, "planicie"),
        tr("burgos", "bilbao", 1863, "montanhas"),
    ], T("Subia a meseta castelhana e descia até o País Basco, de onde saía o minério de ferro.",
         "It climbed the Castilian plateau and came down to the Basque Country, where iron ore was shipped.")),
    ("lombardo_veneta", "Turim–Milão–Veneza", 1857, 1, 5, [
        tr("torino", "milano", 1859, "planicie"),
        tr("milano", "venezia", 1857, "planicie"),
    ], T("A ferrovia da planície do Pó; a ponte da laguna, de 1846, levou o trem até Veneza.",
         "The Po plain railway; the lagoon bridge of 1846 brought the train into Venice.")),
    ("roma_napoli", "Roma–Nápoles", 1863, 3, 5, [
        tr("roma", "napoli", 1863, "colinas"),
    ], T("Ligou a cidade dos papas ao maior porto do sul da Itália, logo depois da unificação.",
         "It linked the city of the popes to southern Italy's largest port, right after unification.")),
    ("frejus", "Túnel do Fréjus (Mont Cenis)", 1871, 4, 5, [
        tr("lyon", "chambery", 1857, "vale"),
        tr("chambery", "torino", 1871, "alpes"),
    ], T("O primeiro grande túnel sob os Alpes, com 13 km, cavado com perfuratrizes de ar comprimido.",
         "The first great tunnel under the Alps, 13 km long, dug with compressed-air drills.")),
    ("brenner", "Ferrovia do Brenner", 1867, 7, 6, [
        tr("munchen", "innsbruck", 1858, "vale"),
        tr("innsbruck", "verona", 1867, "alpes"),
    ], T("A primeira ferrovia a cruzar os Alpes por cima, pelo Passo do Brenner, sem túnel de cume.",
         "The first railway over the Alps, through the Brenner Pass, without a summit tunnel.")),
    ("gotthard", "Ferrovia do Gotardo", 1882, 2, 6, [
        tr("zurich", "luzern", 1864, "colinas"),
        tr("luzern", "milano", 1882, "alpes"),
    ], T("O túnel do Gotardo, de 15 km, custou a vida de quase 200 operários; as voltas em espiral de Wassen viraram cartão-postal.",
         "The 15 km Gotthard tunnel cost nearly 200 workers their lives; the spiral loops at Wassen became a postcard.")),
    ("orient", "Rota do Expresso do Oriente", 1888, 8, 6, [
        tr("wien", "budapest", 1846, "planicie"),
        tr("budapest", "beograd", 1884, "planicie"),
        tr("beograd", "sofia", 1888, "montanhas"),
        tr("sofia", "istanbul", 1888, "colinas"),
    ], T("Em 1889 o Expresso do Oriente passou a ir de Paris a Constantinopla só de trem, com vagões-leito de luxo.",
         "In 1889 the Orient Express began running from Paris to Constantinople entirely by train, with luxury sleeping cars.")),
    ("suecia", "Västra stambanan", 1862, 6, 6, [
        tr("stockholm", "goteborg", 1862, "colinas"),
    ], T("A linha principal do oeste da Suécia, construída pelo Estado para ligar a capital ao Mar do Norte.",
         "Sweden's western main line, built by the state to link the capital to the North Sea.")),
    ("varsovia", "Berlim–Varsóvia", 1870, 1, 7, [
        tr("berlin", "poznan", 1870, "planicie"),
        tr("poznan", "warszawa", 1870, "planicie"),
    ], T("A ligação entre Berlim e Varsóvia pela planície do norte, depois parte do Expresso Nord.",
         "The link between Berlin and Warsaw across the northern plain, later part of the Nord Express.")),
    ("simplon", "Túnel do Simplon", 1906, 5, 7, [
        tr("lausanne", "milano", 1906, "alpes"),
    ], T("Em 1906, com 19,8 km, o Simplon virou o túnel ferroviário mais longo do mundo e encurtou o Paris–Milão.",
         "In 1906, at 19.8 km, the Simplon became the world's longest railway tunnel and shortened Paris–Milan.")),
    # ---------------------------------------------------------------- Gabinete de Projetos
    ("hs2", "HS2", 2033, 3, 5, [
        tr("london", "birmingham", 2033, "colinas"),
        tr("birmingham", "manchester", 2040, "colinas"),
    ], T("A nova linha de alta velocidade britânica: Londres–Birmingham em obras, e o trecho até Manchester cortado em 2023.",
         "Britain's new high-speed line: London–Birmingham under construction, with the stretch to Manchester cancelled in 2023."), "hs2"),
    ("rail_baltica", "Rail Baltica", 2030, 4, 6, [
        tr("warszawa", "kaunas", 2030, "planicie"),
        tr("kaunas", "riga", 2030, "planicie"),
        tr("riga", "tallinn", 2030, "costa", [[24.7, 57.6], [24.75, 58.45]]),
    ], T("Uma ferrovia em bitola europeia para ligar os países bálticos a Varsóvia e ao resto do continente.",
         "A European-gauge railway linking the Baltic states to Warsaw and the rest of the continent."), "rail_baltica"),
    ("fehmarn", "Túnel do Fehmarnbelt", 2031, 7, 7, [
        tr("hamburg", "kobenhavn", 2031, "mar"),
    ], T("Um túnel submerso de 18 km sob o Báltico, entre a Alemanha e a Dinamarca, em obras desde 2020.",
         "An 18 km immersed tunnel under the Baltic, between Germany and Denmark, under construction since 2020."), "fehmarn"),
    ("lyon_turin", "Túnel Lyon–Turim", 2033, 1, 8, [
        tr("lyon", "torino", 2033, "tunel_base"),
    ], T("Um túnel de base de 57 km sob os Alpes, para trens de carga e de alta velocidade entre a França e a Itália.",
         "A 57 km base tunnel under the Alps for freight and high-speed trains between France and Italy."), "lyon_turin"),
    ("messina", "Ponte do Estreito de Messina", 2040, 2, 8, [
        tr("napoli", "reggio", 2040, "colinas", [[15.0, 40.7], [15.6, 40.35], [16.1, 39.7], [16.25, 39.2], [16.45, 38.85], [16.1, 38.35]]),
        tr("reggio", "messina", 2040, "mar"),
        tr("messina", "palermo", 2040, "costa", [[15.3, 38.1], [14.75, 38.04], [14.0, 37.93], [13.6, 37.93]]),
    ], T("E se a Sicília tivesse, enfim, a ponte suspensa mais longa do mundo? O projeto vai e volta há mais de 50 anos.",
         "What if Sicily finally got the world's longest suspension bridge? The plan has come and gone for over 50 years."), "messina"),
]

PROJETOS = [
    {"id": "hs2", "nome": "HS2", "emoji": "pesquisa", "custo": 2500000, "minutos": 80,
     "requer": {"era": "diesel"},
     "texto": T("Estudar a nova linha de alta velocidade de Londres a Birmingham e Manchester.",
                "Study the new high-speed line from London to Birmingham and Manchester.")},
    {"id": "rail_baltica", "nome": "Rail Baltica", "emoji": "pesquisa", "custo": 8000000, "minutos": 240,
     "requer": {"era": "eletrico"},
     "texto": T("Estudar a ferrovia em bitola europeia de Varsóvia a Tallinn.",
                "Study the European-gauge railway from Warsaw to Tallinn.")},
    {"id": "fehmarn", "nome": "Túnel do Fehmarnbelt", "emoji": "pesquisa", "custo": 12000000, "minutos": 240,
     "requer": {"era": "eletrico", "projeto": "rail_baltica"},
     "texto": T("Estudar o túnel sob o Báltico entre Hamburgo e Copenhague.",
                "Study the tunnel under the Baltic between Hamburg and Copenhagen.")},
    {"id": "lyon_turin", "nome": "Túnel Lyon–Turim", "emoji": "pesquisa", "custo": 30000000, "minutos": 180,
     "requer": {"era": "alta"},
     "texto": T("Estudar o túnel de base de 57 km sob os Alpes.", "Study the 57 km base tunnel under the Alps.")},
    {"id": "messina", "nome": "Ponte do Estreito de Messina", "emoji": "pesquisa", "custo": 40000000, "minutos": 180, "ficticio": True,
     "requer": {"era": "alta", "projeto": "lyon_turin"},
     "texto": T("E se a Sicília ganhasse uma ponte até o continente?", "What if Sicily got a bridge to the mainland?")},
]


def rot(tipo, texto, textoEn, lon, lat, zmin=None, zmax=None, ang=None):
    r = {"tipo": tipo, "texto": texto, "textoEn": textoEn, "lon": lon, "lat": lat}
    if zmin is not None:
        r["zoomMin"] = zmin
    if zmax is not None:
        r["zoomMax"] = zmax
    if ang is not None:
        r["angulo"] = ang
    return r


ROTULOS = [
    rot("estado", "REINO UNIDO", "UNITED KINGDOM", -1.8, 52.9, zmax=4),
    rot("estado", "IRLANDA", "IRELAND", -8.0, 53.2, zmax=4),
    rot("estado", "FRANÇA", "FRANCE", 2.4, 46.8, zmax=4),
    rot("estado", "ESPANHA", "SPAIN", -3.6, 39.6, zmax=4),
    rot("estado", "PORTUGAL", "PORTUGAL", -8.0, 39.6, zmax=4, ang=-80),
    rot("estado", "ALEMANHA", "GERMANY", 10.2, 51.0, zmax=4),
    rot("estado", "ITÁLIA", "ITALY", 13.2, 42.8, zmax=4, ang=50),
    rot("estado", "SUÍÇA", "SWITZERLAND", 8.1, 46.75, zmin=1.2, zmax=4),
    rot("estado", "ÁUSTRIA", "AUSTRIA", 14.6, 47.6, zmax=4),
    rot("estado", "BÉLGICA", "BELGIUM", 4.6, 50.55, zmin=1.2, zmax=4),
    rot("estado", "PAÍSES BAIXOS", "NETHERLANDS", 5.6, 52.3, zmin=1.2, zmax=4),
    rot("estado", "DINAMARCA", "DENMARK", 9.2, 56.1, zmax=4),
    rot("estado", "POLÔNIA", "POLAND", 19.3, 52.0, zmax=4),
    rot("estado", "TCHÉQUIA", "CZECHIA", 15.3, 49.8, zmax=4),
    rot("estado", "HUNGRIA", "HUNGARY", 19.4, 47.1, zmax=4),
    rot("estado", "SÉRVIA", "SERBIA", 20.8, 43.9, zmax=4),
    rot("estado", "BULGÁRIA", "BULGARIA", 25.2, 42.7, zmax=4),
    rot("estado", "ROMÊNIA", "ROMANIA", 24.9, 45.9, zmax=4),
    rot("estado", "GRÉCIA", "GREECE", 22.0, 39.5, zmax=4),
    rot("estado", "TURQUIA", "TURKEY", 27.5, 39.5, zmax=4),
    rot("estado", "SUÉCIA", "SWEDEN", 15.0, 58.6, zmax=4),
    rot("estado", "NORUEGA", "NORWAY", 9.0, 60.4, zmax=4),
    rot("estado", "FINLÂNDIA", "FINLAND", 25.0, 61.0, zmax=4),
    rot("estado", "ESTÔNIA", "ESTONIA", 25.8, 58.7, zmin=1.2, zmax=4),
    rot("estado", "LETÔNIA", "LATVIA", 25.6, 56.85, zmin=1.2, zmax=4),
    rot("estado", "LITUÂNIA", "LITHUANIA", 23.9, 55.4, zmin=1.2, zmax=4),
    rot("estado", "UCRÂNIA", "UKRAINE", 28.5, 49.3, zmax=4),
    rot("estado", "BIELORRÚSSIA", "BELARUS", 27.8, 53.5, zmax=4),
    rot("estado", "ESLOVÁQUIA", "SLOVAKIA", 19.6, 48.75, zmin=1.2, zmax=4),
    rot("estado", "CROÁCIA", "CROATIA", 16.4, 45.6, zmin=1.2, zmax=4),
    rot("oceano", "OCEANO ATLÂNTICO", "ATLANTIC OCEAN", -8.5, 46.0, ang=-70),
    rot("oceano", "MAR DO NORTE", "NORTH SEA", 3.5, 55.8),
    rot("oceano", "MAR BÁLTICO", "BALTIC SEA", 19.0, 56.8, ang=-60),
    rot("oceano", "MAR MEDITERRÂNEO", "MEDITERRANEAN SEA", 5.5, 39.0),
    rot("oceano", "MAR ADRIÁTICO", "ADRIATIC SEA", 15.6, 43.0, ang=40, zmin=0.9),
    rot("oceano", "MAR NEGRO", "BLACK SEA", 31.0, 43.3),
    rot("oceano", "MAR TIRRENO", "TYRRHENIAN SEA", 12.0, 39.6, zmin=0.9),
    rot("regiao", "Alpes", "Alps", 10.2, 46.55, ang=-10),
    rot("regiao", "Pireneus", "Pyrenees", 0.5, 42.65, ang=-10),
    rot("regiao", "Cárpatos", "Carpathians", 23.5, 47.9, ang=-35),
    rot("regiao", "Vale do Ruhr", "Ruhr Valley", 7.3, 51.65),
    rot("regiao", "Meseta", "Meseta", -3.3, 40.9),
    rot("regiao", "Planície Húngara", "Hungarian Plain", 20.6, 46.6),
    rot("rio", "Rio Reno", "Rhine", 7.6, 49.9, ang=-70),
    rot("rio", "Rio Danúbio", "Danube", 17.6, 47.95, ang=-15),
    rot("rio", "Rio Sena", "Seine", 3.2, 48.4, ang=-20),
    rot("rio", "Rio Ródano", "Rhône", 4.6, 44.6, ang=-80),
    rot("rio", "Rio Elba", "Elbe", 11.6, 52.8, ang=-40),
    rot("rio", "Rio Pó", "Po", 10.5, 45.1),
    rot("rio", "Rio Tejo", "Tagus", -6.0, 39.75, ang=-10),
    rot("rio", "Rio Vístula", "Vistula", 19.5, 51.2, ang=-70),
]

# Nomes que mudam em inglês (estações, linhas e projetos).
NOMES_EN = {
    "london": "London", "manchester": "Manchester", "edinburgh": "Edinburgh", "rouen": "Rouen", "marseille": "Marseille",
    "bruxelles": "Brussels", "antwerpen": "Antwerp", "amsterdam": "Amsterdam", "rotterdam": "Rotterdam",
    "koln": "Cologne", "hannover": "Hanover", "berlin": "Berlin", "hamburg": "Hamburg", "munchen": "Munich",
    "kobenhavn": "Copenhagen", "zurich": "Zurich", "luzern": "Lucerne", "wien": "Vienna", "ljubljana": "Ljubljana",
    "krakow": "Kraków", "warszawa": "Warsaw", "budapest": "Budapest", "beograd": "Belgrade", "sofia": "Sofia",
    "istanbul": "Istanbul", "torino": "Turin", "milano": "Milan", "venezia": "Venice", "roma": "Rome",
    "napoli": "Naples", "madrid": "Madrid", "zaragoza": "Zaragoza", "bilbao": "Bilbao", "lisboa": "Lisbon",
    "stockholm": "Stockholm", "goteborg": "Gothenburg",
    "belgica": "Belgian State Railways", "berlin_hamburg": "Berlin–Hamburg", "madrid_barcelona": "Madrid–Zaragoza–Barcelona",
    "lisboa_porto": "Northern Line (Portugal)", "norte_espana": "Northern Railway of Spain", "lombardo_veneta": "Turin–Milan–Venice",
    "roma_napoli": "Rome–Naples", "frejus": "Fréjus Tunnel (Mont Cenis)", "brenner": "Brenner Railway",
    "gotthard": "Gotthard Railway", "orient": "Orient Express Route", "varsovia": "Berlin–Warsaw",
    "simplon": "Simplon Tunnel", "fehmarn": "Fehmarnbelt Tunnel", "lyon_turin": "Lyon–Turin Tunnel",
    "messina": "Strait of Messina Bridge",
}

estacoes = []
for (eid, nome, lon, lat, porte, produz, porto, paisagem, uf, hpt, hen) in E:
    e = {"id": eid, "nome": nome, "lon": lon, "lat": lat, "porte": porte, "uf": uf, "historia": T(hpt, hen)}
    if eid in NOMES_EN and NOMES_EN[eid] != nome:
        e["nomeEn"] = NOMES_EN[eid]
    if produz:
        e["produz"] = produz
    if porto:
        e["porto"] = True
    if paisagem:
        e["paisagem"] = paisagem
    estacoes.append(e)

ids = {e["id"] for e in estacoes}
linhas = []
for item in LINHAS:
    lid, nome, ano, cor, degrau, trechos, nota = item[:7]
    for t in trechos:
        assert t["de"] in ids and t["para"] in ids, (lid, t)
    l = {"id": lid, "nome": nome, "ano": ano, "cor": cor, "trechos": trechos, "degrau": degrau, "nota": nota}
    if lid in NOMES_EN:
        l["nomeEn"] = NOMES_EN[lid]
    if len(item) > 7:
        l["projeto"] = item[7]
    linhas.append(l)

for p in PROJETOS:
    if p["id"] in NOMES_EN:
        p["nomeEn"] = NOMES_EN[p["id"]]

usadas = {t[k] for l in linhas for t in l["trechos"] for k in ("de", "para")}
assert usadas == ids, ("estações fora de linha", ids - usadas)

dados = {
    "_nota": "Fonte do mapa da Europa, gerada por montar_europa.py (edite lá, não aqui). Depois rode `node tools/dados/gerar.mjs`.",
    "anos": {"vapor": [1825, 1935], "diesel": [1935, 1960], "eletrico": [1960, 1990], "alta": [1990, 2040]},
    "terrenos": TERRENOS,
    "estacoes": estacoes,
    "linhas": linhas,
    "rotulos": ROTULOS,
    "projetos": PROJETOS,
    "foco": ["stockton_darlington", "liverpool_manchester", "london_birmingham", "grand_junction"],
    # Como nos EUA: Diesel com metade das históricas; Elétrica = as 28 históricas + HS2;
    # Alta Velocidade = + Rail Baltica e Fehmarnbelt.
    "metasEra": {"diesel": 15, "eletrico": 29, "alta": 31},
    "estados": ESTADOS,
    "regioes": REGIOES,
}
with open(os.path.join(AQUI, "europa.json"), "w", encoding="utf-8") as f:
    json.dump(dados, f, ensure_ascii=False, indent=2)
print(f"europa.json: {len(estacoes)} estações, {len(linhas)} linhas, {sum(len(l['trechos']) for l in linhas)} trechos")
