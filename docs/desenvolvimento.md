# Desenvolvimento

## Preparar

```sh
git clone <repo>
cd aura-questor
```

`Libs/` **não está no repositório**. As sete bibliotecas são buscadas na origem
declarada em [`.pkgmeta`](../.pkgmeta) na hora do release, então um clone limpo
não roda no jogo até você trazê-las:

```sh
# com o empacotador instalado
release.sh -d -z
```

Ou baixe as sete manualmente para `Libs/`, uma vez. Depois disso elas ficam em
disco e são ignoradas pelo git.

Para desenvolver com o jogo aberto, crie duas junções (não precisam de
administrador) em `World of Warcraft\_retail_\Interface\AddOns\`:
`AuraQuestor` apontando para a pasta do projeto e `AuraTrackerQuestor`
apontando para `Bridge\AuraTrackerQuestor` dentro dela. O jogo só carrega
`<Pasta>\<Pasta>.toc`, então o nome de cada junção precisa bater com o
manifesto que ela contém.

## Testar

```sh
lua Tests/Run.lua              # todas as suítes
lua Tests/Run.lua Tracker      # só as de Tests/Core/Tracker/
```

Testes sobre o `Core/`, em Lua puro, sem dependências. O harness carrega
`Locales/`, `Source/Core/` e dois arquivos puros de `Source/Options/Components/`
(Theme e Schematic, que não tocam API do jogo) na mesma ordem do `.toc` e
simula o vararg que o jogo passa para cada arquivo. Retorna código 1 se algum
teste falhar.

`Tests/` espelha o interior de `Source/`: cada suíte fica no caminho equivalente
ao do módulo que exercita. Fakes e construtores compartilhados vivem em
[`Tests/Support.lua`](../Tests/Support.lua); o carregamento e as asserções, em
[`Tests/Harness.lua`](../Tests/Harness.lua).

Cobertura: filtros, ordenação, montagem das seções, detecção de conclusão,
cores, perfis, preferências, categorias de conquista e a consistência entre os
arquivos de locale.

Fora de cobertura: tudo que acessa a API do jogo ou cria frames, que só pode ser
verificado no cliente.

## Analisar

```sh
luacheck .
```

A configuração está em [`.luacheckrc`](../.luacheckrc), com os 106 globais do
jogo declarados como somente leitura e os 7 que o addon escreve separados. Roda
no CI a cada push.

## Empacotar

```powershell
.\build.ps1
```

Gera `dist\AuraQuestor-<versão>.zip` com duas pastas na raiz: `AuraQuestor`,
o addon, e `AuraTrackerQuestor`, a ponte com o nome antigo (o mesmo desenho
que o `move-folders` do `.pkgmeta` dá ao zip do release). O script valida o
`.toc` **nos dois sentidos**:

- arquivo listado que não foi empacotado, o que falharia no cliente do jogador
  sem indicar a causa
- arquivo empacotado que não está listado, que nunca carrega e dá a impressão de
  que o recurso não foi implementado

`Ports/`, `Tests/` e `docs/` ficam de fora do pacote: o primeiro contém apenas
anotações de tipo, os outros dois não são carregados pelo jogo.

## Publicar

```sh
git tag v0.72.0
git push --tags
```

A tag dispara [`release.yml`](../.github/workflows/release.yml), que roda o
BigWigs packager: busca as bibliotecas, aplica o `.pkgmeta`, monta o zip e
publica no GitHub Releases, no CurseForge e no Wago Addons.

Cada vitrine precisa de duas coisas, um identificador no `.toc` e um token nos
secrets do repositório:

| Vitrine | `.toc` | Secret |
| --- | --- | --- |
| CurseForge | `## X-Curse-Project-ID` | `CF_API_KEY` |
| Wago Addons | `## X-Wago-ID` | `WAGO_API_TOKEN` |

Faltando qualquer um dos dois, o packager pula aquela vitrine e segue: o
release não falha, e o zip continua sendo publicado no GitHub. É o que permite
adicionar uma vitrine nova sem parar de lançar enquanto ela não está pronta.

O Wago também oferece importar os GitHub Releases sozinho, em Settings. Fica
desligado de propósito: com o packager publicando, as duas rotas criariam a
mesma versão duas vezes.

## Convenções

**Commits** em [Conventional Commits](https://www.conventionalcommits.org/), em
português, como o histórico já usa: `feat:`, `fix:`, `refactor:`, `test:`,
`build:`, `chore:`, `style:`.

**Comentários** explicam a decisão, não o que a linha faz. Um bloco que precisa
de comentário para ser entendido normalmente deveria ser extraído para uma
função com nome descritivo. Código em inglês; textos visíveis ao jogador em
`Locales/`.

**Indentação** com tab, conforme o [`.editorconfig`](../.editorconfig). Finais de
linha normalizados em LF pelo [`.gitattributes`](../.gitattributes).

**Textos** não ficam literais no código. Uma chave nova entra em `Locales/enUS.lua`
**e** em `ptBR.lua`. Há um teste que falha se uma das duas faltar, ou se a
contagem de `%s` divergir entre elas.

## Versão

A versão é declarada em um único lugar, o `## Version:` do `.toc`. O `build.ps1`
usa esse valor para nomear o zip, e o `AddonMetadata` o lê para exibir nas
opções e no `/atq status`.
