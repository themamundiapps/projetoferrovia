# Monta tools/dados/eua.json a partir de eua_estacoes.py e das linhas abaixo.
# Uso: python tools/dados/montar_eua.py && node tools/dados/gerar.mjs
# Traçados simplificados (só as cidades principais); anos dos trechos aproximados: conferir antes do lançamento.
import json, os, sys

AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
from eua_estacoes import E  # noqa: E402


def T(pt, en):
    return {"pt": pt, "en": en}


TERRENOS = {
    "planicie": {"nome": "Planície", "nomeEn": "Plains", "custo": 1.0},
    "costa": {"nome": "Planície costeira", "nomeEn": "Coastal plain", "custo": 1.1},
    "vale": {"nome": "Vale", "nomeEn": "Valley", "custo": 1.2},
    "colinas": {"nome": "Colinas", "nomeEn": "Hills", "custo": 1.4},
    "apalaches": {"nome": "Apalaches", "nomeEn": "Appalachians", "custo": 1.7},
    "deserto": {"nome": "Deserto", "nomeEn": "Desert", "custo": 1.4},
    "pantano": {"nome": "Pântano", "nomeEn": "Swamp", "custo": 1.5},
    "montanhas": {"nome": "Montanhas", "nomeEn": "Mountains", "custo": 2.4},
    "ilhas": {"nome": "Ilhas e pontes sobre o mar", "nomeEn": "Islands and sea bridges", "custo": 3.0},
}

ESTADOS = {
    "MA": ["Massachusetts", "ne"], "NY": ["Nova York", "ne"], "PA": ["Pensilvânia", "ne"], "MD": ["Maryland", "s"],
    "WV": ["Virgínia Ocidental", "s"], "DC": ["Distrito de Colúmbia", "s"], "VA": ["Virgínia", "s"],
    "NC": ["Carolina do Norte", "s"], "SC": ["Carolina do Sul", "s"], "GA": ["Geórgia", "s"], "FL": ["Flórida", "s"],
    "KY": ["Kentucky", "s"], "TN": ["Tennessee", "s"], "AL": ["Alabama", "s"], "MS": ["Mississippi", "s"],
    "LA": ["Luisiana", "s"], "TX": ["Texas", "s"], "OH": ["Ohio", "mw"], "IN": ["Indiana", "mw"], "MI": ["Michigan", "mw"],
    "IL": ["Illinois", "mw"], "IA": ["Iowa", "mw"], "WI": ["Wisconsin", "mw"], "MN": ["Minnesota", "mw"],
    "MO": ["Missouri", "mw"], "KS": ["Kansas", "mw"], "NE": ["Nebraska", "mw"], "ND": ["Dakota do Norte", "mw"],
    "WY": ["Wyoming", "o"], "CO": ["Colorado", "o"], "UT": ["Utah", "o"], "ID": ["Idaho", "o"], "OR": ["Oregon", "o"],
    "WA": ["Washington", "o"], "MT": ["Montana", "o"], "NV": ["Nevada", "o"], "CA": ["Califórnia", "o"],
    "AZ": ["Arizona", "o"], "NM": ["Novo México", "o"],
}

REGIOES = {"ne": T("Nordeste", "Northeast"), "s": T("Sul", "South"), "mw": T("Meio-Oeste", "Midwest"), "o": T("Oeste", "West")}


def tr(de, para, ano, terreno, via=None):
    t = {"de": de, "para": para, "ano": ano, "terreno": terreno}
    if via:
        t["via"] = via
    return t


