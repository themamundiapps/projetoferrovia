--!strict
-- Créditos das fotos das cidades (Wikimedia Commons).
-- GERADO por tools/assetgen/gerar_creditos.py a partir de arte/cidades/CREDITOS.md: não editar à mão.

export type Credito = { cidade: string, era: string, ano: string, autor: string, licenca: string, arquivo: string }

local Creditos: { Credito } = {
	{ cidade = "Rio de Janeiro", era = "Diesel", ano = "1965", autor = "Fortepan / Romák Éva", licenca = "CC BY-SA 3.0", arquivo = "Az Avenida Atlântica (Copacabana) a Rua Sousa Lima torkolatánál. Fortepan 74395.jpg" },
	{ cidade = "Rio de Janeiro", era = "Alta Velocidade", ano = "2014", autor = "Chensiyuan", licenca = "CC BY-SA 4.0", arquivo = "1 leblon aerial 2014.jpg" },
	{ cidade = "São Paulo", era = "Elétrica", ano = "1971", autor = "Roger Wollstadt", licenca = "CC BY-SA 2.0", arquivo = "Downtown São Paulo.jpg" },
	{ cidade = "São Paulo", era = "Alta Velocidade", ano = "2025", autor = "Boaventuravinicius", licenca = "CC BY 4.0", arquivo = "São Paulo vista do MAC-USP.jpg" },
	{ cidade = "Belo Horizonte", era = "Diesel", ano = "1946", autor = "Prefeitura de Belo Horizonte", licenca = "domínio público", arquivo = "Antiga praça da Savassi.jpeg" },
	{ cidade = "Belo Horizonte", era = "Elétrica", ano = "1972", autor = "Correio da Manhã / Arquivo Nacional", licenca = "domínio público", arquivo = "Belo Horizonte, Fundo Correio da Manhã - 2.tif" },
	{ cidade = "Belo Horizonte", era = "Alta Velocidade", ano = "2017", autor = "Sambasoccer27", licenca = "CC BY-SA 4.0", arquivo = "منظر عام لمدينة بيلوهوريزونتي البرازيلية.jpg" },
	{ cidade = "Recife", era = "Diesel", ano = "1969", autor = "Correio da Manhã / Arquivo Nacional", licenca = "domínio público", arquivo = "Recife, Fundo Correio da Manhã.tif" },
	{ cidade = "Recife", era = "Elétrica", ano = "1972", autor = "Correio da Manhã / Arquivo Nacional", licenca = "domínio público", arquivo = "Recife, Fundo Correio da Manhã - 3.tif" },
	{ cidade = "Recife", era = "Alta Velocidade", ano = "2012", autor = "Direitos Urbanos", licenca = "CC BY 2.0", arquivo = "Galpões abandonados - Recife, Pernambuco, Brasil.jpg" },
	{ cidade = "Salvador", era = "Elétrica", ano = "c. 1975", autor = "André Koehne", licenca = "CC BY-SA 4.0", arquivo = "Salvador decada 70 porto da barra.jpg" },
	{ cidade = "Salvador", era = "Alta Velocidade", ano = "2015", autor = "Webysther", licenca = "CC BY-SA 4.0", arquivo = "Webysther 20150907165153 - Mercado modelo e baia de todos os santos.jpg" },
	{ cidade = "Curitiba", era = "Diesel", ano = "1960", autor = "autor não identificado", licenca = "domínio público", arquivo = "Praca rui barbosa curitiba anos 1960.jpg" },
	{ cidade = "Curitiba", era = "Alta Velocidade", ano = "2013", autor = "Marinelson Almeida", licenca = "CC BY 2.0", arquivo = "Vista da Torre das Mercês em Curitiba - Brasil. (10160328624).jpg" },
	{ cidade = "Porto Alegre", era = "Alta Velocidade", ano = "2026", autor = "Fernando Antunes / CMPA", licenca = "Atribuição", arquivo = "FSA1310 Vista do Shopping Pontal.jpg" },
	{ cidade = "Belém", era = "Alta Velocidade", ano = "2023", autor = "Rafaelbyphoto", licenca = "CC BY 4.0", arquivo = "A panoramic view of the historic center of Belém do Pará.jpg" },
	{ cidade = "Manaus", era = "Alta Velocidade", ano = "2013", autor = "José Zamith", licenca = "CC BY 3.0 BR", arquivo = "Teatro Amazonas - Vista Aérea.jpg" },
	{ cidade = "Brasília", era = "Diesel", ano = "anos 1960", autor = "Arquivo Nacional", licenca = "domínio público", arquivo = "Vista do aeroporto de Brasília - BR RJANRIO PH 0 FOT 05962 0001, Acervo do Arquivo Nacional.jpg" },
	{ cidade = "Brasília", era = "Elétrica", ano = "1975", autor = "Urbain J. Kinet", licenca = "sem restrições conhecidas", arquivo = "Brasilia, Brazil (28252970275).jpg" },
	{ cidade = "Brasília", era = "Alta Velocidade", ano = "2018", autor = "Roberto Castro / MTur Destinos", licenca = "domínio público", arquivo = "RobertoCastro Vista Aérea Brasilia DF (39098940290).jpg" },
	{ cidade = "Fortaleza", era = "Elétrica", ano = "1980", autor = "Francisco Marinho de Andrade", licenca = "CC BY 3.0", arquivo = "Avenida Beira Mar - Fortaleza- 1980.jpg" },
	{ cidade = "Fortaleza", era = "Alta Velocidade", ano = "2008", autor = "Ricardo", licenca = "CC BY 2.0", arquivo = "Skyline de Fortaleza.jpg" },
	{ cidade = "Juiz de Fora", era = "Alta Velocidade", ano = "2009", autor = "Rcandre", licenca = "CC BY-SA 4.0", arquivo = "Vista do centro de Juiz de Fora-MG.JPG" },
	{ cidade = "Santos", era = "Alta Velocidade", ano = "2013", autor = "Leguth Edson", licenca = "CC BY-SA 3.0", arquivo = "Santos skyline.jpg" },
	{ cidade = "Campinas", era = "Diesel", ano = "1963", autor = "autor não identificado", licenca = "CC BY-SA 4.0", arquivo = "Vista aérea de Campinas.jpg" },
	{ cidade = "Campinas", era = "Alta Velocidade", ano = "2007", autor = "Fasouzafreitas", licenca = "CC BY-SA 3.0", arquivo = "Campinas - SP - Jardim Proença visto da Rua Proença.JPG" },
	{ cidade = "Vitória", era = "Alta Velocidade", ano = "2018", autor = "Oleg Yunakov", licenca = "CC BY-SA 4.0", arquivo = "2018-12-04 - Vitória - 043.jpg" },
	{ cidade = "São José dos Campos", era = "Alta Velocidade", ano = "2017", autor = "Mike Peel (www.mikepeel.net)", licenca = "CC BY-SA 4.0", arquivo = "View of São Jose dos Campos 2017 01.jpg" },
	{ cidade = "Sorocaba", era = "Alta Velocidade", ano = "2008", autor = "Frederico Cintra", licenca = "CC BY 2.0", arquivo = "Vila Carvalho - Sorocaba.jpg" },
	{ cidade = "Ponta Grossa", era = "Alta Velocidade", ano = "2017", autor = "Gabriel N.12345678", licenca = "CC BY-SA 4.0", arquivo = "Ponta Grossa-Paraná-Brasil.jpg" },
	{ cidade = "Santa Maria", era = "Alta Velocidade", ano = "2008", autor = "Clube Trekking Santa Maria", licenca = "CC BY 2.0", arquivo = "Vista de Santa Maria (RS).jpg" },
	{ cidade = "Campo Grande", era = "Alta Velocidade", ano = "2018", autor = "Flavio Andre / MTur Destinos", licenca = "Atribuição", arquivo = "VA Pq das Nações Indígenas.jpg" },
	{ cidade = "Florianópolis", era = "Alta Velocidade", ano = "2015", autor = "Alfabilesantana", licenca = "CC BY-SA 4.0", arquivo = "Um panorama de história - Ponte Hercílio Luz 2.jpg" },
	{ cidade = "Maceió", era = "Alta Velocidade", ano = "2015", autor = "Mariordo (Mario Roberto Durán Ortiz)", licenca = "CC BY-SA 4.0", arquivo = "Praia Pajuçara Maceió 04 2015 3254.JPG" },
	{ cidade = "Natal", era = "Alta Velocidade", ano = "2018", autor = "Ney Douglas / MTur Destinos", licenca = "Atribuição", arquivo = "Natal, capital do Rio Grande do Norte, Brasil.jpg" },
}

return Creditos
