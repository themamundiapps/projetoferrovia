# Créditos e licenças das imagens das cidades

As ilustrações da Era do Vapor (`arte/cidades/<cidade>.png/jpg`) foram geradas por IA pelo estúdio e não precisam de crédito.
As fotos das outras eras vêm do Wikimedia Commons, com licença livre para uso comercial (domínio público, CC0, CC BY,
CC BY-SA ou "atribuição"; nada de NC nem ND). Elas não ficam no repositório: `python tools/assetgen/baixar_commons.py`
baixa as miniaturas (960 px) para `arte/cidades_jogo/` a partir de `tools/assetgen/fotos_commons.json`.

**Antes de publicar:** as licenças CC BY, CC BY-SA e "atribuição" pedem crédito (autor, licença e link), que vai numa
tela de créditos do jogo (Ajustes › Créditos). As CC BY-SA pedem ainda que a versão recortada fique na mesma licença.
A tela lê `src/shared/Creditos.luau`, gerado desta tabela: depois de mudar a tabela, rode
`python tools/assetgen/gerar_creditos.py`. O jogo não mostra links (regra do Roblox); os links ficam aqui e podem ir na
descrição do jogo.

| Cidade | Era | Foto (página no Commons) | Data | Autor | Licença |
|---|---|---|---|---|---|
| Rio de Janeiro | Diesel | [Az_Avenida_Atlântica_(Copacabana)_a_Rua_Sousa_Lima_torkolatánál._Fortepan_74395.jpg](https://commons.wikimedia.org/wiki/File:Az_Avenida_Atl%C3%A2ntica_%28Copacabana%29_a_Rua_Sousa_Lima_torkolat%C3%A1n%C3%A1l._Fortepan_74395.jpg) | 1965 | Fortepan / Romák Éva | CC BY-SA 3.0 |
| Rio de Janeiro | Alta Velocidade | [1_leblon_aerial_2014.jpg](https://commons.wikimedia.org/wiki/File:1_leblon_aerial_2014.jpg) | 2014 | Chensiyuan | CC BY-SA 4.0 |
| São Paulo | Elétrica | [Downtown_São_Paulo.jpg](https://commons.wikimedia.org/wiki/File:Downtown_S%C3%A3o_Paulo.jpg) | 1971 | Roger Wollstadt | CC BY-SA 2.0 |
| São Paulo | Alta Velocidade | [São_Paulo_vista_do_MAC-USP.jpg](https://commons.wikimedia.org/wiki/File:S%C3%A3o_Paulo_vista_do_MAC-USP.jpg) | 2025 | Boaventuravinicius | CC BY 4.0 |
| Belo Horizonte | Diesel | [Antiga_praça_da_Savassi.jpeg](https://commons.wikimedia.org/wiki/File:Antiga_pra%C3%A7a_da_Savassi.jpeg) | 1946 | Prefeitura de Belo Horizonte | domínio público |
| Belo Horizonte | Elétrica | [Belo_Horizonte,_Fundo_Correio_da_Manhã_-_2.tif](https://commons.wikimedia.org/wiki/File:Belo_Horizonte%2C_Fundo_Correio_da_Manh%C3%A3_-_2.tif) | 1972 | Correio da Manhã / Arquivo Nacional | domínio público |
| Belo Horizonte | Alta Velocidade | [منظر_عام_لمدينة_بيلوهوريزونتي_البرازيلية.jpg](https://commons.wikimedia.org/wiki/File:%D9%85%D9%86%D8%B8%D8%B1_%D8%B9%D8%A7%D9%85_%D9%84%D9%85%D8%AF%D9%8A%D9%86%D8%A9_%D8%A8%D9%8A%D9%84%D9%88%D9%87%D9%88%D8%B1%D9%8A%D8%B2%D9%88%D9%86%D8%AA%D9%8A_%D8%A7%D9%84%D8%A8%D8%B1%D8%A7%D8%B2%D9%8A%D9%84%D9%8A%D8%A9.jpg) | 2017 | Sambasoccer27 | CC BY-SA 4.0 |
| Recife | Diesel | [Recife,_Fundo_Correio_da_Manhã.tif](https://commons.wikimedia.org/wiki/File:Recife%2C_Fundo_Correio_da_Manh%C3%A3.tif) | 1969 | Correio da Manhã / Arquivo Nacional | domínio público |
| Recife | Elétrica | [Recife,_Fundo_Correio_da_Manhã_-_3.tif](https://commons.wikimedia.org/wiki/File:Recife%2C_Fundo_Correio_da_Manh%C3%A3_-_3.tif) | 1972 | Correio da Manhã / Arquivo Nacional | domínio público |
| Recife | Alta Velocidade | [Galpões_abandonados_-_Recife,_Pernambuco,_Brasil.jpg](https://commons.wikimedia.org/wiki/File:Galp%C3%B5es_abandonados_-_Recife%2C_Pernambuco%2C_Brasil.jpg) | 2012 | Direitos Urbanos | CC BY 2.0 |
| Salvador | Elétrica | [Salvador_decada_70_porto_da_barra.jpg](https://commons.wikimedia.org/wiki/File:Salvador_decada_70_porto_da_barra.jpg) | c. 1975 | André Koehne | CC BY-SA 4.0 |
| Salvador | Alta Velocidade | [Webysther_20150907165153_-_Mercado_modelo_e_baia_de_todos_os_santos.jpg](https://commons.wikimedia.org/wiki/File:Webysther_20150907165153_-_Mercado_modelo_e_baia_de_todos_os_santos.jpg) | 2015 | Webysther | CC BY-SA 4.0 |
| Curitiba | Diesel | [Praca_rui_barbosa_curitiba_anos_1960.jpg](https://commons.wikimedia.org/wiki/File:Praca_rui_barbosa_curitiba_anos_1960.jpg) | 1960 | autor não identificado | domínio público |
| Curitiba | Alta Velocidade | [Vista_da_Torre_das_Mercês_em_Curitiba_-_Brasil._(10160328624).jpg](https://commons.wikimedia.org/wiki/File:Vista_da_Torre_das_Merc%C3%AAs_em_Curitiba_-_Brasil._%2810160328624%29.jpg) | 2013 | Marinelson Almeida | CC BY 2.0 |
| Porto Alegre | Alta Velocidade | [FSA1310_Vista_do_Shopping_Pontal.jpg](https://commons.wikimedia.org/wiki/File:FSA1310_Vista_do_Shopping_Pontal.jpg) | 2026 | Fernando Antunes / CMPA | Atribuição |
| Belém | Alta Velocidade | [A_panoramic_view_of_the_historic_center_of_Belém_do_Pará.jpg](https://commons.wikimedia.org/wiki/File:A_panoramic_view_of_the_historic_center_of_Bel%C3%A9m_do_Par%C3%A1.jpg) | 2023 | Rafaelbyphoto | CC BY 4.0 |
| Manaus | Alta Velocidade | [Teatro_Amazonas_-_Vista_Aérea.jpg](https://commons.wikimedia.org/wiki/File:Teatro_Amazonas_-_Vista_A%C3%A9rea.jpg) | 2013 | José Zamith | CC BY 3.0 BR |
| Brasília | Diesel | [Vista_do_aeroporto_de_Brasília_-_BR_RJANRIO_PH_0_FOT_05962_0001,_Acervo_do_Arquivo_Nacional.jpg](https://commons.wikimedia.org/wiki/File:Vista_do_aeroporto_de_Bras%C3%ADlia_-_BR_RJANRIO_PH_0_FOT_05962_0001%2C_Acervo_do_Arquivo_Nacional.jpg) | anos 1960 | Arquivo Nacional | domínio público |
| Brasília | Elétrica | [Brasilia,_Brazil_(28252970275).jpg](https://commons.wikimedia.org/wiki/File:Brasilia%2C_Brazil_%2828252970275%29.jpg) | 1975 | Urbain J. Kinet | sem restrições conhecidas |
| Brasília | Alta Velocidade | [RobertoCastro_Vista_Aérea_Brasilia_DF_(39098940290).jpg](https://commons.wikimedia.org/wiki/File:RobertoCastro_Vista_A%C3%A9rea_Brasilia_DF_%2839098940290%29.jpg) | 2018 | Roberto Castro / MTur Destinos | domínio público |
| Fortaleza | Elétrica | [Avenida_Beira_Mar_-_Fortaleza-_1980.jpg](https://commons.wikimedia.org/wiki/File:Avenida_Beira_Mar_-_Fortaleza-_1980.jpg) | 1980 | Francisco Marinho de Andrade | CC BY 3.0 |
| Fortaleza | Alta Velocidade | [Skyline_de_Fortaleza.jpg](https://commons.wikimedia.org/wiki/File:Skyline_de_Fortaleza.jpg) | 2008 | Ricardo | CC BY 2.0 |
| Juiz de Fora | Alta Velocidade | [Vista_do_centro_de_Juiz_de_Fora-MG.JPG](https://commons.wikimedia.org/wiki/File:Vista_do_centro_de_Juiz_de_Fora-MG.JPG) | 2009 | Rcandre | CC BY-SA 4.0 |
| Santos | Alta Velocidade | [Santos_skyline.jpg](https://commons.wikimedia.org/wiki/File:Santos_skyline.jpg) | 2013 | Leguth Edson | CC BY-SA 3.0 |
| Campinas | Diesel | [Vista_aérea_de_Campinas.jpg](https://commons.wikimedia.org/wiki/File:Vista_a%C3%A9rea_de_Campinas.jpg) | 1963 | autor não identificado | CC BY-SA 4.0 |
| Campinas | Alta Velocidade | [Campinas_-_SP_-_Jardim_Proença_visto_da_Rua_Proença.JPG](https://commons.wikimedia.org/wiki/File:Campinas_-_SP_-_Jardim_Proen%C3%A7a_visto_da_Rua_Proen%C3%A7a.JPG) | 2007 | Fasouzafreitas | CC BY-SA 3.0 |
| Vitória | Alta Velocidade | [2018-12-04_-_Vitória_-_043.jpg](https://commons.wikimedia.org/wiki/File:2018-12-04_-_Vit%C3%B3ria_-_043.jpg) | 2018 | Oleg Yunakov | CC BY-SA 4.0 |
| São José dos Campos | Alta Velocidade | [View_of_São_Jose_dos_Campos_2017_01.jpg](https://commons.wikimedia.org/wiki/File:View_of_S%C3%A3o_Jose_dos_Campos_2017_01.jpg) | 2017 | Mike Peel (www.mikepeel.net) | CC BY-SA 4.0 |
| Sorocaba | Alta Velocidade | [Vila_Carvalho_-_Sorocaba.jpg](https://commons.wikimedia.org/wiki/File:Vila_Carvalho_-_Sorocaba.jpg) | 2008 | Frederico Cintra | CC BY 2.0 |
| Ponta Grossa | Alta Velocidade | [Ponta_Grossa-Paraná-Brasil.jpg](https://commons.wikimedia.org/wiki/File:Ponta_Grossa-Paran%C3%A1-Brasil.jpg) | 2017 | Gabriel N.12345678 | CC BY-SA 4.0 |
| Santa Maria | Alta Velocidade | [Vista_de_Santa_Maria_(RS).jpg](https://commons.wikimedia.org/wiki/File:Vista_de_Santa_Maria_%28RS%29.jpg) | 2008 | Clube Trekking Santa Maria | CC BY 2.0 |
| Campo Grande | Alta Velocidade | [VA_Pq_das_Nações_Indígenas.jpg](https://commons.wikimedia.org/wiki/File:VA_Pq_das_Na%C3%A7%C3%B5es_Ind%C3%ADgenas.jpg) | 2018 | Flavio Andre / MTur Destinos | Atribuição |
| Florianópolis | Alta Velocidade | [Um_panorama_de_história_-_Ponte_Hercílio_Luz_2.jpg](https://commons.wikimedia.org/wiki/File:Um_panorama_de_hist%C3%B3ria_-_Ponte_Herc%C3%ADlio_Luz_2.jpg) | 2015 | Alfabilesantana | CC BY-SA 4.0 |
| Maceió | Alta Velocidade | [Praia_Pajuçara_Maceió_04_2015_3254.JPG](https://commons.wikimedia.org/wiki/File:Praia_Paju%C3%A7ara_Macei%C3%B3_04_2015_3254.JPG) | 2015 | Mariordo (Mario Roberto Durán Ortiz) | CC BY-SA 4.0 |
| Natal | Alta Velocidade | [Natal,_capital_do_Rio_Grande_do_Norte,_Brasil.jpg](https://commons.wikimedia.org/wiki/File:Natal%2C_capital_do_Rio_Grande_do_Norte%2C_Brasil.jpg) | 2018 | Ney Douglas / MTur Destinos | Atribuição |

Cidades e eras sem foto livre encontrada usam a imagem da era anterior mais próxima (no fim, a ilustração do Vapor).
Pela Lei 9.610/98 (art. 44), fotos ficam protegidas por 70 anos contados de 1º de janeiro do ano seguinte ao da
divulgação: foto antiga não é livre só por ser antiga; vale a licença da página no Commons.