# (id, nome, ano, cor, degrau, trechos, nota, projeto)
LINHAS = [
    ("b_o", "Baltimore and Ohio", 1830, 2, 0, [
        tr("baltimore", "harpers_ferry", 1834, "vale"),
        tr("harpers_ferry", "cumberland", 1842, "apalaches"),
        tr("cumberland", "wheeling", 1853, "apalaches"),
    ], T("A primeira ferrovia comercial do país: Baltimore queria um caminho para o oeste e começou a cavar em 1828.",
         "The country's first commercial railroad: Baltimore wanted a road west and broke ground in 1828.")),
    ("sc_rr", "South Carolina Canal and Rail Road", 1833, 6, 0, [
        tr("charleston_sc", "augusta", 1833, "costa"),
    ], T("Em 1833 era a ferrovia mais longa do mundo. A locomotiva Best Friend of Charleston puxou o primeiro trem a vapor regular do país.",
         "In 1833 it was the longest railroad in the world. The Best Friend of Charleston locomotive pulled the country's first regular steam train.")),
    ("boston_albany", "Boston and Albany", 1841, 1, 1, [
        tr("boston", "worcester", 1835, "costa"),
        tr("worcester", "springfield_ma", 1839, "colinas"),
        tr("springfield_ma", "albany", 1841, "apalaches"),
    ], T("A Western Railroad cruzou as montanhas Berkshire em 1841 para levar a carga do Canal Erie até Boston.",
         "The Western Railroad crossed the Berkshire Mountains in 1841 to bring Erie Canal freight to Boston.")),
    ("erie", "Erie Railroad", 1851, 5, 1, [
        tr("new_york", "binghamton", 1848, "apalaches"),
        tr("binghamton", "buffalo", 1851, "colinas"),
    ], T("Quando terminou, em 1851, era a ferrovia mais longa do mundo, ligando o Hudson ao Lago Erie.",
         "When finished in 1851 it was the world's longest railroad, linking the Hudson to Lake Erie.")),
    ("pennsylvania", "Pennsylvania Railroad", 1854, 3, 2, [
        tr("philadelphia", "harrisburg", 1838, "colinas"),
        tr("harrisburg", "altoona", 1850, "vale"),
        tr("altoona", "pittsburgh", 1854, "apalaches"),
    ], T("A Curva da Ferradura, aberta em 1854, deixou os trens subirem os Apalaches sem planos inclinados.",
         "The Horseshoe Curve, opened in 1854, let trains climb the Appalachians without inclined planes.")),
    ("ny_central", "New York Central", 1853, 4, 2, [
        tr("new_york", "albany", 1851, "vale"),
        tr("albany", "syracuse", 1839, "vale"),
        tr("syracuse", "rochester", 1841, "planicie"),
        tr("rochester", "buffalo", 1842, "planicie"),
    ], T("A \"rota de nível d'água\": seguia o Hudson e o vale do Mohawk sem subir montanhas.",
         "The \"Water Level Route\": it followed the Hudson and the Mohawk Valley without climbing mountains.")),
    ("michigan_central", "Michigan Central", 1852, 8, 2, [
        tr("detroit", "kalamazoo", 1846, "planicie"),
        tr("kalamazoo", "chicago", 1852, "planicie"),
    ], T("Chegou a Chicago em 1852, uma das primeiras ligações do leste com a cidade.",
         "It reached Chicago in 1852, one of the first links between the East and the city.")),
    ("georgia", "Western and Atlantic", 1850, 7, 3, [
        tr("chattanooga", "atlanta", 1850, "apalaches"),
        tr("atlanta", "macon", 1846, "colinas"),
        tr("macon", "savannah", 1843, "costa"),
    ], T("Atlanta nasceu como ponta desta ferrovia do estado da Geórgia, em 1837.",
         "Atlanta was born as the end of this Georgia state railroad, in 1837.")),
    ("illinois_central", "Illinois Central", 1856, 2, 3, [
        tr("chicago", "centralia", 1856, "planicie"),
        tr("centralia", "cairo", 1856, "planicie"),
        tr("cairo", "memphis", 1873, "vale"),
        tr("memphis", "jackson_ms", 1882, "planicie"),
        tr("jackson_ms", "new_orleans", 1882, "pantano"),
    ], T("Primeira ferrovia com terras doadas pelo governo, em 1850. Abraham Lincoln foi advogado da companhia.",
         "The first railroad built on federal land grants, in 1850. Abraham Lincoln was one of its lawyers.")),
    ("cbq", "Chicago, Burlington and Quincy", 1864, 6, 3, [
        tr("chicago", "galesburg", 1854, "planicie"),
        tr("galesburg", "burlington", 1855, "planicie"),
        tr("burlington", "omaha", 1869, "planicie"),
    ], T("A Burlington levava os grãos das pradarias para Chicago e chegou a Omaha a tempo da Union Pacific.",
         "The Burlington carried prairie grain to Chicago and reached Omaha in time for the Union Pacific.")),
    ("pacific_mo", "Pacific Railroad (Missouri)", 1865, 1, 3, [
        tr("st_louis", "jefferson_city", 1855, "vale"),
        tr("jefferson_city", "kansas_city", 1865, "planicie"),
    ], T("Na viagem inaugural, em 1855, a ponte do rio Gasconade desabou. A linha só chegou a Kansas City depois da Guerra Civil.",
         "On the opening run in 1855, the Gasconade River bridge collapsed. The line only reached Kansas City after the Civil War.")),
    ("transcontinental", "Primeira Transcontinental", 1869, 4, 4, [
        tr("omaha", "north_platte", 1866, "planicie"),
        tr("north_platte", "cheyenne", 1867, "planicie"),
        tr("cheyenne", "ogden", 1869, "montanhas"),
        tr("ogden", "reno", 1869, "deserto"),
        tr("reno", "sacramento", 1868, "montanhas"),
        tr("sacramento", "san_francisco", 1869, "vale", [[-121.29, 37.95], [-121.9, 37.55], [-122.05, 37.42], [-122.3, 37.55]]),
    ], T("Union Pacific e Central Pacific se encontraram em Promontory, Utah, em 10 de maio de 1869, com um prego de ouro.",
         "The Union Pacific and the Central Pacific met at Promontory, Utah, on May 10, 1869, with a golden spike.")),
    ("l_n", "Louisville and Nashville", 1859, 3, 4, [
        tr("louisville", "nashville", 1859, "colinas"),
        tr("nashville", "birmingham", 1872, "apalaches"),
        tr("birmingham", "montgomery", 1872, "colinas"),
        tr("montgomery", "mobile", 1872, "pantano"),
    ], T("Uma das poucas ferrovias do Sul que saíram mais fortes da Guerra Civil; ajudou a criar Birmingham.",
         "One of the few Southern railroads to come out of the Civil War stronger; it helped create Birmingham.")),
    ("ches_ohio", "Chesapeake and Ohio", 1873, 5, 4, [
        tr("richmond", "charleston_wv", 1873, "apalaches"),
        tr("charleston_wv", "huntington", 1873, "vale"),
        tr("huntington", "cincinnati", 1888, "vale"),
    ], T("Collis Huntington, da Central Pacific, levou a C&O até o rio Ohio para escoar o carvão da Virgínia Ocidental.",
         "Collis Huntington, of the Central Pacific, pushed the C&O to the Ohio River to haul West Virginia coal.")),
    ("atlantic_coast", "Atlantic Coast Line", 1860, 8, 4, [
        tr("richmond", "wilmington", 1840, "costa"),
        tr("wilmington", "charleston_sc", 1856, "costa", [[-78.6, 34.3], [-79.2, 33.9], [-79.6, 33.3]]),
        tr("charleston_sc", "savannah", 1860, "pantano"),
        tr("savannah", "jacksonville", 1893, "costa"),
    ], T("Várias pequenas ferrovias do litoral viraram uma só, levando turistas e algodão de Richmond à Flórida.",
         "Several small coastal railroads became one, carrying tourists and cotton from Richmond to Florida.")),
    ("milwaukee_road", "Milwaukee Road", 1867, 7, 4, [
        tr("chicago", "milwaukee", 1855, "planicie"),
        tr("milwaukee", "minneapolis", 1867, "planicie"),
    ], T("A Chicago, Milwaukee and St. Paul ligou os moinhos de Minneapolis aos portos dos Grandes Lagos.",
         "The Chicago, Milwaukee and St. Paul linked the Minneapolis mills to the Great Lakes ports.")),
    ("santa_fe", "Atchison, Topeka and Santa Fe", 1887, 2, 5, [
        tr("kansas_city", "topeka", 1869, "planicie"),
        tr("topeka", "dodge_city", 1872, "planicie"),
        tr("dodge_city", "la_junta", 1875, "planicie"),
        tr("la_junta", "albuquerque", 1880, "montanhas"),
        tr("albuquerque", "flagstaff", 1882, "deserto"),
        tr("flagstaff", "barstow", 1883, "deserto"),
        tr("barstow", "los_angeles", 1887, "montanhas"),
    ], T("Seguiu a velha Trilha de Santa Fe e chegou a Los Angeles em 1887, provocando uma guerra de passagens com a Southern Pacific.",
         "It followed the old Santa Fe Trail and reached Los Angeles in 1887, sparking a fare war with the Southern Pacific.")),
    ("sunset", "Southern Pacific (Rota Sunset)", 1883, 6, 5, [
        tr("los_angeles", "tucson", 1880, "deserto"),
        tr("tucson", "el_paso", 1881, "deserto"),
        tr("el_paso", "san_antonio", 1883, "deserto"),
        tr("san_antonio", "houston", 1877, "planicie"),
        tr("houston", "new_orleans", 1880, "pantano"),
    ], T("A segunda transcontinental, pelo sul, terminada em 1883 entre Los Angeles e Nova Orleans.",
         "The second transcontinental, along the south, finished in 1883 between Los Angeles and New Orleans.")),
    ("northern_pacific", "Northern Pacific", 1883, 3, 5, [
        tr("minneapolis", "fargo", 1872, "planicie"),
        tr("fargo", "bismarck", 1873, "planicie"),
        tr("bismarck", "billings", 1882, "planicie"),
        tr("billings", "helena", 1883, "montanhas"),
        tr("helena", "spokane", 1883, "montanhas"),
        tr("spokane", "seattle", 1887, "montanhas"),
    ], T("A falência de 1873 parou a obra em Bismarck. Ela só ficou pronta em 1883, com um prego de ouro em Montana.",
         "Its 1873 bankruptcy halted work at Bismarck. It was only finished in 1883, with a golden spike in Montana.")),
    ("texas_pacific", "Texas and Pacific", 1881, 1, 5, [
        tr("shreveport", "dallas", 1873, "colinas"),
        tr("dallas", "fort_worth", 1876, "planicie"),
        tr("fort_worth", "abilene", 1881, "planicie"),
        tr("abilene", "el_paso", 1881, "deserto"),
    ], T("Era para chegar a San Diego, mas parou no oeste do Texas e se juntou à Southern Pacific em 1881.",
         "It was meant to reach San Diego, but stopped in West Texas and joined the Southern Pacific in 1881.")),
    ("denver_pacific", "Denver Pacific", 1870, 5, 5, [
        tr("cheyenne", "denver", 1870, "planicie"),
    ], T("A Union Pacific passou longe de Denver; a cidade construiu ela mesma o ramal até Cheyenne para não morrer.",
         "The Union Pacific bypassed Denver; the city built its own branch to Cheyenne so as not to wither away.")),
    ("denver_rg", "Denver and Rio Grande", 1883, 8, 6, [
        tr("denver", "colorado_springs", 1871, "planicie"),
        tr("colorado_springs", "pueblo", 1872, "planicie"),
        tr("pueblo", "grand_junction", 1882, "montanhas"),
        tr("grand_junction", "salt_lake", 1883, "deserto"),
    ], T("Ferrovia de bitola estreita que atravessou as Rochosas pelo Royal Gorge depois de uma guerra armada com a Santa Fe.",
         "A narrow-gauge railroad that crossed the Rockies through the Royal Gorge after an armed war with the Santa Fe.")),
    ("oregon_short_line", "Oregon Short Line", 1884, 7, 6, [
        tr("ogden", "pocatello", 1878, "montanhas"),
        tr("pocatello", "boise", 1884, "deserto"),
        tr("boise", "portland", 1884, "vale"),
    ], T("A Union Pacific ganhou seu caminho até o Pacífico Norte seguindo a velha Trilha do Oregon.",
         "The Union Pacific got its own way to the Pacific Northwest following the old Oregon Trail.")),
    ("shasta", "Southern Pacific (Rota Shasta)", 1887, 4, 6, [
        tr("portland", "eugene", 1871, "vale"),
        tr("eugene", "redding", 1887, "montanhas"),
        tr("redding", "sacramento", 1872, "vale"),
    ], T("Ligou a Califórnia ao Oregon em 1887, subindo as montanhas Siskiyou.",
         "It linked California to Oregon in 1887, climbing the Siskiyou Mountains.")),
    ("norfolk_western", "Norfolk and Western", 1883, 2, 6, [
        tr("norfolk", "lynchburg", 1858, "costa"),
        tr("lynchburg", "roanoke", 1882, "colinas"),
        tr("roanoke", "bluefield", 1883, "apalaches"),
    ], T("Carvão do campo Pocahontas até o porto de Norfolk: por décadas, uma das ferrovias mais lucrativas do país.",
         "Pocahontas coal to the port of Norfolk: for decades, one of the most profitable railroads in the country.")),
    ("southern_ry", "Southern Railway", 1894, 6, 6, [
        tr("washington", "lynchburg", 1860, "colinas"),
        tr("lynchburg", "charlotte", 1874, "colinas"),
        tr("charlotte", "atlanta", 1873, "colinas"),
    ], T("Formada em 1894 juntando ferrovias falidas do Sul; seu trem Crescent ia de Nova York a Nova Orleans.",
         "Formed in 1894 from bankrupt Southern lines; its Crescent train ran from New York to New Orleans.")),
    ("great_northern", "Great Northern", 1893, 1, 7, [
        tr("minneapolis", "grand_forks", 1880, "planicie"),
        tr("grand_forks", "minot", 1886, "planicie"),
        tr("minot", "havre", 1887, "planicie"),
        tr("havre", "spokane", 1892, "montanhas"),
        tr("spokane", "seattle", 1893, "montanhas"),
    ], T("James J. Hill a construiu sem terras do governo e sem falir: a única transcontinental privada de verdade.",
         "James J. Hill built it without government land grants and without going bankrupt: the only truly private transcontinental.")),
    ("fec", "Florida East Coast", 1912, 3, 7, [
        tr("jacksonville", "st_augustine", 1883, "costa"),
        tr("st_augustine", "daytona", 1886, "costa"),
        tr("daytona", "west_palm", 1894, "costa"),
        tr("west_palm", "miami", 1896, "costa"),
        tr("miami", "key_west", 1912, "ilhas", [[-80.45, 25.28], [-80.6, 25.0], [-80.95, 24.78], [-81.35, 24.66]]),
    ], T("Henry Flagler levou os trilhos até Key West em 1912, sobre pontes de ilha em ilha. Um furacão destruiu a linha em 1935.",
         "Henry Flagler carried the rails to Key West in 1912, on bridges from island to island. A hurricane destroyed the line in 1935.")),
    # ---------------------------------------------------------------- Gabinete de Projetos
    ("texas_central", "Texas Central", 2030, 5, 6, [
        tr("dallas", "houston", 2030, "planicie"),
    ], T("Trem-bala planejado entre Dallas e Houston, em 90 minutos, com tecnologia do Shinkansen japonês.",
         "A planned bullet train between Dallas and Houston in 90 minutes, using Japanese Shinkansen technology."), "texas_central"),
    ("chsr", "Alta Velocidade da Califórnia", 2033, 7, 7, [
        tr("san_francisco", "fresno", 2033, "vale", [[-122.38, 37.62], [-122.15, 37.45], [-121.89, 37.33], [-121.6, 37.0], [-120.9, 36.95]]),
        tr("fresno", "bakersfield", 2030, "vale"),
        tr("bakersfield", "los_angeles", 2033, "montanhas"),
    ], T("Aprovada pelos eleitores em 2008, a linha São Francisco–Los Angeles começou pelo Vale Central e segue em obras.",
         "Approved by voters in 2008, the San Francisco–Los Angeles line started in the Central Valley and is still under construction."), "chsr"),
    ("brightline_west", "Brightline West", 2028, 2, 7, [
        tr("las_vegas", "los_angeles", 2028, "deserto", [[-115.9, 35.6], [-116.9, 34.95], [-117.4, 34.3]]),
    ], T("Trem rápido de Las Vegas ao sul da Califórnia pelo canteiro da rodovia I-15, em obras desde 2024.",
         "A fast train from Las Vegas to Southern California along the I-15 median, under construction since 2024."), "brightline_west"),
    ("ne_maglev", "Maglev do Nordeste", 2040, 8, 8, [
        tr("washington", "baltimore", 2040, "costa"),
        tr("baltimore", "philadelphia", 2040, "costa"),
        tr("philadelphia", "new_york", 2040, "costa"),
    ], T("Trem de levitação magnética planejado de Washington a Baltimore; a extensão até Nova York é o sonho seguinte.",
         "A magnetic levitation train planned from Washington to Baltimore; the extension to New York is the next dream."), "ne_maglev"),
    ("midwest_hsr", "Trem-bala do Meio-Oeste", 2045, 4, 8, [
        tr("chicago", "indianapolis", 2045, "planicie"),
        tr("indianapolis", "cincinnati", 2045, "planicie"),
    ], T("E se Chicago fosse o centro de uma rede de trens-bala, como Paris na França?",
         "What if Chicago were the hub of a bullet-train network, like Paris in France?"), "midwest_hsr"),
]

