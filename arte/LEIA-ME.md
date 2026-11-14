# Ferrovia Tycoon — pacote gráfico v2 (ícones em emoji)

Direção visual: **A · Vintage evoluindo pelas eras** (Vapor → Diesel → Elétrica → Alta Velocidade).
Veja `guia_visual.png` para as 4 eras lado a lado e `emojis.png` para a lista completa de emojis.

**O que mudou da v1:** os 51 ícones desenhados (pasta `icones/` e `atlas/`) saíram e viraram emojis, definidos em `src/shared/Emojis.luau`. Mapas, trens, molduras, marcadores, texturas e identidade continuam iguais.

## A regra principal: imagens brancas, cor por código

Quase todas as imagens são **brancas com transparência**. No Roblox, a cor vem do `ImageColor3`, com a cor da era atual (`Theme.lua`). Assim **um único upload serve para as 4 eras**, e trocar de era é só trocar as cores, sem novas imagens.

Exceções: a pasta `identidade/` (logo, ícone do jogo e thumbnail) já vem colorida, e os emojis têm cor própria (veja abaixo).

## O que tem em cada pasta

| Pasta | Conteúdo | Sobe pro Roblox? |
| --- | --- | --- |
| `mapas/brasil`, `mapas/eua`, `mapas/europa` | Mapas base em blocos de 1024 px. Duas camadas por mapa: `terra` e `linhas` | Sim (8 por mapa, 24 no total) |
| `trens/` | Silhuetas laterais das 4 eras (512×192) | Sim |
| `molduras/` | Molduras 9-slice, sombra, brilho, pílula, picotado, tracejado | Sim |
| `marcadores/` | Estação (miolo + aro), estação fechada, seleção, badge da linha, ficha do trem, carimbo | Sim |
| `texturas/` | Mar (hachura, ondas, pontos), grão de papel, vinheta | Sim |
| `identidade/` | Logo colorido e branco, ícone do jogo 512, thumbnail 1920×1080 | Logos sim; ícone e thumbnail vão na página do jogo |
| `src/shared/` (no repositório) | `Theme.lua`, `Assets.lua`, `Mapas.lua`, `Emojis.lua` (ModuleScripts) | Copiar pro ReplicatedStorage |
| `emojis.png` | Folha com os 55 emojis e o nome de cada um | Não (é só referência) |
| `fonte/` | Scripts que geraram tudo (Python + Node). Mudou uma cor? Regenera o pacote inteiro | Não |

São **51 imagens** pra subir no jogo (24 tiles de mapa + 27 do resto). Os emojis não precisam de upload.

## Como importar

1. No Studio, abra **Asset Manager → Bulk Import** e selecione as imagens das pastas marcadas com "Sim".
2. Copie o `rbxassetid` de cada imagem e cole no lugar do `rbxassetid://0` correspondente em `Assets.lua` e `Mapas.lua`. Os nomes são os mesmos dos arquivos.
3. Coloque os quatro `.lua` como ModuleScripts em `ReplicatedStorage` (o `emojis.json` é só referência).

Dica: mande a lista de ids pra mim depois do upload que eu preencho os módulos.

## Como montar o mapa (de baixo para cima)

1. Frame do mar com `sea` + textura do mar da era em modo Tile (`mar_hachura` no vapor, `mar_ondas` no diesel, nada na elétrica, `mar_pontos` na alta velocidade), tingida com `seaPattern`.
2. Tiles `terra` tingidos com `land`. O país jogável é opaco e os vizinhos têm 45% de alfa, então ficam entre o mar e a terra sem precisar de outra cor.
3. Tiles `linhas` tingidos com `coast`: contorno grosso do país/região, fronteiras internas tracejadas (estados nos EUA, países na Europa).
4. Por cima, por código: trilhos, estações e trens.

`Mapas.lua` traz a posição de cada tile, a projeção usada (d3-geo) e as coordenadas em pixel de algumas cidades. O pipeline de dados das ferrovias vai usar a mesma projeção, pra tudo cair no lugar certo.

## 9-slice e tiles

| Imagem | Modo | Configuração |
| --- | --- | --- |
| `moldura_dupla` | Slice | SliceCenter (12, 12, 116, 116) |
| `bilhete_fundo` / `bilhete_contorno` | Slice | SliceCenter (18, 18, 110, 110) |
| `pilula_fundo` / `pilula_contorno` | Slice | SliceCenter (32, 32, 96, 32) |
| `sombra_painel` | Slice | SliceCenter (64, 64, 96, 96); tingir de preto, transparência 0.7 |
| `perfuracao` | Tile | 16 × 8 |
| `tracejado` | Tile | 24 × 4 |
| `mar_hachura` / `mar_ondas` / `mar_pontos` | Tile | 128×128 / 128×64 / 96×96 |
| `papel_grao` | Tile | 512 × 512; tingir com `ink`, transparência 0.85 |

