# Silent Hill 2 para macOS (Apple Silicon)

Rode o **Silent Hill 2 de PC (2001)** com o **[Enhanced Edition](https://enhanced.townofsilenthill.com/SH2/)** nativamente num Mac com chip M, abrindo com um clique, sem CrossOver e sem máquina virtual.

O port usa um **Wine compilado do código-fonte aberto do CrossOver** (Wine 11.0 + patches da CodeWeavers, LGPL). Esses patches são o que faz o jogo funcionar: com o Wine comum ele cai na inicialização.

> **Este repositório não contém nenhum arquivo do jogo.** Você precisa ter a sua própria cópia do Silent Hill 2 de PC. O Enhanced Edition é baixado do site oficial do projeto durante a instalação.

Testado num **MacBook Air M2 (8 GB), macOS 26**.

## O que você ganha

- Silent Hill 2 + Enhanced Edition completo: widescreen, alta resolução, neblina e efeitos restaurados, texturas, vídeos e áudio remasterizados
- Tradução opcional (qualquer language pack do EE, ex.: português do Brasil)
- `Silent Hill 2.app` para abrir e `Fechar Silent Hill 2.app` para encerrar na hora
- Tela cheia **sem borda**, que não troca a resolução do Mac e não prende a tela
- Sincronização rápida de threads (msync) para reduzir engasgos

## Requisitos

- Mac com Apple Silicon (M1 ou mais novo) e **Rosetta 2** (`softwareupdate --install-rosetta`)
- Xcode Command Line Tools (`xcode-select --install`)
- [Homebrew](https://brew.sh)
- ~25 GB livres (compilação ~5 GB, Wine 1,5 GB, jogo + EE ~10 GB)
- O instalador de PC do Silent Hill 2 (pasta ou `.rar`/`.zip`/`.iso` contendo `data1.cab` e a pasta `movie/`)

## Instalação

```sh
git clone https://github.com/nicoladeli/silent-hill-2-macos.git ~/Games/SH2/port
cd ~/Games/SH2/port

# 1. Compila o Wine (30–60 min, só uma vez)
./scripts/build-wine.sh

# 2. Instala o jogo + Enhanced Edition (+ tradução, opcional)
./scripts/install-game.sh \
    --setup ~/Downloads/"Silent Hill Setup.rar" \
    --langpack ~/Downloads/SH2EE_LangPack_Brazilian_Portuguese.zip
```

Depois é só abrir **Silent Hill 2** pelo Launchpad. Para fechar: **Fechar Silent Hill 2**, Cmd+Tab ou o menu do jogo.

Por padrão tudo fica em `~/Games/SH2` (`wine/`, `prefix/`, `build/`). Para usar outra pasta, exporte `SH2_HOME` antes de rodar os scripts.

## Estrutura

```
scripts/
  env.sh           caminhos e variáveis do Wine (msync, bibliotecas)
  build-wine.sh    baixa o fonte do CrossOver, aplica os patches e compila
  install-game.sh  extrai o jogo, instala o EE, aplica a tradução, configura o Wine
  launch.sh        abre o jogo (usado pelo .app)
  quit.sh          encerra o jogo (usado pelo .app de fechar)
  make-apps.sh     cria os .app em /Applications
config/
  d3d8-overrides.ini  opções do EE reaplicadas a cada execução
patches/
  *.patch          mudanças no fonte do Wine
```

## Como funciona

```
sh2pc.exe (x86, 32 bits)
  └─ Wine 11.0 (fonte CrossOver) em WoW64, x86_64 via Rosetta 2
       ├─ gráficos: Direct3D 8 → d3d8to9 (EE) → Direct3D 9 → WineD3D → OpenGL → Metal
       ├─ áudio: DirectSound → CoreAudio
       └─ controle: Xidi + SDL3 (EE) → HID do Wine → IOHID do macOS
```

Configurações que fizeram diferença:

| Ajuste | Por quê |
|---|---|
| Wine do fonte CrossOver em vez do upstream | Wine 11.18 upstream e GPTK 3.0 caem na inicialização (`page fault` fixo / `alloc_pages_vprot`) |
| `d3d8` e `dinput8` = `native,builtin` | Sem isso o Wine usa a própria DLL e o EE não carrega |
| `CaptureDisplaysForFullscreen = n` + `ScreenMode = 2` | Tela cheia exclusiva prende o display do Mac |
| `VideoMemorySize = 2048` | O Wine anuncia uma GPU de 768 MB, pouco para as texturas HD |
| `WINEMSYNC=1` | Reduz micro-engasgos |
| Flag *Large Address Aware* removida | Evita alocações acima de 2 GB, problemáticas no WoW64 do Mac |

## Problemas conhecidos

- **Controle:** a cadeia DS4/DualSense/Xbox → Xidi está configurada, mas ainda não foi validada em jogo. Teclado funciona.
- **Engasgos curtos** na primeira vez que um efeito aparece (compilação de shader no WineD3D). Para aliviar, use escala de resolução 1,5× nas opções do jogo.
- Os logos de abertura não podem ser pulados automaticamente.

## Créditos

- [Wine](https://www.winehq.org) e [CodeWeavers](https://www.codeweavers.com) (fonte do CrossOver), LGPL 2.1
- [Gcenx](https://github.com/Gcenx/macOS_Wine_builds): bibliotecas x86_64 usadas no build
- Equipe do [Silent Hill 2: Enhanced Edition](https://enhanced.townofsilenthill.com/SH2/), incluindo o Xidi
- Autores dos language packs do EE
- Silent Hill 2 © Konami. Projeto de fãs, sem afiliação com a Konami.

## Licença

Scripts sob [MIT](LICENSE). Os arquivos em `patches/` modificam o Wine e seguem a licença dele (LGPL 2.1).