PROJETOS = [
    {"id": "texas_central", "nome": "Texas Central", "emoji": "velocidade", "custo": 2500000, "minutos": 15,
     "requer": {"era": "eletrico"},
     "descricao": T("Trem-bala entre Dallas e Houston, planejado nos anos 2010 com a tecnologia do Shinkansen. Esbarrou em fazendeiros e na Justiça.",
                    "A bullet train between Dallas and Houston, planned in the 2010s with Shinkansen technology. It ran into landowners and the courts.")},
    {"id": "chsr", "nome": "Alta Velocidade da Califórnia", "emoji": "velocidade", "custo": 8000000, "minutos": 25,
     "requer": {"era": "eletrico", "linhasCompletas": 14},
     "descricao": T("São Francisco a Los Angeles em menos de 3 horas. As obras começaram em 2015 e seguem no Vale Central.",
                    "San Francisco to Los Angeles in under 3 hours. Construction began in 2015 and continues in the Central Valley.")},
    {"id": "brightline_west", "nome": "Brightline West", "emoji": "velocidade", "custo": 12000000, "minutos": 30,
     "requer": {"era": "alta", "projeto": "chsr"},
     "descricao": T("Trem rápido privado de Las Vegas até o sul da Califórnia, pelo meio da rodovia I-15.",
                    "A private fast train from Las Vegas to Southern California, along the middle of the I-15 highway.")},
    {"id": "ne_maglev", "nome": "Maglev do Nordeste", "emoji": "velocidade", "custo": 30000000, "minutos": 35,
     "requer": {"era": "alta", "linhasCompletas": 20},
     "descricao": T("Trem de levitação magnética de Washington a Nova York em uma hora. Hoje só existe no papel.",
                    "A magnetic levitation train from Washington to New York in one hour. Today it only exists on paper.")},
    {"id": "midwest_hsr", "nome": "Trem-bala do Meio-Oeste", "emoji": "velocidade", "custo": 40000000, "minutos": 40, "ficticio": True,
     "requer": {"era": "alta", "projeto": "ne_maglev"},
     "descricao": T("E se? Uma rede de trens-bala saindo de Chicago para as cidades do Meio-Oeste.",
                    "What if? A bullet-train network radiating from Chicago to the Midwestern cities.")},
]


