# Como ligar tudo para trabalhar no jogo

Guia passo a passo para quando o computador foi desligado, o Studio foi fechado ou o terminal caiu.
Feito para o setup do Enzo: Linux Mint, Roblox Studio pelo Tuxblox, projeto em `~/Desktop/projetoferrovia`.

São quatro peças, sempre nesta ordem:

1. **Terminal com o Rojo** (manda o código da pasta para o Studio)
2. **Roblox Studio** com o place do jogo, conectado ao Rojo
3. **App Claude no computador** (deixa o Claude testar o jogo no seu Studio)
4. *(só quando houver imagens novas)* **servidor de imagens**

---

## 1. Rojo

Abra um terminal (Ctrl + Alt + T) e rode:

```
cd ~/Desktop/projetoferrovia
git pull
rojo serve
```

**Deu certo se** aparecer algo como `Rojo server listening` e o endereço `localhost:34872`.
**Deixe esse terminal aberto** o tempo todo. Fechar a janela desliga o Rojo.

Se der erro:

| Mensagem | O que fazer |
| --- | --- |
| `rojo: command not found` ou `rokit: command not found` | O terminal não achou as ferramentas. Rode `export PATH="$HOME/.rokit/bin:$PATH"` e tente de novo. Para não precisar repetir, rode uma vez: `echo 'export PATH="$HOME/.rokit/bin:$PATH"' >> ~/.bashrc` |
| `could not find default.project.json` | Você não está na pasta do projeto. Rode o `cd ~/Desktop/projetoferrovia` antes. |
| `address already in use` | Já existe um Rojo rodando (talvez num terminal escondido). Feche os outros terminais, ou rode `pkill rojo` e depois `rojo serve`. |
| `git pull` reclama de alterações locais | Mande a mensagem para o Claude antes de mexer em qualquer coisa. |

## 2. Roblox Studio

1. Abra o Studio pelo Tuxblox e abra o place **Ferrovia**.
2. Na aba **Plugins**, clique em **Rojo**. Abre uma janelinha.
3. Confira se o endereço é `localhost` e a porta `34872`, e clique em **Connect**.

**Deu certo se** a janela do Rojo mostrar *Connected* e, no terminal do passo 1, aparecer uma linha dizendo que um cliente conectou.

Para conferir que o código está atualizado: aperte **Play** e veja o **Output** (aba *View → Output*, se não estiver aberto). Devem aparecer duas linhas:

```
[Ferrovia] Servidor iniciado.
[Ferrovia] Cliente iniciado: mapa do Brasil com 19 linhas.
```

Depois aperte **Stop**.

Se der errado:

- **O botão Rojo não aparece em Plugins:** no terminal (com o `rojo serve` parado por um momento, Ctrl + C), rode `rojo plugin install`, reabra o Studio e volte ao passo 1.
- **Conecta, mas o jogo está velho:** o Rojo só manda o que está na pasta. Pare o Rojo (Ctrl + C), rode `git pull`, rode `rojo serve` de novo e reconecte no Studio.
- **O Rojo caiu no meio:** reconecte (Plugins → Rojo → Connect). Não precisa fechar o Studio.

## 3. Claude testando no seu Studio

1. Abra o **app Claude** no computador (o mesmo que foi configurado com o Studio) e deixe aberto.
2. Abra **esta conversa** no app. Basta mandar qualquer mensagem por ele uma vez.
3. Mantenha o Studio aberto no place Ferrovia, no modo de edição (sem estar em Play).

**Deu certo se** o Claude conseguir listar o seu Studio. Basta escrever "pode testar" na conversa: se algo estiver desligado, ele avisa o que falta.

Enquanto o Claude testa:

- **Não clique no Studio.** Ele aperta Play, clica nos botões e tira prints sozinho.
- No fim, ele zera o progresso de teste. Não feche o Studio antes de ele avisar que terminou.

Se o app tiver sido fechado à força ou atualizado e o Claude disser que não acha o Studio: feche o app Claude por completo (não só a janela) e abra de novo.

## 4. Servidor de imagens (só quando o Claude pedir)

Quando houver imagens novas para subir ao Roblox (as fichas das cidades, por exemplo), abra **outro** terminal e rode:

```
cd ~/Desktop/projetoferrovia
git pull
python3 -m http.server 8765 --directory arte
```

Deixe aberto até o Claude avisar que terminou de subir as imagens; depois feche com Ctrl + C.

---

## Resumo de bolso

```
Terminal 1:  cd ~/Desktop/projetoferrovia && git pull && rojo serve
Studio:      abrir Ferrovia → Plugins → Rojo → Connect
App Claude:  aberto, nesta conversa
Terminal 2:  (só para imagens) python3 -m http.server 8765 --directory arte
```
