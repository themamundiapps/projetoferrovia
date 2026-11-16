# Projeto Ferrovia (Ferrovia Tycoon, nome provisório)

Tycoon idle de ferrovias no Roblox. O jogador constrói redes históricas reais sobre mapas estilizados dos EUA, do Brasil e da Europa.

O código fica neste repositório e é sincronizado com o Roblox Studio pelo [Rojo](https://rojo.space).

## Primeira vez (cada um no seu PC)

1. **Instale o Rokit**, o gerenciador de ferramentas: siga as instruções em [github.com/rojo-rbx/rokit](https://github.com/rojo-rbx/rokit).
2. **Clone o repositório** e entre na pasta:
   ```
   git clone https://github.com/themamundiapps/projetoferrovia.git
   cd projetoferrovia
   ```
3. **Instale o Rojo** na versão do projeto (definida em `rokit.toml`):
   ```
   rokit install
   ```
4. **Instale o plugin do Rojo no Studio:**
   ```
   rojo plugin install
   ```

## No dia a dia

> Guia completo, com o que fazer em cada erro: [docs/LIGAR.md](docs/LIGAR.md).

1. Na pasta do projeto, rode:
   ```
   rojo serve
   ```
2. No Studio, abra o place do jogo, vá na aba **Plugins → Rojo** e clique em **Connect**.
3. Aperte Play. No Output devem aparecer duas linhas começando com `[Ferrovia]`, uma do servidor e uma do cliente. Se aparecerem, a sincronização está funcionando.

Qualquer arquivo salvo em `src/` aparece no Studio na hora.

## Regras para não perder trabalho

- **Scripts só se editam pelos arquivos do repositório**, nunca dentro do Studio. O Rojo sobrescreve o que foi mudado direto no Studio nas pastas que ele controla.
- O Rojo controla só `ReplicatedStorage.Shared`, `ServerScriptService.Server` e `StarterPlayer.StarterPlayerScripts.Client`. O resto do place (Workspace, iluminação etc.) continua sendo editado no Studio normalmente.
- Antes de começar a mexer: `git pull`. Ao terminar: `git add`, `git commit` e `git push`.
- Para algo maior, crie uma branch (`git checkout -b nome-da-tarefa`) e abra um Pull Request.

## Onde fica cada coisa

| Pasta | Vai para | Conteúdo |
| --- | --- | --- |
| `src/shared/` | `ReplicatedStorage.Shared` | Módulos usados por servidor e cliente: `Theme` (eras, cores, fontes), `Assets` (ids das imagens), `Mapas` (tiles e projeção), `Emojis` |
| `src/server/` | `ServerScriptService.Server` | Economia, save, compras (servidor manda em tudo que vale dinheiro) |
| `src/client/` | `StarterPlayerScripts.Client` | Interface: mapa 2D, painéis, menu |
| `arte/` | não vai para o jogo | Pacote gráfico: imagens para subir no Studio e o guia de uso (`arte/LEIA-ME.md`) |
| `tools/assetgen/` | não vai para o jogo | Scripts que geraram o pacote gráfico (Python + Node) |

## Imagens

As 51 imagens de `arte/` precisam ser enviadas pelo **Asset Manager → Bulk Import** do Studio. Depois, os ids entram em `src/shared/Assets.luau` e `src/shared/Mapas.luau`, no lugar de `rbxassetid://0`. O passo a passo está em `arte/LEIA-ME.md`.

## Pendências visuais (para depois)

- [x] Detalhe em alta resolução no Brasil todo onde há trilhos (grade de 30 blocos, `tools/assetgen/render_detalhes.py`)
- [ ] Afinar os rios do mapa base no zoom intermediário (1x a 1,8x)
- [x] Estações encolherem com o zoom (no Brasil inteiro, as do Sudeste se amontoavam)
- [ ] Posição manual dos nomes de estações muito próximas (Rio, Porto Mauá, Fragoso)

## Andamento do MVP

- [x] GDD aprovado
- [x] Pacote gráfico (v2, com emojis)
- [x] Estrutura do projeto com Rojo
- [x] Dados do Brasil (13 linhas históricas em 5 ondas, 6 projetos reais e 5 linhas "E se?"; 83 estações, 82 trechos)
- [x] Mapa 2D com zoom e arrastar, rios, divisas, nomes e alta resolução no zoom (falta testar no celular)
- [x] Compra de trechos, desbloqueio histórico e renda por segundo
- [x] Trens por linha e porcentagem de serviço
- [x] Carga (café e minério até os portos) e escolha de traçado
- [x] Quatro eras (vapor, diesel, elétrica e alta velocidade), com troca de visual
- [x] Save com DataStore e ganho offline (falta testar com as APIs ligadas no Studio)
- [x] Menu com abas (Linhas, Gabinete, Contratos, Jornal, Banco, Companhia, Ajustes), níveis de estação e estatísticas
- [x] Gabinete de Projetos: 6 ferrovias planejadas do Brasil e 5 "E se?" (Litorânea do Sul, Planalto, Litorânea do Nordeste, Amazônia, Trem-bala do Sul)
- [x] Economia com decisões: demanda por porte das cidades, lotação dos trens, efeito rede e manutenção
- [x] Contratos com prazo, missões do dia, nível da companhia e medalhas (`src/shared/Metas.luau`)
- [x] Trens andando no mapa e tutorial dos primeiros passos
- [x] Fichas das cidades (83 cidades, história em português e inglês; imagens em `arte/cidades/`)
- [x] Jornal da Companhia: 16 eventos de época que mexem na economia (`src/shared/Jornal.luau`)
- [x] Banco: empréstimos com juros pelo crédito da companhia, pagos com parte do lucro (`src/shared/Banco.luau`)
- [x] Preço do frete de cada carga (Companhia, painel da linha e ficha da cidade)
- [ ] Ranking e mapas dos EUA e da Europa
- [ ] Um gamepass e um developer product

## Balanço

`tools/balanco/simular.sh` roda um jogador "guloso" na economia (precisa do `luau` de linha de comando) e
imprime em que minuto cada trecho, estudo e era acontece. Serve para conferir o ritmo depois de mexer nos
números de `src/shared/Economia.luau`. No jogo, 1 minuto de verdade vale 1 dia da ferrovia.

Ritmo atual do jogador guloso: diesel aos ~32 min, elétrica aos ~76 min, alta velocidade aos ~192 min e
trem-bala Rio–SP aos ~228 min. As linhas "E se?" ocupam o meio do jogo (de ~55 a ~200 min).