def rot(tipo, pt, en, lon, lat, zmin=0, zmax=None, ang=None):
    r = {"tipo": tipo, "texto": pt, "textoEn": en, "lon": lon, "lat": lat, "zoomMin": zmin}
    if zmax is not None:
        r["zoomMax"] = zmax
    if ang is not None:
        r["angulo"] = ang
    return r


ROTULOS = [
    rot("estado", "CALIFÓRNIA", "CALIFORNIA", -119.6, 37.2, ang=-28, zmax=4),
    rot("estado", "OREGON", "OREGON", -120.5, 44.0, zmax=4),
    rot("estado", "WASHINGTON", "WASHINGTON", -120.5, 47.4, zmax=4),
    rot("estado", "NEVADA", "NEVADA", -116.8, 39.3, zmax=4),
    rot("estado", "IDAHO", "IDAHO", -114.6, 44.4, zmax=4),
    rot("estado", "MONTANA", "MONTANA", -109.6, 47.0, zmax=4),
    rot("estado", "WYOMING", "WYOMING", -107.5, 43.0, zmax=4),
    rot("estado", "UTAH", "UTAH", -111.7, 39.4, zmax=4),
    rot("estado", "ARIZONA", "ARIZONA", -111.7, 34.3, zmax=4),
    rot("estado", "COLORADO", "COLORADO", -105.6, 39.0, zmax=4),
    rot("estado", "NOVO MÉXICO", "NEW MEXICO", -106.1, 34.4, zmax=4),
    rot("estado", "TEXAS", "TEXAS", -99.3, 31.3, zmax=4),
    rot("estado", "DAKOTA DO NORTE", "NORTH DAKOTA", -100.5, 47.5, zmax=4),
    rot("estado", "DAKOTA DO SUL", "SOUTH DAKOTA", -100.2, 44.4, zmax=4),
    rot("estado", "NEBRASKA", "NEBRASKA", -99.8, 41.5, zmax=4),
    rot("estado", "KANSAS", "KANSAS", -98.4, 38.5, zmax=4),
    rot("estado", "OKLAHOMA", "OKLAHOMA", -97.5, 35.6, zmax=4),
    rot("estado", "MINNESOTA", "MINNESOTA", -94.3, 46.3, zmax=4),
    rot("estado", "IOWA", "IOWA", -93.5, 42.0, zmax=4),
    rot("estado", "MISSOURI", "MISSOURI", -92.5, 38.4, zmax=4),
    rot("estado", "ARKANSAS", "ARKANSAS", -92.4, 34.8, zmax=4),
    rot("estado", "LUISIANA", "LOUISIANA", -92.2, 31.0, zmax=4),
    rot("estado", "WISCONSIN", "WISCONSIN", -89.8, 44.6, zmax=4),
    rot("estado", "ILLINOIS", "ILLINOIS", -89.2, 40.0, zmax=4),
    rot("estado", "MISSISSIPPI", "MISSISSIPPI", -89.7, 32.7, zmax=4),
    rot("estado", "MICHIGAN", "MICHIGAN", -84.7, 43.6, zmax=4),
    rot("estado", "INDIANA", "INDIANA", -86.3, 39.9, zmax=4),
    rot("estado", "OHIO", "OHIO", -82.8, 40.3, zmax=4),
    rot("estado", "KENTUCKY", "KENTUCKY", -85.3, 37.5, zmax=4),
    rot("estado", "TENNESSEE", "TENNESSEE", -86.3, 35.8, zmax=4),
    rot("estado", "ALABAMA", "ALABAMA", -86.8, 32.8, zmax=4),
    rot("estado", "GEÓRGIA", "GEORGIA", -83.5, 32.6, zmax=4),
    rot("estado", "FLÓRIDA", "FLORIDA", -81.6, 28.3, zmax=4),
    rot("estado", "CAROLINA DO SUL", "SOUTH CAROLINA", -80.9, 33.9, zmin=1.2, zmax=4),
    rot("estado", "CAROLINA DO NORTE", "NORTH CAROLINA", -79.4, 35.6, zmin=1.2, zmax=4),
    rot("estado", "VIRGÍNIA", "VIRGINIA", -78.7, 37.6, zmin=1.2, zmax=4),
    rot("estado", "PENSILVÂNIA", "PENNSYLVANIA", -77.6, 40.9, zmin=1.2, zmax=4),
    rot("estado", "NOVA YORK", "NEW YORK", -75.5, 43.0, zmin=1.2, zmax=4),
    rot("oceano", "OCEANO PACÍFICO", "PACIFIC OCEAN", -126.5, 38.0, ang=-75, zmax=1.2),
    rot("oceano", "OCEANO PACÍFICO", "PACIFIC OCEAN", -124.5, 35.0, zmin=1.2),
    rot("oceano", "OCEANO ATLÂNTICO", "ATLANTIC OCEAN", -71.5, 34.0, ang=-50),
    rot("oceano", "GOLFO DO MÉXICO", "GULF OF MEXICO", -89.5, 26.6),
    rot("regiao", "Grandes Planícies", "Great Plains", -101.5, 40.2, zmin=0.9),
    rot("regiao", "Montanhas Rochosas", "Rocky Mountains", -107.2, 41.0, zmin=0.9, ang=-35),
    rot("regiao", "Apalaches", "Appalachians", -80.3, 38.0, zmin=0.9, ang=-40),
    rot("regiao", "Deserto de Mojave", "Mojave Desert", -116.2, 35.0, zmin=1.2),
    rot("regiao", "Serra Nevada", "Sierra Nevada", -119.4, 38.0, zmin=1.2, ang=-55),
    rot("regiao", "Grandes Lagos", "Great Lakes", -84.0, 45.6, zmin=0.9),
    rot("rio", "Rio Mississippi", "Mississippi River", -91.2, 33.8, zmin=0.6, ang=-80),
    rot("rio", "Rio Missouri", "Missouri River", -97.5, 42.9, zmin=0.9, ang=-30),
    rot("rio", "Rio Ohio", "Ohio River", -86.6, 37.9, zmin=0.9, ang=-15),
    rot("rio", "Rio Colorado", "Colorado River", -113.9, 35.9, zmin=0.9, ang=-60),
    rot("rio", "Rio Columbia", "Columbia River", -120.3, 45.9, zmin=0.9, ang=-10),
    rot("rio", "Rio Grande", "Rio Grande", -103.6, 29.6, zmin=0.9, ang=35),
]