Os mesmos valores estão em `Assets.Slice` e `Assets.Tile`.

## Fontes

O Roblox não aceita fontes próprias, então o guia usa só fontes nativas (`rbxasset://fonts/families/…`). Já estão em `Theme.lua`:

| Era | Títulos | Rótulos | Corpo | Números |
| --- | --- | --- | --- | --- |
| Vapor | Merriweather Bold | Special Elite | Source Sans Pro | Special Elite |
| Diesel | Oswald Bold | Oswald Medium | Source Sans Pro | Roboto Mono |
| Elétrica | Montserrat ExtraBold | Montserrat SemiBold | Source Sans Pro | Roboto Mono |
| Alta Velocidade | Michroma | Titillium Web SemiBold | Titillium Web | Roboto Mono |

No mockup a era do vapor usava Playfair Display, que não existe no Roblox; a Merriweather é a substituta mais próxima.

**Atenção:** essas fontes não têm setas como "↔". Use "–" no texto (ex.: "Jundiaí – Campinas") ou o emoji `conectar` (🔗).

## Emojis

Os ícones agora são texto: `label.Text = Emojis.carga_cafe`. Os nomes são os mesmos dos ícones da v1, então voltar pros ícones desenhados é trocar só o módulo.

- **Não mudam de cor.** `TextColor3` não afeta emojis coloridos, então eles ficam iguais nas 4 eras.
- **Tamanho:** use `TextSize` de 18 a 24 nos menus. Em botão, deixe o emoji e o texto em labels separados, dentro de um `UIListLayout`, pra alinhar melhor.
- **Aparência:** as imagens de referência (`emojis.png`, `guia_visual.png`) usam o desenho do Twemoji. No jogo, o desenho pode ser diferente e variar por aparelho. **Testem num celular e num PC antes de fechar.**
- **Compatibilidade:** todos os emojis escolhidos são do Unicode 10 (2017) ou anteriores, pra funcionar em aparelhos mais antigos.
- **Substitutos:** alguns conceitos não têm emoji próprio. Esses estão marcados com `*` em `emojis.png` e explicados em `Emojis.lua`:

| Nome | Emoji | Motivo |
| --- | --- | --- |
| velocidade | 💨 | Não existe velocímetro |
| carga_minerio | ⛏️ | Picareta no lugar de minério |
| carga_soja | 🌱 | O feijão (🫘) é recente demais |
| carga_carvao | 🔥 | Não existe carvão |
| carga_madeira | 🌲 | A tora (🪵) é recente demais |
| terreno_pantano | 🐊 | Jacaré representa o Pantanal |
| terreno_cremalheira | 🧗 | Não existe cremalheira; escalada = trecho íngreme |

## Regras rápidas de uso

- **Linhas sobre o mapa:** sempre com contorno de 2 px na cor `ink` (`UIStroke`). As cores amarelas e claras somem sobre a terra sem isso.
- **Estação:** `estacao_disco` (cor `panel`) com `estacao_anel` por cima (cor `ink`). Fechada: `estacao_fechada` com `locked` a 50%.
- **Cantos dos painéis:** use `forma.canto` da era (`UICorner`). No vapor é 0 e leva `moldura_dupla`.
- **Botões:** mínimo de 44 px de altura (celular).

## Pendências

- O nome **"Ferrovia Tycoon" é provisório** (questão em aberto no GDD). Se mudar, eu regenero logo, ícone e thumbnail.
- Os mapas não têm estados do Brasil. Dá pra incluir se vocês quiserem.

## Créditos e licenças

- Contornos dos países: Natural Earth (domínio público), via o pacote `world-atlas`.
- Estados dos EUA: U.S. Census Bureau (domínio público), via o pacote `us-atlas`.
- Fontes nas imagens de identidade: Merriweather, Special Elite e Source Sans Pro (licenças abertas, SIL OFL/Apache).
- Trens, molduras, marcadores e texturas: feitos para este projeto.
- Desenho dos emojis nas imagens de referência: Twemoji (CC-BY 4.0). Não vai pro jogo; lá os emojis são texto.