# Nomes que mudam em inglês (estações, linhas e projetos).
NOMES_EN = {
    "new_york": "New York", "philadelphia": "Philadelphia", "san_francisco": "San Francisco",
    "new_orleans": "New Orleans", "indianapolis": "Indianapolis", "charleston_wv": "Charleston (West Virginia)",
    "transcontinental": "First Transcontinental", "sunset": "Southern Pacific (Sunset Route)",
    "shasta": "Southern Pacific (Shasta Route)", "chsr": "California High-Speed Rail", "ne_maglev": "Northeast Maglev",
    "midwest_hsr": "Midwest Bullet Train", "pacific_mo": "Pacific Railroad (Missouri)",
}

estacoes = []
for (eid, nome, lon, lat, porte, produz, porto, paisagem, uf, hpt, hen) in E:
    e = {"id": eid, "nome": nome, "lon": lon, "lat": lat, "porte": porte, "uf": uf, "historia": T(hpt, hen)}
    if eid in NOMES_EN:
        e["nomeEn"] = NOMES_EN[eid]
    if produz:
        e["produz"] = produz
    if porto:
        e["porto"] = True
    if paisagem:
        e["paisagem"] = paisagem
    estacoes.append(e)

linhas = []
for item in LINHAS:
    lid, nome, ano, cor, degrau, trechos, nota = item[:7]
    l = {"id": lid, "nome": nome, "ano": ano, "cor": cor, "trechos": trechos, "degrau": degrau, "nota": nota}
    if lid in NOMES_EN:
        l["nomeEn"] = NOMES_EN[lid]
    if len(item) > 7:
        l["projeto"] = item[7]
    linhas.append(l)

for p in PROJETOS:
    if p["id"] in NOMES_EN:
        p["nomeEn"] = NOMES_EN[p["id"]]

dados = {
    "_nota": "Fonte do mapa dos EUA, gerada por montar_eua.py (edite lá, não aqui). Depois rode `node tools/dados/gerar.mjs`.",
    "anos": {"vapor": [1830, 1935], "diesel": [1935, 1970], "eletrico": [1970, 2000], "alta": [2000, 2040]},
    "terrenos": TERRENOS,
    "estacoes": estacoes,
    "linhas": linhas,
    "rotulos": ROTULOS,
    "projetos": PROJETOS,
    "foco": ["b_o", "sc_rr", "boston_albany", "erie"],
    "estados": ESTADOS,
    "regioes": REGIOES,
}
with open(os.path.join(AQUI, "eua.json"), "w", encoding="utf-8") as f:
    json.dump(dados, f, ensure_ascii=False, indent=2)
print(f"eua.json: {len(estacoes)} estações, {len(linhas)} linhas, {sum(len(l['trechos']) for l in linhas)} trechos")
